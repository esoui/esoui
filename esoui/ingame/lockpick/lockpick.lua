local PARTIAL_PIN_ALPHA = 0.2
local FULL_PIN_ALPHA = 1

local NORMAL_TEXTURE = "EsoUI/Art/Lockpicking/pins.dds"
local SET_TEXTURE = "EsoUI/Art/Lockpicking/pins_set.dds"

ZO_Lockpick = ZO_InitializingObject:Subclass()

function ZO_Lockpick:Initialize(control)
    self.control = control
    control.owner = self
    self.body = control:GetNamedChild("Body")

    -- Keyboard specific controls
    self.infoBar = control:GetNamedChild("InfoBar")
    self.lockLevelLabel = self.infoBar:GetNamedChild("LockLevel")
    self.lockpicksLeftLabel = self.infoBar:GetNamedChild("LockpicksLeft")
    self.timer = ZO_MultiSegmentTimerBar:New(control:GetNamedChild("TimerBar"), "ZO_LockpickTimerBarStatus")
    self.timer:SetDirection(TIMER_BAR_COUNTS_DOWN)

    -- Gamepad specific controls
    self.gamepadInfoBar = control:GetNamedChild("GamepadInfoBar")
    self.gamepadLockLevelLabel = self.gamepadInfoBar:GetNamedChild("Difficulty")
    self.gamepadLockpicksLeftLabel = self.gamepadInfoBar:GetNamedChild("LockpicksRemaining")
    self.gamepadTimer = ZO_MultiSegmentTimerBar:New(control:GetNamedChild("GamepadTimerBar"), "ZO_LockpickTimerBarStatusGamepad")
    self.gamepadTimer:SetDirection(TIMER_BAR_COUNTS_DOWN)

    self.lockpick = control:GetNamedChild("Lockpick")

    self.lockpickBreakLeft = control:GetNamedChild("LockpickBreakLeft")
    self.lockpickBreakRight = control:GetNamedChild("LockpickBreakRight")

    self.defaultVibration = GetLockpickingDefaultGamepadVibration()

    self:CreateKeybindStripDescriptor()

    self.springs = {}

    for i = 1, NUM_LOCKPICK_CHAMBERS do
        local spring = control:GetNamedChild("Spring" .. i)
        spring.pin = control:GetNamedChild("Pin" .. i)
        spring.pin.highlight = spring.pin:GetNamedChild("Highlight")
        spring.pin.highlightAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("PinHighlightAnimation", spring.pin.highlight)
        spring.pin.chamberIndex = i
        spring.height = spring:GetHeight()

        spring.pin:SetAnchor(BOTTOM, spring, TOP, 0, 10)

        self.springs[i] = spring
    end

    self.stealthIcon = ZO_StealthIcon:New(control:GetNamedChild("StealthIcon"))

    local LOCKPICK_WINDOW_INTERACTION =
    {
        type = "Lockpick",
        interactTypes = { INTERACTION_LOCKPICK }
    }

    local function OnSceneStateChange(oldState, newState)
        if newState == SCENE_SHOWING then
            self:GatherExtents()

            self.virtualMouseX = nil
            self.virtualNormalizedMouseX = nil

            self:ResetChambers()

            -- make sure to reset the mouse position to the starting state, it may not be updated if a dialog is showing
            self:UpdateVirtualMousePosition()

            local lockQuality = GetLockQuality()

            local nowMs = GetFrameTimeMilliseconds()
            local timerStartS = nowMs / 1000
            local bonusS = 0
            if DoesPlayerHaveLockpickingCompanionBonus() then
                bonusS = GetLockpickingCompanionBonusTimeMS() / 1000
            end
            local durationS = GetLockpickingTimeLeft() / 1000 - bonusS
            local blueStart = ZO_ColorDef:New(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GENERAL, INTERFACE_GENERAL_COLOR_STATUS_BAR_START)))
            local blueEnd = ZO_ColorDef:New(ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_GENERAL, INTERFACE_GENERAL_COLOR_STATUS_BAR_END)))
            local function OnTimerStart(barData)
                local width = self.timer.control:GetWidth()
                local rightOffsetX = ((1 - (self.timer:GetSumDurationForSegment(2) / (durationS + bonusS))) * width - 4) * -1
                local bgControl = barData[2].bar:GetNamedChild("BG")
                bgControl:ClearAnchors()
                bgControl:SetAnchor(TOPLEFT, nil, nil, -3, -3)
                bgControl:SetAnchor(BOTTOMRIGHT, nil, nil, rightOffsetX, 4)
                bgControl:SetDrawLayer(DL_CONTROLS)
                barData[2].bar:SetDrawLevel(3)
                barData[2].bar:GetNamedChild("Gloss"):SetDrawLevel(3)
            end
            local function DecorateTimeString(timeString)
                local INHERIT_COLOR = true
                return ZO_SUCCEEDED_TEXT:Colorize(zo_iconTextFormatNoSpace("EsoUI/Art/TreeIcons/gamepad/GP_collection_indexIcon_Companions.dds", "100%", "100%", timeString, INHERIT_COLOR))
            end

            if SCENE_MANAGER:IsShowing("lockpickKeyboard") then
                self.lockLevelLabel:SetText(zo_strformat(SI_LOCKPICK_LEVEL, GetString("SI_LOCKQUALITY", lockQuality)))
                self.lockpicksLeftLabel:SetText(zo_strformat(SI_LOCKPICK_PICKS_REMAINING, GetNumLockpicksLeft()))

                self.infoBar:SetHidden(false)
                self.gamepadInfoBar:SetHidden(true)
                self.timer:Stop()
                self.timer:ClearSegments()
                self.timer:AddSegment(durationS, blueStart, blueEnd)
                if DoesPlayerHaveLockpickingCompanionBonus() then
                    self.timer:AddSegment(bonusS, ZO_SUCCEEDED_TEXT, ZO_SUCCEEDED_TEXT)
                    self.timer:SetCustomOnStartBehavior(OnTimerStart)
                    self.timer:SetTimeStringDecoratorFunction(DecorateTimeString)
                else
                    local NO_FUNCTION = nil
                    self.timer:SetTimeStringDecoratorFunction(NO_FUNCTION)
                end

                self.timer:Start(timerStartS)
                self.gamepadTimer:Stop()
            elseif SCENE_MANAGER:IsShowing("lockpickGamepad") then
                self.gamepadLockLevelLabel:SetText(GetString("SI_LOCKQUALITY", lockQuality))
                self.gamepadLockpicksLeftLabel:SetText(GetNumLockpicksLeft())

                self.infoBar:SetHidden(true)
                self.gamepadInfoBar:SetHidden(false)
                self.gamepadTimer:Stop()
                self.gamepadTimer:ClearSegments()
                self.gamepadTimer:AddSegment(durationS, blueStart, blueEnd)
                if DoesPlayerHaveLockpickingCompanionBonus() then
                    self.gamepadTimer:AddSegment(bonusS, ZO_SUCCEEDED_TEXT, ZO_SUCCEEDED_TEXT)
                    self.gamepadTimer:SetTimeStringDecoratorFunction(DecorateTimeString)
                end

                self.gamepadTimer:Start(timerStartS)
                self.timer:Stop()
            end

            PlaySound(SOUNDS.LOCKPICKING_START)

            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            HideMouse()
            self.inactivityStart = nil

            -- prioritize the practice tutorial over the general open tutorial
            if lockQuality == LOCK_QUALITY_PRACTICE then
                TriggerTutorial(TUTORIAL_TRIGGER_LOCKPICKING_PRACTICE_OPENED)
            end

            TriggerTutorial(TUTORIAL_TRIGGER_LOCKPICKING_OPENED)
        elseif newState == SCENE_HIDDEN then
            if self:IsPickBroken() then
                self:EndLockpickBreak()
            end
            self.settingChamberIndex = nil
            self:UpdatePinAlpha(FULL_PIN_ALPHA)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            ShowMouse()
        end
    end

    LOCKPICK_FRAGMENT = ZO_FadeSceneFragment:New(control)

    LOCK_PICK_SCENE = ZO_InteractScene:New("lockpickKeyboard", SCENE_MANAGER, LOCKPICK_WINDOW_INTERACTION)
    LOCK_PICK_SCENE:AddFragment(LOCKPICK_FRAGMENT)
    LOCK_PICK_SCENE:RegisterCallback("StateChange", OnSceneStateChange)

    LOCK_PICK_GAMEPAD_SCENE = ZO_InteractScene:New("lockpickGamepad", SCENE_MANAGER, LOCKPICK_WINDOW_INTERACTION)
    LOCK_PICK_GAMEPAD_SCENE:AddFragment(LOCKPICK_FRAGMENT)
    LOCK_PICK_GAMEPAD_SCENE:RegisterCallback("StateChange", OnSceneStateChange)

    self:RegisterForEvents()
