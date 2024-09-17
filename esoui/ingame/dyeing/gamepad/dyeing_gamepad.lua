ZO_DYE_TOOL_GRID_ENTRY_DIMENTIONS = 64

--[[ ZO_Dyeing_Slots_Panel_Gamepad ]]--

ZO_Dyeing_Slots_Panel_Gamepad = ZO_Restyle_Station_Helper_Panel_Gamepad:Subclass()

function ZO_Dyeing_Slots_Panel_Gamepad:New(...)
    return ZO_Restyle_Station_Helper_Panel_Gamepad.New(self, ...)
end

function ZO_Dyeing_Slots_Panel_Gamepad:Initialize(control, owner)
    self.control = control
    self.owner = owner
    self.selectedSetIndex = 1

    ZO_Restyle_Station_Helper_Panel_Gamepad.Initialize(self)

    self:InitializeKeybindDescriptors()
    self:InitializeTooltip()
    self:InitializeTools()
    self:InitializeDyesGrid()
    self:InitializeMultiFocusArea()

    local function UpdateUnlockedDyes()
        if GAMEPAD_RESTYLE_STATION_SCENE:IsShowing() then
            self:UpdateDyesGrid()
        end
    end

    ZO_DYEING_MANAGER:RegisterCallback("UpdateDyeLists", UpdateUnlockedDyes)
    ZO_DYEING_MANAGER:RegisterCallback("UpdateDyeData", UpdateUnlockedDyes)

    GAMEPAD_DYEING_SLOTS_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(control)
end

function ZO_Dyeing_Slots_Panel_Gamepad:OnShowing()
    self:UpdateDyesGrid()
end

function ZO_Dyeing_Slots_Panel_Gamepad:Activate()
    ZO_Restyle_Station_Helper_Panel_Gamepad.Activate(self)
    self:ActivateCurrentFocus()
    DIRECTIONAL_INPUT:Activate(self, self.control)
    self.selectedDye = nil
end

function ZO_Dyeing_Slots_Panel_Gamepad:Deactivate()
    ZO_Restyle_Station_Helper_Panel_Gamepad.Deactivate(self)
    self:DeactivateCurrentFocus()
    DIRECTIONAL_INPUT:Deactivate(self)
end

function ZO_Dyeing_Slots_Panel_Gamepad:InitializeKeybindDescriptors()
    local function HandleMultiFocusAreaBack()
        self:EndSelection()
    end

    -- Apply
    local apply = ZO_RESTYLE_STATION_GAMEPAD:CreateApplyKeybind(self)

    -- Options
    local options = ZO_RESTYLE_STATION_GAMEPAD:CreateOptionsKeybind()

    -- Undo All
    local undoAll = ZO_RESTYLE_STATION_GAMEPAD:CreateUndoKeybind(self)

    -- Randomize
    local randomize = ZO_RESTYLE_STATION_GAMEPAD:CreateRandomizeKeybind(self)

    -- Tools List
    self.toolsKeybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(HandleMultiFocusAreaBack),

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:HandleDyeToolSelectAction()
            end
        },

        apply,
        options,
        undoAll,
        randomize,
    }

    -- Dye List
    self.dyeKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(HandleMultiFocusAreaBack),

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:HandleDyeSelectAction()
            end
        },

        apply,
        options,
        undoAll,
        randomize,
    }
end

function ZO_Dyeing_Slots_Panel_Gamepad:InitializeTooltip()
    local tooltip = self.control:GetNamedChild("Tooltip")
    self.tooltipImage = tooltip:GetNamedChild("Image")
    self.tooltipSwatch = tooltip:GetNamedChild("Swatch")
    self.tooltipContents = tooltip:GetNamedChild("Contents")
    ZO_Tooltip:Initialize(self.tooltipContents, ZO_GAMEPAD_DYEING_TOOLTIP_STYLES)

    self.tooltipSwatch:SetHidden(true)
    self.tooltipImage:SetHidden(true)
end

