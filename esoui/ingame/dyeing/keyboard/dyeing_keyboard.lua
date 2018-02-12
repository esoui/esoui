local BECAUSE_OF_REBUILD = true

ZO_Dyeing_Keyboard = ZO_Object:Subclass()

local SWATCHES_LAYOUT_OPTIONS = 
{
    padding = 6,
    leftMargin = 27,
    topMargin = 18,
    rightMargin = 0,
    bottomMargin = 0,
    selectionScale = ZO_DYEING_SWATCH_SELECTION_SCALE,
}

function ZO_Dyeing_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_Dyeing_Keyboard:Initialize(control)
    self.control = control
    self.pane = control:GetNamedChild("Pane")
    self.noDyesLabel = self.pane:GetNamedChild("NoDyesLabel")
    self.paneScrollChild = self.pane:GetNamedChild("ScrollChild")
    self.sharedHighlight = self.paneScrollChild:GetNamedChild("SharedHighlight")
    self.dyeIdToSwatch = {} -- Create it now so the APIs have a table to index even if we never view the fragment

    self.savedSetInterpolator = ZO_SimpleControlScaleInterpolator:New(.9, 1.0)

    self:InitializeSortsAndFilters()
    self:InitializeTools()
    self:InitializeSavedSets()
    self:InitializeSwatchPool()
    self:InitializeHeaderPool()
    
    KEYBOARD_DYEING_FRAGMENT = ZO_FadeSceneFragment:New(control)
    KEYBOARD_DYEING_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            TriggerTutorial(TUTORIAL_TRIGGER_DYEING_OPENED)
            if IsESOPlusSubscriber() then
                TriggerTutorial(TUTORIAL_TRIGGER_DYEING_OPENED_AS_SUBSCRIBER)
            end

            self:UpdateOptionControls()

            if self.dyeLayoutDirty then
                self:LayoutDyes()
            end
            self:RefreshSavedSets()

            if not ZO_MenuBar_GetSelectedDescriptor(self.toolsTabs) then
                self.suppressSounds = true
                ZO_MenuBar_SelectDescriptor(self.toolsTabs, self.dyeTool)
                self.suppressSounds = false
            end
        elseif newState == SCENE_FRAGMENT_HIDING then
            if ZO_MenuBar_GetSelectedDescriptor(self.toolsTabs) then
                self.suppressSounds = true
                ZO_MenuBar_SelectDescriptor(self.toolsTabs, self.dyeTool)
                self.suppressSounds = false
            end
        end
    end)
    self.fragment = KEYBOARD_DYEING_FRAGMENT

    local function UpdateDyeLayout()
        self:DirtyDyeLayout()
    end

    ZO_DYEING_MANAGER:RegisterCallback("UpdateDyeData", UpdateDyeLayout)
    ZO_DYEING_MANAGER:RegisterCallback("UpdateDyeLists", UpdateDyeLayout)
    ZO_DYEING_MANAGER:RegisterCallback("UpdateSearchResults", UpdateDyeLayout)
    ZO_DYEING_MANAGER:RegisterCallback("OptionsInfoAvailable", function() self:UpdateOptionControls() end)

    self:DirtyDyeLayout()
end

function ZO_Dyeing_Keyboard:OnToolChanged(tool)
    local currentSheet = ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:GetCurrentSheet()

    local mousedOverDyeableSlotData, mousedOverDyeChannel = currentSheet:GetMousedOverDyeableSlotInfo()
    local mousedOverSavedSetIndex
    if not mousedOverDyeableSlotData then
        mousedOverSavedSetIndex, mousedOverDyeChannel = self:GetMousedOverSavedSetInfo()
    end

    local lastTool = self.activeTool
    if lastTool then
        if mousedOverDyeableSlotData and mousedOverDyeChannel then
            ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:OnDyeSlotExit(mousedOverDyeableSlotData, mousedOverDyeChannel)
        elseif mousedOverSavedSetIndex and mousedOverDyeChannel then
            self:OnSavedSetDyeSlotExit(mousedOverSavedSetIndex, mousedOverDyeChannel)
        end
        self.activeTool:Deactivate(self.suppressSounds)
    end

    self.activeTool = tool

    if self.activeTool then
        self.activeTool:Activate(lastTool, self.suppressSounds)

        if mousedOverDyeableSlotData and mousedOverDyeChannel then
            ZO_RESTYLE_SHEET_WINDOW_KEYBOARD:OnDyeSlotEnter(mousedOverDyeableSlotData, mousedOverDyeChannel)
        elseif mousedOverSavedSetIndex and mousedOverDyeChannel then
            self:OnSavedSetDyeSlotEnter(mousedOverSavedSetIndex, mousedOverDyeChannel)
        end

        if self.activeTool:HasSwatchSelection() then
            local TOOL_CHANGE = true
            local autoSelectDyeId = self.selectedDyeId or self.lastSelectedDyeId
            if not autoSelectDyeId then
                local firstUnlockedPlayerDye = ZO_DYEING_MANAGER:GetUnlockedPlayerDyes()[1]
                if firstUnlockedPlayerDye then
                    autoSelectDyeId = firstUnlockedPlayerDye.dyeId
                end
            end
            self:SetSelectedDyeId(autoSelectDyeId, nil, TOOL_CHANGE)
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

