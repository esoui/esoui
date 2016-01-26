ZO_CampaignBrowser_Shared = ZO_Object:Subclass()

CAMPAIGN_QUEUE_INDIVIDUAL = false
CAMPAIGN_QUEUE_GROUP = true

local CAMPAIGN_DATA = 1
local CAMPAIGN_QUEUE_DATA = 2

function ZO_CampaignBrowser_Shared:New(...)
    return ZO_Object.New(self, ...)
end

function ZO_CampaignBrowser_Shared:CanHome(data)
    if data then
        if(data.type == CAMPAIGN_DATA) then
            if(GetAssignedCampaignId() ~= data.id and DoesPlayerMeetCampaignRequirements(data.id)) then
                return true
            end
        end
    end
end

function ZO_CampaignBrowser_Shared:CanGuest(data)
    if data then
        if(data.type == CAMPAIGN_DATA) then
            if(GetGuestCampaignId() ~= data.id and GetAssignedCampaignId() ~= data.id and DoesPlayerMeetCampaignRequirements(data.id)) then
                return true
            end
        end
    end
end

function ZO_CampaignBrowser_Shared:CanQueue(data)
    local canQueueIndividual = false
    local canQueueGroup = false
    if data then
        if(GetCurrentCampaignId() ~= data.id and DoesPlayerMeetCampaignRequirements(data.id)) then
            if(GetAssignedCampaignId() == data.id or GetGuestCampaignId() == data.id or data.numGroupMembers > 0) then
                canQueueIndividual = not IsQueuedForCampaign(data.id, CAMPAIGN_QUEUE_INDIVIDUAL)
                if(not IsQueuedForCampaign(data.id, CAMPAIGN_QUEUE_GROUP)) then
                    if(IsUnitGrouped("player") and IsUnitGroupLeader("player") and not IsInLFGGroup()) then
                        canQueueGroup = true
                    end
                end        
            end
        end
    end
    return canQueueIndividual, canQueueGroup
end

function ZO_CampaignBrowser_Shared:CanLeave(data)
    if data then
        if(data.type == CAMPAIGN_QUEUE_DATA) then
            if(IsQueuedForCampaign(data.id, data.isGroup)) then
                return true
            end
        end
    end
end

function ZO_CampaignBrowser_Shared:DoQueue(data)
    if data then
        if(data.type == CAMPAIGN_DATA) then
            local canQueueIndividual, canQueueGroup = self:CanQueue(data)
            if(canQueueIndividual and canQueueGroup) then
                ZO_Dialogs_ShowDialog("CAMPAIGN_QUEUE", {campaignId = data.id}, {mainTextParams = {data.name}})
            elseif(canQueueIndividual) then
                QueueForCampaign(data.id, CAMPAIGN_QUEUE_INDIVIDUAL)
            else
                QueueForCampaign(data.id, CAMPAIGN_QUEUE_GROUP)
            end
        end
    end
end

function ZO_CampaignBrowser_Shared:GetCampaignType()
    return CAMPAIGN_DATA
end

function ZO_CampaignBrowser_Shared:GetQueueType(data)
    return CAMPAIGN_QUEUE_DATA
end

function ZO_CampaignBrowser_Shared:GetMasterHomeData()
    return self:GetDataByCampaignId(GetAssignedCampaignId())
end

function ZO_CampaignBrowser_Shared:GetMasterGuestData()
    return self:GetDataByCampaignId(GetGuestCampaignId())
end

function ZO_CampaignBrowser_Shared:SetupQueuedData(data)
    if data then
        local queuedIndividual = IsQueuedForCampaign(data.id, CAMPAIGN_QUEUE_INDIVIDUAL)
        local queuedGroup = IsQueuedForCampaign(data.id, CAMPAIGN_QUEUE_GROUP)
        data.queuedIndividualType = self:GetQueueType()
        data.queuedIndividualState = GetCampaignQueueState(data.id, CAMPAIGN_QUEUE_INDIVIDUAL)
        data.queuedGroupType = self:GetQueueType()
        data.queuedGroupState = GetCampaignQueueState(data.id, CAMPAIGN_QUEUE_GROUP)
    end
end

