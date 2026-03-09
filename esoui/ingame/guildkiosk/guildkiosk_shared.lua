ZO_PURCHASE_KIOSK_INTERACTION =
{
    type = "Purchase Kiosk",
    interactTypes = { INTERACTION_GUILDKIOSK_PURCHASE },
}

ZO_BID_ON_KIOSK_INTERACTION =
{
    type = "Bid On Kiosk",
    interactTypes = { INTERACTION_GUILDKIOSK_BID },
}

ZO_GuildKiosk_Purchase_Shared = ZO_Object:Subclass()

function ZO_GuildKiosk_Purchase_Shared:New(...)
    local purchase = ZO_Object.New(self)
    purchase:Initialize(...)
    return purchase
end

function ZO_GuildKiosk_Purchase_Shared:Initialize()
    local function OnGuildKioskConsiderPurchaseStart()
        SYSTEMS:GetObject("guildKioskPurchase"):OnGuildKioskConsiderPurchaseStart()
    end

    local function OnGuildKioskConsiderPurchaseStop()
        SYSTEMS:GetObject("guildKioskPurchase"):OnGuildKioskConsiderPurchaseStop()
    end

    EVENT_MANAGER:RegisterForEvent("guildKioskPurchaseShared", EVENT_GUILD_KIOSK_CONSIDER_PURCHASE_START, OnGuildKioskConsiderPurchaseStart)
    EVENT_MANAGER:RegisterForEvent("guildKioskPurchaseShared", EVENT_GUILD_KIOSK_CONSIDER_PURCHASE_STOP, OnGuildKioskConsiderPurchaseStop)
end

ZO_GUILD_KIOSK_PURCHASE_SHARED = ZO_GuildKiosk_Purchase_Shared:New()

local g_nextPurchaseUpdate = nil
function ZO_GuildKiosk_Purchase_OnUpdate(descriptionLabel, gameTimeSecs)    
    if(g_nextPurchaseUpdate == nil or gameTimeSecs >= g_nextPurchaseUpdate) then
        g_nextPurchaseUpdate = gameTimeSecs + 1
        local secsRemaining = GetKioskBidWindowSecondsRemaining()
        local ownershipDuration = ZO_FormatTimeLargestTwo(secsRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE)
        descriptionLabel:SetText(zo_strformat(SI_GUILD_KIOSK_PURCHASE_DESCRIPTION, ownershipDuration))
    end
end

ZO_GuildKiosk_Bid_Shared = ZO_Object:Subclass()

function ZO_GuildKiosk_Bid_Shared:New(...)
    local bid = ZO_Object.New(self)
    bid:Initialize(...)
    return bid
end

function ZO_GuildKiosk_Bid_Shared:Initialize()
    local function OnGuildKioskConsiderBidStart()
        SYSTEMS:GetObject("guildKioskBid"):OnGuildKioskConsiderBidStart()
    end

    local function OnGuildKioskConsiderBidStop()
        SYSTEMS:GetObject("guildKioskBid"):OnGuildKioskConsiderBidStop()
    end

    EVENT_MANAGER:RegisterForEvent("guildKioskBidShared", EVENT_GUILD_KIOSK_CONSIDER_BID_START, function() OnGuildKioskConsiderBidStart() end)
    EVENT_MANAGER:RegisterForEvent("guildKioskBidShared", EVENT_GUILD_KIOSK_CONSIDER_BID_STOP, function() OnGuildKioskConsiderBidStop() end)
end

function ZO_GuildKiosk_Bid_Shared.GetBidActionText(hasBidOnThisTraderAlready)
    if hasBidOnThisTraderAlready then
        return GetString(SI_GUILD_KIOSK_UPDATE_BID)
    else
        return GetString(SI_GUILD_KIOSK_INITIAL_BID)
    end
end

ZO_GUILD_KIOSK_BID_SHARED = ZO_GuildKiosk_Bid_Shared:New()