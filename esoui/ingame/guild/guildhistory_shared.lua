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
                    [GUILD_EVENT_GUILD_INVITE] = true,
                    [GUILD_EVENT_GUILD_JOIN] = true,
                    [GUILD_EVENT_GUILD_PROMOTE] = true,
                    [GUILD_EVENT_GUILD_DEMOTE] = true,
                    [GUILD_EVENT_GUILD_KICKED] = true,
                    [GUILD_EVENT_GUILD_LEAVE] = true,
                    [GUILD_EVENT_GUILD_APPLICATION_DECLINED] = true,
                    [GUILD_EVENT_GUILD_APPLICATION_ACCEPTED] = true,
                    [GUILD_EVENT_REMOVED_FROM_BLACKLIST] = true,
                    [GUILD_EVENT_ADDED_TO_BLACKLIST] = true,
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
                    [GUILD_EVENT_GUILD_RECRUITMENT_GUILD_LISTED] = true,
                    [GUILD_EVENT_GUILD_RECRUITMENT_GUILD_UNLISTED] = true,
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
                },
                gatingPermission = GUILD_PERMISSION_BANK_VIEW_DEPOSIT_HISTORY,
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
                },
                gatingPermission = GUILD_PERMISSION_BANK_VIEW_WITHDRAW_HISTORY,
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
                },
                gatingPermission = GUILD_PERMISSION_BANK_VIEW_GOLD,
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
    local formattedGoldIcon = ZO_Currency_GetPlatformFormattedCurrencyIcon(CURT_MONEY)
    return zo_strformat(SI_GUILD_EVENT_GOLD_FORMAT, color:Colorize(ZO_CurrencyControl_FormatCurrency(amount)), formattedGoldIcon)
end

local function IsInvalidParam(param)
    return not param or param == "" or param == GetString(SI_GUILD_HISTORY_DEFAULT_PARSED_TEXT)
end

local function DefaultEventFormat(eventType, ...)
    local contrastColor = GetContrastTextColor()
    local formatString = GetString("SI_GUILDEVENTTYPE", eventType)
    local colorizedParams = {}
    for i = 1, select('#', ...) do
        local param = select(i, ...)
        colorizedParams[i] = contrastColor:Colorize(param)
    end

    return zo_strformat(formatString, unpack(colorizedParams))
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

local function BankGoldEventFormat(eventType, displayName, gold)
    local contrastColor = GetContrastTextColor()
    local formatString = GetString("SI_GUILDEVENTTYPE", eventType)

    return zo_strformat(formatString,   contrastColor:Colorize(ZO_FormatUserFacingDisplayName(displayName)),
                                        GetGoldString(gold))
end

local function KioskBuyOrBidEventFormat(eventType, displayName, gold, kioskName)
    local contrastColor = GetContrastTextColor()
    local formatString = GetString("SI_GUILDEVENTTYPE", eventType)

    return zo_strformat(formatString,   contrastColor:Colorize(ZO_FormatUserFacingDisplayName(displayName)),
                                        GetGoldString(gold),
                                        contrastColor:Colorize(kioskName))
end

local function KioskRefundEventFormat(eventType, kiosk, gold)
    local contrastColor = GetContrastTextColor()
    local formatString = GetString("SI_GUILDEVENTTYPE", eventType)

    return zo_strformat(formatString,   contrastColor:Colorize(kiosk),
                                        GetGoldString(gold))
end

local function GuildJoinedEventFormat(eventType, joinerDisplayName, optionalInviterDisplayName)
    if IsInvalidParam(optionalInviterDisplayName) then
        local contrastColor = GetContrastTextColor()
        local userFacingJoinerDisplayName = ZO_FormatUserFacingDisplayName(joinerDisplayName)
        return zo_strformat(SI_GUILDEVENTTYPEDEPRECATED7, contrastColor:Colorize(userFacingJoinerDisplayName))
    else
        return DefaultEventFormatWithTwoDisplayNames(eventType, joinerDisplayName, optionalInviterDisplayName)
    end
end

