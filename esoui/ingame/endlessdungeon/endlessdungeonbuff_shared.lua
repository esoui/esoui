ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ANIMATION_INTERVAL_OFFSET_S = 1.3
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ANIMATION_INTERVAL_OFFSET_MAX_S = 12.1

ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_ALPHA_FACTOR = 1.1
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_ALPHA_MAX = 0.25
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_ALPHA_MAX_FOCUS = 0.25
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_ANIMATION_INTERVAL_S = 2
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_ANIMATION_INTERVAL_OFFSET_S = 0.75
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_COUNT = 2
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_SPEED_FACTOR = 1
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_SCALE_MAX = 1.5
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_SCALE_MIN = 1
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_UV_OFFSET_MAX = 0.1

ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PULSE_BRIGHTNESS_FACTOR = 1.35
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PULSE_BRIGHTNESS_MAX = 1
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PULSE_BRIGHTNESS_MIN = 0.75
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PULSE_INTERVAL_S = 2.5

ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_ALPHA_MAX = 0.7
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_ALPHA_MIN = 0.4
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_BLUR_OFFSET = 0
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_BLUR_ORIGIN_X = 0.5
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_BLUR_ORIGIN_Y = 1.2
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_BLUR_SAMPLES = 11
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_BLUR_STRENGTH = 0.25
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_CROSSFADE_INTERVAL_S = 0.06
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_SPEED_FACTOR = 1.5

local g_endlessDungeonAvatarVisionParticlePool = nil -- Initialized by ZO_EndlessDungeonAvatarVisionParticle_Shared.InitializeTopLevelWindow

ZO_EndlessDungeonAvatarVisionParticle_Shared = ZO_Object:Subclass()

function ZO_EndlessDungeonAvatarVisionParticle_Shared.Initialize(control)
    zo_mixin(control, ZO_EndlessDungeonAvatarVisionParticle_Shared)

    control.previousInterval = math.huge
end

function ZO_EndlessDungeonAvatarVisionParticle_Shared.InitializeTopLevelWindow(control)
    g_endlessDungeonAvatarVisionParticlePool = ZO_ControlPool:New("ZO_EndDunAvatarVisionParticle_Shared", control, "EndDunAvatarVisionParticle")
end

-- Animates an Avatar Vision particle instance.
function ZO_EndlessDungeonAvatarVisionParticle_Shared:Update()
    -- Adds variety when multiple Avatar Visions are visible at once.
    local instanceOffset = self.instanceIntervalOffsetS
    self:SetWaveOffset(instanceOffset * 0.5)

    -- Offsets the texture UV coordinates each time this instance fades in.
    local progress = (GetFrameTimeSeconds() + instanceOffset) * ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_SPEED_FACTOR
    local interval = (progress % ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_ANIMATION_INTERVAL_S) / ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_ANIMATION_INTERVAL_S
    if interval < self.previousInterval then
        local randomAngleRadians = zo_random() * ZO_TWO_PI
        local randomOffsetX = zo_sin(randomAngleRadians) * ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_UV_OFFSET_MAX
        local left, right = 0, 1
        if randomOffsetX < 0 then
            left = left + randomOffsetX
        else
            right = right + randomOffsetX
        end
        local randomOffsetY = zo_cos(randomAngleRadians) * ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_UV_OFFSET_MAX
        local top, bottom = 0, 1
        if randomOffsetY < 0 then
            top = top + randomOffsetY
        else
            bottom = bottom + randomOffsetY
        end
        self:SetTextureCoords(left, right, top, bottom)
    end
    self.previousInterval = interval

    -- Expands the instance as it fades out.
    local scale = zo_lerp(ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_SCALE_MIN, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_SCALE_MAX, interval)
    self:SetScale(scale)

    -- Fades the instance in and out.
    local parentControl = self:GetParent()
    local alphaFactor = parentControl.highlightTexture:IsHidden() and ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_ALPHA_MAX or ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_ALPHA_MAX_FOCUS
    local alpha = zo_min(zo_sin(interval * ZO_PI) * ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_ALPHA_FACTOR, 1) * alphaFactor
    self:SetAlpha(alpha)
