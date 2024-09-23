ZO_EndlessDungeonHUDTracker = ZO_HUDTracker_Base:Subclass()

function ZO_EndlessDungeonHUDTracker:Initialize(...)
    ZO_HUDTracker_Base.Initialize(self, ...)

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
        keybind = "TOGGLE_ENDLESS_DUNGEON_BUFF_TRACKER",
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
    self:Update()
end

function ZO_EndlessDungeonHUDTracker:InitializeStyles()
    -- Intentional override of ZO_HUDTracker_Base behavior.

    self.styles =
    {
        keyboard =
        {
            CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT),
            CONTAINER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT),
            CONTAINER_RESIZE_TO_FIT_PADDING = {0, 20},
            FONT_HEADER = "ZoFontGameShadow",
            FONT_SUBLABEL = "ZoFontGameShadow",
            RESIZE_TO_FIT_PADDING_HEIGHT = 10,
            HEADER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT, self.container),
            HEADER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.container),
            KEYBIND_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.headerLabel, TOPLEFT, 0, -7),
            KEYBIND_BUTTON_TEMPLATE = "ZO_KeybindButton_Keyboard_Template",
            SUBLABEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT, self.headerLabel, BOTTOMLEFT, 10, 2),
            SUBLABEL_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.headerLabel, BOTTOMRIGHT, 0, 2),
            TEXT_HORIZONTAL_ALIGNMENT = TEXT_ALIGN_LEFT,
            TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_NONE,
            TOP_LEVEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT, GuiRoot, TOPRIGHT, -230, 90),
            TOP_LEVEL_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, GuiRoot, nil, 0, 90),
        },
        gamepad =
        {
            CONTAINER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT),
            CONTAINER_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, nil, nil, -15, 0),
            CONTAINER_RESIZE_TO_FIT_PADDING = {0, 30},
            FONT_HEADER = "ZoFontGamepadBold27",
            FONT_SUBLABEL = "ZoFontGamepad34",
            RESIZE_TO_FIT_PADDING_HEIGHT = 20,
            HEADER_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.container),
            KEYBIND_ANCHOR = ZO_Anchor:New(RIGHT, self.headerLabel, LEFT, -5, 5),
            KEYBIND_BUTTON_TEMPLATE = "ZO_KeybindButton_Gamepad_Template",
            SUBLABEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, self.headerLabel, BOTTOMRIGHT, 0, 10),
            TEXT_HORIZONTAL_ALIGNMENT = TEXT_ALIGN_RIGHT,
            TEXT_TYPE_HEADER = MODIFY_TEXT_TYPE_UPPERCASE,
            TOP_LEVEL_PRIMARY_ANCHOR = ZO_Anchor:New(TOPLEFT, GuiRoot, TOPRIGHT, -275, 0),
            TOP_LEVEL_SECONDARY_ANCHOR = ZO_Anchor:New(TOPRIGHT, GuiRoot, nil, 0, 100),
        },
    }

    self.platformStyle = ZO_PlatformStyle:New(function(style)
        self:ApplyPlatformStyle(style)
    end, self.styles.keyboard, self.styles.gamepad)

    self.platformStyle:Apply()
end

function ZO_EndlessDungeonHUDTracker:ApplyPlatformStyle(style)
    ZO_HUDTracker_Base.ApplyPlatformStyle(self, style)

    self.container:SetResizeToFitPadding(unpack(style.CONTAINER_RESIZE_TO_FIT_PADDING))

    -- Order matters:
    self.headerLabel:SetHorizontalAlignment(style.TEXT_HORIZONTAL_ALIGNMENT)
    self.headerLabel:SetText(GetString(SI_ENDLESS_DUNGEON_HUD_TRACKER_TITLE))
    self.showBuffTrackerKeybindButton:ClearAnchors()
    style.KEYBIND_ANCHOR:AddToControl(self.showBuffTrackerKeybindButton)
    ApplyTemplateToControl(self.showBuffTrackerKeybindButton, style.KEYBIND_BUTTON_TEMPLATE)
end

function ZO_EndlessDungeonHUDTracker:GetPrimaryAnchor()
    return self.currentStyle.TOP_LEVEL_PRIMARY_ANCHOR
end

function ZO_EndlessDungeonHUDTracker:GetSecondaryAnchor()
    return self.currentStyle.TOP_LEVEL_SECONDARY_ANCHOR
end

function ZO_EndlessDungeonHUDTracker:OnDungeonStateChanged(newState, oldState)
    self:Update()
end

function ZO_EndlessDungeonHUDTracker:OnHiding()
    KEYBIND_STRIP:RemoveKeybindButton(self.showBuffTrackerKeybindDescriptor)
end

function ZO_EndlessDungeonHUDTracker:OnShown()
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
    return true
end

function ZO_EndlessDungeonHUDTracker:UpdateProgress()
    if ENDLESS_DUNGEON_MANAGER:IsEndlessDungeonStarted() then
        local USE_THICK_OUTLINE = true
        self.subLabel:SetText(ENDLESS_DUNGEON_MANAGER:GetCurrentProgressionText(USE_THICK_OUTLINE))
    else
        self.subLabel:SetText("")
    end
end

function ZO_EndlessDungeonHUDTracker.OnInitialized(control)
    ENDLESS_DUNGEON_HUD_TRACKER = ZO_EndlessDungeonHUDTracker:New(control)
end