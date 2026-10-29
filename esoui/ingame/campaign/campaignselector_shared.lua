ZO_CampaignSelector_Shared = ZO_InitializingObject:Subclass()

function ZO_CampaignSelector_Shared:Initialize(control, allowAllActiveCampaigns)
    self.allowAllActiveCampaigns = allowAllActiveCampaigns
    self:SetCampaignWindows()
    if allowAllActiveCampaigns then
        CAMPAIGN_BROWSER_MANAGER:RegisterCallback("OnCampaignDataUpdated", function() self:RefreshQueryTypes() end)
    end

    control:RegisterForEvent(EVENT_CURRENT_CAMPAIGN_CHANGED, function() self:OnCurrentCampaignChanged() end)
    control:RegisterForEvent(EVENT_ASSIGNED_CAMPAIGN_CHANGED, function() self:OnAssignedCampaignChanged() end)
end

ZO_CampaignSelector_Shared:MUST_IMPLEMENT("SetCampaignWindows")
ZO_CampaignSelector_Shared:MUST_IMPLEMENT("RefreshQueryTypes")
ZO_CampaignSelector_Shared:MUST_IMPLEMENT("NeedsData")

function ZO_CampaignSelector_Shared:IsHomeSelectable()
    return self:IsQueryTypeSelectable(BGQUERY_ASSIGNED_CAMPAIGN)
end

function ZO_CampaignSelector_Shared:IsLocalSelectable()
    return self:IsQueryTypeSelectable(BGQUERY_LOCAL)
end

function ZO_CampaignSelector_Shared:IsSelectedQueryStillValid()
    if self.allowAllActiveCampaigns then
        return true
    end
    return self:IsQueryTypeSelectable(self.selectedQueryType)
end

function ZO_CampaignSelector_Shared:GetCampaignId(overrideQueryType)
    if self.allowAllActiveCampaigns then
        return self.selectedCampaignId
    end

    local queryType = overrideQueryType or self.selectedQueryType
    if queryType == BGQUERY_LOCAL then
        return GetCurrentCampaignId()
    elseif queryType == BGQUERY_ASSIGNED_CAMPAIGN then
        return GetAssignedCampaignId()
    end
end

function ZO_CampaignSelector_Shared:GetCampaignRulesetId(overrideQueryType)
    local campaignId = self:GetCampaignId(overrideQueryType)
    return GetCampaignRulesetId(campaignId)
end

function ZO_CampaignSelector_Shared:GetCampaignRulesetType(overrideQueryType)
    local campaignRulesetId = self:GetCampaignRulesetId(overrideQueryType)
    if campaignRulesetId ~= 0 then
        return GetCampaignRulesetType(campaignRulesetId)
    end
    return nil
end

function ZO_CampaignSelector_Shared:DoesQueryTypeSupportBonuses(overrideQueryType)
    local campaignRulesetType = self:GetCampaignRulesetType(overrideQueryType)
    return campaignRulesetType == CAMPAIGN_RULESET_TYPE_CYRODIIL
end

function ZO_CampaignSelector_Shared:DoesQueryTypeSupportEmperor(overrideQueryType)
    local campaignRulesetType = self:GetCampaignRulesetType(overrideQueryType)
    return campaignRulesetType == CAMPAIGN_RULESET_TYPE_CYRODIIL
end

function ZO_CampaignSelector_Shared:GetQueryType()
    return self.selectedQueryType
end

function ZO_CampaignSelector_Shared:UpdateCampaignWindows()
    for _, window in ipairs(self.campaignWindows) do
        window:SetCampaignAndQueryType(self:GetCampaignId(), self.selectedQueryType)
    end
end

--Events

function ZO_CampaignSelector_Shared:OnCurrentCampaignChanged()
    self:RefreshQueryTypes()
    if self.selectedQueryType == BGQUERY_LOCAL then
        self:UpdateCampaignWindows()
    end
end

function ZO_CampaignSelector_Shared:OnAssignedCampaignChanged()
    self:RefreshQueryTypes()
    if self.selectedQueryType == BGQUERY_ASSIGNED_CAMPAIGN then
        self:UpdateCampaignWindows()
    end
end

function ZO_CampaignSelector_Shared:SetQueryTypeEnabledCondition(conditionFunction)
    self.queryTypeEnabledConditionFunction = conditionFunction
    self:RefreshQueryTypes()
end

function ZO_CampaignSelector_Shared:SetQueryTypeSelectableCondition(conditionFunction)
    self.queryTypeSelectableConditionFunction = conditionFunction
    self:RefreshQueryTypes()
end

function ZO_CampaignSelector_Shared:IsQueryTypeSelectable(queryType)
    if ZO_EvalDefaultTrue(self.queryTypeSelectableConditionFunction, queryType) then
        if queryType == BGQUERY_ASSIGNED_CAMPAIGN then
            return GetAssignedCampaignId() ~= 0
        elseif queryType == BGQUERY_LOCAL then
            local currentId = GetCurrentCampaignId()
            local assignedId = GetAssignedCampaignId()
            return currentId ~= 0 and currentId ~= assignedId
        end
    end
end

function ZO_CampaignSelector_Shared:ShouldShowCampaignSelector()
    return self:IsQueryTypeSelectable(BGQUERY_ASSIGNED_CAMPAIGN) or self:IsQueryTypeSelectable(BGQUERY_LOCAL)
end