ZO_PreviewScreen_ActivePreview_Gamepad = ZO_DeferredInitializingObject:Subclass()

function ZO_PreviewScreen_ActivePreview_Gamepad:Initialize(control)
    local scene = ZO_Scene:New("PreviewScreenActivePreviewSceneGamepad", SCENE_MANAGER)
    PREVIEW_SCREEN_ACTIVE_PREVIEW_SCENE_GAMEPAD = scene
    self.control = control

    ZO_DeferredInitializingObject.Initialize(self, scene)

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)
end

function ZO_PreviewScreen_ActivePreview_Gamepad:OnDeferredInitialize()
    self:InitializeKeybindStripDescriptor()
end

function ZO_PreviewScreen_ActivePreview_Gamepad:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor = {}
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, nil, GetString(SI_ACTIVE_PREVIEW_END_PREVIEW_ACTION))
end

function ZO_PreviewScreen_ActivePreview_Gamepad:PreviewReward()
    local previewableRewardData = self.previewableRewardData
    if not previewableRewardData then
        internalassert(false, "PreviewReward: previewableRewardData is required.")
        return
    end

    local rewardData = previewableRewardData:GetRewardData()
    if rewardData then
        GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_RIGHT_TOOLTIP, rewardData)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end

    local previewSystem = SYSTEMS:GetObject("itemPreview")
    local rewardId = previewableRewardData:GetRewardId()
    if GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST then
        self:PreviewRewardList(rewardId)
    elseif not self.isAlreadyPreviewingReward then
        previewSystem:PreviewReward(rewardId)
    else
        -- Adds action keybinds for preview.
        previewSystem:OnPreviewShowing()
    end
end

function ZO_PreviewScreen_ActivePreview_Gamepad:EndPreviewReward()
    SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
    ApplyChangesToPreviewCollectionShown()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_PreviewScreen_ActivePreview_Gamepad:PreviewRewardList(rewardId)
    -- TODO Veterancy
end

function ZO_PreviewScreen_ActivePreview_Gamepad:SetSceneGroup(sceneGroup)
    self.sceneGroup = sceneGroup
end

function ZO_PreviewScreen_ActivePreview_Gamepad:SetPreviewableRewardData(previewableRewardData, isAlreadyPreviewingReward)
    self.previewableRewardData = previewableRewardData
    self.isAlreadyPreviewingReward = isAlreadyPreviewingReward
end

function ZO_PreviewScreen_ActivePreview_Gamepad:OnShowing()
    self.sceneGroup:SetActiveScene("ZO_PreviewScreenActivePreviewSceneGamepad")
    self:PreviewReward()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_PreviewScreen_ActivePreview_Gamepad:OnHiding()
    self:SetPreviewableRewardData(nil)
    self:EndPreviewReward()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_PreviewScreen_ActivePreview_Gamepad.OnControlInitialized(control)
    PREVIEW_SCREEN_ACTIVE_PREVIEW_SCREEN_GAMEPAD = ZO_PreviewScreen_ActivePreview_Gamepad:New(control)
end