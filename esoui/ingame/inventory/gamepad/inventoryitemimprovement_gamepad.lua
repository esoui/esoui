ZO_GAMEPAD_ITEM_IMPROVEMENT_DESCRIPTION_Y_OFFSET = 15
local NO_MESSAGE = ""

ZO_InventoryItemImprovement_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_InventoryItemImprovement_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_InventoryItemImprovement_Gamepad:Initialize(control, title, sceneName, message, noItemMessage, confirmString, improvementSound, 
                                                        improvementKitPredicate, sortComparator)
    self.isInitialized = false
    self.sceneName = sceneName
    self.message = message
    self.noItemMessage = noItemMessage
    self.confirmString = confirmString
    self.improvementSound = improvementSound
    self.improvementKitPredicate = improvementKitPredicate
    self.sortComparator = sortComparator

    self.headerData = {
        titleText = title,
        messageText = self.message
    }

    self:SetupScene(OnStateChanged)

    local DONT_CREATE_TAB_BAR = false
    local ACTIVATE_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, DONT_CREATE_TABBAR, ACTIVATE_ON_SHOW, self:GetScene())
end

function ZO_InventoryItemImprovement_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(
            function() 
                SCENE_MANAGER:HideCurrentScene()
            end),
        {
            name = self.confirmString,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:ImproveItem()
            end,
            visible = function()
                return self.itemList:GetNumItems() > 0
            end
        }
    }

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.itemList)
end

function ZO_InventoryItemImprovement_Gamepad:PerformDeferredInitialization()
    if self.isInitialized then return end
    
    self.enumeratedList = {}
    self.currentEntrySubLabels = {}
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    self.isInitialized = true
end

function ZO_InventoryItemImprovement_Gamepad:GetScene()
    return SCENE_MANAGER:GetScene(self.sceneName)
end

function ZO_InventoryItemImprovement_Gamepad:SetupList(list)
    local function ItemSetupFunc(control, data, selected, ...)
        control.selected = selected
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, ...)
    end
    
    list:AddDataTemplate(self:GetItemTemplateName(), ItemSetupFunc)
    self.itemList = list
    self.itemList:SetNoItemText(self.noItemMessage)
end

function ZO_InventoryItemImprovement_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self:ClearTooltip()

    if selectedData then
        self.improvementKitBag = selectedData.bag
        self.improvementKitIndex = selectedData.index
        self:UpdateTooltipOnSelectionChanged()
    end
end

function ZO_InventoryItemImprovement_Gamepad:Hide()
    SCENE_MANAGER:Hide(self.sceneName)
end

function ZO_InventoryItemImprovement_Gamepad:Show()
    SCENE_MANAGER:Push(self.sceneName)
end

function ZO_InventoryItemImprovement_Gamepad:SetMessage(message)
    self.headerData.messageText = message
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_InventoryItemImprovement_Gamepad:SetMessageHidden(isHidden)
    if isHidden then
        self:SetMessage(NO_MESSAGE)
    else
        self:SetMessage(self.message)
    end
end

function ZO_InventoryItemImprovement_Gamepad:CheckEmptyList()
    if self.itemList:GetNumItems() > 0 then
        self:SetMessageHidden(false)
    else
        self:SetMessageHidden(true)
    end
end

function ZO_InventoryItemImprovement_Gamepad:AddEntry(entry)
    self.itemList:AddEntry(self:GetItemTemplateName(), entry)
end

function ZO_InventoryItemImprovement_Gamepad:CommitList()
    self.itemList:Commit()
    self:CheckEmptyList()
end

function ZO_InventoryItemImprovement_Gamepad:BuildList()
    local itemList = PLAYER_INVENTORY:GenerateListOfVirtualStackedItems(INVENTORY_BACKPACK, self.improvementKitPredicate)
    ZO_ClearTable(self.enumeratedList)
    self:BuildEnumeratedImprovementKitList(itemList)
    table.sort(self.enumeratedList, self.sortComparator)

    for _, itemInfo in ipairs(self.enumeratedList) do
        local itemLink = GetItemLink(itemInfo.bag, itemInfo.index)
        local icon, _, _, _, _, _, _, quality = GetItemInfo(itemInfo.bag, itemInfo.index)
        local itemName = zo_strformat(SI_LINK_FORMAT_ITEM_NAME, self:GetItemName(itemInfo))
        local entry = ZO_GamepadEntryData:New(itemName, icon)
        ZO_ClearTable(self.currentEntrySubLabels)
        self:AddItemKitSubLabelsToCurrentEntry(itemLink)
        self:InitializeImprovementKitVisualData(entry, itemInfo.bag, itemInfo.index, itemInfo.stack, quality, self.currentEntrySubLabels)
        self:AddEntry(entry)
    end
