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
                                SetPendingSlotDyes(RESTYLE_MODE_EQUIPMENT, ZO_RESTYLE_DEFAULT_SET_INDEX, equipSlot, primary, secondary, accent)
                            end
GetPendingEquippedItemDye = function(equipSlot)
                                return GetPendingSlotDyes(RESTYLE_MODE_EQUIPMENT, ZO_RESTYLE_DEFAULT_SET_INDEX, equipSlot)
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
        local tradeskill, levelRequirement = GetItemLinkRecipeTradeskillRequirement(itemLink, i)
        if tradeskill == CRAFTING_TYPE_PROVISIONING then
            return levelRequirement
        end
    end
    return 0
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

--Switched Activity Finder API from activityType and index based to Id based
function GetCurrentLFGActivity()
    local activityId = GetCurrentLFGActivityId()
    if activityId > 0 then
        return GetActivityTypeAndIndex(activityId)
    end
end

do
    local function BasicTypeIndexToIdTemplate(idFunction, activityType, index)
        local activityId = GetActivityIdByTypeAndIndex(activityType, index)
        return idFunction(activityId)
    end

    GetLFGOption = function(...) return BasicTypeIndexToIdTemplate(GetActivityInfo, ...) end
    GetLFGOptionKeyboardDescriptionTextures = function(...) return BasicTypeIndexToIdTemplate(GetActivityKeyboardDescriptionTextures, ...) end
    GetLFGOptionGamepadDescriptionTexture = function(...) return BasicTypeIndexToIdTemplate(GetActivityGamepadDescriptionTexture, ...) end
    GetLFGOptionGroupType = function(...) return BasicTypeIndexToIdTemplate(GetActivityGroupType, ...) end
    DoesPlayerMeetLFGLevelRequirements = function(...) return BasicTypeIndexToIdTemplate(DoesPlayerMeetActivityLevelRequirements, ...) end
    DoesGroupMeetLFGLevelRequirements = function(...) return BasicTypeIndexToIdTemplate(DoesGroupMeetActivityLevelRequirements, ...) end
    GetRequiredLFGCollectibleId = function(...) return BasicTypeIndexToIdTemplate(GetRequiredActivityCollectibleId, ...) end
end

function AddGroupFinderSearchEntry(activityType, index)
    if index then
        local activityId = GetActivityIdByTypeAndIndex(activityType, index)
        AddActivityFinderSpecificSearchEntry(activityId)
    end
end

function GetLFGRequestInfo(requestIndex)
    local activityId = GetActivityRequestIds()
    return GetActivityTypeAndIndex(activityId)
end

function GetLFGFindReplacementNotificationInfo()
    local activityId = GetActivityFindReplacementNotificationInfo(activityType, index)
    if activityId then
        return GetActivityTypeAndIndex(activityId)
    end
end

function GetLFGAverageRoleTimeByActivity(activityType, index, role)
    local activityId = GetActivityIdByTypeAndIndex(activityType, index)
    return GetActivityAverageRoleTime(activityId, role)
end

-- Queueing by activity type is no longer supported, replaced by LFGSets
function AddActivityFinderRandomSearchEntry()
    -- Do nothing
end

function DoesLFGActivityHasAllOption()
    return false
end

function GetLFGActivityRewardData()
    local REWARD_UI_DATA_ID = 0
    local XP_REWARD = 0
    return REWARD_UI_DATA_ID, XP_REWARD
end

GetNumLFGOptions = GetNumActivitiesByType
GetNumLFGRequests = GetNumActivityRequests
HasLFGFindReplacementNotification = HasActivityFindReplacementNotification
AcceptLFGFindReplacementNotification = AcceptActivityFindReplacementNotification
DeclineLFGFindReplacementNotification = DeclineActivityFindReplacementNotification

--Used to be dungeon only.  Now there's also battlegrounds.  Should use GetLFGCooldownTimeRemainingSeconds now.
function IsEligibleForDailyActivityReward()
    return IsActivityEligibleForDailyReward(LFG_ACTIVITY_DUNGEON)
end

