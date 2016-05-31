local CHECKED_ICON = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"

local function GetCurrencyTextString(currencyType)
    if currencyType == CURT_ALLIANCE_POINTS then
        return SI_GAMEPAD_TRADING_HOUSE_ITEM_AMOUNT_ALLIANCE_POINTS
    else
        return SI_GAMEPAD_TRADING_HOUSE_ITEM_AMOUNT
    end
end

function ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog(selectedData, dialogName, displayPrice)

    local listingIndex = ZO_Inventory_GetSlotIndex(selectedData)
    local stackCount = ZO_InventorySlot_GetStackCount(selectedData)

    local GET_SELECTED_ICON = true
    local ICON_DEFAULT_INDEX = 1
    local icon = selectedData.icon
    local iconFile = selectedData:GetIcon(ICON_DEFAULT_INDEX, GET_SELECTED_ICON)
    local price = displayPrice
    local nameColor = selectedData.selectedNameColor or ZO_SELECTED_TEXT
    local itemName = nameColor:Colorize(selectedData.name)
    local currencyType = selectedData.currencyType
    
    local itemIconAndName = itemName
    if iconFile then
        local iconText = zo_iconFormat(iconFile, 55, 55)
        itemIconAndName = zo_strformat(SI_GAMEPAD_TRADING_HOUSE_ITEM_DESCRIPTION, iconText, itemName)
    end

    costLabelStringId = GetCurrencyTextString(currencyType)
    local priceText = zo_strformat(costLabelStringId, ZO_CurrencyControl_FormatCurrency(price))

    ZO_Dialogs_ShowGamepadDialog(dialogName, {listingIndex = listingIndex, stackCount = stackCount, price = price}, {mainTextParams = {itemIconAndName, itemName, priceText}})
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
        text = SI_GAMEPAD_TRADING_HOUSE_LISTING_REMOVE_DIALOG_TEXT,
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
        text = SI_GAMEPAD_TRADING_HOUSE_CONFIRM_SELL_DIALOG_TEXT,
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
            text =      SI_DIALOG_YES,
            callback =  function(dialog)
                            local stackCount = dialog.data.stackCount
                            local desiredPrice = dialog.data.price
                            local listingIndex = dialog.data.listingIndex
                            RequestPostItemOnTradingHouse(BAG_BACKPACK, listingIndex, stackCount, desiredPrice)
                            TRADING_HOUSE_GAMEPAD:SetSearchAllowed(true) -- allow update to cached search results to find newly sold items
                            exitOnFinished = true
                         end
        },

        [2] =
        {
            text =       SI_DIALOG_NO,
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
        text = SI_GAMEPAD_TRADING_HOUSE_CONFIRM_BUY_DIALOG_TEXT,
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
        text = SI_GAMEPAD_TRADING_HOUSE_CONFIRM_BUY_DIALOG_TEXT,
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
    local currentGuildID = GetSelectedTradingHouseGuildId()

    dialog.info.parametricList = {}
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
                 isCurrentGuild = guildId == currentGuildID
            },
            icon = icon,
            text = guildName,
        }
        table.insert(dialog.info.parametricList, listItem)
    end

    dialog:setupFunc()
    dialog.entryList:SetSelectedDataByEval(IsActiveGuild)
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
            text =      SI_GAMEPAD_SELECT_OPTION,
            callback =  function(dialog)
                            local data = dialog.entryList:GetTargetData()
                            if(data.guildId) then
                                if(SelectTradingHouseGuildId(data.guildId)) then
                                    TRADING_HOUSE_GAMEPAD:UpdateForGuildChange()
                                end
                            end
                         end
        },

        [2] =
        {
            text =      SI_DIALOG_EXIT,
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