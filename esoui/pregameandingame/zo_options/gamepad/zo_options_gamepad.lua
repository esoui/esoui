ZO_GAMEPAD_OPTIONS_CATEGORY_SORT_ORDER =
{
    [SETTING_PANEL_CINEMATIC] = 0,
    [SETTING_PANEL_VIDEO] = 10,
    [SETTING_PANEL_AUDIO] = 20,
    [SETTING_PANEL_GAMEPLAY] = 30,
    [SETTING_PANEL_CAMERA] = 40,
    [SETTING_PANEL_INTERFACE] = 50,
    [SETTING_PANEL_NAMEPLATES] = 60,
    [SETTING_PANEL_SOCIAL] = 70,
    [SETTING_PANEL_COMBAT] = 80,
    [SETTING_PANEL_ACCESSIBILITY] = 90,
    [SETTING_PANEL_ACCOUNT] = 100,
}

local SETTING_PANEL_GAMEPAD_CATEGORIES_ROOT = -1

ZO_GamepadOptions = ZO_Object.MultiSubclass(ZO_SharedOptions, ZO_Gamepad_ParametricList_Screen)

function ZO_GamepadOptions:Initialize(control)
    ZO_SharedOptions.Initialize(self)
    local DONT_ACTIVATE_ON_SHOW = false
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, DONT_ACTIVATE_ON_SHOW)
    GAMEPAD_OPTIONS_FRAGMENT = ZO_SimpleSceneFragment:New(control)

    self.isGamepadOptions = true
    self.currentCategory = SETTING_PANEL_GAMEPAD_CATEGORIES_ROOT
    self.settingsNeedApply = false

    self.customCategories = {}

    local function OnDeferredSettingRequestCompleted(eventId, system, settingId, success, result)
        if GAMEPAD_OPTIONS_FRAGMENT:IsShowing() and not self:AreDeferredSettingsForPanelLoading(self.currentCategory) then
            ZO_Dialogs_ReleaseAllDialogsOfName("REQUESTING_ACCOUNT_DATA")
            if system == SETTING_TYPE_ACCOUNT and settingId == ACCOUNT_SETTING_ACCOUNT_EMAIL and result == ACCOUNT_EMAIL_REQUEST_RESULT_SUCCESS_EMAIL_UPDATED then
                ZO_Dialogs_ShowPlatformDialog("ACCOUNT_MANAGEMENT_EMAIL_CHANGED")
            end
            self:RefreshOptionsList()
        end
    end

    control:RegisterForEvent(EVENT_DEFERRED_SETTING_REQUEST_COMPLETED, OnDeferredSettingRequestCompleted)
    control:RegisterForEvent(EVENT_MOST_RECENT_GAMEPAD_TYPE_CHANGED, function() self:RefreshGamepadInfoPanel() end)
    control:RegisterForEvent(EVENT_KEYBINDINGS_LOADED, function() self:RefreshGamepadInfoPanel() end)
end

function ZO_GamepadOptions:InitializeScenes()
    GAMEPAD_OPTIONS_ROOT_SCENE = ZO_Scene:New("gamepad_options_root", SCENE_MANAGER)
    GAMEPAD_OPTIONS_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.currentCategory = SETTING_PANEL_GAMEPAD_CATEGORIES_ROOT
            self:RefreshCategoryList()
            self:RefreshHeader()
            self:SetCurrentList(self.categoryList)
            self:RefreshGamepadInfoPanel()

            KEYBIND_STRIP:AddKeybindButtonGroup(self.rootKeybindDescriptor)
        elseif newState == SCENE_HIDDEN then
            self:DisableCurrentList()

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.rootKeybindDescriptor)
        end
    end)

    GAMEPAD_OPTIONS_PANEL_SCENE = ZO_Scene:New("gamepad_options_panel", SCENE_MANAGER)
    GAMEPAD_OPTIONS_PANEL_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            RefreshSettings()
            self.settingsNeedApply = false
            if ZO_SharedOptions.DoesPanelDisableShareFeatures(self.currentCategory) and DoesPlatformSupportDisablingShareFeatures() then
                DisableShareFeatures()
            end
            local isDeferredLoading = self:RequestLoadDeferredSettingsForPanel(self.currentCategory)
            if isDeferredLoading then
                ZO_Dialogs_ShowGamepadDialog("REQUESTING_ACCOUNT_DATA")
            end
            self:RefreshOptionsList()
            self:RefreshHeader()
            self:SetCurrentList(self.optionsList)
            if IsInUI("pregame") and not IsAccountLoggedIn() then
                GAMEPAD_OPTIONS_PANEL_SCENE:AddTemporaryFragment(PREGAME_ANIMATED_BACKGROUND_FRAGMENT)
            end
            KEYBIND_STRIP:AddKeybindButtonGroup(self.panelKeybindDescriptor)
        elseif newState == SCENE_HIDDEN then
            if ZO_SharedOptions.DoesPanelDisableShareFeatures(self.currentCategory) and DoesPlatformSupportDisablingShareFeatures() then
                EnableShareFeatures()
            end
            self:DisableCurrentList()
            self:DeactivateSelectedControl()
            self:SaveCachedSettings()
            ZO_SavePlayerConsoleProfile()
            SetCameraOptionsPreviewModeEnabled(false, CAMERA_OPTIONS_PREVIEW_NONE)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.panelKeybindDescriptor)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.primaryActionDescriptor)
        end
    end)

    local GAMEPAD_OPTIONS_SCENE_GROUP = ZO_SceneGroup:New("gamepad_options_root", "gamepad_options_panel")
    self:SetSceneGroup(GAMEPAD_OPTIONS_SCENE_GROUP)
