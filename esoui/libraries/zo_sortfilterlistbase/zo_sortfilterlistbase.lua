ZO_SortFilterListBase = ZO_Object:Subclass()

function ZO_SortFilterListBase:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_SortFilterListBase:Initialize()
end

function ZO_SortFilterListBase:RefreshVisible()
end

function ZO_SortFilterListBase:RefreshSort()
end

function ZO_SortFilterListBase:RefreshFilters() 
end

function ZO_SortFilterListBase:RefreshData()
end

