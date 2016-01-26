ZO_GAMEPAD_MARKET_SCENE_NAME  = "gamepad_market"
ZO_GAMEPAD_MARKET_PREVIEW_SCENE_NAME = "gamepad_market_preview"
ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS_SCENE_NAME = "gamepad_market_bundle_contents"
ZO_GAMEPAD_MARKET_LOCKED_SCENE_NAME = "gamepad_market_locked"
ZO_GAMEPAD_MARKET_PRE_SCENE_NAME = "gamepad_market_pre_scene"

local EMPTY_TAB_HEADER_ENTRY = { text = "" } -- Default tab header, used to have a tab entry before the market results have been pulled
local DEFAULT_AMOUNT_CROWNS = 0
local FIRST_CATEGORY_INDEX = 1
local GAMEPAD_MARKET_LABELED_GROUP_LABEL_TEMPLATE = "ZO_GamepadMarket_GroupLabel"

local LABELED_GROUP_PADDING = 110 --padding from bottom of one gorup to the top of the next
local LABELED_GROUP_LABEL_PADDING = -10 --padding from the top of a group to the bottom of it's header

local MARKET_BUY_CROWNS_BUTTON =
{
    alignment = KEYBIND_STRIP_ALIGN_RIGHT,
    gamepadOrder = 1,
    name = GetString(SI_MARKET_BUY_CROWNS),
    keybind = "UI_SHORTCUT_TERTIARY",
    callback = ZO_GamepadMarket_ShowBuyCrownsDialog
}

local MARKET_BUY_PLUS_BUTTON =
{
    alignment = KEYBIND_STRIP_ALIGN_RIGHT,
    gamepadOrder = 10, --this will come before the buy crowns button
    name = GetString(SI_GAMEPAD_MARKET_BUY_PLUS_KEYBIND_LABEL),
    keybind = "UI_SHORTCUT_RIGHT_STICK",
    callback = ZO_GamepadMarket_ShowBuyPlusDialog
}

--
--[[ Gamepad Market Preview ]]--
--

local GamepadMarketPreview = ZO_Object:Subclass()

function GamepadMarketPreview:New(...)
    local preview = ZO_Object.New(self)
    preview:Initialize(...)
    return preview
end

function GamepadMarketPreview:Initialize(control)
    control.owner = self
    self.control = control
    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.canChangePreview = true
    self.lastSetChangeTime = 0
    self:InitializeKeybindDescriptors()
    GAMEPAD_MARKET_PREVIEW_SCENE = ZO_RemoteScene:New(ZO_GAMEPAD_MARKET_PREVIEW_SCENE_NAME, SCENE_MANAGER)
    GAMEPAD_MARKET_PREVIEW_SCENE:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)
end

function GamepadMarketPreview:InitializeKeybindDescriptors()
    local function RefreshProductsOnPurchase()
        self.previewProductsContainer:RefreshProducts()
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        self:LayoutPreviewedProduct()
    end

    self.keybindStripDescriptors =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_GAMEPAD_PREVIEW_PREVIOUS),
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            callback = function()
                self:MoveToPreviousPreviewProduct()
            end,
            visible = function() return self:HasMultiplePreviewProducts() end,
            enabled = function() return self.canChangePreview end,
        },
        {
            name = GetString(SI_GAMEPAD_PREVIEW_NEXT),
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            callback = function()
                self:MoveToNextPreviewProduct()
            end,
            visible = function() return self:HasMultiplePreviewProducts() end,
            enabled = function() return self.canChangePreview end,
        },
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor()
    }
end

function GamepadMarketPreview:HasMultiplePreviewProducts()
    return self.previewProductsContainer:HasMultiplePreviewProducts()
end

function GamepadMarketPreview:LayoutPreviewedProduct()
    self.marketProduct:LayoutTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function GamepadMarketPreview:UpdatePreviewedProduct(marketProduct, dontPreviewProduct)
    self.marketProduct = marketProduct
    if IsCharacterPreviewingAvailable() and (not dontPreviewProduct) then
        self.marketProduct:Preview()
    end
    
    self:LayoutPreviewedProduct()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptors)
end

function GamepadMarketPreview:SetCanChangePreview(canChangePreview)
    self.canChangePreview = canChangePreview
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptors)
end

function GamepadMarketPreview:MoveToPreviousPreviewProduct()
    self:UpdatePreviewedProduct(self.previewProductsContainer:MoveToPreviousPreviewProduct())
    self:SetCanChangePreview(false) -- Unlocked later with OnUpdate
    self.lastSetChangeTime = GetFrameTimeMilliseconds()
end

function GamepadMarketPreview:MoveToNextPreviewProduct()
    self:UpdatePreviewedProduct(self.previewProductsContainer:MoveToNextPreviewProduct())
    self:SetCanChangePreview(false) -- Unlocked later with OnUpdate
    self.lastSetChangeTime = GetFrameTimeMilliseconds()
end

function GamepadMarketPreview:SetPreviewProductsContainer(previewProductsContainer)
    self.previewProductsContainer = previewProductsContainer
end

do
    local PREVIEW_UPDATE_INTERVAL = 100
    local DONT_PREVIEW_PRODUCT = true
    function GamepadMarketPreview:OnShowing()
        self.canChangePreview = true
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptors)
         -- Don't begin previewing the product on showing because the preview begins before this scene is shown
        self:UpdatePreviewedProduct(self.previewProductsContainer:GetCurrentPreviewProduct(), DONT_PREVIEW_PRODUCT)
        EVENT_MANAGER:RegisterForUpdate("GamepadMarketPreviewUpdate", PREVIEW_UPDATE_INTERVAL, function(...) self:OnUpdate(...) end)
    end
end

function GamepadMarketPreview:OnShown()
    g_activeMarketScreen = ZO_GAMEPAD_MARKET_PREVIEW
end

function GamepadMarketPreview:OnHidden()
    EVENT_MANAGER:UnregisterForUpdate("GamepadMarketPreviewUpdate")
    EndCurrentItemPreview()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptors)
    self:Deactivate()
    self.marketProduct = nil
    self.previewProductsContainer = nil
end

function GamepadMarketPreview:OnStateChanged(oldState, newState)
    if(newState == SCENE_SHOWING) then
        self:OnShowing()
    elseif(newState == SCENE_SHOWN) then
        self:OnShown()
    elseif(newState == SCENE_HIDDEN) then
        self:OnHidden()
    end
end

function GamepadMarketPreview:OnUpdate(ms)
    if (not self.canChangePreview) and ((ms - self.lastSetChangeTime) > ZO_MARKET_PREVIEW_WAIT_TIME_MS) then
        self.lastSetChangeTime = ms
        self:SetCanChangePreview(true)
    end
end

function GamepadMarketPreview:Activate()
    BeginItemPreview()
    BeginItemPreviewSpin() -- don't need to take any further action to allow the spinner
end

function GamepadMarketPreview:Deactivate()
    EndItemPreviewSpin()
    EndItemPreview()
