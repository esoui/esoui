-----------------------------
-- Companion Skills
-----------------------------
ZO_COMPANION_SKILLS_KEYBOARD_SKILL_LINE_CONTAINER_WIDTH = 330
ZO_COMPANION_SKILLS_KEYBOARD_SKILL_LINE_ENTRY_INDENT = 74
ZO_COMPANION_SKILLS_KEYBOARD_SKILL_LINE_ENTRY_LABEL_WIDTH = ZO_COMPANION_SKILLS_KEYBOARD_SKILL_LINE_CONTAINER_WIDTH - ZO_COMPANION_SKILLS_KEYBOARD_SKILL_LINE_ENTRY_INDENT - ZO_SCROLL_BAR_WIDTH

ZO_CompanionSkills_Keyboard = ZO_InitializingObject:Subclass()

function ZO_CompanionSkills_Keyboard:Initialize(control)
    self.control = control

    self.scene = ZO_InteractScene:New("companionSkillsKeyboard", SCENE_MANAGER, ZO_COMPANION_MANAGER:GetInteraction())
    self.scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.skillLinesTreeRefreshGroup:TryClean()
            self.skillListRefreshGroup:TryClean()

            ACTION_BAR_ASSIGNMENT_MANAGER:SetHotbarCycleOverride(HOTBAR_CATEGORY_COMPANION)
            self.assignableActionBar:RefreshAllButtons()
        elseif newState == SCENE_HIDDEN then
            SKILLS_AND_ACTION_BAR_MANAGER:ResetInterface()
            ACTION_BAR_ASSIGNMENT_MANAGER:SetHotbarCycleOverride(nil)
        end
    end)

    COMPANION_SKILLS_KEYBOARD_SCENE = self.scene
    COMPANION_SKILLS_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(self.control)

    self:InitializeSkillLinesTree()
    self:InitializeSkillList()
    self.advisedOverlay = ZO_Skills_SkillLineAdvisedOverlay:New(control:GetNamedChild("SkillLineAdvisedOverlay"))
    self.assignableActionBar = ZO_KeyboardAssignableActionBar:New(control:GetNamedChild("AssignableActionBar"))
    self.skillLineInfo = control:GetNamedChild("SkillLineInfo")

    self:RegisterForEvents()
end

