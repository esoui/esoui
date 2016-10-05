function ZO_OptionsPanel_Social_OnColorOptionEnter(colorControl)
    ZO_Options_OnMouseEnter(colorControl:GetParent())

    local textureControl = colorControl:GetNamedChild("Texture") 
    Options_Social_SharedHighlight:ClearAnchors()
    Options_Social_SharedHighlight:SetAnchor(CENTER, textureControl, CENTER)
    Options_Social_SharedHighlight:SetHidden(false)
end

function ZO_OptionsPanel_Social_OnColorOptionExit(colorControl)
    ZO_Options_OnMouseExit(colorControl:GetParent())
    Options_Social_SharedHighlight:SetHidden(true)
end

local function SetupColor(control)
    control.data.currentRed, control.data.currentGreen, control.data.currentBlue = GetChatCategoryColor(control.data.chatChannelCategory)
    control.data.texture:SetColor(control.data.currentRed, control.data.currentGreen, control.data.currentBlue, 1)
end

do
    local categoryChildren = {
        [CHAT_CATEGORY_MONSTER_SAY] = {CHAT_CATEGORY_MONSTER_YELL, CHAT_CATEGORY_MONSTER_WHISPER, CHAT_CATEGORY_MONSTER_EMOTE}
    }

    local function OpenColorPicker(colorControl, button, upInside)
        if upInside then
            local optionControl = colorControl:GetParent()
            local data = optionControl.data
            local texture = colorControl:GetNamedChild("Texture") 

            local function OnColorSet(r, g, b)
                texture:SetColor(r, g, b, 1)
                data.currentRed, data.currentGreen, data.currentBlue = r, g, b
                CHAT_SYSTEM:SetChannelCategoryColor(data.chatChannelCategory, r, g, b)
                SetChatCategoryColor(data.chatChannelCategory, r, g, b)

                local children = categoryChildren[data.chatChannelCategory]
                if children then
                    for i = 1, #children do
                        CHAT_SYSTEM:SetChannelCategoryColor(children[i], r, g, b)
                        SetChatCategoryColor(children[i], r, g, b)
                    end
                end
            end
            COLOR_PICKER:Show(OnColorSet, data.currentRed, data.currentGreen, data.currentBlue)
        end
    end

    local categoryToChannelMappings = {
        [CHAT_CATEGORY_SAY] = CHAT_CHANNEL_SAY,
        [CHAT_CATEGORY_YELL] = CHAT_CHANNEL_YELL,
        [CHAT_CATEGORY_ZONE] = CHAT_CHANNEL_ZONE,
        [CHAT_CATEGORY_ZONE_ENGLISH] = CHAT_CHANNEL_ZONE_LANGUAGE_1,
        [CHAT_CATEGORY_ZONE_FRENCH] = CHAT_CHANNEL_ZONE_LANGUAGE_2,
        [CHAT_CATEGORY_ZONE_GERMAN] = CHAT_CHANNEL_ZONE_LANGUAGE_3,
        [CHAT_CATEGORY_ZONE_JAPANESE] = CHAT_CHANNEL_ZONE_LANGUAGE_4,
        [CHAT_CATEGORY_WHISPER_INCOMING] = CHAT_CHANNEL_WHISPER,
        [CHAT_CATEGORY_WHISPER_OUTGOING] = CHAT_CHANNEL_WHISPER,
        [CHAT_CATEGORY_PARTY] = CHAT_CHANNEL_PARTY,
        [CHAT_CATEGORY_SYSTEM] = CHAT_CHANNEL_SYSTEM,
        [CHAT_CATEGORY_GUILD_1] = CHAT_CHANNEL_GUILD_1,
        [CHAT_CATEGORY_GUILD_2] = CHAT_CHANNEL_GUILD_2,
        [CHAT_CATEGORY_GUILD_3] = CHAT_CHANNEL_GUILD_3,
        [CHAT_CATEGORY_GUILD_4] = CHAT_CHANNEL_GUILD_4,
        [CHAT_CATEGORY_GUILD_5] = CHAT_CHANNEL_GUILD_5,
        [CHAT_CATEGORY_OFFICER_1] = CHAT_CHANNEL_OFFICER_1,
        [CHAT_CATEGORY_OFFICER_2] = CHAT_CHANNEL_OFFICER_2,
        [CHAT_CATEGORY_OFFICER_3] = CHAT_CHANNEL_OFFICER_3,
        [CHAT_CATEGORY_OFFICER_4] = CHAT_CHANNEL_OFFICER_4,
        [CHAT_CATEGORY_OFFICER_5] = CHAT_CHANNEL_OFFICER_5,
    }

    function ZO_OptionsPanel_Social_InitializeColorControl(control)
        local data = control.data
        local name

        if data.overrideName then
            name = GetString(data.overrideName)
        else
            local switch = CHAT_SYSTEM.switchLookup[categoryToChannelMappings[data.chatChannelCategory]]
            if switch then
                name = switch
            else
                name = GetString("SI_CHATCHANNELCATEGORIES", data.chatChannelCategory)
            end

            if data.nameFormatter then
                name = zo_strformat(data.nameFormatter, name)
            end
        end

        control:GetNamedChild("Label"):SetText(name)

        local color = control:GetNamedChild("Color")
        color:SetHandler("OnMouseUp", OpenColorPicker)
        data.texture = color:GetNamedChild("Texture")

        data.customResetToDefaultsFunction = ZO_OptionsPanel_Social_ResetColorToDefault

        control:SetHandler("OnShow", SetupColor)
    end
