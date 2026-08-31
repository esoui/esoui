ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_DIMENSIONS_GAMEPAD_X = 230
ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_DIMENSIONS_GAMEPAD_Y = 210
ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_PADDING_GAMEPAD_X = 35
ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_PADDING_GAMEPAD_Y = 35
ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_ROW_HEIGHT_GAMEPAD = ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_DIMENSIONS_GAMEPAD_Y + ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_PADDING_GAMEPAD_Y
ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_WIDTH_GAMEPAD = ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_DIMENSIONS_GAMEPAD_X + ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_PADDING_GAMEPAD_X
ZO_GENERIC_SELECTOR_GRID_LIST_MAX_WIDTH_GAMEPAD = 800

ZO_GenericSelector_Gamepad = ZO_GenericSelector_Shared:Subclass()

local TOOLTIP_MODES =
{
    CHOICE = 1,
    REWARD = 2,
}

function ZO_GenericSelector_Gamepad:Initialize(...)
    ZO_GenericSelector_Shared.Initialize(self, ...)

    GENERIC_SELECTOR_SCENE_GAMEPAD = self:GetScene()
    SYSTEMS:RegisterGamepadRootScene("genericSelector", GENERIC_SELECTOR_SCENE_GAMEPAD)

    self.tooltipMode = TOOLTIP_MODES.CHOICE
end

function ZO_GenericSelector_Gamepad:InitializeControls()
    ZO_GenericSelector_Shared.InitializeControls(self)

    local scene = self:GetScene()
    scene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW_NO_KEYBIND_BACKGROUND_WINDOW)
    scene:AddFragment(MINIMIZE_CHAT_FRAGMENT)
    scene:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
    scene:AddFragment(KEYBIND_STRIP_GAMEPAD_BACKDROP_FRAGMENT)
end

function ZO_GenericSelector_Gamepad:InitializeKeybindStripDescriptor()
    ZO_GenericSelector_Shared.InitializeKeybindStripDescriptor(self)

    self.keybindStripDescriptor.alignment = KEYBIND_STRIP_ALIGN_LEFT
    table.insert(self.keybindStripDescriptor, 
    {
        name = GetString(SI_GENERIC_SELECTOR_REWARDS_TOGGLE_GAMEPAD),
        keybind = "UI_SHORTCUT_SECONDARY",
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,
        callback = function()
            self.tooltipMode = self.tooltipMode == TOOLTIP_MODES.CHOICE and TOOLTIP_MODES.REWARD or TOOLTIP_MODES.CHOICE
            local index = nil
            local data = self.gridList:GetSelectedData()
            if data.dataSource and data.dataSource.dataSource then
                index = data.dataSource.dataSource.index
            end
            self:RefreshTooltip(index)
            SCREEN_NARRATION_MANAGER:QueueGridListEntry(self.gridList)
        end,
        visible = function()
            return GetNumGenericSelectorRewards() > 0
        end,
    })
end

function ZO_GenericSelector_Gamepad:GetCloseKeybindDescriptor()
    return self:CreateCloseKeybindDescriptor("UI_SHORTCUT_TERTIARY")
end

function ZO_GenericSelector_Gamepad:InitializeGridList()
    self.gridEntryTemplateName = "ZO_GenericSelectorItem_Gamepad"
    self.entryDataObjectPool = ZO_EntryDataPool:New(ZO_EntryData)

    local NO_AUTO_FILL_ROWS = nil
    local RESIZE_TO_FIT_COLUMN_MAX = 5
    local RESIZE_TO_FIT_ROW_MAX = 6
    self.gridList = ZO_GridScrollList_Gamepad:New(self.gridListControl, "ZO_GridScrollList_Highlight_Gamepad", NO_AUTO_FILL_ROWS, RESIZE_TO_FIT_COLUMN_MAX, RESIZE_TO_FIT_ROW_MAX)

    local NO_HIDE_CALLBACK = nil
    local gridList = self.gridList
    gridList:AddEntryTemplate("ZO_GenericSelectorItem_Gamepad", ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_DIMENSIONS_GAMEPAD_X, ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_DIMENSIONS_GAMEPAD_Y, ZO_GetCallbackForwardingFunction(self, self.SetupGridEntry), NO_HIDE_CALLBACK, ZO_GetCallbackForwardingFunction(self, self.ResetGridEntry), ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_PADDING_GAMEPAD_X, ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_PADDING_GAMEPAD_Y)
    gridList:SetAutoFillEntryTemplate("ZO_GenericSelectorEmptyItem_Gamepad")
    gridList:SetOnSelectedDataChangedCallback(ZO_GetCallbackForwardingFunction(self, self.OnGridEntrySelected))
    gridList:SetHeaderNarrationFunction(function()
        local narrations = {}
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.titleText))
        return narrations
    end)
end

function ZO_GenericSelector_Gamepad:GetSceneName()
    return "genericSelectorGamepad"
end

function ZO_GenericSelector_Gamepad:OnHiding()
    ZO_GenericSelector_Shared.OnHiding(self)

    self.gridList:Deactivate()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_GenericSelector_Gamepad:OnShowing()
    ZO_GenericSelector_Shared.OnShowing(self)

    self.gridList:Activate()
    local ANIMATE_INSTANTLY = true
    local SCROLL_INTO_VIEW = true
    self.gridList:RefreshSelection(ANIMATE_INSTANTLY, SCROLL_INTO_VIEW)
end

function ZO_GenericSelector_Gamepad:ToggleItemSelected(itemControl)
    ZO_GenericSelector_Shared.ToggleItemSelected(self, itemControl)
    local index = nil
    local data = self.gridList:GetSelectedData()
    if data.dataSource and data.dataSource.dataSource then
        index = data.dataSource.dataSource.index
    end
    self:RefreshTooltip(index)
end

function ZO_GenericSelector_Gamepad:RefreshTooltip(index)
    if index and self.tooltipMode == TOOLTIP_MODES.CHOICE then
        GAMEPAD_TOOLTIPS:LayoutGenericSelectorItemTooltip(GAMEPAD_RIGHT_TOOLTIP, index)
    elseif self.tooltipMode == TOOLTIP_MODES.REWARD then
        GAMEPAD_TOOLTIPS:LayoutGenericSelectorRewardsTooltip(GAMEPAD_RIGHT_TOOLTIP)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_GenericSelector_Gamepad:RefreshTitle()
    ZO_GenericSelector_Shared.RefreshTitle(self)
    self.titleText = self.titleLabel:GetText()
end

function ZO_GenericSelector_Gamepad:OnGridEntrySelected(previousData, currentData)
    if previousData then
        self:SetGridEntryFocus(previousData.dataEntry.control, false)
    end

    if currentData then
        self:SetGridEntryFocus(currentData.dataEntry.control, true)
        if currentData.dataSource and currentData.dataSource.dataSource then
            self:RefreshTooltip(currentData.dataSource.dataSource.index)
        end
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
    self:RefreshKeybinds()
end

function ZO_GenericSelector_Gamepad.OnControlInitialized(control)
    GENERIC_SELECTOR_GAMEPAD = ZO_GenericSelector_Gamepad:New(control)
end