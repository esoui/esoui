local GAMEPAD_GUILD_HUB_SCENE_NAME = "gamepad_campaign_root"

local CAMPAIGN_BROWSER_MODES = {
    CAMPAIGNS = 1,
    BONUSES = 2,
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
}

local CONTENT_TYPES = 
{
    BONUSES = 1,
    SCORING = 2,
    EMPERORSHIP = 3,
    CAMPAIGN = 4,
}

local ICON_ENTER = "EsoUI/Art/Campaign/Gamepad/gp_campaign_menuIcon_enter.dds"
local ICON_TRAVEL = "EsoUI/Art/Campaign/Gamepad/gp_campaign_menuIcon_travel.dds"
local ICON_LEAVE = "EsoUI/Art/Campaign/Gamepad/gp_campaign_menuIcon_leave.dds"
local ICON_ABANDON = "EsoUI/Art/Campaign/Gamepad/gp_campaign_menuIcon_abandon.dds"
local ICON_HOME = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_home.dds"
local ICON_GUEST = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_guest.dds"
local ICON_BONUS = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_bonus.dds"
local ICON_SCORING = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_scoring.dds"
local ICON_EMPEROR = "EsoUI/Art/Campaign/Gamepad/gp_overview_menuIcon_emperor.dds"

ZO_CampaignBrowser_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_CampaignBrowser_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_CampaignBrowser_Gamepad:Initialize(control)
    self.control = control

    local ACTIVATE_LIST_ON_SHOW = false
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_LIST_ON_SHOW)

    self.currentMode = CAMPAIGN_BROWSER_MODES.CAMPAIGNS
    self.campaignBrowser = ZO_CampaignBrowser_Shared:New()

    GAMEPAD_AVA_ROOT_SCENE = ZO_Scene:New(GAMEPAD_GUILD_HUB_SCENE_NAME, SCENE_MANAGER)
    GAMEPAD_AVA_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            if(self.currentMode == CAMPAIGN_BROWSER_MODES.BONUSES) then
                self.currentMode = CAMPAIGN_BROWSER_MODES.CAMPAIGNS
            end
                
            self:PerformDeferredInitialization()

            self:Update()

            ZO_GamepadGenericHeader_Activate(self.header)

            self:RegisterEvents()
            
            self.dataRegistration:Refresh()
            
            QueryCampaignSelectionData()
        elseif newState == SCENE_HIDDEN then
            self.dataRegistration:Refresh()

            ZO_GamepadGenericHeader_Deactivate(self.header)

            self:UnregisterEvents()
        end
        
        ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
    end)
end

------------
-- Update --
------------

function ZO_CampaignBrowser_Gamepad:PerformUpdate()
    self:UpdateLists()
    self:UpdateContent()
end

function ZO_CampaignBrowser_Gamepad:UpdateLists()
    self:BuildCampaignList()
    self:SetCurrentList(self.campaignList)
    self:RefreshScreenHeader()
end

