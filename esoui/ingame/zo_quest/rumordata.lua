ZO_RumorData = ZO_InitializingObject:Subclass()

function ZO_RumorData:Initialize(rumorId)
    self.rumorId = rumorId
end

function ZO_RumorData:GetId()
    return self.rumorId
end

function ZO_RumorData:GetRumorType()
    return GetRumorType(self.rumorId)
end

function ZO_RumorData:IsRumorType(rumorType)
    return GetRumorType(self.rumorId) == rumorType
end

function ZO_RumorData:IsPending()
    return IsRumorPending(self.rumorId)
end

function ZO_RumorData:IsComplete()
    return IsRumorComplete(self.rumorId)
end

function ZO_RumorData:IsNotComplete()
    return not self:IsComplete()
end

function ZO_RumorData:GetDisplayName()
    return GetRumorDisplayName(self.rumorId)
end

function ZO_RumorData:GetFormattedDisplayName()
    return zo_strformat(SI_RUMOR_NAME_FORMATTER, GetRumorDisplayName(self.rumorId))
end

function ZO_RumorData:GetBackgroundText()
    return GetRumorBackgroundText(self.rumorId)
end

function ZO_RumorData:GetCompleteText()
    return GetRumorCompleteText(self.rumorId)
end

function ZO_RumorData:GetNumHints()
    return GetNumHintsForPendingRumor(self.rumorId)
end

function ZO_RumorData:HasDiscoveredHint(hintIndex)
    return HasDiscoveredRumorHint(self.rumorId, hintIndex)
end

function ZO_RumorData:GetHintDisplayName(hintIndex)
    return GetRumorHintDisplayName(self.rumorId, hintIndex)
end

function ZO_RumorData:GetHintDescription(hintIndex)
    return GetRumorHintDescription(self.rumorId, hintIndex)
end

function ZO_RumorData:GetHintIcon(hintIndex)
    return GetRumorHintIcon(self.rumorId, hintIndex)
end

function ZO_RumorData:GetHintBook(hintIndex)
    return GetRumorHintBook(self.rumorId, hintIndex)
end
