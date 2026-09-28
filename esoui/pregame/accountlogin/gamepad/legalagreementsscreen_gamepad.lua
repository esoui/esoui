local MIN_SCROLL_VALUE = 0

---------------------------------------
-- The main class.
local ZO_LegalAgreementsScreen_Gamepad = ZO_InitializingObject:Subclass()

function ZO_LegalAgreementsScreen_Gamepad:Initialize(control)
    self.control = control
    self.scrollAvailableAtMS = nil
    self.docData = nil
    self.docProvider = REMOTE_LEGAL_DOCS_PROVIDER

    local legalAgreementsScreenFragment = ZO_FadeSceneFragment:New(control)
    LEGAL_AGREEMENTS_GAMEPAD_SCENE = ZO_Scene:New("LegalAgreementsScreen_Gamepad", SCENE_MANAGER)
    LEGAL_AGREEMENTS_GAMEPAD_SCENE:AddFragment(legalAgreementsScreenFragment)

    local function StateChanged(oldState, newState)
        if newState == SCENE_SHOWING then
            DIRECTIONAL_INPUT:Activate(self, self.control)
            self:PerformDeferredInitialize()
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self:UpdateCurrentText()
        elseif newState == SCENE_HIDING then
            DIRECTIONAL_INPUT:Deactivate(self)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end

    LEGAL_AGREEMENTS_GAMEPAD_SCENE:RegisterCallback("StateChange", StateChanged)
end

function ZO_LegalAgreementsScreen_Gamepad:PerformDeferredInitialize()
    if self.initialized then return end
    self.initialized = true

    local EULAContainer = self.control:GetNamedChild("EULAContainer")

    local container = EULAContainer:GetNamedChild("Container")

    self:InitKeybindingDescriptor()

    self.scroll = container:GetNamedChild("Scroll")

    self.animation, self.timeline = ZO_CreateScrollAnimation(self)

    self.title = EULAContainer:GetNamedChild("TitleContainer"):GetNamedChild("Title")
    self.divider = EULAContainer:GetNamedChild("Divider")
    self.date = EULAContainer:GetNamedChild("Date")
    self.text = self.scroll:GetNamedChild("Child"):GetNamedChild("Text")

    self.scrollValue = MIN_SCROLL_VALUE
    self.useFadeGradient = true

    ZO_ScrollAnimation_MoveWindow(self, self.scrollValue)
    ZO_UpdateScrollFade(self.useFadeGradient, self.scroll, ZO_SCROLL_DIRECTION_VERTICAL)

    --[[
    This is a hack.  Without this, the mask on the EULA isn't correct until the player first scrolls it.
    This seems to be something to do with the fact that there are no scroll extents in the EULA at this point (the text is still downloading?)
    The slider animation has to be modified directly to fix the bug, and only this scroll function seems to have the right low-level access to the scroll system to do what is needed.
    ]]
    ZO_SetSliderValueAnimated(self, 0)
end

function ZO_LegalAgreementsScreen_Gamepad:UpdateDirectionalInput()
    if self.scrollAvailableAtMS and self.scrollAvailableAtMS > GetGameTimeMilliseconds() then
        self.scrollValue = MIN_SCROLL_VALUE
        ZO_ScrollAnimation_OnExtentsChanged(self)
    else
        self.scrollAvailableAtMS = nil
        local inputY = DIRECTIONAL_INPUT:GetY(ZO_DI_LEFT_STICK, ZO_DI_DPAD)
        if inputY ~= 0 then
            ZO_ScrollRelative(self, -inputY * 100)
        end
    end
end

function ZO_LegalAgreementsScreen_Gamepad:UpdateCurrentText()
    -- disable scrolling while transitioning to next doc so that the doc isn't scrolled all the way to the end when it's not displayed
    self.scrollAvailableAtMS = GetGameTimeMilliseconds() + 100
    self.scrollValue = MIN_SCROLL_VALUE

    local currentData = self.docData
    if currentData then
        self.title:SetText(currentData.name)
        self.text:SetText(currentData.text)
    end
    ZO_ScrollAnimation_OnExtentsChanged(self)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_LegalAgreementsScreen_Gamepad:InitKeybindingDescriptor()
    self.keybindStripDescriptor = 
    {
        -- Decline
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = function()
                local currentData = self.docData
                if currentData ~= nil and currentData.negativeButtonPrompt ~= nil then
                    return currentData.negativeButtonPrompt
                end
                -- Should never occur.
                return ""
            end,
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                PlaySound(SOUNDS.NEGATIVE_CLICK)
                self.docData = self.docProvider:PreviousLegalDoc()
                if not self.docData then
                    PREGAME_INITIAL_SCREEN_GAMEPAD:ShowError(GetString(SI_LEGAL_DECLINE_HEADER), GetString(SI_LEGAL_DECLINE_PROMPT))
                else
                    self:UpdateCurrentText()
                end
            end,
        },

        -- Accept
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = function()
                local currentData = self.docData
                if currentData ~= nil and currentData.positiveButtonPrompt ~= nil and currentData.positiveButtonPrompt ~= "" then
                    return currentData.positiveButtonPrompt
                end
                -- Should never occur.
                return ""
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                PlaySound(SOUNDS.POSITIVE_CLICK)
                self.docData.acceptFunction()

                self.docData = self.docProvider:NextLegalDoc()
                if self.docData then
                    self:UpdateCurrentText()
                else
                    self.docProvider:OnDocsFinished()
                end
            end,
        },
    }
end

function ZO_LegalAgreementsScreen_Gamepad:ShouldShowEULA()
    return self.docProvider:ShouldShowEULA()
end

function ZO_LegalAgreementsScreen_Gamepad:ShowEULA()
    self.docData = self.docProvider:NextLegalDoc()
    SCENE_MANAGER:Show("LegalAgreementsScreen_Gamepad")
end

function ZO_LegalAgreementsScreen_Gamepad:ShowFetchedDocs()
    self.docData = self.docProvider:NextLegalDoc()
    SCENE_MANAGER:Show("LegalAgreementsScreen_Gamepad")
end

---------------------------------------
-- Global functions.

function ZO_LegalAgreementsScreen_Gamepad_Initialize(control)
    LEGAL_AGREEMENT_SCREEN_GAMEPAD = ZO_LegalAgreementsScreen_Gamepad:New(control)
end
