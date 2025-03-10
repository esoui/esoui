local CAMPAIGN_AVA_RANK
CampaignAvARank = ZO_Object:Subclass()

function CampaignAvARank:New(control)
    local manager = ZO_Object.New(self)
    manager.name = GetControl(control, "Name")
    manager.icon = GetControl(control, "Icon")
    manager.rank = GetControl(control, "Rank")
    manager.statusBar = GetControl(control, "XPBar")
    ZO_StatusBar_SetGradientColor(manager.statusBar, ZO_AVA_RANK_GRADIENT_COLORS)

    control:RegisterForEvent(EVENT_RANK_POINT_UPDATE, function() manager:Refresh() end) 

    manager:Refresh()

    return manager
end

local function GetCurrentRankProgress()
    local rankPoints = GetUnitAvARankPoints("player")
    local _, _, rankStartsAt, nextRankAt = GetAvARankProgress(rankPoints)
    if rankPoints >= nextRankAt then
        local rank = GetUnitAvARank("player")
        local lastRankPoints = GetNumPointsNeededForAvARank(rank - 1)
        local maxRankPoints = GetNumPointsNeededForAvARank(rank)
        local fullRankPoints = maxRankPoints - lastRankPoints

        return fullRankPoints, fullRankPoints
    else
        return rankPoints - rankStartsAt, nextRankAt - rankStartsAt
    end
end

function CampaignAvARank:Refresh()
    local alliance = GetUnitAlliance("player")
    local rank = GetUnitAvARank("player")
    self.name:SetText(zo_strformat(SI_AVA_ALLIANCE_AND_RANK_NAME, GetAllianceName(alliance), GetAvARankName(GetUnitGender("player"), rank)))
    self.rank:SetText(rank)
    self.icon:SetTexture(GetLargeAvARankIcon(rank))
    local current, max = GetCurrentRankProgress()
    self.statusBar:SetMinMax(0,max)    
    self.statusBar:SetValue(current)

    if InformationTooltip:GetOwner() == ZO_CampaignAvARankXPBar then
        ZO_CampaignAvARankStatusBar_OnMouseEnter(ZO_CampaignAvARankXPBar)
    end
end

function CampaignAvARank:GetNarration()
    local narrations = {}
    
    local alliance = GetUnitAlliance("player")
    local rank = GetUnitAvARank("player")
    ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_AVA_ALLIANCE_AND_RANK_NAME, GetAllianceName(alliance), GetAvARankName(GetUnitGender("player"), rank))))

    local current, max = GetCurrentRankProgress()
    if max > 0 then
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(GetString(SI_GAMEPAD_CAMPAIGN_AVA_RANK_FORMATTER), rank, 100 * (current / max))))
    end

    return narrations
end

--Global XML

function ZO_CampaignAvARankStatusBar_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, TOP, 0, 5)
    SetTooltipText(InformationTooltip, zo_strformat(SI_AVA_RANK_PROGRESS_TOOLTIP, GetCurrentRankProgress()))
end

function ZO_CampaignAvARankStatusBar_OnMouseExit()
    ClearTooltip(InformationTooltip)
end

function ZO_CampaignAvARank_OnInitialized(self)
    CAMPAIGN_AVA_RANK = CampaignAvARank:New(self)
end