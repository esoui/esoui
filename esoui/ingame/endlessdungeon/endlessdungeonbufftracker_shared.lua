ZO_ENDLESS_DUNGEON_BUFF_TRACKER_GRID_LIST_OFFSET_X = ZO_SCROLL_BAR_WIDTH * 0.5
ZO_ENDLESS_DUNGEON_BUFF_TRACKER_GRID_LIST_OFFSET_Y = 15
ZO_ENDLESS_DUNGEON_BUFF_TRACKER_GRID_LIST_MAX_ENTRY_ROWS = 5

ZO_EndlessDungeonBuffTracker_Shared = ZO_DeferredInitializingObject:Subclass()

function ZO_EndlessDungeonBuffTracker_Shared:Initialize(control)
    self.control = control
    control.object = self
    self.progressLabel = self.control:GetNamedChild("Progress")
    self.nextInstanceIntervalOffsetS = 0

    local scene = ZO_Scene:New(self:GetSceneName(), SCENE_MANAGER)
    self.scene = scene
    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)

    -- AddOnLoaded is fired before DeferredInitialize will ever be called, so we have to do
    -- this here instead of in InitializeEvents.
    local function OnAddOnLoaded(_, name)
        if name == "ZO_Ingame" then
            self:UpdateProgress()
            EVENT_MANAGER:UnregisterForEvent(self:GetSceneName(), EVENT_ADD_ON_LOADED)
        end
    end
    EVENT_MANAGER:RegisterForEvent(self:GetSceneName(), EVENT_ADD_ON_LOADED, OnAddOnLoaded)

    ZO_DeferredInitializingObject.Initialize(self, scene)
end

function ZO_EndlessDungeonBuffTracker_Shared:OnDeferredInitialize()
    self:InitializeControls()
    self:InitializeGridList()
    self:InitializeKeybindStripDescriptor()
    self:InitializeEvents()
end

function ZO_EndlessDungeonBuffTracker_Shared:InitializeControls()
    self.gridListControl = self.control:GetNamedChild("List")
    self.emptyLabel = self.control:GetNamedChild("Empty")
    self.titleLabel = self.control:GetNamedChild("Title")

    self.keybindContainer = self.control:GetNamedChild("KeybindContainer")
    self.switchToSummaryKeybindButton = self.keybindContainer:GetNamedChild("SwitchToSummary")
    self.closeKeybindButton = self.keybindContainer:GetNamedChild("Close")

    self.keybindContainer:SetHandler("OnRectChanged", function()
        self:UpdateWindowDimensions()
    end)
end

function ZO_EndlessDungeonBuffTracker_Shared:InitializeGridList(gridScrollListTemplate, gridEntryTemplateName, gridHeaderTemplateName, gridSelectionTemplateName)
    self.gridEntryTemplateName = gridEntryTemplateName
    self.gridHeaderTemplateName = gridHeaderTemplateName
    self.gridList = gridScrollListTemplate:New(self.gridListControl, gridSelectionTemplateName)
end

function ZO_EndlessDungeonBuffTracker_Shared:InitializeKeybindStripDescriptor()
    self.switchToSummaryKeybindDescriptor =
    {
        -- Even though this is an ethereal keybind, the name will still be read during screen narration
        name = GetString(SI_ENDLESS_DUNGEON_BUFF_TRACKER_SWITCH_TO_SUMMARY_KEYBIND),
        keybind = "UI_SHORTCUT_TERTIARY",
        ethereal = true,
        narrateEthereal = function()
            return ENDLESS_DUNGEON_MANAGER:IsEndlessDungeonCompleted()
        end,
        etherealNarrationOrder = 1,
        callback = function()
            ENDLESS_DUNGEON_SUMMARY:Show()
        end,
        enabled = function()
            return ENDLESS_DUNGEON_MANAGER:IsEndlessDungeonCompleted()
        end,
    }

    self.closeKeybindDescriptor =
    {
        -- Even though this is an ethereal keybind, the name will still be read during screen narration
        name = GetString(SI_DIALOG_CLOSE),
        keybind = "TOGGLE_ENDLESS_DUNGEON_BUFF_TRACKER",
        ethereal = true,
        narrateEthereal = true,
        etherealNarrationOrder = 2,
        callback = function()
            SCENE_MANAGER:HideCurrentScene()
        end,
    }

    local backKeybindDescriptor = ZO_DeepTableCopy(KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor())
    backKeybindDescriptor.ethereal = true
    backKeybindDescriptor.narrateEthereal = false

    self.keybindStripDescriptor =
    {
        -- Switch To Summary
        self.switchToSummaryKeybindDescriptor,
        -- Close
        self.closeKeybindDescriptor,
        -- Back
        backKeybindDescriptor,
    }

    self.switchToSummaryKeybindButton:SetKeybindButtonDescriptor(self.switchToSummaryKeybindDescriptor)
    self.closeKeybindButton:SetKeybindButtonDescriptor(self.closeKeybindDescriptor)
