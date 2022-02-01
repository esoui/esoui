ZO_GAMEPAD_ACTION_BUTTON_SIZE = 61
ZO_GAMEPAD_ULTIMATE_BUTTON_SIZE = 67

ACTION_BUTTON_TYPE_VISIBLE = 1
ACTION_BUTTON_TYPE_HIDDEN = 2
ACTION_BUTTON_TYPE_LOCKED = 3

ACTION_BUTTON_TIMER_TEXT_OFFSET_Y_DEFAULT_KEYBOARD = 7
ACTION_BUTTON_TIMER_TEXT_OFFSET_Y_DEFAULT_GAMEPAD = 4

local ACTION_BUTTON_BGS = {ability = "EsoUI/Art/ActionBar/abilityInset.dds", item = "EsoUI/Art/ActionBar/quickslotBG.dds"}
local ACTION_BUTTON_BORDERS = {normal = "EsoUI/Art/ActionBar/abilityFrame64_up.dds", mouseDown = "EsoUI/Art/ActionBar/abilityFrame64_down.dds"}
local MINIMUM_TIMER_DECIMAL_VALUE = 9.94
local FORCE_SUPPRESS_COOLDOWN_SOUND = true

local g_showGlobalCooldown = false

function ZO_ActionButtons_ToggleShowGlobalCooldown()
    g_showGlobalCooldown = not g_showGlobalCooldown
end

ActionButton = ZO_InitializingObject:Subclass()

function ActionButton:Initialize(slotNum, buttonType, parent, controlTemplate, hotbarCategory)
    local controlName 
    if hotbarCategory == HOTBAR_CATEGORY_COMPANION then
        controlName = "CompanionUltimateButton"
    else
        controlName = "ActionButton"..slotNum
    end

    local slotControl = CreateControlFromVirtual(controlName, parent, controlTemplate)

    self.buttonType = buttonType
    self.hasAction = false
    self.slot = slotControl
    self.slot.slotNum = slotNum
    self.button = slotControl:GetNamedChild("Button")
    self.button.slotNum = slotNum
    self.button.slotType = ABILITY_SLOT_TYPE_ACTIONBAR
    self.button.hotbarCategory = hotbarCategory

    self.flipCard = slotControl:GetNamedChild("FlipCard")
    self.bg = slotControl:GetNamedChild("BG")
    self.icon = slotControl:GetNamedChild("Icon")
    self.glow = slotControl:GetNamedChild("Glow")
    self.buttonText = slotControl:GetNamedChild("ButtonText")
    self.countText = slotControl:GetNamedChild("CountText")

    self.stackCountText = slotControl:GetNamedChild("StackCountText")
    self.timerText = slotControl:GetNamedChild("TimerText")
    self.timerOverlay = slotControl:GetNamedChild("TimerOverlay")
    self.cooldown = slotControl:GetNamedChild("Cooldown")
    self.cooldownCompleteAnim = slotControl:GetNamedChild("CooldownCompleteAnimation")
    self.cooldownIcon = slotControl:GetNamedChild("CooldownIcon")
    self.cooldownEdge = slotControl:GetNamedChild("CooldownEdge")
    self.status = slotControl:GetNamedChild("Status")
    self.inCooldown = false
    self.showingCooldown = false
    self.activationHighlight = slotControl:GetNamedChild("ActivationHighlight")
    self.useDesaturation = false
    self.cooldownIcon:SetDesaturation(1)
    self.showTimer = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_ACTION_BAR_TIMERS)
    self.currentUltimateMax = 0
    self.ultimateReadyBurstTimeline = nil
    self.ultimateReadyLoopTimeline = nil
    self.ultimateBarFillLeftTimeline = nil
    self.ultimateBarFillRightTimeline = nil

    local HIDE_UNBOUND = false

    local function OnUltimateChanged(label)
        if IsInGamepadPreferredMode() and ZO_Keybindings_ShouldShowGamepadKeybind() then
            label:SetHidden(true)

            if self.leftKey and self.rightKey then
                self:HideKeys(false)
            end
        else
            label:SetHidden(false)

            if self.leftKey and self.rightKey then
                self:HideKeys(true)
            end 
        end
    end
    local onChanged = (slotNum == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1) and OnUltimateChanged or nil
    if self.button.hotbarCategory == HOTBAR_CATEGORY_COMPANION then
        ZO_Keybindings_RegisterLabelForBindingUpdate(self.buttonText, "COMMAND_PET", HIDE_UNBOUND, "COMMAND_PET", onChanged)
    else
        ZO_Keybindings_RegisterLabelForBindingUpdate(self.buttonText, "ACTION_BUTTON_".. slotNum, HIDE_UNBOUND, "GAMEPAD_ACTION_BUTTON_".. slotNum, onChanged)
    end

    if slotNum == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
        slotControl:RegisterForEvent(EVENT_INTERFACE_SETTING_CHANGED, function(_, settingType, settingId)
            if settingType == SETTING_TYPE_UI and settingId == UI_SETTING_ULTIMATE_NUMBER then
                self:RefreshUltimateNumberVisibility()
            end
        end)
    end

    EVENT_MANAGER:RegisterForEvent(controlName, EVENT_INTERFACE_SETTING_CHANGED, function(...) self:OnInterfaceSettingChanged(...) end)
end

function ActionButton:SetShowBindingText(visible)
    self.buttonText:SetHidden(not visible)
end

function ActionButton:GetSlot()
    return self.slot.slotNum
end

function ActionButton:GetButtonType()
    return self.buttonType
end

function ActionButton:HasAction()
    return self.hasAction
end

function ActionButton:OnPress()
    if self.usable then
        self.button:SetState(BSTATE_PRESSED, false)
    end
end

function ActionButton:OnRelease()
    self:ResetVisualState()
end

function ActionButton:ResetVisualState()
    self.button:SetState(BSTATE_NORMAL, false)
end

function ActionButton:SetEnabled(enabled)
    self.slot:SetHidden(not enabled)
    self.hasAction = enabled
end

