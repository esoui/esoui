ZO_SCRIBING_RECENT_CRAFTED_ABILITY_ENTRY_HEIGHT_KEYBOARD = 52

ZO_SCRIBING_KEYBOARD_MODE_SCRIBING = 1
ZO_SCRIBING_KEYBOARD_MODE_RECENT = 2

local RECENT_ABILITIES_LIST_ABILITY_ENTRY_ID = 1

ZO_Scribing_Keyboard = ZO_Object.MultiSubclass(ZO_Scribing_Shared, ZO_ScribingLayout_Keyboard)

function ZO_Scribing_Keyboard:Initialize(control)
    local interactSceneName = "scribingKeyboard"
    ZO_Scribing_Shared.Initialize(self, control, interactSceneName)
    ZO_ScribingLayout_Keyboard.Initialize(self, control)

    SCRIBING_SCENE_KEYBOARD = self.interactScene
    SCRIBING_FRAGMENT_KEYBOARD = ZO_FadeSceneFragment:New(control)
    SCRIBING_SCENE_KEYBOARD:AddFragment(SCRIBING_FRAGMENT_KEYBOARD)

    SYSTEMS:RegisterKeyboardRootScene("scribing", SCRIBING_SCENE_KEYBOARD)
end

-- Overridden from ZO_Scribing_Shared

function ZO_Scribing_Keyboard:InitializeEvents()
    ZO_Scribing_Shared.InitializeEvents(self)

    local function HandleCursorPickup(eventCode, cursorType, ...)
        if not (self:IsShowing() and self.mode == ZO_SCRIBING_KEYBOARD_MODE_SCRIBING) then
            return
        end
        if cursorType == MOUSE_CONTENT_CRAFTED_ABILITY then
            local craftedAbilityId = ...
            self:ShowSlotDropCalloutsForCraftedAbility(craftedAbilityId)
        elseif cursorType == MOUSE_CONTENT_CRAFTED_ABILITY_SCRIPT then
            local craftedAbilityScriptId = ...
            self:ShowSlotDropCalloutsForCraftedAbilityScript(craftedAbilityScriptId)
        end
    end

    local function HandleCursorCleared()
        if self:IsShowing() then
            self:HideAllSlotDropCallouts()
        end
    end

    self.control:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
    self.control:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorCleared)
end

function ZO_Scribing_Keyboard:OnDeferredInitialize()
    self:PerformDeferredInitialization()
    self:InitializeRecentScribesList()
    self:InitializeModeBar()

    ZO_Scribing_Shared.OnDeferredInitialize(self)
end

function ZO_Scribing_Keyboard:InitializeSlots()
    ZO_Scribing_Shared.InitializeSlots(self)

    self.scribedSearchContainer = self.control:GetNamedChild("RecentSearch")
    self.scribedSearchEditBox = self.scribedSearchContainer:GetNamedChild("Box")
    self.slotsInkCostLabel = self.slotsContainer:GetNamedChild("InkCost")
    self.resultTooltip = self.control:GetNamedChild("ResultTooltip")

    local craftedAbilitySlot = self.slotsContainer:GetNamedChild("CraftedAbilitySlot")
    local slotIcon = "EsoUI/Art/Skills/scribing_grimoire_slot.dds"
    local slotIconDrag = "EsoUI/Art/Skills/scribing_grimoire_dragging.dds"
    local slotIconNegative = "EsoUI/Art/Skills/scribing_grimoire_negative.dds"
    local soundPlaced = SOUNDS.SCRIBING_CRAFTED_ABILITY_PLACED
    local soundRemoved = SOUNDS.SCRIBING_CRAFTED_ABILITY_REMOVED
    local craftedAbilitySlot = ZO_SharedCraftedAbilitySlot:New(self, craftedAbilitySlot, slotIcon, slotIconDrag, slotIconNegative, soundPlaced, soundRemoved)
    self:SetCraftedAbilitySlot(craftedAbilitySlot)

    local primaryScriptSlotControl = self.slotsContainer:GetNamedChild("PrimarySlot")
    slotIcon = "EsoUI/Art/Skills/scribing_primary_slot.dds"
    slotIconDrag = "EsoUI/Art/Skills/scribing_primary_dragging.dds"
    slotIconNegative = "EsoUI/Art/Skills/scribing_primary_negative.dds"
    soundPlaced = SOUNDS.SCRIBING_PRIMARY_SCRIPT_PLACED
    soundRemoved = SOUNDS.SCRIBING_PRIMARY_SCRIPT_REMOVED
    local slotType = SCRIBING_SLOT_PRIMARY
    local slotObject = ZO_SharedCraftedAbilityScriptSlot:New(self, primaryScriptSlotControl, slotIcon, slotIconDrag, slotIconNegative, soundPlaced, soundRemoved, slotType)
    self:AddScriptSlot(slotType, slotObject)

    local secondaryScriptSlotControl = self.slotsContainer:GetNamedChild("SecondarySlot")
    slotIcon = "EsoUI/Art/Skills/scribing_secondary_slot.dds"
    slotIconDrag = "EsoUI/Art/Skills/scribing_secondary_dragging.dds"
    slotIconNegative = "EsoUI/Art/Skills/scribing_secondary_negative.dds"
    soundPlaced = SOUNDS.SCRIBING_SECONDARY_SCRIPT_PLACED
    soundRemoved = SOUNDS.SCRIBING_SECONDARY_SCRIPT_REMOVED
    slotType = SCRIBING_SLOT_SECONDARY
    slotObject = ZO_SharedCraftedAbilityScriptSlot:New(self, secondaryScriptSlotControl, slotIcon, slotIconDrag, slotIconNegative, soundPlaced, soundRemoved, slotType)
    self:AddScriptSlot(slotType, slotObject)

    local tertiaryScriptSlotControl = self.slotsContainer:GetNamedChild("TertiarySlot")
    slotIcon = "EsoUI/Art/Skills/scribing_tertiary_slot.dds"
    slotIconDrag = "EsoUI/Art/Skills/scribing_tertiary_dragging.dds"
    slotIconNegative = "EsoUI/Art/Skills/scribing_tertiary_negative.dds"
    soundPlaced = SOUNDS.SCRIBING_TERTIARY_SCRIPT_PLACED
    soundRemoved = SOUNDS.SCRIBING_TERTIARY_SCRIPT_REMOVED
    slotType = SCRIBING_SLOT_TERTIARY
    slotObject = ZO_SharedCraftedAbilityScriptSlot:New(self, tertiaryScriptSlotControl, slotIcon, slotIconDrag, slotIconNegative, soundPlaced, soundRemoved, slotType)
    self:AddScriptSlot(slotType, slotObject)
