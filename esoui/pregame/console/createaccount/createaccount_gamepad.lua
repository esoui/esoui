local GAMEPAD_CREATE_ACCOUNT_ERROR_DIALOG = "GAMEPAD_CREATE_ACCOUNT_ERROR_DIALOG"

-- Configuration Options
local MINIMUM_AGE = 13

-- Main class.
local ZO_CreateAccount_Gamepad = ZO_Object:Subclass()

function ZO_CreateAccount_Gamepad:New(control)
    local object = ZO_Object.New(self)
    object:Initialize(control)
    return object
end

function ZO_CreateAccount_Gamepad:Initialize(control)
    self.control = control
    self.entryByCountry = {}

    local createAccount_Gamepad_Fragment = ZO_FadeSceneFragment:New(self.control)
    CREATE_ACCOUNT_GAMEPAD_SCENE = ZO_Scene:New("CreateAccount_Gamepad", SCENE_MANAGER)
    CREATE_ACCOUNT_GAMEPAD_SCENE:AddFragment(createAccount_Gamepad_Fragment)

    CREATE_ACCOUNT_GAMEPAD_SCENE:RegisterCallback("StateChange", function(oldState, newState)
                if newState == SCENE_SHOWING then
                    self:ResetMainList()
                    KEYBIND_STRIP:RemoveDefaultExit()
                    self:SwitchToMainList()

                elseif newState == SCENE_HIDDEN then
                    self:ResetScreen()
                    self:SwitchToKeybind(nil)
                    KEYBIND_STRIP:RestoreDefaultExit()
                end
            end)
end

function ZO_CreateAccount_Gamepad:ResetScreen()
    self.optionsControl:SetHidden(true)
    self.header:SetHidden(false)

    self.optionsList:Deactivate()

    if self.countriesList then
        self.countriesList:Deactivate()
    end
end

function ZO_CreateAccount_Gamepad:PerformDeferredInitialize()
    if not self.initialized then 
        self.initialized = true

        self.header = self.control:GetNamedChild("Container"):GetNamedChild("Header")

        self:SetupOptionsList()
        self:InitKeybindingDescriptors()

        self:InitializeErrorDialog()
    end
end

do
    local g_lastErrorString = nil

    function ZO_CreateAccount_Gamepad:InitializeErrorDialog()
        ZO_Dialogs_RegisterCustomDialog(GAMEPAD_CREATE_ACCOUNT_ERROR_DIALOG,
        {
            gamepadInfo = {
                dialogType = GAMEPAD_DIALOGS.BASIC,
            },

            mustChoose = true,

            title =
            {
                text = SI_CREATEACCOUNT_ERROR_HEADER,
            },

            mainText = 
            {
                text = function() return g_lastErrorString end,
            },

            buttons =
            {
                {
                    keybind = "DIALOG_NEGATIVE",
                    text = SI_DIALOG_EXIT,
                },
            }
        })
    end

    function ZO_CreateAccount_Gamepad:ShowError(message)
        g_lastErrorString = message
        ZO_Dialogs_ShowGamepadDialog(GAMEPAD_CREATE_ACCOUNT_ERROR_DIALOG)
    end
end

function ZO_CreateAccount_Gamepad:ClearError()
    g_lastErrorString = ""
end

function ZO_CreateAccount_Gamepad:HasValidCountrySelected()
    return self.selectedCountry ~= nil and self.selectedCountry ~= ""
end

function ZO_CreateAccount_Gamepad:CreateAccountSelected()
    if (not self:HasValidCountrySelected()) then
        self:ShowError(GetString(SI_CONSOLE_CREATEACCOUNT_NOCOUNTRY))
    elseif (self.enteredEmail == nil) or (self.enteredEmail == "") then
        self:ShowError(GetString(SI_CONSOLE_CREATEACCOUNT_NOEMAIL))
    elseif self.ageValid ~= true then
        self:ShowError(zo_strformat(SI_CONSOLE_CREATEACCOUNT_BADAGE, MINIMUM_AGE))
    elseif(not self.creatingAccount) then
        self:ClearError()
        PregameStateManager_AdvanceState()
        self.creatingAccount = true
    end
end

