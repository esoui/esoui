-- Reward --

ZO_PromotionalEventReward_Shared = ZO_InitializingObject:Subclass()

local CAMPAIGN_DURATION_UPDATE_INTERVAL_S = 1

function ZO_PromotionalEventReward_Shared:Initialize(control)
    self.control = control
    control.object = self
    self.backdrop = control:GetNamedChild("Backdrop")
    self.iconTexture = control:GetNamedChild("Icon")
    self.quantityLabel = control:GetNamedChild("Quantity")
    self.completeMarkTexture = control:GetNamedChild("CompleteMark")
    self.fxAnchorControl = control:GetNamedChild("FxAnchorControl")
end

function ZO_PromotionalEventReward_Shared:SetRewardFxPools(rewardPendingLoopPool, blastParticleSystemPool)
    self.rewardPendingLoopPool = rewardPendingLoopPool
    self.blastParticleSystemPool = blastParticleSystemPool
end

function ZO_PromotionalEventReward_Shared:SetRewardableEventData(rewardableEventData)
    self.rewardableEventData = rewardableEventData
    local rewardData = rewardableEventData:GetRewardData()
    self.baseRewardData = rewardData
    if rewardData then
        self.control:SetHidden(false)
    else
        self.control:SetHidden(true)
    end

    self:Refresh()
end

function ZO_PromotionalEventReward_Shared:Refresh()
    if self.baseRewardData then
        local canClaim = false
        local isClaimed = false
        local wasFallbackClaimed = false
        if self.rewardableEventData:CanClaimReward() then
            canClaim = true
        else
            isClaimed, wasFallbackClaimed = self.rewardableEventData:IsRewardClaimed()
        end

        local displayRewardData = self.baseRewardData
        if wasFallbackClaimed or (not isClaimed and self.baseRewardData:ShouldUseFallback()) then
            displayRewardData = self.baseRewardData:GetFallbackRewardData()
        end
        self.displayRewardData = displayRewardData

        self.iconTexture:SetTexture(displayRewardData:GetPlatformLootIcon())
        if displayRewardData:GetQuantity() > 1 then
            local quantity = displayRewardData:GetAbbreviatedQuantity()
            self.quantityLabel:SetText(quantity)
            self.quantityLabel:SetHidden(false)
        else
            self.quantityLabel:SetHidden(true)
        end

        local hasPendingLoop = self.fxAnchorControl.pendingLoop ~= nil
        if canClaim ~= hasPendingLoop then
            if canClaim then
                ZO_PendingLoop.ApplyToControl(self.fxAnchorControl, self.rewardPendingLoopPool)
            else
                self.fxAnchorControl.pendingLoop:ReleaseObject()
            end
        end

        if isClaimed then
            self.completeMarkTexture:SetHidden(false)
            self.quantityLabel:SetHidden(true)
            self.iconTexture:SetColor(0.7, 0.7, 0.7)
        else
            self.completeMarkTexture:SetHidden(true)
            self.quantityLabel:SetHidden(displayRewardData:GetQuantity() <= 1)
            self.iconTexture:SetColor(1, 1, 1)
        end
    else
        self.displayRewardData = nil
        if self.fxAnchorControl.pendingLoop then
            self.fxAnchorControl.pendingLoop:ReleaseObject()
        end
    end
end

function ZO_PromotionalEventReward_Shared:OnRewardClaimed()
    if self.baseRewardData then
        self:Refresh()

        local RELEASE_ON_STOP = true
        local blastParticleSystem = self.blastParticleSystemPool:AcquireForControl(self.control, RELEASE_ON_STOP)
        blastParticleSystem:Start()
    end
end


function ZO_PromotionalEventReward_Shared:OnCollectionUpdated()
    if self.baseRewardData and self.baseRewardData:GetFallbackRewardData() then
        self:Refresh()
    end
end

-- Activity --

ZO_PromotionalEventActivity_Entry_Shared = ZO_InitializingObject:Subclass()

function ZO_PromotionalEventActivity_Entry_Shared:Initialize(control)
    self.control = control
    control.object = self
    self.rewardControl = control:GetNamedChild("Reward")
    self.nameLabel = control:GetNamedChild("Name")
    self.progressStatusBar = control:GetNamedChild("Progress")
    self.progressStatusBar.progress = self.progressStatusBar:GetNamedChild("Progress")
    self.completeIcon = control:GetNamedChild("CompleteIcon")
