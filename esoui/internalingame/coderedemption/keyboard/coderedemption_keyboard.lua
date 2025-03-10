function ZO_KeyboardCodeRedemption_StartCodeRedemptionFlow()
    if DoesPlatformSupportDisablingShareFeatures() then
        DisableShareFeatures()
    end
    ZO_Dialogs_ShowDialog("KEYBOARD_CODE_REDEMPTION_REDEEM_CODE_DIALOG")
end

local function OnCodeRedemptionFlowStopped()
    if DoesPlatformSupportDisablingShareFeatures() then
        EnableShareFeatures()
    end
end

------
-- Redeem Dialog
------

ESO_Dialogs["KEYBOARD_CODE_REDEMPTION_REDEEM_CODE_DIALOG"] =
{
    canQueue = true,
    modal = false,
    title =
    {
        text = GetString(SI_CODE_REDEMPTION_TITLE),
    },
    mainText =
    {
        text = GetString(SI_KEYBOARD_CODE_REDEMPTION_REDEEM_CODE_DIALOG_BODY),
    },
    warning =
    {
        text = GetString(SI_CODE_REDEMPTION_REDEEM_CODE_DIALOG_DETAILS),
    },
    editBox =
    {
        defaultText = zo_strformat(SI_KEYBOARD_CODE_REDEMPTION_REDEEM_CODE_DIALOG_DEFAULT_EDIT_TEXT, GetExampleCodeForCodeRedemption()),
        maxInputCharacters = MAX_PROMO_CODE_LENGTH,
        textType = TEXT_TYPE_ALL,
        initialEditText = function(dialog)
            local enteredCode = dialog.data.enteredCode
            if enteredCode then
                return enteredCode
            end

            return nil
        end,
    },
    buttons =
    {
        {
            text = SI_DIALOG_CONFIRM,
            requiresTextInput = true,
            callback = function(dialog)
                local enteredCode = zo_strgsub(ZO_Dialogs_GetEditBoxText(dialog), "%s+", "")
                local dialogData =
                {
                    enteredCode = enteredCode,
                }
                ZO_Dialogs_ShowDialog("KEYBOARD_CODE_REDEMPTION_PENDING_DIALOG", dialogData)
            end,
        },
        {
            text = SI_DIALOG_CANCEL,
            callback = OnCodeRedemptionFlowStopped,
        }
    },
    noChoiceCallback = OnCodeRedemptionFlowStopped,
}

------
-- Complete Dialog
------

ESO_Dialogs["KEYBOARD_CODE_REDEMPTION_COMPLETE_DIALOG"] =
{
    canQueue = true,
    mustChoose = true,
    modal = false,
    title =
    {
        text = function(dialog)
            local success = dialog.data.success
            if success then
                return GetString(SI_CODE_REDEMPTION_DIALOG_SUCCESS_TITLE)
            else
                return GetString(SI_CODE_REDEMPTION_DIALOG_FAILED_TITLE)
            end
        end,
    },
    mainText =
    {
        text = function(dialog)
            local data = dialog.data
            if data.success then
                local rewardNames = REWARDS_MANAGER:GetListOfRewardNamesFromLastCodeRedemption()
                if #rewardNames > 0 then
                    local listOfRewardNames = ZO_WHITE:Colorize(ZO_GenerateCommaSeparatedListWithoutAnd(rewardNames))
                    return zo_strformat(SI_CODE_REDEMPTION_DIALOG_SUCCESS_WITH_REWARD_NAMES_BODY, listOfRewardNames)
                end
            end

            local redeemCodeResult = data.redeemCodeResult
            return GetString("SI_REDEEMCODERESULT", redeemCodeResult)
        end,
    },
    buttons =
    {
        {
            keybind = "DIALOG_NEGATIVE",
            text = GetString(SI_DIALOG_CLOSE),
            callback = function(dialog)
                local data = dialog.data
                if not data.success then
                    local NO_DIALOG_DATA = nil
                    local textParams =
                    {
                        initialEditText = data.enteredCode,
                    }

                    ZO_Dialogs_ShowDialog("KEYBOARD_CODE_REDEMPTION_REDEEM_CODE_DIALOG", NO_DIALOG_DATA, textParams)
                else
                    OnCodeRedemptionFlowStopped()
                end
            end
        },
    },
}

------
-- Pending Dialog
------

local LOADING_DELAY_MS = 500 -- delay is in milliseconds
local function OnCodeRedemptionComplete(data, success, code, redeemCodeResult)
    EVENT_MANAGER:UnregisterForEvent("KEYBOARD_CODE_REDEMPTION", EVENT_CODE_REDEMPTION_COMPLETE)

    -- add a delay so the dialog transition is smoother
    zo_callLater(function()
                    ZO_Dialogs_ReleaseDialogOnButtonPress("KEYBOARD_CODE_REDEMPTION_PENDING_DIALOG")
                    local dialogData =
                    {
                        success = success,
                        enteredCode = data.enteredCode,
                        returnedCode = code,
                        redeemCodeResult = redeemCodeResult,
                    }
                    ZO_Dialogs_ShowDialog("KEYBOARD_CODE_REDEMPTION_COMPLETE_DIALOG", dialogData)
                    if success then
                        PlaySound(SOUNDS.CODE_REDEMPTION_SUCCESS)
                    else
                        PlaySound(SOUNDS.GENERAL_ALERT_ERROR)
                    end
                end, LOADING_DELAY_MS)
end

local function CodeRedemptionPendingDialogSetup(dialog, data)
    if RequestRedeemCode(data.enteredCode) then
        EVENT_MANAGER:RegisterForEvent("KEYBOARD_CODE_REDEMPTION", EVENT_CODE_REDEMPTION_COMPLETE, function(eventId, ...) OnCodeRedemptionComplete(data, ...) end)
        local SHOW_LOADING_ICON = true
        ZO_Dialogs_SetDialogLoadingIcon(dialog:GetNamedChild("Loading"), dialog:GetNamedChild("Text"), SHOW_LOADING_ICON)
    else
        local dialogData =
        {
            success = false,
            enteredCode = data.enteredCode,
            redeemCodeResult = REDEEM_CODE_RESULT_ERROR,
        }
        ZO_Dialogs_ShowDialog("KEYBOARD_CODE_REDEMPTION_COMPLETE_DIALOG", dialogData)
    end
end

function ZO_KeyboardCodeRedemptionPendingDialog_OnInitialized(control)
    ESO_Dialogs["KEYBOARD_CODE_REDEMPTION_PENDING_DIALOG"] =
    {
        customControl = control,
        setup = CodeRedemptionPendingDialogSetup,
        canQueue = true,
        mustChoose = true,
        title =
        {
            text = GetString(SI_CODE_REDEMPTION_PENDING_TITLE),
        },
        mainText =
        {
            text = GetString(SI_CODE_REDEMPTION_PENDING_LOADING_TEXT),
            align = TEXT_ALIGN_CENTER,
        },
    }
end
