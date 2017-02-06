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
    end
    if options.paddingLeft ~= nil and options.paddingRight ~= nil then
        itemPreviewObject:SetHorizontalPaddings(options.paddingLeft, options.paddingRight)
    end
    if options.previewBufferMS ~= nil then
        itemPreviewObject:SetPreviewBufferMS(options.previewBufferMS)
    end
    if options.dynamicFramingConsumedWidth ~= nil and options.dynamicFramingConsumedHeight ~= nil then
        itemPreviewObject:SetDynamicFramingConsumedSpace(options.dynamicFramingConsumedWidth, options.dynamicFramingConsumedHeight)
    end
    if options.previewInEmptyWorld ~= nil then
        itemPreviewObject:SetPreviewInEmptyWorld(options.previewInEmptyWorld)
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

function ZO_ItemPreviewType:Apply(variationIndex)
    --Override
    assert(false)
end

function ZO_ItemPreviewType:GetNumVariations()
    return 0
end

function ZO_ItemPreviewType:GetVariationName(variationIndex)
    return ""
end

-- Market Product Preview

ZO_ItemPreviewType_MarketProduct = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_MarketProduct:SetStaticParameters(marketProductId)
    self.marketProductId = marketProductId
end

function ZO_ItemPreviewType_MarketProduct:Apply(variationIndex)
    PreviewMarketProduct(self.marketProductId, variationIndex)
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

-- Furniture Market Product Preview
ZO_ItemPreviewType_FurnitureMarketProduct = ZO_ItemPreviewType_MarketProduct:Subclass()

function ZO_ItemPreviewType_FurnitureMarketProduct:Apply(variationIndex)
    PreviewFurnitureMarketProduct(self.marketProductId, variationIndex)
end

--Inventory Item As Furniture

ZO_ItemPreviewType_InventoryItemAsFurniture = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_InventoryItemAsFurniture:SetStaticParameters(bag, slot)
    self.bag = bag
    self.slot = slot
end

function ZO_ItemPreviewType_InventoryItemAsFurniture:Apply(variationIndex)
    PreviewInventoryItemAsFurniture(self.bag, self.slot)
end

--Collectible As Furniture

ZO_ItemPreviewType_CollectibleAsFurniture = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_CollectibleAsFurniture:SetStaticParameters(collectibleId)
    self.collectibleId = collectibleId
end

function ZO_ItemPreviewType_CollectibleAsFurniture:Apply(variationIndex)
    PreviewCollectibleAsFurniture(self.collectibleId)
end

--Placed Furniture

ZO_ItemPreviewType_PlacedFurniture = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_PlacedFurniture:SetStaticParameters(furnitureId)
    self.furnitureId = furnitureId
end

function ZO_ItemPreviewType_PlacedFurniture:Apply(variationIndex)
    PreviewPlacedFurniture(self.furnitureId)
end

--Provisioner Item as Furniture

ZO_ItemPreviewType_ProvisionerItemAsFurniture = ZO_ItemPreviewType:Subclass()

function ZO_ItemPreviewType_ProvisionerItemAsFurniture:SetStaticParameters(recipeListIndex, recipeIndex)
    self.recipeListIndex = recipeListIndex
    self.recipeIndex = recipeIndex
end

function ZO_ItemPreviewType_ProvisionerItemAsFurniture:Apply(variationIndex)
    PreviewProvisionerItemAsFurniture(self.recipeListIndex, self.recipeIndex)
end

--
--[[ Item Preview]]--
--

ZO_ITEM_PREVIEW_MARKET_PRODUCT = 1
ZO_ITEM_PREVIEW_INVENTORY_ITEM_AS_FURNITURE = 2
ZO_ITEM_PREVIEW_COLLECTIBLE_AS_FURNITURE = 3
ZO_ITEM_PREVIEW_PLACED_FURNITURE = 4
ZO_ITEM_PREVIEW_PROVISIONER_ITEM_AS_FURNITURE = 5
ZO_ITEM_PREVIEW_FURNITURE_MARKET_PRODUCT = 6

