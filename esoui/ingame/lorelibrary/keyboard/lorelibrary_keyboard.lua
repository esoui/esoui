local LoreLibrary = ZO_InitializingObject:Subclass()
local LoreLibraryScrollList

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

            if self.collectionIdToSelect then
                self.dirty = true
            end
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end
    LORE_LIBRARY_SCENE:RegisterCallback("StateChange", OnStateChanged)

    self.dirty = true
end

function LoreLibrary:InitializeCategoryList(control)
    self.navigationTree = ZO_Tree:New(control:GetNamedChild("NavigationContainerScrollChild"), 40, -10, 385)
    local function TreeHeaderSetup(node, controlHeader, data, open)
        controlHeader:SetText(data.name)

        ZO_LabelHeader_Setup(controlHeader, open)
    end
    local function TreeHeaderEquality(left, right)
        -- One of these fields will be nil and the other will be valid.
        return left.categoryIndex == right.categoryIndex and left.hirelingType == right.hirelingType
    end
    self.navigationTree:AddTemplate("ZO_LabelHeader", TreeHeaderSetup, nil, TreeHeaderEquality, nil, 0)

    local function TreeEntrySetup(node, entryControl, data, open)
        if data.hirelingType ~= nil and data.numKnownBooks < data.totalBooks then
            -- When only some messages are known: "Hireling Correspondence 15"
            entryControl:SetText(zo_strformat(SI_LORE_LIBRARY_HIRELING_CORRESPONDENCE_TREE_ENTRY, data.name, ZO_SELECTED_TEXT:Colorize(data.numKnownBooks)))
        else
            -- When any book or all messages are known: "Hireling Correspondence 15/15"
            entryControl:SetText(zo_strformat(SI_LORE_LIBRARY_KNOWN_BOOKS, data.name, data.numKnownBooks, data.totalBooks))
        end
        if data.hirelingType ~= nil then
            entryControl:SetEnabled(data.numKnownBooks > 0)
            node:SetEnabled(data.numKnownBooks > 0)
        end
    end
    local function TreeEntryOnSelected(entryControl, data, selected, reselectingDuringRebuild)
        entryControl:SetSelected(selected)
        if selected then
            self:BuildBookList()
        end

        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
    local function TreeEntryEquality(left, right)
        -- Either category and collection will be valid or hireling type will be.  Sufficient for an equality check.
        return left.categoryIndex == right.categoryIndex and left.collectionIndex == right.collectionIndex and left.hirelingType == right.hirelingType
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

    local function OnCorrespondenceUpdated(eventCode, family)
        self:BuildCategoryList()
    end

    control:RegisterForEvent(EVENT_LORE_LIBRARY_INITIALIZED, OnInitialized)
    control:RegisterForEvent(EVENT_LORE_BOOK_LEARNED, OnBookLearned)
    self.control:RegisterForEvent(EVENT_UNLOCKED_HIRELING_CORRESPONDENCE_INITIALIZED, OnInitialized)
    self.control:RegisterForEvent(EVENT_UNLOCKED_HIRELING_CORRESPONDENCE_UPDATED, OnCorrespondenceUpdated)
end

function LoreLibrary:RefreshCollectedInfo()
    self.totalCollectedLabel:SetText(zo_strformat(SI_LORE_LIBRARY_TOTAL_COLLECTED, self.totalCurrentlyCollected, self.totalPossibleCollected))
end

function LoreLibrary:OnShow()
    if self.dirty then
        self:BuildCategoryList()
    end
end

function LoreLibrary:SetCollectionIdToSelect(collectionId)
    self.collectionIdToSelect = collectionId
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

local function GetHirelingMessageCollection(hirelingType)
    local numHirelingMessages, maxHirelingMessages = GetNumUnlockedHirelingCorrespondence(hirelingType)
    local categoryData = 
    {
        hirelingType = hirelingType,
        name = GetString("SI_HIRELINGTYPE", hirelingType),
        numKnownBooks = numHirelingMessages,
        totalBooks = maxHirelingMessages,
    }
    return categoryData
end

