--[[ Template Initialization and Setup Functions ]]--

-- Text Edit
function ZO_PregameGamepadTextEditTemplate_OnInitialized(control)
    control.backdrop = control:GetNamedChild("Backdrop")
    if control.backdrop ~= nil then
        control.edit = control.backdrop:GetNamedChild("Edit")
        control.highlight = control.backdrop:GetNamedChild("Highlight")
    end

    control.text = control:GetNamedChild("Label")
end

function ZO_PregameGamepadTextEditTemplate_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    control.contentsChangedCallback = data.contentsChangedCallback

    if data.textType ~= nil then
        control.edit:SetTextType(data.textType)
    end

    if data.contents then
        local contents = data.contents
        if type(contents) == "function" then
            contents = contents(data)
        end
        if contents then
            control.edit:SetText(contents)
        end
    end

    if control.focusedChangedAnimation == nil then
        control.focusedChangedAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("GamepadMenuEntryFocusedAnimation", control.highlight)
    end
    local focusChanged = (control.focused ~= selected)
    control.focused = selected

    if focusChanged then
        if control.focused then
            control.focusedChangedAnimation:PlayForward()
        else
            control.focusedChangedAnimation:PlayBackward()
        end

        control.highlight:SetHidden(not control.focused)
    end
end

function ZO_PregameGamepadTextEditTemplate_OnPossibleChange(control, textEdit, newText)
    local callback = textEdit.contentsChangedCallback
    if callback then
        callback(newText)
    end
end

-- Button with Icon
function ZO_PregameGamepadButtonWithIconAndTextTemplate_OnInitialized(control)
    control.text = control:GetNamedChild("Label")
    control.label = control.text -- Gamepad templates expects this to be called label

    control.icon = control:GetNamedChild("Icon")
end