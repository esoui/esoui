local ArmorFilter = ZO_Object.MultiSubclass(ZO_TradingHouseMultiFilter, ZO_ArmorFilter_Shared)

function ArmorFilter:New(...)
    return ZO_TradingHouseMultiFilter.New(self, ...)
end

function ArmorFilter:Initialize(parentControl)
    local control = CreateControlFromVirtual("$(parent)ArmorTypeContainer", parentControl, "TradingHouseDualComboFilter")
    ZO_TradingHouseMultiFilter.Initialize(self, control)

    local function SetArmorWornSlot(_, _, entry, selectionChanged)
		TRADING_HOUSE:HandleSearchCriteriaChanged(selectionChanged)
        self.m_equipType = entry.minValue
    end

    local function PopulateArmorSubTypes(_, _, entry, selectionChanged)
		TRADING_HOUSE:HandleSearchCriteriaChanged(selectionChanged)
        entry.minValue()
		if selectionChanged then
		    ZO_TradingHouse_UpdateComboBox(control:GetNamedChild("SubType"), entry.maxValue, SetArmorWornSlot)
		end
    end

    local function SetGenericArmorSearch(mode, traitType, enchantmentType, armorType)
        self.m_mode = mode
        self.m_armorType = armorType
        local traitFilters = TRADING_HOUSE:GetTraitFilters()
        local enchantmentFilters = TRADING_HOUSE:GetEnchantmentFilters()
        traitFilters:SetTraitType(traitType)
	    enchantmentFilters:SetEnchantmentType(enchantmentType)
    end

    ZO_TradingHouse_InitializeRangeComboBox(control:GetNamedChild("Category"), ZO_TradingHouseFilter_GenerateArmorTypeData(SetGenericArmorSearch), PopulateArmorSubTypes)
end

function ArmorFilter:ApplyToSearch(search)
    self:ApplyCategoryFilterToSearch(search, self.m_equipType)
    TRADING_HOUSE:GetTraitFilters():ApplyToSearch(search)
	TRADING_HOUSE:GetEnchantmentFilters():ApplyToSearch(search)
end

function ArmorFilter:SetHidden(hidden)
    ZO_TradingHouseMultiFilter.SetHidden(self, hidden)

    local traits = TRADING_HOUSE:GetTraitFilters()
    traits:SetHidden(hidden)
    traits:SetAnchor(TOPLEFT, self.m_control:GetNamedChild("SubType"), BOTTOMLEFT, 0, 10)

    local enchantments = TRADING_HOUSE:GetEnchantmentFilters()
    enchantments:SetHidden(hidden)
    enchantments:SetAnchor(TOPLEFT, traits.control:GetNamedChild("Category"), BOTTOMLEFT, 0, 10)

	-- Select the first item to ensure that the enchantments combobox is refreshed (e.g. when switching from weapons to apparel).
	local armorComboBox = ZO_ComboBox_ObjectFromContainer(self.m_control:GetNamedChild("Category"))
	armorComboBox:SelectFirstItem()
end

TRADING_HOUSE:RegisterSearchFilter(ArmorFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_APPAREL)