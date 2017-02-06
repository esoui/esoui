local g_currentlySelectedCharacterData
local g_lastSelectedData
local g_canPlayCharacter = true
local g_canCreateCharacter = true

ZO_CHARACTER_SELECT_DETAILS_VALUE_OFFSET_Y = -14
ZO_GAMEPAD_CHARACTER_SELECT_LIST_ENTRY_CHAMPION_ICON_X_OFFSET = -20

local ACTIVATE_VIEWPORT = true

local ENTRY_TYPE_EXTRA_INFO = 1
local ENTRY_TYPE_CHARACTER = 2
local ENTRY_TYPE_CREATE_NEW = 3

local CREATE_NEW_ICON = "EsoUI/Art/Buttons/Gamepad/gp_plus_large.dds"

--[[ Character Select Delete Screen ]]--
local EXPECTED_ICON_SIZE = 64
local BASE_PERCENT = 100

local CHARACTER_DELETE_KEY_ICONS = {
    [true] = {    KEY_GAMEPAD_LEFT_SHOULDER_HOLD,
                KEY_GAMEPAD_RIGHT_SHOULDER_HOLD,
                KEY_GAMEPAD_LEFT_TRIGGER_HOLD,
                KEY_GAMEPAD_RIGHT_TRIGGER_HOLD },
    [false] = {   KEY_GAMEPAD_LEFT_SHOULDER,
                KEY_GAMEPAD_RIGHT_SHOULDER,
                KEY_GAMEPAD_LEFT_TRIGGER,
                KEY_GAMEPAD_RIGHT_TRIGGER },
}
local CHARACTER_DELETE_TEXT_ANIM = {
    ".",
    "..",
    "...",
}
local CHARACTER_DELETE_TEXT_ANIM_SPEED = 0.5

local function ZO_CharacterSelect_Gamepad_GetKeyText(key)
    local path, width, height = ZO_Keybindings_GetTexturePathForKey(key)
    if path then
        local widthPercent = (width / EXPECTED_ICON_SIZE) * BASE_PERCENT;
        local heightPercent = (height / EXPECTED_ICON_SIZE) * BASE_PERCENT;
        return ("|t%f%%:%f%%:%s|t"):format(widthPercent, heightPercent, path)
    end
    return ""
end

function ZO_CharacterSelect_Gamepad_ReturnToCharacterList(activateViewPort)
    local self = ZO_CharacterSelect_Gamepad

    SCENE_MANAGER:AddFragment(CHARACTER_SELECT_CHARACTERS_GAMEPAD_FRAGMENT)
    ZO_CharacterSelect_GamepadCharacterDetails:SetHidden(false)
    
    if activateViewPort then
        ZO_CharacterSelect_GamepadCharacterViewport.Activate()
    end
    
    self.characterList:Activate()
end

local function ZO_CharacterSelect_Gamepad_GetDeleteKeyText()
    local keys = ZO_CharacterSelect_Gamepad.deleteKeys

    local keyText = ""
    for i, enabled in ipairs(keys) do

        if (keyText ~= "") then
            keyText = keyText .. "  "   -- Space out the icons
        end

        local keyCode = CHARACTER_DELETE_KEY_ICONS[enabled][i]
        keyText = keyText .. ZO_CharacterSelect_Gamepad_GetKeyText(keyCode)
    end

    return keyText
end

local function ZO_CharacterSelectDelete_Gamepad_ResetDeleteKeys()
    local keys = ZO_CharacterSelect_Gamepad.deleteKeys

    for i = 1, #keys do
        keys[i] = false
    end
end

local function ZO_CharacterSelectDelete_Gamepad_OnKeyChanged(key, onDown)
    local self = ZO_CharacterSelect_Gamepad
    local keys = self.deleteKeys

    if self.deleting then
        return
    end

    if onDown then
        PlaySound(SOUNDS.POSITIVE_CLICK)
    else
        PlaySound(SOUNDS.NEGATIVE_CLICK)
    end

    -- Change key if we pressed it
    for i, deleteKey in ipairs(CHARACTER_DELETE_KEY_ICONS[false]) do
        if deleteKey == key then
            keys[i] = onDown
        end
    end

    -- Are all of them activated?
    local activated = 0
    for i, deleteKey in ipairs(CHARACTER_DELETE_KEY_ICONS[false]) do
        if keys[i] then
            activated = activated + 1
        end
    end

    if activated == #CHARACTER_DELETE_KEY_ICONS[false] then
        -- Delete character and exit dialog
        PlaySound(SOUNDS.DIALOG_ACCEPT)
        self.deleting = true
        ZO_Dialogs_ReleaseDialog("CONFIRM_DELETE_SELECTED_CHARACTER_GAMEPAD")
        ZO_Dialogs_ShowGamepadDialog("CHARACTER_SELECT_DELETING", {characterId = g_currentlySelectedCharacterData.id})
    end
end

