-- Control types used in the settings panels
OPTIONS_DROPDOWN = 1
OPTIONS_CHECKBOX = 2
OPTIONS_SECTION_TITLE = 3
OPTIONS_SLIDER = 4
OPTIONS_CUSTOM = 5
OPTIONS_HORIZONTAL_SCROLL_LIST = 6
OPTIONS_FINITE_LIST = 7
OPTIONS_INVOKE_CALLBACK = 8
OPTIONS_COLOR = 9
OPTIONS_CHAT_COLOR = 10

local function GetControlType(control)
    return control.optionsManager:GetControlTypeFromControl(control)
end

function ZO_Options_GetSettingFromControl(control)
    local data = control.data
    if data.GetSettingOverride then
        return data.GetSettingOverride(control)
    end

    if GetControlType(control) == OPTIONS_CHECKBOX then
        return GetSetting_Bool(data.system, data.settingId)
    end
    return GetSetting(data.system, data.settingId)
end

function ZO_Options_GetFormattedSliderValues(data, value)
    local shownValue = tonumber(value)
    local min = data.showValueMin or data.minValue
    local max = data.showValueMax or data.maxValue

    local formattedValueString
    if data.showValueFunc then
        formattedValueString = data.showValueFunc(shownValue)
        min = data.showValueFunc(min)
        max = data.showValueFunc(max)
    else
        if data.showValueMin and data.showValueMax and data.showValueMax > data.showValueMin then
            local range = data.maxValue - data.minValue
            local percentage = (shownValue - data.minValue) / range
            local shownRange = data.showValueMax - data.showValueMin
            shownValue = data.showValueMin + percentage * shownRange
            shownValue = string.format("%d", shownValue)
        end

        if data.valueTextFormatter then
            formattedValueString = zo_strformat(data.valueTextFormatter, shownValue)
            min = zo_strformat(data.valueTextFormatter, min)
            max = zo_strformat(data.valueTextFormatter, max)
        else
            formattedValueString = shownValue
        end
    end

    return formattedValueString, min, max
end

local function SetSettingFromControl(control, value)
    local data = control.data
    if data.SetSettingOverride then
        data.SetSettingOverride(control, value)
    end

    SetSetting(data.system, data.settingId, tostring(value))
end

local function IsGamepadOption(control)
    return control.optionsManager:IsGamepadOptions()
end

SAVE_CURRENT_VALUES         = 1
DONT_SAVE_CURRENT_VALUES    = 2

local ENABLED_STATE = 1
local DISABLED_STATE = 0.5

local function SetupColorOptionActivated(control, activated)
    control:GetNamedChild("Color"):SetAlpha(activated and ENABLED_STATE or DISABLED_STATE)
    control:GetNamedChild("Border"):SetAlpha(activated and ENABLED_STATE or DISABLED_STATE)
end

local activateOptionControl =
{
    [OPTIONS_DROPDOWN] =    function(control)
                                local dropdown = control:GetNamedChild("Dropdown")
                                ZO_ComboBox_Enable(dropdown)
                                dropdown:GetNamedChild("SelectedItemText"):SetAlpha(ENABLED_STATE)
                                dropdown:GetNamedChild("BG"):SetAlpha(ENABLED_STATE)
                                dropdown:GetNamedChild("OpenDropdown"):SetAlpha(ENABLED_STATE)
                            end,

    [OPTIONS_CHECKBOX] =    function(control)
                                local boxControl = control:GetNamedChild("Checkbox")
                                ZO_CheckButton_Enable(boxControl)
                                boxControl:SetAlpha(ENABLED_STATE)
                            end,

    [OPTIONS_SLIDER] =      function(control)
                                control:GetNamedChild("Slider"):SetEnabled(true)
                                control:GetNamedChild("SliderBackdrop"):SetAlpha(ENABLED_STATE)
                                control:GetNamedChild("ValueLabel"):SetAlpha(ENABLED_STATE)
                            end,

    [OPTIONS_COLOR] =       function(control)
                                SetupColorOptionActivated(control, true)
                            end,

    [OPTIONS_CHAT_COLOR] =  function(control)
                                SetupColorOptionActivated(control, true)
                            end,

    [OPTIONS_INVOKE_CALLBACK] = function(control)
                                    control:GetNamedChild("Button"):SetEnabled(true)
                                end,
}

