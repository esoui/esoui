ZO_TRIBUTE_MECHANIC_TILE_BACKDROP_ALPHA = 0.5
ZO_TRIBUTE_MECHANIC_TILE_PORTRAIT_UI_WIDTH = 48
ZO_TRIBUTE_MECHANIC_TILE_PORTRAIT_UI_HEIGHT = 64
ZO_TRIBUTE_MECHANIC_TILE_CONTAINER_UI_WIDTH = 70
ZO_TRIBUTE_MECHANIC_TILE_CONTAINER_UI_HEIGHT = ZO_TRIBUTE_MECHANIC_TILE_PORTRAIT_UI_HEIGHT
ZO_TRIBUTE_MECHANIC_TILE_BACKDROP_UI_HEIGHT = ZO_TRIBUTE_MECHANIC_TILE_CONTAINER_UI_HEIGHT + 6
ZO_TRIBUTE_MECHANIC_TILE_UI_HEIGHT = ZO_TRIBUTE_MECHANIC_TILE_BACKDROP_UI_HEIGHT + 8
ZO_TRIBUTE_MECHANIC_TILE_UI_WIDTH = 127
ZO_TRIBUTE_MECHANIC_HISTORY_FADE_GRADIENT_HEIGHT = ZO_TRIBUTE_MECHANIC_TILE_UI_HEIGHT * 2
ZO_TRIBUTE_MECHANIC_HISTORY_HEADING_UI_WIDTH = ZO_TRIBUTE_MECHANIC_TILE_UI_WIDTH
ZO_TRIBUTE_MECHANIC_CONTINUOUS_SCROLL_REGION_HEIGHT = ZO_TRIBUTE_MECHANIC_TILE_UI_HEIGHT
ZO_TRIBUTE_MECHANIC_CONTINUOUS_SCROLL_DISTANCE_PER_SECOND = ZO_TRIBUTE_MECHANIC_TILE_UI_HEIGHT * 4
local TRIBUTE_MECHANIC_TILE_PORTRAIT_DIMENSION_X = 256
local TRIBUTE_MECHANIC_TILE_PORTRAIT_DIMENSION_Y = 512
local TRIBUTE_MECHANIC_TILE_PORTRAIT_CROPPED_DIMENSION_X = 205
local TRIBUTE_MECHANIC_TILE_PORTRAIT_CROPPED_DIMENSION_Y = 274
local TRIBUTE_MECHANIC_TILE_PORTRAIT_CENTER_X = 128
local TRIBUTE_MECHANIC_TILE_PORTRAIT_CENTER_Y = 226
local TRIBUTE_MECHANIC_TILE_PORTRAIT_CENTER_X_COORD = TRIBUTE_MECHANIC_TILE_PORTRAIT_CENTER_X / TRIBUTE_MECHANIC_TILE_PORTRAIT_DIMENSION_X
local TRIBUTE_MECHANIC_TILE_PORTRAIT_CENTER_Y_COORD = TRIBUTE_MECHANIC_TILE_PORTRAIT_CENTER_Y / TRIBUTE_MECHANIC_TILE_PORTRAIT_DIMENSION_Y
local TRIBUTE_MECHANIC_TILE_PORTRAIT_HALF_X_COORD = TRIBUTE_MECHANIC_TILE_PORTRAIT_CROPPED_DIMENSION_X / TRIBUTE_MECHANIC_TILE_PORTRAIT_DIMENSION_X * 0.5
local TRIBUTE_MECHANIC_TILE_PORTRAIT_HALF_Y_COORD = TRIBUTE_MECHANIC_TILE_PORTRAIT_CROPPED_DIMENSION_Y / TRIBUTE_MECHANIC_TILE_PORTRAIT_DIMENSION_Y * 0.5
ZO_TRIBUTE_MECHANIC_TILE_PORTRAIT_BOTTOM_COORD = TRIBUTE_MECHANIC_TILE_PORTRAIT_CENTER_Y_COORD + TRIBUTE_MECHANIC_TILE_PORTRAIT_HALF_Y_COORD
ZO_TRIBUTE_MECHANIC_TILE_PORTRAIT_TOP_COORD = TRIBUTE_MECHANIC_TILE_PORTRAIT_CENTER_Y_COORD - TRIBUTE_MECHANIC_TILE_PORTRAIT_HALF_Y_COORD
ZO_TRIBUTE_MECHANIC_TILE_PORTRAIT_LEFT_COORD = TRIBUTE_MECHANIC_TILE_PORTRAIT_CENTER_X_COORD - TRIBUTE_MECHANIC_TILE_PORTRAIT_HALF_X_COORD
ZO_TRIBUTE_MECHANIC_TILE_PORTRAIT_RIGHT_COORD = TRIBUTE_MECHANIC_TILE_PORTRAIT_CENTER_X_COORD + TRIBUTE_MECHANIC_TILE_PORTRAIT_HALF_X_COORD

local PER_HISTORY_ENTRY_DELAY_MS = 375

local MECHANIC_TILE_ANIMATIONS =
{
    FOCUS_TILE =
    {
        durationMS = 150,
    },
    NEW_RESOLVED_TILE =
    {
        durationMS = 250,
    },
    NEW_UNRESOLVED_TILE =
    {
        durationMS = 250,
    },
    RESOLVE_TILE =
    {
        durationMS = 125,
    },
}

