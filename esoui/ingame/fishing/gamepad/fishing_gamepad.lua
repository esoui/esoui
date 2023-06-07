ZO_Fishing_Gamepad = ZO_Fishing:Subclass()

function ZO_Fishing_Gamepad:Initialize(...)
    ZO_Fishing.Initialize(self, ...)
    self:InitializeNarrationInfo()
end

function ZO_Fishing_Gamepad:InitializeNarrationInfo()
    local narrationInfo =
    {
        canNarrate = function()
            return self:IsInteracting()
        end,
        selectedNarrationFunction = function()
            local narrations = {}
            local selectedEntry = self.menu.selectedEntry
            if selectedEntry then
                local name = selectedEntry.name
                if type(name) == "table" then
                    name = name[1]
                end
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(name))
            end
            return narrations
        end,
        headerNarrationFunction = function()
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_FISHING_WHEEL_NARRATION))
        end,
        additionalInputNarrationFunction = function()
            local narrationData = {}
            if self.menu:ShouldShowKeybinds() then
                self.menu:ForEachOrdinalEntry(function(ordinalIndex, entry)
                    local actionName = ZO_GetRadialMenuActionNameForOrdinalIndex(ordinalIndex)
                    local name = entry.name
                    if type(name) == "table" then
                        name = name[1]
                    end

                    local entryNarrationData =
                    {
                        name = name,
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
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("FishingWheelHUD", narrationInfo)
end

function ZO_Fishing_Gamepad:OnSelectionChangedCallback(selectedEntry)
    ZO_Fishing.OnSelectionChangedCallback(self, selectedEntry)
    --Re-narrate on selection changed
    if selectedEntry then
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("FishingWheelHUD")
    end
end

function ZO_Fishing_Gamepad:ShowMenu()
    ZO_Fishing.ShowMenu(self)
    --Narrate the header when first showing
    local NARRATE_HEADER = true
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("FishingWheelHUD", NARRATE_HEADER)
end

function ZO_Fishing_Gamepad:StopInteraction(...)
    local wasShowing = ZO_Fishing.StopInteraction(self, ...)
    if wasShowing then
        --Clear out any in progress HUD narration when exiting the wheel
        ClearNarrationQueue(NARRATION_TYPE_HUD)
    end
    return wasShowing
end

function ZO_Fishing_Gamepad_Initialize(control)
    FISHING_GAMEPAD = ZO_Fishing_Gamepad:New(control, "ZO_GamepadSelectableItemRadialMenuEntryTemplate", "DefaultRadialMenuAnimation", "SelectableItemRadialMenuEntryAnimation")
end