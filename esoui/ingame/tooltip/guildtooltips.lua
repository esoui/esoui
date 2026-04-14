function ZO_Tooltip:LayoutGuildApplicationDetails(applicationData)
    local primaryName = ZO_GetPrimaryPlayerName(applicationData.name, applicationData.characterName)
    local secondaryName = ZO_GetSecondaryPlayerName(applicationData.name, applicationData.characterName)
    
    -- Primary Name Header
    local headerSection = self:AcquireSection(self:GetStyle("socialTitle"))
    headerSection:AddLine(primaryName)
    self:AddSection(headerSection)

    -- Secondary Name 
    local characterSection = self:AcquireSection(self:GetStyle("characterNameSection"))
    characterSection:AddLine(secondaryName, self:GetStyle("socialStatsValue"))
    self:AddSection(characterSection)

    local statsSection = self:AcquireSection(self:GetStyle("socialStatsSection"))

    -- Player Level
    local statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
    statValuePair:SetStat(GetString(SI_GUILD_RECRUITMENT_APPLICATIONS_SORT_HEADER_LEVEL), self:GetStyle("statValuePairStat"))
    local ICON_SIZE = 40
    local levelText = ZO_GetLevelOrChampionPointsString(applicationData.level, applicationData.championPoints, ICON_SIZE)
    local levelNarrationText = ZO_GetLevelOrChampionPointsNarrationString(applicationData.level, applicationData.championPoints)
    statValuePair:SetValueWithCustomNarration(levelText, levelNarrationText, self:GetStyle("socialStatsValue"))
    statsSection:AddStatValuePair(statValuePair)

    -- Player Class
    statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
    statValuePair:SetStat(GetString(SI_GUILD_RECRUITMENT_CLASS_HEADER), self:GetStyle("statValuePairStat"))
    statValuePair:SetValue(zo_strformat(SI_CLASS_NAME, GetClassName(GENDER_MALE, applicationData.class)), self:GetStyle("socialStatsValue"))
    statsSection:AddStatValuePair(statValuePair)

    -- Player Alliance
    statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
    statValuePair:SetStat(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_ALLIANCE), self:GetStyle("statValuePairStat"))
    statValuePair:SetValue(ZO_CachedStrFormat(SI_ALLIANCE_NAME, GetAllianceName(applicationData.alliance)), self:GetStyle("socialStatsValue"))
    statsSection:AddStatValuePair(statValuePair)

    -- Player Achievement Points
    statValuePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
    statValuePair:SetStat(GetString(SI_GAMEPAD_ACHIEVEMENTS_POINTS_LABEL), self:GetStyle("statValuePairStat"))
    statValuePair:SetValue(zo_strformat(SI_NUMBER_FORMAT, applicationData.achievementPoints), self:GetStyle("socialStatsValue"))
    statsSection:AddStatValuePair(statValuePair)

    self:AddSection(statsSection)

    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(applicationData.message, self:GetStyle("flavorText"))
    self:AddSection(bodySection)
end

function ZO_Tooltip:LayoutGuildLink(link)
    local guildName = ZO_LinkHandler_ParseLink(link)

    local headerSection = self:AcquireSection(self:GetStyle("topSection"))
    headerSection:AddLine(guildName, self:GetStyle("title"))
    self:AddSection(headerSection)

    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    local params = 
    {
        "UI_SHORTCUT_SECONDARY",
        ZO_WHITE:Colorize(guildName),
    }
    local KEYBIND_INDEX = 1
    bodySection:AddParameterizedKeybindLine(SI_GAMEPAD_GUILD_LINK_TOOLTIP_DESCRIPTION, params, KEYBIND_INDEX, self:GetStyle("flavorText"))
    self:AddSection(bodySection)
end

function ZO_Tooltip:LayoutGuildAlert(text)
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(text, self:GetStyle("failed"), self:GetStyle("flavorText"))
    self:AddSection(bodySection)
end

function ZO_Tooltip:LayoutGuildHistoryEvent(eventData)
    local section = self:AcquireSection(self:GetStyle("bodySection"))

    local function GetEventNarration()
        return eventData:GetNarrationText()
    end

    local IS_GAMEPAD = true
    section:AddLineWithCustomNarration(eventData:GetText(IS_GAMEPAD), GetEventNarration, self:GetStyle("bodyDescription"))
    section:AddLine(eventData:GetFormattedTime(), self:GetStyle("bodyDescription"), self:GetStyle("whiteFontColor"))
    self:AddSection(section)
