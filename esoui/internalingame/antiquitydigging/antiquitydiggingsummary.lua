local ACCEPT = true
local REJECT = false

-- Style Constants

local FRAME_BORDER_PADDING_KEYBOARD = 4
local FRAME_BORDER_PADDING_GAMEPAD = 8

ZO_FRAMED_ANTIQUITY_FRAME_DIMENSIONS_KEYBOARD = 64
ZO_FRAMED_ANTIQUITY_ICON_DIMENSIONS_KEYBOARD = ZO_FRAMED_ANTIQUITY_FRAME_DIMENSIONS_KEYBOARD - FRAME_BORDER_PADDING_KEYBOARD
ZO_FRAMED_ANTIQUITY_FRAME_DIMENSIONS_GAMEPAD = 64
ZO_FRAMED_ANTIQUITY_ICON_DIMENSIONS_GAMEPAD = ZO_FRAMED_ANTIQUITY_FRAME_DIMENSIONS_GAMEPAD - FRAME_BORDER_PADDING_GAMEPAD

ZO_SET_COMPLETE_FRAMED_ANTIQUITY_FRAME_DIMENSIONS_KEYBOARD = 100
ZO_SET_COMPLETE_FRAMED_ANTIQUITY_ICON_DIMENSIONS_KEYBOARD = ZO_SET_COMPLETE_FRAMED_ANTIQUITY_FRAME_DIMENSIONS_KEYBOARD - FRAME_BORDER_PADDING_KEYBOARD
ZO_SET_COMPLETE_FRAMED_ANTIQUITY_FRAME_DIMENSIONS_GAMEPAD = 100
ZO_SET_COMPLETE_FRAMED_ANTIQUITY_ICON_DIMENSIONS_GAMEPAD = ZO_SET_COMPLETE_FRAMED_ANTIQUITY_FRAME_DIMENSIONS_GAMEPAD - FRAME_BORDER_PADDING_GAMEPAD

-- Timeline Constants

ZO_ANTIQUITY_DIGGING_FANFARE_OUT_DELAY = 30
ZO_ANTIQUITY_DIGGING_FANFARE_OUT_DURATION = 40

local SET_PROGRESSION_FRAMED_ICON_DELAY_MODIFIER_MS = 35
ZO_PROGRESSION_FRAMED_ICON_FADE_DURATION_MS = 300
ZO_PROGRESSION_FRAMED_ICON_SCALE_DURATION_MS = 100

ZO_END_OF_GAME_FANFARE_TRIGGER_COMMANDS =
{
    BEGIN = "Begin",
    NEXT = "Next",
    ANIMATION_COMPLETE = "AnimationComplete",
    PARTIAL_ANIMATION_COMPLETE = "PartialAnimationComplete", -- For use in the animation event count trigger where we expect more than one call before we count all animations as complete and move on
}

ZO_AntiquityDiggingSummary = ZO_Object:Subclass()

function ZO_AntiquityDiggingSummary:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_AntiquityDiggingSummary:Initialize(control)
    self.control = control

    ANTIQUITY_DIGGING_SUMMARY_FRAGMENT = ZO_SimpleSceneFragment:New(self.control)
    ANTIQUITY_DIGGING_SUMMARY_FRAGMENT:SetHideOnSceneHidden(true)
    ANTIQUITY_DIGGING_SUMMARY_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_HIDDEN then
            self.fanfareStateMachine:SetCurrentState("INACTIVE")
        end
    end)

    control:RegisterForEvent(EVENT_REQUEST_ANTIQUITY_DIGGING_EXIT, function()
        if ANTIQUITY_DIGGING_SUMMARY_FRAGMENT:IsShowing() then
            AntiquityDiggingExitResponse(ACCEPT)
        end
    end)

    control:RegisterForEvent(EVENT_STOP_ANTIQUITY_DIGGING, function()
        if ANTIQUITY_DIGGING_SCENE:IsShowing() then
            self.fanfareStateMachine:SetCurrentState("QUIT")
        end
    end)

    self:InitializeControls()
    self:InitializeStateMachine()

    ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end)
end

