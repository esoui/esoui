local ZO_Dyeing = ZO_Object:Subclass()

local SWATCHES_LAYOUT_OPTIONS = {
        padding = 6,
        leftMargin = 27,
        topMargin = 18,
        rightMargin = 0,
        bottomMargin = 0,
        selectionScale = ZO_DYEING_SWATCH_SELECTION_SCALE,
    }

local DYE_ITEM_TAB_FILTER = 1

function ZO_Dyeing:New(...)
    local dyeing = ZO_Object.New(self)
    dyeing:Initialize(...)
    return dyeing
end

function ZO_Dyeing:Initialize(control)
    self.control = control
    self.pane = self.control:GetNamedChild("Pane")
    self.noDyesLabel = self.pane:GetNamedChild("NoDyesLabel")
    self.paneScrollChild = self.control:GetNamedChild("Pane"):GetNamedChild("ScrollChild")
    self.sharedHighlight = self.control:GetNamedChild("SharedHighlight")
    self.sharedHighlight:SetParent(self.paneScrollChild)

    self.savedSetInterpolator = ZO_SimpleControlScaleInterpolator:New(.9, 1.0)

    self:InitializeTabs()
    self:InitializeSortsAndFilters()
    self:InitializeTools()
    self:InitializeSavedSets()
    self:InitializeSwatchPool()
    self:InitializeHeaderPool()
    self:InitializeEquipmentSheet()
    self:InitializeKeybindStripDescriptors()

    local function OnBlockingSceneActivated()
        self:AttemptExit()
    end

    DYEING_SCENE = ZO_InteractScene:New("dyeing", SCENE_MANAGER, ZO_DYEING_STATION_INTERACTION)
    SYSTEMS:RegisterKeyboardRootScene("dyeing", DYEING_SCENE)
    DYEING_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            MAIN_MENU_MANAGER:SetBlockingScene("dyeing", OnBlockingSceneActivated)
            TriggerTutorial(TUTORIAL_TRIGGER_DYEING_OPENED)

            ZO_Dyeing_CopyExistingDyesToPending()


            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

            if self.dyeLayoutDirty then
                self:LayoutDyes()
            end
            self:RefreshSavedSets()

            self.equipmentSheet:MarkViewDirty()

            if not ZO_MenuBar_GetSelectedDescriptor(self.toolsTabs) then
                self.suppressSounds = true
                ZO_MenuBar_SelectDescriptor(self.toolsTabs, self.dyeTool)
                self.suppressSounds = false
            end
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
            MAIN_MENU_MANAGER:ClearBlockingScene(OnBlockingSceneActivated)
        end
    end)

    self.control:RegisterForEvent(EVENT_UNLOCKED_DYES_UPDATED, function() self:DirtyDyeLayout() end)

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "Dyeing", ZO_DYEING_SAVED_VARIABLES_DEFAULTS)

            ZO_CheckButton_SetCheckState(self.showLockedCheckBox, self.savedVars.showLocked)
            self.sortDropDown:SelectItem(self.savedVars.sortStyle == ZO_DYEING_SORT_STYLE_RARITY and self.sortByRarityEntry or self.sortByHueEntry)

            self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        end
    end

    self.control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    self:DirtyDyeLayout()
end

function ZO_Dyeing:OnTabFilterChanged(tabData)
    self.activeTab:SetText(GetString(tabData.activeTabText))
    -- just one tab for now, nothing to do
end

function ZO_Dyeing:InitializeTabs()
    local function GenerateTab(name, filterType, normal, pressed, highlight, disabled)
        return {
            activeTabText = name,
            categoryName = name,

            descriptor = filterType,
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            disabled = disabled,
            callback = function(tabData) self:OnTabFilterChanged(tabData) end,
        }
    end

    self.tabs = self.control:GetNamedChild("Tabs")
    self.activeTab = self.control:GetNamedChild("TabsLabel")

    ZO_MenuBar_AddButton(self.tabs, GenerateTab(SI_DYEING_DYE_ITEM_TAB, DYE_ITEM_TAB_FILTER, "EsoUI/Art/Dye/dyes_tabIcon_dye_up.dds", "EsoUI/Art/Dye/dyes_tabIcon_dye_down.dds", "EsoUI/Art/Dye/dyes_tabIcon_dye_over.dds", "EsoUI/Art/Dye/dyes_tabIcon_dye_disabled.dds"))

    ZO_MenuBar_SelectDescriptor(self.tabs, DYE_ITEM_TAB_FILTER)
