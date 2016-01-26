ZO_KEYBOARD_MARKET_SCENE_NAME  = "market"
local MARKET_LABELED_GROUP_LABEL_TEMPLATE = "ZO_Market_GroupLabel"

--
--[[ Market ]]--
--

local Market = ZO_Market_Shared:Subclass()

function Market:New(...)
    return ZO_Market_Shared.New(self, ...)
end

function Market:Initialize(control)
    control.owner = self
    self.control = control
    self.contentsControl = self.control:GetNamedChild("Contents")
    self.currencyLabel = self.contentsControl:GetNamedChild("Currency"):GetNamedChild("CurrencyLabel")
    self.messageLabel = self.control:GetNamedChild("MessageLabel")
    self.messageLoadingIcon = self.control:GetNamedChild("MessageLoadingIcon")
    self.rotationControl = self.control:GetNamedChild("RotationArea")
    self.noMatchesMessage = self.contentsControl:GetNamedChild("NoMatchMessage")
    self.nextPreviewChangeTime = 0
    self.canBeginPreview = true

    self.control:SetHandler("OnUpdate", function(control, currentTime) self:OnUpdate(currentTime) end)

    -- ZO_Market_Shared.Initialize needs to be called after the control declarations
    -- This is because several overridden functions such as InitializeCategories and InitializeFilters called during initialization reference them
    ZO_Market_Shared.Initialize(self)
end

function Market:GetLabeledGroupLabelTemplate()
    return MARKET_LABELED_GROUP_LABEL_TEMPLATE
end

function Market:UpdateCurrencyBalance(currency)
    local currencyString = zo_strformat(SI_MARKET_CURRENCY_LABEL, ZO_CommaDelimitNumber(currency))
    self.currencyLabel:SetText(currencyString)
end

function Market:InitializeKeybindDescriptors()
    self.keybindStripDescriptors =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name =      GetString(SI_MARKET_END_PREVIEW_KEYBIND_TEXT),
            keybind =   "UI_SHORTCUT_NEGATIVE",
            visible =   function()
                                local isPreviewing = self:GetPreviewState()
                                return isPreviewing
                        end,
            callback =  function()
                            local isPreviewing = self:GetPreviewState()
                            if isPreviewing then
                                self:EndCurrentPreview()
                            end
                        end,
        },

        {
            name =      GetString(SI_MARKET_PREVIEW_KEYBIND_TEXT),
            keybind =   "UI_SHORTCUT_SECONDARY",
            visible =   function()
                            return self:IsReadyToPreview()
                        end,
            callback =  function()
                            self:BeginPreview()
                            self:SetCanBeginPreview(false, GetFrameTimeSeconds())
                        end,
            enabled =   function()
                            return self.canBeginPreview
                        end,
        },

        {
            name =  function()
                        if self.selectedMarketProduct:IsBundle() then
                            return GetString(SI_MARKET_PURCHASE_BUNDLE_KEYBIND_TEXT)
                        else
                            return GetString(SI_MARKET_PURCHASE_KEYBIND_TEXT)
                        end
                    end,
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                          return self.selectedMarketProduct ~= nil and not self.selectedMarketProduct:IsPurchaseLocked()
                      end,
            callback = function()
                           self.selectedMarketProduct:Purchase()
                       end,
        },
    }
end


do
    -- Map from enum to keyboard specific strings
    local MARKET_FILTERS =
    {
        [MARKET_FILTER_VIEW_ALL] = SI_MARKET_FILTER_SHOW_ALL,
        [MARKET_FILTER_VIEW_PURCHASED] = SI_MARKET_FILTER_SHOW_PURCHASED,
        [MARKET_FILTER_VIEW_NOT_PURCHASED] = SI_MARKET_FILTER_SHOW_NOT_PURCHASED,
    }

    function Market:InitializeFilters()
        self.categoryFilter = self.contentsControl:GetNamedChild("Filter")

        local comboBox = ZO_ComboBox_ObjectFromContainer(self.categoryFilter)
        comboBox:SetSortsItems(false)
        comboBox:SetFont("ZoFontWinT1")
        comboBox:SetSpacing(4)
    
        local function OnFilterChanged(comboBox, entryText, entry)
            self.categoryFilter.filterType = entry.filterType
            self:RefreshVisibleCategoryFilter()
        end

        for i, stringId in ipairs(MARKET_FILTERS) do
            local entry = comboBox:CreateItemEntry(GetString(stringId), OnFilterChanged)
            entry.filterType = i
            comboBox:AddItem(entry)
        end

        comboBox:SelectFirstItem()
    end