end

function ZO_GamepadOptions:OnStateChanged(oldState, newState)
    ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
    if newState == SCENE_GROUP_SHOWING then
        RefreshSettings()
        -- make sure to handle both start and end of screen resize (start only matters for resetting to defautlt)
        self.control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:RefreshOptionsList() end)
        self.control:RegisterForEvent(EVENT_ALL_GUI_SCREENS_RESIZED, function() self:RefreshOptionsList() end)
    elseif newState == SCENE_GROUP_HIDDEN then
        self.control:UnregisterForEvent(EVENT_SCREEN_RESIZED)
        self.control:UnregisterForEvent(EVENT_ALL_GUI_SCREENS_RESIZED)
    end
end

function ZO_GamepadOptions:RefreshOptionsList()
    if not self:IsAtRoot() then
        self.optionsList:RefreshVisible()
        self:OnSelectionChanged(self.optionsList)
    end
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
    self:InitializeGamepadInfoPanel()
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

    self.headerData =
    {
        titleText = headerText,
    }
    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)
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
    elseif controlType == OPTIONS_COLOR then
        ZO_Options_ColorOnClicked(control)
    elseif controlType == OPTIONS_CHAT_COLOR then
        ZO_Options_Social_ChatColorOnClicked(control)
    end
end

do
    local categoriesWithoutDefaults =
    {
        [SETTING_PANEL_CINEMATIC] = true,
        [SETTING_PANEL_ACCOUNT] = true,
    }

    function ZO_GamepadOptions:InitializeKeybindStrip()
        self.keybindStripDescriptor =
        {
            {
                alignment = KEYBIND_STRIP_ALIGN_LEFT,
                name = GetString(SI_OPTIONS_DEFAULTS),
                keybind = "UI_SHORTCUT_SECONDARY",
                visible = function() return not categoriesWithoutDefaults[self.currentCategory] end,
                callback = function()
                    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_OPTIONS_RESET_TO_DEFAULTS")
                end,
            },
            {
                alignment = KEYBIND_STRIP_ALIGN_LEFT,
                name = GetString(SI_APPLY),
                keybind = "UI_SHORTCUT_TERTIARY",
                visible = function() return not self:IsAtRoot() and self.settingsNeedApply end,
                callback = function()
                    self:ApplySettings()
                end,
            },
        }

        local function BackCallback()
            if self.overrideBackCallback then
                self.overrideBackCallback()
            else
                if IsInUI("pregame") and not IsAccountLoggedIn() then
                    GAMEPAD_OPTIONS_ROOT_SCENE:AddTemporaryFragment(PREGAME_ANIMATED_BACKGROUND_FRAGMENT)
                end
                SCENE_MANAGER:HideCurrentScene()
            end
        end

        local function BackName()
            if self.overrideBackName then
                return self.overrideBackName
            end

            return GetString(SI_GAMEPAD_BACK_OPTION)
        end

        ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, BackCallback, BackName)
    
        self.rootKeybindDescriptor = 
        {
            {
                alignment = KEYBIND_STRIP_ALIGN_LEFT,
                name = GetString(SI_GAMEPAD_SELECT_OPTION),
                keybind = "UI_SHORTCUT_PRIMARY",
                callback = function()
                    local data = self.categoryList:GetTargetData()
                    if data.isCustomCategory then
                        data.callback()
                    else
                        self.currentCategory = data.panelId
                        if IsInUI("pregame") and not IsAccountLoggedIn() and PregameStateManager_GetCurrentState() ~= "FirstTimeAccessibilitySettings" then
                            GAMEPAD_OPTIONS_PANEL_SCENE:AddTemporaryFragment(PREGAME_ANIMATED_BACKGROUND_FRAGMENT)
                        end
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
                    if control and self:GetControlTypeFromControl(control) == OPTIONS_CHECKBOX then
                        return GetString(SI_GAMEPAD_TOGGLE_OPTION)
                    else
                        return GetString(SI_GAMEPAD_SELECT_OPTION)
                    end
                end,
                keybind = "UI_SHORTCUT_PRIMARY",
                order = -500,
                callback = function()
                    self:Select()
                end,
            },
        }
    end
