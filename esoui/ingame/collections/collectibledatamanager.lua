ZO_COLLECTIBLE_DATA_FILTERS = 
{
    INCLUDE_LOCKED = true,
    EXCLUDE_LOCKED = false,
    INCLUDE_INVALID_FOR_PLAYER = true,
    EXCLUDE_INVALID_FOR_PLAYER = false,
}

ZO_COLLECTIBLE_LOCK_STATE_CHANGE =
{
    NONE = 0,
    UNLOCKED = 1,
    LOCKED = 2,
}

----------------------
-- Collectible Data --
----------------------

ZO_CollectibleData = ZO_Object:Subclass()

function ZO_CollectibleData:New(...)
    local object = ZO_Object:New(self)
    object:Initialize(...)
    return object
end

function ZO_CollectibleData:Initialize()
    -- Nothing to initialize, for now
end

function ZO_CollectibleData:Reset()
    self.cachedNameWithNickname = nil
end

do
    local g_unusedReturn = nil

    function ZO_CollectibleData:BuildData(categoryData, collectibleIndex)
        self.categoryData = categoryData
        local categoryIndex, subcategoryIndex = categoryData:GetCategoryIndicies()
        local collectibleId = GetCollectibleId(categoryIndex, subcategoryIndex, collectibleIndex)

        self.collectibleIndex = collectibleIndex
        self.collectibleId = collectibleId
        self.name, self.description, self.icon, g_unusedReturn, g_unusedReturn, self.isPurchasable, self.isActive, self.categoryType, self.hint, self.isPlaceholder = GetCollectibleInfo(collectibleId)
        self.keyboardBackgroundImage = GetCollectibleKeyboardBackgroundImage(collectibleId)
        self.gamepadBackgroundImage = GetCollectibleGamepadBackgroundImage(collectibleId)
        self.referenceId = GetCollectibleReferenceId(collectibleId)
        self.sortOrder = GetCollectibleSortOrder(collectibleId)
        self.hasVisualAppearence = DoesCollectibleHaveVisibleAppearance(collectibleId)
        self.categoryTypeDisplayName = GetString("SI_COLLECTIBLECATEGORYTYPE", self.categoryType)
        self.hideMode = GetCollectibleHideMode(collectibleId)
        self.isValidForPlayer = IsCollectibleValidForPlayer(collectibleId)

        self:SetStoriesData()
        self:SetHousingData()
        self:SetOutfitStyleData()

        self:SetupGridCategoryName()

        self:Refresh()
        ZO_COLLECTIBLE_DATA_MANAGER:MapCollectibleData(self)
    end
end

function ZO_CollectibleData:SetStoriesData()
    if self:IsStory() then
        self.unlockedViaSubscription = DoesESOPlusUnlockCollectible(self.collectibleId)
        self.questName, self.questDescription = GetCollectibleQuestPreviewInfo(self.collectibleId)
    else
        self.unlockedViaSubscription = false
        self.questName = nil
        self.questDescription = nil
    end
end

do
    local DEFAULT_HOUSE_HINT = GetString(SI_HOUSING_BOOK_AVAILABLE_FOR_PURCHASE)

    function ZO_CollectibleData:SetHousingData()
        if self:IsHouse() then
            if self.hint == "" then
                self.hint = DEFAULT_HOUSE_HINT
            end
            
            local referenceId = self.referenceId
            local houseFoundInZoneId = GetHouseFoundInZoneId(referenceId)
            self.houseLocation = GetZoneNameById(houseFoundInZoneId)
            self.houseCategoryType = GetHouseCategoryType(referenceId)
            self.isPrimaryResidence = IsPrimaryHouse(referenceId)
        else
            self.houseLocation = nil
            self.houseCategoryType = nil
            self.isPrimaryResidence = nil
        end
    end
end

function ZO_CollectibleData:SetOutfitStyleData()
    if self:IsOutfitStyle() then
        local referenceId = self.referenceId
        self.isArmorStyle = IsOutfitStyleArmor(referenceId)
        self.isWeaponStyle = IsOutfitStyleWeapon(referenceId)
        self.visualArmorType = self.isArmorStyle and GetOutfitStyleVisualArmorType(referenceId) or nil
        self.weaponModelType = self.isWeaponStyle and GetOutfitStyleWeaponModelType(referenceId) or nil
        self.outfitStyleCost = GetOutfitStyleCost(referenceId)
        self.outfitStyleItemStyleId = GetOutfitStyleItemStyleId(referenceId)
        self.outfitStyleItemStyleName = GetItemStyleName(self.outfitStyleItemStyleId)
        self.outfitStyleGearType = self:IsArmorStyle() and self:GetVisualArmorType() or self:GetWeaponModelType()
        self.outfitStyleFreeConversionCollectible = GetOutfitStyleFreeConversionCollectibleId(referenceId)
    else
        self.isArmorStyle = nil
        self.isWeaponStyle = nil
        self.visualArmorType = nil
        self.weaponModelType = nil
        self.outfitStyleCost = nil
        self.outfitStyleItemStyleId = nil
        self.outfitStyleItemStyleName = nil
        self.outfitStyleGearType = nil
        self.outfitStyleFreeConversionCollectible = nil
    end
end

function ZO_CollectibleData:SetupGridCategoryName()
    if self:IsOutfitStyle() then
        if self.isArmorStyle then
            self.gridHeaderName = GetString("SI_VISUALARMORTYPE", self.visualArmorType)
        else
            self.gridHeaderName = GetString("SI_WEAPONMODELTYPE", self.weaponModelType)
        end
    else
        -- If we ever want to support more grid based layouts of collectibles, we can design layouts for the groupings and use categoryName to control it, based on the collectible types
        self.gridHeaderName = nil
    end
end

function ZO_CollectibleData:Refresh()
    local collectibleId = self.collectibleId
    local previousUnlockState = self.unlockState
    self.isActive = IsCollectibleActive(collectibleId)
    self.nickname = GetCollectibleNickname(collectibleId)
    self.unlockState = GetCollectibleUnlockStateById(collectibleId)
    self:SetNew(IsCollectibleNew(collectibleId))
    self.isRenameable = IsCollectibleRenameable(collectibleId)
    self.isSlottable = IsCollectibleSlottable(collectibleId)
    self.cachedNameWithNickname = nil

    local categoryData = self:GetCategoryData()
    if categoryData then
        local specializedSortedCollectibles = categoryData:GetSpecializedSortedCollectiblesObject()
        if previousUnlockState ~= self.unlockState then
            specializedSortedCollectibles:HandleLockStatusChanged(self)
        end
    end
