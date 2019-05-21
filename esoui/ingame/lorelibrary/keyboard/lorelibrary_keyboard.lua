local LoreLibrary = ZO_Object:Subclass()
local LoreLibraryScrollList

function LoreLibrary:New(...)
    local loreLibrary = ZO_Object.New(self)
    loreLibrary:Initialize(...)
    
    return loreLibrary
end

function LoreLibrary:Initialize(control)
    control.owner = self
    self.control = control

    self.totalCollectedLabel = control:GetNamedChild("TotalCollected")

    self:InitializeKeybindStripDescriptors()
    self:InitializeCategoryList(control)
    self:InitializeBookList(control)
    self:InitializeEvents(control)

    LORE_LIBRARY_SCENE = ZO_Scene:New("loreLibrary", SCENE_MANAGER)

    local function OnStateChanged(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end
    LORE_LIBRARY_SCENE:RegisterCallback("StateChange", OnStateChanged)

    self.dirty = true
end

function LoreLibrary:InitializeCategoryList(control)
    self.navigationTree = ZO_Tree:New(control:GetNamedChild("NavigationContainerScrollChild"), 40, -10, 385)
    local function TreeHeaderSetup(node, control, data, open)
        control:SetText(data.name)

        ZO_LabelHeader_Setup(control, open)
    end
    local function TreeHeaderEquality(left, right)
        return left.categoryIndex == right.categoryIndex
    end
    self.navigationTree:AddTemplate("ZO_LabelHeader", TreeHeaderSetup, nil, TreeHeaderEquality, nil, 0)

    local function TreeEntrySetup(node, control, data, open)
        control:SetText(zo_strformat(SI_LORE_LIBRARY_KNOWN_BOOKS, data.name, data.numKnownBooks, data.totalBooks))
    end
    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected then
            self:BuildBookList()
        end
    end
    local function TreeEntryEquality(left, right)
        return left.categoryIndex == right.categoryIndex and left.collectionIndex == right.collectionIndex
    end
    self.navigationTree:AddTemplate("ZO_LoreLibraryNavigationEntry", TreeEntrySetup, TreeEntryOnSelected, TreeEntryEquality)

    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function LoreLibrary:InitializeBookList(control)
    self.list = LoreLibraryScrollList:New(control, self)
end

function LoreLibrary:InitializeEvents(control)
    local function OnInitialized()
        self:BuildCategoryList()
    end

    local function OnBookLearned(eventCode, categoryIndex, collectionIndex, bookIndex)
        self:BuildCategoryList()
    end

    control:RegisterForEvent(EVENT_LORE_LIBRARY_INITIALIZED, OnInitialized)
    control:RegisterForEvent(EVENT_LORE_BOOK_LEARNED, OnBookLearned)
end

function LoreLibrary:RefreshCollectedInfo()
    self.totalCollectedLabel:SetText(zo_strformat(SI_LORE_LIBRARY_TOTAL_COLLECTED, self.totalCurrentlyCollected, self.totalPossibleCollected))
end

function LoreLibrary:OnShow()
    if self.dirty then
        self:BuildCategoryList()
    end
end

function LoreLibrary:GetSelectedCategoryIndex()
    local selectedData = self.navigationTree:GetSelectedData()
    if selectedData then
        return selectedData.categoryIndex
    end
end

function LoreLibrary:GetSelectedCollectionIndex()
    local selectedData = self.navigationTree:GetSelectedData()
    if selectedData then
        return selectedData.collectionIndex
    end
end

function LoreLibrary:BuildBookList()
    self.list:RefreshData()
end

local function NameSorter(left, right)
    return left.name < right.name
end

function LoreLibrary:BuildCategoryList()
    if self.control:IsControlHidden() then
        self.dirty = true
        return
    end

    self.totalCurrentlyCollected = 0
    self.totalPossibleCollected = 0

    self.navigationTree:Reset()

    local categories = {}
    for categoryIndex = 1, GetNumLoreCategories() do
        local categoryName, numCollections = GetLoreCategoryInfo(categoryIndex)
        for collectionIndex = 1, numCollections do
            local _, _, _, _, hidden = GetLoreCollectionInfo(categoryIndex, collectionIndex)
            if not hidden then
                categories[#categories + 1] = { categoryIndex = categoryIndex, name = categoryName, numCollections = numCollections }
                break
            end
        end
    end

    table.sort(categories, NameSorter)

    for i, categoryData in ipairs(categories) do
        local parent = self.navigationTree:AddNode("ZO_LabelHeader", categoryData)

        local categoryIndex = categoryData.categoryIndex
        local numCollections = categoryData.numCollections

        local collections = {}

        for collectionIndex = 1, numCollections do
            local collectionName, description, numKnownBooks, totalBooks, hidden = GetLoreCollectionInfo(categoryIndex, collectionIndex)
            if not hidden then
                collections[#collections + 1] = { categoryIndex = categoryIndex, collectionIndex = collectionIndex, name = collectionName, description = description, numKnownBooks = numKnownBooks, totalBooks = totalBooks }

                self.totalCurrentlyCollected = self.totalCurrentlyCollected + numKnownBooks
                self.totalPossibleCollected = self.totalPossibleCollected + totalBooks
            end
        end

        table.sort(collections, NameSorter)
        
        for k, collectionData in ipairs(collections) do
            self.navigationTree:AddNode("ZO_LoreLibraryNavigationEntry", collectionData, parent)
        end
    end

    self.navigationTree:Commit()

    self:RefreshCollectedInfo()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    self.dirty = false
end

function LoreLibrary:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        -- Read
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_LORE_LIBRARY_READ),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function() return self.list:GetMouseOverRow() and self.list:GetMouseOverRow().known end,
            callback = function()
                ZO_LoreLibrary_ReadBook(self.list:GetMouseOverRow().categoryIndex, self.list:GetMouseOverRow().collectionIndex, self.list:GetMouseOverRow().bookIndex)
            end,
        },
    }
