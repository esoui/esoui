-- Path Settings Menu
----------------------

ZO_HousingPathSettingsMenu_Keyboard = ZO_Object:Subclass()

function ZO_HousingPathSettingsMenu_Keyboard:New(...)
    local menu = ZO_Object.New(self)
    menu:Initialize(...)
    return menu
end

function ZO_HousingPathSettingsMenu_Keyboard:Initialize(control)
    self.control = control

    KEYBOARD_HOUSING_PATH_SETTINGS_SCENE = ZO_Scene:New("keyboard_housing_path_settings_scene", SCENE_MANAGER)
    KEYBOARD_HOUSING_PATH_SETTINGS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.exitKeybindButtonStripDescriptor)
            self:OnShowing()
        elseif newState == SCENE_HIDING then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.exitKeybindButtonStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end)

    self.exitKeybindButtonStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        {
            name = GetString(SI_EXIT_BUTTON),
            keybind = "UI_SHORTCUT_EXIT",
            callback = function()
                    if self.currentPanel == self.pathSettingsPanel then
                        SCENE_MANAGER:HideCurrentScene()
                    else
                        self:ShowPathSettingsPanel()
                    end
                end,
        },
    }

    self.pathSettingsPanel = ZO_HousingPathSettings_Keyboard:New(ZO_HousingPathSettingsPanel_KeyboardTopLevel, self)

    self.changeObjectPanel = ZO_HousingPathChangeObject_Keyboard:New(ZO_HousingPathChangeObject_KeyboardTopLevel, self)
    self.pathableListDirty = true

    -- placeable and pathable furniture is updated in tandum
    SHARED_FURNITURE:RegisterCallback("PlaceableFurnitureChanged", function()
        if SCENE_MANAGER:IsShowing("keyboard_housing_path_settings_scene") then
            self.changeObjectPanel:UpdateChangeObjectPanel()
        else
            self.pathableListDirty = true
        end
    end)

    HOUSING_EDITOR_HUD_SCENE_GROUP:AddScene("keyboard_housing_path_settings_scene")
    SYSTEMS:RegisterKeyboardObject("path_settings", self)
    SYSTEMS:RegisterKeyboardRootScene("housing_path_settings", KEYBOARD_HOUSING_PATH_SETTINGS_SCENE)
end

function ZO_HousingPathSettingsMenu_Keyboard:OnShowing()
    self.pathSettingsPanel:UpdatePathSettings()
    
    if self.pathableListDirty then
        self.changeObjectPanel:UpdateChangeObjectPanel()
        self.pathableListDirty = false
    end
    self.changeObjectPanel:UpdateSearchText()

    SCENE_MANAGER:AddFragment(self.pathSettingsPanel:GetFragment())
    self.currentPanel = self.pathSettingsPanel
end

function ZO_HousingPathSettingsMenu_Keyboard:SetPathData(furnitureId)
    self.targetFurnitureId = furnitureId
end

function ZO_HousingPathSettingsMenu_Keyboard:ShowChangeObjectPanel()
    SCENE_MANAGER:RemoveFragment(self.pathSettingsPanel:GetFragment())
    SCENE_MANAGER:AddFragment(self.changeObjectPanel:GetFragment())
    self.currentPanel = self.changeObjectPanel
end

function ZO_HousingPathSettingsMenu_Keyboard:ShowPathSettingsPanel()
    SCENE_MANAGER:AddFragment(self.pathSettingsPanel:GetFragment())
    SCENE_MANAGER:RemoveFragment(self.changeObjectPanel:GetFragment())
    self.currentPanel = self.pathSettingsPanel
end

function ZO_HousingPathSettingsMenu_Keyboard:ShowChangeCollectibleTooltip(control)
    InitializeTooltip(InformationTooltip, control, BOTTOMLEFT, 0, -2, TOPLEFT)
    SetTooltipText(InformationTooltip, GetString(SI_HOUSING_PATH_SETTINGS_CHANGE_COLLECTIBLE_TOOLTIP))