end

function Market:CreateMarketScene()
    local scene = ZO_RemoteScene:New(ZO_KEYBOARD_MARKET_SCENE_NAME, SCENE_MANAGER)
    SYSTEMS:RegisterKeyboardRootScene(ZO_MARKET_NAME, scene)
    self:SetMarketScene(scene)
end

function Market:InitializeCategories()
    self.categories = self.contentsControl:GetNamedChild("Categories")
    self.categoryTree = ZO_Tree:New(self.categories:GetNamedChild("ScrollChild"), 60, -10, 300)

    local function BaseTreeHeaderIconSetup(control, data, open)
        local iconTexture = (open and data.pressedIcon or data.normalIcon) or "EsoUI/Art/Icons/icon_missing.dds"
        local mouseoverTexture = data.mouseoverIcon or "EsoUI/Art/Icons/icon_missing.dds"
        
        control.icon:SetTexture(iconTexture)
        control.iconHighlight:SetTexture(mouseoverTexture)

        ZO_IconHeader_Setup(control, open)
    end

    local function BaseTreeHeaderSetup(node, control, data, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(data.name)
        BaseTreeHeaderIconSetup(control, data, open)
    end

    local function TreeHeaderSetup_Child(node, control, data, open, userRequested)
        BaseTreeHeaderSetup(node, control, data, open)

        if(open and userRequested) then
            self.categoryTree:SelectFirstChild(node)
        end
    end

    local function TreeHeaderSetup_Childless(node, control, data, open)
        BaseTreeHeaderSetup(node, control, data, open)
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)

        if selected and not reselectingDuringRebuild then
            self:OnCategorySelected(data)
        end
    end

    local function TreeHeaderOnSelected_Childless(control, data, selected, reselectingDuringRebuild)
        TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        BaseTreeHeaderIconSetup(control, data, selected)
    end

    local DEFAULT_NOT_SELECTED = false
    local function TreeEntrySetup(node, control, data, open)
        control:SetText(data.name)
        control:SetSelected(DEFAULT_NOT_SELECTED)
    end
    
    self.categoryTree:AddTemplate("ZO_IconHeader", TreeHeaderSetup_Child, nil, nil, 60, 0)
    self.categoryTree:AddTemplate("ZO_MarketChildlessCategory", TreeHeaderSetup_Childless, TreeHeaderOnSelected_Childless)
    self.categoryTree:AddTemplate("ZO_MarketSubCategory", TreeEntrySetup, TreeEntryOnSelected)

    self.categoryTree:SetExclusive(true) --only one header open at a time
    self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function Market:InitializeMarketList()
    self.marketProductList = self.contentsControl:GetNamedChild("EntryList")
    self.marketScrollChild = self.marketProductList:GetNamedChild("ScrollChild")

    -- MarketProductIcon Pool

    local function CreateMarketProductIcon(objectPool)
        -- parent will be changed to the MarketProduct that uses the icon
        return ZO_MarketProductIcon:New(objectPool:GetNextControlId(), self.marketScrollChild, self.marketProductIconPool)
    end
    
    local function ResetMarketProductIcon(marketProductIcon)
        marketProductIcon:Reset()
    end

    self.marketProductIconPool = ZO_ObjectPool:New(CreateMarketProductIcon, ResetMarketProductIcon)

    -- ZO_MarketProductIndividual Pool

    local function CreateMarketProduct(objectPool)
        return ZO_MarketProductIndividual:New(objectPool:GetNextControlId(), self.marketScrollChild, self.marketProductIconPool, self)
    end
    
    local function ResetMarketProduct(marketProduct)
        marketProduct:Reset()
    end

    self.marketProductPool = ZO_ObjectPool:New(CreateMarketProduct, ResetMarketProduct)

    -- ZO_MarketProductBundle Pool

    local function CreateMarketProductBundle(objectPool)
        return ZO_MarketProductBundle:New(objectPool:GetNextControlId(), self.marketScrollChild, self.marketProductIconPool, self)
    end
    
    local function ResetMarketProductBundle(marketProductBundle)
        marketProductBundle:Reset()
    end

    self.marketProductBundlePool = ZO_ObjectPool:New(CreateMarketProductBundle, ResetMarketProductBundle)
