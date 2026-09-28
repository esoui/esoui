ZO_PreviewScreen_Gamepad = ZO_PreviewScreen_Shared:Subclass()

function ZO_PreviewScreen_Gamepad:Initialize(control, scene)
    ZO_PreviewScreen_Shared.Initialize(self, control, scene)

    local function OnGamepadPreviewScreenHidden()
        self:EndPreview()
    end

    CALLBACK_MANAGER:RegisterCallback("OnGamepadPreviewScreenHidden", OnGamepadPreviewScreenHidden)
end

-- Indicates whether this scene should retain the current preview when hidden.
function ZO_PreviewScreen_Gamepad:ShouldRetainPreview()
    local nextScene = SCENE_MANAGER:GetNextScene()
    return nextScene == PREVIEW_SCREEN_ACTIVE_PREVIEW_SCENE_GAMEPAD
end

function ZO_PreviewScreen_Gamepad:BeginPreviewInternal()
    local previewType, rewardData, previewKey = self:GetActivePreviewInfo()
    local rewardId = rewardData:GetRewardId()
    local rewardType = rewardData:GetRewardType()

    if rewardType == REWARD_ENTRY_TYPE_REWARD_LIST then
        local rewardListId = GetRewardListIdFromReward(rewardId)
        PREVIEW_REWARD_LIST_SCREEN_GAMEPAD:SetRewardList(rewardListId)
        SCENE_MANAGER:Push("previewRewardList_Gamepad")
        return true
    end

    local previewSystem = self.GetPreviewSystem()
    previewSystem:PreviewReward(rewardId)
    self:RefreshPreviewControls()

    if previewType == ZO_PREVIEW_SCREEN_REWARD_DATA_PREVIEW_TYPES.FULL_PREVIEW then
        ITEM_PREVIEW_GAMEPAD:GetFragment():SetHideOnSceneHidden(false)
        PREVIEW_SCREEN_ACTIVE_PREVIEW_SCREEN_GAMEPAD:SetRewardId(rewardId)
        SCENE_MANAGER:Push(PREVIEW_SCREEN_ACTIVE_PREVIEW_SCENE_GAMEPAD:GetName())
    end

    return true
end

function ZO_PreviewScreen_Gamepad:InitializeKeybindStripDescriptors()
    -- Can be overridden
end

function ZO_PreviewScreen_Gamepad:GetControlByPreviewableRewardData(previewableRewardData)
    -- Can be overridden
end