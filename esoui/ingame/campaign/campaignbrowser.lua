local CampaignBrowser = ZO_SortFilterList:Subclass()

local ENTRY_SORT_KEYS =
{
    ["name"] = { },
    ["numFriends"] = { tiebreaker = "name", isNumeric = true },
    ["numGuildMembers"] = { tiebreaker = "name", isNumeric = true },
    ["numGroupMembers"] = { tiebreaker = "name", isNumeric = true },
    ["alliancePopulation1"] = { tiebreaker = "name", isNumeric = true },
    ["alliancePopulation2"] = { tiebreaker = "name", isNumeric = true },
    ["alliancePopulation3"] = { tiebreaker = "name", isNumeric = true },
}

function CampaignBrowser:New(...)
    return ZO_SortFilterList.New(self, ...)
end

function CampaignBrowser:Initialize(control)
    ZO_SortFilterList.Initialize(self, control)

    self.rules = control:GetNamedChild("Rules")

    self.numConfirmingQueues = 0
    
    ZO_ScrollList_AddDataType(self.list, ZO_CAMPAIGN_DATA_TYPE_CAMPAIGN, "ZO_CampaignBrowserRow", 30, function(control, data) self:SetupCampaign(control, data) end)
    ZO_ScrollList_AddDataType(self.list, ZO_CAMPAIGN_DATA_TYPE_QUEUE, "ZO_CampaignBrowserQueueRow", 30, function(control, data) self:SetupCampaignQueue(control, data) end)
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
    self:SetAlternateRowBackgrounds(true)
    self.sortFunction = function(listEntry1, listEntry2) return self:CompareCampaigns(listEntry1, listEntry2) end
    self.filteredList = {}

    self:InitializeTree()
    self:RefreshData()

    self.sortHeaderGroup:SelectHeaderByKey("name")

    CAMPAIGN_BROWSER_MANAGER:RegisterCallback("OnCampaignDataUpdated", function() self:OnCampaignSelectionDataChanged() end)
    CAMPAIGN_BROWSER_MANAGER:RegisterCallback("OnCampaignQueueStateUpdated", function(_, campaignData) self:OnCampaignQueueStateUpdated(campaignData) end)

    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_ASSIGNED_CAMPAIGN_CHANGED, function() self:OnAssignedCampaignChanged() end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_CAMPAIGN_QUEUE_POSITION_CHANGED, function() self:OnCampaignQueuePositionChanged() end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_UNIT_CREATED, function(_, unitTag) self:OnUnitUpdated(unitTag) end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_UNIT_DESTROYED, function(_, unitTag) self:OnUnitUpdated(unitTag) end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_GROUP_MEMBER_CONNECTED_STATUS, function() self:RefreshVisible() end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_LEADER_UPDATE, function() self:OnGroupLeaderUpdate() end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_PLAYER_DEAD, function() self:OnPlayerDead() end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_PLAYER_ALIVE, function() self:OnPlayerAlive() end)

    CAMPAIGN_BROWSER_SCENE = ZO_Scene:New("campaignBrowser", SCENE_MANAGER)
    self:InitializeKeybindDescriptors()
    CAMPAIGN_BROWSER_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            QueryCampaignSelectionData()
            self:SelectAssignedCampainRulesetNode()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)
end

