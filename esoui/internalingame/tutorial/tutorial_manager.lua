-- Tutorial types that should neither fire TriggeredTutorialChanged callbacks nor affect TUTORIAL_MANAGER:IsTutorialTriggered()
-- For now this works with no additional logic required for tutorial as they are hidden because Pointer Box tutorials do not fire the hidden event.
local UNTRACKED_TUTORIAL_TYPES = ZO_CreateSetFromArguments(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TYPE_HUD_BRIEF, TUTORIAL_TYPE_HUD_INFO_BOX)

local Tutorial_Manager = ZO_InitializingCallbackObject:Subclass()

function Tutorial_Manager:Initialize()
    self.triggeredTutorial = false

    local function OnTutorialHidden(eventCode, ...)
        self:OnTutorialHidden(...)
    end

    EVENT_MANAGER:RegisterForEvent("Tutorial_Manager", EVENT_TUTORIAL_HIDDEN, OnTutorialHidden)
end

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

function Tutorial_Manager:IsTutorialTriggered()
    return self.triggeredTutorial
end

function Tutorial_Manager:OnTutorialHidden(tutorialIndex)
    if not self.triggeredTutorial then
        return
    end

    local tutorialType = GetTutorialType(tutorialIndex)
    if not UNTRACKED_TUTORIAL_TYPES[tutorialType] then
        self.triggeredTutorial = false
        self:FireCallbacks("TriggeredTutorialChanged", false)
    end
end

function Tutorial_Manager:OnTutorialTriggered(tutorialTrigger)
    if self.triggeredTutorial then
        return
    end

    local tutorialIndex = GetTutorialIndex(tutorialTrigger)
    local tutorialType = GetTutorialType(tutorialIndex)
    if not UNTRACKED_TUTORIAL_TYPES[tutorialType] then
        self.triggeredTutorial = true
        self:FireCallbacks("TriggeredTutorialChanged", true)
    end
end

function Tutorial_Manager:ShowTutorial(tutorialTrigger)
    if self:CanTutorialTriggerFire(tutorialTrigger) and TriggerTutorial(tutorialTrigger) then
        self:OnTutorialTriggered(tutorialTrigger)
    end
end

function Tutorial_Manager:ShowTutorialWithPosition(tutorialTrigger, anchorPosition, screenX, screenY)
    if self:CanTutorialTriggerFire(tutorialTrigger) and TriggerTutorialWithPosition(tutorialTrigger, anchorPosition, screenX, screenY) then
        self:OnTutorialTriggered(tutorialTrigger)
    end
end

TUTORIAL_MANAGER = Tutorial_Manager:New()