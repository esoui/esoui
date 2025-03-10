--
--[[ Item Preview Options Fragment]]--
--

ZO_ItemPreviewOptionsFragment = ZO_SceneFragment:Subclass()

function ZO_ItemPreviewOptionsFragment:New(...)
    return ZO_SceneFragment.New(self, ...)
end

function ZO_ItemPreviewOptionsFragment:Initialize(options)
    self.options = options
end

function ZO_ItemPreviewOptionsFragment:Show()
    local itemPreviewObject = SYSTEMS:GetObject("itemPreview")
    local options = self.options
    if options.forcePreparePreview ~= nil then
        itemPreviewObject:SetForcePreparePreview(options.forcePreparePreview)
    else
        itemPreviewObject:SetForcePreparePreview(true)
    end

    if options.paddingLeft ~= nil and options.paddingRight ~= nil then
        itemPreviewObject:SetHorizontalPaddings(options.paddingLeft, options.paddingRight)
    else
        itemPreviewObject:SetHorizontalPaddings(0, 0)
    end

    if options.previewBufferMS ~= nil then
        itemPreviewObject:SetPreviewBufferMS(options.previewBufferMS)
    else
        itemPreviewObject:SetPreviewBufferMS(nil)
    end

    if options.dynamicFramingConsumedWidth ~= nil and options.dynamicFramingConsumedHeight ~= nil then
        itemPreviewObject:SetDynamicFramingConsumedSpace(options.dynamicFramingConsumedWidth, options.dynamicFramingConsumedHeight)
    else
        itemPreviewObject:SetDynamicFramingConsumedSpace(0, 0)
    end

    if options.previewInEmptyWorld ~= nil then
        itemPreviewObject:SetPreviewInEmptyWorld(options.previewInEmptyWorld)
    else
        itemPreviewObject:SetPreviewInEmptyWorld(false)
    end

    if itemPreviewObject:GetFragment():IsShowing() then
        itemPreviewObject:RefreshState()
    end
    self:OnShown()
end

function ZO_ItemPreviewOptionsFragment:Hide()
    self:OnHidden()
end

--
--[[ Item Preview Type]]--
--

ZO_ItemPreviewType = ZO_CallbackObject:Subclass()

function ZO_ItemPreviewType:New()
    return ZO_CallbackObject.New(self)
end

function ZO_ItemPreviewType:SetStaticParameters()
    --Override
    assert(false)
end

function ZO_ItemPreviewType:ResetStaticParameters()
    --Override
    assert(false)
end

function ZO_ItemPreviewType:HasStaticParameters()
    --Override
    assert(false)
end

function ZO_ItemPreviewType:Apply(variationIndex)
    --Override
    assert(false)
end


function ZO_ItemPreviewType:ApplyAction(actionIndex)
    --Can be overridden
end

function ZO_ItemPreviewType:GetNumVariations()
    return 0
end

function ZO_ItemPreviewType:GetVariationName(variationIndex)
    return ""
end

function ZO_ItemPreviewType:GetNumActions(variationIndex)
    return 0
end

function ZO_ItemPreviewType:GetActionName(variationIndex, actionIndex)
    return ""
end

-- Market Product Preview

ZO_ItemPreviewType_MarketProduct = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_MarketProduct:SetStaticParameters(marketProductId)
    self.marketProductId = marketProductId
end

function ZO_ItemPreviewType_MarketProduct:ResetStaticParameters()
    self.marketProductId = 0
end

function ZO_ItemPreviewType_MarketProduct:HasStaticParameters(marketProductId)
    return self.marketProductId == marketProductId
end

function ZO_ItemPreviewType_MarketProduct:Apply(variationIndex)
    PreviewMarketProduct(self.marketProductId, variationIndex)
end

function ZO_ItemPreviewType_MarketProduct:ApplyAction(actionIndex)
    PreviewMarketProductCollectibleAction(self.marketProductId, actionIndex)
end

function ZO_ItemPreviewType_MarketProduct:GetNumVariations()
    return GetNumMarketProductPreviewVariations(self.marketProductId)
end

function ZO_ItemPreviewType_MarketProduct:GetVariationName(variationIndex)
    local previewVariationDisplayName = GetMarketProductPreviewVariationDisplayName(self.marketProductId, variationIndex)
    if previewVariationDisplayName == "" then
        return tostring(variationIndex)
    else
        return previewVariationDisplayName
    end
end

function ZO_ItemPreviewType_MarketProduct:GetNumActions(variationIndex)
    return GetNumMarketProductCollectiblePreviewActions(self.marketProductId, variationIndex)
end

function ZO_ItemPreviewType_MarketProduct:GetActionName(variationIndex, actionIndex)
    local previewActionDisplayName = GetMarketProductCollectiblePreviewActionDisplayName(self.marketProductId, variationIndex, actionIndex)
    if previewActionDisplayName == "" then
        return tostring(actionIndex)
    else
        return previewActionDisplayName
    end
end

-- Furniture Market Product Preview
ZO_ItemPreviewType_FurnitureMarketProduct = ZO_ItemPreviewType_MarketProduct:Subclass()

