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

function ZO_TamrielTomesReward_Keyboard:OnMouseEnter()
    ZO_GridEntry_SetIconScaledUp(self.control, true)
    local rewardData = self:GetTamrielTomesRewardData()
    TAMRIEL_TOMES_SCREEN_KEYBOARD:SetSelectedTamrielTomesRewardData(rewardData)
    ZO_Rewards_Shared_OnMouseEnter(self.control, BOTTOM, TOP, 0, -5)
end

function ZO_TamrielTomesReward_Keyboard:OnMouseExit()
    ZO_Rewards_Shared_OnMouseExit(self.control)
    ZO_GridEntry_SetIconScaledUp(self.control, false)
    TAMRIEL_TOMES_SCREEN_KEYBOARD:SetSelectedTamrielTomesRewardData(nil)
end

function ZO_TamrielTomesReward_Keyboard:OnMouseDown(button)
    if button == MOUSE_BUTTON_INDEX_LEFT and self:HasRewardData() then
        local rewardData = self:GetTamrielTomesRewardData()
        if rewardData:CanAffordReward() and rewardData:CanClaimReward() then
            TAMRIEL_TOMES_SCREEN_KEYBOARD:SetSelectedTamrielTomesRewardData(rewardData)
            TAMRIEL_TOMES_SCREEN_KEYBOARD:BeginClaimReward(rewardData)
        end
    end
end

function ZO_TamrielTomesReward_Keyboard:OnMouseUp(button, upInside)
    if button == MOUSE_BUTTON_INDEX_LEFT and self:HasRewardData() then
        local rewardData = self:GetTamrielTomesRewardData()
        TAMRIEL_TOMES_SCREEN_KEYBOARD:EndClaimReward(rewardData)
    end
end

function ZO_TamrielTomesReward_Keyboard:UpdateClaimRewardProgressInternal()
    ZO_TamrielTomesReward_Shared.UpdateClaimRewardProgressInternal(self)

    TAMRIEL_TOMES_SCREEN_KEYBOARD:UpdateKeybinds()
end

function ZO_TamrielTomesReward_Keyboard.OnControlInitialized(control)
    ZO_TamrielTomesReward_Keyboard:New(control)
end