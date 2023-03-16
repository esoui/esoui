------------------
-- Guild Finder --
------------------

ZO_GUILD_FINDER_ROLE_ORDER =
{
    LFG_ROLE_TANK,
    LFG_ROLE_HEAL,
    LFG_ROLE_DPS,
}

ZO_GUILD_FINDER_APPLICATION_ENTRY_TYPE = 1

local DEFAULT_ICON_SIZE = 24

ZO_GuildFinder_Manager = ZO_CallbackObject:Subclass()

function ZO_GuildFinder_Manager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_GuildFinder_Manager:Initialize()
end

function ZO_GuildFinder_Manager:SetKeyboardApplicationTooltipInfo(control)
    self.applicationKeyboardTooltipInfo = 
    {
        control = control,
        titleControl = control:GetNamedChild("Title"),
        levelControl = control:GetNamedChild("Level"),
        classControl = control:GetNamedChild("Class"),
        allianceControl = control:GetNamedChild("Alliance"),
        achievementPointsControl = control:GetNamedChild("AchievementPoints"),
        messageControl = control:GetNamedChild("Message"),
    }
end

function ZO_GuildFinder_Manager:ShowApplicationTooltipOnMouseEnter(data, control)
    self.applicationKeyboardTooltipInfo.control:ClearAnchors()
    self.applicationKeyboardTooltipInfo.control:SetAnchor(RIGHT, control, LEFT, -10, 0)

    local fullName = ZO_GetPrimaryPlayerNameWithSecondary(data.name, data.characterName)
    self.applicationKeyboardTooltipInfo.titleControl:SetText(fullName)

    local iconSize = data.iconSize or DEFAULT_ICON_SIZE
    local levelText = zo_strformat(SI_GUILD_FINDER_APPLICATIONS_ATTRIBUTE_TOOLTIP_FORMATTER, GetString(SI_GUILD_RECRUITMENT_APPLICATIONS_SORT_HEADER_LEVEL), ZO_GetLevelOrChampionPointsString(data.level, data.championPoints, iconSize))
    self.applicationKeyboardTooltipInfo.levelControl:SetText(levelText)

    local classId = data.class
    local classIcon = zo_iconFormatInheritColor(ZO_GetClassIcon(classId), iconSize, iconSize)
    local classValue = ZO_CachedStrFormat(SI_GUILD_FINDER_APPLICATIONS_ATTRIBUTE_ICON_VALUE_TOOLTIP_FORMATTER, classIcon, GetClassName(GENDER_MALE, classId))
    local classText = zo_strformat(SI_GUILD_FINDER_APPLICATIONS_ATTRIBUTE_TOOLTIP_FORMATTER, GetString(SI_GUILD_RECRUITMENT_CLASS_HEADER), classValue)
    self.applicationKeyboardTooltipInfo.classControl:SetText(classText)

    local allianceId = data.alliance
    local allianceIcon = zo_iconFormatInheritColor(ZO_GetAllianceSymbolIcon(allianceId), iconSize, iconSize)
    local allianceValue = ZO_CachedStrFormat(SI_GUILD_FINDER_APPLICATIONS_ATTRIBUTE_ICON_VALUE_TOOLTIP_FORMATTER, allianceIcon, GetAllianceName(allianceId))
    local allianceText = zo_strformat(SI_GUILD_FINDER_APPLICATIONS_ATTRIBUTE_TOOLTIP_FORMATTER, GetString(SI_GUILD_RECRUITMENT_ALLIANCE_HEADER), allianceValue)
    self.applicationKeyboardTooltipInfo.allianceControl:SetText(allianceText)

    local achievementPointsText = zo_strformat(SI_GUILD_FINDER_APPLICATIONS_ATTRIBUTE_TOOLTIP_FORMATTER, GetString(SI_GUILD_RECRUITMENT_ACHIEVEMENT_POINTS_HEADER), ZO_CommaDelimitNumber(data.achievementPoints))
    self.applicationKeyboardTooltipInfo.achievementPointsControl:SetText(achievementPointsText)

    self.applicationKeyboardTooltipInfo.messageControl:SetText(data.message)

    self.applicationKeyboardTooltipInfo.control:SetHidden(false)
end

function ZO_GuildFinder_Manager:HideApplicationTooltipOnMouseExit()
    self.applicationKeyboardTooltipInfo.control:SetHidden(true)
end

