ZO_HousingFurnitureProducts_Gamepad = ZO_HousingFurnitureList_Gamepad:Subclass()

function ZO_HousingFurnitureProducts_Gamepad:New(...)
    return ZO_HousingFurnitureList_Gamepad.New(self, ...)
end

function ZO_HousingFurnitureProducts_Gamepad:Initialize(owner)
    ZO_HousingFurnitureList_Gamepad.Initialize(self, owner)

    SHARED_FURNITURE:RegisterCallback("MarketProductsChanged", function(fromSearch)
        if fromSearch then
            self:ResetSavedPositions()
        end
    end)

    MARKET_CURRENCY_GAMEPAD:RegisterCallback("OnCurrencyUpdated", function() self:OnCurrencyUpdated() end)
end

function ZO_HousingFurnitureProducts_Gamepad:InitializeKeybindStripDescriptors()
    ZO_HousingFurnitureList_Gamepad.InitializeKeybindStripDescriptors(self)

    self:AddFurnitureListKeybind(
        -- Primary
        {
            name = GetString(SI_HOUSING_FURNITURE_BROWSER_PURCHASE_KEYBIND),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback =  function()
                            local targetData = self.furnitureList.list:GetTargetData()
                            if targetData then
                                local furnitureObject = targetData.furnitureObject
                                RequestPurchaseMarketProduct(furnitureObject.marketProductId, furnitureObject.presentationIndex)
                            end
                        end,
        }
    )

    local buyCrownsKeybind = MARKET_CURRENCY_GAMEPAD:GetBuyCrownsKeybind("UI_SHORTCUT_SECONDARY")

    self:AddFurnitureListKeybind(buyCrownsKeybind)

    table.insert(self.categoryKeybindStripDescriptor, buyCrownsKeybind)
end

function ZO_HousingFurnitureProducts_Gamepad:GetCategoryTreeDataRoot()
    return SHARED_FURNITURE:GetMarketProductCategoryTreeData()
end

function ZO_HousingFurnitureProducts_Gamepad:OnFurnitureTargetChanged(list, targetData, oldTargetData)
    ZO_HousingFurnitureList_Gamepad.OnFurnitureTargetChanged(self, list, targetData, oldTargetData)

    ZO_HousingFurnitureBrowser_Base.PreviewFurniture(targetData.furnitureObject)
    self:UpdateCurrentKeybinds()
end

function ZO_HousingFurnitureProducts_Gamepad:GetNoItemText()
    if SHARED_FURNITURE:AreThereMarketProducts() then
        return GetString(SI_HOUSING_FURNITURE_NO_SEARCH_RESULTS)
    else
        return GetString(SI_HOUSING_FURNITURE_NO_MARKET_PRODUCTS)
    end
end

function ZO_HousingFurnitureProducts_Gamepad:OnCurrencyUpdated()
    if GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE:IsShowing() then
        local currencyStyle = MARKET_CURRENCY_GAMEPAD:ModifyKeybindStripStyleForCurrency(KEYBIND_STRIP_GAMEPAD_STYLE)
        KEYBIND_STRIP:SetStyle(currencyStyle)
    end
end

function ZO_HousingFurnitureProducts_Gamepad:OnShowing()
    ZO_HousingFurnitureList_Gamepad.OnShowing(self)
    MARKET_CURRENCY_GAMEPAD:Show()
    self:OnCurrencyUpdated()
end

function ZO_HousingFurnitureProducts_Gamepad:OnHiding()
    ZO_HousingFurnitureList_Gamepad.OnHiding(self)
    MARKET_CURRENCY_GAMEPAD:Hide()
    KEYBIND_STRIP:SetStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
end