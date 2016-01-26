GUILD_HISTORY_CATEGORIES =
{
    [GUILD_HISTORY_GENERAL] =
    {
        up = "EsoUI/Art/Guild/guildHistory_indexIcon_guild_up.dds",
        down = "EsoUI/Art/Guild/guildHistory_indexIcon_guild_down.dds",
        over = "EsoUI/Art/Guild/guildHistory_indexIcon_guild_over.dds",

        subcategoryEnumName = "SI_GUILDHISTORYGENERALSUBCATEGORIES",
        subcategories = 
        {
            [GUILD_HISTORY_GENERAL_ROSTER] =
            {
                gamepadIcon = "EsoUI/Art/Guild/gamepad/gp_guild_menuIcon_roster.dds",
                events = {
                    [GUILD_EVENT_GUILD_CREATE] = true,
                    [GUILD_EVENT_GUILD_JOIN] = true,
                    [GUILD_EVENT_GUILD_PROMOTE] = true,
                    [GUILD_EVENT_GUILD_DEMOTE] = true,
                    [GUILD_EVENT_GUILD_KICKED] = true,
                    [GUILD_EVENT_GUILD_LEAVE] = true,
                }
            },
            [GUILD_HISTORY_GENERAL_CUSTOMIZATION] =
            {
                gamepadIcon = "EsoUI/Art/Guild/gamepad/gp_guild_menuIcon_customization.dds",
                events = {
                    [GUILD_EVENT_BANKGOLD_PURCHASE_HERALDRY] = true,
                    [GUILD_EVENT_HERALDRY_EDITED] = true,
                    [GUILD_EVENT_MOTD_EDITED] = true,
                    [GUILD_EVENT_ABOUT_US_EDITED] = true,
                }
            },
            [GUILD_HISTORY_GENERAL_UNLOCKS] =
            {
                gamepadIcon = "EsoUI/Art/Guild/gamepad/gp_guild_menuIcon_unlocks.dds",
                events = {
                    [GUILD_EVENT_GUILD_BANK_LOCKED] = true,
                    [GUILD_EVENT_GUILD_BANK_UNLOCKED] = true,
                    [GUILD_EVENT_GUILD_KIOSK_LOCKED] = true,
                    [GUILD_EVENT_GUILD_KIOSK_UNLOCKED] = true,
                    [GUILD_EVENT_GUILD_STANDARD_LOCKED] = true,
                    [GUILD_EVENT_GUILD_STANDARD_UNLOCKED] = true,
                    [GUILD_EVENT_GUILD_STORE_LOCKED] = true,
                    [GUILD_EVENT_GUILD_STORE_UNLOCKED] = true,
                    [GUILD_EVENT_GUILD_TABARD_LOCKED] = true,
                    [GUILD_EVENT_GUILD_TABARD_UNLOCKED] = true,
                }
            },
        },
    },
    [GUILD_HISTORY_BANK] =
    {
        up = "EsoUI/Art/Guild/guildHistory_indexIcon_guildBank_up.dds",
        down = "EsoUI/Art/Guild/guildHistory_indexIcon_guildBank_down.dds",
        over = "EsoUI/Art/Guild/guildHistory_indexIcon_guildBank_over.dds",
        
        subcategoryEnumName = "SI_GUILDHISTORYBANKSUBCATEGORIES",
        subcategories = 
        {
            [GUILD_HISTORY_BANK_DEPOSITS] =
            {
                gamepadIcon = "EsoUI/Art/Guild/gamepad/gp_guild_menuIcon_deposits.dds",
                events = {
                    [GUILD_EVENT_BANKITEM_ADDED] = true,
                    [GUILD_EVENT_BANKGOLD_ADDED] = true,
                    [GUILD_EVENT_BANKGOLD_KIOSK_BID_REFUND] = true,
                }
            },
            [GUILD_HISTORY_BANK_WITHDRAWALS] =
            {
                gamepadIcon = "EsoUI/Art/Guild/gamepad/gp_guild_menuIcon_withdrawals.dds",
                events = {
                    [GUILD_EVENT_BANKITEM_REMOVED] = true,
                    [GUILD_EVENT_BANKGOLD_REMOVED] = true,
                    [GUILD_EVENT_BANKGOLD_KIOSK_BID] = true,
                    [GUILD_EVENT_BANKGOLD_PURCHASE_HERALDRY] = true,
                    [GUILD_EVENT_GUILD_KIOSK_PURCHASED] = true,
                    [GUILD_EVENT_HERALDRY_EDITED] = true,
                }
            },
        },
    },
    [GUILD_HISTORY_STORE] =
    {
        up = "EsoUI/Art/Guild/guildHistory_indexIcon_guildStore_up.dds",
        down = "EsoUI/Art/Guild/guildHistory_indexIcon_guildStore_down.dds",
        over = "EsoUI/Art/Guild/guildHistory_indexIcon_guildStore_over.dds",

        subcategoryEnumName = "SI_GUILDHISTORYSTORESUBCATEGORIES",
        subcategories = 
        {
            [GUILD_HISTORY_STORE_PURCHASES] =
            {
                gamepadIcon = "EsoUI/Art/Guild/gamepad/gp_guild_menuIcon_purchases.dds",
                events = {
                    [GUILD_EVENT_ITEM_SOLD] = true,
                }
            },
            [GUILD_HISTORY_STORE_HIRED_TRADER] =
            {
                gamepadIcon = "EsoUI/Art/Guild/gamepad/gp_guild_menuIcon_trader.dds",
                events = {
                    [GUILD_EVENT_BANKGOLD_KIOSK_BID] = true,
                    [GUILD_EVENT_BANKGOLD_KIOSK_BID_REFUND] = true,
                    [GUILD_EVENT_GUILD_KIOSK_PURCHASED] = true,
                }
            },
        },
    },
    [GUILD_HISTORY_ALLIANCE_WAR] =
    {
        up = "EsoUI/Art/Guild/guildHistory_indexIcon_campaigns_up.dds",
        down = "EsoUI/Art/Guild/guildHistory_indexIcon_campaigns_down.dds",
        over = "EsoUI/Art/Guild/guildHistory_indexIcon_campaigns_over.dds",

        subcategoryEnumName = "SI_GUILDHISTORYALLIANCEWARSUBCATEGORIES",
        subcategories = 
        {
            [GUILD_HISTORY_ALLIANCE_WAR_OWNERSHIP] =
            {
                gamepadIcon = "EsoUI/Art/Guild/gamepad/gp_guild_menuIcon_ownership.dds",
                events = {
                    [GUILD_EVENT_KEEP_CLAIMED] = true,
                    [GUILD_EVENT_KEEP_LOST] = true,
                    [GUILD_EVENT_KEEP_RELEASED] = true,
                }
            },
        },
    },
}

