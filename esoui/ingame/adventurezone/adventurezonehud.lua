ZO_AdventureZoneHUD = ZO_InitializingObject:Subclass()

function ZO_AdventureZoneHUD:Initialize(control)
    self.control = control

    -- Order matters:
    self:InitializeControls()
    self:InitializeStyles()
    self:InitializeEvents()
    self:RefreshState()
end

function ZO_AdventureZoneHUD:InitializeControls()
    local control = self.control
    control.object = self

    self.playerScoreContainer = control:GetNamedChild("PlayerScoreContainer")
    self.playerFactionIcon = self.playerScoreContainer:GetNamedChild("FactionIcon")
    self.playerScoreLabel = self.playerScoreContainer:GetNamedChild("Score")
    self.hudElementRef = self.playerScoreContainer:GetNamedChild("HUDElementRef")

    self.playerScoreLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    self.playerScoreLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    self.playerScoreLabel:SetResizeToFitLabels(true)
    self.playerScoreLabelTransitionManager = self.playerScoreLabel:GetOrCreateTransitionManager()
    self.playerScoreLabelTransitionManager:SetMaxTransitionSteps(10)

    self.fragment = ZO_HUDFadeSceneFragment:New(control)
    ADVENTURE_ZONE_HUD_FRAGMENT = self.fragment
end

function ZO_AdventureZoneHUD:InitializeStyles()
    local KEYBOARD_STYLE =
    {
        anchor = ZO_Anchor:New(BOTTOMRIGHT),
        labelFont = "ZoFontWinH2",
        iconSize = 40,
    }
    local GAMEPAD_STYLE =
    {
        anchor = ZO_Anchor:New(BOTTOMLEFT),
        labelFont = "ZoFontGamepad42",
        iconSize = 44,
    }

    local KEYBOARD_CONFIG =
    {
        defaultAnchor = KEYBOARD_STYLE.anchor,
        isValid = IsAdventureZoneActive,
    }
    local GAMEPAD_CONFIG =
    {
        defaultAnchor = GAMEPAD_STYLE.anchor,
        isValid = IsAdventureZoneActive,
    }
    local DISPLAY_NAME = function()
        return zo_strformat(SI_HUD_EDITOR_ADVENTURE_ZONE_SCORE, GetAdventureZoneDisplayName())
    end
    HUD_MANAGER:RegisterKeyboardElement(self.playerScoreContainer, DISPLAY_NAME, KEYBOARD_CONFIG)
    HUD_MANAGER:RegisterGamepadElement(self.playerScoreContainer, DISPLAY_NAME, GAMEPAD_CONFIG)

    ZO_PlatformStyle:New(ZO_GetCallbackForwardingFunction(self, self.OnPlatformStyleChanged), KEYBOARD_STYLE, GAMEPAD_STYLE)
end

function ZO_AdventureZoneHUD:InitializeEvents()
    EVENT_MANAGER:RegisterForEvent("AdventureZoneHUD", EVENT_ADVENTURE_ZONE_FACTION_REPUTATION_CHANGED, ZO_GetEventForwardingFunction(self, self.OnFactionReputationChanged))
    EVENT_MANAGER:RegisterForEvent("AdventureZoneHUD", EVENT_PLAYER_ACTIVATED, ZO_GetEventForwardingFunction(self, self.OnPlayerActivated))
    EVENT_MANAGER:RegisterForEvent("AdventureZoneHUD", EVENT_ADVENTURE_ZONE_FACTION_CHOSEN, ZO_GetEventForwardingFunction(self, self.RefreshState))
end

-- User Interface

function ZO_AdventureZoneHUD:CanUpdate()
    -- Updates cannot be processed while the player is dead
    -- or the animation and fade timer could elapse before
    -- the fragment is even permitted to be visible.
    return not self.fragment:IsHiddenForReason("Dead")
end

function ZO_AdventureZoneHUD:SetHidden(hidden)
    if hidden and self.alwaysVisible then
        -- Suppress requests to hide when the Always Visible flag is set.
        return
    end

    self.fragment:SetHiddenForReason("FadedOut", hidden)
end

function ZO_AdventureZoneHUD:SetUpdateQueueEnabled(enabled)
    if enabled then
        EVENT_MANAGER:RegisterForEvent("AdventureZoneHUD", EVENT_PLAYER_ALIVE, ZO_GetEventForwardingFunction(self, self.OnPlayerAlive))
    else
        EVENT_MANAGER:UnregisterForEvent("AdventureZoneHUD", EVENT_PLAYER_ALIVE)

        -- Clear any queued values.
        self.queuedScore = nil
    end
end

function ZO_AdventureZoneHUD:RefreshState()
    local fragment = self.fragment

    -- The HUD elements should only be visible while in an active Adventure Zone.
    local isInAdventureZone = IsInAdventureZone()
    fragment:SetHiddenForReason("ActiveAdventureZone", not isInAdventureZone)
    if isInAdventureZone then
        -- The player is now in an active Adventure Zone.
        self:UpdateHUD()
    end
end

function ZO_AdventureZoneHUD:UpdateHUD()
    local faction = GetUnitAdventureZoneFaction("player")
    if faction == ADVENTURE_ZONE_FACTION_NONE then
        self.playerFactionIcon:SetHidden(true)
        self.playerScoreLabel:SetHidden(true)
    else
        self.playerFactionIcon:SetHidden(false)
        self.playerScoreLabel:SetHidden(false)
        self.playerFactionIcon:SetTexture(ZO_ADVENTURE_ZONE_FACTION_ICONS[faction])
        local score = GetAdventureZonePlayerReputation()
        self.playerScoreLabelTransitionManager:SetValueImmediately(score)
    end
end

-- Event Handlers

function ZO_AdventureZoneHUD:OnFactionReputationChanged(score)
    if not self:CanUpdate() then
        -- Queue this update for when the player is alive again.
        self.queuedScore = score
        self:SetUpdateQueueEnabled(true)
        return
    end

    self.queuedScore = nil
    zo_callLater(function()
        if not IsInAdventureZone() then
            return
        end

        self.playerScoreLabelTransitionManager:SetValue(score)
    end, 1200)
end

function ZO_AdventureZoneHUD:OnPlatformStyleChanged(style)
    style.anchor:Set(self.hudElementRef)
    self.playerScoreContainer:SetHeight(style.iconSize)
    self.playerFactionIcon:SetDimensions(style.iconSize, style.iconSize)
    self.playerScoreLabel:SetFont(style.labelFont)
end

function ZO_AdventureZoneHUD:OnPlayerActivated()
    -- Order matters:
    self:SetUpdateQueueEnabled(false) -- Clear any queued updates.
    self:RefreshState()
end

function ZO_AdventureZoneHUD:OnPlayerAlive()
    if self.queuedScore then
        -- Process the last queued score update.
        self:OnFactionReputationChanged(self.queuedScore)
    end

    -- Disabled the update queue also clears any queued values;
    -- this must occur after queued updates have been processed.
    self:SetUpdateQueueEnabled(false)
end

-- Static Methods

function ZO_AdventureZoneHUD.OnControlInitialized(control)
    ADVENTURE_ZONE_HUD = ZO_AdventureZoneHUD:New(control)
end