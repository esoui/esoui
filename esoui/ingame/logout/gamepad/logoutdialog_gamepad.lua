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
        OnHiddenCallback = CleanupLogoutDialog,
        blockDialogReleaseOnPress = true,
        canQueue = true,
        title =
        {
            text = SI_PROMPT_TITLE_LOG_OUT,
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_LOG_OUT_GAME_CONFIRM_KEYBIND,
                callback = function(dialog)
                    Logout()
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