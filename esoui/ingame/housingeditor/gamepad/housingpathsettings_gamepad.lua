ZO_HousingPathSettings_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_HousingPathSettings_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_HousingPathSettings_Gamepad:Initialize(control)
    self:InitializeControls(control)
    self:InitializeHeader()
    self:InitializeLists()
end

function ZO_HousingPathSettings_Gamepad:InitializeControls(control)
    GAMEPAD_HOUSING_PATH_SETTINGS_SCENE = ZO_Scene:New("gamepad_housing_path_settings", SCENE_MANAGER)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, GAMEPAD_HOUSING_PATH_SETTINGS_SCENE)

    GAMEPAD_HOUSING_PATH_SETTINGS_FRAGMENT = ZO_SimpleSceneFragment:New(control)

    SYSTEMS:RegisterGamepadObject("path_settings", self)
    SYSTEMS:RegisterGamepadRootScene("housing_path_settings", GAMEPAD_HOUSING_PATH_SETTINGS_SCENE)
end

function ZO_HousingPathSettings_Gamepad:InitializeHeader()
    self.headerData =
    {
        titleText = GetString(SI_HOUSING_EDITOR_PATH_SETTINGS),
        messageText = "",
    }

    ZO_GamepadGenericHeader_SetDataLayout(self.header, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_SEPARATE)
    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

function ZO_HousingPathSettings_Gamepad:InitializeKeybindStripDescriptors()
    local list = self:GetMainList()

    self.keybindStripDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                if self:IsMainListActive() then
                    local data = list:GetSelectedData()
                    if data.callbackLabel then
                        return data.callbackLabel
                    end
                end

                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,
            visible = function()
                if self:IsMainListActive() then
                    local data = list:GetSelectedData()
                    if data and data.callback then
                        return true
                    end

                    return false
                else
                    local currentList = self:GetCurrentList()
                    return currentList and not currentList:IsEmpty()
                end
            end,
            callback = function()
                if self:IsMainListActive() then
                    local data = list:GetSelectedData()
                    if data and data.callback then
                        data.callback()
                    end
                else
                    self:OnSelectTargetObject()
                end
            end,
        },
    }

    local function OnClickCallback()
        if self:IsMainListActive() then
            SCENE_MANAGER:HideCurrentScene()
        else
            self:ShowMainList()
            self:ShowChangeCollectibleTooltip()
        end
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnClickCallback)

    self:SetListsUseTriggerKeybinds(true)
end

