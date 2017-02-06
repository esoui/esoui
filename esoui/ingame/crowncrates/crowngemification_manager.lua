ZO_Gemifiable = ZO_Object:Subclass()

function ZO_Gemifiable:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

--where ... is market product ids
function ZO_Gemifiable:Initialize(name, icon, count, requiredPerConversion, gemsAwardedPerConversion, ...)
    self.name = name
    self.icon = icon
    self.requiredPerConversion = requiredPerConversion
    self.gemsAwardedPerConversion = gemsAwardedPerConversion
    self:UpdateFromOfficialCount(count)

    for i = 1, select("#", ...) do
        local marketProductId = select(i, ...)
        local rewardName, rewardTypeText, cardFaceImage, cardFaceFrameAccentImage = GetMarketProductCrownCrateRewardInfo(marketProductId)
        if cardFaceImage ~= ZO_NO_TEXTURE_FILE and cardFaceFrameAccentImage ~= ZO_NO_TEXTURE_FILE then
            self.faceImage = cardFaceImage
            self.frameImage = cardFaceFrameAccentImage
            self.crownCrateTierId = GetMarketProductCrownCrateTierId(marketProductId)
            break
        end
    end

    if self.crownCrateTierId ~= 0 then
        self.rewardQualityColor = ZO_ColorDef:New(GetCrownCrateTierQualityColor(self.crownCrateTierId))
    else
        self.rewardQualityColor = ZO_WHITE
    end
end

function ZO_Gemifiable:UpdateFromOfficialCount(officialCount)
    if self.lastOfficialCount then
        local serverConfirmedLoss = self.lastOfficialCount - officialCount
        if serverConfirmedLoss > 0 then
            self.countChangeInFlight = zo_max(self.countChangeInFlight - serverConfirmedLoss, 0)
        end
    else
        self.countChangeInFlight = 0
    end
    self.lastOfficialCount = officialCount

    self.count = zo_max(officialCount - self.countChangeInFlight, 0)
    self.maxGemifies = zo_floor(self.count / self.requiredPerConversion)
    self.gemTotal = self.maxGemifies * self.gemsAwardedPerConversion
end

--There is a disjoint between the client visuals and the server backend for this system. When we gemify here we update all of the client
--visuals immediately to show a success. However, we don't send the request for up to a second to pool requests together (if the user is
--wailing on the gemify bind) and it will even take a round trip after that to get the updated inventory information. So we update assuming success
--here and then we end up getting the real update later. When the real update comes in we discount how much we think we have in flight by how much
--we confirmed to have just destroyed. By the time this all resolves we should have nothing in flight and be synched up with the server.
function ZO_Gemifiable:ClientSideUpdate(amountConsumed)
    amountConsumed = zo_min(self.count, amountConsumed)
    self.count = self.count - amountConsumed
    self.maxGemifies = zo_floor(self.count / self.requiredPerConversion)
    self.gemTotal = self.maxGemifies * self.gemsAwardedPerConversion
    self.countChangeInFlight = self.countChangeInFlight + amountConsumed
    self.lastClientSideUpdateMS = GetGameTimeMilliseconds()
    CROWN_GEMIFICATION_MANAGER:FireCallbacks("GemifiableChanged", self)
end

--If something crazy happened and we think we're waiting on the server to destroy something but several seconds later we hear nothing than
--we'll trigger a rebuild to clean everything up. This is a fail safe for some exotic cases.
local OUT_OF_SYNC_INTERVAL = 4000
function ZO_Gemifiable:IsOutOfSync(timeMS)
    if self.countChangeInFlight > 0 and
        self.lastClientSideUpdateMS ~= nil and 
        timeMS > self.lastClientSideUpdateMS + OUT_OF_SYNC_INTERVAL then
        return true
    else
        return false
    end
end

function ZO_Gemifiable:GemifyOne()
    self:Gemify(self.requiredPerConversion)
    self:ClientSideUpdate(self.requiredPerConversion)
