ZO_AccessibleAssignableUtilityWheel_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_AccessibleAssignableUtilityWheel_Gamepad:Initialize(control)
    self.control = control
    GAMEPAD_ACCESSIBLE_ASSIGNABLE_UTILITY_WHEEL_SCENE = ZO_Scene:New("gamepadAccessibleAssignableUtilityWheel", SCENE_MANAGER)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, GAMEPAD_ACCESSIBLE_ASSIGNABLE_UTILITY_WHEEL_SCENE)

    self.headerData =
    {
        titleText = GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN),
        subtitleText = function()
            local hotbarCategory = self.wheel:GetHotbarCategory()
            if hotbarCategory ~= ZO_UTILITY_WHEEL_HOTBAR_CATEGORY_HIDDEN then
                return GetString("SI_HOTBARCATEGORY", hotbarCategory)
            else
                return ""
            end
        end,
        messageText = function()
            return self.wheel:GetPendingName()
        end,
    }

    self:InitializeUtilityWheel()
    self:RefreshHeader()
    self:RegisterForEvents()
end

function ZO_AccessibleAssignableUtilityWheel_Gamepad:RegisterForEvents()
    local function OnSlotUpdated(eventCode, physicalSlot, hotbarCategory)
        if self.wheel:GetHotbarCategory() == hotbarCategory then
            self:Update()
            if self:IsShowing() then
                SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self:GetCurrentList())
            end
        end
    end
    self.control:RegisterForEvent(EVENT_HOTBAR_SLOT_UPDATED, OnSlotUpdated)

    self.control:RegisterForEvent(EVENT_PERSONALITY_CHANGED, function()
        --This event is only relevant if the wheel supports emotes
        if self.wheel:IsActionTypeSupported(ACTION_TYPE_EMOTE) then
            self:Update()
        end
    end)
end

function ZO_AccessibleAssignableUtilityWheel_Gamepad:InitializeUtilityWheel()
    self.wheelControl = self.control:GetNamedChild("QuickslotWheel")
    local wheelData =
    {
        hotbarCategories = { HOTBAR_CATEGORY_QUICKSLOT_WHEEL },
        numSlots = ACTION_BAR_UTILITY_BAR_SIZE,
        showPendingIcon = true,
        showCategoryLabel = true,
        --Do not show name labels on the wheel
        overrideShowNameLabels = false,
        --Display the accessibility keybinds on the wheel
        showKeybinds = true,
        --Do not activate the radial menu on showing to prevent it from accepting directional input
        overrideActivateOnShow = false,
        --We do not need to disable tooltip scrolling in any circumstances for this wheel
        overrideTooltipScrollEnabled = true,
        --Use the right tooltip instead of the default GAMEPAD_QUAD1_TOOLTIP
        overrideGamepadTooltip = GAMEPAD_RIGHT_TOOLTIP,
        onHotbarCategoryChangedCallback = function()
            self:Update()
            if self:IsShowing() then
                --Re-narrate the header if the hotbar category changed
                local NARRATE_HEADER = true
                SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self:GetCurrentList(), NARRATE_HEADER)
            end
        end,
    }
    self.wheel = ZO_AssignableUtilityWheel_Gamepad:New(self.wheelControl, wheelData)
end

function ZO_AccessibleAssignableUtilityWheel_Gamepad:Show(hotbarCategories)
    self.wheel:SetHotbarCategories(hotbarCategories)
    self:Update()
    SCENE_MANAGER:Push("gamepadAccessibleAssignableUtilityWheel")
end

function ZO_AccessibleAssignableUtilityWheel_Gamepad:RefreshHeader()
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_AccessibleAssignableUtilityWheel_Gamepad:SetPendingItem(bagId, slotIndex)
    self.wheel:SetPendingItem(bagId, slotIndex)
end

function ZO_AccessibleAssignableUtilityWheel_Gamepad:SetPendingSimpleAction(slotType, actionId)
    self.wheel:SetPendingSimpleAction(slotType, actionId)
