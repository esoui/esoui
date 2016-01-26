COLLECTIONS_INVENTORY_VALID_CATEGORY_TYPES =
{
    [COLLECTIBLE_CATEGORY_TYPE_MOUNT] = true,
    [COLLECTIBLE_CATEGORY_TYPE_VANITY_PET] = true,
    [COLLECTIBLE_CATEGORY_TYPE_COSTUME] = true,
}

--------------------------------------
--Collections Inventory Singleton
--------------------------------------

COLLECTIONS_INVENTORY_SINGLETON = nil

ZO_CollectionsInventorySingleton = ZO_CallbackObject:Subclass()

function ZO_CollectionsInventorySingleton:New()
    local singleton = ZO_CallbackObject.New(self)
    singleton:Initialize()
    return singleton
end

function ZO_CollectionsInventorySingleton:Initialize()
    self:RegisterForEvents()

    self:BuildQuickslotData()
end

function ZO_CollectionsInventorySingleton:RegisterForEvents()
    local function RebuildScriptData()
        self:BuildQuickslotData()

        self:FireCallbacks("CollectionsInventoryUpdate")
    end

    EVENT_MANAGER:RegisterForEvent("ZO_CollectionsInventorySingleton_OnCollectionUpdated", EVENT_COLLECTION_UPDATED, RebuildScriptData)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectionsInventorySingleton_OnCollectibleUpdated", EVENT_COLLECTIBLE_UPDATED, RebuildScriptData)
end

function ZO_CollectionsInventorySingleton:BuildQuickslotData()
    self.quickslotData = {}

    for i = 1, GetNumCollectibleCategories() do
        local categoryType = select(7, GetCollectibleCategoryInfo(i))
        if COLLECTIONS_INVENTORY_VALID_CATEGORY_TYPES[categoryType] then
            if IsCollectibleCategorySlottable(categoryType) then
                for i = 1, GetTotalCollectiblesByCategoryType(categoryType) do
                    local collectibleId = GetCollectibleIdFromType(categoryType, i)
                    local _, _, iconFile, _, unlocked, _, isActive = GetCollectibleInfo(collectibleId)
                    if unlocked then
                        table.insert(self.quickslotData, 
                            {
                            name = self:GetCollectibleInventoryDisplayName(collectibleId),
                            iconFile = iconFile,
                            collectibleId = collectibleId,
                            categoryType = categoryType,
                            active = isActive,
                            --even though collectibles don't have a value or age, we want to keep them separate when sorted
                            stackSellPrice = -1,
                            age = -1
                            }
                        )
                    end
                end
            end
        end
    end
end

function ZO_CollectionsInventorySingleton:GetQuickslotData()
    return self.quickslotData
end

function ZO_CollectionsInventorySingleton:GetCollectibleInventoryDisplayName(collectibleId)
    local name = GetCollectibleName(collectibleId)
    local nickname = GetCollectibleNickname(collectibleId)
    local displayName = nickname == "" and zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, name) or zo_strformat(SI_COLLECTIONS_INVENTORY_DISPLAY_NAME_FORMAT, name, nickname)

    return displayName
end


do
    COLLECTIONS_INVENTORY_SINGLETON = ZO_CollectionsInventorySingleton:New()
end