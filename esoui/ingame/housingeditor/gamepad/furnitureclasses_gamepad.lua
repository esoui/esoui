--
--[[ ZO_HousingFurnitureList_Gamepad ]]--
--

local RIGHT_INFO_STATE =
{
    NONE = 0,
    HOUSE_INFO = 1,
    FURNITURE_INFO = 2,
}

ZO_HousingFurnitureList_Gamepad = ZO_Object:Subclass()

function ZO_HousingFurnitureList_Gamepad:New(...)
    local furnitureList = ZO_Object.New(self)
    furnitureList:Initialize(...)
    return furnitureList
end

function ZO_HousingFurnitureList_Gamepad:Initialize(owner)
    self.owner = owner

    self:InitializeKeybindStripDescriptors()

    self.categoryList =
    {
        list = owner:RequestNewList(),
        keybinds = self.categoryKeybindStripDescriptor,
        buildListFunction = function() return self:BuildCategoryList() end,
        -- The title text will be updated to the name of current tab
    }

    local furnitureList = owner:RequestNewList()
    self.furnitureList =
    {
        list = furnitureList,
        keybinds = self.furnitureKeybindStripDescriptor,
        buildListFunction = function()
                                self:RefreshCurrentCategoryData()
                                self:UpdateFurnitureListSavedPosition()
                                return self:BuildFurnitureList()
                            end,
        -- The title text will be updated to the name of the furniture category/subcategory
    }
    self.savedCategoryListPositions = {}

    furnitureList:SetOnTargetDataChangedCallback(function(...) self:OnFurnitureTargetChanged(...) end)

    local function FurnitureEntryDataSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

        local statusIndicator = control.statusIndicator
        if statusIndicator then
            if data.isFromCrownStore and not data.furnitureObject.marketProductId then
                statusIndicator:AddIcon(ZO_Currency_GetPlatformCurrencyIcon(UI_ONLY_CURRENCY_CROWNS))
            end

            statusIndicator:Show()
        end
    end

    local PRICE_LABEL_PADDING_X = 5

    local function MarketProductEntryDataSetup(control, data, selected, ...)
        FurnitureEntryDataSetup(control, data, selected, ...)

        local furnitureObject = data.furnitureObject

        ZO_CurrencyControl_SetSimpleCurrency(control.priceLabel, ZO_Currency_MarketCurrencyToUICurrency(furnitureObject.currencyType), furnitureObject.costAfterDiscount, ZO_GAMEPAD_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL)
        
        local priceWidth = control.priceLabel:GetTextWidth() 
        control.label:SetDimensions(ZO_GAMEPAD_DEFAULT_LIST_ENTRY_WIDTH_AFTER_INDENT - PRICE_LABEL_PADDING_X - priceWidth)

        if furnitureObject.onSale then
           control.previousPriceLabel:SetText(furnitureObject.cost)
        end
        control.previousPriceLabel:SetHidden(not furnitureObject.onSale)

        local subLabelBackgroundColor
        local subLabelTextColor
        local sublabelUpdateHandler

        if furnitureObject:IsLimitedTimeProduct() then
            subLabelBackgroundColor = ZO_BLACK
            subLabelTextColor = selected and ZO_MARKET_PRODUCT_ON_SALE_COLOR or ZO_MARKET_PRODUCT_ON_SALE_DIMMED_COLOR
            furnitureObject:SetTimeLeftOnLabel(control.subLabel1)
            sublabelUpdateHandler = function() furnitureObject:SetTimeLeftOnLabel(control.subLabel1) end
        elseif furnitureObject.onSale then
            subLabelBackgroundColor = selected and ZO_MARKET_PRODUCT_ON_SALE_COLOR or ZO_MARKET_PRODUCT_ON_SALE_DIMMED_COLOR
            subLabelTextColor = selected and ZO_MARKET_PRODUCT_BACKGROUND_BRIGHTNESS_COLOR or ZO_MARKET_DIMMED_COLOR
            control.subLabel1:SetText(zo_strformat(SI_MARKET_DISCOUNT_PRICE_PERCENT_FORMAT, furnitureObject.discountPercent))
            control.subLabel1:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        elseif furnitureObject.isNew then
            subLabelBackgroundColor = selected and ZO_MARKET_PRODUCT_NEW_COLOR or ZO_MARKET_PRODUCT_NEW_DIMMED_COLOR
            subLabelTextColor = selected and ZO_MARKET_PRODUCT_BACKGROUND_BRIGHTNESS_COLOR or ZO_MARKET_DIMMED_COLOR
            control.subLabel1:SetText(GetString(SI_MARKET_TILE_CALLOUT_NEW))
            control.subLabel1:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        end

        if subLabelBackgroundColor then
            furnitureObject.SetCalloutBackgroundColor(control.subLabel1LeftBackground, control.subLabel1RightBackground, control.subLabel1CenterBackground, subLabelBackgroundColor)

            control.subLabel1:SetColor(subLabelTextColor:UnpackRGB())

            control.numSubLabels = 1
        else
            control.numSubLabels = 0
        end

        control.subLabel1:SetHidden(not subLabelBackgroundColor)
        control.subLabel1:SetHandler("OnUpdate", sublabelUpdateHandler)
    end

    local DEFAULT_EQUALITY_FUNCTION = nil
    furnitureList:AddDataTemplate("ZO_GamepadHousingItemEntryTemplate", FurnitureEntryDataSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, DEFAULT_EQUALITY_FUNCTION, "ItemEntry")
    furnitureList:AddDataTemplateWithHeader("ZO_GamepadHousingItemEntryTemplate", FurnitureEntryDataSetup,  ZO_GamepadMenuEntryTemplateParametricListFunction, DEFAULT_EQUALITY_FUNCTION, "ZO_GamepadMenuEntryHeaderTemplate", nil, "ItemEntry")
    furnitureList:AddDataTemplate("ZO_GamepadHousingMPEntryTemplate", MarketProductEntryDataSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, DEFAULT_EQUALITY_FUNCTION, "MPEntry")
    furnitureList:AddDataTemplateWithHeader("ZO_GamepadHousingMPEntryTemplate", MarketProductEntryDataSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, DEFAULT_EQUALITY_FUNCTION, "ZO_GamepadMenuEntryHeaderTemplate", nil, "MPEntry")

    self.CompareFurnitureEntriesFunction = function(a, b)
        return self:CompareFurnitureEntries(a, b)
    end
