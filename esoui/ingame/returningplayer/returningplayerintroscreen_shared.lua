ZO_ReturningPlayerIntroScreen_Shared = ZO_DeferredInitializingObject:Subclass()

function ZO_ReturningPlayerIntroScreen_Shared:Initialize(control, scene, rewardTemplate)
    self.control = control

    ZO_DeferredInitializingObject.Initialize(self, scene)

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)

    self.rewardTemplate = rewardTemplate
end

function ZO_ReturningPlayerIntroScreen_Shared:OnDeferredInitialize()
    self.headerLabel = self.control:GetNamedChild("HeaderText")
    local headerText = zo_strformat(SI_RETURNING_PLAYER_HEADER, GetUnitDisplayName("player"))
    self.headerLabel:SetText(headerText)

    self.bodyTextLabel = self.control:GetNamedChild("BodyText")
    local activityName = GetReturningPlayerIntroGameplayDisplayName()
    local bodyText = zo_strformat(SI_RETURNING_PLAYER_INTRO_BODY, activityName)
    self.bodyTextLabel:SetText(bodyText)

    local infoContainer = self.control:GetNamedChild("GameplayInfo")
    self.gameplayTitleLabel = infoContainer:GetNamedChild("Title")
    self.gameplayDescriptionLabel = infoContainer:GetNamedChild("Description")
    self.rewardContainer = infoContainer:GetNamedChild("Rewards")

    local titleText = zo_strformat(SI_RETURNING_PLAYER_GAMEPLAY_EXPERIENCE_NAME_FORMATTER, activityName)
    self.gameplayTitleLabel:SetText(titleText)

    local descriptionText = GetReturningPlayerIntroGameplayDescription()
    self.gameplayDescriptionLabel:SetText(descriptionText)

    self:InitializeGridList()

    local function CloseScreenCallback()
        if ShouldShowReturningPlayerLeaveIntroPrompt() then
            ZO_Dialogs_ShowPlatformDialog("CONFIRM_LEAVE_RETURNING_PLAYER_INTRO")
        else
            SYSTEMS:ShowScene("returningPlayerRewards")
        end
    end

    self.closeKeybindButton = self.control:GetNamedChild("Close")

    self.closeKeybindDescriptor =
    {
        name = GetString(SI_DIALOG_EXIT),
        keybind = "UI_SHORTCUT_EXIT",
        ethereal = true,
        narrateEthereal = true,
        etherealNarrationOrder = 2,
        callback = CloseScreenCallback,
    }
    self.closeKeybindButton:SetKeybindButtonDescriptor(self.closeKeybindDescriptor)

    self.primaryKeybindButton = self.control:GetNamedChild("Primary")

    local function ShouldShowPrimaryKeybind()
        return self:ShouldShowPrimaryKeybind()
    end

    self.primaryKeybindDescriptor =
    {
        name = function()
            return self:GetPrimaryKeybindName()
        end,
        keybind = "UI_SHORTCUT_PRIMARY",
        ethereal = true,
        narrateEthereal = ShouldShowPrimaryKeybind,
        etherealNarrationOrder = 1,
        callback = function()
            self:OnPrimaryKeyPressed()
        end,
        visible = ShouldShowPrimaryKeybind,
    }
    self.primaryKeybindButton:SetKeybindButtonDescriptor(self.primaryKeybindDescriptor)

    local backKeybindDescriptor = KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(CloseScreenCallback)
    backKeybindDescriptor.ethereal = true
    backKeybindDescriptor.narrateEthereal = false

    self.keybindStripDescriptor =
    {
        self.closeKeybindDescriptor,
        self.primaryKeybindDescriptor,
        backKeybindDescriptor,
    }
end

function ZO_ReturningPlayerIntroScreen_Shared:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdateKeybindVisibility()
end

function ZO_ReturningPlayerIntroScreen_Shared:UpdateKeybindVisibility()
    self.primaryKeybindButton:UpdateVisibility()
end

function ZO_ReturningPlayerIntroScreen_Shared:OnShowing()
    KEYBIND_STRIP:RemoveDefaultExit()

    self:UpdateGridList()
    self:UpdateKeybindVisibility()
end

function ZO_ReturningPlayerIntroScreen_Shared:OnShown()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_ReturningPlayerIntroScreen_Shared:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    FlagReturningPlayerAnnouncementSeen()
end

function ZO_ReturningPlayerIntroScreen_Shared:OnHidden()
    KEYBIND_STRIP:RestoreDefaultExit()
end

function ZO_ReturningPlayerIntroScreen_Shared:GetIntroCampaignRewards()
    local rewardData = RETURNING_PLAYER_MANAGER:GetIntroCampaignRewardData()
    if rewardData then
        if rewardData:GetRewardType() == REWARD_ENTRY_TYPE_REWARD_LIST then
            local rewardId = rewardData:GetRewardId()
            local rewardListId = GetRewardListIdFromReward(rewardId)
            return REWARDS_MANAGER:GetAllRewardInfoForRewardList(rewardListId)
        else
            return { rewardData }
        end
    end

    return {}
end

ZO_ReturningPlayerIntroScreen_Shared:MUST_IMPLEMENT("InitializeGridList")
ZO_ReturningPlayerIntroScreen_Shared:MUST_IMPLEMENT("GetPrimaryKeybindName")
ZO_ReturningPlayerIntroScreen_Shared:MUST_IMPLEMENT("OnPrimaryKeyPressed")
ZO_ReturningPlayerIntroScreen_Shared:MUST_IMPLEMENT("ShouldShowPrimaryKeybind")

function ZO_ReturningPlayerIntroScreen_Shared:UpdateGridList()
    self.rewardGridList:ClearGridList()

    local rewards = self:GetIntroCampaignRewards()
    for index, reward in ipairs(rewards) do
        local rewardEntry = ZO_GridSquareEntryData_Shared:New(reward)
        self.rewardGridList:AddEntry(rewardEntry)
    end

    self.rewardGridList:CommitGridList()
end

function ZO_ReturningPlayerIntroScreen_Shared.RewardGridEntrySetup(control, data, selected)
    control.data = data
    control.icon:SetTexture(data:GetPlatformIcon())
    if data:GetQuantity() > 1 then
        local quantity = data:GetAbbreviatedQuantity()
        control.quantityLabel:SetText(quantity)
        control.quantityLabel:SetHidden(false)
    else
        control.quantityLabel:SetHidden(true)
    end
end