function ZO_AntiquityDiggingSummary:InitializeControls()
    self.modalUnderlay = self.control:GetNamedChild("ModalUnderlay")
    self.modalUnderlayTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityDiggingModalUnderlayFade", self.modalUnderlay)

    -- Control style tamplating
    local function MarkStyleDirty(control)
        control.isStyleDirty = true
        if not control:IsHidden() then
            control:CleanStyle()
        end
    end

    local function CleanStyle(control)
        if control.isStyleDirty then
            ApplyTemplateToControl(control, ZO_GetPlatformTemplate(control.styleTemplateBase))
            control.isStyleDirty = false
        end
    end

    local function SetupControlStyleTemplating(control, styleTemplateBase)
        control.MarkStyleDirty = MarkStyleDirty
        control.CleanStyle = CleanStyle
        control.styleTemplateBase = styleTemplateBase
        control.isStyleDirty = true -- When first created they won't have the platform style applied yet
    end

    --Keybind
    local descriptor =
    {
        keybind = "ANTIQUITY_DIGGING_PRIMARY_ACTION",
        callback = function()
            self:HandleCommand(ZO_END_OF_GAME_FANFARE_TRIGGER_COMMANDS.NEXT)
        end,
    }
    self.keybindButton = self.control:GetNamedChild("KeybindButton")
    self.keybindButton:SetKeybindButtonDescriptor(descriptor)
    self.keybindTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityDiggingSummaryKeybindFade", self.keybindButton)

    -- Failure
    self.failureControl = self.control:GetNamedChild("Failure")
    self.failureReasonBodyLabel = self.failureControl:GetNamedChild("Reason"):GetNamedChild("Body")
    self.failureTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityDiggingFailureFade", self.failureControl)

    -- Rewards
    self.rewardsControl = self.control:GetNamedChild("Rewards")
    self.rewardsOutTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityDiggingRewardsOutTimeline", self.rewardsControl)
    -- SetSkipAnimationsBehindPlayheadOnInitialPlay is needed because the animations have delays.
    -- Without this, when playing the animation directly to start, it won't set the various states because the position is technically beyond the playhead
    self.rewardsOutTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)

    -- Antiquity Reward
    self.antiquityRewardControl = self.rewardsControl:GetNamedChild("Antiquity")
    self.rewardAntiquityHeaderLabelRevealer = self.antiquityRewardControl:GetNamedChild("Header")
    local antiquityRewardContainerControl = self.antiquityRewardControl:GetNamedChild("Container")
    self.rewardAntiquityNameLabelRevealer = antiquityRewardContainerControl:GetNamedChild("Name")
    self.rewardAntiquityIconTexture = antiquityRewardContainerControl:GetNamedChild("FrameIcon")
    self.antiquityRewardTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityDiggingAntiquityRewardInTimeline", self.antiquityRewardControl)
    self.antiquityRewardTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)
    self.rewardAntiquityHeaderLabelRevealer:SetSizeAnimation(self.antiquityRewardTimeline:GetAnimation(2))
    self.rewardAntiquityNameLabelRevealer:SetSizeAnimation(self.antiquityRewardTimeline:GetAnimation(8))

    -- New Lead
    self.newLeadControl = self.rewardsControl:GetNamedChild("NewLead")
    local newLeadItemControl = self.newLeadControl:GetNamedChild("Item")
    self.newLeadIconTexture = newLeadItemControl:GetNamedChild("Icon")
    self.newLeadIconTexture:SetTexture(GetAntiquityLeadIcon()) -- Never changes, global def defined
    self.newLeadNameLabel = newLeadItemControl:GetNamedChild("Name")
    self.newLeadTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityDiggingRewardNewLeadFade", self.newLeadControl)
    self.newLeadTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)

    -- Bonus Loot
    self.bonusRewardsControl = self.rewardsControl:GetNamedChild("Bonus")
    self.bonusRewardsHeaderLabel = self.bonusRewardsControl:GetNamedChild("Header")
    local bonusItemsContainer = self.bonusRewardsControl:GetNamedChild("Items")
    self.bonusesControlPool = ZO_ControlPool:New("ZO_AntiquityDiggingRewardItem_Control", bonusItemsContainer)
    self.bonusesControlPool:SetCustomFactoryBehavior(function(control)
        control.iconTexture = control:GetNamedChild("Icon")
        control.stackCountLabel = control.iconTexture:GetNamedChild("StackCount")
        control.nameLabel = control:GetNamedChild("Name")

        SetupControlStyleTemplating(control, "ZO_AntiquityDiggingRewardItem_Control")
    end)

    self.bonusesControlPool:SetCustomAcquireBehavior(function(control)
        control:CleanStyle()
    end)
    
    self.bonusRewardsNoLootFoundLabel = bonusItemsContainer:GetNamedChild("NoLootFound")
    self.bonusRewardsTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityDiggingRewardBonusesFade", self.bonusRewardsControl)
    self.bonusRewardsTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)

    -- Lore
    self.loreControl = self.control:GetNamedChild("Lore")
    self.loreHeaderLabel = self.loreControl:GetNamedChild("Header")
    self.loreTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityDiggingLoreFade", self.loreControl)

    -- Set Progression
    self.setProgressionControl = self.control:GetNamedChild("SetProgression")
    self.setProgressionHeaderLabel = self.setProgressionControl:GetNamedChild("Header")
    self.setProgressionEntriesContainer = self.setProgressionControl:GetNamedChild("Entries")
    self.setProgressionTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityDiggingSetProgressionFade", self.setProgressionControl)

    local function SetAntiquityIconDisplayBehavior(control, desaturateControl, showSilhouette)
        local desaturation = desaturateControl and 1 or 0
        local rgbSampleProcessingWeight = showSilhouette and 0.7 or 1.0
        local alphaAsRGBSampleProcessingWeight = showSilhouette and 0.3 or 0.0

        control.iconTexture:SetDesaturation(desaturation)
        control.frameTexture:SetDesaturation(desaturation)
        control.bgTexture:SetDesaturation(desaturation)
        control.iconTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, rgbSampleProcessingWeight)
        control.iconTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_ALPHA_AS_RGB, alphaAsRGBSampleProcessingWeight)
    end

    local function OnCompleteFireTrigger(_, completedPlaying)
        if completedPlaying then
            ANTIQUITY_DIGGING_SUMMARY:HandleCommand(ZO_END_OF_GAME_FANFARE_TRIGGER_COMMANDS.PARTIAL_ANIMATION_COMPLETE)
        end
    end

    self.setProgressionAntiquityIconPool = ZO_ControlPool:New("ZO_AntiquityDigging_FramedAntiquityIcon", self.setProgressionEntriesContainer, "AntiquityIcon")
    self.setProgressionAntiquityIconPool:SetCustomFactoryBehavior(function(control)
        control.iconTexture = control:GetNamedChild("Icon")
        control.frameTexture = control:GetNamedChild("Frame")
        control.bgTexture = control.frameTexture:GetNamedChild("BG")
        control.fadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityDiggingFramedAntiquityIconFade", control)
        control.fadeTimeline:SetHandler("OnStop", function(_, completedPlaying)
            OnCompleteFireTrigger(_, completedPlaying)
            if completedPlaying then
                PlaySound(SOUNDS.ANTIQUITIES_FANFARE_FRAGMENT_RUNDOWN_ICONS)
            end
        end)

        SetupControlStyleTemplating(control, "ZO_AntiquityDigging_FramedAntiquityIcon")
        control.SetDisplayBehavior = SetAntiquityIconDisplayBehavior
    end)

    local IGNORE_ANIMATION_CALLBACKS = true
    self.setProgressionAntiquityIconPool:SetCustomAcquireBehavior(function(control)
        control:CleanStyle()
        control.fadeTimeline:SetAllAnimationOffsets(0)
        control.fadeTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
    end)
    
    -- Control will be set when we know which one is the relevant one
    self.setProgressionAntiquityIconScaleTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityDiggingFramedAntiquityIconScale")
    self.setProgressionAntiquityIconScaleTimeline:SetHandler("OnStop", function(timeline, completedPlaying)
        if completedPlaying then
            -- 1. The control started out regular size and unfulfilled, then it started growing
            if timeline:IsPlayingBackward() then
                -- 4. Done shrinking, ready to move on
                OnCompleteFireTrigger(timeline, completedPlaying)
            else
                -- 2. After fully growing, mark fulfilled
                local DONT_DESATURATE, DONT_SHOW_SILHOUETTE = false, false
                self.setProgressionControlForCurrentAntiquity:SetDisplayBehavior(DONT_DESATURATE, DONT_SHOW_SILHOUETTE)
                self.setProgressionSparksParticleSystem:Start()
                PlaySound(SOUNDS.ANTIQUITIES_FANFARE_FRAGMENT_DISCOVERED)
                if self.isAntiquitySetComplete then
                    self.setProgressionHeaderLabel:SetText(GetString(SI_ANTIQUITY_DIGGING_ALL_SET_ANTIQUITIES_FOUND))
                    PlaySound(SOUNDS.ANTIQUITIES_FANFARE_FRAGMENTS_FOUND_ALL)
                end
                -- 3. Then start shrinking back to normal
                timeline:PlayFromEnd()
            end
        end
    end)

    -- Set Complete
    self.setCompleteControl = self.control:GetNamedChild("SetComplete")
    self.setCompleteBannerTexture = self.setCompleteControl:GetNamedChild("Banner")
    self.setCompleteFramedAntiquityControl = self.setCompleteControl:GetNamedChild("FramedAntiquity")
    self.setCompleteFramedAntiquityIconTexture = self.setCompleteFramedAntiquityControl:GetNamedChild("Icon")
    self.setCompleteTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AntiquityDiggingSetCompleteFade", self.setCompleteControl)

    self:InitializeParticleSystems()
