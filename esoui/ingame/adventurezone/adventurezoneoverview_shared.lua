ZO_ADVENTURE_ZONE_FACTION_ICONS =
{
    [ADVENTURE_ZONE_FACTION_THE_RUCKUS] = "EsoUI/Art/Stats/u49_faction_ruckus_64.dds",
    [ADVENTURE_ZONE_FACTION_THOUSAND_EYES] = "EsoUI/Art/Stats/u49_faction_thousandeyes_64.dds",
    [ADVENTURE_ZONE_FACTION_GLITTERING_GOAD] = "EsoUI/Art/Stats/u49_faction_glittering_64.dds",
}

-------------------------------
-- Adventure Zone Event Tile --
-------------------------------

ZO_AdventureZoneEventTile_Shared = ZO_ContextualActionsTile:Subclass()

function ZO_AdventureZoneEventTile_Shared:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

function ZO_AdventureZoneEventTile_Shared:Initialize(...)
    ZO_ContextualActionsTile.Initialize(self, ...)

    self.locationLabel = self.control:GetNamedChild("Location")
    self.statusLabel = self.control:GetNamedChild("Status")
end

-- Begin ZO_ContextualActionsTile Overrides --

function ZO_AdventureZoneEventTile_Shared:Layout(index)
    self.iconTexture:SetTexture(GetAdventureZoneEventLocationBackgroundFileIndex(index))
    self.locationLabel:SetText(zo_strformat(SI_ADVENTURE_ZONE_EVENT_FORMATTER, GetAdventureZoneEventLocationName(index)))
    self.titleLabel:SetText(zo_strformat(SI_ADVENTURE_ZONE_EVENT_FORMATTER, GetAdventureZoneEventDisplayName(index)))

    local function UpdateTimer()
        if self.parentObject and self.parentObject:IsShowing() then
            local eventState = GetAdventureZoneEventLocationState(index)
            local statusText = ""
            if eventState == ADVENTURE_ZONE_WORLD_EVENT_LOCATION_STATE_INACTIVE then
                statusText = GetString(SI_ADVENTURE_ZONE_EVENT_INACTIVE)
            elseif eventState == ADVENTURE_ZONE_WORLD_EVENT_LOCATION_STATE_STARTS_SOON then
                local secondsRemaining = zo_max((self.startTimestamp / ZO_ONE_SECOND_IN_MILLISECONDS) - GetTimeStamp(), 0) 
                local timeRemainingText = ZO_FormatTime(secondsRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_SECONDS)
                statusText = zo_strformat(SI_ADVENTURE_ZONE_EVENT_STARTS_SOON_FORMATTER, timeRemainingText)
            elseif eventState == ADVENTURE_ZONE_WORLD_EVENT_LOCATION_STATE_ACTIVE then
                statusText = GetString(SI_ADVENTURE_ZONE_EVENT_ACTIVE)
            end
            self.statusLabel:SetText(statusText)
        end
    end

    self.control:SetHandler("OnUpdate", UpdateTimer)
end

-- End ZO_ContextualActionsTile Overrides --

function ZO_AdventureZoneEventTile_Shared:SetParentObject(parentObject)
    self.parentObject = parentObject
end

-----------------------------
-- Adventure Zone Overview --
-----------------------------

ZO_AdventureZoneOverview_Shared = ZO_DeferredInitializingObject:Subclass()

function ZO_AdventureZoneOverview_Shared:Initialize(control)
    self.control = control
    control.object = self

    local scene = ZO_Scene:New(self:GetSceneName(), SCENE_MANAGER)
    self.scene = scene
    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)

    self.factionScoreControls =
    {
        [ADVENTURE_ZONE_FACTION_THE_RUCKUS] = self.control:GetNamedChild("FactionScore1"),

        [ADVENTURE_ZONE_FACTION_THOUSAND_EYES] = self.control:GetNamedChild("FactionScore2"),

        [ADVENTURE_ZONE_FACTION_GLITTERING_GOAD] = self.control:GetNamedChild("FactionScore3"),
    }

    self.eventsDivider = self.control:GetNamedChild("EventsDivider")
    self.eventsContainer = self.control:GetNamedChild("EventsContainer")
    self.playerPointsControl = self.control:GetNamedChild("PlayerPointsContainer")
    self.playerPointsLabel = self.playerPointsControl:GetNamedChild("PlayerPointsLabel")
    self.playerPointsTexture = self.playerPointsControl:GetNamedChild("PlayerFaction")

    self.eventTileControls =
    {
        [1] = self.eventsContainer:GetNamedChild("Event2"),

        [2] = self.eventsContainer:GetNamedChild("Event1"),

        [3] = self.eventsContainer:GetNamedChild("Event3"),
    }

    for index, eventTile in ipairs(self.eventTileControls) do
        eventTile.eventIndex = index
    end

    ZO_DeferredInitializingObject.Initialize(self, scene)
end

