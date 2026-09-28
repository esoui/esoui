----------------------------------------
-- Vengeance Loadout Stat Entry Keyboard
----------------------------------------

ZO_VengeanceStatEntry_Keyboard = ZO_StatEntry_Keyboard:Subclass()

function ZO_VengeanceStatEntry_Keyboard:GetValue()
    local equippedLoadout = ZO_VENGEANCE_MANAGER:GetEquippedLoadoutData()
    if equippedLoadout then
        return equippedLoadout:GetDerivedStatValueByStatType(self.statType)
    end
    return 0
end

-----------------------------
-- Vengeance Loadout Keyboard
-----------------------------

local DATA_ENTRY_TYPE_COLLAPSED = 1
local DATA_ENTRY_TYPE_EXPANDED = 2

ZO_VENGEANCE_LOADOUT_KEYBOARD_COLLAPSED_ENTRY_HEIGHT = 80
ZO_VENGEANCE_LOADOUT_KEYBOARD_EXPANDED_MIN_ENTRY_HEIGHT = 300
ZO_VENGEANCE_LOADOUT_KEYBOARD_EXPANDED_EQUIPPED_ENTRY_HEIGHT = 260
ZO_VENGEANCE_LOADOUT_KEYBOARD_EXPANDED_PER_STAT_HEIGHT = 25

ZO_Vengeance_Loadouts_Keyboard = ZO_DeferredInitializingObject:Subclass()

function ZO_Vengeance_Loadouts_Keyboard:Initialize(control)
    self.control = control
    self.instructionLabel = control:GetNamedChild("InstructionText")

    VENGEANCE_LOADOUT_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)

    ZO_DeferredInitializingObject.Initialize(self, VENGEANCE_LOADOUT_KEYBOARD_FRAGMENT)
end

function ZO_Vengeance_Loadouts_Keyboard:OnDeferredInitialize()
    self:InitializeList()
    self:InitializeKeybindStripDescriptors()
    self:InitializeDerivedStats()
    self:RegisterForEvents()
end