function ZO_CampaignBrowser_Gamepad:UpdateContent(updateFromTimer)
    local hideContent = true
    local hideScoring = true
    local hideEmperor = true
    local hideBonuses = true

    local targetData = self:GetTargetData()
    if(targetData ~= nil) then
        if(targetData.displayContentType == CONTENT_TYPES.CAMPAIGN) then
            if not updateFromTimer then
                SCENE_MANAGER:AddFragment(GAMEPAD_AVA_CAMPAIGN_INFO_FRAGMENT)
            end
            self:RefreshCampaignInfoContent()
            hideContent = false
        elseif(targetData.displayContentType == CONTENT_TYPES.SCORING) then
            if not updateFromTimer then
                CAMPAIGN_SCORING_GAMEPAD:SetCampaignAndQueryType(targetData.id, queryType)
                SCENE_MANAGER:AddFragment(CAMPAIGN_SCORING_GAMEPAD_FRAGMENT)
            end
            hideScoring = false 
        elseif(targetData.displayContentType == CONTENT_TYPES.EMPERORSHIP) then
            if not updateFromTimer then
                local queryType = BGQUERY_LOCAL
                if(targetData.id == GetAssignedCampaignId()) then
                    queryType = BGQUERY_ASSIGNED_CAMPAIGN
                end
                CAMPAIGN_EMPEROR_GAMEPAD:SetCampaignAndQueryType(targetData.id, queryType)
                SCENE_MANAGER:AddFragment(CAMPAIGN_EMPEROR_GAMEPAD_FRAGMENT)
            end
            hideEmperor = false 
        elseif(targetData.displayContentType == CONTENT_TYPES.BONUSES) then
            if not updateFromTimer then
                CAMPAIGN_BONUSES_GAMEPAD:SetCampaignAndQueryType(targetData.id, queryType)
                SCENE_MANAGER:AddFragment(CAMPAIGN_BONUSES_GAMEPAD_FRAGMENT)
            end
            hideBonuses = false
        end
    end

    if(hideContent) then
        SCENE_MANAGER:RemoveFragment(GAMEPAD_AVA_CAMPAIGN_INFO_FRAGMENT)
    end
    if(hideScoring) then
        SCENE_MANAGER:RemoveFragment(CAMPAIGN_SCORING_GAMEPAD_FRAGMENT)
    end
    if(hideEmperor) then
        SCENE_MANAGER:RemoveFragment(CAMPAIGN_EMPEROR_GAMEPAD_FRAGMENT)
    end
    if(hideBonuses) then
        SCENE_MANAGER:RemoveFragment(CAMPAIGN_BONUSES_GAMEPAD_FRAGMENT)
    end


    local hideAll = hideScoring and hideContent and hideEmperor and hideBonuses
    if(hideAll) then
        self.contentHeader:SetHidden(true)
        GAMEPAD_AVA_ROOT_SCENE:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
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

    local queueWaitSeconds = GetSelectionCampaignQueueWaitTime(data.campaignId)
    if data.alliance == GetUnitAlliance("player") and queueWaitSeconds > 0 then
        --We don't want to show an estimate for seconds
        if queueWaitSeconds < 60 then
            queueWaitSeconds = 60
        end
        queueWaitMs = queueWaitSeconds * 1000
        local textEstimatedTime = ZO_GetSimplifiedTimeEstimateText(queueWaitMs, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT, nil, ZO_TIME_ESTIMATE_STYLE.ARITHMETIC)
        control.estimatedWaitValueControl:SetText(textEstimatedTime)
        control.estimatedWaitControl:SetHidden(false)
    else
        control.estimatedWaitControl:SetHidden(true)
    end

    if(isFull) then
        control.factionControl:SetAlpha(0.5)
    else
        control.factionControl:SetAlpha(1.0)
    end
end

function ZO_CampaignBrowser_Gamepad:UpdateQueuedMessageControls(descriptionControl, id, isGroup, state)
    if state == CAMPAIGN_QUEUE_REQUEST_STATE_FINISHED then
        descriptionControl:SetHidden(true)
    else
        descriptionControl:SetHidden(false)
        local isLoading, message, messageIcon = self.campaignBrowser:GetQueueMessage(id, isGroup, state)
        if isLoading then
            descriptionControl:SetText(message)
        else
            local iconString = zo_iconFormat(messageIcon, 32, 32)
            descriptionControl:SetText(message..iconString)
        end
    end
end

function ZO_CampaignBrowser_Gamepad:UpdateQueueMessages(control, groupControl, data)
    local IS_GROUP = true
    local isGroupQueued = self:UpdateQueuedMessage(groupControl, data, IS_GROUP, data.queuedGroupState)
    local isIndividualQueued = self:UpdateQueuedMessage(control, data, not IS_GROUP, data.queuedIndividualState)
end

function ZO_CampaignBrowser_Gamepad:UpdateQueuedMessage(control, data, isGroup, state)
    local isQueued = IsQueuedForCampaign(data.id, isGroup)
    local descriptionControl = control
    self:UpdateQueuedMessageControls(descriptionControl, data.id, isGroup, state)
    return isQueued
end

function ZO_CampaignBrowser_Gamepad:RefreshCampaignInfoContent()
    local selectedData = self.campaignList:GetTargetData()

    if selectedData then
        self:UpdateQueueMessages(self.campaignQueueMessage, self.groupCampaignQueueMessage, selectedData)

        self.campaignInfoRules:SetText(GetCampaignRulesetDescription(selectedData.rulesetId))

        local campaignId = selectedData.id
        SetupPopulationIcon(self.campaignInfoStats:GetNamedChild("AldmeriDominion"), {population = selectedData.alliancePopulation1, campaignId = campaignId, alliance = ALLIANCE_ALDMERI_DOMINION})
        SetupPopulationIcon(self.campaignInfoStats:GetNamedChild("EbonheartPact"), {population = selectedData.alliancePopulation2, campaignId = campaignId, alliance =  ALLIANCE_EBONHEART_PACT})
        SetupPopulationIcon(self.campaignInfoStats:GetNamedChild("DaggerfallCovenant"), {population = selectedData.alliancePopulation3, campaignId = campaignId, alliance = ALLIANCE_DAGGERFALL_COVENANT})
    end
end

-------------------
-- Deferred Init --
-------------------

