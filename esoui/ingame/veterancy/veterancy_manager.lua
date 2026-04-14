-------------------------------
-- Veterancy Manager
-------------------------------

ZO_Veterancy_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_Veterancy_Manager:Initialize()
    self.rankData = {}
    self.isDataInitialized = false

    local function OnRewardClaimed(event, trackType, trackId, rankIndex, rewardComponent, rewardIndex, isFallback, numRepeatableRewardsClaimed)
        if trackType == self:GetVeterancyTrackType() then
            self:RefreshRankData()
            local wasAnyClaimed = false
            local numRanks = self:GetNumRanks()
            local maxRankToUpdate = zo_min(rankIndex, numRanks)
            for i = 1, maxRankToUpdate do
                local wasClaimed = self.rankData[i]:UpdateClaimedState()

                if wasClaimed then
                    self:FireCallbacks("OnVeterancyRankClaimed", i)
                    wasAnyClaimed = true
                end
            end
            if self.repeatableRankData and numRepeatableRewardsClaimed > 0 then
                self.repeatableRankData:UpdateClaimedState()
                self:FireCallbacks("OnVeterancyRepeatableRankClaimed", numRepeatableRewardsClaimed)
            end
            if wasAnyClaimed then
                CALLBACK_MANAGER:FireCallbacks("OnVeterancyNotificationsRefreshed")
            end
        end
    end

    local function OnRewardsClaimed(event, trackType, trackId, highestRewardTrackTierClaimed, numRepeatableRewardsClaimed)
        if trackType == self:GetVeterancyTrackType() then
            self:RefreshRankData()
            local wasAnyClaimed = false
            local numRanks = self:GetNumRanks()
            local maxRankToUpdate = zo_min(highestRewardTrackTierClaimed, numRanks)
            for i = 1, maxRankToUpdate do
                local wasClaimed = self.rankData[i]:UpdateClaimedState()

                if wasClaimed then
                    local SUPPRESS_SOUNDS = true
                    self:FireCallbacks("OnVeterancyRankClaimed", i, SUPPRESS_SOUNDS)
                    wasAnyClaimed = true
                end
            end
            if self.repeatableRankData and numRepeatableRewardsClaimed > 0 then
                self.repeatableRankData:UpdateClaimedState()
                self:FireCallbacks("OnVeterancyRepeatableRankClaimed", numRepeatableRewardsClaimed)
            end
            if wasAnyClaimed then
                CALLBACK_MANAGER:FireCallbacks("OnVeterancyNotificationsRefreshed")
                PlaySound(SOUNDS.VETERANCY_RANK_REWARD_CLAIM_ALL)
            end
        end
    end

    local function OnProgressGained(event, trackType, trackId, previousRankIndex, rankIndex, newProgress)
        if trackType == self:GetVeterancyTrackType() then
            self:RefreshRankData()
            if rankIndex <= self:GetNumRanks() or previousRankIndex <= self:GetNumRanks() then
                local claimableStateChanged = false
                local nonRepeatableRankIndex = rankIndex
                if nonRepeatableRankIndex > self:GetNumRanks() then
                    nonRepeatableRankIndex = self:GetNumRanks()
                end
                for i = 1, nonRepeatableRankIndex do
                    local claimableBefore = self.rankData[i]:CanClaimRank()
                    self.rankData[i]:UpdateClaimedState()
                    local claimableAfter = self.rankData[i]:CanClaimRank()

                    if claimableBefore ~= claimableAfter then
                        claimableStateChanged = true
                    end
                end

                if claimableStateChanged then
                    TriggerTutorial(TUTORIAL_TRIGGER_VETERANCY_INITIAL_CLAIMABLE_REWARDS_AVAILABLE)
                end

                if previousRankIndex < rankIndex then
                    self:FireCallbacks("OnVeterancyRankUp", nonRepeatableRankIndex)
                end
            end
            if self.repeatableRankData and rankIndex > self:GetNumRanks() then
                local oldCanClaim = self.repeatableRankData:CanClaimRank()
                self.repeatableRankData:UpdateClaimedState()

                if self.repeatableRankData:CanClaimRank() ~= oldCanClaim then
                    PlaySound(SOUNDS.VETERANCY_RANK_UP_REPEATABLE)
                end
            end

            self:FireCallbacks("OnVeterancyRankProgressed", rankIndex, newProgress)
        end
    end

    local function OnAddOnLoaded(_, name)
        if name == "ZO_Ingame" then
            EVENT_MANAGER:UnregisterForEvent("Veterancy", EVENT_ADD_ON_LOADED)
            self.isDataInitialized = false
            self:RefreshRankData()
        end
    end

    local function UpdateVeterancyAvailability()
        self.isDataInitialized = false
        self:RefreshRankData()
    end

    local function OnRewardTrackStarted(_, rewardTrackType, rewardTrackId)
        if rewardTrackType == REWARD_TRACK_TYPE_REWARD_TRACK_TYPE_AVA_VETERANCY then
            self.isDataInitialized = false
            self:RefreshRankData()
        end
    end

    EVENT_MANAGER:RegisterForEvent("Veterancy", EVENT_REWARD_TRACK_REWARD_CLAIMED, OnRewardClaimed)
    EVENT_MANAGER:RegisterForEvent("Veterancy", EVENT_REWARD_TRACK_REWARDS_CLAIMED, OnRewardsClaimed)
    EVENT_MANAGER:RegisterForEvent("Veterancy", EVENT_REWARD_TRACK_PROGRESS_GAINED, OnProgressGained)
    EVENT_MANAGER:RegisterForEvent("Veterancy", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    EVENT_MANAGER:RegisterForEvent("Veterancy", EVENT_HOLIDAYS_CHANGED, UpdateVeterancyAvailability)
    EVENT_MANAGER:RegisterForEvent("Veterancy", EVENT_REWARD_TRACK_UPDATE_RECEIVED, UpdateVeterancyAvailability)
    EVENT_MANAGER:RegisterForEvent("Veterancy", EVENT_REWARD_TRACK_SETTINGS_UPDATE_RECEIVED, UpdateVeterancyAvailability)
    EVENT_MANAGER:RegisterForEvent("Veterancy", EVENT_REWARD_TRACK_STARTED, OnRewardTrackStarted)
end

function ZO_Veterancy_Manager:GetVeterancyTrackType()
    return REWARD_TRACK_TYPE_AVA_VETERANCY
end

function ZO_Veterancy_Manager:GetVeterancyComponent()
    return REWARD_TRACK_COMPONENT_PRIMARY
end

function ZO_Veterancy_Manager:GetVeterancyDefaultRewardIndex()
    local DEFAULT_REWARD_INDEX = 1
    return DEFAULT_REWARD_INDEX
end

function ZO_Veterancy_Manager:RefreshRankData()
    if IsVeterancySeasonActive() and not self.isDataInitialized then
        -- There should never be more than 1 active Vengeance Track
        self.trackType = self:GetVeterancyTrackType()
        self.veterancyTrackId = GetActiveReferenceTrackIdsForRewardTrackType(self.trackType)
        self.rewardTrackId = GetRewardTrackIdFromReferenceTrackId(REWARD_TRACK_TYPE_AVA_VETERANCY, self.veterancyTrackId)
        self.veterancyTrackIndex = GetReferenceTrackIndex(self.trackType, self.veterancyTrackId)

        ReleaseParsedPerkAvailabilityForCurrentSeason()
        RequestParsedPerkAvailabilityForCurrentSeason()

        local numRanks = GetNumBaseTiersForRewardTrack(self.rewardTrackId)
        ZO_ClearTable(self.rankData)
        for i = 1, numRanks do
            local rankData = ZO_VeterancyRankData:New(i)
            table.insert(self.rankData, rankData)
        end

        if self:HasRepeatableRankReward() then
            local repeatableRankIndex = GetInfinitelyRepeatableTierForRewardTrack(self.rewardTrackId)
            self.repeatableRankData = ZO_VeterancyRankData:New(repeatableRankIndex)
        end

        self.isDataInitialized = true

        self:FireCallbacks("OnVeterancyRankDataUpdated")
    end
end

function ZO_Veterancy_Manager:GetNumRanks()
    return #self.rankData
end

function ZO_Veterancy_Manager:GetRankDataByIndex(index)
    return self.rankData[index]
end

function ZO_Veterancy_Manager:GetCurrentRank()
    local _, currentRank = GetInfoForRewardTrack(self.trackType, self.veterancyTrackIndex)
    return currentRank
end

function ZO_Veterancy_Manager:GetCurrentRankData()
    local currentRank = self:GetCurrentRank()
    if currentRank <= self:GetNumRanks() then
        return self:GetRankDataByIndex(currentRank)
    else
        return self.repeatableRankData
    end
end

function ZO_Veterancy_Manager:GetRepeatableRankData()
    return self.repeatableRankData
end

function ZO_Veterancy_Manager:GetHighestUnlockedRankWithClaimableRewards()
    local currentRank = self:GetCurrentRank()
    local numRanks = self:GetNumRanks()
    if currentRank > numRanks then
        currentRank = numRanks
    end
    for i = currentRank, 1, -1 do
        local rankData = self:GetRankDataByIndex(i)
        if rankData:GetNumClaimableRewards() > 0 then
            return i
        end
    end
end

function ZO_Veterancy_Manager:GetCurrentRankName()
    local rankData = self:GetCurrentRankData()
    if rankData then
        return rankData:GetName()
    end
    return ""
end

function ZO_Veterancy_Manager:GetCurrentTierProgress()
    local rankData = self:GetCurrentRankData()
    return rankData:GetRankTierProgressValue()
end

function ZO_Veterancy_Manager:GetCurrentTierTotal()
    local rankData = self:GetCurrentRankData()
    return rankData:GetRankTierTotalValue()
end

function ZO_Veterancy_Manager:IsOnMaxRank()
    return self:GetCurrentRank() >= self:GetNumRanks()
end

function ZO_Veterancy_Manager:HasRepeatableRankReward()
    return HasInfinitelyRepeatableTierForRewardTrack(self.rewardTrackId)
end

function ZO_Veterancy_Manager:HasUnclaimedRankRewards()
    return HasUnclaimedRewardTrackRewards(self.trackType, self.veterancyTrackIndex)
end

function ZO_Veterancy_Manager:TryClaimAllRewards()
    ClaimAllRewardTrackRewards(self.trackType, self.veterancyTrackIndex)
end

ZO_VETERANCY_MANAGER = ZO_Veterancy_Manager:New()