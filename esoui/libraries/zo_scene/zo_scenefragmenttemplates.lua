-- Simple Scene Fragment; just shows the control associated with the fragment, no fancy animations

ZO_SimpleSceneFragment = ZO_SceneFragment:Subclass()

function ZO_SimpleSceneFragment:New(...)
    return ZO_SceneFragment.New(self, ...)
end

function ZO_SimpleSceneFragment:Initialize(control)
    ZO_SceneFragment.Initialize(self)
    self.control = control
end

function ZO_SimpleSceneFragment:Show()
    self.control:SetHidden(false)
    self:OnShown()
end

function ZO_SimpleSceneFragment:Hide()
    self.control:SetHidden(true)
    self:OnHidden()
end

--Animated Scene Fragment
------------------------
local AcquireAnimation, ReleaseAnimation
do
    local animationPools = {}
    function AcquireAnimation(animationTemplate)
        if not animationPools[animationTemplate] then
            animationPools[animationTemplate] = ZO_AnimationPool:New(animationTemplate)
        end
        return animationPools[animationTemplate]:AcquireObject()
    end

    function ReleaseAnimation(animationTemplate, key)
        animationPools[animationTemplate]:ReleaseObject(key)
    end
end

ZO_AnimatedSceneFragment = ZO_SceneFragment:Subclass()

function ZO_AnimatedSceneFragment:New(...)
    return ZO_SceneFragment.New(self, ...)
end

function ZO_AnimatedSceneFragment:Initialize(animationTemplate, control, alwaysAnimate, duration)
    ZO_SceneFragment.Initialize(self)
    self.control = control
    self.alwaysAnimate = alwaysAnimate
    self.animationOnStop = function()
                                self.animation:SetHandler("OnStop", nil)

                                ReleaseAnimation(self.animationTemplate, self.animationKey)
                                self.animation = nil
                                self.animationKey = nil

                                -- This callback should be at the end of the function because it could cause other sequential animations to play
                                self:OnShown()
                            end
    self.animationReverseOnStop = function(_, completedPlaying)
                                    self.animation:SetHandler("OnStop", nil)

                                    if completedPlaying then
                                        self.animation:PlayInstantlyToEnd()
                                    end

                                    control:SetHidden(true)
                                                                    
                                    ReleaseAnimation(self.animationTemplate, self.animationKey)
                                    self.animation = nil
                                    self.animationKey = nil

                                    -- This callback should be at the end of the function because it could cause other sequential animations to play
                                    self:OnHidden()
                                end

    self.duration = duration or DEFAULT_SCENE_TRANSITION_TIME
    self.animationTemplate = animationTemplate
end

function ZO_AnimatedSceneFragment:GetAnimation()
    if(self.animation == nil) then
        self.animation, self.animationKey = AcquireAnimation(self.animationTemplate)
        for i=1, self.animation:GetNumAnimations() do
            self.animation:GetAnimation(i):SetDuration(self.duration)
        end
        self.animation:ApplyAllAnimationsToControl(self.control)
    end

    return self.animation
end

function ZO_AnimatedSceneFragment:GetControl()
    return self.control
end

function ZO_AnimatedSceneFragment:AddInstantScene(scene)
    if(not self.instantScenes) then
        self.instantScenes = {}
    end
    table.insert(self.instantScenes, scene)
end

function ZO_AnimatedSceneFragment:IsAnimatedInCurrentScene()
    local currentScene = self.sceneManager:GetCurrentScene()
    if(self.instantScenes) then
        for _, scene in ipairs(self.instantScenes) do
            if(currentScene == scene) then
                return false
            end 
        end
    end

    return true
end

function ZO_AnimatedSceneFragment:Show()
    local currentScene = self.sceneManager:GetCurrentScene()
    local animation = self:GetAnimation()
    animation:SetHandler("OnStop", self.animationOnStop)
    self.control:SetHidden(false)
    if((currentScene:GetState() ~= SCENE_SHOWN or self.alwaysAnimate) and self:IsAnimatedInCurrentScene()) then

        if(animation:IsPlaying()) then     
            animation:PlayForward()
        else
            animation:PlayFromStart()
        end
    else
        animation:PlayInstantlyToEnd()
    end
end

function ZO_AnimatedSceneFragment:Hide()
    local currentScene = self.sceneManager:GetCurrentScene()
    local animation = self:GetAnimation()
    animation:SetHandler("OnStop", self.animationReverseOnStop)

    if((currentScene:GetState() == SCENE_HIDING or self.alwaysAnimate) and self:IsAnimatedInCurrentScene()) then
        if(animation:IsPlaying()) then     
            animation:PlayBackward()
        else
            animation:PlayFromEnd()
        end
    else
        animation:PlayInstantlyToStart()
    end
