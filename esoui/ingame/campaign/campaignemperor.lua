ZO_CAMPAIGN_EMPEROR_RANK_WIDTH = 60
ZO_CAMPAIGN_EMPEROR_IS_INELIGIBLE_WIDTH = 40

ZO_CAMPAIGN_EMPEROR_NAME_WIDTH = 270
ZO_CAMPAIGN_EMPEROR_NAME_HEADER_OFFSETX = ZO_CAMPAIGN_EMPEROR_IS_INELIGIBLE_WIDTH + 5
ZO_CAMPAIGN_EMPEROR_NAME_HEADER_WIDTH = 265

ZO_CAMPAIGN_EMPEROR_ALLIANCE_WIDTH = 85
ZO_CAMPAIGN_EMPEROR_POINTS_WIDTH = 130

local CampaignEmperor = ZO_Object.MultiSubclass(CampaignEmperor_Shared, ZO_SortFilterList)

function CampaignEmperor:New(control)
    local manager = ZO_Object.New(self)
    manager:Initialize(control)
    return manager
end

function CampaignEmperor:Initialize(control)
    ZO_SortFilterList.InitializeSortFilterList(self, control)
    CampaignEmperor_Shared.Initialize(self, control)

    self.imperialKeepPool = ZO_ControlPool:New("ZO_CampaignImperialKeep", self.imperialKeeps, "ImperialKeep")

    ZO_ScrollList_AddDataType(self.list, ZO_EMPEROR_LEADERBOARD_NONPLAYER_DATA, "ZO_CampaignEmperorLeaderboardsNonPlayerRow", 30, function(control, data)
        self:SetupLeaderboardNonPlayerEntry(control, data)
    end)
    ZO_ScrollList_AddDataType(self.list, ZO_EMPEROR_LEADERBOARD_PLAYER_DATA, "ZO_CampaignEmperorLeaderboardsPlayerRow", 30, function(control, data)
        self:SetupLeaderboardEntry(control, data)
    end)

    CAMPAIGN_EMPEROR_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CampaignEmperor)
    CAMPAIGN_EMPEROR_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWN then
            QueryCampaignLeaderboardData()
            self:RefreshData()
            self:RefreshEmperor()
        end
    end)
end


function CampaignEmperor:ChangeAlliance(alliance, shownAllianceString)
    local leaderboardLabelControl = GetControl(self.control, "LeaderboardLabel")
    if leaderboardLabelControl then
        leaderboardLabelControl:SetText(zo_strformat(SI_CAMPAIGN_EMPEROR_LEADERBOARD, shownAllianceString))
    end

    CampaignEmperor_Shared.ChangeAlliance(self, alliance, shownAllianceString)
end

--Local XML

function CampaignEmperor:ImperialKeep_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    SetTooltipText(InformationTooltip, zo_strformat(SI_TOOLTIP_KEEP_NAME, GetKeepName(control.keepId)))
end

function CampaignEmperor:ImperialKeep_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function CampaignEmperor:IsIneligible_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    SetTooltipText(InformationTooltip, GetString(SI_CAMPAIGN_EMPEROR_CHARACTER_INELIGIBLE_TEXT))
end

function CampaignEmperor:IsIneligible_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function CampaignEmperor:OnDropdownClicked(control)
    local menuShowing = IsMenuVisisble() and GetMenuOwner() == control
    ClearMenu()

    if not menuShowing then
        SetMenuSpacing(3)
        SetMenuPad(10)
        SetMenuMinimumWidth(185)

        for i = 1, #self.menuEntries do
            local entry = self.menuEntries[i]
            AddMenuItem(entry.textString, entry.callback)
        end
        
        ShowMenu(control)
        ZO_Menu:ClearAnchors()
        ZO_Menu:SetAnchor(TOPRIGHT, control, BOTTOMRIGHT, 0, 3)
    end
end

function CampaignEmperor:SetKeepAllianceNoneStatus(keep)
    keep:SetHidden(true)
end

--Global XML

function ZO_CampaignImperialKeep_OnMouseEnter(control)
    CAMPAIGN_EMPEROR:ImperialKeep_OnMouseEnter(control)
end

function ZO_CampaignImperialKeep_OnMouseExit(control)
    CAMPAIGN_EMPEROR:ImperialKeep_OnMouseExit(control)
end

function ZO_CampaignEmperor_DropdownClicked(control)
    CAMPAIGN_EMPEROR:OnDropdownClicked(control)
end

function ZO_CampaignEmperorIsIneligible_OnMouseEnter(control)
    CAMPAIGN_EMPEROR:IsIneligible_OnMouseEnter(control)
end

function ZO_CampaignEmperorIsIneligible_OnMouseExit(control)
    CAMPAIGN_EMPEROR:IsIneligible_OnMouseExit(control)
end

function ZO_CampaignEmperorName_OnMouseEnter(control)
    ZO_SocialListKeyboard.CharacterName_OnMouseEnter(CAMPAIGN_EMPEROR, control)
end

function ZO_CampaignEmperorName_OnMouseExit(control)
     ZO_SocialListKeyboard.CharacterName_OnMouseExit(CAMPAIGN_EMPEROR, control)
end

function ZO_CampaignEmperor_OnInitialized(self)
    CAMPAIGN_EMPEROR = CampaignEmperor:New(self)
end
