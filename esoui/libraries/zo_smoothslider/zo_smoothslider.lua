ZO_SmoothSlider = ZO_Object:Subclass()

function ZO_SmoothSlider:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_SmoothSlider:Initialize(control, buttonTemplate, buttonWidth, buttonHeight, buttonPadding, buttonScaleFactor)
    self.control = control
    control:SetHeight(buttonHeight * buttonScaleFactor)
    self.buttonPool = ZO_ControlPool:New(buttonTemplate, control, "Button")
    self.buttonPool:SetCustomFactoryBehavior(function(control)
        control:SetDimensions(buttonWidth, buttonHeight)
        control.object = self
    end)
    self.buttonWidth = buttonWidth
    self.buttonHeight = buttonHeight
    self.buttonPadding = buttonPadding
    self.buttonScaleFactor = buttonScaleFactor
end

function ZO_SmoothSlider:EnableHighlight(normalTexture, highlightTexture)
    self.normalTexture = normalTexture
    self.highlightTexture = highlightTexture
end

function ZO_SmoothSlider:SetMinMax(min, max)
    self.min = min
    self.max = max
    self.value = min
    self:RefreshScales()
end

function ZO_SmoothSlider:SetValue(value)
    self.value = value
    self:RefreshScales()
end

function ZO_SmoothSlider:SetClickedCallback(clickedCallback)
    self.clickedCallback = clickedCallback
end

function ZO_SmoothSlider:SetNumDivisions(numDivisions)
    self.buttonPool:ReleaseAllObjects()
    self.numDivisions = numDivisions
    self.highlightButton = nil
    
    local buttonScaledHeight = self.buttonHeight * self.buttonScaleFactor
    local buttonScaledWidth = self.buttonWidth * self.buttonScaleFactor
    
    local offsetX = buttonScaledWidth / 2
    local offsetY = buttonScaledHeight / 2
    for i = 1, numDivisions do
        local button = self.buttonPool:AcquireObject(i)
        button.index = i
        --Reset all the highlight states
        if(self:IsHighlightEnabled()) then
            button:SetNormalTexture(self.normalTexture)
        end
        button.normalizedIndex = self:NormalizeIndex(i)
        button:SetAnchor(CENTER, nil, TOPLEFT, offsetX, offsetY)
        if(i < numDivisions) then
            offsetX = offsetX + buttonScaledWidth / 2 + self.buttonWidth / 2 + self.buttonPadding
        end
    end

    self.control:SetWidth(offsetX + buttonScaledWidth / 2)
end

function ZO_SmoothSlider:NormalizeIndex(index)
    return (index - 1) / (self.numDivisions - 1)
end

function ZO_SmoothSlider:NormalizeValue(value)
    local range = self.max - self.min
    if(range > 0) then
        return zo_clamp((value - self.min) / (self.max - self.min), 0, 1)
    else
        return 0
    end
end

function ZO_SmoothSlider:ComputeScale(normalizedDiff)
    local activation
    if(normalizedDiff > 1 / (self.numDivisions - 1)) then
        activation = 0
    else
        activation = 1 - (normalizedDiff * (self.numDivisions - 1))
    end
    return 1 + (self.buttonScaleFactor - 1) * activation
end

function ZO_SmoothSlider:IsHighlightEnabled()
    return self.highlightTexture ~= nil
end

function ZO_SmoothSlider:RefreshScales()
    local normalizedValue = self:NormalizeValue(self.value)
    local newHighlightButton
    local minDistanceFromMaxScale = math.huge

    for _, button in ipairs(self.buttonPool:GetActiveObjects()) do
        local scale = self:ComputeScale(zo_abs(button.normalizedIndex - normalizedValue))
        button:SetScale(scale)
        if(self:IsHighlightEnabled()) then
            local distanceFromMaxScale = zo_abs(scale - self.buttonScaleFactor)
            if(distanceFromMaxScale < minDistanceFromMaxScale) then
                minDistanceFromMaxScale = distanceFromMaxScale
                newHighlightButton = button
            end            
        end
    end

    if(self:IsHighlightEnabled()) then
        if(newHighlightButton ~= self.highlightButton) then
            if(self.highlightButton) then
                self.highlightButton:SetNormalTexture(self.normalTexture)
            end
            self.highlightButton = newHighlightButton
            if(newHighlightButton) then
                newHighlightButton:SetNormalTexture(self.highlightTexture)
            end
        end
    end
end

function ZO_SmoothSlider:GetValueFromButtonIndex(index)
    return self:NormalizeIndex(index) * (self.max - self.min) + self.min
end

function ZO_SmoothSlider:GetButtonIndexFromValue(value)
    return self:NormalizeValue(value) * (self.numDivisions - 1) + 1
end

function ZO_SmoothSlider:GetStepValue(value, amount)
    local targetIndex = self:GetButtonIndexFromValue(value)
    local targetInt, targetDec = zo_decimalsplit(targetIndex)
    if(targetDec < 0.01) then
        targetIndex = targetInt
    elseif(targetDec > 0.99) then
        targetIndex = targetInt + 1
    end

    if(amount > 0) then
        targetIndex = zo_floor(targetIndex) + amount
    elseif(amount < 0) then
        targetIndex = zo_ceil(targetIndex) + amount
    else
        targetIndex = zo_round(targetIndex)
    end

    targetIndex = zo_clamp(targetIndex, 1, self.numDivisions)
    local targetValue = self:GetValueFromButtonIndex(targetIndex)
    return targetValue
end

--Local XML
function ZO_SmoothSlider:Button_OnClicked(button)
    local value = self:GetValueFromButtonIndex(button.index)
    if(self.clickedCallback) then
        self.clickedCallback(value)
    end
end

--Global XML
function ZO_SmoothSliderButton_OnClicked(self)
    self.object:Button_OnClicked(self)
end