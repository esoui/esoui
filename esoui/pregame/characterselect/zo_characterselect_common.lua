
local PRIORITY_DEFAULT = 1
local PRIORITY_MOST_RECENT_CHARACTER = 2
local PRIORITY_PLAYER_CHOSEN = 3

local g_characterDataList = {}
local g_bestSelectionData = nil
local g_bestSelectionIndex = nil
local g_accountChampionPoints = 0
local g_playerSelectedCharacterId

function ZO_CharacterSelect_GetCharacterDataList()
    return g_characterDataList
end

function ZO_CharacterSelect_GetDataForCharacterId(charId)
    for _, dataEntry in ipairs(g_characterDataList) do
        if(AreId64sEqual(dataEntry.id, charId)) then
            return dataEntry
        end
    end
end

do
    local iconString = IsInGamepadPreferredMode() and "EsoUI/Art/Champion/Gamepad/gp_champion_icon.dds" or "EsoUI/Art/Champion/champion_icon.dds"
    local CHAMPION_FORMATTED_ICON = zo_iconFormat(iconString, "100%", "100%")

    function ZO_CharacterSelect_GetFormattedLevel(characterData)
        if characterData.championPoints and characterData.championPoints > 0 then
            return zo_strformat(SI_CHARACTER_SELECT_LEVEL_CHAMPION, characterData.level, CHAMPION_FORMATTED_ICON)
        else
            return zo_strformat(SI_CHARACTER_SELECT_LEVEL_VALUE, characterData.level)
        end
    end

    function ZO_CharacterSelect_GetFormattedLevelChampionAndClass(characterData)
        local className = characterData.class and GetClassName(characterData.gender, characterData.class) or GetString(SI_UNKNOWN_CLASS)
        if characterData.championPoints and characterData.championPoints > 0 then
            return zo_strformat(SI_CHARACTER_SELECT_LEVEL_CHAMPION_CLASS, characterData.level, CHAMPION_FORMATTED_ICON, className)
        else
            return zo_strformat(SI_CHARACTER_SELECT_LEVEL_CLASS, characterData.level, className)
        end
    end
end

function ZO_CharacterSelect_GetFormattedCharacterName(characterData)
    return zo_strformat(SI_CHARACTER_SELECT_NAME, characterData.name)
end

function ZO_CharacterSelect_GetFormattedLevelChampion(characterData)
    if characterData.championPoints and characterData.championPoints > 0 then
        return zo_strformat(SI_CHARACTER_SELECT_CHAMPION_CLASS, characterData.championPoints, '')
    else
        return zo_strformat(SI_CHARACTER_SELECT_LEVEL_CLASS, characterData.level, '')
    end
end

function ZO_CharacterSelect_GetFormattedRaceClassAndLocation(characterData)
    local raceName = characterData.race and GetRaceName(characterData.gender, characterData.race) or GetString(SI_UNKNOWN_RACE)
    local className = characterData.class and GetClassName(characterData.gender, characterData.class) or GetString(SI_UNKNOWN_CLASS)
    local locationName = characterData.location ~= 0 and GetLocationName(characterData.location) or GetString(SI_UNKNOWN_LOCATION)

    return zo_strformat(SI_CHARACTER_SELECT_RACE_CLASS_LOCATION, raceName, className, locationName)
end

function ZO_CharacterSelect_GetBestSelectionData()
    return g_bestSelectionData
end

function ZO_CharacterSelect_GetBestSelectionIndex()
    return g_bestSelectionIndex
end

function ZO_CharacterSelect_GetAccountChampionPoints()
    return g_accountChampionPoints
end

function ZO_CharacterSelect_SetPlayerSelectedCharacterId(id)
    g_playerSelectedCharacterId = id
end

