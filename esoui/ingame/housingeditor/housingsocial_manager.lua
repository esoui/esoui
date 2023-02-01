ZO_HOUSING_LINK_JUMP_CONFIRMATION_DIALOG_NAME = "VISIT_HOUSE_LINK_CONFIRMATION_DIALOG"

local ZO_HousingSocial_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_HousingSocial_Manager:Initialize()
    self:InitializeDialogs()
    self:InitializeLinkHandlers()
end

function ZO_HousingSocial_Manager:InitializeDialogs()
    do
        local function ReleaseDialog()
            ZO_Dialogs_ReleaseDialogOnButtonPress(ZO_HOUSING_LINK_JUMP_CONFIRMATION_DIALOG_NAME)
        end

        ZO_Dialogs_RegisterCustomDialog(ZO_HOUSING_LINK_JUMP_CONFIRMATION_DIALOG_NAME,
        {
            blockDialogReleaseOnPress = true,

            canQueue = true,

            gamepadInfo = {
                dialogType = GAMEPAD_DIALOGS.BASIC,
                allowRightStickPassThrough = false,
            },

            setup = function(dialog)
                self.acceptConfirmText = nil
                dialog:setupFunc()
            end,

            title =
            {
                text = SI_HOUSING_CONFIRM_JUMP_CAPTION,
            },

            mainText = 
            {
                text = function(dialog)
                    if dialog.data.accountName then
                        return GetString(SI_HOUSING_CONFIRM_JUMP_TO_PLAYER_HOUSE)
                    else
                        return GetString(SI_HOUSING_CONFIRM_JUMP_TO_HOUSE)
                    end
                end,
            },

            buttons =
            {
                {
                    keybind = "DIALOG_PRIMARY",
                    text = SI_DIALOG_CONFIRM,

                    callback = function(dialog)
                        self:OnConfirmedVisitHouseLinkDialog(dialog.data)
                        ReleaseDialog()
                    end,
                },

                {
                    keybind = "DIALOG_NEGATIVE",
                    text = SI_DIALOG_CANCEL,

                    callback = function()
                        ReleaseDialog()
                    end,
                },
            }
        })
    end
end

function ZO_HousingSocial_Manager:InitializeLinkHandlers()
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, self.OnLinkClicked, self)
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, self.OnLinkClicked, self)
end

function ZO_HousingSocial_Manager:GetHouseName(houseId)
    houseId = zo_parseUnsignedInteger(houseId)
    if not houseId then
        -- Invalid houseId.
        return ""
    end

    local collectibleId = GetCollectibleIdForHouse(houseId)
    if not collectibleId then
        -- Invalid houseId.
        return ""
    end

    local houseName = GetCollectibleName(collectibleId)
    return houseName
end

function ZO_HousingSocial_Manager:VisitHouse(houseId, accountName)
    houseId = zo_parseUnsignedInteger(houseId)
    if not houseId then
        -- Invalid houseId.
        return false
    end

    local accountNameLower = accountName and string.lower(accountName) or nil
    if not accountNameLower or accountNameLower == "" or accountNameLower == string.lower(GetDisplayName()) then
        -- This house is owned by the local player.
        RequestJumpToHouse(houseId)
    else
        -- This house is owned by a remote player.
        JumpToSpecificHouse(accountName, houseId)
    end

    SCENE_MANAGER:ShowBaseScene()
    return true
end

function ZO_HousingSocial_Manager:OnLinkClicked(link, button, text, color, linkType, ...)
    if linkType == HOUSING_LINK_TYPE then
        return self:OnHouseLinkClicked(link, ...)
    end

    return false
end

function ZO_HousingSocial_Manager:OnHouseLinkClicked(link, houseId, accountName)
    self:ShowVisitHouseLinkConfirmationDialog(houseId, accountName)
    return true
end

function ZO_HousingSocial_Manager:ShowVisitHouseLinkConfirmationDialog(houseId, optionalAccountName)
    houseId = zo_parseUnsignedInteger(houseId)
    if not houseId then
        -- Invalid houseId.
        return
    end

    if not IsInGamepadPreferredMode() then
        -- Hide a preexisting tooltip that may occlude this confirmation dialog.
        ClearTooltip(InformationTooltip)
    end

    local accountName = (optionalAccountName and optionalAccountName ~= "") and optionalAccountName or nil
    local houseName = GetCollectibleName(GetCollectibleIdForHouse(houseId))

    local dialogData =
    {
        accountName = accountName,
        houseId = houseId,
    }

    local dialogParams =
    {
        mainTextParams =
        {
            accountName or houseName
        },
    }

    ZO_Dialogs_ShowPlatformDialog(ZO_HOUSING_LINK_JUMP_CONFIRMATION_DIALOG_NAME, dialogData, dialogParams)
end

function ZO_HousingSocial_Manager:OnConfirmedVisitHouseLinkDialog(dialogData)
    self:VisitHouse(dialogData.houseId, dialogData.accountName)
end

HOUSING_SOCIAL_MANAGER = ZO_HousingSocial_Manager:New()