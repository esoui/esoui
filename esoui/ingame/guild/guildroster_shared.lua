-----------------
--Guild Roster
-----------------

ZO_GuildRosterManager = ZO_SocialManager:Subclass()
GUILD_MEMBER_DATA = 1

GUILD_ROSTER_ENTRY_SORT_KEYS =
{
    ["displayName"] = { },
    ["characterName"] = { },
    ["status"]  = { tiebreaker = "normalizedLogoffSort", isNumeric = true },
    ["class"]  = { tiebreaker = "displayName" },
    ["formattedZone"]  = { tiebreaker = "displayName" },
    ["alliance"] = { tiebreaker = "displayName" },
    ["championPoints"] = { tiebreaker = "displayName", isNumeric = true},
    ["level"] = { tiebreaker = "championPoints", isNumeric = true },
    ["rankIndex"] = { tiebreaker = "displayName", isNumeric = true },
    ["normalizedLogoffSort"] = { tiebreaker = "displayName", isNumeric = true },
}

local EVENT_NAMESPACE = "GuildRoster"

function ZO_GuildRosterManager:New()
    local manager = ZO_SocialManager.New(self)
    manager:Initialize()
    return manager
end

function ZO_GuildRosterManager:Initialize()
    self.noteEditedFunction = function(displayName, note)
        local numGuildMembers = GetNumGuildMembers(self.guildId)
        for guildMemberIndex = 1, numGuildMembers do       
            local currentDisplayName = GetGuildMemberInfo(self.guildId, guildMemberIndex)
            if(currentDisplayName == displayName) then
                SetGuildMemberNote(self.guildId, guildMemberIndex, note)
            end
        end
    end

    self:BuildMasterList()
    
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GUILD_DATA_LOADED, function() self:OnGuildDataLoaded() end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GUILD_RANKS_CHANGED, function(_, guildId) if(self:MatchesGuild(guildId)) then self:OnGuildRanksChanged() end end) 
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GUILD_MEMBER_ADDED, function(_, guildId, displayName) if(self:MatchesGuild(guildId)) then self:OnGuildMemberAdded(guildId, displayName) end end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GUILD_SELF_JOINED_GUILD, function(_, guildId, displayName) self:OnGuildSelfJoined() end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GUILD_MEMBER_REMOVED, function(_, guildId, displayName, characterName) if(self:MatchesGuild(guildId)) then self:OnGuildMemberRemoved(guildId, characterName, displayName) end end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GUILD_MEMBER_CHARACTER_UPDATED, function(_, guildId, displayName) if(self:MatchesGuild(guildId)) then self:OnGuildMemberCharacterUpdated(displayName) end end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GUILD_MEMBER_CHARACTER_ZONE_CHANGED, function(_, guildId, displayName, characterName, zone) if(self:MatchesGuild(guildId)) then self:OnGuildMemberCharacterZoneChanged(displayName, characterName, zone) end end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GUILD_MEMBER_CHARACTER_LEVEL_CHANGED, function(_, guildId, displayName, characterName, level) if(self:MatchesGuild(guildId)) then self:OnGuildMemberCharacterLevelChanged(displayName, characterName, level) end end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GUILD_MEMBER_CHARACTER_CHAMPION_POINTS_CHANGED, function(_, guildId, displayName, characterName, championPoints) if(self:MatchesGuild(guildId)) then self:OnGuildMemberCharacterChampionPointsChanged(displayName, characterName, championPoints) end end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GUILD_MEMBER_RANK_CHANGED, function(_, guildId, displayName, rankIndex) if(self:MatchesGuild(guildId)) then self:OnGuildMemberRankChanged(displayName, rankIndex) end end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GUILD_MEMBER_PLAYER_STATUS_CHANGED, function(_, guildId, displayName, oldStatus, newStatus) if(self:MatchesGuild(guildId)) then self:OnGuildMemberPlayerStatusChanged(displayName, oldStatus, newStatus) end end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_GUILD_MEMBER_NOTE_CHANGED, function(_, guildId, displayName, note) if(self:MatchesGuild(guildId)) then self:OnGuildMemberNoteChanged(displayName, note) end end)
end

function ZO_GuildRosterManager:MatchesGuild(guildId)
    if(guildId == self.guildId) then
        return true
    end
    return false
end

function ZO_GuildRosterManager:SetGuildId(guildId)
    self.guildId = guildId
    self.guildName = GetGuildName(guildId)
    self.guildAlliance = GetGuildAlliance(guildId)

    self:OnGuildIdChanged()
    self:RefreshAll()
end

function ZO_GuildRosterManager:RefreshAll()
    self:RefreshData()
    self:RefreshRankDependentControls()
end

function ZO_GuildRosterManager:RefreshRankDependentControls()
    self:RefreshVisible()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildRosterManager:ColorRow(control, data, textColor, iconColor, textColor2)
    ZO_SocialList_ColorRow(control, data, textColor, iconColor, textColor2)
    
    if(not self.lockedForUpdates) then
        local rank = GetControl(control, "RankIcon")
        rank:SetColor(iconColor:UnpackRGBA())
    end