function ZO_CharacterSelect_Gamepad_InitConfirmDeleteCustomDialog()
    ZO_Dialogs_RegisterCustomDialog("CONFIRM_DELETE_SELECTED_CHARACTER_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        setup = function()
            ZO_CharacterSelectDelete_Gamepad_ResetDeleteKeys()
        end,
        updateFn = function(dialog)
            ZO_Dialogs_RefreshDialogText("CONFIRM_DELETE_SELECTED_CHARACTER_GAMEPAD", dialog, { mainTextParams = { ZO_CharacterSelect_Gamepad_GetDeleteKeyText() }})
        end,
        mustChoose = true,
        title =
        {
            text = SI_CONFIRM_DELETE_CHARACTER_DIALOG_GAMEPAD_TITLE,
        },
        mainText =
        {
            text = SI_CONFIRM_DELETE_CHARACTER_DIALOG_GAMEPAD_TEXT,
        },
        blockDialogReleaseOnPress = true,
        buttons =
        {
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
            {
                keybind = "DIALOG_LEFT_SHOULDER",
                handlesKeyUp = true,
                ethereal = true,
                callback = function(dialog, onUp)
                    ZO_CharacterSelectDelete_Gamepad_OnKeyChanged(KEY_GAMEPAD_LEFT_SHOULDER, not onUp)
                end,
            },
            {
                keybind = "DIALOG_RIGHT_SHOULDER",
                handlesKeyUp = true,
                ethereal = true,
                callback = function(dialog, onUp)
                    ZO_CharacterSelectDelete_Gamepad_OnKeyChanged(KEY_GAMEPAD_RIGHT_SHOULDER, not onUp)
                end,
            },
            {
                keybind = "DIALOG_LEFT_TRIGGER",
                handlesKeyUp = true,
                ethereal = true,
                callback = function(dialog, onUp)
                    ZO_CharacterSelectDelete_Gamepad_OnKeyChanged(KEY_GAMEPAD_LEFT_TRIGGER, not onUp)
                end,
            },
            {
                keybind = "DIALOG_RIGHT_TRIGGER",
                handlesKeyUp = true,
                ethereal = true,
                callback = function(dialog, onUp)
                    ZO_CharacterSelectDelete_Gamepad_OnKeyChanged(KEY_GAMEPAD_RIGHT_TRIGGER, not onUp)
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

local function InitKeybindingDescriptor(self)

    local deleteKeybind = {
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

    local optionsKeybind = {
        name = GetString(SI_CHARACTER_SELECT_GAMEPAD_OPTIONS),
        keybind = "UI_SHORTCUT_TERTIARY",

        callback = function()
            -- fix to keep both buttons from being pushable in the time it takes for the state to change
            local state = PregameStateManager_GetCurrentState()
            if(state == "CharacterSelect" or state == "CharacterSelect_FromCinematic") then
                SCENE_MANAGER:Push("gamepad_options_root")
            end
        end,
    }

    self.charListKeybindStripDescriptorDefault =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
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
        deleteKeybind,
        optionsKeybind,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() PregameStateManager_SetState("Disconnect") end),
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
                ZO_CharacterSelect_GamepadCharacterDetails:SetHidden(true)
                ZO_CharacterSelect_Gamepad_BeginRename()
            end,
        },
        deleteKeybind,
        optionsKeybind,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() PregameStateManager_SetState("Disconnect") end),
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
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() PregameStateManager_SetState("Disconnect") end),
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.charListKeybindStripDescriptorCreateNew, self.characterList)

    -- Keybinds for the additional character slot control
    self.charListKeybindStripDescriptorAdditionalSlots =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        optionsKeybind,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() PregameStateManager_SetState("Disconnect") end),
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
                local requestedServiceMode = ZO_CharacterSelect_Gamepad_GetSelectedServiceMode()
                if requestedServiceMode ~= SERVICE_TOKEN_NONE then
                    return GetNumServiceTokens(requestedServiceMode) > 0
                end

                return false
            end,
            callback = function()
                local newServiceMode = ZO_CharacterSelect_Gamepad_GetSelectedServiceMode()
                local RESET_LIST_TO_DEFAULT = true
                ZO_CharacterSelect_Gamepad_ChangeServiceMode(newServiceMode, RESET_LIST_TO_DEFAULT)
            end,
        },
        optionsKeybind,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() PregameStateManager_SetState("Disconnect") end),
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
                    local DONT_RESET_TO_DEFAULT = false
                    ZO_CHARACTERCREATE_MANAGER:InitializeForRaceChange(g_currentlySelectedCharacterData.dataSource)
                    PregameStateManager_SetState("CharacterCreate_Barbershop")
                elseif self.serviceMode == SERVICE_TOKEN_APPEARANCE_CHANGE then
                    local DONT_RESET_TO_DEFAULT = false
                    ZO_CHARACTERCREATE_MANAGER:InitializeForAppearanceChange(g_currentlySelectedCharacterData.dataSource)
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

local function GetClassIconGamepad(classIdRequested)
    for i = 1, GetNumClasses() do
        local classId, _, _, _, _, _, _, _, gamepadNormalIcon, gamepadPressedIcon = GetClassInfo(i)
        if classId == classIdRequested then
            return gamepadPressedIcon
        end
    end
    return nil
end

local function AddCharacterListEntry(template, data, list)
    local text = (data.name ~= nil) and zo_strformat(SI_CHARACTER_SELECT_NAME, data.name) or data.text

    local newEntry = ZO_GamepadEntryData:New(text, data.icon)

    if data.header then
        newEntry:SetHeader(data.header)
    end

    newEntry:SetFontScaleOnSelection(true)

    -- character select stores a bunch of data that we need on this entry to function correctly
    newEntry:SetDataSource(data)
    newEntry:SetIconTintOnSelection(true)

    list:AddEntry(template, newEntry)
