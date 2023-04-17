ZO_TributeTargetViewer_Shared = ZO_InitializingObject:Subclass()

function ZO_TributeTargetViewer_Shared:Initialize(control, templateData)
    self.control = control
    self.templateData = templateData
    self.hasTargets = false

    ZO_TRIBUTE_TARGET_VIEWER_MANAGER:RegisterCallback("ActivationStateChanged", function(...) self:OnActivationStateChanged(...) end)
    ZO_TRIBUTE_TARGET_VIEWER_MANAGER:RegisterCallback("CardStateFlagsChanged", function(...) self:OnCardStateFlagsChanged(...) end)
    ZO_TRIBUTE_TARGET_VIEWER_MANAGER:RegisterCallback("ViewingBoardChanged", function(...) self:OnViewingBoardChanged(...) end)

    self:InitializeControls()
    self:InitializeGridList()
    self:InitializeKeybindStripDescriptors()
end

function ZO_TributeTargetViewer_Shared:InitializeGridList()
    self.gridContainerControl = self.control:GetNamedChild("GridContainer")
    self.gridListControl = self.gridContainerControl:GetNamedChild("GridList")
    self.gridListEmptyLabel = self.gridContainerControl:GetNamedChild("ContentEmptyLabel")
    self.gridList = self.templateData.gridListClass:New(self.gridListControl)

    local function CardEntryEqualityFunction(left, right)
        return left.cardInstanceId == right.cardInstanceId
    end

    local cardEntryData = self.templateData.cardEntryData
    local HIDE_CALLBACK = nil
    self.gridList:AddEntryTemplate(cardEntryData.entryTemplate, cardEntryData.width, cardEntryData.height, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, cardEntryData.gridPaddingX, cardEntryData.gridPaddingY)
    self.gridList:SetEntryTemplateEqualityFunction(cardEntryData.entryTemplate, CardEntryEqualityFunction)
end

function ZO_TributeTargetViewer_Shared:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = GetString(SI_TRIBUTE_TARGET_VIEWER_CONFIRM_ACTION),
            order = 2,
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                TributeConfirmTargetSelection()
            end,
            enabled = function()
                local canConfirm, expectedResult = CanConfirmTributeTargetSelection()
                if canConfirm then
                    return true
                else
                    local resultString = GetString("SI_TRIBUTETARGETSELECTIONCONFIRMATIONRESULT", expectedResult)
                    if resultString ~= "" then
                        return false, resultString
                    else
                        return false
                    end
                end
            end,
            visible = function()
                return not IsTributeTargetSelectionAutoComplete()
            end,
        },
    }
end

function ZO_TributeTargetViewer_Shared:RefreshGridList(resetToTop, reselectData)
    self.targetData = ZO_TRIBUTE_TARGET_VIEWER_MANAGER:GetCurrentTargetData()
    if self.gridList then
        local selectedData = self.gridList:GetSelectedData()
        self.gridList:ClearGridList(not resetToTop)
        if self.targetData then
            for _, cardData in ipairs(self.targetData) do
                local entryData = ZO_EntryData:New(cardData)
                self.gridList:AddEntry(entryData, self.templateData.cardEntryData.entryTemplate)
            end
        end

        if reselectData then
            self.gridList:SetAutoSelectToMatchingDataEntry(selectedData)
        end
        self.gridList:CommitGridList()

        self.gridListEmptyLabel:SetHidden(self.gridList:HasEntries())
    end
end

function ZO_TributeTargetViewer_Shared:OnActivationStateChanged(viewer, hasTargets)
    if self.hasTargets ~= hasTargets then
        if hasTargets then
            if self:CanShow() then
                local RESET_TO_TOP = true
                self:RefreshGridList(RESET_TO_TOP)
                self:Show()
            end
        else
            --If we get here, that means we no longer want to be showing the target viewer
            self:Hide()
        end

        self.hasTargets = hasTargets
    end
end

function ZO_TributeTargetViewer_Shared:OnCardStateFlagsChanged(cardInstanceId, stateFlags)
    local ALL_ENTRIES = nil
    local function RefreshCardObject(control, data)
        if data.cardInstanceId == cardInstanceId then
            local cardObject = control.object.cardData
            if cardObject then
                local wasTargeted = cardObject:IsTargeted()
                cardObject:OnStateFlagsChanged(stateFlags)
                local isTargeted = cardObject:IsTargeted()
                --If there is no associated board object for this card, we need to handle playing the sound effects ourselves
                --Otherwise the board object will handle playing the sound for us
                if not TRIBUTE:GetCardByInstanceId(cardInstanceId) and wasTargeted ~= isTargeted then
                    if isTargeted then
                        PlaySound(SOUNDS.TRIBUTE_CARD_TARGETED)
                    else
                        PlaySound(SOUNDS.TRIBUTE_CARD_UNTARGETED)
                    end
                end
            end
            KEYBIND_STRIP:UpdateKeybindButtonGroup(control.object.keybindStripDescriptor)
        end
    end
    self.gridList:RefreshGridListEntryData(ALL_ENTRIES, RefreshCardObject)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TributeTargetViewer_Shared:Hide()
    if self.gridList then
        self.gridList:ClearGridList()
    end
end

function ZO_TributeTargetViewer_Shared:RefreshInstruction()
    local instructionText = ZO_TRIBUTE_TARGET_VIEWER_MANAGER:GetInstructionText()
    self:SetInstruction(instructionText)
end

function ZO_TributeTargetViewer_Shared:OnViewingBoardChanged(isViewingBoard)
    if isViewingBoard then
        SCENE_MANAGER:RemoveFragment(self.fragment)
    elseif self:CanShow() then
        SCENE_MANAGER:AddFragment(self.fragment)
    end
end

ZO_TributeTargetViewer_Shared.InitializeControls = ZO_TributeTargetViewer_Shared:MUST_IMPLEMENT()

ZO_TributeTargetViewer_Shared.CanShow = ZO_TributeTargetViewer_Shared:MUST_IMPLEMENT()

ZO_TributeTargetViewer_Shared.Show = ZO_TributeTargetViewer_Shared:MUST_IMPLEMENT()

ZO_TributeTargetViewer_Shared.SetInstruction = ZO_TributeTargetViewer_Shared:MUST_IMPLEMENT()