end

function ZO_CollectibleData:RefreshHousingData()
    if self:IsHouse() then
        local wasPrimaryResidence = self.isPrimaryResidence
        self.isPrimaryResidence = IsPrimaryHouse(self.referenceId)

        local categoryData = self:GetCategoryData()
        if categoryData then
            local specializedSortedCollectibles = categoryData:GetSpecializedSortedCollectiblesObject()
            if wasPrimaryResidence ~= self.isPrimaryResidence then
                specializedSortedCollectibles:HandlePrimaryResidenceChanged(self)
            end
        end
    end
end

function ZO_CollectibleData:GetCategoryData()
    return self.categoryData
end

function ZO_CollectibleData:GetIndex()
    return self.collectibleIndex
end

function ZO_CollectibleData:GetId()
    return self.collectibleId
end

function ZO_CollectibleData:GetName()
    return self.name
end

function ZO_CollectibleData:GetFormattedName()
    return ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, self.name)
end

function ZO_CollectibleData:GetNameWithNickname()
    if not self.cachedNameWithNickname then
        local nickname = self.nickname
        if nickname and nickname ~= "" then
            self.cachedNameWithNickname = zo_strformat(SI_COLLECTIBLE_NAME_WITH_NICKNAME_FORMATTER, self.name, nickname)
        else
            self.cachedNameWithNickname = ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, self.name)
        end
    end

    return self.cachedNameWithNickname
end

function ZO_CollectibleData:GetRawNameWithNickname()
    local nickname = self.nickname
    if nickname and nickname ~= "" then
        return zo_strformat(SI_COLLECTIBLE_NAME_WITH_NICKNAME_RAW, self.name, nickname)
    else
        return self.name
    end
end

function ZO_CollectibleData:GetDescription()
    return self.description
end

function ZO_CollectibleData:GetIcon()
    return self.icon
end

function ZO_CollectibleData:GetUnlockState()
    return self.unlockState
end

function ZO_CollectibleData:IsUnlocked()
    return self.unlockState ~= COLLECTIBLE_UNLOCK_STATE_LOCKED
end

function ZO_CollectibleData:IsLocked()
    return self.unlockState == COLLECTIBLE_UNLOCK_STATE_LOCKED
end

function ZO_CollectibleData:IsOwned()
    return self.unlockState == COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED
end

function ZO_CollectibleData:IsPurchasable()
    return self.isPurchasable
end

function ZO_CollectibleData:IsActive()
    return self.isActive
end

function ZO_CollectibleData:GetCategoryType()
    return self.categoryType
end

function ZO_CollectibleData:GetCategoryTypeDisplayName()
    return self.categoryTypeDisplayName
end

function ZO_CollectibleData:IsCategoryType(categoryType)
    return self.categoryType == categoryType
end

function ZO_CollectibleData:GetHint()
    return self.hint
end

function ZO_CollectibleData:IsPlaceholder()
    return self.isPlaceholder
end

function ZO_CollectibleData:GetKeyboardBackgroundImage()
    return self.keyboardBackgroundImage
end

function ZO_CollectibleData:GetGamepadBackgroundImage()
    return self.gamepadBackgroundImage
end

function ZO_CollectibleData:GetNickname()
    return self.nickname
end

function ZO_CollectibleData:GetFormattedNickname()
    if self.nickname ~= "" then
        return ZO_CachedStrFormat(SI_TOOLTIP_COLLECTIBLE_NICKNAME, self.nickname)
    else
        return ""
    end
end

function ZO_CollectibleData:IsRenameable()
    return self.isRenameable
end

function ZO_CollectibleData:IsSlottable()
    return self.isSlottable
end

function ZO_CollectibleData:IsNew()
    return self.isNew
end

function ZO_CollectibleData:SetNew(isNew)
    if self.isNew ~= isNew then
        self.isNew = isNew
        local categoryData = self:GetCategoryData()
        if categoryData then
            categoryData:UpdateNewCache(self)
        end
    end
end

function ZO_CollectibleData:GetReferenceId()
    return self.referenceId
end

function ZO_CollectibleData:GetSortOrder()
    return self.sortOrder
end

function ZO_CollectibleData:IsStory()
    return self.categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC or self.categoryType == COLLECTIBLE_CATEGORY_TYPE_CHAPTER
end

function ZO_CollectibleData:IsUnlockedViaSubscription()
    return self.unlockedViaSubscription
end

function ZO_CollectibleData:GetQuestName()
    return self.questName
end

function ZO_CollectibleData:GetQuestDescription()
    return self.questDescription
end

function ZO_CollectibleData:IsHouse()
    return self.categoryType == COLLECTIBLE_CATEGORY_TYPE_HOUSE
end

function ZO_CollectibleData:GetHouseLocation()
    return self.houseLocation
end

function ZO_CollectibleData:GetFormattedHouseLocation()
    return ZO_CachedStrFormat(SI_ZONE_NAME, self.houseLocation)
end

function ZO_CollectibleData:GetHouseCategoryType()
    return self.houseCategoryType
end

function ZO_CollectibleData:IsPrimaryResidence()
    return self.isPrimaryResidence
end

function ZO_CollectibleData:IsOutfitStyle()
    return self.categoryType == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE
end

function ZO_CollectibleData:IsArmorStyle()
    return self.isArmorStyle
end

function ZO_CollectibleData:IsWeaponStyle()
    return self.isWeaponStyle
end

function ZO_CollectibleData:GetVisualArmorType()
    return self.visualArmorType
end

function ZO_CollectibleData:GetWeaponModelType()
    return self.weaponModelType
end

function ZO_CollectibleData:GetOutfitGearType()
    return self.outfitStyleGearType
end

function ZO_CollectibleData:GetOutfitStyleItemStyleId()
    return self.outfitStyleItemStyleId
end

function ZO_CollectibleData:GetOutfitStyleItemStyleName()
    return self.outfitStyleItemStyleName
end

function ZO_CollectibleData:GetOutfitStyleCost()
    if self:IsOutfitStyle() then
        if self.outfitStyleCost ~= 0 and self.outfitStyleFreeConversionCollectible then
            local freeConversionCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(self.outfitStyleFreeConversionCollectible)
            if freeConversionCollectibleData and freeConversionCollectibleData:IsUnlocked() then
                return 0
            end
        end
        return self.outfitStyleCost
    end
    return 0 -- No one should ever hit this code
