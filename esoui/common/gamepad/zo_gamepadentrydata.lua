--[[ Gamepad Visual Data Object ]]--
ZO_GamepadEntryData = {}

ZO_GamepadEntryData.metaTable =
{
    __index = function(tbl, key)
        local value = ZO_GamepadEntryData[key]
        if value == nil then
            local dataSource = rawget(tbl, "dataSource")
            if dataSource then
                value = dataSource[key]
            end
        end
        return value
    end,
}

function ZO_GamepadEntryData:New(...)
    local entryData = {}
    setmetatable(entryData, self.metaTable)
    entryData:Initialize(...)
    return entryData
end

function ZO_GamepadEntryData:Initialize(text, icon, selectedIcon, highlight, isNew)
    self.text = text
    self.numIcons = 0
    self:AddIcon(icon, selectedIcon)
    self.highlight = highlight
    self.brandNew = isNew
    self.fontScaleOnSelection = true
    self.alphaChangeOnSelection = false
    self.enabled = true
    self.subLabelTemplate = "ZO_GamepadMenuEntrySubLabelTemplateMain"
end

function ZO_GamepadEntryData:InitializeInventoryVisualData(itemData)
    self.uniqueId = itemData.uniqueId   --need this on self so that it can be used for a compare by EqualityFunction in ParametricScrollList, 
    self:SetDataSource(itemData)        --SharedInventory modifies the dataSource's uniqueId before the GamepadEntryData is rebuilt, 
    self:AddIcon(itemData.icon)         --so by copying it over, we can still have access to the old one during the Equality check
    if not itemData.questIndex then 
        self:SetNameColors(self:GetColorsBasedOnQuality(self.quality))  --quest items are only white
    end
    self.cooldownIcon = itemData.icon or itemData.iconFile
    self:SetFontScaleOnSelection(false)    --item entries don't grow on selection
end

function ZO_GamepadEntryData:InitializeStoreVisualData(itemData)
    self:InitializeInventoryVisualData(itemData)
    self.meetsUsageRequirement = itemData.meetsRequirementsToBuy and itemData.meetsRequirementsToEquip
    self.currencyType1 = itemData.currencyType1
end

function ZO_GamepadEntryData:InitializeTradingHouseVisualData(itemData)
    self:InitializeInventoryVisualData(itemData)
end

function ZO_GamepadEntryData:InitializeItemImprovementVisualData(bag, index, stackCount, quality)
    self.bag = bag
    self.index = index
    self:SetStackCount(stackCount)
    self.quality = quality
    self:SetFontScaleOnSelection(false)    --item entries don't grow on selection

    if quality then
        self:SetNameColors(self:GetColorsBasedOnQuality(quality))
    else
       self:SetNameColors(ZO_NORMAL_TEXT)
    end
end

function ZO_GamepadEntryData:InitializeCollectibleVisualData(itemData)
    self.uniqueId = itemData.uniqueId
    self:SetDataSource(itemData)
    self:AddIcon(itemData.icon)
    self.cooldownIcon = itemData.icon or itemData.iconFile
end

function ZO_GamepadEntryData:AddSubLabels(subLabels)
    for _, subLabel in ipairs(subLabels) do
        self:AddSubLabel(subLabel)
    end
end

function ZO_GamepadEntryData:InitializeImprovementKitVisualData(bag, index, stackCount, quality, subLabels)
    self:InitializeItemImprovementVisualData(bag, index, stackCount, quality)
    self:AddSubLabels(subLabels)
    self:SetSubLabelColors(ZO_NORMAL_TEXT)
end

function ZO_GamepadEntryData:InitializeCraftingInventoryVisualData(itemInfo, customSortData)
    self:SetStackCount(itemInfo.stack)
    self.bagId = itemInfo.bag
    self.slotIndex = itemInfo.index

    local itemName = GetItemName(self.bagId, self.slotIndex)
    local icon, _, sellPrice, meetsUsageRequirements, _, _, _, quality = GetItemInfo(self.bagId, self.slotIndex)
    self:AddIcon(icon)
    self.pressedIcon = self.pressedIcon or icon
    self.sellPrice = sellPrice
    self.meetsUsageRequirement = meetsUsageRequirements
    self.quality = quality
    self.itemType = GetItemType(self.bagId, self.slotIndex)
    self.bestItemCategoryName = zo_strformat(GetString("SI_ITEMTYPE", self.itemType))
    self.customSortData = customSortData

    self:SetNameColors(self:GetColorsBasedOnQuality(self.quality))
    self.subLabelSelectedColor = self.selectedNameColor

    self:SetFontScaleOnSelection(false)    --item entries don't grow on selection