function ZO_AdventureZoneOverview_Shared:OnDeferredInitialize()
    for faction, scoreControl in pairs(self.factionScoreControls) do
        scoreControl:GetNamedChild("Name"):SetText(zo_strformat(GetString("SI_ADVENTUREZONEFACTION", faction)))
        scoreControl:GetNamedChild("Icon"):SetTexture(ZO_ADVENTURE_ZONE_FACTION_ICONS[faction])
        scoreControl:GetNamedChild("Score"):SetText(ZO_CommaDelimitDecimalNumber(GetAdventureZoneFactionReputation(faction)))
    end

    self.playerPointsLabel:SetText(zo_strformat(SI_ADVENTURE_ZONE_POINTS_EARNED, ZO_SELECTED_TEXT:Colorize(GetAdventureZonePlayerReputation())))
    self.playerPointsTexture:SetTexture(ZO_ADVENTURE_ZONE_FACTION_ICONS[GetUnitAdventureZoneFaction("player")])

    for index, eventControl in ipairs(self.eventTileControls) do
        eventControl.object:SetParentObject(self)
        eventControl.object:Layout(index)
    end

    self:RegisterForEvents()
    self:InitializeKeybindStripDescriptor()
end

function ZO_AdventureZoneOverview_Shared:RegisterForEvents()
    local function RefreshScores()
        self:RefreshScores()
    end

    self.control:RegisterForEvent(EVENT_ADVENTURE_ZONE_FACTION_STANDING_UPDATE_RECEIVED, RefreshScores)
    self.control:RegisterForEvent(EVENT_ADVENTURE_ZONE_FACTION_REPUTATION_CHANGED, RefreshScores)

    local function RefreshEvents()
        self:RefreshEvents()
    end

    self.control:RegisterForEvent(EVENT_ADVENTURE_ZONE_WORLD_EVENT_INIT, RefreshEvents)
    self.control:RegisterForEvent(EVENT_ADVENTURE_ZONE_WORLD_EVENT_STARTS_SOON, RefreshEvents)
end

function ZO_AdventureZoneOverview_Shared:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_ADVENTURE_ZONE_VIEW_BOSS_PANEL),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                SYSTEMS:ShowScene("adventureZoneBossTree")
            end,
        },

        {
            name = GetString(SI_ADVENTURE_ZONE_VIEW_SHOW_ON_MAP),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                ShowAdventureZoneEventLocationOnMap(self.selectedEvent)
            end,
            visible = function()
                return self.selectedEvent
            end,
        },

        {
            name = GetString(SI_DIALOG_CLOSE),
            keybind = "TOGGLE_ACTIVITY_HUD_TRACKER",
        },
    }
end

function ZO_AdventureZoneOverview_Shared:OnShowing()
    self:RefreshScores()
    self:RefreshEvents()

    self.playerPointsControl:ClearAnchors()
    self.eventsDivider:ClearAnchors()
    local playerFaction = GetUnitAdventureZoneFaction("player")
    if playerFaction ~= ADVENTURE_ZONE_FACTION_NONE then
        self.playerPointsTexture:SetTexture(ZO_ADVENTURE_ZONE_FACTION_ICONS[playerFaction])
        self.playerPointsControl:SetAnchor(TOP, self.factionScoreControls[GetUnitAdventureZoneFaction("player")], BOTTOM, 5)
        self.playerPointsControl:SetHidden(false)
        self.eventsDivider:SetAnchor(CENTER, self.factionScoreControls[2], nil, 0, 0, ANCHOR_CONSTRAINS_X)
        self.eventsDivider:SetAnchor(TOP, self.playerPointsControl, BOTTOM, 0, 5, ANCHOR_CONSTRAINS_Y)
    else
        self.playerPointsControl:SetHidden(true)
        self.eventsDivider:SetAnchor(TOP, self.factionScoreControls[2], BOTTOM, 0, 20)
    end

    PlaySound(SOUNDS.ADVENTURE_ZONE_OVERVIEW_OPENED)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RemoveDefaultExit()

    ADVENTURE_ZONE_MANAGER:SetPanelToOpen(ZO_ADVENTURE_ZONE_PANELS.OVERVIEW)
end

function ZO_AdventureZoneOverview_Shared:OnHiding()
    PlaySound(SOUNDS.ADVENTURE_ZONE_OVERVIEW_CLOSED)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_AdventureZoneOverview_Shared:OnHidden()
    KEYBIND_STRIP:RestoreDefaultExit()
end

function ZO_AdventureZoneOverview_Shared:IsShowing()
    return self.scene:IsShowing()
end

function ZO_AdventureZoneOverview_Shared:RefreshScores()
    if self.scene:IsShowing() then
        for faction, scoreControl in pairs(self.factionScoreControls) do
            scoreControl:GetNamedChild("Score"):SetText(ZO_CommaDelimitDecimalNumber(GetAdventureZoneFactionReputation(faction)))
        end
    end

    self.playerPointsLabel:SetText(zo_strformat(SI_ADVENTURE_ZONE_POINTS_EARNED, ZO_SELECTED_TEXT:Colorize(GetAdventureZonePlayerReputation())))
end

function ZO_AdventureZoneOverview_Shared:RefreshEvents()
    for index, eventTile in ipairs(self.eventTileControls) do
        eventTile.object.startTimestamp = GetAdventureZoneEventLocationStartTimestampMs(index)
    end
end

function ZO_AdventureZoneOverview_Shared:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

ZO_AdventureZoneOverview_Shared:MUST_IMPLEMENT("GetSceneName")