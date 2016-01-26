local GemFilter = ZO_TradingHouseMultiFilter:Subclass()

function GemFilter:New(...)
    return ZO_TradingHouseMultiFilter.New(self, ...)
end

function GemFilter:Initialize(parentControl)
    local control = CreateControlFromVirtual("$(parent)GemContainer", parentControl, "TradingHouseSingleComboFilter")
    ZO_TradingHouseMultiFilter.Initialize(self, control)

    local function SelectGem(_, _, entry, selectionChanged)
		TRADING_HOUSE:HandleSearchCriteriaChanged(selectionChanged)

        self.m_data = entry.minValue

		local enchantmentType = nil
		if(ZO_TradingHouseFilter_Shared_GetGemHasEnchantments(entry.minValue)) then
			enchantmentType = entry.minValue
		end

	    local enchantments = TRADING_HOUSE:GetEnchantmentFilters()
		enchantments:SetHidden(enchantmentType == nil)
		enchantments:SetEnchantmentType(enchantmentType)
    end

    ZO_TradingHouse_InitializeRangeComboBox(control:GetNamedChild("Category"), ZO_TRADING_HOUSE_FILTER_GEM_TYPE_DATA, SelectGem)
end

function GemFilter:ApplyToSearch(search)
    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, self.m_data)
	TRADING_HOUSE:GetEnchantmentFilters():ApplyToSearch(search)
end

function GemFilter:SetHidden(hidden)
    ZO_TradingHouseMultiFilter.SetHidden(self, hidden)

    local enchantments = TRADING_HOUSE:GetEnchantmentFilters()
    enchantments:SetHidden(hidden)

    if(not hidden) then
        enchantments:SetAnchor(TOPLEFT, self.m_control:GetNamedChild("Category"), BOTTOMLEFT, 0, 10)
    end

	-- Select the first item to ensure that the enchantments combobox is refreshed/shown/hidden (see SelectGem() above).
	local gemComboBox = ZO_ComboBox_ObjectFromContainer(self.m_control:GetNamedChild("Category"))
	gemComboBox:SelectFirstItem()
end

TRADING_HOUSE:RegisterSearchFilter(GemFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_GLYPHS_AND_GEMS)