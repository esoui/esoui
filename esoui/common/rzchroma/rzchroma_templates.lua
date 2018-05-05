local CUSTOM = true
local PREDEFINED = false

ZO_CHROMA_EFFECT_DRAW_LEVEL =
{
    FALLBACK = 0, --Blanket layer, lowest level, there to make sure there's always something genericly lit
    UNDERLAY_LOW =  1, --Blanket layer, like fallback but more specific, e.g.: alliance color when known
    UNDERLAY_HIGH = 2, --Blanket layer, an extra underlay that goes overtop of UNDERLAY_LOW, e.g.: specialized hot zones
    ANIMATION =  300, --Ripples and highlights, usually blending with effects underneath
    ACTIVE_KEY_ACTION =  400, --For lighting up relevant keys, typically regardless of the effects underneath, but can blend if necessary
    ACTIVE_KEY_UI =  410, --For lighting up relevant keys, typically regardless of the effects underneath, but can blend if necessary
    DEATH = 450, --The glows for death cover pretty much everything else, with the exception of COVER
    COVER =  500, --For when you need to just cover up all the other effects
}

ZO_CHROMA_CUSTOM_EFFECT_VALID_CELL = true

--------------
--Animations--
--------------

ZO_ChromaAnimationTimer = ZO_Object:Subclass()

function ZO_ChromaAnimationTimer:New(...)
    local object = ZO_Object:New(self)
    object:Initialize(...)
    return object
end

function ZO_ChromaAnimationTimer:Initialize(animationTimerData)
    self.minValue = animationTimerData.minValue
    self.maxValue = animationTimerData.maxValue
    self.valueRange = self.maxValue - self.minValue
    self.startValue = animationTimerData.startValue
    self.deleteOnComplete = animationTimerData.deleteOnComplete

    self.timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual(animationTimerData.animationName)
    self.timeline.object = self
end

function ZO_ChromaAnimationTimer:PlayFromStart()
    self.value = self.startValue
    self.isComplete = false
    self.timeline:PlayFromStart()
end

function ZO_ChromaAnimationTimer:SetProgress(progress)
    self.value = self.minValue + (self.valueRange * progress)
end

function ZO_ChromaAnimationTimer:GetValue()
    return self.value
end

function ZO_ChromaAnimationTimer:OnAnimationComplete()
    self.isComplete = true
end

function ZO_ChromaAnimationTimer:IsPlaying()
    return self.timeline:IsPlaying()
end

function ZO_ChromaAnimationTimer:IsComplete()
    return self.isComplete
end

--Pulsate--
ZO_ChromaPulsateTimer = ZO_ChromaAnimationTimer:Subclass()

function ZO_ChromaPulsateTimer:New(...)
    return ZO_ChromaAnimationTimer.New(self, ...)
end

function ZO_ChromaPulsateTimer:OnAnimationComplete()
    self.timeline:PlayFromStart()
end

function ZO_ChromaAnimation_SetProgress(animation, progress)
    animation:GetTimeline().object:SetProgress(progress)
end

function ZO_ChromaAnimation_OnStop(timeline, completedPlaying)
    if completedPlaying then
        timeline.object:OnAnimationComplete()
    end
end

ZO_CHROMA_ANIMATION_TIMER_DATA =
{
    DEATH_FADE_OUT = { animationClass = ZO_ChromaAnimationTimer, animationName = "ZO_ChromaDeathFadeOutAnimation", minValue = .33, maxValue = 1, startValue = 1, useAlpha = false, restartOnAdd = true, deleteOnComplete = false, },
    DEATH_PULSATE = { animationClass = ZO_ChromaPulsateTimer, animationName = "ZO_ChromaDeathPulsateAnimation", minValue = .33, maxValue = 1, startValue = .33, useAlpha = false, restartOnAdd = false, deleteOnComplete = false, },
    QUICKSLOT_ONE_PULSE = { animationClass = ZO_ChromaAnimationTimer, animationName = "ZO_ChromaOnePulseAnimation", minValue = .11, maxValue = 1, startValue = .33, useAlpha = true, restartOnAdd = true, deleteOnComplete = true, },
    ULTIMATE_ONE_PULSE = { animationClass = ZO_ChromaAnimationTimer, animationName = "ZO_ChromaOnePulseAnimation", minValue = .5, maxValue = 1, startValue = .5, useAlpha = false, restartOnAdd = true, deleteOnComplete = false, },
    KEYBIND_PROMPT_PULSATE = { animationClass = ZO_ChromaPulsateTimer, animationName = "ZO_ChromaSteadyPulsateAnimation", minValue = .3, maxValue = 1, startValue = .3, useAlpha = false, restartOnAdd = true, deleteOnComplete = false, },
}