local function SetupActionSlot(slotObject, slotId)
    -- pass slotObject.button.hotbarCategory which will be nil or companion
    local slotIcon = GetSlotTexture(slotId, slotObject.button.hotbarCategory)
    slotObject:SetEnabled(true)
    local isGamepad = IsInGamepadPreferredMode()
    ZO_ActionSlot_SetupSlot(slotObject.icon, slotObject.button, slotIcon, isGamepad and "" or ACTION_BUTTON_BORDERS.normal, isGamepad and "" or ACTION_BUTTON_BORDERS.mouseDown, slotObject.cooldownIcon)
    slotObject:UpdateState()
end

local function SetupActionSlotWithBg(slotObject, slotId)
    SetupActionSlot(slotObject, slotId)
    slotObject.bg:SetTexture(ACTION_BUTTON_BGS.ability)
end

local function SetupAbilitySlot(slotObject, slotId)
    SetupActionSlotWithBg(slotObject, slotId)

    if slotId == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
        slotObject:RefreshUltimateNumberVisibility()
    else
        slotObject:ClearCount()
    end
end

local function SetupItemSlot(slotObject, slotId)
    SetupActionSlotWithBg(slotObject, slotId)
    slotObject:SetupCount()
end

local function SetupCollectibleActionSlot(slotObject, slotId)
    SetupActionSlotWithBg(slotObject, slotId)
    slotObject:ClearCount()
end

local function SetupQuestItemActionSlot(slotObject, slotId)
    SetupActionSlotWithBg(slotObject, slotId)
    slotObject:SetupCount()
end

local function SetupEmptyActionSlot(slotObject, slotId)
    slotObject:Clear()
end

SetupSlotHandlers =
{
    [ACTION_TYPE_ABILITY]       = SetupAbilitySlot,
    [ACTION_TYPE_ITEM]          = SetupItemSlot,
    [ACTION_TYPE_COLLECTIBLE]   = SetupCollectibleActionSlot,
    [ACTION_TYPE_QUEST_ITEM]    = SetupQuestItemActionSlot,
    [ACTION_TYPE_NOTHING]       = SetupEmptyActionSlot,
}

function ActionButton:SetupCount()
    local slotId = self:GetSlot()
    local slotType = GetSlotType(slotId, self.button.hotbarCategory)
    local stackCount
    if slotType == ACTION_TYPE_ITEM then
        stackCount = GetSlotItemCount(slotId)
    end

    if stackCount and stackCount >= 0 then
        self.countText:SetHidden(false)
        self.countText:SetText(stackCount)
    else
        self:ClearCount()
    end
end

function ActionButton:ClearCount()
    self.countText:SetHidden(true)
end

function ActionButton:HandleSlotChanged()
    local slotId = self:GetSlot()
    local slotType = GetSlotType(slotId, self.button.hotbarCategory)

    local setupSlotHandler = SetupSlotHandlers[slotType]
    if internalassert(setupSlotHandler, "update slot handlers") then
        setupSlotHandler(self, slotId)
    end

    self:SetShowCooldown(false)
    self:UpdateState()

    local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
    if mouseOverControl == self.button then
        ZO_AbilitySlot_OnMouseEnter(self.button)
    end
end

function ActionButton:Clear()
    if self.buttonType == ACTION_BUTTON_TYPE_LOCKED then
        self.slot:SetHidden(true)
    else
        local isGamepad = IsInGamepadPreferredMode()
        ZO_ActionSlot_ClearSlot(self.icon, self.button, isGamepad and "" or ACTION_BUTTON_BORDERS.normal, isGamepad and "" or ACTION_BUTTON_BORDERS.mouseDown, self.cooldownIcon)
    end
    self.hasAction = false
    self.button.actionId = nil
    self.cooldownEdge:SetHidden(true)
    self.countText:SetText("")
end

function ActionButton:UpdateActivationHighlight()
    local slotnum = self:GetSlot()
    local slotType = GetSlotType(slotnum, self.button.hotbarCategory)
    local slotIsEmpty = (slotType == ACTION_TYPE_NOTHING)
    local showHighlight = not slotIsEmpty and HasActivationHighlight(slotnum, self.button.hotbarCategory) and not self.useFailure and not self.showingCooldown
    local isShowingHighlight = self.activationHighlight:IsControlHidden() == false

    if showHighlight ~= isShowingHighlight then
        self.activationHighlight:SetHidden(not showHighlight)

        if showHighlight then
            local _, _, activationAnimationTexture = GetSlotTexture(slotnum, self.button.hotbarCategory)
            self.activationHighlight:SetTexture(activationAnimationTexture)

            local anim = self.activationHighlight.animation
            if not anim then
                anim = CreateSimpleAnimation(ANIMATION_TEXTURE, self.activationHighlight)
                anim:SetImageData(64, 1)
                anim:SetFramerate(30)
                anim:GetTimeline():SetPlaybackType(ANIMATION_PLAYBACK_LOOP, LOOP_INDEFINITELY)

                self.activationHighlight.animation = anim
            end

            anim:GetTimeline():PlayFromStart()
        else
            local anim = self.activationHighlight.animation
            if anim then
                anim:GetTimeline():Stop()
            end
        end
    end 
end

function ActionButton:UpdateState()
    local slotnum = self:GetSlot()
    local slotType = GetSlotType(slotnum, self.button.hotbarCategory)
    local slotIsEmpty = (slotType == ACTION_TYPE_NOTHING)

    self.button.actionId = GetSlotBoundId(slotnum, self.button.hotbarCategory)

    self:UpdateUseFailure()

    self.status:SetHidden(slotIsEmpty or IsSlotToggled(slotnum) == false)

    self:UpdateActivationHighlight()
    self:UpdateCooldown(FORCE_SUPPRESS_COOLDOWN_SOUND)
end

function ActionButton:SetStackCount(stackCount)
    if stackCount > 0 and self.showTimer then
        self.stackCountText:SetHidden(false)
        self.stackCountText:SetText(stackCount)
    else
        self.stackCountText:SetHidden(true)
    end
end

