-------------------------
-- Guild Kiosk Purchase
-------------------------

local NUMBER_OF_KIOSK_SCENES = 2

local ZO_GuildKiosk_Purchase_Gamepad = ZO_Object:Subclass()

function ZO_GuildKiosk_Purchase_Gamepad:New(...)
    local screen = ZO_Object.New(self)
    screen:Initialize(...)
    return screen
end

function ZO_GuildKiosk_Purchase_Gamepad:Initialize(control)
    control.owner = self
    self.control = control
    self.header = control:GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.header)

    local function OnStateChanged(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_HIDDEN then
            self:OnHide()
        end
    end

    GUILD_KIOSK_PURCHASE_GAMEPAD_SCENE = ZO_InteractScene:New("guildKioskPurchaseGamepad", SCENE_MANAGER, ZO_PURCHASE_KIOSK_INTERACTION)
    GUILD_KIOSK_PURCHASE_GAMEPAD_SCENE:RegisterCallback("StateChange", OnStateChanged)
    SYSTEMS:RegisterGamepadRootScene("guildKioskPurchase", GUILD_KIOSK_PURCHASE_GAMEPAD_SCENE)

    self.control:SetHandler("OnUpdate", function(_, gameTimeSecs) self:OnUpdate(self.descriptionLabel, gameTimeSecs) end)
    self.isInitialized = false
end

function ZO_GuildKiosk_Purchase_Gamepad:OnUpdate(_, gameTimeSecs)
    if self.updateTooltip and (self.nextPurchaseUpdateS == nil or gameTimeSecs >= self.nextPurchaseUpdateS) then
        local secsRemaining = GetKioskBidWindowSecondsRemaining()
        local ownershipDuration = ZO_FormatTimeLargestTwo(secsRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE)
        
        GAMEPAD_TOOLTIPS:LayoutGuildKioskInfo(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_GUILD_KIOSK_HIRING_LABEL), zo_strformat(SI_GUILD_KIOSK_PURCHASE_DESCRIPTION, ownershipDuration))
        self.nextPurchaseUpdateS = gameTimeSecs + 1
    end
end

function ZO_GuildKiosk_Purchase_Gamepad:SetupDialogLabels(control, data)
    local data =
    {
        data1 =
        {
            value = function(control) 
                ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, self.guildBankedMoney, ZO_GAMEPAD_CURRENCY_OPTIONS)
                return true
            end,
            header = GetString(SI_GAMEPAD_GUILD_KIOSK_GUILD_BANK_BALANCE),
        },

        data2 =
        {
            value = function(control) 
                ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, self.purchaseCost, ZO_GAMEPAD_CURRENCY_OPTIONS)
                return true
            end,
            header = GetString(SI_GAMEPAD_GUILD_KIOSK_PURCHASE_COST),
        },
    }

    control.setupFunc(control, data)
end