end

function ZO_AntiquityDiggingSummary:InitializeParticleSystems()
    local particleR, particleG, particleB = ZO_OFF_WHITE:UnpackRGB()
    local FULL_CIRCLE_RADIANS = math.rad(360)

    local setProgressionSparksParticleSystem = ZO_ControlParticleSystem:New(ZO_AnalyticalPhysicsParticle_Control)
    setProgressionSparksParticleSystem:SetParticlesPerSecond(15)
    setProgressionSparksParticleSystem:SetStartPrimeS(0.5)
    setProgressionSparksParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/ember.dds")
    setProgressionSparksParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    setProgressionSparksParticleSystem:SetParticleParameter("StartAlpha", 1)
    setProgressionSparksParticleSystem:SetParticleParameter("EndAlpha", 0)
    setProgressionSparksParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(1, 1.5))
    setProgressionSparksParticleSystem:SetParticleParameter("PhysicsInitialVelocityElevationRadians", ZO_UniformRangeGenerator:New(0, FULL_CIRCLE_RADIANS))
    setProgressionSparksParticleSystem:SetParticleParameter("StartColorR", particleR)
    setProgressionSparksParticleSystem:SetParticleParameter("StartColorG", particleG)
    setProgressionSparksParticleSystem:SetParticleParameter("StartColorB", particleB)
    setProgressionSparksParticleSystem:SetParticleParameter("PhysicsInitialVelocityMagnitude", ZO_UniformRangeGenerator:New(15, 60))
    setProgressionSparksParticleSystem:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(5, 10))
    setProgressionSparksParticleSystem:SetParticleParameter("DrawLevel", 4)
    self.setProgressionSparksParticleSystem = setProgressionSparksParticleSystem

    local setCompleteBlastParticleSystem = ZO_ControlParticleSystem:New(ZO_NumericalPhysicsParticle_Control)
    setCompleteBlastParticleSystem:SetParentControl(self.setCompleteBannerTexture)
    setCompleteBlastParticleSystem:SetParticlesPerSecond(500)
    setCompleteBlastParticleSystem:SetDuration(0.2)
    setCompleteBlastParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/ember.dds")
    setCompleteBlastParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    setCompleteBlastParticleSystem:SetParticleParameter("StartAlpha", 1)
    setCompleteBlastParticleSystem:SetParticleParameter("EndAlpha", 0)
    setCompleteBlastParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(1.5, 2.5))
    setCompleteBlastParticleSystem:SetParticleParameter("PhysicsInitialVelocityElevationRadians", ZO_UniformRangeGenerator:New(0, FULL_CIRCLE_RADIANS))
    setCompleteBlastParticleSystem:SetParticleParameter("PhysicsAccelerationElevationRadians1", math.rad(270)) --Down; Right is 0
    setCompleteBlastParticleSystem:SetParticleParameter("PhysicsAccelerationMagnitude1", 200)
    setCompleteBlastParticleSystem:SetParticleParameter("StartColorR", particleR)
    setCompleteBlastParticleSystem:SetParticleParameter("StartColorG", particleG)
    setCompleteBlastParticleSystem:SetParticleParameter("StartColorB", particleB)
    setCompleteBlastParticleSystem:SetParticleParameter("PhysicsInitialVelocityMagnitude", ZO_UniformRangeGenerator:New(500, 900))
    setCompleteBlastParticleSystem:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(6, 12))
    setCompleteBlastParticleSystem:SetParticleParameter("PhysicsDragMultiplier", 1.5)
    setCompleteBlastParticleSystem:SetParticleParameter("PrimeS", 0.1)
    setCompleteBlastParticleSystem:SetParticleParameter("DrawLevel", 0)
    self.setCompleteBlastParticleSystem = setCompleteBlastParticleSystem

    local setCompleteSparksParticleSystem = ZO_ControlParticleSystem:New(ZO_AnalyticalPhysicsParticle_Control)
    setCompleteSparksParticleSystem:SetParentControl(self.setCompleteFramedAntiquityControl)
    setCompleteSparksParticleSystem:SetParticlesPerSecond(20)
    setCompleteSparksParticleSystem:SetStartPrimeS(0.5)
    setCompleteSparksParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/ember.dds")
    setCompleteSparksParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    setCompleteSparksParticleSystem:SetParticleParameter("StartAlpha", 1)
    setCompleteSparksParticleSystem:SetParticleParameter("EndAlpha", 0)
    setCompleteSparksParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(1.5, 2.0))
    setCompleteSparksParticleSystem:SetParticleParameter("PhysicsInitialVelocityElevationRadians", ZO_UniformRangeGenerator:New(0, FULL_CIRCLE_RADIANS))
    setCompleteSparksParticleSystem:SetParticleParameter("StartColorR", particleR)
    setCompleteSparksParticleSystem:SetParticleParameter("StartColorG", particleG)
    setCompleteSparksParticleSystem:SetParticleParameter("StartColorB", particleB)
    setCompleteSparksParticleSystem:SetParticleParameter("PhysicsInitialVelocityMagnitude", ZO_UniformRangeGenerator:New(15, 60))
    setCompleteSparksParticleSystem:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(5, 10))
    setCompleteSparksParticleSystem:SetParticleParameter("DrawLevel", 4)
    self.setCompleteSparksParticleSystem = setCompleteSparksParticleSystem

    local setCompleteStarbustParticleSystem = ZO_ControlParticleSystem:New(ZO_StationaryParticle_Control)
    setCompleteStarbustParticleSystem:SetParentControl(self.setCompleteFramedAntiquityControl)
    setCompleteStarbustParticleSystem:SetParticlesPerSecond(20)
    setCompleteStarbustParticleSystem:SetStartPrimeS(2)
    setCompleteStarbustParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/Miscellaneous/lensflare_star_256.dds")
    setCompleteStarbustParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    setCompleteStarbustParticleSystem:SetParticleParameter("StartAlpha", 0)
    setCompleteStarbustParticleSystem:SetParticleParameter("EndAlpha", 1)
    setCompleteStarbustParticleSystem:SetParticleParameter("AlphaEasing", ZO_EaseInOutZeroToOneToZero)
    setCompleteStarbustParticleSystem:SetParticleParameter("StartScale", ZO_UniformRangeGenerator:New(1.5, 1.8))
    setCompleteStarbustParticleSystem:SetParticleParameter("EndScale", ZO_UniformRangeGenerator:New(1.05, 1.5))
    setCompleteStarbustParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(1, 2))
    setCompleteStarbustParticleSystem:SetParticleParameter("StartColorR", particleR)
    setCompleteStarbustParticleSystem:SetParticleParameter("StartColorG", particleG)
    setCompleteStarbustParticleSystem:SetParticleParameter("StartColorB", particleB)
    setCompleteStarbustParticleSystem:SetParticleParameter("StartRotationRadians", ZO_UniformRangeGenerator:New(0, FULL_CIRCLE_RADIANS))
    local MIN_ROTATION_SPEED = math.rad(1.5)
    local MAX_ROTATION_SPEED = math.rad(3)
    local headerStarbustRotationSpeedGenerator = ZO_WeightedChoiceGenerator:New(
        MIN_ROTATION_SPEED , 0.25,
        MAX_ROTATION_SPEED , 0.25,
        -MIN_ROTATION_SPEED, 0.25,
        -MAX_ROTATION_SPEED, 0.25)

    setCompleteStarbustParticleSystem:SetParticleParameter("RotationSpeedRadians", headerStarbustRotationSpeedGenerator)
    setCompleteStarbustParticleSystem:SetParticleParameter("Size", 256)
    setCompleteStarbustParticleSystem:SetParticleParameter("DrawLevel", 0)

    self.setCompleteStarbustParticleSystem = setCompleteStarbustParticleSystem
