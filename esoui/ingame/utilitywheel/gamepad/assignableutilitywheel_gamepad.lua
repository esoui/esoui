ZO_AssignableUtilityWheel_Gamepad = ZO_AssignableUtilityWheel_Shared:Subclass()

function ZO_AssignableUtilityWheel_Gamepad:Initialize(control, data)
    ZO_AssignableUtilityWheel_Shared.Initialize(self, control, data)
    self.centerIcon = control:GetNamedChild("Icon")
    self.delayShowCenterIcon = false
    self.tooltipScrollEnabled = true
    self.overrideTooltipScrollEnabled = self.data.overrideTooltipScrollEnabled
    self.tooltipType = data.overrideGamepadTooltip or GAMEPAD_QUAD1_TOOLTIP
    ZO_CreateSparkleAnimation(control)
    self:InitializeNarrationInfo()
end

function ZO_AssignableUtilityWheel_Gamepad:InitializeNarrationInfo()
    local data = self.data

    if data.customNarrationObjectName then
        local narrationInfo =
        {
            canNarrate = function()
                return self.radialMenu:IsShown()
            end,
            selectedNarrationFunction = function()
                local narrations = {}
                local selectedEntry = self:GetSelectedRadialEntry()
                if selectedEntry then
                    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(selectedEntry.name))
                else
                    --If an entry is not selected, just narrate the current category name for the wheel
                    local hotbarCategory = self:GetHotbarCategory()
                    if hotbarCategory ~= ZO_UTILITY_WHEEL_HOTBAR_CATEGORY_HIDDEN then
                        local categoryName = GetString("SI_HOTBARCATEGORY", hotbarCategory)
                        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(categoryName))
                    end
                end
                return narrations
            end,
            headerNarrationFunction = data.headerNarrationFunction,
        }
        SCREEN_NARRATION_MANAGER:RegisterCustomObject(data.customNarrationObjectName, narrationInfo)
    end
end

function ZO_AssignableUtilityWheel_Gamepad:OnSelectionChanged(selectedEntry)
    if selectedEntry then
        local slotIndex = selectedEntry.data.slotIndex
        local hotbarCategory = self:GetHotbarCategory()
        local slotType = GetSlotType(slotIndex, hotbarCategory)

        --Only add this keybind if overrideTooltipScrollEnabled is not set
        if slotType ~= ACTION_TYPE_NOTHING and self.overrideTooltipScrollEnabled == nil then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.tooltipKeybindStripDescriptor)
        else
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.tooltipKeybindStripDescriptor)
        end

        --tooltip update on active item
        if slotType == ACTION_TYPE_COLLECTIBLE then
            local itemLink = GetSlotItemLink(slotIndex, hotbarCategory)
            GAMEPAD_TOOLTIPS:LayoutCollectibleFromLink(self.tooltipType, itemLink)
        elseif slotType == ACTION_TYPE_ITEM then
            local itemLink = GetSlotItemLink(slotIndex, hotbarCategory)
            GAMEPAD_TOOLTIPS:LayoutItemWithStackCountSimple(self.tooltipType, itemLink, ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT)
        elseif slotType == ACTION_TYPE_QUEST_ITEM then
            local questItemId = GetSlotBoundId(slotIndex, hotbarCategory)
            GAMEPAD_TOOLTIPS:LayoutQuestItem(self.tooltipType, questItemId)
        elseif slotType == ACTION_TYPE_EMOTE then
            local emoteId = GetSlotBoundId(slotIndex, hotbarCategory)
            GAMEPAD_TOOLTIPS:LayoutUtilityWheelEmote(self.tooltipType, emoteId)
        elseif slotType == ACTION_TYPE_QUICK_CHAT then
            local quickChatId = GetSlotBoundId(slotIndex, hotbarCategory)
            GAMEPAD_TOOLTIPS:LayoutUtilityWheelQuickChat(self.tooltipType, quickChatId)
        elseif slotType == ACTION_TYPE_NOTHING then
            GAMEPAD_TOOLTIPS:ClearTooltip(self.tooltipType)
        else
            internalassert(false, "Unsupported slot type")
        end
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(self.tooltipType)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.tooltipKeybindStripDescriptor)
    end

    if self.data.onSelectionChangedCallback then
        self.data:onSelectionChangedCallback(selectedEntry)
    end

    --Re-narrate when the selection changes
    if self.data.customNarrationObjectName then
        SCREEN_NARRATION_MANAGER:QueueCustomEntry(self.data.customNarrationObjectName)
    end
