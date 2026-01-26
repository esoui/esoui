ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_WIDTH = 128
ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_HEIGHT = 158

ZO_TAMRIEL_TOMES_REWARD_TILE_HEIGHT = ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_HEIGHT
ZO_TAMRIEL_TOMES_REWARD_TILE_1_X_WIDTH = ZO_TAMRIEL_TOMES_REWARD_TEMPLATE_WIDTH
ZO_TAMRIEL_TOMES_REWARD_TILE_2_X_WIDTH = ZO_TAMRIEL_TOMES_REWARD_TILE_1_X_WIDTH * 2
ZO_TAMRIEL_TOMES_REWARD_TILE_2_5_X_WIDTH = ZO_TAMRIEL_TOMES_REWARD_TILE_1_X_WIDTH * 2.5

ZO_TAMRIEL_TOMES_REWARD_DIVIDER_WIDTH = ZO_TAMRIEL_TOMES_REWARD_TILE_1_X_WIDTH * 5
ZO_TAMRIEL_TOMES_REWARD_DIVIDER_HEIGHT = 40

ZO_TAMRIEL_TOMES_REWARD_TOP_MARGIN_WIDTH = ZO_TAMRIEL_TOMES_REWARD_TILE_1_X_WIDTH * 5
ZO_TAMRIEL_TOMES_REWARD_TOP_MARGIN_HEIGHT = 16

local CLAIM_REWARD_COMPLETE_SECONDS = 0.65
local CLAIM_REWARD_INTERVAL_SECONDS = 1.2
internalassert(CLAIM_REWARD_COMPLETE_SECONDS <= CLAIM_REWARD_INTERVAL_SECONDS, "CLAIM_REWARD_COMPLETE_SECONDS must be less than or equal to CLAIM_REWARD_INTERVAL_SECONDS")

ZO_BRIGHT_DISABLED_TEXT_COLOR = ZO_ColorDef:New(0.85, 0.85, 0.85, 1)

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

    self.rewardContainer = control:GetNamedChild("Reward")
    self.backgroundTexture = control:GetNamedChild("Background")
    self.borderTexture = control:GetNamedChild("Border")
    self.rarityBorderTexture = control:GetNamedChild("RarityBorder")
    self.costLabel = control:GetNamedChild("Cost")
    self.costBackgroundTexture = control:GetNamedChild("CostBackground")
    self.checkTexture = self.rewardContainer:GetNamedChild("Check")
    self.iconTexture = self.rewardContainer:GetNamedChild("Icon")
    self.lockedTexture = self.rewardContainer:GetNamedChild("Locked")
    self.quantityLabel = self.rewardContainer:GetNamedChild("Quantity")
    self.claimRewardOverlay = control:GetNamedChild("ClaimRewardOverlay")
    self.claimHighlightTexture = self.claimRewardOverlay:GetNamedChild("Highlight")
    self.claimOverlayTexture = self.claimRewardOverlay:GetNamedChild("Overlay")

    self.isSelected = false
    self:ResetClaimReward()

    -- Required by ZO_Rewards_Shared_OnMouseEnter
    self.control.GetRewardData = function()
        return self:GetRewardData()
    end

    self.control.onClaimUpdate = function(_, currentFrameTimeSeconds)
        local frameDeltaSeconds = GetFrameDeltaSeconds()
        self:UpdateClaimRewardProgress(frameDeltaSeconds)
    end
end

function ZO_TamrielTomesReward_Shared:BeginClaimReward()
    if self.claimRewardRequested then
        -- A request to claim this reward has already been submitted.
        return
    end

    local tamrielTomesRewardData = self:GetTamrielTomesRewardData()
    if not (tamrielTomesRewardData and tamrielTomesRewardData:CanClaimReward() and tamrielTomesRewardData:CanAffordReward()) then
        -- This reward is too expensive or otherwise ineligible for claiming.
        return
    end

    self:SetClaimRewardMultiplier(1)
end

function ZO_TamrielTomesReward_Shared:EndClaimReward()
    if self.claimRewardRequested then
        -- A request to claim this reward has already been submitted.
        return
    end

    self:SetClaimRewardMultiplier(-1)
end

function ZO_TamrielTomesReward_Shared:ResetClaimReward()
    -- Force the claim reward process to reset.
    self:SetClaimRewardMultiplier(0)
    self:SetClaimRewardTimeElapsedSeconds(0)
    self:SetClaimRewardRequested(false)
end

function ZO_TamrielTomesReward_Shared:GetClaimRewardMultiplier()
    return self.claimRewardMultiplier or 0
end

