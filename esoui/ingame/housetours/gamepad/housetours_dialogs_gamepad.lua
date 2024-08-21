---- Favorite / Recommend Dialog

ZO_HouseTours_FavoriteRecommendHouseDialog_Gamepad = ZO_HouseTours_FavoriteRecommendHouseDialog_Shared:Subclass()

function ZO_HouseTours_FavoriteRecommendHouseDialog_Gamepad:RegisterDialog(dialogName)
    self.dialog =
    {
        canQueue = true,
        blockDialogReleaseOnPress = true,
        onHidingCallback = OnReleaseDialog,
        noChoiceCallback = OnReleaseDialog,
        setup = function(dialog, ...)
            dialog:setupFunc(...)
        end,

        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = false,
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
                enabled = function(dialog)
                    local enabled = true
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData then
                        if type(targetData.enabled) == "function" then
                            enabled = targetData.enabled(dialog)
                        else
                            enabled = targetData.enabled
                        end
                    end
                    return enabled
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
                end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    self:OnConfirmDialog()
                    ZO_Dialogs_ReleaseDialogOnButtonPress(dialogName)
                end,
            },
        },

        parametricListOnSelectionChangedCallback = function(dialog, list, newSelectedData, oldSelectedData)
            self:RefreshTooltip(dialog)
        end,

        parametricList =
        {
            -- Favorite
            {
                template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
                text = GetString(SI_HOUSE_TOURS_VISITOR_DIALOG_FAVORITE_OPTION_TEXT),
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)

                        local isFavorite = self:IsFavoriteOptionSelected()
                        ZO_CheckButton_SetEnableState(control.checkBox, self:IsFavoriteOptionEnabled())

                        local setCheckedFunction = isFavorite and ZO_CheckButton_SetChecked or ZO_CheckButton_SetUnchecked
                        setCheckedFunction(control.checkBox)
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)

                        local isChecked = ZO_GamepadCheckBoxTemplate_IsChecked(targetControl)
                        self:SetFavoriteOptionSelected(isChecked)
                        self:RefreshTooltip(dialog)
                        SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                    end,
                    narrationText = ZO_GetDefaultParametricListToggleNarrationText,
                    narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
                    tooltipText = function(dialog)
                        return self:GetFavoritesText()
                    end,
                },
            },
            -- Recommend
            {
                template = "ZO_CheckBoxTemplate_WithoutIndent_Gamepad",
                text = GetString(SI_HOUSE_TOURS_VISITOR_DIALOG_RECOMMEND_OPTION_TEXT),
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, reselectingDuringRebuild, enabled, active)

                        local isEnabled = self:IsRecommendOptionEnabled()
                        ZO_CheckButton_SetEnableState(control.checkBox, isEnabled)

                        local setCheckedFunction = self:IsRecommendOptionSelected() and ZO_CheckButton_SetChecked or ZO_CheckButton_SetUnchecked
                        setCheckedFunction(control.checkBox)
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        ZO_GamepadCheckBoxTemplate_OnClicked(targetControl)

                        local isChecked = ZO_GamepadCheckBoxTemplate_IsChecked(targetControl)
                        self:SetRecommendOptionSelected(isChecked)
                        self:RefreshTooltip(dialog)
                        SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                    end,
                    enabled = function()
                        return self:IsRecommendOptionEnabled()
                    end,
                    visible = function()
                        return self:IsRecommendOptionVisible()
                    end,
                    narrationText = ZO_GetDefaultParametricListToggleNarrationText,
                    narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
                    tooltipText = function(dialog)
                        return self:GetRecommendationsText()
                    end,
                },
            },
        },
    }

    ZO_Dialogs_RegisterCustomDialog(dialogName, self.dialog)
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Gamepad:RefreshTooltip(dialog)
    local tooltipText = nil
    local data = dialog.entryList:GetTargetData()
    if data and data.tooltipText then
        tooltipText = data.tooltipText(dialog)
    end

    if tooltipText then
        GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, tooltipText)
        ZO_GenericGamepadDialog_ShowTooltip(dialog)
    else
        ZO_GenericGamepadDialog_HideTooltip(dialog)
    end
end

function ZO_HouseTours_FavoriteRecommendHouseDialog_Gamepad:SetupDialog()
    ZO_HouseTours_FavoriteRecommendHouseDialog_Shared.SetupDialog(self)
end

HOUSE_TOURS_FAVORITE_RECOMMEND_HOUSE_DIALOG_GAMEPAD = ZO_HouseTours_FavoriteRecommendHouseDialog_Gamepad:New("HOUSE_TOURS_FAVORITE_RECOMMEND_HOUSE_GAMEPAD")