ZO_EntryData = ZO_DataSourceObject:Subclass()

function ZO_EntryData:New(...)
    local entryData = ZO_DataSourceObject.New(self)
    entryData:Initialize(...)
    return entryData
end

function ZO_EntryData:Initialize(dataSource)
    self:SetDataSource(dataSource)
end

function ZO_EntryData:Reset()
    self:SetDataSource(nil)
end

-- Instead of using ZO_ScrollList_CreateDataEntry, which creates another table,
-- this will allow the ZO_EntryData to serve all of the functionality a scroll list would need,
-- as a ZO_EntryData is already the wrapper around the real underlying data that said table exists to wrap
function ZO_EntryData:SetupAsScrollListDataEntry(typeId, categoryId)
    self.typeId = typeId
    self.categoryId = categoryId
    self.data = self -- Needed for scroll list compatibility
    self.dataEntry = self -- Needed for scroll list compatibility
end