ZO_ITEM_PREVIEW_WAIT_TIME_MS = 500

ZO_ItemPreview_Shared = ZO_CallbackObject:Subclass()

function ZO_ItemPreview_Shared:New(...)
    local preview = ZO_CallbackObject.New(self)
    preview:Initialize(...)
    return preview
end

function ZO_ItemPreview_Shared:Initialize(control)
    self.control = control
    
    self.canChangePreview = true
    self.lastSetChangeTime = 0

    self.fragment = ZO_SimpleSceneFragment:New(control)
    self.fragment:SetHideOnSceneHidden(true)
    self.fragment:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)

    self.previewTypeObjects =
    {
        [ZO_ITEM_PREVIEW_MARKET_PRODUCT] = ZO_ItemPreviewType_MarketProduct:New(),
        [ZO_ITEM_PREVIEW_COLLECTIBLE_AS_FURNITURE] = ZO_ItemPreviewType_CollectibleAsFurniture:New(),
        [ZO_ITEM_PREVIEW_INVENTORY_ITEM_AS_FURNITURE] = ZO_ItemPreviewType_InventoryItemAsFurniture:New(),
        [ZO_ITEM_PREVIEW_PLACED_FURNITURE] = ZO_ItemPreviewType_PlacedFurniture:New(),
        [ZO_ITEM_PREVIEW_PROVISIONER_ITEM_AS_FURNITURE] = ZO_ItemPreviewType_ProvisionerItemAsFurniture:New(),
        [ZO_ITEM_PREVIEW_FURNITURE_MARKET_PRODUCT] = ZO_ItemPreviewType_FurnitureMarketProduct:New(),
    }

    self.forcePreparePreview = true
    self:SetHorizontalPaddings(0, 0)
    self:SetDynamicFramingConsumedSpace(0, 0)
    self:SetPreviewInEmptyWorld(false)

    self.OnScreenResized = function()
        self:RefreshDynamicFramingOpening()
    end
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

do
    local PREVIEW_UPDATE_INTERVAL_MS = 100
    function ZO_ItemPreview_Shared:OnPreviewShowing()
        -- for the first preview we won't put a restriction on when we can preview the next one
        -- previewing a product automatically sets this to false so manually set it to true
        self:SetCanChangePreview(true)

        BeginPreviewMode(self.forcePreparePreview)
        self:RefreshDynamicFramingOpening()
        self:RefreshPreviewInEmptyWorld()
        EVENT_MANAGER:RegisterForUpdate("ZO_ItemPreview_Shared", PREVIEW_UPDATE_INTERVAL_MS, function(...) self:OnUpdate(...) end)
        EVENT_MANAGER:RegisterForEvent("ZO_ItemPreview_Shared", EVENT_SCREEN_RESIZED, self.OnScreenResized)
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

    self:EndCurrentPreview()

    SetInteractionUsingInteractCamera(true)
    ClearPreviewInEmptyWorld()
   
    EndPreviewMode()
    self.forcePreparePreview = true
    self:SetHorizontalPaddings(0, 0)
    self.previewBufferMS = nil
    self:SetDynamicFramingConsumedSpace(0, 0)
    self:SetPreviewInEmptyWorld(false)
end

function ZO_ItemPreview_Shared:EndCurrentPreview()
    self.currentPreviewTypeObject = nil
    self.previewAtMS = nil

    self.numPreviewVariations = 0
    self.previewVariationIndex = 0
    self:SetVariationControlsHidden(true)

    EndCurrentItemPreview()
end

function ZO_ItemPreview_Shared:GetFragment()
    return self.fragment
end

function ZO_ItemPreview_Shared:SharedPreviewSetup(previewType, ...)
    self.currentPreviewTypeObject = self:GetPreviewTypeObject(previewType)
    self.currentPreviewTypeObject:SetStaticParameters(...)

    self.previewVariationIndex = 1

    if IsCharacterPreviewingAvailable() then
        self:ApplyOrBuffer()
    end

    self.numPreviewVariations = self.currentPreviewTypeObject:GetNumVariations()

    if self.numPreviewVariations > 1 then
        self:SetVariationControlsHidden(false)
        self.variationLabel:SetText(self.currentPreviewTypeObject:GetVariationName(self.previewVariationIndex))
    else
        self:SetVariationControlsHidden(true)
    end

    self:SetCanChangePreview(false)
