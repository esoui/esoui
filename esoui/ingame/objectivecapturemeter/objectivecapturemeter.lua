local ZO_ObjectiveCaptureMeter = ZO_Object:Subclass()

-- Capture Meter constants
-----------------

local MIN_NUM_PLAYERS_ONE_ARROW     = 1
local MIN_NUM_PLAYERS_TWO_ARROWS    = 3
local MIN_NUM_PLAYERS_THREE_ARROWS  = 5

local CAPTURE_BAR_BEGIN_OFFSET  = .125  -- Begins 12.5% of the way through the circle
local CAPTURE_BAR_LENGTH        = .76   -- Is 75% of a circle long. We add an extra 1% to allow the semitransparent texture to overlap the bar
local ARROW_LENGTH              = .04   -- Arrow's about 4% of the circle long
local ENDCAP_LENGTH             = .02   -- About 2% of the circle long.

local CAPTURE_BAR_ARCLENGTH = CAPTURE_BAR_LENGTH * 2 * math.pi
local ARROW_ARCLENGTH = ARROW_LENGTH * 2 * math.pi
local ENDCAP_ARCLENGTH = ENDCAP_LENGTH * 2 * math.pi

local FADE_DURATION_MS          = 150
local FULL_BAR_TIMEOUT_MS       = 4000

-- Capture Meter textures
-----------------

