local g_lastSelectedEntryData
local g_canPlayCharacter = true

ZO_CHARACTER_SELECT_DETAILS_VALUE_OFFSET_Y = -14
ZO_GAMEPAD_CHARACTER_SELECT_LIST_ENTRY_CHAMPION_ICON_X_OFFSET = -20

local ACTIVATE_VIEWPORT = true

local ENTRY_TYPE_EXTRA_INFO = 1
local ENTRY_TYPE_CHARACTER = 2
local ENTRY_TYPE_CREATE_NEW = 3
local ENTRY_TYPE_CHAPTER = 4
local ENTRY_TYPE_EVENT = 5
local ENTRY_TYPE_ESO_PLUS = 6

local CREATE_NEW_ICON = "EsoUI/Art/Buttons/Gamepad/gp_plus_large.dds"

--[[ Character Select Delete Screen ]]--


function ZO_CharacterSelect_Gamepad_ReturnToCharacterList(activateViewPort)
    local self = ZO_CharacterSelect_Gamepad

    SCENE_MANAGER:AddFragment(CHARACTER_SELECT_CHARACTERS_GAMEPAD_FRAGMENT)

    if activateViewPort then
        ZO_CharacterSelect_GamepadCharacterViewport.Activate()
    end

    self.characterList:Activate()
    ZO_CharacterSelect_Gamepad_RefreshTooltip()
end

function ZO_CharacterSelect_Gamepad_InitConfirmDeleteCustomDialog()
    local confirmationString = GetString(SI_DELETE_CHARACTER_CONFIRMATION_TEXT)
    local deleteCharacterText = ""

    local lowercaseConfirmationString = string.lower(confirmationString)
    local function DoesDeleteEntryTextMatchConfirmationString()
        return string.lower(deleteCharacterText) == lowercaseConfirmationString
    end

    -- Delete entry
    local deleteEntryData = ZO_GamepadEntryData:New()
    deleteEntryData.isEditControl = true

    deleteEntryData.textChangedCallback = function(control)
        deleteCharacterText = control:GetText()
    end

    deleteEntryData.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
        control.highlight:SetHidden(not selected)

        control.editBoxControl.textChangedCallback = data.textChangedCallback
        control.editBoxControl:SetMaxInputChars(32) -- 32 is oversized, but gives wiggle-room
        control.editBoxControl:SetText(deleteCharacterText)
    end

    deleteEntryData.narrationText = ZO_GetDefaultParametricListEditBoxNarrationText

    -- Submit entry
    local submitEntryData = ZO_GamepadEntryData:New(GetString(SI_OTP_DIALOG_SUBMIT))
    submitEntryData.isSubmit = true

    submitEntryData.setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
        local isValid = DoesDeleteEntryTextMatchConfirmationString()
        data.disabled = not isValid
        data:SetEnabled(isValid)

        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, isValid, active)
    end

    ZO_Dialogs_RegisterCustomDialog("CONFIRM_DELETE_SELECTED_CHARACTER_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        canQueue = true,
        mustChoose = true,
        setup = function(dialog)
            deleteCharacterText = ""
            dialog:setupFunc()
        end,
        title =
        {
            text = SI_CONFIRM_DELETE_CHARACTER_DIALOG_GAMEPAD_TITLE,
        },
        mainText =
        {
            text = zo_strformat(SI_CONFIRM_DELETE_CHARACTER_DIALOG_GAMEPAD_TEXT, confirmationString)
        },
        parametricList =
        {
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
                entryData = deleteEntryData,
            },
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                entryData = submitEntryData,
            },
        },

        blockDialogReleaseOnPress = true,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.isEditControl and targetControl then
                        targetControl.editBoxControl:TakeFocus()
                    elseif targetData.isSubmit then
                        if DoesDeleteEntryTextMatchConfirmationString() then
                            -- Delete character and exit dialog
                            ZO_CharacterSelect_Gamepad.deleting = true
                            ZO_Dialogs_ReleaseDialogOnButtonPress("CONFIRM_DELETE_SELECTED_CHARACTER_GAMEPAD")
                            local characterData = CHARACTER_SELECT_MANAGER:GetSelectedCharacterData()
                            CHARACTER_SELECT_MANAGER:AttemptCharacterDelete(characterData.id)
                        end
                    end
                end,
                enabled = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()

                    if targetData.isEditControl then
                        return true
                    elseif targetData.isSubmit then
                        return DoesDeleteEntryTextMatchConfirmationString()
                    end

                    return false
                end,
            },

            {
                text = GetString(SI_CHARACTER_SELECT_GAMEPAD_DELETE_CANCEL),
                keybind = "DIALOG_NEGATIVE",

                callback = function()
                    local self = ZO_CharacterSelect_Gamepad
                    local selectedData = self.characterList:GetTargetData()
                    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                    ZO_CharacterSelect_Gamepad_ReturnToCharacterList(ACTIVATE_VIEWPORT)
                    if selectedData and selectedData.needsRename then
                        ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorRename)
                    else
                        ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorDefault)
                    end
                    ZO_Dialogs_ReleaseDialog("CONFIRM_DELETE_SELECTED_CHARACTER_GAMEPAD")
                end,
            },
        },
    })
end

function ZO_CharacterSelect_Gamepad_ShowDeleteScreen()
    ZO_CharacterSelect_GamepadCharacterViewport.Deactivate()
    ZO_Dialogs_ShowGamepadDialog("CONFIRM_DELETE_SELECTED_CHARACTER_GAMEPAD")
end

--[[ Character Select Screen ]]--

local function GetClassIconGamepad(classIdRequested)
    for i = 1, GetNumClasses() do
        local classId, _, _, _, _, _, _, _, _, gamepadPressedIcon = GetClassInfo(i)
        if classId == classIdRequested then
            return gamepadPressedIcon
        end
    end
    return nil
end

local function AddCharacterListEntry(template, entryData, list, prePadding, postPadding, preSelectedOffsetAdditionalPadding, postSelectedOffsetAdditionalPadding)
    entryData:SetFontScaleOnSelection(true)
    entryData:SetIconTintOnSelection(true)

    list:AddEntry(template, entryData, prePadding, postPadding, preSelectedOffsetAdditionalPadding, postSelectedOffsetAdditionalPadding)
end

local function CharacterListEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    data:ClearIcons()

    -- we can't set these up at list creation time as the character data isn't fully loaded yet (GetNumClasses() returns 0, which makes GetClassIconGamepad(...) results all nil)
    local icon = ((data.name ~= nil) and data.class) and GetClassIconGamepad(data.class) or data.icon

    data:AddIcon(icon)

    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
end

local function GamepadCharacterSelectMenuEntryHeader_Setup(headerControl, data, ...)
    ZO_ParametricScrollList_DefaultMenuEntryWithHeaderSetup(headerControl, data, ...)

    local subHeader = headerControl:GetNamedChild("SubHeader")

    if subHeader then
        subHeader:SetText(data.subHeader or "")
    end
end

-- Extra Info Functions

