local HelpTutorialsEntriesGamepad = ZO_HelpTutorialsGamepad:Subclass()

function HelpTutorialsEntriesGamepad:New(...)
    return ZO_HelpTutorialsGamepad.New(self, ...)
end

function HelpTutorialsEntriesGamepad:Initialize(control)
    ZO_HelpTutorialsGamepad.Initialize(self, control)

    local helpEntriesFragment = ZO_FadeSceneFragment:New(control)
    HELP_TUTORIALS_ENTRIES_GAMEPAD = ZO_Scene:New("helpTutorialsEntriesGamepad", SCENE_MANAGER)
    HELP_TUTORIALS_ENTRIES_GAMEPAD:AddFragment(helpEntriesFragment)

    local function OnStateChanged(...)
        self:OnStateChanged(...)
    end
    HELP_TUTORIALS_ENTRIES_GAMEPAD:RegisterCallback("StateChange", OnStateChanged)

    self.tutorialBox = control:GetNamedChild("TutorialText")
    self.scrollContainer = self.tutorialBox:GetNamedChild("HelpTextContainer")

    local messageContainer = self.tutorialBox:GetNamedChild("HelpMessageContainer")
    self.description1 = messageContainer:GetNamedChild("DetailsBody1")
    self.description2 = messageContainer:GetNamedChild("DetailsBody2")
    self.image = messageContainer:GetNamedChild("DetailsImage")
end

function HelpTutorialsEntriesGamepad:InitializeEvents()
    ZO_HelpTutorialsGamepad.InitializeEvents(self)

    local function OnShowSpecificPage(eventId, helpCategoryIndex, helpIndex)
        if IsInGamepadPreferredMode() then
            -- ideally we would do a push here, but that is currently not playing
            -- well with opening help from the Crown Store
            -- specifically: attempting to gift from the furniture browser with gifting locked
            self:Show(helpCategoryIndex, helpIndex)
        end
    end

    self.control:RegisterForEvent(EVENT_HELP_SHOW_SPECIFIC_PAGE, OnShowSpecificPage)
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
                ZO_LinkHandler_InsertLink(link)
                CHAT_SYSTEM:SubmitTextEntry()
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

    self.scrollContainer:ResetToTop()

    local _, keyboardDescription1, keyboardDescription2, image, gamepadDescription1, gamepadDescription2 = GetHelpInfo(self.categoryIndex, selectedData.helpIndex)
    local description1 = gamepadDescription1 ~= "" and gamepadDescription1 or keyboardDescription1
    local description2 = gamepadDescription2 ~= "" and gamepadDescription2 or keyboardDescription2

    self.description1:SetText(description1)

    if image then
        self.image:SetHidden(false)
        self.image:SetTexture(image)
    else
        self.image:SetHidden(true)
        self.image:SetHeight(0)
    end

    self.description2:SetText(description2)
end

function HelpTutorialsEntriesGamepad:OnHide()
    ZO_HelpTutorialsGamepad.OnHide(self)
end

local GAMEPAD_HELP_MAX_IMAGE_WIDTH = 767
function ZO_Gamepad_Tutorials_Entries_OnTextureLoaded(control)
    -- when hidden we directly manipulate the height, so don't apply constraints in those cases
    if not control:IsHidden() then
        ZO_ResizeTextureWidthAndMaintainAspectRatio(control, GAMEPAD_HELP_MAX_IMAGE_WIDTH)
    end
end

function ZO_Gamepad_Tutorials_Entries_OnInitialize(control)
    HELP_TUTORIALS_ENTRIES_GAMEPAD = HelpTutorialsEntriesGamepad:New(control)
end
