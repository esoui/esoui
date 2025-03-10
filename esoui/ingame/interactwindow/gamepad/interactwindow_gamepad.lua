-- Matches where the reticle shows up.  The reticle is anchored left to center, but list entries are top to center.
-- If we change the font of reticle in the future, we'll probably need to upgrade this magic number to meet the new position.
ZO_INTERACT_CENTER_OFFSET = 15 + ZO_GAMEPAD_DEFAULT_LIST_ENTRY_SELECTED_HEIGHT / 2

--Gamepad Interaction
---------------------

ZO_GamepadInteraction = ZO_SharedInteraction:Subclass()

function ZO_GamepadInteraction:New(...)
    local interaction = ZO_SharedInteraction.New(self)
    interaction:Initialize(...)
    return interaction
end

function ZO_GamepadInteraction:Initialize(control)
    self.control = control
    self.sceneName = "gamepadInteraction"

    self.contentContainerControl = self.control:GetNamedChild("Container")

    ZO_SharedInteraction.Initialize(self, control)

    self:InitInteraction()
    self:InitializeKeybindStripDescriptors()

    local function OnStateChange(oldState, newState)
        if(newState == SCENE_HIDDEN) then
            self:OnHidden()
        elseif newState == SCENE_SHOWING then
            self:OnShowing()
        end
    end

    local interactScene = self:CreateInteractScene("gamepadInteract")
    interactScene:RegisterCallback("StateChange", OnStateChange)

    SYSTEMS:RegisterGamepadObject(ZO_INTERACTION_SYSTEM_NAME, self)

    self:OnScreenResized()
end

local function SetupBodyText(control, data, selected, selectedDuringRebuild, enabled, activated)
    control:GetNamedChild("TargetArea"):GetNamedChild("BodyText"):SetText(data.bodyText)
end

local function SetupOption(control, data, selected, selectedDuringRebuild, enabled, activated)
    if data.optionsEnabled then
        data.enabled = data.optionUsable

        local label = control:GetNamedChild("Text")
        if selected then
            if data.recolorIfUnusable and not data.optionUsable then
                label:SetColor(ZO_NORMAL_TEXT:UnpackRGB())
            else
                label:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
            end
        elseif data.isImportant then
            label:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        elseif (data.recolorIfUnusable and not data.optionUsable) or data.chosenBefore then
            label:SetColor(ZO_GAMEPAD_DISABLED_UNSELECTED_COLOR:UnpackRGB())
        else
            label:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
        end

        --Order matters, some label update functions use label.optionText so we neeed to set it before calling those
        label.optionText = data.optionText

        --Order matters, do this before running the label update function so we don't overwrite any changes made there
        label:SetText(label.optionText)

        label:SetHandler("OnUpdate", data.labelUpdateFunction)
        if data.labelUpdateFunction then
            data.labelUpdateFunction(label, data)
        end

        local icon = control:GetNamedChild("Icon")
        if #data.iconFiles > 0 then
            icon:ClearIcons()
            for iconIndex, iconFile in pairs(data.iconFiles) do
                icon:AddIcon(iconFile)
            end
            icon:Show()
            label:SetAnchor(TOPLEFT, icon, TOPRIGHT)
        else
            icon:SetHidden(true)
            label:SetAnchor(TOPLEFT)
        end

        control:SetHeight(label:GetHeight())
    end
end

local function ReleaseChatterOptionControl(control)
    control:SetHandler("OnUpdate", nil)
end

