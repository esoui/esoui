ZO_Scribing_Gamepad = ZO_Object.MultiSubclass(ZO_Scribing_Shared, ZO_ScribingLayout_Gamepad)

function ZO_Scribing_Gamepad:Initialize(control)
    self.interactSceneName = "scribingGamepad"

    ZO_Scribing_Shared.Initialize(self, control, self.interactSceneName)
    ZO_ScribingLayout_Gamepad.Initialize(self, control, ZO_DO_NOT_CREATE_TAB_BAR, DONT_ACTIVATE_ON_SHOW, self.interactScene)

    SCRIBING_SCENE_GAMEPAD = self.interactScene
    SCRIBING_FRAGMENT_GAMEPAD = ZO_SimpleSceneFragment:New(control)
    SCRIBING_SCENE_GAMEPAD:AddFragment(SCRIBING_FRAGMENT_GAMEPAD)

    self.headerData =
    {
        titleText = function()
            if self:IsCurrentList(self.recentCraftedAbilitiesList) then
                return GetString(SI_SCRIBING_RECENT_TITLE)
            else
                return GetString(SI_SCRIBING_GAMEPAD_SCRIBING_TITLE)
            end
        end,
        subtitleText = function()
            if self:IsCurrentList(self.craftedAbilityList) then
                return GetString(SI_CRAFTED_ABILITY_SUBTITLE)
            end
        end,
        data1HeaderText = function()
            if self:IsCurrentList(self.scriptsList) then
                return ZO_Scribing_Manager.GetFormattedScribingInkName()
            end
        end,
        data1Text = function()
            if self:IsCurrentList(self.scriptsList) then
                return ZO_Scribing_Manager.GetFormattedNoSpaceAlignedRightScribingInkAmount()
            end
        end,
    }

    SYSTEMS:RegisterGamepadRootScene("scribing", SCRIBING_SCENE_GAMEPAD)
end

function ZO_Scribing_Gamepad:InitializeScriptFiltersDialog()
    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_SCRIBING_SCRIPT_FILTERS",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        setup = function(dialog)
            dialog:setupFunc()
        end,
        title =
        {
            text = GetString(SI_GAMEPAD_CRAFTING_OPTIONS_FILTERS),
        },
        parametricList =
        {
            -- Usable Checkbox
            {
                template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
                text = GetString(SI_SCRIBING_FILTER_USABLE),
                templateData =
                {
                    -- Called when the checkbox is toggled
                    setChecked = function(checkBox, checked)
                        self.scriptFilters.isUsable = checked
                        SCREEN_NARRATION_MANAGER:QueueDialog(checkBox.dialog)
                    end,

                    -- Used during setup to determine if the data should be setup checked or unchecked
                    checked = function(data)
                        return self.scriptFilters.isUsable
                    end,

                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.checkBox.dialog = data.dialog
                        ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)
                    end,

                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)
                    end,

                    narrationText = function(entryData, entryControl)
                        local isChecked = entryData.checked(entryData)
                        return ZO_FormatToggleNarrationText(entryData.text, isChecked)
                    end,
                },
            },
        },
        blockDialogReleaseOnPress = true,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback =  function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData then
                        targetData.callback(dialog)
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback =  function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_SCRIBING_SCRIPT_FILTERS")
                    self:RefreshScriptsList()
                end,
            },
        },
    })
end

-- Overridden from ZO_Scribing_Shared

function ZO_Scribing_Gamepad:OnDeferredInitialize()
    ZO_Scribing_Shared.OnDeferredInitialize(self)

    self:InitializeLists()
    self:InitializeScriptFiltersDialog()

    local function OnInventoryUpdated()
        if self:IsShowing() then
            self:UpdateInkDisplay()
        end
    end

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", OnInventoryUpdated)
end

