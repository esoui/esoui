local function SetupQuitDialog(dialog)
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

function ZO_QuitDialog_Keyboard_OnInitialized(self)
	ZO_Dialogs_RegisterCustomDialog("QUIT",
        {
            customControl = self,
            setup = SetupQuitDialog,
            canQueue = true,
            title =
            {
                text = SI_PROMPT_TITLE_QUIT,
            },
            buttons =
            {
                {
                    keybind = "DIALOG_PRIMARY",
                    control = self:GetNamedChild("Confirm"),
                    text = SI_QUIT_GAME_CONFIRM_KEYBIND,
                    callback = function(dialog)
                        Quit()
                    end
                },
                {
                    control = self:GetNamedChild("Cancel"),
                    text = SI_DIALOG_CANCEL,
                },
            },
        })
end