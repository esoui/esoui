--Data for the hotbars represented on the Utility Wheel
internalassert(HOTBAR_CATEGORY_MAX_VALUE == 14, "Update category data.")
local UTILITY_WHEEL_CATEGORIES =
{
    HOTBAR_CATEGORY_QUICKSLOT_WHEEL,
    HOTBAR_CATEGORY_ALLY_WHEEL,
    HOTBAR_CATEGORY_MEMENTO_WHEEL,
    HOTBAR_CATEGORY_TOOL_WHEEL,
    HOTBAR_CATEGORY_EMOTE_WHEEL,
}
local NUM_UTILITY_WHEEL_CATEGORIES = #UTILITY_WHEEL_CATEGORIES

ZO_UtilityWheel_Shared = ZO_InteractiveRadialMenuController:Subclass()

function ZO_UtilityWheel_Shared:Initialize(control, entryTemplate, animationTemplate, entryAnimationTemplate, actionLayerName)
    ZO_InteractiveRadialMenuController.Initialize(self, control, entryTemplate, animationTemplate, entryAnimationTemplate, actionLayerName)

    --Cycle Left
    self.previousCategoryControl = control:GetNamedChild("PreviousCategory")
    self.previousCategoryName = self.previousCategoryControl:GetNamedChild("CategoryName")
    self.cycleLeftKeybindLabel = self.previousCategoryControl:GetNamedChild("KeybindLabel")

    --Cycle Right
    self.nextCategoryControl = control:GetNamedChild("NextCategory")
    self.nextCategoryName = self.nextCategoryControl:GetNamedChild("CategoryName")
    self.cycleRightKeybindLabel = self.nextCategoryControl:GetNamedChild("KeybindLabel")

    self.categoryLabel = control:GetNamedChild("MenuCategory")
    self.currentHotbarCategoryIndex = 1

    self.menu:SetShowKeybinds(function() return ZO_AreTogglableWheelsEnabled() end)
    self.menu:SetKeybindActionLayer(GetString(SI_KEYBINDINGS_LAYER_ACCESSIBLE_QUICKWHEEL))
end

function ZO_UtilityWheel_Shared:GetHotbarCategory()
    return UTILITY_WHEEL_CATEGORIES[self.currentHotbarCategoryIndex]
end

function ZO_UtilityWheel_Shared:GetNextHotbarCategoryIndex()
    return self.currentHotbarCategoryIndex % NUM_UTILITY_WHEEL_CATEGORIES + 1
end

function ZO_UtilityWheel_Shared:GetPreviousHotbarCategoryIndex()
    local categoryIndex = self.currentHotbarCategoryIndex - 1
    if categoryIndex == 0 then
        categoryIndex = NUM_UTILITY_WHEEL_CATEGORIES
    end
    return categoryIndex
end

function ZO_UtilityWheel_Shared:GetNextHotbarCategory()
    return UTILITY_WHEEL_CATEGORIES[self:GetNextHotbarCategoryIndex()]
end

function ZO_UtilityWheel_Shared:GetPreviousHotbarCategory()
    return UTILITY_WHEEL_CATEGORIES[self:GetPreviousHotbarCategoryIndex()]
end

function ZO_UtilityWheel_Shared:CycleRight()
    local nextHotbarCategoryIndex = self:GetNextHotbarCategoryIndex()
    if nextHotbarCategoryIndex ~= self.currentHotbarCategoryIndex then
        self.currentHotbarCategoryIndex = nextHotbarCategoryIndex
        self:ShowMenu()
        return true
    end
    return false
end

function ZO_UtilityWheel_Shared:CycleLeft()
    local previousHotbarCategoryIndex = self:GetPreviousHotbarCategoryIndex()
    if previousHotbarCategoryIndex ~= self.currentHotbarCategoryIndex then
        self.currentHotbarCategoryIndex = previousHotbarCategoryIndex
        self:ShowMenu()
        return true
    end
    return false
end

function ZO_UtilityWheel_Shared:RefreshCategories()
    self.nextCategoryName:SetText(GetString("SI_HOTBARCATEGORY", self:GetNextHotbarCategory()))
    self.previousCategoryName:SetText(GetString("SI_HOTBARCATEGORY", self:GetPreviousHotbarCategory()))
    self.categoryLabel:SetText(GetString("SI_HOTBARCATEGORY", self:GetHotbarCategory()))
end

--Functions overridden from base

function ZO_UtilityWheel_Shared:StopInteraction(clearSelection)
    --Hide the category controls
    self.previousCategoryControl:SetHidden(true)
    self.nextCategoryControl:SetHidden(true)

    return ZO_InteractiveRadialMenuController.StopInteraction(self, clearSelection)
end

function ZO_UtilityWheel_Shared:PrepareForInteraction()
    if SCENE_MANAGER:IsShowing("treasureMapQuickSlot") then
        SYSTEMS:HideScene("treasureMapQuickSlot")
        return false
    elseif not SCENE_MANAGER:IsShowing("hud") then
        return false
    end

    --Always start at the main quickslot wheel
    self.currentHotbarCategoryIndex = 1
    return true
end

