--[[
    -- Apply a flicker effect to the specified Texture control that simulates the
    -- "random" dimming and brightening that is characteristic of a wax candle.

    local SPEED_MULTIPLIER = 1.0    -- Flicker speed multiplier (ex: 0.5x, 1.0x or 2.0x speed)
    local ALPHA_STRENGTH = 0.5      -- Maximum percentage reduction of the texture alpha (fading)
    local COLOR_STRENGTH = 0.25     -- Maximum percentage reduction of the texture color (dimming)
    FLICKER_EFFECT:RegisterControl(myTextureControl, SPEED_MULTIPLIER, ALPHA_STRENGTH, COLOR_STRENGTH)
]]

local VALID_CONTROL_TYPES =
{
    [CT_TEXTURE] = true
}

local VERTICES =
{
    VERTEX_POINTS_TOPLEFT,
    VERTEX_POINTS_TOPRIGHT,
    VERTEX_POINTS_BOTTOMLEFT,
    VERTEX_POINTS_BOTTOMRIGHT,
}
local NUM_VERTICES = #VERTICES

local CONTROL_POINTS =
{
    {
        offset = 0.0,
        coefficient = ZO_PI * 0.7,
    },
    {
        offset = ZO_HALF_PI,
        coefficient = ZO_PI,
    },
    {
        offset = ZO_PI,
        coefficient = ZO_PI,
    },
    {
        offset = ZO_HALF_PI * 3,
        coefficient = ZO_PI * 1.2,
    },
}
local NUM_CONTROL_POINTS = #CONTROL_POINTS

ZO_FlickerEffect = ZO_BaseVisualEffect:Subclass()

function ZO_FlickerEffect:Initialize(...)
    ZO_BaseVisualEffect.Initialize(self, ...)

    self.controlPoints = {}
    self.vertexInterpolants = {}
end

-- These are the optional arguments that can be passed to RegisterControl.
function ZO_FlickerEffect:CreateParameterTable(control, speedMultiplier, alphaFlickerStrength, colorFlickerStrength, maxGaussianBlurFactor, baseColor)
    local parameterTable = {}
    parameterTable.speedMultiplier = zo_clamp(speedMultiplier or 0.5, 0, 1)
    parameterTable.minAlphaCoefficient = zo_clamp(1 - (alphaFlickerStrength or 0.5), 0, 1)
    parameterTable.maxAlphaCoefficient = 1
    parameterTable.minColorCoefficient = zo_clamp(1 - (colorFlickerStrength or 0.5), 0, 1)
    parameterTable.maxColorCoefficient = 1
    parameterTable.maxGaussianBlurFactor = maxGaussianBlurFactor or 0
    parameterTable.baseColor = baseColor
    return parameterTable
end

function ZO_FlickerEffect:GetEffectName()
    return "ZO_FlickerEffect"
end

function ZO_FlickerEffect:GetValidControlTypes()
    return VALID_CONTROL_TYPES
end

function ZO_FlickerEffect:OnUpdate(frameTimeMs)
    local frameTimeS = frameTimeMs * 0.001

    -- Calculate the Fourier series control points to be combined using varied sets of coefficients
    -- and normalize the resulting sine values from [-1, 1] to [0, 1]; repeat for the upper bound speed.
    local numControlPoints = NUM_CONTROL_POINTS
    local controlPoints = self.controlPoints
    for controlPointIndex, controlPointInfo in ipairs(CONTROL_POINTS) do
        local offset = controlPointInfo.offset
        local coefficient = controlPointInfo.coefficient * frameTimeS
        controlPoints[controlPointIndex] = zo_sin(offset + coefficient) * 0.5 + 0.5
        controlPoints[controlPointIndex + numControlPoints] = zo_sin(offset * 2 + coefficient * 2) * 0.5 + 0.5
    end

    -- Apply the effect to all registered controls in the order in which they were
    -- registered (for animation consistency); repeat for the upper bound speed.
    local vertexInterpolants = self.vertexInterpolants
    for controlIndex, control in ipairs(self.controls) do
        local parameters = self.controlParameters[control]
        local baseR, baseG, baseB, baseA = parameters.baseColor:UnpackRGBA()

        -- Premultiply the vertex interpolants to match the requested flicker "speed."
        for vertexIndex, vertexPoint in ipairs(VERTICES) do
            vertexInterpolants[vertexIndex] = zo_lerp(controlPoints[vertexIndex], controlPoints[vertexIndex + numControlPoints], parameters.speedMultiplier)
        end

        -- Apply the vertex interpolants, interpreted as color and/or alpha coefficients,
        -- to the vertices of this registered control.
        local vertexInterpolantIndexOffset = controlIndex * 3
        local vertexInterpolantSum = 0
        for vertexIndex, vertexPoint in ipairs(VERTICES) do
            local vertexInterpolantIndex = ((vertexIndex + vertexInterpolantIndexOffset) % numControlPoints) + 1
            local vertexInterpolant = vertexInterpolants[vertexInterpolantIndex]
            vertexInterpolantSum = vertexInterpolantSum + vertexInterpolant

            local alphaCoefficient = zo_lerp(parameters.minAlphaCoefficient, parameters.maxAlphaCoefficient, vertexInterpolant)
            local colorCoefficient = zo_lerp(parameters.minColorCoefficient, parameters.maxColorCoefficient, vertexInterpolant)
            local r, g, b, a = baseR * colorCoefficient, baseG * colorCoefficient, baseB * colorCoefficient, baseA * alphaCoefficient
            control:SetVertexColors(vertexPoint, r, g, b, a)
        end

        if parameters.maxGaussianBlurFactor > 0 then
            -- Scale the control's Gaussian blur factor in proportion to the average "brightness."
            local averageVertexInterpolant = vertexInterpolantSum / NUM_VERTICES
            local kernelSize = control:GetGaussianBlur()
            local blurFactor = zo_lerp(0, parameters.maxGaussianBlurFactor, ZO_EaseInQuartic(averageVertexInterpolant))
            control:SetGaussianBlur(kernelSize, blurFactor)
        end
    end
end

-- Effect Specific Methods

function ZO_FlickerEffect:SetControlBaseColor(control, baseColor)
    local parameters = self:GetControlParameters(control)
    if parameters then
        parameters.baseColor = baseColor
    end
end

function ZO_FlickerEffect:SetAlphaAndColorFlickerStrength(control, alphaFlickerStrength, colorFlickerStrength)
    local parameters = self:GetControlParameters(control)
    if parameters then
        parameters.alphaFlickerStrength = alphaFlickerStrength
        parameters.colorFlickerStrength = colorFlickerStrength
    end
end

FLICKER_EFFECT = ZO_FlickerEffect:New()