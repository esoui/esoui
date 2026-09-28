-- Previewable Reward Data --

ZO_PreviewableRewardData = ZO_InitializingObject:Subclass()

ZO_PreviewableRewardData:MUST_IMPLEMENT("CanPreviewReward")

-- Preview Screen --

ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES =
{
    NONE = 0,
    QUICK_PREVIEW = 1,
    FULL_PREVIEW = 2,
}

-- The default delay that precedes the beginning of an active preview.
ZO_QUEUED_PREVIEW_DEFAULT_DELAY_SECONDS = 0.3
-- The default delay that precedes the ending of the active preview.
ZO_QUEUED_END_PREVIEW_DEFAULT_DELAY_SECONDS = 0.4

ZO_PreviewScreen_Shared = ZO_DeferredInitializingObject:Subclass()

ZO_PreviewScreen_Shared:MUST_IMPLEMENT("BeginPreviewInternal")
ZO_PreviewScreen_Shared:MUST_IMPLEMENT("InitializeKeybindStripDescriptors")
ZO_PreviewScreen_Shared:MUST_IMPLEMENT("GetControlByPreviewableRewardData")

function ZO_PreviewScreen_Shared:Initialize(control, scene)
    ZO_DeferredInitializingObject.Initialize(self, scene)
    self.control = control
end

function ZO_PreviewScreen_Shared:OnDeferredInitialize()
    self:InitializeKeybindStripDescriptors()

    self.isQuickPreviewEnabled = true

    self.activePreviewType = ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.NONE
    self.pendingPreviewType = ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.NONE

    self.control:SetHandler("OnUpdate", function(_, ...) self:OnUpdate(...) end)
end

function ZO_PreviewScreen_Shared:SetQuickPreviewEnabled(isEnabled)
    self.isQuickPreviewEnabled = isEnabled
end

function ZO_PreviewScreen_Shared:ShouldHideKeybinds()
    return not self.scene:IsShowing()
end

function ZO_PreviewScreen_Shared:UpdateKeybinds()
    local hideKeybinds = self:ShouldHideKeybinds()
    self:SetKeybindsHidden(hideKeybinds)
end

function ZO_PreviewScreen_Shared:SetKeybindsHidden(hidden)
    if hidden then
        if self.areKeybindsAdded then
            self.areKeybindsAdded = false
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end

        return
    end

    KEYBIND_STRIP:RemoveDefaultExit()
    if self.areKeybindsAdded then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    else
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        self.areKeybindsAdded = true
    end
end

function ZO_PreviewScreen_Shared:SetRewardListKeybinds(keybindStripDescriptor)
    self.rewardListKeybindStripDescriptor = keybindStripDescriptor
end

function ZO_PreviewScreen_Shared:IsShowingRewardList()
    return false
end

function ZO_PreviewScreen_Shared.AreRewardsEqual(reward1, reward2)
    if reward1 then
        if not reward2 then
            return false
        end

        if reward1:GetRewardId() ~= reward2:GetRewardId() then
            return false
        end
    elseif reward2 then
        return false
    end

    return true
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
    -- Order matters
    if self:ShouldRetainPreview() then
        self:ClearQueuedEndPreview()
    else
        self:ClearQueuedEndPreview()
        self:UpdateKeybinds()
    end
end

function ZO_PreviewScreen_Shared:OnShowing()
    if self:GetActivePreviewType() == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW then
        -- If a Full Preview was active, downgrade it to a Quick Preview.
        if self.isQuickPreviewEnabled then
            self.activePreviewType = ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW
        else
            self.activePreviewType = ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.NONE
        end
    end
end

function ZO_PreviewScreen_Shared:OnBeginPreview(previewType, rewardData, previewKey)
    -- 'previewKey' is the ZO_RewardData_Base instance.
    if previewKey then
        self:SetIsPreviewableRewardPreviewing(previewKey, true)
    end
end

function ZO_PreviewScreen_Shared:OnEndPreview(previewType, rewardData, previewKey)
    -- 'previewKey' is the data object instance.
    if previewKey then
        self:SetIsPreviewableRewardPreviewing(previewKey, false)
    end
end

function ZO_PreviewScreen_Shared:EndPreviewInternal()
    local previewSystem = self.GetPreviewSystem()
    previewSystem:EndCurrentPreview()
    self:RefreshPreviewControls()
end

-- Begins a preview of type 'previewType' of 'rewardData' (including an optional 'previewKey' for reference).
-- Returns true if the preview was successfully shown.
function ZO_PreviewScreen_Shared:BeginPreview(previewType, rewardData, previewKey)
    if not self:CanBeginPreview(previewType, rewardData) then
        return false
    end

    if not self.isQuickPreviewEnabled
        and previewType and previewType == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW then
        return false
    end

    if self.activePreviewRewardData and not self.AreRewardsEqual(rewardData, self.activePreviewRewardData) then
        self.GetPreviewSystem():EndCurrentPreview()
    end

    -- Order matters
    self.activePreviewEndTimeS = nil
    self.activePreviewKey = previewKey
    self.activePreviewRewardData = rewardData
    self.activePreviewType = previewType
    self:BeginPreviewInternal()
    self:OnBeginPreview(previewType, rewardData, previewKey)
    self:UpdateKeybinds()
    return true