function ActionButton:SetTimer(durationMS)
    self.endTimeMS = GetFrameTimeMilliseconds() + durationMS
    self.timerText:SetHidden(false)
    local actionType = GetSlotType(self:GetSlot(), self.button.hotbarCategory) 
    local abilityId = GetSlotBoundId(self:GetSlot(), self.button.hotbarCategory)
    if actionType == ACTION_TYPE_ABILITY and ShouldAbilityShowAsUsableWithDuration(abilityId) then
        self.timerOverlay:SetHidden(true)
    else
        self.timerOverlay:SetHidden(false)
    end
    self.slot:SetHandler("OnUpdate", function() self:UpdateTimer() end, "TimerUpdate")
end

function ActionButton:UpdateTimer()
    if self.endTimeMS then
        if self.endTimeMS > GetFrameTimeMilliseconds() and self.showTimer then
            local remainingEffectTimeMS = self.endTimeMS - GetFrameTimeMilliseconds()
            local value = remainingEffectTimeMS / 1000
            
            local SHOW_UNIT_OVER_THRESHOLD_S = ZO_ONE_MINUTE_IN_SECONDS
            local SHOW_DECIMAL_UNDER_THRESHOLD_S = ZO_EFFECT_EXPIRATION_IMMINENCE_THRESHOLD_S
            local timeLeftString = ZO_FormatTimeShowUnitOverThresholdShowDecimalUnderThreshold(value, SHOW_UNIT_OVER_THRESHOLD_S, SHOW_DECIMAL_UNDER_THRESHOLD_S, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT)
            self.timerText:SetText(timeLeftString)

            --We only need to worry about updating the anchor for ultimate slots as they are the only ones with count text
            if self.slot.slotNum == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
                self:RefreshTimerTextAnchor()
            end
        else
            self.endTimeMS = nil
            self.timerText:SetHidden(true)
            self.timerOverlay:SetHidden(true)
            self.slot:SetHandler("OnUpdate", nil, "TimerUpdate")
        end
    end
end

function ActionButton:UpdateUseFailure()
    local slotnum = self:GetSlot()
    local slotType = GetSlotType(slotnum, self.button.hotbarCategory)

    self.itemQtyFailure = false
    local soulGemFailure = false
    if slotType == ACTION_TYPE_ITEM then
        self.itemQtyFailure = (GetSlotItemCount(slotnum) == 0)
    elseif slotType == ACTION_TYPE_ABILITY then
        local isSoulGemAbility = IsSlotSoulTrap(slotnum)
        if isSoulGemAbility and not DoesInventoryContainEmptySoulGem() then
            soulGemFailure = true
        end
    end

    local costFailure = HasCostFailure(slotnum, self.button.hotbarCategory)
    local nonCostFailure = slotType ~= ACTION_TYPE_NOTHING and
                           self.itemQtyFailure or
                           soulGemFailure or
                           HasNonCostStateFailure(slotnum, self.button.hotbarCategory)

    self.costFailureOnly = costFailure and not nonCostFailure
    self.useFailure = costFailure or nonCostFailure
end

function ActionButton:UpdateUsable()
    local isGamepad = IsInGamepadPreferredMode()
    local isShowingCooldown = self.showingCooldown
    local isKeyboardUltimateSlot = not isGamepad and self.slot.slotNum == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1
    local usable = false
    if not self.useFailure and not isShowingCooldown then
        usable = true
    elseif isKeyboardUltimateSlot and self.costFailureOnly then
        usable = true
    end

    local slotId = self:GetSlot()
    local slotType = GetSlotType(slotId, self.button.hotbarCategory)
    local stackEmpty = false
    if slotType == ACTION_TYPE_ITEM then
        local stackCount = GetSlotItemCount(slotId)
        if stackCount <= 0 then
            stackEmpty = true
            usable = false
        end
    end
    
    local useDesaturation = isShowingCooldown and not self.useFailure or stackEmpty
    if usable ~= self.usable or useDesaturation ~= self.useDesaturation then
        self.usable = usable
        self.useDesaturation = useDesaturation
        ZO_ActionSlot_SetUnusable(self.icon, not usable, useDesaturation)
    end
end

function ActionButton:SetShowCooldown(showCooldown)
    if showCooldown ~= self.showingCooldown then
        if showCooldown then
            ZO_ContextualActionBar_AddReference()
        else
            ZO_ContextualActionBar_RemoveReference()
        end

        self.showingCooldown = showCooldown
        self:SetCooldownEdgeState(showCooldown)
    end
end

function ActionButton:SetCooldownEdgeState(inCooldown)
    self.cooldownEdge:SetHidden(not IsInGamepadPreferredMode() or not inCooldown)
end

function ActionButton:SetCooldownPercentComplete(percentComplete)
    local percent = percentComplete or 1 -- Can get here from several places before percentComplete has been set (]forcereload)
    local iconWidth, iconHeight = self.icon:GetDimensions()
    local offsetY = (1 - percent) * iconHeight
    self.cooldownEdge:SetSimpleAnchor(self.icon, 0, offsetY)
    self.cooldownEdge:SetWidth(iconWidth)
end

function ActionButton:RefreshCooldown()
    local remain, duration = GetSlotCooldownInfo(self:GetSlot())
    local percentComplete = (1 - remain/duration)

    if IsInGamepadPreferredMode() then
        self:SetCooldownPercentComplete(percentComplete)
        self:UpdateUsable()
    end

    self.icon.percentComplete = percentComplete
end