end

function ZO_Scribing_Keyboard:InitializeFilters()
    ZO_Scribing_Shared.InitializeFilters(self)

    self.usableFilterCheckButton = self.libraryContainer:GetNamedChild("IsUsableCheckbox")
    ZO_CheckButton_SetCheckState(self.usableFilterCheckButton, self.scriptFilters.isUsable)

    local function OnFilterChanged()
        self.scriptFilters.isUsable = ZO_CheckButton_IsChecked(self.usableFilterCheckButton)
        self:RefreshScriptsList()
    end

    ZO_CheckButton_SetToggleFunction(self.usableFilterCheckButton, OnFilterChanged)
    ZO_CheckButton_SetLabelText(self.usableFilterCheckButton, GetString(SI_SCRIBING_FILTER_USABLE))
end

function ZO_Scribing_Keyboard:InitializeRecentScribesList()
    self.recentContainer = self.control:GetNamedChild("Recent")
    self.recentScribedAbilitiesList = self.recentContainer:GetNamedChild("ScribedAbilities")

    local function RecentCraftedAbilitySetup(control, data)
        control.owner = self
        local nameLabel = control:GetNamedChild("Name")
        nameLabel:SetText(data.name)

        local iconControl = control:GetNamedChild("Icon")
        iconControl:SetTexture(data.icon)
    end

    ZO_ScrollList_AddDataType(self.recentScribedAbilitiesList, RECENT_ABILITIES_LIST_ABILITY_ENTRY_ID, "ZO_Scribing_RecentCraftedAbilityRow_Keyboard", ZO_SCRIBING_RECENT_CRAFTED_ABILITY_ENTRY_HEIGHT_KEYBOARD, RecentCraftedAbilitySetup)

    ZO_ScrollList_EnableHighlight(self.recentScribedAbilitiesList, "ZO_ThinListHighlight")
end