function ZO_CompanionSkills_Keyboard:InitializeSkillLinesTree()
    local container = self.control:GetNamedChild("SkillLinesContainer")

    local DEFAULT_SPACING = -10
    local TREE_WIDTH = ZO_COMPANION_SKILLS_KEYBOARD_SKILL_LINE_CONTAINER_WIDTH - ZO_SCROLL_BAR_WIDTH
    local skillLinesTree = ZO_Tree:New(container:GetNamedChild("ScrollChild"), ZO_COMPANION_SKILLS_KEYBOARD_SKILL_LINE_ENTRY_INDENT, DEFAULT_SPACING, TREE_WIDTH)

    local NEW_COMPANION_SKILLS_FILTER = { ZO_CompanionSkillLineData.IsNew }
    local function TreeHeaderSetup(node, control, skillTypeData, open)
        control.skillTypeData = skillTypeData
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(skillTypeData:GetName())
        local up, down, over = skillTypeData:GetKeyboardIcons()
        
        control.icon:SetTexture(open and down or up)
        control.iconHighlight:SetTexture(over)

        control.statusIcon:ClearIcons()

        if not ZO_IsIteratorEmpty(skillTypeData:SkillLineIterator(NEW_COMPANION_SKILLS_FILTER)) then
            control.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end

        control.statusIcon:Show()
        
        ZO_IconHeader_Setup(control, open)
    end

    local NO_SELECTION_FUNCTION = nil
    local NO_EQUALITY_FUNCTION = nil
    local DEFAULT_CHILD_INDENT = nil
    local childSpacing = 0
    skillLinesTree:AddTemplate("ZO_SkillIconHeader", TreeHeaderSetup, NO_SELECTION_FUNCTION, NO_EQUALITY_FUNCTION, DEFAULT_CHILD_INDENT, childSpacing)

    local function TreeEntrySetup(node, control, skillLineData, open)
        control:SetText(skillLineData:GetFormattedName())

        control.statusIcon:ClearIcons()

        if skillLineData:IsNew() then
            control.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end

        control.statusIcon:Show()
    end

    local function TreeEntryOnSelected(control, skillLineData, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected and not reselectingDuringRebuild then
            self:RefreshSkillLineInfo()
            skillLineData:ClearNew()
            self.skillListRefreshGroup:MarkDirty("List")
            self.skillListRefreshGroup:TryClean()
        end
    end

    skillLinesTree:AddTemplate("ZO_CompanionSkills_SkillLineEntry", TreeEntrySetup, TreeEntryOnSelected)

    skillLinesTree:SetExclusive(true)
    skillLinesTree:SetOpenAnimation("ZO_TreeOpenAnimation")

    local skillLinesTreeRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    skillLinesTreeRefreshGroup:AddDirtyState("List", function()
        self:RefreshSkillLines()
    end)
    skillLinesTreeRefreshGroup:AddDirtyState("Visible", function()
        skillLinesTree:RefreshVisible()
    end)
    skillLinesTreeRefreshGroup:SetActive(function()
        return COMPANION_SKILLS_KEYBOARD_SCENE:IsShowing()
    end)

    skillLinesTreeRefreshGroup:MarkDirty("List")

    self.skillLinesTreeRefreshGroup = skillLinesTreeRefreshGroup
    self.skillLinesTree = skillLinesTree
end

function ZO_CompanionSkills_Keyboard:GetSelectedSkillLineData()
    return self.skillLinesTree:GetSelectedData()
end

local SKILL_ABILITY_DATA = 1
local SKILL_HEADER_DATA = 2

function ZO_CompanionSkills_Keyboard:InitializeSkillList()
    local skillList = self.control:GetNamedChild("SkillList")

    local SKILL_ABILITY_HEIGHT = 70
    ZO_ScrollList_AddDataType(skillList, SKILL_ABILITY_DATA, "ZO_Skills_Ability", SKILL_ABILITY_HEIGHT, function(abilityControl, data)
        ZO_Skills_CompanionSkillEntry_Setup(abilityControl, data.skillData)
    end)
    local SKILL_HEADER_HEIGHT = 32
    ZO_ScrollList_AddDataType(skillList, SKILL_HEADER_DATA, "ZO_Skills_AbilityTypeHeader", SKILL_HEADER_HEIGHT, function(headerControl, data)
        headerControl:GetNamedChild("Label"):SetText(data.headerText)
    end)
    ZO_ScrollList_AddResizeOnScreenResize(skillList)

    local skillListRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    skillListRefreshGroup:AddDirtyState("List", function()
        self:RefreshSkills()
    end)
    skillListRefreshGroup:AddDirtyState("Visible", function()
        local skillLineData = self:GetSelectedSkillLineData()
        if skillLineData then
            ZO_ScrollList_RefreshVisible(skillList)
        end
    end)
    skillListRefreshGroup:SetActive(function()
        return COMPANION_SKILLS_KEYBOARD_SCENE:IsShowing()
    end)

    self.skillListRefreshGroup = skillListRefreshGroup
    self.skillList = skillList
end

function ZO_CompanionSkills_Keyboard:RegisterForEvents()
    local control = self.control

    local function OnFullSystemUpdated()
        self.skillLinesTreeRefreshGroup:MarkDirty("List")
    end

    local function OnSkillLineUpdated(skillLineData)
        if skillLineData == self:GetSelectedSkillLineData() then
            self:RefreshSkillLineInfo()
            self.skillListRefreshGroup:MarkDirty("Visible")
        end
    end

    local function OnSkillProgressionUpdated(skillData)
        if skillData:GetSkillLineData() == self:GetSelectedSkillLineData() then
            self.skillListRefreshGroup:MarkDirty("Visible")
        end
    end

    local function OnSkillLineNewStatusChanged()
        self.skillLinesTreeRefreshGroup:MarkDirty("Visible")
    end

    COMPANION_SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", OnFullSystemUpdated)
    COMPANION_SKILLS_DATA_MANAGER:RegisterCallback("SkillLineUpdated", OnSkillLineUpdated)
    COMPANION_SKILLS_DATA_MANAGER:RegisterCallback("SkillProgressionUpdated", OnSkillProgressionUpdated)
    COMPANION_SKILLS_DATA_MANAGER:RegisterCallback("SkillLineNewStatusChanged", OnSkillLineNewStatusChanged)

    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnFullSystemUpdated)

    local function OnPurchaseLockStateChanged()
        self.skillListRefreshGroup:MarkDirty("Visible")
    end
    control:RegisterForEvent(EVENT_ACTION_BAR_LOCKED_REASON_CHANGED, OnPurchaseLockStateChanged)
