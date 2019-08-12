--Layout consts--
local HEADER_OVERLAP_UNITS = 3
ZO_GAMEPAD_INTERACTIVE_FILTER_ARROW_PADDING = 15
ZO_GAMEPAD_INTERACTIVE_FILTER_HIGHLIGHT_PADDING = 10
ZO_GAMEPAD_INTERACTIVE_FILTER_RIGHT_ALIGN_HIGHLIGHT_PADDING = ZO_GAMEPAD_INTERACTIVE_FILTER_HIGHLIGHT_PADDING + ZO_GAMEPAD_INTERACTIVE_FILTER_ARROW_PADDING
ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_PADDING_X = ZO_GAMEPAD_INTERACTIVE_FILTER_HIGHLIGHT_PADDING - HEADER_OVERLAP_UNITS
ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_DOUBLE_PADDING_X = ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_HEADER_PADDING_X * 2
ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_ROW_HEIGHT = 80
ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_TWO_LINE_ROW_HEIGHT = 96 --Fits two lines of text

ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_SEARCH_TYPE_NAMES = 1
ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_PRIMARY_DATA_TYPE = 1

-----------------
--Focus Filters--
-----------------

local GamepadInteractiveSortFilterFocus_Filters = ZO_GamepadMultiFocusArea_Base:Subclass()

-- Override
function GamepadInteractiveSortFilterFocus_Filters:CanBeSelected()
    return self.manager.areFiltersRemoved ~= true
end

-----------------
--Focus Headers--
-----------------

local GamepadInteractiveSortFilterFocus_Headers = ZO_GamepadMultiFocusArea_Base:Subclass()

function GamepadInteractiveSortFilterFocus_Headers:HandleMoveNext()
    local consumed = true
    if self.manager:HasEntries() then
        consumed = ZO_GamepadMultiFocusArea_Base.HandleMoveNext(self)
    end
    return consumed
end

--------------
--Focus List--
--------------

local GamepadInteractiveSortFilterFocus_Panel = ZO_GamepadMultiFocusArea_Base:Subclass()

function GamepadInteractiveSortFilterFocus_Panel:HandleMovement(horizontalResult, verticalResult)
    if verticalResult == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self.manager:MoveNext()
        return true
    elseif verticalResult == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        self.manager:MovePrevious()
        return true
    end
    return false
end

function GamepadInteractiveSortFilterFocus_Panel:HandleMovePrevious()
    local consumed = false
    if ZO_ScrollList_AtTopOfList(self.manager.list) then
        consumed = ZO_GamepadMultiFocusArea_Base.HandleMovePrevious(self)
    end
    return consumed
end

--------------------
--Sort/Filter List--
--------------------

--Initialization--
ZO_GamepadInteractiveSortFilterList = ZO_Object.MultiSubclass(ZO_SortFilterList_Gamepad, ZO_GamepadMultiFocusArea_Manager)

function ZO_GamepadInteractiveSortFilterList:New(...)
    return ZO_SortFilterList_Gamepad.New(self, ...)
end

function ZO_GamepadInteractiveSortFilterList:Initialize(control)
    self.container = control:GetNamedChild("Container")
    ZO_SortFilterList_Gamepad.Initialize(self, control)
    ZO_GamepadMultiFocusArea_Manager.Initialize(self)

    self.searchProcessor = ZO_StringSearch:New()
    self.searchProcessor:AddProcessor(ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_SEARCH_TYPE_NAMES, function(stringSearch, data, searchTerm, cache) return self:ProcessNames(stringSearch, data, searchTerm, cache) end)

    self:InitializeHeader()
    self:InitializeFilters()
    self:SetupFoci()
    self:InitializeKeybinds()

    self.listFragment = ZO_FadeSceneFragment:New(control)
    self.listFragment:RegisterCallback("StateChange", function(oldState, newState)
                                                        if newState == SCENE_FRAGMENT_SHOWING then
                                                            self:OnShowing()
                                                        elseif newState == SCENE_FRAGMENT_SHOWN then
                                                            self:OnShown()
                                                        elseif newState == SCENE_FRAGMENT_HIDING then
                                                            self:OnHiding()
                                                        elseif newState == SCENE_FRAGMENT_HIDDEN then
                                                            self:OnHidden()
                                                        end
                                                    end)
end

