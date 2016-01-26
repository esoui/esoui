--------------------------------------------
-- CampaignEmperor Gamepad
--------------------------------------------

local CampaignEmperor_Gamepad = ZO_Object.MultiSubclass(CampaignEmperor_Shared, ZO_SortFilterList_Gamepad)

local function MagnitudeQuery()
    return DIRECTIONAL_INPUT:GetY(ZO_DI_RIGHT_STICK)
end

local function LeaderboardEntrySelectionCallback()
    -- Add to this function if there is something to be done on selection when scrolling through a leaderboard.
    -- At the moment this function exists to enable scrolling through a leaderboard.
end

function CampaignEmperor_Gamepad:New(control)
    local manager = ZO_Object.New(self)
    manager:Initialize(control)
    return manager
end

function CampaignEmperor_Gamepad:Initialize(control)
    local SCROLL_AS_BLOCK = true
    ZO_SortFilterList_Gamepad.InitializeSortFilterList(self, control, MagnitudeQuery, SCROLL_AS_BLOCK)
    CampaignEmperor_Shared.Initialize(self, control)

    self.movementController:SetNumTicksToStartAccelerating(2)
    self.movementController:SetAccelerationMagnitudeFactor(6)

    self.scrollIndicator = GetControl(control, "ScrollIndicator")
    self.scrollIndicator:SetTexture(ZO_GAMEPAD_RIGHT_SCROLL_ICON)
    ZO_Scroll_Gamepad_SetScrollIndicatorSide(self.scrollIndicator, ZO_SharedGamepadNavQuadrant_2_3_Background, RIGHT)
    
    self.imperialKeepPool = ZO_ControlPool:New("ZO_CampaignImperialKeep_Gamepad", self.imperialKeeps, "ImperialKeep")

    local function ScrollBarHiddenCallback(list, hidden)
        self.scrollIndicator:SetHidden(hidden)
        list.scrollbar:SetHidden(true)
    end

    local LIST_ENTRY_HEIGHT = 64
    ZO_ScrollList_SetScrollBarHiddenCallback(self.list, ScrollBarHiddenCallback)
    ZO_ScrollList_SetAutoSelect(self.list, true)
    ZO_ScrollList_EnableSelection(self.list, nil, LeaderboardEntrySelectionCallback)
    ZO_ScrollList_AddDataType(self.list, ZO_EMPEROR_LEADERBOARD_NONPLAYER_DATA, "ZO_CampaignEmperorLeaderboardsNonPlayerRow_Gamepad", LIST_ENTRY_HEIGHT, function(control, data) self:SetupLeaderboardNonPlayerEntry(control, data) end)
    ZO_ScrollList_AddDataType(self.list, ZO_EMPEROR_LEADERBOARD_PLAYER_DATA, "ZO_CampaignEmperorLeaderboardsPlayerRow_Gamepad", LIST_ENTRY_HEIGHT, function(control, data) self:SetupLeaderboardEntry(control, data) end)
    ZO_ScrollList_AddDataType(self.list, ZO_EMPEROR_LEADERBOARD_ALLIANCE_DATA, "ZO_CampaignEmperorLeaderboardsAllianceRow_Gamepad", LIST_ENTRY_HEIGHT, function(control, data) self:SetupLeaderboardAllianceEntry(control, data) end)
    ZO_ScrollList_AddDataType(self.list, ZO_EMPEROR_LEADERBOARD_EMPTY_DATA, "ZO_CampaignEmperorLeaderboardsEmptyRow_Gamepad", LIST_ENTRY_HEIGHT, function(control, data) self:SetupLeaderboardEmptyEntry(control, data) end)
	
	self.shownAllianceIndex = self.listAlliance

    self:SetEmptyText(GetString(SI_GAMEPAD_EMPERORSHIP_LEADERBOARD_EMPTY))

    self:SetupLeaderboardAlliances()

    local ALWAYS_ANIMATE = true
    CAMPAIGN_EMPEROR_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CampaignEmperor_Gamepad, ALWAYS_ANIMATE)
    CAMPAIGN_EMPEROR_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                                    if(newState == SCENE_FRAGMENT_SHOWN) then
                                                                        QueryCampaignLeaderboardData()
                                                                        self:RefreshData()
                                                                        self:RefreshEmperor()
                                                                        self:SetDirectionalInputEnabled(true)
																	elseif(newState == SCENE_FRAGMENT_HIDDEN) then
                                                                        self:SetDirectionalInputEnabled(false)
                                                                    end
                                                                end)
end

local leaderboardSortKeys =
{
    isCurrent = { tiebreaker = "allianceName", reverseTiebreakerSortOrder = true },
    allianceName = {},
}

function CampaignEmperor_Gamepad:SetupLeaderboardAllianceEntry(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)

    control.nameLabel = GetControl(control, "Name")
    control.allianceIcon = GetControl(control, "Icon")

    control.nameLabel:SetText(zo_strformat(SI_GAMEPAD_EMPERORSHIP_LEADERBOARD_HEADER, data.name))
    
    local allianceTexture = GetLargeAllianceSymbolIcon(data.alliance)
    control.allianceIcon:SetHidden(false)
    control.allianceIcon:SetTexture(allianceTexture)

    self:SetupBackgroundForEntry(control, data)