end

function ZO_GamepadOptions:SetCategory(category)
    self.currentCategory = category
end

function ZO_GamepadOptions:HasInfoPanel()
    return OPTIONS_MENU_INFO_PANEL_FRAGMENT ~= nil
end

function ZO_GamepadOptions:IsAtRoot()
    return self.currentCategory == SETTING_PANEL_GAMEPAD_CATEGORIES_ROOT
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

    list:AddDataTemplate("ZO_GamepadOptionsColorRow", OptionsSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadOptionsColorRow", OptionsSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadOptionsHeaderTemplate")
    list:SetDataTemplateReleaseFunction("ZO_GamepadOptionsColorRow", ReleaseControl)
    list:SetDataTemplateWithHeaderReleaseFunction("ZO_GamepadOptionsColorRow", ReleaseControl)
end

function ZO_GamepadOptions:InitializeOptionsLists()
    self.categoryList = self:GetMainList()
    self.categoryList:SetSortFunction(function(entry1, entry2)
        if entry1.sortOrder ~= entry2.sortOrder then
            return entry1.sortOrder < entry2.sortOrder
        end

        return entry1:GetText() < entry2:GetText()
    end)
    self.optionsList = self:AddList("options", function(list) self:SetupOptionsList(list) end)
    self.optionsLoadingControl = self.control:GetNamedChild("LoadingContainer")
end

do
    local CONTROL_TYPES_WITH_PRIMARY_ACTION =
    {
        [OPTIONS_CHECKBOX] = true,
        [OPTIONS_INVOKE_CALLBACK] = true,
        [OPTIONS_COLOR] = true,
        [OPTIONS_CHAT_COLOR] = true,
    }

    function ZO_GamepadOptions:OnSelectionChanged(list)
        if self:IsAtRoot() then
            return
        end

        local control = list:GetSelectedControl()
        if control == nil or control.data == nil then
            return
        end

        local controlType = self:GetControlTypeFromControl(control)
        local enabled = control.data.enabled
        if CONTROL_TYPES_WITH_PRIMARY_ACTION[controlType] and enabled ~= false then
            if not self.isPrimaryActionActive then 
                KEYBIND_STRIP:AddKeybindButtonGroup(self.primaryActionDescriptor)
                self.isPrimaryActionActive = true
            else
                --Update incase its name changed based on it being a different control type
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.primaryActionDescriptor)
            end
        else
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.primaryActionDescriptor)
            self.isPrimaryActionActive = false
        end

        local data = list:GetTargetData()
        local settingId = data.settingId
        
        --Controller Info Panel
        local showingInfoPanel = self:HasInfoPanel() and data.gamepadShowsControllerInfo
        if showingInfoPanel then
            GAMEPAD_OPTIONS_PANEL_SCENE:AddFragment(OPTIONS_MENU_INFO_PANEL_FRAGMENT)
            GAMEPAD_OPTIONS_PANEL_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_4_BACKGROUND_FRAGMENT)
        else
            GAMEPAD_OPTIONS_PANEL_SCENE:RemoveFragment(OPTIONS_MENU_INFO_PANEL_FRAGMENT)
            GAMEPAD_OPTIONS_PANEL_SCENE:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_4_BACKGROUND_FRAGMENT)
        end

        --Camera Options (Enables the camera matching the option so you can test it)
        local isFirstPersonCameraSetting = settingId == CAMERA_SETTING_FIRST_PERSON_FIELD_OF_VIEW
                                            or settingId == CAMERA_SETTING_FIRST_PERSON_HEAD_BOB
        local isThirdPersonCameraSetting = settingId == CAMERA_SETTING_THIRD_PERSON_FIELD_OF_VIEW
                                            or settingId == CAMERA_SETTING_THIRD_PERSON_HORIZONTAL_POSITION_MULTIPLIER
                                            or settingId == CAMERA_SETTING_THIRD_PERSON_HORIZONTAL_OFFSET
        local showingCameraPreview = data.system == SETTING_TYPE_CAMERA and (isFirstPersonCameraSetting or isThirdPersonCameraSetting)

        if showingCameraPreview then
            local option = CAMERA_OPTIONS_PREVIEW_FORCE_FIRST_PERSON
            if isThirdPersonCameraSetting then
                option = CAMERA_OPTIONS_PREVIEW_FORCE_THIRD_PERSON
            end

            SetCameraOptionsPreviewModeEnabled(true, option)
            -- pregame does not have FRAGMENT_GROUP so make sure it exists before trying this
            if FRAGMENT_GROUP then
                GAMEPAD_OPTIONS_PANEL_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_OPTIONS)
            end
        else
            SetCameraOptionsPreviewModeEnabled(false, CAMERA_OPTIONS_PREVIEW_NONE)
            -- pregame does not have FRAGMENT_GROUP so make sure it exists before trying this
            if FRAGMENT_GROUP then
                GAMEPAD_OPTIONS_PANEL_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_OPTIONS)
            end
        end

        --Tooltip (only shown if there is tooltip text and the controller info isn't shown and we aren't adjusting a camera setting)
        if not showingInfoPanel and not showingCameraPreview and (data.tooltipText or data.gamepadCustomTooltipFunction) then
            local tooltipText
            if type(data.tooltipText) == "number" then
                tooltipText = GetString(data.tooltipText)
            elseif type(data.tooltipText) == "function" then
                tooltipText = data.tooltipText()
            else
                tooltipText = data.tooltipText
            end

            if data.gamepadCustomTooltipFunction then
                data.gamepadCustomTooltipFunction(GAMEPAD_LEFT_TOOLTIP, data.tooltipText)
            else
                local warningText = nil
                if data.mustRestartToApply then
                    warningText = GetString(SI_OPTIONS_RESTART_WARNING)
                elseif data.mustPushApply then
                    warningText = GetString(SI_OPTIONS_APPLY_WARNING)
                end

                GAMEPAD_TOOLTIPS:LayoutSettingTooltip(GAMEPAD_LEFT_TOOLTIP, tooltipText, warningText)
            end
        else
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
        end
    end
