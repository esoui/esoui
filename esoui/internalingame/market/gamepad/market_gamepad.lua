ZO_GAMEPAD_MARKET_SCENE_NAME  = "gamepad_market"
ZO_GAMEPAD_MARKET_PREVIEW_SCENE_NAME = "gamepad_market_preview"
ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS_SCENE_NAME = "gamepad_market_bundle_contents"
ZO_GAMEPAD_MARKET_LOCKED_SCENE_NAME = "gamepad_market_locked"
ZO_GAMEPAD_MARKET_PRE_SCENE_NAME = "gamepad_market_pre_scene"

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

    local function CreateButtonIcon(name, parent, keycode)
        local buttonIcon = CreateControl(name, parent, CT_BUTTON)
        buttonIcon:SetNormalTexture(ZO_Keybindings_GetTexturePathForKey(keycode))
        buttonIcon:SetDimensions(ZO_TABBAR_ICON_WIDTH, ZO_TABBAR_ICON_HEIGHT)
        buttonIcon:SetHidden(true)
        return buttonIcon
    end

    self.variationLabel = control:GetNamedChild("VariationLabel")
    self.previewVariationLeftIcon = CreateButtonIcon("$(parent)PreviewLeftIcon", control, KEY_GAMEPAD_DPAD_LEFT)
    self.previewVariationRightIcon = CreateButtonIcon("$(parent)PreviewRightIcon", control, KEY_GAMEPAD_DPAD_RIGHT)

    self.previewVariationLeftIcon:SetAnchor(RIGHT, self.variationLabel, LEFT, -32)
    self.previewVariationRightIcon:SetAnchor(LEFT, self.variationLabel, RIGHT, 32)

    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)

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

function GamepadMarketPreview:UpdatePreviewedProduct(marketProduct)
    self.marketProduct = marketProduct
    if IsCharacterPreviewingAvailable() then
        self.marketProduct.variation = 1
        self.marketProduct:Preview()
    end

    if self.marketProduct:GetNumPreviewVariations() > 1 then
        self:SetMultiVariationPreviewIconsHidden(false)
        self.variationLabel:SetText(self.marketProduct:GetPreviewVariationDisplayName())
    else
        self:SetMultiVariationPreviewIconsHidden(true)
    end
    
    self:LayoutPreviewedProduct()
    self:SetCanChangePreview(false)
end

function GamepadMarketPreview:SetCanChangePreview(canChangePreview)
    self.canChangePreview = canChangePreview

    if canChangePreview then
        self.variationLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
    else
        self.variationLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptors)
end

function GamepadMarketPreview:MoveToPreviousPreviewProduct()
    self:UpdatePreviewedProduct(self.previewProductsContainer:MoveToPreviousPreviewProduct())
    self.lastSetChangeTime = GetFrameTimeMilliseconds()
end

function GamepadMarketPreview:MoveToNextPreviewProduct()
    self:UpdatePreviewedProduct(self.previewProductsContainer:MoveToNextPreviewProduct())
    self.lastSetChangeTime = GetFrameTimeMilliseconds()
end

function GamepadMarketPreview:SetPreviewProductsContainer(previewProductsContainer)
    self.previewProductsContainer = previewProductsContainer
end

function GamepadMarketPreview:PreviewNextVariation()
    self.marketProduct:PreviewNextVariation()
    self.variationLabel:SetText(self.marketProduct:GetPreviewVariationDisplayName())
    self.lastSetChangeTime = GetFrameTimeMilliseconds()
end

function GamepadMarketPreview:PreviewPreviousVariation()
    self.marketProduct:PreviewPreviousVariation()
    self.variationLabel:SetText(self.marketProduct:GetPreviewVariationDisplayName())
    self.lastSetChangeTime = GetFrameTimeMilliseconds()
end

function GamepadMarketPreview:UpdateDirectionalInput()
    if self.marketProduct then
        if self.marketProduct:GetNumPreviewVariations() > 0 and self.canChangePreview then
            local result = self.movementController:CheckMovement()
            if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
                self:PreviewNextVariation()
            elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
                self:PreviewPreviousVariation()
            end
        end
    end
end

do
    local PREVIEW_UPDATE_INTERVAL = 100
    local DONT_PREVIEW_PRODUCT = true
    function GamepadMarketPreview:OnShowing()
        self:Activate()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptors)
         -- Start the preview of the container's current object
        self:UpdatePreviewedProduct(self.previewProductsContainer:GetCurrentPreviewProduct())

        -- for the first preview we won't put a restriction on when we can preview the next one
        -- previewing a product automatically sets this to false so manually set it to true
        self:SetCanChangePreview(true)

        EVENT_MANAGER:RegisterForUpdate("GamepadMarketPreviewUpdate", PREVIEW_UPDATE_INTERVAL, function(...) self:OnUpdate(...) end)
    end
