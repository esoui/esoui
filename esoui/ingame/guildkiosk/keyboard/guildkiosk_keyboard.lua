local GUILD_KIOSK_DIALOG_WIDTH = 450

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
    dialog:SetUpdateGuildListWhileShown(false)
    
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
    self.dialog:SetGuildFilter(function(guildId)
        return DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_GUILD_KIOSK_BID)
    end)
    self.dialog:SetDialogUpdateFn(function(_, gameTimeSecs) self:OnUpdate(gameTimeSecs) end)
    self.dialog:SetUpdateGuildListWhileShown(false)

    control:GetNamedChild("Title"):SetWidth(GUILD_KIOSK_DIALOG_WIDTH)
    control:GetNamedChild("Description"):SetText(zo_strformat(SI_GUILD_KIOSK_BID_DESCRIPTION, GetMaxKioskBidsPerGuild()))
    self.control = control
    self.bidControls = control:GetNamedChild("BidControls")
    self.guildBalanceLabel = self.bidControls:GetNamedChild("GuildBalance")
    self.currentBidLabel = self.bidControls:GetNamedChild("CurrentBid")
    self.currentBidHeaderLabel = self.bidControls:GetNamedChild("CurrentBidHeader")
    self.biddingClosesLabel = self.bidControls:GetNamedChild("BiddingCloses")
    self.weeklyBidsLabel = self.bidControls:GetNamedChild("WeeklyBids")
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
    local guildBankedMoney, existingBidAmount, numTotalBids = GetKioskGuildInfo(guildId)
    local maxBidsPerGuild = GetMaxKioskBidsPerGuild()
    local hasBidOnThisTraderAlready = existingBidAmount > 0
    local guildCanUseTradingHouse = DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_TRADING_HOUSE)

    self.bidControls:SetHidden(true)
    self.errorControls:SetHidden(true)
    self.acceptButton:SetEnabled(false)

    self.dialog:SetButtonText(1, ZO_GuildKiosk_Bid_Shared.GetBidActionText(hasBidOnThisTraderAlready))

    if not guildCanUseTradingHouse then
        self.errorControls:SetHidden(false)
        self.errorLabel:SetText(zo_strformat(SI_GUILD_KIOSK_BID_ERROR_TRADING_HOUSE_LOCKED, GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_TRADING_HOUSE)))
    elseif not hasBidOnThisTraderAlready and numTotalBids >= maxBidsPerGuild then
        self.errorControls:SetHidden(false)
        self.errorLabel:SetText(GetString("SI_GUILDKIOSKRESULT", GUILD_KIOSK_TOO_MANY_BIDS))
    elseif guildBankedMoney then
        local minBidAllowed = 0

        ZO_DefaultCurrencyInputField_SetCurrencyMax(self.newBidInput, guildBankedMoney + existingBidAmount)

        local shouldGuildBankGoldShowErrorColor = false
        self.bidControls:SetHidden(false)
        if existingBidAmount == 0 then
            local kioskPurchaseCost = GetKioskPurchaseCost()

            self.currentBidHeaderLabel:SetText(GetString(SI_GUILD_KIOSK_MINIMUM_BID_HEADER))

            local shouldKioskPurchaseCostShowErrorColor = false
            if guildBankedMoney >= kioskPurchaseCost then
                minBidAllowed = kioskPurchaseCost
            else
                shouldKioskPurchaseCostShowErrorColor = true
                ZO_DefaultCurrencyInputField_SetCurrencyMax(self.newBidInput, 0)
            end

            --Show red on the minimum bid text when making the first bid if you don't have enough (less than the kiosk purchase cost in the guild bank)
            ZO_CurrencyControl_SetSimpleCurrency(self.currentBidLabel, CURT_MONEY, kioskPurchaseCost, CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, shouldKioskPurchaseCostShowErrorColor)
        else
            self.currentBidHeaderLabel:SetText(GetString(SI_GUILD_KIOSK_CURRENT_BID_HEADER))

            if guildBankedMoney > 0 then
                minBidAllowed = existingBidAmount + 1
            else
                shouldGuildBankGoldShowErrorColor = true
                ZO_DefaultCurrencyInputField_SetCurrencyMax(self.newBidInput, 0)
            end

            ZO_CurrencyControl_SetSimpleCurrency(self.currentBidLabel, CURT_MONEY, existingBidAmount, CURRENCY_OPTIONS)
        end
        
        self.weeklyBidsLabel:SetText(ZO_FormatFraction(numTotalBids, maxBidsPerGuild))
        --Show red on the guild bank money when updating an existing bid if you don't have enough (0 gold in the guild bank)
        ZO_CurrencyControl_SetSimpleCurrency(self.guildBalanceLabel, CURT_MONEY, guildBankedMoney, CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, shouldGuildBankGoldShowErrorColor)
        ZO_DefaultCurrencyInputField_SetCurrencyMin(self.newBidInput, minBidAllowed)
        ZO_DefaultCurrencyInputField_SetCurrencyAmount(self.newBidInput, minBidAllowed)

        self:RefreshUpdateBidEnabled(minBidAllowed)
    end
end

function BidOnKioskDialog:RefreshUpdateBidEnabled(bidAmount)
    local guildId = self.dialog:GetSelectedGuildId()
    if(guildId) then
        local _, existingBidAmount, numTotalBids = GetKioskGuildInfo(guildId)
        if(existingBidAmount) then
            local hasBidOnThisTraderAlready = existingBidAmount > 0
            if hasBidOnThisTraderAlready then
                self.acceptButton:SetEnabled(bidAmount > existingBidAmount)
            else
                if numTotalBids >= GetMaxKioskBidsPerGuild() then
                    self.acceptButton:SetEnabled(false)
                else
                    local minBid = GetKioskPurchaseCost()
                    self.acceptButton:SetEnabled(bidAmount >= minBid)
                end
            end
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