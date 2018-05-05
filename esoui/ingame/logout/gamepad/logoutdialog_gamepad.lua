local function SetupLogoutDialog(dialog)
	local dailyRewardTile = dialog:GetNamedChild("DailyRewardTile")
    local numRewards = GetNumRewardsInCurrentDailyLoginMonth()
    local hasNoRewards = numRewards == 0
	if dailyRewardTile then
        local tileObject = dailyRewardTile.object
        tileObject:SetHidden(hasNoRewards)
		tileObject:SetActionAvailable(not hasNoRewards)
		tileObject:RefreshLayout()
		tileObject:SetSelected(true)
	end

    local dividerControl = dialog:GetNamedChild("TileDivider")
    dividerControl:SetHidden(hasNoRewards)
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