end

function ZO_AntiquityDiggingSummary:SetKeybindButtonText(text)
    self.keybindButtonText = text
    self.keybindButton:SetText(text)
end

function ZO_AntiquityDiggingSummary:InitializeStateMachine()
    local fanfareStateMachine = ZO_StateMachine_Base:New("ANTIQUITY_DIGGING_FANFARE_STATE_MACHINE")
    self.fanfareStateMachine = fanfareStateMachine
    local IGNORE_ANIMATION_CALLBACKS = true

    --[[ States --
        00 - INACTIVE
        02 - BEGIN
        04 - ANTIQUITY_REWARD_IN
        05 - NEW_LEAD_IN
        06 - BONUS_REWARDS_IN
        08 - REWARDS
        10 - REWARDS_OUT
        12 - LORE_IN
        14 - LORE
        16 - LORE_OUT
        18 - SET_PROGRESSION_IN
        20 - SET_PROGRESSION
        22 - SET_PROGRESSION_OUT
        24 - SET_COMPLETE_IN
        26 - SET_COMPLETE
        50 - FAILURE_IN
        99 - QUIT
    ]]--

    do
        local state = fanfareStateMachine:AddState("INACTIVE")
        state:RegisterCallback("OnActivated", function()
            self.modalUnderlayTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.failureTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.antiquityRewardTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.newLeadTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.bonusRewardsTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.loreTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.setProgressionTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.setCompleteTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.setProgressionAntiquityIconScaleTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.keybindTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.failureControl:SetHidden(true)
            self.antiquityRewardControl:SetHidden(true)
            self.newLeadControl:SetHidden(true)
            self.bonusRewardsControl:SetHidden(true)
            self.loreControl:SetHidden(true)
            self.setProgressionControl:SetHidden(true)
            self.setCompleteControl:SetHidden(true)
            self.bonusesControlPool:ReleaseAllObjects()
            self.setProgressionAntiquityIconPool:ReleaseAllObjects()
            self.setProgressionSparksParticleSystem:Stop()
            self.setCompleteBlastParticleSystem:Stop()
            self.setCompleteSparksParticleSystem:Stop()
            self.setCompleteStarbustParticleSystem:Stop()
            ANTIQUITY_LORE_DOCUMENT_MANAGER:ReleaseAllObjects(self.loreControl)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("BEGIN")
        state:RegisterCallback("OnActivated", function()
            -- This state primarily exists to allow the two possible paths (REWARD_IN/FAILURE_IN) to run their conditionals
            -- And to animate shared controls
            SCENE_MANAGER:AddFragment(UNIFORM_BLUR_FRAGMENT)
            self.modalUnderlayTimeline:PlayFromStart()
            self.keybindTimeline:PlayFromStart()
            fanfareStateMachine:FireCallbacks(ZO_END_OF_GAME_FANFARE_TRIGGER_COMMANDS.NEXT)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("ANTIQUITY_REWARD_IN")
        state:RegisterCallback("OnActivated", function()
            self:SetKeybindButtonText(GetString(SI_ANTIQUITY_DIGGING_FANFARE_NEXT))
            self.antiquityRewardControl:SetHidden(false)
            self.rewardsOutTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.antiquityRewardTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.antiquityRewardTimeline:PlayFromStart()
            PlaySound(SOUNDS.ANTIQUITIES_FANFARE_FRAGMENT_FOUND)
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.antiquityRewardTimeline:IsPlaying() then
                self.antiquityRewardTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

     do
        local state = fanfareStateMachine:AddState("NEW_LEAD_IN")
        state:RegisterCallback("OnActivated", function()
            self.newLeadControl:SetHidden(false)
            self.newLeadTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.newLeadTimeline:PlayFromStart()
        end)
    end

    do
        local state = fanfareStateMachine:AddState("BONUS_REWARDS_IN")
        state:RegisterCallback("OnActivated", function()
            self.bonusRewardsControl:SetHidden(false)
            self.bonusRewardsTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            self.bonusRewardsTimeline:PlayFromStart()
        end)
    end

    do
        local state = fanfareStateMachine:AddState("REWARDS")
        state:RegisterCallback("OnActivated", function()
            -- We may have gotten here via a skip, which means we may never have even made it into the interstitial states
            -- So just ensure these animations are where we want them to be by this point in the flow
            if self.hasNewLead then
                self.newLeadControl:SetHidden(false)
                self.newLeadTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            -- The bonus rewards section always shows even if there aren't any rewards
            self.bonusRewardsControl:SetHidden(false)
            self.bonusRewardsTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("REWARDS_OUT")
        state:RegisterCallback("OnActivated", function()
            self.rewardsOutTimeline:PlayFromStart()
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.rewardsOutTimeline:IsPlaying() then
                self.rewardsOutTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
            self.antiquityRewardControl:SetHidden(true)
            self.bonusRewardsControl:SetHidden(true)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("LORE_IN")
        state:RegisterCallback("OnActivated", function()
            self.loreControl:SetHidden(false)
            self.loreTimeline:PlayFromStart()
            PlaySound(SOUNDS.ANTIQUITIES_FANFARE_MOTIF_SCROLL_APPEAR)
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.loreTimeline:IsPlaying() then
                self.loreTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    fanfareStateMachine:AddState("LORE")

    do
        local state = fanfareStateMachine:AddState("LORE_OUT")
        state:RegisterCallback("OnActivated", function()
            self.loreTimeline:PlayBackward()
        end)

        state:RegisterCallback("OnDeactivated", function() 
            if self.loreTimeline:IsPlaying() then
                self.loreTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            end
            self.loreControl:SetHidden(true)
            ANTIQUITY_LORE_DOCUMENT_MANAGER:ReleaseAllObjects(self.loreControl)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("SET_PROGRESSION_IN")
        state:RegisterCallback("OnActivated", function()
            -- This label can change later if the set is completed
            self.setProgressionHeaderLabel:SetText(GetString(SI_ANTIQUITY_DIGGING_SET_PROGRESSION))
            self.setProgressionControl:SetHidden(false)
            self.setProgressionTimeline:PlayFromStart()
            PlaySound(SOUNDS.ANTIQUITIES_FANFARE_FRAGMENT_PROGRESSION)
        end)

        state:RegisterCallback("OnDeactivated", function()
            local primaryAnimationIsPlaying = self.setProgressionTimeline:IsPlaying()
            if primaryAnimationIsPlaying then
                self.setProgressionTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end

            for _, activeIcon in self.setProgressionAntiquityIconPool:ActiveObjectIterator() do
                if primaryAnimationIsPlaying or activeIcon.fadeTimeline:IsPlaying() then
                    activeIcon.fadeTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
                end
            end
            if primaryAnimationIsPlaying or self.setProgressionAntiquityIconScaleTimeline:IsPlaying() then
                local DONT_DESATURATE, DONT_SHOW_SILHOUETTE = false, false
                self.setProgressionControlForCurrentAntiquity:SetDisplayBehavior(DONT_DESATURATE, DONT_SHOW_SILHOUETTE)
                self.setProgressionAntiquityIconScaleTimeline:SetAllAnimationOffsets(0)
                self.setProgressionAntiquityIconScaleTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
                self.setProgressionSparksParticleSystem:Start()
            end
        end)
    end

    fanfareStateMachine:AddState("SET_PROGRESSION")

    do
        local state = fanfareStateMachine:AddState("SET_PROGRESSION_OUT")
        state:RegisterCallback("OnActivated", function()
            self.setProgressionTimeline:PlayBackward()
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.setProgressionTimeline:IsPlaying() then
                self.setProgressionTimeline:PlayInstantlyToStart(IGNORE_ANIMATION_CALLBACKS)
            end
            self.setProgressionControl:SetHidden(true)
            self.setProgressionSparksParticleSystem:Stop()
        end)
    end

    do
        local state = fanfareStateMachine:AddState("SET_COMPLETE_IN")
        state:RegisterCallback("OnActivated", function()
            self.setCompleteControl:SetHidden(false)
            self.setCompleteTimeline:PlayFromStart()
            self.setCompleteBlastParticleSystem:Start()
            self.setCompleteSparksParticleSystem:Start()
            self.setCompleteStarbustParticleSystem:Start()
            PlaySound(SOUNDS.ANTIQUITIES_FANFARE_COMPLETED)
        end)

        state:RegisterCallback("OnDeactivated", function()
            if self.setCompleteTimeline:IsPlaying() then
                self.setCompleteTimeline:PlayInstantlyToEnd(IGNORE_ANIMATION_CALLBACKS)
            end
        end)
    end

    fanfareStateMachine:AddState("SET_COMPLETE")

    do
        local state = fanfareStateMachine:AddState("FAILURE_IN")
        state:RegisterCallback("OnActivated", function()
            self:SetKeybindButtonText(GetString(SI_EXIT_BUTTON))
            self.failureControl:SetHidden(false)
            self.failureTimeline:PlayFromStart()
            PlaySound(SOUNDS.ANTIQUITIES_FANFARE_FAILURE)
        end)
    end

    do
        local state = fanfareStateMachine:AddState("QUIT")
        state:RegisterCallback("OnActivated", function()
            SCENE_MANAGER:RequestShowLeaderBaseScene()
        end)
    end

    -- Edges --
    do
        fanfareStateMachine:AddEdgeAutoName("INACTIVE", "BEGIN") --0 -> 1
        local antiquityRewardInEdge = fanfareStateMachine:AddEdgeAutoName("BEGIN", "ANTIQUITY_REWARD_IN") --2 -> 4
        antiquityRewardInEdge:SetConditional(function()
            return self.gameOverFlags == ANTIQUITY_DIGGING_GAME_OVER_FLAGS_VICTORY
        end)
        local antiquityRewardToNewLeadInEdge = fanfareStateMachine:AddEdgeAutoName("ANTIQUITY_REWARD_IN", "NEW_LEAD_IN") --4 -> 5
        antiquityRewardToNewLeadInEdge:SetConditional(function()
            return self.hasNewLead
        end)
        local antiquityRewardToBonusRewardsInEdge = fanfareStateMachine:AddEdgeAutoName("ANTIQUITY_REWARD_IN", "BONUS_REWARDS_IN") --4 -> 6
        antiquityRewardToBonusRewardsInEdge:SetConditional(function()
            return not self.hasNewLead
        end)
        fanfareStateMachine:AddEdge("ANTIQUITY_REWARD_IN_TO_REWARDS_SKIP", "ANTIQUITY_REWARD_IN", "REWARDS") --4 -> 8
        fanfareStateMachine:AddEdgeAutoName("NEW_LEAD_IN", "BONUS_REWARDS_IN") --5 -> 6
        fanfareStateMachine:AddEdge("NEW_LEAD_IN_TO_REWARDS_SKIP", "NEW_LEAD_IN", "REWARDS") --5 -> 8
        fanfareStateMachine:AddEdgeAutoName("BONUS_REWARDS_IN", "REWARDS") --6 -> 8
        local rewardsOutEdge = fanfareStateMachine:AddEdgeAutoName("REWARDS", "REWARDS_OUT") --8 -> 10
        rewardsOutEdge:SetConditional(function()
            return self.showLore or self.hasAntiquitySet
        end)
        local rewardsOutToLoreEdge = fanfareStateMachine:AddEdgeAutoName("REWARDS_OUT", "LORE_IN") --10 -> 12
        rewardsOutToLoreEdge:SetConditional(function()
            return self.showLore
        end)
        local rewardsOutToSetCombinationEdge = fanfareStateMachine:AddEdgeAutoName("REWARDS_OUT", "SET_PROGRESSION_IN") --10 -> 18
        rewardsOutToSetCombinationEdge:SetConditional(function()
            return not self.showLore
        end)
        fanfareStateMachine:AddEdgeAutoName("LORE_IN", "LORE") --12 -> 14
        local loreOutEdge = fanfareStateMachine:AddEdgeAutoName("LORE", "LORE_OUT") --14 -> 16
        loreOutEdge:SetConditional(function()
            return self.hasAntiquitySet
        end)
        fanfareStateMachine:AddEdgeAutoName("LORE_OUT", "SET_PROGRESSION_IN") --16 -> 18
        fanfareStateMachine:AddEdgeAutoName("SET_PROGRESSION_IN", "SET_PROGRESSION") --18 -> 20
        local setProgressionOutEdge = fanfareStateMachine:AddEdgeAutoName("SET_PROGRESSION", "SET_PROGRESSION_OUT") --20 -> 22
        setProgressionOutEdge:SetConditional(function()
            return self.isAntiquitySetComplete
        end)
        fanfareStateMachine:AddEdgeAutoName("SET_PROGRESSION_OUT", "SET_COMPLETE_IN") --22 -> 24
        fanfareStateMachine:AddEdgeAutoName("SET_COMPLETE_IN", "SET_COMPLETE") --24 -> 26
        local setCompleteQuitEdge = fanfareStateMachine:AddEdgeAutoName("SET_COMPLETE", "QUIT") --26 -> 99
        setCompleteQuitEdge:RegisterCallback("OnActivated", function()
            self:SetKeybindButtonText(GetString(SI_EXIT_BUTTON))
        end)
        local failureInEdge = fanfareStateMachine:AddEdgeAutoName("BEGIN", "FAILURE_IN") --2 -> 50
        failureInEdge:SetConditional(function()
            return self.gameOverFlags ~= ANTIQUITY_DIGGING_GAME_OVER_FLAGS_VICTORY
        end)
        local rewardsQuitEdge = fanfareStateMachine:AddEdgeAutoName("REWARDS", "QUIT") --6 -> 99
        rewardsQuitEdge:SetConditional(function()
            return not (self.showLore or self.hasAntiquitySet)
        end)
        rewardsQuitEdge:RegisterCallback("OnActivated", function()
            self:SetKeybindButtonText(GetString(SI_EXIT_BUTTON))
        end)
        local loreQuitEdge = fanfareStateMachine:AddEdgeAutoName("LORE", "QUIT") --12 -> 99
        loreQuitEdge:SetConditional(function()
            return not self.hasAntiquitySet
        end)
        loreQuitEdge:RegisterCallback("OnActivated", function()
            self:SetKeybindButtonText(GetString(SI_EXIT_BUTTON))
        end)
        local setProgressionQuitEdge = fanfareStateMachine:AddEdgeAutoName("SET_PROGRESSION", "QUIT") --20 -> 99
        setProgressionQuitEdge:SetConditional(function()
            return not self.isAntiquitySetComplete
        end)
        setProgressionQuitEdge:RegisterCallback("OnActivated", function()
            self:SetKeybindButtonText(GetString(SI_EXIT_BUTTON))
        end)
        -- If the player skips the failure at any point, just let them quit
        fanfareStateMachine:AddEdgeAutoName("FAILURE_IN", "QUIT") --50 -> 99
    end

    -- Triggers --
    fanfareStateMachine:AddTrigger("BEGIN", ZO_StateMachine_TriggerStateCallback, ZO_END_OF_GAME_FANFARE_TRIGGER_COMMANDS.BEGIN)
    fanfareStateMachine:AddTrigger("NEXT", ZO_StateMachine_TriggerStateCallback, ZO_END_OF_GAME_FANFARE_TRIGGER_COMMANDS.NEXT)
    fanfareStateMachine:AddTrigger("ANIMATION_COMPLETE", ZO_StateMachine_TriggerStateCallback, ZO_END_OF_GAME_FANFARE_TRIGGER_COMMANDS.ANIMATION_COMPLETE)
    do
        local trigger = fanfareStateMachine:AddTrigger("SET_PROGRESSION_ANIMATIONS_COMPLETE", ZO_StateMachine_TriggerStateCallback, ZO_END_OF_GAME_FANFARE_TRIGGER_COMMANDS.PARTIAL_ANIMATION_COMPLETE)
        trigger:SetEventCount(function()
            local antiquityId = GetDigSpotAntiquityId()
            local antiquitySetId = GetAntiquitySetId(antiquityId)
            local numFadeAnimations = GetNumAntiquitySetAntiquities(antiquitySetId)
            local NUM_SCALE_ANIMATIONS = 1

            return numFadeAnimations + NUM_SCALE_ANIMATIONS
        end)
    end

    -- Add triggers to edges --
    fanfareStateMachine:AddTriggerToEdge("BEGIN", "INACTIVE_TO_BEGIN")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "ANTIQUITY_REWARD_IN_TO_NEW_LEAD_IN")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "ANTIQUITY_REWARD_IN_TO_BONUS_REWARDS_IN")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "NEW_LEAD_IN_TO_BONUS_REWARDS_IN")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "BONUS_REWARDS_IN_TO_REWARDS")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "REWARDS_OUT_TO_LORE_IN")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "REWARDS_OUT_TO_SET_PROGRESSION_IN")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "LORE_IN_TO_LORE")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "LORE_OUT_TO_SET_PROGRESSION_IN")
    fanfareStateMachine:AddTriggerToEdge("SET_PROGRESSION_ANIMATIONS_COMPLETE", "SET_PROGRESSION_IN_TO_SET_PROGRESSION")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "SET_PROGRESSION_OUT_TO_SET_COMPLETE_IN")
    fanfareStateMachine:AddTriggerToEdge("ANIMATION_COMPLETE", "SET_COMPLETE_IN_TO_SET_COMPLETE")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "BEGIN_TO_ANTIQUITY_REWARD_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "ANTIQUITY_REWARD_IN_TO_REWARDS_SKIP")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "NEW_LEAD_IN_TO_REWARDS_SKIP")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "BONUS_REWARDS_IN_TO_REWARDS")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "REWARDS_TO_REWARDS_OUT")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "REWARDS_OUT_TO_LORE_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "REWARDS_OUT_TO_SET_PROGRESSION_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "LORE_IN_TO_LORE")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "LORE_TO_LORE_OUT")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "LORE_OUT_TO_SET_PROGRESSION_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "SET_PROGRESSION_IN_TO_SET_PROGRESSION")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "SET_PROGRESSION_TO_SET_PROGRESSION_OUT")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "SET_PROGRESSION_OUT_TO_SET_COMPLETE_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "SET_COMPLETE_IN_TO_SET_COMPLETE")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "BEGIN_TO_FAILURE_IN")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "REWARDS_TO_QUIT")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "LORE_TO_QUIT")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "SET_PROGRESSION_TO_QUIT")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "SET_COMPLETE_TO_QUIT")
    fanfareStateMachine:AddTriggerToEdge("NEXT", "FAILURE_IN_TO_QUIT")

    -- Animation callbacks --
    local function OnCompleteFireTrigger(_, completedPlaying)
        if completedPlaying then
            fanfareStateMachine:FireCallbacks(ZO_END_OF_GAME_FANFARE_TRIGGER_COMMANDS.ANIMATION_COMPLETE)
        end
    end

    self.antiquityRewardTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.newLeadTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.bonusRewardsTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.rewardsOutTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.loreTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    self.setProgressionTimeline:SetHandler("OnStop", function(timeline, completedPlaying)
        if timeline:IsPlayingBackward() then
            OnCompleteFireTrigger(timeline, completedPlaying)
        else
            for _, activeIcon in self.setProgressionAntiquityIconPool:ActiveObjectIterator() do
                activeIcon.fadeTimeline:PlayFromStart()
            end
            self.setProgressionAntiquityIconScaleTimeline:PlayFromStart()
        end
    end)
    self.setCompleteTimeline:SetHandler("OnStop", OnCompleteFireTrigger)
    -- Reset state machine
    self.fanfareStateMachine:SetCurrentState("INACTIVE")
