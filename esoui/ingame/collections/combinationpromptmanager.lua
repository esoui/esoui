function ZO_CombinationPromptManager_ShowEvolutionPrompt(baseCollectibleId, unlockedCollectibleId, acceptCallback, declineCallback)
    local baseCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(baseCollectibleId)
    local baseCollectibleName = ZO_WHITE:Colorize(baseCollectibleData:GetName())

    local unlockedCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(unlockedCollectibleId)
    local unlockedCollectibleName = ZO_WHITE:Colorize(unlockedCollectibleData:GetName())

    local dialogData =
    {
        baseCollectibleId = baseCollectibleId,
        evolvedCollectibleId = unlockedCollectibleId,
        acceptCallback = acceptCallback,
        declineCallback = declineCallback,
    }

    local textParams =
    {
        mainTextParams =
        {
            baseCollectibleName,
            unlockedCollectibleName
        },
    }

    if IsInGamepadPreferredMode() then
        ZO_Dialogs_ShowGamepadDialog("CONFIRM_COLLECTIBLE_EVOLUTION_PROMPT_GAMEPAD", dialogData, textParams)
    else
        ZO_Dialogs_ShowDialog("CONFIRM_COLLECTIBLE_EVOLUTION_PROMPT_KEYBOARD", dialogData, textParams)
    end
end

function ZO_CombinationPromptManager_ClearEvolutionPrompt()
    ZO_Dialogs_ReleaseDialog("CONFIRM_COLLECTIBLE_EVOLUTION_PROMPT_KEYBOARD")
    ZO_Dialogs_ReleaseDialog("CONFIRM_COLLECTIBLE_EVOLUTION_PROMPT_GAMEPAD")
end

function ZO_CombinationPromptManager_ShowAdvancedCombinationPrompt(combinationId, acceptCallback, declineCallback)
    local nonFragmentComponentCollectibleIds = { GetCombinationNonFragmentComponentCollectibleIds(combinationId) }
    local nonFragmentComponentCollectibleNames = {}
    for i, collectibleId in ipairs(nonFragmentComponentCollectibleIds) do
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData then
            local colorizedCollectibleName = ZO_WHITE:Colorize(collectibleData:GetName())
            table.insert(nonFragmentComponentCollectibleNames, colorizedCollectibleName)
        end
    end

    local numCollectibleUnlocks = GetCombinationNumUnlockedCollectibles(combinationId)
    local unlockedCollectibleNames = {}
    for i = 1, numCollectibleUnlocks do
        local collectibleId = GetCombinationUnlockedCollectibleId(combinationId, i)
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData then
            local colorizedCollectibleName = ZO_WHITE:Colorize(collectibleData:GetName())
            table.insert(unlockedCollectibleNames, colorizedCollectibleName)
        end
    end

    local componentNameList = ZO_GenerateCommaSeparatedListWithAnd(nonFragmentComponentCollectibleNames)
    local unlockNameList = ZO_GenerateCommaSeparatedListWithAnd(unlockedCollectibleNames)

    local dialogData =
    {
        combinationId = combinationId,
        acceptCallback = acceptCallback,
        declineCallback = declineCallback,
        componentNameList = componentNameList,
        unlockNameList = unlockNameList,
    }

    local textParams =
    {
        mainTextParams =
        {
            componentNameList,
            unlockNameList
        },
    }

    if IsInGamepadPreferredMode() then
        ZO_Dialogs_ShowGamepadDialog("CONFIRM_COLLECTIBLE_ADVANCED_COMBINATION_PROMPT_GAMEPAD", dialogData, textParams)
    else
        ZO_Dialogs_ShowDialog("CONFIRM_COLLECTIBLE_ADVANCED_COMBINATION_PROMPT_KEYBOARD", dialogData, textParams)
    end
end

function ZO_CombinationPromptManager_ClearAdvancedCombinationPrompt()
    ZO_Dialogs_ReleaseDialog("CONFIRM_COLLECTIBLE_ADVANCED_COMBINATION_PROMPT_GAMEPAD")
    ZO_Dialogs_ReleaseDialog("CONFIRM_COLLECTIBLE_ADVANCED_COMBINATION_PROMPT_KEYBOARD")
end

function ZO_CombinationPromptManager_ShowAppropriateCombinationPrompt(combinationId, acceptCallback, declineCallback)
    if GetCombinationNumNonFragmentCollectibleComponents(combinationId) == 1 and GetCombinationNumUnlockedCollectibles(combinationId) == 1 then
        local baseCollectibleId = GetCombinationNonFragmentComponentCollectibleIds(combinationId)
        local unlockedCollectibleId = GetCombinationUnlockedCollectibleId(combinationId, 1)
        ZO_CombinationPromptManager_ShowEvolutionPrompt(baseCollectibleId, unlockedCollectibleId, acceptCallback, declineCallback)
    else
        ZO_CombinationPromptManager_ShowAdvancedCombinationPrompt(combinationId, acceptCallback, declineCallback)
    end
end

function ZO_CombinationPromptManager_ClearAllCombinationPrompts()
    ZO_CombinationPromptManager_ClearEvolutionPrompt()
    ZO_CombinationPromptManager_ClearAdvancedCombinationPrompt()
end
