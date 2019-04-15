local CampaignSelector = ZO_CampaignSelector_Shared:Subclass()

function CampaignSelector:New(control)
    local selector = ZO_CampaignSelector_Shared.New(self, control)
    return selector
end

function CampaignSelector:Initialize(control)
    ZO_CampaignSelector_Shared.Initialize(self, control)

    self.control = control
    local comboBoxControl = GetControl(control, "ComboBox")
    self.comboBox = ZO_ComboBox_ObjectFromContainer(comboBoxControl)
    self.comboBox:SetSortsItems(false)
    self.comboBox:SetSelectedItemFont("ZoFontWinH2")
    self.comboBox:SetDropdownFont("ZoFontHeader2")
    self.comboBox:SetSpacing(8)

    self.scenesCreated = false
    self.OnQueryTypeChanged = function(_, entryText, entry)
        local selectedQueryType = entry.selectedQueryType
        if selectedQueryType ~= self.selectedQueryType then
            self.selectedQueryType = selectedQueryType
            self:UpdateCampaignWindows()
            self.dataRegistration:Refresh()
        end
    end

    self.campaignWindows =
    {
        CAMPAIGN_OVERVIEW,
        CAMPAIGN_SCORING,
        CAMPAIGN_EMPEROR,
        CAMPAIGN_BONUSES,
    }

    EVENT_MANAGER:RegisterForEvent("CampaignSelector", EVENT_CURRENT_CAMPAIGN_CHANGED, function() self:OnCurrentCampaignChanged() end)
    EVENT_MANAGER:RegisterForEvent("CampaignSelector", EVENT_ASSIGNED_CAMPAIGN_CHANGED, function() self:OnAssignedCampaignChanged() end)

    CAMPAIGN_SELECTOR_FRAGMENT = ZO_FadeSceneFragment:New(control)
    CAMPAIGN_SELECTOR_FRAGMENT:RegisterCallback("StateChange", function(oldState, state)
        if state == SCENE_FRAGMENT_SHOWING or state == SCENE_FRAGMENT_HIDDEN then
            self.dataRegistration:Refresh()
        end
    end)
    
    self.dataRegistration = ZO_CampaignDataRegistration:New("CampaignSelectorData", function() return self:NeedsData() end)

    self:RefreshQueryTypes()
end

function CampaignSelector:RefreshQueryTypes()
    self.comboBox:ClearItems()

    local homeEntry
    if self:IsHomeSelectable() then
        local homeCampaignDescription = GetString("SI_BATTLEGROUNDQUERYCONTEXTTYPE", BGQUERY_ASSIGNED_CAMPAIGN)
        homeEntry = self.comboBox:CreateItemEntry(homeCampaignDescription, self.OnQueryTypeChanged)
        homeEntry.selectedQueryType = BGQUERY_ASSIGNED_CAMPAIGN
        self.comboBox:AddItem(homeEntry)
    end

    local localEntry
    if self:IsLocalSelectable() then
        local localCampaignDescription = GetString("SI_BATTLEGROUNDQUERYCONTEXTTYPE", BGQUERY_LOCAL)
        localEntry = self.comboBox:CreateItemEntry(localCampaignDescription, self.OnQueryTypeChanged)
        localEntry.selectedQueryType = BGQUERY_LOCAL
        self.comboBox:AddItem(localEntry)
    end

    if self.selectedQueryType == nil or not self:IsSelectedQueryStillValid() then
        self.comboBox:SelectItem(localEntry or homeEntry)
    else
        local IGNORE_CALLBACKS = true
        self.comboBox:SelectItem(self.selectedQueryType == BGQUERY_ASSIGNED_CAMPAIGN and homeEntry or localEntry, IGNORE_CALLBACKS)
    end
end

--Global XML

function ZO_CampaignSelector_OnInitialized(self)
    CAMPAIGN_SELECTOR = CampaignSelector:New(self)
end