end

--
--[[ Gamepad Market ]]--
--

local GamepadMarket = ZO_Object.MultiSubclass(ZO_GamepadMarket_GridScreen, ZO_Market_Shared)

function GamepadMarket:New(...)
    return ZO_Market_Shared.New(self, ...)
end

function GamepadMarket:Initialize(control)
    ZO_GamepadMarket_GridScreen.Initialize(self, control, ZO_GAMEPAD_MARKET_BUNDLE_PRODUCTS_PER_ROW, ZO_GAMEPAD_MARKET_PRODUCTS_PER_COLUMN, { EMPTY_TAB_HEADER_ENTRY })
    ZO_Market_Shared.Initialize(self)
end

function GamepadMarket:SetupSceneGroupCallback()
    self.marketSceneGroup = self.marketScene:GetSceneGroup()
    self.marketSceneGroup:RegisterCallback("StateChange", function(oldState, newState)
        self:PerformDeferredInitialization()
        if newState == SCENE_GROUP_SHOWING then
            self:OnInitialInteraction()
        elseif newState == SCENE_GROUP_HIDDEN then
            self:OnEndInteraction()
        end
    end)
end

function GamepadMarket:PerformDeferredInitialization()
    if self.isInitialized then return end
    self.isLockedForCategoryRefresh = false
    self.OnGamepadDialogHidden = function() 
        self:AnchorCurrentCategoryControlToScrollChild()
    end
    self.subCategoryDataMarketProductIdMap = {} -- Used to map product IDs to product subcategories during category building
    self.subCategoryLabeledGroupTableMap = {} -- Used to lookup subcategory "LabeledGroup" tables during category building
    self.isInitialized = true
end

function GamepadMarket:GetLabeledGroupLabelTemplate()
    return GAMEPAD_MARKET_LABELED_GROUP_LABEL_TEMPLATE
end

function GamepadMarket:LayoutSelectedMarketProduct()
    local marketProduct = self.selectedMarketProduct
    if not marketProduct:IsBlank() then
        marketProduct:LayoutTooltip(GAMEPAD_RIGHT_TOOLTIP)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function GamepadMarket:OnSelectionChanged(selectedData)
    ZO_GamepadMarket_GridScreen.OnSelectionChanged(self, selectedData)
    local previouslySelectedMarketProduct = self.selectedMarketProduct
    if selectedData then
        self.selectedMarketProduct = selectedData.marketProduct
        self:LayoutSelectedMarketProduct()
    elseif not self.isLockedForCategoryRefresh then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        self.selectedMarketProduct = nil
    end

    self:UpdatePreviousAndNewlySelectedProducts(previouslySelectedMarketProduct, self.selectedMarketProduct)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptors)
end

function GamepadMarket:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self:OnShowing()
    elseif newState == SCENE_SHOWN then
        self:OnShown()
    elseif newState == SCENE_HIDING then
        self:OnHiding()
    elseif newState == SCENE_HIDDEN then
        self:OnHidden()
    end
end

function GamepadMarket:OnInitialInteraction()
    ZO_Market_Shared.OnInitialInteraction(self)
    
    if self.isInitialized and self.marketState == MARKET_STATE_OPEN then
        GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_LEFT_DIALOG_TOOLTIP) -- Clear status labels on entry to the market
        GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_RIGHT_TOOLTIP)
        self.isLockedForCategoryRefresh = false
    end
end

function GamepadMarket:OnEndInteraction()
    self:ClearProducts()
    self:ReleasePreviousCategoryProducts()
    self.currentCategoryMarketProductPool:ReleaseAllObjects()
    self.lastCategoryData = nil
    self.currentCategoryData = nil
    self:ClearPreviewVars()
    self.header.tabBar:Clear()
    g_activeMarketScreen = nil
    self.queuedTutorial = nil
    ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS:SetQueuedTutorial(nil)
    ZO_Market_Shared.OnEndInteraction(self)
    KEYBIND_STRIP:SetStyle(KEYBIND_STRIP_STANDARD_STYLE)
end

function GamepadMarket:OnShowing()
    self:PerformDeferredInitialization()
    ZO_Market_Shared.OnShowing(self)
end

function GamepadMarket:OnShown()
    if self.marketState == MARKET_STATE_OPEN then
        self:OnMarketOpen()
        self:ReleasePreviousCategoryProducts() -- Cleans up any products left over from entering submenus like bundle details or product preview
        self:Activate()
        self:AddKeybinds()

        g_activeMarketScreen = ZO_GAMEPAD_MARKET
        self:UpdateTooltip()
        ZO_Market_Shared.OnShown(self)
        ZO_GamepadMarket_GridScreen.OnShown(self)
        self:RefreshKeybinds()
        CALLBACK_MANAGER:RegisterCallback("OnGamepadDialogHidden", self.OnGamepadDialogHidden)
    else
        self:OnMarketLocked()
    end
end

function GamepadMarket:OnHiding()
    ZO_Market_Shared.OnHiding(self)
    if self.currentCategoryData then
        SCENE_MANAGER:RemoveFragment(self.currentCategoryData.fragment)
    end

    self.currentCategoryControl = nil
    self:Deactivate()
    self:RemoveKeybinds()
    CALLBACK_MANAGER:UnregisterCallback("OnGamepadDialogHidden", self.OnGamepadDialogHidden)
end

function GamepadMarket:InitializeKeybindDescriptors()
    local function RefreshOnPurchase() -- Only called on transaction success
        self.selectedMarketProduct:Refresh()
    end

    local function OnPurchaseEnd(reachedConfirmationScene, purchasedConsumables)
        self.isLockedForCategoryRefresh = reachedConfirmationScene

        if purchasedConsumables then
            self:SetQueuedTutorial(TUTORIAL_TRIGGER_CROWN_CONSUMABLE_PURCHASED)
        end

        self:Activate()
    end

    self.keybindStripDescriptors =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
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
                            return self.selectedMarketProduct and not (self.selectedMarketProduct:IsPurchaseLocked() or self.selectedMarketProduct:IsBlank())
                        end,
            enabled = function() return not self:HasQueuedTutorial() end,
            callback = function()
                self.isLockedForCategoryRefresh = true
                self.currentCategoryData.fragment:SetDirection(ZO_GAMEPAD_MARKET_PAGE_NO_DIRECTION)
                self:BeginPurchase(self.selectedMarketProduct, RefreshOnPurchase, OnPurchaseEnd)
                self:Deactivate()
            end,
        },
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name =  function()
                        if self.selectedMarketProduct:IsBundle() then
                            return GetString(SI_GAMEPAD_MARKET_BUNDLE_DETAILS_KEYBIND)
                        else
                            return GetString(SI_MARKET_PREVIEW_KEYBIND_TEXT)
                        end
                    end,
            keybind = "UI_SHORTCUT_SECONDARY",
            visible =   function()
                            return self.selectedMarketProduct ~= nil and not self.selectedMarketProduct:IsBlank()
                        end,
            enabled =   function()
                            local marketProduct = self.selectedMarketProduct
                            if marketProduct ~= nil and ((marketProduct:HasPreview() and IsCharacterPreviewingAvailable()) or marketProduct:IsBundle()) then
                                return true
                            end
                            return false
                        end,
            callback =  function()
                            local marketProduct = self.selectedMarketProduct
                            if marketProduct:IsBundle() then
                                self.currentCategoryData.fragment:SetDirection(ZO_GAMEPAD_MARKET_PAGE_NO_DIRECTION)
                                self:ShowBundleContents(marketProduct)
                            else
                                self:BeginPreview()
                            end
                        end,
        },
        MARKET_BUY_CROWNS_BUTTON,
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
    }

    if GetUIPlatform() == UI_PLATFORM_XBOX then
        table.insert(self.keybindStripDescriptors, MARKET_BUY_PLUS_BUTTON)
    end
