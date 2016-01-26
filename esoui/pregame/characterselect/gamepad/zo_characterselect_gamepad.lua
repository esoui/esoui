local g_currentlySelectedCharacterData
local g_lastSelectedData
local g_canPlayCharacter = true
local g_canCreateCharacter = true

ZO_CHARACTER_SELECT_DETAILS_SPACING_Y = 51

local CHARACTER_SELECT_GAMEPAD_DIALOG = "CHARACTER_SELECT_GAMEPAD"
local ACTIVATE_VIEWPORT = true

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

    if (onDown) then
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

    if (activated == #CHARACTER_DELETE_KEY_ICONS[false]) then
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

            if selectedData and selectedData.needsRename then
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
                ZO_Dialogs_ShowGamepadDialog(CHARACTER_SELECT_GAMEPAD_DIALOG, { characterName = characterName })
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

local function ZO_CharacterSelect_Gamepad_GetMaxCharacters()
    return g_maxCharacters
end

local function ZO_CharacterSelect_Gamepad_SetMaxCharacters(characterLimit)
    g_maxCharacters = characterLimit
end

local function CreateList(self)
    self.characterList:Clear()

    local characterDataList = ZO_CharacterSelect_GetCharacterDataList()
    local slot = 1
    if(#characterDataList > 0) then
        local isFirstEntry = true
        
        -- Add Rename characters
        for i, data in ipairs(characterDataList) do
            if data.needsRename then
                local template = "ZO_GamepadMenuEntryTemplateLowercase34"
                if isFirstEntry then
                    data.header = GetString(SI_CHARACTER_SELECT_GAMEPAD_RENAME_HEADER)
                    template = "ZO_GamepadMenuEntryTemplateLowercase34WithHeader"
                    isFirstEntry = false
                end

                data.slot = slot
                slot = slot + 1
                AddCharacterListEntry(template , data, self.characterList)
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
                end
                data.slot = slot
                slot = slot + 1
                AddCharacterListEntry(template, data, self.characterList)
            end
        end

    end

    -- Add Create New
    if (slot <= ZO_CharacterSelect_Gamepad_GetMaxCharacters()) then
        local data = { index = slot, createNew = true, header = GetString(SI_CHARACTER_SELECT_GAMEPAD_CREATE_NEW_HEADER), icon = "EsoUI/Art/Buttons/Gamepad/gp_plus_large.dds", text = GetString(SI_CHARACTER_SELECT_GAMEPAD_CREATE_NEW_ENTRY)}
        AddCharacterListEntry("ZO_GamepadMenuEntryTemplateWithHeader", data, self.characterList)
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
    if(IsPregameCharacterConstructionReady()) then
        ZO_CharacterCreate_Gamepad_GenerateRandomCharacter()
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
        CreateList(self)
        ZO_CharacterSelect_Gamepad_RefreshHeader()
        SelectCharacter(ZO_CharacterSelect_GetBestSelectionData())
    end

    SelectedCharacterChanged = function(self, list, selectedData, oldSelectedData)
        local characterName = self.characterDetails:GetNamedChild("Name")
        local characterRace = self.characterDetails:GetNamedChild("Race")
        local characterLevel = self.characterDetails:GetNamedChild("Level")
        local characterClass = self.characterDetails:GetNamedChild("Class")
        local characterAlliance = self.characterDetails:GetNamedChild("Alliance")
        local characterRank = self.characterDetails:GetNamedChild("Rank")
        local characterGrade = self.characterDetails:GetNamedChild("Grade")
        local characterGradeLabel = self.characterDetails:GetNamedChild("GradeLabel")
        local characterLocation = self.characterDetails:GetNamedChild("Location")

        local locationName = ""

        if selectedData then
            characterName:SetText(zo_strformat(SI_CHARACTER_SELECT_NAME, selectedData.name))
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

            if selectedData.needsRename then
                ZO_CharacterSelect_Gamepad_RefreshKeybindStrip(self.charListKeybindStripDescriptorRename)
            elseif selectedData.createNew then
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
end

local function OnCharacterConstructionReady()
    if(GetNumCharacters() > 0) then
        g_currentlySelectedCharacterData = g_currentlySelectedCharacterData or ZO_CharacterSelect_GetBestSelectionData()

        if g_currentlySelectedCharacterData then
            DoCharacterSelection(g_currentlySelectedCharacterData.index)

            local ALLOW_EVEN_IF_DISABLED = true
            local FORCE_ANIMATION = false
            ZO_CharacterSelect_Gamepad.characterList:SetSelectedIndexWithoutAnimation(g_currentlySelectedCharacterData.slot, ALLOW_EVEN_IF_DISABLED, FORCE_ANIMATION)
        end
        ZO_CharacterSelect_Gamepad_RefreshCharacter()
    end
end

local function OnPregameFullyLoaded()
    local self = ZO_CharacterSelect_Gamepad
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
        ZO_CharacterSelect_GamepadCharacterViewport.Activate()
        SCENE_MANAGER:AddFragment(CHARACTER_SELECT_CHARACTERS_GAMEPAD_FRAGMENT)

        if(PregameIsFullyLoaded()) then
            self.characterList:RefreshVisible()
            self.characterList:Activate()
        end

        ZO_CharacterSelect_Gamepad_RefreshKeybindStrip()
        if IsPregameCharacterConstructionReady() then
            OnCharacterConstructionReady()  -- So that if we come to this screen from Character Create, it will load a different scene.
        end
    elseif newState == SCENE_HIDDEN then
        self.active = false
        ZO_CharacterSelect_GamepadCharacterViewport.StopAllInput()
        ZO_CharacterSelect_GamepadCharacterViewport.Deactivate()
        self.characterList:Deactivate()

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

local function OnCharacterRenamed(eventCode, charId, result)
    -- These flags are handled by the dialog
    ZO_CharacterSelect_Gamepad.renaming = false

    if(result ~= NAME_RULE_NO_ERROR) then
        ZO_CharacterSelect_Gamepad.renamingError = GetString("SI_NAMINGERROR", result)

    else
        ZO_CharacterSelect_Gamepad.renamingError = false
    end
end

function ZO_CharacterSelect_Gamepad_IsRenaming()
    return ZO_CharacterSelect_Gamepad.renaming
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
        PregameStateManager_SetState("WaitForPregameFullyLoaded")
    end
end

function ZO_CharacterSelect_Gamepad_Initialize(self)
    self.deleteKeys = {false, false, false, false}

    self.characterList = ZO_GamepadVerticalParametricScrollList:New(self:GetNamedChild("Mask"):GetNamedChild("Characters"):GetNamedChild("List"))
    self.characterList:AddDataTemplate("ZO_GamepadMenuEntryTemplate", CharacterListEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.characterList:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplate", CharacterListEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    self.characterList:AddDataTemplate("ZO_GamepadMenuEntryTemplateLowercase34", CharacterListEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.characterList:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplateLowercase34", CharacterListEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    self.characterList:SetAlignToScreenCenter(true)

    self.characterDetails = self:GetNamedChild("CharacterDetails"):GetNamedChild("Container")
    self.characterNeedsRename = self:GetNamedChild("CharacterDetails"):GetNamedChild("NeedsRename")
    self.header = self:GetNamedChild("Mask"):GetNamedChild("Characters"):GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)
    self.headerData = {
        titleText = GetString(SI_CHARACTER_SELECT_GAMEPAD_SELECT_CHARACTER),
    }

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
            dialogName = CHARACTER_SELECT_GAMEPAD_DIALOG,
            dialogTitle = SI_CHARACTER_SELECT_GAMEPAD_RENAME_TITLE,
            onBack = function() ZO_CharacterSelect_Gamepad_ReturnToCharacterList(ACTIVATE_VIEWPORT) end,
            onFinish = function(dialog)
                local characterName = dialog.selectedName

                if characterName and #characterName > 0 then
                    ZO_CharacterSelect_Gamepad.renaming = true
                    ZO_Dialogs_ShowGamepadDialog("CHARACTER_SELECT_RENAMING", {characterId = g_currentlySelectedCharacterData.id, newName = characterName})
                end
            end,
        })

    ZO_CharacterSelect_Gamepad_InitConfirmDeleteCustomDialog()
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
