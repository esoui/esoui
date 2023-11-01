local TRIBUTE_CARD_ATLAS_FILE_DIMENSIONS = 512
-- TODO Tribute: Work with art to bake this into the suit atlas
local TRIBUTE_SUIT_TAB_TEXTURE_COORD_WIDTH = 135
local TRIBUTE_SUIT_TAB_TEXTURE_COORD_HEIGHT = 400
ZO_TRIBUTE_SUIT_TAB_ICON_WIDTH = 85
ZO_TRIBUTE_SUIT_TAB_ICON_HEIGHT = 240
ZO_TRIBUTE_SUIT_TAB_ICON_TOP_COORD = (TRIBUTE_CARD_ATLAS_FILE_DIMENSIONS - TRIBUTE_SUIT_TAB_TEXTURE_COORD_HEIGHT) / TRIBUTE_CARD_ATLAS_FILE_DIMENSIONS
ZO_TRIBUTE_SUIT_TAB_ICON_BOTTOM_COORD = 1
ZO_TRIBUTE_SUIT_TAB_ICON_LEFT_COORD = (TRIBUTE_CARD_ATLAS_FILE_DIMENSIONS - TRIBUTE_SUIT_TAB_TEXTURE_COORD_WIDTH) / TRIBUTE_CARD_ATLAS_FILE_DIMENSIONS
ZO_TRIBUTE_SUIT_TAB_ICON_RIGHT_COORD = 1

-- Patroin Requirement Container --

ZO_TributePatron_RequirementContainer = ZO_PooledObject:Subclass()

function ZO_TributePatron_RequirementContainer:Initialize(control)
    self.control = control
    control.object = self
    self.frameTexture = control:GetNamedChild("Frame")
    self.typeIconTexture = control:GetNamedChild("TypeIcon")
    self.quantityLabel = control:GetNamedChild("Quantity")
end

do
    internalassert(TRIBUTE_PATRON_REQUIREMENT_ITERATION_END == 3, "A new Tribute Patron requirement has been added. Does the REQUIREMENT_PARAM_MODIFIERS need special modifiers for this requirement?")
    local REQUIREMENT_PARAM_MODIFIERS =
    {
        -- Add quantity overrides for TRIBUTE_PATRON_REQUIREMENTs here. Supports displayParam, displayFunction, indexing by param1
    }

    local ANCHOR_OFFSETS =
    {
        { X = 67, Y = -72, }, -- TOP
        { X = 42, Y = 0, }, -- MIDDLE
        { X = 67, Y = 72, }, -- BOTTOM
    }

    function ZO_TributePatron_RequirementContainer:Setup(stallObject, favorState, requirementIndex)
        self.stallObject = stallObject
        self.favorState = favorState
        self.requirementIndex = requirementIndex
        self.numSiblings = stallObject:GetNumRequirementsForFavorState(favorState)
        self.requirementType, self.quantity, self.param1, self.param2 = stallObject:GetRequirementInfo(favorState, requirementIndex)

        local quantityDisplayValue = self.quantity
        local paramModifiers = REQUIREMENT_PARAM_MODIFIERS[self.requirementType]
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

        self.typeIconTexture:SetTexture(GetTributePatronRequirementIconPath(self.requirementType, self.param1, self.param2))
        local quantityDisplayText = quantityDisplayValue == 0 and GetString(SI_TRIBUTE_MECHANIC_ANY_QUANTITY_SYMBOL) or quantityDisplayValue
        self.quantityLabel:SetText(quantityDisplayText)

        local isDoubleDigitContainer = quantityDisplayValue >= 10
        local styleTemplate = isDoubleDigitContainer and "ZO_TributePatronStall_Requirement_DoubleDigit_Style" or "ZO_TributePatronStall_Requirement_SingleDigit_Style"
        ApplyTemplateToControl(self.control, styleTemplate)

        -- Singular is MIDDLE, otherwise, TOP, MIDDLE, BOTTOM
        local anchorOffsets = (self.numSiblings == 1) and ANCHOR_OFFSETS[2] or ANCHOR_OFFSETS[requirementIndex]
        self.control:SetAnchor(CENTER, nil, CENTER, anchorOffsets.X, anchorOffsets.Y)
    end
