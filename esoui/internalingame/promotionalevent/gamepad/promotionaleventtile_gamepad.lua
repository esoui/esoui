----
-- ZO_PromotionalEventTile_Gamepad
----

local HEADER_TEXT_COLORS =
{
    SELECTED_TEXT_COLOR = ZO_NORMAL_TEXT,
    UNSELECTED_TEXT_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_GAMEPAD_CATEGORY_HEADER))
}

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_PromotionalEventTile_Gamepad = ZO_Object.MultiSubclass(ZO_ActionTile_Gamepad, ZO_PromotionalEventTile)

function ZO_PromotionalEventTile_Gamepad:New(...)
    return ZO_PromotionalEventTile.New(self, ...)
end

-- Begin ZO_ActionTile_Gamepad Overrides --

function ZO_PromotionalEventTile_Gamepad:PostInitializePlatform()
    ZO_ActionTile_Gamepad.PostInitializePlatform(self)

    self:SetActionText(GetString(SI_MARKET_ANNOUNCEMENT_PROMOTIONAL_EVENT_ACTION))
end

function ZO_PromotionalEventTile_Gamepad:SetSelected(isSelected)
    ZO_ActionTile_Gamepad.SetSelected(self, isSelected)

    if isSelected then
        self:SetHeaderColor(HEADER_TEXT_COLORS.SELECTED_TEXT_COLOR)
        self:SetTitleColor(ZO_PROMOTIONAL_EVENT_SELECTED_COLOR)
        self:SetBackgroundColor(ZO_MARKET_PRODUCT_BACKGROUND_BRIGHTNESS_COLOR)
    else
        self:SetHeaderColor(HEADER_TEXT_COLORS.UNSELECTED_TEXT_COLOR)
        self:SetTitleColor(ZO_PROMOTIONAL_EVENT_UNSELECTED_COLOR)
        self:SetBackgroundColor(ZO_MARKET_DIMMED_COLOR)
    end
end

-- End ZO_ActionTile_Gamepad Overrides --

-- Globals

function ZO_PromotionalEventTile_Gamepad.OnControlInitialized(control)
    ZO_PROMOTIONAL_EVENT_TILE_GAMEPAD = ZO_PromotionalEventTile_Gamepad:New(control)
end