local g_BounceEase = ZO_GenerateCubicBezierEase(0.31, 1.2, 0.83, 1.1)

----------------------------
-- ZO_TributeMechanicTile --
----------------------------

ZO_TributeMechanicTile = ZO_Tribute_PooledObject:Subclass()

function ZO_TributeMechanicTile:Initialize(control)
    self.control = control
    self.backdropTexture = control:GetNamedChild("Backdrop")
    self.containerControl = control:GetNamedChild("Container")
    self.mechanicControl = self.containerControl:GetNamedChild("Mechanic")
    self.mechanicFrameTexture = self.mechanicControl:GetNamedChild("Frame")
    self.mechanicTypeIconTexture = self.mechanicControl:GetNamedChild("TypeIcon")
    self.mechanicQuantityLabel = self.mechanicControl:GetNamedChild("Quantity")
    self.patronTexture = self.containerControl:GetNamedChild("Patron")
    self.portraitTexture = self.containerControl:GetNamedChild("Portrait")
    self.portraitFrameTexture = self.portraitTexture:GetNamedChild("Frame")
    self.timelines = {}

    self:Reset()
end

function ZO_TributeMechanicTile:SetSaturation(saturation)
    local quadraticEase = ZO_EaseInQuadratic(saturation)
    self.backdropTexture:SetAlpha(zo_lerp(0, 0.65, quadraticEase))

    local desaturation = zo_lerp(0.5, 0, quadraticEase)
    self.portraitFrameTexture:SetDesaturation(desaturation)
    self.mechanicFrameTexture:SetDesaturation(desaturation)
    self.mechanicTypeIconTexture:SetDesaturation(desaturation)
    self.patronTexture:SetDesaturation(desaturation)
    self.portraitTexture:SetDesaturation(desaturation)
end

function ZO_TributeMechanicTile:GetCardAndPatronDef()
    local cardDefId, patronDefId = GetTributeCardInstanceDefIds(self.cardInstanceId)
    return cardDefId, patronDefId
end

function ZO_TributeMechanicTile:GetControl()
    return self.control
end

function ZO_TributeMechanicTile:GetControlDimensions()
    return self.control:GetDimensions()
end

function ZO_TributeMechanicTile:GetIconTextureFile()
    return GetTributeMechanicIconPath(self.mechanicType, self.param1, self.param2, self.param3)
end

function ZO_TributeMechanicTile:GetQuantity()
    return self.quantity
end

function ZO_TributeMechanicTile:SetQuantity(quantity)
    self.quantity = quantity

    local quantityString = quantity
    if quantity == 0 and not self.isResolved then
        quantityString = GetString(SI_TRIBUTE_MECHANIC_ANY_QUANTITY_SYMBOL)
    end
    self.mechanicQuantityLabel:SetText(quantityString)
end

function ZO_TributeMechanicTile:IsLocalPlayerOwner()
    return self.isLocalPlayerOwner
end

function ZO_TributeMechanicTile:SetPredecessorTileControl(control)
    self.predecessorTileControl = control
end

function ZO_TributeMechanicTile:HideCardPopupAndTooltip()
    if self.cardPopup then
        self.cardPopup:ReleaseObject()
        self.cardPopup = nil

        local OFFSET_MS = 0
        local REVERSE_PLAYBACK = true
        self:PlayAnimation(MECHANIC_TILE_ANIMATIONS.FOCUS_TILE, OFFSET_MS, REVERSE_PLAYBACK)
    end

    if self.cardTooltipControlGamepad then
        ZO_TributeCardTooltip_Gamepad_Hide()
        self.cardTooltipControlGamepad = nil
    end

    if self.cardTooltipControlKeyboard then
        ClearTooltipImmediately(self.cardTooltipControlKeyboard)
        self.cardTooltipControlKeyboard = nil
    end
end

function ZO_TributeMechanicTile:PlayAnimation(animation, offsetMS, reversePlayback, retainAnimation)
    local timeline = self.timelines[animation]
    if not timeline then
        timeline = TRIBUTE_POOL_MANAGER:GetMechanicTileAnimationPool():AcquireObject(self, animation)
        self.timelines[animation] = timeline
    end

    local animationControl = timeline:GetFirstAnimation()
    local durationMS = animation.durationMS
    animationControl:SetDuration(durationMS)

    timeline:SetAllAnimationOffsets(offsetMS or 0)
    timeline:ApplyAllAnimationsToControl(self.control)

    timeline.retainAnimation = retainAnimation
    timeline.reversePlayback = reversePlayback
    if reversePlayback then
        timeline:PlayBackward()
    else
        timeline:PlayForward()
    end
end

function ZO_TributeMechanicTile:ReleaseAnimation(animation)
    local timeline = self.timelines[animation]
    if timeline then
        self:ReleaseTimeline(animation, timeline)
    end
end

function ZO_TributeMechanicTile:ReleaseTimeline(animation, timeline)
    timeline.object = nil
    timeline:PlayInstantlyToStart()
    TRIBUTE_POOL_MANAGER:GetMechanicTileAnimationPool():ReleaseObject(timeline.key)
    self.timelines[animation] = nil