end

function ZO_PromotionalEventActivity_Entry_Shared:SetRewardFxPools(rewardPendingLoopPool, blastParticleSystemPool)
    self.rewardControl.object:SetRewardFxPools(rewardPendingLoopPool, blastParticleSystemPool)
end

function ZO_PromotionalEventActivity_Entry_Shared:SetActivityData(activityData)
    self.activityData = activityData
    local requiredCollectibleData = activityData:GetRequiredCollectibleData()
    local isLocked = requiredCollectibleData and requiredCollectibleData:IsLocked()
    local displayName = activityData:GetDisplayName()
    if isLocked then
        displayName = zo_iconTextFormat("EsoUI/Art/Miscellaneous/status_locked.dds", "100%", "100%", displayName)
    end
    self.nameLabel:SetText(displayName)
    self.rewardControl.object:SetRewardableEventData(self.activityData)

    local progress = self.activityData:GetProgress()
    local completionThreshold = self.activityData:GetCompletionThreshold()
    local progressText = zo_strformat(SI_TIMED_ACTIVITIES_ACTIVITY_COMPLETION_VALUES, ZO_CommaDelimitNumber(progress), ZO_CommaDelimitNumber(completionThreshold))
    self.progressStatusBar:SetValue(progress / completionThreshold)
    self.progressStatusBar.progress:SetText(progressText)
    self:Refresh()
end

function ZO_PromotionalEventActivity_Entry_Shared:OnProgressUpdated(previousProgress, newProgress, rewardFlags)
    local completionThreshold = self.activityData:GetCompletionThreshold()
    local progressText = zo_strformat(SI_TIMED_ACTIVITIES_ACTIVITY_COMPLETION_VALUES, ZO_CommaDelimitNumber(newProgress), ZO_CommaDelimitNumber(completionThreshold))
    self.progressStatusBar:SetValue(newProgress / completionThreshold)
    self.progressStatusBar.progress:SetText(progressText)
    self.rewardControl.object:Refresh()
    self:Refresh()
end

function ZO_PromotionalEventActivity_Entry_Shared:Refresh()
    self.isComplete = self.activityData:IsComplete() and (not self.activityData:GetRewardData() or self.activityData:IsRewardClaimed())
    if self.isComplete then
        self.progressStatusBar.progress:SetHidden(true)
        self.completeIcon:SetHidden(false)
        self.control:SetAlpha(0.4)
    else
        self.progressStatusBar.progress:SetHidden(false)
        self.completeIcon:SetHidden(true)
        self.control:SetAlpha(1)
    end
end

--------------------
-- ZO_PromotionalEvents_Shared --
--------------------

ZO_PromotionalEvents_Shared = ZO_DeferredInitializingObject:Subclass()

function ZO_PromotionalEvents_Shared:Initialize(control)
    self.control = control
    ZO_DeferredInitializingObject.Initialize(self, ZO_FadeSceneFragment:New(control))

    self:InitializeActivityFinderCategory()
end

function ZO_PromotionalEvents_Shared:OnDeferredInitialize()
    self.contentsContainer = self.control:GetNamedChild("Contents")
    self.rewardPendingLoopPool = ZO_MetaPool:New(ZO_Pending_LoopAnimation_Pool)
    self.blastParticleSystemPool = ZO_BlastParticleSystem_MetaPool:New()
    self:InitializeCampaignPanel()
    self:InitializeActivityList()
    self:RegisterForEvents()
end

