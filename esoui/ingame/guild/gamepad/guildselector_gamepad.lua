ZO_GuildSelector_Gamepad = ZO_ComboBox_Gamepad:Subclass()

function ZO_GuildSelector_Gamepad:New(...)
    return ZO_ComboBox_Gamepad.New(self, ...)
end

function ZO_GuildSelector_Gamepad:Initialize(...)
    ZO_ComboBox_Gamepad.Initialize(self, ...)
    self.entries = {}
    self:SetSortsItems(false)

    self.OnGuildChanged = function (_, entryText, entry)
        self:SelectGuild(entry)
    end

    self.filterFunction = function(guildId)
        return DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_GUILD_KIOSK_BID)
    end

    local function RefreshGuildList()
        self:RefreshGuildList()
    end


    self.m_container:SetHandler("OnEffectivelyShown", function()
        EVENT_MANAGER:RegisterForEvent("GuildSelectorGamepad", EVENT_GUILD_DATA_LOADED, RefreshGuildList)
    end)

    self.m_container:SetHandler("OnEffectivelyHidden", function()
        EVENT_MANAGER:UnregisterForEvent("GuildSelectorGamepad", EVENT_GUILD_DATA_LOADED)
    end)

    self:RefreshGuildList()
end

function ZO_GuildSelector_Gamepad:SetGuildFilter(filterFunction)
    self.filterFunction = filterFunction
end

function ZO_GuildSelector_Gamepad:SelectGuild(selectedEntry)
    if selectedEntry then
        self.guildId = selectedEntry.guildId
        self.control:SetSelectedItemText(selectedEntry.selectedText)

        if self.OnSelectionChanged then
            self.OnSelectionChanged(selectedEntry)
        end
    end
end

function ZO_GuildSelector_Gamepad:RefreshGuildList()
    ZO_ClearTable(self.entries)
    self:ClearItems()
    for i = 1, GetNumGuilds() do
        local guildId = GetGuildId(i)
        if not self.filterFunction or self.filterFunction(guildId) then
            local guildName = GetGuildName(guildId)
            local guildAlliance = GetGuildAlliance(guildId)
            local guildText = zo_iconTextFormat(GetLargeAllianceSymbolIcon(guildAlliance), 32, 32, guildName)
            local entry = self:CreateItemEntry(guildText, self.OnGuildSelected)
            entry.guildId = guildId
            entry.guildText = guildText

            if self.OnGuildsRefreshed then
                self.OnGuildsRefreshed(entry)
            end

            self.entries[guildId] = entry
            self:AddItem(entry)
        end
    end

    if next(self.entries) == nil then
        return false
    end

    self.highlightedIndex = 1
    self:SelectFirstItem()
    return true
end

function ZO_GuildSelector_Gamepad:SetOnGuildsRefreshed(OnGuildsRefreshed)
    self.OnGuildsRefreshed = OnGuildsRefreshed
end

function ZO_GuildSelector_Gamepad:OnGuildSelected(itemName, item)
    if self.OnGuildSelectedCallback then
        self.OnGuildSelectedCallback(item)
    end
end

function ZO_GuildSelector_Gamepad:SetOnGuildSelectedCallback(OnGuildSelectedCallback)
    self.OnGuildSelectedCallback = OnGuildSelectedCallback
end