local function CreateExtraInfoEntry(self, data)
    local control, key = self.extraInfoControlPool:AcquireObject()
    control.key = key
    control.owner = self
    control.data = data
    control.icon = control:GetNamedChild("Icon")
    control.frame = control:GetNamedChild("Frame")
    control.tokenCount = control:GetNamedChild("TokenCount")

    if data.icon then
        control.icon:AddIcon(data.icon)
        control.icon:SetHidden(false)
    end

    local numTokens = GetNumServiceTokens(data.serviceMode)
    control.tokenCount:SetText(numTokens)
    control.icon:SetDesaturation(numTokens > 0 and 0 or 1)

    if numTokens > 0 and data.MeetsRequirementsFunction and data.MeetsRequirementsFunction() == false then
        control.icon:SetColor(ZO_ERROR_COLOR:UnpackRGB())
    else
        control.icon:SetColor(ZO_WHITE:UnpackRGB())
    end

    return control
end

local function ActivateFocusEntry(control)
    control.frame:SetEdgeColor(ZO_SELECTED_TEXT:UnpackRGB())

    if control.data.ShowTooltipFunction then
        control.data.ShowTooltipFunction()
    end
end

local function DeactivateFocusEntry(control)
    control.frame:SetEdgeColor(ZO_NORMAL_TEXT:UnpackRGB())

    if control.data.HideTooltipFunction then
        control.data.HideTooltipFunction()
    end
end

local function AddExtraInfoEntryToFocus(self, control)
    local focusEntry = {
        control = control,
        activate = ActivateFocusEntry,
        deactivate = DeactivateFocusEntry,
    }

    self.extraInfoFocus:AddEntry(focusEntry)
    table.insert(self.extraInfoControls, control)
end

local PADDING_X = 8
local PADDING_Y = 3
local function CenterExtraInfoControls(self)
    local numControls = #self.extraInfoControls

    if numControls > 0 then
        local controlWidth = self.extraInfoControls[1]:GetWidth()
        local stride = controlWidth + PADDING_X
        local currentOffsetX = (stride * (numControls - 1)) / -2

        for i = 1, numControls do
            self.extraInfoControls[i]:SetAnchor(CENTER, self.extraInfoCenterer, CENTER, currentOffsetX, PADDING_Y)
            currentOffsetX = currentOffsetX + stride
        end
    end
end

local function CreateExtraInfoControls(self)
    self.extraInfoFocus:RemoveAllEntries()

    if self.extraInfoControls then
        for i, control in ipairs(self.extraInfoControls) do
            self.extraInfoControlPool:ReleaseObject(control.key)
        end
    end
    self.extraInfoControls = {}

    if self.serviceMode == SERVICE_TOKEN_NONE then
        local function ServiceTokenTooltipFunction(tokenType)
            GAMEPAD_TOOLTIPS:LayoutServiceTokenTooltip(GAMEPAD_LEFT_TOOLTIP, tokenType)
        end

        local function ServiceTokenHideTooltipFunction()
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end

        local serviceTokenData =
        {
            {
                keybindStripDesc = self.charListKeybindStripDescriptorServices,
                icon = "EsoUI/Art/Icons/Token_NameChange.dds",
                serviceMode = SERVICE_TOKEN_NAME_CHANGE,
                ShowTooltipFunction = function()
                    ServiceTokenTooltipFunction(SERVICE_TOKEN_NAME_CHANGE)
                end,
                HideTooltipFunction = ServiceTokenHideTooltipFunction,
            },
            {
                keybindStripDesc = self.charListKeybindStripDescriptorServices,
                icon = "EsoUI/Art/Icons/Token_RaceChange.dds",
                serviceMode = SERVICE_TOKEN_RACE_CHANGE,
                ShowTooltipFunction = function()
                    ServiceTokenTooltipFunction(SERVICE_TOKEN_RACE_CHANGE)
                end,
                HideTooltipFunction = ServiceTokenHideTooltipFunction,
            },
            {
                keybindStripDesc = self.charListKeybindStripDescriptorServices,
                icon = "EsoUI/Art/Icons/Token_AppearanceChange.dds",
                serviceMode = SERVICE_TOKEN_APPEARANCE_CHANGE,
                ShowTooltipFunction = function()
                    ServiceTokenTooltipFunction(SERVICE_TOKEN_APPEARANCE_CHANGE)
                end,
                HideTooltipFunction = ServiceTokenHideTooltipFunction,
            },
            {
                keybindStripDesc = self.charListKeybindStripDescriptorServices,
                icon = "EsoUI/Art/Icons/Token_AllianceChange.dds",
                serviceMode = SERVICE_TOKEN_ALLIANCE_CHANGE,
                ShowTooltipFunction = function()
                    ServiceTokenTooltipFunction(SERVICE_TOKEN_ALLIANCE_CHANGE)
                end,
                HideTooltipFunction = ServiceTokenHideTooltipFunction,
                MeetsRequirementsFunction = function()
                    return CanPlayAnyRaceAsAnyAlliance()
                end
            },
        }

        -- Add more extra info controls above this line
        for i, tokenData in ipairs(serviceTokenData) do
            local control = CreateExtraInfoEntry(self, tokenData)
            AddExtraInfoEntryToFocus(self, control)
        end

        CenterExtraInfoControls(self)
    end
end

function ZO_CharacterSelect_Gamepad_UpdateExtraInfoKeybinds(control)
    if control and control.data then
        ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(control.data.keybindStripDesc)
    end
end

local function RefreshServiceHeaderVisibility(self)
    local headerVisible = self.serviceMode ~= SERVICE_TOKEN_NONE

    if headerVisible then
        local tokenCount = GetNumServiceTokens(self.serviceMode)

        local instructions = ""
        if self.serviceMode ~= SERVICE_TOKEN_NONE then
            instructions = zo_strformat(SI_SERVICE_TOKEN_INSTRUCTIONS, GetString("SI_SERVICETOKENTYPE", self.serviceMode))
        end

        self.headerData.data1HeaderText = GetString(SI_SERVICE_TOKEN_COUNT_TOKENS_HEADER)
        self.headerData.data1Text = tokenCount
        self.headerData.messageText = instructions
    else
        self.headerData.data1HeaderText = ""
        self.headerData.data1Text = ""
        self.headerData.messageText = ""
    end
end

-- End Extra Info functions

local g_hasNeedsRenameCharacter = false