end

function ZO_Dyeing:OnToolChanged(tool)
    local mousedOverEquipSlot, mousedOverDyeChannel = self.equipmentSheet:GetMousedOverEquipInfo()
    local mousedOverSavedSetIndex
    if not mousedOverEquipSlot then
        mousedOverSavedSetIndex, mousedOverDyeChannel = self:GetMousedOverSavedSetInfo()
    end

    local lastTool = self.activeTool
    if self.activeTool then
        if mousedOverEquipSlot and mousedOverDyeChannel then
            self:OnEquipmentDyeSlotExit(mousedOverEquipSlot, mousedOverDyeChannel)
        elseif mousedOverSavedSetIndex and mousedOverDyeChannel then
            self:OnSavedSetDyeSlotExit(mousedOverSavedSetIndex, mousedOverDyeChannel)
        end
        self.activeTool:Deactivate(self.suppressSounds)
    end

    self.activeTool = tool

    if self.activeTool then
        self.activeTool:Activate(lastTool, self.suppressSounds)

        if mousedOverEquipSlot and mousedOverDyeChannel then
            self:OnEquipmentDyeSlotEnter(mousedOverEquipSlot, mousedOverDyeChannel)
        elseif mousedOverSavedSetIndex and mousedOverDyeChannel then
            self:OnSavedSetDyeSlotEnter(mousedOverSavedSetIndex, mousedOverDyeChannel)
        end

        if self.activeTool:HasSwatchSelection() then
            local TOOL_CHANGE = true
            self:SetSelectedDyeIndex(self.selectedDyeIndex or self.lastSelectedDyeIndex or self.unlockedDyeIndices[1], nil, TOOL_CHANGE)
        else
            self:SetSelectedDyeIndex(nil)
        end

        if self.activeTool:HasSavedSetSelection() then
            self:SetSelectedSavedSetIndex(self.selectedSavedSetIndex or self.lastSelectedSavedSetIndex)
        else
            self:SetSelectedSavedSetIndex(nil)
        end
    end
end

function ZO_Dyeing:InitializeTools()
    local function GenerateTab(tool, tooltip, normal, pressed, highlight, disabled)
        return {
            descriptor = tool,
            tooltip = tooltip,

            normal = normal,
            pressed = pressed,
            highlight = highlight,
            disabled = disabled,
            callback = function(tabData) self:OnToolChanged(tool) end,
        }
    end

    self.toolsTabs = self.control:GetNamedChild("Tools")

    self.dyeTool = ZO_DyeingToolDye:New(self)
    self.fillTool = ZO_DyeingToolFill:New(self)
    self.eraseTool = ZO_DyeingToolErase:New(self)
    self.sampleTool = ZO_DyeingToolSample:New(self)
    self.setFillTool = ZO_DyeingToolSetFill:New(self)

    ZO_MenuBar_AddButton(self.toolsTabs, GenerateTab(self.dyeTool, SI_DYEING_TOOL_DYE_TOOLTIP, "EsoUI/Art/Dye/dyes_toolIcon_paint_up.dds", "EsoUI/Art/Dye/dyes_toolIcon_paint_down.dds", "EsoUI/Art/Dye/dyes_toolIcon_paint_over.dds"))
    ZO_MenuBar_AddButton(self.toolsTabs, GenerateTab(self.fillTool, SI_DYEING_TOOL_DYE_ALL_TOOLTIP, "EsoUI/Art/Dye/dyes_toolIcon_fill_up.dds", "EsoUI/Art/Dye/dyes_toolIcon_fill_down.dds", "EsoUI/Art/Dye/dyes_toolIcon_fill_over.dds"))
    ZO_MenuBar_AddButton(self.toolsTabs, GenerateTab(self.eraseTool, SI_DYEING_TOOL_ERASE_TOOLTIP, "EsoUI/Art/Dye/dyes_toolIcon_erase_up.dds", "EsoUI/Art/Dye/dyes_toolIcon_erase_down.dds", "EsoUI/Art/Dye/dyes_toolIcon_erase_over.dds"))
    ZO_MenuBar_AddButton(self.toolsTabs, GenerateTab(self.sampleTool, SI_DYEING_TOOL_SAMPLE_TOOLTIP, "EsoUI/Art/Dye/dyes_toolIcon_sample_up.dds", "EsoUI/Art/Dye/dyes_toolIcon_sample_down.dds", "EsoUI/Art/Dye/dyes_toolIcon_sample_over.dds"))
    ZO_MenuBar_AddButton(self.toolsTabs, GenerateTab(self.setFillTool, SI_DYEING_TOOL_SET_FILL, "EsoUI/Art/Dye/dyes_toolIcon_setFill_up.dds", "EsoUI/Art/Dye/dyes_toolIcon_setFill_down.dds", "EsoUI/Art/Dye/dyes_toolIcon_setFill_over.dds"))

    ZO_MenuBar_ClearClickSound(self.toolsTabs)