-- Also overridden from ZO_ScribingLayout_Gamepad
function ZO_Scribing_Gamepad:InitializeLists()
    ZO_ScribingLayout_Gamepad.InitializeLists(self)

    local DEFAULT_EQUALITY_FUNCTION = nil
    self.recentCraftedAbilitiesList = self:AddList("recentCraftedAbilitiesList")
    self.recentCraftedAbilitiesList:AddDataTemplate("ZO_GamepadSubMenuEntryTemplateWithStatus", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, DEFAULT_EQUALITY_FUNCTION, "RecentCraftedAbilityEntry")
    self.recentCraftedAbilitiesList:SetNoItemText(GetString(SI_SCRIBING_NO_RECENT_CRAFTED_ABILITIES))
end

function ZO_Scribing_Gamepad:InitializeSlots()
    ZO_Scribing_Shared.InitializeSlots(self)

    self.scribingSelectInkContainer = self.control:GetNamedChild("InkRequired")
    self.slotsInkCostLabel = self.scribingSelectInkContainer:GetNamedChild("Text")

    local function GamepadCraftedAbilitySlotTemplateSetup(control, data)
        data.slot = ZO_SharedCraftedAbilitySlot:New(data.owner, control, data.slotIcon, data.slotIconDrag, data.slotIconNegative, data.soundPlaced, data.soundRemoved, data.emptySlotIcon)
    end

    local function GamepadCraftedAbilityScriptSlotTemplateSetup(control, data)
        data.slot = ZO_SharedCraftedAbilityScriptSlot:New(data.owner, control, data.slotIcon, data.slotIconDrag, data.slotIconNegative, data.soundPlaced, data.soundRemoved, data.type, data.emptySlotIcon)
    end

    local IS_VERTICAL = true
    self.scribingBar = ZO_GamepadCraftingIngredientBar:New(self.slotsContainer, IS_VERTICAL)
    self.scribingBar:AddDataTemplate("ZO_GamepadCraftedAbilitySlot", GamepadCraftedAbilitySlotTemplateSetup)
    self.scribingBar:AddDataTemplate("ZO_GamepadCraftedAbilityScriptSlot", GamepadCraftedAbilityScriptSlotTemplateSetup)

    self.scribingBar:Clear()

    local craftedAbilitySlotData =
    {
        owner = self,
        slotIcon = "EsoUI/Art/Skills/Gamepad/gp_scribing_grimoire_slot.dds",
        slotIconDrag = "EsoUI/Art/Skills/Gamepad/gp_scribing_grimoire_dragging.dds",
        slotIconNegative = "EsoUI/Art/Skills/Gamepad/gp_scribing_grimoire_negative.dds",
        soundPlaced = SOUNDS.SCRIBING_CRAFTED_ABILITY_PLACED,
        soundRemoved = SOUNDS.SCRIBING_CRAFTED_ABILITY_REMOVED,
        emptySlotIcon = "EsoUI/Art/Skills/Gamepad/gp_scribing_grimoire_slot.dds",
    }

    self.scribingBar:AddEntry("ZO_GamepadCraftedAbilitySlot", craftedAbilitySlotData)
    self:SetCraftedAbilitySlot(craftedAbilitySlotData.slot)

    local primarySlotData =
    {
        owner = self,
        slotIcon = "EsoUI/Art/Skills/Gamepad/gp_scribing_primary_slot.dds",
        slotIconDrag = "EsoUI/Art/Skills/Gamepad/gp_scribing_primary_dragging.dds",
        slotIconNegative = "EsoUI/Art/Skills/Gamepad/gp_scribing_primary_negative.dds",
        soundPlaced = SOUNDS.SCRIBING_PRIMARY_SCRIPT_PLACED,
        soundRemoved = SOUNDS.SCRIBING_PRIMARY_SCRIPT_REMOVED,
        type = SCRIBING_SLOT_PRIMARY,
        emptySlotIcon = "EsoUI/Art/Skills/Gamepad/gp_scribing_primary_slot.dds",
    }

    self.scribingBar:AddEntry("ZO_GamepadCraftedAbilityScriptSlot", primarySlotData)
    self:AddScriptSlot(SCRIBING_SLOT_PRIMARY, primarySlotData.slot)

    local secondarySlotData =
    {
        owner = self,
        slotIcon = "EsoUI/Art/Skills/Gamepad/gp_scribing_secondary_slot.dds",
        slotIconDrag = "EsoUI/Art/Skills/Gamepad/gp_scribing_secondary_dragging.dds",
        slotIconNegative = "EsoUI/Art/Skills/Gamepad/gp_scribing_secondary_negative.dds",
        soundPlaced = SOUNDS.SCRIBING_SECONDARY_SCRIPT_PLACED,
        soundRemoved = SOUNDS.SCRIBING_SECONDARY_SCRIPT_REMOVED,
        type = SCRIBING_SLOT_SECONDARY,
        emptySlotIcon = "EsoUI/Art/Skills/Gamepad/gp_scribing_secondary_slot.dds"
    }
    self.scribingBar:AddEntry("ZO_GamepadCraftedAbilityScriptSlot", secondarySlotData)
    self:AddScriptSlot(SCRIBING_SLOT_SECONDARY, secondarySlotData.slot)

    local tertiarySlotData =
    {
        owner = self,
        slotIcon = "EsoUI/Art/Skills/Gamepad/gp_scribing_tertiary_slot.dds",
        slotIconDrag = "EsoUI/Art/Skills/Gamepad/gp_scribing_tertiary_dragging.dds",
        slotIconNegative = "EsoUI/Art/Skills/Gamepad/gp_scribing_tertiary_negative.dds",
        soundPlaced = SOUNDS.SCRIBING_TERTIARY_SCRIPT_PLACED,
        soundRemoved = SOUNDS.SCRIBING_TERTIARY_SCRIPT_REMOVED,
        type = SCRIBING_SLOT_TERTIARY,
        emptySlotIcon = "EsoUI/Art/Skills/Gamepad/gp_scribing_tertiary_slot.dds",
    }
    self.scribingBar:AddEntry("ZO_GamepadCraftedAbilityScriptSlot", tertiarySlotData)
    self:AddScriptSlot(SCRIBING_SLOT_TERTIARY, tertiarySlotData.slot)

    self.scribingBar:Commit()