end

local function SetSelectedStateOnControl(control, selected)
    control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected))
    local enabled = control.data.enabled ~= false

    local color = ZO_GamepadMenuEntryTemplate_GetLabelColor(selected, not enabled)
    local r, g, b, a = color:UnpackRGBA()

    local label = control:GetNamedChild("Name")
    label:SetColor(r, g, b, 1)
    SetMenuEntryFontFace(label, selected)

    local slider = control:GetNamedChild("Slider")
    if slider then
        slider:SetColor(r,g,b,a)
        slider:GetNamedChild("Left"):SetColor(r,g,b,a)
        slider:GetNamedChild("Right"):SetColor(r,g,b,a)
        slider:GetNamedChild("Center"):SetColor(r,g,b,a)
    end
    local checkBox = control:GetNamedChild("Checkbox")
    if checkBox then
        checkBox.selected = selected and enabled
    end

    if control.horizontalListControl then
        control.horizontalListObject:SetSelectedFromParent(selected)
    end
end

function ZO_GamepadOptions:InitializeControl(control, selected)
    local label = control:GetNamedChild("Name")

    control.data.enabled = true
    -- Determine if this control should be disabled because of a dependency
    if control.data.gamepadIsEnabledCallback then
        control.data.enabled = control.data.gamepadIsEnabledCallback()
    end
    SetSelectedStateOnControl(control, selected)

    local IS_GAMEPAD_CONTROL = false
    ZO_SharedOptions.InitializeControl(self, control, selected, IS_GAMEPAD_CONTROL)

    if not control.data.enabled and control.data.disabledText then
        label:SetText(self:GetTextEntry(control.data.disabledText, control))
    else
        if IsConsoleUI() and control.data.consoleTextOverride then
            label:SetText(self:GetTextEntry(control.data.consoleTextOverride, control))
        elseif control.data.gamepadTextOverride then
            label:SetText(self:GetTextEntry(control.data.gamepadTextOverride, control))
        end
    end

    ZO_Options_UpdateOption(control)
end

local function SetupGameCameraZoomLabels(control, isHoldKey, labelToUse, linesUsed)
    local formatString = isHoldKey and SI_BINDING_NAME_GAMEPAD_HOLD_LEFT or SI_BINDING_NAME_GAMEPAD_TAP_LEFT
    local localizedToggleCameraName = zo_strformat(formatString, GetString(SI_BINDING_NAME_GAMEPAD_TOGGLE_FIRST_PERSON))
    control:GetNamedChild("Label" .. labelToUse):SetText(localizedToggleCameraName)
    labelToUse = labelToUse + 1 --use an extra label to show Toggle
    linesUsed = linesUsed + control:GetNamedChild("Label" .. labelToUse):GetNumLines()
    local chordedActionString = control.alignment == RIGHT and SI_BINDING_NAME_GAMEPAD_CHORD_LEFT or SI_BINDING_NAME_GAMEPAD_CHORD_RIGHT --put bind texture on left if right aligned
    control:GetNamedChild("Label" .. labelToUse):SetText(zo_strformat(GetString(chordedActionString), ZO_Keybinding_GetGamepadActionName("GAME_CAMERA_GAMEPAD_ZOOM"), zo_iconFormat(GetGamepadBothDpadDownAndRightStickScrollIcon(), 80, 40)))
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

function ZO_GamepadOptions:InitializeGamepadInfoPanel()
    if not self:HasInfoPanel() then return end --no infopanel in pregame

    self:RefreshGamepadInfoPanel()
end