end

function ZO_AssignableUtilityWheel_Gamepad:InitializeRadialMenu()
    self.radialMenu = ZO_RadialMenu:New(self.control, "ZO_AssignableUtilityWheelSlot_Gamepad_Template", nil, "SelectableItemRadialMenuEntryAnimation", "RadialMenu", nil, nil, nil, self.data.showKeybinds)
    --Store entry controls to animate with later
    self.radialEntryControls = {}

    if self.data.overrideActivateOnShow ~= nil then
        self.radialMenu:SetActivateOnShow(overrideActivateOnShow)
    end

    local function SetupEntryControl(entryControl, data)
        local hotbarCategory = self:GetHotbarCategory()

        --If we are showing keybinds, do not show name labels in any circumstance
        local showKeybinds = self:ShouldShowKeybinds()
        if self.data.overrideShowNameLabels ~= nil or showKeybinds then
            entryControl.label:SetHidden(showKeybinds or not self.data.overrideShowNameLabels)
        else
            --Only the emote wheel shows name labels by default
            entryControl.label:SetHidden(hotbarCategory ~= HOTBAR_CATEGORY_EMOTE_WHEEL)
        end
        entryControl.label:SetText(data.name)
        entryControl.object = self
        self.radialEntryControls[data.slotIndex] = entryControl

        local slotType = GetSlotType(data.slotIndex, hotbarCategory)
        local itemCount = GetSlotItemCount(data.slotIndex, hotbarCategory)
        local NOT_SELECTED = false
        local NO_STACK_COUNT = nil
        ZO_SetupSelectableItemRadialMenuEntryTemplate(entryControl, NOT_SELECTED, slotType ~= ACTION_TYPE_NOTHING and itemCount or NO_STACK_COUNT)
        ZO_GamepadUtilityWheelCooldownSetup(entryControl, data.slotIndex, hotbarCategory)
    end

    self.radialMenu:SetCustomControlSetUpFunction(SetupEntryControl)
    self.radialMenu:SetOnSelectionChangedCallback(function(...) self:OnSelectionChanged(...) end)
end

function ZO_AssignableUtilityWheel_Gamepad:InitializeKeybindStripDescriptors()
    ZO_AssignableUtilityWheel_Shared.InitializeKeybindStripDescriptors(self)
    self.tooltipKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        -- Toggle tooltip input
        {
            name = function() 
                if self.tooltipScrollEnabled then
                    return GetString(SI_UTILITY_WHEEL_DISABLE_TOOLTIP_SCROLL)
                else
                    return GetString(SI_UTILITY_WHEEL_ENABLE_TOOLTIP_SCROLL)
                end
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                self.tooltipScrollEnabled = not self.tooltipScrollEnabled
                GAMEPAD_TOOLTIPS:SetInputEnabled(self.tooltipType, self.tooltipScrollEnabled)
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.tooltipKeybindStripDescriptor)
            end,
        },
    }
end

function ZO_AssignableUtilityWheel_Gamepad:InitializeSlots()
    self:InitializeRadialMenu()
    local numSlots = self.data.numSlots
    local actionBarOffset = self.data.startSlotIndex or 0
    for i = actionBarOffset + 1, actionBarOffset + numSlots do
        local slotData = 
        {
            name = ZO_UTILITY_SLOT_EMPTY_STRING,
            icon = ZO_UTILITY_SLOT_EMPTY_TEXTURE,
            slotIndex = i,
        }

        self.slots[i] = slotData
    end
end