function ZO_HousingPathSettings_Gamepad:InitializeLists()
    local ALLOW_EVEN_IF_DISABLED = true
    local NO_ANIMATION = true

    local function SetupPathStateControl(control, data, selected, reselectingDuringRebuild, enabled, active)
        local function OnToggled()
            ZO_GamepadCheckBoxTemplate_OnClicked(control)
            HousingEditorToggleSelectedFurniturePathState()
        end

        data.text = GetString(data.generalInfo.text)
        data.callbackLabel = GetString(SI_GAMEPAD_TOGGLE_OPTION)
        data.callback = OnToggled
        ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)

        if HousingEditorGetSelectedFurniturePathState() == HOUSING_FURNITURE_PATH_STATE_ON then
            ZO_CheckButton_SetChecked(control.checkBox)
        else
            ZO_CheckButton_SetUnchecked(control.checkBox)
        end
    end

    local function SetupConformToGroundControl(control, data, selected, reselectingDuringRebuild, enabled, active)
        local function OnToggled()
            ZO_GamepadCheckBoxTemplate_OnClicked(control)
            HousingEditorToggleSelectedFurniturePathConformToGround()
        end

        data.text = GetString(data.generalInfo.text)
        data.callbackLabel = GetString(SI_GAMEPAD_TOGGLE_OPTION)
        data.callback = OnToggled
        ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)

        if HousingEditorGetSelectedFurniturePathConformToGround() then
            ZO_CheckButton_SetChecked(control.checkBox)
        else
            ZO_CheckButton_SetUnchecked(control.checkBox)
        end
    end

    local function SetupCheckboxControl(control, data, selected, reselectingDuringRebuild, enabled, active)
        if data.index == ZO_HOUSING_PATH_SETTINGS_CONTROL_DATA_PATHING_STATE then
            SetupPathStateControl(control, data, selected, reselectingDuringRebuild, enabled, active)
        else
            SetupConformToGroundControl(control, data, selected, reselectingDuringRebuild, enabled, active)
        end
    end

    local function SetupPathTypeControl(control, data, selected, reselectingDuringRebuild, enabled, active)
        local label = control:GetNamedChild("Name")
        local color = selected and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT
        local r, g, b, a = color:UnpackRGBA()
        label:SetColor(r, g, b, 1)
        label:SetText(GetString(data.generalInfo.text))
        
        control.horizontalListObject:Clear()
        local horizontalList = control.horizontalListObject
        for optionValue = PATH_FOLLOW_TYPE_ITERATION_BEGIN, PATH_FOLLOW_TYPE_ITERATION_END do
            if optionValue == PATH_FOLLOW_TYPE_ONE_WAY then
                -- skip this for now, it is not supported
            else
                local entryData = 
                {
                    text = GetString("SI_PATHFOLLOWTYPE", optionValue),
                    value = optionValue,
                    parentControl = control
                }
                horizontalList:AddEntry(entryData)
            end
        end

        horizontalList:SetOnSelectedDataChangedCallback(nil)
        horizontalList:SetSelectedFromParent(selected)
        horizontalList:Commit()
        horizontalList:SetActive(selected)

        local selectedValue = HousingEditorGetSelectedFurniturePathFollowType()
        local selectedIndex = selectedValue + 1
        horizontalList:SetSelectedDataIndex(selectedIndex, ALLOW_EVEN_IF_DISABLED, NO_ANIMATION)

        local function OnSelectionChanged(selectedData, oldData, reselectingDuringRebuild)
            if selectedData then
                local result = HousingEditorSetSelectedFurniturePathFollowType(selectedData.value)
                ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, result)
            end
        end
        horizontalList:SetOnSelectedDataChangedCallback(OnSelectionChanged)
    end

    local function SetupChangeCollectibleControl(control, data, selected, reselectingDuringRebuild, enabled, active)
        data.callback = function()
            self:ShowChangeObjectList()
        end
        data.text = GetString(data.generalInfo.buttonText)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    self.mainList = self:GetMainList()
    self.mainList:AddDataTemplate("ZO_GamepadFullWidthLabelEntryTemplate", SetupChangeCollectibleControl)
    self.mainList:AddDataTemplate("ZO_CheckBoxTemplate_Gamepad", SetupCheckboxControl, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.mainList:AddDataTemplate("ZO_GamepadHorizontalListRow", SetupPathTypeControl, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.mainList:SetOnTargetDataChangedCallback(function(...) self:OnSettingsTargetChanged(...) end)

    self.changeObjectList = self:AddList("changeObject")
    self.changeObjectList:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    local USE_DEFAULT_COMPARISON = nil
    self.changeObjectList:AddDataTemplateWithHeader("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, USE_DEFAULT_COMPARISON, "ZO_GamepadMenuEntryHeaderTemplate")
    self.changeObjectList:SetNoItemText(GetString(SI_ANTIQUITY_EMPTY_LIST))
    self.changeObjectList:SetOnTargetDataChangedCallback(function(...) self:OnChangeObjectTargetChanged(...) end)

    local function OnHouseChanged()
        -- Refresh the Option List to show/hide the Change Object entry as appropriate.
        self.dirty = true
    end

    HOUSING_EDITOR_STATE:RegisterCallback("HouseChanged", OnHouseChanged)
end

function ZO_HousingPathSettings_Gamepad:RefreshFragments()
    if self:IsMainListActive() then
        SCENE_MANAGER:RemoveFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_CENTERED)
        SCENE_MANAGER:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_QUADRANT_3_4)
    else
        SCENE_MANAGER:RemoveFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_QUADRANT_3_4)
        SCENE_MANAGER:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_CENTERED)
    end