function ZO_Dyeing_Keyboard:InitializeTools()
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
function ZO_Dyeing_Keyboard:InitializeSavedSets()
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

function ZO_Dyeing_Keyboard:InitializeSwatchPool()
    local CANNOT_SELECT_LOCKED = false
    self.swatchPool = ZO_Dyeing_InitializeSwatchPool(self, self.sharedHighlight, self.paneScrollChild, "ZO_DyeingSwatch", CANNOT_SELECT_LOCKED, HIGHLIGHT_DIMENSIONS)
end

function ZO_Dyeing_Keyboard:InitializeHeaderPool()
    self.headerPool = ZO_ControlPool:New("ZO_DyeingHeader", self.paneScrollChild)
end

function ZO_Dyeing_Keyboard:InitializeSortsAndFilters()
    self.showLockedCheckBox = self.control:GetNamedChild("ShowLocked")
    local sortByControl = self.control:GetNamedChild("SortBy")

    local function OnFilterChanged(checkButton, isChecked)
        ZO_DYEING_MANAGER:SetShowLocked(isChecked)
    end

    ZO_CheckButton_SetToggleFunction(self.showLockedCheckBox, OnFilterChanged)
    ZO_CheckButton_SetLabelText(self.showLockedCheckBox, GetString(SI_RESTYLE_SHOW_LOCKED))
    ZO_CheckButton_SetLabelWrapMode(self.showLockedCheckBox, TEXT_WRAP_MODE_ELLIPSIS, sortByControl:GetLeft() - self.showLockedCheckBox:GetRight() - 10)

    local function SetSortStyle(_, _, entry)
        ZO_DYEING_MANAGER:SetSortStyle(entry.sortStyleType)
    end

    self.sortDropDown = ZO_ComboBox_ObjectFromContainer(sortByControl)
    self.sortDropDown:SetSortsItems(false)

    self.sortByRarityEntry = ZO_ComboBox:CreateItemEntry(GetString(SI_DYEING_SORT_BY_RARITY), SetSortStyle)
    self.sortByRarityEntry.sortStyleType = ZO_DYEING_SORT_STYLE_RARITY
    self.sortDropDown:AddItem(self.sortByRarityEntry, ZO_COMBOBOX_SUPRESS_UPDATE)

    self.sortByHueEntry = ZO_ComboBox:CreateItemEntry(GetString(SI_DYEING_SORT_BY_HUE), SetSortStyle)
    self.sortByHueEntry.sortStyleType = ZO_DYEING_SORT_STYLE_HUE
    self.sortDropDown:AddItem(self.sortByHueEntry, ZO_COMBOBOX_SUPRESS_UPDATE)

    self.sortDropDown:UpdateItems()
end

function ZO_Dyeing_Keyboard:UpdateOptionControls()
    self.sortDropDown:SelectItem(ZO_DYEING_MANAGER:GetSortStyle() == ZO_DYEING_SORT_STYLE_RARITY and self.sortByRarityEntry or self.sortByHueEntry)
    ZO_CheckButton_SetCheckState(self.showLockedCheckBox, ZO_DYEING_MANAGER:GetShowLocked())
end

function ZO_Dyeing_Keyboard:DirtyDyeLayout()
    if self.fragment:IsShowing() then
        self:LayoutDyes()
    else
        self.dyeLayoutDirty = true
    end
end

