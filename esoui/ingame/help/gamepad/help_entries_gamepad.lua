local HelpTutorialsEntriesGamepad = ZO_HelpTutorialsGamepad:Subclass()

function HelpTutorialsEntriesGamepad:New(...)
    return ZO_HelpTutorialsGamepad.New(self, ...)
end

function HelpTutorialsEntriesGamepad:Initialize(control)
    ZO_HelpTutorialsGamepad.Initialize(self, control)

    local helpEntriesFragment = ZO_FadeSceneFragment:New(control)
    HELP_TUTORIALS_ENTRIES_GAMEPAD_SCENE = ZO_Scene:New("helpTutorialsEntriesGamepad", SCENE_MANAGER)
    HELP_TUTORIALS_ENTRIES_GAMEPAD_SCENE:AddFragment(helpEntriesFragment)

    local function OnStateChanged(...)
        self:OnStateChanged(...)
    end
    HELP_TUTORIALS_ENTRIES_GAMEPAD_SCENE:RegisterCallback("StateChange", OnStateChanged)

    local function OnLinkClicked(...)
        if IsInGamepadPreferredMode() then
            return self.OnLinkClicked(...)
        end
    end

    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, OnLinkClicked, self)
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, OnLinkClicked, self)
end

function HelpTutorialsEntriesGamepad:SelectOrQueueHelpEntry(categoryIndex, helpIndex)
    if self.categoryIndex ~= categoryIndex then
        self.dirty = true
        self.showHelpIndex = helpIndex
    else
        self:SelectHelpEntry(helpIndex)
    end

    self.categoryIndex = categoryIndex
end

function HelpTutorialsEntriesGamepad:Push(categoryIndex, helpIndex)
    self:SelectOrQueueHelpEntry(categoryIndex, helpIndex)
    SCENE_MANAGER:Push("helpTutorialsEntriesGamepad")
end

function HelpTutorialsEntriesGamepad:Show(categoryIndex, helpIndex)
    self:SelectOrQueueHelpEntry(categoryIndex, helpIndex)
    SCENE_MANAGER:Show("helpTutorialsEntriesGamepad")
end

function HelpTutorialsEntriesGamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Link in Chat
        {
            name = GetString(SI_ITEM_ACTION_LINK_TO_CHAT),
            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                local targetData = self.itemList:GetTargetData()
                local link = ZO_LinkHandler_CreateChatLink(GetHelpLink, self.categoryIndex, targetData.helpIndex)
                ZO_LinkHandler_InsertLinkAndSubmit(link)
            end,

            visible = function()
                local targetData = self.itemList:GetTargetData()
                if targetData then
                    return IsChatSystemAvailableForCurrentPlatform()
                end

                return false
            end,
        },

        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, function() return self.itemList end )
end

function HelpTutorialsEntriesGamepad:AddHelpEntry(categoryIndex, helpIndex)
    local helpName, _, _, _, _, _, showOption = GetHelpInfo(categoryIndex, helpIndex)

    if IsGamepadHelpOption(showOption) then
        local entryData = ZO_GamepadEntryData:New(helpName)
        entryData.helpIndex = helpIndex
        self.itemList:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
    end
end

function HelpTutorialsEntriesGamepad:PerformUpdate()
    self.dirty = false

    -- Add the entries.
    self.itemList:Clear()

    if self.searchString and self.searchString ~= "" then
        for i = 1, #self.searchResults do
            local searchResult = self.searchResults[i]
            if searchResult and searchResult.helpCategoryIndex == self.categoryIndex then
                self:AddHelpEntry(self.categoryIndex, searchResult.helpIndex)
            end
        end
    else
        for helpIndex = 1, GetNumHelpEntriesWithinCategory(self.categoryIndex) do
            self:AddHelpEntry(self.categoryIndex, helpIndex)
        end
    end

    self.itemList:SetKeyForNextCommit(self.categoryIndex)
    self.itemList:Commit()

    -- Update the key bindings.
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    -- Update the header.
    local name, _, _, _, _, _, gamepadName = GetHelpCategoryInfo(self.categoryIndex)
    local categoryName = gamepadName ~= "" and gamepadName or name
    self.headerData.titleText = categoryName

    self:SetupSearchHeaderData(self.searchString, self.headerData)
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    if self.showHelpIndex then
        self:SelectHelpEntry(self.showHelpIndex)
        self.showHelpIndex = nil
    end
end

function HelpTutorialsEntriesGamepad:SelectHelpEntry(helpIndex)
    for i = 1, self.itemList:GetNumEntries() do
        local data = self.itemList:GetEntryData(i)
        if data.helpIndex == helpIndex then
            self.itemList:SetSelectedIndexWithoutAnimation(i)
            return
        end
    end
end

function HelpTutorialsEntriesGamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if not selectedData then
        return
    end

    HELP_TUTORIAL_DISPLAY_GAMEPAD:ShowHelp(self.categoryIndex, selectedData.helpIndex)
end

function HelpTutorialsEntriesGamepad:OnLinkClicked(link, button, text, color, linkType, ...)
    if linkType == HELP_LINK_TYPE and button == MOUSE_BUTTON_INDEX_LEFT then
        local helpCategoryIndex, helpIndex = GetHelpIndicesFromHelpLink(link)
        if helpCategoryIndex and helpIndex then
            self:Push(helpCategoryIndex, helpIndex)
        end
        return true
    end
end

function ZO_Gamepad_Tutorials_Entries_OnInitialize(control)
    HELP_TUTORIALS_ENTRIES_GAMEPAD = HelpTutorialsEntriesGamepad:New(control)
end
