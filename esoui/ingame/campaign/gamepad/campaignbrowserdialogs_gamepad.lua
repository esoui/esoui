ZO_GAMEPAD_CAMPAIGN_QUEUE_DIALOG = "GAMEPAD_CAMPAIGN_QUEUE_DIALOG"
ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG = "GAMEPAD_CAMPAIGN_LOCKED_DIALOG"
ZO_GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG = "GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG"
ZO_GAMEPAD_CAMPAIGN_SET_HOME_CONFIRM_DIALOG = "GAMEPAD_CAMPAIGN_SET_HOME_CONFIRM_DIALOG"
ZO_GAMEPAD_CAMPAIGN_ABANDON_HOME_CONFIRM_DIALOG = "GAMEPAD_CAMPAIGN_ABANDON_HOME_CONFIRM_DIALOG"

--------------------
-- Queue Campaign --
--------------------

local function InitializeCampaignQueueDialog()
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_QUEUE_DIALOG,
    {
        canQueue = true,

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC
        },

        setup = function(dialog)
            dialog.data.groupQueueResult = GetExpectedGroupQueueResult()
            dialog:setupFunc()
        end,

        title =
        {
            text = SI_CAMPAIGN_BROWSER_QUEUE_DIALOG_TITLE,
        },

        mainText = 
        {
            text = SI_CAMPAIGN_BROWSER_QUEUE_DIALOG_PROMPT,
        },

        parametricList =
        {
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = {
                    text = GetString(SI_CAMPAIGN_BROWSER_QUEUE_GROUP),
                    setup = function(control, data, ...)
                        data:SetEnabled(parametricDialog.data.groupQueueResult == QUEUE_FOR_CAMPAIGN_RESULT_SUCCESS)
                        return ZO_SharedGamepadEntry_OnSetup(control, data, ...)
                    end,
                    queueType = CAMPAIGN_QUEUE_TYPE_GROUP,
                },
            },
            {
                template = "ZO_GamepadMenuEntryTemplate",
                templateData = {
                    text = GetString(SI_CAMPAIGN_BROWSER_QUEUE_SOLO),
                    setup = ZO_SharedGamepadEntry_OnSetup,
                    queueType = CAMPAIGN_QUEUE_TYPE_INDIVIDUAL,
                },
            },
        },

        parametricListOnSelectionChangedCallback = function(dialog, list, newSelectedData, oldSelectedData)
            if newSelectedData and not newSelectedData:IsEnabled() then
                local tooltipText = GetString("SI_QUEUEFORCAMPAIGNRESPONSETYPE", dialog.data.groupQueueResult)
                GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, tooltipText)
                ZO_GenericGamepadDialog_ShowTooltip(dialog)
            else
                ZO_GenericGamepadDialog_HideTooltip(dialog)
            end
        end,
       
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData then
                        local queueType = targetData.queueType
                        CAMPAIGN_BROWSER_MANAGER:ContinueQueueForCampaignFlow(dialog.data.campaignData, ZO_CAMPAIGN_QUEUE_STEP_SELECT_QUEUE_TYPE, queueType)
                    end
                end,
                enabled = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    return targetData and targetData:IsEnabled()
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
    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG,
    {
        canQueue = true,

        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        updateFn = function(dialog)
            ZO_Dialogs_RefreshDialogText(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG, dialog)

            --If the displayed cooldown reaches 0, automatically forward user to the now unlocked dialog they were trying to navigate to originally
            if dialog.data.isAbandoning then
                local timeLeft = GetCampaignUnassignCooldown()
                if timeLeft <= 0 then
                    ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_ABANDON_HOME_CONFIRM_DIALOG, { id = dialog.data.id }, { mainTextParams = screen:GetTextParamsForAbandonHomeDialog() })
                    ZO_Dialogs_ReleaseDialog("GAMEPAD_CAMPAIGN_LOCKED_DIALOG")
                end
            else
                local timeLeft = GetCampaignReassignCooldown()
                if timeLeft <= 0 then
                    ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG, { id = dialog.data.id, campaignData = dialog.data.campaignData })
                    ZO_Dialogs_ReleaseDialog("GAMEPAD_CAMPAIGN_LOCKED_DIALOG")
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
                if dialog.data.isAbandoning then
                    local timeleftStr = ZO_SELECTED_TEXT:Colorize(ZO_FormatTime(GetCampaignUnassignCooldown(), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING))
                    return zo_strformat(SI_ABANDON_HOME_CAMPAIGN_LOCKED_MESSAGE, timeleftStr)
                else
                    local timeleftStr = ZO_SELECTED_TEXT:Colorize(ZO_FormatTime(GetCampaignReassignCooldown(), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING))
                    return zo_strformat(SI_SELECT_HOME_CAMPAIGN_LOCKED_MESSAGE, timeleftStr)
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
            text = function(dialog)
                local messages = {}
                local data = dialog.data
                local campaignData = data.campaignData

                local campaignName = ZO_SELECTED_TEXT:Colorize(campaignData.name)
                local initialCooldownString = ZO_SELECTED_TEXT:Colorize(ZO_FormatTime(GetCampaignReassignInitialCooldown(), TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING))
                local campaignInfoMessage = ZO_CachedStrFormat(SI_SELECT_HOME_CAMPAIGN_QUERY, campaignName, initialCooldownString)
                table.insert(messages, campaignInfoMessage)

                if ZO_CampaignBrowserDialogs_ShouldShowAllianceLockWarning(campaignData) then
                    local playerAlliance = GetUnitAlliance("player")
                    local allianceString = ZO_SELECTED_TEXT:Colorize(ZO_CampaignBrowser_FormatPlatformAllianceIconAndName(playerAlliance))
                    local campaignEndCooldownString = ZO_SELECTED_TEXT:Colorize(ZO_FormatTime(data.secondsUntilCampaignEnd, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING))
                    local allianceLockMessage = zo_strformat(SI_ABOUT_TO_ALLIANCE_LOCK_CAMPAIGN_WARNING, allianceString, campaignEndCooldownString)
                    table.insert(messages, allianceLockMessage)
                end

                local nowCost, endCost = ZO_SelectHomeCampaign_GetCost()
                local isFree = nowCost == 0
                local costMessage
                if isFree then
                    costMessage = GetString(SI_SELECT_HOME_CAMPAIGN_FREE)
                else
                    local numAlliancePoints = GetCurrencyAmount(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_CHARACTER)
                    local hasEnough = nowCost <= numAlliancePoints
                    local priceMessage = GAMEPAD_AVA_BROWSER:GetPriceMessage(nowCost, hasEnough)
                    costMessage = ZO_CachedStrFormat(SI_GAMEPAD_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN_COST, priceMessage)
                end
                table.insert(messages, costMessage)

                return ZO_GenerateParagraphSeparatedList(messages)
            end,
        },

        updateFn = function(dialog)
            local campaignData = dialog.data.campaignData
            if not ZO_CampaignBrowserDialogs_ShouldShowAllianceLockWarning(campaignData) then
                -- no need to update
                return
            end

            local _, secondsUntilCampaignEnd = GetSelectionCampaignTimes(campaignData.selectionIndex)
            if dialog.data.secondsUntilCampaignEnd ~= secondsUntilCampaignEnd then
                dialog.data.secondsUntilCampaignEnd = secondsUntilCampaignEnd
                ZO_Dialogs_RefreshDialogText(ZO_GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG, dialog)
            end
        end,

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
            screen.numAlliancePoints = GetCurrencyAmount(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_CHARACTER)
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

        if targetData.useAlliancePoints then
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
            screen.numAlliancePoints = GetCurrencyAmount(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_CHARACTER)
            screen.numGoldAvailable = GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
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
                    if targetData and targetData.callback then
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
    InitializeCampaignQueueDialog()
    InitializeCampaignLockedDialog(screen)
    InitializeCampaignSetHomeReviewDialog(screen)
    InitializeCampaignSetHomeConfirmDialog(screen)
    InitializeCampaignAbandonHomeConfirmDialog(screen)
end