end

function ZO_TributeMechanicTile:ReleaseTimelines()
    for animation, timeline in pairs(self.timelines) do
        self:ReleaseTimeline(animation, timeline)
    end
end

function ZO_TributeMechanicTile:Reset()
    self:HideCardPopupAndTooltip()

    self.cardInstanceId = nil
    self.comboNumber = nil
    self.isResolved = nil
    self.mechanicIndex = nil
    self.mechanicTrigger = nil
    self.mechanicType = nil
    self.param1 = nil
    self.param2 = nil
    self.param3 = nil
    self.predecessorTileControl = nil
    self.quantity = nil

    self:ReleaseTimelines()
end

function ZO_TributeMechanicTile:Resolve(animationOffsetMS)
    self.isResolved = true
    self:PlayAnimation(MECHANIC_TILE_ANIMATIONS.RESOLVE_TILE, animationOffsetMS)
end

function ZO_TributeMechanicTile:SetPosition(offsetX, offsetY)
    local control = self.control

    if offsetX then
        local valid, point, relativeTo, relativePoint = control:GetAnchor(0)
        control:SetAnchor(point, relativeTo, relativePoint, offsetX, nil, ANCHOR_CONSTRAINS_X)
    end

    if offsetY then
        local valid, point, relativeTo, relativePoint = control:GetAnchor(1)
        control:SetAnchor(point, relativeTo, relativePoint, nil, offsetY, ANCHOR_CONSTRAINS_Y)
    end
end

function ZO_TributeMechanicTile:Setup(parentControl, cardInstanceId, mechanicTrigger, mechanicIndex, isLocalPlayerOwner, quantity, isResolved)
    self.cardInstanceId = cardInstanceId
    self.isLocalPlayerOwner = isLocalPlayerOwner
    self.mechanicIndex = mechanicIndex
    self.mechanicTrigger = mechanicTrigger
    self.isResolved = isResolved
    self:SetQuantity(quantity)

    local cardDefId, patronDefId = self:GetCardAndPatronDef()
    local cardData = ZO_TributeCardData:New(patronDefId, cardDefId)
    local patronData = cardData:GetPatronData()
    local unusedQuantity = nil
    self.mechanicType, unusedQuantity, self.comboNumber, self.param1, self.param2, self.param3 = GetTributeCardMechanicInfo(cardDefId, self.mechanicTrigger, self.mechanicIndex)

    local digitsSuffix = quantity >= 10 and "Double" or "Single"
    local triggerSuffix = mechanicTrigger == TRIBUTE_MECHANIC_TRIGGER_COMBO and "Combo" or "Activation"
    local mechanicControlTemplate = string.format("ZO_TributeCard_MechanicContainer_Small_%sDigit_%s_Style", digitsSuffix, triggerSuffix)
    ApplyTemplateToControl(self.mechanicControl, mechanicControlTemplate)
    self.mechanicTypeIconTexture:SetTexture(self:GetIconTextureFile())

    local suitAtlasImage, suitAtlasGlowImage = patronData:GetSuitAtlas(cardData:GetCardType())
    self.patronTexture:SetTexture(suitAtlasImage)

    local portraitImage = cardData:GetPortrait()
    self.portraitTexture:SetTexture(portraitImage)

    self:SetSaturation(0)
    self.containerControl:SetScale(1)
    self.control:SetParent(parentControl)
    self.control:SetHidden(false)
end

function ZO_TributeMechanicTile:Show(animationOffsetMS, isResolved)
    if isResolved then
        self.isResolved = true
        self:PlayAnimation(MECHANIC_TILE_ANIMATIONS.NEW_RESOLVED_TILE, animationOffsetMS)
    else
        self:PlayAnimation(MECHANIC_TILE_ANIMATIONS.NEW_UNRESOLVED_TILE, animationOffsetMS)
    end
end

function ZO_TributeMechanicTile:ShowCardPopupAndTooltip()
    self:HideCardPopupAndTooltip()

    local isGamepadMode = TRIBUTE:IsInputStyleGamepad()
    local isMouseMode = TRIBUTE:IsInputStyleMouse()
    if not (isGamepadMode or isMouseMode) then
        return
    end

    local cardPopup = TRIBUTE_POOL_MANAGER:AcquireCardByInstanceId(self.cardInstanceId, TRIBUTE_MECHANIC_MANAGER:GetControl(), SPACE_INTERFACE)
    self.cardPopup = cardPopup

    local VERTICAL_MARGIN = 0
    local _, top = self.control:GetCenter()
    cardPopup:ShowAsPopup(ZO_TRIBUTE_MECHANIC_TILE_UI_WIDTH, top, ZO_TRIBUTE_CARD_POPUP_TYPE.MECHANIC)
    cardPopup:SetMechanicGlowHidden(self.mechanicTrigger, self.mechanicIndex, false)

    if isMouseMode then
        local tooltipControl = ItemTooltip
        InitializeTooltip(tooltipControl, cardPopup:GetControl(), LEFT, HORIZONTAL_MARGIN, VERTICAL_MARGIN, RIGHT)
        tooltipControl:SetTributeCard(cardPopup:GetPatronDefId(), cardPopup:GetCardDefId())
        self.cardTooltipControlKeyboard = tooltipControl
    elseif isGamepadMode then
        local tooltipControl = ZO_TributeCardTooltip_Gamepad_GetControl()
        ZO_TributeCardTooltip_Gamepad_Show(cardPopup, LEFT, cardPopup:GetControl(), RIGHT, HORIZONTAL_MARGIN, VERTICAL_MARGIN)
        self.cardTooltipControlGamepad = tooltipControl
    end

    local OFFSET_MS = 0
    local FORWARD_PLAYBACK = false
    local RETAIN_ANIMATION = true
    self:PlayAnimation(MECHANIC_TILE_ANIMATIONS.FOCUS_TILE, OFFSET_MS, FORWARD_PLAYBACK, RETAIN_ANIMATION)
