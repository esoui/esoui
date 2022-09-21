
ZO_CAMPAIGN_BONUS_TYPE_HOME_KEEPS = 1
ZO_CAMPAIGN_BONUS_TYPE_EMPEROR = 2
ZO_CAMPAIGN_BONUS_TYPE_ENEMY_KEEPS = 3
ZO_CAMPAIGN_BONUS_TYPE_EDGE_KEEPS = 4
ZO_CAMPAIGN_BONUS_TYPE_DEFENSIVE_SCROLLS = 5
ZO_CAMPAIGN_BONUS_TYPE_OFFENSIVE_SCROLLS = 6

local function GetFormattedBonusString(data)
    if data and data.stringId then
        if data.value then
            return zo_strformat(SI_CAMPAIGN_BONUSES_INFO_FORMATTER, GetString(data.stringId), ZO_SELECTED_TEXT:Colorize(data.value))
        else
            return GetString(data.stringId)
        end
    end
    return ""
end

local function GetHomeKeepBonusData(campaignId)
    local data = {}
    local allHomeKeepsHeld = GetAvAKeepScore(campaignId, GetUnitAlliance("player"))
    if allHomeKeepsHeld then
        data.stringId = SI_CAMPAIGN_BONUSES_HOME_KEEP_PASS_INFO
    else
        data.stringId = SI_CAMPAIGN_BONUSES_HOME_KEEP_FAIL_INFO
    end
    return data
end

local function GetHomeKeepBonusScore(campaignId)
    local allHomeKeepsHeld = GetAvAKeepScore(campaignId, GetUnitAlliance("player"))
    return allHomeKeepsHeld and 1 or 0
end

local function GetKeepBonusData(campaignId)
    local _, enemyKeepsHeld = GetAvAKeepScore(campaignId, GetUnitAlliance("player"))
    local data =
    {
        stringId = SI_CAMPAIGN_BONUSES_ENEMY_KEEP_INFO,
        value = enemyKeepsHeld,
    }
    return data
end

local function GetKeepBonusScore(campaignId)
    local allHomeKeepsHeld, enemyKeepsHeld = GetAvAKeepScore(campaignId, GetUnitAlliance("player"))
    return allHomeKeepsHeld and enemyKeepsHeld or 0
end

local function GetEdgeKeepBonusScore(campaignId)
    return select(5, GetAvAKeepScore(campaignId, GetUnitAlliance("player")))
end

local function GetEdgeKeepBonusData(campaignId)
    local data =
    {
        stringId = SI_CAMPAIGN_BONUSES_EDGE_KEEP_INFO,
        value = GetEdgeKeepBonusScore(campaignId),
    }
    return data
end

local function GetDefensiveBonusData(campaignId)
    local _, enemyScrollsHeld = GetAvAArtifactScore(campaignId, GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_DEFENSIVE)
    local data =
    {
        stringId = SI_CAMPAIGN_BONUSES_ENEMY_SCROLL_INFO,
        value = enemyScrollsHeld,
    }
    return data
end

local function GetDefensiveBonusCount()
    return GetNumArtifactScoreBonuses(GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_DEFENSIVE)
end

local function GetDefensiveBonusAbilityId(index)
    return GetArtifactScoreBonusAbilityId(GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_DEFENSIVE, index)
end

local function GetDefensiveBonusScore(campaignId)
    local allHomeScrollsHeld, enemyScrollsHeld = GetAvAArtifactScore(campaignId, GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_DEFENSIVE)
    return allHomeScrollsHeld and enemyScrollsHeld or 0
end

local function GetOffensiveBonusData(campaignId)
    local _, enemyScrollsHeld = GetAvAArtifactScore(campaignId, GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_OFFENSIVE)
    local data =
    {
        stringId = SI_CAMPAIGN_BONUSES_ENEMY_SCROLL_INFO,
        value = enemyScrollsHeld,
    }
    return data
end

local function GetOffensiveBonusCount()
    return GetNumArtifactScoreBonuses(GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_OFFENSIVE)
end

local function GetOffensiveBonusAbilityId(index)
    return GetArtifactScoreBonusAbilityId(GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_OFFENSIVE, index)
end

local function GetOffensiveBonusScore(campaignId)
    local allHomeScrollsHeld, enemyScrollsHeld = GetAvAArtifactScore(campaignId, GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_OFFENSIVE)
    return allHomeScrollsHeld and enemyScrollsHeld or 0
end

