ZO_LootScene = ZO_Scene:Subclass()

function ZO_LootScene:New(...)
    return ZO_Scene.New(self, ...)
end

function ZO_LootScene:OnRemovedFromQueue()
    EndLooting()
end


local ZO_Loot_Shared = ZO_Object:Subclass()
function ZO_Loot_Shared:New(...)
    local loot = ZO_Object.New(self)
    loot:Initialize(...)
    return loot
end

function ZO_Loot_Shared:Initialize()
    local function UpdateLootWindow()
        local name, targetType, actionName, isOwned = GetLootTargetInfo()
        if name ~= "" then
            if targetType == INTERACT_TARGET_TYPE_ITEM then
                name = zo_strformat(SI_TOOLTIP_ITEM_NAME, name)
            elseif targetType == INTERACT_TARGET_TYPE_OBJECT then
                name = zo_strformat(SI_LOOT_OBJECT_NAME, name)
            elseif targetType == INTERACT_TARGET_TYPE_FIXTURE then
                name = zo_strformat(SI_TOOLTIP_FIXTURE_INSTANCE, name)
            end
        end

        SYSTEMS:GetObject("loot"):UpdateLootWindow(name, actionName, isOwned)
    end

    local function OnLootReceived(eventCode, receivedBy, objectName, stackCount, soundCategory, lootType, lootedBySelf, questIcon)
        if not lootedBySelf then
            return
        end

        -- Real item sound hooks are handled by the inventory.
        if lootType == LOOT_TYPE_QUEST_ITEM then
            if soundCategory ~= ITEM_SOUND_CATEGORY_NONE then
                PlayItemSound(soundCategory, ITEM_SOUND_ACTION_ACQUIRE)
            end
        end
    end

    local function CloseLootWindow() -- Called when C++ is telling us to close the window.  Don't call CloseLoot.
        self:Hide()
        local CLOSE_LOOT_WINDOW = true
        ZO_PlayLootWindowSound(CLOSE_LOOT_WINDOW)
    end

    local function LootItemFailed(eventCode, reason, itemLink)
        if reason == LOOT_ITEM_RESULT_INVENTORY_FULL or reason == LOOT_ITEM_RESULT_INVENTORY_FULL_LOOT_ALL then
            TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_FULL)
        end
        local itemName = GetItemLinkName(itemLink)
        local itemDisplayQuality = GetItemLinkDisplayQuality(itemLink)
        local qualityColor = GetItemQualityColor(itemDisplayQuality)
        itemName = qualityColor:Colorize(itemName)
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, zo_strformat(GetString("SI_LOOTITEMRESULT", reason), itemName))
    end

    local function OnPlayerDeath()
        EndInteraction(INTERACTION_LOOT)
    end

    local EvtMgr = GetEventManager()
    EvtMgr:RegisterForEvent("LOOT_SHARED", EVENT_LOOT_UPDATED, UpdateLootWindow)
    EvtMgr:RegisterForEvent("LOOT_SHARED", EVENT_LOOT_RECEIVED, OnLootReceived)
    EvtMgr:RegisterForEvent("LOOT_SHARED", EVENT_LOOT_CLOSED, CloseLootWindow)
    EvtMgr:RegisterForEvent("LOOT_SHARED", EVENT_LOOT_ITEM_FAILED, LootItemFailed)
    EvtMgr:RegisterForEvent("LOOT_SHARED", EVENT_PLAYER_DEAD, OnPlayerDeath)
end

function ZO_Loot_Shared:Hide()
    SYSTEMS:GetObject("loot"):Hide()
end

function ZO_Loot_Shared:LootAllItems()
    LootAll(SYSTEMS:GetObject("loot"):AreNonStolenItemsPresent())
end

function ZO_Loot_Shared:GetLootCurrencyInformation()
    local currencyInfo = {}
    for currencyType = CURT_ITERATION_BEGIN, CURT_ITERATION_END do
        if IsCurrencyValid(currencyType) then
            local currencyAmount, stolenCurrencyAmount = GetLootCurrency(currencyType)
            if currencyAmount + stolenCurrencyAmount > 0 then
                currencyInfo[currencyType] =
                    {
                        currencyAmount = currencyAmount,
                        stolenCurrencyAmount = stolenCurrencyAmount,
                    }
            end
        end
    end
    return currencyInfo
end

