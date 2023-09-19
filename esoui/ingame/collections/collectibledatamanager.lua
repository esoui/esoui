ZO_COLLECTIBLE_DATA_FILTERS = 
{
    INCLUDE_LOCKED = true,
    EXCLUDE_LOCKED = false,
    INCLUDE_INVALID_FOR_PLAYER = true,
    EXCLUDE_INVALID_FOR_PLAYER = false,
}

ZO_COLLECTION_UPDATE_TYPE =
{
    REBUILD = 1,
    FORCE_REINITIALIZE = 2,
    UNLOCK_STATE_CHANGED = 3,
    BLACKLIST_CHANGED = 4,
    USER_FLAGS_CHANGED = 5,
    RANDOM_MOUNT_SETTING_CHANGED = 6,
}

----------------------------------
-- Set Default Collectible Data --
----------------------------------

ZO_SetToDefaultCollectibleData = ZO_InitializingObject:Subclass()

function ZO_SetToDefaultCollectibleData:Initialize(categoryTypeToSetDefault)
    self.categoryTypeToSetDefault = categoryTypeToSetDefault
end

function ZO_SetToDefaultCollectibleData:GetCategoryTypeToSetDefault()
    return self.categoryTypeToSetDefault
end

function ZO_SetToDefaultCollectibleData:GetCategoryType()
    return self:GetCategoryTypeToSetDefault()
end

function ZO_SetToDefaultCollectibleData:GetName()
    return ZO_CachedStrFormat(SI_SET_DEFAULT_COLLECTIBLE_NAME_FORMAT, GetString("SI_COLLECTIBLECATEGORYTYPE", self:GetCategoryTypeToSetDefault()))
end

do
    local DESCRIPTION_FORMATTERS =
    {
        [GAMEPLAY_ACTOR_CATEGORY_COMPANION] = SI_COMPANION_SET_DEFAULT_COLLECTIBLE_DESCRIPTION_FORMAT,
    }

    function ZO_SetToDefaultCollectibleData:GetDescription(actorCategory)
        local descriptionFormatter = DESCRIPTION_FORMATTERS[actorCategory]
        if descriptionFormatter then
            return ZO_CachedStrFormat(descriptionFormatter, GetString("SI_COLLECTIBLECATEGORYTYPE", self:GetCategoryTypeToSetDefault()))
        end
        return nil
    end
end

do
    local COLLECTIBLE_CATEGORY_TYPE_DEFAULT_ICONS =
    {
        [COLLECTIBLE_CATEGORY_TYPE_MOUNT] = "EsoUI/Art/Collections/Default/collections_default_mount.dds",
    }

    function ZO_SetToDefaultCollectibleData:GetIcon()
        return COLLECTIBLE_CATEGORY_TYPE_DEFAULT_ICONS[self.categoryTypeToSetDefault]
    end
end

function ZO_SetToDefaultCollectibleData:IsActive(actorCategory)
    return IsCollectibleCategoryTypeSetToDefault(self.categoryTypeToSetDefault, actorCategory)
end

function ZO_SetToDefaultCollectibleData:IsLocked()
    return false
end

function ZO_SetToDefaultCollectibleData:IsBlocked(actorCategory)
    return false
end

function ZO_SetToDefaultCollectibleData:GetBlockReason(actorCategory)
    return ""
end

function ZO_SetToDefaultCollectibleData:IsUsable(actorCategory)
    actorCategory = actorCategory or GAMEPLAY_ACTOR_CATEGORY_PLAYER
    return self:IsActiveStateSuppressed(actorCategory) or not self:IsActive(actorCategory)
end

function ZO_SetToDefaultCollectibleData:Use(actorCategory)
    if self:IsActiveStateSuppressed(actorCategory) then
        -- If default mount is being suppressed, then using it should just clear the suppression (disable random mount)
        if self:GetCategoryType() == COLLECTIBLE_CATEGORY_TYPE_MOUNT then
            SetRandomMountType(RANDOM_MOUNT_TYPE_NONE, actorCategory)
        end
        return
    end

    SetCollectibleCategoryTypeToDefault(self.categoryTypeToSetDefault, actorCategory)
end

function ZO_SetToDefaultCollectibleData:GetPrimaryInteractionStringId(actorCategory)
    -- Function signature mirrors the one on ZO_CollectibleData,
    -- but right now there's no support for anything other than Set Active variants
    return SI_COLLECTIBLE_ACTION_SET_ACTIVE
end

function ZO_SetToDefaultCollectibleData:ShouldSuppressActiveState(actorCategory)
    return GetRandomMountType(actorCategory) ~= RANDOM_MOUNT_TYPE_NONE
end

function ZO_SetToDefaultCollectibleData:IsActiveStateSuppressed(actorCategory)
    if not self:IsActive(actorCategory) then
        return false
    end

    return self:ShouldSuppressActiveState(actorCategory)
end

---------------------------------------
-- Set Random Mount Collectible Data --
---------------------------------------

ZO_RandomMountCollectibleData = ZO_InitializingObject:Subclass()

function ZO_RandomMountCollectibleData:Initialize(randomMountType)
    self.randomMountType = randomMountType
end

function ZO_RandomMountCollectibleData:GetRandomMountType()
    return self.randomMountType
end

function ZO_RandomMountCollectibleData:GetCategoryType()
    return COLLECTIBLE_CATEGORY_TYPE_MOUNT
end

function ZO_RandomMountCollectibleData:GetName()
    return GetString("SI_RANDOMMOUNTTYPE", self.randomMountType)
end

function ZO_RandomMountCollectibleData:GetDescription()
    return GetString("SI_RANDOMMOUNTTYPE_DESCRIPTION", self.randomMountType)
end

do
    local RANDOM_MOUNT_TYPE_ICONS =
    {
        [RANDOM_MOUNT_TYPE_FAVORITE] = "EsoUI/Art/Collections/Random_FavoriteMount.dds",
        [RANDOM_MOUNT_TYPE_ANY] = "EsoUI/Art/Collections/Random_AnyMount.dds",
    }

    function ZO_RandomMountCollectibleData:GetIcon()
        return RANDOM_MOUNT_TYPE_ICONS[self.randomMountType]
    end
end

function ZO_RandomMountCollectibleData:IsActive(actorCategory)
    return GetRandomMountType(actorCategory) == self.randomMountType
end

function ZO_RandomMountCollectibleData:IsLocked()
    return false
end

function ZO_RandomMountCollectibleData:IsBlocked(actorCategory)
    if self.randomMountType == RANDOM_MOUNT_TYPE_FAVORITE and not ZO_COLLECTIBLE_DATA_MANAGER:HasAnyFavoriteMounts() then
        return true
    elseif self.randomMountType == RANDOM_MOUNT_TYPE_ANY and not HasAnyUnlockedCollectiblesAvailableToActorCategoryByCategoryType(COLLECTIBLE_CATEGORY_TYPE_MOUNT, actorCategory) then
        return true
    end

    return false
end

function ZO_RandomMountCollectibleData:GetBlockReason(actorCategory)
    if self.randomMountType == RANDOM_MOUNT_TYPE_FAVORITE and not ZO_COLLECTIBLE_DATA_MANAGER:HasAnyFavoriteMounts() then
        return zo_strformat(SI_COLLECTIBLE_REQUIRES_FAVORITE, GetString("SI_COLLECTIBLECATEGORYTYPE", self:GetCategoryType()))
    elseif self.randomMountType == RANDOM_MOUNT_TYPE_ANY and not  HasAnyUnlockedCollectiblesAvailableToActorCategoryByCategoryType(COLLECTIBLE_CATEGORY_TYPE_MOUNT, actorCategory) then
        return zo_strformat(SI_COLLECTIBLE_REQUIRES_UNLOCKED_COLLECTIBLE, GetString("SI_COLLECTIBLECATEGORYTYPE", self:GetCategoryType()))
    end

    return ""
