local ZO_Dyeing = ZO_Object:Subclass()

local SWATCHES_LAYOUT_OPTIONS = {
        padding = 6,
        leftMargin = 27,
        topMargin = 18,
        rightMargin = 0,
        bottomMargin = 0,
        selectionScale = ZO_DYEING_SWATCH_SELECTION_SCALE,
    }

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
    self.mode = DYE_MODE_EQUIPMENT

    self.savedSetInterpolator = ZO_SimpleControlScaleInterpolator:New(.9, 1.0)

    self:InitializeTabs()
    self:InitializeSortsAndFilters()
    self:InitializeTools()
    self:InitializeSavedSets()
    self:InitializeSwatchPool()
    self:InitializeHeaderPool()
    self:InitializeEquipmentSheet()
    self:InitializeCollectibleSheet()
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
            local selectedTabType = ZO_MenuBar_GetSelectedDescriptor(self.tabs)
            self:UpdateOptionControls()

            InitializePendingDyes(self.mode)

            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

            if self.dyeLayoutDirty then
                self:LayoutDyes()
            end
            self:RefreshSavedSets()

            self.equipmentSheet:MarkViewDirty()
            self.collectibleSheet:MarkViewDirty()

            if not ZO_MenuBar_GetSelectedDescriptor(self.toolsTabs) then
                self.suppressSounds = true
                ZO_MenuBar_SelectDescriptor(self.toolsTabs, self.dyeTool)
                self.suppressSounds = false
            end

            local IS_ENABLED = true
            if CanUseCollectibleDyeing() then
                ZO_MenuBar_SetDescriptorEnabled(self.tabs, DYE_MODE_COLLECTIBLE, IS_ENABLED)
            else
                ZO_MenuBar_SetDescriptorEnabled(self.tabs, DYE_MODE_COLLECTIBLE, not IS_ENABLED)
            end
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
            MAIN_MENU_MANAGER:ClearBlockingScene(OnBlockingSceneActivated)
        end
    end)

    local function UpdateDyeLayout()
        self:DirtyDyeLayout()
    end
    self.control:RegisterForEvent(EVENT_UNLOCKED_DYES_UPDATED, UpdateDyeLayout)
    ZO_DYEING_MANAGER:RegisterForDyeListUpdates(UpdateDyeLayout)

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "Dyeing", ZO_DYEING_SAVED_VARIABLES_DEFAULTS)

            self:UpdateOptionControls()

            self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        end
    end

    self.control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    self:DirtyDyeLayout()
end

function ZO_Dyeing:OnTabFilterChanged(tabData)
    self.activeTab:SetText(GetString(tabData.activeTabText))
end

function ZO_Dyeing:SetMode(mode)
    if self.mode ~= mode then
        self.mode = mode

        self.equipmentSheet.control:SetHidden(mode ~= DYE_MODE_EQUIPMENT)
        self.collectibleSheet.control:SetHidden(mode ~= DYE_MODE_COLLECTIBLE)

        -- make sure the current sheet has the latest dye data for its slots
        InitializePendingDyes(mode)

        local currentSheet = self:GetCurrentSheet()
        currentSheet:MarkViewDirty()
    end
end

function ZO_Dyeing:HandleTabChange(tabData, nextMode)
    if ZO_Dyeing_AreTherePendingDyes(self.mode) then
        self.pendingTabData = tabData
        self.pendingMode = nextMode
        if ZO_Dyeing_AreAllItemsBound(self.mode) then
            ZO_Dialogs_ShowDialog("SWTICH_DYE_MODE")
        else
            ZO_Dialogs_ShowDialog("SWTICH_DYE_MODE_BIND")
        end
    else
        self:OnTabFilterChanged(tabData)
        self:SetMode(nextMode)
    end
end

