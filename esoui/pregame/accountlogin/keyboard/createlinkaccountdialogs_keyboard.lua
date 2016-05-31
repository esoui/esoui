local PARTNER_ICON_DMM = "EsoUI/Art/Login/link_Login_DMM.dds"
local WARNING_COLOR = ZO_ColorDef:New("DC8122")

local function LinkAccountsDialogSetup(dialog, data)
    GetControl(dialog, "PartnerAccount"):SetText(data.partnerAccount or "")
    GetControl(dialog, "ESOAccount"):SetText(data.esoAccount or "")

    local optionalTextLabel = GetControl(dialog, "OptionalText")
    local partnerIcon = GetControl(dialog, "PartnerIcon")
    local serviceType = GetPlatformServiceType()
        
    if serviceType == PLATFORM_SERVICE_TYPE_DMM then
        optionalTextLabel:SetText(WARNING_COLOR:Colorize(GetString(SI_KEYBOARD_LINKACCOUNT_CROWN_LOSS_WARNING)))
        partnerIcon:SetTexture(PARTNER_ICON_DMM)
    end
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