function ZO_PromotionalEvents_Shared:InitializeCampaignPanel(milestoneTemplate)
    self.campaignPanel = self.contentsContainer:GetNamedChild("CampaignPanel")

    self.campaignBackground = self.campaignPanel:GetNamedChild("BG")
    self.durationLabel = self.campaignPanel:GetNamedChild("Duration")
    self.nameLabel = self.campaignPanel:GetNamedChild("Name")
    self.campaignProgress = self.campaignPanel:GetNamedChild("Progress")
    self.campaignProgress.progress = self.campaignProgress:GetNamedChild("Progress")

    local capstoneRewardControl = self.campaignPanel:GetNamedChild("CapstoneReward")
    self.capstoneRewardObject = capstoneRewardControl.object
    self.capstoneRewardObject:SetRewardFxPools(self.rewardPendingLoopPool, self.blastParticleSystemPool)

    self.nextRefreshTimeS = 0

    self.campaignPanel:SetHandler("OnUpdate", function(_, currentTimeS)
        if self.currentCampaignData and currentTimeS > self.nextRefreshTimeS then
            self.nextRefreshTimeS = currentTimeS + CAMPAIGN_DURATION_UPDATE_INTERVAL_S
            self:RefreshDurationLabel()
        end
    end)

    self.milestonePool = ZO_ControlPool:New(milestoneTemplate, self.campaignProgress, "Milestone")
    self.milestonePool:SetCustomFactoryBehavior(function(control, key)
        local rewardControl = control:GetNamedChild("Reward")
        control.rewardControl = rewardControl
        control.rewardObject = rewardControl.object
        control.thresholdLabel = control:GetNamedChild("Threshold")
        control.displayIndex = key
        control.rewardObject:SetRewardFxPools(self.rewardPendingLoopPool, self.blastParticleSystemPool)

        rewardControl:SetScale(self.GetMilestoneScale())
    end)
end

function ZO_PromotionalEvents_Shared:InitializeActivityList(template, height)
    self.activityList = self.contentsContainer:GetNamedChild("ActivityList")

    local function SetupActivity(control, data)
        self:OnActivityControlSetup(control, data)
    end

    self.entryTypeActivity = 1
    ZO_ScrollList_AddDataType(self.activityList, self.entryTypeActivity, template, height, SetupActivity)
end

function ZO_PromotionalEvents_Shared:RegisterForEvents()
    self.control:RegisterForEvent(EVENT_PROMOTIONAL_EVENTS_ACTIVITY_PROGRESS_UPDATED, ZO_GetEventForwardingFunction(self, self.OnActivityProgressUpdated))
    self.control:RegisterForEvent(EVENT_PROMOTIONAL_EVENTS_ACTIVITY_TRACKING_UPDATED, ZO_GetEventForwardingFunction(self, self.OnActivityTrackingUpdated))
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("RewardsClaimed", ZO_GetCallbackForwardingFunction(self, self.OnRewardsClaimed))
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", ZO_GetCallbackForwardingFunction(self, self.OnCollectionUpdated))
end

function ZO_PromotionalEvents_Shared:OnActivityControlSetup(control, data)
    control.object:SetRewardFxPools(self.rewardPendingLoopPool, self.blastParticleSystemPool)
    control.object:SetActivityData(data)
end

function ZO_PromotionalEvents_Shared:OnActivityProgressUpdated(campaignKey, activityIndex, ...)
    local entryData = self:GetActivityEntryByIndex(campaignKey, activityIndex)
    if entryData then
        local activityData = entryData.data
        if self:IsShowing() and activityData:IsComplete() and activityData:IsTracked() then
            ClearTrackedPromotionalEventActivity()
        end
        if entryData.control then
            local activityObject = entryData.control.object
            activityObject:OnProgressUpdated(...)
        end
        self:RefreshCampaignPanel()
    end
end

function ZO_PromotionalEvents_Shared:OnActivityTrackingUpdated()
    self:RefreshActivityList()
end

function ZO_PromotionalEvents_Shared:GetActivityEntryByIndex(campaignKey, activityIndex)
    if self.currentCampaignData and AreId64sEqual(self.currentCampaignData:GetKey(), campaignKey) then
        local function Query(activityData)
            return activityData.activityIndex == activityIndex
        end

        return ZO_ScrollList_FindDataByQuery(self.activityList, Query)
    end
    return nil
end

