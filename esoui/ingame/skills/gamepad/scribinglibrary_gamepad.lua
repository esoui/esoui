ZO_ScribingLibrary_Gamepad = ZO_ScribingLayout_Gamepad:Subclass()

function ZO_ScribingLibrary_Gamepad:Initialize(control)
    local ACTIVATE_LIST_ON_SHOW = true
    GAMEPAD_SKILLS_SCRIBING_LIBRARY_ROOT_SCENE = ZO_Scene:New("gamepad_skills_scribing_library_root", SCENE_MANAGER)
    GAMEPAD_SKILLS_SCENE_GROUP:AddScene("gamepad_skills_scribing_library_root")
    GAMEPAD_SKILLS_SCRIBING_LIBRARY_ROOT_SCENE:SetHideSceneConfirmationCallback(ZO_GamepadSkills.OnConfirmHideScene)
    ZO_ScribingLayout_Gamepad.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_LIST_ON_SHOW, GAMEPAD_SKILLS_SCRIBING_LIBRARY_ROOT_SCENE)

    local scribingLibraryFragment = ZO_FadeSceneFragment:New(control)
    GAMEPAD_SKILLS_SCRIBING_LIBRARY_ROOT_SCENE:AddFragment(scribingLibraryFragment)

    self.headerData =
    {
        titleText = GetString(SI_SCRIBING_TITLE),
        subtitleText = function()
            if self:IsCurrentList(self.craftedAbilityList) then
                return GetString(SI_CRAFTED_ABILITY_SUBTITLE)
            end
        end,
    }

    self:InitializeLists()

    local function OnSkillLineUpdated(skillLineData)
        if self:IsShowing() then
            local list = self:GetCurrentList()
            if list then
                local selectedData = list:GetTargetData()
                self:RefreshSelection(list, selectedData)
            end
        end
    end

    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineUpdated", OnSkillLineUpdated)
end

-- Start Overridden from ZO_ScribingLayout_Gamepad

function ZO_ScribingLibrary_Gamepad:RefreshHeader()
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_ScribingLibrary_Gamepad:InitializeKeybindStripDescriptors()
    ZO_ScribingLayout_Gamepad.InitializeKeybindStripDescriptors(self)

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local entryData = self:GetCurrentList():GetTargetData()
                if entryData and entryData.isCraftedAbilitiesEntry then
                    ZO_GAMEPAD_SCRIBING_CRAFTED_ABILITY_SKILLS:Activate()
                else
                    self:SelectCraftedAbility()
                end
            end,
            enabled = function()
                return SCRIBING_DATA_MANAGER:IsScribingUnlocked()
            end,
            visible = function()
                return self:IsCurrentList(self.craftedAbilityList)
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
    }

    local function BackNavigationCallback()
        if self:IsCurrentList(self.scriptsList) then
            self:ShowCraftedAbilities()
        else
            SCENE_MANAGER:HideCurrentScene()
        end
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, BackNavigationCallback)

    self:SetListsUseTriggerKeybinds(true)
end

function ZO_ScribingLibrary_Gamepad:OnShow()
    ZO_ScribingLayout_Gamepad.OnShow(self)

    local RESET_TO_TOP = true
    self:ShowCraftedAbilities(RESET_TO_TOP)

    local list = self:GetCurrentList()
    if list then
        local selectedData = list:GetTargetData()
        self:RefreshSelection(list, selectedData)
    end

    TriggerTutorial(TUTORIAL_TRIGGER_SKILLS_SCRIBING_OPENED)
end

function ZO_ScribingLibrary_Gamepad:RefreshCraftedAbilityList(resetToTop)
    self.craftedAbilityList:Clear()

    if SCRIBING_DATA_MANAGER:HasScribedCraftedAbilitySkillsData() and not self:HasSearchFilter() then
        local craftedAbilitySkillsEntryData = ZO_GamepadEntryData:New(GetString(SI_SCRIBING_CRAFTED_ABILITIES))
        craftedAbilitySkillsEntryData.isCraftedAbilitiesEntry = true
        self.craftedAbilityList:AddEntry("ZO_GamepadNewMenuEntryTemplate", craftedAbilitySkillsEntryData)
    end

    local APPEND_TO_LIST = true
    ZO_ScribingLayout_Gamepad.RefreshCraftedAbilityList(self, resetToTop, APPEND_TO_LIST)
end

function ZO_ScribingLibrary_Gamepad:GetCraftedAbilityList()
    return SCRIBING_DATA_MANAGER:GetSortedBySkillTypeCraftedAbilityData()
end

function ZO_ScribingLibrary_Gamepad:OnEnterHeader()
    ZO_ScribingLayout_Gamepad.OnEnterHeader(self)

    self:RefreshSelection(self:GetCurrentList())
end

function ZO_ScribingLibrary_Gamepad:OnLeaveHeader()
    ZO_ScribingLayout_Gamepad.OnLeaveHeader(self)

    local list = self:GetCurrentList()
    if list then
        local selectedData = list:GetTargetData()
        self:RefreshSelection(list, selectedData)
    end
end

function ZO_ScribingLibrary_Gamepad:OnSelectionChanged(list, selectedData, previousData)
    ZO_ScribingLayout_Gamepad.OnSelectionChanged(self, list, selectedData, previousData)

    if not self:IsHeaderActive() then
        self:RefreshSelection(list, selectedData)
    end
end

function ZO_ScribingLibrary_Gamepad:RefreshSelection(list, selectedData)
    SCENE_MANAGER:RemoveFragment(SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_GAMEPAD_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(GAMEPAD_LEFT_TOOLTIP_BACKGROUND_FRAGMENT)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)

    if list == self.craftedAbilityList then
        if selectedData then
            if selectedData.isCraftedAbilitiesEntry then
                if SCRIBING_DATA_MANAGER:IsScribingUnlocked() then
                    SCENE_MANAGER:AddFragment(SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_GAMEPAD_FRAGMENT)
                    SCENE_MANAGER:AddFragment(GAMEPAD_LEFT_TOOLTIP_BACKGROUND_FRAGMENT)
                else
                    local collectibleData = SCRIBING_DATA_MANAGER:IsScribingUnlockCollectibleData()
                    local lockedCollectibleText = zo_strformat(SI_SCRIBING_LOCKED_DESCRIPTION, collectibleData:GetName(), collectibleData:GetCategoryData():GetName())
                    GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_TOOLTIP, lockedCollectibleText)
                end
            else
                self:LayoutTooltipForCraftedAbilityData(selectedData and selectedData.data)
            end
        end
    elseif list == self.scriptsList then
        self:LayoutTooltipForScriptData(selectedData and selectedData.data)
    end

    if not SCRIBING_DATA_MANAGER:IsScribingContentAccessible() and not SCRIBING_DATA_MANAGER:HasScribedCraftedAbilitySkillsData() then
        GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_RIGHT_TOOLTIP, SCRIBING_DATA_MANAGER:GetScribingInaccessibleText())
    end
end

-- End Overridden from ZO_ScribingLayout_Gamepad

-- Global XML Functions --

function ZO_ScribingLibrary_Gamepad.OnControlInitialized(control)
    SCRIBING_LIBRARY_GAMEPAD = ZO_ScribingLibrary_Gamepad:New(control)
end