local deactivateOptionControl =
{
    [OPTIONS_DROPDOWN] =    function(control)
                                local dropdown = control:GetNamedChild("Dropdown")
                                ZO_ComboBox_Disable(dropdown)
                                dropdown:GetNamedChild("SelectedItemText"):SetAlpha(DISABLED_STATE)
                                dropdown:GetNamedChild("BG"):SetAlpha(DISABLED_STATE)
                                dropdown:GetNamedChild("OpenDropdown"):SetAlpha(DISABLED_STATE)
                            end,

    [OPTIONS_CHECKBOX] =    function(control)
                                local boxControl = control:GetNamedChild("Checkbox")
                                ZO_CheckButton_Disable(boxControl)
                                boxControl:SetAlpha(DISABLED_STATE)
                            end,

    [OPTIONS_SLIDER] =      function(control)
                                control:GetNamedChild("Slider"):SetEnabled(false)
                                control:GetNamedChild("SliderBackdrop"):SetAlpha(DISABLED_STATE)
                                control:GetNamedChild("ValueLabel"):SetAlpha(DISABLED_STATE)
                            end,

    [OPTIONS_COLOR] =       function(control)
                                SetupColorOptionActivated(control, false)
                            end,

    [OPTIONS_CHAT_COLOR] =  function(control)
                                SetupColorOptionActivated(control, false)
                            end,

    [OPTIONS_INVOKE_CALLBACK] = function(control)
                                    control:GetNamedChild("Button"):SetEnabled(false)
                                end,

}

local function UpdateOptionControlState(control, updateTable, stateType)
    local controlType = GetControlType(control)
    local updateFn = updateTable[controlType]
    if updateFn then
        updateFn(control)
    end

    local nameControl = control:GetNamedChild("Name")
    local boxControl = control:GetNamedChild("Checkbox")

    if nameControl then
        if stateType == ENABLED_STATE then
            nameControl:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
        else
            nameControl:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGBA())
        end
    end

    if boxControl then
        -- the checkbox could be in the off state even though we now want it enabled
        -- so we have to override that color with the appropriate color
        local currentState = boxControl:GetState()
        if currentState ~= BSTATE_PRESSED and stateType == ENABLED_STATE then
            nameControl:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGBA())
        end
    end

    control.state = stateType
end

local function CheckEnableApplyButton(control, oldValue, currentValue)
    if oldValue ~= currentValue then
        control.optionsManager:EnableApplyButton()
    end
end

--ZO_Options_SetOptionActive/Inactive are keyboard only functions. The gamepad manages active state through
--the gamepadIsEnabledCallback. Using ZO_Options_SetOptionActive/Inactive with gamepad controls will set them
--to the keyboard colors and also doesn't handle the parametric list's selected state's impact.

function ZO_Options_SetOptionActive(control)
    UpdateOptionControlState(control, activateOptionControl, ENABLED_STATE)
end

function ZO_Options_SetOptionInactive(control)
    UpdateOptionControlState(control, deactivateOptionControl, DISABLED_STATE)
end

function ZO_SetControlActiveFromPredicate(control, predicate)
    if predicate() then
        ZO_Options_SetOptionActive(control)
    else
        ZO_Options_SetOptionInactive(control)
    end
end

function ZO_Options_SetOptionActiveOrInactive(control, active)
    UpdateOptionControlState(control, active and activateOptionControl or deactivateOptionControl, active and ENABLED_STATE or DISABLED_STATE)
end

function ZO_Options_IsOptionActive(control)
    if IsGamepadOption(control) then
        return control.data.enabled
    else
        return control.state == ENABLED_STATE
    end
end

function ZO_Options_ShowAssociatedWarning(control)
    ZO_Options_ShowOrHideAssociatedWarning(control, false)
end

function ZO_Options_HideAssociatedWarning(control)
    ZO_Options_ShowOrHideAssociatedWarning(control, true)
end

function ZO_Options_ShowOrHideAssociatedWarning(control, hidden)
    local warningControl = control:GetNamedChild("WarningIcon")
    warningControl:SetHidden(hidden)
end

function ZO_Options_SetWarningText(control, text)
    local hideWarning = text == nil or text == ""
    if not hideWarning then
        local warningControl = control:GetNamedChild("WarningIcon")
        warningControl.data.tooltipText = text
    end
    ZO_Options_ShowOrHideAssociatedWarning(control, hideWarning)
end

