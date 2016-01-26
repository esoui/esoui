local GamepadCraftingFilter = ZO_CategorySubtypeFilter:Subclass()

function GamepadCraftingFilter:New()
    return ZO_CategorySubtypeFilter.New(self, "Crafting", ZO_TRADING_HOUSE_FILTER_CRAFTING_SEARCHES, "armor")
end

function GamepadCraftingFilter:Initialize(name, filterData, traitType)
    ZO_CategorySubtypeFilter.Initialize(self, name, filterData, traitType)
    self:SetTraitType(nil) -- reset to nil to hide the trait filter combo box by default
end

function GamepadCraftingFilter:SetSubType(entry)
    self.categoryType = entry.minValue

    -- Add/Change/Remove Trait filter as needed
    if self.traitType ~= entry.maxValue then
        self:SetTraitType(entry.maxValue)
        ZO_GamepadTradingHouse_Filter.SetComboBoxes(self, self:GetComboBoxData())
    end
end

function GamepadCraftingFilter:SetCategoryTypeAndSubData(entry)
    self.subCategoryData = entry.minValue
end

function GamepadCraftingFilter:ApplyToSearch(search)
    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_ITEM, self.categoryType)
    ZO_GamepadTradingHouse_Filter.ApplyToSearch(self, search)
end

TRADING_HOUSE_GAMEPAD:RegisterSearchFilter(GamepadCraftingFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_CRAFTING)