end

function ZO_Tooltip:LayoutGuildMail(guildMailId)
    local guildId, subject, body, _, expiresInSeconds, _, senderDisplayName = GetGuildMailItemInfo(guildMailId)

    local statPairSection = self:AcquireSection(self:GetStyle("socialStatsSection"))

    --Sender
    if senderDisplayName == "" then
        senderDisplayName = GetString(SI_GUILD_MAIL_MANAGEMENT_UNKNOWN_SENDER)
    else
        senderDisplayName = ZO_FormatUserFacingDisplayName(senderDisplayName)
    end
    local senderPair = statPairSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
    senderPair:SetStat(GetString(SI_GUILD_MAIL_MANAGEMENT_SORT_HEADER_SENDER), self:GetStyle("statValuePairStat"))
    senderPair:SetValue(senderDisplayName, self:GetStyle("socialStatsValue"))
    statPairSection:AddStatValuePair(senderPair)

    --Expires
    local formattedExpiresText
    if expiresInSeconds <= ZO_ONE_MINUTE_IN_SECONDS then
        formattedExpiresText = GetString(SI_STR_TIME_LESS_THAN_MINUTE)
    elseif expiresInSeconds < ZO_ONE_HOUR_IN_SECONDS then
        formattedExpiresText = ZO_FormatTime(expiresInSeconds, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
    else
        formattedExpiresText = ZO_FormatTimeLargestTwo(expiresInSeconds, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL_HIDE_ZEROES)
    end

    local expiresPair = statPairSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
    expiresPair:SetStat(GetString(SI_GUILD_MAIL_MANAGEMENT_SORT_HEADER_EXPIRES), self:GetStyle("statValuePairStat"))
    expiresPair:SetValue(formattedExpiresText, self:GetStyle("socialStatsValue"))
    statPairSection:AddStatValuePair(expiresPair)

    self:AddSection(statPairSection)
    
    -- Target Ranks
    local targetRanks = { GetGuildMailTargetRanks(guildMailId) }
    local targetRankNames = {}
    for _, rank in ipairs(targetRanks) do
        local rankIndex = GetGuildRankIndex(guildId, rank)
        if rankIndex then
            table.insert(targetRankNames, GetFinalGuildRankName(guildId, rankIndex))
        end
    end

    local formattedRanksText
    if #targetRankNames > 0 then
        formattedRanksText = ZO_GenerateCommaSeparatedListWithoutAnd(targetRankNames)
    else
        formattedRanksText = GetString(SI_GUILD_MAIL_MANAGEMENT_RANKS_DROPDOWN_NO_SELECTION_TEXT)
    end

    local ranksSection = self:AcquireSection(self:GetStyle("bodySection"))
    ranksSection:AddLine(GetString(SI_GUILD_MAIL_MANAGEMENT_TO_LABEL), self:GetStyle("guildMailManagementBodyHeader"))
    ranksSection:AddLine(formattedRanksText, self:GetStyle("guildMailManagementBodyDescription"))
    self:AddSection(ranksSection)

    -- Subject
    if subject == "" then
        subject = GetString(SI_MAIL_READ_NO_SUBJECT)
    end
    local subjectSection = self:AcquireSection(self:GetStyle("bodySection"))
    subjectSection:AddLine(GetString(SI_GAMEPAD_MAIL_SUBJECT_LABEL), self:GetStyle("guildMailManagementBodyHeader"))
    subjectSection:AddLine(subject, self:GetStyle("guildMailManagementBodyDescription"))
    self:AddSection(subjectSection)

    --Message
    if body == "" then
        body = GetString(SI_MAIL_READ_NO_BODY)
    end
    local messageSection = self:AcquireSection(self:GetStyle("bodySection"))
    messageSection:AddLine(GetString(SI_GAMEPAD_MAIL_BODY_LABEL), self:GetStyle("guildMailManagementBodyHeader"))
    messageSection:AddLine(body, self:GetStyle("guildMailManagementBodyDescription"))
    self:AddSection(messageSection)
end