function ZO_Scribing_Keyboard:InitializeModeBar()
    self.mode = nil
    self.modeMenu = self.control:GetNamedChild("ModeMenu")
    self.modeBar = self.modeMenu:GetNamedChild("Bar")
    self.modeBarLabel = self.modeBar:GetNamedChild("Label")

    self.scribingTab =
    {
        categoryName = SI_SCRIBING_TITLE,

        descriptor = ZO_SCRIBING_KEYBOARD_MODE_SCRIBING,
        normal = "EsoUI/Art/Crafting/scribing_tabIcon_scribing_up.dds",
        pressed = "EsoUI/Art/Crafting/scribing_tabIcon_scribing_down.dds",
        highlight = "EsoUI/Art/Crafting/scribing_tabIcon_scribing_over.dds",
        disabled = "EsoUI/Art/Crafting/scribing_tabIcon_scribing_disabled.dds",
        callback = function(tabData)
            self.modeBarLabel:SetText(GetString(SI_SCRIBING_TITLE))
            self:SetMode(ZO_SCRIBING_KEYBOARD_MODE_SCRIBING)
        end,
    }

    local function LayoutRecentScribesTabTooltip(tooltip)
        SetTooltipText(tooltip, zo_strformat(SI_MENU_BAR_TOOLTIP, GetString(SI_SCRIBING_RECENT_TITLE)))
        if not SCRIBING_MANAGER:HasAnyUnscribedRecentCraftedAbilities() then
            tooltip:AddLine(GetString(SI_SCRIBING_RECENT_CRAFTED_ABILITIES_TAB_DISABLED_TOOLTIP_TEXT))
        end
    end

    self.recentScribesTab =
    {
        categoryName = SI_SCRIBING_RECENT_TITLE,

        descriptor = ZO_SCRIBING_KEYBOARD_MODE_RECENT,
        normal = "EsoUI/Art/Crafting/scribing_tabIcon_recent_up.dds",
        pressed = "EsoUI/Art/Crafting/scribing_tabIcon_recent_down.dds",
        highlight = "EsoUI/Art/Crafting/scribing_tabIcon_recent_over.dds",
        disabled = "EsoUI/Art/Crafting/scribing_tabIcon_recent_disabled.dds",
        alwaysShowTooltip = true,
        CustomTooltipFunction = LayoutRecentScribesTabTooltip,
        callback = function(tabData)
            self.modeBarLabel:SetText(GetString(SI_SCRIBING_RECENT_TITLE))
            self:SetMode(ZO_SCRIBING_KEYBOARD_MODE_RECENT)
        end,
    }

    ZO_CraftingUtils_ConnectMenuBarToCraftingProcess(self.modeBar)

    self.scribingTabButton = ZO_MenuBar_AddButton(self.modeBar, self.scribingTab)
    self.recentScribesButton = ZO_MenuBar_AddButton(self.modeBar, self.recentScribesTab)

    self:RefreshModeBar()
end

function ZO_Scribing_Keyboard:RefreshModeBar()
    local hasAnyRecentCraftedAbilities = SCRIBING_MANAGER:HasAnyUnscribedRecentCraftedAbilities()
    ZO_MenuBar_SetDescriptorEnabled(self.modeBar, ZO_SCRIBING_KEYBOARD_MODE_RECENT, hasAnyRecentCraftedAbilities)
end

function ZO_Scribing_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
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
            enabled = function()
                if self:AreScriptsShowing() then
                    return not ZO_CraftingUtils_IsPerformingCraftProcess()
                end

                return true
            end,
        },
        -- Perform action
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            alignment = function()
                if self:HasMouseOverRecentCraftedAbilityEntry() or self:HasMouseOverCraftedAbilityEntry() then
                    return KEYBIND_STRIP_ALIGN_RIGHT
                else
                    return KEYBIND_STRIP_ALIGN_CENTER
                end
            end,
            name = function()
                if self:HasMouseOverCraftedAbilityEntry() then
                    return GetString(SI_SCRIBING_LIBRARY_SELECT_GRIMOIRE)
                elseif self:HasMouseOverScriptRow() then
                    local scriptData = ZO_ScrollList_GetData(self:GetMouseOverScriptRow())
                    if self:IsScriptDataSlotted(scriptData) then
                        return GetString(SI_ITEM_ACTION_REMOVE_FROM_CRAFT)
                    else
                        return GetString(SI_ITEM_ACTION_ADD_TO_CRAFT)
                    end
                elseif self:HasMouseOverRecentCraftedAbilityEntry() then
                    return GetString(SI_ITEM_ACTION_SELECT)
                end
            end,
            callback = function()
                if self:HasMouseOverCraftedAbilityEntry() then
                    local craftedAbilityData = self:GetMouseOverCraftedAbilityEntry().dataEntry.data
                    local craftedAbilityId = craftedAbilityData:GetId()
                    self:SelectCraftedAbilityId(craftedAbilityId)
                elseif self:HasMouseOverScriptRow() then
                    local scriptData = ZO_ScrollList_GetData(self:GetMouseOverScriptRow())
                    local scriptId = scriptData:GetId()
                    self:SelectScriptId(scriptId)
                elseif self:HasMouseOverRecentCraftedAbilityEntry() then
                    local recentCraftedAbilityData = self:GetMouseOverRecentCraftedAbilityEntry().dataEntry.data.recentCraftedAbilityData
                    if recentCraftedAbilityData then
                        self:SelectRecentCraftedAbilityData(recentCraftedAbilityData)
                    end
                end
            end,
            enabled = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
            visible = function()
                if self:HasMouseOverCraftedAbilityEntry() then
                    return true
                elseif self:HasMouseOverScriptRow() then
                    -- scriptData could be nil if the list was redrawn and removes this control while rolled over
                    local scriptData = ZO_ScrollList_GetData(self:GetMouseOverScriptRow())
                    return scriptData ~= nil
                elseif self:HasMouseOverRecentCraftedAbilityEntry() then
                    return true
                end
                return false
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
                return self.mode == ZO_SCRIBING_KEYBOARD_MODE_SCRIBING and not self:AreCraftedAbilitiesShowing()
            end,
        },

        -- Navigate to skills
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(SI_SCRIBING_TO_SKILLS_ACTION),
            callback = function()
                local craftedAbilityData = self:GetMouseOverCraftedAbilityEntry().dataEntry.data
                if craftedAbilityData then
                    MAIN_MENU_KEYBOARD:ShowScene("skills")
                    SKILLS_WINDOW:BrowseToSkill(craftedAbilityData:GetSkillData())
                end
            end,
            enabled = function()
                if self:HasMouseOverCraftedAbilityEntry() then
                    local craftedAbilityData = self:GetMouseOverCraftedAbilityEntry().dataEntry.data
                    return craftedAbilityData:IsSlottedOnHotBar()
                end
                return false
            end,
            visible = function()
                return self:AreCraftedAbilitiesShowing() and self:HasMouseOverCraftedAbilityEntry()
            end,
        },

        -- Clear scripts
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_SCRIBING_CLEAR_SCRIPT_SELECTIONS),
            callback = function()
                self:ClearSelectedScripts()
            end,
            enabled = function()
                return not ZO_CraftingUtils_IsPerformingCraftProcess()
            end,
            visible = function()
                return self:IsAnyScriptSlotted()
            end,
        },
    }

    ZO_CraftingUtils_ConnectKeybindButtonGroupToCraftingProcess(self.keybindStripDescriptor)
