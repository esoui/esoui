QuickslotActionButton = ActionButton:Subclass()

function QuickslotActionButton:Initialize(...)
    ActionButton.Initialize(self, ...)

    self.button.tooltip = ItemTooltip
end

function QuickslotActionButton:GetSlot()
    local slotNum = GetCurrentQuickslot()
    return slotNum
end

function QuickslotActionButton:OnRelease()
    if self.itemQtyFailure then
        PlaySound(SOUNDS.QUICKSLOT_USE_EMPTY)
    end

    ActionButton.OnRelease(self)
end

function QuickslotActionButton:ApplyStyle(template)
    ActionButton.ApplyStyle(self, template)

    local cooldownPercent = 1
    if IsInGamepadPreferredMode() and self.showingCooldown then
        cooldownPercent = self.icon.percentComplete
    end

    self:SetCooldownPercentComplete(cooldownPercent)
    self:SetCooldownEdgeState(self.showingCooldown)
end

function QuickslotActionButton:FormatCount(count)
    local USE_LOWERCASE_NUMBER_SUFFIXES = false
    local abbreviatedCount = ZO_AbbreviateAndLocalizeRadialMenuEntryCount(count, USE_LOWERCASE_NUMBER_SUFFIXES)
    return abbreviatedCount
end
