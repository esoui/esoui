ZO_SkillsAdvisor_Suggestions_Keyboard = ZO_Object:Subclass()

local SKILL_SUGGESTION_DATA_TYPE = 1
local SKILL_SUGGESTION_LABEL_TYPE = 2
local SKILL_SUGGESTION_TEXT_TYPE = 3

function ZO_SkillsAdvisor_Suggestions_Keyboard:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_SkillsAdvisor_Suggestions_Keyboard:Initialize(control)
    self.control = control
    self.selectedBuildControl = control:GetNamedChild("SelectedBuild")
    self.skillSuggestionListControl = control:GetNamedChild("SkillSuggestionList")

    ZO_SKILLS_ADVISOR_SUGGESTION_FRAGMENT = ZO_FadeSceneFragment:New(control)

    ZO_SKILLS_ADVISOR_WINDOW:AnchorControlInTabContent(control)

    ZO_ScrollList_Initialize(self.skillSuggestionListControl)
    ZO_ScrollList_AddDataType(self.skillSuggestionListControl, SKILL_SUGGESTION_DATA_TYPE, "ZO_SkillsAdvisorSuggestedAbility", 70, function(control, data) self:SetupAbilityEntry(control, data) end)
    ZO_ScrollList_AddDataType(self.skillSuggestionListControl, SKILL_SUGGESTION_LABEL_TYPE, "ZO_SkillsAdvisorSuggestedLabel", 30, function(control, data) self:SetupHeadingLabel(control, data) end)
    ZO_ScrollList_AddDataType(self.skillSuggestionListControl, SKILL_SUGGESTION_TEXT_TYPE, "ZO_SkillsAdvisorSuggestedText", 70, function(control, data) self:SetupHeadingLabel(control, data) end)


    local function OnSkillPointsChanged()
        if not self.control:IsHidden() then
            self:LoadSkillSuggestionList()
        end
    end

    SKILLS_WINDOW:RegisterCallback("OnReadyToHandleClickAction", function() self:OnReadyToHandleClickAction() end)
    ZO_SKILLS_ADVISOR_SINGLETON:RegisterCallback("OnSkillsAdvisorDataUpdated", OnSkillPointsChanged)
    
    ZO_SKILLS_ADVISOR_SUGGESTION_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        end
    end)
end

function ZO_SkillsAdvisor_Suggestions_Keyboard:OnShowing()
    self:LoadSkillSuggestionList() 
end

function ZO_SkillsAdvisor_Suggestions_Keyboard:LoadSkillSuggestionList()
    local availableAbilityList = ZO_SKILLS_ADVISOR_SINGLETON:GetAvailableAbilityList()
    local scrollData = ZO_ScrollList_GetDataList(self.skillSuggestionListControl)
    ZO_ScrollList_Clear(self.skillSuggestionListControl)

    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILL_SUGGESTION_LABEL_TYPE, { text = GetString(SI_SKILLS_ADVISOR_ADVISED_TITLE) }))
    if #availableAbilityList > 0 then 
        for _, data in ipairs(availableAbilityList) do
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILL_SUGGESTION_DATA_TYPE, data))
        end
    else
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILL_SUGGESTION_TEXT_TYPE, { text = GetString(SI_SKILLS_ADVISOR_NO_ADVISED_ABILITIES_DESCRIPTION) }))
    end

    local purchasedAbilityList = ZO_SKILLS_ADVISOR_SINGLETON:GetPurchasedAbilityList()
    if #purchasedAbilityList > 0 then
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILL_SUGGESTION_LABEL_TYPE, { text = GetString(SI_SKILLS_ADVISOR_PURCHASED_TITLE) }))
    
        for _, data in ipairs(purchasedAbilityList) do
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILL_SUGGESTION_DATA_TYPE, data))
        end
    end

    ZO_ScrollList_Commit(self.skillSuggestionListControl)
end

function ZO_SkillsAdvisor_Suggestions_Keyboard:SetupHeadingLabel(control, data) 
    local textControl = control:GetNamedChild("Text")
    textControl:SetText(data.text)
end

function ZO_SkillsAdvisor_Suggestions_Keyboard:SetupAbilityEntry(ability, data)
    local IS_DISPLAY_VIEW = true
    SKILLS_WINDOW:SetupAbilityEntry(ability, data, ZO_SKILL_ABILITY_DISPLAY_VIEW)
end

function ZO_SkillsAdvisor_Suggestions_Keyboard:OnReadyToHandleClickAction()
    local control = self.lastClickedControl

    if control and control.ability and not ZO_SKILLS_ADVISOR_SINGLETON:IsPassiveRankPurchased(control) then
        local availablePoints = GetAvailableSkillPoints()
        local ability = control.ability
        local skillType = ability.skillType
        local skillLineIndex = ability.lineIndex
        local abilityIndex = ability.index
        local purchaseAvailable = ZO_SKILLS_ADVISOR_SINGLETON:IsPurchaseable(skillType, skillLineIndex, abilityIndex) == ZO_SKILLS_ABILITY_PURCHASEABLE
        local morphAvailable = ZO_SKILLS_ADVISOR_SINGLETON:IsMorphAvailable(skillType, skillLineIndex, abilityIndex, ability.skillBuildMorphChoice) == ZO_SKILLS_ABILITY_MORPH_AVAILABLE
	    local upgradeAvailable = ZO_SKILLS_ADVISOR_SINGLETON:IsUpgradeAvailable(skillType, skillLineIndex, abilityIndex, ability.skillBuildRankIndex) == ZO_SKILLS_ABILITY_UPGRADE_AVAILABLE
        if availablePoints > 0 then
            if purchaseAvailable then
                ZO_Dialogs_ShowDialog("PURCHASE_ABILITY_CONFIRM", control)
                SKILLS_WINDOW:StopSelectedSkillBuildSkillAnimations()
            elseif morphAvailable then
                ZO_Dialogs_ShowDialog("MORPH_ABILITY_CONFIRM", control)
                SKILLS_WINDOW:StopSelectedSkillBuildSkillAnimations()
            elseif upgradeAvailable then
                ZO_Dialogs_ShowDialog("UPGRADE_ABILITY_CONFIRM", control)
                SKILLS_WINDOW:StopSelectedSkillBuildSkillAnimations()
            end
        end
    end
    self.lastClickedControl = nil
end

function ZO_SkillsAdvisor_OnMouseEnter(control)
    InitializeTooltip(SkillTooltip, control, TOPLEFT, 5, -5, TOPRIGHT)
    local data = control.ability.dataEntry.data
    SkillTooltip:SetSkillLineAbilityId(data.abilityId, data.skillType, data.lineIndex, data.abilityIndex, data.skillBuildMorphChoice)
end

function ZO_SkillsAdvisor_AbilitySlot_OnClick(control)
    PlaySound(SOUNDS.SKILLS_ADVISOR_SELECT)
    ZO_SKILLS_ADVISOR_SUGGESTION_WINDOW.lastClickedControl = control
    SKILLS_WINDOW:OnSkillLineSet(control.skillType, control.lineIndex, control.index)
end

function ZO_SkillsAdvisor_Suggestions_Keyboard_OnInitialized(control)
    ZO_SKILLS_ADVISOR_SUGGESTION_WINDOW = ZO_SkillsAdvisor_Suggestions_Keyboard:New(control)
end