function CampaignBrowser:InitializeTree()
    self.tree = ZO_Tree:New(GetControl(self.control, "CategoriesScrollChild"), 60, -10, 255)

    local function RulesetTypeSetup(control, rulesetType, down)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(GetString("SI_CAMPAIGNRULESETTYPE", rulesetType))
        control.rulesetType = rulesetType
        
        local icons = ZO_CampaignBrowser_GetKeyboardIconsForRulesetType(rulesetType)
        control.icon:SetTexture(down and icons.down or icons.up)
        control.iconHighlight:SetTexture(icons.over)
        
        ZO_IconHeader_Setup(control, down)
    end

    --Ruleset Type Header

    local function RulesetTypeHeaderSetup(node, control, rulesetType, open, userRequested)
        RulesetTypeSetup(control, rulesetType, open)

        if open and userRequested then
            self.tree:SelectFirstChild(node)
        end
    end
    self.tree:AddTemplate("ZO_RulesetTypeHeader", RulesetTypeHeaderSetup, nil, nil, nil, 0)

    --Ruleset Entry

    local function RulesetEntrySetup(node, control, data, open)
        local name = GetCampaignRulesetName(data.rulesetId)
        control:SetSelected(false)
        control.rulesetId = data.rulesetId
        control:SetText(name)
    end
    local function RulesetEntrySelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected and not reselectingDuringRebuild then
            self:SetRulesetIdFilter(data.rulesetId)
        end
    end
    local function RulesetEntryEquality(left, right)
        return left.rulesetId == right.rulesetId
    end
    self.tree:AddTemplate("ZO_RulesetEntry", RulesetEntrySetup, RulesetEntrySelected, RulesetEntryEquality)

    self.tree:SetExclusive(true)
    self.tree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function CampaignBrowser:SetRulesetIdFilter(rulesetId)
    self.rulesetIdFilter = rulesetId
    self.rules:SetText(GetCampaignRulesetDescription(rulesetId))
    self:RefreshFilters()
end

function CampaignBrowser:CanSetHomeCampaign()
    if self.mouseOverRow then
        return CAMPAIGN_BROWSER_MANAGER:CanSetHomeCampaign(ZO_ScrollList_GetData(self.mouseOverRow))
    end
end

function CampaignBrowser:DoSetHomeCampaign()
    if self.mouseOverRow then
        return CAMPAIGN_BROWSER_MANAGER:DoSetHomeCampaign(ZO_ScrollList_GetData(self.mouseOverRow))
    end
end

function CampaignBrowser:CanAbandon()
    if self.mouseOverRow then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        local isQueued = IsQueuedForCampaign(data.id, data.isGroup)
        local isCurrentCampaign = data.id == GetAssignedCampaignId()
        if (isCurrentCampaign and not isQueued) then
            return true
        end
    end
end

function CampaignBrowser:DoAbandon()
    if self.mouseOverRow then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        if (data.id == GetAssignedCampaignId()) then
            ABANDON_HOME_CAMPAIGN_DIALOG:Show(data)
        end
    end
end

function CampaignBrowser:CanEnter()
    if self.mouseOverRow then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        if data.type == ZO_CAMPAIGN_DATA_TYPE_QUEUE then
            if data.state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING then
                return true
            end
        end
    end
end

function CampaignBrowser:DoEnter()
    if self.mouseOverRow then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        if data.type == ZO_CAMPAIGN_DATA_TYPE_QUEUE then
            if data.state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING then
                ConfirmCampaignEntry(data.id, data.isGroup, true)
            end
        end
    end
end

function CampaignBrowser:CanQueueForCampaign()
    if self.mouseOverRow then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        if data.type == ZO_CAMPAIGN_DATA_TYPE_CAMPAIGN then
            local canQueueIndividual, canQueueGroup = CAMPAIGN_BROWSER_MANAGER:CanQueueForCampaign(data)
            return canQueueIndividual or canQueueGroup
        end
    end
end

function CampaignBrowser:DoQueueForCampaign()
    if self.mouseOverRow then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        CAMPAIGN_BROWSER_MANAGER:DoQueueForCampaign(data)
    end
end

function CampaignBrowser:CanLeaveCampaignQueue()
    if self.mouseOverRow then
        return CAMPAIGN_BROWSER_MANAGER:CanLeaveCampaignQueue(ZO_ScrollList_GetData(self.mouseOverRow))
    end
    return false
end

function CampaignBrowser:DoLeaveCampaignQueue()
    if self.mouseOverRow then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        CAMPAIGN_BROWSER_MANAGER:DoLeaveCampaignQueue(data)
    end
end

