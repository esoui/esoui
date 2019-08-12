local DEFAULT_TEMPLATE = "ZO_GamepadItemSubEntryTemplate"
local DEFAULT_HEADER_TEMPLATE = "ZO_GamepadMenuEntryHeaderTemplate"

ZO_GamepadInventoryList = ZO_CallbackObject:Subclass()

function ZO_GamepadInventoryList:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

--[[
Initializes the ZO_GamepadInventoryList. This should not be called directly, as it will be called be New().

control must be an XML control for intializing a parameteric list.
inventoryType must be one of the Bag enum values, or a table containing multiple bag enum values.
selectedDataCallback may be a function to call when the selected item has changed. May be nil.
entryEditCallback may be a function to call when initializing the ZO_GamepadEntryData for display.
    If specified, it should take a single argument which will be the ZO_GamepadEntryData, and will
    be called after entry:InitializeInventoryVisualData() and entry.itemData is set. May be nil.
categorizationFunction may be a function to call to retrieve the category string for an inventory
    item. If specified, should take a inventoryData (as returned by SHARED_INVENTORY:GenerateSingleSlotData)
    and return a string category. If nil, defaults to ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription().
sortFunction may be a function that is passed to table.sort to sort the entries for display. If nil, a default
    will be used tgat will sort alphabetically by category than by name.
useTriggers: Should the control bind the triggers to jump categories when activated? If nil, defaults to true.
]]
function ZO_GamepadInventoryList:Initialize(control, inventoryType, slotType, selectedDataCallback, entrySetupCallback, categorizationFunction, sortFunction, useTriggers, template, templateSetupFunction)
    self.control = control
    self.selectedDataCallback = selectedDataCallback
    self.entrySetupCallback = entrySetupCallback
    self.categorizationFunction = categorizationFunction
    self.sortFunction = sortFunction
    self.dataByBagAndSlotIndex = {}
    self.isDirty = true
    self.useTriggers = (useTriggers ~= false) -- nil => true
    self.template = template or DEFAULT_TEMPLATE

    if type(inventoryType) == "table" then
        self.inventoryTypes = inventoryType
    else
        self.inventoryTypes = { inventoryType }
    end

    for i, bagId in ipairs(self.inventoryTypes) do
        self.dataByBagAndSlotIndex[bagId] = {}
    end

    local function VendorEntryTemplateSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_Inventory_BindSlot(data, slotType, data.slotIndex, data.bagId)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    end

    self.list = ZO_GamepadVerticalParametricScrollList:New(self.control)
    self.list:AddDataTemplate(self.template, templateSetupFunction or VendorEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.list:AddDataTemplateWithHeader(self.template, templateSetupFunction or VendorEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, DEFAULT_HEADER_TEMPLATE)

    -- generate the trigger keybinds so we can add/remove them later when necessary
    self.triggerKeybinds = {}
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.triggerKeybinds, self.list)

    local function SelectionChangedCallback(list, selectedData)
        if self.selectedDataCallback then
            self.selectedDataCallback(list, selectedData)
        end
        if selectedData then
            GAMEPAD_INVENTORY:PrepareNextClearNewStatus(selectedData)
            self:GetParametricList():RefreshVisible()
        end
    end

    local function OnEffectivelyShown()
        if self.isDirty then
            self:RefreshList()
        elseif self.selectedDataCallback then
            self.selectedDataCallback(self.list, self.list:GetTargetData())
        end
        self:Activate()
    end

    local function OnEffectivelyHidden()
        GAMEPAD_INVENTORY:TryClearNewStatusOnHidden()
        self:Deactivate()
    end

    local function OnInventoryUpdated(bagId)
        for k, inventoryType in ipairs(self.inventoryTypes) do
            if bagId == inventoryType then
                self:RefreshList()
                break
            end
        end
    end

    local function OnSingleSlotInventoryUpdate(bagId, slotIndex)
        for k, inventoryType in ipairs(self.inventoryTypes) do
            if bagId == inventoryType then
                local bag = self.dataByBagAndSlotIndex[bagId]
                --we should always have a bag table to match all entries in self.inventoryTypes but this will catch any issue with that
                internalassert(bag ~= nil)
                if bag then
                    local entry = bag[slotIndex]
                    if entry then
                        local itemData = SHARED_INVENTORY:GenerateSingleSlotData(inventoryType, slotIndex)
                        if itemData then
                            itemData.bestGamepadItemCategoryName = ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription(itemData)
                            self:SetupItemEntry(entry, itemData)
                            self.list:RefreshVisible()
                        else -- The item was removed.
                            self:RefreshList()
                        end
                    else -- The item is new.
                        self:RefreshList()
                    end
                    -- don't loop over any more inventoryTypes, we've handled the slot update
                    break
                end
            end
        end
    end

    self:SetOnSelectedDataChangedCallback(SelectionChangedCallback)

    self.control:SetHandler("OnEffectivelyShown", OnEffectivelyShown)
    self.control:SetHandler("OnEffectivelyHidden", OnEffectivelyHidden)

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", OnSingleSlotInventoryUpdate)
end

