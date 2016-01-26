function ZO_DyeingSavedSlot_Gamepad_Initialize(control)
    control.multiFocusControl = control:GetNamedChild("Dyes")
    control.dyeControls = control.multiFocusControl.dyeControls
    control.singleFocusControl = control.dyeControls[1]
    control.highlight = control:GetNamedChild("SharedHighlight")
    control.switchIcon = control:GetNamedChild("SwitchIcon")

    control.dyeSelector = ZO_GamepadFocus:New(control, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    control.dyeSelector:SetFocusChangedCallback(function(entry) ZO_Dyeing_Gamepad_Highlight(control, entry and entry.control) end)
    for i=1, #control.dyeControls do
        local dyeControl = control.dyeControls[i]
        local entry = {
                        control = dyeControl,
                        slotIndex = i,
                    }
        control.dyeSelector:AddEntry(entry)
    end

    control.Activate = function(control, retainFocus)
                if not retainFocus then
                    control.dyeSelector:SetFocusByIndex(1)
                end
                control.dyeSelector:Activate(retainFocus)
            end

    control.Deactivate = function(control, ...)
                control.dyeSelector:Deactivate(...)
            end
end
