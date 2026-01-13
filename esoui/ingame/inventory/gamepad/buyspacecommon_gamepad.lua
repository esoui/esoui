
ZO_BuySpaceGamepad = ZO_InitializingObject:Subclass()

function ZO_BuySpaceGamepad:Initialize(control, infoTextCanAfford, infoTextCanNotAfford, buyFunc)
    self.control = control
    self.infoTextCanAfford = infoTextCanAfford
    self.infoTextCanNotAfford = infoTextCanNotAfford 
    self.buyFunc = buyFunc

    self.isInitialized = false
end

function ZO_BuySpaceGamepad:PerformDeferredInitialization()
    if self.isInitialized then
        return
    end

    self.infoText = self.control:GetNamedChild("Info")
    self.goldText = self.control:GetNamedChild("MyGold"):GetNamedChild("Amount")
    self.costText = self.control:GetNamedChild("Cost"):GetNamedChild("Amount")
    self.unlocksRemainingText = self.control:GetNamedChild("UnlocksRemaining")

    self:InitializeKeybindStripDescriptors()

    local OnUpdate = function()
        if self.cost then
            local canAfford = self.cost <= GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
            if self.canAfford == nil or self.canAfford ~= canAfford then
                self.canAfford = canAfford
            
                if self.canAfford then
                    self.infoText:SetText(self.infoTextCanAfford)
                else
                    self.infoText:SetText(self.infoTextCanNotAfford)
                end
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end
            ZO_CurrencyControl_SetSimpleCurrency(self.costText, CURT_MONEY, self.cost, ZO_GAMEPAD_CURRENCY_OPTIONS)
            ZO_CurrencyControl_SetSimpleCurrency(self.goldText, CURT_MONEY, GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER), ZO_GAMEPAD_CURRENCY_OPTIONS)
        end
    end

    self.control:SetHandler("OnUpdate", OnUpdate)

    self.isInitialized = true
end

function ZO_BuySpaceGamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_DIALOG_ACCEPT),
            callback = function()
                self.buyFunc()
                SCENE_MANAGER:HideCurrentScene()
            end,
            visible = function() return self.canAfford end,
            order = 0,
        },
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = function()
                if self.canAfford then
                    return GetString(SI_DIALOG_DECLINE)
                else
                    return GetString(SI_GAMEPAD_BACK_OPTION)
                end
            end,
            order = 1,
            callback = function() SCENE_MANAGER:HideCurrentScene() end,
        },
    }
end

function ZO_BuySpaceGamepad:Activate(cost)
    self:PerformDeferredInitialization()

    self.cost = cost

    local currentUnlock = GetCurrentBackpackUpgrade()
    local maxUnlock = GetMaxBackpackUpgrade()
    local unlocksRemaining = zo_strformat(SI_BUY_BAG_SPACE_UPGRADES_REMAINING, maxUnlock - currentUnlock)
    self.unlocksRemainingText:SetText(unlocksRemaining)

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_BuySpaceGamepad:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_BuySpaceGamepad:GetNarrationText()
    local narrations = {}

    --Narrate player gold
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetCurrencyName(CURT_MONEY, IS_PLURAL, IS_UPPER)))
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_Currency_GetPlayerCarriedGoldCurrencyNameNarration()))

    --Narrate cost
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_BUY_BAG_SPACE_COST)))
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_Currency_FormatGamepad(CURT_MONEY, self.cost, ZO_CURRENCY_FORMAT_AMOUNT_NAME)))

    --Narrate info text
    if self.canAfford then
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.infoTextCanAfford))
    else
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.infoTextCanNotAfford))
    end

    --Narrate unlocks remaining
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.unlocksRemainingText:GetText()))

    return narrations
end