function ZO_GamepadInventoryList:ClearInventoryTypes()
    self.inventoryTypes = {}
    self:RefreshList()
end

function ZO_GamepadInventoryList:SetInventoryTypes(inventoryTypes)
    local newInventoryTypes
    if type(inventoryTypes) == "table" then
        newInventoryTypes = inventoryTypes
    else
        newInventoryTypes = { inventoryTypes }
    end

    if newInventoryTypes then
        local sameBags = true
        for i, newBag in ipairs(newInventoryTypes) do
             if self.inventoryTypes[i] ~= newBag then
                sameBags = false
                break
             end
        end
        if not sameBags then
            self.inventoryTypes = newInventoryTypes
            --Refresh list will also regenerate these tables for each bag, but if the inventory list is hidden it will set a dirty flag instead and do it when it is effectively shown. This is a problem
            --when a single slot update occurs because it checks self.inventoryTypes to know if we have a bag table in dataByBagAndSlotIndex to work with but we haven't rebuilt dataByBagAndSlotIndex yet
            -- so we end up with an index on a bag table that doesn't exist. So we rebuild dataByBagAndSlotIndex immediately here.
            self.dataByBagAndSlotIndex = {}
            for i, bagId in ipairs(self.inventoryTypes) do
                self.dataByBagAndSlotIndex[bagId] = {}
            end
            self:RefreshList()
            return true
        end
    end

    return false
end

function ZO_GamepadInventoryList:AddInventoryType(inventoryType)
    if self.inventoryTypes then
        table.insert(self.inventoryTypes, inventoryType)
    else
        self.inventoryTypes = {inventoryType}
    end

    self:RefreshList()
end

--[[
Add a function called when the selected item is changed.
]]--
function ZO_GamepadInventoryList:SetOnSelectedDataChangedCallback(selectedDataCallback)
    self.list:SetOnSelectedDataChangedCallback(selectedDataCallback)
end

--[[
Remove a function called when the selected item is changed.
]]--
function ZO_GamepadInventoryList:RemoveOnSelectedDataChangedCallback(selectedDataCallback)
    self.list:RemoveOnSelectedDataChangedCallback(selectedDataCallback)
end

--[[
Add a function called when the target data is changed.
]]--
function ZO_GamepadInventoryList:SetOnTargetDataChangedCallback(selectedDataCallback)
    self.list:SetOnTargetDataChangedCallback(selectedDataCallback)
end

--[[
Remove a function called when the target data is changed.
]]--
function ZO_GamepadInventoryList:RemoveOnTargetDataChangedCallback(selectedDataCallback)
    self.list:RemoveOnTargetDataChangedCallback(selectedDataCallback)
end

--[[
categorizationFunction function may be a function which takes a inventory data and returns
    a category string.
]]--
function ZO_GamepadInventoryList:SetCategorizationFunction(categorizationFunction)
    self.categorizationFunction = categorizationFunction
    self:RefreshList()
end

--[[
Sets the function which is passed to table.sort() when sorting the inventory inventory items.
]]--
function ZO_GamepadInventoryList:SetSortFunction(sortFunction)
    self.sortFunction = sortFunction
    self:RefreshList()
end

