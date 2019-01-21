--[[
    The KeyboardAssignableActionBar shows and lets you manage what your current pending skill assignments will be inside the Skills UI.
    It's distinct from the "real" action bar in that only handles skills, it doesn't necessarily care about the state of each ability, and it can change
    without changing the "real" action bar.
]]--

ZO_KeyboardAssignableActionBar = ZO_Object:Subclass()

function ZO_KeyboardAssignableActionBar:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_KeyboardAssignableActionBar:Initialize(control)
    self.control = control

    self.hotbarSwap = ZO_KeyboardAssignableActionBarHotbarSwap:New(self.control:GetNamedChild("HotbarSwap"))
    self.buttons =
    {
       ZO_KeyboardAssignableActionBarButton:New(self.control:GetNamedChild("Button1"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1),
       ZO_KeyboardAssignableActionBarButton:New(self.control:GetNamedChild("Button2"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 2),
       ZO_KeyboardAssignableActionBarButton:New(self.control:GetNamedChild("Button3"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 3),
       ZO_KeyboardAssignableActionBarButton:New(self.control:GetNamedChild("Button4"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 4),
       ZO_KeyboardAssignableActionBarButton:New(self.control:GetNamedChild("Button5"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 5),

       ZO_KeyboardAssignableActionBarButton:New(self.control:GetNamedChild("Button6"), ACTION_BAR_ULTIMATE_SLOT_INDEX + 1),
    }
    self:SetupHotbarSwapAnimationComplete()

    local function OnSlotUpdated(hotbarCategory, slotId)
        if hotbarCategory == ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarCategory() then
            local button = self.buttons[slotId - ACTION_BAR_FIRST_NORMAL_SLOT_INDEX]
            if button then
                button:Refresh()
            end
        end
    end
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("SlotUpdated", OnSlotUpdated)

    local function OnCurrentHotbarUpdated(hotbarCategory, oldHotbarCategory)
        if not ACTION_BAR_ASSIGNMENT_MANAGER:IsHotbarSwapAnimationPlaying() then
            if not self.control:IsHidden() and oldHotbarCategory ~= hotbarCategory then
                self:PlayHotbarSwapAnimation()
            else
                self:RefreshAllButtons()
            end
        end
    end
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("CurrentHotbarUpdated", OnCurrentHotbarUpdated)

    local function OnCursorPickup(eventCode, cursorType, ...)
        if cursorType == MOUSE_CONTENT_ACTION then
            local actionType, _, actionId = ...
            if actionType == ACTION_TYPE_ABILITY and actionId ~= 0 then
                local abilityIndex = actionId
                self:ShowDropCalloutsForAbility(abilityIndex)
                PlaySound(SOUNDS.ABILITY_PICKED_UP)
            end
        end
    end
    EVENT_MANAGER:RegisterForEvent("KeyboardAssignableActionBar", EVENT_CURSOR_PICKUP, OnCursorPickup)

    local function OnCursorDropped(eventCode, cursorType)
        if cursorType == MOUSE_CONTENT_ACTION then
            self:HideDropCallouts()
        end
    end
    EVENT_MANAGER:RegisterForEvent("KeyboardAssignableActionBar", EVENT_CURSOR_DROPPED, OnCursorDropped)
end

function ZO_KeyboardAssignableActionBar:GetHotbarSwap()
    return self.hotbarSwap
end

function ZO_KeyboardAssignableActionBar:RefreshAllButtons()
    for _, button in ipairs(self.buttons) do
        button:Refresh()
    end
end

function ZO_KeyboardAssignableActionBar:HideDropCallouts()
    for _, button in ipairs(self.buttons) do
        button:HideDropCallout()
    end
end

function ZO_KeyboardAssignableActionBar:ShowDropCalloutsForAbility(abilityIndex)
    for _, button in ipairs(self.buttons) do
        local isValid = IsValidAbilityForSlot(abilityIndex, button.slotId)
        button:ShowDropCallout(isValid)
    end
end

function ZO_KeyboardAssignableActionBar:PlayHotbarSwapAnimation()
    ACTION_BAR_ASSIGNMENT_MANAGER:SetIsHotbarSwapAnimationPlaying(true)
    for _, button in ipairs(self.buttons) do
        button.hotbarSwapAnimation:PlayFromStart()
    end
    self.hotbarSwap:Refresh()
end

function ZO_KeyboardAssignableActionBar:SetupHotbarSwapAnimationComplete()
    -- A hotbar is made up of N buttons and N button animations, but we only want to trigger this handler once.
    -- Since each animation ends at the same time, we can just register to the first button as a stand-in for all of the buttons.
    self.buttons[1].hotbarSwapAnimation:SetHandler("OnStop", function()
        ACTION_BAR_ASSIGNMENT_MANAGER:SetIsHotbarSwapAnimationPlaying(false)
        -- The bar state may have changed during the animation (so it was deferred), but after the midpoint (so it wouldn't be reflected during that refresh)
        -- Refresh an extra time for good measure
        self:RefreshAllButtons()
        self.hotbarSwap:Refresh()
    end)
end

local ACTION_BUTTON_BORDERS =
{
    normal = "EsoUI/Art/ActionBar/abilityFrame64_up.dds",
    mouseDown = "EsoUI/Art/ActionBar/abilityFrame64_down.dds",
}

ZO_KeyboardAssignableActionBarButton = ZO_Object:Subclass()

function ZO_KeyboardAssignableActionBarButton:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_KeyboardAssignableActionBarButton:Initialize(control, slotId)
    self.slotId = slotId
    self.isMousedOver = false

    self.icon = control:GetNamedChild("Icon")

    self.button = control:GetNamedChild("Button")
    self.button.owner = self

    self.dropCallout = control:GetNamedChild("DropCallout")

    local buttonTextLabel = control:GetNamedChild("ButtonText")
    local keybindName = string.format("ACTION_BUTTON_%d", slotId)
    local HIDE_UNBOUND = false
    ZO_Keybindings_RegisterLabelForBindingUpdate(buttonTextLabel, keybindName, HIDE_UNBOUND)

    self:SetupHotbarSwapAnimation(control:GetNamedChild("FlipCard"))

    self:Refresh()
end

function ZO_KeyboardAssignableActionBarButton:SetupHotbarSwapAnimation(flipCard)
    local timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("HotbarSwapAnimation", flipCard)
    local width, height = flipCard:GetDimensions()

    local firstAnimation = timeline:GetFirstAnimation()
    firstAnimation:SetStartAndEndWidth(width, width)
    firstAnimation:SetStartAndEndHeight(height, 0)
    firstAnimation:SetHandler("OnStop", function()
        -- delay refresh until the icon is invisible
        self:Refresh()
    end)

    local lastAnimation = timeline:GetLastAnimation()
    lastAnimation:SetStartAndEndWidth(width, width)
    lastAnimation:SetStartAndEndHeight(0, height)

    self.hotbarSwapAnimation = timeline
end

function ZO_KeyboardAssignableActionBarButton:Refresh()
    local hotbar = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
    local slotData = hotbar:GetSlotData(self.slotId)
    local iconTexture = slotData:GetIcon()
    if iconTexture then
        ZO_ActionSlot_SetupSlot(self.icon, self.button, iconTexture, ACTION_BUTTON_BORDERS.normal, ACTION_BUTTON_BORDERS.mouseDown)
    else
        ZO_ActionSlot_ClearSlot(self.icon, self.button, ACTION_BUTTON_BORDERS.normal, ACTION_BUTTON_BORDERS.mouseDown)
    end

    local DONT_DESATURATE = false
    ZO_ActionSlot_SetUnusable(self.icon, not slotData:IsUsable(), DONT_DESATURATE)

    if self.isMousedOver then
        self:ShowTooltip()
    end
end

function ZO_KeyboardAssignableActionBarButton:ShowTooltip()
    self:HideTooltip() -- Hide the old tooltip unconditionally, it may be a different tooltip control

    local slotData = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar():GetSlotData(self.slotId)
    local tooltip = slotData:GetKeyboardTooltipControl()
    if tooltip then
        InitializeTooltip(tooltip, self.button, BOTTOM, 0, -5, TOP)
        slotData:SetKeyboardTooltip(tooltip)
        self.lastTooltip = tooltip
    end
end

function ZO_KeyboardAssignableActionBarButton:HideTooltip()
    if self.lastTooltip then
        ClearTooltip(self.lastTooltip)
        self.lastTooltip = nil
    end
end

function ZO_KeyboardAssignableActionBarButton:ShowDropCallout(isValid)
    if not isValid then
        self.dropCallout:SetColor(1, 0, 0, 1)
    else
        self.dropCallout:SetColor(1, 1, 1, 1)
    end

    self.dropCallout:SetHidden(false)
end

function ZO_KeyboardAssignableActionBarButton:HideDropCallout()
    self.dropCallout:SetHidden(true)
end

function ZO_KeyboardAssignableActionBarButton:TryCursorPickup()
    if GetCursorContentType() == MOUSE_CONTENT_EMPTY then
        local hotbar = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
        local slotData = hotbar:GetSlotData(self.slotId)
        if slotData then
            slotData:TryCursorPickup()
            hotbar:ClearSlot(self.slotId)
        end
    end
end

function ZO_KeyboardAssignableActionBarButton:TryCursorPlace()
    if GetCursorContentType() == MOUSE_CONTENT_EMPTY then
        return
    end

    local hotbar = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
    local oldSlotData = hotbar:GetSlotData(self.slotId)
    if oldSlotData == nil then
        -- invalid slot
        return
    end

    local abilityId = GetCursorAbilityId()
    if abilityId == nil then
        return
    end

    local progressionData = SKILLS_DATA_MANAGER:GetProgressionDataByAbilityId(abilityId)
    if progressionData and hotbar:AssignSkillToSlot(self.slotId, progressionData:GetSkillData()) then
        ClearCursor()
        oldSlotData:TryCursorPickup()
    end
end

function ZO_KeyboardAssignableActionBarButton:ShowActionMenu()
    local hotbar = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
    local slotData = hotbar:GetSlotData(self.slotId)

    if slotData and not slotData:IsEmpty() then
        ClearMenu()
        AddMenuItem(GetString(SI_ABILITY_ACTION_CLEAR_SLOT), function()
            hotbar:ClearSlot(self.slotId)
        end)
        ShowMenu(self.button)
    end
end

ZO_KeyboardAssignableActionBarHotbarSwap = ZO_Object:Subclass()

function ZO_KeyboardAssignableActionBarHotbarSwap:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_KeyboardAssignableActionBarHotbarSwap:Initialize(control)
    self.control = control
    control.owner = self

    self.hotbarNameLabel = control:GetNamedChild("HotbarName")

    self:RegisterForEvents()

    self:Refresh()
end

function ZO_KeyboardAssignableActionBarHotbarSwap:GetControl()
    return self.control
end

function ZO_KeyboardAssignableActionBarHotbarSwap:GetHotbarNameLabel()
    return self.hotbarNameLabel
end

function ZO_KeyboardAssignableActionBarHotbarSwap:RegisterForEvents()
    local function OnCurrentHotbarUpdated(hotbarCategory)
        self:Refresh()
    end
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("CurrentHotbarUpdated", OnCurrentHotbarUpdated)

    local function OnHotbarSwapVisibleStateChanged()
        self:Refresh()
    end
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("HotbarSwapVisibleStateChanged", OnHotbarSwapVisibleStateChanged)
end

function ZO_KeyboardAssignableActionBarHotbarSwap:Refresh()
    self.enabled = ACTION_BAR_ASSIGNMENT_MANAGER:CanCycleHotbars()

    local hotbarCategory = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarCategory()
    self.activeWeaponPair = GetWeaponPairFromHotbarCategory(hotbarCategory)

    if not ACTION_BAR_ASSIGNMENT_MANAGER:ShouldShowHotbarSwap() then
        self.control:SetHidden(true)
        return
    end

    self.control:SetHidden(false)
    self.control:SetEnabled(self.enabled)
    if self.activeWeaponPair ~= ACTIVE_WEAPON_PAIR_NONE then
        self.control:SetText(zo_strformat(SI_ACTIVE_WEAPON_PAIR, self.activeWeaponPair))
    else
        self.control:SetText("")
    end

    --We don't show any text for the primary and backup bars
    if self.activeWeaponPair == ACTIVE_WEAPON_PAIR_NONE then
        local hotbarName = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbarName()
        self.hotbarNameLabel:SetHidden(false)
        self.hotbarNameLabel:SetText(hotbarName)
    else
        self.hotbarNameLabel:SetHidden(true)
        --Set to empty string for the pointer box tutorial that anchors to this
        self.hotbarNameLabel:SetText("")
    end
end

function ZO_KeyboardAssignableActionBarHotbarSwap:SwapBars()
    ACTION_BAR_ASSIGNMENT_MANAGER:CycleCurrentHotbar()
end

function ZO_KeyboardAssignableActionBarHotbarSwap:ShowTooltip()
    InitializeTooltip(InformationTooltip, self.control, RIGHT, -5, 0)
    InformationTooltip:AddLine(GetString(SI_WEAPON_SWAP_TOOLTIP), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())

    if not self.enabled then
        InformationTooltip:AddLine(GetString(SI_WEAPON_SWAP_DISABLED_TOOLTIP), "", ZO_ERROR_COLOR:UnpackRGB())
    end
end

function ZO_KeyboardAssignableActionBarHotbarSwap:HideTooltip()
    ClearTooltip(InformationTooltip)
end

-- Button XML
function ZO_KeyboardAssignableActionBarButton_OnMouseEnter(control)
    control.owner.isMousedOver = true
    control.owner:ShowTooltip()
end

function ZO_KeyboardAssignableActionBarButton_OnMouseExit(control)
    control.owner.isMousedOver = false
    control.owner:HideTooltip()
end

function ZO_KeyboardAssignableActionBarButton_OnMouseClicked(control, buttonId)
    if buttonId == MOUSE_BUTTON_INDEX_LEFT then
        control.owner:TryCursorPlace()
    elseif buttonId == MOUSE_BUTTON_INDEX_RIGHT then
        control.owner:ShowActionMenu()
    end
end

function ZO_KeyboardAssignableActionBarButton_OnDragStart(control)
    control.owner:TryCursorPickup()
end

function ZO_KeyboardAssignableActionBarButton_OnReceiveDrag(control)
    control.owner:TryCursorPlace()
end

-- Weapon Swap XML
function ZO_KeyboardAssignableActionBarHotbarSwap_OnMouseEnter(control)
    control.owner:ShowTooltip()
end

function ZO_KeyboardAssignableActionBarHotbarSwap_OnMouseExit(control)
    control.owner:HideTooltip()
end

function ZO_KeyboardAssignableActionBarHotbarSwap_OnClicked(control)
    control.owner:SwapBars()
end