end

function GamepadMarketPreview:OnShown()
    g_activeMarketScreen = ZO_GAMEPAD_MARKET_PREVIEW
end

function GamepadMarketPreview:OnHidden()
    EVENT_MANAGER:UnregisterForUpdate("GamepadMarketPreviewUpdate")
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptors)
    self:Deactivate()
    self.marketProduct = nil
    self.previewProductsContainer = nil
    self:SetMultiVariationPreviewIconsHidden(true)
end

function GamepadMarketPreview:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self:OnShowing()
    elseif newState == SCENE_SHOWN then
        self:OnShown()
    elseif newState == SCENE_HIDDEN then
        self:OnHidden()
    end
end

function GamepadMarketPreview:OnUpdate(ms)
    if not self.canChangePreview and (ms - self.lastSetChangeTime) > ZO_MARKET_PREVIEW_WAIT_TIME_MS then
        self.lastSetChangeTime = ms
        self:SetCanChangePreview(true)
    end
end

function GamepadMarketPreview:Activate()
    DIRECTIONAL_INPUT:Activate(self, self.control)
    BeginPreviewMode()
    BeginItemPreviewSpin()
end

function GamepadMarketPreview:Deactivate()
    DIRECTIONAL_INPUT:Deactivate(self)
    EndItemPreviewSpin()
    EndCurrentMarketPreview()
    EndPreviewMode()
end

function GamepadMarketPreview:SetMultiVariationPreviewIconsHidden(shouldHide)
    self.variationLabel:SetHidden(shouldHide)
    self.previewVariationLeftIcon:SetHidden(shouldHide)
    self.previewVariationRightIcon:SetHidden(shouldHide)
end

--
--[[ Gamepad Market ]]--
--

local GamepadMarket = ZO_Object.MultiSubclass(ZO_GamepadMarket_GridScreen, ZO_Market_Shared)

function GamepadMarket:New(...)
    return ZO_Market_Shared.New(self, ...)
end

function GamepadMarket:Initialize(control)
    local EMPTY_TAB_HEADER = {}
    ZO_GamepadMarket_GridScreen.Initialize(self, control, ZO_GAMEPAD_MARKET_BUNDLE_PRODUCTS_PER_ROW, ZO_GAMEPAD_MARKET_PRODUCTS_PER_COLUMN, EMPTY_TAB_HEADER)
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
    if self.isInitialized then
        return
    end

    self.isLockedForCategoryRefresh = false
    self.OnGamepadDialogHidden = function()
        self:AnchorCurrentCategoryControlToScrollChild()
    end
    self.subCategoryDataMarketProductIdMap = {} -- Used to map product IDs to product subcategories during category building
    self.subCategoryLabeledGroupTableMap = {} -- Used to lookup subcategory "LabeledGroup" tables during category building

    self.subscriptionBenefitLinePool = ZO_ControlPool:New("ZO_GamepadMarket_SubscriptionBenefitLine", self.control)

    self.isInitialized = true
end

function GamepadMarket:GetLabeledGroupLabelTemplate()
    return GAMEPAD_MARKET_LABELED_GROUP_LABEL_TEMPLATE
end

function GamepadMarket:LayoutSelectedMarketProduct()
    local marketProduct = self.selectedMarketProduct
    if marketProduct ~= nil and not marketProduct:IsBlank() then
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
    SetSecureRenderModeEnabled(true)

    -- ensure that we are in the correct state
    if self.marketState ~= GetMarketState() then
        self:UpdateMarket()
    elseif self.marketState == MARKET_STATE_OPEN then
        self:UpdateCurrentCategory()
    end
    
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

        if self.queuedMarketProductId then
            self:ShowMarketProduct(self.queuedMarketProductId)
            self.queuedMarketProductId = nil
        end
    else
        self:OnMarketLocked()
    end

    ForceCancelMounted()
end

function GamepadMarket:OnHiding()
    ZO_Market_Shared.OnHiding(self)
    if self.currentCategoryData then
        -- just fade out because we are hiding
        self.currentCategoryData.fragment:SetDirection(ZO_GAMEPAD_MARKET_PAGE_NO_DIRECTION)
    end

    self.queuedTutorial = nil
    ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS:SetQueuedTutorial(nil)

    self.currentCategoryControl = nil
    self:Deactivate()
    self:RemoveKeybinds()
    CALLBACK_MANAGER:UnregisterCallback("OnGamepadDialogHidden", self.OnGamepadDialogHidden)
end

