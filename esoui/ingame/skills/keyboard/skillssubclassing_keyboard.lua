local CLASS_HEADER_DATA = 1
local SKILLLINE_INFO_DATA = 2

local SKILL_ABILITY_DATA = 1
local SKILL_HEADER_DATA = 2

ZO_SkillsSubclassing_Keyboard = ZO_InitializingObject:Subclass()

function ZO_SkillsSubclassing_Keyboard:Initialize(control, owner)
    self.control = control

    self.classSkillLineList = self.control:GetNamedChild("ClassSkillLineList")
    self.skillsListContainer = self.control:GetNamedChild("SkillsListContainer")
    self.skillsListInfo = self.skillsListContainer:GetNamedChild("SkillInfo")
    self.skillsList = self.skillsListContainer:GetNamedChild("SkillsList")
    self.trainingInfo = self.control:GetNamedChild("TrainingInfo")
    self.trainingLabel = self.trainingInfo:GetNamedChild("Text")

    self.playerClassId = GetUnitClassId("player")

    self.classIndexToIdList = {}
    self.collapsedClassIds = {}
    self.isInitialized = false
end

function ZO_SkillsSubclassing_Keyboard:OnDeferredInitialize()
    if not self.isInitialized then
        local numClasses = GetNumClasses()
        for classIndex = 1, numClasses do
            local classId = GetClassIdByIndex(classIndex)
            table.insert(self.classIndexToIdList, classId)
            if classId ~= self.playerClassId then
                local firstClassSkillLine = SKILLS_DATA_MANAGER:GetFirstActiveSkillLineByClassId(classId)
                self.collapsedClassIds[classId] = firstClassSkillLine == nil
            end
        end

        self:InitializeSkillLineSwapDialog()
        self:InitializeClassSkillLines()
        self:InitializeSkillsList()
        self:RegisterForEvents()
        self.isInitialized = true
    end
end

function ZO_SkillsSubclassing_Keyboard:InitializeClassSkillLines()
    local function ClassHeaderSetup(control, data)
        local classIcon = zo_iconFormat(select(7, GetClassInfo(data.classIndex)), "100%", "100%")
        local classText = ZO_CachedStrFormat(SI_SKILLS_ENTRY_LINE_NAME_CLASS_FORMAT, GetClassName(GetUnitGender("player"), data.classId), classIcon)
        control.nameLabel:SetText(classText)

        if data.collapsed then
            ZO_ToggleButton_SetState(control.expandedStateButton, TOGGLE_BUTTON_CLOSED)
        else
            ZO_ToggleButton_SetState(control.expandedStateButton, TOGGLE_BUTTON_OPEN)
        end
    end

    local NO_HIDE_CALLBACK = nil
    local DEFAULT_SELECT_SOUND = nil
    ZO_ScrollList_AddDataType(self.classSkillLineList, CLASS_HEADER_DATA, "ZO_Class_Header_Entry_Keyboard", 40, ClassHeaderSetup)
    ZO_ScrollList_AddDataType(self.classSkillLineList, SKILLLINE_INFO_DATA, "ZO_SkillsSubclassing_SkillLine_Keyboard", 65, function(control, data) self:SkillLineSetup(control, data) end, NO_HIDE_CALLBACK, DEFAULT_SELECT_SOUND, function(control) self:SkillLineReset(control) end)

    self.subclassingRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    self.subclassingRefreshGroup:AddDirtyState("ResetToClassSkillLines", function()
        self:RefreshClassSkillLinesView()
    end)
    self.subclassingRefreshGroup:AddDirtyState("VisibleWithoutAnimation", function()
        if self.currentSkillLineData then
            self:RefreshSkillsList()
        else
            self:RefreshClassSkillLinesView()
        end
    end)
    self.subclassingRefreshGroup:AddDirtyState("VisibleWithAnimation", function()
        if self.currentSkillLineData then
            self:RefreshSkillsList()
        else
            self.allowXPBarAnimation = true
            self:RefreshClassSkillLinesView()
            self.allowXPBarAnimation = false
        end
    end)

    self.subclassingRefreshGroup:SetActive(function()
        return self:IsShowing()
    end)
    self.subclassingRefreshGroup:MarkDirty("ResetToClassSkillLines")
end

