ZO_DyeStamp_Confirmation_Gamepad = ZO_DyeStamp_Confirmation_Base:Subclass()

function ZO_DyeStamp_Confirmation_Gamepad:New(...)
    return ZO_DyeStamp_Confirmation_Base.New(self, ...)
end

function ZO_DyeStamp_Confirmation_Gamepad:Initialize(control)
    DYE_STAMP_CONFIRMATION_GAMEPAD_SCENE = ZO_Scene:New("dyeStampConfirmationGamepad", SCENE_MANAGER)
    SYSTEMS:RegisterGamepadRootScene("dyeStampConfirmation", DYE_STAMP_CONFIRMATION_GAMEPAD_SCENE)

    ZO_DyeStamp_Confirmation_Base.Initialize(self, control, DYE_STAMP_CONFIRMATION_GAMEPAD_SCENE)
end

function ZO_DyeStamp_Confirmation_Base:AddExitKey()
    -- Special exit button
    local exit = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        name = GetString(SI_EXIT_BUTTON),
        keybind = "UI_SHORTCUT_NEGATIVE",
        callback = function() self:EndConfirmation() end,
    }
    table.insert(self.keybindStripDescriptor, exit)
end

function ZO_DyeStamp_Confirmation_Gamepad:OnShown()
    ZO_DyeStamp_Confirmation_Base.OnShown(self)
    DIRECTIONAL_INPUT:Activate(self, self.control)
end

function ZO_DyeStamp_Confirmation_Gamepad:OnHidden()
    ZO_DyeStamp_Confirmation_Base.OnHidden(self)
    DIRECTIONAL_INPUT:Deactivate(self)
end

function ZO_DyeStamp_Confirmation_Gamepad:UpdateDirectionalInput()
    -- Camera Spin.
    local x = DIRECTIONAL_INPUT:GetX(ZO_DI_RIGHT_STICK)
    if x ~= 0 then
        BeginItemPreviewSpin()
        self.isSpinning = true
    else
        if self.isSpinning then
            EndItemPreviewSpin()
            self.isSpinning = false
        end
    end
end

function ZO_DyeStamp_Confirmation_Gamepad_OnInitialize(control)
    DYESTAMP_CONFIRMATION_GAMEPAD = ZO_DyeStamp_Confirmation_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("dyeStamp_Confirmation", DYESTAMP_CONFIRMATION_GAMEPAD)
end