--Renamed the objective functions to indicate that they aren't specific to AvA anymore
GetNumAvAObjectives = GetNumObjectives
GetAvAObjectiveKeysByIndex = GetObjectiveIdsForIndex
GetAvAObjectiveInfo = GetObjectiveInfo
GetAvAObjectivePinInfo = GetObjectivePinInfo
GetAvAObjectiveSpawnPinInfo = GetObjectiveSpawnPinInfo
IsAvAObjectiveInBattleground = IsBattlegroundObjective

--Exposed the quest item id instead of duplicating the tooltip function for each system
GetQuestLootItemTooltipInfo = function(lootId)
    local questItemId = GetLootQuestItemId(lootId)
    local itemName = GetQuestItemName(questItemId)
    local tooltipText = GetQuestItemTooltipText(questItemId)
    return GetString(SI_ITEM_FORMAT_STR_QUEST_ITEM), itemName, tooltipText
end

GetQuestToolTooltipInfo = function(questIndex, toolIndex)
    local questItemId = GetQuestToolQuestItemId(questIndex, toolIndex)
    local itemName = GetQuestItemName(questItemId)
    local tooltipText = GetQuestItemTooltipText(questItemId)
    return GetString(SI_ITEM_FORMAT_STR_QUEST_ITEM), itemName, tooltipText    
end

GetQuestItemTooltipInfo = function(questIndex, stepIndex, conditionIndex)
    local questItemId = GetQuestConditionQuestItemId(questIndex, stepIndex, conditionIndex)
    local itemName = GetQuestItemName(questItemId)
    local tooltipText = GetQuestItemTooltipText(questItemId)
    return GetString(SI_ITEM_FORMAT_STR_QUEST_ITEM), itemName, tooltipText    
end

GetNumGuildPermissions = function()
    return GUILD_PERMISSION_MAX_VALUE
end

-- Removal of ItemStyle Enum

function GetNumSmithingStyleItems()
    return GetHighestItemStyleId()
end

function GetFirstKnownStyleIndex()
    return GetFirstKnownItemStyleId()
end

function GetSmithingStyleItemInfo(itemStyleId)
    local styleItemLink = GetItemStyleMaterialLink(itemStyleId)
    local alwaysHideIfLocked = GetItemStyleInfo(itemStyleId)
    local name = GetItemLinkName(styleItemLink)
    local icon, sellPrice, meetsUsageRequirement = GetItemLinkInfo(styleItemLink)
    local quality = GetItemLinkQuality(styleItemLink)
    return name, icon, sellPrice, meetsUsageRequirement, itemStyleId, quality, alwaysHideIfLocked
end

