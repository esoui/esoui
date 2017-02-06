local SETTING_PANEL_GAMEPAD_CATEGORIES_ROOT = -1

ZO_GamepadOptions = ZO_Object.MultiSubclass(ZO_SharedOptions, ZO_Gamepad_ParametricList_Screen)

function ZO_GamepadOptions:New(control)
    local options = ZO_Object.New(self)
    options:Initialize(control)
    return options
end

function ZO_GamepadOptions:Initialize(control) 
    ZO_SharedOptions.Initialize(self, control)
    local DONT_ACTIVATE_ON_SHOW =  false
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, DONT_ACTIVATE_ON_SHOW)
    GAMEPAD_OPTIONS_FRAGMENT = ZO_SimpleSceneFragment:New(control)

    self.isGamepadOptions = true
    self.currentCategory = SETTING_PANEL_GAMEPAD_CATEGORIES_ROOT
end

function ZO_GamepadOptions:InitializeScenes()
    GAMEPAD_OPTIONS_ROOT_SCENE = ZO_Scene:New("gamepad_options_root", SCENE_MANAGER)
    GAMEPAD_OPTIONS_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.currentCategory = SETTING_PANEL_GAMEPAD_CATEGORIES_ROOT
            self:RefreshCategoryList()
            self:RefreshHeader()
            self:SetCurrentList(self.categoryList)

            if(self.inputBlocked) then
                self:SetGamepadOptionsInputBlocked(false)
            end
            KEYBIND_STRIP:AddKeybindButtonGroup(self.rootKeybindDescriptor)
        elseif newState == SCENE_HIDDEN then
            self:DisableCurrentList()

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.rootKeybindDescriptor)
        end
    end)

    GAMEPAD_OPTIONS_PANEL_SCENE = ZO_Scene:New("gamepad_options_panel", SCENE_MANAGER)
    GAMEPAD_OPTIONS_PANEL_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:RefreshOptionsList()
            self:RefreshHeader()
            self:SetCurrentList(self.optionsList)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.panelKeybindDescriptor)
        elseif newState == SCENE_HIDDEN then
            self:DisableCurrentList()
            self:DeactivateSelectedControl()
            self:SaveCachedSettings()
            ZO_SavePlayerConsoleProfile()
            SetCameraOptionsPreviewModeEnabled(false, CAMERA_OPTIONS_PREVIEW_NONE)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.panelKeybindDescriptor)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.primaryActionDescriptor)
        end
    end)
    
    local function OnScreenResize()
        if not self:IsAtRoot() then
            self.optionsList:RefreshVisible()
            self:OnSelectionChanged(self.optionsList)
        end
    end

    local function RegisterForScreenResizeComplete()
        -- make sure to handle both start and end of screen resize (start only matters for resetting to defautlt)
        self.control:RegisterForEvent(EVENT_SCREEN_RESIZED, OnScreenResize)
        self.control:RegisterForEvent(EVENT_ALL_GUI_SCREENS_RESIZED, OnScreenResize)
    end

    local function UnregisterForScreenResizeComplete()
        self.control:UnregisterForEvent(EVENT_SCREEN_RESIZED)
        self.control:UnregisterForEvent(EVENT_ALL_GUI_SCREENS_RESIZED)
    end

    local GAMEPAD_OPTIONS_SCENE_GROUP = ZO_SceneGroup:New("gamepad_options_root", "gamepad_options_panel")
    GAMEPAD_OPTIONS_SCENE_GROUP:RegisterCallback("StateChange", function(oldState, newState)
        ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
        if newState == SCENE_GROUP_SHOWING then
            RefreshSettings()
            RegisterForScreenResizeComplete()
        elseif newState == SCENE_GROUP_HIDDEN then
            UnregisterForScreenResizeComplete()
        end
    end)
end

function ZO_GamepadOptions:PerformUpdate()
    -- Include update functionality here if the screen uses self.dirty to track needing to update
    self.dirty = false
end

function ZO_GamepadOptions:DeactivateSelectedControl()
    local selectedControl = self.optionsList:GetSelectedControl()
    if selectedControl then
        if selectedControl.slider then
            selectedControl.slider:Deactivate()
        elseif selectedControl.horizontalListObject then
            selectedControl.horizontalListObject:Deactivate()
        end
    end
    self.isPrimaryActionActive = false
