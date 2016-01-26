---------------------------------
-- Trading House Create Listing
---------------------------------

local LISTING_PRICE_MODE = 1
local LISTING_FEE_MODE = 2
local LISTING_HOUSE_CUT_MODE = 3
local IS_PREVIEW = true

local LISTING_CURRENCY_ERROR_OPTIONS =
{
    showTooltips = false,
    useShortFormat = true,
    font = "ZoFontGamepadHeaderDataValue",
    iconSide = RIGHT,
    iconSize = 28,
    color = ZO_ERROR_COLOR,
    isGamepad = true,
}

ZO_GamepadTradingHouse_CreateListing = ZO_Object:Subclass()

function ZO_GamepadTradingHouse_CreateListing:New(...)
    local createListing = ZO_Object:New(self)
    createListing:Initialize(...)
    return createListing
end

function ZO_GamepadTradingHouse_CreateListing:Initialize(control)
    self.control = control
    self.isInitialized = false
    self.listingPrice = 0
    self.listingFee = 0
    self.focusMode = LISTING_PRICE_MODE

    TRADING_HOUSE_CREATE_LISTING_GAMEPAD_SCENE = ZO_InteractScene:New("gamepad_trading_house_create_listing", SCENE_MANAGER, ZO_TRADING_HOUSE_INTERACTION)
    TRADING_HOUSE_CREATE_LISTING_GAMEPAD_SCENE:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)
end

function ZO_GamepadTradingHouse_CreateListing:PerformDeferredInitialization()
    if self.isInitialized then return nil end
    
    self:InitializeHeader()
    self:InitializeKeybindStripDescriptors()
    self:InitializeControls()
    self.validPrice = true
    self.isInitialized = true
end

function ZO_GamepadTradingHouse_CreateListing:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            callback = function()
                self:FocusPriceSelector()
            end,
            visible = function() 
                return self.focusMode == LISTING_PRICE_MODE 
            end
        },

        {
            name = GetString(SI_GAMEPAD_TRADING_HOUSE_CREATE_LISTING_CONFIRM),
            keybind = "UI_SHORTCUT_SECONDARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            callback = function()
                self:ShowListItemConfirmation()
            end,
            visible = function() 
                return self.validPrice
            end
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    self.priceSelectorKeybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function() self:UnfocusPriceSelector() end),
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                return self.validPrice
            end,
            callback = function()
                self:SetListingPrice(self.priceSelector:GetValue())
                self:UnfocusPriceSelector()
            end,
        }
    }
end

function ZO_GamepadTradingHouse_CreateListing:InitializeHeader()
    self.header = self.control:GetNamedChild("HeaderContainer").header
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)

    local function GetGuildTitle(control)
		local _, guildName = GetCurrentTradingHouseGuildDetails()
		if guildName ~= "" then
			return GetString(SI_TRADING_HOUSE_GUILD_HEADER)
		else
			return nil
		end
	end

	local function GetGuildName(control)
	    local _, guildName = GetCurrentTradingHouseGuildDetails()
		if guildName ~= "" then
			return guildName
		else
			return nil
		end
	end

    local function UpdateGold(control)
        ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, GetCarriedCurrencyAmount(CURT_MONEY), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
		return true
    end

    local function GetCapacityString()
        return zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))
    end

    self.headerData = {
		data1HeaderText = GetGuildTitle,
		data1Text = GetGuildName,

        data2HeaderText = GetString(SI_GAMEPAD_GUILD_BANK_AVAILABLE_FUNDS),
        data2Text = UpdateGold,

        data3HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data3Text = GetCapacityString,

        titleText = GetString(SI_GAMEPAD_TRADING_HOUSE_CREATE_LISTING_TITLE)
    }

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_GamepadTradingHouse_CreateListing:InitializeControls()
    self.priceSelectorControl = self.control:GetNamedChild("ListingPriceSelectorContainer")
    self.priceSelector = ZO_CurrencySelector_Gamepad:New(self.priceSelectorControl:GetNamedChild("Selector"))
    self.priceSelector:SetClampValues(true)
    self.priceSelector:RegisterCallback("OnValueChanged", function() self:ValidatePriceSelectorValue(self.priceSelector:GetValue()) end)
    
    local CLAMP_VALUES = true
    self.priceSelector:SetClampValues(CLAMP_VALUES)
    self.priceSelector:SetMaxValue(MAX_PLAYER_MONEY)

    self.listingPriceControl = self.control:GetNamedChild("ListingPrice")
    self.listingPriceAmountLabel = self.listingPriceControl:GetNamedChild("AmountLabel")
    self.listingFeeControl = self.control:GetNamedChild("ListingFee")
    self.listingFeeAmountLabel = self.listingFeeControl:GetNamedChild("AmountLabel")
    self.listingHouseCutControl = self.control:GetNamedChild("HouseCut")
    self.listingHouseCutAmountLabel = self.listingHouseCutControl:GetNamedChild("AmountLabel")
    self.listingProfitControl = self.control:GetNamedChild("Profit")
    self.listingProfitAmountLabel = self.listingProfitControl:GetNamedChild("AmountLabel")   
