ZO_TamrielTomesIntroScreen_Gamepad = ZO_TamrielTomesIntroScreen_Shared:Subclass()

function ZO_TamrielTomesIntroScreen_Gamepad:Initialize(control)
    TAMRIEL_TOMES_INTRO_SCENE_GAMEPAD = ZO_Scene:New("TamrielTomesIntroSceneGamepad", SCENE_MANAGER)

    SYSTEMS:RegisterGamepadRootScene("tamrielTomesIntro", TAMRIEL_TOMES_INTRO_SCENE_GAMEPAD)

    local HIGHLIGHT_TEMPLATE = "ZO_TamrielTomesIntroHighlight_Gamepad"
    ZO_TamrielTomesIntroScreen_Shared.Initialize(self, control, TAMRIEL_TOMES_INTRO_SCENE_GAMEPAD, HIGHLIGHT_TEMPLATE)
end

function ZO_TamrielTomesIntroScreen_Gamepad:OnDeferredInitialize()
    ZO_TamrielTomesIntroScreen_Shared.OnDeferredInitialize(self)

    self:InitializeKeybindStripDescriptors()
    self:InitializeNarrationInfo()
end

function ZO_TamrielTomesIntroScreen_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            keybind = "UI_SHORTCUT_PRIMARY",
            sound = SOUNDS.NONE,
            name = GetString(SI_TAMRIEL_TOMES_INTRO_CONTINUE_ACTION),
            callback = function()
                self:AdvanceToTome()
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_TamrielTomesIntroScreen_Gamepad:InitializeNarrationInfo()
    local previewNarrationData =
    {
        canNarrate = function()
            return self:IsShowing()
        end,
        selectedNarrationFunction = function()
            local narrations = {}

            local tomeData = self.tomeData

            local displayName = tomeData:GetDisplayName()
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(displayName))

            local numHighlights = tomeData:GetNumHighlights()
            for highlightIndex = 1, numHighlights do
                local title, text = tomeData:GetHighlightInfo(highlightIndex)
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(title))
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(text))
            end

            return narrations
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("TamrielTomesIntroSceneGamepad", previewNarrationData)
end

function ZO_TamrielTomesIntroScreen_Gamepad:OnShowing()
    ZO_TamrielTomesIntroScreen_Shared.OnShowing(self)

    TAMRIEL_TOMES_SCENE_GROUP_GAMEPAD:SetActiveScene("TamrielTomesIntroSceneGamepad")
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

    SCREEN_NARRATION_MANAGER:QueueCustomEntry("TamrielTomesIntroSceneGamepad")
end

function ZO_TamrielTomesIntroScreen_Gamepad:OnHiding()
    ZO_TamrielTomesIntroScreen_Shared.OnHiding(self)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TamrielTomesIntroScreen_Gamepad:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TamrielTomesIntroScreen_Gamepad.OnControlInitialized(control)
    TAMRIEL_TOMES_INTRO_SCREEN_GAMEPAD = ZO_TamrielTomesIntroScreen_Gamepad:New(control)
end

function ZO_TamrielTomesIntroScreen_Gamepad:AdvanceToTome()
    SCENE_MANAGER:SwapCurrentScene("TamrielTomesSceneGamepad")

    -- Play the page fip sound manually as the ZO_PageNavigation control
    -- is not technically changing pages in this context.
    PlaySound(SOUNDS.TAMRIEL_TOMES_PAGE_FLIPPED)
    PlaySound(SOUNDS.TAMRIEL_TOMES_PAGE_ZERO_CONTINUE_TO_TOME)
end