end

function ZO_HousingFurnitureList_Gamepad:InitializeKeybindStripDescriptors()
    --Category List Keybinds

    self.categoryKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select Category
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:ViewCategory()
            end,
            visible = function()
                if self.currentList then
                    local entryData = self.currentList.list:GetTargetData()
                    return entryData ~= nil
                end
                return false
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Search
        {
            name = GetString(SI_GAMEPAD_FURNITURE_TEXT_FILTER_KEYBIND_TEXT),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                self.owner:SelectTextFilter()
            end,
        },
    }

    local function BackFunction()
        self:CategoryKeybindBackCallback()
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.categoryKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, BackFunction)

    --Furniture List Keybinds

    local function ToggleFurnitureRightInfoState()
        if self.rightInfoState == RIGHT_INFO_STATE.HOUSE_INFO then
            self:SetFurnitureRightInfoState(RIGHT_INFO_STATE.FURNITURE_INFO)
        else
            self:SetFurnitureRightInfoState(RIGHT_INFO_STATE.HOUSE_INFO)
        end
    end

    local function ToggleViewKeybindEnabled()
        return self.furnitureList.list:GetTargetData() ~= nil
    end

    self.furnitureKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Search
        {
            name = GetString(SI_GAMEPAD_FURNITURE_TEXT_FILTER_KEYBIND_TEXT),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                self:SwitchActiveList(self.categoryList)
                self.owner:SelectTextFilter()
            end,
        },

        -- Toggle view
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_GAMEPAD_HOUSING_FURNITURE_BROWSER_TOGGLE_INFO),
            keybind = "UI_SHORTCUT_INPUT_RIGHT",
            callback = ToggleFurnitureRightInfoState,
            visible = ToggleViewKeybindEnabled,
        },

        {
            ethereal = true,
            keybind = "UI_SHORTCUT_INPUT_LEFT",
            callback = ToggleFurnitureRightInfoState,
            enabled = ToggleViewKeybindEnabled,
        },
    }

    local function OnFurnitureListBack()
        self:FurnitureKeybindBackCallback()
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.furnitureKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnFurnitureListBack)
end

function ZO_HousingFurnitureList_Gamepad:AddFurnitureListKeybind(keybindDescriptor)
    table.insert(self.furnitureKeybindStripDescriptor, keybindDescriptor)
end

function ZO_HousingFurnitureList_Gamepad:CategoryKeybindBackCallback()
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_HousingFurnitureList_Gamepad:FurnitureKeybindBackCallback()
    self:SwitchActiveList(self.categoryList)
end

function ZO_HousingFurnitureList_Gamepad:OnShowing()
    self:UpdateLists()
    self:SwitchActiveList(self.categoryList)
end

function ZO_HousingFurnitureList_Gamepad:OnHiding()
    self:HideCurrentList()
    self:SetFurnitureRightInfoState(RIGHT_INFO_STATE.NONE)
end

