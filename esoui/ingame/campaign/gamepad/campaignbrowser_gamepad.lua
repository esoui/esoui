local GAMEPAD_AVA_ROOT_SCENE_NAME = "gamepad_campaign_root"

local CAMPAIGN_BROWSER_MODES = {
    CAMPAIGNS = 1,
    BONUSES = 2,
    CAMPAIGN_RULESET_TYPES = 3,
}

local ENTRY_TYPES = {
    CAMPAIGN = 1,
    BONUSES = 2,
    SCORING = 3,
    EMPERORSHIP = 4,
    ENTER_CAMPAIGN = 5,
    TRAVEL_TO_CAMPAIGN = 6,
    LEAVE_QUEUE = 7,
    SET_HOME = 8,
    ABANDON_CAMPAIGN = 9,
    CAMPAIGN_RULESET_TYPE = 10,
}

local CONTENT_TYPES = {
    BONUSES = 1,
    SCORING = 2,
    EMPERORSHIP = 3,
    CAMPAIGN = 4,
    CAMPAIGN_RULESET_TYPE = 5,
}

local ICON_ENTER = "EsoUI/Art/Campaign/Gamepad/gp_campaign_menuIcon_enter.dds"
local ICON_TRAVEL = "EsoUI/Art/Campaign/Gamepad/gp_campaign_menuIcon_travel.dds"
local ICON_LEAVE = "EsoUI/Art/Campaign/Gamepad/gp_campaign_menuIcon_leave.dds"
local ICON_ABANDON = "EsoUI/Art/Campaign/Gamepad/gp_campaign_menuIcon_abandon.dds"
local ICON_HOME = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_home.dds"
local ICON_BONUS = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_bonus.dds"
local ICON_SCORING = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_scoring.dds"
local ICON_EMPEROR = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_emperor.dds"

ZO_CampaignBrowser_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_CampaignBrowser_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_CampaignBrowser_Gamepad:Initialize(control)
    GAMEPAD_AVA_ROOT_SCENE = ZO_Scene:New(GAMEPAD_AVA_ROOT_SCENE_NAME, SCENE_MANAGER)

    local ACTIVATE_LIST_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_LIST_ON_SHOW, GAMEPAD_AVA_ROOT_SCENE)
end

