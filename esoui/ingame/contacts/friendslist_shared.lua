-----------------
--Friends List
-----------------

ZO_FriendsList = ZO_SocialManager:Subclass()

local EVENT_NAMESPACE = "FriendsList"

FRIEND_DATA = 1
FRIENDS_LIST_ENTRY_SORT_KEYS =
{
    ["displayName"] = { },
    ["characterName"] = { },
    ["status"] = { tiebreaker = "normalizedLogoffSort", isNumeric = true  },
    ["class"] = { tiebreaker = "displayName" },
    ["formattedZone"] = { tiebreaker = "displayName" },
    ["alliance"] = { tiebreaker = "displayName" },
    ["championPoints"] = { tiebreaker = "displayName", isNumeric = true},
    ["level"] = { tiebreaker = "championPoints", isNumeric = true },
    ["normalizedLogoffSort"] = { tiebreaker = "displayName", isNumeric = true },
}

function ZO_FriendsList:New()
    local manager = ZO_SocialManager.New(self)
    ZO_FriendsList.Initialize(manager)
    return manager
end

function ZO_FriendsList:Initialize()
    self.lastUpdateTime = 0
    self.numOnlineFriends = 0

    self.noteEditedFunction = function(crossplayDisplayName, note)
        for i = 1, GetNumFriends() do
            local currentCrossplayDisplayName = GetFriendInfo(i)
            if currentCrossplayDisplayName == crossplayDisplayName then
                SetFriendNote(i, note)
                return
            end
        end
    end

    self:BuildMasterList()

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_SOCIAL_DATA_LOADED, function() self:OnSocialDataLoaded() end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_ADDED, function(_, crossplayDisplayName) self:OnFriendAdded(crossplayDisplayName) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_REMOVED, function(_, crossplayDisplayName) self:OnFriendRemoved(crossplayDisplayName) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_CHARACTER_UPDATED, function(_, crossplayDisplayName) self:OnFriendCharacterUpdated(crossplayDisplayName) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_DISPLAY_NAME_CHANGED, function(_, oldCrossplayDisplayName, newCrossplayDisplayName) self:OnFriendDisplayNameChanged(oldCrossplayDisplayName, newCrossplayDisplayName) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_CHARACTER_ZONE_CHANGED, function(_, crossplayDisplayName, characterName, zoneName) self:OnFriendCharacterZoneChanged(crossplayDisplayName, characterName, zoneName) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_CHARACTER_LEVEL_CHANGED, function(_, crossplayDisplayName, characterName, level) self:OnFriendCharacterLevelChanged(crossplayDisplayName, characterName, level) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_CHARACTER_CHAMPION_POINTS_CHANGED, function(_, crossplayDisplayName, characterName, championPoints) self:OnFriendCharacterChampionPointsChanged(crossplayDisplayName, characterName, championPoints) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_NOTE_UPDATED, function(_, crossplayDisplayName, note) self:OnFriendNoteUpdated(crossplayDisplayName, note) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_PLAYER_STATUS_CHANGED, function(_, crossplayDisplayName, characterName, oldStatus, newStatus) self:OnFriendPlayerStatusChanged(crossplayDisplayName, characterName, oldStatus, newStatus) end)
end

function ZO_FriendsList:GetNumOnline()
    return self.numOnlineFriends
end

function ZO_FriendsList:SetupEntry(control, data, selected)
    if not ZO_IsPlaystationPlatform() then
        ZO_SocialList_SharedSocialSetup(control, data, selected)

        local noteControl = control:GetNamedChild("Note")
        if noteControl then
            noteControl:SetHidden(data.note == "")
        end
    else
        local displayNameLabel = control:GetNamedChild("DisplayName")
        if displayNameLabel then
            displayNameLabel:SetText(ZO_FormatUserFacingDisplayName(data.displayName))
        end

        local statusIconControl = control:GetNamedChild("StatusIcon")
        if statusIconControl then
            local textureFunctions = ZO_SocialList_GetPlatformTextureFunctions()
            statusIconControl:SetTexture(textureFunctions.playerStatusIcon(data.status))
        end
    end
end

function ZO_FriendsList:CreateFriendData(friendIndex, crossplayDisplayName, note, status, platformDisplayName)
    local hasCharacter, characterName, zone, class, alliance, level, championPoints, zoneId, consoleId = GetFriendCharacterInfo(friendIndex)

    local data =
    {
        friendIndex = friendIndex,
        displayName = crossplayDisplayName, -- Kept for backwards compatibility, use crossplayDisplayName instead
        crossplayDisplayName = crossplayDisplayName,
        platformDisplayName = platformDisplayName,
        hasCharacter = hasCharacter,
        characterName = ZO_CachedStrFormat(SI_UNIT_NAME, characterName),
        gender = GetGenderFromNameDescriptor(characterName),
        level = level,
        championPoints = championPoints,
        consoleId = consoleId,
        class = class,
        formattedZone = ZO_CachedStrFormat(SI_ZONE_NAME, zone),
        alliance = alliance,
        formattedAllianceName = ZO_CachedStrFormat(SI_ALLIANCE_NAME, GetAllianceName(alliance)),
        note = note,
        type = SOCIAL_NAME_SEARCH,
        status = status,
    }

    return data
end

function ZO_FriendsList:UpdateFriendData(data, friendIndex)
    local hasCharacter, characterName, zone, class, alliance, level, championPoints, zoneId, consoleId = GetFriendCharacterInfo(friendIndex)

    data.friendIndex = friendIndex
    data.hasCharacter = hasCharacter
    data.characterName = ZO_CachedStrFormat(SI_UNIT_NAME, characterName)
    data.gender = GetGenderFromNameDescriptor(characterName)
    data.formattedZone = ZO_CachedStrFormat(SI_ZONE_NAME, zone)
    data.class = class
    data.alliance = alliance
    data.formattedAllianceName = ZO_CachedStrFormat(SI_ALLIANCE_NAME, GetAllianceName(alliance))
    data.level = level
    data.championPoints = championPoints
    data.consoleId = consoleId
