
function ZO_GamepadEditBox_FocusGained(editControl)
    editControl.descriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_ACCEPT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                editControl:LoseFocus()
            end,
            sound = SOUNDS.DIALOG_ACCEPT,
        },
        {
            name = GetString(SI_CANCEL),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                editControl:SetText(editControl.oldText)
                editControl:LoseFocus()
            end,
            sound = SOUNDS.DIALOG_DECLINE,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Edit Box Accept",
            ethereal = true,
            keybind = "DIALOG_PRIMARY",
            callback = function()
                editControl:LoseFocus()
            end,
            sound = SOUNDS.DIALOG_ACCEPT,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Edit Box Cancel",
            ethereal = true,
            keybind = "DIALOG_NEGATIVE",
            callback = function()
                editControl:SetText(editControl.oldText)
                editControl:LoseFocus()
            end,
            sound = SOUNDS.DIALOG_DECLINE,
        },
    }

    editControl.oldText = editControl:GetText() 
    editControl.m_keybindState = KEYBIND_STRIP:PushKeybindGroupState()
    KEYBIND_STRIP:RemoveDefaultExit(editControl.m_keybindState)
    KEYBIND_STRIP:AddKeybindButtonGroup(editControl.descriptor, editControl.m_keybindState)
end

function ZO_GamepadEditBox_FocusLost(editControl)
    if editControl.descriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(editControl.descriptor, editControl.m_keybindState)
        KEYBIND_STRIP:RestoreDefaultExit(editControl.m_keybindState)
        KEYBIND_STRIP:PopKeybindGroupState()
    end

    if editControl.focusLostCallback then
        editControl.focusLostCallback(editControl)
    end
end