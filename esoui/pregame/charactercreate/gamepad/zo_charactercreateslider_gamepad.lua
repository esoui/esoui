-- Character Create Slider
ZO_CharacterCreateSlider_Gamepad = ZO_CharacterCreateSlider_Base:Subclass()

function ZO_CharacterCreateSlider_Gamepad:New(...)
    return ZO_CharacterCreateSlider_Base.New(self, ...)
end

function ZO_CharacterCreateSlider_Gamepad:Initialize(...)
    ZO_CharacterCreateSlider_Base.Initialize(self, ...)

    self:EnableFocus(false)
end

function ZO_CharacterCreateSlider_Gamepad:EnableFocus(enabled)
    local interfaceColor
    local fontString
    local alpha
    if enabled then
        interfaceColor = INTERFACE_TEXT_COLOR_SELECTED
        fontString = "ZoFontGamepad42"
        alpha = 1.0
    else
        interfaceColor = INTERFACE_TEXT_COLOR_DISABLED
        fontString = "ZoFontGamepad34"
        alpha = 0.5
    end

    local r,g,b = GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, interfaceColor)
    self.name:SetColor(r,g,b)
    self.name:SetFont(fontString)
    self.slider:SetColor(r,g,b)
    self.slider:GetNamedChild("Left"):SetColor(r,g,b)
    self.slider:GetNamedChild("Right"):SetColor(r,g,b)
    self.slider:GetNamedChild("Center"):SetColor(r,g,b)
    self.padlock:SetAlpha(alpha)
end

function ZO_CharacterCreateSlider_Gamepad:Move(delta)
    if self:IsLocked() then
        return
    end

    OnCharacterCreateOptionChanged()
    local oldValue = self:GetValue()
    self:ChangeValue(delta)
    if oldValue ~= self:GetValue() then
        PlaySound(SOUNDS.DEFAULT_CLICK)
    end
end

function ZO_CharacterCreateSlider_Gamepad:MoveNext()
    self:Move(1)
end

function ZO_CharacterCreateSlider_Gamepad:MovePrevious()
    self:Move(-1)
end

-- Character Create Appearance Slider
ZO_CharacterCreateAppearanceSlider_Gamepad = ZO_CharacterCreateSlider_Gamepad:Subclass()

function ZO_CharacterCreateAppearanceSlider_Gamepad:New(control)
    local slider = ZO_CharacterCreateSlider_Gamepad.New(self, control)

    zo_mixin(slider, ZO_CharacterCreateAppearanceSlider)

    return slider
end

-- Voice slider
ZO_CharacterCreateVoiceSlider_Gamepad = ZO_CharacterCreateAppearanceSlider_Gamepad:Subclass()

function ZO_CharacterCreateVoiceSlider_Gamepad:New(control)
    local slider = ZO_CharacterCreateAppearanceSlider_Gamepad.New(self, control)
    slider.primaryButtonName = GetString(SI_CREATE_CHARACTER_GAMEPAD_TEST_VOICE)
    slider.showKeybind = true
    return slider
end

function ZO_CharacterCreateVoiceSlider_Gamepad:OnPrimaryButtonPressed(control)
    PreviewAppearanceValue(APPEARANCE_NAME_VOICE)
end

function ZO_CharacterCreateVoiceSlider_Gamepad:MoveNext()
    if self:IsLocked() then
        return
    end

    local oldValue = self.slider:GetValue()

    ZO_CharacterCreateAppearanceSlider_Gamepad.MoveNext(self)
end

function ZO_CharacterCreateVoiceSlider_Gamepad:MovePrevious()
    if self:IsLocked() then
        return
    end

    local oldValue = self.slider:GetValue()

    ZO_CharacterCreateAppearanceSlider_Gamepad.MovePrevious(self)
end

-- Gender slider
ZO_CharacterCreateGenderSlider_Gamepad = ZO_CharacterCreateSlider_Gamepad:Subclass()

function ZO_CharacterCreateGenderSlider_Gamepad:New(control)
    return ZO_CharacterCreateSlider_Gamepad.New(self, control)
end

function ZO_CharacterCreateGenderSlider_Gamepad:SetData()
    self:SetName(GetString(SI_CREATE_CHARACTER_GAMEPAD_GENDER_SLIDER_NAME))

    self.legalInitialSettings = {}

    local numValues = 2
    for appearanceIndex =  1, numValues do
        table.insert(self.legalInitialSettings, appearanceIndex)
    end

    self.initializing = true
    self.slider:SetMinMax(1, numValues)
    self.slider:SetValueStep(1)
    self.numSteps = numValues
    self:Update()
end

function ZO_CharacterCreateGenderSlider_Gamepad:CanLock()
    return false
end

function ZO_CharacterCreateGenderSlider_Gamepad:SetValue(value)
    if not self.initializing then
        OnCharacterCreateOptionChanged()
        GAMEPAD_CHARACTER_CREATE_MANAGER:SetGender(value)
    end
end

function ZO_CharacterCreateGenderSlider_Gamepad:ChangeValue(changeAmount)
    local newSteppedValue = zo_floor(self.slider:GetValue()) + changeAmount
    local min, max = self.slider:GetMinMax()
    newSteppedValue = zo_clamp(newSteppedValue, min, max)
    self:SetValue(newSteppedValue)
    self:Update()
end

function ZO_CharacterCreateGenderSlider_Gamepad:Randomize(randomizeType)
    if self.lockState == TOGGLE_BUTTON_OPEN then
        local randomValue = 1

        if randomizeType == "initial" and #self.legalInitialSettings > 0 then
            -- If this is the initial randomization and we have some legal initial values
            -- then only randomize over those values
            randomValue = self.legalInitialSettings[zo_random(1, #self.legalInitialSettings)]
        else
            -- Otherwise, pick a random value from the valid values
            local maxValue = self.numSteps
            if maxValue > 0 then
                randomValue = zo_random(1, maxValue)
            end
        end

        self:SetValue(randomValue)
        self:Update()
    end
end

function ZO_CharacterCreateGenderSlider_Gamepad:Update()
    self.initializing = true
	local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local currentValue = CharacterCreateGetGender(characterMode)
    self.slider:SetValue(currentValue)
    self.initializing = nil
end