end

local function CharacterListEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    data:ClearIcons()

    -- we can't set these up at list creation time as the character data isn't fully loaded yet (GetNumClasses() returns 0, which makes GetClassIconGamepad(...) results all nil)
    icon = ((data.name ~= nil) and data.class) and GetClassIconGamepad(data.class) or data.icon

    data:AddIcon(icon)

    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
end

local function GamepadCharacterSelectMenuEntryHeader_Setup(headerControl, data, ...)
    ZO_ParametricScrollList_DefaultMenuEntryWithHeaderSetup(headerControl, data, ...)

    local subHeader = headerControl:GetNamedChild("SubHeader")

    if subHeader then
        subHeader:SetText(data.subHeader or "")
    end
end

local function ZO_CharacterSelect_Gamepad_GetMaxCharacters()
    return g_maxCharacters
end

local function ZO_CharacterSelect_Gamepad_SetMaxCharacters(characterLimit)
    g_maxCharacters = characterLimit
end

-- Extra Info Functions

local function CanShowExtraInfo(self)
    return self.serviceMode == SERVICE_TOKEN_NONE
end

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

    if data.tokenCount then
        control.tokenCount:SetText(data.tokenCount)
        control.icon:SetDesaturation(data.tokenCount > 0 and 0 or 1)
    end
    control.tokenCount:SetHidden(data.tokenCount == nil)

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
    
    local showExtraInfo = CanShowExtraInfo(self)
    if showExtraInfo then
        local data = {}

        local function ServiceTokenTooltipFunction(serviceMode, descriptionTextId)
            self.extraInfoDetails:SetHidden(false)

            local title = zo_strformat(SI_SERVICE_TOOLTIP_HEADER_FORMATTER, GetString("SI_SERVICETOKENTYPE", serviceMode))
            local body1 = GetString(descriptionTextId)
            local body2
            local body2Color

            local numTokens = GetNumServiceTokens(serviceMode)
            if numTokens ~= 0 then
                body2 = zo_strformat(SI_SERVICE_TOOLTIP_SERVICE_TOKENS_AVAILABLE, numTokens, GetString("SI_SERVICETOKENTYPE", serviceMode))
                body2Color = ZO_SUCCEEDED_TEXT
            else
                body2 = zo_strformat(SI_SERVICE_TOOLTIP_NO_SERVICE_TOKENS_AVAILABLE, GetString("SI_SERVICETOKENTYPE", serviceMode))
                body2Color = ZO_ERROR_COLOR
            end

            ZO_CharacterSelect_Gamepad_SetExtraInfoDetails(title, body1, nil, body2, body2Color)
        end

        -- Name Change Tokens
        table.insert(data, {
            keybindStripDesc = self.charListKeybindStripDescriptorServices,
            icon = "EsoUI/Art/Icons/Token_NameChange.dds",
            serviceMode = SERVICE_TOKEN_NAME_CHANGE,
            tokenCount = GetNumServiceTokens(SERVICE_TOKEN_NAME_CHANGE),
            ShowTooltipFunction = function()
                    ServiceTokenTooltipFunction(SERVICE_TOKEN_NAME_CHANGE, SI_SERVICE_TOOLTIP_NAME_CHANGE_TOKEN_DESCRIPTION)
                end,
            HideTooltipFunction = function()
                    self.extraInfoDetails:SetHidden(true)
                end,
        })
        table.insert(data, {
            keybindStripDesc = self.charListKeybindStripDescriptorServices,
            icon = "EsoUI/Art/Icons/Token_RaceChange.dds",
            serviceMode = SERVICE_TOKEN_RACE_CHANGE,
            tokenCount = GetNumServiceTokens(SERVICE_TOKEN_RACE_CHANGE),
            ShowTooltipFunction = function()
                    ServiceTokenTooltipFunction(SERVICE_TOKEN_RACE_CHANGE, SI_SERVICE_TOOLTIP_RACE_CHANGE_TOKEN_DESCRIPTION)
                end,
            HideTooltipFunction = function()
                    self.extraInfoDetails:SetHidden(true)
                end,
        })
        table.insert(data, {
            keybindStripDesc = self.charListKeybindStripDescriptorServices,
            icon = "EsoUI/Art/Icons/Token_AppearanceChange.dds",
            serviceMode = SERVICE_TOKEN_APPEARANCE_CHANGE,
            tokenCount = GetNumServiceTokens(SERVICE_TOKEN_APPEARANCE_CHANGE),
            ShowTooltipFunction = function()
                    ServiceTokenTooltipFunction(SERVICE_TOKEN_APPEARANCE_CHANGE, SI_SERVICE_TOOLTIP_APPEARANCE_CHANGE_TOKEN_DESCRIPTION)
                end,
            HideTooltipFunction = function()
                    self.extraInfoDetails:SetHidden(true)
                end,
        })

        -- Add more extra info controls above this line
        for i=1, #data do
            local control = CreateExtraInfoEntry(self, data[i])
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
        local tokenCount = 0
        local instructions = ""

        tokenCount = GetNumServiceTokens(self.serviceMode)

        if self.serviceMode ~= SERVICE_TOKEN_NONE then
            instructions = zo_strformat(SI_SERVICE_TOKEN_INSTRUCTIONS, GetString("SI_SERVICETOKENTYPE", self.serviceMode))
        end

        self.serviceTokensLabel:SetText(tokenCount)
        self.serviceInstructions:SetText(instructions)
    end

    self.serviceHeader:SetHidden(not headerVisible)
