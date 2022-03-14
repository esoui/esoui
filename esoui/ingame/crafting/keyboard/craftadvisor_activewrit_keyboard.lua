ZO_WritAdvisor_Keyboard = ZO_Object:Subclass()

local DEFAULT_SELECTED_QUEST_INDEX = 1

function ZO_WritAdvisor_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_WritAdvisor_Keyboard:Initialize(control)
    self.control = control
    self.currentlySelectedQuestIndex = DEFAULT_SELECTED_QUEST_INDEX
    self.initialShow = true
    self.questIndexToTreeNode = {}

    local headerContainer = control:GetNamedChild("HeaderContainer")

    WRIT_ADVISOR_FRAGMENT = ZO_FadeSceneFragment:New(control)
    WRIT_ADVISOR_HEADER_FRAGMENT = ZO_SimpleSceneFragment:New(headerContainer)

    self:InitializeQuestList()

    WRIT_ADVISOR_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        end
    end)

    CRAFT_ADVISOR_MANAGER:RegisterCallback("QuestMasterListUpdated", function(updatedQuestList) 
        self.questMasterList = updatedQuestList
        self:RefreshQuestList() 
    end)

    local function OnCraftCompleted()
        if self.dirtyFlag then
            self:RefreshQuestList()
        end
    end
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", OnCraftCompleted)

    --The alchemy info updates later than everything else, so we need to do another refresh once it's ready
    CALLBACK_MANAGER:RegisterCallback("AlchemyInfoReady", function()
        local treeNode = self.questIndexToTreeNode[self.currentlySelectedQuestIndex]
        if treeNode then
            local questData = treeNode.data

            --Make sure we don't actually add the same message a bunch of times
            if not treeNode.alreadyChecked then
                for _, conditionInfo in ipairs(questData.conditionData) do
                    local _, curCount, maxCount = GetJournalQuestConditionInfo(questData.questIndex, QUEST_MAIN_STEP_INDEX, conditionInfo.conditionIndex)
                    local missingMessage, missingDescription = CRAFT_ADVISOR_MANAGER:GetMissingMessage(conditionInfo, curCount, maxCount)
                    if missingMessage then
                        local missingNode = self.navigationTree:AddNode("ZO_ActiveWritNavigationEntry", {errorHeader = missingMessage, errorText = missingDescription, missing = true}, treeNode)
                    end
                end
                treeNode.alreadyChecked = true
            end
        end
    end)

    CRAFT_ADVISOR_MANAGER:RegisterCallback("SelectedQuestConditionsUpdated", function() self:RefreshQuestList() end)
end

function ZO_WritAdvisor_Keyboard:OnShowing()
    if self.dirtyFlag then
        self:RefreshQuestList()
    end
    --We need to do this to prevent the filters and displayed quest getting out of sync in certain cases when switching between gamepad and keyboard
    CRAFT_ADVISOR_MANAGER:OnSelectionChanged(self.currentlySelectedQuestIndex)
end

function ZO_WritAdvisor_Keyboard:InitializeQuestList()
    local DEFAULT_INDENT = 60
    local DEFAULT_SPACING = -20
    local DEFAULT_WIDTH = 350

    self.navigationTree = ZO_Tree:New(self.control:GetNamedChild("NavigationContainerScrollChild"), DEFAULT_INDENT, DEFAULT_SPACING, DEFAULT_WIDTH)

    local OPEN_TEXTURE = "EsoUI/Art/Journal/journal_Quest_Selected.dds"
    local CLOSED_TEXTURE = ""
    local OVER_OPEN_TEXTURE = "EsoUI/Art/Journal/journal_Quest_Selected.dds"
    local OVER_CLOSED_TEXTURE = ""

    local function TreeHeaderSetup(node, control, data, open, userRequested, enabled)
        control.text:SetText(data.name)

        control.questIndex = data.questIndex

        control.icon:SetTexture(open and OPEN_TEXTURE or CLOSED_TEXTURE)
        control.iconHighlight:SetTexture(open and OVER_OPEN_TEXTURE or OVER_CLOSED_TEXTURE)

        control.icon:SetHidden(not open)
        control.iconHighlight:SetHidden(not open)

        control.text:SetSelected(open)

        ZO_IconHeader_Setup(control, open, enabled)
        ZO_IconHeader_UpdateSize(control)

        if open then
            ZO_SelectableLabel_SetNormalColor(control.text, ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED)))
            self.currentlySelectedQuestIndex = control.questIndex
            if enabled then
                CRAFT_ADVISOR_MANAGER:OnSelectionChanged(control.questIndex)
            end
        else
            ZO_SelectableLabel_SetNormalColor(control.text, ZO_ColorDef:New(GetColorForCon(GetCon(data.level))))
        end
    end

    local DEFAULT_SELECTION_FUNCTION = nil
    local DEFAULT_EQUALITY_FUNCTION = nil
    local DEFAULT_CHILD_INDENT = nil

    self.navigationTree:AddTemplate("ZO_ActiveWritHeader", TreeHeaderSetup, DEFAULT_SELECTION_FUNCTION, DEFAULT_EQUALITY_FUNCTION, DEFAULT_CHILD_INDENT, 0)

    local function TreeEntrySetup(node, control, data, open, userRequested, enabled)
        control:SetText(data.name or data.errorHeader)
        if not enabled then
            control:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
        elseif data.missing then
            control:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
            control.missingHeader = data.errorHeader
            control.missingBody = data.errorText
        else
            control:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
            control.missingHeader = nil
            control.missingBody = nil
        end
    end

    local function TreeEntryEquality(left, right)
        return left.name == right.name
    end
    self.navigationTree:AddTemplate("ZO_ActiveWritNavigationEntry", TreeEntrySetup, DEFAULT_SELECTION_FUNCTION, TreeEntryEquality)

    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")
    ZO_CraftingUtils_ConnectTreeToCraftingProcess(self.navigationTree)
