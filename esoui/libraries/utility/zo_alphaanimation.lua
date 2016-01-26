--[[
    A utility object that wraps alpha animation behavior.  This makes it easier
    to control fade in and fade out on a single control that may need to stop or restart
    an animation before it fully finishes.  Rather than making local variables to represent
    the different animations that could play on the control, this allows you to wrap the control
    and just call FadeIn, FadeOut on this object...internally the ZO_AlphaAnimation object
    tracks its own state so it knows which animations to stop or reuse, and knows the current
    alpha of the control being managed.
    
    Here are some usage notes:
    
    - Simple utility to play a one-shot animation on a control.    
    - The control is force-shown before the animation starts, and its alpha can be forced to 1.
    - The control is NOT hidden when the fade out completes...we can add that if necessary    
    - ...and along those lines: after the animation has completed the control REMAINS SHOWN and the animation is released.
    
    NOTE: The alpha animations can be told to use the Control's current alpha, rather than forcing it to 1 or 0 before 
    beginning the animation.  This will also scale the duration of the animation appropriately.  For example, let's say
    the Control has alpha .25 and we want to play a fade out with a duration of 2 seconds.  Setting the fade option to
    ZO_ALPHA_ANIMATION_OPTION_USE_CURRENT_ALPHA will cause the animation to last .5 seconds and fade from .25 to 0 alpha.    
--]]

local ALPHA_OPAQUE = 1
local ALPHA_TRANSPARENT = 0

local function OnAnimationStopped(animation, control)
    -- The callback is called after releasing the animation and resetting the control so that it can actually spawn another
    -- animation if necessary.  The animation is not passed in because it has already been released.
    if(animation.callback) then
        animation.callback(control)
        animation.callback = nil
    end    
end

ZO_ALPHA_ANIMATION_OPTION_USE_CURRENT_ALPHA = 1
ZO_ALPHA_ANIMATION_OPTION_FORCE_ALPHA = 2

ZO_ALPHA_ANIMATION_OPTION_USE_CURRENT_SHOWN = 1
ZO_ALPHA_ANIMATION_OPTION_FORCE_SHOWN = 2

local function InitializeAnimationParams(control, delay, duration, fadeOption, shownOption, forcedAlpha)
    delay = delay or 0
    delay = zo_abs(delay)
    
    duration = duration or 1
    duration = zo_abs(duration)
    
    local currentAlpha = control:GetAlpha()
    
    if(fadeOption == ZO_ALPHA_ANIMATION_OPTION_FORCE_ALPHA)
    then
        control:SetAlpha(forcedAlpha)
        currentAlpha = forcedAlpha
    end
    
    if shownOption == ZO_ALPHA_ANIMATION_OPTION_FORCE_SHOWN
    then
        control:SetHidden(false)
    end

    return delay, duration, currentAlpha
end

--[[
    Interface to obtain the animation object that is linked to the control
--]]
function ZO_AlphaAnimation_GetAnimation(control)
    return control.m_fadeAnimation
end

ZO_AlphaAnimation = ZO_Object:Subclass()

function ZO_AlphaAnimation:New(animatedControl)
    local a = ZO_Object.New(self)
    
    if(animatedControl)
    then    
        a.m_animatedControl = animatedControl
        a.m_fadeTimeline = nil 

        a.minAlpha = ALPHA_TRANSPARENT
        a.maxAlpha = ALPHA_OPAQUE
        
        -- Link the control to this animation object
        animatedControl.m_fadeAnimation = a
    end
    
    return a
end

function ZO_AlphaAnimation:GetControl()
    return self.m_animatedControl
end

function ZO_AlphaAnimation:SetMinMaxAlpha(minAlpha, maxAlpha)
    self.minAlpha = minAlpha
    self.maxAlpha = maxAlpha
end

ZO_ALPHA_ANIMATION_OPTION_PREVENT_CALLBACK = 1

function ZO_AlphaAnimation:Stop(stopOption)
    if(self.m_fadeTimeline)
    then
        if(stopOption == ZO_ALPHA_ANIMATION_OPTION_PREVENT_CALLBACK)
        then
            self.m_fadeTimeline.callback = nil
        end

        self.m_fadeTimeline:Stop()
    end
