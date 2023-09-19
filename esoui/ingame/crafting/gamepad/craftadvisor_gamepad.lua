ZO_CraftAdvisor_Gamepad = ZO_InitializingCallbackObject:Subclass()

local DEFAULT_DISPLAYED_QUEST_INDEX = 1

function ZO_CraftAdvisor_Gamepad:Initialize(control)
    self.control = control
    self.questContainer = self.control:GetNamedChild("QuestContainer")
    self.questHeader = self.questContainer:GetNamedChild("QuestName")
    self.currentlyDisplayedQuestIndex = DEFAULT_DISPLAYED_QUEST_INDEX
    self.questConditionText = {}

    self.questConditionControlPool = ZO_ControlPool:New("ZO_Gamepad_ActiveWritCondition", self.questContainer)
    self.questConditionControlPool:SetCustomFactoryBehavior(function(control)
        control.iconTexture = control:GetNamedChild("Icon")
    end)

    GAMEPAD_CRAFT_ADVISOR_FRAGMENT = ZO_FadeSceneFragment:New(control)

    GAMEPAD_CRAFT_ADVISOR_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWN then
            self:OnShown()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)

    CRAFT_ADVISOR_MANAGER:RegisterCallback("QuestMasterListUpdated", function(updatedQuestList) 
        self.questMasterList = updatedQuestList
        self.currentlyDisplayedQuestIndex = DEFAULT_DISPLAYED_QUEST_INDEX
        self:RefreshQuestList() 
    end)

    CRAFT_ADVISOR_MANAGER:RegisterCallback("SelectedQuestConditionsUpdated", function() self:RefreshQuestList() end)

    --The alchemy info updates later than everything else, so we need to do another refresh once it's ready
    CALLBACK_MANAGER:RegisterCallback("AlchemyInfoReady", function() self:RefreshQuestList() end)

    control:SetHandler("OnResizedToFit", function() self:OnResized() end)

    self:InitializeKeybinds()
end

function ZO_CraftAdvisor_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor =
    {
        {
            --Even though this is an ethereal keybind, the name will still be read during screen narration
            name = GetString(SI_GAMEPAD_CRAFT_ADVISOR_CYCLE_ACTIVE_WRIT_NARRATION),
            ethereal = true,
            narrateEthereal = function()
                return self.questMasterList and #self.questMasterList > 1
            end,
            keybind = "UI_SHORTCUT_LEFT_STICK",
            callback = function() self:CycleActiveQuest() end,
            enabled = function() return not ZO_CraftingUtils_IsPerformingCraftProcess() and self.questMasterList and #self.questMasterList > 1 end,
        },
    }
    local cycleQuestsDescriptor =
    {
        keybind = "UI_SHORTCUT_LEFT_STICK",
        visible = function()
            return self.questMasterList and #self.questMasterList > 1
        end,
    }
    self.questHeader.keybind:SetKeybindButtonDescriptor(cycleQuestsDescriptor)
    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)
end

function ZO_CraftAdvisor_Gamepad:CycleActiveQuest()
    self.currentlyDisplayedQuestIndex = self.currentlyDisplayedQuestIndex + 1

    --If we go beyond the number of quests we can cycle between, go back to the first one
    if self.currentlyDisplayedQuestIndex > #self.questMasterList then
        self.currentlyDisplayedQuestIndex = DEFAULT_DISPLAYED_QUEST_INDEX
    end

    CRAFT_ADVISOR_MANAGER:OnSelectionChanged(self.questMasterList[self.currentlyDisplayedQuestIndex].questIndex)
    self:RefreshQuestList()
    self:FireCallbacks("CycleActiveQuest")
end