end

local function SetExtraInfoLabel(self, labelName, text, color)
    local label = self.extraInfoDetails:GetNamedChild(labelName)
    label:SetText(text or "")

    if color then
        label:SetColor(color:UnpackRGBA())
    else
        label:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
    end
end

function ZO_CharacterSelect_Gamepad_SetExtraInfoDetails(title, body1, body1Color, body2, body2Color)
    local self = ZO_CharacterSelect_Gamepad

    self.extraInfoDetails:GetNamedChild("Title"):SetText(title or "")

    SetExtraInfoLabel(self, "Description1", body1, body1Color)
    SetExtraInfoLabel(self, "Description2", body2, body2Color)
end

-- End Extra Info functions

local function CreateList(self)
    self.characterList:Clear()

    CreateExtraInfoControls(self)

    local characterDataList = ZO_CharacterSelect_GetCharacterDataList()
    local slot = 1
    if  #characterDataList > 0 then
        local isFirstEntry = true
        
        -- Add Rename characters
        if self.serviceMode ~= SERVICE_TOKEN_NAME_CHANGE then
            for i, data in ipairs(characterDataList) do
                if data.needsRename then
                    local template = "ZO_GamepadMenuEntryTemplateLowercase34"
                    if isFirstEntry then
                        data.header = GetString(SI_CHARACTER_SELECT_GAMEPAD_RENAME_HEADER)
                        template = "ZO_GamepadMenuEntryTemplateLowercase34WithHeader"
                        isFirstEntry = false
                    end

                    data.slot = slot
                    data.type = ENTRY_TYPE_CHARACTER
                    slot = slot + 1
                    AddCharacterListEntry(template , data, self.characterList)
                end
            end
        end

        isFirstEntry = true

        -- Add Selectable characters
        for i, data in ipairs(characterDataList) do
            if not data.needsRename then
                local template = "ZO_GamepadMenuEntryTemplateLowercase34"
                if isFirstEntry then
                    data.header = GetString(SI_CHARACTER_SELECT_GAMEPAD_CHARACTERS_HEADER)
                    template = "ZO_GamepadMenuEntryTemplateLowercase34WithHeader"
                    isFirstEntry = false

                    if self.serviceMode == SERVICE_TOKEN_NONE and ZO_CharacterSelect_CanShowAdditionalSlotsInfo() then
                        data.subHeader = zo_strformat(SI_ADDITIONAL_CHARACTER_SLOTS_DESCRIPTION, ZO_CharacterSelect_GetAdditionalSlotsRemaining())
                    else
                        data.subHeader = nil
                    end
                end
                data.slot = slot
                data.type = ENTRY_TYPE_CHARACTER
                slot = slot + 1
                AddCharacterListEntry(template, data, self.characterList)
            end
        end

    end

    if self.serviceMode == SERVICE_TOKEN_NONE then
        -- Add Create New
        if slot <= ZO_CharacterSelect_Gamepad_GetMaxCharacters() then
            local data = { index = slot, type = ENTRY_TYPE_CREATE_NEW, header = GetString(SI_CHARACTER_SELECT_GAMEPAD_CREATE_NEW_HEADER), icon = CREATE_NEW_ICON, text = GetString(SI_CHARACTER_SELECT_GAMEPAD_CREATE_NEW_ENTRY)}
            AddCharacterListEntry("ZO_GamepadMenuEntryTemplateWithHeader", data, self.characterList)
        end
    elseif self.characterList:GetNumEntries() == 0 then
        -- In a service mode, but no characters qualify for the service
        self.characterList:SetNoItemText(GetString(SI_SERVICE_NO_ELIGIBLE_CHARACTERS))
        ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorUseServiceToken)
    end

    g_currentlySelectedCharacterData = nil
    local bestSelection = ZO_CharacterSelect_GetBestSelectionData()
    if bestSelection then
        local ALLOW_EVEN_IF_DISABLED = true
        local FORCE_ANIMATION = false
        ZO_CharacterSelect_Gamepad.characterList:SetSelectedIndex(bestSelection.slot, ALLOW_EVEN_IF_DISABLED, FORCE_ANIMATION)
    end

    self.characterList:Commit()
end

local function DoCharacterSelection(index)
    -- Get character select first random selection loaded in so not waiting for it
    -- when move to Create
    SetSuppressCharacterChanges(true)
    if IsPregameCharacterConstructionReady() then
        GAMEPAD_CHARACTER_CREATE_MANAGER:GenerateRandomCharacter()
        SelectClothing(DRESSING_OPTION_STARTING_GEAR)
    end

    SetCharacterManagerMode(CHARACTER_MODE_SELECTION)
    SetSuppressCharacterChanges(false)
    SelectCharacterToView(index)
end