do
    internalassert(GAMEPAD_TYPE_MAX_VALUE == 7, "Make sure every gamepad type is properly handled in ZO_GamepadOptions:RefreshGamepadInfoPanel()")
    local GAMEPAD_TYPE_HAS_SOUTHERN_LEFT_STICK = ZO_CreateSetFromArguments(GAMEPAD_TYPE_PS4, GAMEPAD_TYPE_PS4_NO_TOUCHPAD, GAMEPAD_TYPE_PS5, GAMEPAD_TYPE_STADIA, GAMEPAD_TYPE_SWITCH)
    local GAMEPAD_TYPE_HAS_SWAPPED_FACE_BUTTONS = ZO_CreateSetFromArguments(GAMEPAD_TYPE_SWITCH)
    function ZO_GamepadOptions:RefreshGamepadInfoPanel()
        if not self:HasInfoPanel() then
            --no infopanel in pregame
            return
        end

        local control = self.control:GetNamedChild("InfoPanel")

        control:GetNamedChild("Gamepad"):SetTexture(GetGamepadVisualReferenceArt())

        local backKeyCode
        if ZO_IsPlaystationPlatform() then
            backKeyCode = KEY_GAMEPAD_TOUCHPAD_PRESSED
        else
            backKeyCode = KEY_GAMEPAD_BACK
        end
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
            [backKeyCode] = control:GetNamedChild("TopLeft"),
        }

        local mostRecentGamepadType = GetMostRecentGamepadType()
        if GAMEPAD_TYPE_HAS_SOUTHERN_LEFT_STICK[mostRecentGamepadType] then
            -- swap dpad and left stick
            self.keyCodeToLabelGroupControl[KEY_GAMEPAD_LEFT_STICK] = control:GetNamedChild("BottomLeft")
            self.keyCodeToLabelGroupControl[KEY_GAMEPAD_DPAD_UP] = control:GetNamedChild("Left3")
            self.keyCodeToLabelGroupControl[KEY_GAMEPAD_DPAD_DOWN] = control:GetNamedChild("Left5")
            self.keyCodeToLabelGroupControl[KEY_GAMEPAD_DPAD_LEFT] = control:GetNamedChild("Left4")
            self.keyCodeToLabelGroupControl[KEY_GAMEPAD_DPAD_RIGHT] = control:GetNamedChild("Left6")
        end

        if GAMEPAD_TYPE_HAS_SWAPPED_FACE_BUTTONS[mostRecentGamepadType] then
            -- swap a/b, x/y
            self.keyCodeToLabelGroupControl[KEY_GAMEPAD_BUTTON_1] = control:GetNamedChild("Right5")
            self.keyCodeToLabelGroupControl[KEY_GAMEPAD_BUTTON_2] = control:GetNamedChild("Right6")
            self.keyCodeToLabelGroupControl[KEY_GAMEPAD_BUTTON_3] = control:GetNamedChild("Right4")
            self.keyCodeToLabelGroupControl[KEY_GAMEPAD_BUTTON_4] = control:GetNamedChild("Right3")
        end

        local generalLayer = GetString(SI_KEYBINDINGS_LAYER_GENERAL)
        local isChordedKeySetupMap = {}

        for key, labelGroupControl in pairs(self.keyCodeToLabelGroupControl) do
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
                    labelToUse, linesUsed = SetupGameCameraZoomLabels(labelGroupControl, NOT_HOLD_KEY, labelToUse, linesUsed)
                elseif actionName == "ACTION_BUTTON_9" then -- special keybind that handles hold functionality in lua to show a radial menu
                    labelToUse, linesUsed = SetupQuickSlotLabels(labelGroupControl, labelToUse, linesUsed)
                else
                    localizedActionName = holdActionName and holdActionName ~= "" and zo_strformat(SI_BINDING_NAME_GAMEPAD_TAP_LEFT, localizedActionName) or localizedActionName 
                    labelGroupControl:GetNamedChild("Label" .. labelToUse):SetText(localizedActionName)           
                end
                linesUsed = linesUsed + labelGroupControl:GetNamedChild("Label" .. labelToUse):GetNumLines()
                labelToUse = labelToUse + 1
            end

            --hold key
            if holdActionName and holdActionName ~= "" then
                local localizedActionName = ZO_Keybinding_GetGamepadActionName(holdActionName)           
                if holdActionName == "GAME_CAMERA_GAMEPAD_ZOOM" then --special keybind that chords a button with a thumbstick direction
                    local HOLD_KEY = true
                    labelToUse, linesUsed = SetupGameCameraZoomLabels(labelGroupControl, HOLD_KEY, labelToUse, linesUsed)
                else
                    labelGroupControl:GetNamedChild("Label" .. labelToUse):SetText(zo_strformat(SI_BINDING_NAME_GAMEPAD_HOLD_LEFT, localizedActionName))           
                end
                linesUsed = linesUsed + labelGroupControl:GetNamedChild("Label" .. labelToUse):GetNumLines()
                labelToUse = labelToUse + 1
            end

            --chorded keys
            local chordedKeys = {GetKeyChordsFromSingleKey(key)} 
            if chordedKeys then
                for i, chordedKey in ipairs(chordedKeys) do
                    actionName = GetActionNameFromKey(generalLayer, chordedKey)
                    if actionName and actionName ~= "" then
                        if linesUsed < 4 and not isChordedKeySetupMap[chordedKey] then
                            local buttonMarkup = self:GetButtonMarkupFromActionName(actionName)
                            local localizedActionName = ZO_Keybinding_GetGamepadActionName(actionName)
                            local chordedActionString = labelGroupControl.alignment == RIGHT and SI_BINDING_NAME_GAMEPAD_CHORD_LEFT or SI_BINDING_NAME_GAMEPAD_CHORD_RIGHT --put bind texture on left if right aligned
                            labelGroupControl:GetNamedChild("Label" .. labelToUse):SetText(zo_strformat(GetString(chordedActionString), localizedActionName, buttonMarkup))
                            
                            local numLines = labelGroupControl:GetNamedChild("Label" .. labelToUse):GetNumLines()
                            if linesUsed == 3 and numLines > 1 then --the last label is using two lines
                                labelGroupControl:GetNamedChild("Label" .. labelToUse):SetText("") --unsetup the label and try on other key
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
                labelGroupControl:GetNamedChild("Label" .. labelToUse):SetText("")
                labelToUse = labelToUse + 1
            end
        end

        for key, isSetup in pairs(isChordedKeySetupMap) do
            assert(isSetup) --in case we make a control scheme with enough chords they can't be nicely placed
        end
    end
