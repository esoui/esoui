PANEL_TYPE_SETTINGS = 1
PANEL_TYPE_CONTROLS = 2

ZO_KeyboardOptions = ZO_SharedOptions:Subclass()

function ZO_KeyboardOptions:Initialize(control)
    ZO_SharedOptions.Initialize(self)

    self.currentPanelId = 100 -- must be higher than total EsoGameDataEnums::SettingSystemPanel
    internalassert(self.currentPanelId > SETTING_PANEL_MAX_VALUE)

    self.control = control
    self.colorOptionHighlight = control:GetNamedChild("Options_Color_SharedHighlight")
    self.emptyPanelLabel = control:GetNamedChild("EmptyPanelLabel")
    self.loadingControl = control:GetNamedChild("Loading")

    OPTIONS_WINDOW_FRAGMENT = ZO_FadeSceneFragment:New(control)
    OPTIONS_WINDOW_FRAGMENT:RegisterCallback("StateChange",   function(oldState, newState)
                                                    if newState == SCENE_FRAGMENT_SHOWING then
                                                        RefreshSettings()
                                                        self:UpdateAllPanelOptions(SAVE_CURRENT_VALUES)
                                                        control:GetNamedChild("ApplyButton"):SetHidden(true)
                                                        PushActionLayerByName("OptionsWindow")
                                                    elseif newState == SCENE_FRAGMENT_HIDING then
                                                        SetCameraOptionsPreviewModeEnabled(false, CAMERA_OPTIONS_PREVIEW_NONE)
                                                        RemoveActionLayerByName("OptionsWindow")
                                                        self:SaveCachedSettings()
                                                    elseif newState == SCENE_FRAGMENT_HIDDEN then
                                                        -- We may hide this scene while one of these panels is active, and disabling share features.
                                                        -- To undo that, just re-enable them here. This assumes that there aren't multiple reasons to disable share features.
                                                        if DoesPlatformSupportDisablingShareFeatures() and ZO_SharedOptions.DoesPanelDisableShareFeatures(self.currentPanel) then
                                                            EnableShareFeatures()
                                                        end
                                                    end
                                                end)
    ZO_ReanchorControlForLeftSidePanel(control)

    CALLBACK_MANAGER:RegisterCallback("OnEditAccountEmailKeyboardDialogClosed", function() self:UpdatePanelVisibility(self.currentPanel) end)

    local function OnDeferredSettingRequestCompleted(eventId, system, settingId, success, result)
        if OPTIONS_WINDOW_FRAGMENT:IsShowing() and not self:AreDeferredSettingsForPanelLoading(self.currentPanel) then
            if system == SETTING_TYPE_ACCOUNT and settingId == ACCOUNT_SETTING_ACCOUNT_EMAIL and result == ACCOUNT_EMAIL_REQUEST_RESULT_SUCCESS_EMAIL_UPDATED then
                ZO_Dialogs_ShowPlatformDialog("ACCOUNT_MANAGEMENT_EMAIL_CHANGED")
            end
            self:ShowPanel(self.currentPanel)
        end
    end

    EVENT_MANAGER:RegisterForEvent("KeyboardOptions", EVENT_DEFERRED_SETTING_REQUEST_COMPLETED, OnDeferredSettingRequestCompleted)
end

function ZO_KeyboardOptions:AddUserPanel(panelIdOrString, panelName, panelType, visible)
    panelType = panelType or PANEL_TYPE_SETTINGS

    local id = panelIdOrString

    if type(panelIdOrString) == "string" then
        id = self.currentPanelId
        _G[panelIdOrString] = id
        self.currentPanelId = self.currentPanelId + 1
    end

    self.panelNames[id] = panelName

    -- SelectionCallback calls expect to place in a control as the first argument even if not used by this callback.
    local callback =    function(optionButtonControl, anchorFunction)
                            if anchorFunction then
                                anchorFunction(self.control)
                            else
                                ZO_ReanchorControlForLeftSidePanel(self.control)
                            end
                            SCENE_MANAGER:AddFragment(OPTIONS_WINDOW_FRAGMENT)
                            self:ChangePanels(id)
                        end
    local unselectedCallback =  function()
                                    SCENE_MANAGER:RemoveFragment(OPTIONS_WINDOW_FRAGMENT)
                                    SetCameraOptionsPreviewModeEnabled(false, CAMERA_OPTIONS_PREVIEW_NONE)
                                end

    local panelData =
    {
        name = panelName,
        visible = visible,
        callback = callback,
        unselectedCallback = unselectedCallback
    }
    if panelType == PANEL_TYPE_SETTINGS then
        ZO_GameMenu_AddSettingPanel(panelData)
    else
        ZO_GameMenu_AddControlsPanel(panelData)
    end
end