local function SelectCharacter(characterData)
    if characterData then
        if IsPregameCharacterConstructionReady() and (g_currentlySelectedCharacterData == nil or g_currentlySelectedCharacterData.index ~= characterData.index) then
            g_currentlySelectedCharacterData = characterData
            DoCharacterSelection(g_currentlySelectedCharacterData.index)
        end
    end
end

local function RecreateList(self)
    CreateList(self)
    RefreshServiceHeaderVisibility(self)
    ZO_CharacterSelect_Gamepad_RefreshHeader()
    SelectCharacter(ZO_CharacterSelect_GetBestSelectionData())
end

local function ZO_CharacterSelect_Gamepad_GetFormattedRace(characterData)
    local raceName = characterData.race and GetRaceName(characterData.gender, characterData.race) or GetString(SI_UNKNOWN_RACE)

    return zo_strformat(SI_CHARACTER_SELECT_RACE, raceName)
end

local function ZO_CharacterSelect_Gamepad_GetFormattedClass(characterData)
    local className = characterData.class and GetClassName(characterData.gender, characterData.class) or GetString(SI_UNKNOWN_CLASS)

    return zo_strformat(SI_CHARACTER_SELECT_CLASS, className)
end

local function ZO_CharacterSelect_Gamepad_GetFormattedAlliance(characterData)
    local allianceName = GetAllianceName(characterData.alliance) or GetString(SI_UNKNOWN_CLASS)

    return zo_strformat(SI_CHARACTER_SELECT_ALLIANCE, allianceName)
end

local function ZO_CharacterSelect_Gamepad_GetRankIcon(rank)
    return zo_iconFormat(GetAvARankIcon(rank), 32, 32)
end

local function ZO_CharacterSelect_Gamepad_GetFormattedLocation(characterData)
    local locationName = characterData.location ~= 0 and GetLocationName(characterData.location) or GetString(SI_UNKNOWN_LOCATION)

    return zo_strformat(SI_CHARACTER_SELECT_LOCATION, locationName)
end

local SetupCharacterList
local SelectedCharacterChanged
do
    SetupCharacterList = function (self, eventCode, numCharacters, maxCharacters, mostRecentlyPlayedCharacterId, numCharacterDeletesRemaining)
        ZO_CharacterSelect_OnCharacterListReceivedCommon(eventCode, numCharacters, maxCharacters, mostRecentlyPlayedCharacterId, numCharacterDeletesRemaining, maxCharacterDeletes)
        g_canCreateCharacter = numCharacters < maxCharacters

        ZO_CharacterSelect_Gamepad_SetMaxCharacters(maxCharacters)
        RecreateList(self)
    end

    SelectedCharacterChanged = function(self, list, selectedData, oldSelectedData)
        if selectedData and selectedData.type == ENTRY_TYPE_EXTRA_INFO then
            g_canPlayCharacter = false
            self.characterNeedsRename:SetHidden(true)
            self.characterDetails:SetHidden(true)
            return
        end
        
        local characterName = self.characterDetails:GetNamedChild("Name")
        local characterRace = self.characterDetails:GetNamedChild("RaceContainer"):GetNamedChild("Race")
        local characterLevel = self.characterDetails:GetNamedChild("LevelContainer"):GetNamedChild("Level")
        local characterClass = self.characterDetails:GetNamedChild("ClassContainer"):GetNamedChild("Class")
        local characterAlliance = self.characterDetails:GetNamedChild("AllianceContainer"):GetNamedChild("Alliance")
        local characterLocation = self.characterDetails:GetNamedChild("LocationContainer"):GetNamedChild("Location")

        local locationName = ""

        if selectedData then
            characterName:SetText(ZO_CharacterSelect_GetFormattedCharacterName(selectedData))
            characterRace:SetText(ZO_CharacterSelect_Gamepad_GetFormattedRace(selectedData))
            characterLevel:SetText(ZO_CharacterSelect_GetFormattedLevel(selectedData))
            characterClass:SetText(ZO_CharacterSelect_Gamepad_GetFormattedClass(selectedData))
            characterAlliance:SetText(ZO_CharacterSelect_Gamepad_GetFormattedAlliance(selectedData))

            -- Location Name isn't always valid
            locationName = ZO_CharacterSelect_Gamepad_GetFormattedLocation(selectedData)

            characterLocation:SetText(locationName)

            if selectedData.name then
                ZO_CharacterSelect_SetPlayerSelectedCharacterId(selectedData.id)
                SelectCharacter(selectedData)
            end

            -- Change the keybind strip if we have create new selected
            local self = ZO_CharacterSelect_Gamepad
            g_canPlayCharacter = false

            if self.serviceMode ~= SERVICE_TOKEN_NONE then
                ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorUseServiceToken)
            elseif selectedData.needsRename then
                ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorRename)
            elseif selectedData.type == ENTRY_TYPE_CREATE_NEW then
                ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorCreateNew)
            else
                g_canPlayCharacter = true
                ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorDefault)
            end
        else
            ZO_CharacterSelect_SetPlayerSelectedCharacterId(nil)
        end

        -- Only show the character details if the slot is valid
        ZO_CharacterSelect_GamepadCharacterDetails:SetHidden(not (selectedData and selectedData.name and locationName ~= ""))

        -- Handle needs rename text
        local needsRename = selectedData and selectedData.needsRename
        self.characterDetails:SetHidden(needsRename)
        self.characterNeedsRename:SetHidden(not needsRename)

        g_lastSelectedData = selectedData
    end