function ZO_ItemPreviewType_FurnitureMarketProduct:Apply(variationIndex)
    PreviewFurnitureMarketProduct(self.marketProductId, variationIndex)
end

-- Collectible As Furniture

ZO_ItemPreviewType_CollectibleAsFurniture = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_CollectibleAsFurniture:SetStaticParameters(collectibleId)
    self.collectibleId = collectibleId
end

function ZO_ItemPreviewType_CollectibleAsFurniture:ResetStaticParameters()
    self.collectibleId = 0
end

function ZO_ItemPreviewType_CollectibleAsFurniture:HasStaticParameters(collectibleId)
    return self.collectibleId == collectibleId
end

function ZO_ItemPreviewType_CollectibleAsFurniture:Apply(variationIndex)
    PreviewCollectibleAsFurniture(self.collectibleId, variationIndex)
end

function ZO_ItemPreviewType_CollectibleAsFurniture:GetNumVariations()
    return GetNumCollectibleAsFurniturePreviewVariations(self.collectibleId)
end

function ZO_ItemPreviewType_CollectibleAsFurniture:GetVariationName(variationIndex)
    return GetCollectibleAsFurniturePreviewVariationDisplayName(self.collectibleId, variationIndex)
end

-- Placed Furniture

ZO_ItemPreviewType_PlacedFurniture = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_PlacedFurniture:SetStaticParameters(furnitureId)
    self.furnitureId = furnitureId
end

function ZO_ItemPreviewType_PlacedFurniture:ResetStaticParameters()
    self.furnitureId = 0
end

function ZO_ItemPreviewType_PlacedFurniture:HasStaticParameters(furnitureId)
    return self.furnitureId == furnitureId
end

function ZO_ItemPreviewType_PlacedFurniture:Apply(variationIndex)
    PreviewPlacedFurniture(self.furnitureId, variationIndex)
end

function ZO_ItemPreviewType_PlacedFurniture:GetNumVariations()
    return GetNumPlacedFurniturePreviewVariations(self.furnitureId)
end

function ZO_ItemPreviewType_PlacedFurniture:GetVariationName(variationIndex)
    return GetPlacedFurniturePreviewVariationDisplayName(self.furnitureId, variationIndex)
end

-- Provisioner Item as Furniture

ZO_ItemPreviewType_ProvisionerItemAsFurniture = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_ProvisionerItemAsFurniture:SetStaticParameters(recipeListIndex, recipeIndex)
    self.recipeListIndex = recipeListIndex
    self.recipeIndex = recipeIndex
end

function ZO_ItemPreviewType_ProvisionerItemAsFurniture:ResetStaticParameters()
    self.recipeListIndex = 0
    self.recipeIndex = 0
end

function ZO_ItemPreviewType_ProvisionerItemAsFurniture:HasStaticParameters(recipeListIndex, recipeIndex)
    return self.recipeListIndex == recipeListIndex and self.recipeIndex == recipeIndex
end

function ZO_ItemPreviewType_ProvisionerItemAsFurniture:Apply(variationIndex)
    PreviewProvisionerItemAsFurniture(self.recipeListIndex, self.recipeIndex, variationIndex)
end

function ZO_ItemPreviewType_ProvisionerItemAsFurniture:GetNumVariations()
    return GetNumProvisionerItemAsFurniturePreviewVariations(self.recipeListIndex, self.recipeIndex)
end

function ZO_ItemPreviewType_ProvisionerItemAsFurniture:GetVariationName(variationIndex)
    return GetProvisionerItemAsFurniturePreviewVariationDisplayName(self.recipeListIndex, self.recipeIndex, variationIndex)
end

--Trading House Search Result

ZO_ItemPreviewType_TradingHouseSearchResult = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_TradingHouseSearchResult:SetStaticParameters(tradingHouseIndex)
    self.tradingHouseIndex = tradingHouseIndex
end

function ZO_ItemPreviewType_TradingHouseSearchResult:ResetStaticParameters()
    self.tradingHouseIndex = 0
end

function ZO_ItemPreviewType_TradingHouseSearchResult:HasStaticParameters(tradingHouseIndex)
    return self.tradingHouseIndex == tradingHouseIndex
end

function ZO_ItemPreviewType_TradingHouseSearchResult:Apply(variationIndex)
    PreviewTradingHouseSearchResultItem(self.tradingHouseIndex, variationIndex)
end

function ZO_ItemPreviewType_TradingHouseSearchResult:ApplyAction(actionIndex)
    PreviewTradingHouseSearchResultItemCollectibleAction(self.tradingHouseIndex, actionIndex)
end

function ZO_ItemPreviewType_TradingHouseSearchResult:GetNumVariations()
    return GetNumTradingHouseSearchResultItemPreviewVariations(self.tradingHouseIndex)
end

function ZO_ItemPreviewType_TradingHouseSearchResult:GetVariationName(variationIndex)
    return GetTradingHouseSearchResultItemPreviewVariationDisplayName(self.tradingHouseIndex, variationIndex)
end