function CampaignBrowser:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,
        
        --Leave/Abandon
        {
            name = function()
                if self.mouseOverRow then
                    if self:CanLeaveCampaignQueue() then
                        return GetString(SI_CAMPAIGN_BROWSER_LEAVE_QUEUE)
                    elseif self:CanAbandon() then
                        return GetString(SI_CAMPAIGN_BROWSER_ABANDON_CAMPAIGN)
                    end
                end
            end,

            keybind = "UI_SHORTCUT_NEGATIVE",
        
            callback = function()
                if self.mouseOverRow then
                    if self:CanLeaveCampaignQueue() then
                        self:DoLeaveCampaignQueue()
                    elseif self:CanAbandon() then
                        self:DoAbandon()
                    end
                end
            end,

            visible = function()
                return self:CanLeaveCampaignQueue() or self:CanAbandon()
            end
        },

        -- Home
        {
            name = GetString(SI_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN),
            keybind = "UI_SHORTCUT_SECONDARY",
        
            callback = function()
                self:DoSetHomeCampaign()
            end,

            visible = function()
                return self:CanSetHomeCampaign()
            end,
        },

        --Queue/Enter
        {
            name = function()
                if self.mouseOverRow then
                    local data = ZO_ScrollList_GetData(self.mouseOverRow)
                    if data.type == ZO_CAMPAIGN_DATA_TYPE_CAMPAIGN then
                        return GetString(SI_CAMPAIGN_BROWSER_QUEUE_CAMPAIGN)
                    elseif data.type == ZO_CAMPAIGN_DATA_TYPE_QUEUE then
                        return GetString(SI_CAMPAIGN_BROWSER_ENTER_CAMPAIGN)
                    end
                end
            end,

            keybind = "UI_SHORTCUT_PRIMARY",
        
            callback = function()
                if self.mouseOverRow then
                    local data = ZO_ScrollList_GetData(self.mouseOverRow)
                    if data.type == ZO_CAMPAIGN_DATA_TYPE_CAMPAIGN then
                        self:DoQueueForCampaign()
                    elseif data.type == ZO_CAMPAIGN_DATA_TYPE_QUEUE then
                        self:DoEnter()
                    end
                end
            end,

            visible = function()
                return self:CanQueueForCampaign() or self:CanEnter()
            end,
        },
    }
end

function CampaignBrowser:SetupAllianceControl(control, data)
    control.data = data
    control:SetTexture(ZO_CampaignBrowser_GetPopulationIcon(data.population))
end

function CampaignBrowser:SetupCampaignQueue(control, queueData)
    ZO_SortFilterList.SetupRow(self, control, queueData)

    local icon = GetControl(control, "Icon")
    local loading = GetControl(control, "Loading")
    local description = GetControl(control, "Description")
    
    local isLoading, message, messageicon = CAMPAIGN_BROWSER_MANAGER:GetQueueMessage(queueData.id, queueData.isGroup, queueData.state)
    icon:SetHidden(isLoading)
    loading:SetHidden(not isLoading)

    if not isLoading then
        icon:SetTexture(messageicon)
    end

    description:SetText(message)
end

function CampaignBrowser:CheckForConfirmingQueues()
    for _, campaignData in ipairs(self.masterList) do
        if campaignData.queue.state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING then
            hasConfirmingQueues = true
            break
        end
    end

    if hasConfirmingQueues then
        self.control:SetHandler("OnUpdate", function(control, seconds)
                -- Ensure that refresh only occurs on second boundaries
                if not self.nextUpdateTimeSeconds or seconds > self.nextUpdateTimeSeconds then
                    self.nextUpdateTimeSeconds  = zo_floor(seconds + 1)
                    self:RefreshVisible()
                end
            end)
    else
        self.control:SetHandler("OnUpdate", nil)
    end
end

function CampaignBrowser:BuildMasterList()
    self.control:SetHandler("OnUpdate", nil)
    self.numConfirmingQueues = 0

    -- get master list
    self.masterList = CAMPAIGN_BROWSER_MANAGER:GetCampaignDataList()

    -- build ruleset categories
    self.rulesetTypes = CAMPAIGN_BROWSER_MANAGER:GetActiveCampaignRulesetsByType()

    self.tree:Reset()
    
    for rulesetType, rulesetIds in pairs(self.rulesetTypes) do
        local parentCategory = self.tree:AddNode("ZO_RulesetTypeHeader", rulesetType)

        for _, rulesetId in pairs(rulesetIds) do
            self.tree:AddNode("ZO_RulesetEntry", {rulesetId = rulesetId}, parentCategory)
        end
    end

    self.tree:Commit()
    self:SelectAssignedCampainRulesetNode()
end

