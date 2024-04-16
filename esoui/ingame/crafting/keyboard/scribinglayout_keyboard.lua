ZO_SCRIBING_CRAFTED_ABILITY_GRID_ENTRY_HEIGHT_KEYBOARD = 140
ZO_SCRIBING_CRAFTED_ABILITY_GRID_ENTRY_WIDTH_KEYBOARD = 178
ZO_SCRIBING_CRAFTED_ABILITY_GRID_ENTRY_ICON_DIMENSIONS_KEYBOARD = 64

ZO_SCRIBING_SCRIPT_ENTRY_HEIGHT_KEYBOARD = 52
ZO_SCRIBING_SCRIPT_HEADER_ENTRY_HEIGHT_KEYBOARD = 30
ZO_SCRIBING_SCRIPT_MESSAGE_ENTRY_WIDTH_KEYBOARD = 509
ZO_SCRIBING_SCRIPT_MESSAGE_ENTRY_LABEL_X_OFFSET_KEYBOARD = 38
ZO_SCRIBING_SCRIPT_MESSAGE_ENTRY_LABEL_WIDTH_KEYBOARD = ZO_SCRIBING_SCRIPT_MESSAGE_ENTRY_WIDTH_KEYBOARD - ZO_SCRIBING_SCRIPT_MESSAGE_ENTRY_LABEL_X_OFFSET_KEYBOARD
ZO_SCRIBING_SCRIPT_ONE_LINE_MESSAGE_ENTRY_HEIGHT_KEYBOARD = 30
ZO_SCRIBING_SCRIPT_TWO_LINE_MESSAGE_ENTRY_HEIGHT_KEYBOARD = 60

local SCRIPT_LIST_SCRIPT_ENTRY_ID = 1
local SCRIPT_LIST_HEADER_ENTRY_ID = 2
local SCRIPT_LIST_ONE_LINE_MESSAGE_ENTRY_ID = 3
local SCRIPT_LIST_TWO_LINE_MESSAGE_ENTRY_ID = 4

ZO_ScribingLayout_Keyboard = ZO_TextSearchObject:Subclass()

function ZO_ScribingLayout_Keyboard:Initialize(control)
    self.control = control
    self.searchContainer = control:GetNamedChild("LibrarySearch")
    self.scribingSearchEditBox = self.searchContainer:GetNamedChild("Box")

    ZO_TextSearchObject.Initialize(self, "craftedAbilityTextSearch", self.searchEditBox)
    self:SetSearchFilterType(BACKGROUND_LIST_FILTER_TARGET_CRAFTED_ABILITY_ID)

    self.collapsedSlots = {}
end

