local SCROLL_LIST_ITEM_TEMPLATE_NAME = "ZO_TradingHouse_ItemListRow_Gamepad"
local SCROLL_LIST_HEADER_OFFSET_VALUE = 0
local SCROLL_LIST_SELECTED_OFFSET_VALUE = 20

local HALF_ALPHA = 0.5
local FULL_ALPHA = 1
local FIRST_PAGE = 0
local NO_MORE_PAGES = false
local NO_ITEMS_ON_PAGE = 0

local SORT_OPTIONS = {
    [ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_TIME] = TRADING_HOUSE_SORT_EXPIRY_TIME,
    [ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_PRICE] = TRADING_HOUSE_SORT_SALE_PRICE,
}

local ZO_GamepadTradingHouse_BrowseResults = ZO_GamepadTradingHouse_SortableItemList:Subclass()

function ZO_GamepadTradingHouse_BrowseResults:New(...)
    local browseStore = ZO_GamepadTradingHouse_SortableItemList.New(self, ...)
    return browseStore
end

function ZO_GamepadTradingHouse_BrowseResults:Initialize(control)
    local DONT_USE_HIGHLIGHT = false
    ZO_GamepadTradingHouse_SortableItemList.Initialize(self, control, ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_PRICE, DONT_USE_HIGHLIGHT)
    self.guildItemsCachedForDisplay = {}
    self.cachedLastItemData = nil
    local footerControl = control:GetNamedChild("Footer")
    self.footer =
    {
        control = footerControl,
        previousButton = footerControl:GetNamedChild("PreviousButton"),
        nextButton = footerControl:GetNamedChild("NextButton"),
        pageNumberLabel = footerControl:GetNamedChild("PageNumberText"),
    }

    GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS_FRAGMENT = ZO_FadeSceneFragment:New(self.control)
    self:SetFragment(GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS_FRAGMENT)
end

local function SetupListing(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)

    local notEnoughMoney = data.purchasePrice > GetCarriedCurrencyAmount(CURT_MONEY)
    ZO_CurrencyControl_SetSimpleCurrency(control.price, CURT_MONEY, data.purchasePrice, ZO_GAMEPAD_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, notEnoughMoney)

    local sellerControl = control:GetNamedChild("SellerName")
    sellerControl:SetText(ZO_FormatUserFacingDisplayName(data.sellerName))

    local timeRemainingControl = control:GetNamedChild("TimeLeft")

    if data.isGuildSpecificItem then
        timeRemainingControl:SetHidden(true)
    else
        timeRemainingControl:SetHidden(false)
        timeRemainingControl:SetText(zo_strformat(SI_TRADING_HOUSE_BROWSE_ITEM_REMAINING_TIME, ZO_FormatTime(data.timeRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)))
    end
end

function ZO_GamepadTradingHouse_BrowseResults:InitializeList()
    ZO_GamepadTradingHouse_SortableItemList.InitializeList(self)
    local list = self:GetList()
    list:AddDataTemplate("ZO_TradingHouse_ItemListRow_Gamepad", SetupListing, ZO_GamepadMenuEntryTemplateParametricListFunction)
    local BROWSE_RESULTS_ITEM_HEIGHT = 65
    list:SetAlignToScreenCenter(true, BROWSE_RESULTS_ITEM_HEIGHT)
    list:SetNoItemText(GetString(SI_DISPLAY_GUILD_STORE_NO_ITEMS))

    list:SetOnSelectedDataChangedCallback(
        function(list, selectedData)
            self:LayoutTooltips(selectedData)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    )
end

function ZO_GamepadTradingHouse_BrowseResults:InitializeSortOptions()
    self.currentTimePriceKey = ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_PRICE
    self.toggleTimePriceKey = ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_TIME
    self:SetSortOptions(SORT_OPTIONS)
end

function ZO_GamepadTradingHouse_BrowseResults:NextPageRequest()
    if self.hasMorePages and self:HasNoCooldown() then
        TRADING_HOUSE_GAMEPAD:SearchNextPage()
    end
end