function ZO_AssignableUtilityWheel_Gamepad:DoSlotUpdate(physicalSlot, playAnimation)
    local slot = self.slots[physicalSlot]
    if slot then
        local hotbarCategory = self:GetHotbarCategory()
        local physicalSlotType = GetSlotType(physicalSlot, hotbarCategory)

        local slotIcon = ZO_UTILITY_SLOT_EMPTY_TEXTURE
        if physicalSlotType ~= ACTION_TYPE_NOTHING then
            slotIcon = GetSlotTexture(physicalSlot, hotbarCategory)
        end

        local name = ZO_UTILITY_SLOT_EMPTY_STRING
        if physicalSlotType == ACTION_TYPE_EMOTE then
            local emoteId = GetSlotBoundId(physicalSlot, hotbarCategory)
            local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(emoteId)
            local found = emoteInfo ~= nil
            if found then
                if emoteInfo.isOverriddenByPersonality then
                    name = ZO_PERSONALITY_EMOTES_COLOR:Colorize(emoteInfo.displayName)
                else
                    name = emoteInfo.displayName
                end
            end
        elseif physicalSlotType == ACTION_TYPE_QUICK_CHAT then
            local quickChatId = GetSlotBoundId(physicalSlot, hotbarCategory)
            if QUICK_CHAT_MANAGER:HasQuickChat(quickChatId) then
                name = QUICK_CHAT_MANAGER:GetFormattedQuickChatName(quickChatId)
            end
        elseif physicalSlotType ~= ACTION_TYPE_NOTHING then
            name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetSlotName(physicalSlot, hotbarCategory))
        end

        local slotData = 
        {
            name = name,
            icon = slotIcon,
            slotIndex = physicalSlot,
        }

        if self.radialMenu:IsShown() then
            local function DoesSlotPassFilter(entry)
                return entry.data.slotIndex == slotData.slotIndex
            end
            self.radialMenu:UpdateFirstEntryByFilter(DoesSlotPassFilter, name, slotIcon, slotIcon, nil, slotData)
        end

        self.slots[physicalSlot] = slotData

        local slotControl = self.radialEntryControls[physicalSlot]
        if physicalSlotType ~= ACTION_TYPE_NOTHING and playAnimation and slotControl and not slotControl:IsHidden() then
            ZO_PlaySparkleAnimation(slotControl)
        end

        --Show the center icon if we were waiting for an update to do so
        if self.data.showPendingIcon and self.delayShowCenterIcon then
            local PLAY_ANIMATION = true
            self:ShowCenterIcon(PLAY_ANIMATION)
            self.delayShowCenterIcon = false
        end
    end
end

function ZO_AssignableUtilityWheel_Gamepad:CycleHotbarCategory()
    --Order matters. Clear the tooltip before cycling hotbar categories
    GAMEPAD_TOOLTIPS:ClearTooltip(self.tooltipType)
    ZO_AssignableUtilityWheel_Shared.CycleHotbarCategory(self)
    --Re-narrate when cycling between hotbar categories
    if self.data.customNarrationObjectName then
        SCREEN_NARRATION_MANAGER:QueueCustomEntry(self.data.customNarrationObjectName)
    end
end

function ZO_AssignableUtilityWheel_Gamepad:Show(unslotPendingEntry)
    self.radialMenu:Clear()
    local numSlots = self.data.numSlots
    local actionBarOffset = self.data.startSlotIndex or 0
    for i = 1, numSlots do
        local slotData = self.slots[i + actionBarOffset]
        self.radialMenu:AddEntry(slotData.name, slotData.icon, slotData.icon, nil, slotData)
    end
    self.radialMenu:Show()

    if unslotPendingEntry and self.pendingSlotData then
        local hotbarCategory = self:GetHotbarCategory()
        local slotNum
        if self.pendingSlotData.actionId then
            slotNum = FindActionSlotMatchingSimpleAction(self.pendingSlotData.slotType, self.pendingSlotData.actionId, hotbarCategory)
        elseif self.pendingSlotData.bagId and self.pendingSlotData.itemSlotIndex then
            slotNum = FindActionSlotMatchingItem(self.pendingSlotData.bagId, self.pendingSlotData.itemSlotIndex, hotbarCategory)
        end

        if slotNum then
            --The center icon will appear on the next slot update
            --This is so we can sync the appearance of the icon with the clearing of the corresponding slot
            self.delayShowCenterIcon = true
            ClearSlot(slotNum, hotbarCategory)
        end
    end

    self:RefreshPendingIcon()
    if self.data.showPendingIcon and not self.delayShowCenterIcon then
        self:ShowCenterIcon()
    end

    if self.overrideTooltipScrollEnabled ~= nil then
        GAMEPAD_TOOLTIPS:SetInputEnabled(self.tooltipType, self.overrideTooltipScrollEnabled)
    else
        GAMEPAD_TOOLTIPS:SetInputEnabled(self.tooltipType, self.tooltipScrollEnabled)
    end
    self:Activate()
end

function ZO_AssignableUtilityWheel_Gamepad:Hide()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.tooltipKeybindStripDescriptor)
    GAMEPAD_TOOLTIPS:SetInputEnabled(self.tooltipType, true)
    GAMEPAD_TOOLTIPS:ClearLines(self.tooltipType)
    self.radialMenu:Clear()
    self:HideCenterIcon()
    --Clear out any pending updates to the center icon
    self.delayShowCenterIcon = false
    self:Deactivate()
