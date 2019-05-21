ZO_EMPEROR_LEADERBOARD_NONPLAYER_DATA = 1
ZO_EMPEROR_LEADERBOARD_PLAYER_DATA = 2
ZO_EMPEROR_LEADERBOARD_ALLIANCE_DATA = 3
ZO_EMPEROR_LEADERBOARD_EMPTY_DATA = 4

local MAX_ALLOWED_EMPEROR_RANK = 10

CampaignEmperor_Shared = ZO_Object:Subclass()

function CampaignEmperor_Shared:New(control)
    local manager = ZO_Object.New(self)
    manager:Initialize(control)
    return manager
end

function CampaignEmperor_Shared:Initialize(control)
    self.control = control
    self.emperorName = GetControl(control, "Name")
    self.emperorAlliance = GetControl(control, "Alliance")
    self.emperorReignDuration = GetControl(control, "ReignDuration")
    self.imperialKeeps = GetControl(control, "Keeps")
    self.imperialKeepsRequired = GetControl(control, "KeepsRequired")
    self.imperialKeepsRequiredData = GetControl(control, "KeepsRequiredData")
    self.playerRow = GetControl(control, "PlayerRow")
    self.playerRow.dataEntry = {}

    self.UpdateReignDuration = function(control, time)
        local duration = GetCampaignEmperorReignDuration(self.campaignId)
        local formattedDuration = ZO_FormatTime(duration, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
        self.emperorReignDuration:SetText(zo_strformat(SI_CAMPAIGN_EMPEROR_REIGN_DURATION, formattedDuration))
    end

    self:InitializeMenu()

    control:RegisterForEvent(EVENT_KEEP_ALLIANCE_OWNER_CHANGED, function() self:RefreshImperialKeeps() end)
    control:RegisterForEvent(EVENT_KEEP_INITIALIZED, function() self:RefreshImperialKeeps() end)
    control:RegisterForEvent(EVENT_KEEPS_INITIALIZED, function() self:RefreshImperialKeeps() end)
    control:RegisterForEvent(EVENT_CAMPAIGN_EMPEROR_CHANGED, function(_, campaignId) self:OnCampaignEmperorChanged(campaignId) end)
    control:RegisterForEvent(EVENT_CAMPAIGN_STATE_INITIALIZED, function(_, campaignId) self:OnCampaignStateInitialized(campaignId) end)
    control:RegisterForEvent(EVENT_CAMPAIGN_LEADERBOARD_DATA_CHANGED, function() self:RefreshData() end)
end

function CampaignEmperor_Shared:InitializeMenu()
    self.menuEntries = {}

    local playerAlliance = GetUnitAlliance("player")

    local function OnEntryClicked(entry)
        self:ChangeAlliance(entry.alliance, entry.textString)
    end

    local function InitializeMenuEntry(alliance)
        local entry = { alliance = alliance,  textString = zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(alliance)) }
        entry.callback = function() OnEntryClicked(entry) end,
        
        table.insert(self.menuEntries, entry)

        if playerAlliance == alliance then
            OnEntryClicked(entry)
        end
    end

    InitializeMenuEntry(ALLIANCE_ALDMERI_DOMINION)
    InitializeMenuEntry(ALLIANCE_DAGGERFALL_COVENANT)
    InitializeMenuEntry(ALLIANCE_EBONHEART_PACT)
end

function CampaignEmperor_Shared:ChangeAlliance(alliance, shownAllianceString)
    self.listAlliance = alliance
    self.shownAllianceString = shownAllianceString

    self:RefreshData()
end

function CampaignEmperor_Shared:CreateImperialKeepControl(rulesetId, playerAlliance, index, prevKeep)
    local keep = self.imperialKeepPool:AcquireObject()
    keep.keepId = GetCampaignRulesetImperialKeepId(rulesetId, playerAlliance, index)
    if prevKeep then
        keep:SetAnchor(TOPLEFT, prevKeep, TOPRIGHT, 0, 0)
    else
        keep:SetAnchor(TOPLEFT)
    end
    keep.iconControl = keep
    return keep
end

function CampaignEmperor_Shared:BuildImperialKeeps()
    if self.campaignId then
        local rulesetId = GetCampaignRulesetId(self.campaignId)
        local playerAlliance = GetUnitAlliance("player")
        local numKeeps = GetCampaignRulesetNumImperialKeeps(rulesetId, playerAlliance)
        
        self.imperialKeepPool:ReleaseAllObjects()
        local prevKeep
        local prevPrevKeep
        for i = 1, numKeeps do
            local keep = self:CreateImperialKeepControl(rulesetId, playerAlliance, i, prevKeep, prevPrevKeep)
            prevPrevKeep = prevKeep
            prevKeep = keep
        end
    end
end

