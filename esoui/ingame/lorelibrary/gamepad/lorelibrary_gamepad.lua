ZO_LoreLibrary_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_LoreLibrary_Gamepad:Initialize(control)
    LORE_LIBRARY_SCENE_GAMEPAD = ZO_Scene:New("loreLibraryGamepad", SCENE_MANAGER)

    local ACTIVATE_ON_SHOW = true
    local DONT_CREATE_TAB_BAR = false
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, DONT_CREATE_TAB_BAR, ACTIVATE_ON_SHOW, LORE_LIBRARY_SCENE_GAMEPAD)

    self.headerData = 
    {
        titleText = GetString(SI_WINDOW_TITLE_LORE_LIBRARY),
        data1HeaderText = "",
        data1Text = "",
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    self:InitializeEvents()
end

function ZO_LoreLibrary_Gamepad:InitializeEvents()
    local function Refresh()
        if self.control:IsControlHidden() then
            self.dirty = true
        else
            self:Update()
        end
    end

    self.control:RegisterForEvent(EVENT_LORE_LIBRARY_INITIALIZED, Refresh)
    self.control:RegisterForEvent(EVENT_LORE_BOOK_LEARNED, Refresh)
end

function ZO_LoreLibrary_Gamepad:InitializeKeybindStripDescriptors()
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
                local selectedData = self:GetMainList():GetTargetData()
                return selectedData and selectedData.collectionIndex
            end,
            callback = function()
                local selectedData = self:GetMainList():GetTargetData()
                LORE_LIBRARY_BOOK_SET_GAMEPAD:Push(selectedData)
            end,
        },
        -- Open in Achievements
        {
            name = GetString(SI_LORE_LIBRARY_TO_ACHIEVEMENT_ACTION),
            keybind = "UI_SHORTCUT_SECONDARY",
            visible = function()
                local selectedData = self:GetMainList():GetTargetData()
                if selectedData and selectedData.collectionIndex then
                    local achievementId = GetLoreBookCollectionLinkedAchievement(selectedData.categoryIndex, selectedData.collectionIndex)
                    return achievementId ~= 0
                end
                return false
            end,
            callback = function()
                local selectedData = self:GetMainList():GetTargetData()
                local achievementId = GetLoreBookCollectionLinkedAchievement(selectedData.categoryIndex, selectedData.collectionIndex)
                MAIN_MENU_GAMEPAD:SelectMenuEntry(ZO_MENU_MAIN_ENTRIES.JOURNAL)
                ACHIEVEMENTS_GAMEPAD:ShowAchievement(achievementId)
            end,
        },
    }

    -- Jump to next section.
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self:GetMainList())
end

function ZO_LoreLibrary_Gamepad:SetupList(list)
    list:AddDataTemplate("ZO_GamepadLoreCollectionEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadLoreCollectionEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_LoreLibrary_Gamepad:SetCollectionIdToSelect(collectionId)
    self.collectionIdToSelect = collectionId
    self.dirty = true
end

do
    local function NameSorter(left, right)
        return left.name < right.name
    end

    function ZO_LoreLibrary_Gamepad:PerformUpdate()
        self.dirty = false

        local totalCurrentlyCollected = 0
        local totalPossibleCollected = 0

        self:GetMainList():Clear()

        -- Get the list of categories that we need to show.
        local categories = {}
        for categoryIndex = 1, GetNumLoreCategories() do
            local categoryName, numCollections = GetLoreCategoryInfo(categoryIndex)
            for collectionIndex = 1, numCollections do
                local _, _, _, _, hidden = GetLoreCollectionInfo(categoryIndex, collectionIndex)
                if not hidden then
                    local categoryData =
                    {
                        categoryIndex = categoryIndex,
                        name = categoryName,
                        numCollections = numCollections,
                    }
                    table.insert(categories, categoryData)
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
                local collectionName, description, numKnownBooks, totalBooks, hidden, gamepadIcon, collectionId = GetLoreCollectionInfo(categoryIndex, collectionIndex)
                if not hidden then
                    local collectionData =
                    {
                        categoryIndex = categoryIndex,
                        collectionIndex = collectionIndex,
                        name = collectionName,
                        knownBooks = numKnownBooks,
                        totalBooks = totalBooks,
                        description = description,
                        enabled = numKnownBooks > 0,
                        icon = gamepadIcon,
                        collectionId = collectionId,
                    }
                    table.insert(collections, collectionData)

                    totalCurrentlyCollected = totalCurrentlyCollected + numKnownBooks
                    totalPossibleCollected = totalPossibleCollected + totalBooks
                end
            end
            table.sort(collections, NameSorter)

            -- Add the collections to the list.
            for index, collectionData in ipairs(collections) do
                local isHeader = (index == 1)

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

                local templateName
                if isHeader then
                    entryData:SetHeader(categoryData.name)
                    templateName = "ZO_GamepadLoreCollectionEntryTemplateWithHeader"
                else
                    templateName = "ZO_GamepadLoreCollectionEntryTemplate"
                end

                self:GetMainList():AddEntry(templateName, entryData)

                if self.collectionIdToSelect == collectionData.collectionId then
                    self:GetMainList():SetSelectedIndex(index)
                end
            end
        end

        self:GetMainList():Commit()

        -- Update the collection count label.
        self.headerData.data1HeaderText = GetString(SI_GAMEPAD_LORE_LIBRARY_TOTAL_COLLECTED_TITLE)
        self.headerData.data1Text = zo_strformat(SI_GAMEPAD_LORE_LIBRARY_TOTAL_COLLECTED, totalCurrentlyCollected, totalPossibleCollected)

        -- Update the key bindings.
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

        -- Update the header.
        self.headerData.titleText = GetString(SI_WINDOW_TITLE_LORE_LIBRARY)
        ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

        if self.collectionIdToSelect then
            local selectedData = self:GetMainList():GetTargetData()
            LORE_LIBRARY_BOOK_SET_GAMEPAD:Push(selectedData)
        end

        self.collectionIdToSelect = nil
    end
end

function ZO_LoreLibrary_Gamepad_OnInitialize(control)
    LORE_LIBRARY_GAMEPAD = ZO_LoreLibrary_Gamepad:New(control)
end