function ZO_Vengeance_Loadouts_Keyboard:InitializeList()
    self.list = self.control:GetNamedChild("List")

    self.attributeRowControlPool = ZO_ControlPool:New("ZO_Vengeance_LoadoutStatsRow_Keyboard")
    self.attributeRowControls = {}

    local function SetupCollapsedLoadoutEntry(control, data)
        control.nameLabel:SetText(data:GetFormattedName())
        control.iconTexture:SetTexture(data:GetIcon())
        control.isEquippedIndicator:SetHidden(not IsLoadoutRoleEquippedAtIndex(data:GetLoadoutIndex()))
    end

    local function SetupExpandedLoadoutEntry(control, data)
        control:SetHeight(self.expandedHeight)

        --Setup the header
        control.nameLabel:SetText(data:GetFormattedName())
        control.iconTexture:SetTexture(data:GetIcon())

        local isEquippedLoadout = IsLoadoutRoleEquippedAtIndex(data:GetLoadoutIndex())
        control.isEquippedIndicator:SetHidden(not isEquippedLoadout)

        if isEquippedLoadout then
            control.statsContainer:SetHidden(true)
            control.perksSkillsContainer:ClearAnchors()
            control.perksSkillsContainer:SetAnchor(TOPLEFT, control.divider, BOTTOMLEFT)
        else
            control.statsContainer:SetHidden(false)
            control.perksSkillsContainer:ClearAnchors()
            control.perksSkillsContainer:SetAnchor(TOPLEFT, control.statsContainer, BOTTOMLEFT)

            local relativeToAnchor = control.statsEntries
            local positiveAttributeList = data:GetPositiveImportantStats()
            local negativeAttributeList = data:GetNegativeImportantStats()
            local longestListLength = zo_max(#positiveAttributeList, #negativeAttributeList)
            for i = 1, longestListLength do
                local attributeRow = self.attributeRowControlPool:AcquireObject()
                if i <= #positiveAttributeList then
                    attributeRow.stat1:SetText(positiveAttributeList[i])
                else
                    attributeRow.stat1:SetText("")
                end

                if i <= #negativeAttributeList then
                    attributeRow.stat2:SetText(negativeAttributeList[i])
                else
                    attributeRow.stat2:SetText("")
                end

                attributeRow:SetParent(control.statsEntries)
                attributeRow:ClearAnchors()
                if i == 1 then
                    attributeRow:SetAnchor(TOPLEFT, relativeToAnchor, TOPLEFT)
                else
                    attributeRow:SetAnchor(TOPLEFT, relativeToAnchor, BOTTOMLEFT)
                end
                table.insert(self.attributeRowControls, attributeRow)
                relativeToAnchor = attributeRow
            end
        end

        for slot, icon in pairs(control.perksControl.icons) do
            icon:SetPerkSlot(slot)
            icon:SetPerkData(data:GetPerkDataBySlot(slot))
            icon:SetTooltipAnchors(BOTTOM, 0, -10, TOP)
        end

        control.primaryActionBar:AssignSkillsData(data:GetPrimaryActionBarData())
        control.backupActionBar:AssignSkillsData(data:GetBackupActionBarData())
    end

    ZO_ScrollList_AddDataType(self.list, DATA_ENTRY_TYPE_COLLAPSED, "ZO_Vengeance_CollapsedLoadoutEntry", ZO_VENGEANCE_LOADOUT_KEYBOARD_COLLAPSED_ENTRY_HEIGHT, SetupCollapsedLoadoutEntry)
    ZO_ScrollList_AddDataType(self.list, DATA_ENTRY_TYPE_EXPANDED, "ZO_Vengeance_ExpandedLoadoutEntry", ZO_VENGEANCE_LOADOUT_KEYBOARD_EXPANDED_MIN_ENTRY_HEIGHT, SetupExpandedLoadoutEntry)
end

function ZO_Vengeance_Loadouts_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        --Equip build
        {
            name = function()
                local loadoutData = ZO_VENGEANCE_MANAGER:GetLoadoutDataByIndex(self.selectedLoadoutIndex)
                return zo_strformat(SI_CAMPAIGN_VENGEANCE_LOADOUT_EQUIP_ACTION, loadoutData:GetRawName())
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            onShowCooldown = function()
                return GetRemainingCooldownForRoleSwapMs() / 1000
            end,
            callback = function()
                RequestSetLoadoutRoleByIndex(self.selectedLoadoutIndex)
            end,
            enabled = function()
                local canEquipResult = CanLoadoutRoleBeEquippedByIndex(self.selectedLoadoutIndex)
                return canEquipResult == VENGEANCE_ACTION_RESULT_SUCCESS, GetString("SI_VENGEANCEACTIONRESULT", canEquipResult)
            end,
            visible = function()
                if self.selectedLoadoutIndex then
                    return ZO_VENGEANCE_MANAGER:IsLoadoutIndexKeybindVisible(self.selectedLoadoutIndex)
                end
                return false
            end,
        },
    }
end

do
    local DEFAULT_STAT_SPACING = 0
    local STAT_GROUP_SPACING = 20
    local STAT_GROUP_OFFSET_X = 10

    function ZO_Vengeance_Loadouts_Keyboard:InitializeDerivedStats()
        self.derivedStatsControls = {}
        self.derivedStatsContainer = self.control:GetNamedChild("DerivedStatsContainer")
        local parentControl = self.derivedStatsContainer:GetNamedChild("ScrollChild")
        local lastControl = nil
        local nextPaddingY = 0
        for _, statGroup in ipairs(ZO_INVENTORY_STAT_GROUPS) do
            for _, statType in ipairs(statGroup) do
                local statControl = CreateControlFromVirtual("$(parent)StatEntry", parentControl, "ZO_StatsEntry", statType)
                self.derivedStatsControls[statType] = statControl

                if lastControl then
                    statControl:SetAnchor(TOP, lastControl, BOTTOM, 0, nextPaddingY)
                else
                    statControl:SetAnchor(TOP, lastControl, TOP, STAT_GROUP_OFFSET_X, nextPaddingY)
                end

                local statEntry = ZO_VengeanceStatEntry_Keyboard:New(statControl, statType)
                statEntry.tooltipAnchorSide = CHARACTER_WINDOW_TOOLTIP_ANCHOR_SIDE
                lastControl = statControl
                nextPaddingY = DEFAULT_STAT_SPACING
            end
            nextPaddingY = STAT_GROUP_SPACING
        end
    end
end

function ZO_Vengeance_Loadouts_Keyboard:RegisterForEvents()
    self.control:RegisterForEvent(EVENT_VENGEANCE_LOADOUT_ROLE_UPDATED, function() self:RefreshLoadouts() end)
    self.control:RegisterForEvent(EVENT_VENGEANCE_PERKS_UPDATED, function() self:RefreshLoadouts() end)

    self.control:SetHandler("OnUpdate", function() self:UpdateInstructionText() end)
