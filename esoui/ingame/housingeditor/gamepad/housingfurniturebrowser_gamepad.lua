ZO_HousingFurnitureBrowser_Gamepad = ZO_Object.MultiSubclass(ZO_HousingFurnitureBrowser_Base, ZO_Gamepad_ParametricList_Screen)

function ZO_HousingFurnitureBrowser_Gamepad:New(...)
    return ZO_HousingFurnitureBrowser_Base.New(self, ...)
end

function ZO_HousingFurnitureBrowser_Gamepad:Initialize(control)
    GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE = ZO_Scene:New("gamepad_housing_furniture_scene", SCENE_MANAGER)
    ZO_HousingFurnitureBrowser_Base.Initialize(self, control, "gamepad_housing_furniture_scene")
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, ACTIVATE_ON_SHOW, GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE)
    SYSTEMS:RegisterGamepadRootScene("housing_furniture_browser", GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE)

    self.visitorPermissionsControl = control:GetNamedChild("Visitors")
    self.banListPermissionsControl = control:GetNamedChild("BanList")
    self.guildVisitorPermissionsControl = control:GetNamedChild("GuildVisitors")
    self.guildBanListPermissionsControl = control:GetNamedChild("GuildBanList")

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
    --Do nothing. We manager the update state in a more nuanced way.
end

--Overridden
function ZO_HousingFurnitureBrowser_Gamepad:UpdatePlaceablePanel()
    self.placementPanel:UpdateLists()
    self:RefreshCategoryHeaderData()
end

--Overridden
function ZO_HousingFurnitureBrowser_Gamepad:UpdateRetrievablePanel()
    self.retrievalPanel:UpdateLists()
    self:RefreshCategoryHeaderData()
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

function ZO_HousingFurnitureBrowser_Gamepad:InitializeHeader()
    local tabBarEntries =
    {
        {
            text = GetString(SI_HOUSING_FURNITURE_TAB_PLACE),
            callback = function()
                self:SetMode(HOUSING_BROWSER_MODE.PLACEMENT)
            end,
        },
        {
            text = GetString(SI_HOUSING_FURNITURE_TAB_PURCHASE),
            callback = function()
                self:SetMode(HOUSING_BROWSER_MODE.PRODUCTS)
            end,
        },
        {
            text = GetString(SI_HOUSING_FURNITURE_TAB_RETRIEVAL),
            callback = function()
                self:SetMode(HOUSING_BROWSER_MODE.RETRIEVAL)
            end,
        },
        {
            text = GetString(SI_HOUSING_FURNITURE_TAB_SETTINGS),
            callback = function()
                self:SetMode(HOUSING_BROWSER_MODE.SETTINGS)
            end,
        },
    }

    self.categoryHeaderData =
    {
        tabBarEntries = tabBarEntries,
    }

    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    local headerContainer = self:GetHeaderContainer()
    self.headerTextFilterControl = headerContainer:GetNamedChild("Filter")
    self.headerTextFilterEditBox = self.headerTextFilterControl:GetNamedChild("SearchEdit")
    self.headerTextFilterHighlight = self.headerTextFilterControl:GetNamedChild("Highlight")
    self.headerTextFilterIcon = self.headerTextFilterControl:GetNamedChild("Icon")
    self.headerBGTexture = self.headerTextFilterControl:GetNamedChild("BG")

    self.headerTextFilterEditBox:SetHandler("OnTextChanged", function(editBox)
        ZO_EditDefaultText_OnTextChanged(editBox)
        local text = editBox:GetText()
        if self.mode == HOUSING_BROWSER_MODE.PLACEMENT then
            SHARED_FURNITURE:SetPlaceableTextFilter(text)
        elseif self.mode == HOUSING_BROWSER_MODE.RETRIEVAL then
            SHARED_FURNITURE:SetRetrievableTextFilter(text)
        elseif self.mode == HOUSING_BROWSER_MODE.PRODUCTS then
            SHARED_FURNITURE:SetMarketProductTextFilter(text)
        end
    end)

    ZO_PreHookHandler(self.headerTextFilterEditBox, "OnFocusGained", function(editBox)
        self:DeactivateCurrentList()
        self.headerTextFilterHighlight:SetHidden(false)
        self.headerTextFilterIcon:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        self.headerBGTexture:SetHidden(false)
    end)

    ZO_PreHookHandler(self.headerTextFilterEditBox, "OnFocusLost", function(editBox)
        self.headerTextFilterHighlight:SetHidden(true)
        self.headerTextFilterIcon:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
        self.headerBGTexture:SetHidden(true)
        self:ActivateCurrentList()
    end)
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

