local MiscellaneousFilter = ZO_TradingHouseMultiFilter:Subclass()

function MiscellaneousFilter:New(...)
    return ZO_TradingHouseMultiFilter.New(self, ...)
end

function MiscellaneousFilter:Initialize(parentControl)
    local control = CreateControlFromVirtual("$(parent)MiscellaneousContainer", parentControl, "TradingHouseSingleComboFilter")
    ZO_TradingHouseMultiFilter.Initialize(self, control)

    local function SelectMatType(_, _, entry, selectionChanged)
		TRADING_HOUSE:HandleSearchCriteriaChanged(selectionChanged)
        self.m_itemType = entry.minValue
    end

    ZO_TradingHouse_InitializeRangeComboBox(control:GetNamedChild("Category"), ZO_TRADING_HOUSE_FILTER_MISC_TYPE_DATA, SelectMatType)
end

function MiscellaneousFilter:ApplyToSearch(search)
    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, self.m_itemType)
end

TRADING_HOUSE:RegisterSearchFilter(MiscellaneousFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_OTHER)