function GamepadMarket:InitializeKeybindDescriptors()
    local function RefreshOnPurchase() -- Only called on transaction success
        self.selectedMarketProduct:Refresh()
    end

    local function OnPurchaseEnd(reachedConfirmationScene, purchasedConsumables, triggerTutorialOnPurchase)
        self.isLockedForCategoryRefresh = reachedConfirmationScene

        if purchasedConsumables then
            self:SetQueuedTutorial(TUTORIAL_TRIGGER_CROWN_CONSUMABLE_PURCHASED)
        end

        -- Check if an item triggers a tutorial on purchase second, since that takes priority over the consumable tutorial
        if triggerTutorialOnPurchase then
            self:SetQueuedTutorial(triggerTutorialOnPurchase)
        end

        -- We push the purchase scene when we reach the confirmation step
        -- So when we show the market again we will reactivate. 
        -- Otherwise, we need to reactivate since we are just hiding a dialog.
        if not reachedConfirmationScene then
            self:Activate()
        end
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
                            local marketProduct = self.selectedMarketProduct
                            if marketProduct ~= nil then
                                if marketProduct:IsBundle() then
                                    return not marketProduct:GetHidesChildProducts()
                                else
                                    return not self.selectedMarketProduct:IsBlank()
                                end
                            end
                            return false
                        end,
            enabled =   function()
                            local marketProduct = self.selectedMarketProduct
                            if marketProduct ~= nil then
                                if marketProduct:HasPreview() and IsCharacterPreviewingAvailable() then
                                    return true
                                elseif marketProduct:IsBundle() then
                                    return true
                                end
                            end
                            return false
                        end,
            callback =  function()
                            local marketProduct = self.selectedMarketProduct
                            if marketProduct:IsBundle() then
                                self:ShowBundleContents(marketProduct)
                            else
                                self:BeginPreview()
                            end
                        end,
        },
        MARKET_BUY_CROWNS_BUTTON,
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
    }

    self.esoPluskeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_MARKET_BUY_PLUS_KEYBIND_LABEL),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = ZO_GamepadMarket_ShowBuyPlusDialog,
            visible = function() return not IsESOPlusSubscriber() end,
        },
        MARKET_BUY_CROWNS_BUTTON,
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
    }
end

function GamepadMarket:GetPrimaryButtonDescriptor()
    return self.primaryButtonDescriptor
end

function GamepadMarket:BeginPreview()
    self.isLockedForCategoryRefresh = true
    self.currentCategoryData.fragment:SetDirection(ZO_GAMEPAD_MARKET_PAGE_NO_DIRECTION)
    ZO_GamepadMarket_GridScreen.BeginPreview(self)
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
            
            if data.type == ZO_MARKET_CATEGORY_TYPE_FEATURED then
                self:BuildFeaturedMarketProductList()
            elseif data.type == ZO_MARKET_CATEGORY_TYPE_ESO_PLUS then
                self:DisplayEsoPlusOffer()
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
                if not self.isLockedForCategoryRefresh then
                    lastCategoryControl:ClearAnchors()
                    lastCategoryControl:SetAnchorFill(self.contentContainer)
                end
                
                SCENE_MANAGER:RemoveFragment(self.lastCategoryData.fragment)
            end

            if not self.isLockedForCategoryRefresh then
                self.currentCategoryControl:ClearAnchors()
                self.currentCategoryControl:SetAnchorFill(self.contentContainer)
            end
            
            SCENE_MANAGER:AddFragment(data.fragment)
        end

        if not self.isLockedForCategoryRefresh then
            local categoryIndex, subCategoryIndex
            -- faked category types don't have real category indices so keep them as nil
            if data.type == ZO_MARKET_CATEGORY_TYPE_NONE then
                if data.parentData then
                    categoryIndex = data.parentData.categoryIndex
                    subCategoryIndex = data.categoryIndex
                else
                    categoryIndex = data.categoryIndex
                end
            end

            OnMarketCategorySelected(categoryIndex, subCategoryIndex)
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
    local GAMEPAD_MARKET_ESO_PLUS_CATEGORY_TEMPLATE = "ZO_GamepadMarket_EsoPlusCategoryTemplate"
    local function GetOrCreateCategoryControl(parent, marketCategoryIndex, categoryType)
        local currentControlName = GAMEPAD_MARKET_CATEGORY_TEMPLATE
        if marketCategoryIndex and marketCategoryIndex > 0 then
            currentControlName = currentControlName .. marketCategoryIndex
        else -- this is a faked category
            currentControlName = currentControlName .. categoryType
        end

        local currentControl = GetControl(currentControlName)

        if currentControl ~= nil then
            return currentControl
        else
            if categoryType == ZO_MARKET_CATEGORY_TYPE_ESO_PLUS then
                return CreateControlFromVirtual(currentControlName, parent, GAMEPAD_MARKET_ESO_PLUS_CATEGORY_TEMPLATE)
            else
                return CreateControlFromVirtual(currentControlName, parent, GAMEPAD_MARKET_CATEGORY_TEMPLATE)
            end
        end
    end

    local ALWAYS_ANIMATE = true
    local function CreateCategoryData(name, parent, marketCategoryIndex, tabIndex, numSubCategories, categoryType)
        categoryType = categoryType or ZO_MARKET_CATEGORY_TYPE_NONE
        local control = GetOrCreateCategoryControl(parent, marketCategoryIndex, categoryType)
        return {
            text = name,
            control = control,
            subCategories = {},
            numSubCategories = numSubCategories,
            soundId = SOUNDS.MARKET_CATEGORY_SELECTED,
            categoryIndex = marketCategoryIndex, -- Market category index used for def lookup
            tabIndex = tabIndex, -- Index in the tab header, as displayed. This can be different from the market category index when there are faked categories
            type = categoryType,
            fragment = ZO_GamepadMarketPageFragment:New(control, ALWAYS_ANIMATE)
        }
    end

    function GamepadMarket:AddTopLevelCategory(categoryIndex, tabIndex, name, numSubCategories, categoryType)
        name = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, name)
        
        local categoryData = CreateCategoryData(name, self.contentContainer.scrollChild, categoryIndex, tabIndex, numSubCategories, categoryType)

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
            categoryData = categoryData,
            callback = function()
                self:OnCategorySelected(categoryData)
            end,
        }

        table.insert(self.headerData.tabBarEntries, tabEntry)
    end