end

function ZO_OptionsPanel_Social_ResetColorToDefault(control)
    CHAT_SYSTEM:ResetChannelCategoryToDefault(control.data.chatChannelCategory)
    SetupColor(control)
end

function ZO_OptionsPanel_Social_InitializeGuildLabel(control)
    local data = control.data
    local guildID = GetGuildId(data.guildIndex)
    local guildName = GetGuildName(guildID)
    local alliance = GetGuildAlliance(guildID)

    if(guildName ~= "") then
        local r,g,b = GetAllianceColor(alliance):UnpackRGB()
        control:SetText(guildName)
        control:SetColor(r, g, b, 1)
    else
        control:SetText(zo_strformat(SI_EMPTY_GUILD_CHANNEL_NAME, data.guildIndex))
    end
end

function ZO_OptionsPanel_Social_TextSizeOnShow(control)
    local currentChoice = GetChatFontSize()
    GetControl(control, "Slider"):SetValue(currentChoice)
    local valueLabel = GetControl(control, "ValueLabel")
    if valueLabel then
        valueLabel:SetText(currentChoice)
    end
end

function ZO_OptionsPanel_Social_ResetTextSizeToDefault(control)
    CHAT_SYSTEM:ResetFontSizeToDefault()
    -- Gamepad does not pass in a control when resetting
    -- So skip attempting to update the control itself
    if not IsInGamepadPreferredMode() then
        ZO_OptionsPanel_Social_TextSizeOnShow(control)
    end
end

do
    local function OnSliderChanged(sliderControl, value, eventReason)
        local valueLabel = GetControl(sliderControl:GetParent(), "ValueLabel")
        if valueLabel then
            valueLabel:SetText(value)
        end
        CHAT_SYSTEM:SetFontSize(value)
        SetChatFontSize(value)
    end

    function ZO_OptionsPanel_Social_InitializeTextSizeControl(control, selected)
        local data = control.data
        GetControl(control, "Name"):SetText(GetString(data.text))
        local slider = GetControl(control, "Slider")
        --Need to override the existing value changed handler first so it doesn't run when we do the SetMinMax
        slider:SetHandler("OnValueChanged", nil)
        slider:SetMinMax(data.minValue, data.maxValue)
        slider:SetValueStep(1)
        slider:SetValue(GetChatFontSize())
        slider:SetHandler("OnValueChanged", OnSliderChanged)
        ZO_Options_SetupSlider(control, selected)
    end
