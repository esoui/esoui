ZO_HousingFurnitureBrowser_Gamepad = ZO_Object.MultiSubclass(ZO_HousingFurnitureBrowser_Base, ZO_Gamepad_ParametricList_Search_Screen)

function ZO_HousingFurnitureBrowser_Gamepad:New(...)
    return ZO_HousingFurnitureBrowser_Base.New(self, ...)
end

function ZO_HousingFurnitureBrowser_Gamepad:Initialize(control)
    GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE = ZO_Scene:New("gamepad_housing_furniture_scene", SCENE_MANAGER)
    ZO_HousingFurnitureBrowser_Base.Initialize(self, control, "gamepad_housing_furniture_scene")
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Search_Screen.Initialize(self, BACKGROUND_LIST_FILTER_TARGET_FURNITURE_ID, "housingEditorTextSearch", control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, ACTIVATE_ON_SHOW, GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE)
    SYSTEMS:RegisterGamepadRootScene("housing_furniture_browser", GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE)

    self.occupantControl = control:GetNamedChild("Occupants")
    self.visitorPermissionsControl = control:GetNamedChild("Visitors")
    self.banListPermissionsControl = control:GetNamedChild("BanList")
    self.guildVisitorPermissionsControl = control:GetNamedChild("GuildVisitors")
    self.guildBanListPermissionsControl = control:GetNamedChild("GuildBanList")

    self.OnRefreshActions = function()
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self:GetCurrentList())
    end

    self.nextListId = 0

    self.placementPanel = ZO_HousingFurniturePlacement_Gamepad:New(self)
    self.productsPanel = ZO_HousingFurnitureProducts_Gamepad:New(self)
    self.retrievalPanel = ZO_HousingFurnitureRetrieval_Gamepad:New(self)
    self.settingsPanel = ZO_HousingFurnitureSettings_Gamepad:New(self)

    self.currentPanel = self.placementPanel

    self:InitializeHeader()

    self:SetListsUseTriggerKeybinds(true)
end

function ZO_HousingFurnitureBrowser_Gamepad:PerformUpdate()
    if self.mode == HOUSING_BROWSER_MODE.PLACEMENT then
        SHARED_FURNITURE:OnPlacementFiltersChanged()
        self:UpdatePlaceablePanel()
    elseif self.mode == HOUSING_BROWSER_MODE.PRODUCTS then
        SHARED_FURNITURE:OnPurchaseFiltersChanged()
        self:UpdateProductsPanel()
    elseif self.mode == HOUSING_BROWSER_MODE.RETRIEVAL then
        SHARED_FURNITURE:OnRetrievableFiltersChanged()
        self:UpdateRetrievablePanel()
    end
end

function ZO_HousingFurnitureBrowser_Gamepad:UpdatePlaceablePanel()
    self.placementPanel:UpdateLists()
end

--Overridden
function ZO_HousingFurnitureBrowser_Gamepad:UpdateRetrievablePanel()
    self.retrievalPanel:UpdateLists()
end

--Overridden
function ZO_HousingFurnitureBrowser_Gamepad:UpdateRetrievablePanelDistancesAndHeadings()
    self.retrievalPanel:UpdateLists()
end

--Overridden
function ZO_HousingFurnitureBrowser_Gamepad:UpdateRetrievablePanelHeadings()
    --Gamepad doesn't show headings so do nothing
end


--Overridden
function ZO_HousingFurnitureBrowser_Gamepad:UpdateProductsPanel()
    self.productsPanel:UpdateLists()
end

--Overridden
function  ZO_HousingFurnitureBrowser_Gamepad:GetFooterNarration()
    if HOUSE_INFORMATION_FRAGMENT_GAMEPAD:IsShowing() then
        return HOUSE_INFORMATION_GAMEPAD:GetNarrationText()
    end
end

function ZO_HousingFurnitureBrowser_Gamepad:InitializeHeader()
    local tabBarEntries =
    {
        {
            text = function()
                if self.titleText then
                    return self.titleText
                else
                    return GetString(SI_HOUSING_FURNITURE_TAB_PLACE)
                end
            end,
            callback = function()
                self:SetMode(HOUSING_BROWSER_MODE.PLACEMENT)
            end,
            visible = function()
                return HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner()
            end,
        },
        {
            text = GetString(SI_HOUSING_FURNITURE_TAB_PURCHASE),
            callback = function()
                self:SetMode(HOUSING_BROWSER_MODE.PRODUCTS)
            end,
            visible = function()
                return HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner()
            end,
        },
        {
            text = function()
                if HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner() then
                    return GetString(SI_HOUSING_FURNITURE_TAB_RETRIEVAL)
                else
                    return GetString(SI_HOUSING_FURNITURE_TAB_FURNITURE_LIST)
                end
            end,
            callback = function()
                self:SetMode(HOUSING_BROWSER_MODE.RETRIEVAL)
            end,
            visible = function()
                return HOUSING_EDITOR_STATE:CanLocalPlayerBrowseFurniture()
            end,
        },
        {
            text = GetString(SI_HOUSING_FURNITURE_TAB_SETTINGS),
            callback = function()
                self:SetMode(HOUSING_BROWSER_MODE.SETTINGS)
            end,
            visible = function()
                return HOUSING_EDITOR_STATE:CanLocalPlayerViewSettings()
            end,
        },
    }

    self.headerData =
    {
        tabBarEntries = tabBarEntries,
    }

    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)