do
    local ANIMATION_TIMERS = {}

    function ZO_GetChromaAnimationTimer(animationTimerData)
        local animationTimer = ANIMATION_TIMERS[animationTimerData]
        if not animationTimer then
            animationTimer = animationTimerData.animationClass:New(animationTimerData)
            ANIMATION_TIMERS[animationTimerData] = animationTimer
        end
        return animationTimer
    end
end

------------------------
--Base template effect--
------------------------

ZO_ChromaEffectBaseTemplate = ZO_Object:Subclass()

function ZO_ChromaEffectBaseTemplate:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ChromaEffectBaseTemplate:Initialize(deviceType, drawLevel, isCustom)
    self.deviceType = deviceType
    self.drawLevel = drawLevel
    self.isCustom = isCustom
    local function OnUpdate(timeMs, callbackManager)
        self:OnUpdate(timeMs, callbackManager)
    end
    self.onUpdate = OnUpdate
end

function ZO_ChromaEffectBaseTemplate:IsCustom()
    return self.isCustom
end

function ZO_ChromaEffectBaseTemplate:SetIsCStyle()
    self.isCStyle = true
end

function ZO_ChromaEffectBaseTemplate:IsCStyle()
    return self.isCStyle
end

function ZO_ChromaEffectBaseTemplate:GetDrawLevel()
    return self.drawLevel
end

function ZO_ChromaEffectBaseTemplate:GetDeviceType()
    return self.deviceType
end

function ZO_ChromaEffectBaseTemplate:HandleAddEffect(callbackManager)
    self.addedTimeMs = GetFrameTimeMilliseconds()
    self.elapsedTimeMs = 0
    callbackManager:RegisterCallback("OnUpdate", self.onUpdate)
end

function ZO_ChromaEffectBaseTemplate:HandleRemoveEffect(callbackManager)
    callbackManager:UnregisterCallback("OnUpdate", self.onUpdate)
end

function ZO_ChromaEffectBaseTemplate:SetOnUpdateCallback(updateCallback)
    self.updateCallback = updateCallback
end

function ZO_ChromaEffectBaseTemplate:OnUpdate(timeMs, callbackManager)
    self.elapsedTimeMs = timeMs - self.addedTimeMs
    if self.updateCallback then
        self.updateCallback(timeMs, callbackManager, self)
    end
end

----------------------
--Custom effect Base--
----------------------

ZO_ChromaCustomEffectBase = ZO_ChromaEffectBaseTemplate:Subclass()

function ZO_ChromaCustomEffectBase:New(...)
    return ZO_ChromaEffectBaseTemplate.New(self, ...)
end

function ZO_ChromaCustomEffectBase:Initialize(deviceType, drawLevel, color, blendMode, animationTimerData, isFullGrid)
    ZO_ChromaEffectBaseTemplate.Initialize(self, deviceType, drawLevel, CUSTOM)
    self.color = color
    self.blendMode = blendMode
    self.isFullGrid = isFullGrid

    self.animationTimerData = animationTimerData
    --Don't create the timer unless we actually end up needing it
    self.animationTimer = nil
end

function ZO_ChromaCustomEffectBase:GetColor(rowIndex, columnIndex)
    assert(false, "You must override the GetColor function in your ChromaCustomEffect")