function ZO_ScribingLayout_Keyboard:InitializeScriptList()
    self.backHeaderControl = self.libraryContainer:GetNamedChild("BackHeader")
    self.backHeaderControl.OnMouseUp = function()
        self:OnBackHeaderControlMouseClick()
    end

    self.infoBar = self.libraryContainer:GetNamedChild("InfoBar")
    self.inkNameLabel = self.infoBar:GetNamedChild("InkName")
    self.inkAmountLabel = self.infoBar:GetNamedChild("InkAmount")

    self.scriptsList = self.libraryContainer:GetNamedChild("Scripts")

    local function ScriptEntrySetup(rowControl, scriptData)
        rowControl.owner = self
        local nameLabel = rowControl:GetNamedChild("Name")
        local iconControl = rowControl:GetNamedChild("Icon")

        nameLabel:SetText(scriptData:GetFormattedName())
        iconControl:SetTexture(scriptData:GetIcon())

        local craftedAbilityData = self:GetSelectedCraftedAbilityData()
        if not self:IsScriptDataCompatible(craftedAbilityData:GetId(), scriptData) then
            nameLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        elseif not scriptData:IsUnlocked() then
            nameLabel:SetColor(self:GetScriptDataDisabledColor():UnpackRGBA())
            iconControl:SetDesaturation(0.8)
            iconControl:SetAlpha(0.8)
        else
            nameLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
            iconControl:SetDesaturation(0)
            iconControl:SetAlpha(1)
        end

        local statusControl = rowControl:GetNamedChild("StatusTexture")
        statusControl:ClearIcons()

        local icons = self:GetIconsForScriptData(scriptData)
        for i, icon in ipairs(icons) do
            statusControl:AddIcon(icon)
        end

        statusControl:Show()
    end

    ZO_ScrollList_AddDataType(self.scriptsList, SCRIPT_LIST_SCRIPT_ENTRY_ID, "ZO_Scribing_CraftedAbilityScriptRow_Keyboard", ZO_SCRIBING_SCRIPT_ENTRY_HEIGHT_KEYBOARD, ScriptEntrySetup)

    local function HeaderSetup(rowControl, data)
        rowControl.owner = self
        local nameLabel = rowControl:GetNamedChild("Name")
        nameLabel:SetText(data.headerName)

        local expandedStateButton = rowControl:GetNamedChild("ExpandedState")
        if self.collapsedSlots[data.scribingSlot] then
            ZO_ToggleButton_SetState(expandedStateButton, TOGGLE_BUTTON_CLOSED)
        else
            ZO_ToggleButton_SetState(expandedStateButton, TOGGLE_BUTTON_OPEN)
        end
    end

    ZO_ScrollList_AddDataType(self.scriptsList, SCRIPT_LIST_HEADER_ENTRY_ID, "ZO_Scribing_AbilityScriptHeaderRow_Keyboard", ZO_SCRIBING_SCRIPT_HEADER_ENTRY_HEIGHT_KEYBOARD, HeaderSetup)

    local function MessageSetup(rowControl, data)
        rowControl.owner = self
        local nameLabel = rowControl:GetNamedChild("Name")
        nameLabel:SetText(data.message)
    end

    ZO_ScrollList_AddDataType(self.scriptsList, SCRIPT_LIST_ONE_LINE_MESSAGE_ENTRY_ID, "ZO_Scribing_AbilityScriptOneLineMessageRow_Keyboard", ZO_SCRIBING_SCRIPT_ONE_LINE_MESSAGE_ENTRY_HEIGHT_KEYBOARD, MessageSetup)
    ZO_ScrollList_AddDataType(self.scriptsList, SCRIPT_LIST_TWO_LINE_MESSAGE_ENTRY_ID, "ZO_Scribing_AbilityScriptTwoLineMessageRow_Keyboard", ZO_SCRIBING_SCRIPT_TWO_LINE_MESSAGE_ENTRY_HEIGHT_KEYBOARD, MessageSetup)

    ZO_ScrollList_EnableHighlight(self.scriptsList, "ZO_ThinListHighlight")

    self.noItemsLabel = self.libraryContainer:GetNamedChild("NoItemsLabel")
end

function ZO_ScribingLayout_Keyboard:IsMousedOver(control)
    return control == self:GetMouseOverCraftedAbilityEntry()
end

function ZO_ScribingLayout_Keyboard:RefreshTitleLabelColor(control)
    local craftedAbilityData = control.dataEntry.data
    local isUnlocked = craftedAbilityData:IsUnlocked()
    local isMousedOver = self:IsMousedOver(control)
    local labelColor
    if isUnlocked then
        labelColor = isMousedOver and ZO_HIGHLIGHT_TEXT or ZO_NORMAL_TEXT
    else
        labelColor = isMousedOver and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT
    end
    control.nameLabel:SetColor(labelColor:UnpackRGBA())
end

