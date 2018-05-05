local NA_STRING = "Live"
local EU_STRING = "Live-EU"

function ZO_GetLocalizedServerName(serverName)
    if(serverName == NA_STRING) then
        serverName = GetString("SI_MEGASERVER", MEGASERVER_NA)
    elseif (serverName == EU_STRING) then
        serverName = GetString("SI_MEGASERVER", MEGASERVER_EU)
    end
    
    return serverName
end

local function InitServerOptions(dialogControl)
    dialogControl.radioButtonGroup = ZO_RadioButtonGroup:New()
    local radioButtonGroupControl = dialogControl:GetNamedChild("RadioButtonContainer")

    local numPlatforms = GetNumPlatforms()

    local prev = nil
    for i = 0, numPlatforms do
        local platformName = GetPlatformInfo(i)
        if(platformName ~= "") then
            local serverRadioButton = CreateControlFromVirtual("ServerOption", radioButtonGroupControl, "ZO_ServerSelectRadioButton", i)

            dialogControl.radioButtonGroup:Add(serverRadioButton)

            local label = GetControl(serverRadioButton, "Label")
            local serverName = ZO_GetLocalizedServerName(platformName)
            label:SetText(serverName)
            serverRadioButton.data = {server = platformName, index = i}

            if(prev == nil) then
                serverRadioButton:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
            else
                serverRadioButton:SetAnchor(TOPLEFT, prev, BOTTOMLEFT, 0, 10)
            end

            prev = serverRadioButton
        end
    end
end

local function SetupDialog(dialog, data)
    if data.isIntro then
        dialog.radioButtonGroup:UpdateFromData(function(button) return false end)
    else
        local currentServer = GetCVar("LastPlatform")
        dialog.radioButtonGroup:UpdateFromData(function(button) return button.data.server == currentServer end)
    end
end

local function ServerSelectDialogInitialize(dialogControl)
    InitServerOptions(dialogControl)

    ZO_Dialogs_RegisterCustomDialog("SERVER_SELECT_DIALOG",
    {
        customControl = dialogControl,
        mustChoose = true,
        setup = SetupDialog,
        title =
        {
            text = SI_SERVER_SELECT_TITLE,
        },
        mainText =
        {
            text = SI_SERVER_SELECT_CHARACTER_WARNING,
        },
        buttons =
        {
            [1] =
            {
                control = GetControl(dialogControl, "Button1"),
                text = SI_DIALOG_ACCEPT,
                callback = function(dialog)
                               local buttonData = ZO_Dialogs_GetSelectedRadioButtonData(dialog)
                               if GetCVar("LastPlatform") ~= buttonData.server then
                                   SetCVar("LastPlatform", buttonData.server)
                                   SetSelectedPlatform(buttonData.index)
                                   RequestAnnouncements()
                                   -- If we're using linked login, it's possible to be on the Create/Link fragment,
                                   -- which means we have a session with a different login endpoint and the next Create/Link will fail.
                                   -- Make sure we're at the login fragment so we have to login again to get a new session.
                                   LOGIN_MANAGER_KEYBOARD:SwitchToLoginFragment()
                               end
                           end,
            },
        },
        updateFn = function(dialog)
                       local server = ZO_Dialogs_GetSelectedRadioButtonData(dialog)
                       local acceptState = server and BSTATE_NORMAL or BSTATE_DISABLED
                       ZO_Dialogs_UpdateButtonState(dialog, 1, acceptState)
                   end,
        finishedCallback = function(dialog)
                               if dialog.data.onClosed then
                                   dialog.data.onClosed()
                               end
                               if dialog.data.isIntro then
                                   SetCVar("IsServerSelected", "true")
                                   PregameStateManager_AdvanceState()
                               end
                           end,
    })
end

function ZO_ServerSelect_Initialize(control)
    ServerSelectDialogInitialize(control)
end