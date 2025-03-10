ZO_MARKET_LIST_ENTRY_HEIGHT = 52
ZO_MARKET_CATEGORY_CONTAINER_WIDTH = 298
-- 75 is the inset from the multiIcon plus the icon and spacing from ZO_IconHeader
ZO_MARKET_CATEGORY_LABEL_WIDTH = ZO_MARKET_CATEGORY_CONTAINER_WIDTH - 75 - ZO_SCROLL_BAR_WIDTH
ZO_MARKET_SUBCATEGORY_LABEL_INDENT = 76
ZO_MARKET_SUBCATEGORY_LABEL_WIDTH = ZO_MARKET_CATEGORY_CONTAINER_WIDTH - ZO_MARKET_SUBCATEGORY_LABEL_INDENT - ZO_SCROLL_BAR_WIDTH

--
--[[ ZO_Market_Keyboard ]]--
--

ZO_Market_Keyboard = ZO_Market_Shared:Subclass()

function ZO_Market_Keyboard:Initialize(control, sceneName)
    self.messageLabel = control:GetNamedChild("MessageLabel")
    self.messageLoadingIcon = control:GetNamedChild("MessageLoadingIcon")

    self:SetMarketCurrencyButtonType(ZO_MARKET_CURRENCY_BUTTON_TYPE_BUY_CROWNS)

    -- Crown Store Contents
    self.contentsControl = control:GetNamedChild("Contents")
    self.contentFragment = ZO_SimpleSceneFragment:New(self.contentsControl)
    self.contentFragment:SetConditional(function()
                                            return self.shouldShowMarketContents
                                        end)

    self.noMatchesMessage = self.contentsControl:GetNamedChild("NoMatchMessage")
    self.searchBox = self.contentsControl:GetNamedChild("SearchBox")
    self.searchBox.owner = self

    self.nextPreviewChangeTime = 0

    self.shownCurrencyTypeBalances = {}

    self:SetMarketProductFilterTypes({})
    self:SetNewMarketProductFilterTypes({MARKET_PRODUCT_FILTER_TYPE_NEW})

    control:SetHandler("OnUpdate", function(control, currentTime) self:OnUpdate(currentTime) end)

    -- MarketProductIcon Pool
    if not ZO_Market_Keyboard.masterMarketProductIconPool then
        local function CreateMarketProductIcon(objectPool)
            -- parent will be changed to the MarketProduct that uses the icon
            return ZO_MarketProductIcon:New(objectPool:GetNextControlId(), control)
        end

        -- this pool is shared with all instances of this class and other objects
        ZO_Market_Keyboard.masterMarketProductIconPool = ZO_ObjectPool:New(CreateMarketProductIcon, ZO_ObjectPool_DefaultResetObject)
    end

    local function OnBackLabelClicked(...) self:OnBackLabelClicked(...) end

    -- Bundle Contents
    self.bundleContentsControl = CreateControlFromVirtual("$(parent)BundleContents", control, "ZO_KeyboardBundleContents")
    self.bundleContentsControl:ClearAnchors()
    self.bundleContentsControl:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 5)
    self.bundleContentsControl:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, -5, 0)
    local bundleContentsBackLabel = self.bundleContentsControl:GetNamedChild("BackLabel")
    bundleContentsBackLabel.OnMouseUp = OnBackLabelClicked

    self.bundleContentFragment = ZO_MarketContentFragment_Keyboard:New(self, self.bundleContentsControl, self.masterMarketProductIconPool)

    -- Product List
    self.productListControl = CreateControlFromVirtual("$(parent)ProductList", control, "ZO_KeyboardMarketProductList")
    self.productListControl:ClearAnchors()
    self.productListControl:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 5)
    self.productListControl:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, -5, 0)
    local productListControlBackLabel = self.productListControl:GetNamedChild("BackLabel")
    productListControlBackLabel.OnMouseUp = OnBackLabelClicked

    self.productListFragment = ZO_MarketListFragment_Keyboard:New(self.productListControl, self)

    self.refreshActionsCallback = function() self:RefreshActions() end

    -- ZO_Market_Shared.Initialize needs to be called after the control declarations
    -- This is because several overridden functions such as InitializeCategories and InitializeFilters called during initialization reference them
    ZO_Market_Shared.Initialize(self, control, sceneName)
end

function ZO_Market_Keyboard:IsPreviewForMarketProductPreviewTypeVisible(previewType)
    if previewType == ZO_MARKET_PREVIEW_TYPE_BUNDLE or previewType == ZO_MARKET_PREVIEW_TYPE_BUNDLE_AS_LIST then
        return not (self.bundleContentFragment:IsShowing() or self.productListFragment:IsShowing())
    elseif previewType == ZO_MARKET_PREVIEW_TYPE_CROWN_CRATE then
        return not self.productListFragment:IsShowing()
    elseif previewType == ZO_MARKET_PREVIEW_TYPE_HOUSE then
        return true
    else -- ZO_MARKET_PREVIEW_TYPE_PREVIEWABLE
        return self:IsReadyToPreview()
    end
end

function ZO_Market_Keyboard:IsPreviewForMarketProductPreviewTypeEnabled(previewType)
    if previewType == ZO_MARKET_PREVIEW_TYPE_PREVIEWABLE then
        return ITEM_PREVIEW_KEYBOARD:CanChangePreview()
    elseif previewType == ZO_MARKET_PREVIEW_TYPE_HOUSE then
        return CanJumpToHouseFromCurrentLocation(), GetString(SI_MARKET_PREVIEW_ERROR_CANNOT_JUMP_FROM_LOCATION)
    else
        return true
    end
end