local NO_LEADING_EDGE = false
function ActionButton:UpdateCooldown(options)
    local slotnum = self:GetSlot()
    local remain, duration, global, globalSlotType = GetSlotCooldownInfo(slotnum)
    local isInCooldown = duration > 0
    local slotType = GetSlotType(slotnum, self.button.hotbarCategory)
    local showGlobalCooldownForCollectible = global and slotType == ACTION_TYPE_COLLECTIBLE and globalSlotType == ACTION_TYPE_COLLECTIBLE
    local showCooldown = isInCooldown and (g_showGlobalCooldown or not global or showGlobalCooldownForCollectible)
    local updateChromaQuickslot = slotType ~= ACTION_TYPE_ABILITY and ZO_RZCHROMA_EFFECTS
    self.cooldown:SetHidden(not showCooldown)

    if showCooldown then
        self.cooldown:StartCooldown(remain, duration, CD_TYPE_RADIAL, nil, NO_LEADING_EDGE)

        if self.cooldownCompleteAnim.animation then
            self.cooldownCompleteAnim.animation:GetTimeline():PlayInstantlyToStart()
        end

        if IsInGamepadPreferredMode() then
            self.cooldown:SetHidden(true)

            if not self.showingCooldown then
                self:SetNeedsAnimationParameterUpdate(true)
                self:PlayAbilityUsedBounce()
            end
        else
            self.cooldown:SetHidden(false)
        end

        self.slot:SetHandler("OnUpdate", function() self:RefreshCooldown() end, "CooldownUpdate")

        if updateChromaQuickslot then
            ZO_RZCHROMA_EFFECTS:RemoveKeybindActionEffect("ACTION_BUTTON_9")
        end
    else
        if self.showingCooldown then
            -- This ability was in a non-global cooldown, and now the cooldown is over...play animation and sound
            if options ~= FORCE_SUPPRESS_COOLDOWN_SOUND then
                PlaySound(SOUNDS.ABILITY_READY)
            end

            self.cooldownCompleteAnim.animation = self.cooldownCompleteAnim.animation or CreateSimpleAnimation(ANIMATION_TEXTURE, self.cooldownCompleteAnim)
            local anim = self.cooldownCompleteAnim.animation

            self.cooldownCompleteAnim:SetHidden(false)
            self.cooldown:SetHidden(false)

            anim:SetImageData(16,1)
            anim:SetFramerate(30)
            anim:GetTimeline():PlayFromStart()

            if updateChromaQuickslot then
                ZO_RZCHROMA_EFFECTS:AddKeybindActionEffect("ACTION_BUTTON_9")
            end
        end

        self.icon.percentComplete = 1
        self.slot:SetHandler("OnUpdate", nil, "CooldownUpdate")
        self.cooldown:ResetCooldown()
    end

    if showCooldown ~= self.showingCooldown then
        self:SetShowCooldown(showCooldown)
        self:UpdateActivationHighlight()

        if IsInGamepadPreferredMode() then
            self:SetCooldownPercentComplete(self.icon.percentComplete)
        end
    end

    if showCooldown or self.itemQtyFailure then
        self.icon:SetDesaturation(1)
    else
        self.icon:SetDesaturation(0)
    end

    local textColor = showCooldown and INTERFACE_TEXT_COLOR_FAILED or INTERFACE_TEXT_COLOR_SELECTED
    self.buttonText:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, textColor))

    self.isGlobalCooldown = global
    self:UpdateUsable()
end

function ActionButton:ApplySwapAnimationStyle()
    local timeline = self.hotbarSwapAnimation
    if timeline then
        local width, height = self.flipCard:GetDimensions()
        local firstAnimation = timeline:GetFirstAnimation()
        local lastAnimation = timeline:GetLastAnimation()

        firstAnimation:SetStartAndEndWidth(width, width)
        firstAnimation:SetStartAndEndHeight(height, 0)
        lastAnimation:SetStartAndEndWidth(width, width)
        lastAnimation:SetStartAndEndHeight(0, height)
    end
end

local BOUNCE_DURATION_MS = 500

local function GetUnusableForPlatform(slotNum, useFailure, usable)
    if IsInGamepadPreferredMode() or slotNum ~= ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
        return useFailure
    else
        return not usable
    end
end

function ActionButton:ApplyStyle(template)
    ApplyTemplateToControl(self.slot, template)

    local isGamepad = IsInGamepadPreferredMode()
    self.button:SetNormalTexture(isGamepad and "" or ACTION_BUTTON_BORDERS.normal)
    self.button:SetPressedTexture(isGamepad and "" or ACTION_BUTTON_BORDERS.mouseDown)
    self.countText:SetFont(isGamepad and "ZoFontGamepadBold27" or "ZoFontGameShadow")
    self:ApplySwapAnimationStyle()

    local decoration = self.slot:GetNamedChild("Decoration")
    if decoration then
        decoration:SetHidden(isGamepad)
    end

    if self.showingCooldown then 
        self.cooldown:SetHidden(isGamepad)

        if isGamepad then
            local slotnum = self:GetSlot()
            local remain = GetSlotCooldownInfo(slotnum)
            self:PlayAbilityUsedBounce(BOUNCE_DURATION_MS + remain)

            if not self.itemQtyFailure then
                self.icon:SetDesaturation(0)
            end
        else
            self:ResetBounceAnimation()
        end
    else
        self:ResetBounceAnimation()
    end

    self:SetCooldownEdgeState(self.showingCooldown)
    self:UpdateUsable()
end

function ActionButton:ApplyAnchor(target, offsetX, isAnchoredLeft)
    if not isAnchoredLeft then
        self.slot:SetAnchor(LEFT, target, RIGHT, offsetX, 0)
    else
        self.slot:SetAnchor(RIGHT, target, LEFT, -offsetX, 0)
    end
end

function ActionButton:SetupSwapAnimation(OnStopHandlerFirst, OnStopHandlerLast)
    local timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("HotbarSwapAnimation", self.flipCard)
    timeline:GetFirstAnimation():SetHandler("OnStop", function(animation) OnStopHandlerFirst(animation, self) end)
    timeline:GetLastAnimation():SetHandler("OnStop", function(animation) OnStopHandlerLast(animation, self) end)
    timeline:SetHandler("OnPlay", function() self:SetShowCooldown(false) end)
    self.hotbarSwapAnimation = timeline

    self:ApplySwapAnimationStyle()
end