ITEMSTYLE_NONE                      = 0
ITEMSTYLE_RACIAL_BRETON             = 1
ITEMSTYLE_RACIAL_REDGUARD           = 2
ITEMSTYLE_RACIAL_ORC                = 3
ITEMSTYLE_RACIAL_DARK_ELF           = 4
ITEMSTYLE_RACIAL_NORD               = 5
ITEMSTYLE_RACIAL_ARGONIAN           = 6
ITEMSTYLE_RACIAL_HIGH_ELF           = 7
ITEMSTYLE_RACIAL_WOOD_ELF           = 8
ITEMSTYLE_RACIAL_KHAJIIT            = 9
ITEMSTYLE_UNIQUE                    = 10
ITEMSTYLE_ORG_THIEVES_GUILD         = 11
ITEMSTYLE_ORG_DARK_BROTHERHOOD      = 12
ITEMSTYLE_DEITY_MALACATH            = 13
ITEMSTYLE_AREA_DWEMER               = 14
ITEMSTYLE_AREA_ANCIENT_ELF          = 15
ITEMSTYLE_DEITY_AKATOSH             = 16
ITEMSTYLE_AREA_REACH                = 17
ITEMSTYLE_ENEMY_BANDIT              = 18
ITEMSTYLE_ENEMY_PRIMITIVE           = 19
ITEMSTYLE_ENEMY_DAEDRIC             = 20
ITEMSTYLE_DEITY_TRINIMAC            = 21
ITEMSTYLE_AREA_ANCIENT_ORC          = 22
ITEMSTYLE_ALLIANCE_DAGGERFALL       = 23
ITEMSTYLE_ALLIANCE_EBONHEART        = 24
ITEMSTYLE_ALLIANCE_ALDMERI          = 25
ITEMSTYLE_UNDAUNTED                 = 26
ITEMSTYLE_RAIDS_CRAGLORN            = 27
ITEMSTYLE_GLASS                     = 28
ITEMSTYLE_AREA_XIVKYN               = 29
ITEMSTYLE_AREA_SOUL_SHRIVEN         = 30
ITEMSTYLE_ENEMY_DRAUGR              = 31
ITEMSTYLE_ENEMY_MAORMER             = 32
ITEMSTYLE_AREA_AKAVIRI              = 33
ITEMSTYLE_RACIAL_IMPERIAL           = 34
ITEMSTYLE_AREA_YOKUDAN              = 35
ITEMSTYLE_UNIVERSAL                 = 36
ITEMSTYLE_AREA_REACH_WINTER         = 37
ITEMSTYLE_AREA_TSAESCI              = 38
ITEMSTYLE_ENEMY_MINOTAUR            = 39
ITEMSTYLE_EBONY                     = 40
ITEMSTYLE_ORG_ABAHS_WATCH           = 41
ITEMSTYLE_HOLIDAY_SKINCHANGER       = 42
ITEMSTYLE_ORG_MORAG_TONG            = 43
ITEMSTYLE_AREA_RA_GADA              = 44
ITEMSTYLE_ENEMY_DROMOTHRA           = 45
ITEMSTYLE_ORG_ASSASSINS             = 46
ITEMSTYLE_ORG_OUTLAW                = 47
ITEMSTYLE_ORG_REDORAN               = 48
ITEMSTYLE_ORG_HLAALU                = 49
ITEMSTYLE_ORG_ORDINATOR             = 50
ITEMSTYLE_ORG_TELVANNI              = 51
ITEMSTYLE_ORG_BUOYANT_ARMIGER       = 52
ITEMSTYLE_HOLIDAY_FROSTCASTER       = 53
ITEMSTYLE_AREA_ASHLANDER            = 54
ITEMSTYLE_ORG_WORM_CULT             = 55
ITEMSTYLE_ENEMY_SILKEN_RING         = 56
ITEMSTYLE_ENEMY_MAZZATUN            = 57
ITEMSTYLE_HOLIDAY_GRIM_HARLEQUIN    = 58
ITEMSTYLE_HOLIDAY_HOLLOWJACK        = 59

ITEMSTYLE_MIN_VALUE                 = 1
ITEMSTYLE_MAX_VALUE                 = GetHighestItemStyleId()

--Currency Generalization

function GetCurrentMoney()
    return GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
end

function GetCarriedCurrencyAmount(currencyType)
    return GetCurrencyAmount(currencyType, CURRENCY_LOCATION_CHARACTER)
end

function GetBankedCurrencyAmount(currencyType)
    return GetCurrencyAmount(currencyType, CURRENCY_LOCATION_BANK)
end

function GetGuildBankedMoney()
    return GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_GUILD_BANK)
end

function GetGuildBankedCurrencyAmount(currencyType)
    return GetCurrencyAmount(currencyType, CURRENCY_LOCATION_GUILD_BANK)
end

function GetMaxCarriedCurrencyAmount(currencyType)
    return GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_CHARACTER)
end

function GetMaxBankCurrencyAmount(currencyType)
    return GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_BANK)
end

function GetMaxGuildBankCurrencyAmount(currencyType)
    return GetMaxPossibleCurrency(currencyType, CURRENCY_LOCATION_GUILD_BANK)
end

function GetMaxBankWithdrawal(currencyType)
    return GetMaxCurrencyTransfer(currencyType, CURRENCY_LOCATION_BANK, CURRENCY_LOCATION_CHARACTER)
end

function GetMaxBankDeposit(currencyType)
    return GetMaxCurrencyTransfer(currencyType, CURRENCY_LOCATION_CHARACTER, CURRENCY_LOCATION_BANK)
end

function GetMaxGuildBankWithdrawal(currencyType)
    return GetMaxCurrencyTransfer(currencyType, CURRENCY_LOCATION_GUILD_BANK, CURRENCY_LOCATION_CHARACTER)
end

