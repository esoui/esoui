ZO_HOUSING_CATEGORY_PATHING_ICON_GAMEPAD = "EsoUI/Art/Housing/Gamepad/gp_housing_category_npc_pathing.dds"
ZO_HOUSING_PATH_STARTING_NODE_ICON_GAMEPAD = "EsoUI/Art/Housing/Gamepad/gp_npc_pathing_start.dds"

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
    self.optionsDialogLayoutInfo = nil

    -- Order matters
    self:InitializeOptionsDialogLayoutInfo()
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
            local NO_TINT = nil
            if data.isFromCrownStore and not data.furnitureObject.marketProductId then
                statusIndicator:AddIcon(ZO_Currency_GetPlatformCurrencyIcon(CURT_CROWNS), NO_TINT, GetString(SI_SCREEN_NARRATION_CROWN_STORE_ITEM_ICON_NARRATION))
            end

            if data.isStartingPathNode then
                statusIndicator:AddIcon(ZO_HOUSING_PATH_STARTING_NODE_ICON_GAMEPAD, NO_TINT, GetString(SI_SCREEN_NARRATION_STARTING_NODE_ICON_NARRATION))
            end

            statusIndicator:Show()
        end
    end

    local PRICE_LABEL_PADDING_X = 5

    local function MarketProductEntryDataSetup(control, data, selected, ...)
        local canBePurchased = data.furnitureObject:CanBePurchased()
        data.iconDesaturation = canBePurchased and 0 or 1
        data.disabled = not canBePurchased
        FurnitureEntryDataSetup(control, data, selected, ...)

        local furnitureObject = data.furnitureObject

        local currencyType = GetCurrencyTypeFromMarketCurrencyType(furnitureObject.currencyType)
        ZO_CurrencyControl_SetSimpleCurrency(control.priceLabel, currencyType, furnitureObject.costAfterDiscount, ZO_GAMEPAD_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL)
        data:SetPriceNarrationInfo(furnitureObject.costAfterDiscount, currencyType)
        
        local priceWidth = control.priceLabel:GetTextWidth()
        control.label:SetDimensions(ZO_GAMEPAD_DEFAULT_LIST_ENTRY_WIDTH_AFTER_INDENT - PRICE_LABEL_PADDING_X - priceWidth)

        if furnitureObject.onSale then
            local formattedAmount = zo_strformat(SI_NUMBER_FORMAT, furnitureObject.cost)
            local strikethroughAmountString = zo_strikethroughTextFormat(formattedAmount)
            control.previousPriceLabel:SetText(strikethroughAmountString)
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
        elseif furnitureObject.isNew and canBePurchased then -- only show the new tag if the product isn't purchased
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

    self:InitializeOptionsDialog()
end

function ZO_HousingFurnitureList_Gamepad:InitializeKeybindStripDescriptors()
    local optionsDialogName = self.optionsDialogLayoutInfo and self.optionsDialogLayoutInfo.dialogName or nil

    local function ShowOptionsDialog()
        local boundFilterValue, locatonFiltersValue, limitFiltersValue = self.optionsDialogLayoutInfo:getFiltersFunction()
        local dialogData =
        {
            boundFilter = boundFilterValue,
            locationFilters = locatonFiltersValue,
            limitFilters = limitFiltersValue,
        }
        ZO_Dialogs_ShowGamepadDialog(optionsDialogName, dialogData)
    end

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
        -- Options
        {
            name = GetString(SI_GAMEPAD_HOUSING_FURNITURE_BROWSER_OPTIONS_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                ShowOptionsDialog()
            end,
            visible = function()
                return optionsDialogName and not HOUSING_EDITOR_STATE:IsHousePreview()
            end,
        },

        -- Send Invite
        {
            name = GetString(SI_GAMEPAD_HOUSING_SEND_INVITE),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            callback = function()
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_HOUSING_EDITOR_LINK_INVITE")
            end,
            visible = function()
                return not HOUSING_EDITOR_STATE:IsHousePreview()
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

        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.furnitureList.list)
    end

    local function ToggleViewKeybindEnabled()
        return self.furnitureList.list:GetTargetData() ~= nil
    end

    self.furnitureKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Options
        {
            name = GetString(SI_GAMEPAD_HOUSING_FURNITURE_BROWSER_OPTIONS_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                ShowOptionsDialog()
            end,
            visible = function()
                return optionsDialogName and not HOUSING_EDITOR_STATE:IsHousePreview()
            end,
        },

        -- Toggle view
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = GetString(SI_GAMEPAD_HOUSING_FURNITURE_BROWSER_TOGGLE_INFO),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            callback = ToggleFurnitureRightInfoState,
            visible = ToggleViewKeybindEnabled,
        },
    }

    local function OnFurnitureListBack()
        self:FurnitureKeybindBackCallback()
    end

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.furnitureKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnFurnitureListBack)
end