function CampaignBrowser:SelectAssignedCampainRulesetNode()
    if self.tree then
        local assignedCampaignId = GetAssignedCampaignId()
        local assignedCampaignRulesetId = GetCampaignRulesetId(assignedCampaignId)

        if assignedCampaignRulesetId ~= 0 then
            local START_AT_ROOT = nil
            self.tree:ExecuteOnSubTree(START_AT_ROOT, function(node)
                if node:GetTemplate() == "ZO_RulesetEntry" then
                    local nodeData = node:GetData()
                    if nodeData.rulesetId == assignedCampaignRulesetId then
                        self.tree:SelectNode(node)
                        return true
                    end
                end
            end)
        end
    end
end

do
    internalassert(CAMPAIGN_RULESET_TYPE_MAX_VALUE == 4, "Update Campaign Rulesets")
    local HIDDEN_COLUMN_KEYS_BY_RULESET_TYPE =
    {
        [CAMPAIGN_RULESET_TYPE_CYRODIIL] = {},
        [CAMPAIGN_RULESET_TYPE_IMPERIAL_CITY] = {["numGroupMembers"] = true, ["numFriends"] = true, ["numGuildMembers"] = true},
    }
    function CampaignBrowser:FilterScrollList()
        -- Apply filter to list
        ZO_ClearNumericallyIndexedTable(self.filteredList)
        for _, campaignData in ipairs(self.masterList) do
            if self.rulesetIdFilter == campaignData.rulesetId then
                table.insert(self.filteredList, ZO_ScrollList_CreateDataEntry(ZO_CAMPAIGN_DATA_TYPE_CAMPAIGN, campaignData))
            end
        end

        -- Apply filter to headers
        local rulesetType = GetCampaignRulesetType(self.rulesetIdFilter)
        local hiddenColumns = HIDDEN_COLUMN_KEYS_BY_RULESET_TYPE[rulesetType]
        local HIDDEN = true
        self.sortHeaderGroup:SetHeadersHiddenFromKeyList(hiddenColumns, HIDDEN)

        if hiddenColumns[self.sortHeaderGroup:GetCurrentSortKey()] then
            -- Table was sorted by a column that is gone now: fallback to name
            self.sortHeaderGroup:SelectHeaderByKey("name")
        end
    end

    function CampaignBrowser:SetupCampaign(control, data)
        ZO_SortFilterList.SetupRow(self, control, data)
     
        local name = GetControl(control, "Name")

        name:SetText(data.name)

        local icon = GetControl(control, "Icon")
        if data.id == GetAssignedCampaignId() then
            icon:SetHidden(false)
            icon:SetTexture("EsoUI/Art/Campaign/campaignBrowser_homeCampaign.dds")
        elseif not ZO_CampaignBrowser_DoesPlayerMatchAllianceLock(data) then
            icon:SetHidden(false)
            icon:SetTexture("EsoUI/Art/Miscellaneous/status_locked.dds")
        else
            icon:SetHidden(true)
        end

        local selectionIndex = data.selectionIndex

        local alliancePopulation1 = control:GetNamedChild("AlliancePopulation1")
        self:SetupAllianceControl(alliancePopulation1, {population = data.alliancePopulation1, selectionIndex = selectionIndex, alliance = ALLIANCE_ALDMERI_DOMINION})

        local alliancePopulation2 = control:GetNamedChild("AlliancePopulation2")
        self:SetupAllianceControl(alliancePopulation2, {population = data.alliancePopulation2, selectionIndex = selectionIndex, alliance = ALLIANCE_EBONHEART_PACT})

        local alliancePopulation3 = control:GetNamedChild("AlliancePopulation3")
        self:SetupAllianceControl(alliancePopulation3, {population = data.alliancePopulation3, selectionIndex = selectionIndex, alliance = ALLIANCE_DAGGERFALL_COVENANT})

        local rulesetType = GetCampaignRulesetType(self.rulesetIdFilter)
        local hiddenColumns = HIDDEN_COLUMN_KEYS_BY_RULESET_TYPE[rulesetType]

        control:GetNamedChild("GroupMembers"):SetHidden(hiddenColumns["numGroupMembers"] or data.numGroupMembers == 0)
        control:GetNamedChild("Friends"):SetHidden(hiddenColumns["numFriends"] or data.numFriends == 0)
        control:GetNamedChild("GuildMembers"):SetHidden(hiddenColumns["numGuildMembers"] or data.numGuildMembers == 0)    
    end
