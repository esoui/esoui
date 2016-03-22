local SCROLL_LIST_ITEM_TEMPLATE_NAME = "ZO_TradingHouse_ItemListRow_Gamepad"
local SCROLL_LIST_HEADER_OFFSET_VALUE = 0
local SCROLL_LIST_SELECTED_OFFSET_VALUE = 20

local ZO_GamepadTradingHouse_Listings = ZO_GamepadTradingHouse_SortableItemList:Subclass()

function ZO_GamepadTradingHouse_Listings:New(...)
    local browseStore = ZO_GamepadTradingHouse_SortableItemList.New(self, ...)
    return browseStore
end

function ZO_GamepadTradingHouse_Listings:Initialize(control)
    local USE_HIGHLIGHT = true
    ZO_GamepadTradingHouse_SortableItemList.Initialize(self, control, ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_TIME, USE_HIGHLIGHT)

    GAMEPAD_TRADING_HOUSE_LISTINGS_FRAGMENT = ZO_FadeSceneFragment:New(self.control)
	self:SetFragment(GAMEPAD_TRADING_HOUSE_LISTINGS_FRAGMENT)
end

local function SetupListing(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)

    local PRICE_VALID = false
    ZO_CurrencyControl_SetSimpleCurrency(control.price, CURT_MONEY, data.purchasePrice, ZO_GAMEPAD_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, PRICE_VALID)

    local sellerControl = control:GetNamedChild("SellerName")
    sellerControl:SetText(ZO_FormatUserFacingDisplayName(data.sellerName))

    local timeRemainingControl = control:GetNamedChild("TimeLeft")
    timeRemainingControl:SetText(zo_strformat(SI_TRADING_HOUSE_BROWSE_ITEM_REMAINING_TIME, ZO_FormatTime(data.timeRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)))
end

function ZO_GamepadTradingHouse_Listings:InitializeList()
    ZO_GamepadTradingHouse_SortableItemList.InitializeList(self)
    self:GetList():AddDataTemplate("ZO_TradingHouse_ItemListRow_Gamepad", SetupListing, ZO_GamepadMenuEntryTemplateParametricListFunction)
    local LISTINGS_ITEM_HEIGHT = 65
    self:GetList():SetAlignToScreenCenter(true, LISTINGS_ITEM_HEIGHT)
    self:GetList():SetNoItemText(GetString(SI_GAMEPAD_TRADING_HOUSE_NO_LISTINGS))

    self:GetList():SetOnSelectedDataChangedCallback(
        function(list, selectedData)
            self:UpdateItemSelectedTooltip(selectedData)
        end
    )
end

function ZO_GamepadTradingHouse_Listings:UpdateForGuildChange()
    self:ClearList()
    self:RefreshData()

    if not self.control:IsHidden() then
        RequestTradingHouseListings()
    end
end

function ZO_GamepadTradingHouse_Listings:UpdateItemSelectedTooltip(selectedData)
    if selectedData then
        local itemLink = GetTradingHouseListingItemLink(selectedData.slotIndex)
        GAMEPAD_TOOLTIPS:LayoutItemWithStackCountSimple(GAMEPAD_LEFT_TOOLTIP, itemLink, selectedData.stackCount)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

function ZO_GamepadTradingHouse_Listings:OnResponseReceived(responseType, result)
    if result == TRADING_HOUSE_RESULT_SUCCESS then
        if responseType == TRADING_HOUSE_RESULT_CANCEL_SALE_PENDING or responseType == TRADING_HOUSE_RESULT_LISTINGS_PENDING or responseType == TRADING_HOUSE_RESULT_POST_PENDING then
            self:RefreshData()
            if responseType == TRADING_HOUSE_RESULT_CANCEL_SALE_PENDING then
                TRADING_HOUSE_GAMEPAD:SetSearchAllowed(true)
            elseif responseType == TRADING_HOUSE_RESULT_POST_PENDING then
                ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_GAMEPAD_TRADING_HOUSE_CREATE_LISTING_ALERT))
            end
        end
    end
end

function ZO_GamepadTradingHouse_Listings:InitializeEvents()
    local function OnResponseReceived(responseType, result)
        self:OnResponseReceived(responseType, result)
    end

    self:SetEventCallback(EVENT_TRADING_HOUSE_RESPONSE_RECEIVED, OnResponseReceived)