function ZO_Dyeing_Keyboard:OnDyeSlotClicked(restyleSlotData, dyeChannel, button)
    if self:GetActiveTool() then
        self.activeTool:OnClicked(restyleSlotData, dyeChannel, button)
    end
end

function ZO_Dyeing_Keyboard:OnSavedSetDyeSlotClicked(dyeSetIndex, dyeChannel, button)
    if self:GetActiveTool() then
        self.activeTool:OnSavedSetClicked(dyeSetIndex, dyeChannel, button)
    end
end

do
    local UNKNOWN_DYE = false
    local IS_NON_PLAYER_DYE = true

    function ZO_Dyeing_Keyboard:OnSavedSetDyeSlotEnter(dyeSetIndex, dyeChannel, dyeControl)
        if self:GetActiveTool() then
            if self.activeTool:HasSavedSetSelection() then
                self.savedSets[dyeSetIndex]:OnMouseEnter()
            else
                local highlightSlot, highlightDyeChannel = self.activeTool:GetHighlightRules(dyeSetIndex, dyeChannel)
                self:ToggleSavedSetHightlight(highlightSlot, true, highlightDyeChannel)
                WINDOW_MANAGER:SetMouseCursor(self.activeTool:GetCursorType())
            end
        end
        local dyeId = select(dyeChannel, GetSavedDyeSetDyes(dyeSetIndex))
        if dyeId ~= 0 then
            local swatchObject = self.dyeIdToSwatch[dyeId]
            if swatchObject then
                ZO_Dyeing_CreateTooltipOnMouseEnter(swatchObject.control, swatchObject.dyeName, swatchObject.known, swatchObject.achievementId)
            else
                -- Technically should never be able to get here, but you never know
                local dyeName, _, _, _, achievementId = GetDyeInfoById(dyeId)
                if dyeName ~= "" then
                    ZO_Dyeing_CreateTooltipOnMouseEnter(dyeControl, dyeName, UNKNOWN_DYE, achievementId, IS_NON_PLAYER_DYE)
                end
            end
        end
    end
end

function ZO_Dyeing_Keyboard:OnSavedSetDyeSlotExit(dyeSetIndex, dyeChannel)
    if self:GetActiveTool() == nil or not self.activeTool:HasSavedSetSelection() then
        self:ToggleSavedSetHightlight(nil, false, nil)
    end
    self.savedSets[dyeSetIndex]:OnMouseExit()
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
    ZO_Dyeing_ClearTooltipOnMouseExit()
end

function ZO_Dyeing_Keyboard:GetSelectedDyeId()
    return self.selectedDyeId
end

function ZO_Dyeing_Keyboard:GetSelectedSavedSetIndex()
    return self.selectedSavedSetIndex
end

function ZO_Dyeing_Keyboard:GetMousedOverSavedSetInfo()
    return self.mousedOverSavedSetIndex, self.mousedOverSavedSetDyeChannel
end

function ZO_Dyeing_Keyboard:OnSavedSetSlotChanged(dyeSetIndex)
    if dyeSetIndex then
        self:RefreshSavedSet(dyeSetIndex)
    else
        self:RefreshSavedSets()
    end
end

function ZO_Dyeing_Keyboard:CancelExit()
    MAIN_MENU_MANAGER:CancelBlockingSceneNextScene()
end

function ZO_Dyeing_Keyboard:SwitchToDyeingWithDyeId(dyeId, suppressSounds)
    self.suppressSounds = suppressSounds

    local toolChanged = false
    if not self.activeTool:HasSwatchSelection() then
        ZO_MenuBar_SelectDescriptor(self.toolsTabs, self.dyeTool)
        toolChanged = true
    end
    self:SetSelectedDyeId(dyeId, nil, toolChanged)

    local swatchObject = self.dyeIdToSwatch[dyeId]
    if swatchObject then
        ZO_Scroll_ScrollControlIntoCentralView(self.pane, swatchObject.control)
    end

    self.suppressSounds = false
end

