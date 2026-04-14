ZO_LOW_LEVEL_PLAYER_PANEL_RIGHT_OFFSET_GAMEPAD = ZO_GAMEPAD_QUADRANT_4_LEFT_OFFSET - 50
ZO_LOW_LEVEL_PLAYER_REWARD_DIMENSIONS_GAMEPAD = 116
ZO_LOW_LEVEL_PLAYER_REWARD_SPACING_GAMEPAD = 5
ZO_LOW_LEVEL_PLAYER_REWARD_GRID_WIDTH_GAMEPAD = ZO_LOW_LEVEL_PLAYER_REWARD_DIMENSIONS_GAMEPAD * 2 + ZO_LOW_LEVEL_PLAYER_REWARD_SPACING_GAMEPAD + ZO_SCROLL_BAR_WIDTH
ZO_LOW_LEVEL_PLAYER_REWARD_GRID_HEIGHT_GAMEPAD = ZO_LOW_LEVEL_PLAYER_REWARD_DIMENSIONS_GAMEPAD * 3 + ZO_LOW_LEVEL_PLAYER_REWARD_SPACING_GAMEPAD * 2

ZO_LowLevelPlayerScreen_Gamepad = ZO_LowLevelPlayerScreen_Shared:Subclass()

function ZO_LowLevelPlayerScreen_Gamepad:Initialize(control)
    LOW_LEVEL_PLAYER_SCENE_GAMEPAD = ZO_Scene:New("LowLevelPlayerSceneGamepad", SCENE_MANAGER)

    ZO_LowLevelPlayerScreen_Shared.Initialize(self, control, LOW_LEVEL_PLAYER_SCENE_GAMEPAD)

    SYSTEMS:RegisterGamepadRootScene("lowLevelPlayer", self.scene)
end

function ZO_LowLevelPlayerScreen_Gamepad:OnDeferredInitialize()
    ZO_LowLevelPlayerScreen_Shared.OnDeferredInitialize(self)

    ApplyTemplateToControl(self.closeKeybindButton, "ZO_KeybindButton_Gamepad_Template")
    ApplyTemplateToControl(self.primaryKeybindButton, "ZO_KeybindButton_Gamepad_Template")
end

function ZO_LowLevelPlayerScreen_Gamepad:InitializeGridList()
    self.rewardGridList = ZO_SingleTemplateGridScrollList_Gamepad:New(self.rewardContainer, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL)

    local function RewardGridEntryReset(control)
        ZO_ObjectPool_DefaultResetControl(control)
    end

    local DEFAULT_HIDE_CALLBACK = nil
    self.rewardGridList:SetGridEntryTemplate("ZO_LowLevelPlayerReward_Gamepad", ZO_LOW_LEVEL_PLAYER_REWARD_DIMENSIONS_GAMEPAD, ZO_LOW_LEVEL_PLAYER_REWARD_DIMENSIONS_GAMEPAD, self.RewardGridEntrySetup, DEFAULT_HIDE_CALLBACK, RewardGridEntryReset, ZO_LOW_LEVEL_PLAYER_REWARD_SPACING_GAMEPAD, ZO_LOW_LEVEL_PLAYER_REWARD_SPACING_GAMEPAD)
    self.rewardGridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridListSelectedDataChanged(...) end)
    local function GetHeaderNarration()
        local narrations = {}
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.headerLabel:GetText()))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.bodyTextLabel:GetText()))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.gameplayTitleLabel:GetText()))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.gameplayDescriptionLabel:GetText()))
        return narrations
    end
    self.rewardGridList:SetHeaderNarrationFunction(GetHeaderNarration)
end

function ZO_LowLevelPlayerScreen_Gamepad:OnShowing()
    ZO_LowLevelPlayerScreen_Shared.OnShowing(self)

    self.rewardGridList:Activate()

    PlaySound(SOUNDS.LOW_LEVEL_PLAYER_OPEN_GAMEPAD)
end

function ZO_LowLevelPlayerScreen_Gamepad:OnHiding()
    ZO_LowLevelPlayerScreen_Shared.OnHiding(self)

    self.rewardGridList:Deactivate()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)

    PlaySound(SOUNDS.LOW_LEVEL_PLAYER_CLOSE_GAMEPAD)
end

function ZO_LowLevelPlayerScreen_Gamepad:OnGridListSelectedDataChanged(previousData, newData)
    if not self.rewardGridList:IsActive() then
        return
    end

    if newData then
        GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_RIGHT_TOOLTIP, newData)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_LowLevelPlayerScreen_Gamepad:GetPrimaryKeybindName()
    local activityName = GetIntroGameplayExperienceDisplayName()
    return zo_strformat(SI_ENTER_INTRO_GAMEPLAY_EXPERIENCE_ACTION, activityName)
end

function ZO_LowLevelPlayerScreen_Gamepad:ShouldShowPrimaryKeybind()
    return PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:CanJumpToIntroGameplay()
end

function ZO_LowLevelPlayerScreen_Gamepad:OnPrimaryKeyPressed()
    PlaySound(SOUNDS.ENTER_INTRO_GAMEPLAY_EXPERIENCE)
    self:RequestJumpToIntroGameplay()
end

function ZO_LowLevelPlayerScreen_Gamepad.OnControlInitialized(control)
    LOW_LEVEL_PLAYER_SCREEN_GAMEPAD = ZO_LowLevelPlayerScreen_Gamepad:New(control)
end
