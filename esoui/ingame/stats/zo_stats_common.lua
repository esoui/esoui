-------------------
-- General Stats --
-------------------

STAT_TYPES =
{
    [ATTRIBUTE_HEALTH] = STAT_HEALTH_MAX,
    [ATTRIBUTE_MAGICKA] = STAT_MAGICKA_MAX,
    [ATTRIBUTE_STAMINA] = STAT_STAMINA_MAX,
}

------------------
-- Stats Common --
------------------

ZO_Stats_Common = ZO_Object:Subclass()

function ZO_Stats_Common:New(...)
    local statsCommon = ZO_Object.New(self)
    statsCommon:Initialize(...)
    return statsCommon
end

function ZO_Stats_Common:Initialize()
    self.availablePoints = 0
    self.statBonuses = {}
end

function ZO_Stats_Common:GetAvailablePoints()
    return self.availablePoints
end

function ZO_Stats_Common:SetAvailablePoints(points)
    self.availablePoints = points

    self:OnSetAvailablePoints()
end

function ZO_Stats_Common:OnSetAvailablePoints()
    -- To be overridden.
end

function ZO_Stats_Common:SpendAvailablePoints(points)
    self:SetAvailablePoints(self:GetAvailablePoints() - points)
end

function ZO_Stats_Common:GetTotalSpendablePoints()
    return GetAttributeUnspentPoints()
end

function ZO_Stats_Common:SetPendingStatBonuses(statType, pendingBonus)
    self.statBonuses[statType] = pendingBonus
end

function ZO_Stats_Common:UpdatePendingStatBonuses(statType, pendingBonus)
    self:SetPendingStatBonuses(statType, pendingBonus)
end

function ZO_Stats_Common:GetPendingStatBonuses(statType)
    return self.statBonuses[statType]
end

function ZO_Stats_Common:UpdateTitleDropdownSelection(dropdown)
    local currentTitleIndex = GetCurrentTitleIndex()
    if currentTitleIndex then
        dropdown:SetSelectedItem(zo_strformat(GetTitle(currentTitleIndex), GetRawUnitName("player")))
    else
        dropdown:SetSelectedItem(GetString(SI_STATS_NO_TITLE))
    end
end

function ZO_Stats_Common:UpdateTitleDropdownTitles(dropdown)
    dropdown:ClearItems()

    dropdown:AddItem(ZO_ComboBox:CreateItemEntry(GetString(SI_STATS_NO_TITLE), function() SelectTitle(nil) end), ZO_COMBOBOX_SUPRESS_UPDATE)
    for i=1, GetNumTitles() do
        dropdown:AddItem(ZO_ComboBox:CreateItemEntry(zo_strformat(GetTitle(i), GetRawUnitName("player")) , function() SelectTitle(i) end), ZO_COMBOBOX_SUPRESS_UPDATE)
    end

    dropdown:UpdateItems()

    self:UpdateTitleDropdownSelection(dropdown)
end

function ZO_Stats_Common:IsPlayerBattleLeveled()
    return IsUnitVetBattleLeveled("player") or IsUnitBattleLeveled("player")
end

function ZO_StatsRidingSkillIcon_Initialize(control, trainingType)
    control.trainingType = trainingType
    control:GetNamedChild("Icon"):SetTexture(STABLE_TRAINING_TEXTURES[trainingType])
end
-----------------------
-- Attribute Spinner --
-----------------------

ZO_AttributeSpinner_Shared = ZO_Object:Subclass()

function ZO_AttributeSpinner_Shared:New(attributeControl, attributeType, attributeManager, valueChangedCallback)
    local attributeSpinner = ZO_Object.New(self)

    attributeSpinner.attributeControl = attributeControl
    
    attributeSpinner.points = 0
    attributeSpinner.addedPoints = 0
    attributeSpinner.attributeManager = attributeManager
    
    attributeSpinner:SetValueChangedCallback(valueChangedCallback)
    attributeSpinner:SetAttributeType(attributeType)

    return attributeSpinner
end

function ZO_AttributeSpinner_Shared:SetSpinner(spinner)
    self.pointsSpinner = spinner
    self.pointsSpinner:RegisterCallback("OnValueChanged", function(points) self:OnValueChanged(points) end)
end

function ZO_AttributeSpinner_Shared:Reinitialize(attributeType, addedPoints, valueChangedCallback)
    self:SetValueChangedCallback(valueChangedCallback)
    self:SetAttributeType(attributeType)

    self.points = GetAttributeSpentPoints(self.attributeType)

    self:SetAddedPoints(addedPoints, true)
    self:RefreshSpinnerMax()

    self.pointsSpinner:SetValue(self.points + addedPoints)
end

function ZO_AttributeSpinner_Shared:SetValueChangedCallback(fn)
    self.valueChangedCallback = fn
end

function ZO_AttributeSpinner_Shared:SetAttributeType(attributeType)
    self.attributeType = attributeType
    self.perPoint = GetAttributeDerivedStatPerPointValue(attributeType, STAT_TYPES[attributeType])
end

function ZO_AttributeSpinner_Shared:OnValueChanged(points)
    self:SetAddedPointsByTotalPoints(points)
    
    if(self.valueChangedCallback ~= nil) then
        self.valueChangedCallback(self.points, self.addedPoints)
    end

    self:RefreshSpinnerMax()
end

function ZO_AttributeSpinner_Shared:RefreshSpinnerMax()
    self.pointsSpinner:SetMinMax(self.points, self.points + self.addedPoints + self.attributeManager:GetAvailablePoints())
end

function ZO_AttributeSpinner_Shared:RefreshPoints()
    self.points = GetAttributeSpentPoints(self.attributeType)
	self:RefreshSpinnerMax()
    self.pointsSpinner:SetValue(self.points)
end

function ZO_AttributeSpinner_Shared:ResetAddedPoints()
    self.addedPoints = 0    
    self:RefreshPoints()
end

function ZO_AttributeSpinner_Shared:GetPoints()
    return self.points
end

function ZO_AttributeSpinner_Shared:GetAllocatedPoints()
    return self.addedPoints
end

function ZO_AttributeSpinner_Shared:SetAddedPointsByTotalPoints(totalPoints)
    self:SetAddedPoints(totalPoints - self.points)
end

function ZO_AttributeSpinner_Shared:SetAddedPoints(points, force)
    points = zo_max(points, 0)
    
    local diff = points - self.addedPoints
    local availablePoints = self.attributeManager:GetAvailablePoints()

    if(force) then
        diff = 0
    elseif diff > availablePoints then
        diff = availablePoints
        points = diff + self.addedPoints
    end

    self.addedPoints = points

    if(diff ~= 0) then
        self.attributeManager:SpendAvailablePoints(diff)
    end
    self.attributeManager:UpdatePendingStatBonuses(STAT_TYPES[self.attributeType], self.perPoint * self.addedPoints)
end

function ZO_AttributeSpinner_Shared:SetButtonsHidden(hidden)
    self.pointsSpinner:SetButtonsHidden(hidden)
end
