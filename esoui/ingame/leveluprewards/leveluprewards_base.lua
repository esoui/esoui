ZO_LEVEL_UP_REWARDS_BACKGROUND_TEXTURE_WIDTH = 512
ZO_LEVEL_UP_REWARDS_BACKGROUND_TEXTURE_HEIGHT = 256
ZO_LEVEL_UP_REWARDS_BACKGROUND_USED_TEXTURE_WIDTH = 448
ZO_LEVEL_UP_REWARDS_BACKGROUND_USED_TEXTURE_HEIGHT = 138
ZO_LEVEL_UP_REWARDS_ART_RIGHT_TEXTURE_COORD = ZO_LEVEL_UP_REWARDS_BACKGROUND_USED_TEXTURE_WIDTH / ZO_LEVEL_UP_REWARDS_BACKGROUND_TEXTURE_WIDTH
ZO_LEVEL_UP_REWARDS_ART_BOTTOM_TEXTURE_COORD = ZO_LEVEL_UP_REWARDS_BACKGROUND_USED_TEXTURE_HEIGHT / ZO_LEVEL_UP_REWARDS_BACKGROUND_TEXTURE_HEIGHT
ZO_LEVEL_UP_REWARDS_ART_REWARDS_SPACING = 10

function ZO_LevelUpRewardsArtTile_OnInitialized(self)
    self.frameTexture = self:GetNamedChild("Frame")
    self.artTexture = self:GetNamedChild("Art")
    self.titleControl = self:GetNamedChild("Title")

    local maskControl = self:GetNamedChild("Mask")
    self.maskControl = maskControl
    
    local layerAnimation = ZO_TextureLayerRevealAnimation:New(maskControl)
    local animationTimeline = layerAnimation:GetAnimationTimeline()
    animationTimeline:SetPlaybackType(ANIMATION_PLAYBACK_LOOP, LOOP_INDEFINITELY)
    self.layerAnimation = layerAnimation

    local function ParticleSystemFactory(pool)
        local particleSystem = ZO_ControlParticleSystem:New(ZO_BentArcParticle_Control)
        particleSystem:SetParentControl(maskControl)
        particleSystem:SetParticleParameter("AnchorRelativePoint", TOPLEFT)
        return particleSystem
    end
    local function ParticleSystemReset(particleSystem, pool)
        particleSystem:Stop()
    end
    self.particleSystemPool = ZO_ObjectPool:New(ParticleSystemFactory, ParticleSystemReset)

    maskControl:SetHandler("OnEffectivelyShown", function()
        if layerAnimation:HasLayers() then
            animationTimeline:PlayFromStart()
        end
        for _, particleSystem in pairs(self.particleSystemPool:GetActiveObjects()) do
            particleSystem:Start()
        end
    end)
    maskControl:SetHandler("OnEffectivelyHidden", function()
        animationTimeline:Stop()
        for _, particleSystem in pairs(self.particleSystemPool:GetActiveObjects()) do
            particleSystem:Stop()
        end
    end)
end

function ZO_LevelUpRewardsArtTileAndRewards_OnInitialized(self)
    ZO_LevelUpRewardsArtTile_OnInitialized(self)
    self.rewardsContainer = self:GetNamedChild("Rewards")
end