end

function ZO_Lockpick:RegisterForEvents()
    self.control:RegisterForEvent(EVENT_STEALTH_STATE_CHANGED, function(event, unitTag, ...) self.stealthIcon:OnStealthStateChanged(...) end)
    self.control:AddFilterForEvent(EVENT_STEALTH_STATE_CHANGED, REGISTER_FILTER_UNIT_TAG, "player")

    self.control:SetHandler("OnUpdate", function() self:OnUpdate() end)

    local function OnBeginLockpick()
        self:SetHidden(false)
    end

    local function OnLockpickFailed()
        self:SetHidden(true)
        PlaySound(SOUNDS.LOCKPICKING_FAILED)
    end

    local function OnLockpickSuccess()
        self:SetHidden(true)
        PlaySound(SOUNDS.LOCKPICKING_UNLOCKED)
    end

    local function OnLockpickBroke(eventCode, inactivityDuration)
        PlaySound(SOUNDS.LOCKPICKING_BREAK)
        self:OnLockpickBroke(inactivityDuration)
        if SCENE_MANAGER:IsShowing("lockpickKeyboard") then
            self.lockpicksLeftLabel:SetText(zo_strformat(SI_LOCKPICK_PICKS_REMAINING, GetNumLockpicksLeft()))
        elseif SCENE_MANAGER:IsShowing("lockpickGamepad") then
            self.gamepadLockpicksLeftLabel:SetText(GetNumLockpicksLeft())
        end
    end

    self.control:RegisterForEvent(EVENT_BEGIN_LOCKPICK, OnBeginLockpick)
    self.control:RegisterForEvent(EVENT_LOCKPICK_FAILED, OnLockpickFailed)
    self.control:RegisterForEvent(EVENT_LOCKPICK_SUCCESS, OnLockpickSuccess)
    self.control:RegisterForEvent(EVENT_LOCKPICK_BROKE, OnLockpickBroke)
