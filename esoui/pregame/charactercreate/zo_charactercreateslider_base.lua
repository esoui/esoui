--[[ Character Create Slider ]]--

ZO_CharacterCreateSlider_Base = ZO_InitializingObject:Subclass()

function ZO_CharacterCreateSlider_Base:Initialize(control)
    control.sliderObject = self
    self.control = control
    self.slider = control:GetNamedChild("Slider")
    self.nameLabel = control:GetNamedChild("Name")
    self.padlock = control:GetNamedChild("Padlock")
    self.lockState = TOGGLE_BUTTON_OPEN
end

function ZO_CharacterCreateSlider_Base:SetName(displayName, enumNameFallback, enumValue)
    if displayName and displayName ~= "" then
        self.name = displayName
    else
        self.name = GetString(enumNameFallback, enumValue)
    end
    self.nameLabel:SetText(self.name)
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
    local currentValue = self.slider:GetValue()
    local valueStep = self.slider:GetValueStep()
    local newSteppedValue = currentValue + (changeAmount * valueStep)
    local min, max = self.slider:GetMinMax()
    if newSteppedValue < min or newSteppedValue > max then
        newSteppedValue = zo_clamp(newSteppedValue, min, max)
    end
    if currentValue ~= newSteppedValue then
        self:SetValue(newSteppedValue)
        self:Update()
    end
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

function ZO_CharacterCreateSlider_Base:SetLocked(isLocked)
    if self:IsLocked() ~= isLocked then
        self:ToggleLocked()
    end
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

function ZO_CharacterCreateAppearanceSlider:GetAppearanceValue()
    return GetAppearanceValue(self.category)
end

function ZO_CharacterCreateAppearanceSlider:SetAppearanceValue(value)
    SetAppearanceValue(self.category, value)
end

function ZO_CharacterCreateAppearanceSlider:SetValue(value)
    if not self.initializing then
        OnCharacterCreateOptionChanged()
        self:SetAppearanceValue(value)
        self:UpdateChangeButtons(value)
    end
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
        value = self:GetAppearanceValue()
    end

    self:UpdateChangeButton(self.decrementButton, value > 1)
    self:UpdateChangeButton(self.incrementButton, value < self.numSteps)
end

function ZO_CharacterCreateAppearanceSlider:Update()
    self.initializing = true
    local currentValue = self:GetAppearanceValue()
    self.slider:SetValue(currentValue)
    self.initializing = nil

    self:UpdateChangeButtons(currentValue)
end


-- Global XML functions

function ZO_CharacterCreateSlider_SetSlider(slider, value)
    OnCharacterCreateOptionChanged()
    slider:GetParent().sliderObject:SetValue(value)
end

do
    -- Terrible first implementation
    local voiceIdToNameId =
    {
        SI_CREATE_CHARACTER_VOICE_A,
        SI_CREATE_CHARACTER_VOICE_B,
        SI_CREATE_CHARACTER_VOICE_C,
        SI_CREATE_CHARACTER_VOICE_D,
        SI_CREATE_CHARACTER_VOICE_E,
        SI_CREATE_CHARACTER_VOICE_F,
        SI_CREATE_CHARACTER_VOICE_G,
        SI_CREATE_CHARACTER_VOICE_H,
    }

    function ZO_CharacterCreateSlider_GetVoiceName(value)
        local nameId = voiceIdToNameId[value]
        if nameId then
            return GetString(nameId)
        end

        return GetString(SI_CREATE_CHARACTER_VOICE_A)
    end
end