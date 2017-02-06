--[[
This file and its accompanying XML file exist for when we decide to rename/refactor 
a system and want ensure backward compatibility for addons.  Just alias the old functions
and inherit any controls you change in a newly commented section.
--]]


--ZO_MoneyInput Changes to ZO_CurrencyInput
MONEY_INPUT = CURRENCY_INPUT

ZO_DefaultMoneyInputField_Initialize = ZO_DefaultCurrencyInputField_Initialize
ZO_DefaultMoneyInputField_SetUsePlayerGoldAsMax = ZO_DefaultCurrencyInputField_SetUsePlayerCurrencyAsMax
ZO_DefaultMoneyInputField_SetGoldMax = ZO_DefaultCurrencyInputField_SetCurrencyMax
ZO_DefaultMoneyInputField_SetGoldMin = ZO_DefaultCurrencyInputField_SetCurrencyMin
ZO_DefaultMoneyInputField_SetMoney = ZO_DefaultCurrencyInputField_SetCurrencyAmount
ZO_DefaultMoneyInputField_GetMoney = ZO_DefaultCurrencyInputField_GetCurrency
--TopLevel CurrencyInput control
ZO_MoneyInput = ZO_CurrencyInput

EVENT_RESURRECT_FAILURE = EVENT_RESURRECT_RESULT
RESURRECT_FAILURE_REASON_DECLINED = RESURRECT_RESULT_DECLINED
RESURRECT_FAILURE_REASON_ALREADY_CONSIDERING = RESURRECT_RESULT_ALREADY_CONSIDERING
RESURRECT_FAILURE_REASON_SOUL_GEM_IN_USE = RESURRECT_RESULT_SOUL_GEM_IN_USE
RESURRECT_FAILURE_REASON_NO_SOUL_GEM = RESURRECT_RESULT_NO_SOUL_GEM

-- Cadwell progression is now separate from player difficulty
EVENT_DIFFICULTY_LEVEL_CHANGED = EVENT_CADWELL_PROGRESSION_LEVEL_CHANGED
GetPlayerDifficultyLevel = GetCadwellProgressionLevel
GetNumZonesForDifficultyLevel = GetNumZonesForCadwellProgressionLevel
GetNumPOIsForDifficultyLevelAndZone = GetNumPOIsForCadwellProgressionLevelAndZone
PLAYER_DIFFICULTY_LEVEL_FIRST_ALLIANCE = CADWELL_PROGRESSION_LEVEL_BRONZE
PLAYER_DIFFICULTY_LEVEL_SECOND_ALLIANCE = CADWELL_PROGRESSION_LEVEL_SILVER
PLAYER_DIFFICULTY_LEVEL_THIRD_ALLIANCE = CADWELL_PROGRESSION_LEVEL_GOLD

-- Player Inventory List Control
ZO_PlayerInventoryBackpack = ZO_PlayerInventoryList

--Raid function rename
GetRaidReviveCounterInfo = GetRaidReviveCountersRemaining

--ItemStoleType is now OwnershipStatus
ITEM_STOLEN_TYPE_ANY = OWNERSHIP_STATUS_ANY
ITEM_STOLEN_TYPE_NOT_STOLEN = OWNERSHIP_STATUS_NOT_STOLEN
ITEM_STOLEN_TYPE_STOLEN = OWNERSHIP_STATUS_STOLEN

RESURRECT_FAILURE_REASON_ALREADY_CONSIDERING = RESURRECT_RESULT_ALREADY_CONSIDERING           
RESURRECT_FAILURE_REASON_DECLINED = RESURRECT_RESULT_DECLINED

EVENT_GUILD_MEMBER_CHARACTER_VETERAN_RANK_CHANGED = EVENT_GUILD_MEMBER_CHARACTER_CHAMPION_POINTS_CHANGED
EVENT_FRIEND_CHARACTER_VETERAN_RANK_CHANGED = EVENT_FRIEND_CHARACTER_CHAMPION_POINTS_CHANGED

function GetItemLinkGlyphMinMaxLevels(itemLink)
	local minLevel, minChampPoints = GetItemLinkGlyphMinLevels(itemLink) 
	local maxLevel = nil
	local maxChampPoints = nil
	return minLevel, maxLevel, minChampPoints, maxChampPoints
end

--Renamed some NameplateDisplayChoice settings
NAMEPLATE_CHOICE_OFF = NAMEPLATE_CHOICE_NEVER
NAMEPLATE_CHOICE_ON = NAMEPLATE_CHOICE_ALWAYS
NAMEPLATE_CHOICE_HURT = NAMEPLATE_CHOICE_INJURED_OR_TARGETED