-- badge textures
local ALLIANCE_BADGE_TEXTURES =
{
    [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/AvA/avaCaptureBar_allianceBadge_aldmeri.dds",
    [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/AvA/avaCaptureBar_allianceBadge_ebonheart.dds",
    [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/AvA/avaCaptureBar_allianceBadge_daggerfall.dds",
}

local BATTLEGROUND_TEAM_BADGE_TEXTURES =
{
    [BATTLEGROUND_ALLIANCE_FIRE_DRAKES] = "EsoUI/Art/Battlegrounds/battlegroundsCaptureBar_teamBadge_orange.dds",
    [BATTLEGROUND_ALLIANCE_STORM_LORDS] = "EsoUI/Art/Battlegrounds/battlegroundsCaptureBar_teamBadge_purple.dds",
    [BATTLEGROUND_ALLIANCE_PIT_DAEMONS] = "EsoUI/Art/Battlegrounds/battlegroundsCaptureBar_teamBadge_green.dds",
}

-- bar textures
local ALLIANCE_BAR_TEXTURES =
{
    [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/AvA/avaCaptureBar_fill_aldmeri.dds",
    [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/AvA/avaCaptureBar_fill_ebonheart.dds",
    [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/AvA/avaCaptureBar_fill_daggerfall.dds",
}

local BATTLEGROUND_TEAM_BAR_TEXTURES =
{
    [BATTLEGROUND_ALLIANCE_FIRE_DRAKES] = "EsoUI/Art/Battlegrounds/battlegroundsCaptureBar_fill_orange.dds",
    [BATTLEGROUND_ALLIANCE_STORM_LORDS] = "EsoUI/Art/Battlegrounds/battlegroundsCaptureBar_fill_purple.dds",
    [BATTLEGROUND_ALLIANCE_PIT_DAEMONS] = "EsoUI/Art/Battlegrounds/battlegroundsCaptureBar_fill_green.dds",
}

-- point textures
local ALLIANCE_POINT_TEXTURES =
{
    [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/AvA/avaCaptureBar_point_aldmeri.dds",
    [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/AvA/avaCaptureBar_point_ebonheart.dds",
    [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/AvA/avaCaptureBar_point_daggerfall.dds",
}

local BATTLEGROUND_TEAM_POINT_TEXTURES =
{
    [BATTLEGROUND_ALLIANCE_FIRE_DRAKES] = "EsoUI/Art/Battlegrounds/battlegroundsCaptureBar_point_orange.dds",
    [BATTLEGROUND_ALLIANCE_STORM_LORDS] = "EsoUI/Art/Battlegrounds/battlegroundsCaptureBar_point_purple.dds",
    [BATTLEGROUND_ALLIANCE_PIT_DAEMONS] = "EsoUI/Art/Battlegrounds/battlegroundsCaptureBar_point_green.dds",
}

-- tail textures
local ALLIANCE_TAIL_TEXTURES =
{
    [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/AvA/avaCaptureBar_point-inverse_aldmeri.dds",
    [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/AvA/avaCaptureBar_point-inverse_ebonheart.dds",
    [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/AvA/avaCaptureBar_point-inverse_daggerfall.dds",
}

local BATTLEGROUND_TEAM_TAIL_TEXTURES =
{
    [BATTLEGROUND_ALLIANCE_FIRE_DRAKES] = "EsoUI/Art/Battlegrounds/battlegroundsCaptureBar_point-inverse_orange.dds",
    [BATTLEGROUND_ALLIANCE_STORM_LORDS] = "EsoUI/Art/Battlegrounds/battlegroundsCaptureBar_point-inverse_purple.dds",
    [BATTLEGROUND_ALLIANCE_PIT_DAEMONS] = "EsoUI/Art/Battlegrounds/battlegroundsCaptureBar_point-inverse_green.dds",
}

-------------------
-- Object functions
-------------------

function ZO_ObjectiveCaptureMeter:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ObjectiveCaptureMeter:Initialize(control)
    self.control = control
    SHARED_INFORMATION_AREA:AddFlagCapture(self.control)
    self.hiddenReasons = ZO_HiddenReasons:New()
    self:SetHiddenForReason("inCaptureArea", true)

    -- Store references to controls
    self.meter = self.control:GetNamedChild("Meter")
    self.ownerBadge = self.control:GetNamedChild("MeterOwnerBadge")
    self.progressBar = self.control:GetNamedChild("MeterProgressBar")
    self.endCap = self.control:GetNamedChild("MeterProgressBarEndCap")
    self.capturingArrow1 = self.control:GetNamedChild("MeterProgressBarCapturingArrow1")
    self.capturingArrow2 = self.control:GetNamedChild("MeterProgressBarCapturingArrow2")
    self.capturingArrow3 = self.control:GetNamedChild("MeterProgressBarCapturingArrow3")
    self.contestingArrow1 = self.control:GetNamedChild("MeterProgressBarContestingArrow1")
    self.contestingArrow2 = self.control:GetNamedChild("MeterProgressBarContestingArrow2")
    self.contestingArrow3 = self.control:GetNamedChild("MeterProgressBarContestingArrow3")

    self.lastOwningAlliance = nil

    --Set up fade in/out anim
    self.meter.fadeAnim = ZO_AlphaAnimation:New(self.meter)
    self.meter.fadeAnim:SetMinMaxAlpha(0.0, 1.0)
    self.meter:SetHidden(true)

    self.capTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CaptureBarEasing")
    self.capTimeline.startPct = 0

    --Register for updates
    EVENT_MANAGER:RegisterForEvent("GameScore", EVENT_CAPTURE_AREA_STATUS, function(...) self:ServerUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent("GameScore", EVENT_HIDE_OBJECTIVE_STATUS, function(...) self:Hide(...) end)

    local KEYBOARD_STYLE = { meter = "ZO_ObjectiveCapture_Keyboard_Template" }
    local GAMEPAD_STYLE = { meter = "ZO_ObjectiveCapture_Gamepad_Template" }
    ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)
end

function ZO_ObjectiveCaptureMeter:GetBadgeTextureFromAlliance(alliance, isBattleground)
    if isBattleground then
        return BATTLEGROUND_TEAM_BADGE_TEXTURES[alliance]
    else
        return ALLIANCE_BADGE_TEXTURES[alliance]
    end
end

function ZO_ObjectiveCaptureMeter:GetBarTextureFromAlliance(alliance, isBattleground)
    if isBattleground then
        return BATTLEGROUND_TEAM_BAR_TEXTURES[alliance]
    else
        return ALLIANCE_BAR_TEXTURES[alliance]
    end
end

function ZO_ObjectiveCaptureMeter:GetPointTextureFromAlliance(alliance, isBattleground)
    if isBattleground then
        return BATTLEGROUND_TEAM_POINT_TEXTURES[alliance]
    else
        return ALLIANCE_POINT_TEXTURES[alliance]
    end
end

function ZO_ObjectiveCaptureMeter:GetTailTextureFromAlliance(alliance, isBattleground)
    if isBattleground then
        return BATTLEGROUND_TEAM_TAIL_TEXTURES[alliance]
    else
        return ALLIANCE_TAIL_TEXTURES[alliance]
    end
end


function ZO_ObjectiveCaptureMeter:ServerUpdate(eventCode, keepId, objectiveId, battlegroundContext, capturePoolValue, capturePoolSize, capturingPlayers, contestingPlayers, owningAlliance)
    -- Short-circuit if we're walking in to an already-owned flag.
    if capturePoolValue / capturePoolSize == 1 and (self.capturePercentage == nil or self.capturePercentage == 1) then
        return
    end

    -- Show the bar frame if we're within range
    self.meter:SetHidden(false)
    self.meter.fadeAnim:FadeIn(0, FADE_DURATION_MS)
    self:SetHiddenForReason("inCaptureArea", false)

    -- Calculate percentage complete
    self.capturePercentage = capturePoolValue / capturePoolSize;

    -- Turn on appropriate arrows
    local numMoreContestingPlayers = contestingPlayers - capturingPlayers
    self.contestingArrow1:SetHidden(numMoreContestingPlayers < MIN_NUM_PLAYERS_ONE_ARROW)
    self.contestingArrow2:SetHidden(numMoreContestingPlayers < MIN_NUM_PLAYERS_TWO_ARROWS)
    self.contestingArrow3:SetHidden(numMoreContestingPlayers < MIN_NUM_PLAYERS_THREE_ARROWS)

    local numMoreCapturingPlayers = capturingPlayers - contestingPlayers
    self.capturingArrow1:SetHidden(numMoreCapturingPlayers < MIN_NUM_PLAYERS_ONE_ARROW)
    self.capturingArrow2:SetHidden(numMoreCapturingPlayers < MIN_NUM_PLAYERS_TWO_ARROWS)
    self.capturingArrow3:SetHidden(numMoreCapturingPlayers < MIN_NUM_PLAYERS_THREE_ARROWS)

    -- Determine visibility of UI
    if owningAlliance ~= 0 then
        local isBattleground = IsActiveWorldBattleground()

        -- Show alliance-specific UI elements
        self.ownerBadge:SetTexture(self:GetBadgeTextureFromAlliance(owningAlliance, isBattleground))
        self.progressBar:SetTexture(self:GetBarTextureFromAlliance(owningAlliance, isBattleground))
        self.ownerBadge:SetHidden(false)
        self.progressBar:SetHidden(false)
        self.lastOwningAlliance = owningAlliance

        -- Show appropriate endcap and arrows
        if self.capturePercentage == 1 then
            self.endCap:SetHidden(true)
            self:HideShowArrows(0)

            -- Flag is fully captured, start the timer to fade out this UI
            zo_callLater(function() self:Hide() end, FULL_BAR_TIMEOUT_MS)
        else
            if capturingPlayers > contestingPlayers then
                -- Flag is being captured; make the endcap a point
                self.endCap:SetTexture(self:GetPointTextureFromAlliance(owningAlliance, isBattleground))
                self.endCap:SetHidden(false)
                -- if we are the team that "owns" the flag (i.e. we are capturing the point for our team)
                -- then play a sound indicating that the point is being captured
                if isBattleground and owningAlliance == GetUnitAlliance("player") then
                    PlaySound(SOUNDS.BATTLEGROUND_CAPTURE_METER_CAPTURING)
                end
            elseif capturingPlayers < contestingPlayers then
                -- Flag is being contested; make the endcap a tail
                self.endCap:SetTexture(self:GetTailTextureFromAlliance(owningAlliance, isBattleground))
                self.endCap:SetHidden(false)
                -- if we aren't the team that owns the flag (i.e. we are taking the point from another team)
                -- then play a sound indicating that the point is being contested
                if isBattleground and owningAlliance ~= GetUnitAlliance("player") then
                    PlaySound(SOUNDS.BATTLEGROUND_CAPTURE_METER_CONTESTING)
                end
            else
                -- Stalemate
                self.endCap:SetHidden(true)
                self:HideShowArrows(0)
            end
        end
    elseif not self.lastOwningAlliance then -- Checks lastOwning alliance against both nil and 0
        -- Hide alliance-specific UI elements
        self.ownerBadge:SetHidden(true)
        self.progressBar:SetHidden(true)
        self.endCap:SetHidden(true)
        self:HideShowArrows(0)
    else
        -- In this case, the capture bar is going from nonzero to zero, which means we need to tween it down to zero and then
        -- hide the alliance-specific textures. This is handled in the AnimationTimeline's OnStop event.
    end

    if self.capTimeline.endPct == nil then
        self.capTimeline.endPct = self.capturePercentage
    end

    self.capTimeline.startPct = self.capTimeline.endPct
    self.capTimeline.endPct = self.capturePercentage
    self:UpdateCaptureBar(self.capTimeline.startPct)
    self.capTimeline:PlayFromStart()
end

function ZO_ObjectiveCaptureMeter:VelocityArrowUpdate(captureBarFillPercentage, visibleArrows)
    local arrowAnchorPointPct -- The percentage of the way around the circle that the arrows should anchor to
                               -- Goes from 0.0-1.0, where 0.0 is 12.5% around the circle (starting from the top center)
                               -- and 1.0 is 87.5% of the way around.

    if visibleArrows > 0 then
        -- We're displaying capturing arrows
        if ARROW_ARCLENGTH * zo_abs(visibleArrows) > captureBarFillPercentage * CAPTURE_BAR_ARCLENGTH then
            -- Our arrows are longer than our capture bar, anchor to the end
            arrowAnchorPointPct = ARROW_LENGTH * zo_abs(visibleArrows)
        else
            -- Our capture bar is longer than our arrows, position arrows to follow capture bar
            arrowAnchorPointPct = captureBarFillPercentage
        end
    elseif visibleArrows < 0 then
        -- We're displaying contesting arrows
        if ARROW_ARCLENGTH * zo_abs(visibleArrows) + ENDCAP_ARCLENGTH > (1 - captureBarFillPercentage) * CAPTURE_BAR_ARCLENGTH then
            -- Our arrows are longer than our capture bar, anchor to the end
            arrowAnchorPointPct = 1 - (ARROW_LENGTH * zo_abs(visibleArrows) + ENDCAP_LENGTH)
        else
            -- Our capture bar is longer than our arrows, position arrows to follow capture bar
            arrowAnchorPointPct = captureBarFillPercentage
        end
    else
        -- No arrows to display, but keep updating the position for the next time we unhide them
        arrowAnchorPointPct = captureBarFillPercentage
    end

    local textureRotation = -arrowAnchorPointPct * CAPTURE_BAR_ARCLENGTH
    self.endCap:SetTextureRotation(textureRotation)
    self.capturingArrow1:SetTextureRotation(textureRotation)
    self.capturingArrow2:SetTextureRotation(textureRotation + ARROW_ARCLENGTH)
    self.capturingArrow3:SetTextureRotation(textureRotation + (2 * ARROW_ARCLENGTH))
    self.contestingArrow1:SetTextureRotation(textureRotation)
    self.contestingArrow2:SetTextureRotation(textureRotation - ARROW_ARCLENGTH)
    self.contestingArrow3:SetTextureRotation(textureRotation - (2 * ARROW_ARCLENGTH))
end

function ZO_ObjectiveCaptureMeter:UpdateCaptureBar(progress)
    local captureBarFillPercentage = (progress * (self.capTimeline.endPct - self.capTimeline.startPct)) + self.capTimeline.startPct;
    local arrows = self:GetVisibleArrows()
    self.progressBar:StartFixedCooldown((captureBarFillPercentage * CAPTURE_BAR_LENGTH) + CAPTURE_BAR_BEGIN_OFFSET, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_REMAINING, NO_LEADING_EDGE) -- CD_TIME_TYPE_TIME_REMAINING causes clockwise scroll
    self:VelocityArrowUpdate(captureBarFillPercentage, arrows)
end

function ZO_ObjectiveCaptureMeter:EasingAnimationStopped()
    if self.capturePercentage == 0 then
        -- Hide alliance-specific UI elements
        self.ownerBadge:SetHidden(true)
        self.progressBar:SetHidden(true)
        self.endCap:SetHidden(true)
        self:HideShowArrows(0)
    end
end

function ZO_ObjectiveCaptureMeter:Hide(eventCode)
    self.meter.fadeAnim:FadeOut(0, FADE_DURATION_MS)

    -- Give the fade-out animation time to play before hiding the control
    zo_callLater(function()
        self:SetHiddenForReason("inCaptureArea", true)
    end, FADE_DURATION_MS)
end

function ZO_ObjectiveCaptureMeter:SetHiddenForReason(reason, hidden)
    self.hiddenReasons:SetHiddenForReason(reason, hidden)
    SHARED_INFORMATION_AREA:SetHidden(self.control, self.hiddenReasons:IsHidden())
end

-- Param numArrows: A number between -3 and 3, determining which arrows to show and which to hide
--                  -3 corresponds to 3 contesting arrows, and
--                  +3 corresponds to 3 capturing arrows.
--                  If the number is <-3 or >3, 3 arrows will be shown in the corresponding direction
function ZO_ObjectiveCaptureMeter:HideShowArrows(numArrows)
    -- Hide and show arrows
    self.capturingArrow1:SetHidden(numArrows < 1)
    self.capturingArrow2:SetHidden(numArrows < 2)
    self.capturingArrow3:SetHidden(numArrows < 3)
    self.contestingArrow1:SetHidden(numArrows > -1)
    self.contestingArrow2:SetHidden(numArrows > -2)
    self.contestingArrow3:SetHidden(numArrows > -3)
end

function ZO_ObjectiveCaptureMeter:GetVisibleArrows()
    local numArrows = 0
    if not self.capturingArrow1:IsHidden() then
        numArrows = 1
        if not self.capturingArrow2:IsHidden() then
            numArrows = 2
            if not self.capturingArrow3:IsHidden() then
                numArrows = 3
            end
        end
    elseif not self.contestingArrow1:IsHidden() then
        numArrows = -1
        if not self.contestingArrow2:IsHidden() then
            numArrows = -2
            if not self.contestingArrow3:IsHidden() then
                numArrows = -3
            end
        end
    end
    return numArrows
end

function ZO_ObjectiveCaptureMeter:ApplyPlatformStyle(style)
    ApplyTemplateToControl(self.control, style.meter)
end

--------------
-- Global XML
--------------

function ZO_ObjectiveCapture_Initialize(self)
    OBJECTIVE_CAPTURE_METER = ZO_ObjectiveCaptureMeter:New(self)
end

function ZO_ObjectiveCapture_UpdateCaptureBar(progress)
    OBJECTIVE_CAPTURE_METER:UpdateCaptureBar(progress)
end

function ZO_ObjectiveCapture_EasingAnimationStopped()
    OBJECTIVE_CAPTURE_METER:EasingAnimationStopped()
end