function ZO_PromotionalEvents_Shared:OnRewardsClaimed(campaignData, rewards)
    if self:IsShowing() and self.currentCampaignData == campaignData then
        local sound = SOUNDS.PROMOTIONAL_EVENT_CLAIM_REWARD
        for _, reward in ipairs(rewards) do
            local type = reward.type
            local index = reward.index
            local rewardObject = self:GetRewardObjectByTypeAndIndex(campaignData:GetKey(), type, index)
            if rewardObject then
                rewardObject:OnRewardClaimed()
            end
            if type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_SCHEDULE then
                sound = SOUNDS.PROMOTIONAL_EVENT_CLAIM_CAPSTONE_REWARD
                self:OnCapstoneRewardClaimed()
            elseif type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_MILESTONE_REWARD then
                local milestoneData = reward.rewardableEventData
                local milestoneControl = self.milestonePool:GetActiveObject(milestoneData:GetDisplayIndex())
                if milestoneControl then
                    self:OnMilestoneRewardClaimed(milestoneControl)
                end
            elseif type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_ACTIVITY then
                local entryData = self:GetActivityEntryByIndex(campaignData:GetKey(), index)
                if entryData then
                    self:OnActivityRewardClaimed(entryData)
                end
            end
        end
        PlaySound(sound)
    end
end

function ZO_PromotionalEvents_Shared:OnCollectionUpdated(collectionUpdateType, collectiblesByNewUnlockState)
    if self:IsShowing() then
        if collectionUpdateType == ZO_COLLECTION_UPDATE_TYPE.UNLOCK_STATE_CHANGED then
            self.capstoneRewardObject:OnCollectionUpdated()
            for _, milestoneControl in pairs(self.milestonePool:GetActiveObjects()) do
                milestoneControl.rewardObject:OnCollectionUpdated()
            end
            local NO_FILTER = nil
            local function RefreshActivityReward(control)
                local activityObject = control.object
                local rewardObject = activityObject.rewardControl.object
                rewardObject:OnCollectionUpdated()
            end
            ZO_ScrollList_RefreshVisible(self.activityList, NO_FILTER, RefreshActivityReward)
        end
    end
end

function ZO_PromotionalEvents_Shared:OnCapstoneRewardClaimed()
    self:ShowCapstoneDialog()
end

function ZO_PromotionalEvents_Shared:OnMilestoneRewardClaimed(milestoneControl)
    -- To be overridden
end

function ZO_PromotionalEvents_Shared:OnActivityRewardClaimed(entryData)
    if entryData.control then
        local activityObject = entryData.control.object
        activityObject:Refresh()
    end
end

function ZO_PromotionalEvents_Shared:GetActivityRewardObject(entryData)
    local activityControl = entryData.dataEntry.control
    if activityControl then
        local activityObject = activityControl.object
        return activityObject.rewardControl.object
    end
    return nil
end

function ZO_PromotionalEvents_Shared:GetRewardObjectByTypeAndIndex(campaignKey, type, index)
    if self.currentCampaignData and AreId64sEqual(self.currentCampaignData:GetKey(), campaignKey) then
        if type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_SCHEDULE then
            return self.capstoneRewardObject
        elseif type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_MILESTONE_REWARD then
            -- index is milestoneIndex, not displayIndex
            local milestoneData = self.currentCampaignData:GetMilestoneData(index)
            local milestoneControl = self.milestonePool:GetActiveObject(milestoneData:GetDisplayIndex())
            return milestoneControl and milestoneControl.rewardObject or nil
        elseif type == PROMOTIONAL_EVENTS_COMPONENT_TYPE_ACTIVITY then
            local entryData = self:GetActivityEntryByIndex(campaignKey, index)
            if entryData and entryData.control then
                local activityObject = entryData.control.object
                return activityObject.rewardControl.object
            end
        end
    end
    return nil
end

function ZO_PromotionalEvents_Shared:GetCurrentCampaignData()
    return self.currentCampaignData
end

