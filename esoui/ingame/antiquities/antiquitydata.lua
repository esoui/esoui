ZO_Antiquity = ZO_Object:Subclass()

function ZO_Antiquity:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_Antiquity:Initialize(antiquityId)
    -- Get Antiquity information.
    self.antiquityId = antiquityId
    self.name = GetAntiquityName(antiquityId)
    self.requiresLead = DoesAntiquityRequireLead(antiquityId)
    self.icon = GetAntiquityIcon(antiquityId)
    self.quality = GetAntiquityQuality(antiquityId)
    self.rewardId = GetAntiquityRewardId(antiquityId)
    self.isRepeatable = IsAntiquityRepeatable(antiquityId)
    self.zoneId = GetAntiquityZoneId(antiquityId)
    self.difficulty = GetAntiquityDifficulty(antiquityId)

    self.hasLead = false
    self.numDigSites = 0
    self.numRecovered = 0
    self.loreEntries = {}
    local fragmentName = nil

    -- Get Antiquity Set information.
    local antiquitySetId = GetAntiquitySetId(antiquityId)
    if antiquitySetId and antiquitySetId ~= 0 then
        local antiquitySetData = ANTIQUITY_DATA_MANAGER:GetOrCreateAntiquitySetData(antiquitySetId)
        self.antiquitySetData = antiquitySetData
        antiquitySetData:AddAntiquityData(self)
        fragmentName = self.name
    end

    -- Get Antiquity Category information.
    local antiquityCategoryId = GetAntiquityCategoryId(antiquityId)
    if antiquityCategoryId and antiquityCategoryId ~= ZO_SCRYABLE_ANTIQUITY_CATEGORY_ID then
        local antiquityCategoryData = ANTIQUITY_DATA_MANAGER:GetOrCreateAntiquityCategoryData(antiquityCategoryId)
        self.antiquityCategoryData = antiquityCategoryData
        antiquityCategoryData:AddAntiquityData(self)
    end

    -- Get Antiquity Lore entries.
    local numLoreEntries = GetNumAntiquityLoreEntries(antiquityId)
    for loreEntryIndex = 1, numLoreEntries do
        local loreDisplayName, loreDescription = GetAntiquityLoreEntry(antiquityId, loreEntryIndex)
        local loreEntryData =
        {
            antiquityId = antiquityId,
            loreEntryIndex = loreEntryIndex,
            displayName = loreDisplayName,
            description = loreDescription,
            fragmentName = fragmentName,
            unlocked = false
        }
        table.insert(self.loreEntries, loreEntryData)
    end

    self:Refresh()
end

function ZO_Antiquity:Refresh()
    local antiquityId = self:GetId()

    -- Get Antiquity Progress information.
    self.hasLead = DoesAntiquityHaveLead(antiquityId)
    -- Retain the New Lead state when refreshing an antiquity that still has a lead.
    self.hasNewLead = self.hasNewLead and self.hasLead
    self.leadExpirationTimeS = GetFrameTimeSeconds() + GetAntiquityLeadTimeRemainingSeconds(antiquityId)
    self.needsCombination = DoesAntiquityNeedCombination(antiquityId)
    self.numRecovered = GetNumAntiquitiesRecovered(antiquityId)
    self.numLoreEntriesAcquired = GetNumAntiquityLoreEntriesAcquired(antiquityId)
    self.difficulty = GetAntiquityDifficulty(antiquityId)
    self:RefreshDigSites()

    -- Update the unlocked state of unlocked lore entries.
    local numUnlockedLoreEntries = self:GetNumUnlockedLoreEntries()
    for loreEntryIndex, loreEntryData in ipairs(self.loreEntries) do
        loreEntryData.unlocked = loreEntryIndex <= numUnlockedLoreEntries
    end
end

function ZO_Antiquity:RefreshDigSites()
    self.numDigSites = GetNumAntiquityDigSites(self:GetId())
    self.numGoalsAchieved = GetNumGoalsAchievedForAntiquity(self:GetId())
end

function ZO_Antiquity:OnDigSitesUpdated()
    self.lastNumGoalsAchieved = self.numGoalsAchieved
    self:RefreshDigSites()
end

function ZO_Antiquity:OnLeadAcquired()
    self.hasNewLead = true
end

function ZO_Antiquity:ClearNewLead()
    if self.hasNewLead then
        self.hasNewLead = false
        ANTIQUITY_DATA_MANAGER:OnSingleAntiquityNewLeadCleared(self:GetId())
    end
end

function ZO_Antiquity:GetType()
    return ZO_ANTIQUITY_TYPE_INDIVIDUAL
end

function ZO_Antiquity:GetId()
    return self.antiquityId
end

function ZO_Antiquity:GetAntiquityCategoryData()
    return self.antiquityCategoryData
end

function ZO_Antiquity:GetAntiquitySetData()
    return self.antiquitySetData
end

function ZO_Antiquity:GetDifficulty()
    return self.difficulty
end

function ZO_Antiquity:GetRewardId()
    return self.rewardId
end

function ZO_Antiquity:HasReward()
    return self.rewardId ~= 0
end

function ZO_Antiquity:GetName()
    return self.name
end

function ZO_Antiquity:GetColorizedName()
    local colorDef = GetAntiquityQualityColor(self:GetQuality())
    return colorDef:Colorize(self:GetName())
end

function ZO_Antiquity:GetFormattedName()
    return ZO_CachedStrFormat(SI_ANTIQUITY_NAME_FORMATTER, self.name)
end

function ZO_Antiquity:GetColorizedFormattedName()
    local colorDef = GetAntiquityQualityColor(self:GetQuality())
    return colorDef:Colorize(self:GetFormattedName())
end