function ZO_Market_Keyboard:InitializeKeybindDescriptors()
    self.keybindStripDescriptors =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- End Preview Keybind
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name =      function()
                            if self:HasAnyCurrentSlotPreviews() then
                                return GetString(SI_MARKET_END_ALL_PREVIEWS_KEYBIND_TEXT)
                            else
                                return GetString(SI_MARKET_END_PREVIEW_KEYBIND_TEXT)
                            end
                        end,
            keybind =   "UI_SHORTCUT_NEGATIVE",
            visible =   function()
                                local isPreviewing = self:GetPreviewState()
                                return (isPreviewing and self.selectedMarketProduct == nil) or self:HasAnyCurrentSlotPreviews()
                        end,
            callback =  function()
                            local isPreviewing = self:GetPreviewState()
                            if isPreviewing then
                                self:EndCurrentPreview()
                            end
                        end,
        },

        -- Redeem Code Keybind
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name =      GetString(SI_KEYBOARD_CODE_REDEMPTION_REDEEM_CODE_KEYBIND_LABEL),
            keybind =   "UI_SHORTCUT_QUATERNARY",
            visible =   function()
                            local isPreviewing = self:GetPreviewState()
                            return not isPreviewing and self.selectedMarketProduct == nil and DoesPlatformSupportCodeRedemption()
                        end,
            callback =  function()
                            ZO_KeyboardCodeRedemption_StartCodeRedemptionFlow()
                        end,
        },

        -- Expiring Currency Keybind
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name =      GetString(SI_KEYBOARD_VIEW_EXPIRING_CROWNS_KEYBIND_LABEL),
            keybind =   "UI_SHORTCUT_QUINARY",
            visible =   function()
                            if not HasExpiringMarketCurrency() then
                                return false
                            end
                            local isPreviewing = self:GetPreviewState()
                            return not isPreviewing and self.selectedMarketProduct == nil and DoesPlatformSupportCodeRedemption()
                        end,
            callback =  function()
                            ZO_Dialogs_ShowDialog("KEYBOARD_EXPIRING_MARKET_CURRENCY_DIALOG")
                        end,
        },

        -- Order the keybinds from left to right: Purchase, Preview, Gift

        -- Purchase Keybind
        {
            order = 3,
            name =  function()
                        if self.bundleContentFragment:IsShowing() then
                            return GetString(SI_MARKET_PURCHASE_BUNDLE_KEYBIND_TEXT)
                        else
                            if self.selectedMarketProduct:IsBundle() then
                                return GetString(SI_MARKET_PURCHASE_BUNDLE_KEYBIND_TEXT)
                            else
                                return GetString(SI_MARKET_PURCHASE_KEYBIND_TEXT)
                            end
                        end
                    end,
            keybind = "UI_SHORTCUT_PRIMARY",
            visible =   function()
                            if self.bundleContentFragment:IsShowing() then
                                return self.bundleContentFragment:CanPurchase()
                            else
                                return self.selectedMarketProduct ~= nil and self.selectedMarketProduct:CanBePurchased()
                            end
                        end,
            callback =  function()
                            local marketProductData
                            if self.bundleContentFragment:IsShowing() then
                                marketProductData = self.bundleContentFragment:GetMarketProductData()
                            else
                                marketProductData = self.selectedMarketProduct:GetMarketProductData()
                            end

                            self:PurchaseMarketProduct(marketProductData)
                        end,
        },

        -- "Preview" Keybind; will also end preview of individual outfit style pieces
        {
            order = 2,
            name =      function()
                            if self.productListFragment:IsShowing() or self:HasActiveCustomPreview() then
                                local _, _, isActivePreview, isPreviewToggleable = self.productListFragment:GetPreviewState()
                                if isActivePreview and isPreviewToggleable then
                                    return GetString(SI_MARKET_END_PREVIEW_KEYBIND_TEXT)
                                else
                                    return GetString(SI_MARKET_PREVIEW_KEYBIND_TEXT)
                                end
                            else
                                local previewType = self.selectedMarketProduct:GetMarketProductPreviewType()
                                if previewType == ZO_MARKET_PREVIEW_TYPE_BUNDLE or previewType == ZO_MARKET_PREVIEW_TYPE_BUNDLE_AS_LIST then
                                    return GetString(SI_MARKET_BUNDLE_DETAILS_KEYBIND_TEXT)
                                else
                                    local _, _, isActivePreview, isPreviewToggleable = self:GetPreviewState()
                                    if isActivePreview and isPreviewToggleable then
                                        return GetString(SI_MARKET_END_PREVIEW_KEYBIND_TEXT)
                                    else
                                        return GetString(SI_MARKET_PREVIEW_KEYBIND_TEXT)
                                    end
                                end
                            end
                        end,
            keybind =   "UI_SHORTCUT_SECONDARY",
            visible =   function()
                            if self.productListFragment:IsShowing() then
                                return self.productListFragment:IsReadyToPreview()
                            elseif self:HasActiveCustomPreview() then
                                return self:IsCustomPreviewReady()
                            else
                                local marketProduct = self.selectedMarketProduct
                                if marketProduct ~= nil then
                                    local previewType = marketProduct:GetMarketProductPreviewType()
                                    return self:IsPreviewForMarketProductPreviewTypeVisible(previewType)
                                end
                            end
                            return false
                        end,
            callback =  function()
                            if self.productListFragment:IsShowing() then
                                self:PreviewData(self.productListFragment:GetSelectedData())
                            elseif self:HasActiveCustomPreview() then
                                self:PerformCustomPreview()
                            else
                                local marketProductData = self.selectedMarketProduct:GetMarketProductData()
                                self:PerformPreview(marketProductData)
                            end
                        end,
            enabled =   function()
                            if not self.productListFragment:IsShowing() and not self:HasActiveCustomPreview()then
                                local previewType = self.selectedMarketProduct:GetMarketProductPreviewType()
                                return self:IsPreviewForMarketProductPreviewTypeEnabled(previewType)
                            else
                                return true
                            end
                        end,
        },

        -- Gift Keybind
        {
            order = 1,
            name =  function()
                        if self.bundleContentFragment:IsShowing() then
                            return GetString(SI_MARKET_GIFT_BUNDLE_KEYBIND_TEXT)
                        else
                            if self.selectedMarketProduct:IsBundle() then
                                return GetString(SI_MARKET_GIFT_BUNDLE_KEYBIND_TEXT)
                            else
                                return GetString(SI_MARKET_GIFT_KEYBIND_TEXT)
                            end
                        end
                    end,
            keybind = "UI_SHORTCUT_TERTIARY",
            visible =   function()
                            if self.bundleContentFragment:IsShowing() then
                                return self.bundleContentFragment:CanGift()
                            else
                                return self.selectedMarketProduct ~= nil and self.selectedMarketProduct:IsGiftable()
                            end
                        end,
            callback =  function()
                            local marketProductData
                            if self.bundleContentFragment:IsShowing() then
                                marketProductData = self.bundleContentFragment:GetMarketProductData()
                            else
                                marketProductData = self.selectedMarketProduct:GetMarketProductData()
                            end

                            self:GiftMarketProduct(marketProductData)
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

    function ZO_Market_Keyboard:InitializeFilters()
        self.categoryFilter = self.contentsControl:GetNamedChild("Filter")
        self.categoryFilterLabel = self.contentsControl:GetNamedChild("FilterLabel")

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

function ZO_Market_Keyboard:CreateMarketScene()
    local scene = ZO_RemoteScene:New(self.sceneName, SCENE_MANAGER)
    self:SetMarketScene(scene)

    self.marketScene:AddFragment(self.contentFragment)

    local mainControlFragment = ZO_FadeSceneFragment:New(self.control)
    self.marketScene:AddFragment(mainControlFragment)
end

function ZO_Market_Keyboard:InitializeCategories()
    self.categories = self.contentsControl:GetNamedChild("Categories")
    self.categoryTree = ZO_Tree:New(self.categories:GetNamedChild("ScrollChild"), 60, -10, ZO_MARKET_CATEGORY_CONTAINER_WIDTH)

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

        local multiIcon = control:GetNamedChild("MultiIcon")
        multiIcon:ClearIcons()

        if data.showNewIcon then
            if type(data.showNewIcon) ~= "function" or data.showNewIcon() then
                multiIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
            end
        end

        multiIcon:Show()
    end

    local function TreeHeaderSetup_Child(node, control, data, open, userRequested)
        BaseTreeHeaderSetup(node, control, data, open)

        if open and userRequested then
            self.categoryTree:SelectFirstChild(node)
        end
    end

    local function TreeHeaderSetup_Childless(node, control, data, open)
        -- childless categories cannot be open because they are leaves, so pass in whether or not they are selected
        BaseTreeHeaderSetup(node, control, data, node:IsSelected())
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)

        if selected and not reselectingDuringRebuild then
            self:OnCategorySelected(data)

            local categoryIndex, subcategoryIndex, isFeaturedCategory
            -- faked category types don't have real category indices so keep them as nil
            if data.type == ZO_MARKET_CATEGORY_TYPE_NONE then
                if data.parentData then
                    categoryIndex = data.parentData.categoryIndex
                    subcategoryIndex = data.categoryIndex
                else
                    categoryIndex = data.categoryIndex
                end
            elseif data.type == ZO_MARKET_CATEGORY_TYPE_FEATURED then
                isFeaturedCategory = true
            end

            if not self:IsSearching() then
                OnMarketCategorySelected(self:GetDisplayGroup(), categoryIndex, subcategoryIndex, self.suppressMarketCategoryTutorials, isFeaturedCategory)
            end
        end
    end

    local function TreeHeaderOnSelected_Childless(control, data, selected, reselectingDuringRebuild)
        TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        BaseTreeHeaderIconSetup(control, data, selected)
    end

    local SUBCATEGORY_GEM_TEXTURE = ZO_Currency_GetKeyboardCurrencyIcon(CURT_CROWN_GEMS)
    local function TreeEntrySetup(node, control, data, open)
        control:SetText(data.name)
        control:SetSelected(node:IsSelected())

        local multiIcon = control:GetNamedChild("MultiIcon")
        multiIcon:ClearIcons()

        if data.showGemIcon then
            multiIcon:AddIcon(SUBCATEGORY_GEM_TEXTURE)
        end

        if data.showNewIcon then
            if type(data.showNewIcon) ~= "function" or data.showNewIcon() then
                multiIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
            end
        end

        multiIcon:Show()
    end
    
    local NO_SELECTION_FUNCTION = nil
    local NO_EQUALITY_FUNCTION = nil
    local childSpacing = 0
    self.categoryTree:AddTemplate("ZO_MarketCategoryWithChildren", TreeHeaderSetup_Child, NO_SELECTION_FUNCTION, NO_EQUALITY_FUNCTION, ZO_MARKET_SUBCATEGORY_LABEL_INDENT, childSpacing)
    self.categoryTree:AddTemplate("ZO_MarketChildlessCategory", TreeHeaderSetup_Childless, TreeHeaderOnSelected_Childless)
    self.categoryTree:AddTemplate("ZO_MarketSubCategory", TreeEntrySetup, TreeEntryOnSelected)

    self.categoryTree:SetExclusive(true) --only one header open at a time
    self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function ZO_Market_Keyboard:InitializeMarketList()
    self.productGridListControl = self.contentsControl:GetNamedChild("ProductList")
    self.productGridList = ZO_GridScrollList_Keyboard:New(self.productGridListControl)

    local function MarketProductEntrySetup(entryControl, data)
        if not entryControl.marketProduct then
            entryControl.marketProduct = ZO_MarketProductIndividual:New(entryControl, self.masterMarketProductIconPool, self)
        end

        entryControl.marketProduct:Show(data.productData)
    end

    local function MarketProductBundleEntrySetup(entryControl, data)
        if not entryControl.marketProduct then
            entryControl.marketProduct = ZO_MarketProductBundle:New(entryControl, self.masterMarketProductIconPool, self)
        end

        entryControl.marketProduct:Show(data.productData)
    end

    local function MarketProductEntryReset(entryControl)
        ZO_ObjectPool_DefaultResetControl(entryControl)
        entryControl.marketProduct:Reset()
    end

    local HIDE_CALLBACK = nil
    local CENTER_ENTRIES = true
    local HEADER_HEIGHT = 50
    local ROW_PADDING = 10
    self.productGridList:AddEntryTemplate("ZO_MarketProduct_Keyboard", ZO_MARKET_PRODUCT_WIDTH, ZO_MARKET_PRODUCT_HEIGHT, MarketProductEntrySetup, HIDE_CALLBACK, MarketProductEntryReset, ZO_MARKET_PRODUCT_COLUMN_PADDING, ROW_PADDING, CENTER_ENTRIES)
    self.productGridList:AddEntryTemplate("ZO_MarketProductBundle_Keyboard", ZO_MARKET_PRODUCT_BUNDLE_WIDTH, ZO_MARKET_PRODUCT_HEIGHT, MarketProductBundleEntrySetup, HIDE_CALLBACK, MarketProductEntryReset, ZO_MARKET_PRODUCT_COLUMN_PADDING, ROW_PADDING, CENTER_ENTRIES)
    self.productGridList:AddHeaderTemplate("ZO_Market_GroupLabel", HEADER_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.productGridList:SetHeaderPrePadding(30)
end

function ZO_Market_Keyboard:BuildCategories()
    local currentCategory = self.currentCategoryData
    self.categoryTree:Reset()
    self.nodeLookupData = {}

    self:HideCustomTopLevelCategories()
    self:AddTopLevelCategories()

    local nodeToSelect
    -- if we've queued up a market product to navigate to, try to select its node right away
    local queuedMarketProductId = self:GetQueuedMarketProductId()
    if queuedMarketProductId then
        nodeToSelect = self:GetCategoryDataForMarketProduct(queuedMarketProductId)
    end

    -- otherwise try to select the last category we had selected
    if nodeToSelect == nil and currentCategory then
        local categoryIndex
        local subcatgoryIndex
        local parentData = currentCategory.parentData
        if parentData then
            categoryIndex = parentData.categoryIndex
            subcatgoryIndex = currentCategory.categoryIndex
        else
            categoryIndex = currentCategory.categoryIndex
        end
        nodeToSelect = self:GetCategoryData(categoryIndex, subcatgoryIndex)
    end

    self.categoryTree:Commit(nodeToSelect)

    self.refreshCategories = false
end

function ZO_Market_Keyboard:RefreshVisibleCategoryFilter()
    local data = self.categoryTree:GetSelectedData()
    if data ~= nil then
        self:OnCategorySelected(data)
    end
end

function ZO_Market_Keyboard:GetCategoryData(categoryIndex, subcategoryIndex)
    if categoryIndex ~= nil then
        local categoryTable = self.nodeLookupData[categoryIndex]
        if categoryTable ~= nil then
            if subcategoryIndex ~= nil then
                return categoryTable.subCategories[subcategoryIndex]
            else
                if categoryTable.node:IsLeaf() then
                    return categoryTable.node
                else
                    return categoryTable.node:GetChildren()[1]
                end
            end
        end
    end
end

function ZO_Market_Keyboard:RequestShowMarketProduct(marketProductId)
    if self:IsShowing() and self.marketState == MARKET_STATE_OPEN then
        local targetNode = self:GetCategoryDataForMarketProduct(marketProductId)
        if targetNode then
            if self.categoryTree:GetSelectedNode() == targetNode then
                local preview = self:ShouldAutomaticallyPreviewMarketProduct(marketProductId)
                self:ScrollToMarketProduct(marketProductId, preview)
            else
                -- make sure to set the queued market product it before selecting the category
                -- so that LayoutMarketProducts can attempt to select the associated market product
                self:SetQueuedMarketProductId(marketProductId)
                self.categoryTree:SelectNode(targetNode)
            end
        else
            internalassert(false, string.format("Category not found for market product id: %s", tostring(marketProductId) or "nil"))
        end
    else
        self:SetQueuedMarketProductId(marketProductId)
    end
end

do
    local AUTOPREVIEWABLE_PRODUCT_TYPES =
    {
        [MARKET_PRODUCT_TYPE_NONE] = false,
        [MARKET_PRODUCT_TYPE_ITEM] = true,
        [MARKET_PRODUCT_TYPE_COLLECTIBLE] = true,
        [MARKET_PRODUCT_TYPE_INSTANT_UNLOCK] = false,
        [MARKET_PRODUCT_TYPE_BUNDLE] = false,
        [MARKET_PRODUCT_TYPE_CROWN_CRATE] = false,
        [MARKET_PRODUCT_TYPE_HOUSING] = false,
    }
    function ZO_Market_Keyboard:ShouldAutomaticallyPreviewMarketProduct(marketProductId, queuePreview)
        local productType = GetMarketProductType(marketProductId)
        if productType == MARKET_PRODUCT_TYPE_COLLECTIBLE then
            local collectibleType = select(4, GetMarketProductCollectibleInfo(marketProductId))
            if collectibleType == COLLECTIBLE_CATEGORY_TYPE_HOUSE then
                return false
            end
        end
        return AUTOPREVIEWABLE_PRODUCT_TYPES[productType]
    end
end

function ZO_Market_Keyboard:GetDataEntryForMarketProductId(marketProductId)
    local allEntryData = self.productGridList:GetData()
    for _, entryData in ipairs(allEntryData) do
        local productData = entryData.data.productData
        if productData and productData:GetId() == marketProductId then
            return entryData
        end
    end

    return nil
end

function ZO_Market_Keyboard:ScrollToMarketProduct(marketProductId, queuePreview)
    local marketProductEntry = self:GetDataEntryForMarketProductId(marketProductId)
    if marketProductEntry then
        local entryData = marketProductEntry.data

        local function OnScrollComplete()
            local entryControl = self.productGridList:GetControlFromData(entryData)
            if entryControl and entryControl.marketProduct then
                entryControl.marketProduct:PlayHighlightAnimationToEnd()
                if queuePreview then
                    self.queuedPreviewProductData = entryData.productData
                end
            end
        end
        local ANIMATE_INSTANTLY = true
        self.productGridList:ScrollDataToCenter(entryData, OnScrollComplete, ANIMATE_INSTANTLY)
    end

    self:ClearQueuedMarketProductId()
end

function ZO_Market_Keyboard:TryScrollToQueuedMarketProduct()
    local queuedMarketProductId = self:GetQueuedMarketProductId()
    if queuedMarketProductId then
        local targetNode = self:GetCategoryDataForMarketProduct(queuedMarketProductId)
        if targetNode then
            if self.categoryTree:GetSelectedNode() == targetNode then
                local preview = self:ShouldAutomaticallyPreviewMarketProduct(queuedMarketProductId)
                self:ScrollToMarketProduct(queuedMarketProductId, preview)
            end
        elseif queuedMarketProductId ~= 0 then
            -- MarketProductId of 0 indicates that the announcement has no associated marketProduct (ie. Promo), but if there is a MarketProductId other than 0
            -- then the expectation is that there should be an active supporting Product Presentation for the MarketProductId and if that is not the case then
            -- there is an error in the data setup of the market stamp.
            internalassert(false, string.format("Category not found for market product id: %s", tostring(queuedMarketProductId) or "nil"))
        end
    end
end

function ZO_Market_Keyboard:RequestShowMarketWithSearchString(searchString)
    if self.marketState ~= MARKET_STATE_OPEN or not self:IsShowing() then
        self.queuedSearchString = searchString
        return
    end

    self:DisplayMarketProductsBySearchString(searchString)
end

function ZO_Market_Keyboard:DisplayMarketProductsBySearchString(searchString)
    self.searchBox:SetText(searchString)
    -- once we've done a search then we don't care about whatever was queued
    self.queuedSearchString = nil
end

do
    local function AddNodeLookup(lookup, node, parent, categoryIndex)
        if categoryIndex ~= nil then
            local parentCategory = categoryIndex
            local subCategory

            if parent then
                parentCategory = parent.data.categoryIndex
                subCategory = categoryIndex
            end

            local categoryTable = lookup[parentCategory]
            
            if categoryTable == nil then
                categoryTable = { subCategories = {} }
                lookup[parentCategory] = categoryTable
            end

            if subCategory then
                categoryTable.subCategories[subCategory] = node
            else
                categoryTable.node = node
            end
        end
    end

    local function AddCategory(lookup, tree, nodeTemplate, parent, categoryIndex, name, normalIcon, pressedIcon, mouseoverIcon, categoryType, isFakedSubcategory, showGemIcon, showNewIcon)
        categoryType = categoryType or ZO_MARKET_CATEGORY_TYPE_NONE
        local entryData =
        {
            isFakedSubcategory = isFakedSubcategory,
            categoryIndex = categoryIndex,
            name = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, name),
            type = categoryType,
            parentData = parent and parent.data or nil,
            normalIcon = normalIcon,
            pressedIcon = pressedIcon,
            mouseoverIcon = mouseoverIcon,
            showGemIcon = showGemIcon,
            showNewIcon = showNewIcon,
        }

        local node = tree:AddNode(nodeTemplate, entryData, parent)
        entryData.node = node

        local finalCategoryIndex = isFakedSubcategory and "root" or categoryIndex
        AddNodeLookup(lookup, node, parent, finalCategoryIndex)
        return node
    end

    local REAL_SUBCATEGORY = false
    local FAKE_SUBCATEGORY = true
    local HIDE_GEM_ICON = false
    local NO_ICON = nil
    -- Returns the category or nil in the event that the category has no products (directly or via subcategories) visible to this market.
    function ZO_Market_Keyboard:AddMarketProductTopLevelCategory(categoryIndex, name, numSubCategories, normalIcon, pressedIcon, mouseoverIcon, categoryType, showNewIcon)
        local displayGroup = self:GetDisplayGroup()
        if not self:DoesCategoryOrSubcategoriesContainFilteredProducts(displayGroup, categoryIndex, ZO_NO_MARKET_SUBCATEGORY, self.marketProductFilterTypes) then
            return nil
        end

        local tree = self.categoryTree
        local lookup = self.nodeLookupData

        -- Either there's more than one subcategory found, or the subcategory found isn't "general", thus children
        local hasSearchResults = self:HasValidSearchString()
        local searchResultsWithChildren = hasSearchResults and (NonContiguousCount(self.searchResults[categoryIndex]) > 1 or self.searchResults[categoryIndex]["root"] == nil)
        local hasChildren = numSubCategories > 0 --Only for non-search results

        -- Select the correct template for the parent based on whether or not we will show any subcategories
        local nodeTemplate
        if hasSearchResults then
            -- if we have search results we will only have children if we have a real subcategory
            -- if we only have the root subcategory, we do not add it
            nodeTemplate = searchResultsWithChildren and "ZO_MarketCategoryWithChildren" or "ZO_MarketChildlessCategory"
        else
            -- if we are not searching, we only have children if the category has subcategories
            nodeTemplate = hasChildren and "ZO_MarketCategoryWithChildren" or "ZO_MarketChildlessCategory"
        end

        local NO_PARENT_CATEGORY = nil
        local parent = AddCategory(lookup, tree, nodeTemplate, NO_PARENT_CATEGORY, categoryIndex, name, normalIcon, pressedIcon, mouseoverIcon, categoryType, REAL_SUBCATEGORY, HIDE_GEM_ICON, showNewIcon)
        if hasSearchResults then
            -- ShouldAddSearchResult handles the check for filtered products in the categories, so we only need to worry about checking for filtered products
            if searchResultsWithChildren and self.searchResults[categoryIndex]["root"] then
                local function DoesCategoryContainNewProducts()
                    return self:DoesCategoryContainFilteredProducts(displayGroup, categoryIndex, ZO_NO_MARKET_SUBCATEGORY, self.newMarketProductFilterTypes)
                end

                AddCategory(lookup, tree, "ZO_MarketSubCategory", parent, categoryIndex, GetString(SI_MARKET_GENERAL_SUBCATEGORY), NO_ICON, NO_ICON, NO_ICON, ZO_MARKET_CATEGORY_TYPE_NONE, FAKE_SUBCATEGORY, HIDE_GEM_ICON, DoesCategoryContainNewProducts)
            end

            for subcategoryIndex, data in pairs(self.searchResults[categoryIndex]) do
                if subcategoryIndex ~= "root" then
                    local subCategoryName, _, showGemIcon = GetMarketProductSubCategoryInfo(displayGroup, categoryIndex, subcategoryIndex)
                    local function DoesCategoryContainNewProducts()
                        return self:DoesCategoryContainFilteredProducts(displayGroup, categoryIndex, subcategoryIndex, self.newMarketProductFilterTypes)
                    end

                    showGemIcon = showGemIcon and self.showCategoryCrownGemIcons
                    AddCategory(lookup, tree, "ZO_MarketSubCategory", parent, subcategoryIndex, subCategoryName, NO_ICON, NO_ICON, NO_ICON, ZO_MARKET_CATEGORY_TYPE_NONE, REAL_SUBCATEGORY, showGemIcon, DoesCategoryContainNewProducts)
                end
            end
        elseif hasChildren then
            if self:DoesCategoryContainFilteredProducts(displayGroup, categoryIndex, ZO_NO_MARKET_SUBCATEGORY, self.marketProductFilterTypes) then
                local function DoesCategoryContainNewProducts()
                    return self:DoesCategoryContainFilteredProducts(displayGroup, categoryIndex, ZO_NO_MARKET_SUBCATEGORY, self.newMarketProductFilterTypes)
                end

                AddCategory(lookup, tree, "ZO_MarketSubCategory", parent, categoryIndex, GetString(SI_MARKET_GENERAL_SUBCATEGORY), NO_ICON, NO_ICON, NO_ICON, ZO_MARKET_CATEGORY_TYPE_NONE, FAKE_SUBCATEGORY, HIDE_GEM_ICON, DoesCategoryContainNewProducts)
            end

            for subcategoryIndex = 1, numSubCategories do
                if self:DoesCategoryContainFilteredProducts(displayGroup, categoryIndex, subcategoryIndex, self.marketProductFilterTypes) then
                    local subCategoryName, _, showGemIcon = GetMarketProductSubCategoryInfo(displayGroup, categoryIndex, subcategoryIndex)
                    local function DoesCategoryContainNewProducts()
                        return self:DoesCategoryContainFilteredProducts(displayGroup, categoryIndex, subcategoryIndex, self.newMarketProductFilterTypes)
                    end

                    showGemIcon = showGemIcon and self.showCategoryCrownGemIcons
                    AddCategory(lookup, tree, "ZO_MarketSubCategory", parent, subcategoryIndex, subCategoryName, NO_ICON, NO_ICON, NO_ICON, ZO_MARKET_CATEGORY_TYPE_NONE, REAL_SUBCATEGORY, showGemIcon, DoesCategoryContainNewProducts)
                end
            end
        end

        return parent
    end

    function ZO_Market_Keyboard:AddCustomTopLevelCategory(categoryIndex, name, numSubCategories, normalIcon, pressedIcon, mouseoverIcon, categoryType, showNewIcon)
        local nodeTemplate = numSubCategories > 0 and "ZO_MarketCategoryWithChildren" or "ZO_MarketChildlessCategory"
        local NO_PARENT_CATEGORY = nil
        local parent = AddCategory(self.nodeLookupData, self.categoryTree, nodeTemplate, NO_PARENT_CATEGORY, categoryIndex, name, normalIcon, pressedIcon, mouseoverIcon, categoryType, REAL_SUBCATEGORY, HIDE_GEM_ICON, showNewIcon)
        return parent
    end

    function ZO_Market_Keyboard:AddCustomSubcategory(parent, subcategoryIndex, name, categoryType, showNewIcon)
        AddCategory(self.nodeLookupData, self.categoryTree, "ZO_MarketSubCategory", parent, subcategoryIndex, name, NO_ICON, NO_ICON, NO_ICON, categoryType, REAL_SUBCATEGORY, HIDE_GEM_ICON, showNewIcon)
    end
