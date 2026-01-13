----------------------------------------
-- Adventure Zone Event Tile Keyboard --
----------------------------------------

ZO_AdventureZoneEventTile_Keyboard = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Keyboard, ZO_AdventureZoneEventTile_Shared)

function ZO_AdventureZoneEventTile_Keyboard:New(...)
    return ZO_AdventureZoneEventTile_Shared.New(self, ...)
end

function ZO_AdventureZoneEventTile_Keyboard:OnMouseEnter()
    ZO_ContextualActionsTile_Keyboard.OnMouseEnter(self)

    ADVENTURE_ZONE_OVERVIEW_KEYBOARD:SetSelectedEvent(self.control.eventIndex)
    ADVENTURE_ZONE_OVERVIEW_KEYBOARD:UpdateKeybinds()
end

function ZO_AdventureZoneEventTile_Keyboard:OnMouseExit()
    ZO_ContextualActionsTile_Keyboard.OnMouseExit(self)

    ADVENTURE_ZONE_OVERVIEW_KEYBOARD:SetSelectedEvent(nil)
    ADVENTURE_ZONE_OVERVIEW_KEYBOARD:UpdateKeybinds()
end

--------------------------------------
-- Adventure Zone Overview Keyboard --
--------------------------------------

ZO_AdventureZoneOverview_Keyboard = ZO_AdventureZoneOverview_Shared:Subclass()

function ZO_AdventureZoneOverview_Keyboard:Initialize(...)
    ZO_AdventureZoneOverview_Shared.Initialize(self, ...)

    local scene = self:GetScene()
    ADVENTURE_ZONE_OVERVIEW_SCENE_KEYBOARD = scene
    SYSTEMS:RegisterKeyboardRootScene("adventureZoneOverview", scene)
end

function ZO_AdventureZoneOverview_Keyboard:GetSceneName()
    return "adventureZoneOverviewKeyboard"
end

function ZO_AdventureZoneOverview_Keyboard:SetSelectedEvent(eventIndex)
    self.selectedEvent = eventIndex
end

function ZO_AdventureZoneOverview_Keyboard.OnControlInitialized(control)
    ADVENTURE_ZONE_OVERVIEW_KEYBOARD = ZO_AdventureZoneOverview_Keyboard:New(control)
end