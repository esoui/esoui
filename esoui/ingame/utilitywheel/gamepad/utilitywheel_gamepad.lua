ZO_UtilityWheel_Gamepad = ZO_UtilityWheel_Shared:Subclass()

local USE_LEADING_EDGE = true
local COOLDOWN_DESATURATION = 1
local COOLDOWN_ALPHA = 1
local DONT_PRESERVE_PREVIOUS_COOLDOWN = false

function ZO_UtilityWheel_Gamepad:Initialize(...)
    ZO_UtilityWheel_Shared.Initialize(self, ...)
    ZO_Keybindings_RegisterLabelForBindingUpdate(self.cycleLeftKeybindLabel, "UTILITY_WHEEL_GAMEPAD_CYCLE_LEFT")
    ZO_Keybindings_RegisterLabelForBindingUpdate(self.cycleRightKeybindLabel, "UTILITY_WHEEL_GAMEPAD_CYCLE_RIGHT")
    self:InitializeNarrationInfo()
end

function ZO_UtilityWheel_Gamepad:InitializeNarrationInfo()
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
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_HOTBARCATEGORY", self:GetHotbarCategory()))
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

            local cycleLeftNarrationData =
            {
                name = GetString("SI_HOTBARCATEGORY", self:GetPreviousHotbarCategory()),
                keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction("UTILITY_WHEEL_GAMEPAD_CYCLE_LEFT") or GetString(SI_ACTION_IS_NOT_BOUND),
                enabled = true,
            }
            table.insert(narrationData, cycleLeftNarrationData)

            local cycleRightNarrationData =
            {
                name = GetString("SI_HOTBARCATEGORY", self:GetNextHotbarCategory()),
                keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction("UTILITY_WHEEL_GAMEPAD_CYCLE_RIGHT") or GetString(SI_ACTION_IS_NOT_BOUND),
                enabled = true,
            }
            table.insert(narrationData, cycleRightNarrationData)

            return narrationData
        end,
        narrationType = NARRATION_TYPE_HUD,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("UtilityWheelHUD", narrationInfo)
end

function ZO_UtilityWheel_Gamepad:SetupEntryControl(entryControl, data)
    ZO_UtilityWheel_Shared.SetupEntryControl(self, entryControl, data)
    ZO_GamepadUtilityWheelCooldownSetup(entryControl, data.slotNum, self:GetHotbarCategory())
end

function ZO_UtilityWheel_Gamepad:OnSelectionChangedCallback(selectedEntry)
    ZO_UtilityWheel_Shared.OnSelectionChangedCallback(self, selectedEntry)
    --Re-narrate on selection changed
    if selectedEntry then
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("UtilityWheelHUD")
    end
end

function ZO_UtilityWheel_Gamepad:ShowMenu()
    ZO_UtilityWheel_Shared.ShowMenu(self)
    --Narrate the header when first showing
    local NARRATE_HEADER = true
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("UtilityWheelHUD", NARRATE_HEADER)
end

function ZO_UtilityWheel_Gamepad:StopInteraction(...)
    local wasShowing = ZO_UtilityWheel_Shared.StopInteraction(self, ...)
    if wasShowing then
        --Clear out any in progress HUD narration when exiting the wheel
        ClearNarrationQueue(NARRATION_TYPE_HUD)
    end
    return wasShowing
end

function ZO_GamepadUtilityWheelCooldownSetup(control, slotNum, hotbarCategory)
    local remaining, duration = GetSlotCooldownInfo(slotNum, hotbarCategory)
    control.cooldown:SetVerticalCooldownLeadingEdgeHeight(4)
    control.cooldown:SetTexture(GetSlotTexture(slotNum, hotbarCategory))
    control.cooldown:SetFillColor(ZO_SELECTED_TEXT:UnpackRGBA())
    ZO_SharedGamepadEntry_Cooldown(control, remaining, duration, CD_TYPE_VERTICAL_REVEAL, CD_TIME_TYPE_TIME_UNTIL, USE_LEADING_EDGE, COOLDOWN_DESATURATION, COOLDOWN_ALPHA, DONT_PRESERVE_PREVIOUS_COOLDOWN)
end

function ZO_UtilityWheel_Gamepad_Initialize(control)
    local actionLayers = { "RadialMenu", GetString(SI_KEYBINDINGS_LAYER_UTILITY_WHEEL) }
    UTILITY_WHEEL_GAMEPAD = ZO_UtilityWheel_Gamepad:New(control, "ZO_UtilityWheelMenuEntryTemplate_Gamepad", "DefaultRadialMenuAnimation", "SelectableItemRadialMenuEntryAnimation", actionLayers)
end