end

function ZO_AssignableUtilityWheel_Gamepad:Activate()
    ZO_AssignableUtilityWheel_Shared.Activate(self)
    if self.data.customNarrationObjectName then
        --Narrate the header when the utility wheel is first activated
        local NARRATE_HEADER = true
        SCREEN_NARRATION_MANAGER:QueueCustomEntry(self.data.customNarrationObjectName, NARRATE_HEADER)
    end
end

function ZO_AssignableUtilityWheel_Gamepad:TryAssignPendingToSelectedEntry(clearPending)
    local selectedEntry = self:GetSelectedRadialEntry()
    local pendingSlotData = self.pendingSlotData
    if self.radialMenu:IsShown() and pendingSlotData and selectedEntry then
        local actionSlotIndex = selectedEntry.data.slotIndex
        local hotbarCategory = self:GetHotbarCategory()
        if pendingSlotData.actionId then
            SelectSlotSimpleAction(pendingSlotData.slotType, pendingSlotData.actionId, actionSlotIndex, hotbarCategory)
        elseif pendingSlotData.bagId and pendingSlotData.itemSlotIndex then
            SelectSlotItem(pendingSlotData.bagId, pendingSlotData.itemSlotIndex, actionSlotIndex, hotbarCategory)
        else
            internalassert(false, "Invalid pending data")
        end

        if clearPending then
            self.pendingSlotData = nil
        end
        PlaySound(SOUNDS.RADIAL_MENU_SELECTION)

        --Re-narrate when the pending entry is assigned to a slot
        if self.data.customNarrationObjectName then
            SCREEN_NARRATION_MANAGER:QueueCustomEntry(self.data.customNarrationObjectName)
        end

        --No need to refresh the pending icon if we aren't showing it in the first place
        if self.data.showPendingIcon then
            self:RefreshPendingIcon()
        end
    end
end

function ZO_AssignableUtilityWheel_Gamepad:SetPendingSimpleAction(slotType, actionId)
    local data =
    {
        slotType = slotType,
        actionId = actionId,
    }
    self.pendingSlotData = data
    if self.data.showPendingIcon then
        self:RefreshPendingIcon()
    end
end

function ZO_AssignableUtilityWheel_Gamepad:SetPendingItem(bagId, itemSlotIndex)
    local data =
    {
        slotType = ACTION_TYPE_ITEM,
        bagId = bagId,
        itemSlotIndex = itemSlotIndex,
    }
    self.pendingSlotData = data
    if self.data.showPendingIcon then
        self:RefreshPendingIcon()
    end
end

function ZO_AssignableUtilityWheel_Gamepad:GetPendingData()
    return self.pendingSlotData
end

--Get the name of the currently pending data (if we have any)
function ZO_AssignableUtilityWheel_Gamepad:GetPendingName()
    local pendingData = self:GetPendingData()
    if pendingData then
        local slotType = pendingData.slotType
        if slotType == ACTION_TYPE_COLLECTIBLE then
            local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(pendingData.actionId)
            if collectibleData then
                return collectibleData:GetFormattedName()
            end
        elseif slotType == ACTION_TYPE_ITEM then
            if pendingData.bagId and pendingData.itemSlotIndex then
                return zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(pendingData.bagId, pendingData.itemSlotIndex))
            end
        elseif slotType == ACTION_TYPE_QUEST_ITEM then
            return zo_strformat(SI_TOOLTIP_ITEM_NAME, GetQuestItemName(pendingData.actionId))
        elseif slotType == ACTION_TYPE_EMOTE then
            local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(pendingData.actionId)
            if emoteInfo then
                if emoteInfo.isOverriddenByPersonality then
                    return ZO_PERSONALITY_EMOTES_COLOR:Colorize(emoteInfo.displayName)
                else
                    return emoteInfo.displayName
                end
            end
        elseif slotType == ACTION_TYPE_QUICK_CHAT then
            if QUICK_CHAT_MANAGER:HasQuickChat(pendingData.actionId) then
                return QUICK_CHAT_MANAGER:GetFormattedQuickChatName(pendingData.actionId)
            end
        else
            internalassert(false, "Unsupported action type")
        end
    end

    return ""
end