end

do
    local currentTabIndex = FIRST_CATEGORY_INDEX
    local function GetFirstTabIndex()
        currentTabIndex = FIRST_CATEGORY_INDEX
        return currentTabIndex
    end

    local function GetNextTabIndex()
        currentTabIndex = currentTabIndex + 1
        return currentTabIndex
    end

    local ZERO_SUBCATEGORIES = 0
    function GamepadMarket:BuildCategories(control)
        if self.marketState == MARKET_STATE_OPEN then
            ZO_ClearTable(self.headerData.tabBarEntries)

            local firstIndex = GetFirstTabIndex()

            local numFeaturedMarketProducts = GetNumFeaturedMarketProducts()
            local hasFeaturedCategory = numFeaturedMarketProducts > 0
            if hasFeaturedCategory then
                self:AddTopLevelCategory(ZO_MARKET_FEATURED_CATEGORY_INDEX, firstIndex, GetString(SI_MARKET_FEATURED_CATEGORY), ZERO_SUBCATEGORIES, ZO_MARKET_CATEGORY_TYPE_FEATURED)
            end

            local esoPlusIndex = hasFeaturedCategory and GetNextTabIndex() or firstIndex
            self:AddTopLevelCategory(ZO_MARKET_ESO_PLUS_CATEGORY_INDEX, esoPlusIndex, GetString(SI_MARKET_ESO_PLUS_CATEGORY), ZERO_SUBCATEGORIES, ZO_MARKET_CATEGORY_TYPE_ESO_PLUS)

            -- adding in the custom categories offsets our market product cateogry indices
            -- so even though a category is index 1 from data, it might actually be index 3
            -- since we show a featured and ESO Plus category
            self.categoryIndexOffset = esoPlusIndex

            local numCategories = GetNumMarketProductCategories()
            for i = 1, numCategories do
                local name, numSubCategories = GetMarketProductCategoryInfo(i)
                self:AddTopLevelCategory(i, GetNextTabIndex(), name, numSubCategories)
            end

            self.categoriesInitialized = true

            self.refreshCategories = false
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

-- override from ZO_GamepadMarket_GridScreen
function GamepadMarket:FinishBuild()
    self:FinishCurrentLabeledGroup() -- must come before call to parent's FinishBuild
    ZO_GamepadMarket_GridScreen.FinishBuild(self)
    self:RefreshKeybinds()
end

-- override from ZO_GamepadMarket_GridScreen
function GamepadMarket:EndCurrentPreview()
    ZO_GamepadMarket_GridScreen.EndCurrentPreview(self)
    self:RefreshKeybinds()
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

function GamepadMarket:FindSubCategoryLabeledGroupTable(categoryIndex)
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

function GamepadMarket:ClearMarketProducts()
    self:ClearProducts()
    self:ClearLabeledGroups(self)
end

function GamepadMarket:UpdateCategoryAnimationDirection()
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
    else -- we don't have a last category or its the same as the current so no need to animate
        direction = ZO_GAMEPAD_MARKET_PAGE_NO_DIRECTION
    end

    if self.lastCategoryData then
        self.lastCategoryData.fragment:SetDirection(direction)
    end
    
    self.currentCategoryData.fragment:SetDirection(self.isLockedForCategoryRefresh and ZO_GAMEPAD_MARKET_PAGE_NO_DIRECTION or direction)
end