function ZO_TamrielTomesReward_Shared:SetClaimRewardMultiplier(multiplier)
    if not (multiplier == 0 or multiplier == 1 or multiplier == -1) then
        internalassert(false, string.format("Invalid multiplier specified: %s", tostring(multiplier) or "nil"))
        return
    end

    self.claimRewardMultiplier = multiplier

    if multiplier == 0 then
        -- No progress will be made in either direction.
        self.control:SetHandler("OnUpdate", nil)
    else
        -- Progress will be increased or reduced.
        self.control:SetHandler("OnUpdate", self.control.onClaimUpdate)
    end
end

function ZO_TamrielTomesReward_Shared:GetClaimRewardNormalizedProgress()
    return self.claimRewardNormalizedProgress
end

function ZO_TamrielTomesReward_Shared:SetClaimRewardNormalizedProgress(normalizedProgress)
    normalizedProgress = zo_clamp(normalizedProgress, 0, 1)
    self.claimRewardNormalizedProgress = normalizedProgress
    self:UpdateClaimRewardProgressInternal()
end

function ZO_TamrielTomesReward_Shared:GetClaimRewardRequested()
    return self.claimRewardRequested
end

function ZO_TamrielTomesReward_Shared:SetClaimRewardRequested(isRequested)
    self.claimRewardRequested = isRequested
end

function ZO_TamrielTomesReward_Shared:GetClaimRewardTimeElapsedSeconds(timeElapsedSeconds)
    return self.claimRewardTimeElapsedSeconds
end

function ZO_TamrielTomesReward_Shared:SetClaimRewardTimeElapsedSeconds(timeElapsedSeconds)
    -- Update the time elapsed and the normalized progress.
    self.claimRewardTimeElapsedSeconds = zo_clamp(timeElapsedSeconds, 0, CLAIM_REWARD_INTERVAL_SECONDS)
    local normalizedProgress = zo_clamp(self.claimRewardTimeElapsedSeconds / CLAIM_REWARD_INTERVAL_SECONDS, 0, 1)
    self:SetClaimRewardNormalizedProgress(normalizedProgress)
end

function ZO_TamrielTomesReward_Shared:GetClaimRewardTimeRemainingSeconds()
    local claimRewardMultiplier = self:GetClaimRewardMultiplier()
    if not (claimRewardMultiplier == 1 or claimRewardMultiplier == -1) then
        -- Claim reward process has not been started.
        return nil
    end

    local claimRewardTimeElapsedSeconds = self:GetClaimRewardTimeElapsedSeconds()
    local claimRewardTimeRemainingSeconds = zo_max(0, CLAIM_REWARD_COMPLETE_SECONDS - claimRewardTimeElapsedSeconds)
    return claimRewardTimeRemainingSeconds
end

function ZO_TamrielTomesReward_Shared:UpdateClaimRewardProgress(timeIncrementSeconds)
    -- Add or deduct the time increment from the total claim reward time elapsed.
    local claimRewardTimeElapsedSeconds = self:GetClaimRewardTimeElapsedSeconds()
    local claimRewardMultiplier = self:GetClaimRewardMultiplier()
    self:SetClaimRewardTimeElapsedSeconds(claimRewardTimeElapsedSeconds + timeIncrementSeconds * claimRewardMultiplier)
    claimRewardTimeElapsedSeconds = self:GetClaimRewardTimeElapsedSeconds()

    if claimRewardMultiplier > 0 and not self.claimRewardRequested and claimRewardTimeElapsedSeconds >= CLAIM_REWARD_COMPLETE_SECONDS then
        local tamrielTomesRewardData = self:GetTamrielTomesRewardData()
        if tamrielTomesRewardData then
            -- Sufficient time has elapsed; submit the claim reward request.
            self.claimRewardRequested = true
            tamrielTomesRewardData:TryClaimReward()
        end
    end

    local normalizedProgress = self:GetClaimRewardNormalizedProgress()
    if (normalizedProgress >= 1 and claimRewardMultiplier > 0) or (normalizedProgress <= 0 and claimRewardMultiplier < 0) then
        -- The claim reward process time has elapsed or rolled back.
        self:ResetClaimReward()
    end
end

function ZO_TamrielTomesReward_Shared:UpdateClaimRewardProgressInternal()
    -- Update the visuals of the claim reward process.
    local normalizedProgress = self:GetClaimRewardNormalizedProgress()
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
end

function ZO_TamrielTomesReward_Shared:SetHidden(hidden)
    self.control:SetHidden(hidden)
    if hidden then
        -- Hiding this reward automatically resets the claim reward process.
        self:ResetClaimReward()
    end
end

function ZO_TamrielTomesReward_Shared:CanPreviewReward()
    local tamrielTomesRewardData = self:GetTamrielTomesRewardData()
    if tamrielTomesRewardData then
        return tamrielTomesRewardData:CanPreviewReward()
    end

    return nil
end

function ZO_TamrielTomesReward_Shared:GetRewardData()
    local tamrielTomesRewardData = self:GetTamrielTomesRewardData()
    if tamrielTomesRewardData then
        return tamrielTomesRewardData:GetRewardData()
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

