local ZO_GamepadHelpLegal = ZO_InitializingObject:Subclass()

local URL_LABEL_Y_OFFSET = 55

function ZO_GamepadHelpLegal:Initialize(control)
    self.control = control
    self.scene = ZO_Scene:New("helpLegalDocsGamepad", SCENE_MANAGER)
    self.scene:AddFragment(ZO_FadeSceneFragment:New(control))
    self.headerData = {
        titleText = GetString(SI_GAMEPAD_HELP_LEGAL_HEADER),
        messageText = GetString(SI_GAMEPAD_HELP_LEGAL_TEXT),
    }

    self:SetupText()
    self:InitializeKeybindDescriptors()

    self.scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindDescriptors)
            SCREEN_NARRATION_MANAGER:QueueCustomEntry("helpLegal")
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindDescriptors)
        end
    end)

    local narrationInfo =
    {
        canNarrate = function()
            return self.scene:IsShowing()
        end,
        selectedNarrationFunction = function()
            local narrations = {}
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_HELP_LEGAL_HEADER)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_HELP_LEGAL_TEXT)))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_TOS_WEBSITE)))
            return narrations
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("helpLegal", narrationInfo)
end

function ZO_GamepadHelpLegal:InitializeKeybindDescriptors()
    self.keybindDescriptors = {}
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindDescriptors, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_GamepadHelpLegal:SetupText()
    local container = self.control:GetNamedChild("Mask"):GetNamedChild("Container")
    local header = container:GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    local urlLabel = CreateControlFromVirtual("LegalURL", container, "ZO_GamepadHelpLegalURL")
    urlLabel:SetAnchor(TOPLEFT, header, BOTTOMLEFT, 0, URL_LABEL_Y_OFFSET)
    urlLabel:SetAnchor(TOPRIGHT, header, BOTTOMRIGHT, 0, URL_LABEL_Y_OFFSET)

    ZO_GamepadGenericHeader_Initialize(header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)
    ZO_GamepadGenericHeader_Refresh(header, self.headerData)
end

function ZO_GamepadHelpLegal_OnInitialize(control)
    HELP_LEGAL_GAMEPAD = ZO_GamepadHelpLegal:New(control)
end