function ZO_HousingFurnitureList_Gamepad:InitializeOptionsDialog()
    local optionsDialogLayoutInfo = self.optionsDialogLayoutInfo
    if not optionsDialogLayoutInfo then
        -- This list does not require an Options dialog.
        return
    end

    local optionsDialogName = optionsDialogLayoutInfo.dialogName
    local boundFilterEnabled = optionsDialogLayoutInfo.boundFilterEnabled
    local locationFilterEnabled = optionsDialogLayoutInfo.locationFilterEnabled
    local limitFilterEnabled = optionsDialogLayoutInfo.limitFilterEnabled

    local boundFilterTypesData = nil
    if boundFilterEnabled then
        boundFilterTypesData = {}
        for filterValue = HOUSING_FURNITURE_BOUND_FILTER_ITERATION_BEGIN, HOUSING_FURNITURE_BOUND_FILTER_ITERATION_END do
            local function OnBoundFilterSelected()
                optionsDialogLayoutInfo.updateFiltersHandler(filterValue)
            end

            local entryName
            if filterValue == HOUSING_FURNITURE_BOUND_FILTER_ALL then
                entryName = GetString(SI_HOUSING_FURNITURE_BOUND_FILTER_ALL_TEXT)
            else
                entryName = GetString("SI_HOUSINGFURNITUREBOUNDFILTER", filterValue)
            end

            local newEntry = ZO_ComboBox_Base:CreateItemEntry(entryName, OnBoundFilterSelected)
            newEntry.filterValue = filterValue
            table.insert(boundFilterTypesData, newEntry)
        end
    end

    local locationFilterTypesData = nil
    if locationFilterEnabled then
        local locationFilterEntries = {}
        for filterValue in ZO_FlagHelpers.FlagIterator(HOUSING_FURNITURE_LOCATION_FILTER_ITERATION_BEGIN * 2, HOUSING_FURNITURE_LOCATION_FILTER_ITERATION_END) do
            local newEntry = ZO_ComboBox_Base:CreateItemEntry(GetString("SI_HOUSINGFURNITURELOCATIONFILTER", filterValue))
            newEntry.filterValue = filterValue

            newEntry.callback = function(control, name, item, isSelected)
                local boundFiltersValue, locationFiltersValue, limitFiltersValue = optionsDialogLayoutInfo:getFiltersFunction()
                if isSelected then
                    locationFiltersValue = ZO_FlagHelpers.SetMaskFlag(locationFiltersValue, filterValue)
                else
                    locationFiltersValue = ZO_FlagHelpers.ClearMaskFlag(locationFiltersValue, filterValue)
                end
                optionsDialogLayoutInfo.updateFiltersHandler(boundFiltersValue, locationFiltersValue, limitFiltersValue)
            end

            table.insert(locationFilterEntries, newEntry)
        end

        local function CompareLocationFilters(left, right)
            return left.name < right.name
        end
        table.sort(locationFilterEntries, CompareLocationFilters)

        locationFilterTypesData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
        for _, entry in ipairs(locationFilterEntries) do
            locationFilterTypesData:AddItem(entry)
        end
    end

    local limitFilterTypesData = nil
    if limitFilterEnabled then
        -- In order to match the House Information panel layout these limit filters are not sorted.
        limitFilterTypesData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
        for limitType = HOUSING_FURNISHING_LIMIT_TYPE_ITERATION_BEGIN, HOUSING_FURNISHING_LIMIT_TYPE_ITERATION_END do
            local newEntry = ZO_ComboBox_Base:CreateItemEntry(GetString("SI_HOUSINGFURNISHINGLIMITTYPE", limitType))
            local filterValue = ZO_HOUSING_FURNITURE_LIMIT_FILTERS[limitType + 1]
            newEntry.filterValue = filterValue

            newEntry.callback = function(control, name, item, isSelected)
                local boundFiltersValue, locationFiltersValue, limitFiltersValue = optionsDialogLayoutInfo:getFiltersFunction()
                if isSelected then
                    limitFiltersValue = ZO_FlagHelpers.SetMaskFlag(limitFiltersValue, filterValue)
                else
                    limitFiltersValue = ZO_FlagHelpers.ClearMaskFlag(limitFiltersValue, filterValue)
                end
                optionsDialogLayoutInfo.updateFiltersHandler(boundFiltersValue, locationFiltersValue, limitFiltersValue)
            end

            limitFilterTypesData:AddItem(newEntry)
        end
    end

    local boundFilterTypesDropdownEntry = nil
    if boundFilterEnabled then
        boundFilterTypesDropdownEntry =
        {
            template = "ZO_GamepadDropdownItem",
            templateData = 
            {
                setup = function(control, data, selected)
                    local dropdown = control.dropdown
                    boundFilterTypesData.dropdownInstance = dropdown

                    dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                    dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                    dropdown:SetSelectedItemTextColor(selected)
                    dropdown:SetSortsItems(false)
                    dropdown:ClearItems()
                    for _, entry in ipairs(boundFilterTypesData) do
                        dropdown:AddItem(entry)
                    end
                    dropdown:UpdateItems()

                    local boundFilterValue = optionsDialogLayoutInfo:getFiltersFunction()
                    boundFilterValue = boundFilterValue or HOUSING_FURNITURE_BOUND_FILTER_ALL
                    local isAllBoundSelected = false
                    if boundFilterValue == HOUSING_FURNITURE_BOUND_FILTER_ALL then
                        isAllBoundSelected = true
                    elseif boundFilterValue == (HOUSING_FURNITURE_BOUND_FILTER_BOUND + HOUSING_FURNITURE_BOUND_FILTER_UNBOUND) then
                        isAllBoundSelected = true
                    end

                    if isAllBoundSelected then
                        dropdown:SelectItemByIndex(1)
                    else
                        if ZO_FlagHelpers.MaskHasFlag(boundFilterValue, HOUSING_FURNITURE_BOUND_FILTER_BOUND) then
                            dropdown:SelectItemByIndex(2)
                        end
                        if ZO_FlagHelpers.MaskHasFlag(boundFilterValue, HOUSING_FURNITURE_BOUND_FILTER_UNBOUND) then
                            dropdown:SelectItemByIndex(3)
                        end
                    end

                    SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdown)
                end,

                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetControl then
                        targetControl.dropdown:Activate()
                    end
                end,

                narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
            },
        }
    end

    local limitFilterTypesDropdownEntry = nil
    if limitFilterEnabled then
        limitFilterTypesDropdownEntry =
        {
            template = "ZO_GamepadMultiSelectionDropdownItem",
            templateData = 
            {
                setup = function(control, data, selected)
                    local dropdown = control.dropdown
                    limitFilterTypesData.dropdownInstance = dropdown

                    local _, _, limitFilterValue = optionsDialogLayoutInfo:getFiltersFunction()
                    local entries = limitFilterTypesData:GetAllItems()
                    limitFilterTypesData:ClearAllSelections()

                    for _, entry in ipairs(entries) do
                        local isSelected = ZO_FlagHelpers.MaskHasFlag(limitFilterValue, entry.filterValue)
                        limitFilterTypesData:SetItemSelected(entry, isSelected)
                    end

                    dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                    dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                    dropdown:SetSelectedItemTextColor(selected)
                    dropdown:SetSortsItems(false)

                    dropdown:SetNoSelectionText(GetString(SI_GAMEPAD_HOUSING_FURNITURE_LIMIT_FILTER_ALL_TEXT))
                    dropdown:SetMultiSelectionTextFormatter(SI_HOUSING_FURNITURE_LIMIT_FILTER_DROPDOWN_TEXT)
                    dropdown:LoadData(limitFilterTypesData)

                    SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdown)
                end,

                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetControl then
                        targetControl.dropdown:Activate()
                    end
                end,

                narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
            },
        }
    end

    local locationFilterTypesDropdownEntry = nil
    if locationFilterEnabled then
        locationFilterTypesDropdownEntry =
        {
            template = "ZO_GamepadMultiSelectionDropdownItem",
            templateData = 
            {
                setup = function(control, data, selected)
                    local dropdown = control.dropdown
                    locationFilterTypesData.dropdownInstance = dropdown

                    local _, locationFilterValue = optionsDialogLayoutInfo:getFiltersFunction()
                    local entries = locationFilterTypesData:GetAllItems()
                    locationFilterTypesData:ClearAllSelections()

                    for _, entry in ipairs(entries) do
                        local isSelected = ZO_FlagHelpers.MaskHasFlag(locationFilterValue, entry.filterValue)
                        locationFilterTypesData:SetItemSelected(entry, isSelected)
                    end

                    dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                    dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                    dropdown:SetSelectedItemTextColor(selected)
                    dropdown:SetSortsItems(false)

                    dropdown:SetNoSelectionText(GetString(SI_GAMEPAD_HOUSING_FURNITURE_LOCATION_FILTER_ALL_TEXT))
                    dropdown:SetMultiSelectionTextFormatter(SI_HOUSING_FURNITURE_LOCATION_FILTER_DROPDOWN_TEXT)
                    dropdown:LoadData(locationFilterTypesData)

                    SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdown)
                end,

                callback = function(dialog)
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetControl then
                        targetControl.dropdown:Activate()
                    end
                end,

                narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
            },
        }
    end

    local dialogInfo =
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = function(dialog)
            ZO_GenericGamepadDialog_RefreshText(dialog, GetString(SI_GAMEPAD_HOUSING_FURNITURE_BROWSER_OPTIONS_KEYBIND))
            dialog:setupFunc()
        end,

        parametricList = { },

        blockDialogReleaseOnPress = true,

        buttons =
        {
            -- Select
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,

                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData and targetData.callback then
                        targetData.callback(dialog)
                    end
                end,
            },

            -- Back
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CLOSE,

                callback = function()
                    ZO_Dialogs_ReleaseDialogOnButtonPress(optionsDialogName)
                end,
            },

            -- Reset Filters
            {
                keybind = "DIALOG_RESET",
                text = SI_HOUSING_FURNITURE_RESET_FILTERS_KEYBIND,

                enabled = function(dialog)
                    return SHARED_FURNITURE:CanResetFurnitureFilters()
                end,

                callback = function(dialog)
                    SHARED_FURNITURE:ResetFurnitureFilters()
                    dialog:setupFunc()
                end,
            },
        },

        onHidingCallback = function(dialog)
            local boundFilterValue = HOUSING_FURNITURE_BOUND_FILTER_ALL
            if boundFilterTypesData then
                boundFilterTypesData.dropdownInstance:Deactivate()

                local boundFilterData = boundFilterTypesData.dropdownInstance:GetSelectedItemData()
                if boundFilterData and boundFilterData.filterValue then
                    boundFilterValue = boundFilterData.filterValue
                end
            end

            local locationFilterValues = 0
            if locationFilterTypesData then
                locationFilterTypesData.dropdownInstance:Deactivate()

                for _, item in ipairs(locationFilterTypesData:GetSelectedItems()) do
                    locationFilterValues = locationFilterValues + item.filterValue
                end
            end

            local limitFilterValues = 0
            if limitFilterTypesData then
                limitFilterTypesData.dropdownInstance:Deactivate()

                for _, item in ipairs(limitFilterTypesData:GetSelectedItems()) do
                    limitFilterValues = limitFilterValues + item.filterValue
                end
            end

            optionsDialogLayoutInfo.updateFiltersHandler(boundFilterValue, locationFilterValues, limitFilterValues)
        end,
    }

    -- Filters
    if locationFilterEnabled then
        table.insert(dialogInfo.parametricList, locationFilterTypesDropdownEntry)
    end
    if limitFilterEnabled then
        table.insert(dialogInfo.parametricList, limitFilterTypesDropdownEntry)
    end
    if boundFilterEnabled then
        table.insert(dialogInfo.parametricList, boundFilterTypesDropdownEntry)
    end

    ZO_Dialogs_RegisterCustomDialog(optionsDialogName, dialogInfo)
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
    self:BuildCategoryList()

    if self.currentList then
        self.currentList.buildListFunction()

        self:UpdateCurrentKeybinds()
    end
