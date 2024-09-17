--[[
    The ActionBarAssignmentManager represents the the state of your skills on the AssignableActionBar, which is used inside the Skills UI.
    The skills UI is allowed to assign new skills without applying it to your "real" action bar, so this shouldn't be taken as the "truth" as the server sees it, but a pending state for the UI.
    This pending state is actually applied along with pending skill allocations inside of the SkillsAndActionBarManager.
]]--

-- These bars can be viewed inside of skills. This should be every bar used ingame.
internalassert(HOTBAR_CATEGORY_MAX_VALUE == 14, "Update hotbars")
local VIEWABLE_HOTBAR_CATEGORY_SET =
{
    [HOTBAR_CATEGORY_PRIMARY] = true,
    [HOTBAR_CATEGORY_BACKUP] = true,
    [HOTBAR_CATEGORY_OVERLOAD] = true,
    [HOTBAR_CATEGORY_WEREWOLF] = true,
    [HOTBAR_CATEGORY_TEMPORARY] = true,
    [HOTBAR_CATEGORY_DAEDRIC_ARTIFACT] = true,
    [HOTBAR_CATEGORY_COMPANION] = true,
}

-- These bars can be edited, and the server will persist those edits
internalassert(NUM_ASSIGNABLE_HOTBARS == 11, "Update hotbars")
local ASSIGNABLE_HOTBAR_CATEGORY_SET =
{
    [HOTBAR_CATEGORY_PRIMARY] = true,
    [HOTBAR_CATEGORY_BACKUP] = true,
    [HOTBAR_CATEGORY_OVERLOAD] = true,
    [HOTBAR_CATEGORY_WEREWOLF] = true,
    [HOTBAR_CATEGORY_COMPANION] = true,
}

-- These bars apply to the player, and hold player skills
local ASSIGNABLE_PLAYER_HOTBAR_CATEGORY_SET = ZO_ShallowTableCopy(ASSIGNABLE_HOTBAR_CATEGORY_SET)
ASSIGNABLE_PLAYER_HOTBAR_CATEGORY_SET[HOTBAR_CATEGORY_COMPANION] = nil

-- These bars have an associated weapon pair with them
local WEAPON_PAIR_HOTBAR_CATEGORY_SET = {}
for hotbarCategory in pairs(ASSIGNABLE_HOTBAR_CATEGORY_SET) do
    if GetWeaponPairFromHotbarCategory(hotbarCategory) ~= ACTIVE_WEAPON_PAIR_NONE then
        WEAPON_PAIR_HOTBAR_CATEGORY_SET[hotbarCategory] = true
    end
end

local HOTBAR_CYCLE_ORDER =
{
    HOTBAR_CATEGORY_PRIMARY,
    HOTBAR_CATEGORY_BACKUP,
    HOTBAR_CATEGORY_COMPANION,
    HOTBAR_CATEGORY_OVERLOAD,
    HOTBAR_CATEGORY_WEREWOLF,
    HOTBAR_CATEGORY_TEMPORARY,
    HOTBAR_CATEGORY_DAEDRIC_ARTIFACT,
}

-- these enums are 0-indexed for historical reasons, while the API that action bars actually use are 1-indexed.
-- we'll just convert them here instead of breaking addons that use the old indexes (which were already broken, anyways)
local SKILL_BAR_FIRST_NORMAL_SLOT_INDEX = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1
local SKILL_BAR_LAST_NORMAL_SLOT_INDEX = ACTION_BAR_ULTIMATE_SLOT_INDEX
local SKILL_BAR_ULTIMATE_SLOT_INDEX = ACTION_BAR_ULTIMATE_SLOT_INDEX + 1
local SKILL_BAR_START_SLOT_INDEX, SKILL_BAR_END_SLOT_INDEX = GetAssignableAbilityBarStartAndEndSlots()
--------------------------------
-- Slottable Action Interface --
--------------------------------

--[[
    A slottable action represents any action you can put into an ActionSlot from inside the Skills UI, which include:
    * the empty action (aka, this slot does nothing)
    * active skills
    * ultimates
    * raw abilities
    This does not include quickslots, which aren't shown and have their own handling someplace else.
]]--
ZO_SLOTTABLE_ACTION_TYPE_EMPTY = 1
ZO_SLOTTABLE_ACTION_TYPE_PLAYER_SKILL = 2
ZO_SLOTTABLE_ACTION_TYPE_ABILITY = 3
ZO_SLOTTABLE_ACTION_TYPE_COMPANION_SKILL = 4

ZO_BaseSlottableAction = ZO_InitializingObject:Subclass()

function ZO_BaseSlottableAction:GetSlottableActionType()
    assert(false, "override me")
end

function ZO_BaseSlottableAction:GetActionType()
    assert(false, "override me")
end

function ZO_BaseSlottableAction:GetActionId()
    assert(false, "override me")
end

function ZO_BaseSlottableAction:EqualsSlot(otherSlottableAction)
    assert(false, "override me")
end

function ZO_BaseSlottableAction:EqualsSkillData(skillData)
    assert(false, "override me")
end

-- This can return nil
function ZO_BaseSlottableAction:GetIcon()
    assert(false, "override me")
end

function ZO_BaseSlottableAction:IsUsable(hotbarCategory)
    assert(false, "override me")
end

function ZO_BaseSlottableAction:IsStillValid()
    assert(false, "override me")
end

function ZO_BaseSlottableAction:LayoutGamepadTooltip()
    assert(false, "override me")
end

-- This can return nil
function ZO_BaseSlottableAction:GetKeyboardTooltipControl()
    assert(false, "override me")
end

function ZO_BaseSlottableAction:SetKeyboardTooltip()
    assert(false, "override me")
end

function ZO_BaseSlottableAction:TryCursorPickup()
    assert(false, "override me")
end

function ZO_BaseSlottableAction:IsEmpty()
    return self:GetSlottableActionType() == ZO_SLOTTABLE_ACTION_TYPE_EMPTY
end

function ZO_BaseSlottableAction:IsWerewolf()
    -- can be overridden
    return false
end

function ZO_BaseSlottableAction:GetPlayerSkillData()
    return nil
end

function ZO_BaseSlottableAction:GetCompanionSkillData()
    return nil
end

------------------
-- Empty Action --
------------------

--[[
    The empty action has no state, it's always action ID 0. To use it, use the ZO_EMPTY_SLOTTABLE_ACTION singleton instead of the class.
]]--
ZO_EmptySlottableAction = ZO_BaseSlottableAction:Subclass()

function ZO_EmptySlottableAction:GetSlottableActionType()
    return ZO_SLOTTABLE_ACTION_TYPE_EMPTY
end

function ZO_EmptySlottableAction:GetActionId()
    local NO_ACTION_ID = 0
    return NO_ACTION_ID
