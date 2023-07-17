ZO_HousingFurnitureProducts_Keyboard = ZO_HousingFurnitureList:Subclass()

function ZO_HousingFurnitureProducts_Keyboard:New(...)
    return ZO_HousingFurnitureList.New(self, ...)
end

function ZO_HousingFurnitureProducts_Keyboard:InitializeKeybindStrip()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        -- purchase
        {
            name = GetString(SI_HOUSING_FURNITURE_BROWSER_PURCHASE_KEYBIND),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                local IS_PURCHASE = false
                self:RequestPurchase(mostRecentlySelectedData, IS_PURCHASE)
            end,
            enabled = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                if mostRecentlySelectedData == nil then
                    return false, GetString(SI_HOUSING_BROWSER_MUST_CHOOSE_TO_PURCHASE)
                elseif not mostRecentlySelectedData:CanBePurchased() then
                    local expectedPurchaseResult = CouldPurchaseMarketProduct(mostRecentlySelectedData.marketProductId, mostRecentlySelectedData.presentationIndex)
                    return false, GetString("SI_MARKETPURCHASABLERESULT", expectedPurchaseResult)
                end
                return true
            end,
        },
        -- placement preview
        {
            name = GetString(SI_HOUSING_EDITOR_PREVIEW_PLACEMENT),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                self:PreviewMarketProductPlacement(mostRecentlySelectedData)
            end,
            visible = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                return mostRecentlySelectedData ~= nil and mostRecentlySelectedData:CanPreviewPlacement()
            end,
        },
        -- gift
        {
            name = GetString(SI_HOUSING_FURNITURE_BROWSER_GIFT_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                local IS_GIFT = true
                self:RequestPurchase(mostRecentlySelectedData, IS_GIFT)
            end,
            visible = function()
                local mostRecentlySelectedData = self:GetMostRecentlySelectedData()
                if mostRecentlySelectedData ~= nil then
                    return IsMarketProductGiftable(mostRecentlySelectedData.marketProductId, mostRecentlySelectedData.presentationIndex)
                end
                return false
            end,
        },
        -- end preview
        {
            name = GetString(SI_CRAFTING_EXIT_PREVIEW_MODE),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                self:ClearSelection()
            end,
            visible = function()
                local hasSelection = self:GetMostRecentlySelectedData() ~= nil and IsCurrentlyPreviewing()
                return hasSelection
            end,
        },
    }
end

function ZO_HousingFurnitureProducts_Keyboard:InitializeThemeSelector()
    self.purchaseThemeDropdown = self.contents:GetNamedChild("ThemeDropdown")

    local function OnThemeChanged(comboBox, entryText, entry)
        SHARED_FURNITURE:SetPurchaseFurnitureTheme(entry.furnitureTheme)
    end

    ZO_HousingSettingsTheme_SetupDropdown(self.purchaseThemeDropdown, OnThemeChanged)
end

function ZO_HousingFurnitureProducts_Keyboard:RefreshFilters()
    -- Get the current filter state.
    local themeFilter = SHARED_FURNITURE:GetPurchaseFurnitureTheme()
    local textFilter = SHARED_FURNITURE:GetPlaceableTextFilter()

    -- Update the Text Search filter to reflect the filter state.
    self.searchEditBox:SetText(textFilter)

    -- Update the Theme filter to reflect the filter state.
    do
        local themesList = ZO_ComboBox_ObjectFromContainer(self.purchaseThemeDropdown)
        for _, themeItem in ipairs(themesList:GetItems()) do
            if themeItem.furnitureTheme == themeFilter then
                themesList:SelectItem(themeItem)
                break
            end
        end
    end
end

function ZO_HousingFurnitureProducts_Keyboard:CompareFurnitureEntries(a, b)
    -- Primary order: New products before existing products.
    if a.isNew then
        if not b.isNew then
            return true
        end
    elseif b.isNew then
        return false
    end

    -- Secondary order: Product name in ascending alphabetical order.
    return ZO_HousingFurnitureList.CompareFurnitureEntries(self, a, b)
end

function ZO_HousingFurnitureProducts_Keyboard:OnSearchTextChanged(editBox)
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
            local IS_PURCHASE = false
            self:RequestPurchase(data, IS_PURCHASE)
        end
    end

    self:AddDataType(ZO_HOUSING_MARKET_PRODUCT_DATA_TYPE, "ZO_MarketProductFurnitureSlot", ZO_HOUSING_FURNITURE_LIST_ENTRY_HEIGHT, function(...) self:SetupMarketProductFurnitureRow(...) end, ZO_HousingFurnitureBrowser_Keyboard.OnHideFurnitureRow)
