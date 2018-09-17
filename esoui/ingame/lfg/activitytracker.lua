local HEADER_MAPPING =
{
    [LFG_ACTIVITY_DUNGEON] = GetString(SI_ACTIVITY_FINDER_CATEGORY_DUNGEON_FINDER),
    [LFG_ACTIVITY_MASTER_DUNGEON] = GetString(SI_ACTIVITY_FINDER_CATEGORY_DUNGEON_FINDER),
    [LFG_ACTIVITY_AVA] = GetString(SI_ACTIVITY_FINDER_CATEGORY_ALLIANCE_WAR),
    [LFG_ACTIVITY_BATTLE_GROUND_CHAMPION] = GetString(SI_ACTIVITY_FINDER_CATEGORY_BATTLEGROUNDS),
    [LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION] = GetString(SI_ACTIVITY_FINDER_CATEGORY_BATTLEGROUNDS),
    [LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL] = GetString(SI_ACTIVITY_FINDER_CATEGORY_BATTLEGROUNDS),
}

------------------
--Initialization--
------------------

local ActivityTracker = ZO_HUDTracker_Base:Subclass()

function ActivityTracker:New(...)
    return ZO_HUDTracker_Base.New(self, ...)
end

function ActivityTracker:Initialize(control)
    ZO_HUDTracker_Base.Initialize(self, control)

    ACTIVITY_TRACKER_FRAGMENT = self:GetFragment()
end

function ActivityTracker:InitializeStyles()
    self.styles =
    {
        keyboard =
        {
            FONT_HEADER = "ZoFontGameShadow",
            FONT_SUBLABEL = "ZoFontGameShadow",
            TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_NONE,

            TOP_LEVEL_PRIMARY_ANCHOR_TO_QUEST_TRACKER = ZO_Anchor:New(TOPLEFT, ZO_FocusedQuestTrackerPanelContainerQuestContainer, BOTTOMLEFT, 0, 10),
            -- The quest timer anchors are very old and bizarre and they screw everything up
            -- So these anchors match what the quest tracker normally does.  If we get the time to redo quest timer/tracker in a not insane way, we should fix this
            -- Everything else should anchor to the bottom of the activity tracker, cause it got all the hard stuff out of the way and made it intuitive from here on
            TOP_LEVEL_PRIMARY_ANCHOR_TO_QUEST_TIMER = ZO_Anchor:New(TOPLEFT, ZO_FocusedQuestTrackerPanelTimerAnchor, BOTTOMLEFT, 35, 10),
            TOP_LEVEL_SECONDARY_ANCHOR = ZO_Anchor:New(RIGHT, GuiRoot, RIGHT, 0, 10, ANCHOR_CONSTRAINS_X),

            CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT),
            CONTAINER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT),

            SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y = 2,
        },
        gamepad =
        {
            FONT_HEADER = "ZoFontGamepadBold27",
            FONT_SUBLABEL = "ZoFontGamepad34",
            TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_UPPERCASE,

            TOP_LEVEL_PRIMARY_ANCHOR_TO_QUEST_TRACKER = ZO_Anchor:New(TOPRIGHT, ZO_FocusedQuestTrackerPanelContainerQuestContainer, BOTTOMRIGHT, 0, 20),
            TOP_LEVEL_PRIMARY_ANCHOR_TO_QUEST_TIMER = ZO_Anchor:New(TOPRIGHT, ZO_FocusedQuestTrackerPanelTimerAnchor, BOTTOMRIGHT, -44, 20),

            CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT),

            SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y = 10,
        }
    }
    ZO_HUDTracker_Base.InitializeStyles(self)
end

function ActivityTracker:RegisterEvents()
    ZO_HUDTracker_Base.RegisterEvents(self)

    local function Update()
        self:Update()
    end

    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnActivityFinderStatusUpdate", Update)
end

function ActivityTracker:Update()
    local activityId = 0
    local activityType

    if IsCurrentlySearchingForGroup() then
        activityId = GetActivityRequestIds(1)
    elseif IsInLFGGroup() then
        activityId = GetCurrentLFGActivityId()
    end

    if activityId > 0 then
        activityType = GetActivityType(activityId)
        self:SetHeaderText(HEADER_MAPPING[activityType])
        self:SetSubLabelText(GetString("SI_ACTIVITYFINDERSTATUS", GetActivityFinderStatus()))
    end

    local fragment = self:GetFragment()
    if fragment then
        fragment:SetHiddenForReason("NoTrackedActivity", activityType == nil, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)
    end
    self.activityType = activityType
end

function ActivityTracker:OnShowing()
    self:FireCallbacks("OnActivityTrackerUpdated")
end

function ActivityTracker:GetPrimaryAnchor()
    local style = self.currentStyle
    if FOCUSED_QUEST_TRACKER_FRAGMENT:IsShowing() then
        return style.TOP_LEVEL_PRIMARY_ANCHOR_TO_QUEST_TRACKER
    else
        return style.TOP_LEVEL_PRIMARY_ANCHOR_TO_QUEST_TIMER
    end
end

function ActivityTracker:GetSecondaryAnchor()
    return self.currentStyle.TOP_LEVEL_SECONDARY_ANCHOR
end

function ZO_ActivityTracker_OnInitialized(control)
    ACTIVITY_TRACKER = ActivityTracker:New(control)
end