local function CreateList(self, scrollToBest)
    self.characterList:Clear()

    CreateExtraInfoControls(self)

    local slot = 1

    if self.serviceMode == SERVICE_TOKEN_NONE then
        if not IsESOPlusSubscriber() then
            local data =
            {
                index = slot,
                type = ENTRY_TYPE_ESO_PLUS,
                header = GetString(SI_CHARACTER_SELECT_GAMEPAD_UPGRADES_HEADER),
                icon = "EsoUI/Art/CharacterSelect/gamepad/gp_characterSelect_ESOPlus.dds",
                text = GetString(SI_ESO_PLUS_JOIN_TEXT),
            }

            local newEntry = ZO_GamepadEntryData:New(data.text, data.icon)
            newEntry:SetDataSource(data)

            AddCharacterListEntry("ZO_GamepadMenuEntryTemplateWithHeader", newEntry, self.characterList)
            slot = slot + 1
        end

        
        if CHAPTER_UPGRADE_MANAGER:CanRegister() then
            local chapterUpgradeId = GetCurrentChapterUpgradeId()
            local chapterCollectibleId = GetChapterCollectibleId(chapterUpgradeId)
            local data =
            {
                index = slot,
                type = ENTRY_TYPE_CHAPTER,
                icon = GetCurrentChapterSmallLogoFileIndex(),
                text = zo_strformat(SI_CHARACTER_SELECT_CHAPTER_LOCKED_FORMAT, GetCollectibleName(chapterCollectibleId))
            }

            local newEntry = ZO_GamepadEntryData:New(data.text, data.icon)
            newEntry:SetDataSource(data)

            local entryTemplate = "ZO_GamepadMenuEntryTemplate"
            if slot == 1 then
                newEntry:SetHeader(GetString(SI_CHARACTER_SELECT_GAMEPAD_UPGRADES_HEADER))
                entryTemplate = "ZO_GamepadMenuEntryTemplateWithHeader"
            end

            AddCharacterListEntry(entryTemplate, newEntry, self.characterList)
            slot = slot + 1
        end

        -- Add entries for events into the parametric list
        local numEvents = CHARACTER_SELECT_MANAGER:GetNumEventAnnouncements()

        for i = 1, numEvents do
            local data = CHARACTER_SELECT_MANAGER:GetEventAnnouncementDataByIndex(i)
            local entryData =
            {
                index = data.index,
                name = data.name,
                description = data.description,
                image = data.image,
                startTime = data.startTime,
                remainingTime = data.remainingTime,
                type = ENTRY_TYPE_EVENT,
                text = data.name,
            }

            local newEntry = ZO_GamepadEntryData:New(entryData.text)
            newEntry:SetDataSource(entryData)

            local entryTemplate = "ZO_GamepadMenuEntryTemplate"
            if i == 1 then
                newEntry:SetHeader(GetString(SI_CHARACTER_SELECT_GAMEPAD_EVENTS_HEADER))
                entryTemplate = "ZO_GamepadMenuEntryTemplateWithHeader"
            end

            AddCharacterListEntry(entryTemplate, newEntry, self.characterList)
            slot = slot + 1
        end
    end

    local bestSelectionListIndex = nil
    local numCharacterSlotsAdded = 0
    local characterDataList = CHARACTER_SELECT_MANAGER:GetCharacterDataList()
    if #characterDataList > 0 then
        local bestSelectionData = CHARACTER_SELECT_MANAGER:GetBestSelectionData()

        local isFirstEntry = true

        -- Add Rename characters
        g_hasNeedsRenameCharacter = false
        if self.serviceMode ~= SERVICE_TOKEN_NAME_CHANGE then
            for i, characterData in ipairs(characterDataList) do
                if characterData.needsRename then
                    g_hasNeedsRenameCharacter = true

                    slot = slot + 1
                    numCharacterSlotsAdded = numCharacterSlotsAdded + 1

                    local template = "ZO_GamepadMenuEntryTemplateLowercase34"
                    local header = nil
                    if isFirstEntry then
                        header = GetString(SI_CHARACTER_SELECT_GAMEPAD_RENAME_HEADER)
                        template = "ZO_GamepadMenuEntryTemplateLowercase34WithHeader"
                        isFirstEntry = false
                    end

                    if characterData == bestSelectionData then
                        bestSelectionListIndex = slot
                    end

                    local text = ZO_CharacterSelect_Manager_GetFormattedCharacterName(characterData)
                    local renameCharacterEntry = ZO_GamepadEntryData:New(text, characterData.icon)
                    renameCharacterEntry.slot = slot
                    renameCharacterEntry.type = ENTRY_TYPE_CHARACTER
                    renameCharacterEntry:SetDataSource(characterData)
                    renameCharacterEntry:SetHeader(header)

                    AddCharacterListEntry(template, renameCharacterEntry, self.characterList)
                end
            end
        end

        isFirstEntry = true

        -- Add Selectable characters
        for i, characterData in ipairs(characterDataList) do
            if not characterData.needsRename then
                local template = "ZO_GamepadMenuEntryTemplateLowercase34"
                local header = nil
                local subHeader = nil
                local prePadding = nil
                local postPadding = nil
                local preSelectedOffsetAdditionalPadding = nil
                local postSelectedOffsetAdditionalPadding = nil
                if isFirstEntry then
                    header = zo_strformat(SI_CHARACTER_SELECT_GAMEPAD_CHARACTERS_HEADER, #characterDataList, CHARACTER_SELECT_MANAGER:GetMaxCharacters())
                    template = "ZO_GamepadMenuEntryTemplateLowercase34WithHeader"
                    isFirstEntry = false

                    if self.serviceMode == SERVICE_TOKEN_NONE and CHARACTER_SELECT_MANAGER:CanShowAdditionalSlotsInfo() then
                        prePadding = 80
                        postPadding = 0
                        preSelectedOffsetAdditionalPadding = 120
                        postSelectedOffsetAdditionalPadding = 0
                        subHeader = zo_strformat(SI_ADDITIONAL_CHARACTER_SLOTS_DESCRIPTION, CHARACTER_SELECT_MANAGER:GetAdditionalSlotsRemaining())
                    end
                end

                if characterData == bestSelectionData then
                    bestSelectionListIndex = slot
                end

                local text = ZO_CharacterSelect_Manager_GetFormattedCharacterName(characterData)
                local characterEntry = ZO_GamepadEntryData:New(text, characterData.icon)
                characterEntry:SetDataSource(characterData)
                characterEntry.slot = slot
                characterEntry.type = ENTRY_TYPE_CHARACTER
                characterEntry:SetHeader(header)
                characterEntry.subHeader = subHeader

                slot = slot + 1
                numCharacterSlotsAdded = numCharacterSlotsAdded + 1
                AddCharacterListEntry(template, characterEntry, self.characterList, prePadding, postPadding, preSelectedOffsetAdditionalPadding, postSelectedOffsetAdditionalPadding)
            end
        end
    end

    if self.serviceMode == SERVICE_TOKEN_NONE then
        -- Add Create New
        if CHARACTER_SELECT_MANAGER:CanCreateNewCharacters() then
            local newEntry = ZO_GamepadEntryData:New(GetString(SI_CHARACTER_SELECT_GAMEPAD_CREATE_NEW_ENTRY), CREATE_NEW_ICON)
            newEntry.index = slot
            newEntry.type = ENTRY_TYPE_CREATE_NEW
            newEntry:SetHeader(GetString(SI_CHARACTER_SELECT_GAMEPAD_CREATE_NEW_HEADER))

            AddCharacterListEntry("ZO_GamepadMenuEntryTemplateWithHeader", newEntry, self.characterList)
        end
    elseif numCharacterSlotsAdded == 0 then
        -- In a service mode, but no characters qualify for the service
        self.characterList:SetNoItemText(GetString(SI_SERVICE_NO_ELIGIBLE_CHARACTERS))
        ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorUseServiceToken)
    end

    if scrollToBest and bestSelectionListIndex and not CHARACTER_SELECT_MANAGER:GetEventAnnouncementAutoShowIndex() then
        local ALLOW_EVEN_IF_DISABLED = true
        local FORCE_ANIMATION = false
        self.characterList:SetSelectedIndex(bestSelectionListIndex, ALLOW_EVEN_IF_DISABLED, FORCE_ANIMATION)
    end

    self.characterList:Commit()
end

local function RecreateList(self)
    CreateList(self, true)
    RefreshServiceHeaderVisibility(self)
    ZO_CharacterSelect_Gamepad_RefreshHeader()