end

function ZO_TributePatron_RequirementContainer:Reset()
    self.stallObject = nil
    self.favorState = nil
    self.requirementIndex = nil
    self.requirementType = nil
    self.quantity = nil
    self.param1 = nil
    self.param2 = nil
    self.numSiblings = nil
end

-- Patron Stall --

ZO_TributePatronStall = ZO_DataSourceObject:Subclass()

function ZO_TributePatronStall:New(...)
    local object = ZO_DataSourceObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_TributePatronStall:Initialize(control)
    self.control = control
    control.object = self

    self.suitTabTexture = control:GetNamedChild("SuitTab")
    self.requirementsControl = control:GetNamedChild("Requirements")

    self.tabFadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributePatronStall_TabFadeTimeline", control)
    -- SetSkipAnimationsBehindPlayheadOnInitialPlay is needed because the animations have delays.
    -- Without this, when playing the animation directly to start, it won't set the state right because the position is technically beyond the playhead
    self.tabFadeTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)
    self.tabFadeTimeline.owner = self

    self.requirementsFadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_TributePatronStall_RequirementsFadeTimeline", self.requirementsControl)
    self.requirementsFadeTimeline.owner = self

    self.requirementContainers = {}
    self.isShowingTooltip = false

    self:RegisterForEvents()
end

function ZO_TributePatronStall:RegisterForEvents()
    local control = self.control

    control:RegisterForEvent(EVENT_TRIBUTE_PATRON_DRAFTED, function(_, _, patronDefId)
        self:OnPatronDrafted(patronDefId)
    end)

    control:RegisterForEvent(EVENT_TRIBUTE_PATRON_STATE_FLAGS_CHANGED, function(_, _, stateFlags)
        self:OnStateFlagsChanged(stateFlags)
    end)

    control:RegisterForEvent(EVENT_TRIBUTE_PATRON_FAVOR_STATE_CHANGED, function(_, _, favorState)
        self:OnFavorStateChanged(favorState)
    end)
end

function ZO_TributePatronStall:GetControl()
    return self.control
end

function ZO_TributePatronStall:GetRequirementsControl()
    return self.requirementsControl
end

function ZO_TributePatronStall:GetScreenAnchorPosition(anchor)
    local screenX, screenY = self.control:ProjectRectToScreenAndComputeAABBPoint(anchor)
    return screenX, screenY
end

function ZO_TributePatronStall:GetPatronDraftId()
    return self.patronDraftId
end

function ZO_TributePatronStall:SetPatronDraftId(patronDraftId)
    self.patronDraftId = patronDraftId
    self.control:AddFilterForEvent(EVENT_TRIBUTE_PATRON_DRAFTED, REGISTER_FILTER_PATRON_DRAFT_ID, patronDraftId)
    self.control:AddFilterForEvent(EVENT_TRIBUTE_PATRON_STATE_FLAGS_CHANGED, REGISTER_FILTER_PATRON_DRAFT_ID, patronDraftId)
    self.control:AddFilterForEvent(EVENT_TRIBUTE_PATRON_FAVOR_STATE_CHANGED, REGISTER_FILTER_PATRON_DRAFT_ID, patronDraftId)
end

function ZO_TributePatronStall:GetCurrentFavorState()
    return self.favorState
end

function ZO_TributePatronStall:HideTooltip()
    if self.isShowingTooltip then
        ClearTooltipImmediately(ItemTooltip)
        ZO_TributePatronTooltip_Gamepad_Hide()
        self.isShowingTooltip = false
    end
end