end

function GamepadMarket:GetPrimaryButtonDescriptor()
    return self.primaryButtonDescriptor
end

function GamepadMarket:BeginPreview()
    self.isLockedForCategoryRefresh = true
    self.currentCategoryData.fragment:SetDirection(ZO_GAMEPAD_MARKET_PAGE_NO_DIRECTION)
    ZO_GamepadMarket_GridScreen.BeginPreview(self)
    self:Deactivate()
end 

function GamepadMarket:OnCategorySelected(data)
    if self.marketScene:IsShowing() and self.marketState == MARKET_STATE_OPEN then
        self.lastCategoryData, self.currentCategoryData = self.currentCategoryData, data
        local lastCategoryControl = self.currentCategoryControl
        self.currentCategoryControl = data.control

        if self.lastCategoryData ~= self.currentCategoryData then
            self.isLockedForCategoryRefresh = false
        end
        
        if not self.isLockedForCategoryRefresh then
            ZO_ClearTable(self.subCategoryDataMarketProductIdMap)
            ZO_ClearTable(self.subCategoryLabeledGroupTableMap)
            
            if data.featured then
                self:BuildFeaturedMarketProductList()
            else
                self:BuildMarketProductList(data)
            end
        else
            self:UpdateScrollbarAlpha()
        end

        if lastCategoryControl ~= self.currentCategoryControl then
            -- This temporarily disables scrolling for the old and new categories, but allows for the paging animation to work correctly. 
            -- The category controls will be re-anchored to the scroll child if/when they are shown
            if self.lastCategoryData then
                local lastCategoryControl = self.lastCategoryData.control
                if not self.isLockedForCategoryRefresh then
                    lastCategoryControl:SetAnchor(TOPLEFT, self.contentContainer, TOPLEFT)
                    lastCategoryControl:SetAnchor(BOTTOMRIGHT, self.contentContainer, BOTTOMRIGHT)
                end
                
                SCENE_MANAGER:RemoveFragment(self.lastCategoryData.fragment)
            end

            if not self.isLockedForCategoryRefresh then
                self.currentCategoryControl:SetAnchor(TOPLEFT, self.contentContainer, TOPLEFT)
                self.currentCategoryControl:SetAnchor(BOTTOMRIGHT, self.contentContainer, BOTTOMRIGHT)
            end
            
            SCENE_MANAGER:AddFragment(data.fragment)
        end
    end
end

do
    local MARKET_PRODUCT_SORT_KEYS =
    {
        name = {},
    }

    function GamepadMarket:CompareMarketProducts(entry1, entry2)
        return ZO_TableOrderingFunction(entry1, entry2, "name", MARKET_PRODUCT_SORT_KEYS, ZO_SORT_ORDER_UP)
    end
end

function GamepadMarket:UpdateCurrencyBalance(currentCurrency)
    self.currencyAmountControl:SetText(ZO_CommaDelimitNumber(currentCurrency))
    
    if not self.control:IsHidden() then
        self:RefreshKeybinds()
    elseif GAMEPAD_MARKET_BUNDLE_CONTENTS_SCENE and GAMEPAD_MARKET_BUNDLE_CONTENTS_SCENE:IsShowing() then
        ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS:RefreshKeybinds()
    end
end

function GamepadMarket:CreateMarketScene()
    local scene = ZO_RemoteScene:New(ZO_GAMEPAD_MARKET_SCENE_NAME , SCENE_MANAGER)
    SYSTEMS:RegisterGamepadRootScene(ZO_MARKET_NAME, scene)
    self:SetMarketScene(scene)
end

function GamepadMarket:AcquireBlankTile()
    return self.currentCategoryBlankProductPool:AcquireObject()
end

function GamepadMarket:InitializeBlankProductPool()
    ZO_GamepadMarket_GridScreen.InitializeBlankProductPool(self)
    self.currentCategoryBlankProductPool = ZO_MetaPool:New(self.blankTilePool)
    self.lastCategoryBlankProductPool = ZO_MetaPool:New(self.blankTilePool)
 end

function GamepadMarket:InitializeMarketProductPool()
    ZO_GamepadMarket_GridScreen.InitializeMarketProductPool(self)
    self.currentCategoryMarketProductPool = ZO_MetaPool:New(self.marketProductPool)
    self.lastCategoryMarketProductPool = ZO_MetaPool:New(self.marketProductPool)
end

-- Cache the current products in lastCategoryMarketProductPool. These will be released after the category change animation has finished
function GamepadMarket:ReleaseAllProducts()
    self:ReleasePreviousCategoryProducts()
    self.currentCategoryMarketProductPool, self.lastCategoryMarketProductPool = self.lastCategoryMarketProductPool, self.currentCategoryMarketProductPool
    self.currentCategoryBlankProductPool, self.lastCategoryBlankProductPool = self.lastCategoryBlankProductPool, self.currentCategoryBlankProductPool
end

function GamepadMarket:ReleasePreviousCategoryProducts()
    self.lastCategoryMarketProductPool:ReleaseAllObjects()
    self.lastCategoryBlankProductPool:ReleaseAllObjects()
end

function GamepadMarket:AnchorCurrentCategoryControlToScrollChild()
    self.currentCategoryControl:ClearAnchors()
    self.currentCategoryControl:SetAnchor(TOPLEFT, self.contentContainer.scrollChild, TOPLEFT)
    self.currentCategoryControl:SetAnchor(BOTTOMRIGHT, self.contentContainer.scrollChild, BOTTOMRIGHT)
end

