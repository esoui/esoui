ZO_EntryData = ZO_DataSourceObject:Subclass()

function ZO_EntryData:New(...)
    local entryData = ZO_DataSourceObject.New(self)
    entryData:Initialize(...)
    return entryData
end

function ZO_EntryData:Initialize(dataSource)
    self:SetDataSource(dataSource)
end