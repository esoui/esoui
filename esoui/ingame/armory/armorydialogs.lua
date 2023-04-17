---------------------
-- ESO Dialogs
---------------------

--Restore Dialogs
ESO_Dialogs["ARMORY_BUILD_RESTORE_DIALOG"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.COOLDOWN,
        allowShowOnNextScene = true,
    },
    title =
    {
        text = GetString("SI_ARMORYBUILDOPERATIONTYPE", ARMORY_BUILD_OPERATION_TYPE_RESTORE),
    },
    mainText =
    {
        align = TEXT_ALIGN_CENTER,
        text = GetString("SI_ARMORYBUILDOPERATIONTYPE_DIALOGMESSAGE", ARMORY_BUILD_OPERATION_TYPE_RESTORE),
    },
    showLoadingIcon = true,
    --Since no choices are provided this forces the dialog to remain shown until programmaticly closed
    mustChoose = true,
    buttons = {},
}

ESO_Dialogs["ARMORY_BUILD_RESTORE_FAILED_DIALOG"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_ARMORY_BUILD_RESTORE_FAIL_DIALOG_TITLE,
    },
    mainText =
    {
        align = TEXT_ALIGN_CENTER,
        text = SI_ARMORY_BUILD_OPERATION_FAIL_REASON_FORMATTER,
    },
    buttons =
    {
        {
            text = SI_OK,
            keybind = "DIALOG_NEGATIVE",
            clickSound = SOUNDS.DIALOG_ACCEPT,
        }
    },
    finishedCallback = function()
        ZO_ARMORY_MANAGER:OnBuildOperationResultClosed()
    end,
}

ESO_Dialogs["ARMORY_BUILD_RESTORE_SUCCESS_DIALOG"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_ARMORY_BUILD_RESTORE_SUCCESS_DIALOG_TITLE,
    },
    mainText =
    {
        align = TEXT_ALIGN_CENTER,
        text = SI_ARMORY_BUILD_RESTORE_SUCCESS_DIALOG_TEXT,
    },
    buttons =
    {
        {
            text = SI_OK,
            keybind = "DIALOG_NEGATIVE",
            gamepadPreferredKeybind = "DIALOG_PRIMARY",
            clickSound = SOUNDS.DIALOG_ACCEPT,
        },
    },
    finishedCallback = function()
        ZO_ARMORY_MANAGER:OnBuildOperationResultClosed()
    end,
}

ESO_Dialogs["ARMORY_BUILD_RESTORE_CONFIRM_DIALOG"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_ARMORY_RESTORE_BUILD_ACTION,
    },
    mainText =
    {
        text =  function(dialog)
            local data = dialog.data
            local playerCurseType = GetPlayerCurseType()
            local confirmationText = zo_strformat(SI_ARMORY_BUILD_RESTORE_CONFIRMATION_DIALOG_TEXT, dialog.textParams.mainTextParams[1])
            local respecText = IsChampionSystemUnlocked() and GetString(SI_ARMORY_BUILD_RESTORE_CONFIRMATION_DIALOG_RESPEC_TEXT) or GetString(SI_ARMORY_BUILD_RESTORE_CONFIRMATION_DIALOG_CHAMPION_LOCKED_RESPEC_TEXT)
            local paragraphs = 
            {
                confirmationText, 
                respecText,
            }
            if data.curseType ~= playerCurseType then
                local curseWarningMessage = nil
                if data.curseType == CURSE_TYPE_NONE then
                    --If equipping the build will cure your curse
                    local playerCurseTypeName = GetString("SI_CURSETYPE", playerCurseType)
                    curseWarningMessage = zo_strformat(SI_ARMORY_BUILD_RESTORE_CONFIRMATION_DIALOG_CURSE_CURE_TEXT, ZO_SELECTED_TEXT:Colorize(playerCurseTypeName))
                elseif playerCurseType == CURSE_TYPE_NONE then
                    --If equipping the build will apply a curse
                    local buildCurseTypeName = GetString("SI_CURSETYPE", data.curseType)
                    curseWarningMessage = zo_strformat(SI_ARMORY_BUILD_RESTORE_CONFIRMATION_DIALOG_CURSE_ADD_TEXT, ZO_SELECTED_TEXT:Colorize(buildCurseTypeName))
                else
                    --If equipping the build will swap your curse
                    local playerCurseTypeName = GetString("SI_CURSETYPE", playerCurseType)
                    local buildCurseTypeName = GetString("SI_CURSETYPE", data.curseType)
                    curseWarningMessage = zo_strformat(SI_ARMORY_BUILD_RESTORE_CONFIRMATION_DIALOG_CURSE_CHANGE_TEXT, ZO_SELECTED_TEXT:Colorize(playerCurseTypeName), ZO_SELECTED_TEXT:Colorize(buildCurseTypeName))
                end
                table.insert(paragraphs, curseWarningMessage)
            end
            
            --If equipping the build will clear your mundus stones
            if data.primaryMundus == MUNDUS_STONE_INVALID then
                table.insert(paragraphs, GetString(SI_ARMORY_BUILD_RESTORE_EMPTY_MUNDUS_TEXT))
            end

            return ZO_GenerateParagraphSeparatedList(paragraphs)
        end,
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                RestoreArmoryBuild(dialog.data.selectedBuildIndex)
            end,
        },
        {
            text = SI_DIALOG_CANCEL
        },
    }
}

