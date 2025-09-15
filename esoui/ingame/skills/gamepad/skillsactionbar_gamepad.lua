-----------------------------
-- Gamepad Skills Action Bar Slot
-----------------------------

ZO_SkillsActionBarSlot_Gamepad = ZO_SkillsActionBarSlot:Subclass()

do
    local NOT_BOUND_ACTION_STRING = GetString(SI_ACTION_IS_NOT_BOUND)
    local DEFAULT_SHOW_AS_HOLD = nil

    function ZO_SkillsActionBarSlot_Gamepad:GetNarrationText()
        local narrations = {}

        --Get the binding narration
        local keyboardActionName, gamepadActionName = ACTION_BAR_ASSIGNMENT_MANAGER:GetKeyboardAndGamepadActionNameForSlot(self.slotIndex, self.actionBar:GetHotbarCategory())
        local bindingTextNarration = ZO_Keybindings_GetPreferredHighestPriorityNarrationStringFromActions(keyboardActionName, gamepadActionName, DEFAULT_SHOW_AS_HOLD) or NOT_BOUND_ACTION_STRING
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(bindingTextNarration))
        
        --Get the narration for the contents of the slot
        if self.skillProgressionData then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.skillProgressionData:GetFormattedName()))
        else
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_EMPTY_SKILLS_ENTRY_NARRATION)))
        end
        return narrations
    end
end

-----------------------------
-- Gamepad Skills Action Bar - Class that builds a read only display of a skills action bar
-----------------------------

ZO_SkillsActionBar_Gamepad = ZO_SkillsActionBar:Subclass()

function ZO_SkillsActionBar_Gamepad:GetNarrationText()
    local narrations = {}
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_GAMEPAD_SKILL_BAR_FORMATTER, GetString("SI_HOTBARCATEGORY", self.hotbarCategory))))
    if self:GetLocked() then
        --If the bar is locked, just narrate that it's locked, and don't bother narrating the individual slots
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_SCREEN_NARRATION_LOCKED_ICON_NARRATION)))
    else
        --Get the narration for each slot
        for _, slot in ipairs(self.slots) do
            ZO_AppendNarration(narrations, slot:GetNarrationText())
        end
    end
    return narrations
end