end

ZO_EndlessDungeonBuff_Shared = ZO_Object:Subclass()

function ZO_EndlessDungeonBuff_Shared.Initialize(control)
    zo_mixin(control, ZO_EndlessDungeonBuff_Shared)

    control.highlightTexture = control:GetNamedChild("Highlight")
    control.highlightTexture.alphaFactor = 0
    control.iconTexture = control:GetNamedChild("Icon")
    control.stackCountLabel = control:GetNamedChild("StackCount")

    control:ResetHighlight()
end

function ZO_EndlessDungeonBuff_Shared:IsHighlighted()
    return not self.highlightTexture:IsHidden()
end

function ZO_EndlessDungeonBuff_Shared:Layout(data)
    -- Setup buff instance.
    self.abilityId = data.abilityId
    self.buffType = data.buffType
    self.isAvatarVision = data.isAvatarVision
    self.highlightTexture:SetTexture(data.iconTexture)
    self.iconTexture:SetTexture(data.iconTexture)
    self.instanceIntervalOffsetS = data.instanceIntervalOffset

    local stackCountString = (data.stackCount and data.stackCount > 1) and tostring(data.stackCount) or ""
    self.stackCountLabel:SetText(stackCountString)

    local avatarUpdateHandler = data.isAvatarVision and self.UpdateAvatar or nil
    self:SetHandler("OnUpdate", avatarUpdateHandler, "Avatar")

    if data.isAvatarVision then
        -- Defer creation of particle metapool for this instance until it is now necessary.
        if not self.avatarVisionParticlePool then
            self.avatarVisionParticlePool = ZO_MetaPool:New(g_endlessDungeonAvatarVisionParticlePool)
        end
        local avatarVisionParticlePool = self.avatarVisionParticlePool

        -- Setup particle instances.
        local waveOffset = 0
        for particleIndex = 1, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_COUNT do
            local particleTexture = avatarVisionParticlePool:AcquireObject()
            particleTexture.previousInterval = math.huge
            particleTexture.instanceIntervalOffsetS = (particleIndex - 1) * ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PARTICLE_ANIMATION_INTERVAL_OFFSET_S
            particleTexture:SetAnchor(CENTER, self.iconTexture)
            particleTexture:SetDimensions(self.iconTexture:GetDimensions())
            particleTexture:SetDrawLevel(1 + particleIndex)
            particleTexture:SetParent(self)
            particleTexture:SetTexture(data.iconTexture)
            particleTexture:SetHidden(false)
        end
    end
end

function ZO_EndlessDungeonBuff_Shared:Reset()
    self.abilityId = nil
    self.iconTexture:SetScale(1)
    self:ResetHighlight()
    if self.avatarVisionParticlePool then
        self.avatarVisionParticlePool:ReleaseAllObjects()
    end
end

function ZO_EndlessDungeonBuff_Shared:ResetHighlight()
    local highlightTexture = self.highlightTexture
    highlightTexture:SetHidden(true)
    highlightTexture.alphaFactor = 0
    highlightTexture.transitionFadeInEndTimeS = nil
    highlightTexture.transitionFadeOutEndTimeS = nil
end

function ZO_EndlessDungeonBuff_Shared:SetHighlightHidden(hidden)
    local currentFrameTimeS = GetFrameTimeSeconds()
    local highlightTexture = self.highlightTexture
    local alphaFactor = highlightTexture.alphaFactor or 0
    highlightTexture.transitionAlphaFactor = alphaFactor
    if hidden then
        highlightTexture.transitionFadeOutEndTimeS = currentFrameTimeS + (ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_CROSSFADE_INTERVAL_S * alphaFactor)
        highlightTexture.transitionFadeInEndTimeS = nil
    else
        highlightTexture.transitionFadeOutEndTimeS = nil
        highlightTexture.transitionFadeInEndTimeS = currentFrameTimeS + (ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_CROSSFADE_INTERVAL_S * (1 - alphaFactor))
        highlightTexture:SetHidden(false)
    end