function GamepadMarket:SetCurrentKeybinds(keybindDescriptor)
    if keybindDescriptor ~= self.currentKeybindDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindDescriptor)
        KEYBIND_STRIP:AddKeybindButtonGroup(keybindDescriptor)

        self.currentKeybindDescriptor = keybindDescriptor
    end
end

function GamepadMarket:DisplayEsoPlusOffer()
    self:ClearMarketProducts()

    self:SetCurrentKeybinds(self.esoPluskeybindStripDescriptor)

    self:ResetGrid()

    local overview, image = GetMarketSubscriptionGamepadInfo()

    local control = self.currentCategoryData.control
    control:GetNamedChild("Overview"):SetText(overview)
    control:GetNamedChild("MembershipInfoBanner"):SetTexture(image)

    local lineContainer = control:GetNamedChild("BenefitsLineContainer")

    self.subscriptionBenefitLinePool:ReleaseAllObjects()

    local numLines = GetNumGamepadMarketSubscriptionBenefitLines()
    local numLeftSideLines = zo_ceil(numLines / 2) -- do it this way so if we have 7 bullets 4 are on the left and 3 on the right
    local firstRightSideLineIndex = numLeftSideLines + 1
    local controlToAnchorTo = lineContainer
    for i = 1, numLines do
        local line = GetGamepadMarketSubscriptionBenefitLine(i);
        local benefitLine = self.subscriptionBenefitLinePool:AcquireObject()
        benefitLine:SetText(line)
        benefitLine:ClearAnchors()
        if i == 1 then -- first left side line
            benefitLine:SetAnchor(TOPLEFT, lineContainer, TOPLEFT, 0, 4)
            benefitLine:SetAnchor(TOPRIGHT, lineContainer, CENTER, 0, 4)
        else
            --rest of the left side
            if i <= numLeftSideLines then
                benefitLine:SetAnchor(TOPLEFT, controlToAnchorTo, BOTTOMLEFT, 0, 4)
                benefitLine:SetAnchor(TOPRIGHT, controlToAnchorTo, BOTTOMRIGHT, 0, 4)
            else
                -- right side layout
                if i == firstRightSideLineIndex then
                    benefitLine:SetAnchor(TOPLEFT, lineContainer, CENTER, 0, 4)
                    benefitLine:SetAnchor(TOPRIGHT, lineContainer, TOPRIGHT, 0, 4)
                else
                    benefitLine:SetAnchor(TOPLEFT, controlToAnchorTo, BOTTOMLEFT, 0, 4)
                    benefitLine:SetAnchor(TOPRIGHT, controlToAnchorTo, BOTTOMRIGHT, 0, 4)
                end
            end
        end
        benefitLine:SetParent(lineContainer)
        controlToAnchorTo = benefitLine
    end

    local isSubscribed = IsESOPlusSubscriber()
    local statusText = isSubscribed and SI_MARKET_SUBSCRIPTION_PAGE_SUBSCRIPTION_STATUS_ACTIVE or SI_MARKET_SUBSCRIPTION_PAGE_SUBSCRIPTION_STATUS_NOT_ACTIVE

    control:GetNamedChild("MembershipInfoStatus"):SetText(GetString(statusText))

    self:UpdateCategoryAnimationDirection()

    ZO_GamepadMarket_GridScreen.FinishBuild(self)
end

function GamepadMarket:LayoutMarketProducts(...)
    self:SetCurrentKeybinds(self.keybindStripDescriptors)

    self:ClearMarketProducts()

    local numProducts = select("#", ...)
    local productsPerRow, productPadding, productWidth, productHeight

    productsPerRow, productPadding, productWidth, productHeight = ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCTS_PER_ROW, ZO_GAMEPAD_MARKET_PRODUCT_PADDING , ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_WIDTH, ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_HEIGHT

    local productsPerColumn = zo_ceil(numProducts / productsPerRow)
    self:PrepareGridForBuild(productsPerRow, productsPerColumn, productWidth, productHeight, productPadding)

    local categoryType = self.currentCategoryData.type

    for i = 1, numProducts do
        local id = select(i, ...)
        local marketProduct = self.currentCategoryMarketProductPool:AcquireObject()
        marketProduct:Show(id)
        local name, description, cost, discountedCost, discountPercent, icon, isNew, isFeatured = marketProduct:GetMarketProductInfo()

        -- durations longer than 1 month aren't represented to the user, so it's effectively not limited time
        local isLimitedTime = marketProduct:IsLimitedTimeProduct()
        local doesContainDLC = DoesMarketProductContainDLC(id)

        if doesContainDLC and categoryType == ZO_MARKET_CATEGORY_TYPE_FEATURED then
            self:AddProductToLabeledGroupTable(self.dlcProducts, name, marketProduct)
        else
            if isLimitedTime then
                self:AddProductToLabeledGroupTable(self.limitedTimedOfferProducts, name, marketProduct)
            elseif isFeatured then
                self:AddProductToLabeledGroupTable(self.featuredProducts, name, marketProduct)
            else
                self:AddMarketProductToLabeledGroupOrGeneralGroup(name, marketProduct, id)
            end
        end
    end

    self:AddLabeledGroupTable(GetString(SI_MARKET_LIMITED_TIME_OFFER_CATEGORY), self.limitedTimedOfferProducts)
    self:AddLabeledGroupTable(GetString(SI_MARKET_DLC_CATEGORY), self.dlcProducts)
    self:AddLabeledGroupTable(GetString(SI_MARKET_FEATURED_CATEGORY), self.featuredProducts)

    if categoryType == ZO_MARKET_CATEGORY_TYPE_FEATURED then
        self:AddLabeledGroupTable(GetString(SI_MARKET_ALL_LABEL), self.marketProducts)
    else
        local sortedSubcategories = CreateSortedSubcategoryList(self.subCategoryLabeledGroupTableMap)
        for categoryIndex, subcategoryInfo in ipairs(sortedSubcategories) do
            local subCategoryName = subcategoryInfo.data.text
            self:AddLabeledGroupTable(subCategoryName, subcategoryInfo.groupTable)
        end

        self:AddLabeledGroupTable(GetString(SI_MARKET_ALL_LABEL), self.marketProducts)
    end

    self:UpdateCategoryAnimationDirection()

    self:FinishBuild()
