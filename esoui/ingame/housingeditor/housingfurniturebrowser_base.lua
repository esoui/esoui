ZO_HousingFurnitureBrowser_Base = ZO_Object:Subclass()

function ZO_HousingFurnitureBrowser_Base:New(...)
    local browserBase = ZO_Object.New(self)
    browserBase:Initialize(...)
    return browserBase
end

function ZO_HousingFurnitureBrowser_Base:Initialize(control)
    self.control = control
end

function ZO_HousingFurnitureBrowser_Base:RegisterEvents(refreshFunction)
    SHARED_FURNITURE:RegisterCallback("HousingFullInventoryUpdate", refreshFunction)
    SHARED_FURNITURE:RegisterCallback("HousingSingleInventoryUpdate", refreshFunction)
    SHARED_FURNITURE:RegisterCallback("HousingFullCollectionUpdate", refreshFunction)
    SHARED_FURNITURE:RegisterCallback("HousingSingleCollectibleUpdate", refreshFunction)
end

function ZO_HousingFurnitureBrowser_Base:Hiding()
    if HousingEditorIsPreviewing() then
        HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_PLACEMENT)
    else
        HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION)
    end
end

function ZO_HousingFurnitureBrowser_Base:PreviewFurniture(placeableData)
    if placeableData then
        placeableData:Preview()
    end
end

function ZO_HousingFurnitureBrowser_Base:RemoveFurniture(data)
    HousingEditorRequestRemoveFurniture(data.furnitureId) 
end