end

function ZO_EndlessDungeonBuffTracker_Shared:InitializeEvents()
    ENDLESS_DUNGEON_MANAGER:RegisterCallback("BuffStackCountChanged", ZO_GetCallbackForwardingFunction(self, self.OnBuffStackCountChanged))
    ENDLESS_DUNGEON_MANAGER:RegisterCallback("StateChanged", ZO_GetCallbackForwardingFunction(self, self.OnDungeonStateChanged))
    ENDLESS_DUNGEON_MANAGER:RegisterCallback("DungeonInitialized", self.UpdateProgress, self)

    self.refreshGroups = ZO_Refresh:New()
    self.refreshGroups:AddRefreshGroup("UpdateBuffs",
    {
        RefreshAll = function()
            self:UpdateGridList()
        end,
    })
    self.refreshGroups:RefreshAll("UpdateBuffs")

    self.control:SetHandler("OnUpdate", function()
        self.refreshGroups:UpdateRefreshGroups()
    end)
end

function ZO_EndlessDungeonBuffTracker_Shared.InitializeGridEntryControl(control)
    control.highlightTexture = control:GetNamedChild("Highlight")
    control.iconTexture = control:GetNamedChild("Icon")
    control.stackCountLabel = control:GetNamedChild("StackCount")
end

function ZO_EndlessDungeonBuffTracker_Shared.CompareGridEntries(left, right)
    return left.abilityId == right.abilityId
end

function ZO_EndlessDungeonBuffTracker_Shared:GetScene()
    return self.scene
end

function ZO_EndlessDungeonBuffTracker_Shared:GetNextInstanceIntervalOffsetS()
    local currentOffset = self.nextInstanceIntervalOffsetS
    self.nextInstanceIntervalOffsetS = (currentOffset + ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ANIMATION_INTERVAL_OFFSET_S) % ZO_ENDLESS_DUNGEON_BUFF_GRID_ENTRY_ANIMATION_INTERVAL_OFFSET_MAX_S
    return currentOffset
end

function ZO_EndlessDungeonBuffTracker_Shared:SetupGridEntry(control, data)
    control.object = self
    control:Layout(data)
end

function ZO_EndlessDungeonBuffTracker_Shared.SetupGridHeader(control, data, selected)
    control:GetNamedChild("Header"):SetText(data.header)
end

function ZO_EndlessDungeonBuffTracker_Shared:ResetGridEntry(control)
    ZO_ObjectPool_DefaultResetControl(control)

    if self.focusGridEntry == control then
        self:SetGridEntryFocus(control, false)
    end

    control:Reset()
end

function ZO_EndlessDungeonBuffTracker_Shared:SetGridEntryFocus(control, isFocus)
    if self.focusGridEntry and self.focusGridEntry ~= control then
        self.focusGridEntry:SetHighlightHidden(true)
        self.focusGridEntry = nil
    end

    if control then
        if isFocus then
            self.focusGridEntry = control
        end
        control:SetHighlightHidden(not isFocus)
    end
end

function ZO_EndlessDungeonBuffTracker_Shared:UpdateKeybinds()
    local hideKeybind = not ENDLESS_DUNGEON_MANAGER:IsEndlessDungeonCompleted()
    self.switchToSummaryKeybindButton:SetHidden(hideKeybind)

    if hideKeybind then
        self.closeKeybindButton:SetAnchor(TOPLEFT)
    else
        self.closeKeybindButton:SetAnchor(TOPLEFT, self.switchToSummaryKeybindButton, TOPRIGHT, 40, 0)
    end

    self:UpdateWindowDimensions()
end

function ZO_EndlessDungeonBuffTracker_Shared:UpdateProgress()
    if ENDLESS_DUNGEON_MANAGER:IsEndlessDungeonStarted() then
        self.progressLabel:SetText(ENDLESS_DUNGEON_MANAGER:GetCurrentProgressionText())
    else
        self.progressLabel:SetText("")
    end
