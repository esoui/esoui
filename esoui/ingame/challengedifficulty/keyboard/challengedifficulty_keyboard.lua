ZO_CHALLENGE_DIFFICULTY_KEYBOARD_SCREEN_WIDTH = 500
ZO_CHALLENGE_DIFFICULTY_KEYBOARD_SCREEN_HEIGHT = 475
ZO_CHALLENGE_DIFFICULTY_HORIZONTAL_PADDING = 20

ZO_ChallengeDifficultyScreen_Keyboard = ZO_InitializingObject:Subclass()

function ZO_ChallengeDifficultyScreen_Keyboard:Initialize(control)
    self.control = control
    self.goToLevelUpRewardsButton = self.control:GetNamedChild("GoToLevelUpRewardsButton")
    self.goToDifficultyButton = control:GetNamedChild("GoToDifficultyButton")
    self.nameLabel = self.control:GetNamedChild("DifficultyName")
    self.descriptionLabel = self.control:GetNamedChild("DifficultyDescription")
    self.changeDifficultyButton = self.control:GetNamedChild("ChangeDifficultyButton")
    self.difficultyEffectsLabel = self.control:GetNamedChild("DifficultyEffects")

    ZO_CHALLENGE_DIFFICULTY_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    ZO_CHALLENGE_DIFFICULTY_KEYBOARD_FRAGMENT:RegisterCallback("StateChange",
                                                function(oldState, newState)
                                                    if newState == SCENE_FRAGMENT_SHOWING then
                                                        self:OnShowing()
                                                    end
                                                end)

    self:ResetPendingDifficulty()
    self:InitializeTabs()
    self:InitializeDifficultyButtons()
    self:RegisterForEvents()
end

function ZO_ChallengeDifficultyScreen_Keyboard:InitializeTabs()
    self.levelUpRewardsRadioButtonGroup = ZO_RadioButtonGroup:New()
    self.levelUpRewardsRadioButtonGroup:Add(self.goToLevelUpRewardsButton)
    self.levelUpRewardsRadioButtonGroup:Add(self.goToDifficultyButton)
end

function ZO_ChallengeDifficultyScreen_Keyboard:InitializeDifficultyButtons()
    self.difficultyButtons =
    {
        [OVERLAND_DIFFICULTY_TYPE_BASEGAME] = self.control:GetNamedChild("RadioContainerBaseGame"),
        [OVERLAND_DIFFICULTY_TYPE_JOURNEYMAN] = self.control:GetNamedChild("RadioContainerJourneyman"),
        [OVERLAND_DIFFICULTY_TYPE_ADVENTURER] = self.control:GetNamedChild("RadioContainerAdventurer"),
        [OVERLAND_DIFFICULTY_TYPE_VETERAN] = self.control:GetNamedChild("RadioContainerVeteran"),
    }

    self.radioButtonGroup = ZO_RadioButtonGroup:New()
    for difficultyType, difficultyButton in pairs(self.difficultyButtons) do
        self.radioButtonGroup:Add(difficultyButton)
    end

    self.radioButtonGroup:SetSelectionChangedCallback(function(_, ...) self:OnDifficultyButtonSelectionChanged(...) end)

    self:RefreshDifficulties()
end

function ZO_ChallengeDifficultyScreen_Keyboard:RegisterForEvents()
    self.control:RegisterForEvent(EVENT_OVERLAND_DIFFICULTY_CHANGED, ZO_GetEventForwardingFunction(self, self.RefreshDifficulties))
end

function ZO_ChallengeDifficultyScreen_Keyboard:OnShowing()
    self:ResetPendingDifficulty()
    self:RefreshDifficulties()

    local shouldShowLevelUpRewardsButton = HasPendingLevelUpReward() or HasUpcomingLevelUpReward()
    self.goToLevelUpRewardsButton:SetHidden(not shouldShowLevelUpRewardsButton)
    self.goToLevelUpRewardsButton:SetEnabled(shouldShowLevelUpRewardsButton)
    self.goToDifficultyButton:SetHidden(not shouldShowLevelUpRewardsButton)
    self.goToDifficultyButton:SetEnabled(shouldShowLevelUpRewardsButton)
    self.levelUpRewardsRadioButtonGroup:SetClickedButton(self.goToDifficultyButton)
