ZO_EndlessDungeonBuffSelector_Keyboard = ZO_EndlessDungeonBuffSelector_Shared:Subclass()

function ZO_EndlessDungeonBuffSelector_Keyboard:Initialize(...)
    ZO_EndlessDungeonBuffSelector_Shared.Initialize(self, ...)

    ENDLESS_DUNGEON_BUFF_SELECTOR_SCENE_KEYBOARD = self:GetScene()
    SYSTEMS:RegisterKeyboardRootScene("endlessDungeonBuffSelector", ENDLESS_DUNGEON_BUFF_SELECTOR_SCENE_KEYBOARD)
end

function ZO_EndlessDungeonBuffSelector_Keyboard:InitializeControls()
    ZO_EndlessDungeonBuffSelector_Shared.InitializeControls(self)
    self.rerollButton = self.control:GetNamedChild("RerollButton")
    self.currencyLabel = self.control:GetNamedChild("Currency")
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

function ZO_EndlessDungeonBuffSelector_Keyboard:OnShowing()
    ZO_EndlessDungeonBuffSelector_Shared.OnShowing(self)
    local canRerollBuffs = CanRerollCurrentBuffSelectorOptions()
    self.rerollButton:SetHidden(not canRerollBuffs)
    self.currencyLabel:SetHidden(not canRerollBuffs)
end

function ZO_EndlessDungeonBuffSelector_Keyboard:RefreshBuffs()
    ZO_EndlessDungeonBuffSelector_Shared.RefreshBuffs(self)
    if CanRerollCurrentBuffSelectorOptions() then
        local rerollCost = GetEndlessDungeonBuffSelectorRerollCost()
        local currencyAmount = GetCurrencyAmount(CURT_ARCHIVAL_FORTUNES, GetCurrencyPlayerStoredLocation(CURT_ARCHIVAL_FORTUNES))
        local IS_KEYBOARD = false
        local canAffordReroll = rerollCost <= currencyAmount
        self.rerollButton:SetEnabled(canAffordReroll)
        rerollCost = ZO_Currency_Format(rerollCost, CURT_ARCHIVAL_FORTUNES, ZO_CURRENCY_FORMAT_AMOUNT_ICON, IS_KEYBOARD)
        currencyAmount = ZO_Currency_Format(currencyAmount, CURT_ARCHIVAL_FORTUNES, ZO_CURRENCY_FORMAT_AMOUNT_ICON, IS_KEYBOARD)
        local rerollLabelText = zo_strformat(SI_ENDLESS_DUNGEON_REROLL_BUFFS_LABEL, zo_iconFormat("EsoUI/Art/EndlessDungeon/reroll_buffs.dds", "200%", "200%"), rerollCost)
        self.rerollButton:SetText(rerollLabelText)

        local IS_PLURAL = false
        local IS_MIXED_CASE = false
        local currencyName = GetCurrencyName(CURT_ARCHIVAL_FORTUNES, IS_PLURAL, IS_MIXED_CASE)
        self.currencyLabel:SetText(zo_strformat(SI_ENDLESS_DUNGEON_BUFF_SELECTOR_CURRENCY_FORMAT, currencyName, currencyAmount))
    end
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

function ZO_EndlessDungeonBuffSelector_Keyboard.OnRerollButtonClicked(control)
    if CanRerollCurrentBuffSelectorOptions() then
        RerollEndlessDungeonBuffSelection()
        ENDLESS_DUNGEON_BUFF_SELECTOR_KEYBOARD:SetIsRerolling(true)
    end
end

function ZO_EndlessDungeonBuffSelector_Keyboard.OnRerollButtonMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, RIGHT, -5, 0)
    SetTooltipText(InformationTooltip, GetString(SI_ENDLESS_DUNGEON_BUFF_SELECTOR_REROLL_INFORMATION))
end

function ZO_EndlessDungeonBuffSelector_Keyboard.OnRerollButtonMouseExit(control)
    ClearTooltip(InformationTooltip)
end