end

function ZO_LoreLibrary_OnInitialize(control)
    LORE_LIBRARY = LoreLibrary:New(control)
end

LoreLibraryScrollList = ZO_SortFilterList:Subclass()
local BOOK_DATA_TYPE = 1

function LoreLibraryScrollList:New(...)
    return ZO_SortFilterList.New(self, ...)
end

function LoreLibraryScrollList:Initialize(control, owner)
    ZO_SortFilterList.Initialize(self, control, owner)
    self.owner = owner
    self.keybindStripDescriptor = owner.keybindStripDescriptor

    local function SetUpBookEntry(control, data)
        control.owner = self

        local title, icon, known = GetLoreBookInfo(data.categoryIndex, data.collectionIndex, data.bookIndex)
        control.categoryIndex = data.categoryIndex
        control.collectionIndex = data.collectionIndex
        control.bookIndex = data.bookIndex
        control.known = known

        control.text:SetText(title)
        control.icon:SetTexture(icon)

        ZO_SortFilterList.SetupRow(self, control, data)
    end

    ZO_ScrollList_AddDataType(self.list, BOOK_DATA_TYPE, "ZO_LoreLibrary_BookEntry", 52, SetUpBookEntry)

    local function OnHighlightChanged(control, highlighted)
        if highlighted then
            if not control.iconAnimation then
                control.iconAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("IconSlotMouseOverAnimation", control.icon)
            end
            control.iconAnimation:PlayForward()
        elseif control.iconAnimation then
            control.iconAnimation:PlayBackward()
        end
    end
    ZO_ScrollList_EnableHighlight(self.list, "ZO_TallListHighlight", OnHighlightChanged)
end

function LoreLibraryScrollList:GetRowColors(data, mouseIsOver, control)
    local known = control.known
    if mouseIsOver then
        return ZO_SELECTED_TEXT, known and 0 or 1
    end
    if known then
        return ZO_NORMAL_TEXT, 0
    end
    return ZO_DISABLED_TEXT, 1
end

function LoreLibraryScrollList:ColorRow(control, data, mouseIsOver)
    local textColor, iconDesaturate = self:GetRowColors(data, mouseIsOver, control)
    control.text:SetColor(textColor:UnpackRGBA())
    control.icon:SetDesaturation(iconDesaturate)
end

do
    local function BookEntryComparator(leftScrollData, rightScrollData)
        local leftData = leftScrollData.data
        local rightData = rightScrollData.data
        local leftTitle, _, leftKnown = GetLoreBookInfo(leftData.categoryIndex, leftData.collectionIndex, leftData.bookIndex)
        local rightTitle, _, rightKnown = GetLoreBookInfo(rightData.categoryIndex, rightData.collectionIndex, rightData.bookIndex)

        if leftKnown == rightKnown then
            return leftTitle < rightTitle
        end

        return leftKnown
    end

    function LoreLibraryScrollList:SortScrollList()
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        table.sort(scrollData, BookEntryComparator)
    end
end

function LoreLibraryScrollList:BuildMasterList()
    -- do nothing
    -- the lore library builds all its data in FilterScrollList because it doesn't need to keep a master list around
end

function LoreLibraryScrollList:FilterScrollList()
    local categoryIndex = self.owner:GetSelectedCategoryIndex()
    local collectionIndex = self.owner:GetSelectedCollectionIndex()

    local totalBooks = select(4, GetLoreCollectionInfo(categoryIndex, collectionIndex))

    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ScrollList_Clear(self.list)

    for bookIndex = 1, totalBooks do
        scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(BOOK_DATA_TYPE, { categoryIndex = categoryIndex, collectionIndex = collectionIndex, bookIndex = bookIndex })
    end
end

function LoreLibraryScrollList:OnRowMouseUp(control, button)
    if button == MOUSE_BUTTON_INDEX_RIGHT then
        ClearMenu()
        SetMenuHiddenCallback(function() self:UnlockSelection() end)
        self:LockSelection()

        if control.known then
            AddMenuItem(GetString(SI_LORE_LIBRARY_READ), function() ZO_LoreLibrary_ReadBook(control.categoryIndex, control.collectionIndex, control.bookIndex) end)
        end
        if IsChatSystemAvailableForCurrentPlatform() then
            AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), function()
                local link = ZO_LinkHandler_CreateChatLink(GetLoreBookLink, control.categoryIndex, control.collectionIndex, control.bookIndex)
                ZO_LinkHandler_InsertLink(link) 
            end)
        end
        ShowMenu(control)
    end
end

function LoreLibraryScrollList:OnMouseDoubleClick(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        if control.known then
            ZO_LoreLibrary_ReadBook(control.categoryIndex, control.collectionIndex, control.bookIndex)
        else
            ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_LORE_LIBRARY_UNKNOWN_BOOK, control.text:GetText()))
        end
    end
end

function LoreLibraryScrollList:GetMouseOverRow()
    return self.mouseOverRow
end