-----------------------
-- Gamepad trading house
-----------------------

local GAMEPAD_TRADING_HOUSE_SCENE_NAME = "gamepad_trading_house"

ZO_GamepadTradingHouse = ZO_TradingHouse_Shared:Subclass()

function ZO_GamepadTradingHouse:New(...)
    local tradingHouse = ZO_TradingHouse_Shared.New(self, ...)
    return tradingHouse
end

function ZO_GamepadTradingHouse:Initialize(control)
    ZO_TradingHouse_Shared.Initialize(self, control)
    self.isInitialized = false
    TRADING_HOUSE_GAMEPAD_SCENE = ZO_InteractScene:New(GAMEPAD_TRADING_HOUSE_SCENE_NAME, SCENE_MANAGER, ZO_TRADING_HOUSE_INTERACTION)
    TRADING_HOUSE_GAMEPAD_SUBSCENE_MANAGER = ZO_SceneManager_Leader:New()
    TRADING_HOUSE_GAMEPAD_SUBSCENE_MANAGER:SetParentScene(TRADING_HOUSE_GAMEPAD_SCENE)
    SYSTEMS:RegisterGamepadRootScene(ZO_TRADING_HOUSE_SYSTEM_NAME, TRADING_HOUSE_GAMEPAD_SCENE)
    SCENE_MANAGER:AddSceneGroup("tradingHouseGamepadSceneGroup", ZO_SceneGroup:New(GAMEPAD_TRADING_HOUSE_SCENE_NAME))
end

function ZO_GamepadTradingHouse:InitializeLists()
    local maskControl = self.control:GetNamedChild("Mask")
    local listContainer = maskControl:GetNamedChild("Container")

    self.loading = maskControl:GetNamedChild("Loading")
    ZO_TradingHouse_Browse_Gamepad_OnInitialize(listContainer:GetNamedChild("Browse"))
    ZO_TradingHouseSearchHistory_Gamepad_OnInitialize(listContainer:GetNamedChild("SearchHistory"))
    ZO_TradingHouseNameSearchAutoComplete_Gamepad_OnInitialize(listContainer:GetNamedChild("NameSearchAutoComplete"))

    ZO_TradingHouse_Sell_Gamepad_OnInitialize(listContainer:GetNamedChild("Sell"))

    ZO_TradingHouse_Listings_Gamepad_OnInitialize(listContainer:GetNamedChild("Listings"))
end

function ZO_GamepadTradingHouse:InitializeHeader()
    self.header = self.control:GetNamedChild("Mask"):GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    local function UpdateGold(control)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
        return true
    end

    local function GetCapacityString()
        return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
    end

    self.tabsTable = {
        --[ZO_TRADING_HOUSE_MODE_BROWSE]
        {
            text = GetString(SI_TRADING_HOUSE_MODE_BROWSE),
            callback = function()
                self:SetCurrentListObject(GAMEPAD_TRADING_HOUSE_BROWSE)
            end,
        },
        --[ZO_TRADING_HOUSE_MODE_SELL]
        {
            text = GetString(SI_TRADING_HOUSE_MODE_SELL),
            callback = function()
                self:SetCurrentListObject(GAMEPAD_TRADING_HOUSE_SELL)
            end,
        },
        --[ZO_TRADING_HOUSE_MODE_LISTINGS]
        {
            text = GetString(SI_TRADING_HOUSE_MODE_LISTINGS),
            callback = function()
                self:SetCurrentListObject(GAMEPAD_TRADING_HOUSE_LISTINGS)
            end,
        },
    }

    self.tabHeaderData = {
        data1HeaderText = GetString(SI_GAMEPAD_GUILD_BANK_AVAILABLE_FUNDS),
        data1Text = UpdateGold,

        data2HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data2Text = GetCapacityString,

        tabBarEntries = self.tabsTable
    }

    self.noTabHeaderData = {
        data1HeaderText = GetString(SI_GAMEPAD_GUILD_BANK_AVAILABLE_FUNDS),
        data1Text = UpdateGold,

        data2HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data2Text = GetCapacityString,

        titleText = nil, -- Set before using
    }

    ZO_GamepadGenericHeader_Refresh(self.header, self.tabHeaderData)
end

function ZO_GamepadTradingHouse:SelectHeaderTab(tradingHouseMode)
    ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, tradingHouseMode)
end

function ZO_GamepadTradingHouse:SetCurrentListObject(listObject)
    if listObject == self.currentListObject then return end

    local mode = listObject:GetTradingHouseMode()
    if mode then
        self:SetCurrentMode(mode)
    end

    --Manage the progression of fragments so they don't overlap
    local previousObject = self.currentListObject
    self.currentListObject = listObject

    if SCENE_MANAGER:IsShowing(GAMEPAD_TRADING_HOUSE_SCENE_NAME) then
        if previousObject then
            previousObject:Hide()
        end

        listObject:Show()
        self:RefreshHeader()
    end
