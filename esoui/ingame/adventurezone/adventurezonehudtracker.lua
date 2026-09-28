local function GetAZDisplayName()
    return zo_strformat(SI_ADVENTURE_ZONE_TITLE_FORMATTER, GetAdventureZoneDisplayName())
end

ZO_AdventureZoneHUDTracker = ZO_HUDTracker_Base:Subclass()

function ZO_AdventureZoneHUDTracker:Initialize(...)
    ZO_HUDTracker_Base.Initialize(self, ...)

    local fragment = self:GetFragment()
    ADVENTURE_ZONE_HUD_TRACKER_FRAGMENT = fragment
    fragment:SetHiddenForReason("NotInAdventureZone", true)

    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, ZO_GetEventForwardingFunction(self, self.Update))
    self.control:RegisterForEvent(EVENT_HOLIDAYS_CHANGED, ZO_GetEventForwardingFunction(self, self.Update))
end

function ZO_AdventureZoneHUDTracker:DeferredInitialize(...)
    self.showOverviewKeybindDescriptor =
    {
        -- Even though this is an ethereal keybind, the name will still be read during screen narration
        keybind = "TOGGLE_ACTIVITY_HUD_TRACKER",
        ethereal = true,
        narrateEthereal = true,
        etherealNarrationOrder = 1,
        visible = IsInAdventureZone,
    }
    self.showOverviewKeybindButton = self.container:GetNamedChild("ShowOverview")
    self.showOverviewKeybindButton:SetKeybindButtonDescriptor(self.showOverviewKeybindDescriptor)

    self.factionScoreControls =
    {
        [ADVENTURE_ZONE_FACTION_THE_RUCKUS] =
        {
            score = self.container:GetNamedChild("FactionScore1"),
            icon = self.container:GetNamedChild("FactionIcon1"),
        },
        [ADVENTURE_ZONE_FACTION_THOUSAND_EYES] =
        {
            score = self.container:GetNamedChild("FactionScore2"),
            icon = self.container:GetNamedChild("FactionIcon2"),
        },
        [ADVENTURE_ZONE_FACTION_GLITTERING_GOAD] =
        {
            score = self.container:GetNamedChild("FactionScore3"),
            icon = self.container:GetNamedChild("FactionIcon3"),
        },
    }
    for faction, factionControl in pairs(self.factionScoreControls) do
        factionControl.icon:SetTexture(ZO_ADVENTURE_ZONE_FACTION_ICONS[faction])
    end

    self.playerFactionIndicator = self.container:GetNamedChild("PlayerFactionIndicator")

    self:InitializeScoreRollingMeters()

    ZO_HUDTracker_Base.DeferredInitialize(self, ...)
end

function ZO_AdventureZoneHUDTracker:InitializeScoreRollingMeters()
    for faction, factionControl in pairs(self.factionScoreControls) do
        factionControl.score:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
        factionControl.score:SetIsCommaDelimited(true)
        factionControl.score:SetResizeToFitLabels(true)
        factionControl.score:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
        factionControl.transitionManager = factionControl.score:GetOrCreateTransitionManager()
    end
end

function ZO_AdventureZoneHUDTracker:GetHUDElementInfo()
    local DISPLAY_NAME = GetAZDisplayName
    local CONFIG =
    {
        isValid = IsAdventureZoneActive,
    }
    return DISPLAY_NAME, CONFIG
end

function ZO_AdventureZoneHUDTracker:GetHUDElementOptionKeys()
    local KEY = "Adventure"
    local DISPLAY_NAME = GetAZDisplayName
    local isOptionValid = IsAdventureZoneActive
    return KEY, DISPLAY_NAME, isOptionValid
end

function ZO_AdventureZoneHUDTracker:RegisterEvents()
    ZO_HUDTracker_Base.RegisterEvents(self)

    EVENT_MANAGER:RegisterForEvent("AdventureZoneHUDTracker", EVENT_ADVENTURE_ZONE_FACTION_STANDING_UPDATE_RECEIVED, function() self:RefreshScores() end)
end

function ZO_AdventureZoneHUDTracker:ApplyPlatformStyle(style)
    ZO_HUDTracker_Base.ApplyPlatformStyle(self, style)

    ApplyTemplateToControl(self.showOverviewKeybindButton, ZO_GetPlatformTemplate("ZO_KeybindButton"))

    for faction, factionControl in pairs(self.factionScoreControls) do
        factionControl.score:SetFont(style.FONT_SUBLABEL)
    end
end

function ZO_AdventureZoneHUDTracker:OnHiding()
    ZO_HUDTracker_Base.OnHiding(self)

    KEYBIND_STRIP:RemoveKeybindButton(self.showOverviewKeybindDescriptor)
end

function ZO_AdventureZoneHUDTracker:OnShown()
    ZO_HUDTracker_Base.OnShown(self)

    KEYBIND_STRIP:AddKeybindButton(self.showOverviewKeybindDescriptor)
    self:SetHeaderText(GetAZDisplayName())
    self:RefreshAnchors()
    local UPDATE_IMMEDIATELY = true
    self:RefreshScores(UPDATE_IMMEDIATELY)
end

function ZO_AdventureZoneHUDTracker:Update()
    local hidden = not (IsInAdventureZone() and IsAdventureZoneActive())
    self:GetFragment():SetHiddenForReason("NotInAdventureZone", hidden, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)

    ZO_HUDTracker_Base.Update(self)
end

function ZO_AdventureZoneHUDTracker:RefreshAnchors()
    ZO_HUDTracker_Base.RefreshAnchors(self)

    local faction = GetUnitAdventureZoneFaction("player")
    if faction == ADVENTURE_ZONE_FACTION_NONE then
        self.playerFactionIndicator:SetHidden(true)
    else
        self.playerFactionIndicator:SetHidden(false)
        self.playerFactionIndicator:SetAnchor(RIGHT, self.factionScoreControls[faction].icon, LEFT, -10)
    end
end

function ZO_AdventureZoneHUDTracker:RefreshScores(updateImmediately)
    if self:GetFragment():IsShowing() then
        for faction, factionControl in pairs(self.factionScoreControls) do
            if updateImmediately then
                factionControl.transitionManager:SetValueImmediately(GetAdventureZoneFactionReputation(faction))
            else
                factionControl.transitionManager:SetValue(GetAdventureZoneFactionReputation(faction))
            end
        end
    end
end

function ZO_AdventureZoneHUDTracker:GetPriority()
    return ZO_HUD_TRACKER_PRIORITY.ADVENTURE_ZONE
end

function ZO_AdventureZoneHUDTracker.OnInitialized(control)
    ADVENTURE_ZONE_HUD_TRACKER = ZO_AdventureZoneHUDTracker:New(control)
end

HUD_TRACKER_MANAGER:RegisterTracker("ZO_AdvZoneHUDTracker_Template", "ZO_AdvZoneHUDTracker")