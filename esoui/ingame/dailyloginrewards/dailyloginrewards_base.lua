
ZO_DailyLoginRewards_Base = ZO_Object:Subclass()

function ZO_DailyLoginRewards_Base:New(...)
    local loginRewards = ZO_Object.New(self)
    loginRewards:Initialize(...)
    return loginRewards
end

function ZO_DailyLoginRewards_Base:Initialize(control)
    self.control = control
    self.hasMultipleRewardPreviews = false
    self.currentRewardAnimationPool = ZO_MetaPool:New(ZO_Pending_Outfit_LoopAnimation_Pool)
    self.isDirty = true

    self.highlightPool = ZO_ControlPool:New("ZO_DailyLoginRewards_Highlight", control, "NextLoginRewardHighlight")

    local particleR, particleG, particleB = ZO_OFF_WHITE:UnpackRGB()
    local FULL_CIRCLE_RADIANS = math.rad(360)

    local blastParticleSystem = ZO_ControlParticleSystem:New(ZO_NumericalPhysicsParticle_Control)
    blastParticleSystem:SetParticlesPerSecond(600)
    blastParticleSystem:SetDuration(.1)
    blastParticleSystem:SetParticleParameter("Texture", "EsoUI/Art/PregameAnimatedBackground/ember.dds")
    blastParticleSystem:SetParticleParameter("BlendMode", TEX_BLEND_MODE_ADD)
    blastParticleSystem:SetParticleParameter("StartAlpha", 1)
    blastParticleSystem:SetParticleParameter("EndAlpha", 0)
    blastParticleSystem:SetParticleParameter("DurationS", ZO_UniformRangeGenerator:New(0.7, 1))
    blastParticleSystem:SetParticleParameter("PhysicsInitialVelocityElevationRadians", ZO_UniformRangeGenerator:New(0, FULL_CIRCLE_RADIANS))
    blastParticleSystem:SetParticleParameter("PhysicsAccelerationElevationRadians1", math.rad(270)) --Down; Right is 0
    blastParticleSystem:SetParticleParameter("PhysicsAccelerationMagnitude1", 250)
    blastParticleSystem:SetParticleParameter("StartColorR", particleR)
    blastParticleSystem:SetParticleParameter("StartColorG", particleG)
    blastParticleSystem:SetParticleParameter("StartColorB", particleB)
    blastParticleSystem:SetParticleParameter("PhysicsInitialVelocityMagnitude", ZO_UniformRangeGenerator:New(400, 600))
    blastParticleSystem:SetParticleParameter("Size", ZO_UniformRangeGenerator:New(6, 12))
    blastParticleSystem:SetParticleParameter("PhysicsDragMultiplier", 4)
    blastParticleSystem:SetSound(SOUNDS.DAILY_LOGIN_REWARDS_CLAIM_FANFARE)
    self.blastParticleSystem = blastParticleSystem

    local USE_LOWERCASE_NUMBER_SUFFIXES = false
    self.dailyLoginRewardsGridEntrySetup = function(control, data, selected)
        control.data = data

        if control.highlightKey then
            self.highlightPool:ReleaseObject(control.highlightKey)
            control.highlightKey = nil
        end

        local isMilestone = false
        if not data.isEmptyCell then
            local isRewardClaimed = IsDailyLoginRewardInCurrentMonthClaimed(data.day)

            if data.quantity > 1 then
                control.quantityLabel:SetText(zo_strformat(SI_NUMBER_FORMAT, ZO_AbbreviateNumber(data.quantity, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)))
                control.quantityLabel:SetHidden(isRewardClaimed)
            else
                control.quantityLabel:SetHidden(true)
            end

            local completeMarkControl = control.completeMark
            local statusIconTexture = control.statusIcon
            local iconTexture = control.icon

            local currentRewardIndex = ZO_DAILYLOGINREWARDS_MANAGER:GetDailyLoginRewardIndex()

            local iconFile = data.iconFile or data.icon
            if iconFile then
                iconTexture:SetTexture(iconFile)
                iconTexture:SetHidden(false)
            else
                iconTexture:SetHidden(true)
            end

            if isRewardClaimed then
                completeMarkControl:SetHidden(false)
                iconTexture:SetHidden(true)
            else
                statusIconTexture:SetTexture("EsoUI/Art/Miscellaneous/status_locked.dds")
                if data.day > GetNumClaimableDailyLoginRewardsInCurrentMonth() then
                    statusIconTexture:SetAlpha(0.3)
                else
                    statusIconTexture:SetAlpha(1)
                end
                statusIconTexture:SetHidden(data.day == GetDailyLoginClaimableRewardIndex())
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
end

function ZO_DailyLoginRewards_Base:GridEntryCleanup(control)
    ZO_ObjectPool_DefaultResetControl(control)
    control.quantityLabel:SetHidden(true)
    control.completeMark:SetHidden(true)
    control.statusIcon:SetHidden(true)
    control.container:SetAlpha(1)
end

function ZO_DailyLoginRewards_Base:UpdateCurrentMonthName()
    local numRewards = GetNumRewardsInCurrentDailyLoginMonth()
    self.currentMonthLabel:SetHidden(numRewards == 0)

    local currentMonth = GetCurrentDailyLoginMonth()
    local currentMonthName = GetString("SI_GREGORIANCALENDARMONTHS", currentMonth)
    local currentESOMonthName = GetString("SI_GREGORIANCALENDARMONTHS_LORENAME", currentMonth)
    self.currentMonthLabel:SetText(zo_strformat(SI_DAILY_LOGIN_REWARDS_MONTH_FORMATTER, currentESOMonthName, currentMonthName))
end

function ZO_DailyLoginRewards_Base:UpdateGridList()
	local gridListPanelList = self.gridListPanelList
    gridListPanelList:ClearGridList()
    self.defaultSelectionData = nil
	
    local numPreviewableRewards = 0
    local numRewardsInMonth = GetNumRewardsInCurrentDailyLoginMonth()
    for i = 1, numRewardsInMonth do
	    local rewardId, quantity, isMilestone = GetDailyLoginRewardInfoForCurrentMonth(i)
		local rewardData = REWARDS_MANAGER:GetInfoForDailyLoginReward(rewardId, quantity)
        if rewardData then
            local dailyLoginRewardData = ZO_GridSquareEntryData_Shared:New(rewardData)
            dailyLoginRewardData.day = i
            dailyLoginRewardData.isMilestone = isMilestone
            dailyLoginRewardData.quantity = quantity

            if CanPreviewReward(dailyLoginRewardData:GetRewardId()) then
                numPreviewableRewards = numPreviewableRewards + 1
            end

		    self.gridListPanelList:AddEntry(dailyLoginRewardData)
        end
    end

    self.lockedLabel:SetHidden(numRewardsInMonth ~= 0)

    self.hasMultipleRewardPreviews = numPreviewableRewards > 1
	
	gridListPanelList:CommitGridList()
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
    return self.hasMultipleRewardPreviews
end

function ZO_DailyLoginRewards_Base:OnRewardClaimed()
    if self:IsShowing() then
        self.gridListPanelList:RefreshGridList()
        self:ShowClaimedRewardFlair()
    else
        self:MarkDirty()
    end
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

function ZO_DailyLoginRewards_Base:UpdateTimeToNextMonthText(formattedTime)
    assert(false) -- must be overridden in derived classes
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