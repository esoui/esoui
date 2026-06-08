-- Previewable Reward Data --

ZO_PreviewableRewardData = ZO_InitializingObject:Subclass()

ZO_PreviewableRewardData:MUST_IMPLEMENT("CanPreviewReward")

-- Preview Screen --

ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES =
{
    NONE = 0,
    ACTIVE_PREVIEW = 1,
    QUICK_PREVIEW = 2,
}

ZO_PreviewScreen_Shared = ZO_DeferredInitializingObject:Subclass()

ZO_PreviewScreen_Shared:MUST_IMPLEMENT("InitializeKeybindStripDescriptor")
ZO_PreviewScreen_Shared:MUST_IMPLEMENT("GetControlByPreviewableRewardData")
ZO_PreviewScreen_Shared:MUST_IMPLEMENT("PreviewRewardList")
ZO_PreviewScreen_Shared:MUST_IMPLEMENT("EndPreviewRewardList")

function ZO_PreviewScreen_Shared:OnDeferredInitialize()
    self:InitializeKeybindStripDescriptor()
end

function ZO_PreviewScreen_Shared:ActivePreviewRewardInternal(rewardId)
    if CanPreviewReward(rewardId) then
        SYSTEMS:GetObject("itemPreview"):PreviewReward(rewardId)
        self:SetPreviewControlsHidden(false)
    else
        self:SetPreviewControlsHidden(true)
    end
end

function ZO_PreviewScreen_Shared:QuickPreviewRewardInternal(rewardId)
    self:EndPreviewInternal()
    self:SetPreviewControlsHidden(true)

    if CanPreviewReward(rewardId) then
        SYSTEMS:GetObject("itemPreview"):PreviewReward(rewardId)
    end
end

function ZO_PreviewScreen_Shared:BeginActivePreviewInternal(previousPreviewableRewardData, previewableRewardData)
    local rewardId = previewableRewardData:GetRewardId()
    if GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST then
        local control = self:GetControlByPreviewableRewardData(previewableRewardData)
        if not control then
            return
        end

        self:EndQuickPreview()
        self:PreviewRewardList(rewardId, control)
        self.activePreviewableRewardData = nil
        return
    end

    -- Order matters
    self.activePreviewableRewardData = previewableRewardData
    self:EndQuickPreview()
    self:ActivePreviewRewardInternal(rewardId)

    local newPreviewRewardData = self:GetCurrentPreviewableRewardData()
    self:OnPreviewedPreviewableRewardDataChanged(previousPreviewableRewardData, newPreviewRewardData)
    self:UpdateKeybinds()

    self:OnBeginActivePreview()
end

function ZO_PreviewScreen_Shared:BeginPreview(previewType, previewableRewardData)
    if not previewableRewardData:CanPreviewReward() then
        return
    end

    local previousPreviewableRewardData = self:GetCurrentPreviewableRewardData()
    if previewType == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW then
        self:BeginQuickPreviewInternal(previousPreviewableRewardData, previewableRewardData)
    elseif previewType == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW then
        self:BeginActivePreviewInternal(previousPreviewableRewardData, previewableRewardData)
    else
        internalassert(false, "Invalid previewType: ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES value specified is invalid.")
    end
end

function ZO_PreviewScreen_Shared:BeginQuickPreview(previewableRewardData)
    if not (previewableRewardData:CanPreviewReward() and self:CanQuickPreview()) then
        return
    end

    -- Order matters
    self.quickPreviewTimeoutSeconds = nil
    self.queuedQuickPreviewableRewardData = previewableRewardData
    self.queuedQuickPreviewableRewardDataStartTimeSeconds = GetFrameTimeSeconds() + QUICK_PREVIEW_DELAY_SECONDS
end

function ZO_PreviewScreen_Shared:BeginQuickPreviewInternal(previousPreviewableRewardData, previewableRewardData)
    self:OnBeginQuickPreview()

    local rewardId = previewableRewardData:GetRewardId()
    if GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST then
        local tile = self:GetControlByPreviewableRewardData(previewableRewardData)
        self:PreviewRewardList(rewardId, tile)
        return
    end

    if not self:CanQuickPreview() then
        self:EndQuickPreview()
        return
    end

    self.quickPreviewableRewardData = previewableRewardData
    self:QuickPreviewRewardInternal(rewardId)

    local newPreviewRewardData = self:GetCurrentPreviewableRewardData()
    self:OnPreviewedPreviewableRewardDataChanged(previousPreviewableRewardData, newPreviewRewardData)
    self:UpdateKeybinds()
end

function ZO_PreviewScreen_Shared:EndActivePreview()
    if self.activePreviewableRewardData then
        local previousPreviewableRewardData = self.activePreviewableRewardData
        self.activePreviewableRewardData = nil
        self:EndPreviewInternal()
        self:OnPreviewedPreviewableRewardDataChanged(previousPreviewableRewardData, nil)
        self:OnEndActivePreview()
    end
