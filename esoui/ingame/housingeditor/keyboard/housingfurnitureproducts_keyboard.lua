ZO_HousingFurnitureProducts_Keyboard = ZO_HousingFurnitureList:Subclass()

function ZO_HousingFurnitureProducts_Keyboard:New(...)
    return ZO_HousingFurnitureList.New(self, ...)
end

function ZO_HousingFurnitureProducts_Keyboard:InitializeKeybindStrip()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_HOUSING_FURNITURE_BROWSER_PURCHASE_KEYBIND),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                self:RequestPurchase(mostRecentlySelectedData)
            end,
            enabled = function()
                local hasMostRecentlySelectedData = self:GetMostRecentlySelectedData() ~= nil
                if not hasMostRecentlySelectedData then
                    return false, GetString(SI_HOUSING_BROWSER_MUST_CHOOSE_TO_PURCHASE)
                end
                return true
            end,
        },
        {
            name = GetString(SI_CRAFTING_EXIT_PREVIEW_MODE),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                self:ClearSelection()
            end,
            visible = function()
                local hasSelection = self:GetMostRecentlySelectedData() ~= nil
                return hasSelection
            end,
        },
    }
end

function ZO_HousingFurnitureProducts_Keyboard:OnSearchTextChanged(editBox)
    ZO_HousingFurnitureList.OnSearchTextChanged(self, editBox)
    SHARED_FURNITURE:SetMarketProductTextFilter(editBox:GetText())
end

function ZO_HousingFurnitureProducts_Keyboard:AddListDataTypes()
    self.MarketProductOnMouseClickCallback = function(control, buttonIndex, upInside)
        if buttonIndex == MOUSE_BUTTON_INDEX_LEFT and upInside then
            ZO_ScrollList_MouseClick(self:GetList(), control)
        end
    end

    self.MarketProductFurnitureOnMouseDoubleClickCallback = function(control, buttonIndex)
        if buttonIndex == MOUSE_BUTTON_INDEX_LEFT then
            local data = ZO_ScrollList_GetData(control)
            self:RequestPurchase(data)
        end
    end

    self:AddDataType(ZO_HOUSING_MARKET_PRODUCT_DATA_TYPE, "ZO_MarketProductFurnitureSlot", ZO_HOUSING_FURNITURE_LIST_ENTRY_HEIGHT, function(...) self:SetupMarketProductFurnitureRow(...) end, ZO_HousingFurnitureBrowser_Keyboard.OnHideFurnitureRow)
end

function ZO_HousingFurnitureProducts_Keyboard:RequestPurchase(data)
    ClearTooltip(ItemTooltip)
    RequestPurchaseMarketProduct(data.marketProductId, data.presentationIndex)
end

do
    local CURRENCY_ICON_SIZE = "100%"

    function ZO_HousingFurnitureProducts_Keyboard:SetupMarketProductFurnitureRow(rowControl, marketProductFurnitureObject)
        rowControl.name:SetText(marketProductFurnitureObject:GetFormattedName())

        local quality = marketProductFurnitureObject:GetQuality()
        local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)
        rowControl.name:SetColor(r, g, b, 1)

        rowControl.icon:SetTexture(marketProductFurnitureObject:GetIcon())

        -- setup the cost
        local currencyType, cost, hasDiscount, costAfterDiscount, discountPercent = marketProductFurnitureObject:GetMarketProductPricingByPresentation()
        local onSale = discountPercent > 0

        rowControl.textCallout:ClearAnchors()

        if onSale then
            rowControl.previousCost:SetText(ZO_CommaDelimitNumber(cost))
            rowControl.textCallout:SetAnchor(RIGHT, rowControl.previousCost, LEFT, -10)
        else
            rowControl.textCallout:SetAnchor(RIGHT, rowControl.cost, LEFT, -10)
        end

        rowControl.previousCost:SetHidden(not onSale)

        local currencyIcon = ZO_Currency_GetPlatformFormattedCurrencyIcon(ZO_Currency_MarketCurrencyToUICurrency(currencyType), CURRENCY_ICON_SIZE)
        local currencyString = zo_strformat(SI_CURRENCY_AMOUNT_WITH_ICON, ZO_CommaDelimitNumber(costAfterDiscount), currencyIcon)
        rowControl.cost:SetText(currencyString)

        local textCalloutBackgroundColor
        local textCalloutTextColor
        local textCalloutUpdateHandler
        if marketProductFurnitureObject:IsLimitedTimeProduct() then
            textCalloutBackgroundColor = ZO_BLACK
            textCalloutTextColor = ZO_MARKET_PRODUCT_ON_SALE_COLOR
            marketProductFurnitureObject:SetTimeLeftOnLabel(rowControl.textCallout)
            textCalloutUpdateHandler = function() marketProductFurnitureObject:SetTimeLeftOnLabel(rowControl.textCallout) end
        elseif marketProductFurnitureObject.onSale then
            textCalloutBackgroundColor = ZO_MARKET_PRODUCT_ON_SALE_COLOR
            textCalloutTextColor = ZO_SELECTED_TEXT
            rowControl.textCallout:SetText(zo_strformat(SI_MARKET_DISCOUNT_PRICE_PERCENT_FORMAT, marketProductFurnitureObject.discountPercent))
            rowControl.textCallout:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        elseif marketProductFurnitureObject.isNew then
            textCalloutBackgroundColor = ZO_MARKET_PRODUCT_NEW_COLOR
            textCalloutTextColor = ZO_SELECTED_TEXT
            rowControl.textCallout:SetText(GetString(SI_MARKET_TILE_CALLOUT_NEW))
            rowControl.textCallout:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        end

        if textCalloutBackgroundColor then
            marketProductFurnitureObject.SetCalloutBackgroundColor(rowControl.textCalloutLeftBackground, rowControl.textCalloutRightBackground, rowControl.textCalloutCenterBackground, textCalloutBackgroundColor)
            rowControl.textCallout:SetColor(textCalloutTextColor:UnpackRGB())
        end

        rowControl.textCallout:SetHidden(not textCalloutBackgroundColor)
        rowControl.textCallout:SetHandler("OnUpdate", textCalloutUpdateHandler)

        rowControl.OnMouseClickCallback = self.MarketProductOnMouseClickCallback
        rowControl.OnMouseDoubleClickCallback = self.MarketProductFurnitureOnMouseDoubleClickCallback
        rowControl.furnitureObject = marketProductFurnitureObject
    end
end

function ZO_HousingFurnitureProducts_Keyboard:GetCategoryTreeData()
    return SHARED_FURNITURE:GetMarketProductCategoryTreeData()
end

function ZO_HousingFurnitureProducts_Keyboard:GetNoItemText()
    if SHARED_FURNITURE:AreThereMarketProducts() then
        return GetString(SI_HOUSING_FURNITURE_NO_SEARCH_RESULTS)
    else
        return GetString(SI_HOUSING_FURNITURE_NO_MARKET_PRODUCTS)
    end
end