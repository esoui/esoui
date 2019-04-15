------------------
-- Guild Finder --
------------------

ZO_GuildRecruitment_Applications_Keyboard = ZO_Object.MultiSubclass(ZO_GuildFinder_Applications_Keyboard, ZO_GuildRecruitment_Shared)

function ZO_GuildRecruitment_Applications_Keyboard:New(...)
    return ZO_GuildFinder_Applications_Keyboard.New(self, ...)
end

function ZO_GuildRecruitment_Applications_Keyboard:Initialize(control)
    ZO_GuildFinder_Applications_Keyboard.Initialize(self, control)
    ZO_GuildRecruitment_Shared.Initialize(self, control)
end

function ZO_GuildRecruitment_Applications_Keyboard:SetGuildId(guildId)
    ZO_GuildRecruitment_Shared.SetGuildId(self, guildId)

    for _, manager in pairs(self.subcategoryManagers) do
        manager:SetGuildId(guildId)
    end
end

GUILD_RECRUITMENT_APPLICATIONS_KEYBOARD = ZO_GuildRecruitment_Applications_Keyboard:New(control)