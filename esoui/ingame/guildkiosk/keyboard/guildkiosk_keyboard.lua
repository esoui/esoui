local GUILD_KIOSK_DIALOG_WIDTH = 400

local CURRENCY_OPTIONS =
{
    showTooltips = true,
    font = "ZoFontGameBold",
    iconSide = RIGHT,
}

--Purchase Kiosk
------------------------------

local PurchaseKioskDialog = ZO_Object:Subclass()

function PurchaseKioskDialog:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)    
    return object
end

function PurchaseKioskDialog:Initialize(control)
    local accept = function(selectedGuildId)
        GuildKioskPurchase(selectedGuildId)
        PlaySound(SOUNDS.ITEM_MONEY_CHANGED)
        INTERACT_WINDOW:OnEndInteraction(ZO_PURCHASE_KIOSK_INTERACTION)
    end

    local decline = function()
        INTERACT_WINDOW:OnEndInteraction(ZO_PURCHASE_KIOSK_INTERACTION)
    end
    
    local dialog = ZO_SelectGuildDialog:New(control, "PURCHASE_KIOSK", accept, decline)
    dialog:SetTitle(GetString(SI_GUILD_KIOSK_PURCHASE_TITLE))
    dialog:SetPrompt(GetString(SI_GUILD_KIOSK_PURCHASE_GUILD_CHOICE_HEADER))
    dialog:SetSelectedCallback(function(guildId) self:OnGuildSelected(guildId) end)
    dialog:SetButtonText(1, GetString(SI_GUILD_KIOSK_PURCHASE))
    dialog:SetGuildFilter(function(guildId)
        return DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_GUILD_KIOSK_BID)
    end)
    dialog:SetDialogUpdateFn(function(_, gameTimeSecs) ZO_GuildKiosk_Purchase_OnUpdate(self.descriptionLabel, gameTimeSecs) end)
    
    control:GetNamedChild("Title"):SetWidth(GUILD_KIOSK_DIALOG_WIDTH)
    self.descriptionLabel = control:GetNamedChild("Description")
    self.purchaseControls = control:GetNamedChild("PurchaseControls")
    self.guildBalanceLabel = self.purchaseControls:GetNamedChild("GuildBalance")
    self.purchaseCostLabel = self.purchaseControls:GetNamedChild("PurchaseCost")

    self.errorControls = control:GetNamedChild("ErrorControls")
    self.errorLabel = self.errorControls:GetNamedChild("Text")

    self.acceptButton = control:GetNamedChild("Accept")
end

--Events

function PurchaseKioskDialog:OnGuildSelected(guildId)
    local guildBankedMoney = GetKioskGuildInfo(guildId)
    local ownedKioskName = GetGuildOwnedKioskInfo(guildId)
    local guildCanUseTradingHouse = DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_TRADING_HOUSE)

    self.purchaseControls:SetHidden(true)
    self.errorControls:SetHidden(true)
    self.acceptButton:SetEnabled(false)

    if not guildCanUseTradingHouse then
        self.errorControls:SetHidden(false)
        self.errorLabel:SetText(zo_strformat(SI_GUILD_KIOSK_PURCHASE_ERROR_TRADING_HOUSE_LOCKED, GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_TRADING_HOUSE)))
    elseif ownedKioskName then
        self.errorControls:SetHidden(false)
        self.errorLabel:SetText(zo_strformat(SI_GUILD_KIOSK_PURCHASE_ERROR_KIOSK_RENTED, ownedKioskName))
    elseif guildBankedMoney then
        local enoughMoney = guildBankedMoney >= GetKioskPurchaseCost()
        ZO_CurrencyControl_SetSimpleCurrency(self.guildBalanceLabel, CURT_MONEY, guildBankedMoney, CURRENCY_OPTIONS)
        ZO_CurrencyControl_SetSimpleCurrency(self.purchaseCostLabel, CURT_MONEY, GetKioskPurchaseCost(), CURRENCY_OPTIONS, nil, not enoughMoney)
        self.purchaseControls:SetHidden(false)
        self.acceptButton:SetEnabled(enoughMoney)
    end
end