-- Override
function ZO_CampaignBrowser_Gamepad:SetupList(list)
    list:AddDataTemplate("ZO_GamepadNewMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadNewMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_CampaignBrowser_Gamepad:OnShowing()
    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    self:SetCurrentMode(CAMPAIGN_BROWSER_MODES.CAMPAIGN_RULESET_TYPES)

    -- need to update the content here because all the fragments have been removed,
    -- so we need to add the appropriate fragment back
    self:UpdateContentPane()

    self:RegisterEvents()

    self.dataRegistration:Refresh()

    QueryCampaignSelectionData()
end

function ZO_CampaignBrowser_Gamepad:OnHiding()
    ZO_Gamepad_ParametricList_Screen.OnHiding(self)

    self.dataRegistration:Refresh()

    self:UnregisterEvents()
end

------------
-- Update --
------------

function ZO_CampaignBrowser_Gamepad:PerformUpdate()
    if self.currentMode == CAMPAIGN_BROWSER_MODES.CAMPAIGN_RULESET_TYPES then
        self:BuildCampaignRulesetTypeList()
    else
        self:BuildCampaignList()
    end

    self:UpdateContentPane()
    self:RefreshScreenHeader()
end

function ZO_CampaignBrowser_Gamepad:GetCampaignQueryType(campaignId)
    if campaignId == GetAssignedCampaignId() then
        return BGQUERY_ASSIGNED_CAMPAIGN
    else
        return BGQUERY_LOCAL
    end
end

function ZO_CampaignBrowser_Gamepad:HasCampaignInformation(campaignId)
    return campaignId == GetAssignedCampaignId() or campaignId == GetCurrentCampaignId()
end

function ZO_CampaignBrowser_Gamepad:UpdateContentPane(updateFromTimer)
    local hideContent = true
    local hideScoring = true
    local hideEmperor = true
    local hideBonuses = true

    local targetData = self:GetTargetData()
    if targetData ~= nil then
        local displayContentType = targetData.displayContentType
        local queryType
        if displayContentType == CONTENT_TYPES.SCORING or
            displayContentType == CONTENT_TYPES.EMPERORSHIP or
            displayContentType == CONTENT_TYPES.BONUSES then
                queryType = self:GetCampaignQueryType(targetData.id)
        end

        if displayContentType == CONTENT_TYPES.CAMPAIGN then
            if not updateFromTimer then
                SCENE_MANAGER:AddFragment(GAMEPAD_AVA_CAMPAIGN_INFO_FRAGMENT)
            end
            self:RefreshCampaignInfoContent()
            hideContent = false
        elseif displayContentType == CONTENT_TYPES.SCORING then
            if not updateFromTimer then
                CAMPAIGN_SCORING_GAMEPAD:SetCampaignAndQueryType(targetData.id, queryType)
                SCENE_MANAGER:AddFragment(CAMPAIGN_SCORING_GAMEPAD_FRAGMENT)
            end
            hideScoring = false
        elseif displayContentType == CONTENT_TYPES.EMPERORSHIP then
            if not updateFromTimer then
                CAMPAIGN_EMPEROR_GAMEPAD:SetCampaignAndQueryType(targetData.id, queryType)
                SCENE_MANAGER:AddFragment(CAMPAIGN_EMPEROR_GAMEPAD_FRAGMENT)
            end
            hideEmperor = false
        elseif displayContentType == CONTENT_TYPES.BONUSES then
            if not updateFromTimer then
                CAMPAIGN_BONUSES_GAMEPAD:SetCampaignAndQueryType(targetData.id, queryType)
                SCENE_MANAGER:AddFragment(CAMPAIGN_BONUSES_GAMEPAD_FRAGMENT)
            end
            hideBonuses = false
        end
    end
    
    if hideContent then
        SCENE_MANAGER:RemoveFragment(GAMEPAD_AVA_CAMPAIGN_INFO_FRAGMENT)
    end
    if hideScoring then
        SCENE_MANAGER:RemoveFragment(CAMPAIGN_SCORING_GAMEPAD_FRAGMENT)
    end
    if hideEmperor then
        SCENE_MANAGER:RemoveFragment(CAMPAIGN_EMPEROR_GAMEPAD_FRAGMENT)
    end
    if hideBonuses then
        SCENE_MANAGER:RemoveFragment(CAMPAIGN_BONUSES_GAMEPAD_FRAGMENT)
    end

    local hideBackgroundAndHeader = hideScoring and hideContent and hideEmperor and hideBonuses
    if hideBackgroundAndHeader then
        GAMEPAD_AVA_ROOT_SCENE:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        self.contentHeader:SetHidden(true)
    else
        GAMEPAD_AVA_ROOT_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        self.contentHeader:SetHidden(false)
        self:RefreshContentHeader()
    end

    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
end

local POPULATION_ICONS =
{
    [CAMPAIGN_POP_LOW] = "EsoUI/Art/AvA/Gamepad/Server_Empty.dds",
    [CAMPAIGN_POP_MEDIUM] = "EsoUI/Art/AvA/Gamepad/Server_One.dds",
    [CAMPAIGN_POP_HIGH] = "EsoUI/Art/AvA/Gamepad/Server_Two.dds",
    [CAMPAIGN_POP_FULL] = "EsoUI/Art/AvA/Gamepad/Server_Full.dds",
}

local function GetPopulationIcon(population)
    return POPULATION_ICONS[population]
end

local function SetupPopulationIcon(control, data) 
    control.populationControl:SetTexture(GetPopulationIcon(data.population))

    local isFull = data.population == CAMPAIGN_POP_FULL
    control.lockedIconControl:SetHidden(not isFull)
    control.fullTextControl:SetHidden(not isFull)

    local queueWaitSeconds = GetSelectionCampaignQueueWaitTime(data.selectionIndex)
    if data.alliance == GetUnitAlliance("player") and queueWaitSeconds > 0 then
        --We don't want to show an estimate for seconds
        if queueWaitSeconds < 60 then
            queueWaitSeconds = 60
        end
        local queueWaitMs = queueWaitSeconds * 1000
        local textEstimatedTime = ZO_GetSimplifiedTimeEstimateText(queueWaitMs, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT, nil, ZO_TIME_ESTIMATE_STYLE.ARITHMETIC)
        control.estimatedWaitValueControl:SetText(textEstimatedTime)
        control.estimatedWaitControl:SetHidden(false)
    else
        control.estimatedWaitControl:SetHidden(true)
    end

    if isFull then
        control.factionControl:SetAlpha(0.5)
    else
        control.factionControl:SetAlpha(1.0)
    end
end

function ZO_CampaignBrowser_Gamepad:GetStateMessageText(campaignData)
    local queueData = campaignData.queue
    if queueData.isQueued and queueData.state ~= CAMPAIGN_QUEUE_REQUEST_STATE_FINISHED then
        local isLoading, message, messageIcon = CAMPAIGN_BROWSER_MANAGER:GetQueueMessage(queueData.id, queueData.isGroup, queueData.state)
        if not isLoading then
            message = message .. zo_iconFormat(messageIcon, 32, 32)
        end
        return ZO_SUCCEEDED_TEXT:Colorize(message)
    elseif not ZO_CampaignBrowser_DoesPlayerMatchAllianceLock(campaignData) then
        return CAMPAIGN_BROWSER_MANAGER:GenerateAllianceLockStatusMessage(campaignData)
    else
        return ""
    end
end

function ZO_CampaignBrowser_Gamepad:SetupStateMessage(stateMessageLabel, campaignData)
    local stateMessageText = self:GetStateMessageText(campaignData)

    if stateMessageText == "" then
        stateMessageLabel:SetHidden(true)
        self.campaignInfoRules:ClearAnchors()
        self.campaignInfoRules:SetAnchor(TOPLEFT, self.campaignInfoRulesContainer, TOPLEFT, 0, 0)
        self.campaignInfoRules:SetAnchor(TOPRIGHT, self.campaignInfoRulesContainer, TOPRIGHT, 0, 0)
    else
        stateMessageLabel:SetText(stateMessageText)
        stateMessageLabel:SetHidden(false)
        self.campaignInfoRules:ClearAnchors()
        self.campaignInfoRules:SetAnchor(TOPLEFT, stateMessageLabel, BOTTOMLEFT, 0, ZO_GAMEPAD_CONTENT_VERT_OFFSET_PADDING)
        self.campaignInfoRules:SetAnchor(TOPRIGHT, stateMessageLabel, BOTTOMRIGHT, 0, ZO_GAMEPAD_CONTENT_VERT_OFFSET_PADDING)
    end
end

function ZO_CampaignBrowser_Gamepad:RefreshCampaignInfoContent()
    local targetData = self:GetTargetData()

    if targetData and targetData.entryType ~= ENTRY_TYPES.CAMPAIGN_RULESET_TYPE then
        self:SetupStateMessage(self.campaignStateMessage, targetData)

        self.campaignInfoRules:SetText(GetCampaignRulesetDescription(targetData.rulesetId))

        local selectionIndex = targetData.selectionIndex
        SetupPopulationIcon(self.campaignInfoStats:GetNamedChild("AldmeriDominion"), {population = targetData.alliancePopulation1, selectionIndex = selectionIndex, alliance = ALLIANCE_ALDMERI_DOMINION})
        SetupPopulationIcon(self.campaignInfoStats:GetNamedChild("EbonheartPact"), {population = targetData.alliancePopulation2, selectionIndex = selectionIndex, alliance =  ALLIANCE_EBONHEART_PACT})
        SetupPopulationIcon(self.campaignInfoStats:GetNamedChild("DaggerfallCovenant"), {population = targetData.alliancePopulation3, selectionIndex = selectionIndex, alliance = ALLIANCE_DAGGERFALL_COVENANT})
    end
end

-------------------
-- Deferred Init --
-------------------

function ZO_CampaignBrowser_Gamepad:OnDeferredInitialize()
    local campaignInfo = self.control:GetNamedChild("CampaignInfo")
    local campaignRules = campaignInfo:GetNamedChild("Rules")

    self.campaignInfoStats = campaignInfo:GetNamedChild("Stats")
    self.campaignInfoRulesContainer = campaignRules
    self.campaignInfoRules = campaignRules:GetNamedChild("RulesContent") 
    self.campaignStateMessage = campaignRules:GetNamedChild("StateMessage")

    self.dataRegistration = ZO_CampaignDataRegistration:New("CampaignSelectorData", function() return GAMEPAD_AVA_ROOT_SCENE:IsShowing() end)

    ZO_CampaignDialogGamepad_Initialize(self)

    self.campaignList = self:GetMainList()
    self.campaignEntries = {}

    self.campaignRulesetTypeList = self:AddList("CampaignRulesetTypes")
    self.campaignRulesetTypes = {}

    self:InitializeHeader()

    -- These events need to be listened for whether we are showing or not
    -- If we are hidden, Update() will set the dirty flag and we will update when we next show
    CAMPAIGN_BROWSER_MANAGER:RegisterCallback("OnCampaignDataUpdated", function() self:Update() end)
    CAMPAIGN_BROWSER_MANAGER:RegisterCallback("OnCampaignQueueStateUpdated", function()
        self:Update()
        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
    end)
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_ASSIGNED_CAMPAIGN_CHANGED, function() self:Update() end)
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_PLAYER_DEAD, function() self:Update() end)
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_PLAYER_ALIVE, function() self:Update() end)
    --Only the group leader can leave when group queued. We add or remove the leave entry through this update
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_LEADER_UPDATE, function() self:Update() end)

    self:SetCurrentMode(CAMPAIGN_BROWSER_MODES.CAMPAIGN_RULESET_TYPES)