function ZO_TributePatronStall:ShowTooltip()
    if not self.isShowingTooltip then
        self:HideTooltip()

        local patronData = self:GetDataSource()
        if not patronData then
            return
        end

        local screenX, screenY = self:GetScreenAnchorPosition(LEFT)
        screenX, screenY = screenX + ZO_TRIBUTE_PATRON_TOOLTIP_OFFSET_X, screenY + ZO_TRIBUTE_PATRON_TOOLTIP_OFFSET_Y
        local currentGameFlowState = TRIBUTE:GetGameFlowState()
        local highlightActivePatronState = currentGameFlowState == TRIBUTE_GAME_FLOW_STATE_PLAYING
        local SUPPRESS_NOT_COLLECTIBLE_WARNING = true

        if IsInGamepadPreferredMode() then
            if currentGameFlowState == TRIBUTE_GAME_FLOW_STATE_PATRON_DRAFT and not ZO_TRIBUTE_PATRON_SELECTION_MANAGER:ShouldShowGamepadTooltips() then
                return
            end

            local optionalArgs =
            {
                highlightActivePatronState = highlightActivePatronState,
                suppressNotCollectibleWarning = SUPPRESS_NOT_COLLECTIBLE_WARNING,
            }
            ZO_TributePatronTooltip_Gamepad_Show(patronData, optionalArgs, RIGHT, GuiRoot, TOPLEFT, screenX, screenY)
        else
            InitializeTooltip(ItemTooltip, GuiRoot, RIGHT, screenX, screenY, TOPLEFT)
            ItemTooltip:SetTributePatron(patronData:GetId(), highlightActivePatronState, SUPPRESS_NOT_COLLECTIBLE_WARNING)
        end

        self.isShowingTooltip = true
    end
end

function ZO_TributePatronStall:IsNeutral()
    return self.patronDraftId == TRIBUTE_PATRON_DRAFT_ID_NEUTRAL
end

function ZO_TributePatronStall:RefreshLayout()
    local renderPositionX, renderPositionY, renderPositionZ, rotationXRadians, rotationYRadians, rotationZRadians = GetTributePatronTabIconTransformInfo(self.patronDraftId)
    self.control:SetTransformOffset(renderPositionX, renderPositionY, renderPositionZ)
    self.control:SetTransformRotation(rotationXRadians, rotationYRadians, rotationZRadians)
end

function ZO_TributePatronStall:OnHighlightChanged(isHighlighted)
    if isHighlighted then
        self:ShowTooltip()
    else
        self:HideTooltip()
    end
end

function ZO_TributePatronStall:OnPatronDrafted(patronDefId)
    self:SetDataSource(TRIBUTE_DATA_MANAGER:GetTributePatronData(patronDefId))
    if self:IsNeutral() then
        self.suitTabTexture:SetHidden(true)
    else
        -- Which card type doesn't matter because they both use the same tab icon in their atlas
        local suitAtlasImage = self:GetSuitAtlas(TRIBUTE_CARD_TYPE_ACTION)
        self.suitTabTexture:SetTexture(suitAtlasImage)
        self.suitTabTexture:SetHidden(false)
    end
    self.control:SetHidden(false)
    local IGNORE_CALLBACKS = true
    self.tabFadeTimeline:PlayInstantlyToStart(IGNORE_CALLBACKS)
    self.requirementsFadeTimeline:PlayInstantlyToStart(IGNORE_CALLBACKS)
    self.tabFadeTimeline:PlayForward()
    self:OnFavorStateChanged(TRIBUTE_PATRON_PERSPECTIVE_FAVOR_STATE_NEUTRAL)
end

function ZO_TributePatronStall:OnStateFlagsChanged(stateFlags)
    local changedFlags = ZO_FlagHelpers.CompareMaskFlags(self.stateFlags or 0, stateFlags or 0)
    if not changedFlags then
        return
    end

    self.stateFlags = stateFlags
    for stateFlag, active in pairs(changedFlags) do
        self:OnStateFlagChanged(stateFlag, active)
    end