end

local function RefreshKeybindStripForCharacterList(self, selectedData)
    if self.characterList:IsActive() then
        if self.serviceMode ~= SERVICE_TOKEN_NONE then
            ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorUseServiceToken)
        elseif selectedData.needsRename then
            ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorRename)
        elseif selectedData.type == ENTRY_TYPE_CREATE_NEW then
            ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorCreateNew)
        elseif selectedData.type == ENTRY_TYPE_CHAPTER then
            ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorChapter)
        elseif selectedData.type == ENTRY_TYPE_EVENT then
            ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorEvent)
        elseif selectedData.type == ENTRY_TYPE_ESO_PLUS then
            ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorEsoPlus)
        else
            ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorDefault)
        end
    end
end

local function ZO_CharacterSelect_Gamepad_ShowEventAnnouncementsBanner(selectedIndex)
    local self = ZO_CharacterSelect_Gamepad

    if IsInGamepadPreferredMode() and selectedIndex then
        self.characterList:Deactivate()
        ZO_CharacterSelect_Gamepad_ClearKeybindStrip()
        CHARACTER_SELECT_EVENT_BANNER_GAMEPAD:SetOnCloseCallback(function()
            CHARACTER_SELECT_MANAGER:ClearEventAnnouncementAutoShowIndex()
            DIRECTIONAL_INPUT:Activate(self, self)
            self.characterList:Activate()
            local selectedData = self.characterList:GetTargetData()
            RefreshKeybindStripForCharacterList(self, selectedData)
            ZO_CharacterSelect_GamepadCharacterViewport.Activate()
            end)
        DIRECTIONAL_INPUT:Deactivate(self, self)
        ZO_CharacterSelect_GamepadCharacterViewport.Deactivate()
        CHARACTER_SELECT_EVENT_BANNER_GAMEPAD:SetSelectedIndex(selectedIndex)
        SCENE_MANAGER:AddFragment(CHARACTER_SELECT_EVENT_BANNER_GAMEPAD:GetFragment())
    end
end

