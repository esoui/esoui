local CraftingFilter = ZO_TradingHouseMultiFilter:Subclass()

function CraftingFilter:New(...)
    return ZO_TradingHouseMultiFilter.New(self, ...)
end

function CraftingFilter:Initialize(parentControl)
    local control = CreateControlFromVirtual("$(parent)CraftingContainer", parentControl, "TradingHouseDualComboFilter")
    ZO_TradingHouseMultiFilter.Initialize(self, control)

    local function SetItemType(_, _, entry, selectionChanged)
		TRADING_HOUSE:HandleSearchCriteriaChanged(selectionChanged)
		
        self.m_specializedItemType = entry.minValue
        self.m_usesTraits = entry.maxValue ~= nil

        local traits = TRADING_HOUSE:GetTraitFilters()
        traits:SetHidden(not self.m_usesTraits)
        traits:SetTraitType(entry.maxValue)
    end

    local function PopulateCraftingSubTypes(_, _, entry, selectionChanged)
		TRADING_HOUSE:HandleSearchCriteriaChanged(selectionChanged)

		if selectionChanged then
	        local subTypeCombo = control:GetNamedChild("SubType")
		    ZO_TradingHouse_UpdateComboBox(subTypeCombo, entry.minValue, SetItemType)
		end
    end

    ZO_TradingHouse_InitializeRangeComboBox(control:GetNamedChild("Category"), ZO_TRADING_HOUSE_FILTER_CRAFTING_SEARCHES, PopulateCraftingSubTypes)
end

function CraftingFilter:ApplyToSearch(search)
    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_SPECIALIZED_ITEM, self.m_specializedItemType)

    if(self.m_usesTraits) then
        TRADING_HOUSE:GetTraitFilters():ApplyToSearch(search)
    end
end

function CraftingFilter:SetHidden(hidden)
    ZO_TradingHouseMultiFilter.SetHidden(self, hidden)

    -- Just in case the traits filter was in use, hide it, if we're switching categories the user will need to reselect it anyway
    local traits = TRADING_HOUSE:GetTraitFilters()
    traits:SetHidden(true)

    -- But set up the anchor in either case
    if(not hidden) then
        traits:SetAnchor(TOPLEFT, self.m_control:GetNamedChild("SubType"), BOTTOMLEFT, 0, 10)
    end
end

TRADING_HOUSE:RegisterSearchFilter(CraftingFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_CRAFTING)