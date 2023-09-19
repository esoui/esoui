ZO_EndlessDungeonBuffSelector_Gamepad = ZO_EndlessDungeonBuffSelector_Shared:Subclass()

function ZO_EndlessDungeonBuffSelector_Gamepad:Initialize(...)
    ZO_EndlessDungeonBuffSelector_Shared.Initialize(self, ...)

    ENDLESS_DUNGEON_BUFF_SELECTOR_SCENE_GAMEPAD = self:GetScene()
    SYSTEMS:RegisterGamepadRootScene("endlessDungeonBuffSelector", ENDLESS_DUNGEON_BUFF_SELECTOR_SCENE_GAMEPAD)
end

function ZO_EndlessDungeonBuffSelector_Gamepad:OnDeferredInitialize()
    ZO_EndlessDungeonBuffSelector_Shared.OnDeferredInitialize(self)

    self:InitializeNarrationInfo()
end

function ZO_EndlessDungeonBuffSelector_Gamepad:InitializeNarrationInfo()
    local narrationInfo =
    {
        canNarrate = function()
            return self:IsShowing()
        end,

        headerNarrationFunction = function()
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.titleText)
        end,

        -- Selection narrated via tooltip
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("EndlessDungeonBuffSelector", narrationInfo)
end

function ZO_EndlessDungeonBuffSelector_Gamepad:InitializeControls()
    local DEFAULT_MOVEMENT_CONTROL = nil
    self.focus = ZO_GamepadFocus:New(self.control, DEFAULT_MOVEMENT_CONTROL, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.focus:SetPlaySoundFunction(function() PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED) end)

    ZO_EndlessDungeonBuffSelector_Shared.InitializeControls(self)
end

function ZO_EndlessDungeonBuffSelector_Gamepad:SetupBuffControl(buffControl, previousBuffControl)
    ZO_EndlessDungeonBuffSelector_Shared.SetupBuffControl(self, buffControl, previousBuffControl)

    local focusEntry =
    {
        control = buffControl,
        highlight = buffControl.iconTexture:GetNamedChild("Highlight"),
        canFocus = function(control) return not control:IsHidden() end,
        activate = function(control) self:SelectBuff(control) end,
        deactivate = function(control) self:DeselectBuff(control) end,
    }
    self.focus:AddEntry(focusEntry)
end

function ZO_EndlessDungeonBuffSelector_Gamepad:SelectBuff(buffControl)
    ZO_EndlessDungeonBuffSelector_Shared.SelectBuff(self, buffControl)

    GAMEPAD_TOOLTIPS:LayoutEndlessDungeonBuffAbility(GAMEPAD_RIGHT_TOOLTIP, buffControl.abilityId)
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("EndlessDungeonBuffSelector", self.narrateHeader)
end

function ZO_EndlessDungeonBuffSelector_Gamepad:DeselectBuff(buffControl)
    ZO_EndlessDungeonBuffSelector_Shared.DeselectBuff(self, buffControl)

    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_EndlessDungeonBuffSelector_Gamepad:OnShowing()
    ZO_EndlessDungeonBuffSelector_Shared.OnShowing(self)
    
    --Narrate the header when first showing
    self.narrateHeader = true
    self.focus:Activate()
    self.narrateHeader = false
end

function ZO_EndlessDungeonBuffSelector_Gamepad:OnHiding()
    ZO_EndlessDungeonBuffSelector_Shared.OnHiding(self)

    self.focus:Deactivate()
end

function ZO_EndlessDungeonBuffSelector_Gamepad:GetSceneName()
    return "endlessDungeonBuffSelectorGamepad"
end

function ZO_EndlessDungeonBuffSelector_Gamepad:GetBuffTemplate()
    return "ZO_EndDunBuffSelectorBuff_Gamepad"
end

function ZO_EndlessDungeonBuffSelector_Gamepad.OnControlInitialized(control)
    ENDLESS_DUNGEON_BUFF_SELECTOR_GAMEPAD = ZO_EndlessDungeonBuffSelector_Gamepad:New(control)
end

