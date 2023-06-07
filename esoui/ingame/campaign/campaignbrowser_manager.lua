-- TODO: replace with CAMPAIGN_QUEUE_TYPE enum
-- this is used where the API expects a bool isGroup value instead of the enum
CAMPAIGN_QUEUE_INDIVIDUAL = false
CAMPAIGN_QUEUE_GROUP = true

ZO_CAMPAIGN_DATA_TYPE_CAMPAIGN = 1
ZO_CAMPAIGN_DATA_TYPE_QUEUE = 2

ZO_CAMPAIGN_QUEUE_STEP_INITIAL = 1
ZO_CAMPAIGN_QUEUE_STEP_COLLECTIBLE_CHECK = 2
ZO_CAMPAIGN_QUEUE_STEP_QUEUED_AS_GUEST_CHECK = 3
ZO_CAMPAIGN_QUEUE_STEP_ALLIANCE_LOCK_CHECK = 4
ZO_CAMPAIGN_QUEUE_STEP_SELECT_QUEUE_TYPE = 5
ZO_CAMPAIGN_QUEUE_STEP_PERFORM_QUEUE = 6

ZO_CampaignBrowser_Manager = ZO_CallbackObject:Subclass()

function ZO_CampaignBrowser_Manager:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_CampaignBrowser_Manager:Initialize()
    self.selectionCampaignList = {}
    self.campaignRulesetsByType = {}
    self:RebuildCampaignData()

    local function OnCampaignSelectionDataChanged()
        self:RebuildCampaignData()
    end
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowserManager", EVENT_CAMPAIGN_SELECTION_DATA_CHANGED, OnCampaignSelectionDataChanged)

    local function OnCampaignQueueChanged(eventCode, campaignId)
        local campaignData = self:GetDataByCampaignId(campaignId)
        if campaignData then
            self:UpdateQueueDataState(campaignData)
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowserManager", EVENT_CAMPAIGN_QUEUE_JOINED, OnCampaignQueueChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowserManager", EVENT_CAMPAIGN_QUEUE_LEFT, OnCampaignQueueChanged)
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowserManager", EVENT_CAMPAIGN_QUEUE_STATE_CHANGED, OnCampaignQueueChanged)

    local function OnCampaignAllianceLockActivated(_, campaignId, lockedToAlliance)
        local campaignData = self:GetDataByCampaignId(campaignId)
        if campaignData then
            campaignData.lockedToAlliance = lockedToAlliance
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_CampaignBrowserManager", EVENT_CAMPAIGN_ALLIANCE_LOCK_ACTIVATED, OnCampaignAllianceLockActivated)
end