function ZO_Antiquity:GetIcon()
    return self.icon
end

function ZO_Antiquity:GetLeadTimeRemainingS()
    if self:HasLead() then
        return self.leadExpirationTimeS - GetFrameTimeSeconds()
    end
    return 0
end

function ZO_Antiquity:RequiresLead()
    return self.requiresLead
end

function ZO_Antiquity:HasLead()
    return self.hasLead
end

function ZO_Antiquity:HasNewLead()
    return self.hasNewLead
end

function ZO_Antiquity:MeetsLeadRequirements()
    return not self:RequiresLead() or self:HasLead()
end

function ZO_Antiquity:GetNumDigSites()
    return self.numDigSites
end

function ZO_Antiquity:HasDiscoveredDigSites()
    return self.numDigSites > 0
end

function ZO_Antiquity:HasNoDiscoveredDigSites()
    return not self:HasDiscoveredDigSites()
end

function ZO_Antiquity:GetLastNumGoalsAchieved()
    return self.lastNumGoalsAchieved or 0
end

function ZO_Antiquity:GetNumGoalsAchieved()
    return self.numGoalsAchieved
end

function ZO_Antiquity:GetTotalNumGoals()
    return GetTotalNumGoalsForAntiquity(self:GetId())
end

function ZO_Antiquity:HasAchievedAllGoals()
    return self:GetNumGoalsAchieved() >= self:GetTotalNumGoals()
end

function ZO_Antiquity:IsInProgress()
    return self:GetNumGoalsAchieved() > 0
end

function ZO_Antiquity:IsInZone(zoneId)
    return self:GetZoneId() == 0 or self:GetZoneId() == zoneId
end

function ZO_Antiquity:IsInCurrentPlayerZone()
    return self:IsInZone(ZO_ExplorationUtils_GetPlayerCurrentZoneId())
end

function ZO_Antiquity:GetNumRecovered()
    return self.numRecovered
end

function ZO_Antiquity:GetQuality()
    return self.quality
end

function ZO_Antiquity:HasRecovered()
    return self:GetNumRecovered() > 0
end

function ZO_Antiquity:HasDiscovered()
    return self:HasRecovered() or self:MeetsLeadRequirements()
end

function ZO_Antiquity:IsRepeatable()
    return self.isRepeatable
end

function ZO_Antiquity:IsVisible()
    local isVisible, errorStringId = DoesAntiquityPassVisibilityRequirements(self.antiquityId)
    return isVisible, errorStringId
end

function ZO_Antiquity:NeedsCombination()
    return self.needsCombination
end

function ZO_Antiquity:IsSetFragment()
    return self:GetAntiquitySetData() ~= nil
end

-- Antiquities and non-repeatable set fragments are complete once recovered; a repeatable set fragment is complete when it is ready for combination.
function ZO_Antiquity:IsComplete()
    if self:IsSetFragment() then
        return self:NeedsCombination() or (self:HasRecovered() and not self:IsRepeatable())
    else
        return self:HasRecovered()
    end
end

function ZO_Antiquity:MeetsAllScryingRequirements()
    local scryingResult = MeetsAntiquityRequirementsForScrying(self:GetId(), ZO_ExplorationUtils_GetPlayerCurrentZoneId())
    return scryingResult == ANTIQUITY_SCRYING_RESULT_SUCCESS
end

function ZO_Antiquity:MeetsScryingSkillRequirements()
    return MeetsAntiquitySkillRequirementsForScrying(self:GetId())
end

function ZO_Antiquity:CanScry()
    local scryResult = CanScryForAntiquity(self:GetId())
    if scryResult == ANTIQUITY_SCRYING_RESULT_SUCCESS then
        return true
    else
        return false, GetString("SI_ANTIQUITYSCRYINGRESULT", scryResult)
    end
end

function ZO_Antiquity:GetLoreEntries()
    return self.loreEntries
end

function ZO_Antiquity:GetLoreEntry(loreEntryIndex)
    return self.loreEntries[loreEntryIndex]
end

function ZO_Antiquity:GetNumLoreEntries()
    return #self.loreEntries
end

function ZO_Antiquity:GetNumUnlockedLoreEntries()
    return self.numLoreEntriesAcquired
end

function ZO_Antiquity:GetZoneId()
    return self.zoneId
end

function ZO_Antiquity:IsTracked()
    return GetTrackedAntiquityId() == self:GetId()
end

function ZO_Antiquity:CompareNameTo(antiquity)
    return self:GetName() < antiquity:GetName()
end

function ZO_Antiquity:CompareSetAndNameTo(antiquity)
    local setData = self:GetAntiquitySetData()
    local compareToSetData = antiquity:GetAntiquitySetData()

    if setData then
        if compareToSetData then
            if setData:GetId() ~= compareToSetData:GetId() then
                -- Order sets by set name.
                return setData:GetName() < compareToSetData:GetName()
            else
                -- Order each set's antiquities by antiquity name.
                return self:GetName() < antiquity:GetName()
            end
        else
            -- Order sets before non-sets.
            return true
        end
    elseif not compareToSetData then
        -- Order non-sets by antiquity name.
        return self:GetName() < antiquity:GetName()
    end
end

-- Filter Helpers

function ZO_Antiquity:IsScryable()
    return not self:HasAchievedAllGoals() and self:MeetsLeadRequirements() and self:IsInCurrentPlayerZone() and self:MeetsAllScryingRequirements()
end

function ZO_Antiquity:IsScryableFromZone(zoneId)
    return not self:HasAchievedAllGoals() and self:MeetsLeadRequirements() and self:IsInZone(zoneId)
end

function ZO_Antiquity:IsActionable()
    return self:MeetsLeadRequirements()
end