end

function ZO_TributeMechanicTile:OnCursorEnter()
    self:ShowCardPopupAndTooltip()
    -- TODO Tribute: Consider highlighting the card instance on the table as well? Would require an exception for non-top-of-stack cards or a different state altogether.
end

function ZO_TributeMechanicTile:OnCursorExit()
    self:HideCardPopupAndTooltip()
end

function ZO_TributeMechanicTile:OnMouseEnter()
    if not IsInGamepadPreferredMode() then
        self:ShowCardPopupAndTooltip()
    end
end

function ZO_TributeMechanicTile:OnTimelineStop(timeline, completedPlaying)
    if timeline.object and not timeline.retainAnimation then
        if (not timeline.reversePlayback and completedPlaying) or (timeline.reversePlayback and not completedPlaying) then
            self.timelines[timeline] = nil
            TRIBUTE_POOL_MANAGER:GetMechanicTileAnimationPool():ReleaseObject(timeline.key)
        end
    end
end

function ZO_TributeMechanicTile:OnTimelineUpdate(timeline, progress)
    local animation = timeline.animation
    if animation == MECHANIC_TILE_ANIMATIONS.NEW_RESOLVED_TILE or animation == MECHANIC_TILE_ANIMATIONS.NEW_UNRESOLVED_TILE then
        local quadraticProgress = ZO_EaseOutQuadratic(progress)
        local control = self.control
        control:SetAlpha(quadraticProgress)

        local bouncedProgress = g_BounceEase(progress)
        local offsetX = zo_floor(ZO_TRIBUTE_MECHANIC_TILE_UI_WIDTH * bouncedProgress) - 15
        self:SetPosition(offsetX)

        if animation == MECHANIC_TILE_ANIMATIONS.NEW_UNRESOLVED_TILE then
            self.containerControl:SetScale(zo_lerp(0.2, 1.15, bouncedProgress))
            self:SetSaturation(progress)
        else
            self.containerControl:SetScale(zo_lerp(1.5, 1, bouncedProgress))
        end

        local predecessorControl = self.predecessorTileControl
        if predecessorControl then
            local predecessorProgress = zo_clamp(progress * 1.25, 0, 1)
            local offsetY = zo_floor(zo_lerp(0, ZO_TRIBUTE_MECHANIC_TILE_UI_HEIGHT, ZO_EaseOutQuadratic(predecessorProgress)))
            local CURRENT_OFFSET_X = nil
            predecessorControl.object:SetPosition(CURRENT_OFFSET_X, offsetY)
        end
    elseif animation == MECHANIC_TILE_ANIMATIONS.FOCUS_TILE then
        local minSaturation = self.isResolved and 0 or 1
        self:SetSaturation(zo_max(progress, minSaturation))
    elseif animation == MECHANIC_TILE_ANIMATIONS.RESOLVE_TILE then
        self:SetSaturation(1 - progress)

        local bouncedProgress = g_BounceEase(progress)
        self.containerControl:SetScale(zo_lerp(1.15, 1, bouncedProgress))
    end
end

--------------------------------
-- Tribute Triggered Mechanic --
--------------------------------

ZO_TributeTriggeredMechanic = ZO_InitializingObject:Subclass()

function ZO_TributeTriggeredMechanic:Initialize(mechanicTrigger, mechanicIndex, quantity, isResolved)
    self.mechanicTrigger = mechanicTrigger
    self.mechanicIndex = mechanicIndex
    self.isPresenting = false
    self.isResolved = isResolved
    self.quantity = quantity
end

function ZO_TributeTriggeredMechanic:Equals(mechanicTrigger, mechanicIndex)
    return self.mechanicTrigger == mechanicTrigger and self.mechanicIndex == mechanicIndex
end

function ZO_TributeTriggeredMechanic:GetMechanicTriggerAndIndex()
    return self.mechanicTrigger, self.mechanicIndex
end

function ZO_TributeTriggeredMechanic:GetQuantity()
    return self.quantity
end

function ZO_TributeTriggeredMechanic:SetQuantity(quantity)
    self.quantity = quantity
end

function ZO_TributeTriggeredMechanic:IsPresenting()
    return self.isPresenting
end

function ZO_TributeTriggeredMechanic:SetIsPresenting(isPresenting)
    self.isPresenting = isPresenting
