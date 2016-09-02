ZO_CrownCratesAnimatable = ZO_Object:Subclass()

function ZO_CrownCratesAnimatable:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_CrownCratesAnimatable:Initialize(control)
    self.control = control
    control:Create3DRenderSpace()
    self.playingAnimationTimelines = {}

    self.textureControls = {}
    for i = 1, control:GetNumChildren() do
        local childControl = control:GetChild(i)
        if childControl:GetType() == CT_TEXTURE then
            table.insert(self.textureControls, childControl)
            childControl:Create3DRenderSpace()
        end
    end
end

function ZO_CrownCratesAnimatable:Reset()
    self:StopAllAnimations()

    self.control:SetHidden(true)
    for _, textureControl in ipairs(self.textureControls) do
        textureControl:SetAlpha(0)
        textureControl:SetMouseEnabled(false)
    end
end

function ZO_CrownCratesAnimatable:GetControl()
    return self.control
end

function ZO_CrownCratesAnimatable:AcquireAndApplyAnimationTimeline(animationType, textureControl, customOnStop)
    local animationPool = CROWN_CRATES:GetAnimationPool(animationType)
    local animationTimeline, animationTimelineKey = animationPool:AcquireObject()
    animationTimeline.animationType = animationType
    animationTimeline:SetHandler("OnStop", function(timeline, completedPlaying)
        self:OnAnimationStopped(timeline, animationTimelineKey, animationPool)
        if customOnStop then
            customOnStop(timeline, completedPlaying)
        end
    end)

    if textureControl then
        for i = 1, animationTimeline:GetNumAnimations() do
            local animation = animationTimeline:GetAnimation(i)
            animation:SetAnimatedControl(textureControl)
        end
    end
    
    return animationTimeline
end

function ZO_CrownCratesAnimatable:GetOnePlayingAnimationOfType(animationType)
    for _, animationTimeline in ipairs(self.playingAnimationTimelines) do
        if animationTimeline.animationType == animationType then
            return animationTimeline
        end
    end
end

function ZO_CrownCratesAnimatable:ReverseAnimationsOfType(animationType)
    for _, animationTimeline in ipairs(self.playingAnimationTimelines) do
        if animationTimeline.animationType == animationType then
            if animationTimeline:IsPlayingBackward() then
                animationTimeline:PlayForward()
            else
                animationTimeline:PlayBackward()
            end
        end
    end
end

function ZO_CrownCratesAnimatable:StopAllAnimations()
    if #self.playingAnimationTimelines > 0 then
        --Copy so the iteration doesn't break when we remove a timeline from the table
        local playingAnimationsCopy = {}
        ZO_ShallowTableCopy(self.playingAnimationTimelines, playingAnimationsCopy)
        for _, animationTimeline in ipairs(playingAnimationsCopy) do
            animationTimeline:Stop()
        end
    end
end

function ZO_CrownCratesAnimatable:StopAllAnimationsOfType(animationType)
    if #self.playingAnimationTimelines > 0 then
        --Copy so the iteration doesn't break when we remove a timeline from the table
        local playingAnimationsCopy = {}
        ZO_ShallowTableCopy(self.playingAnimationTimelines, playingAnimationsCopy)
        for _, animationTimeline in ipairs(playingAnimationsCopy) do
            if animationTimeline.animationType == animationType then
                animationTimeline:Stop()
            end
        end
    end
end

function ZO_CrownCratesAnimatable:EnsureAnimationsArePlayingInDirection(animationType, forward)
    local animationTimeline = self:GetOnePlayingAnimationOfType(animationType)
    local backward = not forward
    if animationTimeline then
        if animationTimeline:IsPlayingBackward() ~= backward then
            self:ReverseAnimationsOfType(animationType)
        else
            --Already playing the right direction
        end
        return true
    else
        return false
    end
end

do
    local FORWARD = true
    function ZO_CrownCratesAnimatable:StartAnimation(animationTimeline, direction)
        table.insert(self.playingAnimationTimelines, animationTimeline)
        if direction == nil or direction == FORWARD then
            animationTimeline:PlayFromStart()
        else
            animationTimeline:PlayFromEnd()
        end
    end
end

function ZO_CrownCratesAnimatable:OnAnimationStopped(animationTimeline, animationTimelineKey, animationPool)
    for i, currentAnimationTimeline in ipairs(self.playingAnimationTimelines) do
        if currentAnimationTimeline == animationTimeline then
            table.remove(self.playingAnimationTimelines, i)
            break
        end
    end
    animationPool:ReleaseObject(animationTimelineKey)
end

function ZO_CrownCratesAnimatable:SetupBezierArcBetween(translateAnimation, startX, startY, startZ, endX, endY, endZ, arcHeightInScreenPercent)
    translateAnimation:SetTranslateOffsets(startX, startY, startZ, endX, endY, endZ)

    --The control point starts at the mid point of the direct line from start to end
    local midX = 0.5 * (startX + endX)
    local midY = 0.5 * (startY + endY)
    local midZ = 0.5 * (startZ + endZ)

    --We then add to the Y a certain amount of world units that is a percentage of the screen height
    local frustumWidthMidpointWorld, frustumHeightMidpointWorld = GetWorldDimensionsOfViewFrustumAtDepth(midZ)        
    local yOffset = arcHeightInScreenPercent * frustumHeightMidpointWorld   
    translateAnimation:SetBezierControlPoint(1, midX, midY + yOffset, midZ)
    translateAnimation:SetBezierControlPoint(2, midX, midY + yOffset, midZ)
end