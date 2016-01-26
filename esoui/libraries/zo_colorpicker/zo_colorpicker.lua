--[[ Provides a simple color picker dialog
	
	Usage:
	COLOR_PICKER:Show(colorSelectedCallback[, r][, g][, b][, a])

	*colorSelectedCallback - Called when a value is picked, signature: colorSelectedCallback(newR, newG, newB, newA)
	*r - Optional starting red value (default: 1)
	*g - Optional starting green value (default: 1)
	*b - Optional starting blue value (default: 1)
	*a - Optional starting alpha value, if no alpha value is provided the alpha slider is not shown, if one is provided the alpha slider is shown
]]--

local FULL_WIDTH = 390
local FULL_HEIGHT = 225

local SMALL_WIDTH = 390
local SMALL_HEIGHT = 200

ZO_ColorPicker = ZO_Object:Subclass()

function ZO_ColorPicker:New(control)
	local picker = ZO_Object.New(self)
	picker:Initialize(control)
	return picker
end

function ZO_ColorPicker:Initialize(control)
	self.control = control
    local content = self.control:GetNamedChild("Content")
    self.content = content
	self.colorSelect = content:GetNamedChild("ColorSelect")
	self.colorSelectThumb = self.colorSelect:GetNamedChild("Thumb")

	self.colorSelect:SetColorWheelThumbTextureControl(self.colorSelectThumb)

	self.valueSlider = content:GetNamedChild("Value")
	self.valueSlider:GetThumbTextureControl():SetDrawLayer(3)
	self.valueTexture = self.valueSlider:GetNamedChild("Texture")

	self.alphaLabel = content:GetNamedChild("AlphaLabel")
	self.alphaSlider = content:GetNamedChild("Alpha")
	self.alphaSlider:GetThumbTextureControl():SetDrawLayer(3)
	self.alphaTexture = self.alphaSlider:GetNamedChild("Texture")

	local preview = content:GetNamedChild("Preview")
	self.previewInitialTexture = preview:GetNamedChild("TextureBottom")
    self.previewCurrentTexture = preview:GetNamedChild("TextureTop")

    local function SetColorFromSpinner(r, g, b, a)
        if not self.isUpdatingColors then
            self:SetColor(r, g, b, a)
        end
    end

    local spinners = content:GetNamedChild("Spinners")
    self.redSpinner = ZO_Spinner:New(spinners:GetNamedChild("Red"), 0, 255)
    self.redSpinner:RegisterCallback("OnValueChanged", function(value)
        local r, g, b, a = self:GetColors()
        SetColorFromSpinner(value / 255, g, b, a)
    end)
    self.redSpinner:SetNormalColor(ZO_ColorDef:New(1, .2, .2, 1))

    self.greenSpinner = ZO_Spinner:New(spinners:GetNamedChild("Green"), 0, 255)
    self.greenSpinner:RegisterCallback("OnValueChanged", function(value)
        local r, g, b, a = self:GetColors()
        SetColorFromSpinner(r, value / 255, b, a)
    end)
    self.greenSpinner:SetNormalColor(ZO_ColorDef:New(.2, 1, .2, 1))

    self.blueSpinner = ZO_Spinner:New(spinners:GetNamedChild("Blue"), 0, 255)
    self.blueSpinner:RegisterCallback("OnValueChanged", function(value)
        local r, g, b, a = self:GetColors()
        SetColorFromSpinner(r, g, value / 255, a)
    end)
    self.blueSpinner:SetNormalColor(ZO_ColorDef:New(.2, .2, 1, 1))

    self.alphaSpinner = ZO_Spinner:New(spinners:GetNamedChild("Alpha"), 0, 255)
    self.alphaSpinner:RegisterCallback("OnValueChanged", function(value)
        local r, g, b, a = self:GetColors()
        SetColorFromSpinner(r, g, b, value / 255)
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
                callback =  function() COLOR_PICKER:Cancel() end,
            },
        }
    })
end

