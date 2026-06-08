ZO_LOW_LEVEL_PLAYER_REWARD_DIMENSIONS_KEYBOARD = 116
ZO_LOW_LEVEL_PLAYER_REWARD_SPACING_KEYBOARD = 5
ZO_LOW_LEVEL_PLAYER_REWARD_GRID_WIDTH_KEYBOARD = ZO_LOW_LEVEL_PLAYER_REWARD_DIMENSIONS_KEYBOARD * 2 + ZO_LOW_LEVEL_PLAYER_REWARD_SPACING_KEYBOARD + ZO_SCROLL_BAR_WIDTH
ZO_LOW_LEVEL_PLAYER_REWARD_GRID_HEIGHT_KEYBOARD = ZO_LOW_LEVEL_PLAYER_REWARD_DIMENSIONS_KEYBOARD * 3 + ZO_LOW_LEVEL_PLAYER_REWARD_SPACING_KEYBOARD * 2

ZO_LowLevelPlayerScreen_Keyboard = ZO_LowLevelPlayerScreen_Shared:Subclass()

function ZO_LowLevelPlayerScreen_Keyboard:Initialize(control)
    LOW_LEVEL_PLAYER_SCENE_KEYBOARD = ZO_Scene:New("LowLevelPlayerSceneKeyboard", SCENE_MANAGER)

    ZO_LowLevelPlayerScreen_Shared.Initialize(self, control, LOW_LEVEL_PLAYER_SCENE_KEYBOARD)

    SYSTEMS:RegisterKeyboardRootScene("lowLevelPlayer", self.scene)
end

function ZO_LowLevelPlayerScreen_Keyboard:OnDeferredInitialize()
    ZO_LowLevelPlayerScreen_Shared.OnDeferredInitialize(self)

    ApplyTemplateToControl(self.closeKeybindButton, "ZO_KeybindButton_Keyboard_Template")
    ApplyTemplateToControl(self.primaryKeybindButton, "ZO_KeybindButton_Keyboard_Template")

    local infoContainer = self.control:GetNamedChild("GameplayInfo")
    self.navigateButton = infoContainer:GetNamedChild("NavigateButton")
end

function ZO_LowLevelPlayerScreen_Keyboard:OnShowing()
    ZO_LowLevelPlayerScreen_Shared.OnShowing(self)

    if PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsIntroCampaignComplete() or IsActiveWorldStarterWorld() then
        self.navigateButton:SetClickSound(SOUNDS.DEFAULT_CLICK)
        self.navigateButton:SetHandler("OnClicked", function() PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:GoToPromotionalEvents() end)

        local promotionalEventNameText = PROMOTIONAL_EVENT_MANAGER:GetPromotionalEventsColorizedDisplayName()
        self.navigateButton:SetText(zo_strformat(SI_PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_NAVIGATION_TO_PROMOTIONAL_EVENT_ACTION, promotionalEventNameText))
    else
        self.navigateButton:SetClickSound(SOUNDS.ENTER_INTRO_GAMEPLAY_EXPERIENCE)
        self.navigateButton:SetHandler("OnClicked", function() self:RequestJumpToIntroGameplay() end)

        local activityName = GetIntroGameplayExperienceDisplayName()
        self.navigateButton:SetText(zo_strformat(SI_ENTER_INTRO_GAMEPLAY_EXPERIENCE_ACTION, activityName))
    end

    PlaySound(SOUNDS.LOW_LEVEL_PLAYER_OPEN_KEYBOARD)
end

function ZO_LowLevelPlayerScreen_Keyboard:OnHiding()
    ZO_LowLevelPlayerScreen_Shared.OnHiding(self)

    PlaySound(SOUNDS.LOW_LEVEL_PLAYER_CLOSE_KEYBOARD)
end

function ZO_LowLevelPlayerScreen_Keyboard:InitializeGridList()
    self.rewardGridList = ZO_SingleTemplateGridScrollList_Keyboard:New(self.rewardContainer, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL)

    local function RewardGridEntryReset(control)
        ZO_ObjectPool_DefaultResetControl(control)
        ZO_GridEntry_SetIconScaledUpInstantly(control, false)
    end

    local DEFAULT_HIDE_CALLBACK = nil
    self.rewardGridList:SetGridEntryTemplate("ZO_LowLevelPlayerReward_Keyboard", ZO_LOW_LEVEL_PLAYER_REWARD_DIMENSIONS_KEYBOARD, ZO_LOW_LEVEL_PLAYER_REWARD_DIMENSIONS_KEYBOARD, self.RewardGridEntrySetup, DEFAULT_HIDE_CALLBACK, RewardGridEntryReset, ZO_LOW_LEVEL_PLAYER_REWARD_SPACING_KEYBOARD, ZO_LOW_LEVEL_PLAYER_REWARD_SPACING_KEYBOARD)
end

function ZO_LowLevelPlayerScreen_Keyboard:GetPrimaryKeybindName()
    -- Must be overridden, no current functionality
    return nil
end

function ZO_LowLevelPlayerScreen_Keyboard:ShouldShowPrimaryKeybind()
    return false
end

function ZO_LowLevelPlayerScreen_Keyboard:OnPrimaryKeyPressed()
    -- Must be overridden, no current functionality
end

function ZO_LowLevelPlayerScreen_Keyboard.OnControlInitialized(control)
    LOW_LEVEL_PLAYER_SCREEN_KEYBOARD = ZO_LowLevelPlayerScreen_Keyboard:New(control)
end

function ZO_LowLevelPlayerScreen_Keyboard.Reward_OnMouseEnter(control)
    ZO_Rewards_Shared_OnMouseEnter(control, RIGHT, LEFT, -5)
    ZO_GridEntry_SetIconScaledUp(control, true)
end

function ZO_LowLevelPlayerScreen_Keyboard.Reward_OnMouseExit(control)
    ZO_Rewards_Shared_OnMouseExit(control)
    ZO_GridEntry_SetIconScaledUp(control, false)
end