do
    local ACTION_BUTTON_TEXTURES =
    {
        PLUS =
        {
            normal = "EsoUI/Art/Progression/addPoints_up.dds",
            mouseDown = "EsoUI/Art/Progression/addPoints_down.dds",
            mouseover = "EsoUI/Art/Progression/addPoints_over.dds",
            disabled = "EsoUI/Art/Progression/addPoints_disabled.dds",
        },
        TRAIN =
        {
            normal = "EsoUI/Art/Progression/train_up.dds",
            mouseDown = "EsoUI/Art/Progression/train_down.dds",
            mouseover = "EsoUI/Art/Progression/train_over.dds",
            disabled = "EsoUI/Art/Progression/train_disabled.dds",
        },
        CROWN_STORE =
        {
            normal = "EsoUI/Art/Market/Keyboard/tabIcon_crownStore_up.dds",
            mouseDown = "EsoUI/Art/Market/Keyboard/tabIcon_crownStore_down.dds",
            mouseover = "EsoUI/Art/Market/Keyboard/tabIcon_crownStore_over.dds",
            disabled = "EsoUI/Art/Market/Keyboard/tabIcon_crownStore_disabled.dds",
        },
    }

    local function ApplyButtonTextures(button, textures)
        button:SetNormalTexture(textures.normal)
        button:SetPressedTexture(textures.mouseDown)
        button:SetMouseOverTexture(textures.mouseover)
        button:SetDisabledTexture(textures.disabled)
    end

    function ZO_SkillsSubclassing_Keyboard:SkillLineSetup(control, data, isPreview)
        control.skillLineData = data

        local DONT_FORCE_INIT = nil
        local IS_SUBCLASSING = true
        local animateInstantly = not self.allowXPBarAnimation
        ZO_SkillLineInfo_Keyboard_Refresh(control, data, DONT_FORCE_INIT, animateInstantly, data:IsDisabled(), IS_SUBCLASSING)

        local actionTextures = nil
        if data:IsContentLocked() then
            actionTextures = ACTION_BUTTON_TEXTURES.CROWN_STORE
        elseif data:CanActivateForRespec() then
            actionTextures = ACTION_BUTTON_TEXTURES.PLUS
        elseif data:CanTrain() then
            actionTextures = ACTION_BUTTON_TEXTURES.TRAIN
        end

        if actionTextures then
            ApplyButtonTextures(control.actionButton, actionTextures)
            if data:IsContentLocked() or data:CanActivateForRespec() or data:CanTrain() then
                control.actionButton:SetState(BSTATE_NORMAL)
            else
                control.actionButton:SetState(BSTATE_DISABLED)
            end
        end

        if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
            control.actionButton:SetHidden(actionTextures == nil)

            if data:IsPendingTrain() and not data:IsPendingActivation() then
                control.untrainButton:SetHidden(false)
            end
        else
            control.actionButton:SetHidden(not data:IsContentLocked())
            control.untrainButton:SetHidden(true)
        end

        local function OnMouseEnter(highlightAreaControl)
            local control = highlightAreaControl:GetParent()
            local xpBarControl = control.xpBar:GetControl()
            local IS_SUBCLASSING = true
            ZO_SkillInfoXPBar_OnMouseEnter(xpBarControl, -170, IS_SUBCLASSING)
            if not isPreview then
                ZO_ResponsiveArrowBar_OnMouseEnter(xpBarControl)
                self.mouseOverSkillLineData = control.skillLineData
            end
            SKILLS_WINDOW:UpdateKeybinds()
        end

        local function OnMouseExit(highlightAreaControl)
            local control = highlightAreaControl:GetParent()
            ClearTooltip(InformationTooltip)
            ZO_SkillInfoXPBar_OnMouseExit()
            ZO_ResponsiveArrowBar_OnMouseExit(control.xpBar:GetControl())
            self.mouseOverSkillLineData = nil
            SKILLS_WINDOW:UpdateKeybinds()
        end

        local function OnMouseUp(highlightAreaControl, button, upInside)
            if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
                local control = highlightAreaControl:GetParent()
                self:ShowSkillsListView(control.skillLineData)
                PlaySound(SOUNDS.SKILLS_SUBCLASSING_SKILL_LINE_SELECT)
            end
        end

        -- Override inherited handlers to not do anything
        control:SetHandler("OnMouseEnter", nil)
        control:SetHandler("OnMouseExit", nil)

        local highlightAreaControl = control:GetNamedChild("HighlightArea")
        highlightAreaControl:SetHandler("OnMouseEnter", OnMouseEnter)
        highlightAreaControl:SetHandler("OnMouseExit", OnMouseExit)
        highlightAreaControl:SetHandler("OnMouseUp", OnMouseUp)
    end

    function ZO_SkillsSubclassing_Keyboard:SkillLineReset(control)
        control:SetHidden(true)
        control.actionButton:SetHidden(true)
        control.untrainButton:SetHidden(true)
    end
