
ZO_ArmorySkillsActionBar = ZO_InitializingCallbackObject:Subclass()

function ZO_ArmorySkillsActionBar:Initialize(control)
    self.control = control
    self.slots = {}
    control.object = self
    self.locked = false

    for i = 1, ACTION_BAR_SLOTS_PER_PAGE - 1 do
        local slot = ZO_ArmorySkillsActionBarSlot:New(control:GetNamedChild("Button" .. i), self, ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + i)
        table.insert(self.slots, slot)
    end

    local ultimateSlot = ZO_ArmorySkillsActionBarSlot:New(control:GetNamedChild("UltimateButton"), self, ACTION_BAR_ULTIMATE_SLOT_INDEX + 1)
    table.insert(self.slots, ultimateSlot)

    self:ResetAllSlots()

    local function OnLevelUpdate(_, unitTag, level)
        self:RefreshLockedState()
    end

    self.control:RegisterForEvent(EVENT_LEVEL_UPDATE, OnLevelUpdate)
    self.control:AddFilterForEvent(EVENT_LEVEL_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
end

function ZO_ArmorySkillsActionBar:SetHotbarCategory(hotbarCategory)
    if hotbarCategory == nil or ZO_ARMORY_MANAGER:GetSkillsHotBarCategories()[hotbarCategory] then
        if hotbarCategory ~= self.hotbarCategory then
            self.hotbarCategory = hotbarCategory
            self:RefreshLockedState()
        end
    else
        internalassert(false, "The armory skills action bar does not support this hotbar category")
    end
end

function ZO_ArmorySkillsActionBar:GetHotbarCategory()
    return self.hotbarCategory
end

function ZO_ArmorySkillsActionBar:ResetAllSlots()
    for _, slot in ipairs(self.slots) do
        slot:Reset()
    end
end

function ZO_ArmorySkillsActionBar:AssignArmoryBuildData(buildData)
    self.buildData = buildData
    self:ResetAllSlots()
end

function ZO_ArmorySkillsActionBar:GetLinkedArmoryBuildData()
    return self.buildData
end

function ZO_ArmorySkillsActionBar:RefreshLockedState()
    local locked = self.hotbarCategory == HOTBAR_CATEGORY_BACKUP and GetUnitLevel("player") < GetWeaponSwapUnlockedLevel()

    if locked ~= self.locked then
        self.locked = locked
        for _, slot in ipairs(self.slots) do
            slot:SetLocked(self.locked)
        end
    end
end

function ZO_ArmorySkillsActionBar:GetLocked()
    return self.locked
end

function ZO_ArmorySkillsActionBar:AddSlotsToMouseInputGroup(inputGroup, inputType)
    for _, slot in ipairs(self.slots) do
        slot:AddToMouseInputGroup(inputGroup, inputType)
    end
end

function ZO_ArmorySkillsActionBar:GetNarrationText()
    local narrations = {}
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_GAMEPAD_ARMORY_SKILL_BAR_FORMATTER, GetString("SI_HOTBARCATEGORY", self.hotbarCategory))))
    if self:GetLocked() then
        --If the bar is locked, just narrate that it's locked, and don't bother narrating the individual slots
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_SCREEN_NARRATION_LOCKED_ICON_NARRATION)))
    else
        --Get the narration for each slot
        for _, slot in ipairs(self.slots) do
            ZO_AppendNarration(narrations, slot:GetNarrationText())
        end
    end
    return narrations
end

ZO_ArmorySkillsActionBarSlot = ZO_InitializingObject:Subclass()

function ZO_ArmorySkillsActionBarSlot:Initialize(control, actionBar, actionSlotIndex)
    self.control = control
    self.control.owner = self
    self.button = self.control:GetNamedChild("Button")
    self.keybindLabel = control:GetNamedChild("KeybindLabel")
    self.bar = actionBar
    self.slotIndex = actionSlotIndex
end

function ZO_ArmorySkillsActionBarSlot:Reset()
    self.buildData = self.bar:GetLinkedArmoryBuildData()
    self.skillProgressionData = self:GetSavedSkillData()
    self:Refresh()
