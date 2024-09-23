local ZoneStoryTracker = ZO_HUDTracker_Base:Subclass()

function ZoneStoryTracker:New(...)
    return ZO_HUDTracker_Base.New(self, ...)
end

function ZoneStoryTracker:Initialize(control)
    ZO_HUDTracker_Base.Initialize(self, control)

    self.iconControl = self.container:GetNamedChild("Icon")

    ZONE_STORY_TRACKER_FRAGMENT = self:GetFragment()
end

function ZoneStoryTracker:InitializeStyles()
    self.styles =
    {
        keyboard =
        {
            FONT_HEADER = "ZoFontGameShadow",
            FONT_SUBLABEL = "ZoFontGameShadow",
            TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_NONE,
            RESIZE_TO_FIT_PADDING_HEIGHT = 10,

            -- Quest Tracker anchors are old and complicated and there's not an easy way to set up a consitent scheme
            -- If we can one day refactor quest tracker to be more sensible this could be simplified
            -- In the mean time, anything anchored after this should be simple
            TOP_LEVEL_PRIMARY_ANCHOR_QUEST_TRACKER = ZO_Anchor:New(TOPLEFT, ZO_FocusedQuestTrackerPanelContainerQuestContainer, BOTTOMLEFT, 0, 10),
            TOP_LEVEL_PRIMARY_ANCHOR_NO_QUEST_TRACKER = ZO_Anchor:New(TOPLEFT, ZO_FocusedQuestTrackerPanelContainerQuestContainer, TOPLEFT, 0, 10),
            TOP_LEVEL_SECONDARY_ANCHOR = ZO_Anchor:New(RIGHT, GuiRoot, RIGHT, 0, 0, ANCHOR_CONSTRAINS_X),

            CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT),
            CONTAINER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT),

            SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y = 2,
        },
        gamepad =
        {
            FONT_HEADER = "ZoFontGamepadBold27",
            FONT_SUBLABEL = "ZoFontGamepad34",
            TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_UPPERCASE,
            RESIZE_TO_FIT_PADDING_HEIGHT = 20,

            TOP_LEVEL_PRIMARY_ANCHOR_QUEST_TRACKER = ZO_Anchor:New(TOPRIGHT, ZO_FocusedQuestTrackerPanelContainerQuestContainer, BOTTOMRIGHT, 0, 20),
            TOP_LEVEL_PRIMARY_ANCHOR_NO_QUEST_TRACKER = ZO_Anchor:New(TOPRIGHT, ZO_FocusedQuestTrackerPanelContainerQuestContainer, TOPRIGHT, 0, 20),

            CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT),

            SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y = 10,
        }
    }
    ZO_HUDTracker_Base.InitializeStyles(self)
end

function ZoneStoryTracker:RegisterEvents()
    ZO_HUDTracker_Base.RegisterEvents(self)

    local function Update()
        self:Update()
    end

    self.control:RegisterForEvent(EVENT_ZONE_STORY_ACTIVITY_TRACKED, Update)
    self.control:RegisterForEvent(EVENT_ZONE_STORY_ACTIVITY_UNTRACKED, Update)
    self.control:RegisterForEvent(EVENT_ZONE_STORY_ACTIVITY_TRACKING_INIT, Update)
end

function ZoneStoryTracker:Update()
    local zoneId, completionType, activityId = GetTrackedZoneStoryActivityInfo()
    if zoneId ~= 0 then
        local data = ZONE_STORIES_MANAGER:GetZoneData(zoneId)
        local subLabelText = GetZoneStoryShortDescriptionByActivityId(zoneId, completionType, activityId)

        self:SetHeaderText(ZO_CachedStrFormat(SI_ZONE_STORY_TRACKER_TITLE, data.name))
        self:SetSubLabelText(subLabelText)
    end
end

function ZoneStoryTracker:GetPrimaryAnchor()
    local style = self.currentStyle
    if FOCUSED_QUEST_TRACKER_FRAGMENT:IsShowing() then
        return style.TOP_LEVEL_PRIMARY_ANCHOR_QUEST_TRACKER
    else
        return style.TOP_LEVEL_PRIMARY_ANCHOR_NO_QUEST_TRACKER
    end
end

function ZoneStoryTracker:GetSecondaryAnchor()
    return self.currentStyle.TOP_LEVEL_SECONDARY_ANCHOR
end

function ZoneStoryTracker:SetHidden(isHidden)
    ZO_HUDTracker_Base.SetHidden(self, isHidden)

    self.iconControl:SetHidden(isHidden)
end

function ZO_ZoneStoryTracker_OnInitialized(control)
    ZONE_STORY_TRACKER = ZoneStoryTracker:New(control)
end