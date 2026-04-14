ZO_RETURNING_PLAYER_REWARDS_PANEL_RIGHT_OFFSET_GAMEPAD = ZO_GAMEPAD_QUADRANT_4_LEFT_OFFSET - 50
ZO_RETURNING_PLAYER_REWARDS_REWARD_DIMENSIONS_GAMEPAD = 116
ZO_RETURNING_PLAYER_REWARDS_REWARD_SPACING_GAMEPAD = 5
ZO_RETURNING_PLAYER_REWARDS_DAILY_REWARD_HEIGHT_GAMEPAD = 150
ZO_RETURNING_PLAYER_REWARDS_GRID_WIDTH_GAMEPAD = ZO_RETURNING_PLAYER_REWARDS_REWARD_DIMENSIONS_GAMEPAD * 5 + ZO_RETURNING_PLAYER_REWARDS_REWARD_SPACING_GAMEPAD * 4 + ZO_SCROLL_BAR_WIDTH
ZO_RETURNING_PLAYER_REWARDS_GRID_HEIGHT_GAMEPAD = ZO_RETURNING_PLAYER_REWARDS_REWARD_DIMENSIONS_GAMEPAD + 2
ZO_RETURNING_PLAYER_REWARDS_DAILY_LOGIN_GRID_HEIGHT_GAMEPAD = ZO_RETURNING_PLAYER_REWARDS_DAILY_REWARD_HEIGHT_GAMEPAD + 2

ZO_ReturningPlayerRewardScreen_Gamepad = ZO_Object.MultiSubclass(ZO_ReturningPlayerRewardScreen_Shared, ZO_GamepadMultiFocusArea_Manager)

function ZO_ReturningPlayerRewardScreen_Gamepad:Initialize(control)
    RETURNING_PLAYER_REWARD_SCENE_GAMEPAD = ZO_Scene:New("ReturningPlayerRewardSceneGamepad", SCENE_MANAGER)

    ZO_ReturningPlayerRewardScreen_Shared.Initialize(self, control, RETURNING_PLAYER_REWARD_SCENE_GAMEPAD)
    ZO_GamepadMultiFocusArea_Manager.Initialize(self)

    SYSTEMS:RegisterGamepadRootScene("returningPlayerRewards", self.scene)
end

function ZO_ReturningPlayerRewardScreen_Gamepad:OnDeferredInitialize()
    ZO_ReturningPlayerRewardScreen_Shared.OnDeferredInitialize(self)

    self.goToPromotionalEventButton = self.control:GetNamedChild("GoToPromotionalEvent")

    self.goToPromotionalEventDescriptor =
    {
        name = function()
            local promotionalEventNameText = PROMOTIONAL_EVENT_MANAGER:GetPromotionalEventsColorizedDisplayName()
            return zo_strformat(SI_PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_NAVIGATION_TO_PROMOTIONAL_EVENT_ACTION, promotionalEventNameText)
        end,
        keybind = "UI_SHORTCUT_TERTIARY",
        ethereal = true,
        narrateEthereal = true,
        etherealNarrationOrder = 2,
        callback = function()
            PROMOTIONAL_EVENT_PERSONAL_CAMPAIGN_MANAGER:GoToPromotionalEvents()
        end,
    }
    self.goToPromotionalEventButton:SetKeybindButtonDescriptor(self.goToPromotionalEventDescriptor)

    self.keybindStripDescriptor =
    {
        self.closeKeybindDescriptor,
        self.goToPromotionalEventDescriptor,
        self.primaryKeybindDescriptor,
        self.backKeybindDescriptor,
    }

    ApplyTemplateToControl(self.closeKeybindButton, "ZO_KeybindButton_Gamepad_Template")
    ApplyTemplateToControl(self.goToPromotionalEventButton, "ZO_KeybindButton_Gamepad_Template")
    ApplyTemplateToControl(self.primaryKeybindButton, "ZO_KeybindButton_Gamepad_Template")

    self:InitializeMultiFocusAreas()

    self:InitializeNarrationInfo()
end

