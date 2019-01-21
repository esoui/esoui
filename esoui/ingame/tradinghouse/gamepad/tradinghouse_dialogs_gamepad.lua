local CHECKED_ICON = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"

function ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog(itemData, dialogName, displayPrice, iconFile)
    local listingIndex = itemData.slotIndex
    local stackCount = itemData.stackCount
    local itemName = itemData.name

    local price = displayPrice
    local nameColor = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, itemData.quality))
    local currencyType = itemData.currencyType or CURT_MONEY
    
    local itemNameWithQuantity = nameColor:Colorize(zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, itemName, stackCount))
    local title = itemNameWithQuantity
    if iconFile then
        local iconMarkup = zo_iconFormat(iconFile, 55, 55)
        title = string.format("%s %s", iconMarkup, itemNameWithQuantity)
    end

    local priceText = zo_strformat(SI_GAMEPAD_TRADING_HOUSE_ITEM_AMOUNT, ZO_CurrencyControl_FormatCurrency(price), ZO_Currency_GetGamepadFormattedCurrencyIcon(currencyType))

    local mainTextParams
    if stackCount > 1 then
        mainTextParams = {title, "|c"..nameColor:ToHex(), itemName, stackCount, priceText}
    else
        mainTextParams = {title, nameColor:Colorize(itemName), priceText}
    end
    ZO_Dialogs_ShowGamepadDialog(dialogName, {listingIndex = listingIndex, stackCount = stackCount, price = price}, {mainTextParams = mainTextParams})
end

ESO_Dialogs["TRADING_HOUSE_CONFIRM_REMOVE_LISTING"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GAMEPAD_TRADING_HOUSE_LISTING_REMOVE_DIALOG_TITLE,
    },
    mainText = 
    {
        text =  function(dialog)
                    if dialog.data.stackCount > 1 then
                        return SI_GAMEPAD_TRADING_HOUSE_LISTING_REMOVE_MULTIPLE_DIALOG_TEXT
                    else
                        return SI_GAMEPAD_TRADING_HOUSE_LISTING_REMOVE_DIALOG_TEXT
                    end
                end,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_REMOVE,
            callback =  function(dialog)
                            CancelTradingHouseListing(dialog.data.listingIndex)
                        end
        },

        [2] =
        {
            text =       SI_DIALOG_CANCEL,
        }  
    }
}

local exitOnFinished = true
ESO_Dialogs["TRADING_HOUSE_CONFIRM_SELL_ITEM"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GAMEPAD_TRADING_HOUSE_CONFIRM_SELL_DIALOG_TITLE,
    },
    mainText = 
    {
        text =  function(dialog)
                    if dialog.data.stackCount > 1 then
                        return SI_GAMEPAD_TRADING_HOUSE_CONFIRM_SELL_MULTIPLE_DIALOG_TEXT
                    else
                        return SI_GAMEPAD_TRADING_HOUSE_CONFIRM_SELL_DIALOG_TEXT
                    end
                end,
    },
    setup = function()
        exitOnFinished = false
    end,
    finishedCallback = function(dialog)
        if exitOnFinished then
            SCENE_MANAGER:HideCurrentScene()
        end
    end,
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_YES,
            callback = function(dialog)
               local stackCount = dialog.data.stackCount
               local desiredPrice = dialog.data.price
               local listingIndex = dialog.data.listingIndex
               RequestPostItemOnTradingHouse(BAG_BACKPACK, listingIndex, stackCount, desiredPrice)
               exitOnFinished = true
            end
        },

        [2] =
        {
            text = SI_DIALOG_NO,
        }  
    }
}