function CampaignEmperor_Shared:SetCampaignAndQueryType(campaignId, queryType)
    self.campaignId = campaignId
    self.queryType = queryType
    self:BuildImperialKeeps()
    self:RefreshAll()
end

function CampaignEmperor_Shared:SetReignDurationEnabled(enabled)
    if self.emperorReignDuration then
        self.emperorReignDuration:SetHidden(not enabled)
        self.control:SetHandler("OnUpdate", enabled and self.UpdateReignDuration or nil)
    end
end

function CampaignEmperor_Shared:RefreshEmperor()
    if self.campaignId and self.emperorName then
        if DoesCampaignHaveEmperor(self.campaignId) then
            local alliance, characterName, displayName = GetCampaignEmperorInfo(self.campaignId)
            local userFacingName = ZO_GetPlatformUserFacingName(characterName, displayName)
            self.emperorName:SetText(userFacingName)
            self.emperorAlliance:SetTexture(GetPlatformAllianceSymbolIcon(alliance))
            self.emperorAlliance:SetHidden(false)
            self:SetReignDurationEnabled(true)
        else
            self.emperorName:SetText(GetString(SI_CAMPAIGN_NO_EMPEROR))
            self.emperorAlliance:SetHidden(true)
            self.emperorReignDuration:SetHidden(true)
            self:SetReignDurationEnabled(false)
        end
    else
        self:SetReignDurationEnabled(false)
    end
end

local KEEP_ICONS =
{
    [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/Campaign/overview_keepIcon_aldmeri.dds",
    [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/Campaign/overview_keepIcon_ebonheart.dds",
    [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/Campaign/overview_keepIcon_daggefall.dds",
}

function CampaignEmperor_Shared:RefreshImperialKeeps()
    local playerAlliance = GetUnitAlliance("player")
    local numRequired = self.imperialKeeps:GetNumChildren()
    local numOwned = 0
    for i = 1, numRequired do
        local keep = self.imperialKeeps:GetChild(i)
        local keepAlliance = GetKeepAlliance(keep.keepId, self.queryType)
        if keepAlliance ~= ALLIANCE_NONE then
            keep:SetHidden(false)
            keep.iconControl:SetTexture(KEEP_ICONS[keepAlliance])
            keep.iconControl:SetDesaturation(0)
            if keep.nameControl then
                keep.nameControl:SetText(keep.name)
                keep.nameControl:SetColor(ZO_SELECTED_TEXT:UnpackRGB())
            end
            if keepAlliance == playerAlliance then
                numOwned = numOwned + 1
            end
        else
            self:SetKeepAllianceNoneStatus(keep)
        end
    end

    if self.imperialKeepsRequiredData then
        self.imperialKeepsRequired:SetText(GetString(SI_GAMEPAD_CAMPAIGN_EMPEROR_KEEPS_NEEDED))
        self.imperialKeepsRequiredData:SetText(zo_strformat(SI_GAMEPAD_CAMPAIGN_EMPEROR_KEEPS_NEEDED_FORMAT, numOwned, numRequired))
    else
        self.imperialKeepsRequired:SetText(zo_strformat(SI_CAMPAIGN_EMPEROR_KEEPS_NEEDED, numOwned, numRequired))
    end
end

function CampaignEmperor_Shared:SetKeepAllianceNoneStatus(keep)
    --override
end

function CampaignEmperor_Shared:RefreshAll()
    self:RefreshEmperor()
    self:RefreshImperialKeeps()
    self:RefreshData()
end

function CampaignEmperor_Shared:SetupBackgroundForEntry(control, data)
    local bg = GetControl(control, "BG")
    local hidden = (data.index % 2) == 0
    bg:SetHidden(hidden)
end

function CampaignEmperor_Shared:SetupLeaderboardEntry(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)

    control.rankLabel = control:GetNamedChild("Rank")
    control.isIneligibleLabel = control:GetNamedChild("IsIneligible")
    control.nameLabel = control:GetNamedChild("Name")
    control.allianceIcon = control:GetNamedChild("Alliance")
    control.pointsLabel = control:GetNamedChild("Points")

    if self:CanLeaderboardCharacterBecomeEmperor(data) then
        control.rankLabel:SetText(data.emperorRank)
        control.isIneligibleLabel:SetHidden(true)
    else
        control.rankLabel:SetText(GetString(SI_CAMPAIGN_EMPEROR_RANK_NOT_APPLICABLE))
        control.isIneligibleLabel:SetHidden(false)
    end

    local userFacingName = ZO_GetPlatformUserFacingName(data.name, data.displayName)
    control.nameLabel:SetText(userFacingName)
    control.pointsLabel:SetText(zo_strformat(SI_NUMBER_FORMAT, ZO_CommaDelimitNumber(data.points)))
    
    local allianceTexture = GetPlatformAllianceSymbolIcon(data.alliance)
    if allianceTexture then
        control.allianceIcon:SetHidden(false)
        control.allianceIcon:SetTexture(allianceTexture)
    else
        control.allianceIcon:SetHidden(true)
    end
end

function CampaignEmperor_Shared:SetupLeaderboardNonPlayerEntry(control, data)
    self:SetupLeaderboardEntry(control, data)

    self:SetupBackgroundForEntry(control, data)
end

function CampaignEmperor_Shared:SetupPlayerRow(data)
    self.playerRow.dataEntry.data = data
    self:SetupLeaderboardEntry(self.playerRow, data)
end

function CampaignEmperor_Shared:GetLocalPlayerLeaderboardEntry()
    return self.playerRow.dataEntry.data
end

function CampaignEmperor_Shared:SortScrollList()
    -- No sorting...just leave in rank order
end

function CampaignEmperor_Shared:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for i = 1, #self.masterList do
        local data = self.masterList[i]
        if data.isAlliance then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ZO_EMPEROR_LEADERBOARD_ALLIANCE_DATA, data))
        elseif data.isEmpty then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ZO_EMPEROR_LEADERBOARD_EMPTY_DATA, data))
        elseif self:CanLeaderboardCharacterBecomeEmperor(data) and data.emperorRank <= MAX_ALLOWED_EMPEROR_RANK then
            if data.isPlayer then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ZO_EMPEROR_LEADERBOARD_PLAYER_DATA, data))
            else
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ZO_EMPEROR_LEADERBOARD_NONPLAYER_DATA, data))
            end
        end
    end
