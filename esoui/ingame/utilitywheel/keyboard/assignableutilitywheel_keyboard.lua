ZO_AssignableUtilityWheel_Keyboard = ZO_AssignableUtilityWheel_Shared:Subclass()

function ZO_AssignableUtilityWheel_Keyboard:RegisterForEvents()
    ZO_AssignableUtilityWheel_Shared.RegisterForEvents(self)

   local function HandleEmoteSlotPickup(emoteId)
        for slotNum, slot in pairs(self.slots) do
            local validInSlot = IsValidEmoteForSlot(emoteId, slotNum)
            if validInSlot then
                self:ShowSlotDropCallout(slot:GetNamedChild("DropCallout"), true)
            end
        end
    end

    local function HandleQuickChatSlotPickup(quickChatId)
        for slotNum, slot in pairs(self.slots) do
            local validInSlot = IsValidQuickChatForSlot(quickChatId, slotNum)
            if validInSlot then
                self:ShowSlotDropCallout(slot:GetNamedChild("DropCallout"), true)
            end
        end
    end

    local function HandleCursorPickup(eventCode, cursorType, ...)
        if cursorType == MOUSE_CONTENT_INVENTORY_ITEM then
            --TODO: Support this case
        elseif cursorType == MOUSE_CONTENT_ACTION then
            --TODO: Support this case
        elseif cursorType == MOUSE_CONTENT_COLLECTIBLE then
            --TODO: Support this case
        elseif cursorType == MOUSE_CONTENT_QUEST_ITEM then
            --TODO: Support this case
        elseif cursorType == MOUSE_CONTENT_EMOTE then
            HandleEmoteSlotPickup(...)
        elseif cursorType == MOUSE_CONTENT_QUICK_CHAT then
            HandleQuickChatSlotPickup(...)
        end
    end

    local function HandleCursorCleared()
        self:HideAllSlotDropCallouts()
    end

    self.control:RegisterForEvent(EVENT_CURSOR_PICKUP, HandleCursorPickup)
    self.control:RegisterForEvent(EVENT_CURSOR_DROPPED, HandleCursorCleared)
end

function ZO_AssignableUtilityWheel_Keyboard:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Remove
        {
            name = GetString(SI_ABILITY_ACTION_CLEAR_SLOT),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local slotId = self.mouseOverSlot.slotNum
                ClearSlot(slotId)
                PlaySound(SOUNDS.QUICKSLOT_CLEAR)
            end,
        },
    }
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
        local slot = CreateControlFromVirtual("WheelSlot"..i, self.control, "ZO_AssignableUtilityWheelSlot_Keyboard_Template")

        self.slots[i] = slot
        slot.button = slot:GetNamedChild("Button")
        slot.button.slotNum = i
        slot.button.object = self
        slot.icon = slot:GetNamedChild("Icon")
        slot.countText = slot:GetNamedChild("CountText")
        slot.nameLabel = slot:GetNamedChild("Label")

        ZO_ActionSlot_SetupSlot(slot.icon, slot.button, "EsoUI/Art/Quickslots/quickslot_emptySlot.dds")
        ZO_CreateSparkleAnimation(slot)
    end

    self:PerformSlotLayout()
end

function ZO_AssignableUtilityWheel_Keyboard:DoSlotUpdate(physicalSlot, playAnimation)
    local slot = self.slots[physicalSlot]
    if slot then
        local physicalSlotType = GetSlotType(physicalSlot)
        slot.nameLabel:SetText("")

        --TODO: Support the other action types
        if physicalSlotType == ACTION_TYPE_NOTHING then
            ZO_ActionSlot_SetupSlot(slot.icon, slot.button, "EsoUI/Art/Quickslots/quickslot_emptySlot.dds")
            slot.nameLabel:SetText(GetString(SI_QUICKSLOTS_EMPTY))
        elseif physicalSlotType == ACTION_TYPE_EMOTE then
            local slotIcon = "EsoUI/Art/Quickslots/quickslot_emptySlot.dds"
            local name = GetString(SI_QUICKSLOTS_EMPTY)
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
            ZO_ActionSlot_SetupSlot(slot.icon, slot.button, slotIcon)
            slot.nameLabel:SetText(name)
        elseif physicalSlotType == ACTION_TYPE_QUICK_CHAT then
            local slotIcon = "EsoUI/Art/Quickslots/quickslot_emptySlot.dds"
            local name = GetString(SI_QUICKSLOTS_EMPTY)
            local quickChatId = GetSlotBoundId(physicalSlot)
            if QUICK_CHAT_MANAGER:HasQuickChat(quickChatId) then
                slotIcon = GetSharedQuickChatIcon()
                name = QUICK_CHAT_MANAGER:GetFormattedQuickChatName(quickChatId)
            end
            ZO_ActionSlot_SetupSlot(slot.icon, slot.button, slotIcon)
            slot.nameLabel:SetText(name)
        else
            local slotIcon = GetSlotTexture(physicalSlot)
            local itemCount = GetSlotItemCount(physicalSlot)

            ZO_ActionSlot_SetupSlot(slot.icon, slot.button, slotIcon)
        end

        local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
        if mouseOverControl == slot.button then
            ZO_AbilitySlot_OnMouseEnter(slot.button)
        end

        if physicalSlotType ~= ACTION_TYPE_NOTHING and playAnimation and not slot:IsHidden() then
            ZO_PlaySparkleAnimation(slot)
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

    if IsSlotUsed(slotControl.slotNum) then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    else
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_AssignableUtilityWheel_Keyboard:OnMouseExitUtilitySlot(slotControl)
    if slotControl.animation then
        slotControl.animation:PlayBackward()
    end

    self.mouseOverSlot = nil
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_UtilityWheelSlotControl_OnInitialize(control)
    local button = control:GetNamedChild("Button")
    button:SetDrawTier(DT_MEDIUM)
    button:SetDrawLayer(DL_BACKGROUND)
    button:SetMouseOverTexture(nil)
    button.slotType = ABILITY_SLOT_TYPE_UTILITY

    local glow = control:GetNamedChild("Glow")
    --TODO: Move this animation here
    button.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("QuickslotGlowAlphaAnimation", glow)

    local icon = control:GetNamedChild("Icon")
    icon:SetDrawTier(DT_MEDIUM)
    icon:SetDrawLayer(DL_BACKGROUND)
end