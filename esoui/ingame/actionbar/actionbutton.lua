ZO_GAMEPAD_ACTION_BUTTON_SIZE = 61
ZO_GAMEPAD_ULTIMATE_BUTTON_SIZE = 67

local FORCE_SUPPRESS_COOLDOWN_SOUND = true

local g_showGlobalCooldown = false

function ZO_ActionButtons_ToggleShowGlobalCooldown()
    g_showGlobalCooldown = not g_showGlobalCooldown
end

ACTION_BUTTON_TYPE_VISIBLE = 1
ACTION_BUTTON_TYPE_HIDDEN = 2
ACTION_BUTTON_TYPE_LOCKED = 3

local ACTION_BUTTON_BGS = {ability = "EsoUI/Art/ActionBar/abilityInset.dds", item = "EsoUI/Art/ActionBar/quickslotBG.dds"}
local ACTION_BUTTON_BORDERS = {normal = "EsoUI/Art/ActionBar/abilityFrame64_up.dds", mouseDown = "EsoUI/Art/ActionBar/abilityFrame64_down.dds"}

local function HasAbility(slotnum)
    local slotType = GetSlotType(slotnum)

    return(slotType == ACTION_TYPE_ABILITY)
end

ActionButton = ZO_Object:Subclass()

function ActionButton:New(slotNum, buttonType, parent, controlTemplate)
    local newB = ZO_Object.New(self)

    if(newB)
    then
        local ctrlName = "ActionButton"..slotNum

        local slotCtrl = CreateControlFromVirtual(ctrlName, parent, controlTemplate)

        newB.buttonType             = buttonType
        newB.hasAction              = false
        newB.slot                   = slotCtrl
        newB.slot.slotNum           = slotNum
        newB.button                 = GetControl(slotCtrl, "Button")
        newB.button.slotNum         = slotNum
        newB.button.slotType        = ABILITY_SLOT_TYPE_ACTIONBAR
        newB.button.tooltip         = AbilityTooltip

        newB.flipCard               = GetControl(slotCtrl, "FlipCard")
        newB.bg                     = GetControl(slotCtrl, "BG")
        newB.icon                   = GetControl(slotCtrl, "Icon")
        newB.glow                   = GetControl(slotCtrl, "Glow")
        newB.buttonText             = GetControl(slotCtrl, "ButtonText")
        newB.countText              = GetControl(slotCtrl, "CountText")
        newB.cooldown               = GetControl(slotCtrl, "Cooldown")
        newB.cooldownCompleteAnim   = GetControl(slotCtrl, "CooldownCompleteAnimation")
        newB.cooldownIcon           = GetControl(slotCtrl, "CooldownIcon")
        newB.cooldownEdge           = GetControl(slotCtrl, "CooldownEdge")
        newB.status                 = GetControl(slotCtrl, "Status")
        newB.inCooldown             = false
        newB.showingCooldown        = false
        newB.activationHighlight    = GetControl(slotCtrl,"ActivationHighlight")

        newB.cooldownIcon:SetDesaturation(1)

        local HIDE_UNBOUND = false

        local onUltimateChanged =   function(label)
                                        if IsInGamepadPreferredMode() then
                                            label:SetHidden(true)
                                        end
                                    end
        local onChanged = (slotNum == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1) and onUltimateChanged or nil
        ZO_Keybindings_RegisterLabelForBindingUpdate(newB.buttonText, "ACTION_BUTTON_".. slotNum, HIDE_UNBOUND, "GAMEPAD_ACTION_BUTTON_".. slotNum, onChanged)

		if slotNum == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
			slotCtrl:RegisterForEvent(EVENT_INTERFACE_SETTING_CHANGED, function(_, settingType, settingId)
														if settingType == SETTING_TYPE_UI and settingId == UI_SETTING_ULTIMATE_NUMBER then
															newB:RefreshUltimateNumberVisibility()
														end
													end)
		end
    end

    return newB
end

function ActionButton:IsClassBarButton()
    return self.slot.slotNum > ACTION_BAR_FIRST_CLASS_BAR_SLOT and self.slot.slotNum <= ACTION_BAR_FIRST_CLASS_BAR_SLOT + ACTION_BAR_CLASS_BAR_SIZE
end

function ActionButton:IsSiegeBarButton()
    return self.slot.slotNum > ACTION_BAR_FIRST_SIEGE_BAR_SLOT and self.slot.slotNum <= ACTION_BAR_FIRST_SIEGE_BAR_SLOT + ACTION_BAR_SIEGE_BAR_SIZE
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

