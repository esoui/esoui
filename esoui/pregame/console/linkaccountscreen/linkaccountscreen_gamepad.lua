local GAMEPAD_LINK_ACCOUNT_ERROR_DIALOG = "GAMEPAD_LINK_ACCOUNT_ERROR_DIALOG"

-- Main class.
local ZO_LinkAccount_Gamepad = ZO_Object:Subclass()

function ZO_LinkAccount_Gamepad:New(control)
    local object = ZO_Object.New(self)
    object:Initialize(control)
    return object
end

function ZO_LinkAccount_Gamepad:Initialize(control)
    self.control = control

    local linkAccount_Gamepad_Fragment = ZO_FadeSceneFragment:New(self.control)
    LINK_ACCOUNT_GAMEPAD_SCENE = ZO_Scene:New("LinkAccount_Gamepad", SCENE_MANAGER)
    LINK_ACCOUNT_GAMEPAD_SCENE:AddFragment(linkAccount_Gamepad_Fragment)

    LINK_ACCOUNT_GAMEPAD_SCENE:RegisterCallback("StateChange", function(oldState, newState)
                if newState == SCENE_SHOWING then
                    self:PerformDeferredInitialize()

                    self:ClearCredentials()
                    KEYBIND_STRIP:RemoveDefaultExit()
                    self:SwitchToMainList()

                elseif newState == SCENE_HIDDEN then
                    self:ResetScreen()
                    self:SwitchToKeybind(nil)
                    KEYBIND_STRIP:RestoreDefaultExit()
                end
            end)
end

function ZO_LinkAccount_Gamepad:ResetScreen()
    self.optionsControl:SetHidden(true)
    self.header:SetHidden(false)

    self.optionsList:Deactivate()
end

function ZO_LinkAccount_Gamepad:PerformDeferredInitialize()
    if self.initialized then return end
    self.initialized = true

    self.header = self.control:GetNamedChild("Container"):GetNamedChild("Header")

    self:SetupOptionsList()
    self:InitKeybindingDescriptors()

    self:InitializeErrorDialog()
end

do
    local g_lastErrorString = nil

    function ZO_LinkAccount_Gamepad:InitializeErrorDialog()
        ZO_Dialogs_RegisterCustomDialog(GAMEPAD_LINK_ACCOUNT_ERROR_DIALOG,
        {
            gamepadInfo = {
                dialogType = GAMEPAD_DIALOGS.BASIC,
            },

            mustChoose = true,

            title =
            {
                text = SI_LINKACCOUNT_ERROR_HEADER,
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

    function ZO_LinkAccount_Gamepad:ShowError(message)
        g_lastErrorString = message
        ZO_Dialogs_ShowGamepadDialog(GAMEPAD_LINK_ACCOUNT_ERROR_DIALOG)
    end
end

function ZO_LinkAccount_Gamepad:LinkAccountSelected()
   if (self.username == nil) or (self.username == "") then
        self:ShowError(GetString(SI_CONSOLE_LINKACCOUNT_NOUSERNAME))
    elseif (self.password == nil) or (self.password == "") then
        self:ShowError(GetString(SI_CONSOLE_LINKACCOUNT_NOPASSWORD))
    else
        PregameStateManager_AdvanceState()
    end
end

function ZO_LinkAccount_Gamepad:InitKeybindingDescriptors()
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
                PregameStateManager_SetState("CreateLinkAccount")
                PlaySound(SOUNDS.NEGATIVE_CLICK)
            end)
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.mainKeybindStripDescriptor, self.optionsList)


    self.errorKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() self:SwitchToMainList() end),
    }
end

function ZO_LinkAccount_Gamepad:SwitchToKeybind(keybindStripDescriptor)
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
    self.keybindStripDescriptor = keybindStripDescriptor
    if keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(keybindStripDescriptor)
    end
end

function ZO_LinkAccount_Gamepad:SwitchToMainList()
    self:ResetScreen()

    self:SwitchToKeybind(self.mainKeybindStripDescriptor)

    self.optionsList:Activate()
    self.optionsList:RefreshVisible()
    self.optionsControl:SetHidden(false)