end

function ZO_RandomMountCollectibleData:IsUsable(actorCategory)
    return not self:IsActive(actorCategory)
end

function ZO_RandomMountCollectibleData:Use(actorCategory)
    if self:IsBlocked(actorCategory) then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.GENERAL_ALERT_ERROR, self:GetBlockReason(actorCategory))
        return
    end

    SetRandomMountType(self.randomMountType, actorCategory)
end

function ZO_RandomMountCollectibleData:GetActiveCollectibleText(actorCategory)
    if actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
        return
    end

    if not IsMounted() then
        return
    end

    local activeMountId = GetActiveCollectibleByType(self:GetCategoryType(), actorCategory)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(activeMountId)
    if collectibleData then
        local activeMountName = collectibleData:GetName()
        return zo_strformat(SI_COLLECTIBLE_ACTIVE_RANDOM_MOUNT_FORMATTER, ZO_SELECTED_TEXT:Colorize(activeMountName))
    end
end

function ZO_RandomMountCollectibleData:GetPrimaryInteractionStringId(actorCategory)
    -- Function signature mirrors the one on ZO_CollectibleData,
    -- but right now there's no support for anything other than Set Active variants
    return SI_COLLECTIBLE_ACTION_SET_ACTIVE
end

function ZO_RandomMountCollectibleData:ShouldSuppressActiveState(actorCategory)
    return false
end

function ZO_RandomMountCollectibleData:IsActiveStateSuppressed(actorCategory)
    if not self:IsActive(actorCategory) then
        return false
    end

    return self:ShouldSuppressActiveState(actorCategory)
end

----------------------
-- Collectible Data --
----------------------

ZO_CollectibleData = ZO_InitializingObject:Subclass()

function ZO_CollectibleData:Reset()
    self.cachedNameWithNickname = nil
end

function ZO_CollectibleData:BuildData(categoryData, collectibleIndex)
    self.categoryData = categoryData
    local categoryIndex, subcategoryIndex = categoryData:GetCategoryIndicies()
    local collectibleId = GetCollectibleId(categoryIndex, subcategoryIndex, collectibleIndex)

    self.collectibleIndex = collectibleIndex
    self.collectibleId = collectibleId
    self.referenceId = GetCollectibleReferenceId(collectibleId)
    self.name = GetCollectibleName(collectibleId)
    -- Speed up sorts by caching
    self.sortOrder = GetCollectibleSortOrder(collectibleId)
    self.gridHeaderName = nil

    self:SetHousingData()
    self:SetOutfitStyleData()

    self:Refresh()
    ZO_COLLECTIBLE_DATA_MANAGER:MapCollectibleData(self)
end

function ZO_CollectibleData:SetHousingData()
    if self:IsHouse() then
        self.isPrimaryResidence = IsPrimaryHouse(self.referenceId) or nil -- Memory optimization
    else
        self.isPrimaryResidence = nil
    end
end

function ZO_CollectibleData:SetOutfitStyleData()
    if self:IsOutfitStyle() then
        self.outfitStyleItemStyleId = GetOutfitStyleItemStyleId(self.referenceId)
        -- Since a lot of oufit style checks look at "if armor else ..." we'll cache isArmorStyle when it's armor as a perf improvement
        -- and not cache isArmorStyle or isWeaponStyle when it's not armor as a memory improvement
        self.isArmorStyle = IsOutfitStyleArmor(self.referenceId) or nil
        if self.isArmorStyle then
            self.gridHeaderName = GetString("SI_VISUALARMORTYPE", self:GetVisualArmorType())
        else
            self.gridHeaderName = GetString("SI_WEAPONMODELTYPE", self:GetWeaponModelType())
        end
    else
        self.outfitStyleItemStyleId = nil
    end
end

function ZO_CollectibleData:Refresh()
    local collectibleId = self.collectibleId
    local previousUnlockState = self.unlockState
    self.unlockState = GetCollectibleUnlockStateById(collectibleId)

    local previousUserFlags = self:GetUserFlags()
    local newUserFlags = GetCollectibleUserFlags(collectibleId)
    self.userFlags = newUserFlags > 0 and newUserFlags or nil

    self:SetNew(IsCollectibleNew(collectibleId))
    self.cachedNameWithNickname = nil

    local unlockStateChanged = previousUnlockState ~= self.unlockState
    local userFlagsChanged = previousUserFlags ~= newUserFlags
    if unlockStateChanged or userFlagsChanged then
        local categoryData = self:GetCategoryData()
        if categoryData then
            local specializedSortedCollectibles = categoryData:GetSpecializedSortedCollectiblesObject()
            if unlockStateChanged then
                specializedSortedCollectibles:HandleLockStatusChanged(self)
            elseif userFlagsChanged then
                specializedSortedCollectibles:HandleUserFlagsChanged(self)
            end
        end
    end
end

function ZO_CollectibleData:RefreshHousingData()
    if self:IsHouse() then
        local wasPrimaryResidence = self.isPrimaryResidence
        self.isPrimaryResidence = IsPrimaryHouse(self.referenceId) or nil -- Memory optimization

        if wasPrimaryResidence ~= self.isPrimaryResidence then
            local categoryData = self:GetCategoryData()
            if categoryData then
                local specializedSortedCollectibles = categoryData:GetSpecializedSortedCollectiblesObject()
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
    return ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, self:GetName())
end

function ZO_CollectibleData:GetNameWithNickname()
    if not self.cachedNameWithNickname then
        local nickname = self:GetNickname()
        if nickname and nickname ~= "" then
            self.cachedNameWithNickname = zo_strformat(SI_COLLECTIBLE_NAME_WITH_NICKNAME_FORMATTER, self:GetName(), nickname)
        else
            self.cachedNameWithNickname = self:GetFormattedName()
        end
    end

    return self.cachedNameWithNickname
end

function ZO_CollectibleData:GetRawNameWithNickname()
    local nickname = self:GetNickname()
    if nickname and nickname ~= "" then
        return zo_strformat(SI_COLLECTIBLE_NAME_WITH_NICKNAME_RAW, self:GetName(), nickname)
    else
        return self:GetName()
    end
end

function ZO_CollectibleData:GetDescription()
    return GetCollectibleDescription(self.collectibleId)
end

function ZO_CollectibleData:GetIcon()
    return GetCollectibleIcon(self.collectibleId)
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
    return IsCollectiblePurchasable(self.collectibleId)
end

function ZO_CollectibleData:CanAcquire()
    return CanAcquireCollectibleByDefId(self.collectibleId)
end

function ZO_CollectibleData:IsActive(actorCategory)
    actorCategory = actorCategory or GAMEPLAY_ACTOR_CATEGORY_PLAYER
    return IsCollectibleActive(self.collectibleId, actorCategory)
end

function ZO_CollectibleData:IsBlacklisted()
    return IsCollectibleBlacklisted(self.collectibleId)
end

function ZO_CollectibleData:IsFavorite()
    return self:IsUserFlagSet(COLLECTIBLE_USER_FLAG_FAVORITE)
end

function ZO_CollectibleData:IsFavoritable()
    return self:IsUnlocked() and IsCollectibleCategoryFavoritable(self:GetCategoryType())
end

function ZO_CollectibleData:IsUserFlagSet(userFlag)
    return ZO_FlagHelpers.MaskHasFlag(self:GetUserFlags(), userFlag)
end

function ZO_CollectibleData:GetUserFlags()
    return self.userFlags or 0
end

