-----------------------
-- Gamepad trading house
-----------------------

local GAMEPAD_TRADING_HOUSE_SCENE_NAME = "gamepad_trading_house"

ZO_GamepadTradingHouse = ZO_TradingHouse_Shared:Subclass()

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

function ZO_GamepadTradingHouse:GetTextSearchText()
    if self.textSearchHeaderFocus then
        return self.textSearchHeaderFocus:GetText()
    end

    return ""
end

function ZO_GamepadTradingHouse:OnBackButtonClicked()
    -- Default back functionality, override this function for different behaviour
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_GamepadTradingHouse:InitializeHeader()
    self.header = self.control:GetNamedChild("Mask"):GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    self.textSearchKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,
            callback = function()
                self:SetTextSearchFocused(true)
            end,
        },
        {
            name = GetString(SI_TRADING_HOUSE_GUILD_HEADER),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                ZO_Dialogs_ShowPlatformDialog("TRADING_HOUSE_CHANGE_ACTIVE_GUILD")
            end,
            visible = function()
                local hasMultipleGuilds = GetNumTradingHouseGuilds() > 1
                local list = self.currentListObject
                if list then
                    return list.itemList:GetNumItems() == 0 and hasMultipleGuilds
                end
                return false
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.textSearchKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        self:OnBackButtonClicked()
    end)

    local function OnTextSearchTextChanged(editBox)
        TEXT_SEARCH_MANAGER:SetSearchText("guildTraderTextSearch", editBox:GetText())
    end

    self:AddSearch(self.textSearchKeybindStripDescriptor, OnTextSearchTextChanged)

    local function UpdateGold(control)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
        return true
    end

    local function GetCapacityString()
        return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
    end

    self.tabsTable =
    {
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

    self.tabHeaderData =
    {
        data1HeaderText = GetString(SI_GAMEPAD_GUILD_BANK_AVAILABLE_FUNDS),
        data1Text = UpdateGold,
        data1TextNarration = ZO_Currency_GetPlayerCarriedGoldCurrencyNameNarration,

        data2HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data2Text = GetCapacityString,

        tabBarEntries = self.tabsTable
    }

    self.noTabHeaderData =
    {
        data1HeaderText = GetString(SI_GAMEPAD_GUILD_BANK_AVAILABLE_FUNDS),
        data1Text = UpdateGold,
        data1TextNarration = ZO_Currency_GetPlayerCarriedGoldCurrencyNameNarration,

        data2HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data2Text = GetCapacityString,

        titleText = nil, -- Set before using
    }

    ZO_GamepadGenericHeader_Refresh(self.header, self.tabHeaderData)
end

-- Header functions: For Sell only --

function ZO_GamepadTradingHouse:AddSearch(textSearchKeybindStripDescriptor, onTextSearchTextChangedCallback)
    self.textSearchKeybindStripDescriptor = textSearchKeybindStripDescriptor
    self.textSearchHeaderControl = CreateControlFromVirtual("$(parent)SearchContainer", self.header, "ZO_Gamepad_TextSearch_HeaderEditbox")
    self.textSearchHeaderFocus = ZO_TextSearch_Header_Gamepad:New(self.textSearchHeaderControl, onTextSearchTextChangedCallback)
    self:SetupHeaderFocus(self.textSearchHeaderFocus)

    ZO_GamepadGenericHeader_SetHeaderFocusControl(self.header, self.textSearchHeaderControl)

    --Register the text search header for narration
    local textSearchHeaderNarrationInfo =
    {
        headerNarrationFunction = function()
            return self:GetHeaderNarration()
        end,
        resultsNarrationFunction = function()
            local narrations = {}
            local listObject = self.currentListObject
            if listObject then
                local list = listObject.itemList:GetParametricList()
                --If the item list is empty, narrate the empty text as part of the results
                if list:IsEmpty() then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(list:GetNoItemText()))
                end
            end
            return narrations
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterTextSearchHeader(self.textSearchHeaderFocus, textSearchHeaderNarrationInfo)
end

function ZO_GamepadTradingHouse:IsTextSearchEntryHidden()
    if self.textSearchHeaderControl then
        return self.textSearchHeaderControl:IsHidden()
    end

    return true
end

function ZO_GamepadTradingHouse:UpdateSearchText()
    if self.textSearchHeaderFocus then
        self.textSearchHeaderFocus:UpdateTextForContext("guildTraderTextSearch")
    end
end

function ZO_GamepadTradingHouse:ActivateTextSearch()
    if not TEXT_SEARCH_MANAGER:IsActiveTextSearch(self.searchContext) then
        self:UpdateSearchText()

        local function OnTextSearchResults()
            local list = self.currentListObject
            if list then
                list:UpdateList()
            end
        end
        self.onTextSearchResults = OnTextSearchResults

        TEXT_SEARCH_MANAGER:ActivateTextSearch("guildTraderTextSearch")
        TEXT_SEARCH_MANAGER:RegisterCallback("UpdateSearchResults", OnTextSearchResults)
        self:SetTextSearchEntryHidden(false)
    end
end

function ZO_GamepadTradingHouse:DeactivateTextSearch()
    TEXT_SEARCH_MANAGER:DeactivateTextSearch("guildTraderTextSearch")
    TEXT_SEARCH_MANAGER:UnregisterCallback("UpdateSearchResults", self.onTextSearchResults)
    self:SetTextSearchEntryHidden(true)
end

function ZO_GamepadTradingHouse:SetTextSearchEntryHidden(isHidden)
    if self.textSearchHeaderControl then
        self.textSearchHeaderControl:SetHidden(isHidden)
    end
end

function ZO_GamepadTradingHouse:SetTextSearchFocused(isFocused)
    -- Only perform if we have a text search and the text search is active
    if self.textSearchHeaderFocus and self:IsHeaderActive() then
        self.textSearchHeaderFocus:SetFocused(isFocused)
    end
end

function ZO_GamepadTradingHouse:SetupHeaderFocus(headerFocus)
    if self.headerFocus then
        assert(false) -- only support one headerFocus ever
    end

    self.headerFocus = headerFocus
    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
end

function ZO_GamepadTradingHouse:IsHeaderActive()
    return self.headerFocus and self.headerFocus:IsActive()
end

function ZO_GamepadTradingHouse:RequestEnterHeader()
    if not self.headerFocus or self.headerFocus:IsActive() then
        return
    end

    if self.textSearchHeaderFocus and self:IsTextSearchEntryHidden() then
        return
    end

    if self:CanEnterHeader() then
        self.currentListObject:Deactivate()
        self.headerFocus:Activate()
        self:OnEnterHeader()
    end
end

function ZO_GamepadTradingHouse:RequestLeaveHeader()
    if not self.headerFocus or not self.headerFocus:IsActive() then
        return
    end

    if self:CanLeaveHeader() then
        self.headerFocus:Deactivate()
        self:OnLeaveHeader()
        if self.currentListObject then
            self.currentListObject:Activate()
        end
    end
end

function ZO_GamepadTradingHouse:ExitHeader()
    if not self.headerFocus then
        return
    end

    self.headerFocus:Deactivate()
    self:OnLeaveHeader()
end

function ZO_GamepadTradingHouse:CanEnterHeader()
    return true -- override function for implementation specific functionality
end

function ZO_GamepadTradingHouse:CanLeaveHeader()
    return not self.currentListObject or self.currentListObject.itemList:GetNumItems() > 0 -- override function for implementation specific functionality
end

function ZO_GamepadTradingHouse:OnEnterHeader()
    -- override function for implementation specific functionality

    -- Swap keybinds to text search keybinds if there is a text search
    if self.textSearchHeaderFocus then
        if self.keybindStripDescriptor then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end

        if self.textSearchKeybindStripDescriptor then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.textSearchKeybindStripDescriptor)
        end
    end
