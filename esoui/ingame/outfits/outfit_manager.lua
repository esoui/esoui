ZO_OUTFIT_STYLE_DEFAULT_ITEM_MATERIAL_INDEX = 1

local WEAPON_SLOTS =
{
    [OUTFIT_SLOT_WEAPON_MAIN_HAND] = true,
    [OUTFIT_SLOT_WEAPON_OFF_HAND] = true,
    [OUTFIT_SLOT_WEAPON_TWO_HANDED] = true,
    [OUTFIT_SLOT_WEAPON_STAFF] = true,
    [OUTFIT_SLOT_WEAPON_BOW] = true,
    [OUTFIT_SLOT_SHIELD] = true,
    [OUTFIT_SLOT_WEAPON_MAIN_HAND_BACKUP] = true,
    [OUTFIT_SLOT_WEAPON_OFF_HAND_BACKUP] = true,
    [OUTFIT_SLOT_WEAPON_TWO_HANDED_BACKUP] = true,
    [OUTFIT_SLOT_WEAPON_STAFF_BACKUP] = true,
    [OUTFIT_SLOT_WEAPON_BOW_BACKUP] = true,
    [OUTFIT_SLOT_SHIELD_BACKUP] = true,
}

-----------------------------
-- Outfit Slot Manipulator --
-----------------------------

ZO_OutfitSlotManipulator = ZO_InitializingObject:Subclass()

function ZO_OutfitSlotManipulator:Initialize(owner, outfitSlotIndex)
    self.owner = owner
    self.outfitSlotIndex = outfitSlotIndex

    local restyleMode
    if owner:GetActorCategory() == GAMEPLAY_ACTOR_CATEGORY_PLAYER then
        restyleMode = RESTYLE_MODE_OUTFIT
    elseif owner:GetActorCategory() == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
        restyleMode = RESTYLE_MODE_COMPANION_OUTFIT
    end

    self.restyleSlotData = ZO_RestyleSlotData:New(restyleMode, owner:GetOutfitIndex(), outfitSlotIndex)

    self:RefreshData()
end

function ZO_OutfitSlotManipulator:RefreshData()
    self.currentCollectibleId, self.currentItemMaterialIndex = GetOutfitSlotInfo(self.owner:GetActorCategory(), self.owner:GetOutfitIndex(), self.outfitSlotIndex)
    self.pendingCollectibleId, self.pendingItemMaterialIndex = self.currentCollectibleId, self.currentItemMaterialIndex
end

function ZO_OutfitSlotManipulator:GetCurrentCollectibleId()
    return self.currentCollectibleId
end

function ZO_OutfitSlotManipulator:GetPendingCollectibleId()
    return self.pendingCollectibleId
end

function ZO_OutfitSlotManipulator:SetPendingCollectibleId(collectibleId, suppressCallbacks)
    if collectibleId then
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData and collectibleData:IsBlacklisted() then
            ZO_AlertEvent(EVENT_COLLECTIBLE_USE_RESULT, COLLECTIBLE_USAGE_BLOCK_REASON_BLACKLISTED, true)
            return
        end
    end

    if self.pendingCollectibleId ~= collectibleId then
        self.pendingCollectibleId = collectibleId
        self:OnPendingDataChanged(suppressCallbacks)
    end
end

function ZO_OutfitSlotManipulator:OnCollectibleBlacklistUpdated(suppressCallbacks)
    if self.pendingCollectibleId then
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(self.pendingCollectibleId)
        if collectibleData and collectibleData:IsBlacklisted() then
            ZO_AlertEvent(EVENT_COLLECTIBLE_USE_RESULT, COLLECTIBLE_USAGE_BLOCK_REASON_BLACKLISTED, true)
            self:RefreshData()
            self:OnPendingDataChanged(suppressCallbacks)
            return true
        end
    end
    return false
end

function ZO_OutfitSlotManipulator:GetCurrentItemMaterialIndex()
    return self.currentItemMaterialIndex
end

function ZO_OutfitSlotManipulator:GetPendingItemMaterialIndex()
    return self.pendingItemMaterialIndex
end

function ZO_OutfitSlotManipulator:SetPendingItemMaterialIndex(itemMaterialIndex, suppressCallbacks)
    if self.pendingItemMaterialIndex ~= itemMaterialIndex then
        self.pendingItemMaterialIndex = itemMaterialIndex
        self:OnPendingDataChanged(suppressCallbacks)
    end
end

function ZO_OutfitSlotManipulator:SetPendingCollectibleIdAndItemMaterialIndex(collectibleId, itemMaterialIndex, suppressCallbacks)
    if collectibleId then
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData and collectibleData:IsBlacklisted() then
            ZO_AlertEvent(EVENT_COLLECTIBLE_USE_RESULT, COLLECTIBLE_USAGE_BLOCK_REASON_BLACKLISTED, true)
            return
        end
    end

    if self.pendingCollectibleId ~= collectibleId or self.pendingItemMaterialIndex ~= itemMaterialIndex then
        self.pendingCollectibleId = collectibleId
        self.pendingItemMaterialIndex = itemMaterialIndex
        self:OnPendingDataChanged(suppressCallbacks)
    end