function ZO_GamepadInteraction:InitInteraction()
    self.titleControl = self.control:GetNamedChild("Title")
    self.textControl = self.contentContainerControl:GetNamedChild("Text")

    -- Setup Interaction with parametric scroll list
    local function SetupRewardTitle(control, data, selected, selectedDuringRebuild, enabled, activated)
        local goldLabel = control:GetNamedChild("Gold")
        local goldReward = data.goldReward
        if goldReward and goldReward.amount > 0 then
            goldLabel:SetHidden(false)
            local creatorFunc = self:GetRewardCreateFunc(REWARD_TYPE_MONEY)
            creatorFunc(goldLabel, goldReward.name, goldReward.amount, ZO_GAMEPAD_CURRENCY_OPTIONS)
        else
            goldLabel:SetHidden(true)
        end
    end
    
    local interactControl = self.contentContainerControl:GetNamedChild("Interact")
    local listControl = interactControl:GetNamedChild("List")
    self.itemList = ZO_GamepadVerticalItemParametricScrollList:New(listControl)
    ZO_GamepadQuadrants_SetBackgroundArrowCenterOffsetY(self.control:GetNamedChild("BG"), LEFT, ZO_INTERACT_CENTER_OFFSET)
    self.itemList:SetFixedCenterOffset(ZO_INTERACT_CENTER_OFFSET)
    self.itemList:SetSelectedItemOffsets(0,10)
    self.itemList:SetAlignToScreenCenter(true)
    self.itemList:SetHandleDynamicViewProperties(true)
    self.itemList:SetDrawScrollArrows(true)

    self.itemList:SetOnSelectedDataChangedCallback(function(list, selectedData)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end)

    self.itemList:AddDataTemplate("ZO_InteractWindow_GamepadBodyTextItem", SetupBodyText, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.itemList:AddDataTemplateWithHeader("ZO_QuestReward_Title_Gamepad", SetupRewardTitle, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadQuestRewardEntryHeaderTemplate")
    self.itemList:AddDataTemplate("ZO_QuestReward_Gamepad", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.itemList:AddDataTemplate("ZO_ChatterOption_Gamepad", SetupOption, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.itemList:SetDataTemplateReleaseFunction("ZO_ChatterOption_Gamepad", ReleaseChatterOptionControl)
end

function ZO_GamepadInteraction:InitializeKeybindStripDescriptors()

    local function ItemSelected()
        local selectedData = self.itemList:GetTargetData()
        if selectedData.isChatterOption then
            self:HandleChatterOptionClicked(selectedData)
        end
    end

    local function IsVisible()
        local selectedData = self.itemList:GetTargetData()
        if selectedData then
            return selectedData.isChatterOption
        else
            return true
        end
    end

    local function IsEnabled()
        local selectedData = self.itemList:GetTargetData()
        if selectedData then
            return selectedData.optionUsable, CHATTER_OPTION_ERROR[selectedData.optionType]
        else
            return true
        end
    end

    self.keybindStripDescriptor = {}
    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.keybindStripDescriptor, 
                                                        GAME_NAVIGATION_TYPE_BUTTON,
                                                        ItemSelected,
                                                        nil,
                                                        IsVisible,
                                                        IsEnabled
                                                    )

    local function BackCallback()
        self:CloseChatter()
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, BackCallback)

end

function ZO_GamepadInteraction:ResetInteraction(bodyText)
    self.titleControl:SetText(GetUnitName("interact"))
    self.textControl:SetText(bodyText)
    if self.itemList then
        self.itemList:Clear()
        self.itemList:Commit()
    end
end

function ZO_GamepadInteraction:SwitchInteraction()
    self.itemList:Deactivate()
end

function ZO_GamepadInteraction:SelectChatterOptionByIndex(optionIndex)
    local chatterBegin = nil
    local numData = #self.itemList.dataList
    for i = 1, numData do
        local itemData = self.itemList:GetDataForDataIndex(i)
        if itemData.isChatterOption then
            chatterBegin = i
            break
        end
    end

    if chatterBegin then 
        local selectedOption = chatterBegin + optionIndex - 1
        self.itemList:SetSelectedIndex(selectedOption)
        self.itemList:RefreshVisible()
    end
end

function ZO_GamepadInteraction:SelectLastChatterOption()
    self:SelectChatterOptionByIndex(#self.itemList.dataList)
end

function ZO_GamepadInteraction:PopulateChatterOption(controlID, optionIndex, optionText, optionType, optionalArg, isImportant, chosenBefore, importantOptions, teleportNPCId, waypointIdTable, dialogueTone)
    local chatterData = self:GetChatterOptionData(optionIndex, optionText, optionType, optionalArg, isImportant, chosenBefore, teleportNPCId, waypointIdTable, dialogueTone)

    if chatterData.isImportant then
        TriggerTutorial(TUTORIAL_TRIGGER_IMPORTANT_DIALOGUE)
    end

    self.itemList:AddEntry("ZO_ChatterOption_Gamepad", chatterData)
end

function ZO_GamepadInteraction:FinalizeChatterOptions(optionCount)
    self.itemList:CommitWithoutReselect()
    self.itemList:RefreshVisible()
end

function ZO_GamepadInteraction:UpdateChatterOptions(optionCount, backToTOCOption)
    self:PopulateChatterOptions(optionCount, backToTOCOption)
end

function ZO_GamepadInteraction:ShowQuestRewards(journalQuestIndex)
    local IS_GAMEPAD = true
    local rewardDataList = self:GetRewardData(journalQuestIndex, IS_GAMEPAD)

    if #rewardDataList == 0 then
        return
    end

    local parametricListRewards = {}
    local goldReward
    local currenciesWithMaxWarning = {}
    local amountsAcquiredWithMaxWarning = {}
    for i, data in ipairs(rewardDataList) do
        if self:IsCurrencyReward(data.rewardType) then
            if data.rewardType == REWARD_TYPE_MONEY then
                goldReward = data
            else
                table.insert(parametricListRewards, data)
            end

            if self:WouldCurrencyExceedMax(data.rewardType, data.amount) then
                local currencyType = self:GetCurrencyTypeFromReward(data.rewardType)
                local currencyText = GetCurrencyName(currencyType)
                table.insert(currenciesWithMaxWarning, currencyText)

                local playerStoredLocation = GetCurrencyPlayerStoredLocation(currencyType)
                local currencyAmount = zo_max(0, GetMaxPossibleCurrency(currencyType, playerStoredLocation) - (GetCurrencyAmount(currencyType, playerStoredLocation)))
                local isSingular = currencyAmount == 1
                currencyText = GetCurrencyName(currencyType, isSingular)
                table.insert(amountsAcquiredWithMaxWarning, string.format('%s %s', currencyAmount, currencyText))
            end
        end
    end
    for i, data in ipairs(rewardDataList) do
        if not self:IsCurrencyReward(data.rewardType) then
            table.insert(parametricListRewards, data)
        end
    end

    local confirmError
    if #currenciesWithMaxWarning > 0 then
        local currencyList = ZO_GenerateCommaSeparatedListWithOr(currenciesWithMaxWarning)
        confirmError = ZO_ERROR_COLOR:Colorize(zo_strformat(SI_QUEST_REWARD_MAX_CURRENCY_ERROR, currencyList))
    end

    local titleData = {}
    titleData.canSelect = false
    titleData.goldReward = goldReward
    titleData.header = GetString(SI_INTERACT_REWARDS_GIVEN)
    self.itemList:AddEntryWithHeader("ZO_QuestReward_Title_Gamepad", titleData)

    for i, rewardData in ipairs(parametricListRewards) do
        if rewardData.rewardType == REWARD_TYPE_PARTIAL_SKILL_POINTS then
            rewardData.name = ZO_QuestReward_GetSkillPointText(rewardData.amount)
            rewardData.icon = nil
        elseif rewardData.rewardType == REWARD_TYPE_SKILL_LINE then
            rewardData.name = ZO_QuestReward_GetSkillLineEarnedText(rewardData.name)
        elseif rewardData.rewardType == REWARD_TYPE_AUTO_ITEM and rewardData.itemType == REWARD_ITEM_TYPE_COLLECTIBLE then
            rewardData.itemId = GetJournalQuestRewardCollectibleId(journalQuestIndex, i)
        elseif self:IsCurrencyReward(rewardData.rewardType) then
            local currencyType = self:GetCurrencyTypeFromReward(rewardData.rewardType)
            --Intentionally use the keyboard icon here because we want the graphic look
            rewardData.icon = ZO_Currency_GetKeyboardCurrencyIcon(currencyType)
        end

        local entry = ZO_GamepadEntryData:New(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, rewardData.name))
        if rewardData.rewardType == REWARD_TYPE_AUTO_ITEM and rewardData.itemType == REWARD_ITEM_TYPE_ITEM then
            entry:InitializeInventoryVisualData(rewardData)
        else
            if rewardData.rewardType == REWARD_TYPE_AUTO_ITEM and rewardData.itemType == REWARD_ITEM_TYPE_TRIBUTE_CARD_UPGRADE then
                entry:SetNameColors(entry:GetColorsBasedOnQuality(rewardData.displayQuality or rewardData.quality))
            end

            entry:SetFontScaleOnSelection(false)
            if rewardData.icon then
                entry:AddIcon(rewardData.icon)
            end
        end

        entry.rewardData = rewardData

        if rewardData.rewardType ~= REWARD_TYPE_TRIBUTE_CLUB_EXPERIENCE then
            entry:SetStackCount(rewardData.amount)
        end

        self.itemList:AddEntry("ZO_QuestReward_Gamepad", entry)
    end

    return confirmError, currenciesWithMaxWarning, amountsAcquiredWithMaxWarning
end

function ZO_GamepadInteraction:RefreshList()
    if self.itemList then
        self.itemList:RefreshVisible()
    end
end

function ZO_GamepadInteraction:UpdateClemencyOnTimeComplete(control, data)
    control:SetText(control.optionText)
    data.optionUsable = true
    control.optionType = CHATTER_TALK_CHOICE_USE_CLEMENCY
    control:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    self:RefreshList()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadInteraction:UpdateShadowyConnectionsOnTimeComplete(control, data)
    control:SetText(control.optionText)
    data.optionUsable = true
    control.optionType = CHATTER_TALK_CHOICE_USE_SHADOWY_CONNECTIONS
    control:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    self:RefreshList()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadInteraction:OnShowing()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self:RefreshList()
    self.itemList:Activate()
end

function ZO_GamepadInteraction:OnHidden()
    self.itemList:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    ZO_SharedInteraction.OnHidden(self)
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_MOVABLE_TOOLTIP)
end

function ZO_InteractWindow_Gamepad_Initialize(control)
    GAMEPAD_INTERACTION = ZO_GamepadInteraction:New(control)
end