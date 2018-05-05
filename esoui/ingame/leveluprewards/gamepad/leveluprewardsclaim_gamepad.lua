ZO_LevelUpRewardsClaim_Gamepad = ZO_Object.MultiSubclass(ZO_LevelUpRewardsClaim_Base, ZO_Gamepad_ParametricList_Screen)

function ZO_LevelUpRewardsClaim_Gamepad:New(...)
    return ZO_LevelUpRewardsClaim_Base.New(self, ...)
end

function ZO_LevelUpRewardsClaim_Gamepad:Initialize(control)
    ZO_GAMEPAD_CLAIM_LEVEL_UP_REWARDS_SCENE = ZO_Scene:New("LevelUpRewardsClaimGamepad", SCENE_MANAGER)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, ZO_GAMEPAD_CLAIM_LEVEL_UP_REWARDS_SCENE)
    ZO_LevelUpRewardsClaim_Base.Initialize(self)

    ZO_GAMEPAD_CLAIM_LEVEL_UP_REWARDS_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    ZO_GAMEPAD_CLAIM_LEVEL_UP_REWARDS_FRAGMENT:SetHideOnSceneHidden(true)
    ZO_GAMEPAD_CLAIM_LEVEL_UP_REWARDS_FRAGMENT:RegisterCallback("StateChange",
                                                function(oldState, newState)
                                                    if newState == SCENE_FRAGMENT_SHOWING then
                                                        CENTER_SCREEN_ANNOUNCE:SupressAnnouncementByType(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_POINTS_GAINED)
                                                    elseif newState == SCENE_FRAGMENT_HIDING then
                                                        CENTER_SCREEN_ANNOUNCE:ResumeAnnouncementByType(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_POINTS_GAINED)
                                                    end
                                                end)
    self.scene:AddFragment(ZO_GAMEPAD_CLAIM_LEVEL_UP_REWARDS_FRAGMENT)

    self.list = self:GetMainList()

    self.list:AddDataTemplate("ZO_GamepadClaimRewardEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.list:AddDataTemplateWithHeader("ZO_GamepadClaimRewardEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    self.list:AddDataTemplate("ZO_GamepadClaimChoiceRewardEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.list:AddDataTemplateWithHeader("ZO_GamepadClaimChoiceRewardEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

    self:SetListsUseTriggerKeybinds(true)

    self:InitializeHeader()

    SYSTEMS:RegisterGamepadObject("LevelUpRewardsClaim", self)
end

function ZO_LevelUpRewardsClaim_Gamepad:OnDeferredInitialize()
    local function UpdateLevelUpRewards()
        if self:IsShowing() then
            if HasPendingLevelUpReward() then
                self:ShowLevelUpRewards()
            elseif HasUpcomingLevelUpReward() then
                SCENE_MANAGER:Show(ZO_GAMEPAD_POST_CLAIM_LEVEL_UP_REWARDS_SCENE:GetName())
            else
                -- if we have no upcoming reward, then we'll just go straight to the skills window
                SCENE_MANAGER:Show(GAMEPAD_SKILLS_ROOT_SCENE:GetName())
            end
        end
    end
    ZO_LEVEL_UP_REWARDS_MANAGER:RegisterCallback("OnLevelUpRewardsUpdated", UpdateLevelUpRewards)
end

function ZO_LevelUpRewardsClaim_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                local targetData = self.list:GetTargetData()
                if targetData ~= nil then
                    if targetData.isClaimEntry then
                        return true
                    elseif targetData.parentChoice ~= nil then
                        return true
                    end
                end
                return false
            end,
            enabled = function()
                local targetData = self.list:GetTargetData()
                if targetData.isClaimEntry then
                    local hasMadeAllSelections = DoAllValidLevelUpRewardChoicesHaveSelections()
                    if not hasMadeAllSelections then
                        return false, GetString("SI_CLAIMREWARDRESULT", CLAIM_REWARD_RESULT_CHOICE_MISSING)
                    else
                        return true
                    end
                end
                return true
            end,
            callback = function()
                local targetData = self.list:GetTargetData()
                if targetData.isClaimEntry then
                    self:ClaimLevelUpRewards()
                    return
                end
                
                local parentChoice = targetData:GetParentChoice()
                if parentChoice ~= nil then
                    local parentRewardId = parentChoice:GetRewardId()
                    local choiceRewardId = targetData:GetRewardId()
                    MakeLevelUpRewardChoice(parentRewardId, choiceRewardId)
                end
            end,
        },
         -- Help
        {
            name = GetString(SI_LEVEL_UP_REWARDS_HELP_KEYBIND),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            visible = function()
                local helpCategoryIndex, helpIndex = GetLevelUpHelpIndicesForLevel(self.rewardLevel)
                return helpCategoryIndex ~= nil
            end,
            callback = function()
                local helpCategoryIndex, helpIndex = GetLevelUpHelpIndicesForLevel(self.rewardLevel)
                HELP_TUTORIALS_ENTRIES_GAMEPAD:Push(helpCategoryIndex, helpIndex)
            end,
        },
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor()
    }
