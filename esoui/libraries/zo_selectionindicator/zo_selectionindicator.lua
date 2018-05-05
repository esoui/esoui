
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

    local function FactoryFunction(objectPool)
        local button = ZO_ObjectPool_CreateNamedControl(self.controlName, self.virtualControlTemplate, objectPool, self.control)
        button:SetHandler("OnClicked", function() self:OnButtonClicked(button) end)
        return button
    end

    self.objectPool = ZO_ObjectPool:New(FactoryFunction)
end

function ZO_SelectionIndicator:OnButtonClicked(button)
    local index = self:GetButtonIndex(button)
    self:SetSelectionByIndex(index)

    if self.buttonClickedCallback then
        self.buttonClickedCallback()
    end
end

function ZO_SelectionIndicator:SetButtonClickedCallback(buttonClickedCallback)
    self.buttonClickedCallback = buttonClickedCallback
end

function ZO_SelectionIndicator:SetButtonControlName(controlName)
    self.controlName = controlName
end

function ZO_SelectionIndicator:SetButtonVirtualControl(virtualControlTemplate)
    self.virtualControlTemplate = virtualControlTemplate
end

function ZO_SelectionIndicator:SetGrowthPadding(padding)
    self.growthPadding = padding
end

function ZO_SelectionIndicator:SetCount(countToAdd)
    self.objectPool:ReleaseAllObjects()
    ZO_ClearNumericallyIndexedTable(self.indicatorList)

    for i = 1, countToAdd do
        local button = self:AddButton()

        -- Set Anchors
        if self.growthDirection == ZO_SELECTION_INDICATOR_GROWTH_DIRECTION.RIGHT then
            if i > 1 then
                button:SetAnchor(TOPLEFT, self.indicatorList[i-1], TOPRIGHT, self.growthPadding)
            else 
                button:SetAnchor(TOPLEFT)
            end
        elseif self.growthDirection == ZO_SELECTION_INDICATOR_GROWTH_DIRECTION.LEFT then
            if i > 1 then
                button:SetAnchor(TOPRIGHT, self.indicatorList[i-1], TOPLEFT, -self.growthPadding)
            else 
                button:SetAnchor(TOPRIGHT)
            end
        elseif self.growthDirection == ZO_SELECTION_INDICATOR_GROWTH_DIRECTION.UP then
            if i > 1 then
                button:SetAnchor(BOTTOMLEFT, self.indicatorList[i-1], TOPLEFT, 0, -self.growthPadding)
            else 
                button:SetAnchor(BOTTOMLEFT)
            end
        elseif self.growthDirection == ZO_SELECTION_INDICATOR_GROWTH_DIRECTION.DOWN then
            if i > 1 then
                button:SetAnchor(TOPLEFT, self.indicatorList[i-1], BOTTOMLEFT, 0, self.growthPadding)
            else 
                button:SetAnchor(TOPLEFT)
            end
        end
    end
end

function ZO_SelectionIndicator:AddButton()
    local button = self.objectPool:AcquireObject()
    button:GetNamedChild("IndicatorButtonTexture"):SetTexture("EsoUI/Art/Buttons/featureDot_inactive.dds")
    button:SetHidden(false)
    table.insert(self.indicatorList, button)
    return button
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
        self.currentSelection:GetNamedChild("IndicatorButtonTexture"):SetTexture("EsoUI/Art/Buttons/featureDot_inactive.dds")
    end
    self.currentSelection = button
    self.currentSelection:GetNamedChild("IndicatorButtonTexture"):SetTexture("EsoUI/Art/Buttons/featureDot_active.dds")
end

-----
-- Global XML Functions
-----

function ZO_SelectionIndicator_OnInitialized(control)
    ZO_SelectionIndicator:New(control)
end