end

function ZO_CollectibleData:GetOutfitStyleFreeConversionCollectible()
    return self.outfitStyleFreeConversionCollectible
end

function ZO_CollectibleData:IsBlocked()
    return IsCollectibleBlocked(self.collectibleId)
end

function ZO_CollectibleData:IsUsable()
    return IsCollectibleUsable(self.collectibleId)
end

function ZO_CollectibleData:IsPlaceableFurniture()
    return IsCollectibleCategoryPlaceableFurniture(self.categoryType)
end

function ZO_CollectibleData:IsValidForPlayer()
    return self.isValidForPlayer
end

function ZO_CollectibleData:HasVisualAppearence()
    return self.hasVisualAppearence
end

function ZO_CollectibleData:WouldBeHidden()
    return WouldCollectibleBeHidden(self.collectibleId)
end

function ZO_CollectibleData:IsVisualLayerHidden()
    return self.hasVisualAppearence and self:IsActive() and self:WouldBeHidden()
end

function ZO_CollectibleData:IsVisualLayerShowing()
    return self.hasVisualAppearence and self:IsActive() and not self:WouldBeHidden()
end

function ZO_CollectibleData:GetNotificationId()
    return self.notificationId
end

function ZO_CollectibleData:SetNotificationId(notificationId)
    self.notificationId = notificationId
end

function ZO_CollectibleData:IsHiddenFromCollection()
    local hideMode = self.hideMode
    if hideMode == COLLECTIBLE_HIDE_MODE_NONE then
        return false
    elseif hideMode == COLLECTIBLE_HIDE_MODE_ALWAYS then
        return true
    elseif hideMode == COLLECTIBLE_HIDE_MODE_WHEN_LOCKED then
        return self:IsLocked()
    elseif hideMode == COLLECTIBLE_HIDE_MODE_WHEN_LOCKED_REQUIREMENT then
        return self:IsLocked() and IsCollectibleDynamicallyHidden(self.collectibleId)
    end
    return false
end

function ZO_CollectibleData:IsShownInCollection()
    return not self:IsHiddenFromCollection()
end

do
    local ARMOR_VISUAL_TO_SOUND_ID =
    {
        [VISUAL_ARMORTYPE_LIGHT]        = SOUNDS.OUTFIT_ARMOR_TYPE_LIGHT,
        [VISUAL_ARMORTYPE_MEDIUM]       = SOUNDS.OUTFIT_ARMOR_TYPE_MEDIUM,
        [VISUAL_ARMORTYPE_HEAVY]        = SOUNDS.OUTFIT_ARMOR_TYPE_HEAVY,
        [VISUAL_ARMORTYPE_UNDAUNTED]    = SOUNDS.OUTFIT_ARMOR_TYPE_UNDAUNTED,
        [VISUAL_ARMORTYPE_CLOTHING]     = SOUNDS.OUTFIT_ARMOR_TYPE_CLOTHING,
        [VISUAL_ARMORTYPE_SIGNATURE]    = SOUNDS.OUTFIT_ARMOR_TYPE_SIGNATURE,
    }

    local WEAPON_VISUAL_TO_SOUND_ID =
    {
        [WEAPON_MODEL_TYPE_AXE]     = SOUNDS.OUTFIT_WEAPON_TYPE_AXE,
        [WEAPON_MODEL_TYPE_HAMMER]  = SOUNDS.OUTFIT_WEAPON_TYPE_MACE,
        [WEAPON_MODEL_TYPE_SWORD]   = SOUNDS.OUTFIT_WEAPON_TYPE_SWORD,
        [WEAPON_MODEL_TYPE_DAGGER]  = SOUNDS.OUTFIT_WEAPON_TYPE_DAGGER,
        [WEAPON_MODEL_TYPE_BOW]     = SOUNDS.OUTFIT_WEAPON_TYPE_BOW,
        [WEAPON_MODEL_TYPE_STAFF]   = SOUNDS.OUTFIT_WEAPON_TYPE_STAFF,
        [WEAPON_MODEL_TYPE_SHIELD]  = SOUNDS.OUTFIT_WEAPON_TYPE_SHIELD,
        [WEAPON_MODEL_TYPE_RUNE]    = SOUNDS.OUTFIT_WEAPON_TYPE_RUNE,
    }

    function ZO_CollectibleData:GetOutfitStyleEquipSound()
        if self.visualArmorType then
            return ARMOR_VISUAL_TO_SOUND_ID[self.visualArmorType]
        elseif self.weaponModelType then
            return WEAPON_VISUAL_TO_SOUND_ID[self.weaponModelType]
        end
    end
end

-----------------------------------
-- Specialized Sorted Collectibles
-----------------------------------

ZO_SpecializedSortedCollectibles = ZO_Object:Subclass()

function ZO_SpecializedSortedCollectibles:New(...)
    local object = ZO_Object:New(self)
    object:Initialize(...)
    return object
end

function ZO_SpecializedSortedCollectibles:Initialize()
    self.dirty = false
    self.sortedCollectibles = {}
end

function ZO_SpecializedSortedCollectibles:GetCollectibles()
    if self.dirty then
        self:RefreshSort()
    end

    return self.sortedCollectibles
end

function ZO_SpecializedSortedCollectibles:InsertCollectible(collectibleData)
    assert(false) -- override in derived classes
end

function ZO_SpecializedSortedCollectibles:OnInsertFinished()
    assert(false) -- override in derived classes
end

function ZO_SpecializedSortedCollectibles:RefreshSort()
    assert(false) -- override in derived classes
end

function ZO_SpecializedSortedCollectibles:CanIterateCollectibles()
    return true
end

function ZO_SpecializedSortedCollectibles:HandleLockStatusChanged(collectibleData)
    -- By default, do nothing
end

function ZO_SpecializedSortedCollectibles:HandlePrimaryResidenceChanged(collectibleData)
    -- By default, do nothing
end

-----------------------------
-- Default Sorted Collectible
-----------------------------

ZO_DefaultSortedCollectibles = ZO_SpecializedSortedCollectibles:Subclass()

function ZO_DefaultSortedCollectibles:New(...)
    return ZO_SpecializedSortedCollectibles.New(self, ...)
end

