local SETUP_MODE_NONE = 0
local SETUP_MODE_NEW = 1
local SETUP_MODE_LINK = 2

local MINIMUM_AGE = 13      -- TODO: We should fetch this from the client instead...

local CreateLinkAccount_Keyboard = ZO_LoginBase_Keyboard:Subclass()

function CreateLinkAccount_Keyboard:New(...)
    return ZO_LoginBase_Keyboard.New(self, ...)
end

function CreateLinkAccount_Keyboard:Initialize(control)
    ZO_LoginBase_Keyboard.Initialize(self, control)

    self.accountSetupContainer = control:GetNamedChild("AccountSetup")
    self.createRadio = self.accountSetupContainer:GetNamedChild("CreateRadio")
    self.linkRadio = self.accountSetupContainer:GetNamedChild("LinkRadio")

    self.radioGroup = ZO_RadioButtonGroup:New()
    self.radioGroup:Add(self.createRadio)
    self.radioGroup:Add(self.linkRadio)

    -- Create Account controls
    self.newAccountContainer = control:GetNamedChild("NewAccount")
    self.accountNameEntry = self.newAccountContainer:GetNamedChild("AccountNameEntry")
    self.accountNameEntryEdit = self.accountNameEntry:GetNamedChild("Edit")
    self.accountNameInstructionsControl = self.accountNameEntry:GetNamedChild("Instructions")
    self.countryLabel = self.newAccountContainer:GetNamedChild("CountryLabel")
    self.countryDropdown = self.newAccountContainer:GetNamedChild("CountryDropdown")
    self.countryDropdownDefaultText = self.countryDropdown:GetNamedChild("DefaultText")
    self.emailLabel = self.newAccountContainer:GetNamedChild("EmailLabel")
    self.emailEntry = self.newAccountContainer:GetNamedChild("EmailEntry")
    self.emailEntryEdit = self.emailEntry:GetNamedChild("Edit")
    self.ageCheckbox = self.newAccountContainer:GetNamedChild("Age")
    self.ageLabel = self.ageCheckbox:GetNamedChild("Label")
    self.subscribeCheckbox = self.newAccountContainer:GetNamedChild("Subscribe")
    self.createAccountButton = self.newAccountContainer:GetNamedChild("CreateAccount")

    ZO_CheckButton_SetToggleFunction(self.ageCheckbox, function() self:UpdateCreateAccountButton() end)

    self.countryComboBox = ZO_ComboBox_ObjectFromContainer(self.countryDropdown)
    self.countryComboBox:SetSortsItems(false)

    self.accountNameEntryEdit:SetMaxInputChars(ACCOUNT_NAME_MAX_LENGTH)
    self.emailEntryEdit:SetMaxInputChars(MAX_EMAIL_LENGTH)

    self:SetupAccountNameInstructions()

    -- Link Account controls
    self.linkAccountContainer = control:GetNamedChild("LinkAccount")
    self.accountName = self.linkAccountContainer:GetNamedChild("AccountName")
    self.accountNameEdit = self.accountName:GetNamedChild("Edit")
    self.password = self.linkAccountContainer:GetNamedChild("Password")
    self.passwordEdit = self.password:GetNamedChild("Edit")
    self.capsLockWarning = self.linkAccountContainer:GetNamedChild("CapsLockWarning")
    self.linkAccountButton = self.linkAccountContainer:GetNamedChild("LinkAccount")

    self.ageLabel:SetText(zo_strformat(SI_CREATEACCOUNT_AGE, MINIMUM_AGE))
    self.mode = SETUP_MODE_NONE

    self.accountNameEdit:SetMaxInputChars(MAX_EMAIL_LENGTH)
    self.passwordEdit:SetMaxInputChars(MAX_PASSWORD_LENGTH)

    self:HideCheckboxesIfNecessary()

    EVENT_MANAGER:RegisterForEvent("CreateLinkAccount", EVENT_SCREEN_RESIZED, function() self:ResizeControls() end)

    local function UpdateForCaps(capsLockIsOn)
        self.capsLockWarning:SetHidden(not capsLockIsOn)
    end

    self.capsLockWarning:RegisterForEvent(EVENT_CAPS_LOCK_STATE_CHANGED, function(eventCode, capsLockIsOn) UpdateForCaps(capsLockIsOn) end)
    
    self:UpdateCreateAccountButton()
    self:UpdateLinkAccountButton()
    self.capsLockWarning:SetHidden(not IsCapsLockOn())

    CREATE_LINK_ACCOUNT_FRAGMENT = ZO_FadeSceneFragment:New(control)
    
    if IsUsingLinkedLogin() then
        LoadCountryData()
        self.control:RegisterForEvent(EVENT_COUNTRY_DATA_LOADED, function() self:PopulateCountryDropdown() end)
    end
