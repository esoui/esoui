local zo_clamp = zo_clamp
local zo_lerp = zo_lerp

--Particle

ZO_Particle = ZO_Object:Subclass()

function ZO_Particle:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_Particle:Initialize()
    self.parameters = {}
end

function ZO_Particle:GetKey()
    return self.key
end

function ZO_Particle:SetKey(key)
    self.key = key
end

function ZO_Particle:GetTextureControl()
    return self.textureControl
end

function ZO_Particle:GetParameter(name)
    return self.parameters[name]
end

function ZO_Particle:SetParameter(name, value)
    self.parameters[name] = value
end

function ZO_Particle:ResetParameters()
    ZO_ClearTable(self.parameters)
end

--startTimeS can be in the past
function ZO_Particle:Start(parentControl, startTimeS, nowS)
    local parameters = self.parameters
    self.textureControl = PARTICLE_SYSTEM_MANAGER:AcquireTexture()

    self.textureControl:SetParent(parentControl)
    self.startTimeS = startTimeS
    local durationS = parameters["DurationS"]
    if durationS then
        self.endTimeS = self.startTimeS + durationS
    end
    self.textureControl:SetTexture(parameters["Texture"])
    local blendMode = parameters["BlendMode"]
    self.textureControl:SetBlendMode(blendMode or TEX_BLEND_MODE_ALPHA)

    --AnimationTimeline based animations

    self:AddAnimationsOnStart(durationS)

    self.animationTimelines = PARTICLE_SYSTEM_MANAGER:FinishBuildingAnimationTimelines()
    if self.animationTimelines then
        local elapsedTimeS = self:GetElapsedTime(nowS)
        for _, animationTimeline in ipairs(self.animationTimelines) do
            animationTimeline:PlayFromStart(elapsedTimeS * 1000)
        end
    end

    --Update Loop based animations

    self.hasOffsetXInterpolation, self.offsetX = self:InitializeEasedLerpParameter("StartOffsetX", "EndOffsetX", 0)
    self.hasOffsetYInterpolation, self.offsetY = self:InitializeEasedLerpParameter("StartOffsetY", "EndOffsetY", 0)
    self.hasOffsetZInterpolation, self.offsetZ = self:InitializeEasedLerpParameter("StartOffsetZ", "EndOffsetZ", 0)
end

function ZO_Particle:AddAnimationsOnStart(durationS)
    local parameters = self.parameters

    local DEFAULT_PLAYBACK_INFO = nil
    local DEFAULT_DURATION_S = durationS
    local DEFAULT_OFFSET_S = 0

    --Alpha
    local alpha
    local hasAlphaInterpolation, alpha = self:InitializeEasedLerpParameter("StartAlpha", "EndAlpha", 1)
    if hasAlphaInterpolation then
        local alphaAnimation = PARTICLE_SYSTEM_MANAGER:GetAnimation(self.textureControl, DEFAULT_PLAYBACK_INFO, ANIMATION_ALPHA, parameters["AlphaEasing"], DEFAULT_DURATION_S, DEFAULT_OFFSET_S)
        alphaAnimation:SetAlphaValues(parameters["StartAlpha"], parameters["EndAlpha"])
    end
    self.textureControl:SetAlpha(alpha)

    --Color
    local hasColorRInterpolation, colorR = self:InitializeEasedLerpParameter("StartColorR", "EndColorR", 1)
    local hasColorGInterpolation, colorG = self:InitializeEasedLerpParameter("StartColorG", "EndColorG", 1)
    local hasColorBInterpolation, colorB = self:InitializeEasedLerpParameter("StartColorB", "EndColorB", 1)
    if hasColorRInterpolation or hasColorGInterpolation or hasColorBInterpolation then
        local colorAnimation = PARTICLE_SYSTEM_MANAGER:GetAnimation(self.textureControl, DEFAULT_PLAYBACK_INFO, ANIMATION_COLOR, parameters["ColorEasing"], DEFAULT_DURATION_S, DEFAULT_OFFSET_S)
        colorAnimation:SetColorValues(parameters["StartColorR"], parameters["StartColorG"], parameters["StartColorB"], 1, parameters["EndColorR"], parameters["StartColorG"], parameters["StartColorB"], 1)
        colorAnimation:SetApplyAlpha(false)
    end
    self.textureControl:SetColor(colorR, colorG, colorB, alpha)

    --Flip Book
    local flipBookCellsWide = parameters["FlipBookCellsWide"]
    if flipBookCellsWide then
        local flipBookCellsHigh = parameters["FlipBookCellsHigh"]
        local NO_EASING_FUNCTION = nil
        local textureAnimation = PARTICLE_SYSTEM_MANAGER:GetAnimation(self.textureControl, parameters["FlipBookPlaybackInfo"], ANIMATION_TEXTURE, NO_EASING_FUNCTION, parameters["FlipBookDurationS"] or DEFAULT_DURATION_S, DEFAULT_OFFSET_S)
        textureAnimation:SetImageData(flipBookCellsWide, flipBookCellsHigh)
    else
        self.textureControl:SetTextureCoords(0, 1, 0, 1)
    end

    --Rotation
    local startRotationRadians = parameters["StartRotationRadians"]
    if startRotationRadians then
        local endRotationRadians = parameters["EndRotationRadians"]
        if not endRotationRadians then
            local rotationSpeedRadians = parameters["RotationSpeedRadians"]
            if rotationSpeedRadians then
                local totalTimeAnimatingS = DEFAULT_DURATION_S
                endRotationRadians = startRotationRadians + totalTimeAnimatingS * rotationSpeedRadians
            end
        end
        if endRotationRadians then
            local NO_EASING_FUNCTION = nil
            local textureRotationAnimation = PARTICLE_SYSTEM_MANAGER:GetAnimation(self.textureControl, DEFAULT_PLAYBACK_INFO, ANIMATION_TEXTUREROTATE, NO_EASING_FUNCTION, DEFAULT_DURATION_S, DEFAULT_OFFSET_S)
            textureRotationAnimation:SetRotationValues(startRotationRadians, endRotationRadians)
        end
    else
        startRotationRadians = 0
    end
    self.textureControl:SetTextureRotation(startRotationRadians)
