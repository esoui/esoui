PANEL_TYPE_SETTINGS = 1
PANEL_TYPE_CONTROLS = 2

ZO_KeyboardOptions = ZO_SharedOptions:Subclass()

function ZO_KeyboardOptions:New(control)
    local options = ZO_SharedOptions.New(self, control)
    return options
end

function ZO_KeyboardOptions:Initialize(control)
    self.currentPanelId = 100 --must be higher than total EsoGameDataEnums::SettingSystemPanel, currently 6
    ZO_SharedOptions.Initialize(self, control)
    OPTIONS_WINDOW_FRAGMENT = ZO_FadeSceneFragment:New(control)
    OPTIONS_WINDOW_FRAGMENT:RegisterCallback("StateChange",   function(oldState, newState)
                                                    if newState == SCENE_FRAGMENT_SHOWING then
                                                        RefreshSettings()
                                                        self:UpdateAllPanelOptions(SAVE_CURRENT_VALUES)
                                                        GetControl(ZO_OptionsWindow, "ApplyButton"):SetHidden(true)
                                                        PushActionLayerByName("OptionsWindow")
                                                    elseif(newState == SCENE_FRAGMENT_HIDING) then
                                                        RemoveActionLayerByName("OptionsWindow")
                                                        self:SaveCachedSettings()
                                                    end
                                                end)
    ZO_ReanchorControlForLeftSidePanel(control)
end

function ZO_KeyboardOptions:AddUserPanel(panelIdOrString, panelName, panelType)
    panelType = panelType or PANEL_TYPE_SETTINGS

    local id = panelIdOrString

    if type(panelIdOrString) == "string" then
        id = self.currentPanelId
        _G[panelIdOrString] = id
        self.currentPanelId = self.currentPanelId + 1
    end
    
    self.panelNames[id] = panelName

    

    local callback =    function()
                            SCENE_MANAGER:AddFragment(OPTIONS_WINDOW_FRAGMENT)
                            self:ChangePanels(id)
                        end
    local unselectedCallback =  function()
                                    SCENE_MANAGER:RemoveFragment(OPTIONS_WINDOW_FRAGMENT)
                                    SetCameraOptionsPreviewModeEnabled(false, CAMERA_OPTIONS_PREVIEW_NONE)
                                end

    local panelData = {name = panelName, callback = callback, unselectedCallback = unselectedCallback}
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

    local settingsScrollChild = GetControl(ZO_OptionsWindow, "SettingsScrollChild")
    control:SetParent(settingsScrollChild)

    -- Put the control in the panel table
    if data.panel then
        -- Panel doesn't exist yet,  so create it
        if not self.controlTable[data.panel] then
            self.controlTable[data.panel] = {}
        end

        -- Add the control to the right panel list
        table.insert(self.controlTable[data.panel], control)

        -- Update visible state
        control:SetHidden(not (data.panel == self.currentPanel))
    end
end

function ZO_KeyboardOptions:ChangePanels(panel)
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

    -- Show the new panel
    local cameraPreviewMode = (panel == SETTING_PANEL_CAMERA)
    SetCameraOptionsPreviewModeEnabled(cameraPreviewMode, CAMERA_OPTIONS_PREVIEW_NONE)
    local newPanel = self.controlTable[panel]
    if newPanel then
        for index = 1, #newPanel do
            local control = newPanel[index]
            control:SetHidden(false)
        end
    end

    local panelName = self.panelNames[panel]
    local isGamepadMode = IsInGamepadPreferredMode()
    local isCameraSettingPanelActive = (panel == SETTING_PANEL_CAMERA)
    local isFirstPersonToggleButtonVisible = not isGamepadMode and isCameraSettingPanelActive

    GetControl(ZO_OptionsWindow, "Title"):SetText(panelName)
    GetControl(ZO_OptionsWindow, "ToggleFirstPersonButton"):SetHidden(not isFirstPersonToggleButtonVisible)

    ZO_Scroll_ResetToTop(GetControl(ZO_OptionsWindow, "Settings"))

    self.currentPanel = panel
end

function ZO_KeyboardOptions:ApplySettings(control)
    ApplySettings()
    
    GetControl(ZO_OptionsWindow, "ApplyButton"):SetHidden(true)

    -- Update the panel settings with the new values (may have changed if they are tied to another setting that changed...e.g. ui scale)
    self:UpdateAllPanelOptions(SAVE_CURRENT_VALUES)
end

function ZO_KeyboardOptions:LoadDefaults() 
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

    for index, control in pairs(controls) do
        local data = control.data
        if self:IsControlTypeAnOption(data) then
            local value = ZO_Options_UpdateOption(control)
            if saveOptions == SAVE_CURRENT_VALUES then
                data.value = value       -- Save the values (can't click cancel to restore old values after this)
            end
        end
    end
end

function ZO_KeyboardOptions:UpdateCurrentPanelOptions(saveOptions)
    self:UpdatePanelOptions(self.currentPanel, saveOptions)
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