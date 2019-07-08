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
end

function ZO_GamepadTradingHouse_BaseList:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = {}
end

function ZO_GamepadTradingHouse_BaseList:UpdateKeybind()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadTradingHouse_BaseList:Hide()
    TRADING_HOUSE_GAMEPAD_SUBSCENE_MANAGER:Hide(self:GetSubscene():GetName())
end

function ZO_GamepadTradingHouse_BaseList:Show()
    TRADING_HOUSE_GAMEPAD_SUBSCENE_MANAGER:Show(self:GetSubscene():GetName())
end

do
    local function FilterForGamepadEvents(callback)
        return function(...)
            if IsInGamepadPreferredMode() then
                callback(...)
            end
        end
    end

    function ZO_GamepadTradingHouse_BaseList:RegisterForTradingHouseEvent(event, callback)
        self.control:RegisterForEvent(event, FilterForGamepadEvents(callback))
    end
end

function ZO_GamepadTradingHouse_BaseList:AddGuildChangeKeybindDescriptor(keybindStripDescriptor)
    table.insert(keybindStripDescriptor,
    {
        name = GetString(SI_TRADING_HOUSE_GUILD_HEADER),
        keybind = "UI_SHORTCUT_TERTIARY",
        callback = function()
            ZO_Dialogs_ShowPlatformDialog("TRADING_HOUSE_CHANGE_ACTIVE_GUILD")
        end,
        visible = function()
            return GetNumTradingHouseGuilds() > 1
        end,
    })
end

-- Functions to be overridden

function ZO_GamepadTradingHouse_BaseList:InitializeEvents()
    TRADING_HOUSE_GAMEPAD:RegisterCallback("OnLockedForInput", function(...) self:OnLockedForInput(...) end)
    TRADING_HOUSE_GAMEPAD:RegisterCallback("OnUnlockedForInput", function(...) self:OnUnlockedForInput(...) end)
end

function ZO_GamepadTradingHouse_BaseList:GetSubscene()
    assert(false) -- This should never be reached, must be overridden
end

function ZO_GamepadTradingHouse_BaseList:GetTradingHouseMode()
    return nil -- should be overriden
end

function ZO_GamepadTradingHouse_BaseList:GetHeaderReplacementInfo()
    -- returns isReplacementActive, replacementTitleText: should be overridden
    return false, ""
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

function ZO_GamepadTradingHouse_BaseList:OnLockedForInput()
    --should be overridden
end

function ZO_GamepadTradingHouse_BaseList:OnUnlockedForInput()
    --should be overridden
end

function ZO_GamepadTradingHouse_BaseList:Deactivate()
    --should be overridden
end

function ZO_GamepadTradingHouse_BaseList:Activate()
    --should be overridden
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
    self:InitializeFragment()
    self:InitializeKeybindStripDescriptors()
    ZO_GamepadTradingHouse_BaseList.Initialize(self)
end

function ZO_GamepadTradingHouse_ItemList:GetKeyBind()
    return self.keybindStripDescriptor
end

function ZO_GamepadTradingHouse_ItemList:InitializeFragment()
    local ALWAYS_ANIMATE = true
    self.fragment = ZO_CreateQuadrantConveyorFragment(self.control, ALWAYS_ANIMATE)
    self.subscene = ZO_Scene:New(self.control:GetName().."Scene", TRADING_HOUSE_GAMEPAD_SUBSCENE_MANAGER)
    self.subscene:AddFragment(self.fragment)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:Activate()
            self:UpdateList()
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            self:OnShown()
        elseif newState == SCENE_FRAGMENT_HIDING then
            self:OnHiding()
            self:Deactivate()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)
end

function ZO_GamepadTradingHouse_ItemList:GetFragment()
    return self.fragment
end

function ZO_GamepadTradingHouse_ItemList:GetSubscene()
    return self.subscene
end

function ZO_GamepadTradingHouse_ItemList:InitializeList()
    self.itemList = ZO_GamepadVerticalItemParametricScrollList:New(self.control:GetNamedChild("List"))
end

function ZO_GamepadTradingHouse_ItemList:OnLockedForInput()
    self.listControl:SetHidden(true)
    if not self.control:IsHidden() then
        self.itemList:Deactivate()
        self:UpdateKeybind()
    end
end

function ZO_GamepadTradingHouse_ItemList:OnUnlockedForInput()
    self.listControl:SetHidden(false)
    if not self.control:IsHidden() then
        self.itemList:Activate() 
        self:UpdateKeybind()
    end
end

function ZO_GamepadTradingHouse_ItemList:Deactivate()
    self.itemList:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadTradingHouse_ItemList:Activate()
    self.itemList:Activate() 
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

-- Functions to be overridden

function ZO_GamepadTradingHouse_ItemList:UpdateList()
    --should be overridden
end

--[[ Globals ]]--

function ZO_TradingHouse_ItemListRow_Gamepad_OnInitialized(control)
    ZO_SharedGamepadEntry_OnInitialized(control)
    ZO_SharedGamepadEntry_SetHeightFromLabels(control)
    control.price = control:GetNamedChild("Price")
end
