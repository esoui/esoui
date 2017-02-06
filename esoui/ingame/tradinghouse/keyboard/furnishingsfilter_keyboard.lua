local FurnishingsFilter = ZO_Object:Subclass()

function FurnishingsFilter:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function FurnishingsFilter:Initialize(parentControl)
    local control = CreateControlFromVirtual("$(parent)Furnishings", parentControl, "ZO_TradingHouseFurnishingsFilter_Keyboard")
    self.control = control
    self.firstTypeComboBoxControl = control:GetNamedChild("FirstType")
    self.firstTypeComboBox = ZO_ComboBox_ObjectFromContainer(self.firstTypeComboBoxControl)
    self.secondTypeComboBoxControl = control:GetNamedChild("SecondType")
    self.secondTypeComboBox = ZO_ComboBox_ObjectFromContainer(self.secondTypeComboBoxControl)
    self.itemTypeComboBoxControl = control:GetNamedChild("ItemType")
    self.itemTypeComboBox = ZO_ComboBox_ObjectFromContainer(self.itemTypeComboBoxControl)

    ZO_TradingHouse_UpdateComboBox(self.firstTypeComboBoxControl, ZO_TRADING_HOUSE_FILTER_FURNITURE_CATEGORY_TYPE_DATA["root"], function(...) self:OnFirstTypeComboBoxSelectionChanged(...) end)
    ZO_TradingHouse_UpdateComboBox(self.itemTypeComboBoxControl, ZO_TRADING_HOUSE_FILTER_FURNITURE_ITEM_TYPE_DATA, function(...) self:OnItemTypeComboBoxSelectionChanged(...) end)

    control:SetAnchor(TOPLEFT, parentControl:GetNamedChild("ItemCategory"), BOTTOMLEFT, 0, 10)
end

function FurnishingsFilter:OnFirstTypeComboBoxSelectionChanged(comboBox, entryName, entry, selectionChanged)
    TRADING_HOUSE:HandleSearchCriteriaChanged(selectionChanged)
    if selectionChanged then
        self:UpdateSecondTypeComboBoxFromFirstTypeChoice()
    end
end

function FurnishingsFilter:OnSecondTypeComboBoxSelectionChanged(comboBox, entryName, entry, selectionChanged)
    TRADING_HOUSE:HandleSearchCriteriaChanged(selectionChanged)
end

function FurnishingsFilter:OnItemTypeComboBoxSelectionChanged(comboBox, entryName, entry, selectionChanged)
    TRADING_HOUSE:HandleSearchCriteriaChanged(selectionChanged)
end

function FurnishingsFilter:UpdateSecondTypeComboBoxFromFirstTypeChoice()
    local firstTypeSelectedData = self.firstTypeComboBox:GetSelectedItemData()
    if firstTypeSelectedData then
        local secondTypeComboBoxCategoryDataKey = firstTypeSelectedData.childKey
        if secondTypeComboBoxCategoryDataKey then
            ZO_TradingHouse_UpdateComboBox(self.secondTypeComboBoxControl, ZO_TRADING_HOUSE_FILTER_FURNITURE_CATEGORY_TYPE_DATA[secondTypeComboBoxCategoryDataKey], function(...) self:OnSecondTypeComboBoxSelectionChanged(...) end)
        else
            self.secondTypeComboBoxControl:SetHidden(true)
        end
    end
end

function FurnishingsFilter:ApplyToSearch(search)
    local categoryData = self.firstTypeComboBox:GetSelectedItemData()
    local subcategoryData
    if not self.secondTypeComboBoxControl:IsHidden() then
        subcategoryData = self.secondTypeComboBox:GetSelectedItemData()
    end
    local itemTypeData = self.itemTypeComboBox:GetSelectedItemData()

    ZO_FurnishingsFilter_ApplyToSearch(search, categoryData, subcategoryData, itemTypeData)
end

function FurnishingsFilter:SetHidden(hidden)
    self.control:SetHidden(hidden)
end

function FurnishingsFilter:Reset()

end

TRADING_HOUSE:RegisterSearchFilter(FurnishingsFilter, SI_TRADING_HOUSE_BROWSE_ITEM_TYPE_FURNISHINGS)