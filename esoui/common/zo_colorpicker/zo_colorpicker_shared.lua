--[[ Provides a simple color picker dialog
	
	Usage:
	colorPickerObject:Show(colorSelectedCallback[, r][, g][, b][, a])

	*colorSelectedCallback - Called when a value is picked, signature: colorSelectedCallback(newR, newG, newB, newA)
	*r - Optional starting red value (default: 1)
	*g - Optional starting green value (default: 1)
	*b - Optional starting blue value (default: 1)
	*a - Optional starting alpha value, if no alpha value is provided the alpha slider is not shown, if one is provided the alpha slider is shown
]]--


ZO_ColorPicker_Shared = ZO_Object:Subclass()

function ZO_ColorPicker_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ColorPicker_Shared:Initialize(control, dialogName)
    self.control = control
    self.dialogName = dialogName

    local content = self.control:GetNamedChild("Content")
    self.content = content

	self.colorSelect = content:GetNamedChild("ColorSelect")
	self.colorSelectThumb = self.colorSelect:GetNamedChild("Thumb")
	self.colorSelect:SetColorWheelThumbTextureControl(self.colorSelectThumb)
    self.colorSelect:SetHandler("OnColorSelected", function(control, r, g, b) self:OnColorSet(r, g, b) end)

	self.valueSlider = content:GetNamedChild("Value")
	self.valueSlider:GetThumbTextureControl():SetDrawLayer(3)
	self.valueTexture = self.valueSlider:GetNamedChild("Texture")
    self.valueSlider:SetHandler("OnValueChanged", function(control, value) 
        self:OnValueSet(1 - value)
    end)

	self.alphaLabel = content:GetNamedChild("AlphaLabel")
	self.alphaSlider = content:GetNamedChild("Alpha")
    local alphaThumbTexture = self.alphaSlider:GetThumbTextureControl()
    alphaThumbTexture:SetTextureRotation(math.pi / 2)
	alphaThumbTexture:SetDrawLayer(3)
	self.alphaTexture = self.alphaSlider:GetNamedChild("Texture")
    self.alphaSlider:SetHandler("OnValueChanged", function(control, value)
        self:OnAlphaSet(value)
    end)

	self.previewControl = content:GetNamedChild("Preview")
	self.previewInitialTexture = self.previewControl:GetNamedChild("TextureBottom")
    self.previewCurrentTexture = self.previewControl:GetNamedChild("TextureTop")
end

function ZO_ColorPicker_Shared:UpdateColors(r, g, b, a)
	local fullR, fullG, fullB = self.colorSelect:GetFullValuedColorAsRGB()

	self.valueTexture:SetGradientColors(ORIENTATION_VERTICAL, 0, 0, 0, 1, fullR, fullG, fullB, 1)

	if self.hasAlpha then
		self.previewCurrentTexture:SetColor(r, g, b, a)
	else
		self.previewCurrentTexture:SetColor(r, g, b, 1)
	end

    --Even though the alpha is 1.0 at the right, a lower value gives a better visual
	self.alphaTexture:SetGradientColors(ORIENTATION_HORIZONTAL, r, g, b, 0, r, g, b, .85)
end

function ZO_ColorPicker_Shared:OnColorSet(r, g, b)
	self:UpdateColors(r, g, b, self.alphaSlider:GetValue())
end

function ZO_ColorPicker_Shared:OnValueSet(value)
	self.colorSelect:SetValue(value)
end

function ZO_ColorPicker_Shared:OnAlphaSet(value)
	local r, g, b = self.colorSelect:GetColorAsRGB()
	self:UpdateColors(r, g, b, value)
end

function ZO_ColorPicker_Shared:SetColor(r, g, b, a)
	self.colorSelect:SetColorAsRGB(r, g, b)
	self.valueSlider:SetValue(1 - self.colorSelect:GetValue())

	if self.hasAlpha then
		self.alphaSlider:SetValue(a or 1)
	end

	self:UpdateColors(r, g, b, a or 1)
end

function ZO_ColorPicker_Shared:GetColors()
	local r, g, b = self.colorSelect:GetColorAsRGB()
	if self.hasAlpha then
		return r, g, b, self.alphaSlider:GetValue()
	end
	return r, g, b
end

function ZO_ColorPicker_Shared:Confirm()
	if self.colorSelectedCallback then
		self.colorSelectedCallback(self:GetColors())
	end
    ZO_Dialogs_ReleaseDialog(self.dialogName)
end

function ZO_ColorPicker_Shared:Cancel()
	if self.colorSelectedCallback then
		if self.hasAlpha then
			self.colorSelectedCallback(self.initialR, self.initialG, self.initialB, self.initialA)
		else
			self.colorSelectedCallback(self.initialR, self.initialG, self.initialB)
		end
	end
    ZO_Dialogs_ReleaseDialog(self.dialogName)
end

function ZO_ColorPicker_Shared:Show(colorSelectedCallback, r, g, b, a)
	self.colorSelectedCallback = colorSelectedCallback

	self.initialR = r or 1
	self.initialG = g or 1
	self.initialB = b or 1
	self.initialA = a or 1

	self.hasAlpha = a ~= nil

    self:SetAlphaLimits(0, 1)

	self:SetColor(self.initialR, self.initialG, self.initialB, self.initialA)
    self.previewInitialTexture:SetColor(self.initialR, self.initialG, self.initialB, self.initialA)

    ZO_Dialogs_ShowPlatformDialog(self.dialogName)
end

function ZO_ColorPicker_Shared:IsShown()
    return not self.control:IsHidden()
end

function ZO_ColorPicker_Shared:UpdateLayout()
    if self.hasAlpha then
	    self.content:SetHeight(self.hasAlphaHeight)
    else
        self.content:SetHeight(self.doesntHaveAlphaHeight)
    end

	if self.hasAlpha then
		self.alphaLabel:SetHidden(false)
		self.alphaSlider:SetHidden(false)
        self.alphaSlider:SetMinMax(self.alphaLowerLimit, self.alphaUpperLimit)
	else
		self.alphaLabel:SetHidden(true)
		self.alphaSlider:SetHidden(true)
	end
end

function ZO_ColorPicker_Shared:SetHasAlphaContentHeight(height)
    self.hasAlphaHeight = height
end

function ZO_ColorPicker_Shared:SetDoesntHaveAlphaContentHeight(height)
    self.doesntHaveAlphaHeight = height
end

function ZO_ColorPicker_Shared:SetAlphaLimits(alphaLowerLimit, alphaUpperLimit)
    self.alphaLowerLimit = alphaLowerLimit or 0
    self.alphaUpperLimit = alphaUpperLimit or 1
    self:UpdateLayout()
end