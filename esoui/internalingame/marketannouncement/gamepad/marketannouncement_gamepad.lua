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
        [ZO_ACTION_TILE_TYPE.PROMOTIONAL_EVENT] = "ZO_PromotionalEventTile_GP",
    }

    ZO_MarketAnnouncement_Shared.Initialize(self, control, IsInGamepadPreferredMode)

    self.headerNarrationFunction = function()
        local narrations = {}
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_MARKET_ANNOUNCEMENT_WELCOME)))
        --If the crown store is locked or the carousel is empty, include that in the header narration
        if ZO_MARKET_ANNOUNCEMENT_MANAGER:ShouldHideMarketProductAnnouncements() then
            if GetMarketAnnouncementCrownStoreLocked() then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_MARKET_ANNOUNCEMENT_LOCKED_CROWN_STORE_TITLE)))
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_MARKET_ANNOUNCEMENT_LOCKED_CROWN_STORE_DESCRIPTION)))
            else
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_MARKET_ANNOUNCEMENT_NO_FEATURED_PRODUCTS_TITLE)))
            end
        end
        return narrations
    end

    local AUTO_SCROLL = true
    self.carousel = ZO_MarketProductCarousel_Gamepad:New(self.carouselControl, "ZO_MarketAnnouncementMarketProductTile_Gamepad_Control", AUTO_SCROLL)
    self.carousel:SetSelectKeybindButton(self.selectButton)
    self.carousel:SetHelpKeybindButton(self.helpButton)
    self.carousel:SetScrollKeybindButton(self.scrollButton)
    self.carousel:SetKeybindAnchorControl(self.closeButton)
    self.carousel:SetHeaderNarrationFunction(self.headerNarrationFunction)
    --Because the announcements are not using the keybind strip, we need to manually narrate the keybinds
    self.carousel:SetAdditionalInputNarrationFunction(function()
        local narrationData = {}
        --Generate the narration for the scroll keybind if applicable
        if not self.scrollButton:IsHidden() then
            if ZO_Keybindings_ShouldShowGamepadKeybind() then
                local scrollNarrationData =
                {
                    name = GetString(SI_MARKET_ANNOUNCEMENT_SCROLL_KEYBIND),
                    --The gamepad scroll "keybind" isn't a real keybind so just use the key that gives us the narration we want here
                    keybindName = ZO_Keybindings_GetNarrationStringFromKeys(KEY_GAMEPAD_RIGHT_STICK, KEY_INVALID, KEY_INVALID, KEY_INVALID, KEY_INVALID),
                    enabled = true,
                }
                table.insert(narrationData, scrollNarrationData)
            else
                local scrollUpNarrationData =
                {
                    keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction("UI_SHORTCUT_RIGHT_STICK_UP") or GetString(SI_ACTION_IS_NOT_BOUND),
                    enabled = true,
                }
                table.insert(narrationData, scrollUpNarrationData)

                local scrollDownNarrationData =
                {
                    name = GetString(SI_MARKET_ANNOUNCEMENT_SCROLL_KEYBIND),
                    keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction("UI_SHORTCUT_RIGHT_STICK_DOWN") or GetString(SI_ACTION_IS_NOT_BOUND),
                    enabled = true,
                }
                table.insert(narrationData, scrollDownNarrationData)
            end
        end

        --Generate the narration for the select button if it is visible
        local selectButtonNarrationData = self.selectButton:GetKeybindButtonNarrationData()
        if selectButtonNarrationData then
            table.insert(narrationData, selectButtonNarrationData)
        end

        --Generate the narration for the help button if it is visible
        local helpButtonNarrationData = self.helpButton:GetKeybindButtonNarrationData()
        if helpButtonNarrationData then
            table.insert(narrationData, helpButtonNarrationData)
        end

        --Generate the narration for the close button
        table.insert(narrationData, self:GetCloseKeybindNarrationData())

        --Only narrate the directional input if there is more than one market product
        if self.carousel:CanScroll() then
            local directionalInputNarrationData = ZO_GetHorizontalDirectionalInputNarrationData(GetString(SI_SCREEN_NARRATION_TABBAR_PREVIOUS_KEYBIND), GetString(SI_SCREEN_NARRATION_TABBAR_NEXT_KEYBIND))
            ZO_CombineNumericallyIndexedTables(narrationData, directionalInputNarrationData)
        end

        return narrationData
    end)

    -- Action Tile Focus object must be setup before vertical navigation
    self.actionTileListFocus = ZO_GamepadFocus:New(self.actionTileListControl, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)

    self:SetupVerticalNavigation()
end

function ZO_MarketAnnouncement_Gamepad:AddTileTypeObjectPoolToMap(tileType)
    ZO_MarketAnnouncement_Shared.AddTileTypeObjectPoolToMap(self, tileType)

    local function OnSelectionChanged(isSelected)
        if isSelected then
            --Re-narrate when the selection changes
            self:NarrateSelection()
        end
    end

    local function FactoryFunction(control)
        control.object:SetKeybindButton(self.selectButton)
        control.object:SetSelectionChangedCallback(OnSelectionChanged)
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
        end,
        narrationText = function()
            return self.actionTileListFocus:GetNarrationText()
        end,
        --Because the announcements are not using the keybind strip, we need to manually narrate the keybinds
        additionalInputNarrationFunction = function()
            local narrationData = {}
            --Generate the narration for the select button if it's visible
            local selectButtonNarrationData = self.selectButton:GetKeybindButtonNarrationData()
            if selectButtonNarrationData then
                table.insert(narrationData, selectButtonNarrationData)
            end
            --Generate the narration for the close button
            table.insert(narrationData, self:GetCloseKeybindNarrationData())
            return narrationData
        end,
        headerNarrationFunction = self.headerNarrationFunction,
    }

    self:UpdateVerticalNavigation()
end

function ZO_MarketAnnouncement_Gamepad:UpdateVerticalNavigation()
    self.verticalFocus:RemoveAllEntries()

    if not ZO_MARKET_ANNOUNCEMENT_MANAGER:ShouldHideMarketProductAnnouncements() then
        self.verticalFocus:AddEntry(self.carousel:GetFocusEntryData())
    else
        self.carousel:UpdateKeybinds()
    end

    if self.actionTileListFocus:GetItemCount() >= 1 then
        self.verticalFocus:AddEntry(self.actionTileListFocusData)
    end

    self.verticalFocus:SetFocusToFirstEntry()
end

function ZO_MarketAnnouncement_Gamepad:OnShowing()
    ZO_MarketAnnouncement_Shared.OnShowing(self)

    self:UpdateVerticalNavigation()
end

function ZO_MarketAnnouncement_Gamepad:OnShown()
    self.verticalFocus:Activate()
    local NARRATE_HEADER = true
    self:NarrateSelection(NARRATE_HEADER)
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
            local hideKeyboard = ZO_Keybindings_ShouldShowGamepadKeybind()
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

function ZO_MarketAnnouncement_Gamepad:NarrateSelection(narrateHeader)
    SCREEN_NARRATION_MANAGER:QueueFocus(self.verticalFocus, narrateHeader)
end

function ZO_MarketAnnouncement_Gamepad:GetCloseKeybindNarrationData()
    local closeButtonNarrationData = self.closeButton:GetKeybindButtonNarrationData()
    --The name for the close button is set separately from the keybind, so we need to manually add it to the narration data
    closeButtonNarrationData.name = GetString(SI_DIALOG_EXIT)
    return closeButtonNarrationData
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