end

function ZO_Scribing_Keyboard:OnShowing()
    ZO_Scribing_Shared.OnShowing(self)

    self:HideAllSlotDropCallouts()

    local oldMode = self.mode
    ZO_MenuBar_SelectDescriptor(self.modeBar, ZO_SCRIBING_KEYBOARD_MODE_SCRIBING)

    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

    -- make sure we update the crafted ability list if it was previously showing
    -- since ZO_MenuBar_SelectDescriptor won't do anything if it was already selected
    if oldMode == ZO_SCRIBING_KEYBOARD_MODE_SCRIBING then
        local RESET_TO_TOP = true
        self:ShowCraftedAbilities(RESET_TO_TOP)
    end

    self:ActivateTextSearch()
end

function ZO_Scribing_Keyboard:OnShown()
    ZO_Scribing_Shared.OnShow(self)

    CRAFTING_RESULTS:SetCraftingTooltip(self.resultTooltip)
    CRAFTING_RESULTS:SetTooltipAnimationSounds(SOUNDS.SCRIBING_SCRIBE_TOOLTIP_GLOW)
end

function ZO_Scribing_Keyboard:OnHiding()
    ZO_Scribing_Shared.OnHiding(self)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RestoreDefaultExit()

    self:ClearMouseOverState()

    self:DeactivateTextSearch()

    CRAFTING_RESULTS:SetCraftingTooltip(nil)
end

function ZO_Scribing_Keyboard:OnScribeComplete()
    ZO_Scribing_Shared.OnScribeComplete(self)

    self:RefreshModeBar()
end

function ZO_Scribing_Keyboard:ShowCraftedAbilities(resetToTop)
    self:ClearCurrentScribingSelection()

    ZO_ScribingLayout_Keyboard.ShowCraftedAbilities(self, resetToTop)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Scribing_Keyboard:RefreshCraftedAbilityList(resetToTop)
    if self.mode == ZO_SCRIBING_KEYBOARD_MODE_SCRIBING then
        ZO_Scribing_Shared.RefreshCraftedAbilityList(self, resetToTop)

        ZO_ScribingLayout_Keyboard.RefreshCraftedAbilityList(self, resetToTop)

        self.usableFilterCheckButton:SetHidden(true)
    end
end

function ZO_Scribing_Keyboard:ShowScripts()
    ZO_Scribing_Shared.ShowScripts(self)

    ZO_ScribingLayout_Keyboard.ShowScripts(self)

    self.usableFilterCheckButton:SetHidden(false)
end

function ZO_Scribing_Keyboard:RefreshScriptsList(resetToTop)
    ZO_Scribing_Shared.RefreshScriptsList(self, resetToTop)

    ZO_ScribingLayout_Keyboard.RefreshScriptsList(self, resetToTop)
end

function ZO_Scribing_Keyboard:UpdateInkDisplay()
    ZO_ScribingLayout_Keyboard.UpdateInkDisplay(self)
end