local function GetHirelingMessages(hirelingType)
    local numHirelingMessages = GetNumUnlockedHirelingCorrespondence(hirelingType)
    local messages = {}
    for messageIndex = 1, numHirelingMessages do
        local sender, subject, body, icon = GetHirelingCorrespondenceInfoByIndex(hirelingType, messageIndex)
        local title = zo_strformat(SI_LORE_LIBRARY_HIRELING_CORRESPONDENCE_ENTRY_FORMATTER, subject, messageIndex)
        table.insert(messages, 
        {
            hirelingType = hirelingType,
            messageIndex = messageIndex,
            title = title,
            body = body,
            icon = icon,
            sender = sender,
        })
    end

    return messages
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
                table.insert(categories, { categoryIndex = categoryIndex, name = categoryName, numCollections = numCollections, })
                break
            end
        end
    end

    table.sort(categories, NameSorter)

    local collectionNodeToSelect = nil
    for i, categoryData in ipairs(categories) do
        local parent = self.navigationTree:AddNode("ZO_LabelHeader", categoryData)

        local categoryIndex = categoryData.categoryIndex
        local numCollections = categoryData.numCollections

        local collections = {}

        for collectionIndex = 1, numCollections do
            local collectionName, description, numKnownBooks, totalBooks, hidden, _, collectionId = GetLoreCollectionInfo(categoryIndex, collectionIndex)
            if not hidden then
                table.insert(collections, { categoryIndex = categoryIndex, collectionIndex = collectionIndex, name = collectionName, description = description, numKnownBooks = numKnownBooks, totalBooks = totalBooks, collectionId = collectionId, })

                self.totalCurrentlyCollected = self.totalCurrentlyCollected + numKnownBooks
                self.totalPossibleCollected = self.totalPossibleCollected + totalBooks
            end
        end

        table.sort(collections, NameSorter)

        for k, collectionData in ipairs(collections) do
            local node = self.navigationTree:AddNode("ZO_LoreLibraryNavigationEntry", collectionData, parent)

            if self.collectionIdToSelect and self.collectionIdToSelect == collectionData.collectionId then
                collectionNodeToSelect = node
            end
        end
    end

    -- Add categories for all hireling messages
    local parent = self.navigationTree:AddNode("ZO_LabelHeader", { name = GetString(SI_LORE_LIBRARY_HIRELING_CORRESPONDENCE_HEADER), })
    for hirelingType = HIRELING_TYPE_ITERATION_BEGIN, HIRELING_TYPE_ITERATION_END do
        local hirelings = {}

        local hirelingCollection = GetHirelingMessageCollection(hirelingType)
        if hirelingCollection.totalBooks > 0 then
            -- If this hireling hasn't been set up with data yet, don't show it.
            table.insert(hirelings, hirelingCollection)
        end

        for k, hirelingData in ipairs(hirelings) do
            self.navigationTree:AddNode("ZO_LoreLibraryNavigationEntry", hirelingData, parent)
        end
    end

    self.navigationTree:Commit(collectionNodeToSelect, true)

    self:RefreshCollectedInfo()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    self.collectionIdToSelect = nil
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
                local control = self.list:GetMouseOverRow()
                if control.bookIndex ~= nil then
                    ZO_LoreLibrary_ReadBook(control.categoryIndex, control.collectionIndex, control.bookIndex)
                elseif control.hirelingType ~= nil then
                    ZO_LoreLibrary_ReadHirelingCorrespondence(control.hirelingType, control.messageIndex)
                end
            end,
        },
        -- Open in Achievements
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_LORE_LIBRARY_TO_ACHIEVEMENT_ACTION),
            keybind = "UI_SHORTCUT_SECONDARY",
            visible = function()
                local targetData = self.navigationTree:GetSelectedData()
                if targetData then
                    local achievementId = GetLoreBookCollectionLinkedAchievement(targetData.categoryIndex, targetData.collectionIndex)
                    return achievementId ~= 0
                end
                return false
            end,
            callback = function()
                local targetData = self.navigationTree:GetSelectedData()
                local achievementId = GetLoreBookCollectionLinkedAchievement(targetData.categoryIndex, targetData.collectionIndex)
                SYSTEMS:GetObject("achievements"):ShowAchievement(achievementId)
                MAIN_MENU_KEYBOARD:ShowScene("achievements")
            end,
        },
    }
end

function ZO_LoreLibrary_OnInitialize(control)
    LORE_LIBRARY = LoreLibrary:New(control)
end

LoreLibraryScrollList = ZO_SortFilterList:Subclass()
local BOOK_DATA_TYPE = 1
local HIRELING_MESSAGE_DATA_TYPE = 2
local HIRELING_MESSAGE_HEADER_TYPE = 3