end

function ZO_HousingPathSettingsMenu_Keyboard:ShowPathingStateTooltip(control)
    InitializeTooltip(InformationTooltip, control, BOTTOMLEFT, 0, -2, TOPLEFT)
    SetTooltipText(InformationTooltip, GetString(SI_HOUSING_PATH_SETTINGS_PATHING_STATE_TOOLTIP))
end

function ZO_HousingPathSettingsMenu_Keyboard:ShowPathTypeTooltip(control)
    InitializeTooltip(InformationTooltip, control, BOTTOMLEFT, 0, -2, TOPLEFT)
    SetTooltipText(InformationTooltip, GetString(SI_HOUSING_PATH_SETTINGS_PATHING_TYPE_TOOLTIP))
end

function ZO_HousingPathSettingsMenu_Keyboard:ShowConformToGroundTooltip(control)
    InitializeTooltip(InformationTooltip, control, BOTTOMLEFT, 0, -2, TOPLEFT)
    SetTooltipText(InformationTooltip, GetString(SI_HOUSING_PATH_SETTINGS_CONFORM_TO_GROUND_TOOLTIP))
end

-- Path Settings Panel
----------------------
ZO_HousingPathSettings_Keyboard = ZO_HousingBrowserList:Subclass()

function ZO_HousingPathSettings_Keyboard:New(...)
    return ZO_HousingBrowserList.New(self, ...)
end

function ZO_HousingPathSettings_Keyboard:Initialize(...)
    ZO_HousingBrowserList.Initialize(self, ...)

    self.settingsTreeData = ZO_RootFurnitureCategory:New()
        
    for name, topLevelSetting in pairs(ZO_PATH_SETTINGS) do
        local subsettingsTreeData = ZO_FurnitureCategory:New(self.settingsTreeData, name)
        self.settingsTreeData:AddSubcategory(name, subsettingsTreeData)
        for _, i in pairs(topLevelSetting) do
            subsettingsTreeData:AddSubcategory(i, ZO_FurnitureCategory:New(subsettingsTreeData, i))
        end
    end
    self:BuildCategories()

    self:InitializeSettingsPanel()
end

