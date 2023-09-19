ZO_EndlessDungeonBuffSelector_Keyboard = ZO_EndlessDungeonBuffSelector_Shared:Subclass()

function ZO_EndlessDungeonBuffSelector_Keyboard:Initialize(...)
    ZO_EndlessDungeonBuffSelector_Shared.Initialize(self, ...)

    ENDLESS_DUNGEON_BUFF_SELECTOR_SCENE_KEYBOARD = self:GetScene()
    SYSTEMS:RegisterKeyboardRootScene("endlessDungeonBuffSelector", ENDLESS_DUNGEON_BUFF_SELECTOR_SCENE_KEYBOARD)
end

function ZO_EndlessDungeonBuffSelector_Keyboard:SetupBuffControl(buffControl, previousBuffControl)
    ZO_EndlessDungeonBuffSelector_Shared.SetupBuffControl(self, buffControl, previousBuffControl)

    buffControl:SetHandler("OnMouseEnter", function()
        self:SelectBuff(buffControl)
    end)

    buffControl:SetHandler("OnMouseExit", function()
        self:DeselectBuff(buffControl)
    end)
end

function ZO_EndlessDungeonBuffSelector_Keyboard:OnBuffDoubleClick(buffControl)
    self:SelectBuff(buffControl)
    self:CommitChoice()
end

function ZO_EndlessDungeonBuffSelector_Keyboard:SelectBuff(buffControl)
    ZO_EndlessDungeonBuffSelector_Shared.SelectBuff(self, buffControl)

    InitializeTooltip(AbilityIconTooltip, self.control, RIGHT, -5, 0, LEFT)
    AbilityIconTooltip:SetAbilityId(buffControl.abilityId)
end

function ZO_EndlessDungeonBuffSelector_Keyboard:DeselectBuff(buffControl)
    ZO_EndlessDungeonBuffSelector_Shared.DeselectBuff(self, buffControl)

    ClearTooltip(AbilityIconTooltip)
end

function ZO_EndlessDungeonBuffSelector_Keyboard:GetSceneName()
    return "endlessDungeonBuffSelectorKeyboard"
end

function ZO_EndlessDungeonBuffSelector_Keyboard:GetBuffTemplate()
    return "ZO_EndDunBuffSelectorBuff_Keyboard"
end

function ZO_EndlessDungeonBuffSelector_Keyboard.OnControlInitialized(control)
    ENDLESS_DUNGEON_BUFF_SELECTOR_KEYBOARD = ZO_EndlessDungeonBuffSelector_Keyboard:New(control)
end

