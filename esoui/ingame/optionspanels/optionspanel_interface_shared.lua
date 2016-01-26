function ZO_OptionsPanel_Interface_ChatBubbleSpeedSliderValueFunc(value)
    if value <= .5 then
        return GetString(SI_INTERFACE_OPTIONS_FADE_RATE_VERY_SLOW)
    elseif value <= .75 then
        return GetString(SI_INTERFACE_OPTIONS_FADE_RATE_SLOW)
    elseif value <= 1.5 then
        return GetString(SI_INTERFACE_OPTIONS_FADE_RATE_AVERAGE)
    elseif value <= 2.5 then
        return GetString(SI_INTERFACE_OPTIONS_FADE_RATE_FAST)
    else
        return GetString(SI_INTERFACE_OPTIONS_FADE_RATE_VERY_FAST)
    end
end

SetChatBubbleCategoryEnabled = SetChatBubbleCategoryEnabled or function() end
IsChatBubbleCategoryEnabled = IsChatBubbleCategoryEnabled or function() return false end

local function SetChannelSetting(control, setting)
    for i, channelCategory in ipairs(control.data.channelCategories) do
        SetChatBubbleCategoryEnabled(channelCategory, setting)
    end
end

local function GetChannelSetting(control)
    return IsChatBubbleCategoryEnabled(control.data.channelCategories[1])
end

function ZO_OptionsPanel_Interface_ChatBubbleChannel_OnInitialized(self)
    self.data.panel = SETTING_PANEL_INTERFACE

    self.data.SetSettingOverride = SetChannelSetting
    self.data.GetSettingOverride = GetChannelSetting

    self.data.eventCallbacks =
    {
        ["ChatBubbles_Off"]   = ZO_Options_SetOptionInactive,
        ["ChatBubbles_On"]    = ZO_Options_SetOptionActive,
    }

    self:GetNamedChild("Checkbox"):SetAnchor(RIGHT, nil, RIGHT, -20, 0)
    ZO_OptionsWindow_InitializeControl(self)
end

local function AreHealthbarsEnabled()
    return tonumber(GetSetting(SETTING_TYPE_NAMEPLATES, NAMEPLATE_TYPE_ALL_HEALTHBARS)) ~= 0
end

