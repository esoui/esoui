ZO_SkillsAdvisor_BuildSelection_Keyboard = ZO_Object:Subclass()

local SKILL_BUILD_DATA_TYPE = 1

function ZO_SkillsAdvisor_BuildSelection_Keyboard:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_SkillsAdvisor_BuildSelection_Keyboard:Initialize(control)
    self.control = control
    self.skillBuildsListControl = control:GetNamedChild("SkillBuildsList")
    self.neverShown = true

    ZO_SKILLS_ADVISOR_BUILD_SELECT_FRAGMENT = ZO_FadeSceneFragment:New(control)

    ZO_SKILLS_ADVISOR_WINDOW:AnchorControlInTabContent(control)

    local function SetUpSkillBuildEntry(setupControl, data)
        local selectedSkillBuildId = ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildId()
        local selectedAdvancedMode = ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected()
        local showCheckmark = selectedSkillBuildId == data.id or (selectedAdvancedMode and data.id == 0)

        setupControl.checkmarkControl:SetHidden(not showCheckmark)
        setupControl.textLabel:SetText(data.name)
    end

    ZO_ScrollList_Initialize(self.skillBuildsListControl)
    ZO_ScrollList_SetDeselectOnReselect(self.skillBuildsListControl, false)
    ZO_ScrollList_AddDataType(self.skillBuildsListControl, SKILL_BUILD_DATA_TYPE, "ZO_SkillsAdvisor_Keyboard_SkillBuildEntry", 52, SetUpSkillBuildEntry)
    ZO_ScrollList_AddResizeOnScreenResize(self.skillBuildsListControl)
    ZO_ScrollList_EnableSelection(self.skillBuildsListControl, "ZO_TallListSelectedHighlight", function(...) self:OnSkillBuildSelected(...) end)
    ZO_ScrollList_EnableHighlight(self.skillBuildsListControl, "ZO_TallListHighlight")

    ZO_SKILLS_ADVISOR_BUILD_SELECT_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        end
    end)

    ZO_SKILLS_ADVISOR_SINGLETON:RegisterCallback("OnSelectedSkillBuildUpdated", function() self:ResetSelection() end)
end

function ZO_SkillsAdvisor_BuildSelection_Keyboard:OnShowing()
    if self.neverShown then
        self:LoadSkillBuildList()    
        self.neverShown = false
    elseif self.dirtyFlag then
        self:RefreshBuildList()
    end
end

function ZO_SkillsAdvisor_BuildSelection_Keyboard:LoadSkillBuildList()
    local scrollData = ZO_ScrollList_GetDataList(self.skillBuildsListControl)
    local numSkillBuilds = ZO_SKILLS_ADVISOR_SINGLETON:GetNumSkillBuildOptions()
    local selectedSkillBuildId = ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildId()
    local selectedAdvancedMode = ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected()
    local selectedData = nil 
    ZO_ScrollList_Clear(self.skillBuildsListControl)

    for skillBuildIndex = 1, numSkillBuilds do
        local skillBuild = ZO_SKILLS_ADVISOR_SINGLETON:GetAvailableSkillBuildByIndex(skillBuildIndex)
        local entryData = ZO_ScrollList_CreateDataEntry(SKILL_BUILD_DATA_TYPE, skillBuild)
        table.insert(scrollData, entryData)
        if skillBuild.id == selectedSkillBuildId then
            selectedData = entryData.data
        end
    end

    ZO_ScrollList_Commit(self.skillBuildsListControl)

    if selectedSkillBuildId or selectedAdvancedMode then
        local CONTROL_TO_USE_INSTEAD_OF_DATA = nil
        local RESELECTING_DURING_REBUILD = true
        ZO_ScrollList_SelectData(self.skillBuildsListControl, selectedData, CONTROL_TO_USE_INSTEAD_OF_DATA, RESELECTING_DURING_REBUILD)
    end
end

