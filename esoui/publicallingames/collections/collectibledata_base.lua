-- ZO_CollectibleData_Base is simply a wrapper around the APIs.
-- It does not care about collectible manager indices and is not necessarily part of the Collectible Data Manager.

ZO_CollectibleData_Base = ZO_PooledObject:Subclass()

function ZO_CollectibleData_Base:SetId(collectibleId)
    self.collectibleId = collectibleId
    self.referenceId = GetCollectibleReferenceId(collectibleId)
end

function ZO_CollectibleData_Base:Reset()
    self.collectibleId = nil
    self.referenceId = nil
    self.cachedNameWithNickname = nil
end

function ZO_CollectibleData_Base:GetId()
    return self.collectibleId
end

function ZO_CollectibleData_Base:GetName()
    return GetCollectibleName(self.collectibleId)
end

function ZO_CollectibleData_Base:GetFormattedName()
    return ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, self:GetName())
end

function ZO_CollectibleData_Base:GetNameWithNickname()
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

function ZO_CollectibleData_Base:GetRawNameWithNickname()
    local nickname = self:GetNickname()
    if nickname and nickname ~= "" then
        return zo_strformat(SI_COLLECTIBLE_NAME_WITH_NICKNAME_RAW, self:GetName(), nickname)
    else
        return self:GetName()
    end
end

function ZO_CollectibleData_Base:GetDescription()
    return GetCollectibleDescription(self.collectibleId)
end

function ZO_CollectibleData_Base:GetIcon()
    return GetCollectibleIcon(self.collectibleId)
end

function ZO_CollectibleData_Base:GetCategoryIndices()
    return GetCategoryInfoFromCollectibleId(self.collectibleId)
end

function ZO_CollectibleData_Base:GetCategoryId()
    local categoryIndex, subcategoryIndex = self:GetCategoryIndices()
    return GetCollectibleCategoryId(categoryIndex, subcategoryIndex)
end

function ZO_CollectibleData_Base:GetCategoryName()
    return GetCollectibleCategoryNameByCategoryId(self:GetCategoryId())
end

function ZO_CollectibleData_Base:GetCategoryFormattedName()
    return ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, self:GetCategoryName())
end

function ZO_CollectibleData_Base:GetCategorySpecialization()
    local categoryIndex = self:GetCategoryIndices()
    return GetCollectibleCategorySpecialization(categoryIndex)
end

function ZO_CollectibleData_Base:GetUnlockState()
    return GetCollectibleUnlockStateById(self.collectibleId)
end

function ZO_CollectibleData_Base:IsUnlocked()
    return IsCollectibleUnlocked(self.collectibleId)
end

function ZO_CollectibleData_Base:IsLocked()
    return not self:IsUnlocked()
end

function ZO_CollectibleData_Base:IsOwned()
    return IsCollectibleOwnedByDefId(self.collectibleId)
end

function ZO_CollectibleData_Base:IsPurchasable()
    -- Will only return true if this collectible is directly purchasable
    return IsCollectiblePurchasable(self.collectibleId)
end

function ZO_CollectibleData_Base:GetPurchasableCollectibleId()
    -- Will either be an override collectible if this collectible can only be purchased by purchasing the other,
    -- or will simply return the id passed if it can be purchased directly
    -- or 0 if it cannot be purchased
    return GetPurchasableCollectibleIdForCollectible(self.collectibleId)
end

function ZO_CollectibleData_Base:CanAcquire()
    return CanAcquireCollectibleByDefId(self.collectibleId)
end

function ZO_CollectibleData_Base:IsActive(actorCategory)
    actorCategory = actorCategory or GAMEPLAY_ACTOR_CATEGORY_PLAYER
    return IsCollectibleActive(self.collectibleId, actorCategory)
end

function ZO_CollectibleData_Base:IsBlacklisted()
    return IsCollectibleBlacklisted(self.collectibleId)
end

function ZO_CollectibleData_Base:IsFavorite()
    return self:IsUserFlagSet(COLLECTIBLE_USER_FLAG_FAVORITE)
end

function ZO_CollectibleData_Base:IsFavoritable()
    return self:IsUnlocked() and IsCollectibleCategoryFavoritable(self:GetCategoryType())
end

function ZO_CollectibleData_Base:IsUserFlagSet(userFlag)
    return ZO_FlagHelpers.MaskHasFlag(self:GetUserFlags(), userFlag)
end