function ZO_GuildKiosk_Purchase_Gamepad:PerformDeferredInitialize()
    if self.isInitialized then return end

    self:InitializeKeybindStripDescriptors()
    self.dropDown = ZO_ComboBox_ObjectFromContainer(self.control:GetNamedChild("ContainerDropdownDropdown"))
    self.dropDown:SetOnGuildSelectedCallback(function(guildEntry) self:OnGuildSelected(guildEntry) end)
    self.dropDown:SetOnGuildsRefreshed(function(guildEntry) self:OnGuildsRefreshed(guildEntry) end)
    self.dropDown:SetDeactivatedCallback(function() self:UnfocusDropDown() end)
    self.guildBankedMoney = 0
    self.purchaseCost = 0
    self.canAffordPurchaseCost = false
    self.hasError = false
    self.selectingGuild = false
    self.normalSelectedColor = self.dropDown.m_selectedColor

    local function UpdateGuildMoney(control)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, self.guildBankedMoney, ZO_GAMEPAD_CURRENCY_OPTIONS)
        return true
    end

    local function UpdateHireCost(control)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, self.purchaseCost, ZO_GAMEPAD_CURRENCY_OPTIONS, nil, not self.canAffordPurchaseCost)
        return true
    end

    self.headerData = 
    {
        titleText = GetString(SI_GUILD_KIOSK_PURCHASE_TITLE),
        data1HeaderText = GetString(SI_GAMEPAD_GUILD_KIOSK_GUILD_BANK_BALANCE),
	    data1Text = UpdateGuildMoney,
        data2HeaderText = GetString(SI_GAMEPAD_GUILD_KIOSK_PURCHASE_COST),
	    data2Text = UpdateHireCost,
    }

    ZO_Dialogs_RegisterCustomDialog("PURCHASE_KIOSK_GAMEPAD", 
    {
        setup = function(dialog, data) self:SetupDialogLabels(dialog, data) end,
        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_GAMEPAD_GUILD_KIOSK_DIALOG_TITLE,
        },
        mainText = 
        {
            text = function()
                return zo_strformat(SI_GAMEPAD_GUILD_KIOSK_DIALOG, ZO_SELECTED_TEXT:Colorize(self.guildName))
            end
        },
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_DECLINE
            },
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_GUILD_KIOSK_HIRE_KEYBIND,
                callback =  function()
                    GuildKioskPurchase(self.guildId)
                    PlaySound(SOUNDS.ITEM_MONEY_CHANGED)
                    SCENE_MANAGER:PopScenes(NUMBER_OF_KIOSK_SCENES)
                end
            }
        },
        noChoiceCallback = function()
            SCENE_MANAGER:PopScenes(NUMBER_OF_KIOSK_SCENES)
        end
    })

    self.isInitialized = true
end

function ZO_GuildKiosk_Purchase_Gamepad:FocusDropDown()
    if not self.selectingGuild then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        self.dropDown:Activate()
        self.dropDown:HighlightSelectedItem()
        self.selectingGuild = true
    end
end

function ZO_GuildKiosk_Purchase_Gamepad:UnfocusDropDown()
    if self.selectingGuild then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        self.selectingGuild = false
    end
end

function ZO_GuildKiosk_Purchase_Gamepad:OnGuildsRefreshed(guildEntry)
    guildEntry.guildBankedMoney = GetKioskGuildInfo(guildEntry.guildId) or 0
    guildEntry.purchaseCost = GetKioskPurchaseCost()
    guildEntry.canAffordPurchaseCost = guildEntry.guildBankedMoney >= guildEntry.purchaseCost
    guildEntry.ownedKioskName = GetGuildOwnedKioskInfo(guildEntry.guildId)
    guildEntry.guildCanUseTradingHouse = DoesGuildHavePrivilege(guildEntry.guildId, GUILD_PRIVILEGE_TRADING_HOUSE)

    if (not guildEntry.guildCanUseTradingHouse) or (guildEntry.ownedKioskName) or (not guildEntry.canAffordPurchaseCost) then
        guildEntry.hasError = true
        guildEntry.m_normalColor = ZO_ERROR_COLOR
        guildEntry.m_highlightColor = ZO_ERROR_COLOR
    else
        guildEntry.hasError = false
    end
end

