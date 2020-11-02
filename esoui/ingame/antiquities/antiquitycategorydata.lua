--
-- ZO_AntiquityCategory_Base
--


ZO_AntiquityCategory_Base = ZO_Object:Subclass()

function ZO_AntiquityCategory_Base:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_AntiquityCategory_Base:Initialize(antiquityCategoryId, categoryName, categoryOrder)
    self.antiquityCategoryId = antiquityCategoryId
    self.categoryOrder = categoryOrder
    self.name = categoryName
    self.gamepadIcon = nil
    self.keyboardNormalIcon = nil
    self.keyboardPressedIcon = nil
    self.keyboardMousedOverIcon = nil
    self.subcategories = {}
end

function ZO_AntiquityCategory_Base:GetId()
    return self.antiquityCategoryId
end

function ZO_AntiquityCategory_Base:GetOrder()
    return self.categoryOrder
end

function ZO_AntiquityCategory_Base:GetName()
    return self.name
end

function ZO_AntiquityCategory_Base:SetKeyboardIcons(normalIcon, pressedIcon, mouseOverIcon)
    self.keyboardNormalIcon = normalIcon
    self.keyboardPressedIcon = pressedIcon
    self.keyboardMousedOverIcon = mouseOverIcon
end

function ZO_AntiquityCategory_Base:GetKeyboardIcons()
    return self.keyboardNormalIcon, self.keyboardPressedIcon, self.keyboardMousedOverIcon
end

function ZO_AntiquityCategory_Base:SetGamepadIcon(icon)
    self.gamepadIcon = icon
end

function ZO_AntiquityCategory_Base:GetGamepadIcon()
    return self.gamepadIcon
end

function ZO_AntiquityCategory_Base:SetParentCategoryData(parentCategoryData)
    self.parentCategoryData = parentCategoryData
end

function ZO_AntiquityCategory_Base:GetParentCategoryData()
    return self.parentCategoryData
end

function ZO_AntiquityCategory_Base:HasNewLead()
    for index, antiquityData in self:AntiquityIterator() do
        if antiquityData:HasNewLead() then
            return true
        end
    end
    for index, subcategoryData in self:SubcategoryIterator() do
        if subcategoryData:HasNewLead() then
            return true
        end
    end
    return false
end

function ZO_AntiquityCategory_Base:AntiquityIterator(filterFunctions)
    assert(false) -- Must be overridden
end

function ZO_AntiquityCategory_Base:AddSubcategoryData(subcategoryData)
    table.insert(self.subcategories, subcategoryData)
    subcategoryData:SetParentCategoryData(self)
end

function ZO_AntiquityCategory_Base:GetNumSubcategories()
    return #self.subcategories
end

function ZO_AntiquityCategory_Base:SortSubcategories()
    table.sort(self.subcategories, ZO_AntiquityCategory_Base.CompareTo)
    for _, subcategory in ipairs(self.subcategories) do
        subcategory:SortSubcategories()
    end
end

function ZO_AntiquityCategory_Base:SubcategoryIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.subcategories, filterFunctions)
end

function ZO_AntiquityCategory_Base:CompareTo(antiquityCategory)
    return self:GetOrder() < antiquityCategory:GetOrder() or (self:GetOrder() == antiquityCategory:GetOrder() and self:GetName() < antiquityCategory:GetName())
end

--
-- ZO_AntiquityCategory
--

ZO_AntiquityCategory = ZO_AntiquityCategory_Base:Subclass()

function ZO_AntiquityCategory:New(...)
    return ZO_AntiquityCategory_Base.New(self, ...)
end

