local SWAP_SAVED_ICON = "EsoUI/Art/Dye/GamePad/Dye_set_icon.dds"

ZO_Dyeing_Equipment_Gamepad = ZO_Dyeing_RadialMenu_Gamepad:Subclass()

function ZO_DyeingEquipSlot_Gamepad_Initialize(control)
    control.slot = control:GetNamedChild("Slot")
    control.multiFocusControl = control:GetNamedChild("Dyes")
    control.dyeControls = control.multiFocusControl.dyeControls
    control.singleFocusControl = control.dyeControls[1]
    control.highlight = control:GetNamedChild("SharedHighlight")

    control.dyeSelector = ZO_GamepadFocus:New(control, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    control.dyeSelector:SetFocusChangedCallback(function(entry) ZO_Dyeing_Gamepad_Highlight(control, entry and entry.control) end)
    
    for i=1, #control.dyeControls do
        local dyeControl = control.dyeControls[i]
        local entry = {
                        control = dyeControl,
                        slotIndex = i,
                        iconScaleAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_DyeingEquipSlot_Gamepad_FocusScaleAnimation", dyeControl),
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
end

function ZO_Dyeing_Equipment_Gamepad:New(control, sharedHighlight)
    local equipment = ZO_Dyeing_RadialMenu_Gamepad.New(self, control, "ZO_DyeingEquipSlot_Gamepad", sharedHighlight)
    equipment.equipmentSetupFunction = function(...) equipment:SetupEquipment(...) end
    return equipment
end

function ZO_Dyeing_Equipment_Gamepad:SetupEquipment(control, data)
    local equipSlot = data.equipSlot
    self.controlsBySlot[equipSlot] = control
    ZO_Dyeing_SetupEquipmentControl(control.slot, equipSlot)
    ZO_Dyeing_RefreshEquipControlDyes(control, equipSlot)
end

function ZO_Dyeing_Equipment_Gamepad:Populate()
    self:ResetData()

    local activeEquipSlot = ZO_Dyeing_GetActiveOffhandEquipSlot()
    for i=1, #ZO_DYEABLE_EQUIP_SLOTS_GAMEPAD_ORDER do
        local equipSlot = ZO_DYEABLE_EQUIP_SLOTS_GAMEPAD_ORDER[i]

        if (equipSlot ~= EQUIP_SLOT_OFF_HAND and equipSlot ~= EQUIP_SLOT_BACKUP_OFF) 
            or equipSlot == activeEquipSlot then

            local data = {
                    equipSlot = equipSlot,
                    setupFunc = self.equipmentSetupFunction,
                }
            self:AddEntry(nil, nil, nil, nil, data)
        end
    end

    self:Refresh()
end
