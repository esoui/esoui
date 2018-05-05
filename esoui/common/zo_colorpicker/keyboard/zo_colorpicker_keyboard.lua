ZO_ColorPicker_Keyboard = ZO_ColorPicker_Shared:Subclass()

function ZO_ColorPicker_Keyboard:New(...)
    return ZO_ColorPicker_Shared.New(self, ...)
end

function ZO_ColorPicker_Keyboard:Initialize(control)
    ZO_ColorPicker_Shared.Initialize(self, control, "COLOR_PICKER")

    SYSTEMS:RegisterKeyboardObject("colorPicker", self)

    self:SetHasAlphaContentHeight(225)
    self:SetDoesntHaveAlphaContentHeight(200)

    local function SetColorFromSpinner(r, g, b, a)
        if not self.isUpdatingColors then
            self:SetColor(r, g, b, a)
        end
    end

    local spinners = self.content:GetNamedChild("Spinners")
    self.redSpinner = ZO_Spinner:New(spinners:GetNamedChild("Red"), 0, 255)
    self.redSpinner:RegisterCallback("OnValueChanged", function(value)
        SetColorFromSpinner(value / 255, self.greenSpinner:GetValue() / 255, self.blueSpinner:GetValue() / 255, self.alphaSpinner:GetValue() / 255)
    end)
    self.redSpinner:SetNormalColor(ZO_ColorDef:New(1, .2, .2, 1))

    self.greenSpinner = ZO_Spinner:New(spinners:GetNamedChild("Green"), 0, 255)
    self.greenSpinner:RegisterCallback("OnValueChanged", function(value)
        SetColorFromSpinner(self.redSpinner:GetValue() / 255, value / 255, self.blueSpinner:GetValue() / 255, self.alphaSpinner:GetValue() / 255)
    end)
    self.greenSpinner:SetNormalColor(ZO_ColorDef:New(.2, 1, .2, 1))

    self.blueSpinner = ZO_Spinner:New(spinners:GetNamedChild("Blue"), 0, 255)
    self.blueSpinner:RegisterCallback("OnValueChanged", function(value)
        SetColorFromSpinner(self.redSpinner:GetValue() / 255, self.greenSpinner:GetValue() / 255, value / 255, self.alphaSpinner:GetValue() / 255)
    end)
    self.blueSpinner:SetNormalColor(ZO_ColorDef:New(.2, .2, 1, 1))

    self.alphaSpinner = ZO_Spinner:New(spinners:GetNamedChild("Alpha"), 0, 255)
    self.alphaSpinner:RegisterCallback("OnValueChanged", function(value)
        SetColorFromSpinner(self.redSpinner:GetValue() / 255, self.greenSpinner:GetValue() / 255, self.blueSpinner:GetValue() / 255, value / 255)
    end)

    ZO_Dialogs_RegisterCustomDialog("COLOR_PICKER",
    {
        customControl = control,
        title =
        {
            text = SI_WINDOW_TITLE_COLOR_PICKER,
        },
        buttons =
        {
            {
                control =   control:GetNamedChild("Accept"),
                text =      SI_DIALOG_ACCEPT,
                keybind =   "DIALOG_PRIMARY",
                callback =  function() self:Confirm() end,
            },  
            {
                control =   control:GetNamedChild("Cancel"),
                text =      SI_DIALOG_CANCEL,
                keybind =   "DIALOG_NEGATIVE",
                callback =  function() self:Cancel() end,
            },
        }
    })
end

function ZO_ColorPicker_Keyboard:UpdateColors(r, g, b, a)
    self.isUpdatingColors = true
    ZO_ColorPicker_Shared.UpdateColors(self, r, g, b, a)

    self.redSpinner:SetValue(r * 255)
    self.greenSpinner:SetValue(g * 255)
    self.blueSpinner:SetValue(b * 255)
    if self.hasAlpha then
        self.alphaSpinner:SetValue(a * 255)
    end

    self.isUpdatingColors = false
end

function ZO_ColorPicker_Keyboard:UpdateLayout()
    ZO_ColorPicker_Shared.UpdateLayout(self)
    self.alphaSpinner:GetControl():SetHidden(not self.hasAlpha)
end

--[[ XML Handlers ]]--
function ZO_ColorPicker_Keyboard_TopLevel_OnInitialized(self)
	COLOR_PICKER = ZO_ColorPicker_Keyboard:New(self)
end