local HEADER_MAPPING =
{
    [LFG_ACTIVITY_DUNGEON] = GetString(SI_ACTIVITY_FINDER_CATEGORY_DUNGEON_FINDER),
    [LFG_ACTIVITY_MASTER_DUNGEON] = GetString(SI_ACTIVITY_FINDER_CATEGORY_DUNGEON_FINDER),
    [LFG_ACTIVITY_BATTLE_GROUND_CHAMPION] = GetString(SI_ACTIVITY_FINDER_CATEGORY_BATTLEGROUNDS),
    [LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION] = GetString(SI_ACTIVITY_FINDER_CATEGORY_BATTLEGROUNDS),
    [LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL] = GetString(SI_ACTIVITY_FINDER_CATEGORY_BATTLEGROUNDS),
    [LFG_ACTIVITY_TRIBUTE_COMPETITIVE] = GetString(SI_ACTIVITY_FINDER_CATEGORY_TRIBUTE),
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
            RESIZE_TO_FIT_PADDING_HEIGHT = 10,

            TOP_LEVEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT, ZO_HouseInformationTrackerTopLevel, BOTTOMLEFT),
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

            TOP_LEVEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, ZO_HouseInformationTrackerTopLevel, BOTTOMRIGHT),

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
    return self.currentStyle.TOP_LEVEL_PRIMARY_ANCHOR
end

function ActivityTracker:GetSecondaryAnchor()
    return self.currentStyle.TOP_LEVEL_SECONDARY_ANCHOR
end

function ZO_ActivityTracker_OnInitialized(control)
    ACTIVITY_TRACKER = ActivityTracker:New(control)
end