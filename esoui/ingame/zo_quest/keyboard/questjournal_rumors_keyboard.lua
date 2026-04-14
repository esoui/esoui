ZO_QUEST_JOURNAL_RUMOR_ENTRY_HEIGHT_KEYBOARD = 52

local RUMOR_LIST_RUMOR_ENTRY_ID = 1

local CATEGORY_TYPE_ACTIVE = "active"
local CATEGORY_TYPE_COMPLETE = "complete"

ZO_QuestJournal_Rumors_Keyboard = ZO_InitializingObject:Subclass()

function ZO_QuestJournal_Rumors_Keyboard:Initialize(control, owner)
    self.control = control
    self.owner = owner

    self.rumorCountLabel = control:GetNamedChild("RumorCount")

    self.mainPanel = control:GetNamedChild("Main")
    self.emptyTextLabel = self.mainPanel:GetNamedChild("EmptyText")

    self.detailsPanel = control:GetNamedChild("Details")

    self.listDirty = true

    self.fragment = ZO_SimpleSceneFragment:New(control)
    QUEST_JOURNAL_RUMORS_FRAGMENT_KEYBOARD = self.fragment
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == ZO_STATE.SHOWING then
            if self.listDirty then
                self:RefreshRumorCount()
                self:RefreshNavigationTree()
            end

            self:ShowMainPanel()
        elseif newState == ZO_STATE.HIDDEN then
        end
    end)

    self:InitializeNavigationTree()
    self:InitializeRumorList()
    self:InitializeRumorDetails()
    self:InitializeKeybindStripDescriptor()

    self:RegisterForEvents()
end

function ZO_QuestJournal_Rumors_Keyboard:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            name = GetString(SI_QUEST_JOURNAL_RUMORS_ABANDON_ACTION),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                local rumorId
                if self.mouseOverRumorEntry then
                    rumorId = self.mouseOverRumorEntry.data:GetId()
                else
                    rumorId = self.selectedRumorData:GetId()
                end
                RUMOR_MANAGER:ConfirmAbandonRumor(rumorId)
            end,
            visible = function()
                if self.mouseOverRumorEntry then
                    return self.mouseOverRumorEntry.data:IsPending()
                end
                if self.selectedRumorData then
                    return self.selectedRumorData:IsPending()
                end
                return false
            end
        }
    }
end

function ZO_QuestJournal_Rumors_Keyboard:GetKeybindStripDescriptor()
    return self.keybindStripDescriptor
end

function ZO_QuestJournal_Rumors_Keyboard:InitializeNavigationTree()
    self.navigationContainer = self.mainPanel:GetNamedChild("NavigationContainer")
    self.navigationTree = ZO_Tree:New(self.navigationContainer:GetNamedChild("ScrollChild"), 60, -10, 300)

    local function TreeHeaderSetup(node, control, name, open, userRequested)
        control:SimpleArrowSetup(name, open)

        ZO_IconHeader_UpdateSize(control)

        if open and userRequested then
            self.navigationTree:SelectFirstChild(node)
        end
    end

    self.navigationTree:AddTemplate("ZO_SimpleArrowIconHeader", TreeHeaderSetup, nil, nil, nil, 0)

    local function TreeEntrySetup(node, control, data, open)
        local categoryName = GetString("SI_RUMORTYPE_JOURNALCATEGORY", data.rumorType)
        control:SetText(categoryName)

        control:SetSelected(false)
        local NOT_SELECTED = false
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected and not reselectingDuringRebuild then
            -- TODO Rumors: Don't refresh if details showing?
            self:RefreshRumorList()
        end
    end

    local function TreeEntryEquality(left, right)
        return left.rumorType == right.rumorType
    end
    self.navigationTree:AddTemplate("ZO_QuestJournal_RumorNavigationEntry", TreeEntrySetup, TreeEntryOnSelected, TreeEntryEquality)

    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function ZO_QuestJournal_Rumors_Keyboard:InitializeRumorList()
    self.rumorListContainer = self.mainPanel:GetNamedChild("RumorListContainer")
    self.rumorListDescription = self.rumorListContainer:GetNamedChild("Description")
    self.rumorList = self.rumorListContainer:GetNamedChild("List")

    local function RumorEntrySetup(control, data)
        control.owner = self
        control.data = data
        local nameLabel = control:GetNamedChild("Name")
        nameLabel:SetText(data:GetFormattedDisplayName())
    end

    ZO_ScrollList_AddDataType(self.rumorList, RUMOR_LIST_RUMOR_ENTRY_ID, "ZO_QuestJournal_RumorListEntry", ZO_QUEST_JOURNAL_RUMOR_ENTRY_HEIGHT_KEYBOARD, RumorEntrySetup)

    ZO_ScrollList_EnableHighlight(self.rumorList, "ZO_ThinListHighlight")
