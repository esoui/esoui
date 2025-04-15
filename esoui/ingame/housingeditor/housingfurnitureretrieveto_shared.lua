ZO_HOUSING_FURNITURE_RETRIEVE_TO_BAGS =
{
    BAG_FURNITURE_VAULT,
    BAG_BACKPACK,
    BAG_BANK,
    BAG_HOUSE_BANK_ONE,
    BAG_HOUSE_BANK_TWO,
    BAG_HOUSE_BANK_THREE,
    BAG_HOUSE_BANK_FOUR,
    BAG_HOUSE_BANK_FIVE,
    BAG_HOUSE_BANK_SIX,
    BAG_HOUSE_BANK_SEVEN,
    BAG_HOUSE_BANK_EIGHT,
}

ZO_HousingFurnitureRetrieveToBag = ZO_InitializingObject:Subclass()

function ZO_HousingFurnitureRetrieveToBag:Initialize(bagId, collectibleId, displayName, enabled)
    self.bagId = bagId
    self.collectibleId = collectibleId
    self.displayName = displayName
    self.enabled = enabled
end

ZO_HousingFurnitureRetrieveTo_Shared = ZO_InitializingObject:Subclass()

function ZO_HousingFurnitureRetrieveTo_Shared:Initialize(control)
    self.control = control
    self.dirty = true
    self.isESOPlusSubscriber = IsESOPlusSubscriber()

    local function OnCollectionUpdated()
        -- Dirty the retrieve to bag list as bag availability or nicknames may have changed.
        self.dirty = true
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", OnCollectionUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCollectionUpdated)

    EVENT_MANAGER:RegisterForEvent(control:GetName() .. "Events", EVENT_HOUSING_FURNITURE_RETRIEVE_TO_BAG_CHANGED, function(_, bagId)
        -- Refresh the currently selected retrieve to bag.
        self:RefreshRetrieveToBag()
    end)
end

function ZO_HousingFurnitureRetrieveTo_Shared:ClearDirty()
    -- Resets the dirty state.
    self.dirty = false
    self.isESOPlusSubscriber = IsESOPlusSubscriber()
end

function ZO_HousingFurnitureRetrieveTo_Shared:DeferredInitializeControls()
    -- Deferred control initialization.
    if not self._initialized then
        self._initialized = true
        self:InitializeControls()
    end
end

function ZO_HousingFurnitureRetrieveTo_Shared:IsDirty()
    -- Returns true if the bag list must be initialized or if retrieve to bag availability has changed.
    return self.dirty or IsESOPlusSubscriber() ~= self.isESOPlusSubscriber
end

function ZO_HousingFurnitureRetrieveTo_Shared:GetRetrieveToBags()
    -- Returns the retrieve bag info table.
    return self.bags
end

function ZO_HousingFurnitureRetrieveTo_Shared:GetRetrieveToBagInfo(bagId)
    if self:IsDirty() or not self.bags then
        self:RefreshRetrieveToBags()
    end

    -- Returns the bag info for the specified bagId.
    for _, bagInfo in ipairs(self.bags) do
        if bagId == bagInfo.bagId then
            return bagInfo
        end
    end
    return nil
end

function ZO_HousingFurnitureRetrieveTo_Shared:GetRetrieveToBagTooltipText(bagId)
    -- Returns the tooltip text that should be displayed for the specified bagId.
    -- Returns nil if no tooltip should be displayed.
    local bagInfo = self:GetRetrieveToBagInfo(bagId)
    if not bagInfo then
        return nil
    end

    local collectibleId = bagInfo.collectibleId
    if bagInfo.bagId == BAG_FURNITURE_VAULT then
        if not IsESOPlusSubscriber() then
            return GetString(SI_FURNITURE_VAULT_ERROR_NEED_ESO_PLUS)
        end

        if collectibleId ~= 0 and not IsCollectibleUnlocked(collectibleId) then
            return GetString(SI_FURNITURE_VAULT_ERROR_NEED_COLLECTIBLE)
        end
    else
        if collectibleId ~= 0 and not IsCollectibleUnlocked(collectibleId) then
            return zo_strformat(SI_HOUSING_EDITOR_RETRIEVE_TO_BAG_LOCKED, GetCollectibleName(collectibleId))
        end
    end
    return nil
end

function ZO_HousingFurnitureRetrieveTo_Shared:GetSelectedRetrieveToBagInfo()
    -- Returns the bag info for the currently selected retrieve to bag.
    return self:GetRetrieveToBagInfo(self.selectedBag)
end

function ZO_HousingFurnitureRetrieveTo_Shared:RefreshRetrieveToBag()
    -- Refresh the currently selected bag and the selection UI.
    self.selectedBag = HOUSING_EDITOR_SHARED:GetRetrieveToBag()
    self:DeferredInitializeControls()
    self:UpdateRetrieveToBagList()
end

function ZO_HousingFurnitureRetrieveTo_Shared:RefreshRetrieveToBags()
    -- Initialize or refresh the retrieve to bag table.
    if self:IsDirty() then
        self:ClearDirty()
        if self.bags then
            ZO_ClearNumericallyIndexedTable(self.bags)
        else
            self.bags = {}
        end

        for _, bagId in ipairs(ZO_HOUSING_FURNITURE_RETRIEVE_TO_BAGS) do
            local collectibleId = GetCollectibleForBag(bagId)
            local displayName
            if collectibleId ~= 0 then
                -- Use the collectible nickname, if set; otherwise, fallback to the collectible name.
                displayName = GetCollectibleNickname(collectibleId)
                if displayName == "" then
                    displayName = GetCollectibleName(collectibleId)
                end
            else
                -- Use the bag name for non-collectible based bags.
                displayName = GetString("SI_BAG", bagId)
            end
            local enabled = collectibleId == 0 or IsCollectibleUnlocked(collectibleId)
            local bagInfo = ZO_HousingFurnitureRetrieveToBag:New(bagId, collectibleId, displayName, enabled)
            table.insert(self.bags, bagInfo)
        end
    end

    self:DeferredInitializeControls()

    -- Refresh the retrieve to bag UI list items.
    self:RefreshRetrieveToBagList()

    -- Refresh the currently selected bag and the selection UI.
    self:RefreshRetrieveToBag()
end

function ZO_HousingFurnitureRetrieveTo_Shared:SetRetrieveToBag(bagId)
    -- Set the currently selected bag and refresh the selection UI.
    HOUSING_EDITOR_SHARED:SetRetrieveToBag(bagId)
end

-- Abstract Methods

ZO_HousingFurnitureRetrieveTo_Shared.InitializeControls = ZO_HousingFurnitureRetrieveTo_Shared:MUST_IMPLEMENT()
ZO_HousingFurnitureRetrieveTo_Shared.RefreshRetrieveToBagList = ZO_HousingFurnitureRetrieveTo_Shared:MUST_IMPLEMENT()
ZO_HousingFurnitureRetrieveTo_Shared.UpdateRetrieveToBagList = ZO_HousingFurnitureRetrieveTo_Shared:MUST_IMPLEMENT()