ZO_WorldMapInfo_Shared = ZO_Object:Subclass()

function ZO_WorldMapInfo_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_WorldMapInfo_Shared:Initialize(control)
    self.control = control

    self:InitializeTabs()
end