do
    local function IsCampaignData(data)
        return data and data.type == ZO_CAMPAIGN_DATA_TYPE_CAMPAIGN
    end

    local function IsQueueData(data)
        return data and data.type == ZO_CAMPAIGN_DATA_TYPE_QUEUE
    end

    function ZO_CampaignBrowser_Manager:CanSetHomeCampaign(data)
        if IsCampaignData(data) then
            return not data.isImperialCityCampaign and GetAssignedCampaignId() ~= data.id and DoesPlayerMeetCampaignRequirements(data.id)
        end
        return false
    end

    function ZO_CampaignBrowser_Manager:DoSetHomeCampaign(data)
        if IsCampaignData(data) then
            if not ZO_CampaignBrowser_DoesPlayerMatchAllianceLock(data) then
                ZO_Dialogs_ShowPlatformDialog("CAMPAIGN_ALLIANCE_LOCKED", { campaignData = data } )
            else
                if IsInGamepadPreferredMode() then
                    local lockTimeLeft = GetCampaignReassignCooldown()
                    if lockTimeLeft > 0 then
                        ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_LOCKED_DIALOG, { id = data.id, campaignData = data } )
                    else
                        ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_SET_HOME_REVIEW_DIALOG, { id = data.id, campaignData = data })
                    end
                else
                    SELECT_HOME_CAMPAIGN_DIALOG:Show(data)
                end
            end
        end
    end

    function ZO_CampaignBrowser_Manager:IsPlayerInSameCampaignType(targetCampaignData)
        local currentCampaignId = GetCurrentCampaignId() 
        if currentCampaignId == targetCampaignData.id then
            return true
        end

        local currentCampaignData = self:GetDataByCampaignId(currentCampaignId) 
        if currentCampaignData == nil then
            return false
        end

        return currentCampaignData.isImperialCityCampaign == targetCampaignData.isImperialCityCampaign
    end

    function ZO_CampaignBrowser_Manager:CanQueueForCampaign(data)
        local canQueueIndividual = false
        local canQueueGroup = false
        if IsCampaignData(data) and not self:IsPlayerInSameCampaignType(data) and not IsQueuedForCampaign(data.id, CAMPAIGN_QUEUE_INDIVIDUAL) and DoesPlayerMeetCampaignRequirements(data.id) then
            if not IsActiveWorldBattleground() and not IsUnitDead("player") then
                canQueueIndividual = true
            end

            if canQueueIndividual and IsUnitGrouped("player") then
                canQueueGroup = true
            end
        end
        return canQueueIndividual, canQueueGroup
    end

    function ZO_CampaignBrowser_Manager:DoQueueForCampaign(data)
        if IsCampaignData(data) then
            local NO_QUEUE_TYPE = nil
            self:ContinueQueueForCampaignFlow(data, ZO_CAMPAIGN_QUEUE_STEP_INITIAL, NO_QUEUE_TYPE)
        end
    end

    function ZO_CampaignBrowser_Manager:ContinueQueueForCampaignFlow(campaignData, lastQueueStepExecuted, queueType)
        -- Queue steps are used to create an asynchronous flow that can be restarted by each individual dialog in the flow.
        -- each dialog knows which step it "comes from", but not which one it "goes to" so we can reorder them without changing each dialog.
        -- To finish a step without needing to stop and restart execution, we can just increment the step.
        local currentQueueStep = lastQueueStepExecuted + 1

        if currentQueueStep == ZO_CAMPAIGN_QUEUE_STEP_COLLECTIBLE_CHECK then
            if campaignData.isImperialCityCampaign then
                local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(GetImperialCityCollectibleId())
                if not collectibleData:IsUnlocked() then
                    local collectibleName = collectibleData:GetName()
                    local categoryName = collectibleData:GetCategoryData():GetName()
                    local message = GetString(SI_COLLECTIBLE_LOCKED_FAILURE_CAUSED_BY_CAMPAIGN_QUEUE)
                    local marketOperation = MARKET_OPEN_OPERATION_DLC_FAILURE_CAMPAIGN_QUEUE
                    ZO_Dialogs_ShowPlatformDialog("COLLECTIBLE_REQUIREMENT_FAILED", { collectibleData = collectibleData, marketOpenOperation = marketOperation }, { mainTextParams = { message, collectibleName, categoryName } })
                    return
                end
            end
            currentQueueStep = currentQueueStep + 1
        end

        if currentQueueStep == ZO_CAMPAIGN_QUEUE_STEP_QUEUED_AS_GUEST_CHECK then
            if campaignData.id ~= GetAssignedCampaignId() then
                TUTORIAL_SYSTEM:TriggerTutorialWithDeferredAction(TUTORIAL_TRIGGER_QUEUED_FOR_CAMPAIGN_AS_GUEST, function()
                    self:ContinueQueueForCampaignFlow(campaignData, ZO_CAMPAIGN_QUEUE_STEP_QUEUED_AS_GUEST_CHECK)
                end)
                return
            end
            currentQueueStep = currentQueueStep + 1
        end

        if currentQueueStep == ZO_CAMPAIGN_QUEUE_STEP_ALLIANCE_LOCK_CHECK then
            if not ZO_CampaignBrowser_DoesPlayerMatchAllianceLock(campaignData) then
                ZO_Dialogs_ShowPlatformDialog("CAMPAIGN_ALLIANCE_LOCKED", {campaignData = campaignData})
                return
            elseif ZO_CampaignBrowserDialogs_ShouldShowAllianceLockWarning(campaignData) then
                ZO_Dialogs_ShowPlatformDialog("CAMPAIGN_ABOUT_TO_ALLIANCE_LOCK", {campaignData = campaignData})
                return
            end
            currentQueueStep = currentQueueStep + 1
        end

        if currentQueueStep == ZO_CAMPAIGN_QUEUE_STEP_SELECT_QUEUE_TYPE then
            local canQueueIndividual, canQueueGroup = self:CanQueueForCampaign(campaignData)
            if canQueueIndividual and canQueueGroup then
                if IsInGamepadPreferredMode() then
                    local campaignRulesetTypeString = GetString("SI_CAMPAIGNRULESETTYPE", campaignData.rulesetType)
                    ZO_Dialogs_ShowGamepadDialog(ZO_GAMEPAD_CAMPAIGN_QUEUE_DIALOG, {campaignData = campaignData}, {mainTextParams = {campaignRulesetTypeString, campaignData.name}})
                    return
                else
                    ZO_Dialogs_ShowDialog("CAMPAIGN_QUEUE", {campaignData = campaignData})
                    return
                end
            elseif canQueueIndividual then
                queueType = CAMPAIGN_QUEUE_TYPE_INDIVIDUAL
            elseif canQueueGroup then
                queueType = CAMPAIGN_QUEUE_TYPE_GROUP
            end
            currentQueueStep = currentQueueStep + 1
        end

        if currentQueueStep == ZO_CAMPAIGN_QUEUE_STEP_PERFORM_QUEUE then
            internalassert(queueType ~= nil, "Campaign queue flow completed without picking a queue type")
            local isGroup = queueType == CAMPAIGN_QUEUE_TYPE_GROUP
            QueueForCampaign(campaignData.id, isGroup)
            return
        end
    end

    function ZO_CampaignBrowser_Manager:CanLeaveCampaignQueue(data)
        if IsCampaignData(data) then
            local queueData = data.queue
            return CanLeaveCampaignQueue(queueData.id, queueData.isGroup) == LEAVE_CAMPAIGN_QUEUE_ERROR_NONE
        end
        return false
    end

    function ZO_CampaignBrowser_Manager:DoLeaveCampaignQueue(data)
        if IsCampaignData(data) then
            local queueData = data.queue
            if IsQueuedForCampaign(queueData.id, queueData.isGroup) then
                if queueData.state == CAMPAIGN_QUEUE_REQUEST_STATE_WAITING then
                    LeaveCampaignQueue(queueData.id, queueData.isGroup)
                elseif queueData.state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING then
                    ConfirmCampaignEntry(queueData.id, queueData.isGroup, false)
                end
            end
        end
    end