local ZO_OptionsPanel_Interface_ControlData =
{
    --UI Settings
    [SETTING_TYPE_UI] =
    {
        --Options_Interface_ShowActionBar
        [UI_SETTING_SHOW_ACTION_BAR] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_UI,
            panel = SETTING_PANEL_INTERFACE,
            settingId = UI_SETTING_SHOW_ACTION_BAR,
            text = SI_INTERFACE_OPTIONS_ACTION_BAR,
            tooltipText = SI_INTERFACE_OPTIONS_ACTION_BAR_TOOLTIP,
            valid = {ACTION_BAR_SETTING_CHOICE_OFF, ACTION_BAR_SETTING_CHOICE_AUTOMATIC, ACTION_BAR_SETTING_CHOICE_ON,},
            valueStringPrefix = "SI_ACTIONBARSETTINGCHOICE",
        },
        --Options_Interface_ShowRaidLives
        [UI_SETTING_SHOW_RAID_LIVES] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_UI,
            panel = SETTING_PANEL_INTERFACE,
            settingId = UI_SETTING_SHOW_RAID_LIVES,
            text = SI_INTERFACE_OPTIONS_SHOW_RAID_LIVES,
            tooltipText = SI_INTERFACE_OPTIONS_SHOW_RAID_LIVES_TOOLTIP,
            valid = {RAID_LIFE_VISIBILITY_CHOICE_OFF, RAID_LIFE_VISIBILITY_CHOICE_AUTOMATIC, RAID_LIFE_VISIBILITY_CHOICE_ON,},
            valueStringPrefix = "SI_RAIDLIFEVISIBILITYCHOICE",
        },
        --UI_Settings_ShowQuestTracker
        [UI_SETTING_SHOW_QUEST_TRACKER] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_QUEST_TRACKER,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_SHOW_QUEST_TRACKER,
            tooltipText = SI_INTERFACE_OPTIONS_SHOW_QUEST_TRACKER_TOOLTIP,
        },
        --Options_Interface_QuestBestowers
        [UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_SHOW_QUEST_BESTOWERS,
            tooltipText = SI_INTERFACE_OPTIONS_SHOW_QUEST_BESTOWERS_TOOLTIP,
            events = {[true] = "Bestowers_On", [false] = "Bestowers_Off",},
            gamepadHasEnabledDependencies = true,
        },
        --Options_Interface_FramerateCheck
        [UI_SETTING_SHOW_FRAMERATE] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_FRAMERATE,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_SHOW_FRAMERATE,
            tooltipText = SI_INTERFACE_OPTIONS_SHOW_FRAMERATE_TOOLTIP,
        },
         --Options_Interface_LatencyCheck
        [UI_SETTING_SHOW_LATENCY] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_LATENCY,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_SHOW_LATENCY,
            tooltipText = SI_INTERFACE_OPTIONS_SHOW_LATENCY_TOOLTIP,
        },
        --Options_Interface_FramerateLatencyLockCheck
        [UI_SETTING_FRAMERATE_LATENCY_LOCK] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_FRAMERATE_LATENCY_LOCK,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_FRAMERATE_LATENCY_LOCK,
            tooltipText = SI_INTERFACE_OPTIONS_FRAMERATE_LATENCY_LOCK_TOOLTIP,
        },
        --UI_Settings_ShowQuestTracker
        [UI_SETTING_COMPASS_QUEST_GIVERS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_COMPASS_QUEST_GIVERS,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_COMPASS_QUEST_GIVERS,
            tooltipText = SI_INTERFACE_OPTIONS_COMPASS_QUEST_GIVERS_TOOLTIP,
            eventCallbacks =
            {
                ["Bestowers_Off"]   = ZO_Options_SetOptionInactive,
                ["Bestowers_On"]    = ZO_Options_SetOptionActive,
            },
            gamepadIsEnabledCallback = function() 
                                            return tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS)) ~= 0
                                        end
        },
        --UI_Settings_ShowQuestTracker
        [UI_SETTING_COMPASS_ACTIVE_QUESTS] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_UI,
            panel = SETTING_PANEL_INTERFACE,
            settingId = UI_SETTING_COMPASS_ACTIVE_QUESTS,
            text = SI_INTERFACE_OPTIONS_COMPASS_ACTIVE_QUESTS,
            tooltipText = SI_INTERFACE_OPTIONS_COMPASS_ACTIVE_QUESTS_TOOLTIP,
            valid = {COMPASS_ACTIVE_QUESTS_CHOICE_OFF, COMPASS_ACTIVE_QUESTS_CHOICE_ON, COMPASS_ACTIVE_QUESTS_CHOICE_FOCUSED,},
            valueStringPrefix = "SI_COMPASSACTIVEQUESTSCHOICE",
            events =
            {
                [COMPASS_ACTIVE_QUESTS_CHOICE_OFF] = "CompassActiveQuests_Off",
                [COMPASS_ACTIVE_QUESTS_CHOICE_FOCUSED] = "CompassActiveQuests_Focused",
                [COMPASS_ACTIVE_QUESTS_CHOICE_ON] = "CompassActiveQuests_On"
            },
            eventCallbacks =
            {
                ["CompassActiveQuests_Off"]   = function(control) ZO_Options_SetWarningText(control, SI_INTERFACE_OPTIONS_COMPASS_ACTIVE_QUESTS_OFF_RESTRICTION) end,
                ["CompassActiveQuests_Focused"]    = function(control) ZO_Options_SetWarningText(control, SI_INTERFACE_OPTIONS_COMPASS_ACTIVE_QUESTS_FOCUSED_RESTRICTION) end,
                ["CompassActiveQuests_On"]    = ZO_Options_HideAssociatedWarning,
            },
        },
    },
    [SETTING_TYPE_ACTIVE_COMBAT_TIP] =
    {
        --Options_Interface_ActiveCombatTips
        [0] =   --[[only one id right now]]
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_ACTIVE_COMBAT_TIP,
            panel = SETTING_PANEL_INTERFACE,
            settingId = 0, --[[only one id right now]]
            text = SI_INTERFACE_OPTIONS_ACT_SETTING_LABEL,
            tooltipText = SI_INTERFACE_OPTIONS_ACT_SETTING_LABEL_TOOLTIP,
            valid = {ACT_SETTING_OFF, ACT_SETTING_AUTO, ACT_SETTING_ALWAYS,},
            valueStringPrefix = "SI_ACTIVECOMBATTIPSETTING",
        },
    },

    --Nameplates
    [SETTING_TYPE_NAMEPLATES] =
    {
        --Options_Interface_AllHB
        [NAMEPLATE_TYPE_ALL_HEALTHBARS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ALL_HEALTHBARS,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_HEALTHBARS_ALL,
            tooltipText = SI_INTERFACE_OPTIONS_HEALTHBARS_ALL_TOOLTIP,
            events = {[false] = "AllHealthBars_Off", [true] = "AllHealthBars_On", },
            gamepadHasEnabledDependencies = true,
        },
        --Options_Interface_PlayerHB
        [NAMEPLATE_TYPE_PLAYER_HEALTHBAR] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_PLAYER_HEALTHBAR,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_HEALTHBARS_PLAYER,
            tooltipText = SI_INTERFACE_OPTIONS_HEALTHBARS_PLAYER_TOOLTIP,
            valid = {NAMEPLATE_CHOICE_OFF, NAMEPLATE_CHOICE_ON, NAMEPLATE_CHOICE_HURT,},
            valueStringPrefix = "SI_NAMEPLATEDISPLAYCHOICE",
            eventCallbacks =
            {
                ["AllHealthBars_Off"]   = ZO_Options_SetOptionInactive,
                ["AllHealthBars_On"]    = ZO_Options_SetOptionActive,
            },
            gamepadIsEnabledCallback = AreHealthbarsEnabled,
        },
        --Options_Interface_FriendlyNPCHB
        [NAMEPLATE_TYPE_FRIENDLY_NPC_HEALTHBARS] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FRIENDLY_NPC_HEALTHBARS,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_HEALTHBARS_FRIENDLY_NPC,
            tooltipText = SI_INTERFACE_OPTIONS_HEALTHBARS_FRIENDLY_NPC_TOOLTIP,
            valid = {NAMEPLATE_CHOICE_OFF, NAMEPLATE_CHOICE_ON,},
            valueStringPrefix = "SI_NAMEPLATEDISPLAYCHOICE",
            eventCallbacks =
            {
                ["AllHealthBars_Off"]   = ZO_Options_SetOptionInactive,
                ["AllHealthBars_On"]    = ZO_Options_SetOptionActive,
            },
            gamepadIsEnabledCallback = AreHealthbarsEnabled,
        },
        --Options_Interface_FriendlyPlayerHB
        [NAMEPLATE_TYPE_FRIENDLY_PLAYER_HEALTHBARS] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FRIENDLY_PLAYER_HEALTHBARS,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_HEALTHBARS_FRIENDLY_PLAYER,
            tooltipText = SI_INTERFACE_OPTIONS_HEALTHBARS_FRIENDLY_PLAYER_TOOLTIP,
            valid = {NAMEPLATE_CHOICE_OFF, NAMEPLATE_CHOICE_ON, NAMEPLATE_CHOICE_HURT,},
            valueStringPrefix = "SI_NAMEPLATEDISPLAYCHOICE",
            eventCallbacks =
            {
                ["AllHealthBars_Off"]   = ZO_Options_SetOptionInactive,
                ["AllHealthBars_On"]    = ZO_Options_SetOptionActive,
            },
            gamepadIsEnabledCallback = AreHealthbarsEnabled,
        },
        --Options_Interface_EnemyNPCHB
        [NAMEPLATE_TYPE_ENEMY_NPC_HEALTHBARS] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ENEMY_NPC_HEALTHBARS,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_HEALTHBARS_ENEMY_NPC,
            tooltipText = SI_INTERFACE_OPTIONS_HEALTHBARS_ENEMY_NPC_TOOLTIP,
            valid = {NAMEPLATE_CHOICE_OFF, NAMEPLATE_CHOICE_ON, NAMEPLATE_CHOICE_HURT,},
            valueStringPrefix = "SI_NAMEPLATEDISPLAYCHOICE",
            eventCallbacks =
            {
                ["AllHealthBars_Off"]   = ZO_Options_SetOptionInactive,
                ["AllHealthBars_On"]    = ZO_Options_SetOptionActive,
            },
            gamepadIsEnabledCallback = AreHealthbarsEnabled,
        },
        --Options_Interface_EnemyPlayerHB
        [NAMEPLATE_TYPE_ENEMY_PLAYER_HEALTHBARS] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ENEMY_PLAYER_HEALTHBARS,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_HEALTHBAR_ENEMY_PLAYER,
            tooltipText = SI_INTERFACE_OPTIONS_HEALTHBAR_ENEMY_PLAYER_TOOLTIP,
            valid = {NAMEPLATE_CHOICE_OFF, NAMEPLATE_CHOICE_ON, NAMEPLATE_CHOICE_HURT,},
            valueStringPrefix = "SI_NAMEPLATEDISPLAYCHOICE",
            eventCallbacks =
            {
                ["AllHealthBars_Off"]   = ZO_Options_SetOptionInactive,
                ["AllHealthBars_On"]    = ZO_Options_SetOptionActive,
            },
            gamepadIsEnabledCallback = AreHealthbarsEnabled,
        },
        --Options_Interface_AllianceIndicators
        [NAMEPLATE_TYPE_ALLIANCE_INDICATORS] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_ALLIANCE_INDICATORS,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_NAMEPLATES_ALLIANCE_INDICATORS,
            tooltipText = SI_INTERFACE_OPTIONS_NAMEPLATES_ALLIANCE_INDICATORS_TOOLTIP,
            valid = {NAMEPLATE_CHOICE_OFF, NAMEPLATE_CHOICE_ALLY, NAMEPLATE_CHOICE_ENEMY, NAMEPLATE_CHOICE_ALL},
            valueStringPrefix = "SI_NAMEPLATEDISPLAYCHOICE",
        },
        --Options_Interface_GroupIndicators
        [NAMEPLATE_TYPE_GROUP_INDICATORS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_GROUP_INDICATORS,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_NAMEPLATES_GROUP_INDICATORS,
            tooltipText = SI_INTERFACE_OPTIONS_NAMEPLATES_GROUP_INDICATORS_TOOLTIP,
        },
        --Options_Interface_ResurrectIndicators
        [NAMEPLATE_TYPE_RESURRECT_INDICATORS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_RESURRECT_INDICATORS,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_NAMEPLATES_RESURRECT_INDICATORS,
            tooltipText = SI_INTERFACE_OPTIONS_NAMEPLATES_RESURRECT_INDICATORS_TOOLTIP,
        },
        --Options_Interface_FollowerIndicators
        [NAMEPLATE_TYPE_FOLLOWER_INDICATORS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_NAMEPLATES,
            settingId = NAMEPLATE_TYPE_FOLLOWER_INDICATORS,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_NAMEPLATES_FOLLOWER_INDICATORS,
            tooltipText = SI_INTERFACE_OPTIONS_NAMEPLATES_FOLLOWER_INDICATORS_TOOLTIP,
        },
    },

    --InWorld
    [SETTING_TYPE_IN_WORLD] =
    {
        --Options_Interface_GlowThickness
        [IN_WORLD_UI_SETTING_GLOW_THICKNESS] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_GLOW_THICKNESS,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_GLOWS_THICKNESS,
            tooltipText = SI_INTERFACE_OPTIONS_GLOWS_THICKNESS_TOOLTIP,
        
            valueFormat = "%f",
            showValue = true,
            showValueMin = 0,
            showValueMax = 100,
        },
        --Options_Interface_TargetGlowCheck
        [IN_WORLD_UI_SETTING_TARGET_GLOW_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_IN_WORLD,
            panel = SETTING_PANEL_INTERFACE,
            settingId = IN_WORLD_UI_SETTING_TARGET_GLOW_ENABLED,
            text = SI_INTERFACE_OPTIONS_TARGET_GLOWS_ENABLED,
            tooltipText = SI_INTERFACE_OPTIONS_TARGET_GLOWS_ENABLED_TOOLTIP,
            events = {[true] = "TargetGlowEnabled_On", [false] = "TargetGlowEnabled_Off",},
            gamepadHasEnabledDependencies = true,
        },
        --Options_Interface_TargetGlowIntensity
        [IN_WORLD_UI_SETTING_TARGET_GLOW_INTENSITY] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_TARGET_GLOW_INTENSITY,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_TARGET_GLOWS_INTENSITY,
            tooltipText = SI_INTERFACE_OPTIONS_TARGET_GLOWS_INTENSITY_TOOLTIP,
        
            valueFormat = "%f",
            showValue = true,
            showValueMin = 0,
            showValueMax = 100,
        
            eventCallbacks =
            {
                ["TargetGlowEnabled_On"]    = ZO_Options_SetOptionActive,
                ["TargetGlowEnabled_Off"]   = ZO_Options_SetOptionInactive,
            },
            gamepadIsEnabledCallback = function() 
                                            return tonumber(GetSetting(SETTING_TYPE_IN_WORLD, IN_WORLD_UI_SETTING_TARGET_GLOW_ENABLED)) ~= 0
                                        end,
        },
        --Options_Interface_InteractableGlowCheck
        [IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_IN_WORLD,
            panel = SETTING_PANEL_INTERFACE,
            settingId = IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_ENABLED,
            text = SI_INTERFACE_OPTIONS_INTERACTABLE_GLOWS_ENABLED,
            tooltipText = SI_INTERFACE_OPTIONS_INTERACTABLE_GLOWS_ENABLED_TOOLTIP,
            events = {[true] = "InteractableGlowEnabled_On", [false] = "InteractableGlowEnabled_Off",},
            gamepadHasEnabledDependencies = true,
        },
        --Options_Interface_InteractableGlowIntensity
        [IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_INTENSITY] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_IN_WORLD,
            settingId = IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_INTENSITY,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_INTERACTABLE_GLOWS_INTENSITY,
            tooltipText = SI_INTERFACE_OPTIONS_INTERACTABLE_GLOWS_INTENSITY_TOOLTIP,
        
            valueFormat = "%f",
            showValue = true,
            showValueMin = 0,
            showValueMax = 100,
        
            eventCallbacks =
            {
                ["InteractableGlowEnabled_On"]    = ZO_Options_SetOptionActive,
                ["InteractableGlowEnabled_Off"]   = ZO_Options_SetOptionInactive,
            },
            gamepadIsEnabledCallback = function() 
                                            return tonumber(GetSetting(SETTING_TYPE_IN_WORLD, IN_WORLD_UI_SETTING_INTERACTABLE_GLOW_ENABLED)) ~= 0
                                        end,
        },
    },

    --Chat bubbles
    [SETTING_TYPE_CHAT_BUBBLE] =
    {
        --Options_Interface_ChatBubblesEnabled
        [CHAT_BUBBLE_SETTING_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_CHAT_BUBBLE,
            settingId = CHAT_BUBBLE_SETTING_ENABLED,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_CHAT_BUBBLES,
            gamepadTextOverride = SI_QUICK_CHAT_SETTING_ENABLED,
            tooltipText = SI_INTERFACE_OPTIONS_CHAT_BUBBLES_TOOLTIP,
            events = {[false] = "ChatBubbles_Off", [true] = "ChatBubbles_On",},
            gamepadHasEnabledDependencies = true,
        },
        --Options_Interface_ChatBubblesSpeed
        [CHAT_BUBBLE_SETTING_SPEED_MODIFIER] =
        {
            controlType = OPTIONS_SLIDER,
            system = SETTING_TYPE_CHAT_BUBBLE,
            settingId = CHAT_BUBBLE_SETTING_SPEED_MODIFIER,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_FADE_RATE,
            tooltipText = SI_INTERFACE_OPTIONS_FADE_RATE_TOOLTIP,
            minValue = .25,
            maxValue = 3.0,
            valueFormat = "%.2f",
            showValue = true,
            showValueFunc = ZO_OptionsPanel_Interface_ChatBubbleSpeedSliderValueFunc,

            eventCallbacks =
            {
                ["ChatBubbles_Off"]   = ZO_Options_SetOptionInactive,
                ["ChatBubbles_On"]    = ZO_Options_SetOptionActive,
            },
            gamepadIsEnabledCallback = function() 
                                            return tonumber(GetSetting(SETTING_TYPE_CHAT_BUBBLE, CHAT_BUBBLE_SETTING_ENABLED)) ~= 0
                                        end,
        },
        --Options_Interface_ChatBubblesEnabledRestrictToContacts
        [CHAT_BUBBLE_SETTING_ENABLED_ONLY_FROM_CONTACTS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_CHAT_BUBBLE,
            settingId = CHAT_BUBBLE_SETTING_ENABLED_ONLY_FROM_CONTACTS,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_ONLY_KNOWN,
            tooltipText = SI_INTERFACE_OPTIONS_ONLY_KNOWN_TOOLTIP,

            eventCallbacks =
            {
                ["ChatBubbles_Off"]   = ZO_Options_SetOptionInactive,
                ["ChatBubbles_On"]    = ZO_Options_SetOptionActive,
            },
        },
        --Options_Interface_ChatBubblesEnabledForLocalPlayer
        [CHAT_BUBBLE_SETTING_ENABLED_FOR_LOCAL_PLAYER] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_CHAT_BUBBLE,
            settingId = CHAT_BUBBLE_SETTING_ENABLED_FOR_LOCAL_PLAYER,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_SELF_BUBBLE,
            tooltipText = SI_INTERFACE_OPTIONS_SELF_BUBBLE_TOOLTIP,

            eventCallbacks =
            {
            ["ChatBubbles_Off"]   = ZO_Options_SetOptionInactive,
            ["ChatBubbles_On"]    = ZO_Options_SetOptionActive,
            },
        },
    },
    --Custom
    [SETTING_TYPE_CUSTOM] =
    {
        --Options_Interface_ChatBubblesSayChannel
        [OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_SAY_ENABLED] = 
        {
            controlType = OPTIONS_CHECKBOX,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_CHAT_SAY,
            tooltipText = SI_INTERFACE_OPTIONS_SAY_TOOLTIP,
            
            channelCategories = { CHAT_CATEGORY_SAY },
        },
        --Options_Interface_ChatBubblesYellChannel
        [OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_YELL_ENABLED] = 
        {
            controlType = OPTIONS_CHECKBOX,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_CHAT_YELL,
            tooltipText = SI_INTERFACE_OPTIONS_YELL_TOOLTIP,
            
            channelCategories = { CHAT_CATEGORY_YELL },
        },
        --Options_Interface_ChatBubblesWhisperChannel
        [OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_WHISPER_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_CHAT_TELL,
            tooltipText = SI_INTERFACE_OPTIONS_TELL_TOOLTIP,
            
            channelCategories = { CHAT_CATEGORY_WHISPER_INCOMING, CHAT_CATEGORY_WHISPER_OUTGOING },
        },
        --Options_Interface_ChatBubblesGroupChannel
        [OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_GROUP_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_CHAT_GROUP,
            tooltipText = SI_INTERFACE_OPTIONS_GROUP_TOOLTIP,
            
            channelCategories = { CHAT_CATEGORY_PARTY },
        },
        --Options_Interface_ChatBubblesEmoteChannel
        [OPTIONS_CUSTOM_SETTING_CHAT_BUBBLE_EMOTE_ENABLED] =
        {
            controlType = OPTIONS_CHECKBOX,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_INTERFACE_OPTIONS_CHAT_EMOTE,
            tooltipText = SI_INTERFACE_OPTIONS_EMOTE_TOOLTIP,
            
            channelCategories = { CHAT_CATEGORY_EMOTE },
        },
    },
}

SYSTEMS:GetObject("options"):AddTableToPanel(SETTING_PANEL_INTERFACE, ZO_OptionsPanel_Interface_ControlData)