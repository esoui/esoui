ZO_GenericSelectorHUDTracker = ZO_HUDTracker_Base:Subclass()

function ZO_GenericSelectorHUDTracker:Initialize(...)
    ZO_HUDTracker_Base.Initialize(self, ...)

    local fragment = self:GetFragment()
    GENERIC_SELECTOR_HUD_TRACKER_FRAGMENT = fragment
    fragment:SetHiddenForReason("GenericSelectorEditableOrUnavailable", true)

    self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, ZO_GetEventForwardingFunction(self, self.Update))
end

function ZO_GenericSelectorHUDTracker:DeferredInitialize(...)
    self.viewGenericSelectionMenuKeybindDescriptor =
    {
        -- Even though this is an ethereal keybind, the name will still be read during screen narration
        keybind = "TOGGLE_ACTIVITY_HUD_TRACKER",
        ethereal = true,
        narrateEthereal = true,
        etherealNarrationOrder = 1,
        callback = function()
            SYSTEMS:ShowScene("genericSelector")
        end,
        visible = function()
            return IsViewGenericSelectionMenuAvailable()
        end,
    }
    self.viewGenericSelectionMenuKeybindButton = self.container:GetNamedChild("ViewGenericSelectionMenu")
    self.viewGenericSelectionMenuKeybindButton:SetKeybindButtonDescriptor(self.viewGenericSelectionMenuKeybindDescriptor)

    ZO_HUDTracker_Base.DeferredInitialize(self, ...)
end

do
    local DISPLAY_NAME = GetString(SI_GENERIC_SELECTOR_HUD_TRACKER_TITLE)

    function ZO_GenericSelectorHUDTracker:GetHUDElementInfo()
        return DISPLAY_NAME
    end

    function ZO_GenericSelectorHUDTracker:GetHUDElementOptionKeys()
        local KEY = "Generic"
        return KEY, DISPLAY_NAME
    end
end

function ZO_GenericSelectorHUDTracker:ApplyPlatformStyle(style)
    ZO_HUDTracker_Base.ApplyPlatformStyle(self, style)

    ApplyTemplateToControl(self.viewGenericSelectionMenuKeybindButton, ZO_GetPlatformTemplate("ZO_KeybindButton"))
end

function ZO_GenericSelectorHUDTracker:OnHiding()
    ZO_HUDTracker_Base.OnHiding(self)

    KEYBIND_STRIP:RemoveKeybindButton(self.viewGenericSelectionMenuKeybindDescriptor)
end

function ZO_GenericSelectorHUDTracker:OnShown()
    ZO_HUDTracker_Base.OnShown(self)

    KEYBIND_STRIP:AddKeybindButton(self.viewGenericSelectionMenuKeybindDescriptor)
    self:RefreshAnchors()
end

function ZO_GenericSelectorHUDTracker:Update()
    local hidden = not IsViewGenericSelectionMenuAvailable()
    self:GetFragment():SetHiddenForReason("GenericSelectorEditableOrUnavailable", hidden, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)

    ZO_HUDTracker_Base.Update(self)
end

function ZO_GenericSelectorHUDTracker:GetPriority()
    return ZO_HUD_TRACKER_PRIORITY.GENERIC_SELECTOR
end

function ZO_GenericSelectorHUDTracker.OnInitialized(control)
    GENERIC_SELECTOR_HUD_TRACKER = ZO_GenericSelectorHUDTracker:New(control)
end

HUD_TRACKER_MANAGER:RegisterTracker("ZO_GenericSelectorHUDTracker_Template", "ZO_GenSelectHUDTracker")