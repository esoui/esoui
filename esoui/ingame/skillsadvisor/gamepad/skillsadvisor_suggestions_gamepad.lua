--------------
--Initialize--
--------------
local SKILLS_ADVISOR_SUGGESTIONS_HEADER_DATA = 1
local SKILLS_ADVISOR_SUGGESTIONS_DATA = 2
local SKILLS_ADVISOR_SUGGESTIONS_TEXT = 3

local SkillsAdvisorSuggestions_Gamepad = ZO_SortFilterList_Gamepad:Subclass()

function SkillsAdvisorSuggestions_Gamepad:New(...)
    return ZO_SortFilterList_Gamepad.New(self, ...)
end

function SkillsAdvisorSuggestions_Gamepad:Initialize(control)
    ZO_SortFilterList_Gamepad.Initialize(self, control)
    ZO_ScrollList_AddDataType(self.list, SKILLS_ADVISOR_SUGGESTIONS_DATA, "ZO_SkillsAdvisorSuggestions_Gamepad_AbilityEntryTemplate", 60, function(...) self:ZO_SkillsAdvisorSuggestionsEntryTemplateSetup(...) end)
    ZO_ScrollList_AddDataType(self.list, SKILLS_ADVISOR_SUGGESTIONS_HEADER_DATA, "ZO_SkillsAdvisorSuggestions_Gamepad_MenuEntryHeader", 50, function(...) self:ZO_SkillsAdvisorSuggestionsTextDisplayTemplateSetup(...) end)
    ZO_ScrollList_AddDataType(self.list, SKILLS_ADVISOR_SUGGESTIONS_TEXT, "ZO_SkillsAdvisorSuggestions_Gamepad_MenuEntryText", 100, function(...) self:ZO_SkillsAdvisorSuggestionsTextDisplayTemplateSetup(...) end)
    ZO_ScrollList_SetTypeSelectable(self.list, SKILLS_ADVISOR_SUGGESTIONS_HEADER_DATA, false)
    ZO_ScrollList_SetTypeCategoryHeader(self.list, SKILLS_ADVISOR_SUGGESTIONS_HEADER_DATA, true)
    ZO_ScrollList_SetTypeSelectable(self.list, SKILLS_ADVISOR_SUGGESTIONS_TEXT, false)

    SKILLS_ADVISOR_SUGGESTIONS_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    SKILLS_ADVISOR_SUGGESTIONS_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                                    if newState == SCENE_FRAGMENT_SHOWING then
                                                                        self:OnShowing()
                                                                    elseif newState == SCENE_FRAGMENT_HIDDEN then
                                                                        self:OnHidden()   
                                                                    end
                                                                end)

    self:InitializeKeybinds()
end

function SkillsAdvisorSuggestions_Gamepad:OnShowing() 
    self:RefreshData()
    self:UpdateTooltip()
end

function SkillsAdvisorSuggestions_Gamepad:OnHidden()
    self:Deactivate()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function SkillsAdvisorSuggestions_Gamepad:Activate()
    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
    ZO_SortFilterList_Gamepad.Activate(self)
    self:UpdateTooltip()

    self.keybindStripId = KEYBIND_STRIP:PushKeybindGroupState()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor, self.keybindStripId)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripRightDescriptor, self.keybindStripId)
end

function SkillsAdvisorSuggestions_Gamepad:Deactivate()
    ZO_SortFilterList_Gamepad.Deactivate(self)
    self:UpdateTooltip()

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor, self.keybindStripId)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripRightDescriptor, self.keybindStripId)
    KEYBIND_STRIP:PopKeybindGroupState()
    self.keybindStripId = nil
end

function SkillsAdvisorSuggestions_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_SortFilterList_Gamepad.OnSelectionChanged(self, oldData, newData)
    self:UpdateTooltip()
end

function SkillsAdvisorSuggestions_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback =  function()
                ZO_SKILLS_ADVISOR_SINGLETON:OnRequestSelectSkillLine()
            end
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Skill Advisor Previous Category",
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            ethereal = true,
            callback = function()
                if ZO_ScrollList_CanScrollUp(self.list) then
                    ZO_ScrollList_SelectFirstIndexInCategory(self.list, ZO_SCROLL_SELECT_CATEGORY_PREVIOUS)
                    PlaySound(ZO_PARAMETRIC_SCROLL_MOVEMENT_SOUNDS[ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_PREVIOUS])
                end
            end
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Skill Advisor Next Category",
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            ethereal = true,
            callback = function()
                if ZO_ScrollList_CanScrollDown(self.list) then
                    ZO_ScrollList_SelectFirstIndexInCategory(self.list, ZO_SCROLL_SELECT_CATEGORY_NEXT)
                    PlaySound(ZO_PARAMETRIC_SCROLL_MOVEMENT_SOUNDS[ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_NEXT])
                end
            end
        },
    }

    local function Back() 
        self:Deactivate()
        PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
        GAMEPAD_SKILLS:SetMode(ZO_GAMEPAD_SKILLS_SKILL_LIST_BROWSE_MODE)
    end

    local keybindCount = #self.keybindStripDescriptor
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, Back)

    self.keybindStripRightDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,
        {   
            name = GetString(SI_SKILLS_ADVISOR_GAMEPAD_OPEN_ADVISOR_SETTINGS),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            sound = SOUNDS.SKILLS_ADVISOR_SELECT,
            visible =  function() return true end,
            callback = function() 
                SCENE_MANAGER:Push(ZO_GAMEPAD_SKILLS_ADVISOR_BUILD_SELECTION_ROOT_SCENE_NAME)
            end,
        }
    }
