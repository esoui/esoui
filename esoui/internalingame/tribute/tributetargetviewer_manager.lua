-----------------------------
-- Tribute Target Viewer Manager
-----------------------------

ZO_TributeTargetViewer_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_TributeTargetViewer_Manager:Initialize()
    EVENT_MANAGER:RegisterForEvent("TributeTargetViewer_Manager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function()
        --If the viewer is already up, we need to close and reopen it to make sure it switches to the correct UI
        if self:IsViewingTargets() then
            local targetData = self:GetCurrentTargetData()
            self:SetViewingTargets(nil)
            self:SetViewingTargets(targetData)
        end
    end)

    EVENT_MANAGER:RegisterForEvent("TributeTargetViewer_Manager", EVENT_TRIBUTE_BEGIN_TARGET_SELECTION, function(_, needsTargetViewer)
        self:OnBeginTargetSelection(needsTargetViewer)
    end)

    EVENT_MANAGER:RegisterForEvent("TributeTargetViewer_Manager", EVENT_TRIBUTE_END_TARGET_SELECTION, function()
        self:SetViewingTargets(nil)
    end)

    EVENT_MANAGER:RegisterForEvent("TributeTargetViewer_Manager", EVENT_TRIBUTE_CARD_STATE_FLAGS_CHANGED, function(_, cardInstanceId, stateFlags)
        if self:IsViewingTargets() then
            self:FireCallbacks("CardStateFlagsChanged", cardInstanceId, stateFlags)
        end
    end)

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
            keybind = "UI_SHORTCUT_EXIT",
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

function ZO_TributeTargetViewer_Manager:GetCurrentTargetData()
    return self.viewingTargetData
end

function ZO_TributeTargetViewer_Manager:IsViewingTargets()
    return self.viewingTargetData ~= nil
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
            self:FireCallbacks("ViewingTargetsChanged", self.viewingTargetData ~= nil)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        else
            self.viewingBoard = false
            --Order matters. Remove the keybinds before firing the callback
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            self:FireCallbacks("ViewingTargetsChanged", self.viewingTargetData ~= nil)
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

function ZO_TributeTargetViewer_Manager:IsViewingBoard()
    return self.viewingBoard
end

function ZO_TributeTargetViewer_Manager:GetInstructionText()
    local instructionText = ""
    local triggerType = GetCurrentTributeTargetSelectionTriggerType()
    if triggerType == TRIBUTE_TARGET_SELECTION_TRIGGER_TYPE_MECHANIC then
        local mechanicType, quantity, param1, param2, param3 = GetTributeTargetSelectionMechanicInfo()
        instructionText = GetTributeMechanicTargetingText(mechanicType, quantity, param1, param2, param3)
    elseif triggerType == TRIBUTE_TARGET_SELECTION_TRIGGER_TYPE_PATRON_REQUIREMENT then
        local requirementType, quantity, param1, param2 = GetTributeTargetSelectionRequirementInfo()
        instructionText = GetTributePatronRequirementTargetingText(requirementType, quantity, param1, param2)
    elseif triggerType == TRIBUTE_TARGET_SELECTION_TRIGGER_TYPE_NONE then
        internalassert(false, "Target selection is not active")
    else
        internalassert(false, "Unimplemented target selection trigger type")
    end
    return instructionText
end

ZO_TRIBUTE_TARGET_VIEWER_MANAGER = ZO_TributeTargetViewer_Manager:New()