function ZO_CollectibleData_Base:GetUserFlags()
    return GetCollectibleUserFlags(self.collectibleId)
end

function ZO_CollectibleData_Base:GetCategoryType()
    return GetCollectibleCategoryType(self.collectibleId)
end

function ZO_CollectibleData_Base:GetSpecializedCategoryType()
    return GetSpecializedCollectibleType(self.collectibleId)
end

function ZO_CollectibleData_Base:GetCategoryTypeDisplayName()
    local specializedCollectibleType = self:GetSpecializedCategoryType()
    if specializedCollectibleType == SPECIALIZED_COLLECTIBLE_TYPE_NONE then
        return GetString("SI_COLLECTIBLECATEGORYTYPE", self:GetCategoryType())
    else
        return GetString("SI_SPECIALIZEDCOLLECTIBLETYPE", specializedCollectibleType)
    end
end

function ZO_CollectibleData_Base:IsCategoryType(categoryType)
    return self:GetCategoryType() == categoryType
end

function ZO_CollectibleData_Base:GetCollectibleAssociatedQuestState()
    return GetCollectibleAssociatedQuestState(self.collectibleId)
end

do
    local DEFAULT_HOUSE_HINT = GetString(SI_HOUSING_BOOK_AVAILABLE_FOR_PURCHASE)

    function ZO_CollectibleData_Base:GetHint()
        local hint = GetCollectibleHint(self.collectibleId)
        if hint == "" and self:IsHouse() then
            hint = DEFAULT_HOUSE_HINT
        end
        return hint
    end
end

function ZO_CollectibleData_Base:GetKeyboardBackgroundImage()
    return GetCollectibleKeyboardBackgroundImage(self.collectibleId)
end

function ZO_CollectibleData_Base:GetGamepadBackgroundImage()
    return GetCollectibleGamepadBackgroundImage(self.collectibleId)
end

function ZO_CollectibleData_Base:GetNickname()
    return GetCollectibleNickname(self.collectibleId)
end

function ZO_CollectibleData_Base:GetDefaultNickname()
    return GetCollectibleDefaultNickname(self.collectibleId)
end

function ZO_CollectibleData_Base:GetFormattedNickname()
    local nickname = self:GetNickname()
    if nickname ~= "" then
        return ZO_CachedStrFormat(SI_TOOLTIP_COLLECTIBLE_NICKNAME, nickname)
    else
        return ""
    end
end

function ZO_CollectibleData_Base:IsRenameable()
    return IsCollectibleRenameable(self.collectibleId)
end

function ZO_CollectibleData_Base:IsSlottable()
    return IsCollectibleSlottable(self.collectibleId)
end

function ZO_CollectibleData_Base:IsNew()
    return IsCollectibleNew(self.IsSlottable)
end

function ZO_CollectibleData_Base:GetReferenceId()
    return self.referenceId
end

function ZO_CollectibleData_Base:GetSortOrder()
    return GetCollectibleSortOrder(self.collectibleId)
end

function ZO_CollectibleData_Base:IsStory()
    local categoryType = self:GetCategoryType()
    return categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC or categoryType == COLLECTIBLE_CATEGORY_TYPE_CHAPTER
end

function ZO_CollectibleData_Base:IsUnlockedViaSubscription()
    return DoesESOPlusUnlockCollectible(self.collectibleId)
end

function ZO_CollectibleData_Base:GetQuestName()
    local questName = GetCollectibleQuestPreviewInfo(self.collectibleId)
    return questName
end

function ZO_CollectibleData_Base:GetQuestDescription()
    local questDescription = select(2, GetCollectibleQuestPreviewInfo(self.collectibleId))
    return questDescription
end

function ZO_CollectibleData_Base:IsSkillStyle()
    return self:GetCategoryType() == COLLECTIBLE_CATEGORY_TYPE_ABILITY_FX_OVERRIDE
end

function ZO_CollectibleData_Base:GetSkillStyleProgressionId()
    if self:IsSkillStyle() then
        return GetAbilityFxOverrideProgressionId(self.referenceId)
    end
    return 0
end

function ZO_CollectibleData_Base:IsHouse()
    return self:GetCategoryType() == COLLECTIBLE_CATEGORY_TYPE_HOUSE
end

function ZO_CollectibleData_Base:GetHouseLocation()
    if self:IsHouse() then
        local houseFoundInZoneId = GetHouseFoundInZoneId(self.referenceId)
        return GetZoneNameById(houseFoundInZoneId)
    end
    return ""