end

function ZO_LevelUpRewardsClaim_Gamepad:InitializeHeader()
    self.headerData = {
        titleText = "",
        data1HeaderText = GetString(SI_LEVEL_UP_REWARDS_GAMEPAD_ATTRIBUTE_POINTS_LABEL),
        data2HeaderText = GetString(SI_LEVEL_UP_REWARDS_GAMEPAD_SKILL_POINTS_LABEL),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_LevelUpRewardsClaim_Gamepad:PerformUpdate()
    self.dirty = false
end

function ZO_LevelUpRewardsClaim_Gamepad:Show()
    SCENE_MANAGER:Push(self.scene:GetName())
end

function ZO_LevelUpRewardsClaim_Gamepad:Hide()
    if self:IsShowing() then
        SCENE_MANAGER:HideCurrentScene()
    end
end

function ZO_LevelUpRewardsClaim_Gamepad:IsShowing()
    return self.scene:IsShowing()
end

function ZO_LevelUpRewardsClaim_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    self:ShowLevelUpRewards()
end

function ZO_LevelUpRewardsClaim_Gamepad:OnHide()
    ZO_Gamepad_ParametricList_Screen.OnHide(self)

    GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_LevelUpRewardsClaim_Gamepad:UpdateHeader()
    local attributePoints = GetAttributePointsAwardedForLevel(self.rewardLevel)
    local skillPoints = GetSkillPointsAwardedForLevel(self.rewardLevel)

    local headerData = self.headerData
    headerData.titleText = zo_strformat(SI_LEVEL_UP_REWARDS_HEADER, self.rewardLevel)
    headerData.data1Text = zo_strformat(SI_LEVEL_UP_REWARDS_GAMEPAD_GAINED_POINTS_FORMATTER, attributePoints)
    headerData.data2Text = zo_strformat(SI_LEVEL_UP_REWARDS_GAMEPAD_GAINED_POINTS_FORMATTER, skillPoints)

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

-- override of ZO_Gamepad_ParametricList_Screen:OnSelectionChanged
function ZO_LevelUpRewardsClaim_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    GAMEPAD_TOOLTIPS:ClearStatusLabel(GAMEPAD_RIGHT_TOOLTIP)
    if selectedData then
        if selectedData.isTip then
            GAMEPAD_TOOLTIPS:LayoutTitleAndMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, GetGamepadLevelUpTipOverview(self.rewardLevel), GetGamepadLevelUpTipDescription(self.rewardLevel))
        elseif not selectedData.isClaimEntry then
            local rewardType = selectedData:GetRewardType()
            if rewardType then
                GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_LEFT_TOOLTIP, selectedData)
                if rewardType == REWARD_ENTRY_TYPE_ITEM then
                    local equipSlot = selectedData:GetEquipSlot()
                    if equipSlot and GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_RIGHT_TOOLTIP, BAG_WORN, equipSlot) then
                        ZO_InventoryUtils_UpdateTooltipEquippedIndicatorText(GAMEPAD_RIGHT_TOOLTIP, equipSlot)
                    end
                end
            elseif selectedData:IsAdditionalUnlock() then
                GAMEPAD_TOOLTIPS:LayoutTitleAndMultiSectionDescriptionTooltip(GAMEPAD_LEFT_TOOLTIP, selectedData:GetFormattedName(), selectedData:GetDescription())
            else
                GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
            end
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