end

function ZO_GamepadOptions:GetButtonMarkupFromActionName(actionName)
    local layerIndex, categoryIndex, actionIndex = GetActionIndicesFromName(actionName)
    for bindingIndex = 1, GetMaxBindingsPerAction() do
        local key = GetActionBindingInfo(layerIndex, categoryIndex, actionIndex, bindingIndex)
        if key ~= KEY_INVALID then
            -- If the key matches the preferred mode then just use it
            if IsKeyCodeGamepadKey(key) then
                return ZO_Keybindings_GenerateIconKeyMarkup(key)
            end
        end
    end
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
    [OPTIONS_INVOKE_CALLBACK] = "ZO_GamepadOptionsLabelRow",
    [OPTIONS_COLOR] = "ZO_GamepadOptionsColorRow",
    [OPTIONS_CHAT_COLOR] = "ZO_GamepadOptionsColorRow",
}

-- Function to add a ZO_GamepadEntryData to the list of settings categories
-- the entry data should have these fields:
--   sortOrder - a number used to sort the categories
--   callback - a function called when the primary keybind is pressed on the category
function ZO_GamepadOptions:RegisterCustomCategory(entryData)
    entryData.isCustomCategory = true
    table.insert(self.customCategories, entryData)
end

function ZO_GamepadOptions:RefreshCategoryList()
    self.categoryList:Clear()

    self:AddCategory(SETTING_PANEL_VIDEO)
    self:AddCategory(SETTING_PANEL_AUDIO)
    self:AddCategory(SETTING_PANEL_CINEMATIC)
    self:AddCategory(SETTING_PANEL_GAMEPLAY)
    self:AddCategory(SETTING_PANEL_CAMERA)
    self:AddCategory(SETTING_PANEL_INTERFACE)
    self:AddCategory(SETTING_PANEL_NAMEPLATES)
    self:AddCategory(SETTING_PANEL_SOCIAL)
    self:AddCategory(SETTING_PANEL_COMBAT)
    self:AddCategory(SETTING_PANEL_ACCESSIBILITY)

    if ZO_OptionsPanel_IsAccountManagementAvailable() then
        self:AddCategory(SETTING_PANEL_ACCOUNT)
    end

    for _, customCategoryEntryData in ipairs(self.customCategories) do
        local visible = true
        if customCategoryEntryData.visible ~= nil then
            visible = customCategoryEntryData.visible()
        end

        if visible then
            self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", customCategoryEntryData)
        end
    end

    self.categoryList:Commit()
end

function ZO_GamepadOptions:SetSettingPanelFilter(filterFunction)
    self.settingPanelFilter = filterFunction
end

