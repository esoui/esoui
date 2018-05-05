local function SetupLogoutDialog(dialog)
	local numRewards = GetNumRewardsInCurrentDailyLoginMonth()
    local hasNoRewards = numRewards == 0
	local dailyRewardTile = dialog:GetNamedChild("DailyRewardTile")
	if dailyRewardTile then
        dailyRewardTile.object:SetHidden(hasNoRewards)
		dailyRewardTile.object:RefreshLayout()
	end
	local dividerControl = dialog:GetNamedChild("TileDivider")
    dividerControl:SetHidden(hasNoRewards)
end

function ZO_LogoutDialog_Keyboard_OnInitialized(self)
	ZO_Dialogs_RegisterCustomDialog("LOG_OUT",
        {
            customControl = self,
            setup = SetupLogoutDialog,
            canQueue = true,
            title =
            {
                text = SI_PROMPT_TITLE_LOG_OUT,
            },
            buttons =
            {
                {
                    keybind = "DIALOG_PRIMARY",
                    control = self:GetNamedChild("Confirm"),
                    text = SI_LOG_OUT_GAME_CONFIRM_KEYBIND,
                    callback = function(dialog)
                        Logout()
                    end
                },
                {
                    control = self:GetNamedChild("Cancel"),
                    text = SI_DIALOG_CANCEL,
                },
            },
        })
end