function ZO_ItemPreviewType_TradingHouseSearchResult:GetNumActions(variationIndex)
    return GetNumTradingHouseSearchResultItemPreviewCollectibleActions(self.tradingHouseIndex, variationIndex)
end

function ZO_ItemPreviewType_TradingHouseSearchResult:GetActionName(variationIndex, actionIndex)
    local previewActionDisplayName = GetTradingHouseSearchResultItemPreviewCollectibleActionDisplayName(self.tradingHouseIndex, variationIndex, actionIndex)
    if previewActionDisplayName == "" then
        return tostring(actionIndex)
    else
        return previewActionDisplayName
    end
end

-- Store

ZO_ItemPreviewType_StoreEntry = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_StoreEntry:SetStaticParameters(storeEntryIndex)
    self.storeEntryIndex = storeEntryIndex
end

function ZO_ItemPreviewType_StoreEntry:ResetStaticParameters()
    self.storeEntryIndex = 0
end

function ZO_ItemPreviewType_StoreEntry:HasStaticParameters(storeEntryIndex)
    return self.storeEntryIndex == storeEntryIndex
end

function ZO_ItemPreviewType_StoreEntry:Apply(variationIndex)
    PreviewStoreEntry(self.storeEntryIndex, variationIndex)
end

function ZO_ItemPreviewType_StoreEntry:ApplyAction(actionIndex)
    PreviewStoreEntryCollectibleAction(self.storeEntryIndex, actionIndex)
end

function ZO_ItemPreviewType_StoreEntry:GetNumVariations()
    return GetNumStoreEntryPreviewVariations(self.storeEntryIndex)
end

function ZO_ItemPreviewType_StoreEntry:GetVariationName(variationIndex)
    return GetStoreEntryPreviewVariationDisplayName(self.storeEntryIndex, variationIndex)
end

function ZO_ItemPreviewType_StoreEntry:GetNumActions(variationIndex)
    return GetNumStoreEntryPreviewCollectibleActions(self.storeEntryIndex, variationIndex)
end

function ZO_ItemPreviewType_StoreEntry:GetActionName(variationIndex, actionIndex)
    local previewActionDisplayName = GetStoreEntryPreviewCollectibleActionDisplayName(self.storeEntryIndex, variationIndex, actionIndex)
    if previewActionDisplayName == "" then
        return tostring(actionIndex)
    else
        return previewActionDisplayName
    end
end

-- Outfit

ZO_ItemPreviewType_Outfit = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_Outfit:SetStaticParameters(actorCategory, outfitIndex)
    self.actorCategory = actorCategory
    self.outfitIndex = outfitIndex
end

function ZO_ItemPreviewType_Outfit:ResetStaticParameters()
    self.actorCategory = GAMEPLAY_ACTOR_CATEGORY_PLAYER
    self.outfitIndex = 0
end

function ZO_ItemPreviewType_Outfit:HasStaticParameters(actorCategory, outfitIndex)
    return self.actorCategory == actorCategory and self.outfitIndex == outfitIndex
end

function ZO_ItemPreviewType_Outfit:Apply()
    if self.outfitIndex then
        SetPreviewingOutfitIndexInPreviewCollection(self.actorCategory, self.outfitIndex)
    else
        SetPreviewingUnequippedOutfitInPreviewCollection(self.actorCategory)
    end
end

-- Reward

ZO_ItemPreviewType_Reward = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_Reward:SetStaticParameters(rewardId)
    self.rewardId = rewardId
end

function ZO_ItemPreviewType_Reward:ResetStaticParameters()
    self.rewardId = 0
end

function ZO_ItemPreviewType_Reward:HasStaticParameters(rewardId)
    return self.rewardId == rewardId
end

function ZO_ItemPreviewType_Reward:Apply(variationIndex)
    PreviewReward(self.rewardId, variationIndex)
end

function ZO_ItemPreviewType_Reward:ApplyAction(actionIndex)
    PreviewRewardCollectibleAction(self.rewardId, actionIndex)
end

function ZO_ItemPreviewType_Reward:GetNumVariations()
    return GetNumRewardPreviewVariations(self.rewardId)
end

function ZO_ItemPreviewType_Reward:GetVariationName(variationIndex)
    return GetRewardPreviewVariationDisplayName(self.rewardId, variationIndex)
end

function ZO_ItemPreviewType_Reward:GetNumActions(variationIndex)
    return GetNumRewardPreviewCollectibleActions(self.rewardId, variationIndex)
end

function ZO_ItemPreviewType_Reward:GetActionName(variationIndex, actionIndex)
    return GetRewardPreviewCollectibleActionDisplayName(self.rewardId, variationIndex, actionIndex)
end

-- Inventory Item
ZO_ItemPreviewType_InventoryItem = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_InventoryItem:SetStaticParameters(bag, slot)
    self.bag = bag
    self.slot = slot
end

function ZO_ItemPreviewType_InventoryItem:ResetStaticParameters()
    self.bag = 0
    self.slot = 0
end

function ZO_ItemPreviewType_InventoryItem:HasStaticParameters(bag, slot)
    return self.bag == bag and self.slot == slot
end