end


function ZO_OptionsPanel_Social_MinAlphaOnShow(control)
    local currentChoice = zo_round(CHAT_SYSTEM:GetMinAlpha() * 100)
    GetControl(control, "Slider"):SetValue(currentChoice)
    local valueLabel = GetControl(control, "ValueLabel")
    if valueLabel then
        valueLabel:SetText(currentChoice)
    end
end

function ZO_OptionsPanel_Social_ResetMinAlphaToDefault(control)
    CHAT_SYSTEM:ResetMinAlphaToDefault()
    -- Gamepad does not pass in a control when resetting
    -- So skip attempting to update the control itself
    if not IsInGamepadPreferredMode() then
        ZO_OptionsPanel_Social_MinAlphaOnShow(control)
    end
end

do
    local function OnSliderChanged(sliderControl, value, eventReason)
        local valueLabel = GetControl(sliderControl:GetParent(), "ValueLabel")
        if valueLabel then
            valueLabel:SetText(value)
        end
        CHAT_SYSTEM:SetMinAlpha(value / 100)
    end

    function ZO_OptionsPanel_Social_InitializeMinAlphaControl(control, selected)
        local data = control.data
        GetControl(control, "Name"):SetText(GetString(data.text))
        local slider = GetControl(control, "Slider")
        slider:SetMinMax(data.minValue, data.maxValue)
        slider:SetValueStep(1)
        slider:SetHandler("OnValueChanged", OnSliderChanged)
        ZO_Options_SetupSlider(control, selected)
    end
end

