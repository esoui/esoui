ZO_TamrielTomesIntroScreen_Keyboard = ZO_TamrielTomesIntroScreen_Shared:Subclass()

function ZO_TamrielTomesIntroScreen_Keyboard:Initialize(control)
    TAMRIEL_TOMES_INTRO_SCENE_KEYBOARD = ZO_Scene:New("TamrielTomesIntroSceneKeyboard", SCENE_MANAGER)

    SYSTEMS:RegisterKeyboardRootScene("tamrielTomesIntro", TAMRIEL_TOMES_INTRO_SCENE_KEYBOARD)

    local HIGHLIGHT_TEMPLATE = "ZO_TamrielTomesIntroHighlight_Keyboard"
    ZO_TamrielTomesIntroScreen_Shared.Initialize(self, control, TAMRIEL_TOMES_INTRO_SCENE_KEYBOARD, HIGHLIGHT_TEMPLATE)
end

function ZO_TamrielTomesIntroScreen_Keyboard:OnDeferredInitialize()
    ZO_TamrielTomesIntroScreen_Shared.OnDeferredInitialize(self)

    self.continueButton = self.control:GetNamedChild("ButtonContainerContinueButton")
    --self.continueButton:SetClickSound() -- TODO TAMRIEL TOMES
    self.continueButton:SetHandler("OnClicked", function() self:AdvanceToTome() end)

    self.continueButton:SetText(GetString(SI_TAMRIEL_TOMES_INTRO_CONTINUE_ACTION))
end


function ZO_TamrielTomesIntroScreen_Keyboard.OnControlInitialized(control)
    TAMRIEL_TOMES_INTRO_SCREEN_KEYBOARD = ZO_TamrielTomesIntroScreen_Keyboard:New(control)
end
