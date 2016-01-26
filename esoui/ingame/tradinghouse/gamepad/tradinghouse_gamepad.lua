-----------------------
-- Gamepad trading house
-----------------------

local GAMEPAD_TRADING_HOUSE_SCENE_NAME = "gamepad_trading_house"

local ZO_GamepadTradingHouse = ZO_TradingHouse_Shared:Subclass()

function ZO_GamepadTradingHouse:New(...)
    local tradingHouse = ZO_TradingHouse_Shared.New(self, ...)
    return tradingHouse
end

function ZO_GamepadTradingHouse:Initialize(control)
    ZO_TradingHouse_Shared.Initialize(self, control)
    self.m_isInitialized = false
    self.m_registeredFilterObjects = {}
    TRADING_HOUSE_GAMEPAD_SCENE = ZO_InteractScene:New(GAMEPAD_TRADING_HOUSE_SCENE_NAME, SCENE_MANAGER, ZO_TRADING_HOUSE_INTERACTION)
	SYSTEMS:RegisterGamepadRootScene(ZO_TRADING_HOUSE_SYSTEM_NAME, TRADING_HOUSE_GAMEPAD_SCENE)
end

function ZO_GamepadTradingHouse:InitializeHeader()

    local function CreateModeData(name, mode, object)
        return {
            text = GetString(name),
            mode = mode,
            object = object
        }
    end

	self.m_header = self.m_control:GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    self.m_loading = self.m_control:GetNamedChild("Loading")
    ZO_GamepadGenericHeader_Initialize(self.m_header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

	local function GetGuildTitle(control)
		local _, guildName = GetCurrentTradingHouseGuildDetails()
		if guildName ~= "" then
			return GetString(SI_TRADING_HOUSE_GUILD_HEADER)
		else
			return nil
		end
	end

	local function GetGuildName(control)
	    local _, guildName = GetCurrentTradingHouseGuildDetails()
		if guildName ~= "" then
			return guildName
		else
			return nil
		end
	end

    local function UpdateGold(control)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCarriedCurrencyAmount(CURT_MONEY), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
		return true
    end

    local function GetCapacityString()
        return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
    end

    local function OnCategoryChanged(selectedData)
        self:SetCurrentMode(selectedData.mode)

        if SCENE_MANAGER:IsShowing(GAMEPAD_TRADING_HOUSE_SCENE_NAME) then
            if self.m_currentObject then
				self.m_currentObject:Hide()
            end

			selectedData.object:Show()
            self:RefreshHeaderData()
        end
        
        self.m_currentObject = selectedData.object
    end

    local browseData = CreateModeData(SI_TRADING_HOUSE_MODE_BROWSE, ZO_TRADING_HOUSE_MODE_BROWSE, GAMEPAD_TRADING_HOUSE_BROWSE_MANAGER)
    local sellData = CreateModeData(SI_TRADING_HOUSE_MODE_SELL, ZO_TRADING_HOUSE_MODE_SELL, GAMEPAD_TRADING_HOUSE_SELL)
    local listingData = CreateModeData(SI_TRADING_HOUSE_MODE_LISTINGS, ZO_TRADING_HOUSE_MODE_LISTINGS, GAMEPAD_TRADING_HOUSE_LISTINGS)

    self.m_modeObjects = { browseData.object, sellData.object, listingData.object }

    self.m_tabsTable = {
        {
            text = GetString(SI_TRADING_HOUSE_MODE_BROWSE),
            callback = function() OnCategoryChanged(browseData) end,
        },
        {
            text = GetString(SI_TRADING_HOUSE_MODE_SELL),
            callback = function() OnCategoryChanged(sellData) end,
        },
        {
            text = GetString(SI_TRADING_HOUSE_MODE_LISTINGS),
            callback = function() OnCategoryChanged(listingData) end,
        },
    }

    self.m_headerData = {
		data1HeaderText = GetGuildTitle,
		data1Text = GetGuildName,

        data2HeaderText = GetString(SI_GAMEPAD_GUILD_BANK_AVAILABLE_FUNDS),
        data2Text = UpdateGold,

        data3HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data3Text = GetCapacityString,

        tabBarEntries = self.m_tabsTable
    }

    ZO_GamepadGenericHeader_Refresh(self.m_header, self.m_headerData)
end

function ZO_GamepadTradingHouse:RefreshHeaderData()
    ZO_GamepadGenericHeader_RefreshData(self.m_header, self.m_headerData)
end

function ZO_GamepadTradingHouse:OnInitialInteraction()
    for i, object in ipairs(self.m_modeObjects) do
        object:OnInitialInteraction()
    end
end

function ZO_GamepadTradingHouse:OnEndInteraction()
    for i, object in ipairs(self.m_modeObjects) do
        object:OnEndInteraction()
    end
end

function ZO_GamepadTradingHouse:UpdateForGuildChange()
    for i, object in ipairs(self.m_modeObjects) do
        object:UpdateForGuildChange()
    end
    self:SetSearchAllowed(true)
    self:RefreshHeaderData()
end

function ZO_GamepadTradingHouse:InitializeScene()
    TRADING_HOUSE_GAMEPAD_SCENE:GetSceneGroup():RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_GROUP_SHOWING then
			self:OnInitialInteraction()
            self:SetSearchAllowed(true)
        elseif newState == SCENE_GROUP_HIDDEN then
            self:OnEndInteraction()
        end
	end)

    TRADING_HOUSE_GAMEPAD_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
			ZO_GamepadGenericHeader_Activate(self.m_header)
			ZO_GamepadGenericHeader_SetActiveTabIndex(self.m_header, self:GetCurrentMode())
            self:RefreshHeaderData()
            self:RegisterForSceneEvents()
        elseif newState == SCENE_SHOWN then
            -- This is in SCENE_SHOWN because SCENE_GROUP_SHOWING fires after SCENE_SHOWING and OnInitialInteraction needs to be called before the curren object is shown
            if self.m_currentObject then
                self.m_currentObject:Show()
            end
        elseif newState == SCENE_HIDDEN then
            self:UnregisterForSceneEvents()
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
			ZO_GamepadGenericHeader_Deactivate(self.m_header)
			if self.m_currentObject then
				self.m_currentObject:Hide()
			end
		end
	end)