do
    local function CreateSubCategoryData(name, parentData, index, numProducts)
        return {
            text = name,
            numProducts = numProducts,
            soundId = SOUNDS.MARKET_SUB_CATEGORY_SELECTED,
            parentData = parentData,
            parent = parentData.control,
            categoryIndex = index,
        }
    end

    local GAMEPAD_MARKET_CATEGORY_TEMPLATE = "ZO_GamepadMarket_CategoryTemplate"
    local ALWAYS_ANIMATE = true
    local function CreateCategoryData(name, parent, marketCategoryIndex, tabIndex, numSubCategories, isFeaturedCategory)
        local control = CreateControlFromVirtual(GAMEPAD_MARKET_CATEGORY_TEMPLATE, parent, GAMEPAD_MARKET_CATEGORY_TEMPLATE, marketCategoryIndex)
        return {
            text = name,
            control = control,
            subCategories = {},
            numSubCategories = numSubCategories,
            soundId = SOUNDS.MARKET_CATEGORY_SELECTED,
            categoryIndex = marketCategoryIndex, -- Market category index used for def lookup
            tabIndex = tabIndex, -- Index in the tab header, as displayed. This can be different from the market category index when there is a featured category 
            featured = isFeaturedCategory,
            fragment = ZO_GamepadMarketPageFragment:New(control, ALWAYS_ANIMATE)
        }
    end

    -- Categories can be marked as "gamepadUseWideTiles" which will make the category display MarketProducts in larger tiles
    -- This should currently only apply to Categories that contain only bundles, but bundles themselves could be in a non-"bundle category"
    function GamepadMarket:AddTopLevelCategory(categoryIndex, tabIndex, name, numSubCategories)
        local isFeaturedCategory = categoryIndex == nil
        local useWideTiles = categoryIndex and DoesMarketProductCategoryGamepadUseWideTiles(categoryIndex)
        name = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, name)
        
        local categoryData = CreateCategoryData(name, self.contentContainer.scrollChild, categoryIndex, tabIndex, numSubCategories, isFeaturedCategory)
        categoryData.useWideTiles = useWideTiles

        local hasChildren = numSubCategories > 0
        if hasChildren then
            for i = 1, numSubCategories do
                local subCategoryName, numSubCategoryMarketProducts = GetMarketProductSubCategoryInfo(categoryIndex, i)
                subCategoryName = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, subCategoryName)
                local subCategoryData = CreateSubCategoryData(subCategoryName, categoryData, i, numSubCategoryMarketProducts)
                table.insert(categoryData.subCategories, subCategoryData)
            end
        end

        local function OnCategoryFragmentStateChanged(oldState, newState)
            if newState == SCENE_FRAGMENT_HIDDEN then
                self:ReleasePreviousCategoryProducts() -- Wait to release products until the after the animation has finished
            elseif newState == SCENE_FRAGMENT_SHOWN and not self.isLockedForCategoryRefresh then
                local categoryControl = categoryData.control
                -- Re-anchoring after animation to enable scrolling of the category control
                self:AnchorCurrentCategoryControlToScrollChild()
            end
        end

        categoryData.fragment:RegisterCallback("StateChange", OnCategoryFragmentStateChanged)
        
        local tabEntry =
        {
            text = name,
            callback = function()
                self:OnCategorySelected(categoryData)
            end,
        }

        table.insert(self.headerData.tabBarEntries, tabEntry)
    end
end

do
    local FEATURED_TAB_INDEX = 1
    local ZERO_SUBCATEGORIES = 0
    function GamepadMarket:BuildCategories(control)
        if self.marketState == MARKET_STATE_OPEN then
            ZO_ClearTable(self.headerData.tabBarEntries)

            local numFeaturedMarketProducts = GetNumFeaturedMarketProducts()
            self.hasFeaturedCategory = numFeaturedMarketProducts > 0
            if self.hasFeaturedCategory then
                self:AddTopLevelCategory(nil, FEATURED_TAB_INDEX, GetString(SI_MARKET_FEATURED_CATEGORY), ZERO_SUBCATEGORIES)
            end

            local numCategories = GetNumMarketProductCategories()
            for i = 1, numCategories do
                local name, numSubCategories = GetMarketProductCategoryInfo(i)
                self:AddTopLevelCategory(i, self.hasFeaturedCategory and i + FEATURED_TAB_INDEX or i, name, numSubCategories)
            end

            self.categoriesInitialized = true
            self:RefreshHeader()
        end
    end
end

function GamepadMarket:BuildMarketProductList(data)
    local parentData = data.parentData
    local categoryIndex, subCategoryIndex = self:GetCategoryIndices(data, parentData)
    self.currentSubCategoryBuildInProgress = nil
    
    --subcategories will be accumulated into the parent categories, so ignore them
    if not subCategoryIndex then
        self:LayoutMarketProducts(self:GetCategoryProductIds(data, 1, data.numSubCategories))
    end
end

-- ... is a list of product ids
function GamepadMarket:GetCategoryProductIds(data, currentSubCategory, numSubCategories, ...)
    if currentSubCategory <= numSubCategories then
        local subCategoryData = data.subCategories[currentSubCategory]
        local categoryIndex, subCategoryIndex = self:GetCategoryIndices(subCategoryData, subCategoryData.parentData)
        local numMarketProducts = select(2, GetMarketProductSubCategoryInfo(categoryIndex, subCategoryIndex))
        self.currentSubCategoryBuildInProgress = subCategoryData
        currentSubCategory = currentSubCategory + 1
        return self:GetCategoryProductIds(data, currentSubCategory, numSubCategories, self:GetMarketProductIds(categoryIndex, subCategoryIndex, numMarketProducts, ...))
    else
        local categoryIndex, subCategoryIndex = self:GetCategoryIndices(data, data.parentData)
        local numMarketProducts = select(3, GetMarketProductCategoryInfo(categoryIndex, subCategoryIndex))
        self.currentSubCategoryBuildInProgress = nil
        return self:GetMarketProductIds(categoryIndex, subCategoryIndex, numMarketProducts, ...)
    end
end

function GamepadMarket:GetMarketProductIds(categoryIndex, subCategoryIndex, index, ...)
    if index >= 1 then
        local id = GetMarketProductDefId(categoryIndex, subCategoryIndex, index)
        self.subCategoryDataMarketProductIdMap[id] = self.currentSubCategoryBuildInProgress
        index = index - 1
        return self:GetMarketProductIds(categoryIndex, subCategoryIndex, index, id, ...)
    end
    return ...
end

function GamepadMarket:FinishBuild()
    self:FinishCurrentLabeledGroup() -- must come before call to parent's FinishBuild
    ZO_GamepadMarket_GridScreen.FinishBuild(self)
end

function GamepadMarket:AddBlankTile(blankTile)
    self:AddEntry(blankTile, blankTile:GetControl())
end

function GamepadMarket:FinishCurrentLabeledGroup()
    self:FinishRowWithBlankTiles()

    if self:GetCurrentLabeledGroupNumProducts() > 0 then
        self.gridYPaddingOffset = self.gridYPaddingOffset + LABELED_GROUP_PADDING
    end
end

function GamepadMarket:AddLabeledGroupTable(labeledGroupName, labeledGroupTable, ignoreHasPreview)
    if #self.labeledGroups > 0 then
        self:FinishCurrentLabeledGroup()
    end

    ZO_Market_Shared.AddLabeledGroupTable(self, labeledGroupName, labeledGroupTable)

    for i, entry in ipairs(labeledGroupTable) do
        self:AddEntry(entry.product, entry.control, ignoreHasPreview)

        if i == 1 and labeledGroupName then
            self:AddLabel(labeledGroupName, entry.control, LABELED_GROUP_LABEL_PADDING)
        end
    end