function ZO_LevelUpRewardsArtTile_SetupTileForLevel(self, level)
    local levelBackground = GetLevelUpBackground(level)
    self.artTexture:SetTexture(levelBackground)

    local layerAnimation = self.layerAnimation
    layerAnimation:RemoveAllLayers()
	local numTextureLayerRevealAnimations = GetNumLevelUpTextureLayerRevealAnimations(level)
	for i = 1, numTextureLayerRevealAnimations do
		local animationId = GetLevelUpTextureLayerRevealAnimation(level, i)
		local layer = layerAnimation:AddLayer()
		layer:SetTexture(GetTextureLayerRevealAnimationTexture(animationId))
		layer:SetTextureCoords(0, ZO_LEVEL_UP_REWARDS_ART_RIGHT_TEXTURE_COORD, 0, ZO_LEVEL_UP_REWARDS_ART_BOTTOM_TEXTURE_COORD)
		layer:SetTextureBlendMode(GetTextureLayerRevealAnimationBlendMode(animationId))
		layer:SetWindowNormalizedDimensions(GetTextureLayerRevealAnimationWindowDimensions(animationId))
		layer:SetWindowNormalizedEndPoints(GetTextureLayerRevealAnimationWindowEndPoints(animationId))
		layer:SetWindowMovementDurationMS(GetTextureLayerRevealAnimationWindowMovementDuration(animationId))
		layer:SetWindowMovementOffsetMS(GetTextureLayerRevealAnimationWindowMovementOffset(animationId))
		for gradientIndex = 1, 2 do
			local x, y, normalizedDistance = GetTextureLayerRevealAnimationWindowFadeGradientInfo(animationId, gradientIndex)
			if normalizedDistance > 0 then
				layer:SetWindowFadeGradient(gradientIndex, x, y, normalizedDistance)
			end
		end
	end
    layerAnimation:Commit()

	if layerAnimation:HasLayers() then
        local minDurationMS = GetLevelUpTextureLayerRevealAnimationsMinDuration(level)
        layerAnimation:GetAnimationTimeline():SetMinDuration(minDurationMS)
        if not self.maskControl:IsHidden() then
		    layerAnimation:GetAnimationTimeline():PlayFromStart()
	    end
    end

    self.particleSystemPool:ReleaseAllObjects()
    local numParticleEffects = GetNumLevelUpGuiParticleEffects(level)
    local maskWidth, maskHeight = self.maskControl:GetDimensions()
    for i = 1, numParticleEffects do
        local particleSystem = self.particleSystemPool:AcquireObject()
        local texture, normalizedVelocityMin, normalizedVelocityMax, durationMinS, durationMaxS, particlesPerSecond, startScaleMin, startScaleMax, endScaleMin, endScaleMax, startAlpha,
            endAlpha, r, g, b, normalizedStartPoint1X, normalizedStartPoint1Y, normalizedStartPoint2X, normalizedStartPoint2Y, angleRadians = GetLevelUpGuiParticleEffectInfo(level, i)
        
        local startPoint1X = normalizedStartPoint1X * maskWidth
        local startPoint1Y = normalizedStartPoint1Y * maskHeight
        local startPoint2X = normalizedStartPoint2X * maskWidth
        local startPoint2Y = normalizedStartPoint2Y * maskHeight
        local velocityMin, velocityMax
        local percentageOfUnitCircle = angleRadians / (2 * math.pi)
        if (percentageOfUnitCircle > 1/8 and percentageOfUnitCircle < 3/8) or (percentageOfUnitCircle > 5/8 and percentageOfUnitCircle < 7/8) then
            --Points more in the Y direction than the X, normalize the particle velocity against height
            velocityMin = normalizedVelocityMin * maskHeight
            velocityMax = normalizedVelocityMax * maskHeight
        else
            --Points more in the X direction than the Y, normalize the particle velocity against width
            velocityMin = normalizedVelocityMin * maskWidth
            velocityMax = normalizedVelocityMax * maskWidth
        end 

        particleSystem:SetParticlesPerSecond(particlesPerSecond)
        particleSystem:SetParticleParameter("Texture", texture)
        particleSystem:SetParticleParameter("BentArcElevationStartRadians", angleRadians)
        particleSystem:SetParticleParameter("BentArcElevationChangeRadians", 0)
        particleSystem:SetParticleParameter("BentArcAzimuthStartRadians", 0)
        particleSystem:SetParticleParameter("BentArcAzimuthChangeRadians", 0)
        particleSystem:SetParticleParameter("BentArcVelocity", ZO_UniformRangeGenerator:New(velocityMin, velocityMax))
        particleSystem:SetParticleParameter("Size", 8)
        particleSystem:SetParticleParameter("StartScale", ZO_UniformRangeGenerator:New(startScaleMin, startScaleMax))
        particleSystem:SetParticleParameter("EndScale", ZO_UniformRangeGenerator:New(endScaleMin, endScaleMax))
        particleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(durationMinS, durationMaxS))
        particleSystem:SetParticleParameter("StartAlpha", startAlpha)
        particleSystem:SetParticleParameter("EndAlpha", endAlpha)
        particleSystem:SetParticleParameter("StartColorR", r)
        particleSystem:SetParticleParameter("StartColorG", g)
        particleSystem:SetParticleParameter("StartColorB", b)
        particleSystem:SetParticleParameter("StartOffsetX", "StartOffsetY", ZO_UniformRangeGenerator:New(startPoint1X, startPoint2X, startPoint1Y, startPoint2Y))
        particleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)

        if not self.maskControl:IsHidden() then
            particleSystem:Start()
        end
    end
end