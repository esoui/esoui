-----------------------------
-- Tribute Patron Selection Manager
-----------------------------

ZO_TributePatronSelection_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_TributePatronSelection_Manager:Initialize()
    EVENT_MANAGER:RegisterForEvent("TributePatronSelection_Manager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() 
        if self.isSelectionInProgress then
            self:FireCallbacks("EndSelection")
            self:FireCallbacks("BeginSelection")
        end
    end)

    EVENT_MANAGER:RegisterForEvent("TributePatronSelection_Manager", EVENT_TRIBUTE_PATRON_DRAFTED, function(_, patronDraftId, patronDefId)
        --Filter out neutral patrons
        if IsTributePatronNeutral(patronDefId) then
            return
        end
        
        self.draftedPatrons[patronDefId] = patronDraftId
        self.isAnimating = true

        --No need to do this if the screen isn't up
        if self.isSelectionInProgress then
            self.selectedPatron = nil
            self:FireCallbacks("PatronDrafted")
        end
    end)

    EVENT_MANAGER:RegisterForEvent("TributePatronSelection_Manager", EVENT_TRIBUTE_PATRON_START_NEXT_DRAFT, function()
        self.isAnimating = false
        --No need to do this if the screen isn't up
        if self.isSelectionInProgress then
            self:FireCallbacks("BeginNextDraftingPhase")
        end
    end)

    self.patronFilterFunction = function(currentData)
        if currentData:GetPatronCollectibleId() == 0 then
            return false
        end

        if currentData:IsNeutral() then
            return false
        end

        return true
    end

    self.patronDataList = {}
    self.draftedPatrons = {}
    self.showGamepadTooltips = true
end

do
    --TODO Tribute: Verify that this is how we want it to sort
    local function ComparePatrons(left, right)
        local isLeftLocked = left:IsPatronLocked()
        local isRightLocked = right:IsPatronLocked()
        if isLeftLocked == isRightLocked then
            return left:GetId() < right:GetId()
        else
            return isRightLocked
        end
    end

    function ZO_TributePatronSelection_Manager:RefreshPatronData()
        ZO_ClearNumericallyIndexedTable(self.patronDataList)
        for _, patronData in TRIBUTE_DATA_MANAGER:TributePatronIterator({self.patronFilterFunction}) do
            table.insert(self.patronDataList, patronData)
        end
        table.sort(self.patronDataList, ComparePatrons)
    end
end

function ZO_TributePatronSelection_Manager:GetPatronData()
    if self.isSelectionInProgress then
        return self.patronDataList
    end
end

function ZO_TributePatronSelection_Manager:IsSelectionInProgress()
    return self.isSelectionInProgress
end

function ZO_TributePatronSelection_Manager:IsDraftAnimating()
    return self.isAnimating
end

function ZO_TributePatronSelection_Manager:BeginPatronSelection()
    if not self.isSelectionInProgress then
        self.isSelectionInProgress = true
        self.showGamepadTooltips = true
        self:RefreshPatronData()
        self:FireCallbacks("BeginSelection")
    end
end

function ZO_TributePatronSelection_Manager:EndPatronSelection(forceEndSelection)
    if self.isSelectionInProgress or forceEndSelection then
        ZO_ClearTable(self.draftedPatrons)
        self.isSelectionInProgress = false
        self.isAnimating = false
        self.selectedPatron = nil
        self:FireCallbacks("EndSelection")
    end
end

function ZO_TributePatronSelection_Manager:SelectPatron(patronId)
    self.selectedPatron = patronId
    self:FireCallbacks("PatronSelected")
end

function ZO_TributePatronSelection_Manager:ConfirmSelection()
    if self.selectedPatron then
        DraftPatron(self.selectedPatron)
    end
end

function ZO_TributePatronSelection_Manager:GetSelectedPatron()
    return self.selectedPatron
end

function ZO_TributePatronSelection_Manager:IsPatronDrafted(patronId)
    return self.draftedPatrons[patronId] ~= nil
end

function ZO_TributePatronSelection_Manager:GetNumDraftedPatrons()
    return NonContiguousCount(self.draftedPatrons)
end

function ZO_TributePatronSelection_Manager:ToggleShowGamepadTooltips()
    self.showGamepadTooltips = not self.showGamepadTooltips
end

function ZO_TributePatronSelection_Manager:ShouldShowGamepadTooltips()
    return self.showGamepadTooltips
end

function ZO_TributePatronSelection_Manager:HasTurnTimer()
    return GetTributeRemainingTimeForTurn() ~= nil
end

ZO_TRIBUTE_PATRON_SELECTION_MANAGER = ZO_TributePatronSelection_Manager:New()