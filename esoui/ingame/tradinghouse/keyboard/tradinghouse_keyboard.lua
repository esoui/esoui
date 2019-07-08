--[[
    Trading House Manager
--]]

local ZO_TradingHouseManager = ZO_TradingHouse_Shared:Subclass()

function ZO_TradingHouseManager:New(...)
    local manager = ZO_TradingHouse_Shared.New(self, ...)
    return manager
end

function ZO_TradingHouseManager:Initialize(control)
    ZO_TradingHouse_Shared.Initialize(self, control)
    self.initialized = false
    self.titleLabel = control:GetNamedChild("TitleLabel")
    TRADING_HOUSE_SCENE = ZO_InteractScene:New("tradinghouse", SCENE_MANAGER, ZO_TRADING_HOUSE_INTERACTION)
    SYSTEMS:RegisterKeyboardRootScene(ZO_TRADING_HOUSE_SYSTEM_NAME, TRADING_HOUSE_SCENE)
end

function ZO_TradingHouseManager:InitializeScene()
    local function SceneStateChange(oldState, newState)
        if newState == SCENE_SHOWING then
            self:UpdateFragments()
        elseif newState == SCENE_HIDING then
            SetPendingItemPost(BAG_BACKPACK, 0, 0)
            ClearMenu()
            ZO_InventorySlot_RemoveMouseOverKeybinds()
        elseif newState == SCENE_HIDDEN then
            self:ClearSearchResults()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            self.keybindStripDescriptor = nil
        end
    end

    TRADING_HOUSE_SCENE:RegisterCallback("StateChange", SceneStateChange)
end

function ZO_TradingHouseManager:InitializeEvents()
    local function FilterForKeyboardEvents(callback)
        return function(...)
            if not IsInGamepadPreferredMode() then
                callback(...)
            end
        end
    end

    TRADING_HOUSE_SEARCH:RegisterCallback("OnSearchStateChanged", FilterForKeyboardEvents(function(...) self:OnSearchStateChanged(...) end))
    TRADING_HOUSE_SEARCH:RegisterCallback("OnAwaitingResponse", FilterForKeyboardEvents(function(...) self:OnAwaitingResponse(...) end))
    TRADING_HOUSE_SEARCH:RegisterCallback("OnResponseReceived", FilterForKeyboardEvents(function(...) self:OnResponseReceived(...) end))
    TRADING_HOUSE_SEARCH:RegisterCallback("OnSelectedGuildChanged", FilterForKeyboardEvents(function() self:UpdateForGuildChange() end))

    TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD:RegisterCallback("MouseOverRowChanged", function()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end)

    local function OnUpdateStatus()
        self:UpdateStatus()
    end
    self.control:RegisterForEvent(EVENT_TRADING_HOUSE_STATUS_RECEIVED, FilterForKeyboardEvents(OnUpdateStatus))

    local function OnOperationTimeout()
        self:OnOperationTimeout()
    end
    self.control:RegisterForEvent(EVENT_TRADING_HOUSE_OPERATION_TIME_OUT, FilterForKeyboardEvents(OnOperationTimeout))
    
    local function OnPendingPostItemUpdated(_, slotId, isPending)
        self:OnPendingPostItemUpdated(slotId, isPending)
    end
    self.control:RegisterForEvent(EVENT_TRADING_HOUSE_PENDING_ITEM_UPDATE, FilterForKeyboardEvents(OnPendingPostItemUpdated))

    local function OnConfirmPendingPurchase(_, pendingPurchaseIndex)
        if pendingPurchaseIndex ~= nil then
            self:ConfirmPendingPurchase(pendingPurchaseIndex)
        end
    end
    self.control:RegisterForEvent(EVENT_TRADING_HOUSE_CONFIRM_ITEM_PURCHASE, FilterForKeyboardEvents(OnConfirmPendingPurchase))
end

function ZO_TradingHouseManager:InitializeKeybindDescriptor()
    local switchGuildsKeybind =
    {
        name = function()
            local selectedGuildId = GetSelectedTradingHouseGuildId()
            if selectedGuildId then
                return GetGuildName(selectedGuildId)
            end
        end,
        keybind = "UI_SHORTCUT_TERTIARY",
        visible = function()
            return GetNumTradingHouseGuilds() > 1
        end,
        enabled = function()
            return TRADING_HOUSE_SEARCH:CanDoCommonOperation()
        end,
        callback = function()
            ZO_Dialogs_ShowDialog("SELECT_TRADING_HOUSE_GUILD")
        end,
    }

    self.browseKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Do Search
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_TRADING_HOUSE_DO_SEARCH),

            callback = function()
                TRADING_HOUSE_SEARCH:DoSearch()
            end,
        },

        --Switch Guilds
        switchGuildsKeybind,
        
        --Reset Search / Delete Search History Entry
        {
            name = function()
                if TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD:GetMouseOverSearchTable() then
                    return GetString(SI_TRADING_HOUSE_DELETE_SEARCH_HISTORY_ENTRY)
                else
                    return GetString(SI_TRADING_HOUSE_RESET_SEARCH)
                end
            end,
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                local mouseOverSearchTable = TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD:GetMouseOverSearchTable()
                if mouseOverSearchTable then
                    TRADING_HOUSE_SEARCH_HISTORY_MANAGER:RemoveSearchTable(mouseOverSearchTable)
                else
                    self:ClearSearchResults()
                    self:ResetSearchTerms()
                    TRADING_HOUSE_SEARCH:ResetAllSearchData()
                    TRADING_HOUSE_SEARCH:CancelPendingSearch()
                end
            end,
        },

        --End Preview
        {
            name = GetString(SI_CRAFTING_EXIT_PREVIEW_MODE),
            keybind = "UI_SHORTCUT_QUATERNARY",
            visible = function()
                return ITEM_PREVIEW_KEYBOARD:IsInteractionCameraPreviewEnabled()
            end,
            callback = function()
                self:TogglePreviewMode()
            end,
        },
    }

    self.sellKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Post Item
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_TRADING_HOUSE_POST_ITEM),

            callback = function()
                if self:CanPostWithMoneyCheck() then
                    self:PostPendingItem()
                end
            end,

            visible = function()
                return self:CanPost()
            end,

            enabled = function()
                return self:HasEnoughMoneyToPostPendingItem()
            end,
        },

        --Switch Guilds
        switchGuildsKeybind,
    }

    self.listingsKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        --Switch Guilds
        switchGuildsKeybind,
    }
end

