--
--[[ Market List Fragment ]]--
--

local MARKET_LIST_ENTRY_MARKET_PRODUCT = 1
local MARKET_LIST_ENTRY_MARKET_REWARD = 2
local MARKET_LIST_ENTRY_HEADER = 3

ZO_MarketListFragment_Keyboard = ZO_SimpleSceneFragment:Subclass()

function ZO_MarketListFragment_Keyboard:New(...)
    local fragment = ZO_SimpleSceneFragment.New(self, ...)
    fragment:Initialize(...)
    return fragment
end

function ZO_MarketListFragment_Keyboard:Initialize(control, owner)
    self.control = control
    self.owner = owner

    self.list = control:GetNamedChild("List")
    self.listHeader = control:GetNamedChild("ListHeader")
    self.contentHeader = control:GetNamedChild("ContentHeader")

    -- initialize the scroll list
    ZO_ScrollList_Initialize(self.list)

    local function SetupMarketProductEntry(...)
        self:SetupMarketProductEntry(...)
    end

    local function OnMarketProductEntryReset(...)
        self:OnMarketProductEntryReset(...)
    end

    local function SetupRewardEntry(...)
        self:SetupRewardEntry(...)
    end

    local function OnRewardEntryReset(...)
        self:OnRewardEntryReset(...)
    end

    local function SetupHeaderEntry(...)
        self:SetupHeaderEntry(...)
    end

    local function OnHeaderEntryReset(...)
        self:OnHeaderEntryReset(...)
    end

    local NO_ON_HIDDEN_CALLBACK = nil
    local NO_SELECT_SOUND = nil
    ZO_ScrollList_AddDataType(self.list, MARKET_LIST_ENTRY_MARKET_PRODUCT, "ZO_MarketListEntry", ZO_MARKET_LIST_ENTRY_HEIGHT, SetupMarketProductEntry, NO_ON_HIDDEN_CALLBACK, NO_SELECT_SOUND, OnMarketProductEntryReset)
    ZO_ScrollList_AddDataType(self.list, MARKET_LIST_ENTRY_MARKET_REWARD, "ZO_MarketListEntry", ZO_MARKET_LIST_ENTRY_HEIGHT, SetupRewardEntry, NO_ON_HIDDEN_CALLBACK, NO_SELECT_SOUND, OnRewardEntryReset)
    ZO_ScrollList_AddDataType(self.list, MARKET_LIST_ENTRY_HEADER, "ZO_MarketListHeader", ZO_MARKET_LIST_ENTRY_HEIGHT, SetupHeaderEntry, NO_ON_HIDDEN_CALLBACK, NO_SELECT_SOUND, OnHeaderEntryReset)
    ZO_ScrollList_AddResizeOnScreenResize(self.list)

    self.scrollData = ZO_ScrollList_GetDataList(self.list)

    -- create closures to use for the mouse functions of all row entries
    self.onRowMouseEnterMarketProduct = function(...) self:OnMouseEnterMarketProduct(...) end
    self.onRowMouseEnterMarketReward = function(...) self:OnMouseEnterMarketReward(...) end
    self.onRowMouseExitMarketProduct = function(...) self:OnMouseExitMarketProduct(...) end
    self.onRowMouseExitMarketReward = function(...) self:OnMouseExitMarketReward(...) end
    self.onRowMouseUp = function(...) self:OnMouseUp(...) end
end

function ZO_MarketListFragment_Keyboard:SetupMarketProductEntry(rowControl, data)
    rowControl.data = data
    rowControl.nameControl:SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, data.name))
    rowControl.iconControl:SetTexture(data.icon)

    if data.stackCount > 1 then
        rowControl.stackCount:SetText(data.stackCount)
        rowControl.stackCount:SetHidden(false)
    else
        rowControl.stackCount:SetHidden(true)
    end

    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, data.displayQuality)
    rowControl.nameControl:SetColor(r, g, b, 1)

    rowControl:SetHandler("OnMouseEnter", self.onRowMouseEnterMarketProduct)
    rowControl:SetHandler("OnMouseExit", self.onRowMouseExitMarketProduct)
    rowControl:SetHandler("OnMouseUp", self.onRowMouseUp)
