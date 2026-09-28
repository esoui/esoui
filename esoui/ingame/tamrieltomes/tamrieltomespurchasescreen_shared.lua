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
        if currencyType == CURT_TOME_TOKENS then
            self:UpdateButtons()
        end
    end

    self.control:RegisterForEvent(EVENT_CURRENCY_UPDATE, OnCurrencyUpdated)

    TAMRIEL_TOMES_MANAGER:RegisterCallback("SelectedTomeChanged", self.OnSelectedTomeChanged, self)
    TAMRIEL_TOMES_MANAGER:RegisterCallback("DirectPurchaseDataUpdated", self.UpdateButtons, self)
    DIRECT_PURCHASE_MANAGER:RegisterCallback("CatalogUpdated", self.UpdateButtons, self)
    DIRECT_PURCHASE_MANAGER:RegisterCallback("SettingsUpdated", self.OnSettingsUpdated, self)

    ZO_DIALOG_SYNC_OBJECT:SetHandler("OnStateChanged", function(_, shownDialog)
        self:OnDialogStateChanged(shownDialog)
    end, self:GetScene():GetName())

    ZO_DIALOG_SYNC_OBJECT:SetHandler("OnShown", function()
        self:OnDialogShown()
    end, self:GetScene():GetName())

    ZO_DIALOG_SYNC_OBJECT:SetHandler("OnHidden", function()
        self:OnDialogHidden()
    end, self:GetScene():GetName())

    self:OnSettingsUpdated()
end

function ZO_TamrielTomesPurchaseScreen_Shared:OnDialogStateChanged(shownDialog)
    if self:IsShowing() and shownDialog == "DIRECT_PURCHASE_RESULT" or shownDialog == "TAMRIEL_TOME_PURCHASE_RESULT" then
        self.refreshOnDialogHidden = true
    end
end

function ZO_TamrielTomesPurchaseScreen_Shared:OnDialogShown()
    -- To be overridden
end

function ZO_TamrielTomesPurchaseScreen_Shared:OnDialogHidden()
    if self.refreshOnDialogHidden then
        self.refreshOnDialogHidden = nil
        self:UpdateButtons()
    end
end

function ZO_TamrielTomesPurchaseScreen_Shared:InitializeControls()
    self.titleLabel = self.control:GetNamedChild("Title")
    self.imageControl = self.control:GetNamedChild("Image")
    self.gridListControl = self.control:GetNamedChild("GridList")
    self.premiumPlusIcon = self.control:GetNamedChild("PremiumPlusIcon")
    self.buttonContainer = self.control:GetNamedChild("Buttons")
    self.row1ButtonContainer = self.buttonContainer:GetNamedChild("Row1")
    self.premiumButton = self.row1ButtonContainer:GetNamedChild("PremiumButton")
    self.premiumPlusButton = self.row1ButtonContainer:GetNamedChild("PremiumPlusButton")
    self.premiumPlusDescription = self.row1ButtonContainer:GetNamedChild("PremiumPlusDescription")
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

function ZO_TamrielTomesPurchaseScreen_Shared:OnSettingsUpdated()
    self:UpdateButtons()
end

function ZO_TamrielTomesPurchaseScreen_Shared:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TamrielTomesPurchaseScreen_Shared:OnShown()
    self:UpdateInfo()
    self:UpdateGridList()

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self:UpdateButtons()

    if ShowPlatformStoreIcon then
        ShowPlatformStoreIcon(PLATFORM_STORE_ICON_LOCATION_LOWER_RIGHT)
    end
end

function ZO_TamrielTomesPurchaseScreen_Shared:OnHiding()
    if HidePlatformStoreIcon then
        HidePlatformStoreIcon()
    end
    self:EndPreviewFocusedReward()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TamrielTomesPurchaseScreen_Shared:OnSelectedTomeChanged()
    if self:IsShowing() then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        SCENE_MANAGER:HideCurrentScene()
    end
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

    local bonusRewardId, bonusRewardQuantity = TAMRIEL_TOMES_MANAGER:GetTomePremiumPlusBonusRewardInfo(selectedTomeId)
    local bonusRewardData = REWARDS_MANAGER:GetInfoForReward(bonusRewardId, bonusRewardQuantity)

    local bonusRewardEntry
    if bonusRewardData then
        if #rewards > 0 then
            local verticalDividerEntryTemplate = self:GetVerticalDividerEntryTemplate()
            self.gridList:AddEntry({}, verticalDividerEntryTemplate)
        end

        bonusRewardEntry = ZO_GridSquareEntryData_Shared:New(bonusRewardData)
        self.gridList:AddEntry(bonusRewardEntry, rewardEntryTemplate)
    end

    self.gridList:CommitGridList()

    self.premiumPlusIcon:SetHidden(true)
    if bonusRewardEntry then
        local control = self.gridList:GetControlFromData(bonusRewardEntry)
        if control then
            self.premiumPlusIcon:SetHidden(false)
            self.premiumPlusIcon:SetAnchor(CENTER, control, BOTTOM)
end
    end
end