end

function ZO_OutfitSlotManipulator:IsSlotDataChangePending()
    return self.currentCollectibleId ~= self.pendingCollectibleId or self.currentItemMaterialIndex ~= self.pendingItemMaterialIndex
end

function ZO_OutfitSlotManipulator:IsDyeChangePending()
    return self.restyleSlotData and self.restyleSlotData:AreTherePendingDyeChanges()
end

function ZO_OutfitSlotManipulator:GetNumPendingDyeChanges()
    local count = 0
    if self.restyleSlotData then
        local changedChannels = self.restyleSlotData:GetDyeChannelChangedStates()
        for i, hasPendingChange in ipairs(changedChannels) do
            if hasPendingChange then
                count = count + 1
            end
        end
    end
    return count
end

function ZO_OutfitSlotManipulator:IsAnyChangePending()
    return self:IsDyeChangePending() or self:IsSlotDataChangePending()
end

function ZO_OutfitSlotManipulator:CanApplyChanges()
    if not self:IsSlotDataChangePending() then
        return false, GetString("SI_APPLYOUTFITCHANGESRESULT", APPLY_OUTFIT_CHANGES_RESULT_INVALID_DATA)
    end

    if self.pendingCollectibleId ~= 0 then
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(self.pendingCollectibleId)
        if not collectibleData then
            return false, GetString("SI_APPLYOUTFITCHANGESRESULT", APPLY_OUTFIT_CHANGES_RESULT_INVALID_DATA)
        elseif collectibleData:IsLocked() then
            return false, GetString("SI_APPLYOUTFITCHANGESRESULT", APPLY_OUTFIT_CHANGES_RESULT_UNOWNED_COLLECTIBLES)
        end
    end
    return true
end

function ZO_OutfitSlotManipulator:GetOutfitSlotIndex()
    return self.outfitSlotIndex
end

function ZO_OutfitSlotManipulator:GetRestyleSlotData()
    return self.restyleSlotData
end

function ZO_OutfitSlotManipulator:GetPendingDyeData()
    -- Only outfit style types have dye data right now
    if self.restyleSlotData then
        return self.restyleSlotData:GetPendingDyes()
    end
    return 0, 0, 0
end

function ZO_OutfitSlotManipulator:GetAllSlotData()
    return self.currentCollectibleId, self.pendingCollectibleId, self.currentItemMaterialIndex, self.pendingItemMaterialIndex
end

function ZO_OutfitSlotManipulator:GetPendingChangeCost()
    if self:IsAnyChangePending() then
        return GetApplyCostForIndividualOutfitSlot(self.owner:GetActorCategory(), self.owner:GetOutfitIndex(), self.outfitSlotIndex, self.pendingCollectibleId, self:GetNumPendingDyeChanges())
    else
        return 0
    end
end

function ZO_OutfitSlotManipulator:GetSlotAppropriateIcon()
    if self.pendingCollectibleId > 0 then
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(self.pendingCollectibleId)
        return collectibleData:GetIcon()
    elseif self:IsSlotDataChangePending() then
        return ZO_Restyle_GetOutfitSlotClearTexture(self.outfitSlotIndex)
    else
        local actorCategory = self.owner:GetActorCategory()
        local bagId = GetWornBagForGameplayActorCategory(actorCategory)
        local equipSlot = GetEquipSlotForOutfitSlot(self.outfitSlotIndex)
        if CanEquippedItemBeShownInOutfitSlot(actorCategory, equipSlot, self.outfitSlotIndex) then
            local icon = GetItemInfo(bagId, equipSlot)
            return icon
        end
    end

    return ZO_Restyle_GetEmptySlotTexture(self.restyleSlotData)
end

function ZO_OutfitSlotManipulator:GetCollectibleDataAssociations(collectibleData)
    local collectibleId = collectibleData.clearAction and 0 or collectibleData:GetId()
    local isPending = self:IsSlotDataChangePending() and self:GetPendingCollectibleId() == collectibleId
    local isCurrent = self:GetCurrentCollectibleId() == collectibleId

    return isCurrent, isPending
end

function ZO_OutfitSlotManipulator:UpdatePreview(refreshImmediately)
    if self:IsAnyChangePending() then
        local primaryDyeId, secondaryDyeId, accentDyeId = self:GetPendingDyeData()
        AddOutfitSlotPreviewElementToPreviewCollection(self.outfitSlotIndex, self.pendingCollectibleId, self.pendingItemMaterialIndex, primaryDyeId, secondaryDyeId, accentDyeId)
    else
        ClearOutfitSlotPreviewElementFromPreviewCollection(self.outfitSlotIndex)
    end

    if refreshImmediately then
        ApplyChangesToPreviewCollectionShown()
    end
end