end

do
    local RANGE = 24
    local HALF_RANGE = RANGE / 2
    local ROTATION_FACTOR = ZO_PI / 140

    local function GenerateLoosenessFunction(loosenessFunction)
        return function(x) 
            return loosenessFunction(x * RANGE - HALF_RANGE) * ROTATION_FACTOR 
        end
    end

    local LoosenessFunctions =
    {
        GenerateLoosenessFunction(function(x)
            return math.cos(math.atan(x)) 
        end),

        GenerateLoosenessFunction(function(x)
            return math.sin(math.atan(x))
        end),

        GenerateLoosenessFunction(function(x)
            return x / HALF_RANGE
        end),

        GenerateLoosenessFunction(function(x)
            return math.cos(math.sin(x / RANGE) * x)
        end),
    }
    function ZO_Lockpick:ResetChambers()
        for i = 1, NUM_LOCKPICK_CHAMBERS do
            local spring = self.springs[i]
            spring:SetHeight(spring.height)
            spring:SetTextureRotation(0)
            spring.pin:SetTextureRotation(0)
            spring.pin.highlight:SetTextureRotation(0)
            spring.pin:SetTexture(NORMAL_TEXTURE)
            spring.loosenessFunction = LoosenessFunctions[math.random(1, #LoosenessFunctions)]
            spring.totalProgress = 0
            spring.interpolatedChamberProgress = 0
            self:UpdateChamber(i)
        end
    end
end

do
    local LOCKPICK_SLOP = 5
    function ZO_Lockpick:GatherExtents()
        local windowLeft = self.body:GetLeft()
        self.lockpickLowerBound = self.springs[1]:GetLeft() - windowLeft - LOCKPICK_SLOP
        self.lockpickUpperBound = self.springs[NUM_LOCKPICK_CHAMBERS]:GetRight() - windowLeft + LOCKPICK_SLOP
    end
end

do
    local PIN_MOVEMENT_PERCENT = .95
    local PIN_CONSTANT_PERCENT = 1 - PIN_MOVEMENT_PERCENT
    local STRESS_RESISTANCE_FACTOR = .5
    local APPROACH_AMOUNT_PER_NORMALIZED_FRAME = .4

    function ZO_Lockpick:UpdateChamber(chamberIndex, stress)
        local spring = self.springs[chamberIndex]
        local chamberState, chamberProgress = GetChamberState(chamberIndex)
        spring.totalProgress = (chamberState + chamberProgress) / (NUM_LOCKPICK_CHAMBER_STATES + 1)
        spring.interpolatedChamberProgress = zo_deltaNormalizedLerp(spring.interpolatedChamberProgress, spring.totalProgress, APPROACH_AMOUNT_PER_NORMALIZED_FRAME)

        local springResistance = 0
        local baseSpringResistance = 0
        if stress then
            baseSpringResistance = stress * STRESS_RESISTANCE_FACTOR
            springResistance = baseSpringResistance * PIN_MOVEMENT_PERCENT * spring.height / (NUM_LOCKPICK_CHAMBER_STATES + 1)
        end

        spring:SetHeight((1 - spring.interpolatedChamberProgress) * PIN_MOVEMENT_PERCENT * spring.height + spring.height * PIN_CONSTANT_PERCENT + springResistance)

        if stress then
            self:ApplyLoosenessToChamber(chamberIndex, baseSpringResistance)
            if chamberProgress < 1 and stress == 0 then
                self:PlayVibration(0.0, self.defaultVibration)
            else
                self:PlayVibration(0, self.defaultVibration + (stress * 0.75))
            end
        end
    end
end

do
    local STRESS_SOUND_THRESHOLD = .2
    function ZO_Lockpick:UpdateSettingChamber(ending)
        local spring = self.springs[self.settingChamberIndex]
        local previousChamberProgress = spring.totalProgress

        self:UpdateChamber(self.settingChamberIndex, GetSettingChamberStress())

        if previousChamberProgress > spring.totalProgress then
            --The chamber was stressed too much and reset
            self.playedStressSound = false
            if (not ending or not IsChamberSolved(self.settingChamberIndex)) and not self:IsPickBroken() and not self.hidden then
                PlaySound(SOUNDS.LOCKPICKING_CHAMBER_RESET)
            end
            if not ending then
                PlaySound(SOUNDS.LOCKPICKING_CHAMBER_START)
            end
        end

        if not self.playedStressSound and GetSettingChamberStress() > STRESS_SOUND_THRESHOLD then
            PlaySound(SOUNDS.LOCKPICKING_CHAMBER_STRESS)
            self.playedStressSound = true 
        end
    end
end

do
    local function CalculateSettingChamberStress()
        local stress = (GetSettingChamberStress())
        return math.sin(GetFrameTimeMilliseconds() * .05) * stress * .035
    end

    function ZO_Lockpick:ApplyLoosenessToChamber(chamberIndex, baseSpringResistance)
        local spring = self.springs[chamberIndex]
        local pin = spring.pin

        local normalizedY = spring.interpolatedChamberProgress - baseSpringResistance
        local looseness = spring.loosenessFunction(normalizedY)

        if chamberIndex == self.settingChamberIndex then
            looseness = looseness + CalculateSettingChamberStress()
        end

        spring:SetTextureRotation(looseness, .5, 1)
        pin:SetTextureRotation(-looseness, .5, 0)
        local normalizedY = (pin:GetTop() - pin.highlight:GetTop()) / pin.highlight:GetHeight()
        pin.highlight:SetTextureRotation(-looseness, .5, normalizedY)
    end
end

function ZO_Lockpick:PlayVibration(coarseMotor, fineMotor)
    if IsInGamepadPreferredMode() and not self.inactivityStart then
        SetGamepadVibration(100, coarseMotor, fineMotor, 0, 0, "lockpick feedback")
    end
end

function ZO_Lockpick:GetLockpickXValues(chamberIndex)
    if chamberIndex then
        local pin = self.springs[chamberIndex].pin
        local inset = pin:GetWidth() * .2
        local windowLeft = self.body:GetLeft()
        local clampedX = zo_clamp(self.virtualMouseX, pin:GetLeft() - windowLeft + inset, pin:GetRight() - windowLeft - inset)
        local normalizedX = (clampedX - self.lockpickLowerBound) / (self.lockpickUpperBound - self.lockpickLowerBound)
        return clampedX, normalizedX
    end
    return self.virtualMouseX, self.virtualNormalizedMouseX
end

do
    local LOCKPICK_X_ROTATION_FACTOR = ZO_PI / 45
    local LOCKPICK_Y_ROTATION_FACTOR = ZO_PI / 15
    local LOCKPICK_X_ROTATION_OFFSET_FACTOR = .15

    local AnchorParams =
    {
        {
            OffsetY = 229,
            NormalizedYFactor = 89,
            NormalizedXFactor = 17,
        },
        {
            OffsetY = 240,
            NormalizedYFactor = 85,
            NormalizedXFactor = 15,
        },
        {
            OffsetY = 251,
            NormalizedYFactor = 81,
            NormalizedXFactor = 12,
        },
        {
            OffsetY = 258,
            NormalizedYFactor = 77,
            NormalizedXFactor = 10,
        },
        {
            OffsetY = 267,
            NormalizedYFactor = 72,
            NormalizedXFactor = 8,
        },
    }

    local X_OFFSET = 5

    function ZO_Lockpick:UpdateLockpick()
        local clampedXOffset, normalizedX = self:GetLockpickXValues(self.settingChamberIndex)

        if self.settingChamberIndex then
            local spring = self.springs[self.settingChamberIndex]
            local params = AnchorParams[self.settingChamberIndex]
            local normalizedY = spring.interpolatedChamberProgress
            self.lockpick:SetAnchor(TOPRIGHT, self.body, TOPLEFT, clampedXOffset + X_OFFSET + normalizedY * params.NormalizedXFactor, params.OffsetY - normalizedY * params.NormalizedYFactor - spring:GetHeight())
            self.lockpick:SetTextureRotation(normalizedX * LOCKPICK_X_ROTATION_FACTOR - normalizedY * LOCKPICK_Y_ROTATION_FACTOR, normalizedX * LOCKPICK_X_ROTATION_OFFSET_FACTOR, .5)
        else
            self.lockpick:SetAnchor(TOPRIGHT, self.body, TOPLEFT, clampedXOffset + X_OFFSET, 112 + normalizedX * 40)
            self.lockpick:SetTextureRotation(normalizedX * LOCKPICK_X_ROTATION_FACTOR, normalizedX * LOCKPICK_X_ROTATION_OFFSET_FACTOR, .5)
        end
    
        self.lockpick:SetScale(1 - normalizedX * .1)
    end

    local LEFT_ROTATION_FACTOR = ZO_PI * 1.04
    local LEFT_ROTATION_FACTOR_AFTER_HIT = ZO_TWO_PI
    local RIGHT_ROTATION_FACTOR = ZO_PI / 3

    function ZO_Lockpick:UpdateBrokenLockpick(progressThroughDuration)
        local clampedXOffset, normalizedX = self:GetLockpickXValues(self.breakingChamberIndex)

        self.lockpickBreakLeft:ClearAnchors()
        self.lockpickBreakRight:ClearAnchors()

        local spring = self.springs[self.breakingChamberIndex]
        local params = AnchorParams[self.breakingChamberIndex]

        local sharedXOffset = clampedXOffset + X_OFFSET
        local sharedYOffset = params.OffsetY - spring:GetHeight()

        local hitLoc = .05 + normalizedX * .04
        local progressThroughHit = self.breakingChamberIndex ~= 1 and progressThroughDuration > hitLoc and (progressThroughDuration - hitLoc) / (1 - hitLoc) or 0

        local progressThroughDurationSquared = progressThroughDuration * progressThroughDuration
        local leftXOffset = sharedXOffset - progressThroughDuration * 100 * normalizedX - progressThroughDuration * 100 - progressThroughHit * 200
        local leftYOffset = sharedYOffset + progressThroughDurationSquared * 800
        self.lockpickBreakLeft:SetAnchor(TOPRIGHT, self.body, TOPLEFT, leftXOffset, leftYOffset)

        local rightXOffset = sharedXOffset + progressThroughDuration * 150 
        local rightYOffset = sharedYOffset + progressThroughDurationSquared * 450
        self.lockpickBreakRight:SetAnchor(TOPRIGHT, self.body, TOPLEFT, rightXOffset, rightYOffset)

        local sharedRotation = normalizedX * LOCKPICK_X_ROTATION_FACTOR
        local normalizedRotationX = normalizedX * LOCKPICK_X_ROTATION_OFFSET_FACTOR

        local leftRotation = sharedRotation - progressThroughDuration * LEFT_ROTATION_FACTOR + progressThroughHit * LEFT_ROTATION_FACTOR_AFTER_HIT
        self.lockpickBreakLeft:SetTextureRotation(leftRotation, normalizedRotationX, .5)

        local rightRotation = sharedRotation + progressThroughDuration * RIGHT_ROTATION_FACTOR
        self.lockpickBreakRight:SetTextureRotation(rightRotation, normalizedRotationX, .5)

        local sharedScale = 1 - normalizedX * .1
        self.lockpickBreakLeft:SetScale(sharedScale + progressThroughDuration * .2)
        self.lockpickBreakRight:SetScale(sharedScale)

        local alpha = 1 - progressThroughDuration ^ 5
        self.lockpickBreakLeft:SetAlpha(alpha)
        self.lockpickBreakRight:SetAlpha(alpha)
    end
end

local MIN_PERCENT_BEFORE_FINISHING = .005

function ZO_Lockpick:OnUpdate(ending)
    if self.settingChamberIndex then
        self:UpdateSettingChamber(ending)
    else
        -- don't update the mouse position if we're showing a dialog
        if not self.inactivityStart and not ZO_Dialogs_IsShowingDialog() then
            self:UpdateVirtualMousePosition()
        end

        self.playedStressSound = false
    end

    for i = 1, NUM_LOCKPICK_CHAMBERS do
        if self.settingChamberIndex ~= i then
            local spring = self.springs[i]
            if zo_abs(spring.totalProgress - spring.interpolatedChamberProgress) > MIN_PERCENT_BEFORE_FINISHING then
                self:UpdateChamber(i)
            end
        end
    end

    if self:IsPickBroken() then
        local now = GetFrameTimeMilliseconds()
        local progress = (now - self.inactivityStart) / self.inactivityDuration
        if progress < 1.0 then
            if IsInGamepadPreferredMode() and not self.hasPlayedBreakVibration then
                self.hasPlayedBreakVibration = true
                SetGamepadVibration(400, 1, 0, 0, 0, "lockpick broke")
            end
            self:UpdateBrokenLockpick(progress)
        else
            self:EndLockpickBreak()
        end
    else
        self:UpdateLockpick()
    end
end

function ZO_Lockpick:EndLockpickBreak()
    self:UpdateBrokenLockpick(1.0)

    self.inactivityStart = nil
    self.hasPlayedBreakVibration = false
    self.lockpick:SetHidden(false)
    self.lockpickBreakLeft:SetHidden(true)
    self.lockpickBreakRight:SetHidden(true)
    self:UpdateLockpick()

    self:UpdatePinAlpha(FULL_PIN_ALPHA)
    if self.settingChamberIndex then
        self:UpdatePinAlpha(PARTIAL_PIN_ALPHA, self.settingChamberIndex, false)
    end
end

function ZO_Lockpick:IsPickBroken()
    return self.inactivityStart ~= nil
end

local STARTING_NORMALIZED_LOCKPICK_X = 0.53
local GAMEPAD_SPEED_FACTOR = 3.5
function ZO_Lockpick:UpdateVirtualMousePosition()
    if not self.virtualMouseX then
        self.virtualMouseX = zo_lerp(self.lockpickLowerBound, self.lockpickUpperBound, STARTING_NORMALIZED_LOCKPICK_X)
        self.virtualNormalizedMouseX = STARTING_NORMALIZED_LOCKPICK_X
        self:OnVirtualLockpickPositionChanged()
    else
        local deltaX
        if IsInGamepadPreferredMode() then
            deltaX = ZO_Gamepad_GetLeftStickEasedX() * GAMEPAD_SPEED_FACTOR
        else
            deltaX = GetUIMouseDeltas()
        end
        deltaX = deltaX * GetFrameDeltaNormalizedForTargetFramerate()

        if deltaX ~= 0 then
            local newX = self.virtualMouseX + deltaX

            local clampedX = zo_clamp(newX, self.lockpickLowerBound, self.lockpickUpperBound)
            if clampedX ~= self.virtualMouseX then
                self.virtualMouseX = clampedX
                self.virtualNormalizedMouseX = (clampedX - self.lockpickLowerBound) / (self.lockpickUpperBound - self.lockpickLowerBound)

                self:OnVirtualLockpickPositionChanged()
            end
        end
    end
end

function ZO_Lockpick:OnVirtualLockpickPositionChanged()
    local oldClosestChamberIndex = self.closestChamberIndexToLockpick
    self.closestChamberIndexToLockpick = self:FindClosestChamberIndexToLockpick()
    if oldClosestChamberIndex ~= self.closestChamberIndexToLockpick then
        if oldClosestChamberIndex then
            self:RemoveHighlightOnPin(self.springs[oldClosestChamberIndex].pin)
        end
        self:PlayHighlightOnPin(self.springs[self.closestChamberIndexToLockpick].pin)
    end
end

function ZO_Lockpick:FindClosestChamberIndexToLockpick()
    local windowLeft = self.body:GetLeft()

    local closestDistance = math.huge
    local closestIndex
    for i = 1, NUM_LOCKPICK_CHAMBERS do
        local spring = self.springs[i]

        local distanceToLockpick = zo_abs((spring:GetCenter() - windowLeft) - (self.virtualMouseX))
        if distanceToLockpick < closestDistance then
            closestDistance = distanceToLockpick
            closestIndex = i
        end
    end

    return closestIndex
end

function ZO_Lockpick:OnLockpickBroke(inactivityDuration)
    if self.settingChamberIndex then
        --A broken pick clears out the setting chamber on the client so stop depressing it here too. Store off settingChamberIndex since that's the champer we broke the pick on and it's cleared by EndDepressingPin.
        local activeChamberIndex = self.settingChamberIndex
        self:EndDepressingPin()

        --If there is a time we have to wait before we can try to pick the lock again then run the break animation
        if inactivityDuration > 0 then
            self.lockpick:SetHidden(true)
            self.breakingChamberIndex = activeChamberIndex
            self.lockpickBreakLeft:SetHidden(false)
            self.lockpickBreakRight:SetHidden(false)
            self.inactivityDuration = inactivityDuration
            self.inactivityStart = GetFrameTimeMilliseconds()

            self:UpdatePinAlpha(PARTIAL_PIN_ALPHA)
        end
    end
end

function ZO_Lockpick:UpdatePinAlpha(alpha, ingoreIndex, allowHighlights)
    for i = 1, NUM_LOCKPICK_CHAMBERS do
        local spring = self.springs[i]
        if i ~= ingoreIndex then
            spring:SetAlpha(alpha)
            spring.pin:SetAlpha(alpha)
        end
        local hasHighlight = self.closestChamberIndexToLockpick == i and not IsChamberSolved(i) and (allowHighlights == nil or allowHighlights)
        if hasHighlight then
            spring.pin.highlightAnimation:PlayForward()
        else
            spring.pin.highlightAnimation:PlayBackward()
        end
    end
end

function ZO_Lockpick:StartDepressingPin()
    local chamberIndex = self.closestChamberIndexToLockpick
    if StartSettingChamber(chamberIndex) then
        PlaySound(SOUNDS.LOCKPICKING_CONTACT)
        PlaySound(SOUNDS.LOCKPICKING_CHAMBER_START)
        self.settingChamberIndex = chamberIndex

        self:UpdatePinAlpha(PARTIAL_PIN_ALPHA, chamberIndex, false)
    end
end

local ENDING_SETTING_CHAMBER = true

function ZO_Lockpick:EndDepressingPin()
    StopSettingChamber()
    if self.settingChamberIndex then
        local wasSettingSpring = self.springs[self.settingChamberIndex]
        if IsChamberSolved(self.settingChamberIndex) then
            wasSettingSpring.pin:SetTexture(SET_TEXTURE)
            PlaySound(SOUNDS.LOCKPICKING_CHAMBER_LOCKED)
        end
        
        self:OnUpdate(ENDING_SETTING_CHAMBER)
        self.settingChamberIndex = nil

        if not self.inactivityStart then
            self:UpdatePinAlpha(FULL_PIN_ALPHA)
        end
    end
end

function ZO_Lockpick:PlayHighlightOnPin(pin)
    if not self.settingChamberIndex and not IsChamberSolved(pin.chamberIndex) then
        pin.highlightAnimation:PlayForward()
    end
end

function ZO_Lockpick:RemoveHighlightOnPin(pin)
    pin.highlightAnimation:PlayBackward()
end

function ZO_Lockpick:CreateKeybindStripDescriptor()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_LOCKPICK_DEPRESS_PIN),
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            visible = IsInGamepadPreferredMode,
            handlesKeyUp = true,

            callback = function(up)
                if up then
                    self:EndDepressingPin()
                else
                    if not self:IsPickBroken() then
                        self:StartDepressingPin()
                    end
                end
            end,
        },
        {
            name = function() 
                    local chanceText
                    if DoesPlayerHaveLockpickingCompanionBonus() then
                        local INHERIT_COLOR = true
                        local iconSize = IsInGamepadPreferredMode() and 48 or 32
                        local iconString = zo_iconTextFormatNoSpace("EsoUI/Art/TreeIcons/gamepad/GP_collection_indexIcon_Companions.dds", iconSize, iconSize, GetChanceToForceLock(), INHERIT_COLOR)
                        chanceText = ZO_SUCCEEDED_TEXT:Colorize(zo_strformat(SI_LOCKPICK_FORCE_CHANCE, iconString))
                    else
                        chanceText = zo_strformat(SI_LOCKPICK_FORCE_CHANCE, GetChanceToForceLock())
                    end
                    return zo_strformat(SI_LOCKPICK_FORCE, chanceText)
                end,
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() 
                AttemptForceLock()
                PlaySound(SOUNDS.LOCKPICKING_FORCE)
                self:SetHidden(true)
            end,
        },
        KEYBIND_STRIP:GenerateGamepadLeftSlideButtonDescriptor(GetString(SI_GAMEPAD_LOCKPICK_MOVE), IsInGamepadPreferredMode),
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_Lockpick:SetHidden(hidden)
    self.hidden = hidden
    if hidden then
        SCENE_MANAGER:Hide("lockpickKeyboard")
        SCENE_MANAGER:Hide("lockpickGamepad")
    else
        if IsInGamepadPreferredMode() then
            SCENE_MANAGER:Show("lockpickGamepad")
        else
            SCENE_MANAGER:Show("lockpickKeyboard")
        end
    end
end

function ZO_Lockpick_OnInitialized(control)
    LOCK_PICK = ZO_Lockpick:New(control)
end

function ZO_Lockpick_OnMouseDown(control)
    if not control.owner:IsPickBroken() then
        control.owner:StartDepressingPin()
    end
end

function ZO_Lockpick_OnMouseUp(control)
    control.owner:EndDepressingPin()
end