ZO_TamrielTomesRewardPreviewScreen_Gamepad = ZO_DeferredInitializingObject:Subclass()

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:Initialize(control)
    local scene = ZO_Scene:New("TamrielTomesRewardPreviewSceneGamepad", SCENE_MANAGER)
    TAMRIEL_TOMES_PREVIEW_REWARD_SCENE_GAMEPAD = scene
    self.control = control
    self.rewardId = nil

    ZO_DeferredInitializingObject.Initialize(self, scene)

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:OnDeferredInitialize()
    self:InitializeKeybindStripDescriptor()
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor = {}
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, nil, GetString(SI_TAMRIEL_TOMES_END_PREVIEW_ACTION))
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:SetRewardId(rewardId)
    -- Order matters
    self.rewardId = rewardId
    self:UpdatePreviewControls()
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:UpdatePreviewControls()
    if not self:IsShowing() then
        return
    end

    self:SetPreviewControlsHidden(self.rewardId == nil)
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:OnShowing()
    -- Order matters
    TAMRIEL_TOMES_SCENE_GROUP_GAMEPAD:SetActiveScene("TamrielTomesPreviewRewardSceneGamepad")
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdatePreviewControls()
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:OnHiding()
    -- Order matters
    self:SetRewardId(nil)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdatePreviewControls()
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:SetPreviewActionsHidden(hidden)
    local previewSystem = self.GetPreviewSystem()
    if hidden then
        previewSystem:SetActionControlsHidden(true)
    else
        previewSystem:SetupActionCarousel()
    end
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:SetPreviewVariationsHidden(hidden)
    local previewSystem = self.GetPreviewSystem()
    if hidden then
        previewSystem:SetVariationControlsHidden(true)
    else
        previewSystem:SetupVariationControls()
    end
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:SetPreviewControlsHidden(hidden)
    self:SetPreviewActionsHidden(hidden)
    self:SetPreviewVariationsHidden(hidden)

    if hidden then
        SCENE_MANAGER:RemoveFragment(PREVIEW_KEYBIND_ACTION_LAYER_FRAGMENT)
    else
        SCENE_MANAGER:AddFragment(PREVIEW_KEYBIND_ACTION_LAYER_FRAGMENT)
    end
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad.GetPreviewSystem()
    return SYSTEMS:GetObject("itemPreview")
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad.OnControlInitialized(control)
    TAMRIEL_TOMES_REWARD_PREVIEW_SCREEN_GAMEPAD = ZO_TamrielTomesRewardPreviewScreen_Gamepad:New(control)
end