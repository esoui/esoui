local SWAP_SAVED_ICON = "EsoUI/Art/Dye/GamePad/Dye_set_icon.dds"

-- XML functions --
-------------------

function ZO_DyeingSlot_Gamepad_Initialize(control)
    control.slot = control:GetNamedChild("Slot")
    control.multiFocusControl = control:GetNamedChild("Dyes")
    control.dyeControls = control.multiFocusControl.dyeControls
    control.singleFocusControl = control.dyeControls[1]
    control.highlight = control:GetNamedChild("SharedHighlight")

    control.dyeSelector = ZO_GamepadFocus:New(control, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    
    for i=1, #control.dyeControls do
        local dyeControl = control.dyeControls[i]
        local entry = {
                        control = dyeControl,
                        slotIndex = i,
                        iconScaleAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_DyeingSlot_Gamepad_FocusScaleAnimation", dyeControl),
                    }
        control.dyeSelector:AddEntry(entry)
    end

    control.Activate = function(control, ...)
                control.dyeSelector:SetFocusByIndex(1)
                control.dyeSelector:Activate(...)
            end

    control.Deactivate = function(control, ...)
                control.dyeSelector:Deactivate(...)
            end

    local function OnSelectionChanged(entry)
        ZO_Dyeing_Gamepad_Highlight(control, entry and entry.control)
        if control.onSelectionChangedCallback then
            control.onSelectionChangedCallback()
        end
    end

    control.dyeSelector:SetFocusChangedCallback(OnSelectionChanged)
end