function PurchaseKioskDialog:OnGuildKioskConsiderPurchaseStart()
    if(not ZO_Dialogs_FindDialog("PURCHASE_KIOSK")) then
        ZO_Dialogs_ShowDialog("PURCHASE_KIOSK")
        INTERACT_WINDOW:OnBeginInteraction(ZO_PURCHASE_KIOSK_INTERACTION)
    end
end

function PurchaseKioskDialog:OnGuildKioskConsiderPurchaseStop()
    ZO_Dialogs_ReleaseDialog("PURCHASE_KIOSK")
end

--Global XML

function ZO_GuildKioskPurchaseDialog_OnInitialized(self)
    PURCHASE_KIOSK_DIALOG = PurchaseKioskDialog:New(self)
    SYSTEMS:RegisterKeyboardObject("guildKioskPurchase", PURCHASE_KIOSK_DIALOG)
end

--Bid On Kiosk
-------------------

local BidOnKioskDialog = ZO_Object:Subclass()

function BidOnKioskDialog:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)    
    return object
end

function BidOnKioskDialog:Initialize(control)
    local accept = function(selectedGuildId)
        local bidAmount = ZO_DefaultCurrencyInputField_GetCurrency(self.newBidInput)
        GuildKioskBid(selectedGuildId, bidAmount)
        PlaySound(SOUNDS.ITEM_MONEY_CHANGED)
        INTERACT_WINDOW:OnEndInteraction(ZO_BID_ON_KIOSK_INTERACTION)
    end

    local decline = function()
        INTERACT_WINDOW:OnEndInteraction(ZO_BID_ON_KIOSK_INTERACTION)
    end
    
    self.dialog = ZO_SelectGuildDialog:New(control, "BID_ON_KIOSK", accept, decline)
    self.dialog:SetTitle(GetString(SI_GUILD_KIOSK_BID_TITLE))
    self.dialog:SetPrompt(GetString(SI_GUILD_KIOSK_BID_GUILD_CHOICE_HEADER))
    self.dialog:SetSelectedCallback(function(guildId) self:OnGuildSelected(guildId) end)
    self.dialog:SetButtonText(1, GetString(SI_GUILD_KIOSK_BID))
    self.dialog:SetGuildFilter(function(guildId)
        return DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_GUILD_KIOSK_BID)
    end)
    self.dialog:SetDialogUpdateFn(function(_, gameTimeSecs) self:OnUpdate(gameTimeSecs) end)
    
    control:GetNamedChild("Title"):SetWidth(GUILD_KIOSK_DIALOG_WIDTH)
    control:GetNamedChild("Description"):SetText(GetString(SI_GUILD_KIOSK_BID_DESCRIPTION))
    self.control = control
    self.bidControls = control:GetNamedChild("BidControls")
    self.guildBalanceLabel = self.bidControls:GetNamedChild("GuildBalance")
    self.currentBidLabel = self.bidControls:GetNamedChild("CurrentBid")
    self.currentBidHeaderLabel = self.bidControls:GetNamedChild("CurrentBidHeader")
    self.biddingClosesLabel = self.bidControls:GetNamedChild("BiddingCloses")
    self.newBidInput = self.bidControls:GetNamedChild("NewBid")

    self.errorControls = control:GetNamedChild("ErrorControls")
    self.errorLabel = self.errorControls:GetNamedChild("Text")

    self.acceptButton = control:GetNamedChild("Accept")

    ZO_DefaultCurrencyInputField_Initialize(self.newBidInput, function(input, money)
        self:OnMoneyChanged(money)
    end)
end

--Events

function BidOnKioskDialog:OnUpdate(gameTimeSecs)    
    if(self.nextUpdateSecs == nil or gameTimeSecs >= self.nextUpdateSecs) then
        self.nextUpdateSecs = gameTimeSecs + 1
        local secsRemaining = GetKioskBidWindowSecondsRemaining()
        local ownershipDuration = ZO_FormatTimeLargestTwo(secsRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE)
        self.biddingClosesLabel:SetText(ownershipDuration)
    end
end

