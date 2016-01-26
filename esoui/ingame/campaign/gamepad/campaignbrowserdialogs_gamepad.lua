ZO_GAMEPAD_CAMPAIGN_SELECT_DIALOG = "GAMEPAD_CAMPAIGN_SELECT_DIALOG"
ZO_GAMEPAD_CAMPAIGN_QUEUE_READY_DIALOG = "CAMPAIGN_QUEUE_READY"
ZO_GAMEPAD_CAMPAIGN_QUEUE_DIALOG = "GAMEPAD_CAMPAIGN_QUEUE_DIALOG"
ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG = "GAMEPAD_CAMPAIGN_LOCKED_DIALOG"
ZO_GAMEPAD_CAMPAIGN_GUEST_WARNING_DIALOG = "GAMEPAD_CAMPAIGN_GUEST_WARNING_DIALOG"
ZO_GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG = "GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG"
ZO_GAMEPAD_CAMPAIGN_SET_HOME_CONFIRM_DIALOG = "GAMEPAD_CAMPAIGN_SET_HOME_CONFIRM_DIALOG"

---------------------
-- Select Campaign --
---------------------

local function InitializeCampaignSelectDialog(screen)
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_SELECT_DIALOG,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC
        },

        parametricListOnSelectionChangedCallback = function()
            KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
        end,

        setup = function()
            local nowCost, endCost = ZO_SelectHomeCampaign_GetCost()
            screen.nowCost = nowCost
            screen.endCost = endCost
            screen.isFree = screen.nowCost == 0
            screen.numAlliancePoints = GetAlliancePoints()
            screen.hasEnough = screen.nowCost <= screen.numAlliancePoints

            dialog.setupFunc(dialog)
        end,

        title =
        {
            text = SI_GAMEPAD_CAMPAIGN_BROWSER_CHOOSE_HOME_OR_GUEST_CAMPAIGN,
        },

        parametricList =
        {
            {
                template = "ZO_CampaignBrowserDialogsGamepadMenuEntry",
                text = GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN),
                icon = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_home.dds",
                templateData = {
                    isHome = true,
                    subLabels = {
                        "",
                        function(control)
                            if screen.isFree then
                                return ""
                            else
                                return GAMEPAD_AVA_BROWSER:GetPriceMessage(screen.nowCost, screen.hasEnough)
                            end
                        end
                    },
                    setup = ZO_SharedGamepadEntry_OnSetup,
                },
            },
            {
                template = "ZO_CampaignBrowserDialogsGamepadMenuEntry",
                text = GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_CHOOSE_GUEST_CAMPAIGN),
                icon = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_guest.dds",
                templateData = {
                    isHome = false,
                    setup = ZO_SharedGamepadEntry_OnSetup,
                },
            },
        },
       
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function()
                    local targetData = dialog.entryList:GetTargetData()
                    local selectedCampaign = screen:GetTargetData()
                    if(selectedCampaign.id) then
                        if(targetData.isHome) then -- assign home
                            local lockTimeLeft = GetCampaignReassignCooldown()
                            if(lockTimeLeft > 0)  then
                                ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG, { isHome = targetData.isHome } )
                            else
                                ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG, { id = selectedCampaign.id }, { mainTextParams = GAMEPAD_AVA_BROWSER:GetTextParamsForSetHomeDialog() })
                            end
                        else -- assign guest
                            local lockTimeLeft = GetCampaignGuestCooldown()
                            if(lockTimeLeft > 0) then
                                ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG, { isHome = targetData.isHome } )
                            else
                                ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_GUEST_WARNING_DIALOG, { id = selectedCampaign.id, name = selectedCampaign.name })                                
                            end
                        end
                    end
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },

        }
    })
end

--------------------
-- Queue Campaign --
--------------------