local function GetContrastTextColor()
    if IsInGamepadPreferredMode() then
        return ZO_SELECTED_TEXT
    end

    return ZO_SECOND_CONTRAST_TEXT
end

local function GetGoldString(amount)
    local color = GetContrastTextColor()
    local goldIcon = "EsoUI/Art/currency/currency_gold.dds"
    local iconSize = 16

    if IsInGamepadPreferredMode() then
        goldIcon = ZO_GAMEPAD_CURRENCY_ICON_GOLD_TEXTURE
        iconSize = 24
    end

    local goldIcon = zo_iconFormat(goldIcon, iconSize, iconSize)
    return zo_strformat(SI_GUILD_EVENT_GOLD_FOMART, color:Colorize(ZO_CurrencyControl_FormatCurrency(amount)), goldIcon)
end

local function DefaultEventFormat(eventType, param1, param2, param3, param4, param5)
    local contrastColor = GetContrastTextColor()
    local formatString = GetString("SI_GUILDEVENTTYPE", eventType)
    return zo_strformat(formatString, param1 and contrastColor:Colorize(param1) or nil,
                                      param2 and contrastColor:Colorize(param2) or nil,
                                      param3 and contrastColor:Colorize(param3) or nil,
                                      param4 and contrastColor:Colorize(param4) or nil,
                                      param5 and contrastColor:Colorize(param5) or nil)