end

function ZO_GamepadTradingHouse:RegisterForSceneEvents()
    local function RefreshHeader()
        self:RefreshHeaderData()
    end

    self.m_control:RegisterForEvent(EVENT_MONEY_UPDATE, RefreshHeader)
    self.m_control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, RefreshHeader)
    self.m_control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, RefreshHeader)
end

function ZO_GamepadTradingHouse:UnregisterForSceneEvents()
    self.m_control:UnregisterForEvent(EVENT_MONEY_UPDATE)
    self.m_control:UnregisterForEvent(EVENT_INVENTORY_FULL_UPDATE)
    self.m_control:UnregisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
end

function ZO_GamepadTradingHouse:InitializeTabEvents()
    self.m_tabEventTable = {}

    for event, _ in pairs(self.m_eventCallbacks) do
        self.m_tabEventTable[event] = {}
    end

    for _, object in ipairs(self.m_modeObjects) do
        object:RegisterForEvents(self.m_tabEventTable)
    end
end

function ZO_GamepadTradingHouse:InitializeKeybindStripDescriptors()
end

function ZO_GamepadTradingHouse:PerformDeferredInitialization()
    if self.m_isInitialized then return end

    self:InitializeKeybindStripDescriptors()
    self:InitializeHeader()
    self:InitializeScene()
    self:InitializeSharedEvents()
    self:InitializeTabEvents()
	self:InitializeSearchTerms()

    self.m_isInitialized = true
end

function ZO_GamepadTradingHouse:FireTabEvents(event, ...)
    if self.m_tabEventTable[event] ~= nil then
        for _, callback in ipairs(self.m_tabEventTable[event]) do
            callback(...)
        end
    end

    if self.m_currentObject then
        self.m_currentObject:UpdateKeybind()
    end

    self:RefreshHeaderData()
end

function ZO_GamepadTradingHouse:OpenTradingHouse()
    self:SetCurrentMode(ZO_TRADING_HOUSE_MODE_BROWSE)
    self:PerformDeferredInitialization()
end

function ZO_GamepadTradingHouse:CloseTradingHouse()
    if SCENE_MANAGER:IsShowing("gamepad_trading_house_create_listing") then
       SCENE_MANAGER:PopScenes(2)
    else
        SYSTEMS:HideScene(ZO_TRADING_HOUSE_SYSTEM_NAME)
    end
    self:SetCurrentMode(nil)
end

function ZO_GamepadTradingHouse:UpdateStatus(...)
    self:FireTabEvents(EVENT_TRADING_HOUSE_STATUS_RECEIVED, ...)