end

function Market:BuildCategories()
    local currentCategory = self.currentCategoryData
    self.categoryTree:Reset()
    self.nodeLookupData = {}

    if self.searchString == "" then
        --Special featured items blade
        local numFeaturedMarketProducts = GetNumFeaturedMarketProducts()
        if numFeaturedMarketProducts > 0 then
            self:AddTopLevelCategory(nil, GetString(SI_MARKET_FEATURED_CATEGORY), 0)
        end
    
        for i = 1, GetNumMarketProductCategories() do
            local name, numSubCategories, numMarketProducts, normalIcon, pressedIcon, mouseoverIcon = GetMarketProductCategoryInfo(i)
            self:AddTopLevelCategory(i, name, numSubCategories, normalIcon, pressedIcon, mouseoverIcon)
        end
    else
        for categoryIndex, data in pairs(self.searchResults) do
            local name, numSubCategories, numMarketProducts, normalIcon, pressedIcon, mouseoverIcon = GetMarketProductCategoryInfo(categoryIndex)
            self:AddTopLevelCategory(categoryIndex, name, numSubCategories, normalIcon, pressedIcon, mouseoverIcon)
        end
    end
    
    local nodeToSelect
    if currentCategory then
        local categoryIndex
        local subcatgoryIndex
        local parentData = currentCategory.parentData
        if parentData then
            categoryIndex = parentData.categoryIndex
            subcatgoryIndex = currentCategory.categoryIndex
        else
            categoryIndex = currentCategory.categoryIndex
        end
        nodeToSelect = self:LookupTreeNodeForData(categoryIndex, subcatgoryIndex)
    end

    self.categoryTree:Commit(nodeToSelect)
end

function Market:RefreshVisibleCategoryFilter()
    local data = self.categoryTree:GetSelectedData()
    if(data ~= nil) then
        self:OnCategorySelected(data)
    end
end