function ZO_CreateAccount_Gamepad:InitKeybindingDescriptors()
    local function SwitchToMainList()
        PlaySound(SOUNDS.NEGATIVE_CLICK)
        self:SwitchToMainList()
    end

    local returnToMainListDescriptor = KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(SwitchToMainList)

    self.mainKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select Control
        {    
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local data = self.optionsList:GetTargetData()
                local control = self.optionsList:GetTargetControl()
                if data ~= nil and data.selectedCallback ~= nil and control ~= nil then
                    data.selectedCallback(control, data)
                end
            end,
        },
        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
                PlaySound(SOUNDS.NEGATIVE_CLICK)
                PregameStateManager_SetState("CreateLinkAccount")
            end)
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.mainKeybindStripDescriptor, self.optionsList)


    self.errorKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Back
        returnToMainListDescriptor,
    }
end

function ZO_CreateAccount_Gamepad:SwitchToKeybind(keybindStripDescriptor)
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
    self.keybindStripDescriptor = keybindStripDescriptor
    if keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(keybindStripDescriptor)
    end
end

function ZO_CreateAccount_Gamepad:SwitchToMainList()
    self:ResetScreen()

    self:AddSecondaryListEntries()

    self:SwitchToKeybind(self.mainKeybindStripDescriptor)

    self.optionsList:Activate()
    self.optionsList:RefreshVisible()
    self.optionsControl:SetHidden(false)
    self.defaultTextLabel:SetHidden(self:HasValidCountrySelected())
end

function ZO_CreateAccount_Gamepad:SwitchToCountryList()
    self:ResetScreen()

    self:SwitchToKeybind(self.countriesKeybindStripDescriptor)

    self.optionsControl:SetHidden(false)
    self.countriesList:Activate()
    self.countriesList:HighlightSelectedItem()
    self.defaultTextLabel:SetHidden(true)
end

function ZO_CreateAccount_Gamepad:AddComboBox(text, contents, selectedCallback, editedCallback)
    local option = ZO_GamepadEntryData:New()
    option:SetHeader(text)
    option.contents = contents
    option.selectedCallback = selectedCallback
    option.contentsChangedCallback = editedCallback
    option:SetFontScaleOnSelection(false)
    self.optionsList:AddEntryWithHeader("ZO_GamepadCountrySelectorTemplate", option)
end

function ZO_CreateAccount_Gamepad:AddTextEdit(text, contents, selectedCallback, editedCallback)
    local option = ZO_GamepadEntryData:New() -- No text to populate - it uses a header instead.
    option:SetHeader(text)
    option.contents = contents
    option.selectedCallback = selectedCallback
    option.contentsChangedCallback = editedCallback
    option:SetFontScaleOnSelection(true)
    self.optionsList:AddEntry("ZO_PregameGamepadTextEditTemplateWithHeader", option)
end

function ZO_CreateAccount_Gamepad:AddCheckbox(text, checked, callback)
    local option = ZO_GamepadEntryData:New(text)
    option.checked = checked
    option.setChecked = callback
    option.selectedCallback = ZO_GamepadCheckBoxTemplate_OnClicked
    option:SetFontScaleOnSelection(true)
    option.list = self.optionsList
    self.optionsList:AddEntry("ZO_CheckBoxTemplate_Pregame_Gamepad", option)
end

function ZO_CreateAccount_Gamepad:AddButton(text, callback)
    local option = ZO_GamepadEntryData:New(text)
    option.selectedCallback = callback
    option:SetFontScaleOnSelection(true)
    self.optionsList:AddEntry("ZO_PregameGamepadButtonWithTextTemplate", option)
end

function ZO_CreateAccount_Gamepad:ActivateEditbox(edit, isEmailBox)
	if (isEmailBox == true) then
		edit:SetVirtualKeyboardType(VIRTUAL_KEYBOARD_TYPE_EMAIL)
	else
		edit:SetVirtualKeyboardType(VIRTUAL_KEYBOARD_TYPE_DEFAULT)
	end
    edit:TakeFocus()
end

