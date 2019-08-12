local HelpTutorialsCategoriesGamepad = ZO_HelpTutorialsGamepad:Subclass()

function HelpTutorialsCategoriesGamepad:New(...)
    return ZO_HelpTutorialsGamepad.New(self, ...)
end

function HelpTutorialsCategoriesGamepad:Initialize(control)
    ZO_HelpTutorialsGamepad.Initialize(self, control)

    local helpTutorialsFramgent = ZO_FadeSceneFragment:New(control)
    HELP_TUTORIAL_CATEGORIES_SCENE_GAMEPAD = ZO_Scene:New("helpTutorialsCategoriesGamepad", SCENE_MANAGER)
    HELP_TUTORIAL_CATEGORIES_SCENE_GAMEPAD:AddFragment(helpTutorialsFramgent)

    local function OnStateChanged(...)
        self:OnStateChanged(...)
    end
    HELP_TUTORIAL_CATEGORIES_SCENE_GAMEPAD:RegisterCallback("StateChange", OnStateChanged)
end

function HelpTutorialsCategoriesGamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
        -- Show Category or filter
        {
            name = function ()
                    return GetString(SI_GAMEPAD_HELP_DETAILS)
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                    local targetData = self.itemList:GetTargetData()
                    HELP_TUTORIALS_ENTRIES_GAMEPAD:Push(targetData.categoryIndex)
            end,
        },
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, function() return self.itemList end )
end

local function SortByCategory(result1, result2)
    return result1.helpCategoryIndex < result2.helpCategoryIndex
end

function HelpTutorialsCategoriesGamepad:AddListEntry(categoryIndex)
    local name, description, _, _, _, gamepadIcon, gamepadName = GetHelpCategoryInfo(categoryIndex)
    local categoryName = gamepadName ~= "" and gamepadName or name
    local entryData = ZO_GamepadEntryData:New(categoryName, gamepadIcon)
    entryData:SetIconTintOnSelection(true)
    entryData.categoryIndex = categoryIndex
    entryData.name = categoryName

    self.itemList:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
end

function HelpTutorialsCategoriesGamepad:IsCategoryEmpty(categoryIndex)
    local numEntries = GetNumHelpEntriesWithinCategory(categoryIndex)
    for helpIndex = 1, numEntries do
        local showOption = select(7, GetHelpInfo(categoryIndex, helpIndex))
        if IsGamepadHelpOption(showOption) then
            return false
        end
    end
    return true
end

function HelpTutorialsCategoriesGamepad:PerformUpdate()
    self.dirty = false

    self.itemList:Clear()

    -- Get the list of categoires we need to show.
    for categoryIndex = 1, GetNumHelpCategories() do
        if not self:IsCategoryEmpty(categoryIndex) then
            self:AddListEntry(categoryIndex)
        end
    end

    self.itemList:Commit()

    -- Update the key bindings.
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    -- Update the header.
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_Gamepad_Tutorials_Categories_OnInitialize(control)
    HELP_TUTORIALS_CATEGORIES = HelpTutorialsCategoriesGamepad:New(control)
end