local function InitKeybindingDescriptor(self)

    local deleteKeybind =
     {
        name = GetString(SI_CHARACTER_SELECT_GAMEPAD_DELETE),
        keybind = "UI_SHORTCUT_SECONDARY",
        disabledDuringSceneHiding = true,
        callback = function()
            self.characterList:Deactivate() -- So we can't select a different character
            PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
            local numCharacterDeletesRemaining = GetNumCharacterDeletesRemaining()
            local selectedData = self.characterList:GetTargetData()

            if numCharacterDeletesRemaining == 0 then
                ZO_Dialogs_ShowGamepadDialog("DELETE_SELECTED_CHARACTER_NO_DELETES_LEFT_GAMEPAD", {keybindDescriptor = self.charListKeybindStripDescriptorDefault})
            elseif selectedData and selectedData.needsRename then
                ZO_Dialogs_ShowGamepadDialog("DELETE_SELECTED_CHARACTER_GAMEPAD", {keybindDescriptor = self.charListKeybindStripDescriptorRename}, {mainTextParams = {numCharacterDeletesRemaining}})
            else
                ZO_Dialogs_ShowGamepadDialog("DELETE_SELECTED_CHARACTER_GAMEPAD", {keybindDescriptor = self.charListKeybindStripDescriptorDefault}, {mainTextParams = {numCharacterDeletesRemaining}})
            end
        end,
    }

    local optionsKeybind =
    {
        name = GetString(SI_CHARACTER_SELECT_GAMEPAD_OPTIONS),
        keybind = "UI_SHORTCUT_TERTIARY",

        callback = function()
            -- fix to keep both buttons from being pushable in the time it takes for the state to change
            local state = PregameStateManager_GetCurrentState()
            if state == "CharacterSelect" then
                SCENE_MANAGER:Push("gamepad_options_root")
            end
        end,
    }

    self.charListKeybindStripDescriptorDefault =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Play
        {
            name = GetString(SI_CHARACTER_SELECT_GAMEPAD_PLAY),
            keybind = "UI_SHORTCUT_PRIMARY",
            disabledDuringSceneHiding = true,
            callback = function()
                if ZO_CharacterSelect_Gamepad_Login(CHARACTER_OPTION_EXISTING_AREA) then
                    self.characterList:Deactivate() -- So we can't select a different character
                    PlaySound(SOUNDS.DIALOG_ACCEPT)
                    ZO_CharacterSelect_Gamepad_ClearKeybindStrip()
                end
            end,
        },
        -- Order Character Up
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = GetString(SI_CHARACTER_SELECT_ORDER_CHARACTER_UP),
            keybind = "UI_SHORTCUT_LEFT_SHOULDER",
            order = 101,
            callback = function()
                if not g_hasNeedsRenameCharacter then
                    local selectedData = self.characterList:GetTargetData()
                    if selectedData and selectedData.type == ENTRY_TYPE_CHARACTER and selectedData.order > 1 then
                        CHARACTER_SELECT_MANAGER:SwapCharacterOrderUp(selectedData.order)
                    end
                end
            end
        },
        -- Order Character Down
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = GetString(SI_CHARACTER_SELECT_ORDER_CHARACTER_DOWN),
            keybind = "UI_SHORTCUT_RIGHT_SHOULDER",
            order = 102,
            callback = function()
                if not g_hasNeedsRenameCharacter then
                    local selectedData = self.characterList:GetTargetData()
                    if selectedData and selectedData.order < CHARACTER_SELECT_MANAGER:GetNumCharacters() then
                        CHARACTER_SELECT_MANAGER:SwapCharacterOrderDown(selectedData.order)
                    end
                end
            end
        },
        deleteKeybind,
        optionsKeybind,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(ZO_Disconnect),
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.charListKeybindStripDescriptorDefault, self.characterList)

    self.charListKeybindStripDescriptorRename =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_CHARACTER_SELECT_GAMEPAD_RENAME),
            keybind = "UI_SHORTCUT_PRIMARY",
            disabledDuringSceneHiding = true,
            callback = function()
                self.characterList:Deactivate() -- So we can't select a different character

                PlaySound(SOUNDS.DIALOG_ACCEPT)
                SCENE_MANAGER:RemoveFragment(CHARACTER_SELECT_CHARACTERS_GAMEPAD_FRAGMENT)
                ZO_CharacterSelect_Gamepad_BeginRename()
            end,
        },
        deleteKeybind,
        optionsKeybind,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(ZO_Disconnect),
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.charListKeybindStripDescriptorRename, self.characterList)

    -- Different keybinding for Create New option
    self.charListKeybindStripDescriptorCreateNew =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_CHARACTER_SELECT_GAMEPAD_CREATE_NEW),
            keybind = "UI_SHORTCUT_PRIMARY",
            disabledDuringSceneHiding = true,

            callback = function()
                self.characterList:Deactivate() -- So we can't select a different character
                PlaySound(SOUNDS.DIALOG_ACCEPT)
                PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                PregameStateManager_SetState("CharacterCreate")
            end,
        },
        optionsKeybind,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(ZO_Disconnect),
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.charListKeybindStripDescriptorCreateNew, self.characterList)

    self.charListKeybindStripDescriptorChapter =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_CHARACTER_SELECT_CHAPTER_UPGRADE_REGISTER),
            keybind = "UI_SHORTCUT_PRIMARY",
            disabledDuringSceneHiding = true,

            callback = function()
                self.characterList:Deactivate() -- So we can't select a different character
                PlaySound(SOUNDS.DIALOG_ACCEPT)
                PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                PregameStateManager_SetState("ChapterUpgrade")
            end,
        },
        optionsKeybind,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(ZO_Disconnect),
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.charListKeybindStripDescriptorChapter, self.characterList)

    self.charListKeybindStripDescriptorEvent =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_CHARACTER_SELECT_GAMEPAD_EVENTS_VIEW_KEYBIND),
            keybind = "UI_SHORTCUT_PRIMARY",
            disabledDuringSceneHiding = true,

            callback = function()
                PlaySound(SOUNDS.DIALOG_ACCEPT)
                local selectedData = self.characterList:GetTargetData()
                ZO_CharacterSelect_Gamepad_ShowEventAnnouncementsBanner(selectedData.index)
            end,
        },
        optionsKeybind,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(ZO_Disconnect),
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.charListKeybindStripDescriptorEvent, self.characterList)

    self.charListKeybindStripDescriptorEsoPlus =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_CHARACTER_SELECT_ESO_PLUS_JOIN),
            keybind = "UI_SHORTCUT_PRIMARY",
            disabledDuringSceneHiding = true,

            callback = function()
                ZO_ShowBuySubscriptionPlatformDialog()
            end,
        },
        {
            name = GetString(SI_CHARACTER_SELECT_ESO_PLUS_READ_MORE),
            keybind = "UI_SHORTCUT_SECONDARY",
            disabledDuringSceneHiding = true,

            callback = function()
                ZO_ESO_PLUS_MEMBERSHIP_DIALOG:Show()
            end,
        },
        optionsKeybind,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(ZO_Disconnect),
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.charListKeybindStripDescriptorEsoPlus, self.characterList)


    -- Keybinds for the additional character slot control
    self.charListKeybindStripDescriptorAdditionalSlots =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        optionsKeybind,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(ZO_Disconnect),
    }

    -- Keybinds for service token controls
    self.charListKeybindStripDescriptorServices =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select service
        {
            name = GetString(SI_SERVICE_USE_SERVICE_KEYBIND),
            keybind = "UI_SHORTCUT_PRIMARY",
            disabledDuringSceneHiding = true,
            enabled = function()
                local selectedEntryData = ZO_CharacterSelect_Gamepad_GetSelectedExtraInfoEntryData()
                if selectedEntryData == nil then
                    return false
                end

                if selectedEntryData.MeetsRequirementsFunction and selectedEntryData.MeetsRequirementsFunction() == false then
                    return false
                end

                if GetNumServiceTokens(selectedEntryData.serviceMode) == 0 then
                    return false
                end

                return true
            end,
            callback = function()
                local newServiceMode = ZO_CharacterSelect_Gamepad_GetSelectedServiceMode()
                local RESET_LIST_TO_DEFAULT = true
                ZO_CharacterSelect_Gamepad_ChangeServiceMode(newServiceMode, RESET_LIST_TO_DEFAULT)
            end,
        },
        optionsKeybind,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(ZO_Disconnect),
    }

    -- Keybinds for using service tokens on the character list
    self.charListKeybindStripDescriptorUseServiceToken =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Use service token
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            disabledDuringSceneHiding = true,
            visible = function()
                return self.characterList:GetNumEntries() > 0
            end,
            callback = function()
                -- Perform a different function based on the currently selected service mode
                if self.serviceMode == SERVICE_TOKEN_NAME_CHANGE then
                    ZO_CharacterSelect_Gamepad_BeginRename()
                elseif self.serviceMode == SERVICE_TOKEN_RACE_CHANGE then
                    ZO_CHARACTERCREATE_MANAGER:InitializeForRaceChange(CHARACTER_SELECT_MANAGER:GetSelectedCharacterData())
                    PregameStateManager_SetState("CharacterCreate_Barbershop")
                elseif self.serviceMode == SERVICE_TOKEN_APPEARANCE_CHANGE then
                    ZO_CHARACTERCREATE_MANAGER:InitializeForAppearanceChange(CHARACTER_SELECT_MANAGER:GetSelectedCharacterData())
                    PregameStateManager_SetState("CharacterCreate_Barbershop")
                elseif self.serviceMode == SERVICE_TOKEN_ALLIANCE_CHANGE then
                    ZO_CHARACTERCREATE_MANAGER:InitializeForAllianceChange(CHARACTER_SELECT_MANAGER:GetSelectedCharacterData())
                    PregameStateManager_SetState("CharacterCreate_Barbershop")
                end
            end,
        },
        -- Custom back button behavior
        {
            name = GetString(SI_SERVICE_BACK_KEYBIND),
            keybind = "UI_SHORTCUT_NEGATIVE",
            disabledDuringSceneHiding = true,
            callback = function()
                -- If the back button is pressed before a service token is consumed, return the player back up to the extra info menu
                local RESET_LIST_TO_DEFAULT = true
                ZO_CharacterSelect_Gamepad_ChangeServiceMode(SERVICE_TOKEN_NONE, RESET_LIST_TO_DEFAULT)
            end,
        },
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.charListKeybindStripDescriptorUseServiceToken, self.characterList)

    self.charListKeybindStripDescriptorLogin =
    {
    }

    self.charListKeybindStripDescriptor = self.charListKeybindStripDescriptorDefault
end

local function SelectedListDataChanged(self, list, selectedData, oldSelectedData)
    if selectedData and selectedData.type == ENTRY_TYPE_EXTRA_INFO then
        g_canPlayCharacter = false
        return
    end

    if selectedData then
        g_canPlayCharacter = false
        if selectedData.type == ENTRY_TYPE_CHARACTER then
            g_canPlayCharacter = true
        end

        RefreshKeybindStripForCharacterList(self, selectedData)
    else
        CHARACTER_SELECT_MANAGER:SetPlayerSelectedCharacterId(nil)
    end

    g_lastSelectedEntryData = selectedData

    ZO_CharacterSelect_Gamepad_RefreshTooltip()
end

function ZO_CharacterSelect_Gamepad_RefreshTooltip()
    local self = ZO_CharacterSelect_Gamepad
    if g_lastSelectedEntryData and g_lastSelectedEntryData.type == ENTRY_TYPE_EXTRA_INFO then
        return
    end

    --Make sure the screen is actually showing before trying to do anything with the tooltips
    if self.active then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        local shouldShowCharacterDetails = false
        if g_lastSelectedEntryData and g_lastSelectedEntryData.type == ENTRY_TYPE_CHARACTER then
            -- Only show character details if the character is in a valid location
            shouldShowCharacterDetails = g_lastSelectedEntryData.location and g_lastSelectedEntryData.location ~= 0 and not g_lastSelectedEntryData.needsRename
        end

        --Handle tooltips
        local needsRename = g_lastSelectedEntryData and g_lastSelectedEntryData.needsRename
        if needsRename then
            GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_TOOLTIP, GetString(SI_CHARACTER_SELECT_GAMEPAD_RENAME_TEXT))
        elseif shouldShowCharacterDetails then
            GAMEPAD_TOOLTIPS:LayoutCharacterDetailsTooltip(GAMEPAD_LEFT_TOOLTIP, g_lastSelectedEntryData)
        end
    end
