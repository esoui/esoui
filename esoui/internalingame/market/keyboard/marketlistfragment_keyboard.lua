--
--[[ Market List Fragment ]]--
--

local MARKET_LIST_ENTRY_MARKET_PRODUCT = 1
local MARKET_LIST_ENTRY_HEADER = 2

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

    local function SetupEntry(...)
        self:SetupEntry(...)
    end

    local function OnEntryReset(...)
        self:OnEntryReset(...)
    end

    local function SetupHeaderEntry(...)
        self:SetupHeaderEntry(...)
    end

    local function OnHeaderEntryReset(...)
        self:OnHeaderEntryReset(...)
    end

    local NO_ON_HIDDEN_CALLBACK = nil
    local NO_SELECT_SOUND = nil
    ZO_ScrollList_AddDataType(self.list, MARKET_LIST_ENTRY_MARKET_PRODUCT, "ZO_MarketListEntry", ZO_MARKET_LIST_ENTRY_HEIGHT, SetupEntry, NO_ON_HIDDEN_CALLBACK, NO_SELECT_SOUND, OnEntryReset)
    ZO_ScrollList_AddDataType(self.list, MARKET_LIST_ENTRY_HEADER, "ZO_MarketListHeader", ZO_MARKET_LIST_ENTRY_HEIGHT, SetupHeaderEntry, NO_ON_HIDDEN_CALLBACK, NO_SELECT_SOUND, OnHeaderEntryReset)
    ZO_ScrollList_AddResizeOnScreenResize(self.list)

    self.scrollData = ZO_ScrollList_GetDataList(self.list)

    -- create closures to use for the mouse functions of all row entries
    self.onRowMouseEnter = function(...) self:OnMouseEnter(...) end
    self.onRowMouseExit = function(...) self:OnMouseExit(...) end
    self.onRowMouseUp = function(...) self:OnMouseUp(...) end
end

function ZO_MarketListFragment_Keyboard:SetupEntry(rowControl, data)
    rowControl.data = data
    rowControl.nameControl:SetText(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, data.name))
    rowControl.iconControl:SetTexture(data.icon)

    if data.stackCount > 1 then
        rowControl.stackCount:SetText(data.stackCount)
        rowControl.stackCount:SetHidden(false)
    else
        rowControl.stackCount:SetHidden(true)
    end

    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, data.quality)
    rowControl.nameControl:SetColor(r, g, b, 1)

    rowControl:SetHandler("OnMouseEnter", self.onRowMouseEnter)
    rowControl:SetHandler("OnMouseExit", self.onRowMouseExit)
    rowControl:SetHandler("OnMouseUp", self.onRowMouseUp)
end

function ZO_MarketListFragment_Keyboard:OnEntryReset(rowControl, data)
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
    rowControl.nameControl:SetText(zo_strformat(SI_MARKET_LIST_ENTRY_HEADER_FORMATTER, headerString))
end

function ZO_MarketListFragment_Keyboard:OnHeaderEntryReset(rowControl, data)
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

-- marketProducts is a table of Market Product info
function ZO_MarketListFragment_Keyboard:ShowMarketProducts(marketProducts)
    ZO_ScrollList_Clear(self.list)
    ZO_ScrollList_ResetToTop(self.list)

    local lastHeaderName = nil

    for index, productInfo in ipairs(marketProducts) do
        -- check if we should add a header
        local productHeader = productInfo.headerName
        if productHeader and lastHeaderName ~= productHeader then
            local headerData =
            {
                headerName = productHeader,
                headerColor = productInfo.headerColor,
            }
            table.insert(self.scrollData, ZO_ScrollList_CreateDataEntry(MARKET_LIST_ENTRY_HEADER, headerData))
            lastHeaderName = productHeader
        end

        local productId = productInfo.productId
        local displayQuality = productInfo.displayQuality or ITEM_DISPLAY_QUALITY_NORMAL

        local rowData =
        {
            productId = productId,
            name = GetMarketProductDisplayName(productId),
            icon = GetMarketProductIcon(productId),
            stackCount = productInfo.stackCount,
            displayQuality = displayQuality,
        }
        table.insert(self.scrollData, ZO_ScrollList_CreateDataEntry(MARKET_LIST_ENTRY_MARKET_PRODUCT, rowData))
    end

    ZO_ScrollList_Commit(self.list)
end

function ZO_MarketListFragment_Keyboard:CanPreview()
    if self.selectedRow ~= nil then
        local productId = self.selectedRow.data.productId
        return CanPreviewMarketProduct(productId)
    end

    return false
end

function ZO_MarketListFragment_Keyboard:IsActivelyPreviewing()
    if self.selectedRow ~= nil then
        local productId = self.selectedRow.data.productId
        return IsPreviewingMarketProduct(productId)
    end

    return false
end

function ZO_MarketListFragment_Keyboard:GetPreviewState()
    local isPreviewing = IsCurrentlyPreviewing()
    local canPreview = false
    local isActivePreview = false

    if self.selectedRow ~= nil then
        
        canPreview = IsCharacterPreviewingAvailable() and self:CanPreview()

        if isPreviewing and self:IsActivelyPreviewing() then
            isActivePreview = true
        end
    end

    return isPreviewing, canPreview, isActivePreview
end

function ZO_MarketListFragment_Keyboard:IsReadyToPreview()
    local _, canPreview, isActivePreview = self:GetPreviewState()
    return canPreview and not isActivePreview
end

function ZO_MarketListFragment_Keyboard:GetSelectedProductId()
    if self.selectedRow ~= nil then
        return self.selectedRow.data.productId
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

function ZO_MarketListFragment_Keyboard:OnMouseEnter(control)
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

function ZO_MarketListFragment_Keyboard:OnMouseExit(control)
    SetListHighlightHidden(control, true)

    local icon = control.iconControl
    if icon.animation then
        icon.animation:PlayBackward()
    end

    ClearTooltip(ItemTooltip)

    self.selectedRow = nil

    self.owner:RefreshActions()
end

function ZO_MarketListFragment_Keyboard:OnMouseUp(control, button)
    if button == MOUSE_BUTTON_INDEX_LEFT and self:IsReadyToPreview() then
        self.owner:PreviewMarketProduct(self:GetSelectedProductId())
    end
end
