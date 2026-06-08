ZO_Mail_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_Mail_Manager:Initialize()
    self:RegisterForEvents()
end

function ZO_Mail_Manager:RegisterForEvents()
    local function OnAddOnLoaded(_, name)
        if name == "ZO_Ingame" then
            self:SetupSavedVars()
            EVENT_MANAGER:UnregisterForEvent("ZO_Mail_Manager", EVENT_ADD_ON_LOADED)
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_Mail_Manager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)

    local function OnUnreadUpdate()
        self:FireCallbacks("NumUnreadMailChanged", self:GetTotalNumUnreadMail())
    end

    EVENT_MANAGER:RegisterForEvent("ZO_Mail_Manager", EVENT_MAIL_NUM_UNREAD_CHANGED, OnUnreadUpdate)
    EVENT_MANAGER:RegisterForEvent("ZO_Mail_Manager", EVENT_GUILD_MAIL_UPDATE, OnUnreadUpdate)
end

function ZO_Mail_Manager:SetupSavedVars()
    local totalUnreadMail = self:GetTotalNumUnreadMail()

    local defaults =
    {
        deleteOnClaim = true,
        readGuildMail = {},
        deletedGuildMail = {},
    }
    self.savedVars = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 2, "MailOptions", defaults)

    --Clean up information for any mails that no longer exist
    for mailId, isRead in pairs(self.savedVars.readGuildMail) do
        if not IsValidGuildMail(StringToId64(mailId)) then
            self.savedVars.readGuildMail[mailId] = nil
        end
    end

    for mailId, isDeleted in pairs(self.savedVars.deletedGuildMail) do
        if not IsValidGuildMail(StringToId64(mailId)) then
            self.savedVars.deletedGuildMail[mailId] = nil
        end
    end

    ZO_SavePlayerConsoleProfile()

    --If the total number of mail changed after initializing saved variables, fire off the mail changed callback
    local newTotalUnreadMail = self:GetTotalNumUnreadMail()
    if newTotalUnreadMail > totalUnreadMail then
        self:FireCallbacks("NumUnreadMailChanged", newTotalUnreadMail)
    end
end

function ZO_Mail_Manager:HasReadGuildMail(mailId)
    return self.savedVars.readGuildMail[zo_getSafeId64Key(mailId)] or false
end

function ZO_Mail_Manager:MarkGuildMailRead(mailId)
    if not self.savedVars.readGuildMail[zo_getSafeId64Key(mailId)] then
        self.savedVars.readGuildMail[zo_getSafeId64Key(mailId)] = true
        ZO_SavePlayerConsoleProfile()
        self:FireCallbacks("NumUnreadMailChanged", self:GetTotalNumUnreadMail())
    end
end

function ZO_Mail_Manager:HasDeletedGuildMail(mailId)
    return self.savedVars.deletedGuildMail[zo_getSafeId64Key(mailId)] or false
end

function ZO_Mail_Manager:MarkGuildMailDeleted(mailId)
    if not self.savedVars.deletedGuildMail[zo_getSafeId64Key(mailId)] then
        self.savedVars.deletedGuildMail[zo_getSafeId64Key(mailId)] = true
        ZO_SavePlayerConsoleProfile()
        self:FireCallbacks("GuildMailDeleted", mailId)
    end
end

do
    local function GetNextValidGuildMailIdIter(_, previousMailId)
        return GetNextValidGuildMailId(previousMailId)
    end

    function ZO_Mail_Manager:GetTotalNumUnreadMail()
        --Add the number of unread regular mails with the number of unread guild mails
        local numUnread = GetNumUnreadMail()
        if self.savedVars then
            for guildMailId in GetNextValidGuildMailIdIter do
                if not self:HasDeletedGuildMail(guildMailId) and not self:HasReadGuildMail(guildMailId) then
                    numUnread = numUnread + 1
                end
            end
        end

        return numUnread
    end

    function ZO_Mail_Manager:HasUnreadMail()
        if HasUnreadMail() then
            return true
        end

        if self.savedVars then
            for guildMailId in GetNextValidGuildMailIdIter do
                if not self:HasDeletedGuildMail(guildMailId) and not self:HasReadGuildMail(guildMailId) then
                    return true
                end
            end
        end

        return false
    end
end

function ZO_Mail_Manager:ShouldDeleteOnClaim()
    return self.savedVars.deleteOnClaim
end

function ZO_Mail_Manager:SetDeleteOnClaim(deleteOnClaim)
    if self.savedVars.deleteOnClaim ~= deleteOnClaim then
        self.savedVars.deleteOnClaim = deleteOnClaim
        ZO_SavePlayerConsoleProfile()
    end
end

MAIL_MANAGER = ZO_Mail_Manager:New()