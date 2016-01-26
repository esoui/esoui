ZO_PAGEDLIST_MOVEMENT_TYPES = 
{
    PAGE_FORWARD = 1,
    PAGE_BACK = 2,
    -- LAST allows derived classes to start their movement enumerations after the base movements 
    LAST = 3,
}

function ZO_PagedListPlaySound(type)
    if type == ZO_PAGEDLIST_MOVEMENT_TYPES.PAGE_FORWARD then
        PlaySound(SOUNDS.GAMEPAD_PAGE_FORWARD)
    elseif type == ZO_PAGEDLIST_MOVEMENT_TYPES.PAGE_BACK then
        PlaySound(SOUNDS.GAMEPAD_PAGE_BACK)
    end
end

function ZO_PagedListSetupFooter(footerControl)
    footer = {}
    footer.control = footerControl
    footer.previousButton = footerControl:GetNamedChild("PreviousButton")
    footer.nextButton = footerControl:GetNamedChild("NextButton")
    footer.pageNumberLabel = footerControl:GetNamedChild("PageNumberText")

    return footer
end

ZO_PagedList = ZO_SortFilterListBase:Subclass()

function ZO_PagedList:New(...)
    return ZO_SortFilterListBase.New(self, ...)
end

function ZO_PagedList:BuildMasterList()
    -- intended to be overriden
    -- should populate the dataList by calling AddEntry
end

function ZO_PagedList:FilterList()
    -- intended to be overriden
    -- should take the dataList and filter it
end

function ZO_PagedList:SortList()
    -- can optionally be overriden
    -- should take the dataList and sort it

    -- The default implemenation will sort according to the sort keys specified in the SetupSort function
    if self.sortKeys then
        table.sort(self.dataList, function(listEntry1, listEntry2) return self:CompareSortEntries(listEntry1, listEntry2) end)
    end
end

function ZO_PagedList:OnListChanged()
    -- intended to be overriden
    -- allows a subclass to react when list contents change
end

function ZO_PagedList:OnPageChanged()
    -- intended to be overriden
    -- allows a subclass to react when list page changes
end

function ZO_PagedList:Initialize(control, movementController)
    ZO_SortFilterListBase.Initialize(self, control, movementController)
    self.listControl = control:GetNamedChild("List")

    self.focus = ZO_GamepadFocus:New(self.listControl, movementController)
    
    self.selectionChangedCallback = nil
    local selectionChangeCallback = function(control)
        if self.selectionChangedCallback then
            local data = nil
            if control then
                data = control.data.data
            end
            self.selectionChangedCallback(data)
        end
    end
    self.focus:SetFocusChangedCallback(selectionChangeCallback)

    self.dataTypes = {}
    self.dataList = {}

    self.pages = {}
    self.currPageNum = 1  
    self.numPages = 0
    self.rememberSpot = false

    local headerContainer = control:GetNamedChild("Headers")
    if(headerContainer) then
        local showArrows = true
        self.sortHeaderGroup = ZO_SortHeaderGroup:New(headerContainer, showArrows)
        self.sortHeaderGroup:SetColors(ZO_SELECTED_TEXT, ZO_NORMAL_TEXT, ZO_SELECTED_TEXT, ZO_DISABLED_TEXT)
        self.sortHeaderGroup:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, function(key, order) self:OnSortHeaderClicked(key, order) end)
        self.sortHeaderGroup:AddHeadersFromContainer()
    end

    local footerControl = control:GetNamedChild("Footer")
    if(footerControl) then
        self.footer = {
            control = footerControl,
            previousButton = footerControl:GetNamedChild("PreviousButton"),
            nextButton = footerControl:GetNamedChild("NextButton"),
            pageNumberLabel = footerControl:GetNamedChild("PageNumberText"),
        }
    end


    self.onEnterRow = function(control, data)
        self:OnEnterRow(control, data.data)   
    end

    self.onLeaveRow = function(control, data)
        self:OnLeaveRow(control, data.data)   
    end

    self.onPlaySoundFunction = ZO_PagedListPlaySound

    local hideKeybind = footerControl ~= nil

    self.pagedListKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Previous
        {
            name = GetString(SI_LORE_READER_PREVIOUS_PAGE),
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            order = 100,
            callback = function()
                self:PreviousPage()
            end,

            ethereal = hideKeybind,
        },

        -- Next
        {
            name = GetString(SI_LORE_READER_NEXT_PAGE),
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            order = 100,
            callback = function()
                self:NextPage()
            end,

            ethereal = hideKeybind,
        },
    }
end

function ZO_PagedList:TakeFocus()
    self.focus:Activate()
end

function ZO_PagedList:ClearFocus()
    self.focus:Deactivate()
end

function ZO_PagedList:Activate()
    self:TakeFocus()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.pagedListKeybindStripDescriptor)
