ZO_GAMEPAD_HOUSE_TOURS_LISTING_PANEL_TEXTURE_SQUARE_DIMENSION = 1024
ZO_GAMEPAD_HOUSE_TOURS_LISTING_PANEL_TEXTURE_COORD_RIGHT = ZO_GAMEPAD_QUADRANT_2_3_CONTENT_BACKGROUND_WIDTH / ZO_GAMEPAD_HOUSE_TOURS_LISTING_PANEL_TEXTURE_SQUARE_DIMENSION

local HOUSE_TOURS_MODES =
{
    OVERVIEW = 1,
    RECOMMENDED = 2,
    BROWSE = 3,
    FAVORITES = 4,
    MANAGE_LISTINGS = 5,
    SELECT_HOME = 6,
}

local PRESERVE_SELECTIONS = true
local SUPPRESS_CALLBACKS = true

local TAGS_DROPDOWN_WIDTH_OFFSET = 130

-----------------------------
--Tags Filter Header Focus
-----------------------------
ZO_HouseTours_Tags_Filter_Header_Focus_Gamepad = ZO_InitializingCallbackObject:Subclass()

function ZO_HouseTours_Tags_Filter_Header_Focus_Gamepad:Initialize(control)
    self.control = control
    self.dropdown = ZO_ComboBox_ObjectFromContainer(control)
    self.dropdown:SetDropdownWidthOffset(TAGS_DROPDOWN_WIDTH_OFFSET)
    self.active = false
    self.enabled = true
end

function ZO_HouseTours_Tags_Filter_Header_Focus_Gamepad:Activate()
    self.active = true
    self:Update()
    self:FireCallbacks("FocusActivated")
end

function ZO_HouseTours_Tags_Filter_Header_Focus_Gamepad:Enable()
    self.enabled = true
    self:Update()
end

function ZO_HouseTours_Tags_Filter_Header_Focus_Gamepad:Deactivate()
    self.active = false
    self:Update()
    self:FireCallbacks("FocusDeactivated")
end

function ZO_HouseTours_Tags_Filter_Header_Focus_Gamepad:Disable()
    self.enabled = false
    self:Update()
end

function ZO_HouseTours_Tags_Filter_Header_Focus_Gamepad:Update()
    local normalColor = self.enabled and ZO_GAMEPAD_UNSELECTED_COLOR or ZO_GAMEPAD_DISABLED_UNSELECTED_COLOR
    local highlightColor = self.enabled and ZO_GAMEPAD_SELECTED_COLOR or ZO_GAMEPAD_DISABLED_SELECTED_COLOR
    self.dropdown:SetNormalColor(normalColor:UnpackRGB())
    self.dropdown:SetHighlightedColor(highlightColor:UnpackRGB())
    self.dropdown:SetSelectedItemTextColor(self.active)
end

function ZO_HouseTours_Tags_Filter_Header_Focus_Gamepad:IsActive()
    return self.active
end

-----------------------------
--House Tours Gamepad
-----------------------------

ZO_HouseTours_Gamepad = ZO_Object.MultiSubclass(ZO_Gamepad_ParametricList_Screen, ZO_SocialOptionsDialogGamepad)

function ZO_HouseTours_Gamepad:Initialize(control)
    HOUSE_TOURS_SCENE_GAMEPAD = ZO_Scene:New("houseToursGamepad", SCENE_MANAGER)

    HOUSE_TOURS_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    HOUSE_TOURS_SCENE_GAMEPAD:AddFragment(HOUSE_TOURS_GAMEPAD_FRAGMENT)

    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_ON_SHOW, HOUSE_TOURS_SCENE_GAMEPAD)
    ZO_SocialOptionsDialogGamepad.Initialize(self)

    self:InitializeActivityFinderCategory()
    self:InitializeListingManagementFunctions()
    self:InitializeTagsSelector()
    self:InitializeListingPanel()
    self:InitializeModeData()

    self:SetIsListingOperationOnCooldown(IsHouseToursListingOnCooldown())
end

function ZO_HouseTours_Gamepad:InitializeActivityFinderCategory()
    self.houseToursCategoryData = 
    {
        gamepadData =
        {
            priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.HOUSE_TOURS,
            name = GetString(SI_ACTIVITY_FINDER_CATEGORY_HOUSE_TOURS),
            menuIcon = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_houseTours.dds",
            disabledMenuIcon = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_houseTours_disabled.dds",
            sceneName = "houseToursGamepad",
            tooltipDescription = GetString(SI_HOUSE_TOURS_DESCRIPTION),
            isHouseTours = true,
        },
    }

    local gamepadData = self.houseToursCategoryData.gamepadData
    ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:AddCategory(gamepadData, gamepadData.priority)
end

function ZO_HouseTours_Gamepad:InitializeTagsSelector()
    self.tagsFilterDropdownControl = self.header:GetNamedChild("TagsSelector")
    self.tagsFilterDropdown = ZO_ComboBox_ObjectFromContainer(self.tagsFilterDropdownControl:GetNamedChild("Dropdown"))
    self.tagsFilterHeaderFocus = ZO_HouseTours_Tags_Filter_Header_Focus_Gamepad:New(self.tagsFilterDropdownControl:GetNamedChild("Dropdown"))

    self.tagsFilterHeaderFocus:RegisterCallback("FocusActivated", function()
        local NARRATE_HEADER = true
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("houseToursTagsFilter", NARRATE_HEADER)
    end)

    local function TagSelectionChanged()
        local newTags = {}
        local selectedTagsData = self.tagsFilterDropdownEntries:GetSelectedItems()
        for _, item in ipairs(selectedTagsData) do
            table.insert(newTags, item.tagValue)
        end

        local modeData = self:GetDataForMode(self.mode)
        local filters = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(modeData.listingType)
        filters:SetTags(newTags)
    end

    local function OnTagsDropdownShown()
        local modeData = self:GetDataForMode(self.mode)
        local filters = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(modeData.listingType)
        self.oldTags = {}
        ZO_DeepTableCopy(filters.tags, self.oldTags)
        table.sort(self.oldTags)
    end

    local function OnDropdownDeactivated()
        if self:IsShowing() then
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("houseToursTagsFilter")
            --Execute a search when the dropdown is closed if filters have changed
            local modeData = self:GetDataForMode(self.mode)
            local filters = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(modeData.listingType)
            table.sort(filters.tags)
            if modeData and modeData.listingType and not ZO_AreNumericallyIndexedTablesEqual(filters.tags, self.oldTags) then
                HOUSE_TOURS_SEARCH_MANAGER:ExecuteSearch(modeData.listingType)
            end
        end
    end

    self.tagsFilterDropdown:SetMaxSelections(MAX_HOUSE_TOURS_LISTING_TAGS)
    self.tagsFilterDropdown:SetNoSelectionText(GetString(SI_HOUSE_TOURS_FILTERS_TAGS_DROPDOWN_NO_SELECTION_TEXT))
    self.tagsFilterDropdown:SetMultiSelectionTextFormatter(SI_HOUSE_TOURS_TAGS_DROPDOWN_TEXT_FORMATTER)
    self.tagsFilterDropdown:SetPreshowDropdownCallback(OnTagsDropdownShown)
    self.tagsFilterDropdown:SetDeactivatedCallback(OnDropdownDeactivated)
    self.tagsFilterDropdown:SetName(GetString(SI_HOUSE_TOURS_LISTING_TAGS_HEADER))

    self.tagsFilterDropdownEntries = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
    for i = HOUSE_TOURS_LISTING_TAG_ITERATION_BEGIN, HOUSE_TOURS_LISTING_TAG_ITERATION_END do
        local tagEntry = ZO_ComboBox_Base:CreateItemEntry(GetString("SI_HOUSETOURLISTINGTAG", i), TagSelectionChanged)
        tagEntry.tagValue = i
        self.tagsFilterDropdownEntries:AddItem(tagEntry)
    end

    self.tagsFilterDropdown:LoadData(self.tagsFilterDropdownEntries)
    self:SetupHeaderFocus(self.tagsFilterHeaderFocus)

    --Set up a custom narration for the header focus
    local narrationInfo =
    {
        canNarrate = function()
            return self:IsHeaderActive()
        end,
        selectedNarrationFunction = function()
            local narrations = {}
            ZO_AppendNarration(narrations, self.tagsFilterDropdown:GetNarrationText())
            local list = self:GetCurrentList()
            --If the list is empty, include that in the header focus narration as well
            if list:IsEmpty() then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(list:GetNoItemText()))
            end
            return narrations
        end,
        headerNarrationFunction = function()
            return self:GetHeaderNarration()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("houseToursTagsFilter", narrationInfo)
end

function ZO_HouseTours_Gamepad:InitializeListingPanel()
    local listingPanel = self.control:GetNamedChild("ListingPanel")
    listingPanel.backgroundControl = listingPanel:GetNamedChild("Background")

    local searchContainer = listingPanel:GetNamedChild("SearchInfo")
    local manageListingsContainer = listingPanel:GetNamedChild("ListingManagementInfo")

    --Initialize each of the content containers
    self:InitializePanelContents(searchContainer)
    self:InitializePanelContents(manageListingsContainer)

    self.listingPanelControl = listingPanel
    self.listingPanelFragment = ZO_FadeSceneFragment:New(self.listingPanelControl)
end

function ZO_HouseTours_Gamepad:InitializePanelContents(control)
    control.nicknameLabel = control:GetNamedChild("Nickname")
    control.nameLabel = control:GetNamedChild("Name")
    control.furnitureCountLabel = control:GetNamedChild("FurnitureCount")
    control.ownerLabel = control:GetNamedChild("OwnerValue")
    control.tagsLabel = control:GetNamedChild("TagsValue")
    control.statusLabel = control:GetNamedChild("StatusValue")
    control.recommendationsLabel = control:GetNamedChild("RecommendationsValue")
    control.recommendationsHeader = control:GetNamedChild("RecommendationsHeader")
