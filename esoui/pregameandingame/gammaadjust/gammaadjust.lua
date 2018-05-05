local currentGamma = GetCVar("GAMMA_ADJUSTMENT")
local DEFAULT_INITIAL_GAMMA = 100 -- this should match the gamma adjustment setting in the RenderSettings

local function GammaDialogInitialize(dialogControl)
    ZO_Dialogs_RegisterCustomDialog("ADJUST_GAMMA_DIALOG",
    {
        customControl = dialogControl,
        mustChoose = true,
        title =
        {
            text = "",
        },
        buttons =
        {
            [1] =
            {
                control = GetControl(dialogControl, "KeyContainerConfirmGamma"),
                text = SI_GAMMA_CONFIRM,
                noReleaseOnClick = true, -- Don't release because the scene needs to fade out, will release later
                callback =  function(dialog)
                                SetCVar("GAMMA_ADJUSTMENT", tostring(currentGamma))
                                SCENE_MANAGER:Hide("gammaAdjust")
                                ZO_SavePlayerConsoleProfile()
                            end,
            },
            [2] =
            {
                control = GetControl(dialogControl, "KeyContainerDeclineGamma"),
                text = SI_GAMMA_DECLINE,
                noReleaseOnClick = true, -- Don't release because the scene needs to fade out, will release later
                callback =  function(dialog)
                                SCENE_MANAGER:Hide("gammaAdjust")
                            end,
                visible = function() return not ZO_GammaAdjust_NeedsFirstSetup() end,
            },
        }
    })
end

-- Gamma Scene and Fragment management
do
    local GAMMA_KEYBOARD_STYLE =
    {
        mainFont = "ZoFontWinH3",
        subFont = "ZoFontConversationOption",
        confirmTemplate = "ZO_DialogButton",
        declineTemplate = "ZO_DialogButton",
        keybindTextFontColor = ZO_NORMAL_TEXT,
    }

    local GAMMA_GAMEPAD_STYLE =
    {
        mainFont = "ZoFontGamepadBold34",
        subFont = "ZoFontGamepadBold22",
        confirmTemplate = "ZO_DialogButton_Gamepad",
        declineTemplate = "ZO_DialogButton_Gamepad",
        keybindTextFontColor = ZO_SELECTED_TEXT,
    }

    local ZO_GammaAdjustFragment = ZO_FadeSceneFragment:Subclass()

    function ZO_GammaAdjustFragment:New(control)
        local fragment = ZO_FadeSceneFragment.New(self, control, 1500)
        fragment.dialog = control
        fragment.mainText = control:GetNamedChild("MainText")
        fragment.subText = control:GetNamedChild("SubText")
        fragment.keyContainer = control:GetNamedChild("KeyContainer")
        fragment.confirmGamma = fragment.keyContainer:GetNamedChild("ConfirmGamma")
        fragment.declineGamma = fragment.keyContainer:GetNamedChild("DeclineGamma")

        local oldStop = fragment.animationReverseOnStop
        fragment.animationReverseOnStop =   function()
                                                --Have to release the dialog before the stop handler hides it or it won't decrease the number of top levels
                                                ZO_Dialogs_ReleaseDialog("ADJUST_GAMMA_DIALOG")
                                                oldStop()
                                            end
        ZO_PlatformStyle:New(function(style) fragment:ApplyPlatformStyle(style) end, GAMMA_KEYBOARD_STYLE, GAMMA_GAMEPAD_STYLE)
        return fragment
    end

    function ZO_GammaAdjustFragment:Show()
        currentGamma = GetCVar("GAMMA_ADJUSTMENT")

        -- Tweak custom dialog controls
        if self.slider.Activate then
            self.slider:Activate()
        end

        if ZO_GammaAdjust_NeedsFirstSetup() then
            self.slider:SetValue(DEFAULT_INITIAL_GAMMA)
        else
            self.slider:SetValue(currentGamma)
        end

        if not self.dialogInitialized then
            GammaDialogInitialize(self.control)
            self.dialogInitialized = true
        end

        local dialog = self.dialog

        dialog:GetNamedChild("Divider"):SetHidden(true)
        dialog:GetNamedChild("BG"):SetHidden(true)
        dialog:GetNamedChild("ModalUnderlay"):SetColor(0, 0, 0, 1)

        ZO_Dialogs_ShowDialog("ADJUST_GAMMA_DIALOG")

        -- Call base class for animations after everything has been tweaked
        ZO_FadeSceneFragment.Show(self)
    end

    function ZO_GammaAdjustFragment:IncrementSliderValue(delta)
        self.slider:SetValue(self.slider:GetValue() + delta)
    end

    function ZO_GammaAdjustFragment:OnHidden()
        ZO_FadeSceneFragment.OnHidden(self)

        if(self.slider.Deactivate) then
            self.slider:Deactivate()
        end
    end

    function CreateGammaSceneFragment(control)
        GAMMA_SCENE_FRAGMENT = ZO_GammaAdjustFragment:New(control)
    end

    function ZO_GammaAdjustFragment:ApplyPlatformStyle(style)
        self.mainText:SetFont(style.mainFont)
        self.subText:SetFont(style.subFont)
        ApplyTemplateToControl(self.confirmGamma, style.confirmTemplate)
        ApplyTemplateToControl(self.declineGamma, style.declineTemplate)
        ZO_SelectableLabel_SetNormalColor(self.confirmGamma:GetNamedChild("NameLabel"), style.keybindTextFontColor)
        ZO_SelectableLabel_SetNormalColor(self.declineGamma:GetNamedChild("NameLabel"), style.keybindTextFontColor)

        self:UpdateVisibility()
    end

    function ZO_GammaAdjustFragment:UpdateVisibility()
        local isGamepad = IsInGamepadPreferredMode()
        if self.gamepadSlider then
            self.gamepadSlider:SetHidden(not isGamepad)
        end

        if self.keyboardSlider then
            self.keyboardSlider:SetHidden(isGamepad)
            self.rightArrow:SetHidden(isGamepad)
            self.leftArrow:SetHidden(isGamepad)
        end
        self.slider = isGamepad and self.gamepadSlider or self.keyboardSlider
    end
