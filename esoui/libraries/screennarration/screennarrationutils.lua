-----------------------------------------------------
-- Global helper functions used for screen narration
-----------------------------------------------------

--Helper function for determining if something is a narratable object
function ZO_IsNarratableObject(narration)
    if narration and narration.IsInstanceOf and narration:IsInstanceOf(ZO_NarratableObject) then
        return true
    end
    return false
end

--Helper function for appending a narration to a table of narratable objects
function ZO_AppendNarration(destination, narration)
    if narration then
        if ZO_IsNarratableObject(narration) then
            table.insert(destination, narration)
        else
            ZO_CombineNumericallyIndexedTables(destination, narration)
        end
    end
end

--Given a grid list entry, returns the narration text from the entry's object. Intended to be used for entries that inherit from ZO_Tile
function ZO_GetNarrationTextForGridListTile(entryData)
    if entryData and entryData.dataEntry then
        if entryData.dataEntry.control then
            return entryData.dataEntry.control.object:GetNarrationText()
        end
    end
end

--Generates narration text for a toggle control. The header and enabled parameters are optional
--If nothing is passed in for enabled, assume true
function ZO_FormatToggleNarrationText(name, isChecked, header, enabled)
    local isCheckedText
    if enabled == nil or enabled then
        isCheckedText = isChecked and GetString(SI_SCREEN_NARRATION_TOGGLE_ON) or GetString(SI_SCREEN_NARRATION_TOGGLE_OFF)
    else
        --If the toggle is disabled, narrate that instead of the on/off state
        isCheckedText = GetString(SI_SCREEN_NARRATION_TOGGLE_DISABLED)
    end

    if header then
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_TOGGLE_WITH_HEADER_FORMATTER, name, isCheckedText, header))
    else
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_TOGGLE_FORMATTER, name, isCheckedText))
    end
end

--Generates narration text for a radio button control. The header parameter is optional
function ZO_FormatRadioButtonNarrationText(name, isChecked, header)
    local isCheckedText = isChecked and GetString(SI_SCREEN_NARRATION_TOGGLE_ON) or GetString(SI_SCREEN_NARRATION_TOGGLE_OFF)
    if header then
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_RADIO_BUTTON_WITH_HEADER_FORMATTER, name, isCheckedText, header))
    else
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_RADIO_BUTTON_FORMATTER, name, isCheckedText))
    end
end

do
    internalassert(TEXT_TYPE_MAX_VALUE == 5)
    local NUMERIC_ONLY_TEXT_TYPES =
    {
        [TEXT_TYPE_NUMERIC] = true,
        [TEXT_TYPE_NUMERIC_UNSIGNED_INT] = true,
    }

    --Generates narration text for an edit control. The name parameter is optional.
    function ZO_FormatEditBoxNarrationText(editControl, name)
        if editControl then
            local narration = SCREEN_NARRATION_MANAGER:CreateNarratableObject(name)

            local textType = editControl:GetTextType()
            --Use a slightly different string if the edit control is numeric (meaning it only accepts numbers)
            if NUMERIC_ONLY_TEXT_TYPES[textType] then
                narration:AddNarrationText(GetString(SI_SCREEN_NARRATION_NUMERIC_EDIT_BOX))
            else
                narration:AddNarrationText(GetString(SI_SCREEN_NARRATION_EDIT_BOX))
            end

            local valueText = editControl:GetText()
            --Default to using the current value text of the edit box, and then fall back to the default text if necessary
            if valueText ~= "" then
                --If this is a password field, narrate that instead of the actual value
                if editControl:IsPassword() then
                    narration:AddNarrationText(GetString(SI_SCREEN_NARRATION_EDIT_BOX_PASSWORD))
                else
                    narration:AddNarrationText(valueText)
                end
            else
                narration:AddNarrationText(editControl:GetDefaultText())
            end
            narration:AddNarrationText(zo_strformat(SI_SCREEN_NARRATION_EDIT_BOX_INPUT_CHARACTER_LIMIT, editControl:GetMaxInputChars()))

            return narration
        end
    end
end

--Generates narration text for a spinner.
function ZO_FormatSpinnerNarrationText(name, value)
    if name then
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_SPINNER_FORMATTER, name, value))
    else
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_SPINNER_FORMATTER_UNNAMED, value))
    end
end

--Generates narration text for a vertical spinner.
function ZO_FormatVerticalSpinnerNarrationText(name, value)
    if name then
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_VERTICAL_SPINNER_FORMATTER, name, value))
    else
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_VERTICAL_SPINNER_FORMATTER_UNNAMED, value))
    end
end

--Generates narration text for a slider
function ZO_FormatSliderNarrationText(sliderControl, name)
    local min, max = sliderControl:GetMinMax()
    local value = sliderControl:GetValue()
    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_SLIDER_FORMATTER, name, value, min, max))
end

--Default function for getting the narration text for a dropdown entry in a parametric list
function ZO_GetDefaultParametricListDropdownNarrationText(entryData, entryControl)
    return entryControl.dropdown:GetNarrationText()
end

