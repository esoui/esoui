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
                        if targetData.furnitureObject:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
                            ZO_HousingFurnitureBrowser_Base.SelectNodeForReplacement(targetData.furnitureObject)
                        else
                            ZO_HousingFurnitureBrowser_Base.SelectFurnitureForReplacement(targetData.furnitureObject)
                        end
                        SCENE_MANAGER:HideCurrentScene()
                    end,
    })

    self:AddFurnitureListKeybind({    
        name =  function()
                    local targetData = self.furnitureList.list:GetTargetData()
                    if targetData and targetData.furnitureObject:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
                        return GetString(SI_HOUSING_EDITOR_PATH_REMOVE_NODE)
                    else
                        return GetString(SI_HOUSING_EDITOR_PUT_AWAY)
                    end
                end,
        keybind = "UI_SHORTCUT_SECONDARY",
        callback =  function() 
                        local targetData = self.furnitureList.list:GetTargetData()
                        if targetData.furnitureObject:GetDataType() == ZO_RECALLABLE_HOUSING_DATA_TYPE then
                            ZO_HousingFurnitureBrowser_Base.PutAwayFurniture(targetData.furnitureObject)
                        else
                            ZO_HousingFurnitureBrowser_Base.PutAwayNode(targetData.furnitureObject)
                        end
                    end,
    })

    self:AddFurnitureListKeybind({
        name = GetString(SI_WORLD_MAP_ACTION_SET_PLAYER_WAYPOINT),
        keybind = "UI_SHORTCUT_RIGHT_STICK",
        callback = function()
            local targetData = self.furnitureList.list:GetTargetData()
            SHARED_FURNITURE:SetPlayerWaypointTo(targetData.furnitureObject)
        end,
        enabled = function()
            local targetData = self.furnitureList.list:GetTargetData()
            if not targetData then
                return false
            end
            local dataType = targetData.furnitureObject:GetDataType()
            return dataType == ZO_RECALLABLE_HOUSING_DATA_TYPE or dataType == ZO_HOUSING_PATH_NODE_DATA_TYPE
        end
    })

    self:AddFurnitureListKeybind({
        name =  GetString(SI_HOUSING_FURNITURE_SET_STARTING_NODE),
        keybind = "HOUSING_EDITOR_QUINARY_ACTION",
        order = 50,
        callback =  function() 
                        local targetData = self.furnitureList.list:GetTargetData()
                        ZO_HousingFurnitureBrowser_Base.SetAsStartingNode(targetData.furnitureObject)
                    end,
        visible =   function()
                        local targetData = self.furnitureList.list:GetTargetData()
                        return targetData and targetData.furnitureObject:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE and not targetData.furnitureObject:IsStartingPathNode()
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