function ZO_GuildKiosk_Purchase_Gamepad:OnGuildSelected(guildEntry)
    self.guildId = guildEntry.guildId
    self.guildBankedMoney = guildEntry.guildBankedMoney
    self.purchaseCost = guildEntry.purchaseCost
    self.canAffordPurchaseCost = self.guildBankedMoney >= self.purchaseCost
    self.ownedKioskName = guildEntry.ownedKioskName
    self.guildCanUseTradingHouse = guildEntry.guildCanUseTradingHouse
    self.guildName = guildEntry.name
    
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    ZO_GUILD_NAME_FOOTER_FRAGMENT:SetGuildName(self.guildName)

    if not self.guildCanUseTradingHouse then
        GAMEPAD_TOOLTIPS:LayoutGuildKioskInfo(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_GUILD_KIOSK_HIRING_LABEL), zo_strformat(SI_GUILD_KIOSK_PURCHASE_ERROR_TRADING_HOUSE_LOCKED, GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_TRADING_HOUSE)))
        self.updateTooltip = false
    elseif self.ownedKioskName then
        GAMEPAD_TOOLTIPS:LayoutGuildKioskInfo(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_GUILD_KIOSK_HIRING_LABEL), zo_strformat(SI_GUILD_KIOSK_PURCHASE_ERROR_KIOSK_RENTED, self.ownedKioskName))
        self.updateTooltip = false
    else
        self.updateTooltip = true --triggers the update loop to update this tooltip while it's showing.        
    end

    GAMEPAD_TOOLTIPS:SetTooltipResetScrollOnClear(GAMEPAD_LEFT_TOOLTIP, not self.updateTooltip)

    if guildEntry.hasError then
        self.dropDown:SetSelectedColor(ZO_ERROR_COLOR)
    else
        self.dropDown:SetSelectedColor(unpack(self.normalSelectedColor))
    end

    self.hasError = guildEntry.hasError
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildKiosk_Purchase_Gamepad:OnGuildKioskConsiderPurchaseStart()
    self:Show()
end

function ZO_GuildKiosk_Purchase_Gamepad:OnGuildKioskConsiderPurchaseStop()
    self:Hide()
end

function ZO_GuildKiosk_Purchase_Gamepad:Hide()
    SCENE_MANAGER:Hide("guildKioskPurchaseGamepad")
    self.updateTooltip = false
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
end

function ZO_GuildKiosk_Purchase_Gamepad:Show()
    self:PerformDeferredInitialize()
    SCENE_MANAGER:Show("guildKioskPurchaseGamepad")
end

function ZO_GuildKiosk_Purchase_Gamepad:OnShowing()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    GAMEPAD_TOOLTIPS:LayoutGuildKioskInfo(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_GUILD_KIOSK_HIRING_LABEL), zo_strformat(SI_GUILD_KIOSK_BID_DESCRIPTION, GetMaxKioskBidsPerGuild()))
    self.dropDown:RefreshGuildList()
end

function ZO_GuildKiosk_Purchase_Gamepad:OnHide()
    if self.selectingGuild then
        self.dropDown:Deactivate()
        self.selectingGuild = false
    end
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildKiosk_Purchase_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:FocusDropDown()
            end
        },
        {
            name = GetString(SI_GAMEPAD_GUILD_KIOSK_HIRE_KEYBIND),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback =  function()
                ZO_Dialogs_ShowGamepadDialog("PURCHASE_KIOSK_GAMEPAD")
            end,
            visible = function()
                return (not self.hasError) and self.guildName
            end
        },
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor()
    }
end

function ZO_GuildKiosk_Purchase_Gamepad:SetTitle(title)
    self.headerData.titleText = title
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_Gamepad_GuildKiosk_Purchase_OnInitialize(control)
    GUILD_KIOSK_PURCHASE_WINDOW_GAMEPAD = ZO_GuildKiosk_Purchase_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("guildKioskPurchase", GUILD_KIOSK_PURCHASE_WINDOW_GAMEPAD)
end

-------------------------
-- Guild Kiosk Bid
-------------------------

local ZO_GuildKiosk_Bid_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_GuildKiosk_Bid_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_GuildKiosk_Bid_Gamepad:Initialize(control)
    GUILD_KIOSK_BID_GAMEPAD_SCENE = ZO_InteractScene:New("guildKioskBidGamepad", SCENE_MANAGER, ZO_BID_ON_KIOSK_INTERACTION)
    SYSTEMS:RegisterGamepadRootScene("guildKioskBid", GUILD_KIOSK_BID_GAMEPAD_SCENE)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, GUILD_KIOSK_BID_GAMEPAD_SCENE)

    control:SetHandler("OnUpdate", function(_, gameTimeSecs) self:OnUpdate(gameTimeSecs) end)
    self.isInitialized = false