function ZO_Scribing_Keyboard:SlotCraftedAbilityById(craftedAbilityId)
    ZO_Scribing_Shared.SlotCraftedAbilityById(self, craftedAbilityId)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Scribing_Keyboard:UpdateResultTooltip()
    local hasCraftedAbilitySlotted = self:HasCraftedAbilitySlotted()
    self.resultTooltip:SetHidden(not hasCraftedAbilitySlotted)
    if hasCraftedAbilitySlotted then
        self.resultTooltip:ClearLines()
        local primaryScriptId = self:GetScriptIdBySlot(SCRIBING_SLOT_PRIMARY)
        local secondaryScriptId = self:GetScriptIdBySlot(SCRIBING_SLOT_SECONDARY)
        local tertiaryScriptId = self:GetScriptIdBySlot(SCRIBING_SLOT_TERTIARY)
        local DISPLAY_FLAGS = SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_SELECTED_SCRIPTS + SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_ERRORS
        self.resultTooltip:SetCraftedAbility(self:GetSlottedCraftedAbilityId(), primaryScriptId, secondaryScriptId, tertiaryScriptId, DISPLAY_FLAGS)
    end
end

function ZO_Scribing_Keyboard:SlotScriptIdByScriptData(scriptData)
    ZO_Scribing_Shared.SlotScriptIdByScriptData(self, scriptData)
    self:CollapseSlotCategory(scriptData:GetScribingSlot())
end

function ZO_Scribing_Keyboard:ClearScriptIdBySlot(slotType)
    ZO_Scribing_Shared.ClearScriptIdBySlot(self, slotType)
    self:ExpandSlotCategory(slotType)
end

-- End Overridden from ZO_Scribing_Shared

-- Overridden from ZO_ScribingLayout_Keyboard

function ZO_Scribing_Keyboard:OnUpdateSearchResults()
    ZO_ScribingLayout_Keyboard.OnUpdateSearchResults(self)

    local RESET_TO_TOP = true
    self:RefreshRecentCraftedAbilitiesList(RESET_TO_TOP)
end

function ZO_Scribing_Keyboard:GetCraftedAbilityDataList()
    return SCRIBING_DATA_MANAGER:GetSortedBySkillTypeUnlockedCraftedAbilityData()
end

function ZO_Scribing_Keyboard:SetMouseOverCraftedAbilityEntry(...)
    ZO_ScribingLayout_Keyboard.SetMouseOverCraftedAbilityEntry(self, ...)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Scribing_Keyboard:SetMouseOverScriptRow(...)
    ZO_ScribingLayout_Keyboard.SetMouseOverScriptRow(self, ...)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Scribing_Keyboard:SelectCraftedAbilityId(craftedAbilityId)
    ZO_ScribingLayout_Keyboard.SelectCraftedAbilityId(self, craftedAbilityId)
    self:SlotCraftedAbilityById(craftedAbilityId)
end

function ZO_Scribing_Keyboard:SelectScriptId(scriptId)
    ZO_Scribing_Shared.SelectScriptId(self, scriptId)
    ZO_ScribingLayout_Keyboard.SelectScriptId(self, scriptId)
end

function ZO_Scribing_Keyboard:IsDraggingEnabled()
    return not ZO_CraftingUtils_IsPerformingCraftProcess()
end

function ZO_Scribing_Keyboard:ShouldAddScriptToList(currentCraftedAbilityId, scriptId)
    return self:IsScriptIdCompatibleWithFilters(currentCraftedAbilityId, scriptId)
end

function ZO_Scribing_Keyboard:GetIconsForScriptData(scriptData)
    local icons = {}

    if self:IsScriptDataSlotted(scriptData) then
        table.insert(icons, ZO_KEYBOARD_IS_EQUIPPED_ICON)
    end

    local craftedAbilityData = self:GetSelectedCraftedAbilityData()
    if craftedAbilityData:IsScriptActive(scriptData) then
        table.insert(icons, "EsoUI/Art/Crafting/scribing_activeScript_icon.dds")
    end

    if not self:IsScriptDataCompatible(craftedAbilityData:GetId(), scriptData) then
        table.insert(icons, "EsoUI/Art/Inventory/inventory_sell_forbidden_icon.dds")
    end

    return icons
end

function ZO_Scribing_Keyboard:GetSelectedScriptDataForSlot(slotType)
    local slottedScriptId = self:GetScriptIdBySlot(slotType)
    return SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(slottedScriptId)
end

function ZO_Scribing_Keyboard:IsScriptDataCompatible(craftedAbilityId, scriptData)
    local primaryScriptId, secondaryScriptId, tertiaryScriptId = self:GetSlottedScriptIds()
    return scriptData:IsCompatibleWithSelections(craftedAbilityId, primaryScriptId, secondaryScriptId, tertiaryScriptId)
end

function ZO_Scribing_Keyboard:OnBackHeaderControlMouseClick()
    if not ZO_CraftingUtils_IsPerformingCraftProcess() then
        ZO_ScribingLayout_Keyboard.OnBackHeaderControlMouseClick(self)
    end
end

-- End Overridden from ZO_ScribingLayout_Keyboard