end

function ZO_HousingFurnitureList_Gamepad:ViewCategory()
    self.currentCategoryData = nil
    self.currentCategoryId = nil
    self.currentCategoryName = nil
    self:RefreshCurrentCategoryData()
    self:BuildFurnitureList()
    self:SwitchActiveList(self.furnitureList)
end

function ZO_HousingFurnitureList_Gamepad:RefreshCurrentCategoryData()
    if self.currentCategoryId == nil then
        -- Stepping into the new category.  Grab its data.
        local entryData = self.categoryList.list:GetTargetData()
        if entryData ~= nil then
            local categoryTreeData = self:GetCategoryTreeDataRoot()
            self.currentCategoryData = categoryTreeData:GetSubcategory(entryData.categoryId)
            -- When searches return 0 results, I need to stay in that category and display some data.  Cache off the important bits.
            self.currentCategoryId = entryData.categoryId
            self.currentCategoryName = self.currentCategoryData:GetName()
        else
            self.currentCategoryData = nil
            self.currentCategoryId = nil
            self.currentCategoryName = nil
        end
    else
        -- The data tree has been rebuilt.  Set our category to the new data.
        local categoryTreeData = self:GetCategoryTreeDataRoot()
        self.currentCategoryData = categoryTreeData:GetSubcategory(self.currentCategoryId)
    end
    
    if self.currentCategoryName then
        GAMEPAD_HOUSING_FURNITURE_BROWSER:SetTitleText(self.currentCategoryName)
    else
        GAMEPAD_HOUSING_FURNITURE_BROWSER:SetTitleText(nil)
    end