end

local function SubcategoryListSort(firstEntry, secondEntry)
    return firstEntry.categoryIndex < secondEntry.categoryIndex
end

-- the table of subcategory data may have holes in it if a category ends up not displaying 
-- any market products (they were all featured for example) so we need to resort to get rid of holes
local function CreateSortedSubcategoryList(subcategoryData)
    local sortedList = {}
    for k, v in pairs(subcategoryData) do
        table.insert(sortedList, { categoryIndex = k, data = v.data, groupTable = v.groupTable})
    end
    table.sort(sortedList, SubcategoryListSort)
    return sortedList
end

function GamepadMarket:FindOrCreateSubCategoryLabeledGroupTable(subCategoryData)
    local categoryIndex = subCategoryData.categoryIndex
    if not self.subCategoryLabeledGroupTableMap[categoryIndex] then
        self.subCategoryLabeledGroupTableMap[categoryIndex] = { data = subCategoryData, groupTable = {}}
    end

    return self.subCategoryLabeledGroupTableMap[categoryIndex].groupTable
end

function GamepadMarket:AddMarketProductToLabeledGroupOrGeneralGroup(name, marketProduct, id)
    local subCategoryData = self.subCategoryDataMarketProductIdMap[id]
    if subCategoryData then
        self:AddProductToLabeledGroupTable(self:FindOrCreateSubCategoryLabeledGroupTable(subCategoryData), name, marketProduct)
    else
        self:AddProductToLabeledGroupTable(self.marketProducts, name, marketProduct)
    end
end

function GamepadMarket:LayoutMarketProducts(...)
    self:ClearProducts()
    self:ClearLabeledGroups(self)

    local numProducts = select("#", ...)
    local productsPerRow, productPadding, productWidth, productHeight

    local useWideTiles = self.currentCategoryData.useWideTiles
    if useWideTiles then
        productsPerRow, productPadding, productWidth, productHeight = ZO_GAMEPAD_MARKET_BUNDLE_PRODUCTS_PER_ROW, ZO_GAMEPAD_MARKET_BUNDLE_PRODUCT_PADDING, ZO_GAMEPAD_MARKET_BUNDLE_PRODUCT_WIDTH, ZO_GAMEPAD_MARKET_BUNDLE_PRODUCT_HEIGHT
    else
        productsPerRow, productPadding, productWidth, productHeight = ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCTS_PER_ROW, ZO_GAMEPAD_MARKET_PRODUCT_PADDING , ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_WIDTH, ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_HEIGHT
    end

    local productsPerColumn = zo_ceil(numProducts / productsPerRow)
    self:PrepareGridForBuild(productsPerRow, productsPerColumn, productWidth, productHeight, productPadding, useWideTiles)

    for i = 1, numProducts do
        local id = select(i, ...)
        local marketProduct = self.currentCategoryMarketProductPool:AcquireObject()
        marketProduct:Show(id)
        local name, description, cost, discountedCost, discountPercent, icon, isNew, isFeatured = marketProduct:GetMarketProductInfo()

        if self.currentCategoryData.featured then
            if isNew then
                self:AddProductToLabeledGroupTable(self.newProducts, name, marketProduct)
            elseif cost ~= discountedCost then
                self:AddProductToLabeledGroupTable(self.onSaleProducts, name, marketProduct)
            else
                self:AddProductToLabeledGroupTable(self.featuredProducts, name, marketProduct)
            end
        else
            -- only show the market product in the featured section or the all section
            if isFeatured then
                self:AddProductToLabeledGroupTable(self.featuredProducts, name, marketProduct)
            else
                self:AddMarketProductToLabeledGroupOrGeneralGroup(name, marketProduct, id)
            end
        end
    end

    self:AddLabeledGroupTable(GetString(SI_MARKET_FEATURED_CATEGORY), self.featuredProducts)

    if self.currentCategoryData.featured then
        self:AddLabeledGroupTable(GetString(SI_MARKET_NEW_LABEL), self.newProducts)
        self:AddLabeledGroupTable(GetString(SI_MARKET_DISCOUNT_LABEL), self.onSaleProducts)
    else
        local sortedSubcategories = CreateSortedSubcategoryList(self.subCategoryLabeledGroupTableMap)
        for categoryIndex, subcategoryInfo in ipairs(sortedSubcategories) do
            local subCategoryName = subcategoryInfo.data.text
            self:AddLabeledGroupTable(subCategoryName, subcategoryInfo.groupTable)
        end

        self:AddLabeledGroupTable(GetString(SI_MARKET_ALL_LABEL), self.marketProducts)
    end

    local direction = ZO_GAMEPAD_MARKET_PAGE_LEFT_DIRECTION
    if self.lastCategoryData and self.lastCategoryData ~= self.currentCategoryData then
        -- We have to account for tab wrapping and perceived direction traversal
        if self.currentCategoryData.tabIndex < self.lastCategoryData.tabIndex  then
            if self.currentCategoryData.tabIndex ~= FIRST_CATEGORY_INDEX or self.lastCategoryData.tabIndex ~= #self.headerData.tabBarEntries then
                direction = ZO_GAMEPAD_MARKET_PAGE_RIGHT_DIRECTION
            end
        elseif self.currentCategoryData.tabIndex == #self.headerData.tabBarEntries and self.lastCategoryData.tabIndex == FIRST_CATEGORY_INDEX then
            direction = ZO_GAMEPAD_MARKET_PAGE_RIGHT_DIRECTION
        end
    end

    if self.lastCategoryData then
        self.lastCategoryData.fragment:SetDirection(direction)
    end
    
    self.currentCategoryData.fragment:SetDirection(self.isLockedForCategoryRefresh and ZO_GAMEPAD_MARKET_PAGE_NO_DIRECTION or direction)
    self:FinishBuild()
end

function GamepadMarket:OnMarketOpen()
    if ZO_GAMEPAD_MARKET_LOCKED then -- This can be called before the lock screen has been initialized
        ZO_GAMEPAD_MARKET_LOCKED:OnMarketOpen()
    end

    if self.isInitialized then
        ZO_GamepadMarket_GridScreen.OnShowing(self)
        
        if (not self.categoriesInitialized) then
            self:BuildCategories()
        else
            self:UpdateCurrentCategory()
        end

        self.isLockedForCategoryRefresh = true -- prevent double category initialization on first entry
        self:RefreshHeader()
        self:SelectAfterPreview()
        self.isLockedForCategoryRefresh = false
    end
end

function GamepadMarket:OnMarketLocked()
    if self.isInitialized and SCENE_MANAGER:IsShowing(ZO_GAMEPAD_MARKET_SCENE_NAME) and (not ZO_GAMEPAD_MARKET_LOCKED_SCENE:IsShowing()) then
        SCENE_MANAGER:SwapCurrentScene(ZO_GAMEPAD_MARKET_LOCKED_SCENE_NAME)
    end
