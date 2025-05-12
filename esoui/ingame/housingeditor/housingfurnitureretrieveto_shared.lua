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

function ZO_HousingFurnitureRetrieveToBag:Initialize(bagId)
    self.bagId = bagId
    self.collectibleId = GetCollectibleForBag(self.bagId)
end

function ZO_HousingFurnitureRetrieveToBag:GetBagId()
    return self.bagId
end

function ZO_HousingFurnitureRetrieveToBag:GetCollectibleId()
    return self.collectibleId
end

function ZO_HousingFurnitureRetrieveToBag:GetDisplayName()
    local displayName

    local collectibleId = self:GetCollectibleId()
    if collectibleId ~= 0 then
        -- Use the collectible nickname, if set; otherwise, use the collectible name.
        displayName = GetCollectibleNickname(collectibleId)
        if displayName == "" then
            displayName = GetCollectibleName(collectibleId)
        end
    else
        -- Use the bag name for non-collectible based bags.
        displayName = GetString("SI_BAG", self:GetBagId())
    end

    return displayName
end

-- Returns the display name of this bag including the relevant color when disabled
-- and the number of slots used/total number of slots.
function ZO_HousingFurnitureRetrieveToBag:GetFormattedDisplayName(includeBagSlots)
    if self:IsEnabled() then
        if includeBagSlots then
            local numUsedSlots = GetNumBagUsedSlots(self.bagId)
            local numTotalSlots = GetBagSize(self.bagId)
            return zo_strformat(SI_HOUSING_EDITOR_RETRIEVE_TO_BAG_FORMATTER, self:GetDisplayName(), numUsedSlots, numTotalSlots)
        end

        return self:GetDisplayName()
    end

    return ZO_DEFAULT_DISABLED_COLOR:Colorize(self:GetDisplayName())
end

-- Returns the "X/Y slots used" string for this bag.
function ZO_HousingFurnitureRetrieveToBag:GetSlotUsageString()
    local numUsedSlots = GetNumBagUsedSlots(self.bagId)
    local numTotalSlots = GetBagSize(self.bagId)
    return zo_strformat(SI_GAMEPAD_HOUSING_EDITOR_RETRIEVE_TO_BAG_FORMATTER, numUsedSlots, numTotalSlots)
end

-- Indicates whether this bag is enabled for use.
function ZO_HousingFurnitureRetrieveToBag:IsEnabled()
    local collectibleId = self:GetCollectibleId()
    if self.bagId == BAG_FURNITURE_VAULT then
        -- Must have ESO+ subscription and unlocked Furnishing Vault collectible.
        return IsESOPlusSubscriber() and collectibleId ~= 0 and IsCollectibleUnlocked(collectibleId)
    end

    -- Must have unlocked the collectible for this bag or this bag has no associated collectible.
    return collectibleId == 0 or IsCollectibleUnlocked(collectibleId)
end

-- Indicates whether this bag is the currently selected Retrieve To bag.
function ZO_HousingFurnitureRetrieveToBag:IsSelected()
    return HOUSING_EDITOR_SHARED:GetRetrieveToBag() == self.bagId
end

-- Indicates whether this bag should be shown in the list of bags.
function ZO_HousingFurnitureRetrieveToBag:IsVisible()
    return self.bagId == BAG_FURNITURE_VAULT or self:IsEnabled()
end

function ZO_HousingFurnitureRetrieveToBag:GetTooltipText()
    local collectibleId = self:GetCollectibleId()
    if self.bagId == BAG_FURNITURE_VAULT then
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

    -- No tooltip is necessary.
    return nil
end

ZO_HousingFurnitureRetrieveTo_Shared = ZO_InitializingObject:Subclass()

