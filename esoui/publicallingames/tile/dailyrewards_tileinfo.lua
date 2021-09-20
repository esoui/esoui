DAILY_REWARDS_TILE_DIMENSIONS_X = 315
DAILY_REWARDS_TILE_DIMENSIONS_Y = 210

-- To only be used with daily login reward-based tiles.
-- Only add functions that access data and pass it back to the caller
ZO_DailyRewards_TileInfo = ZO_Object:Subclass()

function ZO_DailyRewards_TileInfo:New()
    return ZO_Object.New(self)
end

function ZO_DailyRewards_TileInfo:GetUnclaimedHeaderText()
    return GetString(SI_DAILY_LOGIN_REWARDS_TILE_HEADER)
end

function ZO_DailyRewards_TileInfo:GetClaimedHeaderText(isSelected)
    local timeRemaining
    if ZO_DAILYLOGINREWARDS_MANAGER:HasClaimableRewardInMonth() then
        timeRemaining = GetTimeUntilNextDailyLoginRewardClaimS()
    else
        timeRemaining = GetTimeUntilNextDailyLoginMonthS()
    end
    local countDownText = ZO_FormatTime(timeRemaining, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR_NO_SECONDS)
    if isSelected then
        countDownText =  ZO_SELECTED_TEXT:Colorize(countDownText)
    else
        countDownText =  ZO_MARKET_DIMMED_COLOR:Colorize(countDownText)
    end

    return zo_strformat(SI_DAILY_LOGIN_REWARDS_CLAIMED_TILE_HEADER, countDownText)
end

function ZO_DailyRewards_TileInfo:GetTitleAndBackground(dailyRewardIndex)
    local title
    local background

    if dailyRewardIndex and not (GetDailyLoginClaimableRewardIndex() == nil and GetTimeUntilNextDailyLoginMonthS() <= ZO_ONE_DAY_IN_SECONDS) then
        local rewardId, quantity = GetDailyLoginRewardInfoForCurrentMonth(dailyRewardIndex)
        local rewardData = REWARDS_MANAGER:GetInfoForDailyLoginReward(rewardId, quantity)
        if rewardData then
            if rewardData:GetQuantity() > 1 then
                if IsInGamepadPreferredMode() then
                    local entryType = GetRewardType(rewardId)
                    if entryType == REWARD_ENTRY_TYPE_ADD_CURRENCY then
                        title = rewardData:GetFormattedNameWithStackGamepad()
                    else
                        -- Item/crown crate name formatting colorizes quantity, so we need to format the raw name ourselves here to preserve gamepad selection indicator behavior.
                        title = zo_strformat(SI_REWARDS_FORMAT_REWARD_WITH_AMOUNT, rewardData:GetRawName(), rewardData:GetQuantity())
                    end
                else
                    title = rewardData:GetFormattedNameWithStack()
                end
            else
                title = rewardData:GetFormattedName()
            end
            background = rewardData:GetAnnouncementBackground()

            return title, background
        end
    end

    -- if we didn't find the reward, it means we are at the end of the month
    title = GetString(SI_DAILY_LOGIN_REWARDS_MONTH_COMPLETE_TILE_TITLE)
    background = GetMarketAnnouncementCompletedDailyLoginRewardClaimsBackground()

    return title, background
end