-- Piece --

ZO_ItemSetCollectionPieceData = ZO_InitializingObject:Subclass()

function ZO_ItemSetCollectionPieceData:Initialize(pieceId, itemSetCollectionSlot)
    self.pieceId = pieceId
    self.itemSetCollectionSlot = itemSetCollectionSlot
    self:RefreshItemLink() -- Update it the first time immediately during the load screen
end

function ZO_ItemSetCollectionPieceData:GetId()
    return self.pieceId
end

function ZO_ItemSetCollectionPieceData:GetItemSetCollectionSlot()
    return self.itemSetCollectionSlot
end

function ZO_ItemSetCollectionPieceData:GetSetId()
    return self.itemSetCollectionData:GetId()
end

function ZO_ItemSetCollectionPieceData:SetItemSetCollectionData(itemSetCollectionData)
    self.itemSetCollectionData = itemSetCollectionData
end

function ZO_ItemSetCollectionPieceData:GetItemSetCollectionData()
    return self.itemSetCollectionData
end

function ZO_ItemSetCollectionPieceData:MarkItemLinkDirty()
    self.isItemLinkDirty = true
end

function ZO_ItemSetCollectionPieceData:InternalCreateItemLink()
    return GetItemSetCollectionPieceItemLink(self.pieceId, LINK_STYLE_DEFAULT, ITEM_TRAIT_TYPE_NONE)
end

function ZO_ItemSetCollectionPieceData:RefreshItemLink()
    -- As these are often accessed from entry instance data, make sure that the refreshed info actually gets applied to the source data and not the entry instance data
    -- In order to keep this hefty system more lightweight, let the garbage collector clean up isItemLinkDirty. It shouldn't dirty often, so no reason to keep the memory around
    local itemLink = self:InternalCreateItemLink()
    if self.dataSource then
        self.dataSource.itemLink = itemLink
        self.dataSource.isItemLinkDirty = nil
    else
        self.itemLink = itemLink
        self.isItemLinkDirty = nil
    end
end

function ZO_ItemSetCollectionPieceData:GetItemLink()
    if self.isItemLinkDirty then
        self:RefreshItemLink()
    end
    return self.itemLink
end

function ZO_ItemSetCollectionPieceData:GetRawName()
    return GetItemLinkName(self:GetItemLink())
end

function ZO_ItemSetCollectionPieceData:GetRawColorizedName()
    local colorDef = GetItemQualityColor(self:GetDisplayQuality())
    return colorDef:Colorize(self:GetName())
end

function ZO_ItemSetCollectionPieceData:GetFormattedName()
    return zo_strformat(SI_LINK_FORMAT_ITEM_NAME, self:GetRawName())
end

function ZO_ItemSetCollectionPieceData:GetFormattedColorizedName()
    local colorDef = GetItemQualityColor(self:GetDisplayQuality())
    return colorDef:Colorize(self:GetFormattedName())
end

function ZO_ItemSetCollectionPieceData:GetFunctionalQuality()
    return GetItemLinkFunctionalQuality(self:GetItemLink())
end

function ZO_ItemSetCollectionPieceData:GetDisplayQuality()
    return GetItemLinkDisplayQuality(self:GetItemLink())
end

function ZO_ItemSetCollectionPieceData:GetArmorType()
    return GetItemLinkArmorType(self:GetItemLink())
end

function ZO_ItemSetCollectionPieceData:GetEquipmentFilterType()
    return GetEquipmentFilterTypeForItemSetCollectionSlot(self:GetItemSetCollectionSlot())
end

function ZO_ItemSetCollectionPieceData:MatchesEquipmentFilterTypes(equipmentFilterTypes)
    return ZO_IsElementInNumericallyIndexedTable(equipmentFilterTypes, self:GetEquipmentFilterType())
end

function ZO_ItemSetCollectionPieceData:GetIcon()
    return GetItemLinkIcon(self:GetItemLink())
end

function ZO_ItemSetCollectionPieceData:GetTraitType()
    return GetItemLinkTraitType(self:GetItemLink())
end

