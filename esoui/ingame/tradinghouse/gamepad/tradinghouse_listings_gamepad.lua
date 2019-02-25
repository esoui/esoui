local SCROLL_LIST_ITEM_TEMPLATE_NAME = "ZO_TradingHouse_ItemListRow_Gamepad"

local ZO_GamepadTradingHouse_Listings = ZO_GamepadTradingHouse_ItemList:Subclass()

function ZO_GamepadTradingHouse_Listings:New(...)
    return ZO_GamepadTradingHouse_ItemList.New(self, ...)
end

function ZO_GamepadTradingHouse_Listings:Initialize(control)
    ZO_GamepadTradingHouse_ItemList.Initialize(self, control)

    self:ResetSortType()
end

local function SetupListing(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)

    local PRICE_VALID = false
    ZO_CurrencyControl_SetSimpleCurrency(control.price, CURT_MONEY, data.purchasePrice, ZO_GAMEPAD_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, PRICE_VALID)
end

function ZO_GamepadTradingHouse_Listings:InitializeList()
    ZO_GamepadTradingHouse_ItemList.InitializeList(self)
    local list = self.itemList
    list:AddDataTemplate(SCROLL_LIST_ITEM_TEMPLATE_NAME, SetupListing, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:SetAlignToScreenCenter(true)
    list:SetNoItemText(GetString(SI_GUILD_STORE_NO_LISTINGS))


    list:SetOnSelectedDataChangedCallback(function(list, selectedData)
        if not self.control:IsHidden() then
            self:UpdateItemSelectedTooltip(selectedData)
        end
    end)

    list:SetSortFunction(function(left, right)
        return ZO_TableOrderingFunction(left, right, self:GetCurrentSortParams())
    end)
end

function ZO_GamepadTradingHouse_Listings:UpdateForGuildChange()
    self:RefreshData()

    if not self.control:IsHidden() then
        self:RequestListUpdate()
    end
end

function ZO_GamepadTradingHouse_Listings:UpdateItemSelectedTooltip(selectedData)
    if selectedData then
        GAMEPAD_TOOLTIPS:LayoutItemWithStackCountSimple(GAMEPAD_LEFT_TOOLTIP, selectedData.itemLink, selectedData.stackCount)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

function ZO_GamepadTradingHouse_Listings:InitializeEvents()
    local function FilterForGamepadEvents(callback)
        return function(...)
            if IsInGamepadPreferredMode() then
                callback(...)
            end
        end
    end

    TRADING_HOUSE_SEARCH:RegisterCallback("OnSelectedGuildChanged", FilterForGamepadEvents(function() self:UpdateForGuildChange() end))

    local function OnResponseReceived(responseType, result)
        if result == TRADING_HOUSE_RESULT_SUCCESS then
            if responseType == TRADING_HOUSE_RESULT_LISTINGS_PENDING then
                self:ResetSortType()
                self:RefreshData()
            elseif responseType == TRADING_HOUSE_RESULT_CANCEL_SALE_PENDING then
                self:RefreshData()
            end
        end
        if self.requestListings then
            self:RequestListUpdate()
        end
    end
    TRADING_HOUSE_SEARCH:RegisterCallback("OnResponseReceived", FilterForGamepadEvents(OnResponseReceived))

    local function OnSceneGroupStateChanged(oldState, newState)
        if newState == SCENE_GROUP_SHOWING then
            self.itemList:Clear()
        end
    end
    TRADING_HOUSE_GAMEPAD_SCENE:GetSceneGroup():RegisterCallback("StateChange", OnSceneGroupStateChanged)
end

function ZO_GamepadTradingHouse_Listings:RefreshData(dontReselect)
    local itemList = self.itemList

    itemList:Clear()
    for i = 1, GetNumTradingHouseListings() do
        local itemData = ZO_TradingHouse_CreateListingItemData(i)
        if itemData then
            itemData.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, itemData.name)
            itemData.price = itemData.purchasePrice
            itemData.time = itemData.timeRemaining

            local entry = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
            entry:InitializeTradingHouseVisualData(itemData)
            entry:SetSubLabelTemplate("ZO_TradingHouse_ItemListSubLabelTemplate")

            local timeRemainingString = zo_strformat(SI_TRADING_HOUSE_BROWSE_ITEM_REMAINING_TIME, ZO_FormatTime(itemData.timeRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING))
            entry:AddSubLabel(timeRemainingString)

            itemList:AddEntry(SCROLL_LIST_ITEM_TEMPLATE_NAME, entry)
        end
    end
    itemList:Commit(dontReselect)

    self:UpdateItemSelectedTooltip(itemList:GetTargetData())
    self:UpdateKeybind()
end

function ZO_GamepadTradingHouse_Listings:ShowCancelListingConfirmation(selectedData)
    ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog(selectedData, "TRADING_HOUSE_CONFIRM_REMOVE_LISTING", selectedData.purchasePrice, selectedData.icon)
end

-- Overriden functions

local SORT_ARROW_UP = "EsoUI/Art/Miscellaneous/list_sortUp.dds"
local SORT_ARROW_DOWN = "EsoUI/Art/Miscellaneous/list_sortDown.dds"