do
    local CATEGORY_ICONS =
    {
        [SETTING_PANEL_CINEMATIC] = "EsoUI/Art/Options/Gamepad/gp_options_social.dds",
        [SETTING_PANEL_ACCESSIBILITY] = "EsoUI/Art/Options/Gamepad/gp_options_accessibility.dds",
        [SETTING_PANEL_VIDEO] = "EsoUI/Art/Options/Gamepad/gp_options_video.dds",
        [SETTING_PANEL_AUDIO] = "EsoUI/Art/Options/Gamepad/gp_options_audio.dds",
        [SETTING_PANEL_GAMEPLAY] = "EsoUI/Art/Options/Gamepad/gp_options_gameplay.dds",
        [SETTING_PANEL_CAMERA] = "EsoUI/Art/Options/Gamepad/gp_options_camera.dds",
        [SETTING_PANEL_INTERFACE] = "EsoUI/Art/Options/Gamepad/gp_options_interface.dds",
        [SETTING_PANEL_SOCIAL] = "EsoUI/Art/Options/Gamepad/gp_options_social.dds",
        [SETTING_PANEL_NAMEPLATES] = "EsoUI/Art/Options/Gamepad/gp_options_nameplates.dds",
        [SETTING_PANEL_COMBAT] = "EsoUI/Art/Options/Gamepad/gp_options_combat.dds",
        [SETTING_PANEL_ACCOUNT] = "EsoUI/Art/Options/Gamepad/gp_options_account.dds",
    }

    function ZO_GamepadOptions:AddCategory(panelId)
        if self.settingPanelFilter and not self.settingPanelFilter(panelId) then
            return
        end

        local settings = GAMEPAD_SETTINGS_DATA[panelId]
        if settings then
            local entryData = ZO_GamepadEntryData:New(GetString("SI_SETTINGSYSTEMPANEL", panelId), CATEGORY_ICONS[panelId])
            entryData.panelId = panelId
            entryData.sortOrder = ZO_GAMEPAD_OPTIONS_CATEGORY_SORT_ORDER[panelId]
            entryData:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
        end
    end
end

function ShouldShowSettingPanel(panelId)
    if panelId == SETTING_PANEL_CINEMATIC
      or panelId == SETTING_PANEL_CAMERA
      or panelId == SETTING_PANEL_ACCOUNT then
        return IsAccountLoggedIn()
    end

    return true
end

function ZO_GamepadOptions:PanelRequiresDeferredLoading(panelId)
    local settings = GAMEPAD_SETTINGS_DATA[panelId]
    if settings then
        for i, setting in ipairs(settings) do
            if IsSettingDeferred(setting.system, setting.settingId) then
                return true
            end
        end
    end

    return false
end

function ZO_GamepadOptions:AreDeferredSettingsForPanelLoading(panelId)
    local settings = GAMEPAD_SETTINGS_DATA[panelId]
    if settings then
        for i, setting in ipairs(settings) do
            if IsSettingDeferred(setting.system, setting.settingId) and IsDeferredSettingLoading(setting.system, setting.settingId) then
                return true
            end
        end
    end

    return false
end

function ZO_GamepadOptions:AreDeferredSettingsForPanelLoaded(panelId)
    local settings = GAMEPAD_SETTINGS_DATA[panelId]
    if settings then
        for i, setting in ipairs(settings) do
            if IsSettingDeferred(setting.system, setting.settingId) and IsDeferredSettingLoaded(setting.system, setting.settingId) then
                return true
            end
        end
    end

    return false
end

function ZO_GamepadOptions:RequestLoadDeferredSettingsForPanel(panelId)
    local isDeferredLoading = false
    local settings = GAMEPAD_SETTINGS_DATA[panelId]
    if settings then
        for i, setting in ipairs(settings) do
            if IsSettingDeferred(setting.system, setting.settingId) then
                RequestLoadDeferredSetting(setting.system, setting.settingId)
                isDeferredLoading = true
            end
        end
    end

    return isDeferredLoading
end

function ZO_GamepadOptions:RefreshOptionsList()
    self.optionsList:Clear()

    local panelName = GetString("SI_SETTINGSYSTEMPANEL", self.currentCategory)
    self.optionsList:SetNoItemText(zo_strformat(SI_INTERFACE_OPTIONS_SETTINGS_PANEL_UNAVAILABLE, panelName))

    local readyToRefresh = true
    if self:PanelRequiresDeferredLoading(self.currentCategory) then
        if self:AreDeferredSettingsForPanelLoading(self.currentCategory) then
            readyToRefresh = false
        end
    end

    if readyToRefresh then
        self:AddSettingGroup(self.currentCategory)

        if self.currentCategory ~= self.lastCategory then
            self.optionsList:CommitWithoutReselect()
        else
            self.optionsList:Commit()
        end
        self.lastCategory = self.currentCategory
    else
        self.optionsList:Commit()
    end
end