end

local function DefaultEventFormatWithDisplayName(eventType, displayName, ...)
    return DefaultEventFormat(eventType, ZO_FormatUserFacingDisplayName(displayName), ...)
end

local function DefaultEventFormatWithTwoDisplayNames(eventType, displayName1, displayName2, ...)
    return DefaultEventFormat(eventType, ZO_FormatUserFacingDisplayName(displayName1), ZO_FormatUserFacingDisplayName(displayName2), ...)
end

local function DefaultEventFormatNoParams(eventType)
    return zo_strformat(GetString(SI_GUILD_EVENT_NO_PARAM_FORMAT), GetString("SI_GUILDEVENTTYPE", eventType))
end

local function BankItemEventFormat(eventType, displayName, quantity, itemLink)
    local contrastColor = GetContrastTextColor()
    local formatString = GetString("SI_GUILDEVENTTYPE", eventType)
    return zo_strformat(formatString,   contrastColor:Colorize(ZO_FormatUserFacingDisplayName(displayName)),
                                        ZO_SELECTED_TEXT:Colorize(quantity),
                                        itemLink)
end

local function BankGoldEventFormat(eventType, displayName, gold, kiosk)
    local contrastColor = GetContrastTextColor()
    local formatString = GetString("SI_GUILDEVENTTYPE", eventType)

    return zo_strformat(formatString,   contrastColor:Colorize(ZO_FormatUserFacingDisplayName(displayName)),
                                        GetGoldString(gold),
                                        kiosk and contrastColor:Colorize(kiosk) or nil)
end

local function KioskRefundEventFormat(eventType, kiosk, gold)
    local contrastColor = GetContrastTextColor()
    local formatString = GetString("SI_GUILDEVENTTYPE", eventType)

    return zo_strformat(formatString,   contrastColor:Colorize(kiosk),
                                        GetGoldString(gold))
end