end

function ZO_GuildKiosk_Bid_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    self.dropDown:RefreshGuildList()
end

function ZO_GuildKiosk_Bid_Gamepad:OnHide()
    ZO_Gamepad_ParametricList_Screen.OnHide(self)
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
end

function ZO_GuildKiosk_Bid_Gamepad:SetupDialogLabels(control, data)
    local data =
    {
        data1 =
        {
            value = function(control) 
                ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, self.guildBankedMoney, ZO_GAMEPAD_CURRENCY_OPTIONS)
                return true
            end,
            header = GetString(SI_GAMEPAD_GUILD_KIOSK_GUILD_BANK_BALANCE),
        },

        data2 =
        {
            value = function(control) 
                ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, self.bidAmount, ZO_GAMEPAD_CURRENCY_OPTIONS)
                return true
            end,
            header = GetString(SI_GAMEPAD_GUILD_KIOSK_BID_AMOUNT_LABEL),
        },
    }

    control.setupFunc(control, data)

    self.shouldPopScenes = false
end

local g_nextBidUpdate = nil
function ZO_GuildKiosk_Bid_Gamepad:OnUpdate(gameTimeSecs)    
    if(g_nextBidUpdate == nil or gameTimeSecs >= g_nextBidUpdate) then
        g_nextBidUpdate = gameTimeSecs + 1
        GAMEPAD_GENERIC_FOOTER:Refresh(self.footerData)
    end
end

function ZO_GuildKiosk_Bid_Gamepad:CleanDropDown() -- make sure we don't have multiple callbacks
    if not self.dropDown then return end

    self.dropDown:SetOnGuildSelectedCallback()
    self.dropDown:SetOnGuildsRefreshed()
    self.dropDown:SetDeactivatedCallback()
    self.dropDown = nil
end

function ZO_GuildKiosk_Bid_Gamepad:ValidateBidSelectorValue(value)
    if self.hasBidOnThisTraderAlready then
        self.validBid = (value >= self.minBidAllowed) and (value <= self.guildBankedMoney + self.existingBidAmount)
    else
        self.validBid = (value >= self.minBidAllowed) and (value <= self.guildBankedMoney)
    end
    self.bidSelector:SetTextColor(self.validBid and ZO_SELECTED_TEXT or ZO_ERROR_COLOR)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.bidSelectorKeybindStripDescriptor)
end

function ZO_GuildKiosk_Bid_Gamepad:SetupList(list)
    local function SetupDropDown(control, data, selected, reselectingDuringRebuild, enabled, active)
        control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected, data.disabled))
        self:CleanDropDown()
        self.dropDown = ZO_ComboBox_ObjectFromContainer(control:GetNamedChild("Dropdown"))
        self.dropDown:SetOnGuildSelectedCallback(function(guildEntry) self:OnGuildSelected(guildEntry) end)
        self.dropDown:SetOnGuildsRefreshed(function(guildEntry) self:OnGuildsRefreshed(guildEntry) end)
        self.dropDown:SetDeactivatedCallback(function() self:UnfocusDropDown() end)
        data.OnSelection = function() self:FocusDropDown() end
    end

    list:AddDataTemplateWithHeader("ZO_GamepadGuildSelectorTemplate", SetupDropDown, nil, nil, "ZO_Gamepad_GuildKiosk_HeaderTemplate")
    
    local function SetupBidSelector(control, data, selected, reselectingDuringRebuild, enabled, active)
        self.bidAmountControl = control
        self.bidAmountControl:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected, data.disabled))
        self.bidAmountControl.header = control:GetNamedChild("Header")
        self.bidAmountLabel = self.bidAmountControl:GetNamedChild("BidAmountLabel")
        data.OnSelection = function() self:FocusBidSelector() end
    end
    
    list:AddDataTemplateWithHeader("ZO_GamepadBidSelectorTemplate", SetupBidSelector, nil, nil, "ZO_Gamepad_GuildKiosk_HeaderTemplate")
    
    self.itemList = list
