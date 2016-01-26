local ACTIVITY_DATA = {
    [LFG_ACTIVITY_CYRODIIL] = {
        name = GetString("SI_LFGACTIVITY", LFG_ACTIVITY_CYRODIIL),
        type = LFG_ACTIVITY_CYRODIIL,

        texture = "EsoUI/Art/LFG/Keyboard/LFG_activityArt_cyrodiil_keyboard.dds",
        textureGamepad = "EsoUI/Art/LFG/Gamepad/LFG_activityArt_cyrodiil_gamepad.dds",
    },
    [LFG_ACTIVITY_IMPERIAL_CITY] = {
        name = GetString("SI_LFGACTIVITY", LFG_ACTIVITY_IMPERIAL_CITY),
        type = LFG_ACTIVITY_IMPERIAL_CITY,

        texture = "EsoUI/Art/LFG/Keyboard/LFG_activityArt_imperialCity_keyboard.dds",
        textureGamepad = "EsoUI/Art/LFG/Gamepad/LFG_activityArt_imperialCity_gamepad.dds",
    },
    [LFG_ACTIVITY_DUNGEON] = {
        name = GetString("SI_LFGACTIVITY", LFG_ACTIVITY_DUNGEON),
        type = LFG_ACTIVITY_DUNGEON,

        texture = "EsoUI/Art/LFG/Keyboard/LFG_activityArt_dungeon_keyboard.dds",
        textureGamepad = "EsoUI/Art/LFG/Gamepad/LFG_activityArt_dungeon_gamepad.dds",

        allText = GetString(SI_LFG_ANY_DUNGEON),
        allDescription = GetString(SI_LFG_ANY_DUNGEON_DESCRIPTION),
    },
    [LFG_ACTIVITY_MASTER_DUNGEON] = {
        name = GetString("SI_LFGACTIVITY", LFG_ACTIVITY_MASTER_DUNGEON),
        type = LFG_ACTIVITY_MASTER_DUNGEON,

        texture = "EsoUI/Art/LFG/Keyboard/LFG_activityArt_vetDungeon_keyboard.dds",
        textureGamepad = "EsoUI/Art/LFG/Gamepad/LFG_activityArt_vetDungeon_gamepad.dds",

        allText = GetString(SI_LFG_ANY_VETERAN_DUNGEON),
        allDescription = GetString(SI_LFG_ANY_VETERAN_DUNGEON_DESCRIPTION),
    },
}

local NO_TEXTURE_FILE = "/esoui/art/icons/icon_missing.dds"

ZO_GROUP_TYPE_TO_SIZE = {
    [LFG_GROUP_TYPE_REGULAR] = SMALL_GROUP_SIZE_THRESHOLD,
    [LFG_GROUP_TYPE_MEDIUM] = RAID_GROUP_SIZE_THRESHOLD,
    [LFG_GROUP_TYPE_LARGE] = GROUP_SIZE_MAX,
}

LFG_LOCATIONS_ALL_INDEX = 1
local FIRST_LOCATION_INDEX = 2


function LFGLevelSort(entry1, entry2)
    if entry1.veteranRankMin ~= entry2.veteranRankMin then
        return entry1.veteranRankMin < entry2.veteranRankMin
    elseif entry1.levelMin ~= entry2.levelMin then
        return entry1.levelMin < entry2.levelMin
    elseif entry1.veteranRankMax ~= entry2.veteranRankMax then
        return entry1.veteranRankMax < entry2.veteranRankMax
    elseif entry1.levelMax ~= entry2.levelMax then
        return entry1.levelMax < entry2.levelMax
    else
        return entry1.name < entry2.name
    end
end

local function CreateLocationData(activityType, lfgIndex)
    local name, levelMin, levelMax, veteranRankMin, veteranRankMax, groupType, passedReqs, description, descriptionTexture, descriptionTextureGamepad = GetLFGOption(activityType, lfgIndex)

    --Default to 'all' art if one doesn't exist for this location
    if descriptionTexture == NO_TEXTURE_FILE then
        descriptionTexture = ACTIVITY_DATA[activityType].texture
    end
    if descriptionTextureGamepad == NO_TEXTURE_FILE then
        descriptionTextureGamepad = ACTIVITY_DATA[activityType].textureGamepad
    end

    return {
        name = zo_strformat(SI_LFG_ACTIVITY_NAME, name),
        rawName = name,
        description = description,
        descriptionTexture = descriptionTexture,
        descriptionTextureGamepad = descriptionTextureGamepad,
        activityType = activityType,
        levelMin = levelMin,
        levelMax = levelMax,
        veteranRankMin = veteranRankMin,
        veteranRankMax = veteranRankMax,
        groupType = groupType,
        isSelected = false,
        lfgIndex = lfgIndex
    }
