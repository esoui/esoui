-------------------------------
-- Promotional Event Manager --
-------------------------------

ZO_PromotionalEvent_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_PromotionalEvent_Manager:Initialize()
    self:RefreshCampaignData()

    self.syncObject = GetOrCreateSynchronizingObject("PromotionalEventManager")

    local isInGameUI = ZO_IsIngameUI()
    if isInGameUI then
        EVENT_MANAGER:RegisterForEvent("PromotionalEventManager", EVENT_PROMOTIONAL_EVENTS_ACTIVITY_PROGRESS_UPDATED, ZO_GetEventForwardingFunction(self, self.OnActivityProgressUpdated))
        self.syncObject:SetHandler("OnBroadcast", function(_, message)
            local campaignKey = StringToId64(message)
            local campaignData = self:GetCampaignDataByKey(campaignKey)
            local DONT_SCROLL_TO_REWARD = false
            self:ShowPromotionalEventScene(DONT_SCROLL_TO_REWARD, campaignData)
        end)
    end

    local function OnCampaignsUpdated()
        local FORCE_CLEAN_SEEN = true
        self:RefreshCampaignData(FORCE_CLEAN_SEEN)
        if isInGameUI and not IsActiveWorldStarterWorld() then
            TryAutoTrackNextPromotionalEventCampaign()
        end
    end
    EVENT_MANAGER:RegisterForEvent("PromotionalEventManager", EVENT_PROMOTIONAL_EVENTS_CAMPAIGNS_UPDATED, OnCampaignsUpdated)
    EVENT_MANAGER:RegisterForEvent("PromotionalEventManager", EVENT_PROMOTIONAL_EVENTS_REWARDS_CLAIMED, ZO_GetEventForwardingFunction(self, self.OnRewardsClaimed))

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

    table.sort(self.activeCampaignDataList, ZO_PromotionalEventCampaignData.CompareTo)

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

if ZO_IsIngameUI() then
    function ZO_PromotionalEvent_Manager:ShowPromotionalEventScene(scrollToFirstClaimableReward, campaignData)
        local numActiveCampaigns = PROMOTIONAL_EVENT_MANAGER:GetNumActiveCampaigns()
        local showRoot = numActiveCampaigns == 1 -- TODO Promotional Events: WB will have a rule to create a sub list even if there's only 1 campaign visible, so adjust this logic too
        local systemObject
        if IsInGamepadPreferredMode() then
            ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(PROMOTIONAL_EVENTS_GAMEPAD:GetCategoryData())
            if not showRoot then
                PROMOTIONAL_EVENTS_LIST_GAMEPAD:SelectCampaign(campaignData)
            end
            systemObject = PROMOTIONAL_EVENTS_GAMEPAD
        else
            if showRoot then
                GROUP_MENU_KEYBOARD:ShowCategory(PROMOTIONAL_EVENTS_KEYBOARD.fragment)
            else
                GROUP_MENU_KEYBOARD:ShowCategoryByData(campaignData)
            end
            systemObject = PROMOTIONAL_EVENTS_KEYBOARD
        end

        if scrollToFirstClaimableReward then
            systemObject:ScrollToFirstClaimableReward()
        end
    end
else
    function ZO_PromotionalEvent_Manager:ShowPromotionalEventScene(campaignData)
        local campaignKey = campaignData and campaignData:GetKeyString() or nil
        self.syncObject:Broadcast(campaignKey)
    end
end

function ZO_PromotionalEvent_Manager:OnActivityProgressUpdated(campaignKey, activityIndex, previousProgress, newProgress, rewardFlags)
    local campaignData = self:GetCampaignDataByKey(campaignKey)
    if campaignData then
        local activityData = campaignData:GetActivityData(activityIndex)
        if activityData then
            campaignData:OnActivityProgressUpdated(activityData, previousProgress, newProgress, rewardFlags)
            self:FireCallbacks("ActivityProgressUpdated", activityData, previousProgress, newProgress, rewardFlags)
        end
    end
end

