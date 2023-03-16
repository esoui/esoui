--------------
--Initialize--
--------------
local ARMORY_BUILD_SKILLS_HEADER_DATA = 1
local ARMORY_BUILD_SKILLS_DATA = 2

ZO_ArmoryBuildSkills_Gamepad = ZO_SortFilterList_Gamepad:Subclass()

function ZO_ArmoryBuildSkills_Gamepad:New(...)
    return ZO_SortFilterList_Gamepad.New(self, ...)
end

function ZO_ArmoryBuildSkills_Gamepad:Initialize(control)
    ZO_SortFilterList_Gamepad.Initialize(self, control)
    ZO_ScrollList_AddDataType(self.list, ARMORY_BUILD_SKILLS_DATA, "ZO_ArmoryBuildSkills_Gamepad_SkillRow", 55, function(...) self:GamepadSingleLineAbilityEntryTemplateSetup(...) end)
    ZO_ScrollList_AddDataType(self.list, ARMORY_BUILD_SKILLS_HEADER_DATA, "ZO_ArmoryBuildSkills_Gamepad_MenuEntryHeader", 40, function(...) self:ArmoryBuildSkillsTextDisplayTemplateSetup(...) end)
    ZO_ScrollList_SetTypeSelectable(self.list, ARMORY_BUILD_SKILLS_HEADER_DATA, false)
    ZO_ScrollList_SetTypeCategoryHeader(self.list, ARMORY_BUILD_SKILLS_HEADER_DATA, true)

    ARMORY_BUILD_SKILLS_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    ARMORY_BUILD_SKILLS_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                                    if newState == SCENE_FRAGMENT_SHOWING then
                                                                        self:OnShowing()
                                                                    elseif newState == SCENE_FRAGMENT_HIDDEN then
                                                                        self:OnHidden()
                                                                    end
                                                                end)

    self:InitializeKeybinds()
end

function ZO_ArmoryBuildSkills_Gamepad:OnShowing()
    self:RefreshData()
    self:UpdateTooltip()
end

function ZO_ArmoryBuildSkills_Gamepad:OnHidden()
    self:Deactivate()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_ArmoryBuildSkills_Gamepad:IsShowing()
    return ARMORY_BUILD_SKILLS_GAMEPAD_FRAGMENT:IsShowing()
end

function ZO_ArmoryBuildSkills_Gamepad:Activate()
    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
    ZO_SortFilterList_Gamepad.Activate(self)
    self:UpdateTooltip()

    self.keybindStripId = KEYBIND_STRIP:PushKeybindGroupState()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor, self.keybindStripId)
end

function ZO_ArmoryBuildSkills_Gamepad:Deactivate()
    ZO_SortFilterList_Gamepad.Deactivate(self)
    self:UpdateTooltip()

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor, self.keybindStripId)
    KEYBIND_STRIP:PopKeybindGroupState()
    self.keybindStripId = nil
end

function ZO_ArmoryBuildSkills_Gamepad:SetSelectedArmoryBuildData(armoryBuildData)
    self.armoryBuildData = armoryBuildData
end

function ZO_ArmoryBuildSkills_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_SortFilterList_Gamepad.OnSelectionChanged(self, oldData, newData)
    self:UpdateTooltip()
end

function ZO_ArmoryBuildSkills_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Armory Build Skills Previous Category",
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
            name = "Gamepad Armory Build Skills Next Category",
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
        --Because the main build details list remains activated while we are in this one, we need to manually tell it to re-narrate when we leave
        local NARRATE_HEADER = true
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(ARMORY_GAMEPAD:GetCurrentList(), NARRATE_HEADER)
        PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
    end

    local keybindCount = #self.keybindStripDescriptor
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, Back)
end

function ZO_ArmoryBuildSkills_Gamepad:UpdateTooltip()
    if self:IsShowing() then
        GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)

        if self.isActive then
            local selectedData = self:GetSelectedData()
            if selectedData and not selectedData.isHeader and not selectedData.isEntryEmpty then
                local SHOW_RANK_NEEDED_LINE = true
                GAMEPAD_TOOLTIPS:LayoutSkillProgression(GAMEPAD_RIGHT_TOOLTIP, selectedData.skillProgressionData, SHOW_RANK_NEEDED_LINE)
                return
            end
        end
    end
end