end

-- Returns true if a preview of type 'previewType' can be shown right now for 'rewardData'.
function ZO_PreviewScreen_Shared:CanBeginPreview(previewType, rewardData)
    assert(previewType and previewType ~= ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.NONE, "A valid previewType is required.")

    if self.ComparePreviewTypePriorities(previewType, self.activePreviewType) < 0 and not self.activePreviewEndTimeS then
        -- The requested preview type is suppressed by the active preview type.
        return false
    end

    if not self.CanPreviewReward(rewardData) then
        return false
    end

    if previewType == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW and rewardData:GetRewardType() == REWARD_ENTRY_TYPE_REWARD_LIST then
        -- Reward lists must be full previewed in order to show the list.
        return false
    end

    return true
end

function ZO_PreviewScreen_Shared:ClearQueuedEndPreview()
    self.activePreviewEndTimeS = nil
end

function ZO_PreviewScreen_Shared:ClearQueuedPreview()
    self.pendingPreviewKey = nil
    self.pendingPreviewRewardData = nil
    self.pendingPreviewStartTimeS = nil
    self.pendingPreviewType = ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.NONE
end

function ZO_PreviewScreen_Shared:EndPreview()
    -- Order matters
    local activePreviewType = self.activePreviewType
    local activePreviewRewardData = self.activePreviewRewardData
    local activePreviewKey = self.activePreviewKey
    self.activePreviewEndTimeS = nil
    self.activePreviewKey = nil
    self.activePreviewRewardData = nil
    self.activePreviewType = ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.NONE
    self:OnEndPreview(activePreviewType, activePreviewRewardData, activePreviewKey)

    -- Order matters
    self:EndPreviewInternal()
    self:SetPreviewActionsHidden(true)
    self:SetPreviewVariationsHidden(true)
    self:UpdateKeybinds()
end

function ZO_PreviewScreen_Shared:GetFocusedRewardData()
    return self.focusedRewardData
end

function ZO_PreviewScreen_Shared:SetFocusedRewardData(newData)
    if newData == self.focusedRewardData then
        return
    end

    local previousData = self.focusedRewardData
    self.focusedRewardData = newData

    self:OnFocusedRewardDataChanged(newData, newTileControl)
    self:UpdateKeybinds()
end

function ZO_PreviewScreen_Shared:OnFocusedRewardDataChanged(newData)
    if not (newData and newData:CanPreviewReward()) then
        if self:ShouldRetainPreview() then
            return
        end

        self:QueueEndPreview(ZO_QUEUED_PREVIEW_DEFAULT_DELAY_SECONDS)
        self:ClearQueuedPreview()
        return
    end

    self:QueuePreview(ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW, newData:GetRewardData(), newData, ZO_QUEUED_PREVIEW_DEFAULT_DELAY_SECONDS)
end

function ZO_PreviewScreen_Shared:GetActivePreviewRewardData()
    return self.activePreviewRewardData
end

function ZO_PreviewScreen_Shared:GetActivePreviewEndTimeSeconds()
    return self.activePreviewEndTimeS
end

function ZO_PreviewScreen_Shared:GetActivePreviewInfo()
    return self.activePreviewType, self.activePreviewRewardData, self.activePreviewKey
end

function ZO_PreviewScreen_Shared:GetActivePreviewType()
    return self.activePreviewType
end

function ZO_PreviewScreen_Shared:GetPendingPreviewInfo()
    return self.pendingPreviewType, self.pendingPreviewRewardData, self.pendingPreviewKey, self.pendingPreviewStartTimeS
end

function ZO_PreviewScreen_Shared:OnUpdate(currentFrameTimeS)
    self:UpdatePreview(currentFrameTimeS)
end

-- Queues the end of the active preview.
function ZO_PreviewScreen_Shared:QueueEndPreview(delaySeconds)
    assert(tonumber(delaySeconds), "A valid delaySeconds is required.")

    if self:GetActivePreviewType() == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.NONE then
        return
    end

    self.activePreviewEndTimeS = GetFrameTimeSeconds() + delaySeconds
end

