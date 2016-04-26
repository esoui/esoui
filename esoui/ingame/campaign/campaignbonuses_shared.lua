
ZO_CAMPAIGN_BONUS_TYPE_HOME_KEEPS = 1
ZO_CAMPAIGN_BONUS_TYPE_ENEMY_KEEPS = 2
ZO_CAMPAIGN_BONUS_TYPE_DEFENSIVE_SCROLLS = 3
ZO_CAMPAIGN_BONUS_TYPE_OFFENSIVE_SCROLLS = 4
ZO_CAMPAIGN_BONUS_TYPE_EMPEROR = 5

local function GetHomeKeepBonusString(campaignId)
    local allHomeKeepsHeld = GetAvAKeepScore(campaignId, GetUnitAlliance("player"))
    if allHomeKeepsHeld then
        return GetString(SI_CAMPAIGN_BONUSES_HOME_KEEP_PASS_INFO)
    else
        return GetString(SI_CAMPAIGN_BONUSES_HOME_KEEP_FAIL_INFO)
    end
end

local function GetHomeKeepBonusScore(campaignId)
    local allHomeKeepsHeld = GetAvAKeepScore(campaignId, GetUnitAlliance("player"))
    return allHomeKeepsHeld and 1 or 0
end

local function GetKeepBonusString(campaignId)
    local _, enemyKeepsHeld = GetAvAKeepScore(campaignId, GetUnitAlliance("player"))
    return zo_strformat(SI_CAMPAIGN_BONUSES_ENEMY_KEEP_INFO, enemyKeepsHeld)
end

local function GetKeepBonusScore(campaignId)
    local allHomeKeepsHeld, enemyKeepsHeld = GetAvAKeepScore(campaignId, GetUnitAlliance("player"))
    return allHomeKeepsHeld and enemyKeepsHeld or 0
end

local function GetDefensiveBonusString(campaignId)
    local _, enemyScrollsHeld = GetAvAArtifactScore(campaignId, GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_DEFENSIVE)
    return zo_strformat(SI_CAMPAIGN_BONUSES_ENEMY_SCROLL_INFO, enemyScrollsHeld)
end

local function GetDefensiveBonusCount()
    return GetNumArtifactScoreBonuses(GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_DEFENSIVE)
end

local function GetDefensiveBonusInfo(index)
    return GetArtifactScoreBonusInfo(GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_DEFENSIVE, index)
end

local function GetDefensiveBonusScore(campaignId)
    local allHomeScrollsHeld, enemyScrollsHeld = GetAvAArtifactScore(campaignId, GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_DEFENSIVE)
    return allHomeScrollsHeld and enemyScrollsHeld or 0
end

local function GetOffensiveBonusString(campaignId)
    local _, enemyScrollsHeld = GetAvAArtifactScore(campaignId, GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_OFFENSIVE)
    return zo_strformat(SI_CAMPAIGN_BONUSES_ENEMY_SCROLL_INFO, enemyScrollsHeld)
end

local function GetOffensiveBonusCount()
    return GetNumArtifactScoreBonuses(GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_OFFENSIVE)
end

local function GetOffensiveBonusInfo(index)
    return GetArtifactScoreBonusInfo(GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_OFFENSIVE, index)
end

local function GetOffensiveBonusScore(campaignId)
    local allHomeScrollsHeld, enemyScrollsHeld = GetAvAArtifactScore(campaignId, GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_OFFENSIVE)
    return allHomeScrollsHeld and enemyScrollsHeld or 0
end

local function GetEmperorBonusString(campaignId)
    if DoesCampaignHaveEmperor(campaignId) then
        local alliance = GetCampaignEmperorInfo(campaignId)
        if alliance == GetUnitAlliance("player") then
            return GetString(SI_CAMPAIGN_BONUSES_EMPEROR_PASS_INFO)
        else
            return GetString(SI_CAMPAIGN_BONUSES_EMPEROR_FAIL_INFO)
        end
    else
        return GetString(SI_CAMPAIGN_BONUSES_EMPEROR_NONE_INFO)
    end
end

local function GetEmperorBonusInfo(campaignId)
    return GetEmperorAllianceBonusInfo(campaignId, GetUnitAlliance("player"))
end

