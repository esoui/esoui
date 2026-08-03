-- Leave room for things like really long hotkey bindings and superflous icons
local EXTRA_PADDING = 150
ZO_HUD_TRACKER_MANAGER_WIDTH = ZO_HUD_TRACKER_MAX_WIDTH + ZO_SCROLL_BAR_WIDTH + EXTRA_PADDING
-- A mostly arbitrary height to make sure that it can't go too low with customizable HUD
ZO_HUD_TRACKER_MANAGER_HEIGHT = 350

-- A lower number means it will appear first in the order of top to bottom
ZO_HUD_TRACKER_PRIORITY =
{
    ENDLESS_DUNGEON = 100,
    ADVENTURE_ZONE = 200,
    GENERIC_SELECTOR = 300,
    DYNAMIC_EVENTS = 400,
    QUEST = 500,
    ZONE_STORY = 510, -- Linked to QUEST
    TIMED_ACTIVITY = 600,
    ACHIEVEMENT = 610, -- Linked to TIMED_ACTIVITY
    HOUSE_INFORMATION = 700,
    ACTIVITY = 800,
    READY_CHECK = 810, -- Linked to ACTIVITY
}

ZO_HUD_TRACKER_ASPIRATION = 
{
    START = 0,

    PROMOTIONAL_EVENT = 1,
    TIMED_ACTIVITY = 2,
    ACHIEVEMENT = 3,

    END = 4,
}

local DEFAULT_ANCHOR = ZO_Anchor:New(TOPRIGHT, nil, TOPRIGHT, -2, 10)

ZO_HUDTracker_Manager = ZO_InitializingCallbackObject:Subclass()

function ZO_HUDTracker_Manager:Initialize(control)
    self.control = control
    self.scrollContainer = control:GetNamedChild("ScrollContainer")
    self.scrollControl = self.scrollContainer:GetNamedChild("Scroll")
    self.scrollChild = self.scrollControl:GetNamedChild("Child")

    local function UpdateVisibility()
        self:UpdateVisibility()
    end

    self.trackers = {}

    self.control:RegisterForEvent(EVENT_ZONE_STORY_ACTIVITY_TRACKED, UpdateVisibility)
    self.control:RegisterForEvent(EVENT_ZONE_STORY_ACTIVITY_UNTRACKED, UpdateVisibility)
    self.control:RegisterForEvent(EVENT_ZONE_STORY_ACTIVITY_TRACKING_INIT, UpdateVisibility)

    local function OnAnchorStateChanged()
        self:OnAnchorStateChanged()
    end

    self.control:RegisterForEvent(EVENT_GAMEPAD_USE_KEYBOARD_CHAT_CHANGED, OnAnchorStateChanged)
    CALLBACK_MANAGER:RegisterCallback("GamepadChatSystemStateChanged", OnAnchorStateChanged)
    HUD_MANAGER:RegisterCallback("OffsetsChanged", function(element)
        -- So many controls can affect this that trying to check for optimization is annoying.
        -- If it becomes a per issue we can optimze.
        self:OnAnchorStateChanged()
    end)

    HUD_MANAGER:RegisterCallback("PropagateSettings", function(element)
        -- EVENT_GAMEPAD_PREFERRED_MODE_CHANGED is encompassed in this call
        self:OnAnchorStateChanged()
        self:RefreshLayout()
    end)

    HUD_MANAGER:RegisterCallback("PreLoadSettings", function(element)
        -- Last chance to get elements in the system
        self:InitializeHUDElements()
    end)

    local function UpdatedAssistedAspiration()
        if not self.savedVars then
            -- Don't bother doing anything yet, we'll do it when add-ons finish loading
            return
        end

        self.assistedAspirationDirty = true
        self:FireCallbacks("AssistedAspirationChanged")
    end

    self.control:RegisterForEvent(EVENT_PROMOTIONAL_EVENTS_ACTIVITY_TRACKING_UPDATED, UpdatedAssistedAspiration)
    self.control:RegisterForEvent(EVENT_TIMED_ACTIVITY_TRACKING_UPDATED, UpdatedAssistedAspiration)
    self.control:RegisterForEvent(EVENT_ACHIEVEMENT_TRACKING_UPDATE, UpdatedAssistedAspiration)

    local function OnAddOnsLoaded()
        local DEFAULTS = 
        {
            assistedAspiration = ZO_HUD_TRACKER_ASPIRATION.PROMOTIONAL_EVENT
        }
        self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "ZO_HUDTracker_Manager", DEFAULTS)

        self:InitializeRegisteredTrackers()
        UpdatedAssistedAspiration()
        self:UpdateVisibility()
        self:OnAnchorStateChanged()
    end
    self.control:RegisterForEvent(EVENT_ADD_ONS_LOADED, OnAddOnsLoaded)
    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function()
        self.isFullyLoaded = true
        UpdatedAssistedAspiration()
        self:RefreshLayout()
    end)
