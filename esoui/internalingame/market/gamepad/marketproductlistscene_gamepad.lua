ZO_GAMEPAD_MARKET_CONTENT_LIST_SCENE_NAME = "gamepad_market_content_list"

--
--[[ Gamepad Market Product List Scene ]]--
--

local GamepadMarketProductListScene = ZO_Gamepad_ParametricList_Screen:Subclass()

function GamepadMarketProductListScene:Initialize(control)
    ZO_GAMEPAD_MARKET_LIST_SCENE = ZO_RemoteScene:New(ZO_GAMEPAD_MARKET_CONTENT_LIST_SCENE_NAME, SCENE_MANAGER)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, ZO_GAMEPAD_MARKET_LIST_SCENE)
    self.list = self:GetMainList()
    self:InitializeHeader()
    self.shouldAutoPreview = false
end

function GamepadMarketProductListScene:OnDeferredInitialize()
    self:SetListsUseTriggerKeybinds(true)
end

function GamepadMarketProductListScene:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- "Preview" Keybind
        {
            name =      function()
                            local targetData = self.list:GetTargetData()
                            if targetData then
                                local collectibleId
                                local collectibleType
                                if GetMarketProductType(targetData.marketProductId) == MARKET_PRODUCT_TYPE_COLLECTIBLE then
                                    collectibleId, _, _, collectibleType = GetMarketProductCollectibleInfo(targetData.marketProductId)
                                end
                                if collectibleType == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE then
                                    local collectibleData = ZO_CollectibleData_Base:New()
                                    collectibleData:SetId(collectibleId)
                                    if ZO_GAMEPAD_MARKET:IsPreviewingOutfitStyle(collectibleData) then
                                        return GetString(SI_MARKET_END_PREVIEW_KEYBIND_TEXT)
                                    end
                                elseif self.shouldAutoPreview then
                                    return GetString(SI_MARKET_END_PREVIEW_KEYBIND_TEXT)
                                end
                            end
                            return GetString(SI_MARKET_PREVIEW_KEYBIND_TEXT)
                        end,
            keybind = "UI_SHORTCUT_PRIMARY",
            visible =   function()
                            local targetData = self.list:GetTargetData()
                            if targetData then
                                return true
                            end
                            return false
                        end,
            enabled =   function()
                            local targetData = self.list:GetTargetData()
                            if targetData then
                                return targetData.hasPreview and IsCharacterPreviewingAvailable()
                            end
                            return false
                        end,
            callback =  function()
                            self:TogglePreview()
                        end,
        },
        -- "End All Previews" Keybind
        {
            name = GetString(SI_MARKET_END_ALL_PREVIEWS_KEYBIND_TEXT),
            keybind = "UI_SHORTCUT_SECONDARY",
            visible =   function()
                            return ZO_GAMEPAD_MARKET:HasAnyCurrentSlotPreviews()
                        end,
            callback =  function()
                            ZO_GAMEPAD_MARKET:ClearAllCurrentSlotPreviews()
                        end,
        },


        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
    }
end

function GamepadMarketProductListScene:InitializeHeader()
    self.headerData = {
        titleText = "",
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function GamepadMarketProductListScene:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    if self.queuedMarketProductId ~= nil then
        self:ShowMarketProduct(self.queuedMarketProductId, self.queuedPreviewType)
        self.queuedMarketProductId = nil
        self.queuedPreviewType = nil
    end
end

function GamepadMarketProductListScene:OnHiding()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    self.queuedMarketProductId = nil
    self.queuedPreviewType = nil
    self:EndPreview()
end

function GamepadMarketProductListScene:SetMarketProduct(marketProductId, previewType)
    if SCENE_MANAGER:IsShowing(self.scene.name) then
        self:ShowMarketProduct(marketProductId, previewType)
    else
        self.queuedMarketProductId = marketProductId
        self.queuedPreviewType = previewType
    end
end

function GamepadMarketProductListScene:ShowMarketProduct(marketProductId, previewType)
    if previewType == ZO_MARKET_PREVIEW_TYPE_CROWN_CRATE then
        self:ShowCrownCrateContents(marketProductId)
    elseif previewType == ZO_MARKET_PREVIEW_TYPE_BUNDLE or previewType == ZO_MARKET_PREVIEW_TYPE_BUNDLE_AS_LIST then
        self:ShowMarketProductBundleContents(marketProductId)
    end
end

function GamepadMarketProductListScene:ShowCrownCrateContents(marketProductId)
    self.headerData.titleText = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, GetMarketProductDisplayName(marketProductId))
    self.headerData.messageText = GetString(SI_MARKET_CRATE_LIST_HEADER)
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    local marketProducts = ZO_Market_Shared.GetCrownCrateContentsProductInfo(marketProductId)

    table.sort(marketProducts, function(...)
                                    return ZO_Market_Shared.CompareCrateMarketProducts(...)
                                end)

    self:ShowMarketProducts(marketProducts)