function ZO_TradingHouseManager:InitializeMenuBar(control)
    self.menuBar = control:GetNamedChild("MenuBar")
    self.tabLabel = self.menuBar:GetNamedChild("Label")

    local function HandleTabSwitch(tabData)
        self:HandleTabSwitch(tabData)
    end

    local function LayoutSellTabTooltip(tooltip)
        local guildId = GetSelectedTradingHouseGuildId()
        local tooltipText
        if not IsPlayerInGuild(guildId) then
            tooltipText = GetString(SI_TRADING_HOUSE_POSTING_LOCKED_NOT_A_GUILD_MEMBER)
        elseif not DoesGuildHavePrivilege(guildId, GUILD_PRIVILEGE_TRADING_HOUSE) then
            tooltipText = zo_strformat(GetString(SI_TRADING_HOUSE_POSTING_LOCKED_NO_PERMISSION_GUILD), GetNumGuildMembersRequiredForPrivilege(GUILD_PRIVILEGE_TRADING_HOUSE))
        elseif not DoesPlayerHaveGuildPermission(guildId, GUILD_PERMISSION_STORE_SELL) then
            tooltipText = GetString(SI_TRADING_HOUSE_POSTING_LOCKED_NO_PERMISSION_PLAYER)
        else
            tooltipText = GetString(SI_TRADING_HOUSE_MODE_SELL)
        end

        SetTooltipText(tooltip, tooltipText)
    end

    local iconData =
    {
        {
            categoryName = SI_TRADING_HOUSE_MODE_BROWSE,
            descriptor = ZO_TRADING_HOUSE_MODE_BROWSE,
            normal = "EsoUI/Art/TradingHouse/tradinghouse_browse_tabIcon_up.dds",
            pressed = "EsoUI/Art/TradingHouse/tradinghouse_browse_tabIcon_down.dds",
            disabled = "EsoUI/Art/TradingHouse/tradinghouse_browse_tabIcon_disabled.dds",
            highlight = "EsoUI/Art/TradingHouse/tradinghouse_browse_tabIcon_over.dds",
            callback = HandleTabSwitch,
        },
        {
            categoryName = SI_TRADING_HOUSE_MODE_SELL,
            descriptor = ZO_TRADING_HOUSE_MODE_SELL,
            normal = "EsoUI/Art/TradingHouse/tradinghouse_sell_tabIcon_up.dds",
            pressed = "EsoUI/Art/TradingHouse/tradinghouse_sell_tabIcon_down.dds",
            disabled = "EsoUI/Art/TradingHouse/tradinghouse_sell_tabIcon_disabled.dds",
            highlight = "EsoUI/Art/TradingHouse/tradinghouse_sell_tabIcon_over.dds",
            callback = HandleTabSwitch,
            CustomTooltipFunction = LayoutSellTabTooltip,
            alwaysShowTooltip = true,
        },
        {
            categoryName = SI_TRADING_HOUSE_MODE_LISTINGS,
            descriptor = ZO_TRADING_HOUSE_MODE_LISTINGS,
            normal = "EsoUI/Art/TradingHouse/tradinghouse_listings_tabIcon_up.dds",
            pressed = "EsoUI/Art/TradingHouse/tradinghouse_listings_tabIcon_down.dds",
            disabled = "EsoUI/Art/TradingHouse/tradinghouse_listings_tabIcon_disabled.dds",
            highlight = "EsoUI/Art/TradingHouse/tradinghouse_listings_tabIcon_over.dds",
            callback = HandleTabSwitch,
        },
    }

    for _, button in ipairs(iconData) do
        ZO_MenuBar_AddButton(self.menuBar, button)
    end
end

function ZO_TradingHouseManager:HandleTabSwitch(tabData)
    local mode = tabData.descriptor
    self:SetCurrentMode(mode)
    self.tabLabel:SetText(GetString(tabData.categoryName))

    local notSellMode = mode ~= ZO_TRADING_HOUSE_MODE_SELL
    local notBrowseMode = mode ~= ZO_TRADING_HOUSE_MODE_BROWSE
    local notListingsMode = mode ~= ZO_TRADING_HOUSE_MODE_LISTINGS

    -- sell mode controls
    self.postItemPane:SetHidden(notSellMode)

    -- search/browse mode controls
    self.browseItemsLeftPane:SetHidden(notBrowseMode)
    self.itemNameSearch:SetHidden(notBrowseMode)
    self.itemNameSearchLabel:SetHidden(notBrowseMode)
    self.searchResultsList:SetHidden(notBrowseMode)
    self.searchSortHeadersControl:SetHidden(notBrowseMode)
    self.nagivationBar:SetHidden(notBrowseMode)
    self.searchResultsMessageContainer:SetHidden(notBrowseMode)
    self.subcategoryTabsControl:SetHidden(notBrowseMode)
    self.featureAreaControl:SetHidden(notBrowseMode)

    -- player listings mode controls
    self.postedItemsList:SetHidden(notListingsMode)
    self.postedItemsHeader:SetHidden(notListingsMode)
    self.noPostedItemsContainer:SetHidden(notListingsMode)

    if mode == ZO_TRADING_HOUSE_MODE_LISTINGS then
        self:RefreshListings()
    end

    if mode == ZO_TRADING_HOUSE_MODE_SELL then
        self:UpdateListingCounts()
    end

    local newKeybindStripDescriptor
    if mode == ZO_TRADING_HOUSE_MODE_BROWSE then
        newKeybindStripDescriptor = self.browseKeybindStripDescriptor
    elseif mode == ZO_TRADING_HOUSE_MODE_SELL then
        newKeybindStripDescriptor = self.sellKeybindStripDescriptor
    else
        newKeybindStripDescriptor = self.listingsKeybindStripDescriptor
    end
    if self.keybindStripDescriptor ~= newKeybindStripDescriptor then
        if self.keybindStripDescriptor then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
        self.keybindStripDescriptor = newKeybindStripDescriptor
        KEYBIND_STRIP:AddKeybindButtonGroup(newKeybindStripDescriptor)
    end

    if ITEM_PREVIEW_KEYBOARD:IsInteractionCameraPreviewEnabled() and notBrowseMode then
        self:TogglePreviewMode()
    else
        self:UpdateFragments()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_TradingHouseManager:UpdateFragments()
    if TRADING_HOUSE_SCENE:IsShowing() then
        if self:IsInSellMode() then
            SCENE_MANAGER:AddFragment(INVENTORY_FRAGMENT)
        else
            SCENE_MANAGER:RemoveFragment(INVENTORY_FRAGMENT)
        end

        if self:IsInListingsMode() then
            SCENE_MANAGER:RemoveFragment(TREE_UNDERLAY_FRAGMENT)
        else
            SCENE_MANAGER:AddFragment(TREE_UNDERLAY_FRAGMENT)
        end

        if self:IsInSearchMode() and not ITEM_PREVIEW_KEYBOARD:IsInteractionCameraPreviewEnabled() then
            SCENE_MANAGER:AddFragment(TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD_FRAGMENT)
        else
            SCENE_MANAGER:RemoveFragment(TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD_FRAGMENT)
        end
    end
end

function ZO_TradingHouseManager:HasValidPendingItemPost()
    return self.pendingItemSlot ~= nil
end

function ZO_TradingHouseManager:HasEnoughMoneyToPostPendingItem()
    return self:HasValidPendingItemPost() and self.pendingSaleIsValid
end

function ZO_TradingHouseManager:CanPost()
    return TRADING_HOUSE_SEARCH:CanDoCommonOperation() and self:IsInSellMode()
end

function ZO_TradingHouseManager:CanPostWithMoneyCheck()
    return TRADING_HOUSE_SEARCH:CanDoCommonOperation() and self:IsInSellMode() and self:HasEnoughMoneyToPostPendingItem()
end

function ZO_TradingHouseManager:InitializePostItem(control)
    self.postItemPane = control:GetNamedChild("PostItemPane")
    self.pendingItemBG = self.postItemPane:GetNamedChild("PendingBG")
    self.pendingItemName = self.postItemPane:GetNamedChild("FormInfoName")
    self.pendingItem = self.postItemPane:GetNamedChild("FormInfoItem")
    self.currentListings = self.postItemPane:GetNamedChild("FormInfoListingCount")
    self.invoice = self.postItemPane:GetNamedChild("FormInvoice")
    self.invoiceSellPrice = self.invoice:GetNamedChild("SellPriceAmount")
    self.invoiceListingFee = self.invoice:GetNamedChild("ListingFeePrice")
    self.invoiceTheirCut = self.invoice:GetNamedChild("TheirCutPrice")
    self.invoiceProfit = self.invoice:GetNamedChild("ProfitAmount")

    self:OnPendingPostItemUpdated(0, false)
