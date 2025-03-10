
ZO_DailyLoginRewards_Base = ZO_Object:Subclass()

function ZO_DailyLoginRewards_Base:New(...)
    local loginRewards = ZO_Object.New(self)
    loginRewards:Initialize(...)
    return loginRewards
end

function ZO_DailyLoginRewards_Base:Initialize(control)
    self.control = control
    self.previewableRewards = {}
    self.currentRewardAnimationPool = ZO_MetaPool:New(ZO_Pending_LoopAnimation_Pool)
    self.isDirty = true

    self.highlightPool = ZO_ControlPool:New("ZO_DailyLoginRewards_Highlight", control, "NextLoginRewardHighlight")

    self.blastParticleSystem = ZO_BlastParticleSystem:New()
    self.blastParticleSystem:SetSound(SOUNDS.DAILY_LOGIN_REWARDS_CLAIM_FANFARE)

    local USE_LOWERCASE_NUMBER_SUFFIXES = false
    self.dailyLoginRewardsGridEntrySetup = function(control, data, selected)
        control.data = data
        data.displayRewardData = nil
        self.previewableRewards[data] = nil

        if control.highlightKey then
            self.highlightPool:ReleaseObject(control.highlightKey)
            control.highlightKey = nil
        end

        local isMilestone = false
        if not data.isEmptyCell then
            local isRewardClaimed = IsDailyLoginRewardInCurrentMonthClaimed(data.day)
            local baseRewardData = data
            local fallbackRewardData = baseRewardData:GetFallbackRewardData()
            local displayRewardData = baseRewardData:ShouldUseFallback() and fallbackRewardData or baseRewardData
            data.displayRewardData = displayRewardData

            if displayRewardData:GetQuantity() > 1 then
                control.quantityLabel:SetText(zo_strformat(SI_NUMBER_FORMAT, displayRewardData:GetQuantity()))
                control.quantityLabel:SetHidden(isRewardClaimed)
            else
                control.quantityLabel:SetHidden(true)
            end

            local completeMarkControl = control.completeMark
            local statusIconTexture = control.statusIcon
            local iconTexture = control.icon
            local milestoneTexture = control.isMilestoneTag

            local currentRewardIndex = ZO_DAILYLOGINREWARDS_MANAGER:GetDailyLoginRewardIndex()

            local iconFile = data.iconFile or displayRewardData:GetPlatformLootIcon()
            if iconFile then
                iconTexture:SetTexture(iconFile)
                if data.day > GetNumClaimableDailyLoginRewardsInCurrentMonth() then
                    iconTexture:SetDesaturation(1)
                    milestoneTexture:SetDesaturation(1)
                else
                    iconTexture:SetDesaturation(0)
                    milestoneTexture:SetDesaturation(0)
                end
                iconTexture:SetHidden(false)
            else
                iconTexture:SetHidden(true)
            end

            if isRewardClaimed then
                completeMarkControl:SetHidden(false)
                iconTexture:SetHidden(true)
                if fallbackRewardData then
                    -- We don't know if the reward was claimed as base or fallback, so show no info instead of potentially lying
                    data.obscureReward = true
                elseif CanPreviewReward(displayRewardData:GetRewardId()) then
                    self.previewableRewards[data] = true
                end
            else
                statusIconTexture:SetTexture("EsoUI/Art/Miscellaneous/status_locked.dds")
                statusIconTexture:SetHidden(data.day <= GetNumClaimableDailyLoginRewardsInCurrentMonth())
                data.obscureReward = false
                if CanPreviewReward(displayRewardData:GetRewardId()) then
                    self.previewableRewards[data] = true
                end
            end

            control.timerLabel:SetHidden(true)

             if data.day == currentRewardIndex then
                self.defaultSelectionData = data
                -- there is a next daily reward, but it is not claimable yet, so we want to show the timer
                if GetDailyLoginClaimableRewardIndex() == nil and GetTimeUntilNextDailyLoginMonthS() > ZO_ONE_DAY_IN_SECONDS then
                    if self:ShouldShowNextClaimableRewardBorder()  then
                        local highlightControl, highlightKey = self.highlightPool:AcquireObject()
                        highlightControl:ClearAnchors()
                        highlightControl:SetAnchor(TOPLEFT, control, TOPLEFT)
                        highlightControl:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT)
                        highlightControl:SetParent(control)
                        control.highlightKey = highlightKey
                    end
                    control.timerLabel:SetHidden(false)
                    statusIconTexture:SetHidden(true)
                    self.nextRewardControl = control
                    self:UpdateTimeToNextRewardClaim()
                end
            end

            isMilestone = data.isMilestone
        else
            control.icon:SetHidden(true)
        end

        if data.isEmptyCell then
            control:SetAlpha(0.4)
        else
            if IsDailyLoginRewardInCurrentMonthClaimed(data.day) then
                control.container:SetAlpha(0.4)
            else
                control.container:SetAlpha(1)
            end
        end

        self:SetupGridEntryBorderAndMilestone(control, data, self.currentRewardAnimationPool)
    end

    local function MarkViewDirty()
        self:MarkDirty()
    end

    local function OnMonthChanged()
        if self:IsShowing() then
            PlaySound(SOUNDS.DAILY_LOGIN_REWARDS_MONTH_CHANGE)
        end

        self:MarkDirty()
    end

    control:SetHandler("OnUpdate", function() 
        self:UpdateTimers()
    end)
    control:RegisterForEvent(EVENT_DAILY_LOGIN_REWARDS_UPDATED, MarkViewDirty)
    control:RegisterForEvent(EVENT_NEW_DAILY_LOGIN_REWARD_AVAILABLE, MarkViewDirty)
    control:RegisterForEvent(EVENT_DAILY_LOGIN_REWARDS_CLAIMED, function(...) self:OnRewardClaimed(...) end)
    control:RegisterForEvent(EVENT_DAILY_LOGIN_MONTH_CHANGED, OnMonthChanged)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", function(...) self:OnCollectionUpdated(...) end)
