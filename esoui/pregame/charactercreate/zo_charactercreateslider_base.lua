--[[ Character Create Slider ]]--

ZO_CharacterCreateSlider_Base = ZO_Object:Subclass()

function ZO_CharacterCreateSlider_Base:New(...)
    local slider = ZO_Object.New(self)
    slider:Initialize(...)
    return slider
end

function ZO_CharacterCreateSlider_Base:Initialize(control)
    control.sliderObject = self
    self.control = control
    self.slider = GetControl(control, "Slider")
    self.name = GetControl(control, "Name")
    self.padlock = GetControl(control, "Padlock")
    self.lockState = TOGGLE_BUTTON_OPEN
end

function ZO_CharacterCreateSlider_Base:SetName(displayName, enumNameFallback, enumValue)
    if displayName and displayName ~= "" then
        self.name:SetText(displayName)
    else
        self.name:SetText(GetString(enumNameFallback, enumValue))
    end
end

function ZO_CharacterCreateSlider_Base:SetData(sliderIndex, name, category, steps, value, defaultValue)
    self.sliderIndex = sliderIndex
    self.category = category

    self.initializing = true
    self.numSteps = steps
    self.defaultValue = defaultValue
    self.slider:SetValueStep(1 / steps)
    self:SetName(nil, "SI_CHARACTERSLIDERNAME", name)
    self:Update(value)
end

function ZO_CharacterCreateSlider_Base:SetValue(value)
    if not self.initializing then
        SetSliderValue(self.sliderIndex, value)
        self:UpdateChangeButtons(value)
    end
end

function ZO_CharacterCreateSlider_Base:ChangeValue(changeAmount)
    local newSteppedValue = zo_floor(self.slider:GetValue() * self.numSteps) + changeAmount
    self:SetValue(newSteppedValue / self.numSteps)
    self:Update()
end

function ZO_CharacterCreateSlider_Base:GetValue()
    return self.slider:GetValue()
end

function ZO_CharacterCreateSlider_Base:Randomize(randomizeType)
    if self.lockState == TOGGLE_BUTTON_OPEN then
        local randomValue = 0

        if (randomizeType == "initial") and (self.defaultValue >= 0) then
            -- If this is the initial randomization and we have a valid default value
            -- then don't actually randomize anything, just use the default value.
            randomValue = self.defaultValue
        else
            -- Otherwise, pick a random value from the valid values
            local numSteps = self.numSteps
            
            if numSteps > 0 then
                randomValue = zo_random(0, numSteps) / numSteps
            end
        end

        self:SetValue(randomValue)
        self:Update()
    end
end

function ZO_CharacterCreateSlider_Base:ToggleLocked()
    self.lockState = not self.lockState
    ZO_ToggleButton_SetState(self.padlock, self.lockState)

    self:UpdateLockState()
end

function ZO_CharacterCreateSlider_Base:CanLock()
    return true
end

function ZO_CharacterCreateSlider_Base:IsLocked()
    return self.lockState ~= TOGGLE_BUTTON_OPEN
end

function ZO_CharacterCreateSlider_Base:UpdateLockState()
    local enabled = self.lockState == TOGGLE_BUTTON_OPEN
    self.slider:SetEnabled(enabled)

    if enabled then
        self:UpdateChangeButtons()
    else
        self:UpdateChangeButton(self.decrementButton, false)
        self:UpdateChangeButton(self.incrementButton, false)
    end
end

function ZO_CharacterCreateSlider_Base:UpdateChangeButton(button, isEnabled)
    if button then     --- This means that the gamepad version (which has no buttons) works fine.
        if isEnabled then
            button:SetState(BSTATE_NORMAL, false)
        else
            button:SetState(BSTATE_DISABLED, true)
        end
    end
end

function ZO_CharacterCreateSlider_Base:UpdateChangeButtons(value)
    if value == nil then
        value = select(4, GetSliderInfo(self.sliderIndex))
    end

    local steppedValue = zo_floor(value * self.numSteps)

    self:UpdateChangeButton(self.decrementButton, steppedValue > 0)
    self:UpdateChangeButton(self.incrementButton, steppedValue < self.numSteps)
end

function ZO_CharacterCreateSlider_Base:Update(value)
    self.initializing = true
    if not value then
        value = select(4, GetSliderInfo(self.sliderIndex))
    end

    self.slider:SetValue(value)
    self.initializing = nil

    self:UpdateChangeButtons(value)
end

--[[ Character Create Appearance Slider ]]--
-- Implemented as a mixin

ZO_CharacterCreateAppearanceSlider = {}

function ZO_CharacterCreateAppearanceSlider:SetData(appearanceName, numValues, displayName)
    self.category = appearanceName

    self:SetName(displayName, "SI_CHARACTERAPPEARANCENAME", appearanceName)
    
    self.legalInitialSettings = {}

    for appearanceIndex =  1, numValues do
        local legalInitialSetting = select(4, GetAppearanceValueInfo(appearanceName, appearanceIndex))
        if legalInitialSetting then
            table.insert(self.legalInitialSettings, appearanceIndex)
        end
    end

    self.initializing = true
    self.slider:SetMinMax(1, numValues)
    self.slider:SetValueStep(1)
    self.numSteps = numValues
    self:Update()
end

function ZO_CharacterCreateAppearanceSlider:SetValue(value)
    if not self.initializing then
        OnCharacterCreateOptionChanged()
        SetAppearanceValue(self.category, value)
        self:UpdateChangeButtons(value)
    end
end

function ZO_CharacterCreateAppearanceSlider:ChangeValue(changeAmount)
    local newSteppedValue = zo_floor(self.slider:GetValue()) + changeAmount
    self:SetValue(newSteppedValue)
    self:Update()
end

function ZO_CharacterCreateAppearanceSlider:Randomize(randomizeType)
    if self.lockState == TOGGLE_BUTTON_OPEN then
        local randomValue = 1

        if (randomizeType == "initial") and (#self.legalInitialSettings > 0) then
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

function ZO_CharacterCreateAppearanceSlider:UpdateChangeButtons(value)
    if value == nil then
        value = GetAppearanceValue(self.category)
    end

    self:UpdateChangeButton(self.decrementButton, value > 1)
    self:UpdateChangeButton(self.incrementButton, value < self.numSteps)
end

function ZO_CharacterCreateAppearanceSlider:Update()
    self.initializing = true
    local currentValue = GetAppearanceValue(self.category)
    self.slider:SetValue(currentValue)
    self.initializing = nil

    self:UpdateChangeButtons(currentValue)
end


-- Global XML functions

function ZO_CharacterCreateSlider_SetSlider(slider, value)
    OnCharacterCreateOptionChanged()
    slider:GetParent().sliderObject:SetValue(value)
end