end

-- Also overridden from ZO_ScribingLayout_Gamepad
function ZO_Scribing_Gamepad:InitializeKeybindStripDescriptors()
    ZO_ScribingLayout_Gamepad.InitializeKeybindStripDescriptors(self)

    -- Mode keybind strip
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Selection
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                if self:IsCurrentList(self.scriptsList) then
                    local entryData = self:GetCurrentList():GetTargetData()
                    if entryData and entryData.data then
                        local scriptId = entryData.data:GetId()
                        local scriptData = self:GetScriptDataById(scriptId)
                        if scriptData then
                            if self:GetScriptIdBySlot(scriptData:GetScribingSlot()) == scriptData:GetId() then
                                return GetString(SI_ITEM_ACTION_REMOVE_FROM_CRAFT)
                            else
                                return GetString(SI_ITEM_ACTION_ADD_TO_CRAFT)
                            end
                        end
                    end
                end
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,
            callback = function()
                if self:IsCurrentList(self.craftedAbilityList) then
                    local entryData = self:GetCurrentList():GetTargetData()
                    if entryData and entryData.isRecentCraftedAbilitiesEntry then
                        self:ShowRecentCraftedAbilitiesList()
                    else
                        self:SelectCraftedAbility()
                    end
                elseif self:IsCurrentList(self.scriptsList) then
                    self:SelectScript()
                elseif self:IsCurrentList(self.recentCraftedAbilitiesList) then
                    self:SelectRecentCraftedAbility()
                end
            end,
            enabled = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
            sound = function()
                -- don't play a sound when we select a crafted ability or script,
                -- since the slot will play a sound when it is added/removed
                if self:IsCurrentList(self.scriptsList) then
                    return nil
                elseif self:IsCurrentList(self.craftedAbilityList) then
                    local entryData = self:GetCurrentList():GetTargetData()
                    if entryData and not entryData.isRecentCraftedAbilitiesEntry then
                        return nil
                    end
                end

                return SOUNDS.GAMEPAD_MENU_FORWARD
            end,
        },
        -- Perform craft
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_SCRIBING_PERFORM_SCRIBE_KEYBIND),
            callback = function()
                self:ScribeCurrentSelection()
            end,
            enabled = function()
                return self:ShouldCraftButtonBeEnabled()
            end,
            visible = function()
                return self:IsCurrentList(self.scriptsList)
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Open filters
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = function()
                if self:IsCurrentList(self.craftedAbilityList) then
                    return GetString(SI_SCRIBING_TO_SKILLS_ACTION)
                else
                    return GetString(SI_GAMEPAD_CRAFTING_OPTIONS_FILTERS)
                end
            end,
            callback = function()
                if self:IsCurrentList(self.craftedAbilityList) then
                    local entryData = self:GetCurrentList():GetTargetData()
                    if entryData and not entryData.isRecentCraftedAbilitiesEntry then
                        local craftedAbilityId = entryData.data:GetId()
                        local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
                        if craftedAbilityData then
                            MAIN_MENU_GAMEPAD:ShowScene("gamepad_skills_root")
                            GAMEPAD_SKILLS:SelectSkillLineBySkillData(craftedAbilityData:GetSkillData())
                        end
                    end
                else
                    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_SCRIBING_SCRIPT_FILTERS")
                end
            end,
            enabled = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
            visible = function()
                if self:IsCurrentList(self.craftedAbilityList) then
                    local entryData = self:GetCurrentList():GetTargetData()
                    if entryData and not entryData.isRecentCraftedAbilitiesEntry then
                        local craftedAbilityId = entryData.data:GetId()
                        local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
                        if craftedAbilityData then
                            return craftedAbilityData:GetAbilityId() ~= 0
                        end
                    end
                else
                    return self:IsCurrentList(self.scriptsList)
                end
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Clear scripts
        {
            keybind = "UI_SHORTCUT_QUATERNARY",
            name = GetString(SI_SCRIBING_CLEAR_SCRIPT_SELECTIONS),
            callback = function()
                self:ClearSelectedScripts()
            end,
            enabled = function()
                return self:IsAnyScriptSlotted() and not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
            visible = function()
                return self:IsCurrentList(self.scriptsList)
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
    }

    local keybindStripBackDescriptor = KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
        self:OnBackButtonClicked()
    end)
    keybindStripBackDescriptor.visible = function()
        return not ZO_CraftingUtils_IsPerformingCraftProcess()
    end
    table.insert(self.keybindStripDescriptor, keybindStripBackDescriptor)

    self:SetListsUseTriggerKeybinds(true)

    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)