end

function ZO_CharacterSelect_Gamepad_RefreshCharacter()
    local self = ZO_CharacterSelect_Gamepad

    SelectedListDataChanged(self, nil, g_lastSelectedEntryData, nil)
end

function ZO_CharacterSelect_Gamepad_RefreshHeader()
    local self = ZO_CharacterSelect_Gamepad

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    local profileNameString = nil
    local profileLabelString = nil
    if IsConsoleUI() then
        -- Use the console's active profile name
        profileNameString = GetOnlineIdForActiveProfile()
        profileLabelString = GetString(SI_CHARACTER_SELECT_PROFILE_LABEL)
    end

    local profileName = ZO_CharacterSelectProfile_Gamepad:GetNamedChild("ProfileName")
    local profileLabel = ZO_CharacterSelectProfile_Gamepad:GetNamedChild("ProfileLabel")
    if profileNameString and profileNameString ~= "" then
        profileName:SetHidden(false)
        profileLabel:SetHidden(false)
        profileName:SetText(profileNameString)
        profileLabel:SetText(profileLabelString)
    else
        profileName:SetHidden(true)
        profileLabel:SetHidden(true)
    end
end

local function OnCharacterConstructionReady()
    local self = ZO_CharacterSelect_Gamepad

    local selectedCharacterData = CHARACTER_SELECT_MANAGER:GetSelectedCharacterData()
    if GAMEPAD_CHARACTER_SELECT_SCENE:IsShowing() and not self.characterConstructed and selectedCharacterData then
        local ALLOW_EVEN_IF_DISABLED = true
        local FORCE_ANIMATION = false

        local listIndex = self.characterList:FindFirstIndexByEval(function(entry) return AreId64sEqual(selectedCharacterData.id, entry.id) end)
        self.characterList:SetSelectedIndexWithoutAnimation(listIndex, ALLOW_EVEN_IF_DISABLED, FORCE_ANIMATION)

        --if we're quick launching, then just select the first character we can.
        if GetCVar("QuickLaunch") == "1" then
            ZO_CharacterSelect_Gamepad_Login(CHARACTER_OPTION_EXISTING_AREA)
        end
        ZO_CharacterSelect_Gamepad_RefreshCharacter()
        CHARACTER_SELECT_MANAGER:RefreshConstructedCharacter()

        self.characterConstructed = true
    end
end

local function OnPregameFullyLoaded()
    local self = ZO_CharacterSelect_Gamepad

    RecreateList(self)

    if self.active then
        if not CHARACTER_SELECT_MANAGER:GetEventAnnouncementAutoShowIndex() then
            self.characterList:Activate()
        end

        self.characterList:RefreshVisible()
        if IsPregameCharacterConstructionReady() then
            OnCharacterConstructionReady()
        end
    end
end

function ZO_CharacterSelect_Gamepad_ClearKeybindStrip()
    local self = ZO_CharacterSelect_Gamepad

    if self.currentKeystrip then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeystrip)
        self.currentKeystrip = nil
    end
end

function ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(keybindStrip)
    local self = ZO_CharacterSelect_Gamepad

    if keybindStrip then
        self.charListKeybindStripDescriptor = keybindStrip
    end

    if self.active then
        if self.currentKeystrip ~= self.charListKeybindStripDescriptor then
            ZO_CharacterSelect_Gamepad_ClearKeybindStrip()

            self.currentKeystrip = self.charListKeybindStripDescriptor
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.charListKeybindStripDescriptor)
        else
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeystrip)
        end
    end
end

local function ZO_CharacterSelect_Gamepad_StateChanged(oldState, newState)
    local self = ZO_CharacterSelect_Gamepad

    if newState == SCENE_SHOWING then
        self.active = true
        self.deleting = false
        local RESET_TO_DEFAULT = true
        ZO_CharacterSelect_Gamepad_ChangeServiceMode(SERVICE_TOKEN_NONE, RESET_TO_DEFAULT)

        ZO_CharacterSelect_GamepadCharacterViewport.Activate()
        SCENE_MANAGER:AddFragment(CHARACTER_SELECT_CHARACTERS_GAMEPAD_FRAGMENT)

        local characterDataReady = IsPregameCharacterConstructionReady()
        if characterDataReady and not CHARACTER_SELECT_MANAGER:GetEventAnnouncementAutoShowIndex() then
            self.characterList:RefreshVisible()
            self.characterList:Activate()
            self.extraInfoFocus:Deactivate()
        end

        ZO_CharacterSelect_Gamepad_RefreshKeybindStrip()
        if characterDataReady then
            OnCharacterConstructionReady()  -- So that if we come to this screen from Character Create, it will load a different scene.
        end

        DIRECTIONAL_INPUT:Activate(self, self)

        if CHARACTER_SELECT_MANAGER:IsSavedDataReady() then
            ZO_CharacterSelect_Gamepad_ShowEventAnnouncementsBanner(CHARACTER_SELECT_MANAGER:GetEventAnnouncementAutoShowIndex())
        else
            CHARACTER_SELECT_MANAGER:RegisterCallback("OnSavedDataReady", function() ZO_CharacterSelect_Gamepad_ShowEventAnnouncementsBanner(CHARACTER_SELECT_MANAGER:GetEventAnnouncementAutoShowIndex()) end)
        end
    elseif newState == SCENE_HIDDEN then
        self.characterConstructed = false

        DIRECTIONAL_INPUT:Deactivate(self, self)

        self.active = false
        ZO_CharacterSelect_GamepadCharacterViewport.StopAllInput()
        ZO_CharacterSelect_GamepadCharacterViewport.Deactivate()
        self.characterList:Deactivate()
        self.extraInfoFocus:Deactivate()

        ZO_CharacterSelect_Gamepad_ClearKeybindStrip()
    end
end

local function CharacterDeleted(eventCode, charId)
    if ZO_CharacterSelect_Gamepad.deleting then
        -- We need to release the dialog to make sure the keybinds are cleared.
        -- Releasing this dialog will request the character list
        ZO_CharacterSelect_Gamepad.deleting = false
        ZO_CharacterSelect_Gamepad.refreshAfterCharacterDeleted = true
        ZO_Dialogs_ReleaseDialog("CHARACTER_SELECT_DELETING")
    end
end

local g_requestedRename = ""

local function ContextFilter(callback)
    -- This will wrap the callback so that it gets called in the appropriate context
    return function(...)
        if IsGamepadUISupported() then
            callback(...)
        end
    end
end

function ZO_CharacterSelect_Gamepad_UpdateDirectionalInput()
    local self = ZO_CharacterSelect_Gamepad
    local result = self.movementController:CheckMovement()

    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        if self.extraInfoFocus.active then
            self.extraInfoFocus:Deactivate()
            self.characterList:Activate()
            SelectedListDataChanged(self, self.characterList, g_lastSelectedEntryData)
            PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
        elseif self.characterList:IsActive() then
            self.characterList:MoveNext()
        end
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        if self.characterList:IsActive() then
            if self.characterList:GetSelectedIndex() ~= 1 then
                self.characterList:MovePrevious()
            elseif not self.extraInfoContainer:IsHidden() then
                self.extraInfoFocus:Activate()
                self.characterList:Deactivate()
                SelectedListDataChanged(self, self.characterList, { type = ENTRY_TYPE_EXTRA_INFO })
                PlaySound(SOUNDS.GAMEPAD_MENU_UP)
            end
        end
    end
