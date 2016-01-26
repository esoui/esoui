-----------------------
-- Guild Bank Error Screen
-----------------------

local GAMEPAD_GUILD_BANK_ERROR_SCENE_NAME = "gamepad_guild_bank_error"

local GuildBankError_Gamepad = ZO_Object:Subclass()

function GuildBankError_Gamepad:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function GuildBankError_Gamepad:Initialize(control)
    self.control = control

    GAMEPAD_GUILD_BANK_ERROR_SCENE = ZO_InteractScene:New(GAMEPAD_GUILD_BANK_ERROR_SCENE_NAME, SCENE_MANAGER, GUILD_BANKING_INTERACTION)

    GAMEPAD_GUILD_BANK_ERROR_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialization()
            self:SetupMessage()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)
end

function GuildBankError_Gamepad:PerformDeferredInitialization()
    if self.isInitialized then return end

    self.messageControl = self.control:GetNamedChild("Container"):GetNamedChild("Message")

    self:InitializeKeybindStripDescriptors()

    self.isInitialized = true
end

function GuildBankError_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = {}
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function GuildBankError_Gamepad:SetupMessage()
    if self.initData then
        self.messageControl:SetText(GetString("SI_GUILDBANKRESULT", self.initData.error))
    end
end

function GuildBankError_Gamepad:Show(error)
    if IsInGamepadPreferredMode() then
        self.initData = self.initData or {}

        self.initData.error = error

        SCENE_MANAGER:Push(GAMEPAD_GUILD_BANK_ERROR_SCENE_NAME)
    end
end

function ZO_GamepadGuildBankError_Initialize(control)
    GAMEPAD_GUILD_BANK_ERROR = GuildBankError_Gamepad:New(control)
end