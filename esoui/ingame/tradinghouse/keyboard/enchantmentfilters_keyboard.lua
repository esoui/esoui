--[[
    This filter is a little different.  Armor, Weapon and Glyph (Gem) searches use it, so instead of registering
    itself with the trading house manager, this allow other filters to obtain/instantiate the enchantment filter
    object as necessary using the TRADING_HOUSE global.

    At its base, it's just another filter type that can be told to apply itself to a search

    NOTE: The parent should be something that's always shown so that when different filters use this
    they don't need to hide/show something else.
--]]

ZO_TradingHouse_EnchantmentFilters = ZO_TradingHouseComboBoxSetter:Subclass()

function ZO_TradingHouse_EnchantmentFilters:New(...)
    return ZO_TradingHouseComboBoxSetter.New(self, ...)
end

function ZO_TradingHouse_EnchantmentFilters:Initialize(parentControl)
	local control = CreateControlFromVirtual("$(parent)Enchantments", parentControl, "TradingHouseSingleComboFilter")
    self.control = control

    local comboBox = ZO_ComboBox_ObjectFromContainer(control:GetNamedChild("Category"))
    ZO_TradingHouseComboBoxSetter.Initialize(self, TRADING_HOUSE_FILTER_TYPE_ENCHANTMENT, comboBox)
end

function ZO_TradingHouse_EnchantmentFilters:SetEnchantmentType(enchantmentType)
	local childControl = self.control:GetNamedChild("Category")
    if(enchantmentType) then
        ZO_TradingHouse_UpdateComboBox(childControl, ZO_TRADING_HOUSE_FILTER_ENCHANTMENT_TYPE_DATA[enchantmentType], self.SelectionChanged)
	else
		local comboBox = ZO_ComboBox_ObjectFromContainer(childControl)
		comboBox:ClearItems()
    end
end

function ZO_TradingHouse_EnchantmentFilters:SetAnchor(point, relativeTo, relativePoint, offsetX, offsetY)
    self.control:ClearAnchors()
    self.control:SetAnchor(point, relativeTo, relativePoint, offsetX, offsetY)
end

function ZO_TradingHouse_EnchantmentFilters:SetHidden(hidden)
    self.control:SetHidden(hidden)
end