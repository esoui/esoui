------------------
-- Guild Finder --
------------------

ZO_GuildRecruitment_GuildListingInfo_Shared = ZO_GuildRecruitment_Panel_Shared:Subclass()

function ZO_GuildRecruitment_GuildListingInfo_Shared:New(...)
    return ZO_GuildRecruitment_Panel_Shared.New(self, ...)
end

function ZO_GuildRecruitment_GuildListingInfo_Shared:Initialize(control)
    ZO_GuildRecruitment_Panel_Shared.Initialize(self, control)

    local function OnGuildMembershipChanged(guildId)
        if guildId == self.guildId then
            self:UpdateAlert()
        end
    end

    local function OnGuildInfoChanged(guildId)
        if guildId == self.guildId then
            self:RefreshData()
        end
    end

    GUILD_RECRUITMENT_MANAGER:RegisterCallback("GuildMembershipChanged", OnGuildMembershipChanged)
    GUILD_RECRUITMENT_MANAGER:RegisterCallback("GuildInfoChanged", OnGuildInfoChanged)
end

function ZO_GuildRecruitment_GuildListingInfo_Shared:SetGuildId(guildId)
    self.guildId = guildId

    self:RefreshData()
end

function ZO_GuildRecruitment_GuildListingInfo_Shared:UpdateAlert(value)
    -- To be overridden
end

function ZO_GuildRecruitment_GuildListingInfo_Shared:RefreshData()
    local guildId = self.guildId
    local recruitmentMessage, headerMessage, recruitmentStatus, primaryFocus, secondaryFocus, personality, language, minimumCP = GetGuildRecruitmentInfo(guildId)
    self.currentData = {}
    self.currentData.recruitmentStatus = recruitmentStatus
    self.currentData.primaryFocus = primaryFocus
    self.currentData.secondaryFocus = secondaryFocus
    self.currentData.personality = personality
    self.currentData.language = language
    self.currentData.recruitmentHeadline = headerMessage
    self.currentData.description = recruitmentMessage
    self.currentData.startTimeHour = GetGuildRecruitmentStartTime(guildId)
    self.currentData.endTimeHour = GetGuildRecruitmentEndTime(guildId)
    self.currentData.minimumCP = minimumCP

    self.currentData.roles = {}
    for i, role in ipairs(ZO_GUILD_FINDER_ROLE_ORDER) do
        if DoesGuildHaveRoleAttribute(guildId, role) then
            table.insert(self.currentData.roles, role)
        end
    end

    self.currentData.activitiesText = ZO_GuildFinder_Manager.GetAttributeCommaFormattedList(guildId, GUILD_ACTIVITY_ATTRIBUTE_VALUE_ITERATION_BEGIN, GUILD_ACTIVITY_ATTRIBUTE_VALUE_ITERATION_END, GetGuildRecruitmentActivityValue, "SI_GUILDACTIVITYATTRIBUTEVALUE")

    self:RefreshInfoPanel()

    self:UpdateAlert()
end

function ZO_GuildRecruitment_GuildListingInfo_Shared:RefreshInfoPanel()
    -- To be overridden
end

function ZO_GuildRecruitment_GuildListingInfo_Shared:OnShowing()
    self:RefreshData()
end

function ZO_GuildRecruitment_GuildListingInfo_Shared:OnHidden()

end