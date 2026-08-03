local AUTO_HIDE_DELAY_SECONDS = 7.0

ZO_EndlessDungeonHUD = ZO_InitializingObject:Subclass()

function ZO_EndlessDungeonHUD:Initialize(control)
    self.control = control

    -- Order matters:
    self:InitializeControls()
    self:InitializeStyles()
    self:InitializeEvents()
    self:RefreshState()
end

function ZO_EndlessDungeonHUD:InitializeControls()
    local control = self.control
    control.object = self
    local scoreContainer = control:GetNamedChild("ScoreContainer")
    self.scoreContainer = scoreContainer
    self.hudElementRef = scoreContainer:GetNamedChild("HUDElementRef")

    self.alphaTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_EndlessDungeonHUD_AlphaAnimation", self.control)

    self.reviveIconTexture = self.scoreContainer:GetNamedChild("ReviveIcon")
    self.reviveIconTexture:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())

    self.reviveLabel = self.scoreContainer:GetNamedChild("ReviveCount")
    self.reviveLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    self.reviveLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    self.reviveLabel:SetResizeToFitLabels(true)
    self.reviveLabelTransitionManager = self.reviveLabel:GetOrCreateTransitionManager()
    self.reviveLabelTransitionManager:SetMaxTransitionSteps(50)

    self.scoreHeaderLabel = self.scoreContainer:GetNamedChild("Header")

    self.scoreLabel = self.scoreContainer:GetNamedChild("Score")
    self.scoreLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    self.scoreLabel:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
    self.scoreLabel:SetResizeToFitLabels(true)
    self.scoreLabelTransitionManager = self.scoreLabel:GetOrCreateTransitionManager()
    self.scoreLabelTransitionManager:SetMaxTransitionSteps(50)
    self.scoreLabelTransitionManager:SetTransitionAnimationStartedCallback(function(rollingMeterLabel, currentStep, numSteps, currentValue, targetValue)
        if currentValue == targetValue and not self.fragment:IsHidden() then
            PlaySound(SOUNDS.ENDLESS_DUNGEON_SCORE_FINAL_FLIP)
        end
    end)

    self.fragment = ZO_HUDFadeSceneFragment:New(control)
    ENDLESS_DUNGEON_HUD_FRAGMENT = self.fragment
end

function ZO_EndlessDungeonHUD:InitializeStyles()
    local KEYBOARD_STYLE =
    {
        containerAnchor = ZO_Anchor:New(BOTTOMRIGHT),
        scoreHeaderAnchor = ZO_Anchor:New(LEFT, nil, LEFT, 0, 2),
        scoreOffsetY = -2,
        reviveIconAnchor = ZO_Anchor:New(LEFT, self.scoreLabel, RIGHT, 17),
        reviveCountOffsetY = 0,
        headerFont = "ZoFontGameLargeBold",
        valueFont = "ZoFontWinH2",
        iconSize = 40,
        modifyTextType = MODIFY_TEXT_TYPE_NONE,
    }
    local GAMEPAD_STYLE =
    {
        containerAnchor = ZO_Anchor:New(BOTTOMLEFT),
        reviveIconAnchor = ZO_Anchor:New(LEFT),
        reviveCountOffsetY = 0,
        scoreHeaderAnchor = ZO_Anchor:New(LEFT, self.reviveLabel, RIGHT, 20, 5),
        scoreOffsetY = -5,
        headerFont = "ZoFontGamepad27",
        valueFont = "ZoFontGamepad42",
        iconSize = 44,
        modifyTextType = MODIFY_TEXT_TYPE_UPPERCASE,
    }

    local KEYBOARD_CONFIG =
    {
        defaultAnchor = KEYBOARD_STYLE.containerAnchor,
    }
    local GAMEPAD_CONFIG =
    {
        defaultAnchor = GAMEPAD_STYLE.containerAnchor,
    }

    local ENDLESS_DUNGEON_SCORE_OPTIONS =
    {
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.ENUM,
            name = GetString(SI_INTERFACE_OPTIONS_SHOW_RAID_LIVES),
            tooltipText = GetString(SI_INTERFACE_OPTIONS_SHOW_RAID_LIVES_TOOLTIP),
            key = "ShowLives",
            valueStringPrefix = "SI_RAIDLIFEVISIBILITYCHOICE",
            values = { RAID_LIFE_VISIBILITY_CHOICE_OFF, RAID_LIFE_VISIBILITY_CHOICE_AUTOMATIC, RAID_LIFE_VISIBILITY_CHOICE_ON, },
            defaultValue = function()
                return tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_RAID_LIVES))
            end,
            dontSave = true,
            callback = function(element, subKey, oldValue, value)
                if value ~= oldValue then
                    SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_RAID_LIVES, tostring(value))
                end
            end,
        },
    }

    local DISPLAY_NAME = GetString(SI_HUD_EDITOR_ENDLESS_DUNGEON_SCORE)
    HUD_MANAGER:RegisterKeyboardElement(self.scoreContainer, DISPLAY_NAME, KEYBOARD_CONFIG, ENDLESS_DUNGEON_SCORE_OPTIONS)
    HUD_MANAGER:RegisterGamepadElement(self.scoreContainer, DISPLAY_NAME, GAMEPAD_CONFIG, ENDLESS_DUNGEON_SCORE_OPTIONS)
    
    ZO_PlatformStyle:New(ZO_GetCallbackForwardingFunction(self, self.OnPlatformStyleChanged), KEYBOARD_STYLE, GAMEPAD_STYLE)