end

function ZO_WritAdvisor_Keyboard:RefreshQuestList()
    if WRIT_ADVISOR_FRAGMENT:IsShowing() and not ZO_CraftingUtils_IsPerformingCraftProcess() then
        local quests = self.questMasterList

        self.questIndexToTreeNode = {}

        -- Add items to the tree
        self.navigationTree:Reset()

        local questNodes = {}

        local firstNode = nil
        local previousNode = nil 
        for i, questInfo in ipairs(quests) do
            --First, add the quest name
            questNodes[questInfo] = self.navigationTree:AddNode("ZO_ActiveWritHeader", questInfo)
            self.questIndexToTreeNode[questInfo.questIndex] = questNodes[questInfo]

            local _, _, _, _, conditionCount = GetJournalQuestStepInfo(questInfo.questIndex, QUEST_MAIN_STEP_INDEX)
            local conditionInfoIndex = 1;

            --Add the conditions for the quest
            for conditionIndex = 1, conditionCount do
                local conditionText, curCount, maxCount, isFailCondition, isComplete, _, isVisible, conditionType = GetJournalQuestConditionInfo(questInfo.questIndex, QUEST_MAIN_STEP_INDEX, conditionIndex)

                if (not isFailCondition) and (conditionText ~= "") and not isComplete and isVisible then
                    local taskNode = self.navigationTree:AddNode("ZO_ActiveWritNavigationEntry", {name = conditionText}, questNodes[questInfo])
                    firstNode = firstNode or taskNode
                    if previousNode then
                        previousNode.nextNode = taskNode
                    end

                    if i == #quests and conditionIndex == conditionCount then
                        taskNode.nextNode = firstNode
                    end

                    previousNode = taskNode

                    --There are certain cases where we want to defer adding the missing text, so don't do it here in that case
                    if not CRAFT_ADVISOR_MANAGER:ShouldDeferRefresh() then
                        --Determine if we need to add an error message after this condition
                        if questInfo.conditionData[conditionInfoIndex] and questInfo.conditionData[conditionInfoIndex].conditionIndex == conditionIndex then
                            local missingMessage, missingDescription = CRAFT_ADVISOR_MANAGER:GetMissingMessage(questInfo.conditionData[conditionInfoIndex], curCount, maxCount)
                            if missingMessage then
                                local missingNode = self.navigationTree:AddNode("ZO_ActiveWritNavigationEntry", {errorHeader = missingMessage, errorText = missingDescription, missing = true}, questNodes[questInfo])
                                previousNode.nextNode = missingNode
                                if i == #quests and conditionIndex == conditionCount then
                                    missingNode.nextNode = firstNode
                                end

                                previousNode = missingNode
                            end
                            conditionInfoIndex = conditionInfoIndex + 1
                        end
                   end
                end
            end
        end

        self.navigationTree:Commit()
        self.dirtyFlag = false
    else
        self.dirtyFlag = true
    end
end

function ZO_WritAdvisor_Keyboard_OnInitialized(control)
    ZO_WRIT_ADVISOR_WINDOW = ZO_WritAdvisor_Keyboard:New(control)
end

function ZO_ActiveWritNavigationEntry_OnMouseEnter(control)
    local header = control.missingHeader
    local body = control.missingBody

    if header and body then
        local TOOLTIP_OFFSET_X = 15
        local TOOLTIP_OFFSET_Y = 0
        local DEFAULT_FONT = ""
        InitializeTooltip(InformationTooltip, control, LEFT, TOOLTIP_OFFSET_X, TOOLTIP_OFFSET_Y, RIGHT)
        InformationTooltip:AddLine(header, DEFAULT_FONT, ZO_NORMAL_TEXT:UnpackRGBA())
        InformationTooltip:AddLine(body)
    end
end

function ZO_ActiveWritNavigationEntry_OnMouseExit()
    ClearTooltip(InformationTooltip)
end