end

function ZO_ArmorySkillsActionBarSlot:GetSavedSkillData()
    local hotbarCategory = self.bar:GetHotbarCategory()
    if self.buildData and hotbarCategory then
        local abilityId = self.buildData:GetSlottedAbilityId(self.slotIndex, hotbarCategory)
        return SKILLS_DATA_MANAGER:GetProgressionDataByAbilityId(abilityId)
    end
    return nil
end

function ZO_ArmorySkillsActionBarSlot:Refresh()
    if self.skillProgressionData then
        self.control.abilityIcon:SetTexture(self.skillProgressionData:GetIcon())
        self.control.abilityIcon:SetHidden(false)
    else
        self.control.abilityIcon:SetHidden(true)
    end

    if self.keybindLabel then
        local currentHotbarCategory = self.bar:GetHotbarCategory()
        local keyboardActionName, gamepadActionName = ACTION_BAR_ASSIGNMENT_MANAGER:GetKeyboardAndGamepadActionNameForSlot(self.slotIndex, currentHotbarCategory)
        local actionPriority = ACTION_BAR_ASSIGNMENT_MANAGER:GetAutomaticCastPriorityForSlot(self.slotIndex, currentHotbarCategory)
        if gamepadActionName ~= self.actionName or actionPriority ~= self.actionPriority then
            ZO_Keybindings_UnregisterLabelForBindingUpdate(self.keybindLabel)
            if gamepadActionName then
                local HIDE_UNBOUND = false
                ZO_Keybindings_RegisterLabelForBindingUpdate(self.keybindLabel, keyboardActionName, HIDE_UNBOUND, gamepadActionName)
            elseif actionPriority then
                self.keybindLabel:SetText(tostring(actionPriority))
            else
                self.keybindLabel:SetText("")
            end
            self.actionName = gamepadActionName
            self.actionPriority = actionPriority
        end
    end
end

function ZO_ArmorySkillsActionBarSlot:SetLocked(locked)
    self.control.lockIcon:SetHidden(not locked)
end

function ZO_ArmorySkillsActionBarSlot:AddToMouseInputGroup(inputGroup, inputType)
    if self.button then
        inputGroup:Add(self.button, inputType)
    end
end

function ZO_ArmorySkillsActionBarSlot:OnMouseEnter()
    ClearTooltip(SkillTooltip)
    if self.skillProgressionData then
        InitializeTooltip(SkillTooltip, self.control, BOTTOM, 0, -5, TOP)
        self.skillProgressionData:SetKeyboardTooltip(SkillTooltip)
    end
end

function ZO_ArmorySkillsActionBarSlot:OnMouseExit()
    ClearTooltip(SkillTooltip)
end

do
    local NOT_BOUND_ACTION_STRING = GetString(SI_ACTION_IS_NOT_BOUND)
    local DEFAULT_SHOW_AS_HOLD = nil

    function ZO_ArmorySkillsActionBarSlot:GetNarrationText()
        local narrations = {}

        --Get the binding narration
        local keyboardActionName, gamepadActionName = ACTION_BAR_ASSIGNMENT_MANAGER:GetKeyboardAndGamepadActionNameForSlot(self.slotIndex, self.bar:GetHotbarCategory())
        local bindingTextNarration = ZO_Keybindings_GetPreferredHighestPriorityNarrationStringFromActions(keyboardActionName, gamepadActionName, DEFAULT_SHOW_AS_HOLD) or NOT_BOUND_ACTION_STRING
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(bindingTextNarration))
        
        --Get the narration for the contents of the slot
        if self.skillProgressionData then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.skillProgressionData:GetFormattedName()))
        else
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_ARMORY_EMPTY_ENTRY_NARRATION)))
        end
        return narrations
    end
end

function ZO_ArmoryActionButton_Keyboard_OnMouseEnter(control)
    control.owner:OnMouseEnter()
end

function ZO_ArmoryActionButton_Keyboard_OnMouseExit(control)
    control.owner:OnMouseExit()
end