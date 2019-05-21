local ZO_CampaignOverviewManager = ZO_Object:Subclass()

function ZO_CampaignOverviewManager:New(control)
    local manager = ZO_Object.New(self)
    manager.control = control

    CAMPAIGN_OVERVIEW_SCENE = ZO_Scene:New("campaignOverview", SCENE_MANAGER)
    CAMPAIGN_OVERVIEW_SCENE:RegisterCallback("StateChange", function(oldState, newState)
                                                                if newState == SCENE_SHOWING then
                                                                    manager:ChangeCategory(manager.overviewType)
                                                                end
                                                            end)

    manager.campaignName = GetControl(control, "CampaignName")
    manager:InitializeCategories()

    return manager
end

function ZO_CampaignOverviewManager:UpdateCampaignName(campaignId)
    local campaignName = GetCampaignName(campaignId)
    self.campaignName:SetText(campaignName)
end

function ZO_CampaignOverviewManager:SetCampaignAndQueryType(campaignId, queryType)
    self:UpdateCampaignName(campaignId)
end

local CAMPAIGN_OVERVIEW_TYPE_SCORING = 1
local CAMPAIGN_OVERVIEW_TYPE_BONUSES = 2
local CAMPAIGN_OVERVIEW_TYPE_EMPEROR = 3

local CAMPAIGN_OVERVIEW_TYPE_INFO =
{
    [CAMPAIGN_OVERVIEW_TYPE_SCORING] = 
    {
        name = GetString(SI_CAMPAIGN_OVERVIEW_CATEGORY_SCORING),
        up = "EsoUI/Art/Campaign/overview_indexIcon_scoring_up.dds",
        down = "EsoUI/Art/Campaign/overview_indexIcon_scoring_down.dds",
        over = "EsoUI/Art/Campaign/overview_indexIcon_scoring_over.dds",
    },
    [CAMPAIGN_OVERVIEW_TYPE_BONUSES] = 
    {
        name = GetString(SI_CAMPAIGN_OVERVIEW_CATEGORY_BONUSES),
        up = "EsoUI/Art/Campaign/overview_indexIcon_bonus_up.dds",
        down = "EsoUI/Art/Campaign/overview_indexIcon_bonus_down.dds",
        over = "EsoUI/Art/Campaign/overview_indexIcon_bonus_over.dds",
        visible = function() return GetAssignedCampaignId() ~= 0 end,
    },
    [CAMPAIGN_OVERVIEW_TYPE_EMPEROR] = 
    {
        name = GetString(SI_CAMPAIGN_OVERVIEW_CATEGORY_EMPERORSHIP),
        up = "EsoUI/Art/Campaign/overview_indexIcon_emperor_up.dds",
        down = "EsoUI/Art/Campaign/overview_indexIcon_emperor_down.dds",
        over = "EsoUI/Art/Campaign/overview_indexIcon_emperor_over.dds",
    },
}

function ZO_CampaignOverviewManager:InitializeCategories()
    self.tree = ZO_Tree:New(GetControl(self.control, "Categories"), 60, -10, 280)

    local function CategorySetup(node, control, overviewType, down)
        local info = CAMPAIGN_OVERVIEW_TYPE_INFO[overviewType]

        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(info.name)
        control.overviewType = overviewType

        control.icon:SetTexture(down and info.down or info.up)
        control.iconHighlight:SetTexture(info.over)

        ZO_IconHeader_Setup(control, down)
    end
    local function CategorySelected(control, overviewType, selected, reselectingDuringRebuild)
        if selected then
            self:ChangeCategory(overviewType)
        end
        CategorySetup(nil, control, overviewType, selected)
    end
    self.tree:AddTemplate("ZO_CampaignOverviewType", CategorySetup, CategorySelected, nil)
    self.tree:SetExclusive(true)

    self:RefreshCategories()

    self.control:RegisterForEvent(EVENT_ASSIGNED_CAMPAIGN_CHANGED, function() self:RefreshCategories() end)
end

function ZO_CampaignOverviewManager:RefreshCategories()
    self.tree:Reset()

    for categoryType, categoryInfo in ipairs(CAMPAIGN_OVERVIEW_TYPE_INFO) do
        if not categoryInfo.visible or categoryInfo.visible() then
            self.tree:AddNode("ZO_CampaignOverviewType", categoryType)
        end
    end

    self.tree:Commit()
end

function ZO_CampaignOverviewManager:ChangeCategory(overviewType)
    self.overviewType = overviewType

    if not CAMPAIGN_BONUSES_FRAGMENT or not CAMPAIGN_EMPEROR_FRAGMENT or not CAMPAIGN_SCORING_FRAGMENT then
        return
    end

    if overviewType == CAMPAIGN_OVERVIEW_TYPE_SCORING then
        CAMPAIGN_OVERVIEW_SCENE:RemoveFragment(CAMPAIGN_BONUSES_FRAGMENT)
        CAMPAIGN_OVERVIEW_SCENE:RemoveFragment(CAMPAIGN_EMPEROR_FRAGMENT)
        CAMPAIGN_OVERVIEW_SCENE:AddFragment(CAMPAIGN_SCORING_FRAGMENT)
    elseif overviewType == CAMPAIGN_OVERVIEW_TYPE_BONUSES then
        CAMPAIGN_OVERVIEW_SCENE:RemoveFragment(CAMPAIGN_SCORING_FRAGMENT)
        CAMPAIGN_OVERVIEW_SCENE:RemoveFragment(CAMPAIGN_EMPEROR_FRAGMENT)
        CAMPAIGN_OVERVIEW_SCENE:AddFragment(CAMPAIGN_BONUSES_FRAGMENT)
    else
        CAMPAIGN_OVERVIEW_SCENE:RemoveFragment(CAMPAIGN_SCORING_FRAGMENT)
        CAMPAIGN_OVERVIEW_SCENE:RemoveFragment(CAMPAIGN_BONUSES_FRAGMENT)
        CAMPAIGN_OVERVIEW_SCENE:AddFragment(CAMPAIGN_EMPEROR_FRAGMENT)
    end
end

function ZO_CampaignOverview_OnInitialized(self)
    CAMPAIGN_OVERVIEW = ZO_CampaignOverviewManager:New(self)
end
