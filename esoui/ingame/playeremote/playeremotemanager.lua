ZO_PlayerEmote_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_PlayerEmote_Manager:Initialize()
    local function MarkEmoteListDirty()
        self:MarkEmoteListDirty()
    end

    EVENT_MANAGER:RegisterForEvent("ZO_PlayerEmote_Manager", EVENT_PERSONALITY_CHANGED, MarkEmoteListDirty)
    EVENT_MANAGER:RegisterForEvent("ZO_PlayerEmote_Manager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, MarkEmoteListDirty)
    EVENT_MANAGER:RegisterForEvent("ZO_PlayerEmote_Manager", EVENT_ADD_ON_LOADED, function(_, addOnName) self:OnAddOnLoaded(addOnName) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", function(...) self:OnCollectibleUpdated(...) end)
    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", function(...) self:OnCollectionUpdated(...) end)

    self.emoteList = {}
    self.emoteCategories = {}
    self.emoteCategoryTypes = {}

    self:MarkEmoteListDirty()
end

function ZO_PlayerEmote_Manager:OnAddOnLoaded(addOnName)
    if addOnName == "ZO_Ingame" then
        self:RefreshEmoteSlashCommands()
        EVENT_MANAGER:UnregisterForEvent("ZO_PlayerEmote_Manager", EVENT_ADD_ON_LOADED)
    end
end

function ZO_PlayerEmote_Manager:OnCollectionUpdated(collectionUpdateType, collectiblesByNewUnlockState)
    if collectionUpdateType == ZO_COLLECTION_UPDATE_TYPE.REBUILD then
        self:MarkEmoteListDirty()
        self:RefreshEmoteSlashCommands()
    else
        for _, unlockStateTable in pairs(collectiblesByNewUnlockState) do
            for _, collectibleData in ipairs(unlockStateTable) do
                if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_EMOTE) or collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_PERSONALITY) then
                    self:MarkEmoteListDirty()
                    self:RefreshEmoteSlashCommands()
                    return
                end
            end
        end
    end
end

function ZO_PlayerEmote_Manager:OnCollectibleUpdated(collectibleId)
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_EMOTE) or collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_PERSONALITY) then
        self:MarkEmoteListDirty()
        self:RefreshEmoteSlashCommands()
    end
end

function ZO_PlayerEmote_Manager:AddOrRemoveEmoteSlashCommand(emoteIndex, add, ...)
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

function ZO_PlayerEmote_Manager:RefreshEmoteSlashCommands()
    local numEmotes = GetNumEmotes()
    for emoteIndex = 1, numEmotes do
        local lockedByCollectibleId = GetEmoteCollectibleId(emoteIndex)
        local slashName = GetEmoteSlashNameByIndex(emoteIndex)
        if lockedByCollectibleId then
            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(lockedByCollectibleId)
            local add = collectibleData and collectibleData:IsUnlocked()
            self:AddOrRemoveEmoteSlashCommand(emoteIndex, add, zo_strsplit(" ", slashName))
        else
            local ADD = true
            self:AddOrRemoveEmoteSlashCommand(emoteIndex, ADD, zo_strsplit(" ", slashName))
        end
    end
    self:FireCallbacks("EmoteSlashCommandsUpdated")
end

function ZO_PlayerEmote_Manager:CompareEmotes(emoteA, emoteB)
    if IsInGamepadPreferredMode() then
        self:CompareEmotesGamepad(emoteA, emoteB)
    else
        self:CompareEmotesKeyboard(emoteA, emoteB)
    end
end

function ZO_PlayerEmote_Manager:CompareEmotesGamepad(emoteA, emoteB)
    return self:GetEmoteItemInfo(emoteA).displayName < self:GetEmoteItemInfo(emoteB).displayName
end

function ZO_PlayerEmote_Manager:CompareEmotesKeyboard(emoteA, emoteB)
    return self:GetEmoteItemInfo(emoteA).emoteSlashName < self:GetEmoteItemInfo(emoteB).emoteSlashName
end

local function CompareCategories(categoryA, categoryB)
    return categoryA < categoryB
end

function ZO_PlayerEmote_Manager:GetEmoteItemInfo(emoteId)
    self:CleanEmoteList()
    return self.emoteList[emoteId]
end

function ZO_PlayerEmote_Manager:MarkEmoteListDirty()
    self.listDirty = true
    self:FireCallbacks("EmoteListUpdated")
end

function ZO_PlayerEmote_Manager:CleanEmoteList()
    if self.listDirty then
        self:BuildEmoteList()
    end
end

function ZO_PlayerEmote_Manager:BuildEmoteList()
    self.listDirty = false

    ZO_ClearTable(self.emoteList)
    ZO_ClearTable(self.emoteCategories)
    ZO_ClearNumericallyIndexedTable(self.emoteCategoryTypes)

    for emoteIndex = 1, GetNumEmotes() do
        local lockedByCollectibleId = GetEmoteCollectibleId(emoteIndex)
        local collectibleData  = lockedByCollectibleId and ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(lockedByCollectibleId)
        if not collectibleData or collectibleData:IsUnlocked() then
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

                if collectibleData then
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
        emoteSortFunction = function(...) return self:CompareEmotesGamepad(...) end
    else
        emoteSortFunction = function(...) return self:CompareEmotesKeyboard(...) end
    end

    for _, emoteList in pairs(self.emoteCategories) do
        table.sort(emoteList, emoteSortFunction)
    end

    table.sort(self.emoteCategoryTypes, CompareCategories)
end

function ZO_PlayerEmote_Manager:GetEmoteListForType(emoteType, optFilterFunction)
    self:CleanEmoteList()

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

function ZO_PlayerEmote_Manager:GetEmoteCategories()
    self:CleanEmoteList()

    return self.emoteCategoryTypes
end

do
    local SHARED_EMOTE_EMPTY_SLOT_ICON_PATH = "EsoUI/Art/Quickslots/quickslot_emptySlot.dds"
    function ZO_PlayerEmote_Manager:GetSharedEmoteIconForCategory(category)
        return GetSharedEmoteIconForCategory(category) or SHARED_EMOTE_EMPTY_SLOT_ICON_PATH
    end

    function ZO_PlayerEmote_Manager:GetSharedPersonalityEmoteIconForCategory(category)
        return GetSharedPersonalityEmoteIconForCategory(category) or SHARED_EMOTE_EMPTY_SLOT_ICON_PATH
    end
end

-- Globals
-------------------------------------------------------------
PLAYER_EMOTE_MANAGER = ZO_PlayerEmote_Manager:New()