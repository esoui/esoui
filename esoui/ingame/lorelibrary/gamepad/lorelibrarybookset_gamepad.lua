ZO_LoreLibraryBookSet_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_LoreLibraryBookSet_Gamepad:Initialize(control)
    self.bookListIndex = 1
    LORE_LIBRARY_BOOK_SET_SCENE_GAMEPAD = ZO_Scene:New("bookSetGamepad", SCENE_MANAGER)
    local ACTIVATE_ON_SHOW = true
    local DONT_CREATE_TAB_BAR = false
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, DONT_CREATE_TAB_BAR, ACTIVATE_ON_SHOW, LORE_LIBRARY_BOOK_SET_SCENE_GAMEPAD)

    self.headerData = 
    {
        titleText = GetString(SI_WINDOW_TITLE_LORE_LIBRARY),
        data1HeaderText = "",
        data1Text = "",
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    self:InitializeEvents()
end

function ZO_LoreLibraryBookSet_Gamepad:InitializeEvents()
    local function Refresh()
        if self.control:IsControlHidden() then
            self.dirty = true
        else
            self:Update()
        end
    end

    self.control:RegisterForEvent(EVENT_LORE_LIBRARY_INITIALIZED, Refresh)
    self.control:RegisterForEvent(EVENT_LORE_BOOK_LEARNED, Refresh)
    self.control:RegisterForEvent(EVENT_UNLOCKED_HIRELING_CORRESPONDENCE_INITIALIZED, Refresh)
    self.control:RegisterForEvent(EVENT_UNLOCKED_HIRELING_CORRESPONDENCE_UPDATED, Refresh)
end

function ZO_LoreLibraryBookSet_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
        -- Read book
        {
            name = GetString(SI_LORE_LIBRARY_READ),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local selectedData = self:GetMainList():GetTargetData()
                if selectedData and selectedData.bookIndex then
                    if self.hirelingType then
                        ZO_LoreLibrary_ReadHirelingCorrespondence(self.hirelingType, selectedData.bookIndex)
                    else
                        if selectedData.enabled then
                            ZO_LoreLibrary_ReadBook(self.categoryIndex, self.collectionIndex, selectedData.bookIndex)
                        else
                            ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_LORE_LIBRARY_UNKNOWN_BOOK, selectedData.text))
                        end
                    end
                end
            end,
            enabled = function()
                local selectedData = self:GetMainList():GetTargetData()
                return selectedData and selectedData.enabled
            end,
        },
        -- Open in Achievements
        {
            name = GetString(SI_LORE_LIBRARY_TO_ACHIEVEMENT_ACTION),
            keybind = "UI_SHORTCUT_SECONDARY",
            visible = function()
                if self.hirelingType then
                    return false
                else
                    local achievementId = GetLoreBookCollectionLinkedAchievement(self.categoryIndex, self.collectionIndex)
                    return achievementId ~= 0
                end
            end,
            callback = function()
                local achievementId = GetLoreBookCollectionLinkedAchievement(self.categoryIndex, self.collectionIndex)
                MAIN_MENU_GAMEPAD:SelectMenuEntry(ZO_MENU_MAIN_ENTRIES.JOURNAL)
                ACHIEVEMENTS_GAMEPAD:ShowAchievement(achievementId)
            end,
        },
    }

    -- Jump to next section.
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self:GetMainList())
end