ESO_Dialogs["TRADING_HOUSE_CONFIRM_BUY_ITEM"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GAMEPAD_TRADING_HOUSE_CONFIRM_BUY_DIALOG_TITLE,
    },
    mainText = 
    {
        text = function(dialog)
            if dialog.data.stackCount > 1 then
                return SI_GAMEPAD_TRADING_HOUSE_CONFIRM_BUY_MULTIPLE_DIALOG_TEXT
            else
                return SI_GAMEPAD_TRADING_HOUSE_CONFIRM_BUY_DIALOG_TEXT
            end
        end,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CONFIRM,
            callback =  function(dialog)
                            ConfirmPendingItemPurchase()
                         end
        },

        [2] =
        {
            text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CANCEL,
            callback =  function(dialog)
                            ClearPendingItemPurchase()
                        end
        }
    }
}

ESO_Dialogs["TRADING_HOUSE_CONFIRM_BUY_GUILD_SPECIFIC_ITEM"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GAMEPAD_TRADING_HOUSE_CONFIRM_BUY_DIALOG_TITLE,
    },
    mainText = 
    {
        text = function(dialog)
            if dialog.data.stackCount > 1 then
                return SI_GAMEPAD_TRADING_HOUSE_CONFIRM_BUY_MULTIPLE_DIALOG_TEXT
            else
                return SI_GAMEPAD_TRADING_HOUSE_CONFIRM_BUY_DIALOG_TEXT
            end
        end,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CONFIRM,
            callback =  function(dialog)
                            BuyGuildSpecificItem(dialog.data.listingIndex)
                         end
        },

        [2] =
        {
            text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CANCEL
        }
    }
}

local function IsActiveGuild(data)
    return data.isCurrentGuild
end

local function SetupTradingHouseGuildItem(control, data, ...)
    ZO_SharedGamepadEntry_OnSetup(control, data, ...)

    if IsActiveGuild(data) then
        control.statusIndicator:AddIcon(CHECKED_ICON)
        control.statusIndicator:Show()
    end
end

local GUILD_ENTRY_TEMPLATE = "ZO_GamepadSubMenuEntryWithStatusTemplate"

local function SetupGuildSelectionDialog(dialog)
    local currentGuildId = GetSelectedTradingHouseGuildId()

    dialog.info.parametricList = {}
    local indexToSelect = nil
    for i = 1, GetNumGuilds() do
        local guildId = GetGuildId(i)
        local guildName = GetGuildName(guildId)
        local allianceId = GetGuildAlliance(guildId)
        local icon = GetLargeAllianceSymbolIcon(allianceId)

        local listItem = 
        {
            template = GUILD_ENTRY_TEMPLATE,
            templateData = 
            {
                 guildId = guildId,
                 guildName = guildName,
                 allianceId = allianceId,
                 fontScaleOnSelection = false,
                 setup = SetupTradingHouseGuildItem,
                 isCurrentGuild = guildId == currentGuildId
            },
            icon = icon,
            text = guildName,
        }
        table.insert(dialog.info.parametricList, listItem)

        if guildId == currentGuildId then
            indexToSelect = i
        end
    end

    dialog:setupFunc()
    if indexToSelect then
        dialog.entryList:SetSelectedIndexWithoutAnimation(indexToSelect)
    end
end

ESO_Dialogs["TRADING_HOUSE_CHANGE_ACTIVE_GUILD"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
    },
    setup = SetupGuildSelectionDialog,
    title =
    {
        text = SI_GAMEPAD_TRADING_HOUSE_GUILD_SELECTION,
    },
    buttons =
    {
        [1] =
        {
            text = SI_GAMEPAD_SELECT_OPTION,
            callback = function(dialog)
               local data = dialog.entryList:GetTargetData()
               if data.guildId then
                   SelectTradingHouseGuildId(data.guildId)
               end
            end
        },

        [2] =
        {
            text = SI_DIALOG_EXIT,
        }
    }
}

ESO_Dialogs["TRADING_HOUSE_DISPLAY_ERROR"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_PROMPT_TITLE_ERROR,
    },
    mainText = 
    {
        text = SI_GAMEPAD_TRADING_HOUSE_ERROR_TEXT,
    },
    buttons =
    {
        [1] =
        {
            text =       SI_GAMEPAD_BACK_OPTION,
            keybind =    "DIALOG_NEGATIVE",
        }  
    }
}