end

function ZO_HousingPathSettings_Gamepad:OnSettingsTargetChanged(list, targetData, oldTargetData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    if targetData and targetData.generalInfo then
        targetData.generalInfo.tooltipFunction()
    end
end

do
    local HIDE_VISUAL_LAYER_INFO = false
    local NO_COOLDOWN = nil
    local HIDE_BLOCK_REASON = false

    function ZO_HousingPathSettings_Gamepad:RefreshFurnitureTooltip(targetData)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        if targetData then
            local furnitureData = targetData.furnitureData
            if furnitureData and furnitureData.collectibleId then
                local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(furnitureData.collectibleId)
                GAMEPAD_TOOLTIPS:LayoutCollectibleFromData(GAMEPAD_RIGHT_TOOLTIP, collectibleData, HIDE_VISUAL_LAYER_INFO, NO_COOLDOWN, HIDE_BLOCK_REASON)
            end
        end
    end
end

function ZO_HousingPathSettings_Gamepad:OnChangeObjectTargetChanged(list, targetData, oldTargetData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    if targetData then
        if IsCharacterPreviewingAvailable() then
            targetData.furnitureData:Preview()
            self:RefreshFurnitureTooltip(targetData)
        end
    end
end

function ZO_HousingPathSettings_Gamepad:RefreshOptionList()
    self.mainList:Clear()
    for controlTypeIndex, controlInfo in ipairs(ZO_HOUSING_PATH_SETTINGS_CONTROL_DATA) do
        if controlInfo.visible == nil or controlInfo.visible() then
            local entry = ZO_GamepadEntryData:New(GetString(controlInfo.text))
            entry.generalInfo = controlInfo
            entry.index = controlTypeIndex
            self.mainList:AddEntry(controlInfo.gamepadTemplate, entry)
        end
    end
    self.mainList:Commit()
end

function ZO_HousingPathSettings_Gamepad:RefreshChangeObjectList()
    local objectList = self.changeObjectList
    objectList:Clear()

    local categoryTreeData = self:GetPathableFurnitureCategoryTreeData()
    if categoryTreeData then
        local allTopLevelCategories = categoryTreeData:GetAllSubcategories()
        for categoryIndex, categoryData in ipairs(allTopLevelCategories) do
            for subcategoryIndex, subcategoryData in ipairs(categoryData:GetAllSubcategories()) do
                for furnitureIndex, furnitureData in ipairs(subcategoryData:GetAllEntries()) do
                    local furnitureEntry = ZO_GamepadEntryData:New(furnitureData:GetFormattedName(), furnitureData:GetIcon())
                    furnitureEntry.furnitureData = furnitureData

                    if furnitureIndex == 1 then
                        local formattedCategoryName = string.format("%s - %s (%d)", categoryData:GetName(), subcategoryData:GetName(), subcategoryData:GetNumEntryItemsRecursive())
                        furnitureEntry:SetHeader(formattedCategoryName)
                        objectList:AddEntry("ZO_GamepadItemEntryTemplateWithHeader", furnitureEntry)
                    else
                        objectList:AddEntry("ZO_GamepadItemEntryTemplate", furnitureEntry)
                    end
                end
            end
        end
    end

    objectList:SetNoItemText(GetString(SI_HOUSING_FURNITURE_NO_PATHABLE_FURNITURE))
    objectList:Commit()
    return objectList:IsEmpty()
end

function ZO_HousingPathSettings_Gamepad:PerformUpdate()
    self:RefreshHeader()
    self:RefreshOptionList()
    self:RefreshFragments()
    self.dirty = false
end

function ZO_HousingPathSettings_Gamepad:OnHiding()
    ZO_Gamepad_ParametricList_Screen.OnHiding(self)
    self:DeactivateSelectedControl()
end

function ZO_HousingPathSettings_Gamepad:DeactivateSelectedControl()
    local selectedControl = self.mainList:GetSelectedControl()
    if selectedControl and selectedControl.horizontalListObject then
        selectedControl.horizontalListObject:Deactivate()
    end
end

function ZO_HousingPathSettings_Gamepad:RefreshHeader()
    if self:IsMainListActive() then
        local itemName, icon, furnitureDataId = GetPlacedHousingFurnitureInfo(HousingEditorGetSelectedFurnitureId())
        if itemName and itemName ~= "" then
            self.headerData.messageText = zo_strformat(SI_HOUSING_FURNITURE_NAME_FORMAT, itemName)
        else
            self.headerData.messageText = ""
        end
        self.headerData.titleText = GetString(SI_HOUSING_EDITOR_PATH_SETTINGS)
    else
        self.headerData.titleText = GetString(SI_HOUSING_PATH_SETTINGS_CHANGE_COLLECTIBLE_BUTTON_TEXT)
    end

    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
end

function ZO_HousingPathSettings_Gamepad:OnSelectTargetObject()
    local list = self:GetCurrentList()
    if list then
        local data = list:GetTargetData()
        if data then
            local currentFurnitureId = HousingEditorGetSelectedFurnitureId()
            local newCollectibleId = data.furnitureData.collectibleId

            SCENE_MANAGER:HideCurrentScene()
            HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION)
            local result = HousingEditorRequestReplacePathCollectible(currentFurnitureId, newCollectibleId)
            ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, result)
        end
    end
