local ICON_KEEP = "EsoUI/Art/Guild/Gamepad/gp_ownership_icon_keep.dds"
local ICON_TRADER = "EsoUI/Art/Guild/Gamepad/gp_ownership_icon_guildTrader.dds"
local GUILD_RESOURCE_ICONS =
{
    [RESOURCETYPE_WOOD] = "EsoUI/Art/Guild/Gamepad/gp_ownership_icon_lumberMill.dds",
    [RESOURCETYPE_ORE] = "EsoUI/Art/Guild/Gamepad/gp_ownership_icon_mine.dds",
    [RESOURCETYPE_FOOD] = "EsoUI/Art/Guild/Gamepad/gp_ownership_icon_farm.dds",
}

ZO_GamepadGuildInfo = ZO_Object:Subclass()

function ZO_GamepadGuildInfo:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GamepadGuildInfo:Initialize(control)
    if not self.initialized then
        self.initialized = true

        self.control = control

        GUILD_INFO_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(self.control, true)

        GUILD_INFO_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
            if newState == SCENE_SHOWING then
                self:PerformDeferredInitialization(control)

                self:RefreshScreen()

                local function OnProfanityFilterChange()
                    self:RefreshScreen()
                end

                CALLBACK_MANAGER:RegisterCallback("ProfanityFilter_Off", OnProfanityFilterChange)
                CALLBACK_MANAGER:RegisterCallback("ProfanityFilter_On", OnProfanityFilterChange)
            elseif newState == SCENE_HIDING then
                CALLBACK_MANAGER:UnregisterCallback("ProfanityFilter_Off")
                CALLBACK_MANAGER:UnregisterCallback("ProfanityFilter_On")
            end
        end)
    end
end

function ZO_GamepadGuildInfo:PerformDeferredInitialization()
    if self.deferredInitialized then return end
    self.deferredInitialized = true

    local container = self.control:GetNamedChild("Container")

    local headerContainer = container:GetNamedChild("HeaderContainer")
    self.header = headerContainer:GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ZO_GAMEPAD_HEADER_LAYOUTS.CONTENT_HEADER_DATA_PAIRS_LINKED)

    self.headerData = {}

    self.scrollControl = container:GetNamedChild("TextScrollContainer")
    local scrollChild = self.scrollControl:GetNamedChild("ScrollChild")

    local keep = scrollChild:GetNamedChild("Keep")
    self.keepTitle = keep:GetNamedChild("Title")
    self.keepIcon = keep:GetNamedChild("Icon")
    self.keepName = keep:GetNamedChild("Name")
    self.campaignName = keep:GetNamedChild("NameExtra")
    
    local trader = scrollChild:GetNamedChild("Trader")
    self.traderTitle = trader:GetNamedChild("Title")
    self.traderIcon = trader:GetNamedChild("Icon")
    self.traderIcon:SetTexture(ICON_TRADER)
    self.traderName = trader:GetNamedChild("Name")

    local guildMasterContainer = scrollChild:GetNamedChild("GuildMaster")
    local guildMasterTitle = guildMasterContainer:GetNamedChild("Title")
    guildMasterTitle:SetText(GetString(SI_GAMEPAD_GUILD_HEADER_GUILD_MASTER_LABEL))
    self.guildMasterBodyLabel = guildMasterContainer:GetNamedChild("Body")

    local motdContainer = scrollChild:GetNamedChild("MOTD")
    local motdTitle = motdContainer:GetNamedChild("Title")
    motdTitle:SetText(GetString(SI_GUILD_MOTD_HEADER))
    self.motd = motdContainer:GetNamedChild("Body")

    local descriptionContainer = scrollChild:GetNamedChild("Description")
    local descriptionTitle = descriptionContainer:GetNamedChild("Title")
    descriptionTitle:SetText(GetString(SI_GUILD_DESCRIPTION_HEADER))
    self.description = descriptionContainer:GetNamedChild("Body")

    local privilegesControl = container:GetNamedChild("Privileges")
    self.privilegeBankControl = privilegesControl:GetNamedChild("Bank")
    self.privilegeHeraldryControl = privilegesControl:GetNamedChild("Heraldry")
    self.privilegeTradingHouseControl = privilegesControl:GetNamedChild("TradingHouse")

    self:InitializeFooter()
end

function ZO_GamepadGuildInfo:RefreshScreen()
    self.scrollControl:ResetToTop()
    self:RefreshKeepOwnership()
    self:RefreshTraderOwnership()
    self:RefreshGuildMaster()
    self:RefreshMOTD()
    self:RefreshDescription()
    self:RefreshPrivileges()
    self:RefreshHeader()
    self:RefreshFooter()
end

function ZO_GamepadGuildInfo:SetGuildId(guildId)
    self.guildId = guildId
end

local function RefreshPrivilege(privilegeControl, enabled)
    local label = privilegeControl:GetNamedChild("Name")
    local icon = privilegeControl:GetNamedChild("Icon")

    local color = enabled and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT
    local r, g, b = color:UnpackRGB()

    label:SetColor(r, g, b)
    icon:SetColor(r, g, b)