function ZO_ScribingLayout_Keyboard:InitializeGridList()
    local craftedAbilitiesControl = self.libraryContainer:GetNamedChild("CraftedAbilities")
    local craftedAbilitiesGridListControl = craftedAbilitiesControl:GetNamedChild("GridList")
    self.craftedAbilitiesControl = craftedAbilitiesControl
    self.craftedAbilitiesGridListControl = craftedAbilitiesGridListControl
    self.craftedAbilitiesGridList = ZO_SingleTemplateGridScrollList_Keyboard:New(craftedAbilitiesGridListControl, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL)

    local function CraftedAbilityGridEntrySetup(control, craftedAbilityData, selected)
        control.owner = self

        self:RefreshTitleLabelColor(control)
        control.nameLabel:SetText(craftedAbilityData:GetFormattedName())

        control.iconTexture:SetTexture(craftedAbilityData:GetIcon())
        if craftedAbilityData:IsUnlocked() then
            control.iconTexture:SetDesaturation(0)
            control.iconTexture:SetAlpha(1)
        else
            control.iconTexture:SetDesaturation(0.8)
            control.iconTexture:SetAlpha(0.8)
        end

        control.statusMultiIcon:ClearIcons()

        if craftedAbilityData:IsSlottedOnHotBar() then
            control.statusMultiIcon:AddIcon("EsoUI/Art/Skills/scribing_grimoire_equipped.dds")
        end

        control.statusMultiIcon:Show()
    end

    local function CraftedAbilityGridEntryReset(control)
        ZO_ObjectPool_DefaultResetControl(control)

        if control.highlightAnimation then
            control.highlightAnimation:PlayInstantlyToStart()
        end

        ZO_GridEntry_SetIconScaledUpInstantly(control, false)
    end

    local HEADER_HEIGHT = 30
    local NO_HIDE_CALLBACK = nil
    local SPACING = 5
    self.craftedAbilitiesGridList:SetGridEntryTemplate("ZO_Scribing_CraftedAbilityGridEntry_Keyboard", ZO_SCRIBING_CRAFTED_ABILITY_GRID_ENTRY_WIDTH_KEYBOARD, ZO_SCRIBING_CRAFTED_ABILITY_GRID_ENTRY_HEIGHT_KEYBOARD, CraftedAbilityGridEntrySetup, NO_HIDE_CALLBACK, CraftedAbilityGridEntryReset, SPACING, SPACING)
    self.craftedAbilitiesGridList:SetHeaderTemplate(ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD, HEADER_HEIGHT, ZO_DefaultGridHeaderSetup)
end

function ZO_ScribingLayout_Keyboard:PerformDeferredInitialization()
    self.libraryContainer = self.control:GetNamedChild("Library")

    self:InitializeLists()
    self.inkNameLabel:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, ZO_Scribing_Manager.GetScribingInkName()))

    local function OnInventoryUpdated()
        if self:IsShowing() then
            self:UpdateInkDisplay()
        end
    end

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", OnInventoryUpdated)
end

function ZO_ScribingLayout_Keyboard:InitializeLists()
    self:InitializeScriptList()
    self:InitializeGridList()
end

function ZO_ScribingLayout_Keyboard:SetupContextTextSearch()
    -- craftedAbilityTextSearch search context is setup in ZO_Scribing_Manager
end

-- Overrides ZO_TextSearchObject
function ZO_ScribingLayout_Keyboard:OnUpdateSearchResults()
    if self:AreCraftedAbilitiesShowing() then
        self:RefreshCraftedAbilityList()
    elseif self:AreScriptsShowing() then
        self:RefreshScriptsList()
    end
end

function ZO_ScribingLayout_Keyboard:SetMouseOverCraftedAbilityEntry(control)
    self.mouseOverCraftedAbilityEntry = control
end

function ZO_ScribingLayout_Keyboard:GetMouseOverCraftedAbilityEntry()
    return self.mouseOverCraftedAbilityEntry
end

function ZO_ScribingLayout_Keyboard:HasMouseOverCraftedAbilityEntry()
    return self.mouseOverCraftedAbilityEntry ~= nil
end

function ZO_ScribingLayout_Keyboard:SetMouseOverScriptRow(rowControl)
    self.mouseOverScriptRow = rowControl
end

