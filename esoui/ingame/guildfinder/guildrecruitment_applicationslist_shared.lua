------------------
-- Guild Finder --
------------------

ZO_GUILD_RECRUITMENT_APPLICATIONS_ENTRY_SORT_KEYS =
{
    ["name"] = { },
    ["levelPlusChampionPoints"] = { tiebreaker = "name" },
    ["durationS"] = { tiebreaker = "name" },
}

ZO_GuildRecruitment_ApplicationsList_Shared = ZO_GuildRecruitment_Shared:Subclass()

function ZO_GuildRecruitment_ApplicationsList_Shared:New(...)
    return ZO_GuildRecruitment_Shared.New(self, ...)
end

function ZO_GuildRecruitment_ApplicationsList_Shared:Initialize(control)
    ZO_GuildRecruitment_Shared.Initialize(self, control)

    local function OnGuildApplicationResultsReady()
        if self:GetFragment():IsShowing() then
            self:RefreshData()
        end
    end

    GUILD_RECRUITMENT_MANAGER:RegisterCallback("GuildApplicationResultsReady", OnGuildApplicationResultsReady)
end

function ZO_GuildRecruitment_ApplicationsList_Shared:SetGuildId(guildId)
    self.guildId = guildId
end

function ZO_GuildRecruitment_ApplicationsList_Shared:OnShowing()
    self:RefreshData()
end

function ZO_GuildRecruitment_ApplicationsList_Shared:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    local numApplications = GetGuildFinderNumGuildApplications(self.guildId)
    for i = 1, numApplications do
        local level, championPoints, alliance, classId, accountName, characterName, achievementPoints, applicationMessage = GetGuildFinderGuildApplicationInfoAt(self.guildId, i)
        local timeRemainingS = GetGuildFinderGuildApplicationDuration(self.guildId, i)
        local data =
        {
            guildId = self.guildId,
            index = i,
            name = accountName,
            characterName = characterName,
            level = level,
            class = classId,
            alliance = alliance,
            championPoints = championPoints,
            achievementPoints = achievementPoints,
            message = applicationMessage,
            durationS = timeRemainingS,
            levelPlusChampionPoints = level + championPoints,
        }
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ZO_GUILD_FINDER_APPLICATION_ENTRY_TYPE, data))
    end
end

function ZO_GuildRecruitment_ApplicationsList_Shared:SetupRow(control, data)
    local nameLabel = control:GetNamedChild("Name")
    local levelLabel = control:GetNamedChild("Level")
    local expirationLabel = control:GetNamedChild("Expires")

    nameLabel:SetText(data.name)
    local levelText = ZO_GetLevelOrChampionPointsString(data.level, data.championPoints, data.iconSize)
    levelLabel:SetText(levelText)
    local timeRemainingS = GetGuildFinderGuildApplicationDuration(self.guildId, data.index)
    expirationLabel:SetText(ZO_FormatCountdownTimer(timeRemainingS))
end