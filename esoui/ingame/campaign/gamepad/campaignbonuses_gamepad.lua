ZO_GAMEPAD_CAMPAIGN_BONUSES_LIST_ENTRY_WIDTH = 2 * ZO_GAMEPAD_DEFAULT_LIST_ENTRY_WIDTH_AFTER_INDENT - (2 * ZO_GAMEPAD_CONTENT_INSET_X)
ZO_GAMEPAD_CAMPAIGN_BONUSES_LIST_ENTRY_INDENT = 40

local ZO_CampaignBonusesGamepad = ZO_CampaignBonuses_Shared:Subclass()

function ZO_CampaignBonusesGamepad:New(...)
    return ZO_CampaignBonuses_Shared.New(self, ...)
end

function ZO_CampaignBonusesGamepad:Initialize(control)
    ZO_CampaignBonuses_Shared.Initialize(self, control)

    self.control = control

    self.abilityList = ZO_GamepadVerticalParametricScrollList:New(self.control:GetNamedChild("Menu"):GetNamedChild("Container"):GetNamedChild("List"))
    self.abilityList:AddDataTemplate("ZO_CampaignBonusEntryTemplate", ZO_CampaignBonusEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self.abilityList:AddDataTemplateWithHeader("ZO_CampaignBonusEntryTemplate", ZO_CampaignBonusEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadCampaignBonusesHeader", ZO_CampaignBonusEntryHeaderTemplateSetup)
    self.abilityList:SetAlignToScreenCenter(true)

	self.abilityList:SetOnSelectedDataChangedCallback(function(list, selectedData)
		self:UpdateToolTip()
	end)

    local ALWAYS_ANIMATE = true
    CAMPAIGN_BONUSES_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control, ALWAYS_ANIMATE)
    CAMPAIGN_BONUSES_GAMEPAD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                                                                    if(newState == SCENE_FRAGMENT_SHOWN) then
                                                                        self:RegisterForEvents()
                                                                        self:UpdateBonuses()
                                                                    elseif(newState == SCENE_FRAGMENT_HIDDEN) then
                                                                        self:UnregisterForEvents()
                                                                        self:Deactivate()
                                                                    end
                                                                end)
end

function ZO_CampaignBonusesGamepad:RegisterForEvents()
    self.control:RegisterForEvent(EVENT_KEEP_ALLIANCE_OWNER_CHANGED, function() self:UpdateBonuses() end)
    self.control:RegisterForEvent(EVENT_OBJECTIVES_UPDATED, function() self:UpdateBonuses() end)
end

function ZO_CampaignBonusesGamepad:UnregisterForEvents()
    self.control:UnregisterForEvent(EVENT_KEEP_ALLIANCE_OWNER_CHANGED)
    self.control:UnregisterForEvent(EVENT_OBJECTIVES_UPDATED)
end

function ZO_CampaignBonusesGamepad:Activate()
    self.abilityList:Activate()
    self:UpdateToolTip()
end

function ZO_CampaignBonusesGamepad:Deactivate()
    self.abilityList:Deactivate()
    self:UpdateToolTip()
end

function ZO_CampaignBonusesGamepad:UpdateToolTip()
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_RIGHT_TOOLTIP)
    if self.abilityList:IsActive() then
        local targetData = self.abilityList:GetTargetData()
        if targetData and targetData.isHeader == false then
            GAMEPAD_TOOLTIPS:LayoutAvABonus(GAMEPAD_RIGHT_TOOLTIP, targetData)
			self:SetTooltipHidden(false)
            return
        end
    end

    self:SetTooltipHidden(true)
end

function ZO_CampaignBonusesGamepad:SetTooltipHidden(hidden)
    if(hidden) then
        GAMEPAD_TOOLTIPS:HideBg(GAMEPAD_RIGHT_TOOLTIP)
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    else
        GAMEPAD_TOOLTIPS:ShowBg(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_CampaignBonusesGamepad:UpdateBonuses()
    self:BuildMasterList()

    self.abilityList:Clear()

    local header = nil
    local headerInfoString = nil
    for i = 1, #self.masterList do
        local data = self.masterList[i]

        if data.isHeader then
            header = data.headerString
        else
            local entryData = ZO_GamepadEntryData:New(data.name, data.icon)
            entryData:SetDataSource(data)
            if(header) then
                entryData:SetHeader(header)
                self.abilityList:AddEntryWithHeader("ZO_CampaignBonusEntryTemplate", entryData)
                header = nil
            else
                self.abilityList:AddEntry("ZO_CampaignBonusEntryTemplate", entryData)
            end
        end
    end

    self.abilityList:Commit()
end

function ZO_CampaignBonuses_Gamepad_OnInitialized(control)
    CAMPAIGN_BONUSES_GAMEPAD = ZO_CampaignBonusesGamepad:New(control)
end

function ZO_CampaignBonusEntryHeaderTemplateSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    if(data.header) then
        control.text:SetText(data.header)
    end
end

local function GetNumHomeKeepsHeld(campaignId)
    local _, _, numHomeKeepsHeld = GetAvAKeepScore(campaignId, GetUnitAlliance("player"))
    return numHomeKeepsHeld
end

function ZO_CampaignBonusEntryTemplateSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    control.typeIcon:SetTexture(data.typeIconGamepad)

    local showCheckmark = data.active

    if data.countText then
        if data.bonusType == ZO_CAMPAIGN_BONUS_TYPE_HOME_KEEPS then
            control.countText:SetText(zo_strformat(SI_CAMPAIGN_SCORING_HOLDING, GetNumHomeKeepsHeld(CAMPAIGN_BONUSES_GAMEPAD:GetCurrentCampaignId())))
        else
            control.countText:SetText(zo_strformat(SI_CAMPAIGN_SCORING_HOLDING, data.countText))
        end
        
        control.countText:SetHidden(showCheckmark)
    else
        control.countText:SetHidden(true)
    end

    control.checkmark:SetHidden(not showCheckmark)
    control.typeIcon:SetHidden(showCheckmark)

    data:SetIconDesaturation(showCheckmark and 0 or 1)

    ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
end

function ZO_CampaignBonusEntryTemplate_OnInitialized(control)
    ZO_SharedGamepadEntry_OnInitialized(control)
    ZO_SharedGamepadEntry_SetHeightFromLabels(control)
    control.checkmark = control:GetNamedChild("Checkmark")
    control.typeIcon = control:GetNamedChild("ItemIcon")
    control.countText = control:GetNamedChild("ItemCount")
    control.icon = control:GetNamedChild("Icon")
end
