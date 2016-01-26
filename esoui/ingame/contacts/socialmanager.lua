SOCIAL_NAME_SEARCH = 1

ZO_SocialManager = ZO_Object:Subclass()

function ZO_SocialManager:New()
    local manager = ZO_Object.New(self)
    ZO_SocialManager.Initialize(manager)
    return manager
end

function ZO_SocialManager:Initialize()
    -- a list of lists that will be updated when notifications are received
    self.lists = {}
    self.masterList = {}


    self.search = ZO_StringSearch:New()
    self.search:AddProcessor(SOCIAL_NAME_SEARCH, function(stringSearch, data, searchTerm, cache) return self:ProcessDisplayName(stringSearch, data, searchTerm, cache) end)

end

function ZO_SocialManager:GetMasterList()
    return self.masterList
end

function ZO_SocialManager:BuildMasterList()
    -- Meant to be overridden
end

function ZO_SocialManager:AddList(list)
    table.insert(self.lists, list)
end

function ZO_SocialManager:CallFunctionOnLists(funcName, ...)
    for i,list in ipairs(self.lists) do
        if list[funcName] then
            list[funcName](list, ...)
        end
    end
end

function ZO_SocialManager:SetupEntry(control, data, selected)
    --To be overriden
end

function ZO_SocialManager:RefreshSort()
    self:CallFunctionOnLists("RefreshSort")
end

function ZO_SocialManager:RefreshFilters()
    self:CallFunctionOnLists("RefreshFilters")
end

function ZO_SocialManager:RefreshData()
    self:BuildMasterList()
    self:CallFunctionOnLists("RefreshData")
end

function ZO_SocialManager:RefreshVisible()
    self:CallFunctionOnLists("RefreshVisible")
end

function ZO_SocialManager:IsMatch(searchTerm, data)
    return self.search:IsMatch(searchTerm, data)
end

function ZO_SocialManager:ProcessDisplayName(stringSearch, data, searchTerm, cache)
    local lowerSearchTerm = searchTerm:lower()

    if(zo_plainstrfind(data.displayName:lower(), lowerSearchTerm)) then
        return true
    end

    if(data.characterName ~= nil and zo_plainstrfind(data.characterName:lower(), lowerSearchTerm)) then
        return true
    end
end

do
    local FORMATTED_ALLIANCE_NAMES = {}

    function ZO_SocialManager_GetFormattedAllianceName(alliance)
        local formattedName = FORMATTED_ALLIANCE_NAMES[alliance]
        if not formattedName then
            formattedName = zo_strformat(SI_SOCIAL_LIST_ALLIANCE_FORMAT, GetAllianceName(alliance))
            FORMATTED_ALLIANCE_NAMES[alliance] = formattedName
        end
        return formattedName
    end
end