end

function ZO_ChallengeDifficultyScreen_Keyboard:Show()
    if not self:IsShowing() then
        SCENE_MANAGER:AddFragment(ZO_CHALLENGE_DIFFICULTY_KEYBOARD_FRAGMENT)
    end
end

function ZO_ChallengeDifficultyScreen_Keyboard:Hide()
    if self:IsShowing() then
        SCENE_MANAGER:RemoveFragment(ZO_CHALLENGE_DIFFICULTY_KEYBOARD_FRAGMENT)
    end
end

function ZO_ChallengeDifficultyScreen_Keyboard:IsShowing()
    return ZO_CHALLENGE_DIFFICULTY_KEYBOARD_FRAGMENT:IsShowing()
end

function ZO_ChallengeDifficultyScreen_Keyboard:OnDifficultyButtonSelectionChanged(newButton, previousButton)
    self.pendingDifficulty = newButton.difficulty
    self:RefreshDifficulties()
end

function ZO_ChallengeDifficultyScreen_Keyboard:RefreshDifficulties()
    local IGNORE_CALLBACK = true
    self.radioButtonGroup:SetClickedButton(self.difficultyButtons[self.pendingDifficulty], IGNORE_CALLBACK)

    self:RefreshRadioButtonGroupEnabledState()
    self:RefreshChangeDifficultyButtonEnabledState()
    self:RefreshText()
end

function ZO_ChallengeDifficultyScreen_Keyboard:RefreshRadioButtonGroupEnabledState()
    local isChallengeDifficultyDisabled = GetOverlandDifficultyDisabledReason() ~= OVERLAND_DIFFICULTY_DISABLED_REASON_NONE
    self.radioButtonGroup:SetEnabled(not isChallengeDifficultyDisabled)
    for difficulty, button in pairs(self.difficultyButtons) do
        local isCurrentDifficulty = difficulty == GetOverlandDifficulty()
        button:GetNamedChild("SelectedPip"):SetHidden(not isCurrentDifficulty)
    end
end

function ZO_ChallengeDifficultyScreen_Keyboard:RefreshChangeDifficultyButtonEnabledState()
    local isChallengeDifficultyDisabled = GetOverlandDifficultyDisabledReason() ~= OVERLAND_DIFFICULTY_DISABLED_REASON_NONE
    self.changeDifficultyButton:SetEnabled(not isChallengeDifficultyDisabled)
end

function ZO_ChallengeDifficultyScreen_Keyboard:RefreshText()
    local difficultyName = GetString("SI_OVERLANDDIFFICULTYTYPE", self.pendingDifficulty)
    local difficultyDescription = GetOverlandDifficultyDescription(self.pendingDifficulty)
    local difficultyEffects = GetOverlandDifficultyEffects(self.pendingDifficulty)
    self.nameLabel:SetText(difficultyName)
    self.descriptionLabel:SetText(difficultyDescription)
    self.difficultyEffectsLabel:SetText(difficultyEffects)
end

function ZO_ChallengeDifficultyScreen_Keyboard:ResetPendingDifficulty()
    self.pendingDifficulty = GetUnitOverlandDifficulty("player")
    self:RefreshText()
end

function ZO_ChallengeDifficultyScreen_Keyboard.OnControlInitialized(control)
    ZO_CHALLENGE_DIFFICULTY_KEYBOARD = ZO_ChallengeDifficultyScreen_Keyboard:New(control)
end

function ZO_ChallengeDifficultyScreen_Keyboard.OnGoToLevelUpRewardsButtonClicked()
    ZO_CHALLENGE_DIFFICULTY_KEYBOARD:Hide()
    if HasPendingLevelUpReward() then
        ZO_KEYBOARD_CLAIM_LEVEL_UP_REWARDS:Show()
    elseif HasUpcomingLevelUpReward() then
        local CLAIM_WAS_NOT_SHOWING = false
        ZO_KEYBOARD_UPCOMING_LEVEL_UP_REWARDS:Show(CLAIM_WAS_NOT_SHOWING)
    end