function ZO_Options_SetWarningTexture(control, texturePath)
    local shouldHideWarning = texturePath == nil or texturePath == ""
    if not shouldHideWarning then
        local warningControl = control:GetNamedChild("WarningIcon")
        warningControl:SetTexture(texturePath)
    end
    ZO_Options_ShowOrHideAssociatedWarning(control, shouldHideWarning)
end

local function GetValidIndexFromCurrentChoice(valid, currentChoice)
    for i = 1, #valid do
        if valid[i] == currentChoice then
            return i
        end
    end

    return -1
end

local function OptionsScrollListSelectionChanged(selectedData, oldData, reselectingDuringRebuild)
    if oldData ~= nil and reselectingDuringRebuild ~= true then
        local control = selectedData.parentControl
        local oldValue = ZO_Options_GetSettingFromControl(control)

        local value = selectedData.value
        SetSettingFromControl(control, value)

        local optionsData = control.data
        if optionsData.mustPushApply then
            CheckEnableApplyButton(control, oldValue, value)
        end

        local callback = optionsData.scrollListChangedCallback
        if callback then
            callback(selectedData, oldData)
        end

        local optionsManager = control.optionsManager
        if optionsManager and optionsManager:IsGamepadOptions() and optionsManager:IsShowing() then
            SCREEN_NARRATION_MANAGER:QueueParametricListEntry(optionsManager:GetCurrentList())
        end

        if optionsData.gamepadHasEnabledDependencies then
            SYSTEMS:GetGamepadObject("options"):OnOptionWithDependenciesChanged()
        end
    end
end

local function GetValueString(data)
    return type(data) == "function" and data() or GetString(data)
end

local function GetHorizontalScrollListOptionText(control, index)
    local data = control.data

    local validValues = data.valid
    if type(validValues) == "function" then
        validValues = data.valid()
    end

    --gamepadValidStringOverrides exists in case the enum used here has PC specific localization. If so, we create the strings in ClientGamepadStrings.xml and add them
    --to the data table's gamepadValidStringOverrides in the same order.
    local hasGamepadStrings = control.optionsManager:IsGamepadOptions() and (data.gamepadValidStringOverrides ~= nil)
    if hasGamepadStrings then
        return GetString(data.gamepadValidStringOverrides[index])
    elseif data.itemText then
        return data.itemText[index]
    elseif data.valueStringPrefix then
        return GetString(data.valueStringPrefix, validValues[index])
    elseif data.valueStrings then
        local valueStrings = data.valueStrings
        if type(valueStrings) == "function" then
            valueStrings = data.valueStrings()
        end
        return GetValueString(valueStrings[index])
    else
        return validValues[index]
    end
end

