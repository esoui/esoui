-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_ZoneStory_MilestoneTile = ZO_Tile:Subclass()

function ZO_ZoneStory_MilestoneTile:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_ZoneStory_MilestoneTile:Initialize(...)
    ZO_Tile.Initialize(self, ...)

    local control = self.control
    local contentControl = control:GetNamedChild("TextContainer")
    self.iconControl = control:GetNamedChild("Icon")
    self.lockedControl = control:GetNamedChild("Locked")
    self.titleControl = contentControl:GetNamedChild("Title")
    self.statusControl = contentControl:GetNamedChild("Status")
end

function ZO_ZoneStory_MilestoneTile:Layout(data)
    ZO_Tile.Layout(self, data)

    self.milestoneId = data.milestoneId

    local name, icon, isLocked, lockedText = GetZoneStoryMilestoneInfo(data.milestoneId)

    local numCriteriaCompleted = 0
    local numTotalCriteria = GetZoneStoryMilestoneNumCriteria(self.milestoneId)
    for criterionIndex = 1, numTotalCriteria do
        local _, criterionCompleted = GetZoneStoryMilestoneCriterionByIndex(self.milestoneId, criterionIndex)
        if criterionCompleted then
            numCriteriaCompleted = numCriteriaCompleted + 1
        end
    end

    self.iconControl:SetTexture(icon)
    self.lockedControl:SetHidden(not isLocked)
    self:SetTitle(zo_strformat(name), numCriteriaCompleted == numTotalCriteria)
    self:SetCriteria(numTotalCriteria, numCriteriaCompleted)
end

function ZO_ZoneStory_MilestoneTile:SetTitle(title, completed)
    local control = self.titleControl
    local titleColor = completed and ZO_SECOND_SELECTED_TEXT or ZO_SECOND_NORMAL_TEXT

    control:SetText(title)
    control:SetColor(titleColor:UnpackRGB())
end

function ZO_ZoneStory_MilestoneTile:SetCriteria(numTotalCriteria, numCriteriaCompleted)
    local control = self.statusControl
    local statusColor = numCriteriaCompleted == numTotalCriteria and ZO_NORMAL_TEXT or ZO_DEFAULT_TEXT
    control:SetText(zo_strformat(SI_CURRENT_AND_MAX_VALUES_FORMATTER, numCriteriaCompleted, numTotalCriteria))
    control:SetColor(statusColor:UnpackRGB())
end