local ZO_OptionsPanel_Social_ControlData =
{
    --Language Settings
    [SETTING_TYPE_LANGUAGE] =
    {
        --Options_Social_UseProfanityFilter
        [LANGUAGE_SETTING_USE_PROFANITY_FILTER] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_LANGUAGE,
            settingId = LANGUAGE_SETTING_USE_PROFANITY_FILTER,
            panel = SETTING_PANEL_SOCIAL,
            text = SI_INTERFACE_OPTIONS_LANGUAGE_USE_PROFANITY_FILTER,
            tooltipText = SI_INTERFACE_OPTIONS_LANGUAGE_USE_PROFANITY_FILTER_TOOLTIP,
            events = {[false] = "ProfanityFilter_Off", [true] = "ProfanityFilter_On",},
        },
    },

    --UI Settings
    [SETTING_TYPE_UI] =
    {
        --Options_Social_ReturnCursorOnChatFocus
        [UI_SETTING_RETURN_CURSOR_ON_CHAT_FOCUS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_RETURN_CURSOR_ON_CHAT_FOCUS,
            panel = SETTING_PANEL_SOCIAL,
            text = SI_INTERFACE_OPTIONS_RETURN_CURSOR_ON_CHAT_FOCUS,
            tooltipText = SI_INTERFACE_OPTIONS_RETURN_CURSOR_ON_CHAT_FOCUS_TOOLTIP,
        },
        --Options_Social_ShowLeaderboardNotifications
        [UI_SETTING_SHOW_LEADERBOARD_NOTIFICATIONS] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_SHOW_LEADERBOARD_NOTIFICATIONS,
            panel = SETTING_PANEL_SOCIAL,
            text = SI_SOCIAL_OPTIONS_SHOW_LEADERBOARD_NOTIFICATIONS,
            tooltipText = SI_SOCIAL_OPTIONS_SHOW_LEADERBOARD_NOTIFICATIONS_TOOLTIP,
            events = {[false] = "LeaderboardNotifications_Off", [true] = "LeaderboardNotifications_On",},
        },
        --Options_Social_AutoDeclineDuelInvites
        [UI_SETTING_AUTO_DECLINE_DUEL_INVITES] =
        {
            controlType = OPTIONS_CHECKBOX,
            system = SETTING_TYPE_UI,
            settingId = UI_SETTING_AUTO_DECLINE_DUEL_INVITES,
            panel = SETTING_PANEL_SOCIAL,
            text = SI_SOCIAL_OPTIONS_AUTO_DECLINE_DUEL_INVITES,
            tooltipText = SI_SOCIAL_OPTIONS_AUTO_DECLINE_DUEL_INVITES_TOOLTIP,
        },
    },

    --Custom
    [SETTING_TYPE_CUSTOM] =
    {
        --Options_Social_TextSize
        [OPTIONS_CUSTOM_SETTING_SOCIAL_TEXT_SIZE] = 
        {
            controlType = OPTIONS_CUSTOM,
            customControlType = OPTIONS_SLIDER,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeTextSizeControl,
            customResetToDefaultsFunction = ZO_OptionsPanel_Social_ResetTextSizeToDefault,
            onShow = ZO_OptionsPanel_Social_TextSizeOnShow,
            panel = SETTING_PANEL_SOCIAL,
            text = SI_SOCIAL_OPTIONS_TEXT_SIZE,
            tooltipText = SI_SOCIAL_OPTIONS_TEXT_SIZE_TOOLTIP,
            minValue = 8,
            maxValue = 24,
        },
        --Options_Social_MinAlpha
        [OPTIONS_CUSTOM_SETTING_SOCIAL_MIN_ALPHA] = 
        {
            controlType = OPTIONS_CUSTOM,
            customControlType = OPTIONS_SLIDER,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeMinAlphaControl,
            customResetToDefaultsFunction = ZO_OptionsPanel_Social_ResetMinAlphaToDefault,
            onShow = ZO_OptionsPanel_Social_MinAlphaOnShow,
            panel = SETTING_PANEL_SOCIAL,
            text = SI_SOCIAL_OPTIONS_MIN_ALPHA,
            tooltipText = SI_SOCIAL_OPTIONS_MIN_ALPHA_TOOLTIP,
            minValue = 0,
            maxValue = 100,
        },
        --Options_Social_ChatColor_Say
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_SAY] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_SAY,
            tooltipText = SI_SOCIAL_OPTIONS_SAY_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_Yell
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_YELL] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_YELL,
            tooltipText = SI_SOCIAL_OPTIONS_YELL_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_WhisperIncoming
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_WHISPER_INC] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_WHISPER_INCOMING,
            nameFormatter = SI_SOCIAL_OPTIONS_TELL_INCOMING_FORMATTER,
            tooltipText = SI_SOCIAL_OPTIONS_WHISPER_INCOMING_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_WhisperOutoing
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_WHISPER_OUT] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_WHISPER_OUTGOING,
            nameFormatter = SI_SOCIAL_OPTIONS_TELL_OUTGOING_FORMATTER,
            tooltipText = SI_SOCIAL_OPTIONS_WHISPER_OUTGOING_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_Group
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GROUP] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_PARTY,
            tooltipText = SI_SOCIAL_OPTIONS_GROUP_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_Zone
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_ZONE] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_ZONE,
            tooltipText = SI_SOCIAL_OPTIONS_ZONE_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_Zone_English
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_ZONE_ENG] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_ZONE_ENGLISH,
            tooltipText = SI_SOCIAL_OPTIONS_ZONE_ENGLISH_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_Zone_French
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_ZONE_FRA] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_ZONE_FRENCH,
            tooltipText = SI_SOCIAL_OPTIONS_ZONE_FRENCH_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_Zone_German
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_ZONE_GER] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_ZONE_GERMAN,
            tooltipText = SI_SOCIAL_OPTIONS_ZONE_GERMAN_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_Zone_Japan
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_ZONE_JPN] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_ZONE_JAPANESE,
            tooltipText = SI_SOCIAL_OPTIONS_ZONE_JAPANESE_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_NPC
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_NPC] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_MONSTER_SAY,
            overrideName = SI_CHAT_CHANNEL_NAME_NPC,
            tooltipText = SI_SOCIAL_OPTIONS_NPC_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_Emote
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_EMOTE] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_EMOTE,
            tooltipText = SI_SOCIAL_OPTIONS_EMOTE_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_System
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_SYSTEM] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_SYSTEM,
            tooltipText = SI_SOCIAL_OPTIONS_SYSTEM_COLOR_TOOLTIP,
        },
        --Options_Social_Guild1Title
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_TITLE_GUILD1] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeGuildLabel,
            panel = SETTING_PANEL_SOCIAL,
            guildIndex = 1,
        },
        --Options_Social_ChatColor_Guild1
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD1] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_GUILD_1,
            tooltipText = SI_SOCIAL_OPTIONS_GUILD1_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_Officer1
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER1] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_OFFICER_1,
            tooltipText = SI_SOCIAL_OPTIONS_OFFICER1_COLOR_TOOLTIP,
        },
        --Options_Social_Guild2Title
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_TITLE_GUILD2] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeGuildLabel,
            panel = SETTING_PANEL_SOCIAL,
            guildIndex = 2,
        },
        --Options_Social_ChatColor_Guild2
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD2] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_GUILD_2,
            tooltipText = SI_SOCIAL_OPTIONS_GUILD2_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_Officer2
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER2] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_OFFICER_2,
            tooltipText = SI_SOCIAL_OPTIONS_OFFICER2_COLOR_TOOLTIP,
        },
        --Options_Social_Guild3Title
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_TITLE_GUILD3] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeGuildLabel,
            panel = SETTING_PANEL_SOCIAL,
            guildIndex = 3,
        },
        --Options_Social_ChatColor_Guild3
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD3] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_GUILD_3,
            tooltipText = SI_SOCIAL_OPTIONS_GUILD3_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_Officer3
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER3] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_OFFICER_3,
            tooltipText = SI_SOCIAL_OPTIONS_OFFICER3_COLOR_TOOLTIP,
        },
        --Options_Social_Guild4Title
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_TITLE_GUILD4] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeGuildLabel,
            panel = SETTING_PANEL_SOCIAL,
            guildIndex = 4,
        },
        --Options_Social_ChatColor_Guild4
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD4] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_GUILD_4,
            tooltipText = SI_SOCIAL_OPTIONS_GUILD4_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_Officer4
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER4] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_OFFICER_4,
            tooltipText = SI_SOCIAL_OPTIONS_OFFICER4_COLOR_TOOLTIP,
        },
        --Options_Social_Guild5Title
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_TITLE_GUILD5] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeGuildLabel,
            panel = SETTING_PANEL_SOCIAL,
            guildIndex = 5,
        },
        --Options_Social_ChatColor_Guild5
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_GUILD5] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_GUILD_5,
            tooltipText = SI_SOCIAL_OPTIONS_GUILD5_COLOR_TOOLTIP,
        },
        --Options_Social_ChatColor_Officer5
        [OPTIONS_CUSTOM_SETTING_SOCIAL_CHAT_COLOR_OFFICER5] = 
        {
            controlType = OPTIONS_CUSTOM,
            customSetupFunction = ZO_OptionsPanel_Social_InitializeColorControl,
            panel = SETTING_PANEL_SOCIAL,
            chatChannelCategory = CHAT_CATEGORY_OFFICER_5,
            tooltipText = SI_SOCIAL_OPTIONS_OFFICER5_COLOR_TOOLTIP,
        },
    },
}

SYSTEMS:GetObject("options"):AddTableToPanel(SETTING_PANEL_SOCIAL, ZO_OptionsPanel_Social_ControlData)