local DEFAULT_SLIDER_VALUE_STEP_PERCENT = 6.66
local updateControlFromSettings =
{
    [OPTIONS_DROPDOWN] = function(control)
                                local data = control.data
                                local currentSetting = ZO_Options_GetSettingFromControl(control)
                                local currentChoice = tonumber(currentSetting) or currentSetting
                                local isValidNumber = type(currentChoice) == "number"

                               local validValues = data.valid
                                if type(validValues) == "function" then
                                    validValues = data.valid()
                                    -- When valid is a function it can change the number of items in the dropdown so setup the dropdown again.
                                    ZO_Options_SetupDropdown(control)
                                end

                                local dropdownControl = control:GetNamedChild("Dropdown")
                                local dropdown = ZO_ComboBox_ObjectFromContainer(dropdownControl)
                                if data.itemText then
                                    dropdown:SetSelectedItemText(data.itemText[GetValidIndexFromCurrentChoice(validValues, currentChoice)])
                                elseif data.valueStringPrefix and isValidNumber then
                                    dropdown:SetSelectedItemText(GetString(data.valueStringPrefix, currentChoice))
                                elseif data.valueStrings then
                                    local valueStrings = data.valueStrings
                                    if type(valueStrings) == "function" then
                                        valueStrings = data.valueStrings()
                                    end
                                    dropdown:SetSelectedItemText(GetValueString(valueStrings[GetValidIndexFromCurrentChoice(validValues, currentChoice)]))
                                else
                                    dropdown:SetSelectedItemText(tostring(currentChoice))
                                end
                                return currentChoice
                            end,

    [OPTIONS_HORIZONTAL_SCROLL_LIST] = function(control)
                            local data = control.data
                            local currentSetting = ZO_Options_GetSettingFromControl(control)
                            local currentChoice = tonumber(currentSetting) or currentSetting

                            local validValues = data.valid
                            if type(validValues) == "function" then
                                validValues = data.valid()
                            end

                            local index = 0
                            for i = 1, #validValues do
                                if currentChoice == validValues[i] then
                                    index = i
                                    break
                                end
                            end

                            local targetChild = control.horizontalListObject:GetCenterControl()
                            if control.data.enabled == false then
                                targetChild:SetText(GetString(SI_CHECK_BUTTON_DISABLED))
                                targetChild:SetColor(ZO_GAMEPAD_DISABLED_UNSELECTED_COLOR:UnpackRGBA())
                            else
                                local text = GetHorizontalScrollListOptionText(control, index)
                                targetChild:SetText(text)
                            end

                            local ALLOW_EVEN_IF_DISABLED = true
                            local NO_ANIMATION = true
                            control.horizontalListObject:SetSelectedDataIndex(index, ALLOW_EVEN_IF_DISABLED, NO_ANIMATION)
                            control.horizontalListObject:SetOnSelectedDataChangedCallback(OptionsScrollListSelectionChanged)
                            return currentChoice
                        end,

    [OPTIONS_CHECKBOX] = function(control)
                                local currentChoice = ZO_Options_GetSettingFromControl(control)
                                local checkBoxControl = control:GetNamedChild("Checkbox")
                                ZO_CheckButton_SetCheckState(checkBoxControl, currentChoice)

                                local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
                                local nameControl = control:GetNamedChild("Name")

                                local enabled = control.data.enabled
                                if type(enabled) == "function" then
                                    enabled = control.data.enabled()
                                end

                                if not IsGamepadOption(control) then
                                    if enabled == false then
                                        ZO_CheckButton_Disable(checkBoxControl)
                                    else
                                        ZO_CheckButton_Enable(checkBoxControl)
                                    end

                                    if currentChoice then
                                        nameControl:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
                                    elseif mouseOverControl == checkBoxControl or mouseOverControl == control then
                                        nameControl:SetColor(ZO_DEFAULT_DISABLED_MOUSEOVER_COLOR:UnpackRGBA())
                                    else
                                        nameControl:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGBA())
                                    end
                                else
                                    if enabled == false then
                                        checkBoxControl:SetText(GetString(SI_CHECK_BUTTON_DISABLED))
                                        ZO_CheckButton_Disable(checkBoxControl)
                                    else
                                        checkBoxControl.checkedText = GetString(SI_CHECK_BUTTON_ON)
                                        checkBoxControl.uncheckedText = GetString(SI_CHECK_BUTTON_OFF)
                                        ZO_CheckButton_Enable(checkBoxControl)
                                    end

                                    local onLabel = control:GetNamedChild("On")
                                    local offLabel = control:GetNamedChild("Off")
                                    onLabel:SetColor((currentChoice and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT):UnpackRGBA())
                                    offLabel:SetColor((currentChoice and ZO_DISABLED_TEXT or ZO_SELECTED_TEXT):UnpackRGBA())

                                    local selected = checkBoxControl.selected
                                    checkBoxControl:SetHidden(selected)
                                    onLabel:SetHidden(not selected)
                                    offLabel:SetHidden(not selected)
                                end

                                return currentChoice
                            end,

    [OPTIONS_SLIDER] =   function(control)
                                local data = control.data
                                local currentChoice = tonumber(ZO_Options_GetSettingFromControl(control))
                                
                                local slider = control:GetNamedChild("Slider")

                                --We remove the OnValueChanged handler while we set up the slider because
                                --SetMinMax, SetValue, and SetValueStep can all potentially fire the OnValueChanged event
                                --which fires a callback that will actually set whatever setting the slider is attached too.
                                slider:SetHandler("OnValueChanged", nil)

                                slider:SetMinMax(data.minValue, data.maxValue)

                                if IsGamepadOption(control) then
                                    local stepValue = (data.maxValue - data.minValue) * ((data.gamepadValueStepPercent or DEFAULT_SLIDER_VALUE_STEP_PERCENT) / 100)
                                   slider:SetValueStep(stepValue)
                                end

                                slider:SetValue(currentChoice)

                                slider:SetHandler("OnValueChanged", ZO_Options_SliderOnValueChanged)

                                local valueLabelControl = control:GetNamedChild("ValueLabel")
                                if data.showValue and valueLabelControl then
                                    local formattedValueString, min, max = ZO_Options_GetFormattedSliderValues(data, currentChoice)
                                    valueLabelControl:SetText(formattedValueString)
                                end

                                return currentChoice
                            end,

    [OPTIONS_COLOR] =       function(control)
                                local currentChoice = ZO_Options_GetSettingFromControl(control)
                                local color = ZO_ColorDef:New(currentChoice)
                                if color then
                                    control:GetNamedChild("Color"):SetColor(color:UnpackRGB())
                                end
                                --Gamepad has to setup controls out of a pool so it needs to update enabled state all the time instead
                                --of just once like keyboard. This should probably be done as a call to setting the activated state in
                                --the gamepad code instead as part of the option update in gamepad only.
                                if IsGamepadOption(control) then
                                    SetupColorOptionActivated(control, ZO_Options_IsOptionActive(control))
                                end
                            end,

    [OPTIONS_CHAT_COLOR] =  function(control)
                                local data = control.data
                                local currentRed, currentGreen, currentBlue = GetChatCategoryColor(data.chatChannelCategory)
                                control:GetNamedChild("Color"):SetColor(currentRed, currentGreen, currentBlue)

                                --Gamepad has to setup controls out of a pool so it needs to update enabled state all the time instead
                                --of just once like keyboard. This should probably be done as a call to setting the activated state in
                                --the gamepad code instead as part of the option update in gamepad only.
                                if IsGamepadOption(control) then
                                    SetupColorOptionActivated(control, ZO_Options_IsOptionActive(control))
                                end
                            end,
}