end

function ZO_EndlessDungeonHUD:InitializeEvents()
    ENDLESS_DUNGEON_MANAGER:RegisterCallback("AttemptsRemainingChanged", ZO_GetCallbackForwardingFunction(self, self.OnDungeonLivesRemainingUpdated))
    ENDLESS_DUNGEON_MANAGER:RegisterCallback("ScoreChanged", ZO_GetCallbackForwardingFunction(self, self.OnDungeonScoreUpdated))
    ENDLESS_DUNGEON_MANAGER:RegisterCallback("StateChanged", ZO_GetCallbackForwardingFunction(self, self.OnDungeonStateChanged))

    EVENT_MANAGER:RegisterForEvent("EndlessDungeonHUD", EVENT_INTERFACE_SETTING_CHANGED, ZO_GetEventForwardingFunction(self, self.OnInterfaceSettingChanged))
    EVENT_MANAGER:RegisterForEvent("EndlessDungeonHUD", EVENT_PLAYER_ACTIVATED, ZO_GetEventForwardingFunction(self, self.OnPlayerActivated))
    self.control:SetHandler("OnUpdate", ZO_GetEventForwardingFunction(self, self.OnUpdate))
end

-- User Interface

function ZO_EndlessDungeonHUD:SetAlwaysVisible(alwaysVisible)
    if self.alwaysVisible == alwaysVisible then
        return
    end

    self.alwaysVisible = alwaysVisible
    self:Show()
end

function ZO_EndlessDungeonHUD:CanUpdate()
    -- Updates cannot be processed while the player is dead
    -- or the animation and fade timer could elapse before
    -- the fragment is even permitted to be visible.
    return not self.fragment:IsHiddenForReason("Dead")
end

function ZO_EndlessDungeonHUD:Hide()
    if self.alwaysVisible then
        -- Suppress requests to hide when the Always Visible flag is set.
        return
    end

    self.alphaTimeline:PlayBackward()
    self:StopFadeOutTimer()
end

function ZO_EndlessDungeonHUD:SetHidden(hidden)
    if hidden and self.alwaysVisible then
        -- Suppress requests to hide when the Always Visible flag is set.
        return
    end

    self.fragment:SetHiddenForReason("FadedOut", hidden)
end

function ZO_EndlessDungeonHUD:SetUpdateQueueEnabled(enabled)
    if enabled then
        EVENT_MANAGER:RegisterForEvent("EndlessDungeonHUD", EVENT_PLAYER_ALIVE, ZO_GetEventForwardingFunction(self, self.OnPlayerAlive))
    else
        EVENT_MANAGER:UnregisterForEvent("EndlessDungeonHUD", EVENT_PLAYER_ALIVE)

        -- Clear any queued values.
        self.queuedLivesRemaining = nil
        self.queuedScore = nil
    end
end

function ZO_EndlessDungeonHUD:RefreshState()
    local fragment = self.fragment

    -- The HUD elements should only be visible when the corresponding User Interface
    -- setting is not disabled.
    local visibilitySetting = tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_RAID_LIVES))
    if visibilitySetting == RAID_LIFE_VISIBILITY_CHOICE_OFF then
        fragment:SetHiddenForReason("SettingDisabled", true)
        self:SetAlwaysVisible(false)
    else
        fragment:SetHiddenForReason("SettingDisabled", false)
        -- If the "always on" option is selected, ensure that the HUD elements are
        -- always visible while in an active Endless Dungeon.
        self:SetAlwaysVisible(visibilitySetting == RAID_LIFE_VISIBILITY_CHOICE_ON)
    end

    -- The HUD elements should only be visible while in an active Endless Dungeon.
    local wasDungeonActive = fragment:IsHiddenForReason("ActiveDungeon")
    local isDungeonActive = ENDLESS_DUNGEON_MANAGER:IsEndlessDungeonStarted()
    fragment:SetHiddenForReason("ActiveDungeon", not isDungeonActive)
    if wasDungeonActive ~= isDungeonActive then
        if isDungeonActive then
            -- The player is now in an active Endless Dungeon.
            self:UpdateHUD()
            self:Show()
        else
            -- The player is no longer in an active Endless Dungeon.
            self:Hide()
        end
    end
end

