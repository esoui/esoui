-- Card Alpha Animation Pool --

ZO_TributeCardAlphaAnimationPool = ZO_AnimationPool:Subclass()

function ZO_TributeCardAlphaAnimationPool:CreateObject(objectKey)
    local timeline = ZO_AnimationPool.CreateObject(self, objectKey)
    timeline.key = objectKey
    return timeline
end

function ZO_TributeCardAlphaAnimationPool:AcquireObject(cardObject, ...)
    local timeline, objectKey = ZO_AnimationPool.AcquireObject(self, ...)
    timeline.cardObject = cardObject
    return timeline, objectKey
end

-- Card Glow Animation Pool --

ZO_TributeCardGlowAnimationPool = ZO_AnimationPool:Subclass()

function ZO_TributeCardGlowAnimationPool:CreateObject(objectKey)
    local timeline = ZO_AnimationPool.CreateObject(self, objectKey)
    timeline.key = objectKey
    return timeline
end

function ZO_TributeCardGlowAnimationPool:AcquireObject(cardObject, ...)
    local timeline, objectKey = ZO_AnimationPool.AcquireObject(self, ...)
    timeline.cardObject = cardObject
    return timeline, objectKey
end

-- Card Mechanic Container Pool --

ZO_TributeCardMechanicContainerPool = ZO_ControlPool:Subclass()

function ZO_TributeCardMechanicContainerPool:CreateObject(objectKey)
    local control = ZO_ControlPool.CreateObject(self, objectKey)
    control.object:SetPoolAndKey(self, objectKey)
    return control
end

function ZO_TributeCardMechanicContainerPool:AcquireObject(cardObject, activationSource, mechanicIndex, ...)
    local control, objectKey = ZO_ControlPool.AcquireObject(self, ...)

    -- It's a control pool under the hood, for ease of creating the relationship between the control and the object,
    -- but consumers will want the object, not the control, to work with
    local object = control.object
    control:SetParent(cardObject:GetFrontControl())
    object:Setup(cardObject, activationSource, mechanicIndex)

    return object, objectKey
end

function ZO_TributeCardMechanicContainerPool:ResetObject(control)
    ZO_ControlPool.ResetObject(self, control)

    -- When waiting in the pool, parent to the pool's parent, instead of the card
    control:SetParent(self.parent)
    control.object:Reset()
end

-- Card Mechanic Glow Control Pool --

ZO_TributeCardMechanicGlowPool = ZO_ControlPool:Subclass()

function ZO_TributeCardMechanicGlowPool:CreateObject(objectKey)
    local control = ZO_ControlPool.CreateObject(self, objectKey)
    control.key = objectKey
    return control
end

function ZO_TributeCardMechanicGlowPool:AcquireObject(mechanicContainerObject, ...)
    local control, objectKey = ZO_ControlPool.AcquireObject(self, ...)
    local textureFileName = mechanicContainerObject:GetFrameGlowTextureFileName()
    control:SetTexture(textureFileName)
    control:SetParent(mechanicContainerObject:GetControl())
    control:SetAnchorFill()
    return control, objectKey
end

function ZO_TributeCardMechanicGlowPool:ResetObject(control)
    ZO_ControlPool.ResetObject(self, control)

    -- When waiting in the pool, parent to the pool's parent, instead of the card
    control:SetParent(self.parent)
    control:SetTexture(nil)
end

-- Card State Effect Pool --

ZO_TributeCardStateEffectPool = ZO_ControlPool:Subclass()

function ZO_TributeCardStateEffectPool:CreateObject(objectKey)
    local control = ZO_ControlPool.CreateObject(self, objectKey)
    control.object:SetPoolAndKey(self, objectKey)
    return control
end

function ZO_TributeCardStateEffectPool:AcquireObject(cardObject, cardState, cardLayer, ...)
    local control, objectKey = ZO_ControlPool.AcquireObject(self, ...)

    -- It's a control pool under the hood, for ease of creating the relationship between the control and the object,
    -- but consumers will want the object, not the control, to work with
    local object = control.object
    control:SetParent(cardObject:GetFrontControl())
    object:Setup(cardObject, cardState, cardLayer)

    return object, objectKey
end

function ZO_TributeCardStateEffectPool:ResetObject(control)
    ZO_ControlPool.ResetObject(self, control)

    -- When waiting in the pool, parent to the pool's parent, instead of the card
    control:SetParent(self.parent)
    control.object:Reset()
end

-- Card Popup Animation Pool --

