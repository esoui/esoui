---------------------------
--Guild Rank Icon Picker --
---------------------------

ZO_GUILD_RANK_RANK_ICON_PICKER_PICK_GAMEPAD_SIZE = 75
ZO_GUILD_RANK_RANK_ICON_PICKER_PICK_GAMEPAD_OFFSET = 30
ZO_GUILD_RANK_RANK_ICON_PICKER_ICON_GAMEPAD_SIZE = 64
ZO_GUILD_RANK_RANK_ICON_PICKER_ICON_GAMEPAD_OFFSET = 5

ZO_GuildRankIconPicker_Gamepad = ZO_GuildRankIconPicker_Shared:Subclass()

function ZO_GuildRankIconPicker_Gamepad:New(...)
    return ZO_GuildRankIconPicker_Shared.New(self, ...)
end

function ZO_GuildRankIconPicker_Gamepad:Initialize(control)
    local templateData =
    {
        gridListClass = ZO_GridScrollList_Gamepad,
        entryTemplate = "ZO_GuildRank_RankIconPickerIcon_Gamepad_Control",
        entryWidth = ZO_GUILD_RANK_RANK_ICON_PICKER_PICK_GAMEPAD_SIZE,
        entryHeight = ZO_GUILD_RANK_RANK_ICON_PICKER_PICK_GAMEPAD_SIZE,
        entryPaddingX = ZO_GUILD_RANK_RANK_ICON_PICKER_PICK_GAMEPAD_OFFSET,
        entryPaddingY = ZO_GUILD_RANK_RANK_ICON_PICKER_PICK_GAMEPAD_OFFSET,
        narrationText = function(entryData)
            local formatter = entryData.isCurrent() and SI_GAMEPAD_GUILD_RANK_SELECTED_ICON_NARRATION_FORMATTER or SI_GAMEPAD_GUILD_RANK_ICON_NARRATION_FORMATTER
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(formatter, entryData.iconIndex))
        end,
    }

    ZO_GuildRankIconPicker_Shared.Initialize(self, control, templateData)

    self:InitializeRankIconPickerGridList()
end

function ZO_GuildRankIconPicker_Gamepad:InitializeRankIconPickerGridList()
    ZO_GuildRankIconPicker_Shared.InitializeRankIconPickerGridList(self)

    self.rankIconPickerGridList:SetOnSelectedDataChangedCallback(function(...) self:OnRankIconPickerGridSelectionChanged(...) end)
end

function ZO_GuildRankIconPicker_Gamepad:OnRankIconPickerGridSelectionChanged(oldSelectedData, selectedData)
    -- Deselect previous tile
    if oldSelectedData and oldSelectedData.dataEntry then
        oldSelectedData.isSelected = false
    end

    -- Select newly selected tile.
    if selectedData and selectedData.dataEntry then
        selectedData.isSelected = true
    end

    self.rankIconPickerGridList:RefreshGridList()
end

function ZO_GuildRankIconPicker_Gamepad:OnRankIconPickerEntrySetup(control, data)
    local iconTexture = control:GetNamedChild("Icon")
    local pickedControl = control:GetNamedChild("CurrentIconIndicator")

    local isCurrent = data.isCurrent
    if type(isCurrent) == "function" then
        isCurrent = isCurrent()
    end

    iconTexture:SetTexture(GetGuildRankLargeIcon(data.iconIndex))
    pickedControl:SetHidden(not isCurrent)
end

function ZO_GuildRankIconPicker_Gamepad:OnRankIconPickerSelectedGridListEntryClicked()
    local selectedData = self.rankIconPickerGridList:GetSelectedData()
    if selectedData and self.rankIconPickedCallback then
        self.rankIconPickedCallback(selectedData.iconIndex)
    end
    self.rankIconPickerGridList:RefreshGridList()
end

function ZO_GuildRankIconPicker_Gamepad:Activate()
    self.rankIconPickerGridList:Activate()
end

function ZO_GuildRankIconPicker_Gamepad:Deactivate()
    self.rankIconPickerGridList:Deactivate()
end