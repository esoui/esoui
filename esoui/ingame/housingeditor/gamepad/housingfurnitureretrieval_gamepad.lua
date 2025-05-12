ZO_HousingFurnitureRetrieveTo_Gamepad = ZO_HousingFurnitureRetrieveTo_Shared:Subclass()

function ZO_HousingFurnitureRetrieveTo_Gamepad:Initialize(control)
    local fragment = ZO_FadeSceneFragment:New(control)
    HOUSING_FURNITURE_RETRIEVE_TO_GAMEPAD_FRAGMENT = fragment
    ZO_HousingFurnitureRetrieveTo_Shared.Initialize(self, control, fragment)
end

function ZO_HousingFurnitureRetrieveTo_Gamepad:SetHidden(hidden)
    if hidden then
        SCENE_MANAGER:RemoveFragment(self.fragment)
    else
        SCENE_MANAGER:AddFragment(self.fragment)
    end
end

-- ZO_HousingFurnitureRetrieveTo_Shared Methods

function ZO_HousingFurnitureRetrieveTo_Gamepad:InitializeControls()
    self.bagLabel = self.control:GetNamedChild("Bag")
    self.slotsUsed = self.control:GetNamedChild("SlotsUsed")
end

function ZO_HousingFurnitureRetrieveTo_Gamepad:RefreshBagList()
    local bagInfo = self:GetSelectedBagInfo()
    if bagInfo then
        self.bagLabel:SetText(bagInfo:GetDisplayName())
        self.slotsUsed:SetText(bagInfo:GetSlotUsageString())
    end
end

-- Global XML

function ZO_HousingFurnitureRetrieveTo_Gamepad.OnControlInitialized(control)
    HOUSING_FURNITURE_RETRIEVE_TO_GAMEPAD = ZO_HousingFurnitureRetrieveTo_Gamepad:New(control)
end

ZO_HousingFurnitureRetrieval_Gamepad = ZO_HousingFurnitureList_Gamepad:Subclass()

function ZO_HousingFurnitureRetrieval_Gamepad:OnShowing(...)
    ZO_HousingFurnitureList_Gamepad.OnShowing(self, ...)
    HOUSING_FURNITURE_RETRIEVE_TO_GAMEPAD:SetHidden(false)
end

function ZO_HousingFurnitureRetrieval_Gamepad:OnHiding(...)
    HOUSING_FURNITURE_RETRIEVE_TO_GAMEPAD:SetHidden(true)
    ZO_HousingFurnitureList_Gamepad.OnHiding(self, ...)
end

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

    self:InitializeRetrieveToDialog()
end

function ZO_HousingFurnitureRetrieval_Gamepad:InitializeKeybindStripDescriptors()
    ZO_HousingFurnitureList_Gamepad.InitializeKeybindStripDescriptors(self)

    -- Retrieve To keybind for category lists.
    table.insert(self.categoryKeybindStripDescriptor,
        {
            name = GetString(SI_HOUSING_EDITOR_RETRIEVE_TO),
            keybind = "UI_SHORTCUT_QUATERNARY",
            callback = function()
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_FURNITURE_RETRIEVE_TO_BAG")
            end,
            visible = function()
                return HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner()
            end,
        })

    self:AddFurnitureListKeybind({
        order = 0,
        name = GetString(SI_HOUSING_EDITOR_MODIFY),
        keybind = "UI_SHORTCUT_PRIMARY",
        callback = function()
            local targetData = self.furnitureList.list:GetTargetData()
            if targetData.furnitureObject:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
                ZO_HousingFurnitureBrowser_Base.SelectNodeForReplacement(targetData.furnitureObject)
            else
                ZO_HousingFurnitureBrowser_Base.SelectFurnitureForReplacement(targetData.furnitureObject)
            end
            SCENE_MANAGER:HideCurrentScene()
        end,
        visible = function()
            local targetData = self.furnitureList.list:GetTargetData()
            if not targetData then
                return false
            end
            return HOUSING_EDITOR_STATE:CanLocalPlayerEditHouse()
        end,
    })

    self:AddFurnitureListKeybind({
        order = 2,
        name = function()
            local targetData = self.furnitureList.list:GetTargetData()
            if targetData.furnitureObject:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
                return GetString(SI_HOUSING_EDITOR_PATH_REMOVE_NODE)
            else
                return GetString(SI_HOUSING_EDITOR_PUT_AWAY)
            end
        end,
        keybind = "UI_SHORTCUT_SECONDARY",
        callback = function()
            local targetData = self.furnitureList.list:GetTargetData()
            if targetData.furnitureObject:GetDataType() == ZO_RECALLABLE_HOUSING_DATA_TYPE then
                ZO_HousingFurnitureBrowser_Base.PutAwayFurniture(targetData.furnitureObject)
            else
                ZO_HousingFurnitureBrowser_Base.PutAwayNode(targetData.furnitureObject)
            end
        end,
        visible = function()
            local targetData = self.furnitureList.list:GetTargetData()
            if not targetData then
                return false
            end
            if targetData.furnitureObject:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
                return HOUSING_EDITOR_STATE:CanLocalPlayerEditHouse()
            else
                return HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner()
            end
        end,
    })

    self:AddFurnitureListKeybind({
        order = 3,
        name = function()
            local targetData = self.furnitureList.list:GetTargetData()
            if targetData and targetData.furnitureObject:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
                return GetString(SI_HOUSING_FURNITURE_SET_STARTING_NODE)
            else
                return GetString(SI_HOUSING_EDITOR_RETRIEVE_TO)
            end
        end,
        keybind = "UI_SHORTCUT_QUATERNARY",
        callback = function()
            local targetData = self.furnitureList.list:GetTargetData()
            if targetData and targetData.furnitureObject:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
                ZO_HousingFurnitureBrowser_Base.SetAsStartingNode(targetData.furnitureObject)
            else
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_FURNITURE_RETRIEVE_TO_BAG")
            end
        end,
        visible = function()
            -- This keybind is only visible if:
            --   The current target is a path node that is not the starting node; or,
            --   The current target is not a path node or there is no target -and- the local player is the homeowner.
            if HOUSING_EDITOR_STATE:CanLocalPlayerEditHouse() then
                local targetData = self.furnitureList.list:GetTargetData()
                if targetData and targetData.furnitureObject:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
                    return not targetData.furnitureObject:IsStartingPathNode()
                else
                    return HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner()
                end
            end
        end,
    })

    self:AddFurnitureListKeybind({
        order = 5,
        name = GetString(SI_HOUSING_EDITOR_PRECISION_EDIT),
        keybind = "UI_SHORTCUT_QUINARY",
        callback = function()
            local targetData = self.furnitureList.list:GetTargetData()
            if targetData.furnitureObject:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE then
                ZO_HousingFurnitureBrowser_Base.SelectNodeForPrecisionEdit(targetData.furnitureObject)
            else
                ZO_HousingFurnitureBrowser_Base.SelectFurnitureForPrecisionEdit(targetData.furnitureObject)
            end
            SCENE_MANAGER:HideCurrentScene()
        end,
        visible = function()
            local targetData = self.furnitureList.list:GetTargetData()
            if not targetData then
                return false
            end
            return HOUSING_EDITOR_STATE:CanLocalPlayerEditHouse()
        end,
    })

    self:AddFurnitureListKeybind({
        order = 6,
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
        end,
    })