end

do
    local function CompareRulesetsByDuration(rulesetIdA, rulesetIdB)
        return (GetCampaignRulesetDurationInSeconds(rulesetIdA) > GetCampaignRulesetDurationInSeconds(rulesetIdB))
    end

    function ZO_CampaignBrowser_Manager:RebuildCampaignData()
        -- Get Campaign Data
        ZO_ClearNumericallyIndexedTable(self.selectionCampaignList)

        for selectionIndex = 1, GetNumSelectionCampaigns() do
            local campaignId = GetSelectionCampaignId(selectionIndex)
            local rulesetId = GetCampaignRulesetId(campaignId)

            local campaignData = {}

            campaignData.name = ZO_CachedStrFormat(SI_CAMPAIGN_NAME, GetCampaignName(campaignId))
            campaignData.type = ZO_CAMPAIGN_DATA_TYPE_CAMPAIGN
            campaignData.id = campaignId
            campaignData.selectionIndex = selectionIndex
            campaignData.rulesetId = rulesetId
            campaignData.rulesetType = GetCampaignRulesetType(rulesetId)

            campaignData.alliancePopulation1 = GetSelectionCampaignPopulationData(selectionIndex, 1)
            campaignData.alliancePopulation2 = GetSelectionCampaignPopulationData(selectionIndex, 2)
            campaignData.alliancePopulation3 = GetSelectionCampaignPopulationData(selectionIndex, 3)

            campaignData.numGroupMembers = GetNumSelectionCampaignGroupMembers(selectionIndex)
            campaignData.numFriends = GetNumSelectionCampaignFriends(selectionIndex)
            campaignData.numGuildMembers = GetNumSelectionCampaignGuildMembers(selectionIndex)

            campaignData.canBeAllianceLocked = CanCampaignBeAllianceLocked(campaignId)
            campaignData.lockedToAlliance = GetSelectionCampaignCurrentAllianceLock(selectionIndex)
            campaignData.allianceLockReason = GetSelectionCampaignAllianceLockReason(selectionIndex)
            campaignData.allianceLockConflictingCharacterName = GetSelectionCampaignAllianceLockConflictingCharacterName(selectionIndex)

            campaignData.isImperialCityCampaign = IsImperialCityCampaign(campaignId)

            campaignData.queue = self:CreateCampaignQueueData(campaignData, CAMPAIGN_QUEUE_INDIVIDUAL)

            self.selectionCampaignList[selectionIndex] = campaignData
        end

        -- Categorize campaign data
        ZO_ClearTable(self.campaignRulesetsByType)
        
        for _, campaignData in ipairs(self.selectionCampaignList) do
            local campaignRulesetId = campaignData.rulesetId
            local campaignRulesetType = campaignData.rulesetType
            
            if not self.campaignRulesetsByType[campaignRulesetType] then
                self.campaignRulesetsByType[campaignRulesetType] = {}
            end
            local rulesetIds = self.campaignRulesetsByType[campaignRulesetType]

            if not ZO_IsElementInNumericallyIndexedTable(rulesetIds, campaignRulesetId) then
                table.insert(rulesetIds, campaignRulesetId)
            end
        end

        for _, rulesetIds in pairs(self.campaignRulesetsByType) do
            table.sort(rulesetIds, CompareRulesetsByDuration)
        end

        self:FireCallbacks("OnCampaignDataUpdated")
    end