end

function ZO_InventoryItemImprovement_Gamepad:UpdateList()
    self.itemList:Clear()
    self:BuildList()
    self:CommitList()
end

function ZO_InventoryItemImprovement_Gamepad:PerformUpdate()
    self:PerformDeferredInitialization()
    self:ClearTooltip()
    self:ResetTooltipToDefault()
    self:UpdateList()
end

function ZO_InventoryItemImprovement_Gamepad:ImproveItem()
    if self.improvementKitBag and self.itemBag then
        self:PerformItemImprovement()
        PlaySound(self.improvementSound)
        self:Hide()
    end
end

function ZO_InventoryItemImprovement_Gamepad:BeginItemImprovement(bag, index)
    self.itemBag = bag
    self.itemIndex = index
    self:Show()
end

function ZO_InventoryItemImprovement_Gamepad:AddSubLabel(subLabelText)
    table.insert(self.currentEntrySubLabels, subLabelText)
end

function ZO_InventoryItemImprovement_Gamepad:AddEmptySubLabel()
    self:AddSubLabel("")
end

-- These functions may be overridden

function ZO_InventoryItemImprovement_Gamepad:AddItemKitSubLabelsToCurrentEntry(itemLink)
    local requiredLevel = GetItemLinkRequiredLevel(itemLink)
    local requiredVeteranRank = GetItemLinkRequiredVeteranRank(itemLink)

    if requiredVeteranRank > 0 then
        local failed = requiredVeteranRank > GetUnitVeteranRank("player")
        local rankString = failed and ZO_ERROR_COLOR:Colorize(requiredVeteranRank) or ZO_DEFAULT_ENABLED_COLOR:Colorize(requiredVeteranRank)
        self:AddSubLabel(GetString(SI_ITEM_FORMAT_STR_RANK))
        self:AddSubLabel(rankString)
    elseif requiredLevel > 0 then
        local failed = requiredLevel > GetUnitLevel("player")
        local levelString = failed and ZO_ERROR_COLOR:Colorize(requiredLevel) or ZO_DEFAULT_ENABLED_COLOR:Colorize(requiredLevel)
        self:AddSubLabel(GetString(SI_ITEM_FORMAT_STR_LEVEL))
        self:AddSubLabel(levelString)
    else
        self:AddEmptySubLabel()
        self:AddEmptySubLabel()
    end

    local value = GetItemLinkValue(itemLink)
    if value > 0 then
        self:AddSubLabel(GetString(SI_ITEM_FORMAT_STR_VALUE))
        self:AddSubLabel(ZO_DEFAULT_ENABLED_COLOR:Colorize(value))
    else
        self:AddEmptySubLabel()
        self:AddEmptySubLabel()
    end

    self:AddSubLabel(GetItemLinkFlavorText(itemLink))
end

function ZO_InventoryItemImprovement_Gamepad:ClearTooltip()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
end

function ZO_InventoryItemImprovement_Gamepad:ResetTooltipToDefault()
    if self.itemBag and self.itemIndex then
        GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, self.itemBag, self.itemIndex)
    end
end

function ZO_InventoryItemImprovement_Gamepad:GetItemTemplateName()
    return "ZO_Gamepad_ItemImprovement_ItemTemplate"
end

function ZO_InventoryItemImprovement_Gamepad:BuildEnumeratedImprovementKitList(itemList)
    for _, v in pairs(itemList) do
        table.insert(self.enumeratedList, v)
    end
end

function ZO_InventoryItemImprovement_Gamepad:InitializeImprovementKitVisualData(entry, ...)
    entry:InitializeImprovementKitVisualData(...)
end

function ZO_InventoryItemImprovement_Gamepad:GetItemName(itemInfo)
    return GetItemName(itemInfo.bag, itemInfo.index)
end

function ZO_InventoryItemImprovement_Gamepad:UpdateTooltipOnSelectionChanged()
end

-- These functions must be overridden

function ZO_InventoryItemImprovement_Gamepad:SetupScene()
    assert(false)
end

function ZO_InventoryItemImprovement_Gamepad:PerformItemImprovement()
    assert(false)
end