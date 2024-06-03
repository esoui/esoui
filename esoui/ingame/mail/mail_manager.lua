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
end

function ZO_Mail_Manager:SetupSavedVars()
    local defaults =
    {
        deleteOnClaim = true,
    }
    self.savedVars = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 1, "MailOptions", defaults)
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