function ZO_PromotionalEvent_Manager:OnRewardsClaimed(campaignKey)
    local campaignData = self:GetCampaignDataByKey(campaignKey)
    if campaignData then
        campaignData:OnRewardsClaimed()
        local isInGameUI = ZO_IsIngameUI()
        if isInGameUI then
            local rewardKeys = { GetRecentlyClaimedPromotionalEventRewards(campaignKey) }
            local rewards = {}
            local hasCapstoneReward = false
            for i = 1, #rewardKeys, 2 do
                local reward =
                {
                    type = rewardKeys[i],
                    index = rewardKeys[i + 1],
                }
                local rewardableEventData
                if reward.type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_SCHEDULE then
                    rewardableEventData = campaignData
                    hasCapstoneReward = true
                elseif reward.type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_MILESTONE_REWARD then
                    rewardableEventData = campaignData:GetMilestoneData(reward.index)
                elseif reward.type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_ACTIVITY then
                    rewardableEventData = campaignData:GetActivityData(reward.index)
                end
                reward.rewardableEventData = rewardableEventData
                table.insert(rewards, reward)
            end
            self:FireCallbacks("RewardsClaimed", campaignData, rewards, hasCapstoneReward)
        else
            -- Internal doesn't need to know about the actual rewards, only the AreAllRewardsClaimed function
            self:FireCallbacks("RewardsClaimed", campaignData)
        end
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

function ZO_PromotionalEvent_Manager:CampaignIterator(campaignFilterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.activeCampaignDataList, campaignFilterFunctions)
end

function ZO_PromotionalEvent_Manager:GetCampaignDataByKey(campaignKey)
    if not IsId64EqualToNumber(campaignKey, 0) then
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

function ZO_PromotionalEvent_Manager:OnCapstoneDialogClosed()
    self:FireCallbacks("CapstoneDialogClosed")
end

function ZO_PromotionalEvent_Manager:AreAnyReturningPlayerCampaignsIncomplete()
    if self:HasActiveCampaign() then
        for _, campaign in ipairs(self.activeCampaignDataList) do
            if campaign:IsReturningPlayerCampaign() and not campaign:AreAllRewardsClaimed() then
                return true
            end
        end
    end
    return false
end

function ZO_PromotionalEvent_Manager:DoesAnyCampaignHaveCallout()
    if not IsPromotionalEventSystemLocked() then
        for _, campaignData in ipairs(self.activeCampaignDataList) do
            if campaignData:ShouldCampaignBeVisible() and (not campaignData:HasBeenSeen() or campaignData:IsAnyRewardClaimable()) then
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
                local firstCampaignWithClaimableReward = campaignData
                return true, firstCampaignWithClaimableReward
            end
        end
    end
    return false
end

function ZO_PromotionalEvent_Manager:AreAllRewardsClaimed()
    if not IsPromotionalEventSystemLocked() then
        for _, campaignData in ipairs(self.activeCampaignDataList) do
            if not campaignData:AreAllRewardsClaimed() then
                return false
            end
        end
        return true
    end
    return false
end

-- Distinct from IsAnyRewardClaimable, this includes rewards you haven't earned yet
function ZO_PromotionalEvent_Manager:HasAnyUnclaimedRewards()
    if not IsPromotionalEventSystemLocked() then
        for _, campaignData in ipairs(self.activeCampaignDataList) do
            if campaignData:HasAnyUnclaimedRewards() then
                return true
            end
        end
    end
    return false
end

function ZO_PromotionalEvent_Manager:GetPromotionalEventsColorizedDisplayName()
    return ZO_PROMOTIONAL_EVENT_SELECTED_COLOR:Colorize(GetString(SI_ACTIVITY_FINDER_CATEGORY_PROMOTIONAL_EVENTS))
end

function ZO_PromotionalEvent_Manager:IsShowingCapstoneDialog()
    if ZO_DIALOG_SYNC_OBJECT:IsShown() then
        local shownDialog = ZO_DIALOG_SYNC_OBJECT:GetState()
        return shownDialog == "PROMOTIONAL_EVENT_CAPSTONE_KEYBOARD" or shownDialog == "PROMOTIONAL_EVENT_CAPSTONE_GAMEPAD"
    end

    return false
end

PROMOTIONAL_EVENT_MANAGER = ZO_PromotionalEvent_Manager:New()