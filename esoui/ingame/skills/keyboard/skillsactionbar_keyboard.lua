-----------------------------
-- Keyboard Skills Action Bar Slot
-----------------------------

ZO_SkillsActionBarSlot_Keyboard = ZO_SkillsActionBarSlot:Subclass()

function ZO_SkillsActionBarSlot_Keyboard:AddToMouseInputGroup(inputGroup, inputType)
    if self.button then
        inputGroup:Add(self.button, inputType)
    end
end

function ZO_SkillsActionBarSlot_Keyboard:OnMouseEnter()
    ClearTooltip(SkillTooltip)
    if self.skillProgressionData then
        InitializeTooltip(SkillTooltip, self.control, BOTTOM, 0, -5, TOP)
        self.skillProgressionData:SetKeyboardTooltip(SkillTooltip)
    end
end

function ZO_SkillsActionBarSlot_Keyboard:OnMouseExit()
    ClearTooltip(SkillTooltip)
end

function ZO_SkillsActionBarSlot_Keyboard.Ability_OnMouseEnter(control)
    control.owner:OnMouseEnter()
end

function ZO_SkillsActionBarSlot_Keyboard.Ability_OnMouseExit(control)
    control.owner:OnMouseExit()
end

-----------------------------
-- Keyboard Skills Action Bar - Class that builds a read only display of a skills action bar
-----------------------------

ZO_SkillsActionBar_Keyboard = ZO_SkillsActionBar:Subclass()

function ZO_SkillsActionBar_Keyboard:AddSlotsToMouseInputGroup(inputGroup, inputType)
    for _, slot in ipairs(self.slots) do
        slot:AddToMouseInputGroup(inputGroup, inputType)
    end
end