end

function ZO_Scribing_Gamepad:OnBackButtonClicked()
    if self:IsCurrentList(self.scriptsList) or self:IsCurrentList(self.recentCraftedAbilitiesList) then
        self:RequestLeaveHeader()
        self:ShowCraftedAbilities()
    else
        SCENE_MANAGER:HideCurrentScene()
    end
end

-- Also overridden from ZO_ScribingLayout_Gamepad 
function ZO_Scribing_Gamepad:OnShow()
    ZO_ScribingLayout_Gamepad.OnShow(self)
    ZO_Scribing_Shared.OnShow(self)

    local RESET_TO_TOP = true
    self:ShowCraftedAbilities(RESET_TO_TOP)

    GAMEPAD_CRAFTING_RESULTS:SetTooltipAnimationSounds(SOUNDS.SCRIBING_SCRIBE_TOOLTIP_GLOW)
end

function ZO_Scribing_Gamepad:OnHiding()
    ZO_Gamepad_ParametricList_Search_Screen.OnHiding(self)
end

-- Also overridden from ZO_ScribingLayout_Gamepad
function ZO_Scribing_Gamepad:ShowCraftedAbilities(resetToTop)
    ZO_ScribingLayout_Gamepad.ShowCraftedAbilities(self, resetToTop)
    ZO_Scribing_Shared.ShowCraftedAbilities(self, resetToTop)

    self.scribingSelectInkContainer:SetHidden(true)