end

function CreateLinkAccount_Keyboard:GetControl()
    return self.control
end

function CreateLinkAccount_Keyboard:PopulateCountryDropdown()
    if not self.hasPopulatedCountryDropdown then
        local numCountries = GetNumberCountries()

        for i = 1, numCountries do
            local countryName, countryCode, megaServer = GetCountryEntry(i)

            local entry = ZO_ComboBox:CreateItemEntry(countryName, function(...) self:OnCountrySelected(...) end)
            entry.index = i
            entry.countryName = countryName
            entry.countryCode = countryCode
            entry.megaServer = megaServer
            self.countryComboBox:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
        end

        if numCountries == 1 then
            -- If there's only one choice, select that country immediately and disable the dropdown
            self.countryComboBox:SelectItemByIndex(1)
            self:HideCountryDropdown()
        end

        self.countryComboBox:UpdateItems()
        self.hasPopulatedCountryDropdown = true
    end
end

function CreateLinkAccount_Keyboard:OnCountrySelected(comboBox, entryText, entry)
    self.selectedCountry = entry
    self.countryDropdownDefaultText:SetHidden(true)
    self:UpdateCreateAccountButton()
end

function CreateLinkAccount_Keyboard:SetRadioFromMode(mode)
    if mode ~= self.mode then
        if mode == SETUP_MODE_NEW then
            self.radioGroup:SetClickedButton(self.createRadio)
        elseif mode == SETUP_MODE_LINK then
            self.radioGroup:SetClickedButton(self.linkRadio)
        end
    end
end

function CreateLinkAccount_Keyboard:ChangeMode(newMode)
    self.mode = newMode

    self.newAccountContainer:SetHidden(newMode ~= SETUP_MODE_NEW)
    self.linkAccountContainer:SetHidden(newMode ~= SETUP_MODE_LINK)
end

function CreateLinkAccount_Keyboard:IsRequestedAccountNameValid()
    return self.accountNameValid
end

function CreateLinkAccount_Keyboard:CanCreateAccount()
    return self.emailEntryEdit:GetText() ~= "" and ZO_CheckButton_IsChecked(self.ageCheckbox) and self.selectedCountry ~= nil and self:IsRequestedAccountNameValid()
end

function CreateLinkAccount_Keyboard:CanLinkAccount()
    return self.accountNameEdit:GetText() ~= "" and self.passwordEdit:GetText() ~= ""
end

function CreateLinkAccount_Keyboard:AttemptCreateAccount()
    if self:CanCreateAccount() then
        local email = self.emailEntryEdit:GetText()
        local ageValid = ZO_CheckButton_IsChecked(self.ageCheckbox)
        local emailSignup = ZO_CheckButton_IsChecked(self.subscribeCheckbox)
        local country = self.selectedCountry.countryCode
        local requestedAccountName = self.accountNameEntryEdit:GetText()

        LOGIN_MANAGER_KEYBOARD:AttemptCreateAccount(email, ageValid, emailSignup, country, requestedAccountName)
    end
end

