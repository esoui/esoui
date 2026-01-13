---------------------------------------
-- Adventure Zone Event Tile Gamepad --
---------------------------------------

ZO_AdventureZoneEventTile_Gamepad = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Gamepad, ZO_AdventureZoneEventTile_Shared)

function ZO_AdventureZoneEventTile_Gamepad:New(...)
    return ZO_AdventureZoneEventTile_Shared.New(self, ...)
end

-------------------------------------
-- Adventure Zone Overview Gamepad --
-------------------------------------

ZO_AdventureZoneOverview_Gamepad = ZO_Object.MultiSubclass(ZO_AdventureZoneOverview_Shared)

function ZO_AdventureZoneOverview_Gamepad:Initialize(...)
    ZO_AdventureZoneOverview_Shared.Initialize(self, ...)

    local scene = self:GetScene()
    ADVENTURE_ZONE_OVERVIEW_SCENE_GAMEPAD = scene
    SYSTEMS:RegisterGamepadRootScene("adventureZoneOverview", scene)
end

function ZO_AdventureZoneOverview_Gamepad:OnDeferredInitialize()
    ZO_AdventureZoneOverview_Shared.OnDeferredInitialize(self)

    self.eventsFocus = ZO_GamepadFocus:New(self.eventsContainer, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    for index, eventTile in ipairs(self.eventTileControls) do
        local entryData = {
            activate = function()
                eventTile.object:Focus()
                self.selectedEvent = eventTile.eventIndex
                self:UpdateKeybinds()
                SCREEN_NARRATION_MANAGER:QueueCustomEntry("AdventureZoneOverview")
            end,
            deactivate = function()
                eventTile.object:Defocus()
                self.selectedEvent = nil
                self:UpdateKeybinds()
            end,
            highlight = eventTile.object.selection,
        }
        self.eventsFocus:AddEntry(entryData)
    end

    self:InitializeNarrationInfo()
end

function ZO_AdventureZoneOverview_Gamepad:InitializeNarrationInfo()
    local narrationInfo =
    {
        canNarrate = function()
            return self:IsShowing()
        end,

        headerNarrationFunction = function()
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_ADVENTURE_ZONE_OVERVIEW_TITLE))
        end,

        selectedNarrationFunction = function()
            local narrations = {}
            for faction = ADVENTURE_ZONE_FACTION_ITERATION_BEGIN, ADVENTURE_ZONE_FACTION_ITERATION_END do
                local scoreControl = self.factionScoreControls[faction]
                if scoreControl then
                    local name = scoreControl:GetNamedChild("Name"):GetText()
                    local score = scoreControl:GetNamedChild("Score"):GetText()
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(name))
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(score))

                    if faction == GetUnitAdventureZoneFaction("player") then
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.playerPointsLabel:GetText()))
                    end
                end
            end

            if self.selectedEvent then
                local eventTile = self.eventTileControls[self.selectedEvent].object
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(eventTile.locationLabel:GetText()))
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(eventTile.titleLabel:GetText()))
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(eventTile.statusLabel:GetText()))
            end
            return narrations
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("AdventureZoneOverview", narrationInfo)
end

function ZO_AdventureZoneOverview_Gamepad:OnShowing()
    ZO_AdventureZoneOverview_Shared.OnShowing(self)

    self.eventsFocus:SetActive(true)
    local NARRATE_HEADER = true
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("AdventureZoneOverview", NARRATE_HEADER)
end

function ZO_AdventureZoneOverview_Gamepad:OnHiding()
    ZO_AdventureZoneOverview_Shared.OnHiding(self)

    self.eventsFocus:SetActive(false)
end

function ZO_AdventureZoneOverview_Gamepad:GetSceneName()
    return "adventureZoneOverviewGamepad"
end

function ZO_AdventureZoneOverview_Gamepad.OnControlInitialized(control)
    ADVENTURE_ZONE_OVERVIEW_GAMEPAD = ZO_AdventureZoneOverview_Gamepad:New(control)
end