local GamepadGemFilter = ZO_GamepadCategoryFilter:Subclass()

function GamepadGemFilter:New()
    local gems = ZO_Object.New(self)
    gems:Initialize("Gem", ZO_TRADING_HOUSE_FILTER_GEM_TYPE_DATA, nil, ITEMTYPE_GLYPH_ARMOR)
    return gems
end

function GamepadGemFilter:Initialize(name, filterData, traitType, enchantmentType)
    ZO_GamepadCategoryFilter.Initialize(self, name, filterData, traitType, enchantmentType)
    self:SetEnchantmentType(nil) -- reset to nil to hide the enchantment filter combo box by default
end

function GamepadGemFilter:SetCategoryType(entry)
    self.categoryType = entry.minValue

    local enchantmentType = ZO_TradingHouseFilter_Shared_GetGemHasEnchantments(entry.minValue) and entry.minValue or nil

    -- Add/Change/Remove Enchantment filter as needed
    if self.enchantmentType ~= enchantmentType then
        self.lastFilterCategoryName = entry.name
        self.lastFilterCategoryIndex = self.filterCategoryComboBox and self.filterCategoryComboBox:GetHighlightedIndex() or 1
        self:SetEnchantmentType(enchantmentType)
        ZO_GamepadTradingHouse_Filter.SetComboBoxes(self, self:GetComboBoxData())
    end
end

TRADING_HOUSE_GAMEPAD:RegisterSearchFilter(GamepadGemFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_GLYPHS_AND_GEMS)