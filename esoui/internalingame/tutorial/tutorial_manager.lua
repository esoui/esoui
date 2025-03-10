local Tutorial_Manager = ZO_InitializingCallbackObject:Subclass()

function Tutorial_Manager:CanShowTutorial(tutorialId)
    return CanTutorialBeSeen(tutorialId) and (not HasSeenTutorial(tutorialId))
end

function Tutorial_Manager:GetTutorialId(tutorialTrigger)
    if type(tutorialTrigger) == "table" then
        return GetTutorialId(tutorialTrigger.trigger, tutorialTrigger.param)
    else
        return GetTutorialId(tutorialTrigger)
    end
end

function Tutorial_Manager:CanTutorialTriggerFire(tutorialTrigger)
    local tutorialId = self:GetTutorialId(tutorialTrigger)
    return self:CanShowTutorial(tutorialId)
end

function Tutorial_Manager:RemoveTutorialByTrigger(tutorialTrigger)
    RemoveTutorial(tutorialTrigger)
end

--[[
    Supportes either a TUTORIAL_TRIGGER enum or a table. Table format should include these fields:
    trigger - (required) the TUTORIAL_TRIGGER enum value
    param - (optional) the param to use with TriggerTutorialWithParam
    anchorPosition, screenX, screenY - (optional) the arguments to use with TriggerTutorialWithPosition
--]]
function Tutorial_Manager:ShowTutorial(tutorialTrigger)
    if type(tutorialTrigger) == "table" then
        if tutorialTrigger.param then
            return self:ShowTutorialWithParam(tutorialTrigger, tutorialTrigger.param)
        elseif tutorialTrigger.anchorPosition then
            return self:ShowTutorialWithPosition(tutorialTrigger, tutorialTrigger.anchorPosition, tutorialTrigger.screenX, tutorialTrigger.screenY)
        end
    end

    if self:CanTutorialTriggerFire(triggerType) then
        local triggerType = type(tutorialTrigger) == "table" and tutorialTrigger.trigger or tutorialTrigger
        return TriggerTutorial(triggerType)
    end
    return false
end

function Tutorial_Manager:ShowTutorialWithParam(tutorialTrigger, param)
    if self:CanTutorialTriggerFire(tutorialTrigger) then
        local triggerType = type(tutorialTrigger) == "table" and tutorialTrigger.trigger or tutorialTrigger
        return TriggerTutorialWithParam(triggerType, param)
    end
    return false
end

function Tutorial_Manager:ShowTutorialWithPosition(tutorialTrigger, anchorPosition, screenX, screenY)
    if self:CanTutorialTriggerFire(tutorialTrigger) then
        local triggerType = type(tutorialTrigger) == "table" and tutorialTrigger.trigger or tutorialTrigger
        return TriggerTutorialWithPosition(triggerType, anchorPosition, screenX, screenY)
    end
    return false
end

TUTORIAL_MANAGER = Tutorial_Manager:New()