function ZO_ItemSetCollectionPieceData:GetTraitCategory()
    return GetItemLinkTraitCategory(self:GetItemLink())
end

function ZO_ItemSetCollectionPieceData:GetTradeskillType()
    return GetItemLinkCraftingSkillType(self:GetItemLink())
end

function ZO_ItemSetCollectionPieceData:IsUnlocked()
    -- There's a piece id function, but using the slot, if it's already known, is more effecient
    return IsItemSetCollectionSlotUnlocked(self:GetSetId(), self:GetItemSetCollectionSlot())
end

function ZO_ItemSetCollectionPieceData:IsLocked()
    return not self:IsUnlocked()
end

function ZO_ItemSetCollectionPieceData:IsNew()
    return IsItemSetCollectionSlotNew(self:GetSetId(), self:GetItemSetCollectionSlot())
end

function ZO_ItemSetCollectionPieceData:ClearNew(dontBroadcast)
    ClearItemSetCollectionSlotNew(self:GetSetId(), self:GetItemSetCollectionSlot(), not dontBroadcast)
end

function ZO_ItemSetCollectionPieceData:IsSearchResult()
    -- Text search filters on sets, not individual pieces
    return self.itemSetCollectionData:IsSearchResult()
end

-- Reconstruction Piece --

ZO_ItemSetCollectionReconstructionPieceData = ZO_ItemSetCollectionPieceData:Subclass()

function ZO_ItemSetCollectionReconstructionPieceData:Initialize()
    -- Info will be set post initialize
end

function ZO_ItemSetCollectionReconstructionPieceData:Copy(itemSetCollectionPieceData)
    self.pieceId = itemSetCollectionPieceData:GetId()
    self.itemSetCollectionSlot = itemSetCollectionPieceData:GetItemSetCollectionSlot()
    self.itemSetCollectionData = itemSetCollectionPieceData:GetItemSetCollectionData()
    self:MarkItemLinkDirty()
    self.overrideTraitType = ITEM_TRAIT_TYPE_NONE
    self.upgradeFunctionalQuality = nil
end

function ZO_ItemSetCollectionReconstructionPieceData:GetOverrideTraitType()
    return self.overrideTraitType
end

function ZO_ItemSetCollectionReconstructionPieceData:SetOverrideTraitType(overrideTraitType)
    if self.overrideTraitType ~= overrideTraitType then
        self.overrideTraitType = overrideTraitType
        self:MarkItemLinkDirty()
    end
end

function ZO_ItemSetCollectionReconstructionPieceData:GetMinimumFunctionalQuality()
    return GetItemLinkFunctionalQuality(GetItemSetCollectionPieceItemLink(self.pieceId, LINK_STYLE_DEFAULT, ITEM_TRAIT_TYPE_NONE))
end

function ZO_ItemSetCollectionReconstructionPieceData:GetUpgradeFunctionalQuality()
    return self.upgradeFunctionalQuality or self:GetFunctionalQuality()
end

function ZO_ItemSetCollectionReconstructionPieceData:SetUpgradeFunctionalQuality(upgradeFunctionalQuality)
    if self.upgradeFunctionalQuality ~= upgradeFunctionalQuality then
        self.upgradeFunctionalQuality = upgradeFunctionalQuality
        self:MarkItemLinkDirty()
    end
end

function ZO_ItemSetCollectionReconstructionPieceData:InternalCreateItemLink()
    return GetItemSetCollectionPieceItemLink(self.pieceId, LINK_STYLE_DEFAULT, self.overrideTraitType, self.upgradeFunctionalQuality)
end