function ZO_HousingFurnitureList_Gamepad:UpdateLists()
    if self.currentList then
        local success = self.currentList.buildListFunction()
        --if the list was empty with the new data then switch back to the top level category list
        if not success then
            self:BuildCategoryList()
            self:SwitchActiveList(self.categoryList)
        end
    else
        self:BuildCategoryList()
    end

    self:UpdateCurrentKeybinds()
end

function ZO_HousingFurnitureList_Gamepad:ViewCategory()
    self:RefreshCurrentCategoryData()
    self:BuildFurnitureList()
    self:SwitchActiveList(self.furnitureList)
end

function ZO_HousingFurnitureList_Gamepad:RefreshCurrentCategoryData()
    local entryData = self.categoryList.list:GetTargetData()
    local categoryTreeData = self:GetCategoryTreeDataRoot()
    self.currentCategoryData = categoryTreeData:GetSubcategory(entryData.categoryId)
end

function ZO_HousingFurnitureList_Gamepad:UpdateFurnitureListSavedPosition()
    if not self.currentCategoryData then
        return
    end

    local currentCategoryId = self.currentCategoryData:GetCategoryId()
    local currentSelectedIndex = self.furnitureList.list:GetSelectedIndex()
    local currentSelectedData = self.furnitureList.list:GetSelectedData()
    local categoryId, subcategoryId = currentSelectedData.furnitureObject:GetCategoryInfo()

    local savedListPositionData = self.savedCategoryListPositions[currentCategoryId]
    if not savedListPositionData then
        savedListPositionData = {}
        self.savedCategoryListPositions[currentCategoryId] = savedListPositionData
    end
    savedListPositionData.position = currentSelectedIndex
    savedListPositionData.categoryId = categoryId
    savedListPositionData.subcategoryId = subcategoryId
end

function ZO_HousingFurnitureList_Gamepad:ResetSavedPositions()
    ZO_ClearTable(self.savedCategoryListPositions)
end

function ZO_HousingFurnitureList_Gamepad:SwitchActiveList(list)
    if self.currentList == list then
        return
    end

    local previousList = self.currentList
    self.currentList = list

    if previousList then
        if previousList == self.furnitureList then
            self:UpdateFurnitureListSavedPosition()
            ITEM_PREVIEW_GAMEPAD:EndCurrentPreview()
        end

        KEYBIND_STRIP:RemoveKeybindButtonGroup(previousList.keybinds)
    end

    if list then
        self.owner:SetCurrentList(list.list)
        KEYBIND_STRIP:AddKeybindButtonGroup(list.keybinds)

        if list == self.categoryList then
            self:SetFurnitureRightInfoState(RIGHT_INFO_STATE.HOUSE_INFO)
        elseif list == self.furnitureList then
            self:SetFurnitureRightInfoState(RIGHT_INFO_STATE.FURNITURE_INFO)
        end
    else
        self.owner:SetCurrentList(nil)
    end
end

do
    local NO_CATEGORY_NAME = nil
    local NO_NICKNAME = nil
    local IS_PURCHASEABLE = true
    local BLANK_HINT = ""
    local HIDE_VISUAL_LAYER_INFO = false
    local NO_COOLDOWN = nil
    local HIDE_BLOCK_REASON = false

    function ZO_HousingFurnitureList_Gamepad:RefreshFurnitureTooltip()
        if self.rightInfoState == RIGHT_INFO_STATE.FURNITURE_INFO then
            local targetData = self.furnitureList.list:GetTargetData()
            if targetData then
                local furnitureObject = targetData.furnitureObject
                if furnitureObject then
                    if furnitureObject.bagId and furnitureObject.slotIndex then
                        GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_RIGHT_TOOLTIP, furnitureObject.bagId, furnitureObject.slotIndex)
                    elseif furnitureObject.marketProductId then
                        local productId = furnitureObject.marketProductId
                        local productType = GetMarketProductType(productId)
                        if productType == MARKET_PRODUCT_TYPE_COLLECTIBLE then
                            local collectibleId, _, name, type, description, owned, isPlaceholder = GetMarketProductCollectibleInfo(productId)
                            GAMEPAD_TOOLTIPS:LayoutCollectible(GAMEPAD_RIGHT_TOOLTIP, collectibleId, NO_CATEGORY_NAME, name, NO_NICKNAME, IS_PURCHASEABLE, description, BLANK_HINT, isPlaceholder, HIDE_VISUAL_LAYER_INFO, NO_COOLDOWN, HIDE_BLOCK_REASON)
                        elseif productType == MARKET_PRODUCT_TYPE_ITEM then
                            local itemLink = GetMarketProductItemLink(productId)
                            local stackCount = GetMarketProductStackCount(productId)
                            GAMEPAD_TOOLTIPS:LayoutItemWithStackCountSimple(GAMEPAD_RIGHT_TOOLTIP, itemLink, stackCount)
                        end
                    elseif furnitureObject.collectibleId then
                        local collectibleId = furnitureObject.collectibleId
                        local name, description, _, _, _, purchasable, _, _, hint, isPlaceholder = GetCollectibleInfo(collectibleId)
                        local nickname = GetCollectibleNickname(collectibleId)
                        GAMEPAD_TOOLTIPS:LayoutCollectible(GAMEPAD_RIGHT_TOOLTIP, collectibleId, NO_COLLECTION_NAME, name, nickname, purchaseable, description, hint, isPlaceholder, HIDE_VISUAL_LAYER_INFO, NO_COOLDOWN, HIDE_BLOCK_REASON)
                    elseif furnitureObject.retrievableFurnitureId then
                        local itemLink, collectibleLink = GetPlacedFurnitureLink(furnitureObject.retrievableFurnitureId)
                        if itemLink ~= "" then
                            GAMEPAD_TOOLTIPS:LayoutItem(GAMEPAD_RIGHT_TOOLTIP, itemLink)
                        elseif collectibleLink ~= "" then
                            GAMEPAD_TOOLTIPS:LayoutCollectibleFromLink(GAMEPAD_RIGHT_TOOLTIP, collectibleLink)
                        end
                    end
                end
            end
        else
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        end
    end
