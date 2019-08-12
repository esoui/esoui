---------------------------
--Guild Rank Icon Picker --
---------------------------

ZO_GuildRankIconPicker_Shared = ZO_Object:Subclass()

function ZO_GuildRankIconPicker_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GuildRankIconPicker_Shared:Initialize(control)
    self.control = control

    -- This is platform specific data that needs to be overridden by the inheriting classes as it
    -- specifies the platform specific data to use.
    self.templateData =
    {
    --[[ Expected Attributes for Icon Picker
        gridListClass - The class object from which self.rankIconPickerGridList will be created,
        entryTemplate - The name of the template control to be used for an icon in the view that allows a guild rank to select its icon,
        entryWidth - The width to be used for the the entryTemplate,
        entryHeight - The height to be used for the entryTemplate,
        entryPaddingX - The padding in pixels between icons horizontally,
        entryPaddingY - The padding in pixels between icons vertically,
    ]]
    }

    self:InitializeGridListDataPool()
end

function ZO_GuildRankIconPicker_Shared:InitializeGridListDataPool()
    -- Create Data Object Pool
    local function CreateEntryData()
        return ZO_GridSquareEntryData_Shared:New()
    end

    local function ResetEntryData(data)
        data:SetDataSource(nil)
    end

    self.rankIconPickerEntryDataObjectPool = ZO_ObjectPool:New(CreateEntryData, ResetEntryData)
end

function ZO_GuildRankIconPicker_Shared:OnRankIconPickerEntrySetup(control, data)
    assert(false) -- override in derived function
end

function ZO_GuildRankIconPicker_Shared:InitializeRankIconPickerGridList()
    local templateData = self.templateData

    self.rankIconPickerGridList = templateData.gridListClass:New(self.control)

    local function rankIconPickerEntrySetup(control, data)
        self:OnRankIconPickerEntrySetup(control, data)
    end

    local HIDE_CALLBACK = nil
    self.rankIconPickerGridList:AddEntryTemplate(templateData.entryTemplate, templateData.entryWidth, templateData.entryHeight, rankIconPickerEntrySetup, HIDE_CALLBACK, nil, templateData.entryPaddingX, templateData.entryPaddingY)

    self:BuildRankIconPickerGridList()
end

function ZO_GuildRankIconPicker_Shared:OnRankIconPickerGridListEntryClicked()
    assert(false) -- override in derived function
end

function ZO_GuildRankIconPicker_Shared:SetGetSelectedRankFunction(func)
    self.getSelectedRankFunc = func
end

function ZO_GuildRankIconPicker_Shared:SetRankIconPickedCallback(callback)
    self.rankIconPickedCallback = callback
end

function ZO_GuildRankIconPicker_Shared:CreateRankIconPickerDataObject(index)
    local data =
    {
        iconIndex = index,
        isCurrent = function()
            local selectedRank = self.getSelectedRankFunc and self.getSelectedRankFunc()
            return selectedRank and selectedRank:GetIconIndex() == index or false
        end
    }
    return data
end

function ZO_GuildRankIconPicker_Shared:BuildRankIconPickerGridList()
    self.rankIconPickerGridList:ClearGridList()
    self.rankIconPickerEntryDataObjectPool:ReleaseAllObjects()
    local templateData = self.templateData
    for i = 1, GetNumGuildRankIcons() do
        local entryData = self.rankIconPickerEntryDataObjectPool:AcquireObject()
        local data = self:CreateRankIconPickerDataObject(i)
        entryData:SetDataSource(data)
        self.rankIconPickerGridList:AddEntry(entryData, templateData.entryTemplate)
    end

    self.rankIconPickerGridList:CommitGridList()
end

function ZO_GuildRankIconPicker_Shared:RefreshGridList()
    self.rankIconPickerGridList:RefreshGridList()
end