local function GetEmperorBonusData(campaignId)
    local data = {}
    if DoesCampaignHaveEmperor(campaignId) then
        local alliance = GetCampaignEmperorInfo(campaignId)
        if alliance == GetUnitAlliance("player") then
            data.stringId = SI_CAMPAIGN_BONUSES_EMPEROR_PASS_INFO
        else
            data.stringId = SI_CAMPAIGN_BONUSES_EMPEROR_FAIL_INFO
        end
    else
        data.stringId = SI_CAMPAIGN_BONUSES_EMPEROR_NONE_INFO
    end
    return data
end

-- The rankIndex is always the AvA Keep score minus one
function ZO_CampaignBonuses_GetEmperorBonusRank(campaignId)
    if DoesCampaignHaveEmperor(campaignId) then
        local alliance = GetCampaignEmperorInfo(campaignId)
        if alliance == GetUnitAlliance("player") then
            local _, _, homeKeepCount = GetAvAKeepScore(campaignId, GetUnitAlliance("player"))
            return homeKeepCount - 1 > 0 and homeKeepCount - 1 or 0
        end
    end

    return 0
end

local function GetEmperorBonusAbilityId(index, campaignId)
    local emperorBonusRank = ZO_CampaignBonuses_GetEmperorBonusRank(campaignId)
    return GetEmperorAllianceBonusAbilityId(emperorBonusRank)
end

local function GetEmperorBonusScore(campaignId)
    if DoesCampaignHaveEmperor(campaignId) then
        local alliance = GetCampaignEmperorInfo(campaignId)
        if alliance == GetUnitAlliance("player") then
            return 1
        end
    end

    return 0
end

local HIDE_COUNT = 0

local BONUS_SECTION_DATA =
{
    [ZO_CAMPAIGN_BONUS_TYPE_HOME_KEEPS] =
    {
        typeIcon = "EsoUI/Art/Campaign/campaignBonus_keepIcon.dds",
        typeIconGamepad = "EsoUI/Art/Campaign/Gamepad/gp_bonusIcon_keeps.dds",
        headerText = GetString(SI_CAMPAIGN_BONUSES_HOME_KEEP_HEADER),
        infoData = GetHomeKeepBonusData,
        count = 1,
        countText = GetString(SI_CAMPAIGN_BONUSES_HOME_KEEP_ALL),
        abilityFunction = GetKeepScoreBonusAbilityId,
        scoreFunction = GetHomeKeepBonusScore,
    },
    [ZO_CAMPAIGN_BONUS_TYPE_EMPEROR] =
    {
        typeIcon = "EsoUI/Art/Campaign/campaignBonus_emperorshipIcon.dds",
        typeIconGamepad = "EsoUI/Art/Campaign/Gamepad/gp_bonusIcon_emperor.dds",
        headerText = GetString(SI_CAMPAIGN_BONUSES_EMPERORSHIP_HEADER),
        infoData = GetEmperorBonusData,
        count = 1,
        countText = HIDE_COUNT,
        abilityFunction = GetEmperorBonusAbilityId,
        scoreFunction = GetEmperorBonusScore,
    },
    [ZO_CAMPAIGN_BONUS_TYPE_ENEMY_KEEPS] =
    {
        typeIcon = "EsoUI/Art/Campaign/campaignBonus_keepIcon.dds",
        typeIconGamepad = "EsoUI/Art/Campaign/Gamepad/gp_bonusIcon_keeps.dds",
        headerText = GetString(SI_CAMPAIGN_BONUSES_ENEMY_KEEP_HEADER),
        infoData = GetKeepBonusData,
        detailsText = GetString(SI_CAMPAIGN_BONUSES_KEEP_REQUIRE_HOME_KEEP),
        count = GetNumKeepScoreBonuses,
        startIndex = 2,
        abilityFunction = GetKeepScoreBonusAbilityId,
        scoreFunction = GetKeepBonusScore,
    },
    [ZO_CAMPAIGN_BONUS_TYPE_DEFENSIVE_SCROLLS] =
    {
        typeIcon = "EsoUI/Art/Campaign/campaignBonus_scrollIcon.dds",
        typeIconGamepad = "EsoUI/Art/Campaign/Gamepad/gp_bonusIcon_scrolls.dds",
        headerText = GetString(SI_CAMPAIGN_BONUSES_DEFENSIVE_SCROLL_HEADER),
        infoData = GetDefensiveBonusData,
        detailsText = GetString(SI_CAMPAIGN_BONUSES_KEEP_REQUIRE_HOME_SCROLLS),
        count = GetDefensiveBonusCount,
        abilityFunction = GetDefensiveBonusAbilityId,
        scoreFunction = GetDefensiveBonusScore,
    },
    [ZO_CAMPAIGN_BONUS_TYPE_OFFENSIVE_SCROLLS] =
    {
        typeIcon = "EsoUI/Art/Campaign/campaignBonus_scrollIcon.dds",
        typeIconGamepad = "EsoUI/Art/Campaign/Gamepad/gp_bonusIcon_scrolls.dds",
        headerText = GetString(SI_CAMPAIGN_BONUSES_OFFENSIVE_SCROLL_HEADER),
        infoData = GetOffensiveBonusData,
        detailsText = GetString(SI_CAMPAIGN_BONUSES_KEEP_REQUIRE_HOME_SCROLLS),
        count = GetOffensiveBonusCount,
        abilityFunction = GetOffensiveBonusAbilityId,
        scoreFunction = GetOffensiveBonusScore,
    },
    [ZO_CAMPAIGN_BONUS_TYPE_EDGE_KEEPS] =
    {
        typeIcon = "EsoUI/Art/Campaign/campaignBonus_keepIcon.dds",
        typeIconGamepad = "EsoUI/Art/Campaign/Gamepad/gp_bonusIcon_keeps.dds",
        headerText = GetString(SI_CAMPAIGN_BONUSES_EDGE_KEEP_HEADER),
        infoData = GetEdgeKeepBonusData,
        count = GetNumEdgeKeepBonuses,
        abilityFunction = GetEdgeKeepBonusAbilityId,
        scoreFunction = GetEdgeKeepBonusScore,
    },
}