end

function ZO_HousingFurnitureBrowser_Gamepad:RequestNewList()
    local newList
    if self.nextListId == 0 then
        newList = self:GetMainList()
    else
        newList = self:AddList("SubList" .. self.nextListId)
    end
    self.nextListId = self.nextListId + 1
    return newList
end

function ZO_HousingFurnitureBrowser_Gamepad:IsShowing()
    return GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE:IsShowing()
end

function ZO_HousingFurnitureBrowser_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Search_Screen.OnShowing(self)
    ZO_HousingFurnitureBrowser_Base.OnShowing(self)

    --Enter browsing mode if we aren't already
    local currentMode = GetHousingEditorMode()
    if currentMode ~= HOUSING_EDITOR_MODE_BROWSE then
        HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_BROWSE)
    end

    self:RefreshCategoryHeaderData()
    ZO_GamepadGenericHeader_Activate(self.header)
    self.settingsPanel:UpdateLists()
    ITEM_PREVIEW_GAMEPAD:RegisterCallback("RefreshActions", self.OnRefreshActions)
end

function ZO_HousingFurnitureBrowser_Gamepad:OnHiding()
    ZO_Gamepad_ParametricList_Search_Screen.OnHiding(self)
    ZO_HousingFurnitureBrowser_Base.OnHiding(self)
    ZO_GamepadGenericHeader_Deactivate(self.header)
end

function ZO_HousingFurnitureBrowser_Gamepad:OnHide()
    ZO_Gamepad_ParametricList_Search_Screen.OnHide(self)
    self:SetMode(HOUSING_BROWSER_MODE.NONE)
    ITEM_PREVIEW_GAMEPAD:UnregisterCallback("RefreshActions", self.OnRefreshActions)
end

-- Default text search back button closes the screen, but we have multiple layers here.
function ZO_HousingFurnitureBrowser_Gamepad:OnBackButtonClicked()
    if self.currentPanel.currentList and self.currentPanel.currentList == self.currentPanel.furnitureList then
        self.currentPanel:FurnitureKeybindBackCallback()
    else
        -- Call parent to close scene.
        ZO_Gamepad_ParametricList_Search_Screen.OnBackButtonClicked(self)
    end
end

function ZO_HousingFurnitureBrowser_Gamepad:SetMode(mode)
    if self.mode ~= mode then

        if self.currentPanel then
            self.currentPanel:OnHiding()
        end
        self.mode = mode

        if mode == HOUSING_BROWSER_MODE.PLACEMENT then
            self.currentPanel = self.placementPanel
            self:SetTextSearchEntryHidden(false)
            self:SetSearchCriteria({ BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, BACKGROUND_LIST_FILTER_TARGET_COLLECTIBLE_ID }, "housePlaceableItemsTextSearch")
            self:ActivateTextSearch()
        elseif mode == HOUSING_BROWSER_MODE.PRODUCTS then
            self.currentPanel = self.productsPanel
            self:SetTextSearchEntryHidden(false)
            self:SetSearchCriteria(BACKGROUND_LIST_FILTER_TARGET_MARKET_PRODUCT_ID, "houseProductsTextSearch")
            self:ActivateTextSearch()
        elseif mode == HOUSING_BROWSER_MODE.RETRIEVAL then
            self.currentPanel = self.retrievalPanel
            self:SetTextSearchEntryHidden(false)
            self:SetSearchCriteria(BACKGROUND_LIST_FILTER_TARGET_FURNITURE_ID, "houseFurnitureTextSearch")
            self:ActivateTextSearch()
        elseif mode == HOUSING_BROWSER_MODE.SETTINGS then
            self.currentPanel = self.settingsPanel
            self:SetTextSearchEntryHidden(true)
        elseif mode == HOUSING_BROWSER_MODE.NONE then
            self.currentPanel = nil
            self:SetTextSearchEntryHidden(true)
        end

        if self.currentPanel then
            -- Order matters here
            self:RefreshCategoryHeaderData()
            self.currentPanel:OnShowing()
        end
    end
end

do
    function ZO_HousingFurnitureBrowser_Gamepad:RefreshCategoryHeaderData()
        local mode = self.mode
        if (mode == HOUSING_BROWSER_MODE.PLACEMENT or mode == HOUSING_BROWSER_MODE.PRODUCTS or mode == HOUSING_BROWSER_MODE.RETRIEVAL) and HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner() then
            self.headerData.data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY)
            self.headerData.data1Text = zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
        else
            self.headerData.data1HeaderText = nil
            self.headerData.data1Text = nil
        end
        ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    end
end

function ZO_HousingFurnitureBrowser_Gamepad:SetTitleText(text)
    if self.titleText ~= text then
        self.titleText = text
        self:RefreshCategoryHeaderData()
    end
end

--
--[[ XML Functions ]]
--

function ZO_HousingFurnitureBrowser_Gamepad_OnInitialize(control)
    GAMEPAD_HOUSING_FURNITURE_BROWSER = ZO_HousingFurnitureBrowser_Gamepad:New(control)
end