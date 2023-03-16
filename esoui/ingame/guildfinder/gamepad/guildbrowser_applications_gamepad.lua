------------------
-- Guild Finder --
------------------

ZO_GUILD_BROWSER_APPLICATIONS_GAMEPAD_ENTRY_HEIGHT = 64

ZO_GuildBrowser_Applications_Gamepad = ZO_Object.MultiSubclass(ZO_GuildBrowser_Applications_Shared, ZO_GuildFinder_ListPanel_GamepadBehavior)

function ZO_GuildBrowser_Applications_Gamepad:New(...)
    return ZO_GuildFinder_ListPanel_GamepadBehavior.New(self, ...)
end

function ZO_GuildBrowser_Applications_Gamepad:Initialize(control)
    ZO_GuildBrowser_Applications_Shared.Initialize(self, control)
    ZO_GuildFinder_ListPanel_GamepadBehavior.Initialize(self, control)

    self:SetAutomaticallyColorRows(false)

    local function SetupRow(control, data)
        self:SetupRow(control, data)
    end

    ZO_ScrollList_AddDataType(self.list, ZO_GUILD_FINDER_APPLICATION_ENTRY_TYPE, "ZO_GuildBrowser_Applications_Row_Gamepad", ZO_GUILD_BROWSER_APPLICATIONS_GAMEPAD_ENTRY_HEIGHT, SetupRow)
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")

    self:SetEmptyText(GetString(SI_GUILD_BROWSER_APPLICATIONS_EMPTY_LIST_TEXT))
    self:SetupSort(ZO_GUILD_BROWSER_APPLICATIONS_ENTRY_SORT_KEYS, "durationS", ZO_SORT_ORDER_DOWN)
end

function ZO_GuildBrowser_Applications_Gamepad:InitializeKeybinds()
    ZO_GuildFinder_ListPanel_GamepadBehavior.InitializeKeybinds(self)
    table.insert(self.keybindStripDescriptor,
        -- select
        {
            name = GetString(SI_GAMEPAD_GUILD_BROWSER_CANCEL_APPLICATION_LABEL),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    local guildInfo = ZO_AllianceIconNameFormatter(selectedData.alliance, selectedData.guildName)
                    ZO_Dialogs_ShowGamepadDialog("GUILD_FINDER_RESCIND_APPLICATION", selectedData, { mainTextParams = { ZO_WHITE:Colorize(guildInfo) } })
                end
            end,
        }
    )
end

function ZO_GuildBrowser_Applications_Gamepad:OnCommitComplete()
    GUILD_BROWSER_GAMEPAD:RefreshKeybinds()
end

function ZO_GuildBrowser_Applications_Gamepad:OnSelectionChanged(previousData, selectedData)
    ZO_GuildFinder_ListPanel_GamepadBehavior.OnSelectionChanged(self, previousData, selectedData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)

    if selectedData then
        GAMEPAD_TOOLTIPS:LayoutGuildApplicationDetails(GAMEPAD_RIGHT_TOOLTIP, selectedData)
    end
end

function ZO_GuildBrowser_Applications_Gamepad:BuildMasterList()
    self.currentApplications = GUILD_BROWSER_MANAGER:GetCurrentApplicationsList()
end

function ZO_GuildBrowser_Applications_Gamepad:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for _, data in ipairs(self.currentApplications) do
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ZO_GUILD_FINDER_APPLICATION_ENTRY_TYPE, data))
    end
end

function ZO_GuildBrowser_Applications_Gamepad:CommitScrollList()
    ZO_GuildFinder_ListPanel_GamepadBehavior.CommitScrollList(self)
end

function ZO_GuildBrowser_Applications_Gamepad:OnShowing()
    ZO_GuildBrowser_Applications_Shared.OnShowing(self)
    self:RefreshData()
end

function ZO_GuildBrowser_Applications_Gamepad:OnHidden()
    ZO_GuildBrowser_Applications_Shared.OnHidden(self)
end

function ZO_GuildBrowser_Applications_Gamepad:GetSelectedNarrationText()
    local narrations = {}
    local selectedData = self:GetSelectedData()
    if selectedData then
        --Get the narration for the guild name column
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_NAME)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.guildName))

        --Get the narration for the expiration column
        local timeRemainingS = GetGuildFinderAccountApplicationDuration(selectedData.index)
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GUILD_FINDER_APPLICATIONS_SORT_HEADER_EXPIRATION)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_FormatCountdownTimer(timeRemainingS)))
    end
    return narrations
end

--Overridden from base
function ZO_GuildBrowser_Applications_Gamepad:GetHeaderNarration()
    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GUILD_BROWSER_CATEGORY_APPLICATIONS))
end

-- XML Functions
-----------------

function ZO_GuildBrowser_Applications_Gamepad_OnInitialized(control)
    GUILD_BROWSER_APPLICATIONS_GAMEPAD = ZO_GuildBrowser_Applications_Gamepad:New(control)
end