end

function ZO_HouseTours_Gamepad:InitializeModeData()
    self.modeData =
    {
        [HOUSE_TOURS_MODES.OVERVIEW] =
        {
            list = self.categoryList,
            headerData =
            {
                titleText = GetString(SI_ACTIVITY_FINDER_CATEGORY_HOUSE_TOURS),
            },
            keybindStripDescriptor = self.overviewKeybindStripDescriptor,
            refreshFunction = function() self:RefreshCategoryList() end,
        },
        [HOUSE_TOURS_MODES.RECOMMENDED] =
        {
            list = self.searchResultsList,
            headerData =
            {
                titleText = GetString(SI_HOUSE_TOURS_RECOMMENDED),
            },
            keybindStripDescriptor = self.searchKeybindStripDescriptor,
            refreshFunction = function() self:RefreshSearchResultsList() end,
            selectionChangedFunction = function(list, selectedData, oldSelectedData)
                self:SetupOptions(selectedData)
            end,
            listingPanelContents = self.listingPanelControl:GetNamedChild("SearchInfo"),
            hasListingPanel = true,
            listingType = HOUSE_TOURS_LISTING_TYPE_RECOMMENDED,
            hasTagsFilter = true,
        },
        [HOUSE_TOURS_MODES.BROWSE] =
        {
            list = self.searchResultsList,
            headerData =
            {
                titleText = GetString(SI_HOUSE_TOURS_BROWSE_HOMES),
            },
            keybindStripDescriptor = self.searchKeybindStripDescriptor,
            refreshFunction = function() self:RefreshSearchResultsList() end,
            selectionChangedFunction = function(list, selectedData, oldSelectedData)
                self:SetupOptions(selectedData)
            end,
            listingPanelContents = self.listingPanelControl:GetNamedChild("SearchInfo"),
            hasListingPanel = true,
            listingType = HOUSE_TOURS_LISTING_TYPE_BROWSE,
            hasTagsFilter = true,
        },
        [HOUSE_TOURS_MODES.FAVORITES] =
        {
            list = self.searchResultsList,
            headerData =
            {
                titleText = GetString(SI_HOUSE_TOURS_FAVORITE_HOMES),
            },
            keybindStripDescriptor = self.searchKeybindStripDescriptor,
            refreshFunction = function() self:RefreshSearchResultsList() end,
            selectionChangedFunction = function(list, selectedData, oldSelectedData)
                self:SetupOptions(selectedData)
            end,
            listingPanelContents = self.listingPanelControl:GetNamedChild("SearchInfo"),
            hasListingPanel = true,
            listingType = HOUSE_TOURS_LISTING_TYPE_FAVORITE,
            hasTagsFilter = true,
        },
        [HOUSE_TOURS_MODES.MANAGE_LISTINGS] =
        {
            list = self.listingsManagementList,
            headerData =
            {
                titleText = GetString(SI_HOUSE_TOURS_MANAGE_LISTINGS),
            },
            keybindStripDescriptor = self.manageListingsKeybindStripDescriptor,
            refreshFunction = function() self:RefreshListingsManagementList() end,
            listingPanelContents = self.listingPanelControl:GetNamedChild("ListingManagementInfo"),
            hasListingPanel = function()
                --Only show the listing panel when the player owns houses
                return self.hasHouses
            end,
            tooltipFunction = function()
                local selectedData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedPlayerListingCollectibleId)
                if selectedData and not selectedData:HasValidPermissions() then
                    GAMEPAD_TOOLTIPS:LayoutTitleAndDescriptionTooltip(GAMEPAD_RIGHT_TOOLTIP, GetString(SI_HOUSE_TOURS_MANAGE_LISTING_GAMEPAD_LOCKED_TOOLTIP_HEADER), selectedData:GetLockReasonText())
                end
            end,
        },
        [HOUSE_TOURS_MODES.SELECT_HOME] =
        {
            list = self.homeList,
            headerData =
            {
                titleText = GetString(SI_HOUSE_TOURS_MANAGE_LISTING_HOUSE_SELECT_HOME),
            },
            keybindStripDescriptor = self.selectHomeKeybindStripDescriptor,
            refreshFunction = function() self:RefreshHomeList() end,
            listingPanelContents = self.listingPanelControl:GetNamedChild("ListingManagementInfo"),
            hasListingPanel = true,
        },
    }
end

