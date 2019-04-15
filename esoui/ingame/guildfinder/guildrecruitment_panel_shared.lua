----------------------------
-- Guild Finder Recruitment Panel --
----------------------------

ZO_GuildRecruitment_Panel_Shared = ZO_Object.MultiSubclass(ZO_GuildFinder_Panel_Shared, ZO_GuildRecruitment_Shared)

function ZO_GuildRecruitment_Panel_Shared:New(...)
    return ZO_GuildFinder_Panel_Shared.New(self, ...)
end

function ZO_GuildRecruitment_Panel_Shared:Initialize(control)
    ZO_GuildFinder_Panel_Shared.Initialize(self, control)
    ZO_GuildRecruitment_Shared.Initialize(self, control)
end