end

function ZO_QuestJournal_Rumors_Keyboard:InitializeRumorDetails()
    self.backLabel = self.detailsPanel:GetNamedChild("BackLabel")
    self.backLabel.enabled = true
    self.backLabel.allowIconScaling = false
    self.backLabel.OnMouseUp = function()
        self:ShowMainPanel()
    end

    self.rumorDetailsTitleLabel = self.detailsPanel:GetNamedChild("Title")

    self.rumorInfoContainer = self.detailsPanel:GetNamedChild("RumorInfoContainer")
    local scrollChildControl = self.rumorInfoContainer:GetNamedChild("ScrollChild")
    self.rumorInfoBGTitle = scrollChildControl:GetNamedChild("BGTitle")
    self.rumorInfoBGTextLabel = scrollChildControl:GetNamedChild("BGText")
    self.rumorInfoOutcomeTitle = scrollChildControl:GetNamedChild("OutcomeTitle")
    self.rumorInfoOutcomeLabel = scrollChildControl:GetNamedChild("OutcomeText")

    self.rumorDetailsDivider = self.detailsPanel:GetNamedChild("Divider")

    self.rumorClueContainer = self.detailsPanel:GetNamedChild("RumorClueContainer")
    scrollChildControl = self.rumorClueContainer:GetNamedChild("ScrollChild")
    self.rumorClueListContainer = scrollChildControl:GetNamedChild("ClueListContainer")

    self.cluePool = ZO_ControlPool:New("ZO_QuestJournal_RumorClueEntry", self.rumorClueListContainer, "Clue")
end

function ZO_QuestJournal_Rumors_Keyboard:RegisterForEvents()
    local function OnRumorUpdated(rumorData)
        if self:IsShowing() then
            self:RefreshRumorCount()
            if self.selectedRumorData and self.selectedRumorData:GetId() == rumorData:GetId() then
                if rumorData:IsPending() or rumorData:IsComplete() then
                    self:RefreshRumorDetails()
                else
                    -- we must have abandoned the rumor
                    self:RefreshNavigationTree()
                    self:ShowMainPanel()
                end
            else
                self:RefreshNavigationTree()
            end
        else
            self.listDirty = true
        end
    end
    RUMOR_MANAGER:RegisterCallback("SingleRumorUpdated", OnRumorUpdated)

    local function OnRumorsUpdated()
        if self:IsShowing() then
            self:RefreshRumorCount()
            self:RefreshNavigationTree()
            self:ShowMainPanel()
        else
            self.listDirty = true
        end
    end
    RUMOR_MANAGER:RegisterCallback("RumorsUpdated", OnRumorsUpdated)
end

function ZO_QuestJournal_Rumors_Keyboard:IsShowing()
    return self.fragment:IsShowing()
end

function ZO_QuestJournal_Rumors_Keyboard:RefreshRumorCount()
    self.rumorCountLabel:SetText(zo_strformat(SI_QUEST_JOURNAL_RUMORS_CURRENT_MAX_RUMORS_KEYBOARD, GetNumPendingRumors(), GetMaxPendingRumors()))
end

function ZO_QuestJournal_Rumors_Keyboard:RefreshNavigationTree()
    self.rumorIndexToTreeNode = {}

    ClearTooltip(InformationTooltip)

    self.navigationTree:Reset()

    local activeCategoryString = GetString(SI_QUEST_JOURNAL_RUMORS_ACTIVE_CATEGORY)
    local activeRumorsNode = self.navigationTree:AddNode("ZO_SimpleArrowIconHeader", activeCategoryString)

    for rumorType = RUMOR_TYPE_ITERATION_BEGIN, RUMOR_TYPE_ITERATION_END do
        local subCategoryInfo =
        {
            rumorType = rumorType,
            categoryType = CATEGORY_TYPE_ACTIVE,
        }
        local rumorNode = self.navigationTree:AddNode("ZO_QuestJournal_RumorNavigationEntry", subCategoryInfo, activeRumorsNode)
    end

    if GetNumCompleteRumors() > 0 then
        local completedCategoryString = GetString(SI_QUEST_JOURNAL_RUMORS_COMPLETED_CATEGORY)
        local completedRumorsNode = self.navigationTree:AddNode("ZO_SimpleArrowIconHeader", completedCategoryString)

        for rumorType = RUMOR_TYPE_ITERATION_BEGIN, RUMOR_TYPE_ITERATION_END do
            if RUMOR_MANAGER:DoesRumorTypeHaveMatchingRumor(rumorType, {ZO_RumorData.IsComplete}) then
                local subCategoryInfo =
                {
                    rumorType = rumorType,
                    categoryType = CATEGORY_TYPE_COMPLETE,
                }
                local rumorNode = self.navigationTree:AddNode("ZO_QuestJournal_RumorNavigationEntry", subCategoryInfo, completedRumorsNode)
            end
        end
    end

    self.navigationTree:Commit()

    self:RefreshRumorList()

    self.listDirty = false