function ZO_HousingPathSettings_Keyboard:InitializeSettingsPanel()
    self.categoryIndexToPanel = {}
    self.generalOptionsPanel = self.contents:GetNamedChild("General")
    self.activePanel = self.generalOptionsPanel

    self.generalOptionsScrollList = self.generalOptionsPanel:GetNamedChild("Settings")
    local generalOptionsScrollChild = GetControl(self.generalOptionsScrollList, "ScrollChild")

    local function OnChangeCollectibleClicked(button)
        KEYBOARD_HOUSING_PATH_SETTINGS:ShowChangeObjectPanel()
    end

    self:SetupTitleText()

    self.changeCollectibleSetting = self.generalOptionsPanel:GetNamedChild("ChangeCollectible")
    self.changeCollectibleSetting:SetParent(generalOptionsScrollChild)
    self.changeCollectibleButton = self.changeCollectibleSetting:GetNamedChild("Button")
    self.changeCollectibleButton:SetHandler("OnClicked", OnChangeCollectibleClicked)
    local changeCollectibleButtonLabel = self.changeCollectibleButton:GetLabelControl()
    changeCollectibleButtonLabel:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)

    self.pathingStateOnButton = self.generalOptionsPanel:GetNamedChild("ChangePathingStateOn")
    local onButtonLabel = self.pathingStateOnButton:GetNamedChild("Label")
    onButtonLabel:SetText(GetString("SI_FURNITUREPATHSTATE", HOUSING_FURNITURE_PATH_STATE_ON))
    self.pathingStateOnButton.pathState = HOUSING_FURNITURE_PATH_STATE_ON

    self.pathingStateOffButton = self.generalOptionsPanel:GetNamedChild("ChangePathingStateOff")
    local offButtonLabel = self.pathingStateOffButton:GetNamedChild("Label")
    offButtonLabel:SetText(GetString("SI_FURNITUREPATHSTATE", HOUSING_FURNITURE_PATH_STATE_OFF))
    self.pathingStateOffButton.pathState = HOUSING_FURNITURE_PATH_STATE_OFF

    self.radioButtonGroup = ZO_RadioButtonGroup:New()
    self.radioButtonGroup:Add(self.pathingStateOnButton)
    self.radioButtonGroup:Add(self.pathingStateOffButton)
    self.radioButtonGroup:SetSelectionChangedCallback(function(radioButtonGroup, newControl, previousControl)
        if newControl.pathState ~= self.currentPathState then
            self.selectedPathState = newControl.pathState
            local result = HousingEditorToggleSelectedFurniturePathState()
            ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, result)
        end
    end)

    self.conformToGroundOnButton = self.generalOptionsPanel:GetNamedChild("ChangeConformToGroundOn")
    local onButtonLabel = self.conformToGroundOnButton:GetNamedChild("Label")
    onButtonLabel:SetText(GetString("SI_FURNITUREPATHSTATE", HOUSING_FURNITURE_PATH_STATE_ON))
    self.conformToGroundOnButton.conformToGround = true

    self.conformToGroundOffButton = self.generalOptionsPanel:GetNamedChild("ChangeConformToGroundOff")
    local offButtonLabel = self.conformToGroundOffButton:GetNamedChild("Label")
    offButtonLabel:SetText(GetString("SI_FURNITUREPATHSTATE", HOUSING_FURNITURE_PATH_STATE_OFF))
    self.conformToGroundOffButton.conformToGround = false

    self.conformToGroundRadioButtonGroup = ZO_RadioButtonGroup:New()
    self.conformToGroundRadioButtonGroup:Add(self.conformToGroundOnButton)
    self.conformToGroundRadioButtonGroup:Add(self.conformToGroundOffButton)
    self.conformToGroundRadioButtonGroup:SetSelectionChangedCallback(function(radioButtonGroup, newControl, previousControl)
        if newControl.conformToGround ~= self.currentConformToGround then
            self.currentConformToGround = newControl.conformToGround
            local result = HousingEditorToggleSelectedFurniturePathConformToGround()
            ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, result)
        end
    end)

    self.changePathingStateDropDown = self.generalOptionsPanel:GetNamedChild("ChangePathTypeDropDown")
    self:BuildPathTypeSettings(self.changePathingStateDropDown)
end

function ZO_HousingPathSettings_Keyboard:SetupTitleText()
    self:SetTitleTextFromData("ChangeCollectibleTitle")
    self:SetTitleTextFromData("ChangePathingStateTitle")
    self:SetTitleTextFromData("ChangeConformToGroundTitle")
    self:SetTitleTextFromData("ChangePathTypeTitle")
end

function ZO_HousingPathSettings_Keyboard:SetTitleTextFromData(labelName)
    local titleControl = self.generalOptionsPanel:GetNamedChild(labelName)
    titleControl:SetText(GetString(titleControl.data.text))
end

function ZO_HousingPathSettings_Keyboard:InitializeKeybindStrip()
    self.keybindStripDescriptor =
    {
    }
end

function ZO_HousingPathSettings_Keyboard:UpdatePathSettings()
    self:UpdateButtonSettings(self.changeCollectibleSetting)
    self.changeCollectibleButton:SetEnabled(true)

    self.currentPathState = HousingEditorGetSelectedFurniturePathState()
    self.currentConformToGround = HousingEditorGetSelectedFurniturePathConformToGround()
    self.selectedPathState = self.currentPathState
    
    local selectedRadioButton = self.currentPathState == HOUSING_FURNITURE_PATH_STATE_ON and self.pathingStateOnButton or self.pathingStateOffButton
    self.radioButtonGroup:SetClickedButton(selectedRadioButton)
    
    local selectedConformToGroundRadioButton = self.currentConformToGround and self.conformToGroundOnButton or self.conformToGroundOffButton
    self.conformToGroundRadioButtonGroup:SetClickedButton(selectedConformToGroundRadioButton)

    self.currentFollowType = HousingEditorGetSelectedFurniturePathFollowType()
    self.selectedFollowType = self.currentFollowType
    self.comboBox:SetSelectedItemText(GetString("SI_PATHFOLLOWTYPE", self.currentFollowType))
