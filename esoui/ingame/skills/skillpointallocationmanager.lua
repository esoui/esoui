ZO_SKILL_POINT_ACTION =
{
    NONE = 1,
    PURCHASE = 2,
    SELL = 3,
    INCREASE_RANK = 4,
    DECREASE_RANK = 5,
    MORPH = 6,
    UNMORPH = 7,
    REMORPH = 8,
}

local BROADCAST = true
local DONT_BROADCAST = false

-------------------------------
--Skill Point Allocator Base --
-------------------------------

ZO_SkillPointAllocator = ZO_Object:Subclass()

function ZO_SkillPointAllocator:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_SkillPointAllocator:Initialize(manager)
    self.manager = manager
end

function ZO_SkillPointAllocator:SetSkillData(skillData)
    self.skillData = skillData
    self:Revert()
end

function ZO_SkillPointAllocator:GetSkillData()
    return self.skillData
end

function ZO_SkillPointAllocator:Revert()
    self.isPurchased = self.skillData:IsPurchased()
    self.skillProgressionKey = self.skillData:GetCurrentSkillProgressionKey()
end

-- Purchased --

function ZO_SkillPointAllocator:IsPurchased()
    return self.isPurchased
end

function ZO_SkillPointAllocator:InternalSetIsPurchased(isPurchased, ignoreCallback)
    self.isPurchased = isPurchased
    if not ignoreCallback then
        self.manager:OnPurchasedChanged(self)
    end
end

-- Progression Key --

function ZO_SkillPointAllocator:GetSkillProgressionKey()
    return self.skillProgressionKey
end

function ZO_SkillPointAllocator:GetMorphSlot()
    -- Alias
    assert(not self.skillData:IsPassive(), "Passive skill, use GetRank() or GetSkillProgressionKey()")
    return self.skillProgressionKey
end

function ZO_SkillPointAllocator:GetRank()
    -- Alias
    assert(self.skillData:IsPassive(), "Active skill, use GetMorphSlot() or GetSkillProgressionKey()")
    return self.skillProgressionKey
end

function ZO_SkillPointAllocator:InternalSetSkillProgressionKey(skillProgressionKey, ignoreCallback)
    local oldSkillProgressionKey = self.skillProgressionKey
    self.skillProgressionKey = skillProgressionKey
    if not ignoreCallback then
        self.manager:OnSkillProgressionKeyChanged(self, skillProgressionKey, oldSkillProgressionKey)
    end
end

-- Delta --

function ZO_SkillPointAllocator:IsPurchasedChangePending()
    return self.isPurchased ~= self.skillData:IsPurchased()
end

function ZO_SkillPointAllocator:IsSellPending()
    return self.skillData:IsPurchased() and not self.isPurchased
end

function ZO_SkillPointAllocator:IsSkillProgressionKeyChangePending()
    return self.skillProgressionKey ~= self.skillData:GetCurrentSkillProgressionKey()
end

function ZO_SkillPointAllocator:IsSkillProgressionKeyDowngradePending()
    if self:IsSkillProgressionKeyChangePending() then
        if self.skillData:IsPassive() then
            return self.skillData:GetCurrentSkillProgressionKey() > self.skillProgressionKey
        else
            return self.skillProgressionKey == MORPH_SLOT_BASE
        end
    end
    return false
end

function ZO_SkillPointAllocator:IsSkillProgressionKeySidegradePending()
    if self.skillData:IsActive() then
        local currentProgressionKey = self.skillData:GetCurrentSkillProgressionKey()
        return currentProgressionKey ~= self.skillProgressionKey and currentProgressionKey ~= MORPH_SLOT_BASE and self.skillProgressionKey ~= MORPH_SLOT_BASE
    end
    return false
end

function ZO_SkillPointAllocator:IsAnyChangePending()
    return self:IsPurchasedChangePending() or self:IsSkillProgressionKeyChangePending()