end

-- we shouldn't get into this state when the gamepad Crown Store is open, so treat it like a lock (as before)
function GamepadMarket:OnMarketLoading()
    self:OnMarketLocked()
end

function GamepadMarket:OnMarketPurchaseResult()
    -- handled by GamepadMarketPurchaseManager
end

function GamepadMarket:ShowBundleContents(bundle)
    self:Deactivate()
    self.isLockedForCategoryRefresh = true
    ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS:SetBundle(bundle)
    SCENE_MANAGER:Push(ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS_SCENE_NAME)
end

function GamepadMarket:OnTutorialShowing()
    g_activeMarketScreen:RemoveKeybinds()
    g_activeMarketScreen:Deactivate()
end

function GamepadMarket:OnTutorialHidden()
    g_activeMarketScreen:Activate()
    g_activeMarketScreen:AddKeybinds()
end

function GamepadMarket:RestoreActionLayerForTutorial()
    PushActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_GENERAL))
end

function GamepadMarket:RemoveActionLayerForTutorial()
    -- we exit the gamepad tutotial by pressing "A"
    RemoveActionLayerByName(GetString(SI_KEYBINDINGS_LAYER_GENERAL))
end

function GamepadMarket:ClearProducts()
    ZO_GamepadMarket_GridScreen.ClearProducts(self)
    self.selectedMarketProduct = nil
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptors)
end

--
-- [[ Market Product Tooltip ]]--
--

do
    local MarketTooltipMixin = {}
    do
        local BUNDLE_HEADER = GetString(SI_GAMEPAD_MARKET_BUNDLES_TOOLTIP_BUNDLE_HEADER)
        local UPGRADE_HEADER = GetString(SI_MARKET_PRODUCT_TOOLTIP_UPGRADE)
        local UNLOCK_LABEL = GetString(SI_MARKET_PRODUCT_TOOLTIP_UNLOCK)

        function MarketTooltipMixin:AddInstantUnlockEligibilityFailures(...)
            local count = select("#", ...)
            if count > 0 then
                local ineligibilitySection = self:AcquireSection(self:GetStyle("instantUnlockIneligibilitySection"))
                for i = 1, count do
                    local errorStringId = select(i, ...)
                    if errorStringId ~= 0 then
                        ineligibilitySection:AddLine(GetErrorString(errorStringId), self:GetStyle("instantUnlockIneligibilityLine"))
                    end
                end
                self:AddSection(ineligibilitySection)
            end
        end

        function MarketTooltipMixin:LayoutMarketProduct(product)
            local productId = product:GetId()
            local instantUnlockType = GetMarketProductInstantUnlockType(productId);

            --things added to the topSection stack upwards
            local topSection = self:AcquireSection(self:GetStyle("topSection"))
            -- Category
            if product:IsBundle() then
                topSection:AddLine(BUNDLE_HEADER)
            elseif GetMarketProductNumCollectibles(productId) > 0 then
                local type = select(4, GetMarketProductCollectibleInfo(productId, 1))
                topSection:AddLine(GetString("SI_COLLECTIBLECATEGORYTYPE", type))
            elseif instantUnlockType ~= MARKET_INSTANT_UNLOCK_NONE then
                topSection:AddLine(UPGRADE_HEADER)
            end

            self:AddSection(topSection)

            -- Name
            self:AddLine(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, product.name), qualityNormal, self:GetStyle("title"))

            if instantUnlockType == MARKET_INSTANT_UNLOCK_PLAYER_BACKPACK or instantUnlockType == MARKET_INSTANT_UNLOCK_PLAYER_BANK then
                local statsSection = self:AcquireSection(self:GetStyle("baseStatsSection"))
                local statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
                statValuePair:SetStat(UNLOCK_LABEL, self:GetStyle("statValuePairStat"))
            
                local currentUnlock
                local maxUnlock
                local description
                if instantUnlockType == MARKET_INSTANT_UNLOCK_PLAYER_BACKPACK then
                    currentUnlock = GetCurrentBackpackUpgrade()
                    maxUnlock = GetMaxBackpackUpgrade()
                    description = zo_strformat(SI_MARKET_PRODUCT_TOOLTIP_BACKPACK_UPGRADE_DESCRIPTION, GetNumBackpackSlotsPerUpgrade())
                elseif instantUnlockType == MARKET_INSTANT_UNLOCK_PLAYER_BANK then
                    currentUnlock = GetCurrentBankUpgrade()
                    maxUnlock = GetMaxBankUpgrade()
                    description = zo_strformat(SI_MARKET_PRODUCT_TOOLTIP_BANK_UPGRADE_DESCRIPTION, GetNumBankSlotsPerUpgrade())
                end

                statValuePair:SetValue(zo_strformat(SI_MARKET_PRODUCT_TOOLTIP_UNLOCK_LEVEL, currentUnlock, maxUnlock), self:GetStyle("statValuePairValue"))
                statsSection:AddStatValuePair(statValuePair)
                self:AddSection(statsSection)

                -- Description
                local bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))
                bodySection:AddLine(description, self:GetStyle("bodyDescription"))
                self:AddSection(bodySection)
            else
                -- Description
                local bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))
                bodySection:AddLine(product.description, self:GetStyle("bodyDescription"))
                self:AddSection(bodySection)
            end

            --Instant Unlock Restrictions
            if instantUnlockType ~= MARKET_INSTANT_UNLOCK_NONE then
                local GET_CACHED_STATE = true
                local purchaseState = GetMarketProductPurchaseState(productId, GET_CACHED_STATE)
                if purchaseState == MARKET_PRODUCT_PURCHASE_STATE_INSTANT_UNLOCK_INELIGIBLE then
                    self:AddInstantUnlockEligibilityFailures(GetMarketProductReqListErrorStringIds(productId))
                end
            end
        end
    end

    -- Using a mixin because adding a method to ZO_Tooltip doesn't work with GAMEPAD_TOOLTIPS if the method is added after ZO_Tooltip_Gamepad.lua is loaded
    local rightTooltip = GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_RIGHT_TOOLTIP)
    zo_mixin(rightTooltip, MarketTooltipMixin)
end

--
--[[ Gamepad Market Bundle Contents ]]--
--

local GamepadMarketBundleContents = ZO_GamepadMarket_GridScreen:Subclass()

function GamepadMarketBundleContents:New(...)
    local bundleContents = ZO_Object.New(self)
    bundleContents:Initialize(...)
    return bundleContents
end

function GamepadMarketBundleContents:Initialize(control)
    ZO_GamepadMarket_GridScreen.Initialize(self, control, ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCTS_PER_ROW, ZO_GAMEPAD_MARKET_PRODUCTS_PER_COLUMN)
    GAMEPAD_MARKET_BUNDLE_CONTENTS_SCENE = ZO_RemoteScene:New(ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS_SCENE_NAME, SCENE_MANAGER)
    GAMEPAD_MARKET_BUNDLE_CONTENTS_SCENE:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)
