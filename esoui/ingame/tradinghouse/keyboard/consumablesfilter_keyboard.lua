local ConsumablesFilter = ZO_TradingHouseMultiFilter:Subclass()

function ConsumablesFilter:New(...)
    return ZO_TradingHouseMultiFilter.New(self, ...)
end

function ConsumablesFilter:Initialize(parentControl)
    local control = CreateControlFromVirtual("$(parent)ConsumableTypeContainer", parentControl, "TradingHouseSingleComboFilter")
    ZO_TradingHouseMultiFilter.Initialize(self, control)

    local function SelectConsumable(_, _, entry, selectionChanged)
        TRADING_HOUSE:HandleSearchCriteriaChanged(selectionChanged)
        self.m_data = entry.minValue
    end

    ZO_TradingHouse_InitializeRangeComboBox(control:GetNamedChild("Category"), ZO_TRADING_HOUSE_FILTER_CONSUMABLES_TYPE_DATA, SelectConsumable)
end

function ConsumablesFilter:ApplyToSearch(search)
    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, self.m_data)
end

TRADING_HOUSE:RegisterSearchFilter(ConsumablesFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_CONSUMABLES)