--[[
entryEditCallback may be a function to call when initializing the ZO_GamepadEntryData for display.
    If specified, it should take a single argument which will be the ZO_GamepadEntryData, and will
    be called after entry:InitializeInventoryVisualData() and entry.itemData is set. May be nil.
]]--
function ZO_GamepadInventoryList:SetEntrySetupCallback(entrySetupCallback)
    self.entrySetupCallback = entrySetupCallback
    self:RefreshList()
end

--[[
itemFilterFunction function may be a function which takes an inventory data and returns whether to
    include the item in the inventory list. If set to nil, all items will be included.
]]--
function ZO_GamepadInventoryList:SetItemFilterFunction(itemFilterFunction)
    self.itemFilterFunction = itemFilterFunction
    self:RefreshList()
end

--[[
Sets whether to bind the triggers to jump categories while the list is active.

If the list is currently active, this will add/remove the bindings immediately.
]]--
function ZO_GamepadInventoryList:SetUseTriggers(useTriggers)
    if self.useTriggers == useTriggers then -- Exit out if no change, to simplify later logic.
        return
    end

    self.useTriggers = useTriggers
    if self.list:IsActive() then
        if useTriggers then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.triggerKeybinds)
        else
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.triggerKeybinds)
        end
    end
end

--[[
Returns the currently selected entry's data.
]]--
function ZO_GamepadInventoryList:GetTargetData()
    return self.list:GetTargetData()
end

--[[
Returns the underlying parameteric list.
]]--
function ZO_GamepadInventoryList:GetParametricList()
    return self.list
end

--[[
Moves the selection to the next item.
]]--
function ZO_GamepadInventoryList:MoveNext()
    return self.list:MoveNext()
end

--[[
Moves the selection to the previous item.
]]--
function ZO_GamepadInventoryList:MovePrevious()
    return self.list:MovePrevious()
end

--[[
Query if the inventory list is empty
]]--
do
    local function HasSlotData(inventoryType, slotIndex, filterFunction)
        local slotData = SHARED_INVENTORY:GenerateSingleSlotData(inventoryType, slotIndex)
        if slotData then
            if (not filterFunction) or filterFunction(slotData) then
                return true
            end
        end
        return false
    end

    function ZO_GamepadInventoryList:IsEmpty()
        for k, bagId in ipairs(self.inventoryTypes) do
            local filterFunction = self.itemFilterFunction
            for slotIndex in ZO_IterateBagSlots(bagId) do
                if HasSlotData(bagId, slotIndex, filterFunction) then
                    return false
                end
            end
        end

        return true
    end
end

--[[
Passthrough functions for operating on the parametric list itself
]]--
function ZO_GamepadInventoryList:SetFirstIndexSelected(...)
    self.list:SetFirstIndexSelected(...)
end

function ZO_GamepadInventoryList:SetLastIndexSelected(...)
    self.list:SetLastIndexSelected(...)
end

function ZO_GamepadInventoryList:SetPreviousSelectedDataByEval(...)
    return self.list:SetPreviousSelectedDataByEval(...)
end

function ZO_GamepadInventoryList:SetNextSelectedDataByEval(...)
    return self.list:SetNextSelectedDataByEval(...)
end

--[[
Moves the selection to the specified item.

The same arguments can be provided as ZO_ParametricScrollList.SetSelectedIndex() accepts.
]]--
function ZO_GamepadInventoryList:SetSelectedIndex(...)
    self.list:SetSelectedIndex(...)
end

--[[
Activates the inventory list.
]]--
function ZO_GamepadInventoryList:Activate()
    self.list:Activate()
    if self.useTriggers then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.triggerKeybinds)
    end
end

--[[
Deactivates the inventory list.
]]--
function ZO_GamepadInventoryList:Deactivate()
    if self.useTriggers then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.triggerKeybinds)
    end
    self.list:Deactivate()
end

--[[
An internal helper function used to initialize or update a ZO_GamepadEntryData
 with itemData.
]]--
function ZO_GamepadInventoryList:SetupItemEntry(entry, itemData)
    entry:InitializeInventoryVisualData(itemData)
    entry.itemData = itemData
    if self.entrySetupCallback then
        self.entrySetupCallback(entry)
    end
end

