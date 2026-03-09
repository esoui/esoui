-- A single Flag flag for Battlegrounds Round Recap
ZO_BATTLEGROUND_FLAG_WIDTH  = 320 -- 1.25 * 256
ZO_BATTLEGROUND_FLAG_HEIGHT = 576 -- 1.125 * 512
ZO_BATTLEGROUND_BAR_HEIGHT = 64

ZO_BattlegroundsRoundRecapFlag = ZO_InitializingObject:Subclass()

function ZO_BattlegroundsRoundRecapFlag:Initialize(control)
    self.control = control
    control.owner = self

    self.title = self.control:GetNamedChild("ClipRegionTitle")
    self.flag = self.control:GetNamedChild("ClipRegionFlag")

    self.score = control:GetNamedChild("ClipRegionScore")
    self.score:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    self.score:SetResizeToFitLabels(false)
    self.score.owner = self
    self.scoreTransitionManager = self.score:GetOrCreateTransitionManager()
    self.scoreTransitionManager:SetMaxTransitionSteps(50)
    self.scoreTransitionManager:SetValueImmediately(0)
    self:ApplyScorePlatformStyle()

    self.revealTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("BattlegroundsFlagReveal", control)
    self.scoreFlipTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("BattlegroundsFlagFlipScore", control)
    
    self.roundsWonByTeam = 0

end

function ZO_BattlegroundsRoundRecapFlag:ApplyPlatformStyle()
    ZO_ApplyPlatformTemplateToControl(self.control, "ZO_BattlegroundRoundRecapFlag")
    self:ApplyScorePlatformStyle()
end

function ZO_BattlegroundsRoundRecapFlag:ApplyScorePlatformStyle()
    local useGamepadStyle = IsInGamepadPreferredMode()
    if useGamepadStyle then
        self.score:SetFont("ZoFontGamepadBold54")
    else
        self.score:SetFont("ZoFontCallout3")
    end
end

function ZO_BattlegroundsRoundRecapFlag:SetDetails(battlegroundTeam, flagImage, score, delay, isWinner, roundsWonByTeam)
    self.delay = delay
    self.audioPlayed = false
    self.isWinner = isWinner
    self.roundsWonByTeam = roundsWonByTeam

    self.flag:SetShaderEffectType(SHADER_EFFECT_TYPE_WAVE)
    self.flag:SetWave(0.1, 1, 10.77, 0.5)
    self.flag:SetWaveBounds(0.125, 0.125, 0, 0)
    self.flag:SetWaveDampingCoefficients(0, 0, 1.25, 0) --Left damping, right damping, top damping (zeroed for 25%), bottom damping.
    self.flag:SetTexture(flagImage)
  
    local LIGHT_GRAY = ZO_ColorDef:New("CCCCCC")
    self.score:SetColor(LIGHT_GRAY:UnpackRGBA())

    self.title:SetText(zo_strformat(SI_BATTLEGROUND_RESULT_TEAM_NAME_FORMAT, GetBattlegroundTeamName(battlegroundTeam)))
    self.scoreTransitionManager:SetValueImmediately(score)
    self.title:SetColor(ZO_WHITE:UnpackRGBA())

end

function ZO_BattlegroundsRoundRecapFlag:Start()
    if self.control:IsControlHidden() then
        return
    end
    self.revealTimeline:PlayFromStart(self.delay)
end

function ZO_BattlegroundsRoundRecapFlag:Stop()
    self.revealTimeline:Stop()
    self.scoreFlipTimeline:Stop()
end

function ZO_BattlegroundsRoundRecapFlag:OnAnimationUpdate(animation, progressPercent)
    if self.audioPlayed ~= true then
        self.audioPlayed = true
        PlaySound(SOUNDS.BATTLEGROUND_ROUND_RECAP_FLAG_START)
    end

    local modifiedProgress = ZO_BounceEase(zo_clamp(progressPercent, 0, 1))
    local magnitude = zo_lerp(0.5, 0.03, modifiedProgress)
    self.flag:SetWaveBounds(magnitude, magnitude, 0, magnitude * 0.5)
end

function ZO_BattlegroundsRoundRecapFlag:FlipScore()
    self.scoreFlipTimeline:PlayFromStart()
end

function ZO_BattlegroundsRoundRecapFlag:OnAnimationFlipScoreFadedOut()
    if self.control:IsControlHidden() then
        return
    end
    self.score:SetColor(ZO_WHITE:UnpackRGBA())
    if self.isWinner then
        -- The winner will be transitioned later to the correct value.
        self.scoreTransitionManager:SetValueImmediately(zo_max(0, self.roundsWonByTeam - 1))
    else
        self.scoreTransitionManager:SetValueImmediately(self.roundsWonByTeam)
    end
end

function ZO_BattlegroundsRoundRecapFlag:OnAnimationFlipScoreFadedIn()
    if self.control:IsControlHidden() then
        return
    end
    if self.isWinner then
        PlaySound(SOUNDS.BATTLEGROUND_ROUND_RECAP_FLAG_SCORE_COUNT)
        self.scoreTransitionManager:SetValue(self.roundsWonByTeam)
    end
end

--[[ xml functions ]]--

function ZO_BattlegroundsRoundRecapFlag.OnUpdate(animation, progressPercent)
    local owner = animation:GetAnimatedControl().owner
    owner:OnAnimationUpdate(animation, progressPercent)
end

function ZO_BattlegroundsRoundRecapFlag.OnFlipScoreFadedOut(animation, progressPercent, isComplete)
    if isComplete then
        local owner = animation:GetAnimatedControl().owner
        owner:OnAnimationFlipScoreFadedOut(animation, progressPercent)
    end
end

function ZO_BattlegroundsRoundRecapFlag.OnFlipScoreFadedIn(animation, progressPercent, isComplete)
    if isComplete then
        local owner = animation:GetAnimatedControl().owner
        owner:OnAnimationFlipScoreFadedIn(animation, progressPercent)
    end
end