end

function ZO_HousingFurnitureList_Gamepad:SetFurnitureRightInfoState(rightInfoState)
    if self.rightInfoState ~= rightInfoState then
        self.rightInfoState = rightInfoState

        if rightInfoState == RIGHT_INFO_STATE.HOUSE_INFO then
            SCENE_MANAGER:AddFragment(HOUSE_INFORMATION_FRAGMENT_GAMEPAD)
            SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
        elseif rightInfoState == RIGHT_INFO_STATE.FURNITURE_INFO then
            SCENE_MANAGER:RemoveFragment(HOUSE_INFORMATION_FRAGMENT_GAMEPAD)
            SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
        end

        self:RefreshFurnitureTooltip()
    end
end

function ZO_HousingFurnitureList_Gamepad:HideCurrentList()
    if self.currentList == nil then
        return
    end

    self:SwitchActiveList(nil)
end

function ZO_HousingFurnitureList_Gamepad:UpdateCurrentKeybinds()
    if self.currentList then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentList.keybinds)
    end
end

do
    local function CreateCategoryEntryData(categoryData)
        local name, gamepadIcon
        local categoryId = categoryData:GetCategoryId()
        if categoryId == ZO_FURNITURE_NEEDS_CATEGORIZATION_FAKE_CATEGORY then
            gamepadIcon = ZO_NO_TEXTURE_FILE -- TODO: get an icon for this category
        else
            gamepadIcon = GetFurnitureCategoryGamepadIcon(categoryId)
        end
        local formattedName = zo_strformat(SI_HOUSING_FURNITURE_CATEGORY_FORMAT, categoryData:GetName(), categoryData:GetNumEntryItemsRecursive())
        local itemsData = ZO_GamepadEntryData:New(formattedName, gamepadIcon)
        itemsData.categoryId = categoryId
        itemsData.categoryData = categoryData
        return itemsData
    end

    function ZO_HousingFurnitureList_Gamepad:BuildCategoryList()
        local categoryList = self.categoryList.list
        categoryList:Clear()

        local categoryTreeData = self:GetCategoryTreeDataRoot()
        if categoryTreeData then
            local allTopLevelCategories = categoryTreeData:GetAllSubcategories()
            for i, categoryData in ipairs(allTopLevelCategories) do
                local nextCategoryEntry = CreateCategoryEntryData(categoryData)
                categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", nextCategoryEntry)
            end
        end

        categoryList:SetNoItemText(self:GetNoItemText())
        categoryList:Commit()

        return categoryList:IsEmpty()
    end    
end

function ZO_HousingFurnitureList_Gamepad:BuildFurnitureEntry(furnitureObject)
    local entry = ZO_GamepadEntryData:New(furnitureObject:GetFormattedName(), furnitureObject:GetIcon())
    entry.furnitureObject = furnitureObject

    entry:SetFontScaleOnSelection(false)

    entry.quality = furnitureObject:GetQuality()
    entry:SetNameColors(entry:GetColorsBasedOnQuality(entry.quality))

    local stackCount = furnitureObject:GetStackCount()
    entry:SetStackCount(stackCount)

    entry.isGemmable = furnitureObject:IsGemmable()
    entry.stolen = furnitureObject:IsStolen()
    entry.isFromCrownStore = furnitureObject:IsFromCrownStore()

    if furnitureObject:GetDataType() == ZO_RECALLABLE_HOUSING_DATA_TYPE then
        entry:SetShowUnselectedSublabels(true)
        entry:AddSubLabel(zo_strformat(SI_GAMEPAD_HOUSING_DISTANCE_AWAY_FORMAT, furnitureObject:GetDistanceFromPlayerM()))
    end

    return entry