function ZO_ReturningPlayerRewardScreen_Gamepad:InitializeGridLists()
    local function RewardGridEntryReset(control)
        ZO_ReturningPlayerRewardScreen_Shared.DailyLoginRewardGridEntryReset(control)
    end

    local DEFAULT_HIDE_CALLBACK = nil
    local DEFAULT_SELECTION_TEMPLATE = nil
    local DONT_REGISTER_FOR_NARRATION = true

    self.loginRewardGridList = ZO_SingleTemplateGridScrollList_Gamepad:New(self.loginRewardContainer, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL, DEFAULT_SELECTION_TEMPLATE, DONT_REGISTER_FOR_NARRATION)
    self.loginRewardGridList:SetGridEntryTemplate("ZO_ReturningPlayerDailyReward_Gamepad", ZO_RETURNING_PLAYER_REWARDS_REWARD_DIMENSIONS_GAMEPAD, ZO_RETURNING_PLAYER_REWARDS_DAILY_REWARD_HEIGHT_GAMEPAD, self.DailyLoginRewardGridEntrySetup, DEFAULT_HIDE_CALLBACK, RewardGridEntryReset, ZO_RETURNING_PLAYER_REWARDS_REWARD_SPACING_GAMEPAD, ZO_RETURNING_PLAYER_REWARDS_REWARD_SPACING_GAMEPAD)
    self.loginRewardGridList:SetEntryTemplateEqualityFunction("ZO_ReturningPlayerDailyReward_Gamepad", ZO_ReturningPlayerRewardScreen_Shared.AreLoginRewardEntriesEqual)
    self.loginRewardGridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridListSelectedDataChanged(...) end)
    self.loginRewardGridList:SetYDistanceFromEdgeWhereSelectionCausesScroll(10)

    local function GetLoginRewardHeaderNarration()
        local narrations = {}
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.loginBonusTitleLabel:GetText()))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.loginBonusClaimHeaderLabel:GetText()))
        return narrations
    end
    self.loginRewardGridList:SetHeaderNarrationFunction(GetLoginRewardHeaderNarration)
    self.loginRewardGridList:RegisterCallback("OnActivated", function(selectedData)
        self.narrateGridHeader = true
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("ReturningPlayerRewardScreen")
    end)

    self.primaryRewardGridList = ZO_SingleTemplateGridScrollList_Gamepad:New(self.primaryRewardContainer, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL, DEFAULT_SELECTION_TEMPLATE, DONT_REGISTER_FOR_NARRATION)
    self.primaryRewardGridList:SetGridEntryTemplate("ZO_ReturningPlayerRewardsReward_Gamepad", ZO_RETURNING_PLAYER_REWARDS_REWARD_DIMENSIONS_GAMEPAD, ZO_RETURNING_PLAYER_REWARDS_REWARD_DIMENSIONS_GAMEPAD, self.RewardGridEntrySetup, DEFAULT_HIDE_CALLBACK, RewardGridEntryReset, ZO_RETURNING_PLAYER_REWARDS_REWARD_SPACING_GAMEPAD, ZO_RETURNING_PLAYER_REWARDS_REWARD_SPACING_GAMEPAD)
    self.primaryRewardGridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridListSelectedDataChanged(...) end)
    self.primaryRewardGridList:SetYDistanceFromEdgeWhereSelectionCausesScroll(10)

    local function GetPrimaryRewardHeaderNarration()
        local narrations = {}
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.campaignInfoTitleLabel:GetText()))
        return narrations
    end
    self.primaryRewardGridList:SetHeaderNarrationFunction(GetPrimaryRewardHeaderNarration)
    self.primaryRewardGridList:RegisterCallback("OnActivated", function(selectedData)
        self.narrateGridHeader = true
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("ReturningPlayerRewardScreen")
    end)
end

function ZO_ReturningPlayerRewardScreen_Gamepad:OnGridListSelectedDataChanged(previousData, newData)
    if not (self.loginRewardGridList:IsActive() or self.primaryRewardGridList:IsActive()) then
        return
    end

    if newData then
        GAMEPAD_TOOLTIPS:LayoutRewardData(GAMEPAD_RIGHT_TOOLTIP, newData)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end

    self.selectedGridEntry = newData
    self:UpdateKeybinds()

    SCREEN_NARRATION_MANAGER:QueueCustomEntry("ReturningPlayerRewardScreen")
end

function ZO_ReturningPlayerRewardScreen_Gamepad:InitializeMultiFocusAreas()
    self.loginRewardGridArea = ZO_GridScrollList_Gamepad_FocusArea:New(self.loginRewardGridList, self)
    self.primaryRewardGridArea = ZO_GridScrollList_Gamepad_FocusArea:New(self.primaryRewardGridList, self)

    self:AddNextFocusArea(self.loginRewardGridArea)
    self:AddNextFocusArea(self.primaryRewardGridArea)
end

