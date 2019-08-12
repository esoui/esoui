------------------
-- Guild Ranks Manager --
------------------

ZO_GuildRanks_Manager = ZO_CallbackObject:Subclass()

function ZO_GuildRanks_Manager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_GuildRanks_Manager:Initialize()
    self:BuildPermissionsGridData()
end

function ZO_GuildRanks_Manager:BuildPermissionsGridData()
    self.permissionsCategories =
    {
        CHAT_CATEGORY = 1,
        MEMBERS_CATEGORY = 2,
        COMMERCE_CATEGORY = 3,
        EDIT_CATEGORY = 4,
        ALLIANCE_WAR_CATEGORY = 5,
    }

    self.permissionsLayout =
    {
        [self.permissionsCategories.CHAT_CATEGORY] =
        {
            header = GetString(IsConsoleUI() and SI_GUILD_RANK_PERMISSIONS_VOICE_CHAT or SI_GUILD_RANK_PERMISSIONS_CHAT),
            permissions =
            {
                GUILD_PERMISSION_CHAT,
                GUILD_PERMISSION_OFFICER_CHAT_WRITE,
                GUILD_PERMISSION_OFFICER_CHAT_READ,
            },
        },
        [self.permissionsCategories.MEMBERS_CATEGORY] =
        {
            header = GetString(SI_GUILD_RANK_PERMISSIONS_MEMBERS),
            permissions =
            {
                GUILD_PERMISSION_MANAGE_APPLICATIONS,
                GUILD_PERMISSION_NOTE_READ,
                GUILD_PERMISSION_INVITE,
                GUILD_PERMISSION_NOTE_EDIT,
                GUILD_PERMISSION_MANAGE_BLACKLIST,
                GUILD_PERMISSION_PROMOTE,
                GUILD_PERMISSION_REMOVE,
                GUILD_PERMISSION_DEMOTE,
            },
        },
        [self.permissionsCategories.COMMERCE_CATEGORY] =
        {
            header = GetString(SI_GUILD_RANK_PERMISSIONS_COMMERCE),
            permissions =
            {
                GUILD_PERMISSION_BANK_WITHDRAW,
                GUILD_PERMISSION_BANK_WITHDRAW_GOLD,
                GUILD_PERMISSION_BANK_DEPOSIT,
                GUILD_PERMISSION_BANK_VIEW_GOLD,
                GUILD_PERMISSION_STORE_SELL,
                GUILD_PERMISSION_GUILD_KIOSK_BID,
            },
        },
        [self.permissionsCategories.EDIT_CATEGORY] =
        {
            header = GetString(SI_GUILD_RANK_PERMISSIONS_GUILD_INFO),
            permissions =
            {
                GUILD_PERMISSION_SET_MOTD,
                GUILD_PERMISSION_DESCRIPTION_EDIT,
            },
        },
        [self.permissionsCategories.ALLIANCE_WAR_CATEGORY] =
        {
            header = GetString(SI_GUILD_RANK_PERMISSIONS_ALLIANCE_WAR),
            permissions =
            {
                GUILD_PERMISSION_CLAIM_AVA_RESOURCE,
                GUILD_PERMISSION_RELEASE_AVA_RESOURCE,
            },
        },
    }
end

function ZO_GuildRanks_Manager:GetPermissionsLayout()
    return self.permissionsLayout
end

GUILD_RANKS_MANAGER = ZO_GuildRanks_Manager:New()