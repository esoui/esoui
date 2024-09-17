----
-- ZO_PromotionalEventTile_Keyboard
----
ZO_PROMOTIONAL_EVENT_TILE_KEYBOARD_DEFAULT_HIGHLIGHT_ANIMATION_PROVIDER = ZO_ReversibleAnimationProvider:New("ShowOnMouseOverLabelAnimation")

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_PromotionalEventTile_Keyboard = ZO_Object.MultiSubclass(ZO_ActionTile_Keyboard, ZO_PromotionalEventTile)

function ZO_PromotionalEventTile_Keyboard:New(...)
    return ZO_PromotionalEventTile.New(self, ...)
end

-- Begin ZO_ActionTile_Keyboard Overrides --

function ZO_PromotionalEventTile_Keyboard:PostInitializePlatform()
    ZO_ActionTile_Keyboard.PostInitializePlatform(self)

    self:SetActionText(GetString(SI_MARKET_ANNOUNCEMENT_PROMOTIONAL_EVENT_ACTION))
    self:SetHighlightAnimationProvider(ZO_PROMOTIONAL_EVENT_TILE_KEYBOARD_DEFAULT_HIGHLIGHT_ANIMATION_PROVIDER)

    local function OnActionButtonMouseEnter()
        self:OnMouseEnter()
    end

    local function OnActionButtonMouseExit()
        self:OnMouseExit()
    end

    self.actionButton:SetHandler("OnMouseEnter", OnActionButtonMouseEnter)
    self.actionButton:SetHandler("OnMouseExit", OnActionButtonMouseExit)
end

function ZO_PromotionalEventTile_Keyboard:OnMouseEnter()
    ZO_ActionTile_Keyboard.OnMouseEnter(self)
    self.isMousedOver = true

    self.actionButton:SetShowingHighlight(self.isMousedOver)
end

function ZO_PromotionalEventTile_Keyboard:OnMouseExit()
    ZO_ActionTile_Keyboard.OnMouseExit(self)
    self.isMousedOver = false

    self.actionButton:SetShowingHighlight(self.isMousedOver)
end

function ZO_PromotionalEventTile_Keyboard:OnMouseUp(button, upInside)
    if self.actionCallback and self:IsActionAvailable() then
        self.actionCallback()
    end
end

-- Globals

function ZO_PromotionalEventTile_Keyboard.OnControlInitialized(control)
    ZO_PROMOTIONAL_EVENT_TILE_KEYBOARD = ZO_PromotionalEventTile_Keyboard:New(control)
end