end

local SKIP_ANIM = true
function ZO_Dyeing:InitializeSavedSets()
    local function UpdateSelectedState(savedSet)
        if savedSet.mousedOver or savedSet.selected then
            self.savedSetInterpolator:ScaleUp(savedSet)
        else
            self.savedSetInterpolator:ScaleDown(savedSet)
        end
    end

    local function SetSelected(savedSet, selected)
        if savedSet.selected ~= selected then
            for i, control in ipairs(savedSet.dyeControls) do
                control.highlightTexture:SetHidden(not selected)
            end
            savedSet.selected = selected
            savedSet:UpdateSelectedState()
        end
    end

    local function OnMouseEnter(savedSet)
        savedSet.mousedOver = true
        savedSet:UpdateSelectedState()
    end

    local function OnMouseExit(savedSet)
        savedSet.mousedOver = false
        savedSet:UpdateSelectedState()
    end

    self.savedSets = {}
    self.lastSelectedSavedSetIndex = 1

    local header = self.control:GetNamedChild("SavedSetsHeader")
    for dyeSetIndex = 1, GetNumSavedDyeSets() do
        local savedSetSwatch = CreateControlFromVirtual("$(parent)SavedSet", self.control, "ZO_DyeingSwatchSlotDyes", dyeSetIndex)

        savedSetSwatch.SetSelected = SetSelected
        savedSetSwatch.UpdateSelectedState = UpdateSelectedState
        savedSetSwatch.OnMouseEnter = OnMouseEnter
        savedSetSwatch.OnMouseExit = OnMouseExit
        self.savedSetInterpolator:ResetToMin(savedSetSwatch)

        for dyeChannel, dyeControl in ipairs(savedSetSwatch.dyeControls) do
            dyeControl.frameTexture:SetPixelRoundingEnabled(false)
            dyeControl.swatchTexture:SetPixelRoundingEnabled(false)
            dyeControl.highlightTexture:SetPixelRoundingEnabled(false)

            dyeControl:SetHandler("OnMouseUp", function(dyeControl, button, upInside)
                if upInside then
                    self:OnSavedSetDyeSlotClicked(dyeSetIndex, dyeChannel, button)
                end
            end)

            dyeControl:SetHandler("OnMouseEnter", function(dyeControl)
                self.mousedOverSavedSetIndex = dyeSetIndex
                self.mousedOverSavedSetDyeChannel = dyeChannel
                self:OnSavedSetDyeSlotEnter(dyeSetIndex, dyeChannel)
            end)

            dyeControl:SetHandler("OnMouseExit", function(dyeControl)
                self.mousedOverSavedSetIndex = nil
                self.mousedOverSavedSetDyeChannel = nil
                self:OnSavedSetDyeSlotExit(dyeSetIndex, dyeChannel)
            end)
        end

        savedSetSwatch:SetAnchor(CENTER, header, BOTTOMLEFT, 47 + 124 * (dyeSetIndex - 1), 37)
        self.savedSets[#self.savedSets + 1] = savedSetSwatch
    end
end

local HIGHLIGHT_DIMENSIONS = 5

function ZO_Dyeing:InitializeSwatchPool()
    local CANNOT_SELECT_LOCKED = false
    self.swatchPool = ZO_Dyeing_InitializeSwatchPool(self, self.sharedHighlight, self.paneScrollChild, "ZO_DyeingSwatch", CANNOT_SELECT_LOCKED, HIGHLIGHT_DIMENSIONS)
end

function ZO_Dyeing:InitializeHeaderPool()
    self.headerPool = ZO_ControlPool:New("ZO_DyeingHeader", self.paneScrollChild)
end

function ZO_Dyeing:InitializeEquipmentSheet()
    local function OnEquipmentDyeSlotClicked(...)
        self:OnEquipmentDyeSlotClicked(...)
    end

    local function OnEquipmentDyeSlotEnter(...)
        self:OnEquipmentDyeSlotEnter(...)
    end

    local function OnEquipmentDyeSlotExit(...)
        self:OnEquipmentDyeSlotExit(...)
    end
    self.equipmentSheet = ZO_DyeingEquipmentSheet:New(self.control:GetNamedChild("EquipmentSheet"), OnEquipmentDyeSlotClicked, OnEquipmentDyeSlotEnter, OnEquipmentDyeSlotExit)
end

function ZO_Dyeing:InitializeSortsAndFilters()
    self.showLockedCheckBox = self.control:GetNamedChild("ShowLocked")

    local function OnFilterChanged(checkButton, isChecked)
        if self.savedVars.showLocked ~= isChecked then
            self.savedVars.showLocked = isChecked
            self:DirtyDyeLayout()
        end
    end

    ZO_CheckButton_SetToggleFunction(self.showLockedCheckBox, OnFilterChanged)
    ZO_CheckButton_SetLabelText(self.showLockedCheckBox, GetString(SI_DYEING_SHOW_LOCKED))
	ZO_CheckButton_SetLabelWrapMode(self.showLockedCheckBox, TEXT_WRAP_MODE_ELLIPSIS, self.control:GetRight() - self.showLockedCheckBox:GetRight())

    local function SetSortStyle(_, _, entry)
        if entry.sortStyleType ~= self.savedVars.sortStyle then
            self.savedVars.sortStyle = entry.sortStyleType
            self:DirtyDyeLayout()
        end
    end

    self.sortDropDown = ZO_ComboBox_ObjectFromContainer(self.control:GetNamedChild("SortBy"))
    self.sortDropDown:SetSortsItems(false)

    self.sortByRarityEntry = ZO_ComboBox:CreateItemEntry(GetString(SI_DYEING_SORT_BY_RARITY), SetSortStyle)
    self.sortByRarityEntry.sortStyleType = ZO_DYEING_SORT_STYLE_RARITY
    self.sortDropDown:AddItem(self.sortByRarityEntry, ZO_COMBOBOX_SUPRESS_UPDATE)

    self.sortByHueEntry = ZO_ComboBox:CreateItemEntry(GetString(SI_DYEING_SORT_BY_HUE), SetSortStyle)
    self.sortByHueEntry.sortStyleType = ZO_DYEING_SORT_STYLE_HUE
    self.sortDropDown:AddItem(self.sortByHueEntry, ZO_COMBOBOX_SUPRESS_UPDATE)

    self.sortDropDown:UpdateItems()
end

function ZO_Dyeing:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Apply dye
        {
            name = GetString(SI_DYEING_COMMIT),
            keybind = "UI_SHORTCUT_SECONDARY",

            visible = ZO_Dyeing_AreTherePendingDyes,
            callback = function() self:CommitSelection() end,
        },

        -- Uniform Randomize
        {
            name = GetString(SI_DYEING_RANDOMIZE),
            keybind = "UI_SHORTCUT_TERTIARY",

            callback = function() self:UniformRandomize() end,
        },

        -- Undo
        {
            name = GetString(SI_DYEING_UNDO),
            keybind = "UI_SHORTCUT_NEGATIVE",
            visible = ZO_Dyeing_AreTherePendingDyes,
            callback = function() self:UndoPendingChanges() end,
        },

        -- Special exit button
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_EXIT_BUTTON),
            keybind = "UI_SHORTCUT_EXIT",
            callback = function() self:AttemptExit() end,
        },
    }
