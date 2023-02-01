--------------
--Initialize--
--------------
local ARMORY_BUILD_CHAMPION_HEADER_DATA = 1
local ARMORY_BUILD_CHAMPION_DATA = 2

ZO_ArmoryBuildChampion_Gamepad = ZO_SortFilterList_Gamepad:Subclass()

function ZO_ArmoryBuildChampion_Gamepad:New(...)
    return ZO_SortFilterList_Gamepad.New(self, ...)
end

function ZO_ArmoryBuildChampion_Gamepad:Initialize(control)
    ZO_SortFilterList_Gamepad.Initialize(self, control)
    ZO_ScrollList_AddDataType(self.list, ARMORY_BUILD_CHAMPION_DATA, "ZO_ArmoryBuildChampion_Gamepad_AbilityRow", 55, function(...) self:GamepadSingleLineAbilityEntryTemplateSetup(...) end)
    ZO_ScrollList_AddDataType(self.list, ARMORY_BUILD_CHAMPION_HEADER_DATA, "ZO_ArmoryBuildChampion_Gamepad_MenuEntryHeader", 40, function(...) self:ArmoryBuildChampionTextDisplayTemplateSetup(...) end)
    ZO_ScrollList_SetTypeSelectable(self.list, ARMORY_BUILD_CHAMPION_HEADER_DATA, false)
    ZO_ScrollList_SetTypeCategoryHeader(self.list, ARMORY_BUILD_CHAMPION_HEADER_DATA, true)

    ARMORY_BUILD_CHAMPION_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    ARMORY_BUILD_CHAMPION_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                                    if newState == SCENE_FRAGMENT_SHOWING then
                                                                        self:OnShowing()
                                                                    elseif newState == SCENE_FRAGMENT_HIDDEN then
                                                                        self:OnHidden()
                                                                    end
                                                                end)

    self:InitializeKeybinds()
end

function ZO_ArmoryBuildChampion_Gamepad:OnShowing()
    self:RefreshData()
    self:UpdateTooltip()
end

function ZO_ArmoryBuildChampion_Gamepad:OnHidden()
    self:Deactivate()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_ArmoryBuildChampion_Gamepad:IsShowing()
    return ARMORY_BUILD_CHAMPION_GAMEPAD_FRAGMENT:IsShowing()
end

function ZO_ArmoryBuildChampion_Gamepad:Activate()
    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
    ZO_SortFilterList_Gamepad.Activate(self)
    self:UpdateTooltip()

    self.keybindStripId = KEYBIND_STRIP:PushKeybindGroupState()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor, self.keybindStripId)
end

function ZO_ArmoryBuildChampion_Gamepad:Deactivate()
    ZO_SortFilterList_Gamepad.Deactivate(self)
    self:UpdateTooltip()

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor, self.keybindStripId)
    KEYBIND_STRIP:PopKeybindGroupState()
    self.keybindStripId = nil
end

function ZO_ArmoryBuildChampion_Gamepad:SetSelectedArmoryBuildData(armoryBuildData)
    self.armoryBuildData = armoryBuildData
end

function ZO_ArmoryBuildChampion_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_SortFilterList_Gamepad.OnSelectionChanged(self, oldData, newData)
    self:UpdateTooltip()
end

function ZO_ArmoryBuildChampion_Gamepad:InitializeKeybinds()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Armory Build Champion Previous Category",
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
            name = "Gamepad Armory Build Champion Next Category",
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

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, Back)
end

function ZO_ArmoryBuildChampion_Gamepad:UpdateTooltip()
    if self:IsShowing() then
        GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)

        if self.isActive then
            local selectedData = self:GetSelectedData()
            if selectedData and not selectedData.isHeader and not selectedData.isEntryEmpty then
                GAMEPAD_TOOLTIPS:LayoutArmoryBuildChampionSkill(GAMEPAD_RIGHT_TOOLTIP, selectedData.championSkillData)
            end
        end
    end
end

