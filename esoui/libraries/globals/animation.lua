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