end

function ZO_GamepadOptions:OnDeferredInitialize()
    self:InitializeHeader()
    self:InitializeOptionsLists()
    self:InitializeKeybindStrip()
    self:InitializeGamepadInfoPanelTable()
    self:RefreshGamepadInfoPanel()
end

function ZO_GamepadOptions:InitializeHeader()
    ZO_GamepadGenericHeader_SetDataLayout(self.header, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_TOGETHER)
    self:RefreshHeader()
end

function ZO_GamepadOptions:RefreshHeader()
    local headerText
    if self:IsAtRoot() then
        headerText = GetString(SI_GAMEPAD_OPTIONS_MENU)
    else
        headerText = GetString("SI_SETTINGSYSTEMPANEL", self.currentCategory)
    end

    local headerData =
    {
        titleText = headerText,
    }
    ZO_GamepadGenericHeader_RefreshData(self.header, headerData)
end

function ZO_GamepadOptions:OnOptionWithDependenciesChanged()
    if SCENE_MANAGER:IsShowing("gamepad_options_panel") then
        self.optionsList:RefreshVisible()
    end
end

function ZO_GamepadOptions:Select()
    local control = self.optionsList:GetSelectedControl()
    local controlType = self:GetControlTypeFromControl(control)

    if controlType == OPTIONS_CHECKBOX then
        ZO_CheckButton_OnClicked(control:GetNamedChild("Checkbox"))
        --When a checkbox is toggled that controls subsettings refreshVisible to show the dependent controls in their disabled state
        --TODO: Call RefreshVisible when Sliders/Horizontal Lists change if ever needed.
        if control.data.gamepadHasEnabledDependencies then
            self:OnOptionWithDependenciesChanged()
        end
    elseif controlType == OPTIONS_INVOKE_CALLBACK then
        ZO_Options_InvokeCallback(control)
    end
end

function ZO_GamepadOptions:InitializeKeybindStrip()
    self.keybindStripDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_OPTIONS_DEFAULTS),
            keybind = "UI_SHORTCUT_SECONDARY",
            visible = function() return self.currentCategory ~= SETTING_PANEL_CINEMATIC end,
            callback = function()
                if not self.inputBlocked then
                    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_OPTIONS_RESET_TO_DEFAULTS")
                end
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() if not self.inputBlocked then SCENE_MANAGER:HideCurrentScene() end end)
    
    self.rootKeybindDescriptor = 
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                if not self.inputBlocked then
                    local data = self.categoryList:GetTargetData()
                    self.currentCategory = data.panelId
                    SCENE_MANAGER:Push("gamepad_options_panel")
                end
            end,
        },
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.rootKeybindDescriptor, self.categoryList)

    self.panelKeybindDescriptor =
    {
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.panelKeybindDescriptor, self.optionsList)

    self.primaryActionDescriptor = 
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = function()
                local control = self.optionsList:GetSelectedControl()
                local controlType = self:GetControlTypeFromControl(control)
                if controlType == OPTIONS_CHECKBOX then
                    return GetString(SI_GAMEPAD_TOGGLE_OPTION)
                else
                    return GetString(SI_GAMEPAD_SELECT_OPTION)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            order = -500,
            callback = function() 
                if not self.inputBlocked then
                    self:Select() 
                end
            end,
        },
    }
end

function ZO_GamepadOptions:HasInfoPanel()
    return OPTIONS_MENU_INFO_PANEL_FRAGMENT ~= nil
end

function ZO_GamepadOptions:IsAtRoot()
    return self.currentCategory == SETTING_PANEL_GAMEPAD_CATEGORIES_ROOT
end