function ZO_EndlessDungeonHUD:Show()
    self.alphaTimeline:PlayForward()
    self:SetHidden(false)
end

function ZO_EndlessDungeonHUD:StartFadeOutTimer()
    self.fadeOutTimeS = GetFrameTimeSeconds() + AUTO_HIDE_DELAY_SECONDS
end

function ZO_EndlessDungeonHUD:StopFadeOutTimer()
    self.fadeOutTimeS = nil
end

function ZO_EndlessDungeonHUD:UpdateHUD()
    local numAttemptsRemaining = ENDLESS_DUNGEON_MANAGER:GetAttemptsRemaining()
    self.reviveLabelTransitionManager:SetValueImmediately(numAttemptsRemaining)

    local score = ENDLESS_DUNGEON_MANAGER:GetScore()
    self.scoreLabelTransitionManager:SetValueImmediately(score)
end

-- Event Handlers

function ZO_EndlessDungeonHUD:OnAlphaAnimationStarted()
    self:SetHidden(false)
end

function ZO_EndlessDungeonHUD:OnAlphaAnimationStopped(isPlayingBackward)
    if isPlayingBackward then
        self:SetHidden(isPlayingBackward)
        self:StopFadeOutTimer()
    else
        self:StartFadeOutTimer()
    end
end

function ZO_EndlessDungeonHUD:OnDungeonLivesRemainingUpdated(livesRemaining)
    if not self:CanUpdate() then
        -- Queue this update for when the player is alive again.
        self.queuedLivesRemaining = livesRemaining
        self:SetUpdateQueueEnabled(true)
        return
    end

    self.queuedLivesRemaining = nil
    self.reviveLabelTransitionManager:SetValue(livesRemaining)
    self:Show()
end

function ZO_EndlessDungeonHUD:OnDungeonScoreUpdated(score)
    if not self:CanUpdate() then
        -- Queue this update for when the player is alive again.
        self.queuedScore = score
        self:SetUpdateQueueEnabled(true)
        return
    end

    self.queuedScore = nil
    zo_callLater(function()
        if not ENDLESS_DUNGEON_MANAGER:IsPlayerInEndlessDungeon() then
            return
        end

        self.scoreLabelTransitionManager:SetValue(score)
        self:Show()

        if not self.fragment:IsHidden() then
            -- Play the calculation audio clip immediately.
            PlaySound(SOUNDS.ENDLESS_DUNGEON_SCORE_CALCULATE)
        end
    end, 1200)
end

function ZO_EndlessDungeonHUD:OnDungeonStateChanged()
    -- Order matters:
    self:SetUpdateQueueEnabled(false) -- Clear any queued updates.
    self:RefreshState()
end

function ZO_EndlessDungeonHUD:OnInterfaceSettingChanged(settingType, settingId)
    if settingType == SETTING_TYPE_UI and settingId == UI_SETTING_SHOW_RAID_LIVES then
        self:RefreshState()
    end
end

function ZO_EndlessDungeonHUD:OnPlatformStyleChanged(style)
    style.containerAnchor:Set(self.hudElementRef)
    self.scoreContainer:SetHeight(style.iconSize)

    self.reviveIconTexture:ClearAnchors() -- Prevent cyclic anchoring
    style.scoreHeaderAnchor:Set(self.scoreHeaderLabel)
    self.scoreHeaderLabel:SetFont(style.headerFont)
    self.scoreHeaderLabel:SetModifyTextType(style.modifyTextType)
    self.scoreLabel:SetAnchorOffsets(5, style.scoreOffsetY)
    self.scoreLabel:SetFont(style.valueFont)
    style.reviveIconAnchor:Set(self.reviveIconTexture)
    self.reviveIconTexture:SetDimensions(style.iconSize, style.iconSize)
    self.reviveLabel:SetAnchorOffsets(5, style.reviveCountOffsetY)
    self.reviveLabel:SetFont(style.valueFont)
end

function ZO_EndlessDungeonHUD:OnPlayerActivated()
    self:OnDungeonStateChanged()
end

function ZO_EndlessDungeonHUD:OnPlayerAlive()
    if self.queuedLivesRemaining then
        -- Process the last queued lives remaining update.
        self:OnDungeonLivesRemainingUpdated(self.queuedLivesRemaining)
    end

    if self.queuedScore then
        -- Process the last queued score update.
        self:OnDungeonScoreUpdated(self.queuedScore)
    end

    -- Disabled the update queue also clears any queued values;
    -- this must occur after queued updates have been processed.
    self:SetUpdateQueueEnabled(false)
end

function ZO_EndlessDungeonHUD:OnUpdate()
    if self.fadeOutTimeS and GetFrameTimeSeconds() >= self.fadeOutTimeS then
        self:Hide()
    end
end

-- Static Methods

function ZO_EndlessDungeonHUD.OnControlInitialized(control)
    ENDLESS_DUNGEON_HUD = ZO_EndlessDungeonHUD:New(control)
end