end

function ZO_HousingFurnitureList_Gamepad:UpdateFurnitureListSavedPosition()
    if not self.currentCategoryData then
        return
    end

    local currentCategoryId = self.currentCategoryData:GetCategoryId()
    local currentSelectedIndex = self.furnitureList.list:GetSelectedIndex()
    local currentSelectedData = self.furnitureList.list:GetSelectedData()
    if not currentSelectedData then
        if currentCategoryId ~= nil then
            self.savedCategoryListPositions[currentCategoryId] = nil
        end
        return
    end

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
        self.owner.keybindStripDescriptor = list.keybinds
        if self.owner:IsHeaderActive() then
            self.owner:RequestLeaveHeader()
            KEYBIND_STRIP:AddKeybindButtonGroup(list.keybinds)
        elseif list.list:IsEmpty() and not self.owner:IsTextSearchEntryHidden() then
            self.owner:RequestEnterHeader()
        else
            KEYBIND_STRIP:AddKeybindButtonGroup(list.keybinds)
        end

        if list == self.categoryList then
            self:SetFurnitureRightInfoState(RIGHT_INFO_STATE.HOUSE_INFO)
            GAMEPAD_HOUSING_FURNITURE_BROWSER:SetTitleText(nil)
        elseif list == self.furnitureList then
            self:SetFurnitureRightInfoState(RIGHT_INFO_STATE.FURNITURE_INFO)
            GAMEPAD_HOUSING_FURNITURE_BROWSER:SetTitleText(self.currentCategoryName)
        end
    else
        self.owner.keybindStripDescriptor = nil
        self.owner:SetCurrentList(nil)
    end