--Default function for getting the narration text for an edit box control in a parametric list
function ZO_GetDefaultParametricListEditBoxNarrationText(entryData, entryControl)
    return ZO_FormatEditBoxNarrationText(entryControl.editBoxControl)
end

--Default function for getting the narration text for a toggle in a parametric list
function ZO_GetDefaultParametricListToggleNarrationText(entryData, entryControl)
    local isChecked = ZO_GamepadCheckBoxTemplate_IsChecked(entryControl)
    return ZO_FormatToggleNarrationText(entryData.text, isChecked)
end

--Function for getting a table of narratable objects for sublabels defined in a shared gamepad entry
function ZO_GetSharedGamepadEntrySubLabelNarrationText(entryData, entryControl)
    local narrations = {}
    if entryData.subLabelsNarrationText then
        if type(entryData.subLabelsNarrationText) == "function" then
            local narration = entryData.subLabelsNarrationText(entryData, entryControl)
            ZO_AppendNarration(narrations, narration)
        else
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.subLabelsNarrationText))
        end
    elseif entryData.subLabels then
        for _, subLabelTextProvider in ipairs(entryData.subLabels) do
            local subLabelText
            if type(subLabelTextProvider) == "function" then
                subLabelText = subLabelTextProvider()
            else
                subLabelText = subLabelTextProvider
            end
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(subLabelText))
        end
    end
    return narrations
end

--Function for getting a narratable object for stack count defined in a shared gamepad entry
function ZO_GetSharedGamepadEntryStackCountNarrationText(entryData, entryControl)
    local narration = SCREEN_NARRATION_MANAGER:CreateNarratableObject()
    if entryData.stackCount then
        if entryData.stackCount > 1 or entryControl.alwaysShowStackCount then
            narration:AddNarrationText(zo_strformat(SI_SCREEN_NARRATION_STACK_COUNT_FORMATTER, entryData.stackCount))
        end
    end
    return narration
end

--Function for getting a table of narratable objects for the narration for status indicators in a shared gamepad entry
function ZO_GetSharedGamepadEntryStatusIndicatorNarrationText(entryData, entryControl)
    local narrations = {}
    if entryControl then
        if entryControl.statusIndicator and entryControl.statusIndicator.GetNarrationText then
            ZO_AppendNarration(narrations, entryControl.statusIndicator:GetNarrationText())
        end

        if entryControl.subStatusIcon and entryControl.subStatusIcon.GetNarrationText then
            ZO_AppendNarration(narrations, entryControl.subStatusIcon:GetNarrationText())
        end
    end
    return narrations
end

--Function for getting a narratable object for a progress bar, given a min, max and current value
function ZO_GetProgressBarNarrationText(barMin, barMax, barValue)
    if barMax > barMin then
        local range = barMax - barMin
        local percentage = (barValue - barMin) / range
        percentage = string.format("%.2f", percentage * 100)
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_PROGRESS_BAR_PERCENT_FORMATTER, percentage))
    end
end

--Function for getting a narratable object for a progress bar in a shared gamepad entry
function ZO_GetSharedGamepadEntryProgressBarNarrationText(entryData)
    local barMax = entryData.barMax
    if barMax then
        local barMin = entryData.barMin or 0
        local barValue = entryData.barValue or 0
        return ZO_GetProgressBarNarrationText(barMin, barMax, barValue)
    end
end

--Function for grabbing the default narration for a gamepad entry
function ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl)
    local narrations = {}
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.text))
    ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntrySubLabelNarrationText(entryData, entryControl))
    ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryProgressBarNarrationText(entryData))
    ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryStackCountNarrationText(entryData, entryControl))
    ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryStatusIndicatorNarrationText(entryData, entryControl))
    return narrations
end

--Function for getting a narratable object for a vertex of a triangle picker, given a name and a value
function ZO_GetTrianglePickerVertexNarrationText(name, value)
    local percentage = string.format("%d", value * 100)
    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_SCREEN_NARRATION_TRIANGLE_PICKER_PERCENT_FORMATTER, name, percentage))
end

do
    local function CreateKeybindNarrationData(info, keybind)
        local data = 
        {
            name = info.text,
            keybindName = ZO_Keybindings_GetNarrationStringFromKeys(keybind, KEY_INVALID, KEY_INVALID, KEY_INVALID, KEY_INVALID),
            enabled = info.enabled,
        }
        return data
    end

    --Function for getting a table of keybind narration info for each direction that has info specified in the parameters
    function ZO_GetDirectionalInputNarrationData(leftInfo, rightInfo, upInfo, downInfo)
        local narrationData = {}

        local shouldNarrateGamepad = ZO_Keybindings_ShouldShowGamepadKeybind()
        if leftInfo then
            local keybind = shouldNarrateGamepad and KEY_GAMEPAD_DPAD_LEFT or KEY_LEFTARROW
            table.insert(narrationData, CreateKeybindNarrationData(leftInfo, keybind))
        end

        if rightInfo then
            local keybind = shouldNarrateGamepad and KEY_GAMEPAD_DPAD_RIGHT or KEY_RIGHTARROW
            table.insert(narrationData, CreateKeybindNarrationData(rightInfo, keybind))
        end

        if upInfo then
            local keybind = shouldNarrateGamepad and KEY_GAMEPAD_DPAD_UP or KEY_UPARROW
            table.insert(narrationData, CreateKeybindNarrationData(upInfo, keybind))
        end

        if downInfo then
            local keybind = ZO_Keybindings_ShouldShowGamepadKeybind() and KEY_GAMEPAD_DPAD_DOWN or KEY_DOWNARROW
            table.insert(narrationData, CreateKeybindNarrationData(downInfo, keybind))
        end

        return narrationData
    end