local DEFAULT_GAMEPAD_ITEM_SORT =
{
    bestGamepadItemCategoryName = { tiebreaker = "name" },
    name = { tiebreaker = "requiredLevel" },
    requiredLevel = { tiebreaker = "requiredChampionPoints", isNumeric = true },
    requiredChampionPoints = { tiebreaker = "iconFile", isNumeric = true },
    iconFile = { tiebreaker = "uniqueId" },
    uniqueId = { isId64 = true },
}

local function ItemSortFunc(data1, data2)
     return ZO_TableOrderingFunction(data1, data2, "bestGamepadItemCategoryName", DEFAULT_GAMEPAD_ITEM_SORT, ZO_SORT_ORDER_UP)
end

function ZO_GamepadInventoryList:AddSlotDataToTable(slotsTable, inventoryType, slotIndex)
    local itemFilterFunction = self.itemFilterFunction
    local categorizationFunction = self.categorizationFunction or ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription
    local slotData = SHARED_INVENTORY:GenerateSingleSlotData(inventoryType, slotIndex)
    if slotData then
        if (not itemFilterFunction) or itemFilterFunction(slotData) then
            -- itemData is shared in several places and can write their own value of bestItemCategoryName.
            -- We'll use bestGamepadItemCategoryName instead so there are no conflicts.
            slotData.bestGamepadItemCategoryName = categorizationFunction(slotData)

            table.insert(slotsTable, slotData)
        end
    end
end

function ZO_GamepadInventoryList:GenerateSlotTable()
    local slots = {}

    for k, bagId in ipairs(self.inventoryTypes) do
        for slotIndex in ZO_IterateBagSlots(bagId) do
            self:AddSlotDataToTable(slots, bagId, slotIndex)
        end
    end

    table.sort(slots, self.sortFunction or ItemSortFunc)
    return slots
end

--[[
If the list is hidden, queues a refresh for the next time the list is shown.
 Otherwise, clears and fully refreshes the list.
]]--
function ZO_GamepadInventoryList:RefreshList()
    if self.control:IsHidden() then
        self.isDirty = true
        return
    end
    self.isDirty = false

    self.list:Clear()
    for i, bagId in ipairs(self.inventoryTypes) do
        self.dataByBagAndSlotIndex[bagId] = {}
    end

    local slots = self:GenerateSlotTable()
    local currentBestCategoryName = nil
    for i, itemData in ipairs(slots) do
        local entry = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
        self:SetupItemEntry(entry, itemData)

        if itemData.bestGamepadItemCategoryName ~= currentBestCategoryName then
            currentBestCategoryName = itemData.bestGamepadItemCategoryName
            entry:SetHeader(currentBestCategoryName)

            self.list:AddEntryWithHeader(self.template, entry)
        else
            self.list:AddEntry(self.template, entry)
        end

        self.dataByBagAndSlotIndex[itemData.bagId][itemData.slotIndex] = entry
    end

    self.list:Commit()
end

--[[
Refreshes the appearance of the list without clearing and fully refreshing the list
]]--
function ZO_GamepadInventoryList:RefreshVisible()
    self.list:RefreshVisible()
end

--[[
Enables or disables direcitonal input to the list.

enable must be a boolean.
]]--
function ZO_GamepadInventoryList:SetDirectionalInputEnabled(enable)
    self.list:SetDirectionalInputEnabled(enable)
end

--[[
Sets if the inventory list is aligned to the screen center.
Does not need an expectedEntryHeight
]]--
function ZO_GamepadInventoryList:SetAlignToScreenCenter(alignToScreenCenter, expectedEntryHeight)
    self.list:SetAlignToScreenCenter(alignToScreenCenter, expectedEntryHeight)
end

--[[
Gets the control of the list
]]--
function ZO_GamepadInventoryList:GetControl()
    return self.list:GetControl()
end

--[[
Returns true if the list is active
]]--
function ZO_GamepadInventoryList:IsActive()
    return self.list:IsActive()
end

function ZO_GamepadInventoryList:SetNoItemText(noItemText)
    self.list:SetNoItemText(noItemText)
end

function ZO_GamepadInventoryList:ClearList()
    self.list:Clear()
end