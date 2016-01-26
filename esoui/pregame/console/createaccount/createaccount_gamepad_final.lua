function CreateAccount_Gamepad_Final_Initialize(self)
    self.keybindStripDescriptor =
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

    local createAccount_Gamepad_Final_Fragment = ZO_FadeSceneFragment:New(self)
    CREATE_ACCOUNT_FINAL_GAMEPAD_SCENE = ZO_Scene:New("CreateAccount_Gamepad_Final", SCENE_MANAGER)
    CREATE_ACCOUNT_FINAL_GAMEPAD_SCENE:AddFragment(createAccount_Gamepad_Final_Fragment)
    CREATE_ACCOUNT_FINAL_GAMEPAD_SCENE:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)

    local StateChanged = function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end

    CREATE_ACCOUNT_FINAL_GAMEPAD_SCENE:RegisterCallback("StateChange", StateChanged)
end