function ZO_GamepadOptions:GetNarrationText(entryData, entryControl)
    local textEntry = entryData.gamepadTextOverride or entryData.text
    local defaultText = self:GetTextEntry(textEntry, entryControl)
    if entryData.controlType then
        local controlType = self:GetControlType(entryData.controlType)
        if controlType == OPTIONS_HORIZONTAL_SCROLL_LIST then
            --TODO XAR: Look into pulling this value a different way
            local value = entryControl.horizontalListObject:GetCenterControl():GetText()
            return ZO_FormatSpinnerNarrationText(defaultText, value)
        elseif controlType == OPTIONS_CHECKBOX then
            local DEFAULT_HEADER = nil
            local isEnabled = entryData.enabled
            if type(isEnabled) == "function" then
                isEnabled = isEnabled()
            end
            return ZO_FormatToggleNarrationText(defaultText, ZO_Options_GetSettingFromControl(entryControl), DEFAULT_HEADER, isEnabled)
        elseif controlType == OPTIONS_SLIDER then
            local value = ZO_Options_GetSettingFromControl(entryControl)
            local formattedValueString, min, max = ZO_Options_GetFormattedSliderValues(entryData, value)
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_SLIDER_FORMATTER, defaultText, formattedValueString, min, max))
        elseif controlType == OPTIONS_COLOR then
            local currentValue = ZO_Options_GetSettingFromControl(entryControl)
            local color = ZO_ColorDef:New(currentValue)
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_COLOR_PICKER_FORMATTER, defaultText, color:ToHex()))
        elseif controlType == OPTIONS_CHAT_COLOR then
            local currentRed, currentGreen, currentBlue = GetChatCategoryColor(entryData.chatChannelCategory)
            local color = ZO_ColorDef:New(currentRed, currentGreen, currentBlue)
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_COLOR_PICKER_FORMATTER, defaultText, color:ToHex()))
        end
    end

    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(defaultText)
end

function ZO_GamepadOptions:AddSettingGroup(panelId)
    local settings = GAMEPAD_SETTINGS_DATA[panelId]
    if settings then
        local lastHeader = nil
        for i, setting in ipairs(settings) do
            local data = self:GetSettingsData(setting.panel, setting.system, setting.settingId)
            local isVisible = data.visible == nil or data.visible
            --Use a custom narration function for any options
            data.narrationText = function(entryData, entryControl) return self:GetNarrationText(entryData, entryControl) end

            if not self:DoesSettingExist(data) then
                -- This setting isn't available on this platform
                isVisible = false
            elseif IsSettingDeferred(data.system, data.settingId) and not IsDeferredSettingLoaded(data.system, data.settingId) then
                -- If this is a deferred setting and it isn't loaded, then don't show it
                isVisible = false
            elseif type(isVisible) == "function" then
                isVisible = isVisible()
            end

            if isVisible then
                local header
                if setting.header then
                    if type(setting.header) == "function" then
                        -- Clear header data when calling header function so the previous result of function is not retained
                        data.header = nil
                        header = setting.header(setting)
                    else
                        header = GetString(setting.header)
                    end
                end

                local controlType = self:GetControlType(data.controlType)
                if controlType == OPTIONS_SLIDER then
                    data.additionalInputNarrationFunction = function()
                        local selectedControl = self.optionsList:GetSelectedControl()
                        if selectedControl and selectedControl.data then
                            local enabled = selectedControl.data.enabled
                            if type(enabled) == "function" then
                                enabled = enabled()
                            end
                            return ZO_GetNumericHorizontalDirectionalInputNarrationData(enabled, enabled)
                        else
                            return {}
                        end
                    end
                elseif controlType == OPTIONS_HORIZONTAL_SCROLL_LIST then
                    data.additionalInputNarrationFunction = function()
                        local selectedControl = self.optionsList:GetSelectedControl()
                        if selectedControl and selectedControl.horizontalListObject then
                            local narrationFunction = selectedControl.horizontalListObject:GetAdditionalInputNarrationFunction()
                            return narrationFunction()
                        else
                            return {}
                        end
                    end
                end

                if controlType == OPTIONS_CUSTOM then
                    controlType = data.customControlType
                end

                local templateName = TEMPLATE_NAMES[controlType]
                local newHeader = header or data.header
                if newHeader and newHeader ~= lastHeader then 
                    templateName = templateName .. "WithHeader"
                    if not data.header then
                        data.header = header
                    end
                end
                lastHeader = newHeader

                self.optionsList:AddEntry(templateName, data)
            end
        end
    end
end

function ZO_GamepadOptions:LoadPanelDefaults(panelSettings)
    for _, setting in ipairs(panelSettings) do
        local data = self:GetSettingsData(setting.panel, setting.system, setting.settingId)
        local NO_CONTROL = nil
        ZO_SharedOptions.LoadDefaults(self, NO_CONTROL, data)
    end
end


function ZO_GamepadOptions:ApplySettings(control)
    ApplySettings()

    self.settingsNeedApply = false
    self:RefreshKeybinds()
end

function ZO_GamepadOptions:EnableApplyButton()
    self.settingsNeedApply = true
    self:RefreshKeybinds()
end

function ZO_GamepadOptions:LoadAllDefaults()
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

    ZO_SavePlayerConsoleProfile()
    self:SaveCachedSettings()

    self:RefreshGamepadInfoPanel()
end

function ZO_GamepadOptions:ReplaceBackKeybind(callback, name)
    self.overrideBackCallback = callback
    self.overrideBackName = name

    if self:IsShowing() then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GamepadOptions:RevertBackKeybind()
     self.overrideBackCallback = nil
     self.overrideBackName = nil

    if self:IsShowing() then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end