--[[ Character Create Slider ]]--
ZO_CharacterCreateSlider_Keyboard = ZO_CharacterCreateSlider_Base:Subclass()

function ZO_CharacterCreateSlider_Keyboard:New(...)
    return ZO_CharacterCreateSlider_Base.New(self, ...)
end

function ZO_CharacterCreateSlider_Keyboard:Initialize(...)
    ZO_CharacterCreateSlider_Base.Initialize(self, ...)

    self.decrementButton = GetControl(self.control, "Decrement")
    self.incrementButton = GetControl(self.control, "Increment")
end

--[[ Character Create Appearance Slider ]]-- 
ZO_CharacterCreateAppearanceSlider_Keyboard = ZO_CharacterCreateSlider_Keyboard:Subclass()

function ZO_CharacterCreateAppearanceSlider_Keyboard:New(...)
    return ZO_CharacterCreateSlider_Keyboard.New(self, ...)
end

function ZO_CharacterCreateAppearanceSlider_Keyboard:Initialize(...)
    ZO_CharacterCreateSlider_Keyboard.Initialize(self, ...)
    zo_mixin(self, ZO_CharacterCreateAppearanceSlider)
end

--[[ Character Create Color Slider ]]--
-- Similar construction details to the ZO_CharacterCreateSlider_Keyboard.
-- The one main difference is that this comes from a common utility class, so it needs a little extra
-- for wiring up the subsystems.  The internal object and control will be a ZO_ColorSwatchPicker, but this will wrap that in an interface
-- that makes it look like a CharCreate*Slider object.
ZO_CharacterCreateColorSlider_Keyboard = ZO_CharacterCreateSlider_Keyboard:Subclass()

function ZO_CharacterCreateColorSlider_Keyboard:New(...)
    return ZO_CharacterCreateSlider_Keyboard.New(self, ...)
end

function ZO_CharacterCreateColorSlider_Keyboard:Initialize(...)
    ZO_CharacterCreateSlider_Keyboard.Initialize(self, ...)

    local function OnClickedCallback(paletteIndex)
        OnCharacterCreateOptionChanged()
        SetAppearanceValue(self.category, paletteIndex)
    end

    ZO_ColorSwatchPicker_SetClickedCallback(self.slider, OnClickedCallback)
end

function ZO_CharacterCreateColorSlider_Keyboard:SetData(appearanceName, numValues, displayName)
    self.category = appearanceName
    self.numSteps = numValues

    self:SetName(displayName, "SI_CHARACTERAPPEARANCENAME", appearanceName)

    self.legalInitialSettings = {}

    for paletteIndex =  1, numValues do
        local r, g, b, legalInitialSetting = GetAppearanceValueInfo(appearanceName, paletteIndex)
        ZO_ColorSwatchPicker_AddColor(self.slider, paletteIndex, r, g, b)

        if legalInitialSetting then
            table.insert(self.legalInitialSettings, paletteIndex)
        end
    end

    self:Update()
end

function ZO_CharacterCreateColorSlider_Keyboard:Randomize(randomizeType)
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

        OnCharacterCreateOptionChanged()
        SetAppearanceValue(self.category, randomValue)
        self:Update()
    end
end

function ZO_CharacterCreateColorSlider_Keyboard:UpdateLockState()
    ZO_ColorSwatchPicker_SetEnabled(self.slider, self.lockState == TOGGLE_BUTTON_OPEN)
end

function ZO_CharacterCreateColorSlider_Keyboard:Update()
    ZO_ColorSwatchPicker_SetSelected(self.slider, GetAppearanceValue(self.category))
end

--[[ Character Create Dropdown Slider ]]--
-- Similar interface to the ZO_CharacterCreateSlider_Keyboard, completely different internals.
-- The drop down is used to choose named appearance types.
ZO_CharacterCreateDropdownSlider_Keyboard = ZO_Object:Subclass()

function ZO_CharacterCreateDropdownSlider_Keyboard:New(...)
    local slider = ZO_Object.New(self)
    slider:Initialize(...)
    return slider
end

function ZO_CharacterCreateDropdownSlider_Keyboard:Initialize(control)
    control.sliderObject = self
    self.control = control
    self.padlock = GetControl(control, "Padlock")
    self.lockState = TOGGLE_BUTTON_OPEN

    self.dropdown = ZO_ComboBox_ObjectFromContainer(control:GetNamedChild("Dropdown"))
    self.dropdown:SetSortsItems(false)
    self.dropdown:SetFont("ZoFontGame")
    self.dropdown:SetSpacing(4)
end

function ZO_CharacterCreateDropdownSlider_Keyboard:SetName(displayName, enumNameFallback, enumValue)
    -- nothing to do for now, the only dropdown in use has its own section
end

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

local function GetAppearanceItemName(appearanceName, value)
    local nameId = voiceIdToNameId[value]
    if nameId then
        return GetString(nameId)
    end

    return GetString(SI_CREATE_CHARACTER_VOICE_A)
end

function ZO_CharacterCreateDropdownSlider_Keyboard:SetData(appearanceName, numValues, displayName)
    self.category = appearanceName
    self.numSteps = numValues

    self:SetName(displayName, "SI_CHARACTERAPPEARANCENAME", appearanceName)

    self.legalInitialSettings = {}
    self.dropdown:ClearItems()

    local function OnAppearanceItemSelected(dropdown, itemName, entry)
        OnCharacterCreateOptionChanged()
        SetAppearanceValue(self.category, entry.value)
        self:Update()
    end

    for valueIndex = 1, numValues do
        local _, _, _, legalInitialSetting = GetAppearanceValueInfo(appearanceName, valueIndex)

        local itemName = GetAppearanceItemName(appearanceName, valueIndex)
        local entry = self.dropdown:CreateItemEntry(itemName, OnAppearanceItemSelected)
        entry.value = valueIndex
        self.dropdown:AddItem(entry)

        if legalInitialSetting then
            table.insert(self.legalInitialSettings, valueIndex)
        end
    end

    self:Update()
end

function ZO_CharacterCreateDropdownSlider_Keyboard:Randomize(randomizeType)
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

        OnCharacterCreateOptionChanged()
        SetAppearanceValue(self.category, randomValue)
        self:Update()
    end
end

function ZO_CharacterCreateDropdownSlider_Keyboard:ToggleLocked()
    self.lockState = not self.lockState
    ZO_ToggleButton_SetState(self.padlock, self.lockState)

    self:UpdateLockState()
end

function ZO_CharacterCreateDropdownSlider_Keyboard:UpdateLockState()
    self.dropdown:SetEnabled(self.lockState == TOGGLE_BUTTON_OPEN)
end

function ZO_CharacterCreateDropdownSlider_Keyboard:IsLocked()
    return self.lockState ~= TOGGLE_BUTTON_OPEN
end

function ZO_CharacterCreateDropdownSlider_Keyboard:Update()
    local appearanceValue = GetAppearanceValue(self.category)

    local function SelectAppropriateAppearance(index, entry)
        if entry.value == appearanceValue then
            self.dropdown:SetSelectedItem(entry.name)
            return true
        end
    end

    self.dropdown:EnumerateEntries(SelectAppropriateAppearance)
end

function ZO_CharacterCreateDropdownSlider_Keyboard:Preview()
    PreviewAppearanceValue(self.category)
end

-- Global / XML functions

function ZO_CharacterCreateSlider_Keyboard_TogglePadlock(button)
    button:GetParent().sliderObject:ToggleLocked()
end