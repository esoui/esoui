ZO_TargetMarkerWheel_Gamepad = ZO_TargetMarkerWheel_Shared:Subclass()

function ZO_TargetMarkerWheel_Gamepad:Initialize(...)
    ZO_TargetMarkerWheel_Shared.Initialize(self, ...)
    self:InitializeNarrationInfo()
end

function ZO_TargetMarkerWheel_Gamepad:InitializeNarrationInfo()
    local narrationInfo =
    {
        canNarrate = function()
            return self:IsInteracting()
        end,
        selectedNarrationFunction = function()
            local narrations = {}
            local selectedEntry = self.menu.selectedEntry
            if selectedEntry then
                local targetMarkerType = selectedEntry.data
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_TARGETMARKERTYPE", targetMarkerType)))
            end
            return narrations
        end,
        headerNarrationFunction = function()
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_TARGET_MARKER_WHEEL_NARRATION))
        end,
        additionalInputNarrationFunction = function()
            local narrationData = {}
            if self.menu:ShouldShowKeybinds() then
                self.menu:ForEachOrdinalEntry(function(ordinalIndex, entry)
                    local actionName = ZO_GetRadialMenuActionNameForOrdinalIndex(ordinalIndex)
                    local targetMarkerType = entry.data

                    local entryNarrationData =
                    {
                        name = GetString("SI_TARGETMARKERTYPE", targetMarkerType),
                        keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction(actionName) or GetString(SI_ACTION_IS_NOT_BOUND),
                        enabled = true,
                    }

                    table.insert(narrationData, entryNarrationData)
                end)
            end

            return narrationData
        end,
        narrationType = NARRATION_TYPE_HUD,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("TargetMarkerWheelHUD", narrationInfo)
end

function ZO_TargetMarkerWheel_Gamepad:OnSelectionChangedCallback(selectedEntry)
    ZO_TargetMarkerWheel_Shared.OnSelectionChangedCallback(self, selectedEntry)
    --Re-narrate on selection changed
    if selectedEntry then
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("TargetMarkerWheelHUD")
    end
end

function ZO_TargetMarkerWheel_Gamepad:ShowMenu()
    ZO_TargetMarkerWheel_Shared.ShowMenu(self)
    --Narrate the header when first showing
    local NARRATE_HEADER = true
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("TargetMarkerWheelHUD", NARRATE_HEADER)
end

function ZO_TargetMarkerWheel_Gamepad:StopInteraction(...)
    local wasShowing = ZO_TargetMarkerWheel_Shared.StopInteraction(self, ...)
    if wasShowing then
        --Clear out any in progress HUD narration when exiting the wheel
        ClearNarrationQueue(NARRATION_TYPE_HUD)
    end
    return wasShowing
end

function ZO_TargetMarkerWheel_Gamepad_Initialize(control)
    TARGET_MARKER_WHEEL_GAMEPAD = ZO_TargetMarkerWheel_Gamepad:New(control, "ZO_TargetMarkerWheelMenuEntryTemplate_Gamepad", "DefaultRadialMenuAnimation", "SelectableItemRadialMenuEntryAnimation")
end