do
    local function AddNodeLookup(lookup, node, parent, categoryIndex)
        if(categoryIndex ~= nil) then
            local parentCategory = categoryIndex
            local subCategory

            if(parent) then
                parentCategory = parent.data.categoryIndex
                subCategory = categoryIndex
            end

            local categoryTable = lookup[parentCategory]
            
            if(categoryTable == nil) then
                categoryTable = { subCategories = {} }
                lookup[parentCategory] = categoryTable
            end

            if(subCategory) then
                categoryTable.subCategories[subCategory] = node
            else
                categoryTable.node = node
            end
        end
    end

    function Market:LookupTreeNodeForData(categoryIndex, subCategoryIndex)
        if(categoryIndex ~= nil) then
            local categoryTable = self.nodeLookupData[categoryIndex]
            if(categoryTable ~= nil) then
                if(subCategoryIndex ~= nil) then
                    return categoryTable.subCategories[subCategoryIndex]
                else
                    if(categoryTable.node:IsLeaf()) then
                        return categoryTable.node
                    else
                        return categoryTable.node:GetChildren()[1]
                    end
                end
            end
        end
    end

    local function AddCategory(lookup, tree, nodeTemplate, parent, categoryIndex, name, normalIcon, pressedIcon, mouseoverIcon, isFeaturedCategory, isFakedSubcategory)
        local entryData = 
        {
            isFakedSubcategory = isFakedSubcategory,
            categoryIndex = categoryIndex,
            name = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, name),
            featured = isFeaturedCategory,
            parentData = parent and parent.data or nil,
            normalIcon = normalIcon,
            pressedIcon = pressedIcon,
            mouseoverIcon = mouseoverIcon,
        }

        local soundId = parent and SOUNDS.MARKET_SUB_CATEGORY_SELECTED or SOUNDS.MARKET_CATEGORY_SELECTED
        local node = tree:AddNode(nodeTemplate, entryData, parent, soundId)
        entryData.node = node

        AddNodeLookup(lookup, node, parent, categoryIndex)
        return node
    end

    local featuredIcons =
    {
        "esoui/art/treeicons/achievements_indexicon_summary_up.dds",
        "esoui/art/treeicons/achievements_indexicon_summary_down.dds",
        "esoui/art/treeicons/achievements_indexicon_summary_over.dds",
    }
    
    local SPOTLIT = 1
    local IS_NEW = 2
    local ON_SALE = 3
    
    local FEATURED_SUBCATEGORY_FILTER =
    {
        -- spotlit is featured but nothing else "special" about it
        [SPOTLIT] = function(id)
            local _, _, cost, discountedCost, _, _, isNew = GetMarketProductInfo(id)
            return not (cost > discountedCost or isNew)
        end,
        [IS_NEW] = function(id) return select(7, GetMarketProductInfo(id)) end,
        [ON_SALE] = function(id) 
            local _, _, cost, discountedCost = GetMarketProductInfo(id)
            return cost > discountedCost
        end
    }
    
    local FEATURED_CATEGORY_INDEX = 0

    function Market:AddTopLevelCategory(categoryIndex, name, numSubCategories, normalIcon, pressedIcon, mouseoverIcon)
        local isFeaturedCategory = categoryIndex == nil
        local tree = self.categoryTree
        local lookup = self.nodeLookupData

        --Either there's more than one subcategory found, or the subcategory found isn't "general", thus children
        local searchResultsWithChildren = self.searchString ~= "" and (NonContiguousCount(self.searchResults[categoryIndex]) > 1 or self.searchResults[categoryIndex]["root"] == nil)
        local hasChildren = numSubCategories > 0 --Only for non-search results

        local nodeTemplate = (hasChildren or isFeaturedCategory) and "ZO_IconHeader" or "ZO_MarketChildlessCategory"

        if isFeaturedCategory then
            normalIcon, pressedIcon, mouseoverIcon = unpack(featuredIcons)
        end
        
        local parent = AddCategory(lookup, tree, nodeTemplate, nil, isFeaturedCategory and FEATURED_CATEGORY_INDEX or categoryIndex, name, normalIcon, pressedIcon, mouseoverIcon, isFeaturedCategory)

        if searchResultsWithChildren then
            for subcategoryIndex, data in pairs(self.searchResults[categoryIndex]) do
                if subcategoryIndex ~= "root" then
                    local subCategoryName, numSubCategoryMarketProducts = GetMarketProductSubCategoryInfo(categoryIndex, subcategoryIndex)
                    AddCategory(lookup, tree, "ZO_MarketSubCategory", parent, subcategoryIndex, subCategoryName, normalIcon, pressedIcon, mouseoverIcon)
                end
            end
        elseif hasChildren then
            for i = 1, numSubCategories do
                local subCategoryName, numSubCategoryMarketProducts = GetMarketProductSubCategoryInfo(categoryIndex, i)
                AddCategory(lookup, tree, "ZO_MarketSubCategory", parent, i, subCategoryName, normalIcon, pressedIcon, mouseoverIcon)
            end
        elseif isFeaturedCategory then
            local hasSpotlitCategory = false
            local hasNewSubCategory = false
            local hasOnSaleSubCategory = false
            local numFeaturedMarketProducts = GetNumFeaturedMarketProducts()

            -- search the featured products to find the presence of products in various subcategories including New and On Sale. 
            -- This way only subcategories that have contents will be displayed as selectable.
            for i = 1, numFeaturedMarketProducts do
                local featuredProductId = GetFeaturedMarketProductId(i)
                local name, description, cost, discountedCost, discountPercent, icon, isNew, isFeatured = GetMarketProductInfo(featuredProductId)
                
                hasNewSubCategory = hasNewSubCategory or isNew
                hasOnSaleSubCategory = hasOnSaleSubCategory or (cost > discountedCost)
                hasSpotlitCategory = hasSpotlitCategory or not (isNew or (cost > discountedCost))
                
                if hasNewSubCategory and hasOnSaleSubCategory then
                    break
                end
            end
            
            if hasSpotlitCategory then
                AddCategory(lookup, tree, "ZO_MarketSubCategory", parent, SPOTLIT, GetString(SI_MARKET_FEATURED_SUBCATEGORY), normalIcon, pressedIcon, mouseoverIcon, isFeaturedCategory)
            end
            
            if hasNewSubCategory then
                AddCategory(lookup, tree, "ZO_MarketSubCategory", parent, IS_NEW, GetString(SI_MARKET_NEW_LABEL), normalIcon, pressedIcon, mouseoverIcon, isFeaturedCategory)
            end
            
            if hasOnSaleSubCategory then
                AddCategory(lookup, tree, "ZO_MarketSubCategory", parent, ON_SALE, GetString(SI_MARKET_DISCOUNT_LABEL), normalIcon, pressedIcon, mouseoverIcon, isFeaturedCategory)
            end
        end

        return parent
    end
    
    local function GetFeaturedSubCategoryProductIds(filterFunc, index, ...)
        if index >= 1 then
            local id = GetFeaturedMarketProductId(index)
            index = index - 1
            if filterFunc(id) then
                return GetFeaturedSubCategoryProductIds(filterFunc, index, id, ...)
            else
                return GetFeaturedSubCategoryProductIds(filterFunc, index, ...)
            end
        end
        return ...
    end
    
    function Market:BuildFeaturedMarketProductList(data)
        local numFeaturedMarketProducts = GetNumFeaturedMarketProducts()
        local filterFunc = FEATURED_SUBCATEGORY_FILTER[data.categoryIndex]
        self:LayoutMarketProducts(GetFeaturedSubCategoryProductIds(filterFunc, numFeaturedMarketProducts))
    end
