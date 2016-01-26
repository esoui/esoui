ZO_ListDialog = ZO_Object:Subclass()

LIST_DIALOG_CUSTOM_CONTROL_LOCATION_TOP = 1
LIST_DIALOG_CUSTOM_CONTROL_LOCATION_BOTTOM = 2

function ZO_ListDialog:New(...)
    local listDialog = ZO_Object.New(self)
    listDialog:Initialize(...)
    return listDialog
end

local SCROLL_TYPE_ITEM = 1

local listDialogId = 1
function ZO_ListDialog:Initialize(listTemplate, listItemHeight, listSetupFunction)
    self.control = CreateControlFromVirtual("ZO_ListDialog", GuiRoot, "ZO_ListDialogTemplate", listDialogId)
    self.control.owner = self
    listDialogId = listDialogId + 1
    
    self.aboveText = self.control:GetNamedChild("AboveText")
    self.belowText = self.control:GetNamedChild("BelowText")

    self.firstButton = self.control:GetNamedChild("Button1")
    self.secondButton = self.control:GetNamedChild("Button2")

    self.list = self.control:GetNamedChild("List")
    ZO_ScrollList_SetHeight(self.list, self.list:GetHeight())

    self.emptyListText = self.control:GetNamedChild("EmptyListText")

    self.topCustomControlContainer = self.control:GetNamedChild("TopCustomControlContainer")
    self.bottomCustomControlContainer = self.control:GetNamedChild("BottomCustomControlContainer")

    self.customControls = {}

    local function OnMouseUp(rowControl, button, upInside)
        if upInside then
            local data = ZO_ScrollList_GetData(rowControl)
            ZO_ScrollList_SelectData(self.list, data, rowControl)
        end
    end

    local function Setup(rowControl, ...)
        rowControl:SetHandler("OnMouseUp", OnMouseUp)
        listSetupFunction(rowControl, ...)
    end
    ZO_ScrollList_AddDataType(self.list, SCROLL_TYPE_ITEM, listTemplate, listItemHeight, Setup)
    self.listItemHeight = listItemHeight

    self.minVisibleItems = zo_max(zo_floor(220 / listItemHeight), 2)
    self.maxVisibleItems = zo_max(zo_floor(300 / listItemHeight), self.minVisibleItems)

    local function OnListSelection(previouslySelected, selected)
        self.selectedItem = selected
        ZO_ScrollList_RefreshVisible(self.list)
        if self.onSelectedCallback then
            self.onSelectedCallback(selected)
        end
    end
	    
	ZO_ScrollList_EnableSelection(self.list, nil, OnListSelection)
end

function ZO_ListDialog:SetAboveText(text)
    self.aboveText:SetText(text)
end

function ZO_ListDialog:SetBelowText(text)
    self.belowText:SetText(text)
end

function ZO_ListDialog:GetButton(index)
    if index == 1 then
        return self.firstButton
    elseif index == 2 then
        return self.secondButton
    end
end

function ZO_ListDialog:SetFirstButtonEnabled(enabled)
    self.firstButton:SetEnabled(enabled)
end

function ZO_ListDialog:SetSecondButtonEnabled(enabled)
    self.firstButton:SetEnabled(enabled)
end

function ZO_ListDialog:SetEmptyListText(text)
    self.emptyListText:SetText(text)
end

function ZO_ListDialog:ClearList()
    ZO_ScrollList_Clear(self.list)
end

function ZO_ListDialog:CommitList(sortFunction)
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    local numListItems = #scrollData
    self.list:SetHeight(self.listItemHeight * zo_clamp(numListItems, self.minVisibleItems, self.maxVisibleItems))
    ZO_ScrollList_SetHeight(self.list, self.list:GetHeight())

    if sortFunction then
        table.sort(scrollData, sortFunction)
    end

    ZO_ScrollList_Commit(self.list)
    self.emptyListText:SetHidden(numListItems > 0)
end

function ZO_ListDialog:AddListItem(itemData)
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(SCROLL_TYPE_ITEM, itemData)
end

function ZO_ListDialog:AddCustomControl(control, location)
    if self.customControls[location] then
        self.customControls[location]:ClearAnchors()
    end
    local container = self:GetCustomContainerFromLocation(location)
    control:ClearAnchors()
    control:SetAnchor(TOP, container, TOP)
    control:SetParent(container)

    self.customControls[location] = control
end

function ZO_ListDialog:GetCustomContainerFromLocation(location)
    if location == LIST_DIALOG_CUSTOM_CONTROL_LOCATION_TOP then
        return self.topCustomControlContainer
    elseif location == LIST_DIALOG_CUSTOM_CONTROL_LOCATION_BOTTOM then
        return self.bottomCustomControlContainer
    end
end

function ZO_ListDialog:GetSelectedItem()
    return self.selectedItem
end

function ZO_ListDialog:SetOnSelectedCallback(selectedCallback)
    self.onSelectedCallback = selectedCallback
end

function ZO_ListDialog:SetHidden(hidden)
    self.control:SetHidden(hidden)
end

function ZO_ListDialog:GetControl()
    return self.control
end

local function ClearCustomControl(control)
    if control then
        control:ClearAnchors()
        control:SetParent(nil)
        control:SetHidden(true)
    end
end

function ZO_ListDialog:OnHide()
    self.aboveText:SetText("")
    self.belowText:SetText("")

    self.firstButton:SetEnabled(true)
    self.secondButton:SetEnabled(true)

    self.emptyListText:SetText("")

    self.selectedItem = nil
    self.onSelectedCallback = nil

    self.customControls[LIST_DIALOG_CUSTOM_CONTROL_LOCATION_TOP] = ClearCustomControl(self.customControls[LIST_DIALOG_CUSTOM_CONTROL_LOCATION_TOP])
    self.customControls[LIST_DIALOG_CUSTOM_CONTROL_LOCATION_BOTTOM] = ClearCustomControl(self.customControls[LIST_DIALOG_CUSTOM_CONTROL_LOCATION_BOTTOM])

    self:ClearList()
end

function ZO_ListDialog_OnHide(dialog)
    dialog.owner:OnHide()
end