end

do
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
                        GAMEPAD_TOOLTIPS:LayoutMarketProductListing(GAMEPAD_RIGHT_TOOLTIP, furnitureObject.marketProductId, furnitureObject.presentationIndex)
                    elseif furnitureObject.collectibleId then
                        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(furnitureObject.collectibleId)
                        GAMEPAD_TOOLTIPS:LayoutCollectibleFromData(GAMEPAD_RIGHT_TOOLTIP, collectibleData, HIDE_VISUAL_LAYER_INFO, NO_COOLDOWN, HIDE_BLOCK_REASON)
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
            if not HOUSING_EDITOR_STATE:IsHousePreview() then
                SCENE_MANAGER:AddFragment(HOUSE_INFORMATION_FRAGMENT_GAMEPAD)
                SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
            end
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
        local categoryId = categoryData:GetCategoryId()
        local gamepadIcon = ZO_NO_TEXTURE_FILE
        if categoryId == ZO_FURNITURE_PATH_NODES_FAKE_CATEGORY then
            gamepadIcon = ZO_HOUSING_CATEGORY_PATHING_ICON_GAMEPAD
        elseif categoryId ~= ZO_FURNITURE_NEEDS_CATEGORIZATION_FAKE_CATEGORY then
            gamepadIcon = GetFurnitureCategoryGamepadIcon(categoryId)
        end
        -- Avoiding zo_strformat for performance, this will get run for every category every time the number of entries could have changed
        local formattedName = string.format("%s (%d)", categoryData:GetName(), categoryData:GetNumEntryItemsRecursive())
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
            local isOwner = IsOwnerOfCurrentHouse()
            local allTopLevelCategories = categoryTreeData:GetAllSubcategories()
            for i, categoryData in ipairs(allTopLevelCategories) do
                if isOwner or not categoryData:IsOwnerRestrictedCategory() then
                    local nextCategoryEntry = CreateCategoryEntryData(categoryData)
                    categoryList:AddEntry("ZO_GamepadMenuEntryTemplate", nextCategoryEntry)
                end
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

    entry.quality = furnitureObject:GetDisplayQuality()
    entry:SetNameColors(entry:GetColorsBasedOnQuality(entry.quality))

    local stackCount = furnitureObject:GetStackCount()
    entry:SetStackCount(stackCount)

    entry.isGemmable = furnitureObject:IsGemmable()
    entry.stolen = furnitureObject:IsStolen()
    entry.isFromCrownStore = furnitureObject:IsFromCrownStore()
    entry.isStartingPathNode = furnitureObject:GetDataType() == ZO_HOUSING_PATH_NODE_DATA_TYPE and furnitureObject:IsStartingPathNode()
    entry.narrationText = function(entryData, entryControl)
        local narrations = {}
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))
        ZO_AppendNarration(narrations, entryData:GetPriceNarration())
        if IsCurrentlyPreviewing() then
            ZO_AppendNarration(narrations, ITEM_PREVIEW_GAMEPAD:GetPreviewSpinnerNarrationText())
        end
        return narrations
    end

    entry.additionalInputNarrationFunction = function()
        if IsCurrentlyPreviewing() and ITEM_PREVIEW_GAMEPAD:HasVariations() then
            return ZO_GetHorizontalDirectionalInputNarrationData(GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_PREVIOUS), GetString(SI_SCREEN_NARRATION_ITEM_PREVIEW_STATE_NEXT))
        end
        return {}
    end

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

    if self.currentCategoryData then
        self:BuildFurnitureEntriesInCategory(self.currentCategoryData)
        for _, subCategory in ipairs(self.currentCategoryData:GetAllSubcategories()) do
            self:BuildFurnitureEntriesInCategory(subCategory)
        end
    end

    if furnitureList:IsEmpty() then
        if self.currentCategoryName == nil then
            -- No category name.  We're at the root level.
            furnitureList:SetNoItemText(self:GetNoItemText())
        else
            local categoryTreeData = self:GetCategoryTreeDataRoot()
            if categoryTreeData and #categoryTreeData:GetAllSubcategories() > 0 then
                -- No items in this category, but exist elsewhere.
                furnitureList:SetNoItemText(zo_strformat(SI_HOUSING_FURNITURE_NO_SEARCH_RESULTS_IN_CATEGORY, self.currentCategoryName))
            else
                -- No items in any category.
                furnitureList:SetNoItemText(GetString(SI_HOUSING_FURNITURE_NO_SEARCH_RESULTS))
            end
        end
        
        furnitureList:Commit()
        return false
    end

    local savedListPositionData = self.savedCategoryListPositions[self.currentCategoryData:GetCategoryId()]
    local currentPosition = savedListPositionData and savedListPositionData.position or 1
    furnitureList:SetSelectedIndexWithoutAnimation(currentPosition, true)

    furnitureList:Commit()

    local currentSelectedIndex = self.furnitureList.list:GetSelectedIndex()
    local currentSelectedData = self.furnitureList.list:GetSelectedData()
    if not currentSelectedData then
        return true
    end

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