end

function ZO_HousingFurnitureList_Gamepad:CompareFurnitureEntries(a, b)
    return a:GetRawName() < b:GetRawName()
end

function ZO_HousingFurnitureList_Gamepad:BuildFurnitureEntriesInCategory(category)
    local furnitureList = self.furnitureList.list
    local allEntries = category:GetAllEntries()
    if #allEntries > 0 then
        local sortedEntries = ZO_ShallowTableCopy(allEntries)
        table.sort(sortedEntries, self.CompareFurnitureEntriesFunction)

        for i, furnitureObject in ipairs(sortedEntries) do
            local entry = self:BuildFurnitureEntry(furnitureObject)
            local entryHasHeader = i == 1
            if entryHasHeader then
                entry:SetHeader(category:GetName())
            end
            if furnitureObject:GetDataType() == ZO_HOUSING_MARKET_PRODUCT_DATA_TYPE then
                if entryHasHeader then
                    furnitureList:AddEntry("ZO_GamepadHousingMPEntryTemplateWithHeader", entry)
                else
                    furnitureList:AddEntry("ZO_GamepadHousingMPEntryTemplate", entry)
                end
            else
                if entryHasHeader then
                    furnitureList:AddEntry("ZO_GamepadHousingItemEntryTemplateWithHeader", entry)
                else
                    furnitureList:AddEntry("ZO_GamepadHousingItemEntryTemplate", entry)
                end
            end
        end
    end
end

function ZO_HousingFurnitureList_Gamepad:BuildFurnitureList()
    local furnitureListInfo = self.furnitureList
    local furnitureList = furnitureListInfo.list

    furnitureList:Clear()

    if not self.currentCategoryData then
        return false
    end

    self:BuildFurnitureEntriesInCategory(self.currentCategoryData)
    for _, subCategory in ipairs(self.currentCategoryData:GetAllSubcategories()) do
        self:BuildFurnitureEntriesInCategory(subCategory)
    end

    if furnitureList:IsEmpty() then
        furnitureList:Commit()
        return false
    end

    local savedListPositionData = self.savedCategoryListPositions[self.currentCategoryData:GetCategoryId()]
    local currentPosition = savedListPositionData and savedListPositionData.position or 1
    furnitureList:SetSelectedIndexWithoutAnimation(currentPosition, true)

    furnitureList:Commit()

    local currentSelectedIndex = self.furnitureList.list:GetSelectedIndex()
    local currentSelectedData = self.furnitureList.list:GetSelectedData()
    local currentSelectedCategoryId, currentSelectedSubcategoryId = currentSelectedData.furnitureObject:GetCategoryInfo()
    -- check to see if we are no longer in the same category as we were before
    if savedListPositionData and (savedListPositionData.categoryId ~= currentSelectedCategoryId or savedListPositionData.subcategoryId ~= currentSelectedSubcategoryId) then
        local previousIndexData = self.furnitureList.list:GetEntryData(currentSelectedIndex - 1)
        if previousIndexData then
            local previousSelectedCategoryId, previousSelectedSubcategoryId = previousIndexData.furnitureObject:GetCategoryInfo()
            -- check and see if we can move back into the category that we were before, otherwise we are good right where we are right now
            if savedListPositionData.categoryId == previousSelectedCategoryId and savedListPositionData.subcategoryId == previousSelectedSubcategoryId then
                furnitureList:SetSelectedIndexWithoutAnimation(currentSelectedIndex - 1)
            end
        end
    end
    
    return true
end

function ZO_HousingFurnitureList_Gamepad:GetCategoryTreeDataRoot()
    assert(false) -- override in derived classes
end

function ZO_HousingFurnitureList_Gamepad:OnFurnitureTargetChanged(list, targetData, oldTargetData)
    self:RefreshFurnitureTooltip()
end

--Returns the text that is shown when the list has nothing in it
function ZO_HousingFurnitureList_Gamepad:GetNoItemText()
    assert(false) --Override
end

------------------------------------
-- Housing Permissions List Gamepad
------------------------------------

ZO_HousingSettingsList_Gamepad = ZO_Object.MultiSubclass(ZO_GamepadInteractiveSortFilterList, ZO_SocialOptionsDialogGamepad)

