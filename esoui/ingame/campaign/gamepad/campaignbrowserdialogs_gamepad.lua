ZO_GAMEPAD_CAMPAIGN_SELECT_DIALOG = "GAMEPAD_CAMPAIGN_SELECT_DIALOG"
ZO_GAMEPAD_CAMPAIGN_QUEUE_DIALOG = "GAMEPAD_CAMPAIGN_QUEUE_DIALOG"
ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG = "GAMEPAD_CAMPAIGN_LOCKED_DIALOG"
ZO_GAMEPAD_CAMPAIGN_GUEST_WARNING_DIALOG = "GAMEPAD_CAMPAIGN_GUEST_WARNING_DIALOG"
ZO_GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG = "GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG"
ZO_GAMEPAD_CAMPAIGN_SET_HOME_CONFIRM_DIALOG = "GAMEPAD_CAMPAIGN_SET_HOME_CONFIRM_DIALOG"
ZO_GAMEPAD_CAMPAIGN_ABANDON_GUEST_DIALOG = "GAMEPAD_CAMPAIGN_ABANDON_GUEST_DIALOG"
ZO_GAMEPAD_CAMPAIGN_ABANDON_HOME_CONFIRM_DIALOG = "GAMEPAD_CAMPAIGN_ABANDON_HOME_CONFIRM_DIALOG"


---------------------
-- Select Campaign --
---------------------

local function InitializeCampaignSelectDialog(screen)
    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_SELECT_DIALOG,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC
        },

        parametricListOnSelectionChangedCallback = function()
            KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
        end,

        setup = function(dialog)
            local nowCost, endCost = ZO_SelectHomeCampaign_GetCost()
            screen.nowCost = nowCost
            screen.endCost = endCost
            screen.isFree = screen.nowCost == 0
            screen.numAlliancePoints = GetAlliancePoints()
            screen.hasEnough = screen.nowCost <= screen.numAlliancePoints

            dialog:setupFunc()
        end,

        title =
        {
            text = SI_GAMEPAD_CAMPAIGN_BROWSER_CHOOSE_HOME_OR_GUEST_CAMPAIGN,
        },

        parametricList =
        {
            {
                template = "ZO_GamepadMenuEntryTemplate",
                text = GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN),
                icon = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_home.dds",
                templateData = {
                    showUnselectedSublabels = true,
                    isHome = true,
                    subLabels = {
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
                template = "ZO_GamepadMenuEntryTemplate",
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
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local selectedCampaign = screen:GetTargetData()
                    if(selectedCampaign.id) then
                        if(targetData.isHome) then -- assign home
                            local lockTimeLeft = GetCampaignReassignCooldown()
                            if(lockTimeLeft > 0)  then
                                ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG, { isHome = targetData.isHome, id = selectedCampaign.id } )
                            else
                                ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG, { id = selectedCampaign.id }, { mainTextParams = GAMEPAD_AVA_BROWSER:GetTextParamsForSetHomeDialog() })
                            end
                        else -- assign guest
                            local lockTimeLeft = GetCampaignGuestCooldown()
                            if(lockTimeLeft > 0) then
                                ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG, { isHome = targetData.isHome, id = selectedCampaign.id} )
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
    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_QUEUE_DIALOG,
    {
        canQueue = true,

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC
        },

        setup = function(dialog)
            dialog:setupFunc()
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
                    callback = function(dialog)
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
                    callback = function(dialog)
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
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData and targetData.callback then
                        targetData.callback(dialog)
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

