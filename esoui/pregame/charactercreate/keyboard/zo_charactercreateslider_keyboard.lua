--[[ Character Create Slider ]]--
ZO_CharacterCreateSlider_Keyboard = ZO_CharacterCreateSlider_Base:Subclass()

function ZO_CharacterCreateSlider_Keyboard:Initialize(...)
    ZO_CharacterCreateSlider_Base.Initialize(self, ...)

    self.decrementButton = self.control:GetNamedChild("Decrement")
    self.incrementButton = self.control:GetNamedChild("Increment")
    self.warningIcon = self.control:GetNamedChild("NameIcon")

    local function OnMouseEnterLabel(label)
        local sliderObject = label:GetParent() and label:GetParent():GetParent() and label:GetParent():GetParent().sliderObject
        local category = sliderObject.category
        local collectibleId = GetActiveCollectibleIdForCharacterAppearance(category)
        local collectibleName = GetCollectibleName(collectibleId)
        local categoryName = GetCollectibleCategoryNameByCollectibleId(collectibleId)
        local formattedCollectibleName = ZO_SELECTED_TEXT:Colorize(zo_strformat(SI_ITEM_FORMAT_STR_TEXT1_TEXT2, collectibleName, categoryName))
        local appearanceTypeText = ZO_SELECTED_TEXT:Colorize(overrideAppearanceName or GetString("SI_CHARACTERAPPEARANCENAME", category))
        local previewTypeToShow = ZO_SELECTED_TEXT:Colorize(zo_strformat(SI_CREATE_CHARACTER_GAMEPAD_PREVIEW_OPTION_FORMAT, GetString("SI_CHARACTERCREATEDRESSINGOPTION", DRESSING_OPTION_YOUR_GEAR)))
        local descriptionText = zo_strformat(SI_CHARACTER_CREATE_PREVIEWING_COLLECTIBLES_TOOLTIP_DESCRIPTION_FORMATTER, appearanceTypeText, formattedCollectibleName, previewTypeToShow, appearanceTypeText)

        InitializeTooltip(InformationTooltip, label, BOTTOM, 0, -10, TOP)
        SetTooltipText(InformationTooltip, descriptionText)
    end

    local function OnMouseExitLabel()
        ClearTooltip(InformationTooltip)
    end

    if self.warningIcon then
        self.warningIcon:SetHandler("OnMouseEnter", OnMouseEnterLabel)
        self.warningIcon:SetHandler("OnMouseExit", OnMouseExitLabel)
    end
end

--[[ Character Create Appearance Slider ]]-- 
ZO_CharacterCreateAppearanceSlider_Keyboard = ZO_CharacterCreateSlider_Keyboard:Subclass()

function ZO_CharacterCreateAppearanceSlider_Keyboard:Initialize(...)
    ZO_CharacterCreateSlider_Keyboard.Initialize(self, ...)
    zo_mixin(self, ZO_CharacterCreateAppearanceSlider)

    -- The mixin seems to override the class definition of SetData, so set it back to this class
    self.SetData = ZO_CharacterCreateAppearanceSlider_Keyboard.SetData
end

function ZO_CharacterCreateAppearanceSlider_Keyboard:SetData(appearanceName, numValues, displayName)
    ZO_CharacterCreateAppearanceSlider.SetData(self, appearanceName, numValues, displayName)

    if self.warningIcon then
        local collectibleId = GetActiveCollectibleIdForCharacterAppearance(self.category)
        if collectibleId ~= nil then
            self.warningIcon:SetHidden(false)
        else
            self.warningIcon:SetHidden(true)
        end
    end
end

--[[ Character Create Color Slider ]]--
-- Similar construction details to the ZO_CharacterCreateSlider_Keyboard.
-- The one main difference is that this comes from a common utility class, so it needs a little extra
-- for wiring up the subsystems.  The internal object and control will be a ZO_ColorSwatchPicker, but this will wrap that in an interface
-- that makes it look like a CharCreate*Slider object.
ZO_CharacterCreateColorSlider_Keyboard = ZO_CharacterCreateSlider_Keyboard:Subclass()

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

    if self.warningIcon then
        local collectibleId = GetActiveCollectibleIdForCharacterAppearance(self.category)
        if collectibleId ~= nil then
            self.warningIcon:SetHidden(false)
        else
            self.warningIcon:SetHidden(true)
        end
    end
end

-- Override parent function, otherwise parent function will break if called for this class object
function ZO_CharacterCreateColorSlider_Keyboard:GetValue()
    return self.slider.m_picker.m_pressedEntry.m_paletteIndex
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

local function GetAppearanceItemName(appearanceName, value)
    --TODO: Look into an approach that works for more than just voice name
    return ZO_CharacterCreateSlider_GetVoiceName(value)
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

function ZO_CharacterCreateDropdownSlider_Keyboard:SetLocked(isLocked)
    if self:IsLocked() ~= isLocked then
        self:ToggleLocked()
    end
end

function ZO_CharacterCreateDropdownSlider_Keyboard:UpdateLockState()
    self.dropdown:SetEnabled(self.lockState == TOGGLE_BUTTON_OPEN)
end

-- Override parent function, otherwise parent function will break if called for this class object
function ZO_CharacterCreateDropdownSlider_Keyboard:GetValue()
    return self.dropdown:GetSelectedItem()
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