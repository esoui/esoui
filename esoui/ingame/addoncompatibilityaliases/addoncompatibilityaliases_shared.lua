--[[
This file and its accompanying XML file exist for when we decide to rename/refactor 
a system and want ensure backward compatibility for addons.  Just alias the old functions
and inherit any controls you change in a newly commented section. This file is for any aliases we want to exist on both PC and Console
--]]

-- Adds aliases to source object for the specified methods of target object.
local function AddMethodAliases(sourceObject, targetObject, methodNameList)
    for _, methodName in ipairs(methodNameList) do
        internalassert(sourceObject[methodName] == nil, string.format("Method '%s' of sourceObject already exists.", methodName))
        internalassert(type(targetObject[methodName]) == "function", string.format("Method '%s' of targetObject does not exist.", methodName))

        sourceObject[methodName] = function(originalSelf, ...)
            return targetObject[methodName](targetObject, ...)
        end
    end
end

GetCollectibleForHouseBankBag = GetCollectibleForBag
GetCollectibleBankAccessBag = GetBagForCollectible
GetLinkLayoutHandlerName = ZO_GetLinkLayoutHandlerName

function GetMarketProductUnlockedByAchievementInfo(marketProductId)
    local achievementId = GetMarketProductUnlockedByAchievementId(marketProductId)
    local isAchievementComplete = IsAchievementComplete(achievementId)
    local helpCategoryIndex, helpIndex = GetMarketProductUnlockedHelpIndices(marketProductId)
    return achievementId, isAchievementComplete, helpCategoryIndex, helpIndex
end

ITEM_SET_SUPPRESSION_TYPE_NONE = ITEM_BONUS_SUPPRESSION_TYPE_NONE
ITEM_SET_SUPPRESSION_TYPE_CAMPAIGN = ITEM_BONUS_SUPPRESSION_TYPE_CAMPAIGN
ITEM_SET_SUPPRESSION_TYPE_BATTLE_GROUND = ITEM_BONUS_SUPPRESSION_TYPE_BATTLE_GROUND
ITEM_SET_SUPPRESSION_TYPE_ABILITY = ITEM_BONUS_SUPPRESSION_TYPE_ABILITY
ITEM_SET_SUPPRESSION_TYPE_ITEMSET = ITEM_BONUS_SUPPRESSION_TYPE_ITEMSET

-- Currency rename
CURT_CHAOTIC_CREATIA = CURT_TRANSMUTE_CRYSTALS
CURT_ENDEAVOR_SEALS = CURT_SEALS
MKCT_ENDEAVOR_SEALS = MKCT_SEALS
CURRENCY_CHANGE_REASON_PURCHASED_WITH_ENDEAVOR_SEALS = CURRENCY_CHANGE_REASON_PURCHASED_WITH_SEALS
REWARD_TYPE_EVENT_TICKETS = REWARD_TYPE_TRADE_BARS
MARKET_PRODUCT_FILTER_TYPE_COST_ENDEAVOR_SEALS = MARKET_PRODUCT_FILTER_TYPE_COST_SEALS
EVENT_TICKET_UPDATE = EVENT_TRADE_BAR_UPDATE

-- SlashCommandAutoComplete rename
SlashCommandAutoComplete = ZO_SlashCommandAutoComplete

-- ZO_PlatformUtils.lua
ZO_IsConsoleUI = IsConsoleUI

-- Returning player refactor
function GetReturningPlayerIntroGameplayData()
    return GetIntroGameplayExperienceData(PROMOTIONAL_EVENTS_PERSONAL_CAMPAIGN_TYPE_RETURNING_PLAYER)
end

function GetExpectedJumpToReturningPlayerIntroGameplayResult()
    return GetExpectedJumpToIntroGameplayExperienceResult()
end

function GetReturningPlayerCampaignDisplayName()
    return GetPromotionalEventPersonalCampaignDisplayName(PROMOTIONAL_EVENTS_PERSONAL_CAMPAIGN_TYPE_RETURNING_PLAYER)
end

GetReturningPlayerIntroGameplayDisplayName = GetIntroGameplayExperienceDisplayName
IsInReturningPlayerIntroWorld = IsInIntroGameplayExperienceWorld
ShouldShowReturningPlayerLeaveIntroPrompt = ShouldShowPromotionalEventPersonalCampaignLeaveIntroPrompt
MarkReturningPlayerLeaveIntroPromptShown = MarkPromotionalEventPersonalCampaignLeaveIntroPromptShown
HandleReturningPlayerUISystemShown = HandleUISystemShown
HasShownReturningPlayerAnnouncement = HasShownPromotionalEventPersonalCampaignAnnouncement
FlagReturningPlayerAnnouncementSeen = FlagPromotionalEventPersonalCampaignAnnouncementSeen

