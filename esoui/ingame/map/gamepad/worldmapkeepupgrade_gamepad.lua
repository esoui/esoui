--Keep Upgrade Window Gamepad
local SYMBOL_PARAMS = {
    FIRST_SECTION_OFFSET_X = 39,
    FIRST_SECTION_OFFSET_Y = 50,
    SYMBOL_PADDING_X = 10,
    SYMBOL_PADDING_Y = 0,
    SYMBOL_SECTION_OFFSET_X = 0,
    SYMBOL_SECTION_OFFSET_Y = 20,
}

local NORMAL_BUTTON_TEXTURE = "EsoUI/Art/ActionBar/abilityFrame64_up.dds"
local FOCUSED_BUTTON_TEXTURE = "EsoUI/Art/ActionBar/actionBar_mouseOver.dds"

local MapKeepUpgrade_Gamepad = ZO_Object.MultiSubclass(ZO_MapKeepUpgrade_Shared, ZO_GamepadGrid)

function MapKeepUpgrade_Gamepad:New(...)
    local object = ZO_MapKeepUpgrade_Shared.New(self, ...)
    return object
end

function MapKeepUpgrade_Gamepad:Initialize(control)
    self.symbolParams = SYMBOL_PARAMS
    self.selector = control:GetNamedChild("Selector")
    self.sideContent = control:GetNamedChild("SideContent")

    local ROW_MAJOR_GRID = true
    ZO_GamepadGrid.Initialize(self, control, ROW_MAJOR_GRID)

    self.levelLayout = "ZO_WorldMapKeepUpgradeLevel_Gamepad"
    self.buttonLayout = "ZO_WorldMapKeepUpgradeButton_Gamepad"

    self.scrollTooltip = control:GetNamedChild("SideContent"):GetNamedChild("Tooltip")
    ZO_ScrollTooltip_Gamepad:Initialize(self.scrollTooltip, ZO_TOOLTIP_STYLES, "worldMapTooltip")
    zo_mixin(self.scrollTooltip, ZO_MapInformationTooltip_Gamepad_Mixin)
    ZO_Scroll_Gamepad_SetScrollIndicatorSide(self.scrollTooltip.scrollIndicator, ZO_SharedGamepadNavQuadrant_4_Background, LEFT)

    ZO_MapKeepUpgrade_Shared.Initialize(self, control)

    self.fragment = ZO_FadeSceneFragment:New(control)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_FRAGMENT_SHOWN) then
            self:RefreshAll()
            DIRECTIONAL_INPUT:Activate(self, control)
            SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
        elseif(newState == SCENE_FRAGMENT_HIDDEN) then
            self.keepUpgradeObject = nil
            DIRECTIONAL_INPUT:Deactivate(self)
            self.scrollTooltip:ClearLines()
            SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
        end
    end)
end

function MapKeepUpgrade_Gamepad:RefreshAll()
    self:ClearButtonHighlight()     -- Need to do this before RefreshLevels so the button is back to normal
    self:RefreshData()
    self:RefreshLevels()
    self:RefreshBarLabel()
    self:RefreshTimeDependentControls()
    self:RefreshGridHighlight()
end

function MapKeepUpgrade_Gamepad:RefreshData()
    self.keepUpgradeObject = GAMEPAD_WORLD_MAP_KEEP_INFO:GetKeepUpgradeObject()
end

function MapKeepUpgrade_Gamepad:ClearButtonHighlight()
    self.selector:SetHidden(true)
end

function MapKeepUpgrade_Gamepad:GetGridItems()
    return self.buttons
end

function MapKeepUpgrade_Gamepad:RefreshGridHighlight()
    -- Unhighlight old button
    self:ClearButtonHighlight()

    self.scrollTooltip:ClearLines()

    local x, y = self:GetGridPosition()
    local button = self.buttons[y][x]

    local selector = self.selector
    if button then
        selector:SetParent(button)
        selector:SetAnchor(CENTER, button, CENTER, 0, 0)
        selector:SetHidden(false)
        local info = button.info
        
        if info.description and info.description ~= "" then
            self.scrollTooltip:LayoutKeepUpgrade(info.name, info.description)
        end
    else
        selector:SetHidden(true)
    end
end

--Globals

function ZO_WorldMapKeepUpgrade_Gamepad_OnInitialized(self)
    GAMEPAD_WORLD_MAP_KEEP_UPGRADE = MapKeepUpgrade_Gamepad:New(self)
    GAMEPAD_WORLD_MAP_KEEP_INFO:SetFragment("UPGRADE_FRAGMENT", GAMEPAD_WORLD_MAP_KEEP_UPGRADE:GetFragment())
end