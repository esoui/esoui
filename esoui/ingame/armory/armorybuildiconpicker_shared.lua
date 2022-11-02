---------------------------
-- Armory Build Icon Picker --
---------------------------

ZO_ArmoryBuildIconPicker_Shared = ZO_InitializingObject:Subclass()

function ZO_ArmoryBuildIconPicker_Shared:Initialize(control, templateData)
    self.control = control

    -- This is platform specific data that needs to be overridden by the inheriting classes as it
    -- specifies the platform specific data to use.
    --[[ Expected Attributes for Icon Picker
        gridListClass - The class object from which self.armoryBuildIconPickerGridList will be created,
        entryTemplate - The name of the template control to be used for an icon in the view that allows an armory biuild to select its icon,
        entryWidth - The width to be used for the the entryTemplate,
        entryHeight - The height to be used for the entryTemplate,
        entryPaddingX - The padding in pixels between icons horizontally,
        entryPaddingY - The padding in pixels between icons vertically,
        narrationText - Optional: The text used to narrate the entry when using screen narration. Can be a function or a string
    ]]
    self.templateData = templateData
end

function ZO_ArmoryBuildIconPicker_Shared:OnArmoryBuildIconPickerEntrySetup(control, data)
    assert(false) -- override in derived function
end

function ZO_ArmoryBuildIconPicker_Shared:InitializeArmoryBuildIconPickerGridList()
    local templateData = self.templateData

    self.armoryBuildIconPickerGridList = templateData.gridListClass:New(self.control)

    local function armoryBuildIconPickerEntrySetup(control, data)
        self:OnArmoryBuildIconPickerEntrySetup(control, data)
    end

    local HIDE_CALLBACK = nil
    self.armoryBuildIconPickerGridList:AddEntryTemplate(templateData.entryTemplate, templateData.entryWidth, templateData.entryHeight, armoryBuildIconPickerEntrySetup, HIDE_CALLBACK, nil, templateData.entryPaddingX, templateData.entryPaddingY)

    self:BuildArmoryBuildIconPickerGridList()
end

function ZO_ArmoryBuildIconPicker_Shared:OnArmoryBuildIconPickerGridListEntryClicked()
    assert(false) -- override in derived function
end

function ZO_ArmoryBuildIconPicker_Shared:SetupIconPickerForArmoryBuild(buildData)
    self.iconIndex = buildData:GetIconIndex()
end

function ZO_ArmoryBuildIconPicker_Shared:SetArmoryBuildIconPicked(iconIndex)
    self.iconIndex = iconIndex
end

function ZO_ArmoryBuildIconPicker_Shared:GetSelectedArmoryBuildIconIndex()
    return self.iconIndex
end

function ZO_ArmoryBuildIconPicker_Shared:CreateArmoryBuildIconPickerDataObject(index)
    local data =
    {
        iconIndex = index,
        isCurrent = function()
            local selectedIconIndex = self:GetSelectedArmoryBuildIconIndex()
            return selectedIconIndex and selectedIconIndex == index or false
        end,
        narrationText = self.templateData.narrationText,
    }
    return data
end

function ZO_ArmoryBuildIconPicker_Shared:BuildArmoryBuildIconPickerGridList()
    self.armoryBuildIconPickerGridList:ClearGridList()

    local templateData = self.templateData
    for i = 1, ZO_ARMORY_NUM_BUILD_ICONS do
        local data = self:CreateArmoryBuildIconPickerDataObject(i)
        self.armoryBuildIconPickerGridList:AddEntry(data, templateData.entryTemplate)
    end

    self.armoryBuildIconPickerGridList:CommitGridList()
end

function ZO_ArmoryBuildIconPicker_Shared:ScrollToSelectedData()
    for _, dataEntry in pairs(self.armoryBuildIconPickerGridList:GetData()) do
        if dataEntry.data.isCurrent() then
            local NO_CALLBACK = nil
            local ANIMATE_INSTANTLY = true
            self.armoryBuildIconPickerGridList:ScrollDataToCenter(dataEntry.data, NO_CALLBACK, ANIMATE_INSTANTLY)
        end
    end
end

function ZO_ArmoryBuildIconPicker_Shared:RefreshGridList()
    self.armoryBuildIconPickerGridList:RefreshGridList()
end