end

-- Parametric scroll list overrides
function ZO_AccessibleAssignableUtilityWheel_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = 
    {
        {
            name = GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN),
            keybind = "UI_SHORTCUT_PRIMARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            visible = function()
                return self.wheel:GetSelectedRadialEntry() ~= nil
            end,
            callback = function()
                self.wheel:TryAssignPendingToSelectedEntry()
            end,
        }
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_AccessibleAssignableUtilityWheel_Gamepad:SetupList(list)
    ZO_Gamepad_ParametricList_Screen.SetupList(self, list)
    local function EntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        --First unregister for binding updates so we don't accidentally double register
        ZO_Keybindings_UnregisterLabelForBindingUpdate(control.keybindLabel)

        local actionName = ZO_GetRadialMenuActionNameForOrdinalIndex(data.ordinalIndex)
        if actionName then
            ZO_Keybindings_RegisterLabelForBindingUpdate(control.keybindLabel, actionName)
        end
    end
    list:AddDataTemplate("ZO_AccessibleAssignableUtilityWheel_Gamepad_MenuEntryTemplate", EntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "Slot")
    local function OnSelectedDataChangedCallback(innerList, selectedData)
        --Set the wheel selection to match the parametric list selection
        self.wheel:SetSelectedRadialEntry(selectedData)
    end
    list:SetOnSelectedDataChangedCallback(OnSelectedDataChangedCallback)
end


function ZO_AccessibleAssignableUtilityWheel_Gamepad:OnShowing()
    --Order matters. Show the wheel first so the information is updated before we try to perform an update
    self.wheel:Show()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
end

function ZO_AccessibleAssignableUtilityWheel_Gamepad:OnHide()
    ZO_Gamepad_ParametricList_Screen.OnHide(self)
    self.wheel:Hide()
end

function ZO_AccessibleAssignableUtilityWheel_Gamepad:PerformUpdate()
    self:RefreshHeader()

    local list = self:GetMainList()
    list:Clear()

    local function GetSlotEntryNarrationText(entryData, entryControl)
        local narrations = {}
        -- Generate the standard parametric list entry narration
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

        --Generate the narration for the keybind
        local actionName = ZO_GetRadialMenuActionNameForOrdinalIndex(entryData.ordinalIndex)
        local bindingTextNarration = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction(actionName) or GetString(SI_ACTION_IS_NOT_BOUND)
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(bindingTextNarration))

        return narrations
    end

    --Iterate through each ordinal entry in the wheel and add it to the parametric list
    self.wheel:ForEachOrdinalEntry(function(ordinalIndex, entry)
        local slotData = entry.data
        local entryData = ZO_GamepadEntryData:New(zo_strformat(SI_UTILITY_WHEEL_SLOT_FORMATTER, ordinalIndex))
        entryData:AddIcon(slotData.icon)
        entryData:AddSubLabel(slotData.name)
        entryData.slotIndex = slotData.slotIndex
        entryData.ordinalIndex = ordinalIndex
        entryData.narrationText = GetSlotEntryNarrationText
        list:AddEntry("ZO_AccessibleAssignableUtilityWheel_Gamepad_MenuEntryTemplate", entryData)
    end)

    list:Commit()
end

-- Global UI

function ZO_AccessibleAssignableUtilityWheelTopLevel_Gamepad_OnInitialized(control)
    ACCESSIBLE_ASSIGNABLE_UTILITY_WHEEL_GAMEPAD = ZO_AccessibleAssignableUtilityWheel_Gamepad:New(control)
end

function ZO_AccessibleAssignableUtilityWheel_Gamepad_MenuEntryTemplate_OnInitialized(control)
    ZO_SharedGamepadEntry_OnInitialized(control)
    ZO_SharedGamepadEntry_SetHeightFromLabels(control)
    control.keybindLabel = control:GetNamedChild("Keybind")
end