end

function ZO_SkillsSubclassing_Keyboard:InitializeSkillsList()
    local SKILL_ABILITY_HEIGHT = 70
    ZO_ScrollList_AddDataType(self.skillsList, SKILL_ABILITY_DATA, "ZO_Skills_Ability", SKILL_ABILITY_HEIGHT, function(abilityControl, data)
        ZO_Skills_ReadOnly_AbilityEntry_Setup(abilityControl, data.skillData)
    end)
    local SKILL_HEADER_HEIGHT = 32
    ZO_ScrollList_AddDataType(self.skillsList, SKILL_HEADER_DATA, "ZO_Skills_AbilityTypeHeader", SKILL_HEADER_HEIGHT, function(headerControl, data)
        headerControl:GetNamedChild("Label"):SetText(data.headerText)
    end)
    ZO_ScrollList_AddResizeOnScreenResize(self.skillsList)
end

function ZO_SkillsSubclassing_Keyboard:MarkRefreshGroupDirty(dirtyState)
    self.subclassingRefreshGroup:MarkDirty(dirtyState)
end

function ZO_SkillsSubclassing_Keyboard:RegisterForEvents()
    local function RefreshWithoutAnimation()
        self.subclassingRefreshGroup:MarkDirty("VisibleWithoutAnimation")
    end

    local function RefreshWithAnimation()
        self.subclassingRefreshGroup:MarkDirty("VisibleWithAnimation")
    end

    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("SkillPointAllocationModeChanged", RefreshWithoutAnimation)
    SKILL_LINE_ASSIGNMENT_MANAGER:RegisterCallback("SkillLineRespecUpdate", RefreshWithoutAnimation)
    SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", RefreshWithAnimation)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineUpdated", RefreshWithAnimation)

    self.control:SetHandler("OnEffectivelyShown", function()
        self:OnShow()
    end)
end

function ZO_SkillsSubclassing_Keyboard:IsSkillLineMousedOver()
    return self.mouseOverSkillLineData ~= nil
end

function ZO_SkillsSubclassing_Keyboard:GetMousedOverSkillLine()
    return self.mouseOverSkillLineData
end

function ZO_SkillsSubclassing_Keyboard:RefreshClassSkillLinesView()
    self:UpdateTrainingInfo()

    self.currentSkillLineData = nil
    self.classSkillLineList:SetHidden(false)
    self.skillsListContainer:SetHidden(true)
    SKILLS_WINDOW:SetSkillLinesHidden(false)
    self:RefreshClassSkillLines()
end

function ZO_SkillsSubclassing_Keyboard:ShowSkillsListView(skillLineData)
    self.classSkillLineList:SetHidden(true)
    self.skillsListContainer:SetHidden(false)
    SKILLS_WINDOW:SetSkillLinesHidden(true)
    self.currentSkillLineData = skillLineData
    self:RefreshSkillsList()
end

function ZO_SkillsSubclassing_Keyboard:IsShowing()
    return not self.control:IsHidden()
end

function ZO_SkillsSubclassing_Keyboard:Show()
    self:OnDeferredInitialize()
    self.mouseOverSkillLineData = nil
    self.control:SetHidden(false)
end

function ZO_SkillsSubclassing_Keyboard:OnShow()
    self.subclassingRefreshGroup:TryClean()
end

function ZO_SkillsSubclassing_Keyboard:Hide()
    self.mouseOverSkillLineData = nil
    self.control:SetHidden(true)
end

function ZO_SkillsSubclassing_Keyboard:UpdateTrainingInfo()
    self.trainingLabel:SetText(zo_strformat(SI_SKILLS_SUBCLASSING_TRAINING_FORMATTER, SKILLS_DATA_MANAGER:GetNumSkillLinesInTraining(), MAX_SKILL_LINES_IN_TRAINING))
end