end

function ZO_LinkAccount_Gamepad:AddTextEdit(text, textType, contents, selectedCallback, editedCallback)
    local option = ZO_GamepadEntryData:New() -- No text to populate - it uses a header instead.
    option:SetHeader(text)
    option.contents = contents
    option.textType = textType
    option.selectedCallback = selectedCallback
    option.contentsChangedCallback = editedCallback
    option:SetFontScaleOnSelection(true)
    self.optionsList:AddEntry("ZO_PregameGamepadTextEditTemplateWithHeader", option)
end

function ZO_LinkAccount_Gamepad:AddButton(text, callback)
    local option = ZO_GamepadEntryData:New(text)
    option.selectedCallback = callback
    option:SetFontScaleOnSelection(true)
    self.optionsList:AddEntry("ZO_PregameGamepadButtonWithTextTemplate", option)
end

function ZO_LinkAccount_Gamepad:ActivateEditbox(edit)
    edit:TakeFocus()
end

function ZO_LinkAccount_Gamepad:SetupOptionsList()
    self.username = ""
    self.password = ""
    -- TODO: HACK: Starting with a prefilled userId and password.
    self.username = HACK_DEFAULT_USERID
    self.password = HACK_DEFAULT_PASSWORD

    -- Setup the actual list.
    self.optionsControl = self.control:GetNamedChild("Container"):GetNamedChild("Options")
    self.optionsList = ZO_GamepadVerticalParametricScrollList:New(self.optionsControl:GetNamedChild("List"))

    self.optionsList:SetAlignToScreenCenter(true)

    self.optionsList:AddDataTemplateWithHeader("ZO_PregameGamepadTextEditTemplate", ZO_PregameGamepadTextEditTemplate_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_PregameGamepadTextEditHeaderTemplate")
    self.optionsList:AddDataTemplate("ZO_PregameGamepadButtonWithTextTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    -- Populate the list.
    self.optionsList:Clear()

    local function ActivateEditBox(control, data)
        self:ActivateEditbox(control.edit)
    end

    self:AddTextEdit(GetString(SI_ACCOUNT_NAME), nil, function(data) return self.username end, ActivateEditBox, function(newText) self.username = newText end)
    self:AddTextEdit(GetString(SI_PASSWORD), TEXT_TYPE_PASSWORD, function(data) return self.password end, ActivateEditBox, function(newText) self.password = newText end)
    self:AddButton(GetString(SI_LOGIN), function(control, data)
            PlaySound(SOUNDS.POSITIVE_CLICK)
            self:LinkAccountSelected()
        end)
    
    self.optionsList:Commit()
end

function ZO_LinkAccount_Gamepad:GetEnteredUserName()
    return self.username
end

function ZO_LinkAccount_Gamepad:GetEnteredPassword()
    return self.password
end

function ZO_LinkAccount_Gamepad:ClearCredentials()
    self.username = ""
    self.password = ""

    -- Jump back to the username edit box
    if self.optionsList ~= nil then
        self.optionsList:SetSelectedIndexWithoutAnimation(1, true, false)
    end
end

function ZO_LinkAccount_Gamepad:IsAccountValidForLinking(linkErrorCode)
    return (linkErrorCode ~= ACCOUNT_CREATE_LINK_ERROR_ACCOUNT_NOT_FOUND       and
            linkErrorCode ~= ACCOUNT_CREATE_LINK_ERROR_EXTERNAL_REFERENCE_ALREADY_USED and
            linkErrorCode ~= ACCOUNT_CREATE_LINK_ERROR_USER_ALREADY_LINKED and
            linkErrorCode ~= ACCOUNT_CREATE_LINK_ERROR_INVALID_CREDENTIALS     and
            linkErrorCode ~= ACCOUNT_CREATE_LINK_ERROR_ACCOUNT_DELETED         and
            linkErrorCode ~= ACCOUNT_CREATE_LINK_ERROR_ACCOUNT_BANNED)
end

function ZO_LinkAccount_Gamepad_Initialize(self)
    LINK_ACCOUNT_GAMEPAD = ZO_LinkAccount_Gamepad:New(self)
end