function ZO_CampaignBrowser_Gamepad:PerformDeferredInitialization()
    if self.deferredInitialied then return end
    self.deferredInitialied = true

    self:InitLastStates()

    local campaignInfo = self.control:GetNamedChild("CampaignInfo")
    local campaignRules = campaignInfo:GetNamedChild("Rules")

    self.campaignInfoStats = campaignInfo:GetNamedChild("Stats")
    self.campaignInfoRules = campaignRules:GetNamedChild("RulesContent") 
    self.campaignQueueMessage = campaignRules:GetNamedChild("QueueMessage")
    self.groupCampaignQueueMessage = campaignRules:GetNamedChild("GroupQueueMessage")
    
    self.dataRegistration = ZO_CampaignDataRegistration:New("CampaignSelectorData", function() return GAMEPAD_AVA_ROOT_SCENE:IsShowing() end)

    ZO_CampaignDialogGamepad_Initialize(self)

    self.campaignList = self:GetMainList()

    self:InitializeHeader()
end

function ZO_CampaignBrowser_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if selectedData then
        self:UpdateContent()
    end
end

function ZO_CampaignBrowser_Gamepad:InitLastStates()
    self.lastStates = { 
                        {}, 
                        {} 
                      }
end

------------
-- Header --
------------

function ZO_CampaignBrowser_Gamepad:SetCurrentMode(mode)
    self.currentMode = mode
end

function ZO_CampaignBrowser_Gamepad:InitializeHeader()
    self.headerData = {
        titleText = GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_CAMPAIGNS_HEADER),

        data1HeaderText = GetString(SI_CURRENCY_ALLIANCE_POINTS),

        data1Text = function(control)
            ZO_CurrencyControl_SetSimpleCurrency(control, CURT_ALLIANCE_POINTS, GetAlliancePoints(), ZO_GAMEPAD_CURRENCY_OPTIONS_LONG_FORMAT)
            return true
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

local function GetCampaignEndsHeaderText(selectedData) 
    local headerDataText = GetString(SI_GAMEPAD_CAMPAIGN_SCORING_DURATION_REMAINING)
    local dataText = nil

    local secondsRemaining = GetSecondsUntilCampaignEnd(selectedData.id)
    if(secondsRemaining > 0) then
        dataText = ZO_FormatTime(secondsRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_TWELVE_HOUR)
    else
        dataText = GetString(SI_GAMEPAD_CAMPAIGN_SCORING_DURATION_REMAINING_DONE)
    end

    return headerDataText, dataText
end