end

function ZO_TradingHouseManager:InitializeBrowseItems(control)
    self.browseItemsLeftPane = control:GetNamedChild("BrowseItemsLeftPane")
    self.itemNameSearch = control:GetNamedChild("ItemNameSearch")
    self.itemNameSearchLabel = control:GetNamedChild("ItemNameSearchLabel")
    self.itemNameSearchAutoComplete = control:GetNamedChild("ItemNameSearchAutoComplete")

    self.itemPane = control:GetNamedChild("BrowseItemsRightPane")
    self.subcategoryTabsControl = control:GetNamedChild("SubcategoryTabs")
    self.nagivationBar = control:GetNamedChild("SearchControls")

    self.featureAreaControl = self.itemPane:GetNamedChild("FeatureArea")
    self.searchSortHeadersControl = self.itemPane:GetNamedChild("SearchSortBy")
    self.searchResultsList = self.itemPane:GetNamedChild("SearchResults")
    self.searchResultsMessageContainer = self.itemPane:GetNamedChild("SearchResultsMessageContainer")
    self.searchResultsMessageLabel = self.searchResultsMessageContainer:GetNamedChild("Message")

    self:InitializeSearchTerms()
    self:InitializeSearchResults(control)
    self:InitializeSearchSortHeaders(control)
    self:InitializeSearchNavigationBar(control)
    self:ClearSearchResults()
end

function ZO_TradingHouseManager:InitializeSearchSortHeaders(control)
    local sortHeaders = ZO_SortHeaderGroup:New(self.searchSortHeadersControl, true)
    self.searchSortHeaders = sortHeaders

    local function OnSortHeaderClicked(key, order)
        TRADING_HOUSE_SEARCH:ChangeSort(key, order)
    end

    sortHeaders:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, OnSortHeaderClicked)
    sortHeaders:AddHeadersFromContainer()

    local DONT_FORCE_RESELECT = nil
    local sortKey, sortOrder = TRADING_HOUSE_SEARCH:GetSortOptions()
    sortHeaders:SelectHeaderByKey(sortKey, ZO_SortHeaderGroup.SUPPRESS_CALLBACKS, DONT_FORCE_RESELECT, sortOrder)
end

function ZO_TradingHouseManager:InitializeSearchNavigationBar(control)
    self.resultCount = self.nagivationBar:GetNamedChild("ResultCount")
    self.previousPage = self.nagivationBar:GetNamedChild("PreviousPage")
    self.nextPage = self.nagivationBar:GetNamedChild("NextPage")
    self.pageNumberLabel = self.nagivationBar:GetNamedChild("PageNumber")

    local moneyControl = self.nagivationBar:GetNamedChild("Money")
    local function UpdateMoney()
        self.playerMoney[CURT_MONEY] = GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
        ZO_CurrencyControl_SetSimpleCurrency(moneyControl, CURT_MONEY, self.playerMoney[CURT_MONEY], ZO_KEYBOARD_CURRENCY_OPTIONS)
    end

    moneyControl:RegisterForEvent(EVENT_MONEY_UPDATE, UpdateMoney)
    UpdateMoney()

    local function UpdateAlliancePoints()
        self.playerMoney[CURT_ALLIANCE_POINTS] = GetCurrencyAmount(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_CHARACTER)
    end

    moneyControl:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, UpdateAlliancePoints)
    UpdateAlliancePoints()

    self.previousPage:SetHandler("OnClicked", function() TRADING_HOUSE_SEARCH:SearchPreviousPage() end)
    self.nextPage:SetHandler("OnClicked", function() TRADING_HOUSE_SEARCH:SearchNextPage() end)
end

function ZO_TradingHouseManager:ToggleLevelRangeMode()
    if self.levelRangeFilterType == TRADING_HOUSE_FILTER_TYPE_LEVEL then
        self.levelRangeFilterType = TRADING_HOUSE_FILTER_TYPE_CHAMPION_POINTS
        self.levelRangeToggle:SetState(BSTATE_PRESSED, true)
        self.levelRangeLabel:SetText(GetString(SI_TRADING_HOUSE_BROWSE_CHAMPION_POINTS_RANGE_LABEL))
    else
        self.levelRangeFilterType = TRADING_HOUSE_FILTER_TYPE_LEVEL
        self.levelRangeToggle:SetState(BSTATE_NORMAL, false)
        self.levelRangeLabel:SetText(GetString(SI_TRADING_HOUSE_BROWSE_LEVEL_RANGE_LABEL))
    end
end

function ZO_TradingHouseManager:InitializeSearchTerms()
    local globalFeatureArea = self.browseItemsLeftPane:GetNamedChild("GlobalFeatureArea")

    -- Name Search
    local nameSearchFeature = ZO_TradingHouse_CreateKeyboardFeature("NameSearch")
    nameSearchFeature:AttachToControl(self.itemNameSearch, self.itemNameSearchAutoComplete)
    self.itemNameSearchLabel:SetText(nameSearchFeature:GetDisplayName())

    -- Category List
    local categoryListControl = self.browseItemsLeftPane:GetNamedChild("CategoryListContainer")
    local subCategoryTabsControl = self.subcategoryTabsControl
    local featuresParentControl = self.featureAreaControl

    local searchCategoryFeature = ZO_TradingHouse_CreateKeyboardFeature("SearchCategory")
    searchCategoryFeature:AttachToControl(categoryListControl, subCategoryTabsControl, featuresParentControl)

    -- Quality dropdown
    local qualityFeature = ZO_TradingHouse_CreateKeyboardFeature("Quality")
    qualityFeature:AttachToControl(globalFeatureArea:GetNamedChild("Quality"))

    -- Price range
    local priceRangeFeature = ZO_TradingHouse_CreateKeyboardFeature("PriceRange")
    priceRangeFeature:AttachToControl(globalFeatureArea:GetNamedChild("PriceRange"))

    self.features =
    {
        nameSearchFeature = nameSearchFeature,
        searchCategoryFeature = searchCategoryFeature,
        qualityFeature = qualityFeature,
        priceRangeFeature = priceRangeFeature,
    }

    self:ResetSearchTerms()
end

local SEARCH_RESULTS_DATA_TYPE = 1
local ITEM_LISTINGS_DATA_TYPE = 2
local GUILD_SPECIFIC_ITEM_DATA_TYPE = 3

local ITEM_RESULT_CURRENCY_OPTIONS =
{
    showTooltips = false,
    font = "ZoFontGameShadow",
    iconSide = RIGHT,
}

