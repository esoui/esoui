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

ZO_TAMRIEL_TOMES_REWARD_TOP_MARGIN_WIDTH = ZO_TAMRIEL_TOMES_REWARD_TILE_1_X_WIDTH * 5
ZO_TAMRIEL_TOMES_REWARD_TOP_MARGIN_HEIGHT = 16

local CLAIM_REWARD_COMPLETE_SECONDS = 0.65
local CLAIM_REWARD_INTERVAL_SECONDS = 1.2

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
    self.claimRewardOverlay = control:GetNamedChild("ClaimRewardOverlay")
    self.claimHighlightTexture = self.claimRewardOverlay:GetNamedChild("Highlight")
    self.claimOverlayTexture = self.claimRewardOverlay:GetNamedChild("Overlay")

    self.claimRewardEndTimeSeconds = nil
    self.claimRewardNormalizedProgress = 0
    self.claimRewardRequested = false
    self.isSelected = false

    -- Required by ZO_Rewards_Shared_OnMouseEnter
    self.control.GetRewardData = function()
        return self:GetRewardData()
    end
end

function ZO_TamrielTomesReward_Shared:BeginClaimReward()
    local tamrielTomesRewardData = self:GetTamrielTomesRewardData()
    if not (tamrielTomesRewardData and tamrielTomesRewardData:CanClaimReward() and tamrielTomesRewardData:CanAffordReward()) then
        return
    end

    self:SetClaimRewardProgress(0)
    self.claimRewardEndTimeSeconds = GetFrameTimeSeconds() + CLAIM_REWARD_INTERVAL_SECONDS
    self.claimRewardRequested = false
    self.control:SetHandler("OnUpdate", function(_, currentFrameTimeSeconds)
        self:UpdateClaimRewardProgress(currentFrameTimeSeconds)
    end)
end

function ZO_TamrielTomesReward_Shared:EndClaimReward(force)
    local claimingTimeElapsedSeconds = self:GetClaimingRewardTimeElapsedSeconds()
    if force or not self.claimRewardRequested then
        self.control:SetHandler("OnUpdate", nil)
        self.claimRewardEndTimeSeconds = nil
        self.claimRewardRequested = false
        self:SetClaimRewardProgress(0)
    end
end

function ZO_TamrielTomesReward_Shared:GetClaimingRewardNormalizedProgress()
    local remainingTimeSeconds = self:GetClaimingRewardTimeRemainingSeconds()
    if not remainingTimeSeconds then
        return nil
    end

    local normalizedProgress = 1 - (remainingTimeSeconds / CLAIM_REWARD_INTERVAL_SECONDS)
    return normalizedProgress
end

function ZO_TamrielTomesReward_Shared:GetClaimingRewardTimeRemainingSeconds()
    local endTimeSeconds = self.claimRewardEndTimeSeconds
    if not endTimeSeconds then
        return nil
    end

    local currentTimeSeconds = GetFrameTimeSeconds()
    local remainingTimeSeconds = zo_max(0, endTimeSeconds - currentTimeSeconds)
    return remainingTimeSeconds
end

function ZO_TamrielTomesReward_Shared:GetClaimingRewardTimeElapsedSeconds()
    local remainingTimeSeconds = self:GetClaimingRewardTimeRemainingSeconds()
    if not remainingTimeSeconds then
        return nil
    end

    local elapsedTimeSeconds = CLAIM_REWARD_INTERVAL_SECONDS - remainingTimeSeconds
    return elapsedTimeSeconds
end

function ZO_TamrielTomesReward_Shared:IsClaimingReward()
    return self.claimRewardEndTimeSeconds ~= nil
end

function ZO_TamrielTomesReward_Shared:UpdateClaimRewardProgress(currentFrameTimeSeconds)
    local elapsedTimeSeconds = self:GetClaimingRewardTimeElapsedSeconds()
    if not elapsedTimeSeconds then
        self:EndClaimReward()
        return
    end

    if not self.claimRewardRequested and elapsedTimeSeconds >= CLAIM_REWARD_COMPLETE_SECONDS then
        self.claimRewardRequested = true

        local tamrielTomesRewardData = self:GetTamrielTomesRewardData()
        if tamrielTomesRewardData then
            tamrielTomesRewardData:TryClaimReward()
        end
    end

    local normalizedProgress = self:GetClaimingRewardNormalizedProgress()
    self:SetClaimRewardProgress(normalizedProgress)

    if normalizedProgress >= 1 then
        local FORCE = true
        self:EndClaimReward(FORCE)
    end
end

function ZO_TamrielTomesReward_Shared:SetHidden(hidden)
    self.control:SetHidden(hidden)

    if hidden then
        local FORCE = true
        self:EndClaimReward(FORCE)
    end
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

function ZO_TamrielTomesReward_Shared:SetClaimRewardOverlayHidden(hidden)
    self.claimRewardOverlay:SetHidden(hidden)
end

function ZO_TamrielTomesReward_Shared:SetClaimRewardProgress(normalizedProgress)
    normalizedProgress = zo_clamp(normalizedProgress, 0, 1)
    self.claimRewardNormalizedProgress = normalizedProgress

    local hasProgress = normalizedProgress > 0 and normalizedProgress < 1
    if hasProgress then
        local BLUR_ORIGIN_X = 0.5
        local BLUR_ORIGIN_Y = 0.5
        local BLUR_SAMPLES = 11
        local blurRadius = normalizedProgress * 0.16
        local blurOffset = normalizedProgress * 0.08 - 0.08
        self.claimOverlayTexture:SetRadialBlur(BLUR_ORIGIN_X, BLUR_ORIGIN_Y, BLUR_SAMPLES, blurRadius, blurOffset)

        local alpha
        if normalizedProgress < 0.75 then
            alpha = zo_min(0.7, zo_sin(normalizedProgress * ZO_HALF_PI))
        else
            alpha = zo_min(0.7, zo_sin((0.5 + (normalizedProgress - 0.75) * 2.5) * ZO_PI))
        end
        self.claimOverlayTexture:SetAlpha(alpha)
        self.claimHighlightTexture:SetAlpha(alpha)
    end

    self:SetClaimRewardOverlayHidden(not hasProgress)

    local iconIntensity = 2 - zo_abs(ZO_ExponentialEaseOutIn(normalizedProgress, 2) * 2 - 1)
    self.iconTexture:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, iconIntensity)
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

    local displayQuality = tamrielTomesRewardData:GetRewardDisplayQuality()
    local displayQualityColor = GetDimItemQualityColor(displayQuality)
    self.claimOverlayTexture:SetColor(displayQualityColor:UnpackRGB())

    self:EndClaimReward()
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