function ZO_GamepadTradingHouse_BrowseResults:PreviousPageRequest()
    if (self.currentPage > 0) and self:HasNoCooldown() then
        TRADING_HOUSE_GAMEPAD:SearchPreviousPage()
    end
end

function ZO_GamepadTradingHouse_BrowseResults:UpdateRightTooltip(selectedData)
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)

    local itemLink = selectedData and selectedData.itemLink
	if not itemLink then
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
		return
	end

	local equipType = GetItemLinkEquipType(itemLink)
	local equipSlot = ZO_InventoryUtils_GetEquipSlotForEquipType(equipType)

    if equipSlot and GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_RIGHT_TOOLTIP, BAG_WORN, equipSlot) then 
        ZO_InventoryUtils_UpdateTooltipEquippedIndicatorText(GAMEPAD_RIGHT_TOOLTIP, equipSlot)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_GamepadTradingHouse_BrowseResults:UpdateItemSelectedTooltip(selectedData)
    if selectedData then
        local itemLink = nil
        if selectedData.isGuildSpecificItem then
            itemLink = GetGuildSpecificItemLink(selectedData.slotIndex)
        else
            itemLink = selectedData.itemLink
        end
        
        GAMEPAD_TOOLTIPS:LayoutItemWithStackCountSimple(GAMEPAD_LEFT_TOOLTIP, itemLink, selectedData.stackCount)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    end
end

function ZO_GamepadTradingHouse_BrowseResults:LayoutTooltips(selectedData)
    self:UpdateItemSelectedTooltip(selectedData)
    self:UpdateRightTooltip(selectedData)
end

function ZO_GamepadTradingHouse_BrowseResults:AddGuildSpecificItemsToList(ignoreFiltering, cacheGuildItems)
    local numGuildSpecificItems = GetNumGuildSpecificItems()
    for i = 1, numGuildSpecificItems do
        local itemData = TRADING_HOUSE_GAMEPAD:CreateGuildSpecificItemData(i, GetGuildSpecificItemInfo)
        if(itemData and ignoreFiltering or TRADING_HOUSE_GAMEPAD:ShouldAddGuildSpecificItemToList(itemData)) then
            itemData.isGuildSpecificItem = true
            self:FormatItemDataFields(itemData)
            if cacheGuildItems then
                table.insert(self.guildItemsCachedForDisplay, itemData)
            else
                self:AddEntryToList(itemData)
            end
        end
    end
end

function ZO_GamepadTradingHouse_BrowseResults:AddGuildSpecificItems(ignoreFiltering)
    self:ResetPageData()
    self.numItemsOnPage = GetNumGuildSpecificItems()
    self:AddGuildSpecificItemsToList(ignoreFiltering)
    self:CommitList()
    -- Only allow a new search when the search criteria has changed, otherwise show previous results
    TRADING_HOUSE_GAMEPAD:SetSearchAllowed(false)
end

do
    local TIME_SORT_KEYS =
    {
        time = { tiebreaker = "name", isNumeric = true },
        name = { tieBreaker = "uniqueId" },
        uniqueId = { isId64 = true },
    }

    local PRICE_SORT_KEYS =
    {
        price = { tiebreaker = "name", isNumeric = true },
        name = { tieBreaker = "uniqueId" },
        uniqueId = { isId64 = true },
    }

    local IS_AFTER = false
    local IS_BEFORE = true

    function ZO_GamepadTradingHouse_BrowseResults:InsertCachedGuildSpecificItemsForSortPosition(itemA, itemB)
        local sortOptions = self.currentSortOption == TRADING_HOUSE_SORT_EXPIRY_TIME and TIME_SORT_KEYS or PRICE_SORT_KEYS
        for i = #self.guildItemsCachedForDisplay, 1, -1 do
            local guildItem = self.guildItemsCachedForDisplay[i]
            local beforeItemA
            local beforeItemB
            
            if not itemA then
                beforeItemA = IS_AFTER
            else
                beforeItemA = ZO_TableOrderingFunction(guildItem, itemA, self.sortKey, sortOptions, self.sortOrder)
            end

            if not itemB then
                beforeItemB = IS_BEFORE
            else
                beforeItemB = ZO_TableOrderingFunction(guildItem, itemB, self.sortKey, sortOptions, self.sortOrder)
            end

            if (not beforeItemA) and beforeItemB then
                table.remove(self.guildItemsCachedForDisplay, i)
                self:AddEntryToList(guildItem)
            end
        end
    end