function ZO_TradingHouseManager:InitializeSearchResults(control)
    self.searchResultsControlsList = {}
    self.searchResultsInfoList = {}

    local function SetupBaseSearchResultRow(rowControl, result)
        self.searchResultsControlsList[#self.searchResultsControlsList+1] = rowControl
        self.searchResultsInfoList[#self.searchResultsInfoList+1] = result
        local slotIndex = result.slotIndex

        local nameControl = GetControl(rowControl, "Name")
        nameControl:SetText(ZO_TradingHouse_GetItemDataFormattedName(result))
        local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, result.quality)
        nameControl:SetColor(r, g, b, 1)

        local traitInformationControl = GetControl(rowControl, "TraitInfo")
        traitInformationControl:ClearIcons()

        if not result.isGuildSpecificItem then
            local traitInformation = GetItemTraitInformationFromItemLink(result.itemLink)
        
            if traitInformation ~= ITEM_TRAIT_INFORMATION_NONE then
                traitInformationControl:AddIcon(GetPlatformTraitInformationIcon(traitInformation))
                traitInformationControl:Show()
            end
        end

        local sellPricePerUnitControl = GetControl(rowControl, "SellPricePerUnit")
        ZO_CurrencyControl_SetSimpleCurrency(sellPricePerUnitControl, result.currencyType, result.purchasePricePerUnit, ITEM_RESULT_CURRENCY_OPTIONS, nil, false)

        local sellPriceControl = GetControl(rowControl, "SellPrice")
        ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl, result.currencyType, result.purchasePrice, ITEM_RESULT_CURRENCY_OPTIONS, nil, self.playerMoney[result.currencyType] < result.purchasePrice)

        local resultControl = GetControl(rowControl, "Button")
        ZO_Inventory_SetupSlot(resultControl, result.stackCount, result.icon)

        -- Cached for verification when the player tries to purchase this
        resultControl.sellerName = result.sellerName
        resultControl.purchasePrice = result.purchasePrice
        resultControl.currencyType = result.currencyType

        return resultControl
    end

    local function SetupSearchResultRow(rowControl, result)
        local resultControl = SetupBaseSearchResultRow(rowControl, result)

        local timeRemainingControl = GetControl(rowControl, "TimeRemaining")
        local timeRemainingString = ZO_TradingHouse_GetItemDataFormattedTime(result)
        timeRemainingControl:SetText(timeRemainingString)

        ZO_Inventory_BindSlot(resultControl, SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT, result.slotIndex)
    end

    local function SetupGuildSpecificItemRow(rowControl, result)
        local resultControl = SetupBaseSearchResultRow(rowControl, result)
        ZO_Inventory_BindSlot(resultControl, SLOT_TYPE_GUILD_SPECIFIC_ITEM, result.slotIndex)
    end

    ZO_ScrollList_Initialize(self.searchResultsList)
    ZO_ScrollList_AddDataType(self.searchResultsList, SEARCH_RESULTS_DATA_TYPE, "ZO_TradingHouseSearchResult", 52, SetupSearchResultRow, nil, nil, ZO_InventorySlot_OnPoolReset)
    ZO_ScrollList_AddDataType(self.searchResultsList, GUILD_SPECIFIC_ITEM_DATA_TYPE, "ZO_TradingHouseSearchResult", 52, SetupGuildSpecificItemRow, nil, nil, ZO_InventorySlot_OnPoolReset)
    ZO_ScrollList_AddResizeOnScreenResize(self.searchResultsList)
end

function ZO_TradingHouseManager:InitializeListings(control)
    self.postedItemsHeader = control:GetNamedChild("PostedItemsHeader")
    local postedItemsList = control:GetNamedChild("PostedItemsList")
    self.postedItemsList = postedItemsList

    self.noPostedItemsContainer = control:GetNamedChild("PostedItemsNoItemsContainer")
    self.noPostedItemsLabel = self.noPostedItemsContainer:GetNamedChild("NoItems")

    local function CancelListing(cancelButton)
        local postedItem = cancelButton:GetParent():GetNamedChild("Button")
        local listingIndex = ZO_Inventory_GetSlotIndex(postedItem)
        self:ShowCancelListingConfirmation(listingIndex)
    end

    local function SetupPostedItemRow(rowControl, postedItem)
        local index = postedItem.slotIndex

        local nameControl = GetControl(rowControl, "Name")
        nameControl:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, postedItem.name))
        local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, postedItem.quality)
        nameControl:SetColor(r, g, b, 1)

        local timeRemainingControl = GetControl(rowControl, "TimeRemaining")
        timeRemainingControl:SetText(zo_strformat(SI_TRADING_HOUSE_BROWSE_ITEM_REMAINING_TIME, ZO_FormatTime(postedItem.timeRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)))

        local sellPriceControl = GetControl(rowControl, "SellPrice")
        ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl, CURT_MONEY, postedItem.purchasePrice, ITEM_RESULT_CURRENCY_OPTIONS)

        local postedItemControl = GetControl(rowControl, "Button")
        ZO_Inventory_BindSlot(postedItemControl, SLOT_TYPE_TRADING_HOUSE_ITEM_LISTING, index)
        ZO_Inventory_SetupSlot(postedItemControl, postedItem.stackCount, postedItem.icon)

        local cancelButton = GetControl(rowControl, "CancelSale")
        cancelButton:SetHandler("OnClicked", CancelListing)
    end

    ZO_ScrollList_Initialize(postedItemsList)
    ZO_ScrollList_AddDataType(postedItemsList, ITEM_LISTINGS_DATA_TYPE, "ZO_TradingHouseItemListing", 52, SetupPostedItemRow, nil, nil, ZO_InventorySlot_OnPoolReset)
    ZO_ScrollList_AddResizeOnScreenResize(postedItemsList)
end

function ZO_TradingHouseManager:RebuildListingsScrollList()
    local list = self.postedItemsList
    local scrollData = ZO_ScrollList_GetDataList(list)
    ZO_ScrollList_Clear(list)

    for i = 1, GetNumTradingHouseListings() do
        local itemData = ZO_TradingHouse_CreateListingItemData(i)
        if itemData then
            scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(ITEM_LISTINGS_DATA_TYPE, itemData)
        end
    end

    ZO_ScrollList_Commit(list)

    self.noPostedItemsLabel:SetHidden(#scrollData > 0)
end

function ZO_TradingHouseManager:OnPendingPostItemUpdated(slotId, isPending)
    self.pendingSaleIsValid = false

    if isPending then
        self.pendingItemSlot = slotId
        self:SetupPendingPost(slotId)
    else
        self.pendingItemSlot = nil
        self:ClearPendingPost()
    end

    self:UpdateListingCounts()
end

function ZO_TradingHouseManager:OnPostSuccess()
    -- convenience wrapper for clearing out the pending item and updating the post count
    self:OnPendingPostItemUpdated()
end

function ZO_TradingHouseManager:UpdateListingCounts()
    local currentListings, maxListings = GetTradingHouseListingCounts()
    if currentListings < maxListings then
        self.currentListings:SetText(zo_strformat(SI_TRADING_HOUSE_LISTING_COUNT, currentListings, maxListings))
    else
        self.currentListings:SetText(zo_strformat(SI_TRADING_HOUSE_LISTING_COUNT_FULL, currentListings, maxListings))
    end
end

local INVOICE_CURRENCY_OPTIONS =
{
    showTooltips = false,
    font = "ZoFontWinT1",
}

function ZO_TradingHouseManager:SetInvoicePriceColors(color)
    local r, g, b = color:UnpackRGB()
    self.invoiceListingFee:SetColor(r, g, b)
    self.invoiceTheirCut:SetColor(r, g, b)
    self.invoiceProfit:SetColor(r, g, b)
end

-- Only called from the CURRENCY_INPUT control callback chain
function ZO_TradingHouseManager:SetPendingPostPrice(sellPrice)
    sellPrice = tonumber(sellPrice) or 0
    self.invoiceSellPrice.sellPrice = sellPrice

    ZO_CurrencyControl_SetSimpleCurrency(self.invoiceSellPrice, CURT_MONEY, sellPrice, INVOICE_CURRENCY_OPTIONS)

    self:SetInvoicePriceColors(ZO_DEFAULT_ENABLED_COLOR)

    if self.pendingItemSlot then
        local listingFee, tradingHouseCut, profit = GetTradingHousePostPriceInfo(sellPrice)

        ZO_CurrencyControl_SetSimpleCurrency(self.invoiceListingFee, CURT_MONEY, listingFee, INVOICE_CURRENCY_OPTIONS)
        ZO_CurrencyControl_SetSimpleCurrency(self.invoiceTheirCut, CURT_MONEY, tradingHouseCut, INVOICE_CURRENCY_OPTIONS)
        ZO_CurrencyControl_SetSimpleCurrency(self.invoiceProfit, CURT_MONEY, profit, INVOICE_CURRENCY_OPTIONS)

        -- verify the user has enough cash
        if (GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) - listingFee) >= 0 then
            self.pendingSaleIsValid = true
        else
            self.pendingSaleIsValid = false
            self:SetInvoicePriceColors(ZO_ERROR_COLOR)
        end
    else
        self.invoiceListingFee:SetText("0")
        self.invoiceTheirCut:SetText("0")
        self.invoiceProfit:SetText("0")
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TradingHouseManager:GetPendingPostPrice()
    return self.invoiceSellPrice.sellPrice