end

-- Also overridden from ZO_ScribingLayout_Gamepad
function ZO_Scribing_Gamepad:RefreshCraftedAbilityList(resetToTop)
    self.craftedAbilityList:Clear()

    if SCRIBING_MANAGER:HasAnyUnscribedRecentCraftedAbilities() and not self:HasSearchFilter() then
        local craftedAbilityEntryData = ZO_GamepadEntryData:New(GetString(SI_SCRIBING_RECENT_TITLE), "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_recent.dds")
        craftedAbilityEntryData.isRecentCraftedAbilitiesEntry = true
        self.craftedAbilityList:AddEntry("ZO_GamepadMenuEntryTemplate", craftedAbilityEntryData)
    end

    local APPEND_TO_LIST = true
    ZO_ScribingLayout_Gamepad.RefreshCraftedAbilityList(self, resetToTop, APPEND_TO_LIST)
    ZO_Scribing_Shared.RefreshCraftedAbilityList(self, resetToTop)
end

-- Also overridden from ZO_ScribingLayout_Gamepad
function ZO_Scribing_Gamepad:ShowScripts()
    ZO_ScribingLayout_Gamepad.ShowScripts(self)

    if self:IsCraftedAbilitySelected() then
        ZO_Scribing_Shared.ShowScripts(self)

        self.slotsContainer:SetHidden(false)
        self.scribingSelectInkContainer:SetHidden(false)
    end
end

-- Also overridden from ZO_ScribingLayout_Gamepad
function ZO_Scribing_Gamepad:RefreshScriptsList(resetToTop)
    ZO_ScribingLayout_Gamepad.RefreshScriptsList(self, resetToTop)
    ZO_Scribing_Shared.RefreshScriptsList(self, resetToTop)
end

function ZO_Scribing_Gamepad:UpdateInkDisplay()
    self:RefreshHeader()
end

function ZO_Scribing_Gamepad:UpdateResultTooltip()
    if not self:IsCurrentList(self.recentCraftedAbilitiesList) then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)

        if self:HasCraftedAbilitySlotted() then
            local primaryScriptId, secondaryScriptId, tertiaryScriptId = self:GetSlottedScriptIds()
            local OPTIONS = { displayFlags = SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_SELECTED_SCRIPTS + SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_ERRORS }
            GAMEPAD_TOOLTIPS:LayoutCraftedAbilityByIds(GAMEPAD_RIGHT_TOOLTIP, self:GetSlottedCraftedAbilityId(), primaryScriptId, secondaryScriptId, tertiaryScriptId, OPTIONS)
        end
    end
end

function ZO_Scribing_Gamepad:GetScriptDataDisabledColor()
    return ZO_GAMEPAD_DISABLED_SELECTED_COLOR
end

-- End Overridden from ZO_Scribing_Shared

-- Start Overridden from ZO_ScribingLayout_Gamepad

function ZO_Scribing_Gamepad:ShouldShowScript(craftedAbilityId, scriptId)
    return self:IsScriptIdCompatibleWithFilters(craftedAbilityId, scriptId)
end

function ZO_Scribing_Gamepad:IsScriptDataSelected(scriptData)
    return self:GetScriptIdBySlot(scriptData:GetScribingSlot()) == scriptData:GetId()
end

function ZO_Scribing_Gamepad:IsScriptDataCompatible(craftedAbilityId, scriptData)
    local primaryScriptId, secondaryScriptId, tertiaryScriptId = self:GetSlottedScriptIds()
    return scriptData:IsCompatibleWithSelections(craftedAbilityId, primaryScriptId, secondaryScriptId, tertiaryScriptId)
end