function ZO_ScribingLayout_Keyboard:GetMouseOverScriptRow()
    return self.mouseOverScriptRow
end

function ZO_ScribingLayout_Keyboard:HasMouseOverScriptRow()
    return self.mouseOverScriptRow ~= nil
end

function ZO_ScribingLayout_Keyboard:ClearMouseOverState()
    self.mouseOverCraftedAbilityEntry = nil
    self.mouseOverScriptRow = nil
end

function ZO_ScribingLayout_Keyboard:ResetCollapsedSlots()
    ZO_ClearTable(self.collapsedSlots)
end

function ZO_ScribingLayout_Keyboard:ShowCraftedAbilities(resetToTop)
    self:SetSearchCriteria(BACKGROUND_LIST_FILTER_TARGET_CRAFTED_ABILITY_ID, "craftedAbilityTextSearch", self.scribingSearchEditBox)
    SCRIBING_MANAGER:SetScriptSearchCraftedAbility(nil)
    self:RefreshCraftedAbilityList(resetToTop)
    self.craftedAbilitiesControl:SetHidden(false)

    self:HideScripts()
    ClearCursor()
end

function ZO_ScribingLayout_Keyboard:HideCraftedAbilities()
    self.craftedAbilitiesControl:SetHidden(true)
end

function ZO_ScribingLayout_Keyboard:AreCraftedAbilitiesShowing()
    return not self.craftedAbilitiesGridListControl:IsHidden()
end

function ZO_ScribingLayout_Keyboard:RefreshCraftedAbilityList(resetToTop)
    local gridList = self.craftedAbilitiesGridList
    gridList:ClearGridList()

    local craftedAbilities = self:GetCraftedAbilityDataList()
    for i, craftedAbilityData in ipairs(craftedAbilities) do
        if self:IsDataInSearchTextResults(craftedAbilityData:GetId()) and not craftedAbilityData:IsDisabled() then
            local entryData = ZO_EntryData:New(craftedAbilityData)
            entryData.gridHeaderName = GetString("SI_SKILLTYPE", craftedAbilityData:GetSkillType())
            gridList:AddEntry(entryData)
        end
    end

    gridList:CommitGridList(resetToTop)
end

function ZO_ScribingLayout_Keyboard:ShowScripts()
    local RESET_TO_TOP = true
    local craftedAbilityData = self:GetSelectedCraftedAbilityData()
    if craftedAbilityData then
        self:SetSearchCriteria(BACKGROUND_LIST_FILTER_TARGET_CRAFTED_ABILITY_SCRIPT_ID, "craftedAbilityScriptsTextSearch", self.scribingSearchEditBox)
        SCRIBING_MANAGER:SetScriptSearchCraftedAbility(craftedAbilityData:GetId())
        self:RefreshScriptsList(RESET_TO_TOP)
        self:UpdateInkDisplay()
        ClearCursor()

        self:HideCraftedAbilities()

        local craftedAbilityIcon = craftedAbilityData:GetIcon()
        local craftedAbilityDisplayName = craftedAbilityData:GetFormattedName()
        self.backHeaderControl.text:SetText(zo_iconTextFormat(craftedAbilityIcon, "100%", "100%", craftedAbilityDisplayName))
        self.backHeaderControl:SetHidden(false)

        self.scriptsList:SetHidden(false)
        self.infoBar:SetHidden(false)
    end
end

function ZO_ScribingLayout_Keyboard:HideScripts()
    self.backHeaderControl:SetHidden(true)
    self.scriptsList:SetHidden(true)
    self.infoBar:SetHidden(true)

    self:ResetCollapsedSlots()
end

function ZO_ScribingLayout_Keyboard:AreScriptsShowing()
    return not self.scriptsList:IsHidden()
end

