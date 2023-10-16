ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_DIMENSIONS_KEYBOARD_X = 74
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_DIMENSIONS_KEYBOARD_Y = 74
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ICON_DIMENSIONS_KEYBOARD_X = 64
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ICON_DIMENSIONS_KEYBOARD_Y = 64
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_PADDING_KEYBOARD_X = 0
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_PADDING_KEYBOARD_Y = 0
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ROW_HEIGHT_KEYBOARD = ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_DIMENSIONS_KEYBOARD_Y + ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_PADDING_KEYBOARD_Y
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_WIDTH_KEYBOARD = ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_DIMENSIONS_KEYBOARD_X + ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_PADDING_KEYBOARD_X
ZO_ENDLESS_DUNGEON_BUFF_GRID_HEADER_ROW_HEIGHT_KEYBOARD = 32
ZO_ENDLESS_DUNGEON_BUFF_GRID_SECTION_PADDING_KEYBOARD_Y = 20
ZO_ENDLESS_DUNGEON_BUFF_TRACKER_GRID_LIST_MAX_WIDTH_KEYBOARD = 390

ZO_EndlessDungeonBuffTracker_Keyboard = ZO_EndlessDungeonBuffTracker_Shared:Subclass()

function ZO_EndlessDungeonBuffTracker_Keyboard:Initialize(...)
    ZO_EndlessDungeonBuffTracker_Shared.Initialize(self, ...)

    local scene = self:GetScene()
    ENDLESS_DUNGEON_BUFF_TRACKER_SCENE_KEYBOARD = scene
    SYSTEMS:RegisterKeyboardRootScene("endlessDungeonBuffTracker", scene)
end

function ZO_EndlessDungeonBuffTracker_Keyboard:InitializeControls()
    ZO_EndlessDungeonBuffTracker_Shared.InitializeControls(self)

    local scene = self:GetScene()
    scene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW_NO_KEYBIND_BACKGROUND_WINDOW)
    scene:AddFragment(MINIMIZE_CHAT_FRAGMENT)

    ApplyTemplateToControl(self.switchToSummaryKeybindButton, "ZO_KeybindButton_Keyboard_Template")
    ApplyTemplateToControl(self.closeKeybindButton, "ZO_KeybindButton_Keyboard_Template")
end

function ZO_EndlessDungeonBuffTracker_Keyboard:InitializeGridList()
    ZO_EndlessDungeonBuffTracker_Shared.InitializeGridList(self, ZO_GridScrollList_Keyboard, "ZO_EndDunBuffTrackerGridEntry_Keyboard", "ZO_EndDunBuffTrackerGridHeader_Keyboard")

    self.entryDataObjectPool = ZO_EntryDataPool:New(ZO_EntryData)
    local HIDE_CALLBACK = nil
    local gridList = self.gridList
    gridList:AddEntryTemplate("ZO_EndDunBuffTrackerGridEntry_Keyboard", ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_DIMENSIONS_KEYBOARD_X, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_DIMENSIONS_KEYBOARD_Y, ZO_GetCallbackForwardingFunction(self, self.SetupGridEntry), HIDE_CALLBACK, ZO_GetCallbackForwardingFunction(self, self.ResetGridEntry), ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_PADDING_KEYBOARD_X, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_PADDING_KEYBOARD_Y)
    gridList:AddHeaderTemplate("ZO_EndDunBuffTrackerGridHeader_Keyboard", ZO_ENDLESS_DUNGEON_BUFF_GRID_HEADER_ROW_HEIGHT_KEYBOARD, ZO_EndlessDungeonBuffTracker_Shared.SetupGridHeader)
    gridList:SetAutoFillEntryTemplate("ZO_EndDunBuffTrackerEmptyGridEntry_Keyboard")
    gridList:SetHeaderPrePadding(ZO_ENDLESS_DUNGEON_BUFF_GRID_SECTION_PADDING_KEYBOARD_Y)
end

function ZO_EndlessDungeonBuffTracker_Keyboard:OnHiding()
    ZO_EndlessDungeonBuffTracker_Shared.OnHiding(self)

    ClearTooltip(AbilityTooltip)
end

function ZO_EndlessDungeonBuffTracker_Keyboard:OnGridEntryMouseEnter(control)
    self:SetGridEntryFocus(control, true)
    local controlLeft = control:GetLeft()
    local parentLeft = self.control:GetLeft()
    local OFFSET_MARGIN_X = 15
    local offsetX = -(controlLeft - parentLeft + OFFSET_MARGIN_X)
    InitializeTooltip(AbilityIconTooltip, control, RIGHT, offsetX, 0, LEFT)
    AbilityIconTooltip:SetAbilityId(control.abilityId)
end

function ZO_EndlessDungeonBuffTracker_Keyboard:OnGridEntryMouseExit(control)
    self:SetGridEntryFocus(control, false)
    ClearTooltip(AbilityIconTooltip)
end

function ZO_EndlessDungeonBuffTracker_Keyboard:GetSceneName()
    return "endlessDungeonBuffTrackerKeyboard"
end

function ZO_EndlessDungeonBuffTracker_Keyboard:UpdateGridListDimensions(numVerseEntries, numVisionEntries)
    ZO_EndlessDungeonBuffTracker_Shared.UpdateGridListDimensions(self, numVerseEntries, numVisionEntries, ZO_ENDLESS_DUNGEON_BUFF_TRACKER_GRID_LIST_MAX_WIDTH_KEYBOARD, ZoFontWinH3, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_WIDTH_KEYBOARD, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ROW_HEIGHT_KEYBOARD, ZO_ENDLESS_DUNGEON_BUFF_GRID_HEADER_ROW_HEIGHT_KEYBOARD, ZO_ENDLESS_DUNGEON_BUFF_GRID_SECTION_PADDING_KEYBOARD_Y)
end

function ZO_EndlessDungeonBuffTracker_Keyboard.OnControlInitialized(control)
    ENDLESS_DUNGEON_BUFF_TRACKER_KEYBOARD = ZO_EndlessDungeonBuffTracker_Keyboard:New(control)
end