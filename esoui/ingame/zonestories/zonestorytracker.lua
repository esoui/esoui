local ZoneStoryTracker = ZO_HUDTracker_Base:Subclass()

function ZoneStoryTracker:Initialize(control)
    ZO_HUDTracker_Base.Initialize(self, control)

    self.iconControl = self.container:GetNamedChild("Icon")
    self.assistedKeybindButton = self.container:GetNamedChild("Assisted")

    ZONE_STORY_TRACKER_FRAGMENT = self:GetFragment()
end

function ZoneStoryTracker:InitializeStyles()
    self.styles =
    {
        gamepad =
        {
            SUBLABEL_PRIMARY_ANCHOR_OFFSET_Y = 12,
        }
    }
    ZO_HUDTracker_Base.InitializeStyles(self)
end

function ZoneStoryTracker:GetHUDElementInfo()
    local DISPLAY_NAME = nil -- Will be controlled by FocusedQuestTracker
    return DISPLAY_NAME
end

function ZoneStoryTracker:GetHUDElementOptionKeys()
    local KEY = nil -- Will be controlled by FocusedQuestTracker
    return KEY
end

function ZoneStoryTracker:GetParentTracker()
    return FOCUSED_QUEST_TRACKER
end

function ZoneStoryTracker:RegisterEvents()
    ZO_HUDTracker_Base.RegisterEvents(self)

    local function Update()
        self:Update()
    end

    self.control:RegisterForEvent(EVENT_ZONE_STORY_ACTIVITY_TRACKED, Update)
    self.control:RegisterForEvent(EVENT_ZONE_STORY_ACTIVITY_UNTRACKED, Update)
    self.control:RegisterForEvent(EVENT_ZONE_STORY_ACTIVITY_TRACKING_INIT, Update)
    
    local function OnInterfaceSettingChanged(eventCode, settingType, settingId)
        if settingType == SETTING_TYPE_UI and settingId == UI_SETTING_SHOW_QUEST_TRACKER then
            self:UpdateAssistedKeybind()
        end
    end

    self.control:RegisterForEvent(EVENT_INTERFACE_SETTING_CHANGED, OnInterfaceSettingChanged)
    
    local function UpdateAssistedKeybind()
        self:UpdateAssistedKeybind()
    end

    self.control:RegisterForEvent(EVENT_QUEST_ADDED, UpdateAssistedKeybind)
    self.control:RegisterForEvent(EVENT_QUEST_REMOVED, UpdateAssistedKeybind)
end

function ZoneStoryTracker:Update()
    local zoneId, completionType, activityId = GetTrackedZoneStoryActivityInfo()
    if zoneId ~= 0 then
        local data = ZONE_STORIES_MANAGER:GetZoneData(zoneId)
        local subLabelText = GetZoneStoryShortDescriptionByActivityId(zoneId, completionType, activityId)

        self:SetHeaderText(ZO_CachedStrFormat(SI_ZONE_STORY_TRACKER_TITLE, data.name))
        self:SetSubLabelText(subLabelText)

        self:UpdateAssistedKeybind()
    end

    ZO_HUDTracker_Base.Update(self)
end

function ZoneStoryTracker:UpdateAssistedKeybind()
    local showAssistedKeybind = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_TRACKER) and FOCUSED_QUEST_TRACKER:GetNumTracked() > 0
    self.assistedKeybindButton:SetHidden(not showAssistedKeybind)
end

function ZoneStoryTracker:ApplyPlatformStyle(style)
    ZO_HUDTracker_Base.ApplyPlatformStyle(self, style)

    ApplyTemplateToControl(self.assistedKeybindButton, ZO_GetPlatformTemplate("ZO_KeybindButton"))
end

function ZoneStoryTracker:GetPriority()
    return ZO_HUD_TRACKER_PRIORITY.ZONE_STORY
end

function ZO_ZoneStoryTracker_OnInitialized(control)
    ZONE_STORY_TRACKER = ZoneStoryTracker:New(control)
end

HUD_TRACKER_MANAGER:RegisterTracker("ZO_ZoneStoryTracker_Template", "ZO_ZoneStoryTracker")