function ZO_CampaignBrowser_Gamepad:RefreshContentHeader()
    local selectedData = self:GetTargetData()
    local headerData = self.contentHeaderData
    
    if(selectedData and not self.contentHeader:IsHidden()) then
        -- Title
        if(selectedData.contentHeaderTitle) then
            headerData.titleText = selectedData.contentHeaderTitle
        else
            headerData.titleText = selectedData.text
        end

        
        if selectedData.entryType == ENTRY_TYPES.SCORING then
            -- Data 1
            headerData.data1HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_NEXT_SCORING_EVALUATION)
            headerData.data1Text = function(control)
                                    ZO_CampaignScoring_TimeUpdate(control, GetSecondsUntilCampaignScoreReevaluation)
                                    return true
            end

            -- Data 2
            headerData.data2HeaderText, headerData.data2Text = GetCampaignEndsHeaderText(selectedData)

            -- Data 3
            headerData.data3HeaderText = nil
            headerData.data3Text = nil

            -- Data 4
            headerData.data4HeaderText = nil
            headerData.data4Text = nil
        elseif selectedData.entryType == ENTRY_TYPES.BONUSES then
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

        elseif selectedData.entryType == ENTRY_TYPES.EMPERORSHIP then
            -- Data 1
            headerData.data1HeaderText = GetString(SI_CAMPAIGN_EMPEROR_NAME_HEADER)
            headerData.data1Text = function(control)
                                        if(DoesCampaignHaveEmperor(selectedData.id)) then
                                            local alliance, characterName, displayName = GetCampaignEmperorInfo(selectedData.id)
                                            local userFacingName = ZO_GetPlatformUserFacingName(characterName, displayName)
                                            return zo_strformat(GetString(SI_GAMEPAD_CAMPAIGN_EMPEROR_HEADER_NAME), GetAllianceSymbolIcon(alliance), userFacingName)
                                        else
                                            return GetString(SI_CAMPAIGN_NO_EMPEROR)
                                        end
            end

            -- Data 2
            headerData.data2HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_EMPEROR_REIGN_DURATION_HEADER)
            headerData.data2Text = function(control)
                                        local duration = GetCampaignEmperorReignDuration(selectedData.id)
                                        return ZO_FormatTime(duration, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            end

            -- Data 3
            headerData.data3HeaderText = nil
            headerData.data3Text = nil

            -- Data 4
            headerData.data4HeaderText = nil
            headerData.data4Text = nil
        else
            -- Data 1
            headerData.data1HeaderText = nil
            headerData.data1Text = nil

            if(selectedData.numGroupMembers) then
                headerData.data1HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_TOOLTIP_GROUP_MEMBERS)
                headerData.data1Text = zo_strformat(SI_GAMEPAD_CAMPAIGN_BROWSER_PEOPLE_AMOUNT, selectedData.numGroupMembers)
            end

            -- Data 2
            headerData.data2HeaderText = nil
            headerData.data2Text = nil

            if(selectedData.numFriends) then
                headerData.data2HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_TOOLTIP_FRIENDS)
                headerData.data2Text = zo_strformat(SI_GAMEPAD_CAMPAIGN_BROWSER_PEOPLE_AMOUNT, selectedData.numFriends)
            end

            -- Data 3
            headerData.data3HeaderText = nil
            headerData.data3Text = nil

            if(selectedData.numGuildMembers) then
                headerData.data3HeaderText = GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_TOOLTIP_GUILD_MEMBERS)
                headerData.data3Text = zo_strformat(SI_GAMEPAD_CAMPAIGN_BROWSER_PEOPLE_AMOUNT, selectedData.numGuildMembers)
            end

            -- Data 4
            headerData.data4HeaderText, headerData.data4Text = GetCampaignEndsHeaderText(selectedData)
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
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                local selectedData = self:GetTargetData()
                if(selectedData) then
                    if(selectedData.entryType == ENTRY_TYPES.ENTER_CAMPAIGN and self:CanQueue(selectedData)) then
                        self:DoQueue(selectedData)
                    elseif(selectedData.entryType == ENTRY_TYPES.TRAVEL_TO_CAMPAIGN and self:CanEnter(selectedData)) then
                        local isGroup = selectedData.isGroup or selectedData.queuedGroupState == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING
                        self.campaignBrowser:ShowCampaignQueueReadyDialog(selectedData.id, isGroup, selectedData.name)
                    elseif(selectedData.entryType == ENTRY_TYPES.LEAVE_QUEUE and self:IsQueued(selectedData)) then
                        self:DoLeave(selectedData)
                    elseif(selectedData.entryType == ENTRY_TYPES.SET_HOME) then
                        self:DoHome(selectedData)
                    elseif(selectedData.entryType == ENTRY_TYPES.BONUSES) then
						self:DeactivateCurrentList()
                        CAMPAIGN_BONUSES_GAMEPAD:Activate()
                        self:SetCurrentMode(CAMPAIGN_BROWSER_MODES.BONUSES)
                        PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                    elseif(selectedData.entryType == ENTRY_TYPES.ABANDON_CAMPAIGN) then
                        self:DoAbandon(selectedData)
                    end
                end
            end,

            visible = function() 
                local selectedData = self:GetTargetData()
                if(selectedData) then
                    if(selectedData.entryType == ENTRY_TYPES.ENTER_CAMPAIGN and (self:CanQueue(selectedData) or self:IsQueued(selectedData))) then
                        return true
                    elseif(selectedData.entryType == ENTRY_TYPES.TRAVEL_TO_CAMPAIGN and self:CanEnter(selectedData)) then
                        return true
                    elseif(selectedData.entryType == ENTRY_TYPES.LEAVE_QUEUE and self:IsQueued(selectedData)) then
                        return true
                    elseif(selectedData.entryType == ENTRY_TYPES.SET_HOME and self:CanHome(selectedData)) then
                        return true
                    elseif(selectedData.entryType == ENTRY_TYPES.BONUSES) then
                        if self.currentMode == CAMPAIGN_BROWSER_MODES.CAMPAIGNS then
                            return true
                        end
                    elseif(selectedData.entryType == ENTRY_TYPES.ABANDON_CAMPAIGN) then
                        return true
                    end

                    return false
                else
                    return false
                end
            end,

            enabled = function()
                local selectedData = self:GetTargetData()
                if(selectedData) then
                    if selectedData.entryType == ENTRY_TYPES.ENTER_CAMPAIGN and self:IsQueued(selectedData) then
                        return false
                    elseif selectedData.entryType == ENTRY_TYPES.ABANDON_CAMPAIGN and self:IsQueued(selectedData) then
                        return false
                    end
                end
                return true
            end
        },

        { -- back
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                if(self.currentMode == CAMPAIGN_BROWSER_MODES.BONUSES) then
                    CAMPAIGN_BONUSES_GAMEPAD:Deactivate()
                    self:ActivateCurrentList()
                    self:SetCurrentMode(CAMPAIGN_BROWSER_MODES.CAMPAIGNS)
                    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                else
                    SCENE_MANAGER:Hide(GAMEPAD_GUILD_HUB_SCENE_NAME)
                end
            end,
        },
        
        { -- set campaign
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_JOIN_CAMPAIGN),

            visible = function() 
                local selectedData = self:GetTargetData()
                if(not selectedData) then
                    return
                end

                if(self.currentMode == CAMPAIGN_BROWSER_MODES.CAMPAIGNS and selectedData.entryType == ENTRY_TYPES.CAMPAIGN) then
                    return self:CanHome(selectedData) or (self:CanGuest() and GetGuestCampaignId() ~= selectedData.id)
                end

                return false
            end,

            callback = function() 
                local selectedData = self:GetTargetData()
                ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_SELECT_DIALOG, { canHome = self:CanHome(selectedData), canGuest = self:CanGuest() and GetGuestCampaignId() ~= selectedData.id }, { mainTextParams = { selectedData.name } })
            end,
        },
    }
    
    local function GetActiveList()
        if self.currentMode == CAMPAIGN_BROWSER_MODES.BONUSES then
            return CAMPAIGN_BONUSES_GAMEPAD.abilityList
        else
            return self:GetMainList()
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

    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_CAMPAIGN_SELECTION_DATA_CHANGED, function() self:Update() end)
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_ASSIGNED_CAMPAIGN_CHANGED, function() self:Update() end)
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_GUEST_CAMPAIGN_CHANGED, function() self:Update() end)
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_CAMPAIGN_QUEUE_JOINED, function(_, campaignId, group) self:OnCampaignQueueJoined(campaignId) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_CAMPAIGN_QUEUE_LEFT, function(_, campaignId, group) self:OnCampaignQueueLeft(campaignId) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_CAMPAIGN_QUEUE_STATE_CHANGED, function(_, campaignId) self:OnCampaignQueueStateChanged(campaignId) end)
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_CAMPAIGN_QUEUE_POSITION_CHANGED, function() self:OnCampaignQueuePositionChanged() end)
end