end

function GamepadMarketProductListScene:ShowMarketProductBundleContents(marketProductId)
    self.headerData.titleText = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, GetMarketProductDisplayName(marketProductId))
    self.headerData.messageText = nil
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    local marketProducts = ZO_Market_Shared.GetMarketProductBundleChildProductInfo(marketProductId)

    table.sort(marketProducts, function(...)
                return ZO_Market_Shared.CompareBundleMarketProducts(...)
            end)

    self:ShowMarketProducts(marketProducts)
end

-- objectList is a table of MarketProduct and Reward objects
function GamepadMarketProductListScene:ShowMarketProducts(objectList)
    self.list:Clear()

    local numObjects = #objectList
    local lastHeaderName = nil

    for i = 1, numObjects do
        local objectInfo = objectList[i]
        local isReward = objectInfo.isRewardEntry
        local rewardId = objectInfo.rewardId
        local productId = objectInfo.productId
        local productName = nil
        local iconTextureFile = nil
        local stackCount = nil
        local displayQuality = nil

        if isReward then
            productName = objectInfo:GetFormattedName()
            iconTextureFile = objectInfo:GetGamepadIcon()
            stackCount = objectInfo:GetQuantity()
            displayQuality = objectInfo:GetItemDisplayQuality()
        else
            local _
            productName, _, iconTextureFile = GetMarketProductInfo(productId)
            productName = zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, productName)
            stackCount = objectInfo.stackCount
            displayQuality = objectInfo.displayQuality
        end

        local entryData = ZO_GamepadEntryData:New(productName, iconTextureFile)
        entryData.marketProductId = productId
        entryData.rewardId = rewardId
        entryData.listIndex = i
        entryData:SetStackCount(stackCount)
        entryData.displayQuality = displayQuality or ITEM_DISPLAY_QUALITY_NORMAL
        entryData:SetNameColors(entryData:GetColorsBasedOnQuality(displayQuality))

        -- check if we should add a header
        local productHeader = objectInfo.headerName
        if productHeader and lastHeaderName ~= productHeader then
            local headerString = productHeader
            if isReward and numObjects > 1 and objectInfo.stackCount and objectInfo.stackCount > 1 then
                headerString = zo_strformat(SI_MARKET_LIST_ENTRY_HEADER_AND_STACK_COUNT_FORMATTER, headerString, objectInfo.stackCount)
            else
                headerString = zo_strformat(SI_MARKET_LIST_ENTRY_HEADER_FORMATTER, headerString)
            end

            if objectInfo.headerColor then
                headerString = objectInfo.headerColor:Colorize(headerString)
            end

            entryData:SetHeader(headerString)
            self.list:AddEntryWithHeader("ZO_GamepadMenuEntryTemplate", entryData)
            lastHeaderName = productHeader
        else
            self.list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
        end

        local hasPreview = nil
        -- Order matters
        if isReward then
            hasPreview = CanPreviewReward(rewardId)
        else
            hasPreview = CanPreviewMarketProduct(productId)
        end

        entryData.hasPreview = hasPreview
        if hasPreview then
            local previewType = nil
            local previewObjectId = nil

            if isReward then
                previewType = ZO_ITEM_PREVIEW_REWARD
                previewObjectId = rewardId
            else
                previewType = ZO_ITEM_PREVIEW_MARKET_PRODUCT
                previewObjectId = productId
            end
        end
    end

    self.list:Commit()
    self.list:SetSelectedIndexWithoutAnimation(1)
