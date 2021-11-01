---------------------------
--Armory Build Icon Picker --
---------------------------

ZO_ARMORY_BUILD_ICON_PICKER_PICK_KEYBOARD_SIZE = 60
ZO_ARMORY_BUILD_ICON_PICKER_PICK_KEYBOARD_PADDING = 0
ZO_ARMORY_BUILD_ICON_PICKER_ICON_KEYBOARD_SIZE = 48
ZO_ARMORY_BUILD_ICON_PICKER_ICON_KEYBOARD_OFFSET = 10

ZO_ArmoryBuildIconPicker_Keyboard = ZO_ArmoryBuildIconPicker_Shared:Subclass()

function ZO_ArmoryBuildIconPicker_Keyboard:Initialize(control)
    local templateData =
    {
        gridListClass = ZO_GridScrollList_Keyboard,
        entryTemplate = "ZO_ArmoryBuild_BuildIconPickerIcon_Keyboard_Control",
        entryWidth = ZO_ARMORY_BUILD_ICON_PICKER_PICK_KEYBOARD_SIZE,
        entryHeight = ZO_ARMORY_BUILD_ICON_PICKER_PICK_KEYBOARD_SIZE,
        entryPaddingX = ZO_ARMORY_BUILD_ICON_PICKER_PICK_KEYBOARD_PADDING,
        entryPaddingY = ZO_ARMORY_BUILD_ICON_PICKER_PICK_KEYBOARD_PADDING,
    }

    ZO_ArmoryBuildIconPicker_Shared.Initialize(self, control, templateData)

    self:InitializeArmoryBuildIconPickerGridList()
end

function ZO_ArmoryBuildIconPicker_Keyboard:OnArmoryBuildIconPickerEntrySetup(control, data)
    local iconContainer = control:GetNamedChild("IconContainer")
    local checkButton = iconContainer:GetNamedChild("Frame")

    local isCurrent = data.isCurrent
    if type(isCurrent) == "function" then
        isCurrent = isCurrent()
    end

    local function OnClick()
        self:OnArmoryBuildIconPickerGridListEntryClicked(data.iconIndex)
    end

    iconContainer:GetNamedChild("Icon"):SetTexture(ZO_ARMORY_MANAGER:GetBuildIcon(data.iconIndex))
    ZO_CheckButton_SetCheckState(checkButton, isCurrent)
    ZO_CheckButton_SetToggleFunction(checkButton, OnClick)
end

function ZO_ArmoryBuildIconPicker_Keyboard:SetArmoryBuildIconPicked(iconIndex)
    ZO_ArmoryBuildIconPicker_Shared.SetArmoryBuildIconPicked(self, iconIndex)

    self:RefreshGridList()
    PlaySound(SOUNDS.GUILD_RANK_LOGO_SELECTED)
end

function ZO_ArmoryBuildIconPicker_Keyboard:OnArmoryBuildIconPickerGridListEntryClicked(newIconIndex)
    self:SetArmoryBuildIconPicked(newIconIndex)
end