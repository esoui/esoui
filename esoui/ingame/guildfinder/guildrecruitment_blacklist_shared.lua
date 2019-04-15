------------------
-- Guild Finder --
------------------
ZO_GUILD_RECRUITMENT_BLACKLIST_ENTRY_TYPE = 1

ZO_GUILD_RECRUITMENT_BLACKLIST_ENTRY_SORT_KEYS =
{
    ["name"] = { },
}

ZO_GuildRecruitment_Blacklist_Shared = ZO_GuildRecruitment_Shared:Subclass()

function ZO_GuildRecruitment_Blacklist_Shared:New(...)
    return ZO_GuildRecruitment_Shared.New(self, ...)
end

function ZO_GuildRecruitment_Blacklist_Shared:Initialize(control)
    ZO_GuildRecruitment_Shared.Initialize(self, control)

    local function OnGuildBlacklistResultsReady()
        if self:GetFragment():IsShowing() then
            self:RefreshData()
        end
    end

    GUILD_RECRUITMENT_MANAGER:RegisterCallback("GuildBlacklistResultsReady", OnGuildBlacklistResultsReady)
end

function ZO_GuildRecruitment_Blacklist_Shared:OnShowing()
    self:RefreshData()
end

function ZO_GuildRecruitment_Blacklist_Shared:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    local numBlacklist = GetNumGuildBlacklistEntries(self.guildId)
    for i = 1, numBlacklist do
        local accountName, note = GetGuildBlacklistInfoAt(self.guildId, i)
        local data =
        {
            guildId = self.guildId,
            index = i,
            name = accountName,
            note = note,
        }
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ZO_GUILD_RECRUITMENT_BLACKLIST_ENTRY_TYPE, data))
    end
end

function ZO_GuildRecruitment_Blacklist_Shared:SetupRow(control, data)
    local nameLabel = control:GetNamedChild("Name")
    nameLabel:SetText(data.name)
end