---------------------------
--Armory Build Icon Picker --
---------------------------

ZO_ARMORY_BUILD_ICON_PICKER_PICK_GAMEPAD_SIZE = 75
ZO_ARMORY_BUILD_ICON_PICKER_PICK_GAMEPAD_OFFSET = 30
ZO_ARMORY_BUILD_ICON_PICKER_ICON_GAMEPAD_SIZE = 64
ZO_ARMORY_BUILD_ICON_PICKER_ICON_GAMEPAD_OFFSET = 5

ZO_ArmoryBuildIconPicker_Gamepad = ZO_ArmoryBuildIconPicker_Shared:Subclass()

function ZO_ArmoryBuildIconPicker_Gamepad:Initialize(control)
    local templateData =
    {
        gridListClass = ZO_GridScrollList_Gamepad,
        entryTemplate = "ZO_ArmoryBuild_BuildIconPickerIcon_Gamepad_Control",
        entryWidth = ZO_ARMORY_BUILD_ICON_PICKER_PICK_GAMEPAD_SIZE,
        entryHeight = ZO_ARMORY_BUILD_ICON_PICKER_PICK_GAMEPAD_SIZE,
        entryPaddingX = ZO_ARMORY_BUILD_ICON_PICKER_PICK_GAMEPAD_OFFSET,
        entryPaddingY = ZO_ARMORY_BUILD_ICON_PICKER_PICK_GAMEPAD_OFFSET,
    }

    ZO_ArmoryBuildIconPicker_Shared.Initialize(self, control, templateData)

    self:InitializeArmoryBuildIconPickerGridList()
end

function ZO_ArmoryBuildIconPicker_Gamepad:InitializeArmoryBuildIconPickerGridList()
    ZO_ArmoryBuildIconPicker_Shared.InitializeArmoryBuildIconPickerGridList(self)

    self.armoryBuildIconPickerGridList:SetOnSelectedDataChangedCallback(function(...) self:OnArmoryBuildIconPickerGridSelectionChanged(...) end)
end

function ZO_ArmoryBuildIconPicker_Gamepad:OnArmoryBuildIconPickerGridSelectionChanged(oldSelectedData, selectedData)
    -- Deselect previous tile
    if oldSelectedData and oldSelectedData.dataEntry then
        oldSelectedData.isSelected = false
    end

    -- Select newly selected tile.
    if selectedData and selectedData.dataEntry then
        selectedData.isSelected = true
    end

    self.armoryBuildIconPickerGridList:RefreshGridList()
end

function ZO_ArmoryBuildIconPicker_Gamepad:OnArmoryBuildIconPickerEntrySetup(control, data)
    local iconTexture = control:GetNamedChild("Icon")
    local pickedControl = control:GetNamedChild("CurrentIconIndicator")

    local isCurrent = data.isCurrent
    if type(isCurrent) == "function" then
        isCurrent = isCurrent()
    end

    iconTexture:SetTexture(ZO_ARMORY_MANAGER:GetBuildIcon(data.iconIndex))
    pickedControl:SetHidden(not isCurrent)
end

function ZO_ArmoryBuildIconPicker_Gamepad:OnArmoryBuildIconPickerGridListEntryClicked()
    local selectedData = self.armoryBuildIconPickerGridList:GetSelectedData()
    if selectedData then
        self:SetArmoryBuildIconPicked(selectedData.iconIndex)
    end
    self.armoryBuildIconPickerGridList:RefreshGridList()
end

function ZO_ArmoryBuildIconPicker_Gamepad:IsActive()
    return self.armoryBuildIconPickerGridList:IsActive()
end

function ZO_ArmoryBuildIconPicker_Gamepad:Activate()
    self.armoryBuildIconPickerGridList:Activate()
end

function ZO_ArmoryBuildIconPicker_Gamepad:Deactivate()
    self.armoryBuildIconPickerGridList:Deactivate()
end