end

function ZO_ItemPreview_Shared:PreviewMarketProduct(marketProductId)
    self:SharedPreviewSetup(ZO_ITEM_PREVIEW_MARKET_PRODUCT, marketProductId)
end

function ZO_ItemPreview_Shared:PreviewFurnitureMarketProduct(marketProductId)
    self:SharedPreviewSetup(ZO_ITEM_PREVIEW_FURNITURE_MARKET_PRODUCT, marketProductId)
end

function ZO_ItemPreview_Shared:PreviewInventoryItemAsFurniture(bag, slot)
    self:SharedPreviewSetup(ZO_ITEM_PREVIEW_INVENTORY_ITEM_AS_FURNITURE, bag, slot)
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
    self.lastSetChangeTime = GetFrameTimeMilliseconds()
    PlaySound(SOUNDS.MARKET_PREVIEW_SELECTED)
end

function ZO_ItemPreview_Shared:SetCanChangePreview(canChangePreview)
    self.canChangePreview = canChangePreview
end

function ZO_ItemPreview_Shared:CanChangePreview()
    return self.canChangePreview
end

function ZO_ItemPreview_Shared:PreviewNextVariation()
    if self.numPreviewVariations > 0 then
        self.previewVariationIndex = self.previewVariationIndex + 1

        if self.previewVariationIndex > self.numPreviewVariations then
            self.previewVariationIndex = 1
        end

        self:ApplyOrBuffer()
    end

    self:SetVariationLabel(self.currentPreviewTypeObject:GetVariationName(self.previewVariationIndex))
end

function ZO_ItemPreview_Shared:PreviewPreviousVariation()
    if self.numPreviewVariations > 0 then
        self.previewVariationIndex = self.previewVariationIndex - 1

        if self.previewVariationIndex < 1 then
            self.previewVariationIndex = self.numPreviewVariations
        end

        self:ApplyOrBuffer()
    end

    self:SetVariationLabel(self.currentPreviewTypeObject:GetVariationName(self.previewVariationIndex))
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
        else
            ClearPreviewInEmptyWorld()
        end
    end
end

function ZO_ItemPreview_Shared:IsInteractionCameraPreviewEnabled()
    return not IsInteractionUsingInteractCamera()
end

function ZO_ItemPreview_Shared:ToggleInteractionCameraPreview(framingTargetFragment, framingFragment, previewOptionsFragment)
    self:SetInteractionCameraPreviewEnabled(not self:IsInteractionCameraPreviewEnabled(), framingTargetFragment, framingFragment, previewOptionsFragment)
end

do
    function ZO_ItemPreview_Shared:RemoveFragmentImmediately(fragment)
        if fragment:GetHideOnSceneHidden() then
            fragment:SetHideOnSceneHidden(false)
            SCENE_MANAGER:RemoveFragment(fragment)
            fragment:SetHideOnSceneHidden(true)
        else
            SCENE_MANAGER:RemoveFragment(fragment)
        end
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
                self:RemoveFragmentImmediately(self.fragment)
                SCENE_MANAGER:RemoveFragment(previewOptionsFragment)
                self:RemoveFragmentImmediately(framingFragment)
                SCENE_MANAGER:RemoveFragment(framingTargetFragment)
            
                SetInteractionUsingInteractCamera(true)
            end
        end
    end
end

function ZO_ItemPreview_Shared:SetVariationControlsHidden(shouldHide)
    -- optional override
end

function ZO_ItemPreview_Shared:SetVariationLabel(variationName)
    -- optional override
end

function ZO_ItemPreview_Shared:SetHorizontalPaddings(paddingLeft, paddingRight)
    --override
    assert(false)
end

function ZO_ItemPreview_Shared:SetPreviewBufferMS(previewBufferMS)
    self.previewBufferMS = previewBufferMS
end