function ZO_OutfitSlotManipulator:ClearPendingChanges(suppressCallbacks)
    if self.preservedDyeData then
        self.preservedDyeData = nil
    end

    if self:IsSlotDataChangePending() then
        self.pendingCollectibleId, self.pendingItemMaterialIndex = self.currentCollectibleId, self.currentItemMaterialIndex
        self:OnPendingDataChanged(suppressCallbacks)
        return true
    end

    return false
end

function ZO_OutfitSlotManipulator:RandomizeSlotData(suppressCallbacks)
    local categoryData = self.restyleSlotData:GetCollectibleCategoryData()
    if categoryData then
        local outfitSlot = self.outfitSlotIndex
        -- Will technically work with non-style collectibles, but not completely, since that's in un-designed feature as of yet.  So assume we're only working with styles
        local isArmorSlot = ZO_OUTFIT_MANAGER:IsOutfitSlotArmor(outfitSlot)
        local isWeaponSlot = ZO_OUTFIT_MANAGER:IsOutfitSlotWeapon(outfitSlot)

        local function MatchesSlotType(collectibleData)
            if collectibleData:IsOutfitStyle() then
                return (isArmorSlot and collectibleData:IsArmorStyle()) or (isWeaponSlot and collectibleData:IsWeaponStyle())
            end
            return not (isArmorSlot or isWeaponSlot)
        end

        local unlockedCollectibles = categoryData:GetAllCollectibleDataObjects({ ZO_CollectibleData.IsUnlocked, MatchesSlotType })
        local eligibleCollectibleData
        while eligibleCollectibleData == nil and #unlockedCollectibles > 0 do
            local collectibleData = table.remove(unlockedCollectibles, math.random(#unlockedCollectibles))

            local eligibleSlots = { GetEligibleOutfitSlotsForCollectible(collectibleData:GetId()) }

            if isWeaponSlot then
                for _, eligibleOutfitSlot in ipairs(eligibleSlots) do
                    if outfitSlot == eligibleOutfitSlot then
                        eligibleCollectibleData = collectibleData
                    end
                end
            elseif eligibleSlots[1] == outfitSlot then
                eligibleCollectibleData = collectibleData
            end
        end

        if eligibleCollectibleData then
            local outfitStyleId = eligibleCollectibleData:GetReferenceId()
            local itemMaterialIndex = 1
            local numMaterials = GetNumOutfitStyleItemMaterials(outfitStyleId)
            if numMaterials > 1 then
                itemMaterialIndex = math.random(numMaterials)
            end
            self:SetPendingCollectibleIdAndItemMaterialIndex(eligibleCollectibleData:GetId(), itemMaterialIndex, suppressCallbacks)
        end
    end
end

do
    local NO_OUTFIT_COLLECTIBLE = 0
    local NO_ITEM_MATERIAL = nil
    function ZO_OutfitSlotManipulator:Clear(suppressCallbacks)
        self:SetPendingCollectibleIdAndItemMaterialIndex(NO_OUTFIT_COLLECTIBLE, NO_ITEM_MATERIAL, suppressCallbacks)
    end
end

do
    local function PlayChangeOutfitSound(collectibleId)
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData then
            local outfitSound = collectibleData:GetOutfitStyleEquipSound()
            if outfitSound then
                PlaySound(outfitSound)
            else
                PlaySound(SOUNDS.OUTFIT_EQUIPPED_HIDE)
            end
        else
            PlaySound(SOUNDS.OUTFIT_REMOVE_STYLE)
        end
    end

    function ZO_OutfitSlotManipulator:OnPendingDataChanged(suppressCallbacks)
        local noSuppression = not suppressCallbacks
        self:UpdatePreview(noSuppression)
        -- Dyeable channels may have changed, so don't keep pending dye changes that they can't even see
        self.restyleSlotData:CleanPendingDyes()
        if noSuppression then
            PlayChangeOutfitSound(self.pendingCollectibleId)
            self.owner:OnSlotPendingDataChanged(self.outfitSlotIndex)
        end
    end
end

function ZO_OutfitSlotManipulator:PreserveDyeData()
    self.preservedDyeData =
    {
        self:GetPendingDyeData()
    }
end

function ZO_OutfitSlotManipulator:ClearPreservedDyeData()
    self.preservedDyeData = nil
end

function ZO_OutfitSlotManipulator:RestorePreservedDyeData()
    if self.preservedDyeData then
        self:GetRestyleSlotData():SetPendingDyes(unpack(self.preservedDyeData))
        self.preservedDyeData = nil
    end
end

------------------------
-- Outfit Manipulator --
------------------------

ZO_OutfitManipulator = ZO_InitializingCallbackObject:Subclass()

function ZO_OutfitManipulator:Initialize(actorCategory, outfitIndex)
    self.actorCategory = actorCategory
    self.outfitIndex = outfitIndex
    self.outfitSlotManipulators = {}

    self:RefreshName()
    self:RefreshSlotData()
end

function ZO_OutfitManipulator:RefreshName()
    local outfitName = GetOutfitName(self.actorCategory, self.outfitIndex)
    if outfitName == "" then
        outfitName = zo_strformat(SI_OUTFIT_NO_NICKNAME_FORMAT, self.outfitIndex)
    end
    self.outfitName = outfitName
end

function ZO_OutfitManipulator:RefreshSlotData()
    for outfitSlotIndex = OUTFIT_SLOT_ITERATION_BEGIN, OUTFIT_SLOT_ITERATION_END do
        local outfitSlotManipulator = self.outfitSlotManipulators[outfitSlotIndex]
        if not outfitSlotManipulator then
            outfitSlotManipulator = ZO_OutfitSlotManipulator:New(self, outfitSlotIndex)
            self.outfitSlotManipulators[outfitSlotIndex] = outfitSlotManipulator
        end
        outfitSlotManipulator:RefreshData()
    end
end

function ZO_OutfitManipulator:GetActorCategory()
    return self.actorCategory
end

function ZO_OutfitManipulator:GetOutfitIndex()
    return self.outfitIndex
end

function ZO_OutfitManipulator:GetOutfitName()
    return self.outfitName
end

function ZO_OutfitManipulator:SetOutfitName(newName)
    if self.outfitName ~= newName then
        RenameOutfit(self:GetActorCategory(), self:GetOutfitIndex(), newName)
    end
end

function ZO_OutfitManipulator:GetSlotManipulator(outfitSlotIndex)
    return self.outfitSlotManipulators[outfitSlotIndex]
end

function ZO_OutfitManipulator:GetTotalSlotCostsForPendingChanges()
    local pendingData = {}
    for outfitSlotIndex, outfitSlotManipulator in pairs(self.outfitSlotManipulators) do
        if outfitSlotManipulator:IsAnyChangePending() then
            table.insert(pendingData, outfitSlotIndex)
            table.insert(pendingData, outfitSlotManipulator:GetPendingCollectibleId())
            table.insert(pendingData, outfitSlotManipulator:GetNumPendingDyeChanges())
        end
    end

    local totalCost = 0
    if #pendingData > 0 then
        totalCost = GetTotalApplyCostForOutfitSlots(self:GetActorCategory(), self:GetOutfitIndex(), unpack(pendingData))
    end

    return totalCost
end

do
    local OUTFIT_CHANGE_FLAT_COST = GetOutfitChangeFlatCost()

    function ZO_OutfitManipulator:GetAllCostsForPendingChanges()
        local slotsCost = self:GetTotalSlotCostsForPendingChanges()
        local flatCost = (slotsCost > 0) and OUTFIT_CHANGE_FLAT_COST or 0

        return slotsCost, flatCost
    end
end

do
    local SUPPRESS_FIRE_CALLBACKS = true

    function ZO_OutfitManipulator:ClearPendingChanges()
        if not self:IsMarkedForPreservation() then
            local hasChanged = false
            for _, outfitSlotManipulator in pairs(self.outfitSlotManipulators) do
                local slotCleared = outfitSlotManipulator:ClearPendingChanges(SUPPRESS_FIRE_CALLBACKS)
                hasChanged = hasChanged or slotCleared
            end

            if hasChanged then
                ApplyChangesToPreviewCollectionShown()
                self:OnSlotPendingDataChanged()
            end
        end
    end

    function ZO_OutfitManipulator:OnCollectibleBlacklistUpdated()
        local hasChanged = false
        for _, outfitSlotManipulator in pairs(self.outfitSlotManipulators) do
            local slotCleared = outfitSlotManipulator:OnCollectibleBlacklistUpdated(SUPPRESS_FIRE_CALLBACKS)
            hasChanged = hasChanged or slotCleared
        end

        if hasChanged then
            self:OnSlotPendingDataChanged()
        end
    end

    function ZO_OutfitManipulator:RandomizeStyleData(includeHidden)
        for _, outfitSlotManipulator in pairs(self.outfitSlotManipulators) do
            local restyleSlotData = outfitSlotManipulator:GetRestyleSlotData()
            if restyleSlotData:IsOutfitStyle() and (includeHidden or not restyleSlotData:ShouldBeHidden()) then
                outfitSlotManipulator:RandomizeSlotData(SUPPRESS_FIRE_CALLBACKS)
            end
        end
        PlaySound(SOUNDS.DYEING_RANDOMIZE_DYES)
        ApplyChangesToPreviewCollectionShown()
        self:OnSlotPendingDataChanged()
    end
end

do
    local DONT_REFRESH_IF_SHOWN = false

    function ZO_OutfitManipulator:UpdatePreviews()
        for outfitSlot, outfitSlotManipulator in pairs(self.outfitSlotManipulators) do
            if WEAPON_SLOTS[outfitSlot] then
                if outfitSlotManipulator:IsAnyChangePending() then
                    outfitSlotManipulator:UpdatePreview(DONT_REFRESH_IF_SHOWN)
                else
                    ClearOutfitSlotPreviewElementFromPreviewCollection(outfitSlot)
                end
            else
                -- Armor is simple
                outfitSlotManipulator:UpdatePreview(DONT_REFRESH_IF_SHOWN)
            end
        end

        ApplyChangesToPreviewCollectionShown()
    end
end

function ZO_OutfitManipulator:IsDyeChangePending()
    for _, outfitSlotManipulator in pairs(self.outfitSlotManipulators) do
        if outfitSlotManipulator:IsDyeChangePending() then
            return true
        end
    end
    return false
end

function ZO_OutfitManipulator:IsSlotDataChangePending()
    for _, outfitSlotManipulator in pairs(self.outfitSlotManipulators) do
        if outfitSlotManipulator:IsSlotDataChangePending() then
            return true
        end
    end
    return false
end

function ZO_OutfitManipulator:IsAnyChangePending()
    for _, outfitSlotManipulator in pairs(self.outfitSlotManipulators) do
        if outfitSlotManipulator:IsAnyChangePending() then
            return true
        end
    end
    return false
end

function ZO_OutfitManipulator:CanApplyChanges()
    if not ZO_RestyleCanApplyChanges() then
        return false, GetString("SI_APPLYOUTFITCHANGESRESULT", APPLY_OUTFIT_CHANGES_RESULT_ALTERATION_UNAVAILABLE)
    end

    if not self:IsAnyChangePending() then
        return false, GetString("SI_APPLYOUTFITCHANGESRESULT", APPLY_OUTFIT_CHANGES_RESULT_INVALID_DATA)
    end

    for _, outfitSlotManipulator in pairs(self.outfitSlotManipulators) do
        if outfitSlotManipulator:IsSlotDataChangePending() then
            local canApply, errorText = outfitSlotManipulator:CanApplyChanges()
            if not canApply then
                return canApply, errorText
            end
        end
    end

    return true
end

function ZO_OutfitManipulator:GetCollectibleDataAssociations(collectibleData)
    local isCurrent = false
    local isPending = false
    for _, outfitSlotManipulator in pairs(self.outfitSlotManipulators) do
        local isSlotCurrent, isSlotPending = outfitSlotManipulator:GetCollectibleDataAssociations(collectibleData)
        if isSlotPending then
            isPending = true
        end

        if isSlotCurrent then
            isCurrent = true
        end

        if isPending and isCurrent then
            break
        end
    end

    return isCurrent, isPending
end

function ZO_OutfitManipulator:OnSlotPendingDataChanged(outfitSlotIndex)
    self:FireCallbacks("PendingDataChanged", outfitSlotIndex)
end

function ZO_OutfitManipulator:SendOutfitChangeRequest(useFlatCurrency)
    local argumentsTable = {}
    for outfitSlotIndex, outfitSlotManipulator in pairs(self.outfitSlotManipulators) do
        if outfitSlotManipulator:IsAnyChangePending() then
            local primaryDyeId, secondaryDyeId, accentDyeId = outfitSlotManipulator:GetPendingDyeData()
            table.insert(argumentsTable, outfitSlotIndex)
            table.insert(argumentsTable, outfitSlotManipulator:GetPendingCollectibleId())
            table.insert(argumentsTable, outfitSlotManipulator:GetPendingItemMaterialIndex() or (MAX_ITEM_MATERIALS_PER_OUTFIT_STYLE + 1)) -- Can't use nil in this table
            table.insert(argumentsTable, primaryDyeId)
            table.insert(argumentsTable, secondaryDyeId)
            table.insert(argumentsTable, accentDyeId)
        end
    end

    if #argumentsTable > 0 then
        SendOutfitChangeRequest(useFlatCurrency, self:GetActorCategory(), self:GetOutfitIndex(), unpack(argumentsTable))
    end
end

function ZO_OutfitManipulator:SlotManipulatorIterator(...)
    local outfitSlot = nil
    local filterFunctions = {...}
    return function()
        local slotManipulator
        outfitSlot, slotManipulator = next(self.outfitSlotManipulators, outfitSlot)

        while outfitSlot do
            local passesFilter = true
            for filterIndex, filterFunction in ipairs(filterFunctions) do
                if not filterFunction(slotManipulator) then
                    passesFilter = false
                    break
                end
            end

            if passesFilter then
                return outfitSlot, slotManipulator
            else
                outfitSlot, slotManipulator = next(self.outfitSlotManipulators, outfitSlot)
            end
        end
    end
end

function ZO_OutfitManipulator:SetMarkedForPreservation(preservePendingChanges)
    if self.preservePendingChanges ~= preservePendingChanges then
        self.preservePendingChanges = preservePendingChanges

        for outfitSlotIndex, outfitSlotManipulator in pairs(self.outfitSlotManipulators) do
            if preservePendingChanges then
                outfitSlotManipulator:PreserveDyeData()
            else
                outfitSlotManipulator:ClearPreservedDyeData()
            end
        end
    end
end

function ZO_OutfitManipulator:RestorePreservedDyeData()
    for outfitSlotIndex, outfitSlotManipulator in pairs(self.outfitSlotManipulators) do
        outfitSlotManipulator:RestorePreservedDyeData()
    end

    self:SetMarkedForPreservation(false)
end

function ZO_OutfitManipulator:IsMarkedForPreservation()
    return self.preservePendingChanges
end

------------------------------
-- Outfit Manager Singleton --
------------------------------

local Outfit_Manager = ZO_InitializingCallbackObject:Subclass()

function Outfit_Manager:Initialize()
    self.outfits = {}
    self.companionOutfits = {}
    self.equippedOutfitIndices = {}
    self:RefreshOutfits()

    local function OnOutfitEquipResponse(eventCode, actorCategory, equipOutfitResult)
        if equipOutfitResult == EQUIP_OUTFIT_RESULT_SUCCESS then
            self:RefreshEquippedOutfitIndex(actorCategory)
        end
    end

    local function OnOutfitChangeResponse(eventCode, outfitChangeResponse, actorCategory, outfitIndex)
        if outfitChangeResponse == APPLY_OUTFIT_CHANGES_RESULT_SUCCESS then
            self:RefreshOutfitSlotData(actorCategory, outfitIndex)
            self:OnOutfitPendingDataChanged(actorCategory, outfitIndex)
            ClearAllOutfitSlotPreviewElementsFromPreviewCollection()
            ApplyChangesToPreviewCollectionShown()
        end
    end

    local function OnOutfitRenameResponse(eventCode, outfitRenameResponse, actorCategory, outfitIndex)
        if outfitRenameResponse == SET_OUTFIT_NAME_RESULT_SUCCESS then
            self:RefreshOutfitName(actorCategory, outfitIndex)
        end
    end

    local function OnCollectionUpdated(collectionUpdateType)
        if collectionUpdateType == ZO_COLLECTION_UPDATE_TYPE.BLACKLIST_CHANGED then
            for _, outfitManipulator in ipairs(self.outfits) do
                outfitManipulator:OnCollectibleBlacklistUpdated()
            end
        end
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCollectionUpdated)
    EVENT_MANAGER:RegisterForEvent("OutfitManager", EVENT_OUTFIT_EQUIP_RESPONSE, OnOutfitEquipResponse)
    EVENT_MANAGER:RegisterForEvent("OutfitManager", EVENT_OUTFITS_INITIALIZED, function() self:RefreshOutfits() end)
    EVENT_MANAGER:RegisterForEvent("OutfitManager", EVENT_OUTFIT_CHANGE_RESPONSE, OnOutfitChangeResponse)
    EVENT_MANAGER:RegisterForEvent("OutfitManager", EVENT_OUTFIT_RENAME_RESPONSE, OnOutfitRenameResponse)

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            local DEFAULTS = { showLockedStyles = true }
            self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "OutfitSlots", DEFAULTS)
            EVENT_MANAGER:UnregisterForEvent("OutfitManager", EVENT_ADD_ON_LOADED)
            self:FireCallbacks("OptionsInfoAvailable")
        end
    end
    EVENT_MANAGER:RegisterForEvent("OutfitManager", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

function Outfit_Manager.GetActorCategoryByRestyleMode(restyleMode)
    if restyleMode == RESTYLE_MODE_EQUIPMENT or restyleMode == RESTYLE_MODE_OUTFIT then
        return GAMEPLAY_ACTOR_CATEGORY_PLAYER
    elseif restyleMode == RESTYLE_MODE_COMPANION_EQUIPMENT or restyleMode == RESTYLE_MODE_COMPANION_OUTFIT then
        return GAMEPLAY_ACTOR_CATEGORY_COMPANION
    end
    return nil
end

function Outfit_Manager.GetRestyleModeByActorCategory(actorCategory)
    if actorCategory == GAMEPLAY_ACTOR_CATEGORY_PLAYER then
        return RESTYLE_MODE_OUTFIT
    elseif actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
        return RESTYLE_MODE_COMPANION_OUTFIT
    end
    return nil
end

function Outfit_Manager:RefreshOutfitSlotData(actorCategory, outfitIndex)
    local outfits = self:GetOutfitsByActorCategory(actorCategory)
    if outfits then
        local outfitManipulator = outfits[outfitIndex]
        if outfitManipulator then
            outfitManipulator:RefreshSlotData()
            self:FireCallbacks("RefreshOutfit", actorCategory, outfitIndex)
        end
    end
end

function Outfit_Manager:RefreshOutfitName(actorCategory, outfitIndex)
    local outfits = self:GetOutfitsByActorCategory(actorCategory)
    if outfits then
        local outfitManipulator = outfits[outfitIndex]
        if outfitManipulator then
            outfitManipulator:RefreshName()
            self:FireCallbacks("RefreshOutfitName", actorCategory, outfitIndex)
        end
    end
end

do
    local SUPPRESS_BROADCAST = true

    function Outfit_Manager:RefreshOutfits()
        for actorCategory = GAMEPLAY_ACTOR_CATEGORY_ITERATION_BEGIN, GAMEPLAY_ACTOR_CATEGORY_ITERATION_END do
            self:RefreshEquippedOutfitIndex(actorCategory)
        end
        for outfitIndex = 1, GetNumUnlockedOutfits(GAMEPLAY_ACTOR_CATEGORY_PLAYER) do
            self:RefreshOutfit(GAMEPLAY_ACTOR_CATEGORY_PLAYER, outfitIndex, SUPPRESS_BROADCAST)
        end
        for companionOutfitIndex = 1, GetNumUnlockedOutfits(GAMEPLAY_ACTOR_CATEGORY_COMPANION) do
            self:RefreshOutfit(GAMEPLAY_ACTOR_CATEGORY_COMPANION, companionOutfitIndex, SUPPRESS_BROADCAST)
        end
        self:FireCallbacks("RefreshOutfits")
    end
end

function Outfit_Manager:GetOutfitsByActorCategory(actorCategory)
    if actorCategory == GAMEPLAY_ACTOR_CATEGORY_PLAYER then
        return self.outfits
    elseif actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
        return self.companionOutfits
    end
    return nil
end

function Outfit_Manager:RefreshOutfit(actorCategory, outfitIndex, suppressBroadcast)
    local outfits = self:GetOutfitsByActorCategory(actorCategory)
    if outfits then
        local outfitManipulator = outfits[outfitIndex]
        if outfitManipulator then
            outfitManipulator:RefreshName()
            outfitManipulator:RefreshSlotData()
        else
            outfitManipulator = ZO_OutfitManipulator:New(actorCategory, outfitIndex)
            table.insert(outfits, outfitManipulator)
            outfitManipulator:RegisterCallback("PendingDataChanged", function(outfitSlotIndex) self:OnOutfitPendingDataChanged(actorCategory, outfitIndex, outfitSlotIndex) end)
        end
    end

    if not suppressBroadcast then
        self:FireCallbacks("RefreshOutfit", actorCategory, outfitIndex)
    end
end

function Outfit_Manager:OnOutfitPendingDataChanged(actorCategory, outfitIndex, outfitSlotIndex)
    self:FireCallbacks("PendingDataChanged", actorCategory, outfitIndex, outfitSlotIndex)
end

function Outfit_Manager:RefreshEquippedOutfitIndex(actorCategory)
    local equippedOutfitIndex = GetEquippedOutfitIndex(actorCategory)
    if self.equippedOutfitIndices[actorCategory] ~= equippedOutfitIndex then
        local previousManipulator = self:GetOutfitManipulator(actorCategory, self.equippedOutfitIndices[actorCategory])
        if previousManipulator and previousManipulator:IsMarkedForPreservation() then
            previousManipulator:SetMarkedForPreservation(false)
            previousManipulator:ClearPendingChanges(true)
        end
        self.equippedOutfitIndices[actorCategory] = equippedOutfitIndex
        self:FireCallbacks("RefreshEquippedOutfitIndex")
    end
end

function Outfit_Manager:GetOutfitManipulator(actorCategory, outfitIndex)
    local outfits = self:GetOutfitsByActorCategory(actorCategory)
    return outfits[outfitIndex]
end

function Outfit_Manager:GetEquippedOutfitIndex(actorCategory)
    return self.equippedOutfitIndices[actorCategory]
end

function Outfit_Manager:GetNumOutfits(actorCategory)
    if actorCategory == GAMEPLAY_ACTOR_CATEGORY_PLAYER then
        return #self.outfits
    elseif actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
        return #self.companionOutfits
    end
    return nil
end

function Outfit_Manager:EquipOutfit(actorCategory, outfitIndex)
    local outfits = self:GetOutfitsByActorCategory(actorCategory)
    if self.equippedOutfitIndices[actorCategory] ~= outfitIndex then
        EquipOutfit(actorCategory, outfitIndex)
        self:RefreshEquippedOutfitIndex(actorCategory)
    end
end

function Outfit_Manager:UnequipOutfit(actorCategory)
    UnequipOutfit(actorCategory)
    self:RefreshEquippedOutfitIndex(actorCategory)
end

function Outfit_Manager:GetOutfitSlotManipulatorFromRestyleSlotData(restyleSlotData)
    if restyleSlotData:IsOutfitSlot() then
        local restyleMode, restyleSetIndex, restyleSlotType = restyleSlotData:GetData()
        local actorCategory = self.GetActorCategoryByRestyleMode(restyleMode)
        local outfits = self:GetOutfitsByActorCategory(actorCategory)
        local outfitManipulator = outfits and outfits[restyleSetIndex]
        if outfitManipulator then
            return outfitManipulator:GetSlotManipulator(restyleSlotType)
        end
    end
    return nil
end

function Outfit_Manager:IsOutfitSlotWeapon(outfitSlot)
    return WEAPON_SLOTS[outfitSlot] == true
end

do
    local ARMOR_SLOTS =
    {
        [OUTFIT_SLOT_HEAD] = true,
        [OUTFIT_SLOT_CHEST] = true,
        [OUTFIT_SLOT_SHOULDERS] = true,
        [OUTFIT_SLOT_HANDS] = true,
        [OUTFIT_SLOT_WAIST] = true,
        [OUTFIT_SLOT_LEGS] = true,
        [OUTFIT_SLOT_FEET] = true,
    }

    function Outfit_Manager:IsOutfitSlotArmor(outfitSlot)
        return ARMOR_SLOTS[outfitSlot] == true
    end
end

do
    local MAIN_WEAPONS =
    {
        [OUTFIT_SLOT_WEAPON_MAIN_HAND] = true,
        [OUTFIT_SLOT_WEAPON_OFF_HAND] = true,
        [OUTFIT_SLOT_WEAPON_TWO_HANDED] = true,
        [OUTFIT_SLOT_WEAPON_STAFF] = true,
        [OUTFIT_SLOT_WEAPON_BOW] = true,
        [OUTFIT_SLOT_SHIELD] = true,
    }

    local BACKUP_WEAPONS =
    {
        [OUTFIT_SLOT_WEAPON_MAIN_HAND_BACKUP] = true,
        [OUTFIT_SLOT_WEAPON_OFF_HAND_BACKUP] = true,
        [OUTFIT_SLOT_WEAPON_TWO_HANDED_BACKUP] = true,
        [OUTFIT_SLOT_WEAPON_STAFF_BACKUP] = true,
        [OUTFIT_SLOT_WEAPON_BOW_BACKUP] = true,
        [OUTFIT_SLOT_SHIELD_BACKUP] = true,
    }

    function Outfit_Manager:IsWeaponOutfitSlotActive(outfitSlot, actorCategory)
        local activeWeaponPair = GetActiveWeaponPairInfo()
        if activeWeaponPair == ACTIVE_WEAPON_PAIR_MAIN or actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
            return MAIN_WEAPONS[outfitSlot]
        else
            return BACKUP_WEAPONS[outfitSlot]
        end
    end

    function Outfit_Manager:IsWeaponOutfitSlotCurrentlyHeld(outfitSlot, actorCategory)
        if self:IsWeaponOutfitSlotActive(outfitSlot, actorCategory) then
            local mainHandOutfitSlot, offHandOutfitSlot = GetOutfitSlotsForCurrentlyHeldWeapons(actorCategory)
            return outfitSlot == mainHandOutfitSlot or outfitSlot == offHandOutfitSlot
        end
    end

    function Outfit_Manager:IsWeaponOutfitSlotCurrentlyEquipped(outfitSlot, actorCategory)
        local mainHandOutfitSlot, offHandOutfitSlot, backupMainHandOutfitSlot, backupOffHandOutfitSlot = GetOutfitSlotsForEquippedWeapons(actorCategory)
        return outfitSlot == mainHandOutfitSlot
                or outfitSlot == offHandOutfitSlot
                or outfitSlot == backupMainHandOutfitSlot
                or outfitSlot == backupOffHandOutfitSlot
    end

    function Outfit_Manager:IsWeaponOutfitSlotMain(outfitSlot)
        return MAIN_WEAPONS[outfitSlot] == true
    end

    function Outfit_Manager:IsWeaponOutfitSlotBackup(outfitSlot)
        return BACKUP_WEAPONS[outfitSlot] == true
    end
end

function Outfit_Manager:HasWeaponsCurrentlyHeldToOverride(actorCategory)
    local mainHandOutfitSlot, offHandOutfitSlot = GetOutfitSlotsForCurrentlyHeldWeapons(actorCategory)
    return mainHandOutfitSlot ~= nil or offHandOutfitSlot ~= nil
end

function Outfit_Manager:GetPreferredOutfitSlotForStyle(collectibleData)
    if collectibleData.clearAction then
        return collectibleData.preferredOutfitSlot
    else
        local eligibleSlots = { GetEligibleOutfitSlotsForCollectible(collectibleData:GetId()) }
        if #eligibleSlots > 0 then
            if collectibleData:IsArmorStyle() then
                return eligibleSlots[1]
            else
                for _, outfitSlot in ipairs(eligibleSlots) do
                    if self:IsWeaponOutfitSlotActive(outfitSlot) then
                        return outfitSlot
                    end
                end
            end
        end
    end
    return nil
end

function Outfit_Manager:GetShowLocked()
    return self.savedVars.showLockedStyles
end

function Outfit_Manager:SetShowLocked(showLocked)
    if showLocked ~= self.savedVars.showLockedStyles then
        self.savedVars.showLockedStyles = showLocked
        self:FireCallbacks("ShowLockedChanged")
    end
end

ZO_OUTFIT_MANAGER = Outfit_Manager:New()