end

function ZO_Dyeing:DirtyDyeLayout()
    if SCENE_MANAGER:IsShowing("dyeing") then
        self:LayoutDyes()
    else
        self.dyeLayoutDirty = true
    end
end

function ZO_Dyeing:OnEquipmentDyeSlotClicked(equipSlot, dyeChannel, button)
    if self.activeTool then
        self.activeTool:OnEquipSlotClicked(equipSlot, dyeChannel, button)
    end
end

function ZO_Dyeing:OnEquipmentDyeSlotEnter(equipSlot, dyeChannel)
    if self.activeTool then
        local highlightSlot, highlightDyeChannel = self.activeTool:GetHighlightRules(equipSlot, dyeChannel)
        self.equipmentSheet:ToggleEquipSlotHightlight(highlightSlot, true, highlightDyeChannel)
        WINDOW_MANAGER:SetMouseCursor(self.activeTool:GetCursorType(equipSlot, dyeChannel))
    end
    local swatch = self.dyeIndexToSwatch[select(dyeChannel, GetPendingEquippedItemDye(equipSlot))]
    ZO_Dyeing_CreateTooltipOnMouseEnter(swatch)
end

function ZO_Dyeing:OnEquipmentDyeSlotExit(equipSlot, dyeChannel)
    self.equipmentSheet:ToggleEquipSlotHightlight(nil, false, nil)
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
    ZO_Dyeing_ClearTooltipOnMouseExit()
