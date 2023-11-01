ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_DIMENSIONS_GAMEPAD_X = 111
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_DIMENSIONS_GAMEPAD_Y = 111
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ICON_DIMENSIONS_GAMEPAD_X = 96
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ICON_DIMENSIONS_GAMEPAD_Y = 96
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_PADDING_GAMEPAD_X = 0
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_PADDING_GAMEPAD_Y = 0
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ROW_HEIGHT_GAMEPAD = ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_DIMENSIONS_GAMEPAD_Y + ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_PADDING_GAMEPAD_Y
ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_WIDTH_GAMEPAD = ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_DIMENSIONS_GAMEPAD_X + ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_PADDING_GAMEPAD_X
ZO_ENDLESS_DUNGEON_BUFF_GRID_HEADER_ROW_HEIGHT_GAMEPAD = 50
ZO_ENDLESS_DUNGEON_BUFF_GRID_SECTION_PADDING_GAMEPAD_Y = 20
ZO_ENDLESS_DUNGEON_BUFF_TRACKER_GRID_LIST_MAX_WIDTH_GAMEPAD = 655

ZO_EndlessDungeonBuffTracker_Gamepad = ZO_EndlessDungeonBuffTracker_Shared:Subclass()

function ZO_EndlessDungeonBuffTracker_Gamepad:Initialize(...)
    ZO_EndlessDungeonBuffTracker_Shared.Initialize(self, ...)

    local scene = self:GetScene()
    ENDLESS_DUNGEON_BUFF_TRACKER_SCENE_GAMEPAD = scene
    SYSTEMS:RegisterGamepadRootScene("endlessDungeonBuffTracker", scene)
end

-- Overridden from base
function ZO_EndlessDungeonBuffTracker_Gamepad:OnDeferredInitialize()
    ZO_EndlessDungeonBuffTracker_Shared.OnDeferredInitialize(self)

    self.titleText = self.control:GetNamedChild("Title"):GetText()
end

function ZO_EndlessDungeonBuffTracker_Gamepad:InitializeControls()
    ZO_EndlessDungeonBuffTracker_Shared.InitializeControls(self)

    local scene = self:GetScene()
    scene:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_NO_KEYBIND_BACKGROUND_WINDOW)
    scene:AddFragment(MINIMIZE_CHAT_FRAGMENT)

    ApplyTemplateToControl(self.switchToSummaryKeybindButton, "ZO_KeybindButton_Gamepad_Template")
    ApplyTemplateToControl(self.closeKeybindButton, "ZO_KeybindButton_Gamepad_Template")
end

function ZO_EndlessDungeonBuffTracker_Gamepad:InitializeGridList()
    ZO_EndlessDungeonBuffTracker_Shared.InitializeGridList(self, ZO_GridScrollList_Gamepad, "ZO_EndDunBuffTrackerGridEntry_Gamepad", "ZO_EndDunBuffTrackerGridHeader_Gamepad", "ZO_GridScrollList_Highlight_Gamepad")

    self.entryDataObjectPool = ZO_EntryDataPool:New(ZO_EntryData)
    local NO_HIDE_CALLBACK = nil
    local gridList = self.gridList
    gridList:AddHeaderTemplate("ZO_EndDunBuffTrackerGridHeader_Gamepad", ZO_ENDLESS_DUNGEON_BUFF_GRID_HEADER_ROW_HEIGHT_GAMEPAD, ZO_EndlessDungeonBuffTracker_Shared.SetupGridHeader)
    gridList:AddEntryTemplate("ZO_EndDunBuffTrackerGridEntry_Gamepad", ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_DIMENSIONS_GAMEPAD_X, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_DIMENSIONS_GAMEPAD_Y, ZO_GetCallbackForwardingFunction(self, self.SetupGridEntry), NO_HIDE_CALLBACK, ZO_GetCallbackForwardingFunction(self, self.ResetGridEntry), ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_PADDING_GAMEPAD_X, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_PADDING_GAMEPAD_Y)
    gridList:SetAutoFillEntryTemplate("ZO_EndDunBuffTrackerEmptyGridEntry_Gamepad")
    gridList:SetEntryTemplateEqualityFunction("ZO_EndDunBuffTrackerGridEntry_Gamepad", self.CompareGridEntries)
    gridList:SetHeaderPrePadding(ZO_ENDLESS_DUNGEON_BUFF_GRID_SECTION_PADDING_GAMEPAD_Y)
    gridList:SetOnSelectedDataChangedCallback(ZO_GetCallbackForwardingFunction(self, self.OnGridEntrySelected))
    gridList:SetHeaderNarrationFunction(function()
        local narrations = {}
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.titleText))
        if self.progressionNarrationText then
            for _, progressNarration in ipairs(self.progressionNarrationText) do
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(progressNarration))
            end
        end
        if not self.emptyLabel:IsHidden() then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.emptyLabel:GetText()))
        end
        return narrations
    end)