end

function ZO_GamepadTradingHouse:OnLeaveHeader()
    -- override function for implementation specific functionality

    -- Swap keybinds from text search keybinds if there is a text search
    if self.textSearchHeaderFocus then
        self:SetTextSearchFocused(false)

        if self.textSearchKeybindStripDescriptor then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.textSearchKeybindStripDescriptor)
        end

        if self.keybindStripDescriptor then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end
end

function ZO_GamepadTradingHouse:UpdateDirectionalInput()
    local result = self.movementController:CheckMovement()
    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        if self.headerFocus:IsActive() then
            self:RequestLeaveHeader()
        elseif self.currentListObject.itemList then
            self.currentListObject.itemList:MoveNext()
        end
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        if self.currentListObject.itemList and self.currentListObject.itemList:GetSelectedIndex() ~= 1 then
            self.currentListObject.itemList:MovePrevious()
        else
            self:RequestEnterHeader()
        end
    end
end

function ZO_GamepadTradingHouse:SelectHeaderTab(tradingHouseMode)
    ZO_GamepadGenericHeader_SetActiveTabIndex(self.header, tradingHouseMode)
end

function ZO_GamepadTradingHouse:SetCurrentListObject(listObject)
    if listObject == self.currentListObject then
        return
    end

    self:RequestLeaveHeader()

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

    local isInSellMode = self:IsInSellMode()
    if isInSellMode and self.currentListObject then
        self:ActivateTextSearch()
        self.currentListObject.itemList.list:SetOnHitBeginningOfListCallback(function()
            self:RequestEnterHeader(self)
        end)
        DIRECTIONAL_INPUT:Activate(self, self.control)
    else
        self:DeactivateTextSearch()
        DIRECTIONAL_INPUT:Deactivate(self)
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
    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
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
    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
    self:SetCurrentListObject(GAMEPAD_TRADING_HOUSE_BROWSE)
