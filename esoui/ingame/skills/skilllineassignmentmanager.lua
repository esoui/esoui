-- ESO-911673: When swapping out a player skill line for another player skill line pendingDeactivationLines can
-- equal MAX_LINE_SWAPS temporarily until the pending deactivation player skill line is removed upon activation.
-- ESO-915394: Bumping MAX_LINE_SWAPS from 2 to 3 to account for the fact that you actually can swap 3 things if you had
-- already subclassed two lines, and then want to do it again and swap your player class with another player class.
-- As a result of this change, it makes the fix for the prior bug (ESO-911673) moot.
local MAX_LINE_SWAPS = 3

ZO_SkillLineAssignmentManager = ZO_SkillsAssignmentManager_Base:Subclass()

function ZO_SkillLineAssignmentManager:Initialize()
    SKILL_LINE_ASSIGNMENT_MANAGER = self

    self.pendingTrainingLines = {}
    self.pendingDeactivationLines = {}
    self.pendingActivationLines = {}

    ZO_SkillsAssignmentManager_Base.Initialize(self, ZO_SkillsAndActionBarManager.OnSkillLineAssignmentManagerReady)

    SKILLS_DATA_MANAGER:OnSkillLineAssignmentManagerReady()
end

function ZO_SkillLineAssignmentManager:RegisterForEvents()
    local function Reset()
        self:Reset()
    end
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("SkillPointAllocationModeChanged", Reset)
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("RespecStateReset", Reset)
end

-- Training --

function ZO_SkillLineAssignmentManager:TrainSkillLine(skillLineData, suppressCallback)
    if #self.pendingTrainingLines < MAX_SKILL_LINES_IN_TRAINING and not self:IsSkillLinePendingTrain(skillLineData) then
        table.insert(self.pendingTrainingLines, skillLineData:GetId())
        if not suppressCallback then
            self:FireCallbacks("SkillLineRespecUpdate", skillLineData)
        end
        return true
    end
    return false
end

function ZO_SkillLineAssignmentManager:UntrainSkillLine(skillLineData, suppressCallback)
    local index = ZO_IndexOfElementInNumericallyIndexedTable(self.pendingTrainingLines, skillLineData:GetId())
    if index then
        table.remove(self.pendingTrainingLines, index)
        if not suppressCallback then
            self:FireCallbacks("SkillLineRespecUpdate", skillLineData)
        end
        return true
    end
    return false
end

function ZO_SkillLineAssignmentManager:IsSkillLinePendingTrain(skillLineData)
    return ZO_IsElementInNumericallyIndexedTable(self.pendingTrainingLines, skillLineData:GetId())
end

-- Deactivation --

function ZO_SkillLineAssignmentManager:DeactivateSkillLine(skillLineData, suppressCallback)
    local success = false
    local pendingActivationIndex = ZO_IndexOfElementInNumericallyIndexedTable(self.pendingActivationLines, skillLineData:GetId())
    if pendingActivationIndex then
        table.remove(self.pendingActivationLines, pendingActivationIndex)
        success = true
    elseif #self.pendingDeactivationLines < MAX_LINE_SWAPS and not self:IsSkillLinePendingDeactivation(skillLineData) then
        table.insert(self.pendingDeactivationLines, skillLineData:GetId())
        success = true
    end

    if success then
        -- Cannot suppress this, it's necessary
        SKILL_POINT_ALLOCATION_MANAGER:FireCallbacks("OnSkillsCleared", skillLineData)

        if not suppressCallback then
            self:FireCallbacks("SkillLineRespecUpdate", skillLineData)
        end
    end
    return success
end

function ZO_SkillLineAssignmentManager:IsSkillLinePendingDeactivation(skillLineData)
    return ZO_IsElementInNumericallyIndexedTable(self.pendingDeactivationLines, skillLineData:GetId())
end

-- Activation --

function ZO_SkillLineAssignmentManager:ActivateSkillLine(skillLineData)
    local success = false
    local pendingDeactivationIndex = ZO_IndexOfElementInNumericallyIndexedTable(self.pendingDeactivationLines, skillLineData:GetId())
    if pendingDeactivationIndex then
        table.remove(self.pendingDeactivationLines, pendingDeactivationIndex)
        success = true
    elseif #self.pendingActivationLines < MAX_LINE_SWAPS and not self:IsSkillLinePendingActivation(skillLineData) then
        table.insert(self.pendingActivationLines, skillLineData:GetId())
        success = true
    end

    if success and not suppressCallback then
        self:FireCallbacks("SkillLineRespecUpdate", skillLineData)
    end
    return success
end

function ZO_SkillLineAssignmentManager:IsSkillLinePendingActivation(skillLineData)
    return ZO_IsElementInNumericallyIndexedTable(self.pendingActivationLines, skillLineData:GetId())
end

-- Processing --

function ZO_SkillLineAssignmentManager:GetPendingPointAllocationDelta()
    local pendingDelta = 0
    for _, skillLineId in ipairs(self.pendingDeactivationLines) do
        local skillLineData = SKILLS_DATA_MANAGER:GetSkillLineDataById(skillLineId)
        pendingDelta = pendingDelta - skillLineData:GetNumPointsAllocated()
    end
    return pendingDelta
end

function ZO_SkillLineAssignmentManager:IsAnyTrainingChangePending()
    return #self.pendingTrainingLines > 0
end

function ZO_SkillLineAssignmentManager:GetNumTrainingChangesPending()
    return #self.pendingTrainingLines
end

function ZO_SkillLineAssignmentManager:GetPendingTrainingLines()
    return self.pendingTrainingLines
end

function ZO_SkillLineAssignmentManager:IsActivationOrDeactivationPending()
    return #self.pendingDeactivationLines > 0 or #self.pendingActivationLines > 0
end

function ZO_SkillLineAssignmentManager:HasSubclassingChanges()
    local pendingTrainingLines = self:GetPendingTrainingLines()
    local hasSwap = self:IsActivationOrDeactivationPending() and self:DoAnyChangesIncurPointRefunds()
    return #pendingTrainingLines > 0 or hasSwap
end

function ZO_SkillLineAssignmentManager:IsAnyChangePending()
    return self:IsAnyTrainingChangePending() or self:IsActivationOrDeactivationPending()
end

function ZO_SkillLineAssignmentManager:DoPendingChangesIncurCost()
    return self:IsActivationOrDeactivationPending()
end

function ZO_SkillLineAssignmentManager:DoAnyChangesIncurPointRefunds()
    return self:GetPendingPointAllocationDelta() < 0
end

function ZO_SkillLineAssignmentManager:AddChangesToMessage()
    local anyChangesAdded = false

    if #self.pendingTrainingLines > 0 then
        anyChangesAdded = true
        AddTrainingToAllocationRequest(unpack(self.pendingTrainingLines))
    end
    if #self.pendingDeactivationLines > 0 then
        anyChangesAdded = true
        DeactivateSkillLinesInAllocationRequest(unpack(self.pendingDeactivationLines))
    end
    if #self.pendingActivationLines > 0 then
        anyChangesAdded = true
        ActivateSkillLinesInAllocationRequest(unpack(self.pendingActivationLines))
    end

    return anyChangesAdded
end

function ZO_SkillLineAssignmentManager:Reset()
    ZO_ClearNumericallyIndexedTable(self.pendingTrainingLines)
    ZO_ClearNumericallyIndexedTable(self.pendingDeactivationLines)
    ZO_ClearNumericallyIndexedTable(self.pendingActivationLines)
    self:FireCallbacks("SkillLineRespecUpdate")
end

ZO_SkillLineAssignmentManager:New()