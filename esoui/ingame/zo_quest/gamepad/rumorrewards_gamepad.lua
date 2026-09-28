ZO_RumorRewardsDialog_Gamepad = ZO_InitializingObject:Subclass()

function ZO_RumorRewardsDialog_Gamepad:Initialize(control)
    ZO_Dialogs_RegisterCustomDialog("RUMOR_REWARDS_CLAIM_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowShowOnNextScene = true,
        },

        setup = function(dialog)
            local parametricListEntries = dialog.info.parametricList
            self:SetupParametricListEntries(parametricListEntries, dialog.data.rumorEnding)

            dialog:setupFunc()
        end,

        canQueue = true,

        title =
        {
            text = function(dialog)
                local rumorName = GetRumorDisplayName(dialog.data.rumorId)
                return zo_strformat(SI_RUMOR_CLAIM_REWARDS_TITLE, rumorName)
            end,
        },

        parametricList = {}, -- Generated Dynamically

        parametricListOnSelectionChangedCallback = function(dialog, list, newSelectedData, oldSelectedData)
            self:RefreshTooltips(dialog, newSelectedData)
        end,

        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_RUMOR_CLAIM_REWARDS_CLAIM_ACTION,
                callback = function(dialog)
                    RequestCompletePendingRumor(dialog.data.rumorEnding)
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        },
    })
end

function ZO_RumorRewardsDialog_Gamepad:CreateRumorEntry(rewardData)
    local name = rewardData:GetFormattedName()
    local icon = rewardData:GetGamepadLootIcon()
    local entryData = ZO_GamepadEntryData:New(name, icon)
    entryData:SetStackCount(rewardData:GetQuantity())
    entryData:SetNameColors(entryData:GetColorsBasedOnQuality(rewardData:GetItemDisplayQuality()))
    entryData:SetDataSource(rewardData)
    entryData.setup = ZO_SharedGamepadEntry_OnSetup
    entryData.narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP

    return entryData
end

function ZO_RumorRewardsDialog_Gamepad:SetupParametricListEntries(parametricListEntries, rumorEnding)
    ZO_ClearNumericallyIndexedTable(parametricListEntries)

    local rewardId, quantity = GetRewardInfoForRumorEnding(rumorEnding)
    local entryType = GetRewardType(rewardId)
    if entryType == REWARD_ENTRY_TYPE_REWARD_LIST then
        local rewardListId = GetRewardListIdFromReward(rewardId)
        local rewardListEntries = REWARDS_MANAGER:GetAllRewardInfoForRewardList(rewardListId)
        for rewardListIndex, rewardData in ipairs(rewardListEntries) do
            local entryData = self:CreateRumorEntry(rewardData)
            local listEntry =
            {
                template = "ZO_GamepadItemEntryTemplate",
                entryData = entryData,
            }

            table.insert(parametricListEntries, listEntry)
        end
    else
        local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, quantity)
        local entryData = self:CreateRumorEntry(rewardData)
        local listEntry =
        {
            template = "ZO_GamepadItemEntryTemplate",
            entryData = entryData,
        }

        table.insert(parametricListEntries, listEntry)
    end
end

function ZO_RumorRewardsDialog_Gamepad:RefreshTooltips(dialog, selectedData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    if not selectedData then
        ZO_GenericGamepadDialog_HideTooltip(dialog)
        return
    end

    local rewardType = selectedData:GetRewardType()
    if not rewardType then
        ZO_GenericGamepadDialog_HideTooltip(dialog)
        return
    end

    GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_LEFT_DIALOG_TOOLTIP, selectedData)
    ZO_GenericGamepadDialog_ShowTooltip(dialog)
end

RUMORS_REWARD_DIALOG_GAMEPAD = ZO_RumorRewardsDialog_Gamepad:New(control)
