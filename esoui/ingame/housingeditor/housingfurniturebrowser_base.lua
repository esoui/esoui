ZO_HousingFurnitureBrowser_Base = ZO_Object:Subclass()

function ZO_HousingFurnitureBrowser_Base:New(...)
    local browserBase = ZO_Object.New(self)
    browserBase:Initialize(...)
    return browserBase
end

function ZO_HousingFurnitureBrowser_Base:Initialize(control)
    self.control = control
end

function ZO_HousingFurnitureBrowser_Base:RefreshMainList()
    assert(false) --intended to be overridden
end