function ZO_SkillsSubclassing_Keyboard:IsSetHeaderCollapsed(classId)
    return self.collapsedClassIds[classId] or false
end

function ZO_SkillsSubclassing_Keyboard:AddClassSkillLines(scrollData, classIndex, classId)
    local classData =
    {
        classIndex = classIndex,
        classId = classId
    }
    local headerData = ZO_EntryData:New(classData)
    headerData.collapsed = self.collapsedClassIds[classId]
    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(CLASS_HEADER_DATA, headerData))

    if not headerData.collapsed then
        local numSkillLines = GetNumSkillLinesForClass(classId)
        for skillLineIndex = 1, numSkillLines do
            local skillLineId = GetSkillLineIdForClass(classId, skillLineIndex)
            local skillLineData = SKILLS_DATA_MANAGER:GetSkillLineDataById(skillLineId)
            local entryData = ZO_EntryData:New(skillLineData)
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILLLINE_INFO_DATA, entryData))
        end
    end
    return headerData
end

function ZO_SkillsSubclassing_Keyboard:RefreshClassSkillLines()
    local scrollData = ZO_ScrollList_GetDataList(self.classSkillLineList)
    ZO_ClearNumericallyIndexedTable(scrollData)

    local playerHeaderData = self:AddClassSkillLines(scrollData, 0, self.playerClassId)

    for classIndex, classId in ipairs(self.classIndexToIdList) do
        if classId == self.playerClassId then
            playerHeaderData.classIndex = classIndex
        else
            self:AddClassSkillLines(scrollData, classIndex, classId)
        end
    end

    ZO_ScrollList_Commit(self.classSkillLineList)
end

do
    local g_shownHeaderTexts = {}

    function ZO_SkillsSubclassing_Keyboard:RefreshSkillsList()
        local DONT_FORCE_INIT = nil
        local DONT_DISABLE = false
        local IS_SUBCLASSING = true
        local DONT_ANIMATE_INSTANTLY = false
        local skillLineData = self.currentSkillLineData
        self:SkillLineReset(self.skillsListInfo)
        local IS_PREVIEW = true
        self:SkillLineSetup(self.skillsListInfo, skillLineData, IS_PREVIEW)
        self.skillsListInfo:SetHidden(false)

        local scrollData = ZO_ScrollList_GetDataList(self.skillsList)
        ZO_ClearNumericallyIndexedTable(scrollData)
        ZO_ClearTable(g_shownHeaderTexts)

        local function IsSkillVisible(skillData)
            return not skillData:IsHidden()
        end

        for _, skillData in skillLineData:SkillIterator({ IsSkillVisible }) do
            local headerText = skillData:GetHeaderText()
            if not g_shownHeaderTexts[headerText] then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILL_HEADER_DATA, { headerText = headerText }))
                g_shownHeaderTexts[headerText] = true
            end

            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILL_ABILITY_DATA, { skillData = skillData, }))
        end

        ZO_ScrollList_Commit(self.skillsList)
    end
end

function ZO_SkillsSubclassing_Keyboard:SetAllHeadersCollapseState(collapsed)
    if collapsed then
        for _, classId in ipairs(self.classIndexToIdList) do
            self.collapsedClassIds[classId] = true
        end
    else
        ZO_ClearTable(self.collapsedClassIds)
    end
    self:RefreshClassSkillLines()
end

function ZO_SkillsSubclassing_Keyboard:GetAndClearSkillLineToSelect()
    local skillLineToSelect = self.skillLineToSelect
    self.skillLineToSelect = nil
    return skillLineToSelect
end