end

function GamepadMarket:OnMarketOpen()
    if ZO_GAMEPAD_MARKET_LOCKED then -- This can be called before the lock screen has been initialized
        ZO_GAMEPAD_MARKET_LOCKED:OnMarketOpen()
    end

    if self.isInitialized then
        ZO_GamepadMarket_GridScreen.OnShowing(self)

        if not self.categoriesInitialized or self.refreshCategories then
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


function GamepadMarket:GetCategoryDataFromId(productId)
    for i = 1, #self.featuredProducts do
        if self.featuredProducts[i].product:GetId() == productId then
            return self.featuredProducts[i]
        end
    end

    local numSubCategories = self.currentCategoryData.numSubCategories
    for subcategoryIndex = 1, numSubCategories do
        local subCategoryProducts = self:FindSubCategoryLabeledGroupTable(subcategoryIndex)
        for productIndex = 1, #subCategoryProducts do
            if subCategoryProducts[productIndex].product.marketProductId == productId then
                return subCategoryProducts[productIndex]
            end
        end
    end
end

function GamepadMarket:RequestShowMarketProduct(id)
    self.queuedMarketProductId = id
end

function GamepadMarket:ShowMarketProduct(id)
    local data = self:GetCategoryDataForMarketProduct(id)
    if data then
        local targetIndex = data.tabIndex
        if self.header.tabBar:GetSelectedIndex() ~= targetIndex then
            self.header.tabBar:SetSelectedDataIndex(targetIndex)
        end

        local targetMarketProduct = self:GetCategoryDataFromId(id)
        if targetMarketProduct then
            self:ScrollToGridEntry(targetMarketProduct.product:GetFocusData(), true)
            local listIndex = targetMarketProduct.product:GetListIndex()
            self.focusList:SetFocusByIndex(listIndex)
        end
    end
end

function GamepadMarket:GetCategoryData(categoryIndex)
    local categoryTable = self.headerData.tabBarEntries[categoryIndex + self.categoryIndexOffset]
    if categoryTable ~= nil then
        return categoryTable.categoryData
    end
end

-- overrides from ZO_Market_Shared

function GamepadMarket:AddKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.currentKeybindDescriptor)
end

function GamepadMarket:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeybindDescriptor)
end

function GamepadMarket:RefreshKeybinds()
    ZO_GamepadMarketKeybindStrip_RefreshStyle()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindDescriptor)
end

--
-- [[ Market Product Tooltip ]]--
--

