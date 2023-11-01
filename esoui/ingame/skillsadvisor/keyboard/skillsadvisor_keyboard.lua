ZO_SkillsAdvisor_Keyboard = ZO_Object:Subclass()

function ZO_SkillsAdvisor_Keyboard:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_SkillsAdvisor_Keyboard:Initialize(control)
    control.owner = self
    self.control = control

    -- Setup Tabs
    local MENU_BAR_DATA =
    {
        initialButtonAnchorPoint = RIGHT,
        buttonTemplate = "ZO_MenuBarTooltipButton",
        normalSize = 51,
        downSize = 64,
        buttonPadding = -15,
        animationDuration = 180,
    }

    self.tabs = control:GetNamedChild("SelectionTabBar")
    self.windowTitleControl = control:GetNamedChild("Title")
    self.selectedBuildControl = control:GetNamedChild("SelectedBuild")
    self.selectedBuildHelpControl = control:GetNamedChild("Help")
    self:SetSelectedSkillBuildName()

    ZO_MenuBar_SetData(self.tabs, MENU_BAR_DATA)

    self.suggestionData = ZO_MenuBar_GenerateButtonTabData(SI_TOOLTIP_SKILLS_ADVISOR_SUGGESTIONS_TAB, "suggestionTab", "EsoUI/Art/SkillsAdvisor/advisor_tabIcon_tutorial_up.dds", "EsoUI/Art/SkillsAdvisor/advisor_tabIcon_tutorial_down.dds", "EsoUI/Art/SkillsAdvisor/advisor_tabIcon_tutorial_over.dds", "EsoUI/Art/SkillsAdvisor/advisor_tabIcon_tutorial_disabled.dds", nil, nil, function() self:HandleTabChange() end)
    self.buildsData = ZO_MenuBar_GenerateButtonTabData(SI_TOOLTIP_SKILLS_ADVISOR_BUILDS_TAB, "buildsTab", "EsoUI/Art/SkillsAdvisor/advisor_tabIcon_settings_up.dds", "EsoUI/Art/SkillsAdvisor/advisor_tabIcon_settings_down.dds", "EsoUI/Art/SkillsAdvisor/advisor_tabIcon_settings_over.dds", "", nil, nil, function() self:HandleTabChange() end)

    ZO_MenuBar_AddButton(self.tabs, self.buildsData)
    ZO_MenuBar_AddButton(self.tabs, self.suggestionData)

    SKILLS_ADVISOR_FRAGMENT = ZO_FadeSceneFragment:New(control)
    SKILLS_ADVISOR_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_SHOWN then
            self:OnShown()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)

    function OnDataUpdated()
        if SKILLS_ADVISOR_FRAGMENT:GetState() ~= SCENE_FRAGMENT_HIDDEN then
            self:UpdateSkillsAdvisorBuildSelection()
        else
            self.dirtyFlag = true
        end
    end

    self:SetSelectedTab()

    do
    -- Skill Build Selection Tutorial Setup
        local tutorialAnchor = ZO_Anchor:New(LEFT, self.tabs, RIGHT, 40, 0)
        TUTORIAL_SYSTEM:RegisterTriggerLayoutInfo(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_SKILL_BUILD_SELECTION_POINTER_BOX, self.control, ZO_SKILLS_ADVISOR_WINDOW, tutorialAnchor)
    end

    ZO_SKILLS_ADVISOR_SINGLETON:RegisterCallback("OnSelectedSkillBuildUpdated", OnDataUpdated)
end

function ZO_SkillsAdvisor_Keyboard:UpdateSkillsAdvisorBuildSelection()
    self:SetSelectedSkillBuildName()
    self:SetSelectedTab()
    self:HandleTabChange()
    self.dirtyFlag = false
end

