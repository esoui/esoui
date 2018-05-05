local KEYBOARD_STYLE =
{
    FONT_HEADER = "ZoFontGameShadow",
    FONT_STATUS = "ZoFontGameShadow",
    TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_NONE,

    TOP_LEVEL_PRIMARY_ANCHOR_TO_QUEST_TRACKER = ZO_Anchor:New(TOPLEFT, ZO_FocusedQuestTrackerPanelContainerQuestContainer, BOTTOMLEFT, 0, 10),
    -- The quest timer anchors are very old and bizarre and they screw everything up
    -- So these anchors match what the quest tracker normally does.  If we get the time to redo quest timer/tracker in a not insane way, we should fix this
    -- Everything else should anchor to the bottom of the activity tracker, cause it got all the hard stuff out of the way and made it intuitive from here on
    TOP_LEVEL_PRIMARY_ANCHOR_TO_QUEST_TIMER = ZO_Anchor:New(TOPLEFT, ZO_FocusedQuestTrackerPanelTimerAnchor, BOTTOMLEFT, 35, 10),
    TOP_LEVEL_SECONDARY_ANCHOR = ZO_Anchor:New(RIGHT, GuiRoot, RIGHT, 0, 10, ANCHOR_CONSTRAINS_X),

    CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT),
    CONTAINER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT),

    STATUS_PRIMARY_ANCHOR_OFFSET_Y = 2,
}

local GAMEPAD_STYLE =
{
    FONT_HEADER = "ZoFontGamepadBold27",
    FONT_STATUS = "ZoFontGamepad34",
    TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_UPPERCASE,

    TOP_LEVEL_PRIMARY_ANCHOR_TO_QUEST_TRACKER = ZO_Anchor:New(TOPRIGHT, ZO_FocusedQuestTrackerPanelContainerQuestContainer, BOTTOMRIGHT, 0, 20),
    TOP_LEVEL_PRIMARY_ANCHOR_TO_QUEST_TIMER = ZO_Anchor:New(TOPRIGHT, ZO_FocusedQuestTrackerPanelTimerAnchor, BOTTOMRIGHT, -44, 20),

    CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT),

    STATUS_PRIMARY_ANCHOR_OFFSET_Y = 10,
}

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

local ActivityTracker = ZO_Object:Subclass()

function ActivityTracker:New(...)
    local tracker = ZO_Object.New(self)
    tracker:Initialize(...)
    return tracker
end

function ActivityTracker:Initialize(control)
    self.control = control
    control.owner = self

    self.container = control:GetNamedChild("Container")
    self.headerLabel = self.container:GetNamedChild("Header")
    self.statusLabel = self.container:GetNamedChild("Status")

    local allConstants = { KEYBOARD_STYLE, GAMEPAD_STYLE }
    for _, constants in ipairs(allConstants) do
        constants.HEADER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT)
        constants.STATUS_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.headerLabel, BOTTOMRIGHT, 0, constants.STATUS_PRIMARY_ANCHOR_OFFSET_Y)
    end

    KEYBOARD_STYLE.HEADER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPLEFT)
    KEYBOARD_STYLE.STATUS_SECONDARY_ANCHOR = ZO_Anchor:New(TOPLEFT, self.headerLabel, BOTTOMLEFT, 10, KEYBOARD_STYLE.STATUS_PRIMARY_ANCHOR_OFFSET_Y)

    ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)


    ACTIVITY_TRACKER_FRAGMENT = ZO_HUDFadeSceneFragment:New(self.container)

    self:RegisterEvents()
end

function ActivityTracker:RegisterEvents()
    local function Update()
        self:Update()
    end
    
    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnActivityFinderStatusUpdate", Update)

    local function OnQuestTrackerFragmentStateChanged(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING or newState == SCENE_FRAGMENT_HIDDEN then
            self:RefreshAnchors()
        end
    end

    FOCUSED_QUEST_TRACKER:RegisterCallback("QuestTrackerFragmentStateChange", OnQuestTrackerFragmentStateChanged)
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
        self.headerLabel:SetText(HEADER_MAPPING[activityType])
        self.statusLabel:SetText(GetString("SI_ACTIVITYFINDERSTATUS", GetActivityFinderStatus()))
    end

    self.headerLabel:SetHidden(activityType == nil)
    self.statusLabel:SetHidden(activityType == nil)
    self.activityType = activityType
end

function ActivityTracker:ApplyPlatformStyle(style)
    self.currentStyle = style

    self.headerLabel:SetModifyTextType(style.TEXT_TYPE_HEADER)
    self.headerLabel:SetFont(style.FONT_HEADER)
    if self.activityType then
        self.headerLabel:SetText(HEADER_MAPPING[self.activityType])
    end
    self.statusLabel:SetFont(style.FONT_STATUS)
    
    self:RefreshAnchors()
    
end

function ActivityTracker:RefreshAnchors()
    local style = self.currentStyle

    self.control:ClearAnchors()
    local primaryAnchor = FOCUSED_QUEST_TRACKER_FRAGMENT:IsShowing() and style.TOP_LEVEL_PRIMARY_ANCHOR_TO_QUEST_TRACKER or style.TOP_LEVEL_PRIMARY_ANCHOR_TO_QUEST_TIMER
    primaryAnchor:AddToControl(self.control)
    if style.TOP_LEVEL_SECONDARY_ANCHOR then
        style.TOP_LEVEL_SECONDARY_ANCHOR:AddToControl(self.control)
    end

    self.container:ClearAnchors()
    style.CONTAINER_PRIMARY_ANCHOR:AddToControl(self.container)
    if style.CONTAINER_SECONDARY_ANCHOR then
        style.CONTAINER_SECONDARY_ANCHOR:AddToControl(self.container)
    end

    self.headerLabel:ClearAnchors()
    style.HEADER_PRIMARY_ANCHOR:AddToControl(self.headerLabel)
    if style.HEADER_SECONDARY_ANCHOR then
        style.HEADER_SECONDARY_ANCHOR:AddToControl(self.headerLabel)
    end

    self.statusLabel:ClearAnchors()
    style.STATUS_PRIMARY_ANCHOR:AddToControl(self.statusLabel)
    if style.STATUS_SECONDARY_ANCHOR then
        style.STATUS_SECONDARY_ANCHOR:AddToControl(self.statusLabel)
    end
end

function ZO_ActivityTracker_OnInitialized(control)
    ACTIVITY_TRACKER = ActivityTracker:New(control)
end