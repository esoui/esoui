-----------------------------
-- Base Assignment Manager --
-----------------------------

ZO_SkillsAssignmentManager_Base = ZO_InitializingCallbackObject:Subclass()

function ZO_SkillsAssignmentManager_Base:Initialize(readyFunction)
    self:RegisterForEvents()

    readyFunction(SKILLS_AND_ACTION_BAR_MANAGER, self)
end

function ZO_SkillsAssignmentManager_Base:RegisterForEvents()
    -- Can be overridden
end

ZO_SkillsAssignmentManager_Base:MUST_IMPLEMENT("IsAnyChangePending")
ZO_SkillsAssignmentManager_Base:MUST_IMPLEMENT("AddChangesToMessage")
ZO_SkillsAssignmentManager_Base:MUST_IMPLEMENT("DoPendingChangesIncurCost")

--------------------
-- Global Manager --
--------------------

ZO_SkillsAndActionBarManager = ZO_InitializingCallbackObject:Subclass()

function ZO_SkillsAndActionBarManager:Initialize()
    self.skillPointAllocationMode = SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY
    self.skillRespecPaymentType = RESPEC_PAYMENT_TYPE_GOLD

    self.managers = {}

    EVENT_MANAGER:RegisterForEvent("ZO_SkillsAndActionBarManager", EVENT_START_SKILL_RESPEC, function(_, ...) self:OnStartRespec(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_SkillsAndActionBarManager", EVENT_SKILL_RESPEC_RESULT, function(_, ...) self:OnSkillRespecResult(...) end)
    EVENT_MANAGER:RegisterForUpdate("ZO_SkillsAndActionBarManager", 0, function() self:OnUpdate() end)
    EVENT_MANAGER:RegisterForEvent("ZO_SkillsAndActionBarManager", EVENT_INTERACTION_ENDED, function(_, ...) self:OnInteractionEnded(...) end)
end

function ZO_SkillsAndActionBarManager:GetSkillPointAllocationMode()
    return self.skillPointAllocationMode
end

function ZO_SkillsAndActionBarManager:SetSkillPointAllocationMode(skillPointAllocationMode)
    if skillPointAllocationMode ~= self.skillPointAllocationMode then
        local oldSkillPointAllocationMode = self.skillPointAllocationMode
        self.skillPointAllocationMode = skillPointAllocationMode
        if self:DoesSkillPointAllocationModeBatchSave() then
            PlaySound(SOUNDS.SKILLS_ENTER_RESPEC_MODE)
        end

        if self.skillPointAllocationMode == SKILL_POINT_ALLOCATION_MODE_SUBCLASS_ONLY and GetInteractionType() == INTERACTION_SKILL_RESPEC and GetSubclassingAccessLevel() == SUBCLASSING_ACCESS_LEVEL_CONDITIONAL then
            self.hasConditionalAccessToSubclassing = true
        end
        self:FireCallbacks("SkillPointAllocationModeChanged", skillPointAllocationMode, oldSkillPointAllocationMode)
    end

    -- Debug: Trying to track down data in a bad state
    internalassert(SKILL_POINT_ALLOCATION_MANAGER:HasValidChangesForMode(), "Skill point allocation manager has pending changes incompatible with current mode")
end

function ZO_SkillsAndActionBarManager:OnInteractionEnded(oldInteractionType)
    if oldInteractionType == INTERACTION_SKILL_RESPEC and self.hasConditionalAccessToSubclassing then
        self.hasConditionalAccessToSubclassing = false
        self:FireCallbacks("LostConditionalAccessToSubclassing")
    end
end

function ZO_SkillsAndActionBarManager:ResetInterface()
    self:SetSkillRespecPaymentType(RESPEC_PAYMENT_TYPE_GOLD)
    self:SetSkillPointAllocationMode(SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY)
end

function ZO_SkillsAndActionBarManager:ResetRespecState()
    self:SetSkillRespecPaymentType(RESPEC_PAYMENT_TYPE_GOLD)
    self:SetSkillPointAllocationMode(SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY)
    self:FireCallbacks("RespecStateReset")
end

function ZO_SkillsAndActionBarManager:GetSkillRespecPaymentType()
    return self.skillRespecPaymentType
end

function ZO_SkillsAndActionBarManager:SetSkillRespecPaymentType(skillRespecPaymentType)
    if skillRespecPaymentType ~= self.skillRespecPaymentType then
        local oldSkillRespecPaymentType = self.skillRespecPaymentType
        self.skillRespecPaymentType = skillRespecPaymentType
        self:FireCallbacks("SkillRespecPaymentTypeChanged", skillRespecPaymentType, oldSkillRespecPaymentType)
    end
end

function ZO_SkillsAndActionBarManager:DoesSkillPointAllocationModeAllowDecrease()
    return self.skillPointAllocationMode ~= SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY
end

function ZO_SkillsAndActionBarManager:DoesSkillPointAllocationModeAllowClear()
    return self.skillPointAllocationMode ~= SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY and self.skillPointAllocationMode ~= SKILL_POINT_ALLOCATION_MODE_SUBCLASS_ONLY
end

function ZO_SkillsAndActionBarManager:DoesSkillPointAllocationModeBatchSave()
    return self.skillPointAllocationMode ~= SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY
end

function ZO_SkillsAndActionBarManager:DoesSkillPointAllocationModeConfirmOnPurchase()
    return self.skillPointAllocationMode == SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY
end

function ZO_SkillsAndActionBarManager:DoesSkillPointAllocationModeConfirmOnIncreaseRank()
    return self.skillPointAllocationMode == SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY
end

function ZO_SkillsAndActionBarManager:DoesSkillPointAllocationModeAllowAccessToSubclassing()
    -- SUBCLASSING_ACCESS_LEVEL_CONDITIONAL is a special state when you're on the specific intro quest step to engage with the system.
    -- Technically while on this state you have access, but only SKILL_POINT_ALLOCATION_MODE_SUBCLASS_ONLY will work.
    -- So to make the UX make sense, we'll only let you into the system if you're in that mode.
    local subclassingAccessLevel = GetSubclassingAccessLevel()
    if subclassingAccessLevel == SUBCLASSING_ACCESS_LEVEL_FULL then
        return true
    elseif subclassingAccessLevel == SUBCLASSING_ACCESS_LEVEL_CONDITIONAL then
        return self.skillPointAllocationMode == SKILL_POINT_ALLOCATION_MODE_SUBCLASS_ONLY or self.hasConditionalAccessToSubclassing
    end
    return false
end

function ZO_SkillsAndActionBarManager:DoesSkillPointAllocationModeAllowSkillLineRespec()
    return self.skillPointAllocationMode == SKILL_POINT_ALLOCATION_MODE_FULL or self.skillPointAllocationMode == SKILL_POINT_ALLOCATION_MODE_SUBCLASS_ONLY
end

function ZO_SkillsAndActionBarManager:DoesSkillPointAllocationModeAllowSkillLineTraining()
    return self.skillPointAllocationMode == SKILL_POINT_ALLOCATION_MODE_FULL or self.skillPointAllocationMode == SKILL_POINT_ALLOCATION_MODE_SUBCLASS_ONLY
end

function ZO_SkillsAndActionBarManager:OnUpdate()
    --Purchase-only mode saves every change immediately
    if self.isDirty and not self:DoesSkillPointAllocationModeBatchSave() then
        self:ApplyChanges()
    end
end

function ZO_SkillsAndActionBarManager:OnStartRespec(allocationMode, paymentType)
    self:SetSkillRespecPaymentType(paymentType)
    self:SetSkillPointAllocationMode(allocationMode)
    if IsInGamepadPreferredMode() then
        GAMEPAD_SKILLS:SelectEntryByAllocationMode()
        SCENE_MANAGER:Push("gamepad_skills_root")
    else
        SKILLS_WINDOW:SelectEntryByAllocationMode()
        SCENE_MANAGER:Push("skills")
    end
end

do
    internalassert(RESPEC_RESULT_MAX_VALUE == 77, "Update EXPECTED_RESPEC_FAILURES")
    local EXPECTED_RESPEC_FAILURES =
    {
        [RESPEC_RESULT_IS_IN_COMBAT] = true,
        [RESPEC_RESULT_ACTIVE_HOTBAR_NOT_RESPECCABLE] = true,
        [RESPEC_RESULT_ABILITY_DISABLED] = true,
        [RESPEC_RESULT_SCRIBING_DISABLED] = true,
        [RESPEC_RESULT_CRAFTED_ABILITY_SCRIPT_DISABLED] = true,
        [RESPEC_RESULT_SUBCLASSING_ABILITY_PURCHASE_DISABLED] = true,
        [RESPEC_RESULT_SUBCLASSING_SKILL_SWAPPING_DISABLED] = true,
        [RESPEC_RESULT_SKILL_SWAPPING_DISABLED] = true,
        [RESPEC_RESULT_SUBCLASSING_TRAINING_DISABLED] = true,
        [RESPEC_RESULT_SUBCLASSING_DISABLED] = true,
        [RESPEC_RESULT_IN_VENGEANCE] = true,
        [RESPEC_RESULT_ON_COOLDOWN_SKILLS] = true,
        [RESPEC_RESULT_ON_COOLDOWN_ATTRIBUTES] = true,
        [RESPEC_RESULT_CAST_CANCELED] = true,
        [RESPEC_RESULT_DISALLOWED_IN_ACTIVITY] = true,
    }
    function ZO_SkillsAndActionBarManager:OnSkillRespecResult(result)
        if result == RESPEC_RESULT_SUCCESS then
            self:ResetInterface()
        else
            internalassert(EXPECTED_RESPEC_FAILURES[result], string.format("Unexpected Respec Failure (%d)", result))
            if not self:DoesSkillPointAllocationModeBatchSave() then
                -- if we aren't in batch mode, the user has no way to fix bad state, so we need to hard reset for them
                self:ResetRespecState()
            end
        end
    end
end

function ZO_SkillsAndActionBarManager:ApplyChanges()
    PrepareSkillPointAllocationRequest(self.skillPointAllocationMode, self.skillRespecPaymentType)

    local anyChangesAdded = false
    for _, manager in ipairs(self.managers) do
        if manager:AddChangesToMessage() then
            anyChangesAdded = true
        end
    end

    SendSkillPointAllocationRequest()

    self.isDirty = false
end

function ZO_SkillsAndActionBarManager:HasAnyPendingChanges()
    for _, manager in ipairs(self.managers) do
        if manager:IsAnyChangePending() then
            return true
        end
    end
    return false
end

function ZO_SkillsAndActionBarManager:DoPendingChangesIncurCost()
    for _, manager in ipairs(self.managers) do
        if manager:DoPendingChangesIncurCost() then
            return true
        end
    end
    return false
end

function ZO_SkillsAndActionBarManager:OnSkillPointAllocationManagerReady(manager)
    table.insert(self.managers, manager)

    local function MarkDirty()
        self:MarkDirty()
    end

    manager:RegisterCallback("PurchasedChanged", MarkDirty)
    manager:RegisterCallback("SkillProgressionKeyChanged", MarkDirty)
end

function ZO_SkillsAndActionBarManager:OnActionBarAssignmentManagerReady(manager)
    table.insert(self.managers, manager)

    local function OnSlotUpdated(_, _, isChangedByPlayer)
        -- Slots can be updated either by an external system informing the assignment manager of the new state, in which case we shouldn't dirty the state and trigger an apply,
        -- or by the player changing the state themselves through the manager, in which case we should apply that change.
        -- This protects us against superflous diff checking, and more importantly, protects against spamminess/message loops where we cause an update to trigger, which causes us to apply again, etc.
        if isChangedByPlayer then
            self:MarkDirty()
        end
    end

    manager:RegisterCallback("SlotUpdated", OnSlotUpdated)
end

function ZO_SkillsAndActionBarManager:OnSkillLineAssignmentManagerReady(manager)
    table.insert(self.managers, manager)

    local function MarkDirty()
        self:MarkDirty()
    end

    manager:RegisterCallback("TrainingChanged", MarkDirty)
    manager:RegisterCallback("LineSwapped", MarkDirty)
end

function ZO_SkillsAndActionBarManager:MarkDirty()
    self.isDirty = true
end

SKILLS_AND_ACTION_BAR_MANAGER = ZO_SkillsAndActionBarManager:New()