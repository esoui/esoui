ZO_HousingFurniturePlacement_Keyboard = ZO_HousingFurnitureList:Subclass()

function ZO_HousingFurniturePlacement_Keyboard:New(...)
    return ZO_HousingFurnitureList.New(self, ...)
end

function ZO_HousingFurniturePlacement_Keyboard:InitializeKeybindStrip()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_HOUSING_EDITOR_PLACE),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                self:SelectForPlacement(mostRecentlySelectedData)
            end,
            enabled = function()
                local hasSelection = self:GetMostRecentlySelectedData() ~= nil
                if not hasSelection then
                    return false, GetString(SI_HOUSING_BROWSER_MUST_CHOOSE_TO_PLACE)
                end
                return true
            end,
        },
        {
            name = GetString(SI_CRAFTING_EXIT_PREVIEW_MODE),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                self:ClearSelection()
            end,
            visible = function()
                local hasSelection = self:GetMostRecentlySelectedData() ~= nil
                return hasSelection
            end,
        },
    }
end

function ZO_HousingFurniturePlacement_Keyboard:OnSearchTextChanged(editBox)
    ZO_HousingFurnitureList.OnSearchTextChanged(self, editBox)
    SHARED_FURNITURE:SetPlaceableTextFilter(editBox:GetText())
end

function ZO_HousingFurniturePlacement_Keyboard:AddListDataTypes()
    self.PlaceableFurnitureOnMouseClickCallback = function(control, buttonIndex, upInside)
        if buttonIndex == MOUSE_BUTTON_INDEX_LEFT and upInside then
            ZO_ScrollList_MouseClick(self:GetList(), control)
        end
    end

    self.PlaceableFurnitureOnMouseDoubleClickCallback = function(control, buttonIndex)
        if buttonIndex == MOUSE_BUTTON_INDEX_LEFT then
            local data = ZO_ScrollList_GetData(control)
            self:SelectForPlacement(data)
        end
    end

    self:AddDataType(ZO_PLACEABLE_HOUSING_DATA_TYPE, "ZO_PlayerFurnitureSlot", ZO_HOUSING_FURNITURE_LIST_ENTRY_HEIGHT, function(...) self:SetupFurnitureRow(...) end, ZO_HousingFurnitureBrowser_Keyboard.OnHideFurnitureRow)
end

function ZO_HousingFurniturePlacement_Keyboard:SelectForPlacement(data)
    ZO_HousingFurnitureBrowser_Base.SelectFurnitureForPlacement(data)
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_HousingFurniturePlacement_Keyboard:SetupFurnitureRow(control, data)
    ZO_HousingFurnitureBrowser_Keyboard.SetupFurnitureRow(control, data, self.PlaceableFurnitureOnMouseClickCallback, self.PlaceableFurnitureOnMouseDoubleClickCallback)
end

function ZO_HousingFurniturePlacement_Keyboard:GetCategoryTreeData()
    return SHARED_FURNITURE:GetPlaceableFurnitureCategoryTreeData()
end

function ZO_HousingFurniturePlacement_Keyboard:GetNoItemText()
    if SHARED_FURNITURE:DoesPlayerHavePlaceableFurniture() then
        return GetString(SI_HOUSING_FURNITURE_NO_SEARCH_RESULTS)
    else
        return GetString(SI_HOUSING_FURNITURE_NO_PLACEABLE_FURNITURE)
    end
end