function ZO_CampaignBrowser_Shared:BuildMasterList()
    self.masterList = {}

    local assignedCampaign = GetAssignedCampaignId()
    local guestCampaign = GetGuestCampaignId()

    for i = 1, GetNumSelectionCampaigns() do
        local currentPop1 = GetSelectionCampaignPopulationData(i, 1)
        local currentPop2 = GetSelectionCampaignPopulationData(i, 2)
        local currentPop3 = GetSelectionCampaignPopulationData(i, 3)
        local campaignId = GetSelectionCampaignId(i)
        local rulesetId = GetCampaignRulesetId(campaignId)
        local rulesetType = GetCampaignRulesetType(rulesetId)
        local rulesetName = GetCampaignRulesetName(rulesetId)

        self.masterList[i] = {}

        self.masterList[i].name = zo_strformat(SI_CAMPAIGN_NAME, GetCampaignName(campaignId))
        self.masterList[i].type = CAMPAIGN_DATA
        self.masterList[i].id = campaignId
        self.masterList[i].rulesetId = rulesetId
        self.masterList[i].rulesetType = rulesetType
        self.masterList[i].numGroupMembers = GetNumSelectionCampaignGroupMembers(i)
        self.masterList[i].numFriends = GetNumSelectionCampaignFriends(i)
        self.masterList[i].numGuildMembers = GetNumSelectionCampaignGuildMembers(i)
        self.masterList[i].alliancePopulation1 = currentPop1
        self.masterList[i].alliancePopulation2 = currentPop2
        self.masterList[i].alliancePopulation3 = currentPop3

        self:SetupQueuedData(self.masterList[i])
    end

    return self.masterList
end

function ZO_CampaignBrowser_Shared:BuildCategoriesList()
    
    local function compareDuration(rulesetIdA, rulesetIdB)
        return (GetCampaignRulesetDurationInSeconds(rulesetIdA) > GetCampaignRulesetDurationInSeconds(rulesetIdB))
    end

    self.rulesetTypes = {}
    
    for i = 1, #self.masterList do
        local campaignData = self.masterList[i]
        local campaignRulesetId = campaignData.rulesetId
        local campaignRulesetType = campaignData.rulesetType
        
        if(not self.rulesetTypes[campaignRulesetType]) then
            self.rulesetTypes[campaignRulesetType] = {}
        end

        local addToList = true
        for key, value in ipairs(self.rulesetTypes[campaignRulesetType]) do
            if (value == campaignRulesetId) then
                addToList = false
                break
            end
        end
        
        if (addToList) then
            table.insert(self.rulesetTypes[campaignRulesetType], campaignRulesetId)
        end
    end

    for i = 1, GetNumCampaignRulesetTypes() do
        local rulesetIds = self.rulesetTypes[i]
        if(rulesetIds) then
            table.sort(rulesetIds, compareDuration)
        end
    end

    return self.rulesetTypes
end

function ZO_CampaignBrowser_Shared:DoLeave(data)
    if(data.type == CAMPAIGN_QUEUE_DATA) then
        if(IsQueuedForCampaign(data.id, data.isGroup)) then
            if(data.state == CAMPAIGN_QUEUE_REQUEST_STATE_WAITING) then
                LeaveCampaignQueue(data.id, data.isGroup)
            elseif(data.state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING) then
                ConfirmCampaignEntry(data.id, data.isGroup, false)
            end
        end
    end
end

function ZO_CampaignBrowser_Shared:GetDataByCampaignId(campaignId)
    local masterData = nil
    local campaignTableData = nil
    if self.masterList then
        for i = 1,#self.masterList do
            local data = self.masterList[i]
            if(data.id == campaignId) then
                return data
            end
        end
    end
end

