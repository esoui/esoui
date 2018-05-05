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

local ZO_OptionsPanel_Interface_ControlData =
{
    --UI Settings
    [SETTING_TYPE_UI] =
    {
        [UI_SETTING_PRIMARY_PLAYER_NAME_KEYBOARD] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_UI,
            panel = SETTING_PANEL_INTERFACE,
            settingId = UI_SETTING_PRIMARY_PLAYER_NAME_KEYBOARD,
            text = SI_INTERFACE_OPTIONS_PRIMARY_PLAYER_NAME_KEYBOARD,
            tooltipText = SI_INTERFACE_OPTIONS_PRIMARY_PLAYER_NAME_TOOLTIP_KEYBOARD,
            valid = {PRIMARY_PLAYER_NAME_SETTING_PREFER_USERID, PRIMARY_PLAYER_NAME_SETTING_PREFER_CHARACTER,},
            valueStrings =
            {
                function() return zo_strformat(GetString("SI_PRIMARYPLAYERNAMESETTING", PRIMARY_PLAYER_NAME_SETTING_PREFER_USERID), ZO_GetPlatformAccountLabel()) end,
                function() return GetString("SI_PRIMARYPLAYERNAMESETTING", PRIMARY_PLAYER_NAME_SETTING_PREFER_CHARACTER) end
            }
        },
        [UI_SETTING_PRIMARY_PLAYER_NAME_GAMEPAD] =
        {
            controlType = OPTIONS_FINITE_LIST,
            system = SETTING_TYPE_UI,
            panel = SETTING_PANEL_INTERFACE,
            settingId = UI_SETTING_PRIMARY_PLAYER_NAME_GAMEPAD,
            text = SI_GAMEPAD_INTERFACE_OPTIONS_PRIMARY_PLAYER_NAME,
            tooltipText = SI_GAMEPAD_INTERFACE_OPTIONS_PRIMARY_PLAYER_NAME_TOOLTIP,
            valid = {PRIMARY_PLAYER_NAME_SETTING_PREFER_USERID, PRIMARY_PLAYER_NAME_SETTING_PREFER_CHARACTER,},
            valueStrings =
            {
                function() return zo_strformat(GetString("SI_PRIMARYPLAYERNAMESETTING", PRIMARY_PLAYER_NAME_SETTING_PREFER_USERID), ZO_GetPlatformAccountLabel()) end,
                function() return GetString("SI_PRIMARYPLAYERNAMESETTING", PRIMARY_PLAYER_NAME_SETTING_PREFER_CHARACTER) end
            }
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
        --Options_Interface_QuestBestowerIndicators
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
        --UI_Settings_ShowWeaponIndicator
        [UI_SETTING_SHOW_WEAPON_INDICATOR] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_WEAPON_INDICATOR,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_WEAPON_INDICATOR,
            tooltipText = SI_WEAPON_INDICATOR_SETTINGS_TOOLTIP,
        },
        --UI_Settings_ShowArmorIndicator
        [UI_SETTING_SHOW_ARMOR_INDICATOR] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_ARMOR_INDICATOR,
            panel = SETTING_PANEL_INTERFACE,
            text = SI_ARMOR_INDICATOR,
            tooltipText = SI_ARMOR_INDICATOR_SETTINGS_TOOLTIP,
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
            consoleTextOverride = SI_QUICK_CHAT_SETTING_ENABLED,
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
            text = SI_INTERFACE_OPTIONS_CHAT_BUBBLES_FADE_RATE,
            tooltipText = SI_INTERFACE_OPTIONS_CHAT_BUBBLES_FADE_RATE_TOOLTIP,
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
            text = SI_INTERFACE_OPTIONS_CHAT_BUBBLES_ONLY_KNOWN,
            tooltipText = SI_INTERFACE_OPTIONS_CHAT_BUBBLES_ONLY_KNOWN_TOOLTIP,

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
            text = SI_INTERFACE_OPTIONS_CHAT_BUBBLES_SELF,
            tooltipText = SI_INTERFACE_OPTIONS_CHAT_BUBBLES_SELF_TOOLTIP,

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

ZO_SharedOptions.AddTableToPanel(SETTING_PANEL_INTERFACE, ZO_OptionsPanel_Interface_ControlData)