end

function ZO_GamepadTradingHouse_CreateListing:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self:Showing()
    elseif newState == SCENE_HIDING then
        self:Hiding()
    end
end

function ZO_GamepadTradingHouse_CreateListing:Showing()
    self:PerformDeferredInitialization()
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, self.itemBag, self.itemIndex)
    self:SetListingPrice(self.listingPrice)
end

function ZO_GamepadTradingHouse_CreateListing:Hiding()
    self:UnfocusPriceSelector()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
end

function ZO_GamepadTradingHouse_CreateListing:FocusPriceSelector()
    self.priceSelector:SetValue(self.listingPrice)
    self.listingPriceControl:SetHidden(true)
    self.priceSelectorControl:SetHidden(false)
    self.priceSelector:Activate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.priceSelectorKeybindStripDescriptor)
    self.settingPrice = true
end

function ZO_GamepadTradingHouse_CreateListing:UnfocusPriceSelector()
    if self.settingPrice then
        self.priceSelectorControl:SetHidden(true)
        self.listingPriceControl:SetHidden(false)
        self.priceSelector:Deactivate()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.priceSelectorKeybindStripDescriptor)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        self:SetListingPrice(self.listingPrice)
        self.settingPrice = false
    end
end

function ZO_GamepadTradingHouse_CreateListing:ValidatePriceSelectorValue(price)
    self:SetListingPrice(price, IS_PREVIEW)
    self.priceSelector:SetTextColor(self.validPrice and ZO_SELECTED_TEXT or ZO_ERROR_COLOR)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.priceSelectorKeybindStripDescriptor)
end

function ZO_GamepadTradingHouse_CreateListing:SetControlAmountLabel(control, amount, hasError)
    ZO_CurrencyControl_SetSimpleCurrency(control, CURT_MONEY, amount, hasError and LISTING_CURRENCY_ERROR_OPTIONS or ZO_GAMEPAD_CURRENCY_OPTIONS)
end

function ZO_GamepadTradingHouse_CreateListing:SetListingPrice(price, isPreview)
    local listingFee, tradingHouseCut, profit = GetTradingHousePostPriceInfo(price)
    
    self.validPrice = (GetCarriedCurrencyAmount(CURT_MONEY) >= listingFee) and (price > 0) and (price <= MAX_PLAYER_MONEY)
    local HAS_ERROR = not self.validPrice

    self.listingFee = listingFee
    self:SetControlAmountLabel(self.listingPriceAmountLabel, price, HAS_ERROR)
    self:SetControlAmountLabel(self.listingFeeAmountLabel, listingFee, HAS_ERROR)
    self:SetControlAmountLabel(self.listingHouseCutAmountLabel, tradingHouseCut, HAS_ERROR)
    self:SetControlAmountLabel(self.listingProfitAmountLabel, profit, HAS_ERROR)
    
    if not isPreview then
        self.listingPrice = price
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GamepadTradingHouse_CreateListing:SetupListing(selectedData, bag, index, listingPrice)
    self.selectedData = selectedData
    self.itemBag = bag
    self.itemIndex = index
    self.listingPrice = listingPrice
end

function ZO_GamepadTradingHouse_CreateListing:ShowListItemConfirmation()
    SetPendingItemPost(BAG_BACKPACK, self.selectedData.slotIndex, self.selectedData.stackCount)
    ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog(self.selectedData, "TRADING_HOUSE_CONFIRM_SELL_ITEM", self.listingPrice)
end

--[[ Globals ]]--

function ZO_TradingHouse_CreateListing_Gamepad_OnInitialize(control)
    TRADING_HOUSE_CREATE_LISTING_GAMEPAD = ZO_GamepadTradingHouse_CreateListing:New(control)
end

function ZO_TradingHouse_CreateListing_Gamepad_BeginCreateListing(selectedData, bag, index, listingPrice)
    TRADING_HOUSE_CREATE_LISTING_GAMEPAD:SetupListing(selectedData, bag, index, listingPrice)
    SCENE_MANAGER:Push("gamepad_trading_house_create_listing")
end