function ZO_LoreLibraryBookSet_Gamepad:SetupList(list)
    list:AddDataTemplate("ZO_GamepadSubMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadSubMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_LoreLibraryBookSet_Gamepad:Push(libraryData)
    local bookListIndex = libraryData.bookListIndex or 1
    local categoryIndex = libraryData.categoryIndex
    local collectionIndex = libraryData.collectionIndex
    local hirelingType = libraryData.hirelingType
    if (self.bookListIndex ~= bookListIndex) or (self.categoryIndex ~= categoryIndex) or (self.collectionIndex ~= collectionIndex) or (self.hirelingType ~= hirelingType) then
        self.dirty = true
    end

    self.libraryData = libraryData
    self.bookListIndex = bookListIndex
    self.categoryIndex = categoryIndex
    self.collectionIndex = collectionIndex
    self.hirelingType = hirelingType
    SCENE_MANAGER:Push("bookSetGamepad")
end

function ZO_LoreLibraryBookSet_Gamepad:PerformUpdate()
    self.dirty = false
    --Layout the list differently depending on if this is a hireling category or not
    if self.hirelingType then
        self:LayoutHirelingCollection()
    else
        self:LayoutBookCollection()
    end
end

do
    local function BookSorter(left, right)
        if left.enabled == right.enabled then
            return left.name < right.name
        end

        return left.enabled
    end

    function ZO_LoreLibraryBookSet_Gamepad:LayoutBookCollection()
        local mainList = self:GetMainList()
        mainList:Clear()

        -- Get the list of books we need to show.
        local categoryIndex = self.categoryIndex
        local collectionIndex = self.collectionIndex
        local collectionName, _, _, totalBooks = GetLoreCollectionInfo(categoryIndex, collectionIndex)
        local books = {}
        local knownBooks = 0
        for bookIndex = 1, totalBooks do
            local title, icon, known = GetLoreBookInfo(categoryIndex, collectionIndex, bookIndex)
            local bookData =
            { 
                bookIndex = bookIndex,
                name = title,
                icon = icon,
                enabled = known,
            }
            table.insert(books, bookData)
            if known then
                knownBooks = knownBooks + 1
            end
        end

        table.sort(books, BookSorter)

        -- Add the books to the list.
        for i, bookData in ipairs(books) do
            local entryData = ZO_GamepadEntryData:New(bookData.name, bookData.icon)
            entryData.bookIndex = bookData.bookIndex
            entryData.bookListIndex = i
            entryData.enabled = bookData.enabled
            entryData:SetFontScaleOnSelection(false)
            entryData:SetShowUnselectedSublabels(true)

            if bookData.enabled then
                entryData:SetNameColors(ZO_SELECTED_TEXT, ZO_CONTRAST_TEXT)
                entryData:SetIconDesaturation(0)
            else
                entryData:SetNameColors(ZO_DISABLED_TEXT, ZO_DISABLED_TEXT)
                entryData:SetIconDesaturation(1)
            end

            mainList:AddEntry("ZO_GamepadSubMenuEntryTemplate", entryData)
        end


        mainList:CommitWithoutReselect()
        mainList:SetSelectedIndexWithoutAnimation(self.bookListIndex)

        -- Update the collection count label.
        self.headerData.data1HeaderText = GetString(SI_GAMEPAD_LORE_LIBRARY_TOTAL_COLLECTED_TITLE)
        self.headerData.data1Text = zo_strformat(SI_GAMEPAD_LORE_LIBRARY_TOTAL_COLLECTED, knownBooks, totalBooks)

        -- Update the key bindings.
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

        -- Update the header.
        self.headerData.titleText = collectionName
        ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    end
end

function ZO_LoreLibraryBookSet_Gamepad:LayoutHirelingCollection()
    local mainList = self:GetMainList()
    mainList:Clear()

    -- Get the list of correspondences we need to show.
    local hirelingType = self.hirelingType
    local currentUnlocked = GetNumUnlockedHirelingCorrespondence(hirelingType)

    local currentSenderLower = ""
    for index = 1, currentUnlocked do
        local sender, subject, _, icon = GetHirelingCorrespondenceInfoByIndex(hirelingType, index)
        local senderLower = zo_strlower(sender)
        local entryData = ZO_GamepadEntryData:New(zo_strformat(SI_LORE_LIBRARY_HIRELING_CORRESPONDENCE_ENTRY_FORMATTER, subject, index), icon)
        entryData.bookIndex = index
        entryData.bookListIndex = index
        entryData.enabled = true
        entryData:SetFontScaleOnSelection(false)
        entryData:SetShowUnselectedSublabels(true)
        entryData:SetNameColors(ZO_SELECTED_TEXT, ZO_CONTRAST_TEXT)
        entryData:SetIconDesaturation(0)

        local templateName
        --Any time the sender changes, make a new header
        -- ESO-862381: Compare with lower because sometimes senders scream their name
        if senderLower ~= currentSenderLower then
            -- ESO-862381, ESO-888526: If the sender is all caps, lower it before formatting it.
            -- Otherwise, leave it alone so <<C:1>> works right in non-English languages
            local senderClean = zo_strIsUpper(sender) and senderLower or sender
            entryData:SetHeader(zo_strformat(SI_LORE_LIBRARY_HIRELING_CORRESPONDENCE_SENDER_FORMATTER, senderClean))
            templateName = "ZO_GamepadSubMenuEntryTemplateWithHeader"
            currentSenderLower = senderLower
        else
            templateName = "ZO_GamepadSubMenuEntryTemplate"
        end

        mainList:AddEntry(templateName, entryData)
    end

    mainList:CommitWithoutReselect()
    mainList:SetSelectedIndexWithoutAnimation(self.bookListIndex)

    -- Update the collection count label.
    self.headerData.data1HeaderText = GetString(SI_GAMEPAD_LORE_LIBRARY_TOTAL_COLLECTED_TITLE)
    self.headerData.data1Text = ZO_SELECTED_TEXT:Colorize(zo_strformat(SI_GAMEPAD_LORE_LIBRARY_HIRELING_CORRESPONDENCE_TOTAL_COLLECTED, currentUnlocked))

    -- Update the key bindings.
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    -- Update the header.
    self.headerData.titleText = GetString("SI_HIRELINGTYPE", hirelingType)
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_LoreLibraryBookSet_Gamepad:OnSelectionChanged(_, selectedData)
    self.libraryData.bookListIndex = selectedData.bookListIndex
end

function ZO_LoreLibraryBookSet_Gamepad_OnInitialize(control)
    LORE_LIBRARY_BOOK_SET_GAMEPAD = ZO_LoreLibraryBookSet_Gamepad:New(control)
end