local function InitializeCampaignQueueDialog()
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_QUEUE_DIALOG,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC
        },

        setup = function()
            dialog.setupFunc(dialog)
        end,

        title =
        {
            text = SI_CAMPAIGN_BROWSER_QUEUE_DIALOG_TITLE,
        },

        mainText = 
        {
            text = SI_CAMPAIGN_BROSWER_QUEUE_DIALOG_PROMPT,
        },

        parametricList =
        {
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = {
                    isHome = true,
                    text = GetString(SI_CAMPAIGN_BROWSER_QUEUE_GROUP),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function() 
                        local IS_GROUP = true
                        QueueForCampaign(dialog.data.id, IS_GROUP)
                    end,
                },
            },
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = {
                    isHome = false,
                    text = GetString(SI_CAMPAIGN_BROWSER_QUEUE_SOLO),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function() 
                        local IS_GROUP = false
                        QueueForCampaign(dialog.data.id, IS_GROUP)
                    end,
                },
            },
        },
       
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function()
                    local targetData = dialog.entryList:GetTargetData()
                    if(targetData and targetData.callback) then
                        targetData.callback()
                    end
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },

        }
    })
end

---------------------
-- Locked Campaign --
---------------------

local function InitializeCampaignLockedDialog()
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.BASIC)

    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG,
    {
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        updateFn = function()
            ZO_Dialogs_RefreshDialogText(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG, dialog)
        end,
        title =
        {
            text = SI_GAMEPAD_CAMPAIGN_LOCKED_DIALOG_TITLE,
        },
        mainText = 
        {
            text = function() 
                if(dialog.data.isHome) then
                    local timeLeft = GetCampaignReassignCooldown()
                    local timeleftStr = ZO_FormatTime(timeLeft, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING)
                    return zo_strformat(SI_SELECT_HOME_CAMPAIGN_LOCKED_MESSAGE, timeleftStr)
                else
                    local timeLeft = GetCampaignGuestCooldown()
                    local timeleftStr = ZO_FormatTime(timeLeft, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING)
                    return zo_strformat(SI_SELECT_GUEST_CAMPAIGN_LOCKED_MESSAGE, timeleftStr)
                end
            end,
        },
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        },
    })
end

-------------------
-- Guest Warning --
-------------------
local BULLET_ICON = "EsoUI/Art/Miscellaneous/Gamepad/gp_bullet.dds"
local BULLET_ICON_SIZE = 32

local function InitializeCampaignGuestWarningDialog()
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.STATIC_LIST)
    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_GUEST_WARNING_DIALOG,
    {
        canQueue = true,

        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.STATIC_LIST,
        },
        
        setup = function()
            dialog.setupFunc(dialog)
        end,

        title =
        {
            text = SI_GAMEPAD_CAMPAIGN_BROWSER_CONFIRM_GUEST_CAMPAIGN_TITLE,
        },

        mainText = 
        {
            text = SI_SELECT_CAMPAIGN_COOLDOWN_WARNING,
        },

        itemInfo =
        {
            {
                icon = BULLET_ICON,
                iconSize = BULLET_ICON_SIZE,
                label = GetString(SI_SELECT_GUEST_CAMPAIGN_BULLET1),
            },

            {
                icon = BULLET_ICON,
                iconSize = BULLET_ICON_SIZE,
                label = GetString(SI_SELECT_GUEST_CAMPAIGN_BULLET2),
            },

            {
                icon = BULLET_ICON,
                iconSize = BULLET_ICON_SIZE,
                label = GetString(SI_SELECT_GUEST_CAMPAIGN_BULLET3),
            },
        },

        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_ACCEPT,
                callback =  function(callbackDialog)
                    AssignCampaignToPlayer(callbackDialog.data.id, CAMPAIGN_REASSIGN_TYPE_GUEST)
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        },
    })
end

----------------------
-- Set Home Review --
----------------------