end

function ZO_ChallengeDifficultyScreen_Keyboard.OnGoToLevelUpRewardsButtonMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, LEFT, 0, 0, RIGHT)
    InformationTooltip:AddLine(GetString(SI_CHALLENGE_DIFFICULTY_TOOLTIP_LEVEL_UP_REWARDS_TAB))
end

function ZO_ChallengeDifficultyScreen_Keyboard.OnGoToDifficultyButtonMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, LEFT, 0, 0, RIGHT)
    InformationTooltip:AddLine(GetString(SI_CHALLENGE_DIFFICULTY_TOOLTIP_DIFFICULTY_TAB))
end

function ZO_ChallengeDifficultyScreen_Keyboard.OnTabButtonMouseExit(control)
    ClearTooltip(InformationTooltip)
end

do

    local DIFFICULTY_NAME_LOOKUP =
    {
        [OVERLAND_DIFFICULTY_TYPE_BASEGAME] = "basegame",
        [OVERLAND_DIFFICULTY_TYPE_JOURNEYMAN] = "journeyman",
        [OVERLAND_DIFFICULTY_TYPE_ADVENTURER] = "adventurer",
        [OVERLAND_DIFFICULTY_TYPE_VETERAN] = "veteran",
    }

    function ZO_ChallengeDifficultyScreen_Keyboard.OnDifficultyButtonInitialized(control, difficulty)
        local difficultyName = DIFFICULTY_NAME_LOOKUP[difficulty]
        control:SetNormalTexture(string.format("EsoUI/Art/ChallengeDifficulty/challengeDifficulty_%s_up.dds", difficultyName))
        control:SetPressedTexture(string.format("EsoUI/Art/ChallengeDifficulty/challengeDifficulty_%s_down.dds", difficultyName))
        control:SetMouseOverTexture(string.format("EsoUI/Art/ChallengeDifficulty/challengeDifficulty_%s_over.dds", difficultyName))
        control:SetPressedMouseOverTexture(string.format("EsoUI/Art/ChallengeDifficulty/challengeDifficulty_%s_down_over.dds", difficultyName))
        control:SetDisabledTexture(string.format("EsoUI/Art/ChallengeDifficulty/challengeDifficulty_%s_disabled.dds", difficultyName))
        control:SetDisabledPressedTexture(string.format("EsoUI/Art/ChallengeDifficulty/challengeDifficulty_%s_down_disabled.dds", difficultyName))
        control.difficulty = difficulty
    end

    function ZO_ChallengeDifficultyScreen_Keyboard.OnDifficultyButtonMouseEnter(control)
        InitializeTooltip(InformationTooltip, control, LEFT, 0, 0, RIGHT)
        InformationTooltip:AddLine(GetString("SI_OVERLANDDIFFICULTYTYPE", control.difficulty), "ZoFontGameMedium")
    end

    function ZO_ChallengeDifficultyScreen_Keyboard.OnDifficultyButtonMouseExit(control)
        ClearTooltip(InformationTooltip)
    end

end

function ZO_ChallengeDifficultyScreen_Keyboard.OnChangeDifficultyButtonMouseEnter()
    local challengeDifficultyDisabledReason = GetOverlandDifficultyDisabledReason()
    if challengeDifficultyDisabledReason ~= OVERLAND_DIFFICULTY_DISABLED_REASON_NONE then
        InitializeTooltip(InformationTooltip, ZO_CHALLENGE_DIFFICULTY_KEYBOARD.changeDifficultyButton, LEFT, 0, 0, RIGHT)
        InformationTooltip:AddLine(GetString("SI_OVERLANDDIFFICULTYDISABLEDREASON", challengeDifficultyDisabledReason), "ZoFontGameMedium")
    end
end

function ZO_ChallengeDifficultyScreen_Keyboard.OnChangeDifficultyButtonMouseExit()
    ClearTooltip(InformationTooltip)
end

function ZO_ChallengeDifficultyScreen_Keyboard.OnChangeDifficultyButtonClicked()
    RequestChangePlayerOverlandDifficulty(ZO_CHALLENGE_DIFFICULTY_KEYBOARD.pendingDifficulty)
end