end

function ZO_Dyeing:OnSavedSetDyeSlotClicked(dyeSetIndex, dyeChannel, button)
    if self.activeTool then
        self.activeTool:OnSavedSetClicked(dyeSetIndex, dyeChannel, button)
    end
end

function ZO_Dyeing:OnSavedSetDyeSlotEnter(dyeSetIndex, dyeChannel)
    if self.activeTool then
        if self.activeTool:HasSavedSetSelection() then
            self.savedSets[dyeSetIndex]:OnMouseEnter()
        else
            local highlightSlot, highlightDyeChannel = self.activeTool:GetHighlightRules(dyeSetIndex, dyeChannel)
            self:ToggleSavedSetHightlight(highlightSlot, true, highlightDyeChannel)
            WINDOW_MANAGER:SetMouseCursor(self.activeTool:GetCursorType(dyeSetIndex, dyeChannel))
        end
    end
    local swatch = self.dyeIndexToSwatch[select(dyeChannel, GetSavedDyeSetDyes(dyeSetIndex))]
    ZO_Dyeing_CreateTooltipOnMouseEnter(swatch)
end

function ZO_Dyeing:OnSavedSetDyeSlotExit(dyeSetIndex, dyeChannel)
    if self.activeTool == nil or not self.activeTool:HasSavedSetSelection() then
        self:ToggleSavedSetHightlight(nil, false, nil)
    end
    self.savedSets[dyeSetIndex]:OnMouseExit()
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
    ZO_Dyeing_ClearTooltipOnMouseExit()
end

function ZO_Dyeing:GetSelectedDyeIndex()
    return self.selectedDyeIndex
end

function ZO_Dyeing:GetSelectedSavedSetIndex()
    return self.selectedSavedSetIndex
end

function ZO_Dyeing:GetMousedOverSavedSetInfo()
    return self.mousedOverSavedSetIndex, self.mousedOverSavedSetDyeChannel
end

function ZO_Dyeing:OnPendingDyesChanged(equipSlot)
    if equipSlot then
        self.equipmentSheet:RefreshEquipSlotDyes(equipSlot)
    else
        self.equipmentSheet:MarkViewDirty()
    end

    if SCENE_MANAGER:IsShowing("dyeing") then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_Dyeing:OnSavedSetSlotChanged(dyeSetIndex)
    if dyeSetIndex then
        self:RefreshSavedSet(dyeSetIndex)
    else
        self:RefreshSavedSets()
    end
