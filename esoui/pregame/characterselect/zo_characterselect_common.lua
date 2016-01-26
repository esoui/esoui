
local PRIORITY_DEFAULT = 1
local PRIORITY_MOST_RECENT_CHARACTER = 2
local PRIORITY_PLAYER_CHOSEN = 3

local g_characterDataList = {}
local g_bestSelectionData = nil
local g_bestSelectionIndex = nil
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

function ZO_CharacterSelect_GetFormattedLevel(characterData)
    if characterData.veteranRank and characterData.veteranRank > 0 then
        return zo_strformat(SI_CHARACTER_SELECT_VETERAN_RANK_VALUE, characterData.veteranRank)
    else
        return zo_strformat(SI_CHARACTER_SELECT_LEVEL_VALUE, characterData.level)
    end
end

function ZO_CharacterSelect_GetFormattedLevelRankAndClass(characterData)
    local className = characterData.class and GetClassName(characterData.gender, characterData.class) or GetString(SI_UNKNOWN_CLASS)
    
    if characterData.veteranRank and characterData.veteranRank > 0 then
        return zo_strformat(SI_CHARACTER_SELECT_VETERAN_RANK_CLASS, characterData.veteranRank, className)
    else
        return zo_strformat(SI_CHARACTER_SELECT_LEVEL_CLASS, characterData.level, className)
    end
end

function ZO_CharacterSelect_GetFormattedLevelRank(characterData)
    if characterData.veteranRank and characterData.veteranRank > 0 then
        return zo_strformat(SI_CHARACTER_SELECT_VETERAN_RANK_CLASS, characterData.veteranRank, '')
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

function ZO_CharacterSelect_SetPlayerSelectedCharacterId(id)
    g_playerSelectedCharacterId = id
end

do
    local g_bestSelectionPriority = 0
    local g_mostRecentCharId

    local function AddCharacter(i)
        local name, gender, level, veteranRank, class, race, alliance, id, locationId, needsRename = GetCharacterInfo(i)

        -- Because of the way the messaging works, ensure this character doesn't already exist in the table.
        local characterData = ZO_CharacterSelect_GetDataForCharacterId(id)
        if(characterData == nil) then
            characterData = { name = name, gender = gender, level = level, veteranRank = veteranRank, class = class, race = race, alliance = alliance, id = id, location = locationId, needsRename = needsRename, index = #g_characterDataList + 1 }
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