end

function SkillsAdvisorSuggestions_Gamepad:UpdateTooltip()
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)
    if self.isActive then
        local selectedData = ZO_ScrollList_GetSelectedData(self.list)
        if selectedData and not selectedData.isHeader then
            local rankIndex = GetSkillLineProgressionAbilityRankIndex(selectedData.dataSource.skillType, selectedData.dataSource.lineIndex, selectedData.dataSource.abilityIndex, selectedData.dataSource.skillBuildMorphChoice)
            local hideNextUpgrade = false
            local showRank = false
            local showPurchaseInfo = true
            local hidePointsAndAdvisedInfo = true
            GAMEPAD_TOOLTIPS:LayoutSkillLineAbility(GAMEPAD_RIGHT_TOOLTIP, selectedData.dataSource.skillType, selectedData.dataSource.lineIndex, selectedData.dataSource.abilityIndex, hideNextUpgrade, showRank, rankIndex, showPurchaseInfo, selectedData.dataSource.abilityId, hidePointsAndAdvisedInfo)
            return
        end
    end

    GAMEPAD_TOOLTIPS:LayoutSkillBuild(GAMEPAD_RIGHT_TOOLTIP, ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildId())
    GAMEPAD_TOOLTIPS:ShowBg(GAMEPAD_RIGHT_TOOLTIP)
end

function SkillsAdvisorSuggestions_Gamepad:BuildMasterList()
    -- intended to be overriden
    -- should build the master list of data that is later filtered by FilterScrollList
end

function SkillsAdvisorSuggestions_Gamepad:FilterScrollList()
    -- intended to be overriden
    -- should take the master list data and filter it
end

function SkillsAdvisorSuggestions_Gamepad:SortScrollList()
    ZO_ScrollList_Clear(self.list)
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    local headerData = ZO_GamepadEntryData:New(GetString(SI_SKILLS_ADVISOR_ADVISED_TITLE))
    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILLS_ADVISOR_SUGGESTIONS_HEADER_DATA, headerData))

    local availableAbilities = ZO_SKILLS_ADVISOR_SINGLETON:GetAvailableAbilityList()
    if #availableAbilities > 0 then
        for i = 1, #availableAbilities do
            local data = availableAbilities[i]
            local entryData = ZO_GamepadEntryData:New(data.name, data.icon)
            entryData:SetDataSource(data)
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILLS_ADVISOR_SUGGESTIONS_DATA, entryData))
        end
    else
        local textData = ZO_GamepadEntryData:New(GetString(SI_SKILLS_ADVISOR_NO_ADVISED_ABILITIES_DESCRIPTION))
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILLS_ADVISOR_SUGGESTIONS_TEXT, textData))
    end

    local purchasedAbilities = ZO_SKILLS_ADVISOR_SINGLETON:GetPurchasedAbilityList()
    for i = 1, #purchasedAbilities do
        local data = purchasedAbilities[i]
        local entryData = ZO_GamepadEntryData:New(data.name, data.icon)
        entryData:SetDataSource(data)
        if i == 1 then
            local headerData = ZO_GamepadEntryData:New(GetString(SI_SKILLS_ADVISOR_PURCHASED_TITLE))
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILLS_ADVISOR_SUGGESTIONS_HEADER_DATA, headerData))
        end
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILLS_ADVISOR_SUGGESTIONS_DATA, entryData))
    end

    ZO_ScrollList_Commit(self.list)
end

function SkillsAdvisorSuggestions_Gamepad:ZO_SkillsAdvisorSuggestionsEntryTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    ZO_GamepadAbilityEntryTemplate_Setup(control, data.dataSource, selected, activated, ZO_SKILL_ABILITY_DISPLAY_VIEW)
end

function SkillsAdvisorSuggestions_Gamepad:ZO_SkillsAdvisorSuggestionsTextDisplayTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    control.label:SetText(data.text)
end

function SkillsAdvisorSuggestions_Gamepad:SetSelectedAbilityData(skillType, skillIndex, abilityIndex)
    self.selectAbilityData = {
        skillType = skillType,
        skillIndex = skillIndex,
        abilityIndex = abilityIndex,
    }
end

function SkillsAdvisorSuggestions_Gamepad:GetSelectedAbilityData()
    return self.selectAbilityData
end

-----------------------------
-- XML Functions
-----------------------------

function ZO_SkillsAdvisorSuggestions_Gamepad_MenuEntryHeader_OnInitialized(control)
    control.label = control:GetNamedChild("Label")
end

function ZO_SkillsAdvisorSuggestions_Gamepad_MenuEntryTemplate_OnInitialized(control)
    ZO_SharedGamepadEntry_OnInitialized(control)
    ZO_SharedGamepadEntry_SetHeightFromLabels(control)
end

function ZO_SkillsAdvisorSuggestions_Gamepad_OnInitialized(control)
    ZO_GAMEPAD_SKILLS_ADVISOR_SUGGESTIONS_WINDOW = SkillsAdvisorSuggestions_Gamepad:New(control)
end