function ZO_Dyeing:InitializeTabs()
    local function GenerateTab(name, mode, normal, pressed, highlight, disabled, customTooltip)
        return {
            activeTabText = name,
            categoryName = name,

            descriptor = mode,
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            disabled = disabled,
            CustomTooltipFunction = customTooltip,
            alwaysShowTooltip = true,
            callback = function(tabData, playerDriven) 
                            if playerDriven then 
                                self:HandleTabChange(tabData, mode) 
                            end 
                       end,
        }
    end

    self.tabs = self.control:GetNamedChild("Tabs")
    self.activeTab = self.control:GetNamedChild("TabsLabel")

    ZO_MenuBar_AddButton(self.tabs, GenerateTab(SI_DYEING_DYE_EQUIPMENT_TAB, DYE_MODE_EQUIPMENT, "EsoUI/Art/Dye/dyes_tabIcon_dye_up.dds", "EsoUI/Art/Dye/dyes_tabIcon_dye_down.dds", "EsoUI/Art/Dye/dyes_tabIcon_dye_over.dds", "EsoUI/Art/Dye/dyes_tabIcon_dye_disabled.dds"))
    ZO_MenuBar_AddButton(self.tabs, GenerateTab(SI_DYEING_DYE_COLLECTIBLE_TAB, DYE_MODE_COLLECTIBLE, "EsoUI/Art/Dye/dyes_tabIcon_costumeDye_up.dds", "EsoUI/Art/Dye/dyes_tabIcon_costumeDye_down.dds", "EsoUI/Art/Dye/dyes_tabIcon_costumeDye_over.dds", "EsoUI/Art/Dye/dyes_tabIcon_costumeDye_disabled.dds", function(...) self:LayoutCollectionAppearanceTooltip(...) end))

    ZO_MenuBar_SelectDescriptor(self.tabs, DYE_MODE_EQUIPMENT)
    self.activeTab:SetText(GetString(SI_DYEING_DYE_EQUIPMENT_TAB))
end

function ZO_Dyeing:LayoutCollectionAppearanceTooltip(tooltip)
    local description
    local title
    if CanUseCollectibleDyeing() then
        title = zo_strformat(SI_DYEING_COLLECTIBLE_STATUS, ZO_DEFAULT_ENABLED_COLOR:Colorize(GetString(SI_ESO_PLUS_STATUS_UNLOCKED)))
        description = GetString(SI_DYEING_COLLECTIBLE_TAB_DESCRIPTION_UNLOCKED)
    else
        title = zo_strformat(SI_DYEING_COLLECTIBLE_STATUS, ZO_DEFAULT_ENABLED_COLOR:Colorize(GetString(SI_ESO_PLUS_STATUS_LOCKED)))
        description = GetString(SI_DYEING_COLLECTIBLE_TAB_DESCRIPTION_LOCKED)
    end

    SetTooltipText(tooltip, title)
    local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
    tooltip:AddLine(description, "", r, g, b)
end

function ZO_Dyeing:OnToolChanged(tool)
    local currentSheet = self:GetCurrentSheet()

    local mousedOverDyeableSlot, mousedOverDyeChannel = currentSheet:GetMousedOverDyeableSlotInfo()
    local mousedOverSavedSetIndex
    if not mousedOverDyeableSlot then
        mousedOverSavedSetIndex, mousedOverDyeChannel = self:GetMousedOverSavedSetInfo()
    end

    local lastTool = self.activeTool
    if self.activeTool then
        if mousedOverDyeableSlot and mousedOverDyeChannel then
            self:OnDyeSlotExit(mousedOverDyeableSlot, mousedOverDyeChannel)
        elseif mousedOverSavedSetIndex and mousedOverDyeChannel then
            self:OnSavedSetDyeSlotExit(mousedOverSavedSetIndex, mousedOverDyeChannel)
        end
        self.activeTool:Deactivate(self.suppressSounds)
    end

    self.activeTool = tool

    if self.activeTool then
        self.activeTool:Activate(lastTool, self.suppressSounds)

        if mousedOverDyeableSlot and mousedOverDyeChannel then
            self:OnDyeSlotEnter(mousedOverDyeableSlot, mousedOverDyeChannel)
        elseif mousedOverSavedSetIndex and mousedOverDyeChannel then
            self:OnSavedSetDyeSlotEnter(mousedOverSavedSetIndex, mousedOverDyeChannel)
        end

        if self.activeTool:HasSwatchSelection() then
            local TOOL_CHANGE = true
            self:SetSelectedDyeId(self.selectedDyeId or self.lastSelectedDyeId or self.unlockedDyeIds[1], nil, TOOL_CHANGE)
        else
            self:SetSelectedDyeId(nil)
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
                self:OnSavedSetDyeSlotEnter(dyeSetIndex, dyeChannel, dyeControl)
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
        self:OnDyeSlotClicked(...)
    end

    local function OnEquipmentDyeSlotEnter(...)
        self:OnDyeSlotEnter(...)
    end

    local function OnEquipmentDyeSlotExit(...)
        self:OnDyeSlotExit(...)
    end
    self.equipmentSheet = ZO_DyeingSlotsSheet:New(self.control:GetNamedChild("EquipmentSheet"), OnEquipmentDyeSlotClicked, OnEquipmentDyeSlotEnter, OnEquipmentDyeSlotExit)
