ZO_CampaignSelector_Shared = ZO_Object:Subclass()

function ZO_CampaignSelector_Shared:New(control)
    local selector = ZO_Object.New(self)
    selector:Initialize(control)
    return selector
end

function ZO_CampaignSelector_Shared:Initialize(control)
    -- Any code added here will affect derived classes
end

function ZO_CampaignSelector_Shared:RefreshQueryTypes()
    -- Should be overridden
end

function ZO_CampaignSelector_Shared:NeedsData()
    return (CAMPAIGN_SELECTOR_FRAGMENT:IsShowing() and self.selectedQueryType == BGQUERY_ASSIGNED_CAMPAIGN)
end

function ZO_CampaignSelector_Shared:GetCampaignId()
    if(self.selectedQueryType == BGQUERY_LOCAL) then
        return GetCurrentCampaignId()
    elseif(self.selectedQueryType == BGQUERY_ASSIGNED_CAMPAIGN) then
        return GetAssignedCampaignId()
    end
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
    if(self.selectedQueryType == BGQUERY_LOCAL) then
        self:UpdateCampaignWindows()
    end
end

function ZO_CampaignSelector_Shared:OnAssignedCampaignChanged()
    self:RefreshQueryTypes()
    if(self.selectedQueryType == BGQUERY_ASSIGNED_CAMPAIGN) then
        self:UpdateCampaignWindows()
    end
end