end

function ZO_TributeTriggeredMechanic:IsResolved()
    return self.isResolved
end

function ZO_TributeTriggeredMechanic:SetIsResolved(isResolved)
    self.isResolved = isResolved
end

----------------------------------
-- Tribute Mechanic Queue Entry --
----------------------------------

ZO_TributeMechanicQueueEntry = ZO_InitializingObject:Subclass()

function ZO_TributeMechanicQueueEntry:Initialize(cardInstanceId, isLocalPlayerOwner)
    self.cardInstanceId = cardInstanceId
    self.cardDefId, self.patronDefId = GetTributeCardInstanceDefIds(cardInstanceId)
    self.isLocalPlayerOwner = isLocalPlayerOwner
    self.triggeredMechanics = {}
end

function ZO_TributeMechanicQueueEntry:AddTriggeredMechanic(triggeredMechanic)
    table.insert(self.triggeredMechanics, triggeredMechanic)
end

function ZO_TributeMechanicQueueEntry:FindTriggeredMechanic(mechanicTrigger, mechanicIndex)
    for _, triggeredMechanic in ipairs(self.triggeredMechanics) do
        if triggeredMechanic:Equals(mechanicTrigger, mechanicIndex) then
            return triggeredMechanic
        end
    end

    return nil
end

function ZO_TributeMechanicQueueEntry:GetCardInstanceId()
    return self.cardInstanceId
end

function ZO_TributeMechanicQueueEntry:GetCardDefId()
    return self.cardDefId
end

function ZO_TributeMechanicQueueEntry:GetPatronDefId()
    return self.patronDefId
end

function ZO_TributeMechanicQueueEntry:GetTriggeredMechanics()
    return self.triggeredMechanics
end

function ZO_TributeMechanicQueueEntry:IsLocalPlayerOwner()
    return self.isLocalPlayerOwner
end

function ZO_TributeMechanicQueueEntry:IsPresenting()
    return self.isPresenting
end

function ZO_TributeMechanicQueueEntry:SetIsPresenting(isPresenting)
    self.isPresenting = isPresenting
end

------------------------------
-- Tribute Mechanic Manager --
------------------------------

ZO_TributeMechanic_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_TributeMechanic_Manager:AddMechanicHistory(cardInstanceId, mechanicTrigger, mechanicIndex, isLocalPlayerOwner, quantity, isResolved)
    local controlPool = isLocalPlayerOwner and TRIBUTE_POOL_MANAGER:GetMechanicTilePlayerPool() or TRIBUTE_POOL_MANAGER:GetMechanicTileOpponentPool()
    local tileObject = controlPool:AcquireObject(self.scrollChildControl, cardInstanceId, mechanicTrigger, mechanicIndex, isLocalPlayerOwner, quantity, isResolved)
    local tileControl = tileObject:GetControl()
    table.insert(self.history, tileObject)

    tileControl:ClearAnchors()
    tileControl:SetAnchor(LEFT, nil, nil, -tileControl:GetWidth(), nil, ANCHOR_CONSTRAINS_X)
    tileControl:SetAnchor(CENTER, self.scrollChildControl, TOP, nil, ZO_TRIBUTE_MECHANIC_TILE_UI_HEIGHT * 0.5 + 10, ANCHOR_CONSTRAINS_Y)
    tileControl:SetScale(1)

    if self.headAnchorControl then
        self.headAnchorControl:SetAnchor(CENTER, tileControl, CENTER, nil, nil, ANCHOR_CONSTRAINS_Y)
        tileObject:SetPredecessorTileControl(self.headAnchorControl)
    end
    self.headAnchorControl = tileControl

    local NO_ANIMATION_OFFSET_MS = 0
    tileObject:Show(NO_ANIMATION_OFFSET_MS, isResolved)
    if self:CanScrollToTop() then
        self:ScrollToTop()
    end

    self:SetHeadingHidden(false)
    self:SetLastMechanicTile(tileObject)
    PlaySound(SOUNDS.TRIBUTE_COMBO_TRIGGERED)
    return tileObject
end

function ZO_TributeMechanic_Manager:AdjustVerticalScrollOffset(offset)
    local _, currentVerticalOffset = self.scrollControl:GetScrollOffsets()
    local _, currentHeight = self.scrollControl:GetScrollExtents()
    local newVerticalOffset = zo_clamp(currentVerticalOffset + offset, 0, currentHeight)
    self.scrollControl:SetVerticalScroll(newVerticalOffset)
    self:UpdateScrollFadeGradient()
end

function ZO_TributeMechanic_Manager:CanScrollToTop()
    return not self.isScrollOffsetLocked
end

function ZO_TributeMechanic_Manager:GetControl()
    return self.control
end

function ZO_TributeMechanic_Manager:GetLastMechanicTile()
    return self.lastMechanicTile
end

function ZO_TributeMechanic_Manager:SetLastMechanicTile(mechanicTile)
    self.lastMechanicTile = mechanicTile
end

