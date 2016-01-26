--[[
    This list box does not use a ScrollControl.  It is intended for large collections of data
    when it would be more costly to create a Control-container for each row than it would be
    to set the data (i.e. text and icons) on each row as the list is scrolled.
--]]

local DEFAULT_ROW_PADDING = 2

local function CreateListBoxRows(listBox)
    local desiredRowCount   = listBox.m_RowCount
    local existingRowCount  = #(listBox.m_Rows)
    local needRowCount      = desiredRowCount - existingRowCount
    
    if(needRowCount > 0)
    then
        local newRow
        local rowId
        local container     = listBox.m_Container
        local baseRowName   = container:GetName()
        local template      = listBox.m_RowTemplate
        local previousRow   = listBox.m_Rows[existingRowCount]
        
        for i = 1, needRowCount
        do
            rowId = i + existingRowCount
            
            newRow = CreateControlFromVirtual(baseRowName.."Row"..rowId, container, template)
            
            if(newRow)
            then
                table.insert(listBox.m_Rows, newRow)
                
                if(previousRow)
                then
                    newRow:SetAnchor(TOPLEFT, previousRow, BOTTOMLEFT, 0, listBox.m_RowPadding)
                else
                    newRow:SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)
                end                
            end
            
            previousRow = newRow
        end
    end
end

ZO_ListBox = ZO_Object:Subclass()

function ZO_ListBox:New(rowTemplate, container, displayedRowCount, maxRowCount, rowPopulationFunction, scrollUpdateFunction, rowPadding)
    local listBox = ZO_Object.New(self)
    
    if(maxRowCount < displayedRowCount)
    then
        maxRowCount = displayedRowCount
    end
    
    listBox.m_RowTemplate           = rowTemplate
    listBox.m_RowCount              = displayedRowCount
    listBox.m_MaxRowCount           = maxRowCount
    listBox.m_Rows                  = {}
    listBox.m_RowPopulationFunction = rowPopulationFunction
    listBox.m_ScrollUpdateFunction  = scrollUpdateFunction
    listBox.m_Container             = container
    listBox.m_ScrollPosition        = 1
    listBox.m_MaxScrollPosition     = listBox.m_MaxRowCount - listBox.m_RowCount + 1
    listBox.m_RowPadding            = rowPadding or DEFAULT_ROW_PADDING
    
    CreateListBoxRows(listBox)
    
    listBox:Refresh()
    return listBox
end

function ZO_ListBox:SetScrollUpdateFunction(updateFunction)
    self.m_ScrollUpdateFunction = updateFunction
end

function ZO_ListBox:SetPopulatorFunction(populatorFunction)
    self.m_RowPopulationFunction = populatorFunction
end

function ZO_ListBox:GetScrollExtents()
    return self.m_ScrollPosition, self.m_ScrollPosition + self.m_RowCount - 1, self.m_MaxScrollPosition
end

local function SetScrollPosition(listObject, newScroll)
    if(newScroll < 1)
    then
        newScroll = 1
    elseif(newScroll > listObject.m_MaxScrollPosition)
    then
        newScroll = listObject.m_MaxScrollPosition
    end
    
    if(newScroll ~= listObject.m_ScrollPosition)
    then
        listObject.m_ScrollPosition = newScroll
        listObject:Refresh()
    end
end

function ZO_ListBox:ScrollTo(newScrollPosition)
    SetScrollPosition(self, newScrollPosition)
end

function ZO_ListBox:Scroll(scrollByRows)
    SetScrollPosition(self, self.m_ScrollPosition + scrollByRows)
end

function ZO_ListBox:Refresh()
    local currentRow = 1
    local currentRowControl
    local finalPosition = self.m_ScrollPosition + self.m_RowCount
    
    for i = self.m_ScrollPosition, finalPosition
    do
        currentRowControl = self.m_Rows[currentRow]
        
        if(currentRowControl)
        then
            -- The population function returns whether or not the row should be shown.
            currentRowControl:SetHidden(self.m_RowPopulationFunction(currentRowControl, i))
        end
        
        currentRow = currentRow + 1
    end
    
    local rowCount = #(self.m_Rows)
    
    while(currentRow < rowCount)
    do
        currentRow = currentRow + 1
        currentRowControl:SetHidden(true)
    end
    
    if(self.m_ScrollUpdateFunction)
    then 
        self.m_ScrollUpdateFunction(self.m_Container, self.m_ScrollPosition, self.m_MaxScrollPosition)
    end
end

function ZO_ListBox:SetMaxRows(maxRows)
    if(maxRows and (maxRows ~= self.m_MaxRowCount))
    then
        if(maxRows < self.m_RowCount)
        then
            self.m_MaxScrollPosition = 1
        else
            self.m_MaxScrollPosition = maxRows - self.m_RowCount + 1
        end
        
        self.m_MaxRowCount = maxRows

        if(self.m_ScrollPosition > self.m_MaxScrollPosition)
        then
            self.m_ScrollPosition = self.m_MaxScrollPosition
        end
    end
end
