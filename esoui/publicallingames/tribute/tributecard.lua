local NO_CARD = 0

local TRIBUTE_CARD_ATLAS_FILE_DIMENSIONS = 512
ZO_TRIBUTE_CARD_UI_WIDTH = 284
ZO_TRIBUTE_CARD_UI_HEIGHT = 493
ZO_TRIBUTE_CARD_TOP_COORD = 0
ZO_TRIBUTE_CARD_BOTTOM_COORD = ZO_TRIBUTE_CARD_UI_HEIGHT / TRIBUTE_CARD_ATLAS_FILE_DIMENSIONS
ZO_TRIBUTE_CARD_LEFT_COORD = 0
ZO_TRIBUTE_CARD_RIGHT_COORD = ZO_TRIBUTE_CARD_UI_WIDTH / TRIBUTE_CARD_ATLAS_FILE_DIMENSIONS
local TRIBUTE_CARD_WORLD_WIDTH = 0.1115
ZO_TRIBUTE_CARD_WORLD_SCALE = TRIBUTE_CARD_WORLD_WIDTH / ZO_TRIBUTE_CARD_UI_WIDTH

ZO_TRIBUTE_SUIT_ICON_DIMENSIONS = 64
ZO_TRIBUTE_SUIT_ICON_TOP_COORD = 0
ZO_TRIBUTE_SUIT_ICON_BOTTOM_COORD = ZO_TRIBUTE_SUIT_ICON_DIMENSIONS / TRIBUTE_CARD_ATLAS_FILE_DIMENSIONS
ZO_TRIBUTE_SUIT_ICON_LEFT_COORD = (TRIBUTE_CARD_ATLAS_FILE_DIMENSIONS - ZO_TRIBUTE_SUIT_ICON_DIMENSIONS) / TRIBUTE_CARD_ATLAS_FILE_DIMENSIONS
ZO_TRIBUTE_SUIT_ICON_RIGHT_COORD = 1

local MECHANIC_CONTAINER_LARGE_ACTIVATION_HEIGHT = 55
local MECHANIC_CONTAINER_LARGE_COMBO_HEIGHT = 55
local MECHANIC_CONTAINER_SMALL_ACTIVATION_HEIGHT = 41
local MECHANIC_CONTAINER_SMALL_COMBO_HEIGHT = 41

ZO_MECHANIC_TYPE_ICON_LARGE_DIMENSIONS = 32
ZO_MECHANIC_TYPE_ICON_SMALL_DIMENSIONS = 24

local TRIBUTE_CARD_STATE_EFFECT_LAYER_OVERLAY = 1
local TRIBUTE_CARD_STATE_EFFECT_LAYER_UNDERLAY = 2
local TRIBUTE_CARD_STATE_EFFECT_LAYERS =
{
    TRIBUTE_CARD_STATE_EFFECT_LAYER_OVERLAY,
    TRIBUTE_CARD_STATE_EFFECT_LAYER_UNDERLAY,
}

local TRIBUTE_CARD_STATE_EFFECT_CONTROL_TEMPLATES =
{
    [TRIBUTE_CARD_STATE_FLAGS_BUYABLE] =
    {
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_OVERLAY] = "ZO_TributeCard_BuyableOverlay_Template",
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_UNDERLAY] = "ZO_TributeCard_BuyableUnderlay_Template",
    },
    [TRIBUTE_CARD_STATE_FLAGS_DAMAGEABLE] =
    {
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_OVERLAY] = "ZO_TributeCard_DamageableOverlay_Template",
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_UNDERLAY] = "ZO_TributeCard_DamageableUnderlay_Template",
    },
    [TRIBUTE_CARD_STATE_FLAGS_PLAYABLE] =
    {
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_OVERLAY] = "ZO_TributeCard_PlayableOverlay_Template",
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_UNDERLAY] = "ZO_TributeCard_PlayableUnderlay_Template",
    },
    [TRIBUTE_CARD_STATE_FLAGS_TARGETABLE] =
    {
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_OVERLAY] = "ZO_TributeCard_TargetableOverlay_Template",
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_UNDERLAY] = "ZO_TributeCard_TargetableUnderlay_Template",
    },
    [TRIBUTE_CARD_STATE_FLAGS_TARGETED] =
    {
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_OVERLAY] = "ZO_TributeCard_TargetedOverlay_Template",
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_UNDERLAY] = "ZO_TributeCard_TargetedUnderlay_Template",
    },
    [TRIBUTE_CARD_STATE_FLAGS_STACK_PLAYABLE] =
    {
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_OVERLAY] = "ZO_TributeCard_StackPlayableOverlay_Template",
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_UNDERLAY] = "ZO_TributeCard_StackPlayableUnderlay_Template",
    },
    [TRIBUTE_CARD_STATE_FLAGS_STACK_DAMAGEABLE] =
    {
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_OVERLAY] = "ZO_TributeCard_StackDamageableOverlay_Template",
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_UNDERLAY] = "ZO_TributeCard_StackDamageableUnderlay_Template",
    },
    [TRIBUTE_CARD_STATE_FLAGS_CALLOUT] =
    {
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_OVERLAY] = "ZO_TributeCard_CalloutOverlay_Template",
        [TRIBUTE_CARD_STATE_EFFECT_LAYER_UNDERLAY] = "ZO_TributeCard_CalloutUnderlay_Template",
    },
}

