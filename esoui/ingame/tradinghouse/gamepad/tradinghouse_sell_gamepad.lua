---------------------------------
-- Trading House Sell
---------------------------------

local ZO_GamepadTradingHouse_Sell = ZO_GamepadTradingHouse_ItemList:Subclass()

function ZO_GamepadTradingHouse_Sell:New(...)
    local sellStore = ZO_GamepadTradingHouse_ItemList.New(self, ...)
    return sellStore
end

function ZO_GamepadTradingHouse_Sell:Initialize(control)
    ZO_GamepadTradingHouse_ItemList.Initialize(self, control)

    GAMEPAD_TRADING_HOUSE_SELL_FRAGMENT = ZO_FadeSceneFragment:New(self.control)
    self:SetFragment(GAMEPAD_TRADING_HOUSE_SELL_FRAGMENT)

    self.messageControlTextNoGuildPermission = zo_strformat(GetString(SI_GAMEPAD_TRADING_HOUSE_NO_PERMISSION_GUILD), GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_TRADING_HOUSE))
    self.messageControlTextNoPlayerPermission = GetString(SI_GAMEPAD_TRADING_HOUSE_NO_PERMISSION_PLAYER)
end

function ZO_GamepadTradingHouse_Sell:UpdateItemSelectedTooltip(selectedData)
    if selectedData then
        local bag, index = ZO_Inventory_GetBagAndIndex(selectedData)
        GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, bag, index)

        local _, _, _, _, _, equipType = GetItemInfo(bag, index)
        local equipSlot = ZO_InventoryUtils_GetEquipSlotForEquipType(equipType)

        if equipSlot and GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_RIGHT_TOOLTIP, BAG_WORN, equipSlot) then
            ZO_InventoryUtils_UpdateTooltipEquippedIndicatorText(GAMEPAD_RIGHT_TOOLTIP, equipSlot)
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        end
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_GamepadTradingHouse_Sell:SetupSelectedSellItem(selectedItem)
    local bag, index = ZO_Inventory_GetBagAndIndex(selectedItem)
    ZO_TradingHouse_CreateListing_Gamepad_BeginCreateListing(selectedItem, bag, index, selectedItem.stackSellPrice)
end

function ZO_GamepadTradingHouse_Sell:UpdateForGuildChange()
    if not self.control:IsHidden() then
        self:UpdateListForCurrentGuild()
    end
end

function ZO_GamepadTradingHouse_Sell:UpdateListForCurrentGuild()
    local guildId = GetSelectedTradingHouseGuildId()
    if CanSellOnTradingHouse(guildId) then
        self.itemList:Activate()
        self.listControl:SetHidden(false)
        self.messageControl:SetHidden(true)
    else
        self.itemList:Deactivate()
        self.listControl:SetHidden(true)
        self.messageControl:SetHidden(false)
        self.messageControl:SetText(DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_TRADING_HOUSE) and self.messageControlTextNoPlayerPermission or self.messageControlTextNoGuildPermission)
    end

    self:UpdateKeybind()
end

local function SellItemSetupFunction(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)

    local PRICE_INVALID = false
    local priceControl = control:GetNamedChild("Price")
    ZO_CurrencyControl_SetSimpleCurrency(priceControl, CURT_MONEY, data.stackSellPrice, ZO_GAMEPAD_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, PRICE_INVALID)
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

    self.messageControl = self.control:GetNamedChild("StatusMessage")
    self.itemList = ZO_GamepadInventoryList:New(self.listControl, BAG_BACKPACK, SLOT_TYPE_ITEM, OnSelectionChanged, ENTRY_SETUP_CALLBACK, 
                                                    CATEGORIZATION_FUNCTION, SORT_FUNCTION, USE_TRIGGERS, "ZO_TradingHouse_Sell_Item_Gamepad", SellItemSetupFunction)

    self.itemList:SetItemFilterFunction(function(slot) return slot.quality ~= ITEM_QUALITY_TRASH and not slot.stolen and not slot.isPlayerLocked end)
    self.itemList:GetParametricList():SetAlignToScreenCenter(true)
end

function ZO_GamepadTradingHouse_Sell:OnShowing()
    self:UpdateListForCurrentGuild()
    if self.awaitingResponse and self.itemList:IsActive() then
        -- If returning from the create listing screen the item list will still be active even though we're waiting for a response
        -- We deactivate here for correct functionality while we wait for that response
        self:DeactivateForResponse()
    end
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
                if(currentListings < maxListings) then
                    return zo_strformat(SI_GAMEPAD_TRADING_HOUSE_LISTING_CREATE, currentListings, maxListings)
                else
                    return zo_strformat(SI_GAMEPAD_TRADING_HOUSE_LISTING_CREATE_FULL, currentListings, maxListings)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

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
            name = GetString(SI_TRADING_HOUSE_GUILD_LABEL),
            keybind = "UI_SHORTCUT_TERTIARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            callback = function()
                self:DisplayChangeGuildDialog()
            end,
            visible = function()
                return GetSelectedTradingHouseGuildId() ~= nil and GetNumTradingHouseGuilds() > 1
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_GamepadTradingHouse_Sell:GetFragmentGroup()
	return {GAMEPAD_TRADING_HOUSE_SELL_FRAGMENT}
end

function ZO_GamepadTradingHouse_Sell:OnHiding()
    self:UpdateItemSelectedTooltip(nil)
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_GamepadTradingHouse_Sell:DeactivateForResponse()
    ZO_GamepadTradingHouse_BaseList.DeactivateForResponse(self)
    self.messageControl:SetHidden(true)
end

function ZO_TradingHouse_Sell_Gamepad_OnInitialize(control)
    GAMEPAD_TRADING_HOUSE_SELL = ZO_GamepadTradingHouse_Sell:New(control)
end