end

do
    local DEFAULT_LEFT_TEXT = GetString(SI_SCREEN_NARRATION_DIRECTIONAL_INPUT_PREVIOUS)
    local DEFAULT_RIGHT_TEXT = GetString(SI_SCREEN_NARRATION_DIRECTIONAL_INPUT_NEXT)

    local DEFAULT_DOWN_TEXT = GetString(SI_SCREEN_NARRATION_DIRECTIONAL_INPUT_PREVIOUS)
    local DEFAULT_UP_TEXT = GetString(SI_SCREEN_NARRATION_DIRECTIONAL_INPUT_NEXT)

    --Helper function for getting keybind narration info specifically for horizontal directional input. 
    --If nothing is specified for leftText or rightText, we will fall back to "Previous" and "Next" respectively
    --If nothing is specified for leftEnabled or rightEnabled, we will fall back to true
    function ZO_GetHorizontalDirectionalInputNarrationData(leftText, rightText, leftEnabled, rightEnabled)
        local leftInfo =
        {
            text = leftText or DEFAULT_LEFT_TEXT,
            enabled = leftEnabled == nil and true or leftEnabled,
        }

        local rightInfo =
        {
            text = rightText or DEFAULT_RIGHT_TEXT,
            enabled = rightEnabled == nil and true or rightEnabled,
        }
        return ZO_GetDirectionalInputNarrationData(leftInfo, rightInfo)
    end

    --Helper function for getting keybind narration info specifically for vertical directional input. 
    --If nothing is specified for upText or downText, we will fall back to "Next" and "Previous" respectively
    --If nothing is specified for upEnabled or downEnabled, we will fall back to true
    function ZO_GetVerticalDirectionalInputNarrationData(upText, downText, upEnabled, downEnabled)
        local upInfo =
        {
            text = upText or DEFAULT_UP_TEXT,
            enabled = upEnabled == nil and true or upEnabled,
        }

        local downInfo =
        {
            text = downText or DEFAULT_DOWN_TEXT,
            enabled = downEnabled == nil and true or downEnabled,
        }

        local NO_LEFT_INFO = nil
        local NO_RIGHT_INFO = nil
        return ZO_GetDirectionalInputNarrationData(NO_LEFT_INFO, NO_RIGHT_INFO, upInfo, downInfo)
    end

    --Helper function for getting keybind narration info specifically for combined vertical and horizontal directional input.
    --If nothing is specified for the text values, the corresponding keybind will have no name
    --If nothing is specified for the enabled values, we will fall back to true
    function ZO_GetCombinedDirectionalInputNarrationData(leftText, rightText, upText, downText, leftEnabled, rightEnabled, upEnabled, downEnabled)
        local leftInfo =
        {
            text = leftText,
            enabled = leftEnabled == nil and true or leftEnabled,
        }

        local rightInfo =
        {
            text = rightText,
            enabled = rightEnabled == nil and true or rightEnabled,
        }

        local upInfo =
        {
            text = upText,
            enabled = upEnabled == nil and true or upEnabled,
        }

        local downInfo =
        {
            text = downText,
            enabled = downEnabled == nil and true or downEnabled,
        }

        return ZO_GetDirectionalInputNarrationData(leftInfo, rightInfo, upInfo, downInfo)
    end
end

--Helper function for getting keybind narration info specifically for horizontal directional input for elements that are numeric in nature.
--If leftEnabled or rightEnabled are not specified, we will assume enabled is true
function ZO_GetNumericHorizontalDirectionalInputNarrationData(leftEnabled, rightEnabled)
    return ZO_GetHorizontalDirectionalInputNarrationData(GetString(SI_SCREEN_NARRATION_DIRECTIONAL_INPUT_DECREASE), GetString(SI_SCREEN_NARRATION_DIRECTIONAL_INPUT_INCREASE), leftEnabled, rightEnabled)
end

--Helper function for getting keybind narration info specifically for vertical directional input for elements that are numeric in nature.
--If upEnabled or downEnabled are not specified, we will assume enabled is true
function ZO_GetNumericVerticalDirectionalInputNarrationData(upEnabled, downEnabled)
    return ZO_GetVerticalDirectionalInputNarrationData(GetString(SI_SCREEN_NARRATION_DIRECTIONAL_INPUT_INCREASE), GetString(SI_SCREEN_NARRATION_DIRECTIONAL_INPUT_DECREASE), upEnabled, downEnabled)
end