function ActionButton:HandlePressAndRelease()
    OnSlotDownAndUp(self:GetSlot())
end

function ActionButton:HandlePress()
    if(self.usable) then
        self.button:SetState(BSTATE_PRESSED, false)
    end
    OnSlotDown(self:GetSlot())
end

function ActionButton:HandleRelease()
    self:ResetVisualState()
    OnSlotUp(self:GetSlot())
end

function ActionButton:ResetVisualState()
    self.button:SetState(BSTATE_NORMAL, false)
end

local function SetupActionSlot(slotObject, slotId)
    local slotIcon = GetSlotTexture(slotId)

    slotObject.slot:SetHidden(false)
    slotObject.hasAction = true

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
		slotObject:SetupCount(nil)
	end
end

local function SetupItemSlot(slotObject, slotId)
    local itemCount = GetSlotItemCount(slotId)
    local consumable = IsSlotItemConsumable(slotId)

    SetupActionSlotWithBg(slotObject, slotId)
    slotObject:SetupCount(itemCount, consumable)
end

local function SetupSiegeActionSlot(slotObject, slotId)
    SetupActionSlot(slotObject, slotId)
end

local function SetupCollectibleActionSlot(slotObject, slotId)
    SetupActionSlotWithBg(slotObject, slotId)
    slotObject:SetupCount(nil)
end

SetupSlotHandlers = 
{
    [ACTION_TYPE_ABILITY]       = SetupAbilitySlot,
    [ACTION_TYPE_ITEM]          = SetupItemSlot,
    [ACTION_TYPE_SIEGE_ACTION]  = SetupSiegeActionSlot,
    [ACTION_TYPE_COLLECTIBLE]   = SetupCollectibleActionSlot,
}

function ActionButton:SetupCount(count, consumable)
    if(count and count >= 0 and consumable) then
        self.countText:SetHidden(false)
        self.countText:SetText(count)
    else
        self.countText:SetHidden(true)
    end
end

function ActionButton:HandleSlotChanged()
    local slotId = self:GetSlot()
    local slotType = GetSlotType(slotId)

    local setupSlotHandler = SetupSlotHandlers[slotType]
    if(setupSlotHandler)
    then
        setupSlotHandler(self, slotId)
    else
        self:Clear()
    end

    if self.showingCooldown then
        ZO_ContextualActionBar_RemoveReference()
    end
    self.showingCooldown = false

    self:UpdateState()

    local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
    if(mouseOverControl == self.button)
    then
        ZO_AbilitySlot_OnMouseEnter(self.button)
    end
end

function ActionButton:Clear()
    if(self.buttonType == ACTION_BUTTON_TYPE_LOCKED) then
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

function ActionButton:RefreshUltimateNumberVisibility()
    if GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_ULTIMATE_NUMBER) and self.hasAction then
        self.countText:SetHidden(false)
        self:UpdateUltimateNumber()
    else
        self:SetupCount(nil)
    end
end

function ActionButton:UpdateUltimateNumber()
	self.countText:SetText(GetUnitPower("player", POWERTYPE_ULTIMATE))
end

function ActionButton:UpdateActivationHighlight()
    local slotnum = self:GetSlot()
    local slotType = GetSlotType(slotnum)
    local slotIsEmpty = (slotType == 0)

    local showHighlight = not slotIsEmpty and HasActivationHighlight(slotnum) and not self.useFailure and not self.showingCooldown
    local isShowingHighlight = self.activationHighlight:IsHidden() == false

    if(showHighlight ~= isShowingHighlight) then
        self.activationHighlight:SetHidden(not showHighlight)

        if(showHighlight) then
            local _, _, activationAnimation = GetSlotTexture(slotnum)
            self.activationHighlight:SetTexture(activationAnimation)

            self.activationHighlight.animation = self.activationHighlight.animation or CreateSimpleAnimation(ANIMATION_TEXTURE, self.activationHighlight)
            local anim = self.activationHighlight.animation

            anim:SetImageData(64,1)
            anim:SetFramerate(30)
            anim:GetTimeline():PlayFromStart()
        else
            local anim = self.activationHighlight.animation
            if(anim) then
                anim:GetTimeline():Stop()
            end
        end
    end 
end

function ActionButton:UpdateState()
    local slotnum = self:GetSlot()
    local slotType = GetSlotType(slotnum)
    local slotIsEmpty = (slotType == ACTION_TYPE_NOTHING)

    self.button.actionId = GetSlotBoundId(slotnum)

    self:UpdateUseFailure()

    self.status:SetHidden(slotIsEmpty or IsSlotToggled(slotnum) == false)

    self:UpdateActivationHighlight()
    self:UpdateCooldown(FORCE_SUPPRESS_COOLDOWN_SOUND)
