ZO_HousingFurnitureRetrieval_Keyboard = ZO_HousingFurnitureList:Subclass()

function ZO_HousingFurnitureRetrieval_Keyboard:New(...)
    return ZO_HousingFurnitureList.New(self, ...)
end

function ZO_HousingFurnitureRetrieval_Keyboard:Initialize(...)
    ZO_HousingFurnitureList.Initialize(self, ...)

    self.CompareRetrievableEntriesFunction = function(a, b)
        return a.data:CompareTo(b.data)
    end
end

function ZO_HousingFurnitureRetrieval_Keyboard:InitializeKeybindStrip()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_HOUSING_EDITOR_MODIFY),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                self:Retrieve(mostRecentlySelectedData)
            end,
            enabled = function()
                local hasMostRecentlySelectedData = self:GetMostRecentlySelectedData() ~= nil
                if not hasMostRecentlySelectedData then
                    return false, GetString(SI_HOUSING_BROWSER_MUST_CHOOSE_TO_MODIFY)
                end
                return true
            end,
        },
        {
            name = GetString(SI_HOUSING_EDITOR_PUT_AWAY),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                ZO_HousingFurnitureBrowser_Base.PutAwayFurniture(mostRecentlySelectedData)
            end,
            enabled = function()
                local hasMostRecentlySelectedData = self:GetMostRecentlySelectedData() ~= nil
                if not hasMostRecentlySelectedData then
                    return false, GetString(SI_HOUSING_BROWSER_MUST_CHOOSE_TO_PUT_AWAY)
                end
                return true
            end,
        },
        {
            name = GetString(SI_WORLD_MAP_ACTION_SET_PLAYER_WAYPOINT),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                SHARED_FURNITURE:SetPlayerWaypointTo(mostRecentlySelectedData)
            end,
            enabled = function()
                local hasMostRecentlySelectedData = self:GetMostRecentlySelectedData() ~= nil
                if not hasMostRecentlySelectedData then
                    return false, GetString(SI_HOUSING_BROWSER_MUST_CHOOSE_TO_SET_PLAYER_WAYPOINT)
                end
                return true
            end
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

function ZO_HousingFurnitureRetrieval_Keyboard:OnSearchTextChanged(editBox)
    ZO_HousingFurnitureList.OnSearchTextChanged(self, editBox)
    SHARED_FURNITURE:SetRetrievableTextFilter(editBox:GetText())
end

function ZO_HousingFurnitureRetrieval_Keyboard:AddListDataTypes()
    self.RetrievableFurnitureOnMouseClick = function(control, buttonIndex, upInside)
        if buttonIndex == MOUSE_BUTTON_INDEX_LEFT and upInside then
            ZO_ScrollList_MouseClick(self:GetList(), control)
        end
    end

    self.RetrievableFurnitureOnMouseDoubleClick = function(control, buttonIndex)
        if buttonIndex == MOUSE_BUTTON_INDEX_LEFT then
        local data = ZO_ScrollList_GetData(control)
            self:Retrieve(data)
        end
    end

    self:AddDataType(ZO_RECALLABLE_HOUSING_DATA_TYPE, "ZO_RetrievableFurnitureSlot", ZO_HOUSING_FURNITURE_LIST_ENTRY_HEIGHT, function(...) self:SetupRetrievableFurnitureRow(...) end, ZO_HousingFurnitureBrowser_Keyboard.OnHideFurnitureRow)
end

function ZO_HousingFurnitureRetrieval_Keyboard:Retrieve(data)
    ZO_HousingFurnitureBrowser_Base.SelectFurnitureForReplacement(data)
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_HousingFurnitureRetrieval_Keyboard:SetupRetrievableFurnitureRow(control, data)
    ZO_HousingFurnitureBrowser_Keyboard.SetupFurnitureRow(control, data, self.RetrievableFurnitureOnMouseClick, self.RetrievableFurnitureOnMouseDoubleClick)

    local distanceLabel = control:GetNamedChild("Distance")
    distanceLabel:SetText(zo_strformat(SI_HOUSING_BROWSER_DISTANCE_AWAY_FORMAT, data:GetDistanceFromPlayerM()))

    local directionTexture = control:GetNamedChild("Direction")
    directionTexture:SetTextureRotation(data:GetAngleFromPlayerHeadingRadians())
end

--Overridden from ZO_HousingFurnitureList
function ZO_HousingFurnitureRetrieval_Keyboard:GetCategoryTreeData()
    return SHARED_FURNITURE:GetRetrievableFurnitureCategoryTreeData()
end

--Overridden from ZO_HousingFurnitureList
function ZO_HousingFurnitureRetrieval_Keyboard:GetNoItemText()
    if SHARED_FURNITURE:DoesPlayerHaveRetrievableFurniture() then
        return GetString(SI_HOUSING_FURNITURE_NO_SEARCH_RESULTS)
    else
        return GetString(SI_HOUSING_FURNITURE_NO_RETRIEVABLE_FURNITURE)
    end
end

--Overridden from ZO_HousingFurnitureList
function ZO_HousingFurnitureRetrieval_Keyboard:CompareFurnitureEntries(a, b)
    return a:CompareTo(b)
end