end

function ZO_DailyLoginRewards_Base:GridEntryCleanup(control)
    ZO_ObjectPool_DefaultResetControl(control)
    control.quantityLabel:SetHidden(true)
    control.completeMark:SetHidden(true)
    control.statusIcon:SetHidden(true)
    control.container:SetAlpha(1)
end

function ZO_DailyLoginRewards_Base:UpdateCurrentMonthName()
    local shouldHideMonth = not ZO_DAILYLOGINREWARDS_MANAGER:HasClaimableRewardInMonth() or ZO_DAILYLOGINREWARDS_MANAGER:IsDailyRewardsLocked()
    self.currentMonthLabel:SetHidden(shouldHideMonth)

    local currentMonth = GetCurrentDailyLoginMonth()
    local currentMonthName = GetString("SI_GREGORIANCALENDARMONTHS", currentMonth)
    local currentESOMonthName = GetString("SI_GREGORIANCALENDARMONTHS_LORENAME", currentMonth)
    self.currentMonthText = zo_strformat(SI_DAILY_LOGIN_REWARDS_MONTH_FORMATTER, currentESOMonthName, currentMonthName)
    self.currentMonthLabel:SetText(self.currentMonthText)
end

do
    local function GetDailyLoginRewardEntryNarrationText(entryData)
        if not entryData.isEmptyCell then
            local isRewardClaimed = IsDailyLoginRewardInCurrentMonthClaimed(entryData.day)
            if isRewardClaimed then
                return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_DAILY_LOGIN_REWARDS_CLAIMED_TILE_NARRATION))
            end
        end
    end

    function ZO_DailyLoginRewards_Base:UpdateGridList()
        local gridListPanelList = self.gridListPanelList
        gridListPanelList:ClearGridList()
        self.defaultSelectionData = nil

        ZO_ClearTable(self.previewableRewards)
    
        if ZO_DAILYLOGINREWARDS_MANAGER:IsDailyRewardsLocked() then
            self.lockedLabelText = GetString(SI_DAILY_LOGIN_REWARDS_LOCKED)
            self.lockedLabel:SetText(self.lockedLabelText)
            self.lockedLabel:SetHidden(false)
        elseif ZO_DAILYLOGINREWARDS_MANAGER:HasClaimableRewardInMonth() then
            local numRewardsInMonth = GetNumRewardsInCurrentDailyLoginMonth()
            for i = 1, numRewardsInMonth do
                local rewardId, quantity, isMilestone = GetDailyLoginRewardInfoForCurrentMonth(i)
                local rewardData = REWARDS_MANAGER:GetInfoForDailyLoginReward(rewardId, quantity)
                if rewardData then
                    local dailyLoginRewardData = ZO_GridSquareEntryData_Shared:New(rewardData)
                    dailyLoginRewardData.day = i
                    dailyLoginRewardData.isMilestone = isMilestone
                    dailyLoginRewardData.narrationText = GetDailyLoginRewardEntryNarrationText

                    self.gridListPanelList:AddEntry(dailyLoginRewardData)
                end
            end

            self.lockedLabel:SetHidden(true)
        else
            self.lockedLabel:SetHidden(false)
            -- text for the lock label will be set in UpdateTimeToNextMonthText
        end

        gridListPanelList:CommitGridList()
    end
end

