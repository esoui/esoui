-----------------------------
-- Skills Action Bar Slot
-----------------------------

ZO_SkillsActionBarSlot = ZO_InitializingObject:Subclass()

function ZO_SkillsActionBarSlot:Initialize(control, actionBar, actionSlotIndex)
    self.control = control
    self.control.owner = self
    self.button = self.control:GetNamedChild("Button")
    self.keybindLabel = self.control:GetNamedChild("KeybindLabel")
    self.actionBar = actionBar
    self.slotIndex = actionSlotIndex

    self:Reset()
end

function ZO_SkillsActionBarSlot:Reset()
    self.skillsData = self.actionBar:GetLinkedSkillsData()
    self.skillProgressionData = self:GetSavedSkillData()
    self:Refresh()
end

function ZO_SkillsActionBarSlot:GetSavedSkillData()
    local actionbarCategory = self.actionBar:GetHotbarCategory()
    if self.skillsData and actionbarCategory then
        local abilityId = self.skillsData:GetSlottedAbilityId(self.slotIndex, actionbarCategory)
        return SKILLS_DATA_MANAGER:GetProgressionDataByAbilityId(abilityId)
    end
    return nil
end

function ZO_SkillsActionBarSlot:Refresh()
    if self.skillProgressionData then
        self.control.abilityIcon:SetTexture(self.skillProgressionData:GetIcon())
        self.control.abilityIcon:SetHidden(false)
    else
        self.control.abilityIcon:SetHidden(true)
    end

    if self.keybindLabel then
        local currentActionBarCategory = self.actionBar:GetHotbarCategory()
        local keyboardActionName, gamepadActionName = ACTION_BAR_ASSIGNMENT_MANAGER:GetKeyboardAndGamepadActionNameForSlot(self.slotIndex, currentActionBarCategory)
        local actionPriority = ACTION_BAR_ASSIGNMENT_MANAGER:GetAutomaticCastPriorityForSlot(self.slotIndex, currentActionBarCategory)
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

function ZO_SkillsActionBarSlot:SetLocked(locked)
    self.control.lockIcon:SetHidden(not locked)
end

-----------------------------
-- Skills Action Bar - Class that builds a read only display of a skills action bar
-----------------------------

ZO_SkillsActionBar = ZO_InitializingCallbackObject:Subclass()

function ZO_SkillsActionBar:Initialize(control, slotClass)
    self.control = control
    self.slots = {}
    control.object = self
    self.locked = false

    for i = 1, ACTION_BAR_SLOTS_PER_PAGE - 1 do
        local slot = slotClass:New(control:GetNamedChild("Button" .. i), self, ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + i)
        table.insert(self.slots, slot)
    end

    local ultimateSlot = slotClass:New(control:GetNamedChild("UltimateButton"), self, ACTION_BAR_ULTIMATE_SLOT_INDEX + 1)
    table.insert(self.slots, ultimateSlot)

    local function OnLevelUpdate(_, unitTag, level)
        self:RefreshLockedState()
    end

    self.control:RegisterForEvent(EVENT_LEVEL_UPDATE, OnLevelUpdate)
    self.control:AddFilterForEvent(EVENT_LEVEL_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
end

do
    local SUPPORTED_SKILLS_HOTBAR_CATEGORIES =
    {
        [HOTBAR_CATEGORY_PRIMARY] = true,
        [HOTBAR_CATEGORY_BACKUP] = true,
    }
    function ZO_SkillsActionBar:GetSkillsHotBarCategories()
        return SUPPORTED_SKILLS_HOTBAR_CATEGORIES
    end

    function ZO_SkillsActionBar:SetHotbarCategory(hotbarCategory)
        if hotbarCategory == nil or self:GetSkillsHotBarCategories()[hotbarCategory] then
            if hotbarCategory ~= self.hotbarCategory then
                self.hotbarCategory = hotbarCategory
                self:RefreshLockedState()
            end
        else
            internalassert(false, "The skills action bar does not support this hotbar category")
        end
    end
end

function ZO_SkillsActionBar:GetHotbarCategory()
    return self.hotbarCategory
end

function ZO_SkillsActionBar:ResetAllSlots()
    for _, slot in ipairs(self.slots) do
        slot:Reset()
    end
end

-- skillsData should be a ZO_SkillsActionBarData and include an implementation of the function GetSlottedAbilityId(slotIndex, actionBarCategory)
function ZO_SkillsActionBar:AssignSkillsData(skillsData)
    internalassert(skillsData:IsInstanceOf(ZO_SkillsActionBarData))
    self.skillsData = skillsData
    self:ResetAllSlots()
end

function ZO_SkillsActionBar:GetLinkedSkillsData()
    return self.skillsData
end

function ZO_SkillsActionBar:RefreshLockedState()
    local locked = self.hotbarCategory == HOTBAR_CATEGORY_BACKUP and GetUnitLevel("player") < GetWeaponSwapUnlockedLevel()

    if locked ~= self.locked then
        self.locked = locked
        for _, slot in ipairs(self.slots) do
            slot:SetLocked(self.locked)
        end
    end
end

function ZO_SkillsActionBar:GetLocked()
    return self.locked
end

-----------------------------
-- Skills Action Bar Data
-----------------------------

ZO_SkillsActionBarData = ZO_InitializingObject:Subclass()

ZO_SkillsActionBarData:MUST_IMPLEMENT("GetSlottedAbilityId", slotIndex, actionBarCategory)