function ZO_HouseTours_Gamepad:SetupManageListingsList(list)
    local function EntryWithArrowSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

        local color = data:GetNameColor(selected)
        if type(color) == "function" then
            color = color(data)
        end
        control:GetNamedChild("Arrow"):SetColor(color:UnpackRGBA())
    end

    local function OnDropdownDeactivated()
        --Re-narrate the selected entry when the dropdown is closed
        SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.listingsManagementList)
    end

    --Logic shared between both dropdown entries
    local function SharedDropdownEntrySetup(dropdown, selected)
        dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
        dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
        dropdown:SetSelectedItemTextColor(selected)
        dropdown:SetDeactivatedCallback(OnDropdownDeactivated)
    end

    local function OnVisitorAccessPresetSelected(dropdown, entryText, entry)
        local selectedData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedPlayerListingCollectibleId)
        if selectedData then
            local changePermissionData =
            {
                houseId = selectedData:GetHouseId(),
                housePermissionDefaultAccessSetting = entry.defaultAccess,
                failureCallback = function()
                    self:RefreshListingsManagementList(PRESERVE_SELECTIONS)
                    self:RefreshKeybinds()
                    self:RefreshTooltips()
                end,
                successCallback = function()
                    self:RefreshKeybinds()
                    self:RefreshTooltips()
                end,
            }
            ZO_Dialogs_ShowPlatformDialog("CONFIRM_CHANGE_DEFAULT_HOUSING_PERMISSION", changePermissionData)
        end
    end

    local function DefaultVisitorAccessDropdownEntrySetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        local dropdown = control.dropdown
        SharedDropdownEntrySetup(dropdown, selected)

        dropdown:SetSortsItems(false)

        dropdown:ClearItems()
        local allDefaultAccessSettings = HOUSE_SETTINGS_MANAGER:GetAllDefaultAccessSettings()
        for i = HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_ITERATION_BEGIN, HOUSE_PERMISSION_DEFAULT_ACCESS_SETTING_ITERATION_END do
            local entry = dropdown:CreateItemEntry(allDefaultAccessSettings[i], OnVisitorAccessPresetSelected)
            entry.defaultAccess = i
            if not IsHouseDefaultAccessSettingValidForHouseToursListing(i) then
                entry.name = ZO_ERROR_COLOR:Colorize(entry.name)
            end
            dropdown:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
        end

        local selectedListingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedPlayerListingCollectibleId)
        local function ShouldAutoSelectEntry(entry)
            local defaultAccess = HOUSE_SETTINGS_MANAGER:GetDefaultHousingPermission(selectedListingData:GetHouseId())
            return entry.defaultAccess == defaultAccess
        end

        --Attempt to select the currently chosen permission for the house. If we fail to select the matching entry, just default to the first one
        if not dropdown:SetSelectedItemByEval(ShouldAutoSelectEntry, SUPPRESS_CALLBACKS) then
            dropdown:SelectFirstItem(SUPPRESS_CALLBACKS)
        end
    end

    self.tagsDropdownEntries = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
    for i = HOUSE_TOURS_LISTING_TAG_ITERATION_BEGIN, HOUSE_TOURS_LISTING_TAG_ITERATION_END do
        local tagEntry = ZO_ComboBox_Base:CreateItemEntry(GetString("SI_HOUSETOURLISTINGTAG", i))
        tagEntry.tagValue = i
        self.tagsDropdownEntries:AddItem(tagEntry)
    end

    local function TagsDropdownEntrySetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        local dropdown = control.dropdown
        SharedDropdownEntrySetup(dropdown, selected)

        dropdown:SetMaxSelections(MAX_HOUSE_TOURS_LISTING_TAGS)
        dropdown:SetNoSelectionText(GetString(SI_HOUSE_TOURS_TAGS_DROPDOWN_NO_SELECTION_TEXT))
        dropdown:SetMultiSelectionTextFormatter(SI_HOUSE_TOURS_TAGS_DROPDOWN_TEXT_FORMATTER)
        dropdown:LoadData(self.tagsDropdownEntries)
    end

    list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplateWithArrow", EntryWithArrowSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate", nil, "ArrowEntry")
    list:AddDataTemplateWithHeader("ZO_Gamepad_Dropdown_Item_Indented", DefaultVisitorAccessDropdownEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate", nil, "DefaultAccessEntry")
    list:AddDataTemplateWithHeader("ZO_Gamepad_MultiSelection_Dropdown_Item_Indented", TagsDropdownEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate", nil, "TagsEntry")

    --The only time this list can be empty is when the player has no houses
    local housingQuestId = GetHousingStarterQuestId()
    local formattedHousingQuestText = zo_strformat(SI_HOUSE_TOURS_MANAGE_LISTING_NO_HOUSES_STARTER_QUEST, ZO_SELECTED_TEXT:Colorize(GetQuestName(housingQuestId)))
    list:SetNoItemText(ZO_GenerateParagraphSeparatedList({ GetString(SI_HOUSE_TOURS_MANAGE_LISTING_NO_HOUSES), formattedHousingQuestText }))
end

function ZO_HouseTours_Gamepad:InitializeLists()
    local function SetupHomeList(list)
        list:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    end

    local function SetupSearchResultsList(list)
        list:AddDataTemplate("ZO_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, ZO_HouseToursListingSearchData.Equals)
    end

    self.categoryList = self:GetMainList()
    self.searchResultsList = self:AddList("SearchResults", SetupSearchResultsList)
    self.listingsManagementList = self:AddList("ManageListings", function(list) self:SetupManageListingsList(list) end)
    self.homeList = self:AddList("Homes", SetupHomeList)
end

function ZO_HouseTours_Gamepad:RegisterDialogs()
    ZO_Dialogs_RegisterCustomDialog("HOUSE_TOURS_SUBMIT_LISTING_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_HOUSE_TOURS_SUBMIT_HOME,
        },
        mainText =
        {
            text = SI_HOUSE_TOURS_GAMEPAD_SUBMIT_DIALOG_TEXT,
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    local data = dialog.data
                    if data and data.selectedListingData and data.tags then
                        local houseId = data.selectedListingData:GetHouseId()
                        RequestCreateHouseToursListing(houseId, unpack(data.tags))
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        },
    })

    local function OnReleaseDialog(dialog)
        --Make sure we deactivate any open dropdowns when the dialog closes
        local targetControl = dialog.entryList:GetTargetControl()
        if targetControl and targetControl.dropdown then
            targetControl.dropdown:Deactivate()
        end
    end

    local function RefreshFiltersTooltip(dialog, list, data)
        local tooltipText
        if data and data.tooltipText then
            tooltipText = data.tooltipText(dialog)
        end

        if tooltipText then
            GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP, tooltipText)
            ZO_GenericGamepadDialog_ShowTooltip(dialog)
        else
            ZO_GenericGamepadDialog_HideTooltip(dialog)
        end
    end

    ZO_Dialogs_RegisterCustomDialog("HOUSE_TOURS_ALL_FILTERS_GAMEPAD",
    {
        blockDialogReleaseOnPress = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
            allowRightStickPassThrough = true,
        },
        title =
        {
            text = SI_HOUSE_TOURS_ALL_FILTERS,
        },
        setup = function(dialog, data)
            dialog.filterData = data.filterData
            dialog.pendingFilterData = ZO_HouseTours_Search_Filters:New(dialog.filterData:GetListingType())
            dialog.pendingFilterData:CopyFrom(dialog.filterData)
            dialog:setupFunc()
        end,
        parametricList =
        {
            -- User Id
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",
                templateData =
                {
                    focusLostCallback = function(control)
                        local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
                        dialog.pendingFilterData:SetDisplayName(control:GetText())
                    end,
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local dialog = data.dialog
                        control.highlight:SetHidden(not selected)
                        control.editBoxControl:SetDefaultText(ZO_GetPlatformAccountLabel())
                        control.editBoxControl:SetText(dialog.pendingFilterData:GetDisplayName())
                        control.editBoxControl:SetMaxInputChars(DECORATED_DISPLAY_NAME_MAX_LENGTH)
                        control.editBoxControl.focusLostCallback = data.focusLostCallback
                        data.control = control
                    end,
                    callback = function(dialog)
                        local targetData = dialog.entryList:GetTargetData()
                        if targetData then
                            local editControl = targetData.control.editBoxControl
                            editControl:TakeFocus()
                        end
                    end,
                    narrationText = ZO_GetDefaultParametricListEditBoxNarrationText
                }
            },
            -- Tags
            {
                template = "ZO_GamepadMultiSelectionDropdownItem",
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local dialog = data.dialog
                        local dropdown = control.dropdown

                        dropdown:SetSortsItems(true)
                        dropdown:SetMaxSelections(MAX_HOUSE_TOURS_LISTING_TAGS)
                        dropdown:SetNoSelectionText(GetString(SI_HOUSE_TOURS_FILTERS_TAGS_DROPDOWN_NO_SELECTION_TEXT))
                        dropdown:SetMultiSelectionTextFormatter(SI_HOUSE_TOURS_TAGS_DROPDOWN_TEXT_FORMATTER)
                        dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                        dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                        dropdown:SetSelectedItemTextColor(selected)

                        dropdown.dropdownData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
                        local function TagSelectionChanged()
                            local newTags = {}
                            local selectedTagsData = dropdown.dropdownData:GetSelectedItems()
                            for _, item in ipairs(selectedTagsData) do
                                table.insert(newTags, item.tagValue)
                            end

                            dialog.pendingFilterData:SetTags(newTags)
                        end

                        local tags = dialog.pendingFilterData:GetTags()
                        for i = HOUSE_TOURS_LISTING_TAG_ITERATION_BEGIN, HOUSE_TOURS_LISTING_TAG_ITERATION_END do
                            local tagEntry = ZO_ComboBox_Base:CreateItemEntry(GetString("SI_HOUSETOURLISTINGTAG", i), TagSelectionChanged)
                            tagEntry.tagValue = i
                            dropdown.dropdownData:AddItem(tagEntry)
                            if ZO_IsElementInNumericallyIndexedTable(tags, tagEntry.tagValue) then
                                dropdown.dropdownData:SetItemSelected(tagEntry, true)
                            end
                        end
                        dropdown:LoadData(dropdown.dropdownData)

                        SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, dropdown)
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        if targetControl then
                            targetControl.dropdown:Activate()
                        end
                    end,
                    narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
                },
            },
            -- House Name
            {
                template = "ZO_GamepadMultiSelectionDropdownItem",
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local dialog = data.dialog
                        local dropdown = control.dropdown

                        dropdown:SetSortsItems(true)
                        dropdown:SetMaxSelections(MAX_HOUSE_TOURS_HOUSE_FILTERS)
                        dropdown:SetNoSelectionText(GetString(SI_HOUSE_TOURS_FILTERS_HOUSE_DROPDOWN_NO_SELECTION_TEXT))
                        dropdown:SetMultiSelectionTextFormatter(SI_HOUSE_TOURS_FILTERS_HOUSE_DROPDOWN_TEXT_FORMATTER)
                        dropdown:SetNormalColor(ZO_GAMEPAD_COMPONENT_COLORS.UNSELECTED_INACTIVE:UnpackRGB())
                        dropdown:SetHighlightedColor(ZO_GAMEPAD_COMPONENT_COLORS.SELECTED_ACTIVE:UnpackRGB())
                        dropdown:SetSelectedItemTextColor(selected)

                        dropdown.dropdownData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
                        local function HouseSelectionChanged()
                            local newHouseIds = {}
                            local selectedHouseData = dropdown.dropdownData:GetSelectedItems()
                            for _, item in ipairs(selectedHouseData) do
                                table.insert(newHouseIds, item.houseId)
                            end

                            dialog.pendingFilterData:SetHouseIds(newHouseIds)

                            --Changes to the house name selection can impact the house category dropdown, so refresh that too when the house selection changes
                            if dialog.houseCategoryDropdown then
                                --Update the colors of the house category dropdown depending on whether or not it is now disabled
                                local canSet = dialog.pendingFilterData:CanSetHouseCategoryTypes()
                                local normalColor = canSet and ZO_GAMEPAD_UNSELECTED_COLOR or ZO_GAMEPAD_DISABLED_UNSELECTED_COLOR
                                local highlightColor = canSet and ZO_GAMEPAD_SELECTED_COLOR or ZO_GAMEPAD_DISABLED_SELECTED_COLOR
                                dialog.houseCategoryDropdown:SetNormalColor(normalColor:UnpackRGB())
                                dialog.houseCategoryDropdown:SetHighlightedColor(highlightColor:UnpackRGB())

                                --It can be assumed that the house category dropdown is not selected, since in order to change the house selection, the house name dropdown needs to be selected
                                local NOT_SELECTED = false
                                dialog.houseCategoryDropdown:SetSelectedItemTextColor(NOT_SELECTED)

                                --If the house category dropdown is now supposed to be disabled, clear all of its selections
                                if not canSet then
                                    dialog.houseCategoryDropdown:ClearAllSelections()
                                    dialog.houseCategoryDropdown:RefreshSelections()
                                end
                            end
                        end

                        local allHouses = ZO_COLLECTIBLE_DATA_MANAGER:GetAllCollectibleDataObjects({ ZO_CollectibleCategoryData.IsHousingCategory })
                        local houseIds = dialog.pendingFilterData:GetHouseIds()
                        for _, collectibleData in ipairs(allHouses) do
                            local houseEntry = ZO_ComboBox_Base:CreateItemEntry(collectibleData:GetFormattedName(), HouseSelectionChanged)
                            houseEntry.houseId = collectibleData:GetReferenceId()
                            dropdown.dropdownData:AddItem(houseEntry)
                            if ZO_IsElementInNumericallyIndexedTable(houseIds, houseEntry.houseId) then
                                dropdown.dropdownData:SetItemSelected(houseEntry, true)
                            end
                        end

                        dropdown:LoadData(dropdown.dropdownData)
                        SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, dropdown)
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        if targetControl then
                            targetControl.dropdown:Activate()
                        end
                    end,
                    narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
                },
            },
            -- House Category
            {
                template = "ZO_GamepadMultiSelectionDropdownItem",
                templateData =
                {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local dialog = data.dialog
                        local dropdown = control.dropdown
                        dialog.houseCategoryDropdown = dropdown

                        dropdown:SetSortsItems(true)
                        dropdown:SetMaxSelections(MAX_HOUSE_TOURS_CATEGORY_TYPE_FILTERS)
                        dropdown:SetNoSelectionText(GetString(SI_HOUSE_TOURS_FILTERS_HOUSE_CATEGORY_DROPDOWN_NO_SELECTION_TEXT))
                        dropdown:SetMultiSelectionTextFormatter(SI_HOUSE_TOURS_FILTERS_HOUSE_CATEGORY_DROPDOWN_TEXT_FORMATTER)

                        local canSet = dialog.pendingFilterData:CanSetHouseCategoryTypes()
                        local normalColor = canSet and ZO_GAMEPAD_UNSELECTED_COLOR or ZO_GAMEPAD_DISABLED_UNSELECTED_COLOR
                        local highlightColor = canSet and ZO_GAMEPAD_SELECTED_COLOR or ZO_GAMEPAD_DISABLED_SELECTED_COLOR
                        dropdown:SetNormalColor(normalColor:UnpackRGB())
                        dropdown:SetHighlightedColor(highlightColor:UnpackRGB())
                        dropdown:SetSelectedItemTextColor(selected)

                        dropdown.dropdownData = ZO_MultiSelection_ComboBox_Data_Gamepad:New()
                        local function CategorySelectionChanged()
                            local newCategories = {}
                            local selectedHouseCategoryData = dropdown.dropdownData:GetSelectedItems()
                            for _, item in ipairs(selectedHouseCategoryData) do
                                table.insert(newCategories, item.categoryValue)
                            end
                            dialog.pendingFilterData:SetHouseCategoryTypes(newCategories)
                        end

                        local categories = dialog.pendingFilterData:GetHouseCategoryTypes()
                        for i = HOUSE_CATEGORY_TYPE_ITERATION_BEGIN, HOUSE_CATEGORY_TYPE_ITERATION_END do
                            local categoryEntry = ZO_ComboBox_Base:CreateItemEntry(GetString("SI_HOUSECATEGORYTYPE", i), CategorySelectionChanged)
                            categoryEntry.categoryValue = i
                            dropdown.dropdownData:AddItem(categoryEntry)
                            if ZO_IsElementInNumericallyIndexedTable(categories, categoryEntry.categoryValue) then
                                dropdown.dropdownData:SetItemSelected(categoryEntry, true)
                            end
                        end
                        dropdown:LoadData(dropdown.dropdownData)
                        SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(dialog, dropdown)
                    end,
                    callback = function(dialog)
                        local targetControl = dialog.entryList:GetTargetControl()
                        if targetControl then
                            targetControl.dropdown:Activate()
                        end
                    end,
                    enabled = function(dialog)
                        return dialog.pendingFilterData:CanSetHouseCategoryTypes()
                    end,
                    tooltipText = function(dialog)
                        local pendingFilterData = dialog.pendingFilterData
                        if not pendingFilterData:CanSetHouseCategoryTypes() then
                            return GetString(SI_HOUSE_TOURS_FILTERS_HOUSE_CATEGORY_DISABLED)
                        end
                    end,
                    narrationText = ZO_GetDefaultParametricListDropdownNarrationText,
                    narrationTooltip = GAMEPAD_LEFT_DIALOG_TOOLTIP,
                },
            },
        },
        parametricListOnSelectionChangedCallback = function(dialog, list, newSelectedData, oldSelectedData)
            RefreshFiltersTooltip(dialog, list, newSelectedData)
        end,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData and targetData.callback then
                        targetData.callback(dialog)
                    end
                end,
                enabled = function(dialog)
                    local enabled = true
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData then
                        if type(targetData.enabled) == "function" then
                            enabled = targetData.enabled(dialog)
                        else
                            enabled = targetData.enabled
                        end
                    end
                    return enabled
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("HOUSE_TOURS_ALL_FILTERS_GAMEPAD")
                end,
            },
            {
                keybind = "DIALOG_SECONDARY",
                text = SI_DIALOG_CONFIRM,
                callback = function(dialog)
                    dialog.filterData:CopyFrom(dialog.pendingFilterData)
                    if dialog.data.confirmCallback then
                        dialog.data:confirmCallback()
                    end
                    ZO_Dialogs_ReleaseDialogOnButtonPress("HOUSE_TOURS_ALL_FILTERS_GAMEPAD")
                end,
            },
            {
                keybind = "DIALOG_RESET",
                text = SI_HOUSE_TOURS_RESET_FILTERS_KEYBIND,
                callback = function(dialog)
                    dialog.pendingFilterData:ResetFilters()
                    ZO_GenericParametricListGamepadDialogTemplate_RefreshVisibleEntries(dialog)
                    ZO_GenericGamepadDialog_RefreshKeybinds(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    if targetData then
                        RefreshFiltersTooltip(dialog, dialog.entryList, targetData)
                    end
                    --Re-narrate the selection when the filters are reset
                    SCREEN_NARRATION_MANAGER:QueueDialog(dialog)
                end,
            },
        },
        onHidingCallback = OnReleaseDialog,
        noChoiceCallback = OnReleaseDialog,
    })
