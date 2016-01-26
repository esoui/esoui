local BONUSES_HEADER_DATA = 1
local BONUSES_DATA = 2

local ZO_CampaignBonusesManager = ZO_SortFilterList:Subclass()

function ZO_CampaignBonusesManager:New(control)
    local manager = ZO_SortFilterList.New(self, control)

    manager.shown = false

    self.campaignBonuses = ZO_CampaignBonuses_Shared:New(control)

    ZO_ScrollList_AddDataType(manager.list, BONUSES_HEADER_DATA, "ZO_CampaignBonusesHeaderRow", 50, function(control, data) manager:SetupBonusesHeaderEntry(control, data) end)
    ZO_ScrollList_AddDataType(manager.list, BONUSES_DATA, "ZO_CampaignBonusesBonusRow", 80, function(control, data) manager:SetupBonusesEntry(control, data) end)

    CAMPAIGN_BONUSES_FRAGMENT = ZO_FadeSceneFragment:New(control)
    CAMPAIGN_BONUSES_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                                    if(newState == SCENE_FRAGMENT_SHOWN) then
                                                                        manager.shown = true
                                                                        manager:RefreshData()
                                                                    elseif(newState == SCENE_FRAGMENT_HIDDEN) then
                                                                        manager.shown = false
                                                                    end
                                                                end)

    control:RegisterForEvent(EVENT_KEEP_ALLIANCE_OWNER_CHANGED, function() if manager.shown then manager:RefreshData() end end)
    control:RegisterForEvent(EVENT_OBJECTIVES_UPDATED, function() if manager.shown then manager:RefreshData() end end)

    return manager
end

function ZO_CampaignBonusesManager:SetCampaignAndQueryType(campaignId, queryType)
    ZO_CampaignBonuses_Shared.SetCampaignAndQueryType(self.campaignBonuses, campaignId, queryType)
    self:RefreshData()
end

function ZO_CampaignBonusesManager:SetupBonusesHeaderEntry(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)

    control.headerLabel = GetControl(control, "Header")
    control.countInfoLabel = GetControl(control, "CountInfo")
    control.countInfoLabel.bonusType = data.bonusType

    control.headerLabel:SetText(data.headerString)
    control.countInfoLabel:SetText(data.infoString)
end

function ZO_CampaignBonusesManager:SetupBonusesEntry(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)

    control.typeIcon = GetControl(control, "TypeIcon")
    control.count = GetControl(control, "Count")
    control.ability = GetControl(control, "Ability")
    control.icon = GetControl(control.ability, "Icon")
    control.nameLabel = GetControl(control, "Name")
    control.ability.index = data.index
    control.ability.bonusType = data.bonusType

    control.ability:SetEnabled(data.active)
    ZO_ActionSlot_SetUnusable(control.icon, not data.active)

    control.typeIcon:SetTexture(data.typeIcon)
    if data.countText then
        control.count:SetText(zo_strformat(SI_CAMPAIGN_SCORING_HOLDING, data.countText))
        control.count:SetHidden(false)
    else
        control.count:SetHidden(true)
    end
    control.nameLabel:SetText(data.name)
    control.icon:SetTexture(data.icon)
end

function ZO_CampaignBonusesManager:SortScrollList()
    -- No sorting
end

function ZO_CampaignBonusesManager:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for i = 1, #self.campaignBonuses.masterList do
        local data = self.campaignBonuses.masterList[i]
        if data.isHeader then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(BONUSES_HEADER_DATA, data))
        else
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(BONUSES_DATA, data))
        end
    end
end


function ZO_CampaignBonusesManager:BuildMasterList()
    self.campaignBonuses:BuildMasterList()
end

function ZO_CampaignBonusesManager:GetRowColors(data, mouseIsOver)
    if data.isHeader then
        return ZO_CONTRAST_TEXT
    else
        if data.active then
            return ZO_CONTRAST_TEXT
        else
            return ZO_DISABLED_TEXT
        end
    end
end

function ZO_CampaignBonusesManager:ColorRow(control, data, mouseIsOver)
    local textColor = self:GetRowColors(data, mouseIsOver)

    if data.isHeader then
        GetControl(control, "CountInfo"):SetColor(textColor:UnpackRGBA())
    else
        GetControl(control, "Name"):SetColor(textColor:UnpackRGBA())
    end
end

--Global XML

function ZO_CampaignBonuses_AbilitySlot_OnMouseEnter(control)
    InitializeTooltip(SkillTooltip, control, TOPLEFT, 5, -5, TOPRIGHT)
    if control.bonusType == ZO_CAMPAIGN_BONUS_TYPE_DEFENSIVE_SCROLLS then
        SkillTooltip:SetScrollBonusAbility(GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_DEFENSIVE, control.index)
    elseif control.bonusType == ZO_CAMPAIGN_BONUS_TYPE_OFFENSIVE_SCROLLS then
        SkillTooltip:SetScrollBonusAbility(GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_OFFENSIVE, control.index)
    elseif control.bonusType == ZO_CAMPAIGN_BONUS_TYPE_EMPEROR then
        SkillTooltip:SetEmperorBonusAbility(CAMPAIGN_BONUSES.campaignBonuses:GetCurrentCampaignId(), GetUnitAlliance("player"))
    else
        SkillTooltip:SetKeepBonusAbility(control.index)
    end
end

function ZO_CampaignBonuses_AbilitySlot_OnMouseExit()
    ClearTooltip(SkillTooltip)
end

function ZO_CampaignBonuses_CountInfo_OnMouseEnter(control)
    if control.bonusType == ZO_CAMPAIGN_BONUS_TYPE_ENEMY_KEEPS then
        InitializeTooltip(InformationTooltip, control, TOPRIGHT, 0, 5, BOTTOMRIGHT)
        SetTooltipText(InformationTooltip, GetString(SI_CAMPAIGN_BONUSES_ENEMY_KEEP_INFO_TOOLTIP))
    elseif control.bonusType == ZO_CAMPAIGN_BONUS_TYPE_DEFENSIVE_SCROLLS then
        InitializeTooltip(InformationTooltip, control, TOPRIGHT, 0, 5, BOTTOMRIGHT)
        SetTooltipText(InformationTooltip, GetString(SI_CAMPAIGN_BONUSES_ENEMY_SCROLL_INFO_TOOLTIP))
    elseif control.bonusType == ZO_CAMPAIGN_BONUS_TYPE_OFFENSIVE_SCROLLS then
        InitializeTooltip(InformationTooltip, control, TOPRIGHT, 0, 5, BOTTOMRIGHT)
        SetTooltipText(InformationTooltip, GetString(SI_CAMPAIGN_BONUSES_ENEMY_SCROLL_INFO_TOOLTIP))
    end
end

function ZO_CampaignBonuses_CountInfo_OnMouseExit()
    ClearTooltip(InformationTooltip)
end

function ZO_CampaignBonuses_OnInitialized(self)
    CAMPAIGN_BONUSES = ZO_CampaignBonusesManager:New(self)
end