local TRIBUTE_PILE_TOOLTIP_BOARD_LOCATIONS =
{
    TRIBUTE_BOARD_LOCATION_OPPONENT_BOARD_ACTION,
    TRIBUTE_BOARD_LOCATION_OPPONENT_BOARD_AGENT,
    TRIBUTE_BOARD_LOCATION_OPPONENT_COOLDOWN,
    TRIBUTE_BOARD_LOCATION_OPPONENT_DECK,
    TRIBUTE_BOARD_LOCATION_PLAYER_BOARD_ACTION,
    TRIBUTE_BOARD_LOCATION_PLAYER_BOARD_AGENT,
    TRIBUTE_BOARD_LOCATION_PLAYER_COOLDOWN,
    TRIBUTE_BOARD_LOCATION_PLAYER_DECK,
}

-- Mechanic Container --

ZO_TributeCard_MechanicContainer = ZO_Tribute_PooledObject:Subclass()

function ZO_TributeCard_MechanicContainer:Initialize(control)
    self.control = control
    control.object = self
    self.frameTexture = control:GetNamedChild("Frame")
    self.typeIconTexture = control:GetNamedChild("TypeIcon")
    self.quantityLabel = control:GetNamedChild("Quantity")
end

do
    internalassert(TRIBUTE_MECHANIC_TRIGGER_ITERATION_END == 1, "A new Tribute mechanic trigger has been added. Please add it to the MECHANIC_TRIGGER_SUFFIX table")
    local MECHANIC_TRIGGER_SUFFIX =
    {
        [TRIBUTE_MECHANIC_TRIGGER_ACTIVATION] = "Activation",
        [TRIBUTE_MECHANIC_TRIGGER_COMBO] = "Combo",
    }

    internalassert(TRIBUTE_MECHANIC_ITERATION_END == 12, "A new Tribute mechanic has been added. Does the MECHANIC_PARAM_MODIFIERS need special modifiers for this mechanic?")
    local MECHANIC_PARAM_MODIFIERS =
    {
        [TRIBUTE_MECHANIC_HEAL_AGENT] =
        {
            quantityDisplayOverride =
            {
                displayParam = 1,
            }
        },
        [TRIBUTE_MECHANIC_ACQUIRE_CARDS] =
        {
            quantityDisplayOverride =
            {
                displayParam = 1,
            }
        },
    }

    local OFFSET_X = 42
    local LARGE_DOUBLE_DIGIT_OFFSET_X = 52
    local FIRST_TOP_OFFSET_Y = 135
    local LARGE_PADDING_Y = 15
    local SMALL_PADDING_Y = 10

    function ZO_TributeCard_MechanicContainer:Setup(cardObject, trigger, mechanicIndex)
        self.cardDefId = cardObject:GetCardDefId()
        self.trigger = trigger
        self.mechanicIndex = mechanicIndex
        self.tributeMechanicType, self.quantity, self.comboNum, self.param1, self.param2, self.param3 = cardObject:GetMechanicInfo(trigger, mechanicIndex)
        self.numSiblings = cardObject:GetNumMechanics(trigger)
        local isActivationTrigger = trigger == TRIBUTE_MECHANIC_TRIGGER_ACTIVATION
        local chooseOneMechanic = isActivationTrigger and cardObject:DoesChooseOneMechanic()
        if chooseOneMechanic then
            -- Quick and dirty workaround. The choice display isn't actually a mechanic, it replaces all of the mechanics on the card as one unified concept
            -- TODO Tribute: If we want to change to let design control which mechanics require choice, or work with combos, this logic will be useless and will need to be reimplemented
            if mechanicIndex == 1 then
                ApplyTemplateToControl(self.control, "ZO_TributeCard_MechanicContainer_Large_SingleDigit_Activation_Style")
                self.typeIconTexture:SetTexture("EsoUI/Art/Tribute/Mechanics/tributeMechanicCardDisplay_chooseOne.dds")
                self.quantityLabel:SetText(self.numSiblings)
                local offsetY = FIRST_TOP_OFFSET_Y + (MECHANIC_CONTAINER_LARGE_ACTIVATION_HEIGHT / 2)
                self.control:SetAnchor(CENTER, nil, TOPLEFT, OFFSET_X, offsetY)
            else
                self.control:SetHidden(true)
            end
            return
        end

        local isSmallContainer = self.numSiblings >= 4
        local triggerSuffix = MECHANIC_TRIGGER_SUFFIX[trigger]
        local sizeSuffix = isSmallContainer and "Small" or "Large"
        local quantityDisplayValue = self.quantity
        local paramModifiers = MECHANIC_PARAM_MODIFIERS[self.tributeMechanicType]
        if paramModifiers then
            local paramQuantityDisplayOverride = paramModifiers.quantityDisplayOverride
            if paramQuantityDisplayOverride then
                if paramQuantityDisplayOverride.displayParam == 1 then
                    quantityDisplayValue = self.param1
                elseif paramQuantityDisplayOverride.displayParam == 2 then
                    quantityDisplayValue = self.param2
                elseif paramQuantityDisplayOverride.displayFunction then
                    quantityDisplayValue = paramQuantityDisplayOverride.displayFunction(self.param1, self.param2)
                else
                    quantityDisplayValue = paramQuantityDisplayOverride[self.param1]
                end
            end
        end
        local isDoubleDigitContainer = quantityDisplayValue >= 10
        local digitsSuffix = isDoubleDigitContainer and "Double" or "Single"
        
        ApplyTemplateToControl(self.control, string.format("ZO_TributeCard_MechanicContainer_%s_%sDigit_%s_Style", sizeSuffix, digitsSuffix, triggerSuffix))
        self.typeIconTexture:SetTexture(GetTributeMechanicIconPath(self.tributeMechanicType, self.param1, self.param2, self.param3))
        local quantityDisplayText = quantityDisplayValue == 0 and GetString(SI_TRIBUTE_MECHANIC_ANY_QUANTITY_SYMBOL) or quantityDisplayValue
        self.quantityLabel:SetText(quantityDisplayText)
        self.frameGlowTextureFileName = string.format("EsoUI/Art/Tribute/Mechanics/tributeMechanicCardFrame_%s_%s_%s_glow.dds", triggerSuffix, sizeSuffix, digitsSuffix)
        
        local offsetX = OFFSET_X
        local height
        local paddingY
        if isSmallContainer then
            height = isActivationTrigger and MECHANIC_CONTAINER_SMALL_ACTIVATION_HEIGHT or MECHANIC_CONTAINER_SMALL_COMBO_HEIGHT
            paddingY = SMALL_PADDING_Y
        else
            height = isActivationTrigger and MECHANIC_CONTAINER_LARGE_ACTIVATION_HEIGHT or MECHANIC_CONTAINER_LARGE_COMBO_HEIGHT
            paddingY = LARGE_PADDING_Y
            if isDoubleDigitContainer then
                offsetX = LARGE_DOUBLE_DIGIT_OFFSET_X
            end
        end
        
        local firstCenterOffsetY = FIRST_TOP_OFFSET_Y + (height / 2)
        local offsetY = firstCenterOffsetY + ((height + paddingY) * (mechanicIndex - 1))
        if isActivationTrigger then
            self.control:SetAnchor(CENTER, nil, TOPLEFT, offsetX, offsetY)
        else
            self.control:SetAnchor(CENTER, nil, TOPRIGHT, -offsetX, offsetY)
        end
    end
