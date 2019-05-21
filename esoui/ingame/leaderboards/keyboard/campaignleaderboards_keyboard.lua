local CAMPAIGN_LEADERBOARD_FRAGMENT

-----------------
-- Leaderboard Campaign Selector Keyboard
-----------------

local MENU_BAR_DATA =
{
    initialButtonAnchorPoint = LEFT,
    buttonTemplate = "ZO_CampaignLeaderboardSelectorTab",
    normalSize = 51,
    downSize = 64,
    buttonPadding = 15,
    animationDuration = 180,
}

local ZO_LeaderboardCampaignSelector_Keyboard = ZO_LeaderboardCampaignSelector_Shared:Subclass()

function ZO_LeaderboardCampaignSelector_Keyboard:New(control)
    local selector = ZO_LeaderboardCampaignSelector_Shared.New(self, control)
    return selector
end

function ZO_LeaderboardCampaignSelector_Keyboard:Initialize(control)
    ZO_LeaderboardCampaignSelector_Shared.Initialize(self, control)

    self.activeTab = GetControl(control, "TabsActive")

    local function CreateNewTabData(queryType, normal, pressed, highlight)
        local tabData =
        {
            -- Custom data
            queryType = queryType,
            tooltipText = GetString("SI_BATTLEGROUNDQUERYCONTEXTTYPE", queryType),

            -- Menu bar data
            descriptor = queryType,
            normal = normal,
            pressed = pressed,
            highlight = highlight,
            callback = function(tabData) self:OnQueryTypeChanged(tabData) end,
        }

        return tabData
    end

    self.homeTabData = CreateNewTabData(BGQUERY_ASSIGNED_CAMPAIGN, "EsoUI/Art/Journal/leaderboard_tabIcon_home_up.dds", "EsoUI/Art/Journal/leaderboard_tabIcon_home_down.dds", "EsoUI/Art/Journal/leaderboard_tabIcon_home_over.dds")
    self.localTabData = CreateNewTabData(BGQUERY_LOCAL, "EsoUI/Art/Journal/leaderboard_tabIcon_guest_up.dds", "EsoUI/Art/Journal/leaderboard_tabIcon_guest_down.dds", "EsoUI/Art/Journal/leaderboard_tabIcon_guest_over.dds")

    ZO_MenuBar_SetData(self.tabs, MENU_BAR_DATA)

    self.dataRegistration = ZO_CampaignDataRegistration:New("CampaignLeaderboardSelectorData", function() return self:NeedsData() end)

    self:RefreshQueryTypes()
end    

function ZO_LeaderboardCampaignSelector_Keyboard:SetCampaignWindows()
    self.campaignWindows =
    {
        SYSTEMS:GetKeyboardObject(CAMPAIGN_LEADERBOARD_SYSTEM_NAME),
    }
end

function ZO_LeaderboardCampaignSelector_Keyboard:NeedsData()
    return (CAMPAIGN_LEADERBOARD_FRAGMENT:IsShowing() and self.selectedQueryType == BGQUERY_ASSIGNED_CAMPAIGN)
end

function ZO_LeaderboardCampaignSelector_Keyboard:RefreshQueryTypes()
    ZO_MenuBar_ClearButtons(self.tabs)

    if self:IsHomeSelectable() then
        ZO_MenuBar_AddButton(self.tabs, self.homeTabData)

        if not self.selectedQueryType or (self.homeTabData.queryType == self.selectedQueryType) then
            ZO_MenuBar_SelectDescriptor(self.tabs, BGQUERY_ASSIGNED_CAMPAIGN)
        end
    end

    if self:IsLocalSelectable() then
        ZO_MenuBar_AddButton(self.tabs, self.localTabData)

        if not self.selectedQueryType or (self.localTabData.queryType == self.selectedQueryType) then
            ZO_MenuBar_SelectDescriptor(self.tabs, BGQUERY_LOCAL)
        end
    end

    self.activeTab:SetText(GetCampaignName(self:GetCampaignId()))
end

function ZO_CampaignLeaderboardSelector_ButtonOnMouseEnter(self)
    ZO_MenuBarButtonTemplate_OnMouseEnter(self)
    InitializeTooltip(InformationTooltip, self, BOTTOM, 0, 0)
    SetTooltipText(InformationTooltip, ZO_MenuBarButtonTemplate_GetData(self).tooltipText)
end

function ZO_LeaderboardCampaignSelector_Keyboard:OnQueryTypeChanged(tabData)
    ZO_LeaderboardCampaignSelector_Shared.OnQueryTypeChanged(self, tabData)
    self.activeTab:SetText(GetCampaignName(self:GetCampaignId()))
end

function ZO_CampaignLeaderboardSelector_ButtonOnMouseExit(self)
    ClearTooltip(InformationTooltip)
    ZO_MenuBarButtonTemplate_OnMouseExit(self)
end

-----------------
-- Campaign Leaderboards Keyboard
-----------------

local ZO_CampaignLeaderboardsManager_Keyboard = ZO_CampaignLeaderboardsManager_Shared:Subclass()

function ZO_CampaignLeaderboardsManager_Keyboard:New(...)  
    return ZO_CampaignLeaderboardsManager_Shared.New(self, ...)
end

function ZO_CampaignLeaderboardsManager_Keyboard:Initialize(control)
    CAMPAIGN_LEADERBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)

    ZO_CampaignLeaderboardsManager_Shared.Initialize(self, control, LEADERBOARDS, LEADERBOARDS_SCENE, CAMPAIGN_LEADERBOARD_FRAGMENT)

    self.currentScoreLabel = GetControl(control, "CurrentScore")
    self.currentRankLabel = GetControl(control, "CurrentRank")
    self.scoringInfoLabel = GetControl(control, "ScoringInfo")
    self.timerLabel = GetControl(control, "Timer")

    self:InitializeTimer()

    CAMPAIGN_LEADERBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                 if newState == SCENE_FRAGMENT_SHOWING then
                                                     self.selector.dataRegistration:Refresh()
                                                 elseif newState == SCENE_FRAGMENT_HIDDEN then
                                                     self.selector.dataRegistration:Refresh()
                                                 end
                                             end)

    SYSTEMS:RegisterKeyboardObject(CAMPAIGN_LEADERBOARD_SYSTEM_NAME, self)
    LEADERBOARDS:UpdateCategories()
    self.selector = ZO_LeaderboardCampaignSelector_Keyboard:New(control)
end

function ZO_CampaignLeaderboardsManager_Keyboard:RefreshHeaderPlayerInfo()
    local displayedScore, displayedRank = self:GetScoreAndRankTexts()
    local rankingTypeText = GetString("SI_LEADERBOARDTYPE", LEADERBOARD_LIST_MANAGER.leaderboardRankType)

    self.currentScoreLabel:SetText(zo_strformat(SI_CAMPAIGN_LEADERBOARDS_CURRENT_POINTS, displayedScore))
    self.currentRankLabel:SetText(zo_strformat(SI_LEADERBOARDS_CURRENT_RANK, rankingTypeText, displayedRank))
end

function ZO_CampaignLeaderboardsManager_Keyboard:RefreshHeaderTimer()
    if self.timerLabelData then
        self.timerLabel:SetText(zo_strformat(self.timerLabelIdentifier, self.timerLabelData))
    else
        self.timerLabel:SetText("")
    end

    self.scoringInfoLabel:SetText(self.scoringInfoText)
end

function ZO_CampaignLeaderboardsInformationArea_OnInitialized(self)
    CAMPAIGN_LEADERBOARDS = ZO_CampaignLeaderboardsManager_Keyboard:New(self)
end