end

function ZO_HousingPathSettings_Gamepad:IsMainListActive()
    local currentList = self:GetCurrentList()
    return currentList == self:GetMainList()
end

function ZO_HousingPathSettings_Gamepad:ShowMainList()
    ITEM_PREVIEW_GAMEPAD:EndCurrentPreview()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    self:SetCurrentList(self:GetMainList())
    self:RefreshHeader()
    self:RefreshFragments()
end

function ZO_HousingPathSettings_Gamepad:ShowChangeObjectList()
    self:RefreshChangeObjectList()
    self:SetCurrentList("changeObject")
    self:RefreshHeader()
    self:RefreshFragments()
end

function ZO_HousingPathSettings_Gamepad:GetPathableFurnitureCategoryTreeData()
    return SHARED_FURNITURE:GetPathableFurnitureCategoryTreeData()
end

function ZO_HousingPathSettings_Gamepad:SetPathData()
    self:Update()
end

function ZO_HousingPathSettings_Gamepad:ShowPathTypeTooltip()
    local title = GetString(SI_HOUSING_PATH_SETTINGS_PATHING_TYPE_TEXT)
    local body = GetString(SI_HOUSING_PATH_SETTINGS_PATHING_TYPE_TOOLTIP)
    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, title, body)
end

function ZO_HousingPathSettings_Gamepad:ShowPathingStateTooltip()
    local title = GetString(SI_HOUSING_PATH_SETTINGS_PATHING_STATE_TEXT)
    local body = GetString(SI_HOUSING_PATH_SETTINGS_PATHING_STATE_TOOLTIP)
    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, title, body)
end

function ZO_HousingPathSettings_Gamepad:ShowConformToGroundTooltip()
    local title = GetString(SI_HOUSING_PATH_SETTINGS_CONFORM_TO_GROUND_TEXT)
    local body = GetString(SI_HOUSING_PATH_SETTINGS_CONFORM_TO_GROUND_TOOLTIP)
    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, title, body)
end

function ZO_HousingPathSettings_Gamepad:ShowChangeCollectibleTooltip()
    local title = GetString(SI_HOUSING_PATH_SETTINGS_CHANGE_COLLECTIBLE_BUTTON_TEXT)
    local body = GetString(SI_HOUSING_PATH_SETTINGS_CHANGE_COLLECTIBLE_TOOLTIP)
    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, title, body)
end

-- Global UI

function ZO_HousingPathSettings_Gamepad_OnInitialized(control)
    GAMEPAD_HOUSING_PATH_SETTINGS = ZO_HousingPathSettings_Gamepad:New(control)
end