do
    local function IsAnyGroupMemberOffline()
        for i = 1, GROUP_SIZE_MAX do
            local unitTag = ZO_Group_GetUnitTagForGroupIndex(i)
            if not IsUnitOnline(unitTag) then
                return true
            end
        end
    
        return false
    end
    
    function ZO_CampaignBrowser_Shared:ShowQueueMessage(description, icon, id, isGroup, state)
        icon:SetHidden(false)
        description:SetHidden(false)
    
        if(state == CAMPAIGN_QUEUE_REQUEST_STATE_WAITING) then
            icon:SetTexture("EsoUI/Art/Campaign/campaignBrowser_queued.dds")
        elseif(state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING) then
            icon:SetTexture("EsoUI/Art/Campaign/campaignBrowser_ready.dds")
        end
    
        if(state == CAMPAIGN_QUEUE_REQUEST_STATE_WAITING) then
            local positionInQueue = GetCampaignQueuePosition(id, isGroup)
            if(isGroup) then
                if IsAnyGroupMemberOffline() then
                    description:SetText(GetString(SI_CAMPAIGN_BROWSER_GROUP_PAUSED))
                else
                    description:SetText(zo_strformat(SI_CAMPAIGN_BROWSER_GROUP_QUEUED, positionInQueue))
                end
            else
                description:SetText(zo_strformat(SI_CAMPAIGN_BROWSER_SOLO_QUEUED, positionInQueue))
            end
        elseif(state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING) then
            seconds = ZO_FormatTime(GetCampaignQueueRemainingConfirmationSeconds(id, isGroup), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            if(isGroup) then            
                description:SetText(zo_strformat(SI_CAMPAIGN_BROWSER_GROUP_READY, seconds))
            else
                description:SetText(zo_strformat(SI_CAMPAIGN_BROWSER_SOLO_READY, seconds))
            end
        end
    end
end

local QUEUE_MESSAGES = {
    [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_JOIN] = GetString(SI_CAMPAIGN_BROWSER_QUEUE_PENDING_JOIN),
    [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_LEAVE] = GetString(SI_CAMPAIGN_BROWSER_QUEUE_PENDING_LEAVE),
    [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_ACCEPT] = GetString(SI_CAMPAIGN_BROWSER_QUEUE_PENDING_ACCEPT),
}

function ZO_CampaignBrowser_Shared:UpdateQueuedMessageControls(loading, description, icon, id, isGroup, state)
    local queueMessage = QUEUE_MESSAGES[state]
    if queueMessage then
        loading:SetText(queueMessage)

        icon:SetHidden(true)
        description:SetHidden(true)
        if(loading.Show) then
            loading:Show()
        else
            loading:SetHidden(false)
        end
    else
        if(loading.Hide) then
            loading:Hide()
        else
            loading:SetHidden(true)
        end
        
        self:ShowQueueMessage(description, icon, id, isGroup, state)
    end
end

local CAMPAIGN_RULESET_TYPE_ICONS =
{
    [CAMPAIGN_RULESET_TYPE_NORMAL] = 
    {
        up = "EsoUI/Art/Campaign/campaignBrowser_indexIcon_normal_up.dds",
        down = "EsoUI/Art/Campaign/campaignBrowser_indexIcon_normal_down.dds",
        over = "EsoUI/Art/Campaign/campaignBrowser_indexIcon_normal_over.dds",
    },
    [CAMPAIGN_RULESET_TYPE_HARDCORE] = 
    {
        up = "EsoUI/Art/Campaign/campaignBrowser_indexIcon_hardcore_up.dds",
        down = "EsoUI/Art/Campaign/campaignBrowser_indexIcon_hardcore_down.dds",
        over = "EsoUI/Art/Campaign/campaignBrowser_indexIcon_hardcore_over.dds",
    },
    [CAMPAIGN_RULESET_TYPE_SPECIAL] = 
    {
        up = "EsoUI/Art/Campaign/campaignBrowser_indexIcon_specialEvents_up.dds",
        down = "EsoUI/Art/Campaign/campaignBrowser_indexIcon_specialEvents_down.dds",
        over = "EsoUI/Art/Campaign/campaignBrowser_indexIcon_specialEvents_over.dds",
    },
}

local POPULATION_ICONS =
{
    [CAMPAIGN_POP_LOW] = "EsoUI/Art/Campaign/campaignBrowser_lowPop.dds",
    [CAMPAIGN_POP_MEDIUM] = "EsoUI/Art/Campaign/campaignBrowser_medPop.dds",
    [CAMPAIGN_POP_HIGH] = "EsoUI/Art/Campaign/campaignBrowser_hiPop.dds",
    [CAMPAIGN_POP_FULL] = "EsoUI/Art/Campaign/campaignBrowser_fullPop.dds",
}

function ZO_CampaignBrowser_GetPopulationIcon(population)
    return POPULATION_ICONS[population]
end

function ZO_CampaignBrowser_GetIcons(rulesetType)
    return CAMPAIGN_RULESET_TYPE_ICONS[rulesetType]
end





