end

function ZO_GuildKiosk_Bid_Gamepad:PerformDeferredInitialize()
    if self.isInitialized then return end

    self.normalSelectedColor = { GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED) }
    self.bidSelectorControl = self.control:GetNamedChild("BidSelectorContainer")
    self.bidSelector = ZO_CurrencySelector_Gamepad:New(self.bidSelectorControl:GetNamedChild("Selector"))
    self.bidSelector:SetClampValues(true)
    self.bidSelector:RegisterCallback("OnValueChanged", function() self:ValidateBidSelectorValue(self.bidSelector:GetValue()) end)
    
    local CREATE_BID_SELECTOR = true
    self:RepopulateItemList(CREATE_BID_SELECTOR)
    self.guildBankedMoney = 0
    self.minBidAllowed = 0
    self:SetBidAmount(0)
    self.canAffordMinBid = false
    self.hasError = false
    self.selectingGuild = false

    local function UpdateGuildMoney(control)
        --Show red on the guild bank money when updating an existing bid if you don't have enough (0 gold in the guild bank)
        local showErrorColor = not self.canAffordMinBid and self.hasBidOnThisTraderAlready
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, self.guildBankedMoney, ZO_GAMEPAD_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, showErrorColor)
        return true
    end

    local function UpdateMinOrCurrentBidText(control)
        return self.hasBidOnThisTraderAlready and GetString(SI_GAMEPAD_GUILD_KIOSK_CURRENT_BID) or GetString(SI_GAMEPAD_GUILD_KIOSK_MINIMUM_BID)
    end

    local function UpdateMinOrCurrentBid(control)
        --Show red on the minimum bid text when making the first bid if you don't have enough (less than the kiosk purchase cost in the guild bank)
        local showErrorColor = not self.canAffordMinBid and not self.hasBidOnThisTraderAlready
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, self.hasBidOnThisTraderAlready and self.existingBidAmount or self.minBidAllowed, ZO_GAMEPAD_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, showErrorColor)
        return true
    end

    local function UpdateBiddingCloses(control)
        local secsRemaining = GetKioskBidWindowSecondsRemaining()
        local ownershipDuration = ZO_FormatTimeLargestTwo(secsRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE_SHORT)
        local timeString = zo_strformat("<<1>>|t32:32:EsoUI/Art/Miscellaneous/timer_32.dds|t", ownershipDuration)
        return timeString
    end

    local function UpdateWeeklyBids(control)
        local maxBids = GetMaxKioskBidsPerGuild()
        control:SetText(ZO_FormatFraction(self.numTotalBids, maxBids))
        local noNewBids = not (self.existingBidAmount > 0 or self.numTotalBids < maxBids)
        if noNewBids then
            control:SetColor(ZO_ERROR_COLOR:UnpackRGBA())
        else
            control:SetColor(ZO_WHITE:UnpackRGBA())
        end
        return true
    end

    self.headerData = 
    {
        titleText = GetString(SI_GUILD_KIOSK_BID_TITLE),
        data1HeaderText = GetString(SI_GAMEPAD_GUILD_KIOSK_GUILD_BANK_BALANCE),
	    data1Text = UpdateGuildMoney,
        data2HeaderText = UpdateMinOrCurrentBidText,
	    data2Text = UpdateMinOrCurrentBid,
        data3HeaderText = GetString(SI_GAMEPAD_GUILD_KIOSK_WEEKLY_BIDS),
        data3Text = UpdateWeeklyBids,
    }

    self.footerData = {
        data1HeaderText = GetString(SI_GAMEPAD_GUILD_KIOSK_BIDDING_CLOSES),
        data1Text = UpdateBiddingCloses,
        data2HeaderText = GetString(SI_GAMEPAD_GUILD_KIOSK_TRADER_HEADER),
        data2Text = function() return GetUnitName("interact") end,
    }

    ZO_Dialogs_RegisterCustomDialog("BID_KIOSK_GAMEPAD", 
    {
        setup = function(dialog, data) self:SetupDialogLabels(dialog, data) end,
        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_GAMEPAD_GUILD_KIOSK_BID_DIALOG_TITLE,
        },
        mainText = 
        {
            text = function()
                return zo_strformat(SI_GAMEPAD_GUILD_KIOSK_BID_BODY, ZO_SELECTED_TEXT:Colorize(self.guildName))
            end
        },
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_DECLINE
            },
            {
                keybind = "DIALOG_PRIMARY",
                text = function()
                    return ZO_GuildKiosk_Bid_Shared.GetBidActionText(self.hasBidOnThisTraderAlready)
                end,
                callback =  function()
                    GuildKioskBid(self.guildId, self.bidAmount)
                    PlaySound(SOUNDS.ITEM_MONEY_CHANGED)
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, SI_GAMEPAD_GUILD_KIOSK_BID_ALERT)
                    self.shouldPopScenes = true
                end
            }
        },
        finishedCallback = function(dialog)
            if self.shouldPopScenes then
                SCENE_MANAGER:PopScenes(NUMBER_OF_KIOSK_SCENES)
            end
        end,
        noChoiceCallback = function()
            SCENE_MANAGER:PopScenes(NUMBER_OF_KIOSK_SCENES)
        end
    })

    self:InitializeKeybindStripDescriptors()
    self.isInitialized = true
