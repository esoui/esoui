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
    -- dirty will only refresh when visible, or it will refresh next time it's visible
    self:CallFunctionOnLists("DirtySort")
end

function ZO_SocialManager:RefreshFilters()
    -- dirty will only refresh when visible, or it will refresh next time it's visible
    self:CallFunctionOnLists("DirtyFilters")
end

function ZO_SocialManager:RefreshData()
    self:BuildMasterList()
    -- dirty will only refresh when visible, or it will refresh next time it's visible
    self:CallFunctionOnLists("DirtyData")
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