function GetMaxGuildBankDeposit(currencyType)
    return GetMaxCurrencyTransfer(currencyType, CURRENCY_LOCATION_CHARACTER, CURRENCY_LOCATION_GUILD_BANK)
end

function DepositCurrencyIntoBank(currencyType, amount)
    TransferCurrency(currencyType, amount, CURRENCY_LOCATION_CHARACTER, CURRENCY_LOCATION_BANK)
end

function WithdrawCurrencyFromBank(currencyType, amount)
    TransferCurrency(currencyType, amount, CURRENCY_LOCATION_BANK, CURRENCY_LOCATION_CHARACTER)
end

function DepositMoneyIntoGuildBank(amount)
    TransferCurrency(CURT_MONEY, amount, CURRENCY_LOCATION_CHARACTER, CURRENCY_LOCATION_GUILD_BANK)
end

function WithdrawMoneyFromGuildBank(amount)
    TransferCurrency(CURT_MONEY, amount, CURRENCY_LOCATION_GUILD_BANK, CURRENCY_LOCATION_CHARACTER)
end

function DepositCurrencyIntoGuildBank(currencyType, amount)
    TransferCurrency(currencyType, amount, CURRENCY_LOCATION_CHARACTER, CURRENCY_LOCATION_GUILD_BANK)
end

function WithdrawCurrencyFromGuildBank(currencyType, amount)
    TransferCurrency(currencyType, amount, CURRENCY_LOCATION_GUILD_BANK, CURRENCY_LOCATION_CHARACTER)
end

function GetBankedMoney()
    return GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_BANK)
end

function DepositMoneyIntoBank(amount)
    DepositCurrencyIntoBank(CURT_MONEY, amount)
end

function WithdrawMoneyFromBank(amount)
    WithdrawCurrencyFromBank(CURT_MONEY, amount)
end

function GetBankedTelvarStones()
    return GetCurrencyAmount(CURT_TELVAR_STONES, CURRENCY_LOCATION_BANK)
end

function DepositTelvarStonesIntoBank(amount)
    DepositCurrencyIntoBank(CURT_TELVAR_STONES, amount)
end

function WithdrawTelvarStonesFromBank(amount)
    WithdrawCurrencyFromBank(CURT_TELVAR_STONES, amount)
end

function GetAlliancePoints()
    return GetCurrencyAmount(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_CHARACTER)
end

MAX_PLAYER_MONEY = MAX_PLAYER_CURRENCY

function ZO_Currency_GetPlatformFormattedGoldIcon()
    return ZO_Currency_GetPlatformFormattedCurrencyIcon(CURT_MONEY)
end

-- The concept of "abilities earned at a level" went away when we added Skill Lines, so we finally removed API for it
function GetNumAbilitiesLearnedForLevel(level, isProgression)
    if level == 0 then
        return GetNumAbilities()
    else
        return 0
    end
end

-- The concept of "abilities earned at a level" went away when we added Skill Lines, so we finally removed API for it
function GetLearnedAbilityInfoForLevel(level, learnedIndex, isProgression)
    if level == 0 then
        local name, textureFile, _, _, _, _ = GetAbilityInfoByIndex(learnedIndex)
        return name, textureFile, learnedIndex, 0
    else
        return "", "", 0, 0
    end
end

-- Battleground pin enum fixup
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_A_NEUTRAL = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_NEUTRAL
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_A_FIRE_DRAKES = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_FIRE_DRAKES
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_A_PIT_DAEMONS = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_PIT_DAEMONS
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_A_STORM_LORDS = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_STORM_LORDS
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_B_NEUTRAL = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_NEUTRAL
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_B_FIRE_DRAKES = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_FIRE_DRAKES
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_B_PIT_DAEMONS = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_PIT_DAEMONS
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_B_STORM_LORDS = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_STORM_LORDS
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_C_NEUTRAL = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_NEUTRAL
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_C_FIRE_DRAKES = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_FIRE_DRAKES
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_C_PIT_DAEMONS = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_PIT_DAEMONS
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_C_STORM_LORDS = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_STORM_LORDS
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_D_NEUTRAL = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_NEUTRAL
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_D_FIRE_DRAKES = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_FIRE_DRAKES
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_D_PIT_DAEMONS = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_PIT_DAEMONS
MAP_PIN_TYPE_BGPIN_MULTI_CAPTURE_AREA_D_STORM_LORDS = MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_STORM_LORDS

