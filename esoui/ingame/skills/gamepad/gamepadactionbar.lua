ZO_GamepadActionBar = ZO_Object:Subclass()

function ZO_GamepadActionBar:New(...)
    local assignableActionBar = ZO_Object.New(self)
    assignableActionBar:Initialize(...)
    return assignableActionBar
end

function ZO_GamepadActionBar:Initialize(control)
    self.control = control

    self.interpolator = ZO_SimpleControlScaleInterpolator:New(1.0, 1.28)

    self.buttons = {
        ZO_GamepadActionBarButton:New(self.control:GetNamedChild("Button1"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1),
        ZO_GamepadActionBarButton:New(self.control:GetNamedChild("Button2"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 2),
        ZO_GamepadActionBarButton:New(self.control:GetNamedChild("Button3"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 3),
        ZO_GamepadActionBarButton:New(self.control:GetNamedChild("Button4"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 4),
        ZO_GamepadActionBarButton:New(self.control:GetNamedChild("Button5"), ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 5),

        ZO_GamepadActionBarButton:New(self.control:GetNamedChild("Button6"), ACTION_BAR_ULTIMATE_SLOT_INDEX + 1),
    }

    local function Refresh()
        self:OnSkillsChanged()
    end

    local function MarkButtonSlotDirty(slotNum)
        self:MarkButtonSlotDirty(slotNum)
    end

    local function OnUpdateActionBar()
        self:RefreshDirtyButtons()
    end

    self.control:RegisterForEvent(EVENT_ACTION_SLOT_UPDATED, function (_, slotnum) MarkButtonSlotDirty(slotnum) end)
    self.control:RegisterForEvent(EVENT_ACTION_SLOTS_FULL_UPDATE, Refresh)
    EVENT_MANAGER:RegisterForUpdate(self.control:GetName(), 100, OnUpdateActionBar)
end

function ZO_GamepadActionBar:OnSkillsChanged()
    if not self.control:IsControlHidden() then
        self:RefreshAllButtons()
    end
end

function ZO_GamepadActionBar:MarkButtonSlotDirty(slotNum)
    if not self.control:IsControlHidden() then
        -- we need to convert absolute button slot position (slotNum) into our self.buttons position, which is offset by ACTION_BAR_FIRST_NORMAL_SLOT_INDEX
        local button = self.buttons[slotNum - ACTION_BAR_FIRST_NORMAL_SLOT_INDEX]
        if button and not button.noUpdates then
            button.markedDirty = true
        end
    end
end

function ZO_GamepadActionBar:Activate()
    self:RefreshAllButtons()
end

function ZO_GamepadActionBar:Deactivate()

end

function ZO_GamepadActionBar:GetControl()
    return self.control
end

function ZO_GamepadActionBar:RefreshAllButtons()
    for i, button in ipairs(self.buttons) do
        button:Refresh()
    end
end

function ZO_GamepadActionBar:RefreshDirtyButtons()
    for i, button in ipairs(self.buttons) do
        if button.markedDirty then
            button:Refresh()
            button.markedDirty = false
        end
    end
end

function ZO_GamepadActionBar:SetHighlightAll(highlightAll)
    for i, button in ipairs(self.buttons) do
        button:SetSelected(highlightAll, self.interpolator)
    end
end

ZO_GamepadActionBarButton = ZO_Object:Subclass()

function ZO_GamepadActionBarButton:New(...)
    local gamepadActionBarButton = ZO_Object.New(self)
    gamepadActionBarButton:Initialize(...)
    return gamepadActionBarButton
end

function ZO_GamepadActionBarButton:Initialize(control, slotId)
    self.control = control
    self.icon = self.control:GetNamedChild("Icon")
    self.highlight = self.control:GetNamedChild("Highlight")
    self.keybindLabel = self.control:GetNamedChild("KeybindLabel")
    self.frame = self.control:GetNamedChild("Frame")

    if self.keybindLabel then
        local HIDE_UNBOUND = false
        ZO_Keybindings_RegisterLabelForBindingUpdate(self.keybindLabel, "GAMEPAD_ACTION_BUTTON_" .. slotId, HIDE_UNBOUND)
    end

    self.slotId = slotId
end

function ZO_GamepadActionBarButton:GetSlotId()
    return self.slotId
end

function ZO_GamepadActionBarButton:IsUltimateSlot()
    return self.slotId == ACTION_BAR_ULTIMATE_SLOT_INDEX + 1
end

function ZO_GamepadActionBarButton:GetControl()
    return self.control
end

function ZO_GamepadActionBarButton:GetIconControl()
    return self.icon
end

function ZO_GamepadActionBarButton:SetSelected(selected, interpolator)
    if selected then
        interpolator:ScaleUp(self:GetIconControl())
    else
        interpolator:ScaleDown(self:GetIconControl())
    end

    if self.highlight then
        self.highlight:SetHidden(not selected)
    end

    if self.frame then
        local color = selected and ZO_SELECTED_TEXT or ZO_NORMAL_TEXT
        self.frame:SetEdgeColor(color:UnpackRGBA())
    end
end

function ZO_GamepadActionBarButton:Refresh()
    local slotType = GetSlotType(self:GetSlotId())
    if slotType == ACTION_TYPE_NOTHING then
        self.icon:SetHidden(true)
    else
        self.icon:SetHidden(false)
        local slotIcon = GetSlotTexture(self:GetSlotId())
        self.icon:SetTexture(slotIcon)
    end
end

function ZO_GamepadActionBarButton:ClearSlot()
    ClearSlot(self.slotId)
end

function ZO_GamepadActionBarButton:SetAbility(skillType, skillLineIndex, abilityIndex)
    SelectSlotSkillAbility(skillType, skillLineIndex, abilityIndex, self:GetSlotId())
end