end

function ZO_CollectibleData_Base:GetFormattedHouseLocation()
    return ZO_CachedStrFormat(SI_ZONE_NAME, self:GetHouseLocation())
end

function ZO_CollectibleData_Base:GetHouseCategoryType()
    if self:IsHouse() then
        return GetHouseCategoryType(self.referenceId)
    end
    return 0
end

function ZO_CollectibleData_Base:IsPrimaryResidence()
    if self:IsHouse() then
        return IsPrimaryHouse(self.referenceId)
    end
    return false
end

function ZO_CollectibleData_Base:GetHouseFlags()
    if self:IsHouse() then
        return GetHouseFlags(self.referenceId)
    end
    return 0
end

function ZO_CollectibleData_Base:IsOutfitStyle()
    return self:GetCategoryType() == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE
end

function ZO_CollectibleData_Base:IsArmorStyle()
    return IsOutfitStyleArmor(self.referenceId)
end

function ZO_CollectibleData_Base:IsWeaponStyle()
    return IsOutfitStyleWeapon(self.referenceId)
end

function ZO_CollectibleData_Base:GetVisualArmorType()
    return self:IsArmorStyle() and GetOutfitStyleVisualArmorType(self.referenceId) or nil
end

function ZO_CollectibleData_Base:GetWeaponModelType()
    return self:IsWeaponStyle() and GetOutfitStyleWeaponModelType(self.referenceId) or nil
end

function ZO_CollectibleData_Base:GetOutfitGearType()
    return self:IsArmorStyle() and self:GetVisualArmorType() or self:GetWeaponModelType()
end

function ZO_CollectibleData_Base:GetOutfitStyleItemStyleId()
    return GetOutfitStyleItemStyleId(self.referenceId)
end

function ZO_CollectibleData_Base:GetOutfitStyleItemStyleName()
    return GetItemStyleName(self:GetOutfitStyleItemStyleId())
end

function ZO_CollectibleData_Base:GetOutfitStyleCost()
    if self:IsOutfitStyle() then
        local outfitStyleCost = GetOutfitStyleCost(self.referenceId)
        if outfitStyleCost ~= 0 then
            local outfitStyleFreeConversionCollectible = self:GetOutfitStyleFreeConversionCollectible()
            if outfitStyleFreeConversionCollectible ~= 0 and IsCollectibleUnlocked(outfitStyleFreeConversionCollectible) then
                return 0
            end
        end
        return outfitStyleCost
    end
    return 0 -- No one should ever hit this code
end

function ZO_CollectibleData_Base:GetOutfitStyleFreeConversionCollectible()
    return GetOutfitStyleFreeConversionCollectibleId(self.referenceId)
end

function ZO_CollectibleData_Base:IsBlocked(actorCategory)
    return IsCollectibleBlocked(self.collectibleId, actorCategory)
end

function ZO_CollectibleData_Base:IsCollectibleAvailableToActorCategory(aActorCategory)
    return IsCollectibleAvailableToActorCategory(self.collectibleId, aActorCategory)
end