function ZO_ReturningPlayerRewardScreen_Gamepad:InitializeNarrationInfo()
    local narrationInfo =
    {
        canNarrate = function()
            return self:IsShowing()
        end,
        canNarrateTooltips = false, -- handled manually
        headerNarrationFunction = function()
            return self:GetHeaderNarrationText()
        end,
        selectedNarrationFunction = function()
            return self:GetNarrationText()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("ReturningPlayerRewardScreen", narrationInfo)
end

function ZO_ReturningPlayerRewardScreen_Gamepad:GetHeaderNarrationText()
    local narrations = {}

    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.headerLabel:GetText()))
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.subHeaderTitle:GetText()))
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.subHeaderTimeRemaining:GetText()))

    return narrations
end

function ZO_ReturningPlayerRewardScreen_Gamepad:GetNarrationText()
    local narrations = {}

    if self.loginRewardGridList:IsActive() then
        local gridNarration = self:GetGridNarrationText(self.loginRewardGridList)
        ZO_AppendNarration(narrations, gridNarration)
    elseif self.primaryRewardGridList:IsActive() then
        local gridNarration = self:GetGridNarrationText(self.primaryRewardGridList)
        ZO_AppendNarration(narrations, gridNarration)
    end

    return narrations
end

-- This is a customized version of ZO_ScreenNarrationManager:NarrateGridListEntry
-- We cannot rely on the default grid list narration since this screen has two grid lists
function ZO_ReturningPlayerRewardScreen_Gamepad:GetGridNarrationText(gridList)
    local narrations = {}

    if self.narrateGridHeader then
        ZO_AppendNarration(narrations, gridList:GetHeaderNarration())
        self.narrateGridHeader = false
    end

    local entryData = gridList:GetSelectedData()
    if entryData then
        if entryData.narrationText then
            if type(entryData.narrationText) == "function" then
                --If the narration text is a function it should return either a narratable object or table of narratable objects
                local narration = entryData.narrationText(entryData)
                ZO_AppendNarration(narrations, narration)
            else
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.narrationText))
            end
        end
    end

    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:GetTooltipNarration())

    if self.narrateFooter then
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.bodyTextLabel:GetText()))
        self.narrateFooter = false
    end

    return narrations
end

function ZO_ReturningPlayerRewardScreen_Gamepad:OnShowing()
    ZO_ReturningPlayerRewardScreen_Shared.OnShowing(self)

    self:SelectFocusArea(self.loginRewardGridArea)
    self:ActivateFocusArea(self.loginRewardGridArea)
    DIRECTIONAL_INPUT:Activate(self, self.control)

    PlaySound(SOUNDS.RETURNING_PLAYER_OPEN_GAMEPAD)

    self.narrateGridHeader = true
    self.narrateFooter = true
    local NARRATE_HEADER = true
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("ReturningPlayerRewardScreen", NARRATE_HEADER)
end

function ZO_ReturningPlayerRewardScreen_Gamepad:OnShown()
    ZO_ReturningPlayerRewardScreen_Shared.OnShown(self)
end

function ZO_ReturningPlayerRewardScreen_Gamepad:OnHiding()
    ZO_ReturningPlayerRewardScreen_Shared.OnHiding(self)

    self:DeactivateCurrentFocus()
    DIRECTIONAL_INPUT:Deactivate(self)

    PlaySound(SOUNDS.RETURNING_PLAYER_CLOSE_GAMEPAD)
end

function ZO_ReturningPlayerRewardScreen_Gamepad:OnHidden()
    ZO_ReturningPlayerRewardScreen_Shared.OnHidden(self)
end

function ZO_ReturningPlayerRewardScreen_Gamepad:ShouldShowPrimaryKeybind()
    if self.selectedGridEntry == nil then
        return false
    end

    local rewardData = self.selectedGridEntry.dataSource
    if rewardData.type ~= ZO_RETURNING_PLAYER_REWARD_TYPE.DAILY_REWARD then
        return false
    end

    local claimableRewardIndex = GetReturningPlayerDailyLoginClaimableRewardIndex()
    if claimableRewardIndex == nil or claimableRewardIndex ~= rewardData.index then
        return false
    end

    return true
end

function ZO_ReturningPlayerRewardScreen_Gamepad:OnPrimaryKeyPressed()
    ClaimCurrentReturningPlayerDailyLoginReward()
    self:SetTargetedClaimData(self.selectedGridEntry)
end

function ZO_ReturningPlayerRewardScreen_Gamepad.OnControlInitialized(control)
    RETURNING_PLAYER_REWARD_SCREEN_GAMEPAD = ZO_ReturningPlayerRewardScreen_Gamepad:New(control)
end