end

function ZO_GamepadTradingHouse_BrowseResults:OnSearchResultsReceived(_, numItemsOnPage, currentPage, hasMorePages)
    self:UpdatePageData(numItemsOnPage, currentPage, hasMorePages)

    -- Only allow a new search when the search criteria has changed, otherwise show previous results
    TRADING_HOUSE_GAMEPAD:SetSearchAllowed(false)
    self:RefreshData()
end

function ZO_GamepadTradingHouse_BrowseResults:InitializeEvents()
    local function OnResponseReceived(responseType, result)
        if (responseType == TRADING_HOUSE_RESULT_PURCHASE_PENDING) and (result == TRADING_HOUSE_RESULT_SUCCESS) then
            local RESELECT = false
            self:RefreshData(RESELECT)
        end
    end

    self:SetEventCallback(EVENT_TRADING_HOUSE_RESPONSE_RECEIVED, OnResponseReceived)

    local function OnSearchResultsReceived(...)
        self:OnSearchResultsReceived(...)
    end

    self:SetEventCallback(EVENT_TRADING_HOUSE_SEARCH_RESULTS_RECEIVED, OnSearchResultsReceived)

    local function OnSearchCooldownUpdate(...)
        self:OnSearchCooldownUpdate(...)
    end

    self:SetEventCallback(EVENT_TRADING_HOUSE_SEARCH_COOLDOWN_UPDATE, OnSearchCooldownUpdate)
end

function ZO_GamepadTradingHouse_BrowseResults:AddEntryToList(itemData)
    if(itemData) then
        local entry = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
        entry:InitializeTradingHouseVisualData(itemData)

        self:GetList():AddEntry("ZO_TradingHouse_ItemListRow_Gamepad", 
                                entry, 
                                SCROLL_LIST_HEADER_OFFSET_VALUE, 
                                SCROLL_LIST_HEADER_OFFSET_VALUE, 
                                SCROLL_LIST_SELECTED_OFFSET_VALUE, 
                                SCROLL_LIST_SELECTED_OFFSET_VALUE)
    end
end

function ZO_GamepadTradingHouse_BrowseResults:FormatItemDataFields(itemData)
    --- convert to names expected by sort options
    itemData.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, itemData.name)
    itemData.price = itemData.purchasePrice
    itemData.time = itemData.timeRemaining
end

function ZO_GamepadTradingHouse_BrowseResults:BuildList()
    local numNonGuildItems = self.numItemsOnPage

    --[[
        According to design, we need to add in guild specific items if the category filter is ALL_ITEMS
        Guild specific items are different than items that are returned from a normal search query because they are not stored on the server and retrieved via the TradingHouseManager
        Instead guild specific items are created in lua when specifically requested. A problem arises because search queries are returned to the client page by page and pre-sorted.
        In order to insert the guild specific items in the correct sorted place, without knowing the full contents of the sorted list (it could be hundreds, even thousands, of items long),
        we have to check entries as they are added to the list using a sort comparator and specifically insert in these guild items where needed, on a page by page basis
    --]]
    local displayGuildItems = not TRADING_HOUSE_GAMEPAD:GetSearchActiveFilter() -- TRADING_HOUSE_GAMEPAD:GetSearchActiveFilter() returns nil when the category filter combo box is set to ALL_ITEMS
    if displayGuildItems then
        local DONT_IGNORE_FILTERING = false
        local CACHE_GUILD_ITEMS = true
        self:AddGuildSpecificItemsToList(DONT_IGNORE_FILTERING, CACHE_GUILD_ITEMS) -- cache guild specific items in a table that will be removed from during the add entry block below
    end

    for i = 1, numNonGuildItems do
        local itemData = ZO_TradingHouse_CreateItemData(i, GetTradingHouseSearchResultItemInfo)

        if itemData then
            itemData.itemLink = GetTradingHouseSearchResultItemLink(itemData.slotIndex)
            self:FormatItemDataFields(itemData)

            if displayGuildItems then
                -- Check the cached guild specific items to see if any items should be inserted between the current item and the last item added.
                self:InsertCachedGuildSpecificItemsForSortPosition(self.cachedLastItemData, itemData)
                self.cachedLastItemData = itemData
            end

            self:AddEntryToList(itemData)
        end
    end

    if displayGuildItems and not self.hasMorePages then
        self:InsertCachedGuildSpecificItemsForSortPosition(self.cachedLastItemData, nil) -- Check one last time to see if any guild specific items should be at the end of the list
    end