function ZO_ItemPreviewType_InventoryItem:Apply(variationIndex)
    PreviewInventoryItem(self.bag, self.slot, variationIndex)
end

function ZO_ItemPreviewType_InventoryItem:ApplyAction(actionIndex)
    PreviewInventoryItemCollectibleAction(self.bag, self.slot, actionIndex)
end

function ZO_ItemPreviewType_InventoryItem:GetNumVariations()
    return GetNumInventoryItemPreviewVariations(self.bag, self.slot)
end

function ZO_ItemPreviewType_InventoryItem:GetVariationName(variationIndex)
    return GetInventoryItemPreviewVariationDisplayName(self.bag, self.slot, variationIndex)
end

function ZO_ItemPreviewType_InventoryItem:GetNumActions(variationIndex)
    return GetNumInventoryItemPreviewCollectibleActions(self.bag, self.slot, variationIndex)
end

function ZO_ItemPreviewType_InventoryItem:GetActionName(variationIndex, actionIndex)
    return GetInventoryItemPreviewCollectibleActionDisplayName(self.bag, self.slot, variationIndex, actionIndex)
end

-- Collectible

ZO_ItemPreviewType_Collectible = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_Collectible:SetStaticParameters(collectibleId)
    self.collectibleId = collectibleId
end

function ZO_ItemPreviewType_Collectible:ResetStaticParameters()
    self.collectibleId = 0
end

function ZO_ItemPreviewType_Collectible:HasStaticParameters(collectibleId)
    return self.collectibleId == collectibleId
end

function ZO_ItemPreviewType_Collectible:Apply(variationIndex)
    PreviewCollectible(self.collectibleId, variationIndex)
end

function ZO_ItemPreviewType_Collectible:ApplyAction(actionIndex)
    PreviewCollectibleAction(self.collectibleId, actionIndex)
end

function ZO_ItemPreviewType_Collectible:GetNumVariations()
    return GetNumCollectiblePreviewVariations(self.collectibleId)
end

function ZO_ItemPreviewType_Collectible:GetVariationName(variationIndex)
    return GetCollectiblePreviewVariationDisplayName(self.collectibleId, variationIndex)
end

function ZO_ItemPreviewType_Collectible:GetNumActions(variationIndex)
    return GetNumCollectiblePreviewActions(self.collectibleId, variationIndex)
end

function ZO_ItemPreviewType_Collectible:GetActionName(variationIndex, actionIndex)
    return GetCollectiblePreviewActionDisplayName(self.collectibleId, variationIndex, actionIndex)
end

--
--[[ Item Preview]]--
--

ZO_ITEM_PREVIEW_MARKET_PRODUCT = 1
ZO_ITEM_PREVIEW_COLLECTIBLE_AS_FURNITURE = 2
ZO_ITEM_PREVIEW_PLACED_FURNITURE = 3
ZO_ITEM_PREVIEW_PROVISIONER_ITEM_AS_FURNITURE = 4
ZO_ITEM_PREVIEW_FURNITURE_MARKET_PRODUCT = 5
ZO_ITEM_PREVIEW_TRADING_HOUSE_SEARCH_RESULT = 6
ZO_ITEM_PREVIEW_STORE_ENTRY = 7
ZO_ITEM_PREVIEW_OUTFIT = 8
ZO_ITEM_PREVIEW_REWARD = 9
ZO_ITEM_PREVIEW_INVENTORY_ITEM = 10
ZO_ITEM_PREVIEW_COLLECTIBLE = 11

ZO_ITEM_PREVIEW_WAIT_TIME_MS = 500

ZO_ITEM_PREVIEW_PLAY_CLICK_SOUND = true

ZO_ItemPreview_Shared = ZO_InitializingCallbackObject:Subclass()

function ZO_ItemPreview_Shared:Initialize(control)
    self.control = control
    
    self.canChangePreview = true
    self.lastSetChangeTime = 0
    self.currentPreviewType = 0

    self.fragment = ZO_SimpleSceneFragment:New(control)
    self.fragment:SetHideOnSceneHidden(true)
    self.fragment:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)

    self.previewTypeObjects =
    {
        [ZO_ITEM_PREVIEW_MARKET_PRODUCT] = ZO_ItemPreviewType_MarketProduct:New(),
        [ZO_ITEM_PREVIEW_COLLECTIBLE_AS_FURNITURE] = ZO_ItemPreviewType_CollectibleAsFurniture:New(),
        [ZO_ITEM_PREVIEW_PLACED_FURNITURE] = ZO_ItemPreviewType_PlacedFurniture:New(),
        [ZO_ITEM_PREVIEW_PROVISIONER_ITEM_AS_FURNITURE] = ZO_ItemPreviewType_ProvisionerItemAsFurniture:New(),
        [ZO_ITEM_PREVIEW_FURNITURE_MARKET_PRODUCT] = ZO_ItemPreviewType_FurnitureMarketProduct:New(),
        [ZO_ITEM_PREVIEW_TRADING_HOUSE_SEARCH_RESULT] = ZO_ItemPreviewType_TradingHouseSearchResult:New(),
        [ZO_ITEM_PREVIEW_STORE_ENTRY] = ZO_ItemPreviewType_StoreEntry:New(),
        [ZO_ITEM_PREVIEW_OUTFIT] = ZO_ItemPreviewType_Outfit:New(),
        [ZO_ITEM_PREVIEW_REWARD] = ZO_ItemPreviewType_Reward:New(),
        [ZO_ITEM_PREVIEW_INVENTORY_ITEM] = ZO_ItemPreviewType_InventoryItem:New(),
        [ZO_ITEM_PREVIEW_COLLECTIBLE] = ZO_ItemPreviewType_Collectible:New(),
    }

    self.forcePreparePreview = true
    self:SetHorizontalPaddings(0, 0)
    self:SetDynamicFramingConsumedSpace(0, 0)
    self:SetPreviewInEmptyWorld(false)

    self.OnScreenResized = function()
        self:RefreshDynamicFramingOpening()
    end

    local function SetupPreviewOnReady()
        if self.waitingForPreviewBegin then
            self:SetupPreview()
        end
    end

    self.control:RegisterForEvent(EVENT_ITEM_PREVIEW_READY, SetupPreviewOnReady)
