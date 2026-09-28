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

function ActivityTracker:Initialize(control)
    ZO_HUDTracker_Base.Initialize(self, control)

    ACTIVITY_TRACKER_FRAGMENT = self:GetFragment()
end

function ActivityTracker:InitializeStyles()
    self.styles =
    {
        keyboard =
        {
            HUD_ELEMENT_HEIGHT = 115,
        },
        gamepad =
        {
            HUD_ELEMENT_HEIGHT = 195,
        }
    }
    ZO_HUDTracker_Base.InitializeStyles(self)
end

do
    local DISPLAY_NAME = GetString(SI_HUD_EDITOR_ACTIVITY_TRACKER)

    function ActivityTracker:GetHUDElementInfo()
        return DISPLAY_NAME
    end

    function ActivityTracker:GetHUDElementOptionKeys()
        local KEY = "Activity"
        return KEY, DISPLAY_NAME
    end
end

function ActivityTracker:RegisterEvents()
    ZO_HUDTracker_Base.RegisterEvents(self)

    local function Update()
        self:Update()
    end

    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnActivityFinderStatusUpdate", Update)
end

function ActivityTracker:ApplyPlatformStyle(style)
    ZO_HUDTracker_Base.ApplyPlatformStyle(self, style)

    self.hudElementRef:SetHeight(style.HUD_ELEMENT_HEIGHT)
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

    ZO_HUDTracker_Base.Update(self)
end

function ActivityTracker:GetPriority()
    return ZO_HUD_TRACKER_PRIORITY.ACTIVITY
end

function ZO_ActivityTracker_OnInitialized(control)
    ACTIVITY_TRACKER = ActivityTracker:New(control)
end

HUD_TRACKER_MANAGER:RegisterTracker("ZO_ActivityTracker_Template", "ZO_ActivityTracker")