function LoreLibraryScrollList:Initialize(control, owner)
    ZO_SortFilterList.Initialize(self, control, owner)
    self.owner = owner
    self.keybindStripDescriptor = owner.keybindStripDescriptor

    local function SetUpBookEntry(entryControl, data)
        entryControl.owner = self
        local title, icon, known = GetLoreBookInfo(data.categoryIndex, data.collectionIndex, data.bookIndex)
        entryControl.categoryIndex = data.categoryIndex
        entryControl.collectionIndex = data.collectionIndex
        entryControl.bookIndex = data.bookIndex
        entryControl.known = known

        entryControl.text:SetText(title)
        entryControl.icon:SetTexture(icon)

        ZO_SortFilterList.SetupRow(self, entryControl, data)
    end
    ZO_ScrollList_AddDataType(self.list, BOOK_DATA_TYPE, "ZO_LoreLibrary_BookEntry", 52, SetUpBookEntry)
    
    local function SetUpHirelingMessageEntry(entryControl, data)
        entryControl.owner = self
        entryControl.hirelingType = data.hirelingType
        entryControl.messageIndex = data.messageIndex
        entryControl.known = true

        entryControl.text:SetText(data.title)
        entryControl.icon:SetTexture(data.icon)

        ZO_SortFilterList.SetupRow(self, entryControl, data)
    end
    ZO_ScrollList_AddDataType(self.list, HIRELING_MESSAGE_DATA_TYPE, "ZO_LoreLibrary_BookEntry", 52, SetUpHirelingMessageEntry)
    
    local function SetUpHirelingMessageHeaderEntry(entryControl, data)
        entryControl.owner = self
        entryControl.known = true
        entryControl.text:SetText(data.name)

        ZO_SortFilterList.SetupRow(self, entryControl, data)
    end
    ZO_ScrollList_AddDataType(self.list, HIRELING_MESSAGE_HEADER_TYPE, "ZO_LoreLibrary_HirelingMessageHeader", 60, SetUpHirelingMessageHeaderEntry)

    local function OnHighlightChanged(entryControl, highlighted)
        if highlighted then
            if not entryControl.iconAnimation then
                entryControl.iconAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("IconSlotMouseOverAnimation", entryControl.icon)
            end
            entryControl.iconAnimation:PlayForward()
        elseif entryControl.iconAnimation then
            entryControl.iconAnimation:PlayBackward()
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

        local categoryData = self.owner.navigationTree:GetSelectedData()
        if categoryData.hirelingType == nil then
            table.sort(scrollData, BookEntryComparator)
        end
    end
end

function LoreLibraryScrollList:BuildMasterList()
    -- do nothing
    -- the lore library builds all its data in FilterScrollList because it doesn't need to keep a master list around
end

function LoreLibraryScrollList:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ScrollList_Clear(self.list)

    local categoryData = self.owner.navigationTree:GetSelectedData()
    if categoryData.hirelingType ~= nil then
        local currentHirelingSenderLower = ""

        -- Fill out hireling message into the list
        local messages = GetHirelingMessages(categoryData.hirelingType)
        for index, messageData in ipairs(messages) do
            local nextSender = messageData.sender
            local nextSenderLower = zo_strlower(nextSender)
            -- ESO-862381: Compare with lower because sometimes senders scream their name
            if currentHirelingSenderLower ~= nextSenderLower then
                currentHirelingSenderLower = nextSenderLower
                -- ESO-862381, ESO-888526: If the sender is all caps, lower it before formatting it.
                -- Otherwise, leave it alone so <<C:1>> works right in non-English languages
                local senderClean = zo_strIsUpper(nextSender) and nextSenderLower or nextSender
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(HIRELING_MESSAGE_HEADER_TYPE,
                {
                    hirelingType = messageData.hirelingType, 
                    name = zo_strformat(SI_LORE_LIBRARY_HIRELING_CORRESPONDENCE_SENDER_FORMATTER, senderClean), 
                    sortOrder = index, 
                }))
            end
            messageData.sortOrder = index
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(HIRELING_MESSAGE_DATA_TYPE, messageData))
        end
    else
        -- Fill out books of a collection into the list.
        local categoryIndex = self.owner:GetSelectedCategoryIndex()
        local collectionIndex = self.owner:GetSelectedCollectionIndex()
        local totalBooks = select(4, GetLoreCollectionInfo(categoryIndex, collectionIndex))
        for bookIndex = 1, totalBooks do
            table.insert(scrollData,
                ZO_ScrollList_CreateDataEntry(BOOK_DATA_TYPE, 
                { 
                    categoryIndex = categoryIndex, 
                    collectionIndex = collectionIndex, 
                    bookIndex = bookIndex,
                })
            )
        end
    end
end

function LoreLibraryScrollList:OnRowMouseUp(control, button)
    if button == MOUSE_BUTTON_INDEX_RIGHT then
        ClearMenu()
        SetMenuHiddenCallback(function() self:UnlockSelection() end)
        self:LockSelection()

        if control.known then
            AddMenuItem(GetString(SI_LORE_LIBRARY_READ), function() 
                if control.bookIndex ~= nil then
                    ZO_LoreLibrary_ReadBook(control.categoryIndex, control.collectionIndex, control.bookIndex) 
                elseif control.hirelingType ~= nil then
                    ZO_LoreLibrary_ReadHirelingCorrespondence(control.hirelingType, control.messageIndex)
                end
            end)
        end
        if IsChatSystemAvailableForCurrentPlatform() and control.bookIndex ~= nil then
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
            if control.bookIndex ~= nil then
                ZO_LoreLibrary_ReadBook(control.categoryIndex, control.collectionIndex, control.bookIndex)
            elseif control.hirelingType ~= nil then
                ZO_LoreLibrary_ReadHirelingCorrespondence(control.hirelingType, control.messageIndex)
            end
        else
            ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_LORE_LIBRARY_UNKNOWN_BOOK, control.text:GetText()))
        end
    end
end

function LoreLibraryScrollList:GetMouseOverRow()
    return self.mouseOverRow
end