function ZO_ItemSetCollectionReconstructionPieceData:GetCostInfo(overrideFunctionalQuality)
    local itemSetCollectionData = self:GetItemSetCollectionData()
    local currencyOptionTypes = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetReconstructionCurrencyOptionTypes()
    local currencyOptions = {}
    for _, currencyType in ipairs(currencyOptionTypes) do
        local currencyCost = itemSetCollectionData:GetReconstructionCurrencyOptionCost(currencyType)
        local currencyLocation = GetCurrencyPlayerStoredLocation(currencyType)
        table.insert(currencyOptions,
        {
            currencyAvailable = GetCurrencyAmount(currencyType, currencyLocation),
            currencyIcon = ZO_Currency_GetPlatformCurrencyIcon(currencyType),
            currencyLocation = currencyLocation,
            currencyName = GetCurrencyName(currencyType),
            currencyRequired = currencyCost,
            currencyType = currencyType,
        })
    end

    local tradeskillType = self:GetTradeskillType()
    local minimumQuality = self:GetMinimumFunctionalQuality()
    -- Calculate the costs from the default quality through the requested upgrade quality.
    local upgradeQuality = overrideFunctionalQuality or (self:GetUpgradeFunctionalQuality() - 1)
    local materialCosts = {}
    for quality = minimumQuality, upgradeQuality do
        local reagentItemLink = GetSmithingImprovementItemLink(tradeskillType, quality)
        local _, reagentIcon, reagentsAvailable = GetSmithingImprovementItemInfo(tradeskillType, quality)
        local reagentsRequired = GetSmithingGuaranteedImprovementItemAmount(tradeskillType, quality)
        local materialCost =
        {
            fromFunctionalQuality = quality,
            toFunctionalQuality = quality + 1,
            reagentIcon = reagentIcon,
            reagentItemLink = reagentItemLink,
            reagentsRequired = reagentsRequired,
            reagentsAvailable = reagentsAvailable,
        }
        table.insert(materialCosts, materialCost)
    end

    return currencyOptions, materialCosts
end

-- Collection --

ZO_ItemSetCollectionData = ZO_InitializingObject:Subclass()

function ZO_ItemSetCollectionData:Initialize(itemSetId)
    self.itemSetId = itemSetId
    self.pieces = {}

    -- Get Item Set Collection Category information
    local itemSetCollectionCategoryId = GetItemSetCollectionCategoryId(itemSetId)
    if itemSetCollectionCategoryId ~= 0 then
        local itemSetCollectionCategoryData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetOrCreateItemSetCollectionCategoryData(itemSetCollectionCategoryId)
        self.itemSetCollectionCategoryData = itemSetCollectionCategoryData
        itemSetCollectionCategoryData:AddItemSetCollectionData(self)
    end

    for i = 1, GetNumItemSetCollectionPieces(itemSetId) do
        local pieceId, slot = GetItemSetCollectionPieceInfo(itemSetId, i)
        local itemSetCollectionPieceData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetOrCreateItemSetCollectionPieceData(pieceId, slot)
        if internalassert(itemSetCollectionPieceData ~= nil) then
            table.insert(self.pieces, itemSetCollectionPieceData)
            itemSetCollectionPieceData:SetItemSetCollectionData(self)
        end
    end
end

function ZO_ItemSetCollectionData:GetId()
    return self.itemSetId
end

function ZO_ItemSetCollectionData:GetRawName()
    return GetItemSetName(self.itemSetId)
end

function ZO_ItemSetCollectionData:GetFormattedName()
    return zo_strformat(SI_ITEM_SET_NAME_FORMATTER, self:GetRawName())
end

function ZO_ItemSetCollectionData:GetSetType()
    return GetItemSetType(self.itemSetId)
end

function ZO_ItemSetCollectionData:GetUnperfectedSetId()
    return GetItemSetUnperfectedSetId(self.itemSetId)
end

function ZO_ItemSetCollectionData:GetUnperfectedSetCollectionData()
    return ITEM_SET_COLLECTIONS_DATA_MANAGER:GetItemSetCollectionData(self:GetUnperfectedSetId())
end

function ZO_ItemSetCollectionData:GetNumPieces()
    return #self.pieces
end

function ZO_ItemSetCollectionData:GetNumUnlockedPieces()
    return GetNumItemSetCollectionSlotsUnlocked(self.itemSetId)
end

function ZO_ItemSetCollectionData:HasAnyUnlockedPieces()
    return self:GetNumUnlockedPieces() > 0
end

function ZO_ItemSetCollectionData:HasAnyNewPieces()
    return ItemSetCollectionHasNewPieces(self.itemSetId)
end