function ZO_HousingFurnitureBrowser_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    ZO_HousingFurnitureBrowser_Base.OnShowing(self)
    self:RefreshCategoryHeaderData()
    ZO_GamepadGenericHeader_Activate(self.header)
    self.settingsPanel:UpdateLists()
end

function ZO_HousingFurnitureBrowser_Gamepad:OnHiding()
    ZO_Gamepad_ParametricList_Screen.OnHiding(self)
    ZO_HousingFurnitureBrowser_Base.OnHiding(self)
    ZO_GamepadGenericHeader_Deactivate(self.header)
end

function ZO_HousingFurnitureBrowser_Gamepad:OnHide()
    self:SetMode(HOUSING_BROWSER_MODE.NONE)
end

function ZO_HousingFurnitureBrowser_Gamepad:SetMode(mode)
    if self.mode ~= mode then

        if self.currentPanel then
            self.currentPanel:OnHiding()
        end
        self.mode = mode

        if mode == HOUSING_BROWSER_MODE.PLACEMENT then
            self.currentPanel = self.placementPanel
            self.headerTextFilterControl:SetHidden(false)
            self.headerTextFilterEditBox:SetText(SHARED_FURNITURE:GetPlaceableTextFilter())
        elseif mode == HOUSING_BROWSER_MODE.PRODUCTS then
            self.currentPanel = self.productsPanel
            self.headerTextFilterControl:SetHidden(false)
            self.headerTextFilterEditBox:SetText(SHARED_FURNITURE:GetMarketProductTextFilter())
        elseif mode == HOUSING_BROWSER_MODE.RETRIEVAL then
            self.currentPanel = self.retrievalPanel
            self.headerTextFilterControl:SetHidden(false)
            self.headerTextFilterEditBox:SetText(SHARED_FURNITURE:GetRetrievableTextFilter())
        elseif mode == HOUSING_BROWSER_MODE.SETTINGS then
            self.currentPanel = self.settingsPanel
            self.headerTextFilterControl:SetHidden(true)
        elseif mode == HOUSING_BROWSER_MODE.NONE then
            self.currentPanel = nil
            self.headerTextFilterControl:SetHidden(true)
        end

        if self.currentPanel then
            self.currentPanel:OnShowing()
            self:RefreshCategoryHeaderData()
        end
    end
end

function ZO_HousingFurnitureBrowser_Gamepad:SelectTextFilter()
    self.headerTextFilterEditBox:TakeFocus()
end

do
    function ZO_HousingFurnitureBrowser_Gamepad:RefreshCategoryHeaderData()
        local mode = self.mode
        if mode == HOUSING_BROWSER_MODE.PLACEMENT or mode == HOUSING_BROWSER_MODE.PRODUCTS or mode == HOUSING_BROWSER_MODE.RETRIEVAL then
            self.categoryHeaderData.data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY)
            self.categoryHeaderData.data1Text = zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
        else
            self.categoryHeaderData.data1HeaderText = nil
            self.categoryHeaderData.data1Text = nil
        end
        ZO_GamepadGenericHeader_Refresh(self.header, self.categoryHeaderData)
    end
end

--
--[[ XML Functions ]]
--

function ZO_HousingFurnitureBrowser_Gamepad_OnInitialize(control)
    local gamepadBrowser = ZO_HousingFurnitureBrowser_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("housing_furniture_browser", gamepadBrowser)
end