end

function ZO_EndlessDungeonBuffTracker_Shared.CompareBuffEntries(entry1, entry2)
    return entry1.abilityName < entry2.abilityName
end

function ZO_EndlessDungeonBuffTracker_Shared:AddGridListBuffEntries(buffType, headerName)
    local buffTable = ENDLESS_DUNGEON_MANAGER:GetAbilityStackCountTable(buffType)
    if not (buffTable and next(buffTable)) then
        -- No buffs.
        return 0
    end

    local gridEntryTemplateName = self.gridEntryTemplateName
    local gridHeaderTemplateName = self.gridHeaderTemplateName
    local buffEntries = {}
    for abilityId, stackCount in pairs(buffTable) do
        local buffType, isAvatarVision = GetAbilityEndlessDungeonBuffType(abilityId)
        local buffData =
        {
            abilityId = abilityId,
            abilityName = GetAbilityName(abilityId),
            buffType = buffType,
            iconTexture = GetAbilityIcon(abilityId),
            instanceIntervalOffset = self:GetNextInstanceIntervalOffsetS(),
            isAvatarVision = isAvatarVision,
            stackCount = stackCount,
        }

        local buffEntry = self.entryDataObjectPool:AcquireObject()
        buffEntry:SetDataSource(buffData)
        buffEntry.gridHeaderTemplate = gridHeaderTemplateName
        buffEntry.gridHeaderName = headerName
        table.insert(buffEntries, buffEntry)
    end

    local numBuffsAdded = #buffEntries
    if numBuffsAdded == 0 then
        return 0
    end

    table.sort(buffEntries, self.CompareBuffEntries)

    local gridList = self.gridList
    for _, buffEntry in ipairs(buffEntries) do
        gridList:AddEntry(buffEntry, gridEntryTemplateName)
    end

    return numBuffsAdded
end

function ZO_EndlessDungeonBuffTracker_Shared:UpdateGridList()
    -- Order matters:
    local gridList = self.gridList
    gridList:ClearGridList()
    self.entryDataObjectPool:ReleaseAllObjects()
    local numVerseEntries = self:AddGridListBuffEntries(ENDLESS_DUNGEON_BUFF_TYPE_VERSE, GetString(SI_ENDLESS_DUNGEON_SUMMARY_VERSES_HEADER))
    local numVisionEntries = self:AddGridListBuffEntries(ENDLESS_DUNGEON_BUFF_TYPE_VISION, GetString(SI_ENDLESS_DUNGEON_SUMMARY_VISIONS_HEADER))
    local isListEmpty = (numVerseEntries + numVisionEntries) == 0
    self.emptyLabel:SetHidden(not isListEmpty)
    self:UpdateGridListDimensions(numVerseEntries, numVisionEntries)
    gridList:CommitGridList()
end

function ZO_EndlessDungeonBuffTracker_Shared:UpdateGridListDimensions(numVerseEntries, numVisionEntries, maxGridWidth, gridHeaderFont, gridEntryWidth, gridEntryRowHeight, gridHeaderRowHeight, gridPaddingY)
    local maxColumns = zo_floor(maxGridWidth / gridEntryWidth)
    local numRowsAvailable = ZO_ENDLESS_DUNGEON_BUFF_TRACKER_GRID_LIST_MAX_ENTRY_ROWS
    local minGridWidth = 0
    local DEFAULT_SCALE = 1.0

    local versesHeight = 0
    if numVerseEntries > 0 then
        local numVerseRows = zo_min(zo_ceil(numVerseEntries / maxColumns), numRowsAvailable)
        numRowsAvailable = numRowsAvailable - numVerseRows
        versesHeight = gridHeaderRowHeight + numVerseRows * gridEntryRowHeight

        local versesWidth = GetStringWidthScaled(gridHeaderFont, GetString(SI_ENDLESS_DUNGEON_SUMMARY_VERSES_HEADER), DEFAULT_SCALE, SPACE_INTERFACE)
        minGridWidth = zo_max(minGridWidth, versesWidth + ZO_ENDLESS_DUNGEON_BUFF_TRACKER_GRID_LIST_OFFSET_X)
    end

    local visionsHeight = 0
    if numVisionEntries > 0 then
        local numVisionRows = zo_min(zo_ceil(numVisionEntries / maxColumns), numRowsAvailable)
        visionsHeight = gridHeaderRowHeight + numVisionRows * gridEntryRowHeight

        local visionsWidth = GetStringWidthScaled(gridHeaderFont, GetString(SI_ENDLESS_DUNGEON_SUMMARY_VISIONS_HEADER), DEFAULT_SCALE, SPACE_INTERFACE)
        minGridWidth = zo_max(minGridWidth, visionsWidth + ZO_ENDLESS_DUNGEON_BUFF_TRACKER_GRID_LIST_OFFSET_X)
    end

    local sectionPadding = (versesHeight > 0 and visionsHeight > 0) and gridPaddingY or 0
    local GRID_HEIGHT_PADDING = 5
    local totalHeight = versesHeight + visionsHeight + sectionPadding + GRID_HEIGHT_PADDING
    self.gridListControl:SetHeight(totalHeight)

    local maxBuffsByType = zo_max(numVerseEntries, numVisionEntries)
    local numColumns = zo_min(maxBuffsByType, maxColumns)
    local gridWidth = zo_clamp(numColumns * gridEntryWidth, minGridWidth, maxGridWidth)
    local gridWidthMargin = numColumns > 0 and (maxGridWidth % gridEntryWidth) or 0
    self.gridListControl:SetWidth(gridWidth + gridWidthMargin)

    self:UpdateWindowDimensions()