end

function ZO_EndlessDungeonBuff_Shared:UpdateAvatarVision()
    local interval = ((GetFrameTimeSeconds() + self.instanceIntervalOffsetS) % ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PULSE_INTERVAL_S) / ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PULSE_INTERVAL_S
    local progress = zo_min(zo_sin(interval * ZO_PI) * ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PULSE_BRIGHTNESS_FACTOR, 1)
    local brightness = zo_lerp(ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PULSE_BRIGHTNESS_MIN, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_AVATAR_VISION_PULSE_BRIGHTNESS_MAX, progress)
    self.iconTexture:SetColor(brightness, brightness, brightness, 1)
end

do
    local VERTEX_POINTS_BOTTOM = VERTEX_POINTS_BOTTOMLEFT + VERTEX_POINTS_BOTTOMRIGHT
    local VERTEX_POINTS_ALL = VERTEX_POINTS_BOTTOM + VERTEX_POINTS_TOPLEFT + VERTEX_POINTS_TOPRIGHT

    function ZO_EndlessDungeonBuff_Shared:UpdateHighlight()
        local highlightTexture = self.highlightTexture
        local alphaFactor = highlightTexture.alphaFactor
        if highlightTexture.transitionFadeOutEndTimeS then
            alphaFactor = zo_lerp(highlightTexture.transitionAlphaFactor, 0, 1 - zo_min((highlightTexture.transitionFadeOutEndTimeS - GetFrameTimeSeconds()) / ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_CROSSFADE_INTERVAL_S, 1))
            if alphaFactor <= 0 then
                highlightTexture:SetVertexColors(VERTEX_POINTS_ALL, 0, 0, 0, 0)
                highlightTexture:SetHidden(true)
                highlightTexture.alphaFactor = 0
                highlightTexture.transitionFadeOutEndTimeS = nil
                return
            end
            highlightTexture.alphaFactor = alphaFactor
        elseif highlightTexture.transitionFadeInEndTimeS then
            alphaFactor = zo_lerp(highlightTexture.transitionAlphaFactor, 1, 1 - zo_min((highlightTexture.transitionFadeInEndTimeS - GetFrameTimeSeconds()) / ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_CROSSFADE_INTERVAL_S, 1))
            if alphaFactor >= 1 then
                alphaFactor = 1
                highlightTexture.transitionFadeInEndTimeS = nil
            end
            highlightTexture.alphaFactor = alphaFactor
        end

        -- Animation interval offset for this particular buff instance (for visual variety).
        local instanceIntervalOffsetS = self.instanceIntervalOffsetS
        local progress = (GetFrameTimeSeconds() + instanceIntervalOffsetS) * ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_SPEED_FACTOR
        highlightTexture:SetRadialBlur(ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_BLUR_ORIGIN_X, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_BLUR_ORIGIN_Y, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_BLUR_SAMPLES, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_BLUR_STRENGTH, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_BLUR_OFFSET)

        highlightTexture:SetVertexColors(VERTEX_POINTS_BOTTOM, 0, 0, 0, 0)
        do
            local alphaCoefficient = zo_sin(progress) * 0.5 + 0.5
            local alpha = zo_lerp(ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_ALPHA_MIN, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_ALPHA_MAX, alphaCoefficient)
            local intensityAndAlpha = alpha * alphaFactor
            highlightTexture:SetVertexColors(VERTEX_POINTS_TOPLEFT, intensityAndAlpha, intensityAndAlpha, intensityAndAlpha, intensityAndAlpha)
        end
        do
            local alphaCoefficient = zo_sin(progress * 1.7) * 0.5 + 0.5
            local alpha = zo_lerp(ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_ALPHA_MAX, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_HIGHLIGHT_ALPHA_MIN, alphaCoefficient)
            local intensityAndAlpha = alpha * alphaFactor
            highlightTexture:SetVertexColors(VERTEX_POINTS_TOPRIGHT, intensityAndAlpha, intensityAndAlpha, intensityAndAlpha, intensityAndAlpha)
        end
    end
end