function ZO_ArmoryBuildSkills_Gamepad:SortScrollList()
    local previouslySelectedData = self:GetSelectedData()
    local previouslySelectedSkillProgressionData = previouslySelectedData and previouslySelectedData.skillProgressionData
    local reselectData = nil

    ZO_ScrollList_Clear(self.list)
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    local hotbarCategoryList = ZO_ARMORY_MANAGER:GetSkillsHotBarCategories()
    for hotbarCategory, _ in pairs(hotbarCategoryList) do
        if hotbarCategory == HOTBAR_CATEGORY_BACKUP and GetUnitLevel("player") < GetWeaponSwapUnlockedLevel() then
            -- Backup hotbar is locked for current player

            -- Add backup hotbar header
            self:AddSkillsCategoryHeader(scrollData, hotbarCategory)

            -- Add info text about locked hotbar
            local infoText = zo_strformat(SI_WEAPON_SWAP_UNEARNED_TOOLTIP, GetWeaponSwapUnlockedLevel())
            local entryData = ZO_GamepadEntryData:New(infoText)
            entryData.isEntryEmpty = true
            entryData.showLock = true
            entryData.headerText = zo_strformat(SI_GAMEPAD_ARMORY_SKILL_BAR_FORMATTER, GetString("SI_HOTBARCATEGORY", hotbarCategory))
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ARMORY_BUILD_SKILLS_DATA, entryData))
        else
            local skillsAdded = 0
            for slotIndex = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1, ACTION_BAR_ULTIMATE_SLOT_INDEX + 1 do
                local abilityId = self.armoryBuildData:GetSlottedAbilityId(slotIndex, hotbarCategory)
                local headerText = nil
                if abilityId == 0 then
                    if skillsAdded == 0 then
                        self:AddSkillsCategoryHeader(scrollData, hotbarCategory)
                        headerText = zo_strformat(SI_GAMEPAD_ARMORY_SKILL_BAR_FORMATTER, GetString("SI_HOTBARCATEGORY", hotbarCategory))
                    end
                    local entryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_ARMORY_EMPTY_ENTRY_TEXT))
                    entryData.isEntryEmpty = true
                    entryData.headerText = headerText
                    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ARMORY_BUILD_SKILLS_DATA, entryData))
                    skillsAdded = skillsAdded + 1
                else
                    local skillProgressionData = SKILLS_DATA_MANAGER:GetProgressionDataByAbilityId(abilityId)
                    if skillProgressionData then
                        if skillsAdded == 0 then
                            self:AddSkillsCategoryHeader(scrollData, hotbarCategory)
                            headerText = zo_strformat(SI_GAMEPAD_ARMORY_SKILL_BAR_FORMATTER, GetString("SI_HOTBARCATEGORY", hotbarCategory))
                        end

                        local name = skillProgressionData:GetFormattedName()
                        local entryData = ZO_GamepadEntryData:New(name, skillProgressionData:GetIcon())
                        entryData.hotbarCategory = hotbarCategory
                        entryData.slotIndex = slotIndex
                        entryData.skillProgressionData = skillProgressionData
                        entryData.headerText = headerText
                        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ARMORY_BUILD_SKILLS_DATA, entryData))

                        skillsAdded = skillsAdded + 1
                    end
                end
            end
        end
    end

    ZO_ScrollList_Commit(self.list)

    if reselectData then
        ZO_ScrollList_SelectData(self.list, reselectData)
    end
end

function ZO_ArmoryBuildSkills_Gamepad:AddSkillsCategoryHeader(scrollData, hotbarCategory)
    local headerText = zo_strformat(SI_GAMEPAD_ARMORY_SKILL_BAR_FORMATTER, GetString("SI_HOTBARCATEGORY", hotbarCategory))
    local headerData = ZO_GamepadEntryData:New(headerText)
    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ARMORY_BUILD_SKILLS_HEADER_DATA, headerData))
end

function ZO_ArmoryBuildSkills_Gamepad:GamepadSingleLineAbilityEntryTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    if not data.isEntryEmpty and not data.showLock then
        ZO_GamepadArmorySkillEntryTemplate_Setup(control, data.skillProgressionData, data.slotIndex, data.hotbarCategory)
    elseif not data.showLock then
        -- Empty entry
        control.lock:SetHidden(true)
        control.icon:SetHidden(true)
        control.edgeFrame:SetHidden(true)
        control.keybind:SetHidden(true)
    else
        -- Unlock at level
        control.lock:SetHidden(false)
        control.icon:SetHidden(true)
        control.edgeFrame:SetHidden(true)
        control.keybind:SetHidden(true)
    end
end

function ZO_ArmoryBuildSkills_Gamepad:ArmoryBuildSkillsTextDisplayTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    control.label:SetText(data.text)
end

do
    local NOT_BOUND_ACTION_STRING = GetString(SI_ACTION_IS_NOT_BOUND)
    local DEFAULT_SHOW_AS_HOLD = nil

    --Overridden from base
    function ZO_ArmoryBuildSkills_Gamepad:GetNarrationText()
        local narrations = {}
        local selectedData = self:GetSelectedData()
        if selectedData and not selectedData.isHeader then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.headerText))
            if not selectedData.isEntryEmpty then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.text))

                local keyboardActionName, gamepadActionName = ACTION_BAR_ASSIGNMENT_MANAGER:GetKeyboardAndGamepadActionNameForSlot(selectedData.slotIndex, selectedData.hotbarCategory)
                local bindingTextNarration = ZO_Keybindings_GetPreferredHighestPriorityNarrationStringFromActions(keyboardActionName, gamepadActionName, DEFAULT_SHOW_AS_HOLD) or NOT_BOUND_ACTION_STRING
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(bindingTextNarration))
            elseif selectedData.showLock then
                local infoText = zo_strformat(SI_WEAPON_SWAP_UNEARNED_TOOLTIP, GetWeaponSwapUnlockedLevel())
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(infoText))
            else
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_ARMORY_EMPTY_ENTRY_NARRATION)))
            end
        end
        return narrations
    end
end

-----------------------------
-- XML Functions
-----------------------------

function ZO_ArmoryBuildSkills_Gamepad_MenuEntryHeader_OnInitialized(control)
    control.label = control:GetNamedChild("Label")
end

function ZO_ArmoryBuildSkills_Gamepad_MenuEntryTemplate_OnInitialized(control)
    ZO_SharedGamepadEntry_OnInitialized(control)
    ZO_SharedGamepadEntry_SetHeightFromLabels(control)
end

function ZO_ArmoryBuildSkills_Gamepad_OnInitialized(control)
    ARMORY_BUILD_SKILLS_GAMEPAD = ZO_ArmoryBuildSkills_Gamepad:New(control)
end
