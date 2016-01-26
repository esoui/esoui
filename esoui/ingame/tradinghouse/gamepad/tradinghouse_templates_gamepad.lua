ZO_TRADINGHOUSE_TIMELEFT_GAMEPAD_OFFSET_Y = 40

------------------
-- Base List
------------------

ZO_GamepadTradingHouse_BaseList = ZO_Object:Subclass() 

function ZO_GamepadTradingHouse_BaseList:New(...)
    local list = ZO_Object.New(self)
    list:Initialize(...)
    return list
end

function ZO_GamepadTradingHouse_BaseList:Initialize()
    self.eventCallbacks = {}
    self:InitializeEvents()
    self:InitializeKeybindStripDescriptors()
end

function ZO_GamepadTradingHouse_BaseList:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = {}
end

function ZO_GamepadTradingHouse_BaseList:UpdateKeybind()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadTradingHouse_BaseList:Hide()
	SCENE_MANAGER:RemoveFragmentGroup(self:GetFragmentGroup())
end

function ZO_GamepadTradingHouse_BaseList:Show()
	SCENE_MANAGER:AddFragmentGroup(self:GetFragmentGroup())
end

function ZO_GamepadTradingHouse_BaseList:SetEventCallback(event, callback)
    self.eventCallbacks[event] = callback
end

function ZO_GamepadTradingHouse_BaseList:RegisterForEvents(eventTable)
    if self.eventCallbacks then
        for event, callback in pairs(self.eventCallbacks) do
            if eventTable[event] ~= nil then
                table.insert(eventTable[event], callback)
            end
        end
    end
end

function ZO_GamepadTradingHouse_BaseList:DisplayErrorDialog(errorMessage)
    ZO_Dialogs_ShowPlatformDialog("TRADING_HOUSE_DISPLAY_ERROR", {}, {mainTextParams = {errorMessage}})
end

function ZO_GamepadTradingHouse_BaseList:DisplayChangeGuildDialog()
    ZO_Dialogs_ShowPlatformDialog("TRADING_HOUSE_CHANGE_ACTIVE_GUILD")
end

function ZO_GamepadTradingHouse_BaseList:SetAwaitingResponse(awaitingResponse)
    self.awaitingResponse = awaitingResponse
    if awaitingResponse then
        self:DeactivateForResponse()
    else
        self:ActivateOnResponse()
    end

    if not self.control:IsHidden() then
        self:UpdateKeybind()
    end
end

-- Functions to be overridden

function ZO_GamepadTradingHouse_BaseList:InitializeList()
    --- should be overridden to add in templates to parametric list & handle needed callbacks
end

function ZO_GamepadTradingHouse_BaseList:InitializeEvents()
	--should be overridden
end

function ZO_GamepadTradingHouse_BaseList:GetFragmentGroup()
	assert(false) -- This should never be reached, must be overridden
end

function ZO_GamepadTradingHouse_BaseList:OnInitialInteraction()
    --should be overridden
end

function ZO_GamepadTradingHouse_BaseList:OnEndInteraction()
    --should be overridden
end

function ZO_GamepadTradingHouse_BaseList:UpdateForGuildChange()
    --should be overridden
end

function ZO_GamepadTradingHouse_BaseList:OnHiding()
    --should be overridden
end

function ZO_GamepadTradingHouse_BaseList:OnHidden()
    --should be overridden
end

function ZO_GamepadTradingHouse_BaseList:OnShowing()
    --should be overridden
end

function ZO_GamepadTradingHouse_BaseList:OnShown()
    --should be overridden
end

function ZO_GamepadTradingHouse_BaseList:DeactivateForResponse()
    self.listControl:SetHidden(true)
    self.itemList:Deactivate()
end

function ZO_GamepadTradingHouse_BaseList:ActivateOnResponse()
    self.listControl:SetHidden(false)
    if not self.control:IsHidden() then
        self.itemList:Activate() 
    end
end

function ZO_GamepadTradingHouse_BaseList:HasNoCooldown()
    return GetTradingHouseCooldownRemaining() == 0 
end

------------------
-- Item List
------------------

ZO_GamepadTradingHouse_ItemList = ZO_GamepadTradingHouse_BaseList:Subclass()

function ZO_GamepadTradingHouse_ItemList:New(...)
    return ZO_GamepadTradingHouse_BaseList.New(self, ...)
end

function ZO_GamepadTradingHouse_ItemList:Initialize(control)
    self.control = control
    control.owner = self
    self.listControl = self.control:GetNamedChild("List")
    self:InitializeList()
    ZO_GamepadTradingHouse_BaseList.Initialize(self)
end

function ZO_GamepadTradingHouse_ItemList:GetKeyBind()
	return self.keybindStripDescriptor
end

