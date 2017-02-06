local SUB_TYPE_INDEX = 2

local GamepadFurnshingsFilter = ZO_CategorySubtypeFilter:Subclass()

function GamepadFurnshingsFilter:New()
    --Does not use trait or enchantment filters
    return ZO_CategorySubtypeFilter.New(self)
end

function GamepadFurnshingsFilter:Initialize()
    ZO_CategorySubtypeFilter.Initialize(self, "Furnishings")

    --First Type Combo Box Options
    self:GetFilterComboBoxData("Category"):SetData(ZO_TRADING_HOUSE_FILTER_FURNITURE_CATEGORY_TYPE_DATA["root"])

    --Second Type Combo Box Options
    self:GetFilterComboBoxData("SubType"):SetVisible(false)

    --Item Type Combo Box Options
    local itemTypeComboBoxData = self:AddFilterComboBoxData("ItemType", function(...) self:OnItemTypeComboBoxSelectionChanged(...) end)
    itemTypeComboBoxData:SetData(ZO_TRADING_HOUSE_FILTER_FURNITURE_ITEM_TYPE_DATA)
end

function GamepadFurnshingsFilter:PopulateSubTypes(comboBox, entryName, entry)
    local categoryComboBoxData = self:GetFilterComboBoxData("Category")
    local subTypeComboBoxData = self:GetFilterComboBoxData("SubType")

	if categoryComboBoxData:UpdateSelectedEntryMemory(entryName, comboBox:GetHighlightedIndex()) then
        self.categoryEntry = entry

        local hasChildCategory = entry.childKey ~= nil and ZO_TRADING_HOUSE_FILTER_FURNITURE_CATEGORY_TYPE_DATA[entry.childKey] ~= nil
        local subCategoryData
        if hasChildCategory then
            subCategoryData = ZO_TRADING_HOUSE_FILTER_FURNITURE_CATEGORY_TYPE_DATA[entry.childKey]
        else
            subCategoryData = nil
        end
        subTypeComboBoxData:SetData(subCategoryData)

        if subTypeComboBoxData:IsVisible() ~= hasChildCategory then
            subTypeComboBoxData:SetVisible(hasChildCategory)
            ZO_GamepadTradingHouse_Filter.SetComboBoxes(self, self:GetComboBoxData())
        end
        
        subTypeComboBoxData:ReInitializeComboBox()
	end

    ZO_TradingHouse_SearchCriteriaChanged(selectionChanged)
end

function GamepadFurnshingsFilter:OnItemTypeComboBoxSelectionChanged(comboBox, entryName, entry)
    local itemTypeComboBoxData = self:GetFilterComboBoxData("ItemType")    
    if itemTypeComboBoxData:UpdateSelectedEntryMemory(entryName, comboBox:GetHighlightedIndex()) then
        self.itemTypeEntry = entry
        ZO_TradingHouse_SearchCriteriaChanged(true)
    end
end

function GamepadFurnshingsFilter:ApplyToSearch(search)
    local categoryData = self.categoryEntry
    local subcategoryData
    if self:GetFilterComboBoxData("SubType"):IsVisible() then
        --subcategoryEntry is set by the ZO_CategorySubtypeFilter handler for the subcategory combo box
        subcategoryData = self.subcategoryEntry
    end
    local itemTypeData = self.itemTypeEntry

    ZO_FurnishingsFilter_ApplyToSearch(search, categoryData, subcategoryData, itemTypeData)
end

TRADING_HOUSE_GAMEPAD:RegisterSearchFilter(GamepadFurnshingsFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_FURNISHINGS)