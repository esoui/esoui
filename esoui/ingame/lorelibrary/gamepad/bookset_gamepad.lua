local BookSetGamepad = ZO_LoreLibraryBookSetGamepad:Subclass()

function BookSetGamepad:New(...)
    return ZO_LoreLibraryBookSetGamepad.New(self, ...)
end

function BookSetGamepad:Initialize(control)
    ZO_LoreLibraryBookSetGamepad.Initialize(self, control)
    self.bookListIndex = 1

    BOOKSET_SCENE_GAMEPAD = ZO_Scene:New("bookSetGamepad", SCENE_MANAGER)

    local function OnStateChanged(...)
        self:OnStateChanged(...)
    end
    BOOKSET_SCENE_GAMEPAD:RegisterCallback("StateChange", OnStateChanged)
end

function BookSetGamepad:InitializeKeybindStripDescriptors()
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
                local selectedData = self.itemList:GetTargetData()
                if selectedData and selectedData.bookIndex then
                    if selectedData.enabled then
                        ZO_LoreLibrary_ReadBook(self.categoryIndex, self.collectionIndex, selectedData.bookIndex)
                    else
                        ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_LORE_LIBRARY_UNKNOWN_BOOK, selectedData.text))
                    end
                end
            end,
            enabled = function()
                local selectedData = self.itemList:GetTargetData()
                return selectedData and selectedData.enabled
            end,
        },
    }

    -- Jump to next section.
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self:GetMainList())
end

function BookSetGamepad:SetupList(list)
    list:AddDataTemplate("ZO_GamepadSubMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadSubMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

function BookSetGamepad:Push(libraryData)
    local bookListIndex = libraryData.bookListIndex or 1
    local categoryIndex = libraryData.categoryIndex
    local collectionIndex = libraryData.collectionIndex
    if (self.bookListIndex ~= bookListIndex) or (self.categoryIndex ~= categoryIndex) or (self.collectionIndex ~= collectionIndex) then
        self.dirty = true
    end

    self.libraryData = libraryData
    self.bookListIndex = bookListIndex
    self.categoryIndex = categoryIndex
    self.collectionIndex = collectionIndex
    SCENE_MANAGER:Push("bookSetGamepad")
end

local function BookSorter(left, right)
    if left.enabled == right.enabled then
        return left.name < right.name
    end

    return left.enabled
end

function BookSetGamepad:PerformUpdate()
    self.dirty = false

    self.itemList:Clear()

    -- Get the list of books we need to show.
    local categoryIndex = self.categoryIndex
    local collectionIndex = self.collectionIndex
    local collectionName, description, numKnownBooks, totalBooks, hidden = GetLoreCollectionInfo(categoryIndex, collectionIndex)
    local books = {}
    local knownBooks = 0
    for bookIndex = 1, totalBooks do
        local title, icon, known = GetLoreBookInfo(categoryIndex, collectionIndex, bookIndex)
        books[#books + 1] = { bookIndex = bookIndex, name=title, icon=icon, enabled=known }
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

        self.itemList:AddEntry("ZO_GamepadSubMenuEntryTemplate", entryData)
    end

    self.itemList:CommitWithoutReselect()
    self.itemList:SetSelectedIndexWithoutAnimation(self.bookListIndex)

    -- Update the collection count label.
    self.headerData.data1HeaderText = GetString(SI_GAMEPAD_LORE_LIBRARY_TOTAL_COLLECTED_TITLE)
    self.headerData.data1Text = zo_strformat(SI_GAMEPAD_LORE_LIBRARY_TOTAL_COLLECTED, knownBooks, totalBooks)

    -- Update the key bindings.
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    -- Update the header.
    self.headerData.titleText = collectionName
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function BookSetGamepad:OnSelectionChanged(_, selectedData)
    self.libraryData.bookListIndex = selectedData.bookListIndex
end

function ZO_Gamepad_BookSet_OnInitialize(control)
    BOOK_SET_GAMEPAD = BookSetGamepad:New(control)
end