function ZO_GamepadTradingHouse_Listings:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_TRADING_HOUSE_LISTING_REMOVE),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                local postedItem = self.itemList:GetTargetData()
                self:ShowCancelListingConfirmation(postedItem)
            end,
            visible = function()
                local postedItem = self.itemList:GetTargetData()
                return postedItem ~= nil
            end,
        },

        {
            name = GetString(SI_TRADING_HOUSE_SEARCH_FROM_ITEM),
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            keybind = "UI_SHORTCUT_QUATERNARY",

            visible = function()
                local postedItem = self.itemList:GetTargetData()
                return postedItem ~= nil
            end,

            callback = function()
                local postedItem = self.itemList:GetTargetData()
                TRADING_HOUSE_GAMEPAD:SearchForItemLink(postedItem.itemLink)
            end,
        },

        {
            name = function()
                local sortTypeText = GetString("SI_TRADINGHOUSELISTINGSORTTYPE", self.currentSortType)
                local sortIconPath = self.currentSortOrder == ZO_SORT_ORDER_UP and SORT_ARROW_UP or SORT_ARROW_DOWN
                local sortIconText = zo_iconFormat(sortIconPath, 16, 16)
                return zo_strformat(SI_GAMEPAD_TRADING_HOUSE_SORT_TIME_PRICE_TOGGLE, sortTypeText, sortIconText)
            end,
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            callback = function()
                self:CycleSortType()
            end,
            sound = SOUNDS.TRADING_HOUSE_SEARCH_INITIATED,
        },
    }

    self:AddGuildChangeKeybindDescriptor(self.keybindStripDescriptor)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.itemList)
end

function ZO_GamepadTradingHouse_Listings:ResetSortType()
    self.currentSortOrder = ZO_SORT_ORDER_DOWN
    self.currentSortType = TRADING_HOUSE_LISTING_SORT_TYPE_TIME
end

function ZO_GamepadTradingHouse_Listings:CycleSortType()
    if self.currentSortOrder == ZO_SORT_ORDER_DOWN then
        self.currentSortOrder = ZO_SORT_ORDER_UP
    else
        self.currentSortOrder = ZO_SORT_ORDER_DOWN
        if self.currentSortType == TRADING_HOUSE_LISTING_SORT_TYPE_TIME then
            self.currentSortType = TRADING_HOUSE_LISTING_SORT_TYPE_PRICE
        elseif self.currentSortType == TRADING_HOUSE_LISTING_SORT_TYPE_PRICE then
            self.currentSortType = TRADING_HOUSE_LISTING_SORT_TYPE_NAME
        elseif self.currentSortType == TRADING_HOUSE_LISTING_SORT_TYPE_NAME then
            self.currentSortType = TRADING_HOUSE_LISTING_SORT_TYPE_TIME
        end
    end

    -- Apply sort
    local DONT_RESELECT = true
    self.itemList:Commit(DONT_RESELECT)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

do
    local SORT_TYPE_TO_SORT_PRIMARY_KEY = {
        [TRADING_HOUSE_LISTING_SORT_TYPE_TIME] = "time",
        [TRADING_HOUSE_LISTING_SORT_TYPE_PRICE] = "price",
        [TRADING_HOUSE_LISTING_SORT_TYPE_NAME] = "name",
    }
    local SORT_TYPE_TO_SORT_OPTIONS = {
        [TRADING_HOUSE_LISTING_SORT_TYPE_TIME] = 
        {
            time = {tiebreaker = "name"},
            name = {tiebreaker = "price"},
            price = {},
        },
        [TRADING_HOUSE_LISTING_SORT_TYPE_PRICE] =
        {
            price = {tiebreaker = "name"},
            name = {tiebreaker = "time"},
            time = {},
        },
        [TRADING_HOUSE_LISTING_SORT_TYPE_NAME] =
        {
            name = {tiebreaker = "time"},
            time = {tiebreaker = "price"},
            price = {},
        },
    }

    function ZO_GamepadTradingHouse_Listings:GetCurrentSortParams()
        local sortKey = SORT_TYPE_TO_SORT_PRIMARY_KEY[self.currentSortType]
        local sortOptions = SORT_TYPE_TO_SORT_OPTIONS[self.currentSortType]
        local sortOrder = self.currentSortOrder
        return sortKey, sortOptions, sortOrder
    end
end

local RESELECT = false
function ZO_GamepadTradingHouse_Listings:RequestListUpdate()
    if not HasTradingHouseListings() then
        if TRADING_HOUSE_SEARCH:CanDoCommonOperation() then
            self.requestListings = false
            RequestTradingHouseListings()
        else
            -- only queue the request if we are not currently waiting for a listings response
            if not TRADING_HOUSE_SEARCH:IsWaitingForResponseType(TRADING_HOUSE_RESULT_LISTINGS_PENDING) then
                self.requestListings = true
            end
        end
    else
        self.requestListings = false
        self:RefreshData(RESELECT)
    end
end

function ZO_GamepadTradingHouse_Listings:GetTradingHouseMode()
    return ZO_TRADING_HOUSE_MODE_LISTINGS
end

function ZO_GamepadTradingHouse_Listings:OnShowing()
    self:RequestListUpdate()
end

function ZO_GamepadTradingHouse_Listings:OnHiding()
    self:UpdateItemSelectedTooltip(nil)
end

function ZO_GamepadTradingHouse_Listings:UpdateKeybind()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

-- Global functions

function ZO_TradingHouse_Listings_Gamepad_OnInitialize(control)
    GAMEPAD_TRADING_HOUSE_LISTINGS = ZO_GamepadTradingHouse_Listings:New(control)
end