end

function ZO_MarketListFragment_Keyboard:SetupRewardEntry(rowControl, rewardInfo)
    rowControl.data = rewardInfo
    rowControl.nameControl:SetText(rewardInfo:GetFormattedName())
    rowControl.iconControl:SetTexture(rewardInfo:GetKeyboardIcon())

    if rewardInfo:GetQuantity() > 1 then
        rowControl.stackCount:SetText(rewardInfo:GetQuantity())
        rowControl.stackCount:SetHidden(false)
    else
        rowControl.stackCount:SetHidden(true)
    end

    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, rewardInfo:GetItemDisplayQuality())
    rowControl.nameControl:SetColor(r, g, b, 1)

    rowControl:SetHandler("OnMouseEnter", self.onRowMouseEnterMarketReward)
    rowControl:SetHandler("OnMouseExit", self.onRowMouseExitMarketReward)
    rowControl:SetHandler("OnMouseUp", self.onRowMouseUp)
end

function ZO_MarketListFragment_Keyboard:OnMarketProductEntryReset(rowControl)
    local highlight = rowControl.highlight
    if highlight.animation then
        highlight.animation:PlayFromEnd(highlight.animation:GetDuration())
    end

    local icon = rowControl.iconControl
    if icon.animation then
        icon.animation:PlayInstantlyToStart()
    end

    rowControl.data = nil

    ZO_ObjectPool_DefaultResetControl(rowControl)
end

function ZO_MarketListFragment_Keyboard:OnRewardEntryReset(rowControl)
    local highlight = rowControl.highlight
    if highlight.animation then
        highlight.animation:PlayFromEnd(highlight.animation:GetDuration())
    end

    local icon = rowControl.iconControl
    if icon.animation then
        icon.animation:PlayInstantlyToStart()
    end

    rowControl.data = nil

    ZO_ObjectPool_DefaultResetControl(rowControl)
end

function ZO_MarketListFragment_Keyboard:SetupHeaderEntry(rowControl, data)
    rowControl.data = data
    local headerString = data.headerName or ""
    if data.headerColor then
        headerString = data.headerColor:Colorize(headerString)
    end

    local formattedHeaderString
    if data.headerStackCount and data.headerStackCount > 1 then
        formattedHeaderString = zo_strformat(SI_MARKET_LIST_ENTRY_HEADER_AND_STACK_COUNT_FORMATTER, headerString, data.headerStackCount)
    else
        formattedHeaderString = zo_strformat(SI_MARKET_LIST_ENTRY_HEADER_FORMATTER, headerString)
    end

    rowControl.nameControl:SetText(formattedHeaderString)
end

function ZO_MarketListFragment_Keyboard:OnHeaderEntryReset(rowControl)
    rowControl.data = nil

    ZO_ObjectPool_DefaultResetControl(rowControl)
end

function ZO_MarketListFragment_Keyboard:SetupListHeader(headerString)
    if headerString == nil or headerString == "" then
        self.listHeader:SetHidden(true)
        -- we want to position the list up to where the header starts
        self.list:ClearAnchors()
        self.list:SetAnchor(TOPLEFT, self.listHeader, TOPLEFT, 0, 0)
    else
        self.listHeader:SetHidden(false)
        self.list:ClearAnchors()
        self.list:SetAnchor(TOPLEFT, self.listHeader, BOTTOMLEFT, 0, 15)
        self.listHeader:SetText(headerString)
    end
end