function ZO_HousingSettingsList_Gamepad:New(...)
    return ZO_GamepadSocialListPanel.New(self, ...)
end

function ZO_HousingSettingsList_Gamepad:Initialize(userGroup, control, owner, dataType)
    self.userGroup = userGroup
    self.owner = owner
    self.rowDataType = dataType
    self.masterList = {}
    ZO_GamepadInteractiveSortFilterList.Initialize(self, control)
    ZO_SocialOptionsDialogGamepad.Initialize(self)
    ZO_ScrollList_AddDataType(self.list, dataType, "ZO_HousingPermissionsRow_Gamepad", ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_ROW_HEIGHT, function(control, data) self:SetupRow(control, data) end)
    self:SetEmptyText(GetString(SI_GAMEPAD_HOUSING_PERMISSIONS_NO_ENTRIES))
    self:SetupSort(ZO_HOUSING_SETTINGS_LIST_ENTRY_SORT_KEYS, "displayName", ZO_SORT_ORDER_DOWN)
end

function ZO_HousingSettingsList_Gamepad:InitializeKeybinds()
    local keybindDescriptor = {}
    self.backButtonCallback = function()
                                self:Deactivate()
                                SYSTEMS:GetObject("furniture_settings"):SelectMainMenuList()
                            end
    self:AddSocialOptionsKeybind(keybindDescriptor)
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(keybindDescriptor, GAME_NAVIGATION_TYPE_BUTTON, self:GetBackKeybindCallback())
    self:SetKeybindStripDescriptor(keybindDescriptor)
    ZO_GamepadInteractiveSortFilterList.InitializeKeybinds(self)
end

function ZO_HousingSettingsList_Gamepad:InitializeSearchFilter()
    ZO_GamepadInteractiveSortFilterList.InitializeSearchFilter(self)

    if self.userGroup == HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL then
        ZO_EditDefaultText_Initialize(self.searchEdit, ZO_GetPlatformAccountLabel())
    else
        ZO_EditDefaultText_Initialize(self.searchEdit, GetString(SI_GAMEPAD_HOUSING_PERMISSIONS_SEARCH_GUILD))
    end

    self.filterFunction = function(data)
                             return self:IsMatch(self:GetCurrentSearch(), data)
                          end
end

function ZO_HousingSettingsList_Gamepad:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    local searchTerm = self:GetCurrentSearch()
    
    for _, data in ipairs(self.masterList) do
        if searchTerm == "" or self:IsMatch(searchTerm, data) then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_PRIMARY_DATA_TYPE, data))
        end
    end
end

function ZO_HousingSettingsList_Gamepad:BuildOptionsList()
    local groupingId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)

    local function BuildRemoveUserGroupOption()
        return self:BuildRemoveUserGroupOption()
    end

    local function BuildChangeUserGroupPermissionsOption()
        return self:BuildChangeUserGroupPermissionsOption()
    end

    self:AddOptionTemplate(groupingId, BuildChangeUserGroupPermissionsOption, ZO_HousingSettingsList_Gamepad.SelectedDataHasPreset)
    self:AddOptionTemplate(groupingId, BuildRemoveUserGroupOption)
end

function ZO_HousingSettingsList_Gamepad:SelectedDataHasPreset()
    return self.socialData.permissionPresetName ~= nil
end

function ZO_HousingSettingsList_Gamepad:GetBackKeybindCallback()
    return self.backButtonCallback
end

function ZO_HousingSettingsList_Gamepad:SetupRow(control, data, selected)
    local displayNameControl = control:GetNamedChild("DisplayName")
    local permissionControl = control:GetNamedChild("Permission")

    displayNameControl:SetText(data.displayName)
    displayNameControl:SetColor(ZO_NORMAL_TEXT:UnpackRGB())

    if permissionControl then
        permissionControl:SetText(data.permissionPresetName)
    end
end

function ZO_HousingSettingsList_Gamepad:OnShown()
    ZO_GamepadInteractiveSortFilterList.OnShowing(self)
    self:RefreshData()
end

function ZO_HousingSettingsList_Gamepad:RefreshData()
    if not self.control:IsHidden() then
        ZO_GamepadSocialListPanel.RefreshData(self)
    end
end

function ZO_HousingSettingsList_Gamepad:RefreshTooltip()
    -- Do nothing, because housing permission list doesn't use a tooltip like other social lists
end

function ZO_HousingSettingsList_Gamepad:InitializeDropdownFilter()
    -- housing permission list doesn't use a the dropdown
    local filterControl = self.contentHeader:GetNamedChild("DropdownFilter")
    local filterDropdownControl = filterControl:GetNamedChild("Dropdown")
    self.filterDropdown = ZO_ComboBox_ObjectFromContainer(filterDropdownControl)
    filterControl:SetHidden(true)
