local ZO_Gamepad_GuildNameFooterFragment = ZO_FadeSceneFragment:Subclass()

function ZO_Gamepad_GuildNameFooterFragment:New(...)
    return ZO_FadeSceneFragment.New(self, ...)
end

function ZO_Gamepad_GuildNameFooterFragment:Initialize(...)
    ZO_FadeSceneFragment.Initialize(self, ...)

    self.guildName = nil
    self.guildNameControl = self.control:GetNamedChild("GuildName")
end

function ZO_Gamepad_GuildNameFooterFragment:SetGuildName(guildName)
    self.guildName = guildName
    self.guildNameControl:SetText(guildName)
end

function ZO_Gamepad_GuildNameFooterFragment:Show()
    ZO_FadeSceneFragment.Show(self)
end

ZO_GUILD_NAME_FOOTER_FRAGMENT = ZO_Gamepad_GuildNameFooterFragment:New(ZO_Gamepad_GuildNameFooter)