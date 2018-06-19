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
    ["status"]  = { tiebreaker = "normalizedLogoffSort", isNumeric = true  },
    ["class"]  = { tiebreaker = "displayName" },
    ["formattedZone"]  = { tiebreaker = "displayName" },
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

    self.noteEditedFunction = function(displayName, note)
        for i = 1, GetNumFriends() do
            local currentDisplayName = GetFriendInfo(i)
            if(currentDisplayName == displayName) then
                SetFriendNote(i, note)
                return
            end
        end
    end

    self:BuildMasterList()

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_SOCIAL_DATA_LOADED, function() self:OnSocialDataLoaded() end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_ADDED, function(_, displayName) self:OnFriendAdded(displayName) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_REMOVED, function(_, displayName) self:OnFriendRemoved(displayName) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_CHARACTER_UPDATED, function(_, displayName) self:OnFriendCharacterUpdated(displayName) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_DISPLAY_NAME_CHANGED, function(_, oldDisplayName, newDisplayName) self:OnFriendDisplayNameChanged(oldDisplayName, newDisplayName) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_CHARACTER_ZONE_CHANGED, function(_, displayName, characterName, zoneName) self:OnFriendCharacterZoneChanged(displayName, characterName, zoneName) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_CHARACTER_LEVEL_CHANGED, function(_, displayName, characterName, level) self:OnFriendCharacterLevelChanged(displayName, characterName, level) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_CHARACTER_CHAMPION_POINTS_CHANGED, function(_, displayName, characterName, championPoints) self:OnFriendCharacterChampionPointsChanged(displayName, characterName, championPoints) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_NOTE_UPDATED, function(_, displayName, note) self:OnFriendNoteUpdated(displayName, note) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_FRIEND_PLAYER_STATUS_CHANGED, function(_, displayName, characterName, oldStatus, newStatus) self:OnFriendPlayerStatusChanged(displayName, characterName, oldStatus, newStatus) end)
end

function ZO_FriendsList:GetNumOnline()
    return self.numOnlineFriends
end

function ZO_FriendsList:SetupEntry(control, data, selected)
    ZO_SocialList_SharedSocialSetup(control, data, selected)

    local note = GetControl(control, "Note")
    if note then
        note:SetHidden(data.note == "")
    end
end

function ZO_FriendsList:CreateFriendData(friendIndex, displayName, note, status)
    local hasCharacter, characterName, zone, class, alliance, level, championPoints = GetFriendCharacterInfo(friendIndex)

    local data =
    {
        friendIndex = friendIndex,
        displayName = displayName,
        hasCharacter = hasCharacter,
        characterName = ZO_CachedStrFormat(SI_UNIT_NAME, characterName), 
        gender = GetGenderFromNameDescriptor(characterName),
        level = level,
        championPoints = championPoints, 
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
    local hasCharacter, characterName, zone, class, alliance, level, championPoints = GetFriendCharacterInfo(friendIndex)

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
end

function ZO_FriendsList:BuildMasterList()
    ZO_ClearNumericallyIndexedTable(self.masterList)
    
    self.numOnlineFriends = 0
    local numFriends = GetNumFriends()

    for i=1, numFriends do  
        local displayName, note, status, secsSinceLogoff = GetFriendInfo(i)

        local online = status ~= PLAYER_STATUS_OFFLINE
        if(online) then
            self.numOnlineFriends = self.numOnlineFriends + 1
        end

        local data = self:CreateFriendData(i, displayName, note, status)
        ZO_SocialList_SetUpOnlineData(data, online, secsSinceLogoff)
        self.masterList[i] = data
    end

    self:OnNumOnlineChanged()
    self:OnNumTotalFriendsChanged()
end

function ZO_FriendsList:FindDataByDisplayName(displayName)
    for i = 1, #self.masterList do
        local data = self.masterList[i]
        if(data.displayName == displayName) then
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

function ZO_FriendsList:OnFriendAdded(displayName)
    self:RefreshData()
end

function ZO_FriendsList:OnFriendRemoved(displayName)
    local data, index = self:FindDataByDisplayName(displayName)
    if(index) then
        -- NOTE: This must stay in sync with the friends list ordering-by-index in the client
        -- TODO: Use displayName as accessor?
        self.masterList[index] = self.masterList[#self.masterList]
        self.masterList[#self.masterList] = nil
        self:OnNumTotalFriendsChanged()

        if(data.online) then
            self.numOnlineFriends = self.numOnlineFriends - 1
            self:OnNumOnlineChanged()
        end

        self:RefreshFilters()
    end
end

function ZO_FriendsList:OnFriendNoteUpdated(displayName, note)
    local data = self:FindDataByDisplayName(displayName)
    if(data) then
        data.note = note
        self:RefreshFilters()
    end
end

function ZO_FriendsList:OnFriendCharacterUpdated(displayName)
    local data, friendIndex = self:FindDataByDisplayName(displayName)
    if(data) then
        self:UpdateFriendData(data, friendIndex)
        self:RefreshFilters()
    end
end

function ZO_FriendsList:OnFriendDisplayNameChanged(oldDisplayName, newDisplayName)
    local data = self:FindDataByDisplayName(oldDisplayName)
    if(data) then
        data.displayName = newDisplayName
        self:RefreshSort()
    end
end

function ZO_FriendsList:OnFriendCharacterZoneChanged(displayName, characterName, zoneName)
    local data = self:FindDataByDisplayName(displayName)
    if data then
        data.zone = zoneName
        data.formattedZone = ZO_CachedStrFormat(SI_ZONE_NAME, zoneName)
        self:RefreshSort()
    end
end

function ZO_FriendsList:OnFriendCharacterLevelChanged(displayName, characterName, level)
    local data = self:FindDataByDisplayName(displayName)
    if(data) then
        data.level = level
        self:RefreshSort()
    end
end

function ZO_FriendsList:OnFriendCharacterChampionPointsChanged(displayName, characterName, championPoints)
    local data = self:FindDataByDisplayName(displayName)
    if(data) then
        data.championPoints = championPoints
        self:RefreshSort()
    end
end

function ZO_FriendsList:OnFriendPlayerStatusChanged(displayName, characterName, oldStatus, newStatus)
    local data, friendIndex = self:FindDataByDisplayName(displayName)
    if(data) then
        --Because we may have refreshed the whole list in between when this event happened and when we received it,
        --we must use our conception of whether they were online, not whether they were online or not when the event happened.
        local wasOnline = data.online
        local isOnline = (newStatus ~= PLAYER_STATUS_OFFLINE)

        data.status = newStatus

        if(wasOnline and not isOnline) then
            ZO_SocialList_SetUpOnlineData(data, false, 0)
            self.numOnlineFriends = self.numOnlineFriends - 1
            self:OnNumOnlineChanged()
        elseif(not wasOnline and isOnline) then            
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
    CHAT_SYSTEM:OnNumOnlineFriendsChanged(self.numOnlineFriends)
end

-- A singleton will be used by both keyboard and gamepad screens
FRIENDS_LIST_MANAGER = ZO_FriendsList:New()