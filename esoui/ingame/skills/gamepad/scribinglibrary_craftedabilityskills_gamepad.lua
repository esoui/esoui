--------------
--Initialize--
--------------
local SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_HEADER_DATA = 1
local SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_DATA = 2
local SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_TEXT = 3

ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad = ZO_Object.MultiSubclass(ZO_SortFilterList_Gamepad, ZO_InitializingCallbackObject)

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:New(...)
    return ZO_SortFilterList_Gamepad.New(self, ...)
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:Initialize(control)
    ZO_SortFilterList_Gamepad.Initialize(self, control)
    ZO_ScrollList_AddDataType(self.list, SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_DATA, "ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad_CraftedAbilityRow", 60, function(...) self:ScribingCraftedAbilityEntryTemplateSetup(...) end)
    ZO_ScrollList_AddDataType(self.list, SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_HEADER_DATA, "ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad_MenuEntryHeader", 50, function(...) self:ScribingCraftedAbilityTextDisplayTemplateSetup(...) end)
    ZO_ScrollList_AddDataType(self.list, SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_TEXT, "ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad_MenuEntryText", 100, function(...) self:ScribingCraftedAbilityTextDisplayTemplateSetup(...) end)
    ZO_ScrollList_SetTypeSelectable(self.list, SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_HEADER_DATA, false)
    ZO_ScrollList_SetTypeCategoryHeader(self.list, SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_HEADER_DATA, true)
    ZO_ScrollList_SetTypeSelectable(self.list, SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_TEXT, false)

    local function OnStateChanged(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end

    SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", OnStateChanged)

    self:InitializeKeybinds()
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:OnShowing()
    self:RefreshData()
    self:UpdateTooltip()

    if self.autoActivateOnShowing then
        self.autoActivateOnShowing = nil
        -- second entry is always scribing
        GAMEPAD_SKILLS.categoryList:SetSelectedIndexWithoutAnimation(2)
        self:Activate()
    end
    self.previouslySelectedData = nil
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:SetToAutoActivate()
    self.autoActivateOnShowing = true
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:OnHidden()
    self:Deactivate()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:IsShowing()
    return SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_GAMEPAD_FRAGMENT:IsShowing()
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:Activate()
    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
    ZO_SortFilterList_Gamepad.Activate(self)
    self:UpdateTooltip()

    self.keybindStripId = KEYBIND_STRIP:PushKeybindGroupState()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor, self.keybindStripId)
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:Deactivate()
    self.previouslySelectedData = self:GetSelectedData()
    ZO_SortFilterList_Gamepad.Deactivate(self)
    self:UpdateTooltip()

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor, self.keybindStripId)
    KEYBIND_STRIP:PopKeybindGroupState()
    self.keybindStripId = nil
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_SortFilterList_Gamepad.OnSelectionChanged(self, oldData, newData)
    self:UpdateTooltip()
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback =  function()
                local selectedData = self:GetSelectedData()
                if selectedData and selectedData.skillData then
                    GAMEPAD_SKILLS:SelectSkillLineBySkillData(selectedData.skillData)
                end
            end
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Scribing Library Crafted Ability Previous Category",
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
            name = "Gamepad  Scribing Library Crafted Ability Next Category",
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
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, Back)
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:UpdateTooltip()
    if self:IsShowing() then
        GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)

        if self.isActive then
            local selectedData = self:GetSelectedData()
            if selectedData and not selectedData.isHeader then
                local skillData = selectedData.skillData
                local skillProgressionData = skillData:GetPointAllocatorProgressionData()
                local SHOW_RANK_NEEDED_LINE = true
                GAMEPAD_TOOLTIPS:LayoutSkillProgression(GAMEPAD_RIGHT_TOOLTIP, skillProgressionData, SHOW_RANK_NEEDED_LINE)
                return
            end
        end
    end
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:BuildMasterList()
    -- intended to be overridden
    -- should build the master list of data that is later filtered by FilterScrollList
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:FilterScrollList()
    -- intended to be overridden
    -- should take the master list data and filter it
end

do
    local function AddEntry(scrollData, skillData)
        local progressionData = skillData and skillData:GetCurrentProgressionData()
        if progressionData then
            local name = progressionData:GetFormattedName()
            local entryData = ZO_GamepadEntryData:New(name, progressionData:GetIcon())
            entryData.skillData = skillData
            entryData.narrationText = function()
                local narrations = {}
                if entryData.headerNarrationText then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.headerNarrationText))
                end
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(name))
                return narrations
            end
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_DATA, entryData))
            return entryData
        end
    end

    function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:SortScrollList()
        local previouslySelectedCraftedAbilitySkill = self.previouslySelectedData and self.previouslySelectedData.skillData
        local reselectData = nil

        ZO_ScrollList_Clear(self.list)
        local scrollData = ZO_ScrollList_GetDataList(self.list)

        local headerText = nil
        local scribedCraftedAbilitySkills = SCRIBING_DATA_MANAGER:GetScribedCraftedAbilitySkillsData()
        if #scribedCraftedAbilitySkills > 0 then
            for i, skillData in ipairs(scribedCraftedAbilitySkills) do
                if skillData:IsUltimate() then
                    local ultimateText = GetString(SI_SKILLS_ULTIMATE_ABILITIES)
                    if not headerText or headerText ~= ultimateText then
                        headerText = ultimateText
                        local headerEntryData = ZO_GamepadEntryData:New(headerText)
                        headerEntryData.headerNarrationText = headerText
                        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_HEADER_DATA, headerEntryData))
                    end
                else
                    local activeText = GetString(SI_SKILLS_ACTIVE_ABILITIES)
                    if not headerText or headerText ~= activeText then
                        headerText = GetString(SI_SKILLS_ACTIVE_ABILITIES)
                        local headerEntryData = ZO_GamepadEntryData:New(headerText)
                        headerEntryData.headerNarrationText = headerText
                        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_HEADER_DATA, headerEntryData))
                    end
                end
                local entryData = AddEntry(scrollData, skillData)
                if previouslySelectedCraftedAbility == skillData then
                    reselectData = entryData
                end
            end
        else
            local textData = ZO_GamepadEntryData:New(GetString(SI_SCRIBING_NO_CRAFTED_ABILITIES_DESCRIPTION))
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_TEXT, textData))
        end

        ZO_ScrollList_Commit(self.list)

        if reselectData then
            ZO_ScrollList_SelectDataAndScrollIntoView(self.list, reselectData)
        end
    end
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:ScribingCraftedAbilityEntryTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    ZO_GamepadSkillEntryTemplate_Setup(control, data, selected, activated, ZO_SKILL_ABILITY_DISPLAY_VIEW)
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:ScribingCraftedAbilityTextDisplayTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    control.label:SetText(data.text)
end

-- Overridden from base
function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:GetHeaderNarration()
    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_SCRIBING_TITLE))
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:GetNarrationText()
    local selectedData = self:GetSelectedData()
    if selectedData and selectedData.narrationText then
        return selectedData.narrationText(selectedData)
    end
end

-----------------------------
-- XML Functions
-----------------------------

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad.OnMenuEntryHeaderInitialized(control)
    control.label = control:GetNamedChild("Label")
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad.OnMenuEntryTemplateInitialized(control)
    ZO_SharedGamepadEntry_OnInitialized(control)
    ZO_SharedGamepadEntry_SetHeightFromLabels(control)
end

function ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad.OnControlInitialized(control)
    ZO_GAMEPAD_SCRIBING_CRAFTED_ABILITY_SKILLS = ZO_ScribingLibrary_CraftedAbilitySkills_Gamepad:New(control)
end