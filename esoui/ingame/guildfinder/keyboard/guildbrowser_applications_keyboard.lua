------------------
-- Guild Finder --
------------------

ZO_GuildBrowser_Applications_Keyboard = ZO_GuildFinder_Applications_Keyboard:Subclass()

function ZO_GuildBrowser_Applications_Keyboard:New(...)
    return ZO_GuildFinder_Applications_Keyboard.New(self, ...)
end

function ZO_GuildBrowser_Applications_Keyboard:Initialize(control)
    ZO_GuildFinder_Applications_Keyboard.Initialize(self, control)
end

GUILD_BROWSER_APPLICATIONS_KEYBOARD = ZO_GuildBrowser_Applications_Keyboard:New(control)