end

function ZO_CampaignBrowser_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if selectedData then
        self:UpdateContentPane()
    end
end

------------
-- Header --
------------

function ZO_CampaignBrowser_Gamepad:SetCampaignRulesetTypeFilter(campaignRulesetTypeFilter)
    self.campaignRulesetTypeFilter = campaignRulesetTypeFilter
end

function ZO_CampaignBrowser_Gamepad:SetCurrentMode(mode)
    self.currentMode = mode
    if mode == CAMPAIGN_BROWSER_MODES.CAMPAIGN_RULESET_TYPES then
        self:SetCurrentList(self.campaignRulesetTypeList)
    else
        self:SetCurrentList(self.campaignList)
    end
    self:Update()
end

function ZO_CampaignBrowser_Gamepad:InitializeHeader()
    local IS_PLURAL = false
    local IS_UPPER = false
    self.headerData = 
    {
        titleText = GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_CAMPAIGNS_HEADER),

        data1HeaderText = GetCurrencyName(CURT_ALLIANCE_POINTS, IS_PLURAL, IS_UPPER),

        data1Text = function(control)
            ZO_CurrencyControl_SetSimpleCurrency(control, CURT_ALLIANCE_POINTS, GetCurrencyAmount(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_CHARACTER), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
            return true
        end,

        data1TextNarration = function()
            return ZO_Currency_FormatGamepad(CURT_ALLIANCE_POINTS, GetCurrencyAmount(CURT_ALLIANCE_POINTS, CURRENCY_LOCATION_CHARACTER), ZO_CURRENCY_FORMAT_AMOUNT_ICON)
        end,
    }

    local rightPane = self.control:GetNamedChild("RightPane")
    local contentContainer = rightPane:GetNamedChild("ContentContainer")
    self.contentHeader = contentContainer:GetNamedChild("Header")

    self.contentHeaderData = {}
    ZO_GamepadGenericHeader_Initialize(self.contentHeader, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ZO_GAMEPAD_HEADER_LAYOUTS.CONTENT_HEADER_DATA_PAIRS_LINKED)
end

function ZO_CampaignBrowser_Gamepad:RefreshScreenHeader()
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

local function GetCampaignEndsHeaderText(targetData) 
    local headerDataText = GetString(SI_GAMEPAD_CAMPAIGN_SCORING_DURATION_REMAINING)
    local dataText

    local _, secondsRemaining = GetSelectionCampaignTimes(targetData.selectionIndex)
    if secondsRemaining > 0 then
        dataText = ZO_FormatTime(secondsRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_TWELVE_HOUR)
    else
        dataText = GetString(SI_GAMEPAD_CAMPAIGN_SCORING_DURATION_REMAINING_DONE)
    end

    return headerDataText, dataText
end