function ZO_SkillsSubclassing_Keyboard:InitializeSkillLineSwapDialog()
    local dialogControl = ZO_SkillLineSwapSelectionDialog
    dialogControl.description = dialogControl:GetNamedChild("Description")

    dialogControl.currentSkillLineControls =
    {
        dialogControl:GetNamedChild("OptionsCurrentSkillLine1"),
        dialogControl:GetNamedChild("OptionsCurrentSkillLine2"),
        dialogControl:GetNamedChild("OptionsCurrentSkillLine3"),
    }

    local function OnMouseEnter(clickableAreaControl)
        local control = clickableAreaControl:GetParent()
        local disabled = #control.errorTooltips > 0
        if disabled then
            local SET_TO_FULL_SIZE = true
            local errorR, errorG, errorB = ZO_ERROR_COLOR:UnpackRGB()
            InitializeTooltip(InformationTooltip, control, TOPLEFT, 40, 10)
            for i, errorString in ipairs(control.errorTooltips) do
                InformationTooltip:AddLine(errorString, "", errorR, errorG, errorB, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, SET_TO_FULL_SIZE)
            end
        end
        local xpBarControl = control.xpBar:GetControl()
        local IS_SUBCLASSING = true
        ZO_SkillInfoXPBar_OnMouseEnter(xpBarControl, -160, IS_SUBCLASSING)
        if not disabled then
            ZO_ResponsiveArrowBar_OnMouseEnter(xpBarControl)
        end
    end

    local function OnMouseExit(clickableAreaControl)
        ClearTooltip(InformationTooltip)
        local control = clickableAreaControl:GetParent()
        ZO_SkillInfoXPBar_OnMouseExit()
        ZO_ResponsiveArrowBar_OnMouseExit(control.xpBar:GetControl())
    end

    local function SetupSkillLineSwapSelectionDialog(dialog, skillLineData)
        dialog.description:SetText(zo_strformat(SI_SKILLS_SUBCLASSING_SWAP_DIALOG_DESCRIPTION_FORMATTER, skillLineData:GetName()))

        dialog.swapInSkillLineData = skillLineData
        dialogControl.selectedSkillLineData = nil

        local DONT_FORCE_INIT = nil
        local DONT_DISABLE = false
        local IS_SUBCLASSING = true
        local ANIMATE_INSTANTLY = true
        local playerClassId = GetUnitClassId("player")
        local numPlayerClassActiveSkillLines = SKILLS_DATA_MANAGER:GetNumPlayerClassActiveSkillLines()
        local swapInSkillLineClassId = skillLineData:GetClassId()
        local swapInClassActiveSkillLine = SKILLS_DATA_MANAGER:GetFirstActiveSkillLineByClassId(swapInSkillLineClassId)
        local swapInSkillLineName = ZO_WHITE:Colorize(skillLineData:GetName())
        for i, control in ipairs(dialog.currentSkillLineControls) do
            local currentSkillLineData = SKILLS_DATA_MANAGER:GetActiveClassSkillLine(i)
            local currentSkillLineName = ZO_WHITE:Colorize(currentSkillLineData:GetName())

            control.skillLineData = currentSkillLineData
            control.errorTooltips = {}

            control:GetNamedChild("Check"):SetHidden(true)
            local clickableAreaControl = control:GetNamedChild("ClickableArea")

            ZO_SkillLineInfo_Keyboard_Refresh(control, currentSkillLineData, DONT_FORCE_INIT, ANIMATE_INSTANTLY, DONT_DISABLE, IS_SUBCLASSING)

            local controlClassId = control.skillLineData:GetClassId()
            control.name:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
            if numPlayerClassActiveSkillLines <= 1 and controlClassId == playerClassId and swapInSkillLineClassId ~= playerClassId then
                table.insert(control.errorTooltips, GetString(SI_SKILLS_SUBCLASSING_ERROR_MIN_PLAYER_CLASS_SKILL_LINE))
            end

            if swapInClassActiveSkillLine and controlClassId ~= swapInSkillLineClassId and not swapInClassActiveSkillLine:IsPlayerClassSkillLine() then
                table.insert(control.errorTooltips, GetString(SI_SKILLS_SUBCLASSING_ERROR_MAX_SKILL_LINES_PER_CLASS))
            end

            local swapSkillPointDeficit = skillLineData:GetSwappingForRespecSkillPointsDeficit(currentSkillLineData)
            if swapSkillPointDeficit > 0 then
                local IGNORE_ACTIVE_STATE = true
                local numSkillPointsAllocatedInSkillLine = ZO_WHITE:Colorize(SKILL_POINT_ALLOCATION_MANAGER:GetNumPointsAllocatedInSkillLine(skillLineData, IGNORE_ACTIVE_STATE))
                local deficitErrorText = zo_strformat(SI_SKILLS_SUBCLASSING_ERROR_NOT_ENOUGH_SKILL_POINTS_TO_SWAP, swapInSkillLineName, numSkillPointsAllocatedInSkillLine)
                table.insert(control.errorTooltips, deficitErrorText)
            end

            if #control.errorTooltips > 0 then
                local headerErrorText = zo_strformat(SI_SKILLS_SUBCLASSING_SWAP_SKILL_LINE_GENERAL_ERROR_FORMATTER, currentSkillLineName, swapInSkillLineName)
                table.insert(control.errorTooltips, 1, headerErrorText)
                control.name:SetColor(ZO_ERROR_COLOR:GetDim():UnpackRGBA())
            end

            clickableAreaControl:SetHandler("OnMouseEnter", OnMouseEnter)
            clickableAreaControl:SetHandler("OnMouseExit", OnMouseExit)
        end

        ZO_Dialogs_UpdateButtonVisibilityAndEnabledState(dialogControl)

        local SKIP_ANIMATIONS = true
        TUTORIAL_SYSTEM:ForceRemoveAll(SKIP_ANIMATIONS)
        local tutorialAnchor = ZO_Anchor:New(LEFT, dialogControl, RIGHT)
        TUTORIAL_SYSTEM:RegisterTriggerLayoutInfo(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_SUBCLASSING_SWAP_SKILL_LINE_POINTER_BOX, dialogControl, SKILLS_WINDOW, tutorialAnchor)

        TriggerTutorial(TUTORIAL_TRIGGER_SUBCLASSING_SWAP_SKILL_LINE_POINTER_BOX)
    end

    local function OnSelectSkillLineClicked(button)
        local selectedControl = button:GetParent()

        if #selectedControl.errorTooltips == 0 then
            local DONT_FORCE_INIT = nil
            local IS_SUBCLASSING = true
            local ANIMATE_INSTANTLY = true
            for i, control in ipairs(dialogControl.currentSkillLineControls) do
                local isSelectedControl = control == selectedControl
                ZO_SkillLineInfo_Keyboard_Refresh(control, control.skillLineData, DONT_FORCE_INIT, ANIMATE_INSTANTLY, not isSelectedControl, IS_SUBCLASSING)
                control:GetNamedChild("Check"):SetHidden(not isSelectedControl)
            end
            PlaySound(SOUNDS.TREE_SUBCATEGORY_CLICK)
            dialogControl.selectedSkillLineData = selectedControl.skillLineData
            ZO_Dialogs_UpdateButtonVisibilityAndEnabledState(dialogControl)
        else
            PlaySound(SOUNDS.GENERAL_ALERT_ERROR)
        end
    end

    for i, control in ipairs(dialogControl.currentSkillLineControls) do
        control:GetNamedChild("ClickableArea"):SetHandler("OnClicked", OnSelectSkillLineClicked)
        control:GetNamedChild("Check"):SetHidden(true)
    end

    ZO_Dialogs_RegisterCustomDialog("SKILL_LINE_SWAP_SELECTION",
    {
        customControl = dialogControl,
        setup = SetupSkillLineSwapSelectionDialog,
        title =
        {
            text = SI_SKILLS_SUBCLASSING_SWAP_DIALOG_TITLE,
        },
        buttons =
        {
            {
                control = dialogControl:GetNamedChild("Confirm"),
                text =  SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    if dialog.selectedSkillLineData:CanDeactivateForRespec() then
                        if dialog.swapInSkillLineData:CanActivateForRespec() then
                            local SUPPRESS_CALLBACK = true
                            dialog.selectedSkillLineData:DeactivateForRespec(SUPPRESS_CALLBACK)
                            dialog.swapInSkillLineData:ActivateForRespec()
                            PlaySound(SOUNDS.SKILLS_SUBCLASSING_SWAP_SKILL_LINE_CONFIRM)
                            self.currentSkillLineData = nil
                            self.skillLineToSelect = dialog.swapInSkillLineData
                        end
                    end
                end,
                enabled = function(dialog)
                    return dialog.selectedSkillLineData ~= nil and dialog.swapInSkillLineData ~= nil
                end
            },
            {
                control = dialogControl:GetNamedChild("Cancel"),
                text = SI_CANCEL,
            }
        },
        finishedCallback = function(dialog)
            TUTORIAL_SYSTEM:RemoveTutorialByTrigger(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_SUBCLASSING_SWAP_SKILL_LINE_POINTER_BOX)
        end,
    })