function ZO_Dyeing_Keyboard:SetSelectedDyeId(dyeId, becauseOfRebuild, becauseToolChange)
    if self.selectedDyeId ~= dyeId or becauseOfRebuild then
        if not becauseOfRebuild then
            local oldSwatchObject = self.dyeIdToSwatch[self.selectedDyeId]
            if oldSwatchObject then
                oldSwatchObject:SetSelected(false)
            end
        end

        if self.selectedDyeId then
            self.lastSelectedDyeId = self.selectedDyeId
        end

        self.selectedDyeId = dyeId

        local newSwatchObject = self.activeTool:HasSwatchSelection() and self.dyeIdToSwatch[self.selectedDyeId]
        if newSwatchObject then
            local skipAnim = becauseOfRebuild
            local skipSound = becauseOfRebuild or becauseToolChange
            newSwatchObject:SetSelected(true, skipAnim, skipSound)
        else
            self.sharedHighlight:SetHidden(true)
        end
    end
end

function ZO_Dyeing_Keyboard:SetSelectedSavedSetIndex(dyeSetIndex)
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

function ZO_Dyeing_Keyboard:ToggleSavedSetHightlightBySlotControl(slotControl, isHighlighted, dyeChannel)
    if dyeChannel ~= nil then
        slotControl.dyeControls[dyeChannel].highlightTexture:SetHidden(not isHighlighted)
    else
        for dyeChannel, dyeControl in ipairs(slotControl.dyeControls) do
            dyeControl.highlightTexture:SetHidden(not isHighlighted)
        end
    end
end

function ZO_Dyeing_Keyboard:ToggleSavedSetHightlight(dyeSetIndex, isHighlighted, dyeChannel)
    if dyeSetIndex ~= nil then
        local slotControl = self.savedSets[dyeSetIndex]
        self:ToggleSavedSetHightlightBySlotControl(slotControl, isHighlighted, dyeChannel)
    else
        for _, slotControl in ipairs(self.savedSets) do
            self:ToggleSavedSetHightlightBySlotControl(slotControl, isHighlighted, dyeChannel)
        end
    end
end

do
    local USE_SEARCH_RESULTS = true

    function ZO_Dyeing_Keyboard:LayoutDyes()
        self.dyeLayoutDirty = false

        local _, _, dyeIdToSwatch = ZO_Dyeing_LayoutSwatches(ZO_DYEING_MANAGER:GetShowLocked(), ZO_DYEING_MANAGER:GetSortStyle(), self.swatchPool, self.headerPool, SWATCHES_LAYOUT_OPTIONS, self.pane, USE_SEARCH_RESULTS)
        self.dyeIdToSwatch = dyeIdToSwatch

        local anyDyesToSwatch = (next(dyeIdToSwatch) ~= nil)
        self.noDyesLabel:SetHidden(anyDyesToSwatch)
        if self.selectedDyeId then
            self:SetSelectedDyeId(self.selectedDyeId, BECAUSE_OF_REBUILD)
        end
    end
end

function ZO_Dyeing_Keyboard:AttemptExit(exitingToAchievementId)
    local exitDestinationData = { achievementId = exitingToAchievementId, }
    ZO_RESTYLE_STATION_KEYBOARD:AttemptExit(exitDestinationData)
end

function ZO_Dyeing_Keyboard:RefreshSavedSet(dyeSetIndex)
    local savedSetSwatch = self.savedSets[dyeSetIndex]
    for dyeChannel, dyeControl in ipairs(savedSetSwatch.dyeControls) do
        local currentDyeId = select(dyeChannel, GetSavedDyeSetDyes(dyeSetIndex))
        ZO_DyeingUtils_SetSlotDyeSwatchDyeId(dyeControl, currentDyeId)
    end
end

function ZO_Dyeing_Keyboard:RefreshSavedSets()
    for dyeSetIndex in ipairs(self.savedSets) do
        self:RefreshSavedSet(dyeSetIndex)
    end
end

function ZO_Dyeing_Keyboard:GetSwatchControlFromDyeId(dyeId)
    local swatchObject = self.dyeIdToSwatch[dyeId]
    if swatchObject then
        return swatchObject.control
    end
end

function ZO_Dyeing_Keyboard:GetActiveTool()
    if self.fragment:IsShowing() then
        return self.activeTool
    end
    return nil
end

function ZO_Dyeing_Keyboard:OnPendingDyesChanged(restyleSlotData)
    ZO_RESTYLE_STATION_KEYBOARD:OnPendingDyesChanged(restyleSlotData)
end

function ZO_Dyeing_Keyboard_OnInitialized(control)
    ZO_DYEING_KEYBOARD = ZO_Dyeing_Keyboard:New(control)
end