function ZO_GamepadOptions:InitializeGamepadInfoPanelTable()
    if not self:HasInfoPanel() then return end --no infopanel in pregame

    local showXbox = GetGamepadType() ~= GAMEPAD_TYPE_PS4

    local control = self.control:GetNamedChild("InfoPanel")

    control:GetNamedChild("Gamepad"):SetTexture(showXbox and "EsoUI/Art/Buttons/Gamepad/XBox/Console_Art_XB1.dds" or "EsoUI/Art/Buttons/Gamepad/PS4/Console_Art_PS4.dds")
    
    if showXbox then 
        self.keyCodeToLabelGroupControl = 
        {
            [KEY_GAMEPAD_BUTTON_1] = control:GetNamedChild("Right6"),
            [KEY_GAMEPAD_BUTTON_2] = control:GetNamedChild("Right5"),
            [KEY_GAMEPAD_BUTTON_3] = control:GetNamedChild("Right3"),
            [KEY_GAMEPAD_BUTTON_4] = control:GetNamedChild("Right4"),
            [KEY_GAMEPAD_LEFT_TRIGGER] = control:GetNamedChild("Left1"),
            [KEY_GAMEPAD_RIGHT_TRIGGER] = control:GetNamedChild("Right1"),
            [KEY_GAMEPAD_LEFT_SHOULDER] = control:GetNamedChild("Left2"),
            [KEY_GAMEPAD_RIGHT_SHOULDER] = control:GetNamedChild("Right2"),
            [KEY_GAMEPAD_LEFT_STICK] = control:GetNamedChild("Left3"),
            [KEY_GAMEPAD_RIGHT_STICK] = control:GetNamedChild("BottomRight"),
            [KEY_GAMEPAD_DPAD_UP] = control:GetNamedChild("Left4"),
            [KEY_GAMEPAD_DPAD_DOWN] = control:GetNamedChild("Left6"),
            [KEY_GAMEPAD_DPAD_LEFT] = control:GetNamedChild("Left5"),
            [KEY_GAMEPAD_DPAD_RIGHT] = control:GetNamedChild("BottomLeft"),
            [KEY_GAMEPAD_START] = control:GetNamedChild("TopRight"),
            [KEY_GAMEPAD_BACK] = control:GetNamedChild("TopLeft"),
        }
    else
        self.keyCodeToLabelGroupControl = 
        {
            [KEY_GAMEPAD_BUTTON_1] = control:GetNamedChild("Right6"),
            [KEY_GAMEPAD_BUTTON_2] = control:GetNamedChild("Right5"),
            [KEY_GAMEPAD_BUTTON_3] = control:GetNamedChild("Right3"),
            [KEY_GAMEPAD_BUTTON_4] = control:GetNamedChild("Right4"),
            [KEY_GAMEPAD_LEFT_TRIGGER] = control:GetNamedChild("Left1"),
            [KEY_GAMEPAD_RIGHT_TRIGGER] = control:GetNamedChild("Right1"),
            [KEY_GAMEPAD_LEFT_SHOULDER] = control:GetNamedChild("Left2"),
            [KEY_GAMEPAD_RIGHT_SHOULDER] = control:GetNamedChild("Right2"),
            [KEY_GAMEPAD_LEFT_STICK] = control:GetNamedChild("BottomLeft"),
            [KEY_GAMEPAD_RIGHT_STICK] = control:GetNamedChild("BottomRight"),
            [KEY_GAMEPAD_DPAD_UP] = control:GetNamedChild("Left3"),
            [KEY_GAMEPAD_DPAD_DOWN] = control:GetNamedChild("Left5"),
            [KEY_GAMEPAD_DPAD_LEFT] = control:GetNamedChild("Left4"),
            [KEY_GAMEPAD_DPAD_RIGHT] = control:GetNamedChild("Left6"),
            [KEY_GAMEPAD_START] = control:GetNamedChild("TopRight"),
            [KEY_GAMEPAD_TOUCHPAD_PRESSED] = control:GetNamedChild("TopLeft"),
        }
    end
end

function ZO_GamepadOptions_OptionsHorizontalListSetup(control, data, selected, reselectingDuringRebuild, enabled, selectedFromParent)
    if data.parentControl.data.enabled ~= false then
        ZO_GamepadDefaultHorizontalListEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, selectedFromParent)
    end
end

function ZO_GamepadOptions_HorizontalListEqualityFunction(left, right)
    return left.text == right.text
end

local function ReleaseControl(control)
    control.state = nil
end

local function ReleaseSlider(control)
    control.slider:Deactivate()
    ReleaseControl(control)
end

local function ReleaseHorizontalList(control)
    control.horizontalListObject:Deactivate()
    ReleaseControl(control)