function ZO_GamepadInteractiveSortFilterList:InitializeSortFilterList(control)
    ZO_SortFilterList_Gamepad.InitializeSortFilterList(self, self.container)
    self.sortFunction = function(listEntry1, listEntry2) return self:CompareSortEntries(listEntry1, listEntry2) end
end

function ZO_GamepadInteractiveSortFilterList:SetupFoci()
    -- TODO: If we want to turn on filters and searching after initialization foci will have to be re-setup
    if not (self.contentHeader:IsControlHidden() or (self.filterControl:IsControlHidden() and self.searchControl:IsControlHidden())) then
        local function FiltersActivateCallback()
            self.filterSwitcher:Activate()
        end

        local function FiltersDeactivateCallback()
            self.filterSwitcher:Deactivate()
        end
        self.filtersFocalArea = GamepadInteractiveSortFilterFocus_Filters:New(self, FiltersActivateCallback, FiltersDeactivateCallback)
        self:AddNextFocusArea(self.filtersFocalArea)
    end

    local function HeaderActivateCallback()
        if self.sortHeaderGroup then
            self.sortHeaderGroup:SetDirectionalInputEnabled(true)
            self.sortHeaderGroup:EnableSelection(true)
        end
    end

    local function HeaderDeactivateCallback()
        if self.sortHeaderGroup then
            self.sortHeaderGroup:SetDirectionalInputEnabled(false)
            self.sortHeaderGroup:EnableSelection(false)
        end
    end
    self.headersFocalArea =  GamepadInteractiveSortFilterFocus_Headers:New(self, HeaderActivateCallback, HeaderDeactivateCallback)
    self:AddNextFocusArea(self.headersFocalArea)

    local function PanelActivateCallback()
        local ANIMATE_INSTANTLY = true
        ZO_ScrollList_AutoSelectData(self.list, ANIMATE_INSTANTLY)
    end

    local function PanelDeactivateCallback()
        self:DeselectListData()
    end
    self.panelFocalArea = GamepadInteractiveSortFilterFocus_Panel:New(self, PanelActivateCallback, PanelDeactivateCallback)

    self:AddNextFocusArea(self.panelFocalArea)
end

function ZO_GamepadInteractiveSortFilterList:InitializeHeader(headerData)
    self.contentHeader = self.container:GetNamedChild("ContentHeader")
    ZO_GamepadGenericHeader_Initialize(self.contentHeader, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ZO_GAMEPAD_HEADER_LAYOUTS.CONTENT_HEADER_DATA_PAIRS_LINKED)

    if headerData then
        headerData.titleTextAlignment = headerData.titleTextAlignment or TEXT_ALIGN_CENTER
    else
        headerData = { titleTextAlignment = TEXT_ALIGN_CENTER }
    end
    self.contentHeaderData = headerData

    ZO_GamepadGenericHeader_RefreshData(self.contentHeader, self.contentHeaderData)

    local titleFonts =
    {
        {
            font = "ZoFontGamepadBold48",
        },
        {
            font = "ZoFontGamepadBold34",
        },
        {
            font = "ZoFontGamepadBold27",
        }
    }
    ZO_FontAdjustingWrapLabel_OnInitialized(self.contentHeader:GetNamedChild("TitleContainerTitle"), titleFonts, TEXT_WRAP_MODE_ELLIPSIS)
end

function ZO_GamepadInteractiveSortFilterList:InitializeFilters()
    self.filterSwitcher = ZO_GamepadFocus:New(self.contentHeader, ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL))

    self:InitializeDropdownFilter()
    self:InitializeSearchFilter()

    local FocusChangedCallback = function()
        self.searchEdit:LoseFocus()
    end
    self.filterSwitcher:SetFocusChangedCallback(FocusChangedCallback)
end