function ZO_Scribing_Keyboard:ShowRecentCraftedAbilities()
    self:SetSearchCriteria(BACKGROUND_LIST_FILTER_TARGET_CRAFTED_ABILITY_COMBINATION, "scribedCraftedAbilityTextSearch", self.scribedSearchEditBox)

    local RESET_TO_TOP = true
    self:RefreshRecentCraftedAbilitiesList(RESET_TO_TOP)
end

function ZO_Scribing_Keyboard:RefreshRecentCraftedAbilitiesList(resetToTop)
    if self.mode == ZO_SCRIBING_KEYBOARD_MODE_RECENT then
        local list = self.recentScribedAbilitiesList

        ZO_ScrollList_Clear(list)

        local scrollData = ZO_ScrollList_GetDataList(list)
        local recentCraftedAbilities = self:GetRecentCraftedAbilities()
        for i = #recentCraftedAbilities, 1, -1 do
            local recentCraftedAbility = recentCraftedAbilities[i]
            if self:IsDataInSearchTextResults(recentCraftedAbility) then
                local craftedAbilityId = recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.CRAFTED_ABILITY]
                local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
                if craftedAbilityData and not craftedAbilityData:IsDisabled() then
                    local primaryScriptId, secondaryScriptId, tertiaryScriptId = craftedAbilityData:GetActiveScriptIds()
                    craftedAbilityData:SetScriptIdSelectionOverride(primaryScriptId, secondaryScriptId, tertiaryScriptId)

                    if not (recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.PRIMARY_SCRIPT] == primaryScriptId
                        and recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.SECONDARY_SCRIPT] == secondaryScriptId
                        and recentCraftedAbility[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.TERTIARY_SCRIPT] == tertiaryScriptId) then

                        local representativeAbilityId = craftedAbilityData:GetRepresentativeAbilityId()
                        local entryData =
                        {
                            name = ZO_CachedStrFormat(SI_ABILITY_NAME, GetAbilityName(representativeAbilityId)),
                            icon = craftedAbilityData:GetIcon(),
                            recentCraftedAbilityData = recentCraftedAbility,
                        }

                        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(RECENT_ABILITIES_LIST_ABILITY_ENTRY_ID, entryData))
                    end
                end
            end
        end

        ZO_ScrollList_Commit(list)
    end
end

function ZO_Scribing_Keyboard:SetMode(mode)
    if self.mode ~= mode then
        local oldMode = self.mode
        self.mode = mode

        if oldMode == ZO_SCRIBING_KEYBOARD_MODE_SCRIBING then
            self:ClearCurrentScribingSelection()
        end

        if mode == ZO_SCRIBING_KEYBOARD_MODE_SCRIBING then
            local RESET_TO_TOP = true
            self:ShowCraftedAbilities(RESET_TO_TOP)
        elseif mode == ZO_SCRIBING_KEYBOARD_MODE_RECENT  then
            self:ShowRecentCraftedAbilities()
        end

        local isScribingMode = mode == ZO_SCRIBING_KEYBOARD_MODE_SCRIBING
        self.libraryContainer:SetHidden(not isScribingMode)
        self.slotsContainer:SetHidden(not isScribingMode)

        local isRecentMode = mode == ZO_SCRIBING_KEYBOARD_MODE_RECENT
        self.recentContainer:SetHidden(not isRecentMode)

        ClearCursor()

        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_Scribing_Keyboard:SelectRecentCraftedAbilityData(recentCraftedAbilityData)
    ZO_MenuBar_SelectDescriptor(self.modeBar, ZO_SCRIBING_KEYBOARD_MODE_SCRIBING)

    ZO_Scribing_Shared.SelectRecentCraftedAbilityData(self, recentCraftedAbilityData)
end

-- Crafted Ability Slot

function ZO_Scribing_Keyboard:TrySlotCraftedAbilityFromMouse(control)
    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        return
    end

    local craftedAbilityId = GetCursorCraftedAbilityId()
    ClearCursor()
    if self.craftedAbilitySlot:IsSlotControl(control) then
        self:SelectCraftedAbilityId(craftedAbilityId)
    end
end
function ZO_Scribing_Keyboard:TryPickupCraftedAbilityFromSlot(control)
    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        return
    end

    local slotObject = control.slot
    local craftedAbilityId = slotObject:GetCraftedAbilityId()
    self:SelectCraftedAbilityId(0)
    PickupCraftedAbility(craftedAbilityId)
end

-- Crafted Ability Script Slot

function ZO_Scribing_Keyboard:TrySlotCraftedAbilityScriptFromMouse(control)
    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        return
    end

    local scriptId = GetCursorCraftedAbilityScriptId()
    if scriptId then
        ClearCursor()

        local scriptData = self:GetScriptDataById(scriptId)
        if not scriptData then
            return
        end

        local scribingSlot = scriptData:GetScribingSlot()
        local slotObject = self.scribingSlots[scribingSlot]
        if slotObject and slotObject:IsSlotControl(control) then
            self:SelectScriptId(scriptId, scribingSlot)
        end
    else
        for scribingSlot = SCRIBING_SLOT_ITERATION_BEGIN, SCRIBING_SLOT_ITERATION_END do
            local slotObject = self.scribingSlots[scribingSlot]
            if slotObject and slotObject:IsSlotControl(control) then
                -- This function will unselect if already selected
                self:SelectScriptId(self:GetScriptIdBySlot(scribingSlot), scribingSlot)
            end
        end
    end
