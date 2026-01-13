----------------------------------------
-- Tamriel Tomes Reward Tile Keyboard --
----------------------------------------

ZO_TamrielTomes_RewardTile_Keyboard = ZO_Object.MultiSubclass(ZO_Tile_Keyboard, ZO_TamrielTomes_RewardTile_Shared)

function ZO_TamrielTomes_RewardTile_Keyboard:New(...)
    return ZO_TamrielTomes_RewardTile_Shared.New(self, ...)
end

function ZO_TamrielTomes_RewardTile_Keyboard:Initialize(control)
    ZO_TamrielTomes_RewardTile_Shared.Initialize(self, control)
end

function ZO_TamrielTomes_RewardTile_Keyboard.OnControlInitialized(control)
    ZO_TamrielTomes_RewardTile_Keyboard:New(control)
end

-----------------------------------
-- Tamriel Tomes Reward Keyboard --
-----------------------------------

ZO_TamrielTomesReward_Keyboard = ZO_TamrielTomesReward_Shared:Subclass()

function ZO_TamrielTomesReward_Keyboard:Initialize(control)
    ZO_TamrielTomesReward_Shared.Initialize(self, control)

    self.currencyOptions = ZO_KEYBOARD_CURRENCY_OPTIONS
    control.icon = self.iconTexture
end

function ZO_TamrielTomesReward_Keyboard:ClaimReward()
    local tamrielTomesRewardData = self:GetTamrielTomesRewardData()
    if tamrielTomesRewardData:CanClaimReward() then
        local rewardId = self:GetRewardData():GetRewardId()
        if GetRewardType(rewardId) == REWARD_ENTRY_TYPE_CHOICE then
            local CLAIM_ONE = false
            TAMRIEL_TOMES_SCREEN_KEYBOARD:ShowClaimChoiceDialog(tamrielTomesRewardData, CLAIM_ONE)
        else
            tamrielTomesRewardData:TryClaimReward()
        end
    end
end

function ZO_TamrielTomesReward_Keyboard:OnMouseEnter()
    ZO_Rewards_Shared_OnMouseEnter(self.control, RIGHT, LEFT, -5)
    ZO_GridEntry_SetIconScaledUp(self.control, true)
    local rewardData = self:GetTamrielTomesRewardData()
    TAMRIEL_TOMES_SCREEN_KEYBOARD:SetSelectedTamrielTomesRewardData(rewardData)

    if rewardData and rewardData:CanPreviewReward() then
        WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_PREVIEW)
    end
end

function ZO_TamrielTomesReward_Keyboard:OnMouseExit()
    ZO_Rewards_Shared_OnMouseExit(self.control)
    ZO_GridEntry_SetIconScaledUp(self.control, false)
    TAMRIEL_TOMES_SCREEN_KEYBOARD:SetSelectedTamrielTomesRewardData(nil)
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
end

function ZO_TamrielTomesReward_Keyboard:OnMouseUp(button, upInside)
    if not (upInside and button == MOUSE_BUTTON_INDEX_LEFT and self:HasRewardData()) then
        return
    end

    local rewardId = self:GetRewardData():GetRewardId()
    if CanPreviewReward(rewardId) or GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST then
        local tamrielTomesRewardData = self:GetTamrielTomesRewardData()
        TAMRIEL_TOMES_SCREEN_KEYBOARD:BeginPreview(ZO_TAMRIEL_TOMES_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW, tamrielTomesRewardData)
    end
end

function ZO_TamrielTomesReward_Keyboard.OnControlInitialized(control)
    ZO_TamrielTomesReward_Keyboard:New(control)
end