
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
    self.collectionsData = {}

    self:RegisterForEvents()
    self:BuildCollectionsData()
end

function ZO_CollectionsInventorySingleton:RegisterForEvents()
    local function RebuildScriptData()
        self:BuildCollectionsData()
        self:FireCallbacks("FullCollectionsInventoryUpdate")
    end

    local function RebuildSingleScriptData(eventId, collectibleId)
        self:BuildSingleCollectionsData(collectibleId)
        self:FireCallbacks("SingleCollectionsInventoryUpdate", collectibleId)
    end

    EVENT_MANAGER:RegisterForEvent("ZO_CollectionsInventorySingleton_OnCollectionUpdated", EVENT_COLLECTION_UPDATED, RebuildScriptData)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectionsInventorySingleton_OnCollectibleUpdated", EVENT_COLLECTIBLES_UPDATED, RebuildScriptData)
    EVENT_MANAGER:RegisterForEvent("ZO_CollectionsInventorySingleton_OnCollectibleUpdated", EVENT_COLLECTIBLE_UPDATED, RebuildSingleScriptData)
end

function ZO_CollectionsInventorySingleton:BuildCollectionsData()
    ZO_ClearTable(self.collectionsData)

    for categoryType = COLLECTIBLE_CATEGORY_TYPE_MIN_VALUE, COLLECTIBLE_CATEGORY_TYPE_MAX_VALUE do
        for i = 1, GetTotalCollectiblesByCategoryType(categoryType) do
            local collectibleId = GetCollectibleIdFromType(categoryType, i)
            self:BuildSingleCollectionsData(collectibleId)
        end
    end
end

function ZO_CollectionsInventorySingleton:BuildSingleCollectionsData(collectibleId)
    local name, _, iconFile, _, unlocked, _, isActive, categoryType = GetCollectibleInfo(collectibleId)
    local isValidForPlayer = IsCollectibleValidForPlayer(collectibleId)
    if unlocked and isValidForPlayer then    --not sure if we'll ever need locked collectibles in here?
        self.collectionsData[collectibleId] =
        {
            name = name,
			nickname = GetCollectibleNickname(collectibleId),
            iconFile = iconFile,
            collectibleId = collectibleId,
            categoryType = categoryType,
            active = isActive,
            --even though collectibles don't have a value or age, we want to keep them separate when sorted
            stackSellPrice = -1,
            age = -1,
        }
    end
end

function ZO_CollectionsInventorySingleton:GetCollectionsData(...) --... are filter functions that takes COLLECTIBLE_CATEGORY_TYPE as an argument
    local filteredItems = {}
    local passedFilter

    for index, data in pairs(self.collectionsData) do
        passedFilter = true
        for i = 1, select("#", ...) do
            local filterFunction = select(i, ...)
            if not filterFunction(data.categoryType) then
                passedFilter = false
                break --you must pass every filter function to be included
            end
        end

        if passedFilter then
            table.insert(filteredItems, data)
        end
    end
    return filteredItems
end

function ZO_CollectionsInventorySingleton:GetSingleCollectibleData(collectibleId, ...)
    local data = self.collectionsData[collectibleId]
    if data then
        for i = 1, select("#", ...) do
            local filterFunction = select(i, ...)
            if not filterFunction(data.categoryType) then
                return
            end
        end
    end

    return data
end

function ZO_CollectionsInventorySingleton:GetQuickslotData()
    return self:GetCollectionsData(IsCollectibleCategoryUsable, IsCollectibleCategorySlottable)
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