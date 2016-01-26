--Shared Scroll Animation Functions
---------------------------------------

local MIN_SCROLL_VALUE = 0
local MAX_SCROLL_VALUE = 100
ZO_SCROLL_DIRECTION_HORIZONTAL = 1
ZO_SCROLL_DIRECTION_VERTICAL = 2

function ZO_SetSliderValueAnimated(self, targetValue)
    self.timeline:Stop()
    targetValue = zo_clamp(targetValue, MIN_SCROLL_VALUE, MAX_SCROLL_VALUE)
    self.animationStart = self.scrollValue
    self.animationTarget = targetValue
    self.timeline:PlayFromStart()
end

function ZO_UpdateScrollFade(useFadeGradient, scroll, scrollDirection, maxFadeGradientSize)
    if(useFadeGradient) then
        local sliderValue = select(scrollDirection, scroll:GetScrollOffsets())
        local sliderMin = 0
        local sliderMax = select(scrollDirection, scroll:GetScrollExtents())

        if(sliderValue > sliderMin) then
            scroll:SetFadeGradient(1, 0, 1, zo_min(sliderValue - sliderMin, maxFadeGradientSize or 128))
        else
            scroll:SetFadeGradient(1, 0, 0, 0)
        end
        
        if(sliderValue < sliderMax) then
            scroll:SetFadeGradient(2, 0, -1, zo_min(sliderMax - sliderValue, maxFadeGradientSize or 128))
        else
            scroll:SetFadeGradient(2, 0, 0, 0);
        end
    else
        scroll:SetFadeGradient(1, 0, 0, 0)
        scroll:SetFadeGradient(2, 0, 0, 0)
    end
end

function ZO_OnAnimationStop(animationObject, control)
    local scrollObject = animationObject.scrollObject
    scrollObject.animationStart = nil
    scrollObject.animationTarget = nil
end

function ZO_OnAnimationUpdate(animationObject, progress)
    local scrollObject = animationObject.scrollObject
    if (scrollObject.animationTarget == nil) then
        return
    end
    local value = scrollObject.animationStart + (scrollObject.animationTarget - scrollObject.animationStart) * progress
    scrollObject.scrollValue = value

    ZO_ScrollAnimation_MoveWindow(scrollObject, value)

    ZO_UpdateScrollFade(scrollObject.useFadeGradient, scrollObject.scroll, ZO_SCROLL_DIRECTION_VERTICAL, ZO_GetScrollMaxFadeGradientSize(scrollObject))
end

function ZO_GetScrollMaxFadeGradientSize(scrollObject)
    return scrollObject.maxFadeGradientSize
end

function ZO_SetScrollMaxFadeGradientSize(scrollObject, maxFadeGradientSize)
    scrollObject.maxFadeGradientSize = maxFadeGradientSize
end

function ZO_CreateScrollAnimation(scrollObject)
    local animation, timeline = CreateSimpleAnimation(ANIMATION_CUSTOM)
    animation.scrollObject = scrollObject
    animation:SetEasingFunction(ZO_BezierInEase)
    animation:SetUpdateFunction(ZO_OnAnimationUpdate)
    animation:SetDuration(10)
    animation:SetHandler("OnStop", ZO_OnAnimationStop)

    return animation, timeline
end

function ZO_ScrollRelative(self, verticalDelta)
    local scroll = self.scroll
    local _, verticalExtents = scroll:GetScrollExtents()   
    
    if(verticalExtents > 0) then
        if(self.animationTarget) then
            local oldVerticalOffset = (self.animationTarget * verticalExtents) / 100
            local newVerticalOffset = oldVerticalOffset + verticalDelta
            ZO_SetSliderValueAnimated(self, (newVerticalOffset / verticalExtents) * 100)
        else
            local _, currentVerticalOffset = scroll:GetScrollOffsets()
            local newVerticalOffset = currentVerticalOffset + verticalDelta
            ZO_SetSliderValueAnimated(self, (newVerticalOffset / verticalExtents) * 100)
        end
    end
end

function ZO_ScrollAnimation_MoveWindow(self, value)
    local scroll = self.scroll
    local _, verticalExtents = scroll:GetScrollExtents()
    
    scroll:SetVerticalScroll((value/(MAX_SCROLL_VALUE - MIN_SCROLL_VALUE)) * verticalExtents) 
end

function ZO_ScrollAnimation_OnExtentsChanged(self)
    if self then
        ZO_ScrollAnimation_MoveWindow(self, self.scrollValue)
        ZO_UpdateScrollFade(self.useFadeGradient, self.scroll, ZO_SCROLL_DIRECTION_VERTICAL, ZO_GetScrollMaxFadeGradientSize(self))
    end
end
