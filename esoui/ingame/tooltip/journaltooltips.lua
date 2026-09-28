function ZO_Tooltip:LayoutRumorClues(rumorData)
    local titleSection = self:AcquireSection(self:GetStyle("topSection"))
    titleSection:AddLine(GetString(SI_QUEST_JOURNAL_RUMORS_CLUES), self:GetStyle("rumorClueHeader"))
    self:AddSection(titleSection)

    local clueSection = self:AcquireSection(self:GetStyle("rumorClueSection"))

    local numClues = rumorData:GetNumHints()
    for clueIndex = 1, numClues do
        if rumorData:HasDiscoveredHint(clueIndex) then
            local clueIcon = rumorData:GetHintIcon(clueIndex)
            clueSection:AddTexture(clueIcon, self:GetStyle("rumorClueIcon"))

            local clueName = rumorData:GetHintDisplayName(clueIndex)
            clueSection:AddLine(clueName, self:GetStyle("rumorClueLine"))
        end
    end

    self:AddSection(clueSection)
end

function ZO_Tooltip:LayoutRumorClue(rumorData, clueIndex)
    local titleSection = self:AcquireSection(self:GetStyle("topSection"))
    local clueName = rumorData:GetHintDisplayName(clueIndex)
    titleSection:AddLine(clueName, self:GetStyle("title"))
    self:AddSection(titleSection)

    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    local clueDescription = rumorData:GetHintDescription(clueIndex)
    bodySection:AddLine(clueDescription, self:GetStyle("bodyDescription"))
    self:AddSection(bodySection)
end