local function InitializeCampaignLockedDialog(screen)
    local basicDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.BASIC)
    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG,
    {
        canQueue = true,

        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        updateFn = function(dialog)
            ZO_Dialogs_RefreshDialogText(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG, basicDialog)

            --If the displayed cooldown reaches 0, automatically forward user to the now unlocked dialog they were trying to navigate to originally
            if dialog.data.isHome then
                if dialog.data.isAbandoning then
                    local timeLeft = GetCampaignUnassignCooldown()
                    if timeLeft <= 0 then
                        ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_ABANDON_HOME_CONFIRM_DIALOG, { id = dialog.data.id }, { mainTextParams = screen:GetTextParamsForAbandonHomeDialog() })
                        ZO_Dialogs_ReleaseDialog("GAMEPAD_CAMPAIGN_LOCKED_DIALOG")
                    end
                else
                    local timeLeft = GetCampaignReassignCooldown()
                    if timeLeft <= 0 then
                        ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG, { id = dialog.data.id }, { mainTextParams = screen:GetTextParamsForSetHomeDialog() })
                        ZO_Dialogs_ReleaseDialog("GAMEPAD_CAMPAIGN_LOCKED_DIALOG")
                    end
                end
            else
                local timeLeft = GetCampaignGuestCooldown()
                if timeLeft <= 0 then
                    if dialog.data.isAbandoning then
                        ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_ABANDON_GUEST_DIALOG)
                        ZO_Dialogs_ReleaseDialog("GAMEPAD_CAMPAIGN_LOCKED_DIALOG")
                    else
                        local selectedCampaign = screen:GetTargetData()
                        ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_GUEST_WARNING_DIALOG, { id = selectedCampaign.id, name = selectedCampaign.name })
                        ZO_Dialogs_ReleaseDialog("GAMEPAD_CAMPAIGN_LOCKED_DIALOG")
                    end
                end
            end
        end,
        title =
        {
            text = SI_GAMEPAD_CAMPAIGN_LOCKED_DIALOG_TITLE,
        },
        mainText =
        {
            text = function(dialog)
                if dialog.data.isHome then
                    local timeLeft = dialog.data.isAbandoning and GetCampaignUnassignCooldown() or GetCampaignReassignCooldown()
                    local timeleftStr = ZO_FormatTime(timeLeft, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING)
                    if (dialog.data.isAbandoning) then
                        return zo_strformat(SI_ABANDON_HOME_CAMPAIGN_LOCKED_MESSAGE, timeleftStr)
                    else
                        return zo_strformat(SI_SELECT_HOME_CAMPAIGN_LOCKED_MESSAGE, timeleftStr)
                    end
                else
                    local timeLeft = GetCampaignGuestCooldown()
                    local timeleftStr = ZO_FormatTime(timeLeft, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING)
                    if (dialog.data.isAbandoning) then
                        return zo_strformat(SI_ABANDON_GUEST_CAMPAIGN_LOCKED_MESSAGE, timeleftStr)
                    else
                        return zo_strformat(SI_SELECT_GUEST_CAMPAIGN_LOCKED_MESSAGE, timeleftStr)
                    end
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
    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_GUEST_WARNING_DIALOG,
    {
        canQueue = true,
        onlyQueueOnce = true,

        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.STATIC_LIST,
        },
        
        setup = function(dialog)
            dialog:setupFunc()
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
-- Abandon Guest --
----------------------
local function InitializeCampaignAbandonGuestDialog()
    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_ABANDON_GUEST_DIALOG,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.BASIC
        },

        canQueue = true,
        onlyQueueOnce = true,

        setup = function(dialog)
            dialog:setupFunc()
        end,

        title =
        {
            text = SI_CAMPAIGN_BROWSER_ABANDON_CAMPAIGN,
        },

        mainText = 
        {
            text = function()
                local guestCampaignId = GetGuestCampaignId()
                return zo_strformat(GetString(SI_ABANDON_GUEST_CAMPAIGN_QUERY), GetCampaignName(guestCampaignId))
            end,
        },

        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_ACCEPT,
                callback = function()
                    UnassignCampaignForPlayer(CAMPAIGN_UNASSIGN_TYPE_GUEST)
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
-- Set Home Review --
----------------------

