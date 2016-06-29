--------------------------------------
--Group List Manager
--------------------------------------

GROUP_LIST_MANAGER = nil

ZO_GroupList_Manager = ZO_SocialManager:Subclass()

function ZO_GroupList_Manager:New()
    local manager = ZO_SocialManager.New(self)
    manager:Initialize()
    return manager
end

function ZO_GroupList_Manager:Initialize()
    self:RegisterForEvents()

    self.delayedRebuildCounter = 0

    self:BuildMasterList()
end

function ZO_GroupList_Manager:RegisterForEvents()
    --  During group invitation, we can receive a lot of event spam at once on a single invite when the
     -- involved players are at the same location. Add a delay so we only refresh once in cases like this.
    local function DelayedRefreshData()
        self.delayedRebuildCounter = self.delayedRebuildCounter - 1
        if self.delayedRebuildCounter == 0 then
            self:RefreshData()
        end
    end

    local function RegisterDelayedRefresh()
        self.delayedRebuildCounter = self.delayedRebuildCounter + 1
        zo_callLater(DelayedRefreshData, 50)
    end

    local function RegisterDelayedRefreshOnUnitEvent(eventCode, unitTag)
        if ZO_Group_IsGroupUnitTag(unitTag) then
            RegisterDelayedRefresh()
        end
    end

    local function RefreshOnUnitEvent(eventCode, unitTag)
        if ZO_Group_IsGroupUnitTag(unitTag) then
            self:RefreshData()
        end
    end

    local function RefreshData()
        self:RefreshData()
    end

    local function OnGroupMemberLeft(eventCode, characterName, reason, wasLocalPlayer, amLeader)
        if(wasLocalPlayer) then
            RefreshData()
        end
    end
    
    local function OnGroupMemberJoined()
        --EVENT_UNIT_CREATED will handle the major logic, this is just for the sound
        PlaySound(SOUNDS.GROUP_JOIN)
    end

    EVENT_MANAGER:RegisterForEvent("ZO_GroupList_Manager", EVENT_UNIT_CREATED, RegisterDelayedRefreshOnUnitEvent)
    EVENT_MANAGER:RegisterForEvent("ZO_GroupList_Manager", EVENT_UNIT_DESTROYED, RegisterDelayedRefreshOnUnitEvent)
    EVENT_MANAGER:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_JOINED, OnGroupMemberJoined)
    EVENT_MANAGER:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_LEFT, OnGroupMemberLeft)
    EVENT_MANAGER:RegisterForEvent("ZO_GroupList_Manager", EVENT_LEVEL_UPDATE, RefreshOnUnitEvent)
    EVENT_MANAGER:RegisterForEvent("ZO_GroupList_Manager", EVENT_CHAMPION_POINT_UPDATE, RefreshOnUnitEvent)
    EVENT_MANAGER:RegisterForEvent("ZO_GroupList_Manager", EVENT_ZONE_UPDATE, RefreshOnUnitEvent)
    EVENT_MANAGER:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_ROLES_CHANGED, RegisterDelayedRefreshOnUnitEvent)
    EVENT_MANAGER:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_CONNECTED_STATUS, RefreshOnUnitEvent)
    EVENT_MANAGER:RegisterForEvent("ZO_GroupList_Manager", EVENT_LEADER_UPDATE, RegisterDelayedRefresh)
    EVENT_MANAGER:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_UPDATE, RegisterDelayedRefresh)
    EVENT_MANAGER:RegisterForEvent("ZO_GroupList_Manager", EVENT_PLAYER_ACTIVATED, RegisterDelayedRefresh)
    EVENT_MANAGER:RegisterForEvent("ZO_GroupList_Manager", EVENT_GROUP_MEMBER_ACCOUNT_NAME_UPDATED, RefreshData)
end

function ZO_GroupList_Manager:BuildMasterList()
    ZO_ClearNumericallyIndexedTable(self.masterList)

    for i = 1, GetGroupSize() do
        local unitTag = GetGroupUnitTagByIndex(i)
        if unitTag then
            local isDps, isHeal, isTank = GetGroupMemberRoles(unitTag)
            local rawCharacterName = GetRawUnitName(unitTag)
            local zoneName = zo_strformat(SI_SOCIAL_LIST_LOCATION_FORMAT, GetUnitZone(unitTag))
            local unitOnline = IsUnitOnline(unitTag)
            local displayName = GetUnitDisplayName(unitTag)
            local userFacingDisplayName = ZO_FormatUserFacingDisplayName(displayName)
            local status = unitOnline and PLAYER_STATUS_ONLINE or PLAYER_STATUS_OFFLINE

            self.masterList[i] = 
            {
                index = i,
                unitTag = unitTag,
                characterName = GetUnitName(unitTag),
                rawCharacterName = rawCharacterName,
                gender = GetGenderFromNameDescriptor(rawCharacterName),
                formattedZone = zoneName,
                class = GetUnitClassId(unitTag),
                level = GetUnitLevel(unitTag),
                championPoints = GetUnitEffectiveChampionPoints(unitTag),
                leader = IsUnitGroupLeader(unitTag),
                online = unitOnline,
                isPlayer = AreUnitsEqual(unitTag, "player"),
                isDps = isDps,
                isHeal = isHeal,
                isTank = isTank,
                displayName = displayName,
                status = status,
                hasCharacter = true,
                isGroup = true,
                type = ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_SEARCH_TYPE_NAMES,
            }
        end
end
end

--Globals
GROUP_LIST_MANAGER = ZO_GroupList_Manager:New()

do
    local groupUnitTags = setmetatable({}, {__index = function(self, key)
        local groupIndex = tonumber(key:match("^group(%d+)$"))
        if groupIndex and groupIndex >= 1 and groupIndex <= GROUP_SIZE_MAX then
            self[key] = groupIndex
        else
            self[key] = false
        end

        return self[key]
    end, })

    function ZO_Group_IsGroupUnitTag(unitTag)
        return groupUnitTags[unitTag] ~= false
    end

    function ZO_Group_GetGroupIndexFromUnitTag(unitTag)
        return groupUnitTags[unitTag] or nil
    end

    local groupIndices = {}
    function ZO_Group_GetUnitTagForGroupIndex(groupIndex)
        return groupIndices[groupIndex]
    end

    for i = 1, GROUP_SIZE_MAX do
        groupIndices[i] = "group" .. i
    end
end