end

function ZO_SkillPointAllocator:DoPendingChangesIncurCost()
    return self:IsSellPending() or self:IsSkillProgressionKeyDowngradePending() or self:IsSkillProgressionKeySidegradePending()
end

--Returns how many more points will be spent
function ZO_SkillPointAllocator:GetPendingPointAllocationDelta()
    if self:IsAnyChangePending() then
        return self:GetNumPointsAllocated() - self.skillData:GetNumPointsAllocated()
    end
    return 0
end

function ZO_SkillPointAllocator:GetNumPointsAllocated()
    if self:IsPurchased() then
        local autoGrantSubtraction = self.skillData:IsAutoGrant() and 1 or 0
        if self.skillData:IsPassive() then
            return self:GetRank() - autoGrantSubtraction
        else
            local rawPointsAllocated = self:GetMorphSlot() == MORPH_SLOT_BASE and 1 or 2
            return rawPointsAllocated - autoGrantSubtraction
        end
    end
    return 0
end

function ZO_SkillPointAllocator:HasValidChangesForMode(allocationMode)
    if self:DoPendingChangesIncurCost() then
        if allocationMode == SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY then
            return false
        elseif allocationMode == SKILL_POINT_ALLOCATION_MODE_MORPHS_ONLY then
            if self:IsSellPending() then
                return false
            elseif self:IsSkillProgressionKeyDowngradePending() then
                return self.skillData:IsActive()
            end
        end
    end
    return true
end

-- Modify --

function ZO_SkillPointAllocator:HasAvailableSkillPoints()
    return self.manager:GetAvailableSkillPoints() > 0
end

function ZO_SkillPointAllocator:CanPurchase()
    return not self.isPurchased and self.skillData:MeetsLinePurchaseRequirement() and self:HasAvailableSkillPoints()
end

function ZO_SkillPointAllocator:Purchase(ignoreCallbacks)
    if self:CanPurchase() then
        self:InternalSetIsPurchased(true, ignoreCallbacks)
        return true
    end
    return false
end

function ZO_SkillPointAllocator:CanSell()
    if self.isPurchased and not self.skillData:IsAutoGrant() then
        local isPassive = self.skillData:IsPassive()
        if isPassive and self.skillProgressionKey == 1 then
            return true
        elseif not isPassive and self.skillProgressionKey == MORPH_SLOT_BASE then
            return true
        end
    end
    return false
end

-- Once a skill is at it's lowest (MORPH_SLOT_BASE for active, rank 1 for passive) you can sell the skill to get a point back
-- You cannot sell a progressed skill
function ZO_SkillPointAllocator:Sell(ignoreCallbacks)
    if self:CanSell() then
        -- Debug: Trying to track down data in a bad state
        internalassert(not self.skillData:IsPurchased() or SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode() == SKILL_POINT_ALLOCATION_MODE_FULL, "Attempting to sell skill when not in full allocation mode")

        self:InternalSetIsPurchased(false, ignoreCallbacks)
        return true
    end
    return false
end

function ZO_SkillPointAllocator:CanIncreaseRank()
    if self.skillData:IsPassive() and self.isPurchased and self:HasAvailableSkillPoints() then
        local nextSkillProgressionData = self:GetProgressionData():GetNextRankData()
        if nextSkillProgressionData then
            return nextSkillProgressionData:MeetsLineRankUnlockRequirement()
        end
    end
    return false
end

function ZO_SkillPointAllocator:IncreaseRank(ignoreCallbacks)
    if self:CanIncreaseRank() then
        self:InternalSetSkillProgressionKey(self.skillProgressionKey + 1, ignoreCallbacks)
        return true
    end
    return false
end

function ZO_SkillPointAllocator:CanDecreaseRank()
    return self.skillData:IsPassive() and self.isPurchased and self.skillProgressionKey > self:GetLowestAllowedRank()
end