function ZO_CampaignBrowser_Gamepad:RefreshContentHeader()
    local targetData = self:GetTargetData()
    local headerData = self.contentHeaderData

    if targetData and not self.contentHeader:IsHidden() then
        -- Title
        if targetData.contentHeaderTitle then
            headerData.titleText = targetData.contentHeaderTitle
        else
            headerData.titleText = targetData.text
        end

        headerData.data1HeaderText = nil
        headerData.data1Text = nil
        headerData.data1TextNarration = nil
        headerData.data2HeaderText = nil
        headerData.data2Text = nil
        headerData.data3HeaderText = nil
        headerData.data3Text = nil
        headerData.data4HeaderText = nil
        headerData.data4Text = nil

        if targetData.entryType == ENTRY_TYPES.SCORING then
            -- Data 1
            headerData.data1HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_NEXT_SCORING_EVALUATION)
            headerData.data1Text = function(control)
                ZO_CampaignScoring_TimeUpdate(control, GetSecondsUntilCampaignScoreReevaluation)
                return true
            end
            headerData.data1TextNarration = function()
                local secondsRemaining = GetSecondsUntilCampaignScoreReevaluation(targetData.id)
                return ZO_FormatTime(secondsRemaining, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            end

            -- Data 2
            headerData.data2HeaderText, headerData.data2Text = GetCampaignEndsHeaderText(targetData)
        elseif targetData.entryType == ENTRY_TYPES.BONUSES then
            -- Data 1
            headerData.data1HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_BONUSES_HOME_KEEPS_HEADER)
            headerData.data1Text = function(control)
                local _, _, numHomeHeld, numTotalHome = GetAvAKeepScore(CAMPAIGN_BONUSES_GAMEPAD.campaignId, GetUnitAlliance("player"))
                return zo_strformat(GetString(SI_GAMEPAD_CAMPAIGN_BONUSES_HOME_KEEPS_HEADER_INFO), numHomeHeld, numTotalHome)
            end

            -- Data 2
            headerData.data2HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_BONUSES_ENEMY_KEEPS_HEADER)
            headerData.data2Text = function(control)
                local _, enemyKeepsHeld = GetAvAKeepScore(CAMPAIGN_BONUSES_GAMEPAD.campaignId, GetUnitAlliance("player"))
                return enemyKeepsHeld
            end

            -- Data 3
            headerData.data3HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_BONUSES_DEFENSIVE_SCROLLS_HEADER)
            headerData.data3Text = function(control)
                local _, enemyScrollsHeld = GetAvAArtifactScore(CAMPAIGN_BONUSES_GAMEPAD.campaignId, GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_DEFENSIVE)
                return enemyScrollsHeld
            end

            -- Data 4
            headerData.data4HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_BONUSES_OFFENSIVE_SCROLLS_HEADER)
            headerData.data4Text = function(control)
                local _, enemyScrollsHeld = GetAvAArtifactScore(CAMPAIGN_BONUSES_GAMEPAD.campaignId, GetUnitAlliance("player"), OBJECTIVE_ARTIFACT_OFFENSIVE)
                return enemyScrollsHeld
            end
        elseif targetData.entryType == ENTRY_TYPES.EMPERORSHIP then
            -- Data 1
            headerData.data1HeaderText = GetString(SI_CAMPAIGN_EMPEROR_NAME_HEADER)
            headerData.data1Text = function(control)
                if DoesCampaignHaveEmperor(targetData.id) then
                    local alliance, characterName, displayName = GetCampaignEmperorInfo(targetData.id)
                    if alliance ~= nil and characterName ~= nil and displayName ~= nil then
                        local userFacingName = ZO_GetPlatformUserFacingName(characterName, displayName)
                        if userFacingName ~= nil and userFacingName ~= "" then
                            return zo_strformat(GetString(SI_GAMEPAD_CAMPAIGN_EMPEROR_HEADER_NAME), ZO_GetLargeAllianceSymbolIcon(alliance), userFacingName)
                        else
                            return GetString(SI_CAMPAIGN_UNKNOWN_EMPEROR)
                        end
                    else
                        return GetString(SI_CAMPAIGN_UNKNOWN_EMPEROR)
                    end
                else
                    return GetString(SI_CAMPAIGN_NO_EMPEROR)
                end
            end

            -- Data 2
            headerData.data2HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_EMPEROR_REIGN_DURATION_HEADER)
            headerData.data2Text = function(control)
                local duration = GetCampaignEmperorReignDuration(targetData.id)
                return ZO_FormatTime(duration, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            end
        elseif self:DoesCampaignHaveSocialInfo(targetData) then
            -- Data 1
            headerData.data1HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_TOOLTIP_GROUP_MEMBERS)
            headerData.data1Text = zo_strformat(SI_GAMEPAD_CAMPAIGN_BROWSER_PEOPLE_AMOUNT, targetData.numGroupMembers)

            -- Data 2
            headerData.data2HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_TOOLTIP_FRIENDS)
            headerData.data2Text = zo_strformat(SI_GAMEPAD_CAMPAIGN_BROWSER_PEOPLE_AMOUNT, targetData.numFriends)

            -- Data 3
            headerData.data3HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_TOOLTIP_GUILD_MEMBERS)
            headerData.data3Text = zo_strformat(SI_GAMEPAD_CAMPAIGN_BROWSER_PEOPLE_AMOUNT, targetData.numGuildMembers)

            -- Data 4
            headerData.data4HeaderText, headerData.data4Text = GetCampaignEndsHeaderText(targetData)
        end

        ZO_GamepadGenericHeader_Refresh(self.contentHeader, headerData)
    end
end

--------------
-- Key Bind --
--------------