function ZO_TributeMechanic_Manager:Initialize(control)
    self.control = control
    control.object = self

    self.gameState = TRIBUTE_GAME_FLOW_STATE_INACTIVE
    self.gamepadCursorX, self.gamepadCursorY = 0, 0
    self.mouseCursorX, self.mouseCursorY = 0, 0
    self.history = {}
    self.queue = {}

    self:InitializeControls()
    self:InitializeEvents()
    self:Reset()
end

function ZO_TributeMechanic_Manager:InitializeControls()
    local control = self.control
    self.headingLabel = control:GetNamedChild("Heading")
    self.showHeadingTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributeMechanicHistory_ShowTimeline", self.headingLabel)
    self:SetHeadingHidden(true)

    self.scrollControl = control:GetNamedChild("Scroll")
    self.scrollChildControl = self.scrollControl:GetNamedChild("Child")

    local KEYBOARD_PLATFORM_STYLE =
    {
        headingLabel = "ZoFontWinH3",
    }

    local GAMEPAD_PLATFORM_STYLE =
    {
        headingLabel = "ZoFontGamepadBold27",
    }

    local function ApplyPlatformStyle(style)
        self.headingLabel:SetFont(style.headingLabel)
    end

    self.platformStyle = ZO_PlatformStyle:New(function(style) ApplyPlatformStyle(style) end, KEYBOARD_PLATFORM_STYLE, GAMEPAD_PLATFORM_STYLE)
end

function ZO_TributeMechanic_Manager:InitializeEvents()
    local function OnCardMechanicResolutionStateChanged(_, ...)
        self:OnCardMechanicResolutionStateChanged(...)
    end

    EVENT_MANAGER:RegisterForEvent("ZO_TributeMechanic_Manager", EVENT_TRIBUTE_CARD_MECHANIC_RESOLUTION_STATE_CHANGED, OnCardMechanicResolutionStateChanged)

    local function OnGameStateChanged(_, ...)
        self:OnGameStateChanged(...)
    end

    EVENT_MANAGER:RegisterForEvent("ZO_TributeMechanic_Manager", EVENT_TRIBUTE_GAME_FLOW_STATE_CHANGE, OnGameStateChanged)

    local function OnPlayerTurnStarted(_, ...)
        self:OnPlayerTurnStarted(...)
    end

    EVENT_MANAGER:RegisterForEvent("ZO_TributeMechanic_Manager", EVENT_TRIBUTE_PLAYER_TURN_STARTED, OnPlayerTurnStarted)

    local function OnScrollExtentsChanged(...)
        self:OnScrollExtentsChanged()
    end

    self.scrollControl:SetHandler("OnScrollExtentsChanged", OnScrollExtentsChanged)
end

function ZO_TributeMechanic_Manager:OnScrollExtentsChanged()
    local _, currentHeight = self.scrollControl:GetScrollExtents()
    local previousHeight= self.previousScrollHeight or currentHeight
    self.previousScrollHeight = currentHeight

    if self.isScrollOffsetLocked then
        local delta = currentHeight - previousHeight
        if delta ~= 0 then
            self:AdjustVerticalScrollOffset(delta)
        end
    end

    self:UpdateScrollFadeGradient()
end

function ZO_TributeMechanic_Manager:IsLocalPlayersTurn()
    return self.isLocalPlayersTurn == true
end

function ZO_TributeMechanic_Manager:QueueMechanic(cardInstanceId, isLocalPlayerOwner, mechanicTrigger, mechanicIndex, quantity, isResolved)
    if mechanicTrigger ~= TRIBUTE_MECHANIC_TRIGGER_COMBO then
        -- Only Combo Mechanic activation tiles should appear in the history.
        return
    end

    for _, queueEntry in ipairs(self.queue) do
        -- Queue unique mechanics for the same player and card instance together.
        if cardInstanceId == queueEntry:GetCardInstanceId() and isLocalPlayerOwner == queueEntry:IsLocalPlayerOwner() then
            local triggeredMechanic = queueEntry:FindTriggeredMechanic(mechanicTrigger, mechanicIndex)
            if triggeredMechanic then
                -- This triggered mechanic has already been queued in this queue entry.
                if isResolved and not triggeredMechanic:IsResolved() then
                    -- This triggered mechanic was previously unresolved and can now be resolved with its final quantity.
                    triggeredMechanic:SetIsResolved(true)
                    triggeredMechanic:SetQuantity(quantity)
                    return
                end
            elseif not queueEntry:IsPresenting() then
                -- This queue entry has not yet begun presentation; append this triggered mechanic to the entry.
                triggeredMechanic = ZO_TributeTriggeredMechanic:New(mechanicTrigger, mechanicIndex, quantity, isResolved)
                queueEntry:AddTriggeredMechanic(triggeredMechanic)
                return
            end
        end
    end

    -- This triggered mechanic could not be added to any existing queue entries; create a new entry and add this mechanic to the entry.
    local newQueueEntry = ZO_TributeMechanicQueueEntry:New(cardInstanceId, isLocalPlayerOwner)
    local triggeredMechanic = ZO_TributeTriggeredMechanic:New(mechanicTrigger, mechanicIndex, quantity, isResolved)
    newQueueEntry:AddTriggeredMechanic(triggeredMechanic)
    table.insert(self.queue, newQueueEntry)