end

function ZO_SkillsSubclassing_Keyboard.OnClassHeaderInitialize(control)
    control.contentsContainer = control:GetNamedChild("Contents")
    control.nameLabel = control.contentsContainer:GetNamedChild("Name")
    control.expandedStateButton = control.contentsContainer:GetNamedChild("ExpandedState")
end

function ZO_SkillsSubclassing_Keyboard:OnClassHeaderMouseUp(control, button, upInside)
    if upInside then
        local headerData = control.dataEntry.data
        local function ToggleHeaderExpansion()
            headerData.collapsed = not headerData.collapsed
            if headerData.collapsed then
                PlaySound(SOUNDS.TREE_SUBCATEGORY_CLICK)
                self.collapsedClassIds[headerData.classId] = true
            else
                PlaySound(SOUNDS.TREE_SUBCATEGORY_CLICK)
                self.collapsedClassIds[headerData.classId] = nil
            end
            self:RefreshClassSkillLines()
        end

        if button == MOUSE_BUTTON_INDEX_LEFT then
            ToggleHeaderExpansion()
        elseif button == MOUSE_BUTTON_INDEX_RIGHT then
            ClearMenu()

            if headerData.collapsed then
                AddMenuItem(GetString(SI_ITEM_SETS_BOOK_HEADER_EXPAND), ToggleHeaderExpansion)
            else
                AddMenuItem(GetString(SI_ITEM_SETS_BOOK_HEADER_COLLAPSE), ToggleHeaderExpansion)
            end

            AddMenuItem(GetString(SI_ITEM_SETS_BOOK_HEADER_EXPAND_ALL), function() self:SetAllHeadersCollapseState(false) end)
            AddMenuItem(GetString(SI_ITEM_SETS_BOOK_HEADER_COLLAPSE_ALL), function() self:SetAllHeadersCollapseState(true) end)

            ShowMenu(control)
        end
    end