function ZO_PromotionalEvents_Shared:RefreshCampaignPanel(rebuild)
    if self.currentCampaignData then
        self:RefreshDurationLabel()

        if rebuild then
            local campaignBackgroundFileIndex = self.currentCampaignData:GetLargeBackgroundFileIndex()
            if campaignBackgroundFileIndex ~= ZO_NO_TEXTURE_FILE then
                self.campaignBackground:SetTexture(campaignBackgroundFileIndex)
            else
                self.campaignBackground:SetTexture("EsoUI/Art/PromotionalEvent/promotionalEvents_generic_bg.dds")
            end
        end

        local completedActivities = self.currentCampaignData:GetNumActivitiesCompleted()
        local capstoneThreshold = self.currentCampaignData:GetCapstoneRewardThreshold()
        local progressText = zo_strformat(SI_TIMED_ACTIVITIES_ACTIVITY_COMPLETION_VALUES, ZO_CommaDelimitNumber(completedActivities), ZO_CommaDelimitNumber(capstoneThreshold))
        self.campaignProgress:SetValue(completedActivities / capstoneThreshold)
        self.campaignProgress.progress:SetText(progressText)

        if rebuild then
            self.capstoneRewardObject:SetRewardableEventData(self.currentCampaignData)

            self.milestonePool:ReleaseAllObjects()
            local milestones = self.currentCampaignData:GetMilestones()
            local numMilestones = #milestones
            if numMilestones > 0 then
                local progressWidth = self.campaignProgress:GetWidth()
                local milestoneControlWidth
                local previousOffsetX = 0
                local milestoneControls = { }
                local milestonePadding = self.GetMilestonePadding()
                for displayIndex, milestone in ipairs(milestones) do
                    local milestoneControl = self.milestonePool:AcquireObject(displayIndex)
                    if not milestoneControlWidth then
                        milestoneControlWidth = milestoneControl:GetWidth()
                    end

                    milestoneControl.milestoneData = milestone
                    milestoneControl.rewardObject:SetRewardableEventData(milestone)

                    local milestoneThreshold = milestone:GetCompletionThreshold()
                    milestoneControl.thresholdLabel:SetText(milestoneThreshold)

                    local offsetX = (milestoneThreshold / capstoneThreshold) * progressWidth

                    if offsetX - previousOffsetX < milestoneControlWidth + milestonePadding then
                        offsetX = previousOffsetX + milestoneControlWidth + milestonePadding
                    end

                    milestoneControl:SetAnchor(BOTTOM, self.campaignProgress, TOPLEFT, offsetX, -3)
                    table.insert(milestoneControls, milestoneControl)

                    previousOffsetX = offsetX
                end

                -- The previous loop guarantees no overlaps, so we only need to go back through if it pushed
                -- the final milestone too far to the right.
                if progressWidth - previousOffsetX + milestonePadding < milestoneControlWidth / 2 then
                    previousOffsetX = progressWidth + milestoneControlWidth / 2
                    for index = numMilestones, 1, -1 do
                        local milestoneControl = milestoneControls[index]
                        local _, _, _, _, currentOffsetX = milestoneControl:GetAnchor(0)

                        if currentOffsetX <= previousOffsetX - milestoneControlWidth then
                            break
                        end

                        local newOffsetX = previousOffsetX - milestoneControlWidth - milestonePadding
                        milestoneControl:SetAnchor(BOTTOM, self.campaignProgress, TOPLEFT, newOffsetX, -3)

                        previousOffsetX = newOffsetX
                    end
                end
            end
        else
            self.capstoneRewardObject:Refresh()
            for _, milestoneControl in pairs(self.milestonePool:GetActiveObjects()) do
                milestoneControl.rewardObject:Refresh()
            end
        end
    end
end

function ZO_PromotionalEvents_Shared:RefreshDurationLabel()
    local secondsRemaining = self.currentCampaignData:GetSecondsRemaining()
    if secondsRemaining > 0 then
        local durationText = ZO_FormatTime(secondsRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR)
        self.durationLabel:SetText(zo_strformat(SI_EVENT_ANNOUNCEMENT_TIME, durationText))
    end
    self.nameLabel:SetText(self.currentCampaignData:GetDisplayName())
end

function ZO_PromotionalEvents_Shared:RefreshActivityList(rebuild)
    if rebuild then
        ZO_ScrollList_Clear(self.activityList)
        local scrollData = ZO_ScrollList_GetDataList(self.activityList)
            
        if self.currentCampaignData then
            for _, activityData in ipairs(self.currentCampaignData:GetActivities()) do
                local entryData = ZO_EntryData:New(activityData) 
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(self.entryTypeActivity, entryData))
            end
        end

        ZO_ScrollList_Commit(self.activityList)
        ZO_ScrollList_ResetToTop(self.activityList)
    else
        ZO_ScrollList_RefreshVisible(self.activityList)
    end
