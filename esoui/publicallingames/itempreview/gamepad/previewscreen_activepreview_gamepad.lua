ZO_PreviewScreen_ActivePreview_Gamepad = ZO_DeferredInitializingObject:Subclass()

function ZO_PreviewScreen_ActivePreview_Gamepad:Initialize(control)
    local scene = ZO_Scene:New("PreviewScreenActivePreviewSceneGamepad", SCENE_MANAGER)
    PREVIEW_SCREEN_ACTIVE_PREVIEW_SCENE_GAMEPAD = scene
    self.control = control
    self.rewardId = nil

    ZO_DeferredInitializingObject.Initialize(self, scene)

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)
end

function ZO_PreviewScreen_ActivePreview_Gamepad:OnDeferredInitialize()
    self:InitializeKeybindStripDescriptors()
end

function ZO_PreviewScreen_ActivePreview_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = {}
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, nil, GetString(SI_ACTIVE_PREVIEW_END_PREVIEW_ACTION))
end

function ZO_PreviewScreen_ActivePreview_Gamepad:SetRewardId(rewardId)
    -- Order matters
    self.rewardId = rewardId
    self:UpdatePreviewControls()
end

function ZO_PreviewScreen_ActivePreview_Gamepad:UpdatePreviewControls()
    if not self:IsShowing() then
        return
    end

    self:SetPreviewControlsHidden(self.rewardId == nil)
end

function ZO_PreviewScreen_ActivePreview_Gamepad:SetSceneGroup(sceneGroup)
    self.sceneGroup = sceneGroup
end

function ZO_PreviewScreen_ActivePreview_Gamepad:OnShowing()
    -- Order matters
    self.sceneGroup:SetActiveScene("ZO_PreviewScreenActivePreviewSceneGamepad")
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdatePreviewControls()
end

function ZO_PreviewScreen_ActivePreview_Gamepad:OnHiding()
    -- Order matters
    self:SetRewardId(nil)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdatePreviewControls()
    CALLBACK_MANAGER:FireCallbacks("OnGamepadPreviewScreenHidden")
end

function ZO_PreviewScreen_ActivePreview_Gamepad:SetPreviewActionsHidden(hidden)
    local previewSystem = self.GetPreviewSystem()
    if hidden then
        previewSystem:SetActionControlsHidden(true)
    else
        previewSystem:SetupActionCarousel()
    end
end

function ZO_PreviewScreen_ActivePreview_Gamepad:SetPreviewVariationsHidden(hidden)
    local previewSystem = self.GetPreviewSystem()
    if hidden then
        previewSystem:SetVariationControlsHidden(true)
    else
        previewSystem:SetupVariationControls()
    end
end

function ZO_PreviewScreen_ActivePreview_Gamepad:SetPreviewControlsHidden(hidden)
    self:SetPreviewActionsHidden(hidden)
    self:SetPreviewVariationsHidden(hidden)

    if hidden then
        SCENE_MANAGER:RemoveFragment(PREVIEW_KEYBIND_ACTION_LAYER_FRAGMENT)
    else
        SCENE_MANAGER:AddFragment(PREVIEW_KEYBIND_ACTION_LAYER_FRAGMENT)
    end
end

function ZO_PreviewScreen_ActivePreview_Gamepad.GetPreviewSystem()
    return SYSTEMS:GetObject("itemPreview")
end

function ZO_PreviewScreen_ActivePreview_Gamepad.OnControlInitialized(control)
    PREVIEW_SCREEN_ACTIVE_PREVIEW_SCREEN_GAMEPAD = ZO_PreviewScreen_ActivePreview_Gamepad:New(control)
end