ZO_TributeCardPopupAnimationPool = ZO_AnimationPool:Subclass()

function ZO_TributeCardPopupAnimationPool:CreateObject(objectKey)
    local timeline = ZO_AnimationPool.CreateObject(self, objectKey)
    timeline.key = objectKey
    return timeline
end

function ZO_TributeCardPopupAnimationPool:AcquireObject(cardObject, ...)
    local timeline, objectKey = ZO_AnimationPool.AcquireObject(self, ...)
    timeline.cardObject = cardObject
    return timeline, objectKey
end

-- Card Pool --

ZO_TributeCardPool = ZO_ControlPool:Subclass()

function ZO_TributeCardPool:CreateObject(objectKey)
    local control = ZO_ControlPool.CreateObject(self, objectKey)
    control.object:SetPoolAndKey(self, objectKey)
    return control
end

function ZO_TributeCardPool:AcquireObject(cardDefId, patronDefId, parentControl, overrideSpace, ...)
    local control, objectKey = ZO_ControlPool.AcquireObject(self, ...)

    -- It's a control pool under the hood, for ease of creating the relationship between the control and the object,
    -- but consumers will want the object, not the control, to work with
    local object = control.object
    if parentControl then
        control:SetParent(parentControl)
    end
    object:Setup(cardDefId, patronDefId, overrideSpace)

    return object, objectKey
end

function ZO_TributeCardPool:ResetObject(control)
    ZO_ControlPool.ResetObject(self, control)

    -- When waiting in the pool, parent to the pool's parent, instead of the card
    -- Order matters here, because we need to clear any space or transform changes before we reparent
    control.object:Reset()
    control:SetParent(self.parent)
end

-- Mechanic Card Tile Pool --

ZO_TributeMechanicCardTilePool = ZO_ControlPool:Subclass()

function ZO_TributeMechanicCardTilePool:CreateObject(objectKey)
    local control = ZO_ControlPool.CreateObject(self, objectKey)
    control.object:SetPoolAndKey(self, objectKey)
    return control
end

function ZO_TributeMechanicCardTilePool:AcquireObject(parentControl, cardInstanceId, mechanicActivationSource, mechanicIndex, isLocalPlayerOwner, quantity, isResolved, ...)
    local control, objectKey = ZO_ControlPool.AcquireObject(self, ...)

    -- It's a control pool under the hood, for ease of creating the relationship between the control and the object,
    -- but consumers will want the object, not the control, to work with
    local object = control.object
    object:Setup(parentControl, cardInstanceId, mechanicActivationSource, mechanicIndex, isLocalPlayerOwner, quantity, isResolved)
    return object, objectKey
end

function ZO_TributeMechanicCardTilePool:ResetObject(control)
    ZO_ControlPool.ResetObject(self, control)

    -- When waiting in the pool, parent to the pool's parent, instead of the card
    control:SetParent(self.parent)
    control.object:Reset()
end

-- Mechanic Patron Tile Pool --

ZO_TributeMechanicPatronTilePool = ZO_ControlPool:Subclass()

function ZO_TributeMechanicPatronTilePool:CreateObject(objectKey)
    local control = ZO_ControlPool.CreateObject(self, objectKey)
    control.object:SetPoolAndKey(self, objectKey)
    return control
end

function ZO_TributeMechanicPatronTilePool:AcquireObject(parentControl, patronDraftId, favorState, isPassive, mechanicIndex, isLocalPlayerOwner, quantity, isResolved, ...)
    local control, objectKey = ZO_ControlPool.AcquireObject(self, ...)

    -- It's a control pool under the hood, for ease of creating the relationship between the control and the object,
    -- but consumers will want the object, not the control, to work with
    local object = control.object
    object:Setup(parentControl, patronDraftId, favorState, isPassive, mechanicIndex, isLocalPlayerOwner, quantity, isResolved)
    return object, objectKey
end

function ZO_TributeMechanicPatronTilePool:ResetObject(control)
    ZO_ControlPool.ResetObject(self, control)

    -- When waiting in the pool, parent to the pool's parent, instead of the patron
    control:SetParent(self.parent)
    control.object:Reset()
end

-- Mechanic Tile Animation Pool --

ZO_TributeMechanicTileAnimationPool = ZO_AnimationPool:Subclass()

function ZO_TributeMechanicTileAnimationPool:CreateObject(objectKey)
    local timeline = ZO_AnimationPool.CreateObject(self, objectKey)
    timeline.key = objectKey
    return timeline
