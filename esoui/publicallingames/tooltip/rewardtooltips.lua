do
    local NOT_EQUIPPED = false
    local NO_CREATOR_NAME = nil
    local FORCE_FULL_DURABILITY = true
    local NO_PREVIEW_VALUE = nil

    function ZO_Tooltip:LayoutReward(rewardId, amount, displayFlags)
        local rewardType = GetRewardType(rewardId)
        -- For some market product types we can just use other tooltip layouts
        if rewardType == REWARD_ENTRY_TYPE_COLLECTIBLE then
            local collectibleId = GetCollectibleRewardCollectibleId(rewardId)
            local params =
            {
                collectibleId = collectibleId,
                showIfPurchasable = true,
            }
            self:LayoutCollectibleWithParams(params)
            return
        elseif rewardType == REWARD_ENTRY_TYPE_ITEM then
            local stackCount = amount
            local itemLink = GetItemRewardItemLink(rewardId, amount, displayFlags)
            self:LayoutItemWithStackCount(itemLink, NOT_EQUIPPED, NO_CREATOR_NAME, FORCE_FULL_DURABILITY, NO_PREVIEW_VALUE, stackCount, EQUIP_SLOT_NONE)
            return
        elseif rewardType == REWARD_ENTRY_TYPE_LOOT_CRATE then
            local crateId = GetCrownCrateRewardCrateId(rewardId)
            local quantity = amount
            self:LayoutCrownCrate(crateId, quantity)
            return
        elseif rewardType == REWARD_ENTRY_TYPE_ADD_CURRENCY then
            local currencyType = GetAddCurrencyRewardInfo(rewardId)
            self:LayoutCurrency(currencyType, amount)
            return
        elseif rewardType == REWARD_ENTRY_TYPE_INSTANT_UNLOCK then
            local instantUnlockId = GetInstantUnlockRewardInstantUnlockId(rewardId)
            self:LayoutInstantUnlock(instantUnlockId)
            return
        end
    end
end

do
    local g_dailyLoginRewardtimerStatValuePair
    function ZO_Tooltip:LayoutDailyLoginReward(rewardIndex)
        local rewardId, quantity = GetDailyLoginRewardInfoForCurrentMonth(rewardIndex)
        if ShouldUseFallbackReward(rewardId) then
            rewardId, quantity = GetFallbackReward(rewardId)
        end

        self:LayoutReward(rewardId, quantity, REWARD_DISPLAY_FLAGS_NONE)

        g_dailyLoginRewardtimerStatValuePair = nil
        local claimableRewardIndex = GetDailyLoginClaimableRewardIndex()
        local nextPotentialRewardIndex = ZO_DAILYLOGINREWARDS_MANAGER:GetNextPotentialReward()
        if not claimableRewardIndex and nextPotentialRewardIndex == rewardIndex then
            local timeToNextClaim = GetTimeUntilNextDailyLoginRewardClaimS()
            local timeToNextMonth = GetTimeUntilNextDailyLoginMonthS()
            if timeToNextMonth == 0 or timeToNextClaim < timeToNextMonth then
                local timerSection = self:AcquireSection(self:GetStyle("dailyLoginRewardsTimerSection"))
                local statValuePair = timerSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
                statValuePair:SetStat(GetString(SI_GAMEPAD_DAILY_LOGIN_REWARDS_TOOLTIP_AVAILABLE_TIMER), self:GetStyle("statValuePairStat"))
                local formattedTime = ZO_FormatTimeLargestTwo(timeToNextClaim, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
            
                statValuePair:SetValue(formattedTime, self:GetStyle("statValuePairValue"))
                timerSection:AddStatValuePair(statValuePair)
                self:AddSection(timerSection)
                g_dailyLoginRewardtimerStatValuePair = statValuePair
            end
        end

        if rewardIndex > GetNumClaimableDailyLoginRewardsInCurrentMonth() then
            local lockedSection = self:AcquireSection(self:GetStyle("dailyLoginRewardsLockedSection"))
            lockedSection:AddLine(GetString(SI_DAILY_LOGIN_REWARDS_NOT_CLAIMABLE_TOOLTIP))
            self:AddSection(lockedSection)
        end
    end

    function ZO_Tooltip:UpdateDailyLoginRewardTimer()
        if g_dailyLoginRewardtimerStatValuePair then
            local formattedTime = ZO_FormatTimeLargestTwo(GetTimeUntilNextDailyLoginRewardClaimS(), TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
            g_dailyLoginRewardtimerStatValuePair:SetValue(formattedTime, self:GetStyle("statValuePairValue"))
        end
    end
end

function ZO_Tooltip:LayoutRewardData(rewardData)
    local rewardId = rewardData:GetRewardId()
    local quantity = rewardData:GetQuantity()
    local displayFlags = rewardData:GetDisplayFlags()
    self:LayoutReward(rewardId, quantity, displayFlags)
end