function ZO_CampaignBrowser_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = { 
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        
        { -- select
            keybind = "UI_SHORTCUT_PRIMARY",

            name = function()
                local targetData = self:GetTargetData()
                -- Contextual campaign action
                if targetData and targetData.entryType == ENTRY_TYPES.CAMPAIGN then
                    if self:CanEnter(targetData) then
                        -- enter campaign after queue
                        return GetString(SI_CAMPAIGN_BROWSER_ENTER_CAMPAIGN)
                    elseif self:CanQueueForCampaign(targetData) then
                        -- enter campaign queue
                        return GetString(SI_CAMPAIGN_BROWSER_QUEUE_CAMPAIGN)
                    end
                end

                return GetString(SI_GAMEPAD_SELECT_OPTION)
            end,

            callback = function()
                local targetData = self:GetTargetData()

                local entryType = targetData.entryType

                -- Contextual campaign action
                if entryType == ENTRY_TYPES.CAMPAIGN then
                    if self:CanEnter(targetData) then
                        entryType = ENTRY_TYPES.TRAVEL_TO_CAMPAIGN
                    elseif self:CanQueueForCampaign(targetData) then
                        entryType = ENTRY_TYPES.ENTER_CAMPAIGN
                    end
                end

                if entryType == ENTRY_TYPES.ENTER_CAMPAIGN then
                    self:DoQueueForCampaign(targetData)
                elseif entryType == ENTRY_TYPES.TRAVEL_TO_CAMPAIGN then
                    ConfirmCampaignEntry(targetData.id, targetData.isGroup, true)
                elseif entryType == ENTRY_TYPES.LEAVE_QUEUE then
                    self:DoLeaveCampaignQueue(targetData)
                elseif entryType == ENTRY_TYPES.SET_HOME then
                    self:DoSetHomeCampaign(targetData)
                elseif entryType == ENTRY_TYPES.BONUSES then
                    self:GetCurrentList():SetEnabled(false)
                    self:DeactivateCurrentList()
                    CAMPAIGN_BONUSES_GAMEPAD:Activate()
                    self:SetCurrentMode(CAMPAIGN_BROWSER_MODES.BONUSES)
                    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                elseif entryType == ENTRY_TYPES.ABANDON_CAMPAIGN then
                    self:DoAbandon(targetData)
                elseif entryType == ENTRY_TYPES.CAMPAIGN_RULESET_TYPE then
                    self:SetCampaignRulesetTypeFilter(targetData.rulesetType)
                    self:SetCurrentMode(CAMPAIGN_BROWSER_MODES.CAMPAIGNS)
                    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                end
            end,

            visible = function()
                local targetData = self:GetTargetData()
                if not targetData then
                    return false
                end

                if targetData.entryType == ENTRY_TYPES.CAMPAIGN then
                    return self:CanQueueForCampaign(targetData) or self:CanEnter(targetData)
                elseif targetData.entryType == ENTRY_TYPES.ENTER_CAMPAIGN then
                    return self:CanQueueForCampaign(targetData) or self:IsQueuedForCampaign(targetData)
                elseif targetData.entryType == ENTRY_TYPES.TRAVEL_TO_CAMPAIGN then
                    return self:CanEnter(targetData)
                elseif targetData.entryType == ENTRY_TYPES.LEAVE_QUEUE then
                    return self:CanLeaveCampaignQueue(targetData)
                elseif targetData.entryType == ENTRY_TYPES.SET_HOME then
                    return self:CanSetHomeCampaign(targetData)
                elseif targetData.entryType == ENTRY_TYPES.BONUSES then
                    return self.currentMode == CAMPAIGN_BROWSER_MODES.CAMPAIGNS and self:HasCampaignInformation(targetData.id)
                elseif targetData.entryType == ENTRY_TYPES.ABANDON_CAMPAIGN then
                    return true
                elseif targetData.entryType == ENTRY_TYPES.CAMPAIGN_RULESET_TYPE then
                    return true
                else
                    return false
                end
            end,

            enabled = function()
                local targetData = self:GetTargetData()
                if targetData then
                    if targetData.entryType == ENTRY_TYPES.ENTER_CAMPAIGN then
                        return not self:IsQueuedForCampaign(targetData)
                    elseif targetData.entryType == ENTRY_TYPES.ABANDON_CAMPAIGN then
                        return not self:IsQueuedForCampaign(targetData)
                    end
                end
                return true
            end
        },

        { -- back
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                if self.currentMode == CAMPAIGN_BROWSER_MODES.BONUSES then
                    CAMPAIGN_BONUSES_GAMEPAD:Deactivate()
                    self:GetCurrentList():SetEnabled(true)
                    self:ActivateCurrentList()
                    self:SetCurrentMode(CAMPAIGN_BROWSER_MODES.CAMPAIGNS)
                    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                elseif self.currentMode == CAMPAIGN_BROWSER_MODES.CAMPAIGNS then
                    self:SetCurrentMode(CAMPAIGN_BROWSER_MODES.CAMPAIGN_RULESET_TYPES)
                    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                else
                    SCENE_MANAGER:Hide(GAMEPAD_AVA_ROOT_SCENE_NAME)
                end
            end,
        },
        
        { -- set home campaign
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN),

            visible = function() 
                local targetData = self:GetTargetData()
                if not targetData then
                    return
                end

                if self.currentMode == CAMPAIGN_BROWSER_MODES.CAMPAIGNS and targetData.entryType == ENTRY_TYPES.CAMPAIGN then
                    return self:CanSetHomeCampaign(targetData)
                end

                return false
            end,

            callback = function() 
                local targetCampaignData = self:GetTargetData()
                self:DoSetHomeCampaign(targetCampaignData)
            end,
        },
        { -- Leave a non-home/local campaign
            keybind = "UI_SHORTCUT_RIGHT_STICK",

            name = GetString(SI_CAMPAIGN_BROWSER_LEAVE_QUEUE),

            callback = function()
                local targetData = self:GetTargetData()

                if targetData.entryType == ENTRY_TYPES.CAMPAIGN then
                    self:DoLeaveCampaignQueue(targetData)
                end
            end,

            visible = function()
                local targetData = self:GetTargetData()

                if targetData and targetData.entryType == ENTRY_TYPES.CAMPAIGN then
                    return self:CanLeaveCampaignQueue(targetData)
                end
                return false
            end,
        },
    }
    
    local function GetActiveList()
        if self.currentMode == CAMPAIGN_BROWSER_MODES.BONUSES then
            return CAMPAIGN_BONUSES_GAMEPAD.abilityList
        elseif self.currentMode == CAMPAIGN_BROWSER_MODES.CAMPAIGN_RULESET_TYPES then
            return self.campaignRulesetTypeList
        elseif self.currentMode == CAMPAIGN_BROWSER_MODES.CAMPAIGNS then
            return self.campaignList
        end
    end

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, GetActiveList)
end

------------
-- Events --
------------

function ZO_CampaignBrowser_Gamepad:RegisterEvents()
    self.control:SetHandler("OnUpdate", function(control, seconds) self:OnUpdate(control, seconds) end)
    self.nextUpdateTimeSeconds = 0

    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_CAMPAIGN_QUEUE_POSITION_CHANGED, function() self:OnCampaignQueuePositionChanged() end)
end

function ZO_CampaignBrowser_Gamepad:UnregisterEvents()
    self.control:SetHandler("OnUpdate", nil)

    EVENT_MANAGER:UnregisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_CAMPAIGN_QUEUE_POSITION_CHANGED)
end

function ZO_CampaignBrowser_Gamepad:OnUpdate(control, seconds)
    -- Many content pages contain countdown timers on them, so update every second to keep those fresh
    if seconds > self.nextUpdateTimeSeconds then
        self.nextUpdateTimeSeconds = zo_floor(seconds + 1)
        local UPDATE_FROM_TIMER = true
        self:UpdateContentPane(UPDATE_FROM_TIMER)
    end
end

------------------------------------------------------------------------------------------------------------

function ZO_CampaignBrowser_Gamepad:GetTargetData()
    local currentList = self:GetCurrentList()
    if currentList then
        return currentList:GetTargetData()
    end
    return nil
end

function ZO_CampaignBrowser_Gamepad:IsQueuedForCampaign(data)
    return IsQueuedForCampaign(data.id, CAMPAIGN_QUEUE_INDIVIDUAL)
end

function ZO_CampaignBrowser_Gamepad:CanEnter(data)
    return data.queue.state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING
end

do
    local PENDING_QUEUE_STATES = {
        [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_JOIN] = true,
        [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_LEAVE] = true,
        [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_ACCEPT] = true,
    }

    function ZO_CampaignBrowser_Gamepad:IsPendingQueueState(data)
        return PENDING_QUEUE_STATES[data.queue.state]
    end
end

function ZO_CampaignBrowser_Gamepad:CanSetHomeCampaign(data)
    return CAMPAIGN_BROWSER_MANAGER:CanSetHomeCampaign(data)
end

function ZO_CampaignBrowser_Gamepad:DoSetHomeCampaign(data)
    return CAMPAIGN_BROWSER_MANAGER:DoSetHomeCampaign(data)
end

function ZO_CampaignBrowser_Gamepad:CanLeaveCampaignQueue(data)
    return CAMPAIGN_BROWSER_MANAGER:CanLeaveCampaignQueue(data)
end

function ZO_CampaignBrowser_Gamepad:DoLeaveCampaignQueue(data)
    return CAMPAIGN_BROWSER_MANAGER:DoLeaveCampaignQueue(data)
end