function ZO_Dyeing_Slots_Panel_Gamepad:InitializeTools()
    local toolsGrid = self.control:GetNamedChild("ToolsGrid")

    self.dyeTool = ZO_DyeingToolDye:New(self)
    self.fillTool = ZO_DyeingToolFill:New(self)
    self.eraseTool = ZO_DyeingToolErase:New(self)
    self.sampleTool = ZO_DyeingToolSample:New(self)
    self.setFillTool = ZO_DyeingToolSetFill:New(self)

    GAMEPAD_DYE_TOOLS_GRID_LIST_FRAGMENT = ZO_FadeSceneFragment:New(toolsGrid)

    self.dyeToolsGridList = ZO_SingleTemplateGridScrollList_Gamepad:New(toolsGrid, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL)

    local function DyeToolGridEntrySetup(control, data, list)
        ZO_DefaultGridEntrySetup(control, data, selected)

        control.selectedBackground:SetHidden(data.tool ~= self.activeTool)
    end

    local function DyeToolGridEntryReset(control)
        ZO_ObjectPool_DefaultResetControl(control)
    end

    local function CreateDyeToolEntryData(tool, tooltipDescription, icon)
        local toolData = ZO_GridSquareEntryData_Shared:New()
        toolData.tool = tool
        toolData.icon = icon
        toolData.tooltipTitle = GetString(tool:GetToolActionString())
        toolData.tooltipDescription = GetString(tooltipDescription)
        toolData.narrationText = function(entryData)
            return { SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.tooltipTitle), SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.tooltipDescription) }
        end
        return toolData
    end

    local HIDE_CALLBACK = nil
    local SPACING_X = 12
    self.dyeToolsGridList:SetGridEntryTemplate("ZO_DyeTool_GridEntry_Template_Gamepad", ZO_DYE_TOOL_GRID_ENTRY_DIMENTIONS, ZO_DYE_TOOL_GRID_ENTRY_DIMENTIONS, DyeToolGridEntrySetup, HIDE_CALLBACK, DyeToolGridEntryReset, SPACING_X, ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD)
    self.dyeToolsGridList:SetHeaderTemplate(ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_GAMEPAD, ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.dyeToolsGridList:SetHeaderPrePadding(ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD)
    self.dyeToolsGridList:SetOnSelectedDataChangedCallback(function(previousData, newData) self:OnDyeToolsGridSelectedDataChanged(previousData, newData) end)
    self.dyeToolsGridList:SetDimsOnDeactivate(true)

    self.dyeToolsGridList:AddEntry(CreateDyeToolEntryData(self.dyeTool, SI_GAMEPAD_DYEING_TOOL_DYE_DESCRIPTION, "EsoUI/Art/Dye/Gamepad/gp_dyes_toolIcon_paint_down.dds"))
    self.dyeToolsGridList:AddEntry(CreateDyeToolEntryData(self.fillTool, SI_GAMEPAD_DYEING_TOOL_DYE_ALL_DESCRIPTION, "EsoUI/Art/Dye/Gamepad/gp_dyes_toolIcon_fill_down.dds"))
    self.dyeToolsGridList:AddEntry(CreateDyeToolEntryData(self.eraseTool, SI_GAMEPAD_DYEING_TOOL_ERASE_DESCRIPTION, "EsoUI/Art/Dye/Gamepad/gp_dyes_toolIcon_erase_down.dds"))
    self.dyeToolsGridList:AddEntry(CreateDyeToolEntryData(self.sampleTool, SI_GAMEPAD_DYEING_TOOL_COPY_COLOR_DESCRIPTION, "EsoUI/Art/Dye/Gamepad/gp_dyes_toolIcon_sample_down.dds"))
    self.dyeToolsGridList:AddEntry(CreateDyeToolEntryData(self.setFillTool, SI_GAMEPAD_DYEING_TOOL_SET_FILL_DESCRIPTION, "EsoUI/Art/Dye/Gamepad/gp_dyes_toolIcon_setFill_down.dds"))

    self.dyeToolsGridList:CommitGridList()

    self:SwitchToTool(self.dyeTool)
end

function ZO_Dyeing_Slots_Panel_Gamepad:InitializeDyesGrid()
    local dyesGrid = self.control:GetNamedChild("DyesGrid")
    GAMEPAD_DYES_GRID_LIST_FRAGMENT = ZO_FadeSceneFragment:New(dyesGrid)

    self.dyeGridList = ZO_SingleTemplateGridScrollList_Gamepad:New(dyesGrid, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL)

    local function DyeSwatchGridEntrySetup(control, data, list)
        control:SetColor(ZO_DYEING_SWATCH_INDEX, data.r, data.g, data.b)
        control:SetSurfaceHidden(ZO_DYEING_LOCK_INDEX, data.known)
        control:SetSurfaceHidden(ZO_DYEING_NEW_INDEX, not data:IsNew())
        data:SetControl(control)
    end

    local function DyeSwatchGridEntryReset(control)
        ZO_ObjectPool_DefaultResetControl(control)
    end

    local DYE_SWATCH_DIMENSIONS = 43
    local HIDE_CALLBACK = nil
    local SPACING_XY = 0
    local CENTER_ENTRIES = true
    -- the values sent for control dimensions are the scaled up size so that when the control is scaled up, they do not clip with the scroll mask
    self.dyeGridList:SetGridEntryTemplate("ZO_DyeingSwatch_Gamepad", DYE_SWATCH_DIMENSIONS, DYE_SWATCH_DIMENSIONS, DyeSwatchGridEntrySetup, HIDE_CALLBACK, DyeSwatchGridEntryReset, SPACING_XY, SPACING_XY, CENTER_ENTRIES)
    self.dyeGridList:SetHeaderTemplate(ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_GAMEPAD, ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_HEIGHT, ZO_DefaultGridHeaderSetup)
    self.dyeGridList:SetHeaderPrePadding(ZO_GRID_SCROLL_LIST_DEFAULT_SPACING_GAMEPAD * 2)
    self.dyeGridList:SetOnSelectedDataChangedCallback(function(previousData, newData) self:OnDyesGridSelectedDataChanged(previousData, newData) end)
    self.dyeGridList:SetDimsOnDeactivate(true)
end

function ZO_Dyeing_Slots_Panel_Gamepad:InitializeMultiFocusArea()
    local FOREGO_DIRECTIONAL_INPUT = true

    local function SearchActivateCallback()
        self.dyeToolsGridList:Activate(FOREGO_DIRECTIONAL_INPUT)
    end

    local function SearchDeactivateCallback()
        self.dyeToolsGridList:Deactivate(FOREGO_DIRECTIONAL_INPUT)
    end
    self.toolsArea = ZO_GamepadInteractiveSortFilterFocusArea_Grid:New(self, SearchActivateCallback, SearchDeactivateCallback)
    self.toolsArea:SetKeybindDescriptor(self.toolsKeybindStripDescriptor)
    self.toolsArea.gridList = self.dyeToolsGridList

    local function GridActivateCallback()
        self.dyeGridList:Activate(FOREGO_DIRECTIONAL_INPUT)
    end

    local function GridDeactivateCallback()
        self.dyeGridList:Deactivate(FOREGO_DIRECTIONAL_INPUT)
    end
    self.gridArea = ZO_GamepadInteractiveSortFilterFocusArea_Grid:New(self, GridActivateCallback, GridDeactivateCallback)
    self.gridArea:SetKeybindDescriptor(self.dyeKeybindStripDescriptor)
    self.gridArea.gridList = self.dyeGridList

    self:AddNextFocusArea(self.toolsArea)
    self:AddNextFocusArea(self.gridArea)

    local DONT_ACTIVATE_FOCUS_AREA = false
    self:SelectFocusArea(self.gridArea, DONT_ACTIVATE_FOCUS_AREA)
end

function ZO_Dyeing_Slots_Panel_Gamepad:OnDyesGridSelectedDataChanged(previousData, newData)
    if previousData and previousData.control then
        if previousData:IsNew() then 
            previousData:SetNew(false)
        end
        previousData.mousedOver = false
        previousData:UpdateSelectedState()
    end

    if newData then
        if newData.control then
            newData.mousedOver = true
            newData:UpdateSelectedState()
        end
        -- Only update the tooltip on newData existing so that we can
        -- show it while we are looking at the parametric list
        self:UpdateToolTip()
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:OnDyeToolsGridSelectedDataChanged(previousData, newData)
    if newData then
        self:UpdateToolTip()
    end
end

do
    local CAN_SELECT_LOCKED = true

    function ZO_Dyeing_Slots_Panel_Gamepad:UpdateDyesGrid()
        local dyeGridList = self.dyeGridList
        dyeGridList:ClearGridList()
    
        local sortStyle = ZO_DYEING_MANAGER:GetSortStyle()
        local showLocked = ZO_DYEING_MANAGER:GetShowLocked()
        local tempTable = {}

        local dyesBySortStyleCategory = (sortStyle == ZO_DYEING_SORT_STYLE_RARITY) and ZO_DYEING_MANAGER:GetPlayerDyesByRarity() or ZO_DYEING_MANAGER:GetPlayerDyesByHueCategory()

        for sortStyleCategory, dyes in pairs(dyesBySortStyleCategory) do
            local gridHeaderName
            if sortStyle == ZO_DYEING_SORT_STYLE_RARITY then
                gridHeaderName = GetString("SI_DYERARITY", sortStyleCategory)
            elseif sortStyle == ZO_DYEING_SORT_STYLE_HUE then
                gridHeaderName = GetString("SI_DYEHUECATEGORY", sortStyleCategory)
            end

            for _, dyeInfo in ipairs(dyes) do
                if dyeInfo.known or showLocked then
                    local swatchObject = ZO_DyeingSwatch_Shared:New(self, CAN_SELECT_LOCKED)
                    swatchObject:SetDataSource(dyeInfo)
                    swatchObject.gridHeaderName = gridHeaderName
                    swatchObject.categoryOrder = sortStyleCategory
                    swatchObject.color = ZO_ColorDef:New(dyeInfo.r, dyeInfo.g, dyeInfo.b)
                    table.insert(tempTable, swatchObject)
                end
            end
        end

        table.sort(tempTable, ZO_DyeSwatchesGridSort)

        for i, entry in ipairs(tempTable) do
            dyeGridList:AddEntry(entry)
        end

        dyeGridList:CommitGridList()
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:RebuildList()
    self:UpdateDyesGrid()
    self:UpdateActiveFocusKeybinds()
end

function ZO_Dyeing_Slots_Panel_Gamepad:UpdateToolTip()
    if self.toolsArea:IsFocused() then
        local selectedTool = self.dyeToolsGridList:GetSelectedData()
        self:LayoutToolTooltip(selectedTool)
    elseif self.gridArea:IsFocused() then
        local selectedDye = self.dyeGridList:GetSelectedData()
        self:LayoutDyeTooltip(selectedDye)
    end
end

do
    local IS_DYEABLE = true
    function ZO_Dyeing_Slots_Panel_Gamepad:LayoutDyeTooltip(dyeData)
        self.tooltipContents:ClearLines()
        self.tooltipImage:SetHidden(true)
        self.tooltipSwatch:SetHidden(true)
   
        local titleText = dyeData.dyeName
        local bodyText = ZO_Dyeing_GetAchievementText(dyeData.known, dyeData.achievementId)
        ZO_DyeingUtils_SetSlotDyeSwatchDyeId(self.tooltipSwatch, dyeData.dyeId, IS_DYEABLE)
        self.tooltipSwatch:SetHidden(false)

        self:LayoutTooltipText(titleText, bodyText)
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:LayoutToolTooltip(toolData)
    self.tooltipContents:ClearLines()
    self.tooltipImage:SetHidden(true)
    self.tooltipSwatch:SetHidden(true)

    local titleText = toolData.tooltipTitle
    local bodyText = toolData.tooltipDescription
    self.tooltipImage:SetHidden(false)
    self.tooltipImage:SetTexture(toolData.icon)

    self:LayoutTooltipText(titleText, bodyText)
end

function ZO_Dyeing_Slots_Panel_Gamepad:LayoutTooltipText(titleText, bodyText)
    self.tooltipContents:AddLine(titleText, nil, self.tooltipContents:GetStyle("title"))
    self.tooltipContents:AddLine(bodyText, nil, self.tooltipContents:GetStyle("body"))
end

function ZO_Dyeing_Slots_Panel_Gamepad:HandleDyeSelectAction()
    local selectedData = self.dyeGridList:GetSelectedData()
    if selectedData and selectedData.known then
        if not self.activeTool:HasSwatchSelection() then
            self:SwitchToTool(self.dyeTool)
        end

        self.selectedDye = selectedData.dyeId
        self:FireCallbacks("DyeSelected")
    end
end

function ZO_Dyeing_Slots_Panel_Gamepad:HandleDyeToolSelectAction()
    local selectedToolData = self.dyeToolsGridList:GetSelectedData()
    self:SwitchToTool(selectedToolData.tool)
    self.dyeToolsGridList:RefreshGridList()
end

function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToTool(newTool)
    local lastTool = self.activeTool
    if lastTool then
        lastTool:Deactivate()
    end

    self.activeTool = newTool
    if newTool then
        self.activeTool:Activate(lastTool, self.suppressToolSounds)
        self.suppressToolSounds = true
    end

    self.dyeToolsGridList:RefreshGridList()

    if newTool:HasSwatchSelection() then
        self:SelectFocusArea(self.gridArea)
    end

    self:FireCallbacks("ToolSelected")
end

function ZO_Dyeing_Slots_Panel_Gamepad:GetActiveDyeTool()
    return self.activeTool
end

function ZO_Dyeing_Slots_Panel_Gamepad:GetSelectedDyeId()
    return self.selectedDye
end

function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToSavedSet(index)
    self:SetSelectedSavedSetIndex(index)
    self:SwitchToTool(self.setFillTool)
    local toolData = self:GetDataForTool(self.setFillTool)
    self:LayoutToolTooltip(toolData)
end

function ZO_Dyeing_Slots_Panel_Gamepad:OnPendingDyesChanged(restyleSlotData)
    self:FireCallbacks("PendingDyesChanged", restyleSlotData)
end

function ZO_Dyeing_Slots_Panel_Gamepad:SwitchToDyeingWithDyeId(dyeId)
    self:SwitchToTool(self.dyeTool)
    self.selectedDye = dyeId
    local DONT_ACTIVATE_FOCUS_AREA = false
    self:SelectFocusArea(self.gridArea, DONT_ACTIVATE_FOCUS_AREA)
    local dyeDataEntry = self:GetDataEntryForDyeId(dyeId)
    local dyeData = dyeDataEntry.data
    local NO_CALLBACK = nil
    local ANIMATE_INSTANTLY = true
    self.dyeGridList:ScrollDataToCenter(dyeData, NO_CALLBACK, ANIMATE_INSTANTLY)
    self:LayoutDyeTooltip(dyeData)
    self:FireCallbacks("DyeSelected")
end

function ZO_Dyeing_Slots_Panel_Gamepad:OnSavedSetSlotChanged(dyeSetIndex)
    self:FireCallbacks("SavedSetSlotChanged", dyeSetIndex)
end

function ZO_Dyeing_Slots_Panel_Gamepad:SetSelectedSavedSetIndex(setIndex)
    self.selectedSetIndex = setIndex
end

function ZO_Dyeing_Slots_Panel_Gamepad:GetSelectedSavedSetIndex()
    return self.selectedSetIndex
end

function ZO_Dyeing_Slots_Panel_Gamepad:GetDataForTool(tool)
    local allToolData = self.dyeToolsGridList:GetData()
    for _, toolData in ipairs(allToolData) do
        if toolData.data.tool == tool then
            return toolData.data
        end
    end

    return nil
end

function ZO_Dyeing_Slots_Panel_Gamepad:GetDataEntryForDyeId(dyeId)
    local allDyeEntryData = self.dyeGridList:GetData()
    for _, dyeEntryData in ipairs(allDyeEntryData) do
        if dyeEntryData.data.dyeId == dyeId then
            return dyeEntryData
        end
    end

    return nil
end

-- XML functions --

function ZO_Dyeing_Slots_Panel_Gamepad_OnInitialize(control)
    ZO_DYEING_PANEL_GAMEPAD = ZO_Dyeing_Slots_Panel_Gamepad:New(control)
end

function ZO_Dyeing_Slot_Initialize(self)
    self.swatchTexture = self:GetNamedChild("Swatch")
    self.background = self:GetNamedChild("Background")
    self.invalidTexture = self:GetNamedChild("BadSlot")
    self.edgeFrame = self:GetNamedChild("EdgeFrame")
end