function ZO_TamrielTomesReward_Shared:Refresh()
    if not self:HasRewardData() then
        self:SetHidden(true)
        return
    end

    local tamrielTomesRewardData = self:GetTamrielTomesRewardData()
    ZO_CurrencyControl_SetSimpleCurrency(self.costLabel, CURT_TOME_POINTS, tamrielTomesRewardData.rewardCost, self.currencyOptions)

    local quantity = tamrielTomesRewardData.rewardQuantity
    local isRewardList = tamrielTomesRewardData:IsRewardList()
    if isRewardList then
        local rewardListData = tamrielTomesRewardData:GetRewardListData()
        if rewardListData then
            quantity = #rewardListData - 1
        end
    end
    if quantity <= 1 then
        quantity = ""
    else
        quantity = ZO_CommaDelimitNumber(quantity)
        if isRewardList then
            quantity = zo_strformat(SI_TAMRIEL_TOMES_REWARD_LIST_QUANTITY_FORMATTER, quantity)
        end
    end
    self.quantityLabel:SetText(quantity)

    local iconTextureFile = tamrielTomesRewardData:GetPlatformLootIcon()
    self.iconTexture:SetTexture(iconTextureFile)

    local displayQuality = tamrielTomesRewardData:GetRewardDisplayQuality()
    local displayQualityColor = GetItemQualityColor(displayQuality)
    self.claimOverlayTexture:SetColor(displayQualityColor:UnpackRGB())

    local component = tamrielTomesRewardData:GetRewardComponent()
    if component == REWARD_TRACK_COMPONENT_SECONDARY then
        self.lockedTexture:SetTexture("EsoUI/Art/TamrielTomes/premium_tome_slot_lock.dds")
        self.lockedTexture:SetDimensions(45, 45)
    else
        self.lockedTexture:SetTexture("EsoUI/Art/TamrielTomes/tome_slot_lock.dds")
        self.lockedTexture:SetDimensions(32, 32)
    end

    self:EndClaimReward()
    self:RefreshState()
    self:SetHidden(false)
end

function ZO_TamrielTomesReward_Shared:UpdateTextureVisualsInternal(textureControl, desaturation, samplingWeightAlpha, samplingWeightRGB)
    textureControl:SetDesaturation(desaturation)
    textureControl:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_ALPHA_AS_RGB, samplingWeightAlpha)
    textureControl:SetTextureSampleProcessingWeight(TEX_SAMPLE_PROCESSING_RGB, samplingWeightRGB)
end

function ZO_TamrielTomesReward_Shared:RefreshState()
    local tamrielTomesRewardData = self:GetTamrielTomesRewardData()
    if not tamrielTomesRewardData then
        return
    end

    local canAfford = tamrielTomesRewardData:CanAffordReward()
    local isClaimed = tamrielTomesRewardData:IsRewardClaimed()
    self.checkTexture:SetHidden(not isClaimed)

    local isLocked = self:IsLocked() and not isClaimed
    self.lockedTexture:SetHidden(not isLocked)

    local iconDesaturation = 0
    local tileLabelColor = ZO_WHITE
    local tileDesaturation = 0
    local tileSamplingWeightAlpha = 0
    local tileSamplingWeightRGB = 1
    if isLocked then
        iconDesaturation = 1
        tileDesaturation = 1
        tileLabelColor = ZO_BRIGHT_DISABLED_TEXT_COLOR
        tileSamplingWeightAlpha = 0.3
        tileSamplingWeightRGB = 0.7
    elseif not canAfford then
        iconDesaturation = 1
        tileLabelColor = ZO_BRIGHT_DISABLED_TEXT_COLOR
    elseif isClaimed then
        iconDesaturation = 1
    end

    self:UpdateTextureVisualsInternal(self.backgroundTexture, tileDesaturation, tileSamplingWeightAlpha, tileSamplingWeightRGB)
    self:UpdateTextureVisualsInternal(self.borderTexture, tileDesaturation, tileSamplingWeightAlpha, tileSamplingWeightRGB)
    self:UpdateTextureVisualsInternal(self.costBackgroundTexture, tileDesaturation, tileSamplingWeightAlpha, tileSamplingWeightRGB)
    self:UpdateTextureVisualsInternal(self.iconTexture, iconDesaturation, tileSamplingWeightAlpha, tileSamplingWeightRGB)

    self.costLabel:SetColor(tileLabelColor:UnpackRGBA())
    self.quantityLabel:SetColor(tileLabelColor:UnpackRGBA())

    local displayQuality = tamrielTomesRewardData:GetRewardDisplayQuality()
    local rarityBorderColor = GetItemQualityColor(displayQuality)
    self.rarityBorderTexture:SetColor(rarityBorderColor:UnpackRGBA())
    self.rarityBorderTexture:SetHidden(tamrielTomesRewardData:GetHideRewardQuality())
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