do
    local CHAMPION_SKILL_DISCIPLINE_ICONS = 
    {
        [CHAMPION_DISCIPLINE_TYPE_COMBAT] = "EsoUI/Art/Champion/Gamepad/gp_quickmenu_combat.dds",
        [CHAMPION_DISCIPLINE_TYPE_CONDITIONING] = "EsoUI/Art/Champion/Gamepad/gp_quickmenu_conditioning.dds",
        [CHAMPION_DISCIPLINE_TYPE_WORLD] = "EsoUI/Art/Champion/Gamepad/gp_quickmenu_world.dds",
    }

    local function AddEntry(scrollData, disciplineType, championSkillId)
        if championSkillId == 0 then
            -- No champion skill set
            local entryData = ZO_GamepadEntryData:New(GetString(SI_GAMEPAD_ARMORY_EMPTY_ENTRY_TEXT))
            entryData.isEntryEmpty = true
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ARMORY_BUILD_CHAMPION_DATA, entryData))
            return entryData
        else
            local entryText = ZO_CachedStrFormat(SI_CHAMPION_STAR_NAME, GetChampionSkillName(championSkillId))
            local entryData = ZO_GamepadEntryData:New(entryText, CHAMPION_SKILL_DISCIPLINE_ICONS[disciplineType])
            entryData.championSkillData = CHAMPION_DATA_MANAGER:GetChampionSkillData(championSkillId)
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ARMORY_BUILD_CHAMPION_DATA, entryData))
            return entryData
        end
    end

    function ZO_ArmoryBuildChampion_Gamepad:SortScrollList()
        local previouslySelectedData = self:GetSelectedData()
        local reselectData = nil

        ZO_ScrollList_Clear(self.list)
        local scrollData = ZO_ScrollList_GetDataList(self.list)

        local startSlotIndex, endSlotIndex = GetAssignableChampionBarStartAndEndSlots()
        local lastDisciplineId = nil
        local disciplineSection = nil
        for actionSlotIndex = startSlotIndex, endSlotIndex do
            local currentDisciplineId = GetRequiredChampionDisciplineIdForSlot(actionSlotIndex, HOTBAR_CATEGORY_CHAMPION)
            local headerText = nil
            if lastDisciplineId ~= currentDisciplineId then
                headerText = ZO_CachedStrFormat(SI_CHAMPION_CONSTELLATION_NAME_FORMAT, GetChampionDisciplineName(currentDisciplineId))
                local headerData = ZO_GamepadEntryData:New(headerText)
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ARMORY_BUILD_CHAMPION_HEADER_DATA, headerData))

                lastDisciplineId = currentDisciplineId
            end

            local disciplineType = GetChampionDisciplineType(currentDisciplineId)
            local championSkillId = self.armoryBuildData:GetSlottedChampionSkillId(actionSlotIndex)
            local entry = AddEntry(scrollData, disciplineType, championSkillId)
            entry.headerText = headerText
        end

        ZO_ScrollList_Commit(self.list)

        if reselectData then
            ZO_ScrollList_SelectData(self.list, reselectData)
        end
    end
end

function ZO_ArmoryBuildChampion_Gamepad:GamepadSingleLineAbilityEntryTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
end

function ZO_ArmoryBuildChampion_Gamepad:ArmoryBuildChampionTextDisplayTemplateSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    control.label:SetText(data.text)
end

--Overridden from base
function ZO_ArmoryBuildChampion_Gamepad:GetNarrationText()
    local narrations = {}
    local selectedData = self:GetSelectedData()
    if selectedData and not selectedData.isHeader then
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.headerText))
        if not selectedData.isEntryEmpty then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.text))
        else
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_ARMORY_EMPTY_ENTRY_NARRATION)))
        end
    end
    return narrations
end

-----------------------------
-- XML Functions
-----------------------------

function ZO_ArmoryBuildChampion_Gamepad_MenuEntryHeader_OnInitialized(control)
    control.label = control:GetNamedChild("Label")
end

function ZO_ArmoryBuildChampion_Gamepad_OnInitialized(control)
    ARMORY_BUILD_CHAMPION_GAMEPAD = ZO_ArmoryBuildChampion_Gamepad:New(control)
end