end

function ZO_Market_Keyboard:BuildFeaturedMarketProductList()
    local marketProductPresentations = self:GetFeaturedProductPresentations()
    self:LayoutMarketProducts(marketProductPresentations)
end

function ZO_Market_Keyboard:BuildMarketProductList(data)
    local parentData = data.parentData
    local categoryIndex, subcategoryIndex = self:GetCategoryIndices(data, parentData)

    local finalSubcategoryIndex = subcategoryIndex
    if data.isFakedSubcategory then
        finalSubcategoryIndex = nil
    end

    local numMarketProducts
    if finalSubcategoryIndex then
        numMarketProducts = select(2, GetMarketProductSubCategoryInfo(self:GetDisplayGroup(), categoryIndex, subcategoryIndex))
    else
        numMarketProducts = select(3, GetMarketProductCategoryInfo(self:GetDisplayGroup(), categoryIndex))
    end

    local marketProductPresentations = {}
    self:GetMarketProductPresentations(categoryIndex, finalSubcategoryIndex, numMarketProducts, marketProductPresentations)
    local disableLTOGrouping = IsLTODisabledForMarketProductCategory(self:GetDisplayGroup(), categoryIndex, finalSubcategoryIndex)
    self:LayoutMarketProducts(marketProductPresentations, disableLTOGrouping)
