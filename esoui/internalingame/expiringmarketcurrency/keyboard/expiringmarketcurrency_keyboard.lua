ZO_EXPIRING_MARKET_CURRENCY_DIALOG_ROW_KEYBOARD_HEIGHT = 32

local DATA_ENTRY_TYPE_EXPIRING_CURRENCY = 1

local function LayoutExpiringMarketCurrency(control)
    local list = control.list
    local emptyTextLabel = control.emptyTextLabel
    ZO_ScrollList_Clear(list)

    local numExpiringMarketCurrencyInfos = GetNumExpiringMarketCurrencyInfos()
    if numExpiringMarketCurrencyInfos == 0 then
        list:SetHidden(true)
        emptyTextLabel:SetHidden(false)
    else
        list:SetHidden(false)
        emptyTextLabel:SetHidden(true)

        local scrollData = ZO_ScrollList_GetDataList(list)
        for i = 1, numExpiringMarketCurrencyInfos do
            local currencyAmount, timeLeftS = GetExpiringMarketCurrencyInfo(i)

            local entryData =
            {
                currencyAmount = currencyAmount,
                timeLeftS = timeLeftS,
            }
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(DATA_ENTRY_TYPE_EXPIRING_CURRENCY, entryData))
        end
    end

    ZO_ScrollList_Commit(list)
end

local function ExpiringMarketCurrencyDialogSetup(dialog, data)
    RequestExpiringMarketCurrencyInfo()

    LayoutExpiringMarketCurrency(dialog.info.customControl)
end

function ZO_ExpiringMarketCurrencyDialog_Keyboard_OnInitialized(control)
    control.list = control:GetNamedChild("List")
    control.emptyTextLabel = control:GetNamedChild("EmptyText")

    local function SetupExpiringCurrencyRow(control, data)
        local textColor = ZO_SELECTED_TEXT
        if data.timeLeftS < EXPIRING_MARKET_CURRENCY_WARNING_THRESHOLD_SECONDS then
            textColor = ZO_ERROR_COLOR
        end

        local expiresAtLabel = control:GetNamedChild("ExpiresAt")
        local formattedTimeLeft = ZO_FormatTimeLongDurationExpiration(data.timeLeftS)
        expiresAtLabel:SetText(formattedTimeLeft)
        expiresAtLabel:SetColor(textColor:UnpackRGB())

        local amountLabel = control:GetNamedChild("Amount")
        local formattedCrownAmount = ZO_Currency_FormatKeyboard(CURT_CROWNS, data.currencyAmount, ZO_CURRENCY_FORMAT_AMOUNT_ICON, {color = ZO_SELECTED_TEXT})
        amountLabel:SetText(formattedCrownAmount)
    end
    ZO_ScrollList_AddDataType(control.list, DATA_ENTRY_TYPE_EXPIRING_CURRENCY, "ZO_ExpiringMarketCurrencyDialogRow_Keyboard", ZO_EXPIRING_MARKET_CURRENCY_DIALOG_ROW_KEYBOARD_HEIGHT, SetupExpiringCurrencyRow)

    local function OnCrownsUpdated()
        if ZO_Dialogs_IsShowing("KEYBOARD_EXPIRING_MARKET_CURRENCY_DIALOG") then
            RequestExpiringMarketCurrencyInfo()
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ExpiringMarketCurrencyDialog_Keyboard", EVENT_CROWN_UPDATE, OnCrownsUpdated)

    local function OnExpiringMarketCurrencyStateUpdated(eventId, state)
        if ZO_Dialogs_IsShowing("KEYBOARD_EXPIRING_MARKET_CURRENCY_DIALOG") and state == EXPIRING_MARKET_CURRENCY_STATE_READY then
            LayoutExpiringMarketCurrency(control)
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_ExpiringMarketCurrencyDialog_Keyboard", EVENT_EXPIRING_MARKET_CURRENCY_STATE_UPDATED, OnExpiringMarketCurrencyStateUpdated)

    local nextUpdateTimeSeconds = nil

    ESO_Dialogs["KEYBOARD_EXPIRING_MARKET_CURRENCY_DIALOG"] =
    {
        customControl = control,
        setup = ExpiringMarketCurrencyDialogSetup,
        canQueue = true,
        mustChoose = true,
        updateFn = function(control, seconds)
            -- Ensure that refresh only occurs on second boundaries
            if not nextUpdateTimeSeconds or seconds > nextUpdateTimeSeconds then
                nextUpdateTimeSeconds = zo_floor(seconds + ZO_ONE_MINUTE_IN_SECONDS)
                LayoutExpiringMarketCurrency(control)
            end
        end,
        title =
        {
            text = GetString(SI_KEYBOARD_EXPIRING_CROWNS_DIALOG_TITLE),
        },
        buttons =
        {
            {
                control = control:GetNamedChild("Close"),
                text = SI_DIALOG_CLOSE,
                keybind = "DIALOG_NEGATIVE",
            },
        },
    }
end