function ZO_ScribingLayout_Keyboard:AddScriptsToScrollData(scrollData, currentCraftedAbilityId, scribingSlot)
    local headerName = GetString("SI_SCRIBINGSLOT", scribingSlot)
    local headerData =
    {
        headerName = headerName,
        scribingSlot = scribingSlot,
    }
    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SCRIPT_LIST_HEADER_ENTRY_ID, headerData))

    local headerIsCollapsed = self.collapsedSlots[scribingSlot] or false
    if headerIsCollapsed then
        local scriptData = self:GetSelectedScriptDataForSlot(scribingSlot)
        if scriptData then
            local entryData = ZO_EntryData:New(scriptData)
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SCRIPT_LIST_SCRIPT_ENTRY_ID, entryData))
        end
    else
        local showedAnyScripts = false
        local scriptIds = self:GetScriptDataList(currentCraftedAbilityId, scribingSlot)
        for i, scriptId in ipairs(scriptIds) do
            if self:ShouldAddScriptToList(currentCraftedAbilityId, scriptId) and self:IsDataInSearchTextResults(scriptId) then
                local entryData = ZO_EntryData:New(SCRIBING_DATA_MANAGER:GetCraftedAbilityScriptData(scriptId))
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SCRIPT_LIST_SCRIPT_ENTRY_ID, entryData))
                showedAnyScripts = true
            end
        end

        if not showedAnyScripts then
            local unlockedScripts = SCRIBING_DATA_MANAGER:GetUnlockedSortedScriptsForCraftedAbilityAndSlot(currentCraftedAbilityId, scribingSlot)
            local message = GetString(SI_SCRIBING_FILTER_NO_SCRIPTS)
            if #unlockedScripts == 0 then
                message = GetString(SI_SCRIBING_NO_SCRIPTS_UNLOCKED)
            end

            local dataType = SCRIPT_LIST_ONE_LINE_MESSAGE_ENTRY_ID
            local numMessageLines = ZO_LabelUtils_GetNumLines(message, "ZoFontWinH3", ZO_SCRIBING_SCRIPT_MESSAGE_ENTRY_LABEL_WIDTH_KEYBOARD)
            if numMessageLines > 1 then
                dataType = SCRIPT_LIST_TWO_LINE_MESSAGE_ENTRY_ID
            end

            local messageInfo =
            {
                message = message
            }
            local entryData = ZO_EntryData:New(messageInfo)
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(dataType, entryData))
        end
    end
end

function ZO_ScribingLayout_Keyboard:RefreshScriptsList(resetToTop)
    local scriptsList = self.scriptsList

    ZO_ScrollList_Clear(scriptsList)

    local selectedCraftedAbilityData = self:GetSelectedCraftedAbilityData()
    if selectedCraftedAbilityData then
        local scrollData = ZO_ScrollList_GetDataList(scriptsList)
        local craftedAbilityId = selectedCraftedAbilityData:GetId()
        self:AddScriptsToScrollData(scrollData, craftedAbilityId, SCRIBING_SLOT_PRIMARY)
        self:AddScriptsToScrollData(scrollData, craftedAbilityId, SCRIBING_SLOT_SECONDARY)
        self:AddScriptsToScrollData(scrollData, craftedAbilityId, SCRIBING_SLOT_TERTIARY)

        ZO_ScrollList_Commit(scriptsList)
    end
end

function ZO_ScribingLayout_Keyboard:UpdateInkDisplay()
    self.inkAmountLabel:SetText(ZO_Scribing_Manager.GetFormattedNoSpaceAlignedRightScribingInkAmount())
end

function ZO_ScribingLayout_Keyboard:SelectCraftedAbilityId(craftedAbilityId)
    self.selectedCraftedAbilityId = craftedAbilityId
    ClearCursor()
end

function ZO_ScribingLayout_Keyboard:GetSelectedCraftedAbilityData()
    return SCRIBING_DATA_MANAGER:GetCraftedAbilityData(self.selectedCraftedAbilityId)
end

ZO_ScribingLayout_Keyboard:MUST_IMPLEMENT("GetCraftedAbilityDataList")

