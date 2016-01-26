ZO_GUILD_RESOURCE_ICONS =
{
    [RESOURCETYPE_WOOD] = "EsoUI/Art/Guild/ownership_icon_lumberMill.dds",
    [RESOURCETYPE_ORE] = "EsoUI/Art/Guild/ownership_icon_mine.dds",
    [RESOURCETYPE_FOOD] = "EsoUI/Art/Guild/ownership_icon_farm.dds",
}

local GuildHomeManager = ZO_Object:Subclass()

function GuildHomeManager:New(control)
    local manager = ZO_Object.New(self)

    manager.control = control
    manager.scroll = GetControl(control, "PaneScroll")
    manager.scrollChild = GetControl(manager.scroll, "Child")
    manager.infoContainer = CreateControlFromVirtual("ZO_GuildHomeInfo", manager.scrollChild, "ZO_GuildHomeInfo")
    manager.keepIcon = GetControl(control, "KeepIcon")
    manager.keepName = GetControl(control, "KeepName")
    manager.campaignName = GetControl(control, "KeepCampaignName")
    manager.traderIcon = GetControl(control, "TraderIcon")
    manager.traderName = GetControl(control, "TraderName")

    manager.savingEditBoxGroup = ZO_SavingEditBoxGroup:New()

    manager.motd = ZO_SavingEditBox:New(GetControl(manager.infoContainer, "MotD"))
    manager.motd:SetDefaultText(GetString(SI_GUILD_MOTD_DEFAULT_TEXT))
    manager.motd:SetEmptyText(GetString(SI_GUILD_MOTD_EMPTY_TEXT))
    manager.savingEditBoxGroup:Add(manager.motd)
    local motdEditControl = manager.motd:GetEditControl()
    motdEditControl:SetMultiLine(true)
    motdEditControl:SetMaxInputChars(MAX_GUILD_MOTD_LENGTH)
    manager.motd:RegisterCallback("Save", function(text) SetGuildMotD(manager.guildId, text) end)

    manager.description = ZO_SavingEditBox:New(GetControl(manager.infoContainer, "Description"))
    manager.description:SetDefaultText(GetString(SI_GUILD_DESCRIPTION_DEFAULT_TEXT))
    manager.description:SetEmptyText(GetString(SI_GUILD_DESCRIPTION_EMPTY_TEXT))
    manager.savingEditBoxGroup:Add(manager.description)
    local descriptionEditControl = manager.description:GetEditControl()
    descriptionEditControl:SetMultiLine(true)
    descriptionEditControl:SetMaxInputChars(MAX_GUILD_DESCRIPTION_LENGTH)
    manager.description:RegisterCallback("Save", function(text) SetGuildDescription(manager.guildId, text) end)

    manager:InitializeKeybindDescriptors()

    control:RegisterForEvent(EVENT_GUILD_MOTD_CHANGED, function(_, guildId) if(manager.guildId == guildId) then manager:OnGuildMotDChanged() end end)
    control:RegisterForEvent(EVENT_GUILD_DESCRIPTION_CHANGED, function(_, guildId) if(manager.guildId == guildId) then manager:OnGuildDescriptionChanged() end end)
    control:RegisterForEvent(EVENT_GUILD_RANK_CHANGED, function(_, guildId) if(manager.guildId == guildId) then manager:OnGuildRankChanged() end end)
    control:RegisterForEvent(EVENT_GUILD_RANKS_CHANGED, function(_, guildId) if(manager.guildId == guildId) then manager:OnGuildRanksChanged() end end)
    control:RegisterForEvent(EVENT_GUILD_MEMBER_RANK_CHANGED, function(_, guildId, displayName) if(manager.guildId == guildId) then manager:OnGuildMemberRankChanged(displayName) end end)
    control:RegisterForEvent(EVENT_GUILD_KEEP_CLAIM_UPDATED, function(_, guildId) if(manager.guildId == guildId) then manager:OnGuildKeepClaimUpdated() end end)
    control:RegisterForEvent(EVENT_GUILD_TRADER_HIRED_UPDATED, function(_, guildId) if(manager.guildId == guildId) then manager:OnGuildTraderHiredUpdated() end end)

    CALLBACK_MANAGER:RegisterCallback("ProfanityFilter_Off", function() manager:OnProfanityFilterChanged() end)
    CALLBACK_MANAGER:RegisterCallback("ProfanityFilter_On", function() manager:OnProfanityFilterChanged() end)

    GUILD_HOME_SCENE = ZO_Scene:New("guildHome", SCENE_MANAGER)
    GUILD_HOME_SCENE:RegisterCallback("StateChange",     function(oldState, state)
                                                                if(state == SCENE_SHOWING) then
                                                                    KEYBIND_STRIP:AddKeybindButtonGroup(manager.keybindStripDescriptor)
                                                                elseif(state == SCENE_HIDDEN) then
                                                                    KEYBIND_STRIP:RemoveKeybindButtonGroup(manager.keybindStripDescriptor)
                                                                end
                                                            end)

    return manager
end