end

function ZO_CharacterSelect_Gamepad_Initialize(self)
    self.deleteKeys = {false, false, false, false}

    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)

    self.characterList = ZO_GamepadVerticalParametricScrollList:New(self:GetNamedChild("Mask"):GetNamedChild("Characters"):GetNamedChild("List"))
    self.characterList:AddDataTemplate("ZO_GamepadMenuEntryTemplate", CharacterListEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.characterList:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplate", CharacterListEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    self.characterList:AddDataTemplate("ZO_GamepadMenuEntryTemplateLowercase34", CharacterListEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.characterList:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplateLowercase34", CharacterListEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadCharacterSelectMenuEntryHeaderTemplate", GamepadCharacterSelectMenuEntryHeader_Setup)
    self.characterList:SetAlignToScreenCenter(true)
    self.characterList:SetHandleDynamicViewProperties(true)

    self.UpdateDirectionalInput = ZO_CharacterSelect_Gamepad_UpdateDirectionalInput
    self.characterList:SetDirectionalInputEnabled(false)
    self.header = self:GetNamedChild("Mask"):GetNamedChild("Characters"):GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)
    self.headerData =
    {
        titleText = GetString(SI_CHARACTER_SELECT_GAMEPAD_SELECT_CHARACTER),
    }

    local narrationInfo = 
    {
        canNarrate = function()
            return CHARACTER_SELECT_CHARACTERS_GAMEPAD_FRAGMENT:IsShowing()
        end,
        headerNarrationFunction = function()
            return ZO_GamepadGenericHeader_GetNarrationText(self.header, self.headerData)
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterParametricList(self.characterList, narrationInfo)

    -- Extra Info controls
    self.extraInfoContainer = self:GetNamedChild("Mask"):GetNamedChild("Characters"):GetNamedChild("HeaderContainer"):GetNamedChild("ExtraInfo")
    self.extraInfoCenterer = self.extraInfoContainer:GetNamedChild("Centerer")
    self.extraInfoFocus = ZO_GamepadFocus:New(self.extraInfoCenterer, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.extraInfoFocus.onPlaySoundFunction = function() PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED) end

    self.extraInfoFocus:SetFocusChangedCallback(function(focusItem)
        if focusItem then
            ZO_CharacterSelect_Gamepad_UpdateExtraInfoKeybinds(focusItem.control)
            SCREEN_NARRATION_MANAGER:QueueFocus(self.extraInfoFocus)
        end
    end)

    self.extraInfoControlPool = ZO_ControlPool:New("ZO_CharacterSelect_ExtraInfo_Entry", self.extraInfoCenterer)

    -- Service header controls
    self.serviceMode = SERVICE_TOKEN_NONE

    InitKeybindingDescriptor(self) -- Depends on self.characterList since we bind to it.

    local function OnCharacterSelectionChanged(list, selectedData, oldSelectedData)
        if selectedData.type == ENTRY_TYPE_CHARACTER then
            CHARACTER_SELECT_MANAGER:SetSelectedCharacter(selectedData:GetDataSource())
        end
        SelectedListDataChanged(self, list, selectedData, oldSelectedData)
    end

    self.characterList:SetOnTargetDataChangedCallback(OnCharacterSelectionChanged)

    local ALWAYS_ANIMATE = true
    CHARACTER_SELECT_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(self, ALWAYS_ANIMATE)
    CHARACTER_SELECT_PROFILE_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CharacterSelectProfile_Gamepad, ALWAYS_ANIMATE)
    CHARACTER_SELECT_RENAME_ERROR_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CharacterSelect_GamepadRenameError, ALWAYS_ANIMATE)
    GAMEPAD_CHARACTER_SELECT_SCENE = ZO_Scene:New("gamepadCharacterSelect", SCENE_MANAGER)
    GAMEPAD_CHARACTER_SELECT_SCENE:AddFragment(CHARACTER_SELECT_GAMEPAD_FRAGMENT)
    GAMEPAD_CHARACTER_SELECT_SCENE:AddFragment(CHARACTER_SELECT_PROFILE_GAMEPAD_FRAGMENT)

    CHARACTER_SELECT_CHARACTERS_GAMEPAD_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_CharacterSelect_GamepadMaskCharacters)

    GAMEPAD_CHARACTER_SELECT_SCENE:RegisterCallback("StateChange", ZO_CharacterSelect_Gamepad_StateChanged)

    CALLBACK_MANAGER:RegisterCallback("OnCharacterConstructionReady", ContextFilter(OnCharacterConstructionReady))
    CALLBACK_MANAGER:RegisterCallback("PregameFullyLoaded", ContextFilter(OnPregameFullyLoaded))

    self:RegisterForEvent(EVENT_CHARACTER_DELETED, ContextFilter(CharacterDeleted))
    self:RegisterForEvent(EVENT_ENTITLEMENT_STATE_CHANGED, function()
        -- Need the game data to be loaded before we can recreate the list, which is handled by OnPregameFullyLoaded()
        if PregameIsFullyLoaded() then
            RecreateList(self)
        end
    end)

    CHARACTER_SELECT_MANAGER:RegisterCallback("EventAnnouncementsReceived", function()
        if PregameIsFullyLoaded() then
            ZO_CharacterSelect_Gamepad_ShowEventAnnouncementsBanner(CHARACTER_SELECT_MANAGER:GetEventAnnouncementAutoShowIndex())
        end
    end)

    CHARACTER_SELECT_MANAGER:RegisterCallback("CharacterListUpdated", function()
        if self.refreshAfterCharacterDeleted then
            if CHARACTER_SELECT_MANAGER:GetNumCharacters() == 0 then
                return -- We are going to the character create screen
            end
            PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
            ZO_CharacterSelect_Gamepad_ReturnToCharacterList(ACTIVATE_VIEWPORT)
            self.characterList:Clear()
            self.refreshAfterCharacterDeleted = false
        end

        RecreateList(self)
    end)

    CHARACTER_SELECT_MANAGER:RegisterCallback("CharacterOrderChanged", function(targetCharacterData)
        CreateList(self)
        local listIndex = self.characterList:FindFirstIndexByEval(function(entry) return AreId64sEqual(targetCharacterData.id, entry.id) end)
        local ALLOW_EVEN_IF_DISABLED = true
        local FORCE_ANIMATION = false
        self.characterList:SetSelectedIndexWithoutAnimation(listIndex, ALLOW_EVEN_IF_DISABLED, FORCE_ANIMATION)
    end)

    local function OnRenameResult(success)
        if success then
            -- there are multiple ways to rename a character, some of which do not change the servicemode, so we will
            -- check if this is from a service use or not, and update the appropriate items
            if self.serviceMode == SERVICE_TOKEN_NONE then
                ZO_CharacterSelect_Gamepad_ReturnToCharacterList(ACTIVATE_VIEWPORT)
            else
                local DONT_RESET_TO_DEFAULT = false
                ZO_CharacterSelect_Gamepad_ChangeServiceMode(SERVICE_TOKEN_NONE, DONT_RESET_TO_DEFAULT)
            end
        else
            -- restart flow
            ZO_CharacterSelect_Gamepad_BeginRename()
        end
    end

    ZO_CharacterNaming_Gamepad_CreateDialog(ZO_CharacterSelect_Gamepad,
        {
            errorControl = ZO_CharacterSelect_GamepadRenameError,
            errorFragment = CHARACTER_SELECT_RENAME_ERROR_GAMEPAD_FRAGMENT,
            dialogName = "CHARACTER_SELECT_RENAME_CHARACTER_GAMEPAD",
            dialogTitle = function(dialog)
                local titleText = SI_CHARACTER_SELECT_RENAME_CHARACTER_TITLE

                if dialog and dialog.data and dialog.data.renameFromToken then
                    titleText = SI_CHARACTER_SELECT_RENAME_CHARACTER_FROM_TOKEN_TITLE
                end

                return GetString(titleText)
            end,
            dialogMainText = function(dialog)
                local mainText = ""

                if dialog.data and dialog.data.originalCharacterName then
                    mainText = zo_strformat(SI_RENAME_CHARACTER_NAME_LABEL, dialog.data.originalCharacterName)
                end

                return mainText
            end,
            onBack = function()
                -- viewport was never deactivated, so don't reactivate
                local DONT_ACTIVATE_VIEWPORT = false
                ZO_CharacterSelect_Gamepad_ReturnToCharacterList(DONT_ACTIVATE_VIEWPORT)
            end,
            onFinish = function(dialog)
                g_requestedRename = dialog.selectedName

                if g_requestedRename and g_requestedRename ~= "" then
                    local selectedCharacterData = CHARACTER_SELECT_MANAGER:GetSelectedCharacterData()
                    CHARACTER_SELECT_MANAGER:AttemptCharacterRename(selectedCharacterData.id, g_requestedRename, OnRenameResult)
                end
            end,
            createHeaderDataFunction = function(dialog, data)
                local headerData = {}

                if data then
                    if data.renameFromToken then
                        headerData.data1 =
                        {
                            value = GetNumServiceTokens(SERVICE_TOKEN_NAME_CHANGE),
                            header = GetString(SI_SERVICE_TOKEN_COUNT_TOKENS_HEADER),
                        }
                    end
                end

                return headerData
            end,
        })

    ZO_CharacterSelect_Gamepad_InitConfirmDeleteCustomDialog()