function CreateLinkAccount_Keyboard:AttemptLinkAccount()
    if self:CanLinkAccount() then
        local dialogData = { 
                                partnerAccount = GetExternalName(),
                                esoAccount = self.accountNameEdit:GetText(),
                                password = self.passwordEdit:GetText(),
                           }
        ZO_Dialogs_ShowDialog("LINK_ACCOUNT_KEYBOARD", dialogData)
    end
end

function CreateLinkAccount_Keyboard:UpdateCreateAccountButton()
    self.createAccountButton:SetEnabled(self:CanCreateAccount())
end

function CreateLinkAccount_Keyboard:UpdateLinkAccountButton()
    self.linkAccountButton:SetEnabled(self:CanLinkAccount())
end

function CreateLinkAccount_Keyboard:GetAccountNameEdit()
    return self.accountNameEdit
end

function CreateLinkAccount_Keyboard:GetPasswordEdit()
    return self.passwordEdit
end

function CreateLinkAccount_Keyboard:GetAccountNameEntryEdit()
    return self.accountNameEntryEdit
end

function CreateLinkAccount_Keyboard:GetEmailEntryEdit()
    return self.emailEntryEdit
end

function CreateLinkAccount_Keyboard:HideCheckboxesIfNecessary()
    -- To ensure a consistent layout, hide the age checkbox first if necessary

    if not DoesPlatformRequireAgeVerification() then
        -- We don't need age verification, so check and remove the age checkbox
        ZO_CheckButton_SetChecked(self.ageCheckbox)
        self:HideAgeVerificationCheckbox()
    end

    if not DoesPlatformAllowForEmailSubscription() then
        -- Email subscription isn't allowed on the client, so remove the checkbox
        ZO_CheckButton_SetUnchecked(self.subscribeCheckbox)
        self:HideEmailSubscriptionCheckbox()
    end
end

function CreateLinkAccount_Keyboard:HideAgeVerificationCheckbox()
    -- Hide the age verification checkbox and tranfer the age checkbox anchor to the subscribe checkbox
    self.ageCheckbox:SetHidden(true)

    local _, point, relTo, relPoint, offsetX, offsetY = self.ageCheckbox:GetAnchor(0)

    self.subscribeCheckbox:ClearAnchors()
    self.subscribeCheckbox:SetAnchor(point, relTo, relPoint, offsetX, offsetY)
end

function CreateLinkAccount_Keyboard:HideEmailSubscriptionCheckbox()
    -- Hide the email subscription checkbox, and reanchor the Create Account button
    self.subscribeCheckbox:SetHidden(true)

    -- use the Create Account button's current anchors, but use the subscribe checkbox's relative point
    local _, _, relTo = self.subscribeCheckbox:GetAnchor(0)
    local _, point, _, relPoint, offsetX, offsetY = self.createAccountButton:GetAnchor(0)

    self.createAccountButton:ClearAnchors()
    self.createAccountButton:SetAnchor(point, relTo, relPoint, offsetX, offsetY)
end

function CreateLinkAccount_Keyboard:HideCountryDropdown()
    -- Hide the country dropdown and transfer its anchors to the email entry field
    self.countryLabel:SetHidden(true)
    self.countryDropdown:SetHidden(true)

    local isValid, point, relTo, relPoint, offsetX, offsetY = self.countryLabel:GetAnchor(0)

    self.emailLabel:ClearAnchors()
    self.emailLabel:SetAnchor(point, relTo, relPoint, offsetX, offsetY)
end

function CreateLinkAccount_Keyboard:SetupAccountNameInstructions()
    if not self.accountNameInstructions then
        local ACCOUNT_NAME_INSTRUCTIONS_OFFSET_X = 15
        local ACCOUNT_NAME_INSTRUCTIONS_OFFSET_Y = 0

        self.accountNameInstructions = ZO_ValidAccountNameInstructions:New(self.accountNameInstructionsControl)
        self.accountNameInstructions:SetPreferredAnchor(LEFT, self.accountNameEntryEdit, RIGHT, ACCOUNT_NAME_INSTRUCTIONS_OFFSET_X, ACCOUNT_NAME_INSTRUCTIONS_OFFSET_Y)
    end