end

ZO_FadeSceneFragment = ZO_AnimatedSceneFragment:Subclass()

function ZO_FadeSceneFragment:New(control, alwaysAnimate, duration)
    return ZO_AnimatedSceneFragment.New(self, "FadeSceneAnimation", control, alwaysAnimate, duration)
end

ZO_TranslateFromLeftSceneFragment = ZO_AnimatedSceneFragment:Subclass()

function ZO_TranslateFromLeftSceneFragment:New(control, alwaysAnimate, duration)
    return ZO_AnimatedSceneFragment.New(self, "TranslateFromLeftSceneAnimation", control, alwaysAnimate, duration)
end

ZO_TranslateFromRightSceneFragment = ZO_AnimatedSceneFragment:Subclass()

function ZO_TranslateFromRightSceneFragment:New(control, alwaysAnimate, duration)
    return ZO_AnimatedSceneFragment.New(self, "TranslateFromRightSceneAnimation", control, alwaysAnimate, duration)
end

ZO_TranslateFromBottomSceneFragment = ZO_AnimatedSceneFragment:Subclass()

function ZO_TranslateFromBottomSceneFragment:New(control, alwaysAnimate, duration)
    return ZO_AnimatedSceneFragment.New(self, "TranslateFromBottomSceneAnimation", control, alwaysAnimate, duration)
end

ZO_TranslateFromTopSceneFragment = ZO_AnimatedSceneFragment:Subclass()

function ZO_TranslateFromTopSceneFragment:New(control, alwaysAnimate, duration)
    return ZO_AnimatedSceneFragment.New(self, "TranslateFromTopSceneAnimation", control, alwaysAnimate, duration)
end

ZO_ConveyorSceneFragment = ZO_SceneFragment:Subclass()

function ZO_ConveyorSceneFragment:New(...)
    return ZO_SceneFragment.New(self, ...)
end

function ZO_ConveyorSceneFragment:Initialize(control, alwaysAnimate, inAnimation, outAnimation)
    ZO_SceneFragment.Initialize(self)
    self.control = control
    self.alwaysAnimate = alwaysAnimate
    self.inAnimation = inAnimation or "ConveyorInSceneAnimation"
    self.outAnimation = outAnimation or "ConveyorOutSceneAnimation"

    self:ComputeOffsets()

    self.animationOnStop = function(_, completedPlaying)
        self.animation:SetHandler("OnStop", nil)
        local wasHiding = self:GetState() == SCENE_FRAGMENT_HIDING

        if wasHiding and completedPlaying then
            self.animation:PlayInstantlyToStart()
        end

        if wasHiding then
            control:SetHidden(true)
        end
                                                                    
        ReleaseAnimation(self.currentAnimationTemplate, self.animationKey)
        self.animation = nil
        self.animationKey = nil
        self.currentAnimationTemplate = nil

        -- This callback should be at the end of the function because it could cause other sequential animations to play
        if wasHiding then
            self:OnHidden()
        else
            self:OnShown()
        end
    end
end

do
    --Used to allow a conveyor animation to move in the opposite direction it was designed as
    local g_reverseAnimationDirection = false

    --Allows the function below to return a variable number of results while still preforming the reset afterward
    local function UnreverseAndReturnResults(...)
        g_reverseAnimationDirection = false
        return ...
    end

    -- Use this function in order to wrap your logic in a closure that will reverse the animation and un-reverse when it's done
    -- Right now it only supports 3 return values for the behavior, add more as needed.
    -- This system makes sure we can't accidentally reverse the direction and leave it reversed.  Do not expose the reverse variable globally
    -- Or allow a global function to set it explicitely
    function ZO_ConveyorSceneFragment_ReverseAnimationDirectionForBehavior(behavior, ...)
        g_reverseAnimationDirection = true
        return UnreverseAndReturnResults(behavior(...))
    end

    function ZO_ConveyorSceneFragment:ChooseAnimation()
        -- When reversed, things that would normally move forward should move backward
        -- And the animations should be swapped so the alhpas fade in the right order
        local forward = not g_reverseAnimationDirection
        local backward = not forward
        local inAnimation = g_reverseAnimationDirection and self.outAnimation or self.inAnimation
        local outAnimation = g_reverseAnimationDirection and self.inAnimation or self.outAnimation

        local currentScene = self.sceneManager:GetCurrentScene()
        if self:GetState() == SCENE_FRAGMENT_SHOWING then
            if self.sceneManager:WasSceneOnStack(currentScene:GetName()) then
                return outAnimation, backward
            end
            return inAnimation, forward
        else
            if self.sceneManager:WasSceneOnTopOfStack(currentScene:GetName()) then
                if not self.sceneManager:IsSceneOnStack(currentScene:GetName()) then
                    local nextScene = self.sceneManager:GetNextScene()
                    if not nextScene or nextScene ~= self.sceneManager:GetBaseScene() then
                        return inAnimation, backward
                    end
                end

                return outAnimation, forward
            end
            return outAnimation, forward
        end
    end
