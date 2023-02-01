------------------
-- Guild Finder --
------------------

ZO_GUILD_BROWSER_GUILD_LIST_GAMEPAD_ENTRY_HEIGHT = 240

ZO_GuildBrowser_GuildList_Gamepad = ZO_Object.MultiSubclass(ZO_GuildBrowser_GuildList_Shared, ZO_GuildFinder_Panel_GamepadBehavior, ZO_SortFilterList_Gamepad)

function ZO_GuildBrowser_GuildList_Gamepad:New(...)
    return ZO_GuildFinder_Panel_GamepadBehavior.New(self, ...)
end

function ZO_GuildBrowser_GuildList_Gamepad:Initialize(control)
    ZO_GuildBrowser_GuildList_Shared.Initialize(self, control)
    ZO_GuildFinder_Panel_GamepadBehavior.Initialize(self, control)
    ZO_SortFilterList_Gamepad.Initialize(self, control, "ZO_GamepadInteractiveSortFilterThickHighlight")

    self:SetAutomaticallyColorRows(false)

    ZO_ScrollList_AddDataType(self.list, ZO_GUILD_BROWSER_GUILD_LIST_ENTRY_TYPE, "ZO_GuildBrowser_GuildList_Row_Gamepad", ZO_GUILD_BROWSER_GUILD_LIST_GAMEPAD_ENTRY_HEIGHT, function(control, data) self:SetupRow(control, data) end)
end

function ZO_GuildBrowser_GuildList_Gamepad:InitializeKeybinds()
    ZO_GuildFinder_Panel_GamepadBehavior.InitializeKeybinds(self)
    table.insert(self.keybindStripDescriptor,
        -- select
        {
            name = GetString(SI_GUILD_BROWSER_GUILD_LIST_VIEW_GUILD_INFO_KEYBIND),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    GUILD_BROWSER_GAMEPAD:ShowGuildInfo(selectedData.guildId)
                end
            end,
        }
    )

    table.insert(self.keybindStripDescriptor,
        -- filters dialog
        {
            name = GetString(SI_GAMEPAD_GUILD_BROWSER_FILTERS_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local dialogName = "GAMEPAD_GUILD_BROWSER_FILTERS"
                ZO_Dialogs_ShowGamepadDialog(dialogName)
            end,
        }
    )

    table.insert(self.keybindStripDescriptor,
        -- report
        {
            name = GetString(SI_GUILD_BROWSER_REPORT_GUILD_KEYBIND),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            callback = function()
                local selectedData = self:GetSelectedData()
                if selectedData then
                    local function ReportCallback()
                        GUILD_BROWSER_MANAGER:AddReportedGuild(selectedData.guildId)
                    end
                    self:Deactivate()
                    GUILD_BROWSER_GAMEPAD:OnReportingGuild()
                    ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportGuildTicketScene(selectedData.guildName, CUSTOMER_SERVICE_ASK_FOR_HELP_REPORT_GUILD_CATEGORY_INAPPROPRIATE_LISTING, ReportCallback)
                end
            end,
        }
    )
end

function ZO_GuildBrowser_GuildList_Gamepad:PopulateList()
    ZO_GuildBrowser_GuildList_Shared.PopulateList(self)

    if self.isActive then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        if #scrollData == 0 then
            --If the cursor is in the list, but the list is empty because of a filter, we need to force it out of the panel area
            self:EndSelection()
        else
            -- if we've lost our selection and the panelFocalArea is active, then we want to
            -- AutoSelect the next appropriate entry
            local selectedData = ZO_ScrollList_GetSelectedData(self.list)
            if not selectedData then
                local ANIMATE_INSTANTLY = true
                ZO_ScrollList_AutoSelectData(self.list, ANIMATE_INSTANTLY)
            end
        end
    end
end

function ZO_GuildBrowser_GuildList_Gamepad:SetupRow(control, data)
    ZO_GuildBrowser_GuildList_Shared.SetupRow(self, control, data)

    control.guildSizeHeaderLabel:SetText(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_SIZE))
    control.guildSizeLabel:SetText(data.size)
end