local function GetEmperorBonusScore(campaignId)
    if(DoesCampaignHaveEmperor(campaignId)) then
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
    [ZO_CAMPAIGN_BONUS_TYPE_HOME_KEEPS] =           {
                                            typeIcon = "EsoUI/Art/Campaign/campaignBonus_keepIcon.dds",
                                            typeIconGamepad = "EsoUI/Art/Campaign/Gamepad/gp_bonusIcon_keeps.dds",
                                            headerText = GetString(SI_CAMPAIGN_BONUSES_HOME_KEEP_HEADER),
                                            infoText = GetHomeKeepBonusString,
                                            count = 1, 
                                            countText = GetString(SI_CAMPAIGN_BONUSES_HOME_KEEP_ALL), 
                                            infoFunction = GetKeepScoreBonusInfo,
                                            scoreFunction = GetHomeKeepBonusScore,
                                        },
    [ZO_CAMPAIGN_BONUS_TYPE_ENEMY_KEEPS] =          {
                                            typeIcon = "EsoUI/Art/Campaign/campaignBonus_keepIcon.dds",
                                            typeIconGamepad = "EsoUI/Art/Campaign/Gamepad/gp_bonusIcon_keeps.dds",
                                            headerText = GetString(SI_CAMPAIGN_BONUSES_ENEMY_KEEP_HEADER),
                                            infoText = GetKeepBonusString,
                                            count = GetNumKeepScoreBonuses,
                                            startIndex = 2,
                                            infoFunction = GetKeepScoreBonusInfo,
                                            scoreFunction = GetKeepBonusScore,
                                        },
    [ZO_CAMPAIGN_BONUS_TYPE_DEFENSIVE_SCROLLS] =    {
                                            typeIcon = "EsoUI/Art/Campaign/campaignBonus_scrollIcon.dds",
                                            typeIconGamepad = "EsoUI/Art/Campaign/Gamepad/gp_bonusIcon_scrolls.dds",
                                            headerText = GetString(SI_CAMPAIGN_BONUSES_DEFENSIVE_SCROLL_HEADER),
                                            infoText = GetDefensiveBonusString,
                                            count = GetDefensiveBonusCount,
                                            infoFunction = GetDefensiveBonusInfo,
                                            scoreFunction = GetDefensiveBonusScore,
                                        },
    [ZO_CAMPAIGN_BONUS_TYPE_OFFENSIVE_SCROLLS] =    {
                                            typeIcon = "EsoUI/Art/Campaign/campaignBonus_scrollIcon.dds",
                                            typeIconGamepad = "EsoUI/Art/Campaign/Gamepad/gp_bonusIcon_scrolls.dds",
                                            headerText = GetString(SI_CAMPAIGN_BONUSES_OFFENSIVE_SCROLL_HEADER),
                                            infoText = GetOffensiveBonusString,
                                            count = GetOffensiveBonusCount,
                                            infoFunction = GetOffensiveBonusInfo,
                                            scoreFunction = GetOffensiveBonusScore,
                                        },
    [ZO_CAMPAIGN_BONUS_TYPE_EMPEROR] =              {
                                            typeIcon = "EsoUI/Art/Campaign/campaignBonus_emporershipIcon.dds",
                                            typeIconGamepad = "EsoUI/Art/Campaign/Gamepad/gp_bonusIcon_emperor.dds",
                                            headerText = GetString(SI_CAMPAIGN_BONUSES_EMPERORSHIP_HEADER),
                                            infoText = GetEmperorBonusString,
                                            count = 1,
                                            countText = HIDE_COUNT,
                                            infoFunction = GetEmperorBonusInfo,
                                            scoreFunction = GetEmperorBonusScore,
                                        },
}

ZO_CampaignBonuses_Shared = ZO_Object:Subclass()

function ZO_CampaignBonuses_Shared:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_CampaignBonuses_Shared:Initialize(control)
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
        local data = {
            isHeader = true,
            headerString = info.headerText,
            infoString = type(info.infoText) == "function" and info.infoText(self.campaignId) or info.infoText,
            bonusType = bonusType,
        }

        self.masterList[#self.masterList + 1] = data

        local count = type(info.count) == "function" and info.count(self.campaignId) or info.count
        local startIndex = info.startIndex or 1
        local score = info.scoreFunction(self.campaignId)

        for i = startIndex, count do
            local name, icon, description = info.infoFunction(i)

            local scoreIndex = i - startIndex + 1
            local countText = scoreIndex
            if info.countText then
                if info.countText == HIDE_COUNT then
                    countText = nil
                else
                    countText = info.countText
                end
            end

            local data = {
                index = i,
                isHeader = false,
                typeIcon = info.typeIcon,
                typeIconGamepad = info.typeIconGamepad,
                countText = countText,
                name = zo_strformat(SI_CAMPAIGN_BONUSES_ENTRY_ROW_FORMATTER, name),
                icon = icon,
                active = score and score >= scoreIndex,
                bonusType = bonusType,
                description = description,
            }

            self.masterList[#self.masterList + 1] = data
        end
    end

    return self.masterList
end