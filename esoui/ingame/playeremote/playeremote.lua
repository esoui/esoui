local function AddEmote(emoteIndex, ...)
    for i = 1, select("#", ...) do
        local cmd = select(i, ...)
        if(SLASH_COMMANDS[cmd] == nil) then
		    SLASH_COMMANDS[cmd] = function() PlayEmoteByIndex(emoteIndex) end
        end
    end
end

local function AddEmotes()
	local numEmotes = GetNumEmotes()
	for emoteIndex = 1, numEmotes, 1 do
        AddEmote(emoteIndex, zo_strsplit(" ", GetEmoteSlashNameByIndex(emoteIndex)))
	end
end

local function OnAddOnLoaded(event, name)
    if name == "ZO_Ingame" then
		AddEmotes()
        EVENT_MANAGER:UnregisterForEvent("PlayerEmote_OnAddOnLoaded", EVENT_ADD_ON_LOADED)
	end
end
     
EVENT_MANAGER:RegisterForEvent("PlayerEmote_OnAddOnLoaded", EVENT_ADD_ON_LOADED, OnAddOnLoaded)


local ZO_PlayerEmoteManager = ZO_CallbackObject:Subclass()

function ZO_PlayerEmoteManager:New(...)
	local playerEmoteManager = ZO_CallbackObject.New(self)
	playerEmoteManager:Initialize(...)
	return playerEmoteManager
end

function ZO_PlayerEmoteManager:Initialize()
	EVENT_MANAGER:RegisterForEvent("ZO_PlayerEmoteManager", EVENT_PERSONALITY_CHANGED, function() self:RefreshPersonalityEmotes() end)
	EVENT_MANAGER:RegisterForEvent("ZO_PlayerEmoteManager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:RefreshPersonalityEmotes() end)
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
    if not self.emoteList then
        self:InitializeEmoteList()
    end
    return self.emoteList[emoteId]
end

function ZO_PlayerEmoteManager:InitializeEmoteList()
    self.emoteList = {}
    self.emoteCategories = {}
    self.emoteCategoryTypes = {}
	self.emotePersonalityCategoryAdded = false

	for emoteIndex = 1, GetNumEmotes() do
        local emoteSlashName, emoteCategory, emoteId, displayName, showInGamepadUI = GetEmoteInfo(emoteIndex)
		local isOverriddenByPersonality = IsPlayerEmoteOverridden(emoteId)

        if emoteSlashName ~= "" then
            if displayName == "" then 
                displayName = string.sub(emoteSlashName,2) --Temp in case data isn't set up.
            end
            if not self.emoteCategories[emoteCategory] then
                self.emoteCategories[emoteCategory] = {}
                table.insert(self.emoteCategoryTypes, emoteCategory)
            end

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
					self.emotePersonalityCategoryAdded = true
				end

				table.insert(self.emoteCategories[EMOTE_CATEGORY_PERSONALITY_OVERRIDE], emoteId)
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
end

function ZO_PlayerEmoteManager:RefreshPersonalityEmotes()
	if not self.emoteCategories then
        self:InitializeEmoteList()
    end

	if self.emoteCategories[EMOTE_CATEGORY_PERSONALITY_OVERRIDE] then
		ZO_ClearNumericallyIndexedTable(self.emoteCategories[EMOTE_CATEGORY_PERSONALITY_OVERRIDE])
	end
	local personalityEmoteAdded = false

	for emoteIndex = 1, GetNumEmotes() do
        local emoteSlashName, emoteCategory, emoteId, displayName, showInGamepadUI = GetEmoteInfo(emoteIndex)
		local isOverriddenByPersonality = IsPlayerEmoteOverridden(emoteId)

        if emoteSlashName ~= "" then
            self.emoteList[emoteId].isOverriddenByPersonality = isOverriddenByPersonality

			if isOverriddenByPersonality then
				if not self.emoteCategories[EMOTE_CATEGORY_PERSONALITY_OVERRIDE] then
					self.emoteCategories[EMOTE_CATEGORY_PERSONALITY_OVERRIDE] = {}
				end

				if not self.emotePersonalityCategoryAdded then
					self.emotePersonalityCategoryAdded = true
					table.insert(self.emoteCategoryTypes, EMOTE_CATEGORY_PERSONALITY_OVERRIDE)
				end

				if displayName == "" then 
					displayName = string.sub(emoteSlashName,2) --Temp in case data isn't set up.
				end

				personalityEmoteAdded = true

				table.insert(self.emoteCategories[EMOTE_CATEGORY_PERSONALITY_OVERRIDE], emoteId)
			end
        end
	end

    if not personalityEmoteAdded and self.emotePersonalityCategoryAdded then
        for i, categoryType in ipairs(self.emoteCategoryTypes) do
            if categoryType == EMOTE_CATEGORY_PERSONALITY_OVERRIDE then
                table.remove(self.emoteCategoryTypes, i)
                self.emotePersonalityCategoryAdded = false
                break
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
end

function ZO_PlayerEmoteManager:GetEmoteListForType(emoteType, optFilterFunction)
    if not self.emoteCategories then
        self:InitializeEmoteList()
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
        self:InitializeEmoteList()
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