GUILD_EVENT_EVENT_FORMAT =
{                                                                           -- Event Values passed to function
    [GUILD_EVENT_GUILD_PROMOTE] = DefaultEventFormatWithTwoDisplayNames,    -- (eventType, displayName1, displayName2, rankName)
    [GUILD_EVENT_GUILD_DEMOTE] = DefaultEventFormatWithTwoDisplayNames,     -- (eventType, displayName1, displayName2, rankName)
    [GUILD_EVENT_GUILD_CREATE] = DefaultEventFormatWithDisplayName,         -- (eventType, displayName)
    [GUILD_EVENT_GUILD_INVITE] = DefaultEventFormatWithTwoDisplayNames,     -- (eventType, displayName1, displayName2)
    [GUILD_EVENT_GUILD_JOIN] = GuildJoinedEventFormat,                      -- (eventType, joinerDisplayName, optionalInviterDisplayName)
    [GUILD_EVENT_GUILD_LEAVE] = DefaultEventFormatWithDisplayName,          -- (eventType, displayName)
    [GUILD_EVENT_GUILD_KICKED] = DefaultEventFormatWithTwoDisplayNames,     -- (eventType, displayName1, displayName2)
    [GUILD_EVENT_BANKITEM_ADDED] = BankItemEventFormat,                     -- (eventType, displayName, itemQuantity, itemName)
    [GUILD_EVENT_BANKITEM_REMOVED] = BankItemEventFormat,                   -- (eventType, displayName, itemQuantity, itemName)
    [GUILD_EVENT_BANKGOLD_ADDED] = BankGoldEventFormat,                     -- (eventType, displayName, goldQuantity)
    [GUILD_EVENT_BANKGOLD_REMOVED] = BankGoldEventFormat,                   -- (eventType, displayName, goldQuantity)
    [GUILD_EVENT_BANKGOLD_KIOSK_BID_REFUND] = KioskRefundEventFormat,       -- (eventType, kioskName, goldQuantity)
    [GUILD_EVENT_BANKGOLD_KIOSK_BID] = KioskBuyOrBidEventFormat,            -- (eventType, displayName, goldQuantity, kioskName)
    [GUILD_EVENT_GUILD_KIOSK_PURCHASED] = KioskBuyOrBidEventFormat,         -- (eventType, displayName, goldQuantity, kioskName)
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
    [GUILD_EVENT_GUILD_APPLICATION_DECLINED] = DefaultEventFormatWithTwoDisplayNames,     -- (eventType, displayName1, displayName2)
    [GUILD_EVENT_GUILD_APPLICATION_ACCEPTED] = DefaultEventFormatWithTwoDisplayNames,     -- (eventType, displayName1, displayName2)
    [GUILD_EVENT_REMOVED_FROM_BLACKLIST] = DefaultEventFormatWithTwoDisplayNames,     -- (eventType, displayName1, displayName2)
    [GUILD_EVENT_ADDED_TO_BLACKLIST] = DefaultEventFormatWithTwoDisplayNames,     -- (eventType, displayName1, displayName2)
    [GUILD_EVENT_GUILD_RECRUITMENT_GUILD_LISTED] = DefaultEventFormatWithDisplayName,          -- (eventType, displayName)
    [GUILD_EVENT_GUILD_RECRUITMENT_GUILD_UNLISTED] = DefaultEventFormatWithDisplayName,          -- (eventType, displayName)

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

function ZO_GuildHistory_GetNoEntriesText(categoryId, subcategoryId, guildId)
    local categoryData = GUILD_HISTORY_CATEGORIES[categoryId]
    if not categoryData then
        return GetString(SI_GUILD_HISTORY_NO_ENTRIES)
    end

    if subcategoryId then
        local subcategoryData = categoryData.subcategories[subcategoryId]
        if subcategoryData.gatingPermission and not DoesPlayerHaveGuildPermission(guildId, subcategoryData.gatingPermission) then
            return GetString(SI_GUILD_CANT_VIEW_HISTORY)
        end
    else
        local numSubcategories = #categoryData.subcategories
        local numPermissionsFailed = 0
        for i, subcategoryData in ipairs(categoryData.subcategories) do
            if subcategoryData.gatingPermission and not DoesPlayerHaveGuildPermission(guildId, subcategoryData.gatingPermission) then
                numPermissionsFailed = numPermissionsFailed + 1
            else
                -- subcategory was not gated or permission was met, we can show the generic message
                break
            end
        end

        if numPermissionsFailed == numSubcategories then
            return GetString(SI_GUILD_CANT_VIEW_HISTORY)
        else
            return GetString(SI_GUILD_HISTORY_NO_ENTRIES)
        end
    end

    return GetString(SI_GUILD_HISTORY_NO_ENTRIES)
end