end

function ZO_PagedList:Deactivate(retainFocus)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.pagedListKeybindStripDescriptor)
    self.focus:Deactivate(retainFocus)
end

function ZO_PagedList:ActivateHeader()
    if self.sortHeaderGroup then
        self.sortHeaderGroup:SetDirectionalInputEnabled(true)
        self.sortHeaderGroup:EnableSelection(true)
    end
end

function ZO_PagedList:DeactivateHeader()
    if self.sortHeaderGroup then
        self.sortHeaderGroup:SetDirectionalInputEnabled(false)
        self.sortHeaderGroup:EnableSelection(false)
    end
end

function ZO_PagedList:SetupSort(sortKeys, initialKey, initialDirection)
    self.sortKeys = sortKeys
    self.currentSortKey = initialKey
    self.currentSortOrder = initialDirection
end

function ZO_PagedList:SetSelectionChangedCallback(callback)
    self.selectionChangedCallback = callback
end

function ZO_PagedList:SetLeaveListAtBeginningCallback(callback)
    self.focus:SetLeaveFocusAtBeginningCallback(callback)
end

function ZO_PagedList:OnEnterRow(control, data)
    -- This is meant to be overriden in a subclass
end

function ZO_PagedList:OnLeaveRow(control, data)
    -- This is meant to be overriden in a subclass
end

function ZO_PagedList:RefreshData()
    self:BuildMasterList()
    self:FilterList()
    self:SortList()
    self:CommitList()
end

function ZO_PagedList:RefreshSort()
    self:SortList()
    self:CommitList()
end

function ZO_PagedList:RefreshFilters()
    self:FilterList()
    self:SortList()
    self:CommitList()
end

function ZO_PagedList:RefreshVisible()
    local page = self.pages[self.currPageNum]
    if page == nil then
        return 
    end
    local lastIndex = (page.startIndex + page.count - 1)
    local previousControl
    for i = page.startIndex, lastIndex do
        local data = self.dataList[i]
        local control = data.control
        local selected = self:IsSelected(data.data)
        self.dataTypes[control.templateName].setupCallback(control, data.data, selected)
    end

    self:OnListChanged()
end

function ZO_PagedList:CommitList()
    self:BuildPages()
    self:BuildPage(self.currPageNum)
    self:RefreshFooter()
    self:OnListChanged()
end

function ZO_PagedList:AddDataTemplate(templateName, height, setupCallback, controlPoolPrefix)
    if not self.dataTypes[templateName] then
        local dataTypeInfo = {
            pool = ZO_ControlPool:New(templateName, self.listControl, controlPoolPrefix or templateName),
            height = height,
            setupCallback = setupCallback
        }
        self.dataTypes[templateName] = dataTypeInfo
    end
end