do
    local SHRINK_SCALE = 0.9
    local ICON_SHRINK_SCALE = 0.8
    local GROW_SCALE = 1.1
    local ICON_COOLDOWN_SCALE = 0.9
    local FRAME_RESET_TIME_MS = 167
    local ICON_RESET_TIME_MS = 100

    local function SetAnimationParameters(timeline, control, shrinkScale, resetTime, isUltimateSlot)
        local shrink = timeline:GetAnimation(1)
        local grow = timeline:GetAnimation(2)
        local reset = timeline:GetAnimation(3)
        local size = isUltimateSlot and ZO_GAMEPAD_ULTIMATE_BUTTON_SIZE or ZO_GAMEPAD_ACTION_BUTTON_SIZE

        shrink:SetStartAndEndWidth(size, size * shrinkScale)
        shrink:SetStartAndEndHeight(size, size * shrinkScale)

        grow:SetStartAndEndWidth(size * shrinkScale, size * GROW_SCALE)
        grow:SetStartAndEndHeight(size * shrinkScale, size * GROW_SCALE)

        reset:SetStartAndEndWidth(size * GROW_SCALE, size)
        reset:SetStartAndEndHeight(size * GROW_SCALE, size)
        reset:SetDuration(resetTime)
    end

    function ActionButton:SetBounceAnimationParameters(cooldownTime)
        local isUltimateSlot = self:GetSlot() == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1
        SetAnimationParameters(self.bounceAnimation, self.flipCard, SHRINK_SCALE, FRAME_RESET_TIME_MS, isUltimateSlot)
        SetAnimationParameters(self.iconBounceAnimation, self.icon, ICON_SHRINK_SCALE, ICON_RESET_TIME_MS, isUltimateSlot)
    end
end

function ActionButton:SetupBounceAnimation()
    local mainTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ActionSlotBounceAnimation", self.flipCard)
    local iconTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ActionSlotBounceAnimation", self.icon)

    self.bounceAnimation = mainTimeline
    self.iconBounceAnimation = iconTimeline

    self.glowAnimation = ZO_AlphaAnimation:New(self.glow)
    self.glowAnimation:SetMinMaxAlpha(0, 1)

    self.needsAnimationParameterUpdate = true
end

function ActionButton:ResetBounceAnimation()
    self.bounceAnimation:Stop()
    self.iconBounceAnimation:Stop()
end

function ActionButton:PlayAbilityUsedBounce(offset)
    if not self.bounceAnimation:IsPlaying() then
        if self.needsAnimationParameterUpdate then
            local slotnum = self:GetSlot()
            local _, duration = GetSlotCooldownInfo(slotnum)
            local slotType = GetSlotType(slotnum, self.button.hotbarCategory)
            self:SetBounceAnimationParameters(slotType == ACTION_TYPE_ITEM and duration or 0)
            self.needsAnimationParameterUpdate = false
        end

        self.bounceAnimation:PlayFromStart(offset)
        self.iconBounceAnimation:PlayFromStart(offset)
        if not offset then
            self:PlayGlow()
        end
    end
end

function ActionButton:PlayGlow()
    self.glowAnimation:PingPong(0, 1, BOUNCE_DURATION_MS * (1 / 3), 1)
end

function ActionButton:SetNeedsAnimationParameterUpdate(needsUpdate)
    self.needsAnimationParameterUpdate = needsUpdate
end

function ActionButton:SetupKeySlideAnimation()
    local leftKey = self.slot:GetNamedChild("LeftKeybind")
    local rightKey = self.slot:GetNamedChild("RightKeybind")
    
    if leftKey and rightKey then
        if self.button.hotbarCategory == HOTBAR_CATEGORY_COMPANION then
            leftKey:SetKeyCode(KEY_GAMEPAD_LEFT_STICK)
            rightKey:SetKeyCode(KEY_GAMEPAD_RIGHT_STICK)
        end
        self.leftKeyTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("UltimateAbilityButtonSlideLeft", leftKey)
        self.rightKeyTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("UltimateAbilityButtonSlideRight", rightKey)

        self.leftKey = leftKey
        self.rightKey = rightKey
    end
end

function ActionButton:SlideKeysIn()
    self.leftKeyTimeline:PlayForward()
    self.rightKeyTimeline:PlayForward()
end

function ActionButton:SlideKeysOut()
    self.leftKeyTimeline:PlayBackward()
    self.rightKeyTimeline:PlayBackward()
end

function ActionButton:SetupTimerSwapAnimation()
    self.timerSwapAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("TimerSwapAnimation", self.timerText)
    self.stackCountSwapAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("TimerSwapAnimation", self.stackCountText)
end

do
    local function AnchorKey(key, anchor)
        key:ClearAnchors()
        anchor:AddToControl(key)
    end

    function ActionButton:AnchorKeysIn()
        if not self.keyAnchorInLeft then
            self.keyAnchorInLeft = ZO_Anchor:New(TOPRIGHT, self.slot, BOTTOMLEFT, 15, -15)
            self.keyAnchorInRight = ZO_Anchor:New(TOPLEFT, self.slot, BOTTOMRIGHT, -15, -15)
        end

        if not self.leftKeyTimeline:IsPlaying() then
            AnchorKey(self.leftKey, self.keyAnchorInLeft)
            AnchorKey(self.rightKey, self.keyAnchorInRight)
        end
    end

    function ActionButton:AnchorKeysOut()
        if not self.keyAnchorOutLeft then
            self.keyAnchorOutLeft = ZO_Anchor:New(TOPRIGHT, self.slot, BOTTOMLEFT, 0, -15)
            self.keyAnchorOutRight = ZO_Anchor:New(TOPLEFT, self.slot, BOTTOMRIGHT, 0, -15)
        end

        if not self.leftKeyTimeline:IsPlaying() then
            AnchorKey(self.leftKey, self.keyAnchorOutLeft)
            AnchorKey(self.rightKey, self.keyAnchorOutRight)
        end
    end
end

function ActionButton:HideKeys(hide)
    self.leftKey:SetHidden(hide)
    self.rightKey:SetHidden(hide)
end

function ActionButton:OnInterfaceSettingChanged(eventId, settingType, settingId)
    if settingType == SETTING_TYPE_UI then
        if settingId == UI_SETTING_SHOW_ACTION_BAR_TIMERS then
            self.showTimer = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_ACTION_BAR_TIMERS)
        end
    end
end

function ActionButton:PlayAnimationFromOffset(animation, newOffset)
    animation:ClearAllCallbacks()
    local function StopAnimationTimeline(timeline)
        timeline:Stop()
    end
    animation:InsertCallback(StopAnimationTimeline, newOffset)

    if newOffset == 0 then
        animation:PlayBackward()
    else
        animation:PlayFromStart(newOffset)
    end

    animation.currentOffset = newOffset