end

function ZO_GamepadTradingHouse_Listings:BuildList()
    for i = 1, GetNumTradingHouseListings() do
	    local itemData = ZO_TradingHouse_CreateItemData(i, GetTradingHouseListingItemInfo)
        if(itemData) then
            itemData.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, itemData.name)
            itemData.price = itemData.purchasePrice
            itemData.time = itemData.timeRemaining

            local entry = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
            entry:InitializeTradingHouseVisualData(itemData)

            self:GetList():AddEntry("ZO_TradingHouse_ItemListRow_Gamepad", 
                                    entry, 
                                    SCROLL_LIST_HEADER_OFFSET_VALUE, 
                                    SCROLL_LIST_HEADER_OFFSET_VALUE, 
                                    SCROLL_LIST_SELECTED_OFFSET_VALUE, 
                                    SCROLL_LIST_SELECTED_OFFSET_VALUE)
        end
    end
end

function ZO_GamepadTradingHouse_Listings:ShowCancelListingConfirmation(selectedData)
    ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog(selectedData, "TRADING_HOUSE_CONFIRM_REMOVE_LISTING", selectedData.purchasePrice)
end

-- Overriden functions

function ZO_GamepadTradingHouse_Listings:InitializeKeybindStripDescriptors()
    local function NotAwaitingResponse() 
        return not self.awaitingResponse
    end

    self.keybindStripDescriptor = {
        {
            name = GetString(SI_GAMEPAD_SORT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            callback = function()
                self:SortBySelected()
            end,
            enabled = NotAwaitingResponse,
            sound = SOUNDS.TRADING_HOUSE_SEARCH_INITIATED,
        },

        {
            name = function()
                return GetString(SI_GAMEPAD_TRADING_HOUSE_LISTING_REMOVE)
            end,

            keybind = "UI_SHORTCUT_SECONDARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            callback = function()
                local postedItem = self:GetList():GetTargetData()
                self:ShowCancelListingConfirmation(postedItem)
            end,

            visible = function()
                local selectedItem = self:GetList():GetTargetData()
                return selectedItem ~= nil
            end,
            enabled = NotAwaitingResponse
        },

        {
            name = GetString(SI_TRADING_HOUSE_GUILD_LABEL),
            keybind = "UI_SHORTCUT_TERTIARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            callback = function()
                self:DisplayChangeGuildDialog()
            end,
            visible = function()
                return GetSelectedTradingHouseGuildId() ~= nil and GetNumTradingHouseGuilds() > 1
            end,
            enabled = NotAwaitingResponse
        },

        {
            name = function()
                return zo_strformat(SI_GAMEPAD_TRADING_HOUSE_SORT_TIME_PRICE_TOGGLE, self:GetTextForToggleTimePriceKey())
            end,
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            callback = function()
                self:ToggleSortOptions()
            end,
            enabled = NotAwaitingResponse,
            sound = SOUNDS.TRADING_HOUSE_SEARCH_INITIATED,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
	ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self:GetList())
end

local RESELECT = false
function ZO_GamepadTradingHouse_Listings:RequestListUpdate()
    if GetNumTradingHouseListings() == 0 then
        RequestTradingHouseListings()
    else
        self:RefreshData(RESELECT)
    end
end

function ZO_GamepadTradingHouse_Listings:GetFragmentGroup()
	return {GAMEPAD_TRADING_HOUSE_LISTINGS_FRAGMENT}
end

function ZO_GamepadTradingHouse_Listings:OnHiding()
    self:UpdateItemSelectedTooltip(nil)
end

function ZO_GamepadTradingHouse_Listings:OnInitialInteraction()
    self:ClearList()
    self:SelectInitialSortOption()
end

function ZO_GamepadTradingHouse_Listings:OnEndInteraction()
    self:ResetSortOptions()
end

-- Global functions

function ZO_TradingHouse_Listings_Gamepad_OnInitialize(control)
    GAMEPAD_TRADING_HOUSE_LISTINGS = ZO_GamepadTradingHouse_Listings:New(control)
end