end

function ZO_GamepadTradingHouse:OnOperationTimeout(...)
    self:FireTabEvents(EVENT_TRADING_HOUSE_OPERATION_TIME_OUT, ...)
end

function ZO_GamepadTradingHouse:OnSearchCooldownUpdate(...)
    self:FireTabEvents(EVENT_TRADING_HOUSE_SEARCH_COOLDOWN_UPDATE, ...)
end

function ZO_GamepadTradingHouse:OnPendingPostItemUpdated(...)
    self:FireTabEvents(EVENT_TRADING_HOUSE_PENDING_ITEM_UPDATE, ...)
end

function ZO_GamepadTradingHouse:OnAwaitingResponse(...)
	self:FireTabEvents(EVENT_TRADING_HOUSE_AWAITING_RESPONSE, ...)
    ZO_GamepadGenericHeader_Deactivate(self.m_header)
    self.m_loading:SetHidden(false)
    self.m_currentObject:SetAwaitingResponse(true)
end

function ZO_GamepadTradingHouse:OnResponseReceived(...)
	self:FireTabEvents(EVENT_TRADING_HOUSE_RESPONSE_RECEIVED, ...)
    ZO_GamepadGenericHeader_Activate(self.m_header)
    self.m_loading:SetHidden(true)
    self.m_currentObject:SetAwaitingResponse(false)
end

function ZO_GamepadTradingHouse:OnSearchResultsReceived(...)
	self:FireTabEvents(EVENT_TRADING_HOUSE_SEARCH_RESULTS_RECEIVED, ...)
end

function ZO_GamepadTradingHouse:ConfirmPendingPurchase(...)
	self:FireTabEvents(EVENT_TRADING_HOUSE_CONFIRM_ITEM_PURCHASE, ...)
end

function ZO_GamepadTradingHouse:InitializeSearchTerms()
    self.m_search = ZO_TradingHouseSearch:New()
    GAMEPAD_TRADING_HOUSE_BROWSE:InitializeSearchTerms(self.m_search)
    self.m_traitFilters = ZO_GamepadTradingHouse_TraitFilters:New()
    self.m_enchantmentFilters = ZO_GamepadTradingHouse_EnchantmentFilters:New()
end

function ZO_GamepadTradingHouse:AddSearchSetter(setterObject)
    self.m_search:AddSetter(setterObject)
end

function ZO_GamepadTradingHouse:AllowSearch()
    self.m_searchAllowed = true
end

function ZO_GamepadTradingHouse:GetSearchAllowed()
    return self.m_searchAllowed
end

function ZO_GamepadTradingHouse:SetSearchAllowed(searchAllowed)
    self.m_searchAllowed = searchAllowed
end

function ZO_GamepadTradingHouse:SetSearchPageData(currentPage, hasMorePages)
    self.m_search:SetPageData(currentPage, hasMorePages)
end

function ZO_GamepadTradingHouse:SearchNextPage()
    self.m_search:SearchNextPage()
end

function ZO_GamepadTradingHouse:SearchPreviousPage()
    self.m_search:SearchPreviousPage()
end

function ZO_GamepadTradingHouse:UpdateSortOption(...)
    self.m_search:UpdateSortOption(...)
end

function ZO_GamepadTradingHouse:InitializeFilterFactory(entry, filterFactory, filterStringId)
    if not self.m_registeredFilterObjects[filterStringId] then
        self.m_registeredFilterObjects[filterStringId] = filterFactory:New()
    end

    entry.filterObject = self.m_registeredFilterObjects[filterStringId]
end

function ZO_GamepadTradingHouse:AddSearchSetter(setter)
    self.m_search:AddSetter(setter)
end

function ZO_GamepadTradingHouse:AddGuildSpecificItems(...)
    GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:AddGuildSpecificItems(...)
end

--[[ Globals ]]--

function ZO_TradingHouse_Gamepad_Initialize(control)
    TRADING_HOUSE_GAMEPAD = ZO_GamepadTradingHouse:New(control)
	SYSTEMS:RegisterGamepadObject(ZO_TRADING_HOUSE_SYSTEM_NAME, TRADING_HOUSE_GAMEPAD)
end

function ZO_TradingHouse_Gamepad_AddSearchSetter(setter)
    TRADING_HOUSE_GAMEPAD:AddSearchSetter(setter)
end