end

function ZO_HouseTours_Gamepad:RegisterForEvents()
    HOUSE_TOURS_SEARCH_MANAGER:RegisterCallback("OnSearchStateChanged", function(newState, listingType)
        if self:IsShowing() then
            local modeData = self:GetDataForMode(self.mode)
            if modeData and modeData.listingType == listingType then
                self:RefreshList()
                local currentList = self:GetCurrentList()
                self:RefreshListingPanel(currentList, currentList:GetSelectedData())
                local NARRATE_HEADER = true
                if self:IsHeaderActive() then
                    SCREEN_NARRATION_MANAGER:QueueCustomEntry("houseToursTagsFilter", NARRATE_HEADER)
                else
                    SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self:GetCurrentList(), NARRATE_HEADER)
                end
            end
        end
    end)

    HOUSE_TOURS_SEARCH_MANAGER:RegisterCallback("OnFavoritesChanged", function()
        if self:IsShowing() and
            (self.mode == HOUSE_TOURS_MODES.BROWSE or
             self.mode == HOUSE_TOURS_MODES.FAVORITES or
             self.mode == HOUSE_TOURS_MODES.RECOMMENDED) then
            local modeData = self:GetDataForMode(self.mode)
            if modeData and modeData.listingType then
                -- Refresh the current list.
                HOUSE_TOURS_SEARCH_MANAGER:ExecuteSearch(modeData.listingType)
            end
        end
    end)

    HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:RegisterCallback("ListingOperationCooldownStateChanged", ZO_GetCallbackForwardingFunction(self, self.SetIsListingOperationOnCooldown))

    HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:RegisterCallback("ListingOperationCompleted", function(operationType, houseId, result)
        if self:IsShowing() and self.mode == HOUSE_TOURS_MODES.MANAGE_LISTINGS then
            local listingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedPlayerListingCollectibleId)
            if listingData and listingData:GetHouseId() == houseId then
                self:RefreshList()
                self:RefreshListingPanel(self:GetCurrentList(), listingData)
            end
        end
    end)

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", function() self:RefreshNickname() end)

    local function OnQuestsUpdated()
        if self:IsShowing() then
            self:RefreshKeybinds()
        end
    end

    EVENT_MANAGER:RegisterForEvent("HouseTours_Gamepad", EVENT_QUEST_ADDED, OnQuestsUpdated)
    EVENT_MANAGER:RegisterForEvent("HouseTours_Gamepad", EVENT_QUEST_REMOVED, OnQuestsUpdated)

    local function OnPendingPermissionsChangesUpdated()
        if self:IsShowing() then
            self:RefreshKeybinds()
        end
    end

    EVENT_MANAGER:RegisterForEvent("HouseTours_Gamepad", EVENT_HOUSING_PERMISSIONS_SAVE_PENDING, OnPendingPermissionsChangesUpdated)
    EVENT_MANAGER:RegisterForEvent("HouseTours_Gamepad", EVENT_HOUSING_PERMISSIONS_SAVE_COMPLETE, OnPendingPermissionsChangesUpdated)
end