end

function ZO_EmptySlottableAction:GetActionType()
    return ACTION_TYPE_NOTHING
end

function ZO_EmptySlottableAction:EqualsSlot(otherSlottableAction)
    return otherSlottableAction ~= nil and otherSlottableAction:IsEmpty()
end

function ZO_EmptySlottableAction:EqualsSkillData(skillData)
    return false
end

function ZO_EmptySlottableAction:GetIcon()
    -- Empty slots have no icon
    return nil
end

function ZO_EmptySlottableAction:IsUsable(hotbarCategory)
    return false
end

function ZO_EmptySlottableAction:IsStillValid()
    return true -- It's always valid to have an empty slot
end

function ZO_EmptySlottableAction:LayoutGamepadTooltip(tooltipType)
    -- Empty out tooltips
    GAMEPAD_TOOLTIPS:ClearTooltip(tooltipType)
end

function ZO_EmptySlottableAction:GetKeyboardTooltipControl()
    -- Empty slots have no tooltip
    return nil
end

function ZO_EmptySlottableAction:SetKeyboardTooltip()
    -- Do nothing
end

function ZO_EmptySlottableAction:TryCursorPickup()
    return false -- pickup failed
end

ZO_EMPTY_SLOTTABLE_ACTION = ZO_EmptySlottableAction:New()

-----------------------------
-- Slottable Player Skills --
-----------------------------

ZO_SlottablePlayerSkill = ZO_BaseSlottableAction:Subclass()

function ZO_SlottablePlayerSkill:Initialize(skillData, hotbarCategory)
    assert(skillData ~= nil, "SlottablePlayerSkill requires a linked skillData, got nil")
    assert(skillData:IsPassive() == false, "Only actives/ultimates are slottable")
    assert(hotbarCategory, "SlottablePlayerSkill requires a hotbarCategory, got nil")
    self.skillData = skillData
    self.hotbarCategory = hotbarCategory -- used for visualization purposes, has no effect on things like equality or the resulting message
end

function ZO_SlottablePlayerSkill:GetPlayerSkillData()
    return self.skillData
end

function ZO_SlottablePlayerSkill:GetSlottableActionType()
    return ZO_SLOTTABLE_ACTION_TYPE_PLAYER_SKILL
end

function ZO_SlottablePlayerSkill:GetActionId()
    if self.skillData:IsCraftedAbility() then
        return self.skillData:GetCraftedAbilityId()
    else
        local skillProgressionData = self.skillData:GetPointAllocatorProgressionData()
        return skillProgressionData:GetAbilityId()
    end
end

function ZO_SlottablePlayerSkill:GetActionType()
    if self.skillData:IsCraftedAbility() then
        return ACTION_TYPE_CRAFTED_ABILITY
    else
        return ACTION_TYPE_ABILITY
    end
end

function ZO_SlottablePlayerSkill:EqualsSlot(otherSlottableAction)
    return otherSlottableAction ~= nil and otherSlottableAction:GetSlottableActionType() == self:GetSlottableActionType() and self.skillData == otherSlottableAction.skillData
end

function ZO_SlottablePlayerSkill:EqualsSkillData(skillData)
    return skillData == self.skillData
end

function ZO_SlottablePlayerSkill:GetEffectiveAbilityId()
    local skillProgressionData = self.skillData:GetPointAllocatorProgressionData()
    local rootAbilityId = skillProgressionData:GetAbilityId()
    if skillProgressionData.IsChainingAbility and skillProgressionData:IsChainingAbility() then
        return GetEffectiveAbilityIdForAbilityOnHotbar(rootAbilityId, self.hotbarCategory)
    else
        return rootAbilityId
    end
end

function ZO_SlottablePlayerSkill:GetIcon()
    return GetAbilityIcon(self:GetEffectiveAbilityId())
end

function ZO_SlottablePlayerSkill:IsUsable()
    return CanAbilityBeUsedFromHotbar(self:GetEffectiveAbilityId(), self.hotbarCategory)
end

function ZO_SlottablePlayerSkill:IsStillValid()
    -- We should invalidate skills that have been refunded
    return self.skillData:GetPointAllocator():IsPurchased()
end

function ZO_SlottablePlayerSkill:LayoutGamepadTooltip(tooltipType)
    GAMEPAD_TOOLTIPS:LayoutAbilityWithSkillProgressionData(tooltipType, self:GetEffectiveAbilityId(), self.skillData:GetPointAllocatorProgressionData())
end

function ZO_SlottablePlayerSkill:GetKeyboardTooltipControl()
    return SkillTooltip
end

function ZO_SlottablePlayerSkill:SetKeyboardTooltip(tooltipControl)
    local DONT_SHOW_SKILL_POINT_COST = false
    local DONT_SHOW_UPGRADE_TEXT = false
    local DONT_SHOW_ADVISED = false
    local DONT_SHOW_BAD_MORPH = false
    local NO_OVERRIDE_RANK = nil
    self.skillData:GetPointAllocatorProgressionData():SetKeyboardTooltip(tooltipControl, DONT_SHOW_SKILL_POINT_COST, DONT_SHOW_UPGRADE_TEXT, DONT_SHOW_ADVISED, DONT_SHOW_BAD_MORPH, NO_OVERRIDE_RANK, self:GetEffectiveAbilityId())
end

function ZO_SlottablePlayerSkill:TryCursorPickup()
    return self.skillData:GetPointAllocatorProgressionData():TryPickup()
end

function ZO_SlottablePlayerSkill:IsWerewolf()
    return self.skillData:GetSkillLineData():IsWerewolf()
end

--------------------------------
-- Slottable Companion Skills --
--------------------------------

ZO_SlottableCompanionSkill = ZO_BaseSlottableAction:Subclass()

function ZO_SlottableCompanionSkill:Initialize(skillData, hotbarCategory)
    assert(skillData ~= nil, "SlottableCompanionSkill requires a linked skillData, got nil")
    assert(skillData:IsPassive() == false, "Only actives/ultimates are slottable")
    assert(hotbarCategory, "SlottableCompanionSkill requires a hotbarCategory, got nil")
    self.skillData = skillData
    self.hotbarCategory = hotbarCategory -- used for visualization purposes, has no effect on things like equality or the resulting message
end

function ZO_SlottableCompanionSkill:GetCompanionSkillData()
    return self.skillData
end

function ZO_SlottableCompanionSkill:GetSlottableActionType()
    return ZO_SLOTTABLE_ACTION_TYPE_COMPANION_SKILL
end

function ZO_SlottableCompanionSkill:GetActionId()
    local skillProgressionData = self.skillData:GetPointAllocatorProgressionData()
    return skillProgressionData:GetAbilityId()
end