end

-- This function will append the ZO_MarketProductData it finds to the marketProductPresentations table as its output
function ZO_Market_Keyboard:GetMarketProductPresentations(categoryIndex, subcategoryIndex, index, marketProductPresentations)
    if index >= 1 then
        if self:HasValidSearchString() then
            if NonContiguousCount(self.searchResults) == 0 then
                return
            end

            local skipMarketProduct = true
            local categorySearchResults = self.searchResults[categoryIndex]
            if categorySearchResults then
                local effectiveSubcategoryIndex = subcategoryIndex or "root"
                local subcategorySearchResults = categorySearchResults[effectiveSubcategoryIndex]
                if subcategorySearchResults and subcategorySearchResults[index] then
                    skipMarketProduct = false
                end
            end

            if skipMarketProduct then
                index = index - 1
                return self:GetMarketProductPresentations(categoryIndex, subcategoryIndex, index, marketProductPresentations)
            end
        end

        local id, presentationIndex = GetMarketProductPresentationIds(self:GetDisplayGroup(), categoryIndex, subcategoryIndex, index)
        if self:ShouldAddMarketProductPresentation(id, presentationIndex) then
            marketProductPresentations = self:AddNewMarketProductPresentationToList(marketProductPresentations, id, presentationIndex)
        end

        index = index - 1
        return self:GetMarketProductPresentations(categoryIndex, subcategoryIndex, index, marketProductPresentations)
    end
