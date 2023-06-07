-- Ability Bar settings helper function

local function AreAbilityBarsEnabled()
    return tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_ACTION_BAR)) ~= ACTION_BAR_SETTING_CHOICE_OFF
end

local function AreAbilityBarTimersEnabled()
    return tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_ACTION_BAR_TIMERS)) ~= 0
end

local function IsAbilityBarBackRowEnabled()
    return AreAbilityBarsEnabled() and AreAbilityBarTimersEnabled()
end

local function OnAbilityBarsEnabledChanged(control)
    ZO_SetControlActiveFromPredicate(control, AreAbilityBarsEnabled)
end

local function OnAbilityBarTimersEnabledChanged(control)
    ZO_SetControlActiveFromPredicate(control, AreAbilityBarTimersEnabled)
end

local function OnAbilityBarBackRowEnabledChanged(control)
    ZO_SetControlActiveFromPredicate(control, IsAbilityBarBackRowEnabled)
end

-- SCT settings helper functions

local function IsSCTEnabled()
    return tonumber(GetSetting(SETTING_TYPE_COMBAT, COMBAT_SETTING_SCROLLING_COMBAT_TEXT_ENABLED)) ~= 0
end

local function OnSCTEnabledChanged(control)
    ZO_SetControlActiveFromPredicate(control, IsSCTEnabled)
end

local function IsSCTAndOutgoingEnabled()
    return IsSCTEnabled() and tonumber(GetSetting(SETTING_TYPE_COMBAT, COMBAT_SETTING_SCT_OUTGOING_ENABLED)) ~= 0
end

local function OnSCTOrOutgoingEnabledChanged(control)
    ZO_SetControlActiveFromPredicate(control, IsSCTAndOutgoingEnabled)
end

local function IsSCTAndIncomingEnabled()
    return IsSCTEnabled() and tonumber(GetSetting(SETTING_TYPE_COMBAT, COMBAT_SETTING_SCT_INCOMING_ENABLED)) ~= 0
end

local function OnSCTOrIncomingEnabledChanged(control)
    ZO_SetControlActiveFromPredicate(control, IsSCTAndIncomingEnabled)
end

local function GenerateSCTOutgoingOption(optionType)
    local option =
    {
        controlType = OPTIONS_CHECKBOX,
        system = SETTING_TYPE_COMBAT,
        settingId = _G["COMBAT_SETTING_SCT_OUTGOING_"..optionType.."_ENABLED"],
        panel = SETTING_PANEL_COMBAT,
        text = _G["SI_INTERFACE_OPTIONS_COMBAT_SCT_OUTGOING_"..optionType.."_ENABLED"],
        tooltipText = _G["SI_INTERFACE_OPTIONS_COMBAT_SCT_OUTGOING_"..optionType.."_ENABLED_TOOLTIP"],
        eventCallbacks =
        {
            ["SCTEnabled_Changed"] = OnSCTOrOutgoingEnabledChanged,
            ["SCTOutgoingEnabled_Changed"] = OnSCTOrOutgoingEnabledChanged,
        },
        gamepadIsEnabledCallback = IsSCTAndOutgoingEnabled,
    }
    return option
end

local function GenerateSCTIncomingOption(optionType)
    local option =
    {
        controlType = OPTIONS_CHECKBOX,
        system = SETTING_TYPE_COMBAT,
        settingId = _G["COMBAT_SETTING_SCT_INCOMING_"..optionType.."_ENABLED"],
        panel = SETTING_PANEL_COMBAT,
        text = _G["SI_INTERFACE_OPTIONS_COMBAT_SCT_INCOMING_"..optionType.."_ENABLED"],
        tooltipText = _G["SI_INTERFACE_OPTIONS_COMBAT_SCT_INCOMING_"..optionType.."_ENABLED_TOOLTIP"],
        eventCallbacks =
        {
            ["SCTEnabled_Changed"] = OnSCTOrIncomingEnabledChanged,
            ["SCTIncomingEnabled_Changed"] = OnSCTOrIncomingEnabledChanged,
        },
        gamepadIsEnabledCallback = IsSCTAndIncomingEnabled,
    }
    return option
end

-- Buff/Debuff settings helper functions

local function IsBuffDebuffEnabled()
    return tonumber(GetSetting(SETTING_TYPE_BUFFS, BUFFS_SETTING_ALL_ENABLED)) ~= 0
end

