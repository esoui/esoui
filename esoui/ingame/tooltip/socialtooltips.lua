
local function AddHeader(self, displayName)
    local headerSection = self:AcquireSection(self:GetStyle("socialTitle"))
    headerSection:AddLine(displayName)
    self:AddSection(headerSection)
end

local function AddNote(self, note)
     if note and note ~= "" then
        local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
        bodySection:AddLine(note, self:GetStyle("bodyDescription"))
        self:AddSection(bodySection)
    end
end

local function TryAddOffline(self, offline, secsSinceLogoff, timeStamp)
    if offline then
        local offlineSection = self:AcquireSection(self:GetStyle("bodySection"))
        offlineSection:AddLine(GetString(SI_GAMEPAD_CONTACTS_STATUS_OFFLINE), self:GetStyle("socialOffline"))
        self:AddSection(offlineSection)

        local lastOnlineSection = self:AcquireSection(self:GetStyle("socialStatsSection"))
        local lastOnlinePair = lastOnlineSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
        lastOnlinePair:SetStat(GetString(SI_GAMEPAD_SOCIAL_LIST_LAST_ONLINE), self:GetStyle("statValuePairStat"))
        lastOnlinePair:SetValue(ZO_FormatDurationAgo(secsSinceLogoff + GetFrameTimeSeconds() - timeStamp), self:GetStyle("socialStatsValue"))
        lastOnlineSection:AddStatValuePair(lastOnlinePair)

        self:AddSection(lastOnlineSection)
    end
end

local function AddCharacterInfo(self, characterName, class, gender, guildId, guildRankIndex, level, championPoints, alliance, zone)
    if characterName then
        local characterSection = self:AcquireSection(self:GetStyle("characterNameSection"))
        characterSection:AddLine(ZO_FormatUserFacingCharacterName(characterName), self:GetStyle("socialStatsValue"))
        self:AddSection(characterSection)
    end
    
    local statsSection = self:AcquireSection(self:GetStyle("socialStatsSection"))

    if level then
        local levelPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
        levelPair:SetStat(GetString(SI_GAMEPAD_CONTACTS_LIST_HEADER_LEVEL), self:GetStyle("statValuePairStat"))
        local ICON_SIZE = 40
        local levelString = ZO_GetLevelOrChampionPointsString(level, championPoints, ICON_SIZE)
        levelPair:SetValue(levelString, self:GetStyle("socialStatsValue"))
        statsSection:AddStatValuePair(levelPair)
    end

    if class then
        local classPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
        classPair:SetStat(GetString(SI_GAMEPAD_CONTACTS_LIST_HEADER_CLASS), self:GetStyle("statValuePairStat"))
        gender = gender or GENDER_MALE
        local className = zo_strformat(SI_CLASS_NAME, GetClassName(gender, class))
        classPair:SetValue(className, self:GetStyle("socialStatsValue"))
        statsSection:AddStatValuePair(classPair)
    end
    
    if alliance then
        local alliancePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
        alliancePair:SetStat(GetString(SI_GAMEPAD_CONTACTS_LIST_HEADER_ALLIANCE), self:GetStyle("statValuePairStat"))
        alliancePair:SetValue(alliance, self:GetStyle("socialStatsValue"))
        statsSection:AddStatValuePair(alliancePair)
    end

    if guildRankIndex and guildId then
        local guildRankPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
        guildRankPair:SetStat(GetString(SI_GAMEPAD_GUILD_ROSTER_RANK_HEADER), self:GetStyle("statValuePairStat"))
        local guildRankName = GetFinalGuildRankName(guildId, guildRankIndex)
        guildRankPair:SetValue(guildRankName, self:GetStyle("socialStatsValue"))
        statsSection:AddStatValuePair(guildRankPair)
    end

    if zone then
        local zonePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"), self:GetStyle("fullWidth"))
        zonePair:SetStat(GetString(SI_SOCIAL_LIST_PANEL_HEADER_ZONE), self:GetStyle("statValuePairStat"))
        zonePair:SetValue(zone, self:GetStyle("socialStatsValue"))
        statsSection:AddStatValuePair(zonePair)
    end

    self:AddSection(statsSection)
end

function ZO_Tooltip:LayoutFriend(displayName, characterName, class, gender, level, championPoints, alliance, zone, offline, secsSinceLogoff, timeStamp)
    AddHeader(self, displayName)
    local NO_GUILD_ID = nil
    local NO_GUILD_RANK = nil
    AddCharacterInfo(self, characterName, class, gender, NO_GUILD_ID, NO_GUILD_RANK, level, championPoints, alliance, zone)
    TryAddOffline(self, offline, secsSinceLogoff, timeStamp)
end

function ZO_Tooltip:LayoutGuildMember(displayName, characterName, class, gender, guildId, guildRankIndex, note, level, championPoints, alliance, zone, offline, secsSinceLogoff, timeStamp)
    AddHeader(self, displayName)
    AddCharacterInfo(self, characterName, class, gender, guildId, guildRankIndex, level, championPoints, alliance, zone)
    AddNote(self, note)
    TryAddOffline(self, offline, secsSinceLogoff, timeStamp)
end

function ZO_Tooltip:LayoutGuildInvitee(displayName, characterName)
    AddHeader(self, displayName)

    local inviteeSection = self:AcquireSection(self:GetStyle("socialStatsSection"))
    inviteeSection:AddLine(GetString(SI_GUILD_INVITED_PLAYER_LOCATION), self:GetStyle("guildInvitee"))
    self:AddSection(inviteeSection)
end

function ZO_Tooltip:LayoutHelpLink(helpLink)
    local headerSection = self:AcquireSection(self:GetStyle("topSection"))
    headerSection:AddLine(GetString(SI_GAMEPAD_HELP_LINK_TOOLTIP_HEADER), self:GetStyle("title"))
    self:AddSection(headerSection)

    local helpCategoryIndex, helpIndex = GetHelpIndicesFromHelpLink(helpLink)
    local helpName = GetHelpInfo(helpCategoryIndex, helpIndex)
    local name, _, _, _, _, _, gamepadName = GetHelpCategoryInfo(helpCategoryIndex)
    local helpCategoryName = gamepadName ~= "" and gamepadName or name

    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    params = {
        "UI_SHORTCUT_SECONDARY",
        ZO_WHITE:Colorize(helpCategoryName),
        ZO_WHITE:Colorize(helpName),
    }
    local KEYBIND_INDEX = 1
    bodySection:AddParameterizedKeybindLine(SI_GAMEPAD_HELP_LINK_TOOLTIP_DESCRIPTION, params, KEYBIND_INDEX, self:GetStyle("flavorText"))
    self:AddSection(bodySection)
end