end

function GamepadMarketBundleContents:InitializeMarketProductPool()
    local BUNDLE_ITEM_NAME = self.control:GetName() .. ZO_GAMEPAD_MARKET_PRODUCT_BUNDLE_ITEM_ATTACHMENT_TEMPLATE
    local BUNDLE_COLLECTIBLE_NAME = self.control:GetName() .. ZO_GAMEPAD_MARKET_PRODUCT_BUNDLE_COLLECTIBLE_ATTACHMENT_TEMPLATE
    
    local function ResetMarketProduct(marketProduct)
        marketProduct:Reset()
    end
    
    local function CreateMarketItemProduct(objectPool)
        return ZO_GamepadMarketProductBundleItemAttachment:New(objectPool:GetNextControlId(), self.currentCategoryControl, self, BUNDLE_ITEM_NAME)
    end

    self.marketItemProductPool = ZO_ObjectPool:New(CreateMarketItemProduct, ResetMarketProduct)

    local function CreateMarketCollectibleProduct(objectPool)
        return ZO_GamepadMarketProductBundleCollectibleAttachment:New(objectPool:GetNextControlId(), self.currentCategoryControl, self, BUNDLE_COLLECTIBLE_NAME)
    end

    self.marketCollectibleProductPool = ZO_ObjectPool:New(CreateMarketCollectibleProduct, ResetMarketProduct)
    
    self:InitializeBlankProductPool()
end

function GamepadMarketBundleContents:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self:OnShowing()
    elseif newState == SCENE_SHOWN then
        self:OnShown()
    elseif newState == SCENE_HIDDEN then
        self:OnHiding()
    end
end

function GamepadMarketBundleContents:PerformDeferredInitialization()
    if not self.isInitialized then
        self.titleControl = self.header:GetNamedChild("TitleContainerTitle")

        local function RefreshOnPurchase()
            self:RefreshProducts()
        end

        local function QueueTutorial(_, purchasedConsumables)
            if purchasedConsumables then
                self:SetQueuedTutorial(TUTORIAL_TRIGGER_CROWN_CONSUMABLE_PURCHASED)
            end
        end

        GAMEPAD_MARKET_BUNDLE_CONTENTS_SCENE:GetSceneGroup():RegisterCallback("StateChange", function(oldState, newState)
            if newState == SCENE_GROUP_SHOWING then
                self:OnInitialInteraction()
            elseif newState == SCENE_GROUP_HIDDEN then
                self:OnEndInteraction()
            end
        end)

        self.keybindStripDescriptors =
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            {
                name = GetString(SI_MARKET_PURCHASE_BUNDLE_KEYBIND_TEXT),
                keybind = "UI_SHORTCUT_PRIMARY",
                visible = function()
                    return self.bundle ~= nil and not self.bundle:IsPurchaseLocked()
                end,
                enabled = function() return not self:HasQueuedTutorial() end,
                callback = function()
                    self.prePurchaseSelectedIndex = self.focusList:GetSelectedIndex()
                    self:BeginPurchase(self.bundle, RefreshOnPurchase, QueueTutorial)
                end,
            },
            {
                alignment = KEYBIND_STRIP_ALIGN_CENTER,
                name =  GetString(SI_MARKET_PREVIEW_KEYBIND_TEXT),
                keybind = "UI_SHORTCUT_SECONDARY",
                visible = function()
                    return self.selectedMarketProduct ~= nil and self.bundle ~= nil and self.selectedMarketProduct:HasPreview() and IsCharacterPreviewingAvailable()
                end,
                callback = function() self:BeginPreview() end
            },
            MARKET_BUY_CROWNS_BUTTON,
            KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor()
        }

        self.isInitialized = true
    end
end

function GamepadMarketBundleContents:SetBundle(bundle)
    self.bundle = bundle 
    self.headerData.titleText = bundle.title:GetText()
end

do
    local BLANK_HINT = ""
    local IS_PURCHASEABLE = true
    local IS_NOT_BUNDLE = false
    function GamepadMarketBundleContents:LayoutBundleProducts(bundle)
        self:ClearProducts()
        self:PrepareGridForBuild(ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCTS_PER_ROW, ZO_GAMEPAD_MARKET_PRODUCTS_PER_COLUMN, ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_WIDTH, ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_HEIGHT, ZO_GAMEPAD_MARKET_PRODUCT_PADDING, IS_NOT_BUNDLE)

        local bundleId = bundle:GetId()
        local numProducts = bundle:GetNumAttachedItems()

        for i = 1, numProducts do
            local id, iconFile, name, itemQuality, requiredLevel, itemCount = GetMarketProductItemInfo(bundleId, i)
            local background = GetMarketProductItemGamepadBackground(bundleId, i)
            local marketProduct = self.marketItemProductPool:AcquireObject()
            local marketControl = marketProduct:GetControl()
            local itemLink = GetMarketProductItemLink(bundleId, i)

            marketProduct:SetBundle(bundle)
            marketProduct:ShowAsBundleItem(id, iconFile, name, itemQuality, requiredLevel, itemCount, itemLink, i, background)
            self:AddEntry(marketProduct, marketControl)
        end

        local numCollectibles = bundle:GetNumAttachedCollectibles() 
        for i = 1, numCollectibles do
            local collectibleId, iconFile, name, type, description, owned, isPlaceholder = GetMarketProductCollectibleInfo(bundleId, i)
            local unlockState = GetCollectibleUnlockStateById(collectibleId)
            local background = GetMarketProductCollectibleGamepadBackground(bundleId, i)
            local marketProduct = self.marketCollectibleProductPool:AcquireObject()
            local marketControl = marketProduct:GetControl()
            local categoryName = GetString("SI_COLLECTIBLECATEGORYTYPE", type)
            local layoutArgs = { categoryName, name, nil, unlockState, IS_PURCHASEABLE, description, BLANK_HINT, isPlaceholder }

            marketProduct:SetBundle(bundle)
            marketProduct:ShowAsBundleCollectible(collectibleId, iconFile, name, owned, layoutArgs, i, background)
            self:AddEntry(marketProduct, marketControl)
        end
        
        self:FinishRowWithBlankTiles()
        self:FinishBuild()
    end
end

function GamepadMarketBundleContents:OnShowing()
    ZO_GamepadMarket_GridScreen.OnShowing(self)
    self:LayoutBundleProducts(self.bundle)
    self.titleControl:SetText(self.headerData.titleText)
    self:SelectAfterPreview()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptors)
    self:Activate()
    if self.prePurchaseSelectedIndex then
        self.focusList:SetFocusByIndex(self.prePurchaseSelectedIndex)
        self.prePurchaseSelectedIndex = nil
    end
end

function GamepadMarketBundleContents:OnShown()
    g_activeMarketScreen = ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS
    ZO_GamepadMarket_GridScreen.OnShown(self)
    self:RefreshKeybinds()