function ZO_Options_UpdateOption(control)
    local data = control.data
    local controlType = GetControlType(control)
    local updateFn = updateControlFromSettings[controlType]
    local currentChoice

    -- Determine the activation state from control's enabled setting before getting the current save state.
    -- The functionality for managing state is only used on Keyboard and does not have defined behavour on Gamepad
    if not IsGamepadOption(control) then
        if control.data.enabled ~= nil then
            local enabled = control.data.enabled
            if type(enabled) == "function" then
                enabled = control.data.enabled()
            end
            ZO_SetControlActiveFromPredicate(control, function() return enabled end)
        end
    end

    -- If the control is inactive, activate it temporarily
    local saveCurrentState = control.state
    if saveCurrentState == DISABLED_STATE and not IsGamepadOption(control) then
        ZO_Options_SetOptionActive(control)
    end

    local previousChoice = data.currentChoice

    if updateFn then
        currentChoice = updateFn(control)
    end

    -- Restore the control's state
    if saveCurrentState == DISABLED_STATE and not IsGamepadOption(control) then
        ZO_Options_SetOptionInactive(control)
    end

    -- Fire events
    if currentChoice ~= previousChoice then
        data.currentChoice = currentChoice

        if data.events and data.events[currentChoice] then
            CALLBACK_MANAGER:FireCallbacks(data.events[currentChoice])
        end
    end

    return currentChoice
end

-- Change the actual settings as they are changed...they are reverted if the player chooses not to save
local function OptionsDropdown_SelectChoice(control, index)
    local data = control.data
    local oldValueString = ZO_Options_GetSettingFromControl(control)

    local validValues = data.valid
    if type(validValues) == "function" then
        validValues = data.valid()
    end

    local value = validValues[index]
    local valueString = tostring(value)
    SetSettingFromControl(control, valueString)
    if data.mustPushApply then
        -- If this control needs to be applied, update the dropdown with the local value, because the setting hasn't been changed yet.
        local dropdownControl = control:GetNamedChild("Dropdown")
        local dropdown = ZO_ComboBox_ObjectFromContainer(dropdownControl)
        if data.itemText then
            dropdown:SetSelectedItemText(data.itemText[index])
        elseif data.valueStringPrefix then
            dropdown:SetSelectedItemText(GetString(data.valueStringPrefix, value))
        elseif data.valueStrings then
            local valueStrings = data.valueStrings
            if type(valueStrings) == "function" then
                valueStrings = data.valueStrings()
            end
            dropdown:SetSelectedItemText(GetValueString(valueStrings[index]))
        else
            dropdown:SetSelectedItemText(valueString)
        end

        if data.events and data.events[value] then
            CALLBACK_MANAGER:FireCallbacks(data.events[value])
        end

        CheckEnableApplyButton(control, oldValueString, valueString)
    else
        ZO_Options_UpdateOption(control)
    end

    if data.mustReloadSettings then
        KEYBOARD_OPTIONS:UpdateCurrentPanelOptions(DONT_SAVE_CURRENT_VALUES)
    end