end

do
    local function ZO_GammaAdjustSlider_OnInitialized(slider)
        slider:SetMinMax(75, 150)
        slider:SetValue(75)
        ZO_GammaAdjust_ColorTexturesWithGamma(75)
        slider:SetHandler("OnValueChanged", ZO_GammaAdjust_SetGamma)
        GAMMA_SCENE_FRAGMENT:UpdateVisibility()
    end

    function ZO_GammaAdjust_Initialize(self)
        if not self.initialized then
            self.initialized = true
            CreateGammaSceneFragment(self)

            local gamepadSlider = self:GetNamedChild("GamepadSlider")
            GAMMA_SCENE_FRAGMENT.gamepadSlider = gamepadSlider
            ZO_GammaAdjustSlider_OnInitialized(gamepadSlider)

            local keyboardSlider = self:GetNamedChild("Slider")
            GAMMA_SCENE_FRAGMENT.keyboardSlider = keyboardSlider
            GAMMA_SCENE_FRAGMENT.rightArrow = keyboardSlider:GetNamedChild("Increment")
            GAMMA_SCENE_FRAGMENT.leftArrow = keyboardSlider:GetNamedChild("Decrement")
            ZO_GammaAdjustSlider_OnInitialized(keyboardSlider)
        end
    end
end

local function GammaToLinear(gamma)
    if(gamma <= 0.04045) then
        return (gamma / 12.92)
    else
        return zo_pow(zo_abs(gamma + 0.055) / 1.055, 2.4)
    end
end

local function LinearToGamma(linear)
    if(linear <= 0.0031308) then
        return (linear * 12.92)
    else
        return (1.055 * zo_pow(zo_abs(linear), 1 / 2.4) - 0.055)
    end
end

do
    local imageData =
    {
        { "ZO_GammaAdjustReferenceImage1", 2 / 255 },
        { "ZO_GammaAdjustReferenceImage2", 7 / 255 },
        { "ZO_GammaAdjustReferenceImage3", 20 / 255 },
    }

    function ZO_GammaAdjust_SetGamma(slider, value)
        currentGamma = value
        ZO_GammaAdjust_ColorTexturesWithGamma(currentGamma)
    end

    function ZO_GammaAdjust_ColorTexturesWithGamma(gamma)
        for index, setupData in ipairs(imageData) do
            local image = GetControl(setupData[1])
            local linearAlpha = GammaToLinear(setupData[2])
            local correctedLinear = zo_pow(linearAlpha, 100 / gamma)
            local gammaAlpha = LinearToGamma(correctedLinear)
            image:SetColor(1, 1, 1, gammaAlpha)
        end
    end
end

function ZO_GammaAdjust_ChangeGamma(delta)
    GAMMA_SCENE_FRAGMENT:IncrementSliderValue(delta)
end

function ZO_GammaAdjust_NeedsFirstSetup()
    return GetCVar("PregameGammaCheckEnabled") == "1"
end