end

function ZO_AntiquityDiggingSummary:ApplyPlatformStyle()
    ApplyTemplateToControl(self.failureControl, ZO_GetPlatformTemplate("ZO_AntiquityDiggingSummary_Failure"))
    ApplyTemplateToControl(self.antiquityRewardControl, ZO_GetPlatformTemplate("ZO_AntiquityDiggingSummary_AntiquityReward"))
    ApplyTemplateToControl(self.newLeadControl, ZO_GetPlatformTemplate("ZO_AntiquityDiggingSummary_NewLead"))
    ApplyTemplateToControl(self.bonusRewardsControl, ZO_GetPlatformTemplate("ZO_AntiquityDiggingSummary_BonusRewards"))
    ApplyTemplateToControl(self.loreControl, ZO_GetPlatformTemplate("ZO_AntiquityDiggingSummary_Lore"))
    if not self.loreControl:IsHidden() then
        ANTIQUITY_LORE_DOCUMENT_MANAGER:ReleaseAllObjects(self.loreControl)
        self:AcquireAndLayoutLoreDocumentControl()
    end
    ApplyTemplateToControl(self.setProgressionControl, ZO_GetPlatformTemplate("ZO_AntiquityDiggingSummary_SetProgression"))
    ApplyTemplateToControl(self.setCompleteControl, ZO_GetPlatformTemplate("ZO_AntiquityDiggingSummary_SetComplete"))

    for _, control in self.bonusesControlPool:ActiveAndFreeObjectIterator() do
        control:MarkStyleDirty()
    end

    for _, control in self.setProgressionAntiquityIconPool:ActiveAndFreeObjectIterator() do
        control:MarkStyleDirty()
    end

    ApplyTemplateToControl(self.keybindButton, ZO_GetPlatformTemplate("ZO_KeybindButton"))
    -- Reset the text here to handle the force uppercase on gamepad
    self.keybindButton:SetText(self.keybindButtonText)