end

function ZO_TradingHouseManager:SetupPendingPost()
    if self.pendingItemSlot then
        local icon, stackCount, sellPrice = GetItemInfo(BAG_BACKPACK, self.pendingItemSlot)
        ZO_Inventory_BindSlot(self.pendingItem, SLOT_TYPE_TRADING_HOUSE_POST_ITEM, self.pendingItemSlot, BAG_BACKPACK)
        ZO_ItemSlot_SetupSlot(self.pendingItem, stackCount, icon)
        self.pendingItemName:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(BAG_BACKPACK, self.pendingItemSlot)))

        self.pendingItemBG:SetHidden(false)
        self.invoice:SetHidden(false)

        local initialPostPrice = ZO_TradingHouse_CalculateItemSuggestedPostPrice(BAG_BACKPACK, self.pendingItemSlot)
        self:SetPendingPostPrice(initialPostPrice)

        ZO_InventorySlot_HandleInventoryUpdate(self.pendingItem)
    end
end

function ZO_TradingHouseManager:ClearPendingPost()
    ZO_Inventory_BindSlot(self.pendingItem, SLOT_TYPE_TRADING_HOUSE_POST_ITEM)
    ZO_ItemSlot_SetupSlot(self.pendingItem, 0, "EsoUI/Art/TradingHouse/tradinghouse_emptySellSlot_icon.dds")
    self.pendingItemName:SetText(GetString(SI_TRADING_HOUSE_SELECT_AN_ITEM_TO_SELL))

    self.pendingItemBG:SetHidden(true)
    self.invoice:SetHidden(true)
    self:SetPendingPostPrice(0)
    ZO_InventorySlot_HandleInventoryUpdate(self.pendingItem)
end

function ZO_TradingHouseManager:PostPendingItem()
    if self.pendingItemSlot and self.pendingSaleIsValid then
        local stackCount = ZO_InventorySlot_GetStackCount(self.pendingItem)
        local desiredPrice = self.invoiceSellPrice.sellPrice or 0
        RequestPostItemOnTradingHouse(BAG_BACKPACK, self.pendingItemSlot, stackCount, desiredPrice)
    end
end

function ZO_TradingHouseManager:RefreshListings()
    if HasTradingHouseListings() then
        self:RebuildListingsScrollList()
    else
        self:ClearListedItems()
        if TRADING_HOUSE_SEARCH:CanDoCommonOperation() then
            self.requestListings = false
            RequestTradingHouseListings()
        else
            -- only queue the request if we are not currently waiting for a listings response
            if not TRADING_HOUSE_SEARCH:IsWaitingForResponseType(TRADING_HOUSE_RESULT_LISTINGS_PENDING) then
                self.requestListings = true
            end
        end
    end
end

function ZO_TradingHouseManager:OnSearchStateChanged(searchState, searchOutcome)
    if searchState == TRADING_HOUSE_SEARCH_STATE_NONE then
        self.previousPage:SetHidden(true)
        self.nextPage:SetHidden(true)
        self.searchResultsMessageLabel:SetHidden(true)
        self.resultCount:SetHidden(true)
        self.pageNumberLabel:SetHidden(true)
    elseif searchState == TRADING_HOUSE_SEARCH_STATE_WAITING then
        --Update the page number while we're waiting for it to load (page number is 0 based). The page number label may not have been shown yet since we don't show it until the initial search completes, but
        --we update it here for when it does show.
        local targetPage = TRADING_HOUSE_SEARCH:GetTargetPage() or 0
        self.pageNumberLabel:SetText(targetPage + 1)
        
        --Clear the result count label until we know the number of results
        self.resultCount:SetText(zo_strformat(SI_TRADING_HOUSE_RESULT_COUNT, ""))
        
        self:ShowSearchResultMessage(GetString("SI_TRADINGHOUSESEARCHSTATE", searchState))
    elseif searchState == TRADING_HOUSE_SEARCH_STATE_COMPLETE then
        if searchOutcome == TRADING_HOUSE_SEARCH_OUTCOME_HAS_RESULTS then
            self.searchResultsMessageLabel:SetHidden(true)
            self:RebuildSearchResultsPage()
            ZO_ScrollList_ResetToTop(self.searchResultsList)
        else
            self.resultCount:SetText(zo_strformat(SI_TRADING_HOUSE_RESULT_COUNT, 0))
            self:ShowSearchResultMessage(GetString("SI_TRADINGHOUSESEARCHOUTCOME", searchOutcome))
        end
    end
end

function ZO_TradingHouseManager:OnAwaitingResponse(responseType)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TradingHouseManager:OnResponseReceived(responseType, result)
    local success = result == TRADING_HOUSE_RESULT_SUCCESS

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

    if responseType == TRADING_HOUSE_RESULT_POST_PENDING then
        if success then
            self:OnPostSuccess()
            self:RefreshListings()
        end
    elseif responseType == TRADING_HOUSE_RESULT_SEARCH_PENDING then
        if success then
            -- Hide the fictional "awaiting search results" animation?
        end
    elseif responseType == TRADING_HOUSE_RESULT_PURCHASE_PENDING then
        if success then
            self:OnPurchaseSuccess()
        end
    elseif responseType == TRADING_HOUSE_RESULT_LISTINGS_PENDING then
        if success then
            self:RefreshListings()
            self.requestListings = false -- make sure that we don't request again right after we get an answer.
        end
    elseif responseType == TRADING_HOUSE_RESULT_CANCEL_SALE_PENDING then
        if success then
            -- Refresh all listings when the cancel goes through
            -- This doesn't need to ensure that the listings were received because the interface to cancel a listing requires that
            -- the listings have been received from the server.
            self:RefreshListings()
        end
    end

    if self.requestListings then
        self:RefreshListings()
    end
end

function ZO_TradingHouseManager:ShowSearchResultMessage(messageText)
    local list = self.searchResultsList
    ZO_ScrollList_Clear(list)
    ZO_ScrollList_Commit(list)

    self.previousPage:SetEnabled(false)
    self.nextPage:SetEnabled(false)

    self.searchResultsMessageLabel:SetHidden(false)
    self.searchResultsMessageLabel:SetText(messageText)
end