function ZO_CampaignBrowser_Gamepad:UnregisterEvents()
    self.control:SetHandler("OnUpdate", nil)

    EVENT_MANAGER:UnregisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_CAMPAIGN_SELECTION_DATA_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_ASSIGNED_CAMPAIGN_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_GUEST_CAMPAIGN_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_CAMPAIGN_QUEUE_JOINED)
    EVENT_MANAGER:UnregisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_CAMPAIGN_QUEUE_LEFT)
    EVENT_MANAGER:UnregisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_CAMPAIGN_QUEUE_STATE_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("ZO_CampaignBrowser_Gamepad", EVENT_CAMPAIGN_QUEUE_POSITION_CHANGED)
end

function ZO_CampaignBrowser_Gamepad:OnUpdate(control, seconds)

    if(seconds > self.nextUpdateTimeSeconds) then
        self.nextUpdateTimeSeconds = zo_floor(seconds + 1)  -- Update on the second boundary

        local listUpdateRequired = false        
        for i = 1, #self.assignedCampaignData do
            local data = self.assignedCampaignData[i]
            if(data ~= nil) then
                local lastStateInfo = self.lastStates[i]
                if(lastStateInfo.groupState ~= data.queuedGroupState or lastStateInfo.soloState ~= data.queuedIndividualState) then
                    listUpdateRequired = true
                end

                lastStateInfo.groupState = data.queuedGroupState
                lastStateInfo.soloState = data.queuedIndividualState
            end
        end

        if(listUpdateRequired) then
            self:Update()
        else
            self:UpdateContent(true)
        end
    end
end

------------------------------------------------------------------------------------------------------------

function ZO_CampaignBrowser_Gamepad:GetTargetData()
    return self.campaignList:GetTargetData()
end

function ZO_CampaignBrowser_Gamepad:IsQueued(data)
    local IS_GROUP = true
    return IsQueuedForCampaign(data.id, IS_GROUP) or IsQueuedForCampaign(data.id, not IS_GROUP)
end

function ZO_CampaignBrowser_Gamepad:CanEnter(data)
    return data.queuedGroupState == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING or data.queuedIndividualState == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING
end