end

local function IsPreferredRoleSelected()
    local isDPS, isHeal, isTank = GetPlayerRoles()
    return isDPS or isHeal or isTank
end



--------------------------------------------
-- Grouping Tools Manager Shared
--------------------------------------------
ZO_GroupingToolsManager_Shared = ZO_Object:Subclass()


function ZO_GroupingToolsManager_Shared:New(control)
    local manager = ZO_Object.New(self)
    manager:Initialize(control)
    return manager
end

function ZO_GroupingToolsManager_Shared:Initialize(control)
    self.control = control

    self:InitializeActivityData()
    self:InitializeLocationData()
    self:RegisterForEvents()

    self:OnPreferredCampaignChanged(GetPreferredCampaign())

    self.selectedGroupType = nil
end

local ACTIVITY_ORDER = {
    [LFG_ACTIVITY_DUNGEON]          = 0,
    [LFG_ACTIVITY_MASTER_DUNGEON]   = 1,
    [LFG_ACTIVITY_TRIAL]            = 2,
    [LFG_ACTIVITY_CYRODIIL]         = 3,
    [LFG_ACTIVITY_IMPERIAL_CITY]    = 4,
}

local function ActivitySort(entry1, entry2)
    return ACTIVITY_ORDER[entry1.type] < ACTIVITY_ORDER[entry2.type]
end

function ZO_GroupingToolsManager_Shared:InitializeActivityData()
    local activitiesData = {}

    for type, data in pairs(ACTIVITY_DATA) do
        table.insert(activitiesData, data)
    end
    table.sort(activitiesData, ActivitySort)

    self.activitiesData = activitiesData
end

function ZO_GroupingToolsManager_Shared:InitializeLocationData()
    local locationsData = {}

    for i = 1, #self.activitiesData do
        local activityType = self.activitiesData[i].type
        locationsData[activityType] = {}

        for lfgIndex = 1, GetNumLFGOptions(activityType) do
            local passedRequirements = select(7, GetLFGOption(activityType, lfgIndex))
            if passedRequirements then --this should only need to be checked at initialization, the current requirements don't change between sessions
                local data = CreateLocationData(activityType, lfgIndex)
                table.insert(locationsData[activityType], data)
            end
        end
        
        table.sort(locationsData[activityType], LFGLevelSort)

        --Insert the all selection
        if DoesLFGActivityHasAllOption(activityType) then
            local activityData = ACTIVITY_DATA[activityType]
            local data = {
                    name = activityData.allText,
                    description = activityData.allDescription,
                    descriptionTexture = activityData.texture,
                    descriptionTextureGamepad = activityData.textureGamepad,
                    activityType = activityType,
                    groupType = locationsData[activityType][LFG_LOCATIONS_ALL_INDEX].groupType, --there should not be an all option unless the group types are the same for all locations
                    isSelected = false,
                    isAllOption = true,
                }
            table.insert(locationsData[activityType], LFG_LOCATIONS_ALL_INDEX, data)
        end
    end

    self.locationsData = locationsData

    self:UpdateLocations()
end

function ZO_GroupingToolsManager_Shared:RegisterForEvents()

    local function ClearUpdate()
        self:ClearUpdate()
    end


    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, ClearUpdate)
    self.control:RegisterForEvent(EVENT_GROUPING_TOOLS_STATUS_UPDATE, function(event, ...) self:OnGroupingToolsStatusUpdate(...) end)
    self.control:RegisterForEvent(EVENT_PREFERRED_CAMPAIGN_CHANGED, function(event, ...) self:OnPreferredCampaignChanged(...) end)

    self.control:RegisterForEvent(EVENT_LEVEL_UPDATE, function(eventCode, ...) self:OnLevelUpdate(...) end)
    self.control:RegisterForEvent(EVENT_VETERAN_RANK_UPDATE, function(eventCode, ...) self:OnVeteranRankUpdate(...) end)
    self.control:RegisterForEvent(EVENT_GROUP_MEMBER_LEFT, ClearUpdate)
    self.control:RegisterForEvent(EVENT_GROUP_MEMBER_JOINED, ClearUpdate)
    self.control:RegisterForEvent(EVENT_GROUP_UPDATE, ClearUpdate)

    self.control:RegisterForEvent(EVENT_LEADER_UPDATE, ClearUpdate)