end

function ZO_ChromaCustomEffectBase:GetColorRGB(rowIndex, columnIndex)
    assert(false, "You must override the GetColorRGB function in your ChromaCustomEffect")
end

function ZO_ChromaCustomEffectBase:GetBlendMode()
    return self.blendMode
end

function ZO_ChromaCustomEffectBase:IsFullGrid()
    return self.isFullGrid
end

function ZO_ChromaCustomEffectBase:HandleAddEffect(...)
    ZO_ChromaEffectBaseTemplate.HandleAddEffect(self, ...)

    if self.animationTimerData then
        if not self.animationTimer then
            self.animationTimer = ZO_GetChromaAnimationTimer(self.animationTimerData)
        end

        if not self.animationTimer:IsPlaying() or self.animationTimerData.restartOnAdd then
            self.animationTimer:PlayFromStart()
        end

        self:RefreshColor()
    end
end

function ZO_ChromaCustomEffectBase:OnUpdate(timeMs, callbackManager)
    ZO_ChromaEffectBaseTemplate.OnUpdate(self, timeMs, callbackManager)

    if self.animationTimer then
        if self.animationTimer:IsPlaying() then
            callbackManager:MarkDirty(self.deviceType)
        end

        self:RefreshColor()
    end
end

function ZO_ChromaCustomEffectBase:RefreshColor()
    --To be overriden
end

function ZO_ChromaCustomEffectBase:GetCurrentAnimationValue()
    return self.animationTimer and self.animationTimer:GetValue() or 0
end

----------------------
--Custom effect Full--
----------------------

ZO_ChromaCustomEffectFull = ZO_ChromaCustomEffectBase:Subclass()

function ZO_ChromaCustomEffectFull:New(...)
    return ZO_ChromaCustomEffectBase.New(self, ...)
end

function ZO_ChromaCustomEffectFull:Initialize(deviceType, drawLevel, color, blendMode, animationTimerData)
    ZO_ChromaCustomEffectBase.Initialize(self, deviceType, drawLevel, color, blendMode, animationTimerData, true)
end

function ZO_ChromaCustomEffectFull:GetColor(rowIndex, columnIndex)
    return ZO_CHROMA_CUSTOM_EFFECT_VALID_CELL, self.color
end

function ZO_ChromaCustomEffectFull:GetCellValid(rowIndex, columnIndex)
    return ZO_CHROMA_CUSTOM_EFFECT_VALID_CELL
end

function ZO_ChromaCustomEffectFull:GetColorRGB(rowIndex, columnIndex)
    return ZO_CHROMA_CUSTOM_EFFECT_VALID_CELL, self.color:UnpackRGBA()
end

-----------------------
--Custom effect Cells--
-----------------------

ZO_ChromaCustomEffectCells = ZO_ChromaCustomEffectBase:Subclass()

function ZO_ChromaCustomEffectCells:New(...)
    return ZO_ChromaCustomEffectBase.New(self, ...)
end

function ZO_ChromaCustomEffectCells:Initialize(deviceType, drawLevel, color, blendMode, animationTimerData)
    ZO_ChromaCustomEffectBase.Initialize(self, deviceType, drawLevel, color, blendMode, animationTimerData, false)
    self.cells = { }
end

function ZO_ChromaCustomEffectCells:SetCellActive(rowIndex, columnIndex, isActive)
    local row = self.cells[rowIndex]
    if not row then
        if not isActive then
            -- Cell is already inactive
            return
        end

        row = { }
        self.cells[rowIndex] = row
    end

    row[columnIndex] = isActive or nil
end

function ZO_ChromaCustomEffectCells:GetColor(rowIndex, columnIndex)
    local validCell = self.cells[rowIndex] and self.cells[rowIndex][columnIndex]
    return validCell, self.color
end

---------------------------
--Full custom fade effect--
---------------------------