function ZO_ItemSetCollectionData:ClearNew(dontBroadcast)
    local DONT_BROADCAST = true
    for _, itemSetCollectionPieceData in self:PieceIterator() do
        itemSetCollectionPieceData:ClearNew(DONT_BROADCAST)
    end

    if not dontBroadcast then
        ITEM_SET_COLLECTIONS_DATA_MANAGER:OnCollectionNewStatusCleared(self)
    end
end

function ZO_ItemSetCollectionData:GetReconstructionCurrencyOptionCost(currencyType)
    return GetItemReconstructionCurrencyOptionCost(self.itemSetId, currencyType)
end

function ZO_ItemSetCollectionData:GetReconstructionCurrencyOptionInfo(currencyOptionIndex)
    local currencyType = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetReconstructionCurrencyOptionType(currencyOptionIndex)
    return currencyType, self:GetReconstructionCurrencyOptionCost(currencyType)
end

function ZO_ItemSetCollectionData:GetCategoryData()
    return self.itemSetCollectionCategoryData
end

function ZO_ItemSetCollectionData:GetPieceDataBySlot(itemSetCollectionSlot)
    for i, itemSetCollectionPieceData in self:PieceIterator() do
        if CompareId64s(itemSetCollectionPieceData:GetItemSetCollectionSlot(), itemSetCollectionSlot) == 0 then
            return itemSetCollectionPieceData
        end
    end
    return nil
end

function ZO_ItemSetCollectionData:SetSearchResultsVersion(searchResultsVersion)
    self.searchResultsVersion = searchResultsVersion
    self.itemSetCollectionCategoryData:SetSearchResultsVersion(searchResultsVersion)
end

function ZO_ItemSetCollectionData:IsSearchResult()
    if self.searchResultsVersion then
        if self.searchResultsVersion == ITEM_SET_COLLECTIONS_DATA_MANAGER:GetSearchResultsVersion() then
            return true
        else
            -- Old search result, might as well clean it up while we're here
            self.searchResultsVersion = nil
        end
    end
    return false
end

do
    -- if this triggers, need to add set type to this arbitrary sort order
    internalassert(ITEM_SET_TYPE_MAX_VALUE == 5)

    local SET_TYPE_SORT_ORDER =
    {
        [ITEM_SET_TYPE_MONSTER] = 1,
        [ITEM_SET_TYPE_WEAPON] = 2,
        [ITEM_SET_TYPE_DUNGEON] = 3,
        [ITEM_SET_TYPE_WORLD] = 4,
        [ITEM_SET_TYPE_CRAFTED] = 99, -- Technically invalid for item set collections
        [ITEM_SET_TYPE_NONE] = 99, -- Technically invalid for item set collections
    }

    function ZO_ItemSetCollectionData:CompareTo(otherItemSetCollectionData)
        if self:GetId() == otherItemSetCollectionData:GetId() then
            -- table.sort compares an entry to itself, no good answer, just always return false
            return false
        end

        local setTypeSortOrder = SET_TYPE_SORT_ORDER[self:GetSetType()]
        local otherSetTypeSortOrder = SET_TYPE_SORT_ORDER[otherItemSetCollectionData:GetSetType()]
        if setTypeSortOrder ~= otherSetTypeSortOrder then
            return setTypeSortOrder < otherSetTypeSortOrder
        end

        -- Check for perfected versions of sets and group them after their unperfected counterpart
        local unperfectedSetCollectionData = self:GetUnperfectedSetCollectionData()
        local otherUnperfectedSetCollectionData = otherItemSetCollectionData:GetUnperfectedSetCollectionData()

        local isSetPerfected = unperfectedSetCollectionData ~= nil
        local isOtherSetPerfected = otherUnperfectedSetCollectionData ~= nil

        local sortName = isSetPerfected and unperfectedSetCollectionData:GetRawName() or self:GetRawName()
        local otherSortName = isOtherSetPerfected and otherUnperfectedSetCollectionData:GetRawName() or otherItemSetCollectionData:GetRawName()

        if sortName == otherSortName then
            -- Names in theory should only match if one is the perfected version of the other, or when table.sort compares an entry to itself
            if isSetPerfected ~= isOtherSetPerfected then
                -- Unperfected comes first
                return isOtherSetPerfected
            else
                return self:GetId() < otherItemSetCollectionData:GetId()
            end
        else
            return sortName < otherSortName
        end
    end