end

function ZO_PromotionalEvents_Shared:RefreshAll(rebuild)
    if rebuild then
        self.rewardPendingLoopPool:ReleaseAllObjects()
        self.blastParticleSystemPool:ReleaseAllObjects()
    end
    self:RefreshCampaignPanel(rebuild)
    self:RefreshActivityList(rebuild)
end

function ZO_PromotionalEvents_Shared.GetActivityRequiredCollectibleText(activityData)
    local requiredCollectibleData = activityData:GetRequiredCollectibleData()
    if requiredCollectibleData then
        return requiredCollectibleData:GetContentRequiresCollectibleText()
    end
    return nil
end

function ZO_PromotionalEvents_Shared:RefreshCampaignData()
    local rebuild = false

    local selectedCampaignData = self:GetSelectedCampaignData()
    if selectedCampaignData then
        selectedCampaignData:SetSeen(true)
    end
    if selectedCampaignData ~= self.currentCampaignData then
        self.currentCampaignData = selectedCampaignData
        rebuild = true
    end
    self:RefreshAll(rebuild)

    local trackedCampaignKey, trackedActivityIndex = GetTrackedPromotionalEventActivityInfo()
    local trackedEntryData = self:GetActivityEntryByIndex(trackedCampaignKey, trackedActivityIndex)
    if trackedEntryData and trackedEntryData.data:IsComplete() then
        ClearTrackedPromotionalEventActivity()
    end
end

function ZO_PromotionalEvents_Shared:GetSelectedCampaignData()
    return PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByIndex(1) -- TODO Promotional Event: Make this a MUST_IMPLEMENT function
end

function ZO_PromotionalEvents_Shared:OnShowing()
    self:RefreshCampaignData()
    TriggerTutorial(TUTORIAL_TRIGGER_PROMOTIONAL_EVENTS_OPENED)
end

function ZO_PromotionalEvents_Shared:OnHidden()
    self.rewardPendingLoopPool:ReleaseAllObjects()
    self.blastParticleSystemPool:ReleaseAllObjects()
end

function ZO_PromotionalEvents_Shared:ScrollToFirstClaimableReward()
    local claimableMilestoneData = nil
    for _, milestoneControl in pairs(self.milestonePool:GetActiveObjects()) do
        local milestoneData = milestoneControl.milestoneData
        if milestoneData:CanClaimReward() then
            claimableMilestoneData = milestoneData
            break
        end
    end

    local claimableCapstoneData  = nil
    if self.capstoneRewardObject.rewardableEventData:CanClaimReward() then
        claimableCapstoneData = self.capstoneRewardObject.rewardableEventData
    end

    local function ActivityQuery(activityData)
        return activityData:CanClaimReward()
    end

    local claimableActivityData = nil
    local activityData, activityDataIndex = ZO_ScrollList_FindDataByQuery(self.activityList, ActivityQuery)
    if activityData then
        claimableActivityData = activityData.data
        ZO_ScrollList_ScrollDataIntoView(self.activityList, activityDataIndex)
    end

    return claimableMilestoneData, claimableCapstoneData, claimableActivityData -- For override behavior
end

ZO_PromotionalEvents_Shared:MUST_IMPLEMENT("InitializeActivityFinderCategory")
ZO_PromotionalEvents_Shared:MUST_IMPLEMENT("ShowCapstoneDialog")
ZO_PromotionalEvents_Shared:MUST_IMPLEMENT("GetMilestoneScale")
ZO_PromotionalEvents_Shared:MUST_IMPLEMENT("GetMilestonePadding")

-- Capstone Dialog --

ZO_PromotionalEvents_CapstoneDialog_Shared = ZO_InitializingObject:Subclass()

function ZO_PromotionalEvents_CapstoneDialog_Shared:Initialize(control)
    self.control = control
    control.object = self
    self:InitializeControls()
    self:InitializeParticleSystems()
end