function ZO_GamepadTradingHouse_ItemList:SetFragment(fragment)
	self.fragment = fragment
    fragment:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_SHOWING then
            self:UpdateList()
            if not self.awaitingResponse then
                self.itemList:Activate()
            end
            
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self:OnShowing()
		elseif newState == SCENE_SHOWN then
            self:OnShown()
        elseif newState == SCENE_HIDING then
			self:OnHiding()
            self.itemList:Deactivate()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
		elseif newState == SCENE_HIDDEN then
            self:OnHidden()
        end
    end)
end

function ZO_GamepadTradingHouse_ItemList:InitializeList()
    self.itemList = ZO_GamepadVerticalItemParametricScrollList:New(self.control:GetNamedChild("List"))
end

-- Functions to be overridden

function ZO_GamepadTradingHouse_ItemList:UpdateList()
	--should be overridden
end

----------------------
-- Sortable Item List
----------------------

ZO_GamepadTradingHouse_SortableItemList = ZO_Object.MultiSubclass(ZO_GamepadTradingHouse_BaseList, ZO_SortableParametricList)

ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_TIME = "time"
ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_NAME = "name"
ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_PRICE = "price"

function ZO_GamepadTradingHouse_SortableItemList:New(...)
    return ZO_SortableParametricList.New(self, ...)
end

function ZO_GamepadTradingHouse_SortableItemList:Initialize(control, initialSortKey, useHighlight)
    ZO_SortableParametricList.Initialize(self, control, useHighlight)
    ZO_GamepadTradingHouse_BaseList.Initialize(self)
    self.initialSortKey = initialSortKey
    self:InitializeSortOptions()
end

local NAME_SORT_KEYS =
{
    name = {tiebreaker = "time"},
    time = {}
}

local TIME_SORT_KEYS =
{
    time = {tiebreaker = "name"},
    name = {}
}

local PRICE_SORT_KEYS =
{
    price = {tiebreaker = "name"},
    name = {}
}

local tradingHouseSortOptions = {
    [ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_TIME] = TIME_SORT_KEYS,
    [ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_NAME] = NAME_SORT_KEYS,
    [ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_PRICE] = PRICE_SORT_KEYS,
}

function ZO_GamepadTradingHouse_SortableItemList:GetKeyBind()
	return self.keybindStripDescriptor
end

function ZO_GamepadTradingHouse_SortableItemList:SetFragment(fragment)
	self.fragment = fragment
    fragment:RegisterCallback("StateChange", function(oldState, newState)
		if newState == SCENE_SHOWING then
            self:Activate()
			self:RequestListUpdate()
			KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self:OnShowing()
		elseif newState == SCENE_SHOWN then
            self:OnShown()
        elseif newState == SCENE_HIDING then
			self:OnHiding()
			self:Deactivate()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        elseif newState == SCENE_HIDDEN then
            self:OnHidden()
        end
    end)
end

function ZO_GamepadTradingHouse_SortableItemList:InitializeSortOptions()
    self.currentTimePriceKey = ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_TIME
    self.toggleTimePriceKey = ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_PRICE
    self:SetSortOptions(tradingHouseSortOptions)
end

function ZO_GamepadTradingHouse_SortableItemList:ResetSortOptions()
    if self.currentTimePriceKey ~= self.initialSortKey then
        self:ToggleSortOptions()
    end
end

function ZO_GamepadTradingHouse_SortableItemList:SelectInitialSortOption()
    if self.initialSortKey then
        self:SelectAndResetSortForKey(self.initialSortKey)
    end
end

local function GetTextForKey(key)
    if key == ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_PRICE then
        return GetString(SI_TRADING_HOUSE_SORT_TYPE_PRICE)
    else
        return GetString(SI_TRADING_HOUSE_SORT_TYPE_TIME)
    end
end

function ZO_GamepadTradingHouse_SortableItemList:GetTextForCurrentTimePriceKey()
    return GetTextForKey(self.currentTimePriceKey)
end

function ZO_GamepadTradingHouse_SortableItemList:GetTextForToggleTimePriceKey()
    return GetTextForKey(self.toggleTimePriceKey)
end

function ZO_GamepadTradingHouse_SortableItemList:ToggleSortOptions()
    local SELECT_NEW_KEY = true
    self:ReplaceKey(self.currentTimePriceKey, self.toggleTimePriceKey, self:GetTextForToggleTimePriceKey(), SELECT_NEW_KEY)
    self.currentTimePriceKey, self.toggleTimePriceKey = self.toggleTimePriceKey, self.currentTimePriceKey
    self:RefreshSort()
    self:UpdateKeybind()
end

-- Functions to be overridden

function ZO_GamepadTradingHouse_SortableItemList:BuildList()
    -- intended to be overriden
    -- should populate the itemList by calling AddEntry
end

function ZO_GamepadTradingHouse_SortableItemList:RequestListUpdate()
    -- intended to be overridden if needed
    -- use to send a message to the server that a list update is needed
    -- response from that message should call RefreshData
end

--[[ Globals ]]--

function ZO_TradingHouse_ItemListRow_Gamepad_OnInitialized(control)
	ZO_SharedGamepadEntry_OnInitialized(control)
end