end

function ZO_GuildKiosk_Bid_Gamepad:RepopulateItemList(createBidSelector)
    self.itemList:Clear()

    local data = ZO_GamepadEntryData:New("GuildSelector")
    data:SetHeader(GetString(SI_GAMEPAD_GUILD_KIOSK_GUILD_LABEL))
    self.itemList:AddEntryWithHeader("ZO_GamepadGuildSelectorTemplate", data)

    if createBidSelector then
        local data = ZO_GamepadEntryData:New("BidSelector")
        data:SetHeader(GetString(SI_GAMEPAD_GUILD_KIOSK_BID_AMOUNT_LABEL))
        self.itemList:AddEntryWithHeader("ZO_GamepadBidSelectorTemplate", data)
    end

    self.itemList:Commit()
end

function ZO_GuildKiosk_Bid_Gamepad:FocusDropDown()
    if not self.selectingGuild then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        self.dropDown:Activate()
        self.dropDown:HighlightSelectedItem()
        self.selectingGuild = true
    end
end

function ZO_GuildKiosk_Bid_Gamepad:UnfocusDropDown()
    if self.selectingGuild then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        self.selectingGuild = false
        self.itemList:Activate()
    end
end

function ZO_GuildKiosk_Bid_Gamepad:FocusBidSelector()
    self.bidSelector:SetMaxValue(self.hasBidOnThisTraderAlready and self.existingBidAmount + self.guildBankedMoney or self.guildBankedMoney)
    self.bidSelector:SetValue(self.bidAmount)
    self.bidSelectorControl:SetHidden(false)
    self.bidAmountControl:SetHidden(true)
    self.bidAmountControl.header:SetHidden(true)
    self.bidSelector:Activate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.bidSelectorKeybindStripDescriptor)
    self.settingBid = true
end

function ZO_GuildKiosk_Bid_Gamepad:UnfocusBidSelector()
    if self.settingBid then
        self.bidSelectorControl:SetHidden(true)
        self.bidAmountControl:SetHidden(false)
        self.bidAmountControl.header:SetHidden(false)
        self.bidSelector:Deactivate()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.bidSelectorKeybindStripDescriptor)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        self.settingBid = false
    end
end

