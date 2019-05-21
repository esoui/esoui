local GuildSharedInfo = ZO_Object:Subclass()

function GuildSharedInfo:New(control)
    local manager = ZO_Object.New(self)
    manager.control = control
    manager.bankIcon = GetControl(control, "Bank")
    manager.tradingHouseIcon = GetControl(control, "TradingHouse")
    manager.heraldryIcon = GetControl(control, "Heraldry")

    control:RegisterForEvent(EVENT_GUILD_DATA_LOADED, function() manager:Refresh(manager.guildId) end)
    control:RegisterForEvent(EVENT_GUILD_MEMBER_ADDED, function(_, guildId) manager:Refresh(guildId) end)
    control:RegisterForEvent(EVENT_GUILD_MEMBER_REMOVED, function(_, guildId) manager:Refresh(guildId) end)
    control:RegisterForEvent(EVENT_GUILD_MEMBER_PLAYER_STATUS_CHANGED, function(_, guildId) manager:Refresh(guildId) end)

    return manager
end

function GuildSharedInfo:SetGuildId(guildId)
    self.guildId = guildId
    self:Refresh(guildId)
end

function GuildSharedInfo:Refresh(guildId)
    if(self.guildId and self.guildId == guildId) then
        local count = GetControl(self.control, "Count")
        local numGuildMembers, numOnline, _, numInvitees = GetGuildInfo(guildId)

        count:SetText(zo_strformat(SI_GUILD_NUM_MEMBERS_ONLINE_FORMAT, numOnline, numGuildMembers + numInvitees))

        self.canDepositToBank = DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_BANK_DEPOSIT)
        if(self.canDepositToBank) then
            self.bankIcon:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
        else
            self.bankIcon:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGBA())
        end

        self.canUseTradingHouse = DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_TRADING_HOUSE)
        if(self.canUseTradingHouse) then
            self.tradingHouseIcon:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
        else
            self.tradingHouseIcon:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGBA())
        end

        self.canUseHeraldry = DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_HERALDRY)
        if(self.canUseHeraldry) then
            self.heraldryIcon:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
        else
            self.heraldryIcon:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGBA())
        end
    end
end

function ZO_GuildSharedInfoBank_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, TOP, 0, 0)
    if(GUILD_SHARED_INFO.canDepositToBank) then
        SetTooltipText(InformationTooltip, GetString(SI_GUILD_TOOLTIP_BANK_DEPOSIT_ENABLED))
    else
        SetTooltipText(InformationTooltip, zo_strformat(SI_GUILD_TOOLTIP_BANK_DEPOSIT_DISABLED, GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_BANK_DEPOSIT)))
    end
end

function ZO_GuildSharedInfoBank_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_GuildSharedInfoTradingHouse_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, TOP, 0, 0)
    if(GUILD_SHARED_INFO.canUseTradingHouse) then
        SetTooltipText(InformationTooltip, GetString(SI_GUILD_TOOLTIP_TRADING_HOUSE_ENABLED))
    else
        SetTooltipText(InformationTooltip, zo_strformat(SI_GUILD_TOOLTIP_TRADING_HOUSE_DISABLED, GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_TRADING_HOUSE)))
    end
end

function ZO_GuildSharedInfoTradingHouse_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_GuildSharedInfoHeraldry_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, TOP, 0, 0)
    if(GUILD_SHARED_INFO.canUseHeraldry) then
        SetTooltipText(InformationTooltip, GetString(SI_GUILD_TOOLTIP_HERALDRY_ENABLED))
    else
        SetTooltipText(InformationTooltip, zo_strformat(SI_GUILD_TOOLTIP_HERALDRY_DISABLED, GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_HERALDRY)))
    end
end

function ZO_GuildSharedInfoHeraldry_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_GuildSharedInfo_OnInitialized(self)
    GUILD_SHARED_INFO = GuildSharedInfo:New(self)
end