do
    local DEFAULT_CENTER_ICON_COLOR = ZO_ColorDef:New(1, 1, 1)
    local CENTER_ICON_DISABLED_COLOR = ZO_ColorDef:New(1, 0, 0)
    function ZO_AssignableUtilityWheel_Gamepad:RefreshPendingIcon()
        local slotEnabled
        local slotIcon
        if self.pendingSlotData then
            local slotType = self.pendingSlotData.slotType
            if slotType == ACTION_TYPE_COLLECTIBLE then
                local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(self.pendingSlotData.actionId)
                if collectibleData then
                    slotIcon = collectibleData:GetIcon()
                    slotEnabled = collectibleData:IsUnlocked()
                end
            elseif slotType == ACTION_TYPE_ITEM then
                if self.pendingSlotData.bagId and self.pendingSlotData.itemSlotIndex then
                    local icon, _, _, meetsUsageRequirements = GetItemInfo(self.pendingSlotData.bagId, self.pendingSlotData.itemSlotIndex)
                    slotIcon = icon
                    slotEnabled = meetsUsageRequirements
                end
            elseif slotType == ACTION_TYPE_QUEST_ITEM then
                slotIcon = GetQuestItemIcon(self.pendingSlotData.actionId)
                slotEnabled = true
            elseif slotType == ACTION_TYPE_EMOTE then
                local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(self.pendingSlotData.actionId)
                if emoteInfo then
                    if emoteInfo.isOverriddenByPersonality then
                        slotIcon = PLAYER_EMOTE_MANAGER:GetSharedPersonalityEmoteIconForCategory(emoteInfo.emoteCategory)
                    else
                        slotIcon = PLAYER_EMOTE_MANAGER:GetSharedEmoteIconForCategory(emoteInfo.emoteCategory)
                    end
                    slotEnabled = true
                end
            elseif slotType == ACTION_TYPE_QUICK_CHAT then
                slotIcon = GetSharedQuickChatIcon()
                slotEnabled = true
            else
                internalassert(false, "Unsupported action type")
            end

            local iconColor = slotEnabled and DEFAULT_CENTER_ICON_COLOR or CENTER_ICON_DISABLED_COLOR
            self:SetCenterIcon(slotIcon, iconColor)
        else
            --If we have no pending data then there is nothing to show
            self:HideCenterIcon()
        end
    end


    function ZO_AssignableUtilityWheel_Gamepad:SetCenterIcon(iconTexture, color)
        self.centerIcon:SetTexture(iconTexture)
        if color then
            self.centerIcon:SetColor(color:UnpackRGBA())
        else
            self.centerIcon:SetColor(DEFAULT_CENTER_ICON_COLOR:UnpackRGBA())
        end
    end
end

function ZO_AssignableUtilityWheel_Gamepad:ShowCenterIcon(playAnimation)
    self.centerIcon:SetHidden(false)
    self.categoryLabel:ClearAnchors()
    self.categoryLabel:SetAnchor(BOTTOM, self.centerIcon, TOP, 0, -5)
    if playAnimation then
        ZO_PlaySparkleAnimation(self.control)
    end
end

function ZO_AssignableUtilityWheel_Gamepad:HideCenterIcon()
    self.categoryLabel:ClearAnchors()
    self.categoryLabel:SetAnchor(CENTER)
    self.centerIcon:SetHidden(true)
end

function ZO_AssignableUtilityWheel_Gamepad:GetSelectedRadialEntry()
    return self.radialMenu.selectedEntry
end

function ZO_AssignableUtilityWheel_Gamepad:SetSelectedRadialEntry(slotData)
    local function DoesSlotPassFilter(entry)
        return entry.data.slotIndex == slotData.slotIndex
    end

    if self.radialMenu:SelectFirstEntryByFilter(DoesSlotPassFilter) then
        --If we successfully set the selected radial entry, manually call OnSelectionChanged
        self:OnSelectionChanged(self:GetSelectedRadialEntry())
    end
end

function ZO_AssignableUtilityWheel_Gamepad:ForEachOrdinalEntry(callbackFunction)
    self.radialMenu:ForEachOrdinalEntry(callbackFunction)
end

function ZO_AssignableUtilityWheel_Gamepad:SetCustomSparkleStopCallback(callback)
    self.customSparkleStopCallback = callback
end

function ZO_AssignableUtilityWheelSlot_Gamepad_OnSparkleAnimationStop(slotControl)
    if slotControl.object.customSparkleStopCallback then
        slotControl.object.customSparkleStopCallback()
    end
end