end

function ZO_ItemPreview_Shared:GetPreviewTypeObject(previewType)
    return self.previewTypeObjects[previewType]
end

function ZO_ItemPreview_Shared:OnStateChanged(oldState, newState)
    if newState == SCENE_FRAGMENT_SHOWING then
        self:OnPreviewShowing()
    elseif newState == SCENE_FRAGMENT_SHOWN then
        self:OnPreviewShown()
    elseif newState == SCENE_FRAGMENT_HIDDEN then
        self:OnPreviewHidden()
    end
end

function ZO_ItemPreview_Shared:OnPreviewShowing()
    -- We should always EnablePreview followed by a DisablePreview, but if we show a fragment
    -- before it has become hidden, we will need to make sure we don't reinitialize things
    -- below. It is especially bad to call EnablePreviewMode multiple times because that
    -- increments a counter, but we will only decrement once.
    if self.enabledPreview then
        return
    end
    self.enabledPreview = true

    -- for the first preview we won't put a restriction on when we can preview the next one
    -- previewing a product automatically sets this to false so manually set it to true
    self:SetCanChangePreview(true)

    EnablePreviewMode(self.forcePreparePreview)

    if not GetPreviewModeEnabled() then
        self.waitingForPreviewBegin = true
        return
    end

    self:SetupPreview()
end

function ZO_ItemPreview_Shared:IsPreviewEnabled()
    return self.enabledPreview
end

