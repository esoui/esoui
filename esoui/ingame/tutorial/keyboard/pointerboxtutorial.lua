ZO_PointerBoxTutorial = ZO_TutorialHandlerBase:Subclass()

function ZO_PointerBoxTutorial:Initialize(parent)
    self.parent = parent
    self.tutorial = CreateControlFromVirtual(parent:GetName(), parent, "ZO_PointerBoxTutorialTip", "PointerBoxTip")
end

do
    local g_triggerLayoutInfo = {}

    function ZO_PointerBoxTutorial:RegisterTriggerLayoutInfo(tutorialTrigger, parent, fragment, anchor, optionalParams)
        g_triggerLayoutInfo[tutorialTrigger] =
        {
            parent = parent,
            fragment = fragment,
            anchor = anchor,
            optionalParams = optionalParams,
        }
    end

    function ZO_PointerBoxTutorial:GetTriggerLayoutInfo(tutorialTrigger)
        return g_triggerLayoutInfo[tutorialTrigger]
    end
end

function ZO_PointerBoxTutorial:SuppressTutorials(suppress, reason)
    -- Suppression is disabled in ZO_PointerBoxTutorial
end

function ZO_PointerBoxTutorial:DisplayTutorial(tutorialIndex, anchor, offsetX, offsetY)
    local title, description = GetTutorialInfo(tutorialIndex)
    local trigger = GetTutorialTrigger(tutorialIndex)
    local layoutInfo = self:GetTriggerLayoutInfo(trigger)
    if not layoutInfo then
        internalassert(false, string.format("No tutorial layout registered for trigger %d", trigger or 0))
        return
    end

    self.tutorial:SetText(description)

    local pointerBox = POINTER_BOXES:Acquire()
    pointerBox:SetContentsControl(self.tutorial)
    pointerBox:SetCloseable(true)
    pointerBox:SetParent(layoutInfo.parent)
    pointerBox:SetReleaseOnHidden(true)
    pointerBox:SetTutorialIndex(tutorialIndex)

    if not anchor or anchor == NONE then
        -- Preregistered layout anchoring
        layoutInfo.anchor:Set(pointerBox)
    else
        -- Ad-hoc anchoring
        local customAnchor = ZO_Anchor:New()
        customAnchor:ResetToAnchor(layoutInfo.anchor)
        customAnchor:SetMyPoint(anchor)
        customAnchor:SetOffsets(offsetX, offsetY)
        customAnchor:Set(pointerBox)
    end

    if layoutInfo.fragment then
        pointerBox:SetHideWithFragment(layoutInfo.fragment)
    end

    self:SetOptionalPointerBoxParams(layoutInfo.optionalParams)

    pointerBox:Commit()
    pointerBox:Show()

    SetTutorialSeen(tutorialIndex)
end

do
    local DEFAULT_VERTICAL_ALIGNMENT = TEXT_ALIGN_TOP
    local DEFAULT_HORIZONTAL_ALIGNMENT = TEXT_ALIGN_CENTER
    local DEFAULT_WIDTH = 290
    local DEFAULT_HEIGHT = 0

    function ZO_PointerBoxTutorial:SetOptionalPointerBoxParams(optionalParams)
        local tutorialControl = self.tutorial
        if optionalParams then
            if optionalParams.dimensionConstraintsMinX or optionalParams.dimensionConstraintsMinY or optionalParams.dimensionConstraintsMaxX or optionalParams.dimensionConstraintsMaxY then
                tutorialControl:SetDimensionConstraints(optionalParams.dimensionConstraintsMinX or 0, optionalParams.dimensionConstraintsMinY or 0, optionalParams.dimensionConstraintsMaxX or 0, optionalParams.dimensionConstraintsMaxY or 0)
            else
                tutorialControl:SetDimensions(optionalParams.width or DEFAULT_WIDTH, optionalParams.height or DEFAULT_HEIGHT)
            end
            tutorialControl:SetVerticalAlignment(optionalParams.verticalAlignment or DEFAULT_VERTICAL_ALIGNMENT)
            tutorialControl:SetHorizontalAlignment(optionalParams.horizontalAlignment or DEFAULT_HORIZONTAL_ALIGNMENT)
        else
            tutorialControl:SetDimensionConstraints(0, 0, 0, 0)
            tutorialControl:SetDimensions(DEFAULT_WIDTH, DEFAULT_HEIGHT)
            tutorialControl:SetVerticalAlignment(DEFAULT_VERTICAL_ALIGNMENT)
            tutorialControl:SetHorizontalAlignment(DEFAULT_HORIZONTAL_ALIGNMENT)
        end
    end
end

function ZO_PointerBoxTutorial:GetActiveTutorials()
    local activePointerBoxes = {}
    local activeObjects = POINTER_BOXES:GetActiveObjects()
    for _, pointerBox in pairs(activeObjects) do
        if pointerBox:GetTutorialIndex() then
            table.insert(activePointerBoxes, pointerBox)
        end
    end
    return activePointerBoxes
end

function ZO_PointerBoxTutorial:GetActiveTutorialByIndex(tutorialIndex)
    local activeObjects = POINTER_BOXES:GetActiveObjects()
    for _, pointerBox in pairs(activeObjects) do
        if pointerBox:GetTutorialIndex() == tutorialIndex then
            return pointerBox
        end
    end
end

function ZO_PointerBoxTutorial:GetActiveTutorialByTrigger(tutorialTrigger)
    local activeObjects = POINTER_BOXES:GetActiveObjects()
    for _, pointerBox in pairs(activeObjects) do
        if pointerBox:GetTutorialTrigger() == tutorialTrigger then
            return pointerBox
        end
    end
end

function ZO_PointerBoxTutorial:GetCurrentlyDisplayedTutorialIndex()
    -- For backward compatibility with:
    --   ZO_Tutorials:ForceRemoveAll()
    --   ZO_TutorialHandlerBase:SuppressTutorials()
    --   ZO_TutorialHandlerBase:CanShowTutorial()

    local activeObjects = POINTER_BOXES:GetActiveObjects()
    for _, pointerBox in pairs(activeObjects) do
        local tutorialIndex = pointerBox:GetTutorialIndex()
        if tutorialIndex then
            return tutorialIndex
        end
    end
end

function ZO_PointerBoxTutorial:IsTutorialDisplayed(tutorialIndex)
    return self:GetActiveTutorialByIndex(tutorialIndex) ~= nil
end

function ZO_PointerBoxTutorial:OnDisplayTutorial(tutorialIndex, priority, ...)
     if not self:GetActiveTutorialByIndex(tutorialIndex) then
        if self:CanShowTutorial() then
            self:DisplayTutorial(tutorialIndex, ...)
        end
    end
end

function ZO_PointerBoxTutorial:RemoveTutorialByTrigger(tutorialTrigger)
    local pointerBox = self:GetActiveTutorialByTrigger(tutorialTrigger)
    if pointerBox then
        pointerBox:Hide()
    end
end

function ZO_PointerBoxTutorial:RemoveTutorial(tutorialIndex)
    local pointerBox = self:GetActiveTutorialByIndex(tutorialIndex)
    if pointerBox then
        pointerBox:Hide()
    end
end

function ZO_PointerBoxTutorial:GetTutorialType()
    return TUTORIAL_TYPE_POINTER_BOX
end

function ZO_PointerBoxTutorial:ClearAll()
    local activePointerBoxes = self:GetActiveTutorials()
    for _, pointerBox in ipairs(activePointerBoxes) do
        pointerBox:Hide()
    end
end