end

function ZO_HousingSettingsList_Gamepad:EntrySelectionCallback(oldData, newData)
    ZO_GamepadInteractiveSortFilterList.EntrySelectionCallback(self, oldData, newData)
    self:SetupOptions(newData)
end

function ZO_HousingSettingsList_Gamepad:BuildRemoveUserGroupOption()
    local callback = function()
        local data = self.socialData

        local headerText
        local titleText
        if data.dataEntry.typeId == ZO_SETTINGS_VISITOR_DATA_TYPE  then
            headerText = zo_strformat(SI_DIALOG_TEXT_REMOVE_INDIVIDUAL_PERMISSION, data.displayName)
            titleText = GetString(SI_DIALOG_TITLE_REMOVE_INDIVIDUAL_PERMISSION)
        elseif data.dataEntry.typeId == ZO_SETTINGS_GUILD_VISITOR_DATA_TYPE then
            headerText = zo_strformat(SI_DIALOG_TEXT_REMOVE_GUILD_PERMISSION, data.displayName)
            titleText = GetString(SI_DIALOG_TITLE_REMOVE_GUILD_PERMISSION)
        elseif data.dataEntry.typeId == ZO_SETTINGS_BANLIST_DATA_TYPE then
            headerText = zo_strformat(SI_DIALOG_TEXT_REMOVE_BANLIST_INDIVIDUAL_PERMISSION, data.displayName)
            titleText = GetString(SI_DIALOG_TITLE_REMOVE_BANLIST_INDIVIDUAL_PERMISSION)
        elseif data.dataEntry.typeId == ZO_SETTINGS_GUILD_BANLIST_DATA_TYPE then
            headerText = zo_strformat(SI_DIALOG_TEXT_REMOVE_BANLIST_GUILD_PERMISSION, data.displayName)
            titleText = GetString(SI_DIALOG_TITLE_REMOVE_BANLIST_GUILD_PERMISSION)
        end

        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_CONFIRM_REMOVE_PERMISSIONS", { titleText = titleText, headerText = headerText, currentHouse = data.currentHouse, userGroup = data.userGroup, index = data.index }) 
    end
    return self:BuildOptionEntry(nil, GetString(SI_HOUSING_PERMISSIONS_OPTIONS_REMOVE), callback)
end

function ZO_HousingSettingsList_Gamepad:BuildChangeUserGroupPermissionsOption()
    local callback = function()
        local data = self.socialData
        ZO_Dialogs_ShowGamepadDialog("GAMEPAD_CHANGE_HOUSING_PERMISSIONS", data) 
    end
    return self:BuildOptionEntry(nil, GetString(SI_HOUSING_PERMISSIONS_OPTIONS_CHANGE_PERMISSIONS), callback)
end

function ZO_HousingSettingsList_Gamepad:ShowList()
    if not self.listFragmentGroup then
        self.listFragmentGroup = { self.listFragment, GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT }
    end
    GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE:AddFragmentGroup(self.listFragmentGroup)
end

function ZO_HousingSettingsList_Gamepad:HideList()
    GAMEPAD_HOUSING_FURNITURE_BROWSER_SCENE:RemoveFragmentGroup(self.listFragmentGroup)
end

function ZO_HousingSettingsList_Gamepad:ActivateList()
    self:Activate()
end

function ZO_HousingSettingsList_Gamepad:GetNumPossibleEntries()
    return #self.masterList
end

function ZO_HousingSettingsList_Gamepad:GetUserGroup()
    return self.userGroup
end

function ZO_HousingSettingsList_Gamepad:FilterScrollList()
    ZO_HousingSettings_FilterScrollList(self.list, self.masterList, self.rowDataType, self.filterFunction)
end

function ZO_HousingSettingsList_Gamepad:DoesEntryPassFilter(data)
    return self:IsMatch(self:GetCurrentSearch(), data)
end

function ZO_HousingSettingsList_Gamepad_CreateScrollData(displayName, currentHouse, userGroup, index, permissionPresetName)
    return { 
                displayName = displayName, 
                userGroup = userGroup,
                currentHouse = currentHouse, 
                index = index,
                permissionPresetName = permissionPresetName,
                type = ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_SEARCH_TYPE_NAMES,
           }
end

--
--[[ ZO_HousingSettingsVisitorList_Gamepad ]]--
--

ZO_HousingSettingsVisitorList_Gamepad = ZO_HousingSettingsList_Gamepad:Subclass()

function ZO_HousingSettingsVisitorList_Gamepad:New(...)
    return ZO_HousingSettingsList_Gamepad.New(self, HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL, ...)
end

