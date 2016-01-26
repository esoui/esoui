local DATA_CALLBACK_INDEX = 1
local SUB_TYPE_INDEX = 2

local GamepadArmorFilter = ZO_Object.MultiSubclass(ZO_CategorySubtypeFilter, ZO_ArmorFilter_Shared)

function GamepadArmorFilter:New()
    return ZO_CategorySubtypeFilter.New(self, "Armor", "armor", ITEMTYPE_GLYPH_ARMOR)
end

function GamepadArmorFilter:Initialize(name, traitType, enchantmentType)
    ZO_CategorySubtypeFilter.Initialize(self, name, nil, traitType, enchantmentType)
    self.filterData = ZO_TradingHouseFilter_GenerateArmorTypeData(function(...) self:SetGenericArmorSearch(...) end)
end

function GamepadArmorFilter:ApplyToSearch(search)
    self:ApplyCategoryFilterToSearch(search, self.m_FilterSubType)
    ZO_GamepadTradingHouse_Filter.ApplyToSearch(self, search)
end

function GamepadArmorFilter:PopulateSubTypes(comboBox, entryName, entry)
    local currentFilterCategoryIndex = comboBox:GetHighlightedIndex()
    local selectionChanged = self.lastFilterCategoryName ~= entryName
    local forceRepopulate = true
    local filterData = self.filterData[currentFilterCategoryIndex]
    local EQUIP_TYPE_INDEX = 2
    local filterEquipTypeData = filterData[EQUIP_TYPE_INDEX]

    if (not filterEquipTypeData) and self.filterComboBoxData[SUB_TYPE_INDEX].visible then
        self.filterComboBoxData[SUB_TYPE_INDEX].visible = false
    elseif filterEquipTypeData and not self.filterComboBoxData[SUB_TYPE_INDEX].visible then
        self.filterComboBoxData[SUB_TYPE_INDEX].visible = true
    else
        forceRepopulate = false
    end

    if forceRepopulate then
        -- reset list to remove or add sub category combo box as needed
        self.lastFilterCategoryName = entryName
        self.lastFilterCategoryIndex = currentFilterCategoryIndex
        self.lastFilterSubTypeName = nil
        self.lastFilterSubTypeIndex = 1
        self:SetCategoryTypeAndSubData(entry)
        ZO_GamepadTradingHouse_Filter.SetComboBoxes(self, self:GetComboBoxData())
        ZO_TradingHouse_SearchCriteriaChanged(selectionChanged)
    else
        ZO_CategorySubtypeFilter.PopulateSubTypes(self, comboBox, entryName, entry, selectionChanged)
    end

    self:UpdateFilterData()
end

function GamepadArmorFilter:SetGenericArmorSearch(mode, traitType, enchantmentType, armorType)
    self.m_mode = mode
    self:SetTraitType(traitType)
    self:SetEnchantmentType(enchantmentType)
    self.m_armorType = armorType
end

function GamepadArmorFilter:UpdateFilterData()
    local currentData = self.filterData[self.lastFilterCategoryIndex]
    currentData[DATA_CALLBACK_INDEX]() -- Invoke callback in data container which will in turn call SetGenericArmorSearch
end

function GamepadArmorFilter:SetHidden(hidden)
    if not hidden then
        self:UpdateFilterData()
    end

    ZO_CategorySubtypeFilter.SetHidden(self, hidden)
end

TRADING_HOUSE_GAMEPAD:RegisterSearchFilter(GamepadArmorFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_APPAREL)