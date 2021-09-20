ZO_ArmoryBuildSettingsDialog_Keyboard = ZO_InitializingObject:Subclass()

function ZO_ArmoryBuildSettingsDialog_Keyboard:Initialize(control)
    self.control = control
    self.containerControl = control:GetNamedChild("ContentContainer")
    self.buildNameEditBox = self.containerControl:GetNamedChild("EditBox")
    self.armoryBuildIconPickerGridListControl = self.containerControl:GetNamedChild("BuildIconPicker")
    self.armoryBuildIconPicker = ZO_ArmoryBuildIconPicker_Keyboard:New(self.armoryBuildIconPickerGridListControl)

    --Needed in order for the requiresTextInput field in the dialog data to work
    control.requiredTextFields = ZO_RequiredTextFields:New()
    control.requiredTextFields:AddTextField(self.buildNameEditBox)
end

function ZO_ArmoryBuildSettingsDialog_Keyboard:SetFocusedBuildData(buildData)
    self.selectedBuildData = buildData
    self.buildNameEditBox:SetText(buildData:GetName())
    self.armoryBuildIconPicker:SetupIconPickerForArmoryBuild(buildData)
end

function ZO_ArmoryBuildSettingsDialog_Keyboard:SavePendingChanges()
    --If we somehow don't have any build data, there isn't anything to save our changes to
    if self.selectedBuildData then
        local pendingBuildName = self.buildNameEditBox:GetText()
        if pendingBuildName and pendingBuildName ~= "" then
            local violations = { IsValidArmoryBuildName(pendingBuildName) }
            if #violations == 0 then
                self.selectedBuildData:SetName(pendingBuildName)
                self.selectedBuildData:SetIconIndex(self.armoryBuildIconPicker:GetSelectedArmoryBuildIconIndex())
                return true
            end
        end
    end

    --If we get here, that means we failed to save the pending changes for some reason, so return false
    return false
end

function ZO_ArmoryBuildSettingsDialog_OnInitialized(self)
    self.object = ZO_ArmoryBuildSettingsDialog_Keyboard:New(self)

    ZO_Dialogs_RegisterCustomDialog("ArmorySettingsDialog",
    {
        title =
        {
            text = SI_ARMORY_BUILD_DIALOG_TITLE,
        },
        mainText =
        {
            text = "",
        },
        setup = function(dialog, data)
            --Set up the rules for the edit box
            local editControl = dialog:GetNamedChild("ContentContainerEditBox")
            editControl:SetTextType(TEXT_TYPE_ALL)
            editControl:SetMaxInputChars(MAX_ARMORY_BUILD_NAME_LENGTH)

            self.object:SetFocusedBuildData(data.selectedBuildData)
            self.object.armoryBuildIconPicker:ScrollToSelectedData()
            self.object.armoryBuildIconPicker:RefreshGridList()
        end,
        customControl = self,
        buttons =
        {
            {
                requiresTextInput = true,
                noReleaseOnClick = true,
                control = self:GetNamedChild("Close"),
                text = SI_DIALOG_CLOSE,
                callback = function(dialog)
                    --Only close the dialog if the changes were saved successfully
                    if dialog.object:SavePendingChanges() then
                        if dialog.data.confirmCallback then
                            dialog.data:confirmCallback()
                        end
                        ZO_Dialogs_ReleaseDialog("ArmorySettingsDialog")
                    end
                end
            },
        }
    })
end

------------------
--Global XML
------------------

function ZO_ArmoryBuild_BuildIconPickerIcon_Keyboard_OnMouseEnter(self)
    if ZO_CheckButton_IsEnabled(self:GetNamedChild("IconContainerFrame")) then
        self:GetNamedChild("Highlight"):SetHidden(false)
    end
end

function ZO_ArmoryBuild_BuildIconPickerIcon_Keyboard_OnMouseExit(self)
    self:GetNamedChild("Highlight"):SetHidden(true)
end