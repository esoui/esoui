local CreditsScreen_Keyboard = CreditsScreen_Base:Subclass()

function CreditsScreen_Keyboard:Initialize(control)
    -- NOTE: Templates must be unique due to how the object pools name controls as they're created.
    local POOL_TEMPLATES =
    {
        [GAME_CREDITS_ENTRY_TYPE_DEPARTMENT_HEADER] = "ZO_GameCreditsDepartment",
        [GAME_CREDITS_ENTRY_TYPE_SECTION_HEADER] = "ZO_GameCreditsSection",
        [GAME_CREDITS_ENTRY_TYPE_SECTION_TEXT] = "ZO_GameCreditsNames",
        [GAME_CREDITS_ENTRY_TYPE_SECTION_TEXT_BLOCK] = "ZO_GameCreditsTextBlock",
        [GAME_CREDITS_ENTRY_TYPE_COMPANY_LOGO] = "ZO_GameCreditsLogo",
        [GAME_CREDITS_ENTRY_TYPE_BACKGROUND_SWITCH] = "ZO_GameCreditsBGSwitch",
        [GAME_CREDITS_ENTRY_TYPE_PADDING_SECTION] = "ZO_GameCreditsPadding",
    }
    CreditsScreen_Base.Initialize(self, control, POOL_TEMPLATES)
end

function CreditsScreen_Keyboard:SetOnExitCallback(onExitCallback)
    self.onExitCallback = onExitCallback
end

function CreditsScreen_Keyboard:Exit()
    if self.onExitCallback then
        self.onExitCallback()
    end
end

function CreditsScreen_Keyboard:IsPreferredScreen()
    return not IsInGamepadPreferredMode()
end


function ZO_GameCredits_Keyboard_Initialize(control)
    GAME_CREDITS_KEYBOARD = CreditsScreen_Keyboard:New(control)
end

function ZO_GameCredits_Keyboard_OnKeyUp()
    GAME_CREDITS_KEYBOARD:Exit()
end

function ZO_GameCredits_Keyboard_OnMouseUp(upInside)
    if upInside then
        GAME_CREDITS_KEYBOARD:Exit()
    end
end