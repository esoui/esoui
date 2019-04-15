ZO_GAMEPAD_TRADING_HOUSE_SEARCH_RESULTS_ICON_SIZE = ZO_GAMEPAD_LIST_ICON_SIZE
ZO_GAMEPAD_TRADING_HOUSE_SEARCH_RESULTS_NAME_WIDTH = 290
ZO_GAMEPAD_TRADING_HOUSE_SEARCH_RESULTS_TIME_LEFT_WIDTH = 66
ZO_GAMEPAD_TRADING_HOUSE_SEARCH_RESULTS_UNIT_PRICE_WIDTH = 122
ZO_GAMEPAD_TRADING_HOUSE_SEARCH_RESULTS_PRICE_WIDTH = 122

ZO_GAMEPAD_TRADING_HOUSE_SEARCH_RESULTS_HEADER_INITIAL_OFFSET = ZO_GAMEPAD_TRADING_HOUSE_SEARCH_RESULTS_ICON_SIZE + (ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X * 2)

local ZO_GamepadTradingHouse_BrowseResults = ZO_GamepadInteractiveSortFilterList:Subclass()

function ZO_GamepadTradingHouse_BrowseResults:New(...)
    return ZO_GamepadInteractiveSortFilterList.New(self, ...)
end

function ZO_GamepadTradingHouse_BrowseResults:Initialize(control)
    ZO_GamepadInteractiveSortFilterList.Initialize(self, control)
    ZO_GamepadTradingHouse_BaseList.Initialize(self)
    self.searchResultItemDataList = {}
    self:InitializePreview()

    self:SetTitle(GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS_TITLE))
    ZO_ScrollList_AddDataType(self.list, ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_PRIMARY_DATA_TYPE, "ZO_TradingHouse_BrowseResultsRow_Gamepad", ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_TWO_LINE_ROW_HEIGHT, function(rowControl, rowData)
        self:SetupResultItemRow(rowControl, rowData)
    end)

    local footerControl = control:GetNamedChild("Footer")
    self.footer =
    {
        control = footerControl,
        previousButton = footerControl:GetNamedChild("PreviousButton"),
        nextButton = footerControl:GetNamedChild("NextButton"),
        pageNumberLabel = footerControl:GetNamedChild("PageNumberText"),
    }

    -- No master list, because we don't use client-side filters. we just apply the data directly to the scroll list
    -- Since ZO_GamepadInteractiveSortFilterList does expect a master list to exist though, we will at least pass in an empty table.
    self:SetMasterList({})

    -- Defining a set of sort keys causes the ZO_GamepadInteractiveSortFilterList to locally sort, which we don't need: the server sends us the data pre-sorted.
    local NO_SORT_KEYS = nil
    self:SetupSort(NO_SORT_KEYS, TRADING_HOUSE_SEARCH:GetSortOptions())

    self:RemoveFilters()
    self:RefreshPagingControls()
end

local PRICE_THRESHOLD_DIGITS = 6
local PRICE_THRESHOLD = zo_pow(10, PRICE_THRESHOLD_DIGITS)

ZO_GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS_CURRENCY_OPTIONS =
{
    showTooltips = false,
    iconSide = RIGHT,
    isGamepad = true,
    useShortFormat = false,
}
ZO_GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS_ABBREVIATED_CURRENCY_OPTIONS =
{
    showTooltips = false,
    iconSide = RIGHT,
    isGamepad = true,
    useShortFormat = true,
}
function ZO_GamepadTradingHouse_BrowseResults:SetupResultItemRow(control, itemData)
    -- icon/stack count
    control.slotIcon:SetTexture(itemData.icon)
    if itemData.stackCount and itemData.stackCount > 1 then
        control.slotStackCount:SetText(zo_strformat(SI_NUMBER_FORMAT, ZO_AbbreviateNumber(itemData.stackCount, NUMBER_ABBREVIATION_PRECISION_TENTHS, USE_LOWERCASE_NUMBER_SUFFIXES)))
        control.slotStackCount:SetHidden(false)
    else
        control.slotStackCount:SetHidden(true)
    end

    -- name
    control.nameLabel:SetText(ZO_TradingHouse_GetItemDataFormattedName(itemData))
    control.nameLabel:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, itemData.quality))

    -- time
    if not itemData.isGuildSpecificItem then
        local timeRemainingString = ZO_TradingHouse_GetItemDataFormattedTime(itemData)
        control.timeLeftLabel:SetHidden(false)
        control.timeLeftLabel:SetText(timeRemainingString)
    else
        control.timeLeftLabel:SetHidden(true)
    end

    -- unit price
    local currencyOptions = ZO_CountDigitsInNumber(itemData.purchasePricePerUnit) <= PRICE_THRESHOLD_DIGITS and ZO_GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS_CURRENCY_OPTIONS or ZO_GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS_ABBREVIATED_CURRENCY_OPTIONS
    ZO_CurrencyControl_SetSimpleCurrency(control.unitPriceLabel, CURT_MONEY, itemData.purchasePricePerUnit, currencyOptions, CURRENCY_SHOW_ALL)

    -- total price
    local notEnoughMoney = itemData.purchasePrice > GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
    local currencyOptions = itemData.purchasePrice < PRICE_THRESHOLD and ZO_GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS_CURRENCY_OPTIONS or ZO_GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS_ABBREVIATED_CURRENCY_OPTIONS
    ZO_CurrencyControl_SetSimpleCurrency(control.priceLabel, CURT_MONEY, itemData.purchasePrice, currencyOptions, CURRENCY_SHOW_ALL, notEnoughMoney)
