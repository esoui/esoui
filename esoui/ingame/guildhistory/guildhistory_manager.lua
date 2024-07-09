local GUILD_HISTORY_EVENT_CATEGORIES =
{
    [GUILD_HISTORY_EVENT_CATEGORY_ROSTER] =
    {
        up = "EsoUI/Art/Guild/History/guildHistory_roster_up.dds",
        down = "EsoUI/Art/Guild/History/guildHistory_roster_down.dds",
        over = "EsoUI/Art/Guild/History/guildHistory_roster_over.dds",

        subcategories = 
        {
            {
                subcategoryType = GUILD_HISTORY_EVENT_SUBCATEGORY_ALL,
                gamepadIcon = "EsoUI/Art/Guild/History/Gamepad/gp_guildHistory_roster.dds",
            },
        },
    },
    [GUILD_HISTORY_EVENT_CATEGORY_ACTIVITY] =
    {
        up = "EsoUI/Art/Guild/History/guildHistory_customize_up.dds",
        down = "EsoUI/Art/Guild/History/guildHistory_customize_down.dds",
        over = "EsoUI/Art/Guild/History/guildHistory_customize_over.dds",

        subcategories = 
        {
            {
                subcategoryType = GUILD_HISTORY_EVENT_SUBCATEGORY_ALL,
                gamepadIcon = "EsoUI/Art/Guild/History/Gamepad/gp_guildHistory_customize.dds",
            }
        }
    },
    [GUILD_HISTORY_EVENT_CATEGORY_MILESTONE] =
    {
        up = "EsoUI/Art/Guild/History/guildHistory_unlock_up.dds",
        down = "EsoUI/Art/Guild/History/guildHistory_unlock_down.dds",
        over = "EsoUI/Art/Guild/History/guildHistory_unlock_over.dds",

        subcategories = 
        {
            {
                subcategoryType = GUILD_HISTORY_EVENT_SUBCATEGORY_ALL,
                gamepadIcon = "EsoUI/Art/Guild/History/Gamepad/gp_guildHistory_unlocks.dds",
            }
        }
    },
    [GUILD_HISTORY_EVENT_CATEGORY_BANKED_ITEM] =
    {
        up = "EsoUI/Art/Guild/History/guildHistory_bankItem_up.dds",
        down = "EsoUI/Art/Guild/History/guildHistory_bankItem_down.dds",
        over = "EsoUI/Art/Guild/History/guildHistory_bankItem_over.dds",
        
        subcategories = 
        {
            {
                subcategoryType = GUILD_HISTORY_EVENT_SUBCATEGORY_DEPOSITS,
                gamepadIcon = "EsoUI/Art/Guild/History/Gamepad/gp_guildHistory_depositItems.dds",
                events =
                {
                    [GUILD_HISTORY_BANKED_ITEM_EVENT_ADDED] = true,
                },
            },
            {
                subcategoryType = GUILD_HISTORY_EVENT_SUBCATEGORY_WITHDRAWALS,
                gamepadIcon = "EsoUI/Art/Guild/History/Gamepad/gp_guildHistory_withdrawItems.dds",
                events =
                {
                    [GUILD_HISTORY_BANKED_ITEM_EVENT_REMOVED] = true,
                },
            },
        },
    },
    [GUILD_HISTORY_EVENT_CATEGORY_BANKED_CURRENCY] =
    {
        up = "EsoUI/Art/Guild/History/guildHistory_bankCurrency_up.dds",
        down = "EsoUI/Art/Guild/History/guildHistory_bankCurrency_down.dds",
        over = "EsoUI/Art/Guild/History/guildHistory_bankCurrency_over.dds",
        
        subcategories = 
        {
            {
                subcategoryType = GUILD_HISTORY_EVENT_SUBCATEGORY_DEPOSITS,
                gamepadIcon = "EsoUI/Art/Guild/History/Gamepad/gp_guildHistory_depositCurrency.dds",
                events =
                {
                    [GUILD_HISTORY_BANKED_CURRENCY_EVENT_DEPOSITED] = true,
                },
                gatingPermission = GUILD_PERMISSION_BANK_VIEW_DEPOSIT_HISTORY,
            },
            {
                subcategoryType = GUILD_HISTORY_EVENT_SUBCATEGORY_WITHDRAWALS,
                gamepadIcon = "EsoUI/Art/Guild/History/Gamepad/gp_guildHistory_withdrawCurrency.dds",
                events =
                {
                    [GUILD_HISTORY_BANKED_CURRENCY_EVENT_WITHDRAWN] = true,
                    [GUILD_HISTORY_BANKED_CURRENCY_EVENT_HERALDRY_EDITED] = true,
                },
                gatingPermission = GUILD_PERMISSION_BANK_VIEW_WITHDRAW_HISTORY,
            },
            {
                subcategoryType = GUILD_HISTORY_EVENT_SUBCATEGORY_HIRED_TRADER,
                gamepadIcon = "EsoUI/Art/Guild/History/Gamepad/gp_guildHistory_trader.dds",
                events =
                {
                    [GUILD_HISTORY_BANKED_CURRENCY_EVENT_KIOSK_BID] = true,
                    [GUILD_HISTORY_BANKED_CURRENCY_EVENT_KIOSK_PURCHASED] = true,
                    [GUILD_HISTORY_BANKED_CURRENCY_EVENT_KIOSK_BID_REFUND] = true,
                },
                gatingPermission = GUILD_PERMISSION_GUILD_KIOSK_BID,
            },
        },
    },
    [GUILD_HISTORY_EVENT_CATEGORY_TRADER] =
    {
        up = "EsoUI/Art/Guild/History/guildHistory_purchases_up.dds",
        down = "EsoUI/Art/Guild/History/guildHistory_purchases_down.dds",
        over = "EsoUI/Art/Guild/History/guildHistory_purchases_over.dds",

        subcategories = 
        {
            {
                subcategoryType = GUILD_HISTORY_EVENT_SUBCATEGORY_PURCHASES,
                gamepadIcon = "EsoUI/Art/Guild/History/Gamepad/gp_guildHistory_purchases.dds",
            },
        },
    },
    [GUILD_HISTORY_EVENT_CATEGORY_AVA_ACTIVITY] =
    {
        up = "EsoUI/Art/Guild/History/guildHistory_allianceWar_up.dds",
        down = "EsoUI/Art/Guild/History/guildHistory_allianceWar_down.dds",
        over = "EsoUI/Art/Guild/History/guildHistory_allianceWar_over.dds",

        subcategories = 
        {
            {
                subcategoryType = GUILD_HISTORY_EVENT_SUBCATEGORY_OWNERSHIP,
                gamepadIcon = "EsoUI/Art/Guild/History/Gamepad/gp_guildHistory_allianceWar.dds",
            },
        },
    },
}

