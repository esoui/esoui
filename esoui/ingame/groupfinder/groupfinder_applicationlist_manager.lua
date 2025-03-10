GROUP_FINDER_APPLICATIONS_LIST_ENTRY_SORT_KEYS =
{
    --Sort keys correspond to functions from ZO_GroupFinderPendingApplicationData
    ["GetDisplayName"] = { },
    ["GetCharacterName"] = { },
    ["GetClassId"] = { tiebreaker = "GetDisplayName" },
    ["GetChampionPoints"] = { tiebreaker = "GetDisplayName", isNumeric = true},
    ["GetLevel"] = { tiebreaker = "GetChampionPoints", isNumeric = true },
    ["GetRole"] = { tiebreaker = "GetDisplayName" },
    ["GetEndTimeSeconds"] = { tiebreaker = "GetDisplayName", isNumeric = true },
}

ZO_GroupFinder_ApplicationsList_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_GroupFinder_ApplicationsList_Manager:Initialize()
    self.applicationsData = {}

    self:RegisterForEvents()
end

function ZO_GroupFinder_ApplicationsList_Manager:RegisterForEvents()
    --TODO GroupFinder: Verify which additional events we need to listen for
    EVENT_MANAGER:RegisterForEvent("GroupFinder_ApplicationsList_Manager", EVENT_GROUP_FINDER_CREATE_GROUP_LISTING_RESULT, function() self:RefreshApplicationsData() end)
    EVENT_MANAGER:RegisterForEvent("GroupFinder_ApplicationsList_Manager", EVENT_GROUP_FINDER_REMOVE_GROUP_LISTING_RESULT, function() self:RefreshApplicationsData() end)
    EVENT_MANAGER:RegisterForEvent("GroupFinder_ApplicationsList_Manager", EVENT_GROUP_FINDER_UPDATE_APPLICATIONS, function() self:RefreshApplicationsData() end)
    EVENT_MANAGER:RegisterForEvent("GroupFinder_ApplicationsList_Manager", EVENT_GROUP_FINDER_APPLICATION_RECEIVED, function() self:SetHasNewApplication(true) end)
    EVENT_MANAGER:RegisterForEvent("GroupFinder_ApplicationsList_Manager", EVENT_PLAYER_ACTIVATED, function() self:RefreshApplicationsData() end)
end

do
    local function GetNextApplicationCharacterIdIter(_, lastApplicationCharacterId)
        return GetNextGroupListingApplicationCharacterId(lastApplicationCharacterId)
    end

    function ZO_GroupFinder_ApplicationsList_Manager:RefreshApplicationsData()
        ZO_ClearNumericallyIndexedTable(self.applicationsData)
        --If we haven't created a group listing we shouldn't have any application data
        if HasGroupListingForUserType(GROUP_FINDER_GROUP_LISTING_USER_TYPE_CREATED_GROUP_LISTING) then
            for characterId in GetNextApplicationCharacterIdIter do
                table.insert(self.applicationsData, ZO_GroupFinderPendingApplicationData:New(characterId))
            end
        end
        self:FireCallbacks("ApplicationsListUpdated")
    end
end

function ZO_GroupFinder_ApplicationsList_Manager:GetApplicationsData(optionalSortFunction)
    if optionalSortFunction then
        local sortedApplicationsData = ZO_ShallowTableCopy(self.applicationsData)
        table.sort(sortedApplicationsData, optionalSortFunction)
        return sortedApplicationsData
    else
        return self.applicationsData
    end
end

function ZO_GroupFinder_ApplicationsList_Manager:SetHasNewApplication(hasNew)
    self.hasNewApplication = hasNew
end

function ZO_GroupFinder_ApplicationsList_Manager:HasNewApplication()
    return HasGroupListingForUserType(GROUP_FINDER_GROUP_LISTING_USER_TYPE_CREATED_GROUP_LISTING) and self.hasNewApplication
end

GROUP_FINDER_APPLICATIONS_LIST_MANAGER = ZO_GroupFinder_ApplicationsList_Manager:New()