function ZO_CampaignBrowser_Gamepad:DoAbandon(data)
    if internalassert(data.id == GetAssignedCampaignId()) then
        local lockTimeLeft = GetCampaignUnassignCooldown()
        if lockTimeLeft > 0 then
            ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG, { isAbandoning = true, id = data.id } )
        else
            ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_ABANDON_HOME_CONFIRM_DIALOG, { id = data.id }, { mainTextParams = self:GetTextParamsForAbandonHomeDialog() })
        end
    end
end

function ZO_CampaignBrowser_Gamepad:CanQueueForCampaign(data)
    return CAMPAIGN_BROWSER_MANAGER:CanQueueForCampaign(data)
end

function ZO_CampaignBrowser_Gamepad:DoQueueForCampaign(data)
    CAMPAIGN_BROWSER_MANAGER:DoQueueForCampaign(data.dataSource)
end

do
    local DEFAULT_GAMEPAD_CAMPAIGN_ITEM_SORT =
    {
        campaignSort = { tiebreaker = "name", isNumeric = true },
        name = { tiebreaker = "id" },
        id = { isId64 = true },
    }
    local HOME_CAMPAIGN_SORT_ID = -2 -- sort first, before campaign ruleset ids
    local LOCAL_CAMPAIGN_SORT_ID = -1 -- sort second, before campaign ruleset ids and after home campaign
    function ZO_CampaignBrowser_Gamepad:CreateAndSortCampaignEntries()
        local campaignDataList = CAMPAIGN_BROWSER_MANAGER:GetCampaignDataList()

        local assignedCampaign = GetAssignedCampaignId()
        local currentCampaign = GetCurrentCampaignId()

        ZO_ClearNumericallyIndexedTable(self.campaignEntries)
        for _, campaignData in ipairs(campaignDataList) do
            local campaignEntry = ZO_GamepadEntryData:New(campaignData.name)
            campaignEntry:SetDataSource(campaignData)
            campaignEntry.displayContentType = CONTENT_TYPES.CAMPAIGN
            campaignEntry.entryType = ENTRY_TYPES.CAMPAIGN

            local campaignRulesetName = GetCampaignRulesetName(campaignData.rulesetId)
            campaignEntry.contentHeaderTitle = zo_strformat(SI_GAMEPAD_CAMPAIGN_BROWSER_CONTENT_TITLE, campaignData.name, campaignRulesetName)

            if assignedCampaign == campaignData.id then
                if currentCampaign == campaignData.id then
                    campaignEntry.campaignAssignmentType = BGQUERY_ASSIGNED_AND_LOCAL
                else
                    campaignEntry.campaignAssignmentType = BGQUERY_ASSIGNED_CAMPAIGN
                end
                campaignEntry.campaignSort = HOME_CAMPAIGN_SORT_ID
                campaignEntry.headerText = GetString("SI_BATTLEGROUNDQUERYCONTEXTTYPE", BGQUERY_ASSIGNED_CAMPAIGN)
            elseif currentCampaign == campaignData.id then
                campaignEntry.campaignAssignmentType = BGQUERY_LOCAL
                campaignEntry.campaignSort = LOCAL_CAMPAIGN_SORT_ID
                campaignEntry.headerText = GetString("SI_BATTLEGROUNDQUERYCONTEXTTYPE", BGQUERY_LOCAL)
            else
                campaignEntry.campaignSort = campaignData.rulesetId
                campaignEntry.headerText = campaignRulesetName
            end

            campaignEntry.narrationText = function(listEntryData, listEntryControl)
                local narrations = {}
                -- Generate the standard parametric list entry narration
                ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(listEntryData, listEntryControl))

                --Generate the narration for the selected campaign screen
                ZO_AppendNarration(narrations, self:GetCampaignScreenNarration(listEntryData))
                return narrations
            end

            campaignEntry.queue = CAMPAIGN_BROWSER_MANAGER:CreateCampaignQueueData(campaignEntry, CAMPAIGN_QUEUE_INDIVIDUAL)

            campaignEntry:SetLocked(not ZO_CampaignBrowser_DoesPlayerMatchAllianceLock(campaignEntry))

            table.insert(self.campaignEntries, campaignEntry)
        end

        table.sort(self.campaignEntries, function(left, right) return ZO_TableOrderingFunction(left, right, "campaignSort", DEFAULT_GAMEPAD_CAMPAIGN_ITEM_SORT, ZO_SORT_ORDER_UP) end)
    end
end

do

    local function GetVerboseCampaignPopulationNarration(narrations, alliance, alliancePopulation)
        if alliancePopulation == nil then
            return
        end

        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetAllianceName(alliance)))

        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString("SI_CAMPAIGNPOPULATIONTYPE", alliancePopulation)))

        if alliancePopulation == CAMPAIGN_POP_FULL then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_SCREEN_NARRATION_LOCKED_ICON_NARRATION)))
        end
    end

    function ZO_CampaignBrowser_Gamepad:GetCampaignScreenNarration(listEntryData)
        local narrations = {}

        ZO_AppendNarration(narrations, ZO_GamepadGenericHeader_GetNarrationText(self.contentHeader, self.contentHeaderData))

        local targetData = self:GetTargetData()
        local displayContentType = targetData.displayContentType

        if displayContentType == CONTENT_TYPES.CAMPAIGN then
            local stateMessageText = self:GetStateMessageText(targetData)
            if stateMessageText ~= "" then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(stateMessageText))
            end

            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetCampaignRulesetDescription(targetData.rulesetId)))

            if targetData.dataSource ~= nil then
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_SERVER_POPULATION)))

                GetVerboseCampaignPopulationNarration(narrations, ALLIANCE_ALDMERI_DOMINION, targetData.dataSource.alliancePopulation1)
                GetVerboseCampaignPopulationNarration(narrations, ALLIANCE_EBONHEART_PACT, targetData.dataSource.alliancePopulation2)
                GetVerboseCampaignPopulationNarration(narrations, ALLIANCE_DAGGERFALL_COVENANT, targetData.dataSource.alliancePopulation3)
            end

            local selectedData = self:GetCurrentList():GetSelectedData()
            local queueWaitMinutes = GetSelectionCampaignQueueWaitTime(selectedData.selectionIndex) / 60
            if queueWaitMinutes > 0  then
                queueWaitMinutes = zo_max(queueWaitMinutes, 1)
        
                local timeText = zo_strformat(GetString(SI_TIME_FORMAT_MINUTES_DESC), zo_ceil(queueWaitMinutes))
                ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(GetString(SI_GAMEPAD_CAMPAIGN_DETAIL_INFO_FORMATTER), GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_ESTIMATED_WAIT), timeText)))
            end
        end

        return narrations
    end

