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

function ZO_AdventureZoneHUDTracker:InitializeStyles()
    self.styles =
    {
        keyboard =
        {
            CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT),
            CONTAINER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT),
            FONT_HEADER = "ZoFontGameShadow",
            FONT_SUBLABEL = "ZoFontGameShadow",
            RESIZE_TO_FIT_PADDING_HEIGHT = 30,
            KEYBIND_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.headerLabel, TOPLEFT, 0, -7),
            KEYBIND_BUTTON_TEMPLATE = "ZO_KeybindButton_Keyboard_Template",
            TEXT_HORIZONTAL_ALIGNMENT = TEXT_ALIGN_LEFT,
            TOP_LEVEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT, ZO_EndDunHUDTracker, BOTTOMLEFT),
            TOP_LEVEL_SECONDARY_ANCHOR = ZO_Anchor:New(RIGHT, GuiRoot, RIGHT, 0, 0, ANCHOR_CONSTRAINS_X),
        },
        gamepad =
        {
            CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT),
            CONTAINER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, nil, nil, -15, 0),
            FONT_HEADER = "ZoFontGamepadBold27",
            FONT_SUBLABEL = "ZoFontGamepad34",
            RESIZE_TO_FIT_PADDING_HEIGHT = 50,
            KEYBIND_ANCHOR = ZO_Anchor:New(RIGHT, self.headerLabel, LEFT, -5, 5),
            KEYBIND_BUTTON_TEMPLATE = "ZO_KeybindButton_Gamepad_Template",
            TEXT_HORIZONTAL_ALIGNMENT = TEXT_ALIGN_RIGHT,
            TOP_LEVEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT, ZO_EndDunHUDTracker, BOTTOMLEFT),
            TOP_LEVEL_SECONDARY_ANCHOR = ZO_Anchor:New(RIGHT, GuiRoot, RIGHT, 0, 0, ANCHOR_CONSTRAINS_X),
        },
    }

    ZO_HUDTracker_Base.InitializeStyles(self)
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

function ZO_AdventureZoneHUDTracker:RegisterEvents()
    ZO_HUDTracker_Base.RegisterEvents(self)

    EVENT_MANAGER:RegisterForEvent("AdventureZoneHUDTracker", EVENT_ADVENTURE_ZONE_FACTION_STANDING_UPDATE_RECEIVED, function() self:RefreshScores() end)
end

function ZO_AdventureZoneHUDTracker:ApplyPlatformStyle(style)
    ZO_HUDTracker_Base.ApplyPlatformStyle(self, style)

    self.showOverviewKeybindButton:ClearAnchors()
    style.KEYBIND_ANCHOR:AddToControl(self.showOverviewKeybindButton)
    ApplyTemplateToControl(self.showOverviewKeybindButton, style.KEYBIND_BUTTON_TEMPLATE)

    for faction, factionControl in pairs(self.factionScoreControls) do
        factionControl.score:SetFont(style.FONT_SUBLABEL)
    end
end

function ZO_AdventureZoneHUDTracker:GetPrimaryAnchor()
    return self.currentStyle.TOP_LEVEL_PRIMARY_ANCHOR
end

function ZO_AdventureZoneHUDTracker:GetSecondaryAnchor()
    return self.currentStyle.TOP_LEVEL_SECONDARY_ANCHOR
end

function ZO_AdventureZoneHUDTracker:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButton(self.showOverviewKeybindDescriptor)
end

function ZO_AdventureZoneHUDTracker:OnShown()
    KEYBIND_STRIP:AddKeybindButton(self.showOverviewKeybindDescriptor)
    self:SetHeaderText(zo_strformat(SI_ADVENTURE_ZONE_TITLE_FORMATTER, GetAdventureZoneDisplayName()))
    self:RefreshAnchors()
    local UPDATE_IMMEDIATELY = true
    self:RefreshScores(UPDATE_IMMEDIATELY)
end

function ZO_AdventureZoneHUDTracker:Update()
    local hidden = not (IsInAdventureZone() and IsAdventureZoneActive())
    self:GetFragment():SetHiddenForReason("NotInAdventureZone", hidden, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)
    return true
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

function ZO_AdventureZoneHUDTracker.OnInitialized(control)
    ADVENTURE_ZONE_HUD_TRACKER = ZO_AdventureZoneHUDTracker:New(control)
end