end

function ZO_SkillsSubclassing_Keyboard.OnClassHeaderMouseEnter(control)
    local headerData = control.dataEntry.data
    local classId = headerData.classId
    local classIndex = GetClassIndexById(classId)
    local _, lore = GetClassInfo(classIndex)
    InitializeTooltip(InformationTooltip, control.contentsContainer, RIGHT)
    InformationTooltip:AddLine(lore, "", ZO_NORMAL_TEXT:UnpackRGBA())

    control.nameLabel:SetColor(ZO_HIGHLIGHT_TEXT:UnpackRGBA())
end

function ZO_SkillsSubclassing_Keyboard.OnClassHeaderMouseExit(control)
    ClearTooltip(InformationTooltip)

    control.nameLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
end

function ZO_SkillsSubclassing_Keyboard:OnActionButtonClicked(control)
    local skillLineData = control.skillLineData
    if skillLineData then
        if skillLineData:IsContentLocked() then
            local collectibleId = skillLineData:GetClassAccessCollectibleId()
            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
            if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_CHAPTER) then
                ZO_ShowChapterUpgradePlatformScreen(MARKET_OPEN_OPERATION_SKILLS_SUBCLASSING)
            else
                local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData:GetName())
                ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_SKILLS_SUBCLASSING)
            end
        elseif SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
            if skillLineData:CanActivateForRespec() then
                ZO_Dialogs_ShowDialog("SKILL_LINE_SWAP_SELECTION", skillLineData)
            elseif skillLineData:CanTrain() then
                TriggerTutorial(TUTORIAL_TRIGGER_SUBCLASSING_TRAIN_SKILL_LINE)
                skillLineData:Train()
                PlaySound(SOUNDS.SKILLS_SUBCLASSING_TRAIN)
            end
        end
    end
end

function ZO_SkillsSubclassing_Keyboard:OnActionButtonMouseEnter(actionControl)
    local control = actionControl:GetParent()
    local tooltipText
    local skillLineData = control.skillLineData
    if skillLineData then
        if skillLineData:IsContentLocked() then
            tooltipText = GetString(SI_SKILLS_SUBCLASSING_OPEN_STORE_ACTION)
        elseif SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
            if skillLineData:CanActivateForRespec() then
                tooltipText = GetString(SI_SKILLS_SUBCLASSING_EQUIP_ACTION)
            elseif skillLineData:CanTrain() then
                tooltipText = GetString(SI_SKILLS_SUBCLASSING_TRAIN_ACTION)
            end
        end
    end

    if tooltipText then
        InitializeTooltip(InformationTooltip, actionControl, RIGHT)
        InformationTooltip:AddLine(tooltipText, "", ZO_NORMAL_TEXT:UnpackRGBA())
    end