function ZO_CollectibleData:GetCategoryType()
    return GetCollectibleCategoryType(self.collectibleId)
end

function ZO_CollectibleData:GetSpecializedCategoryType()
    return GetSpecializedCollectibleType(self.collectibleId)
end

function ZO_CollectibleData:GetCategoryTypeDisplayName()
    local specializedCollectibleType = self:GetSpecializedCategoryType()
    if specializedCollectibleType == SPECIALIZED_COLLECTIBLE_TYPE_NONE then
        return GetString("SI_COLLECTIBLECATEGORYTYPE", self:GetCategoryType())
    else
        return GetString("SI_SPECIALIZEDCOLLECTIBLETYPE", specializedCollectibleType)
    end
end

function ZO_CollectibleData:IsCategoryType(categoryType)
    return self:GetCategoryType() == categoryType
end

function ZO_CollectibleData:GetCollectibleAssociatedQuestState()
    return GetCollectibleAssociatedQuestState(self.collectibleId)
end

do
    local DEFAULT_HOUSE_HINT = GetString(SI_HOUSING_BOOK_AVAILABLE_FOR_PURCHASE)

    function ZO_CollectibleData:GetHint()
        local hint = GetCollectibleHint(self.collectibleId)
        if hint == "" and self:IsHouse() then
            hint = DEFAULT_HOUSE_HINT
        end
        return hint
    end
end

function ZO_CollectibleData:GetKeyboardBackgroundImage()
    return GetCollectibleKeyboardBackgroundImage(self.collectibleId)
end

function ZO_CollectibleData:GetGamepadBackgroundImage()
    return GetCollectibleGamepadBackgroundImage(self.collectibleId)
end

function ZO_CollectibleData:GetNickname()
    return GetCollectibleNickname(self.collectibleId)
end

function ZO_CollectibleData:GetDefaultNickname()
    return GetCollectibleDefaultNickname(self.collectibleId)
end

function ZO_CollectibleData:GetFormattedNickname()
    local nickname = self:GetNickname()
    if nickname ~= "" then
        return ZO_CachedStrFormat(SI_TOOLTIP_COLLECTIBLE_NICKNAME, nickname)
    else
        return ""
    end
end

function ZO_CollectibleData:IsRenameable()
    return IsCollectibleRenameable(self.collectibleId)
end

function ZO_CollectibleData:IsSlottable()
    return IsCollectibleSlottable(self.collectibleId)
end

function ZO_CollectibleData:IsNew()
    return self.isNew
end

function ZO_CollectibleData:SetNew(isNew)
    if isNew == false then
        isNew = nil -- Memory optimization
    end
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
    local categoryType = self:GetCategoryType()
    return categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC or categoryType == COLLECTIBLE_CATEGORY_TYPE_CHAPTER
end

function ZO_CollectibleData:IsUnlockedViaSubscription()
    return DoesESOPlusUnlockCollectible(self.collectibleId)
end

function ZO_CollectibleData:GetQuestName()
    local questName = GetCollectibleQuestPreviewInfo(self.collectibleId)
    return questName
end

function ZO_CollectibleData:GetQuestDescription()
    local questDescription = select(2, GetCollectibleQuestPreviewInfo(self.collectibleId))
    return questDescription
end

function ZO_CollectibleData:IsHouse()
    return self:GetCategoryType() == COLLECTIBLE_CATEGORY_TYPE_HOUSE
end

function ZO_CollectibleData:GetHouseLocation()
    local houseFoundInZoneId = GetHouseFoundInZoneId(self.referenceId)
    return GetZoneNameById(houseFoundInZoneId)
end

function ZO_CollectibleData:GetFormattedHouseLocation()
    return ZO_CachedStrFormat(SI_ZONE_NAME, self:GetHouseLocation())
end

function ZO_CollectibleData:GetHouseCategoryType()
    return GetHouseCategoryType(self.referenceId)
end

function ZO_CollectibleData:IsPrimaryResidence()
    return self.isPrimaryResidence or false -- Memory optimization
end

function ZO_CollectibleData:IsOutfitStyle()
    return self:GetCategoryType() == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE
end

function ZO_CollectibleData:IsArmorStyle()
    return self.isArmorStyle or false -- Memory/perf optimization, see ZO_CollectibleData:SetOutfitStyleData for details
end

function ZO_CollectibleData:IsWeaponStyle()
    return IsOutfitStyleWeapon(self.referenceId)
end

function ZO_CollectibleData:GetVisualArmorType()
    return self:IsArmorStyle() and GetOutfitStyleVisualArmorType(self.referenceId) or nil
end

function ZO_CollectibleData:GetWeaponModelType()
    return self:IsWeaponStyle() and GetOutfitStyleWeaponModelType(self.referenceId) or nil
end

function ZO_CollectibleData:GetOutfitGearType()
    return self:IsArmorStyle() and self:GetVisualArmorType() or self:GetWeaponModelType()
end

function ZO_CollectibleData:GetOutfitStyleItemStyleId()
    return self.outfitStyleItemStyleId
end

function ZO_CollectibleData:GetOutfitStyleItemStyleName()
    return GetItemStyleName(self:GetOutfitStyleItemStyleId())
end

function ZO_CollectibleData:GetOutfitStyleCost()
    if self:IsOutfitStyle() then
        local outfitStyleCost = GetOutfitStyleCost(self.referenceId)
        if outfitStyleCost ~= 0 then
            local outfitStyleFreeConversionCollectible = self:GetOutfitStyleFreeConversionCollectible()
            if outfitStyleFreeConversionCollectible then
                local freeConversionCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(outfitStyleFreeConversionCollectible)
                if freeConversionCollectibleData and freeConversionCollectibleData:IsUnlocked() then
                    return 0
                end
            end
        end
        return outfitStyleCost
    end
    return 0 -- No one should ever hit this code
end

function ZO_CollectibleData:GetOutfitStyleFreeConversionCollectible()
    return GetOutfitStyleFreeConversionCollectibleId(self.referenceId)
end

function ZO_CollectibleData:IsBlocked(actorCategory)
    return IsCollectibleBlocked(self.collectibleId)
end

function ZO_CollectibleData:IsCollectibleAvailableToActorCategory(aActorCategory)
    return IsCollectibleAvailableToActorCategory(self.collectibleId, aActorCategory)
end

function ZO_CollectibleData:IsCollectibleAvailableToCompanion()
    return self:IsCollectibleAvailableToActorCategory(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
end

function ZO_CollectibleData:IsCollectibleCategoryUsable(actorCategory)
    return IsCollectibleCategoryUsable(self:GetCategoryType(), actorCategory)
end

function ZO_CollectibleData:IsCollectibleCategoryCompanionUsable()
    return self:IsCollectibleCategoryUsable(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
end

function ZO_CollectibleData:IsUsable(actorCategory)
    actorCategory = actorCategory or GAMEPLAY_ACTOR_CATEGORY_PLAYER
    return self:IsActiveStateSuppressed(actorCategory) or IsCollectibleUsable(self.collectibleId, actorCategory)
end

function ZO_CollectibleData:Use(actorCategory)
    if self:IsActiveStateSuppressed(actorCategory) and self:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_MOUNT) then
        -- If the active mount is being suppressed, then using it should just clear the suppression (disable random mount)
        SetRandomMountType(RANDOM_MOUNT_TYPE_NONE, actorCategory)
        return
    end

    -- combination fragment collectibles can consume collectibles on use
    -- so we want to show a confirmation dialog if it consumes a non-fragment collectible
    if self:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_COMBINATION_FRAGMENT) then
        if not CheckPlayerCanPerformCombinationAndWarn(self.referenceId) then
            return
        end
        -- this combination might be acting as an "evolution" of a collectible into another collectible
        -- like the nascent indrik evolving into another type of indrik
        if GetCombinationNumNonFragmentCollectibleComponents(self.referenceId) > 0 then
            local function AcceptCombinationCallback()
                UseCollectible(self.collectibleId, actorCategory)
            end

            local function DeclineCombinationCallback()
            end

            ZO_CombinationPromptManager_ShowAppropriateCombinationPrompt(self.referenceId, AcceptCombinationCallback, DeclineCombinationCallback)
            return
        end
    end

    UseCollectible(self.collectibleId, actorCategory)