end

function ZO_GuildRosterManager:SetupEntry(control, data, selected)
    ZO_SocialList_SharedSocialSetup(control, data, selected)

    local note = GetControl(control, "Note")
    if note then

        if(data.note ~= "") then
            note:SetHidden(false)
            if(DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_NOTE_EDIT)) then
                note:SetState(BSTATE_NORMAL, false)
            else
                note:SetState(BSTATE_DISABLED, true)
            end
        else
            note:SetHidden(true)
        end
    end

    local rank = GetControl(control, "RankIcon")
    local rankTextureFunction = IsInGamepadPreferredMode() and GetFinalGuildRankTextureLarge or GetFinalGuildRankTextureSmall
    local rankTexture = rankTextureFunction(self.guildId, data.rankIndex)
    if(rankTexture) then
        rank:SetHidden(false)
        rank:SetTexture(rankTexture)
    else
        rank:SetHidden(true)
    end
end

function ZO_GuildRosterManager:BuildMasterList()
    ZO_ClearNumericallyIndexedTable(self.masterList)

    local guildId = self.guildId
    local localPlayerIndex = GetPlayerGuildMemberIndex(guildId)
    local numGuildMembers = GetNumGuildMembers(guildId)
    for guildMemberIndex = 1, numGuildMembers do
        local displayName, note, rankIndex, status, secsSinceLogoff = GetGuildMemberInfo(guildId, guildMemberIndex)
        local online = (status ~= PLAYER_STATUS_OFFLINE)
        local rankId = GetGuildRankId(guildId, rankIndex)
        local isLocalPlayer = (localPlayerIndex > 0 and guildMemberIndex == localPlayerIndex)        
        local hasCharacter, rawCharacterName, zone, class, alliance, level, championPoints = GetGuildMemberCharacterInfo(guildId, guildMemberIndex)
       
        local data =  {  
                            index = guildMemberIndex,
                            displayName=displayName,
                            hasCharacter = hasCharacter,
                            isLocalPlayer = isLocalPlayer, 
                            characterName = zo_strformat(SI_UNIT_NAME, rawCharacterName), 
                            gender = GetGenderFromNameDescriptor(rawCharacterName),
                            level = level, 
                            championPoints = championPoints, 
                            class = class, 
                            formattedZone = zo_strformat(SI_SOCIAL_LIST_LOCATION_FORMAT, zone),                         
                            alliance = alliance, 
                            formattedAllianceName = zo_strformat(SI_SOCIAL_LIST_ALLIANCE_FORMAT, GetAllianceName(alliance)),
                            note = note,
                            rankIndex = rankIndex,
                            rankId = rankId,
                            type = SOCIAL_NAME_SEARCH,
                            status = status,
                        }

        ZO_SocialList_SetUpOnlineData(data, online, secsSinceLogoff)
        self.masterList[guildMemberIndex] = data
    end
end

function ZO_GuildRosterManager:GetNoteEditedFunction()
    return self.noteEditedFunction
end

function ZO_GuildRosterManager:GetGuildId()
    return self.guildId
end

function ZO_GuildRosterManager:GetGuildName()
    return self.guildName
end

function ZO_GuildRosterManager:GetGuildAlliance()
    return self.guildAlliance
end

function ZO_GuildRosterManager:GetPlayerData()
    local playerIndex = GetPlayerGuildMemberIndex(self.guildId)   
    return self.masterList[playerIndex]
end

function ZO_GuildRosterManager:FindDataByDisplayName(displayName)
    for i = 1, #self.masterList do
        local data = self.masterList[i]
        if(data.displayName == displayName) then
            return data
        end
    end
end

--Events
---------

function ZO_GuildRosterManager:OnGuildDataLoaded()
    self:RefreshAll()
end

function ZO_GuildRosterManager:OnGuildMemberAdded(guildId, displayName)
    self:RefreshData()
    if(DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_INVITE)) then
        local data = self:FindDataByDisplayName(displayName)
        if(data) then
            local hasCharacter, rawCharacterName, zone, class, alliance, level, championPoints = GetGuildMemberCharacterInfo(self.guildId, data.index)
            local nameToShow = IsInGamepadPreferredMode() and ZO_FormatUserFacingDisplayName(displayName) or rawCharacterName
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GUILD_ROSTER_ADDED, zo_strformat(SI_GUILD_ROSTER_ADDED, nameToShow, self.guildName))
        end
    end
end

function ZO_GuildRosterManager:OnGuildSelfJoined()
    PlaySound(SOUNDS.GUILD_SELF_JOINED)
end