end

function ZO_Scribing_Keyboard:TryPickupCraftedAbilityScriptFromSlot(control)
    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        return
    end

    local slotObject = control.slot
    local scriptId = slotObject:GetScriptId()
    if scriptId == nil or scriptId == 0 then
        -- no slotted script, nothing to pick up
        return
    end

    local scriptData = SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(scriptId)
    if internalassert(scriptData ~= nil, "Attempting to pick up invalid script") then
        PickupCraftedAbilityScript(scriptId)
        self:ClearScriptIdBySlot(scriptData:GetScribingSlot(), scriptId)
    end
end

-- Recent Crafted Ability Row

function ZO_Scribing_Keyboard:TrySelectRecentCraftedAbilityFromList(control)
    local entry = ZO_ScrollList_GetData(control)
    local recentCraftedAbilityData = entry.recentCraftedAbilityData
    if recentCraftedAbilityData then
        self:SelectRecentCraftedAbilityData(recentCraftedAbilityData)
    end
end

function ZO_Scribing_Keyboard:OnRecentCraftedAbilityEntryMouseEnter(control)
    self:SetMouseOverRecentCraftedAbilityEntry(control)
    self:ShowRecentCraftedAbilityComparisonTooltip(control)
end

function ZO_Scribing_Keyboard:OnRecentCraftedAbilityEntryMouseExit(control)
    self:SetMouseOverRecentCraftedAbilityEntry(nil)
    self:HideRecentCraftedAbilityComparisonTooltip(control)
end

function ZO_Scribing_Keyboard:SetMouseOverRecentCraftedAbilityEntry(control)
    self.mouseOverRecentCraftedAbilityEntry = control

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_Scribing_Keyboard:GetMouseOverRecentCraftedAbilityEntry()
    return self.mouseOverRecentCraftedAbilityEntry
end

function ZO_Scribing_Keyboard:HasMouseOverRecentCraftedAbilityEntry()
    return self.mouseOverRecentCraftedAbilityEntry ~= nil
end

function ZO_Scribing_Keyboard:ShowRecentCraftedAbilityComparisonTooltip(control)
    local entry = ZO_ScrollList_GetData(control)
    local recentCraftedAbilityData = entry.recentCraftedAbilityData
    if recentCraftedAbilityData then
        local craftedAbilityId = recentCraftedAbilityData[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.CRAFTED_ABILITY]
        local craftedAbilityData = SCRIBING_DATA_MANAGER:GetCraftedAbilityData(craftedAbilityId)
        local recentPrimaryScriptId = recentCraftedAbilityData[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.PRIMARY_SCRIPT]
        local recentSecondaryScriptId = recentCraftedAbilityData[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.SECONDARY_SCRIPT]
        local recentTertiaryScriptId = recentCraftedAbilityData[ZO_RECENT_SCRIBE_SAVED_VAR_INDEX.TERTIARY_SCRIPT]
        local activePrimaryScriptId, activeSecondaryScriptId, activeTertiaryScriptId = craftedAbilityData:GetActiveScriptIds()

        -- Just in case something goes wrong with getting the final ability and we have to fallback to the scripts themselves
        local DISPLAY_FLAGS = SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_SELECTED_SCRIPTS 

        InitializeTooltip(AbilityTooltip, control, RIGHT, 0, 0, LEFT)
        AbilityTooltip:SetCraftedAbility(craftedAbilityId, recentPrimaryScriptId, recentSecondaryScriptId, recentTertiaryScriptId, DISPLAY_FLAGS)

        InitializeTooltip(ComparativeAbilityTooltip1, AbilityTooltip, TOPRIGHT, -5, 0, TOPLEFT)
        ComparativeAbilityTooltip1:SetCraftedAbility(craftedAbilityId, activePrimaryScriptId, activeSecondaryScriptId, activeTertiaryScriptId, DISPLAY_FLAGS)
    end
end

function ZO_Scribing_Keyboard:HideRecentCraftedAbilityComparisonTooltip(control)
    ClearTooltip(AbilityTooltip)
    ClearTooltip(ComparativeAbilityTooltip1)
end

--
-- Functions for XML
--

function ZO_Scribing_Keyboard.OnControlInitialized(control)
    SCRIBING_KEYBOARD = ZO_Scribing_Keyboard:New(control)
end

-- Crafted Ability Slot

