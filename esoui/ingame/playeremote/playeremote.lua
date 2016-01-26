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


local ZO_PlayerEmoteManager = ZO_Object:Subclass()

function ZO_PlayerEmoteManager:CompareEmotes(emoteA, emoteB)
    return self:GetEmoteItemInfo(emoteA).displayName < self:GetEmoteItemInfo(emoteB).displayName
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

	for emoteIndex = 1, GetNumEmotes() do
        local emoteSlashName, emoteCategory, emoteId, displayName, showInGamepadUI = GetEmoteInfo(emoteIndex)
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
                                            showInGamepadUI = showInGamepadUI
                                        }

            table.insert(self.emoteCategories[emoteCategory], emoteId)
        end
	end

    for _, emoteList in pairs(self.emoteCategories) do
        table.sort(emoteList, function(emoteA, emoteB) return self:CompareEmotes(emoteA, emoteB) end)
    end

    table.sort(self.emoteCategoryTypes, CompareCategories)
end

local EMOTE_ICON_PATH = "EsoUI/Art/Emotes/Gamepad/gp_emoteIcon_"

local EMOTE_ICONS = {
    [EMOTE_CATEGORY_INVALID]            = "EsoUI/Art/Quickslots/quickslot_emptySlot.dds",
    [EMOTE_CATEGORY_CEREMONIAL]         = EMOTE_ICON_PATH .. "ceremonial.dds",
    [EMOTE_CATEGORY_CHEERS_AND_JEERS]   = EMOTE_ICON_PATH .. "cheersJeers.dds",
    [EMOTE_CATEGORY_DEPRECATED]         = "EsoUI/Art/Quickslots/quickslot_emptySlot.dds",
    [EMOTE_CATEGORY_EMOTION]            = EMOTE_ICON_PATH .. "emotion.dds",
    [EMOTE_CATEGORY_ENTERTAINMENT]      = EMOTE_ICON_PATH .. "entertain.dds",
    [EMOTE_CATEGORY_FOOD_AND_DRINK]     = EMOTE_ICON_PATH .. "eatDrink.dds",
    [EMOTE_CATEGORY_GIVE_DIRECTIONS]    = EMOTE_ICON_PATH .. "direction.dds",
    [EMOTE_CATEGORY_PERPETUAL]          = EMOTE_ICON_PATH .. "perpetual.dds",
    [EMOTE_CATEGORY_PHYSICAL]           = EMOTE_ICON_PATH .. "physical.dds",
    [EMOTE_CATEGORY_POSES_AND_FIDGETS]  = EMOTE_ICON_PATH .. "fidget.dds",
    [EMOTE_CATEGORY_PROP]               = EMOTE_ICON_PATH .. "prop.dds",
    [EMOTE_CATEGORY_SOCIAL]             = EMOTE_ICON_PATH .. "social.dds",
}

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

function ZO_PlayerEmoteManager:GetEmoteIconForCategory(category)
    if EMOTE_ICONS[category] then
        return EMOTE_ICONS[category]
    end
    return EMOTE_ICONS[EMOTE_CATEGORY_INVALID]
end

-- Globals
-------------------------------------------------------------
PLAYER_EMOTE_MANAGER = ZO_PlayerEmoteManager:New()