function ZO_SkillPointAllocator:GetLowestAllowedRank()
    return 1
end

function ZO_SkillPointAllocator:DecreaseRank(ignoreCallbacks)
    if self:CanDecreaseRank() then
        -- Debug: Trying to track down data in a bad state
        internalassert(self.skillData:GetCurrentRank() < self.skillProgressionKey or SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode() == SKILL_POINT_ALLOCATION_MODE_FULL, "Attempting to decrease skill rank when not in full allocation mode")

        self:InternalSetSkillProgressionKey(self.skillProgressionKey - 1, ignoreCallbacks)
        return true
    end
end

function ZO_SkillPointAllocator:CanMorph()
    if not self.skillData:IsPassive() and self.isPurchased and self.skillData:IsAtMorph() then
        return self:GetSkillProgressionKey() ~= MORPH_SLOT_BASE or self:HasAvailableSkillPoints()
    end
    return false
end

function ZO_SkillPointAllocator:Morph(morphSlot, ignoreCallbacks)
    internalassert(morphSlot ~= MORPH_SLOT_BASE, "Use Unmorph function to go to base")
    if self:CanMorph() then
        -- Debug: Trying to track down data in a bad state
        internalassert(self.skillProgressionKey == MORPH_SLOT_BASE or SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode() ~= SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY, "Attempting to change skill morph when in purchase-only allocation mode")

        self:InternalSetSkillProgressionKey(morphSlot, ignoreCallbacks)
        return true
    end
    return false
end

function ZO_SkillPointAllocator:CanUnmorph()
    return not self.skillData:IsPassive() and self.skillProgressionKey ~= MORPH_SLOT_BASE
end

function ZO_SkillPointAllocator:Unmorph(ignoreCallbacks)
    if self:CanUnmorph() then
        -- Debug: Trying to track down data in a bad state
        internalassert(SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode() ~= SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY, "Attempting to unmorph skill when in purchase-only allocation mode")

        self:InternalSetSkillProgressionKey(MORPH_SLOT_BASE, ignoreCallbacks)
        return true
    end
    return false
end

function ZO_SkillPointAllocator:CanClear()
    return self:CanUnmorph() or self:CanDecreaseRank() or self:CanSell()
end

function ZO_SkillPointAllocator:Clear(ignoreCallbacks)
    if self:CanClear() then
        -- Debug: Trying to track down data in a bad state
        local allocationMode = SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode()
        internalassert(allocationMode ~= SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY, "Attempting to clear skill in purchase-only allocation mode")

        local oldSkillProgressionKey = self.skillProgressionKey
        local IGNORE_CALLBACKS_UNTIL_LAST_STEP = true

        if self.skillData:IsPassive() then
            local lowestDecreaseRank = self:GetLowestAllowedRank()
            -- Debug: Trying to track down data in a bad state
            internalassert(lowestDecreaseRank == self.skillData:GetCurrentRank() or allocationMode == SKILL_POINT_ALLOCATION_MODE_FULL, "Attempting to decrease skill rank when not in full allocation mode")

            self:InternalSetSkillProgressionKey(lowestDecreaseRank, IGNORE_CALLBACKS_UNTIL_LAST_STEP)
        else
            self:InternalSetSkillProgressionKey(MORPH_SLOT_BASE, IGNORE_CALLBACKS_UNTIL_LAST_STEP)
        end

        self:Sell(IGNORE_CALLBACKS_UNTIL_LAST_STEP)

        -- Fire off the appropriate callback unless instructed not to
        if not ignoreCallbacks then
            if self.isPurchased then
                -- We didn't sell, only cleared progression key
                self.manager:OnSkillProgressionKeyChanged(self, self.skillProgressionKey, oldSkillProgressionKey)
            else
                self.manager:OnPurchasedChanged(self)
            end
        end

        return true
    end
    return false
end