end

function ZO_TributeMechanic_Manager:Reset()
    -- Order matters
    self:SetContinuousScrollingEnabled(false)
    self:SetVerticalScrollOffsetLocked(false)

    self:SetLastMechanicTile(nil)
    self:ResetHistory()
    self:ResetQueue()
end

function ZO_TributeMechanic_Manager:ResetHistory()
    self.headAnchorControl = nil
    self:SetHeadingHidden(true)

    TRIBUTE_POOL_MANAGER:GetMechanicTilePlayerPool():ReleaseAllObjects()
    TRIBUTE_POOL_MANAGER:GetMechanicTileOpponentPool():ReleaseAllObjects()
    ZO_ClearNumericallyIndexedTable(self.history)

    local FORCE = true
    self:ScrollToTop(FORCE)
end

function ZO_TributeMechanic_Manager:ResetQueue()
    self.nextQueueUpdateTimeMS = 0
    ZO_ClearNumericallyIndexedTable(self.queue)
end

function ZO_TributeMechanic_Manager:SetContinuousScrollingEnabled(enabled, direction)
    if enabled == self.isContinuousScrollingEnabled then
        return
    end

    self.isContinuousScrollingEnabled = enabled

    if enabled then
        local function OnUpdate()
            local offset = direction * ZO_TRIBUTE_MECHANIC_CONTINUOUS_SCROLL_DISTANCE_PER_SECOND * GetFrameDeltaTimeSeconds()
            self:AdjustVerticalScrollOffset(offset)
        end

        self.control:SetHandler("OnUpdate", OnUpdate, "ContinuousScrolling")
    else
        self.control:SetHandler("OnUpdate", nil, "ContinuousScrolling")
    end
end

function ZO_TributeMechanic_Manager:SetHeadingHidden(hidden)
    if hidden then
        self.showHeadingTimeline:PlayInstantlyToStart()
    else
        self.showHeadingTimeline:PlayForward()
    end
end

function ZO_TributeMechanic_Manager:SetVerticalScrollOffsetLocked(locked)
    if locked == self.isScrollOffsetLocked then
        return
    end

    self.isScrollOffsetLocked = locked
    self:UpdateCursors()
end

function ZO_TributeMechanic_Manager:ScrollToTop(force)
    if force or self:CanScrollToTop() then
        self.scrollControl:SetVerticalScroll(0)
    end
end

function ZO_TributeMechanic_Manager:UpdateCursors()
    local minX, minY, maxX, maxY = self.scrollControl:GetScreenRect()
    local x, y = nil, nil
    if self.isGamepadCursorActive then
        -- Check whether the Gamepad cursor is over the history scroll region.
        x, y = self.gamepadCursorX, self.gamepadCursorY
        if x and y then
            if x < minX or x > maxX or y < minY or y > maxY then
                x, y = nil, nil
            end
        end
    end

    if not x then
        -- Check whether the Mouse cursor is over the history scroll region.
        x, y = self.mouseCursorX, self.mouseCursorY
        if x < minX or x > maxX or y < minY or y > maxY then
            self:SetContinuousScrollingEnabled(false)
            self:SetVerticalScrollOffsetLocked(false)
            return
        end
    end

    self:SetVerticalScrollOffsetLocked(true)

    local topOffset = y - minY
    if topOffset <= ZO_TRIBUTE_MECHANIC_CONTINUOUS_SCROLL_REGION_HEIGHT then
        local DIRECTION = -1
        self:SetContinuousScrollingEnabled(true, DIRECTION)
    else
        local bottomOffset = maxY - y
        if bottomOffset <= ZO_TRIBUTE_MECHANIC_CONTINUOUS_SCROLL_REGION_HEIGHT then
            local DIRECTION = 1
            self:SetContinuousScrollingEnabled(true, DIRECTION)
        else
            self:SetContinuousScrollingEnabled(false)
        end
    end
end

function ZO_TributeMechanic_Manager:UpdateMouseCursor()
    local x, y = GetUIMousePosition()
    if x ~= self.mouseCursorX or y ~= self.mouseCursorY then
        self.mouseCursorX, self.mouseCursorY = x, y
        self:UpdateCursors()
    end
end

function ZO_TributeMechanic_Manager:UpdateScrollFadeGradient()
    local USE_FADE_GRADIENT = true
    ZO_UpdateScrollFade(USE_FADE_GRADIENT, self.scrollControl, ZO_SCROLL_DIRECTION_VERTICAL, ZO_TRIBUTE_MECHANIC_HISTORY_FADE_GRADIENT_HEIGHT)
end

function ZO_TributeMechanic_Manager:OnGamepadCursorPositionChanged(x, y)
    self.gamepadCursorX, self.gamepadCursorY = x, y
    self:UpdateCursors()
end

function ZO_TributeMechanic_Manager:OnGamepadCursorStateChanged(active)
    self.gamepadCursorX, self.gamepadCursorY = nil, nil
    self.isGamepadCursorActive = active
    self:UpdateCursors()
end