end

function ZO_PreviewScreen_Shared:EndPreviewInternal()
    SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
    ApplyChangesToPreviewCollectionShown()
    self:UpdateKeybinds()
end

function ZO_PreviewScreen_Shared:EndPreview()
    local currentPreviewType = self:GetCurrentPreviewType()
    if currentPreviewType == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW then
        self:EndActivePreview()
    elseif currentPreviewType == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW then
        self:EndQuickPreview()
    else
        self:EndPreviewInternal()
    end
end

function ZO_PreviewScreen_Shared:ClearQueuedQuickPreview()
    self.queuedQuickPreviewableRewardData = nil
    self.queuedQuickPreviewableRewardDataStartTimeSeconds = nil
end

function ZO_PreviewScreen_Shared:ClearQuickPreview()
    local previousPreviewableRewardData = self:GetCurrentPreviewableRewardData()
    self.quickPreviewableRewardData = nil
    self.quickPreviewTimeoutSeconds = nil

    local newPreviewableRewardData = self:GetCurrentPreviewableRewardData()
    self:OnPreviewedPreviewableRewardDataChanged(previousPreviewableRewardData, newPreviewableRewardData)
end

function ZO_PreviewScreen_Shared:EndQuickPreview()
    if self.quickPreviewableRewardData or self.queuedQuickPreviewableRewardDataStartTimeSeconds then
        -- Order matters
        self:ClearQueuedQuickPreview()
        self:ClearQuickPreview()

        if self:GetCurrentPreviewType() ~= ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW then
            self:EndPreviewInternal()
        end
    end
end

function ZO_PreviewScreen_Shared:GetCurrentPreviewType()
    if self.activePreviewableRewardData then
        return ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW
    end

    if self.quickPreviewableRewardData or self.quickPreviewableRewardDataStartTimeSeconds then
        return ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW
    end

    return ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.NONE
end

function ZO_PreviewScreen_Shared:GetCurrentPreviewableRewardData()
    local previewType = self:GetCurrentPreviewType()

    if previewType == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.ACTIVE_PREVIEW then
        return self.activePreviewableRewardData
    end
    
    if previewType == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW then
        return self.quickPreviewableRewardData or self.queuedQuickPreviewableRewardData
    end

    return nil
end

function ZO_PreviewScreen_Shared:UpdateKeybinds()
    if self.scene:IsShowing() then
        if self.areKeybindsAdded then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        else
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self.areKeybindsAdded = true
        end
    else
        if self.areKeybindsAdded then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            self.areKeybindsAdded = false
        end
    end
end

function ZO_PreviewScreen_Shared:OnBeginActivePreview()
    -- Can be overridden
end

function ZO_PreviewScreen_Shared:OnEndActivePreview()
    -- Can be overridden
end

function ZO_PreviewScreen_Shared:OnBeginQuickPreview()
    -- Can be overridden
end

function ZO_PreviewScreen_Shared:OnEndQuickPreview()
    -- Can be overridden
end

function ZO_PreviewScreen_Shared:OnPreviewedPreviewableRewardDataChanged(previousPreviewableRewardData, newPreviewableRewardData)
    if previousPreviewableRewardData ~= newPreviewableRewardData then
        if previousPreviewableRewardData then
            self:SetIsPreviewableRewardPreviewing(previousPreviewableRewardData, false)
        end

        if newPreviewableRewardData then
            self:SetIsPreviewableRewardPreviewing(newPreviewableRewardData, true)
        end
    end
end

function ZO_PreviewScreen_Shared:SetPreviewControlsHidden(hidden)
    local previewSystem = SYSTEMS:GetObject("itemPreview")
    if hidden then
        previewSystem:SetActionControlsHidden(true)
        previewSystem:SetVariationControlsHidden(true)
    else
        -- Restores the preview action carousel and/or variaton controls if appropriate to do so.
        previewSystem:SetupActionCarousel()
        previewSystem:SetupVariationControls()
    end
end

function ZO_PreviewScreen_Shared:SetIsPreviewableRewardPreviewing(previewableRewardData, isPreviewing)
    local control = self:GetControlByPreviewableRewardData(previewableRewardData)
    if not control then
        return
    end

    control.object:GetReward():SetPreviewing(isPreviewing)
end

-- Indicates whether this scene should retain the current preview when hidden.
function ZO_PreviewScreen_Shared:ShouldRetainPreview()
    return false
end

function ZO_PreviewScreen_Shared:OnHiding()
    if self:GetCurrentPreviewType() ~= ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.NONE and self:ShouldRetainPreview() then
        -- The upcoming scene will need the current preview, if any, to remain visible.
        self:SetPreviewControlsHidden(false)
    else
        self:EndPreview()
    end

    self:EndPreviewRewardList()
    self:UpdateKeybinds()
end