end

local GAMEPAD_OPTIONS_HEADER_SELECTED_PADDING = -20

function ZO_GamepadOptions:SetupList(list)
    list:AddDataTemplate("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

function ZO_GamepadOptions:SetupOptionsList(list)
    local function OptionsSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        control.data = data
        self:InitializeControl(control, selected)     
    end

    list:SetHeaderPadding(GAMEPAD_HEADER_DEFAULT_PADDING, GAMEPAD_OPTIONS_HEADER_SELECTED_PADDING)

    list:AddDataTemplate("ZO_GamepadOptionsSliderRow", OptionsSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)    
    list:AddDataTemplateWithHeader("ZO_GamepadOptionsSliderRow", OptionsSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadOptionsHeaderTemplate")
    list:SetDataTemplateReleaseFunction("ZO_GamepadOptionsSliderRow", ReleaseSlider)
    list:SetDataTemplateWithHeaderReleaseFunction("ZO_GamepadOptionsSliderRow", ReleaseSlider)

    list:AddDataTemplate("ZO_GamepadOptionsCheckboxRow", OptionsSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)    
    list:AddDataTemplateWithHeader("ZO_GamepadOptionsCheckboxRow", OptionsSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadOptionsHeaderTemplate")
    list:SetDataTemplateReleaseFunction("ZO_GamepadOptionsCheckboxRow", ReleaseControl)
    list:SetDataTemplateWithHeaderReleaseFunction("ZO_GamepadOptionsCheckboxRow", ReleaseControl)

    list:AddDataTemplate("ZO_GamepadOptionsHorizontalListRow", OptionsSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)    
    list:AddDataTemplateWithHeader("ZO_GamepadOptionsHorizontalListRow", OptionsSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadOptionsHeaderTemplate")
    list:SetDataTemplateReleaseFunction("ZO_GamepadOptionsHorizontalListRow", ReleaseHorizontalList)
    list:SetDataTemplateWithHeaderReleaseFunction("ZO_GamepadOptionsHorizontalListRow", ReleaseHorizontalList)

    list:AddDataTemplate("ZO_GamepadOptionsLabelRow", OptionsSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)    
    list:AddDataTemplateWithHeader("ZO_GamepadOptionsLabelRow", OptionsSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadOptionsHeaderTemplate")
    list:SetDataTemplateReleaseFunction("ZO_GamepadOptionsLabelRow", ReleaseControl)
    list:SetDataTemplateWithHeaderReleaseFunction("ZO_GamepadOptionsLabelRow", ReleaseControl)
end

function ZO_GamepadOptions:InitializeOptionsLists()
    self.categoryList = self:GetMainList()
    self.optionsList = self:AddList("options", function(list) self:SetupOptionsList(list) end)
end

function ZO_GamepadOptions:OnSelectionChanged(list)
    if self:IsAtRoot() then return end

    local control = list:GetSelectedControl()
    if control.data == nil then return end

    local controlType = self:GetControlTypeFromControl(control)
    local enabled = control.data.enabled
    if ((controlType == OPTIONS_CHECKBOX or controlType == OPTIONS_INVOKE_CALLBACK) and enabled ~= false) then
        if not self.isPrimaryActionActive then 
            KEYBIND_STRIP:AddKeybindButtonGroup(self.primaryActionDescriptor)
            self.isPrimaryActionActive = true
        end
    else
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.primaryActionDescriptor)
        self.isPrimaryActionActive = false
    end

    if self:HasInfoPanel() then
        local data = list:GetTargetData()
        local settingId = data.settingId
        local isFirstPersonCameraSetting = settingId == CAMERA_SETTING_FIRST_PERSON_FIELD_OF_VIEW
        local isThirdPersonCameraSetting = settingId == CAMERA_SETTING_THIRD_PERSON_FIELD_OF_VIEW
                                            or settingId == CAMERA_SETTING_THIRD_PERSON_HORIZONTAL_POSITION_MULTIPLIER
                                            or settingId == CAMERA_SETTING_THIRD_PERSON_HORIZONTAL_OFFSET
        if data.system == SETTING_TYPE_CAMERA and (isFirstPersonCameraSetting or isThirdPersonCameraSetting) then
            local option = CAMERA_OPTIONS_PREVIEW_FORCE_FIRST_PERSON
            if isThirdPersonCameraSetting then
                option = CAMERA_OPTIONS_PREVIEW_FORCE_THIRD_PERSON
            end

            SetCameraOptionsPreviewModeEnabled(true, option)

            GAMEPAD_OPTIONS_PANEL_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_OPTIONS)
            GAMEPAD_OPTIONS_PANEL_SCENE:RemoveFragment(OPTIONS_MENU_INFO_PANEL_FRAGMENT)
            GAMEPAD_OPTIONS_PANEL_SCENE:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_4_BACKGROUND_FRAGMENT)
        else
            SetCameraOptionsPreviewModeEnabled(false, CAMERA_OPTIONS_PREVIEW_NONE)

            GAMEPAD_OPTIONS_PANEL_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_OPTIONS)
            GAMEPAD_OPTIONS_PANEL_SCENE:AddFragment(OPTIONS_MENU_INFO_PANEL_FRAGMENT)
            GAMEPAD_OPTIONS_PANEL_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_4_BACKGROUND_FRAGMENT)
        end
    end
