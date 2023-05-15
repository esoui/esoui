local LinkAccount_Gamepad = ZO_InitializingObject:Subclass()

function LinkAccount_Gamepad:Initialize(control)
    self.control = control

    local fragment = ZO_FadeSceneFragment:New(self.control)
    LINK_ACCOUNT_ACTIVATION_SCENE = ZO_Scene:New("LinkAccount_Activation_Gamepad", SCENE_MANAGER)
    LINK_ACCOUNT_ACTIVATION_SCENE:AddFragment(fragment)

    LINK_ACCOUNT_ACTIVATION_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialize()

            RequestLinkAccountActivationCode()

            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RemoveDefaultExit()
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end)
end

function LinkAccount_Gamepad:PerformDeferredInitialize()
    if self.initialized then
        return
    end

    self.initialized = true

    self:InitializeControls()
    self:InitializeKeybindStripDescriptors()
    self:InitializeErrorDialog()

    local function OnActivationCodeReceived(eventId, activationCode)
        self.activationCode = activationCode

        local DELIMITER = " "
        local SEGMENT_LENGTH = 4
        local formattedCode = ZO_GenerateDelimiterSegmentedString(activationCode, SEGMENT_LENGTH, DELIMITER)
        self.codeLabel:SetText(formattedCode)

        if LINK_ACCOUNT_ACTIVATION_SCENE:IsShowing() then
            RegisterForLinkAccountActivationProgress()
        end
    end

    self.control:RegisterForEvent(EVENT_ACCOUNT_LINK_ACTIVATION_CODE_RECEIVED, OnActivationCodeReceived)

    local function OnAccountLinkSuccessful()
        if LINK_ACCOUNT_ACTIVATION_SCENE:IsShowing() then
            PregameStateManager_AdvanceState()
        end
    end

    self.control:RegisterForEvent(EVENT_ACCOUNT_LINK_SUCCESSFUL, OnAccountLinkSuccessful)

    local function OnCreateLinkLoadingError(eventId, loginError, linkingError, debugInfo)
        if not LINK_ACCOUNT_ACTIVATION_SCENE:IsShowing() or linkingError == ACCOUNT_CREATE_LINK_ERROR_NO_ERROR then
            return
        end

        -- TODO Account Linking are there more errors we need to handle?

        local formattedErrorString
        if linkingError == ACCOUNT_CREATE_LINK_ERROR_EXTERNAL_REFERENCE_ALREADY_USED or linkingError == ACCOUNT_CREATE_LINK_ERROR_USER_ALREADY_LINKED then
            local serviceType = GetPlatformServiceType()
            local accountTypeName = GetString("SI_PLATFORMSERVICETYPE", serviceType)
            formattedErrorString = zo_strformat(SI_LINKACCOUNT_ALREADY_LINKED_ERROR_FORMAT, accountTypeName)
        else
            local linkErrorString = GetString("SI_ACCOUNTCREATELINKERROR", linkingError)
            formattedErrorString = zo_strformat(linkErrorString, GetURLTextByType(APPROVED_URL_ESO_HELP))
        end

        -- debugInfo will be empty in public, non-debug builds
        local message = formattedErrorString .. debugInfo
        self:ShowError(message)
    end

    self.control:RegisterForEvent(EVENT_CREATE_LINK_LOADING_ERROR, OnCreateLinkLoadingError)
end

function LinkAccount_Gamepad:InitializeControls()
    local contentsContainer = self.control:GetNamedChild("ContainerContent")
    self.textControl = contentsContainer:GetNamedChild("Text")
    self.codeLabel = contentsContainer:GetNamedChild("Code")

    local activationURL = ZO_SELECTED_TEXT:Colorize(GetURLTextByType(APPROVED_URL_ESO_ACCOUNT_LINKING))
    self.textControl:SetText(zo_strformat(SI_LINKACCOUNT_ACTIVATION_MESSAGE, activationURL))
end

function LinkAccount_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Copy Code
        {
            name = GetString(SI_LINKACCOUNT_ACTIVATION_COPY_CODE_KEYBIND),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                if self.activationCode then
                    CopyToClipboard(self.activationCode)
                end
            end,
            visible = function()
                return not IsConsoleUI()
            end,
        },
        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
            PregameStateManager_SetState("CreateLinkAccount")
            PlaySound(SOUNDS.NEGATIVE_CLICK)
        end)
    }
end

function LinkAccount_Gamepad:InitializeErrorDialog()
    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_LINK_ACCOUNT_ERROR_DIALOG_2", -- TODO Account Linking remove the _2
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },

        title =
        {
            text = SI_LINKACCOUNT_ERROR_HEADER,
        },

        mainText = 
        {
            text = function(dialog)
                return dialog.data.errorString
            end,
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

function LinkAccount_Gamepad:ShowError(message)
    local dialogData = { errorString = message}
    ZO_Dialogs_ShowGamepadDialog("GAMEPAD_LINK_ACCOUNT_ERROR_DIALOG_2", dialogData)
end

-- XML Handlers --

function ZO_LinkAccount_Activation_Gamepad_Initialize(self)
    LINK_ACCOUNT_GAMEPAD_2 = LinkAccount_Gamepad:New(self) -- TODO Account Linking remove the _2
end