end

function ZO_TributeMechanicTileAnimationPool:AcquireObject(tileObject, animation, ...)
    local timeline, objectKey = ZO_AnimationPool.AcquireObject(self, ...)
    timeline.object = tileObject
    timeline.animation = animation
    return timeline, objectKey
end

function ZO_TributeMechanicTileAnimationPool:ResetObject(timeline)
    timeline.object = nil
    timeline.animation = nil
    timeline:PlayInstantlyToStart()
    ZO_AnimationPool.ResetObject(self, timeline)
end

-- Patron Requirement Container Pool --

ZO_TributePatronRequirementContainerPool = ZO_ControlPool:Subclass()

function ZO_TributePatronRequirementContainerPool:CreateObject(objectKey)
    local control = ZO_ControlPool.CreateObject(self, objectKey)
    control.object:SetPoolAndKey(self, objectKey)
    return control
end

function ZO_TributePatronRequirementContainerPool:AcquireObject(patronStallObject, favorState, requirementIndex, ...)
    local control, objectKey = ZO_ControlPool.AcquireObject(self, ...)

    -- It's a control pool under the hood, for ease of creating the relationship between the control and the object,
    -- but consumers will want the object, not the control, to work with
    local object = control.object
    control:SetParent(patronStallObject:GetRequirementsControl())
    object:Setup(patronStallObject, favorState, requirementIndex)

    return object, objectKey
end

function ZO_TributePatronRequirementContainerPool:ResetObject(control)
    ZO_ControlPool.ResetObject(self, control)

    -- When waiting in the pool, parent to the pool's parent, instead of the stall
    control:SetParent(self.parent)
    control.object:Reset()
end

-- Pool Manager --
-- This manager exists as a convenient way to keep track of all pools being used, and its control can be the parent instead of GuiRoot.
-- It also allows deferring the creation of the pools until all other XMLs load.

ZO_Tribute_PoolManager = ZO_InitializingObject:Subclass()

function ZO_Tribute_PoolManager:Initialize(control)
    self.control = control

    -- Alpha Animation Pool
    self.alphaAnimationPool = ZO_TributeCardGlowAnimationPool:New("ZO_TributeCard_AlphaTimeline")

    -- Glow Animation Pool
    self.glowAnimationPool = ZO_TributeCardGlowAnimationPool:New("ZO_TributeCard_GlowTimeline")

    -- Card Mechanic Control Pool
    self.mechanicContainerPool = ZO_TributeCardMechanicContainerPool:New("ZO_TributeCard_MechanicContainer_Template", control, "Mechanic")

    -- Card Mechanic Glow Control Pool
    self.mechanicGlowPool = ZO_TributeCardMechanicGlowPool:New("ZO_TributeCard_MechanicGlow_Template", control, "MechanicGlow")

    -- Card State Effect Control Pool
    self.cardStateEffectPool = ZO_TributeCardStateEffectPool:New("ZO_TributeCard_StateEffect_Template", control, "CardStateEffect")

    -- Card Trigger Animation Control Pool
    self.cardTriggerAnimationPool = ZO_TributeCardStateEffectPool:New("ZO_TributeCard_TriggerAnimation_Template", control, "CardTriggerAnimation")

    -- Card Popup Animation Pool
    self.cardPopupAnimationPool = ZO_TributeCardPopupAnimationPool:New("ZO_TributeCard_PopupTimeline")

    internalassert(TRIBUTE_CARD_TYPE_ITERATION_END == 1, "A new Tribute card type has been added. Please add a new template and control pool for it (e.g: ZO_TributeCard_Action)")
    -- Card Pools
    self.cardTypeToPool =
    {
        [TRIBUTE_CARD_TYPE_ACTION] = ZO_TributeCardPool:New("ZO_TributeCard_Action", control, "ActionCard"),
        [TRIBUTE_CARD_TYPE_AGENT] = ZO_TributeCardPool:New("ZO_TributeCard_Agent", control, "AgentCard"),
    }

    -- Mechanic Card Tile Player Control Pool
    self.mechanicCardTilePlayerPool = ZO_TributeMechanicCardTilePool:New("ZO_TributeMechanicCardTilePlayer", control, "TributeMechanicCardTilePlayer")

    -- Mechanic Card Tile Opponent Control Pool
    self.mechanicCardTileOpponentPool = ZO_TributeMechanicCardTilePool:New("ZO_TributeMechanicCardTileOpponent", control, "TributeMechanicCardTileOpponent")

    --Mechanic Patron Tile Player Control Pool
    self.mechanicPatronTilePlayerPool = ZO_TributeMechanicPatronTilePool:New("ZO_TributeMechanicPatronTilePlayer", control, "TributeMechanicPatronTilePlayer")

    --Mechanic Patron Tile Opponent Control Pool
    self.mechanicPatronTileOpponentPool = ZO_TributeMechanicPatronTilePool:New("ZO_TributeMechanicPatronTileOpponent", control, "TributeMechanicPatronTileOpponent")

    -- Mechanic Tile Animation Pool
    self.mechanicTileAnimationPool = ZO_TributeMechanicTileAnimationPool:New("ZO_TributeMechanicTile_Timeline")

    -- Patron Requirement Control Pool
    self.patronRequirementContainerPool = ZO_TributePatronRequirementContainerPool:New("ZO_TributePatronStall_RequirementContainer_Template", control, "Requirement")

    -- Stacked Card Back Texture Control Pool
    local function ResetStackedCardBack(stackedCardBack)
        stackedCardBack:SetHidden(true)
        stackedCardBack:ClearAnchors()
        stackedCardBack:SetParent(control)
        stackedCardBack:SetDrawLevel(0)
    end
    self.stackedCardBackTexturePool = ZO_ControlPool:New("ZO_TributeCard_StackedCardBack", control, "StackedCardBack")
    self.stackedCardBackTexturePool:SetCustomResetBehavior(ResetStackedCardBack)