function ZO_HousingSettingsVisitorList_Gamepad:BuildMasterList()
    self.currentHouse = self.owner.currentHouse
    self.numPermissions = GetNumHousingPermissions(self.currentHouse, HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL)
    ZO_HousingSettings_BuildMasterList_Visitor(self.currentHouse, self.userGroup, self.numPermissions, self.masterList, ZO_HousingSettingsList_Gamepad_CreateScrollData)
end

function ZO_HousingSettingsVisitorList_Gamepad:GetAddUserGroupDialogTitle()
    return GetString(SI_DIALOG_TITLE_ADD_INDIVIDUAL_PERMISSION)
end


--
--[[ ZO_HousingSettingsBanList_Gamepad ]]--
--

ZO_HousingSettingsBanList_Gamepad = ZO_HousingSettingsList_Gamepad:Subclass()

function ZO_HousingSettingsBanList_Gamepad:New(...)
    return ZO_HousingSettingsList_Gamepad.New(self, HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL, ...)
end

function ZO_HousingSettingsBanList_Gamepad:BuildMasterList()
    self.currentHouse = self.owner.currentHouse
    self.numPermissions = GetNumHousingPermissions(self.currentHouse, HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL)
    ZO_HousingSettings_BuildMasterList_Ban(self.currentHouse, self.userGroup, self.numPermissions, self.masterList, ZO_HousingSettingsList_Gamepad_CreateScrollData)
end

function ZO_HousingSettingsBanList_Gamepad:GetAddUserGroupDialogTitle()
    return GetString(SI_DIALOG_TITLE_BAN_INDIVIDUAL_PERMISSION)
end

--
--[[ ZO_HousingSettingsGuildVisitorList_Gamepad ]]--
--

ZO_HousingSettingsGuildVisitorList_Gamepad = ZO_HousingSettingsList_Gamepad:Subclass()

function ZO_HousingSettingsGuildVisitorList_Gamepad:New(...)
    return ZO_HousingSettingsList_Gamepad.New(self, HOUSE_PERMISSION_USER_GROUP_GUILD, ...)
end

function ZO_HousingSettingsGuildVisitorList_Gamepad:BuildMasterList()
    self.currentHouse = self.owner.currentHouse
    self.numPermissions = GetNumHousingPermissions(self.currentHouse, HOUSE_PERMISSION_USER_GROUP_GUILD)
    ZO_HousingSettings_BuildMasterList_Visitor(self.currentHouse, self.userGroup, self.numPermissions, self.masterList, ZO_HousingSettingsList_Gamepad_CreateScrollData)
end

function ZO_HousingSettingsGuildVisitorList_Gamepad:GetAddUserGroupDialogTitle()
    return GetString(SI_DIALOG_TITLE_ADD_GUILD_PERMISSION)
end

--
--[[ ZO_HousingSettingsGuildBanList_Gamepad ]]--
--

ZO_HousingSettingsGuildBanList_Gamepad = ZO_HousingSettingsList_Gamepad:Subclass()

function ZO_HousingSettingsGuildBanList_Gamepad:New(...)
    return ZO_HousingSettingsList_Gamepad.New(self, HOUSE_PERMISSION_USER_GROUP_GUILD, ...)
end

function ZO_HousingSettingsGuildBanList_Gamepad:BuildMasterList()
    self.currentHouse = self.owner.currentHouse
    self.numPermissions = GetNumHousingPermissions(self.currentHouse, HOUSE_PERMISSION_USER_GROUP_GUILD)
    ZO_HousingSettings_BuildMasterList_Ban(self.currentHouse, self.userGroup, self.numPermissions, self.masterList, ZO_HousingSettingsList_Gamepad_CreateScrollData)
end

function ZO_HousingSettingsGuildBanList_Gamepad:GetAddUserGroupDialogTitle()
    return GetString(SI_DIALOG_TITLE_BAN_GUILD_PERMISSION)
end

-- Global XML functions

function ZO_GamepadHousingMPEntryTemplate_OnInitialized(control)
    ZO_SharedGamepadEntry_OnInitialized(control)
    ZO_SharedGamepadEntry_SetHeightFromLabels(control)

    control.priceLabel = control:GetNamedChild("Price")
    control.previousPriceLabel = control:GetNamedChild("PreviousPrice")

    control.subLabel1 = control:GetNamedChild("SubLabel1")
    control.subLabel1Background = control.subLabel1:GetNamedChild("Background")
    control.subLabel1LeftBackground = control.subLabel1Background:GetNamedChild("Left")
    control.subLabel1RightBackground = control.subLabel1Background:GetNamedChild("Right")
    control.subLabel1CenterBackground = control.subLabel1Background:GetNamedChild("Center")
end
