ZO_Refresh = ZO_Object:Subclass()

function ZO_Refresh:New()
    local object = ZO_Object.New(self)
    object.refreshGroups = {}
    object.currentlyRefreshing = false
    return object
end

function ZO_Refresh:AddRefreshGroup(refreshGroup, data)
    data.dirtySingles = {}
    data.wasShown = false
    self.refreshGroups[refreshGroup] = data
end

function ZO_Refresh:RefreshAll(refreshGroup)
    local refreshData = self.refreshGroups[refreshGroup]
    refreshData.allDirty = true
end

function ZO_Refresh:RefreshSingle(refreshGroup, ...)
    local refreshData = self.refreshGroups[refreshGroup]

    if(refreshData.allDirty) then
        return
    end

    local numInList = select("#", ...)
    for _, data in ipairs(refreshData.dirtySingles) do
        local alreadyHaveData = true
        for i = 1, numInList do
            if(data[i] ~= select(i, ...)) then
                alreadyHaveData = false
                break
            end
        end
        if(alreadyHaveData) then
            return
        end
    end

    table.insert(refreshData.dirtySingles, {...})
end

function ZO_Refresh:UpdateRefreshGroups()
    if self.currentlyRefreshing then return end
    self.currentlyRefreshing = true

    for refreshGroup, refreshData in pairs(self.refreshGroups) do
        if(refreshData.IsShown) then
            local dataShown = refreshData.IsShown()
            if(dataShown ~= refreshData.wasShown) then
                refreshData.wasShown = dataShown
                refreshData.RefreshAll()
                refreshData.allDirty = false
                ZO_ClearNumericallyIndexedTable(refreshData.dirtySingles)
            end
        end
        if(refreshData.allDirty or #refreshData.dirtySingles > 0) then
            if(refreshData.IsShown == nil or refreshData.IsShown()) then
                if(refreshData.allDirty) then
                    refreshData.RefreshAll()
                else
                    for _, singleData in ipairs(refreshData.dirtySingles) do
                        refreshData.RefreshSingle(unpack(singleData))
                    end
                end
                refreshData.allDirty = false
                ZO_ClearNumericallyIndexedTable(refreshData.dirtySingles)
            end
        end
    end

    self.currentlyRefreshing = false
end