function ZO_MarketListFragment_Keyboard:ShowCrownCrateContents(marketProductData)
    self.contentHeader:SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, marketProductData:GetDisplayName()))
    self:SetupListHeader(GetString(SI_MARKET_CRATE_LIST_HEADER))

    local marketProducts = ZO_Market_Shared.GetCrownCrateContentsProductInfo(marketProductData:GetId())

    table.sort(marketProducts, function(...)
                return ZO_Market_Shared.CompareCrateMarketProducts(...)
            end)

    self:ShowMarketProducts(marketProducts)
end

function ZO_MarketListFragment_Keyboard:ShowMarketProductBundleContents(marketProductData)
    self.contentHeader:SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, marketProductData:GetDisplayName()))
    self:SetupListHeader(nil)

    local marketProducts = ZO_Market_Shared.GetMarketProductBundleChildProductInfo(marketProductData:GetId())

    table.sort(marketProducts, function(...)
                return ZO_Market_Shared.CompareBundleMarketProducts(...)
            end)

    self:ShowMarketProducts(marketProducts)
end

-- marketProducts is a table of Market Product info and Reward info objects
function ZO_MarketListFragment_Keyboard:ShowMarketProducts(marketProducts)
    ZO_ScrollList_Clear(self.list)
    ZO_ScrollList_ResetToTop(self.list)

    local lastHeaderName = nil
    local numMarketProducts = #marketProducts

    for index, productInfo in ipairs(marketProducts) do
        local productId = productInfo.productId
        local productHeaderColor = productInfo.headerColor
        local productHeaderName = productInfo.headerName
        local productDisplayQuality = productInfo.displayQuality or ITEM_DISPLAY_QUALITY_NORMAL
        local productStackCount = productInfo.stackCount
        local isReward = productInfo.rewardId ~= nil

        -- Determine whether a header row should be insert first.
        if productHeaderName ~= "" and numMarketProducts > 1 then
            -- Header rows should only be shown when multiple products are bundled together.
            if lastHeaderName ~= productHeaderName then
                lastHeaderName = productHeaderName
                local headerData =
                {
                    headerName = productHeaderName,
                    headerStackCount = productStackCount,
                    headerColor = productHeaderColor,
                }
                table.insert(self.scrollData, ZO_ScrollList_CreateDataEntry(MARKET_LIST_ENTRY_HEADER, headerData))
            end
        else
            lastHeaderName = ""
        end

        if isReward then
            -- Create and insert a reward row.
            local rewardRowData = ZO_ScrollList_CreateDataEntry(MARKET_LIST_ENTRY_MARKET_REWARD, productInfo)
            table.insert(self.scrollData, rewardRowData)
        else
            -- Create and insert a market product row.
            local rowData =
            {
                productId = productId,
                name = GetMarketProductDisplayName(productId),
                icon = GetMarketProductIcon(productId),
                stackCount = productInfo.stackCount,
                displayQuality = productDisplayQuality,
            }
            local productRowData = ZO_ScrollList_CreateDataEntry(MARKET_LIST_ENTRY_MARKET_PRODUCT, rowData)
            table.insert(self.scrollData, productRowData)
        end
    end

    ZO_ScrollList_Commit(self.list)
end

function ZO_MarketListFragment_Keyboard:CanPreview()
    local data = self:GetSelectedData()
    if data then
        -- Order matters
        if data.rewardId then
            return CanPreviewReward(data.rewardId)
        elseif data.productId then
            return CanPreviewMarketProduct(data.productId)
        end
    end

    return false
end

function ZO_MarketListFragment_Keyboard:IsActivelyPreviewing()
    local data = self:GetSelectedData()
    if data then
        -- Order matters
        if data.rewardId then
            return IsPreviewingReward(data.rewardId)
        elseif data.productId then
            return IsPreviewingMarketProduct(data.productId)
        end
    end

    return false
end