ZO_ChromaCustomEffectFullFadeAnimation = ZO_ChromaCustomEffectFull:Subclass()

function ZO_ChromaCustomEffectFullFadeAnimation:New(...)
    return ZO_ChromaCustomEffectFull.New(self, ...)
end

function ZO_ChromaCustomEffectFullFadeAnimation:Initialize(deviceType, drawLevel, color, blendMode, animationTimerData)
    ZO_ChromaCustomEffectFull.Initialize(self, deviceType, drawLevel, color, blendMode, animationTimerData)
    
    self.initColor = color
    self.color = ZO_ColorDef:New(color:UnpackRGB())
end

function ZO_ChromaCustomEffectFullFadeAnimation:RefreshColor()
    local currentValue = self:GetCurrentAnimationValue()
    if self.animationTimerData.useAlpha then
        self.color:SetAlpha(currentValue)
    else
        local initColor = self.initColor
        self.color:SetRGB(self.initColor.r * currentValue, self.initColor.g * currentValue, self.initColor.b * currentValue)
    end
end

----------------------------
--Cells custom fade effect--
----------------------------

ZO_ChromaCustomEffectCellsFadeAnimation = ZO_ChromaCustomEffectCells:Subclass()

function ZO_ChromaCustomEffectCellsFadeAnimation:New(...)
    return ZO_ChromaCustomEffectCells.New(self, ...)
end

function ZO_ChromaCustomEffectCellsFadeAnimation:Initialize(deviceType, drawLevel, color, blendMode, animationTimerData)
    ZO_ChromaCustomEffectCells.Initialize(self, deviceType, drawLevel, color, blendMode, animationTimerData)

    self.initColor = color
    self.color = ZO_ColorDef:New(color:UnpackRGB())
end

function ZO_ChromaCustomEffectCellsFadeAnimation:RefreshColor()
    local currentValue = self:GetCurrentAnimationValue()
    if self.animationTimerData.useAlpha then
        self.color:SetAlpha(currentValue)
    else
        local initColor = self.initColor
        self.color:SetRGB(self.initColor.r * currentValue, self.initColor.g * currentValue, self.initColor.b * currentValue)
    end
end

-------------------------
--C-Style Custom Effect--
-------------------------

--Base--

ZO_ChromaCStyleCustomEffect = ZO_ChromaEffectBaseTemplate:Subclass()

function ZO_ChromaCStyleCustomEffect:New(...)
    return ZO_ChromaEffectBaseTemplate.New(self, ...)
end

function ZO_ChromaCStyleCustomEffect:Initialize(deviceType, drawLevel, gridStyle, animationTimerData)
    ZO_ChromaEffectBaseTemplate.Initialize(self, deviceType, drawLevel, CUSTOM)
    self:SetIsCStyle(true)

    self.effectId = ChromaGenerateCustomEffect(deviceType, self:GetEffectType(), gridStyle)

    self.animationTimerData = animationTimerData
    --Don't create the timer unless we actually end up needing it
    self.animationTimer = nil
end

function ZO_ChromaCStyleCustomEffect:GetEffectId()
    return self.effectId
end

function ZO_ChromaCStyleCustomEffect:GetEffectType()
    assert(false, "You must override GetEffectType for this effect")
end

function ZO_ChromaCStyleCustomEffect:SetCellActive(row, column, isActive)
    ChromaSetCustomEffectCellActive(self:GetEffectId(), row, column, isActive)
end

function ZO_ChromaCStyleCustomEffect:SetDeleteEffectCallback(callback)
    self.deleteEffectCallback = callback
end

--Single Color--

ZO_ChromaCStyleCustomSingleColorEffect = ZO_ChromaCStyleCustomEffect:Subclass()

function ZO_ChromaCStyleCustomSingleColorEffect:New(...)
    return ZO_ChromaCStyleCustomEffect.New(self, ...)
end