function ZO_ScribingLayout_Keyboard:GetScriptDataList(craftedAbilityId, slotType)
    return SCRIBING_DATA_MANAGER:GetAllSortedScriptsForCraftedAbilityAndSlot(craftedAbilityId, slotType)
end

function ZO_ScribingLayout_Keyboard:SelectScriptId(scriptId)
    ClearCursor()
end

function ZO_ScribingLayout_Keyboard:IsSlotCategoryCollapsed(slotType)
    return self.collapsedSlots[slotType] == true
end

function ZO_ScribingLayout_Keyboard:ExpandSlotCategory(slotType, playSound)
    if self:IsSlotCategoryCollapsed(slotType) then
        if playSound then
            PlaySound(SOUNDS.SCRIBING_SLOT_CATEGORY_EXPANDED)
        end
        self.collapsedSlots[slotType] = nil
        self:RefreshScriptsList()
    end
end

function ZO_ScribingLayout_Keyboard:CollapseSlotCategory(slotType, playSound)
    if not self:IsSlotCategoryCollapsed(slotType) then
        if playSound then
            PlaySound(SOUNDS.SCRIBING_SLOT_CATEGORY_COLLAPSED)
        end
        self.collapsedSlots[slotType] = true
        self:RefreshScriptsList()
    end
end

function ZO_ScribingLayout_Keyboard:IsDraggingEnabled()
    return false
end

function ZO_ScribingLayout_Keyboard:ShouldAddScriptToList(currentCraftedAbilityId, scriptId)
    return true
end

function ZO_ScribingLayout_Keyboard:GetIconsForScriptData(scriptData)
    return {}
end

function ZO_ScribingLayout_Keyboard:GetSelectedScriptDataForSlot(slotType)
    return nil
end

function ZO_ScribingLayout_Keyboard:IsScriptDataCompatible(craftedAbilityId, scriptData)
    return true
end

function ZO_ScribingLayout_Keyboard:GetScriptDataDisabledColor()
    return ZO_DISABLED_TEXT
end

-- Back Header Control

function ZO_ScribingLayout_Keyboard:OnBackHeaderControlMouseClick()
    self:ShowCraftedAbilities()
end

-- Crafted Ability Entry

function ZO_ScribingLayout_Keyboard:OnCraftedAbilityEntryMouseEnter(control)
    if not self:IsShowing() then
        return
    end

    if not control.highlightAnimation then
        control.highlightAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_Scribing_CraftedAbilityGridEntry_Keyboard_HighlightAnimation", control.highlight)
    end

    control.highlightAnimation:PlayForward()

    ZO_GridEntry_SetIconScaledUp(control, true)

    self:SetMouseOverCraftedAbilityEntry(control)
    self:RefreshTitleLabelColor(control)

    local craftedAbilityData = control.dataEntry.data
    local craftedAbilityId = craftedAbilityData:GetId()
    -- set the tooltip so it's to the left of the grid list, but still relative to the entry
    local offsetX = control:GetParent():GetLeft() - control:GetLeft() - 5
    InitializeTooltip(AbilityTooltip, control, RIGHT, offsetX, 0, LEFT)
    local NO_SELECTED_SCRIPT = 0
    local DISPLAY_FLAGS = SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_ACQUIRE_HINT
    AbilityTooltip:SetCraftedAbility(craftedAbilityId, NO_SELECTED_SCRIPT, NO_SELECTED_SCRIPT, NO_SELECTED_SCRIPT, DISPLAY_FLAGS)

    if craftedAbilityData:IsScribed() then
        local activePrimaryScriptId, activeSecondaryScriptId, activeTertiaryScriptId = craftedAbilityData:GetActiveScriptIds()
        InitializeTooltip(ComparativeAbilityTooltip1, AbilityTooltip, TOPRIGHT, -5, 0, TOPLEFT)
        ComparativeAbilityTooltip1:SetCraftedAbility(craftedAbilityId, activePrimaryScriptId, activeSecondaryScriptId, activeTertiaryScriptId, DISPLAY_FLAGS)
    end