end

function ActionButton:PlayUltimateFillAnimation(leftTexture, rightTexture, newPercentComplete, setProgressNoAnim)
    if not self.ultimateBarFillLeftTimeline then
        self.ultimateBarFillLeftTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("UltimateBarFillLoopAnimation", leftTexture)
        self.ultimateBarFillRightTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("UltimateBarFillLoopAnimation", rightTexture)
        self.ultimateBarFillRightTimeline:GetFirstAnimation():SetMirrorAlongY(true)
    end

    if not self.ultimateBarFillLeftTimeline:IsPlaying() then
        local duration = self.ultimateBarFillLeftTimeline:GetDuration()
        local offset = zo_floor(duration * newPercentComplete)
        if self.ultimateBarFillLeftTimeline.currentOffset ~= offset then
            self:PlayAnimationFromOffset(self.ultimateBarFillLeftTimeline, offset)
            self:PlayAnimationFromOffset(self.ultimateBarFillRightTimeline, offset)

            if offset == duration then
                if setProgressNoAnim then
                    self:AnchorKeysIn()
                else
                    self:PlayGlow()
                    self:SlideKeysIn()
                end
            elseif offset == 0 then
                self:SlideKeysOut()
            end
        end
    end
end

function ActionButton:StopUltimateReadyAnimations()
    if self.ultimateReadyBurstTimeline then
        self.ultimateReadyBurstTimeline:Stop()
        self.ultimateReadyLoopTimeline:Stop()
        if ZO_RZCHROMA_EFFECTS then
            ZO_RZCHROMA_EFFECTS:RemoveKeybindActionEffect("ACTION_BUTTON_8")
        end
    end

    if self.ultimateReadyBurstTimeline then
        self.ultimateReadyBurstTimeline:Stop()
        self.ultimateReadyLoopTimeline:Stop()
    end
end

function ActionButton:PlayUltimateReadyAnimations(ultimateReadyBurstTexture, ultimateReadyLoopTexture, setProgressNoAnim)
    local isCompanionUltimate = self.button.hotbarCategory == HOTBAR_CATEGORY_COMPANION
    local ultimateSound = isCompanionUltimate and SOUNDS.ABILITY_COMPANION_ULTIMATE_READY or SOUNDS.ABILITY_ULTIMATE_READY
    if not self.ultimateReadyBurstTimeline then
        self.ultimateReadyBurstTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("UltimateReadyBurst", ultimateReadyBurstTexture)
        self.ultimateReadyLoopTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("UltimateReadyLoop", ultimateReadyLoopTexture)
        self.ultimateReadyBurstTimeline:SetHandler("OnPlay", function() 
            if not self.suppressUltimateSound then
                PlaySound(ultimateSound)
            end
        end)

        local function OnStop(timeline)
            if timeline:GetProgress() == 1.0 then
                ultimateReadyBurstTexture:SetHidden(true)
                self.ultimateReadyLoopTimeline:PlayFromStart()
                ultimateReadyLoopTexture:SetHidden(false)
            end
        end
        self.ultimateReadyBurstTimeline:SetHandler("OnStop", function(timeline) OnStop(timeline) end)
    end

    self.suppressUltimateSound = setProgressNoAnim and isCompanionUltimate

    local addChromaEffect = false
    if not g_activeWeaponSwapInProgress then
        if not self.ultimateReadyBurstTimeline:IsPlaying() and not self.ultimateReadyLoopTimeline:IsPlaying() then
            ultimateReadyBurstTexture:SetHidden(false)
            self.ultimateReadyBurstTimeline:PlayFromStart()
            addChromaEffect = true
        end
    elseif not self.ultimateReadyLoopTimeline:IsPlaying() then
        self.ultimateReadyLoopTimeline:PlayFromStart()
        ultimateReadyLoopTexture:SetHidden(false)
        addChromaEffect = true
    end

    if ZO_RZCHROMA_EFFECTS and addChromaEffect then
        ZO_RZCHROMA_EFFECTS:AddKeybindActionEffect("ACTION_BUTTON_8")
    end
end

function ActionButton:ResetUltimateFillAnimations()
    if self.ultimateBarFillLeftTimeline then
        self:PlayAnimationFromOffset(self.ultimateBarFillLeftTimeline, 0)
        self:PlayAnimationFromOffset(self.ultimateBarFillRightTimeline, 0)

        self.ultimateBarFillLeftTimeline:ClearAllCallbacks()
        self.ultimateBarFillRightTimeline:ClearAllCallbacks()
    end
end

function ActionButton:RefreshUltimateNumberVisibility()
    if GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_ULTIMATE_NUMBER) and self.hasAction then
        self.countText:SetHidden(false)
        self:UpdateUltimateNumber()
    else
        self:ClearCount()
    end
end

do
    local TIMER_TEXT_OFFSET_Y_COUNT_TEXT_VISIBLE_GAMEPAD = -8
    local TIMER_TEXT_OFFSET_Y_COUNT_TEXT_VISIBLE_KEYBOARD =  -5

    function ActionButton:RefreshTimerTextAnchor()
        local timerTextYOffset = 0

        --The timer text needs to be in a slightly different spot if the count text is showing to prevent overlap
        if self.countText:IsHidden() then
            timerTextYOffset = IsInGamepadPreferredMode() and ACTION_BUTTON_TIMER_TEXT_OFFSET_Y_DEFAULT_GAMEPAD or ACTION_BUTTON_TIMER_TEXT_OFFSET_Y_DEFAULT_KEYBOARD
        else
            timerTextYOffset = IsInGamepadPreferredMode() and TIMER_TEXT_OFFSET_Y_COUNT_TEXT_VISIBLE_GAMEPAD or TIMER_TEXT_OFFSET_Y_COUNT_TEXT_VISIBLE_KEYBOARD
        end

        if timerTextYOffset ~= self.timerTextYOffset then
            self.timerText:SetAnchor(CENTER, nil, CENTER, 0, timerTextYOffset)
            self.timerTextYOffset = timerTextYOffset
        end
    end