end

function CampaignEmperor_Shared:CommitScrollList()
    ZO_Scroll_ResetToTop(self.list)
    ZO_SortFilterList.CommitScrollList(self)
end

function CampaignEmperor_Shared:AddAllianceToMasterList(alliance)

    local foundPlayerInLeaderboard = false
    local numEntries = GetNumCampaignAllianceLeaderboardEntries(self.campaignId, alliance)

    -- emperor rank is distinct from AP rank because some characters can be on the AP leaderboards without being eligible for emperor.
    -- to handle this, we will just take the top 10 eligible entries sorted by AP rank and number them 1-N.
    local nextEmperorRank = 1

    for i = 1, numEntries do
        -- entry info is guaranteed to be sorted by alliancePointsRank
        local isPlayer, alliancePointsRank, name, points, _, displayName, achievedEmperorForAlliance = GetCampaignAllianceLeaderboardEntryInfo(self.campaignId, alliance, i)

        local data =
        {
            isPlayer = isPlayer,
            alliancePointsRank = alliancePointsRank,
            name = name,
            alliance = alliance,
            points = points,
            displayName = displayName,
            achievedEmperorForAlliance = achievedEmperorForAlliance,
         }

        if self:CanLeaderboardCharacterBecomeEmperor(data) then
            data.emperorRank = nextEmperorRank
            nextEmperorRank = nextEmperorRank + 1
        end

        data.index = #self.masterList + 1
        self.masterList[data.index] = data

        if isPlayer then
            self:SetupPlayerRow(data)
            foundPlayerInLeaderboard = true
        end
    end

    return foundPlayerInLeaderboard
end

function CampaignEmperor_Shared:CanLeaderboardCharacterBecomeEmperor(leaderboardEntry)
    -- characters are inelgible for emperorship when it has already been achieved on an opposing alliance for this campaign
    return leaderboardEntry.achievedEmperorForAlliance == ALLIANCE_NONE or leaderboardEntry.achievedEmperorForAlliance == leaderboardEntry.alliance
end

function CampaignEmperor_Shared:BuildMasterList()
    self.masterList = {}

    local foundPlayer = self:AddAllianceToMasterList(self.listAlliance)

    self.playerRow:SetHidden(not foundPlayer)
end

function CampaignEmperor_Shared:GetRowColors(data, mouseIsOver)
    if data.isPlayer then
        return ZO_SELECTED_TEXT
    elseif data.isAlliance then
        return ZO_NORMAL_TEXT
    else
        return ZO_SECOND_CONTRAST_TEXT
    end
end

function CampaignEmperor_Shared:ColorRow(control, data, mouseIsOver)
    local textColor = self:GetRowColors(data, mouseIsOver)
    local name = GetControl(control, "Name")
    name:SetColor(textColor:UnpackRGBA())
end

--Events

function CampaignEmperor_Shared:OnCampaignEmperorChanged(campaignId)
    if self.campaignId == campaignId then
        self:RefreshEmperor()
    end
end

function CampaignEmperor_Shared:OnCampaignStateInitialized(campaignId)
    if self.campaignId == campaignId then
        self:RefreshEmperor()
    end
end
