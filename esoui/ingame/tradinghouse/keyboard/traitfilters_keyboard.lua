--[[
    This filter is a little different.  Both Armor and Weapon searches use it, so instead of registering
    itself with the trading house manager, this allow other filters to obtain/instantiate the trait filter
    object as necessary using the TRADING_HOUSE global.  

    At its base, it's just another filter type that can be told to apply itself to a search

    NOTE: The parent should be something that's always shown so that when different filters use this
    they don't need to hide/show something else.
--]]

ZO_TradingHouse_TraitFilters = ZO_TradingHouseComboBoxSetter:Subclass()

function ZO_TradingHouse_TraitFilters:New(...)
    return ZO_TradingHouseComboBoxSetter.New(self, ...)
end

function ZO_TradingHouse_TraitFilters:Initialize(parentControl)
	local control = CreateControlFromVirtual("$(parent)Traits", parentControl, "TradingHouseSingleComboFilter")
    self.control = control

    local comboBox = ZO_ComboBox_ObjectFromContainer(control:GetNamedChild("Category"))
    ZO_TradingHouseComboBoxSetter.Initialize(self, TRADING_HOUSE_FILTER_TYPE_TRAIT, comboBox)
end

function ZO_TradingHouse_TraitFilters:SetTraitType(traitType)
    if(traitType) then
        ZO_TradingHouse_UpdateComboBox(self.control:GetNamedChild("Category"), ZO_TRADING_HOUSE_FILTER_TRAIT_TYPE_DATA[traitType], self.SelectionChanged)
    end
end

function ZO_TradingHouse_TraitFilters:SetAnchor(point, relativeTo, relativePoint, offsetX, offsetY)
    self.control:ClearAnchors()
    self.control:SetAnchor(point, relativeTo, relativePoint, offsetX, offsetY)
end

function ZO_TradingHouse_TraitFilters:SetHidden(hidden)
    self.control:SetHidden(hidden)
end