end

function ZO_TributeCard_MechanicContainer:Reset()
    self:SetGlowHidden(true)

    self.cardDefId = nil
    self.trigger = nil
    self.mechanicIndex = nil
    self.tributeMechanicType = nil
    self.quantity = nil
    self.param1 = nil
    self.param2 = nil
    self.param3 = nil
    self.numSiblings = nil
    self.frameGlowTextureFileName = nil
end

function ZO_TributeCard_MechanicContainer:GetControl()
    return self.control
end

function ZO_TributeCard_MechanicContainer:GetFrameGlowTextureFileName()
    return self.frameGlowTextureFileName
end

function ZO_TributeCard_MechanicContainer:SetGlowHidden(hidden)
    if hidden then
        if self.frameGlowTexture then
            TRIBUTE_POOL_MANAGER:GetMechanicGlowPool():ReleaseObject(self.frameGlowTexture.key)
            self.frameGlowTexture = nil
        end
    else
        if not self.frameGlowTexture then
            self.frameGlowTexture = TRIBUTE_POOL_MANAGER:GetMechanicGlowPool():AcquireObject(self)
        end
    end
end

-- Card State Effect --

ZO_TributeCard_StateEffect = ZO_Tribute_PooledObject:Subclass()

function ZO_TributeCard_StateEffect:Initialize(control)
    self.control = control
    control.object = self

    local timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeCard_StateEffectTimeline")
    self.timeline = timeline
    timeline.object = self
    timeline:ApplyAllAnimationsToControl(self.control)

    self:Reset()
end

do
    -- Used for diversification of animation visuals.
    local nextAnimationOffset = 0
    local nextWaveAngle = math.rad(15)

    local MAX_ANIMATION_OFFSET = 1000
    local MAX_SHADER_PRECISION = 3600
    local WAVE_OFFSET_COEFFICIENT = 10
    local WAVE_ANGLE_INCREMENT = ZO_HALF_PI * 3

    function ZO_TributeCard_StateEffect:Setup(cardObject, cardState, cardLayer)
        self.cardObject = cardObject
        self.cardState = cardState
        self.cardLayer = cardLayer
        internalassert(self:IsValid(), "Tribute card state effect 'cardObject', 'cardState' or 'cardLayer' is invalid.")

        local control = self.control
        local controlTemplate = self:GetControlTemplate()
        ApplyTemplateToControl(control, controlTemplate)

        local alphaAnimation = self.timeline:GetAnimation(1)
        if cardLayer == TRIBUTE_CARD_STATE_EFFECT_LAYER_OVERLAY then
            alphaAnimation:SetEndAlpha(0.75)
        elseif cardLayer == TRIBUTE_CARD_STATE_EFFECT_LAYER_UNDERLAY then
            alphaAnimation:SetEndAlpha(1.0)
        end

        local parentControl = self.cardObject.frontControl
        control:SetParent(parentControl)
        control:ClearAnchors()
        control:SetAnchor(CENTER, parentControl)

        local animationOffset = nextAnimationOffset
        nextAnimationOffset = (nextAnimationOffset + 1) % MAX_ANIMATION_OFFSET

        local waveOffset = (animationOffset * WAVE_OFFSET_COEFFICIENT) % MAX_SHADER_PRECISION
        control:SetWaveOffset(waveOffset)
        local waveAngle = nextWaveAngle
        nextWaveAngle = (nextWaveAngle + WAVE_ANGLE_INCREMENT) % ZO_TWO_PI
        control:SetWaveAngle(waveAngle)

        control:SetHidden(false)
        self:SetActive(true)
    end