end

local function OptionsCheckBox_SelectChoice(control, boxIsChecked)
    local data = control.data
    local oldValue = ZO_Options_GetSettingFromControl(control)
    local value = boxIsChecked

    SetSettingFromControl(control, value)
    if data.mustPushApply then
        local checkBoxControl = control:GetNamedChild("Checkbox")
        ZO_CheckButton_SetCheckState(checkBoxControl, boxIsChecked)

        local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
        local nameControl = control:GetNamedChild("Name")
        
        if not IsGamepadOption(control) then
            if boxIsChecked then
                nameControl:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
            elseif mouseOverControl == checkBoxControl or mouseOverControl == control then
                nameControl:SetColor(ZO_DEFAULT_DISABLED_MOUSEOVER_COLOR:UnpackRGBA())
            else
                nameControl:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGBA())
            end
        end

        if data.events and data.events[boxIsChecked] then
            CALLBACK_MANAGER:FireCallbacks(data.events[boxIsChecked])
        end

        CheckEnableApplyButton(control, oldValue, value)
    else
        ZO_Options_UpdateOption(control)
    end

    local optionsManager = control.optionsManager
    if optionsManager and optionsManager:IsGamepadOptions() and optionsManager:IsShowing() then
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(optionsManager:GetCurrentList())
    end
    
    if data.mustReloadSettings then
        KEYBOARD_OPTIONS:UpdateCurrentPanelOptions(DONT_SAVE_CURRENT_VALUES)
    end
end

local function GetSliderOptionValues(control, value)
    local data = control.data
    local oldValueString = ZO_Options_GetSettingFromControl(control)
    local valueFormat = data.valueFormat or "%d"
    local formattedValueString = string.format(valueFormat, value)
    local formattedValue = tonumber(formattedValueString)

    return oldValueString, formattedValueString, formattedValue
end

-- NOTE: Sliders do not support value-based events
local function OptionsSlider_SelectChoice(control, value, eventReason)
    local data = control.data
    local oldValueString, formattedValueString, formattedValue = GetSliderOptionValues(control, value)
    SetSettingFromControl(control, formattedValueString)
    if data.mustPushApply then
        control:GetNamedChild("Slider"):SetValue(formattedValue)
        CheckEnableApplyButton(control, oldValueString, formattedValueString)
    else
        ZO_Options_UpdateOption(control)
    end

    local valueLabelControl = control:GetNamedChild("ValueLabel")
    if data.showValue and valueLabelControl then
        local formattedShowValueString, min, max = ZO_Options_GetFormattedSliderValues(data, formattedValue)
        valueLabelControl:SetText(formattedShowValueString)
    end

    local optionsManager = control.optionsManager
    if optionsManager and optionsManager:IsGamepadOptions() and optionsManager:IsShowing() then
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(optionsManager:GetCurrentList())
    end

    if data.mustReloadSettings then
        KEYBOARD_OPTIONS:UpdateCurrentPanelOptions(DONT_SAVE_CURRENT_VALUES)
    end
end

local function OptionsSlider_OnReleased(control, value)
    local data = control.data
    if data.onReleasedHandler then
        local oldValueString, formattedValueString, formattedValue = GetSliderOptionValues(control, value)

        if oldValueString ~= formattedValueString then
            data.onReleasedHandler(control, formattedValueString)
        end
    end
end

function ZO_Options_SliderOnValueChanged(sliderControl, value, eventReason)
    OptionsSlider_SelectChoice(sliderControl:GetParent(), value, eventReason)
end

function ZO_Options_SliderOnSliderReleased(sliderControl, value)
    OptionsSlider_OnReleased(sliderControl:GetParent(), value)
end