end

function ZO_CampaignBrowser_Gamepad:GetFooterNarration()
    return CAMPAIGN_AVA_RANK_GAMEPAD:GetNarration()
end

function ZO_CampaignBrowser_Gamepad:CreateAndSortCampaignRulesetTypes()
    local campaignDataList = CAMPAIGN_BROWSER_MANAGER:GetCampaignDataList()

    ZO_ClearNumericallyIndexedTable(self.campaignRulesetTypes)
    for _, campaignData in ipairs(campaignDataList) do
        if not ZO_IsElementInNumericallyIndexedTable(self.campaignRulesetTypes, campaignData.rulesetType) then
            table.insert(self.campaignRulesetTypes, campaignData.rulesetType)
        end
    end
    table.sort(self.campaignRulesetTypes) -- sort by enum order
end

function ZO_CampaignBrowser_Gamepad:IsHomeCampaign(campaignEntry)
    return campaignEntry.campaignAssignmentType == BGQUERY_ASSIGNED_CAMPAIGN or campaignEntry.campaignAssignmentType == BGQUERY_ASSIGNED_AND_LOCAL
end

function ZO_CampaignBrowser_Gamepad:IsLocalCampaign(campaignEntry)
    return campaignEntry.campaignAssignmentType == BGQUERY_LOCAL or campaignEntry.campaignAssignmentType == BGQUERY_ASSIGNED_AND_LOCAL
end

function ZO_CampaignBrowser_Gamepad:DoesCampaignHaveScoreInfo(campaignEntry)
    return campaignEntry.campaignAssignmentType ~= nil and not campaignEntry.isImperialCityCampaign
end

function ZO_CampaignBrowser_Gamepad:DoesCampaignHaveSocialInfo(campaignEntry)
    -- IC can't be assigned, so there will never be any friends/guild members/group members to display
    return not campaignEntry.isImperialCityCampaign
end

function ZO_CampaignBrowser_Gamepad:IsHomeAndNotLocalCampaign(campaignEntry)
    return campaignEntry.campaignAssignmentType == BGQUERY_ASSIGNED_CAMPAIGN or campaignEntry.campaignAssignmentType == BGQUERY_ASSIGNED_AND_LOCAL
end

function ZO_CampaignBrowser_Gamepad:CreateCampaignRulesetTypeEntry(campaignRulesetType)
    local rulesetTypeName = GetString("SI_CAMPAIGNRULESETTYPE", campaignRulesetType)
    local rulesetTypeIcon = ZO_CampaignBrowser_GetGamepadIconForRulesetType(campaignRulesetType)
    local campaignTypeEntry = ZO_GamepadEntryData:New(rulesetTypeName, rulesetTypeIcon)
    campaignTypeEntry:SetIconTintOnSelection(true)
    campaignTypeEntry.rulesetType = campaignRulesetType
    campaignTypeEntry.displayContentType = CONTENT_TYPES.CAMPAIGN_RULESET_TYPE
    campaignTypeEntry.entryType = ENTRY_TYPES.CAMPAIGN_RULESET_TYPE

    return campaignTypeEntry
end

function ZO_CampaignBrowser_Gamepad:AddExpandedCampaignEntryToList(entries, sourceCampaignEntry, name, icon, contentType, entryType)
    local expandedEntry = ZO_GamepadEntryData:New(name, icon)
    expandedEntry:SetIconTintOnSelection(true)
    expandedEntry:SetDataSource(sourceCampaignEntry)
    expandedEntry.displayContentType = contentType
    expandedEntry.entryType = entryType

    table.insert(entries, expandedEntry)
end

function ZO_CampaignBrowser_Gamepad:CreateExpandedCampaignEntries(campaignEntry)
    local entries = {}
    -- ENTER CAMPAIGN
    if self:CanQueueForCampaign(campaignEntry) or (self:IsQueuedForCampaign(campaignEntry) and not self:CanEnter(campaignEntry)) then
        self:AddExpandedCampaignEntryToList(entries, campaignEntry, GetString(SI_CAMPAIGN_BROWSER_QUEUE_CAMPAIGN), ICON_ENTER, CONTENT_TYPES.CAMPAIGN, ENTRY_TYPES.ENTER_CAMPAIGN)
    end

    -- TRAVEL TO / LEAVE CAMPAIGN
    if self:CanEnter(campaignEntry) then
        self:AddExpandedCampaignEntryToList(entries, campaignEntry, GetString(SI_CAMPAIGN_BROWSER_ENTER_CAMPAIGN), ICON_TRAVEL, CONTENT_TYPES.CAMPAIGN, ENTRY_TYPES.TRAVEL_TO_CAMPAIGN)
        self:AddExpandedCampaignEntryToList(entries, campaignEntry, GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_LEAVE_CAMPAIGN), ICON_LEAVE, CONTENT_TYPES.CAMPAIGN, ENTRY_TYPES.LEAVE_QUEUE)
    elseif self:CanLeaveCampaignQueue(campaignEntry) and not self:IsPendingQueueState(campaignEntry) then
        -- LEAVE QUEUE
        self:AddExpandedCampaignEntryToList(entries, campaignEntry, GetString(SI_CAMPAIGN_BROWSER_LEAVE_QUEUE), ICON_LEAVE, CONTENT_TYPES.CAMPAIGN, ENTRY_TYPES.LEAVE_QUEUE)
    end

    -- SET HOME
    if not self:IsHomeCampaign(campaignEntry) and self:CanSetHomeCampaign(campaignEntry) then
        self:AddExpandedCampaignEntryToList(entries, campaignEntry, GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN), ICON_HOME, CONTENT_TYPES.CAMPAIGN, ENTRY_TYPES.SET_HOME)
    end

    -- BONUSES
    self:AddExpandedCampaignEntryToList(entries, campaignEntry, GetString(SI_CAMPAIGN_OVERVIEW_CATEGORY_BONUSES), ICON_BONUS, CONTENT_TYPES.BONUSES, ENTRY_TYPES.BONUSES)

    -- SCORING
    self:AddExpandedCampaignEntryToList(entries, campaignEntry, GetString(SI_CAMPAIGN_OVERVIEW_CATEGORY_SCORING), ICON_SCORING, CONTENT_TYPES.SCORING, ENTRY_TYPES.SCORING)

    -- EMPERORSHIP
    self:AddExpandedCampaignEntryToList(entries, campaignEntry, GetString(SI_CAMPAIGN_OVERVIEW_CATEGORY_EMPERORSHIP), ICON_EMPEROR, CONTENT_TYPES.EMPERORSHIP, ENTRY_TYPES.EMPERORSHIP)

    -- ABANDON
    if self:IsHomeAndNotLocalCampaign(campaignEntry) then
        self:AddExpandedCampaignEntryToList(entries, campaignEntry, GetString(SI_CAMPAIGN_BROWSER_ABANDON_CAMPAIGN), ICON_ABANDON, CONTENT_TYPES.CAMPAIGN, ENTRY_TYPES.ABANDON_CAMPAIGN)
    end

    return entries
