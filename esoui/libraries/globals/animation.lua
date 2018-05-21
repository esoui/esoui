ANIMATION_INSTANT = true

function ZO_Animation_PlayForwardOrInstantlyToEnd(timeline, instant)
    if instant then
        timeline:PlayInstantlyToEnd()
    else
        timeline:PlayForward()
    end
end

function ZO_Animation_PlayFromStartOrInstantlyToEnd(timeline, instant)
    if instant then
        timeline:PlayInstantlyToEnd()
    else
        timeline:PlayFromStart()
    end
end

function ZO_Animation_PlayBackwardOrInstantlyToStart(timeline, instant)
    if instant then
        timeline:PlayInstantlyToStart()
    else
        timeline:PlayBackward()
    end
end

--Allow playing an animation type forward or backward on an unlimited number of controls using an animation pool without having to do manual tracking.
--The animation is released when it is played back to the start.

ZO_ReversibleAnimationProvider = ZO_Object:Subclass()

function ZO_ReversibleAnimationProvider:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ReversibleAnimationProvider:Initialize(virtualTimelineName)
    self.animationPool = ZO_AnimationPool:New(virtualTimelineName)

    self.animationPool:SetCustomFactoryBehavior(function(animationTimeline)
        animationTimeline:SetHandler("OnStop", function(timeline, completedPlaying)
            if completedPlaying and timeline:IsPlayingBackward() then
                local control = timeline:GetFirstAnimation():GetAnimatedControl()
                self.controlToAnimationTimeline[control] = nil
                local poolKey = self.animationTimelineToPoolKey[timeline]
                self.animationPool:ReleaseObject(poolKey)
                self.animationTimelineToPoolKey[timeline] = nil
            end
        end)
    end)

    self.controlToAnimationTimeline = {}
    self.animationTimelineToPoolKey = {}
end

function ZO_ReversibleAnimationProvider:PlayForward(control, instant)
    local animationTimeline = self.controlToAnimationTimeline[control]
    if not animationTimeline then
        local poolKey
        animationTimeline, poolKey = self.animationPool:AcquireObject()
        animationTimeline:ApplyAllAnimationsToControl(control)
        self.controlToAnimationTimeline[control] = animationTimeline
        self.animationTimelineToPoolKey[animationTimeline] = poolKey
    end
    if instant then
        animationTimeline:PlayInstantlyToEnd()
    else
        animationTimeline:PlayForward()
    end 
end

function ZO_ReversibleAnimationProvider:PlayBackward(control, instant)
    local animationTimeline = self.controlToAnimationTimeline[control]
    --We release the timeline when we finish playing backwards, so if there is none active we're already done
    if animationTimeline then
        if instant then
            animationTimeline:PlayInstantlyToStart()
        else
            animationTimeline:PlayBackward()
        end
    end
end