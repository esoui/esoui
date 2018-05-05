local function AreMonsterTellsEnabled()
    return tonumber(GetSetting(SETTING_TYPE_COMBAT, COMBAT_SETTING_MONSTER_TELLS_ENABLED)) ~= 0
end

local function OnMonsterTellsEnabledChanged(control)
    ZO_SetControlActiveFromPredicate(control, AreMonsterTellsEnabled)
end

local function IsMonsterTellsColorSwapEnabled()
    return AreMonsterTellsEnabled() and tonumber(GetSetting(SETTING_TYPE_COMBAT, COMBAT_SETTING_MONSTER_TELLS_COLOR_SWAP_ENABLED)) ~= 0
end

local function OnMonsterTellsOrColorSwapEnabledChanged(control)
    ZO_SetControlActiveFromPredicate(control, IsMonsterTellsColorSwapEnabled)
end


local ZO_OptionsPanel_Gameplay_ControlData =
{
    --Combat
    [SETTING_TYPE_COMBAT] =
    {
        --Options_Gameplay_MonsterTells
        [COMBAT_SETTING_MONSTER_TELLS_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_COMBAT,
            panel = SETTING_PANEL_GAMEPLAY,
            settingId = COMBAT_SETTING_MONSTER_TELLS_ENABLED,
            text = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_ENABLE,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_ENABLE_TOOLTIP,
            events = {[true] = "MonsterTellsEnabled_Changed", [false] = "MonsterTellsEnabled_Changed",},
            gamepadHasEnabledDependencies = true,
        },
        --Options_Gameplay_MonsterTellsColorSwapEnabled
        [COMBAT_SETTING_MONSTER_TELLS_COLOR_SWAP_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_COMBAT,
            panel = SETTING_PANEL_GAMEPLAY,
            settingId = COMBAT_SETTING_MONSTER_TELLS_COLOR_SWAP_ENABLED,
            text = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_COLOR_SWAP_ENABLED,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_COLOR_SWAP_ENABLED_TOOLTIP,
            events = {[true] = "MonsterTellsColorSwapEnabled_Changed", [false] = "MonsterTellsColorSwapEnabled_Changed",},
            eventCallbacks =
            {
                ["MonsterTellsEnabled_Changed"] = OnMonsterTellsEnabledChanged,
            },
            gamepadIsEnabledCallback = AreMonsterTellsEnabled,
            gamepadHasEnabledDependencies = true,
        },
        --Options_Gameplay_MonsterTellsFriendlyColor
        [COMBAT_SETTING_MONSTER_TELLS_FRIENDLY_COLOR] =
        {
            controlType = OPTIONS_COLOR,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_MONSTER_TELLS_FRIENDLY_COLOR,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_FRIENDLY_COLOR,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_FRIENDLY_COLOR_TOOLTIP,
            eventCallbacks =
            {
                ["MonsterTellsEnabled_Changed"] = OnMonsterTellsOrColorSwapEnabledChanged,
                ["MonsterTellsColorSwapEnabled_Changed"] = OnMonsterTellsOrColorSwapEnabledChanged,
            },
            gamepadIsEnabledCallback = IsMonsterTellsColorSwapEnabled,
        },
        --Options_Gameplay_MonsterTellsFriendlyBrightness
        [COMBAT_SETTING_MONSTER_TELLS_FRIENDLY_BRIGHTNESS] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_MONSTER_TELLS_FRIENDLY_BRIGHTNESS,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_FRIENDLY_BRIGHTNESS,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_FRIENDLY_BRIGHTNESS_TOOLTIP,
            minValue = 1,
            maxValue = 50,
            showValue = true,
            eventCallbacks =
            {
                ["MonsterTellsEnabled_Changed"] = OnMonsterTellsOrColorSwapEnabledChanged,
                ["MonsterTellsColorSwapEnabled_Changed"] = OnMonsterTellsOrColorSwapEnabledChanged,
            },
            gamepadIsEnabledCallback = IsMonsterTellsColorSwapEnabled,
        },
        --Options_Gameplay_MonsterTellsEnemyColor
        [COMBAT_SETTING_MONSTER_TELLS_ENEMY_COLOR] =
        {
            controlType = OPTIONS_COLOR,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_MONSTER_TELLS_ENEMY_COLOR,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_ENEMY_COLOR,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_ENEMY_COLOR_TOOLTIP,
            eventCallbacks =
            {
                ["MonsterTellsEnabled_Changed"] = OnMonsterTellsOrColorSwapEnabledChanged,
                ["MonsterTellsColorSwapEnabled_Changed"] = OnMonsterTellsOrColorSwapEnabledChanged,
            },
            gamepadIsEnabledCallback = IsMonsterTellsColorSwapEnabled,
        },
        --Options_Gameplay_MonsterTellsEnemyBrightness
        [COMBAT_SETTING_MONSTER_TELLS_ENEMY_BRIGHTNESS] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_MONSTER_TELLS_ENEMY_BRIGHTNESS,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_ENEMY_BRIGHTNESS,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_ENEMY_BRIGHTNESS_TOOLTIP,
            minValue = 1,
            maxValue = 50,
            showValue = true,
            eventCallbacks =
            {
                ["MonsterTellsEnabled_Changed"] = OnMonsterTellsOrColorSwapEnabledChanged,
                ["MonsterTellsColorSwapEnabled_Changed"] = OnMonsterTellsOrColorSwapEnabledChanged,
            },
            gamepadIsEnabledCallback = IsMonsterTellsColorSwapEnabled,
        },
        --Options_Gameplay_DodgeDoubleTap
        [COMBAT_SETTING_ROLL_DODGE_DOUBLE_TAP] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_COMBAT,
            panel = SETTING_PANEL_GAMEPLAY,
            settingId = COMBAT_SETTING_ROLL_DODGE_DOUBLE_TAP,
            text = SI_INTERFACE_OPTIONS_COMBAT_ROLL_DODGE_ENABLED,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_ROLL_DODGE_ENABLED_TOOLTIP,
            events = {[true] = "DoubleTapRollDodgeEnabled_On", [false] = "DoubleTapRollDodgeEnabled_Off",},
        },
        --Options_Gameplay_RollDodgeTime
        [COMBAT_SETTING_ROLL_DODGE_WINDOW] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_ROLL_DODGE_WINDOW,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_INTERFACE_OPTIONS_COMBAT_ROLL_DODGE_WINDOW,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_ROLL_DODGE_WINDOW_TOOLTIP,
            minValue = 75,
            maxValue = 275,
            
            showValue = true,
            valueTextFormatter = SI_INTERFACE_OPTIONS_COMBAT_ROLL_DODGE_WINDOW_MS,
            
            eventCallbacks =
            {
                ["DoubleTapRollDodgeEnabled_On"]    = ZO_Options_SetOptionActive,
                ["DoubleTapRollDodgeEnabled_Off"]   = ZO_Options_SetOptionInactive,
            },
        },
        --Options_Gameplay_ClampGroundTarget
        [COMBAT_SETTING_CLAMP_GROUND_TARGET_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_CLAMP_GROUND_TARGET_ENABLED,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_INTERFACE_OPTIONS_COMBAT_CLAMP_GROUND_TARGET_ENABLED,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_CLAMP_GROUND_TARGET_ENABLED_TOOLTIP,
        },
        --Options_Gameplay_PreventAttackingInnocents
        [COMBAT_SETTING_PREVENT_ATTACKING_INNOCENTS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_COMBAT,
            settingId = COMBAT_SETTING_PREVENT_ATTACKING_INNOCENTS,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_INTERFACE_OPTIONS_COMBAT_PREVENT_ATTACKING_INNOCENTS,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_PREVENT_ATTACKING_INNOCENTS_TOOLTIP,
        },
        --Options_Gameplay_QuickCastGroundAbilities
        [COMBAT_SETTING_QUICK_CAST_GROUND_ABILITIES] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_COMBAT,
            panel = SETTING_PANEL_GAMEPLAY,
            settingId = COMBAT_SETTING_QUICK_CAST_GROUND_ABILITIES,
            text = SI_INTERFACE_OPTIONS_COMBAT_QUICK_CAST_GROUND_ABILITIES,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_QUICK_CAST_GROUND_ABILITIES_TOOLTIP,
            valid = {QUICK_CAST_GROUND_ABILITIES_CHOICE_ON, QUICK_CAST_GROUND_ABILITIES_CHOICE_AUTOMATIC, QUICK_CAST_GROUND_ABILITIES_CHOICE_OFF,},
            valueStringPrefix = "SI_QUICKCASTGROUNDABILITIESCHOICE",
        },
    },

    --Loot
    [SETTING_TYPE_LOOT] =
    {
        --Options_Gameplay_UseAoeLoot
        [LOOT_SETTING_AOE_LOOT] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_LOOT,
            settingId = LOOT_SETTING_AOE_LOOT,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_INTERFACE_OPTIONS_LOOT_USE_AOELOOT,
            tooltipText = SI_INTERFACE_OPTIONS_LOOT_USE_AOELOOT_TOOLTIP,
        },
        --Options_Gameplay_UseAutoLoot
        [LOOT_SETTING_AUTO_LOOT] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_LOOT,
            settingId = LOOT_SETTING_AUTO_LOOT,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_INTERFACE_OPTIONS_LOOT_USE_AUTOLOOT,
            tooltipText = SI_INTERFACE_OPTIONS_LOOT_USE_AUTOLOOT_TOOLTIP,
            events = {[true] = "AutoLoot_On", [false] = "AutoLoot_Off",},
            gamepadHasEnabledDependencies = true,
        },
        --Options_Gameplay_UseAutoLootStolen
        [LOOT_SETTING_AUTO_LOOT_STOLEN] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_LOOT,
            settingId = LOOT_SETTING_AUTO_LOOT_STOLEN,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_INTERFACE_OPTIONS_LOOT_USE_AUTOLOOT_STOLEN,
            tooltipText = SI_INTERFACE_OPTIONS_LOOT_USE_AUTOLOOT_STOLEN_TOOLTIP,
            eventCallbacks =
            {
                ["AutoLoot_On"]    = ZO_Options_SetOptionActive,
                ["AutoLoot_Off"]   = ZO_Options_SetOptionInactive,
            },
            gamepadIsEnabledCallback = function()
                                            return tonumber(GetSetting(SETTING_TYPE_LOOT,LOOT_SETTING_AUTO_LOOT)) ~= 0
                                        end
        },
        --Options_Gameplay_AutoAddToCraftBag
        [LOOT_SETTING_AUTO_ADD_TO_CRAFT_BAG] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_LOOT,
            settingId = LOOT_SETTING_AUTO_ADD_TO_CRAFT_BAG,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_INTERFACE_OPTIONS_LOOT_AUTO_ADD_TO_CRAFT_BAG,
            tooltipText = SI_INTERFACE_OPTIONS_LOOT_AUTO_ADD_TO_CRAFT_BAG_TOOLTIP,
            gamepadIsEnabledCallback = IsESOPlusSubscriber,
            onInitializeFunction = function(control, isKeyboardControl)
                                        if isKeyboardControl then
                                            --ZO_Options_SetOptionActive/Inactive are keyboard only functions. The gamepad manages active state through
                                            --the gamepadIsEnabledCallback. Using ZO_Options_SetOptionActive/Inactive with gamepad controls will set them
                                            --to the keyboard colors and also doesn't handle the parametric list's selected state's impact.
                                            if IsESOPlusSubscriber() then
                                                ZO_Options_SetOptionActive(control)
                                            else 
                                                ZO_Options_SetOptionInactive(control)
                                            end
                                        end
                                    end
        },
        --Options_Gameplay_UseLootHistory
        [LOOT_SETTING_LOOT_HISTORY] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_LOOT,
            settingId = LOOT_SETTING_LOOT_HISTORY,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_INTERFACE_OPTIONS_LOOT_TOGGLE_LOOT_HISTORY,
            tooltipText = SI_INTERFACE_OPTIONS_LOOT_TOGGLE_LOOT_HISTORY_TOOLTIP,
        },
    },

    --In world
    [SETTING_TYPE_IN_WORLD] =
    {
        --Options_Gameplay_HidePolymorphHelm
        [IN_WORLD_UI_SETTING_HIDE_POLYMORPH_HELM] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_IN_WORLD,
            panel = SETTING_PANEL_GAMEPLAY,
            settingId = IN_WORLD_UI_SETTING_HIDE_POLYMORPH_HELM,
            text = SI_INTERFACE_OPTIONS_HIDE_POLYMORPH_HELM,
            tooltipText = SI_INTERFACE_OPTIONS_HIDE_POLYMORPH_HELM_TOOLTIP,
        },

        --Options_Gameplay_HideMountStaminaUpgrade
        [IN_WORLD_UI_SETTING_HIDE_MOUNT_STAMINA_UPGRADE] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_IN_WORLD,
            panel = SETTING_PANEL_GAMEPLAY,
            settingId = IN_WORLD_UI_SETTING_HIDE_MOUNT_STAMINA_UPGRADE,
            text = SI_INTERFACE_OPTIONS_HIDE_MOUNT_STAMINA_UPGRADE,
            tooltipText = SI_INTERFACE_OPTIONS_HIDE_MOUNT_STAMINA_UPGRADE_TOOLTIP,
        },

        --Options_Gameplay_HideMountSpeedUpgrade
        [IN_WORLD_UI_SETTING_HIDE_MOUNT_SPEED_UPGRADE] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_IN_WORLD,
            panel = SETTING_PANEL_GAMEPLAY,
            settingId = IN_WORLD_UI_SETTING_HIDE_MOUNT_SPEED_UPGRADE,
            text = SI_INTERFACE_OPTIONS_HIDE_MOUNT_SPEED_UPGRADE,
            tooltipText = SI_INTERFACE_OPTIONS_HIDE_MOUNT_SPEED_UPGRADE_TOOLTIP,
        },

        --Options_Gameplay_HideMountInventoryUpgrade
        [IN_WORLD_UI_SETTING_HIDE_MOUNT_INVENTORY_UPGRADE] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_IN_WORLD,
            panel = SETTING_PANEL_GAMEPLAY,
            settingId = IN_WORLD_UI_SETTING_HIDE_MOUNT_INVENTORY_UPGRADE,
            text = SI_INTERFACE_OPTIONS_HIDE_MOUNT_INVENTORY_UPGRADE,
            tooltipText = SI_INTERFACE_OPTIONS_HIDE_MOUNT_INVENTORY_UPGRADE_TOOLTIP,
        },		

        --Options_Gameplay_DefaultSoulGem
        [IN_WORLD_UI_SETTING_DEFAULT_SOUL_GEM] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_IN_WORLD,
            panel = SETTING_PANEL_GAMEPLAY,
            settingId = IN_WORLD_UI_SETTING_DEFAULT_SOUL_GEM,
            text = SI_GAMEPLAY_OPTIONS_DEFAULT_SOUL_GEM,
            tooltipText = SI_GAMEPLAY_OPTIONS_DEFAULT_SOUL_GEM_TOOLTIP,
            valid = {DEFAULT_SOUL_GEM_CHOICE_GOLD, DEFAULT_SOUL_GEM_CHOICE_CROWN,},
            gamepadValidStringOverrides = {SI_GAMEPAD_OPTIONS_DEFAULT_SOUL_GEM_CHOICE_GOLD, SI_GAMEPAD_OPTIONS_DEFAULT_SOUL_GEM_CHOICE_CROWNS},
            valueStringPrefix = "SI_DEFAULTSOULGEMCHOICE",
        },

        --Options_Gameplay_FootInverseKinematics
        [IN_WORLD_UI_SETTING_FOOT_INVERSE_KINEMATICS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_FOOT_INVERSE_KINEMATICS,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_INTERFACE_OPTIONS_FOOT_INVERSE_KINEMATICS,
            tooltipText = SI_INTERFACE_OPTIONS_FOOT_INVERSE_KINEMATICS_TOOLTIP,
        },
    },

    --Tutorial
    [SETTING_TYPE_TUTORIAL] =
    {
        --Options_Gameplay_TutorialEnabled
        [TUTORIAL_ENABLED_SETTING_ID] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_TUTORIAL,
            settingId = TUTORIAL_ENABLED_SETTING_ID,
            panel = SETTING_PANEL_GAMEPLAY,
            text = SI_INTERFACE_OPTIONS_TOOLTIPS_TUTORIAL_ENABLED,
            tooltipText = SI_INTERFACE_OPTIONS_TOOLTIPS_TUTORIAL_ENABLED_TOOLTIP,
            events = {[true] = "TutorialsEnabled", [false] = "TutorialsDisabled",},
        },

        [OPTIONS_CUSTOM_SETTING_RESET_TUTORIALS] = -- this setting will only be used in the gamepad options, keyboard has a different implementation
        {
            controlType = OPTIONS_INVOKE_CALLBACK,
            system = SETTING_TYPE_TUTORIAL,
            panel = SETTING_PANEL_GAMEPLAY,
            settingId = OPTIONS_CUSTOM_SETTING_RESET_TUTORIALS,
            text = SI_INTERFACE_OPTIONS_RESET_TUTORIALS,
            callback = function()
                            ZO_Dialogs_ShowGamepadDialog("CONFIRM_RESET_TUTORIALS")
                        end,
        },
    },

    [SETTING_TYPE_CUSTOM] =
    {
        --Options_Gameplay_MonsterTellsFriendlyTest
        [OPTIONS_CUSTOM_SETTING_MONSTER_TELLS_FRIENDLY_TEST] =
        {
            controlType = OPTIONS_INVOKE_CALLBACK,
            system = SETTING_TYPE_CUSTOM,
            panel = SETTING_PANEL_GAMEPLAY,
            settingId = OPTIONS_CUSTOM_SETTING_MONSTER_TELLS_FRIENDLY_TEST,
            text = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_FRIENDLY_TEST,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_FRIENDLY_TEST_TOOLTIP,
            eventCallbacks =
            {
                ["MonsterTellsEnabled_Changed"] = OnMonsterTellsOrColorSwapEnabledChanged,
                ["MonsterTellsColorSwapEnabled_Changed"] = OnMonsterTellsOrColorSwapEnabledChanged,
            },
            gamepadIsEnabledCallback = IsMonsterTellsColorSwapEnabled,
            callback = function()
                            StartWorldEffectOnPlayer(UI_WORLD_EFFECT_FRIENDLY_TELEGRAPH)
                        end,
        },
        --Options_Gameplay_MonsterTellsEnemyTest
        [OPTIONS_CUSTOM_SETTING_MONSTER_TELLS_ENEMY_TEST] =
        {
            controlType = OPTIONS_INVOKE_CALLBACK,
            system = SETTING_TYPE_CUSTOM,
            panel = SETTING_PANEL_GAMEPLAY,
            settingId = OPTIONS_CUSTOM_SETTING_MONSTER_TELLS_ENEMY_TEST,
            text = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_ENEMY_TEST,
            tooltipText = SI_INTERFACE_OPTIONS_COMBAT_MONSTER_TELLS_ENEMY_TEST_TOOLTIP,
            eventCallbacks =
            {
                ["MonsterTellsEnabled_Changed"] = OnMonsterTellsOrColorSwapEnabledChanged,
                ["MonsterTellsColorSwapEnabled_Changed"] = OnMonsterTellsOrColorSwapEnabledChanged,
            },
            gamepadIsEnabledCallback = IsMonsterTellsColorSwapEnabled,
            callback = function()
                            StartWorldEffectOnPlayer(UI_WORLD_EFFECT_ENEMY_TELEGRAPH)
                        end,
        },
    }
}