end

function ZO_HousingPathSettings_Keyboard:UpdateButtonSettings(control)
    local data = control.data
    local buttonControl = GetControl(control, "Button")
    local nameControl = GetControl(control, "Name")

    local buttonText = GetString(data.buttonText)
    buttonControl:SetText(buttonText)

    local visible = data.visible == nil or data.visible()
    buttonControl:SetHidden(not visible)

    local furnitureName = GetPlacedHousingFurnitureInfo(self.owner.targetFurnitureId)
    local labelText = zo_strformat(SI_HOUSING_FURNITURE_NAME_FORMAT, furnitureName)
    nameControl:SetText(labelText)
end

function ZO_HousingPathSettings_Keyboard:BuildPathTypeSettings(dropDownControl)
    local comboBox = ZO_ComboBox_ObjectFromContainer(dropDownControl)
    self.comboBox = comboBox
    comboBox:SetSortsItems(false)

    local function OnFollowTypeSelected(_, entryText, entry)
        comboBox:SetSelectedItemText(entry.name)
        HousingEditorSetSelectedFurniturePathFollowType(entry.followType)
        self.selectedFollowType = entry.followType
    end

    for i = PATH_FOLLOW_TYPE_ITERATION_BEGIN, PATH_FOLLOW_TYPE_ITERATION_END do
        if i == PATH_FOLLOW_TYPE_ONE_WAY then
            -- skip this for now, it is not supported
        else
            local entry = comboBox:CreateItemEntry(GetString("SI_PATHFOLLOWTYPE", i), OnFollowTypeSelected)
            entry.followType = i
            comboBox:AddItem(entry)
        end
    end
end

function ZO_HousingPathSettings_Keyboard:GetCategoryTreeData()
    return self.settingsTreeData
end

function ZO_HousingPathSettings_Keyboard:OnCategorySelected(data)
    --TODO: update panel from category data selected
end

function ZO_HousingPathSettings_Keyboard:GetCategoryInfo(categoryIndex)
    local normalIcon, pressedIcon, mouseoverIcon
    if categoryIndex == 0 then
        normalIcon = "EsoUI/Art/Housing/Keyboard/path_settings_icon_up.dds"
        pressedIcon = "EsoUI/Art/Housing/Keyboard/path_settings_icon_down.dds"
        mouseoverIcon = "EsoUI/Art/Housing/Keyboard/path_settings_icon_up.dds"
    end

    return GetString("SI_HOUSEPATHSETTINGCATEGORIES", categoryIndex), normalIcon, pressedIcon, mouseoverIcon
end

-- Change Object Panel
-----------------------

ZO_HousingPathChangeObject_Keyboard = ZO_HousingFurnitureList:Subclass()

function ZO_HousingPathChangeObject_Keyboard:New(...)
    return ZO_HousingFurnitureList.New(self, ...)
end

function ZO_HousingPathChangeObject_Keyboard:InitializeKeybindStrip()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_HOUSING_EDITOR_REPLACE_OBJECT),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                self:ReplaceWithCollectible(mostRecentlySelectedData.collectibleId)
            end,
            enabled = function()
                return self:GetMostRecentlySelectedData() ~= nil
            end,
        },
        {
            name = GetString(SI_CRAFTING_EXIT_PREVIEW_MODE),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                self:ClearSelection()
            end,
            visible = function()
                local hasSelection = self:GetMostRecentlySelectedData() ~= nil and IsCurrentlyPreviewing()
                return hasSelection
            end,
        },
    }