end

function GamepadMarketBundleContents:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptors)
    self:Deactivate()
end

function GamepadMarketBundleContents:LayoutSelectedMarketProduct()
    self.selectedMarketProduct:LayoutTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function GamepadMarketBundleContents:OnSelectionChanged(selectedData)
    ZO_GamepadMarket_GridScreen.OnSelectionChanged(self, selectedData)
    local previouslySelectedMarketProduct = self.selectedMarketProduct
    if selectedData then
        self.selectedMarketProduct = selectedData.marketProduct
        self:LayoutSelectedMarketProduct()
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        self.selectedMarketProduct = nil
    end

    self:UpdatePreviousAndNewlySelectedProducts(previouslySelectedMarketProduct, self.selectedMarketProduct)
    self:RefreshKeybinds()
end

function GamepadMarketBundleContents:OnInitialInteraction()
    self:ClearPreviewVars()
end

function GamepadMarketBundleContents:OnEndInteraction()
    self:ClearPreviewVars()
    self.prePurchaseSelectedIndex = nil
end

function GamepadMarketBundleContents:ReleaseAllProducts()
    self.marketCollectibleProductPool:ReleaseAllObjects()
    self.marketItemProductPool:ReleaseAllObjects()
    self.blankTilePool:ReleaseAllObjects()
end

--
-- [[ Market Locked Screen ]]--
--

local GamepadMarketLockedScreen = ZO_Object:New()

function GamepadMarketLockedScreen:New(...)
    local locked = ZO_Object.New(self)
    locked:Initialize(...)
    return locked
end

function GamepadMarketLockedScreen:Initialize(control)
    control.owner = self
    self.control = control

    self.keybindStripDescriptors =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor()
    }

    ZO_GAMEPAD_MARKET_LOCKED_SCENE = ZO_RemoteScene:New(ZO_GAMEPAD_MARKET_LOCKED_SCENE_NAME, SCENE_MANAGER)
    ZO_GAMEPAD_MARKET_LOCKED_SCENE:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)
end

function GamepadMarketLockedScreen:OnStateChanged(oldState, newState)
    if(newState == SCENE_SHOWN) then
        ZO_GamepadMarketKeybindStrip_RefreshStyle()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptors)
    elseif(newState == SCENE_HIDDEN) then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptors)
        KEYBIND_STRIP:SetStyle(KEYBIND_STRIP_STANDARD_STYLE)
    end
end

function GamepadMarketLockedScreen:OnMarketOpen()
    if ZO_GAMEPAD_MARKET_LOCKED_SCENE:IsShowing() then
        SCENE_MANAGER:SwapCurrentScene(ZO_GAMEPAD_MARKET_SCENE_NAME)
    end
end

--
-- [[ Market Pre Scene ]]--
--

local GamepadMarketPreScene = ZO_Object:New()

function GamepadMarketPreScene:New(...)
    local preScene = ZO_Object.New(self)
    preScene:Initialize(...)
    return preScene
end

function GamepadMarketPreScene:Initialize(control)
    self.control = control

    self.keybindStripDescriptors =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor()
    }

    ZO_GAMEPAD_MARKET_PRE_SCENE = ZO_RemoteScene:New(ZO_GAMEPAD_MARKET_PRE_SCENE_NAME, SCENE_MANAGER)
    ZO_GAMEPAD_MARKET_PRE_SCENE:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)
end

function GamepadMarketPreScene:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWN then
        self:OnShown()
    elseif newState == SCENE_HIDING then
        self:OnHiding()
    end
end

function GamepadMarketPreScene:OnShown()
    self.marketState = GetMarketState()
    self.loadingStartTime = nil
    EVENT_MANAGER:RegisterForEvent(ZO_GAMEPAD_MARKET_PRE_SCENE_NAME, EVENT_MARKET_STATE_UPDATED, function(eventId, ...) self:OnMarketStateUpdated(...) end)
    EVENT_MANAGER:RegisterForUpdate(ZO_GAMEPAD_MARKET_PRE_SCENE_NAME, 0, function(...) self:OnUpdate(...) end)
    ZO_MARKET_SINGLETON:RequestOpenMarket()
    SetSecureRenderModeEnabled(true)

    if self.marketState ~= MARKET_STATE_UNKNOWN then
        self:SwapToMarketScene()
    end
end

function GamepadMarketPreScene:OnHiding()
    SetSecureRenderModeEnabled(false)
    EVENT_MANAGER:UnregisterForUpdate(ZO_GAMEPAD_MARKET_PRE_SCENE_NAME)
    EVENT_MANAGER:UnregisterForEvent(ZO_GAMEPAD_MARKET_PRE_SCENE_NAME, EVENT_MARKET_STATE_UPDATED)
    ZO_GAMEPAD_MARKET_PRE_SCENE:RemoveFragment(GAMEPAD_MARKET_PRE_SCENE_FRAGMENT)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptors)
end

function GamepadMarketPreScene:OnMarketStateUpdated(marketState)
    self.marketState = marketState
    self:SwapToMarketScene()
end

function GamepadMarketPreScene:OnUpdate(currentMs)
    if self.loadingStartTime == nil then
        self.loadingStartTime = currentMs
    end

    if currentMs - self.loadingStartTime >= ZO_MARKET_DISPLAY_LOADING_DELAY_MS then
        -- show the loading text
        ZO_GAMEPAD_MARKET_PRE_SCENE:AddFragment(GAMEPAD_MARKET_PRE_SCENE_FRAGMENT)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptors)
    end
end

function GamepadMarketPreScene:SwapToMarketScene()
    if ZO_GAMEPAD_MARKET_PRE_SCENE:IsShowing() then
        if self.marketState == MARKET_STATE_OPEN then
            SCENE_MANAGER:SwapCurrentScene(ZO_GAMEPAD_MARKET_SCENE_NAME)
        else
            SCENE_MANAGER:SwapCurrentScene(ZO_GAMEPAD_MARKET_LOCKED_SCENE_NAME)
        end
    end
end

--
--[[ XML Handlers ]]--
--
function ZO_Market_Gamepad_OnInitialize(control)
    ZO_GAMEPAD_MARKET = GamepadMarket:New(control)
    SYSTEMS:RegisterGamepadObject(ZO_MARKET_NAME, ZO_GAMEPAD_MARKET)
end

function ZO_GamepadMarket_BundleContents_OnInitialize(control)
    ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS = GamepadMarketBundleContents:New(control)
end

function ZO_GamepadMarket_Preview_OnInitialize(control)
    ZO_GAMEPAD_MARKET_PREVIEW = GamepadMarketPreview:New(control)
end

function ZO_GamepadMarket_Locked_OnInitialize(control)
    ZO_GAMEPAD_MARKET_LOCKED = GamepadMarketLockedScreen:New(control)
end

function ZO_GamepadMarket_PreScene_OnInitialize(control)
    ZO_MARKET_PRE_SCENE = GamepadMarketPreScene:New(control)
end