local ZO_SharedOptions_Gameplay_GamepadSettingsData = 
{
    --Options_Gamepad_Preferred
    [GAMEPAD_SETTING_GAMEPAD_PREFERRED] =
    {
        controlType = OPTIONS_CHECKBOX,
        system = SETTING_TYPE_GAMEPAD,
        settingId = GAMEPAD_SETTING_GAMEPAD_PREFERRED,
        panel = SETTING_PANEL_GAMEPLAY,
        text = SI_GAMEPAD_OPTIONS_GAMEPAD_MODE,
        tooltipText = SI_GAMEPAD_OPTIONS_GAMEPAD_MODE_TOOLTIP,
        excludeFromResetToDefault = true,
    },

    --Options_Gamepad_Template
    [GAMEPAD_SETTING_GAMEPAD_TEMPLATE] =
    {
        controlType = OPTIONS_FINITE_LIST,
        system = SETTING_TYPE_GAMEPAD,
        settingId = GAMEPAD_SETTING_GAMEPAD_TEMPLATE,
        panel = SETTING_PANEL_GAMEPLAY,
        text = SI_GAMEPAD_OPTIONS_TEMPLATES,
        valid = {GAMEPAD_TEMPLATE_DEFAULT, GAMEPAD_TEMPLATE_ALTERNATE_INTERACT, GAMEPAD_TEMPLATE_WEAPON_TRICKS,},
        valueStringPrefix = "SI_GAMEPADTEMPLATE",
        gamepadShowsControllerInfo = true,

        scrollListChangedCallback = ZO_GamepadOptions_RefreshGamepadInfoPanel,
    },
}

ZO_SharedOptions.AddTableToPanel(SETTING_PANEL_GAMEPLAY, ZO_OptionsPanel_Gameplay_ControlData)
ZO_SharedOptions.AddTableToSystem(SETTING_PANEL_GAMEPLAY, SETTING_TYPE_GAMEPAD, ZO_SharedOptions_Gameplay_GamepadSettingsData)