
ZO_SELECTION_INDICATOR_GROWTH_DIRECTION =
{
    LEFT = 1,
    RIGHT = 2,
    UP = 3,
    DOWN = 4
}

ZO_SelectionIndicator = ZO_Object:Subclass()

function ZO_SelectionIndicator:New(...)
    local indicator = ZO_Object.New(self)
    indicator:Initialize(...)
    return indicator
end

function ZO_SelectionIndicator:Initialize(control)
    self.control = control
    control.object = self

    -- Set default direction to grow to the Right
    self.growthDirection = ZO_SELECTION_INDICATOR_GROWTH_DIRECTION.RIGHT
    self.growthPadding = 0

    self.indicatorList = {}
    self:SetButtonVirtualControl("ZO_SelectionIndicator_Button_Control")

    self.controlPool = ZO_ControlPool:New(self.virtualControlTemplate, self.control, "SelectionIndicatorPip")

    self.selectedImage = "EsoUI/Art/Buttons/featureDot_active.dds"
    self.unselectedImage = "EsoUI/Art/Buttons/featureDot_inactive.dds"
    self.mouseOverImage = nil
    self.buttonWidth = 16
    self.buttonHeight = 16
end

function ZO_SelectionIndicator:OnButtonClicked(button)
    local index = self:GetButtonIndex(button)
    self:SetSelectionByIndex(index)

    if self.buttonClickedCallback then
        self.buttonClickedCallback()
    end
end

function ZO_SelectionIndicator:OnMouseEnter(button)
    if self.mouseOverImage then
        button:GetNamedChild("IndicatorButtonTexture"):SetTexture(self.mouseOverImage)
    end
end

function ZO_SelectionIndicator:OnMouseExit(button)
    if button == self.currentSelection then
        button:GetNamedChild("IndicatorButtonTexture"):SetTexture(self.selectedImage)
    else
        button:GetNamedChild("IndicatorButtonTexture"):SetTexture(self.unselectedImage)
    end
end

function ZO_SelectionIndicator:SetButtonClickedCallback(buttonClickedCallback)
    self.buttonClickedCallback = buttonClickedCallback
end

function ZO_SelectionIndicator:SetButtonControlName(controlName)
    self.controlName = controlName
end

function ZO_SelectionIndicator:SetButtonSelectedImage(image)
    self.selectedImage = image
end

function ZO_SelectionIndicator:SetButtonUnselectedImage(image)
    self.unselectedImage = image
end

function ZO_SelectionIndicator:SetButtonMouseOverImage(image)
    self.mouseOverImage = image
end

function ZO_SelectionIndicator:SetButtonVirtualControl(virtualControlTemplate)
    self.virtualControlTemplate = virtualControlTemplate
end

function ZO_SelectionIndicator:SetGrowthPadding(padding)
    self.growthPadding = padding
end

function ZO_SelectionIndicator:SetButtonWidth(width)
    self.buttonWidth = width
end

function ZO_SelectionIndicator:SetButtonHeight(height)
    self.buttonHeight = height
end

function ZO_SelectionIndicator:SetCount(countToAdd)
    self.controlPool:ReleaseAllObjects()
    ZO_ClearNumericallyIndexedTable(self.indicatorList)

    local width = 0
    for i = 1, countToAdd do
        local button = self:AddButton()
        width = width + button:GetWidth()

        -- Set Anchors
        if self.growthDirection == ZO_SELECTION_INDICATOR_GROWTH_DIRECTION.RIGHT then
            if i > 1 then
                button:SetAnchor(TOPLEFT, self.indicatorList[i-1], TOPRIGHT, self.growthPadding)
                width = width + self.growthPadding
            else
                button:SetAnchor(TOPLEFT)
            end
        elseif self.growthDirection == ZO_SELECTION_INDICATOR_GROWTH_DIRECTION.LEFT then
            if i > 1 then
                button:SetAnchor(TOPRIGHT, self.indicatorList[i-1], TOPLEFT, -self.growthPadding)
                width = width + self.growthPadding
            else
                button:SetAnchor(TOPRIGHT)
            end
        elseif self.growthDirection == ZO_SELECTION_INDICATOR_GROWTH_DIRECTION.UP then
            if i > 1 then
                button:SetAnchor(BOTTOMLEFT, self.indicatorList[i-1], TOPLEFT, 0, -self.growthPadding)
                width = width + self.growthPadding
            else
                button:SetAnchor(BOTTOMLEFT)
            end
        elseif self.growthDirection == ZO_SELECTION_INDICATOR_GROWTH_DIRECTION.DOWN then
            if i > 1 then
                button:SetAnchor(TOPLEFT, self.indicatorList[i-1], BOTTOMLEFT, 0, self.growthPadding)
                width = width + self.growthPadding
            else
                button:SetAnchor(TOPLEFT)
            end
        end
    end
end

function ZO_SelectionIndicator:AddButton()
    if self.controlPool then
        local button = self.controlPool:AcquireObject()
        button:GetNamedChild("IndicatorButtonTexture"):SetTexture(self.unselectedImage)
        button:SetHidden(false)
        button:SetWidth(self.buttonWidth)
        button:SetHeight(self.buttonHeight)
        table.insert(self.indicatorList, button)
        return button
    end
    return nil
end

function ZO_SelectionIndicator:GetButtonByIndex(index)
    return self.indicatorList[index]
end

function ZO_SelectionIndicator:GetButtonIndex(button)
    for i, indicatorButton in ipairs(self.indicatorList) do
        if button == indicatorButton then
            return i
        end
    end
end

function ZO_SelectionIndicator:GetSelectionIndex()
    return self:GetButtonIndex(self.currentSelection)
end

function ZO_SelectionIndicator:SetSelectionByIndex(index)
    local button = self.indicatorList[index]
    if self.currentSelection then
        self.currentSelection:GetNamedChild("IndicatorButtonTexture"):SetTexture(self.unselectedImage)
    end
    self.currentSelection = button
    self.currentSelection:GetNamedChild("IndicatorButtonTexture"):SetTexture(self.selectedImage)
end

-----
-- Global XML Functions
-----

function ZO_SelectionIndicator_OnInitialized(control)
    ZO_SelectionIndicator:New(control)
end
