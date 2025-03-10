local function SetupLogoutDialog(dialog)
    local dailyRewardTile = dialog:GetNamedChild("DailyRewardTile")
    local isLocked = ZO_DAILYLOGINREWARDS_MANAGER:IsDailyRewardsLocked()
    if dailyRewardTile then
        local tileObject = dailyRewardTile.object
        tileObject:SetHidden(isLocked)
        tileObject:SetActionAvailable(not isLocked)
        tileObject:RefreshLayout()
        tileObject:SetSelected(true)
    end

    local mainText = dialog.data.quit and GetString(SI_QUIT_DIALOG) or GetString(SI_LOG_OUT_DIALOG)
    dialog:GetNamedChild("LogoutText"):SetText(mainText)

    local dividerControl = dialog:GetNamedChild("TileDivider")
    dividerControl:SetHidden(isLocked)
end

function ZO_LogoutDialog_Gamepad_OnInitialized(self)
    ZO_GenericGamepadDialog_OnInitialized(self)

    local dailyRewardTile = self:GetNamedChild("DailyRewardTile")
    local tileObject = dailyRewardTile.object
    tileObject:SetKeybindKey("DIALOG_SECONDARY")
    tileObject:RegisterCallback("OnRefreshLayout", function() ZO_GenericGamepadDialog_RefreshKeybinds(self) end)

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_LOG_OUT",
    {
        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.CUSTOM
        },
        customControl = self,
        setup = SetupLogoutDialog,
        updateFn = function(dialog)
            local isLocked = ZO_DAILYLOGINREWARDS_MANAGER:IsDailyRewardsLocked()
            if tileObject:IsActionAvailable() == isLocked then
                tileObject:SetHidden(isLocked)
                tileObject:SetActionAvailable(not isLocked)
                tileObject:RefreshLayout()
                ZO_GenericGamepadDialog_RefreshKeybinds(self)

                local dividerControl = dialog:GetNamedChild("TileDivider")
                dividerControl:SetHidden(isLocked)
            end
        end,
        blockDialogReleaseOnPress = true,
        canQueue = true,
        title =
        {
            text = function(dialog)
                if dialog.data.quit then
                    return GetString(SI_PROMPT_TITLE_QUIT)
                else
                    return GetString(SI_PROMPT_TITLE_LOG_OUT)
                end
            end,
        },
        narrationText = function(dialog)
            local narrations = {}
            if dialog.data.quit then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_QUIT_DIALOG)))
            else
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_LOG_OUT_DIALOG)))
            end
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(dailyRewardTile.object.headerText))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(dailyRewardTile.object.titleText))
            return narrations
        end,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = function(dialog)
                    if dialog.data.quit then
                        return GetString(SI_QUIT_GAME_CONFIRM_KEYBIND)
                    else
                        return GetString(SI_LOG_OUT_GAME_CONFIRM_KEYBIND)
                    end
                end,
                callback = function(dialog)
                    if dialog.data.quit then
                        Quit()
                    else
                        Logout()
                    end
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_LOG_OUT")
                end
            },
            tileObject:GetKeybindDescriptor(),
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_LOG_OUT")
                end
            },
        },
    })
end