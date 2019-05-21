------------------
-- Guild Finder --
------------------

ZO_GUILD_BROWSER_APPLICATIONS_ENTRY_SORT_KEYS =
{
    ["guildName"] = { },
    ["durationS"] = { tiebreaker = "guildName" },
}

ZO_GuildBrowser_Applications_Shared = ZO_GuildFinder_Panel_Shared:Subclass()

function ZO_GuildBrowser_Applications_Shared:New(...)
    return ZO_GuildFinder_Panel_Shared.New(self, ...)
end

function ZO_GuildBrowser_Applications_Shared:Initialize(control)
    ZO_GuildFinder_Panel_Shared.Initialize(self, control)

    local function OnAccountApplicationResultsReady()
        if self:GetFragment():IsShowing() then
            self:RefreshData()
        end
    end

    GUILD_BROWSER_MANAGER:RegisterCallback("OnApplicationsChanged", OnAccountApplicationResultsReady)
end

function ZO_GuildBrowser_Applications_Shared:OnShowing()
    self:RefreshData()
end

function ZO_GuildBrowser_Applications_Shared:SetupRow(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)

    local guildNameLabel = control:GetNamedChild("Name")
    local expirationLabel = control:GetNamedChild("Expires")

    local guildInfo = ZO_AllianceIconNameFormatter(data.guildAlliance, data.guildName)
    guildNameLabel:SetText(guildInfo)
    local timeRemainingS = GetGuildFinderAccountApplicationDuration(data.index)
    expirationLabel:SetText(ZO_FormatCountdownTimer(timeRemainingS))
end