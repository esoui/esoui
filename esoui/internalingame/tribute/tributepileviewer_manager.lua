-----------------------------
-- Tribute Pile Viewer Manager
-----------------------------

internalassert(TRIBUTE_BOARD_LOCATION_ITERATION_END == 20, "New TRIBUTE_BOARD_LOCATION added, check if it should be added to the PILE_FAMILIES table")
local PILE_FAMILIES =
{
    { TRIBUTE_BOARD_LOCATION_PLAYER_DECK, TRIBUTE_BOARD_LOCATION_PLAYER_HAND, TRIBUTE_BOARD_LOCATION_PLAYER_COOLDOWN },
    { TRIBUTE_BOARD_LOCATION_OPPONENT_DECK, TRIBUTE_BOARD_LOCATION_OPPONENT_COOLDOWN },
    { TRIBUTE_BOARD_LOCATION_DOCKS_DECK, TRIBUTE_BOARD_LOCATION_DOCKS_DISCARD },
    { TRIBUTE_BOARD_LOCATION_PLAYER_BOARD_AGENT, TRIBUTE_BOARD_LOCATION_PLAYER_BOARD_ACTION },
    { TRIBUTE_BOARD_LOCATION_OPPONENT_BOARD_AGENT, TRIBUTE_BOARD_LOCATION_OPPONENT_BOARD_ACTION },
}

local COMPOSITE_PILE_GROUPINGS =
{
    {
        BOARD_LOCATIONS = { TRIBUTE_BOARD_LOCATION_PLAYER_DECK, TRIBUTE_BOARD_LOCATION_PLAYER_HAND },
        OVERRIDE_NAME = GetString(SI_TRIBUTE_COMPOSITE_PILE_PLAYER_DECK_AND_HAND_NAME_OVERRIDE),
    },
    {
        BOARD_LOCATIONS = { TRIBUTE_BOARD_LOCATION_OPPONENT_DECK, TRIBUTE_BOARD_LOCATION_OPPONENT_HAND },
        OVERRIDE_NAME = GetString(SI_TRIBUTE_COMPOSITE_PILE_OPPONENT_DECK_AND_HAND_NAME_OVERRIDE),
        OVERRIDE_VIEWER = true, 
    },
}

ZO_TributePileViewer_Manager = ZO_TributeViewer_Manager_Base:Subclass()

function ZO_TributePileViewer_Manager:Initialize()
    ZO_TributeViewer_Manager_Base.Initialize(self)
    local function FindFamily(boardLocations)
        for _, boardLocation in ipairs(boardLocations) do
            for _, family in ipairs(PILE_FAMILIES) do
                if ZO_IsElementInNumericallyIndexedTable(family, boardLocation) then
                    return family
                end
            end
        end
        return nil
    end

    -- First build any composite piles, which may get used in place of regular pile viewer piles
    -- Make special composite piles that are used for some special cases where we want to describe piles as grouped together
    -- This is sort of a hack solution to make the opponent DECK/HAND appear as one pile when viewed, to combat card counting
    -- This also fascilitates combining the player and opponent's DECK and HAND being counted together for the Patron card count tooltips
    local compositePilesData = {}
    for _, compositePileGrouping in ipairs(COMPOSITE_PILE_GROUPINGS) do
        local boardLocations = compositePileGrouping.BOARD_LOCATIONS
        local family = FindFamily(boardLocations)
        internalassert(family ~= nil, "No matching family found for composite pile grouping.")
        local compositePileData = ZO_TributeCompositePileData:New(boardLocations, family)
        compositePileData:SetOverrideName(compositePileGrouping.OVERRIDE_NAME)
        compositePileData.overrideViewer = compositePileGrouping.OVERRIDE_VIEWER
        for _, boardLocation in ipairs(boardLocations) do
            compositePilesData[boardLocation] = compositePileData
        end
    end
    self.compositePilesData = compositePilesData

    -- Next build all the piles for the viewer out of the families
    local pilesData = {}
    for _, family in ipairs(PILE_FAMILIES) do
        for _, boardLocation in ipairs(family) do
            internalassert(pilesData[boardLocation] == nil, "The pile at board location %d already exists.", boardLocation)
            pilesData[boardLocation] = ZO_TributePileData:New(boardLocation, family)
        end
    end

    self.pilesData = pilesData

    ZO_HELP_OVERLAY_SYNC_OBJECT:SetHandler("OnShown", function(isVisible)
        self:RequestClose()
    end, "tributePileViewer")
end