function ZO_SkillsAdvisor_BuildSelection_Keyboard:RefreshBuildList()
    ZO_ScrollList_RefreshVisible(self.skillBuildsListControl)

    local selectedSkillBuildId = ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildId()
    local selectedAdvancedMode = ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected()
    if selectedSkillBuildId or selectedAdvancedMode then
        local CONTROL_TO_USE_INSTEAD_OF_DATA = nil
        local RESELECTING_DURING_REBUILD = true
        local GET_ADVANCED_IF_NO_ID = true
        local selectedData = ZO_SKILLS_ADVISOR_SINGLETON:GetAvailableSkillBuildById(selectedSkillBuildId, GET_ADVANCED_IF_NO_ID)
        local selectedScrollData = self:GetSkillBuildScrollDataFromData(selectedData)
        ZO_ScrollList_SelectData(self.skillBuildsListControl, selectedScrollData, CONTROL_TO_USE_INSTEAD_OF_DATA, RESELECTING_DURING_REBUILD)
    end

    self.dirtyFlag = false
end

function ZO_SkillsAdvisor_BuildSelection_Keyboard:GetSkillBuildScrollDataFromData(skillBuildData)
    local dataList = ZO_ScrollList_GetDataList(self.skillBuildsListControl)
    for i, data in ipairs(dataList) do
        if data.data.id == skillBuildData.id then
            return data.data
        end
    end
    return nil
end

function ZO_SkillsAdvisor_BuildSelection_Keyboard:ResetSelection()
    if ZO_SKILLS_ADVISOR_BUILD_SELECT_FRAGMENT:GetState() ~= SCENE_FRAGMENT_HIDDEN then
        self:RefreshBuildList()
    else
        self.dirtyFlag = true
    end
end

function ZO_SkillsAdvisor_BuildSelection_Keyboard:OnSkillBuildSelected(previouslySelectedData, selectedData, selectingDuringRebuild)
    if not selectingDuringRebuild then
        local previousSelectedControl = ZO_ScrollList_GetDataControl(self.skillBuildsListControl, previouslySelectedData)
        if previousSelectedControl then
            previousSelectedControl.checkmarkControl:SetHidden(true)
        end

        local currentSelectedControl = ZO_ScrollList_GetDataControl(self.skillBuildsListControl, selectedData)
        if currentSelectedControl then
            currentSelectedControl.checkmarkControl:SetHidden(false)
        end
        ZO_SKILLS_ADVISOR_SINGLETON:OnSkillBuildSelected(selectedData.index)
    end
end

function ZO_SkillsAdvisor_BuildSelection_Keyboard_OnMouseClick(control, buttonIndex, upInside)
    PlaySound(SOUNDS.SKILLS_ADVISOR_SELECT)
    ZO_ScrollList_MouseClick(ZO_SKILLS_ADVISOR_BUILD_SELECT_WINDOW.skillBuildsListControl, control)
end

function ZO_SkillsAdvisor_BuildSelection_Keyboard_OnMouseEnter(control)
    local data = control and control.dataEntry and control.dataEntry.data
    
    InitializeTooltip(GameTooltip, control, TOPLEFT, -15)
    ZO_SKILLS_ADVISOR_SINGLETON:SetupKeyboardSkillBuildTooltip(data)
    ZO_ScrollList_MouseEnter(ZO_SKILLS_ADVISOR_BUILD_SELECT_WINDOW.skillBuildsListControl, control)
end

function ZO_SkillsAdvisor_BuildSelection_Keyboard_OnMouseExit(control)
    ClearTooltip(GameTooltip)
    ZO_ScrollList_MouseExit(ZO_SKILLS_ADVISOR_BUILD_SELECT_WINDOW.skillBuildsListControl, control)
end

function ZO_SkillsAdvisor_BuildSelection_Keyboard_OnInitialized(control)
    ZO_SKILLS_ADVISOR_BUILD_SELECT_WINDOW = ZO_SkillsAdvisor_BuildSelection_Keyboard:New(control)
end