function ZO_CraftAdvisor_Gamepad:OnShown()
    if self.dirtyFlag then
        self.currentlyDisplayedQuestIndex = DEFAULT_DISPLAYED_QUEST_INDEX
        self:RefreshQuestList()
    end

    local currentQuest = self.questMasterList[self.currentlyDisplayedQuestIndex]
    if currentQuest then
        --We need to do this to prevent the filters and displayed quest getting out of sync in certain cases when switching between gamepad and keyboard
        CRAFT_ADVISOR_MANAGER:OnSelectionChanged(currentQuest.questIndex)
    end

    --If there are active writs, we need to tell the crafting alerts to adjust the maximum height to prevent any overlap with the bottom bar
    if CRAFT_ADVISOR_MANAGER:HasActiveWrits() then
        ZO_CraftingAlertCondenseMaxHeight_Gamepad(self.control:GetHeight())
    end

    self.questContainer:SetHidden(false)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_CraftAdvisor_Gamepad:OnHidden()
    --Reset the max height for the crafting alerts to its original value
    ZO_CraftingAlertCondenseMaxHeight_Gamepad(0)
    self.questContainer:SetHidden(true)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_CraftAdvisor_Gamepad:RebuildConditions(questInfo)
    self.questConditionControlPool:ReleaseAllObjects()
    ZO_ClearNumericallyIndexedTable(self.questConditionText)
    if questInfo then
        local _, _, _, _, conditionCount = GetJournalQuestStepInfo(questInfo.questIndex, QUEST_MAIN_STEP_INDEX)
        local previousControl = nil
        local conditionInfoIndex = 1

        --Add the conditions
        for conditionIndex = 1, conditionCount do
            local conditionText, curCount, maxCount, isFailCondition, isComplete, _, isVisible, conditionType = GetJournalQuestConditionInfo(questInfo.questIndex, QUEST_MAIN_STEP_INDEX, conditionIndex)

            if (not isFailCondition) and (conditionText ~= "") and not isComplete and isVisible then
                local control = self.questConditionControlPool:AcquireObject()
                control:ClearAnchors()
                control:SetText(conditionText)
                table.insert(self.questConditionText, conditionText)
                control:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
                
                --Determine if we need to anchor to the header or to a previous condition
                if previousControl ~= nil then
                    control:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT, 0, 16)
                else
                    control:SetAnchor(TOPRIGHT, self.questHeader, BOTTOMRIGHT, 0, 16)
                end

                previousControl = control

                --Check if we need to add an error message underneath this condition
                if questInfo.conditionData[conditionInfoIndex] and questInfo.conditionData[conditionInfoIndex].conditionIndex == conditionIndex then
                    local missingMessage = CRAFT_ADVISOR_MANAGER:GetMissingMessage(questInfo.conditionData[conditionInfoIndex], curCount, maxCount)
                    if missingMessage then
                        local missingControl = self.questConditionControlPool:AcquireObject()
                        missingControl:ClearAnchors()
                        missingControl:SetText(missingMessage)
                        table.insert(self.questConditionText, missingMessage)
                        missingControl:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
                        missingControl:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT)
                        previousControl = missingControl
                    end
                    conditionInfoIndex = conditionInfoIndex + 1
                end
            end
        end      
    end
end

function ZO_CraftAdvisor_Gamepad:RefreshQuestList()
    if GAMEPAD_CRAFT_ADVISOR_FRAGMENT:IsShowing() then
        if CRAFT_ADVISOR_MANAGER:HasActiveWrits() then
            self.questHeader:SetHidden(false)

            local quests = self.questMasterList
            local questInfo = quests[self.currentlyDisplayedQuestIndex]
            self.questHeaderText = questInfo.name
            self.questHeader:SetText(questInfo.name)

            self:RebuildConditions(questInfo)
            CRAFT_ADVISOR_MANAGER:UpdateQuestConditionInfo()
        else
            self.questHeaderText = nil
            self.questHeader:SetHidden(true)
            self:RebuildConditions()
        end

        self.dirtyFlag = false
    else
        self.dirtyFlag = true
    end
end

function ZO_CraftAdvisor_Gamepad:OnResized()
    if GAMEPAD_CRAFT_ADVISOR_FRAGMENT:IsShowing() and CRAFT_ADVISOR_MANAGER:HasActiveWrits() then
        ZO_CraftingAlertCondenseMaxHeight_Gamepad(self.control:GetHeight())
    end
end

function ZO_CraftAdvisor_Gamepad:GetControl()
    return self.control
end

function ZO_CraftAdvisor_Gamepad:GetNarrationText()
    local narrations = {}
    --Only narrate if the craft advisor is actually showing
    if GAMEPAD_CRAFT_ADVISOR_FRAGMENT:IsShowing() then
        table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.questHeaderText))
        for _, conditionText in ipairs(self.questConditionText) do
            table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(conditionText))
        end
    end
    return narrations
end

function ZO_CraftAdvisor_Gamepad_OnInitialized(control)
    ZO_WRIT_ADVISOR_GAMEPAD = ZO_CraftAdvisor_Gamepad:New(control)
end

do
    function ZO_Gamepad_ActiveWritHeader_OnInitialized(self)
        self.keybind = self:GetNamedChild("Keybind")
    end
end