end

function ZO_GroupingToolsManager_Shared:ClearUpdate()
    --  A clear and update is required when the selections may change due to requirement changes. (Ex: a group member
    --joins that doesn't meet the level requirement of a location already selected. The location needs to be unselected
    --and locked, and then all other locations need to be refreshed again in case they are now unlocked. Instead of
    --nesting refreshes, just clear and update when an event occurs that can lead to this.)

    self:ClearSelections()
    self:UpdateLocations()
end

do
    local function IsAnyGroupMemberVeteran()
        for i = 1, GROUP_SIZE_MAX do
            local unitTag = ZO_Group_GetUnitTagForGroupIndex(i)
            if IsUnitVeteran(unitTag) then
                return true
            end
        end

        return false
    end

    local function GetLevelRankRequirementText(levelMin, levelMax, rankMin, rankMax)
        local playerRank = GetUnitVeteranRank("player")
    
        if playerRank > 0 or levelMin == GetMaxLevel() then
            if playerRank < rankMin then
                return zo_strformat(SI_LFG_LOCK_REASON_PLAYER_MIN_RANK_REQUIREMENT, rankMin)
            elseif playerRank > rankMax then
                return zo_strformat(SI_LFG_LOCK_REASON_PLAYER_MAX_RANK_REQUIREMENT, rankMax)
            end
        else
            local playerLevel = GetUnitLevel("player")
    
            if playerLevel < levelMin then
                return zo_strformat(SI_LFG_LOCK_REASON_PLAYER_MIN_LEVEL_REQUIREMENT, levelMin)
            elseif playerLevel > levelMax then
                return zo_strformat(SI_LFG_LOCK_REASON_PLAYER_MAX_LEVEL_REQUIREMENT, levelMax)
            end
        end
    end

    function ZO_GroupingToolsManager_Shared:UpdateLocations()
        if IsCurrentlySearchingForGroup() then
            self:UpdateLocationsFromSearch()
            return
        end

        --Determine lock status for each location
        for activityType, locationsByActivity in pairs(self.locationsData) do
            local allAreLocked = true
            local inAGroup = IsUnitGrouped("player")
            local groupSize = GetGroupSize()
            local isRoleSelected = IsPreferredRoleSelected()
            local activityIsAvA = activityType == LFG_ACTIVITY_CYRODIIL or activityType == LFG_ACTIVITY_IMPERIAL_CITY

            for index = #locationsByActivity, 1, -1 do --reversed so we know the 'all locked' status for the all entry at index 1
                local location = locationsByActivity[index]
                location.isLocked = true
                
                if inAGroup and not IsUnitGroupLeader("player") then
                    location.lockReasonText = GetString(SI_LFG_LOCK_REASON_NOT_LEADER)
                elseif not isRoleSelected then
                    location.lockReasonText = GetString(SI_LFG_LOCK_REASON_NO_ROLES_SELECTED)
                elseif activityIsAvA and not IsInAvAZone() then
                    location.lockReasonText = GetString(SI_LFG_LOCK_REASON_NOT_IN_AVA)
                elseif activityIsAvA and not IsInLFGAVAZone(activityType, location.lfgIndex) then
                    location.lockReasonText = zo_strformat(SI_LFG_LOCK_REASON_NOT_IN_AVA_ZONE, location.rawName)
                elseif not activityIsAvA and IsInAvAZone() then
                    location.lockReasonText = GetString(SI_LFG_LOCK_REASON_IN_AVA)
                elseif IsInAvAZone() and IsInLFGGroup() then
                    location.lockReasonText = GetString(SI_LFG_LOCK_REASON_AVA_CROSS_ALLIANCE)
                else
                    if location.isAllOption then
                        if inAGroup then
                            location.lockReasonText = GetString(SI_LFG_LOCK_REASON_SELECTION_LIMIT_MEMBER_SEARCH)
                        elseif allAreLocked then
                            location.lockReasonText = zo_strformat(SI_LFG_LOCK_REASON_ALL_LOCATIONS_LOCKED, GetString("SI_LFGACTIVITY", activityType))
                        else
                            location.isLocked = false
                            location.lockReasonText = ""
                        end
                    else
                        local lfgIndex = location.lfgIndex
                        location.playerMeetsRequirements = DoesPlayerMeetLFGLevelRequirements(activityType, lfgIndex)
                        location.groupMeetsLevelRequirements = DoesGroupMeetLFGLevelRequirements(activityType, lfgIndex)
    
                        local isAnotherLocationSelected = self:IsAnyLocationSelected() and not location.isSelected
                        local groupTooLarge = groupSize > ZO_GROUP_TYPE_TO_SIZE[location.groupType]
                        local groupFull = groupSize == ZO_GROUP_TYPE_TO_SIZE[location.groupType]
                        local isDifferentGroupType = self.selectedGroupType and (location.groupType ~= self.selectedGroupType) or false
                        local requiredCollectible = GetRequiredLFGCollectibleId(activityType, lfgIndex)

                        if inAGroup and isAnotherLocationSelected then --enforce having only one selection for LFM
                            location.lockReasonText = GetString(SI_LFG_LOCK_REASON_SELECTION_LIMIT_MEMBER_SEARCH)
                        elseif groupTooLarge then
                            location.lockReasonText = GetString(SI_LFG_LOCK_REASON_GROUP_TOO_LARGE)
                        elseif groupFull then
                            location.lockReasonText = GetString(SI_LFG_LOCK_REASON_GROUP_FULL)
                        elseif not location.playerMeetsRequirements then
                            location.lockReasonText = GetLevelRankRequirementText(location.levelMin, location.levelMax, location.veteranRankMin, location.veteranRankMax)
                        elseif not location.groupMeetsLevelRequirements and inAGroup then
                            location.lockReasonText = GetString(SI_LFG_LOCK_REASON_GROUP_LOCATION_LEVEL_REQUIREMENTS)
                        elseif isDifferentGroupType then
                            location.lockReasonText = GetString(SI_LFG_LOCK_REASON_SELECTIONS_GROUP_SIZE)
                        elseif requiredCollectible ~= 0 and not IsCollectibleUnlocked(requiredCollectible) then
                            location.lockReasonText = zo_strformat(SI_LFG_LOCK_REASON_DLC_NOT_UNLOCKED, GetCollectibleName(requiredCollectible))
                        else
                            location.isLocked = false
                            location.lockReasonText = ""
                            allAreLocked = false
                        end
                    end
                end
            end
        end
    
        self:RefreshLocationsList()
    end
