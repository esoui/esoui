
local ChapterUpgrade_Gamepad = ZO_ChapterUpgrade_Shared:Subclass()

function ChapterUpgrade_Gamepad:New(...)
    return ZO_ChapterUpgrade_Shared.New(self, ...)
end

function ChapterUpgrade_Gamepad:Initialize(control)
    ZO_ChapterUpgrade_Shared.Initialize(self, control, "chapterUpgradeGamepad")

    self.focus = ZO_GamepadFocus:New(control, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    
    local enterCodeButton = control:GetNamedChild("EnterCodeButton")
    local enterCodeButtonFocusData = 
    {
        highlight = enterCodeButton:GetNamedChild("Highlight"),
        control = enterCodeButton,
        callback = function() self:EnterCodeButtonClicked() end,
    }

    local upgradeButton = control:GetNamedChild("UpgradeButton")
    local upgradeButtonFocusData = 
    {
        highlight = upgradeButton:GetNamedChild("Highlight"),
        control = upgradeButton,
        callback = function() self:UpgradeButtonClicked() end,
    }
    
    self.focus:AddEntry(enterCodeButtonFocusData)
    self.focus:AddEntry(upgradeButtonFocusData)

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            callback = function()
                local selection = self.focus:GetFocusItem()
                if selection and selection.callback then
                    selection.callback()
                end
            end,
        },

        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_CHAPTER_UPGRADE_CONTINUE),
            callback = function()
                self:ShowContinueDialog()
            end,
        },
    }
end

function ChapterUpgrade_Gamepad:UpgradeButtonClicked()
    local IS_STANDARD_EDITION = false
    ZO_ShowChapterUpgradePlatformDialog(IS_STANDARD_EDITION, CHAPTER_UPGRADE_SOURCE_PREGAME)
end

function ChapterUpgrade_Gamepad:EnterCodeButtonClicked()
    ZO_Dialogs_ShowGamepadDialog("SHOW_REDEEM_CODE_CONSOLE")
end

function ChapterUpgrade_Gamepad:OnShowing()
    ZO_ChapterUpgrade_Shared.OnShowing(self)
    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self.focus:Activate()
end

function ChapterUpgrade_Gamepad:OnHiding()
    ZO_ChapterUpgrade_Shared.OnHiding(self)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RestoreDefaultExit()
    ZO_SavePlayerConsoleProfile()
    self.focus:Deactivate()
end

function ZO_ChapterUpgrade_Gamepad_OnInitialized(control)
    CHAPTER_UPGRADE_SCREEN_GAMEPAD = ChapterUpgrade_Gamepad:New(control)
end