end

local LOOT_QUEST_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_TOOLTIP, ITEM_TOOLTIP_COLOR_QUEST_ITEM_NAME))
function ZO_GamepadEntryData:InitializeLootVisualData(lootId, count, quality, value, isQuest, isStolen, itemType)
    self.lootId = lootId
    self:SetStackCount(count)
    self.quality = quality
    self.value = value
    self.isQuest = isQuest
    self.isStolen = isStolen
    self.itemType = itemType
    self:SetFontScaleOnSelection(false)    --item entries don't grow on selection
    
    if isQuest then
        self:SetNameColors(LOOT_QUEST_COLOR)
    elseif quality then
        self:SetNameColors(self:GetColorsBasedOnQuality(quality))
    else
       self:SetNameColors(ZO_NORMAL_TEXT)
    end
end

--[[ Setters for specific fields and options ]]--
function ZO_GamepadEntryData:SetHeader(header)
    self.header = header
end

function ZO_GamepadEntryData:SetNew(isNew)
    self.brandNew = isNew
end

function ZO_GamepadEntryData:SetText(text)
    self.text = text
end

function ZO_GamepadEntryData:SetFontScaleOnSelection(active)
    self.fontScaleOnSelection = active
end

function ZO_GamepadEntryData:SetAlphaChangeOnSelection(active)
    self.alphaChangeOnSelection = active
end

function ZO_GamepadEntryData:SetMaxIconAlpha(alpha)
    self.maxIconAlpha = alpha
end

function ZO_GamepadEntryData:SetDataSource(source)
    self.dataSource = source
end

function ZO_GamepadEntryData:GetColorsBasedOnQuality(quality)
    local selectedNameColor = GetItemQualityColor(quality)
    local unselectedNameColor = GetDimItemQualityColor(quality)

    return selectedNameColor, unselectedNameColor
end

function ZO_GamepadEntryData:SetCooldown(remainingMs, durationMs)
    self.timeCooldownRecordedMs = GetFrameTimeMilliseconds()
    self.cooldownRemainingMs = remainingMs
    self.cooldownDurationMs = durationMs
end

function ZO_GamepadEntryData:GetCooldownDurationMs()
    return self.cooldownDurationMs or 0
end

function ZO_GamepadEntryData:GetCooldownTimeRemainingMs()
    if self.timeCooldownRecordedMs and self.cooldownRemainingMs then
        local timeOffsetMs = GetFrameTimeMilliseconds() - self.timeCooldownRecordedMs
        return self.cooldownRemainingMs - timeOffsetMs
    end
    return 0
end

function ZO_GamepadEntryData:IsOnCooldown()
    return self:GetCooldownDurationMs() > 0 and self:GetCooldownTimeRemainingMs() > 0
end

function ZO_GamepadEntryData:AddIconSubtype(subtypeName, texture)
    if texture then
        if not self[subtypeName] then
            self[subtypeName] = {}
            for i = 1, self.numIcons do
                table.insert(self[subtypeName], false)
            end
        end
        table.insert(self[subtypeName], texture)
    end
end

function ZO_GamepadEntryData:GetNumIcons()
    return self.numIcons
end

function ZO_GamepadEntryData:GetSubtypeIcon(subtypeName, index)
    if self[subtypeName] then
        return self[subtypeName][index] or nil
    end
end

function ZO_GamepadEntryData:GetIcon(index, selected)
    if selected then
        local selectedIcon = self:GetSubtypeIcon("iconsSelected", index)
        if selectedIcon then
            return selectedIcon
        end
    end

    return self:GetSubtypeIcon("iconsNormal", index)
end

function ZO_GamepadEntryData:AddIcon(normalTexture, selectedTexture)
    if normalTexture or selectedTexture then
        self:AddIconSubtype("iconsNormal", normalTexture)
        self:AddIconSubtype("iconsSelected", selectedTexture)
        self.numIcons = self.numIcons + 1
    end
end

function ZO_GamepadEntryData:ClearIcons()
    if self.iconsNormal then
        ZO_ClearNumericallyIndexedTable(self.iconsNormal)
    end
    if self.iconsSelected then
        ZO_ClearNumericallyIndexedTable(self.iconsSelected)
    end