function ZO_Scribing_Gamepad:IsCraftedAbilitySelected()
    return self:HasCraftedAbilitySlotted()
end

function ZO_Scribing_Gamepad:SelectCraftedAbilityId(craftedAbilityId)
    self:SlotCraftedAbilityById(craftedAbilityId)
end

function ZO_Scribing_Gamepad:SetSelectedCraftedAbilityId(craftedAbilityId)
    self.craftedAbilitySlot:SetCraftedAbilityId(craftedAbilityId)
end

function ZO_Scribing_Gamepad:GetSelectedCraftedAbilityData()
    return SCRIBING_DATA_MANAGER:GetCraftedAbilityData(self:GetSlottedCraftedAbilityId())
end

function ZO_Scribing_Gamepad:OnStateChanged(_, newState)
    ZO_ScribingLayout_Gamepad.OnStateChanged(self, _, newState)
    if newState == SCENE_SHOWING then
        self:RefreshSlots()
    end
end

function ZO_Scribing_Gamepad:OnSelectionChanged(list, selectedData, previousData)
    ZO_ScribingLayout_Gamepad.OnSelectionChanged(self, list, selectedData, previousData)

    if self:IsCurrentList(self.recentCraftedAbilitiesList) then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)

        local recentCraftedAbility = selectedData and selectedData.data
        if recentCraftedAbility then
            local craftedAbilityId, recentPrimaryScriptId, recentSecondaryScriptId, recentTertiaryScriptId = unpack(recentCraftedAbility)
            local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
            local activePrimaryScriptId, activeSecondaryScriptId, activeTertiaryScriptId = craftedAbilityData:GetActiveScriptIds()
            -- Just in case something goes wrong with getting the final ability and we have to fallback to the scripts themselves
            local OPTIONS = { displayFlags = SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_SELECTED_SCRIPTS }
            GAMEPAD_TOOLTIPS:LayoutCraftedAbilityByIds(GAMEPAD_LEFT_TOOLTIP, craftedAbilityId, recentPrimaryScriptId, recentSecondaryScriptId, recentTertiaryScriptId, OPTIONS)
            GAMEPAD_TOOLTIPS:LayoutCraftedAbilityByIds(GAMEPAD_RIGHT_TOOLTIP, craftedAbilityId, activePrimaryScriptId, activeSecondaryScriptId, activeTertiaryScriptId, OPTIONS)
        end
    end

    if self:IsCurrentList(self.craftedAbilityList) then
        if (selectedData and selectedData.isRecentCraftedAbilitiesEntry) or self:IsHeaderActive() then
            self.slotsContainer:SetHidden(true)
            self.scribingSelectInkContainer:SetHidden(true)
        else
            self.slotsContainer:SetHidden(false)
            self.scribingSelectInkContainer:SetHidden(false)
        end
    end
end

