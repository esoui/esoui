do
    local NO_CATEGORY_NAME = nil
    local NO_NICKNAME = nil
    local BLANK_HINT = ""
    local HIDE_VISUAL_LAYER_INFO = false
    local NO_COOLDOWN = nil
    local HIDE_BLOCK_REASON = false
    local NOT_EQUIPPED = false
    local NO_CREATOR_NAME = nil
    local FORCE_FULL_DURABILITY = true
    local NO_PREVIEW_VALUE = nil

    function ZO_Tooltip:LayoutReward(rewardId, amount)
        local rewardType = GetRewardType(rewardId)
        -- For some market product types we can just use other tooltip layouts
        if rewardType == REWARD_ENTRY_TYPE_COLLECTIBLE then
            local collectibleId = GetCollectibleRewardCollectibleId(rewardId)
            local name, description, icon, _, _, isPurchasable, _, categoryType, hint, isPlaceholder = GetCollectibleInfo(collectibleId)
            self:LayoutCollectible(collectibleId, NO_CATEGORY_NAME, name, NO_NICKNAME, isPurchasable, description, BLANK_HINT, isPlaceholder, categoryType, HIDE_VISUAL_LAYER_INFO, NO_COOLDOWN, HIDE_BLOCK_REASON)
            return
        elseif rewardType == REWARD_ENTRY_TYPE_ITEM then
            local stackCount = amount
            local itemLink = GetItemRewardItemLink(rewardId, amount)
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
        self:LayoutReward(rewardId, quantity)

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
    end

    function ZO_Tooltip:UpdateDailyLoginRewardTimer()
        if g_dailyLoginRewardtimerStatValuePair then
            local formattedTime = ZO_FormatTimeLargestTwo(GetTimeUntilNextDailyLoginRewardClaimS(), TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL)
            g_dailyLoginRewardtimerStatValuePair:SetValue(formattedTime, self:GetStyle("statValuePairValue"))
        end
    end
end

function ZO_Tooltip:LayoutRewardData(rewardData)
    self:LayoutReward(rewardData:GetRewardId(), rewardData:GetQuantity())
end
