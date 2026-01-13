ZO_TamrielTomesRewardPreviewScreen_Gamepad = ZO_DeferredInitializingObject:Subclass()

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:Initialize(control)
    local scene = ZO_Scene:New("TamrielTomesRewardPreviewSceneGamepad", SCENE_MANAGER)
    TAMRIEL_TOMES_PREVIEW_REWARD_SCENE_GAMEPAD = scene
    self.control = control

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

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:EndPreviewReward()
    SYSTEMS:GetObject("itemPreview"):ClearPreviewCollection()
    ApplyChangesToPreviewCollectionShown()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:PreviewReward()
    local tamrielTomesRewardData = self.tamrielTomesRewardData
    if not tamrielTomesRewardData then
        internalassert(false, "PreviewReward: tamrielTomesRewardData is required.")
        return
    end

    local rewardData = tamrielTomesRewardData:GetRewardData()
    if rewardData then
        GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_RIGHT_TOOLTIP, rewardData)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end

    local previewSystem = SYSTEMS:GetObject("itemPreview")
    local rewardId = tamrielTomesRewardData:GetRewardId()
    if GetRewardType(rewardId) == REWARD_ENTRY_TYPE_REWARD_LIST then
        self:PreviewRewardList(rewardId)
    elseif not self.isAlreadyPreviewingReward then
        previewSystem:PreviewReward(rewardId)
    else
        -- Adds action keybinds for preview.
        previewSystem:OnPreviewShowing()
    end
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:PreviewRewardList(rewardId)
    -- TODO Tamriel Tomes
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:SetTamrielTomesRewardData(tamrielTomesRewardData, isAlreadyPreviewingReward)
    self.tamrielTomesRewardData = tamrielTomesRewardData
    self.isAlreadyPreviewingReward = isAlreadyPreviewingReward
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:OnShowing()
    TAMRIEL_TOMES_SCENE_GROUP_GAMEPAD:SetActiveScene("TamrielTomesPreviewRewardSceneGamepad")
    self:PreviewReward()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad:OnHiding()
    self:SetTamrielTomesRewardData(nil)
    self:EndPreviewReward()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TamrielTomesRewardPreviewScreen_Gamepad.OnControlInitialized(control)
    TAMRIEL_TOMES_REWARD_PREVIEW_SCREEN_GAMEPAD = ZO_TamrielTomesRewardPreviewScreen_Gamepad:New(control)
end