do
    local g_bestSelectionPriority = 0
    local g_mostRecentCharId

    local function AddCharacter(i)
        local name, gender, level, championPoints, class, race, alliance, id, locationId, needsRename = GetCharacterInfo(i)

        -- if one character has champion points, than the account has champion points
        -- also make sure that the account never loses champion points between characters
        if championPoints > 0  and g_accountChampionPoints < championPoints then
            g_accountChampionPoints = championPoints
        end

        -- Because of the way the messaging works, ensure this character doesn't already exist in the table.
        local characterData = ZO_CharacterSelect_GetDataForCharacterId(id)
        if(characterData == nil) then
            characterData = { name = name, gender = gender, level = level, championPoints = championPoints, class = class, race = race, alliance = alliance, id = id, location = locationId, needsRename = needsRename, index = #g_characterDataList + 1 }
            table.insert(g_characterDataList, characterData)

            if(g_bestSelectionPriority < PRIORITY_DEFAULT) then
                g_bestSelectionPriority = PRIORITY_DEFAULT
                g_bestSelectionData = characterData
                g_bestSelectionIndex = i
            end

            if(AreId64sEqual(g_playerSelectedCharacterId, id)) then
                g_bestSelectionPriority = PRIORITY_PLAYER_CHOSEN
                g_bestSelectionData = characterData
                g_bestSelectionIndex = i
            end

            if(AreId64sEqual(g_mostRecentCharId, id)) then
                if(g_bestSelectionPriority < PRIORITY_MOST_RECENT_CHARACTER) then
                    g_bestSelectionPriority = PRIORITY_MOST_RECENT_CHARACTER
                    g_bestSelectionData = characterData
                    g_bestSelectionIndex = i
                end
            end
        end
    end

    function ZO_CharacterSelect_OnCharacterListReceivedCommon(eventCode, numCharacters, maxCharacters, mostRecentlyPlayedCharacterId, numCharacterDeletesRemaining, maxCharacterDeletes)
        g_mostRecentCharId = mostRecentlyPlayedCharacterId
        g_bestSelectionPriority = 0
        g_accountChampionPoints = 0
        g_bestSelectionData = nil

        g_characterDataList = {}
    
        if(numCharacters > 0) then
            for i = 1, numCharacters do
                AddCharacter(i)
            end
        end
    end
end

function ZO_CharacterSelect_ClearDefVersionInfo()
    defVersionInfo = ""
end

function ZO_CharacterSelect_CanShowAdditionalSlotsInfo()
    local currentUsedSlots = GetNumCharacters()
    local ownedCharacterSlots = GetNumOwnedCharacterSlots()

    return ownedCharacterSlots <= currentUsedSlots and ZO_CharacterSelect_GetAdditionalSlotsRemaining() > 0
end

function ZO_CharacterSelect_GetAdditionalSlotsRemaining()
    local ownedCharacterSlots = GetNumOwnedCharacterSlots()
    local maxSlotsAvailable = GetNumMaxCharacterSlotsAvailable()

    return maxSlotsAvailable - ownedCharacterSlots
end

function ZO_CharacterSelect_OnCharacterRenamedCommon(eventCode, characterId, result, requestedName, successCallback, errorCallback)
    ZO_Dialogs_ReleaseAllDialogsOfName("CHARACTER_SELECT_CHARACTER_RENAMING")

    if result == NAME_RULE_NO_ERROR then
        ZO_Dialogs_ShowPlatformDialog("CHARACTER_SELECT_RENAME_CHARACTER_SUCCESS", { callback = successCallback }, { mainTextParams = {requestedName}})
    else
        local titleText
        local errorMessageText

        if result == NAME_RULE_DUPLICATE_NAME then
            titleText = SI_RENAME_CHARACTER_NAME_IN_USE_ERROR_HEADER
            errorMessageText = zo_strformat(SI_RENAME_CHARACTER_NAME_IN_USE_ERROR_BODY, requestedName)
        else
            titleText = SI_RENAME_CHARACTER_GENERIC_ERROR_HEADER
            errorMessageText = GetString("SI_NAMINGERROR", result)
        end

        local dialogParams = {
            titleParams = { GetString(titleText) },
            mainTextParams = { errorMessageText },
        }

        ZO_Dialogs_ShowPlatformDialog("CHARACTER_SELECT_RENAME_CHARACTER_ERROR", { callback = errorCallback }, dialogParams)
    end
end

function ZO_CharacterSelect_SetChromaColorForCharacterIndex(index)
    if ZO_RZCHROMA_EFFECTS then
        local characterData = g_characterDataList[index]
        ZO_RZCHROMA_EFFECTS:SetAlliance(characterData.alliance)
    end
end