end

function ZO_TributeCard_StateEffect:Reset()
    self.control:SetHidden(true)
    self.timeline:Stop()

    self.cardObject = nil
    self.cardState = nil
    self.cardLayer = nil
end

function ZO_TributeCard_StateEffect:GetCardObject()
    return self.cardObject
end

function ZO_TributeCard_StateEffect:GetCardState()
    return self.cardState
end

function ZO_TributeCard_StateEffect:GetCardLayer()
    return self.cardLayer
end

function ZO_TributeCard_StateEffect:GetControlTemplate()
    local stateEffectTemplates = TRIBUTE_CARD_STATE_EFFECT_CONTROL_TEMPLATES[self.cardState]
    if not stateEffectTemplates then
        internalassert(false, string.format("No card state effect template configured for Tribute card state '%s'.", tostring(self.cardState) or "nil"))
    end
    local controlTemplate = stateEffectTemplates[self.cardLayer]
    if not controlTemplate then
        internalassert(false, string.format("Layer '%s' does not exist for card state effect template '%s'.", tostring(self.cardLayer) or "nil", tostring(self.cardState)))
    end
    return controlTemplate
end

function ZO_TributeCard_StateEffect:IsValid()
    return self.cardObject ~= nil and self.cardState ~= nil and self.cardLayer ~= nil
end

function ZO_TributeCard_StateEffect:IsActive()
    return not self.timeline:IsPlayingBackward() and (self.timeline:IsPlaying() or self.timeline:GetProgress() > 0)
end

function ZO_TributeCard_StateEffect:SetActive(active)
    if self:IsValid() and active ~= self:IsActive() then
        if active then
            self.timeline:PlayForward()
        else
            self.timeline:PlayBackward()
        end
    end
end

function ZO_TributeCard_StateEffect:OnStateEffectTimelineStopped(completedPlaying)
    if self:IsValid() then
        self.cardObject:OnStateEffectChanged(self, self:IsActive())
    end
end

-- Card --

ZO_TributeCard = ZO_InitializingObject:MultiSubclass(ZO_Tribute_PooledObject, ZO_TributeCardData)

function ZO_TributeCard:Initialize(control)
    ZO_TributeCardData.Initialize(self)

    self.control = control
    control.object = self

    local frontControl = control:GetNamedChild("Front")
    self.frontControl = frontControl
    self.bgGlowableTexture = frontControl:GetNamedChild("BG")
    self.portraitGlowableTexture = frontControl:GetNamedChild("Portrait")
    self.frameGlowableTexture = frontControl:GetNamedChild("Frame")
    self.suitGlowableTexture = frontControl:GetNamedChild("Suit")
    self.nameLabel = frontControl:GetNamedChild("Name")
    self.contractBannerTexture = frontControl:GetNamedChild("ContractBanner")
    self.costLabel = frontControl:GetNamedChild("Cost")
    self.costIconTexture = self.costLabel:GetNamedChild("Icon")
    self.defeatCostLabel = frontControl:GetNamedChild("DefeatCost")
    if self.defeatCostLabel then
        self.defeatCostBannerTexture = self.defeatCostLabel:GetNamedChild("Banner")
    end
    self.backGlowableTexture = control:GetNamedChild("Back")

    self.mechanicContainers = {}
    self.numMechanicsByTrigger = {}
    self.stateEffects = {}

    self:Reset()
end

function ZO_TributeCard:Setup(cardDefId, patronDefId, overrideSpace)
    ZO_TributeCardData.Setup(self, patronDefId, cardDefId)

    if overrideSpace and overrideSpace ~= self.control:GetParent():GetSpace() then
        self.control:SetSpace(overrideSpace)
    end

    self.popupType = nil

    self.control:SetScale(self:GetDefaultScale())
    if self:IsWorldCard() then
        self.control:SetAnchor(CENTER, GuiRoot)
    end

    local patronData = self:GetPatronData()
    local suitAtlasImage, suitAtlasGlowImage = patronData:GetSuitAtlas(self:GetCardType())
    local portraitImage, portraitGlowImage = self:GetPortrait()

    self.bgGlowableTexture:SetTexture(suitAtlasImage)
    self.bgGlowableTexture.glowTexture:SetTexture(suitAtlasGlowImage)
    self.suitGlowableTexture:SetTexture(suitAtlasImage)
    self.suitGlowableTexture.glowTexture:SetTexture(suitAtlasImage)
    self.portraitGlowableTexture:SetTexture(portraitImage)
    self.portraitGlowableTexture.glowTexture:SetTexture(portraitGlowImage)
    self.nameLabel:SetText(self:GetFormattedName())

    local isContract = self:IsContract()
    self.contractBannerTexture:SetHidden(not isContract)

    local costResourceType, costQuantity = self:GetAcquireCost()
    if costQuantity > 0 then
        self.costLabel:SetHidden(false)
        self.costLabel:SetText(costQuantity)
        local costTextureFile = self:GetAcquireCostTextureFile()
        self.costIconTexture:SetTexture(costTextureFile)
    else
        self.costLabel:SetHidden(true)
    end

    local defeatCostBannerTextureFile = self:GetDefeatCostTextureFile()
    if defeatCostBannerTextureFile then
        self.defeatCostBannerTexture:SetTexture(defeatCostBannerTextureFile)
    end

    self:UpdateDefeatCost()

    local mechanicContainerPool = TRIBUTE_POOL_MANAGER:GetMechanicContainerPool()
    for trigger = TRIBUTE_MECHANIC_TRIGGER_ITERATION_BEGIN, TRIBUTE_MECHANIC_TRIGGER_ITERATION_END do
        for mechanicIndex = 1, self.numMechanicsByTrigger[trigger] do
            local mechanicContainer = mechanicContainerPool:AcquireObject(self, trigger, mechanicIndex)
            table.insert(self.mechanicContainers, mechanicContainer)
        end
    end