end

function CampaignEmperor_Gamepad:SetupLeaderboardEmptyEntry(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)
    self:SetupBackgroundForEntry(control, data)
end

local function LeaderboardSortFunc(data1, data2)
    return ZO_TableOrderingFunction(data1, data2, "isCurrent", leaderboardSortKeys, ZO_SORT_ORDER_DOWN)
end

function CampaignEmperor_Gamepad:SetupLeaderboardAlliances()

    local allianceList = { ALLIANCE_ALDMERI_DOMINION, ALLIANCE_DAGGERFALL_COVENANT, ALLIANCE_EBONHEART_PACT }
    
    self.leaderboardAlliances = {}
    for _, alliance in ipairs(allianceList) do
        local allianceInfo = {
            alliance = alliance,
            allianceName = zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(alliance)),
            isCurrent = self.listAlliance == alliance
        }

        table.insert(self.leaderboardAlliances, allianceInfo)
    end

    table.sort(self.leaderboardAlliances, LeaderboardSortFunc)                      
end

function CampaignEmperor_Gamepad:SetCampaignAndQueryType(campaignId, queryType)
    CampaignEmperor_Shared.SetCampaignAndQueryType(self, campaignId, queryType)
end

function CampaignEmperor_Gamepad:BuildMasterList()
    self.masterList = {}

    local foundPlayer = false
    if self.leaderboardAlliances then
        for i, allianceInfo in ipairs(self.leaderboardAlliances) do

            local data = {
                    index = #self.masterList,
                    isAlliance = true,
                    name = allianceInfo.allianceName,
                    alliance = allianceInfo.alliance,
                    }

            self.masterList[#self.masterList + 1] = data

            local numEntries = GetNumCampaignAllianceLeaderboardEntries(self.campaignId, allianceInfo.alliance)
            if numEntries > 0 then
                local playerInAllianceLeaderboard = self:AddAllianceToMasterList(allianceInfo.alliance)
                foundPlayer = foundPlayer or playerInAllianceLeaderboard
            end

            if i < #self.leaderboardAlliances then
                local emptyData = {
                                    index = #self.masterList,
                                    isEmpty = true,
                                    }

                self.masterList[#self.masterList + 1] = emptyData
            end
        end
    end

    self.playerRow:SetHidden(not foundPlayer)
end

function CampaignEmperor_Gamepad:CreateImperialKeepControl(rulesetId, playerAlliance, index, _, prevKeep)
    local keep = self.imperialKeepPool:AcquireObject()
    keep.keepId = GetCampaignRulesetImperialKeepId(rulesetId, playerAlliance, index)
    if(prevKeep) then
        keep:SetAnchor(TOPLEFT, prevKeep, BOTTOMLEFT, 0, -20)
    else
        local xOffset = index == 1 and 0 or 360
        keep:SetAnchor(TOPLEFT, nil, TOPLEFT, xOffset, 0)
    end
    keep.iconControl = GetControl(keep, "Icon")
    keep.nameControl = GetControl(keep, "Name")
    keep.name = zo_strformat(SI_TOOLTIP_KEEP_NAME, GetKeepName(keep.keepId))
    return keep
end

function CampaignEmperor_Gamepad:SetKeepAllianceNoneStatus(keep)
    keep.iconControl:SetColor(ZO_DISABLED_TEXT:UnpackRGB())
    if keep.nameControl then
        keep.nameControl:SetText(keep.name)
        keep.nameControl:SetColor(ZO_DISABLED_TEXT:UnpackRGB())
    end
end


-- CampaignEmperor_Shared Overrides
function CampaignEmperor_Gamepad:RefreshImperialKeeps()
    local playerAlliance = GetUnitAlliance("player")
    local numRequired = self.imperialKeeps:GetNumChildren()
    local numOwned = 0
    for i = 1, numRequired do
        local keep = self.imperialKeeps:GetChild(i)
        local keepAlliance = GetKeepAlliance(keep.keepId, self.queryType)
        if(keepAlliance ~= ALLIANCE_NONE) then
            keep.iconControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ALLIANCE, keepAlliance))
            if keep.nameControl then
                keep.nameControl:SetText(keep.name)
                keep.nameControl:SetColor(ZO_SELECTED_TEXT:UnpackRGB())
            end
            if(keepAlliance == playerAlliance) then
                numOwned = numOwned + 1
            end
        else
            self:SetKeepAllianceNoneStatus(keep)
        end
    end

    if(self.imperialKeepsRequiredData) then
        self.imperialKeepsRequired:SetText(GetString(SI_GAMEPAD_CAMPAIGN_EMPEROR_KEEPS_NEEDED))
        self.imperialKeepsRequiredData:SetText(zo_strformat(SI_GAMEPAD_CAMPAIGN_EMPEROR_KEEPS_NEEDED_FORMAT, numOwned, numRequired))
    else
        self.imperialKeepsRequired:SetText(zo_strformat(SI_CAMPAIGN_EMPEROR_KEEPS_NEEDED, numOwned, numRequired))
    end
end


-- XML Calls
function ZO_CampaignEmperor_Gamepad_OnInitialized(self)
    CAMPAIGN_EMPEROR_GAMEPAD = CampaignEmperor_Gamepad:New(self)
end