end

function ActionButton:UpdateUltimateNumber()
    local ultimateCount
    if self.button.hotbarCategory == HOTBAR_CATEGORY_COMPANION then
        ultimateCount = GetUnitPower("companion", POWERTYPE_ULTIMATE)
    else
        ultimateCount = GetUnitPower("player", POWERTYPE_ULTIMATE)
    end
    self.countText:SetText(ultimateCount)
end

function ActionButton:UpdateUltimateMeter()
    local SET_ULTIMATE_METER_NO_ANIM = true
    self:UpdateCurrentUltimateMax()
    local ultimateCount
    if self.button.hotbarCategory == HOTBAR_CATEGORY_COMPANION then
        ultimateCount = GetUnitPower("companion", POWERTYPE_ULTIMATE)
    else
        ultimateCount = GetUnitPower("player", POWERTYPE_ULTIMATE)
    end

    self:SetUltimateMeter(ultimateCount, SET_ULTIMATE_METER_NO_ANIM)
end

function ActionButton:UpdateCurrentUltimateMax()
    local cost, mechanic = GetSlotAbilityCost(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1, self.button.hotbarCategory)

    if mechanic == POWERTYPE_ULTIMATE then
        self.currentUltimateMax = cost
    else
        self.currentUltimateMax = 0
    end
end

function ActionButton:SetUltimateMeter(ultimateCount, setProgressNoAnim)
    --self.button.hotbarCategory below can be nil, and currently should be in all cases except the companion ultimate button
    local isSlotUsed = IsSlotUsed(ACTION_BAR_ULTIMATE_SLOT_INDEX + 1, self.button.hotbarCategory)
    local barTexture = GetControl(self.slot, "UltimateBar")
    local leadingEdge = GetControl(self.slot, "LeadingEdge")
    local ultimateReadyBurstTexture = GetControl(self.slot, "ReadyBurst")
    local ultimateReadyLoopTexture = GetControl(self.slot, "ReadyLoop")
    local ultimateFillLeftTexture = GetControl(self.slot, "FillAnimationLeft")
    local ultimateFillRightTexture = GetControl(self.slot, "FillAnimationRight")
    local ultimateFillFrame = GetControl(self.slot, "Frame")

    local isGamepad = IsInGamepadPreferredMode()

    if isSlotUsed then
        -- Show fill bar if platform appropriate
        ultimateFillFrame:SetHidden(not isGamepad)
        ultimateFillLeftTexture:SetHidden(not isGamepad)
        ultimateFillRightTexture:SetHidden(not isGamepad)
        
        if ultimateCount >= self.currentUltimateMax then
            --hide progress bar
            barTexture:SetHidden(true)
            leadingEdge:SetHidden(true)

            -- Set fill bar to full
            self:PlayUltimateFillAnimation(ultimateFillLeftTexture, ultimateFillRightTexture, 1, setProgressNoAnim)
            self:PlayUltimateReadyAnimations(ultimateReadyBurstTexture, ultimateReadyLoopTexture, setProgressNoAnim)
        else
            --stop animation
            ultimateReadyBurstTexture:SetHidden(true)
            ultimateReadyLoopTexture:SetHidden(true)
            self:StopUltimateReadyAnimations()

            -- show platform appropriate progress bar
            barTexture:SetHidden(isGamepad)
            leadingEdge:SetHidden(isGamepad)

            -- update both platforms progress bars
            local slotHeight = self.slot:GetHeight()
            local percentComplete = ultimateCount / self.currentUltimateMax
            local yOffset = zo_floor(slotHeight * (1 - percentComplete))
            barTexture:SetHeight(yOffset)

            leadingEdge:ClearAnchors()
            leadingEdge:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, yOffset - 5)
            leadingEdge:SetAnchor(TOPRIGHT, nil, TOPRIGHT, 0, yOffset - 5)

            self:PlayUltimateFillAnimation(ultimateFillLeftTexture, ultimateFillRightTexture, percentComplete, setProgressNoAnim)
            self:AnchorKeysOut()
        end

        self:UpdateUltimateNumber()
    else
        --stop animation
        ultimateReadyBurstTexture:SetHidden(true)
        ultimateReadyLoopTexture:SetHidden(true)
        self:StopUltimateReadyAnimations()
        self:ResetUltimateFillAnimations()

        --hide progress bar for all platforms
        barTexture:SetHidden(true)
        leadingEdge:SetHidden(true)
        ultimateFillLeftTexture:SetHidden(true)
        ultimateFillRightTexture:SetHidden(true)
        ultimateFillFrame:SetHidden(true)
        self:AnchorKeysOut()
    end

    self:HideKeys(not (isGamepad and ZO_Keybindings_ShouldShowGamepadKeybind()))
end

--------------------
-- ActionBarTimer --
--------------------

local ACTION_BAR_TIMER_FRAMES = {keyboard = "EsoUI/Art/ActionBar/backrow_abilityFrame.dds", gamepad = "EsoUI/Art/ActionBar/Gamepad/gp_backrow_abilityFrame.dds"}

ZO_ActionBarTimer = ZO_InitializingObject:Subclass()

function ZO_ActionBarTimer:Initialize(slotNum, parent, controlTemplate, barType)
    local controlName = "ActionBarTimer"..slotNum

    local slotControl = CreateControlFromVirtual(controlName, parent, controlTemplate)

    self.slot = slotControl
    self.slot.slotNum = slotNum
    self.barType = barType

    self.iconTexture = slotControl:GetNamedChild("Icon")

    self.fillStatusBar = slotControl:GetNamedChild("ActionTimerStatusBar")
    ZO_StatusBar_SetGradientColor(self.fillStatusBar, ZO_CAST_BAR_COLORS[ZO_CAST_STATE_BEGIN_CHARGE_UP])

    self.frame = slotControl:GetNamedChild("Frame")
    local frame = IsInGamepadPreferredMode() and ACTION_BAR_TIMER_FRAMES.gamepad or ACTION_BAR_TIMER_FRAMES.keyboard
    self.frame:SetTexture(frame)

    self.showTimer = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_ACTION_BAR_TIMERS)
    self.showBackRowSlot = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_ACTION_BAR_BACK_ROW) and self.showTimer
    EVENT_MANAGER:RegisterForEvent(controlName, EVENT_INTERFACE_SETTING_CHANGED, function(...) self:OnInterfaceSettingChanged(...) end)