end

function ZO_AlphaAnimation:IsPlaying()
    if(self.m_fadeTimeline)
    then
        return self.m_fadeTimeline:IsPlaying()
    end

    return false
end

local function GetOrCreateFadeAnimation(self, control)
    if self.m_fadeTimeline then
        return self.m_fadeTimeline:GetFirstAnimation()
    else
        local fade
        fade, self.m_fadeTimeline = CreateSimpleAnimation(ANIMATION_ALPHA, control)
        return fade
    end
end

function ZO_AlphaAnimation:FadeIn(delay, duration, fadeOption, callback, shownOption)
    self:Stop()

    fadeOption = fadeOption or ZO_ALPHA_ANIMATION_OPTION_USE_CURRENT_ALPHA
    shownOption = shownOption or ZO_ALPHA_ANIMATION_OPTION_FORCE_SHOWN
    local control = self.m_animatedControl

    local currentAlpha
    delay, duration, currentAlpha = InitializeAnimationParams(control, delay, duration, fadeOption, shownOption, self.minAlpha)

    local fade = GetOrCreateFadeAnimation(self, control)

    fade:SetDuration(duration - (currentAlpha * duration))
    fade:SetAlphaValues(currentAlpha, self.maxAlpha)
    fade:SetHandler("OnStop", OnAnimationStopped)
    fade.callback = callback

    self.m_fadeTimeline:SetAnimationOffset(fade, delay)
    self.m_fadeTimeline:SetPlaybackType(ANIMATION_PLAYBACK_ONE_SHOT, 0)
    self.m_fadeTimeline:PlayFromStart()
end

function ZO_AlphaAnimation:FadeOut(delay, duration, fadeOption, callback, shownOption)
    self:Stop()
    
    fadeOption = fadeOption or ZO_ALPHA_ANIMATION_OPTION_USE_CURRENT_ALPHA
    shownOption = shownOption or ZO_ALPHA_ANIMATION_OPTION_FORCE_SHOWN
    local control = self.m_animatedControl
    
    local currentAlpha
    delay, duration, currentAlpha = InitializeAnimationParams(control, delay, duration, fadeOption, shownOption, self.maxAlpha)

    local fade = GetOrCreateFadeAnimation(self, control)

    fade:SetDuration(currentAlpha * duration)
    fade:SetAlphaValues(currentAlpha, self.minAlpha)
    fade:SetHandler("OnStop", OnAnimationStopped)
    fade.callback = callback

    self.m_fadeTimeline:SetAnimationOffset(fade, delay)
    self.m_fadeTimeline:SetPlaybackType(ANIMATION_PLAYBACK_ONE_SHOT, 0)
    self.m_fadeTimeline:PlayFromStart()
end

function ZO_AlphaAnimation:PingPong(initial, final, duration, loopCount, callback)
    self:Stop()
    
    local control = self.m_animatedControl
    local fade = GetOrCreateFadeAnimation(self, control)
    fade:SetDuration(duration)
    fade:SetAlphaValues(initial, final)
    fade:SetHandler("OnStop", OnAnimationStopped)
    fade.callback = callback

    self.m_fadeTimeline:SetAnimationOffset(fade, 0)
    self.m_fadeTimeline:SetPlaybackType(ANIMATION_PLAYBACK_PING_PONG, loopCount or LOOP_INDEFINITELY)
    self.m_fadeTimeline:PlayFromStart()
end

function ZO_AlphaAnimation:SetPlaybackLoopsRemaining(loopCount)
    self.m_fadeTimeline:SetPlaybackLoopsRemaining(loopCount or LOOP_INDEFINITELY)
end

function ZO_AlphaAnimation:SetPlaybackLoopCount(loopCount)
    self.m_fadeTimeline:SetPlaybackLoopCount(loopCount)
end

function ZO_AlphaAnimation:GetPlaybackLoopsRemaining()
    return self.m_fadeTimeline:GetPlaybackLoopsRemaining()
end