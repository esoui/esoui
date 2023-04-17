ZO_TributePileViewer_Shared = ZO_InitializingObject:Subclass()

function ZO_TributePileViewer_Shared:Initialize(control, templateData)
    self.control = control
    self.templateData = templateData

    ZO_TRIBUTE_PILE_VIEWER_MANAGER:RegisterCallback("ViewingPileChanged", function(...) self:OnViewingPileChanged(...) end)
    ZO_TRIBUTE_PILE_VIEWER_MANAGER:RegisterCallback("CardStateFlagsChanged", function(...) self:OnCardStateFlagsChanged(...) end)
    ZO_TRIBUTE_PILE_VIEWER_MANAGER:RegisterCallback("AgentDefeatCostChanged", function(...) self:OnAgentDefeatCostChanged(...) end)
    ZO_TRIBUTE_PILE_VIEWER_MANAGER:RegisterCallback("ConfinedCardsChanged", function(...) self:OnConfinedCardsChanged(...) end)

    self:InitializeControls()
    self:InitializeGridList()
    self:InitializeKeybindStripDescriptors()
end

function ZO_TributePileViewer_Shared:InitializeGridList()
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

function ZO_TributePileViewer_Shared:RefreshGridList(resetToTop, reselectData)
    self.currentPileData = ZO_TRIBUTE_PILE_VIEWER_MANAGER:GetCurrentPileData()
    if self.gridList then
        local selectedData = self.gridList:GetSelectedData()
        self.gridList:ClearGridList(not resetToTop)
        if self.currentPileData then
            local cardList = self.currentPileData:GetCardList()
            for _, cardData in ipairs(cardList) do
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

function ZO_TributePileViewer_Shared:OnViewingPileChanged(boardLocation)
    if self.viewingPileLocation ~= boardLocation then
        if boardLocation then
            if self:CanShow() then
                local RESET_TO_TOP = true
                self:RefreshGridList(RESET_TO_TOP)
                --If we don't already have a viewing pile location, then that means we are not currently viewing a pile
                if self.viewingPileLocation == nil then
                    self:Show()
                end
            end
        else
            --If we get here, that means we no longer want to be showing the pile viewer
            self:Hide()
        end

        self.viewingPileLocation = boardLocation
    elseif self.viewingPileLocation and self:CanShow() then
        --If we get here, then we just need to refresh the pile we are currently viewing
        self:RefreshPile()
    end
end

function ZO_TributePileViewer_Shared:OnCardStateFlagsChanged(cardInstanceId, stateFlags)
    if not self:CanShow() then
        return
    end

    local ALL_ENTRIES = nil
    local function RefreshCardObject(control, data)
        if data.cardInstanceId == cardInstanceId then
            local cardObject = control.object.cardData
            if cardObject then
                cardObject:OnStateFlagsChanged(stateFlags)
            end
            KEYBIND_STRIP:UpdateKeybindButtonGroup(control.object.keybindStripDescriptor)
        end
    end
    self.gridList:RefreshGridListEntryData(ALL_ENTRIES, RefreshCardObject)
end

function ZO_TributePileViewer_Shared:OnConfinedCardsChanged(cardInstanceId)
    if not self:CanShow() then
        return
    end

    local ALL_ENTRIES = nil
    local function RefreshCardObject(control, data)
        if data.cardInstanceId == cardInstanceId then
            local cardObject = control.object.cardData
            if cardObject then
                cardObject:RefreshConfinedStack()
            end
            KEYBIND_STRIP:UpdateKeybindButtonGroup(control.object.keybindStripDescriptor)
        end
    end
    self.gridList:RefreshGridListEntryData(ALL_ENTRIES, RefreshCardObject)
end

function ZO_TributePileViewer_Shared:OnAgentDefeatCostChanged(cardInstanceId, delta, newDefeatCost, shouldPlayFx)
    if not self:CanShow() then
        return
    end

    local ALL_ENTRIES = nil
    local function RefreshCardObject(control, data)
        if data.cardInstanceId == cardInstanceId then
            local cardObject = control.object.cardData
            if cardObject then
                if shouldPlayFx then
                    --Let the world space cards handle playing the SFX
                    local SUPPRESS_SOUND = true
                    cardObject:UpdateDefeatCost(newDefeatCost, delta, SUPPRESS_SOUND)
                else
                    cardObject:RefreshDefeatCost()
                end
            end
            KEYBIND_STRIP:UpdateKeybindButtonGroup(control.object.keybindStripDescriptor)
        end
    end
    self.gridList:RefreshGridListEntryData(ALL_ENTRIES, RefreshCardObject)
end

function ZO_TributePileViewer_Shared:Hide()
    if self.gridList then
        self.gridList:ClearGridList()
    end
end

ZO_TributePileViewer_Shared.InitializeControls = ZO_TributePileViewer_Shared:MUST_IMPLEMENT()

ZO_TributePileViewer_Shared.InitializeKeybindStripDescriptors = ZO_TributePileViewer_Shared:MUST_IMPLEMENT()

ZO_TributePileViewer_Shared.RefreshPile = ZO_TributePileViewer_Shared:MUST_IMPLEMENT()

ZO_TributePileViewer_Shared.CanShow = ZO_TributePileViewer_Shared:MUST_IMPLEMENT()

ZO_TributePileViewer_Shared.Show = ZO_TributePileViewer_Shared:MUST_IMPLEMENT()