end

local function SetSelectedStateOnControl(control, selected)
    control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected))
    local enabled =  control.data.enabled ~= false
    local color
    if not enabled then
        color = selected and ZO_NORMAL_TEXT or ZO_GAMEPAD_DISABLED_UNSELECTED_COLOR
    else
        color = selected and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT
    end

    local r,g,b,a = color:UnpackRGBA()

    local label = GetControl(control, "Name")    
    label:SetColor(r, g, b, 1)
    SetMenuEntryFontFace(label, selected)

    local slider = GetControl(control, "Slider")
    if slider then
        slider:SetColor(r,g,b,a)
        slider:GetNamedChild("Left"):SetColor(r,g,b,a)
        slider:GetNamedChild("Right"):SetColor(r,g,b,a)
        slider:GetNamedChild("Center"):SetColor(r,g,b,a)
    end
    local checkBox = GetControl(control, "Checkbox")
    if checkBox then
        checkBox.selected = selected and enabled
    end

    if control.horizontalListControl then
        control.horizontalListObject:SetSelectedFromParent(selected)
    end
end

local function GetTextEntry(text)
    if type(text) == "string" then
        return text
    else
        return GetString(text)
    end
end

function ZO_GamepadOptions:InitializeControl(control, selected)
    local label = GetControl(control, "Name")
    --determine if this control should be disabled because of a dependency on another control type
    --this is rarely used so enabled == nil or true, only false is disabled
    control.data.enabled = control.data.gamepadIsEnabledCallback and control.data.gamepadIsEnabledCallback()
    SetSelectedStateOnControl(control, selected)

    local IS_GAMEPAD_CONTROL = false
    ZO_SharedOptions.InitializeControl(self, control, selected, IS_GAMEPAD_CONTROL)

    if(not control.data.enabled and control.data.disabledText) then
        label:SetText(GetTextEntry(control.data.disabledText))
    else
        if IsConsoleUI() and control.data.consoleTextOverride then
            label:SetText(GetTextEntry(control.data.consoleTextOverride))
        elseif control.data.gamepadTextOverride then
            label:SetText(GetTextEntry(control.data.gamepadTextOverride))
        end
    end

    ZO_Options_UpdateOption(control)
end

local GAMEPAD_BUTTON_SCALE = .75
local PS4_ADJUST_POV_ICON = "EsoUI/Art/Buttons/Gamepad/PS4/Nav_PS4_DpadDown_Hold_RS.dds"
local XBOX_ADJUST_POV_ICON = "EsoUI/Art/Buttons/Gamepad/XBox/Nav_XBone_DpadDown_Hold_RS.dds"

