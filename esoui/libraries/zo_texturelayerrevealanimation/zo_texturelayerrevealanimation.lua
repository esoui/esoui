--Animation Layer
----------------------

local Layer = ZO_Object:Subclass()

function Layer:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function Layer:Initialize(textureControl, windowControl, timeline)
    self.textureControl = textureControl
    self.windowControl = windowControl
    self.windowMovementOffsetMS = 0
    self.windowTranslateAnimation = timeline:InsertAnimation(ANIMATION_TRANSLATE, self.windowControl, self.windowMovementOffsetMS)
    self.windowTranslateAnimation:SetEnabled(false)
    self.timeline = timeline
    self.windowFadeGradients = {}
end

function Layer:SetWindowNormalizedDimensions(normalizedWidth, normalizedHeight)
    self.windowNormalizedWidth = normalizedWidth
    self.windowNormalizedHeight = normalizedHeight
end

function Layer:SetWindowNormalizedEndPoints(startNX, startNY, startRegistrationPointNX, startRegistrationPointNY,  endNX, endNY, endRegistrationPointNX, endRegistrationPointNY)
    self.startNX = startNX
    self.startNY = startNY
    self.startRegistrationPointNX = startRegistrationPointNX
    self.startRegistrationPointNY = startRegistrationPointNY
    self.endNX = endNX
    self.endNY = endNY
    self.endRegistrationPointNX = endRegistrationPointNX
    self.endRegistrationPointNY = endRegistrationPointNY
end

function Layer:SetWindowMovementDurationMS(durationMS)
    self.windowMovementDurationMS = durationMS
end

function Layer:SetWindowMovementOffsetMS(offsetMS)
    self.windowMovementOffsetMS = offsetMS
end

function Layer:SetWindowFadeGradient(gradientIndex, x, y, normalizedDistance)
    self.windowFadeGradients[gradientIndex] = { x = x, y = y, normalizedDistance = normalizedDistance}
end

function Layer:SetTexture(texture)
    self.textureControl:SetTexture(texture)
end

function Layer:SetTextureCoords(left, right, top, bottom)
    self.textureControl:SetTextureCoords(left, right, top, bottom)
end

function Layer:SetTextureBlendMode(blendMode)
    self.textureControl:SetBlendMode(blendMode)
end

function Layer:AddToAnimationTimeline()
    self.textureControl:SetHidden(false)
    self.windowControl:SetHidden(false)

    local textureWidth, textureHeight = self.textureControl:GetDimensions()
    local windowWidth, windowHeight = self.windowNormalizedWidth * textureWidth, self.windowNormalizedHeight * textureHeight
    self.windowControl:SetDimensions(windowWidth, windowHeight)
    --Reset to outside the display area
    self.windowControl:SetAnchor(CENTER, nil, TOPLEFT, -windowWidth, 0)

    for gradientIndex, gradient in pairs(self.windowFadeGradients) do
        local distance
        --if the gradient normal is more horizontal multiply normalized distance by width, otherwise height.
        if zo_abs(gradient.x) > zo_abs(gradient.y) then
            distance = gradient.normalizedDistance * windowWidth
        else
            distance = gradient.normalizedDistance * windowHeight
        end
        self.windowControl:SetFadeGradient(gradientIndex, gradient.x, gradient.y, distance)
    end

    self.windowTranslateAnimation:SetEnabled(true)
    self.timeline:SetAnimationOffset(self.windowTranslateAnimation, self.windowMovementOffsetMS)
    self.windowTranslateAnimation:SetDuration(self.windowMovementDurationMS)
    self.windowTranslateAnimation:SetTranslateOffsets(self.startNX * textureWidth - (self.startRegistrationPointNX - 0.5) * windowWidth,
                                                 self.startNY * textureHeight - (self.endRegistrationPointNY - 0.5) * windowHeight,
                                                 self.endNX * textureWidth - (self.endRegistrationPointNX - 0.5) * windowWidth,
                                                 self.endNY * textureHeight - (self.endRegistrationPointNY - 0.5) * windowHeight)
end

function Layer:Reset()
    self.windowTranslateAnimation:SetEnabled(false)
    self.windowMovementOffsetMS = 0
    self.textureControl:SetBlendMode(TEX_BLEND_MODE_ALPHA)
    self.fadeGradients = {}
    self.windowControl:SetFadeGradient(1, 0, 0, 0)
    self.windowControl:SetFadeGradient(2, 0, 0, 0)
    self.windowControl:SetHidden(true)
    self.textureControl:SetHidden(true)
end

--Texture Layer Reveal Animation
-----------------------------------

ZO_TextureLayerRevealAnimation = ZO_Object:Subclass()

function ZO_TextureLayerRevealAnimation:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_TextureLayerRevealAnimation:Initialize(container)
    self.container = container
    self.timeline = ANIMATION_MANAGER:CreateTimeline()

    local function LayerFactory(pool)
        local nextControlId = pool:GetNextControlId()
        local windowControl = CreateControlFromVirtual("$(parent)RevealAnimationWindow", self.container, "ZO_TextureLayerRevealAnimationWindow", nextControlId)
        local textureControl = windowControl:GetNamedChild("Texture")
        return Layer:New(textureControl, windowControl, self.timeline)
    end

    local function LayerReset(layer, pool)
        layer:Reset()
    end

    self.layerPool = ZO_ObjectPool:New(LayerFactory, LayerReset)
end

function ZO_TextureLayerRevealAnimation:RemoveAllLayers()
    self.timeline:Stop()
    self.layerPool:ReleaseAllObjects()
end

function ZO_TextureLayerRevealAnimation:AddLayer()
    return self.layerPool:AcquireObject()
end

function ZO_TextureLayerRevealAnimation:HasLayers()
    return next(self.layerPool:GetActiveObjects()) ~= nil
end

function ZO_TextureLayerRevealAnimation:Commit()
    for _, layer in pairs(self.layerPool:GetActiveObjects()) do
        layer:AddToAnimationTimeline()
    end
end

function ZO_TextureLayerRevealAnimation:GetAnimationTimeline()
    return self.timeline
end