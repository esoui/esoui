local WeaponFilter = ZO_TradingHouseMultiFilter:Subclass()

function WeaponFilter:New(...)
    return ZO_TradingHouseMultiFilter.New(self, ...)
end

function WeaponFilter:Initialize(parentControl)
    local control = CreateControlFromVirtual("$(parent)WeaponTypeContainer", parentControl, "TradingHouseDualComboFilter")
    ZO_TradingHouseMultiFilter.Initialize(self, control)

    local function SetWeaponSubType(_, _, entry, selectionChanged)
		TRADING_HOUSE:HandleSearchCriteriaChanged(selectionChanged)
        self.m_weaponSubType = entry.minValue
    end

    local function PopulateSubTypes(_, _, entry, selectionChanged)
		TRADING_HOUSE:HandleSearchCriteriaChanged(selectionChanged)
        self.m_equipType = entry.minValue

		if (selectionChanged) then
	        local subTypeCombo = ZO_ComboBox_ObjectFromContainer(control:GetNamedChild("SubType"))
		    if(subTypeCombo) then
			    subTypeCombo:ClearItems()
			end

			ZO_TradingHouse_InitializeRangeComboBox(control:GetNamedChild("SubType"), entry.maxValue, SetWeaponSubType)
		end
    end

    ZO_TradingHouse_InitializeRangeComboBox(control:GetNamedChild("Category"), ZO_TRADING_HOUSE_FILTER_WEAPON_TYPE_DATA, PopulateSubTypes)
end

function WeaponFilter:ApplyToSearch(search)
    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_EQUIP, self.m_equipType)
    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_WEAPON, self.m_weaponSubType)
    TRADING_HOUSE:GetTraitFilters():ApplyToSearch(search)
    TRADING_HOUSE:GetEnchantmentFilters():ApplyToSearch(search)
end

function WeaponFilter:SetHidden(hidden)
    ZO_TradingHouseMultiFilter.SetHidden(self, hidden)

    local traits = TRADING_HOUSE:GetTraitFilters()
    traits:SetHidden(hidden)

    if(not hidden) then
        traits:SetAnchor(TOPLEFT, self.m_control:GetNamedChild("SubType"), BOTTOMLEFT, 0, 10)
        traits:SetTraitType("weapon")
    end

    local enchantments = TRADING_HOUSE:GetEnchantmentFilters()
    enchantments:SetHidden(hidden)

    if(not hidden) then
        enchantments:SetAnchor(TOPLEFT, traits.control:GetNamedChild("Category"), BOTTOMLEFT, 0, 10)
        enchantments:SetEnchantmentType(ITEMTYPE_GLYPH_WEAPON)
    end
end

TRADING_HOUSE:RegisterSearchFilter(WeaponFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_WEAPON)