end

function ZO_Dyeing:InitializeCollectibleSheet()
    local function OnCollectibleDyeSlotClicked(...)
        self:OnDyeSlotClicked(...)
    end

    local function OnCollectibleDyeSlotEnter(...)
        self:OnDyeSlotEnter(...)
    end

    local function OnCollectibleDyeSlotExit(...)
        self:OnDyeSlotExit(...)
    end
    self.collectibleSheet = ZO_DyeingSlotsSheet:New(self.control:GetNamedChild("CollectibleSheet"), OnCollectibleDyeSlotClicked, OnCollectibleDyeSlotEnter, OnCollectibleDyeSlotExit)
end

function ZO_Dyeing:InitializeSortsAndFilters()
    self.showLockedCheckBox = self.control:GetNamedChild("ShowLocked")

    local function OnFilterChanged(checkButton, isChecked)
        if self.savedVars.showLocked ~= isChecked then
            self.savedVars.showLocked = isChecked
            ZO_DYEING_MANAGER:UpdateAllDyeLists()
        end
    end

    ZO_CheckButton_SetToggleFunction(self.showLockedCheckBox, OnFilterChanged)
    ZO_CheckButton_SetLabelText(self.showLockedCheckBox, GetString(SI_DYEING_SHOW_LOCKED))
	ZO_CheckButton_SetLabelWrapMode(self.showLockedCheckBox, TEXT_WRAP_MODE_ELLIPSIS, self.control:GetRight() - self.showLockedCheckBox:GetRight())

    local function SetSortStyle(_, _, entry)
        if entry.sortStyleType ~= self.savedVars.sortStyle then
            self.savedVars.sortStyle = entry.sortStyleType
            ZO_DYEING_MANAGER:UpdateAllDyeLists()
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

function ZO_Dyeing:UpdateOptionControls()
    self.sortDropDown:SelectItem(self.savedVars.sortStyle == ZO_DYEING_SORT_STYLE_RARITY and self.sortByRarityEntry or self.sortByHueEntry)
    ZO_CheckButton_SetCheckState(self.showLockedCheckBox, self.savedVars.showLocked)
end

