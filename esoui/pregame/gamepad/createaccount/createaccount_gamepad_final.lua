function CreateAccount_Gamepad_Final_Initialize(control)
    control.keybindStripDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            disabledDuringSceneHiding = true,
            name = GetString(SI_CONSOLE_PREGANE_TRIAL_ADVANCE),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                PlaySound(SOUNDS.POSITIVE_CLICK)
                PregameStateManager_AdvanceState()
            end,
        },
    }

    local note3Label = control:GetNamedChild("ContainerScrollContainerScrollChildNote3")
    local note3StringId = GetPlatformServiceType() == PLATFORM_SERVICE_TYPE_DMM and SI_CREATEACCOUNT_SUCCESS_NOTE_3_DMM or SI_CREATEACCOUNT_SUCCESS_NOTE_3
    note3Label:SetText(GetString(note3StringId))

    local createAccount_Gamepad_Final_Fragment = ZO_FadeSceneFragment:New(control)
    CREATE_ACCOUNT_FINAL_GAMEPAD_SCENE = ZO_Scene:New("CreateAccount_Gamepad_Final", SCENE_MANAGER)
    CREATE_ACCOUNT_FINAL_GAMEPAD_SCENE:AddFragment(createAccount_Gamepad_Final_Fragment)
    CREATE_ACCOUNT_FINAL_GAMEPAD_SCENE:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)

    local function StateChanged(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(control.keybindStripDescriptor)
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(control.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end

    CREATE_ACCOUNT_FINAL_GAMEPAD_SCENE:RegisterCallback("StateChange", StateChanged)
end