function ZO_PromotionalEvents_CapstoneDialog_Shared:InitializeControls()
    local control = self.control
    self.titleLabel = control:GetNamedChild("Title")
    assert(self.titleLabel, "ZO_PromotionalEvents_CapstoneDialog_Shared derived top level must add label control called 'Title'")
    self.rewardIcon = control:GetNamedChild("RewardContainerIcon")
    self.rewardNameLabel = control:GetNamedChild("RewardContainerName")
    self.rewardStackCountLabel = control:GetNamedChild("RewardContainerStackCount")
    assert(self.rewardStackCountLabel, "ZO_PromotionalEvents_CapstoneDialog_Shared derived top level must add label control called 'StackCount' to the RewardContainer")
    self.overlayGlowControl = self.control:GetNamedChild("OverlayGlow")
    internalassert(self.overlayGlowControl ~= nil)
    self.overlayGlowFadeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_PromotionalEvents_CapstoneDialog_OverlayGlowFadeAnimation", self.overlayGlowControl)

    local topLevelwidth, topLevelheight = self.control:GetDimensions()
    local BACKGROUND_PADDING = 8 * 2 -- Padding per edge times num edges
    self.control:SetHandler("OnRectChanged", function(control, newLeft, newTop, newRight, newBottom)
        local newWidth = newRight - newLeft
        local newHeight = newBottom - newTop
        if newWidth ~= topLevelwidth or newHeight ~= topLevelheight then
            self.overlayGlowControl:SetDimensions(newWidth + BACKGROUND_PADDING, newHeight + BACKGROUND_PADDING)
            topLevelwidth = newWidth
            topLevelheight = newHeight
        end
    end)
end

function ZO_PromotionalEvents_CapstoneDialog_Shared:InitializeParticleSystems()
    local particleR, particleG, particleB = ZO_OFF_WHITE:UnpackRGB()

    local blastParticleSystem = ZO_BlastParticleSystem:New()
    blastParticleSystem:SetParentControl(self.control:GetNamedChild("BlastParticlesOrigin"))
    blastParticleSystem:SetParticlesPerSecond(500)
    blastParticleSystem:SetDuration(.2)
    blastParticleSystem:SetSound(SOUNDS.PROMOTIONAL_EVENT_CAPSTONE_CELEBRATION_HEADER_CLICK)
    blastParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(1.5, 2.5))
    blastParticleSystem:SetParticleParameter("PhysicsAccelerationMagnitude1", 300)
    blastParticleSystem:SetParticleParameter("PhysicsInitialVelocityMagnitude", ZO_UniformRangeGenerator:New(700, 1100))
    blastParticleSystem:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(6, 12))
    blastParticleSystem:SetParticleParameter("PhysicsDragMultiplier", 1.5)
    blastParticleSystem:SetParticleParameter("PrimeS", .5)
    self.blastParticleSystem = blastParticleSystem

    local headerSparksParticleSystem = ZO_ControlParticleSystem:New(ZO_AnalyticalPhysicsParticle_Control)
    headerSparksParticleSystem:SetParticlesPerSecond(15)
    headerSparksParticleSystem:SetStartPrimeS(1.5)
    headerSparksParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/ember.dds")
    headerSparksParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    headerSparksParticleSystem:SetParticleParameter("StartAlpha", 1)
    headerSparksParticleSystem:SetParticleParameter("EndAlpha", 0)
    headerSparksParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(1, 1.5))
    headerSparksParticleSystem:SetParticleParameter("PhysicsInitialVelocityElevationRadians", ZO_UniformRangeGenerator:New(0, ZO_TWO_PI))
    headerSparksParticleSystem:SetParticleParameter("StartColorR", particleR)
    headerSparksParticleSystem:SetParticleParameter("StartColorG", particleG)
    headerSparksParticleSystem:SetParticleParameter("StartColorB", particleB)
    headerSparksParticleSystem:SetParticleParameter("PhysicsInitialVelocityMagnitude", ZO_UniformRangeGenerator:New(15, 60))
    headerSparksParticleSystem:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(5, 10))
    headerSparksParticleSystem:SetParticleParameter("DrawLayer", DL_OVERLAY)
    headerSparksParticleSystem:SetParticleParameter("DrawLevel", 2)
    self.headerSparksParticleSystem = headerSparksParticleSystem

    local headerStarbustParticleSystem = ZO_ControlParticleSystem:New(ZO_StationaryParticle_Control)
    headerStarbustParticleSystem:SetParticlesPerSecond(20)
    headerStarbustParticleSystem:SetStartPrimeS(2)
    headerStarbustParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/Miscellaneous/lensflare_star_256.dds")
    headerStarbustParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    headerStarbustParticleSystem:SetParticleParameter("StartAlpha", 0)
    headerStarbustParticleSystem:SetParticleParameter("EndAlpha", 1)
    headerStarbustParticleSystem:SetParticleParameter("AlphaEasing", ZO_EaseInOutZeroToOneToZero)
    headerStarbustParticleSystem:SetParticleParameter("StartScale", ZO_UniformRangeGenerator:New(1, 1.3))
    headerStarbustParticleSystem:SetParticleParameter("EndScale", ZO_UniformRangeGenerator:New(.65, 1))
    headerStarbustParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(1, 2))
    headerStarbustParticleSystem:SetParticleParameter("StartColorR", particleR)
    headerStarbustParticleSystem:SetParticleParameter("StartColorG", particleG)
    headerStarbustParticleSystem:SetParticleParameter("StartColorB", particleB)
    headerStarbustParticleSystem:SetParticleParameter("StartRotationRadians", ZO_UniformRangeGenerator:New(0, ZO_TWO_PI))
    local MIN_ROTATION_SPEED = math.rad(1.5)
    local MAX_ROTATION_SPEED =  math.rad(3)
    local headerStarbustRotationSpeedGenerator = ZO_WeightedChoiceGenerator:New(
        MIN_ROTATION_SPEED , 0.25,
        MAX_ROTATION_SPEED , 0.25,
        -MIN_ROTATION_SPEED, 0.25,
        -MAX_ROTATION_SPEED, 0.25)

    headerStarbustParticleSystem:SetParticleParameter("RotationSpeedRadians", headerStarbustRotationSpeedGenerator)
    headerStarbustParticleSystem:SetParticleParameter("Size", 256)
    headerStarbustParticleSystem:SetParticleParameter("DrawLayer", DL_OVERLAY)
    headerStarbustParticleSystem:SetParticleParameter("DrawLevel", 1)

    self.headerStarbustParticleSystem = headerStarbustParticleSystem