end

function ZO_HousingFurnitureProducts_Keyboard:RequestPurchase(data, isGift)
    ClearTooltip(ItemTooltip)
    RequestPurchaseMarketProduct(data.marketProductId, data.presentationIndex, isGift)
end

do
    local CURRENCY_ICON_SIZE = "100%"
    local INHERIT_ICON_COLOR = true

    function ZO_HousingFurnitureProducts_Keyboard:SetupMarketProductFurnitureRow(rowControl, marketProductFurnitureObject)
        local canBePurchased = marketProductFurnitureObject:CanBePurchased()
        local nameColorR, nameColorG, nameColorB
        local currencyColorR, currencyColorG, currencyColorB
        local iconDesaturation
        if canBePurchased then
            local displayQuality = marketProductFurnitureObject:GetDisplayQuality()
            nameColorR, nameColorG, nameColorB = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, displayQuality)
            currencyColorR, currencyColorG, currencyColorB = ZO_SELECTED_TEXT:UnpackRGB()
            iconDesaturation = 0
        else
            nameColorR, nameColorG, nameColorB = ZO_DISABLED_TEXT:UnpackRGB()
            currencyColorR, currencyColorG, currencyColorB = ZO_DISABLED_TEXT:UnpackRGB()
            iconDesaturation = 1
        end

        rowControl.name:SetText(marketProductFurnitureObject:GetFormattedName())
        rowControl.name:SetColor(nameColorR, nameColorG, nameColorB, 1)

        rowControl.icon:SetTexture(marketProductFurnitureObject:GetIcon())
        rowControl.icon:SetDesaturation(iconDesaturation)

        -- setup the cost
        local currencyType, cost, costAfterDiscount, discountPercent, esoPlusCost = marketProductFurnitureObject:GetMarketProductPricingByPresentation()
        local onSale = discountPercent > 0

        rowControl.textCallout:ClearAnchors()

        if onSale then
            local formattedAmount = zo_strformat(SI_NUMBER_FORMAT, cost)
            local strikethroughAmountString = zo_strikethroughTextFormat(formattedAmount)
            rowControl.previousCost:SetText(strikethroughAmountString)

            rowControl.textCallout:SetAnchor(RIGHT, rowControl.previousCost, LEFT, -10)
        else
            rowControl.textCallout:SetAnchor(RIGHT, rowControl.cost, LEFT, -10)
        end

        rowControl.previousCost:SetHidden(not onSale)

        -- format the price with the currency icon
        -- done this way so we can easily change the color of the string
        local currencyIcon = ZO_Currency_GetKeyboardFormattedCurrencyIcon(GetCurrencyTypeFromMarketCurrencyType(currencyType), CURRENCY_ICON_SIZE, INHERIT_ICON_COLOR)
        local currencyString = string.format("%s %s", zo_strformat(SI_NUMBER_FORMAT, costAfterDiscount), currencyIcon)

        rowControl.cost:SetText(currencyString)
        rowControl.cost:SetColor(currencyColorR, currencyColorG, currencyColorB, 1)

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
        elseif marketProductFurnitureObject.isNew and canBePurchased then -- only show the new tag if the product isn't purchased
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

--Overridden from ZO_HousingFurnitureList
function ZO_HousingFurnitureProducts_Keyboard:OnShowing()
    ZO_HousingFurnitureList.OnShowing(self)

    UpdateMarketDisplayGroup(MARKET_DISPLAY_GROUP_HOUSE_EDITOR)
    self:RefreshFilters()
end

--Overridden from ZO_HousingFurnitureList
function ZO_HousingFurnitureProducts_Keyboard:GetCategoryTreeData()
    return SHARED_FURNITURE:GetMarketProductCategoryTreeData()
end

--Overridden from ZO_HousingFurnitureList
function ZO_HousingFurnitureProducts_Keyboard:GetNoItemText()
    if SHARED_FURNITURE:AreThereMarketProducts() then
        return GetString(SI_HOUSING_FURNITURE_NO_SEARCH_RESULTS)
    else
        return GetString(SI_HOUSING_FURNITURE_NO_MARKET_PRODUCTS)
    end
end