local function SetupAccessibilityModeDialog(dialogControl)
    ZO_Dialogs_RegisterCustomDialog("ACCESSIBILITY_MODE_DIALOG",
    {
        customControl = dialogControl,
        mustChoose = true,
        title =
        {
            text = SI_ACCESSIBILITY_OPTIONS_ACCESSIBILITY_MODE,
        },
        setup = function() ACCESSIBILITY_MODE_PROMPT_FRAGMENT:Setup() end,
        buttons =
        {
            {
                control =   dialogControl:GetNamedChild("ContentContainerContinue"),
                text =      function()
                    local disabledText = GetString(SI_ACCESSIBILITY_MODE_PROMPT_CONTINUE_DISABLED)
                    disabledText = ZO_SELECTED_TEXT:Colorize(disabledText)
                    return zo_strformat(SI_ACCESSIBILITY_MODE_PROMPT_CONTINUE, disabledText)
                end,
                keybind =   "DIALOG_PRIMARY",
                callback =  function(dialog)
                                -- do nothing .... yet
                            end,
            },
        },
        finishedCallback = function(dialog)
            ZO_AccessibilityModePrompt_OnContinueClicked()
        end,
    })
end

ZO_AccessibilityModeFragment = ZO_SceneFragment:Subclass()

function ZO_AccessibilityModeFragment:New(control)
    local fragment = ZO_SceneFragment.New(self, control)
    fragment:Initialize(control)
    return fragment
end

function ZO_AccessibilityModeFragment:Initialize(control)
    self.dialog = control
    self.contentContainer = control:GetNamedChild("ContentContainer")
    self.enableCheckbox = self.contentContainer:GetNamedChild("EnableAccessibilityModeCheckbox")
    self.enableLabel = self.enableCheckbox:GetNamedChild("Label")
    self.continueButton = self.contentContainer:GetNamedChild("Continue")

    local function ToggleEnableAccessibilityMode()
        ZO_AccessibilityModePrompt_OnEnableToggled()
    end
    
    ZO_CheckButton_SetToggleFunction(self.enableCheckbox, ToggleEnableAccessibilityMode)

    self.accessibilityModeEnabled = false
end

function ZO_AccessibilityModeFragment:Show()
    if not self.dialogInitialized then
        self.dialogInitialized = true
    end

    ZO_Dialogs_ShowDialog("ACCESSIBILITY_MODE_DIALOG")
    ZO_SceneFragment.Show(self)
end

function ZO_AccessibilityModeFragment:Setup()    
    local pressToBindKeybindText = ZO_Keybindings_GetBindingStringFromAction("DIALOG_SECONDARY", KEYBIND_TEXT_OPTIONS_FULL_NAME, KEYBIND_TEXTURE_OPTIONS_EMBED_MARKUP)
    self.enableLabel:SetText(pressToBindKeybindText)
end

--[[ XML Handlers ]]--
function ZO_AccessibilityModePrompt_Initialize(control)
    SetupAccessibilityModeDialog(control)
    ACCESSIBILITY_MODE_PROMPT_FRAGMENT = ZO_AccessibilityModeFragment:New(control)
end

function ZO_AccessibilityModePrompt_OnToggleEnableButton()
    ZO_CheckButton_OnClicked(ACCESSIBILITY_MODE_PROMPT_FRAGMENT.enableCheckbox)
end

function ZO_AccessibilityModePrompt_OnEnableToggled()
    local enabledState = ZO_CheckButton_IsChecked(ACCESSIBILITY_MODE_PROMPT_FRAGMENT.enableCheckbox)
    local enabledText = enabledState and SI_ACCESSIBILITY_MODE_PROMPT_CONTINUE_ENABLED or SI_ACCESSIBILITY_MODE_PROMPT_CONTINUE_DISABLED
    enabledText = ZO_SELECTED_TEXT:Colorize(GetString(enabledText))
    local buttonText = zo_strformat(SI_ACCESSIBILITY_MODE_PROMPT_CONTINUE, enabledText)
    ACCESSIBILITY_MODE_PROMPT_FRAGMENT.continueButton:SetText(buttonText)
    ACCESSIBILITY_MODE_PROMPT_FRAGMENT.accessibilityModeEnabled = enabledState
end

function ZO_AccessibilityModePrompt_OnContinueClicked()
    if ACCESSIBILITY_MODE_PROMPT_FRAGMENT.accessibilityModeEnabled then
        SetSetting(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_ACCESSIBILITY_MODE, "true")
    else
        SetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_INPUT_PREFERRED_MODE, INPUT_PREFERRED_MODE_ALWAYS_KEYBOARD)
        SetCVar("PregameAccessibilityPromptEnabled", "false")
        PregameStateManager_SetState("ScreenAdjustIntro")
    end
end