function ZO_LevelUpRewardsClaim_Gamepad:CreateRewardEntry(rewardEntryData)
    local name = ZO_LEVEL_UP_REWARDS_MANAGER:GetPendingRewardNameFromRewardData(rewardEntryData)
    local icon = rewardEntryData:GetGamepadIcon()
    local entryData = ZO_GamepadEntryData:New(name, icon)
    entryData:SetStackCount(rewardEntryData:GetQuantity())
    entryData:SetNameColors(entryData:GetColorsBasedOnQuality(rewardEntryData:GetItemQuality()))
    entryData:SetDataSource(rewardEntryData)

    return entryData
end

function ZO_LevelUpRewardsClaim_Gamepad:AddRewards(rewards)
    self.list:Clear()

    local overviewText = GetGamepadLevelUpTipOverview(self.rewardLevel)
    local descriptionText = GetGamepadLevelUpTipDescription(self.rewardLevel)
    if overviewText ~= "" and descriptionText ~= "" then
        local entryData = ZO_GamepadEntryData:New(overviewText)
        entryData:SetHeader(GetString(SI_LEVEL_UP_REWARDS_GAMEPAD_TIP_HEADER))
        entryData.isTip = true
        self.list:AddEntryWithHeader("ZO_GamepadClaimRewardEntryTemplate", entryData)
    end

    local numNonChoiceRewards = 0
    local firstNonChoiceEntryData
    for i, reward in ipairs(rewards) do
        if reward:IsValidReward() then
            local rewardChoices = reward:GetChoices()
            if rewardChoices then
                local numVisibleChoices = 0
                for choiceIndex, choiceReward in ipairs(rewardChoices) do
                    if choiceReward:IsValidReward() then
                        numVisibleChoices = numVisibleChoices + 1
                        local entryData = self:CreateRewardEntry(choiceReward)
                        entryData:SetSelected(entryData.isSelectedChoice)
                        if numVisibleChoices == 1 then
                            entryData:SetHeader(GetString(SI_LEVEL_UP_REWARDS_CHOICE_HEADER))
                            self.list:AddEntryWithHeader("ZO_GamepadClaimChoiceRewardEntryTemplate", entryData)
                        else
                            self.list:AddEntry("ZO_GamepadClaimChoiceRewardEntryTemplate", entryData)
                        end
                    end
                end
            else
                local entryData = self:CreateRewardEntry(reward)
                numNonChoiceRewards = numNonChoiceRewards + 1
                if numNonChoiceRewards == 1 then
                    firstNonChoiceEntryData = entryData
                    self.list:AddEntryWithHeader("ZO_GamepadClaimRewardEntryTemplate", entryData)
                else
                    self.list:AddEntry("ZO_GamepadClaimRewardEntryTemplate", entryData)
                end
            end
        end
    end

    if firstNonChoiceEntryData then
        if numNonChoiceRewards == 1 then
            firstNonChoiceEntryData:SetHeader(GetString(SI_LEVEL_UP_REWARDS_GAMEPAD_REWARD_SECTION_HEADER_SINGULAR))
        else
            firstNonChoiceEntryData:SetHeader(GetString(SI_LEVEL_UP_REWARDS_GAMEPAD_REWARD_SECTION_HEADER_PLURAL))
        end
    end

    local claimEntry = ZO_GamepadEntryData:New(GetString(SI_LEVEL_UP_REWARDS_GAMEPAD_CLAIM_REWARDS_ENTRY))
    claimEntry.isClaimEntry = true
    self.list:AddEntry("ZO_GamepadMenuEntryTemplate", claimEntry)

    self.list:CommitWithoutReselect()
end

function ZO_LevelUpRewardsClaim_Gamepad:RefreshSelectedChoices()
    local numRewardEntries = self.list:GetNumEntries()
    for listIndex = 1, numRewardEntries do
        local entryData = self.list:GetEntryData(listIndex)
        entryData:SetSelected(entryData.isSelectedChoice)
    end

    self.list:RefreshVisible()
end

--
--[[ XML Handlers ]]--
--

function ZO_ClaimLevelUpRewards_Gamepad_OnInitialized(control)
    ZO_GAMEPAD_CLAIM_LEVEL_UP_REWARDS = ZO_LevelUpRewardsClaim_Gamepad:New(control)
end
