ZO_TributeConfinementViewer_Shared = ZO_InitializingObject:Subclass()

function ZO_TributeConfinementViewer_Shared:Initialize(control, templateData)
    self.control = control
    self.templateData = templateData
    self.active = false

    ZO_TRIBUTE_CONFINEMENT_VIEWER_MANAGER:RegisterCallback("ActivationStateChanged", function(...) self:OnActivationStateChanged(...) end)
    ZO_TRIBUTE_CONFINEMENT_VIEWER_MANAGER:RegisterCallback("ConfinementsChanged", function(...) self:OnConfinementsChanged(...) end)

    self:InitializeControls()
    self:InitializeGridList()
end

function ZO_TributeConfinementViewer_Shared:InitializeGridList()
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

function ZO_TributeConfinementViewer_Shared:RefreshGridList(resetToTop, reselectData)
    self.confinementData = ZO_TRIBUTE_CONFINEMENT_VIEWER_MANAGER:GetConfinedCardsData()
    local selectedData = self.gridList:GetSelectedData()
    self.gridList:ClearGridList(not resetToTop)
    if self.confinementData then
        for _, cardData in ipairs(self.confinementData) do
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

function ZO_TributeConfinementViewer_Shared:OnActivationStateChanged(viewer, active)
    if self.active ~= active then
        if active then
            if self:CanShow() then
                local RESET_TO_TOP = true
                self:RefreshGridList(RESET_TO_TOP)
                self:Show()
            end
        else
            --If we get here, that means we no longer want to be showing the confinement viewer
            self:Hide()
        end

        self.active = active
    end
end

function ZO_TributeConfinementViewer_Shared:OnConfinementsChanged()
    if self:CanShow() then
        self:RefreshGridList()
    end
end

function ZO_TributeConfinementViewer_Shared:Hide()
    if self.gridList then
        self.gridList:ClearGridList()
    end
end

function ZO_TributeConfinementViewer_Shared:RefreshTitle()
    local titleText = ZO_TRIBUTE_CONFINEMENT_VIEWER_MANAGER:GetConfinementText()
    self:SetTitle(titleText)
end

ZO_TributeConfinementViewer_Shared.InitializeControls = ZO_TributeConfinementViewer_Shared:MUST_IMPLEMENT()

ZO_TributeConfinementViewer_Shared.CanShow = ZO_TributeConfinementViewer_Shared:MUST_IMPLEMENT()

ZO_TributeConfinementViewer_Shared.Show = ZO_TributeConfinementViewer_Shared:MUST_IMPLEMENT()

ZO_TributeConfinementViewer_Shared.SetTitle = ZO_TributeConfinementViewer_Shared:MUST_IMPLEMENT()