end

function GamepadMarketProductListScene:OnTargetChanged(list, targetData, oldTargetData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)

    if targetData then
        if targetData.rewardId and targetData.rewardId ~= 0 then
            GAMEPAD_TOOLTIPS:LayoutReward(GAMEPAD_LEFT_TOOLTIP, targetData.rewardId, targetData.stackCount, REWARD_DISPLAY_FLAGS_FROM_CROWN_STORE_CONTAINER)
        else
            GAMEPAD_TOOLTIPS:LayoutMarketProduct(GAMEPAD_LEFT_TOOLTIP, targetData.marketProductId)
        end
        self:UpdatePreview()
    end
end

function GamepadMarketProductListScene:TogglePreview()
    if self.shouldAutoPreview then
        self:EndPreview()
    else
        local targetData = self.list:GetTargetData()
        if targetData and targetData.hasPreview then
            local collectibleId
            local collectibleType
            if GetMarketProductType(targetData.marketProductId) == MARKET_PRODUCT_TYPE_COLLECTIBLE then
                collectibleId, _, _, collectibleType = GetMarketProductCollectibleInfo(targetData.marketProductId)
            end
            if targetData.rewardId then
                ZO_GAMEPAD_MARKET:ClearAllCurrentSlotPreviews()
                ZO_Market_Shared.PreviewReward(ITEM_PREVIEW_GAMEPAD, targetData.rewardId)
                self.shouldAutoPreview = true
            elseif collectibleType == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE then
                ZO_GAMEPAD_MARKET:PreviewOutfitStyle(collectibleId)
            else
                ZO_GAMEPAD_MARKET:ClearAllCurrentSlotPreviews()
                ZO_Market_Shared.PreviewMarketProduct(ITEM_PREVIEW_GAMEPAD, targetData.marketProductId)
                self.shouldAutoPreview = true
            end
        end
    end
    self:RefreshKeybinds()
end

function GamepadMarketProductListScene:UpdatePreview()
    if self.shouldAutoPreview then
        local targetData = self.list:GetTargetData()
        if targetData and targetData.hasPreview then
            local collectibleType
            if GetMarketProductType(targetData.marketProductId) == MARKET_PRODUCT_TYPE_COLLECTIBLE then
                collectibleType = select(4, GetMarketProductCollectibleInfo(targetData.marketProductId))
            end
            if targetData.rewardId then
                ZO_Market_Shared.PreviewReward(ITEM_PREVIEW_GAMEPAD, targetData.rewardId)
            elseif collectibleType == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE then
                self:EndPreview()
            else
                ZO_Market_Shared.PreviewMarketProduct(ITEM_PREVIEW_GAMEPAD, targetData.marketProductId)
            end
        else
            self:EndPreview()
        end
    end
    self:RefreshKeybinds()
end

function GamepadMarketProductListScene:EndPreview()
    ZO_GAMEPAD_MARKET:ClearAllCurrentSlotPreviews()
    ITEM_PREVIEW_GAMEPAD:EndCurrentPreview()
    self.shouldAutoPreview = false
    self:RefreshKeybinds()
end

function GamepadMarketProductListScene:PerformUpdate()
    -- This function is required but unused
    self.dirty = false
end

--Overridden from base
function GamepadMarketProductListScene:GetFooterNarration()
    if MARKET_CURRENCY_GAMEPAD_FRAGMENT:IsShowing() then
        return MARKET_CURRENCY_GAMEPAD:GetNarrationText()
    end
end

function ZO_GamepadMarketProductList_OnInitialized(control)
    ZO_GAMEPAD_MARKET_PRODUCT_LIST = GamepadMarketProductListScene:New(control)
end