local function InitializeCampaignSetHomeReviewDialog(screen)
    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.BASIC
        },

        canQueue = true,
        onlyQueueOnce = true,

        setup = function(dialog)
            dialog:setupFunc()
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
                callback = function(dialog)
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
    local function CanChange(dialog)
        local targetData = dialog.entryList:GetTargetData()

        if targetData.isNow then
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

        setup = function(dialog)
            local nowCost, endCost = ZO_SelectHomeCampaign_GetCost()
            screen.nowCost = nowCost
            screen.endCost = endCost
            screen.isFree = screen.nowCost == 0
            screen.numAlliancePoints = GetAlliancePoints()
            screen.hasEnoughNow = screen.nowCost <= screen.numAlliancePoints
            screen.hasEnoughEnd = screen.endCost <= screen.numAlliancePoints

            dialog:setupFunc()
        end,

        title =
        {
            text = SI_GAMEPAD_CAMPAIGN_BROWSER_CONFIRM_HOME_CAMPAIGN_DIALOG_TITLE,
        },

        parametricList =
        {
            {
                template = "ZO_CampaignBrowserDialogsGamepadMenuEntryNoIcon",
                text = GetString(SI_GAMEPAD_CAMPAIGN_SELECT_HOME_NOW),
                templateData = {
                    isNow = true,
                    showUnselectedSublabels = true,
                    subLabels = {
                        function(control)
                            if screen.isFree then
                                return ""
                            else
                                return GAMEPAD_AVA_BROWSER:GetPriceMessage(screen.nowCost, screen.hasEnoughNow)
                            end
                        end
                    },
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
                        AssignCampaignToPlayer(dialog.data.id, CAMPAIGN_REASSIGN_TYPE_IMMEDIATE)
                    end,
                },
            },
            {
                template = "ZO_CampaignBrowserDialogsGamepadMenuEntryNoIcon",
                text = GetString(SI_GAMEPAD_CAMPAIGN_SELECT_HOME_ON_END),
                templateData = {
                    showUnselectedSublabels = true,
                    subLabels = {
                        GetString(SI_GAMEPAD_CAMPAIGN_SELECT_HOME_ON_END_INFO),
                        function(control)
                            if screen.isFree then
                                return ""
                            else
                                return GAMEPAD_AVA_BROWSER:GetPriceMessage(screen.endCost, screen.hasEnoughEnd)
                            end
                        end
                    },
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function(dialog)
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
                visible = function(dialog)
                    return CanChange(dialog)
                end,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData and targetData.callback then
                        targetData.callback(dialog)
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

--------------------------
-- Abandon Home Confirm --
--------------------------

local function InitializeCampaignAbandonHomeConfirmDialog(screen)
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
    
    local function CanChange()
        local targetData = dialog.entryList:GetTargetData()

        if(targetData.useAlliancePoints) then
            return screen.alliancePointCost <= screen.numAlliancePoints
        else
            return screen.goldCost <= screen.numGoldAvailable
        end
    end

    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_ABANDON_HOME_CONFIRM_DIALOG,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC
        },

        canQueue = true,
        onlyQueueOnce = true,

        setup = function(dialog)
            local alliancePointCost, goldCost = ZO_AbandonHomeCampaign_GetCost()
            screen.alliancePointCost = alliancePointCost
            screen.goldCost = goldCost
            screen.numAlliancePoints = GetAlliancePoints()
            screen.numGoldAvailable = GetCurrentMoney()
            screen.hasEnoughAlliancePoints = screen.alliancePointCost <= screen.numAlliancePoints
            screen.hasEnoughGold = screen.goldCost <= screen.numGoldAvailable

            dialog:setupFunc()
        end,

        title =
        {
            text = SI_CAMPAIGN_BROWSER_ABANDON_CAMPAIGN,
        },

        mainText = 
        {
            text = SI_GAMEPAD_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN_MESSAGE,
        },

        --Only show those options that are relevant to the current cost of abandoning campaign through visible function parameter
        parametricList =
        {
            --Free Change: this option intentionally empty text, if the change is free then only this option will be allowed and the dialog is just an accept/confirm with no options
            {
                template = "ZO_CampaignBrowserDialogsGamepadMenuEntryNoIcon",
                text = "",
                templateData = {
                    useAlliancePoints = true,
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function()
                        UnassignCampaignForPlayer(CAMPAIGN_UNASSIGN_TYPE_HOME_USE_ALLIANCE_POINTS)
                    end,
                    visible = function()
                        return screen.alliancePointCost == 0
                    end,
                },
            },
            --Use Alliance Points
            {
                template = "ZO_CampaignBrowserDialogsGamepadMenuEntryNoIcon",
                text = GetString(SI_ABANDON_HOME_CAMPAIGN_USE_ALLIANCE_POINTS),
                templateData = {
                    useAlliancePoints = true,
                    showUnselectedSublabels = true,
                    subLabels = {
                        function(control)
                            return GAMEPAD_AVA_BROWSER:GetPriceMessage(screen.alliancePointCost, screen.hasEnoughAlliancePoints)
                        end
                    },
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function()
                        UnassignCampaignForPlayer(CAMPAIGN_UNASSIGN_TYPE_HOME_USE_ALLIANCE_POINTS)
                    end,
                    visible = function()
                        return screen.alliancePointCost ~= 0
                    end,
                },
            },
            --Use Gold
            {
                template = "ZO_CampaignBrowserDialogsGamepadMenuEntryNoIcon",
                text = GetString(SI_ABANDON_HOME_CAMPAIGN_USE_GOLD),
                templateData = {
                    showUnselectedSublabels = true,
                    subLabels = {
                        function(control)
                            local USE_GOLD = true
                            return GAMEPAD_AVA_BROWSER:GetPriceMessage(screen.goldCost, screen.hasEnoughGold, USE_GOLD)
                        end
                    },
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    callback = function()
                        UnassignCampaignForPlayer(CAMPAIGN_UNASSIGN_TYPE_HOME_USE_GOLD)
                    end,
                    visible = function()
                        return screen.goldCost ~= 0 and screen.alliancePointCost ~= 0
                    end,
                },
            },
        },

        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_ACCEPT,
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
    InitializeCampaignLockedDialog(screen)
    InitializeCampaignGuestWarningDialog()
    InitializeCampaignSetHomeReviewDialog(screen)
    InitializeCampaignSetHomeConfirmDialog(screen)
    InitializeCampaignAbandonGuestDialog()
    InitializeCampaignAbandonHomeConfirmDialog(screen)
end