end

function ZO_Vengeance_Loadouts_Keyboard:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    for _, keybindDesc in ipairs(self.keybindStripDescriptor) do
        local onShowCooldown = keybindDesc.onShowCooldown
        if onShowCooldown then
            KEYBIND_STRIP:TriggerCooldown(keybindDesc, onShowCooldown)
        end
    end
end

function ZO_Vengeance_Loadouts_Keyboard:UpdateInstructionText()
    local isErrorText = false
    local loadoutIndex = self.selectedLoadoutIndex
    if not loadoutIndex then
        local equippedLoadoutData = ZO_VENGEANCE_MANAGER:GetEquippedLoadoutData()
        loadoutIndex = equippedLoadoutData:GetLoadoutIndex()
    end

    local canEquipResult = CanLoadoutRoleBeEquippedByIndex(loadoutIndex)
    if canEquipResult ~= VENGEANCE_ACTION_RESULT_SUCCESS
        and canEquipResult ~= VENGEANCE_ACTION_RESULT_ROLE_ALREADY_EQUIPPED then
        self.instructionLabel:SetText(GetString("SI_VENGEANCEACTIONRESULT", canEquipResult))
        self.instructionLabel:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        isErrorText = true
    end

    if not isErrorText then
        self.instructionLabel:SetText(GetString(SI_CAMPAIGN_VENGEANCE_SELECT_LOADOUT))
        self.instructionLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
    end
end

function ZO_Vengeance_Loadouts_Keyboard:OnShowing()
    TriggerTutorial(TUTORIAL_TRIGGER_VENGEANCE_LOADOUTS_OPENED)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self:RefreshLoadouts()
    SCENE_MANAGER:AddFragment(MEDIUM_LEFT_PANEL_BG_FRAGMENT)
    self.derivedStatsContainer:SetHidden(false)
end

function ZO_Vengeance_Loadouts_Keyboard:OnHidden()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    SCENE_MANAGER:RemoveFragment(MEDIUM_LEFT_PANEL_BG_FRAGMENT)
    self.derivedStatsContainer:SetHidden(true)
end

function ZO_Vengeance_Loadouts_Keyboard:UpdateExpandedEntryHeight()
    local selectedLoadoutData = ZO_VENGEANCE_MANAGER:GetLoadoutDataByIndex(self.selectedLoadoutIndex)
    if selectedLoadoutData then
        local height = ZO_VENGEANCE_LOADOUT_KEYBOARD_EXPANDED_EQUIPPED_ENTRY_HEIGHT
        if not selectedLoadoutData:IsEquipped() then
            local numPositiveStats = #selectedLoadoutData:GetPositiveImportantStats()
            local numNegativeStats = #selectedLoadoutData:GetNegativeImportantStats()
            local numStatsRows = zo_max(numPositiveStats, numNegativeStats)
            height = ZO_VENGEANCE_LOADOUT_KEYBOARD_EXPANDED_MIN_ENTRY_HEIGHT + (numStatsRows * ZO_VENGEANCE_LOADOUT_KEYBOARD_EXPANDED_PER_STAT_HEIGHT)
        end
        ZO_ScrollList_UpdateDataTypeHeight(self.list, DATA_ENTRY_TYPE_EXPANDED, height)
        self.expandedHeight = height
    end
end

function ZO_Vengeance_Loadouts_Keyboard:RefreshLoadouts(scrollToSelected)
    self:UpdateExpandedEntryHeight()

    ZO_ScrollList_Clear(self.list)
    self.attributeRowControlPool:ReleaseAllObjects()
    ZO_ClearTable(self.attributeRowControls)
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    for _, loadoutData in ZO_VENGEANCE_MANAGER:LoadoutDataIterator() do
        local entryData = ZO_EntryData:New(loadoutData)

        if loadoutData:GetLoadoutIndex() == self.selectedLoadoutIndex then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_ENTRY_TYPE_EXPANDED, entryData))
        else
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_ENTRY_TYPE_COLLAPSED, entryData))
        end
    end

    ZO_ScrollList_Commit(self.list)

    --Order matters. We want to do this after ZO_ScrollList_Commit so the controls can be positioned properly before we attempt to scroll to them 
    if scrollToSelected and self.selectedLoadoutIndex then
        local NO_CALLBACK = nil
        local ANIMATE_INSTANTLY = true
        ZO_ScrollList_ScrollDataToCenter(self.list, self.selectedLoadoutIndex, NO_CALLBACK, ANIMATE_INSTANTLY)
    end

    self:UpdateKeybinds()
    self:UpdateInstructionText()
    self:UpdateDerivedStatsComparisonValues()