end

function Market:GetMarketProductIds(categoryIndex, subCategoryIndex, index, ...)
    if index >= 1 then
        if self.searchString ~= "" then
            if NonContiguousCount(self.searchResults) == 0 then
                return ...
            end

            local effectiveSubcategoryIndex = subCategoryIndex or "root"
            if not self.searchResults[categoryIndex][effectiveSubcategoryIndex][index] then
                index = index - 1
                return self:GetMarketProductIds(categoryIndex, subCategoryIndex, index, ...)
            end
        end

        local id = GetMarketProductDefId(categoryIndex, subCategoryIndex, index)
        index = index - 1
        return self:GetMarketProductIds(categoryIndex, subCategoryIndex, index, id, ...)
    end
    return ...
end

do
    local ROW_PADDING = 10
    local NUM_COLUMNS = 2
    local LABELED_GROUP_PADDING = 70
    local FIRST_LABELED_GROUP_PADDING = 40
    local LABELED_GROUP_LABEL_PADDING = -20
    function Market:AddLabeledGroupTable(labeledGroupName, labeledGroupTable)
        ZO_Market_Shared.AddLabeledGroupTable(self, labeledGroupName, labeledGroupTable)
        
        local previousRowControl = self.previousRowControl
        local previousControl
        local currentColumn = 1
        for i = 1, #labeledGroupTable do
            local productInfo = labeledGroupTable[i]
            local marketProduct = productInfo.product
            local marketControl = marketProduct:GetControl()
            marketControl:ClearAnchors()

            local isBundle = productInfo.isBundle
            if isBundle and currentColumn ~= 1 then
                currentColumn = 1 -- make sure the bundle is on a new line, it takes 2 spots
            end

            if currentColumn == 1 then
                if previousRowControl then
                    local yPadding = (i == 1 and LABELED_GROUP_PADDING or 0) + ROW_PADDING
                    marketControl:SetAnchor(TOPLEFT, previousRowControl, BOTTOMLEFT, 0, yPadding)
                else
                    marketControl:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, labeledGroupName and FIRST_LABELED_GROUP_PADDING or 0)
                end
                
                previousRowControl = marketControl
            else
                marketControl:SetAnchor(LEFT, previousControl, RIGHT, ZO_MARKET_PRODUCT_COLUMN_PADDING, 0)
            end

            if isBundle then
                currentColumn = 1 -- make sure the next item goes on a new line
            else
                currentColumn = currentColumn + 1
                if currentColumn > NUM_COLUMNS then
                    currentColumn = 1
                end
            end
            
            if i == 1 and labeledGroupName then
                self:AddLabel(labeledGroupName, marketControl, LABELED_GROUP_LABEL_PADDING)
            end

            previousControl = marketControl
        end
        
        if #labeledGroupTable > 0 then
            self.previousRowControl = previousRowControl
        end
    end