function ZO_Dyeing:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Apply dye
        {
            name = GetString(SI_DYEING_COMMIT),
            keybind = "UI_SHORTCUT_SECONDARY",

            visible = function() return ZO_Dyeing_AreTherePendingDyes(self.mode) end,
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
            visible = function() return ZO_Dyeing_AreTherePendingDyes(self.mode) end,
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

function ZO_Dyeing:OnDyeSlotClicked(dyeableSlot, dyeChannel, button)
    if self.activeTool then
        self.activeTool:OnClicked(dyeableSlot, dyeChannel, button)
    end
end

function ZO_Dyeing:OnSavedSetDyeSlotClicked(dyeSetIndex, dyeChannel, button)
    if self.activeTool then
        self.activeTool:OnSavedSetClicked(dyeSetIndex, dyeChannel, button)
    end
end

do
    local NON_PLAYER_DYE_NOT_KNOWN = false
    local IS_NON_PLAYER_DYE = true

    function ZO_Dyeing:OnDyeSlotEnter(dyeableSlot, dyeChannel, dyeControl)
        if self.activeTool then
            local highlightSlot, highlightDyeChannel = self.activeTool:GetHighlightRules(dyeableSlot, dyeChannel)
            self:GetCurrentSheet():ToggleDyeableSlotHightlight(highlightSlot, true, highlightDyeChannel)
            WINDOW_MANAGER:SetMouseCursor(self.activeTool:GetCursorType(dyeableSlot, dyeChannel))
        end
        local dyeId = select(dyeChannel, GetPendingSlotDyes(dyeableSlot))
        local swatch = self.dyeIdToSwatch[dyeId]
        if swatch then
            ZO_Dyeing_CreateTooltipOnMouseEnter(swatch, swatch.dyeName, swatch.known, swatch.achievementId)
        else
            local dyeName, _, _, _, achievementId = GetDyeInfoById(dyeId)
            if dyeName ~= "" then
                ZO_Dyeing_CreateTooltipOnMouseEnter(dyeControl, dyeName, NON_PLAYER_DYE_NOT_KNOWN, achievementId, IS_NON_PLAYER_DYE)
            end
        end
    end

    function ZO_Dyeing:OnDyeSlotExit(dyeableSlot, dyeChannel)
        self:GetCurrentSheet():ToggleDyeableSlotHightlight(nil, false, nil)
        WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
        ZO_Dyeing_ClearTooltipOnMouseExit()
    end

    function ZO_Dyeing:OnSavedSetDyeSlotEnter(dyeSetIndex, dyeChannel, dyeControl)
        if self.activeTool then
            if self.activeTool:HasSavedSetSelection() then
                self.savedSets[dyeSetIndex]:OnMouseEnter()
            else
                local highlightSlot, highlightDyeChannel = self.activeTool:GetHighlightRules(dyeSetIndex, dyeChannel)
                self:ToggleSavedSetHightlight(highlightSlot, true, highlightDyeChannel)
                WINDOW_MANAGER:SetMouseCursor(self.activeTool:GetCursorType(dyeSetIndex, dyeChannel))
            end
        end
        local dyeId = select(dyeChannel, GetSavedDyeSetDyes(dyeSetIndex))
        local swatch = self.dyeIdToSwatch[dyeId]
        if swatch then
            ZO_Dyeing_CreateTooltipOnMouseEnter(swatch, swatch.dyeName, swatch.known, swatch.achievementId)
        else
            -- Technically should never be able to get here, but you never know
            local dyeName, _, _, _, achievementId = GetDyeInfoById(dyeId)
            ZO_Dyeing_CreateTooltipOnMouseEnter(dyeControl, dyeName, NON_PLAYER_DYE_NOT_KNOWN, achievementId, IS_NON_PLAYER_DYE)
        end
    end
end

function ZO_Dyeing:OnSavedSetDyeSlotExit(dyeSetIndex, dyeChannel)
    if self.activeTool == nil or not self.activeTool:HasSavedSetSelection() then
        self:ToggleSavedSetHightlight(nil, false, nil)
    end
    self.savedSets[dyeSetIndex]:OnMouseExit()
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
    ZO_Dyeing_ClearTooltipOnMouseExit()
end

function ZO_Dyeing:GetSelectedDyeId()
    return self.selectedDyeId
end

function ZO_Dyeing:GetSelectedSavedSetIndex()
    return self.selectedSavedSetIndex
end

function ZO_Dyeing:GetMousedOverSavedSetInfo()
    return self.mousedOverSavedSetIndex, self.mousedOverSavedSetDyeChannel
end

function ZO_Dyeing:OnPendingDyesChanged(dyeableSlot)
    local currentSheet = self:GetCurrentSheet()

    if dyeableSlot then
        currentSheet:RefreshDyeableSlotDyes(dyeableSlot)
    else
        currentSheet:MarkViewDirty()
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

    if ZO_Dyeing_AreTherePendingDyes(self.mode) then
        if ZO_Dyeing_AreAllItemsBound(self.mode) then
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

function ZO_Dyeing:ConfirmSwitchMode(applyChanges)
    if applyChanges then
        self:ConfirmCommitSelection()
        PlaySound(SOUNDS.DYEING_APPLY_CHANGES_FROM_DIALOGUE)
    else
        self:UndoPendingChanges()
    end

    self:OnTabFilterChanged(self.pendingTabData)
    self:SetMode(self.pendingMode)

    self.pendingTabData = nil
    self.pendingMode = nil
end

function ZO_Dyeing:CommitSelection()
    if ZO_Dyeing_AreAllItemsBound(self.mode) then
        self:ConfirmCommitSelection()
        PlaySound(SOUNDS.DYEING_APPLY_CHANGES)
    else
        ZO_Dialogs_ShowDialog("CONFIRM_APPLY_DYE")
    end
end

function ZO_Dyeing:ConfirmCommitSelection()
    ApplyPendingDyes()
    InitializePendingDyes(self.mode)
    self:OnPendingDyesChanged()
end

function ZO_Dyeing:CancelExitToAchievements()
    self.exitingToAchievementId = nil
end

function ZO_Dyeing:CancelExit()
    MAIN_MENU_MANAGER:CancelBlockingSceneNextScene()
end

function ZO_Dyeing:UniformRandomize()
    ZO_Dyeing_UniformRandomize(self.mode, function() return self:GetRandomUnlockedDyeId() end)
    self:OnPendingDyesChanged()
end

function ZO_Dyeing:GetRandomUnlockedDyeId()
    if #self.unlockedDyeIds > 0 then
        return self.unlockedDyeIds[zo_random(1, #self.unlockedDyeIds)]
    end
    return nil
end

function ZO_Dyeing:UndoPendingChanges()
    InitializePendingDyes(self.mode)
    self:OnPendingDyesChanged()
    PlaySound(SOUNDS.DYEING_UNDO_CHANGES)
end

function ZO_Dyeing:SwitchToDyeingWithDyeId(dyeId, suppressSounds)
    local swatch = self.dyeIdToSwatch[dyeId]
    if swatch then -- super edge case check (most likely only an internal issue) for having a non-player dye in your saved sets
        self.suppressSounds = suppressSounds

        local toolChanged = false
        if not self.activeTool:HasSwatchSelection() then
            ZO_MenuBar_SelectDescriptor(self.toolsTabs, self.dyeTool)
            toolChanged = true
        end
        self:SetSelectedDyeId(dyeId, nil, toolChanged)

        ZO_Scroll_ScrollControlIntoCentralView(self.pane, self.dyeIdToSwatch[dyeId])

        self.suppressSounds = false
    end
end

function ZO_Dyeing:DoesDyeIdExistInPlayerDyes(dyeId)
    return self.dyeIdToSwatch[dyeId] ~= nil
end

function ZO_Dyeing:SetSelectedDyeId(dyeId, becauseOfRebuild, becauseToolChange)
    if self.selectedDyeId ~= dyeId or becauseOfRebuild then
        if not becauseOfRebuild then
            local oldSwatch = self.dyeIdToSwatch[self.selectedDyeId]
            if oldSwatch then
                oldSwatch:SetSelected(false)
            end
        end

        if self.selectedDyeId then
            self.lastSelectedDyeId = self.selectedDyeId
        end

        self.selectedDyeId = dyeId

        local newSwatch = self.activeTool:HasSwatchSelection() and self.dyeIdToSwatch[self.selectedDyeId]
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

    local _, _, unlockedDyeIds, dyeIdToSwatch = ZO_Dyeing_LayoutSwatches(self.savedVars.showLocked, self.savedVars.sortStyle, self.swatchPool, self.headerPool, SWATCHES_LAYOUT_OPTIONS, self.pane)
    self.unlockedDyeIds = unlockedDyeIds
    self.dyeIdToSwatch = dyeIdToSwatch

    local anyDyesToSwatch = (next(dyeIdToSwatch) ~= nil)
    self.noDyesLabel:SetHidden(anyDyesToSwatch)
    if self.selectedDyeId then
        self:SetSelectedDyeId(self.selectedDyeId, true)
    end
end

function ZO_Dyeing:RefreshSavedSet(dyeSetIndex)
    local savedSetSwatch = self.savedSets[dyeSetIndex]
    for dyeChannel, dyeControl in ipairs(savedSetSwatch.dyeControls) do
        local currentDyeId = select(dyeChannel, GetSavedDyeSetDyes(dyeSetIndex))
        ZO_DyeingUtils_SetSlotDyeSwatchDyeId(dyeChannel, dyeControl, currentDyeId)
    end
end

function ZO_Dyeing:RefreshSavedSets()
    for dyeSetIndex in ipairs(self.savedSets) do
        self:RefreshSavedSet(dyeSetIndex)
    end
end

function ZO_Dyeing:GetCurrentSheet()
    local selectedTabType = self.mode
    if selectedTabType == DYE_MODE_EQUIPMENT then
        return self.equipmentSheet
    elseif selectedTabType == DYE_MODE_COLLECTIBLE then
        return self.collectibleSheet
    end
end

function ZO_Dyeing:GetMode()
    return self.mode
end

ZO_DyeingSlotsSheet = ZO_Object:Subclass()

function ZO_DyeingSlotsSheet:New(...)
    local dyeingSlotsSheet = ZO_Object.New(self)
    dyeingSlotsSheet:Initialize(...)
    return dyeingSlotsSheet
end

function ZO_DyeingSlotsSheet:Initialize(control, onSlotClickedCallback, onSlotEnterCallback, onSlotExitCallback)
    self.control = control
    self.slots = self.control.slots

    self:InitializeOnSlotCallbacks(onSlotClickedCallback, onSlotEnterCallback, onSlotExitCallback)

    local function OnFullInventoryUpdated()
        self:MarkViewDirty()
    end

    --Filtered on bagId == BAG_WORN
    local function OnInventorySlotUpdated(eventCode, bagId, slotIndex)
        self:MarkViewDirty()
    end

    control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, OnFullInventoryUpdated)
    control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySlotUpdated)
    control:AddFilterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_WORN)

    self:MarkViewDirty()