--Overridden from base
function ZO_HouseTours_Gamepad:InitializeKeybindStripDescriptors()
    self.overviewKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                local categoryData = self.categoryList:GetTargetData()
                if categoryData then
                    self:SetMode(categoryData.mode)
                end
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
    }

    local function OnConfirmFilters()
        if self:IsShowing() then
            self:RefreshTagsFilterDropdown()
            local modeData = self:GetDataForMode(self.mode)
            --Execute a new search when the filters change
            if modeData and modeData.listingType then
                HOUSE_TOURS_SEARCH_MANAGER:ExecuteSearch(modeData.listingType)
            end
        end
    end

    self.searchKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select / Visit Home
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                if self:IsHeaderActive() then
                    return GetString(SI_GAMEPAD_SELECT_OPTION)
                else
                    return GetString(SI_HOUSE_TOURS_VISIT_HOME)
                end
            end,
            callback = function()
                if self:IsHeaderActive() then
                    self.tagsFilterDropdown:Activate()
                else
                    local targetData = self.searchResultsList:GetTargetData()
                    if targetData then
                        local FROM_HOUSE_TOURS = true
                        HOUSING_SOCIAL_MANAGER:VisitHouse(targetData:GetHouseId(), targetData:GetOwnerDisplayName(), FROM_HOUSE_TOURS)
                    end
                end
            end,
            enabled = function()
                --Dont allow use of the header dropdown if a search is in progress
                if self:IsHeaderActive() then
                    local modeData = self:GetDataForMode(self.mode)
                    local currentSearchState = HOUSE_TOURS_SEARCH_MANAGER:GetSearchState(modeData.listingType)
                    return currentSearchState == ZO_HOUSE_TOURS_SEARCH_STATES.COMPLETE
                end
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- All Filters
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_HOUSE_TOURS_ALL_FILTERS),
            callback = function()
                local modeData = self:GetDataForMode(self.mode)
                ZO_Dialogs_ShowPlatformDialog("HOUSE_TOURS_ALL_FILTERS_GAMEPAD", { filterData = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(modeData.listingType), confirmCallback = OnConfirmFilters })
            end,
        },
        -- Add/Remove Favorite Home
        {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = function()
                local targetData = self.searchResultsList:GetTargetData()
                if targetData then
                    if targetData:IsFavorite() then
                        return zo_strformat(SI_HOUSE_TOURS_REMOVE_FAVORITE_LISTING, GetNumFavoriteHouses(), MAX_HOUSE_TOURS_LISTING_FAVORITES)
                    else
                        return zo_strformat(SI_HOUSE_TOURS_ADD_FAVORITE_LISTING, GetNumFavoriteHouses(), MAX_HOUSE_TOURS_LISTING_FAVORITES)
                    end
                end
            end,
            callback = function()
                local targetData = self.searchResultsList:GetTargetData()
                if targetData then
                    if targetData:IsFavorite() then
                        targetData:RequestRemoveFavorite()
                    else
                        targetData:RequestAddFavorite()
                    end
                end
            end,
            visible = function()
                if self:IsHeaderActive() or self.searchResultsList:IsEmpty() then
                    return false
                end

                local targetData = self.searchResultsList:GetTargetData()
                if not targetData then
                    return false
                end

                if not targetData:CanFavorite() then
                    return false
                end

                local modeData = self:GetDataForMode(self.mode)
                local currentSearchState = HOUSE_TOURS_SEARCH_MANAGER:GetSearchState(modeData.listingType)
                return currentSearchState == ZO_HOUSE_TOURS_SEARCH_STATES.COMPLETE
            end,
        },
        -- Options
        {
            keybind = "UI_SHORTCUT_QUATERNARY",
            name = GetString(SI_GAMEPAD_OPTIONS_MENU),
            visible = function()
                if self:IsHeaderActive() or self.searchResultsList:IsEmpty() then
                    return false
                end

                local targetData = self.searchResultsList:GetTargetData()
                return targetData ~= nil
            end,
            callback = function()
                self:ShowOptionsDialog()
            end,
        },
        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
            self:SetMode(HOUSE_TOURS_MODES.OVERVIEW)
        end, nil, SOUNDS.GAMEPAD_MENU_BACK)
    }

    self.manageListingsKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = function()
                if not self.hasHouses then
                    return GetString(SI_COLLECTIBLE_ACTION_ACCEPT_QUEST)
                end
                local targetData = self.listingsManagementList:GetTargetData()
                if targetData and targetData.selectName then
                    return targetData.selectName
                end
                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,
            callback = function()
                if self.hasHouses then
                    local targetData = self.listingsManagementList:GetTargetData()
                    if targetData.selectCallback ~= nil then
                        local targetControl = self.listingsManagementList:GetTargetControl()
                        targetData.selectCallback(targetData, targetControl, self.selectedPlayerListingCollectibleId)
                    end
                else
                    RequestBestowHousingStarterQuest()
                end
            end,
            enabled = function()
                if self.isListingOperationOnCooldown then
                    return false, GetString("SI_HOUSETOURLISTINGRESULT", HOUSE_TOURS_LISTING_RESULT_COOLDOWN_NOT_READY)
                end

                if self.hasHouses and AreHousingPermissionsChangesPending() then
                    return false, GetString(SI_HOUSE_TOURS_MANAGE_LISTINGS_GAMEPAD_PERMISSIONS_CHANGE_PENDING)
                end

                return true
            end,
            visible = function()
                if self.hasHouses then
                    return true
                else
                    local questId = GetHousingStarterQuestId()
                    return not HasQuest(questId)
                end
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Submit/Edit
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            keybind = "UI_SHORTCUT_SECONDARY",
            name = function()
                local selectedData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedPlayerListingCollectibleId)
                if selectedData then
                    local isListed = selectedData:IsListed()
                    return isListed and GetString(SI_HOUSE_TOURS_EDIT_LISTING) or GetString(SI_HOUSE_TOURS_SUBMIT_HOME)
                end
                return GetString(SI_HOUSE_TOURS_SUBMIT_HOME)
            end,
            callback = function()
                local selectedData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedPlayerListingCollectibleId)
                if selectedData then
                    local tags = {}
                    local selectedTagsData = self.tagsDropdownEntries:GetSelectedItems()
                    for _, item in ipairs(selectedTagsData) do
                        table.insert(tags, item.tagValue)
                    end

                    if selectedData:IsListed() then
                        RequestUpdateHouseToursListing(selectedData:GetHouseId(), unpack(tags))
                    else
                        ZO_Dialogs_ShowGamepadDialog("HOUSE_TOURS_SUBMIT_LISTING_GAMEPAD", { selectedListingData = selectedData, tags = tags })
                    end
                end
            end,
            visible = function()
                return self.hasHouses
            end,
            enabled = function()
                if self.isListingOperationOnCooldown then
                    return false, GetString("SI_HOUSETOURLISTINGRESULT", HOUSE_TOURS_LISTING_RESULT_COOLDOWN_NOT_READY)
                end

                if AreHousingPermissionsChangesPending() then
                    return false, GetString(SI_HOUSE_TOURS_MANAGE_LISTINGS_GAMEPAD_PERMISSIONS_CHANGE_PENDING)
                end

                local selectedData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedPlayerListingCollectibleId)
                if selectedData then
                    if selectedData:IsListed() then
                        --Grab a copy of the currently saved tags
                        local currentTags = {}
                        ZO_ShallowNumericallyIndexedTableCopy(selectedData:GetTags(), currentTags)

                        --Grab the currently selected tags in the UI
                        local newTags = {}
                        local selectedTagsData = self.tagsDropdownEntries:GetSelectedItems()
                        for _, item in ipairs(selectedTagsData) do
                            table.insert(newTags, item.tagValue)
                        end

                        --Sort both the current and new tags to make sure they are in the same order when we compare them
                        table.sort(newTags)
                        table.sort(currentTags)

                        return not ZO_AreNumericallyIndexedTablesEqual(currentTags, newTags)
                    else
                        return selectedData:HasValidPermissions(), selectedData:GetLockReasonText()
                    end
                end
                return false
            end,
        },
        -- Remove Listing
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            keybind = "UI_SHORTCUT_TERTIARY",
            name = GetString(SI_HOUSE_TOURS_REMOVE_LISTING),
            callback = function()
                local selectedData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedPlayerListingCollectibleId)
                if selectedData then
                    RequestDeleteHouseToursListing(selectedData:GetHouseId())
                end
            end,
            enabled = function()
                if self.isListingOperationOnCooldown then
                    return false, GetString("SI_HOUSETOURLISTINGRESULT", HOUSE_TOURS_LISTING_RESULT_COOLDOWN_NOT_READY)
                end

                if AreHousingPermissionsChangesPending() then
                    return false, GetString(SI_HOUSE_TOURS_MANAGE_LISTINGS_GAMEPAD_PERMISSIONS_CHANGE_PENDING)
                end
                
                return true
            end,
            visible = function()
                local selectedData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedPlayerListingCollectibleId)
                if selectedData then
                    return selectedData:IsListed()
                end
                return false
            end,
        },
        -- Travel to home
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,
            keybind = "UI_SHORTCUT_QUATERNARY",
            name = GetString(SI_HOUSE_TOURS_MANAGE_LISTING_TRAVEL_TO_HOUSE),
            callback = function()
                local selectedData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedPlayerListingCollectibleId)
                if selectedData then
                    HOUSING_SOCIAL_MANAGER:VisitHouse(selectedData:GetHouseId())
                end
            end,
            visible = function()
                return self.hasHouses
            end,
        },
        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
            self:SetMode(HOUSE_TOURS_MODES.OVERVIEW)
        end, nil, SOUNDS.GAMEPAD_MENU_BACK)
    }

    self.selectHomeKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Select
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                local entryData = self.homeList:GetSelectedData()
                if entryData then
                    self.selectedPlayerListingCollectibleId = entryData:GetCollectibleId()
                    self:SetMode(HOUSE_TOURS_MODES.MANAGE_LISTINGS)
                end
            end,
            enabled = function()
                if self.isListingOperationOnCooldown then
                    return false, GetString("SI_HOUSETOURLISTINGRESULT", HOUSE_TOURS_LISTING_RESULT_COOLDOWN_NOT_READY)
                end

                return true
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
            self:SetMode(HOUSE_TOURS_MODES.MANAGE_LISTINGS)
        end, nil, SOUNDS.GAMEPAD_MENU_BACK)
    }

    self:SetListsUseTriggerKeybinds(true)
end

--Overridden from base
function ZO_HouseTours_Gamepad:OnDeferredInitialize()
    --Order matters
    --The lists must be initialized before initializing mode data, and mode data must be initialized before refreshing the header
    self:InitializeLists()
    self:InitializeModeData()
    self:RegisterDialogs()
    self:RegisterForEvents()
    self:RefreshHeader()
end

--Overridden from base
function ZO_HouseTours_Gamepad:PerformUpdate()
   self.dirty = false
end

--Overridden from base
function ZO_HouseTours_Gamepad:RefreshKeybinds()
    local modeData = self:GetDataForMode(self.mode)
    if modeData and modeData.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(modeData.keybindStripDescriptor)
    end
end

--Overridden from base
function ZO_HouseTours_Gamepad:OnShow()
    ZO_Gamepad_ParametricList_Screen.OnShow(self)

    TriggerTutorial(TUTORIAL_TRIGGER_HOUSE_TOURS_OPENED)
end

--Overridden from base
function ZO_HouseTours_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)
    self:SetMode(HOUSE_TOURS_MODES.OVERVIEW)

    --Calculate if the player has any houses
    local sortedListingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetSortedListingData()
    self.hasHouses = #sortedListingData > 0

    if self.manageSpecificHouseId then
        -- Queued house id for the Manage Listings UI.
        self.selectedPlayerListingCollectibleId = GetCollectibleIdForHouse(self.manageSpecificHouseId)
        self.manageSpecificHouseId = nil
        self:SetMode(HOUSE_TOURS_MODES.MANAGE_LISTINGS)
    elseif self.pendingBrowseHouseId then
        -- Queued house id for the Browse UI.
        self:BrowseSpecificHouse(self.pendingBrowseHouseId)
        self.pendingBrowseHouseId = nil
    elseif self.hasHouses then
        if IsOwnerOfCurrentHouse() then
            -- Automatically select the current house if the player is in one of their own homes.
            self.selectedPlayerListingCollectibleId = GetCollectibleIdForHouse(GetCurrentZoneHouseId())
        elseif not self.selectedPlayerListingCollectibleId then
            --If we have houses but haven't set the selected player listing for the management screen, do that now
            --Default to the house the player is in, fall back to first thing in the list
            self.selectedPlayerListingCollectibleId = sortedListingData[1]:GetCollectibleId()
        end
    end