end

local NO_LABELED_GROUP_HEADER = nil
function Market:LayoutMarketProducts(...)
    self.marketProductPool:ReleaseAllObjects()
    self.marketProductBundlePool:ReleaseAllObjects()
    self:ClearLabeledGroups()
    ZO_Scroll_ResetToTop(self.marketProductList)
    self.previousRowControl = nil
    
    local filterType = self.categoryFilter.filterType
    local hasShownProduct = false
    for i = 1, select("#", ...) do
        local id = select(i, ...)
        if self:ShouldAddMarketProduct(filterType, id) then
            hasShownProduct = true
            local numAttachments = GetMarketProductNumCollectibles(id) + GetMarketProductNumItems(id)
            local isBundle = numAttachments > 1

            local pool = isBundle and self.marketProductBundlePool or self.marketProductPool
            local marketProduct = pool:AcquireObject()
            marketProduct:Show(id)

            local name, description, cost, discountedCost, discountPercent, icon, isNew, isFeatured = marketProduct:GetMarketProductInfo()
            
            -- only show the market product in the featured section or the all section
            if not self.currentCategoryData.featured and isFeatured then
                self:AddProductToLabeledGroupTable(self.featuredProducts, name, marketProduct)
            else
                self:AddProductToLabeledGroupTable(self.marketProducts, name, marketProduct)
            end
        end
    end

    if not self.currentCategoryData.featured and #self.featuredProducts > 0 then
        self:AddLabeledGroupTable(GetString(SI_MARKET_FEATURED_CATEGORY), self.featuredProducts)
    end

    local categoryHeader = (#self.labeledGroups > 0) and GetString(SI_MARKET_ALL_LABEL) or NO_LABELED_GROUP_HEADER
    self:AddLabeledGroupTable(categoryHeader, self.marketProducts)
    self:ShowNoMatchesMessage(not hasShownProduct)
end

function Market:ShowMarket(showMarket)
    self.contentsControl:SetHidden(not showMarket)
    self.messageLabel:SetHidden(showMarket)
    self.rotationControl:SetHidden(not showMarket)
    if showMarket then
        -- hide the market products and show our no matches message if search has no results
        local showMessage = self.searchString ~= "" and NonContiguousCount(self.searchResults) == 0
        self:ShowNoMatchesMessage(showMessage)
        self.messageLoadingIcon:Hide()
    end
end

function Market:ShowNoMatchesMessage(showMessage)
    self.marketProductList:SetHidden(showMessage)
    self.noMatchesMessage:SetHidden(not showMessage)
end

function Market:OnMarketUpdate()
    if MARKET_TREE_UNDERLAY_FRAGMENT then
        MARKET_TREE_UNDERLAY_FRAGMENT:Refresh()
    end
end

function Market:OnMarketLocked()
    self.messageLabel:SetText(GetString(SI_MARKET_LOCKED_TEXT))
    self:ShowMarket(false)
    self.messageLoadingIcon:Hide()
end

function Market:OnMarketLoading()
    if self.showLoadingText then
        self.messageLabel:SetText(GetString(SI_GAMEPAD_MARKET_PRESCENE_LOADING))
        self.messageLoadingIcon:Show()
    end
    self:ShowMarket(false)
end

function Market:MarketProductSelected(marketProduct)
    self.selectedMarketProduct = marketProduct
    self:RefreshActions()
end

function Market:RefreshActions()
    self:RefreshKeybinds()
    local cursor = self:IsReadyToPreview() and MOUSE_CURSOR_PREVIEW or MOUSE_CURSOR_DO_NOT_CARE
    WINDOW_MANAGER:SetMouseCursor(cursor)
end

do
    local PREVIEW_WAIT_TIME_SECONDS = ZO_MARKET_PREVIEW_WAIT_TIME_MS / 1000
    function Market:SetCanBeginPreview(canBeginPreview, lastChangeTimeSeconds)
        self.canBeginPreview = canBeginPreview
        self.nextPreviewChangeTime = lastChangeTimeSeconds + PREVIEW_WAIT_TIME_SECONDS
        self:RefreshKeybinds()
    end
end

do
    local DISPLAY_LOADING_DELAY_SECONDS = ZO_MARKET_DISPLAY_LOADING_DELAY_MS / 1000
    function Market:OnUpdate(currentTime)
        if(not self.canBeginPreview and (currentTime >= self.nextPreviewChangeTime)) then
            self:SetCanBeginPreview(true, currentTime)
        end

        if self.marketState == MARKET_STATE_UNKNOWN then
            if self.loadingStartTime == nil then
                self.loadingStartTime = currentTime
            end

            if currentTime - self.loadingStartTime >= DISPLAY_LOADING_DELAY_SECONDS then
                self.showLoadingText = true
                self:OnMarketLoading()
            end
        else
            self.showLoadingText = false
            loadingStartTime = nil
        end
    end
end

function Market:OnShown()
    self:AddKeybinds()
    ZO_Market_Shared.OnShown(self)
end

function Market:OnHidden()
    self:RemoveKeybinds()
    ZO_Dialogs_ReleaseAllDialogs()
end

function Market:RefreshProducts()
    for i = 1, #self.marketProducts do
        local product = self.marketProducts[i].product
        product:Refresh()
    end

    for i = 1, #self.featuredProducts do
        local product = self.featuredProducts[i].product
        product:Refresh()
    end
end

function Market:RestoreActionLayerForTutorial()
    PushActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_USER_INTERFACE_SHORTCUTS))
