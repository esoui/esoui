----
-- ZO_ZoneStoriesTile_Keyboard
----
ZO_ZONE_STORIES_TILE_KEYBOARD_DEFAULT_HIGHLIGHT_ANIMATION_PROVIDER = ZO_ReversibleAnimationProvider:New("ShowOnMouseOverLabelAnimation")

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_ZoneStoriesTile_Keyboard = ZO_Object.MultiSubclass(ZO_ActionTile_Keyboard, ZO_ZoneStoriesTile)

function ZO_ZoneStoriesTile_Keyboard:New(...)
    return ZO_ZoneStoriesTile.New(self, ...)
end

-- Begin ZO_ActionTile_Keyboard Overrides --

function ZO_ZoneStoriesTile_Keyboard:PostInitializePlatform()
    ZO_ActionTile_Keyboard.PostInitializePlatform(self)

    self:SetHeaderText(GetString(SI_ZONE_STORY_INFO_HEADER))
    self:SetActionText(GetString(SI_MARKET_ANNOUNCEMENT_ACTIVITY_FINDER_ACTION))
    self:SetHighlightAnimationProvider(ZO_ZONE_STORIES_TILE_KEYBOARD_DEFAULT_HIGHLIGHT_ANIMATION_PROVIDER)

    local function OnActionButtonMouseEnter()
        self:OnMouseEnter()
    end

    local function OnActionButtonMouseExit()
        self:OnMouseExit()
    end

    self.actionButton:SetHandler("OnMouseEnter", OnActionButtonMouseEnter)
    self.actionButton:SetHandler("OnMouseExit", OnActionButtonMouseExit)
end

function ZO_ZoneStoriesTile_Keyboard:OnMouseEnter()
    ZO_ActionTile_Keyboard.OnMouseEnter(self)
    self.isMousedOver = true

    self.actionButton:SetShowingHighlight(self.isMousedOver)
end

function ZO_ZoneStoriesTile_Keyboard:OnMouseExit()
    ZO_ActionTile_Keyboard.OnMouseExit(self)
    self.isMousedOver = false

    self.actionButton:SetShowingHighlight(self.isMousedOver)
end

function ZO_ZoneStoriesTile_Keyboard:OnMouseUp(button, upInside)
    if self.actionCallback and self:IsActionAvailable() then
        self.actionCallback()
    end
end

-- Globals

function ZO_ZoneStoriesTile_Keyboard_OnInitialized(control)
    ZO_ZoneStoriesTile_Keyboard:New(control)
end