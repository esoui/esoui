ZO_RETURNING_PLAYER_INTRO_REWARD_DIMENSIONS_KEYBOARD = 116
ZO_RETURNING_PLAYER_INTRO_REWARD_SPACING_KEYBOARD = 5
ZO_RETURNING_PLAYER_INTRO_REWARD_GRID_WIDTH_KEYBOARD = ZO_RETURNING_PLAYER_INTRO_REWARD_DIMENSIONS_KEYBOARD * 2 + ZO_RETURNING_PLAYER_INTRO_REWARD_SPACING_KEYBOARD + ZO_SCROLL_BAR_WIDTH
ZO_RETURNING_PLAYER_INTRO_REWARD_GRID_HEIGHT_KEYBOARD = ZO_RETURNING_PLAYER_INTRO_REWARD_DIMENSIONS_KEYBOARD * 3 + ZO_RETURNING_PLAYER_INTRO_REWARD_SPACING_KEYBOARD * 2

ZO_ReturningPlayerIntroScreen_Keyboard = ZO_ReturningPlayerIntroScreen_Shared:Subclass()

function ZO_ReturningPlayerIntroScreen_Keyboard:Initialize(control)
    RETURNING_PLAYER_INTRO_SCENE_KEYBOARD = ZO_Scene:New("ReturningPlayerIntroSceneKeyboard", SCENE_MANAGER)

    ZO_ReturningPlayerIntroScreen_Shared.Initialize(self, control, RETURNING_PLAYER_INTRO_SCENE_KEYBOARD)

    SYSTEMS:RegisterKeyboardRootScene("returningPlayerIntro", self.scene)
end

function ZO_ReturningPlayerIntroScreen_Keyboard:OnDeferredInitialize()
    ZO_ReturningPlayerIntroScreen_Shared.OnDeferredInitialize(self)

    ApplyTemplateToControl(self.closeKeybindButton, "ZO_KeybindButton_Keyboard_Template")
    ApplyTemplateToControl(self.primaryKeybindButton, "ZO_KeybindButton_Keyboard_Template")

    local infoContainer = self.control:GetNamedChild("GameplayInfo")
    self.enterGameplayButton = infoContainer:GetNamedChild("EnterButton")
    self.enterGameplayButton:SetClickSound(SOUNDS.RETURNING_PLAYER_ENTER_INTRO_GAMEPLAY)
    self.enterGameplayButton:SetHandler("OnClicked", function() self:RequestJumpToIntroGameplay() end)

    local activityName = GetReturningPlayerIntroGameplayDisplayName()
    local buttonText = zo_strformat(SI_RETURNING_PLAYER_ENTER_GAMEPLAY_EXPERIENCE_ACTION, activityName)
    self.enterGameplayButton:SetText(buttonText)
end

function ZO_ReturningPlayerIntroScreen_Keyboard:OnShowing()
    ZO_ReturningPlayerIntroScreen_Shared.OnShowing(self)

    local enableButton = RETURNING_PLAYER_MANAGER:CanJumpToIntroGameplay()
    self.enterGameplayButton:SetEnabled(enableButton)

    PlaySound(SOUNDS.RETURNING_PLAYER_OPEN_KEYBOARD)
end

function ZO_ReturningPlayerIntroScreen_Keyboard:OnHiding()
    ZO_ReturningPlayerIntroScreen_Shared.OnHiding(self)

    PlaySound(SOUNDS.RETURNING_PLAYER_CLOSE_KEYBOARD)
end

function ZO_ReturningPlayerIntroScreen_Keyboard:InitializeGridList()
    self.rewardGridList = ZO_SingleTemplateGridScrollList_Keyboard:New(self.rewardContainer, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL)

    local function RewardGridEntryReset(control)
        ZO_ObjectPool_DefaultResetControl(control)
        ZO_GridEntry_SetIconScaledUpInstantly(control, false)
    end

    local DEFAULT_HIDE_CALLBACK = nil
    self.rewardGridList:SetGridEntryTemplate("ZO_ReturningPlayerIntroReward_Keyboard", ZO_RETURNING_PLAYER_INTRO_REWARD_DIMENSIONS_KEYBOARD, ZO_RETURNING_PLAYER_INTRO_REWARD_DIMENSIONS_KEYBOARD, self.RewardGridEntrySetup, DEFAULT_HIDE_CALLBACK, RewardGridEntryReset, ZO_RETURNING_PLAYER_INTRO_REWARD_SPACING_KEYBOARD, ZO_RETURNING_PLAYER_INTRO_REWARD_SPACING_KEYBOARD)
end

function ZO_ReturningPlayerIntroScreen_Keyboard:GetPrimaryKeybindName()
    -- Must be overridden, no current functionality
    return nil
end

function ZO_ReturningPlayerIntroScreen_Keyboard:ShouldShowPrimaryKeybind()
    return false
end

function ZO_ReturningPlayerIntroScreen_Keyboard:OnPrimaryKeyPressed()
    -- Must be overridden, no current functionality
end

function ZO_ReturningPlayerIntroScreen_Keyboard.OnControlInitialized(control)
    RETURNING_PLAYER_INTRO_SCREEN_KEYBOARD = ZO_ReturningPlayerIntroScreen_Keyboard:New(control)
end

function ZO_ReturningPlayerIntroScreen_Keyboard.IntroReward_OnMouseEnter(control)
    ZO_Rewards_Shared_OnMouseEnter(control, RIGHT, LEFT, -5)
    ZO_GridEntry_SetIconScaledUp(control, true)
end

function ZO_ReturningPlayerIntroScreen_Keyboard.IntroReward_OnMouseExit(control)
    ZO_Rewards_Shared_OnMouseExit(control)
    ZO_GridEntry_SetIconScaledUp(control, false)
end