end

function ZO_AntiquityDiggingSummary:BeginEndOfGameFanfare(gameOverFlags)
    SCENE_MANAGER:AddFragment(ANTIQUITY_DIGGING_SUMMARY_FRAGMENT)

    self.gameOverFlags = gameOverFlags

    if gameOverFlags ~= ANTIQUITY_DIGGING_GAME_OVER_FLAGS_VICTORY then
        self.failureReasonBodyLabel:SetText(GetString("SI_DIGGINGGAMEOVERFLAGS", gameOverFlags))
        self.fanfareStateMachine:FireCallbacks(ZO_END_OF_GAME_FANFARE_TRIGGER_COMMANDS.BEGIN)
        return
    end

    local antiquityId = GetDigSpotAntiquityId()
    local antiquitySetId = GetAntiquitySetId(antiquityId)
    self.hasAntiquitySet = antiquitySetId ~= 0

    -- Antiquity Reward
    local antiquityName = GetAntiquityName(antiquityId)
    local antiquityQuality = GetAntiquityQuality(antiquityId)
    local qualityColorDef = GetAntiquityQualityColor(antiquityQuality)
    self.rewardAntiquityIconTexture:SetTexture(GetAntiquityIcon(antiquityId))
    self.rewardAntiquityNameLabelRevealer:SetText(qualityColorDef:Colorize(antiquityName))

    -- New Lead
    local newLeadAntiquityId = GetDigSpotNewLeadRewardAntiquityId()
    self.hasNewLead = newLeadAntiquityId ~= 0
    if self.hasNewLead then
        local antiquityLeadName = zo_strformat(SI_ANTIQUITY_LEAD_NAME_FORMATTER, GetAntiquityName(newLeadAntiquityId))
        local antiquityLeadQuality = GetAntiquityQuality(newLeadAntiquityId)
        local antiquityLeadQualityColorDef = GetAntiquityQualityColor(antiquityLeadQuality)
        self.newLeadNameLabel:SetText(antiquityLeadQualityColorDef:Colorize(antiquityLeadName))
        self.bonusRewardsHeaderLabel:SetAnchor(TOP, self.bonusRewardsControl, CENTER, 0, 70)
        self.hasNewLead = true
    else
        self.bonusRewardsHeaderLabel:SetAnchor(TOP, self.bonusRewardsControl, CENTER, 0, -70)
        self.hasNewLead = false
    end

    -- Bonus Rewards
    local numBonusLootRewards = GetNumDigSpotBonusLootRewards()
    local previousLeftControl = nil
    local previousRightControl = nil
    self.hasBonusRewards = numBonusLootRewards > 0
    for i = 1, numBonusLootRewards do
        local control = self.bonusesControlPool:AcquireObject(i)
        local lootType, id, name, icon, count, quality = GetDigSpotBonusLootRewardInfo(i)
        local qualityColorDef = nil
        local countText = ""
        if lootType == LOOT_TABLE_ENTRY_TYPE_CURRENCY then
            name = ZO_Currency_GetAmountLabel(id)
            icon = ZO_Currency_GetPlatformCurrencyIcon(id)
            local USE_SHORT_FORMAT = true
            countText = ZO_CurrencyControl_FormatCurrency(count, USE_SHORT_FORMAT)
        elseif lootType == LOOT_TABLE_ENTRY_TYPE_ITEM then
            qualityColorDef = GetItemQualityColor(quality)
            countText = tostring(count)
        elseif lootType == LOOT_TABLE_ENTRY_TYPE_ANTIQUITY_LEAD then
            qualityColorDef = GetAntiquityQualityColor(quality)
        end

        if qualityColorDef then
            name = qualityColorDef:Colorize(name)
        end

        control.nameLabel:SetText(name)
        control.iconTexture:SetTexture(icon)
        control.stackCountLabel:SetText(countText)

        -- TODO: Expecting some iteration on the rules of layout here
        if i % 2 == 0 then
            if previousRightControl then
                control:SetAnchor(TOPLEFT, previousRightControl, BOTTOMLEFT, 0, 10)
            else
                control:SetAnchor(TOPLEFT, nil, TOP, 20, 15)
            end
            previousRightControl = control
        else
            if i == numBonusLootRewards then
                -- Last one is odd, center it
                if previousLeftControl then
                    control:SetAnchor(TOP, previousLeftControl, BOTTOMRIGHT, 20, 10)
                else
                    control:SetAnchor(TOP, nil, TOP, 0, 15)
                end
            else
                if previousLeftControl then
                    control:SetAnchor(TOPRIGHT, previousLeftControl, BOTTOMRIGHT, 0, 10)
                else
                    control:SetAnchor(TOPRIGHT, nil, TOP, -20, 15)
                end
                previousLeftControl = control
            end
        end
    end
    self.bonusRewardsNoLootFoundLabel:SetHidden(self.hasBonusRewards)

    -- Lore
    if GetDiggingAntiquityHasNewLoreEntryToShow() then
        self:AcquireAndLayoutLoreDocumentControl()
        self.showLore = true
    else
        self.showLore = false
    end
    
    -- Set Progression
    if self.hasAntiquitySet then
        local MAX_ICONS_PER_ROW = 8
        local numAntiquitiesInSet = GetNumAntiquitySetAntiquities(antiquitySetId)

        -- TODO: This logic will need to change when we implement the fancy translation animations
        local firstControlInRow = nil
        local previousControl = nil
        local isAntiquitySetComplete = DidDigSpotCompleteAntiquitySet()
        for i = 1, numAntiquitiesInSet do
            local control = self.setProgressionAntiquityIconPool:AcquireObject()

            local antiquityFragmentId = GetAntiquitySetAntiquityId(antiquitySetId, i)
            local isAntiquityFragmentDigSpotAntiquity = antiquityFragmentId == antiquityId
            local antiquityFragmentRecovered = GetNumAntiquitiesRecovered(antiquityFragmentId) > 0
            -- If the set is complete, the flag will have already been cleared before we hit this rewards fanfare, so treat it like it had been set.
            local antiquityFragmentNeedsCombination = DoesAntiquityNeedCombination(antiquityFragmentId) or isAntiquitySetComplete

            local antiquityFragmentDiscovered = isAntiquityFragmentDigSpotAntiquity or antiquityFragmentRecovered
            if not antiquityFragmentDiscovered then
                local requiresLead = DoesAntiquityRequireLead(antiquityFragmentId)
                local meetsLeadRequirement = not requiresLead or DoesAntiquityHaveLead(antiquityFragmentId)
                antiquityFragmentDiscovered = meetsLeadRequirement
            end

            -- TODO: Still need hidden antiquity icon
            local icon = antiquityFragmentDiscovered and GetAntiquityIcon(antiquityFragmentId) or "EsoUI/Art/Icons/U26_Unknown_Antiquity_QuestionMark.dds"
            local iconTexture = control.iconTexture
            iconTexture:SetTexture(icon)
            -- The just dug up antiquity will start incomplete and become complete through animations
            local desaturateControl = not antiquityFragmentNeedsCombination or isAntiquityFragmentDigSpotAntiquity
            local showSilhouette = (antiquityFragmentDiscovered and not antiquityFragmentNeedsCombination) or isAntiquityFragmentDigSpotAntiquity
            control:SetDisplayBehavior(desaturateControl, showSilhouette)
            if isAntiquityFragmentDigSpotAntiquity then
                self.setProgressionAntiquityIconScaleTimeline:ApplyAllAnimationsToControl(iconTexture)
                self.setProgressionControlForCurrentAntiquity = control
                self.setProgressionSparksParticleSystem:SetParentControl(control.frameTexture)
            end

            local delayMs = (i - 1) * SET_PROGRESSION_FRAMED_ICON_DELAY_MODIFIER_MS
            control.fadeTimeline:SetAllAnimationOffsets(delayMs)

            if i % MAX_ICONS_PER_ROW == 1 then
                if firstControlInRow then
                    control:SetAnchor(TOPLEFT, firstControlInRow, BOTTOMLEFT, 0, 5)
                else
                    control:SetAnchor(TOPLEFT)
                end
                firstControlInRow = control
            else
                control:SetAnchor(LEFT, previousControl, RIGHT, 5, 0)
            end
            previousControl = control
        end

        self.setProgressionAntiquityIconScaleTimeline:SetAllAnimationOffsets((numAntiquitiesInSet * SET_PROGRESSION_FRAMED_ICON_DELAY_MODIFIER_MS) + ZO_PROGRESSION_FRAMED_ICON_FADE_DURATION_MS)

        -- Set Complete
        self.isAntiquitySetComplete = isAntiquitySetComplete
        if isAntiquitySetComplete then
            local icon = GetAntiquitySetIcon(antiquitySetId)
            self.setCompleteFramedAntiquityIconTexture:SetTexture(icon)
        end
    end

    self.fanfareStateMachine:FireCallbacks(ZO_END_OF_GAME_FANFARE_TRIGGER_COMMANDS.BEGIN)
end

function ZO_AntiquityDiggingSummary:AcquireAndLayoutLoreDocumentControl()
    local loreDocumentControl = ANTIQUITY_LORE_DOCUMENT_MANAGER:AcquireWideDocumentForLoreEntry(self.loreControl, GetDigSpotAntiquityId(), GetNumAntiquityLoreEntriesAcquired(GetDigSpotAntiquityId()))
    loreDocumentControl:SetAnchor(TOP, self.loreHeaderLabel, BOTTOM, 0, 20)
end

function ZO_AntiquityDiggingSummary:HandleCommand(command)
    self.fanfareStateMachine:FireCallbacks(command)
end

-- Global / XML --

function ZO_AntiquityDiggingSummary_OnInitialized(control)
    ANTIQUITY_DIGGING_SUMMARY = ZO_AntiquityDiggingSummary:New(control)
end