function ZO_SkillPointAllocator:CanMaxout()
    return self:CanPurchase() or self:CanIncreaseRank()
end

function ZO_SkillPointAllocator:Maxout(ignoreCallbacks)
    if self:CanMaxout() then
        if self.skillData:IsActive() then
            -- Maxout for active is really just a purchase, because we can't choose a morph for the player
            self:Purchase(ignoreCallbacks)
        else
            local manager = self.manager
            availableSkillPoints = manager:GetAvailableSkillPoints()
            local oldSkillProgressionKey = self.skillProgressionKey

            local IGNORE_CALLBACKS_UNTIL_LAST_STEP = true

            if self:Purchase(IGNORE_CALLBACKS_UNTIL_LAST_STEP) then
                manager:ChangeAvailableSkillPoints(-1, DONT_BROADCAST)
            end

            while self:IncreaseRank(IGNORE_CALLBACKS_UNTIL_LAST_STEP) do
                manager:ChangeAvailableSkillPoints(-1, DONT_BROADCAST)
            end

            -- Fire off the appropriate callback unless instructed not to
            if not ignoreCallbacks then
                if self.skillProgressionKey > oldSkillProgressionKey then
                    manager:OnSkillProgressionKeyChanged(self, self.skillProgressionKey, oldSkillProgressionKey)
                else
                    manager:OnPurchasedChanged(self)
                end
                manager:BroadcastSkillPointsChanged()
            end
        end

        return true
    end
    return false
end

function ZO_SkillPointAllocator:GetIncreaseSkillAction()
    if self:CanPurchase() then
        return ZO_SKILL_POINT_ACTION.PURCHASE
    elseif self:CanMorph() then
        local skillProgressionData = self:GetProgressionData()
        if skillProgressionData:IsMorph() then
            return ZO_SKILL_POINT_ACTION.REMORPH
        else
            return ZO_SKILL_POINT_ACTION.MORPH
        end
    elseif self:CanIncreaseRank() then
        return ZO_SKILL_POINT_ACTION.INCREASE_RANK
    else
        return ZO_SKILL_POINT_ACTION.NONE
    end
end

function ZO_SkillPointAllocator:GetDecreaseSkillAction()
    if self:CanSell() then
        return ZO_SKILL_POINT_ACTION.SELL
    elseif self:CanUnmorph() then
        return ZO_SKILL_POINT_ACTION.UNMORPH
    elseif self:CanDecreaseRank() then
        return ZO_SKILL_POINT_ACTION.DECREASE_RANK
    else
        return ZO_SKILL_POINT_ACTION.NONE
    end
end

-- Utility --

function ZO_SkillPointAllocator:IsProgressedToKey(skillProgressionKey)
    if self.isPurchased then
        if self.skillData:IsPassive() then
            return self.skillProgressionKey >= skillProgressionKey
        else
            return skillProgressionKey == MORPH_SLOT_BASE or skillProgressionKey == self.skillProgressionKey
        end
    end
    return false
end

function ZO_SkillPointAllocator:GetProgressionData()
    return self.skillData:GetProgressionData(self.skillProgressionKey)
end

function ZO_SkillPointAllocator:AddChangesToMessage()
    if self:IsAnyChangePending() then
        local skillData = self.skillData
        local skillLineId = skillData:GetSkillLineData():GetId()
        if skillData:IsPassive() then
            local relevantRankData = nil
            local isRemoval = not self:IsPurchased()

            if isRemoval then
                relevantRankData = skillData:GetRankData(skillData:GetCurrentRank())
            else
                relevantRankData = self:GetProgressionData()
            end

            local abilityId = relevantRankData:GetAbilityId()
            AddPassiveChangeToAllocationRequest(skillLineId, abilityId, isRemoval)
        else
            AddActiveChangeToAllocationRequest(skillLineId, skillData:GetProgressionId(), self.skillProgressionKey, self:IsPurchased())
        end
    end
end