end

function ZO_TributeCard:GetCardInstanceId()
    return self.cardInstanceId
end

function ZO_TributeCard:SetCardInstanceId(cardInstanceId)
    self.cardInstanceId = cardInstanceId
    self:UpdateDefeatCost()
    if self:IsWorldCard() then
        AssignControlToTributeCard(cardInstanceId, self.control)
    end
    self:OnStateFlagsChanged(GetTributeCardStateFlags(cardInstanceId))
end

function ZO_TributeCard:GetPopupType()
    return self.popupType
end

function ZO_TributeCard:SetPopupType(popupType)
    self.popupType = popupType
end

function ZO_TributeCard:PlayAlphaAnimation(playForward, animateInstantly)
    if animateInstantly then
        self:ReleaseAlphaAnimation()
        self:SetAlphaProgress(playForward and 1 or 0)
    else
        local timeline = self.alphaTimeline
        if not timeline then
            timeline = TRIBUTE_POOL_MANAGER:GetAlphaAnimationPool():AcquireObject()
            timeline:ApplyAllAnimationsToControl(self.control)
            timeline:PlayInstantlyToStart()
            timeline.cardObject = self
            self.alphaTimeline = timeline
        end

        if playForward then
            timeline:PlayForward()
        else
            timeline:PlayBackward()
        end
    end
end

function ZO_TributeCard:IsRevealed()
    return self.cardInstanceId and not self.frontControl:IsHidden()
end

function ZO_TributeCard:IsInterfaceCard()
    return self.control:GetSpace() == SPACE_INTERFACE
end

function ZO_TributeCard:IsWorldCard()
    return self.control:GetSpace() == SPACE_WORLD
end

function ZO_TributeCard:GetDefaultScale()
    return self:IsWorldCard() and ZO_TRIBUTE_CARD_WORLD_SCALE or 1
end

function ZO_TributeCard:GetScreenAnchor(anchor)
    return self.control:ProjectRectToScreenAndComputeAABBPoint(anchor)
end

function ZO_TributeCard:GetScreenCenter()
    return self.control:ProjectToScreen(0.5, 0.5)
end

function ZO_TributeCard:GetAnchorNearestScreenCenter()
    local anchor = ZO_GetAnchorPointNearestScreenCenter(self:GetScreenCenter())
    local screenX, screenY = self:GetScreenAnchor(anchor)
    return anchor, screenX, screenY
end

--- Override of ZO_TributeCardData ---
-- Returns resourceType, maxQuantity, currentQuantity
function ZO_TributeCard:GetDefeatCost()
    local resourceType, maxQuantity = GetTributeCardDefeatCost(self.cardDefId)
    local currentQuantity = maxQuantity
    if self.cardInstanceId then
        resourceType, currentQuantity = GetTributeCardInstanceDefeatCost(self.cardInstanceId)
    end
    return resourceType, maxQuantity, currentQuantity
end

function ZO_TributeCard:UpdateDefeatCost()
    if self:GetCardType() == TRIBUTE_CARD_TYPE_AGENT then
        local resourceType, maxQuantity, currentQuantity = self:GetDefeatCost()
        if resourceType ~= TRIBUTE_RESOURCE_POWER then
            assert(false, string.format("Card %d using invalid Defeat Cost type. No UI design for any defeat cost that isn't TRIBUTE_RESOURCE_POWER. If another type is desired, please contact a UI designer.", self.cardDefId))
        end

        self.defeatCostLabel:SetText(currentQuantity)
        local color = currentQuantity < maxQuantity and GetStatusEffectColor(STATUS_EFFECT_TYPE_WOUND) or ZO_WHITE
        self.defeatCostLabel:SetColor(color:UnpackRGB())
    end
end

-- Evaluates the effective state flags given the specified state flags or, if unspecified, the current state flags of the card.
function ZO_TributeCard:GetEffectiveStateFlags(currentStateFlags)
    local stateFlags = currentStateFlags or self.stateFlags
    local _, _, isStacked, isTopOfStack = self:GetStackInfo()

    if self:IsWorldCard() then
        if (isStacked and not isTopOfStack) or not TRIBUTE:CanInteractWithCards() then
            -- Suppress all flags for World space cards in a stack that are not the top card in that stack.
            -- Suppress all flags for World space cards while the pile viewer, target viewer or mechanic selector is open.
            stateFlags = 0
        end
    else
        if self:GetPopupType() == ZO_TRIBUTE_CARD_POPUP_TYPE.MECHANIC then
            -- Suppress all flags for a Mechanic tile's popup card.
            stateFlags = 0
        else
            -- Suppress stack-related flags for all Interface space cards.
            stateFlags = ZO_ClearMaskFlags(stateFlags, TRIBUTE_CARD_STATE_FLAGS_STACK_DAMAGEABLE, TRIBUTE_CARD_STATE_FLAGS_STACK_PLAYABLE)
        end
    end

    return stateFlags
