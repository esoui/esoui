ZO_TamrielTomesPurchaseScreen_Shared = ZO_DeferredInitializingObject:Subclass()

function ZO_TamrielTomesPurchaseScreen_Shared:Initialize(control, scene)
    self.control = control

    ZO_DeferredInitializingObject.Initialize(self, scene)

    self.fragment = ZO_FadeSceneFragment:New(control)
    scene:AddFragment(self.fragment)
end

function ZO_TamrielTomesPurchaseScreen_Shared:OnDeferredInitialize()
    self:InitializeControls()
    self:InitializeGridList()
    self:InitializeKeybindStripDescriptors()

    -- eventId, currencyType, currencyLocation, delta, reason, reasonInfo
    local function OnCurrencyUpdated(_, currencyType)
        if not self.control:IsHidden() then
            if currencyType == CURT_TOME_TOKENS then
                self:UpdateButtons()
                self:UpdateKeybinds()
            end
        end
    end

    self.control:RegisterForEvent(EVENT_CURRENCY_UPDATE, OnCurrencyUpdated)

    local function OnPurchaseDataUpdated()
        if self:IsShowing() then
            self:UpdateButtons()
        end
    end

    TAMRIEL_TOMES_MANAGER:RegisterCallback("DirectPurchaseDataUpdated", OnPurchaseDataUpdated)

    DIRECT_PURCHASE_MANAGER:RegisterCallback("PurchaseSkuResult", self.OnPurchaseSkuResult, self)
    DIRECT_PURCHASE_MANAGER:RegisterCallback("SettingsUpdated", self.OnSettingsUpdated, self)

    self:OnSettingsUpdated()
end

function ZO_TamrielTomesPurchaseScreen_Shared:InitializeControls()
    self.titleLabel = self.control:GetNamedChild("Title")
    self.imageControl = self.control:GetNamedChild("Image")
    self.gridListControl = self.control:GetNamedChild("GridList")
    self.buttonContainer = self.control:GetNamedChild("Buttons")
    self.row1ButtonContainer = self.buttonContainer:GetNamedChild("Row1")
    self.premiumButton = self.row1ButtonContainer:GetNamedChild("PremiumButton")
    self.premiumPlusButton = self.row1ButtonContainer:GetNamedChild("PremiumPlusButton")
    self.row2ButtonContainer = self.buttonContainer:GetNamedChild("Row2")
    self.tokenButton = self.row2ButtonContainer:GetNamedChild("TokenButton")
end

ZO_TamrielTomesPurchaseScreen_Shared:MUST_IMPLEMENT("InitializeGridList")
-- Should at least define self.keybindStripDescriptor
ZO_TamrielTomesPurchaseScreen_Shared:MUST_IMPLEMENT("InitializeKeybindStripDescriptors")
ZO_TamrielTomesPurchaseScreen_Shared:MUST_IMPLEMENT("GetRewardEntryTemplate")
ZO_TamrielTomesPurchaseScreen_Shared:MUST_IMPLEMENT("GetVerticalDividerEntryTemplate")
ZO_TamrielTomesPurchaseScreen_Shared:MUST_IMPLEMENT("ShowTokenRedemptionDialog")
ZO_TamrielTomesPurchaseScreen_Shared:MUST_IMPLEMENT("ShowInsufficientTokenRedemptionDialog")

function ZO_TamrielTomesPurchaseScreen_Shared:OnPurchaseSkuResult(result)
    if not self:IsShowing() then
        return
    end

    if result == DIRECT_PURCHASE_PURCHASE_SKU_RESULT_SUCCESS then
        PlaySound(SOUNDS.TAMRIEL_TOMES_PASS_PURCHASED)
    end
end

function ZO_TamrielTomesPurchaseScreen_Shared:OnSettingsUpdated()
    self:UpdateButtons()
end

function ZO_TamrielTomesPurchaseScreen_Shared:OnShowing()
    self:UpdateInfo()
    self:UpdateGridList()
    self:UpdateButtons()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TamrielTomesPurchaseScreen_Shared:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TamrielTomesPurchaseScreen_Shared:UpdateInfo()
    local selectedTomeId = TAMRIEL_TOMES_MANAGER:GetSelectedTomeId()
    local backgroundFile = GetTamrielTomePremiumUpgradeBackgroundFileIndex(selectedTomeId)
    self.imageControl:SetTexture(backgroundFile)
end

function ZO_TamrielTomesPurchaseScreen_Shared:UpdateGridList()
    self.gridList:ClearGridList()

    local selectedTomeId = TAMRIEL_TOMES_MANAGER:GetSelectedTomeId()
    local rewards = TAMRIEL_TOMES_MANAGER:GetFeaturedTomeRewards(selectedTomeId)
    local rewardEntryTemplate = self:GetRewardEntryTemplate()
    for index, reward in ipairs(rewards) do
        local rewardEntry = ZO_GridSquareEntryData_Shared:New(reward)
        self.gridList:AddEntry(rewardEntry, rewardEntryTemplate)
    end

    if #rewards > 0 then
        local verticalDividerEntryTemplate = self:GetVerticalDividerEntryTemplate()
        self.gridList:AddEntry({}, verticalDividerEntryTemplate)
    end

    -- TODO Tamriel Tomes bonus products

    self.gridList:CommitGridList()
end

