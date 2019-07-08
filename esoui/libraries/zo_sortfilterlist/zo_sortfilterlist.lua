----------------------
--Sort/Filter List
----------------------

local UPDATE_SORT = 1
local UPDATE_FILTER = 2
local UPDATE_DATA = 3

ZO_SortFilterList = ZO_SortFilterListBase:Subclass()

function ZO_SortFilterList:New(...)
    return ZO_SortFilterListBase.New(self, ...)
end

function ZO_SortFilterList:Initialize(control, ...)
    ZO_SortFilterListBase.Initialize(self, ...)
    self:InitializeSortFilterList(control, ...)
end

function ZO_SortFilterList:BuildMasterList()
    -- intended to be overriden
    -- should build the master list of data that is later filtered by FilterScrollList
end

function ZO_SortFilterList:FilterScrollList()
    -- intended to be overriden
    -- should take the master list data and filter it
end

function ZO_SortFilterList:SortScrollList()
    -- intended to be overriden
    -- should take the filtered data and sort it
end

function ZO_SortFilterList:InitializeSortFilterList(control)
    self.control = control
    self.list = GetControl(control, "List") 
    ZO_ScrollList_AddResizeOnScreenResize(self.list)

    self.headersContainer = GetControl(control, "Headers")
    if self.headersContainer then
        self.sortHeaderGroup = ZO_SortHeaderGroup:New(self.headersContainer, true)
        self.sortHeaderGroup:RegisterCallback(ZO_SortHeaderGroup.HEADER_CLICKED, function(key, order) self:OnSortHeaderClicked(key, order) end)
        self.sortHeaderGroup:AddHeadersFromContainer()
    end

    self.automaticallyColorRows = true
end

function ZO_SortFilterList:GetListControl()
    return self.list
end

function ZO_SortFilterList:ClearUpdateInterval()
    self.control:SetHandler("OnUpdate", nil)
    self.updateIntervalSecs = nil
end

function ZO_SortFilterList:SetUpdateInterval(updateIntervalSecs)
    local hadUpdateInterval = self.updateIntervalSecs ~= nil
    self.updateIntervalSecs = updateIntervalSecs

    if(not hadUpdateInterval) then
        self.updateIntervalLastUpdate = 0
        ZO_PreHookHandler(self.control, "OnUpdate", function(control, seconds)
            if(seconds > self.updateIntervalLastUpdate + self.updateIntervalSecs) then
                self.updateIntervalLastUpdate = seconds
                self:RefreshVisible()
            end
        end)
    end
end

function ZO_SortFilterList:SetAlternateRowBackgrounds(alternate)
    self.alternateRowBackgrounds = alternate
end

function ZO_SortFilterList:SetEmptyText(emptyText)
    if not self.emptyRow then
        self.emptyRow = CreateControlFromVirtual("$(parent)EmptyRow", self.list, "ZO_SortFilterListEmptyRow_Keyboard")
    end
    GetControl(self.emptyRow, "Message"):SetText(emptyText)
end

function ZO_SortFilterList:SetAutomaticallyColorRows(autoColorRows)
    self.automaticallyColorRows = autoColorRows
end

function ZO_SortFilterList:ShowMenu(...)
    if(not self.unlockSelectionCallback) then
        self.unlockSelectionCallback = function() self:UnlockSelection() end
    end

    SetMenuHiddenCallback(self.unlockSelectionCallback)
    if(ShowMenu(...)) then
        self:LockSelection()
    end
end

function ZO_SortFilterList:UpdatePendingUpdateLevel(pendingUpdate)
    if(self.pendingUpdate == nil or pendingUpdate > self.pendingUpdate) then
        self.pendingUpdate = pendingUpdate
    end
end

function ZO_SortFilterList:RefreshVisible()
    ZO_ScrollList_RefreshVisible(self.list)
end

function ZO_SortFilterList:RefreshSort()
    if(self:IsLockedForUpdates()) then
        self:UpdatePendingUpdateLevel(UPDATE_SORT)
        return
    end
    
    self:SortScrollList()
    self:CommitScrollList()
end

function ZO_SortFilterList:RefreshFilters()
    if(self:IsLockedForUpdates()) then
        self:UpdatePendingUpdateLevel(UPDATE_FILTER)
        return
    end

    self:FilterScrollList()
    self:SortScrollList()
    self:CommitScrollList()
end

function ZO_SortFilterList:RefreshData()
    if(self:IsLockedForUpdates()) then
        self:UpdatePendingUpdateLevel(UPDATE_DATA)
        return
    end

    self:BuildMasterList()
    self:FilterScrollList()
    self:SortScrollList()
    self:CommitScrollList()
end

