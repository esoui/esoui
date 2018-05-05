ZO_LEVEL_UP_REWARDS_KEYBOARD_SCREEN_WIDTH = 500
ZO_LEVEL_UP_REWARDS_KEYBOARD_MAX_SCREEN_HEIGHT = 760
ZO_LEVEL_UP_REWARDS_KEYBOARD_ART_WIDTH = ZO_LEVEL_UP_REWARDS_BACKGROUND_USED_TEXTURE_WIDTH
ZO_LEVEL_UP_REWARDS_KEYBOARD_ART_HEIGHT = 138
ZO_LEVEL_UP_REWARDS_KEYBOARD_ROW_WIDTH = ZO_LEVEL_UP_REWARDS_KEYBOARD_ART_WIDTH
local SCROLL_BAR_WIDTH = 16
local ADDITIONAL_RIGHT_PADDING = 5
ZO_LEVEL_UP_REWARDS_KEYBOARD_SCROLL_WIDTH = ZO_LEVEL_UP_REWARDS_KEYBOARD_ROW_WIDTH + SCROLL_BAR_WIDTH + ADDITIONAL_RIGHT_PADDING

ZO_LevelUpRewardsLayout_Keyboard = ZO_Object:Subclass()

function ZO_LevelUpRewardsLayout_Keyboard:New()
    return ZO_Object.New(self)
end

function ZO_LevelUpRewardsLayout_Keyboard:ResetAnchoring(initialControl)
    --the control that all further controls are anchored off of
    self.initialControl = initialControl
    self.nextOffsetY = 0
    self.totalHeight = 0
    self.rewardControlsBySection = {}
    self.currentSection = 0
end

function ZO_LevelUpRewardsLayout_Keyboard:StartSection()
    self.currentSection = self.currentSection + 1
    self.rewardControlsBySection[self.currentSection] = {}
end

function ZO_LevelUpRewardsLayout_Keyboard:Anchor(control)
    if self.initialControl then
        control:SetAnchor(TOPLEFT, self.initialControl, BOTTOMLEFT, 0, self.totalHeight + self.nextOffsetY)
    else
        control:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, self.totalHeight + self.nextOffsetY)
    end
    self.totalHeight = self.totalHeight + control:GetHeight() + self.nextOffsetY
    self.nextOffsetY = 0
    table.insert(self.rewardControlsBySection[self.currentSection], control)
end

function ZO_LevelUpRewardsLayout_Keyboard:AddOffsetY(offsetY)
   self.nextOffsetY = self.nextOffsetY + offsetY
end

function ZO_LevelUpRewardsLayout_Keyboard:GetTotalHeight()
    return self.totalHeight
end

function ZO_LevelUpRewardsLayout_Keyboard:GetRewardControlsBySection()
    return self.rewardControlsBySection
end