VISUAL_LAYER_HEADWEAR = VISUAL_LAYER_HAT

-- Unifying smithing filters
ZO_SMITHING_IMPROVEMENT_SHARED_FILTER_TYPE_ARMOR = SMITHING_FILTER_TYPE_ARMOR
ZO_SMITHING_IMPROVEMENT_SHARED_FILTER_TYPE_WEAPONS = SMITHING_FILTER_TYPE_WEAPONS

ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_ARMOR = SMITHING_FILTER_TYPE_ARMOR
ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_WEAPONS = SMITHING_FILTER_TYPE_WEAPONS
ZO_SMITHING_EXTRACTION_SHARED_FILTER_TYPE_RAW_MATERIALS = SMITHING_FILTER_TYPE_RAW_MATERIALS

ZO_SMITHING_CREATION_FILTER_TYPE_WEAPONS = SMITHING_FILTER_TYPE_WEAPONS
ZO_SMITHING_CREATION_FILTER_TYPE_ARMOR = SMITHING_FILTER_TYPE_ARMOR
ZO_SMITHING_CREATION_FILTER_TYPE_SET_WEAPONS = SMITHING_FILTER_TYPE_SET_WEAPONS
ZO_SMITHING_CREATION_FILTER_TYPE_SET_ARMOR = SMITHING_FILTER_TYPE_SET_ARMOR

ZO_SMITHING_RESEARCH_FILTER_TYPE_WEAPONS = SMITHING_FILTER_TYPE_WEAPONS
ZO_SMITHING_RESEARCH_FILTER_TYPE_ARMOR = SMITHING_FILTER_TYPE_ARMOR

ZO_RETRAIT_FILTER_TYPE_ARMOR = SMITHING_FILTER_TYPE_ARMOR
ZO_RETRAIT_FILTER_TYPE_WEAPONS = SMITHING_FILTER_TYPE_WEAPONS

SMITHING_MODE_REFINMENT = SMITHING_MODE_REFINEMENT

-- Rewards Refactor
EVENT_CLAIM_LEVEL_UP_REWARD_RESULT = EVENT_CLAIM_REWARD_RESULT

-- Collectible entitlement restrictions are now handled on the acquisition end only
function DoesCollectibleRequireEntitlement(collectibleId)
    return false
end

-- Crafting animation bugfix. Please also consider ZO_CraftingUtils_IsPerformingCraftProcess()
IsPerformingCraftProcess = IsAwaitingCraftingProcessResponse

--Collectible hide mode rework
function IsCollectibleHiddenWhenLockedDynamic(collectibleId)
    return GetCollectibleHideMode(collectibleId) == COLLECTIBLE_HIDE_MODE_WHEN_LOCKED_REQUIREMENT
end

function IsCollectibleHiddenWhenLocked(collectibleId)
    if IsCollectibleHiddenWhenLockedDynamic(collectibleId) then
        return IsCollectibleDynamicallyHidden(collectibleId)
    else
        return GetCollectibleHideMode(collectibleId) == COLLECTIBLE_HIDE_MODE_WHEN_LOCKED
    end
end

--Added Tracking Level Map Pin Function

function SetMapQuestPinsAssisted(questIndex, assisted)
    SetMapQuestPinsTrackingLevel(questIndex, assisted and TRACKING_LEVEL_ASSISTED or TRACKING_LEVEL_UNTRACKED)
end

-- LFG now only supports single role selection

do
    local function RoleToRoles(role)
        local isDPS = false
        local isHealer = false
        local isTank = false

        if role == LFG_ROLE_DPS then
            isDPS = true
        elseif role == LFG_ROLE_HEAL then
            isHealer = true
        elseif role == LFG_ROLE_TANK then
            isTank = true
        end

        return isDPS, isHealer, isTank
    end

    function GetGroupMemberRoles(unitTag)
        local role = GetGroupMemberSelectedRole(unitTag)
        return RoleToRoles(role)
    end

    function GetPlayerRoles()
        local role = GetSelectedLFGRole()
        return RoleToRoles(role)
    end
