local LoreLibraryGamepad = ZO_LoreLibraryBookSetGamepad:Subclass()

function LoreLibraryGamepad:New(...)
    return ZO_LoreLibraryBookSetGamepad.New(self, ...)
end

function LoreLibraryGamepad:Initialize(control)
    ZO_LoreLibraryBookSetGamepad.Initialize(self, control)

    LORE_LIBRARY_SCENE_GAMEPAD = ZO_Scene:New("loreLibraryGamepad", SCENE_MANAGER)

    local function OnStateChanged(...)
        self:OnStateChanged(...)
    end
    LORE_LIBRARY_SCENE_GAMEPAD:RegisterCallback("StateChange", OnStateChanged)
end

function LoreLibraryGamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
        -- Open collection.
        {
            name = GetString(SI_GAMEPAD_LORE_LIBRARY_OPEN_COLLECTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                local selectedData = self.itemList:GetTargetData()
                return selectedData and selectedData.collectionIndex
            end,
            callback = function()
                local selectedData = self.itemList:GetTargetData()
                BOOK_SET_GAMEPAD:Push(selectedData)
            end,
        },
    }

    -- Jump to next section.
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self:GetMainList())
end

function LoreLibraryGamepad:SetupList(list)
    list:AddDataTemplate("ZO_GamepadLoreCollectionEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadLoreCollectionEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

local function NameSorter(left, right)
    return left.name < right.name
end

function LoreLibraryGamepad:PerformUpdate()
    self.dirty = false

    local totalCurrentlyCollected = 0
    local totalPossibleCollected = 0

    self.itemList:Clear()

    -- Get the list of categories that we need to show.
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

    -- Add the categories and their contents to the list.
    for i, categoryData in ipairs(categories) do
        local categoryIndex = categoryData.categoryIndex
        local numCollections = categoryData.numCollections

        -- Get the list of collections that we need to show.
        local collections = {}
        for collectionIndex = 1, numCollections do
            local collectionName, description, numKnownBooks, totalBooks, hidden, gamepadIcon = GetLoreCollectionInfo(categoryIndex, collectionIndex)
            if not hidden then
                collections[#collections + 1] = { categoryIndex = categoryIndex, collectionIndex = collectionIndex, name = collectionName, knownBooks = numKnownBooks, totalBooks = totalBooks, description = description, enabled = (numKnownBooks > 0), icon = gamepadIcon }

                totalCurrentlyCollected = totalCurrentlyCollected + numKnownBooks
                totalPossibleCollected = totalPossibleCollected + totalBooks
            end
        end
        table.sort(collections, NameSorter)

        -- Add the collections to the list.
        for k, collectionData in ipairs(collections) do
            local isHeader = (k == 1)

            local entryData = ZO_GamepadEntryData:New(collectionData.name, collectionData.icon)
            entryData:AddSubLabel(zo_strformat("<<1>>/<<2>>", collectionData.knownBooks, collectionData.totalBooks))
            entryData.categoryIndex = collectionData.categoryIndex
            entryData.collectionIndex = collectionData.collectionIndex
            entryData.description = collectionData.description
            entryData.enabled = collectionData.enabled
            entryData:SetFontScaleOnSelection(false)
            entryData:SetShowUnselectedSublabels(true)

            if collectionData.enabled then
                entryData:SetNameColors(ZO_SELECTED_TEXT, ZO_CONTRAST_TEXT)
                entryData:SetSubLabelColors(ZO_SELECTED_TEXT, ZO_CONTRAST_TEXT)
                entryData:SetIconDesaturation(0)
            else
                entryData:SetNameColors(ZO_DISABLED_TEXT, ZO_DISABLED_TEXT)
                entryData:SetSubLabelColors(ZO_DISABLED_TEXT, ZO_DISABLED_TEXT)
                entryData:SetIconDesaturation(1)
            end

            local categoryName = nil
            local templateName

            if isHeader then
                entryData:SetHeader(categoryData.name)
                templateName = "ZO_GamepadLoreCollectionEntryTemplateWithHeader"
            else
                templateName = "ZO_GamepadLoreCollectionEntryTemplate"
            end

            self.itemList:AddEntry(templateName, entryData)
        end
    end

    self.itemList:Commit()

    -- Update the collection count label.
    self.headerData.data1HeaderText = GetString(SI_GAMEPAD_LORE_LIBRARY_TOTAL_COLLECTED_TITLE)
    self.headerData.data1Text = zo_strformat(SI_GAMEPAD_LORE_LIBRARY_TOTAL_COLLECTED, totalCurrentlyCollected, totalPossibleCollected)

    -- Update the key bindings.
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    -- Update the header.
    self.headerData.titleText = GetString(SI_WINDOW_TITLE_LORE_LIBRARY)
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_Gamepad_LoreLibrary_OnInitialize(control)
    LORE_LIBRARY_GAMEPAD = LoreLibraryGamepad:New(control)
end
