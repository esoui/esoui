ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_WIDTH = 136
ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_HEIGHT = 158
ZO_TAMRIEL_TOMES_REWARD_TILE_X_MARGIN = 8
ZO_TAMRIEL_TOMES_REWARD_TILE_Y_MARGIN = 0
ZO_TAMRIEL_TOMES_REWARD_TILE_HEIGHT = ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_HEIGHT + ZO_TAMRIEL_TOMES_REWARD_TILE_Y_MARGIN
ZO_TAMRIEL_TOMES_REWARD_TILE_1_X_WIDTH = ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_WIDTH + ZO_TAMRIEL_TOMES_REWARD_TILE_X_MARGIN
ZO_TAMRIEL_TOMES_REWARD_TILE_2_X_WIDTH = ZO_TAMRIEL_TOMES_REWARD_TILE_1_X_WIDTH * 2
ZO_TAMRIEL_TOMES_REWARD_TILE_2_5_X_WIDTH = ZO_TAMRIEL_TOMES_REWARD_TILE_1_X_WIDTH * 2.5

ZO_TAMRIEL_TOMES_REWARD_DIVIDER_WIDTH = ZO_TAMRIEL_TOMES_REWARD_TILE_1_X_WIDTH * 5
ZO_TAMRIEL_TOMES_REWARD_DIVIDER_HEIGHT = 50

-------------------------------
-- Tamriel Tomes Reward Tile --
-------------------------------

ZO_TamrielTomes_RewardTile_Shared = ZO_Tile:Subclass()

function ZO_TamrielTomes_RewardTile_Shared:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_TamrielTomes_RewardTile_Shared:Initialize(control)
    ZO_Tile.Initialize(self, control)

    self.rewardControl = control:GetNamedChild("Reward")
end

function ZO_TamrielTomes_RewardTile_Shared:Layout(data)
    ZO_Tile.Layout(self, data)

    self.rewardData = data
    self.rewardControl.object:SetTamrielTomesRewardData(data)
end

function ZO_TamrielTomes_RewardTile_Shared:GetReward()
    return self.rewardControl.object
end

function ZO_TamrielTomes_RewardTile_Shared:GetRewardControl()
    return self.rewardControl
end

--------------------------
-- Tamriel Tomes Reward --
--------------------------

ZO_TamrielTomesReward_Shared = ZO_InitializingObject:Subclass()

function ZO_TamrielTomesReward_Shared:Initialize(control)
    self.control = control
    control.object = self

    self.rarityBorderTexture = control:GetNamedChild("RarityBorder")
    self.costLabel = control:GetNamedChild("Cost")
    self.iconTexture = control:GetNamedChild("Icon")
    self.lockedTexture = control:GetNamedChild("Locked")
    self.quantityLabel = control:GetNamedChild("Quantity")

    self.isSelected = false

    -- Required by ZO_Rewards_Shared_OnMouseEnter
    self.control.GetRewardData = function()
        return self:GetRewardData()
    end
end

function ZO_TamrielTomesReward_Shared:SetHidden(hidden)
    self.control:SetHidden(hidden)
end

function ZO_TamrielTomesReward_Shared:CanPreviewReward()
    local tamrielTomesRewardData = self:GetTamrielTomesRewardData()
    return tamrielTomesRewardData:CanPreviewReward()
end

function ZO_TamrielTomesReward_Shared:GetRewardData()
    if self.tamrielTomesRewardData then
        return self.tamrielTomesRewardData:GetRewardData()
    end

    return nil
end

function ZO_TamrielTomesReward_Shared:HasRewardData()
    return self:GetRewardData() ~= nil
end

function ZO_TamrielTomesReward_Shared:GetTamrielTomesRewardData()
    return self.tamrielTomesRewardData
end

function ZO_TamrielTomesReward_Shared:SetTamrielTomesRewardData(tamrielTomesRewardData)
    self.tamrielTomesRewardData = tamrielTomesRewardData

    self:Refresh()
end

function ZO_TamrielTomesReward_Shared:Refresh()
    if not self:HasRewardData() then
        self:SetHidden(true)
        return
    end

    local tamrielTomesRewardData = self:GetTamrielTomesRewardData()
    self.quantityLabel:SetText(ZO_CommaDelimitNumber(tamrielTomesRewardData.rewardQuantity))
    ZO_CurrencyControl_SetSimpleCurrency(self.costLabel, CURT_TOME_POINTS, tamrielTomesRewardData.rewardCost, self.currencyOptions)

    local rewardData = self:GetRewardData()
    local iconTextureFile = rewardData:GetPlatformIcon()
    self.iconTexture:SetTexture(iconTextureFile)

    self:RefreshState()
    self:SetHidden(false)
end

function ZO_TamrielTomesReward_Shared:RefreshState()
    local tamrielTomesRewardData = self:GetTamrielTomesRewardData()
    if not tamrielTomesRewardData then
        return
    end

    local isLocked = self:IsLocked()
    self.lockedTexture:SetHidden(not isLocked)

    if isLocked then
        self.iconTexture:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGBA())
    else
        self.iconTexture:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
    end

    if tamrielTomesRewardData:GetHideRewardQuality() then
        self.rarityBorderTexture:SetHidden(true)
    else
        local displayQuality = tamrielTomesRewardData:GetRewardDisplayQuality()
        local borderColor = ZO_WHITE
        if isLocked then
            if self:IsSelected() then
                borderColor = GetItemQualityColor(displayQuality)
            else
                borderColor = GetDimItemQualityColor(displayQuality)
            end
        elseif self:IsSelected() or tamrielTomesRewardData:IsRewardClaimed() or not tamrielTomesRewardData:CanClaimReward() then
            borderColor = GetBrightItemQualityColor(displayQuality)
        else
            borderColor = GetItemQualityColor(displayQuality)
        end

        local r, g, b = borderColor:UnpackRGB()
        local BORDER_ALPHA = 0.65
        self.rarityBorderTexture:SetColor(r, g, b, BORDER_ALPHA)
        self.rarityBorderTexture:SetHidden(false)
    end
end

function ZO_TamrielTomesReward_Shared:IsLocked()
    return self:GetTamrielTomesRewardData():IsLocked()
end

function ZO_TamrielTomesReward_Shared:IsPreviewing()
    return self.isPreviewing
end

function ZO_TamrielTomesReward_Shared:SetPreviewing(isPreviewing)
    self.isPreviewing = isPreviewing
    self:RefreshState()
end

function ZO_TamrielTomesReward_Shared:IsSelected()
    return self.isSelected
end

function ZO_TamrielTomesReward_Shared:SetSelected(isSelected)
    self.isSelected = isSelected
    self:RefreshState()
end