do
    local MarketTooltipMixin = {}
    do
        local BUNDLE_HEADER = GetString(SI_MARKET_PRODUCT_TOOLTIP_BUNDLE)
        local DLC_HEADER = GetString(SI_MARKET_PRODUCT_TOOLTIP_DLC)
        local UPGRADE_HEADER = GetString(SI_MARKET_PRODUCT_TOOLTIP_UPGRADE)
        local UNLOCK_LABEL = GetString(SI_MARKET_PRODUCT_TOOLTIP_UNLOCK)
        local SERVICE_HEADER = GetString(SI_SERVICE_TOOLTIP_TYPE)

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

            local productType = product:GetProductType()
            -- Category
            if productType == MARKET_PRODUCT_TYPE_BUNDLE then
                if DoesMarketProductContainDLC(productId) and GetMarketProductNumBundledProducts(productId) == 1 then
                    topSection:AddLine(DLC_HEADER)
                else
                    topSection:AddLine(BUNDLE_HEADER)
                end
            elseif productType == MARKET_PRODUCT_TYPE_INSTANT_UNLOCK and instantUnlockType ~= MARKET_INSTANT_UNLOCK_NONE then
                if IsMarketInstantUnlockServiceToken(instantUnlockType) then
                    topSection:AddLine(SERVICE_HEADER)
                else
                    topSection:AddLine(UPGRADE_HEADER)
                end
            end

            self:AddSection(topSection)

            -- Name
            self:AddLine(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, product.name), qualityNormal, self:GetStyle("title"))

            local tooltipLines = {}
            if IsMarketInstantUnlockUpgrade(instantUnlockType) then
                local statsSection = self:AcquireSection(self:GetStyle("baseStatsSection"))
                local statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
                statValuePair:SetStat(UNLOCK_LABEL, self:GetStyle("statValuePairStat"))
            
                local currentUnlock
                local maxUnlock
                local unlockDescription

                if instantUnlockType == MARKET_INSTANT_UNLOCK_PLAYER_BACKPACK then
                    currentUnlock = GetCurrentBackpackUpgrade()
                    maxUnlock = GetMaxBackpackUpgrade()
                    unlockDescription = zo_strformat(SI_MARKET_PRODUCT_TOOLTIP_BACKPACK_UPGRADE_DESCRIPTION, GetNumBackpackSlotsPerUpgrade())
                elseif instantUnlockType == MARKET_INSTANT_UNLOCK_PLAYER_BANK then
                    currentUnlock = GetCurrentBankUpgrade()
                    maxUnlock = GetMaxBankUpgrade()
                    unlockDescription = zo_strformat(SI_MARKET_PRODUCT_TOOLTIP_BANK_UPGRADE_DESCRIPTION, GetNumBankSlotsPerUpgrade())
                elseif instantUnlockType == MARKET_INSTANT_UNLOCK_CHARACTER_SLOT then
                    currentUnlock = GetCurrentCharacterSlotsUpgrade()
                    maxUnlock = GetMaxCharacterSlotsUpgrade()
                    unlockDescription = zo_strformat(SI_MARKET_PRODUCT_TOOLTIP_CHARACTER_SLOT_UPGRADE_DESCRIPTION, GetNumCharacterSlotsPerUpgrade())
                end

                table.insert(tooltipLines, unlockDescription)

                statValuePair:SetValue(zo_strformat(SI_MARKET_PRODUCT_TOOLTIP_UNLOCK_LEVEL, currentUnlock, maxUnlock), self:GetStyle("statValuePairValue"))
                statsSection:AddStatValuePair(statValuePair)
                self:AddSection(statsSection)
            elseif IsMarketInstantUnlockServiceToken(instantUnlockType) then
                local tokenDescription
                local tokenUsageRequirement = GetString(SI_SERVICE_TOKEN_USAGE_REQUIREMENT_CHARACTER_SELECT)    -- All tokens only usable frm character select
                local tokenCountString

                if instantUnlockType == MARKET_INSTANT_UNLOCK_RENAME_TOKEN then
                    tokenDescription = GetString(SI_SERVICE_TOOLTIP_NAME_CHANGE_TOKEN_DESCRIPTION)
                    tokenCountString = zo_strformat(SI_SERVICE_TOOLTIP_SERVICE_TOKENS_AVAILABLE, GetNumServiceTokens(SERVICE_TOKEN_NAME_CHANGE), GetString("SI_SERVICETOKENTYPE", SERVICE_TOKEN_NAME_CHANGE))
                elseif instantUnlockType == MARKET_INSTANT_UNLOCK_RACE_CHANGE_TOKEN then
                    tokenDescription = GetString(SI_SERVICE_TOOLTIP_RACE_CHANGE_TOKEN_DESCRIPTION)
                    tokenCountString = zo_strformat(SI_SERVICE_TOOLTIP_SERVICE_TOKENS_AVAILABLE, GetNumServiceTokens(SERVICE_TOKEN_RACE_CHANGE), GetString("SI_SERVICETOKENTYPE", SERVICE_TOKEN_RACE_CHANGE))
                elseif instantUnlockType == MARKET_INSTANT_UNLOCK_APPEARANCE_CHANGE_TOKEN then
                    tokenDescription = GetString(SI_SERVICE_TOOLTIP_APPEARANCE_CHANGE_TOKEN_DESCRIPTION)
                    tokenCountString = zo_strformat(SI_SERVICE_TOOLTIP_SERVICE_TOKENS_AVAILABLE, GetNumServiceTokens(SERVICE_TOKEN_APPEARANCE_CHANGE), GetString("SI_SERVICETOKENTYPE", SERVICE_TOKEN_APPEARANCE_CHANGE))
                end

                table.insert(tooltipLines, tokenDescription)
                table.insert(tooltipLines, tokenUsageRequirement)
                table.insert(tooltipLines, tokenCountString)
            else
                table.insert(tooltipLines, product.description)
            end

            -- Description
            local bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))
            for i=1, #tooltipLines do
                bodySection:AddLine(tooltipLines[i], self:GetStyle("bodyDescription"))
            end
            self:AddSection(bodySection)

            --Instant Unlock Restrictions
            if instantUnlockType ~= MARKET_INSTANT_UNLOCK_NONE then
                local GET_CACHED_STATE = true
                local purchaseState = GetMarketProductPurchaseState(productId, GET_CACHED_STATE)
                if purchaseState == MARKET_PRODUCT_PURCHASE_STATE_INSTANT_UNLOCK_INELIGIBLE then
                    self:AddInstantUnlockEligibilityFailures(GetMarketProductEligibilityErrorStringIds(productId))
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
    local BUNDLE_ATTACHMENT_NAME = self.control:GetName() .. ZO_GAMEPAD_MARKET_PRODUCT_BUNDLE_ATTACHMENT_TEMPLATE
    
    local function ResetMarketProduct(marketProduct)
        marketProduct:Reset()
    end
    
    local function CreateMarketBundleAttachment(objectPool)
        return ZO_GamepadMarketProductBundleAttachment:New(objectPool:GetNextControlId(), self.currentCategoryControl, self, BUNDLE_ATTACHMENT_NAME)
    end

    self.marketBundleAttachmentPool = ZO_ObjectPool:New(CreateMarketBundleAttachment, ResetMarketProduct)
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

        local function QueueTutorial(_, purchasedConsumables, triggerTutorialOnPurchase)
            if purchasedConsumables then
                self:SetQueuedTutorial(TUTORIAL_TRIGGER_CROWN_CONSUMABLE_PURCHASED)
            end

            if triggerTutorialOnPurchase then
                self:SetQueuedTutorial(triggerTutorialOnPurchase)
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