end

function ZO_TributeCard:RefreshStateFlags()
    self:OnStateFlagsChanged(self.stateFlags)
end

function ZO_TributeCard:OnStateFlagsChanged(stateFlags)
    -- Cache the state flags in order to avoid unnecessary visual effect spawning/releasing.
    -- TODO Tribute: Reevaluate performance at a later point to see if this is still necessary.
    if not stateFlags then
        stateFlags = 0
    end

    self.stateFlags = stateFlags
    local effectiveStateFlags = self:GetEffectiveStateFlags(stateFlags)
    local flagValueChangesTable = ZO_CompareMaskFlags(self.effectiveStateFlags, effectiveStateFlags)
    if not flagValueChangesTable then
        return
    end

    self.effectiveStateFlags = effectiveStateFlags
    for stateFlag, active in pairs(flagValueChangesTable) do
        self:OnStateFlagChanged(stateFlag, active)
    end
end

function ZO_TributeCard:OnStateFlagChanged(stateFlag, active)
    if stateFlag == TRIBUTE_CARD_STATE_FLAGS_HIGHLIGHTED then
        -- Tribute highlight is handled directly via SetHighlighted.
        self:SetHighlighted(active)
        return
    end

    -- All other card states are managed using pooled state effects.
    local stateEffects = self.stateEffects[stateFlag]
    if stateEffects then
        for cardLayer, layerEffect in pairs(stateEffects) do
            -- If activating, reactivate an existing effect that is in the process of deactivating;
            -- if deactivating, effects will be released via the OnStateEffectChanged callback issued from the OnStop animation event.
            layerEffect:SetActive(active)
        end
    else
        if active then
            stateEffects = {}
            self.stateEffects[stateFlag] = stateEffects
            for _, cardLayer in ipairs(TRIBUTE_CARD_STATE_EFFECT_LAYERS) do
                -- Acquire an effect from the pool; effect activation is handled via the acquisition process.
                local layerEffect = TRIBUTE_POOL_MANAGER:GetCardStateEffectPool():AcquireObject(self, stateFlag, cardLayer)
                stateEffects[cardLayer] = layerEffect
            end
        end
    end
end

function ZO_TributeCard:OnStateEffectChanged(stateEffect, active)
    if not active then
        local cardState = stateEffect:GetCardState()
        if cardState then
            local stateEffects = self.stateEffects[cardState]
            if stateEffects then
                local cardLayer = stateEffect:GetCardLayer()
                local layerEffect = stateEffects[cardLayer]
                if layerEffect == stateEffect then
                    -- Release this effect.
                    stateEffects[cardLayer] = nil
                    layerEffect:ReleaseObject()

                    if not next(stateEffects) then
                        -- If no other layer effects exist for this state
                        -- remove the state table from self.stateEffects.
                        self.stateEffects[cardState] = nil
                    end
                end
            end
        end
    end
end

function ZO_TributeCard:Reset()
    self:HideBoardLocationPatronsTooltip()
    self:ReleaseAllObjects()

    local control = self.control
    control:SetClampedToScreen(false)
    control:SetClampedToScreenInsets(0, 0, 0, 0)
    control:ClearTransform()
    control:SetSpace(nil)
    control:SetAlpha(1)
    self.frontControl:SetHidden(false)
    self.backGlowableTexture:SetHidden(true)
    self:SetMouseEnabled(true)

    self.cardDefId = nil
    self.patronDefId = nil
    self.cardInstanceId = nil
    self.effectiveStateFlags = 0
    self.stateFlags = 0
    self.keyboardTooltipControl = nil
    self.gamepadTooltipControl = nil
end

function ZO_TributeCard:ReleaseAllObjects()
    self:ReleaseAlphaAnimation()
    self:ReleaseGlowAnimation()
    self:ReleaseMechanics()
    self:ReleasePopupAnimation()
    self:ReleaseStateEffects()
end

function ZO_TributeCard:ReleaseAlphaAnimation()
    local timeline = self.alphaTimeline
    if timeline then
        self.alphaTimeline = nil
        TRIBUTE_POOL_MANAGER:GetAlphaAnimationPool():ReleaseObject(timeline.key)
        self:SetAlphaProgress(1)
    end
end

function ZO_TributeCard:ReleaseGlowAnimation()
    local timeline = self.glowTimeline
    if timeline then
        self.glowTimeline = nil
        TRIBUTE_POOL_MANAGER:GetGlowAnimationPool():ReleaseObject(timeline.key)
        self:SetGlowProgress(0)
    end
end

function ZO_TributeCard:ReleaseMechanics()
    ZO_ClearTable(self.numMechanicsByTrigger)
    for _, mechanicContainer in ipairs(self.mechanicContainers) do
        mechanicContainer:ReleaseObject()
    end
    ZO_ClearNumericallyIndexedTable(self.mechanicContainers)
end