--Save Dialogs
ESO_Dialogs["ARMORY_BUILD_SAVE_DIALOG"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.COOLDOWN,
        allowShowOnNextScene = true,
    },
    title =
    {
        text = GetString("SI_ARMORYBUILDOPERATIONTYPE", ARMORY_BUILD_OPERATION_TYPE_SAVE),
    },
    mainText =
    {
        align = TEXT_ALIGN_CENTER,
        text = GetString("SI_ARMORYBUILDOPERATIONTYPE_DIALOGMESSAGE", ARMORY_BUILD_OPERATION_TYPE_SAVE),
    },
    showLoadingIcon = true,
    --Since no choices are provided this forces the dialog to remain shown until programmaticly closed
    mustChoose = true,
    buttons = {},
}

ESO_Dialogs["ARMORY_BUILD_SAVE_FAILED_DIALOG"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_ARMORY_BUILD_SAVE_FAIL_DIALOG_TITLE,
    },
    mainText = 
    {
        align = TEXT_ALIGN_CENTER,
        text = SI_ARMORY_BUILD_OPERATION_FAIL_REASON_FORMATTER,
    },
    buttons =
    {
        {
            text = SI_OK,
            keybind = "DIALOG_NEGATIVE",
            clickSound = SOUNDS.DIALOG_ACCEPT,
        }
    },
    finishedCallback = function()
        ZO_ARMORY_MANAGER:OnBuildOperationResultClosed()
    end,
}

ESO_Dialogs["ARMORY_BUILD_SAVE_SUCCESS_DIALOG"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_ARMORY_BUILD_SAVE_SUCCESS_DIALOG_TITLE,
    },
    mainText =
    {
        align = TEXT_ALIGN_CENTER,
        text = SI_ARMORY_BUILD_SAVE_SUCCESS_DIALOG_TEXT,
    },
    buttons =
    {
        {
            text = SI_OK,
            keybind = "DIALOG_NEGATIVE",
            gamepadPreferredKeybind = "DIALOG_PRIMARY",
            clickSound = SOUNDS.DIALOG_ACCEPT,
        }
    },
    finishedCallback = function()
        ZO_ARMORY_MANAGER:OnBuildOperationResultClosed()
    end,
}

ESO_Dialogs["ARMORY_BUILD_SAVE_CONFIRM_DIALOG"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_ARMORY_SAVE_BUILD_ACTION,
    },
    mainText =
    {
        text = SI_ARMORY_BUILD_SAVE_CONFIRMATION_DIALOG_TEXT,
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                SaveArmoryBuild(dialog.data.selectedBuildIndex)
            end,
        },
        {
            text = SI_DIALOG_CANCEL
        },
    }
}