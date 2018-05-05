ZO_LevelUpRewardsPostClaim_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_LevelUpRewardsPostClaim_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_LevelUpRewardsPostClaim_Gamepad:Initialize(control)
    ZO_GAMEPAD_POST_CLAIM_LEVEL_UP_REWARDS_SCENE = ZO_Scene:New("LevelUpRewardsPostClaimGamepad", SCENE_MANAGER)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, ZO_GAMEPAD_POST_CLAIM_LEVEL_UP_REWARDS_SCENE)

    ZO_GAMEPAD_POST_CLAIM_LEVEL_UP_REWARDS_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    ZO_GAMEPAD_POST_CLAIM_LEVEL_UP_REWARDS_FRAGMENT:SetHideOnSceneHidden(true)
    self.scene:AddFragment(ZO_GAMEPAD_POST_CLAIM_LEVEL_UP_REWARDS_FRAGMENT)

    self.list = self:GetMainList()

    self:SetListsUseTriggerKeybinds(true)

    self:InitializeHeader()
end

function ZO_LevelUpRewardsPostClaim_Gamepad:OnDeferredInitialize()

end

function ZO_LevelUpRewardsPostClaim_Gamepad:InitializeHeader()
    self.headerData = {
        titleText = GetString(SI_LEVEL_UP_REWARDS_GAMEPAD_POST_CLAIM_HEADER),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_LevelUpRewardsPostClaim_Gamepad:PerformUpdate()
    self:RefreshList()

    self.dirty = false
end

function ZO_LevelUpRewardsPostClaim_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    if HasUpcomingLevelUpReward() then
        ZO_GAMEPAD_UPCOMING_LEVEL_UP_REWARDS:Show()
    end
end

function ZO_LevelUpRewardsPostClaim_Gamepad:OnHide()
    ZO_Gamepad_ParametricList_Screen.OnHide(self)

    ZO_GAMEPAD_UPCOMING_LEVEL_UP_REWARDS:Hide()
end

function ZO_LevelUpRewardsPostClaim_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select
        {
            name = GetString(SI_LEVEL_UP_REWARDS_GAMEPAD_POST_CLAIM_CONTINUE_KEYBIND),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                SCENE_MANAGER:Show(GAMEPAD_SKILLS_ROOT_SCENE:GetName())
            end,
        },
    }
end

function ZO_LevelUpRewardsPostClaim_Gamepad:RefreshList()
    self.list:Clear()

    if HasUpcomingLevelUpReward() then
        local upcomingRewardsEntry = ZO_GamepadEntryData:New(GetString(SI_LEVEL_UP_REWARDS_UPCOMING_REWARDS_HEADER))
        self.list:AddEntry("ZO_GamepadMenuEntryTemplate", upcomingRewardsEntry)
    end

    self.list:Commit()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

--
--[[ XML Handlers ]]--
--

function ZO_PostClaimLevelUpRewards_Gamepad_OnInitialized(control)
    ZO_GAMEPAD_POST_CLAIM_LEVEL_UP_REWARDS = ZO_LevelUpRewardsPostClaim_Gamepad:New(control)
end
