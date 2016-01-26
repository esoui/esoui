function LinkAccountScreen_Gamepad_Final_Initialize(self)
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

    local fillText = self:GetNamedChild("Container"):GetNamedChild("FillText")
    local isXbox = GetUIPlatform() == UI_PLATFORM_XBOX
    fillText:SetText(GetString(isXbox and SI_CONSOLE_LINKACCOUNT_SUCCESS_FULL_XBOX or SI_CONSOLE_LINKACCOUNT_SUCCESS_FULL_PS4))

    local linkAccountScreen_Gamepad_Final_Fragment = ZO_FadeSceneFragment:New(self)
    LINK_ACCOUNT_FINAL_GAMEPAD_SCENE = ZO_Scene:New("LinkAccountScreen_Gamepad_Final", SCENE_MANAGER)
    LINK_ACCOUNT_FINAL_GAMEPAD_SCENE:AddFragment(linkAccountScreen_Gamepad_Final_Fragment)
    LINK_ACCOUNT_FINAL_GAMEPAD_SCENE:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)

    local StateChanged = function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end

    LINK_ACCOUNT_FINAL_GAMEPAD_SCENE:RegisterCallback("StateChange", StateChanged)
end
