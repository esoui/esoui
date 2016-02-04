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

GAMEPAD_SCREEN_ADJUST_ACTION_LAYER_FRAGMENT = ZO_ActionLayerFragment:New("ScreenAdjust")

GAMEPAD_COLLECTIONS_BOOK_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadCollections)
GAMEPAD_COLLECTIONS_BOOK_FRAGMENT:SetHideOnSceneHidden(true)
GAMEPAD_COLLECTIONS_BOOK_INFO_PANEL_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadCollectionsInfoPanel, true)

GAMEPAD_ACTIVITY_FINDER_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_ActivityFinderRoot_Gamepad)
GAMEPAD_ACTIVITY_FINDER_FRAGMENT:SetHideOnSceneHidden(true)