end

function CreateLinkAccount_Keyboard:ValidateAccountName()
    local requestedAccountName = self.accountNameEntryEdit:GetText()
    local accountNameViolations = { IsValidAccountName(requestedAccountName) }
    
    self.accountNameValid = #accountNameViolations == 0

    if self.accountNameValid then
        self:HideAccountNameInstructions()
    else
        self.accountNameInstructions:Show(self.accountNameEntryEdit, accountNameViolations)
    end

    self:UpdateCreateAccountButton()
end

function CreateLinkAccount_Keyboard:HideAccountNameInstructions()
    self.accountNameInstructions:Hide()
end

-- XML Handlers --

function ZO_CreateLinkAccount_Initialize(control)
    CREATE_LINK_ACCOUNT_KEYBOARD = CreateLinkAccount_Keyboard:New(control)
end

function ZO_CreateLinkAccount_SetNewAccountMode()
    CREATE_LINK_ACCOUNT_KEYBOARD:ChangeMode(SETUP_MODE_NEW)
end

function ZO_CreateLinkAccount_SetNewAccountModeFromLabel()
    CREATE_LINK_ACCOUNT_KEYBOARD:SetRadioFromMode(SETUP_MODE_NEW)
end

function ZO_CreateLinkAccount_SetLinkAccountMode()
    CREATE_LINK_ACCOUNT_KEYBOARD:ChangeMode(SETUP_MODE_LINK)
end

function ZO_CreateLinkAccount_SetLinkAccountModeFromLabel()
    CREATE_LINK_ACCOUNT_KEYBOARD:SetRadioFromMode(SETUP_MODE_LINK)
end

function ZO_CreateLinkAccount_AttemptCreateAccount()
    CREATE_LINK_ACCOUNT_KEYBOARD:AttemptCreateAccount()
end

function ZO_CreateLinkAccount_AttemptLinkAccount()
    CREATE_LINK_ACCOUNT_KEYBOARD:AttemptLinkAccount()
end

function ZO_CreateLinkAccount_PasswordEdit_TakeFocus()
    CREATE_LINK_ACCOUNT_KEYBOARD:GetPasswordEdit():TakeFocus()
end

function ZO_CreateLinkAccount_AccountNameEdit_TakeFocus()
    CREATE_LINK_ACCOUNT_KEYBOARD:GetAccountNameEdit():TakeFocus()
end

function ZO_CreateLinkAccount_AccountNameEdit_TakeFocus()
    CREATE_LINK_ACCOUNT_KEYBOARD:GetAccountNameEntryEdit():TakeFocus()
end

function ZO_CreateLinkAccount_EmailEdit_TakeFocus()
    CREATE_LINK_ACCOUNT_KEYBOARD:GetEmailEntryEdit():TakeFocus()
end

function ZO_CreateLinkAccount_UpdateCreateAccountButton()
    CREATE_LINK_ACCOUNT_KEYBOARD:UpdateCreateAccountButton()
end

function ZO_CreateLinkAccount_UpdateLinkAccountButton()
    CREATE_LINK_ACCOUNT_KEYBOARD:UpdateLinkAccountButton()
end

function ZO_CreateLinkAccount_ToggleCheckButtonFromLabel(labelControl)
    -- Assumes that the check button is the parent of the label
    local checkButton = labelControl:GetParent()

    ZO_CheckButton_SetCheckState(checkButton, not ZO_CheckButton_IsChecked(checkButton))
end

function ZO_CreateLinkAccount_CheckAccountNameValidity()
    CREATE_LINK_ACCOUNT_KEYBOARD:ValidateAccountName()
end

function ZO_CreateLinkAccount_OnAccountNameFocusLost()
    CREATE_LINK_ACCOUNT_KEYBOARD:HideAccountNameInstructions()
end