function ZO_SkillsAdvisor_Keyboard:SetSelectedTab()
    self.windowTitleControl:ClearAnchors()

    if ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() then
        self.selectedBuildControl:SetHidden(true)
        self.selectedBuildHelpControl:SetHidden(true)

        local dividerControl = self.control:GetNamedChild("Divider")
        self.windowTitleControl:SetAnchor(BOTTOMLEFT, dividerControl, TOPLEFT)
        
        ZO_MenuBar_SelectDescriptor(self.tabs, self.buildsData.descriptor)
        ZO_MenuBar_SetDescriptorEnabled(self.tabs, self.suggestionData.descriptor, false)
    else
        self.selectedBuildControl:SetHidden(false)
        self.selectedBuildHelpControl:SetHidden(false)

        self.windowTitleControl:SetAnchor(LEFT, self.selectedBuildHelpControl, LEFT, 0, 0, ANCHOR_CONSTRAINS_X)
        self.windowTitleControl:SetAnchor(BOTTOM, self.selectedBuildControl, TOP, 0, 0, ANCHOR_CONSTRAINS_Y)
 
        ZO_MenuBar_SetDescriptorEnabled(self.tabs, self.suggestionData.descriptor, true)
        ZO_MenuBar_SelectDescriptor(self.tabs, self.suggestionData.descriptor)
    end
end

function ZO_SkillsAdvisor_Keyboard:SetSelectedSkillBuildName()
    local skillBuildId = ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildId()
    local skillBuild = ZO_SKILLS_ADVISOR_SINGLETON:GetAvailableSkillBuildById(skillBuildId)
    if skillBuild then
        self.selectedBuildControl:SetText(skillBuild.name)
    end
end

function ZO_SkillsAdvisor_Keyboard:AnchorControlInTabContent(control) 
    local anchorControl = self.control:GetNamedChild("Divider")

    control:ClearAnchors()
    control:SetAnchor(TOPLEFT, anchorControl, BOTTOMLEFT)
    control:SetAnchor(BOTTOMRIGHT, self.control, BOTTOMRIGHT)
end

function ZO_SkillsAdvisor_Keyboard:OnShowing()
    SCENE_MANAGER:AddFragment(MEDIUM_LEFT_PANEL_BG_FRAGMENT)
    if self.dirtyFlag then
        self:UpdateSkillsAdvisorBuildSelection()
    else
        self:SetSelectedSkillBuildName()
        self:HandleTabChange()
    end
end

function ZO_SkillsAdvisor_Keyboard:OnShown()
    local level = GetUnitLevel("player")
    if level >= GetSkillBuildTutorialLevel() then
        TriggerTutorial(TUTORIAL_TRIGGER_SKILL_BUILD_SELECTION_POINTER_BOX)
    end
end

function ZO_SkillsAdvisor_Keyboard:OnHidden()
    SCENE_MANAGER:RemoveFragment(self.currentTabFragment)
    SCENE_MANAGER:RemoveFragment(MEDIUM_LEFT_PANEL_BG_FRAGMENT)
end

function ZO_SkillsAdvisor_Keyboard:HandleTabChange()
    TUTORIAL_SYSTEM:RemoveTutorialByTrigger(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_SKILL_BUILD_SELECTION_POINTER_BOX)
    SCENE_MANAGER:RemoveFragment(self.currentTabFragment)
    self.currentTabFragment = nil
    if ZO_MenuBar_GetSelectedDescriptor(self.tabs) == self.buildsData.descriptor then
        self.currentTabFragment = ZO_SKILLS_ADVISOR_BUILD_SELECT_FRAGMENT
    else
        self.currentTabFragment = ZO_SKILLS_ADVISOR_SUGGESTION_FRAGMENT
    end

    if self.currentTabFragment then 
        SCENE_MANAGER:AddFragment(self.currentTabFragment)
    end
end

function ZO_SkillsAdvisor_KeyboardHelp_OnMouseEnter(control)
    local data = ZO_SKILLS_ADVISOR_SINGLETON:GetAvailableSkillBuildById(ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildId())
    
    InitializeTooltip(GameTooltip, control, TOPLEFT, -15)
    ZO_SKILLS_ADVISOR_SINGLETON:SetupKeyboardSkillBuildTooltip(data)
end

function ZO_SkillsAdvisor_KeyboardHelp_OnMouseExit(control)
    ClearTooltip(GameTooltip)
end

function ZO_SkillsAdvisor_Keyboard_OnInitialized(control)
    ZO_SKILLS_ADVISOR_WINDOW = ZO_SkillsAdvisor_Keyboard:New(control)
end