end

function ZO_QuestJournal_Rumors_Keyboard:RefreshActiveRumorList(rumorType)
    local list = self.rumorList

    self.rumorListDescription:SetHidden(false)
    list:ClearAnchors()
    list:SetAnchor(TOPLEFT, self.rumorListDescription, BOTTOMLEFT, 0, 20, ANCHOR_CONSTRAINS_Y)
    list:SetAnchor(BOTTOMRIGHT)

    ZO_ScrollList_Clear(list)

    local scrollData = ZO_ScrollList_GetDataList(list)

    for index, rumorData in RUMOR_MANAGER:RumorTypeRumorIterator(rumorType, {ZO_RumorData.IsNotComplete}) do
        local entryData =
        {
            rumorData = rumorData,
        }

        local entryData = ZO_EntryData:New(rumorData)
        entryData:SetupAsScrollListDataEntry(RUMOR_LIST_RUMOR_ENTRY_ID)

        table.insert(scrollData, entryData)
    end

    local function RumorSortFunction(left, right)
        -- Pending rumors first
        local leftPending = left:IsPending()
        local rightPending = right:IsPending()
        if leftPending ~= rightPending then
            return leftPending
        end

        -- If they're both pending, alphabetical sort
        -- rumors that aren't pending all have the same display name
        if leftPending then
            local leftDisplayName = left:GetDisplayName()
            local rightDisplayName = right:GetDisplayName()
            if leftDisplayName ~= rightDisplayName then
                return leftDisplayName < rightDisplayName
            end
        end

        -- fallback to the rumorId
        return left:GetId() < right:GetId()
    end

    table.sort(scrollData, RumorSortFunction)

    if #scrollData == 0 then
        local rumorCategoryString = ZO_SELECTED_TEXT:Colorize(GetString("SI_RUMORTYPE_JOURNALCATEGORY", rumorType))
        local emptyText = zo_strformat(SI_QUEST_JOURNAL_RUMORS_NO_PENDING_RUMORS, rumorCategoryString)
        self.emptyTextLabel:SetText(emptyText)
        self.emptyTextLabel:SetHidden(false)
        self.rumorListContainer:SetHidden(true)
    else
        self.emptyTextLabel:SetHidden(true)
        self.rumorListContainer:SetHidden(false)
    end

    ZO_ScrollList_Commit(list)
end

function ZO_QuestJournal_Rumors_Keyboard:RefreshCompletedRumorList(rumorType)
    local list = self.rumorList

    self.rumorListDescription:SetHidden(true)
    list:ClearAnchors()
    list:SetAnchor(TOPLEFT, self.rumorListDescription, TOPLEFT, 0, 0, ANCHOR_CONSTRAINS_Y)
    list:SetAnchor(BOTTOMRIGHT)

    ZO_ScrollList_Clear(list)

    local scrollData = ZO_ScrollList_GetDataList(list)

    for index, rumorData in RUMOR_MANAGER:RumorTypeRumorIterator(rumorType, {ZO_RumorData.IsComplete}) do
        local entryData =
        {
            rumorData = rumorData,
        }

        local entryData = ZO_EntryData:New(rumorData)
        entryData:SetupAsScrollListDataEntry(RUMOR_LIST_RUMOR_ENTRY_ID)

        table.insert(scrollData, entryData)
    end

    local function RumorSortFunction(left, right)
        local leftDisplayName = left:GetDisplayName()
        local rightDisplayName = right:GetDisplayName()
        if leftDisplayName ~= rightDisplayName then
            return leftDisplayName < rightDisplayName
        end

        -- fallback to the rumorId
        return left:GetId() < right:GetId()
    end

    table.sort(scrollData, RumorSortFunction)

    self.emptyTextLabel:SetHidden(true)
    self.rumorListContainer:SetHidden(false)

    ZO_ScrollList_Commit(list)
end