function ZO_DailyLoginRewards_Base:UpdateTimeToNextMonth()
    local timeUntilNextDailyLoginMonthS = GetTimeUntilNextDailyLoginMonthS()
    if timeUntilNextDailyLoginMonthS ~= self.lastCalculatedTimeUntilNextMonthS then
        local formattedTime = ZO_FormatTimeLargestTwo(timeUntilNextDailyLoginMonthS, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
        self.lastCalculatedTimeUntilNextMonthS = timeUntilNextDailyLoginMonthS
        self:UpdateTimeToNextMonthText(formattedTime)
    end
end

function ZO_DailyLoginRewards_Base:UpdateTimeToNextRewardClaim()
    if self.nextRewardControl then
        local timeUntilNextDailyLoginRewardClaimS = GetTimeUntilNextDailyLoginRewardClaimS()
        if timeUntilNextDailyLoginRewardClaimS ~= self.lastCalcualtedTimeUntilNextRewardClaimS then
            local formattedTime = ZO_FormatCountdownTimer(timeUntilNextDailyLoginRewardClaimS, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
            self.lastCalcualtedTimeUntilNextRewardClaimS = timeUntilNextDailyLoginRewardClaimS
            self:UpdateTimeToNextRewardClaimText(formattedTime)
        end
    end
end

function ZO_DailyLoginRewards_Base:UpdateTimeToNextRewardClaimText(formattedTime)
    if self.nextRewardControl then
        self.nextRewardControl.timerLabel:SetText(formattedTime)
    end
end

function ZO_DailyLoginRewards_Base:UpdateTimers()
    self:UpdateTimeToNextMonth() 
    self:UpdateTimeToNextRewardClaim() 
end

function ZO_DailyLoginRewards_Base:OnShowing()
    self:CleanDirty()
    TriggerTutorial(TUTORIAL_TRIGGER_DAILY_LOGIN_REWARDS_OPENED)
end 

function ZO_DailyLoginRewards_Base:OnHiding()
	self.blastParticleSystem:Stop()
end 

function ZO_DailyLoginRewards_Base:HasMultiplePreviews()
    return NonContiguousCount(self.previewableRewards) > 1
end

function ZO_DailyLoginRewards_Base:OnRewardClaimed()
    if self:IsShowing() then
        if ZO_DAILYLOGINREWARDS_MANAGER:HasClaimableRewardInMonth() then
            self.gridListPanelList:RefreshGridList()
            self:ShowClaimedRewardFlair()
        else
            -- this will hide all the controls and show the "nothing left to claim" message
            self:MarkDirty()
        end
    else
        self:MarkDirty()
    end
end

function ZO_DailyLoginRewards_Base:OnCollectionUpdated()
    self.gridListPanelList:RefreshGridList()
end

function ZO_DailyLoginRewards_Base:ShowClaimedRewardFlair()
    if self.targetedClaimData then
        local claimedControl = self.gridListPanelList:GetControlFromData(self.targetedClaimData)
        self.particleGeneratorPosition:ClearAnchors()
        self.particleGeneratorPosition:SetAnchor(CENTER, claimedControl, CENTER, 0, -10)
        self.blastParticleSystem:Start()

        ZO_CraftingResults_Base_PlayPulse(claimedControl)
        self:SetTargetedClaimData(nil)
    end
end

function ZO_DailyLoginRewards_Base:MarkDirty()
    self.isDirty = true
    if self:IsShowing() then
        self:CleanDirty()
    end
end

function ZO_DailyLoginRewards_Base:CleanDirty()
    if self.isDirty then
        self:UpdateGridList()
        self:UpdateCurrentMonthName()
        self:UpdateTimeToNextMonthVisibility()
        self:UpdateTimers()
        self.isDirty = false
    end
end

function ZO_DailyLoginRewards_Base:SetTargetedClaimData(claimData)
    self.targetedClaimData = claimData
end

function ZO_DailyLoginRewards_Base:ClaimTargetedData()
    if self.targetedClaimData then
        PlaySound(SOUNDS.DAILY_LOGIN_REWARDS_ACTION_CLAIM)
        if self.targetedClaimData:ShouldUseFallback() then
            -- For CSAs
            ZO_DAILY_LOGIN_REWARD_CLAIMING_FALLBACK = true
        else
            ZO_DAILY_LOGIN_REWARD_CLAIMING_FALLBACK = nil
        end
        ClaimCurrentDailyLoginReward()
    end
end

function ZO_DailyLoginRewards_Base:UpdateTimeToNextMonthText(formattedTime)
    if not ZO_DAILYLOGINREWARDS_MANAGER:IsDailyRewardsLocked() then
        self.lockedLabelText = zo_strformat(SI_DAILY_LOGIN_REWARDS_LOCKED_UNTIL_NEW_MONTH, ZO_WHITE:Colorize(formattedTime))
        self.lockedLabel:SetText(self.lockedLabelText)
    end
end

function ZO_DailyLoginRewards_Base:ShouldChangeTimerBeHidden()
    return self.lastCalculatedTimeUntilNextMonthS == 0 or ZO_DAILYLOGINREWARDS_MANAGER:IsDailyRewardsLocked() or not ZO_DAILYLOGINREWARDS_MANAGER:HasClaimableRewardInMonth()
end

function ZO_DailyLoginRewards_Base:UpdateTimeToNextMonthVisibility()
    assert(false) -- must be overridden in derived classes
end

function ZO_DailyLoginRewards_Base:IsShowing()
    assert(false) -- must be overridden in derived classes
end

function ZO_DailyLoginRewards_Base:ShouldShowNextClaimableRewardBorder()
    assert(false) -- must be overridden in derived classes
end