function BidOnKioskDialog:OnGuildSelected(guildId)
    local guildBankedMoney, existingBidAmount, existingBidIsOnThisKiosk, existingBidKioskName = GetKioskGuildInfo(guildId)
    local guildCanUseTradingHouse = DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_TRADING_HOUSE)

    self.bidControls:SetHidden(true)
    self.errorControls:SetHidden(true)
    self.acceptButton:SetEnabled(false)

    if not guildCanUseTradingHouse then
        self.errorControls:SetHidden(false)
        self.errorLabel:SetText(zo_strformat(SI_GUILD_KIOSK_BID_ERROR_TRADING_HOUSE_LOCKED, GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_TRADING_HOUSE)))
    elseif not existingBidIsOnThisKiosk and existingBidKioskName then
        self.errorControls:SetHidden(false)
        self.errorLabel:SetText(zo_strformat(SI_GUILD_KIOSK_BID_ERROR_EXISTING_BID, existingBidKioskName))
    elseif guildBankedMoney and (existingBidAmount == 0 or existingBidIsOnThisKiosk) then
        local bidAmount = 0

        ZO_DefaultCurrencyInputField_SetCurrencyMax(self.newBidInput, guildBankedMoney + existingBidAmount)

        self.bidControls:SetHidden(false)
        if(existingBidAmount == 0) then
            local kioskPurchaseCost = GetKioskPurchaseCost()

            ZO_CurrencyControl_SetSimpleCurrency(self.currentBidLabel, CURT_MONEY, kioskPurchaseCost, CURRENCY_OPTIONS)
            self.currentBidHeaderLabel:SetText(GetString(SI_GUILD_KIOSK_MINIMUM_BID_HEADER))

            if guildBankedMoney >= kioskPurchaseCost then
                bidAmount = kioskPurchaseCost
            else
                ZO_DefaultCurrencyInputField_SetCurrencyMax(self.newBidInput, 0)
            end
        else
            ZO_CurrencyControl_SetSimpleCurrency(self.currentBidLabel, CURT_MONEY, existingBidAmount, CURRENCY_OPTIONS)
            self.currentBidHeaderLabel:SetText(GetString(SI_GUILD_KIOSK_CURRENT_BID_HEADER))

            if guildBankedMoney > 0 then
                bidAmount = existingBidAmount + 1
            else
                ZO_DefaultCurrencyInputField_SetCurrencyMax(self.newBidInput, 0)
            end
        end
        
        ZO_CurrencyControl_SetSimpleCurrency(self.guildBalanceLabel, CURT_MONEY, guildBankedMoney, CURRENCY_OPTIONS)
        ZO_DefaultCurrencyInputField_SetCurrencyMin(self.newBidInput, bidAmount)
        ZO_DefaultCurrencyInputField_SetCurrencyAmount(self.newBidInput, bidAmount)

        self:RefreshUpdateBidEnabled(bidAmount)
    end
end

function BidOnKioskDialog:RefreshUpdateBidEnabled(bidAmount)
    local guildId = self.dialog:GetSelectedGuildId()
    if(guildId) then
        local _, existingBidAmount, existingBidIsOnThisKiosk = GetKioskGuildInfo(guildId)
        if(existingBidAmount) then
            local bidOnADifferentKioskAlready = existingBidAmount > 0 and not existingBidIsOnThisKiosk
            local minBid = GetKioskPurchaseCost()
            self.acceptButton:SetEnabled(not bidOnADifferentKioskAlready and bidAmount > existingBidAmount and bidAmount >= minBid)
        else
            self.acceptButton:SetEnabled(false)
        end
    end
end

function BidOnKioskDialog:OnMoneyChanged(money)
    self:RefreshUpdateBidEnabled(money)
end

function BidOnKioskDialog:OnGuildKioskConsiderBidStart()
    if(not ZO_Dialogs_FindDialog("BID_ON_KIOSK")) then
        ZO_Dialogs_ShowDialog("BID_ON_KIOSK")
        INTERACT_WINDOW:OnBeginInteraction(ZO_BID_ON_KIOSK_INTERACTION)
    end
end

function BidOnKioskDialog:OnGuildKioskConsiderBidStop()
    ZO_Dialogs_ReleaseDialog("BID_ON_KIOSK")
end

--Global XML

function ZO_GuildKioskBidDialog_OnInitialized(self)
    BID_ON_KIOSK_DIALOG = BidOnKioskDialog:New(self)
    SYSTEMS:RegisterKeyboardObject("guildKioskBid", BID_ON_KIOSK_DIALOG)
end