end

function ZO_FriendsList:BuildMasterList()
    ZO_ClearNumericallyIndexedTable(self.masterList)

    self.numOnlineFriends = 0
    local numFriends = GetNumFriends()

    for i = 1, numFriends do
        local crossplayDisplayName, note, status, secsSinceLogoff, platformDisplayName = GetFriendInfo(i)

        local online = status ~= PLAYER_STATUS_OFFLINE
        if online then
            self.numOnlineFriends = self.numOnlineFriends + 1
        end

        local data = self:CreateFriendData(i, crossplayDisplayName, note, status, platformDisplayName)
        ZO_SocialList_SetUpOnlineData(data, online, secsSinceLogoff)
        self.masterList[i] = data
    end

    self:OnNumOnlineChanged()
    self:OnNumTotalFriendsChanged()
end

function ZO_FriendsList:FindDataByCrossplayDisplayName(crossplayDisplayName)
    for i, data in ipairs(self.masterList) do
        if data.crossplayDisplayName == crossplayDisplayName then
            return data, i
        end
    end
end

function ZO_FriendsList:GetNoteEditedFunction()
    return self.noteEditedFunction
end

--Events
---------

function ZO_FriendsList:OnSocialDataLoaded()
    self:RefreshData()
end

function ZO_FriendsList:OnFriendAdded(crossplayDisplayName)
    self:RefreshData()
end

function ZO_FriendsList:OnFriendRemoved(crossplayDisplayName)
    local data, index = self:FindDataByCrossplayDisplayName(crossplayDisplayName)
    if index then
        -- NOTE: This must stay in sync with the friends list ordering-by-index in the client
        -- TODO: Use displayName as accessor?
        self.masterList[index] = self.masterList[#self.masterList]
        self.masterList[#self.masterList] = nil
        self:OnNumTotalFriendsChanged()

        if data.online then
            self.numOnlineFriends = self.numOnlineFriends - 1
            self:OnNumOnlineChanged()
        end

        self:RefreshFilters()
    end
end

function ZO_FriendsList:OnFriendNoteUpdated(crossplayDisplayName, note)
    local data = self:FindDataByCrossplayDisplayName(crossplayDisplayName)
    if data then
        data.note = note
        self:RefreshFilters()
    end
end

function ZO_FriendsList:OnFriendCharacterUpdated(crossplayDisplayName)
    local data, friendIndex = self:FindDataByCrossplayDisplayName(crossplayDisplayName)
    if data then
        self:UpdateFriendData(data, friendIndex)
        self:RefreshFilters()
    end
end

function ZO_FriendsList:OnFriendDisplayNameChanged(oldCrossplayDisplayName, newCrossplayDisplayName)
    local data = self:FindDataByCrossplayDisplayName(oldCrossplayDisplayName)
    if data then
        data.displayName = newCrossplayDisplayName -- maintain backwards compatibility
        data.crossplayDisplayName = newCrossplayDisplayName
        self:RefreshSort()
    end
end

function ZO_FriendsList:OnFriendCharacterZoneChanged(crossplayDisplayName, characterName, zoneName)
    local data = self:FindDataByCrossplayDisplayName(crossplayDisplayName)
    if data then
        data.zone = zoneName
        data.formattedZone = ZO_CachedStrFormat(SI_ZONE_NAME, zoneName)
        self:RefreshSort()
    end
end

function ZO_FriendsList:OnFriendCharacterLevelChanged(crossplayDisplayName, characterName, level)
    local data = self:FindDataByCrossplayDisplayName(crossplayDisplayName)
    if data then
        data.level = level
        self:RefreshSort()
    end
end

function ZO_FriendsList:OnFriendCharacterChampionPointsChanged(crossplayDisplayName, characterName, championPoints)
    local data = self:FindDataByCrossplayDisplayName(crossplayDisplayName)
    if data then
        data.championPoints = championPoints
        self:RefreshSort()
    end
end

function ZO_FriendsList:OnFriendPlayerStatusChanged(crossplayDisplayName, characterName, oldStatus, newStatus)
    local data, friendIndex = self:FindDataByCrossplayDisplayName(crossplayDisplayName)
    if data then
        --Because we may have refreshed the whole list in between when this event happened and when we received it,
        --we must use our conception of whether they were online, not whether they were online or not when the event happened.
        local wasOnline = data.online
        local isOnline = (newStatus ~= PLAYER_STATUS_OFFLINE)

        data.status = newStatus

        if wasOnline and not isOnline then
            ZO_SocialList_SetUpOnlineData(data, false, 0)
            self.numOnlineFriends = self.numOnlineFriends - 1
            self:OnNumOnlineChanged()
        elseif not wasOnline and isOnline then
            ZO_SocialList_SetUpOnlineData(data, true)
            self:UpdateFriendData(data, friendIndex)

            self.numOnlineFriends = self.numOnlineFriends + 1
            self:OnNumOnlineChanged()
        end

        self:RefreshFilters()
    end
end

function ZO_FriendsList:OnNumTotalFriendsChanged()
    self:CallFunctionOnLists("OnNumTotalFriendsChanged")
end

function ZO_FriendsList:OnNumOnlineChanged()
    self:CallFunctionOnLists("OnNumOnlineChanged")
    CALLBACK_MANAGER:FireCallbacks("NumOnlineFriendsChanged", self.numOnlineFriends)
end

-- A singleton will be used by both keyboard and gamepad screens
FRIENDS_LIST_MANAGER = ZO_FriendsList:New()