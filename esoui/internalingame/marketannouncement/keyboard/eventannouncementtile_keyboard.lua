----
-- ZO_EventAnnouncementTile_Keyboard
----
ZO_EVENT_ANNOUNCEMENT_TILE_KEYBOARD_DEFAULT_HIGHLIGHT_ANIMATION_PROVIDER = ZO_ReversibleAnimationProvider:New("ShowOnMouseOverLabelAnimation")

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_EventAnnouncementTile_Keyboard = ZO_Object.MultiSubclass(ZO_ActionTile_Keyboard, ZO_EventAnnouncementTile)

function ZO_EventAnnouncementTile_Keyboard:New(...)
    return ZO_EventAnnouncementTile.New(self, ...)
end

-- Begin ZO_ActionTile_Keyboard Overrides --

function ZO_EventAnnouncementTile_Keyboard:PostInitializePlatform()
    ZO_ActionTile_Keyboard.PostInitializePlatform(self)

    self:SetActionText(GetString(SI_EVENT_ANNOUNCEMENT_ACTION))
    self:SetHighlightAnimationProvider(ZO_EVENT_ANNOUNCEMENT_TILE_KEYBOARD_DEFAULT_HIGHLIGHT_ANIMATION_PROVIDER)

    local function OnActionButtonMouseEnter()
        self:OnMouseEnter()
    end

    local function OnActionButtonMouseExit()
        self:OnMouseExit()
    end

    self.actionButton:SetHandler("OnMouseEnter", OnActionButtonMouseEnter)
    self.actionButton:SetHandler("OnMouseExit", OnActionButtonMouseExit)
end

function ZO_EventAnnouncementTile_Keyboard:Layout(data)
    ZO_EventAnnouncementTile.Layout(self, data)

    self:SetActionCallback(function()
        if self.data.marketProductId ~= 0 then
            ZO_KEYBOARD_MARKET_ANNOUNCEMENT:DoOpenMarketBehaviorForMarketProductId(self.data.marketProductId)
        else
            SYSTEMS:GetObject(ZO_MARKET_NAME):RequestShowMarket(MARKET_OPEN_OPERATION_ANNOUNCEMENT, OPEN_MARKET_BEHAVIOR_SHOW_FEATURED_CATEGORY)
        end
    end)
end

function ZO_EventAnnouncementTile_Keyboard:OnMouseEnter()
    ZO_ActionTile_Keyboard.OnMouseEnter(self)
    self.isMousedOver = true

    self.actionButton:SetShowingHighlight(self.isMousedOver)
end

function ZO_EventAnnouncementTile_Keyboard:OnMouseExit()
    ZO_ActionTile_Keyboard.OnMouseExit(self)
    self.isMousedOver = false

    self.actionButton:SetShowingHighlight(self.isMousedOver)
end

function ZO_EventAnnouncementTile_Keyboard:OnMouseUp(button, upInside)
    if self.actionCallback and self:IsActionAvailable() then
        self.actionCallback()
    end
end

-- Globals

function ZO_EventAnnouncementTile_Keyboard_OnInitialized(control)
    ZO_EventAnnouncementTile_Keyboard:New(control)
end