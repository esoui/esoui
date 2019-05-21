------------------
-- Guild Finder --
------------------

ZO_GUILD_BROWSER_CATEGORY_APPLICATIONS = 1
ZO_GUILD_BROWSER_CATEGORY_GUILD_LIST = 2

ZO_GuildBrowser_Shared = ZO_Object:Subclass()

function ZO_GuildBrowser_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GuildBrowser_Shared:Initialize(control)
    self.control = control
end

function ZO_GuildBrowser_Shared:OnShowing()
    
end

function ZO_GuildBrowser_Shared:OnHidden()
    
end