function ZO_TributeMechanic_Manager:OnGameStateChanged(gameState)
    local previousState = self.gameState
    if previousState ~= gameState then
        self.gameState = gameState

        local isInactive = gameState == TRIBUTE_GAME_FLOW_STATE_INACTIVE
        self.control:SetHidden(isInactive)

        if isInactive then
            self:Reset()
        else
            if gameState == TRIBUTE_GAME_FLOW_STATE_PLAYING then
                -- Initialize the current player turn state at the onset of the game; events will subsequently maintain the turn state.
                local isLocalPlayersTurn = IsLocalTributePlayersTurn()
                self:OnPlayerTurnStarted(isLocalPlayersTurn)
            end
        end
    end
end

function ZO_TributeMechanic_Manager:OnCardMechanicResolutionStateChanged(cardInstanceId, mechanicTrigger, mechanicIndex, quantity, isResolved)
    local isLocalPlayerOwner = self:IsLocalPlayersTurn()
    self:QueueMechanic(cardInstanceId, isLocalPlayerOwner, mechanicTrigger, mechanicIndex, quantity, isResolved)
end

function ZO_TributeMechanic_Manager:OnMouseWheel(delta, ctrl, alt, shift)
    local offsetMultiplier = (ctrl or shift) and 2 or 1
    local offset = delta * offsetMultiplier * ZO_TRIBUTE_MECHANIC_TILE_UI_HEIGHT
    self:AdjustVerticalScrollOffset(offset)

    if self.isContinuousScrollingEnabled then
        -- Receiving mouse wheel input cancels any continuous scrolling.
        self.control:SetHandler("OnUpdate", nil, "ContinuousScrolling")
    end
end

function ZO_TributeMechanic_Manager:OnPlayerTurnStarted(isLocalPlayer)
    self.isLocalPlayersTurn = isLocalPlayer

    if not isLocalPlayer then
        -- Reset the mechanic history stream when the local player finishes their turn.
        self:ResetHistory()
        self:ResetQueue()
    end
end

function ZO_TributeMechanic_Manager:OnUpdate()
    self:UpdateMouseCursor()

    local frameTimeMS = GetFrameTimeMilliseconds()
    if self.nextQueueUpdateTimeMS > frameTimeMS then
        return
    end

    local queueEntry = self.queue[1]
    if not queueEntry then
        return
    end

    self.nextQueueUpdateTimeMS = frameTimeMS + PER_HISTORY_ENTRY_DELAY_MS
    queueEntry:SetIsPresenting(true)

    local isTriggeredMechanicResolved = false
    local triggeredMechanics = queueEntry:GetTriggeredMechanics()
    local triggeredMechanic = triggeredMechanics[1]
    if triggeredMechanic then
        if triggeredMechanic:IsPresenting() then
            -- This mechanic has been presented already but not dequeued;
            -- therefore the mechanic must have been pending resolution previously.
            if triggeredMechanic:IsResolved() then
                local mechanicTile = self:GetLastMechanicTile()
                if mechanicTile then
                    -- Resolve this mechanic tile and update its final quantity.
                    -- Order matters:
                    mechanicTile:Resolve()
                    mechanicTile:SetQuantity(triggeredMechanic:GetQuantity())
                end

                -- Dequeue the mechanic.
                isTriggeredMechanicResolved = true
            end
        else
            local cardInstanceId = queueEntry:GetCardInstanceId()
            local isLocalPlayerOwner = queueEntry:IsLocalPlayerOwner()
            local mechanicTrigger, mechanicIndex = triggeredMechanic:GetMechanicTriggerAndIndex()
            local quantity = triggeredMechanic:GetQuantity()
            local isResolved = triggeredMechanic:IsResolved()

            -- Present this new mechanic.
            self:AddMechanicHistory(cardInstanceId, mechanicTrigger, mechanicIndex, isLocalPlayerOwner, quantity, isResolved)

            if isResolved then
                -- Dequeue the mechanic.
                isTriggeredMechanicResolved = true
            else
                -- Flag this mechanic as being presented but pending resolution.
                triggeredMechanic:SetIsPresenting(true)
            end
        end
    end

    if isTriggeredMechanicResolved then
        -- Dequeue the mechanic.
        table.remove(triggeredMechanics, 1)

        if not next(triggeredMechanics) then
            -- No additional mechanics remain for this queue entry.
            table.remove(self.queue, 1)
        end
    end
end

-- Global XML

function ZO_TributeMechanicHistory_OnInitialized(control)
    TRIBUTE_MECHANIC_MANAGER = ZO_TributeMechanic_Manager:New(control)
end

function ZO_TributeMechanicHistory_OnMouseWheel(control, ...)
    control.object:OnMouseWheel(...)
end

function ZO_TributeMechanicHistory_OnUpdate(control)
    control.object:OnUpdate()
end

function ZO_TributeMechanicTile_OnInitialized(control)
    control.object = ZO_TributeMechanicTile:New(control)
end

function ZO_TributeMechanicTile_Timeline_OnStop(timeline, completedPlaying)
    if timeline.object then
        timeline.object:OnTimelineStop(timeline, completedPlaying)
    end
end

function ZO_TributeMechanicTile_Timeline_OnUpdate(timeline, progress)
    if timeline.object then
        timeline.object:OnTimelineUpdate(timeline, progress)
    end
end