end

function ZO_Particle:Stop()
    if self.textureControl then
        PARTICLE_SYSTEM_MANAGER:ReleaseTexture(self.textureControl)
        self.textureControl = nil
    end
    if self.animationTimelines then
        PARTICLE_SYSTEM_MANAGER:ReleaseAnimationTimelines(self.animationTimelines)
        self.animationTimelines = nil
    end
end

function ZO_Particle:GetProgress(timeS)
    return zo_clamp((timeS - self.startTimeS) / (self.endTimeS - self.startTimeS), 0, 1)
end

function ZO_Particle:GetElapsedTime(timeS)
    return zo_clamp(timeS - self.startTimeS, 0, self.endTimeS - self.startTimeS)
end

function ZO_Particle:IsDone(timeS)
    return timeS > self.endTimeS
end

function ZO_Particle:InitializeEasedLerpParameter(startName, endName, defaultValue)
    local parameters = self.parameters
    local hasInterpolation = false
    local initialValue = defaultValue
    if parameters[startName] ~= nil then
        initialValue = parameters[startName]
        if parameters[endName] ~= nil then
            hasInterpolation = true
        end
    end
    return hasInterpolation, initialValue
end

function ZO_Particle:ComputedEasedLerpParameter(startName, endName, easingName, defaultValue, progress)
    local parameters = self.parameters
    local startValue = parameters[startName]
    local endValue = parameters[endName]
    local value = defaultValue
    if startValue and endValue then
        local easingFunction = parameters[easingName]
        if easingFunction then
            progress = easingFunction(progress)
        end
        value = zo_lerp(startValue, endValue, progress)
    end
    return value
end

function ZO_Particle:OnUpdate(timeS)
    local progress = self:GetProgress(timeS)
    local parameters = self.parameters
    
    if self.hasOffsetXInterpolation then
        self.offsetX = self:ComputedEasedLerpParameter("StartOffsetX", "EndOffsetX", "OffsetXEasing", 0, progress)
    end
    if self.hasOffsetYInterpolation then
        self.offsetY = self:ComputedEasedLerpParameter("StartOffsetY", "EndOffsetY", "OffsetYEasing", 0, progress)
    end
    if self.hasOffsetZInterpolation then
        self.offsetZ = self:ComputedEasedLerpParameter("StartOffsetZ", "EndOffsetZ", "OffsetZEasing", 0, progress)
    end
end

