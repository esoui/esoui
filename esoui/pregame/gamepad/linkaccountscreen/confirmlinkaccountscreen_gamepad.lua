local WARNING_COLOR = ZO_ColorDef:New("DC8122")

local ZO_ConfirmLinkAccount_Gamepad = ZO_InitializingObject:Subclass()

function ZO_ConfirmLinkAccount_Gamepad:Initialize(control)
    self.control = control

    local scrollChild = control:GetNamedChild("Container"):GetNamedChild("ScrollContainer"):GetNamedChild("ScrollChild")
    self.esoAccountNameLabel = scrollChild:GetNamedChild("ESOAccount")
    self.consoleAccountNameLabel = scrollChild:GetNamedChild("ConsoleAccount")
    self.consoleAccountIcon = scrollChild:GetNamedChild("ConsoleIcon")

    local confirmation2Label = scrollChild:GetNamedChild("Confirmation_2")

    local confirmation2Text
    local confirmation3Text
    local accountIcon

    local uiPlatform = GetUIPlatform()
    if uiPlatform == UI_PLATFORM_XBOX then
        confirmation2Text = GetString(SI_CONSOLE_LINKACCOUNT_CONFIRM_2_XBOX)
        confirmation3Text = GetString(SI_CONSOLE_LINKACCOUNT_CONFIRM_3_XBOX)
        accountIcon = "EsoUI/Art/Login/Gamepad/console_LoginLogo_XB.dds"
    elseif uiPlatform == UI_PLATFORM_PS4 or uiPlatform == UI_PLATFORM_PS4 then
        confirmation2Text = GetString(SI_CONSOLE_LINKACCOUNT_CONFIRM_2_PS4)
        confirmation3Text = GetString(SI_CONSOLE_LINKACCOUNT_CONFIRM_3_PS4)
        accountIcon = "EsoUI/Art/Login/Gamepad/console_LoginLogo_PS.dds"
    else
        local serviceType = GetPlatformServiceType()

        confirmation2Text = zo_strformat(GetString(SI_LINKACCOUNT_CONFIRM_2_FORMAT), GetString("SI_PLATFORMSERVICETYPE", serviceType))
        confirmation3Text = ""

        if serviceType == PLATFORM_SERVICE_TYPE_DMM then
            confirmation3Text = GetString(SI_KEYBOARD_LINKACCOUNT_CROWN_LOSS_WARNING)
        end

        local PLATFORM_SERVICE_ICONS =
        {
            [PLATFORM_SERVICE_TYPE_DMM] = "EsoUI/Art/Login/link_Login_DMM.dds",
            [PLATFORM_SERVICE_TYPE_STEAM] = "EsoUI/Art/Login/link_Login_Steam.dds",
            [PLATFORM_SERVICE_TYPE_EPIC] = "EsoUI/Art/Login/link_Login_Epic.dds",
        }
        accountIcon = PLATFORM_SERVICE_ICONS[serviceType]
    end

    confirmation2Label:SetText(confirmation2Text)

    self:InitKeybindingDescriptor()

    self.consoleAccountIcon:SetTexture(accountIcon)

    local confirmLinkAccountScreen_Gamepad_Fragment = ZO_FadeSceneFragment:New(control)
    CONFIRM_LINK_ACCOUNT_SCREEN_GAMEPAD_SCENE = ZO_Scene:New("ConfirmLinkAccountScreen_Gamepad", SCENE_MANAGER)
    CONFIRM_LINK_ACCOUNT_SCREEN_GAMEPAD_SCENE:AddFragment(confirmLinkAccountScreen_Gamepad_Fragment)

    local function OnStateChanged(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

            if confirmation3Text ~= "" then
                GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_QUAD_2_3_TOOLTIP, WARNING_COLOR:Colorize(confirmation3Text))
            end
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()

            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD_2_3_TOOLTIP)
        end
    end

    CONFIRM_LINK_ACCOUNT_SCREEN_GAMEPAD_SCENE:RegisterCallback("StateChange", OnStateChanged)
end

function ZO_ConfirmLinkAccount_Gamepad:InitKeybindingDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            name = GetString(SI_DIALOG_NO),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                    PlaySound(SOUNDS.NEGATIVE_CLICK)
                    PregameStateManager_SetState("LinkAccount")
                end,
        },

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
    local accountName
    if IsConsoleUI() then
        accountName = GetOnlineIdForActiveProfile()
    elseif GetPlatformServiceType() == PLATFORM_SERVICE_TYPE_DMM then
        accountName = GetString(SI_KEYBOARD_LINKACCOUNT_GENERIC_ACCOUNT_NAME_DMM)
    else
        accountName = GetExternalName()
    end
    self.consoleAccountNameLabel:SetText(accountName)
    SCENE_MANAGER:Show("ConfirmLinkAccountScreen_Gamepad")
end

function ConfirmLinkAccountScreen_Gamepad_Initialize(self)
    CONFIRM_LINK_ACCOUNT_SCREEN_GAMEPAD = ZO_ConfirmLinkAccount_Gamepad:New(self)
end