local function SetupGameCameraZoomLabels(control, isHoldKey, labelToUse, linesUsed)
    local formatString = isHoldKey and SI_BINDING_NAME_GAMEPAD_HOLD_LEFT or SI_BINDING_NAME_GAMEPAD_TAP_LEFT
    local localizedToggleCameraName = zo_strformat(formatString, GetString(SI_BINDING_NAME_GAMEPAD_TOGGLE_FIRST_PERSON))
    control:GetNamedChild("Label" .. labelToUse):SetText(localizedToggleCameraName)
    labelToUse = labelToUse + 1 --use an extra label to show Toggle
    linesUsed = linesUsed + control:GetNamedChild("Label" .. labelToUse):GetNumLines()
    local chordedActionString = control.alignment == RIGHT and SI_BINDING_NAME_GAMEPAD_CHORD_LEFT or SI_BINDING_NAME_GAMEPAD_CHORD_RIGHT --put bind texture on left if right aligned
    local showXbox = GetGamepadType() ~= GAMEPAD_TYPE_PS4
    local povIcon = showXbox and XBOX_ADJUST_POV_ICON or PS4_ADJUST_POV_ICON
    control:GetNamedChild("Label" .. labelToUse):SetText(zo_strformat(GetString(chordedActionString), ZO_Keybinding_GetGamepadActionName("GAME_CAMERA_GAMEPAD_ZOOM"), povIcon))
    return labelToUse, linesUsed
end

local function SetupQuickSlotLabels(control, labelToUse, linesUsed)
    local localizedQuickSlotName = zo_strformat(SI_BINDING_NAME_GAMEPAD_TAP_LEFT, GetString(SI_BINDING_NAME_GAMEPAD_ACTION_BUTTON_9))
    control:GetNamedChild("Label" .. labelToUse):SetText(localizedQuickSlotName)
    labelToUse = labelToUse + 1 --use an extra label to show hold
    linesUsed = linesUsed + control:GetNamedChild("Label" .. labelToUse):GetNumLines()  
    local localizedQuickSlotHoldName = zo_strformat(SI_BINDING_NAME_GAMEPAD_HOLD_LEFT, GetString(SI_BINDING_NAME_GAMEPAD_ASSIGN_QUICKSLOT))
    control:GetNamedChild("Label" .. labelToUse):SetText(localizedQuickSlotHoldName)
    return labelToUse, linesUsed
end