end

GetGroupMemberAssignedRole = GetGroupMemberSelectedRole

function DoAllGroupMembersHavePreferredRole()
    return true
end

function UpdatePlayerRole(role, selected)
    if selected then
        UpdateSelectedLFGRole(role)
    end
end

--Skills refactor
SelectSlotSkillAbility = SlotSkillAbilityInSlot

function ZO_Skills_GetIconsForSkillType(skillType)
    local skillTypeData = SKILLS_DATA_MANAGER:GetSkillTypeData(skillType)
    if skillTypeData then
        local normal, pressed, mouseOver = skillTypeData:GetKeyboardIcons()
        local announce = skillTypeData:GetAnnounceIcon()
        return pressed, normal, mouseOver, announce
    end
end

function ZO_Skills_GenerateAbilityName(stringIndex, name, currentUpgradeLevel, maxUpgradeLevel, progressionIndex)
    if currentUpgradeLevel and maxUpgradeLevel then
        return zo_strformat(stringIndex, name, currentUpgradeLevel, maxUpgradeLevel) 
    elseif progressionIndex then
        local _, _, rank = GetAbilityProgressionInfo(progressionIndex)
        if rank > 0 then
            return zo_strformat(SI_ABILITY_NAME_AND_RANK, name, rank)
        end
    end

    return zo_strformat(SI_SKILLS_ENTRY_NAME_FORMAT, name)
end

function ZO_Skills_PurchaseAbility(skillType, skillLineIndex, skillIndex)
    local skillData = SKILLS_DATA_MANAGER:GetSkillDataByIndices(skillType, skillLineIndex, skillIndex)
    if skillData then
        skillData:GetPointAllocator():Purchase()
    end
end

function ZO_Skills_UpgradeAbility(skillType, skillLineIndex, skillIndex)
    local skillData = SKILLS_DATA_MANAGER:GetSkillDataByIndices(skillType, skillLineIndex, skillIndex)
    if skillData then
        skillData:GetPointAllocator():IncreaseRank()
    end
end

function ZO_Skills_MorphAbility(progressionIndex, morphSlot)
    local skillType, skillLineIndex, skillIndex = GetSkillAbilityIndicesFromProgressionIndex(progressionIndex)
    local skillData = SKILLS_DATA_MANAGER:GetSkillDataByIndices(skillType, skillLineIndex, skillIndex)
    if skillData then
        skillData:GetPointAllocator():Morph(morphSlot)
    end
end

function ZO_Skills_AbilityFailsWerewolfRequirement(skillType, skillLineIndex)
    local skillLineData = SKILLS_DATA_MANAGER:GetSkillLineDataByIndices(skillType, skillLineIndex)
    return IsWerewolf() and not skillLineData:IsWerewolf()
end

function ZO_Skills_OnlyWerewolfAbilitiesAllowedAlert()
    ZO_AlertEvent(EVENT_HOT_BAR_RESULT, HOT_BAR_RESULT_CANNOT_USE_WHILE_WEREWOLF)
end

EVENT_SKILL_ABILITY_PROGRESSIONS_UPDATED = EVENT_SKILLS_FULL_UPDATE

function GetSkillLineInfo(skillType, skillLineIndex)
    local skillLineData = SKILLS_DATA_MANAGER:GetSkillLineDataByIndices(skillType, skillLineIndex)
    if skillLineData then
        return skillLineData:GetName(), skillLineData:GetCurrentRank(), skillLineData:IsAvailable(), skillLineData:GetId(), skillLineData:IsAdvised(), skillLineData:GetUnlockText(), skillLineData:IsActive(), skillLineData:IsDiscovered()
    end
    return "", 1, false, 0, false, "", false, false
end

-- Campaign Bonus Ability Refactor
function GetArtifactScoreBonusInfo(alliance, artifactType, index)
    local abilityId = GetArtifactScoreBonusAbilityId(alliance, artifactType, index)
    local name = GetAbilityName(abilityId)
    local icon = GetAbilityIcon(abilityId)
    local description = GetAbilityDescription(abilityId)
    return name, icon, description
end