do
    local PENDING_QUEUE_STATES = {
        [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_JOIN] = true,
        [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_LEAVE] = true,
        [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_ACCEPT] = true,
    }

    function ZO_CampaignBrowser_Gamepad:IsPendingQueueState(data)
        return PENDING_QUEUE_STATES[data.queuedGroupState] or PENDING_QUEUE_STATES[data.queuedIndividualState]
    end
end

function ZO_CampaignBrowser_Gamepad:CanHome(data)
    return self.campaignBrowser:CanHome(data)
end

function ZO_CampaignBrowser_Gamepad:DoHome(data)
    if(data.type == self.campaignBrowser:GetCampaignType()) then
        local lockTimeLeft = GetCampaignReassignCooldown()
        if(lockTimeLeft > 0)  then
            ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG, { isHome = true, id = data.id } )
        else
            ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG, { id = data.id }, { mainTextParams = self:GetTextParamsForSetHomeDialog() })
        end
    end
end

function ZO_CampaignBrowser_Gamepad:CanGuest()
    return self.campaignBrowser:CanGuest(self:GetTargetData())
end

function ZO_CampaignBrowser_Gamepad:DoLeave(data)
    if data then
        local IS_GROUP = true
        local groupQueue = IsQueuedForCampaign(data.id, IS_GROUP)
        local individualQueue = IsQueuedForCampaign(data.id, not IS_GROUP)
        state = groupQueue and data.queuedGroupState or data.queuedIndividualState
        if groupQueue or individualQueue then
            if(state == CAMPAIGN_QUEUE_REQUEST_STATE_WAITING) then
                LeaveCampaignQueue(data.id, groupQueue)
            elseif(state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING) then
                ConfirmCampaignEntry(data.id, groupQueue, false)
            end
        end
    end
end

function ZO_CampaignBrowser_Gamepad:DoAbandon(data)
    if(data.id == GetAssignedCampaignId()) then
        local lockTimeLeft = GetCampaignUnassignCooldown()
        if(lockTimeLeft > 0)  then
            ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG, { isHome = true, isAbandoning = true, id = data.id } )
        else
            ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_ABANDON_HOME_CONFIRM_DIALOG, { id = data.id }, { mainTextParams = self:GetTextParamsForAbandonHomeDialog() })
        end
    elseif (data.id == GetGuestCampaignId()) then
        local lockTimeLeft = GetCampaignGuestCooldown()
        if(lockTimeLeft > 0)  then
            ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG, { isHome = false, isAbandoning = true, id = data.id } )
        else
            ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_ABANDON_GUEST_DIALOG)
        end
    end
end

function ZO_CampaignBrowser_Gamepad:GetCampaignBrowser()
    return self.campaignBrowser
end

function ZO_CampaignBrowser_Gamepad:CanQueue(data)
    return self.campaignBrowser:CanQueue(data)
end

function ZO_CampaignBrowser_Gamepad:DoQueue(data)
    self.campaignBrowser:DoQueue(data.dataSource)
end

local DEFAULT_GAMEPAD_CAMPAIGN_ITEM_SORT =
{
    campaignSort = { tiebreaker = "name", isNumeric = true },
    name = { tiebreaker = "id" },
    id = { isId64 = true },
}

function ZO_CampaignBrowser_Gamepad:AddCampaignListEntry(data, headerText)
    if(not self.headerAlreadyAddedToCampaignList) then
        data:SetHeader(headerText)
        self.campaignList:AddEntryWithHeader("ZO_GamepadMenuEntryTemplate", data)
        self.headerAlreadyAddedToCampaignList = true
    else
        self.campaignList:AddEntry("ZO_GamepadMenuEntryTemplate", data)
    end
end

function ZO_CampaignBrowser_Gamepad:AddCampaignDataToList(data, name, icon, contentType, entryType)
    local itemData = ZO_GamepadEntryData:New(name, icon)
    itemData:SetIconTintOnSelection(true)
    itemData:SetDataSource(data)
    itemData.displayContentType = contentType
    itemData.entryType = entryType
    self:AddCampaignListEntry(itemData, data.headerText)
end