end

function ActionButton:UpdateUseFailure()
    local slotnum = self:GetSlot()
    local slotType = GetSlotType(slotnum)
    local slotIsEmpty = (slotType == ACTION_TYPE_NOTHING)

    self.itemQtyFailure = false
    if(not slotIsEmpty and (slotType == ACTION_TYPE_ITEM)) then
        self.itemQtyFailure = (GetSlotItemCount(slotnum) == 0)
    end

	local soulGemFailure = false
	if(not slotIsEmpty and slotType == ACTION_TYPE_ABILITY) then
		local isSoulGemAbility = IsSlotSoulTrap(slotnum)
		if(isSoulGemAbility and not DoesInventoryContainEmptySoulGem()) then
			soulGemFailure = true
		end
	end

    local costFailure = HasCostFailure(slotnum)
    local nonCostFailure = not slotIsEmpty and
                           self.itemQtyFailure or
                           soulGemFailure or
					       HasTargetFailure(slotnum) or
					       HasRequirementFailure(slotnum) or
					       HasWeaponSlotFailure(slotnum) or
					       HasStatusEffectFailure(slotnum) or
					       HasFallingFailure(slotnum) or
					       HasSwimmingFailure(slotnum) or
					       HasMountedFailure(slotnum) or
                           HasReincarnatingFailure(slotnum) or
                           HasRangeFailure(slotnum)

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

    if usable ~= self.usable or isGamepad ~= self.isGamepad then
        self.usable = usable
        self.isGamepad = isGamepad
        local useDesaturation = isShowingCooldown and not self.useFailure
        ZO_ActionSlot_SetUnusable(self.icon, not usable, useDesaturation)
    end
end

function ActionButton:SetCooldownIconAnchors(inCooldown)
    self.icon:ClearAnchors()
    local isGamepad = IsInGamepadPreferredMode()
    self.cooldownEdge:SetHidden(not isGamepad or not inCooldown)

    if isGamepad then
        if inCooldown then
            self.icon:SetAnchor(BOTTOMLEFT, self.flipCard)
            self.icon:SetAnchor(BOTTOMRIGHT, self.flipCard)
        else
            self.icon:SetAnchor(CENTER, self.flipCard)
        end
    else
        self.icon:SetAnchor(TOPLEFT, self.flipCard)
        self.icon:SetAnchor(BOTTOMRIGHT, self.flipCard)
    end
end

function ActionButton:SetCooldownHeight(percentComplete)
    local percent = percentComplete or 1 -- Can get here from several places before percentComplete has been set (]forcereload)
    local height = zo_ceil(ZO_GAMEPAD_ACTION_BUTTON_SIZE * percent)
    local textureCoord = 1 - height / ZO_GAMEPAD_ACTION_BUTTON_SIZE
    self.icon:SetHeight(height)
    self.icon:SetTextureCoords(0, 1, textureCoord, 1)
    self.cooldownIcon:SetTextureCoords(0, 1, 0, textureCoord)
end

function ActionButton:RefreshCooldown()
    local remain, duration = GetSlotCooldownInfo(self:GetSlot())
    local percentComplete = (1 - remain/duration)

    if IsInGamepadPreferredMode() then
        self:SetCooldownHeight(percentComplete)
    end

    self.icon.percentComplete = percentComplete
end