function GetEmperorAllianceBonusInfo(campaignId, alliance)
    local abilityId = GetEmperorAllianceBonusAbilityId(campaignId, alliance)
    local name = GetAbilityName(abilityId)
    local icon = GetAbilityIcon(abilityId)
    local description = GetAbilityDescription(abilityId)
    return name, icon, description
end

function GetKeepScoreBonusInfo(index)
    local abilityId = GetKeepScoreBonusAbilityId(index)
    local name = GetAbilityName(abilityId)
    local icon = GetAbilityIcon(abilityId)
    local description = GetAbilityDescription(abilityId)
    return name, icon, description
end


-- Action slots refactor
EVENT_ACTION_SLOTS_FULL_UPDATE = EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED
EVENT_ACTION_BAR_SLOTTING_ALLOWED_STATE_CHANGED = EVENT_ACTION_BAR_IS_RESPECCABLE_BAR_STATE_CHANGED
IsActionBarSlottingAllowed = IsActionBarRespeccable

function GetItemCurrentActionBarSlot(bagId, slotIndex)
    return FindActionSlotMatchingItem(bagId, slotIndex)
end

function GetCollectibleCurrentActionBarSlot(collectibleId)
    return FindActionSlotMatchingSimpleAction(ACTION_TYPE_COLLECTIBLE, collectibleId)
end

function GetFirstFreeValidSlotForCollectible(collectibleId)
    return GetFirstFreeValidSlotForSimpleAction(ACTION_TYPE_COLLECTIBLE, collectibleId)
end

-- You can now weapon swap to unarmed, so this function no longer means anything to the UI
function HasActivatableSwapWeaponsEquipped()
    return true
end

-- rename rankIndex -> rank: ranks are from 1-4, and not array indices
GetSkillLineProgressionAbilityRankIndex = GetSkillLineProgressionAbilityRank
GetUpgradeSkillHighestRankIndexAvailableAtSkillLineRank = GetUpgradeSkillHighestRankAvailableAtSkillLineRank


-- removed placeholder collectibles
function ZO_CollectibleData:IsPlaceholder()
    return false
end

-- Renamed to better reflect behavior: the output isn't localized, it's delimited.
ZO_LocalizeDecimalNumber = ZO_CommaDelimitDecimalNumber

-- Removed alliance war guest campaigns. You can now join any campaign, so no need to guest anywhere.
function GetGuestCampaignId()
    return 0
end

function GetCampaignGuestCooldown()
    return 0
end

function SwitchGuestCampaign(campaignId)
    -- do nothing
end

GetAllianceBannerIcon = GetAllianceSymbolIcon

-- GetCraftingSkillLineIndices removed
function GetCraftingSkillLineIndices(tradeskillType)
    local skillLineData = SKILLS_DATA_MANAGER:GetCraftingSkillLineData(tradeskillType)
    if skillLineData then
        return skillLineData:GetIndices()
    end
    return 0, 0
end

-- Deconstruction now supports multiple items per deconstruct
function ExtractOrRefineSmithingItem(bagId, slotIndex)
    local isRefine = CanItemBeRefined(bagId, slotIndex, GetCraftingInteractionType())
    PrepareDeconstructMessage()
    local quantity = isRefine and GetRequiredSmithingRefinementStackSize() or 1
    if AddItemToDeconstructMessage(bagId, slotIndex, quantity) then
        SendDeconstructMessage()
    end
end

function ExtractEnchantingItem(bagId, slotIndex)
    PrepareDeconstructMessage()
    if AddItemToDeconstructMessage(bagId, slotIndex, 1) then
        SendDeconstructMessage()
    end
end

function CanItemBeSmithingExtractedOrRefined(bagId, slotIndex, craftingType)
    return CanItemBeRefined(bagId, slotIndex, craftingType) or CanItemBeDeconstructed(bagId, slotIndex, craftingType)
end

-- The only information you need to determine if a trait is known is the pattern
function IsSmithingTraitKnownForResult(patternIndex, materialIndex, materialQuantity, styleId, traitIndex)
    local traitType = traitIndex - 1 -- traitIndex is just the trait type offset by one so it behaves like a lua index, let's just manually convert
    return IsSmithingTraitKnownForPattern(patternIndex, traitType)
end