function ZO_MarketListFragment_Keyboard:GetPreviewState()
    local isPreviewing = IsCurrentlyPreviewing()
    local canPreview = false
    local isActivePreview = false
    local isPreviewToggleable = false
    local data = self:GetSelectedData()

    if data then
        canPreview = IsCharacterPreviewingAvailable() and self:CanPreview()

        if isPreviewing and self:IsActivelyPreviewing() then
            isActivePreview = true
        end

        local collectibleType = select(4, GetMarketProductCollectibleInfo(data.productId))
        isPreviewToggleable = collectibleType == COLLECTIBLE_CATEGORY_TYPE_OUTFIT_STYLE
    end

    return isPreviewing, canPreview, isActivePreview, isPreviewToggleable
end

function ZO_MarketListFragment_Keyboard:IsReadyToPreview()
    local _, canPreview, isActivePreview, isPreviewToggleable = self:GetPreviewState()
    return canPreview and (not isActivePreview or isPreviewToggleable)
end

function ZO_MarketListFragment_Keyboard:GetSelectedData()
    if self.selectedRow then
        return self.selectedRow.data
    end
    return nil
end

function ZO_MarketListFragment_Keyboard:GetSelectedProductId()
    local data = self:GetSelectedData()
    if data then
        return data.productId
    end
    return 0
end

function ZO_MarketListFragment_Keyboard:GetSelectedRewardId()
    local data = self:GetSelectedData()
    if data then
        return data.rewardId
    end
    return 0
end

local function SetListHighlightHidden(control, hidden)
    local highlight = control.highlight
    if not highlight.animation then
        highlight.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", highlight)
    end
    if hidden then
        highlight.animation:PlayBackward()
    else
        highlight.animation:PlayForward()
    end
end

function ZO_MarketListFragment_Keyboard:OnMouseEnterMarketProduct(control)
    SetListHighlightHidden(control, false)

    local icon = control.iconControl
    if not icon.animation then
        icon.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("IconSlotMouseOverAnimation", icon)
    end
    icon.animation:PlayForward()

    local offsetX = -15
    local offsetY = 0
    InitializeTooltip(ItemTooltip, control, RIGHT, offsetX, offsetY, LEFT)
    ItemTooltip:SetMarketProduct(control.data.productId)

    self.selectedRow = control
    self.owner:RefreshActions()
end

function ZO_MarketListFragment_Keyboard:OnMouseEnterMarketReward(control)
    SetListHighlightHidden(control, false)

    local icon = control.iconControl
    if not icon.animation then
        icon.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("IconSlotMouseOverAnimation", icon)
    end
    icon.animation:PlayForward()

    local offsetX = -15
    local offsetY = 0
    ZO_Rewards_Shared_OnMouseEnter(control, RIGHT, LEFT, offsetX, offsetY)

    self.selectedRow = control
    self.owner:RefreshActions()
end

function ZO_MarketListFragment_Keyboard:OnMouseExitMarketProduct(control)
    SetListHighlightHidden(control, true)

    local icon = control.iconControl
    if icon.animation then
        icon.animation:PlayBackward()
    end

    ClearTooltip(ItemTooltip)

    self.selectedRow = nil
    self.owner:RefreshActions()
end

function ZO_MarketListFragment_Keyboard:OnMouseExitMarketReward(control)
    SetListHighlightHidden(control, true)

    local icon = control.iconControl
    if icon.animation then
        icon.animation:PlayBackward()
    end

    ZO_Rewards_Shared_OnMouseExit(control)

    self.selectedRow = nil
    self.owner:RefreshActions()
end

function ZO_MarketListFragment_Keyboard:OnMouseUp(control, button)
    if self.selectedRow and button == MOUSE_BUTTON_INDEX_LEFT and self:IsReadyToPreview() then
        local data = self:GetSelectedData()
        -- Order matters
        if data.rewardId then
            self.owner:PreviewReward(data.rewardId)
        elseif data.productId then
            self.owner:PreviewMarketProduct(data.productId)
        end
    end
end