-- Configuration options
local PS4_ACCOUNT_ICON = "EsoUI/Art/Login/Gamepad/console_LoginLogo_PS.dds"
local XBOX_ACCOUNT_ICON = "EsoUI/Art/Login/Gamepad/console_LoginLogo_XB.dds"

-- The main class.
local ZO_ConfirmLinkAccount_Gamepad = ZO_Object:Subclass()

function ZO_ConfirmLinkAccount_Gamepad:New(control)
    local object = ZO_Object.New(self)
    object:Initialize(control)
    return object
end

function ZO_ConfirmLinkAccount_Gamepad:Initialize(control)
    self.control = control

    local scrollChild = self.control:GetNamedChild("Container"):GetNamedChild("ScrollContainer"):GetNamedChild("ScrollChild")
    local confirmation2 = scrollChild:GetNamedChild("Confirmation_2")
    local confirmation3 = scrollChild:GetNamedChild("Confirmation_3")
    local isXbox = GetUIPlatform() == UI_PLATFORM_XBOX
    confirmation2:SetText(GetString(isXbox and SI_CONSOLE_LINKACCOUNT_CONFIRM_2_XBOX or SI_CONSOLE_LINKACCOUNT_CONFIRM_2_PS4))
    confirmation3:SetText(GetString(isXbox and SI_CONSOLE_LINKACCOUNT_CONFIRM_3_XBOX or SI_CONSOLE_LINKACCOUNT_CONFIRM_3_PS4))

    self:InitKeybindingDescriptor()

    local scrollChild = control:GetNamedChild("Container"):GetNamedChild("ScrollContainer"):GetNamedChild("ScrollChild")
    self.esoAccountNameLabel = scrollChild:GetNamedChild("ESOAccount")
    self.consoleAccountNameLabel = scrollChild:GetNamedChild("ConsoleAccount")
    self.consoleAccountIcon = scrollChild:GetNamedChild("ConsoleIcon")

    if(isXbox) then
        self.consoleAccountIcon:SetTexture(XBOX_ACCOUNT_ICON)
    else
        self.consoleAccountIcon:SetTexture(PS4_ACCOUNT_ICON)
    end

    local confirmLinkAccountScreen_Gamepad_Fragment = ZO_FadeSceneFragment:New(control)
    CONFIRM_LINK_ACCOUNT_SCREEN_GAMEPAD_SCENE = ZO_Scene:New("ConfirmLinkAccountScreen_Gamepad", SCENE_MANAGER)
    CONFIRM_LINK_ACCOUNT_SCREEN_GAMEPAD_SCENE:AddFragment(confirmLinkAccountScreen_Gamepad_Fragment)

    local StateChanged = function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end

    CONFIRM_LINK_ACCOUNT_SCREEN_GAMEPAD_SCENE:RegisterCallback("StateChange", StateChanged)
end

function ZO_ConfirmLinkAccount_Gamepad:InitKeybindingDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        
        -- No
        {
            name = GetString(SI_DIALOG_NO),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                    PlaySound(SOUNDS.NEGATIVE_CLICK)
                    PregameStateManager_SetState("LinkAccount")
                end,
        },

        -- Yes
        {
            name = GetString(SI_DIALOG_YES),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                    PlaySound(SOUNDS.POSITIVE_CLICK)
                    PregameStateManager_AdvanceState()
                end,
        },
    }
end

function ZO_ConfirmLinkAccount_Gamepad:GetUsernamePassword()
    return self.username, self.password
end

function ZO_ConfirmLinkAccount_Gamepad:Show(username, password)
    self.username = username
    self.password = password
    self.esoAccountNameLabel:SetText(username)
    self.consoleAccountNameLabel:SetText(GetOnlineIdForActiveProfile())
    SCENE_MANAGER:Show("ConfirmLinkAccountScreen_Gamepad")
end

function ConfirmLinkAccountScreen_Gamepad_Initialize(self)
    CONFIRM_LINK_ACCOUNT_SCREEN_GAMEPAD = ZO_ConfirmLinkAccount_Gamepad:New(self)
end
