ZO_EndlessDungeonHUDTracker = ZO_HUDTracker_Base:Subclass()

function ZO_EndlessDungeonHUDTracker:Initialize(...)
    ZO_HUDTracker_Base.Initialize(self, ...)

    self:SetHeaderText(GetString(SI_ENDLESS_DUNGEON_HUD_TRACKER_TITLE))

    local fragment = self:GetFragment()
    ENDLESS_DUNGEON_HUD_TRACKER_FRAGMENT = fragment
    fragment:SetHiddenForReason("InactiveDungeon", true)

    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, ZO_GetEventForwardingFunction(self, self.Update))

    local function OnAddOnLoaded(_, name)
        if name == "ZO_Ingame" then
            if ENDLESS_DUNGEON_MANAGER:IsEndlessDungeonStarted() then
                self:UpdateProgress()
            end
            EVENT_MANAGER:UnregisterForEvent("ZO_EndlessDungeonHUDTracker", EVENT_ADD_ON_LOADED)
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_EndlessDungeonHUDTracker", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end

function ZO_EndlessDungeonHUDTracker:DeferredInitialize(...)
    self.showBuffTrackerKeybindDescriptor =
    {
        -- Even though this is an ethereal keybind, the name will still be read during screen narration
        keybind = "TOGGLE_ACTIVITY_HUD_TRACKER",
        ethereal = true,
        narrateEthereal = true,
        etherealNarrationOrder = 1,
        callback = function()
            SYSTEMS:ShowScene("endlessDungeonBuffTracker")
        end,
        visible = function()
            return ENDLESS_DUNGEON_MANAGER:IsEndlessDungeonStarted()
        end,
    }
    self.showBuffTrackerKeybindButton = self.container:GetNamedChild("ShowBuffTracker")
    self.showBuffTrackerKeybindButton:SetKeybindButtonDescriptor(self.showBuffTrackerKeybindDescriptor)

    ZO_HUDTracker_Base.DeferredInitialize(self, ...)
end

do
    local DISPLAY_NAME = GetString(SI_ENDLESS_DUNGEON_HUD_TRACKER_TITLE)

    function ZO_EndlessDungeonHUDTracker:GetHUDElementInfo()
        return DISPLAY_NAME
    end

    function ZO_EndlessDungeonHUDTracker:GetHUDElementOptionKeys()
        local KEY = "Infinite"
        return KEY, DISPLAY_NAME
    end
end

function ZO_EndlessDungeonHUDTracker:ApplyPlatformStyle(style)
    ZO_HUDTracker_Base.ApplyPlatformStyle(self, style)

    ApplyTemplateToControl(self.showBuffTrackerKeybindButton, ZO_GetPlatformTemplate("ZO_KeybindButton"))
end

function ZO_EndlessDungeonHUDTracker:OnDungeonStateChanged(newState, oldState)
    self:Update()
end

function ZO_EndlessDungeonHUDTracker:OnHiding()
    ZO_HUDTracker_Base.OnHiding(self)

    KEYBIND_STRIP:RemoveKeybindButton(self.showBuffTrackerKeybindDescriptor)
end

function ZO_EndlessDungeonHUDTracker:OnShown()
    ZO_HUDTracker_Base.OnShown(self)

    KEYBIND_STRIP:AddKeybindButton(self.showBuffTrackerKeybindDescriptor)
    self:RefreshAnchors()
end

function ZO_EndlessDungeonHUDTracker:RegisterEvents(...)
    ZO_HUDTracker_Base.RegisterEvents(self, ...)

    ENDLESS_DUNGEON_MANAGER:RegisterCallback("StateChanged", self.OnDungeonStateChanged, self)
    ENDLESS_DUNGEON_MANAGER:RegisterCallback("DungeonInitialized", self.UpdateProgress, self)
end

function ZO_EndlessDungeonHUDTracker:Update()
    local hidden = not ENDLESS_DUNGEON_MANAGER:IsEndlessDungeonStarted()
    self:GetFragment():SetHiddenForReason("InactiveDungeon", hidden, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)

    ZO_HUDTracker_Base.Update(self)
end

function ZO_EndlessDungeonHUDTracker:UpdateProgress()
    if ENDLESS_DUNGEON_MANAGER:IsEndlessDungeonStarted() then
        local USE_THICK_OUTLINE = true
        self.subLabel:SetText(ENDLESS_DUNGEON_MANAGER:GetCurrentProgressionText(USE_THICK_OUTLINE))
    else
        self.subLabel:SetText("")
    end
end

function ZO_EndlessDungeonHUDTracker:GetPriority()
    return ZO_HUD_TRACKER_PRIORITY.ENDLESS_DUNGEON
end

function ZO_EndlessDungeonHUDTracker.OnInitialized(control)
    ENDLESS_DUNGEON_HUD_TRACKER = ZO_EndlessDungeonHUDTracker:New(control)
end

HUD_TRACKER_MANAGER:RegisterTracker("ZO_EndDunHUDTracker_Template", "ZO_EndDunHUDTracker")