function GuildHomeManager:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
		alignment = KEYBIND_STRIP_ALIGN_CENTER,

		-- Leave Guild
		{
			name = GetString(SI_GUILD_LEAVE),
			keybind = "UI_SHORTCUT_NEGATIVE",

			callback = function()
				ZO_ShowLeaveGuildDialog(self.guildId)
			end,

			visible = function()
				return true;
			end
		},

        -- Release Keep
        {
            name = GetString(SI_GUILD_RELEASE_KEEP),
            keybind = "UI_SHORTCUT_SECONDARY",

            visible = function()
                return DoesGuildHaveClaimedKeep(self.guildId) and DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_RELEASE_AVA_RESOURCE)
            end,

            callback = function()
                local keepId, campaignId = GetGuildClaimedKeep(self.guildId)
                ZO_Dialogs_ShowDialog("CONFIRM_RELEASE_KEEP_OWNERSHIP", { release = function() ReleaseKeepForGuild(self.guildId) end, keepId = keepId })
            end,
        },
    }
end

function GuildHomeManager:SetGuildId(guildId)
    self.guildId = guildId
    self:RefreshAll()
end

function GuildHomeManager:RefreshGuildMaster()
    local guildMasterLabel = GetControl(self.control, "GuildMaster")
    local _, _, guildLeader = GetGuildInfo(self.guildId)
    guildMasterLabel:SetText(guildLeader)
end

function GuildHomeManager:RefreshMotD()
    self.motd:SetText(GetGuildMotD(self.guildId))
end

function GuildHomeManager:RefreshDescription()
    self.description:SetText(GetGuildDescription(self.guildId))
end

function GuildHomeManager:RefreshPermissions()
    if(DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_SET_MOTD)) then
        self.motd:SetHidden(false)
    else
        self.motd:SetHidden(true)
    end

    if(DoesPlayerHaveGuildPermission(self.guildId, GUILD_PERMISSION_DESCRIPTION_EDIT)) then
        self.description:SetHidden(false)
    else
        self.description:SetHidden(true)
    end

    self:RefreshReleaseKeep()
end

function GuildHomeManager:RefreshFoundedDate()
    GetControl(self.control, "Founded"):SetText(GetGuildFoundedDate(self.guildId))
end

function GuildHomeManager:RefreshKeepOwnership()
    if(DoesGuildHaveClaimedKeep(self.guildId)) then    
        local keepId, campaignId = GetGuildClaimedKeep(self.guildId)
        local keepType = GetKeepType(keepId)

        local icon = "EsoUI/Art/Guild/ownership_icon_keep.dds"
        if(keepType == KEEPTYPE_RESOURCE) then
            local resourceType = GetKeepResourceType(keepId)
            icon = ZO_GUILD_RESOURCE_ICONS[resourceType]
        end

        self.keepIcon:SetTexture(icon)
        self.keepIcon:SetAlpha(1)
        self.keepName:SetText(zo_strformat(SI_TOOLTIP_KEEP_NAME, GetKeepName(keepId)))
        self.campaignName:SetHidden(false)
        self.campaignName:SetText(GetCampaignName(campaignId))
    else
        self.keepIcon:SetTexture("EsoUI/Art/Guild/ownership_icon_keep.dds")
        self.keepIcon:SetAlpha(0.2)
        self.keepName:SetText(GetString(SI_GUILD_NO_CLAIMED_KEEP))
        self.campaignName:SetHidden(true)
    end

    self:RefreshReleaseKeep()
end

function GuildHomeManager:RefreshTraderOwnership()
    local traderName = GetGuildOwnedKioskInfo(self.guildId)

    if(traderName) then
        self.traderIcon:SetAlpha(1)
        self.traderName:SetText(zo_strformat(SI_GUILD_HIRED_TRADER, traderName))
    else
        self.traderIcon:SetAlpha(0.2)
        self.traderName:SetText(GetString(SI_GUILD_NO_HIRED_TRADER))
    end
end

function GuildHomeManager:RefreshReleaseKeep()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function GuildHomeManager:RefreshAll()
    self.motd:SetEditing(false)
    self.description:SetEditing(false)

    self:RefreshGuildMaster()
    self:RefreshMotD()
    self:RefreshDescription()
    self:RefreshPermissions()
    self:RefreshFoundedDate()
    self:RefreshKeepOwnership()
    self:RefreshTraderOwnership()
end

--Events

function GuildHomeManager:OnGuildMotDChanged()
    self:RefreshMotD()
end

function GuildHomeManager:OnGuildDescriptionChanged()
    self:RefreshDescription()
end

function GuildHomeManager:OnProfanityFilterChanged()
    self:RefreshMotD()
    self:RefreshDescription()
end

function GuildHomeManager:OnGuildRanksChanged()
    self:RefreshPermissions()
    self:RefreshGuildMaster()
end

function GuildHomeManager:OnGuildMemberRankChanged()
    self:RefreshPermissions()
    self:RefreshGuildMaster()
end

function GuildHomeManager:OnGuildRankChanged()
    self:RefreshPermissions()
end

function GuildHomeManager:OnGuildKeepClaimUpdated()
    self:RefreshKeepOwnership()
end

function GuildHomeManager:OnGuildTraderHiredUpdated()
    self:RefreshTraderOwnership()
end

--Global XML

function ZO_GuildHome_OnInitialized(self)
    GUILD_HOME = GuildHomeManager:New(self)
end