end

do
    local AVAILABLE_COMPANION_SKILLS_FILTER = { ZO_CompanionSkillLineData.IsAvailableOrAdvised }
    function ZO_CompanionSkills_Keyboard:RefreshSkillLines()
        self.skillLinesTree:Reset()
        for _, skillTypeData in COMPANION_SKILLS_DATA_MANAGER:SkillTypeIterator() do
            local parent
            for _, skillLineData in skillTypeData:SkillLineIterator(AVAILABLE_COMPANION_SKILLS_FILTER) do
                if not parent then
                    parent = self.skillLinesTree:AddNode("ZO_SkillIconHeader", skillTypeData)
                end
                self.skillLinesTree:AddNode("ZO_CompanionSkills_SkillLineEntry", skillLineData, parent)
            end
        end

        self.skillLinesTree:Commit()

        self.skillListRefreshGroup:MarkDirty("List")
        self.skillListRefreshGroup:TryClean()

        local FORCE_INIT = true
        self:RefreshSkillLineInfo(FORCE_INIT)
    end
end

function ZO_CompanionSkills_Keyboard:RefreshSkills()
    local scrollData = ZO_ScrollList_GetDataList(self.skillList)
    ZO_ScrollList_Clear(self.skillList)

    local skillLineData = self:GetSelectedSkillLineData()
    if skillLineData then
        local lastHeaderText = nil
        for _, skillData in skillLineData:SkillIterator() do
            local headerText = skillData:GetHeaderText()
            if lastHeaderText ~= headerText then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILL_HEADER_DATA, { headerText = headerText }))
                lastHeaderText = headerText
            end

            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILL_ABILITY_DATA, { skillData = skillData }))
        end
    end

    ZO_ScrollList_Commit(self.skillList)

    self:RefreshSkillLineAdvisedOverlay(skillLineData)
end

function ZO_CompanionSkills_Keyboard:RefreshSkillLineInfo(forceInit)
    local skillLineData = self:GetSelectedSkillLineData()
    if skillLineData then
        self.skillLineInfo:SetHidden(false)
        ZO_SkillLineInfo_Keyboard_Refresh(self.skillLineInfo, skillLineData, forceInit)
    else
        self.skillLineInfo:SetHidden(true)
    end
end

function ZO_CompanionSkills_Keyboard:RefreshSkillLineAdvisedOverlay(skillLineData)
    if skillLineData and not skillLineData:IsAvailable() and skillLineData:IsAdvised() then
        self.advisedOverlay:Show(skillLineData)
        self.skillList:SetAlpha(0.1)
    else
        self.advisedOverlay:Hide()
        self.skillList:SetAlpha(1)
    end 
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_CompanionSkills_Keyboard_OnInitialize(control)
    COMPANION_SKILLS_KEYBOARD = ZO_CompanionSkills_Keyboard:New(control)
end