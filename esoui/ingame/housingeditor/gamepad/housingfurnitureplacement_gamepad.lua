ZO_HousingFurniturePlacement_Gamepad = ZO_HousingFurnitureList_Gamepad:Subclass()

function ZO_HousingFurniturePlacement_Gamepad:New(...)
    return ZO_HousingFurnitureList_Gamepad.New(self, ...)
end

function ZO_HousingFurniturePlacement_Gamepad:Initialize(owner)
    ZO_HousingFurnitureList_Gamepad.Initialize(self, owner)

    SHARED_FURNITURE:RegisterCallback("PlaceableFurnitureChanged", function(fromSearch)
        if fromSearch then
            self:ResetSavedPositions()
        end
    end)
end

function ZO_HousingFurniturePlacement_Gamepad:InitializeKeybindStripDescriptors()
    ZO_HousingFurnitureList_Gamepad.InitializeKeybindStripDescriptors(self)

    self:AddFurnitureListKeybind(
        -- Primary
        {
            name =  GetString(SI_HOUSING_EDITOR_PLACE),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback =  function()
                            local targetData = self.furnitureList.list:GetTargetData()
                            if targetData then
                                local furnitureObject = targetData.furnitureObject
                                ZO_HousingFurnitureBrowser_Base.SelectFurnitureForPlacement(furnitureObject)
                                SCENE_MANAGER:HideCurrentScene()
                            end
                        end,
        }
    )

end

function ZO_HousingFurniturePlacement_Gamepad:GetCategoryTreeDataRoot()
    return SHARED_FURNITURE:GetPlaceableFurnitureCategoryTreeData()
end

function ZO_HousingFurniturePlacement_Gamepad:OnFurnitureTargetChanged(list, targetData, oldTargetData)
    ZO_HousingFurnitureList_Gamepad.OnFurnitureTargetChanged(self, list, targetData, oldTargetData)

    ZO_HousingFurnitureBrowser_Base.PreviewFurniture(targetData.furnitureObject)
    self:UpdateCurrentKeybinds()
end

function ZO_HousingFurniturePlacement_Gamepad:GetNoItemText()
    if SHARED_FURNITURE:DoesPlayerHavePlaceableFurniture() then
        return GetString(SI_HOUSING_FURNITURE_NO_SEARCH_RESULTS)
    else
        return GetString(SI_HOUSING_FURNITURE_NO_PLACEABLE_FURNITURE)
    end
end