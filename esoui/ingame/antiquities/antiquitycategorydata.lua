ZO_AntiquityCategory = ZO_Object:Subclass()

function ZO_AntiquityCategory:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_AntiquityCategory:Initialize(antiquityCategoryId)
    self.antiquityCategoryId = antiquityCategoryId
    self.categoryOrder = GetAntiquityCategoryOrder(antiquityCategoryId)
    self.name = GetAntiquityCategoryName(antiquityCategoryId)
    self.gamepadIcon = GetAntiquityCategoryGamepadIcon(antiquityCategoryId)
    self.keyboardNormalIcon, self.keyboardPressedIcon, self.keyboardMousedOverIcon = GetAntiquityCategoryKeyboardIcons(antiquityCategoryId)
    self.antiquities = {}
    self.subcategories = {}

    -- Get Parent Antiquity Category information.
    local parentCategoryId = GetAntiquityCategoryParentId(antiquityCategoryId)
    if parentCategoryId ~= 0 then
        self.parentCategoryData = ANTIQUITY_DATA_MANAGER:GetOrCreateAntiquityCategoryData(parentCategoryId)
        self.parentCategoryData:AddSubcategoryData(self)
    end
end

function ZO_AntiquityCategory:GetId()
    return self.antiquityCategoryId
end

function ZO_AntiquityCategory:GetOrder()
    return self.categoryOrder
end

function ZO_AntiquityCategory:GetName()
    return self.name
end

function ZO_AntiquityCategory:GetKeyboardIcons()
    return self.keyboardNormalIcon, self.keyboardPressedIcon, self.keyboardMousedOverIcon
end

function ZO_AntiquityCategory:GetGamepadIcon()
    return self.gamepadIcon
end

function ZO_AntiquityCategory:GetParentCategoryData()
    return self.parentCategoryData
end

function ZO_AntiquityCategory:HasNewLead()
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

function ZO_AntiquityCategory:AddAntiquityData(antiquityData)
    table.insert(self.antiquities, antiquityData)
end

function ZO_AntiquityCategory:AntiquityIterator(filterFunctions)
    if self:GetId() == ZO_SCRYABLE_ANTIQUITY_CATEGORY_ID then
        -- Aggregate all antiquities that qualify as Scryable regardless of category.
        local function MatchAllScryableAntiquities(antiquityData)
            return antiquityData:IsInProgress() or antiquityData:IsScryable() or (antiquityData:HasDiscovered() and antiquityData:IsInCurrentPlayerZone())
        end

        local combinedFilterFunctions = {MatchAllScryableAntiquities}
        if filterFunctions then
            ZO_CombineNumericallyIndexedTables(combinedFilterFunctions, filterFunctions)
        end

        return ANTIQUITY_DATA_MANAGER:AntiquityIterator(combinedFilterFunctions)
    else
        return ZO_FilteredNumericallyIndexedTableIterator(self.antiquities, filterFunctions)
    end
end

function ZO_AntiquityCategory:AddSubcategoryData(subcategoryData)
    table.insert(self.subcategories, subcategoryData)
end

function ZO_AntiquityCategory:GetNumSubcategories()
    return #self.subcategories
end

function ZO_AntiquityCategory:GetNumAntiquities()
    return #self.antiquities
end

function ZO_AntiquityCategory:SortAntiquities()
    table.sort(self.antiquities, ZO_DefaultAntiquityOrSetSortComparison)
end

function ZO_AntiquityCategory:SortSubcategories()
    table.sort(self.subcategories, ZO_AntiquityCategory.CompareTo)
    for _, subcategory in ipairs(self.subcategories) do
        subcategory:SortAntiquities()
        subcategory:SortSubcategories()
    end
end

function ZO_AntiquityCategory:SubcategoryIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.subcategories, filterFunctions)
end

function ZO_AntiquityCategory:CompareTo(antiquityCategory)
    return self:GetOrder() < antiquityCategory:GetOrder() or (self:GetOrder() == antiquityCategory:GetOrder() and self:GetName() < antiquityCategory:GetName())
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