function ZO_Options_SetupSlider(control, selected)
    local data = control.data

    -- Sliders need a min/max value so verify that they are set here
    data.minValue = data.minValue or 0
    data.maxValue = data.maxValue or 1

    local slider = control:GetNamedChild("Slider")

    if selected ~= nil then
        slider:SetActive(selected and control.data.enabled ~= false)    --TODO: Added Gamepad Slider Disabled state colors, needs design
    end

    data.events = nil -- Sliders don't support events

    if data.defaultMarker and not IsGamepadOption(control) then
        local defaultMarkerControl = CreateControlFromVirtual("$(parent)DefaultMarker", slider, "ZO_Options_DefaultMarker")
        local offsetX = zo_clampedPercentBetween(data.minValue, data.maxValue, data.defaultMarker) * slider:GetWidth()
        defaultMarkerControl:SetAnchor(TOP, slider, LEFT, offsetX + .25, 6)

        defaultMarkerControl:SetHandler("OnClicked", function(self, button)
            PlaySound(SOUNDS.SINGLE_SETTING_RESET_TO_DEFAULT)
            slider:SetValue(data.defaultMarker)
            ZO_Options_SliderOnValueChanged(slider, slider:GetValue())
        end)
    end
end

function ZO_Options_SetupDropdown(control)
    local data = control.data
    local dropdownControl = control:GetNamedChild("Dropdown")
    local dropdown = ZO_ComboBox_ObjectFromContainer(dropdownControl)
    dropdown:ClearItems()
    dropdown.m_sortOrder = false        -- Add the valid items in the order they are added in the xml file (don't sort them)

    local validValues = data.valid
    if type(validValues) == "function" then
        validValues = data.valid()
    end

    local optionString, optionLine
    for index = 1, #validValues do
        if data.itemText then
            optionString = data.itemText[index]
        elseif data.valueStringPrefix then
            optionString = GetString(data.valueStringPrefix, validValues[index])
        elseif data.valueStrings then
            local valueStrings = data.valueStrings
            if type(valueStrings) == "function" then
                valueStrings = data.valueStrings()
            end
            optionString = GetValueString(valueStrings[index])
        else
            optionString = tostring(validValues[index])
        end
        optionLine = dropdown:CreateItemEntry(optionString, function() OptionsDropdown_SelectChoice(control, index) end)
        dropdown:AddItem(optionLine)
    end
end

function ZO_Options_InvokeCallback(control)
    local callback = control.data.callback
    if callback then
        callback()
    end
end

function ZO_Options_SetupScrollList(control, selected)
    control.horizontalListObject:Clear()

    local validValues = control.data.valid
    if type(validValues) == "function" then
        validValues = control.data.valid()
    end

    for i, validOption in ipairs(validValues) do
        local entryText = GetHorizontalScrollListOptionText(control, i)

        local entryData =
        {
            text = entryText,
            value = validOption,
            parentControl = control
        }
        control.horizontalListObject:AddEntry(entryData)
    end
    control.horizontalListObject:SetOnSelectedDataChangedCallback(nil)  -- don't set the callback til after we update the menu to the right setting
    control.horizontalListObject:Commit()
    control.horizontalListObject:SetActive(selected and control.data.enabled ~= false)  --TODO: Added Gamepad Slider Disabled state colors, needs design
end

local function CheckBoxToggleFunction(checkBoxControl, boxIsChecked)
    local control = checkBoxControl:GetParent()
    OptionsCheckBox_SelectChoice(control, boxIsChecked)
end

function ZO_Options_SetupCheckBox(control)
    local checkBoxControl = control:GetNamedChild("Checkbox")
    ZO_CheckButton_SetToggleFunction(checkBoxControl, CheckBoxToggleFunction)
end

function ZO_Options_CheckBoxOnMouseEnter(control)
    ZO_Options_OnMouseEnter(control)

    local nameControl = control:GetNamedChild("Name")
    local checkBoxControl = control:GetNamedChild("Checkbox")
    if checkBoxControl and nameControl then
        local currentState = checkBoxControl:GetState()
        if currentState == BSTATE_NORMAL then
            nameControl:SetColor(ZO_DEFAULT_DISABLED_MOUSEOVER_COLOR:UnpackRGBA())
        end

        checkBoxControl:SetPressedFontColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_HIGHLIGHT))
        checkBoxControl:SetNormalFontColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_HIGHLIGHT))
    end
end

function ZO_Options_CheckBoxOnMouseExit(control)
    ZO_Options_OnMouseExit(control)

    local nameControl = control:GetNamedChild("Name")
    local checkBoxControl = control:GetNamedChild("Checkbox")
    if checkBoxControl and nameControl then
        local currentState = checkBoxControl:GetState()
        if currentState == BSTATE_NORMAL then
            nameControl:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGBA())
        end

        checkBoxControl:SetPressedFontColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
        checkBoxControl:SetNormalFontColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
    end
end