end

function ZO_ConveyorSceneFragment:ComputeOffsets()
    self.offsets = {}
    local templates = { self.inAnimation, self.outAnimation }
    for _, template in ipairs(templates) do
        local templateInfo = {}
        self.offsets[template] = templateInfo
        for i = 1, MAX_ANCHORS do
            local anchorInfo = {}
            templateInfo[i] = anchorInfo
            anchorInfo.xStartOffset, anchorInfo.xEndOffset = self:GetAnimationXOffsets(i, template)
            anchorInfo.yOffset = self:GetAnimationYOffset(i)
        end
    end
end

function ZO_ConveyorSceneFragment:GetAnimationXOffsets(index, animationTemplate)
    local isValid, point, relTo, relPoint, offsetX, offsetY = self.control:GetAnchor(index - 1)
    if isValid then    
        local controlWidth = self.control:GetWidth()

        local middleX = offsetX
        if animationTemplate == "ConveyorInSceneAnimation" then
            local rightX = middleX + controlWidth
            return rightX, middleX
        else
            local leftX = middleX - controlWidth
            return middleX, leftX
        end
    end
    return 0, 0
end

function ZO_ConveyorSceneFragment:GetAnimationYOffset(index)
    local isValid, point, relTo, relPoint, offsetX, offsetY = self.control:GetAnchor(index - 1)
    if isValid then
        return offsetY
    end
    return 0
end

function ZO_ConveyorSceneFragment:ConfigureTranslateAnimation(index)
    local templateInfo = self.offsets[self.currentAnimationTemplate]
    local anchorInfo = templateInfo[index]
    local animation = self.animation:GetAnimation(index)
    animation:SetStartOffsetX(anchorInfo.xStartOffset)
    animation:SetEndOffsetX(anchorInfo.xEndOffset)
    animation:SetStartOffsetY(anchorInfo.yOffset)
    animation:SetEndOffsetY(anchorInfo.yOffset)
end

function ZO_ConveyorSceneFragment:GetAnimation()
    local animationTemplate, playForward = self:ChooseAnimation()

    local currentScene = self.sceneManager:GetCurrentScene()

    if self.currentAnimationTemplate ~= animationTemplate then
        if self.animation then
            self.animation:SetHandler("OnStop", nil)
            self.animation:Stop()
        end

        self.currentAnimationTemplate = animationTemplate
        self.animation, self.animationKey = AcquireAnimation(animationTemplate)
        self.animation:SetHandler("OnStop", self.animationOnStop)

        self:ConfigureTranslateAnimation(1)
        self:ConfigureTranslateAnimation(2)
        self.animation:ApplyAllAnimationsToControl(self.control)
    end

    return self.animation, playForward
end

function ZO_ConveyorSceneFragment:GetControl()
    return self.control
end

function ZO_ConveyorSceneFragment:AddInstantScene(scene)
    if not self.instantScenes then
        self.instantScenes = {}
    end
    table.insert(self.instantScenes, scene)
end

function ZO_ConveyorSceneFragment:IsAnimatedInCurrentScene()
    local currentScene = self.sceneManager:GetCurrentScene()
    if self.instantScenes then
        for _, scene in ipairs(self.instantScenes) do
            if currentScene == scene then
                return false
            end 
        end
    end

    return true
end

local function PlayAnimation(animation, playForward, instant)
    if instant then
        if playForward then
            animation:PlayInstantlyToEnd()
        else
            animation:PlayInstantlyToStart()
        end
    else
        if playForward then
            animation:PlayFromStart()
        else
            animation:PlayFromEnd()
        end
    end
end

function ZO_ConveyorSceneFragment:GetBackgroundFragment()
    return GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT
end