function ZO_TradingHouseManager:RebuildSearchResultsPage(isInitialResults)
    local list = self.searchResultsList
    local scrollData = ZO_ScrollList_GetDataList(list)
    ZO_ScrollList_Clear(list)

    local showingGuildSpecificItems = TRADING_HOUSE_SEARCH:ShouldShowGuildSpecificItems() or isInitialResults
    local numItemsOnPage = 0
    if showingGuildSpecificItems then
        for i = 1, GetNumGuildSpecificItems() do
            local result = self:CreateGuildSpecificItemData(i, GetGuildSpecificItemInfo)
            if result then
                scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(GUILD_SPECIFIC_ITEM_DATA_TYPE, result)
                numItemsOnPage = numItemsOnPage + 1
            end
        end
    else
        for i = 1, TRADING_HOUSE_SEARCH:GetNumItemsOnPage() do
            local result = ZO_TradingHouse_CreateSearchResultItemData(i)
            if result then
                scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(SEARCH_RESULTS_DATA_TYPE, result)
                numItemsOnPage = numItemsOnPage + 1
            end
        end
    end

    ZO_ScrollList_Commit(list)

    if showingGuildSpecificItems then
        --Don't show the search stats or controls for the guild specific items
        self.pageNumberLabel:SetHidden(true)
        self.resultCount:SetHidden(true)
        self.previousPage:SetHidden(true)
        self.nextPage:SetHidden(true)
    else
        self.previousPage:SetHidden(false)
        self.nextPage:SetHidden(false)
        local hasPreviousPage = TRADING_HOUSE_SEARCH:HasPreviousPage()
        local hasNextPage = TRADING_HOUSE_SEARCH:HasNextPage()
        self.previousPage:SetEnabled(hasPreviousPage)
        self.nextPage:SetEnabled(hasNextPage)

        --The page number is set above while waiting for results, but we don't show it until the first results arrive.
        self.pageNumberLabel:SetHidden(false)

        self.resultCount:SetHidden(false)
        self.resultCount:SetText(zo_strformat(SI_TRADING_HOUSE_RESULT_COUNT, numItemsOnPage))
    end
end

function ZO_TradingHouseManager:OnPurchaseSuccess()
    self:RebuildSearchResultsPage()
end

function ZO_TradingHouseManager:ClearSearchResults()
    ZO_ScrollList_Clear(self.searchResultsList)
    ZO_ScrollList_Commit(self.searchResultsList)

    self.previousPage:SetHidden(true)
    self.nextPage:SetHidden(true)
    self.searchResultsMessageLabel:SetHidden(true)
    self.resultCount:SetHidden(true)
    self.pageNumberLabel:SetHidden(true)
end

function ZO_TradingHouseManager:ClearListedItems()
    ZO_ScrollList_Clear(self.postedItemsList)
    ZO_ScrollList_Commit(self.postedItemsList)
    self.noPostedItemsLabel:SetHidden(false)
end

function ZO_TradingHouseManager:ResetSearchTerms()
    for _, feature in pairs(self.features) do
        feature:ResetSearch()
    end
end

function ZO_TradingHouseManager:OpenTradingHouse()
    if not self.initialized then
        self:RunInitialSetup(self.control)
        self.initialized = true
    end

    self:SetCurrentMode(ZO_TRADING_HOUSE_MODE_BROWSE)
    TRADING_HOUSE_SEARCH:AssociateWithSearchFeatures(self.features)
    ZO_MenuBar_SelectDescriptor(self.menuBar, self:GetCurrentMode())
    self.currentDisplayName = GetDisplayName()
end

function ZO_TradingHouseManager:CloseTradingHouse()
    SYSTEMS:HideScene(ZO_TRADING_HOUSE_SYSTEM_NAME)
    if self.initialized then
        self.currentDisplayName = nil
        self:SetCurrentMode(nil)
        ZO_MenuBar_ClearSelection(self.menuBar)
    end
    TRADING_HOUSE_SEARCH:DisassociateWithSearchFeatures()
end

function ZO_TradingHouseManager:TogglePreviewMode()
    ITEM_PREVIEW_KEYBOARD:ToggleInteractionCameraPreview(FRAME_TARGET_STANDARD_RIGHT_PANEL_FRAGMENT, FRAME_PLAYER_ON_SCENE_HIDDEN_FRAGMENT, RIGHT_BG_EMPTY_WORLD_ITEM_PREVIEW_OPTIONS_FRAGMENT)

    self:UpdateFragments()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TradingHouseManager:PreviewSearchResult(tradingHouseIndex)
    if not ITEM_PREVIEW_KEYBOARD:IsInteractionCameraPreviewEnabled() then
        self:TogglePreviewMode()
    end

    ITEM_PREVIEW_KEYBOARD:PreviewTradingHouseSearchResultAsFurniture(tradingHouseIndex)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

--Override
function ZO_TradingHouseManager:SearchForItemLink(itemLink)
    if TRADING_HOUSE_SCENE:IsShowing() then
        TRADING_HOUSE_SEARCH:LoadSearchItem(itemLink)
        --Changing to browse will add the quaternary bind for preview so we need to get rid of the quaternary bind for search before that
        ZO_InventorySlot_RemoveMouseOverKeybinds()
        ZO_MenuBar_SelectDescriptor(self.menuBar, ZO_TRADING_HOUSE_MODE_BROWSE)
        TRADING_HOUSE_SEARCH:DoSearch()
    end
end

-- Select Active Guild for Trading House Dialog
----------------------

local function SelectTradingHouseGuildDialogInitialize(dialogControl, tradingHouseManager)
    local function SelectTradingHouseGuild(selectedGuildId)
        if selectedGuildId then
            SelectTradingHouseGuildId(selectedGuildId)
        end
    end

    local dialog = ZO_SelectGuildDialog:New(dialogControl, "SELECT_TRADING_HOUSE_GUILD", SelectTradingHouseGuild)
    dialog:SetTitle(SI_PROMPT_TITLE_SELECT_GUILD_STORE)
    dialog:SetPrompt(GetString(SI_SELECT_GUILD_STORE_INSTRUCTIONS))
    dialog:SetCurrentStateSource(GetSelectedTradingHouseGuildId)
end

function ZO_TradingHouseManager:UpdateStatus()
    if not self.changeGuildDialog then
        self.changeGuildDialog = ZO_SelectTradingHouseGuildDialog
        SelectTradingHouseGuildDialogInitialize(self.changeGuildDialog, self)
    end

    self:UpdateForGuildChange()
end

function ZO_TradingHouseManager:OnOperationTimeout()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TradingHouseManager:UpdateForGuildChange()
    local guildId = GetSelectedTradingHouseGuildId()

    if not IsPlayerInGuild(guildId) then
        -- Player is using a Guild Trader
        self:UpdateListingCounts()
        self:ClearListedItems()
        self:ClearPendingPost()
        self:ClearSearchResults()

        ZO_MenuBar_SelectDescriptor(self.menuBar, ZO_TRADING_HOUSE_MODE_BROWSE)

        ZO_MenuBar_SetDescriptorEnabled(self.menuBar, ZO_TRADING_HOUSE_MODE_SELL, false)
        ZO_MenuBar_SetDescriptorEnabled(self.menuBar, ZO_TRADING_HOUSE_MODE_LISTINGS, false)
    else
        -- Player is using a regular Guild Store
        local canSell = CanSellOnTradingHouse(guildId)

        self:UpdateListingCounts()
        if self:GetCurrentMode() == ZO_TRADING_HOUSE_MODE_LISTINGS then
            self:RefreshListings()
        end
        self:ClearPendingPost()
        self:ClearSearchResults()
        local IS_INITIAL_RESULTS = true
        self:RebuildSearchResultsPage(IS_INITIAL_RESULTS)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)

        if self:IsInSellMode() and not canSell then
            ZO_MenuBar_SelectDescriptor(self.menuBar, ZO_TRADING_HOUSE_MODE_BROWSE)
        end

        ZO_MenuBar_SetDescriptorEnabled(self.menuBar, ZO_TRADING_HOUSE_MODE_SELL, canSell)
        ZO_MenuBar_SetDescriptorEnabled(self.menuBar, ZO_TRADING_HOUSE_MODE_LISTINGS, true)
    end

    local _, guildName = GetCurrentTradingHouseGuildDetails()
    if guildName ~= "" then
        self.titleLabel:SetText(guildName)
    else
        self.titleLabel:SetText(GetString(SI_WINDOW_TITLE_TRADING_HOUSE))
    end