function ZO_CampaignBrowser_Gamepad:CollectAssignedCampaignData()
    local masterList = self.campaignBrowser:BuildMasterList()

    local assignedCampaign = GetAssignedCampaignId()
    local guestCampaign = GetGuestCampaignId()

    local homeIndex = nil
    local guestIndex = nil

    for i = 1, #masterList do
        local headerText = nil
        local campaignInfo = masterList[i]
        
        if assignedCampaign == campaignInfo.id then
            homeIndex = i
            headerText = GetString(SI_GAMEPAD_CAMPAIGN_HOME_CAMPAIGN)
        elseif guestCampaign == campaignInfo.id then
            guestIndex = i
            headerText = GetString(SI_GAMEPAD_CAMPAIGN_GUEST_CAMPAIGN)
        end

        local campaignEntry = ZO_GamepadEntryData:New(campaignInfo.name)
        campaignEntry:SetDataSource(campaignInfo)
        campaignEntry.bestItemCategoryName = GetCampaignRulesetName(campaignInfo.rulesetId)
        campaignEntry.campaignSort = campaignInfo.rulesetId
        campaignEntry.displayContentType = CONTENT_TYPES.CAMPAIGN
        campaignEntry.entryType = ENTRY_TYPES.CAMPAIGN
        campaignEntry.headerText = headerText
        campaignEntry.contentHeaderTitle = zo_strformat(SI_GAMEPAD_CAMPAIGN_BROWSER_CONTENT_TITLE, campaignInfo.name, campaignEntry.bestItemCategoryName)

        self.masterList[i] = campaignEntry
    end

    if(homeIndex) then
        table.insert(self.assignedCampaignData, self.masterList[homeIndex])
    end
    if(guestIndex) then
        table.insert(self.assignedCampaignData, self.masterList[guestIndex])
    end
end

function ZO_CampaignBrowser_Gamepad:AddAssignedCampaignsToList()
	local guestCampaign = GetGuestCampaignId()

    for i = 1, #self.assignedCampaignData do
        local data = self.assignedCampaignData[i]
        if(data ~= nil) then
            self.headerAlreadyAddedToCampaignList = false

            -- ENTER CAMPAIGN
            if(self:CanQueue(data) or (self:IsQueued(data) and not self:CanEnter(data))) then
                self:AddCampaignDataToList(data, GetString(SI_CAMPAIGN_BROWSER_QUEUE_CAMPAIGN), ICON_ENTER, CONTENT_TYPES.CAMPAIGN, ENTRY_TYPES.ENTER_CAMPAIGN)
            end

            -- TRAVEL TO / Leave CAMPAIGN
            if(self:CanEnter(data)) then
                self:AddCampaignDataToList(data, GetString(SI_CAMPAIGN_BROWSER_ENTER_CAMPAIGN), ICON_TRAVEL, CONTENT_TYPES.CAMPAIGN, ENTRY_TYPES.TRAVEL_TO_CAMPAIGN)
                self:AddCampaignDataToList(data, GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_LEAVE_CAMPAIGN), ICON_LEAVE, CONTENT_TYPES.CAMPAIGN, ENTRY_TYPES.LEAVE_QUEUE)
            elseif(self:IsQueued(data) and not self:IsPendingQueueState(data)) then
                -- LEAVE QUEUE
                self:AddCampaignDataToList(data, GetString(SI_CAMPAIGN_BROWSER_LEAVE_QUEUE), ICON_LEAVE, CONTENT_TYPES.CAMPAIGN, ENTRY_TYPES.LEAVE_QUEUE)
            end

            -- SET HOME
            if guestCampaign == data.id and self:CanHome(data) then
                self:AddCampaignDataToList(data, GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN), ICON_HOME, CONTENT_TYPES.CAMPAIGN, ENTRY_TYPES.SET_HOME)
            end

            -- BONUSES
            self:AddCampaignDataToList(data, GetString(SI_CAMPAIGN_OVERVIEW_CATEGORY_BONUSES), ICON_BONUS, CONTENT_TYPES.BONUSES, ENTRY_TYPES.BONUSES)

            -- SCORING
            self:AddCampaignDataToList(data, GetString(SI_CAMPAIGN_OVERVIEW_CATEGORY_SCORING), ICON_SCORING, CONTENT_TYPES.SCORING, ENTRY_TYPES.SCORING)

            -- EMPERORSHIP
            self:AddCampaignDataToList(data, GetString(SI_CAMPAIGN_OVERVIEW_CATEGORY_EMPERORSHIP), ICON_EMPEROR, CONTENT_TYPES.EMPERORSHIP, ENTRY_TYPES.EMPERORSHIP)

            -- ABANDON
            self:AddCampaignDataToList(data, GetString(SI_CAMPAIGN_BROWSER_ABANDON_CAMPAIGN), ICON_ABANDON, CONTENT_TYPES.CAMPAIGN, ENTRY_TYPES.ABANDON_CAMPAIGN)

            -- Store current state so we can use it to check for changes in OnUpdate
            self.lastStates[i].groupState = data.queuedGroupState
            self.lastStates[i].soloState = data.queuedIndividualState
        end
    end
end