end

function ZO_SkillsSubclassing_Keyboard:OnActionButtonMouseExit(actionControl)
    ClearTooltip(InformationTooltip)
end

function ZO_SkillsSubclassing_Keyboard:OnUntrainButtonClicked(control, shift)
    if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
        local skillLineData = control.skillLineData
        if skillLineData and skillLineData:CanUntrain() then
            skillLineData:Untrain()
            PlaySound(SOUNDS.SKILLS_SUBCLASSING_UNTRAIN)
        end
    end
end

function ZO_SkillsSubclassing_Keyboard:OnUntrainButtonMouseEnter(actionControl)
    InitializeTooltip(InformationTooltip, actionControl, RIGHT)
    InformationTooltip:AddLine(GetString(SI_SKILLS_SUBCLASSING_UNTRAIN_ACTION), "", ZO_NORMAL_TEXT:UnpackRGBA())
end

function ZO_SkillsSubclassing_Keyboard:OnUntrainButtonMouseExit(control)
    ClearTooltip(InformationTooltip)
end

--[[Global functions]]--
------------------------

function ZO_SkillsSubclassing_SkillLine_Keyboard_OnInitialize(control)
    control.actionButton = control:GetNamedChild("Action")
    control.untrainButton = control:GetNamedChild("Untrain")
end

function ZO_SkillsTrainingInfo_Keyboard_OnMouseEnter(control)
    local numTrainingSkillLines = SKILLS_DATA_MANAGER:GetNumSkillLinesInTraining()
    local statusText = zo_strformat(SI_SKILLS_SUBCLASSING_TRAINING_TOOLTIP_FORMATTER_STATUS, numTrainingSkillLines, MAX_SKILL_LINES_IN_TRAINING)

    InitializeTooltip(InformationTooltip, control, TOPRIGHT, -5)
    InformationTooltip:AddLine(statusText, "", ZO_NORMAL_TEXT:UnpackRGBA())

    for i = 1, numTrainingSkillLines do
        local skillLineData = SKILLS_DATA_MANAGER:GetSkillLineInTrainingAtIndex(i)
        local skillLineText = zo_strformat(SI_SKILLS_SUBCLASSING_TRAINING_SKILL_LINE_FORMATTER, skillLineData:GetClassName(), skillLineData:GetName())
        InformationTooltip:AddLine(skillLineText, "", ZO_NORMAL_TEXT:UnpackRGBA())
    end

    InformationTooltip:AddLine(GetString(SI_SKILLS_SUBCLASSING_TRAINING_TOOLTIP_FORMATTER_INFO), "", ZO_NORMAL_TEXT:UnpackRGBA())
end

function ZO_SkillsTrainingInfo_Keyboard_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_Class_Header_Entry_Keyboard_OnMouseUp(control, button, upInside)
    SKILLS_WINDOW.subclassingPanel:OnClassHeaderMouseUp(control, button, upInside)
end

function ZO_Skills_SubclassSkillLine_OnClicked(control, shift)
    SKILLS_WINDOW.subclassingPanel:OnActionButtonClicked(control:GetParent())
end

function ZO_Skills_SubclassSkillLine_OnMouseEnter(control)
    SKILLS_WINDOW.subclassingPanel:OnActionButtonMouseEnter(control)
end

function ZO_Skills_SubclassSkillLine_OnMouseExit(control)
    SKILLS_WINDOW.subclassingPanel:OnActionButtonMouseExit(control)
end

function ZO_Skills_SubclassSkillLine_Untrain_OnClicked(control, shift)
    SKILLS_WINDOW.subclassingPanel:OnUntrainButtonClicked(control:GetParent())
end

function ZO_Skills_SubclassSkillLine_Untrain_OnMouseEnter(control)
    SKILLS_WINDOW.subclassingPanel:OnUntrainButtonMouseEnter(control)
end

function ZO_Skills_SubclassSkillLine_Untrain_OnMouseExit(control)
    SKILLS_WINDOW.subclassingPanel:OnUntrainButtonMouseExit(control)
end

function ZO_Skills_SubclassSkillLine_SkillsListBackButton_OnClicked(control)
    SKILLS_WINDOW.subclassingPanel:MarkRefreshGroupDirty("ResetToClassSkillLines")
    PlaySound(SOUNDS.SKILLS_SUBCLASSING_SKILL_LINE_BACK)
end