function ZO_UtilityWheel_Shared:SetupEntryControl(entryControl, data)
    local hotbarCategory = self:GetHotbarCategory()
    local selected = (hotbarCategory == HOTBAR_CATEGORY_QUICKSLOT_WHEEL and data.slotNum == self.selectedSlotNum)
    local itemCount = GetSlotItemCount(data.slotNum, hotbarCategory)
    local slotType = GetSlotType(data.slotNum, hotbarCategory)
    ZO_SetupSelectableItemRadialMenuEntryTemplate(entryControl, selected, slotType ~= ACTION_TYPE_NOTHING and itemCount or nil)

    if entryControl.label then
        entryControl.label:SetText(data.name)
        --Only the emote wheel shows labels for its entries
        --Do not show labels for the entries while the togglable wheel is enabled
        entryControl.label:SetHidden(ZO_AreTogglableWheelsEnabled() or hotbarCategory ~= HOTBAR_CATEGORY_EMOTE_WHEEL)
    end
end

function ZO_UtilityWheel_Shared:PopulateMenu()
    self.selectedSlotNum = GetCurrentQuickslot()
    local hotbarCategory = self:GetHotbarCategory()
    local slottedEntries = ZO_GetUtilityWheelSlottedEntries(hotbarCategory)

    for i, entry in ipairs(slottedEntries) do
        local defaultCallback = nil
        if hotbarCategory == HOTBAR_CATEGORY_QUICKSLOT_WHEEL then
            defaultCallback = function() SetCurrentQuickslot(i) end
        end

        if not ZO_UtilityWheelValidateOrClearSlot(i, hotbarCategory) then
            self.menu:AddEntry(ZO_UTILITY_SLOT_EMPTY_STRING, ZO_UTILITY_SLOT_EMPTY_TEXTURE, ZO_UTILITY_SLOT_EMPTY_TEXTURE, defaultCallback, { slotNum = i })
        else
            local slotType = entry.type
            local slotId = entry.id
            local slotIcon = entry.icon
            local callback = defaultCallback
            local slotNameData
            if slotType == ACTION_TYPE_EMOTE then
                local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(slotId)
                if emoteInfo ~= nil then
                    if emoteInfo.isOverriddenByPersonality then
                        slotNameData = ZO_PERSONALITY_EMOTES_COLOR:Colorize(emoteInfo.displayName)
                    else
                        slotNameData = emoteInfo.displayName
                    end

                    if hotbarCategory ~= HOTBAR_CATEGORY_QUICKSLOT_WHEEL then
                        callback = function() PlayEmoteByIndex(emoteInfo.emoteIndex) end
                    end
                end
            elseif slotType == ACTION_TYPE_QUICK_CHAT then
                if QUICK_CHAT_MANAGER:HasQuickChat(slotId) then
                    slotNameData = QUICK_CHAT_MANAGER:GetFormattedQuickChatName(slotId)
                    if hotbarCategory ~= HOTBAR_CATEGORY_QUICKSLOT_WHEEL then
                        callback = function() QUICK_CHAT_MANAGER:PlayQuickChat(slotId) end
                    end
                end
            else
                local slotName = GetSlotName(i, hotbarCategory)
                slotName = zo_strformat(SI_TOOLTIP_ITEM_NAME, slotName)

                local slotItemDisplayQuality = GetSlotItemDisplayQuality(i, hotbarCategory)

                if slotItemDisplayQuality then
                    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, slotItemDisplayQuality)
                    local colorTable = { r = r, g = g, b = b }
                    slotNameData = { slotName, colorTable }
                else
                    slotNameData = slotName
                end

                if hotbarCategory ~= HOTBAR_CATEGORY_QUICKSLOT_WHEEL then
                    callback = function() OnSlotUp(i, hotbarCategory) end
                end
            end

            local name = slotNameData
            if type(name) == "table" then
                name = name[1]
            end
            self.menu:AddEntry(slotNameData, slotIcon, slotIcon, callback, {slotNum = i, name = name})
        end
    end

    self.previousCategoryControl:SetHidden(false)
    self.nextCategoryControl:SetHidden(false)

    self:RefreshCategories()
end

-----------------------------
-- Global Functions
-----------------------------

function ZO_GetUtilityWheelSlottedEntries(hotbarCategory)
    local slottedEntryList = {}
    for slotIndex = 1, ACTION_BAR_UTILITY_BAR_SIZE do
        slottedEntryList[slotIndex] =
        {
            type = GetSlotType(slotIndex, hotbarCategory),
            id = GetSlotBoundId(slotIndex, hotbarCategory),
            icon = GetSlotTexture(slotIndex, hotbarCategory),
            slotIndex = slotIndex,
        }
    end
    return slottedEntryList
end

function ZO_UtilityWheelValidateOrClearSlot(slot, hotbarCategory)
    local isValid = false
    local slotType = GetSlotType(slot, hotbarCategory)
    if slotType ~= ACTION_TYPE_NOTHING then
        local slotIcon = GetSlotTexture(slot, hotbarCategory)
        if not slotIcon or slotIcon == '' then
            ClearSlot(slot, hotbarCategory)
        else
            isValid = true
        end
    end
    return isValid
end

function ZO_UtilityWheelMenuEntryTemplate_OnInitialized(control)
    control.label = control:GetNamedChild("Label")
    ZO_SelectableItemRadialMenuEntryTemplate_OnInitialized(control)
end