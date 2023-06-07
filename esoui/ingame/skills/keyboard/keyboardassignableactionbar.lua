--[[
    The KeyboardAssignableActionBar shows and lets you manage what your current pending skill assignments will be inside the Skills UI.
    It's distinct from the "real" action bar in that only handles skills, it doesn't necessarily care about the state of each ability, and it can change
    without changing the "real" action bar.
]]--

ZO_KeyboardAssignableActionBar = ZO_InitializingObject:Subclass()

function ZO_KeyboardAssignableActionBar:Initialize(control)
    self.control = control
    self.areHotbarEditsEnabled = true

    self.hotbarSwap = ZO_KeyboardAssignableActionBarHotbarSwap:New(self.control:GetNamedChild("HotbarSwap"))
    self.buttons =
    {
       ZO_KeyboardAssignableActionBarButton:New(self, self.control:GetNamedChild("Button1"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1),
       ZO_KeyboardAssignableActionBarButton:New(self, self.control:GetNamedChild("Button2"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 2),
       ZO_KeyboardAssignableActionBarButton:New(self, self.control:GetNamedChild("Button3"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 3),
       ZO_KeyboardAssignableActionBarButton:New(self, self.control:GetNamedChild("Button4"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 4),
       ZO_KeyboardAssignableActionBarButton:New(self, self.control:GetNamedChild("Button5"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 5),

       ZO_KeyboardAssignableActionBarButton:New(self, self.control:GetNamedChild("Button6"), ACTION_BAR_ULTIMATE_SLOT_INDEX + 1),
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
    ACTION_BAR_ASSIGNMENT_MANAGER:RegisterCallback("SlotNewStatusChanged", OnSlotUpdated)

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

    local function OnPlayerActivated(eventCode)
        self:HideDropCallouts()
    end
    EVENT_MANAGER:RegisterForEvent("KeyboardAssignableActionBar", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
end

function ZO_KeyboardAssignableActionBar:SetHotbarEditsEnabled(areHotbarEditsEnabled)
    self.areHotbarEditsEnabled = areHotbarEditsEnabled
end

function ZO_KeyboardAssignableActionBar:AreHotbarEditsEnabled()
    return self.areHotbarEditsEnabled
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
    mouseOver = "EsoUI/Art/ActionBar/actionBar_mouseOver.dds",
}

ZO_KeyboardAssignableActionBarButton = ZO_InitializingObject:Subclass()

function ZO_KeyboardAssignableActionBarButton:Initialize(hotbar, control, slotId)
    self.hotbar = hotbar
    self.slotId = slotId
    self.isMousedOver = false
    self.isSlotNew = false
    self.actionName = nil
    self.actionPriority = nil

    self.icon = control:GetNamedChild("Icon")
    self.lock = control:GetNamedChild("Lock")

    self.newIndicator = control:GetNamedChild("NewIndicator")
    self.newIndicatorIdle = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_KeyboardAssignableActionBarNewIndicator_Idle", self.newIndicator)
    self.newIndicatorFadeout = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_KeyboardAssignableActionBarNewIndicator_Fadeout", self.newIndicator)

    self.button = control:GetNamedChild("Button")
    self.button.owner = self

    self.dropCallout = control:GetNamedChild("DropCallout")

    self.buttonText = control:GetNamedChild("ButtonText")

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
    local hotbarData = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
    local slotData = hotbarData:GetSlotData(self.slotId)
    local iconTexture = slotData:GetIcon()
    local mouseDownFrameTexture = self.hotbar:AreHotbarEditsEnabled() and ACTION_BUTTON_BORDERS.mouseDown or ACTION_BUTTON_BORDERS.normal -- do not indicate pressed if it won't do anything
    local mouseOverFrameTexture = self.hotbar:AreHotbarEditsEnabled() and ACTION_BUTTON_BORDERS.mouseOver or "" -- do not indicate mouse over if we can't actually click it
    if iconTexture then
        ZO_ActionSlot_SetupSlot(self.icon, self.button, iconTexture, ACTION_BUTTON_BORDERS.normal, mouseDownFrameTexture, nil, mouseOverFrameTexture)
    else
        ZO_ActionSlot_ClearSlot(self.icon, self.button, ACTION_BUTTON_BORDERS.normal, mouseDownFrameTexture, nil, mouseOverFrameTexture)
    end

    self.lock:SetHidden(not hotbarData:IsSlotLocked(self.slotId))
    local isNew = hotbarData:IsSlotNew(self.slotId)
    if isNew ~= self.isSlotNew then
        self.isSlotNew = isNew
        if isNew then
            self.newIndicatorFadeout:Stop()
            self.newIndicatorIdle:PlayFromStart()
        else
            self.newIndicatorIdle:Stop()
            self.newIndicatorFadeout:PlayFromStart()
        end
    end

    local DONT_DESATURATE = false
    ZO_ActionSlot_SetUnusable(self.icon, not slotData:IsUsable(), DONT_DESATURATE)

    local KEYBOARD_MODE = false
    local actionName = ACTION_BAR_ASSIGNMENT_MANAGER:GetActionNameForSlot(self.slotId, hotbarData:GetHotbarCategory(), KEYBOARD_MODE)
    local actionPriority = ACTION_BAR_ASSIGNMENT_MANAGER:GetAutomaticCastPriorityForSlot(self.slotId, hotbarData:GetHotbarCategory())
    if actionName ~= self.actionName or actionPriority ~= self.actionPriority then
        ZO_Keybindings_UnregisterLabelForBindingUpdate(self.buttonText)
        if actionName then
            local HIDE_UNBOUND = false
            ZO_Keybindings_RegisterLabelForBindingUpdate(self.buttonText, actionName, HIDE_UNBOUND)
        elseif actionPriority then
            self.buttonText:SetText(tostring(actionPriority))
        else
            self.buttonText:SetText("")
        end
        self.actionName = actionName
        self.actionPriority = actionPriority
    end

    if self.isMousedOver then
        self:ShowTooltip()
    end
end

function ZO_KeyboardAssignableActionBarButton:ClearNewIndicator()
    ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar():ClearSlotNew(self.slotId)
end

function ZO_KeyboardAssignableActionBarButton:ShowTooltip()
    self:HideTooltip() -- Hide the old tooltip unconditionally, it may be a different tooltip control

    local hotbarData = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
    if hotbarData:IsSlotLocked(self.slotId) then
        InitializeTooltip(InformationTooltip, self.button, BOTTOM, 0, -5, TOP)
        local DEFAULT_FONT = ""
        InformationTooltip:AddLine(GetString(SI_ACTION_BAR_SLOT_LOCKED_HEADER), "ZoFontHeader", ZO_SELECTED_TEXT:UnpackRGBA())
        ZO_Tooltip_AddDivider(InformationTooltip)
        InformationTooltip:AddLine(hotbarData:GetSlotUnlockText(self.slotId), DEFAULT_FONT, ZO_ERROR_COLOR:UnpackRGBA())
        self.lastTooltip = InformationTooltip
    else
        local slotData = hotbarData:GetSlotData(self.slotId)
        local tooltip = slotData:GetKeyboardTooltipControl()
        if tooltip then
            InitializeTooltip(tooltip, self.button, BOTTOM, 0, -5, TOP)
            slotData:SetKeyboardTooltip(tooltip)
            self.lastTooltip = tooltip
        end
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
    if self.hotbar:AreHotbarEditsEnabled() then
        if GetCursorContentType() == MOUSE_CONTENT_EMPTY then
            local hotbarData = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
            local slotData = hotbarData:GetSlotData(self.slotId)
            if slotData then
                slotData:TryCursorPickup()
                hotbarData:ClearSlot(self.slotId)
            end
        end
    end
end

function ZO_KeyboardAssignableActionBarButton:TryCursorPlace()
    if not self.hotbar:AreHotbarEditsEnabled() then
        return
    end

    if GetCursorContentType() == MOUSE_CONTENT_EMPTY then
        return
    end

    local hotbarData = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
    local oldSlotData = hotbarData:GetSlotData(self.slotId)
    if oldSlotData == nil then
        -- invalid slot
        return
    end

    local abilityId = GetCursorAbilityId()
    if abilityId == nil then
        return
    end

    if hotbarData:AssignSkillToSlotByAbilityId(self.slotId, abilityId) then
        ClearCursor()
        oldSlotData:TryCursorPickup()
        PlaySound(SOUNDS.ABILITY_SLOTTED)
    end
end

function ZO_KeyboardAssignableActionBarButton:ShowActionMenu()
    if not self.hotbar:AreHotbarEditsEnabled() then
        return
    end 
    local hotbarData = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
    local slotData = hotbarData:GetSlotData(self.slotId)

    if slotData and not slotData:IsEmpty() and not IsActionSlotRestricted(self.slotId, hotbarData:GetHotbarCategory()) then
        ClearMenu()
        AddMenuItem(GetString(SI_ABILITY_ACTION_CLEAR_SLOT), function()
            if hotbarData:ClearSlot(self.slotId) then
                PlaySound(SOUNDS.ABILITY_SLOT_CLEARED)
            end
        end)
        ShowMenu(self.button)
    end
end

ZO_KeyboardAssignableActionBarHotbarSwap = ZO_InitializingObject:Subclass()

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
    control.owner:ClearNewIndicator()
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