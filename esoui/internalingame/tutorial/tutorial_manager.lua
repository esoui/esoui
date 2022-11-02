local Tutorial_Manager = ZO_InitializingCallbackObject:Subclass()

function Tutorial_Manager:CanShowTutorial(tutorialId)
    return CanTutorialBeSeen(tutorialId) and (not HasSeenTutorial(tutorialId))
end

function Tutorial_Manager:CanTutorialTriggerFire(tutorialTrigger)
    local tutorialId = GetTutorialId(tutorialTrigger)
    return self:CanShowTutorial(tutorialId)
end

function Tutorial_Manager:RemoveTutorialByTrigger(tutorialTrigger)
    RemoveTutorial(tutorialTrigger)
end

function Tutorial_Manager:ShowTutorial(tutorialTrigger)
    if self:CanTutorialTriggerFire(tutorialTrigger) then
        return TriggerTutorial(tutorialTrigger)
    end
    return false
end

function Tutorial_Manager:ShowTutorialWithPosition(tutorialTrigger, anchorPosition, screenX, screenY)
    if self:CanTutorialTriggerFire(tutorialTrigger) then
        return TriggerTutorialWithPosition(tutorialTrigger, anchorPosition, screenX, screenY)
    end
    return false
end

TUTORIAL_MANAGER = Tutorial_Manager:New()