local function OnBuffDebuffEnabledChanged(control)
    ZO_SetControlActiveFromPredicate(control, IsBuffDebuffEnabled)
end

local function AreBuffsEnabled()
    return IsBuffDebuffEnabled() and tonumber(GetSetting(SETTING_TYPE_BUFFS, BUFFS_SETTING_BUFFS_ENABLED)) ~= BUFF_DEBUFF_ENABLED_CHOICE_DONT_SHOW
end

local function OnBuffsEnabledChanged(control)
    ZO_SetControlActiveFromPredicate(control, AreBuffsEnabled)
end

local function AreDebuffsEnabled()
    return IsBuffDebuffEnabled() and tonumber(GetSetting(SETTING_TYPE_BUFFS, BUFFS_SETTING_DEBUFFS_ENABLED)) ~= 0
end

local function OnDebuffsEnabledChanged(control)
    ZO_SetControlActiveFromPredicate(control, AreDebuffsEnabled)
end

local function AreDebuffsForTargetEnabled()
    return IsBuffDebuffEnabled() and tonumber(GetSetting(SETTING_TYPE_BUFFS, BUFFS_SETTING_DEBUFFS_ENABLED_FOR_TARGET)) ~= 0
end

local function OnDebuffsEnabledForTargetChanged(control)
    ZO_SetControlActiveFromPredicate(control, AreDebuffsForTargetEnabled)
end