end

--Overridden from base
function ZO_HouseTours_Gamepad:OnHiding()
    ZO_Gamepad_ParametricList_Screen.OnHiding(self)
    local currentList = self:GetCurrentList()
    local targetControl = currentList:GetTargetControl()
    --Make sure dropdowns are deactivated when the screen hides
    if targetControl and targetControl.dropdown then
        targetControl.dropdown:Deactivate()
    end

    self.tagsFilterDropdown:Deactivate()
    self:SetMode(nil)
end

--Overridden from base
function ZO_HouseTours_Gamepad:OnTargetChanged(list, selectedData, oldSelectedData, hasReachedTarget, targetIndex, reselectingDuringRebuild)
    if self.mode ~= HOUSE_TOURS_MODES.MANAGE_LISTINGS then
        if not reselectingDuringRebuild then
            self:UpdateLastSelectedIndexForCurrentMode(targetIndex)
        end

        self:RefreshListingPanel(list, selectedData)
    end
end

--Overridden from base
function ZO_HouseTours_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    ZO_Gamepad_ParametricList_Screen.OnSelectionChanged(self, list, selectedData, oldSelectedData)
    local modeData = self:GetDataForMode(self.mode)
    if modeData and list == modeData.list and modeData.selectionChangedFunction then
        modeData.selectionChangedFunction(list, selectedData, oldSelectedData)
    end
end

--Overridden from base
function ZO_HouseTours_Gamepad:CanEnterHeader()
    return not self.tagsFilterDropdownControl:IsHidden()
end

--Overridden from base
function ZO_HouseTours_Gamepad:OnEnterHeader()
    self:RefreshKeybinds()
end

--Overridden from base
function ZO_HouseTours_Gamepad:OnLeaveHeader()
    self:RefreshKeybinds()
end

--Overridden from base
function ZO_HouseTours_Gamepad:BuildOptionsList()
    local groupId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)
    self:AddOptionTemplate(groupId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, IsConsoleUI)
    local function CanReport()
        return self.socialData.canReport
    end
    self:AddOptionTemplate(groupId, ZO_HouseTours_Gamepad.BuildReportOption, CanReport)
    self:AddOptionTemplate(groupId, ZO_HouseTours_Gamepad.BuildLinkToChatOption, IsChatSystemAvailableForCurrentPlatform)
end

--Overridden from base
function ZO_HouseTours_Gamepad:SetupOptions(entryData)
    if entryData then
        local socialData =
        {
            displayName = entryData:GetOwnerDisplayName(),
            canReport = entryData:CanReport(),
        }
        ZO_SocialOptionsDialogGamepad.SetupOptions(self, socialData)
    end
end

function ZO_HouseTours_Gamepad:GetCategoryData()
    return self.houseToursCategoryData
end

function ZO_HouseTours_Gamepad:BrowseSpecificHouse(houseId)
    if self:IsShowing() then
        local modeData = self:GetDataForMode(HOUSE_TOURS_MODES.BROWSE)
        local filters = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(modeData.listingType)

        --Switch the filters to use the specific house id
        filters:ResetFilters()
        filters:SetHouseIds({houseId})

        --Make sure "Browse Homes" is selected in the category list
        self.categoryList:SetSelectedIndex(2)

        --If we are already in browse, just refresh the filters and manually execute the search, otherwise switch to browse
        if self.mode == HOUSE_TOURS_MODES.BROWSE then
            self:RefreshTagsFilterDropdown()
            HOUSE_TOURS_SEARCH_MANAGER:ExecuteSearch(modeData.listingType)
        else
            self:SetMode(HOUSE_TOURS_MODES.BROWSE)
        end
    else
        self.pendingBrowseHouseId = houseId
    end
end

function ZO_HouseTours_Gamepad:ManageSpecificHouse(houseId)
    if self:IsShowing() then
        -- Order matters:
        local collectibleId = GetCollectibleIdForHouse(houseId)
        self.selectedPlayerListingCollectibleId = collectibleId
        self:SetMode(HOUSE_TOURS_MODES.MANAGE_LISTINGS)
        self:RefreshListingsManagementList(PRESERVE_SELECTIONS)
    else
        -- Order matters:
        self.manageSpecificHouseId = houseId
        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(self:GetCategoryData())
    end
end

function ZO_HouseTours_Gamepad:BuildReportOption()
    local callback = function()
        local targetData = self.searchResultsList:GetTargetData()
        if targetData and targetData:CanReport() then
            ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportHouseTourListingTicketScene(targetData)
        end
    end
    return self:BuildOptionEntry(nil, SI_HOUSE_TOURS_REPORT_LISTING, callback)
end

function ZO_HouseTours_Gamepad:BuildLinkToChatOption()
    local callback = function()
        if IsChatSystemAvailableForCurrentPlatform() then
            local targetData = self.searchResultsList:GetTargetData()
            if targetData then
                local houseId = targetData:GetHouseId()
                local ownerDisplayName = targetData:GetFormattedOwnerDisplayName()
                local link = GetHousingLink(houseId, ownerDisplayName, LINK_STYLE_DEFAULT)
                ZO_LinkHandler_InsertLinkAndSubmit(link)
            end
        end
    end
    return self:BuildOptionEntry(nil, SI_ITEM_ACTION_LINK_TO_CHAT, callback)
end

function ZO_HouseTours_Gamepad:RefreshHeader()
    local modeData = self:GetDataForMode(self.mode)
    if modeData then
        self.headerData = modeData.headerData
        ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    else
        self.headerData = nil
    end
end

do
    local function CreateHouseToursEntryData(text, icon, mode)
        local entryData = ZO_GamepadEntryData:New(text, icon)
        entryData.mode = mode    
    
        entryData.selectedIconTint = ZO_WHITE
        entryData.unselectedIconTint = ZO_GAMEPAD_UNSELECTED_COLOR
    
        return entryData
    end

    function ZO_HouseTours_Gamepad:RefreshCategoryList()
        local list = self.categoryList
        list:Clear()

        list:AddEntry("ZO_GamepadMenuEntryTemplate", CreateHouseToursEntryData(GetString(SI_HOUSE_TOURS_RECOMMENDED), "EsoUI/Art/HouseTours/Gamepad/houseTours_recommended.dds", HOUSE_TOURS_MODES.RECOMMENDED))

        list:AddEntry("ZO_GamepadMenuEntryTemplate", CreateHouseToursEntryData(GetString(SI_HOUSE_TOURS_BROWSE_HOMES), "EsoUI/Art/HouseTours/Gamepad/houseTours_browse.dds", HOUSE_TOURS_MODES.BROWSE))

        list:AddEntry("ZO_GamepadMenuEntryTemplate", CreateHouseToursEntryData(GetString(SI_HOUSE_TOURS_FAVORITE_HOMES), "EsoUI/Art/HouseTours/Gamepad/houseTours_favorites.dds", HOUSE_TOURS_MODES.FAVORITES))

        list:AddEntry("ZO_GamepadMenuEntryTemplate", CreateHouseToursEntryData(GetString(SI_HOUSE_TOURS_MANAGE_LISTINGS), "EsoUI/Art/HouseTours/Gamepad/houseTours_manageListings.dds", HOUSE_TOURS_MODES.MANAGE_LISTINGS))

        list:Commit()
    end
end

do
    local function GetSearchEntryNarrationText(entryData, entryControl)
        local narrations = {}

        --Get the narration for the nickname and house name
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetFormattedNickname()))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetFormattedHouseName()))

        --Get the narration for the furniture count
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSE_TOURS_LISTING_FURNITURE_COUNT_HEADER_NARRATION)))
        local furnitureCount = entryData:GetFurnitureCount()
        --If the furniture count is unknown, narrate that instead of a number
        if furnitureCount ~= nil then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(furnitureCount))
        else
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSE_TOURS_LISTING_FURNITURE_COUNT_UNKNOWN_NARRATION)))
        end

        --Get the narration for the tags
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSE_TOURS_LISTING_TAGS_HEADER)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetFormattedTagsText()))

        --Get the narration for the owner
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSE_TOURS_LISTING_OWNER_HEADER)))

        --If the owner is a friend or in one of our guilds, include that in the narration
        if entryData:IsOwnedByFriend() then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSE_TOURS_LISTING_OWNER_IS_FRIEND_NARRATION)))
        elseif entryData:IsOwnedByGuildMember() then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSE_TOURS_LISTING_OWNER_IS_GUILD_MEMBER_NARRATION)))
        end

        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData:GetFormattedOwnerDisplayName()))

        return narrations
    end

    local function CreateSearchEntry(houseListingData)
        local houseNickname = houseListingData:GetFormattedNickname()
        local houseName = houseListingData:GetFormattedHouseName()
        local icon = houseListingData:GetCollectibleIcon()

        local entryData = ZO_GamepadEntryData:New(houseNickname, icon)
        entryData:AddSubLabel(houseName)
        entryData:SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
        entryData:SetDataSource(houseListingData)
        entryData.narrationText = GetSearchEntryNarrationText
        entryData.isHouseToursFavorite = houseListingData:IsFavorite()

        return entryData
    end

    function ZO_HouseTours_Gamepad:RefreshSearchResultsList(dontLeaveHeader)
        local list = self.searchResultsList
        list:Clear()

        local modeData = self:GetDataForMode(self.mode)
        local searchResults = HOUSE_TOURS_SEARCH_MANAGER:GetSortedSearchResults(modeData.listingType)
        for _, houseListingData in ipairs(searchResults) do
            local entryData = CreateSearchEntry(houseListingData)
            list:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
        end

        list:Commit()

        if modeData.hasTagsFilter then
            --If the list is empty, enter the header instead
            if list:IsEmpty() then
                self:RequestEnterHeader()
            elseif self:IsHeaderActive() and not dontLeaveHeader then
                self:RequestLeaveHeader()
                self.tagsFilterDropdown:Deactivate()
            end
        end

        self:RefreshSearchState()
    end

    function ZO_HouseTours_Gamepad:RefreshSearchState()
        local modeData = self:GetDataForMode(self.mode)
        local currentSearchState = HOUSE_TOURS_SEARCH_MANAGER:GetSearchState(modeData.listingType)
        if currentSearchState == ZO_HOUSE_TOURS_SEARCH_STATES.WAITING or currentSearchState == ZO_HOUSE_TOURS_SEARCH_STATES.QUEUED then
            self.searchResultsList:SetNoItemText(GetString(SI_GROUP_FINDER_SEARCH_RESULTS_REFRESHING_RESULTS))
            self.tagsFilterHeaderFocus:Disable()
        elseif currentSearchState == ZO_HOUSE_TOURS_SEARCH_STATES.COMPLETE then
            self.searchResultsList:SetNoItemText(GetString(SI_HOUSE_TOURS_SEARCH_RESULTS_EMPTY_TEXT))
            self.tagsFilterHeaderFocus:Enable()
        end

        self:RefreshKeybinds()
    end