function ZO_SortFilterList:CommitScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    for i = 1, #scrollData do
        scrollData[i].data.sortIndex = i
    end

    if(self.emptyRow) then
        self.emptyRow:SetHidden(#scrollData > 0)
    end

    if(self.mouseOverRow) then
        self:ExitRow(self.mouseOverRow)
    end

    ZO_ScrollList_Commit(self.list)
end

function ZO_SortFilterList:SetLockedForUpdates(locked)
    if(locked ~= self.lockedForUpdates) then
        self.lockedForUpdates = locked
        if(not locked) then
            if(self.mouseOverRow) then
                self:ExitRow(self.mouseOverRow)
            end
            
            if(self.pendingUpdate) then
                local pendingUpdate = self.pendingUpdate
                self.pendingUpdate = nil
                if(pendingUpdate == UPDATE_DATA) then
                    self:RefreshData()
                elseif(pendingUpdate == UPDATE_FILTER) then
                    self:RefreshFilters()
                elseif(pendingUpdate == UPDATE_SORT) then
                    self:RefreshSort()
                end
            end
        end
    end
end

function ZO_SortFilterList:IsLockedForUpdates()
    return self.lockedForUpdates
end

function ZO_SortFilterList:LockSelection()
    ZO_ScrollList_SetLockScrolling(self.list, true)
    ZO_ScrollList_SetLockHighlight(self.list, true)
    self:SetLockedForUpdates(true)
end

function ZO_SortFilterList:UnlockSelection()
    ZO_ScrollList_SetLockScrolling(self.list, false)
    ZO_ScrollList_SetLockHighlight(self.list, false)
    self:SetLockedForUpdates(false)

    local mouseOverRow = ZO_ScrollList_GetMouseOverControl(self.list)
    if mouseOverRow then
        self:EnterRow(mouseOverRow)
    end
end

function ZO_SortFilterList:OnSortHeaderClicked(key, order)
    self.currentSortKey = key
    self.currentSortOrder = order
    self:RefreshSort()
end

function ZO_SortFilterList:SetHighlightedRow(row)
    if self.mouseOverRow then
        self:ExitRow(self.mouseOverRow)
    end
    if row then
        self:EnterRow(row)
    end
end

function ZO_SortFilterList:EnterRow(row)
    if not self.lockedForUpdates then
        ZO_ScrollList_MouseEnter(self.list, row)
        local data = ZO_ScrollList_GetData(row)
        if(data) then
            self:ColorRow(row, ZO_ScrollList_GetData(row), true)
        end
        self.mouseOverRow = row
        self:UpdateKeybinds()
    end
end

function ZO_SortFilterList:ExitRow(row)
    if not self.lockedForUpdates then
        ZO_ScrollList_MouseExit(self.list, row)
        local data = ZO_ScrollList_GetData(row)
        if(data) then
            self:ColorRow(row, ZO_ScrollList_GetData(row), false)
        end
        self.mouseOverRow = nil
        self:UpdateKeybinds()
    end
end

function ZO_SortFilterList:SelectRow(row)
    ZO_ScrollList_MouseClick(self.list, row)
end

function ZO_SortFilterList:OnSelectionChanged(previouslySelected, selected)
    self.selectedData = selected
    self:RefreshVisible()
end

function ZO_SortFilterList:GetRowColors(data, mouseIsOver, control)
    local textColor = ZO_SECOND_CONTRAST_TEXT
    local iconColor = ZO_DEFAULT_ENABLED_COLOR
    if(mouseIsOver or data == self.selectedData) then
        textColor = ZO_SELECTED_TEXT
        iconColor = ZO_SELECTED_TEXT
    else
        if(control.normalColor) then
            textColor = control.normalColor
        end
    end

    return textColor, iconColor
end

function ZO_SortFilterList:ColorRow(control, data, mouseIsOver)
    if self.automaticallyColorRows then
        for i = 1, control:GetNumChildren() do
            local child = control:GetChild(i)
            if not child.nonRecolorable then
                local childType = child:GetType()
                local textColor, iconColor = self:GetRowColors(data, mouseIsOver, child)
                if(childType == CT_LABEL and textColor ~= nil) then
                    local r, g, b = textColor:UnpackRGB() 
                    child:SetColor(r, g, b, child:GetControlAlpha())
                elseif(childType == CT_TEXTURE and iconColor ~= nil) then
                    local r, g, b = iconColor:UnpackRGB() 
                    child:SetColor(r, g, b, child:GetControlAlpha())
                end
            end
        end
    end
end

function ZO_SortFilterList:SetupRow(control, data)
    local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
    local mocBelongsToRow = false
    while(mouseOverControl ~= nil) do
        if(mouseOverControl == control) then
            mocBelongsToRow = true
            break
        end
        mouseOverControl = mouseOverControl:GetParent()
    end

    if(self.lockedForUpdates) then
        self:ColorRow(control, data, self.mouseOverRow == control)
    else
        if(mocBelongsToRow) then
            self:EnterRow(control)
        else 
            self:ColorRow(control, data, false)
        end
    end

    if(self.alternateRowBackgrounds) then
        local bg = GetControl(control, "BG")
        local hidden = (data.sortIndex % 2) == 0
        bg:SetHidden(hidden)
    end
end

function ZO_SortFilterList:GetSelectedData()
    return ZO_ScrollList_GetSelectedData(self.list)
end

function ZO_SortFilterList:HasEntries()
    local dataList = ZO_ScrollList_GetDataList(self.list)
    return #dataList > 0
end

function ZO_SortFilterList:SetKeybindStripDescriptor(keybindStripDescriptor)
    self.keybindStripDescriptor = keybindStripDescriptor
end

function ZO_SortFilterList:SetKeybindStripId(keybindStripId)
    self.keybindStripId = keybindStripId
end

function ZO_SortFilterList:AddKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor, self.keybindStripId)
    end
end

function ZO_SortFilterList:RemoveKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor, self.keybindStripId)
    end
end

function ZO_SortFilterList:UpdateKeybinds()
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor, self.keybindStripId)
    end
end

--XML

function ZO_SortFilterList:Row_OnMouseEnter(control)
    self:EnterRow(control)
end

function ZO_SortFilterList:Row_OnMouseExit(control)
    self:ExitRow(control)
end