function ZO_ChromaCStyleCustomSingleColorEffect:Initialize(deviceType, drawLevel, gridStyle, animationTimerData, color, blendMode)
    ZO_ChromaCStyleCustomEffect.Initialize(self, deviceType, drawLevel, gridStyle, animationTimerData)

    ChromaSetCustomEffectSingleColorRGBA(self.effectId, color:UnpackRGBA())
    ChromaSetCustomEffectSingleColorBlendMode(self.effectId, blendMode)
end

function ZO_ChromaCStyleCustomSingleColorEffect:GetEffectType()
    return CHROMA_CUSTOM_EFFECT_TYPE_SINGLE_COLOR
end

--Single Color Fading--

ZO_ChromaCStyleCustomSingleColorFadingEffect = ZO_ChromaCStyleCustomSingleColorEffect:Subclass()

function ZO_ChromaCStyleCustomSingleColorFadingEffect:New(...)
    return ZO_ChromaCStyleCustomSingleColorEffect.New(self, ...)
end

function ZO_ChromaCStyleCustomSingleColorFadingEffect:Initialize(deviceType, drawLevel, gridStyle, animationTimerData, color, blendMode)
    ZO_ChromaCStyleCustomSingleColorEffect.Initialize(self, deviceType, drawLevel, gridStyle, animationTimerData, color, blendMode)

    assert(animationTimerData, "Please provide animation timer data for this fading effect")
    ChromaSetCustomSingleColorFadingEffectUsesAlphaChannel(self.effectId, animationTimerData.useAlpha)
end

function ZO_ChromaCStyleCustomSingleColorFadingEffect:GetEffectType()
    return CHROMA_CUSTOM_EFFECT_TYPE_SINGLE_COLOR_FADING
end

function ZO_ChromaCStyleCustomSingleColorFadingEffect:HandleAddEffect(...)
    ZO_ChromaEffectBaseTemplate.HandleAddEffect(self, ...)

    if self.animationTimerData then
        if not self.animationTimer then
            self.animationTimer = ZO_GetChromaAnimationTimer(self.animationTimerData)
        end

        if not self.animationTimer:IsPlaying() or self.animationTimerData.restartOnAdd then
            self.animationTimer:PlayFromStart()
        end

        self:RefreshColor()
    end
end

function ZO_ChromaCStyleCustomSingleColorFadingEffect:OnUpdate(timeMs, callbackManager)
    ZO_ChromaEffectBaseTemplate.OnUpdate(self, timeMs, callbackManager)

    if self.animationTimer then
        if self.animationTimer:IsPlaying() then
            callbackManager:MarkDirty(self.deviceType)
        elseif self.animationTimer:IsComplete() and self.animationTimerData.deleteOnComplete then
            if self.deleteEffectCallback then
                self.deleteEffectCallback()
            else
                ChromaDeleteCustomEffectById(self.effectId)
                callbackManager:RemoveEffect(self)
                callbackManager:MarkDirty(self.deviceType)
            end
        end

        self:RefreshColor()
    end
end

function ZO_ChromaCStyleCustomSingleColorFadingEffect:RefreshColor()
    ChromaSetCustomSingleColorFadingEffectValue(self.effectId, self:GetCurrentAnimationValue())
end

function ZO_ChromaCStyleCustomSingleColorFadingEffect:GetCurrentAnimationValue()
    return self.animationTimer and self.animationTimer:GetValue() or 0
end

---------------------
--Predefined Effect--
---------------------

ZO_ChromaPredefinedEffect = ZO_ChromaEffectBaseTemplate:Subclass()

function ZO_ChromaPredefinedEffect:New(...)
    return ZO_ChromaEffectBaseTemplate.New(self, ...)
end

function ZO_ChromaPredefinedEffect:Initialize(deviceType, drawLevel, createFunction, ...)
    ZO_ChromaEffectBaseTemplate.Initialize(self, deviceType, drawLevel, PREDEFINED)
    self.createFunction = createFunction
    self.args = { ... }
end

function ZO_ChromaPredefinedEffect:FireCreateFunction()
    return self.createFunction(unpack(self.args))
end