local NO_LEADING_EDGE = false
function ActionButton:UpdateCooldown(options)
    local slotnum = self:GetSlot()
    local remain, duration, global, globalSlotType = GetSlotCooldownInfo(slotnum)
    local isInCooldown = duration > 0
    local slotType = GetSlotType(slotnum)
    local showGlobalCooldownForCollectible = global and slotType == ACTION_TYPE_COLLECTIBLE and globalSlotType == ACTION_TYPE_COLLECTIBLE
    local showCooldown = isInCooldown and (g_showGlobalCooldown or not global or showGlobalCooldownForCollectible)

    self.cooldown:SetHidden(not showCooldown)

    local updateChromaQuickslot = slotType ~= ACTION_TYPE_ABILITY and ZO_RZCHROMA_EFFECTS

    if showCooldown then
        self.cooldown:StartCooldown(remain, duration, CD_TYPE_RADIAL, nil, NO_LEADING_EDGE)
        if(self.cooldownCompleteAnim.animation) then
            self.cooldownCompleteAnim.animation:GetTimeline():PlayInstantlyToStart()
        end

        if IsInGamepadPreferredMode() then
            if not self.itemQtyFailure then
                self.icon:SetDesaturation(0)
            end
            self.cooldown:SetHidden(true)
            if not self.showingCooldown then
                self:SetNeedsAnimationParameterUpdate(true)
                self:PlayAbilityUsedBounce()
            end
        else
            self.cooldown:SetHidden(false)
        end

        self.slot:SetHandler("OnUpdate", function() self:RefreshCooldown() end)
        if updateChromaQuickslot then
            ZO_RZCHROMA_EFFECTS:RemoveKeybindActionEffect("UI_SHORTCUT_QUICK_SLOTS")
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
                ZO_RZCHROMA_EFFECTS:AddKeybindActionEffect("UI_SHORTCUT_QUICK_SLOTS")
            end
        end

        self.icon.percentComplete = 1
        self.slot:SetHandler("OnUpdate", nil)
        self.cooldown:ResetCooldown()
    end

    if showCooldown ~= self.showingCooldown then
        self.showingCooldown = showCooldown

        if self.showingCooldown then
            ZO_ContextualActionBar_AddReference()
        else
            ZO_ContextualActionBar_RemoveReference()
        end
                    
        self:UpdateActivationHighlight()
        if IsInGamepadPreferredMode() then
            self:SetCooldownHeight(self.icon.percentComplete)
        end
        self:SetCooldownIconAnchors(showCooldown)
    end

    local textColor = showCooldown and INTERFACE_TEXT_COLOR_FAILED or INTERFACE_TEXT_COLOR_SELECTED
    self.buttonText:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, textColor))

    self.isGlobalCooldown = global
    self:UpdateUsable()
end

function ActionButton:ApplyFlipAnimationStyle()
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
    self:ApplyFlipAnimationStyle()

    local decoration = self.slot:GetNamedChild("Decoration")
    if decoration then
        decoration:SetHidden(isGamepad)
    end

    local slotnum = self:GetSlot()
    local slotType = GetSlotType(slotnum)

    local cooldownHeight = 1

    if self.showingCooldown then 
        self.cooldown:SetHidden(isGamepad)

        if isGamepad then
            local remain = GetSlotCooldownInfo(slotnum)
            self:PlayAbilityUsedBounce(BOUNCE_DURATION_MS + remain)
            cooldownHeight = self.icon.percentComplete
            if not self.itemQtyFailure then
                self.icon:SetDesaturation(0)
            end
        else
            self.bounceAnimation:Stop()
            self.iconBounceAnimation:Stop()
        end
    end

    self:UpdateUsable()
end

function ActionButton:ApplyAnchor(target, offsetX)
    self.slot:SetAnchor(LEFT, target, RIGHT, offsetX, 0)
end

local function OnStartFlipAnimation(button)
    if IsInGamepadPreferredMode() and button:GetSlot() ~= ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
        button.icon:ClearAnchors()
        button.icon:SetAnchor(TOPLEFT, button.flipCard)
        button.icon:SetAnchor(BOTTOMRIGHT, button.flipCard)
    end
end

local function OnStopFlipAnimation(button)
    if IsInGamepadPreferredMode() and button:GetSlot() ~= ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 then
        button.icon:ClearAnchors()
        button.icon:SetAnchor(CENTER, button.flipCard)
    end
end

function ActionButton:SetupFlipAnimation(OnStopHandlerFirst, OnStopHandlerLast)
    local timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("HotbarSwapAnimation", self.flipCard)
    timeline:GetFirstAnimation():SetHandler("OnStop", function(animation) OnStopHandlerFirst(animation, self) end)
    timeline:GetLastAnimation():SetHandler("OnStop", function(animation) OnStopHandlerLast(animation, self) end)
    timeline:SetHandler("OnPlay", function() OnStartFlipAnimation(self) end)
    timeline:SetHandler("OnStop", function() OnStopFlipAnimation(self) end)
    self.hotbarSwapAnimation = timeline

    self:ApplyFlipAnimationStyle()
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

function ActionButton:PlayAbilityUsedBounce(offset)
    if not self.bounceAnimation:IsPlaying() then
        if self.needsAnimationParameterUpdate then
            local slotnum = self:GetSlot()
            local _, duration = GetSlotCooldownInfo(slotnum)
            local slotType = GetSlotType(slotnum)
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
    local leftKey = self.slot:GetNamedChild("LBkey")
    local rightKey = self.slot:GetNamedChild("RBkey")
    if leftKey and rightKey then
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