function ZO_Scribing_Keyboard.OnCraftedAbilitySlotMouseEnter(control)
    if not SCRIBING_KEYBOARD:IsShowing() then
        return
    end

    local slotObject = control.slot
    local craftedAbilityId = slotObject:GetCraftedAbilityId()
    if craftedAbilityId == nil or craftedAbilityId == 0 then
        InitializeTooltip(InformationTooltip, slotObject.slotIcon, LEFT, 15)
        SetTooltipText(InformationTooltip, GetString(SI_SCRIBING_CRAFTED_ABILITY_SLOT_NAME))
        local DEFAULT_FONT = ""
        InformationTooltip:AddLine(GetString(SI_SCRIBING_CRAFTED_ABILITY_SLOT_DESCRIPTION), DEFAULT_FONT, ZO_NORMAL_TEXT:UnpackRGBA())
    end
end

function ZO_Scribing_Keyboard.OnCraftedAbilitySlotMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_Scribing_Keyboard.OnCraftedAbilitySlotMouseUp(control, button, upInside)
    if not SCRIBING_KEYBOARD:IsShowing() then
        return
    end

    if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
        SCRIBING_KEYBOARD:TrySlotCraftedAbilityFromMouse(control)
    end
end

function ZO_Scribing_Keyboard.OnCraftedAbilitySlotStartDrag(control, button)
    if not SCRIBING_KEYBOARD:IsShowing() then
        return
    end

    if button == MOUSE_BUTTON_INDEX_LEFT then
        SCRIBING_KEYBOARD:TryPickupCraftedAbilityFromSlot(control)
    end
end

function ZO_Scribing_Keyboard.OnCraftedAbilitySlotReceiveDrag(control, button)
    if not SCRIBING_KEYBOARD:IsShowing() then
        return
    end

    if button == MOUSE_BUTTON_INDEX_LEFT then
        SCRIBING_KEYBOARD:TrySlotCraftedAbilityFromMouse(control)
    end
end

-- Crafted Ability Script Slot

function ZO_Scribing_Keyboard.OnCraftedAbilityScriptSlotMouseEnter(control)
    if not SCRIBING_KEYBOARD:IsShowing() then
        return
    end

    local slotObject = control.slot
    local scriptId = slotObject:GetScriptId()
    if scriptId == nil or scriptId == 0 then
        local slotType = slotObject.slotType
        InitializeTooltip(InformationTooltip, slotObject.slotIcon, LEFT, 15)
        SetTooltipText(InformationTooltip, GetString("SI_SCRIBINGSLOT", slotType))
        local DEFAULT_FONT = ""
        InformationTooltip:AddLine(GetString("SI_SCRIBINGSLOT_DESCRIPTION", slotType), DEFAULT_FONT, ZO_NORMAL_TEXT:UnpackRGBA())
    end
end

function ZO_Scribing_Keyboard.OnCraftedAbilityScriptSlotMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_Scribing_Keyboard.OnCraftedAbilityScriptSlotMouseUp(control, button, upInside)
    if not SCRIBING_KEYBOARD:IsShowing() then
        return
    end

    if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
        SCRIBING_KEYBOARD:TrySlotCraftedAbilityScriptFromMouse(control)
    end
end

function ZO_Scribing_Keyboard.OnCraftedAbilityScriptSlotStartDrag(control, button)
    if not SCRIBING_KEYBOARD:IsShowing() then
        return
    end

    if button == MOUSE_BUTTON_INDEX_LEFT then
        SCRIBING_KEYBOARD:TryPickupCraftedAbilityScriptFromSlot(control)
    end
end

function ZO_Scribing_Keyboard.OnCraftedAbilityScriptSlotReceiveDrag(control, button)
    if not SCRIBING_KEYBOARD:IsShowing() then
        return
    end

    if button == MOUSE_BUTTON_INDEX_LEFT then
        SCRIBING_KEYBOARD:TrySlotCraftedAbilityScriptFromMouse(control)
    end
end

-- Recent Crafted Ability Row

function ZO_Scribing_Keyboard.OnMouseEnterRecentCraftedAbility(control)
    if not SCRIBING_KEYBOARD:IsShowing() then
        return
    end

    SCRIBING_KEYBOARD:OnRecentCraftedAbilityEntryMouseEnter(control)
end

function ZO_Scribing_Keyboard.OnMouseExitRecentCraftedAbility(control)
    if not SCRIBING_KEYBOARD:IsShowing() then
        return
    end

    SCRIBING_KEYBOARD:OnRecentCraftedAbilityEntryMouseExit(control)
end

function ZO_Scribing_Keyboard.OnMouseClickRecentCraftedAbility(control, button)
    if not SCRIBING_KEYBOARD:IsShowing() then
        return
    end

    if button == MOUSE_BUTTON_INDEX_LEFT then
        SCRIBING_KEYBOARD:TrySelectRecentCraftedAbilityFromList(control)
    end
end
