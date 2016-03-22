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

--Raid function rename
GetRaidReviveCounterInfo = GetRaidReviveCountersRemaining

--ItemStoleType is now OwnershipStatus
ITEM_STOLEN_TYPE_ANY = OWNERSHIP_STATUS_ANY
ITEM_STOLEN_TYPE_NOT_STOLEN = OWNERSHIP_STATUS_NOT_STOLEN
ITEM_STOLEN_TYPE_STOLEN = OWNERSHIP_STATUS_STOLEN