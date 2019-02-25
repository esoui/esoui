---------------------------------
-- Trading House Sell
---------------------------------

local ZO_GamepadTradingHouse_Sell = ZO_GamepadTradingHouse_ItemList:Subclass()

function ZO_GamepadTradingHouse_Sell:New(...)
    return ZO_GamepadTradingHouse_ItemList.New(self, ...)
end

function ZO_GamepadTradingHouse_Sell:Initialize(control)
    ZO_GamepadTradingHouse_ItemList.Initialize(self, control)
end

function ZO_GamepadTradingHouse_Sell:InitializeEvents()
    ZO_GamepadTradingHouse_ItemList.InitializeEvents(self)

    local function FilterForGamepadEvents(callback)
        return function(...)
            if IsInGamepadPreferredMode() then
                callback(...)
            end
        end
    end

    TRADING_HOUSE_SEARCH:RegisterCallback("OnSelectedGuildChanged", FilterForGamepadEvents(function() self:UpdateForGuildChange() end))
end

function ZO_GamepadTradingHouse_Sell:UpdateItemSelectedTooltip(selectedData)
    if self:GetFragment():IsShowing() then
        if selectedData then
            local bag, index = ZO_Inventory_GetBagAndIndex(selectedData)
            GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, bag, index)
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        end
    end
end

function ZO_GamepadTradingHouse_Sell:SetupSelectedSellItem(selectedItem)
    local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(selectedItem)
    local initialPostPrice = ZO_TradingHouse_CalculateItemSuggestedPostPrice(bagId, slotIndex)
    ZO_TradingHouse_CreateListing_Gamepad_BeginCreateListing(selectedItem, bagId, slotIndex, initialPostPrice)
end

function ZO_GamepadTradingHouse_Sell:UpdateForGuildChange()
    if not self.control:IsHidden() then
        self:UpdateListForCurrentGuild()
    end
end

function ZO_GamepadTradingHouse_Sell:UpdateListForCurrentGuild()
    local guildId = GetSelectedTradingHouseGuildId()
    if CanSellOnTradingHouse(guildId) then
        self.itemList:SetNoItemText(GetString(SI_GAMEPAD_NO_SELL_ITEMS))
        self.itemList:SetInventoryTypes(BAG_BACKPACK)
    else
        local errorMessage
        if not IsPlayerInGuild(guildId) then
            errorMessage = GetString(SI_TRADING_HOUSE_POSTING_LOCKED_NOT_A_GUILD_MEMBER)
        elseif not DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_TRADING_HOUSE) then
            errorMessage = zo_strformat(GetString(SI_TRADING_HOUSE_POSTING_LOCKED_NO_PERMISSION_GUILD), GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_TRADING_HOUSE))
        elseif not DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_STORE_SELL) then
            errorMessage = GetString(SI_TRADING_HOUSE_POSTING_LOCKED_NO_PERMISSION_PLAYER)
        end

        self.itemList:SetNoItemText(errorMessage)
        self.itemList:ClearInventoryTypes()
    end

    self:UpdateKeybind()
end

local function SellItemSetupFunction(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)

    local PRICE_INVALID = false
    ZO_CurrencyControl_SetSimpleCurrency(control.price, CURT_MONEY, data.stackSellPrice, ZO_GAMEPAD_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, PRICE_INVALID)
end

function ZO_GamepadTradingHouse_Sell:OnSelectionChanged(list, selectedData, oldSelectedData)
    self:UpdateItemSelectedTooltip(selectedData) 
end

-- Overriden functions

function ZO_GamepadTradingHouse_Sell:InitializeList()
    local function OnSelectionChanged(...)
        self:OnSelectionChanged(...)
    end

    local USE_TRIGGERS = true
    local SORT_FUNCTION = nil
    local CATEGORIZATION_FUNCTION = nil
    local ENTRY_SETUP_CALLBACK = nil

    self.itemList = ZO_GamepadInventoryList:New(self.listControl, BAG_BACKPACK, SLOT_TYPE_ITEM, OnSelectionChanged, ENTRY_SETUP_CALLBACK, 
                                                    CATEGORIZATION_FUNCTION, SORT_FUNCTION, USE_TRIGGERS, "ZO_TradingHouse_ItemListRow_Gamepad", SellItemSetupFunction)

    self.itemList:SetItemFilterFunction(function(slot) 
        return IsItemSellableOnTradingHouse(slot.bagId, slot.slotIndex)
    end)
    local parametricList = self.itemList:GetParametricList()
    parametricList:SetAlignToScreenCenter(true)
end

function ZO_GamepadTradingHouse_Sell:OnShowing()
    self:UpdateListForCurrentGuild()
end

function ZO_GamepadTradingHouse_Sell:OnShown()
    self:UpdateKeybind()
end

function ZO_GamepadTradingHouse_Sell:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = function()
                local currentListings, maxListings = GetTradingHouseListingCounts()
                if currentListings < maxListings then
                    return zo_strformat(SI_GAMEPAD_TRADING_HOUSE_LISTING_CREATE, currentListings, maxListings)
                else
                    return zo_strformat(SI_GAMEPAD_TRADING_HOUSE_LISTING_CREATE_FULL, currentListings, maxListings)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                local selectedItem = self.itemList:GetTargetData()
                self:SetupSelectedSellItem(selectedItem)
            end,

            visible = function()
                local guildId = GetSelectedTradingHouseGuildId()
                local selectedItem = self.itemList:GetTargetData()
                return selectedItem and CanSellOnTradingHouse(guildId)
            end,

            enabled = function()
                local currentListings, maxListings = GetTradingHouseListingCounts()
                return currentListings < maxListings
            end

        },

        {
            name = GetString(SI_TRADING_HOUSE_SEARCH_FROM_ITEM),

            keybind = "UI_SHORTCUT_QUATERNARY",

            visible = function()
                return self.itemList:GetTargetData() ~= nil
            end,

            callback = function()
                local selectedItem = self.itemList:GetTargetData()
                local bag, index = ZO_Inventory_GetBagAndIndex(selectedItem)
                TRADING_HOUSE_GAMEPAD:SearchForItemLink(GetItemLink(bag, index))
            end,
        }
    }

    self:AddGuildChangeKeybindDescriptor(self.keybindStripDescriptor)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_GamepadTradingHouse_Sell:GetTradingHouseMode()
    return ZO_TRADING_HOUSE_MODE_SELL
end

function ZO_GamepadTradingHouse_Sell:OnHiding()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
end

function ZO_TradingHouse_Sell_Gamepad_OnInitialize(control)
    GAMEPAD_TRADING_HOUSE_SELL = ZO_GamepadTradingHouse_Sell:New(control)
end