end

function ZO_GamepadTradingHouse_BrowseResults:ClearList()
    ZO_SortableParametricList.ClearList(self)
    ZO_ClearTable(self.guildItemsCachedForDisplay)
end

function ZO_GamepadTradingHouse_BrowseResults:ShowPurchaseItemConfirmation(selectedData)
    if selectedData then
        local dialogName = selectedData.isGuildSpecificItem and "TRADING_HOUSE_CONFIRM_BUY_GUILD_SPECIFIC_ITEM" or "TRADING_HOUSE_CONFIRM_BUY_ITEM"
        if not selectedData.isGuildSpecificItem then
            SetPendingItemPurchase(selectedData.slotIndex)
        end

        ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog(selectedData, dialogName, selectedData.purchasePrice)
    end
end

-- Overridden functions

function ZO_GamepadTradingHouse_BrowseResults:InitializeKeybindStripDescriptors()
    local function NotAwaitingResponse()
        return not self.awaitingResponse
    end

    local function HasNoCoolDownAndNotAwaitingResponse() 
        return self:HasNoCooldown() and NotAwaitingResponse()
    end

    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
         {
            name = GetString(SI_GAMEPAD_SORT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            callback = function()
                TRADING_HOUSE_GAMEPAD:SetSearchPageData(FIRST_PAGE, NO_MORE_PAGES) -- Reset pages for new sort option
                self:SortBySelected()
            end,
            enabled = HasNoCoolDownAndNotAwaitingResponse
        },

        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_SECONDARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            callback = function()
                local postedItem = self:GetList():GetTargetData()
                self:ShowPurchaseItemConfirmation(postedItem)
            end,
            enabled =   function()
                            if NotAwaitingResponse() then
                                local postedItem = self:GetList():GetTargetData()
                                if postedItem then
                                    local sellerName = postedItem.dataSource.sellerName
                                    return sellerName ~= GetDisplayName(), GetString("SI_TRADINGHOUSERESULT", TRADING_HOUSE_RESULT_CANT_BUY_YOUR_OWN_POSTS)
                                end
                            end
                            return false
                        end
        },

        {
            name = GetString(SI_TRADING_HOUSE_GUILD_LABEL),
            keybind = "UI_SHORTCUT_TERTIARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            callback = function()
                self:DisplayChangeGuildDialog()
            end,
            visible = function()
                return GetSelectedTradingHouseGuildId() ~= nil and GetNumTradingHouseGuilds() > 1
            end,
            enabled = HasNoCoolDownAndNotAwaitingResponse
        },

        {
            name = function()
                return zo_strformat(SI_GAMEPAD_TRADING_HOUSE_SORT_TIME_PRICE_TOGGLE, self:GetTextForToggleTimePriceKey())
            end,
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            callback = function()
                TRADING_HOUSE_GAMEPAD:SetSearchPageData(FIRST_PAGE, NO_MORE_PAGES) -- Reset pages for new sort option
                self:ToggleSortOptions()
            end,
            enabled = HasNoCoolDownAndNotAwaitingResponse
        },

        {
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            ethereal = true,
            callback = function()
                self:PreviousPageRequest()
            end,
        },

        {
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            ethereal = true,
            callback = function()
                self:NextPageRequest()
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:ShowBrowseFilters() end)
end

function ZO_GamepadTradingHouse_BrowseResults:UpdateForGuildChange()
    self:ClearList()
    self:AddGuildSpecificItems()
end

