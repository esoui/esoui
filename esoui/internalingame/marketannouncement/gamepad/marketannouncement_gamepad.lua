----
-- ZO_MarketAnnouncement_Gamepad
----

local VERTICAL_FOCUS_INDEX =
{
    CAROUSEL = 1,
    ACTION_TILES = 2
}

local ZO_MarketAnnouncement_Gamepad = ZO_MarketAnnouncement_Shared:Subclass()

function ZO_MarketAnnouncement_Gamepad:New(...)
    return ZO_MarketAnnouncement_Shared.New(self, ...)
end

function ZO_MarketAnnouncement_Gamepad:Initialize(control)
    -- This data must be setup before parent initialize is called
    self.actionTileControlByType =
    {
        [ZO_ACTION_TILE_TYPE.EVENT_ANNOUNCEMENT] = "ZO_EventAnnouncementTile_Gamepad_Control",
        [ZO_ACTION_TILE_TYPE.DAILY_REWARDS] = "ZO_DailyRewardsTile_Gamepad_Control",
        [ZO_ACTION_TILE_TYPE.ZONE_STORIES] = "ZO_ZoneStoriesTile_Gamepad_Control",
    }

    ZO_MarketAnnouncement_Shared.Initialize(self, control, IsInGamepadPreferredMode)

    local AUTO_SCROLL = true
    self.carousel = ZO_MarketProductCarousel_Gamepad:New(self.carouselControl, "ZO_MarketAnnouncementMarketProductTile_Gamepad_Control", AUTO_SCROLL)
    self.carousel:SetSelectKeybindButton(self.selectButton)
    self.carousel:SetHelpKeybindButton(self.helpButton)
    self.carousel:SetScrollKeybindButton(self.scrollButton)
    self.carousel:SetKeybindAnchorControl(self.closeButton)

    -- Action Tile Focus object must be setup before vertical navigation
    self.actionTileListFocus = ZO_GamepadFocus:New(self.actionTileListControl, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)

    self:SetupVerticalNavigation()
end

function ZO_MarketAnnouncement_Gamepad:AddTileTypeObjectPoolToMap(tileType)
    ZO_MarketAnnouncement_Shared.AddTileTypeObjectPoolToMap(self, tileType)

    local function FactoryFunction(control)
        control.object:SetKeybindButton(self.selectButton)
    end

    self.actionTileControlPoolMap[tileType]:SetCustomFactoryBehavior(FactoryFunction)
end

function ZO_MarketAnnouncement_Gamepad:SetupVerticalNavigation()
    self.verticalFocus = ZO_GamepadFocus:New(self.control, nil, MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)

    self.actionTileListFocusData =
    {
        activate = function()
            self.actionTileListFocus:SetActive(true)
        end,
        deactivate = function()
            self.actionTileListFocus:SetActive(false)
        end
    }

    self:UpdateVerticalNavigation()
end

function ZO_MarketAnnouncement_Gamepad:UpdateVerticalNavigation()
    self.verticalFocus:RemoveAllEntries()

    if not GetMarketAnnouncementCrownStoreLocked() then
        self.verticalFocus:AddEntry(self.carousel:GetFocusEntryData())
    else
        self.carousel:UpdateKeybinds()
    end

    if self.actionTileListFocus:GetItemCount() >= 1 then
        self.verticalFocus:AddEntry(self.actionTileListFocusData)
    end
end

function ZO_MarketAnnouncement_Gamepad:OnShowing()
    ZO_MarketAnnouncement_Shared.OnShowing(self)

    self:UpdateVerticalNavigation()
end

function ZO_MarketAnnouncement_Gamepad:OnShown()
    self.verticalFocus:Activate()
end

function ZO_MarketAnnouncement_Gamepad:OnHidden()
    self.verticalFocus:Deactivate()
end

