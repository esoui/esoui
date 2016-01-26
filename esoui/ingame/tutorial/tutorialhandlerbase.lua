ZO_TutorialHandlerBase = ZO_Object:Subclass()

function ZO_TutorialHandlerBase:New(...)
    local tutorialHandler = ZO_Object.New(self)
    tutorialHandler.hiddenReasons = ZO_HiddenReasons:New()
    tutorialHandler:Initialize(...)
    return tutorialHandler
end

function ZO_TutorialHandlerBase:Initialize(...)
    -- Intended to be overriden
end

function ZO_TutorialHandlerBase:GetTutorialType()
    -- Required to be overriden, returns the type of tutorial this handles
end

function ZO_TutorialHandlerBase:ClearAll()
    -- Intended to be overriden, requests that all tutorials are hidden and removed from queues
end

function ZO_TutorialHandlerBase:ShowHelp()
    -- Intended to be overriden, if this tutorial has help linked to it should open the correct UI for that and return true, return false otherwise
    return false
end

function ZO_TutorialHandlerBase:SetHidden(hide)
    -- Intended to be overriden, requests that the current tutorial window be hidden or shown
end

function ZO_TutorialHandlerBase:SetHiddenForReason(reason, hidden)
    self.hiddenReasons:SetHiddenForReason(reason, hidden)
    self:SetHidden(self.hiddenReasons:IsHidden())
end

TUTORIAL_SUPPRESSED_BY_SCENE = 1
TUTORIAL_SUPPRESSED_BY_LOOT = 2

function ZO_TutorialHandlerBase:SuppressTutorials(suppress, reason)
    if reason == TUTORIAL_SUPPRESSED_BY_SCENE then
        self.suppressedByScene = suppress
    elseif reason == TUTORIAL_SUPPRESSED_BY_LOOT then
        self.suppressedByLoot = suppress
    end

    self.suppressed = self.suppressedByScene or self.suppressedByLoot

    self:SetHiddenForReason("suppressed", self.suppressed)

    if not self.suppressed then
        if not self:GetCurrentlyDisplayedTutorialIndex() and #self.queue > 0 then
            local nextTutorialIndex = table.remove(self.queue, 1)
            self:DisplayTutorial(nextTutorialIndex)
        end
    end
end

function ZO_TutorialHandlerBase:CanShowTutorial()
    return not self.suppressed and not self:GetCurrentlyDisplayedTutorialIndex()
end

local function BinaryInsertComparer(priority, otherTutorialIndex)
    return priority - select(3, GetTutorialInfo(otherTutorialIndex))
end

function ZO_TutorialHandlerBase:OnDisplayTutorial(tutorialIndex, priority)
    -- Can to be overriden for custom queueing behavior, occurs when a tutorial matching GetTutorialType() is requested to be displayed
    if not self:IsTutorialDisplayedOrQueued(tutorialIndex) then
        if not self:CanShowTutorial() then
            local _, insertPosition = zo_binarysearch(priority, self.queue, BinaryInsertComparer)
            table.insert(self.queue, insertPosition, tutorialIndex)
        else
            self:DisplayTutorial(tutorialIndex)
        end
    end
end

function ZO_TutorialHandlerBase:OnRemoveTutorial(tutorialIndex)
    -- Can to be overriden for custom behavior, occurs when a tutorial matching GetTutorialType() is requested to be removed
    self:RemoveTutorial(tutorialIndex)
end

function ZO_TutorialHandlerBase:SetCurrentlyDisplayedTutorialIndex(currentlyDisplayedTutorialIndex)
    self.currentlyDisplayedTutorialIndex = currentlyDisplayedTutorialIndex
end

function ZO_TutorialHandlerBase:GetCurrentlyDisplayedTutorialIndex()
    return self.currentlyDisplayedTutorialIndex
end

function ZO_TutorialHandlerBase:IsTutorialDisplayedOrQueued(tutorialIndex)
    if tutorialIndex == self:GetCurrentlyDisplayedTutorialIndex() then
        return true
    end
    return self:IsTutorialQueued(tutorialIndex)
end

function ZO_TutorialHandlerBase:IsTutorialQueued(tutorialIndex)
    for i, queuedTutorialIndex in ipairs(self.queue) do
        if queuedTutorialIndex == tutorialIndex then
            return true
        end
    end
    return false
end

function ZO_TutorialHandlerBase:RemoveFromQueue(tutorialIndex)
    for i, queuedTutorialIndex in ipairs(self.queue) do
        if queuedTutorialIndex == tutorialIndex then
            table.remove(self.queue, i)
            return true
        end
    end
    return false
end