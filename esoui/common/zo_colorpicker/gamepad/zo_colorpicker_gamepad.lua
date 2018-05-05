ZO_ColorPicker_Gamepad = ZO_ColorPicker_Shared:Subclass()

function ZO_ColorPicker_Gamepad:New(...)
    return ZO_ColorPicker_Shared.New(self, ...)
end

function ZO_ColorPicker_Gamepad:Initialize(control)
    ZO_ColorPicker_Shared.Initialize(self, control, "GAMEPAD_COLOR_PICKER")

    SYSTEMS:RegisterGamepadObject("colorPicker", self)

    self:SetHasAlphaContentHeight(340)
    self:SetDoesntHaveAlphaContentHeight(282)

    --These are anchored here because they use pixel offsets instead of UI unit offsets to get exact 2-pixel borders
    local previewInitialTextureSizing = PIXEL_UNITS:Add(self.previewInitialTexture, PIXEL_SOURCE_PIXELS)
    previewInitialTextureSizing:AddAnchor(TOP, self.previewCurrentTexture, BOTTOM, 0, 2)

    local previewBorderBackdrop = self.previewControl:GetNamedChild("Border")
    local previewBorderBackdropSizing = PIXEL_UNITS:Add(previewBorderBackdrop, PIXEL_SOURCE_PIXELS)
    previewBorderBackdropSizing:AddAnchor(TOPLEFT, self.previewControl, TOPLEFT, -6, -6)
    previewBorderBackdropSizing:AddAnchor(BOTTOMRIGHT, self.previewControl, BOTTOMRIGHT, 6, 6)

    --Make it resize to fit after all of its children get anchored
    self.previewControl:SetResizeToFitDescendents(true)

    local valueSliderBackgroundTexture = self.valueSlider:GetNamedChild("Background")
    local valueSliderBackgroundTextureSizing = PIXEL_UNITS:Add(valueSliderBackgroundTexture, PIXEL_SOURCE_PIXELS)
    valueSliderBackgroundTextureSizing:AddAnchor(TOPLEFT, self.valueSlider, TOPLEFT, -6, -6)
    valueSliderBackgroundTextureSizing:AddAnchor(BOTTOMRIGHT, self.valueSlider, BOTTOMRIGHT, 6, 6)

    local alphaSliderBackgroundTexture = self.alphaSlider:GetNamedChild("Background")
    local alphaSliderBackgroundTextureSizing = PIXEL_UNITS:Add(alphaSliderBackgroundTexture, PIXEL_SOURCE_PIXELS)
    alphaSliderBackgroundTextureSizing:AddAnchor(TOPLEFT, self.alphaSlider, TOPLEFT, -6, -6)
    alphaSliderBackgroundTextureSizing:AddAnchor(BOTTOMRIGHT, self.alphaSlider, BOTTOMRIGHT, 6, 6)

    self.colorSelect:GetNamedChild("Binding"):SetTexture(ZO_GAMEPAD_LEFT_SLIDE_SCROLL_ICON)
    self.valueSlider:GetNamedChild("Binding"):SetTexture(ZO_GAMEPAD_RIGHT_SCROLL_ICON)

    local function OnDialogReleased()
        self:OnDialogReleased()
    end

    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_COLOR_PICKER",
    {
        customControl = control,
        title = 
        {
            text = SI_WINDOW_TITLE_COLOR_PICKER,
        },
        gamepadInfo = 
        {
            dialogType = GAMEPAD_DIALOGS.CUSTOM,
            allowShowOnNextScene = true,
            dontEndInWorldInteractions = true,
        },
        canQueue = true,
        blockDialogReleaseOnPress = true,
        blockDirectionalInput = true,
        setup = function() self:OnDialogShowing() end,
        finishedCallback = OnDialogReleased,
        noChoiceCallback = OnDialogReleased,

        buttons =
        {
            [1] =
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_DIALOG_ACCEPT,
                clickSound = SOUNDS.DIALOG_ACCEPT,
                alignment = KEYBIND_STRIP_ALIGN_CENTER,
                callback =  function() self:Confirm() end,
            },
            [2] =
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                clickSound = SOUNDS.DIALOG_DECLINE,
                alignment = KEYBIND_STRIP_ALIGN_CENTER,
                callback =  function() self:Cancel() end,
            },
        }
    })
end

function ZO_ColorPicker_Gamepad:SetColor(r, g, b, a)
    ZO_ColorPicker_Shared.SetColor(self, r, g, b, a)
    self.colorSelectNormalizedX, self.colorSelectNormalizedY = self.colorSelect:GetThumbNormalizedPosition()
end

function ZO_ColorPicker_Gamepad:OnDialogShowing()
    DIRECTIONAL_INPUT:Activate(self, self.control)
end

function ZO_ColorPicker_Gamepad:OnDialogReleased()
    DIRECTIONAL_INPUT:Deactivate(self)
end

do
    local COLOR_SELECT_SPEED = 1.4
    local VALUE_SPEED = 1
    function ZO_ColorPicker_Gamepad:UpdateDirectionalInput(deltaS)
        local leftX, leftY = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK, ZO_DI_DPAD)
        if not zo_floatsAreEqual(leftX, 0) or not zo_floatsAreEqual(leftY, 0) then
            self.colorSelectNormalizedX = self.colorSelectNormalizedX + leftX * deltaS * COLOR_SELECT_SPEED
            self.colorSelectNormalizedY = self.colorSelectNormalizedY - leftY * deltaS * COLOR_SELECT_SPEED
            local radiusSq = self.colorSelectNormalizedX * self.colorSelectNormalizedX + self.colorSelectNormalizedY * self.colorSelectNormalizedY
            if radiusSq > 1 then
                local radius = math.sqrt(radiusSq)
                self.colorSelectNormalizedX = self.colorSelectNormalizedX / radius
                self.colorSelectNormalizedY = self.colorSelectNormalizedY / radius
            end
            self.colorSelect:SetThumbNormalizedPosition(self.colorSelectNormalizedX, self.colorSelectNormalizedY)
        end

        local rightX, rightY = DIRECTIONAL_INPUT:GetXY(ZO_DI_RIGHT_STICK)
        if not zo_floatsAreEqual(rightY, 0) then
            self.valueSlider:SetValue(self.valueSlider:GetValue() - rightY * deltaS * VALUE_SPEED)
        end
    end
end


--[[ XML Handlers ]]--
function ZO_ColorPicker_Gamepad_TopLevel_OnInitialized(self)
	COLOR_PICKER_GAMEPAD = ZO_ColorPicker_Gamepad:New(self)
end