function ZO_GuildBrowser_GuildList_Gamepad:UpdateResultsLabel()
    ZO_GuildBrowser_GuildList_Shared.UpdateResultsLabel(self)

    if self.focusType == nil then
        self.resultsLabel:SetText(GetString(SI_GAMEPAD_GUILD_BROWSER_GUILD_LIST_START_SEARCHING))
        self.resultsLabel:SetHidden(false)
    end
end

function ZO_GuildBrowser_GuildList_Gamepad:RefreshList()
    ZO_GuildBrowser_GuildList_Shared.RefreshList(self)
    if self.isActive then
        ZO_ScrollList_ResetAutoSelectIndex(self.list)
        ZO_ScrollList_AutoSelectData(self.list)
    end
end

function ZO_GuildBrowser_GuildList_Gamepad:SetupRowContextualInfo(control, data)
    local contextualInfoHeader, contextualInfoValue = self:GetRowContextualInfo(data)
    control.guildContextualInfoHeaderLabel:SetText(contextualInfoHeader)
    control.guildContextualInfoValueLabel:SetText(zo_strformat(SI_GAMEPAD_GUILD_BROWSER_GUILD_LIST_CONTEXTUAL_INFO_FORMATTER, contextualInfoValue))
end

function ZO_GuildBrowser_GuildList_Gamepad:SetFocusType(focusType)
    self.focusType = focusType
    SetGuildFinderFocusSearchFilter(self.focusType)
end

function ZO_GuildBrowser_GuildList_Gamepad:RefreshSearchFilters()
    SetGuildFinderFocusSearchFilter(self.focusType)
    GUILD_BROWSER_GAMEPAD:RefreshSearchFilters()
end

function ZO_GuildBrowser_GuildList_Gamepad:ResetFilters()
    GUILD_BROWSER_GAMEPAD:ResetFilters()
    self:RefreshSearchFilters()
end

function ZO_GuildBrowser_GuildList_Gamepad:Activate()
    ZO_SortFilterList_Gamepad.Activate(self)
    ZO_GuildFinder_Panel_GamepadBehavior.Activate(self)
end

function ZO_GuildBrowser_GuildList_Gamepad:Deactivate()
    ZO_SortFilterList_Gamepad.Deactivate(self)
    ZO_GuildFinder_Panel_GamepadBehavior.Deactivate(self)
end

function ZO_GuildBrowser_GuildList_Gamepad:GetAllianceIcon(alliance)
    return ZO_GetLargeAllianceSymbolIcon(alliance)
end

function ZO_GuildBrowser_GuildList_Gamepad:OnShowing()
    ZO_GuildBrowser_GuildList_Shared.OnShowing(self)
    self:RefreshSearchFilters()
    self:UpdateResultsLabel()

    local scrollData = ZO_ScrollList_GetDataList(self.list)
    if self.focusType == nil or (#scrollData <= 0 and GUILD_BROWSER_MANAGER:HasCurrentFoundGuilds()) then
        self:RefreshList()
    end
end

function ZO_GuildBrowser_GuildList_Gamepad:OnHidden()
    ZO_GuildBrowser_GuildList_Shared.OnHidden(self)
end

--Overridden from base
function ZO_GuildBrowser_GuildList_Gamepad:GetHeaderNarration()
    return SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_GUILD_BROWSER_GUILD_LIST_HEADER))
end

--Overridden from base
function ZO_GuildBrowser_GuildList_Gamepad:GetNarrationText()
    local selectedData = self:GetSelectedData()
    if selectedData then
        local narrations = {}
        --Generate the narration for the alliance
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_CachedStrFormat(SI_ALLIANCE_NAME, GetAllianceName(selectedData.alliance))))

        --Generate the narration for the guild name
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.guildName))

        --Generate the narration for the active members
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_GUILDMETADATAATTRIBUTE", GUILD_META_DATA_ATTRIBUTE_SIZE)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.size))

        --Generate the contextual info narration
        local contextualInfoHeader, contextualInfoValue = self:GetRowContextualInfo(selectedData)
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(contextualInfoHeader))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(contextualInfoValue))

        --Generate the narration for the guild message
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedData.headerMessage))
        return narrations
    end
end

-- XML Functions
-----------------

function ZO_GuildBrowser_GuildList_Gamepad_OnInitialized(control)
    GUILD_BROWSER_GUILD_LIST_GAMEPAD = ZO_GuildBrowser_GuildList_Gamepad:New(control)
end