function ZO_KeyboardOptions:InitializeControl(control)
    local data = control.data
    local IS_KEYBOARD_CONTROL = true
    local USE_SELECTED = nil
    ZO_SharedOptions.InitializeControl(self, control, USE_SELECTED, IS_KEYBOARD_CONTROL)

    -- Catch events...callbacks set in the xml
    if data.eventCallbacks then
        for event, callback in pairs(data.eventCallbacks) do
            CALLBACK_MANAGER:RegisterCallback(event, callback, control)
        end
    end

    local settingsScrollChild = self.control:GetNamedChild("SettingsScrollChild")
    control:SetParent(settingsScrollChild)

    -- Put the control in the panel table
    if data.panel then
        -- Panel doesn't exist yet, so create it
        if not self.controlTable[data.panel] then
            self.controlTable[data.panel] = {}
        end

        -- Add the control to the right panel list
        table.insert(self.controlTable[data.panel], control)

        -- Update visible state
        control:SetHidden(not (data.panel == self.currentPanel))
    end

    ZO_Options_SetOptionActive(control)
end

function ZO_KeyboardOptions:ChangePanels(panelId)
    -- Hide the old panel
    if self.currentPanel then
        local oldPanel = self.controlTable[self.currentPanel]
        if oldPanel then
            for index = 1, #oldPanel do
                local control = oldPanel[index]
                control:SetHidden(true)
            end
        end
    end

    self.currentPanel = panelId

    local panelName = self.panelNames[panelId]
    self.control:GetNamedChild("Title"):SetText(panelName)

    self.emptyPanelLabel:SetText(zo_strformat(SI_INTERFACE_OPTIONS_SETTINGS_PANEL_UNAVAILABLE, panelName))
    self.emptyPanelLabel:SetHidden(true)

    -- Determine if the panel requires deferred loading
    local readyToShowPanel = true
    if self:PanelRequiresDeferredLoading(panelId) then
        local isDeferredLoading = self:RequestLoadDeferredSettingsForPanel(panelId)
        if isDeferredLoading then
            self.loadingControl:Show()

            readyToShowPanel = false
        end
    end

    if readyToShowPanel then
        self:ShowPanel(panelId)
    end
end

function ZO_KeyboardOptions:PanelRequiresDeferredLoading(panelId)
    local panelControls = self.controlTable[panelId]
    if panelControls then
        for i, control in ipairs(panelControls) do
            local data = control.data
            if IsSettingDeferred(data.system, data.settingId) then
                return true
            end
        end
    end

    return false
end

function ZO_KeyboardOptions:AreDeferredSettingsForPanelLoading(panelId)
    local panelControls = self.controlTable[panelId]
    for i, control in ipairs(panelControls) do
        local data = control.data
        if IsSettingDeferred(data.system, data.settingId) and IsDeferredSettingLoading(data.system, data.settingId) then
            return true
        end
    end

    return false
end

function ZO_KeyboardOptions:RequestLoadDeferredSettingsForPanel(panelId)
    local isDeferredLoading = false
    local panelControls = self.controlTable[panelId]
    for i, control in ipairs(panelControls) do
        local data = control.data
        if IsSettingDeferred(data.system, data.settingId) then
            RequestLoadDeferredSetting(data.system, data.settingId)
            isDeferredLoading = true
        end
    end

    return isDeferredLoading
end

function ZO_KeyboardOptions:ShowPanel(panelId)
    if DoesPlatformSupportDisablingShareFeatures() and ZO_SharedOptions.DoesPanelDisableShareFeatures(panelId) then
        DisableShareFeatures()
    end

    self.loadingControl:Hide()

    -- Show the new panel
    local cameraPreviewMode = panelId == SETTING_PANEL_CAMERA
    SetCameraOptionsPreviewModeEnabled(cameraPreviewMode, CAMERA_OPTIONS_PREVIEW_NONE)
    if SetFrameLocalPlayerInGameCamera then
        SetFrameLocalPlayerInGameCamera(not cameraPreviewMode)
    end
    self:UpdateCurrentPanelOptions(DONT_SAVE_CURRENT_VALUES)
    self:UpdatePanelVisibility(panelId)

    self.control:GetNamedChild("ToggleFirstPersonButton"):SetHidden(panelId ~= SETTING_PANEL_CAMERA) -- only in camera panel
    self.control:GetNamedChild("ResetToDefaultButton"):SetHidden(panelId == SETTING_PANEL_ACCOUNT) -- everywhere but account panel

    ZO_Scroll_ResetToTop(self.control:GetNamedChild("Settings"))

    self.currentPanel = panelId
end

function ZO_KeyboardOptions:UpdatePanelVisibilityIfShowing(panelId)
    if self.currentPanel == panelId then
        self:UpdatePanelVisibility(panelId)
    end
end

local function IsSettingVisible(data)
    local isVisible = data.visible == nil or data.visible
    if type(isVisible) == "function" then
        isVisible = isVisible()
    end
    if isVisible and data.system and data.settingId then
        if IsSettingDeferred(data.system, data.settingId) and not IsDeferredSettingLoaded(data.system, data.settingId) then
            isVisible = false
        end
    end
    return isVisible
end