end

function CampaignBrowser:CompareCampaigns(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, ENTRY_SORT_KEYS, self.currentSortOrder)
end

function CampaignBrowser:SortScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    if self.currentSortKey ~= nil and self.currentSortOrder ~= nil then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        table.sort(self.filteredList, self.sortFunction)

        --add the queue rows under the campaign rows
        for _, campaignEntry in ipairs(self.filteredList) do
            table.insert(scrollData, campaignEntry)
            local data = campaignEntry.data
            if data.queue.isQueued then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ZO_CAMPAIGN_DATA_TYPE_QUEUE, data.queue))
            end
        end
    end
end

function CampaignBrowser:GetRowColors(data, mouseIsOver, control)
    local textColor
    if data.type == ZO_CAMPAIGN_DATA_TYPE_CAMPAIGN then
        textColor = ZO_SECOND_CONTRAST_TEXT
    else
        textColor = ZO_NORMAL_TEXT
    end

    if mouseIsOver then
        textColor = ZO_SELECTED_TEXT
    else
        if control.normalColor then
            textColor = control.normalColor
        end
    end

    return textColor, nil
end

function CampaignBrowser:GetDataByCampaignId(campaignId)
    return CAMPAIGN_BROWSER_MANAGER:GetDataByCampaignId(campaignId)
end

--Events
------------

function CampaignBrowser:OnCampaignSelectionDataChanged()
    self:RefreshData()
end

function CampaignBrowser:OnAssignedCampaignChanged()
    self:SelectAssignedCampainRulesetNode()
    self:RefreshVisible()
end

function CampaignBrowser:OnCampaignQueueStateUpdated(campaignData)
    self:CheckForConfirmingQueues()
    self:RefreshFilters()
end

function CampaignBrowser:OnCampaignQueuePositionChanged()
    self:RefreshVisible()
end

function CampaignBrowser:OnUnitUpdated(unitTag)
    if ZO_Group_IsGroupUnitTag(unitTag) then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function CampaignBrowser:OnGroupLeaderUpdate()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function CampaignBrowser:OnPlayerDead()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function CampaignBrowser:OnPlayerAlive()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

--Local XML Handlers
---------------------

local g_nextTimeUpdate
local function UpdateWaitingTooltip(control, time)
    if not g_nextTimeUpdate or time > g_nextTimeUpdate then
        g_nextTimeUpdate = time + 1
        CAMPAIGN_BROWSER:QueueRowIcon_OnMouseEnter(control)
    end
end