end

function ZO_GamepadTradingHouse_BrowseResults:OnSelectionChanged(oldItemData, newItemData)
    self:UpdateItemSelectedTooltip(newItemData)
end

function ZO_GamepadTradingHouse_BrowseResults:UpdateItemSelectedTooltip(selectedData)
    if selectedData then
        local itemLink
        if selectedData.isGuildSpecificItem then
            itemLink = GetGuildSpecificItemLink(selectedData.slotIndex)
        else
            itemLink = selectedData.itemLink
        end

        GAMEPAD_TOOLTIPS:LayoutGuildStoreSearchResult(GAMEPAD_RIGHT_TOOLTIP, itemLink, selectedData.stackCount, selectedData.sellerName)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end


function ZO_GamepadTradingHouse_BrowseResults:InitializeEvents()
    local function FilterForGamepadEvents(callback)
        return function(...)
            if IsInGamepadPreferredMode() then
                callback(...)
            end
        end
    end

    TRADING_HOUSE_SEARCH:RegisterCallback("OnSearchStateChanged", FilterForGamepadEvents(function(...) self:OnSearchStateChanged(...) end))
    TRADING_HOUSE_SEARCH:RegisterCallback("OnResponseReceived", FilterForGamepadEvents(function(...) self:OnResponseReceived(...) end))

    local function OnSceneGroupStateChanged(oldState, newState)
        if newState == SCENE_GROUP_SHOWING then
            self:RefreshData()
        elseif newState == SCENE_GROUP_HIDING then
            self.previewItemData = nil
        end
    end
    TRADING_HOUSE_GAMEPAD_SCENE:GetSceneGroup():RegisterCallback("StateChange", OnSceneGroupStateChanged)
end

function ZO_GamepadTradingHouse_BrowseResults:ShowPurchaseItemConfirmation(selectedData)
    if selectedData then
        local dialogName = selectedData.isGuildSpecificItem and "TRADING_HOUSE_CONFIRM_BUY_GUILD_SPECIFIC_ITEM" or "TRADING_HOUSE_CONFIRM_BUY_ITEM"
        if not selectedData.isGuildSpecificItem then
            SetPendingItemPurchase(selectedData.slotIndex)
        end

        ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog(selectedData, dialogName, selectedData.purchasePrice, selectedData.icon)
    end
end

function ZO_GamepadTradingHouse_BrowseResults:OnSearchStateChanged(searchState, searchOutcome)
    local shouldActivateBrowseResults = false
    local shouldDeactivateBrowseResults = false
    if searchState == TRADING_HOUSE_SEARCH_STATE_NONE then
        self:SetEmptyText("")
    elseif searchState == TRADING_HOUSE_SEARCH_STATE_WAITING then
        self:SetEmptyText(GetString("SI_TRADINGHOUSESEARCHSTATE", searchState))
    elseif searchState == TRADING_HOUSE_SEARCH_STATE_COMPLETE then
        if searchOutcome == TRADING_HOUSE_SEARCH_OUTCOME_HAS_RESULTS then
            self:DeselectListData()

            shouldActivateBrowseResults = true
        else
            self:SetEmptyText(GetString("SI_TRADINGHOUSESEARCHOUTCOME", searchOutcome))

            shouldDeactivateBrowseResults = (searchOutcome == TRADING_HOUSE_SEARCH_OUTCOME_ALL_RESULTS_PURCHASED)
        end
    end

    self:RefreshData()

    if TRADING_HOUSE_GAMEPAD_SCENE:IsShowing() then
        if shouldActivateBrowseResults then
            if self:IsActive() then
                -- We are already activated, focus on the panel so we start on the first item entry
                self:ActivatePanelFocus()
            else
                TRADING_HOUSE_GAMEPAD:ActivateBrowseResults()
            end
        end

        if shouldDeactivateBrowseResults then
            if self:IsActive() then
                TRADING_HOUSE_GAMEPAD:DeactivateBrowseResults()
            end
        end
    end