end

function ZO_CampaignBrowser_Gamepad:BuildCampaignRulesetTypeList()
    self.campaignRulesetTypeList:Clear()
    self:CreateAndSortCampaignRulesetTypes()

    for _, campaignRulesetType in ipairs(self.campaignRulesetTypes) do
        self.campaignRulesetTypeList:AddEntry("ZO_GamepadNewMenuEntryTemplate", self:CreateCampaignRulesetTypeEntry(campaignRulesetType))
    end

    local DEFAULT_RESELECT = nil
    local BLOCK_SELECTION_CHANGED_CALLBACK = true
    self.campaignRulesetTypeList:Commit(DEFAULT_RESELECT, BLOCK_SELECTION_CHANGED_CALLBACK)
end

function ZO_CampaignBrowser_Gamepad:BuildCampaignList()
    self.campaignList:Clear()
    self:CreateAndSortCampaignEntries()

    local lastCampaignListHeaderText = nil
    for _, campaignEntry in ipairs(self.campaignEntries) do
        if campaignEntry.rulesetType == self.campaignRulesetTypeFilter then
            local entries
            if self:DoesCampaignHaveScoreInfo(campaignEntry) then
                entries = self:CreateExpandedCampaignEntries(campaignEntry)
            else
                entries = {campaignEntry}
            end

            for _, entry in ipairs(entries) do
                if lastCampaignListHeaderText ~= entry.headerText then
                    entry:SetHeader(entry.headerText)
                    self.campaignList:AddEntryWithHeader("ZO_GamepadNewMenuEntryTemplate", entry)
                    lastCampaignListHeaderText = entry.headerText
                else
                    self.campaignList:AddEntry("ZO_GamepadNewMenuEntryTemplate", entry)
                end
            end
        end
    end

    local DEFAULT_RESELECT = nil
    local BLOCK_SELECTION_CHANGED_CALLBACK = true
    self.campaignList:Commit(DEFAULT_RESELECT, BLOCK_SELECTION_CHANGED_CALLBACK)
end

function ZO_CampaignBrowser_Gamepad:GetPriceMessage(cost, hasEnough, useGold)
    if useGold then
        local goldIconMarkup = ZO_Currency_GetGamepadFormattedCurrencyIcon(CURT_MONEY)
        if hasEnough then
            return zo_strformat(ZO_SELECTED_TEXT:Colorize(GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_PRICE)), cost, goldIconMarkup)
        else
            return zo_strformat(ZO_ERROR_COLOR:Colorize(GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_PRICE)), cost, goldIconMarkup)
        end
    else
        local alliancePointIconMarkup = ZO_Currency_GetGamepadFormattedCurrencyIcon(CURT_ALLIANCE_POINTS)
        if hasEnough then
            return zo_strformat(ZO_SELECTED_TEXT:Colorize(GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_PRICE)), cost, alliancePointIconMarkup)
        else
            return zo_strformat(ZO_ERROR_COLOR:Colorize(GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_PRICE)), cost, alliancePointIconMarkup)
        end 
    end
end

function ZO_CampaignBrowser_Gamepad:GetTextParamsForAbandonHomeDialog()
    local homeCampaignId = GetAssignedCampaignId()
    local warning = zo_strformat(GetString(SI_ABANDON_HOME_CAMPAIGN_QUERY), GetCampaignName(homeCampaignId))

    local alliancePointCost = ZO_AbandonHomeCampaign_GetCost()
    local isFree = alliancePointCost == 0
    local costMessage
    if isFree then
        costMessage = GetString(SI_ABANDON_HOME_CAMPAIGN_FREE)
    else
        costMessage = ""
    end

    return {warning, costMessage}
end

function ZO_CampaignBrowser_Gamepad:OnCampaignQueuePositionChanged()
    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
end

function ZO_CampaignAvARank_Gamepad_OnInitialized(control)
    CAMPAIGN_AVA_RANK_GAMEPAD = CampaignAvARank:New(control)
end

function ZO_CampaignBrowser_Gamepad_Initialize(control)
    GAMEPAD_AVA_BROWSER = ZO_CampaignBrowser_Gamepad:New(control)
end

function ZO_AvAFactionPopulation_Gamepad_OnInitialize(control, alliance)
    local allianceTexture = nil
    if alliance == ALLIANCE_EBONHEART_PACT then
        allianceTexture = "EsoUI/Art/Campaign/Gamepad/gp_overview_allianceIcon_ebonheart.dds"
    elseif alliance == ALLIANCE_ALDMERI_DOMINION then
        allianceTexture = "EsoUI/Art/Campaign/Gamepad/gp_overview_allianceIcon_aldmeri.dds"
    elseif alliance == ALLIANCE_DAGGERFALL_COVENANT then
        allianceTexture = "EsoUI/Art/Campaign/Gamepad/gp_overview_allianceIcon_daggerfall.dds"
    end

    control.populationControl = control:GetNamedChild("Population")
    control.factionControl = control:GetNamedChild("Faction")
    control.allianceNameControl = control:GetNamedChild("AllianceName")
    control.lockedIconControl = control:GetNamedChild("LockedIcon")
    control.fullTextControl = control:GetNamedChild("FullText")
    control.estimatedWaitControl = control:GetNamedChild("EstimatedWait")
    control.estimatedWaitValueControl = control.estimatedWaitControl:GetNamedChild("Value")

    local r,g,b,a = GetInterfaceColor(INTERFACE_COLOR_TYPE_ALLIANCE, alliance)
    control.populationControl:SetColor(r,g,b,a)
    control.factionControl:SetTexture(allianceTexture)
    local allianceName = GetAllianceName(alliance)
    control.allianceNameControl:SetText(zo_strformat(GetString(SI_ALLIANCE_NAME), allianceName))
end