end

function ZO_CharacterSelect_Gamepad_RefreshCharacter()
    local self = ZO_CharacterSelect_Gamepad

    SelectedCharacterChanged(self, nil, g_lastSelectedData, nil)
end

local function GetPlayerCountString()
    local characterDataList = ZO_CharacterSelect_GetCharacterDataList()
    return zo_strformat(SI_CHARACTER_SELECT_GAMEPAD_CHARACTERS_COUNTER, #characterDataList, ZO_CharacterSelect_Gamepad_GetMaxCharacters())
end

function ZO_CharacterSelect_Gamepad_RefreshHeader()
    local self = ZO_CharacterSelect_Gamepad

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    ZO_CharacterSelectProfile_Gamepad:GetNamedChild("CharacterCount"):SetText(GetPlayerCountString())
    ZO_CharacterSelectProfile_Gamepad:GetNamedChild("Profile"):SetText(GetOnlineIdForActiveProfile())
    local accountChampionPoints = ZO_CharacterSelect_GetAccountChampionPoints()
    local championPointsContainer = ZO_CharacterSelectProfile_Gamepad:GetNamedChild("ChampionPointsContainer")
    if accountChampionPoints > 0 then
        championPointsContainer:SetHidden(false)
        championPointsContainer:GetNamedChild("ChampionPointsCount"):SetText(accountChampionPoints)
    else
        championPointsContainer:SetHidden(true)
    end
end

local function OnCharacterConstructionReady()
    if(GetNumCharacters() > 0) then
        g_currentlySelectedCharacterData = g_currentlySelectedCharacterData or ZO_CharacterSelect_GetBestSelectionData()

        if g_currentlySelectedCharacterData then
            DoCharacterSelection(g_currentlySelectedCharacterData.index)

            local ALLOW_EVEN_IF_DISABLED = true
            local FORCE_ANIMATION = false
            ZO_CharacterSelect_Gamepad.characterList:SetSelectedIndexWithoutAnimation(g_currentlySelectedCharacterData.slot, ALLOW_EVEN_IF_DISABLED, FORCE_ANIMATION)

            --if we're quick launching, then just select the first character we can.
            if (GetCVar("QuickLaunch") == "1") then
                ZO_CharacterSelect_Gamepad_Login(CHARACTER_OPTION_EXISTING_AREA)
            end
        end
        ZO_CharacterSelect_Gamepad_RefreshCharacter()
    end
end

local function OnPregameFullyLoaded()
    local self = ZO_CharacterSelect_Gamepad

    RecreateList(self)
    
    if self.active then
        self.characterList:Activate()
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

    if (keybindStrip) then
        self.charListKeybindStripDescriptor = keybindStrip
    end

    if self.active and self.currentKeystrip ~= self.charListKeybindStripDescriptor then
        ZO_CharacterSelect_Gamepad_ClearKeybindStrip()

        self.currentKeystrip = self.charListKeybindStripDescriptor
        KEYBIND_STRIP:RemoveDefaultExit()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.charListKeybindStripDescriptor)
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

        if PregameIsFullyLoaded() then
            self.characterList:RefreshVisible()
            self.characterList:Activate()
            self.extraInfoFocus:Deactivate()
        end

        ZO_CharacterSelect_Gamepad_RefreshKeybindStrip()
        if IsPregameCharacterConstructionReady() then
            OnCharacterConstructionReady()  -- So that if we come to this screen from Character Create, it will load a different scene.
        end

        DIRECTIONAL_INPUT:Activate(self, self)
    elseif newState == SCENE_HIDDEN then
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
    -- We need to release the dialog to make sure the keybinds are cleared.
    -- Releasing this dialog will request the character list
    ZO_CharacterSelect_Gamepad.deleting = false
    ZO_CharacterSelect_Gamepad.refresh = true
    ZO_Dialogs_ReleaseDialog("CHARACTER_SELECT_DELETING")
end

local g_requestedRename = ""

local function OnCharacterRenamedSuccessCallback()
    local DONT_RESET_TO_DEFAULT = false
    local self = ZO_CharacterSelect_Gamepad

    -- there are multiple ways to rename a character, some of which do not change the servicemode, so we will
    -- check if this is from a service use or not, and update the appropriate items
    if self.serviceMode == SERVICE_TOKEN_NONE then
        ZO_CharacterSelect_Gamepad_ReturnToCharacterList(ACTIVATE_VIEWPORT)
    else
        ZO_CharacterSelect_Gamepad_ChangeServiceMode(SERVICE_TOKEN_NONE, DONT_RESET_TO_DEFAULT)
    end
end

local function OnCharacterRenamedErrorCallback()
    ZO_CharacterSelect_Gamepad_BeginRename()
end

local function OnCharacterRenamed(eventCode, charId, result)
    ZO_CharacterSelect_OnCharacterRenamedCommon(eventCode, charId, result, g_requestedRename, OnCharacterRenamedSuccessCallback, OnCharacterRenamedErrorCallback)
end