end

function ZO_DyeingSlotsSheet:InitializeOnSlotCallbacks(onSlotClickedCallback, onSlotEnterCallback, onSlotExitCallback)
    for dyeableSlot, slotControl in pairs(self.control.slots) do
        for i, dyeControl in ipairs(slotControl.dyeControls) do
            dyeControl:SetHandler("OnMouseUp", function(dyeControl, button, upInside)
                if upInside then
                    onSlotClickedCallback(dyeableSlot, i, button)
                end
            end)

            dyeControl:SetHandler("OnMouseEnter", function(dyeControl)
                self.mousedOverDyeableSlot = dyeableSlot
                self.mousedOverDyeChannel = i
                onSlotEnterCallback(dyeableSlot, i, dyeControl)
            end)

            dyeControl:SetHandler("OnMouseExit", function(dyeControl)
                self.mousedOverDyeableSlot = nil
                self.mousedOverDyeChannel = nil
                onSlotExitCallback(dyeableSlot, i)
            end)
        end
    end
end

function ZO_DyeingSlotsSheet:GetMousedOverDyeableSlotInfo()
    return self.mousedOverDyeableSlot, self.mousedOverDyeChannel
end

function ZO_DyeingSlotsSheet:MarkViewDirty()
    if SCENE_MANAGER:IsShowing("dyeing") then
        self:RefreshView()
    else
        self.dirty = true
    end
