ZO_ZONE_STORIES_MILESTONE_TILE_KEYBOARD_DIMENSIONS_X = 284
ZO_ZONE_STORIES_MILESTONE_TILE_KEYBOARD_DIMENSIONS_Y = 74
ZO_ZONE_STORIES_MILESTONE_TILE_KEYBOARD_ICON_DIMENSIONS = 64

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_ZoneStory_MilestoneTile_Keyboard = ZO_Object.MultiSubclass(ZO_Tile_Keyboard, ZO_ZoneStory_MilestoneTile)

-- The tooltip is a singleton shared across all tile instances, so the criteria pool must also be a singleton
local g_tooltipCriteriaPool = nil

function ZO_ZoneStory_MilestoneTile_Keyboard:New(...)
    return ZO_ZoneStory_MilestoneTile.New(self, ...)
end

function ZO_ZoneStory_MilestoneTile_Keyboard:InitializePlatform()
    ZO_Tile_Keyboard.InitializePlatform(self)
    self.iconOverlay = self.control:GetNamedChild("Icon"):GetNamedChild("Overlay")

    self.tooltipControl = ZO_ZoneStory_Milestone_Tooltip
    self.tooltip = {}
    self.tooltip.title = self.tooltipControl:GetNamedChild("Title")
    self.tooltip.icon = self.tooltipControl:GetNamedChild("Icon")
    self.tooltip.description = self.tooltipControl:GetNamedChild("Description")
    self.tooltip.reward = self.tooltipControl:GetNamedChild("Reward")
    self.tooltip.locked = self.tooltipControl:GetNamedChild("Locked")

    if not g_tooltipCriteriaPool then
        local criteriaContainer = self.tooltipControl:GetNamedChild("Criteria")
        g_tooltipCriteriaPool = ZO_ControlPool:New("ZO_ZoneStory_MilestoneTooltip_CriterionEntry_Keyboard", criteriaContainer, "Criterion")
    end
    self.tooltipCriteriaPool = g_tooltipCriteriaPool
end

function ZO_ZoneStory_MilestoneTile_Keyboard:OnMouseEnter()
    ZO_Tile_Keyboard.OnMouseEnter(self)

    local offsetX = self.control:GetParent():GetLeft() - self.control:GetLeft() - 15
    local anchor = ZO_Anchor:New(RIGHT, self.control, LEFT, offsetX)

    self.iconOverlay:SetHidden(false)
    self:ShowMilestoneTooltip()
end

function ZO_ZoneStory_MilestoneTile_Keyboard:OnMouseExit()
    ZO_Tile_Keyboard.OnMouseExit(self)

    self.iconOverlay:SetHidden(true)
    self:HideMilestoneTooltip()
end

function ZO_ZoneStory_MilestoneTile_Keyboard:ShowMilestoneTooltip()
    local name, icon, isLocked, lockedText = GetZoneStoryMilestoneInfo(self.milestoneId)

    self.tooltipCriteriaPool:ReleaseAllObjects()
    local previousEntry = nil
    local numCriteriaCompleted = 0
    local numTotalCriteria = GetZoneStoryMilestoneNumCriteria(self.milestoneId)
    for criterionIndex = 1, numTotalCriteria do
        local criterionDescription, criterionCompleted = GetZoneStoryMilestoneCriterionByIndex(self.milestoneId, criterionIndex)
        local entry = self.tooltipCriteriaPool:AcquireObject()
        local textColor = criterionCompleted and ZO_SELECTED_TEXT or ZO_NORMAL_TEXT
        entry:GetNamedChild("CriterionCheckmark"):SetHidden(not criterionCompleted)
        local textControl = entry:GetNamedChild("CriterionText")
        textControl:SetText(criterionDescription)
        textControl:SetColor(textColor:UnpackRGB())
        -- Chain entries vertically; ControlReset already called ClearAnchors
        if previousEntry then
            entry:SetAnchor(TOPLEFT, previousEntry, BOTTOMLEFT)
        else
            entry:SetAnchor(TOPLEFT)
        end
        entry:SetAnchor(RIGHT, self.tooltip.description, RIGHT, 0, 0, ANCHOR_CONSTRAINS_X)
        previousEntry = entry
        if criterionCompleted then
            numCriteriaCompleted = numCriteriaCompleted + 1
        end
    end

    local titleColor = numCriteriaCompleted >= numTotalCriteria and ZO_SECOND_SELECTED_TEXT or ZO_SECOND_NORMAL_TEXT
    local titleIcon = zo_iconFormatInheritColor("EsoUI/Art/Miscellaneous/Gamepad/gp_charNameIcon.dds", "100%", "100%")
    local titleText = zo_strformat(SI_ACHIEVEMENT_TITLE_CHARACTER_LEVEL, titleIcon, name)
    self.tooltip.title:SetText(titleText)
    self.tooltip.title:SetColor(titleColor:UnpackRGB())
    self.tooltip.icon:SetTexture(icon)
    self.tooltip.description:SetText(GetZoneStoryMilestoneDescription(self.milestoneId))
    self.tooltip.reward:SetText(GetZoneStoryMilestoneReward(self.milestoneId))

    if isLocked then
        self.tooltip.locked:SetText(lockedText)
    end
    self.tooltip.locked:SetHidden(not isLocked)

    ZO_ZoneStory_Milestone_Tooltip:ClearAnchors()
    ZO_ZoneStory_Milestone_Tooltip:SetAnchor(TOPRIGHT, self.control, TOPLEFT, -5)
    ZO_ZoneStory_Milestone_Tooltip:SetHidden(false)
end

function ZO_ZoneStory_MilestoneTile_Keyboard:HideMilestoneTooltip()
    ZO_ZoneStory_Milestone_Tooltip:SetHidden(true)
end

function ZO_ZoneStory_MilestoneTile_Keyboard_OnInitialized(control)
    ZO_ZoneStory_MilestoneTile_Keyboard:New(control)
end