function ZO_DefaultSortedCollectibles:Initialize(owner)
    ZO_SpecializedSortedCollectibles.Initialize(self)
    self.owner = owner

    self.collectibleNameLookupTable = {}
end


function ZO_DefaultSortedCollectibles:InsertCollectible(collectibleData)
    table.insert(self.sortedCollectibles, collectibleData)

    local collectibleId = collectibleData:GetId()
    if not self.collectibleNameLookupTable[collectibleId] then
        self.collectibleNameLookupTable[collectibleId] =
        {
            name = collectibleData:GetName(),
            id = collectibleId
        }
    end

    self.dirty = true
end

function ZO_DefaultSortedCollectibles:HandleLockStatusChanged(collectibleData)
    self.dirty = true
end

function ZO_DefaultSortedCollectibles:RefreshSort()
    if self.dirty then
        local collectibleNameLookupTable = self.collectibleNameLookupTable
        table.sort(self.sortedCollectibles, function(left, right) 
            if left:IsUnlocked() ~= right:IsUnlocked() then
                return left:IsUnlocked()
            elseif left:GetSortOrder() ~= right:GetSortOrder() then
                return left:GetSortOrder() < right:GetSortOrder()
            elseif left:IsValidForPlayer() ~= right:IsValidForPlayer() then
                return left:IsValidForPlayer()
            else
                return collectibleNameLookupTable[left:GetId()] < collectibleNameLookupTable[right:GetId()]
            end
        end)
    end

    self.dirty = false
end

function ZO_DefaultSortedCollectibles:OnInsertFinished()
    local tempTable = {}
    for _, collectibleNameData in pairs(self.collectibleNameLookupTable) do
        table.insert(tempTable, collectibleNameData)
    end

    table.sort(tempTable, function(left, right)
        return left.name < right.name
    end)

    self.collectibleNameLookupTable = {}
    
    for position, collectibleNameData in ipairs(tempTable) do
        self.collectibleNameLookupTable[collectibleNameData.id] = position
    end
end

-------------------------------------------------------
-- Specialized Sorted Collectibles Outfit Style Types
-------------------------------------------------------

ZO_SpecializedSortedOutfitStyleTypes = ZO_SpecializedSortedCollectibles:Subclass()

function ZO_SpecializedSortedOutfitStyleTypes:New(...)
    return ZO_SpecializedSortedCollectibles.New(self, ...)
end

function ZO_SpecializedSortedOutfitStyleTypes:Initialize()
    ZO_SpecializedSortedCollectibles.Initialize(self)

    self.itemStyleNameLookupTable = {}
end

function ZO_SpecializedSortedOutfitStyleTypes:InsertCollectible(collectibleData)
    local type = collectibleData:GetOutfitGearType()
    if type then
        local styles = self.sortedCollectibles[type] 
        if not styles then
            styles = ZO_SpecializedSortedOutfitStyles:New(self)
            self.sortedCollectibles[type] = styles
        end

        local itemStyleId = collectibleData:GetOutfitStyleItemStyleId()
        if not self.itemStyleNameLookupTable[itemStyleId] then
            self.itemStyleNameLookupTable[itemStyleId] =
            {
                name = collectibleData:GetOutfitStyleItemStyleName(),
                id = itemStyleId
            }
        end

        styles:InsertCollectible(collectibleData)
        self.dirty = true
    end
end

function ZO_SpecializedSortedOutfitStyleTypes:HandleLockStatusChanged(collectibleData)
    local type = collectibleData:GetOutfitGearType()
    if type and self.sortedCollectibles[type] then
        self.sortedCollectibles[type]:HandleLockStatusChanged(collectibleData)
        self.dirty = true
    end
end

function ZO_SpecializedSortedOutfitStyleTypes:RefreshSort()
    if self.dirty then
        for weaponOrArmorType, collectibleDataForType in pairs(self.sortedCollectibles) do
            collectibleDataForType:RefreshSort()
        end

        self.dirty = false
    end
end

function ZO_SpecializedSortedOutfitStyleTypes:OnInsertFinished()
    local tempTable = {}
    for _, styleNameData in pairs(self.itemStyleNameLookupTable) do
        table.insert(tempTable, styleNameData)
    end

    table.sort(tempTable, function(left, right)
        return left.name < right.name
    end)
    
    for position, styleNameData in ipairs(tempTable) do
        self.itemStyleNameLookupTable[styleNameData.id] = position
    end

    for weaponOrArmorType, collectibleDataForType in pairs(self.sortedCollectibles) do
        collectibleDataForType:OnInsertFinished()
    end

    self:RefreshSort()
end

function ZO_SpecializedSortedOutfitStyleTypes:CanIterateCollectibles()
    -- Outfit styles are sorted with a custom structure that requires manual looping
    return false
end

--------------------------------------------------
-- Specialized Sorted Collectibles Outfit Styles
--------------------------------------------------

ZO_SpecializedSortedOutfitStyles = ZO_DefaultSortedCollectibles:Subclass()

function ZO_SpecializedSortedOutfitStyles:New(...)
    return ZO_DefaultSortedCollectibles.New(self, ...)
end

function ZO_SpecializedSortedOutfitStyles:RefreshSort()
    if self.dirty then
        local itemStyleNameLookupTable = self.owner.itemStyleNameLookupTable
        local collectibleNameLookupTable = self.collectibleNameLookupTable
        table.sort(self.sortedCollectibles, function(left, right) 
            if left:IsUnlocked() ~= right:IsUnlocked() then
                return left:IsUnlocked()
            elseif left:GetOutfitStyleItemStyleId() ~= right:GetOutfitStyleItemStyleId() then
                return itemStyleNameLookupTable[left:GetOutfitStyleItemStyleId()] < itemStyleNameLookupTable[right:GetOutfitStyleItemStyleId()]
            elseif left:GetSortOrder() ~= right:GetSortOrder() then
                return left:GetSortOrder() < right:GetSortOrder()
            else
                return collectibleNameLookupTable[left:GetId()] < collectibleNameLookupTable[right:GetId()]
            end
        end)
    end

    self.dirty = false
end

-----------------------------------------
-- Specialized Sorted Collectibles Houses
-----------------------------------------

ZO_SpecializedSortedHouses = ZO_DefaultSortedCollectibles:Subclass()

function ZO_SpecializedSortedHouses:New(...)
    return ZO_DefaultSortedCollectibles.New(self, ...)
end