end

function ZO_DyeingSlotsSheet:RefreshView()
    self.dirty = false
    for dyeableSlot, slotControl in pairs(self.slots) do
        ZO_Dyeing_SetupDyeableSlotControl(slotControl.slot, dyeableSlot)
        self:RefreshDyeableSlotDyes(dyeableSlot)
    end
end

function ZO_DyeingSlotsSheet:RefreshDyeableSlotDyes(dyeableSlot)
    local slotControl = self.slots[dyeableSlot]
    ZO_Dyeing_RefreshDyeableSlotControlDyes(slotControl, dyeableSlot)

    if dyeableSlot == DYEABLE_SLOT_OFF_HAND or dyeableSlot == DYEABLE_SLOT_BACKUP_OFF then
        local activeDyeableSlot = ZO_Dyeing_GetActiveOffhandDyeableSlot()
        slotControl:SetHidden(dyeableSlot ~= activeDyeableSlot)
    end
end

function ZO_DyeingSlotsSheet:ToggleDyeableSlotHightlightBySlotControl(slotControl, isHighlighted, dyeChannel)
    if dyeChannel ~= nil then
        slotControl.dyeControls[dyeChannel].highlightTexture:SetHidden(not isHighlighted)
    else
        for dyeChannel, dyeControl in ipairs(slotControl.dyeControls) do
            dyeControl.highlightTexture:SetHidden(not isHighlighted)
        end
    end