function ZO_PagedList:AddEntry(templateName, data)
     if self.dataTypes[templateName] then

        local entry = 
        {
            templateName = templateName,
            data = data
        }
        
        self.dataList[#self.dataList + 1] = entry
    end
end

function ZO_PagedList:Clear()
    self.dataList = {}
    for templateName, dataTypeInfo in pairs(self.dataTypes) do
        dataTypeInfo.pool:ReleaseAllObjects()
    end
end

function ZO_PagedList:GetSelectedData()
    local focusItem = self.focus:GetFocusItem()
    if focusItem then
        return focusItem.data.data
    end
end

function ZO_PagedList:IsSelected(data)
    local focusItem = self.focus:GetFocusItem()
    if focusItem then
        return focusItem.data.data == data
    end
    return false
end

function ZO_PagedList:SetPage(pageNum)
    local newPageNum = zo_clamp(pageNum, 1, self.numPages)
    if newPageNum ~= self.currPageNum then
        if newPageNum > self.currPageNum then
            self.onPlaySoundFunction(ZO_PAGEDLIST_MOVEMENT_TYPES.PAGE_FORWARD)
        else
            self.onPlaySoundFunction(ZO_PAGEDLIST_MOVEMENT_TYPES.PAGE_BACK)
        end
        self.currPageNum = newPageNum
        self:BuildPage(self.currPageNum)
        self:RefreshFooter()
        self:OnListChanged()
    end
end

function ZO_PagedList:PreviousPage()
    self:SetPage(self.currPageNum - 1)
end

function ZO_PagedList:NextPage()
    self:SetPage(self.currPageNum + 1)
end

function ZO_PagedList:AcquireControl(dataIndex, relativeControl)
    local PADDING = 0

    local templateName = self.dataList[dataIndex].templateName
    local control, key = self.dataTypes[templateName].pool:AcquireObject()
    
    if relativeControl then
        control:SetAnchor(TOPLEFT, relativeControl, BOTTOMLEFT, 0, PADDING)
    else
        control:SetAnchor(TOPLEFT, self.listControl, TOPLEFT, 0, PADDING)
    end

    control.key = key
    control.templateName = templateName
    control.dataIndex = dataIndex

    return control, true
end

function ZO_PagedList:ReleaseControl(control)
    local templateName = control.templateName
    local pool = self.dataTypes[templateName].pool
    pool:ReleaseObject(control.key)
end

function ZO_PagedList:BuildPages()
    self.pages = {}

    local currPageHeight = 0
    local currPageNum = 1

    local pageWidth, pageHeight = self.listControl:GetDimensions()
    

    self.pages[currPageNum] = {startIndex = 1, count = 0}

    for i,data in ipairs(self.dataList) do
        local templateName = data.templateName

        local height = self.dataTypes[templateName].height
        if (currPageHeight + height) > pageHeight then
            currPageHeight = 0
            currPageNum = currPageNum + 1
            self.pages[currPageNum] = {startIndex = i, count = 0}
        end

        currPageHeight = currPageHeight + height
        self.pages[currPageNum].count = self.pages[currPageNum].count + 1
    end

    if(self.emptyRow) then
        self.emptyRow:SetHidden(#self.dataList > 0)
    end

    self.numPages = currPageNum

    if self.rememberSpot then
        self.currPageNum = zo_min(self.currPageNum, currPageNum)
    else
        self.currPageNum = 1
    end
end

local INCLUDE_SAVED_INDEX = true

function ZO_PagedList:BuildPage(pageNum)
    local savedIndex = self.focus:GetFocus(INCLUDE_SAVED_INDEX)
    self.focus:RemoveAllEntries()
    for templateName, dataTypeInfo in pairs(self.dataTypes) do
        dataTypeInfo.pool:ReleaseAllObjects()
    end

    local page = self.pages[pageNum]

    local lastIndex = (page.startIndex + page.count - 1)
    local previousControl
    for i = page.startIndex, lastIndex do
        
        local data = self.dataList[i]
        local control = self:AcquireControl(i, previousControl)
        data.control = control
        local selected = self:IsSelected(data.data)
        self.dataTypes[control.templateName].setupCallback(control, data.data, selected)
        local entry = {
            control = control,
            highlight = control:GetNamedChild("Highlight"),
            data = data,
            activate = self.onEnterRow,
            deactivate = self.onLeaveRow,
        }
        self.focus:AddEntry(entry)

        previousControl = control

        if(self.alternateRowBackgrounds) then
            local rowBackground = GetControl(control, "BG")
            if(rowBackground) then
                local hidden = (i % 2) == 0
                rowBackground:SetHidden(hidden)
            end
        end
    end

    if self.rememberSpot then
        local itemsOnPage = self.focus:GetItemCount()
        if savedIndex then
            savedIndex = zo_min(savedIndex, itemsOnPage)
        end

        self.focus:SetFocusByIndex(savedIndex or 1)
    else
        self.focus:SetFocusByIndex(1)
    end
end

function ZO_PagedList:RefreshSelectedRow()
    local focusItem = self.focus:GetFocusItem()
    if focusItem then
        local selected = self:IsSelected(focusItem.data.data)
        self.dataTypes[focusItem.control.templateName].setupCallback(focusItem.control, focusItem.data.data, selected)
    end
end

function ZO_PagedList:OnSortHeaderClicked(key, order)
    self.currentSortKey = key
    self.currentSortOrder = order
    self:RefreshSort()
end

function ZO_PagedList:CompareSortEntries(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, self.sortKeys, self.currentSortOrder)
end

function ZO_PagedList:SetEmptyText(emptyText, template)
    if not self.emptyRow then
        self.emptyRow = CreateControlFromVirtual("$(parent)EmptyRow", self.focus.control, template)
    end
    GetControl(self.emptyRow, "Message"):SetText(emptyText)
end

function ZO_PagedList:RefreshFooter()
    if not self.footer then return end

    local enablePrevious = self.currPageNum > 1
    self.footer.previousButton:SetEnabled(enablePrevious)

    local enableNext = self.currPageNum < #self.pages
    self.footer.nextButton:SetEnabled(enableNext)
    
    local pageNumberText = zo_strformat(SI_GAMEPAD_PAGED_LIST_PAGE_NUMBER, self.currPageNum)
    self.footer.pageNumberLabel:SetText(pageNumberText)

    self.footer.control:SetHidden(#self.pages <= 1)
end

function ZO_PagedList:SetAlternateRowBackgrounds(alternate)
    self.alternateRowBackgrounds = alternate
end

function ZO_PagedList:SetPlaySoundFunction(fn)
    self.onPlaySoundFunction = fn
end

function ZO_PagedList:SetRememberSpotInList(rememberSpot)
    self.rememberSpot = rememberSpot
end
