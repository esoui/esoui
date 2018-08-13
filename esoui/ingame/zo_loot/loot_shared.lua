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

function ZO_Loot_Shared:Initialize(control)
    self.control = control

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
        ZO_PlayMonsterLootSound(CLOSE_LOOT_WINDOW)
    end

    local function LootItemFailed(eventCode, reason, itemLink)
        if reason == LOOT_ITEM_RESULT_INVENTORY_FULL or reason == LOOT_ITEM_RESULT_INVENTORY_FULL_LOOT_ALL then
            TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_FULL)
        end
        local itemName = GetItemLinkName(itemLink)
        local itemQuality = GetItemLinkQuality(itemLink)
        local qualityColor = GetItemQualityColor(itemQuality)
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

--[[ Globals ]]--
LOOT_SHARED = ZO_Loot_Shared:New(control)

function ZO_PlayMonsterLootSound(isOpen)
    local isMonster = IsGameCameraInteractableUnitMonster()

    if isMonster then
        local audioModelType, audioModelMaterial, audioModelSize = GetGameCameraInteractableUnitAudioInfo()
        PlayLootSound(audioModelType, isOpen)
    end
end