ZO_AntiquitySet = ZO_Object:Subclass()

function ZO_AntiquitySet:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_AntiquitySet:Initialize(antiquitySetId)
    self.antiquitySetId = antiquitySetId
    self.name = GetAntiquitySetName(antiquitySetId)
    self.icon = GetAntiquitySetIcon(antiquitySetId)
    self.quality = GetAntiquitySetQuality(antiquitySetId)
    self.rewardId = GetAntiquitySetRewardId(antiquitySetId)
    self.antiquities = {}
end

function ZO_AntiquitySet:GetId()
    return self.antiquitySetId
end

function ZO_AntiquitySet:GetType()
    return ZO_ANTIQUITY_TYPE_SET
end

function ZO_AntiquitySet:GetName()
    return self.name
end

function ZO_AntiquitySet:GetFormattedName()
    return ZO_CachedStrFormat(SI_ANTIQUITY_SET_NAME_FORMATTER, self.name)
end

function ZO_AntiquitySet:GetColorizedFormattedName()
    local itemQualityColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ANTIQUITY_QUALITY_COLORS, self:GetQuality()))
    return itemQualityColor:Colorize(self:GetFormattedName())
end

function ZO_AntiquitySet:GetIcon()
    return self.icon
end

function ZO_AntiquitySet:GetQuality()
    return self.quality
end

function ZO_AntiquitySet:GetRewardId()
    return self.rewardId
end

function ZO_AntiquitySet:HasReward()
    return self.rewardId ~= 0
end

function ZO_AntiquitySet:IsRepeatable()
    for _, antiquityData in self:AntiquityIterator() do
        if antiquityData:IsRepeatable() then
            return true
        end
    end
    return false
end

function ZO_AntiquitySet:HasDiscoveredDigSites()
    for _, antiquityData in self:AntiquityIterator() do
        if antiquityData:HasDiscoveredDigSites() then
            return true
        end
    end
    return false
end

function ZO_AntiquitySet:HasNoDiscoveredDigSites()
    return not self:HasDiscoveredDigSites()
end

function ZO_AntiquitySet:GetNumRecovered()
    local numRecovered
    for _, antiquityData in self:AntiquityIterator() do
        local antiquityNumRecovered = antiquityData:GetNumRecovered()
        numRecovered = numRecovered and math.min(numRecovered, antiquityNumRecovered) or antiquityNumRecovered
    end
    return numRecovered or 0
end

function ZO_AntiquitySet:GetLoreEntries()
    local loreEntries = {}
    for _, antiquityData in self:AntiquityIterator() do
        for _, loreEntry in ipairs(antiquityData:GetLoreEntries()) do
            table.insert(loreEntries, loreEntry)
        end
    end
    return loreEntries
end

function ZO_AntiquitySet:GetNumLoreEntries()
    local numLoreEntries = 0
    for _, antiquityData in self:AntiquityIterator() do
        numLoreEntries = numLoreEntries + antiquityData:GetNumLoreEntries()
    end
    return numLoreEntries
end

function ZO_AntiquitySet:GetNumUnlockedLoreEntries()
    local numUnlockedEntries = 0
    for _, antiquityData in self:AntiquityIterator() do
        numUnlockedEntries = numUnlockedEntries + antiquityData:GetNumUnlockedLoreEntries()
    end
    return numUnlockedEntries
end

function ZO_AntiquitySet:GetNumAntiquities()
    return #self.antiquities
end

function ZO_AntiquitySet:GetNumAntiquitiesRecovered()
    local count = 0
    for _, _ in self:AntiquityIterator({ZO_Antiquity.IsComplete}) do
        count = count + 1
    end
    return count
end

function ZO_AntiquitySet:HasNewLead()
    for _, antiquityData in self:AntiquityIterator() do
        if antiquityData:HasNewLead() then
            return true
        end
    end
    return false
end

function ZO_AntiquitySet:HasDiscovered()
    return self:AntiquityIterator({ZO_Antiquity.HasDiscovered})() ~= nil
end

function ZO_AntiquitySet:HasRecovered()
    return self:AntiquityIterator({function(antiquityData) return not antiquityData:HasRecovered() end})() == nil
end

function ZO_AntiquitySet:IsComplete()
    return self:HasRecovered()
end

function ZO_AntiquitySet:AddAntiquityData(antiquityData)
    table.insert(self.antiquities, antiquityData)
end

function ZO_AntiquitySet:AntiquityIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.antiquities, filterFunctions)
end