end

function ZO_Market_Keyboard:AddNewMarketProductPresentationToList(marketProductPresentionList, id, presentationIndex)
    local productData = ZO_MarketProductData:New(id, presentationIndex)
    table.insert(marketProductPresentionList, productData)
    return marketProductPresentionList
end

function ZO_Market_Keyboard:ClearMarketProducts()
    self:ClearLabeledGroups()
    self.productGridList:ClearGridList()
    self.productGridList:CommitGridList()
    self:ShowNoMatchesMessage(false)
    -- make sure to clear the selected market product as its
    -- product data will no longer be valid when it's reset
    self.selectedMarketProduct = nil
end

function ZO_Market_Keyboard:AddLabeledGroupTable(labeledGroupName, labeledGroupTable)
    table.sort(labeledGroupTable, function(entry1, entry2)
        return self:CompareMarketProducts(entry1, entry2)
    end)

    for index, productInfo in ipairs(labeledGroupTable) do
        productInfo.gridHeaderName = labeledGroupName
        self.productGridList:AddEntry(productInfo, productInfo.templateName)
    end
end

function ZO_Market_Keyboard:ShouldAddSearchResult(categoryIndex, subcategoryIndex, productIndex)
    -- if we wouldn't add it to our view normally, don't add it to our search results
    local id, presentationIndex = GetMarketProductPresentationIds(self:GetDisplayGroup(), categoryIndex, subcategoryIndex, productIndex)
    return self:ShouldAddMarketProductPresentation(id, presentationIndex)
end

function ZO_Market_Keyboard:ShouldAddMarketProductPresentation(id, presentationIndex)
    return self:DoesMarketProductMatchAnyFilter(id, presentationIndex, self.marketProductFilterTypes)
end

function ZO_Market_Keyboard:ShouldAddMarketProduct(filterType, id)
    if filterType == MARKET_FILTER_VIEW_ALL then
        return true
    end

    local isPurchased = IsMarketProductPurchased(id)
    if isPurchased then
        return filterType == MARKET_FILTER_VIEW_PURCHASED
    else
        return filterType == MARKET_FILTER_VIEW_NOT_PURCHASED
    end
end