local DEBUG_RESULT_TEXT =
{
    [GUILD_KIOSK_GUILD_INFO_RESULT_SUCCESS] = "Success",
    [GUILD_KIOSK_GUILD_INFO_RESULT_NO_INFO] = "No Info",
    [GUILD_KIOSK_GUILD_INFO_RESULT_NO_GUILD] = "No Guild",
    [GUILD_KIOSK_GUILD_INFO_RESULT_NO_INFO_FOR_GUILD] = "No Info For Guild",
    [GUILD_KIOSK_GUILD_INFO_RESULT_NO_INFO_FOR_ANY_GUILD] = "No Info For Any Guild",
}

function ZO_GuildKiosk_Bid_Gamepad:OnGuildsRefreshed(guildEntry)
    local guildBankedMoney, existingBidAmount, numTotalBids, result = GetKioskGuildInfo(guildEntry.guildId)
    local resultText = DEBUG_RESULT_TEXT[result]
    local interactType = GetInteractionType()
    internalassert(guildBankedMoney ~= nil, string.format("Result [%s]. InteractType [%d]. GuildId [%d]. NumGuilds [%d]", resultText, interactType, guildEntry.guildId, GetNumGuilds()))

    guildEntry.guildBankedMoney = guildBankedMoney
    guildEntry.existingBidAmount = existingBidAmount
    guildEntry.hasBidOnThisTraderAlready = existingBidAmount > 0
    guildEntry.numTotalBids = numTotalBids
    guildEntry.guildCanUseTradingHouse = DoesGuildHavePrivilege(guildEntry.guildId, GUILD_PRIVILEGE_TRADING_HOUSE)
    
    if guildEntry.hasBidOnThisTraderAlready then
        guildEntry.minBidAllowed = existingBidAmount + 1
        guildEntry.canAffordMinBid = guildEntry.guildBankedMoney > 0
    else
        guildEntry.minBidAllowed = GetKioskPurchaseCost()
        guildEntry.canAffordMinBid = guildEntry.guildBankedMoney >= guildEntry.minBidAllowed
    end

    if not guildEntry.guildCanUseTradingHouse then
        guildEntry.hasError = true
    elseif not guildEntry.hasBidOnThisTraderAlready and numTotalBids >= GetMaxKioskBidsPerGuild() then
        guildEntry.hasError = true
    elseif not guildEntry.canAffordMinBid then
        guildEntry.hasError = true
    end

    if guildEntry.hasError then
        guildEntry.m_normalColor = ZO_ERROR_COLOR
        guildEntry.m_highlightColor = ZO_ERROR_COLOR
    end
end

function ZO_GuildKiosk_Bid_Gamepad:OnGuildSelected(guildEntry)
    self.guildId = guildEntry.guildId
    self.guildBankedMoney = guildEntry.guildBankedMoney
    self.minBidAllowed = guildEntry.minBidAllowed
    self:SetBidAmount(self.minBidAllowed)
    self.canAffordMinBid = guildEntry.canAffordMinBid
    self.existingBidAmount = guildEntry.existingBidAmount
    self.hasBidOnThisTraderAlready = guildEntry.hasBidOnThisTraderAlready
    self.numTotalBids = guildEntry.numTotalBids
    self.guildCanUseTradingHouse = guildEntry.guildCanUseTradingHouse
    self.guildName = guildEntry.name

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    GAMEPAD_GENERIC_FOOTER:Refresh(self.footerData)

    if not self.guildCanUseTradingHouse then
        GAMEPAD_TOOLTIPS:LayoutGuildKioskInfo(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_GUILD_KIOSK_BIDDING_LABEL), zo_strformat(SI_GUILD_KIOSK_PURCHASE_ERROR_TRADING_HOUSE_LOCKED, GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_TRADING_HOUSE)))
    elseif not self.hasBidOnThisTraderAlready and self.numTotalBids >= GetMaxKioskBidsPerGuild() then
        GAMEPAD_TOOLTIPS:LayoutGuildKioskInfo(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_GUILD_KIOSK_BIDDING_LABEL), GetString("SI_GUILDKIOSKRESULT", GUILD_KIOSK_TOO_MANY_BIDS))
    else
        GAMEPAD_TOOLTIPS:LayoutGuildKioskInfo(GAMEPAD_LEFT_TOOLTIP, GetString(SI_GAMEPAD_GUILD_KIOSK_BIDDING_LABEL), zo_strformat(SI_GUILD_KIOSK_BID_DESCRIPTION, GetMaxKioskBidsPerGuild()))
    end

    if guildEntry.hasError then
        self.dropDown:SetSelectedColor(ZO_ERROR_COLOR)
    else
        self.dropDown:SetSelectedColor(unpack(self.normalSelectedColor))
    end

    self:SetHasError(guildEntry.hasError)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GuildKiosk_Bid_Gamepad:SetHasError(hasError)
    if self.hasError ~= hasError then
        if hasError then
            local DONT_CREATE_BID_SELECTOR = false
            self:RepopulateItemList(DONT_CREATE_BID_SELECTOR)
        else
            local CREATE_BID_SELECTOR = true
            self:RepopulateItemList(CREATE_BID_SELECTOR)
        end
        
        self.hasError = hasError
    end
