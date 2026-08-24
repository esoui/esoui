ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_DIMENSIONS_KEYBOARD_X = 220
ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_DIMENSIONS_KEYBOARD_Y = 185
ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_PADDING_KEYBOARD_X = 20
ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_PADDING_KEYBOARD_Y = 20
ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_ROW_HEIGHT_KEYBOARD = ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_DIMENSIONS_KEYBOARD_Y + ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_PADDING_KEYBOARD_Y
ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_WIDTH_KEYBOARD = ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_DIMENSIONS_KEYBOARD_X + ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_PADDING_KEYBOARD_X
ZO_GENERIC_SELECTOR_GRID_LIST_MAX_WIDTH_KEYBOARD = 800

ZO_GenericSelector_Keyboard = ZO_GenericSelector_Shared:Subclass()

function ZO_GenericSelector_Keyboard:Initialize(...)
    ZO_GenericSelector_Shared.Initialize(self, ...)

    GENERIC_SELECTOR_SCENE_KEYBOARD = self:GetScene()
    SYSTEMS:RegisterKeyboardRootScene("genericSelector", GENERIC_SELECTOR_SCENE_KEYBOARD)
end

function ZO_GenericSelector_Keyboard:OnShowing()
    ZO_GenericSelector_Shared.OnShowing(self)
    if ZO_GENERIC_SELECTOR_REWARDS:ShouldShow() then
        ZO_GENERIC_SELECTOR_REWARDS:Show()
    end
end

function ZO_GenericSelector_Keyboard:OnHiding()
    ZO_GenericSelector_Shared.OnHiding(self)
    ZO_GENERIC_SELECTOR_REWARDS:Hide()
end

function ZO_GenericSelector_Keyboard:InitializeControls()
    ZO_GenericSelector_Shared.InitializeControls(self)

    local scene = self:GetScene()
    scene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW_NO_KEYBIND_BACKGROUND_WINDOW)
    scene:AddFragment(MINIMIZE_CHAT_FRAGMENT)
end

function ZO_GenericSelector_Keyboard:InitializeGridList()
    self.gridEntryTemplateName = "ZO_GenericSelectorItem_Keyboard"
    self.entryDataObjectPool = ZO_EntryDataPool:New(ZO_EntryData)

    local NO_AUTO_FILL_ROWS = nil
    local RESIZE_TO_FIT_COLUMN_MAX = 3
    local RESIZE_TO_FIT_ROW_MAX = 3
    self.gridList = ZO_GridScrollList_Keyboard:New(self.gridListControl, NO_AUTO_FILL_ROWS, RESIZE_TO_FIT_COLUMN_MAX, RESIZE_TO_FIT_ROW_MAX)

    local NO_HIDE_CALLBACK = nil
    local gridList = self.gridList
    gridList:AddEntryTemplate("ZO_GenericSelectorItem_Keyboard", ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_DIMENSIONS_KEYBOARD_X, ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_DIMENSIONS_KEYBOARD_Y, ZO_GetCallbackForwardingFunction(self, self.SetupGridEntry), NO_HIDE_CALLBACK, ZO_GetCallbackForwardingFunction(self, self.ResetGridEntry), ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_PADDING_KEYBOARD_X, ZO_GENERIC_SELECTOR_ITEM_GRID_ENTRY_PADDING_KEYBOARD_Y)
    gridList:SetAutoFillEntryTemplate("ZO_GenericSelectorEmptyItem_Keyboard")
end

function ZO_GenericSelector_Keyboard:ToggleItemSelected(itemControl)
    ZO_GenericSelector_Shared.ToggleItemSelected(self, itemControl)
    if ZO_GENERIC_SELECTOR_REWARDS:ShouldShow() then
        ZO_GENERIC_SELECTOR_REWARDS:SetupRewards()
    end
end

function ZO_GenericSelector_Keyboard:OnGridEntryMouseEnter(itemControl)
    self:SetGridEntryFocus(itemControl, true)
    self:RefreshKeybinds()
    if itemControl.dataEntry.data then
        InitializeTooltip(InformationTooltip, self.control, RIGHT, -10, 0, LEFT)
        InformationTooltip:SetGenericSelectorChoice(itemControl.dataEntry.data.index)
    end
end

function ZO_GenericSelector_Keyboard:OnGridEntryMouseExit(itemControl)
    self:SetGridEntryFocus(itemControl, false)
    self:RefreshKeybinds()
    ClearTooltip(InformationTooltip)
end

function ZO_GenericSelector_Keyboard:OnGridEntryMouseUp(itemControl, button, upInside)
    if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
        self:ToggleItemSelected(itemControl)
    end
end

function ZO_GenericSelector_Keyboard:GetSceneName()
    return "genericSelectorKeyboard"
end

function ZO_GenericSelector_Keyboard.OnControlInitialized(control)
    GENERIC_SELECTOR_KEYBOARD = ZO_GenericSelector_Keyboard:New(control)
end