end

-- Utility to show a confirmation for some kind of trading house item (listing or search result)
local function SetupTradingHouseItemDialog(dialogControl, itemInfoFn, slotIndex, slotType, costLabelStringId)
    -- Item data is set up on the dialog control before the dialog is shown
    local icon, itemName, quality, stackCount, _, _, purchasePrice, currencyType = itemInfoFn(slotIndex)

    local nameControl = dialogControl:GetNamedChild("ItemName")
    nameControl:SetText(zo_strformat(SI_TOOLTIP_ITEM_NAME, itemName))
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)
    nameControl:SetColor(r, g, b, 1)

    local itemControl = dialogControl:GetNamedChild("Item")
    ZO_Inventory_BindSlot(itemControl, slotType, slotIndex)
    ZO_Inventory_SetupSlot(itemControl, stackCount, icon)

    local costControl = dialogControl:GetNamedChild("Cost")
    costControl:SetHidden(costLabelStringId == nil)
    if costLabelStringId then
        costControl:SetText(zo_strformat(costLabelStringId, ZO_Currency_FormatKeyboard(currencyType, purchasePrice, ZO_CURRENCY_FORMAT_WHITE_AMOUNT_ICON)))
    end
end

-- Confirm Item Purchase Dialog
local function PurchaseItemDialogInitialize(dialogControl, tradingHouseManager)
    ZO_Dialogs_RegisterCustomDialog("CONFIRM_TRADING_HOUSE_PURCHASE",
    {
        customControl = dialogControl,
        setup = function(self) SetupTradingHouseItemDialog(self, GetTradingHouseSearchResultItemInfo, self.purchaseIndex, SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT, SI_TRADING_HOUSE_PURCHASE_ITEM_AMOUNT) end,
        title =
        {
            text = SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_TITLE,
        },
        buttons =
        {
            [1] =
            {
                control =   GetControl(dialogControl, "Accept"),
                text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CONFIRM,
                callback =  function(dialog)
                                ConfirmPendingItemPurchase()
                            end,
            },

            [2] =
            {
                control =   GetControl(dialogControl, "Cancel"),
                text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CANCEL,
                callback =  function(dialog)
                                ClearPendingItemPurchase()
                            end,
            }
        }
    })
end

function ZO_TradingHouseManager:ConfirmPendingPurchase(pendingPurchaseIndex)
    if not self.purchaseDialog then
        self.purchaseDialog = ZO_TradingHousePurchaseItemDialog
        PurchaseItemDialogInitialize(self.purchaseDialog, self)
    end

    self.purchaseDialog.purchaseIndex = pendingPurchaseIndex
    ZO_Dialogs_ShowDialog("CONFIRM_TRADING_HOUSE_PURCHASE")
end

-- Confirm Guild Specific Item Purchase Dialog
local function PurchaseGuildSpecificItemDialogInitialize(dialogControl, tradingHouseManager)
    ZO_Dialogs_RegisterCustomDialog("CONFIRM_TRADING_HOUSE_GUILD_SPECIFIC_PURCHASE",
    {
        customControl = dialogControl,
        setup = function(self) SetupTradingHouseItemDialog(self, GetGuildSpecificItemInfo, self.guildSpecificItemIndex, SLOT_TYPE_GUILD_SPECIFIC_ITEM, SI_TRADING_HOUSE_PURCHASE_ITEM_AMOUNT) end,
        title =
        {
            text = SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_TITLE,
        },
        buttons =
        {
            [1] =
            {
                control =   GetControl(dialogControl, "Accept"),
                text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CONFIRM,
                callback =  function(dialog)
                                BuyGuildSpecificItem(dialog.guildSpecificItemIndex)
                                tradingHouseManager:HandleGuildSpecificPurchase(dialog.guildSpecificItemIndex)
                            end,
            },

            [2] =
            {
                control =   GetControl(dialogControl, "Cancel"),
                text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CANCEL,
                callback =  function(dialog)
                                -- Do nothing
                            end,
            }
        }
    })
end

function ZO_TradingHouseManager:ConfirmPendingGuildSpecificPurchase(guildSpecificItemIndex)
    if not self.purchaseGuildSpecificDialog then
        self.purchaseGuildSpecificDialog = ZO_TradingHousePurchaseItemDialog
        PurchaseGuildSpecificItemDialogInitialize(self.purchaseGuildSpecificDialog, self)
    end

    self.purchaseGuildSpecificDialog.guildSpecificItemIndex = guildSpecificItemIndex
    ZO_Dialogs_ShowDialog("CONFIRM_TRADING_HOUSE_GUILD_SPECIFIC_PURCHASE")
end

function ZO_TradingHouseManager:HandleGuildSpecificPurchase(guildSpecificItemIndex)
    local purchasedItemValue = self.searchResultsInfoList[guildSpecificItemIndex].purchasePrice
    for i = 1, #self.searchResultsControlsList do
    
        local purchasePrice = self.searchResultsInfoList[i].purchasePrice
        local currencyType = self.searchResultsInfoList[i].currencyType

        local sellPriceControl = GetControl(self.searchResultsControlsList[i], "SellPrice")
        ZO_CurrencyControl_SetSimpleCurrency(sellPriceControl, currencyType, purchasePrice, ITEM_RESULT_CURRENCY_OPTIONS, nil, self.playerMoney[currencyType] - purchasedItemValue < purchasePrice)
    end
end

-- Cancel Listing Confirmation Dialog
local function CancelListingDialogInitialize(dialogControl, tradingHouseManager)
    ZO_Dialogs_RegisterCustomDialog("CONFIRM_TRADING_HOUSE_CANCEL_LISTING",
    {
        customControl = dialogControl,
        setup = function(self) SetupTradingHouseItemDialog(self, GetTradingHouseListingItemInfo, self.listingIndex, SLOT_TYPE_TRADING_HOUSE_ITEM_LISTING) end,
        title =
        {
            text = SI_TRADING_HOUSE_CANCEL_LISTING_DIALOG_TITLE,
        },
        buttons =
        {
            [1] =
            {
                control =   GetControl(dialogControl, "Accept"),
                text =      SI_TRADING_HOUSE_CANCEL_LISTING_DIALOG_CONFIRM,
                callback =  function(dialog)
                                CancelTradingHouseListing(dialog.listingIndex)
                                dialog.listingIndex = nil
                            end,
            },

            [2] =
            {
                control =   GetControl(dialogControl, "Cancel"),
                text =      SI_TRADING_HOUSE_CANCEL_LISTING_DIALOG_CANCEL,
                callback =  function(dialog)
                                dialog.listingIndex = nil
                            end,
            }
        }
    })

    -- Update the text on the cancel dialog (since it inherited from the purchase item dialog)
    dialogControl:GetNamedChild("Description"):SetText(GetString(SI_TRADING_HOUSE_CANCEL_LISTING_DIALOG_DESCRIPTION))