end

function ZO_GamepadTradingHouse:EnterBrowseResults()
    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
    if GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:IsActive() then
        -- Deactivate the panel so you can't manipulate the sort during a search
        self:DeactivateBrowseResults()
    end
    -- Perform the search now: We will ActivateBrowseResults when the search completes
    TRADING_HOUSE_SEARCH:DoSearch()
end

function ZO_GamepadTradingHouse:ActivateBrowseResults()
    self.currentListObject:Deactivate()
    GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:Activate()
end

function ZO_GamepadTradingHouse:LeaveBrowseResults()
    PlaySound(SOUNDS.GAMEPAD_MENU_BACKWARD)
    self:DeactivateBrowseResults()
end

function ZO_GamepadTradingHouse:DeactivateBrowseResults()
    GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:Deactivate()
    self.currentListObject:Activate()
end

function ZO_GamepadTradingHouse:EnterSearchHistory()
    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
    self:SetCurrentListObject(GAMEPAD_TRADING_HOUSE_SEARCH_HISTORY)
end

function ZO_GamepadTradingHouse:LeaveSearchHistory()
    PlaySound(SOUNDS.GAMEPAD_MENU_BACKWARD)
    self:SetCurrentListObject(GAMEPAD_TRADING_HOUSE_BROWSE)
end

function ZO_GamepadTradingHouse:EnterNameSearchAutoComplete()
    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
    self:SetCurrentListObject(GAMEPAD_TRADING_HOUSE_NAME_SEARCH_AUTOCOMPLETE)
end

function ZO_GamepadTradingHouse:LeaveNameSearchAutoComplete()
    PlaySound(SOUNDS.GAMEPAD_MENU_BACKWARD)
    self:SetCurrentListObject(GAMEPAD_TRADING_HOUSE_BROWSE)
end

function ZO_GamepadTradingHouse:SelectCurrentListInHeader()
    local replacementActive = self.currentListObject:GetHeaderReplacementInfo()
    if not replacementActive then
        ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, self:GetCurrentMode())
    end
end

function ZO_GamepadTradingHouse:RefreshHeader()
    local replacementActive, replacementTitleText = self.currentListObject:GetHeaderReplacementInfo()
    if replacementActive then
        self.noTabHeaderData.titleText = replacementTitleText
        local BLOCK_TAB_CALLBACKS = true
        ZO_GamepadGenericHeader_Refresh(self.header, self.noTabHeaderData, BLOCK_TAB_CALLBACKS)
    else
        ZO_GamepadGenericHeader_Refresh(self.header, self.tabHeaderData)
    end
end

function ZO_GamepadTradingHouse:RefreshGuildNameFooter()
    local _, guildName = GetCurrentTradingHouseGuildDetails()

    ZO_GUILD_NAME_FOOTER_FRAGMENT:SetGuildName(guildName)
end

function ZO_GamepadTradingHouse:RegisterForSceneEvents()
    local function RefreshHeader()
        self:RefreshHeader()
    end

    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, RefreshHeader)
    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, RefreshHeader)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, RefreshHeader)
end

function ZO_GamepadTradingHouse:UnregisterForSceneEvents()
    self.control:UnregisterForEvent(EVENT_MONEY_UPDATE)
    self.control:UnregisterForEvent(EVENT_INVENTORY_FULL_UPDATE)
    self.control:UnregisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
end

function ZO_GamepadTradingHouse:InitializeKeybindStripDescriptors()
end

function ZO_GamepadTradingHouse:PerformDeferredInitialization()
    if self.isInitialized then return end

    self:InitializeKeybindStripDescriptors()
    self:InitializeLists()
    self:InitializeHeader()
    self:InitializeEvents()
    self:InitializeSearchTerms()

    self.isInitialized = true
end

function ZO_GamepadTradingHouse:OpenTradingHouse()
    self:SetCurrentMode(ZO_TRADING_HOUSE_MODE_BROWSE)
    self:PerformDeferredInitialization()
    TRADING_HOUSE_SEARCH:AssociateWithSearchFeatures(GAMEPAD_TRADING_HOUSE_BROWSE:GetFeatures())
end

function ZO_GamepadTradingHouse:CloseTradingHouse()
    if SCENE_MANAGER:IsShowing("gamepad_trading_house_create_listing") then
        SCENE_MANAGER:PopScenes(2)
    else
        SYSTEMS:HideScene(ZO_TRADING_HOUSE_SYSTEM_NAME)
    end
    self:SetCurrentMode(nil)
    TRADING_HOUSE_SEARCH:DisassociateWithSearchFeatures()