local function ContextFilter(callback)
    -- This will wrap the callback so that it gets called in the appropriate context
    return function(...)
        if IsConsoleUI() then
            callback(...)
        end
    end
end

local function OnPregameCharacterListReceived(characterCount, previousCharacterCount)
    if (characterCount > 0) then
        local currentState = PregameStateManager_GetCurrentState()

        -- The character list is received a second time once a character is renamed, which prevents the rename success dialog from
        -- displaying if we're already at CharacterSelect
        if currentState ~= "CharacterSelect" and currentState ~= "WaitForPregameFullyLoaded" then
            PregameStateManager_SetState("WaitForPregameFullyLoaded")
        end
    end
end

function ZO_CharacterSelect_Gamepad_UpdateDirectionalInput()
    local self = ZO_CharacterSelect_Gamepad
    local result = self.movementController:CheckMovement()

    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        if self.extraInfoFocus.active then
            SelectedCharacterChanged(self, self.characterList, g_lastSelectedData)
            self.extraInfoFocus:Deactivate()
            self.characterList:Activate()
            PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
        else
            self.characterList:MoveNext()
        end
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then 
        if self.characterList:GetSelectedIndex() ~= 1 then
            self.characterList:MovePrevious()
        elseif not self.extraInfoContainer:IsHidden() then
            SelectedCharacterChanged(self, self.characterList, { type = ENTRY_TYPE_EXTRA_INFO })
            self.extraInfoFocus:Activate()
            self.characterList:Deactivate()
            PlaySound(SOUNDS.GAMEPAD_MENU_UP)
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

    self.UpdateDirectionalInput = ZO_CharacterSelect_Gamepad_UpdateDirectionalInput
    self.characterList:SetDirectionalInputEnabled(false)

    self.characterDetails = self:GetNamedChild("CharacterDetails"):GetNamedChild("Container")
    self.extraInfoDetails = self:GetNamedChild("CharacterDetails"):GetNamedChild("ExtraInfoDetails")
    self.characterNeedsRename = self:GetNamedChild("CharacterDetails"):GetNamedChild("NeedsRename")
    self.header = self:GetNamedChild("Mask"):GetNamedChild("Characters"):GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)
    self.headerData = {
        titleText = GetString(SI_CHARACTER_SELECT_GAMEPAD_SELECT_CHARACTER),
    }

    -- Extra Info controls
    self.extraInfoContainer = self:GetNamedChild("Mask"):GetNamedChild("Characters"):GetNamedChild("HeaderContainer"):GetNamedChild("ExtraInfo")
    self.extraInfoCenterer = self.extraInfoContainer:GetNamedChild("Centerer")
    self.extraInfoFocus = ZO_GamepadFocus:New(self.extraInfoCenterer, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.extraInfoFocus.onPlaySoundFunction = function() PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED) end

    self.extraInfoFocus:SetFocusChangedCallback(function(focusItem)
            if focusItem then
                ZO_CharacterSelect_Gamepad_UpdateExtraInfoKeybinds(focusItem.control)
            end
        end)

    self.extraInfoControlPool = ZO_ControlPool:New("ZO_CharacterSelect_ExtraInfo_Entry", self.extraInfoCenterer)

    -- Service header controls
    self.serviceMode = SERVICE_TOKEN_NONE

    self.serviceHeader = self:GetNamedChild("Mask"):GetNamedChild("Characters"):GetNamedChild("HeaderContainer"):GetNamedChild("CurrentServiceInfo")
    self.serviceTokensLabel = self.serviceHeader:GetNamedChild("Tokens")
    self.serviceInstructions = self.serviceHeader:GetNamedChild("Instructions")

    InitKeybindingDescriptor(self) -- Depends on self.characterList since we bind to it.

    local function OnCharacterSelectionChanged(list, selectedData, oldSelectedData)
        SelectedCharacterChanged(self, list, selectedData, oldSelectedData)
    end

    local function OnCharacterListReceived(eventCode, numCharacters, maxCharacters, mostRecentlyPlayedCharacterId, numCharacterDeletesRemaining, maxCharacterDeletes)
        if ZO_CharacterSelect_Gamepad.refresh then
            if numCharacters == 0 then
                return -- We are going to the character create screen
            end
            PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
            ZO_CharacterSelect_Gamepad_ReturnToCharacterList(ACTIVATE_VIEWPORT)
            ZO_CharacterSelect_Gamepad.refresh = false
            ZO_CharacterSelect_Gamepad.characterList:Clear()
        end

        SetupCharacterList(self, eventCode, numCharacters, maxCharacters, mostRecentlyPlayedCharacterId, numCharacterDeletesRemaining, maxCharacterDeletes)
    end

    self.characterList:SetOnTargetDataChangedCallback(OnCharacterSelectionChanged)

    self:RegisterForEvent(EVENT_CHARACTER_LIST_RECEIVED, ContextFilter(OnCharacterListReceived))
    
    local ALWAYS_ANIMATE = true
    CHARACTER_SELECT_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(self, ALWAYS_ANIMATE)
    CHARACTER_SELECT_PROFILE_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CharacterSelectProfile_Gamepad, ALWAYS_ANIMATE)
    CHARACTER_SELECT_RENAME_ERROR_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CharacterSelect_GamepadRenameError, ALWAYS_ANIMATE)
    GAMEPAD_CHARACTER_SELECT_SCENE = ZO_Scene:New("gamepadCharacterSelect", SCENE_MANAGER)
    GAMEPAD_CHARACTER_SELECT_SCENE:AddFragment(CHARACTER_SELECT_GAMEPAD_FRAGMENT)
    GAMEPAD_CHARACTER_SELECT_SCENE:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
    GAMEPAD_CHARACTER_SELECT_SCENE:AddFragment(CHARACTER_SELECT_PROFILE_GAMEPAD_FRAGMENT)

    self.control = GAMEPAD_CHARACTER_SELECT_SCENE

    CHARACTER_SELECT_CHARACTERS_GAMEPAD_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_CharacterSelect_GamepadMaskCharacters)

    GAMEPAD_CHARACTER_SELECT_SCENE:RegisterCallback("StateChange", ZO_CharacterSelect_Gamepad_StateChanged)

    CALLBACK_MANAGER:RegisterCallback("OnCharacterConstructionReady", ContextFilter(OnCharacterConstructionReady))
    CALLBACK_MANAGER:RegisterCallback("PregameFullyLoaded", ContextFilter(OnPregameFullyLoaded))
    CALLBACK_MANAGER:RegisterCallback("PregameCharacterListReceived", ContextFilter(OnPregameCharacterListReceived))

    self:RegisterForEvent(EVENT_CHARACTER_DELETED, ContextFilter(CharacterDeleted))
    self:RegisterForEvent(EVENT_CHARACTER_RENAME_RESULT, ContextFilter(OnCharacterRenamed))

    self.control:AddFragment(KEYBIND_STRIP_GAMEPAD_BACKDROP_FRAGMENT)

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
            onBack = function() ZO_CharacterSelect_Gamepad_ReturnToCharacterList(ACTIVATE_VIEWPORT) end,
            onFinish = function(dialog)
                g_requestedRename = dialog.selectedName

                if g_requestedRename and #g_requestedRename > 0 then
                    AttemptCharacterRename(g_currentlySelectedCharacterData.id, g_requestedRename)
                    ZO_Dialogs_ShowGamepadDialog("CHARACTER_SELECT_CHARACTER_RENAMING")
                end
            end,
            createHeaderDataFunction = function(dialog, data)
                local headerData = {}

                if data then
                    if data.renameFromToken then
                        headerData.data1 = {
                                                value = GetNumServiceTokens(SERVICE_TOKEN_NAME_CHANGE),
                                                header = GetString(SI_SERVICE_TOKEN_COUNT_TOKENS_HEADER)
                                           }
                    end
                end

                return headerData
            end,
        })

    ZO_CharacterSelect_Gamepad_InitConfirmDeleteCustomDialog()
