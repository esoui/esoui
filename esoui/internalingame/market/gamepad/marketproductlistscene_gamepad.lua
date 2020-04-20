ZO_GAMEPAD_MARKET_CONTENT_LIST_SCENE_NAME = "gamepad_market_content_list"

--
--[[ Gamepad Market Product List Scene ]]--
--

local GamepadMarketProductListScene = ZO_Gamepad_ParametricList_Screen:Subclass()

function GamepadMarketProductListScene:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function GamepadMarketProductListScene:Initialize(control)
    ZO_GAMEPAD_MARKET_LIST_SCENE = ZO_RemoteScene:New(ZO_GAMEPAD_MARKET_CONTENT_LIST_SCENE_NAME, SCENE_MANAGER)
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, ZO_GAMEPAD_MARKET_LIST_SCENE)
    self.list = self:GetMainList()
    self:InitializeHeader()
    self.previewProductIds = {}
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
            name = GetString(SI_MARKET_PREVIEW_KEYBIND_TEXT),
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
                            self:BeginPreview()
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
    else
        self:TrySelectLastPreviewedProduct()
    end
end

function GamepadMarketProductListScene:OnHiding()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    self.queuedMarketProductId = nil
    self.queuedPreviewType = nil
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
    elseif previewType == ZO_MARKET_PREVIEW_TYPE_BUNDLE or previewType == ZO_MARKET_PREVIEW_TYPE_BUNDLE_HIDES_CHILDREN then
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

-- marketProducts is a table of Market Product info
function GamepadMarketProductListScene:ShowMarketProducts(marketProducts)
    self.list:Clear()

    ZO_ClearNumericallyIndexedTable(self.previewProductIds)

    local lastHeaderName = nil

    for i = 1, #marketProducts do
        local productInfo = marketProducts[i]
        local productId = productInfo.productId
        local name, description, icon, isNew, isFeatured = GetMarketProductInfo(productId)

        local entryData = ZO_GamepadEntryData:New(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, name), icon)
        entryData.marketProductId = productId
        entryData.listIndex = i
        entryData:SetStackCount(productInfo.stackCount)

        entryData.displayQuality = productInfo.displayQuality or ITEM_DISPLAY_QUALITY_NORMAL
        entryData:SetNameColors(entryData:GetColorsBasedOnQuality(entryData.displayQuality))

        -- check if we should add a header
        local productHeader = productInfo.headerName
        if productHeader and lastHeaderName ~= productHeader then
            local headerString = productHeader
            if productInfo.headerColor then
                headerString = productInfo.headerColor:Colorize(headerString)
            end
            entryData:SetHeader(headerString)
            self.list:AddEntryWithHeader("ZO_GamepadMenuEntryTemplate", entryData)
            lastHeaderName = productHeader
        else
            self.list:AddEntry("ZO_GamepadMenuEntryTemplate", entryData)
        end

        local hasPreview = CanPreviewMarketProduct(productId)
        entryData.hasPreview = hasPreview
        if hasPreview then
            table.insert(self.previewProductIds, productId)
            entryData.previewIndex = #self.previewProductIds
        end
    end

    self.list:Commit()
    self.list:SetSelectedIndexWithoutAnimation(1)
end

function GamepadMarketProductListScene:OnTargetChanged(list, targetData, oldTargetData)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)

    if targetData then
        local productId = targetData.marketProductId
        GAMEPAD_TOOLTIPS:LayoutMarketProduct(GAMEPAD_LEFT_TOOLTIP, productId)
    end
end

function GamepadMarketProductListScene:OnPreviewChanged(previewData)
    self.lastPreviewedMarketProductId = previewData
end

function GamepadMarketProductListScene:BeginPreview()
    local targetData = self.list:GetTargetData()
    if targetData then
        local previewIndex = targetData.previewIndex
        ZO_MARKET_PREVIEW_GAMEPAD:BeginPreview(self.previewProductIds, previewIndex, function(...) self:OnPreviewChanged(...) end)
    end
end

function GamepadMarketProductListScene:TrySelectLastPreviewedProduct()
    local marketProductId = self.lastPreviewedMarketProductId
    if marketProductId then
        local index = self.list:FindFirstIndexByEval(function(data) return data.marketProductId == marketProductId end)
        if index then
            self.list:SetSelectedIndexWithoutAnimation(index)
        end
    end
end

function GamepadMarketProductListScene:PerformUpdate()
    -- This function is required but unused
    self.dirty = false
end

function ZO_GamepadMarketProductList_OnInitialized(control)
    ZO_GAMEPAD_MARKET_PRODUCT_LIST = GamepadMarketProductListScene:New(control)
end