function ZO_SpecializedSortedHouses:HandlePrimaryResidenceChanged(collectibleData)
    self.dirty = true
end

function ZO_SpecializedSortedHouses:RefreshSort()
    if self.dirty then
        local collectibleNameLookupTable = self.collectibleNameLookupTable
        table.sort(self.sortedCollectibles, function(left, right)
            if left:IsPrimaryResidence() ~= right:IsPrimaryResidence() then
                return left:IsPrimaryResidence()
            elseif left:IsUnlocked() ~= right:IsUnlocked() then
                return left:IsUnlocked()
            elseif left:GetSortOrder() ~= right:GetSortOrder() then
                return left:GetSortOrder() < right:GetSortOrder()
            else
                return collectibleNameLookupTable[left:GetId()] < collectibleNameLookupTable[right:GetId()]
            end
        end)
    end

    self.dirty = false
end

------------------------------------------
-- Specialized Sorted Collectibles Stories
------------------------------------------

ZO_SpecializedSortedStories = ZO_DefaultSortedCollectibles:Subclass()

function ZO_SpecializedSortedStories:New(...)
    return ZO_DefaultSortedCollectibles.New(self, ...)
end

function ZO_SpecializedSortedStories:HandleLockStatusChanged(collectibleData)
    -- Do nothing, stories don't re-sort, their order is based on release date
end

function ZO_SpecializedSortedStories:RefreshSort()
    if self.dirty then
        local collectibleNameLookupTable = self.collectibleNameLookupTable
        table.sort(self.sortedCollectibles, function(left, right)
            if left:GetSortOrder() ~= right:GetSortOrder() then
                return left:GetSortOrder() < right:GetSortOrder()
            else
                return collectibleNameLookupTable[left:GetId()] < collectibleNameLookupTable[right:GetId()]
            end
        end)
    end

    self.dirty = false
end
-------------------
-- Category Base --
-------------------

ZO_CollectibleCategoryData = ZO_Object:Subclass()

function ZO_CollectibleCategoryData:New(...)
    local object = ZO_Object:New(self)
    object:Initialize(...)
    return object
end

function ZO_CollectibleCategoryData:Initialize(masterCollectibleObjectPool, masterSubcategoryObjectPool)
    -- orderedCollectibles is the order they came from C in.  specializedSortedCollectibles is the sorted list, based on criterea set for the category type
    self.orderedCollectibles = {}
    self.newCollectibleIdsCache = {}
    self.collectibleObjectPool = ZO_MetaPool:New(masterCollectibleObjectPool)
    
    if masterSubcategoryObjectPool then
        self.orderedSubcategories = {}
        self.subcategoryObjectPool = ZO_MetaPool:New(masterSubcategoryObjectPool)
        self.isTopLevelCategory = true
    else
        self.isTopLevelCategory = false
    end
end

function ZO_CollectibleCategoryData:Reset()
    ZO_ClearNumericallyIndexedTable(self.orderedCollectibles)
    ZO_ClearTable(self.newCollectibleIdsCache)
    self.collectibleObjectPool:ReleaseAllObjects()

    if self.isTopLevelCategory then
        ZO_ClearNumericallyIndexedTable(self.orderedSubcategories)
        self.subcategoryObjectPool:ReleaseAllObjects()
    end
end

function ZO_CollectibleCategoryData:IsTopLevelCategory()
    return self.isTopLevelCategory
end

function ZO_CollectibleCategoryData:IsSubcategory()
    return not self.isTopLevelCategory
end

function ZO_CollectibleCategoryData:GetParentData()
    if self:IsSubcategory() then
        return ZO_COLLECTIBLE_DATA_MANAGER:GetCategoryDataByIndicies(self.categoryIndex)
    end
    return nil
end

function ZO_CollectibleCategoryData:GetId()
    return self.categoryId
end

function ZO_CollectibleCategoryData:GetCategorySpecialization()
    return self.categorySpecialization
end

function ZO_CollectibleCategoryData:IsSpecializedCategory(specializedCategoryType)
    return self.categorySpecialization == specializedCategoryType
end

function ZO_CollectibleCategoryData:IsOutfitStylesCategory()
    return self.categorySpecialization == COLLECTIBLE_CATEGORY_SPECIALIZATION_OUTFIT_STYLES
end

function ZO_CollectibleCategoryData:IsHousingCategory()
    return self.categorySpecialization == COLLECTIBLE_CATEGORY_SPECIALIZATION_HOUSING
end

function ZO_CollectibleCategoryData:IsDLCCategory()
    return self.categorySpecialization == COLLECTIBLE_CATEGORY_SPECIALIZATION_DLC
end

function ZO_CollectibleCategoryData:IsStandardCategory()
    return self.categorySpecialization == COLLECTIBLE_CATEGORY_SPECIALIZATION_NONE
end

function ZO_CollectibleCategoryData:GetCategoryIndicies()
    return self.categoryIndex, self.subcategoryIndex
end

function ZO_CollectibleCategoryData:BuildData(categoryIndex, subcategoryIndex)
    self.categoryIndex, self.subcategoryIndex = categoryIndex, subcategoryIndex
    self.categoryId = GetCollectibleCategoryId(categoryIndex, subcategoryIndex)
    
    self.keyboardNormalIcon, self.keyboardPressedIcon, self.keyboardMousedOverIcon, self.disabledIcon = GetCollectibleCategoryKeyboardIcons(categoryIndex, subcategoryIndex)
    self.gamepadIcon = GetCollectibleCategoryGamepadIcon(categoryIndex, subcategoryIndex)

    if self.isTopLevelCategory then
        self.name, self.numSubcategories, self.numCollectibles = GetCollectibleCategoryInfo(categoryIndex)

        for subcategoryIndex = 1, self:GetNumSubcategories() do
            local subcategoryData = self.subcategoryObjectPool:AcquireObject()
            subcategoryData:BuildData(categoryIndex, subcategoryIndex)
            table.insert(self.orderedSubcategories, subcategoryData)
        end
    else
        self.name, self.numCollectibles = GetCollectibleSubCategoryInfo(categoryIndex, subcategoryIndex)
        self.numSubcategories = 0
    end

    self.categorySpecialization = GetCollectibleCategorySpecialization(categoryIndex)
    self.specializedSortedCollectibles = self:CreateSpecializedSortedCollectiblesTable()

    for collectibleIndex = 1, self.numCollectibles do
        local collectibleData = self.collectibleObjectPool:AcquireObject()
        collectibleData:BuildData(self, collectibleIndex)
        table.insert(self.orderedCollectibles, collectibleData)
        self.specializedSortedCollectibles:InsertCollectible(collectibleData)
    end

    self.specializedSortedCollectibles:OnInsertFinished()

    ZO_COLLECTIBLE_DATA_MANAGER:MapCategoryData(self)
