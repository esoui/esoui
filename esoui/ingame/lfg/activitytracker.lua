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

            TOP_LEVEL_PRIMARY_ANCHOR_TO_ZONE_STORY_TRACKER = ZO_Anchor:New(TOPLEFT, ZO_ZoneStoryTracker, BOTTOMLEFT, 0, 10),
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

            TOP_LEVEL_PRIMARY_ANCHOR_TO_ZONE_STORY_TRACKER = ZO_Anchor:New(TOPRIGHT, ZO_ZoneStoryTracker, BOTTOMRIGHT, 0, 20),

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

    self:RefreshAnchors()
end

function ActivityTracker:GetPrimaryAnchor()
    return self.currentStyle.TOP_LEVEL_PRIMARY_ANCHOR_TO_ZONE_STORY_TRACKER
end

function ActivityTracker:GetSecondaryAnchor()
    return self.currentStyle.TOP_LEVEL_SECONDARY_ANCHOR
end

function ZO_ActivityTracker_OnInitialized(control)
    ACTIVITY_TRACKER = ActivityTracker:New(control)
end