function ZO_Market_Keyboard:LayoutMarketProducts(marketProductPresentations, disableLTOGrouping)
    self:ClearLabeledGroups()
    self:HideCustomTopLevelCategories()
    self.categoryFilter:SetHidden(false)
    self.categoryFilterLabel:SetHidden(false)
    self:ShowNoMatchesMessage(false)
    -- make sure to clear the selected market product as its
    -- product data will no longer be valid when it's reset
    self.selectedMarketProduct = nil

    self.productGridList:ClearGridList()

    local categoryType = self.currentCategoryData.type
    local filterType = self.categoryFilter.filterType
    local hasShownProduct = false
    for _, productData in ipairs(marketProductPresentations) do
        if self:ShouldAddMarketProduct(filterType, productData:GetId()) then
            hasShownProduct = true
            local isBundle = productData:IsBundle()
            local templateName = isBundle and "ZO_MarketProductBundle_Keyboard" or "ZO_MarketProduct_Keyboard"

            local productInfo =
            {
                templateName = templateName,
                productData = productData,
                gridHeaderTemplate = "ZO_Market_GroupLabel",
                -- for sorting
                name = productData:GetDisplayName(),
                isBundle = isBundle,
                stackCount = productData:GetStackCount(),
            }

            -- DLC products in the featured category go into a special category
            if categoryType == ZO_MARKET_CATEGORY_TYPE_FEATURED and productData:ContainsDLC() then
                table.insert(self.dlcProducts, productInfo)
            else
                -- Otherwise in a normal category we will put the product into one of these buckets
                if productData:IsLimitedTimeProduct() and not disableLTOGrouping then
                    table.insert(self.limitedTimedOfferProducts, productInfo)
                elseif productData:IsFeatured() then
                    table.insert(self.featuredProducts, productInfo)
                else
                    table.insert(self.marketProducts, productInfo)
                end
            end
        end
    end

    local numAddedGroups = 0

    if #self.limitedTimedOfferProducts > 0 then
        self:AddLabeledGroupTable(GetString(SI_MARKET_LIMITED_TIME_OFFER_CATEGORY), self.limitedTimedOfferProducts)
        numAddedGroups = numAddedGroups + 1
    end

    if #self.dlcProducts > 0 then
        self:AddLabeledGroupTable(GetString(SI_MARKET_DLC_CATEGORY), self.dlcProducts)
        numAddedGroups = numAddedGroups + 1
    end

    if #self.featuredProducts > 0 then
        if categoryType == ZO_MARKET_CATEGORY_TYPE_NONE or categoryType == ZO_MARKET_CATEGORY_TYPE_ESO_PLUS_OFFERS then
            self:AddLabeledGroupTable(GetString(SI_MARKET_FEATURED_CATEGORY), self.featuredProducts)
        else -- featured
            self:AddLabeledGroupTable(GetString(SI_MARKET_ALL_LABEL), self.featuredProducts)
        end
        numAddedGroups = numAddedGroups + 1
    end

    local categoryHeader = (numAddedGroups > 0) and GetString(SI_MARKET_ALL_LABEL) or nil
    self:AddLabeledGroupTable(categoryHeader, self.marketProducts)
    self:ShowNoMatchesMessage(not hasShownProduct)
    self.productGridList:CommitGridList()

    -- once we finish building the grid, we should try to scroll to the queued market product if any
    -- since we probably queued it because we have to change categories (and therefor rebuild the grid)
    self:TryScrollToQueuedMarketProduct()
end

function ZO_Market_Keyboard:SetShownCurrencyTypeBalances(...)
    self.shownCurrencyTypeBalances = {...}
    local isCrownGemCurrencyTypeShown = ZO_IsElementInNumericallyIndexedTable(self.shownCurrencyTypeBalances, MKCT_CROWN_GEMS)
    self.showCategoryCrownGemIcons = isCrownGemCurrencyTypeShown
    -- We only want to display the Crown Crate-related tutorial in the context of a
    -- store that displays products available for purchase using Crown Gems.
    self.suppressMarketCategoryTutorials = not isCrownGemCurrencyTypeShown
end

-- Accepts an array of MARKET_PRODUCT_FILTER_TYPE masks.
function ZO_Market_Keyboard:SetMarketProductFilterTypes(typeList)
    self.marketProductFilterTypes = typeList
end

function ZO_Market_Keyboard:GetMarketProductFilterTypes()
    return self.marketProductFilterTypes
end

-- Accepts an array of MARKET_PRODUCT_FILTER_TYPE masks.
function ZO_Market_Keyboard:SetNewMarketProductFilterTypes(typeList)
    self.newMarketProductFilterTypes = typeList
end

function ZO_Market_Keyboard:GetNewMarketProductFilterTypes()
    return self.newMarketProductFilterTypes
end

-- Accepts a MARKET_PRODUCT_FILTER_TYPE mask.
function ZO_Market_Keyboard:SetFeaturedMarketProductFiltersMask(filterType)
    self.featuredMarketProductFiltersMask = filterType
end

function ZO_Market_Keyboard:GetFeaturedMarketProductFiltersMask()
    return self.featuredMarketProductFiltersMask
end

function ZO_Market_Keyboard:ShowMarket(showMarket)
    ZO_Market_Shared.ShowMarket(self, showMarket)

    -- if the Crown Store is locked (showMarket == false) then we don't want to show the
    -- Category tree and the MarketProduct scroll area, so set this flag
    -- so the content fragment can hide appropriately
    self.shouldShowMarketContents = showMarket

    self.marketScene:AddFragment(self.contentFragment)
    SCENE_MANAGER:RemoveFragment(self.bundleContentFragment)
    SCENE_MANAGER:RemoveFragment(self.productListFragment)
    self.contentFragment:Refresh() -- make sure the contents show/hide appropriately
    if showMarket then
        self.marketScene:AddFragment(MARKET_CURRENCY_KEYBOARD_FRAGMENT)
    else
        self.marketScene:RemoveFragment(MARKET_CURRENCY_KEYBOARD_FRAGMENT)
    end
    self.messageLabel:SetHidden(showMarket)
    ITEM_PREVIEW_KEYBOARD:SetEnabled(showMarket)
    if showMarket then
        -- hide the market products and show our no matches message if search has no results
        local showMessage = self:HasValidSearchString() and NonContiguousCount(self.searchResults) == 0
        self:ShowNoMatchesMessage(showMessage)
        self.messageLoadingIcon:Hide()
    end

    self:EndCurrentPreview()
end

function ZO_Market_Keyboard:ShowNoMatchesMessage(showMessage)
    self.productGridListControl:SetHidden(showMessage)
    self.noMatchesMessage:SetHidden(not showMessage)
end

function ZO_Market_Keyboard:ShowBundleContents(marketProductData)
    self:EndCurrentPreview()

    self.marketScene:RemoveFragment(self.contentFragment)
    SCENE_MANAGER:RemoveFragment(self.productListFragment)
    SCENE_MANAGER:AddFragment(self.bundleContentFragment)
    self.bundleContentFragment:ShowMarketProductContents(marketProductData)
end

function ZO_Market_Keyboard:ShowCrownCrateContents(marketProductData)
    self:EndCurrentPreview()

    self.marketScene:RemoveFragment(self.contentFragment)
    SCENE_MANAGER:RemoveFragment(self.bundleContentFragment)
    SCENE_MANAGER:AddFragment(self.productListFragment)
    self.productListFragment:ShowCrownCrateContents(marketProductData)
end

function ZO_Market_Keyboard:ShowBundleContentsAsList(marketProductData)
    self:EndCurrentPreview()

    self.marketScene:RemoveFragment(self.contentFragment)
    SCENE_MANAGER:RemoveFragment(self.bundleContentFragment)
    SCENE_MANAGER:AddFragment(self.productListFragment)
    self.productListFragment:ShowMarketProductBundleContents(marketProductData)
end

function ZO_Market_Keyboard:ShowHousePreviewDialog(marketProductData)
    self:EndCurrentPreview()

    if not CanJumpToHouseFromCurrentLocation() then
        RequestAlert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, GetString(SI_MARKET_PREVIEW_ERROR_CANNOT_JUMP_FROM_LOCATION))
        return
    end

    local mainTextParams = {mainTextParams = ZO_MarketDialogs_Shared_GetPreviewHouseDialogMainTextParams(marketProductData:GetId())}
    ZO_Dialogs_ShowDialog("CROWN_STORE_PREVIEW_HOUSE", { marketProductData = marketProductData }, mainTextParams)
end

function ZO_Market_Keyboard:OnDialogShowing()
    if self.searchBox:HasFocus() then
        self.searchBox:LoseFocus()
    end
end

function ZO_Market_Keyboard:OnMarketUpdate()
    if TREE_UNDERLAY_FRAGMENT then
        if self:GetState() == MARKET_STATE_OPEN and not self:IsMarketEmpty() then
            self.marketScene:AddFragment(TREE_UNDERLAY_FRAGMENT)
        else
            self.marketScene:RemoveFragment(TREE_UNDERLAY_FRAGMENT)
        end
    end
end

function ZO_Market_Keyboard:OnMarketLocked()
    self.messageLabel:SetText(GetString(SI_MARKET_LOCKED_TEXT))
    self:ShowMarket(false)
    self.messageLoadingIcon:Hide()
end