end

function ZO_TributePatronStall:OnStateFlagChanged(stateFlag, active)
    if stateFlag == TRIBUTE_PATRON_STATE_FLAGS_HIGHLIGHTED then
        self:OnHighlightChanged(active)
        return
    end

    -- TODO Tribute: Handle other Patron state flags if necessary.
end

function ZO_TributePatronStall:OnFavorStateChanged(newFavorState)
    local oldFavorState = self.favorState
    self.favorState = newFavorState

    if self.tabFadeTimeline:IsPlaying() then
        -- We'll show the requirements after the tab fade has finished coming in
        return
    end

    local crossfadeRequirements = false
    local numOldRequirements = self:GetNumRequirementsForFavorState(oldFavorState)
    local numNewRequirements = self:GetNumRequirementsForFavorState(newFavorState)
    if numOldRequirements ~= numNewRequirements then
        crossfadeRequirements = true
    else
        for requirementIndex = 1, numNewRequirements do
            local oldRequirementType, oldQuantity, oldParam1, oldParam2 = self:GetRequirementInfo(oldFavorState, requirementIndex)
            local newRequirementType, newQuantity, newParam1, newParam2 = self:GetRequirementInfo(newFavorState, requirementIndex)
            if oldRequirementType ~= newRequirementType or oldQuantity ~= newQuantity or oldParam1 ~= newParam1 or oldParam2 ~= newParam2 then
                crossfadeRequirements = true
                break
            end
        end
    end

    if crossfadeRequirements then
        -- Fade out the current requirements, then replace them and fade back in
        self.requirementsFadeTimeline:PlayBackward()
    else
        -- Skip the crossfade animation and immediately update the requirements.
        self:RefreshRequirements()
    end
end

function ZO_TributePatronStall:OnTabFadeTimelineStopped(completedPlaying)
    if completedPlaying then
        -- Tab fade in from draft is complete, time to bring in the requirements
        self:RefreshRequirements()
    end
end

function ZO_TributePatronStall:OnRequirementsFadeTimelineStopped(completedPlaying)
    if completedPlaying and self.requirementsFadeTimeline:IsPlayingBackward() then
        -- Fading out old requirements is complete, clear them, create new requirements, and fade them in
        self:RefreshRequirements()
    end
end

function ZO_TributePatronStall:RefreshRequirements()
    self:ReleaseRequirements()

    local requirementContainerPool = TRIBUTE_POOL_MANAGER:GetPatronRequirementContainerPool()
    for requirementIndex = 1, self:GetNumRequirementsForFavorState(self.favorState) do
        local requirementContainer = requirementContainerPool:AcquireObject(self, self.favorState, requirementIndex)
        table.insert(self.requirementContainers, requirementContainer)
    end

    self.requirementsFadeTimeline:PlayForward()
end

function ZO_TributePatronStall:ReleaseRequirements()
    for _, requirementContainer in ipairs(self.requirementContainers) do
        requirementContainer:ReleaseObject()
    end
    ZO_ClearNumericallyIndexedTable(self.requirementContainers)
end

function ZO_TributePatronStall:Reset()
    self:OnHighlightChanged(false)
    self:SetDataSource(nil)
    self.control:SetHidden(true)
    self:ReleaseRequirements()
    self.stateFlags = nil
    self.favorState = nil
    local IGNORE_CALLBACKS = true
    self.tabFadeTimeline:PlayInstantlyToStart(IGNORE_CALLBACKS)
    self.requirementsFadeTimeline:PlayInstantlyToStart(IGNORE_CALLBACKS)
    -- Allow cleanup of big texture to gain back some memory
    self.suitTabTexture:SetTexture(nil)
end

function ZO_TributePatronStall_OnInitialized(control)
    ZO_TributePatronStall:New(control)
end

function ZO_TributePatron_RequirementContainer_OnInitialized(control)
    ZO_TributePatron_RequirementContainer:New(control)
end