end

function ZO_HousingPathChangeObject_Keyboard:ReplaceWithCollectible(collectibleId)
    SCENE_MANAGER:HideCurrentScene()
    HousingEditorRequestModeChange(HOUSING_EDITOR_MODE_SELECTION)
    local result = HousingEditorRequestReplacePathCollectible(self.owner.targetFurnitureId, collectibleId)
    ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, result)
end

function ZO_HousingPathChangeObject_Keyboard:OnSearchTextChanged(editBox)
    SHARED_FURNITURE:SetPlaceableTextFilter(editBox:GetText())
end

function ZO_HousingPathChangeObject_Keyboard:AddListDataTypes()

    local function IsFurnitureCollectibleBlacklisted(collectibleId)
        if collectibleId then
            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
            return collectibleData and collectibleData:IsBlacklisted()
        end
        return false
    end

    self.PathableFurnitureOnMouseClickCallback = function(control, buttonIndex, upInside)
        if buttonIndex == MOUSE_BUTTON_INDEX_LEFT and upInside then
            if control.furnitureObject and IsFurnitureCollectibleBlacklisted(control.furnitureObject.collectibleId) then
                ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, HOUSING_REQUEST_RESULT_BLOCKED_BY_BLACKLISTED_COLLECTIBLE)
            else
                ZO_ScrollList_MouseClick(self:GetList(), control)
            end
        end
    end

    self.PathableFurnitureOnMouseDoubleClickCallback = function(control, buttonIndex)
        if buttonIndex == MOUSE_BUTTON_INDEX_LEFT then
            if control.furnitureObject and IsFurnitureCollectibleBlacklisted(control.furnitureObject.collectibleId) then
                ZO_AlertEvent(EVENT_HOUSING_EDITOR_REQUEST_RESULT, HOUSING_REQUEST_RESULT_BLOCKED_BY_BLACKLISTED_COLLECTIBLE)
            else
                local data = ZO_ScrollList_GetData(control)
                self:ReplaceWithCollectible(data.collectibleId)
            end
        end
    end

    self:AddDataType(ZO_PLACEABLE_HOUSING_DATA_TYPE, "ZO_PlayerFurnitureSlot", ZO_HOUSING_FURNITURE_LIST_ENTRY_HEIGHT, function(...) self:SetupFurnitureRow(...) end, ZO_HousingFurnitureBrowser_Keyboard.OnHideFurnitureRow)
end

function ZO_HousingPathChangeObject_Keyboard:SetupFurnitureRow(control, data)
    ZO_HousingFurnitureBrowser_Keyboard.SetupFurnitureRow(control, data, self.PathableFurnitureOnMouseClickCallback, self.PathableFurnitureOnMouseDoubleClickCallback)
end

function ZO_HousingPathChangeObject_Keyboard:UpdateChangeObjectPanel()
    self:UpdateLists()
end

function ZO_HousingPathChangeObject_Keyboard:UpdateSearchText()
    self.searchEditBox:SetText(SHARED_FURNITURE:GetPlaceableTextFilter())
end

function ZO_HousingPathChangeObject_Keyboard:GetCategoryTreeData()
    return SHARED_FURNITURE:GetPathableFurnitureCategoryTreeData()
end

function ZO_HousingPathChangeObject_Keyboard:GetNoItemText()
    if SHARED_FURNITURE:DoesPlayerHavePathableFurniture() then
        return GetString(SI_HOUSING_FURNITURE_NO_SEARCH_RESULTS)
    else
        return GetString(SI_HOUSING_FURNITURE_NO_PATHABLE_FURNITURE)
    end
end

-- XML Functions
-------------------

function ZO_HousingPathSettings_Keyboard_OnInitialize(control)
    KEYBOARD_HOUSING_PATH_SETTINGS = ZO_HousingPathSettingsMenu_Keyboard:New(control)
end