ZO_RETURNING_PLAYER_REWARDS_REWARD_DIMENSIONS_KEYBOARD = 116
ZO_RETURNING_PLAYER_REWARDS_REWARD_SPACING_KEYBOARD = 5
ZO_RETURNING_PLAYER_REWARDS_DAILY_REWARD_HEIGHT_KEYBOARD = 145
ZO_RETURNING_PLAYER_REWARDS_GRID_WIDTH_KEYBOARD = ZO_RETURNING_PLAYER_REWARDS_REWARD_DIMENSIONS_KEYBOARD * 5 + ZO_RETURNING_PLAYER_REWARDS_REWARD_SPACING_KEYBOARD * 4 + ZO_SCROLL_BAR_WIDTH
ZO_RETURNING_PLAYER_REWARDS_GRID_HEIGHT_KEYBOARD = ZO_RETURNING_PLAYER_REWARDS_REWARD_DIMENSIONS_KEYBOARD + 2
ZO_RETURNING_PLAYER_REWARDS_DAILY_LOGIN_GRID_HEIGHT_KEYBOARD = ZO_RETURNING_PLAYER_REWARDS_DAILY_REWARD_HEIGHT_KEYBOARD + 2

ZO_ReturningPlayerRewardScreen_Keyboard = ZO_ReturningPlayerRewardScreen_Shared:Subclass()

function ZO_ReturningPlayerRewardScreen_Keyboard:Initialize(control)
    RETURNING_PLAYER_REWARD_SCENE_KEYBOARD = ZO_Scene:New("ReturningPlayerRewardSceneKeyboard", SCENE_MANAGER)

    ZO_ReturningPlayerRewardScreen_Shared.Initialize(self, control, RETURNING_PLAYER_REWARD_SCENE_KEYBOARD)

    SYSTEMS:RegisterKeyboardRootScene("returningPlayerRewards", self.scene)
end

function ZO_ReturningPlayerRewardScreen_Keyboard:OnDeferredInitialize()
    ZO_ReturningPlayerRewardScreen_Shared.OnDeferredInitialize(self)

    self.goToPromotionalEventButton = self.control:GetNamedChild("GoToPromotionalEvent")
    local promotionalEventNameText = PROMOTIONAL_EVENT_MANAGER:GetPromotionalEventsColorizedDisplayName()
    self.goToPromotionalEventButton:SetText(zo_strformat(SI_RETURNING_PLAYER_REWARDS_NAVIGATION_ACTION, promotionalEventNameText))

    ApplyTemplateToControl(self.closeKeybindButton, "ZO_KeybindButton_Keyboard_Template")
    ApplyTemplateToControl(self.primaryKeybindButton, "ZO_KeybindButton_Keyboard_Template")
end

function ZO_ReturningPlayerRewardScreen_Keyboard:InitializeGridLists()
    local function RewardGridEntryReset(control)
        ZO_ReturningPlayerRewardScreen_Shared.DailyLoginRewardGridEntryReset(control)

        ZO_GridEntry_SetIconScaledUpInstantly(control, false)
    end

    local DEFAULT_HIDE_CALLBACK = nil

    self.loginRewardGridList = ZO_SingleTemplateGridScrollList_Keyboard:New(self.loginRewardContainer, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL)
    self.loginRewardGridList:SetGridEntryTemplate("ZO_ReturningPlayerDailyReward_Keyboard", ZO_RETURNING_PLAYER_REWARDS_REWARD_DIMENSIONS_KEYBOARD, ZO_RETURNING_PLAYER_REWARDS_DAILY_REWARD_HEIGHT_KEYBOARD, self.DailyLoginRewardGridEntrySetup, DEFAULT_HIDE_CALLBACK, RewardGridEntryReset, ZO_RETURNING_PLAYER_REWARDS_REWARD_SPACING_KEYBOARD, ZO_RETURNING_PLAYER_REWARDS_REWARD_SPACING_KEYBOARD)
    self.loginRewardGridList:SetEntryTemplateEqualityFunction("ZO_ReturningPlayerDailyReward_Keyboard", ZO_ReturningPlayerRewardScreen_Shared.AreLoginRewardEntriesEqual)

    self.primaryRewardGridList = ZO_SingleTemplateGridScrollList_Keyboard:New(self.primaryRewardContainer, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL)
    self.primaryRewardGridList:SetGridEntryTemplate("ZO_ReturningPlayerRewardsReward_Keyboard", ZO_RETURNING_PLAYER_REWARDS_REWARD_DIMENSIONS_KEYBOARD, ZO_RETURNING_PLAYER_REWARDS_REWARD_DIMENSIONS_KEYBOARD, self.RewardGridEntrySetup, DEFAULT_HIDE_CALLBACK, RewardGridEntryReset, ZO_RETURNING_PLAYER_REWARDS_REWARD_SPACING_KEYBOARD, ZO_RETURNING_PLAYER_REWARDS_REWARD_SPACING_KEYBOARD)