end

function ZO_Gemifiable:GemifyAll()
    local amount = self.maxGemifies * self.requiredPerConversion
    self:Gemify(amount)
    self:ClientSideUpdate(amount)
end

function ZO_Gemifiable:Gemify(amount)
    --Override
end

function ZO_Gemifiable:LayoutKeyboardTooltip()
    --Override
end

function ZO_Gemifiable:LayoutGamepadTooltip()
    --Override
end

--Item

ZO_GemifiableItem = ZO_Gemifiable:Subclass()

function ZO_GemifiableItem:New(...)
    local object = ZO_Gemifiable.New(self, ...)
    object:Initialize(...)
    return object
end

function ZO_GemifiableItem:Initialize(bag, slot, count)
    --Have to use the item API instead of the shared inventory slot here because we generate the virtual item stacks using the
    --item API which is updated sooner than shared inventory (which waits for events a frame later to update its cache).
    local name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bag, slot))
    local icon = GetItemInfo(bag, slot)
    local itemsRequiredPerConversion, gemsAwardedPerConversion = GetNumCrownGemsFromItemManualGemification(bag, slot)
    self.itemId = GetItemId(bag, slot)
    self.bagId = bag
    self.slotIndex = slot
    local ALL_PRODUCTS = false
    ZO_Gemifiable.Initialize(self, name, icon, count, itemsRequiredPerConversion, gemsAwardedPerConversion, GetMarketProductsForItem(self.itemId, ALL_PRODUCTS))
end

function ZO_GemifiableItem:Gemify(amount)
    GemifyItem(self.itemId, amount)
end

function ZO_GemifiableItem:LayoutKeyboardTooltip()
    InformationTooltip:SetBagItem(self.bagId, self.slotIndex)
end

function ZO_GemifiableItem:LayoutGamepadTooltip()
    GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_RIGHT_TOOLTIP, self.bagId, self.slotIndex)
end

--Manager

ZO_CrownGemification_Manager = ZO_CallbackObject:Subclass()

function ZO_CrownGemification_Manager:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_CrownGemification_Manager:Initialize()    
    self.gemifiables = {}
    self.gemifiableItems = {}
    
    self.IsItemGemmable = function(bagId, slotIndex)
        if IsItemFromCrownCrate(bagId, slotIndex) and not IsItemPlayerLocked(bagId, slotIndex) then
            local itemsRequired, gemsAwarded = GetNumCrownGemsFromItemManualGemification(bagId, slotIndex)
            return gemsAwarded > 0 and itemsRequired > 0
        end
        return false
    end

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", function(bagId) self:OnFullInventoryUpdate(bagId) end)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", function(...) self:OnSingleSlotInventoryUpdate(...) end)
    EVENT_MANAGER:RegisterForUpdate("ZO_CrownGemification_Manager", 500, function() self:OnUpdate() end)
end

function ZO_CrownGemification_Manager:OnUpdate()
    local timeMS = GetGameTimeMilliseconds()
    for _, gemifiable in ipairs(self.gemifiables) do
        if gemifiable:IsOutOfSync(timeMS) then
            self:RefreshItems()
            break
        end
    end
end

function ZO_CrownGemification_Manager:IsRelevantBag(bagId)
    return bagId == BAG_BACKPACK or bagId == BAG_BANK
end

function ZO_CrownGemification_Manager:GetGemifiableList()
    return self.gemifiables
end

function ZO_CrownGemification_Manager:OnFullInventoryUpdate(bagId)
    if self:IsRelevantBag(bagId) then
        self:RefreshItems()
    end
end

function ZO_CrownGemification_Manager:RemoveItemGemifiableInternal(existingGemifiable, itemInstanceId)
    for i, searchGemifiable in ipairs(self.gemifiables) do
        if searchGemifiable == existingGemifiable then
            table.remove(self.gemifiables, i)
            break
        end
    end
    self.gemifiableItems[itemInstanceId] = nil
    self:FireCallbacks("GemifiableListChanged")