function ZO_TributePileViewer_Manager:RegisterForEvents(systemName)
    ZO_TributeViewer_Manager_Base.RegisterForEvents(self, systemName)
    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_PILE_UPDATED, function(_, boardLocation)
        local viewingPileChanged = false
        local compositePileData = self:GetCompositePileData(boardLocation)
        if compositePileData then
            compositePileData:MarkDirty()
            if compositePileData.overrideViewer and self.viewingPileLocation and ZO_IsElementInNumericallyIndexedTable(compositePileData:GetBoardLocations(), self.viewingPileLocation) then 
                viewingPileChanged = true
            end
        end

        local pileData = self:GetPileData(boardLocation)
        if pileData then
            pileData:MarkDirty()
            if self.viewingPileLocation == boardLocation then
                viewingPileChanged = true
            end
        end

        if viewingPileChanged then
            self:FireCallbacks("ViewingPileChanged", self.viewingPileLocation)
        end
    end)

    --Mark all pile data dirty when the board is cleared
    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_CLEAR_BOARD_CARDS, function()
        local viewingPileChanged = false
        for _, compositePileData in pairs(self.compositePilesData) do
            compositePileData:MarkDirty()
            if compositePileData.overrideViewer and self.viewingPileLocation and ZO_IsElementInNumericallyIndexedTable(compositePileData:GetBoardLocations(), self.viewingPileLocation) then 
                viewingPileChanged = true
            end
        end

        for boardLocation, pileData in pairs(self.pilesData) do
            pileData:MarkDirty()
            if self.viewingPileLocation == boardLocation then
                viewingPileChanged = true
            end
        end

        if viewingPileChanged then
            self:FireCallbacks("ViewingPileChanged", self.viewingPileLocation)
        end
    end)

    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_VIEW_PILE, function(_, boardLocation)
        local pileData = self:GetPileData(boardLocation)
        if pileData then
            self:SetViewingPile(boardLocation)
        end
    end)

    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_CARD_STATE_FLAGS_CHANGED, function(_, cardInstanceId, stateFlags)
        if self:IsActive() then
            self:FireCallbacks("CardStateFlagsChanged", cardInstanceId, stateFlags)
        end
    end)

    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_AGENT_DEFEAT_COST_CHANGED, function(_, cardInstanceId, delta, newDefeatCost, shouldPlayFx)
        if self:IsActive() then
            self:FireCallbacks("AgentDefeatCostChanged", cardInstanceId, delta, newDefeatCost, shouldPlayFx)
        end
    end)

    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_AGENT_CONFINEMENTS_CHANGED, function(_, agentInstanceId)
        if self:IsActive() then
            self:FireCallbacks("ConfinedCardsChanged", agentInstanceId)
        end
    end)

    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_BEGIN_TARGET_SELECTION, function(_, needsTargetViewer)
        --Close the viewer if target selection begins
        if self:IsActive() then
            self:RequestClose()
        end
    end)

    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_BEGIN_MECHANIC_SELECTION, function(_, cardInstanceId)
        --Close the viewer if mechanic selection begins
        if self:IsActive() then
            self:RequestClose()
        end
    end)
end

function ZO_TributePileViewer_Manager:GetPileData(boardLocation)
    return self.pilesData[boardLocation]
end

function ZO_TributePileViewer_Manager:GetCompositePileData(boardLocation)
    return self.compositePilesData[boardLocation]
end

function ZO_TributePileViewer_Manager:GetViewerPileData(boardLocation)
    local compositePileData = self.compositePilesData[boardLocation]
    if compositePileData and compositePileData.overrideViewer then
        return compositePileData
    end
    return self.pilesData[boardLocation]
end

function ZO_TributePileViewer_Manager:GetCurrentPileData()
    if self.viewingPileLocation then
        return self:GetViewerPileData(self.viewingPileLocation)
    else
        return nil
    end
end

function ZO_TributePileViewer_Manager:SetViewingPile(boardLocation)
    if self.viewingPileLocation ~= boardLocation then
        --Order matters. Set the pile location before firing the activation state change
        self.viewingPileLocation = boardLocation
        self:FireActivationStateChanged()
        self:FireCallbacks("ViewingPileChanged", self.viewingPileLocation)
    end
end

function ZO_TributePileViewer_Manager:OpenConfinementViewer(cardData)
    --Cache which pile we are currently looking at before closing the pile viewer and opening the confinement viewer
    self.cachedViewingPileLocation = self.viewingPileLocation
    self:RequestClose()
    cardData:ShowConfinedCards(self)
end

function ZO_TributePileViewer_Manager:OpenFromConfinementViewer(isInterceptingCloseAction)
    --Once the confinement viewer closes, if we had a cached pile we were previously looking at, try to re-open it
    if self.cachedViewingPileLocation then
        --Do not try to re-open the pile viewer if the user pressed escape
        if not isInterceptingCloseAction then
            self:SetViewingPile(self.cachedViewingPileLocation)
        end
        self.cachedViewingPileLocation = nil
    end
end

-- Required Overrides

function ZO_TributePileViewer_Manager:GetSystemName()
    return "TributePileViewer_Manager"
end

function ZO_TributePileViewer_Manager:OnGamepadPreferredModeChanged()
    --If the viewer is already up, we need to close and reopen it to make sure it switches to the correct UI
    if self:IsActive() then
        local pileLocation = self.viewingPileLocation
        self:RequestClose()
        self:SetViewingPile(pileLocation)
    end
end

--The pile viewer does not have functionality for viewing the board while it's open
function ZO_TributePileViewer_Manager:IsViewingBoard()
    return false
end

function ZO_TributePileViewer_Manager:IsActive()
    return self.viewingPileLocation ~= nil
end

--The pile viewer always has a visible keybind strip
function ZO_TributePileViewer_Manager:IsKeybindStripVisible()
    return true
end

function ZO_TributePileViewer_Manager:RequestClose()
    local NO_PILE = nil
    self:SetViewingPile(NO_PILE)
end

ZO_TRIBUTE_PILE_VIEWER_MANAGER = ZO_TributePileViewer_Manager:New()