end

function ZO_GamepadTradingHouse:InitializeEvents()
    local function FilterForGamepadEvents(callback)
        return function(...)
            if IsInGamepadPreferredMode() then
                callback(...)
            end
        end
    end

    TRADING_HOUSE_SEARCH:RegisterCallback("OnSearchRequested", FilterForGamepadEvents(function(...) self:OnSearchRequested(...) end))
    TRADING_HOUSE_SEARCH:RegisterCallback("OnSearchRequestCanceled", FilterForGamepadEvents(function(...) self:OnSearchRequestCanceled(...) end))
    TRADING_HOUSE_SEARCH:RegisterCallback("OnSearchStateChanged", FilterForGamepadEvents(function(...) self:OnSearchStateChanged(...) end))
    TRADING_HOUSE_SEARCH:RegisterCallback("OnAwaitingResponse", FilterForGamepadEvents(function() self:OnAwaitingResponse() end))
    TRADING_HOUSE_SEARCH:RegisterCallback("OnResponseReceived", FilterForGamepadEvents(function() self:OnResponseReceived() end))
    TRADING_HOUSE_SEARCH:RegisterCallback("OnResponseTimeout", FilterForGamepadEvents(function(...) self:OnResponseTimeout(...) end))
    TRADING_HOUSE_SEARCH:RegisterCallback("OnSelectedGuildChanged", FilterForGamepadEvents(function() self:OnSelectedGuildChanged() end))

    TRADING_HOUSE_GAMEPAD_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:RefreshHeader()
            self:SelectCurrentListInHeader()
            self:RefreshGuildNameFooter()
            self:RegisterForSceneEvents()

            self.currentListObject:Show()
            ZO_GamepadGenericHeader_Activate(self.header)
        elseif newState == SCENE_HIDDEN then
            self:UnregisterForSceneEvents()
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            ZO_GamepadGenericHeader_Deactivate(self.header)
            self.currentListObject:Hide()
        end
    end)

    TRADING_HOUSE_GAMEPAD_SCENE:GetSceneGroup():RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_GROUP_HIDDEN then
            self:UnlockForInput()
        end
    end)
end

function ZO_GamepadTradingHouse:LockForInput()
    if not self.lockedForInput then
        self.lockedForInput = true
        self.loading:SetHidden(false)
        self:FireCallbacks("OnLockedForInput")
        ZO_GamepadGenericHeader_Deactivate(self.header)
        KEYBIND_STRIP:PushKeybindGroupState() -- push empty group to disable keybinds
    end
end

function ZO_GamepadTradingHouse:UnlockForInput()
    if self.lockedForInput then
        self.lockedForInput = false
        self.loading:SetHidden(true)
        self:FireCallbacks("OnUnlockedForInput")

        if not self.header:IsHidden() then
            ZO_GamepadGenericHeader_Activate(self.header)
        end
        KEYBIND_STRIP:PopKeybindGroupState()
    end
end

function ZO_GamepadTradingHouse:OnSearchRequested()
    self:LockForInput()
end

function ZO_GamepadTradingHouse:OnSearchRequestCanceled()
    self:UnlockForInput()
end

function ZO_GamepadTradingHouse:OnSearchStateChanged(searchState)
    if searchState == TRADING_HOUSE_SEARCH_STATE_COMPLETE then
        self:UnlockForInput()
    end
end

function ZO_GamepadTradingHouse:OnAwaitingResponse()
    self:LockForInput()
end

function ZO_GamepadTradingHouse:OnResponseReceived()
    self:UnlockForInput()
end

function ZO_GamepadTradingHouse:OnResponseTimeout()
    self:UnlockForInput()
end

function ZO_GamepadTradingHouse:OnSelectedGuildChanged()
    self:RefreshHeader()
    self:RefreshGuildNameFooter()
end

function ZO_GamepadTradingHouse:InitializeSearchTerms()
    GAMEPAD_TRADING_HOUSE_BROWSE:InitializeSearchTerms(self.search)
end

function ZO_GamepadTradingHouse:SearchForItemLink(itemLink)
    if TRADING_HOUSE_GAMEPAD_SCENE:IsShowing() then
        TRADING_HOUSE_SEARCH:LoadSearchItem(itemLink)
        GAMEPAD_TRADING_HOUSE_BROWSE:ShowAndThenEnterBrowseResults()
    end
end

--[[ Globals ]]--

function ZO_TradingHouse_Gamepad_Initialize(control)
    TRADING_HOUSE_GAMEPAD = ZO_GamepadTradingHouse:New(control)
    SYSTEMS:RegisterGamepadObject(ZO_TRADING_HOUSE_SYSTEM_NAME, TRADING_HOUSE_GAMEPAD)
end