end

function ZO_CollectibleCategoryData:CreateSpecializedSortedCollectiblesTable()
    if self:IsOutfitStylesCategory() then
        return ZO_SpecializedSortedOutfitStyleTypes:New()
    elseif self:IsHousingCategory() then
        return ZO_SpecializedSortedHouses:New()
    elseif self:IsDLCCategory() then
        return ZO_SpecializedSortedStories:New()
    else
        return ZO_DefaultSortedCollectibles:New()
    end
end

function ZO_CollectibleCategoryData:GetName()
    return self.name
end

function ZO_CollectibleCategoryData:GetFormattedName()
    return ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, self.name)
end

function ZO_CollectibleCategoryData:GetKeyboardIcons()
    return self.keyboardNormalIcon, self.keyboardPressedIcon, self.keyboardMousedOverIcon, self.disabledIcon
end

function ZO_CollectibleCategoryData:GetGamepadIcon()
    return self.gamepadIcon
end

function ZO_CollectibleCategoryData:GetNumSubcategories()
    return self.numSubcategories
end

function ZO_CollectibleCategoryData:GetSubcategoryData(subcategoryIndex)
    if self.isTopLevelCategory then
        return self.orderedSubcategories[subcategoryIndex]
    end
    return nil
end

function ZO_CollectibleCategoryData:SubcategoryIterator(subcategoryFilterFunctions) -- ... Are filter functions that take categoryData as a param
    local index = 0
    local count = self.numSubcategories
    local numFilters = subcategoryFilterFunctions and #subcategoryFilterFunctions or 0
    return function()
        index = index + 1
        while index <= count do
            local passesFilter = true
            local categoryData = self.orderedSubcategories[index]
            for filterIndex = 1, numFilters do
                if not subcategoryFilterFunctions[filterIndex](categoryData) then
                    passesFilter = false
                    break
                end
            end

            if passesFilter then
                return index, categoryData
            else
                index = index + 1
            end
        end
    end
end

function ZO_CollectibleCategoryData:GetNumCollectibles()
    return #self.orderedCollectibles
end

function ZO_CollectibleCategoryData:GetCollectibleDataByIndex(collectibleIndex)
    return self.orderedCollectibles[collectibleIndex]
end

function ZO_CollectibleCategoryData:GetCollectibleDataBySpecializedSort()
    return self.specializedSortedCollectibles:GetCollectibles()
end

function ZO_CollectibleCategoryData:GetSpecializedSortedCollectiblesObject()
    return self.specializedSortedCollectibles
end

function ZO_CollectibleCategoryData:SortedCollectibleIterator(collectibleFilterFunctions)
    local collectiblesTable = self.specializedSortedCollectibles:CanIterateCollectibles() and self.specializedSortedCollectibles:GetCollectibles() or self.orderedCollectibles
    return self:CollectibleIteratorInternal(collectiblesTable, collectibleFilterFunctions)
end

function ZO_CollectibleCategoryData:CollectibleIterator(collectibleFilterFunctions)
    return self:CollectibleIteratorInternal(self.orderedCollectibles, collectibleFilterFunctions)
end

function ZO_CollectibleCategoryData:CollectibleIteratorInternal(collectiblesTable, collectibleFilterFunctions)
    local index = 0
    local count = #collectiblesTable
    local numFilters = collectibleFilterFunctions and #collectibleFilterFunctions or 0
    return function()
        index = index + 1
        while index <= count do
            local passesFilter = true
            local collectibleData = collectiblesTable[index]
            for filterIndex = 1, numFilters do
                if not collectibleFilterFunctions[filterIndex](collectibleData) then
                    passesFilter = false
                    break
                end
            end

            if passesFilter then
                return index, collectibleData
            else
                index = index + 1
            end
        end
    end
end

function ZO_CollectibleCategoryData:GetAllCollectibleDataObjects(collectibleFilterFunctions, sorted) 
    local foundCollectibleDataObjects = {}
    return self:AppendAllCollectibleDataObjects(foundCollectibleDataObjects, collectibleFilterFunctions, sorted)
end

function ZO_CollectibleCategoryData:AppendAllCollectibleDataObjects(foundCollectibleDataObjects, collectibleFilterFunctions, sorted)
    local iterator = sorted and ZO_CollectibleCategoryData.SortedCollectibleIterator or ZO_CollectibleCategoryData.CollectibleIterator

    for _, collectibleData in iterator(self, collectibleFilterFunctions) do
        table.insert(foundCollectibleDataObjects, collectibleData)
    end

    if self.isTopLevelCategory then
        for subcategoryIndex, subcategoryData in ipairs(self.orderedSubcategories) do
            subcategoryData:AppendAllCollectibleDataObjects(foundCollectibleDataObjects, collectibleFilterFunctions, sorted)
        end
    end

    return foundCollectibleDataObjects
end

function ZO_CollectibleCategoryData:HasAnyNewCollectibles()
    if NonContiguousCount(self.newCollectibleIdsCache) > 0 then
        return true
    end

    if self.isTopLevelCategory then
        for subcategoryIndex, subcategoryData in ipairs(self.orderedSubcategories) do
            if subcategoryData:HasAnyNewCollectibles() then
                return true
            end
        end
    end

    return false
end

function ZO_CollectibleCategoryData:UpdateNewCache(collectibleData)
    local collectibleId = collectibleData:GetId()
    local isNew = collectibleData:IsNew()
    self.newCollectibleIdsCache[collectibleId] = isNew or nil
end

function ZO_CollectibleCategoryData:HasAnyUnlockedCollectibles()
    for collectibleIndex, collectibleData in ipairs(self.orderedCollectibles) do
        if collectibleData:IsUnlocked() then
            return true
        end
    end

    if self.isTopLevelCategory then
        for subcategoryIndex, subcategoryData in ipairs(self.orderedSubcategories) do
            if subcategoryData:HasAnyUnlockedCollectibles() then
                return true
            end
        end
    end

    return false
end

