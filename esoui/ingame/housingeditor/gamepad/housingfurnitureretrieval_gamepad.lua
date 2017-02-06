ZO_HousingFurnitureRetrieval_Gamepad = ZO_HousingFurnitureList_Gamepad:Subclass()

function ZO_HousingFurnitureRetrieval_Gamepad:New(...)
    return ZO_HousingFurnitureList_Gamepad.New(self, ...)
end

function ZO_HousingFurnitureRetrieval_Gamepad:Initialize(...)
    ZO_HousingFurnitureList_Gamepad.Initialize(self, ...)

    SHARED_FURNITURE:RegisterCallback("RetrievableFurnitureChanged", function(fromSearch)
        if fromSearch then
            self:ResetSavedPositions()
        end
    end)
end

function ZO_HousingFurnitureRetrieval_Gamepad:InitializeKeybindStripDescriptors()
    ZO_HousingFurnitureList_Gamepad.InitializeKeybindStripDescriptors(self)

    self:AddFurnitureListKeybind({    
        name =  GetString(SI_HOUSING_EDITOR_MODIFY),
        keybind = "UI_SHORTCUT_PRIMARY",
        callback =  function() 
                        local targetData = self.furnitureList.list:GetTargetData()
                        ZO_HousingFurnitureBrowser_Base.SelectFurnitureForReplacement(targetData.furnitureObject)
                        SCENE_MANAGER:HideCurrentScene()
                    end,
    })

    self:AddFurnitureListKeybind({    
        name =  GetString(SI_HOUSING_EDITOR_PUT_AWAY),
        keybind = "UI_SHORTCUT_SECONDARY",
        callback =  function() 
                        local targetData = self.furnitureList.list:GetTargetData()
                        ZO_HousingFurnitureBrowser_Base.PutAwayFurniture(targetData.furnitureObject)
                    end,
    })

    self:AddFurnitureListKeybind({
        name = GetString(SI_WORLD_MAP_ACTION_SET_PLAYER_WAYPOINT),
        keybind = "UI_SHORTCUT_RIGHT_STICK",
        callback = function()
            local targetData = self.furnitureList.list:GetTargetData()
            SHARED_FURNITURE:SetPlayerWaypointTo(targetData.furnitureObject)
        end,
    })
end

--Overridden from ZO_HousingFurnitureList_Gamepad
function ZO_HousingFurnitureRetrieval_Gamepad:GetCategoryTreeDataRoot()
    return SHARED_FURNITURE:GetRetrievableFurnitureCategoryTreeData()
end

--Overridden from ZO_HousingFurnitureList_Gamepad
function ZO_HousingFurnitureRetrieval_Gamepad:GetNoItemText()
    if SHARED_FURNITURE:DoesPlayerHaveRetrievableFurniture() then
        return GetString(SI_HOUSING_FURNITURE_NO_SEARCH_RESULTS)
    else
        return GetString(SI_HOUSING_FURNITURE_NO_RETRIEVABLE_FURNITURE)
    end
end

--Overridden from ZO_HousingFurnitureList_Gamepad
function ZO_HousingFurnitureRetrieval_Gamepad:CompareFurnitureEntries(a, b)
    return a:CompareTo(b)
end