function ZO_HousingFurnitureList_Gamepad:InitializeOptionsDialogLayoutInfo()
    -- Override in derived classes that implement an options dialog.
end

function ZO_HousingFurnitureList_Gamepad:OnFurnitureTargetChanged(list, targetData, oldTargetData)
    self:RefreshFurnitureTooltip()
    self:UpdateCurrentKeybinds()
end

--Returns the text that is shown when the list has nothing in it
function ZO_HousingFurnitureList_Gamepad:GetNoItemText()
    assert(false) --Override
end

function ZO_HousingFurnitureList_Gamepad:PreviewMarketProductPlacement(marketProductData)
    if not marketProductData then
        return
    end

    if HousingEditorRequestMarketProductPlacementPreview(marketProductData.marketProductId) == HOUSING_REQUEST_RESULT_SUCCESS then
        HOUSING_EDITOR_SHARED:SetCurrentPreviewMarketProduct(marketProductData)
    end
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
    ZO_ScrollList_AddDataType(self.list, dataType, "ZO_HousingPermissionsRow_Gamepad", ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_ROW_HEIGHT, function(entryControl, data) self:SetupRow(entryControl, data) end)
    self:SetEmptyText(GetString(SI_GAMEPAD_HOUSING_PERMISSIONS_NO_ENTRIES))
    self:SetupSort(ZO_HOUSING_SETTINGS_LIST_ENTRY_SORT_KEYS, "displayName", ZO_SORT_ORDER_UP)
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
        self.searchEdit:SetDefaultText(ZO_GetPlatformAccountLabel())
    else
        self.searchEdit:SetDefaultText(GetString(SI_GAMEPAD_HOUSING_PERMISSIONS_SEARCH_GUILD))
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

    local function BuildKickOccupantOption()
        return self:BuildKickOccupantOption()
    end

    local function BuildRemoveUserGroupOption()
        return self:BuildRemoveUserGroupOption()
    end

    local function BuildChangeUserGroupPermissionsOption()
        return self:BuildChangeUserGroupPermissionsOption()
    end

    local function ShouldShowGamerCardOption()
        return IsConsoleUI() and (self.rowDataType == ZO_SETTINGS_VISITOR_DATA_TYPE or self.rowDataType == ZO_SETTINGS_BANLIST_DATA_TYPE or self.rowDataType == ZO_SETTINGS_OCCUPANT_DATA_TYPE)
    end

    self:AddOptionTemplate(groupingId, BuildChangeUserGroupPermissionsOption, ZO_HousingSettingsList_Gamepad.SelectedDataHasPreset)
    self:AddOptionTemplate(groupingId, BuildKickOccupantOption, ZO_HousingSettingsList_Gamepad.IsOccupantsListAndHomeowner)
    self:AddOptionTemplate(groupingId, BuildRemoveUserGroupOption, ZO_HousingSettingsList_Gamepad.IsNotOccupantsList)
    self:AddOptionTemplate(groupingId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, ShouldShowGamerCardOption)