end

function ZO_ActionBarTimer:ApplyAnchor(target, offsetY)
    self.slot:ClearAnchors()
    self.slot:SetAnchor(CENTER, target, CENTER, 0, offsetY)
    self:ApplySwapAnimationStyle(offsetY)
end

function ZO_ActionBarTimer:ApplyStyle(template)
    ApplyTemplateToControl(self.slot, template)
    local frame = IsInGamepadPreferredMode() and ACTION_BAR_TIMER_FRAMES.gamepad or ACTION_BAR_TIMER_FRAMES.keyboard
    self.frame:SetTexture(frame)

    if self.endTimeMS and self.durationMS and self.showBackRowSlot then
        self.slot:SetHidden(false)
    else
        self.slot:SetHidden(true)
    end
end

function ZO_ActionBarTimer:SetFillBar(timeRemainingMS, durationMS)
    self.endTimeMS = GetFrameTimeMilliseconds() + timeRemainingMS
    self.durationMS = durationMS

    self:UpdateFillBar()
    if self.showBackRowSlot and self:HasValidDuration() then
        self.slot:SetHidden(false)
        self.slot:SetHandler("OnUpdate", function() self:UpdateFillBar() end, "FillBarUpdate")
    end
end

function ZO_ActionBarTimer:UpdateFillBar()
    if self.showBackRowSlot and self:HasValidDuration() then
        local interval = (self.endTimeMS - GetFrameTimeMilliseconds()) / self.durationMS
        self.fillStatusBar:SetValue(interval)
    else
        self.endTimeMS = nil
        self.fillStatusBar:SetValue(0)
        self.slot:SetHidden(true)
        self.slot:SetHandler("OnUpdate", nil, "FillBarUpdate")
    end
end

function ZO_ActionBarTimer:HasValidDuration()
    return self.durationMS and self.durationMS ~= 0 and self.endTimeMS and self.endTimeMS >= GetFrameTimeMilliseconds()
end

function ZO_ActionBarTimer:HandleSlotChanged(barType)
    local slotId = self.slot.slotNum
    self.barType = barType
    self:SetupBackRowSlot(slotId, barType)
end

function ZO_ActionBarTimer:SetupSwapAnimation(OnStopHandlerFirst, OnStopHandlerLast)
    local IS_BACK_BAR_SLOT = true
    local timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("BackBarSwapAnimation", self.slot)
    timeline:GetFirstAnimation():SetHandler("OnPlay", ApplySwapAnimationStyle)
    timeline:GetFirstAnimation():SetHandler("OnStop", function(animation) OnStopHandlerFirst(animation, self, IS_BACK_BAR_SLOT) end)
    timeline:GetLastAnimation():SetHandler("OnStop", function(animation) OnStopHandlerLast(animation, self) end)
    self.backBarSwapAnimation = timeline

    self:ApplySwapAnimationStyle()
end

function ZO_ActionBarTimer:ApplySwapAnimationStyle(offsetY)
    local translateDownAnimation = self.backBarSwapAnimation:GetAnimation(1)
    local frameSizeDownAnimation = self.backBarSwapAnimation:GetAnimation(2)
    local iconSizeDownAnimation = self.backBarSwapAnimation:GetAnimation(3)
    local translateUpAnimation = self.backBarSwapAnimation:GetAnimation(4)
    local frameSizeUpAnimation = self.backBarSwapAnimation:GetAnimation(5)
    local iconSizeUpAnimation = self.backBarSwapAnimation:GetAnimation(6)

    translateDownAnimation:SetStartOffsetY(offsetY)
    translateDownAnimation:SetEndOffsetY(0)
    translateUpAnimation:SetStartOffsetY(0)
    translateUpAnimation:SetEndOffsetY(offsetY)

    local width, height = self.slot:GetDimensions()
    frameSizeDownAnimation:SetStartAndEndWidth(width, width)
    frameSizeDownAnimation:SetStartAndEndHeight(height, 0)
    frameSizeUpAnimation:SetStartAndEndWidth(width, width)
    frameSizeUpAnimation:SetStartAndEndHeight(0, height)

    width, height = self.iconTexture:GetDimensions()
    iconSizeDownAnimation:SetStartAndEndWidth(width, width)
    iconSizeDownAnimation:SetStartAndEndHeight(height, 0)
    iconSizeUpAnimation:SetStartAndEndWidth(width, width)
    iconSizeUpAnimation:SetStartAndEndHeight(0, height)
end

function ZO_ActionBarTimer:GetSlot()
    return self.slot.slotNum
end

function ZO_ActionBarTimer:SetupBackRowSlot(slotId, barType)
    local isValidBarType = barType == HOTBAR_CATEGORY_BACKUP or barType == HOTBAR_CATEGORY_PRIMARY
    local shown = isValidBarType and GetSlotType(slotId, barType) ~= ACTION_TYPE_NOTHING and self.active and self.showBackRowSlot and self:HasValidDuration()
    self.slot:SetHidden(not shown)

    if self.iconTexture then
        local slotIcon = GetSlotTexture(slotId, barType)
        self.iconTexture:SetTexture(slotIcon)
    end
end

function ZO_ActionBarTimer:SetActive(active)
    self.active = active
end

function ZO_ActionBarTimer:OnInterfaceSettingChanged(eventId, settingType, settingId)
    if settingType == SETTING_TYPE_UI then
        if settingId == UI_SETTING_SHOW_ACTION_BAR_BACK_ROW or settingId == UI_SETTING_SHOW_ACTION_BAR_TIMERS then
            if settingId == UI_SETTING_SHOW_ACTION_BAR_TIMERS then
                self.showTimer = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_ACTION_BAR_TIMERS)
            end
            self.showBackRowSlot = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_ACTION_BAR_BACK_ROW) and self.showTimer
            self:SetupBackRowSlot(self.slot.slotNum, self.barType)
        end
    end
end