end

function ZO_GamepadTradingHouse:EnterNameSearchAutoComplete()
    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
    self:SetCurrentListObject(GAMEPAD_TRADING_HOUSE_NAME_SEARCH_AUTOCOMPLETE)
end

function ZO_GamepadTradingHouse:LeaveNameSearchAutoComplete()
    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
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

function ZO_GamepadTradingHouse:GetHeaderNarration()
    --Determine which header data we are using
    local replacementActive = self.currentListObject:GetHeaderReplacementInfo()
    local headerData = replacementActive and self.noTabHeaderData or self.tabHeaderData
    return ZO_GamepadGenericHeader_GetNarrationText(self.header, headerData)
end

function ZO_GamepadTradingHouse:RefreshGuildNameFooter()
    local _, guildName = GetCurrentTradingHouseGuildDetails()

    ZO_GUILD_NAME_FOOTER_FRAGMENT:SetGuildName(guildName)
end

function ZO_GamepadTradingHouse:GetFooterNarration()
    if ZO_GUILD_NAME_FOOTER_FRAGMENT:IsShowing() then
        return ZO_GUILD_NAME_FOOTER_FRAGMENT:GetNarrationText()
    end
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
            SelectTradingHouseGuildId(ZO_GUILD_SELECTOR_MANAGER:GetSelectedGuildStoreId())
            self:RefreshHeader()
            self:SelectCurrentListInHeader()
            self:RefreshGuildNameFooter()
            self:RegisterForSceneEvents()
            if self:IsInSellMode() then
                DIRECTIONAL_INPUT:Activate(self, self.control)
                self:ActivateTextSearch()
            end
            self.currentListObject:Show()
            ZO_GamepadGenericHeader_Activate(self.header)
        elseif newState == SCENE_HIDING then
            self:DeactivateTextSearch()
            ZO_GamepadGenericHeader_Deactivate(self.header)
        elseif newState == SCENE_HIDDEN then
            if self:IsInSellMode() then
                DIRECTIONAL_INPUT:Deactivate(self)
            end

            self:UnregisterForSceneEvents()
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            self.currentListObject:Hide()
            ZO_SavePlayerConsoleProfile()
        end
    end)

    TRADING_HOUSE_GAMEPAD_SCENE:GetSceneGroup():RegisterCallback("StateChange", function(_, newState)
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
        local resultsActive = GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:IsActive()
        self:FireCallbacks("OnUnlockedForInput", not resultsActive)

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