end

function ZO_Vengeance_Loadouts_Keyboard:SetSelectedLoadoutIndex(loadoutIndex)
    if self.selectedLoadoutIndex ~= loadoutIndex then
        if loadoutIndex == nil then
            PlaySound(SOUNDS.ARMORY_BUILD_SLOT_COLLAPSED)
        else
            PlaySound(SOUNDS.ARMORY_BUILD_SLOT_EXPANDED)
            PlaySound(SOUNDS.VENGEANCE_LOADOUT_SELECTED)
        end
        self.selectedLoadoutIndex = loadoutIndex
        local SCROLL_TO_SELECTED = true
        self:RefreshLoadouts(SCROLL_TO_SELECTED)
    end
end

function ZO_Vengeance_Loadouts_Keyboard:GetSelectedLoadoutData()
    return ZO_VENGEANCE_MANAGER:GetLoadoutDataByIndex(self.selectedLoadoutIndex)
end

function ZO_Vengeance_Loadouts_Keyboard:UpdateDerivedStatsComparisonValues()
    local equippedLoadoutData = ZO_VENGEANCE_MANAGER:GetEquippedLoadoutData()
    local loadoutIndex = self.selectedLoadoutIndex
    if not loadoutIndex then
        loadoutIndex = equippedLoadoutData:GetLoadoutIndex()
    end

    local selectedLoadoutData = ZO_VENGEANCE_MANAGER:GetLoadoutDataByIndex(loadoutIndex)
    for _, statGroup in ipairs(ZO_INVENTORY_STAT_GROUPS) do
        for _, statType in ipairs(statGroup) do
            local equippedLoadoutStat = equippedLoadoutData:GetDerivedStatValueByStatType(statType)
            local selectedLoadoutStat = selectedLoadoutData:GetDerivedStatValueByStatType(statType)
            local statDelta = selectedLoadoutStat - equippedLoadoutStat
            local statControl = self.derivedStatsControls[statType]
            if statDelta ~= 0 then
                statControl.statEntry:ShowComparisonValue(statDelta)
            else
                statControl.statEntry:HideComparisonValue()
            end
        end
    end
end

-----------------------------
-- Global XML Functions
-----------------------------

function ZO_Vengeance_Loadouts_Keyboard.OnControlInitialized(control)
    VENGEANCE_LOADOUTS_KEYBOARD = ZO_Vengeance_Loadouts_Keyboard:New(control)
end

function ZO_Vengeance_Loadouts_Keyboard.CollapsedEntry_OnMouseUp(control, button, upInside)
    if upInside then
        VENGEANCE_LOADOUTS_KEYBOARD:SetSelectedLoadoutIndex(control:GetParent().dataEntry.data:GetLoadoutIndex())
    end
end

function ZO_Vengeance_Loadouts_Keyboard.ExpandedEntry_OnInitialized(control)
    control.nameLabel = control:GetNamedChild("ContainerHeaderName")
    control.iconTexture = control:GetNamedChild("ContainerHeaderIcon")
    control.isEquippedIndicator = control:GetNamedChild("ContainerHeaderCheck")
    control.divider = control:GetNamedChild("ContainerDivider")
    control.statsContainer = control:GetNamedChild("ContainerImportantStatsContainer")
    control.statsEntries = control.statsContainer:GetNamedChild("Entries")
    control.perksSkillsContainer = control:GetNamedChild("ContainerPerksSkillsContainer")
    control.perksControl = control.perksSkillsContainer:GetNamedChild("Perks")
    control.primaryActionBar = control.perksSkillsContainer:GetNamedChild("PrimaryActionBar").object
    control.backupActionBar = control.perksSkillsContainer:GetNamedChild("BackupActionBar").object
    control.primaryActionBar:SetHotbarCategory(HOTBAR_CATEGORY_PRIMARY)
    control.backupActionBar:SetHotbarCategory(HOTBAR_CATEGORY_BACKUP)
end

function ZO_Vengeance_Loadouts_Keyboard.ExpandedEntry_OnMouseUp(control, button, upInside)
    if upInside then
        VENGEANCE_LOADOUTS_KEYBOARD:SetSelectedLoadoutIndex(nil)
    end
end