end

function ZO_CrownGemification_Manager:OnSingleSlotInventoryUpdate(bagId, slotIndex, previousSlotData)
    if self:IsRelevantBag(bagId) then
        local instanceId = GetItemInstanceId(bagId, slotIndex)
        --If the slot was cleared out or became a new item (like through crafting) and it previously held a gemifiable item...
        if previousSlotData and instanceId ~= previousSlotData.itemInstanceId and self.gemifiableItems[previousSlotData.itemInstanceId] then
            local data = PLAYER_INVENTORY:GenerateVirtualStackedItem(self.IsItemGemmable, previousSlotData.itemInstanceId, INVENTORY_BACKPACK, INVENTORY_BANK)
            local existingGemifiable = self.gemifiableItems[previousSlotData.itemInstanceId]
            --...and there are still more of those items, then just update our info. 
            if data then
                existingGemifiable:Initialize(data.bag, data.index, data.stack)
                self:FireCallbacks("GemifiableChanged", existingGemifiable)
            --...and there are no more of those item, then remove it from the list.
            else
                self:RemoveItemGemifiableInternal(existingGemifiable, previousSlotData.itemInstanceId)
            end
        --Otherwise, the slot was updated (in count or flags) or added so...
        else
            --It might be the case that the slot was updated to become ungemmifiable (like it the player locked it)
            local data = PLAYER_INVENTORY:GenerateVirtualStackedItem(self.IsItemGemmable, instanceId, INVENTORY_BACKPACK, INVENTORY_BANK)
            --...and we have items of this instanceId that we can gemify
            if data then
                --...if we already had info for this kind of item then just update it.
                if self.gemifiableItems[instanceId] then
                    local existingGemifiable = self.gemifiableItems[instanceId]
                    existingGemifiable:Initialize(data.bag, data.index, data.stack)
                    self:FireCallbacks("GemifiableChanged", existingGemifiable)
                --...if we didn't have info then add it to the list.
                elseif self.IsItemGemmable(bagId, slotIndex) then
                    local newGemifiable = ZO_GemifiableItem:New(data.bag, data.index, data.stack)
                    self.gemifiableItems[instanceId] = newGemifiable
                    table.insert(self.gemifiables, newGemifiable)
                    self:FireCallbacks("GemifiableListChanged")
                end
            --...otherwise we didn't find anything with this instanceId to gem so make sure it's cleared out if it existed
            else
                if self.gemifiableItems[instanceId] then
                    local existingGemifiable = self.gemifiableItems[instanceId]
                    self:RemoveItemGemifiableInternal(existingGemifiable, instanceId)
                end
            end
        end
    end
end

function ZO_CrownGemification_Manager:RefreshAll()
    self:BuildGemifiableItems()
    self:BuildGemifiableListFromSystemLists()
end

function ZO_CrownGemification_Manager:RefreshItems()
    self:BuildGemifiableItems()
    self:BuildGemifiableListFromSystemLists()
end

function ZO_CrownGemification_Manager:BuildGemifiableListFromSystemLists()
    ZO_ClearNumericallyIndexedTable(self.gemifiables)
    for _, itemGemifiable in pairs(self.gemifiableItems) do
        table.insert(self.gemifiables, itemGemifiable)
    end

    self:FireCallbacks("GemifiableListChanged")
end

function ZO_CrownGemification_Manager:BuildGemifiableItems()
    ZO_ClearTable(self.gemifiableItems)

    local list = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, self.IsItemGemmable)
    PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BANK, self.IsItemGemmable, list)

    for itemInstanceId, virtualStackData in pairs(list) do
        self.gemifiableItems[itemInstanceId] = ZO_GemifiableItem:New(virtualStackData.bag, virtualStackData.index, virtualStackData.stack)
    end
end

CROWN_GEMIFICATION_MANAGER = ZO_CrownGemification_Manager:New()