-- Configuration data.
local function GetEULA()
    local eulaText, agreeText, disagreeText = GetEULADetails(ET_PREGAME_EULA)

    -- TODO: Generate all of this list from some outside data source.
    --  Possibly, this entire function should just be replaced by some API that can request the information?
    return {
        {
            name = GetString(SI_WINDOW_TITLE_EULA), 
            text = eulaText,
            positiveButtonPrompt = agreeText,
            negativeButtonPrompt = disagreeText,
            acceptFunction = function() AgreeToEULA() end,
        },
    }
end

local function GetFetchedDocs()
    local data = {}
    local i = 0
    local numDocs = GetNumLegalDocs()
    for i = 1, numDocs do
        title = GetLegalDocTitle(i)
        content = GetLegalDocContent(i)
        data[#data+1] = {
            name = title,
            text = content,
            positiveButtonPrompt = GetString(SI_CONSOLE_LEGAL_BUTTON_AGREE),
            negativeButtonPrompt = GetString(SI_CONSOLE_LEGAL_BUTTON_DISAGREE),
            acceptFunction = function() end,
        }
    end

    return data
end

local MIN_SCROLL_VALUE = 0
local MAX_SCROLL_VALUE = 100

---------------------------------------
-- The main class.
local LegalAgreementScreen_Console = ZO_Object:Subclass()

function LegalAgreementScreen_Console:New(...)
    local legalAgreements = ZO_Object.New(self)
    legalAgreements:Initialize(...)
    return legalAgreements
end

function LegalAgreementScreen_Console:Initialize(control)
    self.control = control
    self.showEULA = false
    self.showFetchedDocs = false
    self.scrollAvailableAtMS = nil

    local legalAgreementsScreenFragment = ZO_FadeSceneFragment:New(control)
    LEGAL_AGREEMENTS_GAMEPAD_SCENE = ZO_Scene:New("LegalAgreementsScreen_Gamepad", SCENE_MANAGER)
    LEGAL_AGREEMENTS_GAMEPAD_SCENE:AddFragment(legalAgreementsScreenFragment)

    local function StateChanged(oldState, newState)
        if newState == SCENE_SHOWING then
            DIRECTIONAL_INPUT:Activate(self, self.control)
            self:PerformDeferredInitialize()
            self:UpdateCurrentText()
            KEYBIND_STRIP:RemoveDefaultExit()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

        elseif newState == SCENE_HIDING then
            DIRECTIONAL_INPUT:Deactivate(self)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            KEYBIND_STRIP:RestoreDefaultExit()
        end
    end

    LEGAL_AGREEMENTS_GAMEPAD_SCENE:RegisterCallback("StateChange", StateChanged)
end

function LegalAgreementScreen_Console:PerformDeferredInitialize()
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

    self.activeIndex = 1
end

function LegalAgreementScreen_Console:UpdateDirectionalInput()
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

function LegalAgreementScreen_Console:UpdateCurrentText()
    -- disable scrolling while transitioning to next doc so that the doc isn't scrolled all the way to the end when it's not displayed
    self.scrollAvailableAtMS = GetGameTimeMilliseconds() + 100

    local currentData = self.data[self.activeIndex]
    
    local currentTitle = currentData and currentData.name
    local currentText = currentData and currentData.text

    self.scrollValue = MIN_SCROLL_VALUE

    self.title:SetText(currentTitle)
    self.text:SetText(currentText)

    ZO_ScrollAnimation_OnExtentsChanged(self)

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function LegalAgreementScreen_Console:InitKeybindingDescriptor()
    self.keybindStripDescriptor = 
    {
        -- Decline
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = function()
                local currentData = self.data[self.activeIndex]
                if (currentData ~= nil) and (currentData.negativeButtonPrompt ~= nil) then
                    return currentData.negativeButtonPrompt
                end
                -- Should never occur.
                return ""
            end,
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                PlaySound(SOUNDS.NEGATIVE_CLICK)
                if self.activeIndex == 1 then
                    PREGAME_INITIAL_SCREEN_CONSOLE:ShowError(GetString(SI_CONSOLE_LEGAL_DECLINE_HEADER), GetString(SI_CONSOLE_LEGAL_DECLINE_PROMPT))
                else
                    self.activeIndex = self.activeIndex - 1
                    self:UpdateCurrentText()
                end
            end,
        },

        -- Accept
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = function()
                local currentData = self.data[self.activeIndex]
                if (currentData ~= nil) and (currentData.positiveButtonPrompt ~= nil) and (currentData.positiveButtonPrompt ~= "") then
                    return currentData.positiveButtonPrompt
                end
                -- Should never occur.
                return ""
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                PlaySound(SOUNDS.POSITIVE_CLICK)
                local currentData = self.data[self.activeIndex]
                currentData.acceptFunction()

                if self.activeIndex == #self.data then
                    if self.showFetchedDocs then
                        -- Services legal docs require an extra confirmation step before we consider them to be accepted
                        ZO_Dialogs_ShowGamepadDialog("LEGAL_AGREEMENT_UPDATED_ACKNOWLEDGE")
                    else
                        PregameStateManager_AdvanceState()
                    end
                else
                    self.activeIndex = self.activeIndex + 1
                    self:UpdateCurrentText()
                end
            end,
        },
    }
end

function LegalAgreementScreen_Console:ShowEULA()
    self.showEULA = true
    self.showFetchedDocs= false
    self.activeIndex = 1
    self.data = GetEULA()
end

function LegalAgreementScreen_Console:ShowFetchedDocs()
    self.showEULA = false
    self.showFetchedDocs= true
    self.activeIndex = 1
    self.data = GetFetchedDocs()
end

---------------------------------------
-- Global functions.

function LegalAgreementsScreen_Gamepad_Initialize(control)
    LEGAL_AGREEMENT_SCREEN_CONSOLE = LegalAgreementScreen_Console:New(control)
end


---------------------------------------
-- Register for events
EVENT_MANAGER:RegisterForEvent("LegalAgreements", EVENT_FETCHED_LEGAL_DOCS, function() PregameStateManager_SetState("LegalAgreements") end)