end

do
    local function GetPlayerListingEntryNarrationText(listingData)
        local narrations = {}
        --Get the narration for the nickname and house name
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(listingData:GetFormattedHouseName()))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(listingData:GetFormattedNickname()))

        --Get the narration for the furniture count
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSE_TOURS_LISTING_FURNITURE_COUNT_HEADER_NARRATION)))
        local furnitureCount = listingData:GetFurnitureCount()
        --If the furniture count is unknown, narrate that instead of a number
        if furnitureCount ~= nil then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(furnitureCount))
        else
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSE_TOURS_LISTING_FURNITURE_COUNT_UNKNOWN_NARRATION)))
        end

        -- Get the narration for the listed status
        local statusText = listingData:IsListed() and GetString(SI_HOUSE_TOURS_MANAGE_LISTING_STATUS_LISTED) or GetString(SI_HOUSE_TOURS_MANAGE_LISTING_STATUS_NOT_LISTED)
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSE_TOURS_MANAGE_LISTING_STATUS_HEADER)))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(statusText))

        -- Get the narration for the number of recommendations
        local numRecommendations = listingData:GetNumRecommendations()
        if numRecommendations > 0 then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_HOUSE_TOURS_MANAGE_LISTING_RECOMMENDATIONS_HEADER)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(numRecommendations))
        end

        return narrations
    end

    function ZO_HouseTours_Gamepad:InitializeListingManagementFunctions()
        self.narrateEntryFunction = function(narrationFunction, entryData, entryControl)
            local narrations = {}
            -- Generate the entry narration using the specified narration function.
            ZO_AppendNarration(narrations, narrationFunction(entryData, entryControl))

            -- Generate the listing panel narration
            ZO_AppendNarration(narrations, GetPlayerListingEntryNarrationText(self:GetSelectedPlayerListingData()))
            return narrations
        end

        self.narrateDefaultEntryFunction = function(entryData, entryControl)
            return self.narrateEntryFunction(ZO_GetSharedGamepadEntryDefaultNarrationText, entryData, entryControl)
        end

        self.narrateDropdownEntryFunction = function(entryData, entryControl)
            return self.narrateEntryFunction(ZO_GetDefaultParametricListDropdownNarrationText, entryData, entryControl)
        end

        self.onDropdownEntrySelected = function(entryData, entryControl)
            entryControl.dropdown:Activate()
        end

        self.onNicknameEntrySelected = function(targetData, targetControl, selectedCollectibleId)
            local selectedListingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(selectedCollectibleId)
            if selectedListingData then
                local nickname = selectedListingData:GetNickname()
                local defaultNickname = selectedListingData:GetDefaultNickname()
                -- Only pre-fill the edit text if it's different from the default nickname
                local initialEditText = ""
                if nickname ~= defaultNickname then
                    initialEditText = nickname
                end
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE", { collectibleId = selectedCollectibleId, name = initialEditText, defaultName = defaultNickname })
            end
        end

        self.onSelectHomeSelected = function(entryData, entryControl)
            self:SetMode(HOUSE_TOURS_MODES.SELECT_HOME)
        end
    end

    function ZO_HouseTours_Gamepad:GetSelectedPlayerListingData()
        return HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedPlayerListingCollectibleId)
    end

    function ZO_HouseTours_Gamepad:RefreshListingsManagementList(preserveEntrySelections)
        local preservedTagSelections = nil
        if preserveEntrySelections then
            preservedTagSelections = {}
            local selectedTagsData = self.tagsDropdownEntries:GetSelectedItems()
            for _, item in ipairs(selectedTagsData) do
                table.insert(preservedTagSelections, item.tagValue)
            end
        end

        local list = self.listingsManagementList
        list:Clear()

        local selectedData = self:GetSelectedPlayerListingData()
        if selectedData then
            -- Setup the select home entry
            local selectHomeEntryData = ZO_GamepadEntryData:New(selectedData:GetFormattedHouseName(), selectedData:GetCollectibleIcon())
            selectHomeEntryData.header = GetString(SI_HOUSE_TOURS_MANAGE_LISTING_HOUSE_SELECT_HOME)
            selectHomeEntryData.selectCallback = self.onSelectHomeSelected
            selectHomeEntryData.isListedResidence = selectedData:IsListed()
            selectHomeEntryData.isPrimaryResidence = selectedData:IsPrimaryResidence()
            selectHomeEntryData.isFavorite = selectedData:IsCollectibleFavorite()
            selectHomeEntryData.narrationText = self.narrateDefaultEntryFunction
            list:AddEntryWithHeader("ZO_GamepadMenuEntryTemplateWithArrow", selectHomeEntryData)

            -- Setup the default visitor access dropdown
            local defaultVisitorAccessEntryData = ZO_GamepadEntryData:New("")
            defaultVisitorAccessEntryData.header = GetString(SI_HOUSING_FURNITURE_SETTINGS_GENERAL_DEFAULT_ACCESS_TEXT)
            defaultVisitorAccessEntryData.selectCallback = self.onDropdownEntrySelected
            defaultVisitorAccessEntryData.narrationText = self.narrateDropdownEntryFunction
            list:AddEntryWithHeader("ZO_Gamepad_Dropdown_Item_Indented", defaultVisitorAccessEntryData)

            -- Setup the tags dropdown
            -- Clear out the tag selections and auto select the currently saved tags for this house
            self.tagsDropdownEntries:ClearAllSelections()
            local tags = preservedTagSelections or selectedData:GetTags()
            for _, item in ipairs(self.tagsDropdownEntries:GetAllItems()) do
                if ZO_IsElementInNumericallyIndexedTable(tags, item.tagValue) then
                    self.tagsDropdownEntries:SetItemSelected(item, true)
                end
            end

            local tagsEntryData = ZO_GamepadEntryData:New("")
            tagsEntryData.header = GetString(SI_HOUSE_TOURS_LISTING_TAGS_HEADER)
            tagsEntryData.selectCallback = self.onDropdownEntrySelected
            tagsEntryData.narrationText = self.narrateDropdownEntryFunction
            list:AddEntryWithHeader("ZO_Gamepad_MultiSelection_Dropdown_Item_Indented", tagsEntryData)

            -- Setup the house nickname entry
            local nicknameEntryData = ZO_GamepadEntryData:New(selectedData:GetFormattedNickname())
            nicknameEntryData.header = GetString(SI_HOUSE_TOURS_MANAGE_LISTING_CURRENT_NICKNAME_HEADER)
            nicknameEntryData.selectCallback = self.onNicknameEntrySelected
            nicknameEntryData.selectName = GetString(SI_COLLECTIBLE_ACTION_RENAME)
            nicknameEntryData.narrationText = self.narrateDefaultEntryFunction
            list:AddEntryWithHeader("ZO_GamepadMenuEntryTemplate", nicknameEntryData)
        end

        list:Commit()
    end

    local function GetHomeListEntryNarrationText(entryData, entryControl)
        local narrations = {}
        -- Generate the standard parametric list entry narration
        ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

        --Generate the listing panel narration
        ZO_AppendNarration(narrations, GetPlayerListingEntryNarrationText(entryData))
        return narrations
    end

    function ZO_HouseTours_Gamepad:RefreshHomeList()
        local list = self.homeList
        list:Clear()
        local sortedListingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetSortedListingData()
        for _, listingData in ipairs(sortedListingData) do
            local entryData = ZO_GamepadEntryData:New(listingData:GetFormattedHouseName(), listingData:GetCollectibleIcon())
            entryData:SetDataSource(listingData)
            entryData.isListedResidence = listingData:IsListed()
            entryData.isPrimaryResidence = listingData:IsPrimaryResidence()
            entryData.isFavorite = listingData:IsCollectibleFavorite()
            entryData.narrationText = GetHomeListEntryNarrationText
            list:AddEntry("ZO_GamepadItemEntryTemplate", entryData)
        end

        list:Commit()
    end
end

function ZO_HouseTours_Gamepad:ReselectLastSelectedIndexForCurrentMode()
    local modeData = self:GetDataForMode(self.mode)
    if not (modeData and modeData.list == self.searchResultsList) then
        -- Only reselect the last selected index for search results.
        return
    end

    local lastSelectedIndex = modeData.lastSelectedIndex
    if not lastSelectedIndex then
        -- There is no last selected index yet.
        return
    end

    local numEntries = modeData.list:GetNumEntries()
    if numEntries < 1 then
        -- There is nothing to reselect.
        return
    end

    -- Attempt to reselect the last selected index.
    local ALLOW_EVEN_IF_DISABLED = true
    lastSelectedIndex = zo_clamp(lastSelectedIndex, 1, numEntries)
    modeData.list:SetSelectedIndexWithoutAnimation(lastSelectedIndex, ALLOW_EVEN_IF_DISABLED)
end