GUILD_EVENT_EVENT_FORMAT =
{                                                                           -- Event Values passed to function
    [GUILD_EVENT_GUILD_PROMOTE] = DefaultEventFormatWithTwoDisplayNames,    -- (eventType, displayName1, displayName2, rankName)
    [GUILD_EVENT_GUILD_DEMOTE] = DefaultEventFormatWithTwoDisplayNames,     -- (eventType, displayName1, displayName2, rankName)
    [GUILD_EVENT_GUILD_CREATE] = DefaultEventFormatWithDisplayName,         -- (eventType, displayName)
    [GUILD_EVENT_GUILD_JOIN] = DefaultEventFormatWithDisplayName,           -- (eventType, displayName)
    [GUILD_EVENT_GUILD_LEAVE] = DefaultEventFormatWithDisplayName,          -- (eventType, displayName)
    [GUILD_EVENT_GUILD_KICKED] = DefaultEventFormatWithTwoDisplayNames,     -- (eventType, displayName1, displayName2)
    [GUILD_EVENT_BANKITEM_ADDED] = BankItemEventFormat,                     -- (eventType, displayName, itemQuantity, itemName)
    [GUILD_EVENT_BANKITEM_REMOVED] = BankItemEventFormat,                   -- (eventType, displayName, itemQuantity, itemName)
    [GUILD_EVENT_BANKGOLD_ADDED] = BankGoldEventFormat,                     -- (eventType, displayName, goldQuantity)
    [GUILD_EVENT_BANKGOLD_REMOVED] = BankGoldEventFormat,                   -- (eventType, displayName, goldQuantity)
    [GUILD_EVENT_BANKGOLD_KIOSK_BID_REFUND] = KioskRefundEventFormat,       -- (eventType, kioskName, goldQuantity)
    [GUILD_EVENT_BANKGOLD_KIOSK_BID] = BankGoldEventFormat,                 -- (eventType, displayName, goldQuantity, kioskName)
    [GUILD_EVENT_GUILD_KIOSK_PURCHASED] = BankGoldEventFormat,              -- (eventType, displayName, goldQuantity, kioskName)
    [GUILD_EVENT_BANKGOLD_GUILD_STORE_TAX] = DefaultEventFormatNoParams,    -- (eventType)
    [GUILD_EVENT_MOTD_EDITED] = DefaultEventFormatWithDisplayName,          -- (eventType, displayName)
    [GUILD_EVENT_ABOUT_US_EDITED] = DefaultEventFormatWithDisplayName,      -- (eventType, displayName)
    [GUILD_EVENT_KEEP_CLAIMED] = DefaultEventFormatWithDisplayName,         -- (eventType, displayName, keepName, campaignName)
    [GUILD_EVENT_KEEP_RELEASED] = DefaultEventFormatWithDisplayName,        -- (eventType, displayName, keepName, campaignName)
    [GUILD_EVENT_KEEP_LOST] = DefaultEventFormat,                           -- (eventType, keepName, campaignName)
    [GUILD_EVENT_HERALDRY_EDITED] = BankGoldEventFormat,                    -- (eventType, displayName, goldCost)
    [GUILD_EVENT_GUILD_STORE_UNLOCKED] = DefaultEventFormatNoParams,        -- (eventType)
    [GUILD_EVENT_GUILD_STORE_LOCKED] = DefaultEventFormatNoParams,          -- (eventType)
    [GUILD_EVENT_GUILD_BANK_UNLOCKED] = DefaultEventFormatNoParams,         -- (eventType)
    [GUILD_EVENT_GUILD_BANK_LOCKED] = DefaultEventFormatNoParams,           -- (eventType)
    [GUILD_EVENT_GUILD_STANDARD_UNLOCKED] = DefaultEventFormatNoParams,     -- (eventType)
    [GUILD_EVENT_GUILD_STANDARD_LOCKED] = DefaultEventFormatNoParams,       -- (eventType)
    [GUILD_EVENT_GUILD_KIOSK_UNLOCKED] = DefaultEventFormatNoParams,        -- (eventType)
    [GUILD_EVENT_GUILD_KIOSK_LOCKED] = DefaultEventFormatNoParams,          -- (eventType)
    [GUILD_EVENT_GUILD_TABARD_UNLOCKED] = DefaultEventFormatNoParams,       -- (eventType)
    [GUILD_EVENT_GUILD_TABARD_LOCKED] = DefaultEventFormatNoParams,         -- (eventType)

    [GUILD_EVENT_ITEM_SOLD] = function(eventType, seller, buyer, quantity, itemLink, price, tax)
        local contrastColor = GetContrastTextColor()
        local formatString = GetString("SI_GUILDEVENTTYPE", eventType)
        return zo_strformat(formatString,   contrastColor:Colorize(ZO_FormatUserFacingDisplayName(seller)),
                                            contrastColor:Colorize(ZO_FormatUserFacingDisplayName(buyer)),
                                            ZO_SELECTED_TEXT:Colorize(quantity),
                                            itemLink,
                                            GetGoldString(price),
                                            GetGoldString(tax))
    end,
}

function ComputeGuildHistoryEventSubcategory(eventType, category)
    local categoryData = GUILD_HISTORY_CATEGORIES[category]
    local subcategoryData = categoryData.subcategories

    if(subcategoryData ~= nil) then
        for subcategoryId, data in pairs(subcategoryData) do
            if(data.events[eventType]) then
                return subcategoryId
            end
        end
    end
end