function ZO_SlottableCompanionSkill:GetActionType()
    return ACTION_TYPE_ABILITY
end

function ZO_SlottableCompanionSkill:EqualsSlot(otherSlottableAction)
    return otherSlottableAction ~= nil and otherSlottableAction:GetSlottableActionType() == self:GetSlottableActionType() and self.skillData == otherSlottableAction.skillData
end

function ZO_SlottableCompanionSkill:EqualsSkillData(skillData)
    return skillData == self.skillData
end

function ZO_SlottableCompanionSkill:GetEffectiveAbilityId()
    return self.skillData:GetAbilityId()
end

function ZO_SlottableCompanionSkill:GetIcon()
    return GetAbilityIcon(self:GetEffectiveAbilityId())
end

function ZO_SlottableCompanionSkill:IsUsable()
    return CanAbilityBeUsedFromHotbar(self:GetEffectiveAbilityId(), self.hotbarCategory)
end

function ZO_SlottableCompanionSkill:IsStillValid()
    -- We should invalidate skills that have been refunded
    return self.skillData:GetPointAllocator():IsPurchased()
end

function ZO_SlottableCompanionSkill:LayoutGamepadTooltip(tooltipType)
    GAMEPAD_TOOLTIPS:LayoutCompanionSkillProgression(tooltipType, self.skillData:GetPointAllocatorProgressionData())
end

function ZO_SlottableCompanionSkill:GetKeyboardTooltipControl()
    return SkillTooltip
end

function ZO_SlottableCompanionSkill:SetKeyboardTooltip(tooltipControl)
    self.skillData:GetPointAllocatorProgressionData():SetKeyboardTooltip(tooltipControl)
end

function ZO_SlottableCompanionSkill:TryCursorPickup()
    return self.skillData:GetCurrentProgressionData():TryPickup()
end

-----------------------
-- Slottable Ability --
-----------------------
--[[
    Slottable abilities are "loose", aka unassociated with a skill line. These should only show up on temp bars in normal play.
    These are built under the assumption that they can't be edited, because you can't edit temp bars.
]]--

ZO_SlottableAbility = ZO_BaseSlottableAction:Subclass()

function ZO_SlottableAbility:Initialize(abilityId)
    assert(abilityId ~= nil, "ZO_SlottableAbility requires an abilityId")
    self.abilityId = abilityId
end

function ZO_SlottableAbility:GetSlottableActionType()
    return ZO_SLOTTABLE_ACTION_TYPE_ABILITY
end

function ZO_SlottableAbility:GetActionId()
    return self.abilityId
end

function ZO_SlottableAbility:GetActionType()
    return ACTION_TYPE_ABILITY
end

function ZO_SlottableAbility:EqualsSlot(otherSlottableAction)
    return otherSlottableAction ~= nil and otherSlottableAction:GetSlottableActionType() == ZO_SLOTTABLE_ACTION_TYPE_ABILITY and self.abilityId == otherSlottableAction:GetActionId()
end

function ZO_SlottableAbility:EqualsSkillData(skillData)
    return false
end

function ZO_SlottableAbility:GetIcon()
    return GetAbilityIcon(self.abilityId)
end

function ZO_SlottableAbility:IsUsable(hotbarCategory)
    return true
end

function ZO_SlottableAbility:IsStillValid()
    return true
end

function ZO_SlottableAbility:LayoutGamepadTooltip(tooltipType)
    GAMEPAD_TOOLTIPS:LayoutSimpleAbility(tooltipType, self.abilityId)
end

function ZO_SlottableAbility:GetKeyboardTooltipControl()
    return AbilityTooltip
end

function ZO_SlottableAbility:SetKeyboardTooltip(tooltipControl)
    tooltipControl:SetAbilityId(self.abilityId)
end

function ZO_SlottableAbility:TryCursorPickup()
    return false
end

------------
-- Hotbar --
------------
--[[
    Hotbar objects model the subset of a server side hotbar that matters for the skills window: We only care about the 5 active slots and the one ultimate slot, and we only store SlottableActions.
]]--

ZO_ActionBarAssignmentManager_Hotbar = ZO_InitializingObject:Subclass()

function ZO_ActionBarAssignmentManager_Hotbar:Initialize(hotbarCategory)
    self.hotbarCategory = hotbarCategory
    self.isInCycle = false
    self.slots = {}
    self.newSlotsById = {}

    self.overrideSlotSkillDatas = {}
    for actionSlotIndex = SKILL_BAR_START_SLOT_INDEX, SKILL_BAR_END_SLOT_INDEX do
        local progressionId = GetSkillProgressionIdForHotbarSlotOverrideRule(actionSlotIndex, hotbarCategory)
        if progressionId ~= 0 then
            self.overrideSlotSkillDatas[actionSlotIndex] = SKILLS_DATA_MANAGER:GetSkillDataByProgressionId(progressionId)
        end
    end
end

function ZO_ActionBarAssignmentManager_Hotbar:Clear()
    ZO_ClearTable(self.slots)
end

function ZO_ActionBarAssignmentManager_Hotbar:Reset()
    self:Clear()
    for actionSlotIndex = SKILL_BAR_START_SLOT_INDEX, SKILL_BAR_END_SLOT_INDEX do
        self:ResetSlot(actionSlotIndex)
    end
end

function ZO_ActionBarAssignmentManager_Hotbar:ResetSlot(actionSlotIndex)
    if actionSlotIndex < SKILL_BAR_START_SLOT_INDEX or actionSlotIndex > SKILL_BAR_END_SLOT_INDEX then
        -- We can't assign skills to this actionSlotIndex
        return
    end

    local overrideSkillData = self:GetOverrideSkillDataForSlot(actionSlotIndex)
    if overrideSkillData then
        self.slots[actionSlotIndex] = ZO_SlottablePlayerSkill:New(overrideSkillData, self.hotbarCategory)
        return
    end

    self.slots[actionSlotIndex] = ZO_EMPTY_SLOTTABLE_ACTION
    local actionType = GetSlotType(actionSlotIndex, self.hotbarCategory)
    if actionType == ACTION_TYPE_ABILITY then
        local abilityId = GetSlotBoundId(actionSlotIndex, self.hotbarCategory)

        if self.hotbarCategory == HOTBAR_CATEGORY_COMPANION then
            local companionSkillData = COMPANION_SKILLS_DATA_MANAGER:GetSkillDataByAbilityId(abilityId)
            if companionSkillData then
                self.slots[actionSlotIndex] = ZO_SlottableCompanionSkill:New(companionSkillData, self.hotbarCategory)
                return
            else
                internalassert(false, string.format("Attempted to place non-companion ability %d on companion bar; does the companion skill manager know about this ability?", abilityId))
            end
        end

        local playerSkillProgressionData = SKILLS_DATA_MANAGER:GetProgressionDataByAbilityId(abilityId)
        if playerSkillProgressionData then
            self.slots[actionSlotIndex] = ZO_SlottablePlayerSkill:New(playerSkillProgressionData:GetSkillData(), self.hotbarCategory)
            return
        end

        if not ASSIGNABLE_HOTBAR_CATEGORY_SET[self.hotbarCategory] then
            self.slots[actionSlotIndex] = ZO_SlottableAbility:New(abilityId)
            return
        end

        if ActionSlotHasEffectiveSlotAbilityData(actionSlotIndex, self.hotbarCategory) then
            self.slots[actionSlotIndex] = ZO_SlottableAbility:New(abilityId)
            return
        end
    elseif actionType == ACTION_TYPE_CRAFTED_ABILITY then
        local craftedAbilityId = GetSlotBoundId(actionSlotIndex, self.hotbarCategory)
        local abilityId = GetAbilityIdForCraftedAbilityId(craftedAbilityId)
        local playerSkillProgressionData = SKILLS_DATA_MANAGER:GetProgressionDataByAbilityId(abilityId)
        if playerSkillProgressionData then
            self.slots[actionSlotIndex] = ZO_SlottablePlayerSkill:New(playerSkillProgressionData:GetSkillData(), self.hotbarCategory)
            return
        end
    end
