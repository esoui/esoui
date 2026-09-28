ZO_GenericSelectorRewards_Keyboard = ZO_InitializingObject:Subclass()

function ZO_GenericSelectorRewards_Keyboard:Initialize(control)
    self.control = control
    control.object = self

    self.titleLabel = control:GetNamedChild("Title")
    self.listContainer = control:GetNamedChild("List")
    self.rewardLabelControlPool = ZO_ControlPool:New("ZO_GenericSelectorRewards_RewardLabel", self.listContainer, "Reward")
end

function ZO_GenericSelectorRewards_Keyboard:SetupRewards()
    self.rewardLabelControlPool:ReleaseAllObjects()
    local LABEL_OFFSET_Y = 5
    local numRewards = GetNumGenericSelectorRewards()
    local previousControl = nil
    for index = 1, numRewards do
        local labelControl = self.rewardLabelControlPool:AcquireObject()
        local rewardText = GetGenericSelectorRewardDescriptionAtIndex(index)
        local rewardTextColor = IsGenericSelectorRewardActiveAtIndex(index) and ZO_NORMAL_TEXT or ZO_DISABLED_TEXT
        labelControl:SetText(rewardText)
        labelControl:SetColor(rewardTextColor:UnpackRGBA())

        if not previousControl then
            labelControl:SetAnchor(TOP, self.listContainer, TOP)
        else
            labelControl:SetAnchor(TOP, previousControl, BOTTOM, 0, LABEL_OFFSET_Y)
        end
        previousControl = labelControl
    end
end

function ZO_GenericSelectorRewards_Keyboard:Show()
    self:SetupRewards()
    self.control:SetHidden(false)
end

function ZO_GenericSelectorRewards_Keyboard:Hide()
    self.control:SetHidden(true)
    self.rewardLabelControlPool:ReleaseAllObjects()
end

function ZO_GenericSelectorRewards_Keyboard:ShouldShow()
    return GetNumGenericSelectorRewards() > 0
end

function ZO_GenericSelectorRewards_Keyboard.OnControlInitialized(control)
    ZO_GENERIC_SELECTOR_REWARDS = ZO_GenericSelectorRewards_Keyboard:New(control)
end