function CampaignBrowser:QueueRowIcon_OnMouseEnter(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
        
    if data.state == CAMPAIGN_QUEUE_REQUEST_STATE_WAITING then
        InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
        local timeElapsed = GetSecondsInCampaignQueue(data.id, data.isGroup)
        local text = zo_strformat(SI_CAMPAIGN_BROWSER_TOOLTIP_IN_QUEUE_FOR, ZO_FormatTime(timeElapsed, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR))
        SetTooltipText(InformationTooltip, text)

        control:SetHandler("OnUpdate", UpdateWaitingTooltip)
    end
    
    self:EnterRow(control:GetParent())
end

function CampaignBrowser:QueueRowIcon_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    control:SetHandler("OnUpdate", nil)
    g_nextTimeUpdate = nil
    self:ExitRow(control:GetParent())
end

function CampaignBrowser:RowIcon_OnMouseEnter(control)
    local campaignData = ZO_ScrollList_GetData(control:GetParent())

    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    if campaignData.id == GetAssignedCampaignId() then
        SetTooltipText(InformationTooltip, GetString(SI_CAMPAIGN_BROWSER_TOOLTIP_HOME_CAMPAIGN))
    elseif not ZO_CampaignBrowser_DoesPlayerMatchAllianceLock(campaignData) then
        local lastSecondsUntilCampaignEnd = nil
        local function UpdateTooltipText()
            local _, secondsUntilCampaignEnd = GetSelectionCampaignTimes(campaignData.selectionIndex)
            if lastSecondsUntilCampaignEnd ~= secondsUntilCampaignEnd then
                InformationTooltip:ClearLines()
                SetTooltipText(InformationTooltip, CAMPAIGN_BROWSER_MANAGER:GenerateAllianceLockStatusMessage(campaignData))
            end
        end
        control:SetHandler("OnUpdate", UpdateTooltipText)
        UpdateTooltipText()
    end
    
    self:EnterRow(control:GetParent())
end

function CampaignBrowser:RowIcon_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    self:ExitRow(control:GetParent())
    control:SetHandler("OnUpdate", nil)
end

function CampaignBrowser:RowGroupMembers_OnMouseEnter(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    SetTooltipText(InformationTooltip, zo_strformat(SI_CAMPAIGN_BROWSER_TOOLTIP_NUM_GROUP_MEMBERS, data.numGroupMembers))

    self:EnterRow(control:GetParent())
end

function CampaignBrowser:RowGroupMembers_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    self:ExitRow(control:GetParent())
end

function CampaignBrowser:RowFriends_OnMouseEnter(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    SetTooltipText(InformationTooltip, zo_strformat(SI_CAMPAIGN_BROWSER_TOOLTIP_NUM_FRIENDS, data.numFriends))

    self:EnterRow(control:GetParent())
end

function CampaignBrowser:RowFriends_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    self:ExitRow(control:GetParent())
end

function CampaignBrowser:RowGuildMembers_OnMouseEnter(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    SetTooltipText(InformationTooltip, zo_strformat(SI_CAMPAIGN_BROWSER_TOOLTIP_NUM_GUILD_MEMBERS, data.numGuildMembers))

    self:EnterRow(control:GetParent())
end

function CampaignBrowser:RowGuildMembers_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    self:ExitRow(control:GetParent())
end

function CampaignBrowser:RowAlliancePopulation_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)

    local data = control.data
    
    local textPopulation = GetString("SI_CAMPAIGNPOPULATIONTYPE", data.population)
    InformationTooltip:AddLine(textPopulation, "", ZO_NORMAL_TEXT:UnpackRGB())

    if data.alliance == GetUnitAlliance("player") then
        local queueWaitSeconds = GetSelectionCampaignQueueWaitTime(data.selectionIndex)
        if queueWaitSeconds > 0 then
            --We don't want to show an estimate for seconds
            if queueWaitSeconds < 60 then
                queueWaitSeconds = 60
            end
            queueWaitMs = queueWaitSeconds * 1000
            local textEstimatedTime = ZO_GetSimplifiedTimeEstimateText(queueWaitMs, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT, nil, ZO_TIME_ESTIMATE_STYLE.ARITHMETIC)
            textEstimatedTime = zo_strformat(SI_CAMPAIGN_BROWSER_TOOLTIP_ESTIMATED_TIME, textEstimatedTime)
            InformationTooltip:AddLine(textEstimatedTime, "", ZO_NORMAL_TEXT:UnpackRGB())
        end
    end

    self:EnterRow(control:GetParent())
end

function CampaignBrowser:RowAlliancePopulation_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    self:ExitRow(control:GetParent())
end

function CampaignBrowser:Row_OnMouseUp(control, button, upInside)
    if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        ClearMenu()

        if self:CanQueueForCampaign() then
            AddMenuItem(GetString(SI_CAMPAIGN_BROWSER_QUEUE_CAMPAIGN), function() self:DoQueueForCampaign() end)
        end
        if self:CanSetHomeCampaign() then
            AddMenuItem(GetString(SI_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN), function() self:DoSetHomeCampaign() end)
        end
        if self:CanAbandon() then
            AddMenuItem(GetString(SI_CAMPAIGN_BROWSER_ABANDON_CAMPAIGN), function() self:DoAbandon() end)
        end
        
        self:ShowMenu(control)
    end
end

function CampaignBrowser:Row_OnMouseDoubleClick(control)
    if self:CanQueueForCampaign() then
        self:DoQueueForCampaign()
    end
end

function CampaignBrowser:QueueRow_OnMouseUp(control, button, upInside)
    if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        ClearMenu()

        if self:CanEnter() then
            AddMenuItem(GetString(SI_CAMPAIGN_BROWSER_ENTER_CAMPAIGN), function() self:DoEnter() end)
        end
        if self:CanLeaveCampaignQueue() then
            AddMenuItem(GetString(SI_CAMPAIGN_BROWSER_LEAVE_QUEUE), function() self:DoLeaveCampaignQueue() end)
        end
        
        self:ShowMenu(control)
    end
end

function CampaignBrowser:QueueRow_OnMouseDoubleClick(control)
    if self:CanEnter() then
        self:DoEnter()
    end
end

--Global XML Handlers
-----------------------

function ZO_CampaignBrowserQueueRowIcon_OnMouseEnter(control)
    CAMPAIGN_BROWSER:QueueRowIcon_OnMouseEnter(control)
end

function ZO_CampaignBrowserQueueRowIcon_OnMouseExit(control)
    CAMPAIGN_BROWSER:QueueRowIcon_OnMouseExit(control)
end

function ZO_CampaignBrowserRowIcon_OnMouseEnter(control)
    CAMPAIGN_BROWSER:RowIcon_OnMouseEnter(control)
end

function ZO_CampaignBrowserRowIcon_OnMouseExit(control)
    CAMPAIGN_BROWSER:RowIcon_OnMouseExit(control)
end

function ZO_CampaignBrowserRowGroupMembers_OnMouseEnter(control)
    CAMPAIGN_BROWSER:RowGroupMembers_OnMouseEnter(control)
end

function ZO_CampaignBrowserRowGroupMembers_OnMouseExit(control)
    CAMPAIGN_BROWSER:RowGroupMembers_OnMouseExit(control)
end

function ZO_CampaignBrowserRowFriends_OnMouseEnter(control)
    CAMPAIGN_BROWSER:RowFriends_OnMouseEnter(control)
end

function ZO_CampaignBrowserRowFriends_OnMouseExit(control)
    CAMPAIGN_BROWSER:RowFriends_OnMouseExit(control)
end

function ZO_CampaignBrowserRowGuildMembers_OnMouseEnter(control)
    CAMPAIGN_BROWSER:RowGuildMembers_OnMouseEnter(control)
end

function ZO_CampaignBrowserRowGuildMembers_OnMouseExit(control)
    CAMPAIGN_BROWSER:RowGuildMembers_OnMouseExit(control)
end

function ZO_CampaignBrowserRowAlliancePopulation_OnMouseEnter(control)
    CAMPAIGN_BROWSER:RowAlliancePopulation_OnMouseEnter(control)
end

function ZO_CampaignBrowserRowAlliancePopulation_OnMouseExit(control)
    CAMPAIGN_BROWSER:RowAlliancePopulation_OnMouseExit(control)
end

function ZO_CampaignBrowserRow_OnMouseEnter(control)
    CAMPAIGN_BROWSER:Row_OnMouseEnter(control)
end

function ZO_CampaignBrowserRow_OnMouseExit(control)
    CAMPAIGN_BROWSER:Row_OnMouseExit(control)
end

function ZO_CampaignBrowserRow_OnMouseUp(control, button, upInside)
    CAMPAIGN_BROWSER:Row_OnMouseUp(control, button, upInside)
end

function ZO_CampaignBrowserRow_OnMouseDoubleClick(control)
    CAMPAIGN_BROWSER:Row_OnMouseDoubleClick(control)
end

function ZO_CampaignBrowserQueueRow_OnMouseEnter(control)
    CAMPAIGN_BROWSER:Row_OnMouseEnter(control)
    ZO_TooltipIfTruncatedLabel_OnMouseEnter(GetControl(control, "Description"))
end

function ZO_CampaignBrowserQueueRow_OnMouseExit(control)
    CAMPAIGN_BROWSER:Row_OnMouseExit(control)
    ZO_TooltipIfTruncatedLabel_OnMouseExit(GetControl(control, "Description"))
end

function ZO_CampaignBrowserQueueRow_OnMouseUp(control, button, upInside)
    CAMPAIGN_BROWSER:QueueRow_OnMouseUp(control, button, upInside)
end

function ZO_CampaignBrowserQueueRow_OnMouseDoubleClick(control)
    CAMPAIGN_BROWSER:QueueRow_OnMouseDoubleClick(control)
end

function ZO_CampaignBrowser_OnInitialized(self)
    CAMPAIGN_BROWSER = CampaignBrowser:New(self)
end
