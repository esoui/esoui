--[[Basic screen]]--
ZO_HelpTutorialsGamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_HelpTutorialsGamepad:Initialize(control, activateOnShow)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, activateOnShow)
    self.itemList = ZO_Gamepad_ParametricList_Screen.GetMainList(self)

    self.headerData = 
    {
        titleText = GetString(SI_HELP_TUTORIALS),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    self:InitializeEvents()
end

function ZO_HelpTutorialsGamepad:InitializeEvents()
    local function UpdateHelp()
        self:Update()
    end

    self.control:RegisterForEvent(EVENT_HELP_INITIALIZED, UpdateHelp)
end

function ZO_HelpTutorialsGamepad:SetupSearchHeaderData(searchString, headerData)
    if searchString and searchString ~= "" then
        headerData.data1HeaderText = GetString(SI_GAMEPAD_HELP_SEARCH)
        headerData.data1Text = searchString
    else
        headerData.data1HeaderText = nil
        headerData.data1Text = nil
    end
end

function ZO_HelpTutorialsGamepad:SetupList(list)
    ZO_Gamepad_ParametricList_Screen.SetupList(self, list)

    local DEFAULT_EQUALITY_FUNCTION = nil
    list:AddDataTemplate("ZO_GamepadSubMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadSubMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, DEFAULT_EQUALITY_FUNCTION, "ZO_GamepadMenuEntryHeaderTemplate")
end

--[[Tutorial Info Display]]--

ZO_HelpTutorialsDisplay_Gamepad = ZO_InitializingObject:Subclass()

function ZO_HelpTutorialsDisplay_Gamepad:Initialize(control)
    self.control = control

    HELP_TUTORIAL_DISPLAY_FRAGMENT_GAMEPAD = ZO_FadeSceneFragment:New(control)

    self.scrollContainer = control:GetNamedChild("HelpTextContainer")

    local messageContainer = self.scrollContainer:GetNamedChild("ScrollChild"):GetNamedChild("HelpMessageContainer")
    self.description1Label = messageContainer:GetNamedChild("DetailsBody1")
    self.description2Label = messageContainer:GetNamedChild("DetailsBody2")
    self.imageTexture = messageContainer:GetNamedChild("DetailsImage")
end

function ZO_HelpTutorialsDisplay_Gamepad:ShowHelp(helpCategoryIndex, helpIndex)
    if helpCategoryIndex ~= self.helpCategoryIndex or helpIndex ~= self.helpIndex then
        self.helpCategoryIndex = helpCategoryIndex
        self.helpIndex = helpIndex

        local _, description1, description2, image, gamepadDescription1, gamepadDescription2 = GetHelpInfo(helpCategoryIndex, helpIndex)
        description1 = gamepadDescription1 == "" and description1 or gamepadDescription1
        description2 = gamepadDescription2 == "" and description2 or gamepadDescription2

        self.description1Label:SetText(description1)

        if image then
            self.imageTexture:SetHidden(false)
            self.imageTexture:SetTexture(image)
        else
            self.imageTexture:SetHidden(true)
            self.imageTexture:SetHeight(0)
        end

        self.description2Label:SetText(description2)
    end

    self.scrollContainer:ResetToTop()
    SCENE_MANAGER:AddFragment(HELP_TUTORIAL_DISPLAY_FRAGMENT_GAMEPAD)
end

function ZO_HelpTutorialsDisplay_Gamepad:Hide()
    SCENE_MANAGER:RemoveFragment(HELP_TUTORIAL_DISPLAY_FRAGMENT_GAMEPAD)
end

--[[Overlay Dialog View]]--
ESO_Dialogs["HELP_TUTORIALS_OVERLAY_DIALOG"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        allowRightStickPassThrough = true,
    },
    title =
    {
        text = SI_HELP_TUTORIALS,
    },
    parametricList = {}, -- Generated Dynamically
    setup = function(dialog)
        local parametricList = dialog.info.parametricList
        ZO_ClearNumericallyIndexedTable(parametricList)
        local systemFilters = HELP_MANAGER:GetShowingOverlaySceneSystemFilters()

        for helpCategoryIndex = 1, GetNumHelpCategories() do
            local categoryName = GetHelpCategoryInfo(helpCategoryIndex)
            for helpIndex = 1, GetNumHelpEntriesWithinCategory(helpCategoryIndex) do
                local helpName, _, _, _, _, _, showOption = GetHelpInfo(helpCategoryIndex, helpIndex)

                if IsGamepadHelpOption(showOption) then
                    local passesSystemFilter = true
                    if systemFilters and #systemFilters > 0 then
                        if not ZO_IsElementInNumericallyIndexedTable(systemFilters, GetUISystemAssociatedWithHelpEntry(helpCategoryIndex, helpIndex)) then
                            passesSystemFilter = false
                        end
                    end

                    if passesSystemFilter then
                        local entryData = ZO_GamepadEntryData:New(helpName)
                        entryData.setup = ZO_SharedGamepadEntry_OnSetup
                        entryData.helpCategoryIndex = helpCategoryIndex
                        entryData.helpIndex = helpIndex
                        entryData.narrationText = function(listEntryData, listEntryControl)
                            --TODO XAR: Do we want to somehow narrate the image as well?
                            local _, description1, description2, image, gamepadDescription1, gamepadDescription2 = GetHelpInfo(listEntryData.helpCategoryIndex, listEntryData.helpIndex)
                            description1 = gamepadDescription1 == "" and description1 or gamepadDescription1
                            description2 = gamepadDescription2 == "" and description2 or gamepadDescription2
                            return { SCREEN_NARRATION_MANAGER:CreateNarratableObject(listEntryData.text), SCREEN_NARRATION_MANAGER:CreateNarratableObject(description1), SCREEN_NARRATION_MANAGER:CreateNarratableObject(description2) }
                        end

                        local listItem =
                        {
                            template = "ZO_GamepadSubMenuEntryTemplate",
                            entryData = entryData,
                            header = categoryName,
                        }
                        -- Clear so only the first one gets the header
                        categoryName = nil

                        table.insert(parametricList, listItem)
                    end
                end
            end
        end

        local IS_VISIBLE = true
        HELP_MANAGER:GetOverlaySyncObject():Show()

        dialog:setupFunc()
    end,
    parametricListOnSelectionChangedCallback = function(dialog, list)
        local targetData = list:GetTargetData()
        if targetData then
            HELP_TUTORIAL_DISPLAY_GAMEPAD:ShowHelp(targetData.helpCategoryIndex, targetData.helpIndex)
        else
            HELP_TUTORIAL_DISPLAY_GAMEPAD:Hide()
        end
    end,
    onHidingCallback = function()
        HELP_TUTORIAL_DISPLAY_GAMEPAD:Hide()
    end,
    finishedCallback = function()
        local IS_NOT_VISIBLE = false
        HELP_MANAGER:GetOverlaySyncObject():Hide()
    end,
    buttons =
    {
        {
            keybind = "DIALOG_NEGATIVE",
            text = SI_GAMEPAD_BACK_OPTION,
            callback =  function(dialog)
                ZO_Dialogs_ReleaseDialogOnButtonPress("HELP_TUTORIALS_OVERLAY_DIALOG")
            end
        },
    },
}

--[[Global XML]]--

function ZO_HelpTutorialsDisplay_Gamepad_OnInitialized(control)
    HELP_TUTORIAL_DISPLAY_GAMEPAD = ZO_HelpTutorialsDisplay_Gamepad:New(control)
end

local GAMEPAD_HELP_MAX_IMAGE_WIDTH = 767
function ZO_Gamepad_Tutorials_Entries_OnTextureLoaded(control)
    -- when hidden we directly manipulate the height, so don't apply constraints in those cases
    if not control:IsHidden() then
        ZO_ResizeTextureWidthAndMaintainAspectRatio(control, GAMEPAD_HELP_MAX_IMAGE_WIDTH)
    end
end

