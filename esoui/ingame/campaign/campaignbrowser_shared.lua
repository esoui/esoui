ZO_CampaignBrowser_Shared = ZO_Object:Subclass()

CAMPAIGN_QUEUE_INDIVIDUAL = false
CAMPAIGN_QUEUE_GROUP = true

local CAMPAIGN_DATA = 1
local CAMPAIGN_QUEUE_DATA = 2

function ZO_CampaignBrowser_Shared:New(...)
    return ZO_Object.New(self)
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
            local function QueueCallback()
                local canQueueIndividual, canQueueGroup = self:CanQueue(data)
                if(canQueueIndividual and canQueueGroup) then
                    if IsInGamepadPreferredMode() then
                        ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_QUEUE_DIALOG, data, { mainTextParams = { data.name } })
                    else
                        ZO_Dialogs_ShowDialog("CAMPAIGN_QUEUE", {campaignId = data.id}, {mainTextParams = {data.name}})
                    end
                elseif(canQueueIndividual) then
                    QueueForCampaign(data.id, CAMPAIGN_QUEUE_INDIVIDUAL)
                else
                    QueueForCampaign(data.id, CAMPAIGN_QUEUE_GROUP)
                end
            end

            if IsInLFGGroup() and GetCurrentLFGActivity() ~= LFG_ACTIVITY_AVA then
                ZO_Dialogs_ShowPlatformDialog("CAMPAIGN_QUEUE_KICKING_FROM_LFG_GROUP_WARNING", {onAcceptCallback = QueueCallback })
            else
                QueueCallback()
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

function ZO_CampaignBrowser_Shared:ShowCampaignQueueReadyDialog(campaignId, isGroup, campaignName)
    local timeLeftSeconds = GetCampaignQueueRemainingConfirmationSeconds(campaignId, isGroup)
    if timeLeftSeconds > 0 then
        local timeString = ZO_FormatTime(timeLeftSeconds, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
        ZO_Dialogs_ShowPlatformDialog("CAMPAIGN_QUEUE_READY", {campaignId = campaignId, isGroup = isGroup, timeLeftSeconds = timeLeftSeconds }, {mainTextParams = { campaignName, timeString }})
    else
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, nil, SI_CAMPAIGN_BROWSER_QUEUE_ACCEPT_ERROR_EXPIRED)
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

    local QUEUE_MESSAGES = {
        [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_JOIN] = GetString(SI_CAMPAIGN_BROWSER_QUEUE_PENDING_JOIN),
        [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_LEAVE] = GetString(SI_CAMPAIGN_BROWSER_QUEUE_PENDING_LEAVE),
        [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_ACCEPT] = GetString(SI_CAMPAIGN_BROWSER_QUEUE_PENDING_ACCEPT),
    }
    
    function ZO_CampaignBrowser_Shared:GetQueueMessage(id, isGroup, state)
        local queueMessage = QUEUE_MESSAGES[state]
        
        if queueMessage then
            return true, queueMessage
        else
            local descrtiptionText
            local iconTexture

            if(state == CAMPAIGN_QUEUE_REQUEST_STATE_WAITING) then
                iconTexture = "EsoUI/Art/Campaign/campaignBrowser_queued.dds"
            elseif(state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING) then
                iconTexture = "EsoUI/Art/Campaign/campaignBrowser_ready.dds"
            end
    
            if(state == CAMPAIGN_QUEUE_REQUEST_STATE_WAITING) then
                local positionInQueue = GetCampaignQueuePosition(id, isGroup)
                if(isGroup) then
                    if IsAnyGroupMemberOffline() then
                        descrtiptionText = GetString(SI_CAMPAIGN_BROWSER_GROUP_PAUSED)
                    else
                         descrtiptionText = zo_strformat(SI_CAMPAIGN_BROWSER_GROUP_QUEUED, positionInQueue)
                    end
                else
                    descrtiptionText = zo_strformat(SI_CAMPAIGN_BROWSER_SOLO_QUEUED, positionInQueue)
                end
            elseif(state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING) then
                local timeString = ZO_FormatTime(GetCampaignQueueRemainingConfirmationSeconds(id, isGroup), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
                if(isGroup) then            
                    descrtiptionText = zo_strformat(SI_CAMPAIGN_BROWSER_GROUP_READY, timeString)
                else
                    descrtiptionText = zo_strformat(SI_CAMPAIGN_BROWSER_SOLO_READY, timeString)
                end
            end

            return false, descrtiptionText, iconTexture
        end
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





















