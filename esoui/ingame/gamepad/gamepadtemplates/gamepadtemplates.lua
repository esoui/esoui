--[[ Global Helper Functions ]]--

do
    local function ApplyParametricScaling(control, parametricValue)
        control:SetScale(zo_lerp(ZO_GAMEPAD_DEFAULT_LIST_MAX_CONTROL_SCALE, ZO_GAMEPAD_DEFAULT_LIST_MIN_CONTROL_SCALE, parametricValue))
    end

    function ZO_GamepadMenuEntryTemplateParametricListFunction(control, distanceFromCenter, continousParametricOffset)
        if control.icon then
            local parametricValue = zo_abs(zo_clamp(distanceFromCenter - continousParametricOffset, -1, 1))
            ApplyParametricScaling(control.icon, parametricValue)
        end
    end
end

--[[ Item Templates ]]--
local function SetupCooldown(control, data)
    if control.cooldown then
        control.inCooldown = false
        control.cooldown:SetTexture(data.icon)
        local remaining, duration = GetItemCooldownInfo(data.bagId, data.slotIndex)
        ZO_GamepadItemSlot_UpdateCooldowns(control, remaining, duration)
    end
end

function ZO_GamepadCheckboxOptionTemplate_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    control.optionEnabledIcon:SetHidden(not data.currentValue)
end

ZO_GamepadQuantitySpinner = {}

function ZO_GamepadQuantitySpinner:InitializeSpinner(valueChangedCallback, direction)
    self.spinner = ZO_Spinner_Gamepad:New(self:GetNamedChild("Spinner"), 1, 1, direction or GAMEPAD_SPINNER_DIRECTION_HORIZONTAL)
    self.spinner:RegisterCallback("OnValueChanged", function(newValue) self:OnValueChanged(newValue) end)
    self.currencyControl = self:GetNamedChild("Price")
    self.valueChangedCallback = valueChangedCallback
end

function ZO_GamepadQuantitySpinner:SetValueChangedCallback(callback)
    self.valueChangedCallback = callback
end

function ZO_GamepadQuantitySpinner:SetMinMax(min, max)
    self.spinner:SetMinMax(min, max)
    self:OnValueChanged(self:GetValue())
end

function ZO_GamepadQuantitySpinner:SetValue(value)
    self.spinner:SetValue(value)
    self:OnValueChanged(self:GetValue())
end

function ZO_GamepadQuantitySpinner:GetValue(value)
    return self.spinner:GetValue()
end

function ZO_GamepadQuantitySpinner:SetupCurrency(unitPrice, currencyType)
    self.unitPrice = unitPrice
    if currencyType and (currencyType ~= 0) then
        self.currencyType = currencyType
    else
        self.currencyType = CURT_MONEY
    end

    self.currencyControl:SetHidden(not unitPrice)
    self:OnValueChanged(self:GetValue())
end

function ZO_GamepadQuantitySpinner:Activate()
    self.spinner:Activate()
end

function ZO_GamepadQuantitySpinner:Deactivate()
    self.spinner:Deactivate()
end

function ZO_GamepadQuantitySpinner:OnValueChanged(newValue)
    if self.valueChangedCallback then
        self.valueChangedCallback(newValue)
    end

    if self.unitPrice then
        local totalCost = newValue * self.unitPrice
        local notEnough = not self.ignoreInvalidCost and totalCost > GetCurrencyAmount(self.currencyType, GetCurrencyPlayerStoredLocation(self.currencyType)) or false
        ZO_CurrencyControl_SetSimpleCurrency(self.currencyControl, self.currencyType, totalCost, ZO_GAMEPAD_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, notEnough)
    end
end

function ZO_GamepadQuantitySpinner:AttachAndShowSpinner(list, targetControl)
    self:Activate()
    self:SetHidden(false)
    self:ClearAnchors()
    self:SetAnchor(TOPLEFT, targetControl, TOPLEFT, 0, -8)
    self:SetAnchor(BOTTOMRIGHT, targetControl, BOTTOMRIGHT, 0, 8)
    self.anchoredToList = list
    self.ignoreInvalidCost = false
	self.anchoredToList:SetMouseEnabled(false)
end

local function OnSelectedDataChanged(list, selectedData)
    local spinner = selectedData.gamepadQuantitySpinner
    if spinner then
        spinner:AttachAndShowSpinner(list, list:GetSelectedControl())
    end
end

function ZO_GamepadQuantitySpinner:AttachToTargetListEntry(list)
    local targetControl = list:GetTargetControl()
    if targetControl then
        self:AttachAndShowSpinner(list, targetControl)
    else
        --There may be no target control if the target is off the top or bottom of the list (not in view). In this case save it off on the target for when it is selected.
        list:SetOnSelectedDataChangedCallback(OnSelectedDataChanged)
        local targetData = list:GetTargetData()
        if targetData then
            targetData.gamepadQuantitySpinner = self
        end
    end
end

function ZO_GamepadQuantitySpinner:DetachFromListEntry()
    if self.anchoredToList then
        self:Deactivate()
        self:SetValue(1)
        self:SetHidden(true)
        self.anchoredToList:RemoveOnSelectedDataChangedCallback(OnSelectedDataChanged)
        local targetData = self.anchoredToList:GetTargetData()
        if targetData then
            targetData.gamepadQuantitySpinner = nil
        end
		self.anchoredToList:SetMouseEnabled(true)
        self.anchoredToList = nil
    end
end

function ZO_GamepadQuantitySpinner:SetIgnoreInvalidCost(ignoreInvalidCost)
    self.ignoreInvalidCost = ignoreInvalidCost
end

function ZO_GamepadLabeledQuantitySpinnerContainerTemplate_Initialize(control)
    zo_mixin(control, ZO_GamepadQuantitySpinner)
end