end

function ZO_CharacterSelect_Gamepad_BeginRename()
    local selectedCharacterData = CHARACTER_SELECT_MANAGER:GetSelectedCharacterData()
    if selectedCharacterData then
        local dialogData =
        {
            originalCharacterName = selectedCharacterData.name,

            -- Dialog displays additional info if a player is spending a token to rename
            renameFromToken = not selectedCharacterData.needsRename,
        }

        ZO_Dialogs_ShowGamepadDialog("CHARACTER_SELECT_RENAME_CHARACTER_GAMEPAD", dialogData)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

function ZO_CharacterSelect_Gamepad_Login(option)
    local state = PregameStateManager_GetCurrentState()
    if state == "CharacterSelect" then
        local selectedCharacterData = CHARACTER_SELECT_MANAGER:GetSelectedCharacterData()
        if selectedCharacterData then
            PregameStateManager_PlayCharacter(selectedCharacterData.id, option)
            return true
        end
    end
    return false
end

function ZO_CharacterSelect_Gamepad_HasPlayableCharacterSelected()
    return g_canPlayCharacter
end

function ZO_CharacterSelect_Gamepad_ShowLoginScreen()
    local self = ZO_CharacterSelect_Gamepad

    ZO_CharacterSelect_GamepadCharacterViewport.Deactivate()
    SCENE_MANAGER:RemoveFragment(CHARACTER_SELECT_CHARACTERS_GAMEPAD_FRAGMENT)

    ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorLogin)

    -- Show the fact that the login has been requested
    ZO_Dialogs_ShowGamepadDialog("CHARACTER_SELECT_LOGIN")
end

function ZO_CharacterSelect_Gamepad_GetSelectedExtraInfoEntryData()
    local self = ZO_CharacterSelect_Gamepad

    local selectedFocus = self.extraInfoFocus:GetFocusItem()
    if selectedFocus then
        if selectedFocus.control and selectedFocus.control.data then
            return selectedFocus.control.data
        end
    end

    return nil
end

function ZO_CharacterSelect_Gamepad_GetSelectedServiceMode()
    local selectedEntryData = ZO_CharacterSelect_Gamepad_GetSelectedExtraInfoEntryData()
    if selectedEntryData then
        return selectedEntryData.serviceMode
    end

    return SERVICE_TOKEN_NONE
end

function ZO_CharacterSelect_Gamepad_ChangeServiceMode(serviceMode, resetListToDefault)
    local self = ZO_CharacterSelect_Gamepad

    if self.serviceMode ~= serviceMode then
        local previousService = self.serviceMode
        self.serviceMode = serviceMode

        self.extraInfoContainer:SetHidden(serviceMode ~= SERVICE_TOKEN_NONE)

        -- Update Header Text and rebuild the list to filter out invalid options
        local characterListHeader

        if serviceMode == SERVICE_TOKEN_NAME_CHANGE then
            characterListHeader = GetString(SI_CHARACTER_SELECT_RENAME_CHARACTER_FROM_TOKEN_TITLE)
        elseif serviceMode == SERVICE_TOKEN_RACE_CHANGE then
            characterListHeader = GetString(SI_CHARACTER_SELECT_RACE_CHANGE_FROM_TOKEN_TITLE)
        elseif serviceMode == SERVICE_TOKEN_APPEARANCE_CHANGE then
            characterListHeader = GetString(SI_CHARACTER_SELECT_APPEARANCE_CHANGE_FROM_TOKEN_TITLE)
        elseif serviceMode == SERVICE_TOKEN_ALLIANCE_CHANGE then
            characterListHeader = GetString(SI_CHARACTER_SELECT_ALLIANCE_CHANGE_FROM_TOKEN_TITLE)
        else
            characterListHeader = GetString(SI_CHARACTER_SELECT_GAMEPAD_SELECT_CHARACTER)
        end

        self.headerData.titleText = characterListHeader

        RecreateList(self)

        -- Update list positions
        if resetListToDefault and not CHARACTER_SELECT_MANAGER:GetEventAnnouncementAutoShowIndex() then
            if serviceMode == SERVICE_TOKEN_NONE then
                self.characterList:SetSelectedIndex(1)
                SelectedListDataChanged(self, self.characterList, { type = ENTRY_TYPE_EXTRA_INFO })
                self.characterList:Deactivate()
                self.extraInfoFocus:Activate()

                -- Select the previously selected service in the extra info control, if it exists
                for i = 1, self.extraInfoFocus:GetItemCount() do
                    local item = self.extraInfoFocus:GetItem(i)

                    if item and item.control then
                        if item.control.data.serviceMode == previousService then
                            self.extraInfoFocus:SetFocusByIndex(i)
                            break
                        end
                    end
                end
            else
                self.characterList:Activate()
                self.extraInfoFocus:Deactivate()
                
                -- after activating the character list select the first character
                -- if this is done before activation, the keybinds won't refresh correctly
                self.characterList:SetSelectedIndex(1)
            end
        end
    end
end