function ZO_HousingFurnitureRetrieveTo_Shared:Initialize(control, fragment)
    self.control = control
    self.fragment = fragment
    self.isESOPlusSubscriber = IsESOPlusSubscriber()

    -- Construct the bag info list.
    self.bags = {}
    for _, bagId in ipairs(ZO_HOUSING_FURNITURE_RETRIEVE_TO_BAGS) do
        local bagInfo = ZO_HousingFurnitureRetrieveToBag:New(bagId)
        table.insert(self.bags, bagInfo)
    end

    -- Immediately flag bag info as dirty to force the initial refresh when the fragment is shown for the first time.
    self:SetDirty()

    local function OnBagsUpdated()
        -- Dirty the retrieve to bag list as bag availability, nicknames or capacity may have changed.
        self:SetDirty()
    end

    -- Flag bag info as dirty when bag ownership changes.
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", OnBagsUpdated)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnBagsUpdated)

    -- Flag bag info as dirty when bag capacity changes.
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", OnBagsUpdated)
    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", OnBagsUpdated)
    control:RegisterForEvent(EVENT_INVENTORY_BAG_CAPACITY_CHANGED, OnBagsUpdated)
    control:RegisterForEvent(EVENT_INVENTORY_BANK_CAPACITY_CHANGED, OnBagsUpdated)
    control:RegisterForEvent(EVENT_STACKED_ALL_ITEMS_IN_BAG, OnBagsUpdated)

    -- Flag bag info as dirty when the selected Retrieve To bag changes.
    control:RegisterForEvent(EVENT_HOUSING_FURNITURE_RETRIEVE_TO_BAG_CHANGED, OnBagsUpdated)

    fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            -- Refreshes bag info if flagged as dirty.
            self:RefreshBags()
        end
    end)
end

function ZO_HousingFurnitureRetrieveTo_Shared:ClearDirty()
    -- Resets the dirty state.
    self.dirty = false
    self.isESOPlusSubscriber = IsESOPlusSubscriber()
end

function ZO_HousingFurnitureRetrieveTo_Shared:SetDirty()
    -- Sets the dirty state to ensure that the bag list is updated the next time that this fragment is shown.
    self.dirty = true

    -- Refresh immediately if the fragment is already showing.
    if self.fragment:IsShowing() then
        self:RefreshBags()
    end
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

function ZO_HousingFurnitureRetrieveTo_Shared:GetBags()
    -- Returns the bag info table.
    return self.bags
end

function ZO_HousingFurnitureRetrieveTo_Shared:GetBagInfo(bagId)
    -- Returns the bag info for the specified bagId.
    for _, bagInfo in ipairs(self.bags) do
        if bagId == bagInfo.bagId then
            return bagInfo
        end
    end
    return nil
end

function ZO_HousingFurnitureRetrieveTo_Shared:GetBagTooltipText(bagId)
    -- Returns the tooltip text that should be displayed for the specified bagId.
    -- Returns nil if no tooltip should be displayed.
    local bagInfo = self:GetBagInfo(bagId)
    if bagInfo then
        return bagInfo:GetTooltipText()
    end
    return nil
end

function ZO_HousingFurnitureRetrieveTo_Shared:GetSelectedBagId()
    return HOUSING_EDITOR_SHARED:GetRetrieveToBag()
end

function ZO_HousingFurnitureRetrieveTo_Shared:GetSelectedBagInfo()
    -- Returns the bag info for the currently selected retrieve to bag.
    return self:GetBagInfo(self:GetSelectedBagId())
end

function ZO_HousingFurnitureRetrieveTo_Shared:RefreshBags()
    self:DeferredInitializeControls()

    if self:IsDirty() then
        self:ClearDirty()

        -- Refresh the Retrieve To bag list.
        self:RefreshBagList()
    end
end

function ZO_HousingFurnitureRetrieveTo_Shared:SetSelectedBag(bagId)
    -- Set the currently selected bag and refresh the Retrieve To bag list.
    if self:GetSelectedBagId() ~= bagId then
        HOUSING_EDITOR_SHARED:SetRetrieveToBag(bagId)
    end
end

-- Abstract Methods

ZO_HousingFurnitureRetrieveTo_Shared.InitializeControls = ZO_HousingFurnitureRetrieveTo_Shared:MUST_IMPLEMENT()
ZO_HousingFurnitureRetrieveTo_Shared.RefreshBagList = ZO_HousingFurnitureRetrieveTo_Shared:MUST_IMPLEMENT()