end

function ZO_GroupingToolsManager_Shared:UpdateLocationsFromSearch()
    --Populate data from any existing search
    local numLFGRequests = GetNumLFGRequests()
    if numLFGRequests > 0 then
        --Update locations
        for i = 1, numLFGRequests do
            local activityType, lfgIndex, isDPS, isHealer, isTank = GetLFGRequestInfo(i)
            local location = self:GetLocationFromLFGIndex(activityType, lfgIndex)
            location.isSelected = true
        end

        --Update 'all' option
        for activityType, locationsByActivity in pairs(self.locationsData) do
            if DoesLFGActivityHasAllOption(activityType) then
                local numberAvailable = 0
                local numberSelected = 0

                for index = FIRST_LOCATION_INDEX, #locationsByActivity do
                    local location = locationsByActivity[index]
                    local playerMeetsRequirements = DoesPlayerMeetLFGLevelRequirements(activityType, location.lfgIndex)

                    if playerMeetsRequirements then
                        numberAvailable = numberAvailable + 1
                    end
                    if location.isSelected then
                        numberSelected = numberSelected + 1
                    end
                end

                local allAreSelected = numberAvailable > 0 and numberSelected == numberAvailable
                if allAreSelected then
                    local allLocation = locationsByActivity[LFG_LOCATIONS_ALL_INDEX]
                    allLocation.isSelected = true
                end
            end
        end
    end

    self:RefreshLocationsList()
end

function ZO_GroupingToolsManager_Shared:ClearSelections()
    for activityType, locationsByActivity in pairs(self.locationsData) do
        for index = 1, #locationsByActivity do
            local location = locationsByActivity[index]
            location.isSelected = false
            location.isLocked = false
        end
    end

    self.selectedGroupType = nil
end

local function IsRoleSelected(roles)
    return roles[LFG_ROLE_DPS] or roles[LFG_ROLE_HEAL] or roles[LFG_ROLE_TANK]
end