function ZO_GuildFinder_Manager.GetAttributeCommaFormattedList(guildId, iterBegin, iterEnd, checkFunction, stringBase)
    local foundValues = {}
    local hasAttributeSet = false
    for i = iterBegin, iterEnd do
        if checkFunction(guildId, i) then
            table.insert(foundValues, ZO_CachedStrFormat(SI_GUILD_FINDER_ATTRIBUTE_VALUE_FORMATTER, GetString(stringBase, i)))
            hasAttributeSet = true
        end
    end
    
    if not hasAttributeSet then
        table.insert(foundValues, GetString(SI_GUILD_FINDER_GUILD_INFO_DEFAULT_ATTRIBUTE_VALUE))
    end
    
    return ZO_GenerateCommaSeparatedListWithoutAnd(foundValues)
end

function ZO_GuildFinder_Manager.SetTextForMetaDataAttributeKeyboard(labelControl, metaDataAttribute, attributeStringPrefix, data)
    local labelString = GetString("SI_GUILDMETADATAATTRIBUTE", metaDataAttribute)
    local valueString = GetString(attributeStringPrefix, data)
    ZO_GuildFinder_Manager.SetTextForValuePairKeyboard(labelControl, zo_strformat(SI_GUILD_FINDER_GUILD_INFO_HEADER_FORMATTER, labelString), valueString)
end

function ZO_GuildFinder_Manager.SetTextForValuePairKeyboard(labelControl, labelString, valueString)
    local text = zo_strformat(SI_GUILD_FINDER_GUILD_INFO_ATTRIBUTE_FORMATTER, labelString, ZO_SELECTED_TEXT:Colorize(valueString))
    labelControl:SetText(text)
end

function ZO_GuildFinder_Manager.SetTextForNoGrammarValuePairKeyboard(labelControl, labelString, valueString)
    local text = zo_strformat(SI_GUILD_FINDER_GUILD_INFO_NO_GRAMMAR_ATTRIBUTE_FORMATTER, labelString, ZO_SELECTED_TEXT:Colorize(valueString))
    labelControl:SetText(text)
end

function ZO_GuildFinder_Manager.CreatePlaytimeRangeText(guildData)
    local formattedStartTime = ZO_FormatTime(guildData.startTimeHour * ZO_ONE_HOUR_IN_SECONDS, TIME_FORMAT_STYLE_CLOCK_TIME, ZO_GetClockFormat())
    local formattedEndTime = ZO_FormatTime(guildData.endTimeHour * ZO_ONE_HOUR_IN_SECONDS, TIME_FORMAT_STYLE_CLOCK_TIME, ZO_GetClockFormat())
    return zo_strformat(SI_GUILD_FINDER_GUILD_INFO_PLAYTIME_FORMATTER, formattedStartTime, formattedEndTime)
end

function ZO_GuildFinder_Manager.GetRoleIconsText(roles)
    local MAX_ROLES = 3
    local iconTexts = {}

    -- If none are selected auto-select all
    if #roles == 0 then
        roles = { LFG_ROLE_DPS, LFG_ROLE_TANK, LFG_ROLE_HEAL }
    end

    for i = 1, MAX_ROLES do
        if i <= #roles then
            iconTexts[i] = zo_iconFormat(ZO_GetRoleIcon(roles[i]), "100%", "100%")
        else
            iconTexts[i] = ""
        end
    end

    return string.format("%s%s%s", iconTexts[1], iconTexts[2], iconTexts[3])
end

do
    local MAX_CP_ALLOWED = GetMaxSpendableChampionPointsInAttribute() * GetNumAttributes()

    function ZO_GuildFinder_Manager.GetMaxCPAllowedForInput()
        return MAX_CP_ALLOWED
    end
end

function ZO_GuildFinder_Manager.IsFailedApplicationResult(applicationResult)
    return applicationResult ~= GUILD_PROCESS_APP_RESPONSE_APPLICATION_UNPROCESSED and
           applicationResult ~= GUILD_PROCESS_APP_RESPONSE_APPLICATION_ACTION_PROCESSING
end

GUILD_FINDER_MANAGER = ZO_GuildFinder_Manager:New()

-- XML Functions

function ZO_GuildFinder_Applications_Tooltip_Keyboard_OnInitialized(control)
    GUILD_FINDER_MANAGER:SetKeyboardApplicationTooltipInfo(control)
end