local ZO_PlayerEmoteManager = ZO_CallbackObject:Subclass()

function ZO_PlayerEmoteManager:New(...)
	local playerEmoteManager = ZO_CallbackObject.New(self)
	playerEmoteManager:Initialize(...)
	return playerEmoteManager
end

function ZO_PlayerEmoteManager:Initialize()
	EVENT_MANAGER:RegisterForEvent("ZO_PlayerEmoteManager", EVENT_PERSONALITY_CHANGED, function() self:BuildEmoteList() end)
	EVENT_MANAGER:RegisterForEvent("ZO_PlayerEmoteManager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:BuildEmoteList() end)
    EVENT_MANAGER:RegisterForEvent("ZO_PlayerEmoteManager", EVENT_ADD_ON_LOADED, function(_, addOnName) self:OnAddOnLoaded(addOnName) end)
    EVENT_MANAGER:RegisterForEvent("ZO_PlayerEmoteManager", EVENT_COLLECTION_UPDATED, function() self:OnCollectionUpdated() end)
    EVENT_MANAGER:RegisterForEvent("ZO_PlayerEmoteManager", EVENT_COLLECTIBLES_UPDATED, function() self:OnCollectiblesUpdated() end)
    EVENT_MANAGER:RegisterForEvent("ZO_PlayerEmoteManager", EVENT_COLLECTIBLE_UPDATED, function(_, ...) self:OnCollectibleUpdated(...) end)

    self.emoteList = {}
    self.emoteCategories = {}
    self.emoteCategoryTypes = {}

    self:BuildEmoteList()
end

function ZO_PlayerEmoteManager:OnAddOnLoaded(addOnName)
    if addOnName == "ZO_Ingame" then
		self:RefreshEmoteSlashCommands()
        EVENT_MANAGER:UnregisterForEvent("ZO_PlayerEmoteManager", EVENT_ADD_ON_LOADED)
	end
end

function ZO_PlayerEmoteManager:OnCollectionUpdated()
    self:BuildEmoteList()
    self:RefreshEmoteSlashCommands()
end

function ZO_PlayerEmoteManager:OnCollectiblesUpdated()
    self:BuildEmoteList()
    self:RefreshEmoteSlashCommands()
end

function ZO_PlayerEmoteManager:OnCollectibleUpdated(collectibleId)
    local categoryType = GetCollectibleCategoryType(collectibleId)
    if categoryType == COLLECTIBLE_CATEGORY_TYPE_EMOTE then
        self:BuildEmoteList()
        self:RefreshEmoteSlashCommands()
    end
end

function ZO_PlayerEmoteManager:AddOrRemoveEmoteSlashCommand(emoteIndex, add, ...)
    for i = 1, select("#", ...) do
        local cmd = select(i, ...)
        if SLASH_COMMANDS[cmd] == nil then
            if add then
		        SLASH_COMMANDS[cmd] = function() PlayEmoteByIndex(emoteIndex) end
            end
        else
            if not add then
                SLASH_COMMANDS[cmd] = nil
            end
        end
    end
end

function ZO_PlayerEmoteManager:RefreshEmoteSlashCommands()
    local numEmotes = GetNumEmotes()
	for emoteIndex = 1, numEmotes do
        local lockedByCollectibleId = GetEmoteCollectibleId(emoteIndex)
        local slashName = GetEmoteSlashNameByIndex(emoteIndex)
        if lockedByCollectibleId then
            local add = IsCollectibleUnlocked(lockedByCollectibleId)
            self:AddOrRemoveEmoteSlashCommand(emoteIndex, add, zo_strsplit(" ", slashName))
        else
            local ADD = true
            self:AddOrRemoveEmoteSlashCommand(emoteIndex, ADD, zo_strsplit(" ", slashName))
        end
	end
    if SLASH_COMMAND_AUTO_COMPLETE then
        SLASH_COMMAND_AUTO_COMPLETE:InvalidateSlashCommandCache()
    end
end

function ZO_PlayerEmoteManager:CompareEmotes(emoteA, emoteB)
    if IsInGamepadPreferredMode() then
        self:CompareEmotesGamepad(emoteA, emoteB)
    else
        self:CompareEmotesKeyboard(emoteA, emoteB)
    end
end

function ZO_PlayerEmoteManager:CompareEmotesGamepad(emoteA, emoteB)
    return self:GetEmoteItemInfo(emoteA).displayName < self:GetEmoteItemInfo(emoteB).displayName
end

function ZO_PlayerEmoteManager:CompareEmotesKeyboard(emoteA, emoteB)
    return self:GetEmoteItemInfo(emoteA).emoteSlashName < self:GetEmoteItemInfo(emoteB).emoteSlashName
end

local function CompareCategories(categoryA, categoryB)
    return categoryA < categoryB
end

function ZO_PlayerEmoteManager:GetEmoteItemInfo(emoteId)
    return self.emoteList[emoteId]
end

function ZO_PlayerEmoteManager:BuildEmoteList()
    ZO_ClearTable(self.emoteList)
    ZO_ClearTable(self.emoteCategories)
    ZO_ClearNumericallyIndexedTable(self.emoteCategoryTypes)

	for emoteIndex = 1, GetNumEmotes() do
        local lockedByCollectibleId = GetEmoteCollectibleId(emoteIndex)
        if not lockedByCollectibleId or IsCollectibleUnlocked(lockedByCollectibleId) then
            local emoteSlashName, emoteCategory, emoteId, displayName, showInGamepadUI = GetEmoteInfo(emoteIndex)
            if emoteSlashName ~= "" then
                if not self.emoteCategories[emoteCategory] then
                    self.emoteCategories[emoteCategory] = {}
                    table.insert(self.emoteCategoryTypes, emoteCategory)
                end

       		    local isOverriddenByPersonality = IsPlayerEmoteOverridden(emoteId)
                self.emoteList[emoteId] =   {
                                                emoteCategory = emoteCategory,
                                                emoteId = emoteId,
                                                emoteIndex = emoteIndex,
                                                displayName = displayName,
											    emoteSlashName = emoteSlashName,
                                                showInGamepadUI = showInGamepadUI,
											    isOverriddenByPersonality = isOverriddenByPersonality,
                                            }

                table.insert(self.emoteCategories[emoteCategory], emoteId)

			    if isOverriddenByPersonality then
				    if not self.emoteCategories[EMOTE_CATEGORY_PERSONALITY_OVERRIDE] then
					    self.emoteCategories[EMOTE_CATEGORY_PERSONALITY_OVERRIDE] = {}
					    table.insert(self.emoteCategoryTypes, EMOTE_CATEGORY_PERSONALITY_OVERRIDE)
				    end

				    table.insert(self.emoteCategories[EMOTE_CATEGORY_PERSONALITY_OVERRIDE], emoteId)
			    end

                if lockedByCollectibleId then
                    if not self.emoteCategories[EMOTE_CATEGORY_COLLECTED] then
                        self.emoteCategories[EMOTE_CATEGORY_COLLECTED] = {}
                        table.insert(self.emoteCategoryTypes, EMOTE_CATEGORY_COLLECTED)
                    end

                    table.insert(self.emoteCategories[EMOTE_CATEGORY_COLLECTED], emoteId)
                end
            end
        end
	end

    local emoteSortFunction
    if IsInGamepadPreferredMode() then
        emoteSortFunction = function(...) self:CompareEmotesGamepad(...) end
    else
        emoteSortFunction = function(...) self:CompareEmotesKeyboard(...) end
    end

    for _, emoteList in pairs(self.emoteCategories) do
        table.sort(emoteList, emoteSortFunction)
    end

    table.sort(self.emoteCategoryTypes, CompareCategories)

    self:FireCallbacks("EmoteListUpdated")
end

function ZO_PlayerEmoteManager:GetEmoteListForType(emoteType, optFilterFunction)
    if not self.emoteCategories then
        self:BuildEmoteList()
    end

    local emoteCategory = self.emoteCategories[emoteType]
    if not optFilterFunction then
        return emoteCategory
    else
        local filteredEmoteCategory = {}
        for _, emoteId in ipairs(emoteCategory) do
            if optFilterFunction(self.emoteList[emoteId]) then
                table.insert(filteredEmoteCategory, emoteId)
            end
        end

        return filteredEmoteCategory
    end    
end

function ZO_PlayerEmoteManager:GetEmoteCategories()
    if not self.emoteCategoryTypes then
        self:BuildEmoteList()
    end

    return self.emoteCategoryTypes
end

function ZO_PlayerEmoteManager:GetSlottedEmotes()
    local slottedEmoteList = {}
    for i = 1, ACTION_BAR_EMOTE_QUICK_SLOT_SIZE do
        local slotIndex = i + ACTION_BAR_FIRST_EMOTE_QUICK_SLOT_INDEX
        local slotType = GetSlotType(slotIndex)
        local emoteID = GetSlotBoundId(slotIndex)
        slottedEmoteList[i] =
        {
            type = slotType,
            id = emoteID,
        }
    end
    return slottedEmoteList
end

-- Globals
-------------------------------------------------------------
PLAYER_EMOTE_MANAGER = ZO_PlayerEmoteManager:New()