end

function ZO_CollectibleData:GetPrimaryInteractionStringId(actorCategory)
    local categoryType = self:GetCategoryType()
    if self:IsActive(actorCategory) and not self:ShouldSuppressActiveState(actorCategory) then
        if categoryType == COLLECTIBLE_CATEGORY_TYPE_VANITY_PET or categoryType == COLLECTIBLE_CATEGORY_TYPE_ASSISTANT or categoryType == COLLECTIBLE_CATEGORY_TYPE_COMPANION then
            return SI_COLLECTIBLE_ACTION_DISMISS
        else
            return SI_COLLECTIBLE_ACTION_PUT_AWAY
        end
    else
        if categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC or categoryType == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
            return SI_COLLECTIBLE_ACTION_ACCEPT_QUEST
        elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_HOUSE then
            return self:IsUnlocked() and SI_HOUSING_BOOK_ACTION_TRAVEL_TO_HOUSE or SI_HOUSING_BOOK_ACTION_PREVIEW_HOUSE
        elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_MEMENTO then
            return SI_COLLECTIBLE_ACTION_USE
        elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_COMBINATION_FRAGMENT then
            return SI_COLLECTIBLE_ACTION_COMBINE
        elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_COMPANION then
            local activeState = self:GetCollectibleAssociatedQuestState()
            if activeState == COLLECTIBLE_ASSOCIATED_QUEST_STATE_INACTIVE then
                return SI_COLLECTIBLE_ACTION_ACCEPT_QUEST
            elseif activeState == COLLECTIBLE_ASSOCIATED_QUEST_STATE_ACCEPTED then
                return nil
            else
                return SI_COLLECTIBLE_ACTION_SET_ACTIVE
            end
        else
            return SI_COLLECTIBLE_ACTION_SET_ACTIVE
        end
    end
end

function ZO_CollectibleData:IsPlaceableFurniture()
    return IsCollectibleCategoryPlaceableFurniture(self:GetCategoryType())
end

function ZO_CollectibleData:IsValidForPlayer()
    return IsCollectibleValidForPlayer(self.collectibleId)
end

function ZO_CollectibleData:HasVisualAppearence()
    return DoesCollectibleHaveVisibleAppearance(self.collectibleId)
end

function ZO_CollectibleData:WouldBeHidden(actorCategory)
    return WouldCollectibleBeHidden(self.collectibleId, actorCategory)
end

function ZO_CollectibleData:IsVisualLayerHidden(actorCategory)
    return self:HasVisualAppearence() and self:IsActive(actorCategory) and self:WouldBeHidden(actorCategory)
end

function ZO_CollectibleData:IsVisualLayerShowing(actorCategory)
    return self:HasVisualAppearence() and self:IsActive(actorCategory) and not self:WouldBeHidden(actorCategory)
end

function ZO_CollectibleData:GetNotificationId()
    return self.notificationId
end

function ZO_CollectibleData:SetNotificationId(notificationId)
    self.notificationId = notificationId
end

do
    local IS_HIDDEN_FROM_COLLECTION_MODE =
    {
        [COLLECTIBLE_HIDE_MODE_WHEN_LOCKED] = function(collectibleData) return collectibleData:IsLocked() end,
        [COLLECTIBLE_HIDE_MODE_WHEN_LOCKED_REQUIREMENT] = function(collectibleData) return collectibleData:IsCollectibleDynamicallyHidden() end,
    }

    function ZO_CollectibleData:IsHiddenFromCollection()
        local hideMode = GetCollectibleHideMode(self.collectibleId)
        if hideMode == COLLECTIBLE_HIDE_MODE_NONE then
            return false
        elseif hideMode == COLLECTIBLE_HIDE_MODE_ALWAYS then
            return true
        else
            local modeFunction = IS_HIDDEN_FROM_COLLECTION_MODE[hideMode]
            return modeFunction(self)
        end
    end
end

function ZO_CollectibleData:IsCollectibleDynamicallyHidden()
    return self:IsLocked() and IsCollectibleDynamicallyHidden(self.collectibleId)
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
        local visualArmorType = self:GetVisualArmorType()
        if visualArmorType then
            return ARMOR_VISUAL_TO_SOUND_ID[visualArmorType]
        end

        local weaponModelType = self:GetWeaponModelType()
        if weaponModelType then
            return WEAPON_VISUAL_TO_SOUND_ID[weaponModelType]
        end
    end
end

function ZO_CollectibleData:ShouldSuppressActiveState(actorCategory)
    if self:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_MOUNT) and GetRandomMountType(actorCategory) ~= RANDOM_MOUNT_TYPE_NONE then
        return true
    elseif self:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_COMPANION) and HasSuppressedCompanion() then
        return true
    end
    return false
end

function ZO_CollectibleData:IsActiveStateSuppressed(actorCategory)
    if not self:IsActive(actorCategory) then
        return false
    end

    return self:ShouldSuppressActiveState(actorCategory)
end

-- Determines whether the collectible is a placeable furnishing that can be placed in the current house.
function ZO_CollectibleData:CanPlaceInCurrentHouse()
    return self:IsPlaceableFurniture() and ZO_CanPlaceFurnitureInCurrentHouse() and HousingEditorCanPlaceCollectible(self.collectibleId)
end

-----------------------------------
-- Specialized Sorted Collectibles
-----------------------------------

ZO_SpecializedSortedCollectibles = ZO_InitializingObject:Subclass()

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

function ZO_SpecializedSortedCollectibles:HandleUserFlagsChanged(collectibleData)
    -- By default, do nothing
end

-----------------------------
-- Default Sorted Collectible
-----------------------------

ZO_DefaultSortedCollectibles = ZO_SpecializedSortedCollectibles:Subclass()

function ZO_DefaultSortedCollectibles:Initialize(owner)
    ZO_SpecializedSortedCollectibles.Initialize(self)
    self.owner = owner

    self.collectibleNameLookupTable = {}
end

function ZO_DefaultSortedCollectibles:InsertCollectible(collectibleData)
    table.insert(self.sortedCollectibles, collectibleData)
    
    local collectibleId = collectibleData:GetId()
    if not self.collectibleNameLookupTable[collectibleId] then
        -- This will be replaced with a number when the sort is concluded
        self.collectibleNameLookupTable[collectibleId] = collectibleData
    end

    self.dirty = true
end

function ZO_DefaultSortedCollectibles:HandleLockStatusChanged(collectibleData)
    self.dirty = true
end

function ZO_DefaultSortedCollectibles:HandleUserFlagsChanged()
    self.dirty = true
end

