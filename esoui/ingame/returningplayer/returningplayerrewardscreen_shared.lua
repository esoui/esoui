ZO_ReturningPlayerRewardScreen_Shared = ZO_DeferredInitializingObject:Subclass()

function ZO_ReturningPlayerRewardScreen_Shared:Initialize(control, scene)
    self.control = control

    ZO_DeferredInitializingObject.Initialize(self, scene)

    self.targetedClaimData = nil

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)
end

function ZO_ReturningPlayerRewardScreen_Shared:OnDeferredInitialize()
    self.headerLabel = self.control:GetNamedChild("HeaderText")
    local headerText = zo_strformat(SI_RETURNING_PLAYER_HEADER, GetUnitDisplayName("player"))
    self.headerLabel:SetText(headerText)

    local function CloseScreenCallback()
        SCENE_MANAGER:HideCurrentScene()
    end

    local loginBonusContainer = self.control:GetNamedChild("LoginBonus")
    self.loginRewardContainer = loginBonusContainer:GetNamedChild("Rewards")
    self.loginBonusTitleLabel = loginBonusContainer:GetNamedChild("Title")
    self.loginBonusTitleLabel:SetText(GetString(SI_RETURNING_PLAYER_DAILY_LOGIN_REWARDS_TITLE))
    self.loginBonusClaimHeaderLabel = loginBonusContainer:GetNamedChild("ClaimHeader")

    local campaignInfoContainer = self.control:GetNamedChild("CampaignInfo")
    self.primaryRewardContainer = campaignInfoContainer:GetNamedChild("Rewards")
    self.campaignInfoTitleLabel = campaignInfoContainer:GetNamedChild("Title")

    self.subHeaderTitle = self.control:GetNamedChild("SubHeaderTitle")
    self.subHeaderTimeRemaining = self.control:GetNamedChild("SubHeaderTimeRemaining")
    self.bodyTextLabel = self.control:GetNamedChild("BodyText")

    self:InitializeGridLists()
    self:InitializeParticleSystems()

    self.closeKeybindButton = self.control:GetNamedChild("Close")

    self.closeKeybindDescriptor =
    {
        name = GetString(SI_DIALOG_EXIT),
        keybind = "UI_SHORTCUT_EXIT",
        ethereal = true,
        narrateEthereal = true,
        etherealNarrationOrder = 3,
        callback = CloseScreenCallback,
    }
    self.closeKeybindButton:SetKeybindButtonDescriptor(self.closeKeybindDescriptor)

    self.primaryKeybindButton = self.control:GetNamedChild("Primary")

    local function ShouldShowPrimaryKeybind()
        return self:ShouldShowPrimaryKeybind()
    end

    self.primaryKeybindDescriptor =
    {
        name = GetString(SI_RETURNING_PLAYER_CLAIM_ACTION),
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

    self.backKeybindDescriptor = KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(CloseScreenCallback)
    self.backKeybindDescriptor.ethereal = true
    self.backKeybindDescriptor.narrateEthereal = false

    self.keybindStripDescriptor =
    {
        self.closeKeybindDescriptor,
        self.primaryKeybindDescriptor,
        self.backKeybindDescriptor,
    }

    RETURNING_PLAYER_MANAGER:RegisterCallback("DailyRewardClaimed", ZO_GetCallbackForwardingFunction(self, self.OnDailyRewardClaimed))
end

function ZO_ReturningPlayerRewardScreen_Shared:InitializeParticleSystems()
    self.blastParticleSystem = ZO_BlastParticleSystem:New()
    self.blastParticleSystem:SetSound(SOUNDS.DAILY_LOGIN_REWARDS_CLAIM_FANFARE)

    self.particleGeneratorPositionControl = self.control:GetNamedChild("RewardParticleGeneratorPosition")
    self.blastParticleSystem:SetParentControl(self.particleGeneratorPositionControl)
end

function ZO_ReturningPlayerRewardScreen_Shared:ShowClaimedRewardFlair()
    if self.targetedClaimData then
        local claimedControl = self.loginRewardGridList:GetControlFromData(self.targetedClaimData)
        self.particleGeneratorPositionControl:ClearAnchors()
        self.particleGeneratorPositionControl:SetAnchor(CENTER, claimedControl, CENTER, 0, -10)
        self.blastParticleSystem:Start()

        ZO_CraftingResults_Base_PlayPulse(claimedControl)
        self:SetTargetedClaimData(nil)
    end
end

function ZO_ReturningPlayerRewardScreen_Shared:OnDailyRewardClaimed()
    if self:IsShowing() then
        self:UpdateLoginRewardGridList()
        self:UpdateKeybinds()
        self:ShowClaimedRewardFlair()
        self:UpdateLoginBonusClaimHeader()
    end
end

function ZO_ReturningPlayerRewardScreen_Shared:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdateKeybindVisibility()
end

function ZO_ReturningPlayerRewardScreen_Shared:UpdateKeybindVisibility()
    self.primaryKeybindButton:UpdateVisibility()
end

function ZO_ReturningPlayerRewardScreen_Shared:OnShowing()
    KEYBIND_STRIP:RemoveDefaultExit()

    EVENT_MANAGER:RegisterForUpdate(self.scene:GetName(), ZO_ONE_MINUTE_IN_MILLISECONDS, function() self:OnUpdate() end)
    self:OnUpdate()

    self:UpdateDisplayText()
    self:UpdateLoginRewardGridList()
    self:UpdatePrimaryRewardGridList()
    self:UpdateKeybindVisibility()
end

function ZO_ReturningPlayerRewardScreen_Shared:OnShown()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_ReturningPlayerRewardScreen_Shared:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

    EVENT_MANAGER:UnregisterForUpdate(self.scene:GetName())
    self.blastParticleSystem:Stop()

    FlagReturningPlayerAnnouncementSeen()
end

function ZO_ReturningPlayerRewardScreen_Shared:OnHidden()
    KEYBIND_STRIP:RestoreDefaultExit()
end

ZO_ReturningPlayerRewardScreen_Shared:MUST_IMPLEMENT("InitializeGridLists")
ZO_ReturningPlayerRewardScreen_Shared:MUST_IMPLEMENT("OnPrimaryKeyPressed")
ZO_ReturningPlayerRewardScreen_Shared:MUST_IMPLEMENT("ShouldShowPrimaryKeybind")

function ZO_ReturningPlayerRewardScreen_Shared:UpdateDisplayText()
    local subheaderTitleText = zo_strformat(SI_RETURNING_PLAYER_SUBHEADER_TITLE, RETURNING_PLAYER_MANAGER:GetIntroCampaignDisplayName())
    self.subHeaderTitle:SetText(subheaderTitleText)

    local campaignDisplayName = RETURNING_PLAYER_MANAGER:GetColorizedIntroCampaignDisplayName()
    local titleText = zo_strformat(SI_RETURNING_PLAYER_CAMPAIGN_NAME_FORMATTER, campaignDisplayName)
    self.campaignInfoTitleLabel:SetText(titleText)

    local remainingTimeText = RETURNING_PLAYER_MANAGER:GetCampaignRemainingTimeDisplayText()
    self.subHeaderTimeRemaining:SetText(remainingTimeText)

    local campaignDescriptionText = RETURNING_PLAYER_MANAGER:GetCampaignRewardsDescriptionText()
    self.bodyTextLabel:SetText(campaignDescriptionText)
end

function ZO_ReturningPlayerRewardScreen_Shared:UpdatePrimaryRewardGridList()
    self.primaryRewardGridList:ClearGridList()

    local rewards = RETURNING_PLAYER_MANAGER:GetPrimaryRewards()
    for index, reward in ipairs(rewards) do
        local rewardEntry = ZO_GridSquareEntryData_Shared:New(reward)
        self.primaryRewardGridList:AddEntry(rewardEntry)
    end

    self.primaryRewardGridList:CommitGridList()
end

function ZO_ReturningPlayerRewardScreen_Shared:UpdateLoginRewardGridList()
    self.loginRewardGridList:ClearGridList()

    local rewards = RETURNING_PLAYER_MANAGER:GetDailyLoginRewards()
    for index, reward in ipairs(rewards) do
        local rewardEntry = ZO_GridSquareEntryData_Shared:New(reward)
        self.loginRewardGridList:AddEntry(rewardEntry)
    end

    self.loginRewardGridList:CommitGridList()
end

function ZO_ReturningPlayerRewardScreen_Shared:GetDailyLoginRewardClaimText()
    local claimableRewardIndex = GetReturningPlayerDailyLoginClaimableRewardIndex()
    if claimableRewardIndex ~= nil then
        return GetString(SI_RETURNING_PLAYER_DAILY_LOGIN_REWARDS_CLAIMABLE_LABEL)
    end

    local numRewards = GetNumReturningPlayerDailyLoginRewards()
    local numClaimedRewards = GetNumReturningPlayerDailyLoginRewardsClaimed()
    local hasUnclaimedRewards = numClaimedRewards < numRewards
    if hasUnclaimedRewards then
        local timeRemaining = GetTimeUntilNextReturningPlayerDailyLoginRewardClaimS()
        timeRemaining = ZO_FormatTime(timeRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS)
        return zo_strformat(SI_RETURNING_PLAYER_DAILY_LOGIN_REWARDS_NEXT_CLAIMABLE_LABEL, ZO_SELECTED_TEXT:Colorize(timeRemaining))
    end

    return GetString(SI_RETURNING_PLAYER_DAILY_LOGIN_REWARDS_ALL_CLAIMED_LABEL)
end

function ZO_ReturningPlayerRewardScreen_Shared:UpdateLoginBonusClaimHeader()
    local claimHeaderText = self:GetDailyLoginRewardClaimText()
    self.loginBonusClaimHeaderLabel:SetText(claimHeaderText)
end

function ZO_ReturningPlayerRewardScreen_Shared:OnUpdate()
    self:UpdateLoginBonusClaimHeader()
end

function ZO_ReturningPlayerRewardScreen_Shared:SetTargetedClaimData(claimData)
    self.targetedClaimData = claimData
end

function ZO_ReturningPlayerRewardScreen_Shared.RewardGridEntrySetup(control, data, selected)
    control.data = data

    if data.claimed then
        control.completeMark:SetHidden(false)
        control.icon:SetHidden(true)
        control.quantityLabel:SetHidden(true)
    else
        control.completeMark:SetHidden(true)
        control.icon:SetHidden(false)
        control.icon:SetTexture(data:GetPlatformIcon())
        if data:GetQuantity() > 1 then
            local quantity = data:GetAbbreviatedQuantity()
            control.quantityLabel:SetText(quantity)
            control.quantityLabel:SetHidden(false)
        else
            control.quantityLabel:SetHidden(true)
        end
        if data.type == ZO_RETURNING_PLAYER_REWARD_TYPE.DAILY_REWARD then
            if data.index > GetNumClaimableReturningPlayerRewards() then
                control.icon:SetDesaturation(1)
            else
                control.icon:SetDesaturation(0)
            end
        else
            control.icon:SetDesaturation(0)
        end
    end
end

function ZO_ReturningPlayerRewardScreen_Shared.DailyLoginRewardGridEntrySetup(control, data, selected)
    ZO_ReturningPlayerRewardScreen_Shared.RewardGridEntrySetup(control, data, selected)
    local dayText = zo_strformat(SI_RETURNING_PLAYER_DAILY_LOGIN_DAY_LABEL, ZO_SELECTED_TEXT:Colorize(data.index))
    control.dayLabel:SetText(dayText)

    if GetReturningPlayerDailyLoginClaimableRewardIndex() == data.index then
        if not control.backdrop.pendingLoop then
            ZO_PendingLoop.ApplyToControl(control.backdrop)
        end
    else
        if control.backdrop.pendingLoop then
            control.backdrop.pendingLoop:ReleaseObject()
        end
    end
end

function ZO_ReturningPlayerRewardScreen_Shared.AreLoginRewardEntriesEqual(data1, data2)
    return data1.index == data2.index
end

function ZO_ReturningPlayerRewardScreen_Shared.DailyLoginRewardGridEntryReset(control)
    ZO_ObjectPool_DefaultResetControl(control)

    if control.backdrop.pendingLoop then
        control.backdrop.pendingLoop:ReleaseObject()
    end
end