end

function ZO_DyeingSlotsSheet:ToggleDyeableSlotHightlight(dyeableSlot, isHighlighted, dyeChannel)
    if dyeableSlot ~= nil then
        local slotControl = self.slots[dyeableSlot]
        self:ToggleDyeableSlotHightlightBySlotControl(slotControl, isHighlighted, dyeChannel)
    else
        for _, slotControl in pairs(self.slots) do
            self:ToggleDyeableSlotHightlightBySlotControl(slotControl, isHighlighted, dyeChannel)
        end
    end
end

function ZO_Dyeing_OnInitialized(control)
    DYEING = ZO_Dyeing:New(control)
    SYSTEMS:RegisterKeyboardObject("dyeing", DYEING)
end

local SHOW_NICKNAME, SHOW_HINT, SHOW_BLOCK_REASON = true, true, true
function ZO_DyeableSlot_OnMouseEnter(control)
    local equipSlot = GetEquipSlotFromDyeableSlot(control.dyeableSlot)
    local collectibleCategoryType = GetCollectibleCategoryFromDyeableSlot(control.dyeableSlot)
    if equipSlot ~= EQUIP_SLOT_NONE then
        ZO_InventorySlot_OnMouseEnter(control)
    elseif collectibleCategoryType ~= COLLECTIBLE_CATEGORY_TYPE_INVALID then
        local collectibleId = GetDyeableSlotId(control.dyeableSlot)
        if collectibleId > 0 then
            InitializeTooltip(ItemTooltip, control, LEFT, 5, 0, RIGHT)
            ItemTooltip:SetCollectible(collectibleId, SHOW_NICKNAME, SHOW_HINT, SHOW_BLOCK_REASON)
        else
            InitializeTooltip(InformationTooltip, control, LEFT, 5, 0, RIGHT)
            SetTooltipText(InformationTooltip, zo_strformat(SI_CHARACTER_EQUIP_SLOT_FORMAT, GetString("SI_DYEABLESLOT", control.dyeableSlot)))
        end
    end
end

function ZO_DyeableSlot_OnMouseExit(control)
    local equipSlot = GetEquipSlotFromDyeableSlot(control.dyeableSlot)
    local collectibleCategoryType = GetCollectibleCategoryFromDyeableSlot(control.dyeableSlot)
    if equipSlot ~= EQUIP_SLOT_NONE then
        ZO_InventorySlot_OnMouseExit(control)
    elseif collectibleCategoryType ~= COLLECTIBLE_CATEGORY_TYPE_INVALID then
        ClearTooltip(ItemTooltip)
        ClearTooltip(InformationTooltip)
    end
end