function ZO_HouseTours_Gamepad:UpdateLastSelectedIndexForCurrentMode(selectedIndex)
    local modeData = self:GetDataForMode(self.mode)
    if not (modeData and modeData.list == self.searchResultsList) then
        -- Only track the last selected data for search results.
        return
    end

    -- Store the last selected index, if any.
    modeData.lastSelectedIndex = selectedIndex
end

function ZO_HouseTours_Gamepad:RefreshList()
    local modeData = self:GetDataForMode(self.mode)
    if modeData then
        modeData.refreshFunction()
    end

    self:ReselectLastSelectedIndexForCurrentMode()
    self:RefreshHeader()
end

function ZO_HouseTours_Gamepad:ResetTooltips()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_HouseTours_Gamepad:RefreshTooltips()
    self:ResetTooltips()
    local modeData = self:GetDataForMode(self.mode)
    if modeData and modeData.tooltipFunction then
        modeData.tooltipFunction()
    end
end

function ZO_HouseTours_Gamepad:RefreshTagsFilterDropdown()
    local modeData = self:GetDataForMode(self.mode)
    if modeData then
        self.tagsFilterDropdownControl:SetHidden(not modeData.hasTagsFilter)
        if modeData.hasTagsFilter then
            self.tagsFilterDropdownEntries:ClearAllSelections()
            local filters = HOUSE_TOURS_SEARCH_MANAGER:GetSearchFilters(modeData.listingType)
            if filters then
                local tags = filters:GetTags()
                for _, item in ipairs(self.tagsFilterDropdownEntries:GetAllItems()) do
                    if ZO_IsElementInNumericallyIndexedTable(tags, item.tagValue) then
                        self.tagsFilterDropdownEntries:SetItemSelected(item, true)
                    end
                end
                self.tagsFilterDropdown:LoadData(self.tagsFilterDropdownEntries)
            end
        end
    else
        self.tagsFilterDropdownControl:SetHidden(true)
    end
end

do
    local FURNITURE_COUNT_TEXTURE = "EsoUI/Art/HouseTours/houseTours_furnitureCount.dds"
    local IS_FRIEND_TEXTURE = "EsoUI/Art/HouseTours/houseTours_listingIcon_friends.dds"
    local IS_GUILD_MEMBER_TEXTURE = "EsoUI/Art/HouseTours/houseTours_listingIcon_guild.dds"
    local IS_LOCAL_PLAYER_TEXTURE = "EsoUI/Art/HouseTours/houseTours_listingIcon_localPlayer.dds"
    local IS_LISTED_TEXTURE = "EsoUI/Art/HouseTours/houseTours_listed.dds"

    function ZO_HouseTours_Gamepad:RefreshListingPanel(list, selectedData)
        local showPanel = false
        local modeData = self:GetDataForMode(self.mode)
        --If the mode has a listing panel that is visible, update it now
        if modeData and selectedData and list == modeData.list then
            local hasListingPanel = modeData.hasListingPanel
            if type(hasListingPanel) == "function" then
                hasListingPanel = hasListingPanel()
            end

            local panelContents = modeData.listingPanelContents
            if hasListingPanel and panelContents then
                local listingPanel = self.listingPanelControl
                listingPanel.backgroundControl:SetTexture(selectedData:GetBackgroundImage())

                panelContents.nicknameLabel:SetText(selectedData:GetFormattedNickname())
                panelContents.nameLabel:SetText(selectedData:GetFormattedHouseName())

                local furnitureCountText
                local furnitureCount = selectedData:GetFurnitureCount()
                if furnitureCount ~= nil then
                    furnitureCountText = zo_iconTextFormat(FURNITURE_COUNT_TEXTURE, 64, 64, furnitureCount)
                else
                    furnitureCountText = zo_iconTextFormat(FURNITURE_COUNT_TEXTURE, 64, 64, GetString(SI_HOUSE_TOURS_LISTING_FURNITURE_COUNT_UNKNOWN))
                end
                panelContents.furnitureCountLabel:SetText(furnitureCountText)

                if panelContents.tagsLabel then
                    panelContents.tagsLabel:SetText(selectedData:GetFormattedTagsText())
                end

                if panelContents.ownerLabel then
                    local formattedDisplayName = selectedData:GetFormattedOwnerDisplayName()
                    if selectedData:IsOwnedByFriend() then
                        formattedDisplayName = zo_iconTextFormatNoSpace(IS_FRIEND_TEXTURE, 64, 64, formattedDisplayName)
                    elseif selectedData:IsOwnedByGuildMember() then
                        formattedDisplayName = zo_iconTextFormatNoSpace(IS_GUILD_MEMBER_TEXTURE, 64, 64, formattedDisplayName)
                    elseif selectedData:IsOwnedByLocalPlayer() then
                        local INHERIT_COLOR = true
                        formattedDisplayName = ZO_SECOND_CONTRAST_TEXT:Colorize(zo_iconTextFormatNoSpace(IS_LOCAL_PLAYER_TEXTURE, 64, 64, formattedDisplayName, INHERIT_COLOR))
                    end
                    panelContents.ownerLabel:SetText(formattedDisplayName)
                end

                if panelContents.statusLabel then
                    local statusText
                    if selectedData:IsListed() then
                        statusText = zo_iconTextFormatNoSpace(IS_LISTED_TEXTURE, 32, 32, GetString(SI_HOUSE_TOURS_MANAGE_LISTING_STATUS_LISTED))
                    else
                        statusText = GetString(SI_HOUSE_TOURS_MANAGE_LISTING_STATUS_NOT_LISTED)
                    end
                    panelContents.statusLabel:SetText(statusText)
                end

                if panelContents.recommendationsLabel and panelContents.recommendationsHeader then
                    local numRecommendations = selectedData:GetNumRecommendations()
                    if numRecommendations > 0 then
                        panelContents.recommendationsHeader:SetHidden(false)
                        panelContents.recommendationsLabel:SetHidden(false)
                        panelContents.recommendationsLabel:SetText(ZO_CommaDelimitNumber(numRecommendations))
                    else
                        panelContents.recommendationsHeader:SetHidden(true)
                        panelContents.recommendationsLabel:SetHidden(true)
                    end
                end

                showPanel = true
            end
        end

        --Add or remove the fragments for the listing panel depending on if we should be showing it
        if showPanel then
            SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
            SCENE_MANAGER:AddFragment(self.listingPanelFragment)
        else
            SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
            SCENE_MANAGER:RemoveFragment(self.listingPanelFragment)
        end
    end
end

function ZO_HouseTours_Gamepad:RefreshNickname()
    if not (self.hasHouses and self.mode == HOUSE_TOURS_MODES.MANAGE_LISTINGS and self:IsShowing()) then
        return
    end

    local modeData = self:GetDataForMode(self.mode)
    if not modeData then
        return
    end

    local hasListingPanel = modeData.hasListingPanel
    if not hasListingPanel or (type(hasListingPanel) == "function" and not hasListingPanel()) then
        return
    end

    local panelContents = modeData.listingPanelContents
    if not panelContents then
        return
    end

    local selectedListingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedPlayerListingCollectibleId)
    if not selectedListingData then
        return
    end

    -- Refresh the nickname in the listing panel.
    local formattedNickname = selectedListingData:GetFormattedNickname()
    panelContents.nicknameLabel:SetText(formattedNickname)

    -- Refresh the nickname entry data in the parametric list.
    self:RefreshListingsManagementList(PRESERVE_SELECTIONS)
end

function ZO_HouseTours_Gamepad:SetIsListingOperationOnCooldown(isListingOperationOnCooldown)
    self.isListingOperationOnCooldown = isListingOperationOnCooldown
    self:RefreshKeybinds()
end

function ZO_HouseTours_Gamepad:GetDataForMode(mode)
    return self.modeData[mode]
end

function ZO_HouseTours_Gamepad:SetMode(newMode)
    local oldMode = self.mode
    if newMode ~= oldMode then
        self.mode = newMode

        --Remove the keybinds and hide the panel contents for the previous mode first
        if oldMode then
            local oldModeData = self:GetDataForMode(oldMode)
            if oldModeData.listingPanelContents then
                oldModeData.listingPanelContents:SetHidden(true)
            end
            KEYBIND_STRIP:RemoveKeybindButtonGroup(oldModeData.keybindStripDescriptor)
        end

        self:RefreshTagsFilterDropdown()

        if newMode then
            --Add the keybinds and panel contents for the new mode and switch to the corresponding list
            local newModeData = self:GetDataForMode(newMode)
            if newModeData.listingPanelContents then
                newModeData.listingPanelContents:SetHidden(false)
            end
            KEYBIND_STRIP:AddKeybindButtonGroup(newModeData.keybindStripDescriptor)
            self:SetCurrentList(newModeData.list)
            --If the new mode doesn't have a tags filter, make sure to leave the header
            if not newModeData.hasTagsFilter and self:IsHeaderActive() then
                self:RequestLeaveHeader()
            end

            if newModeData.listingType then
                HOUSE_TOURS_SEARCH_MANAGER:ExecuteSearch(newModeData.listingType)
            end
        end

        --Since the mode changed, refresh the list and listing panel
        self:RefreshList()
        local currentList = self:GetCurrentList()
        local listingData
        --The manage listings mode pull its listing data from the selected player listing collectible id, not the current selection in the list
        if self.mode == HOUSE_TOURS_MODES.MANAGE_LISTINGS then
            listingData = HOUSE_TOURS_PLAYER_LISTINGS_MANAGER:GetListingDataByCollectibleId(self.selectedPlayerListingCollectibleId)
        else
            listingData = currentList:GetSelectedData()
        end
        self:RefreshListingPanel(currentList, listingData)
        self:RefreshTooltips()
    end
end

function ZO_HouseTours_Gamepad.OnControlInitialized(control)
    HOUSE_TOURS_GAMEPAD = ZO_HouseTours_Gamepad:New(control)
end