function GamepadMarketBundleContents:LayoutBundleProducts(bundle)
    self:ClearProducts()
    self:PrepareGridForBuild(ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCTS_PER_ROW, ZO_GAMEPAD_MARKET_PRODUCTS_PER_COLUMN, ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_WIDTH, ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_HEIGHT, ZO_GAMEPAD_MARKET_PRODUCT_PADDING)

    local numChildren = bundle:GetNumChildren()

    if numChildren > 0 then
        local childTiles = {}
        for childIndex = 1, numChildren do
            local childMarketProductId = bundle:GetChildMarketProductId(childIndex)
            local displayName = GetMarketProductDisplayName(childMarketProductId)

            local marketProduct = self.marketBundleAttachmentPool:AcquireObject()
            marketProduct:SetBundle(bundle)
            marketProduct:Show(childMarketProductId)
            table.insert(childTiles, {displayName = displayName, marketProduct = marketProduct})
        end

        -- Sort the child tiles alphabetically
        table.sort(childTiles, function(a,b)
                                        return a.displayName < b.displayName
                                    end)

        for i = 1, #childTiles do
            local marketProduct = childTiles[i].marketProduct
            self:AddEntry(marketProduct, marketProduct:GetControl())
        end
    end

    self:FinishRowWithBlankTiles()
    self:FinishBuild()
end

function GamepadMarketBundleContents:OnShowing()
    ZO_GamepadMarket_GridScreen.OnShowing(self)
    self:LayoutBundleProducts(self.bundle)
    self.titleControl:SetText(self.headerData.titleText)
    self:SelectAfterPreview()
    self:AddKeybinds()
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
    self:RemoveKeybinds()
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
    self.marketBundleAttachmentPool:ReleaseAllObjects()
    self.blankTilePool:ReleaseAllObjects()
end


function GamepadMarketBundleContents:AddKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptors)
end

function GamepadMarketBundleContents:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptors)
end

function GamepadMarketBundleContents:RefreshKeybinds()
    ZO_GamepadMarketKeybindStrip_RefreshStyle()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptors)
end

-- override from ZO_GamepadMarket_GridScreen
function GamepadMarketBundleContents:FinishBuild()
    ZO_GamepadMarket_GridScreen.FinishBuild(self)
    self:RefreshKeybinds()
end

-- override from ZO_GamepadMarket_GridScreen
function GamepadMarketBundleContents:EndCurrentPreview()
    ZO_GamepadMarket_GridScreen.EndCurrentPreview(self)
    self:RefreshKeybinds()
end

-- MarketClasses_Shared expects us to have this function (because Market_Shared does)
function GamepadMarketBundleContents:RefreshActions()
    self:RefreshKeybinds()
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