function ZO_QuestJournal_Rumors_Keyboard:RefreshRumorList()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    local rumorCategoryData = self.navigationTree:GetSelectedData()

    if rumorCategoryData.categoryType == CATEGORY_TYPE_ACTIVE then
        local rumorType = rumorCategoryData.rumorType
        self:RefreshActiveRumorList(rumorType)
    else -- CATEGORY_TYPE_COMPLETE
        local rumorType = rumorCategoryData.rumorType
        self:RefreshCompletedRumorList(rumorType)
    end
end

function ZO_QuestJournal_Rumors_Keyboard:RefreshRumorDetails()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    local rumorData = self.selectedRumorData

    self.rumorDetailsTitleLabel:SetText(rumorData:GetFormattedDisplayName())

    local isRumorPending = rumorData:IsPending()
    self.rumorInfoOutcomeTitle:SetHidden(isRumorPending)
    self.rumorInfoOutcomeLabel:SetHidden(isRumorPending)
    self.rumorDetailsDivider:SetHidden(not isRumorPending)

    self.rumorInfoContainer:ClearAnchors()
    self.rumorInfoContainer:SetAnchor(TOPLEFT, self.rumorDetailsTitleLabel, BOTTOMLEFT, 0, 15, ANCHOR_CONSTRAINS_Y)
    self.rumorInfoBGTitle:ClearAnchors()
    if isRumorPending then
        self.rumorInfoContainer:SetAnchor(BOTTOMRIGHT, nil, RIGHT, -33, 50)
        self.rumorInfoBGTitle:SetAnchor(TOPLEFT)
        self.rumorInfoOutcomeLabel:SetText("")
    else
        self.rumorInfoContainer:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, -33, -25)
        self.rumorInfoBGTitle:SetAnchor(TOPLEFT, self.rumorInfoOutcomeLabel, BOTTOMLEFT, -25, 10)
        self.rumorInfoOutcomeLabel:SetText(rumorData:GetCompleteText())
    end

    self.rumorInfoBGTextLabel:SetText(rumorData:GetBackgroundText())

    self.cluePool:ReleaseAllObjects()

    local numClues = rumorData:GetNumHints()
    local previousClueControl = nil
    for clueIndex = 1, numClues do
        if rumorData:HasDiscoveredHint(clueIndex) then
            local clueControl = self.cluePool:AcquireObject()
            clueControl.rumorData = rumorData
            clueControl.clueIndex = clueIndex

            local clueNameLabel = clueControl:GetNamedChild("Name")
            clueNameLabel:SetText(rumorData:GetHintDisplayName(clueIndex))

            local clueIconControl = clueControl:GetNamedChild("Icon")
            clueIconControl:SetTexture(rumorData:GetHintIcon(clueIndex))

            local clueBookButton = clueControl:GetNamedChild("OpenBook")
            local clueBookId = rumorData:GetHintBook(clueIndex)
            local hasBook = clueBookId ~= 0
            clueBookButton:SetHidden(not hasBook)
            if hasBook then
                local categoryIndex, collectionIndex, bookIndex = GetLoreBookIndicesFromBookId(clueBookId)
                clueBookButton:SetHandler("OnClicked", function()
                    ZO_LoreLibrary_ReadBook(categoryIndex, collectionIndex, bookIndex)
                end)
            else
                clueBookButton:SetHandler("OnClicked", nil)
            end

            if previousClueControl then
                clueControl:SetAnchor(TOPLEFT, previousClueControl, BOTTOMLEFT, 0, 2)
            else
                clueControl:SetAnchor(TOPLEFT, nil, TOPLEFT)
            end

            previousClueControl = clueControl
        end
    end

    self.rumorClueContainer:SetHidden(not self.cluePool:HasActiveObjects())
end

function ZO_QuestJournal_Rumors_Keyboard:ShowRumorDetails()
    self.mainPanel:SetHidden(true)

    self.detailsPanel:SetHidden(false)
    self:RefreshRumorDetails()
end

function ZO_QuestJournal_Rumors_Keyboard:ShowMainPanel()
    self.selectedRumorData = nil
    self.detailsPanel:SetHidden(true)

    self.mainPanel:SetHidden(false)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_QuestJournal_Rumors_Keyboard:GetSelectedRumorData()
    return self.selectedRumorData
end

function ZO_QuestJournal_Rumors_Keyboard:HasSelectedRumorData()
    return self.selectedRumorData ~= nil
end

-- Rumor Entry

function ZO_QuestJournal_Rumors_Keyboard:TrySelectRumorEntryFromList(control)
    local entry = ZO_ScrollList_GetData(control)
    self.selectedRumorData = entry
    if entry and (entry:IsPending() or entry:IsComplete()) then
        self:ShowRumorDetails()
    end