function ZO_ColorPicker:UpdateColors(r, g, b, a)
    self.isUpdatingColors = true
	local fullR, fullG, fullB = self.colorSelect:GetFullValuedColorAsRGB()

	self.valueTexture:SetGradientColors(ORIENTATION_VERTICAL, 0, 0, 0, 1, fullR, fullG, fullB, 1)

	if self.hasAlpha then
		self.previewCurrentTexture:SetColor(r, g, b, a)
	else
		self.previewCurrentTexture:SetColor(r, g, b, 1)
	end

    --Even though the alpha is 1.0 at the right, a lower value gives a better visual
	self.alphaTexture:SetGradientColors(ORIENTATION_HORIZONTAL, r, g, b, 0, r, g, b, .85)

    self.redSpinner:SetValue(r * 255)
    self.greenSpinner:SetValue(g * 255)
    self.blueSpinner:SetValue(b * 255)
    if self.hasAlpha then
        self.alphaSpinner:SetValue(a * 255)
    end
    self.isUpdatingColors = false

	if self.colorSelectedCallback then
		if self.hasAlpha then
			self.colorSelectedCallback(r, g, b, a)
		else
			self.colorSelectedCallback(r, g, b)
		end
	end
end

function ZO_ColorPicker:OnColorSet(r, g, b)
	self:UpdateColors(r, g, b, self.alphaSlider:GetValue())
end

function ZO_ColorPicker:OnValueSet(value)
	self.colorSelect:SetValue(value)
end

function ZO_ColorPicker:OnAlphaSet(value)
	local r, g, b = self.colorSelect:GetColorAsRGB()
	self:UpdateColors(r, g, b, value)
end

function ZO_ColorPicker:SetColor(r, g, b, a)
	self.colorSelect:SetColorAsRGB(r, g, b)
	self.valueSlider:SetValue(1 - self.colorSelect:GetValue())

	if self.hasAlpha then
		self.alphaSlider:SetValue(a or 1)
	end

	self:UpdateColors(r, g, b, a or 1)
end

function ZO_ColorPicker:GetColors()
	local r, g, b = self.colorSelect:GetColorAsRGB()
	if self.hasAlpha then
		return r, g, b, self.alphaSlider:GetValue()
	end
	return r, g, b
end

function ZO_ColorPicker:Confirm()
    ZO_Dialogs_ReleaseDialog("COLOR_PICKER")
end

function ZO_ColorPicker:Cancel()
	if self.colorSelectedCallback then
		if self.hasAlpha then
			self.colorSelectedCallback(self.initialR, self.initialG, self.initialB, self.initialA)
		else
			self.colorSelectedCallback(self.initialR, self.initialG, self.initialB)
		end
	end
	self:Confirm()
end

function ZO_ColorPicker:Show(colorSelectedCallback, r, g, b, a)
	self.colorSelectedCallback = colorSelectedCallback

	self.initialR = r or 1
	self.initialG = g or 1
	self.initialB = b or 1
	self.initialA = a or 1

	self.hasAlpha = a ~= nil

    self:SetAlphaLimits(0, 1)

	self:SetColor(self.initialR, self.initialG, self.initialB, self.initialA)
    self.previewInitialTexture:SetColor(self.initialR, self.initialG, self.initialB, self.initialA)

    ZO_Dialogs_ShowDialog("COLOR_PICKER")
end

function ZO_ColorPicker:IsShown()
    return not self.control:IsHidden()
end

function ZO_ColorPicker:UpdateLayout()
	self.content:SetHeight(self.hasAlpha and FULL_HEIGHT or SMALL_HEIGHT)

	if self.hasAlpha then
		self.alphaLabel:SetHidden(false)
		self.alphaSlider:SetHidden(false)
        self.alphaSpinner:GetControl():SetHidden(false)
        self.alphaSlider:SetMinMax(self.alphaLowerLimit, self.alphaUpperLimit)
	else
		self.alphaLabel:SetHidden(true)
		self.alphaSlider:SetHidden(true)
        self.alphaSpinner:GetControl():SetHidden(true)
	end
end

function ZO_ColorPicker:SetAlphaLimits(alphaLowerLimit, alphaUpperLimit)
    self.alphaLowerLimit = alphaLowerLimit or 0
    self.alphaUpperLimit = alphaUpperLimit or 1
    self:UpdateLayout()
end

--[[ XML Handlers ]]--
function ZO_ColorPicker_OnInitialized(self)
	COLOR_PICKER = ZO_ColorPicker:New(self)
end