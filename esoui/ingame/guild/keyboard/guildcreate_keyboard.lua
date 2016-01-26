local GUILD_CREATE
local GuildCreateManager = ZO_Object:Subclass()

function GuildCreateManager:New(control)
    local manager = ZO_Object.New(self)

    manager.control = control
    manager.errorLabel = GetControl(control, "Error")

    manager:InitializeKeybindDescriptor()

    control:RegisterForEvent(EVENT_GUILD_DATA_LOADED, function() manager:RefreshGuildCreateStatus() end)
    control:RegisterForEvent(EVENT_GUILD_MEMBER_RANK_CHANGED, function() manager:RefreshGuildCreateStatus() end)
    control:RegisterForEvent(EVENT_LEVEL_UPDATE, function(_, unitTag) if(unitTag == "player") then manager:RefreshGuildCreateStatus() end end)

    GUILD_CREATE_SCENE = ZO_Scene:New("guildCreate", SCENE_MANAGER)
    GUILD_CREATE_SCENE:RegisterCallback("StateChange",  function(oldState, newState)
                                                            if(newState == SCENE_SHOWING) then                                                                
                                                                KEYBIND_STRIP:AddKeybindButtonGroup(manager.keybindStripDescriptor)
                                                            elseif(newState == SCENE_HIDDEN) then                                                                
                                                                KEYBIND_STRIP:RemoveKeybindButtonGroup(manager.keybindStripDescriptor)
                                                            end
                                                        end)

    manager:RefreshGuildCreateStatus()

    return manager
end

function GuildCreateManager:InitializeKeybindDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Invite
        {
            name = GetString(SI_GUILD_CREATE),
            keybind = "UI_SHORTCUT_PRIMARY",
        
            callback = function()
                ZO_Dialogs_ShowDialog("CREATE_GUILD")
            end,

            visible = function()
                return self.canCreateGuild
            end
        },
    }
end

function GuildCreateManager:RefreshGuildCreateStatus()
    self.canCreateGuild = ZO_SetGuildCreateError(self.errorLabel)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

--Global XML

function ZO_GuildCreate_OnInitialized(self)
    GUILD_CREATE = GuildCreateManager:New(self)
end