local DATA_CALLBACK_INDEX = 1
local EQUIP_TYPE_INDEX = 2

local GamepadArmorFilter = ZO_Object.MultiSubclass(ZO_CategorySubtypeFilter, ZO_ArmorFilter_Shared)

function GamepadArmorFilter:New()
    return ZO_CategorySubtypeFilter.New(self, "Armor", "armor", ITEMTYPE_GLYPH_ARMOR)
end

function GamepadArmorFilter:Initialize(name, traitType, enchantmentType)
    ZO_CategorySubtypeFilter.Initialize(self, name, nil, traitType, enchantmentType)
    self:GetFilterComboBoxData("Category"):SetData(ZO_TradingHouseFilter_GenerateArmorTypeData(function(...) self:SetGenericArmorSearch(...) end))
end

function GamepadArmorFilter:ApplyToSearch(search)
    self:ApplyCategoryFilterToSearch(search, self.m_FilterSubType)
    ZO_GamepadTradingHouse_Filter.ApplyToSearch(self, search)
end

function GamepadArmorFilter:PopulateSubTypes(comboBox, entryName, entry)
    local categoryComboBoxData = self:GetFilterComboBoxData("Category")
    local subTypeComboBoxData = self:GetFilterComboBoxData("SubType")
    local selectedEntryIndex = comboBox:GetHighlightedIndex()
    --Grab this from the base data that populates the category combo box. It isn't on the combo box entry
    local entryEquipTypeData = categoryComboBoxData:GetData()[selectedEntryIndex][EQUIP_TYPE_INDEX]
    
    local forceRepopulate = true    
    if not filterEquipTypeData and subTypeComboBoxData:IsVisible() then
        subTypeComboBoxData:SetVisible(false)
    elseif filterEquipTypeData and not subTypeComboBoxData:IsVisible() then
        subTypeComboBoxData:SetVisible(true)
    else
        forceRepopulate = false
    end

    if forceRepopulate then
        -- reset list to remove or add sub category combo box as needed
        local selectionChanged = categoryComboBoxData:UpdateSelectedEntryMemory(entryName, selectedEntryIndex)
        subTypeComboBoxData:ClearSelectedEntryMemory()
        self:SetCategoryTypeAndSubData(entry)
        ZO_GamepadTradingHouse_Filter.SetComboBoxes(self, self:GetComboBoxData())
        ZO_TradingHouse_SearchCriteriaChanged(selectionChanged)
    else
        ZO_CategorySubtypeFilter.PopulateSubTypes(self, comboBox, entryName, entry)
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
    local categoryComboBoxData = self:GetFilterComboBoxData("Category")
    local currentSelectedData =  categoryComboBoxData:GetSelectedEntryDataFromMemory()
    currentSelectedData[DATA_CALLBACK_INDEX]() -- Invoke callback in data container which will in turn call SetGenericArmorSearch
end

function GamepadArmorFilter:SetHidden(hidden)
    if not hidden then
        self:UpdateFilterData()
    end

    ZO_CategorySubtypeFilter.SetHidden(self, hidden)
end

TRADING_HOUSE_GAMEPAD:RegisterSearchFilter(GamepadArmorFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_APPAREL)