end

function ZO_HUDTracker_Manager:InitializeHUDElements()
    --Custom HUD Editor option to choose which elements to split out
    local values = {}
    for _, trackerData in ipairs(self.trackers) do
        local key, displayName, isValid = trackerData.owner:GetHUDElementOptionKeys()
        if key then
            table.insert(values, { key = key, displayName = displayName, isValid = isValid })
        end
    end

    local OPTIONS = 
    {
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.MULTI_SELECT_DROPDOWN,
            name = GetString(SI_HUD_EDITOR_SEPARATED_TRACKERS_OPTION),
            tooltipText = GetString(SI_HUD_EDITOR_SEPARATED_TRACKERS_OPTION_TOOLTIP),
            key = "SeparatedTrackers",
            values = values,
            -- Default all subkeys to false
            defaultValue = false,
            callback = function(element, subKey, oldValue, newValue)
                self:FireCallbacks("SeparatedTrackersUpdated", element, subKey, oldValue, newValue)
                self:RefreshLayout()
            end,
        },
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.BOOLEAN,
            name = GetString(SI_INTERFACE_OPTIONS_SHOW_QUEST_TRACKER),
            tooltipText = GetString(SI_INTERFACE_OPTIONS_SHOW_QUEST_TRACKER_TOOLTIP),
            key = "QuestTrackerVisible",
            defaultValue = function()
                return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_TRACKER)
            end,
            dontSave = true,
            callback = function(element, subKey, oldValue, value)
                if value ~= oldValue then
                    SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_TRACKER, tostring(value))
                end
            end,
        },
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.BOOLEAN,
            name = GetString(SI_INTERFACE_OPTIONS_SHOW_HOUSE_TRACKER),
            tooltipText = GetString(SI_INTERFACE_OPTIONS_SHOW_HOUSE_TRACKER_TOOLTIP),
            key = "HouseInfoVisible",
            defaultValue = function()
                return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_HOUSE_TRACKER)
            end,
            dontSave = true,
            callback = function(element, subKey, oldValue, value)
                if value ~= oldValue then
                    SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_HOUSE_TRACKER, tostring(value))
                end
            end,
        },
    }
    local DEFAULT_CONFIG = nil
    local elementName = GetString(SI_HUD_EDITOR_TRACKERS)
    self.keyboardHUDElement = HUD_MANAGER:RegisterKeyboardElement(self.control, elementName, DEFAULT_CONFIG, OPTIONS)
    self.gamepadHUDElement = HUD_MANAGER:RegisterGamepadElement(self.control, elementName, DEFAULT_CONFIG, OPTIONS)
end

function ZO_HUDTracker_Manager:GetPlatformHUDElement()
    return self:GetHUDElement(IsInGamepadPreferredMode())
end

function ZO_HUDTracker_Manager:GetHUDElement(gamepad)
    return gamepad and self.gamepadHUDElement or self.keyboardHUDElement
end

function ZO_HUDTracker_Manager:UpdateVisibility()
    local isZoneStoryAssisted = IsZoneStoryAssisted()
    
    local FADE_INSTANT_MS = 0
    FOCUSED_QUEST_TRACKER:GetFragment():SetHiddenForReason("TrackingZoneStory", isZoneStoryAssisted, FADE_INSTANT_MS, FADE_INSTANT_MS)
    ZONE_STORY_TRACKER:GetFragment():SetHiddenForReason("NoTrackedZoneStory", not isZoneStoryAssisted, FADE_INSTANT_MS, FADE_INSTANT_MS)

    self:RefreshLayout()
