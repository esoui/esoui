ZO_RUMOR_REWARDS_DIALOG_KEYBOARD_ROW_HEIGHT = 52

local REWARDS_LIST_DATA_TYPE = 1

-- min and max height for the reward list include a bit of padding to avoid the scroll bar appearing unnecessarily
local REWARD_LIST_MIN_HEIGHT = ZO_RUMOR_REWARDS_DIALOG_KEYBOARD_ROW_HEIGHT * 2 + 5
local REWARD_LIST_MAX_HEIGHT = ZO_RUMOR_REWARDS_DIALOG_KEYBOARD_ROW_HEIGHT * 5 + 5

ZO_RumorRewardsDialog_Keyboard = ZO_InitializingObject:Subclass()

function ZO_RumorRewardsDialog_Keyboard:Initialize(control)
    self.control = control
    control.object = self
    self.currentSelectedChoice = nil

    self.list = control:GetNamedChild("List")
    self.confirmButton = control:GetNamedChild("ConfirmButton")
    self.closeButton = control:GetNamedChild("CloseButton")

    ZO_ScrollList_AddDataType(self.list, REWARDS_LIST_DATA_TYPE, "ZO_RumorRewards_Keyboard_RewardRow", ZO_RUMOR_REWARDS_DIALOG_KEYBOARD_ROW_HEIGHT, function(control, data) self:SetupRewardEntry(control, data) end)

    ZO_Dialogs_RegisterCustomDialog("RUMOR_REWARDS_CLAIM_KEYBOARD",
    {
        customControl = control,

        setup = function(dialog, data)
            local rumorEnding = data.rumorEnding
            self:SetRewardData(rumorEnding)
        end,

        canQueue = true,

        title =
        {
            text = function(dialog)
                local rumorName = GetRumorDisplayName(dialog.data.rumorId)
                return zo_strformat(SI_RUMOR_CLAIM_REWARDS_TITLE, rumorName)
            end,
        },

        buttons =
        {
            {
                control = self.confirmButton,
                text = SI_RUMOR_CLAIM_REWARDS_CLAIM_ACTION,
                keybind = "DIALOG_PRIMARY",
                callback = function(dialog)
                    RequestCompletePendingRumor(dialog.data.rumorEnding)
                end,
            },
            {
                control = self.closeButton,
                text = SI_DIALOG_CANCEL,
                keybind = "DIALOG_NEGATIVE",
            },
        },
    })
end

function ZO_RumorRewardsDialog_Keyboard:SetupRewardEntry(control, data)
    control.data = data

    local nameControl = control:GetNamedChild("Name")
    nameControl:SetText(data.formattedName)

    if data.currencyType and data.currencyType ~= CURT_NONE then
        nameControl:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
    else
        if data.rewardType == REWARD_ENTRY_TYPE_COLLECTIBLE then
            nameControl:SetColor(ZO_WHITE:UnpackRGBA())
        elseif data.displayQuality then
            nameControl:SetColor(GetItemQualityColor(data.displayQuality):UnpackRGBA())
        end
    end

    control.icon = control:GetNamedChild("Icon")
    local iconControl = control.icon
    if data.icon then
        iconControl:SetTexture(data.icon)
        iconControl:SetHidden(false)
    else
        iconControl:SetHidden(true)
    end

    local stackCount = data.quantity
    local stackCountLabel = iconControl:GetNamedChild("StackCount")
    if stackCount and stackCount > 1 then
        local USE_LOWERCASE_NUMBER_SUFFIXES = false
        stackCountLabel:SetText(ZO_AbbreviateAndLocalizeNumber(stackCount, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES))
    else
        stackCountLabel:SetText("")
    end

    control:SetHidden(false)
end

function ZO_RumorRewardsDialog_Keyboard:SetRewardData(rumorEnding)
    ZO_ScrollList_Clear(self.list)
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    local rewardId, quantity = GetRewardInfoForRumorEnding(rumorEnding)
    local entryType = GetRewardType(rewardId)
    if entryType == REWARD_ENTRY_TYPE_REWARD_LIST then
        local rewardListId = GetRewardListIdFromReward(rewardId)
        local rewardListEntries = REWARDS_MANAGER:GetAllRewardInfoForRewardList(rewardListId)
        for rewardListIndex, rewardData in ipairs(rewardListEntries) do
            local scrollEntryData = ZO_ScrollList_CreateDataEntry(REWARDS_LIST_DATA_TYPE, rewardData)
            table.insert(scrollData, scrollEntryData)
        end
    else
        local rewardData = REWARDS_MANAGER:GetInfoForReward(rewardId, quantity)
        local scrollEntryData = ZO_ScrollList_CreateDataEntry(REWARDS_LIST_DATA_TYPE, rewardData)
        table.insert(scrollData, scrollEntryData)
    end

    local numEntries = #scrollData
    local desiredHeight = numEntries * ZO_RUMOR_REWARDS_DIALOG_KEYBOARD_ROW_HEIGHT + 5
    local height = zo_clamp(desiredHeight, REWARD_LIST_MIN_HEIGHT, REWARD_LIST_MAX_HEIGHT)
    self.list:SetHeight(height)

    ZO_ScrollList_Commit(self.list)
end

function ZO_RumorRewardsDialog_Keyboard.OnDialogInitialized(control)
    RUMORS_REWARD_DIALOG_KEYBOARD = ZO_RumorRewardsDialog_Keyboard:New(control)
end

function ZO_RumorRewardsDialog_Keyboard.OnListMouseEnter(control)
    local rewardData = control.data
    if rewardData then
        local rewardType = rewardData:GetRewardType()
        if rewardType then
            ZO_Rewards_Shared_OnMouseEnter(control, RIGHT, LEFT, -5)
        end
    end
    ZO_InventorySlot_SetHighlightHidden(control, false)
end

function ZO_RumorRewardsDialog_Keyboard.OnListMouseExit(control)
    ZO_Rewards_Shared_OnMouseExit(control)
    ZO_InventorySlot_SetHighlightHidden(control, true)
end
