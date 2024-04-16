ZO_ScribingLibrary_Keyboard = ZO_Object.MultiSubclass(ZO_DeferredInitializingObject, ZO_ScribingLayout_Keyboard)

function ZO_ScribingLibrary_Keyboard:Initialize(control)
    self.scene = ZO_Scene:New("scribingLibraryKeyboard", SCENE_MANAGER)
    ZO_ScribingLayout_Keyboard.Initialize(self, control)
    ZO_DeferredInitializingObject.Initialize(self, self.scene)

    self.infoTextControl = self.control:GetNamedChild("InfoText")

    local fragment = ZO_FadeSceneFragment:New(control)
    self.scene:AddFragment(fragment)
end

function ZO_ScribingLibrary_Keyboard:OnDeferredInitialize()
    self:PerformDeferredInitialization()

    self:InitializeKeybindStripDescriptors()

    local function OnSkillLineUpdated(skillLineData)
        if self:IsShowing() then
            self:RefreshLeftPanel()
        end
    end

    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineUpdated", OnSkillLineUpdated)
end

function ZO_ScribingLibrary_Keyboard:OnShowing()
    local RESET_TO_TOP = true
    self:ShowCraftedAbilities(RESET_TO_TOP)

    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

    self:RefreshLeftPanel()

    self:ActivateTextSearch()
end

function ZO_ScribingLibrary_Keyboard:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RestoreDefaultExit()

    self:ClearMouseOverState()

    self:DeactivateTextSearch()
end

function ZO_ScribingLibrary_Keyboard:OnHidden()
    ResetCraftedAbilityScriptSelectionOverride()
end

function ZO_ScribingLibrary_Keyboard:RefreshLeftPanel()
    self.infoTextControl:SetHidden(true)

    if SCRIBING_DATA_MANAGER:HasScribedCraftedAbilitySkillsData() then
        self.scene:AddFragment(FRAME_TARGET_STANDARD_RIGHT_PANEL_MEDIUM_LEFT_PANEL_FRAGMENT)
        self.scene:AddFragment(FRAME_TARGET_BLUR_STANDARD_RIGHT_PANEL_MEDIUM_LEFT_PANEL_FRAGMENT)
        self.scene:AddFragment(SCRIBING_LIBRARY_CRAFTED_ABILITY_SKILLS_FRAGMENT)
    else
        if not SCRIBING_DATA_MANAGER:IsScribingContentAccessible() then
            self.infoTextControl:SetText(SCRIBING_DATA_MANAGER:GetScribingInaccessibleText())
            self.infoTextControl:SetHidden(false)
            self.scene:AddFragment(MEDIUM_LEFT_PANEL_BG_FRAGMENT)
        end
        self.scene:AddFragment(FRAME_TARGET_STANDARD_RIGHT_PANEL_FRAGMENT)
        self.scene:AddFragment(FRAME_TARGET_BLUR_STANDARD_RIGHT_PANEL_FRAGMENT)
    end
end

function ZO_ScribingLibrary_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Select Grimoire
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_SCRIBING_LIBRARY_SELECT_GRIMOIRE),
            callback = function()
                local entryData = self:GetMouseOverCraftedAbilityEntry().dataEntry.data
                local craftedAbilityId = entryData:GetId()
                self:SelectCraftedAbilityId(craftedAbilityId)
            end,
            visible = function()
                return self:HasMouseOverCraftedAbilityEntry()
            end,
        },

        -- Exit/Back
        {
            name = function()
                if self:AreScriptsShowing() then
                    return GetString(SI_SCRIBING_BACK_KEYBIND_LABEL)
                else
                    return GetString(SI_EXIT_BUTTON)
                end
            end,
            keybind = "UI_SHORTCUT_EXIT",
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            callback = function()
                if self:AreScriptsShowing() then
                    self:ShowCraftedAbilities()
                else
                    SCENE_MANAGER:HideCurrentScene()
                end
            end,
        },
    }
end

function ZO_ScribingLibrary_Keyboard:ShowCraftedAbilities(resetToTop)
    ZO_ScribingLayout_Keyboard.ShowCraftedAbilities(self, resetToTop)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

-- Overridden from ZO_ScribingLayout_Keyboard

function ZO_ScribingLibrary_Keyboard:GetCraftedAbilityDataList()
    return SCRIBING_DATA_MANAGER:GetSortedBySkillTypeCraftedAbilityData()
end

function ZO_ScribingLibrary_Keyboard:SetMouseOverCraftedAbilityEntry(...)
    ZO_ScribingLayout_Keyboard.SetMouseOverCraftedAbilityEntry(self, ...)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_ScribingLibrary_Keyboard:SelectCraftedAbilityId(craftedAbilityId)
    ZO_ScribingLayout_Keyboard.SelectCraftedAbilityId(self, craftedAbilityId)

    local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
    if craftedAbilityData then
        craftedAbilityData:SetScriptIdSelectionOverride(0, 0, 0)

        self:ShowScripts()
    else
        self:ShowCraftedAbilities()
    end
end

function ZO_ScribingLibrary_Keyboard:GetIconsForScriptData(scriptData)
    local icons = {}

    local craftedAbilityData = self:GetSelectedCraftedAbilityData()
    if craftedAbilityData:IsScriptActive(scriptData) then
        table.insert(icons, "EsoUI/Art/Crafting/scribing_activeScript_icon.dds")
    end

    return icons
end

-- End Overridden from ZO_ScribingLayout_Keyboard

--
-- Functions for XML
--

function ZO_ScribingLibrary_Keyboard.OnControlInitialized(control)
    SCRIBING_LIBRARY_KEYBOARD = ZO_ScribingLibrary_Keyboard:New(control)
end