end

function ZO_CampaignBrowser_Manager:CreateCampaignQueueData(campaignData, isGroup)
    return
    {
        type = ZO_CAMPAIGN_DATA_TYPE_QUEUE,
        id = campaignData.id,
        isGroup = isGroup,
        isQueued = IsQueuedForCampaign(campaignData.id, isGroup),
        state = GetCampaignQueueState(campaignData.id, isGroup),
        name = campaignData.name,
    }
end

function ZO_CampaignBrowser_Manager:UpdateQueueDataState(campaignData)
    local queueData = campaignData.queue

    queueData.isQueued = IsQueuedForCampaign(queueData.id, queueData.isGroup)
    queueData.state = GetCampaignQueueState(queueData.id, queueData.isGroup)

    self:FireCallbacks("OnCampaignQueueStateUpdated", campaignData)
end

function ZO_CampaignBrowser_Manager:GetCampaignDataList()
    return self.selectionCampaignList
end

function ZO_CampaignBrowser_Manager:GetActiveCampaignRulesetsByType()
    return self.campaignRulesetsByType
end

function ZO_CampaignBrowser_Manager:GetDataByCampaignId(campaignId)
    if campaignId ~= 0 then -- zero means "no campaign"
        for _, campaignData in ipairs(self.selectionCampaignList) do
            if campaignData.id == campaignId then
                return campaignData
            end
        end
    end

    return nil
end

function ZO_CampaignBrowser_Manager:GetMasterHomeData()
    return self:GetDataByCampaignId(GetAssignedCampaignId())
end

