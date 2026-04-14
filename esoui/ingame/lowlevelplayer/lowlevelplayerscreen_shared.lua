ZO_LowLevelPlayerScreen_Shared = ZO_DeferredInitializingObject:Subclass()

function ZO_LowLevelPlayerScreen_Shared:Initialize(control, scene)
    self.control = control

    ZO_DeferredInitializingObject.Initialize(self, scene)

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)

    scene:SetHideSceneConfirmationCallback(function(...) self:OnConfirmHideScene(...) end)
end

function ZO_LowLevelPlayerScreen_Shared:OnDeferredInitialize()
    self.headerLabel = self.control:GetNamedChild("HeaderText")
    local headerText = zo_strformat(SI_LOW_LEVEL_PLAYER_HEADER, GetUnitDisplayName("player"))
    self.headerLabel:SetText(headerText)

    self.bodyTextLabel = self.control:GetNamedChild("BodyText")
    local campaignNameText = PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:GetCampaignDisplayName()
    local promotionalEventNameText = PROMOTIONAL_EVENT_MANAGER:GetPromotionalEventsColorizedDisplayName()
    local bodyText = zo_strformat(SI_LOW_LEVEL_PLAYER_BODY, campaignNameText, promotionalEventNameText)
    self.bodyTextLabel:SetText(bodyText)

    local infoContainer = self.control:GetNamedChild("GameplayInfo")
    self.gameplayBackgroundTexture = infoContainer:GetNamedChild("Background")
    self.gameplayTitleLabel = infoContainer:GetNamedChild("Title")
    self.gameplayTimeRemainingLabel = infoContainer:GetNamedChild("TimeRemaining")
    self.gameplayDescriptionLabel = infoContainer:GetNamedChild("Description")
    self.rewardContainer = infoContainer:GetNamedChild("Rewards")

    self:InitializeGridList()

    local function CloseScreenCallback()
        SCENE_MANAGER:ShowBaseScene()
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

function ZO_LowLevelPlayerScreen_Shared:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdateKeybindVisibility()
end

function ZO_LowLevelPlayerScreen_Shared:UpdateKeybindVisibility()
    self.primaryKeybindButton:UpdateVisibility()
end

function ZO_LowLevelPlayerScreen_Shared:OnShowing()
    KEYBIND_STRIP:RemoveDefaultExit()
    
    local backgroundTextureFile
    local titleText
    local descriptionText
    if PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsIntroCampaignComplete() or IsActiveWorldStarterWorld() then
        backgroundTextureFile = "EsoUI/Art/PromotionalEvent/lowLevelPlayer_Gameplay.dds"
        titleText = PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:GetCampaignDisplayName()
        descriptionText = PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:GetCampaignDescription()
    else
        backgroundTextureFile = "EsoUI/Art/ReturningPlayer/IntroBackground.dds"
        titleText = zo_strformat(SI_INTRO_GAMEPLAY_EXPERIENCE_NAME_FORMATTER, GetIntroGameplayExperienceDisplayName())
        descriptionText = GetIntroGameplayExperienceDescription()
    end
    self.gameplayBackgroundTexture:SetTexture(backgroundTextureFile)
    self.gameplayTitleLabel:SetText(titleText)
    local remainingTimeText = PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:GetCampaignRemainingTimeDisplayText()
    self.gameplayTimeRemainingLabel:SetText(remainingTimeText)
    self.gameplayDescriptionLabel:SetText(descriptionText)

    self:UpdateGridList()
    self:UpdateKeybindVisibility()

    LOW_LEVEL_PLAYER_MANAGER:MarkRewardsAsSeen()
end

function ZO_LowLevelPlayerScreen_Shared:OnShown()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_LowLevelPlayerScreen_Shared:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    FlagPromotionalEventPersonalCampaignAnnouncementSeen()
end

function ZO_LowLevelPlayerScreen_Shared:OnHidden()
    KEYBIND_STRIP:RestoreDefaultExit()
end

function ZO_LowLevelPlayerScreen_Shared:OnConfirmHideScene(scene, nextSceneName, bypassHideSceneConfirmationReason)
    if bypassHideSceneConfirmationReason == nil and not PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:IsIntroCampaignComplete() and ShouldShowPromotionalEventPersonalCampaignLeaveIntroPrompt() then
        ZO_Dialogs_ShowPlatformDialog("CONFIRM_LEAVE_PERSONAL_CAMPAIGN_INTRO",
        {
            confirmCallback = function() scene:AcceptHideScene() end,
            declineCallback = function() scene:RejectHideScene() end,
        },
        {
            mainTextParams = 
            {
                PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:GetWhiteIntroGameplayDisplayName(),
                PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:GetColorizedCampaignDisplayName()
            },
        })
    else
        scene:AcceptHideScene()
    end
end

function ZO_LowLevelPlayerScreen_Shared:GetRewards()
    return PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:GetPrimaryRewards()
end

function ZO_LowLevelPlayerScreen_Shared:RequestJumpToIntroGameplay()
    MarkPromotionalEventPersonalCampaignLeaveIntroPromptShown()
    RequestJumpToIntroGameplayExperience()
end

ZO_LowLevelPlayerScreen_Shared:MUST_IMPLEMENT("InitializeGridList")
ZO_LowLevelPlayerScreen_Shared:MUST_IMPLEMENT("GetPrimaryKeybindName")
ZO_LowLevelPlayerScreen_Shared:MUST_IMPLEMENT("OnPrimaryKeyPressed")
ZO_LowLevelPlayerScreen_Shared:MUST_IMPLEMENT("ShouldShowPrimaryKeybind")

function ZO_LowLevelPlayerScreen_Shared:UpdateGridList()
    self.rewardGridList:ClearGridList()

    local rewards = self:GetRewards()
    for index, reward in ipairs(rewards) do
        local rewardEntry = ZO_GridSquareEntryData_Shared:New(reward)
        self.rewardGridList:AddEntry(rewardEntry)
    end

    self.rewardGridList:CommitGridList()
end

function ZO_LowLevelPlayerScreen_Shared.RewardGridEntrySetup(control, data, selected)
    control.data = data
    control.icon:SetTexture(data:GetPlatformLootIcon())

    if data:GetRewardType() == REWARD_ENTRY_TYPE_REWARD_LIST then
        local quantity = GetNumRewardListEntries(GetRewardListIdFromReward(data:GetRewardId()))
        local shouldHideQuantityLabel = not (quantity > 1)
        if not shouldHideQuantityLabel then
            quantity = zo_strformat(SI_PROMOTIONAL_EVENT_REWARD_LIST_QUANTITY_FORMATTER, quantity - 1)
            control.quantityLabel:SetText(quantity)
        end
        control.quantityLabel:SetHidden(shouldHideQuantityLabel)
    elseif data:GetQuantity() > 1 then
        local quantity = data:GetAbbreviatedQuantity()
        control.quantityLabel:SetText(quantity)
        control.quantityLabel:SetHidden(false)
    else
        control.quantityLabel:SetHidden(true)
    end

    local alpha = data.claimed and 0.4 or 1
    control.icon:SetAlpha(alpha)
    control.quantityLabel:SetAlpha(alpha)
    control.claimedMarkTexture:SetHidden(not data.claimed)
end
