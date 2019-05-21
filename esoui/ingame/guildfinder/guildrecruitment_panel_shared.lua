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
    self.guildPermissionRemovedCallbacksByPermission = {}
end

function ZO_GuildRecruitment_Panel_Shared:RegisterPermissionRemovedDialogCallback(guildPermission, onPermissionRemovedCallback)
    internalassert(self.onGuildPermissionChangedDialogCallback == nil, "Attempting to set guild permission changed callback when one already exists")
    if internalassert(onPermissionRemovedCallback ~= nil, "Attempting to register a nil callback") then
        local function OnPermissionChanged(guildId)
            if guildId == self.guildId and not DoesPlayerHaveGuildPermission(self.guildId, guildPermission) then
                onPermissionRemovedCallback()
            end
        end

        GUILD_RECRUITMENT_MANAGER:RegisterCallback("GuildPermissionsChanged", OnPermissionChanged)
        self.guildPermissionRemovedCallbacksByPermission[guildPermission] = OnPermissionChanged
    end
end

function ZO_GuildRecruitment_Panel_Shared:UnregisterPermissionRemovedDialogCallback(guildPermission)
    GUILD_RECRUITMENT_MANAGER:UnregisterCallback("GuildPermissionsChanged", self.guildPermissionRemovedCallbacksByPermission[guildPermission])
    self.guildPermissionRemovedCallbacksByPermission[guildPermission] = nil
end