end

function ZO_Dyeing:AttemptExit(exitingToAchievementId)
    self.exitingToAchievementId = exitingToAchievementId

    if ZO_Dyeing_AreTherePendingDyes() then
        if ZO_Dyeing_AreAllItemsBound() then
            if self.exitingToAchievementId then
                ZO_Dialogs_ShowDialog("EXIT_DYE_UI_TO_ACHIEVEMENT")
            else
                ZO_Dialogs_ShowDialog("EXIT_DYE_UI")
            end
        else
            if self.exitingToAchievementId then
                ZO_Dialogs_ShowDialog("EXIT_DYE_UI_TO_ACHIEVEMENT_BIND")
            else
                ZO_Dialogs_ShowDialog("EXIT_DYE_UI_BIND")
            end
        end
    else
        self:ConfirmExit()
    end
end

function ZO_Dyeing:ConfirmExit(applyChanges)
    if applyChanges then
        self:ConfirmCommitSelection()
        PlaySound(SOUNDS.DYEING_APPLY_CHANGES_FROM_DIALOGUE)
    end
    if self.exitingToAchievementId then
        SYSTEMS:GetObject("achievements"):ShowAchievement(self.exitingToAchievementId)
        self.exitingToAchievementId = nil
    else
        SCENE_MANAGER:ShowBaseScene()
    end
end

function ZO_Dyeing:CommitSelection()
    if ZO_Dyeing_AreAllItemsBound() then
        self:ConfirmCommitSelection()
        PlaySound(SOUNDS.DYEING_APPLY_CHANGES)
    else
        ZO_Dialogs_ShowDialog("CONFIRM_APPLY_DYE")
    end
end

function ZO_Dyeing:ConfirmCommitSelection()
    ApplyPendingDyes()
    ZO_Dyeing_CopyExistingDyesToPending()
    self:OnPendingDyesChanged()
end

function ZO_Dyeing:CancelExitToAchievements()
    self.exitingToAchievementId = nil
end

function ZO_Dyeing:CancelExit()
    MAIN_MENU_MANAGER:CancelBlockingSceneNextScene()
end

function ZO_Dyeing:UniformRandomize()
    ZO_Dyeing_UniformRandomize(function() return self:GetRandomUnlockedDyeIndex() end)
    self:OnPendingDyesChanged()
end

