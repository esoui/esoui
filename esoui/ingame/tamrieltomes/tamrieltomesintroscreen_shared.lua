ZO_TamrielTomesIntroScreen_Shared = ZO_DeferredInitializingObject:Subclass()

function ZO_TamrielTomesIntroScreen_Shared:Initialize(control, scene, highlightTemplate)
    self.control = control

    ZO_DeferredInitializingObject.Initialize(self, scene)

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)

    self.highlightTemplate = highlightTemplate
end

function ZO_TamrielTomesIntroScreen_Shared:OnDeferredInitialize()
    self.highlightsContainer = self.control:GetNamedChild("HighlightsScrollChild")
    self.highlightsControlPool = ZO_ControlPool:New(self.highlightTemplate, self.highlightsContainer, "Entry")

    self.titleLabel = self.control:GetNamedChild("Title")
    self.rewardImageControl = self.control:GetNamedChild("ImageBackground")
end

function ZO_TamrielTomesIntroScreen_Shared:OnShowing()
    local selectedTomeId = TAMRIEL_TOMES_MANAGER:GetSelectedTomeId()
    self:ShowTomeInfo(selectedTomeId)
end

function ZO_TamrielTomesIntroScreen_Shared:OnShown()
    local selectedTomeId = TAMRIEL_TOMES_MANAGER:GetSelectedTomeId()
    TAMRIEL_TOMES_MANAGER:MarkTomeSeen(selectedTomeId)
end

function ZO_TamrielTomesIntroScreen_Shared:OnHiding()
    -- TODO Tamriel Tomes
end

function ZO_TamrielTomesIntroScreen_Shared:OnHidden()
    -- TODO Tamriel Tomes
end

function ZO_TamrielTomesIntroScreen_Shared:ShowTomeInfo(tamrielTomeId)
    self.highlightsControlPool:ReleaseAllObjects()

    local tomeData = ZO_TamrielTomeData:New(tamrielTomeId)
    self.tomeData = tomeData

    local displayName = tomeData:GetDisplayName()
    self.titleLabel:SetText(displayName)

    local backgroundFile = tomeData:GetIntroBackgroundFile()
    self.rewardImageControl:SetTexture(backgroundFile)

    local previousControl = nil
    local numHighlights = tomeData:GetNumHighlights()
    for highlightIndex = 1, numHighlights do
        local title, text = tomeData:GetHighlightInfo(highlightIndex)
        local highlightControl = self.highlightsControlPool:AcquireObject()
        highlightControl:SetParent(self.highlightsContainer)
        highlightControl.titleLabel:SetText(title)
        highlightControl.bodyTextLabel:SetText(text)
        if previousControl then
            highlightControl:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 15)
        else
            highlightControl:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
        end

        previousControl = highlightControl
    end
end

function ZO_TamrielTomesIntroScreen_Shared:AdvanceToTome()
    SYSTEMS:ShowScene("tamrielTomes")

    -- Play the page fip sound manually as the ZO_PageNavigation control
    -- is not technically changing pages in this context.
    PlaySound(SOUNDS.TAMRIEL_TOMES_PAGE_FLIPPED)
end
