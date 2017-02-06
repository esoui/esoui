local SWAP_SAVED_ICON = "EsoUI/Art/Dye/GamePad/Dye_set_icon.dds"

ZO_Dyeing_Slots_Gamepad = ZO_Dyeing_RadialMenu_Gamepad:Subclass()

function ZO_Dyeing_Slots_Gamepad:New(control, sharedHighlight)
    local dyeableSlotMenu = ZO_Dyeing_RadialMenu_Gamepad.New(self, control, "ZO_DyeingSlot_Gamepad", sharedHighlight)
    dyeableSlotMenu.dyeableSlotSetupFunction = function(...) dyeableSlotMenu:SetupDyeableSlot(...) end
    return dyeableSlotMenu
end

function ZO_Dyeing_Slots_Gamepad:SetupDyeableSlot(control, data)
    local dyeableSlot = data.dyeableSlot
    self.controlsBySlot[dyeableSlot] = control
	control.onSelectionChangedCallback = self.onSelectionChangedCallback
    ZO_Dyeing_SetupDyeableSlotControl(control.slot, dyeableSlot)
    ZO_Dyeing_RefreshDyeableSlotControlDyes(control, dyeableSlot)
end

function ZO_Dyeing_Slots_Gamepad:Populate()
    self:ResetData()

    local activeDyeableSlot = ZO_Dyeing_GetActiveOffhandDyeableSlot()
    local slotsByMode = ZO_Dyeing_GetSlotsForMode(self.mode)
    for i=1, #slotsByMode do
        local dyeableSlotData = slotsByMode[i]
        local dyeableSlot = dyeableSlotData.dyeableSlot

        if (dyeableSlot ~= DYEABLE_SLOT_OFF_HAND and dyeableSlot ~= DYEABLE_SLOT_BACKUP_OFF) 
            or dyeableSlot == activeDyeableSlot then

            local data = {
                    dyeableSlot = dyeableSlot,
                    setupFunc = self.dyeableSlotSetupFunction,
                }
            self:AddEntry(nil, nil, nil, nil, data)
        end
    end

    self:Refresh()
end

function ZO_Dyeing_Slots_Gamepad:SetMode(mode)
    self.mode = mode
end

function ZO_Dyeing_Slots_Gamepad:SetSelectionChangedCallback(callback)
    self.onSelectionChangedCallback = callback
end

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