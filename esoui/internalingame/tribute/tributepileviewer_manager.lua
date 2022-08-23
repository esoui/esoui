-----------------------------
-- Tribute Pile Viewer Manager
-----------------------------

internalassert(TRIBUTE_BOARD_LOCATION_ITERATION_END == 18, "New TRIBUTE_BOARD_LOCATION added, check if it should be added to the PILE_FAMILIES table")
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

ZO_TributePileViewer_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_TributePileViewer_Manager:Initialize()
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
    EVENT_MANAGER:RegisterForEvent("TributePileViewer_Manager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:SetViewingPile(nil) end)
    EVENT_MANAGER:RegisterForEvent("TributePileViewer_Manager", EVENT_TRIBUTE_PILE_UPDATED, function(_, boardLocation)
        local viewingPileChanged = false
        local compositePileData = compositePilesData[boardLocation]
        if compositePileData then
            compositePileData:MarkDirty()
            if compositePileData.overrideViewer and self.isViewingPileLocation and ZO_IsElementInNumericallyIndexedTable(compositePileData:GetBoardLocations(), self.isViewingPileLocation) then 
                viewingPileChanged = true
            end
        end

        local pileData = self.pilesData[boardLocation]
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

    EVENT_MANAGER:RegisterForEvent("TributePileViewer_Manager", EVENT_TRIBUTE_VIEW_PILE, function(_, boardLocation)
        local pileData = self:GetPileData(boardLocation)
        if pileData then
            self:SetViewingPile(boardLocation)
        end
    end)

    EVENT_MANAGER:RegisterForEvent("TributePileViewer_Manager", EVENT_TRIBUTE_CARD_STATE_FLAGS_CHANGED, function(_, cardInstanceId, stateFlags)
        if self:IsViewingPile() then
            self:FireCallbacks("CardStateFlagsChanged", cardInstanceId, stateFlags)
        end
    end)

    EVENT_MANAGER:RegisterForEvent("TributePileViewer_Manager", EVENT_TRIBUTE_AGENT_DEFEAT_COST_CHANGED, function(_, cardInstanceId, delta, newDefeatCost, shouldPlayFx)
        if self:IsViewingPile() then
            self:FireCallbacks("AgentDefeatCostChanged", cardInstanceId, delta, newDefeatCost, shouldPlayFx)
        end
    end)

    EVENT_MANAGER:RegisterForEvent("TributePileViewer_Manager", EVENT_TRIBUTE_BEGIN_TARGET_SELECTION, function(_, needsTargetViewer)
        --Close the viewer if target selection begins
        if self:IsViewingPile() then
            local NO_PILE = nil
            self:SetViewingPile(NO_PILE)
        end
    end)

    HELP_MANAGER:RegisterCallback("OverlayVisibilityChanged", function(isVisible)
        if isVisible then
            self:SetViewingPile(nil)
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

function ZO_TributePileViewer_Manager:IsViewingPile()
    return self.viewingPileLocation ~= nil
end

function ZO_TributePileViewer_Manager:SetViewingPile(boardLocation)
    if self.viewingPileLocation ~= boardLocation then
        self.viewingPileLocation = boardLocation
        self:FireCallbacks("ViewingPileChanged", self.viewingPileLocation)
    end
end

ZO_TRIBUTE_PILE_VIEWER_MANAGER = ZO_TributePileViewer_Manager:New()