ZO_CampaignBonuses_Shared = ZO_InitializingObject:Subclass()

function ZO_CampaignBonuses_Shared:Initialize(control)
    self.control = control
end

function ZO_CampaignBonuses_Shared:SetCampaignAndQueryType(campaignId, queryType)
    self.campaignId = campaignId
    self.queryType = queryType
end

function ZO_CampaignBonuses_Shared:GetCurrentCampaignId()
    return self.campaignId
end

function ZO_CampaignBonuses_Shared:CreateDataTable()
    self:BuildMasterList()

    self.dataTable = {}
    local nextItemIsHeader = false
    local headerName = nil
    for i = 1, #self.masterList do
        local data = self.masterList[i]
        if data.isHeader then
            nextItemIsHeader = true
            headerName = data.headerString
        else
            self.dataTable[i] = ZO_GamepadEntryData:New(data.name, data.icon)

            if nextItemIsHeader then
                self.dataTable[i]:SetHeader(header)
            end

            self.dataTable[i].index = data.index
            self.dataTable[i].typeIcon = data.typeIcon
            self.dataTable[i].countText = data.countText
            self.dataTable[i].active = data.active
            self.dataTable[i].bonusType = data.bonusType
            self.dataTable[i].description = data.description

            nextItemIsHeader = false
        end
    end
end

function ZO_CampaignBonuses_Shared:BuildMasterList()
    self.masterList = {}

    for bonusType, info in ipairs(BONUS_SECTION_DATA) do
        local infoData = info.infoData
        if type(info.infoData) == "function" then
            infoData = info.infoData(self.campaignId)
        end

        local infoText = ""
        if infoData then
            infoText = GetFormattedBonusString(infoData)
        end

        local detailsText = info.detailsText
        if type(info.detailsText) == "function" then
            detailsText = info.detailsText(self.campaignId)
        end

        local headerData =
        {
            isHeader = true,
            headerString = info.headerText,
            infoString = infoText,
            detailsString = detailsText or "",
            bonusType = bonusType,
        }

        self.masterList[#self.masterList + 1] = headerData

        local startIndex = info.startIndex or 1
        local score = info.scoreFunction(self.campaignId)
        local index = score and score ~= 0 and score + startIndex - 1 or startIndex
        local scoreIndex = index - startIndex + 1
        local countText = scoreIndex
        local abilityId = info.abilityFunction(index, self.campaignId)
        local name = GetAbilityName(abilityId)
        local icon = GetAbilityIcon(abilityId)
        local description = GetAbilityDescription(abilityId)

        if info.countText then
            if info.countText == HIDE_COUNT then
                countText = nil
            else
                countText = info.countText
            end
        end

        local data =
        {
            index = index,
            isHeader = false,
            typeIcon = info.typeIcon,
            typeIconGamepad = info.typeIconGamepad,
            countText = countText,
            name = zo_strformat(SI_CAMPAIGN_BONUSES_ENTRY_ROW_FORMATTER, name),
            icon = icon,
            active = score and score >= scoreIndex,
            bonusType = bonusType,
            description = description,
            infoData = infoData,
            detailsText = detailsText or "",
        }

        self.masterList[#self.masterList + 1] = data
    end

    return self.masterList
end