end

function ZO_HousingSettingsList_Gamepad:IsOccupantsListAndHomeowner()
    return self.rowDataType == ZO_SETTINGS_OCCUPANT_DATA_TYPE and HOUSING_EDITOR_STATE:IsLocalPlayerHouseOwner()
end

function ZO_HousingSettingsList_Gamepad:IsNotOccupantsList()
    return self.rowDataType ~= ZO_SETTINGS_OCCUPANT_DATA_TYPE
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

--ZO_GamepadInteractiveSortFilterList override
function ZO_HousingSettingsList_Gamepad:InitializeDropdownFilter()
    -- housing permission list doesn't use a dropdown
    self.filterControl = self.contentHeader:GetNamedChild("DropdownFilter")
    local filterDropdownControl = self.filterControl:GetNamedChild("Dropdown")
    self.filterDropdown = ZO_ComboBox_ObjectFromContainer(filterDropdownControl)
    self.filterControl:SetHidden(true)
end

--ZO_GamepadInteractiveSortFilterList override
function ZO_HousingSettingsList_Gamepad:GetNarrationText()
    local narrations = {}
    local entryData = self:GetSelectedData()

    if entryData then
        --Get the narration for the display name column
        if self.userGroup == HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(ZO_GetPlatformAccountLabel()))
        else
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSING_FURNITURE_SETTINGS_SOCIAL_LIST_GUILD)))
        end
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.displayName))

        --Get the narration for the permissions column if present
        if entryData.permissionPresetName then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSING_FURNITURE_SETTINGS_SOCIAL_LIST_PERMISSIONS)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.permissionPresetName))
        end
    end

    return narrations
