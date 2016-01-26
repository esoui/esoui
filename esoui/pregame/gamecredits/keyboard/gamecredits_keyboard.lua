local CreditsScreen_Keyboard = CreditsScreen_Base:Subclass()

function CreditsScreen_Keyboard:New(...)
    return CreditsScreen_Base.New(self, ...)
end

function CreditsScreen_Keyboard:Initialize(control)
    CreditsScreen_Base.Initialize(self, control)
    
    GAME_CREDITS_FRAGMENT = ZO_FadeSceneFragment:New(control)
    GAME_CREDITS_FRAGMENT:RegisterCallback("StateChange",   function(oldState, newState)
                                                            if(newState == SCENE_FRAGMENT_SHOWING) then
                                                                ShowCredits()

                                                            elseif(newState == SCENE_FRAGMENT_HIDDEN) then
                                                                self:StopCredits()
                                                            end
                                                        end)

    -- NOTE: Templates must be unique due to how the object pools name controls as they're created.
    self:AddPool(GAME_CREDITS_ENTRY_TYPE_DEPARTMENT_HEADER, "ZO_GameCreditsDepartment", function(textControl, text) return self:SetupTextControl(textControl, text) end)
    self:AddPool(GAME_CREDITS_ENTRY_TYPE_SECTION_HEADER, "ZO_GameCreditsSection", function(textControl, text) return self:SetupTextControl(textControl, text) end)
    self:AddPool(GAME_CREDITS_ENTRY_TYPE_SECTION_TEXT, "ZO_GameCreditsNames", function(textControl, text) return self:SetupTextControl(textControl, text) end)
    self:AddPool(GAME_CREDITS_ENTRY_TYPE_SECTION_TEXT_BLOCK, "ZO_GameCreditsTextBlock", function(textControl, text) return self:SetupTextControl(textControl, text) end)
    self:AddPool(GAME_CREDITS_ENTRY_TYPE_COMPANY_LOGO, "ZO_GameCreditsLogo", function(logoControl, texture, height) return self:SetupLogoControl(logoControl, texture, height) end)
    self:AddPool(GAME_CREDITS_ENTRY_TYPE_BACKGROUND_SWITCH, "ZO_GameCreditsBGSwitch", function(backgroundControl, texture) return self:SetupBackgroundSwitch(backgroundControl, texture) end)
    self:AddPool(GAME_CREDITS_ENTRY_TYPE_PADDING_SECTION, "ZO_GameCreditsPadding", function(paddingControl, unused, height) return self:SetupPaddingSection(paddingControl, unused, height) end)

    EVENT_MANAGER:RegisterForEvent("GameCreditsKeyboard", EVENT_GAME_CREDITS_READY, function() self:BeginCredits() end)

end

function CreditsScreen_Keyboard:Exit()
    SCENE_MANAGER:RemoveFragment(GAME_CREDITS_FRAGMENT)
    ZO_GameMenu_PreGame_Reset()
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
    if(upInside) then
        GAME_CREDITS_KEYBOARD:Exit()
    end
end