end

function ZO_ScribingLayout_Keyboard:OnCraftedAbilityEntryMouseExit(control)
    -- make sure we always clear the tooltip on mouse exit so the tooltip doesn't say
    -- on screen when the scene hides
    ClearTooltip(AbilityTooltip)
    ClearTooltip(ComparativeAbilityTooltip1)

    if not self:IsShowing() then
        return
    end

    control.highlightAnimation:PlayBackward()
    ZO_GridEntry_SetIconScaledUp(control, false)

    self:SetMouseOverCraftedAbilityEntry(nil)
    self:RefreshTitleLabelColor(control)
end

function ZO_ScribingLayout_Keyboard:OnCraftedAbilityEntryMouseClick(control)
    local craftedAbilityData = control.dataEntry.data
    self:SelectCraftedAbilityId(craftedAbilityData:GetId())
end

function ZO_ScribingLayout_Keyboard:TryPickupCraftedAbilityFromGridEntry(control)
    if not self:IsShowing() or not self:IsDraggingEnabled() then
        return
    end

    local craftedAbilityData = control.dataEntry.data
    local craftedAbilityId = craftedAbilityData:GetId()
    PickupCraftedAbility(craftedAbilityId)
end

function ZO_ScribingLayout_Keyboard:TryReceiveCraftedAbilityInGridEntry(control)
    if not self:IsShowing() or not self:IsDraggingEnabled() then
        return
    end

    local craftedAbilityId = GetCursorCraftedAbilityId()
    if craftedAbilityId then
        ClearCursor()
    end
end

-- Script Row

function ZO_ScribingLayout_Keyboard:OnMouseEnterCraftedAbilityScriptRow(control)
    if not self:IsShowing() then
        return
    end

    ZO_ScrollList_MouseEnter(self.scriptsList, control)

    self:SetMouseOverScriptRow(control)

    local scriptData = ZO_ScrollList_GetData(control)

    -- scriptData could be nil if the list was redrawn and removes this control while rolled over
    if scriptData then
        InitializeTooltip(AbilityTooltip, control, RIGHT, -5, 0, LEFT)
        local displayFlags = SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_ACQUIRE_HINT + SCRIBING_TOOLTIP_DISPLAY_FLAGS_SHOW_ERRORS
        if not self:IsScriptDataCompatible(self.selectedCraftedAbilityId, scriptData) then
            displayFlags = ZO_FlagHelpers.SetMaskFlag(displayFlags, SCRIBING_TOOLTIP_DISPLAY_FLAGS_SCRIPT_COMPATIBILITY_ERROR)
        end
        -- Choosing some scripts can possibly alter the description of this script
        local primaryScriptData = self:GetSelectedScriptDataForSlot(SCRIBING_SLOT_PRIMARY)
        local primaryScriptId = primaryScriptData and primaryScriptData:GetId() or 0
        local secondaryScriptData = self:GetSelectedScriptDataForSlot(SCRIBING_SLOT_SECONDARY)
        local secondaryScriptId = secondaryScriptData and secondaryScriptData:GetId() or 0
        local tertiaryScriptData = self:GetSelectedScriptDataForSlot(SCRIBING_SLOT_TERTIARY)
        local tertiaryScriptId = tertiaryScriptData and tertiaryScriptData:GetId() or 0
        AbilityTooltip:SetCraftedAbilityScript(self.selectedCraftedAbilityId, scriptData:GetId(), primaryScriptId, secondaryScriptId, tertiaryScriptId, displayFlags)
    end
end

function ZO_ScribingLayout_Keyboard:OnMouseExitCraftedAbilityScriptRow(control)
    -- make sure we always clear the tooltip on mouse exit so the tooltip doesn't say
    -- on screen when the scene hides
    ClearTooltip(AbilityTooltip)

    if not self:IsShowing() then
        return
    end

    ZO_ScrollList_MouseExit(self.scriptsList, control)

    self:SetMouseOverScriptRow(nil)