function ZO_TributeCard:ReleasePopupAnimation()
    local timeline = self.popupTimeline
    if timeline then
        self.popupTimeline = nil
        TRIBUTE_POOL_MANAGER:GetCardPopupAnimationPool():ReleaseObject(timeline.key)
        self:SetPopupProgress(1)
    end
end

function ZO_TributeCard:ReleaseStateEffects()
    for _, stateEffects in pairs(self.stateEffects) do
        for _, layerEffect in pairs(stateEffects) do
            layerEffect:ReleaseObject()
        end
    end
    ZO_ClearTable(self.stateEffects)
end

function ZO_TributeCard:GetStackInfo()
    if not self.cardInstanceId then
        return
    end
    
    local cardIndexInPile, numCardsInPile, isStacked = GetTributeCardPositionInPile(self.cardInstanceId)
    local isTopOfStack = isStacked and cardIndexInPile == numCardsInPile
    return cardIndexInPile, numCardsInPile, isStacked, isTopOfStack
end

function ZO_TributeCard:IsStacked()
    local _, _, isStacked = self:GetStackInfo()
    return isStacked == true
end

function ZO_TributeCard:GetBoardLocation()
    return self.cardInstanceId and GetTributeCardInstanceBoardLocation(self.cardInstanceId) or nil
end

function ZO_TributeCard:HideBoardLocationPatronsTooltip()
    if self.keyboardTooltipControl then
        ClearTooltipImmediately(self.keyboardTooltipControl)
        self.keyboardTooltipControl = nil
    end

    if self.gamepadTooltipControl then
        ZO_TributeBoardLocationPatronsTooltip_Gamepad_Hide()
        self.gamepadTooltipControl = nil
    end
end

function ZO_TributeCard:ShowBoardLocationPatronsTooltip()
    if not (self.cardInstanceId and self:IsWorldCard()) then
        return false
    end

    self:HideBoardLocationPatronsTooltip()

    local boardLocation = self:GetBoardLocation()
    if not ZO_IsElementInNumericallyIndexedTable(TRIBUTE_PILE_TOOLTIP_BOARD_LOCATIONS, boardLocation) then
        return false
    end

    local anchor, offsetX, offsetY
    local cardCenterX, _ = self:GetScreenCenter()
    local screenCenterX, _ = GuiRoot:GetCenter()

    -- The positioning of the tooltip is based on which half of the screen the card is on
    if cardCenterX > screenCenterX then
        offsetX, offsetY = self:GetScreenAnchor(LEFT)
        anchor = RIGHT
    else
        offsetX, offsetY = self:GetScreenAnchor(RIGHT)
        anchor = LEFT
    end

    if TRIBUTE:IsInputStyleMouse() then
        local control = NarrowTooltip
        InitializeTooltip(control, GuiRoot, anchor, offsetX, offsetY, TOPLEFT)
        control:SetTributeBoardLocationPatrons(boardLocation)
        self.keyboardTooltipControl = control

        return true
    elseif TRIBUTE:IsInputStyleGamepad() then
        local tooltipControl = ZO_TributeBoardLocationPatronsTooltip_Gamepad_GetControl()
        ZO_TributeBoardLocationPatronsTooltip_Gamepad_Show(boardLocation, anchor, GuiRoot, TOPLEFT, offsetX, offsetY)
        self.gamepadTooltipControl = tooltipControl

        return true
    end

    return false
end

function ZO_TributeCard:IsInteractive()
    if not (self.cardInstanceId and TRIBUTE:CanInteractWithCards()) then
        -- Suppress interaction for non-instanced cards or when the pile viewer, target viewer or mechanic selector is open.
        return false
    end

    local _, _, isStacked, isTopOfStack = self:GetStackInfo()
    if isStacked and not isTopOfStack then
        -- Suppress interaction for stacked cards that are not the top card in the stack.
        return false
    end

    return true
end

function ZO_TributeCard:OnCursorEnter()
    if self:IsInteractive() then
        SetHighlightedTributeCard(self.cardInstanceId)

        if self:IsStacked() then
            self:ShowBoardLocationPatronsTooltip(self.cardInstanceId)
        end
    end
end

function ZO_TributeCard:OnCursorExit()
    self:HideBoardLocationPatronsTooltip()

    if self.cardInstanceId then
        SetHighlightedTributeCard(NO_CARD)
    end
end

function ZO_TributeCard:OnMouseUp(button, upInside)
    if upInside and button == MOUSE_BUTTON_INDEX_LEFT and self.cardInstanceId then
        -- Don't allow interaction with cards while the target viewer is up
        if ZO_TRIBUTE_TARGET_VIEWER_MANAGER:IsViewingTargets() then
            return
        end
        InteractWithTributeCard(self.cardInstanceId)
    end
end

function ZO_TributeCard:IsCardStateActive(cardState)
    return ZO_MaskHasFlag(self.stateFlags, cardState)
end

function ZO_TributeCard:IsPlayable()
    return ZO_MaskHasFlag(self.stateFlags, TRIBUTE_CARD_STATE_FLAGS_PLAYABLE)
end

function ZO_TributeCard:IsDamageable()
    return ZO_MaskHasFlag(self.stateFlags, TRIBUTE_CARD_STATE_FLAGS_DAMAGEABLE)
end

function ZO_TributeCard:IsTargeted()
    return ZO_MaskHasFlag(self.stateFlags, TRIBUTE_CARD_STATE_FLAGS_TARGETED)
end

