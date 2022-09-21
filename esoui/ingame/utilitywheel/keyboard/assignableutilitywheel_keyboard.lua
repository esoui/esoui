ZO_AssignableUtilityWheel_Keyboard = ZO_AssignableUtilityWheel_Shared:Subclass()

function ZO_AssignableUtilityWheel_Keyboard:RegisterForEvents()
    ZO_AssignableUtilityWheel_Shared.RegisterForEvents(self)

    local function HandleInventorySlotPickup(bagId, slotIndex)
        local _, _, _, meetsUsageRequirement = GetItemInfo(bagId, slotIndex)
        local hotbarCategory = self:GetHotbarCategory()
        for slotNum, slot in pairs(self.slots) do
            local validInSlot = IsValidItemForSlot(bagId, slotIndex, slotNum, hotbarCategory)
            if validInSlot then
                self:ShowSlotDropCallout(slot:GetNamedChild("DropCallout"), meetsUsageRequirement)
            end
        end
    end
    
    local function HandleActionSlotPickup(slotType, sourceSlot, itemId)
        local MET_EQUIP_REQUIREMENTS = true -- This was already in a slot, chances are you're not going to fail equip requirements
        if slotType == ACTION_TYPE_ITEM then
            local hotbarCategory = self:GetHotbarCategory()
            for slotNum, slot in pairs(self.slots) do
                local validInSlot = IsValidItemForSlotByItemId(itemId, slotNum, hotbarCategory)
                if validInSlot then
                    self:ShowSlotDropCallout(slot:GetNamedChild("DropCallout"), MET_EQUIP_REQUIREMENTS)
                end
            end
        end
    end

    local function HandleCollectibleSlotPickup(collectibleId)
        local hotbarCategory = self:GetHotbarCategory()
        for slotNum, slot in pairs(self.slots) do
            local validInSlot = IsValidCollectibleForSlot(collectibleId, slotNum, hotbarCategory)
            if validInSlot then
                self:ShowSlotDropCallout(slot:GetNamedChild("DropCallout"), true)
            end
        end
    end

    local function HandleQuestItemSlotPickup(questIndex, stepIndex, conditionIndex, toolIndex, questItemId)
        local hotbarCategory = self:GetHotbarCategory()
        for slotNum, slot in pairs(self.slots) do
            local validInSlot = IsValidQuestItemForSlot(questItemId, slotNum, hotbarCategory)
            if validInSlot then
                self:ShowSlotDropCallout(slot:GetNamedChild("DropCallout"), true)
            end
        end
    end

    local function HandleEmoteSlotPickup(emoteId)
        local hotbarCategory = self:GetHotbarCategory()
        for slotNum, slot in pairs(self.slots) do
            local validInSlot = IsValidEmoteForSlot(emoteId, slotNum, hotbarCategory)
            if validInSlot then
                self:ShowSlotDropCallout(slot:GetNamedChild("DropCallout"), true)
            end
        end
    end

    local function HandleQuickChatSlotPickup(quickChatId)
        local hotbarCategory = self:GetHotbarCategory()
        for slotNum, slot in pairs(self.slots) do
            local validInSlot = IsValidQuickChatForSlot(quickChatId, slotNum, hotbarCategory)
            if validInSlot then
                self:ShowSlotDropCallout(slot:GetNamedChild("DropCallout"), true)
            end
        end
    end

    local function HandleCursorPickup(eventCode, cursorType, ...)
        if self:GetHotbarCategory() ~= ZO_UTILITY_WHEEL_HOTBAR_CATEGORY_HIDDEN then
            if cursorType == MOUSE_CONTENT_INVENTORY_ITEM then
                HandleInventorySlotPickup(...)
            elseif cursorType == MOUSE_CONTENT_ACTION then
                HandleActionSlotPickup(...)
            elseif cursorType == MOUSE_CONTENT_COLLECTIBLE then
                HandleCollectibleSlotPickup(...)
            elseif cursorType == MOUSE_CONTENT_QUEST_ITEM then
                HandleQuestItemSlotPickup(...)
            elseif cursorType == MOUSE_CONTENT_EMOTE then
                HandleEmoteSlotPickup(...)
            elseif cursorType == MOUSE_CONTENT_QUICK_CHAT then
                HandleQuickChatSlotPickup(...)
            end
        end
    end

    local function HandleCursorCleared()
        self:HideAllSlotDropCallouts()
    end

    local function HandleInventoryChanged()
        --This is only relevant if the wheel supports inventory items
        if not self.control:IsHidden() and self:IsActionTypeSupported(ACTION_TYPE_ITEM) then
            local hotbarCategory = self:GetHotbarCategory()
            for slotNum, slot in pairs(self.slots) do
                local slotType = GetSlotType(slotNum, hotbarCategory)
                if slotType == ACTION_TYPE_ITEM then
                    local itemCount = GetSlotItemCount(slotNum, hotbarCategory)
                    if itemCount then
                        slot.icon:SetDesaturation(itemCount == 0 and 1 or 0)
                        slot.countText:SetText(itemCount)
                        slot.countText:SetHidden(false)
                    else
                        slot.icon:SetDesaturation(0)
                        slot.countText:SetHidden(true)
                    end
                end
            end
        end
    end

    self.control:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
    self.control:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorCleared)

    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, HandleInventoryChanged)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, HandleInventoryChanged)
