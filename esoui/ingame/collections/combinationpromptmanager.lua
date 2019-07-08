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