function ZO_Dyeing:GetRandomUnlockedDyeIndex()
    if #self.unlockedDyeIndices > 0 then
        return self.unlockedDyeIndices[zo_random(1, #self.unlockedDyeIndices)]
    end
    return nil
end

function ZO_Dyeing:UndoPendingChanges()
    ZO_Dyeing_CopyExistingDyesToPending()
    self:OnPendingDyesChanged(nil)
    PlaySound(SOUNDS.DYEING_UNDO_CHANGES)
end

function ZO_Dyeing:SwitchToDyeingWithDyeIndex(dyeIndex, suppressSounds)
    self.suppressSounds = suppressSounds

    local toolChanged = false
    if not self.activeTool:HasSwatchSelection() then
        ZO_MenuBar_SelectDescriptor(self.toolsTabs, self.dyeTool)
        toolChanged = true
    end
    self:SetSelectedDyeIndex(dyeIndex, nil, toolChanged)

    ZO_Scroll_ScrollControlIntoCentralView(self.pane, self.dyeIndexToSwatch[dyeIndex])

    self.suppressSounds = false
end

function ZO_Dyeing:SetSelectedDyeIndex(dyeIndex, becauseOfRebuild, becauseToolChange)
    if self.selectedDyeIndex ~= dyeIndex or becauseOfRebuild then
        local oldSwatch = not becauseOfRebuild and self.dyeIndexToSwatch[self.selectedDyeIndex]
        if oldSwatch then
            oldSwatch:SetSelected(false)
        end

        if self.selectedDyeIndex then
            self.lastSelectedDyeIndex = self.selectedDyeIndex
        end

        self.selectedDyeIndex = dyeIndex

        local newSwatch = self.activeTool:HasSwatchSelection() and self.dyeIndexToSwatch[self.selectedDyeIndex]
        if newSwatch then
            local skipAnim = becauseOfRebuild
            local skipSound = becauseOfRebuild or becauseToolChange
            newSwatch:SetSelected(true, skipAnim, skipSound)
        else
            self.sharedHighlight:SetHidden(true)
        end
    end
end

function ZO_Dyeing:SetSelectedSavedSetIndex(dyeSetIndex)
    if self.selectedSavedSetIndex ~= dyeSetIndex then
        if self.selectedSavedSetIndex then
            self.savedSets[self.selectedSavedSetIndex]:SetSelected(false)
        end

        self.lastSelectedSavedSetIndex = self.selectedSavedSetIndex
        self.selectedSavedSetIndex = dyeSetIndex

        if self.selectedSavedSetIndex then
            self.savedSets[self.selectedSavedSetIndex]:SetSelected(true)

            if self.lastSelectedSavedSetIndex then
                PlaySound(SOUNDS.DYEING_SAVED_SET_SELECTED)
            end
        end
    end
end

function ZO_Dyeing:ToggleSavedSetHightlightBySlotControl(slotControl, isHighlighted, dyeChannel)
    if dyeChannel ~= nil then
        slotControl.dyeControls[dyeChannel].highlightTexture:SetHidden(not isHighlighted)
    else
        for dyeChannel, dyeControl in ipairs(slotControl.dyeControls) do
            dyeControl.highlightTexture:SetHidden(not isHighlighted)
        end
    end
end

function ZO_Dyeing:ToggleSavedSetHightlight(dyeSetIndex, isHighlighted, dyeChannel)
    if dyeSetIndex ~= nil then
        local slotControl = self.savedSets[dyeSetIndex]
        self:ToggleSavedSetHightlightBySlotControl(slotControl, isHighlighted, dyeChannel)
    else
        for _, slotControl in ipairs(self.savedSets) do
            self:ToggleSavedSetHightlightBySlotControl(slotControl, isHighlighted, dyeChannel)
        end
    end
end

function ZO_Dyeing:LayoutDyes()
    self.dyeLayoutDirty = false

    local _, _, unlockedDyeIndices, dyeIndexToSwatch = ZO_Dyeing_LayoutSwatches(self.savedVars.showLocked, self.savedVars.sortStyle, self.swatchPool, self.headerPool, SWATCHES_LAYOUT_OPTIONS, self.pane)
    self.unlockedDyeIndices = unlockedDyeIndices
    self.dyeIndexToSwatch = dyeIndexToSwatch

    local anyDyesToSwatch = (next(dyeIndexToSwatch) ~= nil)
    self.noDyesLabel:SetHidden(anyDyesToSwatch)
    if (self.selectedDyeIndex) then
        self:SetSelectedDyeIndex(self.selectedDyeIndex, true)
    end
end

function ZO_Dyeing:RefreshSavedSet(dyeSetIndex)
    local savedSetSwatch = self.savedSets[dyeSetIndex]
    for dyeChannel, dyeControl in ipairs(savedSetSwatch.dyeControls) do
        local currentDyeIndex = select(dyeChannel, GetSavedDyeSetDyes(dyeSetIndex))
        ZO_DyeingUtils_SetSlotDyeSwatchDyeIndex(dyeChannel, dyeControl, currentDyeIndex)
    end
end

function ZO_Dyeing:RefreshSavedSets()
    for dyeSetIndex in ipairs(self.savedSets) do
        self:RefreshSavedSet(dyeSetIndex)
    end
end

ZO_DyeingEquipmentSheet = ZO_Object:Subclass()

function ZO_DyeingEquipmentSheet:New(...)
    local dyeingEquipment = ZO_Object.New(self)
    dyeingEquipment:Initialize(...)
    return dyeingEquipment
end

function ZO_DyeingEquipmentSheet:Initialize(control, onEquipSlotClickedCallback, onEquipSlotEnterCallback, onEquipSlotExitCallback)
    self.control = control
    self.slots = self.control.slots

    self:InitializeOnEquipSlotCallbacks(onEquipSlotClickedCallback, onEquipSlotEnterCallback, onEquipSlotExitCallback)

    local function OnFullInventoryUpdated()
        self:MarkViewDirty()
    end

    local function OnInventorySlotUpdated(eventCode, bagId, slotIndex)
        if bagId == BAG_WORN then
            self:MarkViewDirty()
        end
    end

    control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, OnFullInventoryUpdated)
    control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySlotUpdated)

    self:MarkViewDirty()