end

do
    local SECONDARY_ANCHOR_POINT =
    {
        GUI = 1,
        GUI_WITH_PADDING = 2,
        GAMEPAD_CHAT = 3,
        GAMEPAD_CHAT_BUBBLE = 4,
    }

    function ZO_HUDTracker_Manager:OnAnchorStateChanged()
        local hudElement = IsInGamepadPreferredMode() and self.gamepadHUDElement or self.keyboardHUDElement
        local lastAnchorPoint = self.secondaryAnchorPoint
        self.secondaryAnchorPoint = SECONDARY_ANCHOR_POINT.GUI_WITH_PADDING
        if not hudElement:IsUsingDefaultAnchor() then
            self.secondaryAnchorPoint = SECONDARY_ANCHOR_POINT.GUI
        elseif not ZO_ChatSystem_ShouldUseKeyboardChatSystem() and GAMEPAD_CHAT_SYSTEM:GetHUDElement():IsUsingDefaultAnchor() then
            if GAMEPAD_CHAT_SYSTEM:IsMinimized() then
                self.secondaryAnchorPoint = SECONDARY_ANCHOR_POINT.GAMEPAD_CHAT_BUBBLE
            else
                self.secondaryAnchorPoint = SECONDARY_ANCHOR_POINT.GAMEPAD_CHAT
            end
        end

        if lastAnchorPoint ~= self.secondaryAnchorPoint then
            self.scrollContainer:ClearAnchors()
            self.scrollContainer:SetAnchor(TOPLEFT)
            if self.secondaryAnchorPoint == SECONDARY_ANCHOR_POINT.GUI then
                self.scrollContainer:SetAnchor(BOTTOM, GuiRoot, BOTTOM, 0, 0, ANCHOR_CONSTRAINS_Y)
            elseif self.secondaryAnchorPoint == SECONDARY_ANCHOR_POINT.GUI_WITH_PADDING then
                self.scrollContainer:SetAnchor(BOTTOM, GuiRoot, BOTTOM, 0, -130, ANCHOR_CONSTRAINS_Y)
            elseif self.secondaryAnchorPoint == SECONDARY_ANCHOR_POINT.GAMEPAD_CHAT then
                self.scrollContainer:SetAnchor(BOTTOM, GAMEPAD_CHAT_SYSTEM.control, TOP, 0, -20, ANCHOR_CONSTRAINS_Y)
            elseif self.secondaryAnchorPoint == SECONDARY_ANCHOR_POINT.GAMEPAD_CHAT_BUBBLE then
                self.scrollContainer:SetAnchor(BOTTOM, GAMEPAD_CHAT_SYSTEM.chatBubble, TOP, 0, -20, ANCHOR_CONSTRAINS_Y)
            end
        end
    end
end

function ZO_HUDTracker_Manager:RefreshLayout()
    if not self.isFullyLoaded then
        -- Wait until activation so eveything else has time to init
        return
    end

    local previousControl = nil
    for _, trackerData in ipairs(self.trackers) do
        local control = trackerData.control
        local owner = trackerData.owner
        local isActive = owner:IsActive()
        control:SetHidden(not isActive)
        local isDetached = owner:IsDetached()
        if isDetached then
            control:SetParent(self.control)
            local parentTracker = owner:GetParentTracker()
            if parentTracker then
                control:SetAnchor(TOPRIGHT, parentTracker.control, BOTTOMRIGHT)
            else
                owner:GetPlatformHUDElement():RevertOffsetModifications()
            end
        else
            control:ClearAnchors()

            if isActive then
                control:SetParent(self.scrollChild)
                if previousControl then
                    control:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT)
                else
                    control:SetAnchor(TOPRIGHT, nil, TOPRIGHT, -2, 10)
                    DEFAULT_ANCHOR:Set(control)
                end
                previousControl = control
            else
                control:SetParent(self.scrollControl)
                DEFAULT_ANCHOR:Set(control)
            end
        end
    end