function ZO_SkillPointAllocator.GetPurchaseSound()
    return SOUNDS.SKILL_PURCHASED
end

function ZO_SkillPointAllocator.GetSellSound()
    return SOUNDS.SKILL_SOLD
end

function ZO_SkillPointAllocator.GetIncreaseRankSound()
    return SOUNDS.PASSIVE_SKILL_RANK_INCREASED
end

function ZO_SkillPointAllocator.GetDecreaseRankSound()
    return SOUNDS.PASSIVE_SKILL_RANK_DECREASED
end

function ZO_SkillPointAllocator.GetMorphChosenSound()
    return SOUNDS.ACTIVE_SKILL_MORPH_CHOSEN
end

function ZO_SkillPointAllocator.GetUnmorphedSound()
    return SOUNDS.ACTIVE_SKILL_UNMORPHED
end

----------------------------------------
--Purchase-Only Skill Point Allocator --
----------------------------------------

-- Purchase-only interaction fire their changes immediately, they don't accumulate into a giant delta.

ZO_PurchaseOnlySkillPointAllocator = ZO_SkillPointAllocator:Subclass()

function ZO_PurchaseOnlySkillPointAllocator:New(...)
    return ZO_SkillPointAllocator.New(self, ...)
end

function ZO_PurchaseOnlySkillPointAllocator:CanSell()
    return false
end

function ZO_PurchaseOnlySkillPointAllocator:CanDecreaseRank()
    return false
end

function ZO_PurchaseOnlySkillPointAllocator:CanMorph()
    if ZO_SkillPointAllocator.CanMorph(self) then
        -- Can only go forward in purchase-only mode.  No swapping morphs.
        return self:GetSkillProgressionKey() == MORPH_SLOT_BASE
    end
end

function ZO_PurchaseOnlySkillPointAllocator:CanUnmorph()
    return false
end

function ZO_PurchaseOnlySkillPointAllocator:CanClear()
    return false
end

-------------------------------------
--Morphs-Only Skill Point Allocator --
--------------------------------------

ZO_MorphsOnlySkillPointAllocator = ZO_SkillPointAllocator:Subclass()

function ZO_MorphsOnlySkillPointAllocator:New(...)
    return ZO_SkillPointAllocator.New(self, ...)
end

function ZO_MorphsOnlySkillPointAllocator:CanSell()
    if ZO_SkillPointAllocator.CanSell(self) then
        -- You can only sell this skill if it hasn't been purchased on the server yet
        return not self:GetSkillData():IsPurchased()
    end
    return false
end

function ZO_MorphsOnlySkillPointAllocator:GetLowestAllowedRank()
    -- You can only decrease rank if it's not lower than the rank saved on the server
    return self:GetSkillData():GetCurrentRank()
end

function ZO_MorphsOnlySkillPointAllocator.GetPurchaseSound()
    return SOUNDS.SKILL_RESPEC_PURCHASED
end

function ZO_MorphsOnlySkillPointAllocator.GetIncreaseRankSound()
    return SOUNDS.PASSIVE_SKILL_RESPEC_RANK_INCREASED
end

function ZO_MorphsOnlySkillPointAllocator.GetMorphChosenSound()
    return SOUNDS.ACTIVE_SKILL_RESPEC_MORPH_CHOSEN
end

-------------------------------
--Full Skill Point Allocator --
-------------------------------

-- No limitations

ZO_FullSkillPointAllocator = ZO_SkillPointAllocator:Subclass()

function ZO_FullSkillPointAllocator:New(...)
    return ZO_SkillPointAllocator.New(self, ...)
end

function ZO_FullSkillPointAllocator.GetPurchaseSound()
    return SOUNDS.SKILL_RESPEC_PURCHASED
end

function ZO_FullSkillPointAllocator.GetIncreaseRankSound()
    return SOUNDS.PASSIVE_SKILL_RESPEC_RANK_INCREASED