function ZO_GamepadOptions:RefreshGamepadInfoPanel()
    if not self:HasInfoPanel() then return end --no infopanel in pregame

    local generalLayer = GetString(SI_KEYBINDINGS_LAYER_GENERAL)
    local isChordedKeySetupMap = {}

    for key, control in pairs(self.keyCodeToLabelGroupControl) do
        local labelToUse = 1
        local linesUsed = 0
        local actionName = GetActionNameFromKey(generalLayer, key)
        local holdKey = ConvertKeyPressToHold(key)
        local holdActionName = GetActionNameFromKey(generalLayer, holdKey)
        --regular key
        if actionName and actionName ~= "" then
            local localizedActionName = ZO_Keybinding_GetGamepadActionName(actionName)
            if actionName == "GAME_CAMERA_GAMEPAD_ZOOM" then --special keybind that chords a button with a thumbstick direction and also can toggle camera
                local NOT_HOLD_KEY = false
                labelToUse, linesUsed = SetupGameCameraZoomLabels(control, NOT_HOLD_KEY, labelToUse, linesUsed)
            elseif actionName == "ACTION_BUTTON_9" then -- special keybind that handles hold functionality in lua to show a radial menu
                labelToUse, linesUsed = SetupQuickSlotLabels(control, labelToUse, linesUsed)
            else
                localizedActionName = holdActionName and holdActionName ~= "" and zo_strformat(SI_BINDING_NAME_GAMEPAD_TAP_LEFT, localizedActionName) or localizedActionName 
                control:GetNamedChild("Label" .. labelToUse):SetText(localizedActionName)           
            end
            linesUsed = linesUsed + control:GetNamedChild("Label" .. labelToUse):GetNumLines()
            labelToUse = labelToUse + 1
        end

        --hold key
        if holdActionName and holdActionName ~= "" then
            local localizedActionName = ZO_Keybinding_GetGamepadActionName(holdActionName)           
            if holdActionName == "GAME_CAMERA_GAMEPAD_ZOOM" then --special keybind that chords a button with a thumbstick direction
                local HOLD_KEY = true
                labelToUse, linesUsed = SetupGameCameraZoomLabels(control, HOLD_KEY, labelToUse, linesUsed)
            else
                control:GetNamedChild("Label" .. labelToUse):SetText(zo_strformat(SI_BINDING_NAME_GAMEPAD_HOLD_LEFT, localizedActionName))           
            end
            linesUsed = linesUsed + control:GetNamedChild("Label" .. labelToUse):GetNumLines()
            labelToUse = labelToUse + 1
        end

        --chorded keys
        local chordedKeys = {GetKeyChordsFromSingleKey(key)} 
        if chordedKeys then
            for i, chordedKey in ipairs(chordedKeys) do
                actionName = GetActionNameFromKey(generalLayer, chordedKey)
                if actionName and actionName ~= "" then
                    if linesUsed < 4 and not isChordedKeySetupMap[chordedKey] then
                        local icon = self:GetButtonTextureInfoFromActionName(actionName)
                        local localizedActionName = ZO_Keybinding_GetGamepadActionName(actionName)
                        local chordedActionString = control.alignment == RIGHT and SI_BINDING_NAME_GAMEPAD_CHORD_LEFT or SI_BINDING_NAME_GAMEPAD_CHORD_RIGHT --put bind texture on left if right aligned
                        control:GetNamedChild("Label" .. labelToUse):SetText(zo_strformat(GetString(chordedActionString), localizedActionName, icon))
                        
                        local numLines = control:GetNamedChild("Label" .. labelToUse):GetNumLines()
                        if linesUsed == 3 and numLines > 1 then --the last label is using two lines
                             control:GetNamedChild("Label" .. labelToUse):SetText("") --unsetup the label and try on other key
                            isChordedKeySetupMap[chordedKey] = false
                        else
                            labelToUse = labelToUse + 1
                            linesUsed = linesUsed + numLines
                            isChordedKeySetupMap[chordedKey] = true --this chord has been setup, ignore it when check the second key
                        end             
                    elseif isChordedKeySetupMap[chordedKey] == nil then
                        isChordedKeySetupMap[chordedKey] = false --We ran out of space in this group, we'll try again on the chords other key
                    end
                end
            end
        end

        --clean up unused labels
        while labelToUse < 5 do
            control:GetNamedChild("Label" .. labelToUse):SetText("")
            labelToUse = labelToUse + 1
        end
    end

    for key, isSetup in pairs(isChordedKeySetupMap) do
        assert(isSetup) --in case we make a control scheme with enough chords they can't be nicely placed
    end
end

function ZO_GamepadOptions:GetButtonTextureInfoFromActionName(actionName)
    local layerIndex, categoryIndex, actionIndex = GetActionIndicesFromName(actionName)
    for bindingIndex = 1, GetMaxBindingsPerAction() do
        local key, mod1, mod2, mod3, mod4 = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, bindingIndex)
        if key ~= KEY_INVALID then                  
            -- If the key matches the preferred mode then just use it
            if IsKeyCodeGamepadKey(key) then
                local icon, width, height = GetGamepadIconPathForKeyCode(key)
                local isKeyHold = IsKeyCodeHoldKey(key)
                return icon, width, height, isKeyHold
            end
        end
    end
end

function ZO_GamepadOptions_RefreshGamepadInfoPanel()
    GAMEPAD_OPTIONS:RefreshGamepadInfoPanel()
end

function ZO_GamepadOptions_OnInitialize(control)
    GAMEPAD_OPTIONS = ZO_GamepadOptions:New(control)
    SYSTEMS:RegisterGamepadObject("options", GAMEPAD_OPTIONS)
end

local TEMPLATE_NAMES = 
{
    [OPTIONS_HORIZONTAL_SCROLL_LIST] = "ZO_GamepadOptionsHorizontalListRow",
    [OPTIONS_SLIDER] = "ZO_GamepadOptionsSliderRow",
    [OPTIONS_CHECKBOX] = "ZO_GamepadOptionsCheckboxRow",
    [OPTIONS_INVOKE_CALLBACK] = "ZO_GamepadOptionsLabelRow"
}