end

function ZO_GuildKiosk_Bid_Gamepad:SetBidAmount(bidAmount)
    ZO_CurrencyControl_SetSimpleCurrency(self.bidAmountLabel, CURT_MONEY, bidAmount, ZO_GAMEPAD_CURRENCY_OPTIONS)
    self.bidAmount = bidAmount
end

function ZO_GuildKiosk_Bid_Gamepad:OnGuildKioskConsiderBidStart()
    self:Show()
end

function ZO_GuildKiosk_Bid_Gamepad:OnGuildKioskConsiderBidStop()
    self:Hide()
end

function ZO_GuildKiosk_Bid_Gamepad:Hide()
    SCENE_MANAGER:Hide("guildKioskBidGamepad")
end

function ZO_GuildKiosk_Bid_Gamepad:Show()
    self:PerformDeferredInitialize()
    SCENE_MANAGER:Show("guildKioskBidGamepad")
end

function ZO_GuildKiosk_Bid_Gamepad:PerformUpdate()
    self.itemList:SetSelectedIndex(1)

    if self.dropDown then
        self.dropDown:RefreshGuildList()
    end
end

function ZO_GuildKiosk_Bid_Gamepad:OnHiding()
    if self.selectingGuild then
        self.selectingGuild = false -- set selectingGuild to false first before deactivation so that the unfocusDropDown call via the deactivated callback can't cause keybinding issues
        self.dropDown:Deactivate()
    end

    self:UnfocusBidSelector()
end

function ZO_GuildKiosk_Bid_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self.itemList:GetTargetData().OnSelection()
            end,
        },
        {
            name = function()
                return ZO_GuildKiosk_Bid_Shared.GetBidActionText(self.hasBidOnThisTraderAlready)
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            callback =  function()
                ZO_Dialogs_ShowGamepadDialog("BID_KIOSK_GAMEPAD")
            end,
            visible = function()
                return (not self.hasError) and self.guildName and self.bidAmount >= self.minBidAllowed
            end
        },
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor()
    }

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.itemList)

    self.bidSelectorKeybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() self:UnfocusBidSelector() end),
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                return self.validBid
            end,
            callback = function()
                self:SetBidAmount(self.bidSelector:GetValue())
                self:UnfocusBidSelector()
            end,
        }
    }
end

function ZO_GuildKiosk_Bid_Gamepad:SetTitle(title)
    self.headerData.titleText = title
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_Gamepad_GuildKiosk_Bid_OnInitialize(control)
    GUILD_KIOSK_BID_WINDOW_GAMEPAD = ZO_GuildKiosk_Bid_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("guildKioskBid", GUILD_KIOSK_BID_WINDOW_GAMEPAD)
end