end

function ZO_ActionBarAssignmentManager_Hotbar:GetHotbarCategory()
    return self.hotbarCategory
end

function ZO_ActionBarAssignmentManager_Hotbar:GetSlotData(actionSlotIndex)
    return self.slots[actionSlotIndex]
end

function ZO_ActionBarAssignmentManager_Hotbar:GetOverrideSkillDataForSlot(actionSlotIndex)
    local overrideSkillData = self.overrideSlotSkillDatas[actionSlotIndex]
    if overrideSkillData and overrideSkillData:GetPointAllocator():IsPurchased() then
        return overrideSkillData
    end
    return nil
end

function ZO_ActionBarAssignmentManager_Hotbar:SlotIterator(filterFunctions)
    return ZO_FilteredNonContiguousTableIterator(self.slots, filterFunctions)
end

function ZO_ActionBarAssignmentManager_Hotbar:DoesSlotHavePendingChanges(actionSlotIndex)
    local pendingAction = self:GetSlotData(actionSlotIndex)
    if pendingAction == nil then
        return false
    end

    local actionType = GetSlotType(actionSlotIndex, self.hotbarCategory)
    local actionId = GetSlotBoundId(actionSlotIndex, self.hotbarCategory)

    local pendingActionType = pendingAction:GetActionType()
    local slottableActionType = pendingAction:GetSlottableActionType()
    local pendingActionId
    if pendingActionType == ACTION_TYPE_ABILITY and (slottableActionType == ZO_SLOTTABLE_ACTION_TYPE_PLAYER_SKILL or slottableActionType == ZO_SLOTTABLE_ACTION_TYPE_COMPANION_SKILL) then
        pendingActionId = pendingAction:GetEffectiveAbilityId()
    else
        pendingActionId = pendingAction:GetActionId()
    end

    return pendingActionType ~= actionType or pendingActionId ~= actionId
end

function ZO_ActionBarAssignmentManager_Hotbar:IsSlotLocked(actionSlotIndex)
    return IsActionSlotLocked(actionSlotIndex, self.hotbarCategory)
end

function ZO_ActionBarAssignmentManager_Hotbar:IsSlotMutable(actionSlotIndex)
    return IsActionSlotMutable(actionSlotIndex, self.hotbarCategory)
end

function ZO_ActionBarAssignmentManager_Hotbar:GetSlotUnlockText(actionSlotIndex)
    return GetActionSlotUnlockText(actionSlotIndex, self.hotbarCategory)
end

function ZO_ActionBarAssignmentManager_Hotbar:IsEditable()
    return ASSIGNABLE_HOTBAR_CATEGORY_SET[self.hotbarCategory] == true -- coerce to bool
end

function ZO_ActionBarAssignmentManager_Hotbar:GetExpectedSlotEditResult(actionSlotIndex)
    if not self:IsEditable() then
        return HOT_BAR_RESULT_CANNOT_EDIT_HOTBAR
    end

    if self:IsSlotLocked(actionSlotIndex) then
        return HOT_BAR_RESULT_SLOT_LOCKED
    end

    if self:GetOverrideSkillDataForSlot(actionSlotIndex) or not self:IsSlotMutable(actionSlotIndex) then
        return HOT_BAR_RESULT_CANNOT_EDIT_SLOT
    end

    if GetActionBarLockedReason() == ACTION_BAR_LOCKED_REASON_COMBAT then
        return HOT_BAR_RESULT_NO_COMBAT_SWAP
    end
    
    return HOT_BAR_RESULT_SUCCESS
end

function ZO_ActionBarAssignmentManager_Hotbar:GetExpectedSkillSlotResult(actionSlotIndex, skillData)
    local editResult = self:GetExpectedSlotEditResult(actionSlotIndex)
    if editResult ~= HOT_BAR_RESULT_SUCCESS then
        return editResult
    end

    local isPlayerSkill = skillData:IsPlayerSkill()
    if isPlayerSkill then
        local isWerewolfBar = self.hotbarCategory == HOTBAR_CATEGORY_WEREWOLF
        local isWerewolfSkill = skillData:GetSkillLineData():IsWerewolf()
        if isWerewolfBar and not isWerewolfSkill then
            return HOT_BAR_RESULT_CANNOT_USE_WHILE_WEREWOLF
        end
    end

    local isUltimateSlot = ACTION_BAR_ASSIGNMENT_MANAGER:IsUltimateSlot(actionSlotIndex)
    if skillData:IsUltimate() ~= isUltimateSlot or skillData:IsPassive() then
        if isUltimateSlot then
            return HOT_BAR_RESULT_IS_NOT_ULTIMATE
        else
            return HOT_BAR_RESULT_IS_NOT_NORMAL
        end
    end

    return HOT_BAR_RESULT_SUCCESS
end