end

local function GetDataForAspiration(aspiration)
    if aspiration == ZO_HUD_TRACKER_ASPIRATION.PROMOTIONAL_EVENT then
        return TIMED_ACTIVITY_TRACKER:GetTrackedPromotionalEventActivityData()
    elseif aspiration == ZO_HUD_TRACKER_ASPIRATION.TIMED_ACTIVITY then
        return TIMED_ACTIVITY_TRACKER:GetTrackedTimedActivityData()
    else -- ZO_HUD_TRACKER_ASPIRATION.ACHIEVEMENT
        local trackedAchievementId = GetTrackedAchievement()
        return trackedAchievementId > 0 and trackedAchievementId or nil
    end
end

function ZO_HUDTracker_Manager:CycleAssistedAspiration()
    local workingAspiration = self.savedVars.assistedAspiration
    self.assistedAspirationDirty = false
    repeat
        workingAspiration = workingAspiration + 1
        if workingAspiration == ZO_HUD_TRACKER_ASPIRATION.END then
            workingAspiration = ZO_HUD_TRACKER_ASPIRATION.START + 1
        end

        local data = GetDataForAspiration(workingAspiration)
        if data then
            self.savedVars.assistedAspiration = workingAspiration
            self:FireCallbacks("AssistedAspirationChanged")
            break
        end
    until workingAspiration == self.savedVars.assistedAspiration
end

function ZO_HUDTracker_Manager:SetAssistedAspiration(aspiration)
    if self.savedVars.assistedAspiration ~= aspiration then
        self.savedVars.assistedAspiration = aspiration
        self.assistedAspirationDirty = true
        self:FireCallbacks("AssistedAspirationChanged")
    end
end

function ZO_HUDTracker_Manager:GetAssistedAspiration()
    local aspiration = self.savedVars and self.savedVars.assistedAspiration or ZO_HUD_TRACKER_ASPIRATION.PROMOTIONAL_EVENT

    if not (self.assistedAspirationDirty and self.isFullyLoaded) then
        -- Only attempt to clean when everything is ready
        return aspiration
    end

    local data = GetDataForAspiration(aspiration)
    if not data then
        self:CycleAssistedAspiration()
    end

    return self.savedVars.assistedAspiration
end

function ZO_HUDTracker_Manager:BeginAssistInteract()
    self:QueueCycleAssistedAspiration()
end

function ZO_HUDTracker_Manager:QueueCycleAssistedAspiration()
    local delayMs = self.cycledAssistedAsipration and 500 or 200
    self.cycleAspirationCallbackId = zo_callLater(function()
        self:CycleAssistedAspiration()
        self.cycledAssistedAsipration = true
        self:QueueCycleAssistedAspiration()
    end, delayMs)
end

function ZO_HUDTracker_Manager:EndAssistInteract()
    if self.cycleAspirationCallbackId then
        zo_removeCallLater(self.cycleAspirationCallbackId)
        self.cycleAspirationCallbackId = nil
    end

    if not self.cycledAssistedAsipration then
        local isTrackerVisible = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_TRACKER)
        if isTrackerVisible then
            FOCUSED_QUEST_TRACKER:AssistNext()
        end
    end
    self.cycledAssistedAsipration = nil
end

function ZO_HUDTracker_Manager:RegisterTracker(trackerTemplate, trackerControlName)
    local control = CreateControlFromVirtual(trackerControlName, self.scrollControl, trackerTemplate)
    local trackerData =
    {
        template = trackerTemplate,
        controlName = trackerControlName,
        control = control,
        owner = control.owner
    }
    table.insert(self.trackers, trackerData)
end

function ZO_HUDTracker_Manager:InitializeRegisteredTrackers()
    local function SortTrackers(left, right)
        return left.owner:GetPriority() < right.owner:GetPriority()
    end

    table.sort(self.trackers, SortTrackers)
end

function ZO_HUDTracker_Manager.OnControlInitialized(control)
    HUD_TRACKER_MANAGER = ZO_HUDTracker_Manager:New(control)
end