end

function ZO_ItemSetCollectionData:PieceIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.pieces, filterFunctions)
end

function ZO_ItemSetCollectionData:AnyChildPassesFilters(pieceFilterFunctions)
    for _, pieceData in self:PieceIterator(pieceFilterFunctions) do
        return true
    end
    return false
end

-- Category --

ZO_ItemSetCollectionCategoryData = ZO_InitializingObject:Subclass()

function ZO_ItemSetCollectionCategoryData:Initialize(categoryId)
    self.categoryId = categoryId
    self.collections = {}
    self.subcategories = {}

    -- Get parent category information
    local parentCategoryId = GetItemSetCollectionCategoryParentId(categoryId)
    if parentCategoryId ~= 0 then
        self.parentCategoryData = ITEM_SET_COLLECTIONS_DATA_MANAGER:GetOrCreateItemSetCollectionCategoryData(parentCategoryId)
        self.parentCategoryData:AddSubcategoryData(self)
    end
end

function ZO_ItemSetCollectionCategoryData:AddSubcategoryData(subcategoryData)
    table.insert(self.subcategories, subcategoryData)
end

function ZO_ItemSetCollectionCategoryData:AddItemSetCollectionData(itemSetCollectionData)
    table.insert(self.collections, itemSetCollectionData)
end

function ZO_ItemSetCollectionCategoryData:GetId()
    return self.categoryId
end

function ZO_ItemSetCollectionCategoryData:GetName()
    return GetItemSetCollectionCategoryName(self.categoryId)
end

function ZO_ItemSetCollectionCategoryData:GetFormattedName()
    return zo_strformat(SI_ITEM_SET_CATEGORY_NAME_FORMATTER, self:GetName())
end

function ZO_ItemSetCollectionCategoryData:GetKeyboardIcons()
    return GetItemSetCollectionCategoryKeyboardIcons(self.categoryId)
end

function ZO_ItemSetCollectionCategoryData:GetGamepadIcon()
    return GetItemSetCollectionCategoryGamepadIcon(self.categoryId)
end

function ZO_ItemSetCollectionCategoryData:GetOrder()
    return GetItemSetCollectionCategoryOrder(self.categoryId)
end

function ZO_ItemSetCollectionCategoryData:GetParentCategoryData()
    return self.parentCategoryData
end

function ZO_ItemSetCollectionCategoryData:IsTopLevel()
    return self.parentCategoryData == nil
end

function ZO_ItemSetCollectionCategoryData:IsSubcategory()
    return self.parentCategoryData ~= nil
end

function ZO_ItemSetCollectionCategoryData:GetNumSubcategories()
    return #self.subcategories
end

function ZO_ItemSetCollectionCategoryData:HasSubcategories()
    return #self.subcategories > 0
end

function ZO_ItemSetCollectionCategoryData:GetNumCollections()
    return #self.collections
end

function ZO_ItemSetCollectionCategoryData:HasCollections()
    return #self.collections > 0
end

function ZO_ItemSetCollectionCategoryData:GetNumPieces()
    local numPieces = self.numPieces
    if not numPieces then
        numPieces = 0
        if self:HasSubcategories() then
            for _, subcategoryData in self:SubcategoryIterator() do
                numPieces = numPieces + subcategoryData:GetNumPieces()
            end
        else
            for _, collectionData in self:CollectionIterator() do
                numPieces = numPieces + collectionData:GetNumPieces()
            end
        end
        self.numPieces = numPieces
    end
    return numPieces
end

function ZO_ItemSetCollectionCategoryData:GetNumUnlockedPieces()
    local numUnlockedPieces = self.numUnlockedPieces
    if not numUnlockedPieces then
        numUnlockedPieces = 0
        if self:HasSubcategories() then
            for _, subcategoryData in self:SubcategoryIterator() do
                numUnlockedPieces = numUnlockedPieces + subcategoryData:GetNumUnlockedPieces()
            end
        else
            for _, collectionData in self:CollectionIterator() do
                numUnlockedPieces = numUnlockedPieces + collectionData:GetNumUnlockedPieces()
            end
        end
        self.numUnlockedPieces = numUnlockedPieces
    end
    return numUnlockedPieces