end

function ZO_AssignableUtilityWheel_Keyboard:InitializeKeybindStripDescriptors()
    ZO_AssignableUtilityWheel_Shared.InitializeKeybindStripDescriptors(self)
    self.mouseOverKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Remove
        {
            name = GetString(SI_ABILITY_ACTION_CLEAR_SLOT),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local slotId = self.mouseOverSlot.slotNum
                ClearSlot(slotId, self:GetHotbarCategory())
                PlaySound(SOUNDS.QUICKSLOT_CLEAR)
            end,
        },
    }
end

function ZO_AssignableUtilityWheel_Keyboard:Deactivate()
    ZO_AssignableUtilityWheel_Shared.Deactivate(self)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mouseOverKeybindStripDescriptor)
end


local INITIAL_ROTATION = 0
function ZO_AssignableUtilityWheel_Keyboard:PerformSlotLayout()
    local width, height = self.control:GetDimensions()
    local scale = self.control:GetScale()
    local halfWidth, halfHeight = width * scale * 0.5, height * scale * 0.5
    local numSlots = self.data.numSlots
    local actionBarOffset = self.data.startSlotIndex or 0

    for i = 1, numSlots do
        local control = self.slots[i + actionBarOffset]
        local centerAngle = INITIAL_ROTATION + i / numSlots * ZO_TWO_PI
        local x = math.sin(centerAngle)
        local y = math.cos(centerAngle)

        if math.abs(x) < 0.01 then
            x = 0
        end

        if control.nameLabel then
            control.nameLabel:ClearAnchors()
            if x > 0 then
                control.nameLabel:SetAnchor(LEFT, control.icon, RIGHT, 15, 0)
            elseif x < 0 then
                control.nameLabel:SetAnchor(RIGHT, control.icon, LEFT, -15, 0)
            elseif y > 0 then
                control.nameLabel:SetAnchor(TOP, control.icon, BOTTOM, 0, 0)
            else
                control.nameLabel:SetAnchor(BOTTOM, control.icon, TOP, 0, -5)
            end
        end

        control:SetAnchor(CENTER, nil, CENTER, x * halfWidth, y * halfHeight)
        control:SetHidden(false)
    end
end

function ZO_AssignableUtilityWheel_Keyboard:InitializeSlots()
    local numSlots = self.data.numSlots
    local actionBarOffset = self.data.startSlotIndex or 0
    for i = actionBarOffset + 1, actionBarOffset + numSlots do
        local slot = CreateControlFromVirtual("$(parent)WheelSlot" .. i, self.control, "ZO_AssignableUtilityWheelSlot_Keyboard_Template")

        self.slots[i] = slot
        slot.button = slot:GetNamedChild("Button")
        slot.button.slotNum = i
        slot.button.object = self
        slot.icon = slot:GetNamedChild("Icon")
        slot.countText = slot:GetNamedChild("CountText")
        slot.nameLabel = slot:GetNamedChild("Label")

        if self.data.overrideShowNameLabels ~= nil then
            slot.nameLabel:SetHidden(not self.data.overrideShowNameLabels)
        end

        ZO_ActionSlot_SetupSlot(slot.icon, slot.button, ZO_UTILITY_SLOT_EMPTY_TEXTURE)
        ZO_CreateSparkleAnimation(slot)
    end

    self:PerformSlotLayout()
end