function ZO_GamepadInteractiveSortFilterList:InitializeDropdownFilter()
    self.filterControl = self.contentHeader:GetNamedChild("DropdownFilter")
    local filterDropdownControl = self.filterControl:GetNamedChild("Dropdown")

    self.filterDropdown = ZO_ComboBox_ObjectFromContainer(filterDropdownControl)
    self.filterDropdown:SetSelectedColor(ZO_DISABLED_TEXT)
    self.filterDropdown:SetSortsItems(false)

    local function DropDownDeactivatedCallback()
        self.filterSwitcher:Activate()
        self:OnFilterDeactivated()
    end

    self.filterDropdown:SetDeactivatedCallback(DropDownDeactivatedCallback)

    local filterData = {
        callback = function()
            self.filterSwitcher:Deactivate()
            self.filterDropdown:Activate()
        end,
        activate = function()
            self.filterDropdown:SetSelectedColor(ZO_SELECTED_TEXT)
        end,
        deactivate = function()
            self.filterDropdown:SetSelectedColor(ZO_DISABLED_TEXT)
        end,
        highlight = self.filterControl:GetNamedChild("Highlight"),
        canFocus = function() return not self.filterControl:IsHidden() and not filterDropdownControl:IsHidden() end,
    }
    self.filterSwitcher:AddEntry(filterData)
end

function ZO_GamepadInteractiveSortFilterList:InitializeSearchFilter()
    self.searchControl = self.contentHeader:GetNamedChild("SearchFilter")
    local searchEdit = self.searchControl:GetNamedChild("SearchEdit")

    local function SearchEditFocusLost()
        ZO_GamepadEditBox_FocusLost(searchEdit)
        self:RefreshFilters()
    end
    searchEdit:SetHandler("OnFocusLost", SearchEditFocusLost)

    local searchData = {
        callback = function() 
            if not searchEdit:HasFocus() then
                searchEdit:TakeFocus()
            end
        end,
        highlight = self.searchControl:GetNamedChild("Highlight"),
        canFocus = function() return not self.searchControl:IsHidden() and not searchEdit:IsHidden() end
    }
    self.filterSwitcher:AddEntry(searchData)
    self.searchEdit = searchEdit
end

function ZO_GamepadInteractiveSortFilterList:InitializeKeybinds()
    -- Keybind Strip when a filter column header is selected
    local filterKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                local data = self.filterSwitcher:GetFocusItem()
                if data.callback then
                    data.callback()
                end
            end,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(filterKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, self:GetBackKeybindCallback())

    -- Keybind Strip when a list column header is selected
    local headerKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            name = GetString(SI_GAMEPAD_SORT_OPTION),

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                self.sortHeaderGroup:SortBySelected()
            end,

            enabled = function()
                return self:CanChangeSortKey()
            end
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(headerKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, self:GetBackKeybindCallback())

    --Triggers let you go straight to top or bottom of the list
    self.keybindStripDescriptor[#self.keybindStripDescriptor + 1] = {
         --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
        name = "Gamepad Interactive Sort Filter List Left Trigger",

        keybind = "UI_SHORTCUT_LEFT_TRIGGER",

        ethereal = true,

        callback = function()
            self:OnLeftTrigger()
        end,
    }

    self.keybindStripDescriptor[#self.keybindStripDescriptor + 1] = {
        --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
        name = "Gamepad Interactive Sort Filter List Right Trigger",

        keybind = "UI_SHORTCUT_RIGHT_TRIGGER",

        ethereal = true,

        callback = function()
            self:OnRightTrigger()
        end,
    }

    if self.filtersFocalArea then
        self.filtersFocalArea:SetKeybindDescriptor(filterKeybindStripDescriptor)
    end
    self.headersFocalArea:SetKeybindDescriptor(headerKeybindStripDescriptor)
    self.panelFocalArea:SetKeybindDescriptor(self.keybindStripDescriptor)
end

function ZO_GamepadInteractiveSortFilterList:AddUniversalKeybind(keybind)
    if self.filtersFocalArea then
        self.filtersFocalArea:AppendKeybind(keybind)
    end
    self.headersFocalArea:AppendKeybind(keybind)
    self.panelFocalArea:AppendKeybind(keybind)
end

function ZO_GamepadInteractiveSortFilterList:GetBackKeybindCallback()
    -- this function can be overridden in a subclass
end

function ZO_GamepadInteractiveSortFilterList:SetupSort(sortKeys, initialKey, initialDirection)
    self.sortKeys = sortKeys
    local DONT_SUPPRESS_CALLBACKS = nil
    local DONT_FORCE_RESELECT = nil
    self.sortHeaderGroup:SelectHeaderByKey(initialKey, DONT_SUPPRESS_CALLBACKS, DONT_FORCE_RESELECT, initialDirection)
    self.sortHeaderGroup:SortBySelected()