local ZO_OptionsPanel_Combat_ControlData =
{
    --UI Settings
    [SETTING_TYPE_UI] =
    {
        --Options_Interface_ShowActionBar
        [UI_SETTING_SHOW_ACTION_BAR] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_UI,
            panel = SETTING_PANEL_COMBAT,
            settingId = UI_SETTING_SHOW_ACTION_BAR,
            text = SI_INTERFACE_OPTIONS_ACTION_BAR,
            tooltipText = SI_INTERFACE_OPTIONS_ACTION_BAR_TOOLTIP,
            valid = {ACTION_BAR_SETTING_CHOICE_OFF, ACTION_BAR_SETTING_CHOICE_AUTOMATIC, ACTION_BAR_SETTING_CHOICE_ON,},
            valueStringPrefix = "SI_ACTIONBARSETTINGCHOICE",
            events = {[ACTION_BAR_SETTING_CHOICE_OFF] = "OnAbilityBarsEnabledChanged", [ACTION_BAR_SETTING_CHOICE_AUTOMATIC] = "OnAbilityBarsEnabledChanged", [ACTION_BAR_SETTING_CHOICE_ON] = "OnAbilityBarsEnabledChanged"},
            gamepadHasEnabledDependencies = true,
        },
        [UI_SETTING_SHOW_ACTION_BAR_TIMERS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            panel = SETTING_PANEL_COMBAT,
            settingId = UI_SETTING_SHOW_ACTION_BAR_TIMERS,
            text = SI_INTERFACE_OPTIONS_ACTION_BAR_TIMERS,
            tooltipText = SI_INTERFACE_OPTIONS_ACTION_BAR_TIMERS_TOOLTIP,
            eventCallbacks =
            {
                ["OnAbilityBarsEnabledChanged"] = OnAbilityBarsEnabledChanged,
            },
            gamepadIsEnabledCallback = AreAbilityBarsEnabled,
            events = {[false] = "OnAbilityBarTimersEnabledChanged", [true] = "OnAbilityBarTimersEnabledChanged"},
            gamepadHasEnabledDependencies = true,
        },
        [UI_SETTING_SHOW_ACTION_BAR_BACK_ROW] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            panel = SETTING_PANEL_COMBAT,
            settingId = UI_SETTING_SHOW_ACTION_BAR_BACK_ROW,
            text = SI_INTERFACE_OPTIONS_ACTION_BAR_BACK_ROW,
            tooltipText = SI_INTERFACE_OPTIONS_ACTION_BAR_BACK_ROW_TOOLTIP,
            eventCallbacks =
            {
                ["OnAbilityBarsEnabledChanged"] = OnAbilityBarBackRowEnabledChanged,
                ["OnAbilityBarTimersEnabledChanged"] = OnAbilityBarBackRowEnabledChanged,
            },
            gamepadIsEnabledCallback = IsAbilityBarBackRowEnabled,
        },
        --Options_Interface_ShowResourceBars
        [UI_SETTING_SHOW_RESOURCE_BARS] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_UI,
            panel = SETTING_PANEL_COMBAT,
            settingId = UI_SETTING_SHOW_RESOURCE_BARS,
            text = SI_INTERFACE_OPTIONS_RESOURCE_BARS,
            tooltipText = SI_INTERFACE_OPTIONS_RESOURCE_BARS_TOOLTIP,
            valid = {RESOURCE_BARS_SETTING_CHOICE_DONT_SHOW, RESOURCE_BARS_SETTING_CHOICE_AUTOMATIC, RESOURCE_BARS_SETTING_CHOICE_ALWAYS_SHOW,},
            valueStringPrefix = "SI_RESOURCEBARSSETTINGCHOICE",
        },
        --Options_Interface_ResourceNumbers
        [UI_SETTING_RESOURCE_NUMBERS] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_UI,
            panel = SETTING_PANEL_COMBAT,
            settingId = UI_SETTING_RESOURCE_NUMBERS,
            text = SI_INTERFACE_OPTIONS_RESOURCE_NUMBERS,
            tooltipText = SI_INTERFACE_OPTIONS_RESOURCE_NUMBERS_TOOLTIP,
            valid = {RESOURCE_NUMBERS_SETTING_OFF, RESOURCE_NUMBERS_SETTING_NUMBER_ONLY, RESOURCE_NUMBERS_SETTING_PERCENT_ONLY, RESOURCE_NUMBERS_SETTING_NUMBER_AND_PERCENT},
            valueStringPrefix = "SI_RESOURCENUMBERSSETTING",
        },
        --Options_Interface_UltimateNumber
        [UI_SETTING_ULTIMATE_NUMBER] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            panel = SETTING_PANEL_COMBAT,
            settingId = UI_SETTING_ULTIMATE_NUMBER,
            text = SI_INTERFACE_OPTIONS_ULTIMATE_NUMBER,
            tooltipText = SI_INTERFACE_OPTIONS_ULTIMATE_NUMBER_TOOLTIP,
        },
    },

    [SETTING_TYPE_ACTIVE_COMBAT_TIP] =
    {
        --Options_Interface_ActiveCombatTips
        [0] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_ACTIVE_COMBAT_TIP,
            panel = SETTING_PANEL_COMBAT,
            settingId = 0, -- TODO: make an enum for this, or merge it with another setting type
            text = SI_INTERFACE_OPTIONS_ACT_SETTING_LABEL,
            tooltipText = SI_INTERFACE_OPTIONS_ACT_SETTING_LABEL_TOOLTIP,
            valid = {ACT_SETTING_OFF, ACT_SETTING_AUTO, ACT_SETTING_ALWAYS,},
            valueStringPrefix = "SI_ACTIVECOMBATTIPSETTING",
        },
    },

    --Combat
    [SETTING_TYPE_COMBAT] =
    {
        [COMBAT_SETTING_ENCOUNTER_LOG_APPEAR_ANONYMOUS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_ENCOUNTER_LOG_APPEAR_ANONYMOUS,
            panel = SETTING_PANEL_COMBAT,
            text = SI_INTERFACE_OPTIONS_COMBAT_ENCOUNTER_LOG_APPEAR_ANONYMOUS,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_ENCOUNTER_LOG_APPEAR_ANONYMOUS_TOOLTIP,
            exists = ZO_IsPCUI,
        },
        [COMBAT_SETTING_SCROLLING_COMBAT_TEXT_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCROLLING_COMBAT_TEXT_ENABLED,
            panel = SETTING_PANEL_COMBAT,
            text = SI_INTERFACE_OPTIONS_COMBAT_SCT_ENABLED,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_SCT_ENABLED_TOOLTIP,
            events = {[true] = "SCTEnabled_Changed", [false] = "SCTEnabled_Changed",},
            gamepadHasEnabledDependencies = true,
        },
        [COMBAT_SETTING_SCT_OUTGOING_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_OUTGOING_ENABLED,
            panel = SETTING_PANEL_COMBAT,
            text = SI_INTERFACE_OPTIONS_COMBAT_SCT_OUTGOING_ENABLED,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_SCT_OUTGOING_ENABLED_TOOLTIP,
            events = {[true] = "SCTOutgoingEnabled_Changed", [false] = "SCTOutgoingEnabled_Changed",},
            eventCallbacks =
            {
                ["SCTEnabled_Changed"]   = OnSCTEnabledChanged,
            },
            gamepadIsEnabledCallback = IsSCTEnabled,
            gamepadHasEnabledDependencies = true,
        },
        [COMBAT_SETTING_SCT_OUTGOING_DAMAGE_ENABLED] = GenerateSCTOutgoingOption("DAMAGE"),
        [COMBAT_SETTING_SCT_OUTGOING_DOT_ENABLED] = GenerateSCTOutgoingOption("DOT"),
        [COMBAT_SETTING_SCT_OUTGOING_HEALING_ENABLED] = GenerateSCTOutgoingOption("HEALING"),
        [COMBAT_SETTING_SCT_OUTGOING_HOT_ENABLED] = GenerateSCTOutgoingOption("HOT"),
        [COMBAT_SETTING_SCT_OUTGOING_STATUS_EFFECTS_ENABLED] = GenerateSCTOutgoingOption("STATUS_EFFECTS"),
        [COMBAT_SETTING_SCT_OUTGOING_PET_DAMAGE_ENABLED] = GenerateSCTOutgoingOption("PET_DAMAGE"),
        [COMBAT_SETTING_SCT_OUTGOING_PET_DOT_ENABLED] = GenerateSCTOutgoingOption("PET_DOT"),
        [COMBAT_SETTING_SCT_OUTGOING_PET_HEALING_ENABLED] = GenerateSCTOutgoingOption("PET_HEALING"),
        [COMBAT_SETTING_SCT_OUTGOING_PET_HOT_ENABLED] = GenerateSCTOutgoingOption("PET_HOT"),
        [COMBAT_SETTING_SCT_INCOMING_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_INCOMING_ENABLED,
            panel = SETTING_PANEL_COMBAT,
            text = SI_INTERFACE_OPTIONS_COMBAT_SCT_INCOMING_ENABLED,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_SCT_INCOMING_ENABLED_TOOLTIP,
            events = {[true] = "SCTIncomingEnabled_Changed", [false] = "SCTIncomingEnabled_Changed",},
            eventCallbacks =
            {
                ["SCTEnabled_Changed"]   = OnSCTEnabledChanged,
            },
            gamepadIsEnabledCallback = IsSCTEnabled,
            gamepadHasEnabledDependencies = true,
        },
        [COMBAT_SETTING_SCT_INCOMING_DAMAGE_ENABLED] = GenerateSCTIncomingOption("DAMAGE"),
        [COMBAT_SETTING_SCT_INCOMING_DOT_ENABLED] = GenerateSCTIncomingOption("DOT"),
        [COMBAT_SETTING_SCT_INCOMING_HEALING_ENABLED] = GenerateSCTIncomingOption("HEALING"),
        [COMBAT_SETTING_SCT_INCOMING_HOT_ENABLED] = GenerateSCTIncomingOption("HOT"),
        [COMBAT_SETTING_SCT_INCOMING_PET_DAMAGE_ENABLED] = GenerateSCTIncomingOption("PET_DAMAGE"),
        [COMBAT_SETTING_SCT_INCOMING_PET_DOT_ENABLED] = GenerateSCTIncomingOption("PET_DOT"),
        [COMBAT_SETTING_SCT_INCOMING_STATUS_EFFECTS_ENABLED] = GenerateSCTIncomingOption("STATUS_EFFECTS"),
        [COMBAT_SETTING_SCT_SHOW_OVER_HEAL] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_SCT_SHOW_OVER_HEAL,
            panel = SETTING_PANEL_COMBAT,
            text = SI_INTERFACE_OPTIONS_COMBAT_SCT_SHOW_OVER_HEAL,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_SCT_SHOW_OVER_HEAL_TOOLTIP,
            eventCallbacks =
            {
                ["SCTEnabled_Changed"]   = OnSCTEnabledChanged,
            },
            gamepadIsEnabledCallback = IsSCTEnabled,
        }
    },

    --Buffs & Debuffs
    [SETTING_TYPE_BUFFS] =
    {
        --Options_Combat_Buffs_AllEnabled
        [BUFFS_SETTING_ALL_ENABLED] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_BUFFS,
            panel = SETTING_PANEL_COMBAT,
            settingId = BUFFS_SETTING_ALL_ENABLED,
            text = SI_BUFFS_OPTIONS_ALL_ENABLED,
            tooltipText = SI_BUFFS_OPTIONS_ALL_ENABLED_TOOLTIP,
            valid = {BUFF_DEBUFF_ENABLED_CHOICE_DONT_SHOW, BUFF_DEBUFF_ENABLED_CHOICE_AUTOMATIC, BUFF_DEBUFF_ENABLED_CHOICE_ALWAYS_SHOW,},
            valueStringPrefix = "SI_BUFFDEBUFFENABLEDCHOICE",
            events = {[BUFF_DEBUFF_ENABLED_CHOICE_DONT_SHOW] = "AllBuffsDebuffsEnabled_Changed", [BUFF_DEBUFF_ENABLED_CHOICE_AUTOMATIC] = "AllBuffsDebuffsEnabled_Changed", [BUFF_DEBUFF_ENABLED_CHOICE_ALWAYS_SHOW] = "AllBuffsDebuffsEnabled_Changed"},
            gamepadHasEnabledDependencies = true,
        },
        --Options_Combat_Buffs_AllBuffs
        [BUFFS_SETTING_BUFFS_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_BUFFS,
            panel = SETTING_PANEL_COMBAT,
            settingId = BUFFS_SETTING_BUFFS_ENABLED,
            text = SI_BUFFS_OPTIONS_BUFFS_ENABLED,
            tooltipText = SI_BUFFS_OPTIONS_BUFFS_ENABLED_TOOLTIP,
            events = {[false] = "BuffsEnabled_Changed", [true] = "BuffsEnabled_Changed",},
            gamepadHasEnabledDependencies = true,

            eventCallbacks =
            {
                ["AllBuffsDebuffsEnabled_Changed"]   = OnBuffDebuffEnabledChanged,
            },
            gamepadIsEnabledCallback = IsBuffDebuffEnabled,
        },
        --Options_Combat_Buffs_SelfBuffs
        [BUFFS_SETTING_BUFFS_ENABLED_FOR_SELF] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_BUFFS,
            panel = SETTING_PANEL_COMBAT,
            settingId = BUFFS_SETTING_BUFFS_ENABLED_FOR_SELF,
            text = SI_BUFFS_OPTIONS_BUFFS_ENABLED_FOR_SELF,
            tooltipText = SI_BUFFS_OPTIONS_BUFFS_ENABLED_FOR_SELF_TOOLTIP,

            eventCallbacks =
            {
                ["AllBuffsDebuffsEnabled_Changed"]   = OnBuffsEnabledChanged,
                ["BuffsEnabled_Changed"]    = OnBuffsEnabledChanged,
            },
            gamepadIsEnabledCallback = AreBuffsEnabled,
        },
        --Options_Combat_Buffs_TargetBuffs
        [BUFFS_SETTING_BUFFS_ENABLED_FOR_TARGET] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_BUFFS,
            panel = SETTING_PANEL_COMBAT,
            settingId = BUFFS_SETTING_BUFFS_ENABLED_FOR_TARGET,
            text = SI_BUFFS_OPTIONS_BUFFS_ENABLED_FOR_TARGET,
            tooltipText = SI_BUFFS_OPTIONS_BUFFS_ENABLED_FOR_TARGET_TOOLTIP,

            eventCallbacks =
            {
                ["AllBuffsDebuffsEnabled_Changed"]   = OnBuffsEnabledChanged,
                ["BuffsEnabled_Changed"]    = OnBuffsEnabledChanged,
            },
            gamepadIsEnabledCallback = AreBuffsEnabled,
        },
        --Options_Combat_Buffs_AllDebuffs
        [BUFFS_SETTING_DEBUFFS_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_BUFFS,
            panel = SETTING_PANEL_COMBAT,
            settingId = BUFFS_SETTING_DEBUFFS_ENABLED,
            text = SI_BUFFS_OPTIONS_DEBUFFS_ENABLED,
            tooltipText = SI_BUFFS_OPTIONS_DEBUFFS_ENABLED_TOOLTIP,
            events = {[false] = "DebuffsEnabled_Changed", [true] = "DebuffsEnabled_Changed",},
            gamepadHasEnabledDependencies = true,

            eventCallbacks =
            {
                ["AllBuffsDebuffsEnabled_Changed"]   = OnBuffDebuffEnabledChanged,
            },
            gamepadIsEnabledCallback = IsBuffDebuffEnabled,
        },
        --Options_Combat_Buffs_SelfDebuffs
        [BUFFS_SETTING_DEBUFFS_ENABLED_FOR_SELF] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_BUFFS,
            panel = SETTING_PANEL_COMBAT,
            settingId = BUFFS_SETTING_DEBUFFS_ENABLED_FOR_SELF,
            text = SI_BUFFS_OPTIONS_DEBUFFS_ENABLED_FOR_SELF,
            tooltipText = SI_BUFFS_OPTIONS_DEBUFFS_ENABLED_FOR_SELF_TOOLTIP,

            eventCallbacks =
            {
                ["AllBuffsDebuffsEnabled_Changed"]   = OnDebuffsEnabledChanged,
                ["DebuffsEnabled_Changed"]    = OnDebuffsEnabledChanged,
            },
            gamepadIsEnabledCallback = AreDebuffsEnabled,
        },
        --Options_Combat_Buffs_TargetDebuffs
        [BUFFS_SETTING_DEBUFFS_ENABLED_FOR_TARGET] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_BUFFS,
            panel = SETTING_PANEL_COMBAT,
            settingId = BUFFS_SETTING_DEBUFFS_ENABLED_FOR_TARGET,
            text = SI_BUFFS_OPTIONS_DEBUFFS_ENABLED_FOR_TARGET,
            tooltipText = SI_BUFFS_OPTIONS_DEBUFFS_ENABLED_FOR_TARGET_TOOLTIP,
            events = {[false] = "DebuffsEnabledForTarget_Changed", [true] = "DebuffsEnabledForTarget_Changed",},
            gamepadHasEnabledDependencies = true,

            eventCallbacks =
            {
                ["AllBuffsDebuffsEnabled_Changed"]   = OnDebuffsEnabledChanged,
                ["DebuffsEnabled_Changed"]    = OnDebuffsEnabledChanged,
            },
            gamepadIsEnabledCallback = AreDebuffsEnabled,
        },
        --Options_Combat_Buffs_LongEffects
        [BUFFS_SETTING_LONG_EFFECTS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_BUFFS,
            panel = SETTING_PANEL_COMBAT,
            settingId = BUFFS_SETTING_LONG_EFFECTS,
            text = SI_BUFFS_OPTIONS_LONG_EFFECTS,
            tooltipText = SI_BUFFS_OPTIONS_LONG_EFFECTS_TOOLTIP,

            eventCallbacks =
            {
                ["AllBuffsDebuffsEnabled_Changed"]   = OnBuffDebuffEnabledChanged,
            },
            gamepadIsEnabledCallback = IsBuffDebuffEnabled,
        },
        --Options_Combat_Buffs_PermanentEffects
        [BUFFS_SETTING_PERMANENT_EFFECTS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_BUFFS,
            panel = SETTING_PANEL_COMBAT,
            settingId = BUFFS_SETTING_PERMANENT_EFFECTS,
            text = SI_BUFFS_OPTIONS_PERMANENT_EFFECTS,
            tooltipText = SI_BUFFS_OPTIONS_PERMANENT_EFFECTS_TOOLTIP,

            eventCallbacks =
            {
                ["AllBuffsDebuffsEnabled_Changed"]   = OnBuffDebuffEnabledChanged,
            },
            gamepadIsEnabledCallback = IsBuffDebuffEnabled,
        },
        --Option_Combat_Buffs_Debuffs_Enabled_For_Target_From_Others
        [BUFFS_SETTING_DEBUFFS_ENABLED_FOR_TARGET_FROM_OTHERS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_BUFFS,
            panel = SETTING_PANEL_COMBAT,
            settingId = BUFFS_SETTING_DEBUFFS_ENABLED_FOR_TARGET_FROM_OTHERS,
            text = SI_BUFFS_OPTIONS_DEBUFFS_ENABLED_FOR_TARGET_FROM_OTHERS,
            tooltipText = SI_BUFFS_OPTIONS_DEBUFFS_ENABLED_FOR_TARGET_FROM_OTHERS_TOOLTIP,
            
            eventCallbacks =
            {
                ["AllBuffsDebuffsEnabled_Changed"] = OnDebuffsEnabledForTargetChanged,
                ["DebuffsEnabled_Changed"] = OnDebuffsEnabledForTargetChanged,
                ["DebuffsEnabledForTarget_Changed"] = OnDebuffsEnabledForTargetChanged,
            },
            gamepadIsEnabledCallback = AreDebuffsForTargetEnabled,
        }
    },
}

ZO_SharedOptions.AddTableToPanel(SETTING_PANEL_COMBAT, ZO_OptionsPanel_Combat_ControlData)