function ZO_AssignableUtilityWheel_Keyboard:DoSlotUpdate(physicalSlot, playAnimation)
    local slot = self.slots[physicalSlot]
    if slot then
        local hotbarCategory = self:GetHotbarCategory()
        local physicalSlotType = GetSlotType(physicalSlot, hotbarCategory)
        slot.nameLabel:SetText("")

        if self.data.overrideShowNameLabels ~= nil then
            slot.nameLabel:SetHidden(not self.data.overrideShowNameLabels)
        else
            --Only the emote wheel shows name labels by default
            slot.nameLabel:SetHidden(hotbarCategory ~= HOTBAR_CATEGORY_EMOTE_WHEEL)
        end

        local slotIcon = GetSlotTexture(physicalSlot, hotbarCategory)

        if physicalSlotType == ACTION_TYPE_NOTHING then
            ZO_ActionSlot_SetupSlot(slot.icon, slot.button, ZO_UTILITY_SLOT_EMPTY_TEXTURE)
            slot.nameLabel:SetText(ZO_UTILITY_SLOT_EMPTY_STRING)
        elseif physicalSlotType == ACTION_TYPE_EMOTE then
            local name = ZO_UTILITY_SLOT_EMPTY_STRING
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
            ZO_ActionSlot_SetupSlot(slot.icon, slot.button, slotIcon)
            slot.nameLabel:SetText(name)
        elseif physicalSlotType == ACTION_TYPE_QUICK_CHAT then
            local name = ZO_UTILITY_SLOT_EMPTY_STRING
            local quickChatId = GetSlotBoundId(physicalSlot, hotbarCategory)
            if QUICK_CHAT_MANAGER:HasQuickChat(quickChatId) then
                name = QUICK_CHAT_MANAGER:GetFormattedQuickChatName(quickChatId)
            end
            ZO_ActionSlot_SetupSlot(slot.icon, slot.button, slotIcon)
            slot.nameLabel:SetText(name)
        else
            local name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetSlotName(physicalSlot, hotbarCategory))
            slot.nameLabel:SetText(name)

            ZO_ActionSlot_SetupSlot(slot.icon, slot.button, slotIcon)
        end

        local itemCount = GetSlotItemCount(physicalSlot, hotbarCategory)
        if itemCount then
            slot.icon:SetDesaturation(itemCount == 0 and 1 or 0)
            slot.countText:SetText(itemCount)
            slot.countText:SetHidden(false)
        else
            slot.icon:SetDesaturation(0)
            slot.countText:SetHidden(true)
        end

        local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
        if mouseOverControl == slot.button then
            ZO_AbilitySlot_OnMouseEnter(slot.button)
        end

        if physicalSlotType ~= ACTION_TYPE_NOTHING and playAnimation and not slot:IsHidden() then
            ZO_PlaySparkleAnimation(slot)
            if hotbarCategory == HOTBAR_CATEGORY_QUICKSLOT_WHEEL and self:GetNumSlotted() == 1 then
                SetCurrentQuickslot(physicalSlot)
            end
        end
    end
end

function ZO_AssignableUtilityWheel_Keyboard:HideAllSlotDropCallouts()
    for _, slot in pairs(self.slots) do
       slot:GetNamedChild("DropCallout"):SetHidden(true)
    end
end

function ZO_AssignableUtilityWheel_Keyboard:ShowSlotDropCallout(calloutControl, meetsUsageRequirement)
    calloutControl:SetHidden(false)
    if meetsUsageRequirement then
        calloutControl:SetColor(1, 1, 1, 1)
    else
        calloutControl:SetColor(1, 0, 0, 1)
    end
end

function ZO_AssignableUtilityWheel_Keyboard:OnMouseOverUtilitySlot(slotControl)
    if slotControl.animation then
        slotControl.animation:PlayForward()
    end

    if self.mouseOverSlot ~= slotControl then
        PlaySound(SOUNDS.QUICKSLOT_MOUSEOVER)
        self.mouseOverSlot = slotControl
    end

    if IsSlotUsed(slotControl.slotNum, self:GetHotbarCategory()) then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.mouseOverKeybindStripDescriptor)
    else
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mouseOverKeybindStripDescriptor)
    end
end

function ZO_AssignableUtilityWheel_Keyboard:OnMouseExitUtilitySlot(slotControl)
    if slotControl.animation then
        slotControl.animation:PlayBackward()
    end

    self.mouseOverSlot = nil
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mouseOverKeybindStripDescriptor)
end

function ZO_UtilityWheelSlotControl_OnInitialize(control)
    local button = control:GetNamedChild("Button")
    button:SetDrawTier(DT_MEDIUM)
    button:SetDrawLayer(DL_BACKGROUND)
    button:SetMouseOverTexture(nil)
    button.slotType = ABILITY_SLOT_TYPE_UTILITY

    local glow = control:GetNamedChild("Glow")
    button.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("UtilitySlotGlowAlphaAnimation", glow)

    local icon = control:GetNamedChild("Icon")
    icon:SetDrawTier(DT_MEDIUM)
    icon:SetDrawLayer(DL_BACKGROUND)
end