function ZO_TributeCard:IsHighlighted()
    return ZO_MaskHasFlag(self.stateFlags, TRIBUTE_CARD_STATE_FLAGS_HIGHLIGHTED)
end

function ZO_TributeCard:SetHighlighted(isHighlighted)
    local timeline = self.glowTimeline
    if isHighlighted then
        if not timeline then
            timeline = TRIBUTE_POOL_MANAGER:GetGlowAnimationPool():AcquireObject()
            timeline:ApplyAllAnimationsToControl(self.control)
            timeline:PlayInstantlyToStart()
            timeline.cardObject = self
            self.glowTimeline = timeline
        end
        timeline:PlayForward()
    else
        if timeline then
            timeline:PlayBackward()
        end
    end
end

function ZO_TributeCard:SetMouseEnabled(enabled)
    self.control:SetMouseEnabled(enabled)
end

function ZO_TributeCard:ShowAsPopup(screenX, screenY, popupType)
    local control = self.control
    local timeline = self.popupTimeline
    if not timeline then
        timeline = TRIBUTE_POOL_MANAGER:GetCardPopupAnimationPool():AcquireObject()
        timeline:ApplyAllAnimationsToControl(control)
        timeline:PlayInstantlyToStart()
        timeline.cardObject = self
        self.popupTimeline = timeline
    end
    timeline:PlayForward()

    self:SetMouseEnabled(false)
    control:SetAnchor(CENTER, GuiRoot, TOPLEFT, screenX, screenY)
    if ZO_TRIBUTE_TARGET_VIEWER_MANAGER:IsViewingTargets() then
        local bottom = IsInGamepadPreferredMode() and ZO_KEYBIND_STRIP_GAMEPAD_VISUAL_HEIGHT or ZO_KEYBIND_STRIP_KEYBOARD_VISUAL_HEIGHT
        control:SetClampedToScreenInsets(0, 0, 0, bottom)
    end
    control:SetClampedToScreen(true)
    control:SetHidden(false)

    self:SetPopupType(popupType)
end

function ZO_TributeCard:OnAlphaTimelineStopped(timeline)
    if timeline == self.alphaTimeline and timeline:IsPlayingBackward() then
        self:ReleaseAlphaAnimation()
    end
end

function ZO_TributeCard:OnGlowTimelineStopped(timeline)
    if timeline == self.glowTimeline and timeline:IsPlayingBackward() then
        self:ReleaseGlowAnimation()
    end
end

function ZO_TributeCard:SetAlphaProgress(alpha)
    self.control:SetAlpha(alpha)
    if self.cardInstanceId then
        SetTributeCardHidden(self.cardInstanceId, alpha < 1)
    end
end

function ZO_TributeCard:SetGlowProgress(progress)
    self.bgGlowableTexture.glowTexture:SetAlpha(progress)
    self.portraitGlowableTexture.glowTexture:SetAlpha(progress)
    self.frameGlowableTexture.glowTexture:SetAlpha(progress)
    self.suitGlowableTexture.glowTexture:SetAlpha(progress)
    self.backGlowableTexture.glowTexture:SetAlpha(progress)
end

function ZO_TributeCard:SetPopupProgress(progress)
    local maxScale = self:GetDefaultScale()
    local minScale = maxScale * 0.5
    self.control:SetScale(zo_lerp(minScale, maxScale, progress))
end

function ZO_TributeCard:GetControl()
    return self.control
end

function ZO_TributeCard:GetFrontControl()
    return self.frontControl
end

function ZO_TributeCard:GetScreenAnchorPosition(anchor)
    local screenX, screenY = self.control:ProjectRectToScreenAndComputeAABBPoint(anchor)
    return screenX, screenY
end

-- Global Functions --

function ZO_TributeCard_OnInitialized(...)
    ZO_TributeCard:New(...)
end

function ZO_TributeCard_AlphaTimeline_OnStop(timeline, completedPlaying)
    if timeline.cardObject then
        timeline.cardObject:OnAlphaTimelineStopped(timeline)
    end
end

function ZO_TributeCard_AlphaTimeline_SetProgress(animation, progress)
    local timeline = animation:GetTimeline()
    if timeline.cardObject then
        timeline.cardObject:SetAlphaProgress(progress)
    end
end

function ZO_TributeCard_GlowTimeline_OnStop(timeline, completedPlaying)
    if timeline.cardObject then
        timeline.cardObject:OnGlowTimelineStopped(timeline)
    end
end

function ZO_TributeCard_GlowTimeline_SetProgress(animation, progress)
    local timeline = animation:GetTimeline()
    if timeline.cardObject then
        timeline.cardObject:SetGlowProgress(progress)
    end
end

function ZO_TributeCard_MechanicContainer_OnInitialized(...)
    ZO_TributeCard_MechanicContainer:New(...)
end

function ZO_TributeCard_PopupTimeline_SetProgress(animation, progress)
    local timeline = animation:GetTimeline()
    if timeline.cardObject then
        timeline.cardObject:SetPopupProgress(progress)
    end
end

function ZO_TributeCard_StateEffect_OnInitialized(...)
    ZO_TributeCard_StateEffect:New(...)
end

function ZO_TributeCard_StateEffectTimeline_OnStop(timeline, completedPlaying)
    if timeline.object then
        timeline.object:OnStateEffectTimelineStopped(completedPlaying)
    end
end