function ZO_CollectibleCategoryData:HasShownCollectiblesInCollection()
    for collectibleIndex, collectibleData in ipairs(self.orderedCollectibles) do
        if not collectibleData:IsHiddenFromCollection() then
            return true
        end
    end

    if self.isTopLevelCategory then
        for subcategoryIndex, subcategoryData in ipairs(self.orderedSubcategories) do
            if subcategoryData:HasShownCollectiblesInCollection() then
                return true
            end
        end
    end

    return false
end

------------------
-- Data Manager --
------------------

local FULL_COLLECTION_UPDATE = 0

ZO_CollectibleDataManager = ZO_CallbackObject:Subclass()

function ZO_CollectibleDataManager:New(...)
    ZO_COLLECTIBLE_DATA_MANAGER = ZO_CallbackObject.New(self)
    ZO_COLLECTIBLE_DATA_MANAGER:Initialize(...)
    return ZO_COLLECTIBLE_DATA_MANAGER
end

function ZO_CollectibleDataManager:Initialize()
    self.collectibleIdToDataMap = {}
    self.collectibleCategoryIdToDataMap = {}

    local function CreateCategoryData(objectPool)
        return ZO_CollectibleCategoryData:New(self.collectibleObjectPool, self.subcategoryObjectPool)
    end

    local function CreateSubcategoryData(objectPool)
        return ZO_CollectibleCategoryData:New(self.collectibleObjectPool)
    end

    local function CreateCollectibleData(objectPool)
        return ZO_CollectibleData:New()
    end

    local function ResetData(data)
        data:Reset()
    end
    
    self.categoryObjectPool = ZO_ObjectPool:New(CreateCategoryData, ResetData)
    self.subcategoryObjectPool = ZO_ObjectPool:New(CreateSubcategoryData, ResetData)
    self.collectibleObjectPool = ZO_ObjectPool:New(CreateCollectibleData, ResetData)

    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTIBLE_UPDATED, function(eventId, ...) self:OnCollectibleUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTION_UPDATED, function(eventId, ...) self:OnCollectionUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTIBLES_UPDATED, function(eventId, ...) self:OnCollectionUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_ESO_PLUS_FREE_TRIAL_STATUS_CHANGED, function(eventId, ...) self:OnCollectionUpdated() end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTIBLE_NEW_STATUS_CLEARED, function(eventId, ...) self:OnCollectibleNewStatusCleared(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTIBLE_CATEGORY_NEW_STATUS_CLEARED, function(eventId, ...) self:OnCollectibleCategoryNewStatusCleared(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTIBLE_NOTIFICATION_NEW, function(eventId, ...) self:OnCollectibleNotificationNew(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTIBLE_NOTIFICATION_REMOVED, function(eventId, ...) self:OnCollectibleNotificationRemoved(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_HOUSING_PRIMARY_RESIDENCE_SET, function(_, ...) self:OnPrimaryResidenceSet(...) end)

    self:RebuildCollection()
end

function ZO_CollectibleDataManager:OnCollectibleUpdated(collectibleId, justUnlocked)
    local collectibleData = self.collectibleIdToDataMap[collectibleId]
    if collectibleData then
        collectibleData:Refresh()

        local lockStateChange = ZO_COLLECTIBLE_LOCK_STATE_CHANGE.NONE
        if justUnlocked then
            TriggerTutorial(TUTORIAL_TRIGGER_ACQUIRED_COLLECTIBLE)
            lockStateChange = ZO_COLLECTIBLE_LOCK_STATE_CHANGE.UNLOCKED
        elseif collectibleData:IsLocked() then
            lockStateChange = ZO_COLLECTIBLE_LOCK_STATE_CHANGE.LOCKED
        end
        self:FireCallbacks("OnCollectibleUpdated", collectibleId, lockStateChange)
    else
        local errorString = string.format("EVENT_COLLECTIBLE_UPDATED fired with invalid collectible id (%d)", collectibleId)
        internalassert(false, errorString)
    end
end

function ZO_CollectibleDataManager:OnCollectionUpdated(numJustUnlocked)
    numJustUnlocked = numJustUnlocked or FULL_COLLECTION_UPDATE
    if numJustUnlocked > 0 then
         self:RefreshCollectionOnlyDirtyCollectibles()
    else
        self:RefreshCollection()
    end
    
    if numJustUnlocked > 0 or self:HasAnyUnlockedCollectibles() then
        TriggerTutorial(TUTORIAL_TRIGGER_ACQUIRED_COLLECTIBLE)
    end

    self:FireCallbacks("OnCollectionUpdated", numJustUnlocked)
end

function ZO_CollectibleDataManager:OnCollectibleNewStatusCleared(collectibleId)
    local collectibleData = self.collectibleIdToDataMap[collectibleId]
    if collectibleData then
        collectibleData:SetNew(false)
        self:FireCallbacks("OnCollectibleNewStatusCleared", collectibleId)
    else
        local errorString = string.format("EVENT_COLLECTIBLE_NEW_STATUS_CLEARED fired with invalid collectible id (%d)", collectibleId)
        internalassert(false, errorString)
    end
end

function ZO_CollectibleDataManager:OnCollectibleCategoryNewStatusCleared(categoryId)
    local categoryData = self.collectibleCategoryIdToDataMap[categoryId]
    if categoryData then
        for _, collectibleData in categoryData:CollectibleIterator({ ZO_CollectibleData.IsNew }) do
            collectibleData:SetNew(false)
        end
        self:FireCallbacks("OnCollectibleCategoryNewStatusCleared", categoryId)
    end
end


function ZO_CollectibleDataManager:OnCollectibleNotificationNew(collectibleId, notificationId)
    local collectibleData = self.collectibleIdToDataMap[collectibleId]
    if collectibleData then
        collectibleData:SetNotificationId(notificationId)
        self:FireCallbacks("OnCollectibleNotificationNew", notificationId, collectibleId)
    else
        local errorString = string.format("EVENT_COLLECTIBLE_NOTIFICATION_NEW fired with invalid collectible id (%d)", collectibleId)
        internalassert(false, errorString)
    end
end

function ZO_CollectibleDataManager:OnCollectibleNotificationRemoved(notificationId, collectibleId)
    local collectibleData = self.collectibleIdToDataMap[collectibleId]
    if collectibleData then
        collectibleData:SetNotificationId(nil)
        self:FireCallbacks("OnCollectibleNotificationRemoved", notificationId, collectibleId)
    else
        local errorString = string.format("EVENT_COLLECTIBLE_NOTIFICATION_REMOVED fired with invalid collectible id (%d)", collectibleId)
        internalassert(false, errorString)
    end
end

function ZO_CollectibleDataManager:OnPrimaryResidenceSet(houseId)
    local oldPrimaryResidenceResults = self:GetAllCollectibleDataObjects({ ZO_CollectibleCategoryData.IsHousingCategory }, { ZO_CollectibleData.IsPrimaryResidence })
    for _, collectibleData in ipairs(oldPrimaryResidenceResults) do
        collectibleData:RefreshHousingData()
    end

    if houseId ~= 0 then
        local newPrimaryResidenceCollectibleId = GetCollectibleIdForHouse(houseId)
        local newPrimaryResidenceCollectibleData = self:GetCollectibleDataById(newPrimaryResidenceCollectibleId)
        newPrimaryResidenceCollectibleData:RefreshHousingData()
    end

    self:FireCallbacks("PrimaryResidenceSet", houseId)
end

function ZO_CollectibleDataManager:RefreshCollection()
    for _, collectibleData in pairs(self.collectibleIdToDataMap) do
        collectibleData:Refresh()
        collectibleData:SetNotificationId(nil)
    end

    self:MapNotifications()
end

do
    local function ZO_GetNextDirtyCollectibeIdIter(state, lastCollectibleId)
        return GetNextCollectiblesUpdatedEventCollectibleId(lastCollectibleId)
    end

    function ZO_CollectibleDataManager:RefreshCollectionOnlyDirtyCollectibles()
        local numCollectiblesUpdated = GetNumCollectiblesUpdatedEventCollectibleIds()
        for index = 1, numCollectiblesUpdated do
            local collectibleId = GetCollectiblesUpdatedEventCollectibleId(index)
            local collectibleData = self.collectibleIdToDataMap[collectibleId]
            if collectibleData then
                collectibleData:Refresh()
                collectibleData:SetNotificationId(nil)
            else
                local errorString = string.format("EVENT_COLLECTIBLES_UPDATED fired with invalid dirty collectible id (%d)", collectibleId)
                internalassert(false, errorString)
            end
        end

        self:MapNotifications()
    end
end

function ZO_CollectibleDataManager:RebuildCollection()
    ZO_ClearTable(self.collectibleIdToDataMap)
    ZO_ClearTable(self.collectibleCategoryIdToDataMap)

    self.categoryObjectPool:ReleaseAllObjects()

    for categoryIndex = 1, GetNumCollectibleCategories() do
        local categoryData = self.categoryObjectPool:AcquireObject(categoryIndex)
        categoryData:BuildData(categoryIndex)
    end

    self:MapNotifications()

    self:FireCallbacks("OnCollectionUpdated", FULL_COLLECTION_UPDATE)
end

function ZO_CollectibleDataManager:MapNotifications()
    for index = 1, GetNumCollectibleNotifications() do
        local notificationId, collectibleId = GetCollectibleNotificationInfo(index)
        local collectibleData = self.collectibleIdToDataMap[collectibleId]
        if collectibleData then
            collectibleData:SetNotificationId(notificationId)
        else
            local errorString = string.format("GetNumCollectibleNotifications returned a bad collectible id (%d)", collectibleId)
            internalassert(false, errorString)
        end
    end
end

function ZO_CollectibleDataManager:GetCollectibleDataById(collectibleId)
    return self.collectibleIdToDataMap[collectibleId]
end

function ZO_CollectibleDataManager:GetCollectibleDataByIndicies(categoryIndex, subcategoryIndex, collectibleIndex)
    local categoryData = self:GetCategoryDataByIndicies(categoryIndex, subcategoryIndex)
    if categoryData then
        return categoryData:GetCollectibleDataByIndex(collectibleIndex)
    end
    return nil
end

function ZO_CollectibleDataManager:MapCollectibleData(collectibleData)
    self.collectibleIdToDataMap[collectibleData:GetId()] = collectibleData
end

function ZO_CollectibleDataManager:GetCategoryDataById(categoryId)
    return self.collectibleCategoryIdToDataMap[categoryId]
end

function ZO_CollectibleDataManager:MapCategoryData(categoryData)
    self.collectibleCategoryIdToDataMap[categoryData:GetId()] = categoryData
end

function ZO_CollectibleDataManager:GetCategoryDataByIndicies(categoryIndex, subcategoryIndex)
    local categoryData = self.categoryObjectPool:GetExistingObject(categoryIndex)
    if categoryData and subcategoryIndex then
        return categoryData:GetSubcategoryData(subcategoryIndex)
    end
    return categoryData
end

function ZO_CollectibleDataManager:GetNumCategories()
    return self.categoryObjectPool:GetActiveObjectCount()
end


function ZO_CollectibleDataManager:CategoryIterator(categoryFilterFunctions)
    local index = 0
    local count = self.categoryObjectPool:GetActiveObjectCount()
    local numFilters = categoryFilterFunctions and #categoryFilterFunctions or 0
    return function()
        index = index + 1
        while index <= count do
            local passesFilter = true
            local categoryData = self.categoryObjectPool:GetExistingObject(index)
            for filterIndex = 1, numFilters do
                if not categoryFilterFunctions[filterIndex](categoryData) then
                    passesFilter = false
                    break
                end
            end

            if passesFilter then
                return index, categoryData
            else
                index = index + 1
            end
        end
    end
end

function ZO_CollectibleDataManager:GetAllCollectibleDataObjects(categoryFilterFunctions, collectibleFilterFunctions, sorted)
    local foundCollectibleDataObjects = {}
    for categoryIndex, categoryData in self:CategoryIterator(categoryFilterFunctions) do
        categoryData:AppendAllCollectibleDataObjects(foundCollectibleDataObjects, collectibleFilterFunctions, sorted)
    end
    return foundCollectibleDataObjects
end

function ZO_CollectibleDataManager:HasAnyNewCollectibles()
    for categoryIndex, categoryData in self:CategoryIterator() do
        if categoryData:HasAnyNewCollectibles() then
            return true
        end
    end
    return false
end

function ZO_CollectibleDataManager:HasAnyUnlockedCollectibles()
    for categoryIndex, categoryData in self:CategoryIterator() do
        if categoryData:HasAnyUnlockedCollectibles() then
            return true
        end
    end
    return false
end

ZO_CollectibleDataManager:New()