do
    local IS_CHANGED_BY_PLAYER = true
    function ZO_ActionBarAssignmentManager_Hotbar:ClearSlot(actionSlotIndex)
        if self.slots[actionSlotIndex] == nil then
            internalassert(false, "Invalid slot ID")
            return
        end

        local expectedResult = self:GetExpectedSlotEditResult(actionSlotIndex)
        if expectedResult ~= HOT_BAR_RESULT_SUCCESS then
            ZO_AlertEvent(EVENT_HOT_BAR_RESULT, expectedResult)
            return false
        end

        self.slots[actionSlotIndex] = ZO_EMPTY_SLOTTABLE_ACTION
        ACTION_BAR_ASSIGNMENT_MANAGER:FireCallbacks("SlotUpdated", self.hotbarCategory, actionSlotIndex, IS_CHANGED_BY_PLAYER)
    end

    function ZO_ActionBarAssignmentManager_Hotbar:AssignSkillToSlot(actionSlotIndex, skillData)
        local currentAction = self:GetSlotData(actionSlotIndex)

        -- this slot already has this skill, skip
        if currentAction:EqualsSkillData(skillData) then
            return false
        end

        -- you can't slot this specific skill here
        local expectedResult = self:GetExpectedSkillSlotResult(actionSlotIndex, skillData)
        if expectedResult ~= HOT_BAR_RESULT_SUCCESS then
            ZO_AlertEvent(EVENT_HOT_BAR_RESULT, expectedResult)
            return false
        end

        -- the skill is already slotted on this bar, clear that instance out
        local oldactionSlotIndex = self:FindSlotMatchingSkill(skillData)
        if oldactionSlotIndex then
            self:ClearSlot(oldactionSlotIndex)
        end

        if skillData:IsCompanionSkill() then
            self.slots[actionSlotIndex] = ZO_SlottableCompanionSkill:New(skillData, self.hotbarCategory)
        elseif skillData:IsPlayerSkill() then
            self.slots[actionSlotIndex] = ZO_SlottablePlayerSkill:New(skillData, self.hotbarCategory)
        else
            internalassert(false, "unimplemented action slot type")
        end
        ACTION_BAR_ASSIGNMENT_MANAGER:FireCallbacks("SlotUpdated", self.hotbarCategory, actionSlotIndex, IS_CHANGED_BY_PLAYER)
        return true
    end

    function ZO_ActionBarAssignmentManager_Hotbar:AssignSkillToSlotByAbilityId(actionSlotIndex, abilityId)
        local playerSkillProgressionData = SKILLS_DATA_MANAGER:GetProgressionDataByAbilityId(abilityId)
        if playerSkillProgressionData then
            return self:AssignSkillToSlot(actionSlotIndex, playerSkillProgressionData:GetSkillData())
        end

        local companionSkillData = COMPANION_SKILLS_DATA_MANAGER:GetSkillDataByAbilityId(abilityId)
        if companionSkillData then
            return self:AssignSkillToSlot(actionSlotIndex, companionSkillData)
        end

        internalassert(false, "unimplemented action slot type")
        return false
    end
end

function ZO_ActionBarAssignmentManager_Hotbar:FindEmptySlotForSkill(skillData)
    -- Can't slot passives
    if skillData:IsPassive() then
        return nil
    end

    if skillData:IsUltimate() then
        -- This is an ultimate, it can only be slotted in one place
        if self:GetSlotData(SKILL_BAR_ULTIMATE_SLOT_INDEX):IsEmpty() and not self:IsSlotLocked(SKILL_BAR_ULTIMATE_SLOT_INDEX) then
            return SKILL_BAR_ULTIMATE_SLOT_INDEX
        end
    else
        -- This is a normal active, slot it in the first empty slot
        for actionSlotIndex = SKILL_BAR_FIRST_NORMAL_SLOT_INDEX, SKILL_BAR_LAST_NORMAL_SLOT_INDEX do 
            if self:GetSlotData(actionSlotIndex):IsEmpty() and not self:IsSlotLocked(actionSlotIndex) then
                return actionSlotIndex
            end
        end
    end

    return nil
end

function ZO_ActionBarAssignmentManager_Hotbar:FindSlotMatchingSkill(skillData)
    for actionSlotIndex, slotAction in self:SlotIterator() do
        if slotAction:EqualsSkillData(skillData) then
            return actionSlotIndex
        end
    end
end

function ZO_ActionBarAssignmentManager_Hotbar:IsInCycle()
    return self.isInCycle
end

-- NumHotbarsInCycle is kept in sync by these two methods: if you manipulate isInCycle someplace else, you'll have a bad time
function ZO_ActionBarAssignmentManager_Hotbar:EnableInCycle()
    local wasInCycle = self.isInCycle
    self.isInCycle = true
    if wasInCycle ~= self.isInCycle then
        ACTION_BAR_ASSIGNMENT_MANAGER:ChangeNumHotbarsInCycle(1)
    end
end

function ZO_ActionBarAssignmentManager_Hotbar:DisableInCycle()
    local wasInCycle = self.isInCycle
    self.isInCycle = false
    if wasInCycle ~= self.isInCycle then
        ACTION_BAR_ASSIGNMENT_MANAGER:ChangeNumHotbarsInCycle(-1)
    end
end

function ZO_ActionBarAssignmentManager_Hotbar:MarkSlotNewInternal(slotIndex)
    self.newSlotsById[slotIndex] = true
end

function ZO_ActionBarAssignmentManager_Hotbar:ClearSlotNew(slotIndex)
    if self.newSlotsById[slotIndex] then
        self.newSlotsById[slotIndex] = nil
        local IS_CHANGED_BY_PLAYER = true
        ACTION_BAR_ASSIGNMENT_MANAGER:FireCallbacks("SlotNewStatusChanged", self.hotbarCategory, slotIndex)
    end
end

function ZO_ActionBarAssignmentManager_Hotbar:IsSlotNew(slotIndex)
    return self.newSlotsById[slotIndex] == true -- coerce to bool
end

function ZO_ActionBarAssignmentManager_Hotbar:AreAnySlotsNew()
    return not ZO_IsTableEmpty(self.newSlotsById) 
end

-----------------------------------
-- Action Bar Assignment Manager --
-----------------------------------

ZO_ActionBarAssignmentManager = ZO_InitializingCallbackObject:Subclass()

function ZO_ActionBarAssignmentManager:Initialize()
    ACTION_BAR_ASSIGNMENT_MANAGER = self
    self.hotbars = {}
    for hotbarCategory in pairs(VIEWABLE_HOTBAR_CATEGORY_SET) do
        self.hotbars[hotbarCategory] = ZO_ActionBarAssignmentManager_Hotbar:New(hotbarCategory)
        self.hotbars[hotbarCategory]:Reset()
    end
    self:ResetCurrentHotbarToActiveBarInternal()

    self.numHotbarsInCycle = 0
    self.overrideHotbarCategory = nil
    self:GetHotbar(HOTBAR_CATEGORY_PRIMARY):EnableInCycle()
    self:UpdateBackupBarStateInCycle()

    self:RegisterForEvents()

    SKILLS_AND_ACTION_BAR_MANAGER:OnActionBarAssignmentManagerReady(self)
end