function ZO_TamrielTomesPurchaseScreen_Shared:UpdateButtons()
    if not self:IsShowing() then
        return
    end

    if ZO_DIALOG_SYNC_OBJECT:IsShown() then
        self.refreshOnDialogHidden = true
        return
    end

    if not TAMRIEL_TOMES_MANAGER:CanPurchaseAnySelectedTomeProduct() then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        SCENE_MANAGER:HideCurrentScene()
        return
    end

    -- Use the enabled state of the Direct Purchase system to determine whether the buttons are visible.
    local isSystemEnabled = DIRECT_PURCHASE_MANAGER:IsSystemEnabled()
    self.buttonContainer:SetHidden(not isSystemEnabled)
    if not isSystemEnabled then
        return
    end

    local premiumProductType = TAMRIEL_TOME_PRODUCT_TYPE_PREMIUM
    local premiumProductData = TAMRIEL_TOMES_MANAGER:GetPurchaseDataForSelectedTomeProductType(premiumProductType)
    self.premiumButton.productData = premiumProductData
    local shouldEnablePremium = false
    if premiumProductData ~= nil then
        shouldEnablePremium = premiumProductData:CanPurchase()
        if shouldEnablePremium then
            local priceString = TAMRIEL_TOMES_MANAGER:GetPricingStringFormattedForSelectedTomeProductType(premiumProductType)
            self.premiumButton:SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
            self.premiumButton:SetText(priceString)
        else
            self.premiumButton:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
            self.premiumButton:SetText(GetString(SI_TAMRIEL_TOMES_PURCHASED_UPGRADE))
        end
    else
        -- We shouldn't be in this screen if we don't have direct purchase data.
        self.premiumButton:SetText("")
    end

    self.premiumButton:SetEnabled(shouldEnablePremium)

    local plusProductType = self:GetPremiumPlusProductType()
    local premiumPlusProductData = TAMRIEL_TOMES_MANAGER:GetPurchaseDataForSelectedTomeProductType(plusProductType)
    self.premiumPlusButton.productData = premiumPlusProductData
    local hasPremiumPlusProductData = premiumPlusProductData ~= nil
    if hasPremiumPlusProductData then
        local premiumPlusPriceString = TAMRIEL_TOMES_MANAGER:GetPricingStringFormattedForSelectedTomeProductType(plusProductType)
        self.premiumPlusButton:SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
        self.premiumPlusButton:SetText(premiumPlusPriceString)
    else
        -- We shouldn't be in this screen if we don't have direct purchase data.
        self.premiumPlusButton:SetText("")
    end

    self.premiumPlusButton:SetEnabled(hasPremiumPlusProductData)
    -- If premium is owned, you can't use tokens. If both are owned, you can't even be in this screen.
    self.tokenButton:SetEnabled(hasPremiumPlusProductData and shouldEnablePremium)

    local selectedTomeId = TAMRIEL_TOMES_MANAGER:GetSelectedTomeId()
    local premiumPlusDescription = hasPremiumPlusProductData and TAMRIEL_TOMES_MANAGER:GetTomePremiumPlusRewardDescription(selectedTomeId) or ""
    self.premiumPlusDescription:SetText(premiumPlusDescription)

    local currencyCost = GetCurrencyCostToUpgradeTamrielTome()
    local IS_UPPER = false
    local currencyName = GetCurrencyName(CURT_TOME_TOKENS, IsCountSingularForm(currencyCost), IS_UPPER)
    local tokenButtonString = zo_strformat(SI_TAMRIEL_TOMES_PREMIUM_PLUS_TOKEN_UPGRADE_LABEL, currencyCost, currencyName)
    self.tokenButton:SetText(tokenButtonString)

    self:UpdateKeybinds()
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
        productData:GetSkuData():RequestPurchase()
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
    control.quantityLabel:SetText(data:GetFormattedDisplayQuantity())
end

function ZO_TamrielTomesPurchaseScreen_Shared:SetFocusedRewardControl(control, isPopUpRewardData)
    if control then
        local rewardData = control.GetRewardData and control.GetRewardData() or control.data
        if rewardData then
            self.focusedRewardControl = control
            self.focusedRewardData = rewardData
            self.isFocusedRewardDataPopUp = isPopUpRewardData
            self:UpdateKeybinds()
            return
        end
    end
    self.focusedRewardControl = nil
    self.focusedRewardData = nil
    self.isFocusedRewardDataPopUp = nil
    self:UpdateKeybinds()
end

function ZO_TamrielTomesPurchaseScreen_Shared:GetPreviewFocusedRewardKeybindName()
    local rewardType = self.focusedRewardData:GetRewardType()
    if rewardType == REWARD_ENTRY_TYPE_REWARD_LIST then
        return GetString(SI_REWARD_LIST_VIEW_ACTION)
    end
    return GetString(SI_TAMRIEL_TOMES_PREVIEW_ACTION)
end

function ZO_TamrielTomesPurchaseScreen_Shared:CanPreviewFocusedReward()
    if self.focusedRewardData then
        local rewardType = self.focusedRewardData:GetRewardType()
        if rewardType == REWARD_ENTRY_TYPE_REWARD_LIST then
            return true
        else
            local rewardId = self.focusedRewardData:GetRewardId()
            return CanPreviewReward(rewardId) and not SYSTEMS:GetObject("itemPreview"):IsCurrentlyPreviewing(ZO_ITEM_PREVIEW_REWARD, rewardId)
        end
    end
    return false
end

function ZO_TamrielTomesPurchaseScreen_Shared:BeginPreviewFocusedReward()
    
end

function ZO_TamrielTomesPurchaseScreen_Shared:EndPreviewFocusedReward()
    SYSTEMS:GetObject("itemPreview"):EndCurrentPreview()
    self:UpdateKeybinds()
end

function ZO_TamrielTomesPurchaseScreen_Shared.RewardGridEntryReset(control)
    ZO_ObjectPool_DefaultResetControl(control)
end