RETURNING_PLAYER_INSTANCE_JUMP_RESULT_SUCCESS = INTRO_GAMEPLAY_EXPERIENCE_JUMP_RESULT_SUCCESS
RETURNING_PLAYER_INSTANCE_JUMP_RESULT_JUMP_FAILED = INTRO_GAMEPLAY_EXPERIENCE_JUMP_RESULT_JUMP_FAILED
RETURNING_PLAYER_INSTANCE_JUMP_RESULT_NOT_ELIGIBLE = INTRO_GAMEPLAY_EXPERIENCE_JUMP_RESULT_NOT_ELIGIBLE
RETURNING_PLAYER_INSTANCE_JUMP_RESULT_ALREADY_IN_INSTANCE = INTRO_GAMEPLAY_EXPERIENCE_JUMP_RESULT_ALREADY_IN_INSTANCE
RETURNING_PLAYER_INSTANCE_JUMP_RESULT_CANT_JUMP_FROM_ZONE = INTRO_GAMEPLAY_EXPERIENCE_JUMP_RESULT_CANT_JUMP_FROM_ZONE
RETURNING_PLAYER_INSTANCE_JUMP_RESULT_MIN_VALUE = INTRO_GAMEPLAY_EXPERIENCE_JUMP_RESULT_MIN_VALUE
RETURNING_PLAYER_INSTANCE_JUMP_RESULT_MAX_VALUE = INTRO_GAMEPLAY_EXPERIENCE_JUMP_RESULT_MAX_VALUE
RETURNING_PLAYER_INSTANCE_JUMP_RESULT_ITERATION_BEGIN = INTRO_GAMEPLAY_EXPERIENCE_JUMP_RESULT_ITERATION_BEGIN
RETURNING_PLAYER_INSTANCE_JUMP_RESULT_ITERATION_END = INTRO_GAMEPLAY_EXPERIENCE_JUMP_RESULT_ITERATION_END
EVENT_RETURNING_PLAYER_INSTANCE_JUMP_RESULT = EVENT_INTRO_GAMEPLAY_EXPERIENCE_JUMP_RESULT

function GetNumReturningPlayerPrimaryRewards()
    return GetNumPromotionalEventPersonalCampaignPrimaryRewards(PROMOTIONAL_EVENTS_PERSONAL_CAMPAIGN_TYPE_RETURNING_PLAYER)
end

function GetReturningPlayerPrimaryRewardData(rewardIndex)
    return GetPromotionalEventPersonalCampaignPrimaryRewardData(PROMOTIONAL_EVENTS_PERSONAL_CAMPAIGN_TYPE_RETURNING_PLAYER, rewardIndex)
end

function ZoIsOfficialLanguageSupported()
    return true
end

-- Refactored the names to make more sense
ZO_Tracker.GetContainerControl = ZO_Tracker.GetTrackerControl

-- Renamed tracker
ZO_PromotionalEventTracker = ZO_TimedActivityTracker
PROMOTIONAL_EVENT_TRACKER_FRAGMENT = TIMED_ACTIVITY_TRACKER_FRAGMENT
PROMOTIONAL_EVENT_TRACKER = TIMED_ACTIVITY_TRACKER
ZO_PromotionalEventTracker_TL = ZO_TimedActivityTracker_TL

-- Zone Guide Updates
AreAllZoneStoryActivitiesCompleteForZoneCompletionType = AreAllZoneStoryActivitiesCompleteForZoneCompletionTypeAndIndex
GetNumZoneActivitiesForZoneCompletionType = GetNumZoneActivitiesForZoneCompletionTypeAndIndex
GetNumUnblockedZoneStoryActivitiesForZoneCompletionType = GetNumUnblockedZoneStoryActivitiesForZoneCompletionTypeAndIndex
GetNumCompletedZoneActivitiesForZoneCompletionType = GetNumCompletedZoneActivitiesForZoneCompletionTypeAndIndex

-- Crossplay changes
PRIMARY_PLAYER_NAME_SETTING_PREFER_USERID = PRIMARY_PLAYER_NAME_SETTING_PREFER_PLATFORM

-- Furniture Action Preview changes
local NO_VARIATION_INDEX = 0

GetNumInventoryItemPreviewCollectibleActions = GetNumInventoryItemPreviewActions
GetInventoryItemPreviewCollectibleActionDisplayName = GetInventoryItemPreviewActionDisplayName
PreviewInventoryItemCollectibleAction = function(bag, slotIndex, action)
    PreviewInventoryItemAction(bag, slotIndex, NO_VARIATION_INDEX, action)
end

GetNumRewardPreviewCollectibleActions = GetNumRewardPreviewActions
GetRewardPreviewCollectibleActionDisplayName = GetRewardPreviewActionDisplayName
PreviewRewardCollectibleAction = function(rewardId, action)
    PreviewRewardAction(rewardId, NO_VARIATION_INDEX, action)
end

GetNumStoreEntryPreviewCollectibleActions = GetNumStoreEntryPreviewActions
GetStoreEntryPreviewCollectibleActionDisplayName = GetStoreEntryPreviewActionDisplayName
PreviewStoreEntryCollectibleAction = function(storeEntryIndex, action)
    PreviewStoreEntryAction(storeEntryIndex, NO_VARIATION_INDEX, action)
end

GetNumTradingHouseSearchResultItemPreviewCollectibleActions = GetNumTradingHouseSearchResultItemPreviewActions
GetTradingHouseSearchResultItemPreviewCollectibleActionDisplayName = GetTradingHouseSearchResultItemPreviewActionDisplayName
PreviewTradingHouseSearchResultItemCollectibleAction = function(index, action)
    PreviewTradingHouseSearchResultItemAction(index, NO_VARIATION_INDEX, action)
end

ZO_VengeanceLoadoutData.GetName = ZO_VengeanceLoadoutData.GetRawName
ZO_VengeancePerkData.GetName = ZO_VengeancePerkData.GetRawName
ZO_VeterancyRankData.GetName = ZO_VeterancyRankData.GetRawName
ZO_VengeanceLoadoutData.GetPerkNameBySlot = ZO_VengeanceLoadoutData.GetRawPerkNameBySlot
ZO_Veterancy_Manager.GetCurrentRankName = ZO_Veterancy_Manager.GetCurrentRankRawName
