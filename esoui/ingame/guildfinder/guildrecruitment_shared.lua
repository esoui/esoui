------------------
-- Guild Finder --
------------------
ZO_GuildRecruitment_Shared = ZO_Object:Subclass()

function ZO_GuildRecruitment_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GuildRecruitment_Shared:Initialize(control)
    self.control = control

    local function OnGuildPermissionChanged(guildId)
        if guildId == self.guildId then
            self:RefreshGuildPermissionsState()
        end
    end

    GUILD_RECRUITMENT_MANAGER:RegisterCallback("GuildPermissionsChanged", OnGuildPermissionChanged)
end

function ZO_GuildRecruitment_Shared:InitializeDefaultMessageDefaults()
   self.savedMessageFunction = function()
        return GUILD_RECRUITMENT_MANAGER:GetSavedApplicationsDefaultMessage(self.guildId) or ""
    end
end

function ZO_GuildRecruitment_Shared:SetGuildId(guildId)
    self.guildId = guildId
end

function ZO_GuildRecruitment_Shared:RefreshGuildPermissionsState()
    -- To be overridden
end