end

function ZO_CharacterSelect_Gamepad_BeginRename()
    if g_currentlySelectedCharacterData then
        local dialogData = {
                                originalCharacterName = g_currentlySelectedCharacterData.name,

                                -- Dialog displays additional info if a player is spending a token to rename
                                renameFromToken = not g_currentlySelectedCharacterData.needsRename,
                           }

        ZO_Dialogs_ShowGamepadDialog("CHARACTER_SELECT_RENAME_CHARACTER_GAMEPAD", dialogData)
        ZO_CharacterSelect_GamepadCharacterDetails:SetHidden(true)
    end
end

function ZO_CharacterSelect_Gamepad_Login(option)
    local state = PregameStateManager_GetCurrentState()
    if(state == "CharacterSelect" or state == "CharacterSelect_FromCinematic") then
        if(g_currentlySelectedCharacterData) then
            PregameStateManager_PlayCharacter(g_currentlySelectedCharacterData.id, option)
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

function ZO_CharacterSelect_Gamepad_SetLabelMaxWidth(labelControl, siblingName)
    local siblingControl = labelControl:GetParent():GetNamedChild(siblingName)
    local isValid, anchor, _, _, offsetX = labelControl:GetAnchor(0)
    local maxConstraintX = ZO_GAMEPAD_CONTENT_WIDTH - offsetX

    if siblingControl then
        maxConstraintX = maxConstraintX - siblingControl:GetWidth()
    end

    labelControl:SetDimensionConstraints(maxConstraintX, 0)
end

function ZO_CharacterSelect_Gamepad_GetSelectedServiceMode()
    local self = ZO_CharacterSelect_Gamepad

    local selectedFocus = self.extraInfoFocus:GetFocusItem()
    local serviceMode = SERVICE_TOKEN_NONE

    if selectedFocus then
        if selectedFocus.control and selectedFocus.control.data then
            serviceMode = selectedFocus.control.data.serviceMode
        end
    end

    return serviceMode
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
        else
            characterListHeader = GetString(SI_CHARACTER_SELECT_GAMEPAD_SELECT_CHARACTER)
        end

        self.headerData.titleText = characterListHeader

        RecreateList(self)

        -- Update list positions
        if resetListToDefault then
            self.characterList:SetSelectedIndex(1)

            if serviceMode == SERVICE_TOKEN_NONE then
                SelectedCharacterChanged(self, self.characterList, { type = ENTRY_TYPE_EXTRA_INFO })
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
            end
        end
    end
end