end

-- Minor optimization over calling the two functions independently
function ZO_ItemSetCollectionCategoryData:GetNumUnlockedAndTotalPieces()
    local numPieces = self.numPieces
    local numUnlockedPieces = self.numUnlockedPieces
    if not (numUnlockedPieces or numPieces) then
        numPieces, numUnlockedPieces = 0, 0
        if self:HasSubcategories() then
            for _, subcategoryData in self:SubcategoryIterator() do
                local numUnlockedSubcategoryPieces, numTotalSubcategoryPieces = subcategoryData:GetNumUnlockedAndTotalPieces()
                numUnlockedPieces = numUnlockedPieces + numUnlockedSubcategoryPieces
                numPieces = numPieces + numTotalSubcategoryPieces
            end
        else
            for _, collectionData in self:CollectionIterator() do
                numUnlockedPieces = numUnlockedPieces + collectionData:GetNumUnlockedPieces()
                numPieces = numPieces + collectionData:GetNumPieces()
            end
        end
        self.numUnlockedPieces = numUnlockedPieces
        self.numPieces = numPieces
    elseif not numUnlockedPieces then
        numUnlockedPieces = self:GetNumUnlockedPieces()
    elseif not numPieces then
        numPieces = self:GetNumPieces()
    end
    return numUnlockedPieces, numPieces
end

function ZO_ItemSetCollectionCategoryData:InvalidateCacheData()
    self.numUnlockedPieces = nil
    for _, subcategoryData in self:SubcategoryIterator() do
        subcategoryData:InvalidateCacheData()
    end
end

do
    local COLLECTION_FILTERS = { ZO_ItemSetCollectionData.HasAnyUnlockedPieces }

    function ZO_ItemSetCollectionCategoryData:HasAnyUnlockedPieces()
        if self:HasSubcategories() then
            for _, subcategoryData in self:SubcategoryIterator({ ZO_ItemSetCollectionCategoryData.HasAnyUnlockedPieces }) do
                return true
            end
        else
            for _, collectionData in self:CollectionIterator(COLLECTION_FILTERS) do
                return true
            end
        end
        return false
    end
end

function ZO_ItemSetCollectionCategoryData:HasAnyNewPieces()
    if self:HasSubcategories() then
        for _, subcategoryData in self:SubcategoryIterator({ ZO_ItemSetCollectionCategoryData.HasAnyNewPieces }) do
            return true
        end
    else
        for _, collectionData in self:CollectionIterator({ ZO_ItemSetCollectionData.HasAnyNewPieces }) do
            return true
        end
    end
end

function ZO_ItemSetCollectionCategoryData:ClearNew(dontBroadcast)
    local DONT_BROADCAST = true
    if self:HasSubcategories() then
        for _, subcategoryData in self:SubcategoryIterator() do
            subcategoryData:ClearNew(DONT_BROADCAST)
        end
    else
        for _, collectionData in self:CollectionIterator() do
            collectionData:ClearNew(DONT_BROADCAST)
        end
    end

    if not dontBroadcast then
        ITEM_SET_COLLECTIONS_DATA_MANAGER:OnCollectionCategoryNewStatusCleared(self)
    end
end

function ZO_ItemSetCollectionCategoryData:SetSearchResultsVersion(searchResultsVersion)
    self.searchResultsVersion = searchResultsVersion
    if self.parentCategoryData then
        self.parentCategoryData:SetSearchResultsVersion(searchResultsVersion)
    end
end

function ZO_ItemSetCollectionCategoryData:IsSearchResult()
    if self.searchResultsVersion then
        if self.searchResultsVersion == ITEM_SET_COLLECTIONS_DATA_MANAGER:GetSearchResultsVersion() then
            return true
        else
            -- Old search result, might as well clean it up while we're here
            self.searchResultsVersion = nil
        end
    end
    return false