function ZO_TamrielTomesPurchaseScreen_Shared:UpdateButtons()
    -- Use the enabled state of the Direct Purchase system to determine whether the buttons are visible.
    local isSystemEnabled = DIRECT_PURCHASE_MANAGER:IsSystemEnabled()
    self.buttonContainer:SetHidden(not isSystemEnabled)
    if not isSystemEnabled then
        return
    end

    local premiumProductData = TAMRIEL_TOMES_MANAGER:GetPurchaseDataForSelectedTomeProductType(TAMRIEL_TOME_PRODUCT_TYPE_PREMIUM)
    self.premiumButton.productData = premiumProductData
    if premiumProductData then
        local shouldEnablePremium = premiumProductData:CanPurchase()
        self.premiumButton:SetEnabled(shouldEnablePremium)

        -- TODO Tamriel Tomes: Better pricing info?
        local currentPrice, basePrice, currency = premiumProductData:GetPricingInfo()
        local priceString = string.format("%.2f %s", currentPrice, currency)
        self.premiumButton:SetText(zo_strformat(SI_TAMRIEL_TOMES_PREMIUM_UPGRADE_LABEL, priceString))
    else
        -- We shouldn't be in this screen if we don't have direct purchase data
        self.premiumButton:SetEnabled(false)
        self.premiumButton:SetText(GetString(SI_TAMRIEL_TOMES_PREMIUM_UPGRADE_WITHOUT_COST_LABEL))
    end

    local plusProductType = self:GetPremiumPlusProductType()
    local premiumPlusProductData = TAMRIEL_TOMES_MANAGER:GetPurchaseDataForSelectedTomeProductType(plusProductType)
    self.premiumPlusButton.productData = premiumPlusProductData
    local hasPremiumPlusProductData = premiumPlusProductData ~= nil
    if hasPremiumPlusProductData then
        -- TODO Tamriel Tomes: Better pricing info?
        local currentPrice, basePrice, currency = premiumPlusProductData:GetPricingInfo()
        local priceString = string.format("%.2f %s", currentPrice, currency)
        self.premiumPlusButton:SetText(zo_strformat(SI_TAMRIEL_TOMES_PREMIUM_PLUS_UPGRADE_LABEL, priceString))
    else
        -- We shouldn't be in this screen if we don't have direct purchase data
        self.premiumPlusButton:SetText(GetString(SI_TAMRIEL_TOMES_PREMIUM_PLUS_UPGRADE_WITHOUT_COST_LABEL))
    end

    self.premiumPlusButton:SetEnabled(hasPremiumPlusProductData)
    self.tokenButton:SetEnabled(hasPremiumPlusProductData)

    local currencyCost = GetCurrencyCostToUpgradeTamrielTome()
    local IS_UPPER = false
    local currencyName = GetCurrencyName(CURT_TOME_TOKENS, IsCountSingularForm(currencyCost), IS_UPPER)
    local tokenButtonString = zo_strformat(SI_TAMRIEL_TOMES_PREMIUM_PLUS_TOKEN_UPGRADE_LABEL, currencyCost, currencyName)
    self.tokenButton:SetText(tokenButtonString)
end

function ZO_TamrielTomesPurchaseScreen_Shared:GetPremiumPlusProductType()
    if self:CanAcquireTomeProduct(TAMRIEL_TOME_PRODUCT_TYPE_PREMIUM) and self:CanAcquireTomeProduct(TAMRIEL_TOME_PRODUCT_TYPE_PREMIUM_PLUS) then
        return TAMRIEL_TOME_PRODUCT_TYPE_PREMIUM_PLUS
    else
        return TAMRIEL_TOME_PRODUCT_TYPE_PREMIUM_PLUS_UPGRADE
    end
end

function ZO_TamrielTomesPurchaseScreen_Shared:RequestPurchaseTome(tomeProductType)
    local productData = TAMRIEL_TOMES_MANAGER:GetPurchaseDataForSelectedTomeProductType(tomeProductType)
    if productData then
        productData:RequestPurchase()
    end
end

function ZO_TamrielTomesPurchaseScreen_Shared:RequestPurchasePremiumTome()
    self:RequestPurchaseTome(TAMRIEL_TOME_PRODUCT_TYPE_PREMIUM)
end

function ZO_TamrielTomesPurchaseScreen_Shared:RequestPurchasePremiumPlusTome()
    local productType = self:GetPremiumPlusProductType()
    self:RequestPurchaseTome(productType)
end

function ZO_TamrielTomesPurchaseScreen_Shared:CanAcquireTomeProduct(tomeProductType)
    local productData = TAMRIEL_TOMES_MANAGER:GetPurchaseDataForSelectedTomeProductType(tomeProductType)
    if productData then
        local canPurchase = productData:CanPurchase()
        return canPurchase
    end

    return false
end

function ZO_TamrielTomesPurchaseScreen_Shared:RequestRedeemTomeTokens()
    local numTokens = GetPlayerStoredCurrencyAmount(CURT_TOME_TOKENS)
    local hasEnoughTokens = numTokens >= GetCurrencyCostToUpgradeTamrielTome()
    if hasEnoughTokens then
        self:ShowTokenRedemptionDialog()
    else
        self:ShowInsufficientTokenRedemptionDialog()
    end
end

function ZO_TamrielTomesPurchaseScreen_Shared.RewardGridEntrySetup(control, data, selected)
    control.data = data

    control.icon:SetHidden(false)
    control.icon:SetTexture(data:GetPlatformLootIcon())
    if data:GetQuantity() > 1 then
        local quantity = data:GetAbbreviatedQuantity()
        control.quantityLabel:SetText(quantity)
        control.quantityLabel:SetHidden(false)
    else
        control.quantityLabel:SetHidden(true)
    end
end

function ZO_TamrielTomesPurchaseScreen_Shared.RewardGridEntryReset(control)
    ZO_ObjectPool_DefaultResetControl(control)
end