end

function ZO_TradingHouseManager:ShowCancelListingConfirmation(listingIndex)
    if not self.cancelListingDialog then
        self.cancelListingDialog = ZO_TradingHouseCancelListingDialog
        CancelListingDialogInitialize(self.cancelListingDialog, self)
    end

    self.cancelListingDialog.listingIndex = listingIndex
    ZO_Dialogs_ShowDialog("CONFIRM_TRADING_HOUSE_CANCEL_LISTING")
end

--[[
    End of Dialog Section
--]]

function ZO_TradingHouseManager:CanBuyItem(inventorySlot)
    if not TRADING_HOUSE_SEARCH:IsAtTradingHouse() then
        return false
    end

    if inventorySlot.sellerName == self.currentDisplayName then
        return false
    end

    return true
end

function ZO_TradingHouseManager:VerifyBuyItemAndShowErrors(inventorySlot)
    if inventorySlot.purchasePrice > self.playerMoney[inventorySlot.currencyType] then
        ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, SOUNDS.PLAYER_ACTION_INSUFFICIENT_GOLD, SI_TRADING_HOUSE_ERROR_NOT_ENOUGH_GOLD)
        return false
    end

    return true
end

function ZO_TradingHouseManager:RunInitialSetup(control)
    self.playerMoney = {}

    self:InitializeEvents()
    self:InitializeKeybindDescriptor()
    self:InitializeMenuBar(control)
    self:InitializePostItem(control)
    self:InitializeBrowseItems(control)
    self:InitializeListings(control)
    self:InitializeScene()
end

local function SetPostPriceCallback(moneyInput, gold, eventType)
    local tradingHouse = moneyInput:GetContext()

    if eventType == "confirm" then
        tradingHouse:SetPendingPostPrice(gold)
        tradingHouse.invoiceSellPrice:SetHidden(false)
    elseif eventType == "cancel" then
        tradingHouse.invoiceSellPrice:SetHidden(false)
    end
end

function ZO_TradingHouseManager:BeginSetPendingPostPrice(anchorTo)
    if self:HasValidPendingItemPost() then
        self.invoiceSellPrice:SetHidden(true)
        CURRENCY_INPUT:SetContext(self)
        CURRENCY_INPUT:Show(SetPostPriceCallback, false, self:GetPendingPostPrice(), CURT_MONEY, anchorTo, 20)
    end
end

--[[ Globals ]]--
ZO_TRADING_HOUSE_SEARCH_RESULT_ITEM_ICON_MAX_WIDTH = 60 -- this is larger than the item icon to allow the icon to scale up
ZO_TRADING_HOUSE_SEARCH_RESULT_ITEM_NAME_WIDTH = 240
ZO_TRADING_HOUSE_SEARCH_RESULT_TRAIT_COLUMN_WIDTH = 42 -- this is larger than the trait icon to create a right margin
ZO_TRADING_HOUSE_SEARCH_RESULT_ITEM_NAME_WITHOUT_TRAIT_COLUMN_WIDTH = ZO_TRADING_HOUSE_SEARCH_RESULT_ITEM_NAME_WIDTH - ZO_TRADING_HOUSE_SEARCH_RESULT_TRAIT_COLUMN_WIDTH
ZO_TRADING_HOUSE_SEARCH_RESULT_TIME_LEFT_WIDTH = 60
ZO_TRADING_HOUSE_SEARCH_RESULT_UNIT_PRICE_WIDTH = 120
ZO_TRADING_HOUSE_SEARCH_RESULT_PRICE_WIDTH = 130

local function GetTradingHouseIndexForPreviewFromSlot(storeEntrySlot)
    local inventorySlot, listPart, multiIconPart = ZO_InventorySlot_GetInventorySlotComponents(storeEntrySlot)

    local slotType = ZO_InventorySlot_GetType(inventorySlot)
    if slotType == SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT then
        local tradingHouseIndex = ZO_Inventory_GetSlotIndex(inventorySlot)
        local itemLink = GetTradingHouseSearchResultItemLink(tradingHouseIndex)
        if ZO_ItemPreview_Shared.CanItemLinkBePreviewedAsFurniture(itemLink) then
            return tradingHouseIndex
        end
    end

    return nil
end

function ZO_TradingHouse_OnSearchResultClicked(searchResultSlot, button)
    -- left button for an inventory slot click will only try and drag and drop, but that
    -- should be handled for us by the OnReceiveDrag handler, so if we left click
    -- we'll do our custom behavior
    if button ~= MOUSE_BUTTON_INDEX_LEFT then
        ZO_InventorySlot_OnSlotClicked(searchResultSlot, button)
    else
        local tradingHouseIndex = GetTradingHouseIndexForPreviewFromSlot(searchResultSlot)
        if tradingHouseIndex ~= nil then
            TRADING_HOUSE:PreviewSearchResult(tradingHouseIndex)
        end
    end
end

function ZO_TradingHouse_OnSearchResultMouseEnter(searchResultSlot)
    ZO_InventorySlot_OnMouseEnter(searchResultSlot)

    local tradingHouseIndex = GetTradingHouseIndexForPreviewFromSlot(searchResultSlot)

    local cursor = MOUSE_CURSOR_DO_NOT_CARE
    if tradingHouseIndex ~= nil then
        cursor = MOUSE_CURSOR_PREVIEW
    end

    WINDOW_MANAGER:SetMouseCursor(cursor)
end

function ZO_TradingHouse_OnSearchResultMouseExit(searchResultSlot)
    ZO_InventorySlot_OnMouseExit(searchResultSlot)
    WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
end

function ZO_TradingHouse_SearchResult_TraitInfo_OnMouseEnter(control)
    local buttonPart, listPart, multiIconPart = ZO_InventorySlot_GetInventorySlotComponents(control:GetParent())
    ZO_InventorySlot_SetHighlightHidden(listPart, false)

    local slotData = control:GetParent().dataEntry.data
    if slotData.isGuildSpecificItem then
        return
    end

    local slotIndex = slotData.slotIndex
    local traitInformation = GetItemTraitInformationFromItemLink(slotData.itemLink)

    if traitInformation ~= ITEM_TRAIT_INFORMATION_NONE then
        local itemTrait = GetItemLinkTraitInfo(slotData.itemLink)
        local traitName = GetString("SI_ITEMTRAITTYPE", itemTrait)
        local traitInformationString = GetString("SI_ITEMTRAITINFORMATION", traitInformation)
        InitializeTooltip(InformationTooltip, control, TOPRIGHT, -10, 0, TOPLEFT)
        InformationTooltip:AddLine(zo_strformat(SI_INVENTORY_TRAIT_STATUS_TOOLTIP, traitName, ZO_SELECTED_TEXT:Colorize(traitInformationString)), "", ZO_NORMAL_TEXT:UnpackRGB())
    end
end

function ZO_TradingHouse_SearchResult_TraitInfo_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    local buttonPart, listPart, multiIconPart = ZO_InventorySlot_GetInventorySlotComponents(control:GetParent())
    ZO_InventorySlot_SetHighlightHidden(listPart, true)
end

function ZO_TradingHouse_OnInitialized(self)
    TRADING_HOUSE = ZO_TradingHouseManager:New(self)
    SYSTEMS:RegisterKeyboardObject(ZO_TRADING_HOUSE_SYSTEM_NAME, TRADING_HOUSE)
end