function ZO_ConveyorSceneFragment:ChooseAndPlayAnimation()
    local currentScene = self.sceneManager:GetCurrentScene()
    local animation, playForward = self:GetAnimation()
    
    local instant = (currentScene:GetState() == SCENE_SHOWN and not self.alwaysAnimate) or not self:IsAnimatedInCurrentScene()
    if not instant then
        local backgroundFragment = self:GetBackgroundFragment()
        --if the background is translating in we don't want the conveyor to animate because it doubles up the movement
        if backgroundFragment:GetState() == SCENE_FRAGMENT_SHOWING or backgroundFragment:GetState() == SCENE_FRAGMENT_HIDDEN then
            instant = true
        end
    end
    PlayAnimation(animation, playForward, instant)
end

function ZO_ConveyorSceneFragment:Show()
    self:ChooseAndPlayAnimation()
    self.control:SetHidden(false)
end

function ZO_ConveyorSceneFragment:Hide()
    self:ChooseAndPlayAnimation()
end

--HUD Fade Scene Fragment

DEFAULT_HUD_DURATION = 250
ZO_HUDFadeSceneFragment = ZO_SceneFragment:Subclass()

function ZO_HUDFadeSceneFragment:New(...)
    return ZO_SceneFragment.New(self, ...)
end

function ZO_HUDFadeSceneFragment:Initialize(control, showDuration, hideDuration)
    ZO_SceneFragment.Initialize(self)

    showDuration = showDuration or DEFAULT_HUD_DURATION
    hideDuration = hideDuration or 0

    self.hiddenReasons = ZO_HiddenReasons:New()
    self.animationOnStop =  function(timeline, completed)
                                if completed then
                                    self:OnShown()
                                end
                            end
    self.animationReverseOnStop = function(timeline, completed)
                                    if completed then
                                        control:SetHidden(true)
                                        control:SetAlpha(1)
                                        self:OnHidden()
                                    end
                                end

    self.control = control
    self.showDuration = showDuration
    self.hideDuration = hideDuration

    self:SetConditional(function()
        return not self.hiddenReasons:IsHidden()
    end)

    --Allow Show and Hide to be called even if we're already showing or hiding. Something may come along with a hide that
    --requests to be hidden faster than the hide already in progress.
    self:SetAllowShowHideTimeUpdates(true)
end

function ZO_HUDFadeSceneFragment:GetAnimation()
    if(self.animation == nil) then
        self.animation, self.animationKey = AcquireAnimation("FadeSceneAnimation")
        self.animation:ApplyAllAnimationsToControl(self.control)
    end

    return self.animation
end

function ZO_HUDFadeSceneFragment:SetHiddenForReason(reason, hidden, customShowDuration, customHideDuration)
    --Refresh here even if this reason didn't change the hidden state for the hiddenReasons object. If, for example, a reason came in
    --that wanted to hide over 0 ms and the fragment was currently hiding over 200ms, we want to Refresh so we can Hide at the faster rate.
    self.hiddenReasons:SetHiddenForReason(reason, hidden)
    self:Refresh(customShowDuration, customHideDuration)
end

function ZO_HUDFadeSceneFragment:IsHiddenForReason(reason)
    return self.hiddenReasons:IsHiddenForReason(reason)
end

function ZO_HUDFadeSceneFragment:Show(customShowDuration)
    local animation = self:GetAnimation()
    local alphaAnimation = animation:GetFirstAnimation()
    local duration = customShowDuration or self.showDuration 
    if(animation:IsPlaying()) then
        --set the show duration
        local progress = animation:GetFullProgress()
        animation:Stop()
        animation:SetHandler("OnStop", self.animationOnStop)
        local currentDuration = alphaAnimation:GetDuration()
        --take the slowest requested show
        alphaAnimation:SetDuration(zo_max(duration, currentDuration))
        animation:SetProgress(progress)
        animation:PlayForward()
    else
        if(self.control:IsHidden()) then
            --play from start at show duration
            self.control:SetHidden(false)
            animation:SetHandler("OnStop", self.animationOnStop)
            alphaAnimation:SetDuration(duration)
            animation:PlayFromStart()
        end
    end
end