end

function ZO_HousingSettingsList_Gamepad:OnSelectionChanged(oldData, newData)
    ZO_GamepadInteractiveSortFilterList.OnSelectionChanged(self, oldData, newData)
    self:SetupOptions(newData)
end

function ZO_HousingSettingsList_Gamepad:BuildKickOccupantOption()
    local callback = function()
        local data = self.socialData
        if data.dataEntry.typeId == ZO_SETTINGS_OCCUPANT_DATA_TYPE then
            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_CONFIRM_KICK_OCCUPANT", { currentHouse = data.currentHouse, displayName = data.displayName, index = data.index }) 
        end
    end
    return self:BuildOptionEntry(nil, GetString(SI_HOUSING_OCCUPANTS_KICK_OCCUPANT), callback)
end

function ZO_HousingSettingsList_Gamepad:BuildRemoveUserGroupOption()
    local callback = function()
        local data = self.socialData

        local headerText
        local titleText
        if data.dataEntry.typeId == ZO_SETTINGS_VISITOR_DATA_TYPE then
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

function ZO_HousingSettingsList_Gamepad_CreateOccupantScrollData(displayName, currentHouse, index, accountName)
    return
    { 
        displayName = displayName,
        gamerCardDisplayName = accountName,
        currentHouse = currentHouse,
        index = index,
        type = ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_SEARCH_TYPE_NAMES,
    }
end

function ZO_HousingSettingsList_Gamepad_CreateScrollData(displayName, currentHouse, userGroup, index, permissionPresetName)
    return
    {
        displayName = displayName, 
        userGroup = userGroup,
        currentHouse = currentHouse, 
        index = index,
        permissionPresetName = permissionPresetName,
        type = ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_SEARCH_TYPE_NAMES,
    }
end

--
--[[ ZO_HousingSettingsOccupantList_Gamepad ]]--
--

ZO_HousingSettingsOccupantList_Gamepad = ZO_HousingSettingsList_Gamepad:Subclass()

function ZO_HousingSettingsOccupantList_Gamepad:New(...)
    return ZO_HousingSettingsList_Gamepad.New(self, HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL, ...)
end

function ZO_HousingSettingsOccupantList_Gamepad:BuildMasterList()
    self.currentHouse = GetCurrentZoneHouseId()
    ZO_HousingSettings_BuildMasterList_Occupant(self.currentHouse, self.masterList, ZO_HousingSettingsList_Gamepad_CreateOccupantScrollData)
end

--
--[[ ZO_HousingSettingsVisitorList_Gamepad ]]--
--

ZO_HousingSettingsVisitorList_Gamepad = ZO_HousingSettingsList_Gamepad:Subclass()

function ZO_HousingSettingsVisitorList_Gamepad:New(...)
    return ZO_HousingSettingsList_Gamepad.New(self, HOUSE_PERMISSION_USER_GROUP_INDIVIDUAL, ...)
end

function ZO_HousingSettingsVisitorList_Gamepad:BuildMasterList()
    self.currentHouse = GetCurrentZoneHouseId()
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
    self.currentHouse = GetCurrentZoneHouseId()
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
    self.currentHouse = GetCurrentZoneHouseId()
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
    self.currentHouse = GetCurrentZoneHouseId()
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