end

function ZO_EndlessDungeonBuffTracker_Gamepad:GetSceneName()
    return "endlessDungeonBuffTrackerGamepad"
end

function ZO_EndlessDungeonBuffTracker_Gamepad:OnHiding()
    ZO_EndlessDungeonBuffTracker_Shared.OnHiding(self)

    self.gridList:Deactivate()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_EndlessDungeonBuffTracker_Gamepad:OnShown()
    ZO_EndlessDungeonBuffTracker_Shared.OnShown(self)

    self.gridList:Activate()
    local ANIMATE_INSTANTLY = true
    local SCROLL_INTO_VIEW = true
    self.gridList:RefreshSelection(ANIMATE_INSTANTLY, SCROLL_INTO_VIEW)
end

function ZO_EndlessDungeonBuffTracker_Gamepad:OnGridEntrySelected(previousData, currentData)
    if currentData then
        self:SetGridEntryFocus(currentData.dataEntry.control, true)

        -- Show the tooltip for the entry that is selected.
        if currentData.abilityId then
            GAMEPAD_TOOLTIPS:LayoutEndlessDungeonBuffAbility(GAMEPAD_RIGHT_TOOLTIP, currentData.abilityId)
            return
        end
    end

    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_EndlessDungeonBuffTracker_Gamepad:UpdateGridListDimensions(numVerseEntries, numVisionEntries)
    ZO_EndlessDungeonBuffTracker_Shared.UpdateGridListDimensions(self, numVerseEntries, numVisionEntries, ZO_ENDLESS_DUNGEON_BUFF_TRACKER_GRID_LIST_MAX_WIDTH_GAMEPAD, ZoFontGamepad36, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_WIDTH_GAMEPAD, ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ROW_HEIGHT_GAMEPAD, ZO_ENDLESS_DUNGEON_BUFF_GRID_HEADER_ROW_HEIGHT_GAMEPAD, ZO_ENDLESS_DUNGEON_BUFF_GRID_SECTION_PADDING_GAMEPAD_Y)
end

-- Overridden from base
function ZO_EndlessDungeonBuffTracker_Gamepad:UpdateProgress()
    ZO_EndlessDungeonBuffTracker_Shared.UpdateProgress(self)

    if ENDLESS_DUNGEON_MANAGER:IsEndlessDungeonStarted() then
        local stageNarration, cycleNarration, arcNarration = ENDLESS_DUNGEON_MANAGER:GetCurrentProgressionNarrationDescriptions()
        self.progressionNarrationText = { arcNarration, cycleNarration, stageNarration }

        if self:IsShowing() then
            local NARRATE_HEADER = true
            SCREEN_NARRATION_MANAGER:QueueGridListEntry(self.gridList, NARRATE_HEADER)
        end
    else
        self.progressionNarrationText = nil
    end
end

function ZO_EndlessDungeonBuffTracker_Gamepad.OnControlInitialized(control)
    ENDLESS_DUNGEON_BUFF_TRACKER_GAMEPAD = ZO_EndlessDungeonBuffTracker_Gamepad:New(control)
end