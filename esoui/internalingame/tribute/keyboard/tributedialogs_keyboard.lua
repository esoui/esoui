ZO_TributeSettingsDialog_Keyboard = ZO_InitializingObject:Subclass()

function ZO_TributeSettingsDialog_Keyboard:Initialize(control)
    self.control = control
    self.containerControl = control:GetNamedChild("ContentContainer")
    self.autoPlayButton = self.containerControl:GetNamedChild("AutoPlayCheck")
    self.concedeButton = self.containerControl:GetNamedChild("ConcedeButton")

    self.concedeButton:SetNormalFontColor(ZO_ERROR_COLOR:UnpackRGBA())
    self.concedeButton:SetMouseOverFontColor(ZO_ERROR_COLOR:GetBright():UnpackRGBA())
    self.concedeButton:SetPressedFontColor(ZO_ERROR_COLOR:GetDim():UnpackRGBA())

    ZO_CheckButton_SetLabelText(self.autoPlayButton, GetString(SI_TRIBUTE_SETTINGS_DIALOG_AUTO_PLAY))
    ZO_CheckButton_SetToggleFunction(self.autoPlayButton, function() self:SetAutoPlay(ZO_CheckButton_IsChecked(self.autoPlayButton)) end)
end

function ZO_TributeSettingsDialog_Keyboard:SavePendingChanges()
    TRIBUTE:OnSettingsChanged(self.autoPlayEnabled)
end

function ZO_TributeSettingsDialog_Keyboard:SetAutoPlay(autoPlayEnabled)
    --Make sure the checkbox is in sync with the setting
    if ZO_CheckButton_IsChecked(self.autoPlayButton) ~= autoPlayEnabled then
        ZO_CheckButton_SetCheckState(self.autoPlayButton, autoPlayEnabled)
    end
    self.autoPlayEnabled = autoPlayEnabled
end

function ZO_TributeSettingsDialog_Keyboard_OnInitialized(self)
    self.object = ZO_TributeSettingsDialog_Keyboard:New(self)

    ZO_Dialogs_RegisterCustomDialog("KEYBOARD_TRIBUTE_OPTIONS",
    {
        customControl = self,
        title =
        {
            text = SI_TRIBUTE_SETTINGS_DIALOG_TITLE,
        },
        mainText =
        {
            text = "",
        },
        setup = function(dialog, data)
            self.object:SetAutoPlay(data.autoPlay)

            local warningLabel = self.object.containerControl:GetNamedChild("ConcedeWarning")
            if WillConcedeCausePenalty() then
                local forfeitPenaltyMs = GetTributeForfeitPenaltyDurationMs()
                local formattedTimeText = ZO_FormatTimeMilliseconds(forfeitPenaltyMs, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
                warningLabel:SetText(zo_strformat(SI_TRIBUTE_SETTINGS_DIALOG_CONCEDE_WARNING, formattedTimeText))
                warningLabel:SetHidden(false)
            else
                warningLabel:SetText("")
                warningLabel:SetHidden(true)
            end
        end,
        finishedCallback = function(dialog)
            --Wait until the dialog closes before saving the changes to the settings
            dialog.object:SavePendingChanges() 
            TRIBUTE:RefreshInputState()
        end,
        buttons =
        {
            {
                noReleaseOnClick = true,
                control = self:GetNamedChild("Close"),
                text = SI_DIALOG_CLOSE,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("KEYBOARD_TRIBUTE_OPTIONS")
                end,
            },
        }
    })
end

------------------
--Global XML
------------------

function ZO_TributeSettingsDialogConcedeButton_Keyboard_OnClicked(control)
    --TODO Tribute: Look into potentially making this transition smoother
    ZO_Dialogs_ReleaseDialog("KEYBOARD_TRIBUTE_OPTIONS")
    ZO_Dialogs_ShowDialog("CONFIRM_CONCEDE_TRIBUTE")
    TRIBUTE:RefreshInputState()
end