-------------
-- Manager --
-------------

ZO_GuildHistory_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_GuildHistory_Manager:Initialize()
    self.guilds = {}

    EVENT_MANAGER:RegisterForEvent("ZO_GuildHistory_Manager", EVENT_GUILD_HISTORY_CATEGORY_UPDATED, function(_, ...) self:OnCategoryUpdated(...) end)
    -- TODO: Manage leaving guilds
end

function ZO_GuildHistory_Manager:OnCategoryUpdated(guildId, eventCategory, flags)
    local guildData = self.guilds[guildId]
    if guildData then
        local categoryData = guildData:GetEventCategoryData(eventCategory)
        categoryData:OnCategoryUpdated(flags)
        self:FireCallbacks("CategoryUpdated", categoryData, flags)
    end
end

function ZO_GuildHistory_Manager:GetGuildData(guildId)
    if not self.guilds[guildId] then
        self.guilds[guildId] = ZO_GuildHistoryGuildData:New(guildId)
    end
    return self.guilds[guildId]
end

function ZO_GuildHistory_Manager.GetEventCategoryInfo(eventCategory)
    return GUILD_HISTORY_EVENT_CATEGORIES[eventCategory]
end

function ZO_GuildHistory_Manager.ComputeEventSubcategory(eventCategory, eventType)
    local categoryInfo = GUILD_HISTORY_EVENT_CATEGORIES[eventCategory]
    if categoryInfo then
        if #categoryInfo.subcategories > 1 then
            for subcategoryIndex, subcategoryInfo in ipairs(categoryInfo.subcategories) do
                if subcategoryInfo.events[eventType] then
                    return subcategoryIndex, subcategoryInfo.subcategoryType
                end
            end
        else
            local FIRST_SUBCATEGORY = 1
            return FIRST_SUBCATEGORY, categoryInfo.subcategories[FIRST_SUBCATEGORY].subcategoryType
        end
    end
end

function ZO_GuildHistory_Manager.GetNoEntriesText(eventCategory, subcategoryIndex, guildId)
    local hasPermissions = ZO_GuildHistory_Manager.HasPermissionsForCategoryAndSubcategory(eventCategory, subcategoryIndex, guildId)
    return hasPermissions and GetString(SI_GUILD_HISTORY_NO_ENTRIES) or GetString(SI_GUILD_CANT_VIEW_HISTORY)
end

function ZO_GuildHistory_Manager.HasPermissionsForCategoryAndSubcategory(eventCategory, subcategoryIndex, guildId)
    local categoryInfo = GUILD_HISTORY_EVENT_CATEGORIES[eventCategory]
    if categoryInfo then
        if subcategoryIndex then
            local subcategoryInfo = categoryInfo.subcategories[subcategoryIndex]
            if subcategoryInfo.gatingPermission and not DoesPlayerHaveGuildPermission(guildId, subcategoryInfo.gatingPermission) then
                return false
            end
        else
            local permissionsFailedOnAllSubcategories = true
            for i, subcategoryInfo in ipairs(categoryInfo.subcategories) do
                if not subcategoryInfo.gatingPermission or DoesPlayerHaveGuildPermission(guildId, subcategoryInfo.gatingPermission) then
                    --Subcategory was not gated or permission was met
                    permissionsFailedOnAllSubcategories = false
                    break
                end
            end

            if permissionsFailedOnAllSubcategories then
                return false
            end
        end
    end

    return true
end

GUILD_HISTORY_MANAGER = ZO_GuildHistory_Manager:New()