function ZO_GamepadTradingHouse_BrowseResults:DoSearch()
    self:ResetPageData()
    self.cachedLastItemData = nil
    self:ClearList()
    TRADING_HOUSE_GAMEPAD:DoSearch()
    self:SetFooterAlpha(HALF_ALPHA)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadTradingHouse_BrowseResults:RequestListUpdate()
    if TRADING_HOUSE_GAMEPAD:GetSearchAllowed() then
        self:DoSearch()
    else
        self:LayoutTooltips(self.itemList:GetTargetData())
    end
end

function ZO_GamepadTradingHouse_BrowseResults:GetFragmentGroup()
    return {GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS_FRAGMENT}
end

function ZO_GamepadTradingHouse_BrowseResults:ResetPageData()
    self:UpdatePageData(NO_ITEMS_ON_PAGE, FIRST_PAGE, NO_MORE_PAGES)
end

function ZO_GamepadTradingHouse_BrowseResults:UpdatePageData(numItemsOnPage, currentPage, hasMorePages)
    TRADING_HOUSE_GAMEPAD:SetSearchPageData(currentPage, hasMorePages)
    self.numItemsOnPage = numItemsOnPage
    self.currentPage = currentPage
    self.hasMorePages = hasMorePages
    local enablePrevious = self.currentPage ~= 0
    local enableNext = self.hasMorePages
    local hideButtons = (not enablePrevious) and (not enableNext)
    local showPageNumber = not hideButtons

    local prevButton = self.footer.previousButton
    local nextButton = self.footer.nextButton

    prevButton:SetEnabled(enablePrevious)
    nextButton:SetEnabled(enableNext)
    prevButton:SetHidden(hideButtons)
    nextButton:SetHidden(hideButtons)

    if showPageNumber then
        self.footer.pageNumberLabel:SetHidden(false)
        self.footer.pageNumberLabel:SetText(zo_strformat(SI_GAMEPAD_PAGED_LIST_PAGE_NUMBER, self.currentPage + 1)) -- Pages start at 0, offset by 1 for expected display number
    else
        self.footer.pageNumberLabel:SetHidden(true)
    end
end

function ZO_GamepadTradingHouse_BrowseResults:OnHiding()
    self:LayoutTooltips(nil)
end

function ZO_GamepadTradingHouse_BrowseResults:ShowBrowseFilters()
    GAMEPAD_TRADING_HOUSE_BROWSE_MANAGER:Toggle()
end

function ZO_GamepadTradingHouse_BrowseResults:OnInitialInteraction()
    self:ResetPageData()
    self:ClearList()
    self:SelectInitialSortOption()
end

function ZO_GamepadTradingHouse_BrowseResults:OnEndInteraction()
    self:ResetSortOptions()
end

function ZO_GamepadTradingHouse_BrowseResults:SetFooterAlpha(alpha)
    self.footer.nextButton:SetAlpha(alpha)
    self.footer.previousButton:SetAlpha(alpha)
end

function ZO_GamepadTradingHouse_BrowseResults:DeactivateForResponse()
    ZO_GamepadTradingHouse_BaseList.DeactivateForResponse(self)
    self:SetFooterAlpha(HALF_ALPHA)
end

function ZO_GamepadTradingHouse_BrowseResults:OnSearchCooldownUpdate(cooldownMilliseconds)
    if cooldownMilliseconds == 0 then
        self:SetFooterAlpha(FULL_ALPHA)
    else
        self:SetFooterAlpha(HALF_ALPHA)
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadTradingHouse_BrowseResults:UpdateListSortFunction()
    if self.currentSortOption then
        TRADING_HOUSE_GAMEPAD:UpdateSortOption(self.sortOptions[self.sortKey], self.sortOrder)    
    end
end

function ZO_GamepadTradingHouse_BrowseResults:RefreshSort()
    self:UpdateSortOption()

    if not self.control:IsHidden() then
        self:DoSearch()
    end
end

-- Global functions

function ZO_TradingHouse_BrowseResults_Gamepad_OnInitialize(control)
    GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS = ZO_GamepadTradingHouse_BrowseResults:New(control)
end