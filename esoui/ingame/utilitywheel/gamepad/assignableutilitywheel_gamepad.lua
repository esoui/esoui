ZO_AssignableUtilityWheel_Gamepad = ZO_AssignableUtilityWheel_Shared:Subclass()

function ZO_AssignableUtilityWheel_Gamepad:InitializeRadialMenu()
    self.radialMenu = ZO_RadialMenu:New(self.control, "ZO_AssignableUtilityWheelSlot_Gamepad_Template", nil, "SelectableItemRadialMenuEntryAnimation", "RadialMenu")
    --Store entry controls to animate with later
    self.radialEntryControls = {}

    local function SetupEntryControl(entryControl, data)
        entryControl.label:SetText(data.name)
        self.radialEntryControls[data.slotIndex] = entryControl
        ZO_SetupSelectableItemRadialMenuEntryTemplate(entryControl)
    end

    self.radialMenu:SetCustomControlSetUpFunction(SetupEntryControl)
end

function ZO_AssignableUtilityWheel_Gamepad:InitializeSlots()
    self:InitializeRadialMenu()
    local numSlots = self.data.numSlots
    local actionBarOffset = self.data.startSlotIndex or 0
    for i = actionBarOffset + 1, actionBarOffset + numSlots do
        local slotData = 
        {
            name = GetString(SI_QUICKSLOTS_EMPTY),
            icon = "EsoUI/Art/Quickslots/quickslot_emptySlot.dds",
            slotIndex = i,
        }

        self.slots[i] = slotData
    end
end

function ZO_AssignableUtilityWheel_Gamepad:DoSlotUpdate(physicalSlot, playAnimation)
    local slot = self.slots[physicalSlot]
    if slot then
        local physicalSlotType = GetSlotType(physicalSlot)

        local slotIcon = "EsoUI/Art/Quickslots/quickslot_emptySlot.dds"
        local name = GetString(SI_QUICKSLOTS_EMPTY)
        --TODO: Support the other action types
        if physicalSlotType == ACTION_TYPE_EMOTE then
            local emoteId = GetSlotBoundId(physicalSlot)
            local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(emoteId)
            local found = emoteInfo ~= nil
            if found then
                if emoteInfo.isOverriddenByPersonality then
                    slotIcon = PLAYER_EMOTE_MANAGER:GetSharedPersonalityEmoteIconForCategory(emoteInfo.emoteCategory)
                    name = ZO_PERSONALITY_EMOTES_COLOR:Colorize(emoteInfo.displayName)
                else
                    slotIcon = PLAYER_EMOTE_MANAGER:GetSharedEmoteIconForCategory(emoteInfo.emoteCategory)
                    name = emoteInfo.displayName
                end
            end
        elseif physicalSlotType == ACTION_TYPE_QUICK_CHAT then
            local quickChatId = GetSlotBoundId(physicalSlot)
            if QUICK_CHAT_MANAGER:HasQuickChat(quickChatId) then
                slotIcon = GetSharedQuickChatIcon()
                name = QUICK_CHAT_MANAGER:GetFormattedQuickChatName(quickChatId)
            end
        elseif physicalSlotType ~= ACTION_TYPE_NOTHING then
            name = ""
            slotIcon = GetSlotTexture(physicalSlot)
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
    end
end

function ZO_AssignableUtilityWheel_Gamepad:Show()
    self.radialMenu:Clear()
    local numSlots = self.data.numSlots
    local actionBarOffset = self.data.startSlotIndex or 0
    for i = 1, numSlots do
        local slotData = self.slots[i + actionBarOffset]
        self.radialMenu:AddEntry(slotData.name, slotData.icon, slotData.icon, nil, slotData)
    end
    self.radialMenu:Show()
end

function ZO_AssignableUtilityWheel_Gamepad:Hide()
    self.radialMenu:Clear()
end

function ZO_AssignableUtilityWheel_Gamepad:GetSelectedRadialEntry()
    return self.radialMenu.selectedEntry
end