function ZO_Scribing_Gamepad:LayoutTooltipForScriptData(scriptData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    if scriptData then
        -- Choosing some scripts can possibly alter the description of this script
        local primaryScriptId, secondaryScriptId, tertiaryScriptId = self:GetSlottedScriptIds()
        local primaryScriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(primaryScriptId)
        local secondaryScriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(secondaryScriptId)
        local tertiaryScriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(tertiaryScriptId)
        local displayFlags = SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_ACQUIRE_HINT + SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_ERRORS
        if not self:IsScriptDataCompatible(self:GetSlottedCraftedAbilityId(), scriptData) then
            displayFlags = ZO_FlagHelpers.SetMaskFlag(displayFlags, SCRIBING_TOOLTIP_DISPLAY_FLAGS_SCRIPT_COMPATIBILITY_ERROR)
        end
        local OPTIONS = { displayFlags = displayFlags }
        GAMEPAD_TOOLTIPS:LayoutCraftedAbilityScript(GAMEPAD_LEFT_TOOLTIP, self:GetSelectedCraftedAbilityData(), scriptData, primaryScriptData, secondaryScriptData, tertiaryScriptData, OPTIONS)

        self:UpdateResultTooltip()
    end
end

function ZO_Scribing_Gamepad:PerformUpdate()
    ZO_ScribingLayout_Gamepad.PerformUpdate(self)

    if self:IsCurrentList(self.recentCraftedAbilitiesList) then
        local RESET_TO_TOP = true
        self:RefreshRecentCraftedAbilitiesList(RESET_TO_TOP)
    end
end

-- End Overridden from ZO_ScribingLayout_Gamepad

function ZO_Scribing_Gamepad:RefreshHeader()
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_Scribing_Gamepad:ShowRecentCraftedAbilitiesList()
    self:SetCurrentList(self.recentCraftedAbilitiesList)
    self:SetSearchCriteria(BACKGROUND_LIST_FILTER_TARGET_CRAFTED_ABILITY_COMBINATION, "scribedCraftedAbilityTextSearch")

    local RESET_TO_TOP = true
    self:RefreshRecentCraftedAbilitiesList(RESET_TO_TOP)
    self:RefreshHeader()

    self.slotsContainer:SetHidden(true)
    self.scribingSelectInkContainer:SetHidden(true)
end

function ZO_Scribing_Gamepad:RefreshRecentCraftedAbilitiesList(resetToTop)
    self.recentCraftedAbilitiesList:Clear()

    local recentCraftedAbilities = self:GetRecentCraftedAbilities()
    for i = #recentCraftedAbilities, 1, -1 do
        local recentCraftedAbility = recentCraftedAbilities[i]
        if self:IsDataInSearchTextResults(recentCraftedAbility) then
            local craftedAbilityId = recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.CRAFTED_ABILITY]
            local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
            if craftedAbilityData and not craftedAbilityData:IsDisabled() then
                local primaryScriptId = recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.PRIMARY_SCRIPT]
                local secondaryScriptId = recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.SECONDARY_SCRIPT]
                local tertiaryScriptId = recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.TERTIARY_SCRIPT]
                local activePrimaryScriptId, activeSecondaryScriptId, activeTertiaryScriptId = craftedAbilityData:GetActiveScriptIds()

                craftedAbilityData:SetScriptIdSelectionOverride(primaryScriptId, secondaryScriptId, tertiaryScriptId)

                if not (primaryScriptId == activePrimaryScriptId
                    and secondaryScriptId == activeSecondaryScriptId
                    and tertiaryScriptId == activeTertiaryScriptId) then

                    local representativeAbilityId = craftedAbilityData:GetRepresentativeAbilityId()
                    local abilityName = ZO_CachedStrFormat(SI_ABILITY_NAME, GetAbilityName(representativeAbilityId))
                    local entryData = ZO_GamepadEntryData:New(abilityName, craftedAbilityData:GetIcon())
                    entryData.data = recentCraftedAbility
                    entryData:SetIconTintOnSelection(true)
                    self.recentCraftedAbilitiesList:AddEntry("ZO_GamepadSubMenuEntryTemplateWithStatus", entryData)
                end
            end
        end
    end

    self.recentCraftedAbilitiesList:Commit(resetToTop)

    self:RefreshSlots()
end

function ZO_Scribing_Gamepad:SelectScript()
    if self:IsCurrentList(self.scriptsList) then
        local entryData = self:GetCurrentList():GetTargetData()
        if entryData and entryData.data then
            local scriptId = entryData.data:GetId()
            self:SelectScriptId(scriptId)
        end
    end
end

function ZO_Scribing_Gamepad:SelectRecentCraftedAbility()
    if self:IsCurrentList(self.recentCraftedAbilitiesList) then
        local entryData = self:GetCurrentList():GetTargetData()
        if entryData and entryData.data then
            self:SelectRecentCraftedAbilityData(entryData.data)
        end
    end
end

function ZO_Scribing_Gamepad.OnControlInitialized(control)
    SCRIBING_GAMEPAD = ZO_Scribing_Gamepad:New(control)
end