function ZO_MarketAnnouncement_Gamepad:InitializeKeybindButtons()
    ZO_MarketAnnouncement_Shared.InitializeKeybindButtons(self)

    self.selectButton = self.controlContainer:GetNamedChild("PrimaryAction")
    self.selectButton:SetupStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
    self.helpButton = self.controlContainer:GetNamedChild("SecondaryAction")
    self.helpButton:SetupStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
    self.helpButton:SetHidden(true)
    self.scrollButton = self.controlContainer:GetNamedChild("TertiaryAction")
    self.keyLabel = self.scrollButton:GetNamedChild("KeyLabel")
    self.upLabel = self.scrollButton:GetNamedChild("ScrollUpKeyLabel")
    self.downLabel = self.scrollButton:GetNamedChild("ScrollDownKeyLabel")
    self.scrollButton:SetupStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
    local WIDE_SPACING = false
    ZO_GamepadTypeBasedControl_OnInitialized(self.scrollButton)
    self.scrollButton:SetUpdateCallback(function(keybindButton)
        keybindButton:SetCustomKeyIcon(GetGamepadRightStickScrollIcon())
    end)
    self.scrollButton:AdjustBindingAnchors(WIDE_SPACING)
    self.closeButton:SetupStyle(KEYBIND_STRIP_GAMEPAD_STYLE)

    local function OnInputChanged()
        if IsInGamepadPreferredMode() then
            local hideKeyboard = WasLastInputGamepad()
            self.keyLabel:SetHidden(not hideKeyboard)
            self.upLabel:SetHidden(hideKeyboard)
            self.downLabel:SetHidden(hideKeyboard)
        end
    end

    local SHOW_UNBOUND = true
    local DEFAULT_GAMEPAD_ACTION_NAME = nil
    ZO_Keybindings_RegisterLabelForBindingUpdate(self.upLabel, "UI_SHORTCUT_RIGHT_STICK_UP", SHOW_UNBOUND, DEFAULT_GAMEPAD_ACTION_NAME, OnInputChanged)
    ZO_Keybindings_RegisterLabelForBindingUpdate(self.downLabel, "UI_SHORTCUT_RIGHT_STICK_DOWN")
    -- We only need to register one of the above with OnInputChanged because one call of that function does everything we need
end

function ZO_MarketAnnouncement_Gamepad:OnSelectionClicked()
    self.selectButton:OnClicked()
end

function ZO_MarketAnnouncement_Gamepad:OnHelpClicked()
    self.helpButton:OnClicked()
end

function ZO_MarketAnnouncement_Gamepad:UpdateActionTileNavigation()
    self.actionTileListFocus:RemoveAllEntries()
    for _, control in ipairs(self.actionTileList) do
        local entryData = control.object:GetFocusEntryData()
        self.actionTileListFocus:AddEntry(entryData)
    end
end

function ZO_MarketAnnouncement_Gamepad:OnDailyLoginRewardsUpdated()
    if self.fragment:IsShowing() then
        self:LayoutActionTiles()
        self.verticalFocus:Deactivate()
        self:UpdateVerticalNavigation()
        self.verticalFocus:Activate()
    end
end

function ZO_MarketAnnouncement_Gamepad:LayoutActionTiles()
    ZO_MarketAnnouncement_Shared.LayoutActionTiles(self)

    self:UpdateActionTileNavigation()
end

function ZO_MarketAnnouncement_Gamepad:CreateMarketProduct()
    return ZO_MarketAnnouncementMarketProduct_Gamepad:New()
end

--global XML functions

function ZO_MarketAnnouncement_Gamepad_OnInitialize(control)
    ZO_GAMEPAD_MARKET_ANNOUNCEMENT = ZO_MarketAnnouncement_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("marketAnnouncement", ZO_GAMEPAD_MARKET_ANNOUNCEMENT)
end

function ZO_MarketAnnouncement_Gamepad_PlayArrowAnimation(control, animation, playForward)
    local currentState = control:GetState()
    if not (currentState == BSTATE_DISABLED or currentState == BSTATE_DISABLED_PRESSED) then
        if playForward then
            animation:PlayForward()
        else
            animation:PlayBackward()
        end
    end
end