end

function ZO_PromotionalEvents_CapstoneDialog_Shared:SetCampaignData(campaignData)
    self.campaignData = campaignData
    local baseRewardData = campaignData:GetRewardData()
    local _, wasFallbackClaimed = campaignData:IsRewardClaimed()
    local displayRewardData = wasFallbackClaimed and baseRewardData:GetFallbackRewardData() or baseRewardData
    self.displayRewardData = displayRewardData

    local titleText = zo_strformat(SI_PROMOTIONAL_EVENT_CAPSTONE_DIALOG_TITLE_FORMATTER, ZO_PROMOTIONAL_EVENT_SELECTED_COLOR:Colorize(campaignData:GetDisplayName()))
    self.titleLabel:SetText(titleText)
    self.rewardIcon:SetTexture(displayRewardData:GetPlatformLootIcon())
    self.rewardNameLabel:SetText(displayRewardData:GetFormattedName())
    local stackCount = displayRewardData:GetQuantity()
    if stackCount > 1 then
        self.rewardStackCountLabel:SetHidden(false)
        self.rewardStackCountLabel:SetText(displayRewardData:GetAbbreviatedQuantity())
    else
        self.rewardStackCountLabel:SetHidden(true)
    end
end

function ZO_PromotionalEvents_CapstoneDialog_Shared:ViewInCollections()
    local collectibleId = GetCollectibleRewardCollectibleId(self.displayRewardData:GetRewardId())
    COLLECTIONS_BOOK_SINGLETON:BrowseToCollectible(collectibleId)
end

function ZO_PromotionalEvents_CapstoneDialog_Shared:OnShown()
    self.overlayGlowFadeAnimation:PlayFromStart()
    self.blastParticleSystem:Start()
    self.headerSparksParticleSystem:Start()
    self.headerStarbustParticleSystem:Start()
end

function ZO_PromotionalEvents_CapstoneDialog_Shared:OnHidden()
    self.blastParticleSystem:Stop()
    self.headerSparksParticleSystem:Stop()
    self.headerStarbustParticleSystem:Stop()
end