function ZO_CampaignBrowser_Gamepad:AddNonAssignedCampaignsToList()

    table.sort(self.masterList, function(left, right) return ZO_TableOrderingFunction(left, right, "campaignSort", DEFAULT_GAMEPAD_CAMPAIGN_ITEM_SORT, ZO_SORT_ORDER_UP) end)

    local assignedCampaign = GetAssignedCampaignId()
    local guestCampaign = GetGuestCampaignId()

    local lastBestItemCategoryName
    for i, itemData in ipairs(self.masterList) do
        -- Home and Guest index locations are already added above in detail so skip them when adding in the other campaigns
        if assignedCampaign ~= itemData.id and guestCampaign ~= itemData.id then
            if itemData.bestItemCategoryName ~= lastBestItemCategoryName then
                lastBestItemCategoryName = itemData.bestItemCategoryName
                itemData:SetHeader(itemData.bestItemCategoryName)            
                self.campaignList:AddEntryWithHeader("ZO_GamepadMenuEntryTemplate", itemData)
            else
                self.campaignList:AddEntry("ZO_GamepadMenuEntryTemplate", itemData)
            end
        end
    end
end

function ZO_CampaignBrowser_Gamepad:BuildCampaignList()
    local previousSelectedData = self:GetTargetData()

    self.masterList = {}
    self.assignedCampaignData = {}  
    self:InitLastStates()
    self.campaignList:Clear()

    self:CollectAssignedCampaignData()
    self:AddAssignedCampaignsToList()
    self:AddNonAssignedCampaignsToList()
    
    local BLOCK_SELECTION_CHANGED_CALLBACK = true
    self.campaignList:Commit(nil, BLOCK_SELECTION_CHANGED_CALLBACK)

    if self.currentMode == CAMPAIGN_BROWSER_MODES.BONUSES then
        local function ReselectBonus(data)
            if previousSelectedData.entryType == ENTRY_TYPES.BONUSES and data.entryType == ENTRY_TYPES.BONUSES then
                if previousSelectedData.dataSource.text == data.dataSource.text then
                    return true
                end
            end

            return false
        end
        self.campaignList:SetSelectedDataByEval(ReselectBonus)
    end
end

function ZO_CampaignBrowser_Gamepad:GetPriceMessage(cost, hasEnough, useGold)
    if useGold then
        if hasEnough then
            return zo_strformat(GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_GOLD_PRICE), cost)
        else
            return zo_strformat(GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_GOLD_PRICE_NOT_ENOUGH), cost)
        end
    else
        if hasEnough then
            return zo_strformat(GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_PRICE), cost)
        else
            return zo_strformat(GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_PRICE_NOT_ENOUGH), cost)
        end 
    end

end

function ZO_CampaignBrowser_Gamepad:GetTextParamsForSetHomeDialog()
    local nowCost, endCost = ZO_SelectHomeCampaign_GetCost()
    local isFree = nowCost == 0
    local numAlliancePoints = GetAlliancePoints()
    local hasEnough = nowCost <= numAlliancePoints

    local warning = GetString(SI_SELECT_CAMPAIGN_COOLDOWN_WARNING)
    local costMessage = nil

    if isFree then
        costMessage = GetString(SI_SELECT_HOME_CAMPAIGN_FREE)
    else
        local priceMessage = self:GetPriceMessage(nowCost, hasEnough)
        costMessage = zo_strformat(GetString(SI_GAMEPAD_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN_COST), priceMessage)
    end

    return {warning, costMessage}
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

function ZO_CampaignBrowser_Gamepad:OnCampaignQueueJoined(campaignId)
    local data = self.campaignBrowser:GetDataByCampaignId(campaignId)
    self.campaignBrowser:SetupQueuedData(data)
    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
end

function ZO_CampaignBrowser_Gamepad:OnCampaignQueueLeft(campaignId)
    local data = self.campaignBrowser:GetDataByCampaignId(campaignId)
    self.campaignBrowser:SetupQueuedData(data)
    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
end

function ZO_CampaignBrowser_Gamepad:OnCampaignQueueStateChanged(campaignId)
    local data = self.campaignBrowser:GetDataByCampaignId(campaignId)
    self.campaignBrowser:SetupQueuedData(data)
    KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
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
    if(alliance == ALLIANCE_EBONHEART_PACT) then
        allianceTexture = "EsoUI/Art/Campaign/Gamepad/gp_overview_allianceIcon_ebonheart.dds"
    elseif(alliance == ALLIANCE_ALDMERI_DOMINION) then
        allianceTexture = "EsoUI/Art/Campaign/Gamepad/gp_overview_allianceIcon_aldmeri.dds"
    elseif(alliance == ALLIANCE_DAGGERFALL_COVENANT) then
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