end

function ZO_Tribute_PoolManager:GetAlphaAnimationPool()
    return self.alphaAnimationPool
end

function ZO_Tribute_PoolManager:GetGlowAnimationPool()
    return self.glowAnimationPool
end

function ZO_Tribute_PoolManager:GetMechanicContainerPool()
    return self.mechanicContainerPool
end

function ZO_Tribute_PoolManager:GetMechanicGlowPool()
    return self.mechanicGlowPool
end

function ZO_Tribute_PoolManager:GetCardStateEffectPool()
    return self.cardStateEffectPool
end

function ZO_Tribute_PoolManager:GetCardTriggerAnimationPool()
    return self.cardTriggerAnimationPool
end

function ZO_Tribute_PoolManager:GetCardPopupAnimationPool()
    return self.cardPopupAnimationPool
end

function ZO_Tribute_PoolManager:GetCardPool(cardType)
    return self.cardTypeToPool[cardType]
end

function ZO_Tribute_PoolManager:GetMechanicCardTilePlayerPool()
    return self.mechanicCardTilePlayerPool
end

function ZO_Tribute_PoolManager:GetMechanicCardTileOpponentPool()
    return self.mechanicCardTileOpponentPool
end

function ZO_Tribute_PoolManager:GetMechanicPatronTilePlayerPool()
    return self.mechanicPatronTilePlayerPool
end

function ZO_Tribute_PoolManager:GetMechanicPatronTileOpponentPool()
    return self.mechanicPatronTileOpponentPool
end

function ZO_Tribute_PoolManager:GetMechanicTileAnimationPool()
    return self.mechanicTileAnimationPool
end

function ZO_Tribute_PoolManager:AcquireCardByDefIds(cardDefId, patronDefId, parentControl, overrideSpace)
    local cardType = GetTributeCardType(cardDefId)
    local pool = self.cardTypeToPool[cardType]
    local cardObject = pool:AcquireObject(cardDefId, patronDefId, parentControl, overrideSpace)
    return cardObject
end

function ZO_Tribute_PoolManager:AcquireCardByInstanceId(cardInstanceId, parentControl, overrideSpace)
    -- Instance id based APIs are only available in the internal GUI
    if GetTributeCardInstanceDefIds then
        local cardDefId, patronDefId = GetTributeCardInstanceDefIds(cardInstanceId)
        local cardObject = self:AcquireCardByDefIds(cardDefId, patronDefId, parentControl, overrideSpace)
        cardObject:SetCardInstanceId(cardInstanceId)
        return cardObject
    end
    return nil
end

function ZO_Tribute_PoolManager:GetPatronRequirementContainerPool()
    return self.patronRequirementContainerPool
end

function ZO_Tribute_PoolManager:GetStackedCardBackTexturePool()
    return self.stackedCardBackTexturePool
end

function ZO_Tribute_PoolManager_OnInitialized(...)
    TRIBUTE_POOL_MANAGER = ZO_Tribute_PoolManager:New(...)
end