function ZO_KeyboardOptions:UpdatePanelVisibility(panelId)
    local panelControls = self.controlTable[panelId]
    if panelControls then
        -- Determine the visibility of each control on the panel
        -- Since the controls are also headers and the like, we need to check if any
        -- settings controls are showing so we don't end up showing just headers
        local hasAnyVisibleSetting = false
        for index, control in ipairs(panelControls) do
            local data = control.data
            local isVisible = IsSettingVisible(data)
            control:SetHidden(not isVisible)

            if isVisible and data.system ~= nil then
                hasAnyVisibleSetting = true
            end
        end
        
        if hasAnyVisibleSetting then
            -- Set anchors in separate loop in case controls in panel are not processed in the order they appear on the screen.
            for index, control in ipairs(panelControls) do
                local isValid, point, relTo, relPoint, offsetX, offsetY = control:GetAnchor(0)
                -- If the previous element can be dynamically hidden, then we need to update our anchors to reflect its hidden state
                if isValid and relTo and relTo.data and relTo.data.visible ~= nil then
                    -- TODO: headers are still visible, even when every setting
                    -- under that header isn't. We should keep track when a setting is
                    -- visible underneath a header, and then for any header with 0
                    -- visible settings, we should mark them as not visible
                    -- like any other setting control.
                    if not control.originalPoint then
                        control.originalOffsetX = offsetX
                        control.originalOffsetY = offsetY
                        control.originalPoint = point
                        control.originalRelativePoint = relPoint
                    end
                    control:ClearAnchors()
                    if relTo:IsHidden() then
                        control:SetAnchor(TOPLEFT, relTo, TOPLEFT, 0, 0)
                    else
                        control:SetAnchor(control.originalPoint, relTo, control.originalRelativePoint, control.originalOffsetX, control.originalOffsetY)
                    end
                end
            end
        end

        self.emptyPanelLabel:SetHidden(hasAnyVisibleSetting)
        self.control:GetNamedChild("Settings"):SetHidden(not hasAnyVisibleSetting)
    else
        self.emptyPanelLabel:SetHidden(false)
    end
end

function ZO_KeyboardOptions:ApplySettings(control)
    ApplySettings()

    self.control:GetNamedChild("ApplyButton"):SetHidden(true)

    -- Update the panel settings with the new values (may have changed if they are tied to another setting that changed...e.g. ui scale)
    self:UpdateAllPanelOptions(SAVE_CURRENT_VALUES)
end

function ZO_KeyboardOptions:EnableApplyButton()
    self.control:GetNamedChild("ApplyButton"):SetHidden(false)
end

function ZO_KeyboardOptions:LoadAllDefaults()
    local controls = self.controlTable[self.currentPanel]
    if controls then
        for index, control in pairs(controls) do
            ZO_SharedOptions.LoadDefaults(self, control, control.data)
        end
        self:UpdateCurrentPanelOptions(DONT_SAVE_CURRENT_VALUES)
    end
end

function ZO_KeyboardOptions:UpdatePanelOptions(panelIndex, saveOptions)
    local controls = self.controlTable[panelIndex]
    if controls then
        for index, control in pairs(controls) do
            local data = control.data
            if self:IsControlTypeAnOption(data) then
                local value = ZO_Options_UpdateOption(control)
                if saveOptions == SAVE_CURRENT_VALUES then
                    data.value = value       -- Save the values (can't click cancel to restore old values after this)
                end
            elseif data.controlType == OPTIONS_CUSTOM then
                if data.customSetupFunction then
                    data.customSetupFunction(control)
                end
            end
        end
    end
end

function ZO_KeyboardOptions:UpdateCurrentPanelOptions(saveOptions)
    self:UpdatePanelOptions(self.currentPanel, saveOptions)
end

function ZO_KeyboardOptions:GetColorOptionHighlight()
    return self.colorOptionHighlight
end

-- Pass SAVE_CURRENT_VALUES in the first parameter to save the updated values (can't click cancel to restore afterwards).
-- Pass DONT_SAVE_CURRENT_VALUES to update the values, but not save them (cancel will restore the previous values).
function ZO_KeyboardOptions:UpdateAllPanelOptions(saveOptions)
    for index in pairs(self.controlTable) do
        self:UpdatePanelOptions(index, saveOptions)
    end
end

function ZO_KeyboardOptions:SetSectionTitleData(control, panel, text)
    control.data =
    {
        panel = panel,
        controlType = OPTIONS_SECTION_TITLE,
        text = text,
    }
end

function ZO_Options_Keyboard_OnInitialize(control)
    KEYBOARD_OPTIONS = ZO_KeyboardOptions:New(control)
    SYSTEMS:RegisterKeyboardObject("options", KEYBOARD_OPTIONS)
end

--keep this around for backwards compatibility
function ZO_OptionsWindow_InitializeControl(control)
    KEYBOARD_OPTIONS:InitializeControl(control)
end

function ZO_OptionsWindow_ApplySettings(control)
    KEYBOARD_OPTIONS:ApplySettings(control)
end

function ZO_OptionsWindow_ToggleFirstPerson(control)
    ToggleGameCameraFirstPerson()
end

function ZO_OptionsWindow_AddUserPanel(panelIdString, panelName, panelType)
    KEYBOARD_OPTIONS:AddUserPanel(panelIdString, panelName, panelType)
end