end

function ZO_GamepadGuildInfo:RefreshPrivileges()
    local canDepositToBank = DoesGuildHavePrivilege(self.guildId, GUILD_PRIVILEGE_BANK_DEPOSIT)
    RefreshPrivilege(self.privilegeBankControl, canDepositToBank)

    local canUseHeraldry = DoesGuildHavePrivilege(self.guildId, GUILD_PRIVILEGE_HERALDRY)
    RefreshPrivilege(self.privilegeHeraldryControl, canUseHeraldry)

    local canUseTradingHouse = DoesGuildHavePrivilege(self.guildId, GUILD_PRIVILEGE_TRADING_HOUSE)
    RefreshPrivilege(self.privilegeTradingHouseControl, canUseTradingHouse)
end

function ZO_GamepadGuildInfo:RefreshHeader()
    local headerData = self.headerData
    headerData.titleText = GetGuildName(self.guildId)
    ZO_GamepadGenericHeader_Refresh(self.header, headerData)
end

function ZO_GamepadGuildInfo:InitializeFooter()
    self.footerData = {
        data1HeaderText = GetString(SI_GAMEPAD_GUILD_HEADER_MEMBERS_ONLINE_LABEL),
    }
end

function ZO_GamepadGuildInfo:RefreshFooter()
    local numGuildMembers, numOnline, _, numInvitees = GetGuildInfo(self.guildId)
    self.footerData.data1Text = zo_strformat(GetString(SI_GAMEPAD_GUILD_HEADER_MEMBERS_ONLINE_FORMAT), numOnline, numGuildMembers + numInvitees)

    GAMEPAD_GENERIC_FOOTER:Refresh(self.footerData)
end

--------------
-- Messages --
--------------

function ZO_GamepadGuildInfo:RefreshGuildMaster()
    local guildMaster = select(3, GetGuildInfo(self.guildId))
    self.guildMasterBodyLabel:SetText(ZO_FormatUserFacingDisplayName(guildMaster))
end

function ZO_GamepadGuildInfo:RefreshMOTD()
    local text = GetGuildMotD(self.guildId)

    if text == "" then
        text = GetString(SI_GUILD_MOTD_EMPTY_TEXT)
    end

    self.motd:SetText(text)
end

function ZO_GamepadGuildInfo:RefreshDescription()
    local text = GetGuildDescription(self.guildId)

    if text == "" then
        text = GetString(SI_GUILD_DESCRIPTION_EMPTY_TEXT)
    end

    self.description:SetText(text)
end

-----------
-- Icons --
-----------

function ZO_GamepadGuildInfo:RefreshKeepOwnership()
    local text = GetString(SI_GUILD_NO_CLAIMED_KEEP)
    local headerText = GetString(SI_GAMEPAD_GUILD_KEEP_OWNERSHIP_HEADER)
    if(DoesGuildHaveClaimedKeep(self.guildId)) then
        local keepId, campaignId = GetGuildClaimedKeep(self.guildId)
        local keepType = GetKeepType(keepId)

        local icon = ICON_KEEP
        if(keepType == KEEPTYPE_RESOURCE) then
            local resourceType = GetKeepResourceType(keepId)
            icon = GUILD_RESOURCE_ICONS[resourceType]
        end

        self.keepIcon:SetTexture(icon)
        self.keepIcon:SetAlpha(1)
        text = zo_strformat(SI_TOOLTIP_KEEP_NAME, GetKeepName(keepId))
        
        self.campaignName:SetHidden(false)
        self.campaignName:SetText(GetCampaignName(campaignId))
    else
        self.keepIcon:SetTexture(ICON_KEEP)
        self.keepIcon:SetAlpha(0.2)
        text = ZO_DISABLED_TEXT:Colorize(text)
        headerText = ZO_DISABLED_TEXT:Colorize(headerText)
        self.campaignName:SetHidden(true)
    end

    self.keepTitle:SetText(headerText)
    self.keepName:SetText(text)
end

function ZO_GamepadGuildInfo:RefreshTraderOwnership()
    local headerText = GetString(SI_GUILD_TRADER_OWNERSHIP_HEADER)
    local traderText = GetString(SI_GUILD_NO_HIRED_TRADER)
    
    local traderName = GetGuildOwnedKioskInfo(self.guildId)
    if(traderName) then
        self.traderIcon:SetAlpha(1)
        traderText = zo_strformat(SI_GUILD_HIRED_TRADER, traderName)
    else
        self.traderIcon:SetAlpha(0.2)
        traderText = ZO_DISABLED_TEXT:Colorize(traderText)
        headerText = ZO_DISABLED_TEXT:Colorize(headerText)
    end

    self.traderName:SetText(traderText)
    self.traderTitle:SetText(headerText)
end

--------------------

function ZO_GuildInfo_Gamepad_Initialize(control)
    GAMEPAD_GUILD_INFO = ZO_GamepadGuildInfo:New(control)
end