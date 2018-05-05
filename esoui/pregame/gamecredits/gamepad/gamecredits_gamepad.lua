local MAX_SCROLL_SPEED_MODIFIER = 5
local MIN_SCROLL_SPEED_MODIFIER = 1

local CreditsScreen_Gamepad = CreditsScreen_Base:Subclass()

function CreditsScreen_Gamepad:New(...)
    return CreditsScreen_Base.New(self, ...)
end

function CreditsScreen_Gamepad:Initialize(control)
    CreditsScreen_Base.Initialize(self, control)
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

    GAME_CREDITS_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    GAME_CREDITS_GAMEPAD_FRAGMENT:RegisterCallback("StateChange",   function(oldState, newState)
                                                            if newState == SCENE_FRAGMENT_SHOWING then
                                                                self.keybindState = KEYBIND_STRIP:PushKeybindGroupState()
                                                                KEYBIND_STRIP:RemoveDefaultExit(self.keybindState)
                                                                KEYBIND_STRIP:AddKeybindButtonGroup(self.creditDescriptor, self.keybindState)
                                                                ShowCredits()

                                                            elseif newState == SCENE_FRAGMENT_HIDDEN then
                                                                self:StopCredits()
                                                                KEYBIND_STRIP:RemoveKeybindButtonGroup(self.creditDescriptor, self.keybindState)
                                                                KEYBIND_STRIP:RestoreDefaultExit(self.keybindState)
                                                                KEYBIND_STRIP:PopKeybindGroupState()
                                                            end
                                                        end)

    -- NOTE: Templates must be unique due to how the object pools name controls as they're created.
    self:AddPool(GAME_CREDITS_ENTRY_TYPE_DEPARTMENT_HEADER, "ZO_GameCreditsDepartmentGamepad", function(textControl, text) return self:SetupTextControl(textControl, text) end)
    self:AddPool(GAME_CREDITS_ENTRY_TYPE_SECTION_HEADER, "ZO_GameCreditsSectionGamepad", function(textControl, text) return self:SetupTextControl(textControl, text) end)
    self:AddPool(GAME_CREDITS_ENTRY_TYPE_SECTION_TEXT, "ZO_GameCreditsNamesGamepad", function(textControl, text) return self:SetupTextControl(textControl, text) end)
    self:AddPool(GAME_CREDITS_ENTRY_TYPE_SECTION_TEXT_BLOCK, "ZO_GameCreditsTextBlockGamepad", function(textControl, text) return self:SetupTextControl(textControl, text) end)
    self:AddPool(GAME_CREDITS_ENTRY_TYPE_COMPANY_LOGO, "ZO_GameCreditsLogoGamepad", function(logoControl, texture, height) return self:SetupLogoControl(logoControl, texture, height) end)
    self:AddPool(GAME_CREDITS_ENTRY_TYPE_BACKGROUND_SWITCH, "ZO_GameCreditsBGSwitchGamepad", function(backgroundControl, texture) return self:SetupBackgroundSwitch(backgroundControl, texture) end)
    self:AddPool(GAME_CREDITS_ENTRY_TYPE_PADDING_SECTION, "ZO_GameCreditsPaddingGamepad", function(paddingControl, unused, height) return self:SetupPaddingSection(paddingControl, unused, height) end)

    EVENT_MANAGER:RegisterForEvent("GameCreditsGamepad", EVENT_GAME_CREDITS_READY, function() self:BeginCredits() end)
end

function CreditsScreen_Gamepad:Exit()
    SCENE_MANAGER:HideCurrentScene()
end

function CreditsScreen_Gamepad:IsPreferredScreen()
    return IsInGamepadPreferredMode()
end

function ZO_GameCredits_Gamepad_Initialize(control)
    GAME_CREDITS_GAMEPAD = CreditsScreen_Gamepad:New(control)
end