end

function ZO_QuestJournal_Rumors_Keyboard:OnRumorEntryMouseEnter(control)
    self:SetMouseOverRumorEntry(control)

    ZO_ScrollList_MouseEnter(self.rumorList, control)
end

function ZO_QuestJournal_Rumors_Keyboard:OnRumorEntryMouseExit(control)
    self:SetMouseOverRumorEntry(nil)

    ZO_ScrollList_MouseExit(self.rumorList, control)
end

function ZO_QuestJournal_Rumors_Keyboard:SetMouseOverRumorEntry(control)
    self.mouseOverRumorEntry = control

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_QuestJournal_Rumors_Keyboard:GetMouseOverRumorEntry()
    return self.mouseOverRumorEntry
end

function ZO_QuestJournal_Rumors_Keyboard:HasMouseOverRumorEntry()
    return self.mouseOverRumorEntry ~= nil
end

-- Clue Entry

function ZO_QuestJournal_Rumors_Keyboard:OnClueEntryMouseEnter(control)
    if not self:IsShowing() then
        return
    end

    local rumorData = control.rumorData
    local clueIndex = control.clueIndex

    InitializeTooltip(ItemTooltip, control, RIGHT, -5, 0, LEFT)

    ItemTooltip:SetPendingRumorHint(rumorData:GetId(), clueIndex)

    local bookButton = control:GetNamedChild("OpenBook")
    if not bookButton:IsControlHidden() then
        local nameLabel = control:GetNamedChild("Name")
        nameLabel:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
    end
end

function ZO_QuestJournal_Rumors_Keyboard:OnClueEntryMouseExit(control)
    ClearTooltip(ItemTooltip)

    local nameLabel = control:GetNamedChild("Name")
    nameLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGB())
end

-- Rumor Entry XML

function ZO_QuestJournal_Rumors_Keyboard.OnMouseEnterRumorEntry(control)
    if not ZO_QUEST_JOURNAL_RUMORS_KEYBOARD:IsShowing() then
        return
    end

    ZO_QUEST_JOURNAL_RUMORS_KEYBOARD:OnRumorEntryMouseEnter(control)
end

function ZO_QuestJournal_Rumors_Keyboard.OnMouseExitRumorEntry(control)
    ZO_QUEST_JOURNAL_RUMORS_KEYBOARD:OnRumorEntryMouseExit(control)
end

function ZO_QuestJournal_Rumors_Keyboard.OnMouseClickRumorEntry(control, button, upInside)
    if not upInside or button ~= MOUSE_BUTTON_INDEX_LEFT or not ZO_QUEST_JOURNAL_RUMORS_KEYBOARD:IsShowing() then
        return
    end

    ZO_QUEST_JOURNAL_RUMORS_KEYBOARD:TrySelectRumorEntryFromList(control)
end

-- Clue Entry XML

function ZO_QuestJournal_Rumors_Keyboard.OnInitializeClueEntry(control)
    local bookButton = control:GetNamedChild("OpenBook")

    control:SetHandler("OnMouseEnter", function()
        ZO_QUEST_JOURNAL_RUMORS_KEYBOARD:OnClueEntryMouseEnter(control)
        if not bookButton:IsControlHidden() then
            bookButton:SetShowingHighlight(true)
        end
    end)

    control:SetHandler("OnMouseExit", function()
        ZO_QUEST_JOURNAL_RUMORS_KEYBOARD:OnClueEntryMouseExit(control)
        if not bookButton:IsControlHidden() then
            bookButton:SetShowingHighlight(false)
        end
    end)

    control:SetHandler("OnMouseDown", function()
        if not bookButton:IsControlHidden() then
            bookButton:SetState(BSTATE_PRESSED)
        end
    end)

    control:SetHandler("OnMouseUp", function(_, button, upInside)
        bookButton:SetState(BSTATE_NORMAL)
        if not bookButton:IsControlHidden() then
            if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
                bookButton:GetHandler("OnClicked")(bookButton)
            end
        end
    end)
end

function ZO_QuestJournal_Rumors_Keyboard.OnMouseEnterClueEntry(control)
    ZO_QUEST_JOURNAL_RUMORS_KEYBOARD:OnClueEntryMouseEnter(control)
end

function ZO_QuestJournal_Rumors_Keyboard.OnMouseExitClueEntry(control)
    ZO_QUEST_JOURNAL_RUMORS_KEYBOARD:OnClueEntryMouseExit(control)
end