end

function ZO_FullSkillPointAllocator.GetMorphChosenSound()
    return SOUNDS.ACTIVE_SKILL_RESPEC_MORPH_CHOSEN
end

-----------------------------------
--Skill Point Allocation Manager --
-----------------------------------

ZO_SkillPointAllocationManager = ZO_CallbackObject:Subclass()

function ZO_SkillPointAllocationManager:New(...)
    SKILL_POINT_ALLOCATION_MANAGER = ZO_CallbackObject.New(self)
    SKILL_POINT_ALLOCATION_MANAGER:Initialize(...)
    return SKILL_POINT_ALLOCATION_MANAGER
end

function ZO_SkillPointAllocationManager:Initialize()
    local function PurchaseOnlyFactory()
        return ZO_PurchaseOnlySkillPointAllocator:New(self)
    end

    local function MorphsOnlyFactory()
        return ZO_MorphsOnlySkillPointAllocator:New(self)
    end

    local function FullFactory()
        return ZO_FullSkillPointAllocator:New(self)
    end

    local function Reset(allocator)
        allocator:GetSkillData().allocatorKey = nil
    end

    self.allocatorPools =
    {
        [SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY] = ZO_ObjectPool:New(PurchaseOnlyFactory, Reset),
        [SKILL_POINT_ALLOCATION_MODE_MORPHS_ONLY] = ZO_ObjectPool:New(MorphsOnlyFactory, Reset),
        [SKILL_POINT_ALLOCATION_MODE_FULL] = ZO_ObjectPool:New(FullFactory, Reset),
    }

    self:SetRawAvailableSkillPoints(GetAvailableSkillPoints())

    SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", function() self:OnFullSystemUpdated() end)
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("SkillPointAllocationModeChanged", function(...) self:OnSkillPointAllocationModeChanged(...) end)
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("RespecStateReset", function(...) self:OnFullSystemUpdated(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_SkillPointAllocationManager", EVENT_SKILL_POINTS_CHANGED, function(eventId, ...) self:OnSkillPointsChanged(...) end)
    SKILLS_AND_ACTION_BAR_MANAGER:OnSkillPointAllocationManagerReady(self)
end

function ZO_SkillPointAllocationManager:GetAllocatorPool()
    return self.allocatorPools[SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode()]
end

function ZO_SkillPointAllocationManager:GetSkillPointAllocatorForSkillData(skillData)
    local allocatorPool = self:GetAllocatorPool()
    local allocator = nil
    local allocatorKey = skillData.allocatorKey
    if allocatorKey then
        allocator = allocatorPool:GetActiveObject(allocatorKey)
    end

    if not allocator then
        allocator, allocatorKey = allocatorPool:AcquireObject()
        skillData.allocatorKey = allocatorKey
        allocator:SetSkillData(skillData)
    end

    return allocator
end

function ZO_SkillPointAllocationManager:ReleaseAllocators()
    self:GetAllocatorPool():ReleaseAllObjects()
    self:UpdateAvailableSkillPoints()
end

function ZO_SkillPointAllocationManager:OnFullSystemUpdated()
    self:ReleaseAllocators()
    self:SetRawAvailableSkillPoints(GetAvailableSkillPoints())
    self:BroadcastSkillPointsChanged()
end

function ZO_SkillPointAllocationManager:OnSkillPointAllocationModeChanged(newSkillPointAllocationMode, oldSkillPointAllocationMode)
    local oldAllocatorPool = self.allocatorPools[oldSkillPointAllocationMode]
    oldAllocatorPool:ReleaseAllObjects()
    self:UpdateAvailableSkillPoints(BROADCAST)
end

function ZO_SkillPointAllocationManager:SetRawAvailableSkillPoints(rawAvailableSkillPoints)
    self.rawAvailableSkillPoints = rawAvailableSkillPoints
    self:UpdateAvailableSkillPoints(DONT_BROADCAST)
end

function ZO_SkillPointAllocationManager:OnSkillPointsChanged(_, newPoints)
    self:SetRawAvailableSkillPoints(newPoints)
    self:BroadcastSkillPointsChanged()
end

function ZO_SkillPointAllocationManager:OnPurchasedChanged(skillPointAllocator)
    if skillPointAllocator:IsPurchased() then
        PlaySound(skillPointAllocator:GetPurchaseSound())
    else
        PlaySound(skillPointAllocator:GetSellSound())
    end

    self:FireCallbacks("PurchasedChanged", skillPointAllocator)
    self:UpdateAvailableSkillPoints(BROADCAST)
end

function ZO_SkillPointAllocationManager:OnSkillProgressionKeyChanged(skillPointAllocator, skillProgressionKey, oldSkillProgressionKey)
    if skillPointAllocator:GetSkillData():IsPassive() then
        if skillProgressionKey > oldSkillProgressionKey then
            PlaySound(skillPointAllocator:GetIncreaseRankSound())
        else
            PlaySound(skillPointAllocator:GetDecreaseRankSound())
        end
    else
        if skillProgressionKey == MORPH_SLOT_BASE then
            PlaySound(skillPointAllocator:GetUnmorphedSound())
        else
            PlaySound(skillPointAllocator:GetMorphChosenSound())
        end
    end

    self:FireCallbacks("SkillProgressionKeyChanged", skillPointAllocator, skillProgressionKey, oldSkillProgressionKey)
    self:UpdateAvailableSkillPoints(BROADCAST)
end

function ZO_SkillPointAllocationManager:UpdateAvailableSkillPoints(broadcast)
    local oldAvailableSkillPoints = self.availableSkillPoints
    local availableSkillPoints = self.rawAvailableSkillPoints
    for _, allocator in self:AllocatorIterator() do
        availableSkillPoints = availableSkillPoints - allocator:GetPendingPointAllocationDelta()
    end
    self.availableSkillPoints = availableSkillPoints

    if broadcast and oldAvailableSkillPoints ~= availableSkillPoints then
        self:BroadcastSkillPointsChanged()
    end
end

function ZO_SkillPointAllocationManager:ChangeAvailableSkillPoints(delta, broadcast)
    if delta ~= 0 then
        local availableSkillPoints = self.availableSkillPoints + delta
        assert(availableSkillPoints >= 0)
        self.availableSkillPoints = availableSkillPoints

        if broadcast then
            self:BroadcastSkillPointsChanged()
        end
    end
end

function ZO_SkillPointAllocationManager:BroadcastSkillPointsChanged()
    self:FireCallbacks("SkillPointsChanged", self.availableSkillPoints)
end

function ZO_SkillPointAllocationManager:GetAvailableSkillPoints()
    return self.availableSkillPoints
end

function ZO_SkillPointAllocationManager:IsAnyChangePending()
    for _, allocator in self:AllocatorIterator({ ZO_SkillPointAllocator.IsAnyChangePending }) do
        return true
    end
    return false
end

function ZO_SkillPointAllocationManager:DoPendingChangesIncurCost()
    for _, allocator in self:AllocatorIterator({ ZO_SkillPointAllocator.DoPendingChangesIncurCost }) do
        return true
    end
    return false
end

function ZO_SkillPointAllocationManager:AllocatorIterator(allocatorFilterFunctions)
    return ZO_FilteredNonContiguousTableIterator(self:GetAllocatorPool():GetActiveObjects(), allocatorFilterFunctions)
end

function ZO_SkillPointAllocationManager:AddChangesToMessage()
    local anyChangesAdded = false
    local allValidChanges = true
    local allocationMode = SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode()
    for _, allocator in self:AllocatorIterator({ ZO_SkillPointAllocator.IsAnyChangePending }) do
        if allocator:HasValidChangesForMode(allocationMode) then
            allocator:AddChangesToMessage()
            anyChangesAdded = true
        else
            allValidChanges = false
        end
    end

    -- Debug: Trying to track down data in a bad state
    internalassert(allValidChanges, "Has pending skill changes incompatible with current mode")

    return anyChangesAdded
end

function ZO_SkillPointAllocationManager:HasValidChangesForMode()
    local allocationMode = SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode()
    for _, allocator in self:AllocatorIterator({ ZO_SkillPointAllocator.IsAnyChangePending }) do
        if not allocator:HasValidChangesForMode(allocationMode) then
            return false
        end
    end
    return true
end

function ZO_SkillPointAllocationManager:GetNumPointsAllocatedInSkillLine(skillLineData)
    local numPointsAllocated = 0

    for _, skillData in skillLineData:SkillIterator() do
        local allocatorPool = self:GetAllocatorPool()
        local allocatorKey = skillData.allocatorKey
        local allocator = allocatorKey and allocatorPool:GetActiveObject(allocatorKey)
        if allocator then
            numPointsAllocated = numPointsAllocated + allocator:GetNumPointsAllocated()
        else
            numPointsAllocated = numPointsAllocated + skillData:GetNumPointsAllocated()
        end
    end

    return numPointsAllocated
end

function ZO_SkillPointAllocationManager:ClearPointsOnSkillLine(skillLineData, ignoreCallbacks)
    local allocationMode = SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode()
    if allocationMode ~= SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY and skillLineData:IsAvailable() then
        
        local anyCleared = false
        local IGNORE_CALLBACKS = true

        local function CanClearPoints(skillData)
            -- We don't want to make allocators if they don't already exist and we don't need them
            local allocatorPool = self:GetAllocatorPool()
            local allocatorKey = skillData.allocatorKey
            local allocator = allocatorKey and allocatorPool:GetActiveObject(allocatorKey)
            if allocator then
                return allocator:CanClear()
            else
                local clearMorphsOnly = allocationMode == SKILL_POINT_ALLOCATION_MODE_MORPHS_ONLY
                return skillData:HasPointsToClear(clearMorphsOnly)
            end
        end

        for _, skillData in skillLineData:SkillIterator({ CanClearPoints }) do
            local allocator = self:GetSkillPointAllocatorForSkillData(skillData)
            if allocator:Clear(IGNORE_CALLBACKS) then
                anyCleared = true
            end
        end

        if anyCleared then
            if not ignoreCallbacks then
                self:FireCallbacks("OnSkillsCleared", skillLineData)
                self:UpdateAvailableSkillPoints(BROADCAST)
            end

            return true
        end
    end

    return false
end

function ZO_SkillPointAllocationManager:ClearPointsOnSkillType(skillTypeData, ignoreCallbacks)
    if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
        local anyCleared = false

        for _, skillLineData in skillTypeData:SkillLineIterator({ ZO_SkillLineData.IsAvailable }) do
            if self:ClearPointsOnSkillLine(skillLineData, ignoreCallbacks) then
                anyCleared = true
            end
        end

        if anyCleared then
            if not ignoreCallbacks then
                self:FireCallbacks("OnSkillsCleared")
                self:UpdateAvailableSkillPoints(BROADCAST)
            end

            return true
        end
    end

    return false
end

function ZO_SkillPointAllocationManager:ClearPointsOnAllSkillLines()
    local anyCleared = false

    if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
        local IGNORE_CALLBACKS = true

        for _, skillTypeData in SKILLS_DATA_MANAGER:SkillTypeIterator() do
            if self:ClearPointsOnSkillType(skillTypeData, IGNORE_CALLBACKS) then
                anyCleared = true
            end
        end
    end

    if anyCleared then
        self:FireCallbacks("OnSkillsCleared")
        self:UpdateAvailableSkillPoints(BROADCAST)
    end
end

ZO_SkillPointAllocationManager:New()