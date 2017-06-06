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

function ZO_Particle:SetParameter(name, value)
    self.parameters[name] = value
end

function ZO_Particle:Start(parentControl)
    local parameters = self.parameters
    self.textureControl = PARTICLE_SYSTEM_MANAGER:AcquireTexture()

    self.textureControl:SetParent(parentControl)
    self.startTimeS = GetGameTimeMilliseconds() / 1000
    local durationS = parameters["DurationS"]
    if durationS then
        self.endTimeS = self.startTimeS + durationS
    end
    self.textureControl:SetTexture(parameters["Texture"])
    local blendMode = parameters["BlendMode"]
    self.textureControl:SetBlendMode(blendMode or TEX_BLEND_MODE_ALPHA)

    local size = parameters["Size"]
    self.hasScaleInterpolation, self.scale = self:InitializeEasedLerpParameter("StartScale", "EndScale", 1)
    self.textureControl:SetDimensions(size * self.scale, size * self.scale)

    self.hasOffsetXInterpolation, self.offsetX = self:InitializeEasedLerpParameter("StartOffsetX", "EndOffsetX", 0)
    self.hasOffsetYInterpolation, self.offsetY = self:InitializeEasedLerpParameter("StartOffsetY", "EndOffsetY", 0)
    self.hasOffsetZInterpolation, self.offsetZ = self:InitializeEasedLerpParameter("StartOffsetZ", "EndOffsetZ", 0)

    local alpha
    self.hasAlphaInterpolation, alpha = self:InitializeEasedLerpParameter("StartAlpha", "EndAlpha", 1)
    self.hasColorRInterpolation, self.colorR = self:InitializeEasedLerpParameter("StartColorR", "EndColorR", 1)
    self.hasColorGInterpolation, self.colorG = self:InitializeEasedLerpParameter("StartColorG", "EndColorG", 1)
    self.hasColorBInterpolation, self.colorB = self:InitializeEasedLerpParameter("StartColorB", "EndColorB", 1)
    self.textureControl:SetColor(self.colorR, self.colorG, self.colorB, alpha)
end

function ZO_Particle:Stop()
    PARTICLE_SYSTEM_MANAGER:ReleaseTexture(self.textureControl)
    self.textureControl = nil
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

local lerp = zo_lerp
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
        value = lerp(startValue, endValue, progress)
    end
    return value
end

function ZO_Particle:OnUpdate(timeS)
    local progress = self:GetProgress(timeS)
    
    if self.hasScaleInterpolation then
        local parameters = self.parameters
        local size = parameters["Size"]
        local scale = self:ComputedEasedLerpParameter("StartScale", "EndScale", "ScaleEasing", 1, progress)
        self.textureControl:SetDimensions(size * scale, size * scale)
    end

    if self.hasOffsetXInterpolation then
        self.offsetX = self:ComputedEasedLerpParameter("StartOffsetX", "EndOffsetX", "OffsetXEasing", 0, progress)
    end
    if self.hasOffsetYInterpolation then
        self.offsetY = self:ComputedEasedLerpParameter("StartOffsetY", "EndOffsetY", "OffsetYEasing", 0, progress)
    end
    if self.hasOffsetZInterpolation then
        self.offsetZ = self:ComputedEasedLerpParameter("StartOffsetZ", "EndOffsetZ", "OffsetZEasing", 0, progress)
    end

    local r, g, b, a = self.textureControl:GetColor()
    if self.hasColorRInterpolation then
        r = self:ComputedEasedLerpParameter("StartColorR", "EndColorR", "ColorREasing", 1, progress)
    end
    if self.hasColorGInterpolation then
        g = self:ComputedEasedLerpParameter("StartColorG", "EndColorG", "ColorGEasing", 1, progress)
    end
    if self.hasColorBInterpolation then
        b = self:ComputedEasedLerpParameter("StartColorB", "EndColorB", "ColorBEasing", 1, progress)
    end
    if self.hasAlphaInterpolation then
        a = self:ComputedEasedLerpParameter("StartAlpha", "EndAlpha", "AlphaEasing", 1, progress)
    end
    self.textureControl:SetColor(r, g, b, a)
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

function ZO_SceneGraphParticle:Start(parentControl)
    ZO_Particle.Start(self, parentControl)
    self.parentNode:AddControl(self.textureControl, 0, 0, 0)
end

function ZO_SceneGraphParticle:Stop()
    self.parentNode:RemoveControl(self.textureControl)
    ZO_Particle.Stop(self)
end

function ZO_SceneGraphParticle:SetPosition(x, y, z)
    if z == nil then
        z = 0
    end
    self.parentNode:SetControlPosition(self.textureControl, x + self.offsetX, -(y + self.offsetY), z + self.offsetZ)
end