
--------------------------------------
--Collections Inventory Singleton
--------------------------------------

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

    for categoryType = COLLECTIBLE_CATEGORY_TYPE_MIN_VALUE, COLLECTIBLE_CATEGORY_TYPE_MAX_VALUE do
        if IsCollectibleCategoryUsable(categoryType) and IsCollectibleCategorySlottable(categoryType) then
            for i = 1, GetTotalCollectiblesByCategoryType(categoryType) do
                local collectibleId = GetCollectibleIdFromType(categoryType, i)
                local _, _, iconFile, _, unlocked, _, isActive = GetCollectibleInfo(collectibleId)
                if unlocked then
                    table.insert(self.quickslotData, 
                        {
                        name = GetCollectibleName(collectibleId),
						nickname = GetCollectibleNickname(collectibleId),
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

function ZO_CollectionsInventorySingleton:GetQuickslotData()
    return self.quickslotData
end

function ZO_CollectionsInventorySingleton:GetCollectibleInventoryDisplayName(data)
	local displayName = ""
	if data then
		if data.name then 
			if data.nickname and data.nickname ~= "" then
				displayName = zo_strformat(SI_COLLECTIONS_INVENTORY_DISPLAY_NAME_FORMAT, data.name, data.nickname)
			else
				displayName = zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, data.name)
			end
		end
	end

    return displayName
end

COLLECTIONS_INVENTORY_SINGLETON = ZO_CollectionsInventorySingleton:New()