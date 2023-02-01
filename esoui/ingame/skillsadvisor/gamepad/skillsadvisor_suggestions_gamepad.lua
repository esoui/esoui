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
    ZO_ScrollList_AddDataType(self.list, SKILLS_ADVISOR_SUGGESTIONS_DATA, "ZO_SkillsAdvisorSuggestion_Gamepad_SkillRow", 60, function(...) self:GamepadSingleLineAbilityEntryTemplateSetup(...) end)
    ZO_ScrollList_AddDataType(self.list, SKILLS_ADVISOR_SUGGESTIONS_HEADER_DATA, "ZO_SkillsAdvisorSuggestions_Gamepad_MenuEntryHeader", 50, function(...) self:SkillsAdvisorSuggestionsTextDisplayTemplateSetup(...) end)
    ZO_ScrollList_AddDataType(self.list, SKILLS_ADVISOR_SUGGESTIONS_TEXT, "ZO_SkillsAdvisorSuggestions_Gamepad_MenuEntryText", 100, function(...) self:SkillsAdvisorSuggestionsTextDisplayTemplateSetup(...) end)
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

function SkillsAdvisorSuggestions_Gamepad:IsShowing()
    return SKILLS_ADVISOR_SUGGESTIONS_GAMEPAD_FRAGMENT:IsShowing()
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
                SCENE_MANAGER:Push("gamepad_skills_advisor_build_selection_root")
            end,
        }
    }
end

function SkillsAdvisorSuggestions_Gamepad:UpdateTooltip()
    if self:IsShowing() then
        GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)

        if self.isActive then
            local selectedData = self:GetSelectedData()
            if selectedData and not selectedData.isHeader then
                local SHOW_RANK_NEEDED_LINE = true
                GAMEPAD_TOOLTIPS:LayoutSkillProgression(GAMEPAD_RIGHT_TOOLTIP, selectedData.skillProgressionData, SHOW_RANK_NEEDED_LINE)
                return
            end
        end

        GAMEPAD_TOOLTIPS:LayoutSkillBuild(GAMEPAD_RIGHT_TOOLTIP, ZO_SKILLS_ADVISOR_SINGLETON:GetSelectedSkillBuildId())
        GAMEPAD_TOOLTIPS:ShowBg(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function SkillsAdvisorSuggestions_Gamepad:BuildMasterList()
    -- intended to be overriden
    -- should build the master list of data that is later filtered by FilterScrollList
end

function SkillsAdvisorSuggestions_Gamepad:FilterScrollList()
    -- intended to be overriden
    -- should take the master list data and filter it
end

do
    local function AddEntry(scrollData, skillProgressionData)
        local name = skillProgressionData:IsPassive() and skillProgressionData:GetFormattedNameWithRank() or skillProgressionData:GetFormattedName()
        local entryData = ZO_GamepadEntryData:New(name, skillProgressionData:GetIcon())
        entryData.skillProgressionData = skillProgressionData
        entryData.narrationText = function()
            local narrations = {}
            if entryData.headerNarrationText then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.headerNarrationText))
            end
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(name))
            return narrations
        end
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILLS_ADVISOR_SUGGESTIONS_DATA, entryData))
        return entryData
    end

    function SkillsAdvisorSuggestions_Gamepad:SortScrollList()
        local previouslySelectedData = self:GetSelectedData()
        local previouslySelectedSkillProgressionData = previouslySelectedData and previouslySelectedData.skillProgressionData
        local reselectData = nil

        ZO_ScrollList_Clear(self.list)
        local scrollData = ZO_ScrollList_GetDataList(self.list)

        local availableHeaderData = ZO_GamepadEntryData:New(GetString(SI_SKILLS_ADVISOR_ADVISED_TITLE))
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILLS_ADVISOR_SUGGESTIONS_HEADER_DATA, availableHeaderData))

        local availableAbilities = ZO_SKILLS_ADVISOR_SINGLETON:GetAvailableAbilityList()
        if #availableAbilities > 0 then
            for i, skillProgressionData in ipairs(availableAbilities) do
                local entryData = AddEntry(scrollData, skillProgressionData)
                -- Since the heading itself can't be selected, include the heading text as part of the narration for the first entry in this section
                if i == 1 then
                    entryData.headerNarrationText = GetString(SI_SKILLS_ADVISOR_ADVISED_TITLE)
                end
                if previouslySelectedSkillProgressionData == skillProgressionData then
                    reselectData = entryData
                end
            end
        else
            local textData = ZO_GamepadEntryData:New(GetString(SI_SKILLS_ADVISOR_NO_ADVISED_ABILITIES_DESCRIPTION))
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILLS_ADVISOR_SUGGESTIONS_TEXT, textData))
        end

        local purchasedAbilities = ZO_SKILLS_ADVISOR_SINGLETON:GetPurchasedAbilityList()
        if #purchasedAbilities > 0 then
            local purchasedHeaderData = ZO_GamepadEntryData:New(GetString(SI_SKILLS_ADVISOR_PURCHASED_TITLE))
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILLS_ADVISOR_SUGGESTIONS_HEADER_DATA, purchasedHeaderData))

            for i, skillProgressionData in ipairs(purchasedAbilities) do
                local entryData = AddEntry(scrollData, skillProgressionData)
                -- Since the heading itself can't be selected, include the heading text as part of the narration for the first entry in this section
                if i == 1 then
                    entryData.headerNarrationText = GetString(SI_SKILLS_ADVISOR_PURCHASED_TITLE)
                end
                if previouslySelectedSkillProgressionData == skillProgressionData then
                    reselectData = entryData
                end
            end
        end

        ZO_ScrollList_Commit(self.list)

        if reselectData then
            ZO_ScrollList_SelectDataAndScrollIntoView(self.list, reselectData)
        end
    end
end

function SkillsAdvisorSuggestions_Gamepad:GamepadSingleLineAbilityEntryTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    ZO_GamepadSkillEntryTemplate_Setup(control, data, selected, activated, ZO_SKILL_ABILITY_DISPLAY_VIEW)
end

function SkillsAdvisorSuggestions_Gamepad:SkillsAdvisorSuggestionsTextDisplayTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    control.label:SetText(data.text)
end

function SkillsAdvisorSuggestions_Gamepad:SetSelectSkillData(skillData)
    self.selectSkillData = skillData
end

function SkillsAdvisorSuggestions_Gamepad:GetSelectSkillData()
    return self.selectSkillData
end

-- Overridden from base
function SkillsAdvisorSuggestions_Gamepad:GetHeaderNarration()
    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_SKILLS_ADVISOR_TITLE))
end

function SkillsAdvisorSuggestions_Gamepad:GetNarrationText()
    local selectedData = self:GetSelectedData()
    if selectedData and selectedData.narrationText then
        return selectedData.narrationText(selectedData)
    end
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