function ZO_AntiquityCategory:Initialize(antiquityCategoryId)
    local name = GetAntiquityCategoryName(antiquityCategoryId)
    local categoryOrder = GetAntiquityCategoryOrder(antiquityCategoryId)
    ZO_AntiquityCategory_Base.Initialize(self, antiquityCategoryId, name, categoryOrder)

    self:SetGamepadIcon(GetAntiquityCategoryGamepadIcon(antiquityCategoryId))

    local keyboardNormalIcon, keyboardPressedIcon, keyboardMousedOverIcon = GetAntiquityCategoryKeyboardIcons(antiquityCategoryId)
    self:SetKeyboardIcons(keyboardNormalIcon, keyboardPressedIcon, keyboardMousedOverIcon)

    self.antiquities = {}

    -- Get Parent Antiquity Category information.
    local parentCategoryId = GetAntiquityCategoryParentId(antiquityCategoryId)
    if parentCategoryId ~= 0 then
        local parentCategoryData = ANTIQUITY_DATA_MANAGER:GetOrCreateAntiquityCategoryData(parentCategoryId)
        parentCategoryData:AddSubcategoryData(self)
    end
end

function ZO_AntiquityCategory:AddAntiquityData(antiquityData)
    table.insert(self.antiquities, antiquityData)
end

function ZO_AntiquityCategory:AntiquityIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.antiquities, filterFunctions)
end

function ZO_AntiquityCategory:GetNumAntiquities()
    return #self.antiquities
end

function ZO_AntiquityCategory:SortAntiquities()
    table.sort(self.antiquities, ZO_DefaultAntiquityOrSetSortComparison)
end

-- override of ZO_AntiquityCategory_Base:SortSubcategories()
function ZO_AntiquityCategory:SortSubcategories()
    table.sort(self.subcategories, ZO_AntiquityCategory.CompareTo)
    for _, subcategory in ipairs(self.subcategories) do
        subcategory:SortAntiquities()
        subcategory:SortSubcategories()
    end
end

--
-- ZO_AntiquityFilterCategory
--

ZO_AntiquityFilterCategory = ZO_AntiquityCategory_Base:Subclass()

function ZO_AntiquityFilterCategory:New(...)
    return ZO_AntiquityCategory_Base.New(self, ...)
end

function ZO_AntiquityFilterCategory:Initialize(...)
    ZO_AntiquityCategory_Base.Initialize(self, ...)

    self.antiquityFilterFunction = nil
end

function ZO_AntiquityFilterCategory:SetAntiquityFilterFunction(filterFunction)
    self.antiquityFilterFunction = filterFunction
end

function ZO_AntiquityFilterCategory:AntiquityIterator(filterFunctions)
    local combinedFilterFunctions = {self.antiquityFilterFunction}
    if filterFunctions then
        ZO_CombineNumericallyIndexedTables(combinedFilterFunctions, filterFunctions)
    end

    return ANTIQUITY_DATA_MANAGER:AntiquityIterator(combinedFilterFunctions)
end

-- Global Functions

-- Sort by Discovered, Quality (ascending) and Antiquity Name (ascending).
function ZO_DefaultAntiquitySortComparison(leftAntiquityData, rightAntiquityData)
    if leftAntiquityData:HasDiscovered() ~= rightAntiquityData:HasDiscovered() then
        return leftAntiquityData:HasDiscovered()
    elseif leftAntiquityData:GetQuality() < rightAntiquityData:GetQuality() then
        return true
    elseif leftAntiquityData:GetQuality() == rightAntiquityData:GetQuality() then
        return ZO_Antiquity.CompareNameTo(leftAntiquityData, rightAntiquityData)
    end

    return false
end

-- Sort by Discovered, Quality (ascending) and Set or Antiquity Name (ascending).
function ZO_DefaultAntiquityOrSetSortComparison(leftAntiquityOrSetData, rightAntiquityOrSetData)
    local leftData = leftAntiquityOrSetData:GetAntiquitySetData() or leftAntiquityOrSetData
    local rightData = rightAntiquityOrSetData:GetAntiquitySetData() or rightAntiquityOrSetData

    if leftData:HasDiscovered() ~= rightData:HasDiscovered() then
        return leftData:HasDiscovered()
    elseif leftData:GetQuality() < rightData:GetQuality() then
        return true
    elseif leftData:GetQuality() == rightData:GetQuality() then
        return ZO_Antiquity.CompareSetAndNameTo(leftAntiquityOrSetData, rightAntiquityOrSetData)
    end

    return false
end