end

function ZO_EndlessDungeonBuffTracker_Shared:UpdateWindowDimensions()
    local minWidth = zo_max(self.progressLabel:GetWidth(), self.titleLabel:GetWidth())
    minWidth = zo_max(minWidth, self.keybindContainer:GetWidth())
    if self.emptyLabel:IsHidden() then
        minWidth = zo_max(minWidth, self.gridListControl:GetWidth())
    else
        minWidth = zo_max(minWidth, self.emptyLabel:GetWidth())
    end

    local WINDOW_WIDTH_MARGIN = 50
    local windowWidth = minWidth + WINDOW_WIDTH_MARGIN
    self.control:SetWidth(windowWidth)
end

function ZO_EndlessDungeonBuffTracker_Shared:ResizeGridListToFitHeaderLabelControl(labelControl)
    local numExcessLines = labelControl:GetNumLines() - 1
    if numExcessLines < 1 then
        -- The label control is not wrapping; no padding is necessary.
        return
    end

    -- Expand the grid list width incrementally in order to accommodate
    -- the full width of the specified label control.
    local gridWidth = self.gridListControl:GetWidth()
    local labelWidthPadding = numExcessLines * labelControl:GetWidth()
    self.gridListControl:SetWidth(gridWidth + labelWidthPadding)

    -- Resize the top level window accordingly.
    self:UpdateWindowDimensions()
end

function ZO_EndlessDungeonBuffTracker_Shared:OnBuffStackCountChanged(buffType, abilityId, stackCount, previousStackCount)
    self.refreshGroups:RefreshAll("UpdateBuffs")
end

function ZO_EndlessDungeonBuffTracker_Shared:OnDungeonStateChanged(newState, oldState)
    if self:IsShowing() then
        self:UpdateKeybinds()
    end
end

function ZO_EndlessDungeonBuffTracker_Shared:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RestoreDefaultExit()
    PlaySound(SOUNDS.ENDLESS_DUNGEON_BUFF_TRACKER_CLOSE)
end

function ZO_EndlessDungeonBuffTracker_Shared:OnShowing()
    PlaySound(SOUNDS.ENDLESS_DUNGEON_BUFF_TRACKER_OPEN)
end

function ZO_EndlessDungeonBuffTracker_Shared:OnShown()
    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdateKeybinds()
    self.refreshGroups:UpdateRefreshGroups()
end

function ZO_EndlessDungeonBuffTracker_Shared.ToggleVisibility()
    if ENDLESS_DUNGEON_MANAGER:IsEndlessDungeonStarted() then
        if SYSTEMS:IsShowing("endlessDungeonBuffTracker") then
            SYSTEMS:HideScene("endlessDungeonBuffTracker")
        else
            SYSTEMS:ShowScene("endlessDungeonBuffTracker")
        end
    end
end

function ZO_EndlessDungeonBuffTracker_Shared:OnGridEntryMouseEnter()
    -- Can be overridden.
end

function ZO_EndlessDungeonBuffTracker_Shared:OnGridEntryMouseExit()
    -- Can be overridden.
end

ZO_EndlessDungeonBuffTracker_Shared:MUST_IMPLEMENT("GetSceneName")