end

function ZO_ReturningPlayerRewardScreen_Keyboard:ShouldShowPrimaryKeybind()
    if self.mouseOverReward == nil then
        return false
    end

    local rewardData = self.mouseOverReward.data
    if rewardData.type ~= ZO_RETURNING_PLAYER_REWARD_TYPE.DAILY_REWARD then
        return false
    end

    local claimableRewardIndex = GetReturningPlayerDailyLoginClaimableRewardIndex()
    if claimableRewardIndex == nil or claimableRewardIndex ~= rewardData.index then
        return false
    end

    return true
end

function ZO_ReturningPlayerRewardScreen_Keyboard:OnPrimaryKeyPressed()
    ClaimCurrentReturningPlayerDailyLoginReward()
    self:SetTargetedClaimData(self.mouseOverReward.data)
end

function ZO_ReturningPlayerRewardScreen_Keyboard:OnMouseEnterReward(control)
    self.mouseOverReward = control
    self:UpdateKeybinds()

    ZO_GridEntry_SetIconScaledUp(control, true)
end

function ZO_ReturningPlayerRewardScreen_Keyboard:OnMouseExitReward(control)
    self.mouseOverReward = nil
    self:UpdateKeybinds()

    ZO_GridEntry_SetIconScaledUp(control, false)
end

function ZO_ReturningPlayerRewardScreen_Keyboard:OnMouseUp(control)
    local claimableIndex = GetReturningPlayerDailyLoginClaimableRewardIndex()
    if control.data.index == claimableIndex then
        self:OnPrimaryKeyPressed()
    end
end

function ZO_ReturningPlayerRewardScreen_Keyboard:OnShowing()
    ZO_ReturningPlayerRewardScreen_Shared.OnShowing(self)

    PlaySound(SOUNDS.RETURNING_PLAYER_OPEN_KEYBOARD)
end

function ZO_ReturningPlayerRewardScreen_Keyboard:OnHiding()
    ZO_ReturningPlayerRewardScreen_Shared.OnHiding(self)

    PlaySound(SOUNDS.RETURNING_PLAYER_CLOSE_KEYBOARD)
end

function ZO_ReturningPlayerRewardScreen_Keyboard:OnHidden()
    ZO_ReturningPlayerRewardScreen_Shared.OnHidden(self)

    self.mouseOverReward = nil
end

----
-- XML Functions
----

function ZO_ReturningPlayerRewardScreen_Keyboard.OnControlInitialized(control)
    RETURNING_PLAYER_REWARD_SCREEN_KEYBOARD = ZO_ReturningPlayerRewardScreen_Keyboard:New(control)
end

function ZO_ReturningPlayerRewardScreen_Keyboard.IntroReward_OnMouseEnter(control)
    ZO_Rewards_Shared_OnMouseEnter(control, RIGHT, LEFT, -5)

    RETURNING_PLAYER_REWARD_SCREEN_KEYBOARD:OnMouseEnterReward(control)
end

function ZO_ReturningPlayerRewardScreen_Keyboard.IntroReward_OnMouseExit(control)
    ZO_Rewards_Shared_OnMouseExit(control)

    RETURNING_PLAYER_REWARD_SCREEN_KEYBOARD:OnMouseExitReward(control)
end

function ZO_ReturningPlayerRewardScreen_Keyboard.IntroReward_OnMouseUp(control)
    RETURNING_PLAYER_REWARD_SCREEN_KEYBOARD:OnMouseUp(control)
end

function ZO_ReturningPlayerRewardScreen_Keyboard.GoToPromotionalEvent_OnClicked(control)
    RETURNING_PLAYER_MANAGER:GoToPromotionalEvents()
end
