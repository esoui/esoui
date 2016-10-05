local WARNING_COLOR = ZO_ColorDef:New("DC8122")

local PARTNER_ICONS = 
{
    [PLATFORM_SERVICE_TYPE_DMM] = "EsoUI/Art/Login/link_Login_DMM.dds",
    [PLATFORM_SERVICE_TYPE_STEAM] = "EsoUI/Art/Login/link_Login_Steam.dds",
}

local function LinkAccountsDialogSetup(dialog, data)
    local partnerAccountName = GetControl(dialog, "PartnerAccount")
    local optionalTextLabel = GetControl(dialog, "OptionalText")
    local partnerIcon = GetControl(dialog, "PartnerIcon")
    local serviceType = GetPlatformServiceType()

    local iconPath = PARTNER_ICONS[serviceType]
    if iconPath then
        partnerIcon:SetTexture(iconPath)
    end

    if serviceType == PLATFORM_SERVICE_TYPE_DMM then
        optionalTextLabel:SetText(WARNING_COLOR:Colorize(GetString(SI_KEYBOARD_LINKACCOUNT_CROWN_LOSS_WARNING)))
        partnerAccountName:SetText(GetString(SI_KEYBOARD_LINKACCOUNT_GENERIC_ACCOUNT_NAME_DMM))
    else
        partnerAccountName:SetText(data.partnerAccount or "")
    end

    local accountTypeName = GetString("SI_PLATFORMSERVICETYPE", serviceType)
    if accountTypeName then
        local confirmWarning = GetControl(dialog, "LinkConfirm2")
        confirmWarning:SetText(zo_strformat(GetString(SI_KEYBOARD_LINKACCOUNT_CONFIRM_2_FORMAT), accountTypeName))
    end

    GetControl(dialog, "ESOAccount"):SetText(data.esoAccount or "")
end

function ZO_LinkAccountsDialog_Initialized(control)
    ZO_Dialogs_RegisterCustomDialog("LINK_ACCOUNT_KEYBOARD",
    {
        customControl = control,
        setup = LinkAccountsDialogSetup,
        canQueue = true,
        title = 
        {
            text = SI_KEYBOARD_LINKACCOUNT_DIALOG_HEADER,
        },
        buttons =
        {
            {
                control = GetControl(control, "Link"),
                text    = SI_DIALOG_ACCEPT,
                callback = function(dialog)
                        local data = dialog.data
                        LOGIN_MANAGER_KEYBOARD:AttemptAccountLink(data.esoAccount, data.password)
                    end,
            },

            {
                control = GetControl(control, "Cancel"),
                text    = SI_DIALOG_CANCEL,
            },
        }
    })
end