end

--Events/Callbacks--

function ZO_GamepadInteractiveSortFilterList:OnShowing()
    --To be overriden
end

function ZO_GamepadInteractiveSortFilterList:OnShown()
    --To be overriden
end

function ZO_GamepadInteractiveSortFilterList:OnHiding()
    self:Deactivate()
end

function ZO_GamepadInteractiveSortFilterList:OnHidden()
    --To be overriden
end

function ZO_GamepadInteractiveSortFilterList:Activate()
    self:SetDirectionalInputEnabled(true)
    local activeFocus = self:HasEntries() and self.panelFocalArea or self.headersFocalArea
    if not activeFocus then
        self:Deactivate()
    else
        self:ActivateFocusArea(activeFocus)
        self.isActive = true
        ZO_GamepadOnDefaultActivatedChanged(self.list, self.isActive)
    end
end

function ZO_GamepadInteractiveSortFilterList:Deactivate()
    self:SetDirectionalInputEnabled(false)

    if self.filterDropdown and self.filterDropdown:IsActive() then
        local BLOCK_CALLBACK = true
        self.filterDropdown:Deactivate(BLOCK_CALLBACK)
    end

    self:DeactivateCurrentFocus()

    self.isActive = false
    ZO_GamepadOnDefaultActivatedChanged(self.list, self.isActive)
end

function ZO_GamepadInteractiveSortFilterList:IsActive()
    return self.isActive
end

function ZO_GamepadInteractiveSortFilterList:ActivatePanelFocus()
    if self:HasEntries() then
        self:ActivateFocusArea(self.panelFocalArea)
    end
end

function ZO_GamepadInteractiveSortFilterList:IsPanelFocused()
    return self:IsCurrentFocusArea(self.panelFocalArea)
end

function ZO_GamepadInteractiveSortFilterList:CanChangeSortKey()
    --To be overriden
    return true
end

-- explicitly call the correct base class function
function ZO_GamepadInteractiveSortFilterList:UpdateDirectionalInput()
    ZO_GamepadMultiFocusArea_Manager.UpdateDirectionalInput(self)
end

function ZO_GamepadInteractiveSortFilterList:OnFilterDeactivated()
    self:RefreshFilters()
end

function ZO_GamepadInteractiveSortFilterList:OnLeftTrigger()
    ZO_ScrollList_TrySelectFirstData(self.list)
end

function ZO_GamepadInteractiveSortFilterList:OnRightTrigger()
    ZO_ScrollList_TrySelectLastData(self.list)
end

--Get / Set --
function ZO_GamepadInteractiveSortFilterList:SetTitle(titleName)
    self.contentHeaderData.titleText = titleName
    ZO_GamepadGenericHeader_RefreshData(self.contentHeader, self.contentHeaderData)
end

function ZO_GamepadInteractiveSortFilterList:RefreshHeader()
    ZO_GamepadGenericHeader_RefreshData(self.contentHeader, self.contentHeaderData)
end

function ZO_GamepadInteractiveSortFilterList:SetEmptyText(emptyText)
    if not self.emptyRow then
        self.emptyRow = self.container:GetNamedChild("EmptyRow")
        self.emptyRowMessage = self.emptyRow:GetNamedChild("Message")
    end
    self.emptyText = emptyText
    self.emptyRowMessage:SetText(emptyText)
end

function ZO_GamepadInteractiveSortFilterList:SetMasterList(list)
    self.masterList = list
end

function ZO_GamepadInteractiveSortFilterList:GetMasterList()
    return self.masterList
end

function ZO_GamepadInteractiveSortFilterList:GetHeaderControl(headerName)
    return self.headersContainer:GetNamedChild(headerName)
end

function ZO_GamepadInteractiveSortFilterList:GetContentHeaderData()
    return self.contentHeaderData
end

function ZO_GamepadInteractiveSortFilterList:GetCurrentSearch()
    return self.searchEdit:GetText()
end

function ZO_GamepadInteractiveSortFilterList:HasEntries(ignoreFilters)
    if ignoreFilters then
        return self.masterList and #self.masterList > 0 or false
    else
        return ZO_SortFilterList.HasEntries(self)
    end
end

function ZO_GamepadInteractiveSortFilterList:GetListFragment()
    return self.listFragment