function ZO_ItemPreview_Shared:SetupPreview()
    self:RefreshDynamicFramingOpening()
    self:RefreshPreviewInEmptyWorld()
    local PREVIEW_UPDATE_INTERVAL_MS = 100
    EVENT_MANAGER:RegisterForUpdate("ZO_ItemPreview_Shared", PREVIEW_UPDATE_INTERVAL_MS, function(...) self:OnUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent("ZO_ItemPreview_Shared", EVENT_SCREEN_RESIZED, self.OnScreenResized)
    self.waitingForPreviewBegin = false

    if self.queuedPreviewData then
        self:SharedPreviewSetup(self.queuedPreviewData.previewType, unpack(self.queuedPreviewData.data))
        self.queuedPreviewData = nil
    end
end

function ZO_ItemPreview_Shared:OnUpdate(currentTimeMs)
    if not self.canChangePreview and (currentTimeMs - self.lastSetChangeTime) > ZO_ITEM_PREVIEW_WAIT_TIME_MS then
        self.lastSetChangeTime = currentTimeMs
        self:SetCanChangePreview(true)
    end

    if self.previewAtMS and currentTimeMs > self.previewAtMS then
        self:Apply()
    end
end

function ZO_ItemPreview_Shared:OnPreviewShown()
    --Override if desired
end

function ZO_ItemPreview_Shared:OnPreviewHidden()
    EVENT_MANAGER:UnregisterForUpdate("ZO_ItemPreview_Shared")
    EVENT_MANAGER:UnregisterForEvent("ZO_ItemPreview_Shared", EVENT_SCREEN_RESIZED)

    -- Order matters here
    self:EndCurrentPreview()
    DisablePreviewMode()
    self.enabledPreview = false

    self.forcePreparePreview = true
    self:SetHorizontalPaddings(0, 0)
    self.previewBufferMS = nil
    self:SetDynamicFramingConsumedSpace(0, 0)
    self:SetPreviewInEmptyWorld(false)
    self.waitingForPreviewBegin = false
    self.queuedPreviewData = nil
end

function ZO_ItemPreview_Shared:ResetCurrentPreviewObject()
    if self.currentPreviewTypeObject then
        self.currentPreviewTypeObject:ResetStaticParameters()
    end
    self.currentPreviewTypeObject = nil
    self.previewAtMS = nil

    self.currentPreviewType = 0
    self.numPreviewVariations = 0
    self.previewVariationIndex = 0
    self.numPreviewActions = 0
    self.previewActionIndex = 0
    self:SetVariationControlsHidden(true)
    self:SetActionControlsHidden(true)
end

function ZO_ItemPreview_Shared:EndCurrentPreview()
    self:ResetCurrentPreviewObject()

    EndCurrentItemPreview()

    self:FireCallbacks("EndCurrentPreview")
end

function ZO_ItemPreview_Shared:ClearPreviewCollection()
    self:ResetCurrentPreviewObject()

    ClearCurrentItemPreviewCollection()

    self:FireCallbacks("ClearPreviewCollection")
end

function ZO_ItemPreview_Shared:RefreshState()
    self:EndCurrentPreview()

    self:RefreshDynamicFramingOpening()
    self:RefreshPreviewInEmptyWorld()
end

function ZO_ItemPreview_Shared:GetFragment()
    return self.fragment
end

function ZO_ItemPreview_Shared:GetPreviewTypeAndData(previewType, ...)
    local previewData = {...}
    if previewType == nil then
        -- For lists that contain list entries of different preview types, the previewType
        -- argument should be nil and each list entry should be a numerically indexed table,
        -- the first element of which must be the individual element's previewType.
        previewType = previewData[1]
        table.remove(previewData, 1)
    end
    return previewType, previewData
end

function ZO_ItemPreview_Shared:SharedPreviewSetup(previewType, ...)
    if self.waitingForPreviewBegin then
        self.queuedPreviewData = 
        {
            previewType = previewType,
            data = {...},
        }
        return
    end

    if not GetPreviewModeEnabled() then
        return
    end

    if self:IsCurrentlyPreviewing(previewType, ...) then
        return
    end

    local data
    previewType, data = self:GetPreviewTypeAndData(previewType, ...)

    self.currentPreviewType = previewType
    if self.currentPreviewTypeObject then
        self.currentPreviewTypeObject:ResetStaticParameters()
    end

    self.currentPreviewTypeObject = self:GetPreviewTypeObject(previewType)
    self.currentPreviewTypeObject:SetStaticParameters(unpack(data))

    self.previewVariationIndex = 1
    self.previewActionIndex = 1

    if IsCharacterPreviewingAvailable() then
        self:ApplyOrBuffer()
        PlaySound(SOUNDS.MARKET_PREVIEW_SELECTED)
    end

    self.numPreviewVariations = self.currentPreviewTypeObject:GetNumVariations()

    if self.numPreviewVariations > 1 then
        self:SetVariationControlsHidden(false)
        self.variationLabel:SetText(self.currentPreviewTypeObject:GetVariationName(self.previewVariationIndex))
    else
        self:SetVariationControlsHidden(true)
    end

    self:SetupActionCarousel()

    self:SetCanChangePreview(false)
end

function ZO_ItemPreview_Shared:IsCurrentlyPreviewing(previewType, ...)
    local data
    previewType, data = self:GetPreviewTypeAndData(previewType, ...)

    return previewType == self.currentPreviewType
           and self.currentPreviewTypeObject
           and self.currentPreviewTypeObject:HasStaticParameters(unpack(data))
end

function ZO_ItemPreview_Shared:PreviewMarketProduct(marketProductId)
    self:SharedPreviewSetup(ZO_ITEM_PREVIEW_MARKET_PRODUCT, marketProductId)
end

function ZO_ItemPreview_Shared:PreviewFurnitureMarketProduct(marketProductId)
    self:SharedPreviewSetup(ZO_ITEM_PREVIEW_FURNITURE_MARKET_PRODUCT, marketProductId)
end

function ZO_ItemPreview_Shared:PreviewCollectibleAsFurniture(collectibleId)
    self:SharedPreviewSetup(ZO_ITEM_PREVIEW_COLLECTIBLE_AS_FURNITURE, collectibleId)
end

function ZO_ItemPreview_Shared:PreviewPlacedFurniture(furnitureId)
    self:SharedPreviewSetup(ZO_ITEM_PREVIEW_PLACED_FURNITURE, furnitureId)
end

function ZO_ItemPreview_Shared:PreviewProvisionerItemAsFurniture(recipeListIndex, recipeIndex)
    self:SharedPreviewSetup(ZO_ITEM_PREVIEW_PROVISIONER_ITEM_AS_FURNITURE, recipeListIndex, recipeIndex)
end

function ZO_ItemPreview_Shared:PreviewTradingHouseSearchResult(tradingHouseIndex)
    self:SharedPreviewSetup(ZO_ITEM_PREVIEW_TRADING_HOUSE_SEARCH_RESULT, tradingHouseIndex)
end

function ZO_ItemPreview_Shared:PreviewStoreEntry(storeEntryIndex)
    self:SharedPreviewSetup(ZO_ITEM_PREVIEW_STORE_ENTRY, storeEntryIndex)
end

function ZO_ItemPreview_Shared:PreviewOutfit(actorCategory, outfitIndex)
    self:SharedPreviewSetup(ZO_ITEM_PREVIEW_OUTFIT, actorCategory, outfitIndex)
end

function ZO_ItemPreview_Shared:PreviewCollectible(collectibleId)
    self:SharedPreviewSetup(ZO_ITEM_PREVIEW_COLLECTIBLE, collectibleId)
end

do
    local UNEQUIPPED_OUTFIT_INDEX = nil

    function ZO_ItemPreview_Shared:PreviewUnequipOutfit(actorCategory)
        self:SharedPreviewSetup(ZO_ITEM_PREVIEW_OUTFIT, actorCategory, UNEQUIPPED_OUTFIT_INDEX)
    end
end

function ZO_ItemPreview_Shared:ResetOutfitPreview()
    if self.currentPreviewType == ZO_ITEM_PREVIEW_OUTFIT then
        self:ResetCurrentPreviewObject()
        ClearPreviewingOutfitIndexInPreviewCollection()
    end
end

function ZO_ItemPreview_Shared:PreviewReward(rewardId)
    self:SharedPreviewSetup(ZO_ITEM_PREVIEW_REWARD, rewardId)
end

function ZO_ItemPreview_Shared:PreviewInventoryItem(bagId, slotIndex)
    self:SharedPreviewSetup(ZO_ITEM_PREVIEW_INVENTORY_ITEM, bagId, slotIndex)
end

function ZO_ItemPreview_Shared:ApplyOrBuffer()
    if self.previewBufferMS then
        if IsCurrentlyPreviewing() then
            self.previewAtMS = GetFrameTimeMilliseconds() + self.previewBufferMS
        else
            self:Apply()
        end
    else
        self:Apply()
    end
end

function ZO_ItemPreview_Shared:Apply()
    self.previewAtMS = nil
    self.currentPreviewTypeObject:Apply(self.previewVariationIndex)
    self.currentPreviewTypeObject:ApplyAction(self.previewActionIndex)
    self.lastSetChangeTime = GetFrameTimeMilliseconds()
    ApplyChangesToPreviewCollectionShown()
    self.oldPreviewVariationIndex = nil
    self.oldPreviewActionIndex = nil
end

function ZO_ItemPreview_Shared:SetCanChangePreview(canChangePreview)
    self.canChangePreview = canChangePreview
    self:FireCallbacks("CanChangePreviewChanged", canChangePreview)
end

function ZO_ItemPreview_Shared:CanChangePreview()
    return self.canChangePreview
end

function ZO_ItemPreview_Shared:PreviewNextVariation()
    if self.numPreviewVariations > 0 then
        self.oldPreviewVariationIndex = self.previewVariationIndex
        self.previewVariationIndex = self.previewVariationIndex + 1

        if self.previewVariationIndex > self.numPreviewVariations then
            self.previewVariationIndex = 1
        end

        self.previewActionIndex = 1

        self:SetupActionCarousel()

        self:ApplyOrBuffer()
    end

    self:SetVariationLabel(self.currentPreviewTypeObject:GetVariationName(self.previewVariationIndex))
end

function ZO_ItemPreview_Shared:PreviewPreviousVariation()
    if self.numPreviewVariations > 0 then
        self.oldPreviewVariationIndex = self.previewVariationIndex
        self.previewVariationIndex = self.previewVariationIndex - 1

        if self.previewVariationIndex < 1 then
            self.previewVariationIndex = self.numPreviewVariations
        end

        self.previewActionIndex = 1

        self:SetupActionCarousel()

        self:ApplyOrBuffer()
    end

    self:SetVariationLabel(self.currentPreviewTypeObject:GetVariationName(self.previewVariationIndex))
end

function ZO_ItemPreview_Shared:HasVariations()
    return self.numPreviewVariations > 0
end

function ZO_ItemPreview_Shared:PreviewNextAction()
    if self.numPreviewActions > 0 then
        self.oldPreviewActionIndex = self.previewActionIndex
        self.previewActionIndex = self.previewActionIndex + 1

        if self.previewActionIndex > self.numPreviewActions then
            self.previewActionIndex = 1
        end

        self:ApplyOrBuffer()
    end

    self:SetActionLabel(self.currentPreviewTypeObject:GetActionName(self.previewVariationIndex, self.previewActionIndex))
end

function ZO_ItemPreview_Shared:PreviewPreviousAction()
    if self.numPreviewActions > 0 then
        self.oldPreviewActionIndex = self.previewActionIndex
        self.previewActionIndex = self.previewActionIndex - 1

        if self.previewActionIndex < 1 then
            self.previewActionIndex = self.numPreviewActions
        end

        self:ApplyOrBuffer()
    end

    self:SetActionLabel(self.currentPreviewTypeObject:GetActionName(self.previewVariationIndex, self.previewActionIndex))
end

function ZO_ItemPreview_Shared:HasActions()
    return self.numPreviewActions > 0
end

function ZO_ItemPreview_Shared:SetupActionCarousel()
    self.numPreviewActions = self.currentPreviewTypeObject:GetNumActions(self.previewVariationIndex)

    if self.numPreviewActions > 1 then
        self:SetActionControlsHidden(false)
        self.actionLabel:SetText(self.currentPreviewTypeObject:GetActionName(self.previewVariationIndex, self.previewActionIndex))
    else
        self:SetActionControlsHidden(true)
    end
end

function ZO_ItemPreview_Shared:SetForcePreparePreview(forcePreparePreview)
    self.forcePreparePreview = forcePreparePreview
end

function ZO_ItemPreview_Shared:SetDynamicFramingConsumedSpace(consumedWidth, consumedHeight)
    self.dynamicFramingConsumedWidth = consumedWidth
    self.dynamicFramingConsumedHeight = consumedHeight
    self:RefreshDynamicFramingOpening()
end

do
    local DYNAMIC_FRAMING_ANGLE_RADIANS = -0.4
    function ZO_ItemPreview_Shared:RefreshDynamicFramingOpening()
        if self.fragment:IsShowing() then
            local guiWidth, guiHeight = GuiRoot:GetDimensions()
            local openingWidth = guiWidth - self.dynamicFramingConsumedWidth
            local openingHeight = guiHeight - self.dynamicFramingConsumedHeight
            SetPreviewDynamicFramingOpening(openingWidth, openingHeight, DYNAMIC_FRAMING_ANGLE_RADIANS)
        end
    end
end

function ZO_ItemPreview_Shared:SetPreviewInEmptyWorld(previewInEmptyWorld)
    self.previewInEmptyWorld = previewInEmptyWorld
    self:RefreshPreviewInEmptyWorld()
end

do
    local EMPTY_WORLD_PREVIEW_SUN_AZIMUTH_RADIANS = math.rad(135)
    local EMPTY_WORLD_PREVIEW_SUN_ELEVATION_RADIANS = math.rad(45)

    function ZO_ItemPreview_Shared:RefreshPreviewInEmptyWorld()
        if self.previewInEmptyWorld then
            SetPreviewInEmptyWorld(EMPTY_WORLD_PREVIEW_SUN_AZIMUTH_RADIANS, EMPTY_WORLD_PREVIEW_SUN_ELEVATION_RADIANS)
        end
    end
end

function ZO_ItemPreview_Shared:IsInteractionCameraPreviewEnabled()
    return GetInteractionType() ~= INTERACTION_NONE and not IsInteractionUsingInteractCamera()
end

function ZO_ItemPreview_Shared:ToggleInteractionCameraPreview(framingTargetFragment, framingFragment, previewOptionsFragment)
    self:SetInteractionCameraPreviewEnabled(not self:IsInteractionCameraPreviewEnabled(), framingTargetFragment, framingFragment, previewOptionsFragment)
end

function ZO_ItemPreview_Shared:SetInteractionCameraPreviewEnabled(enabled, framingTargetFragment, framingFragment, previewOptionsFragment)
    if enabled ~= self:IsInteractionCameraPreviewEnabled() then
        if enabled then
            SetInteractionUsingInteractCamera(false)
            SCENE_MANAGER:AddFragment(framingTargetFragment)
            SCENE_MANAGER:AddFragment(framingFragment)
            SCENE_MANAGER:AddFragment(previewOptionsFragment)
            SCENE_MANAGER:AddFragment(self.fragment)
        else
            --We want the preview to end instantly in the toggle case but on scene hidden otherwise. If it ends instantly when the scene hides
            --there will be a 200ms window where it tries to go back into the interact camera then exits the scene and goes into the game camera.
            --The two fragments that are important for continuing the preview until the scene is hidden are the preview fragment (self.fragment)
            --and the framing fragment.
            SCENE_MANAGER:RemoveFragmentImmediately(self.fragment)
            SCENE_MANAGER:RemoveFragment(previewOptionsFragment)
            SCENE_MANAGER:RemoveFragmentImmediately(framingFragment)
            SCENE_MANAGER:RemoveFragment(framingTargetFragment)

            SetInteractionUsingInteractCamera(true)
        end
    end
end

function ZO_ItemPreview_Shared:SetVariationControlsHidden(shouldHide)
    -- optional override
end

function ZO_ItemPreview_Shared:SetVariationLabel(variationName)
    -- optional override
end

function ZO_ItemPreview_Shared:SetActionControlsHidden(shouldHide)
    -- optional override
end

function ZO_ItemPreview_Shared:SetActionLabel(actionName)
    -- optional override
end

function ZO_ItemPreview_Shared:SetHorizontalPaddings(paddingLeft, paddingRight)
    --override
    assert(false)
end

function ZO_ItemPreview_Shared:SetPreviewBufferMS(previewBufferMS)
    self.previewBufferMS = previewBufferMS
end

function ZO_ItemPreview_Shared.CanItemLinkBePreviewedAsFurniture(itemLink)
    local itemType, specializedItemType = GetItemLinkItemType(itemLink)
    if itemType == ITEMTYPE_FURNISHING then
        return specializedItemType ~= SPECIALIZED_ITEMTYPE_FURNISHING_ATTUNABLE_STATION
    elseif itemType == ITEMTYPE_RECIPE then
        return IsItemLinkFurnitureRecipe(itemLink)
    end

    local collectibleId = GetCollectibleIdFromLink(itemLink)
    if collectibleId and collectibleId > 0 then
        local furnitureDataId = GetCollectibleFurnitureDataIdForPreview(collectibleId)
        if furnitureDataId > 0 then
            return true
        end
    end

    return false
end