end

function ZO_DyeingEquipmentSheet:InitializeOnEquipSlotCallbacks(onEquipSlotClickedCallback, onEquipSlotEnterCallback, onEquipSlotExitCallback)
    for equipSlot, slotControl in pairs(self.control.slots) do
        for i, dyeControl in ipairs(slotControl.dyeControls) do
            dyeControl:SetHandler("OnMouseUp", function(dyeControl, button, upInside)
                if upInside then
                    onEquipSlotClickedCallback(equipSlot, i, button)
                end
            end)

            dyeControl:SetHandler("OnMouseEnter", function(dyeControl)
                self.mousedOverEquipSlot = equipSlot
                self.mousedOverDyeChannel = i
                onEquipSlotEnterCallback(equipSlot, i)
            end)

            dyeControl:SetHandler("OnMouseExit", function(dyeControl)
                self.mousedOverEquipSlot = nil
                self.mousedOverDyeChannel = nil
                onEquipSlotExitCallback(equipSlot, i)
            end)
        end
    end
end

function ZO_DyeingEquipmentSheet:GetMousedOverEquipInfo()
    return self.mousedOverEquipSlot, self.mousedOverDyeChannel
end

function ZO_DyeingEquipmentSheet:MarkViewDirty()
    if SCENE_MANAGER:IsShowing("dyeing") then
        self:RefreshView()
    else
        self.dirty = true
    end
end

function ZO_DyeingEquipmentSheet:RefreshView()
    self.dirty = false
    for equipSlot, slotControl in pairs(self.slots) do
        ZO_Dyeing_SetupEquipmentControl(slotControl.slot, equipSlot)
        self:RefreshEquipSlotDyes(equipSlot)
    end
end

function ZO_DyeingEquipmentSheet:RefreshEquipSlotDyes(equipSlot)
    local slotControl = self.slots[equipSlot]
    ZO_Dyeing_RefreshEquipControlDyes(slotControl, equipSlot)

    if equipSlot == EQUIP_SLOT_OFF_HAND or equipSlot == EQUIP_SLOT_BACKUP_OFF then
        local activeEquipSlot = ZO_Dyeing_GetActiveOffhandEquipSlot()
        slotControl:SetHidden(equipSlot ~= activeEquipSlot)
    end
end

function ZO_DyeingEquipmentSheet:ToggleEquipSlotHightlightBySlotControl(slotControl, isHighlighted, dyeChannel)
    if dyeChannel ~= nil then
        slotControl.dyeControls[dyeChannel].highlightTexture:SetHidden(not isHighlighted)
    else
        for dyeChannel, dyeControl in ipairs(slotControl.dyeControls) do
            dyeControl.highlightTexture:SetHidden(not isHighlighted)
        end
    end
end

function ZO_DyeingEquipmentSheet:ToggleEquipSlotHightlight(equipSlot, isHighlighted, dyeChannel)
    if equipSlot ~= nil then
        local slotControl = self.slots[equipSlot]
        self:ToggleEquipSlotHightlightBySlotControl(slotControl, isHighlighted, dyeChannel)
    else
        for _, slotControl in pairs(self.slots) do
            self:ToggleEquipSlotHightlightBySlotControl(slotControl, isHighlighted, dyeChannel)
        end
    end
end

function ZO_Dyeing_OnInitialized(control)
    DYEING = ZO_Dyeing:New(control)
    SYSTEMS:RegisterKeyboardObject("dyeing", DYEING)
end