end

function ZO_GamepadInteractiveSortFilterList:UpdateKeybinds()
    ZO_SortFilterList_Gamepad.UpdateKeybinds(self)

    if self.filtersFocalArea then
        self.filtersFocalArea:UpdateKeybinds()
    end
    self.headersFocalArea:UpdateKeybinds()
    self.panelFocalArea:UpdateKeybinds()
end

function ZO_GamepadInteractiveSortFilterList:RemoveFilters()
    -- TODO: Instead of doing this, create a ZO_GamepadInteractiveSortList base class that doesn't have filters, and then implement filter behavior as a subclass.
    self.areFiltersRemoved = true
    local searchControl = self.contentHeader:GetNamedChild("SearchFilter")
    local dropdownControl = self.contentHeader:GetNamedChild("DropdownFilter")
    local titleControl = self.contentHeader:GetNamedChild("TitleContainerTitle")
    searchControl:SetHidden(true)
    dropdownControl:SetHidden(true)
    titleControl:ClearAnchors()
    titleControl:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
    titleControl:SetAnchor(BOTTOMRIGHT, nil, BOTTOMRIGHT, 0, 0)
end

--List management --

function ZO_GamepadInteractiveSortFilterList:FilterScrollList()
    -- intended to be overriden
    -- should take the master list data and filter it
end

function ZO_GamepadInteractiveSortFilterList:SortScrollList()
    -- can optionally be overriden
    -- should take the filtered data and sort it

    -- The default implemenation will sort according to the sort keys specified in the SetupSort function
    if self.sortKeys and self.currentSortKey and self.currentSortOrder ~= nil then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        table.sort(scrollData, self.sortFunction)
    end
end

function ZO_GamepadInteractiveSortFilterList:CompareSortEntries(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, self.sortKeys, self.currentSortOrder)
end

function ZO_GamepadInteractiveSortFilterList:CommitScrollList()
    ZO_SortFilterList.CommitScrollList(self)

    --Display a different string if there are no results to find than if your filters eliminated all results
    if self.emptyRow and not self.emptyRow:IsHidden() then
        self.emptyRowMessage:SetText(#self.masterList == 0 and self.emptyText or GetString(SI_SORT_FILTER_LIST_NO_RESULTS))
    end

    if self:IsPanelFocused() and self.isActive then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        if #scrollData == 0 then
            --If the cursor is in the list, but the list is empty because of a filter, we need to force it out of the panel area
            self:ActivateFocusArea(self.headersFocalArea)
        else
            -- if we've lost our selection and the panelFocalArea is active, then we want to
            -- AutoSelect the next appropriate entry
            local selectedData = ZO_ScrollList_GetSelectedData(self.list)
            if not selectedData then
                local ANIMATE_INSTANTLY = true
                ZO_ScrollList_AutoSelectData(self.list, ANIMATE_INSTANTLY)
            end
        end
    end
end

function ZO_GamepadInteractiveSortFilterList:IsMatch(searchTerm, data)
    return self.searchProcessor:IsMatch(searchTerm, data)
end

function ZO_GamepadInteractiveSortFilterList:ProcessNames(stringSearch, data, searchTerm, cache)
    local lowerSearchTerm = searchTerm:lower()

    if(zo_plainstrfind(data.displayName:lower(), lowerSearchTerm)) then
        return true
    end

    if(data.characterName ~= nil and zo_plainstrfind(data.characterName:lower(), lowerSearchTerm)) then
        return true
    end
end

function ZO_GamepadInteractiveSortFilterList:DeselectListData()
    ZO_ScrollList_SelectData(self.list, nil)
    ZO_ScrollList_ResetAutoSelectIndex(self.list)
end


--Global functions--

function ZO_GamepadInteractiveSortFilterHeader_Initialize(control, text, sortKey, textAlignment)
    ZO_SortHeader_Initialize(control, text, sortKey, ZO_SORT_ORDER_UP, textAlignment, nil, "ZO_GamepadInteractiveSortFilterHeaderHighlight")
    if textAlignment == TEXT_ALIGN_RIGHT then
        local nameControl = control:GetNamedChild("Name")
        --Account for the arrow
        nameControl:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, -ZO_GAMEPAD_INTERACTIVE_FILTER_ARROW_PADDING)
    end
end