-- Queues a preview of type 'previewType' of 'rewardData' (including an optional 'previewKey' for reference) to begin in 'delaySeconds'.
-- Returns true if the preview was successfully queued.
function ZO_PreviewScreen_Shared:QueuePreview(previewType, rewardData, previewKey, delaySeconds)
    assert(previewType and previewType ~= ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.NONE, "A valid previewType is required.")
    assert(tonumber(delaySeconds), "A valid delaySeconds is required.")

    if rewardData == self.activePreviewRewardData then
        -- The request is for the same reward; just retain the active preview.
        self:ClearQueuedPreview()
        self:ClearQueuedEndPreview()

        -- Update the preview details in the event that this request came from a different source
        -- or the preview type itself has changed.
        self.activePreviewKey = previewKey
        self.activePreviewType = previewType
        self:BeginPreviewInternal()

        return true
    end

    if not self.CanPreviewReward(rewardData) then
        return false
    end

    if not self.isQuickPreviewEnabled
        and previewType and previewType == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.QUICK_PREVIEW then
        return false
    end

    self.pendingPreviewKey = previewKey
    self.pendingPreviewRewardData = rewardData
    self.pendingPreviewStartTimeS = GetFrameTimeSeconds() + delaySeconds
    self.pendingPreviewType = previewType
    return true
end

function ZO_PreviewScreen_Shared:SetPreviewActionsHidden(hidden)
    local previewSystem = self.GetPreviewSystem()
    if hidden then
        previewSystem:SetActionControlsHidden(true)
    else
        previewSystem:SetupActionCarousel()
    end
end

function ZO_PreviewScreen_Shared:SetPreviewVariationsHidden(hidden)
    local previewSystem = self.GetPreviewSystem()
    if hidden then
        previewSystem:SetVariationControlsHidden(true)
    else
        previewSystem:SetupVariationControls()
    end
end

function ZO_PreviewScreen_Shared:SetPreviewControlsHidden(hidden)
    self:SetPreviewActionsHidden(hidden)
    self:SetPreviewVariationsHidden(hidden)
end

function ZO_PreviewScreen_Shared:ShouldActivePreviewShowFullPreview()
    local previewType = self:GetActivePreviewType()
    if previewType ~= ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW then
        return false
    end

    local previewEndTimeS = self:GetActivePreviewEndTimeSeconds()
    if previewEndTimeS then
        return false
    end

    local rewardData = self:GetActivePreviewRewardData()
    if not rewardData or rewardData:GetRewardType() == REWARD_ENTRY_TYPE_REWARD_LIST then
        return false
    end

    return true
end

function ZO_PreviewScreen_Shared:ShouldHidePreviewControls()
    local previewType = self:GetActivePreviewType()
    if previewType == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW then
        local previewRewardData = self:GetActivePreviewRewardData()
        if previewRewardData and previewRewardData:GetRewardType() ~= REWARD_ENTRY_TYPE_REWARD_LIST then
            return false
        end
    end

    return true
end

function ZO_PreviewScreen_Shared:RefreshPreviewControls()
    local hidden = self:ShouldHidePreviewControls()
    self:SetPreviewControlsHidden(hidden)
end

function ZO_PreviewScreen_Shared:UpdatePreview(currentFrameTimeS)
    if not self:IsShowing() then
        return
    end

    -- Process a queued preview request prior to a queued end preview request
    -- to ensure that a follow up preview is not cleared as a result of the
    -- scheduled termination of the previous preview.

    if self.pendingPreviewStartTimeS and currentFrameTimeS >= self.pendingPreviewStartTimeS then
        -- Order matters
        local previewKey = self.pendingPreviewKey
        local rewardData = self.pendingPreviewRewardData
        local previewType = self.pendingPreviewType
        self:ClearQueuedPreview()
        self:BeginPreview(previewType, rewardData, previewKey)
    elseif self.activePreviewEndTimeS and currentFrameTimeS >= self.activePreviewEndTimeS then
        self:EndPreview()
    end
end

-- Static methods

-- Returns true if 'rewardData' can be previewed.
function ZO_PreviewScreen_Shared.CanPreviewReward(rewardData)
    assert(rewardData and rewardData:IsInstanceOf(ZO_RewardData), "A valid instance of ZO_RewardData is required.")

    local rewardType = rewardData:GetRewardType()
    if rewardType == REWARD_ENTRY_TYPE_REWARD_LIST then
        return true
    end

    local rewardId = rewardData:GetRewardId()
    if not CanPreviewReward(rewardId) then
        return false
    end

    return true
end

-- Returns a positive integer if previewType1 is a higher priority than previewType2;
-- returns a negative integer if previewType1 is a lower priority than previewType2;
-- returns zero if both preview types are of equal priority.
function ZO_PreviewScreen_Shared.ComparePreviewTypePriorities(previewType1, previewType2)
    if previewType1 < previewType2 then
        return -1
    end

    if previewType1 > previewType2 then
        return 1
    end

    return 0
end

function ZO_PreviewScreen_Shared.GetPreviewSystem()
    return SYSTEMS:GetObject("itemPreview")
end