end

function Market:RemoveActionLayerForTutorial()
    -- we exit the gamepad tutotial by pressing "Alt"
    RemoveActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_USER_INTERFACE_SHORTCUTS))
end

--
--[[ XML Handlers ]]--
--

function ZO_Market_OnInitialize(self)
    MARKET = Market:New(self)
    SYSTEMS:RegisterKeyboardObject(ZO_MARKET_NAME, MARKET)
end

function ZO_Market_BeginSearch(editBox)
    editBox:TakeFocus()
end

function ZO_Market_EndSearch(editBox)
    editBox:LoseFocus()
end

function ZO_Market_OnSearchTextChanged(editBox)
    MARKET:SearchStart(editBox:GetText())
end

function ZO_Market_OnSearchEnterKeyPressed(editBox)
    MARKET:SearchStart(editBox:GetText())
    editBox:LoseFocus()
end

function ZO_MarketCurrency_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, -2)
    SetTooltipText(InformationTooltip, GetString(SI_MARKET_CURRENCY_TOOLTIP))
end

function ZO_MarketCurrency_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end


function ZO_MarketCurrencyBuyCrowns_OnClicked(control)
    ZO_Dialogs_ShowDialog("MARKET_CONFIRM_OPEN_URL", ZO_BUY_CROWNS_URL, ZO_BUY_CROWNS_FRONT_FACING_ADDRESS)
end