function ZO_CreateAccount_Gamepad:SetupOptionsList()
    -- Setup the actual list.
    self.optionsControl = self.control:GetNamedChild("Container"):GetNamedChild("Options")
    self.optionsList = ZO_GamepadVerticalParametricScrollList:New(self.optionsControl:GetNamedChild("List"))

    self.optionsList:SetAlignToScreenCenter(true)

    self.optionsList:AddDataTemplateWithHeader("ZO_PregameGamepadTextEditTemplate", ZO_PregameGamepadTextEditTemplate_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_PregameGamepadTextEditHeaderTemplate")
    self.optionsList:AddDataTemplate("ZO_CheckBoxTemplate_Pregame_Gamepad", ZO_GamepadCheckBoxListEntryTemplate_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.optionsList:AddDataTemplate("ZO_PregameGamepadButtonWithTextTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    local function SetupCountrySelector(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        if self.comboControl ~= control then
            self.comboControl = control
            self.countriesList = control.dropdown
            self.countriesList:SetDeactivatedCallback(function() self:SwitchToMainList() end)
            self.countriesList:SetSortsItems(false)
            self.defaultTextLabel = control:GetNamedChild("DefaultText")
            self.defaultTextLabel:SetText(GetString(SI_CREATEACCOUNT_SELECT_COUNTRY))
        end
    end

    self.optionsList:AddDataTemplateWithHeader("ZO_GamepadCountrySelectorTemplate", SetupCountrySelector, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_PregameGamepadTextEditHeaderTemplate")

    -- Populate the main list.
    self:ResetMainList()
end

function ZO_CreateAccount_Gamepad:ResetMainList()
    -- Setup the data used by the main list controls.
    self.selectedCountry = ""
    self.enteredEmail = ""
    self.ageValid = false
    self.emailSignup = false
    self.lastErrorMessage = ""
    self.secondaryEntriesAdded = false
    self.creatingAccount = false

    -- Populate the list.
    self.optionsList:Clear()

    self:AddComboBox(GetString(SI_CREATEACCOUNT_COUNTRY), function(data) return self.selectedCountry end, function(control, data)
                self:SwitchToCountryList()
            end)

    self:AddTextEdit(GetString(SI_CREATEACCOUNT_EMAIL), function(data) return self.enteredEmail	end, function(control, data) self:ActivateEditbox(control.edit, true) end, function(newText) self.enteredEmail = newText end)
    
    self.optionsList:Commit()
    self.countriesList:ClearItems()
    self:PopulateCountriesDropdownList()
end

function ZO_CreateAccount_Gamepad:AddSecondaryListEntries()
    if((not self.secondaryEntriesAdded) and (self.selectedCountry ~= "")) then
        self:AddCheckbox(zo_strformat(SI_CREATEACCOUNT_AGE, MINIMUM_AGE), function(data) return self.ageValid end, function(data, checked) self.ageValid = checked end)
        self:AddCheckbox(GetString(SI_CREATEACCOUNT_EMAIL_SIGNUP), function(data) return self.emailSignup end, function(data, checked) self.emailSignup = checked end)
        self:AddButton(GetString(SI_CREATEACCOUNT_CREATE_ACCOUNT_BUTTON), function(control, data)
                    PlaySound(SOUNDS.POSITIVE_CLICK)
                    self:CreateAccountSelected()
                end)

        self.optionsList:Commit()
        self.secondaryEntriesAdded = true
    end
end

function ZO_CreateAccount_Gamepad:PopulateCountriesDropdownList()
    -- Checking for 0 to ensure we only setup the country list once
    if self.countriesList:GetNumItems() == 0 then       

        -- Populate the combobox list.
        self.countriesList:ClearItems()

        local numCountries = GetNumberCountries() 

        local function OnCountrySelected(comboBox, entryText, entry)
            self.selectedCountry = entryText 
            self.countryCode = entry.countryCode
            self.emailSignup = entry.megaServer == MEGASERVER_NA
        end

        for i=1, numCountries do
            local countryName, countryCode, megaServer = GetCountryEntry(i)
            local option = self.countriesList:CreateItemEntry(countryName, OnCountrySelected) 
            option.megaServer = megaServer
            option.countryCode = countryCode
            self.countriesList:AddItem(option)
        end

        self.countriesList:HighlightSelectedItem()
        self.optionsList:Commit()
    end
end

function ZO_CreateAccount_Gamepad_Initialize(self)
    CREATE_ACCOUNT_GAMEPAD = ZO_CreateAccount_Gamepad:New(self)
end