function ZO_ActionBarAssignmentManager:RegisterForEvents()
    -- Action slot events
    local function OnHotbarSlotUpdated(_, actionSlotIndex, hotbarCategory, justUnlocked)
        if VIEWABLE_HOTBAR_CATEGORY_SET[hotbarCategory] then
            local hotbar = self:GetHotbar(hotbarCategory)
            if not SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
                -- Only refresh from data when not respeccing.
                hotbar:ResetSlot(actionSlotIndex)
            end

            if justUnlocked then
                hotbar:MarkSlotNewInternal(actionSlotIndex)
                self:FireCallbacks("SlotNewStatusChanged", hotbarCategory, actionSlotIndex)
            end
            self:FireCallbacks("SlotUpdated", hotbarCategory, actionSlotIndex)
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBarAssignmentManager", EVENT_HOTBAR_SLOT_UPDATED, OnHotbarSlotUpdated)

    local function OnActiveHotbarUpdated(_, didActiveHotbarChange, shouldUpdateSlotAssignments)
        local oldHotbarCategory = self.currentHotbarCategory
        self:ResetCurrentHotbarToActiveBarInternal()
        if shouldUpdateSlotAssignments then
            self:GetCurrentHotbar():Reset()
        end
        self:FireCallbacks("CurrentHotbarUpdated", self.currentHotbarCategory, oldHotbarCategory)
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBarAssignmentManager", EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED, OnActiveHotbarUpdated)

    local function ResetAllHotbars()
        self:ResetAllHotbars()
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBarAssignmentManager", EVENT_ACTION_SLOTS_ALL_HOTBARS_UPDATED, ResetAllHotbars)

    local function ResetPlayerHotbars()
        self:ResetPlayerHotbars()
    end
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("SkillPointAllocationModeChanged", ResetPlayerHotbars)
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("RespecStateReset", ResetPlayerHotbars)

    local function OnSkillsDataFullUpdate()
        -- Current morph may have changed, refresh visuals
        self:FireCallbacks("CurrentHotbarUpdated", self.currentHotbarCategory, self.currentHotbarCategory)
    end
    SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", OnSkillsDataFullUpdate)

    local function UpdateWeaponSwapState()
        self:UpdateWeaponSwapState()
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBarAssignmentManager", EVENT_WEAPON_PAIR_LOCK_CHANGED, UpdateWeaponSwapState)

    local function HandleSlotChangeRequested(_, abilityId, actionSlotIndex, hotbarCategory)
        if VIEWABLE_HOTBAR_CATEGORY_SET[hotbarCategory] then
            local hotbar = self:GetHotbar(hotbarCategory)
            if abilityId == 0 then
                if hotbar:ClearSlot(actionSlotIndex) then
                    PlaySound(SOUNDS.ABILITY_SLOT_CLEARED)
                end
            else
                local progressionData = SKILLS_DATA_MANAGER:GetProgressionDataByAbilityId(abilityId)
                if progressionData and hotbar:AssignSkillToSlot(actionSlotIndex, progressionData:GetSkillData())then
                    PlaySound(SOUNDS.ABILITY_SLOTTED)
                end
            end
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBarAssignmentManager", EVENT_HOTBAR_SLOT_CHANGE_REQUESTED, HandleSlotChangeRequested)

    -- Skill point Allocation events
    local function OnSkillPurchaseStateChanged(skillPointAllocator)
        local skillData = skillPointAllocator:GetSkillData()
        if skillData:IsPassive() then
            return
        end

        if skillPointAllocator:IsPurchased() then
            self:TryToSlotNewSkill(skillData)
        else
            self:ClearAllSlotsWithSkill(skillData)
        end
    end
    SKILL_POINT_ALLOCATION_MANAGER:RegisterCallback("PurchasedChanged", OnSkillPurchaseStateChanged)

    local function OnSkillProgressionStateChanged(skillPointAllocator)
        local skillData = skillPointAllocator:GetSkillData()
        if skillData:IsPassive() then
            return
        end

        for hotbarCategory, hotbar in pairs(self.hotbars) do
            for actionSlotIndex, slotData in hotbar:SlotIterator() do
                if slotData:EqualsSkillData(skillData) then
                    self:FireCallbacks("SlotUpdated", hotbarCategory, actionSlotIndex)
                end
            end
        end
    end
    SKILL_POINT_ALLOCATION_MANAGER:RegisterCallback("SkillProgressionKeyChanged", OnSkillProgressionStateChanged)

    local function OnSkillsCleared()
        for hotbarCategory, hotbar in pairs(self.hotbars) do
            for actionSlotIndex, slotData in hotbar:SlotIterator() do
                if slotData:IsStillValid() then
                    self:FireCallbacks("SlotUpdated", hotbarCategory, actionSlotIndex)
                else
                    hotbar:ClearSlot(actionSlotIndex)
                end
            end
        end
    end
    SKILL_POINT_ALLOCATION_MANAGER:RegisterCallback("OnSkillsCleared", OnSkillsCleared)

    -- weapon swapping unlocked state events
    local function OnPlayerUnitCreated(_, unitTag)
        self:UpdateBackupBarStateInCycle()
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBarAssignmentManager", EVENT_UNIT_CREATED, OnPlayerUnitCreated)
    EVENT_MANAGER:AddFilterForEvent("ZO_ActionBarAssignmentManager", EVENT_UNIT_CREATED, REGISTER_FILTER_UNIT_TAG, "player")

    local function OnPlayerLevelUpdate(_, unitTag, level)
        self:UpdateBackupBarStateInCycle()
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBarAssignmentManager", EVENT_LEVEL_UPDATE, OnPlayerLevelUpdate)
    EVENT_MANAGER:AddFilterForEvent("ZO_ActionBarAssignmentManager", EVENT_LEVEL_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")

    local function OnPlayerActivated()
        self:ResetCurrentHotbarToActiveBarInternal()
        if HasActiveCompanion() and COMPANION_SKILLS_DATA_MANAGER:IsDataReady() then
            self:ResetAllHotbars()
        else
            -- We do not have companion skills data at this time, let's skip the companion bar until we do
            self:ResetPlayerHotbars()
        end
        self:UpdateBackupBarStateInCycle()
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBarAssignmentManager", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

    local function OnPlayerDeactivated()
        -- the companion may or may not be resummoned after a jump or load
        -- screen, let's clear out the data so we can refill it afterward.
        self.hotbars[HOTBAR_CATEGORY_COMPANION]:Clear()
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ActionBarAssignmentManager", EVENT_PLAYER_DEACTIVATED, OnPlayerDeactivated)
end

function ZO_ActionBarAssignmentManager:ResetCurrentHotbarToActiveBarInternal()
    local playerActiveHotbarCategory = GetActiveHotbarCategory()
    self.playerActiveHotbarCategory = playerActiveHotbarCategory
    if VIEWABLE_HOTBAR_CATEGORY_SET[playerActiveHotbarCategory] and self.overrideHotbarCategory == nil then
        self.currentHotbarCategory = playerActiveHotbarCategory
    end
    self.shouldUpdateWeaponSwapState = false
end

function ZO_ActionBarAssignmentManager:ResetCurrentHotbarToActiveBar()
    local oldHotbarCategory = self.currentHotbarCategory
    self:ResetCurrentHotbarToActiveBarInternal()
    self:FireCallbacks("CurrentHotbarUpdated", self.currentHotbarCategory, oldHotbarCategory)
end

function ZO_ActionBarAssignmentManager:ResetPlayerHotbarsInternal()
    for hotbarCategory, _ in pairs(ASSIGNABLE_PLAYER_HOTBAR_CATEGORY_SET) do
        self.hotbars[hotbarCategory]:Reset()
    end
end

function ZO_ActionBarAssignmentManager:ResetCompanionHotbarsInternal()
    self.hotbars[HOTBAR_CATEGORY_COMPANION]:Reset()
end

function ZO_ActionBarAssignmentManager:ResetPlayerHotbars()
    self:ResetPlayerHotbarsInternal()
    self:FireCallbacks("CurrentHotbarUpdated", self.currentHotbarCategory, self.currentHotbarCategory)
end

function ZO_ActionBarAssignmentManager:ResetAllHotbars()
    self:ResetPlayerHotbarsInternal()
    self:ResetCompanionHotbarsInternal()
    self:FireCallbacks("CurrentHotbarUpdated", self.currentHotbarCategory, self.currentHotbarCategory)
end

function ZO_ActionBarAssignmentManager:ShouldSubmitChangesForHotbarCategory(hotbarCategory)
    -- Don't perform werewolf changes if the werewolf line isn't unlocked
    -- this solves an issue where characters that have refunded werewolf still try to place their auto-grant ultimate on the werewolf bar
    if hotbarCategory == HOTBAR_CATEGORY_WEREWOLF then
        local werewolfSkillLineData = SKILLS_DATA_MANAGER:GetWerewolfSkillLineData()
        return werewolfSkillLineData and werewolfSkillLineData:IsAvailable()
    end

    return true -- most hotbars are cool
end

function ZO_ActionBarAssignmentManager:IsAnyChangePending()
    for hotbarCategory in pairs(ASSIGNABLE_HOTBAR_CATEGORY_SET) do
        if self:ShouldSubmitChangesForHotbarCategory(hotbarCategory) then
            local hotbar = self.hotbars[hotbarCategory]
            for actionSlotIndex in hotbar:SlotIterator() do
                if hotbar:DoesSlotHavePendingChanges(actionSlotIndex) then
                    return true
                end
            end
        end
    end
    return false
end

function ZO_ActionBarAssignmentManager:AddChangesToMessage()
    local anyChangesAdded = false
    for hotbarCategory in pairs(ASSIGNABLE_HOTBAR_CATEGORY_SET) do
        if self:ShouldSubmitChangesForHotbarCategory(hotbarCategory) then
            local hotbar = self.hotbars[hotbarCategory]
            for actionSlotIndex, action in hotbar:SlotIterator() do
                if hotbar:DoesSlotHavePendingChanges(actionSlotIndex) then
                    anyChangesAdded = true
                    AddHotbarSlotChangeToAllocationRequest(actionSlotIndex, hotbarCategory, action:GetActionType(), action:GetActionId())
                end
            end
        end
    end
    return anyChangesAdded
end

function ZO_ActionBarAssignmentManager:GetCurrentHotbarCategory()
    return self.currentHotbarCategory
end

function ZO_ActionBarAssignmentManager:GetCurrentHotbarName()
    return GetString("SI_HOTBARCATEGORY", self.currentHotbarCategory)
end

function ZO_ActionBarAssignmentManager:GetCurrentHotbar()
    return self.hotbars[self.currentHotbarCategory]
end

function ZO_ActionBarAssignmentManager:GetHotbar(hotbarCategory)
    local hotbar = self.hotbars[hotbarCategory]
    internalassert(hotbar ~= nil, "invalid hotbar category")
    return hotbar
end

function ZO_ActionBarAssignmentManager:UpdateWeaponSwapState()
    if self.shouldUpdateWeaponSwapState ~= true then
        return
    end
    local _, weaponSwapDisabled = GetActiveWeaponPairInfo()

    if not weaponSwapDisabled then
        if self.currentHotbarCategory == HOTBAR_CATEGORY_PRIMARY then
            OnWeaponSwapToSet1()
        elseif self.currentHotbarCategory == HOTBAR_CATEGORY_BACKUP then
            OnWeaponSwapToSet2()
        end
        self.shouldUpdateWeaponSwapState = false
    end
end

function ZO_ActionBarAssignmentManager:CancelPendingWeaponSwap()
    if self.shouldUpdateWeaponSwapState then
        self:ResetCurrentHotbarToActiveBar()
    end
end

function ZO_ActionBarAssignmentManager:ChangeNumHotbarsInCycle(numHotbarsEnabled)
    local oldShouldShowHotbarSwap = self:ShouldShowHotbarSwap()

    self.numHotbarsInCycle = self.numHotbarsInCycle + numHotbarsEnabled

    if oldShouldShowHotbarSwap ~= self:ShouldShowHotbarSwap() then
        self:FireCallbacks("HotbarSwapVisibleStateChanged")
    end
end

function ZO_ActionBarAssignmentManager:EnableHotbarInCycle(hotbarCategory)
    self:GetHotbar(hotbarCategory):EnableInCycle()
end

function ZO_ActionBarAssignmentManager:DisableAndSwitchOffHotbarInCycle(hotbarCategory)
    self:GetHotbar(hotbarCategory):DisableInCycle()

    if hotbarCategory == self.currentHotbarCategory then
        self:ResetCurrentHotbarToActiveBar()
    end
end

function ZO_ActionBarAssignmentManager:UpdateBackupBarStateInCycle()
    local backupBar = self:GetHotbar(HOTBAR_CATEGORY_BACKUP)

    if GetUnitLevel("player") >= GetWeaponSwapUnlockedLevel() then
        backupBar:EnableInCycle()
    else
        backupBar:DisableInCycle()
    end
end

function ZO_ActionBarAssignmentManager:IsWerewolfUltimateSlottedOnAnyWeaponBar()
    for hotbarCategory in pairs(WEAPON_PAIR_HOTBAR_CATEGORY_SET) do
        local ultimateSlotData = self:GetHotbar(hotbarCategory):GetSlotData(ACTION_BAR_ULTIMATE_SLOT_INDEX)
        if ultimateSlotData:IsWerewolf() then
            return true
        end
    end
    return false
end

function ZO_ActionBarAssignmentManager:UpdateWerewolfBarStateInCycle(selectedSkillLineData)
    if selectedSkillLineData and selectedSkillLineData:IsWerewolf() then
        self:EnableHotbarInCycle(HOTBAR_CATEGORY_WEREWOLF)
        if ACTION_BAR_ASSIGNMENT_MANAGER:IsWerewolfUltimateSlottedOnAnyWeaponBar() then
            self:SetCurrentHotbar(HOTBAR_CATEGORY_WEREWOLF)
        end
    else
        self:DisableAndSwitchOffHotbarInCycle(HOTBAR_CATEGORY_WEREWOLF)
    end
end

function ZO_ActionBarAssignmentManager:SetHotbarCycleOverride(overrideHotbarCategory)
    if self.overrideHotbarCategory ~= overrideHotbarCategory then
        self.overrideHotbarCategory = overrideHotbarCategory
        if overrideHotbarCategory then
            self:SetCurrentHotbar(overrideHotbarCategory)
        else
            self:ResetCurrentHotbarToActiveBar()
        end
    end
end

function ZO_ActionBarAssignmentManager:ShouldShowHotbarSwap()
    return self.numHotbarsInCycle > 1 and self.overrideHotbarCategory == nil
end

function ZO_ActionBarAssignmentManager:CanCycleHotbars()
    if self:IsHotbarSwapAnimationPlaying() or not self:ShouldShowHotbarSwap() then
        return false
    end
    -- Normally you can only hotbar cycle from your weapon bars, so preserve that behavior here
    return WEAPON_PAIR_HOTBAR_CATEGORY_SET[self.playerActiveHotbarCategory] == true
end

function ZO_ActionBarAssignmentManager:CycleCurrentHotbar()
    if self:CanCycleHotbars() then
        local oldCycleIndex = ZO_IndexOfElementInNumericallyIndexedTable(HOTBAR_CYCLE_ORDER, self.currentHotbarCategory)
        if internalassert(oldCycleIndex ~= nil, "Current hotbar isn't defined in cycle") then
            local newCycleIndex = oldCycleIndex
            local cycleLength = #HOTBAR_CYCLE_ORDER
            repeat
                newCycleIndex = (newCycleIndex % cycleLength) + 1
            until newCycleIndex == oldCycleIndex or self:GetHotbar(HOTBAR_CYCLE_ORDER[newCycleIndex]):IsInCycle()

            internalassert(newCycleIndex ~= oldCycleIndex, "no other hotbar found in cycle, cycling requires at least 2 hotbars")
            self:SetCurrentHotbar(HOTBAR_CYCLE_ORDER[newCycleIndex])
        end
    end
end

function ZO_ActionBarAssignmentManager:SetIsHotbarSwapAnimationPlaying(isHotbarSwapAnimationPlaying)
    self.isHotbarSwapAnimationPlaying = isHotbarSwapAnimationPlaying
end

function ZO_ActionBarAssignmentManager:IsHotbarSwapAnimationPlaying()
    return self.isHotbarSwapAnimationPlaying
end

function ZO_ActionBarAssignmentManager:SetCurrentHotbar(hotbarCategory)
    if self.hotbars[hotbarCategory] == nil then
        internalassert(false, "Invalid hotbar category")
        return
    end

    local oldHotbarCategory = self.currentHotbarCategory
    self.currentHotbarCategory = hotbarCategory
    self.shouldUpdateWeaponSwapState = true
    
    self:UpdateWeaponSwapState()
    self:FireCallbacks("CurrentHotbarUpdated", hotbarCategory, oldHotbarCategory)
end

function ZO_ActionBarAssignmentManager:IsUltimateSlot(actionSlotIndex)
    return actionSlotIndex == SKILL_BAR_ULTIMATE_SLOT_INDEX
end

function ZO_ActionBarAssignmentManager:GetActionNameForSlot(actionSlotIndex, hotbarCategory, isGamepadPreferred)
    local keyboardActionName, gamepadActionName = self:GetKeyboardAndGamepadActionNameForSlot(actionSlotIndex, hotbarCategory)
    if isGamepadPreferred then
        return gamepadActionName
    else
        return keyboardActionName
    end
end

function ZO_ActionBarAssignmentManager:GetKeyboardAndGamepadActionNameForSlot(actionSlotIndex, hotbarCategory)
    if hotbarCategory == HOTBAR_CATEGORY_QUICKSLOT_WHEEL then
        return "ACTION_BUTTON_9", "GAMEPAD_ACTION_BUTTON_9"
    elseif hotbarCategory == HOTBAR_CATEGORY_COMPANION then
        if self:IsUltimateSlot(actionSlotIndex) then
            return "COMMAND_PET", "COMMAND_PET"
        end

        -- use Automatic Cast priority instead
        return nil, nil
    end

    local keyboardActionName = string.format("ACTION_BUTTON_%d", actionSlotIndex)
    local gamepadActionName = string.format("GAMEPAD_ACTION_BUTTON_%d", actionSlotIndex)
    return keyboardActionName, gamepadActionName
end

function ZO_ActionBarAssignmentManager:GetAutomaticCastPriorityForSlot(actionSlotIndex, hotbarCategory)
    -- Normal companion skills are automatically cast by their companion, from left to right
    local isCompanionBar = hotbarCategory == HOTBAR_CATEGORY_COMPANION
    if isCompanionBar and not self:IsUltimateSlot(actionSlotIndex) then
        -- first slot is 1, continuing from left to right
        return actionSlotIndex - SKILL_BAR_FIRST_NORMAL_SLOT_INDEX + 1
    end
    return nil
end

function ZO_ActionBarAssignmentManager:TryToSlotNewSkill(skillData)
    local hotbar = self:GetCurrentHotbar()
    local actionSlotIndex = hotbar:FindEmptySlotForSkill(skillData)
    -- We check if GetExpectedSkillSlotResult() here is valid ahead of time to supress the alert the Assign() would otherwise trigger for an invalid result. If we would fail, fail silently instead.
    -- There is also an encoded assumption here that any empty slot is as good as any other slot for the GetExpectedSkillSlotResult(), so we only need to check one before bailing out.
    if actionSlotIndex and hotbar:GetExpectedSkillSlotResult(actionSlotIndex, skillData) == HOT_BAR_RESULT_SUCCESS then
        hotbar:AssignSkillToSlot(actionSlotIndex, skillData)
        return true
    end
    return false
end

function ZO_ActionBarAssignmentManager:ClearAllSlotsWithSkill(skillData)
    for _, hotbar in pairs(self.hotbars) do
        local actionSlotIndex = hotbar:FindSlotMatchingSkill(skillData)
        if actionSlotIndex then
            hotbar:ClearSlot(actionSlotIndex)
        end
    end
end

ZO_ActionBarAssignmentManager:New()
