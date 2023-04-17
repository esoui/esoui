-----------------------------
-- Tribute Target Viewer Manager
-----------------------------

ZO_TributeTargetViewer_Manager = ZO_TributeViewer_Manager_Base:Subclass()

function ZO_TributeTargetViewer_Manager:Initialize()
    ZO_TributeViewer_Manager_Base.Initialize(self)

    self.keybindStripDescriptor = 
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = function()
                if self.viewingBoard then
                    return GetString(SI_TRIBUTE_TARGET_VIEWER_SHOW_TARGETS_ACTION)
                else
                    return GetString(SI_TRIBUTE_TARGET_VIEWER_SHOW_BOARD_ACTION)
                end
            end,
            order = 3,
            keybind = "UI_SHORTCUT_QUATERNARY",
            callback = function()
                self:SetViewingBoard(not self.viewingBoard)
            end,
        },
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_TRIBUTE_TARGET_VIEWER_CANCEL_ACTION),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                TributeCancelCurrentMove()
            end,
            visible = function()
                return TributeCanCancelCurrentMove()
            end,
        },
        {
            keybind = "UI_SHORTCUT_EXIT",
            ethereal = true,
            callback = function()
                TributeCancelCurrentMove()
            end,
            visible = function()
                return TributeCanCancelCurrentMove()
            end,
        },
    }

    self.viewingBoard = false
end

function ZO_TributeTargetViewer_Manager:RegisterForEvents(systemName)
    ZO_TributeViewer_Manager_Base.RegisterForEvents(self, systemName)
    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_BEGIN_TARGET_SELECTION, function(_, needsTargetViewer)
        self:OnBeginTargetSelection(needsTargetViewer)
    end)

    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_END_TARGET_SELECTION, function()
        self:SetViewingTargets(nil)
    end)

    EVENT_MANAGER:RegisterForEvent(systemName, EVENT_TRIBUTE_CARD_STATE_FLAGS_CHANGED, function(_, cardInstanceId, stateFlags)
        if self:IsActive() then
            self:FireCallbacks("CardStateFlagsChanged", cardInstanceId, stateFlags)
        end
    end)
end

function ZO_TributeTargetViewer_Manager:GetCurrentTargetData()
    return self.viewingTargetData
end

function ZO_TributeTargetViewer_Manager:OnBeginTargetSelection(needsTargetViewer)
    if needsTargetViewer then
        local targetData = {}
        local numTargetable = GetNumTargetableTributeCards()
        for targetableIndex = 1, numTargetable do
            local cardInstanceId = GetTargetableTributeCardInstanceIdByIndex(targetableIndex)
            local cardId, patronId = GetTributeCardInstanceDefIds(cardInstanceId)
            local data =
            {
                cardId = cardId,
                patronId = patronId,
                cardInstanceId = cardInstanceId,
            }
            table.insert(targetData, data)
        end
        self:SetViewingTargets(targetData)
        PlaySound(SOUNDS.TRIBUTE_SHOW_TARGET_VIEWER)
    else
        self:SetViewingTargets(nil)
    end
end

function ZO_TributeTargetViewer_Manager:SetViewingTargets(viewingTargetData)
    if self.viewingTargetData ~= viewingTargetData then
        self.viewingTargetData = viewingTargetData
        if viewingTargetData then
            --Order matters. Wait until the callback has been fired before adding the keybinds
            self:FireActivationStateChanged()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        else
            self.viewingBoard = false
            --Order matters. Remove the keybinds before firing the callback
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            self:FireActivationStateChanged()
        end
    end
end

function ZO_TributeTargetViewer_Manager:SetViewingBoard(isViewingBoard)
    if self.viewingBoard ~= isViewingBoard then
        self.viewingBoard = isViewingBoard
        self:FireCallbacks("ViewingBoardChanged", self.viewingBoard)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_TributeTargetViewer_Manager:GetInstructionText()
    local instructionText = ""
    local sourceType = GetCurrentTributeTargetSelectionSourceType()
    if sourceType == TRIBUTE_TARGET_SELECTION_SOURCE_TYPE_MECHANIC then
        local mechanicType, quantity, param1, param2, param3, targetingFormatterOverrideText = GetTributeTargetSelectionMechanicInfo()
        instructionText = GetTributeMechanicTargetingText(mechanicType, quantity, param1, param2, param3, targetingFormatterOverrideText)
    elseif sourceType == TRIBUTE_TARGET_SELECTION_SOURCE_TYPE_PATRON_REQUIREMENT then
        local requirementType, quantity, param1, param2, targetingFormatterOverrideText = GetTributeTargetSelectionRequirementInfo()
        instructionText = GetTributePatronRequirementTargetingText(requirementType, quantity, param1, param2, targetingFormatterOverrideText)
    elseif sourceType == TRIBUTE_TARGET_SELECTION_SOURCE_TYPE_NONE then
        internalassert(false, "Target selection is not active")
    else
        internalassert(false, "Unimplemented target selection source type")
    end
    return instructionText
end

function ZO_TributeTargetViewer_Manager:OpenConfinementViewer(cardData)
    --Cache the target data we are currently looking at before closing the target viewer and opening the confinement viewer
    self.cachedViewingTargetData = self:GetCurrentTargetData()
    --Avoid calling RequestClose so we dont cancel target selection
    self:SetViewingTargets(nil)
    cardData:ShowConfinedCards(self)
end

function ZO_TributeTargetViewer_Manager:OpenFromConfinementViewer()
    --Once the confinement viewer closes, if we had cached target data we were previously looking at, try to re-open it
    if self.cachedViewingTargetData then
        --Make sure target selection is still active before attempting to re-open
        if GetCurrentTributeTargetSelectionSourceType() ~= TRIBUTE_TARGET_SELECTION_SOURCE_TYPE_NONE then
            self:SetViewingTargets(self.cachedViewingTargetData)
        end
        self.cachedViewingTargetData = nil
    end
end

-- Required Overrides

function ZO_TributeTargetViewer_Manager:GetSystemName()
    return "TributeTargetViewer_Manager"
end

function ZO_TributeTargetViewer_Manager:OnGamepadPreferredModeChanged()
    --If the viewer is already up, we need to close and reopen it to make sure it switches to the correct UI
    if self:IsActive() then
        --ESO-773300: In the situation where this event fires at the same time as EVENT_TRIBUTE_END_TARGET_SELECTION, the information cached on the manager may have not yet been updated
        --As a result, we need to ask the C++ directly to make sure target selection is actually still active
        if GetCurrentTributeTargetSelectionSourceType() ~= TRIBUTE_TARGET_SELECTION_SOURCE_TYPE_NONE then
            local targetData = self:GetCurrentTargetData()
            self:SetViewingTargets(nil)
            self:SetViewingTargets(targetData)
        end
    end
end

function ZO_TributeTargetViewer_Manager:IsViewingBoard()
    return self.viewingBoard
end

function ZO_TributeTargetViewer_Manager:IsActive()
    return self.viewingTargetData ~= nil
end

--The target viewer will always have a visible keybind strip
function ZO_TributeTargetViewer_Manager:IsKeybindStripVisible()
    return true
end

function ZO_TributeTargetViewer_Manager:RequestClose()
    if TributeCanCancelCurrentMove() then
        TributeCancelCurrentMove()
    end
end

ZO_TRIBUTE_TARGET_VIEWER_MANAGER = ZO_TributeTargetViewer_Manager:New()