function ZO_GamepadOptions:RefreshCategoryList()
    self.categoryList:Clear()

    self:AddCategory(SETTING_PANEL_CINEMATIC)
    self:AddCategory(SETTING_PANEL_VIDEO)
    self:AddCategory(SETTING_PANEL_AUDIO)
    self:AddCategory(SETTING_PANEL_GAMEPLAY)
    self:AddCategory(SETTING_PANEL_CAMERA)
    self:AddCategory(SETTING_PANEL_INTERFACE)
    self:AddCategory(SETTING_PANEL_NAMEPLATES)
    self:AddCategory(SETTING_PANEL_SOCIAL)

    self.categoryList:Commit()
end

do
    local CATEGORY_ICONS =
    {
        [SETTING_PANEL_CINEMATIC] = "EsoUI/Art/Options/Gamepad/gp_options_social.dds",
        [SETTING_PANEL_VIDEO] = "EsoUI/Art/Options/Gamepad/gp_options_video.dds",
        [SETTING_PANEL_AUDIO] = "EsoUI/Art/Options/Gamepad/gp_options_audio.dds",
        [SETTING_PANEL_GAMEPLAY] = "EsoUI/Art/Options/Gamepad/gp_options_gameplay.dds",
        [SETTING_PANEL_CAMERA] = "EsoUI/Art/Options/Gamepad/gp_options_camera.dds",
        [SETTING_PANEL_INTERFACE] = "EsoUI/Art/Options/Gamepad/gp_options_interface.dds",
        [SETTING_PANEL_SOCIAL] = "EsoUI/Art/Options/Gamepad/gp_options_social.dds",
        [SETTING_PANEL_NAMEPLATES] = "EsoUI/Art/Options/Gamepad/gp_options_nameplates.dds",
    }

    function ZO_GamepadOptions:AddCategory(panelId)
        local settings = GAMEPAD_SETTINGS_DATA[panelId]
        if settings then
            local entryData = ZO_GamepadEntryData:New(GetString("SI_SETTINGSYSTEMPANEL", panelId), CATEGORY_ICONS[panelId])
            entryData.panelId = panelId
            entryData:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
        end
    end
end

function ZO_GamepadOptions:RefreshOptionsList()
    self.optionsList:Clear()
    
    self:AddSettingGroup(self.currentCategory)

    if self.currentCategory ~= self.lastCategory then
        self.optionsList:CommitWithoutReselect()
    else
        self.optionsList:Commit()
    end
    self.lastCategory = self.currentCategory
end

function ZO_GamepadOptions:AddSettingGroup(panelId)
    local settings = GAMEPAD_SETTINGS_DATA[panelId]
    if settings then
        for i = 1, #settings do
            local setting = settings[i]
            local header = setting.header and GetString(setting.header)
            local data = self:GetSettingsData(setting.panel, setting.system, setting.settingId)
            local controlType = self:GetControlType(data.controlType)
            
            if controlType == OPTIONS_CUSTOM then
                controlType = data.customControlType
            end

            local templateName = TEMPLATE_NAMES[controlType]
            
            local isHeader = header or data.header
            
            if isHeader then 
                templateName = templateName .. "WithHeader"
                if not data.header then 
                    data.header = header 
                end
            end

            self.optionsList:AddEntry(templateName, data)
        end
    end
end

function ZO_GamepadOptions:LoadPanelDefaults(panelSettings)
    for _, setting in ipairs(panelSettings) do
        local data = self:GetSettingsData(setting.panel, setting.system, setting.settingId)
        ZO_SharedOptions.LoadDefaults(self, nil, data)
    end
end

function ZO_GamepadOptions:LoadDefaults()
    if self:IsAtRoot() then
        for panel, settings in pairs(GAMEPAD_SETTINGS_DATA) do
            self:LoadPanelDefaults(settings)
        end
    else
        local settings = GAMEPAD_SETTINGS_DATA[self.currentCategory]
        if settings then
            self:LoadPanelDefaults(settings)
        end
        self:RefreshOptionsList()
    end

    if self.currentCategory == SETTING_PANEL_VIDEO or self:IsAtRoot() then
        -- reset the screen adjustments
        SetOverscanOffsets(0, 0, 0, 0)
    end

    ZO_SavePlayerConsoleProfile()
    self:SaveCachedSettings()

    self:RefreshGamepadInfoPanel()
end

function ZO_GamepadOptions:SetGamepadOptionsInputBlocked(blocked)
    self.inputBlocked = blocked
end