function ZO_Market_Keyboard:OnMarketLoading()
    if self.showLoadingText then
        self.messageLabel:SetText(GetString(SI_GAMEPAD_MARKET_PRESCENE_LOADING))
        self.messageLoadingIcon:Show()
    end
    self:ShowMarket(false)
end

do
    local function GetPurchaseErrorInfo(...)
        return ZO_MARKET_MANAGER:GetMarketProductPurchaseErrorInfo(...)
    end
    local IS_PURCHASE = false
    function ZO_Market_Keyboard:PurchaseMarketProduct(marketProductData)
        if marketProductData:IsHouseCollectible() then
            ZO_Dialogs_ShowDialog("MARKET_PURCHASE_HOUSE_TEMPLATE_SELECTION", { marketProductData = marketProductData, isGift = IS_PURCHASE })
        else
            self:StartPurchaseFlow(marketProductData, GetPurchaseErrorInfo, IS_PURCHASE)
        end
    end
end

function ZO_Market_Keyboard:ShowExpectedErrorDialog(hasErrors, dialogParams, allowContinue, expectedPurchaseResult, marketProductData)
    local NO_DIALOG_DATA = nil
    if expectedPurchaseResult == MARKET_PURCHASE_RESULT_REQUIRES_ESO_PLUS then
        ZO_Dialogs_ShowDialog("MARKET_CROWN_STORE_PURCHASE_ERROR_JOIN_ESO_PLUS", NO_DIALOG_DATA, dialogParams)
        return true
    elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_NOT_ENOUGH_VC then
        ZO_Dialogs_ShowDialog("MARKET_CROWN_STORE_PURCHASE_ERROR_PURCHASE_CROWNS", NO_DIALOG_DATA, dialogParams)
        return true
    elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_GIFTING_GRACE_PERIOD_ACTIVE then
        ZO_Dialogs_ShowDialog("MARKET_CROWN_STORE_PURCHASE_ERROR_GIFTING_GRACE_PERIOD", {}, dialogParams)
        return true
    elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_GIFTING_NOT_ALLOWED then
        ZO_Dialogs_ShowDialog("MARKET_CROWN_STORE_PURCHASE_ERROR_GIFTING_NOT_ALLOWED", NO_DIALOG_DATA, dialogParams)
        return true
    elseif expectedPurchaseResult == MARKET_PURCHASE_RESULT_PRODUCT_ALREADY_IN_GIFT_INVENTORY then
        ZO_Dialogs_ShowDialog("MARKET_CROWN_STORE_PURCHASE_ERROR_ALREADY_HAVE_PRODUCT_IN_GIFT_INVENTORY", NO_DIALOG_DATA, dialogParams)
        return true
    elseif not allowContinue then
        ZO_Dialogs_ShowDialog("MARKET_CROWN_STORE_PURCHASE_ERROR_EXIT", NO_DIALOG_DATA, dialogParams)
        return true
    elseif hasErrors then
        ZO_Dialogs_ShowDialog("MARKET_CROWN_STORE_PURCHASE_ERROR_CONTINUE", { marketProductData = marketProductData }, dialogParams)
        return true
    else
        return false
    end
end

do
    local function GetGiftErrorInfo(...)
        return ZO_MARKET_MANAGER:GetMarketProductGiftErrorInfo(...)
    end
    local IS_GIFTING = true
    function ZO_Market_Keyboard:GiftMarketProduct(marketProductData)
        if marketProductData:IsHouseCollectible() then
            local isHouseMarketProduct, houseTemplateDataList, defaultHouseTemplateIndex = ZO_MarketProduct_GetMarketProductHouseTemplateDataList(marketProductData.marketProductId, function(...) return { GetActiveMarketProductListingsForHouseTemplate(...) } end)

            local hasGiftableTemplate = false
            local firstErrorResult = nil
            for index, houseTemplateData in pairs(houseTemplateDataList) do
                local currencyType, marketData = next(houseTemplateData.marketPurchaseOptions)
                local houseTemplateMarketProductData = ZO_MarketProductData:New(marketData.marketProductId, marketData.presentationIndex)

                local hasErrors, dialogParams, allowContinue, expectedPurchaseResult = GetGiftErrorInfo(houseTemplateMarketProductData)

                if hasErrors and not firstErrorResult then
                    firstErrorResult =
                    {
                        hasErrors = hasErrors,
                        dialogParams = dialogParams,
                        allowContinue = allowContinue,
                        expectedPurchaseResult = expectedPurchaseResult,
                    }
                end
                hasGiftableTemplate = hasGiftableTemplate or not hasErrors
            end

            if hasGiftableTemplate or not self:ShowExpectedErrorDialog(firstErrorResult.hasErrors, firstErrorResult.dialogParams, firstErrorResult.allowContinue, firstErrorResult.expectedPurchaseResult, marketProductData) then
                ZO_Dialogs_ShowDialog("MARKET_PURCHASE_HOUSE_TEMPLATE_SELECTION", { marketProductData = marketProductData, isGift = IS_GIFTING })
            end
        else
            self:StartPurchaseFlow(marketProductData, GetGiftErrorInfo, IS_GIFTING)
        end
    end
end

function ZO_Market_Keyboard:StartPurchaseFlow(marketProductData, errorInfoFunction, isGift)
    local selectionSound = isGift and SOUNDS.MARKET_GIFT_SELECTED or SOUNDS.MARKET_PURCHASE_SELECTED
    PlaySound(selectionSound)

    local hasErrors, dialogParams, allowContinue, expectedPurchaseResult = errorInfoFunction(marketProductData)
    if not self:ShowExpectedErrorDialog(hasErrors, dialogParams, allowContinue, expectedPurchaseResult, marketProductData) then
        local dialogData =
        {
            marketProductData = marketProductData,
            isGift = isGift,
            isPreviewingMarketProductPlacement = IsHousingEditorPreviewingMarketProductPlacement(),
        }
        ZO_Dialogs_ShowDialog("MARKET_PURCHASE_CONFIRMATION", dialogData)
    end

    OnMarketStartPurchase(marketProductData:GetId())
end

function ZO_Market_Keyboard:OnMarketPurchaseResult()
    ZO_Market_Shared.OnMarketPurchaseResult(self)
    self:RefreshCategoryTree()
end

function ZO_Market_Keyboard:OnCollectiblesUnlockStateChanged()
    ZO_Market_Shared.OnCollectiblesUnlockStateChanged(self)
    self:RefreshCategoryTree()
end

function ZO_Market_Keyboard:RequestShowCategory(categoryIndex, subcategoryIndex)
    if self.marketScene:IsShowing() and self.marketState == MARKET_STATE_OPEN then
        self:SelectCategory(categoryIndex, subcategoryIndex)
        self:ClearQueuedCategoryIndices()
    else
        self:SetQueuedCategoryIndices(categoryIndex, subcategoryIndex)
    end
end

function ZO_Market_Keyboard:RequestShowCategoryById(categoryId)
    if self.marketScene:IsShowing() and self.marketState == MARKET_STATE_OPEN then
        local categoryIndex, subcategoryIndex = GetCategoryIndicesFromMarketProductCategoryId(self:GetDisplayGroup(), categoryId)
        self:RequestShowCategory(categoryIndex, subcategoryIndex)
        self:ClearQueuedCategoryId()
    else
        self:SetQueuedCategoryId(categoryId)
    end
end

function ZO_Market_Keyboard:SelectCategory(categoryIndex, subcategoryIndex)
    local targetNode = self:GetCategoryData(categoryIndex, subcategoryIndex)
    if targetNode then
        if self.categoryTree:GetSelectedNode() ~= targetNode then
            self.categoryTree:SelectNode(targetNode)
        end
    end
end

function ZO_Market_Keyboard:MarketProductSelected(marketProduct)
    self.selectedMarketProduct = marketProduct
    self:RefreshActions()
end

