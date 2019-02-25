----
-- ZO_ZoneStoriesTile_Gamepad
----

local HEADER_TEXT_COLORS = 
{
    SELECTED_TEXT_COLOR = ZO_NORMAL_TEXT,
    UNSELECTED_TEXT_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_GAMEPAD_CATEGORY_HEADER))
}

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_ZoneStoriesTile_Gamepad = ZO_Object.MultiSubclass(ZO_ActionTile_Gamepad, ZO_ZoneStoriesTile)

function ZO_ZoneStoriesTile_Gamepad:New(...)
    return ZO_ZoneStoriesTile.New(self, ...)
end

-- Begin ZO_ActionTile_Gamepad Overrides --

function ZO_ZoneStoriesTile_Gamepad:PostInitializePlatform()
    ZO_ActionTile_Gamepad.PostInitializePlatform(self)

    self:SetHeaderText(GetString(SI_ZONE_STORY_INFO_HEADER))
    self:SetActionText(GetString(SI_MARKET_ANNOUNCEMENT_ACTIVITY_FINDER_ACTION))
end

function ZO_ZoneStoriesTile_Gamepad:SetSelected(isSelected)
    ZO_ActionTile_Gamepad.SetSelected(self, isSelected)

    if isSelected then
        self:SetHeaderColor(HEADER_TEXT_COLORS.SELECTED_TEXT_COLOR)
        self:SetTitleColor(ZO_MARKET_PRODUCT_BACKGROUND_BRIGHTNESS_COLOR)
        self:SetBackgroundColor(ZO_MARKET_PRODUCT_BACKGROUND_BRIGHTNESS_COLOR)
    else
        self:SetHeaderColor(HEADER_TEXT_COLORS.UNSELECTED_TEXT_COLOR)
        self:SetTitleColor(ZO_MARKET_DIMMED_COLOR)
        self:SetBackgroundColor(ZO_MARKET_DIMMED_COLOR)
    end
end

-- End ZO_ActionTile_Gamepad Overrides --

-- Globals

function ZO_ZoneStoriesTile_Gamepad_OnInitialized(control)
    ZO_ZoneStoriesTile_Gamepad:New(control)
end