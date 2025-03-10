-------------------------------
-- Promotional Event Manager --
-------------------------------

ZO_PromotionalEvent_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_PromotionalEvent_Manager:Initialize()
    self:RefreshCampaignData()

    local isInGameUI = ZO_IsIngameUI()
    if isInGameUI then
        EVENT_MANAGER:RegisterForEvent("PromotionalEventManager", EVENT_SHOW_PROMOTIONAL_EVENT_SCENE, function() self:ShowPromotionalEventScene() end)
        EVENT_MANAGER:RegisterForEvent("PromotionalEventManager", EVENT_PROMOTIONAL_EVENTS_REWARDS_CLAIMED, ZO_GetEventForwardingFunction(self, self.OnRewardsClaimed))
    end

    local function OnCampaignsUpdated()
        local FORCE_CLEAN_SEEN = true
        self:RefreshCampaignData(FORCE_CLEAN_SEEN)
        if isInGameUI and not IsActiveWorldStarterWorld() then
            TryAutoTrackNextPromotionalEventCampaign()
        end
    end
    EVENT_MANAGER:RegisterForEvent("PromotionalEventManager", EVENT_PROMOTIONAL_EVENTS_CAMPAIGNS_UPDATED, OnCampaignsUpdated)

    local function OnAddOnLoaded(_, name)
        if name == "ZO_Ingame" then
            local defaults =
            {
                seenCampaignKeys = {}
            }
            self.savedVars = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 1, "PromotionalEvents", defaults)

            if #self.activeCampaignDataList > 0 then
                self:CleanupSeenCampaigns()
            end
            EVENT_MANAGER:UnregisterForEvent("PromotionalEventManager", EVENT_ADD_ON_LOADED)
        end
    end
    EVENT_MANAGER:RegisterForEvent("PromotionalEventManager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

function ZO_PromotionalEvent_Manager:RefreshCampaignData(forceCleanSeen)
    if self.activeCampaignDataList then
        ZO_ClearNumericallyIndexedTable(self.activeCampaignDataList)
    else
        self.activeCampaignDataList = {}
    end

    for i = 1, GetNumActivePromotionalEventCampaigns() do
        local campaignKey = GetActivePromotionalEventCampaignKey(i)
        local campaignData = ZO_PromotionalEventCampaignData:New(campaignKey)
        table.insert(self.activeCampaignDataList, campaignData)
    end

    if forceCleanSeen or #self.activeCampaignDataList > 0 then
        -- If there are no campaigns, we might not have received the info from the server yet
        -- so we can't be sure we have accurate data yet. So only clean up if we know there are campaigns
        -- Or we're receiving an event about the campaigns
        self:CleanupSeenCampaigns()
    end

    self:FireCallbacks("CampaignsUpdated")
end

function ZO_PromotionalEvent_Manager:CleanupSeenCampaigns()
    if self.savedVars then
        local seenCampaignKeys = {}
        for _, campaignData in ipairs(self.activeCampaignDataList) do
            local key = campaignData:GetKeyString()
            if self.savedVars.seenCampaignKeys[key] then
                seenCampaignKeys[key] = true
            end
        end
        self.savedVars.seenCampaignKeys = seenCampaignKeys
    end
end

function ZO_PromotionalEvent_Manager:ShowPromotionalEventScene(scrollToFirstClaimableReward)
    if ZO_IsIngameUI() then
        local systemObject
        if IsInGamepadPreferredMode() then
            ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(PROMOTIONAL_EVENTS_GAMEPAD:GetCategoryData())
            systemObject = PROMOTIONAL_EVENTS_GAMEPAD
        else
            GROUP_MENU_KEYBOARD:ShowCategory(PROMOTIONAL_EVENTS_KEYBOARD.fragment) -- TODO Promotional Events: Add a way to specifically open a particular subcategory
            systemObject = PROMOTIONAL_EVENTS_KEYBOARD
        end
        if scrollToFirstClaimableReward then
            systemObject:ScrollToFirstClaimableReward()
        end
    else
        ShowPromotionalEventScene()
    end
end

function ZO_PromotionalEvent_Manager:OnRewardsClaimed(campaignKey)
    local campaignData = self:GetCampaignDataByKey(campaignKey)
    if campaignData then
        local rewardKeys = { GetRecentlyClaimedPromotionalEventRewards(campaignKey) }
        local rewards = {}
        for i = 1, #rewardKeys, 2 do
            local reward =
            {
                type = rewardKeys[i],
                index = rewardKeys[i + 1],
            }
            local rewardableEventData
            if reward.type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_SCHEDULE then
                rewardableEventData = campaignData
            elseif reward.type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_MILESTONE_REWARD then
                rewardableEventData = campaignData:GetMilestoneData(reward.index)
            elseif reward.type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_ACTIVITY then
                rewardableEventData = campaignData:GetActivityData(reward.index)
            end
            reward.rewardableEventData = rewardableEventData
            table.insert(rewards, reward)
        end
        self:FireCallbacks("RewardsClaimed", campaignData, rewards)
    end
end

function ZO_PromotionalEvent_Manager:HasActiveCampaign()
    return #self.activeCampaignDataList > 0
end

function ZO_PromotionalEvent_Manager:GetNumActiveCampaigns()
    return #self.activeCampaignDataList
end

function ZO_PromotionalEvent_Manager:GetCampaignDataByIndex(campaignIndex)
    return self.activeCampaignDataList[campaignIndex]
end

function ZO_PromotionalEvent_Manager:GetCampaignDataByKey(campaignKey)
    if CompareId64ToNumber(campaignKey, 0) ~= 0 then
        for _, campaignData in ipairs(self.activeCampaignDataList) do
            if AreId64sEqual(campaignKey, campaignData:GetKey()) then
                return campaignData
            end
        end
    end
    return nil
end

function ZO_PromotionalEvent_Manager:HasCampaignBeenSeen(campaignData)
    if self.savedVars then
        local keyString = campaignData:GetKeyString()
        return self.savedVars.seenCampaignKeys[keyString] == true
    end
    return false
end

function ZO_PromotionalEvent_Manager:SetCampaignSeen(campaignData, seen)
    if self.savedVars then
        seen = seen ~= false -- nil => true
        local keyString = campaignData:GetKeyString()
        if self.savedVars.seenCampaignKeys[keyString] ~= seen then
            self.savedVars.seenCampaignKeys[keyString] = seen
            self:FireCallbacks("CampaignSeenStateChanged", campaignData)
        end
    end
end

function ZO_PromotionalEvent_Manager:DoesAnyCampaignHaveCallout()
    if not IsPromotionalEventSystemLocked() then
        for _, campaignData in ipairs(self.activeCampaignDataList) do
            if (not campaignData:HasBeenSeen() or campaignData:IsAnyRewardClaimable()) then
                return true
            end
        end
    end
    return false
end

function ZO_PromotionalEvent_Manager:IsAnyRewardClaimable()
    if not IsPromotionalEventSystemLocked() then
        for _, campaignData in ipairs(self.activeCampaignDataList) do
            if campaignData:IsAnyRewardClaimable() then
                return true
            end
        end
    end
    return false
end

PROMOTIONAL_EVENT_MANAGER = ZO_PromotionalEvent_Manager:New()