function ZO_Market_Keyboard:RefreshActions()
    self:RefreshKeybinds()

    local readyToPreview
    if self.productListFragment:IsShowing() then
        readyToPreview = self.productListFragment:IsReadyToPreview()
    elseif self:HasActiveCustomPreview() then
        readyToPreview = self:IsCustomPreviewReady()
    else
        readyToPreview = self:IsReadyToPreview()
    end

    local cursor = readyToPreview and MOUSE_CURSOR_PREVIEW or MOUSE_CURSOR_DO_NOT_CARE
    WINDOW_MANAGER:SetMouseCursor(cursor)
end

do
    local DISPLAY_LOADING_DELAY_SECONDS = ZO_MARKET_DISPLAY_LOADING_DELAY_MS / 1000
    function ZO_Market_Keyboard:OnUpdate(currentTime)
        if self.marketState == MARKET_STATE_UNKNOWN or self.marketState == MARKET_STATE_UPDATING then
            if self.loadingStartTime == nil then
                self.loadingStartTime = currentTime
            end

            if currentTime - self.loadingStartTime >= DISPLAY_LOADING_DELAY_SECONDS then
                self.showLoadingText = true
                self:OnMarketLoading()
            end
        else
            self.showLoadingText = false
            self.loadingStartTime = nil
        end
    end
end

function ZO_Market_Keyboard:SetMarketCurrencyButtonType(buttonType)
    self.marketCurrencyButtonType = buttonType
end

function ZO_Market_Keyboard:OnShowing()
    ZO_Market_Shared.OnShowing(self)
    ITEM_PREVIEW_KEYBOARD:RegisterCallback("RefreshActions", self.refreshActionsCallback)
    UpdateMarketDisplayGroup(self:GetDisplayGroup())

    if self.shownCurrencyTypeBalances then
        local currencyControl = MARKET_CURRENCY_KEYBOARD
        currencyControl:SetVisibleMarketCurrencyTypes(self.shownCurrencyTypeBalances)
        currencyControl:ShowMarketCurrencyButtonType(self.marketCurrencyButtonType)
    end
end

function ZO_Market_Keyboard:OnShown()
    self:AddKeybinds()
    ZO_Market_Shared.OnShown(self)

    if self.refreshCategories then
        self:BuildCategories()
    else
        self:RefreshCategoryTree()
    end

    if self.marketState == MARKET_STATE_OPEN then
        self:ProcessQueuedNavigation()

        if self.queuedPreviewProductData and IsCharacterPreviewingAvailable() then
            self:PerformPreview(self.queuedPreviewProductData)
            self.queuedPreviewProductData = nil
        end
    end
end

function ZO_Market_Keyboard:OnHidden()
    ZO_Market_Shared.OnHidden(self)
    self:RemoveKeybinds()
    ZO_Dialogs_ReleaseAllDialogs()
    -- make sure we restore the content fragment when we close the market
    self.marketScene:AddFragment(self.contentFragment)
    ITEM_PREVIEW_KEYBOARD:UnregisterCallback("RefreshActions", self.refreshActionsCallback)
    self.queuedPreviewProductData = nil
end

function ZO_Market_Keyboard:RefreshProducts()
    local ALL_ENTRIES = nil
    local function RefreshMarketProduct(control, data)
        if control.marketProduct then
            control.marketProduct:Refresh()
        end
    end
    self.productGridList:RefreshGridListEntryData(ALL_ENTRIES, RefreshMarketProduct)

    if self.bundleContentFragment:IsShowing() then
        self.bundleContentFragment:RefreshProducts()
    end
end

function ZO_Market_Keyboard:RefreshCategoryTree()
    -- We want to refresh the category tree in order to update the new
    -- state on the categories, however we don't want to reset the view
    -- so when we call RefreshVisible we need to make sure not to reselect any nodes
    local NOT_USER_REQUESTED = false
    self.categoryTree:RefreshVisible(NOT_USER_REQUESTED)
end

function ZO_Market_Keyboard:ResetSearch()
    -- this not only clears the text in the edit box, but it will also cancel
    -- any active search since setting text will call ZO_Market_OnSearchTextChanged
    -- which will attempt to start a new search, canceling any current search
    self.searchBox:SetText("")
end

function ZO_Market_Keyboard:PreviewData(data)
    if data then
        -- Order matters
        if data.rewardId then
            self:PreviewReward(data.rewardId)
        elseif data.productId then
            self:PreviewMarketProduct(data.productId)
        end
    end
end

function ZO_Market_Keyboard:PreviewMarketProduct(productId)
    local collectibleId
    local collectibleType
    if GetMarketProductType(productId) == MARKET_PRODUCT_TYPE_COLLECTIBLE then
        collectibleId, _, _, collectibleType = GetMarketProductCollectibleInfo(productId)
    end
    if collectibleType == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE then
        if not self:HasAnyCurrentSlotPreviews() then
            ITEM_PREVIEW_KEYBOARD:EndCurrentPreview()
        end
        self:PreviewOutfitStyle(collectibleId)
        self:RefreshActions()
    else
        self:ClearAllCurrentSlotPreviews()
        ZO_Market_Shared.PreviewMarketProduct(ITEM_PREVIEW_KEYBOARD, productId)
    end
end

function ZO_Market_Keyboard:PreviewReward(rewardId)
    ZO_Market_Shared.PreviewReward(ITEM_PREVIEW_KEYBOARD, rewardId)
end

function ZO_Market_Keyboard:PerformPreview(previewData)
    if previewData then
        -- Order matters
        if previewData.rewardId then
            self:PreviewReward(previewData.rewardId)
        elseif previewData.marketProductId then
            local marketProductData = previewData
            local previewType = marketProductData:GetMarketProductPreviewType()
            if previewType == ZO_MARKET_PREVIEW_TYPE_BUNDLE then
                self:ShowBundleContents(marketProductData)
            elseif previewType == ZO_MARKET_PREVIEW_TYPE_CROWN_CRATE then
                self:ShowCrownCrateContents(marketProductData)
            elseif previewType == ZO_MARKET_PREVIEW_TYPE_BUNDLE_AS_LIST then
                self:ShowBundleContentsAsList(marketProductData)
            elseif previewType == ZO_MARKET_PREVIEW_TYPE_HOUSE then
                self:ShowHousePreviewDialog(marketProductData)
            else -- ZO_MARKET_PREVIEW_TYPE_PREVIEWABLE
                self:PreviewMarketProduct(marketProductData:GetId())
            end
        end
    end
end

function ZO_Market_Keyboard:EndCurrentPreview()
    ZO_Market_Shared.EndCurrentPreview(self)
    ITEM_PREVIEW_KEYBOARD:EndCurrentPreview()
end

function ZO_Market_Keyboard:RefreshEsoPlusPage()
    self:DisplayEsoPlusOffer()
end

function ZO_Market_Keyboard:OnBackLabelClicked(control, upInside)
    if upInside then
        PlaySound(SOUNDS.TREE_SUBCATEGORY_CLICK)
        self:ShowMarket(true)
    end
end

function ZO_Market_Keyboard:AddTopLevelCategories()
    -- Optional Override
end

function ZO_Market_Keyboard:HideCustomTopLevelCategories()
    -- Optional Override
end

function ZO_Market_Keyboard:HasActiveCustomPreview()
    return false
end

function ZO_Market_Keyboard:IsCustomPreviewReady()
    return false
end

function ZO_Market_Keyboard:PerformCustomPreview()
    -- Optional Override
end

--
--[[ XML Handlers ]]--
--

function ZO_Market_OnSearchTextChanged(editBox)
    editBox.owner:SearchStart(editBox:GetText())
end

function ZO_Market_OnSearchEnterKeyPressed(editBox)
    editBox.owner:SearchStart(editBox:GetText())
    editBox:LoseFocus()
end

function ZO_MarketSubscribeButton_OnClicked(control)
    ZO_ShowBuySubscriptionPlatformDialog()
end

function ZO_MarketFreeTrialButton_OnClicked(control)
    ZO_Dialogs_ShowDialog("MARKET_FREE_TRIAL_PURCHASE_CONFIRMATION", {marketProductData = ZO_MARKET_MANAGER:GetFreeTrialProductData()})
end