function ZO_CollectibleData_Base:IsCollectibleAvailableToCompanion()
    return self:IsCollectibleAvailableToActorCategory(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
end

function ZO_CollectibleData_Base:IsCollectibleCategoryUsable(actorCategory)
    return IsCollectibleCategoryUsable(self:GetCategoryType(), actorCategory)
end

function ZO_CollectibleData_Base:IsCollectibleCategoryCompanionUsable()
    return self:IsCollectibleCategoryUsable(GAMEPLAY_ACTOR_CATEGORY_COMPANION)
end

function ZO_CollectibleData_Base:IsUsable(actorCategory)
    actorCategory = actorCategory or GAMEPLAY_ACTOR_CATEGORY_PLAYER
    return self:IsActiveStateSuppressed(actorCategory) or IsCollectibleUsable(self.collectibleId, actorCategory)
end

function ZO_CollectibleData_Base:Use(actorCategory)
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

function ZO_CollectibleData_Base:GetPrimaryInteractionStringId(actorCategory)
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
        elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_ABILITY_FX_OVERRIDE then
            return nil
        elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_ACCOUNT_UPGRADE then
            local hasQuestBestowal = self.referenceId ~= 0
            return hasQuestBestowal and SI_COLLECTIBLE_ACTION_ACCEPT_QUEST or nil
        else
            return SI_COLLECTIBLE_ACTION_SET_ACTIVE
        end
    end
end

function ZO_CollectibleData_Base:IsPlaceableFurniture()
    return IsCollectibleCategoryPlaceableFurniture(self:GetCategoryType())
end

function ZO_CollectibleData_Base:IsValidForPlayer()
    return IsCollectibleValidForPlayer(self.collectibleId)
end

function ZO_CollectibleData_Base:HasVisualAppearence()
    return DoesCollectibleHaveVisibleAppearance(self.collectibleId)
end

function ZO_CollectibleData_Base:WouldBeHidden(actorCategory)
    return WouldCollectibleBeHidden(self.collectibleId, actorCategory)
end

function ZO_CollectibleData_Base:IsVisualLayerHidden(actorCategory)
    return self:HasVisualAppearence() and self:IsActive(actorCategory) and self:WouldBeHidden(actorCategory)
end

function ZO_CollectibleData_Base:IsVisualLayerShowing(actorCategory)
    return self:HasVisualAppearence() and self:IsActive(actorCategory) and not self:WouldBeHidden(actorCategory)
end

do
    local IS_HIDDEN_FROM_COLLECTION_MODE =
    {
        [COLLECTIBLE_HIDE_MODE_WHEN_LOCKED] = function(collectibleData) return collectibleData:IsLocked() end,
        [COLLECTIBLE_HIDE_MODE_WHEN_LOCKED_REQUIREMENT] = function(collectibleData) return collectibleData:IsCollectibleDynamicallyHidden() end,
    }

    function ZO_CollectibleData_Base:IsHiddenFromCollection()
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

function ZO_CollectibleData_Base:IsCollectibleDynamicallyHidden()
    return self:IsLocked() and IsCollectibleDynamicallyHidden(self.collectibleId)
end

function ZO_CollectibleData_Base:IsShownInCollection()
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

    function ZO_CollectibleData_Base:GetOutfitStyleEquipSound()
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

function ZO_CollectibleData_Base:ShouldSuppressActiveState(actorCategory)
    if self:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_MOUNT) and GetRandomMountType(actorCategory) ~= RANDOM_MOUNT_TYPE_NONE then
        return true
    elseif self:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_COMPANION) and HasSuppressedCompanion() then
        return true
    elseif self:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_ABILITY_FX_OVERRIDE) then
        return true
    end
    return false
end

function ZO_CollectibleData_Base:IsActiveStateSuppressed(actorCategory)
    if not self:IsActive(actorCategory) then
        return false
    end

    return self:ShouldSuppressActiveState(actorCategory)
end

-- Determines whether the collectible is a placeable furnishing that can be placed in the current house.
function ZO_CollectibleData_Base:CanPlaceInCurrentHouse()
    return self:IsPlaceableFurniture() and ZO_CanPlaceFurnitureInCurrentHouse() and HousingEditorCanPlaceCollectible(self.collectibleId)
end

function ZO_CollectibleData_Base:GetLinkedAchievement()
    return GetCollectibleLinkedAchievement(self.collectibleId)
end

function ZO_CollectibleData_Base:GetContentRequiresCollectibleText()
    if self:IsLocked() then
        local categoryType = self:GetCategoryType()
        if categoryType == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
            return zo_strformat(SI_CONTENT_REQUIRES_CHAPTER_FORMATTER, self:GetName())
        elseif categoryType == COLLECTIBLE_CATEGORY_TYPE_DLC then
            return zo_strformat(SI_CONTENT_REQUIRES_DLC_FORMATTER, self:GetName(), self:GetCategoryName())
        else
            return zo_strformat(SI_CONTENT_REQUIRES_NON_ESO_PLUS_COLLECTIBLE_FORMATTER, self:GetName(), self:GetCategoryName())
        end
    end
    return nil
end

-- Pool --

do
    local function CollectibleDataBaseFactory(pool, key)
        local collectibleData = ZO_CollectibleData_Base:New()
        collectibleData:SetPoolAndKey(pool, key)
        return collectibleData
    end

    local function CollectibleDataBaseReset(collectibleData)
        collectibleData:Reset()
    end

    local dataPool = ZO_ObjectPool:New(CollectibleDataBaseFactory, CollectibleDataBaseReset)

    function ZO_CollectibleData_Base.Acquire(collectibleId)
        local collectibleData = dataPool:AcquireObject()
        collectibleData:SetId(collectibleId)
        return collectibleData
    end

    ZO_COLLECTIBLE_DATA_BASE_POOL = dataPool
end