do
    local function IsAnyGroupMemberOffline()
        for i = 1, MAX_GROUP_SIZE_THRESHOLD do
            local unitTag = ZO_Group_GetUnitTagForGroupIndex(i)
            if not IsUnitOnline(unitTag) then
                return true
            end
        end
    
        return false
    end

    local QUEUE_MESSAGES = {
        [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_JOIN] = GetString(SI_CAMPAIGN_BROWSER_QUEUE_PENDING_JOIN),
        [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_LEAVE] = GetString(SI_CAMPAIGN_BROWSER_QUEUE_PENDING_LEAVE),
        [CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_ACCEPT] = GetString(SI_CAMPAIGN_BROWSER_QUEUE_PENDING_ACCEPT),
    }
    
    function ZO_CampaignBrowser_Manager:GetQueueMessage(id, isGroup, state)
        local queueMessage = QUEUE_MESSAGES[state]
        
        if queueMessage then
            return true, queueMessage
        else
            local descriptionText
            local iconTexture

            if state == CAMPAIGN_QUEUE_REQUEST_STATE_WAITING then
                iconTexture = "EsoUI/Art/Campaign/campaignBrowser_queued.dds"
            elseif state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING then
                iconTexture = "EsoUI/Art/Campaign/campaignBrowser_ready.dds"
            end
    
            if state == CAMPAIGN_QUEUE_REQUEST_STATE_WAITING then
                local positionInQueue = GetCampaignQueuePosition(id, isGroup)
                descriptionText = zo_strformat(SI_CAMPAIGN_BROWSER_QUEUED, positionInQueue)
            elseif state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING then
                local timeString = ZO_FormatTime(GetCampaignQueueRemainingConfirmationSeconds(id, isGroup), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
                descriptionText = zo_strformat(SI_CAMPAIGN_BROWSER_READY, timeString)
            end

            return false, descriptionText, iconTexture
        end
    end
end

function ZO_CampaignBrowser_Manager:GenerateAllianceLockStatusMessage(campaignData)
    local _, secondsUntilCampaignEnd = GetSelectionCampaignTimes(campaignData.selectionIndex)

    local message = GetString("SI_CAMPAIGNALLIANCELOCKREASON", campaignData.allianceLockReason)
    local allianceString = ZO_SELECTED_TEXT:Colorize(ZO_CampaignBrowser_FormatPlatformAllianceIconAndName(campaignData.lockedToAlliance))
    local characterNameString = campaignData.allianceLockConflictingCharacterName and ZO_SELECTED_TEXT:Colorize(ZO_FormatUserFacingCharacterName(campaignData.allianceLockConflictingCharacterName))
    local campaignEndCooldownString = ZO_SELECTED_TEXT:Colorize(ZO_FormatTime(secondsUntilCampaignEnd, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING))

    if campaignData.allianceLockReason == CAMPAIGN_ALLIANCE_LOCK_REASON_ENTERED_CAMPAIGN then
        return zo_strformat(message, allianceString, campaignEndCooldownString)
    elseif campaignData.allianceLockReason == CAMPAIGN_ALLIANCE_LOCK_REASON_CHARACTER_ASSIGNED then
        return zo_strformat(message, allianceString, characterNameString)
    elseif campaignData.allianceLockReason == CAMPAIGN_ALLIANCE_LOCK_REASON_CAMPAIGN_ENTERED_AND_ASSIGNED then
        return zo_strformat(message, allianceString, campaignEndCooldownString, characterNameString)
    end
end

CAMPAIGN_BROWSER_MANAGER = ZO_CampaignBrowser_Manager:New()

-- Global functions
do
    internalassert(CAMPAIGN_RULESET_TYPE_MAX_VALUE == 4, "Update ruleset icons")
    local CAMPAIGN_RULESET_TYPE_KEYBOARD_ICONS =
    {
        [CAMPAIGN_RULESET_TYPE_CYRODIIL] = 
        {
            up = "EsoUI/Art/LFG/LFG_indexIcon_allianceWar_up.dds",
            down = "EsoUI/Art/LFG/LFG_indexIcon_allianceWar_down.dds",
            over = "EsoUI/Art/LFG/LFG_indexIcon_allianceWar_over.dds",
        },
        [CAMPAIGN_RULESET_TYPE_IMPERIAL_CITY] = 
        {
            up = "EsoUI/Art/LFG/LFG_indexIcon_imperialCity_up.dds",
            down = "EsoUI/Art/LFG/LFG_indexIcon_imperialCity_down.dds",
            over = "EsoUI/Art/LFG/LFG_indexIcon_imperialCity_over.dds",
        },
    }
    local CAMPAIGN_RULESET_TYPE_GAMEPAD_ICONS =
    {
        [CAMPAIGN_RULESET_TYPE_CYRODIIL] = "EsoUI/Art/LFG/Gamepad/LFG_activityIcon_cyrodiil.dds",
        [CAMPAIGN_RULESET_TYPE_IMPERIAL_CITY] = "EsoUI/Art/LFG/Gamepad/LFG_activityIcon_imperialCity.dds",
    }

    function ZO_CampaignBrowser_GetKeyboardIconsForRulesetType(rulesetType)
        return CAMPAIGN_RULESET_TYPE_KEYBOARD_ICONS[rulesetType]
    end

    function ZO_CampaignBrowser_GetGamepadIconForRulesetType(rulesetType)
        return CAMPAIGN_RULESET_TYPE_GAMEPAD_ICONS[rulesetType]
    end
end

do
    local POPULATION_ICONS =
    {
        [CAMPAIGN_POP_LOW] = "EsoUI/Art/Campaign/campaignBrowser_lowPop.dds",
        [CAMPAIGN_POP_MEDIUM] = "EsoUI/Art/Campaign/campaignBrowser_medPop.dds",
        [CAMPAIGN_POP_HIGH] = "EsoUI/Art/Campaign/campaignBrowser_hiPop.dds",
        [CAMPAIGN_POP_FULL] = "EsoUI/Art/Campaign/campaignBrowser_fullPop.dds",
    }

    function ZO_CampaignBrowser_GetPopulationIcon(population)
        return POPULATION_ICONS[population]
    end
end

function ZO_CampaignBrowser_DoesPlayerMatchAllianceLock(campaignData)
    return campaignData.lockedToAlliance == ALLIANCE_NONE or campaignData.lockedToAlliance == GetUnitAlliance("player")
end

function ZO_CampaignBrowserDialogs_ShouldShowAllianceLockWarning(campaignData)
    -- Only show warning if the campaign hasn't already been entered
   return campaignData.canBeAllianceLocked and
        campaignData.allianceLockReason ~= CAMPAIGN_ALLIANCE_LOCK_REASON_ENTERED_CAMPAIGN and
        campaignData.allianceLockReason ~= CAMPAIGN_ALLIANCE_LOCK_REASON_CAMPAIGN_ENTERED_AND_ASSIGNED
end

function ZO_CampaignBrowser_FormatPlatformAllianceIconAndName(alliance)
    local ICON_SIZE = "100%"
    return zo_iconTextFormatNoSpace(ZO_GetPlatformAllianceSymbolIcon(alliance), ICON_SIZE, ICON_SIZE, GetAllianceName(alliance))
end