function ZO_DefaultSortedCollectibles:RefreshSort()
    if self.dirty then
        local collectibleNameLookupTable = self.collectibleNameLookupTable
        table.sort(self.sortedCollectibles, function(left, right) 
            local leftIsFavorite = left:IsFavorite()
            local rightIsFavorite = right:IsFavorite()
            if leftIsFavorite ~= rightIsFavorite then
                return leftIsFavorite
            end

            local leftIsUnlocked = left:IsUnlocked()
            local rightIsUnlocked = right:IsUnlocked()
            if leftIsUnlocked ~= rightIsUnlocked then
                return leftIsUnlocked
            end

            local leftSortOrder = left:GetSortOrder()
            local rightSortOrder = right:GetSortOrder()
            if leftSortOrder ~= rightSortOrder then
                return leftSortOrder < rightSortOrder
            end
            
            local leftIsValidForPlayer = left:IsValidForPlayer()
            local rightIsValidForPlayer = right:IsValidForPlayer()
            if leftIsValidForPlayer ~= rightIsValidForPlayer then
                return leftIsValidForPlayer
            else
                return collectibleNameLookupTable[left:GetId()] < collectibleNameLookupTable[right:GetId()]
            end
        end)
    end

    self.dirty = false
end

function ZO_DefaultSortedCollectibles:OnInsertFinished()
    local tempTable = {}
    for _, collectibleData in pairs(self.collectibleNameLookupTable) do
        table.insert(tempTable, collectibleData)
    end

    table.sort(tempTable, function(left, right)
        return left.name < right.name
    end)
    
    -- We know that we start with a mapping of id to data and end with a mapping of id to position
    -- So since these mappings have 1 to 1 keys, rather than wasting the old table and creating a new table,
    -- we can just replace everything as another minor optimization
    for position, collectibleData in ipairs(tempTable) do
        self.collectibleNameLookupTable[collectibleData:GetId()] = position
    end
end

-------------------------------------------------------
-- Specialized Sorted Collectibles Outfit Style Types
-------------------------------------------------------

ZO_SpecializedSortedOutfitStyleTypes = ZO_SpecializedSortedCollectibles:Subclass()

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
            -- Cache this off here instead of just storing the collectibleData
            -- so we don't have to fetch the name repeatedly in the sort function
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
    if type then
        local sortedCollectibles = self.sortedCollectibles[type]
        if sortedCollectibles then
            sortedCollectibles:HandleLockStatusChanged(collectibleData)
            self.dirty = true
        end
    end
end

function ZO_SpecializedSortedOutfitStyleTypes:RefreshSort()
    if self.dirty then
        for _, collectibleDataForType in pairs(self.sortedCollectibles) do
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

    for _, collectibleDataForType in pairs(self.sortedCollectibles) do
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