local function InitializeCampaignSetHomeReviewDialog(screen)
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.BASIC)

    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.BASIC
        },

        canQueue = true,

        setup = function()
            dialog.setupFunc(dialog)
        end,

        title =
        {
            text = SI_GAMEPAD_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN_DIALOG_TITLE,
        },

        mainText = 
        {
            text = SI_GAMEPAD_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN_MESSAGE,
        },

        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_ACCEPT,
                callback = function()
                    ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_SET_HOME_CONFIRM_DIALOG, { id = dialog.data.id } )
                end,
                clickSound = SOUNDS.DIALOG_ACCEPT,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },

        }
    })
end

----------------------
-- Set Home Confirm --
----------------------

local function InitializeCampaignSetHomeConfirmDialog(screen)
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
    
    
    local function CanChange()
        local targetData = dialog.entryList:GetTargetData()

        if(targetData.isNow) then
            return screen.nowCost <= screen.numAlliancePoints
        else
            return screen.endCost <= screen.numAlliancePoints
        end
    end

    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_SET_HOME_CONFIRM_DIALOG,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC
        },

        canQueue = true,

        setup = function()
            local nowCost, endCost = ZO_SelectHomeCampaign_GetCost()
            screen.nowCost = nowCost
            screen.endCost = endCost
            screen.isFree = screen.nowCost == 0
            screen.numAlliancePoints = GetAlliancePoints()
            screen.hasEnough = screen.nowCost <= screen.numAlliancePoints

            dialog.setupFunc(dialog)
        end,

        title =
        {
            text = SI_GAMEPAD_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN_DIALOG_TITLE,
        },

        mainText = 
        {
            text = SI_SELECT_CAMPAIGN_COOLDOWN_WARNING,
        },

        parametricList =
        {
            {
                template = "ZO_CampaignBrowserDialogsGamepadMenuEntryNoIcon",
                text = GetString(SI_GAMEPAD_CAMPAIGN_SELECT_HOME_NOW),
                templateData = {
                    isNow = true,               
                    subLabels = {
                        "",
                        function(control)
                            if screen.isFree then
                                return ""
                            else
                                return GAMEPAD_AVA_BROWSER:GetPriceMessage(screen.nowCost, screen.hasEnough)
                            end
                        end
                    },
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function()
                        AssignCampaignToPlayer(dialog.data.id, CAMPAIGN_REASSIGN_TYPE_IMMEDIATE)
                    end,
                },
            },
            {
                template = "ZO_CampaignBrowserDialogsGamepadMenuEntryNoIcon",
                text = GetString(SI_GAMEPAD_CAMPAIGN_SELECT_HOME_ON_END),
                templateData = {
                    subLabels = {
                        GetString(SI_GAMEPAD_CAMPAIGN_SELECT_HOME_ON_END_INFO),
                        function(control)
                            local hasEnough = screen.numAlliancePoints >= screen.endCost
                            return GAMEPAD_AVA_BROWSER:GetPriceMessage(screen.nowCost, hasEnough)
                        end
                    },
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function()
                        AssignCampaignToPlayer(dialog.data.id, CAMPAIGN_REASSIGN_TYPE_ON_END)
                    end,
                    visible = function()
                        return GetAssignedCampaignId() ~= 0
                    end,
                },
            },
        },

        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                visible = function()
                    return CanChange()
                end,
                callback = function()
                    local targetData = dialog.entryList:GetTargetData()
                    if(targetData and targetData.callback) then
                        targetData.callback()
                    end
                end,
                clickSound = SOUNDS.DIALOG_ACCEPT,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },

        }
    })
end

----------
-- Init --
----------

function ZO_CampaignDialogGamepad_Initialize(screen)
    InitializeCampaignSelectDialog(screen)
    InitializeCampaignQueueDialog()
    InitializeCampaignLockedDialog()
    InitializeCampaignGuestWarningDialog()
    InitializeCampaignSetHomeReviewDialog(screen)
    InitializeCampaignSetHomeConfirmDialog(screen)
end
