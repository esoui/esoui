local MAX_SCROLL_SPEED_MODIFIER = 5
local MIN_SCROLL_SPEED_MODIFIER = 1

local CreditsScreen_Gamepad = CreditsScreen_Base:Subclass()

function CreditsScreen_Gamepad:Initialize(control)
    -- NOTE: Templates must be unique due to how the object pools name controls as they're created.
    local POOL_TEMPLATES =
    {
        [GAME_CREDITS_ENTRY_TYPE_DEPARTMENT_HEADER] = "ZO_GameCreditsDepartmentGamepad",
        [GAME_CREDITS_ENTRY_TYPE_SECTION_HEADER] = "ZO_GameCreditsSectionGamepad",
        [GAME_CREDITS_ENTRY_TYPE_SECTION_TEXT] = "ZO_GameCreditsNamesGamepad",
        [GAME_CREDITS_ENTRY_TYPE_SECTION_TEXT_BLOCK] = "ZO_GameCreditsTextBlockGamepad",
        [GAME_CREDITS_ENTRY_TYPE_COMPANY_LOGO] = "ZO_GameCreditsLogoGamepad",
        [GAME_CREDITS_ENTRY_TYPE_BACKGROUND_SWITCH] = "ZO_GameCreditsBGSwitchGamepad",
        [GAME_CREDITS_ENTRY_TYPE_PADDING_SECTION] = "ZO_GameCreditsPaddingGamepad",
    }
    CreditsScreen_Base.Initialize(self, control, POOL_TEMPLATES)

    self.creditDescriptor =
    {
        {
            name = GetString(SI_CANCEL),
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                self:Exit()
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Game Credits Faster",
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            ethereal = true,
            callback = function()
                local speedMultiplier = self:GetScrollSpeedMultiplier()
                if speedMultiplier < MAX_SCROLL_SPEED_MODIFIER then
                    self:SetScrollSpeedMultiplier(speedMultiplier + 1)
                end
            end,
        },
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad Game Credits Slower",
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            ethereal = true,
            callback = function()
                local speedMultiplier = self:GetScrollSpeedMultiplier()
                if speedMultiplier > MIN_SCROLL_SPEED_MODIFIER then
                    self:SetScrollSpeedMultiplier(speedMultiplier - 1)
                end
            end,
        },
    }
end

function CreditsScreen_Gamepad:Exit()
    SCENE_MANAGER:HideCurrentScene()
end

function CreditsScreen_Gamepad:IsPreferredScreen()
    return IsInGamepadPreferredMode()
end

function CreditsScreen_Gamepad:ShowCredits()
    self.keybindState = KEYBIND_STRIP:PushKeybindGroupState()
    KEYBIND_STRIP:RemoveDefaultExit(self.keybindState)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.creditDescriptor, self.keybindState)

    CreditsScreen_Base.ShowCredits(self)
end

function CreditsScreen_Gamepad:StopCredits()
    CreditsScreen_Base.StopCredits(self)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.creditDescriptor, self.keybindState)
    KEYBIND_STRIP:RestoreDefaultExit(self.keybindState)
    KEYBIND_STRIP:PopKeybindGroupState()
end

function ZO_GameCredits_Gamepad_Initialize(control)
    GAME_CREDITS_GAMEPAD = CreditsScreen_Gamepad:New(control)
end