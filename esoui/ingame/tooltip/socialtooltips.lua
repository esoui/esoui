
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

local function TryAddOffline(self, offline)
    if offline then
        local offlineSection = self:AcquireSection(self:GetStyle("bodySection"))
        offlineSection:AddLine(GetString(SI_GAMEPAD_CONTACTS_STATUS_OFFLINE), self:GetStyle("socialOffline"))
        self:AddSection(offlineSection)
    end
end

local FORMATTED_VETERAN_RANK_ICON = zo_iconFormat(GetGamepadVeteranRankIcon(), 48, 48)

local function AddCharacterInfo(self, characterName, class, gender, guildId, guildRankIndex, level, veteranRank, alliance, zone)
    if characterName then
        local characterSection = self:AcquireSection(self:GetStyle("charaterNameSection"))
        characterSection:AddLine(characterName, self:GetStyle("socialStatsValue"))
        self:AddSection(characterSection)
    end
    
    local statsSection = self:AcquireSection(self:GetStyle("socialStatsSection"))

    if level then
        local levelPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
        levelPair:SetStat(GetString(SI_GAMEPAD_CONTACTS_LIST_HEADER_LEVEL), self:GetStyle("statValuePairStat"))
        local levelString = level
        if veteranRank and veteranRank ~= 0 then
            levelString = zo_strformat(SI_GAMEPAD_CONTACTS_VETERAN_RANK_FORMAT, FORMATTED_VETERAN_RANK_ICON, veteranRank)
        end
        levelPair:SetValue(levelString, self:GetStyle("socialStatsValue"))
        statsSection:AddStatValuePair(levelPair)
    end

    if class then
        local classPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
        classPair:SetStat(GetString(SI_GAMEPAD_CONTACTS_LIST_HEADER_CLASS), self:GetStyle("statValuePairStat"))
        gender = gender or GENDER_MALE
        local className = zo_strformat(SI_CLASS_NAME, GetClassName(gender, class))
        classPair:SetValue(className, self:GetStyle("socialStatsValue"))
        statsSection:AddStatValuePair(classPair)
    end
    
    if alliance then
        local alliancePair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
        alliancePair:SetStat(GetString(SI_GAMEPAD_CONTACTS_LIST_HEADER_ALLIANCE), self:GetStyle("statValuePairStat"))
        alliancePair:SetValue(alliance, self:GetStyle("socialStatsValue"))
        statsSection:AddStatValuePair(alliancePair)
    end

    if guildRankIndex and guildId then
        local guildRankPair = statsSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
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

function ZO_Tooltip:LayoutFriend(displayName, characterName, class, gender, level, veteranRank, alliance, zone, offline)
    AddHeader(self, displayName)
    AddCharacterInfo(self, characterName, class, gender, nil, nil, level, veteranRank, alliance, zone)
    TryAddOffline(self, offline)
end


function ZO_Tooltip:LayoutGuildMember(displayName, characterName, class, gender, guildId, guildRankIndex, note, level, veteranRank, alliance, zone, offline)
    AddHeader(self, displayName)
    AddCharacterInfo(self, characterName, class, gender, guildId, guildRankIndex, level, veteranRank, alliance, zone)
    AddNote(self, note)
    TryAddOffline(self, offline)
end