function ZO_Options_ColorOnClicked(control)
    local data = control.data
    if ZO_Options_IsOptionActive(control) then
        local currentChoice = ZO_Options_GetSettingFromControl(control)
        local color = ZO_ColorDef:New(currentChoice)
        if color then
            local function OnColorSet(r, g, b)
                control:GetNamedChild("Color"):SetColor(r, g, b)
                local ARGBHexadecimal = ZO_ColorDef.FloatsToHex(r, g, b, 1)
                SetSetting(data.system, data.settingId, ARGBHexadecimal)
                local optionsManager = control.optionsManager
                if optionsManager and optionsManager:IsGamepadOptions() and optionsManager:IsShowing() then
                    SCREEN_NARRATION_MANAGER:QueueParametricListEntry(optionsManager:GetCurrentList())
                end
            end
            SYSTEMS:GetObject("colorPicker"):Show(OnColorSet, color:UnpackRGB())
        end
    end
end

do
    local categoryChildren =
    {
        [CHAT_CATEGORY_MONSTER_SAY] = {CHAT_CATEGORY_MONSTER_YELL, CHAT_CATEGORY_MONSTER_WHISPER, CHAT_CATEGORY_MONSTER_EMOTE}
    }

    function ZO_Options_Social_ChatColorOnClicked(control)
        if ZO_Options_IsOptionActive(control) then
            local data = control.data
            if data then
                local function OnColorSet(r, g, b)
                    control:GetNamedChild("Color"):SetColor(r, g, b)
                    SetChatCategoryColor(data.chatChannelCategory, r, g, b)

                    local children = categoryChildren[data.chatChannelCategory]
                    if children then
                        for i = 1, #children do
                            SetChatCategoryColor(children[i], r, g, b)
                        end
                    end

                    local optionsManager = control.optionsManager
                    if optionsManager and optionsManager:IsGamepadOptions() and optionsManager:IsShowing() then
                        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(optionsManager:GetCurrentList())
                    end
                end
                local currentRed, currentGreen, currentBlue = GetChatCategoryColor(data.chatChannelCategory)
                SYSTEMS:GetObject("colorPicker"):Show(OnColorSet, currentRed, currentGreen, currentBlue)
            end
        end
    end
end

function ZO_Options_ColorOnMouseEnter(colorControl)
    local textureControl = colorControl:GetNamedChild("Color")
    local sharedHighlight = SYSTEMS:GetObject("options"):GetColorOptionHighlight()
    if sharedHighlight then
        sharedHighlight:ClearAnchors()
        sharedHighlight:SetAnchor(CENTER, textureControl, CENTER)
        sharedHighlight:SetHidden(false)
    end
    ZO_Options_OnMouseEnter(colorControl)
end

function ZO_Options_ColorOnMouseExit(colorControl)
    local sharedHighlight = SYSTEMS:GetObject("options"):GetColorOptionHighlight()
    if sharedHighlight then
        sharedHighlight:SetHidden(true)
    end
    ZO_Options_OnMouseExit(colorControl)
end

function ZO_Options_ColorOnMouseUp(control, upInside)
    if upInside then
        ZO_Options_ColorOnClicked(control)
    end
end

function ZO_Options_Social_ChatColorOnMouseUp(control, upInside)
    if upInside then
        ZO_Options_Social_ChatColorOnClicked(control)
    end
end

function ZO_Options_SetupInvokeCallback(control, selected, text)
    if IsGamepadOption(control) then
        control:GetNamedChild("Name"):SetText(text)
    else
        local button = control:GetNamedChild("Button")
        button:SetText(text)
        button:SetHandler("OnClicked", function()
            control.data.callback()
        end)
    end
end

function ZO_Options_OnMouseEnter(control)
    local data = control.data
    local tooltipText = data.tooltipText

    if tooltipText ~= nil then
        local tooltipTextType = type(tooltipText)
        if tooltipTextType == "number" then
            tooltipText = GetString(tooltipText)
        elseif tooltipTextType == "function" then
            tooltipText = tooltipText()
        end

        if tooltipText == "" then
            return
        end

        InitializeTooltip(InformationTooltip, control, BOTTOMLEFT, 0, -2, TOPLEFT)
        SetTooltipText(InformationTooltip, tooltipText)
    end
end

function ZO_Options_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_Options_OnShow(control)
    local data = control.data
    if data and data.onShow then
        data.onShow(control)
    end
end