local function CheckAddLocation(activityType, lfgIndex, roles)
    if not IsRoleSelected(roles) then
        local alertEnum = IsUnitGrouped("player") and LFG_ERROR_NO_ROLES_SELECTED or LFG_ERROR_NO_ROLES_SELECTED_MULTIPLE
        ZO_AlertEvent(EVENT_GROUPING_TOOLS_ERROR, alertEnum)    
    	return false
    end

    AddGroupFinderSearchEntry(activityType, lfgIndex, roles[LFG_ROLE_DPS], roles[LFG_ROLE_HEAL], roles[LFG_ROLE_TANK])
    return true
end

function ZO_GroupingToolsManager_Shared:StartSearch()
    if IsCurrentlySearchingForGroup() then
        return
    end
    ClearGroupFinderSearch()

    local preferredRoles = GAMEPAD_GROUP_ROLES_BAR:GetRoles()

    --Add locations
    for activityType, locationsByActivity in pairs(self.locationsData) do

        for index = 1, #locationsByActivity do
            local location = locationsByActivity[index]
            if location.isSelected and not location.isAllOption then
                local lfgIndex = location.lfgIndex
                if not CheckAddLocation(activityType, lfgIndex, preferredRoles) then
                    return
                end
            end
        end
    end

    StartGroupFinderSearch()
end

function ZO_GroupingToolsManager_Shared:ToggleLocationSelected(location)
    if location.isLocked then
        return
    end

    if location.isAllOption then
        local locationsByActivity = self.locationsData[location.activityType]

        location.isSelected = not location.isSelected
        for i = 1, #locationsByActivity do
            locationsByActivity[i].isSelected = location.isSelected and not locationsByActivity[i].isLocked
        end

    else
        --Don't allow toggling individual locations when All option is selected
        if self:IsAllOptionSelected(location.activityType) then
            return
        end
        
        location.isSelected = not location.isSelected
    end

    --Set group type. This should only ever be cleared or re-set to the same type since locations of different types are locked.
    if self:IsAnyLocationSelected() then
        self.selectedGroupType = location.groupType
    else
        self.selectedGroupType = nil
    end

    self:UpdateLocations()
end

function ZO_GroupingToolsManager_Shared:IsAllOptionSelected(activityType)
    if DoesLFGActivityHasAllOption(activityType) then
        local locationsByActivity = self.locationsData[activityType]
        return locationsByActivity[LFG_LOCATIONS_ALL_INDEX].isSelected
    end

    return false
end

function ZO_GroupingToolsManager_Shared:IsAnyLocationSelected()
    --TODO: maybe keep an ongoing count of selected activities instead, and return > 0
    for activityType, locationsByActivity in pairs(self.locationsData) do
        for i = 1, #locationsByActivity do
            if locationsByActivity[i].isSelected then
                return true
            end
        end
    end

    return false
end

function ZO_GroupingToolsManager_Shared:GetLocationFromLFGIndex(activityType, lfgIndex)
    local locationsByActivity = self.locationsData[activityType]

    for i = 1, #locationsByActivity do
        if locationsByActivity[i].lfgIndex == lfgIndex then
            return locationsByActivity[i]
        end
    end
end

-- Event callbacks
function ZO_GroupingToolsManager_Shared:OnGroupingToolsStatusUpdate()
    self:ClearUpdate()
end

function ZO_GroupingToolsManager_Shared:OnPreferredCampaignChanged(preferredCampaignId)
    self.currentCampaignName = GetCampaignName(preferredCampaignId)
end

function ZO_GroupingToolsManager_Shared:OnLevelUpdate(unitTag)
    if ZO_Group_IsGroupUnitTag(unitTag) or unitTag == "player" then
        self:ClearUpdate()
    end
end

function ZO_GroupingToolsManager_Shared:OnVeteranRankUpdate(unitTag)
    self:OnLevelUpdate(unitTag)
end

-- 'Virtual' functions
function ZO_GroupingToolsManager_Shared:RefreshLocationsList()
    assert(false) --needs to be overridden
end


do
    EVENT_MANAGER:RegisterForEvent("ZO_GroupingToolsManager_Shared_OnGroupingToolsStatusUpdate", EVENT_GROUPING_TOOLS_STATUS_UPDATE,
        function(event, isSearching)
            PlaySound(isSearching and SOUNDS.LFG_SEARCH_STARTED or SOUNDS.LFG_SEARCH_FINISHED)
        end
    )
end