end

function ZO_ItemSetCollectionCategoryData:Equals(otherItemSetCollectionCategoryData)
    return self:GetId() == otherItemSetCollectionCategoryData:GetId()
end

function ZO_ItemSetCollectionCategoryData:CompareTo(otherItemSetCollectionCategoryData)
    if self:IsInstanceOf(ZO_ItemSetCollectionSummaryCategoryData) then
        return not otherItemSetCollectionCategoryData:IsInstanceOf(ZO_ItemSetCollectionSummaryCategoryData)
    end
    local order = self:GetOrder()
    local otherOrder = otherItemSetCollectionCategoryData:GetOrder()
    return order < otherOrder or (order == otherOrder and self:GetName() < otherItemSetCollectionCategoryData:GetName())
end

function ZO_ItemSetCollectionCategoryData:SortChildren()
    self:SortSubcategories()
    self:SortCollections()
end

function ZO_ItemSetCollectionCategoryData:SortSubcategories()
    table.sort(self.subcategories, ZO_ItemSetCollectionCategoryData.CompareTo)
    for _, subcategory in ipairs(self.subcategories) do
        subcategory:SortChildren()
    end
end

function ZO_ItemSetCollectionCategoryData:SortCollections()
    table.sort(self.collections, ZO_ItemSetCollectionData.CompareTo)
end

function ZO_ItemSetCollectionCategoryData:SubcategoryIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.subcategories, filterFunctions)
end

function ZO_ItemSetCollectionCategoryData:CollectionIterator(filterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.collections, filterFunctions)
end

function ZO_ItemSetCollectionCategoryData:AnyChildPassesFilters(pieceFilterFunctions)
    if self:HasSubcategories() then
        for _, subcategoryData in self:SubcategoryIterator() do
            if subcategoryData:AnyChildPassesFilters(pieceFilterFunctions) then
                return true
            end
        end
    else
        for _, collectionData in self:CollectionIterator() do
            if collectionData:AnyChildPassesFilters(pieceFilterFunctions) then
                return true
            end
        end
    end
    return false
end

-- Summary Category --

ZO_ItemSetCollectionSummaryCategoryData = ZO_ItemSetCollectionCategoryData:Subclass()

function ZO_ItemSetCollectionSummaryCategoryData:AnyChildPassesFilters(pieceFilterFunctions)
    -- Ensure that this top-level category appears in the list despite having no valid children.
    return true
end

function ZO_ItemSetCollectionSummaryCategoryData:GetGamepadIcon()
    return "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_itemSetCollections.dds"
end

function ZO_ItemSetCollectionSummaryCategoryData:GetKeyboardIcons()
    local UP_ICON = "EsoUI/Art/Collections/collections_tabIcon_itemSets_up.dds"
    local DOWN_ICON = "EsoUI/Art/Collections/collections_tabIcon_itemSets_down.dds"
    local OVER_ICON = "EsoUI/Art/Collections/collections_tabIcon_itemSets_over.dds"
    return UP_ICON, DOWN_ICON, OVER_ICON
end

function ZO_ItemSetCollectionSummaryCategoryData:GetName()
    return GetString(SI_ITEM_SET_CATEGORY_SUMMARY_LABEL)
end

function ZO_ItemSetCollectionSummaryCategoryData:GetNumUnlockedAndTotalPieces()
    local numUnlockedPieces, numPieces = 0, 0
    for _, topLevelCategoryData in ITEM_SET_COLLECTIONS_DATA_MANAGER:TopLevelItemSetCollectionCategoryIterator() do
        local categoryUnlockedPieces, categoryPieces = topLevelCategoryData:GetNumUnlockedAndTotalPieces()
        numUnlockedPieces = numUnlockedPieces + categoryUnlockedPieces
        numPieces = numPieces + categoryPieces
    end
    return numUnlockedPieces, numPieces
end

local SUMMARY_CATEGORY_ID = 0
ITEM_SET_COLLECTIONS_SUMMARY_CATEGORY_DATA = ZO_ItemSetCollectionSummaryCategoryData:New(SUMMARY_CATEGORY_ID)