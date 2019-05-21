--------------
--Initialize--
--------------

local SkillsAdvisorBuildSelectionRoot_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function SkillsAdvisorBuildSelectionRoot_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function SkillsAdvisorBuildSelectionRoot_Gamepad:Initialize(control)
    local ACTIVATE_LIST_ON_SHOW = true
    GAMEPAD_SKILLS_ADVISOR_BUILD_SELECTION_ROOT_SCENE = ZO_Scene:New("gamepad_skills_advisor_build_selection_root", SCENE_MANAGER)
    GAMEPAD_SKILLS_SCENE_GROUP:AddScene("gamepad_skills_advisor_build_selection_root")
    GAMEPAD_SKILLS_ADVISOR_BUILD_SELECTION_ROOT_SCENE:SetHideSceneConfirmationCallback(ZO_GamepadSkills.OnConfirmHideScene)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_LIST_ON_SHOW, GAMEPAD_SKILLS_ADVISOR_BUILD_SELECTION_ROOT_SCENE)

    local skillAdvisorBuildSelectionFragment = ZO_FadeSceneFragment:New(control)
    GAMEPAD_SKILLS_ADVISOR_BUILD_SELECTION_ROOT_SCENE:AddFragment(skillAdvisorBuildSelectionFragment)

    local function OnDataUpdated()
        self:RefreshBuildSelectionList()
    end

    ZO_SKILLS_ADVISOR_SINGLETON:RegisterCallback("OnSelectedSkillBuildUpdated", OnDataUpdated)
end

function SkillsAdvisorBuildSelectionRoot_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            sound = SOUNDS.SKILLS_ADVISOR_SELECT,
            callback = function()
                    local list = self:GetMainList()
                    local selectedData = list:GetSelectedData()
                    ZO_SKILLS_ADVISOR_SINGLETON:OnSkillBuildSelected(selectedData.skillBuildIndex)
                    SCENE_MANAGER:HideCurrentScene()
                end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self:GetMainList())
end

function SkillsAdvisorBuildSelectionRoot_Gamepad:OnDeferredInitialize()
    self.headerData =
    {
        titleText = GetString(SI_SKILLS_ADVISOR_TITLE),
    }

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    self:RefreshBuildSelectionList()
end

function SkillsAdvisorBuildSelectionRoot_Gamepad:SetupList(list)
    local function BuildEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        control.selectedIcon:SetHidden(ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildIndex() ~= data.skillBuildIndex)
    end

    list:AddDataTemplate("ZO_SkillsAdvisorBuildSelection_Gamepad_MenuEntryTemplate", BuildEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_SkillBuild_Template")
  
    local function OnSelectedMenuEntry(_, selectedData, previousData)
        if GAMEPAD_SKILLS_ADVISOR_BUILD_SELECTION_ROOT_SCENE:GetState() ~= SCENE_HIDDEN then
            self:RefreshTooltip(selectedData)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end

    local selectedIndex = ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildIndex()
    if not selectedIndex then
        selectedIndex = 1
    end

    list:SetOnSelectedDataChangedCallback(OnSelectedMenuEntry)
    list:SetDefaultSelectedIndex(selectedIndex)
end

function SkillsAdvisorBuildSelectionRoot_Gamepad:RefreshTooltip(data)
    if self.scene:IsShowing() then
        GAMEPAD_TOOLTIPS:LayoutSkillBuild(GAMEPAD_LEFT_TOOLTIP, data.skillBuildId)
    end
end

function SkillsAdvisorBuildSelectionRoot_Gamepad:RefreshBuildSelectionList()
    local list = self:GetMainList()
    local numSkillBuilds = ZO_SKILLS_ADVISOR_SINGLETON:GetNumSkillBuildOptions()

    list:Clear()
    for skillBuildIndex = 1, numSkillBuilds do
        local skillBuild = ZO_SKILLS_ADVISOR_SINGLETON:GetAvailableSkillBuildByIndex(skillBuildIndex)
        local entryData = ZO_GamepadEntryData:New(skillBuild.name)
        entryData.skillBuildId = skillBuild.id
        entryData.skillBuildIndex = skillBuild.index
        list:AddEntry("ZO_SkillsAdvisorBuildSelection_Gamepad_MenuEntryTemplate", entryData)
    end

    list:Commit()
end

-- Scene state change callbacks overriden from ZO_Gamepad_ParametricList_Screen
function SkillsAdvisorBuildSelectionRoot_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    local list = self:GetMainList()
    local selectedIndex = ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildIndex()

    -- There my be no selected index if no skill builds have been added to data
    if selectedIndex then
        list:SetSelectedIndexWithoutAnimation(selectedIndex)
    end

    local selectedData = list:GetSelectedData()
    self:RefreshTooltip(selectedData)
end

function SkillsAdvisorBuildSelectionRoot_Gamepad:PerformUpdate()
    -- Include update functionality here if the screen uses self.dirty to track needing to update
    self.dirty = false
end

function ZO_SkillsAdvisorBuildSelection_Gamepad_MenuEntryTemplate_OnInitialized(control)
    ZO_SharedGamepadEntry_OnInitialized(control)
    ZO_SharedGamepadEntry_SetHeightFromLabels(control)
    control.selectedIcon = control:GetNamedChild("SelectedIcon")
    control.selectedIcon:GetNamedChild("Highlight"):SetHidden(true)
end

function ZO_SkillsAdvisorBuildSelectionRoot_Gamepad_OnInitialized(control)
    ZO_GAMEPAD_SKILLS_ADVISOR_BUILD_SELECT_WINDOW = SkillsAdvisorBuildSelectionRoot_Gamepad:New(control)
end