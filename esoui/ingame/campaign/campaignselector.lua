local CampaignSelector = ZO_CampaignSelector_Shared:Subclass()

function CampaignSelector:Initialize(control)
    ZO_CampaignSelector_Shared.Initialize(self, control)

    self.control = control
    local comboBoxControl = GetControl(control, "ComboBox")
    self.comboBox = ZO_ComboBox_ObjectFromContainer(comboBoxControl)
    self.comboBox:SetSortsItems(false)
    self.comboBox:SetSelectedItemFont("ZoFontWinH2")
    self.comboBox:SetDropdownFont("ZoFontHeader2")
    self.comboBox:SetSpacing(8)
    self.comboBox:SetDisabledColor(ZO_DEFAULT_DISABLED_COLOR)

    local function OnComboBoxEntryMouseEnter(_, entry)
        local data = entry.m_data
        local enabled = ZO_EvalDefaultTrue(data.enabled)
        if not enabled and data.disabledText then
            InitializeTooltip(InformationTooltip, entry, RIGHT, -10)
            InformationTooltip:AddLine(data.disabledText, "", ZO_NORMAL_TEXT:UnpackRGBA())
        end
    end

    local function OnComboBoxEntryMouseExit()
        ClearTooltip(InformationTooltip)
    end

    self.comboBox:SetEntryMouseOverCallbacks(OnComboBoxEntryMouseEnter, OnComboBoxEntryMouseExit)

    self.scenesCreated = false
    self.OnQueryTypeChanged = function(_, entryText, entry)
        local selectedQueryType = entry.selectedQueryType
        if selectedQueryType ~= self.selectedQueryType then
            self.selectedQueryType = selectedQueryType
            self:UpdateCampaignWindows()
            self.dataRegistration:Refresh()
        end
    end

    CAMPAIGN_SELECTOR_FRAGMENT = ZO_FadeSceneFragment:New(control)
    CAMPAIGN_SELECTOR_FRAGMENT:RegisterCallback("StateChange", function(oldState, state)
        if state == SCENE_FRAGMENT_SHOWING or state == SCENE_FRAGMENT_HIDDEN then
            self.dataRegistration:Refresh()
        end
    end)
    
    self.dataRegistration = ZO_CampaignDataRegistration:New("CampaignSelectorData", function() return self:NeedsData() end)

    self:RefreshQueryTypes()
end

function CampaignSelector:SetCampaignWindows()
    self.campaignWindows =
    {
        CAMPAIGN_OVERVIEW,
        CAMPAIGN_SCORING,
        CAMPAIGN_EMPEROR,
        CAMPAIGN_BONUSES,
    }
end

local ORDERED_QUERY_TYPES =
{
    BGQUERY_ASSIGNED_CAMPAIGN,
    BGQUERY_LOCAL
}

function CampaignSelector:RefreshQueryTypes()
    self.comboBox:ClearItems()

    local anyEntry
    local selectedQueryTypeEntry
    for _, queryType in ipairs(ORDERED_QUERY_TYPES) do
        if self:IsQueryTypeSelectable(queryType) then
            local campaignDescription = GetString("SI_BATTLEGROUNDQUERYCONTEXTTYPE", queryType)
            local enabled, disabledText = ZO_EvalDefaultTrue(self.queryTypeEnabledConditionFunction, queryType)
            local entry = self.comboBox:CreateItemEntry(campaignDescription, self.OnQueryTypeChanged, enabled)
            entry.selectedQueryType = queryType
            entry.disabledText = disabledText
            self.comboBox:AddItem(entry)

            anyEntry = entry -- Always assigning means local will take priority over home, which is desired
            if queryType == self.selectedQueryType then
                selectedQueryTypeEntry = entry
            end
        end
    end

    if self.selectedQueryType == nil or not self:IsSelectedQueryStillValid() then
        self.comboBox:SelectItem(anyEntry)
    else
        local IGNORE_CALLBACKS = true
        self.comboBox:SelectItem(selectedQueryTypeEntry, IGNORE_CALLBACKS)
    end
end

function CampaignSelector:NeedsData()
    return (CAMPAIGN_SELECTOR_FRAGMENT:IsShowing() and self.selectedQueryType == BGQUERY_ASSIGNED_CAMPAIGN)
end

--Global XML

function ZO_CampaignSelector_OnInitialized(self)
    CAMPAIGN_SELECTOR = CampaignSelector:New(self)
end