end

function ZO_ScribingLayout_Keyboard:OnMouseClickCraftedAbilityScriptRow(control)
    local scriptData = ZO_ScrollList_GetData(control)
    local scriptId = scriptData:GetId()
    self:SelectScriptId(scriptId)
end

function ZO_ScribingLayout_Keyboard:TryPickupCraftedAbilityScriptFromRow(control)
    if not self:IsShowing() or not self:IsDraggingEnabled() then
        return
    end

    local scriptData = ZO_ScrollList_GetData(control)
    local scriptId = scriptData:GetId()
    PickupCraftedAbilityScript(scriptId)
end

function ZO_ScribingLayout_Keyboard:TryReceiveCraftedAbilityScriptInRow(control)
    if not self:IsShowing() or not self:IsDraggingEnabled() then
        return
    end

    local scriptId = GetCursorCraftedAbilityScriptId()
    if scriptId then
        ClearCursor()
    end
end

-- Script Header Row

function ZO_ScribingLayout_Keyboard:OnMouseClickCraftedAbilityScriptHeaderRow(control)
    local headerData = ZO_ScrollList_GetData(control)
    local scribingSlot = headerData.scribingSlot
    local PLAY_SOUND = true
    if self.collapsedSlots[scribingSlot] then
        self:ExpandSlotCategory(scribingSlot, PLAY_SOUND)
    else
        self:CollapseSlotCategory(scribingSlot, PLAY_SOUND)
    end
end

--
-- Functions for XML
--

-- Crafted Ability Entry

function ZO_ScribingLayout_Keyboard.OnCraftedAbilityGridEntryMouseEnter(control)
    control.owner:OnCraftedAbilityEntryMouseEnter(control)
end

function ZO_ScribingLayout_Keyboard.OnCraftedAbilityGridEntryMouseExit(control)
    control.owner:OnCraftedAbilityEntryMouseExit(control)
end

function ZO_ScribingLayout_Keyboard.OnCraftedAbilityGridEntryMouseUp(control, button, upInside)
    if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
        control.owner:OnCraftedAbilityEntryMouseClick(control)
    end
end

function ZO_ScribingLayout_Keyboard.OnCraftedAbilityGridEntryStartDrag(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        control.owner:TryPickupCraftedAbilityFromGridEntry(control)
    end
end

function ZO_ScribingLayout_Keyboard.OnCraftedAbilityGridEntryReceiveDrag(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        control.owner:TryReceiveCraftedAbilityInGridEntry(control)
    end
end

-- Script Row

function ZO_ScribingLayout_Keyboard.OnCraftedAbilityScriptRowMouseEnter(control)
    control.owner:OnMouseEnterCraftedAbilityScriptRow(control)
end

function ZO_ScribingLayout_Keyboard.OnCraftedAbilityScriptRowMouseExit(control)
    control.owner:OnMouseExitCraftedAbilityScriptRow(control)
end

function ZO_ScribingLayout_Keyboard.OnCraftedAbilityScriptRowMouseUp(control, button, upInside)
     if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
        control.owner:OnMouseClickCraftedAbilityScriptRow(control)
    end
end

function ZO_ScribingLayout_Keyboard.OnCraftedAbilityScriptRowStartDrag(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        control.owner:TryPickupCraftedAbilityScriptFromRow(control)
    end
end

function ZO_ScribingLayout_Keyboard.OnCraftedAbilityScriptRowReceiveDrag(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        control.owner:TryReceiveCraftedAbilityScriptInRow(control)
    end
end

-- Script Header Row

function ZO_ScribingLayout_Keyboard.OnCraftedAbilityScriptHeaderRowMouseUp(control, button, upInside)
     if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
        control.owner:OnMouseClickCraftedAbilityScriptHeaderRow(control)
    end
end