function ZO_GuildRosterManager:OnGuildMemberRemoved(guildId, rawCharacterName, displayName)
    if(DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_INVITE)) then
        if(ShouldDisplayGuildMemberRemoveAlert(rawCharacterName)) then
            local nameToShow = IsInGamepadPreferredMode() and ZO_FormatUserFacingDisplayName(displayName) or rawCharacterName
            ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.GUILD_ROSTER_REMOVED, zo_strformat(SI_GUILD_ROSTER_REMOVED, nameToShow, self.guildName))
        else
            PlaySound(SOUNDS.GUILD_ROSTER_REMOVED)
        end
    end
    self:RefreshData()
end

function ZO_GuildRosterManager:OnGuildMemberCharacterUpdated(displayName)
    local data = self:FindDataByDisplayName(displayName)
    if(data) then
        local hasCharacter, rawCharacterName, zone, class, alliance, level, championPoints = GetGuildMemberCharacterInfo(self.guildId, data.index)
        data.hasCharacter = hasCharacter
        data.characterName = zo_strformat(SI_UNIT_NAME, rawCharacterName)
        data.gender = GetGenderFromNameDescriptor(rawCharacterName)
        data.formattedZone = zo_strformat(SI_SOCIAL_LIST_LOCATION_FORMAT, zone)
        data.class = class
        data.alliance = alliance
        data.formattedAllianceName = ZO_SocialManager_GetFormattedAllianceName(alliance)
        data.level = level
        data.championPoints = championPoints
        self:RefreshFilters()
    end
end

function ZO_GuildRosterManager:OnGuildMemberCharacterZoneChanged(displayName, characterName, zone)
    local data = self:FindDataByDisplayName(displayName)
    if(data) then
        data.formattedZone = zo_strformat(SI_SOCIAL_LIST_LOCATION_FORMAT, zone)
        self:RefreshSort()
    end
end

function ZO_GuildRosterManager:OnGuildMemberCharacterLevelChanged(displayName, characterName, level)
    local data = self:FindDataByDisplayName(displayName)
    if(data) then
        data.level = level
        self:RefreshSort()
    end
end

function ZO_GuildRosterManager:OnGuildMemberCharacterChampionPointsChanged(displayName, characterName, championPoints)
    local data = self:FindDataByDisplayName(displayName)
    if(data) then
        data.championPoints = championPoints
        self:RefreshSort()
    end
end

function ZO_GuildRosterManager:OnGuildMemberRankChanged(displayName, rankIndex)
    local data = self:FindDataByDisplayName(displayName)
    if(data) then
        data.rankIndex = rankIndex
        self:RefreshSort()

        local playerIndex = GetPlayerGuildMemberIndex(self.guildId)
        local playerDisplayName = GetGuildMemberInfo(self.guildId, playerIndex)
        if(playerDisplayName == displayName) then
            self:RefreshRankDependentControls()
        end
    end
end

function ZO_GuildRosterManager:OnGuildMemberPlayerStatusChanged(displayName, oldStatus, newStatus)
    local data = self:FindDataByDisplayName(displayName)
    if(data) then
        --Because we may have refreshed the whole list in between when this event happened and when we received it,
        --we must use our conception of whether they were online, not whether they were online or not when the event happened.
        local wasOnline = data.online
        local isOnline = (newStatus ~= PLAYER_STATUS_OFFLINE)

        data.status = newStatus

        if(wasOnline and not isOnline) then
            ZO_SocialList_SetUpOnlineData(data, false, 0)
        elseif(not wasOnline and isOnline) then
            ZO_SocialList_SetUpOnlineData(data, true) 
            local hasCharacter, rawCharacterName, zone, class, alliance, level, championPoints = GetGuildMemberCharacterInfo(self.guildId, data.index)
            data.characterName = zo_strformat(SI_UNIT_NAME, rawCharacterName)
            data.gender = GetGenderFromNameDescriptor(rawCharacterName)
            data.formattedZone = zo_strformat(SI_SOCIAL_LIST_LOCATION_FORMAT, zone)
            data.class = class
            data.alliance = alliance
            data.formattedAllianceName = ZO_SocialManager_GetFormattedAllianceName(alliance)
            data.level = level
            data.championPoints = championPoints
        end

        self:RefreshFilters()
    end
end

function ZO_GuildRosterManager:OnGuildMemberNoteChanged(displayName, note)
    local data = self:FindDataByDisplayName(displayName)
    if(data) then
        data.note = note
        self:RefreshVisible()
    end
end

function ZO_GuildRosterManager:OnGuildRanksChanged()
    self:RefreshAll()
end

function ZO_GuildRosterManager:OnUpdate(control, currentTime)
    if(currentTime - self.lastUpdateTime > OFFLINE_TIME_UPDATE) then 
        self.lastUpdateTime = currentTime
        self:RefreshVisible()
    end
end

function ZO_GuildRosterManager:OnGuildIdChanged()
    self:CallFunctionOnLists("OnGuildIdChanged")
end


-- A singleton will be used by both keyboard and gamepad screens
GUILD_ROSTER_MANAGER = ZO_GuildRosterManager:New()
