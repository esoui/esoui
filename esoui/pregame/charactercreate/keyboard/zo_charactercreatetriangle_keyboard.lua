ZO_CharacterCreateTriangle_Keyboard = ZO_CharacterCreateTriangle_Base:Subclass()

function ZO_CharacterCreateTriangle_Keyboard:New(...)
    return ZO_CharacterCreateTriangle_Base.New(self, ...)
end

function ZO_CharacterCreateTriangle_Keyboard:UpdateLockState()
    local enabled = self.lockState == TOGGLE_BUTTON_OPEN
    self.picker:SetEnabled(enabled)
    GetControl(self.thumb, "Glow"):SetHidden(not enabled)

    local backgroundControl = GetControl(self.control, "BG")
    if enabled then
        backgroundControl:SetTexture("EsoUI/Art/CharacterCreate/selectorTriangle.dds")
    else
        backgroundControl:SetTexture("EsoUI/Art/CharacterCreate/selectorTriangle_disabled.dds")
    end
end