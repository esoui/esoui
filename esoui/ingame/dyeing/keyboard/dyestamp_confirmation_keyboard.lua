ZO_DyeStamp_Confirmation_Keyboard = ZO_DyeStamp_Confirmation_Base:Subclass()

function ZO_DyeStamp_Confirmation_Keyboard:New(...)
    return ZO_DyeStamp_Confirmation_Base.New(self, ...)
end

function ZO_DyeStamp_Confirmation_Keyboard:Initialize(control)
    DYE_STAMP_CONFIRMATION_KEYBOARD_SCENE = ZO_Scene:New("dyeStampConfirmationKeyboard", SCENE_MANAGER)
    SYSTEMS:RegisterKeyboardRootScene("dyeStampConfirmation", DYE_STAMP_CONFIRMATION_KEYBOARD_SCENE)

    ZO_DyeStamp_Confirmation_Base.Initialize(self, control, DYE_STAMP_CONFIRMATION_KEYBOARD_SCENE)
    self.rotationArea = self.control:GetNamedChild("RotationArea")
end

function ZO_DyeStamp_Confirmation_Base:AddExitKey()
    -- Special exit button
    local exit = 
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,
        name = GetString(SI_EXIT_BUTTON),
        keybind = "UI_SHORTCUT_EXIT",
        callback = function() self:EndConfirmation() end,
    }
    table.insert(self.keybindStripDescriptor, exit)
end

function ZO_DyeStamp_Confirmation_Keyboard_OnInitialize(control)
    DYESTAMP_CONFIRMATION_KEYBOARD = ZO_DyeStamp_Confirmation_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject("dyeStamp_Confirmation", DYESTAMP_CONFIRMATION_KEYBOARD)
end