end

function ZO_GamepadTradingHouse_BrowseResults:OnResponseReceived(responseType, responseResult)
    if responseType == TRADING_HOUSE_RESULT_PURCHASE_PENDING and responseResult == TRADING_HOUSE_RESULT_SUCCESS then
        -- Item purchased, remove it from the list
        self:RefreshData()
    end
end

function ZO_GamepadTradingHouse_BrowseResults:RefreshPagingControls()
    local enablePrevious = self:IsPanelFocused() and TRADING_HOUSE_SEARCH:HasPreviousPage()
    local enableNext = self:IsPanelFocused() and TRADING_HOUSE_SEARCH:HasNextPage()
    local hideButtons = not (TRADING_HOUSE_SEARCH:HasPreviousPage() or TRADING_HOUSE_SEARCH:HasNextPage())
    local showPageNumber = not hideButtons

    local prevButton = self.footer.previousButton
    local nextButton = self.footer.nextButton

    prevButton:SetEnabled(enablePrevious)
    nextButton:SetEnabled(enableNext)
    prevButton:SetHidden(hideButtons)
    nextButton:SetHidden(hideButtons)

    if showPageNumber then
        self.footer.pageNumberLabel:SetHidden(false)
        self.footer.pageNumberLabel:SetText(zo_strformat(SI_GAMEPAD_PAGED_LIST_PAGE_NUMBER, TRADING_HOUSE_SEARCH:GetPage() + 1)) -- Pages start at 0, offset by 1 for expected display number
    else
        self.footer.pageNumberLabel:SetHidden(true)
    end
end

function ZO_GamepadTradingHouse_BrowseResults:AddFragmentsToSubscene(subscene)
    subscene:AddFragment(self:GetListFragment())
    subscene:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
end

-- Overridden functions: derived from ZO_GamepadInteractiveSortFilterList

function ZO_GamepadTradingHouse_BrowseResults:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    -- Search results can be non-contiguous: bought items keep their index but get removed from the scroll list
    ZO_ClearTable(self.searchResultItemDataList)
    ZO_ClearNumericallyIndexedTable(scrollData)
    ZO_ClearNumericallyIndexedTable(self.previewListEntries)

    if TRADING_HOUSE_SEARCH:ShouldShowGuildSpecificItems() then
        for i = 1, GetNumGuildSpecificItems() do
            local itemData = TRADING_HOUSE_GAMEPAD:CreateGuildSpecificItemData(i, GetGuildSpecificItemInfo)
            if itemData then
                itemData.isGuildSpecificItem = true
                local dataEntry = ZO_ScrollList_CreateDataEntry(ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_PRIMARY_DATA_TYPE, itemData)
                table.insert(scrollData, dataEntry)
            end
        end
    else
        for tradingHouseItemIndex = 1, TRADING_HOUSE_SEARCH:GetNumItemsOnPage() do
            local itemData = ZO_TradingHouse_CreateSearchResultItemData(tradingHouseItemIndex)

            if itemData then
                local dataEntry = ZO_ScrollList_CreateDataEntry(ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_PRIMARY_DATA_TYPE, itemData)
                self.searchResultItemDataList[tradingHouseItemIndex] = itemData
                table.insert(scrollData, dataEntry)
                if self:CanPreviewTradingHouseItem(itemData) then
                    table.insert(self.previewListEntries, tradingHouseItemIndex)
                end
            end
        end
    end

    if TRADING_HOUSE_PREVIEW_GAMEPAD_SCENE:IsShowing() then
        self:UpdatePreviewForChangedData()
    end
end