--Stat Change
STAT_WEAPON_POWER = STAT_WEAPON_AND_SPELL_DAMAGE

-- VR Removal 
GetUnitVeteranRank = GetUnitChampionPoints
GetUnitVeteranPoints = GetUnitXP
GetNumVeteranPointsInRank = GetNumChampionXPInChampionPoint
GetItemRequiredVeteranRank = GetItemRequiredChampionPoints
IsUnitVetBattleLeveled = IsUnitChampionBattleLeveled
IsUnitVeteran = IsUnitChampion
GetItemLinkRequiredVeteranRank = GetItemLinkRequiredChampionPoints
GetGamepadVeteranRankIcon = GetGamepadChampionPointsIcon
GetVeteranRankIcon = GetChampionPointsIcon
GetMaxVeteranRank = GetChampionPointsPlayerProgressionCap

VETERAN_POINTS_GAIN = EVENT_EXPERIENCE_GAIN
VETERAN_POINTS_UPDATE = CHAMPION_POINT_UPDATE
EVENT_FRIEND_CHARACTER_VETERAN_RANK_CHANGED = EVENT_FRIEND_CHARACTER_CHAMPION_POINTS_CHANGED
EVENT_GUILD_MEMBER_CHARACTER_VETERAN_RANK_CHANGED = EVENT_GUILD_MEMBER_CHARACTER_CHAMPION_POINTS_CHANGED

--Traits Changed
ITEM_TRAIT_TYPE_ARMOR_EXPLORATION = ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS
ITEM_TRAIT_TYPE_WEAPON_WEIGHTED = ITEM_TRAIT_TYPE_WEAPON_DECISIVE

--Dyeing Changed
SetPendingEquippedItemDye = function(equipSlot, primary, secondary, accent)
                                local dyeableSlot = GetEquipSlotFromDyeableSlot(equipSlot)
                                SetPendingSlotDyes(dyeableSlot, primary, secondary, accent)
                            end
GetPendingEquippedItemDye = function(equipSlot)
                                local dyeableSlot = GetEquipSlotFromDyeableSlot(equipSlot)
                                return GetPendingSlotDyes(dyeableSlot)
                            end

-- Removed 'by-zone' scaling for OneTamriel. Zone is no longer relevant to quest rewards.
GetJournalQuestRewardInfoInZone = function(zoneIndex, journalQuestIndex, rewardIndex)
                                      return GetJournalQuestRewardInfo(journalQuestIndex, rewardIndex)
                                  end

--Merged these two events in to one event that also includes success
EVENT_COLLECTIBLE_ON_COOLDOWN = EVENT_COLLECTIBLE_USE_RESULT
EVENT_COLLECTIBLE_USE_BLOCKED = EVENT_COLLECTIBLE_USE_RESULT

--Renamed quest instance type function to match the others
GetJournalInstanceDisplayType = GetJournalQuestInstanceDisplayType

--Recipes can now have multiple tradeskill requirements
GetItemLinkRecipeRankRequirement = function(itemLink)
    for i = 1, GetItemLinkRecipeNumTradeskillRequirements(itemLink) do
        local tradeskill, levelRequirement = GetItemLinkTradeskillRequirement(itemLink, i)
        if tradeskill == CRAFTING_TYPE_PROVISIONING then
            return levelRequirement
        end
    end
    return 0
end

--Items can now be converted to more styles than just imperial
CanConvertItemStyleToImperial = function(itemToBagId, itemToSlotIndex)
    return CanConvertItemStyle(itemToBagId, itemToSlotIndex, ITEMSTYLE_RACIAL_IMPERIAL)
end

ConvertItemStyleToImperial = function(itemToBagId, itemToSlotIndex)
    ConvertItemStyle(itemToBagId, itemToSlotIndex, ITEMSTYLE_RACIAL_IMPERIAL)
end

--renamed this type
COLLECTIBLE_CATEGORY_TYPE_TROPHY = COLLECTIBLE_CATEGORY_TYPE_MEMENTO

--Condensed these into one function
IsPOIWayshrine = function(zoneIndex, poiIndex)
    return GetPOIType(zoneIndex, poiIndex) == POI_TYPE_WAYSHRINE
end

IsPOIPublicDungeon = function(zoneIndex, poiIndex)
    return GetPOIType(zoneIndex, poiIndex) == POI_TYPE_PUBLIC_DUNGEON
end

IsPOIGroupDungeon = function(zoneIndex, poiIndex)
    return GetPOIType(zoneIndex, poiIndex) == POI_TYPE_GROUP_DUNGEON
end

-- Added category to item tags
GetItemLinkItemTagDescription = function(itemLink, index)
    local description, category = GetItemLinkItemTagInfo(itemLink, index)
    return description
end