end

function ZO_GamepadEntryData:GetNameColor(selected)
    if self.enabled then
        if selected then
            return self.selectedNameColor or ZO_SELECTED_TEXT
        else
            return self.unselectedNameColor or ZO_DISABLED_TEXT
        end
    else
        return self:GetNameDisabledColor(selected)
    end
end

function ZO_GamepadEntryData:SetIconTintOnSelection(selected)
    self:SetIconTint(selected and ZO_SELECTED_TEXT, selected and ZO_DISABLED_TEXT)
end

function ZO_GamepadEntryData:GetSubLabelColor(selected)
    if selected then
        return self.selectedSubLabelColor or ZO_SELECTED_TEXT
    else
        return self.unselectedSubLabelColor or ZO_DISABLED_TEXT
    end
end

function ZO_GamepadEntryData:SetNameColors(selectedColor, unselectedColor)
    self.selectedNameColor = selectedColor
    self.unselectedNameColor = unselectedColor
end

function ZO_GamepadEntryData:SetSubLabelColors(selectedColor, unselectedColor)
    self.selectedSubLabelColor = selectedColor
    self.unselectedSubLabelColor = unselectedColor
end

function ZO_GamepadEntryData:GetSubLabelTemplate()
    return self.subLabelTemplate
end

function ZO_GamepadEntryData:SetSubLabelTemplate(template)
    self.subLabelTemplate = template
end

function ZO_GamepadEntryData:SetIconTint(selectedColor, unselectedColor)
    self.selectedIconTint = selectedColor
    self.unselectedIconTint = unselectedColor
end

function ZO_GamepadEntryData:SetIconDesaturation(desaturation)
    self.iconDesaturation = desaturation
end

function ZO_GamepadEntryData:AddSubLabel(text)
    if not self.subLabels then
        self.subLabels = {}
    end
    table.insert(self.subLabels, text)
end

function ZO_GamepadEntryData:ClearSubLabels()
    if self.subLabels then
        ZO_ClearNumericallyIndexedTable(self.subLabels)
    end
end

function ZO_GamepadEntryData:SetShowUnselectedSublabels(showUnselectedSublabels)
    self.showUnselectedSublabels = showUnselectedSublabels
end

function ZO_GamepadEntryData:SetChannelActive(isChannelActive)
    self.isChannelActive = isChannelActive
end

function ZO_GamepadEntryData:SetLocked(isLocked)
    self.isLocked = isLocked
end

function ZO_GamepadEntryData:SetSelected(isSelected)
    self.isSelected = isSelected
end

function ZO_GamepadEntryData:SetChannelActive(isChannelActive)
    self.isChannelActive = isChannelActive
end

-- Functions for displaying an entry as disabled

function ZO_GamepadEntryData:SetEnabled(isEnabled)
    self.enabled = isEnabled
end

function ZO_GamepadEntryData:IsEnabled()
    return self.enabled
end

function ZO_GamepadEntryData:SetDisabledNameColors(selectedColor, unselectedColor)
    self.selectedNameDisabledColor = selectedColor
    self.unselectedNameDisabledColor = unselectedColor
end

function ZO_GamepadEntryData:SetDisabledIconTint(selectedColor, unselectedColor)
    self.selectedIconDisabledTint = selectedColor
    self.unselectedIconDisabledTint = unselectedColor
end

function ZO_GamepadEntryData:GetNameDisabledColor(selected)
    if selected then
        return self.selectedNameDisabledColor or ZO_NORMAL_TEXT
    else
        return self.unselectedNameDisabledColor or ZO_GAMEPAD_DISABLED_UNSELECTED_COLOR
    end
end

function ZO_GamepadEntryData:SetIconDisabledTintOnSelection(selected)
    self:SetDisabledIconTint(selected and ZO_NORMAL_TEXT, selected and ZO_GAMEPAD_DISABLED_UNSELECTED_COLOR)
end

function ZO_GamepadEntryData:SetModifyTextType(modifyTextType)
    self.modifyTextType = modifyTextType
end

function ZO_GamepadEntryData:SetIsHiddenByWardrobe(isHidden)
    self.isHiddenByWardrobe = isHidden
end

function ZO_GamepadEntryData:SetStackCount(stackCount)
    self.stackCount = stackCount
end