function ZO_GamepadTradingHouse_BrowseResults:InitializeKeybinds()
    local function GetPreviewSelectedData()
        return self:GetItemDataBeingPreviewed()
    end

    local function GetResultsSelectedData()
        return self:GetSelectedData()
    end

    local function CreatePurchaseItemKeybindDescriptor(getItemDataCallback)
        return
        {
            name = function()
                local postedItem = getItemDataCallback()
                local purchasePriceText = ZO_Currency_FormatGamepad(CURT_MONEY, postedItem.purchasePrice, ZO_CURRENCY_FORMAT_AMOUNT_ICON)
                return zo_strformat(SI_GAMEPAD_TRADING_HOUSE_BUY_ITEM, purchasePriceText)
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            callback = function()
                local postedItem = getItemDataCallback()
                self:ShowPurchaseItemConfirmation(postedItem)
            end,
            enabled = function()
                local postedItem = getItemDataCallback()
                if postedItem == nil then
                    return false
                end

                if postedItem.sellerName == GetDisplayName() then
                    return false, GetString("SI_TRADINGHOUSERESULT", TRADING_HOUSE_RESULT_CANT_BUY_YOUR_OWN_POSTS)
                end

                if postedItem.purchasePrice > GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) then
                    return false, GetString("SI_TRADINGHOUSERESULT", TRADING_HOUSE_RESULT_CANT_AFFORD_BUYPRICE)
                end

                return true
            end,
        }
    end

    self.previewKeybindStripDescriptor =
    {
        CreatePurchaseItemKeybindDescriptor(GetPreviewSelectedData),
    }
    local function LeavePreviewScene()
        self.navigateToItemData = self.previewItemData
        SCENE_MANAGER:HideCurrentScene()
    end
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.previewKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, LeavePreviewScene)

    self.keybindStripDescriptor = {
        CreatePurchaseItemKeybindDescriptor(GetResultsSelectedData),
        {
            name = GetString(SI_CRAFTING_ENTER_PREVIEW_MODE),
            keybind = "UI_SHORTCUT_SECONDARY",
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            callback = function()
                local selectedData = self:GetSelectedData()
                self.previewItemData = selectedData
                SCENE_MANAGER:Push("tradingHousePreview_Gamepad")
            end,
            visible = function()
                local selectedData = self:GetSelectedData()
                return selectedData and self:CanPreviewTradingHouseItem(selectedData)
            end,
        },
        {
            name = GetString(SI_TRADING_HOUSE_SEARCH_FROM_ITEM),
            alignment = KEYBIND_STRIP_ALIGN_LEFT,

            keybind = "UI_SHORTCUT_QUATERNARY",

            visible = function()
                return self:GetSelectedData() ~= nil
            end,

            callback = function()
                local selectedItem = self:GetSelectedData()
                TRADING_HOUSE_GAMEPAD:SearchForItemLink(selectedItem.itemLink)
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, self:GetBackKeybindCallback())

    ZO_GamepadInteractiveSortFilterList.InitializeKeybinds(self)
end

do
    local function LeaveBrowseResults()
        TRADING_HOUSE_SEARCH:CancelPendingSearch()
        TRADING_HOUSE_GAMEPAD:LeaveBrowseResults()
    end
    function ZO_GamepadTradingHouse_BrowseResults:GetBackKeybindCallback()
        return LeaveBrowseResults
    end
end

function ZO_GamepadTradingHouse_BrowseResults:OnLeftTrigger()
    TRADING_HOUSE_SEARCH:SearchPreviousPage()
end

function ZO_GamepadTradingHouse_BrowseResults:OnRightTrigger()
    TRADING_HOUSE_SEARCH:SearchNextPage()
end

-- Overrides ZO_SortFilterList
function ZO_GamepadTradingHouse_BrowseResults:RefreshSort()
    if not self.control:IsHidden() then
        TRADING_HOUSE_SEARCH:ChangeSort(self.currentSortKey, self.currentSortOrder)
    end
end

function ZO_GamepadTradingHouse_BrowseResults:OnShowing()
    if self.navigateToItemData then
        local tradingHouseIndex = ZO_Inventory_GetSlotIndex(self.navigateToItemData)
        -- Check to see that this item data is still around, if not, we fallback to the existing selected entry
        if self.searchResultItemDataList[tradingHouseIndex] ~= nil then
            local NO_CALLBACK = nil
            local ANIMATE_INSTANTLY = true
            ZO_ScrollList_SelectDataAndScrollIntoView(self.list, self.navigateToItemData, NO_CALLBACK, ANIMATE_INSTANTLY)
        end

        TRADING_HOUSE_GAMEPAD:ActivateBrowseResults()

        self.navigateToItemData = nil
    end
end

function ZO_GamepadTradingHouse_BrowseResults:OnHiding()
    self:UpdateItemSelectedTooltip(nil)
    self:Deactivate()
end

-- Overrides ZO_GamepadMultiFocusArea_Manager
function ZO_GamepadTradingHouse_BrowseResults:OnFocusChanged()
    self:RefreshPagingControls()
end

---------------------------
-- Preview Scene Functions
---------------------------

function ZO_GamepadTradingHouse_BrowseResults:InitializePreview()
    self.previewItemData = nil
    self.previewListEntries = {}

    local function UpdatePreviewItemData(tradingHouseIndex)
        local itemData = self.searchResultItemDataList[tradingHouseIndex]
        if itemData then 
            self.previewItemData = itemData
            self:UpdateItemSelectedTooltip(self.previewItemData)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.previewKeybindStripDescriptor)
        end
    end

    TRADING_HOUSE_PREVIEW_GAMEPAD_SCENE = ZO_InteractScene:New("tradingHousePreview_Gamepad", SCENE_MANAGER, ZO_TRADING_HOUSE_INTERACTION)
    TRADING_HOUSE_PREVIEW_GAMEPAD_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            ITEM_PREVIEW_LIST_HELPER_GAMEPAD:RegisterCallback("OnPreviewChanged", UpdatePreviewItemData)
            ITEM_PREVIEW_GAMEPAD:SetInteractionCameraPreviewEnabled(true, FRAME_TARGET_CENTERED_FRAGMENT, FRAME_PLAYER_ON_SCENE_HIDDEN_FRAGMENT, GAMEPAD_NAV_QUADRANT_2_3_FURNITURE_ITEM_PREVIEW_OPTIONS_FRAGMENT)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.previewKeybindStripDescriptor)
        elseif newState == SCENE_SHOWN then
            local tradingHouseIndex = ZO_Inventory_GetSlotIndex(self.previewItemData)
            local previewIndex = ZO_IndexOfElementInNumericallyIndexedTable(self.previewListEntries, tradingHouseIndex)
            local DONT_WRAP = true
            ITEM_PREVIEW_LIST_HELPER_GAMEPAD:PreviewList(ZO_ITEM_PREVIEW_TRADING_HOUSE_SEARCH_RESULT_AS_FURNITURE, self.previewListEntries, previewIndex, DONT_WRAP)
        elseif newState == SCENE_HIDDEN then
            self.previewItemData = nil
            ITEM_PREVIEW_GAMEPAD:SetInteractionCameraPreviewEnabled(false, FRAME_TARGET_CENTERED_FRAGMENT, FRAME_PLAYER_ON_SCENE_HIDDEN_FRAGMENT, GAMEPAD_NAV_QUADRANT_2_3_FURNITURE_ITEM_PREVIEW_OPTIONS_FRAGMENT)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.previewKeybindStripDescriptor)
            ITEM_PREVIEW_LIST_HELPER_GAMEPAD:UnregisterCallback("OnPreviewChanged", UpdatePreviewItemData)
        end
    end)

    TRADING_HOUSE_GAMEPAD_SCENE:GetSceneGroup():AddScene("tradingHousePreview_Gamepad")
end

function ZO_GamepadTradingHouse_BrowseResults:UpdatePreviewForChangedData()
    if #self.previewListEntries == 0 then
        -- There are no entries left to preview, return to browse results
        SCENE_MANAGER:Hide("tradingHousePreview_Gamepad")
    else
        ITEM_PREVIEW_LIST_HELPER_GAMEPAD:UpdatePreviewList(self.previewListEntries)
    end
end

function ZO_GamepadTradingHouse_BrowseResults:CanPreviewTradingHouseItem(data)
    if data and not data.isGuildSpecificItem then
        return ZO_ItemPreview_Shared.CanItemLinkBePreviewedAsFurniture(data.itemLink)
    end

    return false
end

function ZO_GamepadTradingHouse_BrowseResults:GetItemDataBeingPreviewed()
    return self.previewItemData
end

-- Global functions

function ZO_TradingHouse_BrowseResults_Gamepad_OnInitialize(control)
    GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS = ZO_GamepadTradingHouse_BrowseResults:New(control)
end