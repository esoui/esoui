local function SetupQuitDialog(dialog)
    local isLocked = ZO_DAILYLOGINREWARDS_MANAGER:IsDailyRewardsLocked()
	local dailyRewardTile = dialog:GetNamedChild("DailyRewardTile")
	if dailyRewardTile then
        dailyRewardTile.object:SetHidden(isLocked)
        dailyRewardTile.object:SetActionAvailable(not isLocked)
		dailyRewardTile.object:RefreshLayout()
	end
	local dividerControl = dialog:GetNamedChild("TileDivider")
    dividerControl:SetHidden(isLocked)
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
            updateFn = function(dialog) -- if lock status changes, make sure to update the tile visibility
                local isLocked = ZO_DAILYLOGINREWARDS_MANAGER:IsDailyRewardsLocked()
                local dailyRewardTile = dialog:GetNamedChild("DailyRewardTile")
                if dailyRewardTile.object:IsActionAvailable() == isLocked then
                    SetupQuitDialog(dialog)
                end
            end,
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