end

--Overridden from ZO_HousingFurnitureList_Gamepad
function ZO_HousingFurnitureRetrieval_Gamepad:InitializeOptionsDialogLayoutInfo()
    self.optionsDialogLayoutInfo =
    {
        dialogName = "GAMEPAD_FURNITURE_RETRIEVAL_OPTIONS",
        boundFilterEnabled = true,
        locationFilterEnabled = false,
        limitFilterEnabled = true,
        getFiltersFunction = function()
            local boundFilters = SHARED_FURNITURE:GetRetrievableFurnitureBoundFilters()
            local locationFilters = nil
            local limitFilters = SHARED_FURNITURE:GetRetrievableFurnitureLimitFilters()
            return boundFilters, locationFilters, limitFilters
        end,
        updateFiltersHandler = function(boundFilterValues, locationFilterValues, limitFilterValues)
            SHARED_FURNITURE:SetRetrievableFurnitureFilters(boundFilterValues, limitFilterValues)
        end,
    }
end

function ZO_HousingFurnitureRetrieval_Gamepad:InitializeRetrieveToDialog()
    local function OnRetrieveToBagSelected(bagId)
        HOUSING_FURNITURE_RETRIEVE_TO_GAMEPAD:SetSelectedBag(bagId)
    end

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_FURNITURE_RETRIEVE_TO_BAG",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        title =
        {
            text = SI_HOUSING_EDITOR_RETRIEVE_TO
        },

        finishedCallback = function(dialog)
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end,

        parametricListOnSelectionChangedCallback = function(dialog, list, newSelectedData, oldSelectedData)
            if not (newSelectedData and newSelectedData.bagInfo) then
                return
            end

            local bagInfo = newSelectedData.bagInfo
            local tooltipText = bagInfo:GetTooltipText()
            if tooltipText then
                GAMEPAD_TOOLTIPS:LayoutHousingRetrieveToBag(GAMEPAD_LEFT_TOOLTIP, bagInfo)
            else
                GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
            end
        end,

        setup = function(dialog, allActions)
            local parametricList = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricList)
            HOUSING_FURNITURE_RETRIEVE_TO_GAMEPAD:RefreshBags()

            local bags = HOUSING_FURNITURE_RETRIEVE_TO_GAMEPAD:GetBags()
            for bagIndex, bagInfo in ipairs(bags) do
                if bagInfo:IsVisible() then
                    local displayName = bagInfo:GetFormattedDisplayName()
                    local enabled = bagInfo:IsEnabled()
                    local icon = nil
                    if not enabled then
                        icon = "/EsoUI/Art/Miscellaneous/Gamepad/gp_icon_locked32.dds"
                    elseif bagInfo:IsSelected() then
                        icon = "/EsoUI/Art/Miscellaneous/check_icon_64.dds"
                    end

                    local entryData = ZO_GamepadEntryData:New(displayName, icon)
                    entryData:AddSubLabel(bagInfo:GetSlotUsageString())
                    entryData.bagInfo = bagInfo
                    entryData.bagId = bagInfo:GetBagId()
                    entryData.enabled = enabled
                    entryData.setup = ZO_SharedGamepadEntry_OnSetup
                    entryData.text = displayName
                    entryData.onEnter = OnEnterEntry
                    entryData.onExit = OnExitEntry

                    local desaturation = entryData.enabled and 0 or 1
                    entryData:SetIconDesaturation(desaturation)

                    local listItem =
                    {
                        template = "ZO_GamepadHousingEditorRetrieveToBagEntry",
                        templateData = entryData,
                    }
                    table.insert(parametricList, listItem)
                end
            end

            dialog:setupFunc()
        end,

        parametricList = {}, -- Generated Dynamically

        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData then
                        OnRetrieveToBagSelected(targetData.bagId)
                    end
                end,
                enabled = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    return targetData and targetData.enabled
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_BACK_OPTION,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_FURNITURE_RETRIEVE_TO_BAG")
                end,
            },
        },
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