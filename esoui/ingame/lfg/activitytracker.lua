local KEYBOARD_STYLE =
{
    FONT_HEADER = "ZoFontGameShadow",
    FONT_STATUS = "ZoFontGameShadow",
    TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_NONE,

    HEADER_PRIMARY_ANCHOR_OFFSET_Y = 10,
    STATUS_PRIMARY_ANCHOR_OFFSET_Y = 2,
}

local GAMEPAD_STYLE =
{
    FONT_HEADER = "ZoFontGamepadBold27",
    FONT_STATUS = "ZoFontGamepad34",
    TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_UPPERCASE,

    HEADER_PRIMARY_ANCHOR_OFFSET_Y = 20,
    STATUS_PRIMARY_ANCHOR_OFFSET_Y = 16,
}

local HEADER_MAPPING =
{
    [LFG_ACTIVITY_DUNGEON] = GetString(SI_ACTIVITY_FINDER_CATEGORY_DUNGEON_FINDER),
    [LFG_ACTIVITY_MASTER_DUNGEON] = GetString(SI_ACTIVITY_FINDER_CATEGORY_DUNGEON_FINDER),
    [LFG_ACTIVITY_AVA] = GetString(SI_ACTIVITY_FINDER_CATEGORY_ALLIANCE_WAR),
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

    local container = control:GetNamedChild("Container")
    self.headerLabel = container:GetNamedChild("Header")
    self.statusLabel = container:GetNamedChild("Status")

    local allConstants = { KEYBOARD_STYLE, GAMEPAD_STYLE }
    for _, constants in ipairs(allConstants) do
        constants.HEADER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, container, TOPRIGHT, 0, constants.HEADER_PRIMARY_ANCHOR_OFFSET_Y)
        constants.STATUS_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.headerLabel, BOTTOMRIGHT, 0, constants.STATUS_PRIMARY_ANCHOR_OFFSET_Y)
    end

    local questTrackerContainerControl = GetControl("ZO_FocusedQuestTrackerPanelContainerQuestContainer")
    KEYBOARD_STYLE.HEADER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPLEFT, questTrackerContainerControl, BOTTOMLEFT, 0, 10)
    KEYBOARD_STYLE.STATUS_SECONDARY_ANCHOR = ZO_Anchor:New(TOPLEFT, self.headerLabel, BOTTOMLEFT, 10, 2)

    ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)

    self.container = container

    ACTIVITY_TRACKER_FRAGMENT = ZO_HUDFadeSceneFragment:New(control)

    self:RegisterEvents()
end

function ActivityTracker:RegisterEvents()
    local function Update()
        self:Update()
    end

    ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnActivityFinderStatusUpdate", Update)
end

function ActivityTracker:Update()
    local activityType
    if IsCurrentlySearchingForGroup() then
        activityType = GetLFGRequestInfo(1)
    elseif IsInLFGGroup() then
        activityType = GetCurrentLFGActivity()
    end
    if activityType then
        self.headerLabel:SetText(HEADER_MAPPING[activityType])
        self.statusLabel:SetText(GetString("SI_ACTIVITYFINDERSTATUS", GetActivityFinderStatus()))
    end
    self.container:SetHidden(activityType == nil)
    self.activityType = activityType
end

function ActivityTracker:ApplyPlatformStyle(style)
    self.headerLabel:SetModifyTextType(style.TEXT_TYPE_HEADER)
    self.headerLabel:SetFont(style.FONT_HEADER)
    if self.activityType then
        self.headerLabel:SetText(HEADER_MAPPING[self.activityType])
    end
    self.statusLabel:SetFont(style.FONT_STATUS)

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