function ZO_SpecializedSortedOutfitStyles:RefreshSort()
    if self.dirty then
        local itemStyleNameLookupTable = self.owner.itemStyleNameLookupTable
        local collectibleNameLookupTable = self.collectibleNameLookupTable
        table.sort(self.sortedCollectibles, function(left, right) 
            local leftIsUnlocked = left:IsUnlocked()
            local rightIsUnlocked = right:IsUnlocked()
            if leftIsUnlocked ~= rightIsUnlocked then
                return leftIsUnlocked
            end

            local leftOutfitStyleItemStyleId = left:GetOutfitStyleItemStyleId()
            local rightOutfitStyleItemStyleId = right:GetOutfitStyleItemStyleId()
            if leftOutfitStyleItemStyleId ~= rightOutfitStyleItemStyleId then
                return itemStyleNameLookupTable[leftOutfitStyleItemStyleId] < itemStyleNameLookupTable[rightOutfitStyleItemStyleId]
            end

            local leftSortOrder = left:GetSortOrder()
            local rightSortOrder = right:GetSortOrder()
            if leftSortOrder ~= rightSortOrder then
                return leftSortOrder < rightSortOrder
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

function ZO_SpecializedSortedHouses:HandlePrimaryResidenceChanged(collectibleData)
    self.dirty = true
end

function ZO_SpecializedSortedHouses:RefreshSort()
    if self.dirty then
        local collectibleNameLookupTable = self.collectibleNameLookupTable
        table.sort(self.sortedCollectibles, function(left, right)
            local leftIsPrimaryResidence = left:IsPrimaryResidence()
            local rightIsPrimaryResidence = right:IsPrimaryResidence()
            if leftIsPrimaryResidence ~= rightIsPrimaryResidence then
                return leftIsPrimaryResidence
            end

            local leftIsFavorite = left:IsFavorite()
            local rightIsFavorite = right:IsFavorite()
            if leftIsFavorite ~= rightIsFavorite then
                return leftIsFavorite
            end

            local leftIsUnlocked = left:IsUnlocked()
            local rightIsUnlocked = right:IsUnlocked()
            if leftIsUnlocked ~= rightIsUnlocked then
                return leftIsUnlocked
            end

            local leftSortOrder = left:GetSortOrder()
            local rightSortOrder = right:GetSortOrder()
            if leftSortOrder ~= rightSortOrder then
                return leftSortOrder < rightSortOrder
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

function ZO_SpecializedSortedStories:HandleLockStatusChanged(collectibleData)
    -- Do nothing, stories don't re-sort, their order is based on release date
end

function ZO_SpecializedSortedStories:RefreshSort()
    if self.dirty then
        local collectibleNameLookupTable = self.collectibleNameLookupTable
        table.sort(self.sortedCollectibles, function(left, right)
            local leftSortOrder = left:GetSortOrder()
            local rightSortOrder = right:GetSortOrder()
            if leftSortOrder ~= rightSortOrder then
                return leftSortOrder < rightSortOrder
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

ZO_CollectibleCategoryData = ZO_InitializingObject:Subclass()

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

function ZO_CollectibleCategoryData:IsTributePatronCategory()
    return self.categorySpecialization == COLLECTIBLE_CATEGORY_SPECIALIZATION_TRIBUTE_PATRONS
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

    if self.isTopLevelCategory then
        local numSubcategories = GetNumSubcategoriesInCollectibleCategory(categoryIndex)
        for loopSubcategoryIndex = 1, numSubcategories do
            local subcategoryData = self.subcategoryObjectPool:AcquireObject()
            subcategoryData:BuildData(categoryIndex, loopSubcategoryIndex)
            table.insert(self.orderedSubcategories, subcategoryData)
        end
    else
        self.numSubcategories = 0
    end

    self.categorySpecialization = GetCollectibleCategorySpecialization(categoryIndex)
    self.specializedSortedCollectibles = self:CreateSpecializedSortedCollectiblesTable()

    local numCollectibles = GetNumCollectiblesInCollectibleCategory(categoryIndex, subcategoryIndex)
    for collectibleIndex = 1, numCollectibles do
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
    return GetCollectibleCategoryNameByCategoryId(self.categoryId)
end

function ZO_CollectibleCategoryData:GetFormattedName()
    return ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, self:GetName())
end

function ZO_CollectibleCategoryData:GetKeyboardIcons()
    return GetCollectibleCategoryKeyboardIcons(self.categoryIndex, self.subcategoryIndex)
end

function ZO_CollectibleCategoryData:GetGamepadIcon()
    return GetCollectibleCategoryGamepadIcon(self.categoryIndex, self.subcategoryIndex)
end

function ZO_CollectibleCategoryData:GetNumSubcategories()
    return #self.orderedSubcategories
end

function ZO_CollectibleCategoryData:GetSubcategoryData(subcategoryIndex)
    if self.isTopLevelCategory then
        return self.orderedSubcategories[subcategoryIndex]
    end
    return nil
end

function ZO_CollectibleCategoryData:SubcategoryIterator(subcategoryFilterFunctions) -- ... Are filter functions that take categoryData as a param
    return ZO_FilteredNumericallyIndexedTableIterator(self.orderedSubcategories, subcategoryFilterFunctions)
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
    return ZO_FilteredNumericallyIndexedTableIterator(collectiblesTable, collectibleFilterFunctions)
end

function ZO_CollectibleCategoryData:CollectibleIterator(collectibleFilterFunctions)
    return ZO_FilteredNumericallyIndexedTableIterator(self.orderedCollectibles, collectibleFilterFunctions)
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
        for _, subcategoryData in ipairs(self.orderedSubcategories) do
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
        for _, subcategoryData in ipairs(self.orderedSubcategories) do
            if subcategoryData:HasAnyNewCollectibles() then
                return true
            end
        end
    end

    return false
end

function ZO_CollectibleCategoryData:HasAnyNewCompanionCollectibles()
    if NonContiguousCount(self.newCollectibleIdsCache) > 0 and self:HasAnyCompanionUsableCollectibles() then
        return true
    end

    if self.isTopLevelCategory then
        for _, subcategoryData in ipairs(self.orderedSubcategories) do
            if subcategoryData:HasAnyNewCompanionCollectibles() then
                return true
            end
        end
    end

    return false
end

function ZO_CollectibleCategoryData:HasAnyNewTributePatronCollectibles()
    if NonContiguousCount(self.newCollectibleIdsCache) > 0 and self:IsTributePatronCategory() then
        return true
    end

    if self.isTopLevelCategory then
        for _, subcategoryData in ipairs(self.orderedSubcategories) do
            if subcategoryData:HasAnyNewTributePatronCollectibles() then
                return true
            end
        end
    end

    return false
end

function ZO_CollectibleCategoryData:HasAnyNewNonTributePatronCollectibles()
    if NonContiguousCount(self.newCollectibleIdsCache) > 0 and not self:IsTributePatronCategory() then
        return true
    end

    if self.isTopLevelCategory then
        for _, subcategoryData in ipairs(self.orderedSubcategories) do
            if subcategoryData:HasAnyNewNonTributePatronCollectibles() then
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
    for _, collectibleData in ipairs(self.orderedCollectibles) do
        if collectibleData:IsUnlocked() then
            return true
        end
    end

    if self.isTopLevelCategory then
        for _, subcategoryData in ipairs(self.orderedSubcategories) do
            if subcategoryData:HasAnyUnlockedCollectibles() then
                return true
            end
        end
    end

    return false
end

function ZO_CollectibleCategoryData:HasShownCollectiblesInCollection()
    for _, collectibleData in ipairs(self.orderedCollectibles) do
        if not collectibleData:IsHiddenFromCollection() then
            return true
        end
    end

    if self.isTopLevelCategory then
        for _, subcategoryData in ipairs(self.orderedSubcategories) do
            if subcategoryData:HasShownCollectiblesInCollection() then
                return true
            end
        end
    end

    return false
end

function ZO_CollectibleCategoryData:HasAnyCompanionUsableCollectibles()
    for _, collectibleData in ipairs(self.orderedCollectibles) do
        if collectibleData:IsCollectibleCategoryCompanionUsable() and collectibleData:IsCollectibleAvailableToCompanion() then
            return true
        end
    end

    if self.isTopLevelCategory then
        for _, subcategoryData in ipairs(self.orderedSubcategories) do
            if subcategoryData:HasAnyCompanionUsableCollectibles() then
                return true
            end
        end
    end

    return false
end

function ZO_CollectibleCategoryData:GetCollectibleCategoryTypesInCategory()
    if not self.collectibleCategoryTypesInCategory then
        local collectibleCategoryTypesInCategory = {}
        for _, collectibleData in self:CollectibleIterator() do
            collectibleCategoryTypesInCategory[collectibleData:GetCategoryType()] = true
        end

        if self.isTopLevelCategory then
            for _, subcategoryData in self:SubcategoryIterator() do
                local collectibleCategoryTypesInSubcategory = subcategoryData:GetCollectibleCategoryTypesInCategory()
                for categoryType in pairs(collectibleCategoryTypesInSubcategory) do
                    collectibleCategoryTypesInCategory[categoryType] = true
                end
            end
        end

        self.collectibleCategoryTypesInCategory = collectibleCategoryTypesInCategory
    end

    return self.collectibleCategoryTypesInCategory
end

------------------
-- Data Manager --
------------------

ZO_CollectibleDataManager = ZO_InitializingCallbackObject:Subclass()

function ZO_CollectibleDataManager:Initialize()
    self.collectibleIdToDataMap = {}
    self.collectibleCategoryIdToDataMap = {}
    self.collectibleCategoryTypeToSetToDefaultCollectibleDataMap = {}

    ZO_COLLECTIBLE_DATA_MANAGER = self

    local function CreateCategoryData()
        return ZO_CollectibleCategoryData:New(self.collectibleObjectPool, self.subcategoryObjectPool)
    end

    local function CreateSubcategoryData()
        return ZO_CollectibleCategoryData:New(self.collectibleObjectPool)
    end

    self.categoryObjectPool = ZO_ObjectPool:New(CreateCategoryData, ZO_ObjectPool_DefaultResetObject)
    self.subcategoryObjectPool = ZO_ObjectPool:New(CreateSubcategoryData, ZO_ObjectPool_DefaultResetObject)
    self.collectibleObjectPool = ZO_ObjectPool:New(ZO_CollectibleData, ZO_ObjectPool_DefaultResetObject)

    --[[
        EVENT_COLLECTIBLE_UPDATED fires when a nickname changes or a collectible is set as active/inactive. It does not encompass unlock state changes.
        EVENT_COLLECTION_UPDATED happens on init or when a command forces all collectibles to lock/unlock (re-init). Those cases don't use dirty unlock mappings from C, so we do that delta work here while we refresh everything.
        EVENT_ESO_PLUS_FREE_TRIAL_STATUS_CHANGED can happen at any time, and is an event that tells us to re-evaluate unlock status for everything because anything could be based on that. Like with EVENT_COLLECTION_UPDATED, we handle the delta here, not in C.
        EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED happens when the client maps out dirty unlock states (collectibles go on trial or ownership changes like crown store or rewards). We consume the dirty mapping from C and broadcast it out.
        EVENT_COLLECTIBLE_BLACKLIST_UPDATED happens when the client maps out dirty blacklist states. We consume the dirty mapping from C and broadcast it out.
        The later 4 all fire the same callback ("OnCollectionUpdated") to all systems registering with the callback manager with info to help determine what happened: collectionUpdateType (ZO_COLLECTION_UPDATE_TYPE), collectiblesByNewUnlockState
    --]]

    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTIBLE_UPDATED, function(_, ...) self:OnCollectibleUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTION_UPDATED, function(_, ...) self:OnCollectionUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_ESO_PLUS_FREE_TRIAL_STATUS_CHANGED, function(_, ...) self:OnESOPlusFreeTrialStatusChanged(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED, function(_, ...) self:OnCollectiblesUnlockStateChanged(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTIBLE_BLACKLIST_UPDATED, function(_, ...) self:OnCollectibleBlacklistUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTIBLE_USER_FLAGS_UPDATED, function(_, ...) self:OnCollectibleUserFlagsUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTIBLE_NEW_STATUS_CLEARED, function(_, ...) self:OnCollectibleNewStatusCleared(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTIBLE_CATEGORY_NEW_STATUS_CLEARED, function(_, ...) self:OnCollectibleCategoryNewStatusCleared(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTIBLE_NOTIFICATION_NEW, function(_, ...) self:OnCollectibleNotificationNew(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_COLLECTIBLE_NOTIFICATION_REMOVED, function(_, ...) self:OnCollectibleNotificationRemoved(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_HOUSING_PRIMARY_RESIDENCE_SET, function(_, ...) self:OnPrimaryResidenceSet(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_RANDOM_MOUNT_SETTING_CHANGED, function(_, ...) self:RandomMountSettingUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectibleDataManager", EVENT_PLAYER_ACTIVATED, function(_, ...) self:OnPlayerActivated(...) end)

    self:RebuildCollection()
end

function ZO_CollectibleDataManager:OnCollectibleUpdated(collectibleId)
    local collectibleData = self:GetCollectibleDataById(collectibleId)
    if collectibleData then
        collectibleData:Refresh()
        self:FireCallbacks("OnCollectibleUpdated", collectibleId)
    else
        local errorString = string.format("EVENT_COLLECTIBLE_UPDATED fired with invalid collectible id (%d)", collectibleId)
        internalassert(false, errorString)
    end
end

-- Begin Collection Update Functions --

function ZO_CollectibleDataManager:MarkCollectionDirty()
    self.isCollectionDirty = true
end

function ZO_CollectibleDataManager:CleanCollection()
    if self.isCollectionDirty then
        self:RebuildCollection()
    end
end

function ZO_CollectibleDataManager:RebuildCollection()
    self.isCollectionDirty = false

    ZO_ClearTable(self.collectibleIdToDataMap)
    ZO_ClearTable(self.collectibleCategoryIdToDataMap)

    self.categoryObjectPool:ReleaseAllObjects()

    for categoryIndex = 1, GetNumCollectibleCategories() do
        local categoryData = self.categoryObjectPool:AcquireObject(categoryIndex)
        categoryData:BuildData(categoryIndex)
    end

    -- No state to track changes for
    local collectiblesByNewUnlockState = {}
    self:FinalizeCollectionUpdates(ZO_COLLECTION_UPDATE_TYPE.REBUILD, collectiblesByNewUnlockState)
end

do
    local function ProcessCollectibleDataForUnlockStateChange(collectibleData, collectiblesByUnlockState)
        local oldUnlockState = collectibleData:GetUnlockState()

        collectibleData:Refresh()
        collectibleData:SetNotificationId(nil)

        local newUnlockState = collectibleData:GetUnlockState()
        if oldUnlockState ~= newUnlockState then
            local unlockStateTable = collectiblesByUnlockState[newUnlockState]
            if not unlockStateTable then
                unlockStateTable = {}
                collectiblesByUnlockState[newUnlockState] = unlockStateTable
            end
            table.insert(unlockStateTable, collectibleData)
        end
    end

    function ZO_CollectibleDataManager:OnCollectionUpdated()
        local collectiblesByNewUnlockState = {}

        for _, collectibleData in self:CollectibleIterator() do
            ProcessCollectibleDataForUnlockStateChange(collectibleData, collectiblesByNewUnlockState)
        end

        self:FinalizeCollectionUpdates(ZO_COLLECTION_UPDATE_TYPE.FORCE_REINITIALIZE, collectiblesByNewUnlockState)
    end

    function ZO_CollectibleDataManager:OnESOPlusFreeTrialStatusChanged()
        local collectiblesByNewUnlockState = {}

        for _, collectibleData in self:CollectibleIterator() do
            ProcessCollectibleDataForUnlockStateChange(collectibleData, collectiblesByNewUnlockState)
        end

        self:FinalizeCollectionUpdates(ZO_COLLECTION_UPDATE_TYPE.UNLOCK_STATE_CHANGED, collectiblesByNewUnlockState)
    end

    local function GetNextDirtyUnlockStateCollectibleIdIter(_, lastCollectibleId)
        return GetNextDirtyUnlockStateCollectibleId(lastCollectibleId)
    end

    local function GetNextDirtyBlacklistCollectibleIdIter(_, lastCollectibleId)
        return GetNextDirtyBlacklistCollectibleId(lastCollectibleId)
    end

    function ZO_CollectibleDataManager:OnCollectiblesUnlockStateChanged()
        local collectiblesByNewUnlockState = {}
        for collectibleId in GetNextDirtyUnlockStateCollectibleIdIter do
            local collectibleData = self:GetCollectibleDataById(collectibleId)
            if collectibleData then
                ProcessCollectibleDataForUnlockStateChange(collectibleData, collectiblesByNewUnlockState)
            else
                local errorString = string.format("EVENT_COLLECTIBLES_UPDATED fired with invalid dirty collectible id (%d)", collectibleId)
                internalassert(false, errorString)
            end
        end

        self:FinalizeCollectionUpdates(ZO_COLLECTION_UPDATE_TYPE.UNLOCK_STATE_CHANGED, collectiblesByNewUnlockState)
    end

    function ZO_CollectibleDataManager:OnCollectibleBlacklistUpdated()
        for collectibleId in GetNextDirtyBlacklistCollectibleIdIter do
            local collectibleData = self:GetCollectibleDataById(collectibleId)
            if collectibleData then
                collectibleData:Refresh()
            end
        end

        local collectiblesByNewUnlockState = {}
        self:FinalizeCollectionUpdates(ZO_COLLECTION_UPDATE_TYPE.BLACKLIST_CHANGED, collectiblesByNewUnlockState)
    end
end

-- TODO: Refactor this so that collectiblesByNewUnlockState can hold collectibles for any collectionUpdateType to support different kinds of state changes
function ZO_CollectibleDataManager:FinalizeCollectionUpdates(collectionUpdateType, collectiblesByNewUnlockState)
    local hasUnlockStateChanges = not ZO_IsTableEmpty(collectiblesByNewUnlockState)
    if hasUnlockStateChanges then
        if collectiblesByNewUnlockState[COLLECTIBLE_UNLOCK_STATE_UNLOCKED_OWNED] then
            TriggerTutorial(TUTORIAL_TRIGGER_ACQUIRED_COLLECTIBLE)
        end
    end

    self:ValidateRandomMountSettings()

    if hasUnlockStateChanges or collectionUpdateType ~= ZO_COLLECTION_UPDATE_TYPE.UNLOCK_STATE_CHANGED then
        self:MapNotifications()

        self:FireCallbacks("OnCollectionUpdated", collectionUpdateType, collectiblesByNewUnlockState)
    end
end

-- End Collection Update Functions --

function ZO_CollectibleDataManager:OnCollectibleNewStatusCleared(collectibleId)
    local collectibleData = self:GetCollectibleDataById(collectibleId)
    if collectibleData then
        collectibleData:SetNew(false)
        self:FireCallbacks("OnCollectibleNewStatusCleared", collectibleId)
    else
        local errorString = string.format("EVENT_COLLECTIBLE_NEW_STATUS_CLEARED fired with invalid collectible id (%d)", collectibleId)
        internalassert(false, errorString)
    end
end

function ZO_CollectibleDataManager:OnCollectibleCategoryNewStatusCleared(categoryId)
    local categoryData = self:GetCategoryDataById(categoryId)
    if categoryData then
        for _, collectibleData in categoryData:CollectibleIterator({ ZO_CollectibleData.IsNew }) do
            collectibleData:SetNew(false)
        end
        self:FireCallbacks("OnCollectibleCategoryNewStatusCleared", categoryId)
    end
end


function ZO_CollectibleDataManager:OnCollectibleNotificationNew(collectibleId, notificationId)
    local collectibleData = self:GetCollectibleDataById(collectibleId)
    if collectibleData then
        collectibleData:SetNotificationId(notificationId)
        self:FireCallbacks("OnCollectibleNotificationNew", notificationId, collectibleId)
    else
        local errorString = string.format("EVENT_COLLECTIBLE_NOTIFICATION_NEW fired with invalid collectible id (%d)", collectibleId)
        internalassert(false, errorString)
    end
end

function ZO_CollectibleDataManager:OnCollectibleNotificationRemoved(notificationId, collectibleId)
    local collectibleData = self:GetCollectibleDataById(collectibleId)
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

function ZO_CollectibleDataManager:OnCollectibleUserFlagsUpdated(collectibleId, oldUserFlags, newUserFlags)
    if oldUserFlags ~= newUserFlags then
        local collectibleData = self:GetCollectibleDataById(collectibleId)
        collectibleData.userFlags = newUserFlags > 0 and newUserFlags or nil -- Memory optimization
        local categoryData = collectibleData:GetCategoryData()
        if categoryData then
            local specializedSortedCollectibles = categoryData:GetSpecializedSortedCollectiblesObject()
            specializedSortedCollectibles:HandleUserFlagsChanged(self)
        end

        self:ValidateRandomMountSettings()

        self:FireCallbacks("OnCollectibleUserFlagsUpdated", collectibleId)
    end
end

function ZO_CollectibleDataManager:RandomMountSettingUpdated()
    local collectiblesByNewUnlockState = {}
    self:FinalizeCollectionUpdates(ZO_COLLECTION_UPDATE_TYPE.RANDOM_MOUNT_SETTING_CHANGED, collectiblesByNewUnlockState)
end

function ZO_CollectibleDataManager:OnPlayerActivated()
    self:ValidateRandomMountSettings()
end

function ZO_CollectibleDataManager:ValidateRandomMountSettings()
    local playerRandomMountType = GetRandomMountType(GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    if playerRandomMountType ~= RANDOM_MOUNT_TYPE_NONE and not self:HasAnyUnlockedMounts() then
        SetRandomMountType(RANDOM_MOUNT_TYPE_NONE, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    elseif playerRandomMountType == RANDOM_MOUNT_TYPE_FAVORITE and not self:HasAnyFavoriteMounts() then
        SetRandomMountType(RANDOM_MOUNT_TYPE_ANY, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    end

    local companionRandomMountType = GetRandomMountType(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
    if companionRandomMountType ~= RANDOM_MOUNT_TYPE_NONE and not self:HasAnyUnlockedCompanionMounts() then
        SetRandomMountType(RANDOM_MOUNT_TYPE_NONE, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
    end
end

function ZO_CollectibleDataManager:MapNotifications()
    for index = 1, GetNumCollectibleNotifications() do
        local notificationId, collectibleId = GetCollectibleNotificationInfo(index)
        local collectibleData = self:GetCollectibleDataById(collectibleId)
        if collectibleData then
            collectibleData:SetNotificationId(notificationId)
        else
            local errorString = string.format("GetNumCollectibleNotifications returned a bad collectible id (%d)", collectibleId)
            internalassert(false, errorString)
        end
    end
end

function ZO_CollectibleDataManager:GetCollectibleDataById(collectibleId)
    self:CleanCollection()
    return self.collectibleIdToDataMap[collectibleId]
end

function ZO_CollectibleDataManager:GetCollectibleDataByIndicies(categoryIndex, subcategoryIndex, collectibleIndex)
    local categoryData = self:GetCategoryDataByIndicies(categoryIndex, subcategoryIndex)
    if categoryData then
        return categoryData:GetCollectibleDataByIndex(collectibleIndex)
    end
    return nil
end

function ZO_CollectibleDataManager:CollectibleIterator(collectibleFilterFunctions)
    self:CleanCollection()
    return ZO_FilteredNonContiguousTableIterator(self.collectibleIdToDataMap, collectibleFilterFunctions)
end

function ZO_CollectibleDataManager:MapCollectibleData(collectibleData)
    self.collectibleIdToDataMap[collectibleData:GetId()] = collectibleData
end

function ZO_CollectibleDataManager:GetCategoryDataById(categoryId)
    self:CleanCollection()
    return self.collectibleCategoryIdToDataMap[categoryId]
end

function ZO_CollectibleDataManager:MapCategoryData(categoryData)
    self.collectibleCategoryIdToDataMap[categoryData:GetId()] = categoryData
end

function ZO_CollectibleDataManager:GetCategoryDataByIndicies(categoryIndex, subcategoryIndex)
    self:CleanCollection()
    local categoryData = self.categoryObjectPool:GetActiveObject(categoryIndex)
    if categoryData and subcategoryIndex then
        return categoryData:GetSubcategoryData(subcategoryIndex)
    end
    return categoryData
end

function ZO_CollectibleDataManager:GetNumCategories()
    self:CleanCollection()
    return self.categoryObjectPool:GetActiveObjectCount()
end

function ZO_CollectibleDataManager:CategoryIterator(categoryFilterFunctions)
    self:CleanCollection()
    -- This only works because we use the categoryObjectPool like a numerically indexed table
    return ZO_FilteredNumericallyIndexedTableIterator(self.categoryObjectPool:GetActiveObjects(), categoryFilterFunctions)
end

function ZO_CollectibleDataManager:GetAllCollectibleDataObjects(categoryFilterFunctions, collectibleFilterFunctions, sorted)
    local foundCollectibleDataObjects = {}
    for _, categoryData in self:CategoryIterator(categoryFilterFunctions) do
        categoryData:AppendAllCollectibleDataObjects(foundCollectibleDataObjects, collectibleFilterFunctions, sorted)
    end
    return foundCollectibleDataObjects
end

function ZO_CollectibleDataManager:HasAnyNewCollectibles()
    for _, categoryData in self:CategoryIterator() do
        if categoryData:HasAnyNewCollectibles() then
            return true
        end
    end
    return false
end

function ZO_CollectibleDataManager:HasAnyNewCompanionCollectibles()
    for _, categoryData in self:CategoryIterator() do
        if categoryData:HasAnyNewCompanionCollectibles() then
            return true
        end
    end
    return false
end

function ZO_CollectibleDataManager:HasAnyNewTributePatronCollectibles()
    for _, categoryData in self:CategoryIterator() do
        if categoryData:HasAnyNewTributePatronCollectibles() then
            return true
        end
    end
    return false
end

function ZO_CollectibleDataManager:HasAnyNewNonTributePatronCollectibles()
    for _, categoryData in self:CategoryIterator() do
        if categoryData:HasAnyNewNonTributePatronCollectibles() then
            return true
        end
    end
    return false
end

function ZO_CollectibleDataManager:HasAnyUnlockedCollectibles()
    for _, categoryData in self:CategoryIterator() do
        if categoryData:HasAnyUnlockedCollectibles() then
            return true
        end
    end
    return false
end

function ZO_CollectibleDataManager:GetSetToDefaultCollectibleData(categoryTypeToSetDefault, actorCategory)
    local setToDefaultCollectibleData = self.collectibleCategoryTypeToSetToDefaultCollectibleDataMap[categoryTypeToSetDefault]
    if not setToDefaultCollectibleData and DoesCollectibleCategoryTypeHaveDefault(categoryTypeToSetDefault, actorCategory) then
        setToDefaultCollectibleData = ZO_SetToDefaultCollectibleData:New(categoryTypeToSetDefault)
        self.collectibleCategoryTypeToSetToDefaultCollectibleDataMap[categoryTypeToSetDefault] = setToDefaultCollectibleData
    end
    return setToDefaultCollectibleData
end

function ZO_CollectibleDataManager:HasAnyUnlockedMounts()
    return HasAnyUnlockedCollectiblesByCategoryType(COLLECTIBLE_CATEGORY_TYPE_MOUNT)
end

function ZO_CollectibleDataManager:HasAnyUnlockedCompanionMounts()
    return HasAnyUnlockedCollectiblesAvailableToActorCategoryByCategoryType(COLLECTIBLE_CATEGORY_TYPE_MOUNT, GAMEPLAY_ACTOR_CATEGORY_COMPANION)
end

function ZO_CollectibleDataManager:HasAnyFavoriteMounts()
    return DoesCollectibleCategoryContainAnyCollectiblesWithUserFlags(COLLECTIBLE_CATEGORY_TYPE_MOUNT, COLLECTIBLE_USER_FLAG_FAVORITE)
end

ZO_CollectibleDataManager:New()