do
    local STOLEN = true

    local LOOT_SORT_ORDER_CURRENCY = 0
    local LOOT_SORT_ORDER_COLLECTIBLE = 1
    local LOOT_SORT_ORDER_ITEM = 2

    local sortKeys =
    {
        isStolen = { tiebreaker = "sortOrder" },
        sortOrder = { tiebreaker = "displayQuality", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
        displayQuality = { tiebreaker = "sortName", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
        sortName = { tiebreaker = "lootId", caseInsensitive = true },
        lootId = { }
    }
    local function LootSortFunction(left, right)
        return ZO_TableOrderingFunction(left, right, "isStolen", sortKeys, ZO_SORT_ORDER_UP)
    end

    local function CreateCurrencyLootData(currencyType, currencyAmount, isStolen)
        local formattedName
        if IsInGamepadPreferredMode() then
            local IS_UPPER = false
            formattedName = GetCurrencyName(currencyType, IsCountSingularForm(currencyAmount), IS_UPPER)
        else
            formattedName = zo_strformat(SI_LOOT_CURRENCY_FORMAT, ZO_Currency_FormatPlatform(currencyType, currencyAmount, ZO_CURRENCY_FORMAT_AMOUNT_NAME))
        end
        local IS_PLURAL = false
        local IS_UPPER = false
        local sortName = GetCurrencyName(currencyType, IS_PLURAL, IS_UPPER)
        local currencyData =
        {
            currencyType = currencyType,
            currencyAmount = currencyAmount,
            name = formattedName,
            sortName = sortName,
            count = 1,
            displayQuality = ITEM_DISPLAY_QUALITY_NORMAL,
            isStolen = isStolen,
            sortOrder = LOOT_SORT_ORDER_CURRENCY,
            lootId = -1,
        }

        return currencyData
    end

    function ZO_Loot_Shared:GetSortedLootData()
        local lootData = {}

        local lootCurrencyInfo = self:GetLootCurrencyInformation()
        for currencyType, currencyInfo in pairs(lootCurrencyInfo) do
            local nonStolenCurrencyAmount = currencyInfo.currencyAmount
            if nonStolenCurrencyAmount > 0 then
                local currencyData = CreateCurrencyLootData(currencyType, nonStolenCurrencyAmount, not STOLEN)
                table.insert(lootData, currencyData)
            end

            local stolenCurrencyAmount = currencyInfo.stolenCurrencyAmount
            if stolenCurrencyAmount > 0 then
                local currencyData = CreateCurrencyLootData(currencyType, stolenCurrencyAmount, STOLEN)
                table.insert(lootData, currencyData)
            end
        end

        local numLootItems = GetNumLootItems()
        for i = 1, numLootItems do
            local lootId, name, icon, count, displayQuality, value, isQuest, isStolen, lootType = GetLootItemInfo(i)
            local formattedName = zo_strformat(SI_TOOLTIP_ITEM_NAME, name)
            local sortOrder = lootType == LOOT_TYPE_COLLECTIBLE and LOOT_SORT_ORDER_COLLECTIBLE or LOOT_SORT_ORDER_ITEM
            local itemData =
            {
                lootId = lootId,
                name = formattedName,
                sortName = formattedName,
                icon = icon,
                count = count,
                displayQuality = displayQuality,
                -- quality is deprecated, included here for addon backwards compatibility
                quality = displayQuality,
                value = value,
                isQuest = isQuest,
                isStolen = isStolen,
                -- itemType has been lootType for a long time, but we'll keep the tradition alive for compatibility
                itemType = lootType,
                sortOrder = sortOrder,
            }

            table.insert(lootData, itemData)
        end

        table.sort(lootData, LootSortFunction)

        return lootData
    end
end

--[[ Globals ]]--
LOOT_SHARED = ZO_Loot_Shared:New()

function ZO_PlayLootWindowSound(isOpen)
    local isMonster = IsGameCameraInteractableUnitMonster()

    if isMonster then
        local audioModelType, audioModelMaterial, audioModelSize = GetGameCameraInteractableUnitAudioInfo()
        PlayLootSound(audioModelType, isOpen)
    else
        if isOpen then
            PlaySound(SOUNDS.LOOT_WINDOW_CLOSE)
        else
            PlaySound(SOUNDS.LOOT_WINDOW_OPEN)
        end
    end
end