function ZO_HUDFadeSceneFragment:Hide(customHideDuration)
    local animation = self:GetAnimation()
    local alphaAnimation = animation:GetFirstAnimation()
    local duration = customHideDuration or self.hideDuration
    if(animation:IsPlaying()) then
        --set the hide duration
        local progress = animation:GetFullProgress()
        animation:Stop()
        animation:SetHandler("OnStop", self.animationReverseOnStop)
        local currentDuration = alphaAnimation:GetDuration()
        --take the fastest requested hide
        alphaAnimation:SetDuration(zo_min(duration, currentDuration))
        animation:SetProgress(progress)
        animation:PlayBackward()
    else
        if(not self.control:IsHidden()) then
            --play from end at hide duration
            animation:SetHandler("OnStop", self.animationReverseOnStop)
            alphaAnimation:SetDuration(duration)
            animation:PlayFromEnd()
        else
            self:OnHidden()
        end
    end
end

function ZO_HUDFadeSceneFragment:OnShown()
    if(self.state == SCENE_FRAGMENT_SHOWING) then
        ZO_SceneFragment.OnShown(self)
    end
end

function ZO_HUDFadeSceneFragment:OnHidden()
    if(self.state == SCENE_FRAGMENT_HIDING) then
        ZO_SceneFragment.OnHidden(self)
    end
end

-------------------------
--Anchor Scene Fragment
-------------------------

ZO_AnchorSceneFragment = ZO_SceneFragment:Subclass()

function ZO_AnchorSceneFragment:New(...)
    return ZO_SceneFragment.New(self, ...)
end

function ZO_AnchorSceneFragment:Initialize(control, anchor)
    ZO_SceneFragment.Initialize(self)
    self.control = control
    self.anchor = anchor
end

function ZO_AnchorSceneFragment:Show()
    self.anchor:Set(self.control)
    self:OnShown()
end

-------------------------
--Background Fragment
-------------------------

ZO_BackgroundFragment = {}

function ZO_BackgroundFragment:ResetOnHiding()
    self:TakeFocus()
end

function ZO_BackgroundFragment:ResetOnHidden()
    local FADE_IN = true
    local INSTANT_FADE = true
    self:FadeRightDivider(FADE_IN, INSTANT_FADE)
end

function ZO_BackgroundFragment:Mixin(baseFragment)
    zo_mixin(baseFragment, self)
    baseFragment:ResetOnHiding()
    baseFragment:ResetOnHidden()
    
    SCENE_MANAGER:RegisterCallback("SceneStateChanged", function(scene, oldState, newState)
            if newState == SCENE_HIDING then
                if scene:HasFragment(baseFragment) then
                    baseFragment:ResetOnHiding()
                end
            elseif newState == SCENE_HIDDEN then
                if scene:HasFragment(baseFragment) then
                    baseFragment:ResetOnHidden()
                end
            end
        end)
end

function ZO_BackgroundFragment:TakeFocus()
    self:SetFocus(true)
end

function ZO_BackgroundFragment:ClearFocus()
    self:SetFocus(false)
end

function ZO_BackgroundFragment:SetFocus(focused)
    self.control.background:SetTexture(focused and self.control.focusTexture or self.control.unfocusTexture)
end

function ZO_BackgroundFragment:ClearHighlight()
    self:SetHighlightHidden(true)
end

function ZO_BackgroundFragment:SetHighlightHidden(hidden)
    self.control.highlight:SetHidden(hidden)
end

function ZO_BackgroundFragment:FadeRightDivider(fadeIn, instant)
    local anim = nil

    if(fadeIn and self.control.rightDividerFadeInAnimation ~= nil) then
        anim = self.control.rightDividerFadeInAnimation
    elseif(not fadeIn and self.control.rightDividerFadeOutAnimation ~= nil) then
        anim = self.control.rightDividerFadeOutAnimation
    end

    if(anim ~= nil) then
        if(instant) then
            anim:PlayInstantlyToEnd()
        else
            anim:PlayFromStart()
        end
    end
end

-------------------------
--Action Layer Fragment
-------------------------

ZO_ActionLayerFragment = ZO_SceneFragment:Subclass()

function ZO_ActionLayerFragment:New(...)
    return ZO_SceneFragment.New(self, ...)
end

function ZO_ActionLayerFragment:Initialize(actionLayerName)
    ZO_SceneFragment.Initialize(self)
    self.actionLayerName = actionLayerName

    --ZO_ActionLayerFragments should always refresh so that in the case where a new scene
    --is shown with a different combination of layers, the intended stack order for the layers
    --won't be broken by leaving the previous ones pushed.
    self:SetForceRefresh(true)
end

function ZO_ActionLayerFragment:Show()
    PushActionLayerByName(self.actionLayerName)
    self:OnShown()
end

function ZO_ActionLayerFragment:Hide()
    RemoveActionLayerByName(self.actionLayerName)
    self:OnHidden()
end