function ZO_Particle:GetDimensionsFromParameters()
    local parameters = self.parameters
    local size = parameters["Size"]
    local width = parameters["Width"] or size
    local height = parameters["Height"] or size
    return width, height
end

--Scene Graph Particle

ZO_SceneGraphParticle = ZO_Particle:Subclass()

function ZO_SceneGraphParticle:New(...)
    return ZO_Particle.New(self, ...)
end

function ZO_SceneGraphParticle:Initialize()
    ZO_Particle.Initialize(self)
end

function ZO_SceneGraphParticle:SetParentNode(parentNode)
    self.parentNode = parentNode
end

--startTimeS can be in the past
function ZO_SceneGraphParticle:Start(parentControl, startTimeS, nowS)
    ZO_Particle.Start(self, parentControl, startTimeS, nowS)
    self.parentNode:AddTexture(self.textureControl, 0, 0, 0)

    --Scene graph nodes make use of the control scale for their own purposes so these have to calculate it into the size
    self.widthFromParamters, self.heightFromParameters = self:GetDimensionsFromParameters()
    local scale
    self.hasScaleInterpolation, scale = self:InitializeEasedLerpParameter("StartScale", "EndScale", 1)
    self.textureControl:SetDimensions(self.widthFromParamters * scale, self.heightFromParameters * scale)
end

function ZO_SceneGraphParticle:OnUpdate(timeS)
    ZO_Particle.OnUpdate(self, timeS)
    
    --Scene graph nodes make use of the control scale for their own purposes so these have to calculate it into the size
    if self.hasScaleInterpolation then        
        local progress = self:GetProgress(timeS)
        local scale = self:ComputedEasedLerpParameter("StartScale", "EndScale", "ScaleEasing", 1, progress)
        self.textureControl:SetDimensions(self.widthFromParamters * scale, self.heightFromParameters * scale)
    end
end

function ZO_SceneGraphParticle:Stop()
    if self.textureControl then
        self.parentNode:RemoveTexture(self.textureControl)
    end
    ZO_Particle.Stop(self)
end

--Expects that x is right and y is up
function ZO_SceneGraphParticle:SetPosition(x, y, z)
    if z == nil then
        z = 0
    end
    self.parentNode:SetControlPosition(self.textureControl, x + self.offsetX, -(y + self.offsetY), z + self.offsetZ)
end

--Control Particle

ZO_ControlParticle = ZO_Particle:Subclass()

function ZO_ControlParticle:New(...)
    return ZO_Particle.New(self, ...)
end

--startTimeS can be in the past
function ZO_ControlParticle:Start(parentControl, startTimeS, nowS)
    ZO_Particle.Start(self, parentControl, startTimeS, nowS)
    local parameters = self.parameters
    self.anchorPoint = parameters["AnchorPoint"] or CENTER
    self.anchorRelativePoint = parameters["AnchorRelativePoint"] or CENTER
    local drawLevel = parameters["DrawLevel"] or 0
    self.textureControl:SetDrawLevel(drawLevel)
    local drawLayer = parameters["DrawLayer"] or DL_BACKGROUND
    self.textureControl:SetDrawLayer(drawLayer)
    local width, height = self:GetDimensionsFromParameters()
    self.textureControl:SetDimensions(width, height)
end

function ZO_ControlParticle:AddAnimationsOnStart(durationS)
    ZO_Particle.AddAnimationsOnStart(self, durationS)

    local parameters = self.parameters
    local hasScaleInterpolation, scale = self:InitializeEasedLerpParameter("StartScale", "EndScale", 1)
    self.textureControl:SetScale(scale)
    if hasScaleInterpolation then
        local DEFAULT_PLAYBACK_INFO = nil
        local DEFAULT_DURATION_S = durationS
        local DEFAULT_OFFSET_S = 0

        local scaleAnimation = PARTICLE_SYSTEM_MANAGER:GetAnimation(self.textureControl, DEFAULT_PLAYBACK_INFO, ANIMATION_SCALE, parameters["ScaleEasing"], DEFAULT_DURATION_S, DEFAULT_OFFSET_S)
        scaleAnimation:SetScaleValues(parameters["StartScale"], parameters["EndScale"])
    end
end

--Expects that x is right and y is down
function ZO_ControlParticle:SetPosition(x, y, z)
    self.textureControl:SetAnchor(self.anchorPoint, nil, self.anchorRelativePoint, x + self.offsetX, y + self.offsetY)
end
