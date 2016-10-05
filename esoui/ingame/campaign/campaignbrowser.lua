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

function CampaignBrowser:New(control)
    local manager = ZO_SortFilterList.New(self, control)
    self.campaignBrowser = ZO_CampaignBrowser_Shared:New()

    manager.rules = GetControl(control, "Rules")
    manager.numConfirmingQueues = 0
    
    ZO_ScrollList_AddDataType(manager.list, self.campaignBrowser:GetCampaignType(), "ZO_CampaignBrowserRow", 30, function(control, data) manager:SetupCampaign(control, data) end)
    ZO_ScrollList_AddDataType(manager.list, self.campaignBrowser:GetQueueType(), "ZO_CampaignBrowserQueueRow", 30, function(control, data) manager:SetupCampaignQueue(control, data) end)
    ZO_ScrollList_EnableHighlight(manager.list, "ZO_ThinListHighlight")
    manager:SetAlternateRowBackgrounds(true)
    manager.sortFunction = function(listEntry1, listEntry2) return manager:CompareCampaigns(listEntry1, listEntry2) end

    manager:InitializeTree()
    manager:RefreshData()

    manager.sortHeaderGroup:SelectHeaderByKey("name")

    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_CAMPAIGN_SELECTION_DATA_CHANGED, function() manager:OnCampaignSelectionDataChanged() end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_ASSIGNED_CAMPAIGN_CHANGED, function() manager:RefreshVisible() end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_GUEST_CAMPAIGN_CHANGED, function() manager:RefreshVisible() end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_CAMPAIGN_QUEUE_JOINED, function(_, campaignId, group) manager:OnCampaignQueueJoined(campaignId) end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_CAMPAIGN_QUEUE_LEFT, function(_, campaignId, group) manager:OnCampaignQueueLeft(campaignId) end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_CAMPAIGN_QUEUE_STATE_CHANGED, function(_, campaignId) manager:OnCampaignQueueStateChanged(campaignId) end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_CAMPAIGN_QUEUE_POSITION_CHANGED, function() manager:OnCampaignQueuePositionChanged() end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_UNIT_CREATED, function(_, unitTag) manager:OnUnitUpdated(unitTag) end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_UNIT_DESTROYED, function(_, unitTag) manager:OnUnitUpdated(unitTag) end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_GROUP_MEMBER_CONNECTED_STATUS, function() manager:RefreshVisible() end)
    EVENT_MANAGER:RegisterForEvent("CampaignBrowser", EVENT_LEADER_UPDATE, function() manager:OnGroupLeaderUpdate() end)

    CAMPAIGN_BROWSER_SCENE = ZO_Scene:New("campaignBrowser", SCENE_MANAGER)
    manager:InitializeKeybindDescriptors()
    CAMPAIGN_BROWSER_SCENE:RegisterCallback("StateChange",  function(oldState, newState)
                                                                if(newState == SCENE_SHOWING) then
                                                                    QueryCampaignSelectionData()
                                                                    KEYBIND_STRIP:AddKeybindButtonGroup(manager.keybindStripDescriptor)
                                                                elseif(newState == SCENE_HIDDEN) then                                                             
                                                                    KEYBIND_STRIP:RemoveKeybindButtonGroup(manager.keybindStripDescriptor)
                                                                end
                                                            end)
    
    return manager
end

function CampaignBrowser:InitializeTree()
    self.tree = ZO_Tree:New(GetControl(self.control, "CategoriesScrollChild"), 60, -10, 255)

    local function RulesetTypeSetup(control, rulesetType, down)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(GetString("SI_CAMPAIGNRULESETTYPE", rulesetType))
        control.rulesetType = rulesetType
        
        local icons = ZO_CampaignBrowser_GetIcons(rulesetType)
        control.icon:SetTexture(down and icons.down or icons.up)
        control.iconHighlight:SetTexture(icons.over)
        
        ZO_IconHeader_Setup(control, down)
    end

    --Ruleset Type Header

    local function RulesetTypeHeaderSetup(node, control, rulesetType, open)
        RulesetTypeSetup(control, rulesetType, open)
    end
    self.tree:AddTemplate("ZO_RulesetTypeHeader", RulesetTypeHeaderSetup, nil, nil, nil, 0)

    --Ruleset Type Entry

    local function RulesetTypeEntrySetup(node, control, rulesetType, open)
        RulesetTypeSetup(control, rulesetType, false)
    end
    local function RulesetTypeEntrySelected(control, rulesetType, selected, reselectingDuringRebuild)
        if(selected and not reselectingDuringRebuild) then
            self:SetRulesetTypeFilter(rulesetType)
        end
        RulesetTypeSetup(control, rulesetType, selected)
    end
    local function RulesetTypeEquality(left, right)
        return left == right
    end
    self.tree:AddTemplate("ZO_RulesetTypeEntry", RulesetTypeEntrySetup, RulesetTypeEntrySelected, RulesetTypeEquality)

    --Ruleset Entry

    local function RulesetEntrySetup(node, control, data, open)
        local name = GetCampaignRulesetName(data.rulesetId)
        control:SetSelected(false)
        control.rulesetId = data.rulesetId
        control:SetHeight(0)
        control:SetText(name)

        if(data.noHeader) then
            local TEXT_HEIGHT_BUFFER = 10
            control:SetHeight(control:GetTextHeight() + TEXT_HEIGHT_BUFFER)
        else
            control:SetHeight(control:GetTextHeight())
        end
    end
    local function RulesetEntrySelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if(selected and not reselectingDuringRebuild) then
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

function CampaignBrowser:SetRulesetTypeFilter(rulesetType)
    self.rulesetTypeFilter = rulesetType
    self.rulesetIdFilter = nil
    
    local rulesetIds = self.rulesetTypes[rulesetType]
    if(rulesetIds) then
        local rulesetId = next(rulesetIds)
        if(rulesetId) then
            self.rules:SetText(GetCampaignRulesetDescription(rulesetId))
        end
    end

    self:RefreshFilters()
end

function CampaignBrowser:SetRulesetIdFilter(rulesetId)
    self.rulesetIdFilter = rulesetId
    self.rulesetTypeFilter = nil
    self.rules:SetText(GetCampaignRulesetDescription(rulesetId))
    self:RefreshFilters()
end

function CampaignBrowser:CanGuest()
    if(self.mouseOverRow) then
        return self.campaignBrowser:CanGuest(ZO_ScrollList_GetData(self.mouseOverRow))
    end
end

function CampaignBrowser:DoGuest()
    if(self.mouseOverRow) then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        if(data.type == self.campaignBrowser:GetCampaignType()) then
            SELECT_GUEST_CAMPAIGN_DIALOG:Show(data)                    
        end
    end
end

function CampaignBrowser:CanHome()
    if(self.mouseOverRow) then
        return self.campaignBrowser:CanHome(ZO_ScrollList_GetData(self.mouseOverRow))
    end
end

function CampaignBrowser:DoHome()
    if(self.mouseOverRow) then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        if(data.type == self.campaignBrowser:GetCampaignType()) then
            SELECT_HOME_CAMPAIGN_DIALOG:Show(data)
        end
    end
end

function CampaignBrowser:CanAbandon()
    if(self.mouseOverRow) then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        local isQueued = IsQueuedForCampaign(data.id, data.isGroup)
        local isCurrentCampaign = data.id == GetAssignedCampaignId() or data.id == GetGuestCampaignId()
        if (isCurrentCampaign and not isQueued) then
            return true
        end
    end
end

function CampaignBrowser:DoAbandon()
    if(self.mouseOverRow) then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        if (data.id == GetAssignedCampaignId()) then
            ABANDON_HOME_CAMPAIGN_DIALOG:Show(data)
        elseif (data.id == GetGuestCampaignId()) then
            ABANDON_GUEST_CAMPAIGN_DIALOG:Show(data)
        end
    end
end

function CampaignBrowser:CanEnter()
    if(self.mouseOverRow) then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        if(data.type == self.campaignBrowser:GetQueueType()) then
            if(data.state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING) then
                return true
            end
        end
    end
end

function CampaignBrowser:DoEnter()
    if(self.mouseOverRow) then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        if(data.type == self.campaignBrowser:GetQueueType()) then
            if(data.state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING) then
                self.campaignBrowser:ShowCampaignQueueReadyDialog(data.id, data.isGroup, data.name)
            end
        end
    end
end

function CampaignBrowser:CanQueue()
    if(self.mouseOverRow) then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        if(data.type == self.campaignBrowser:GetCampaignType()) then
            local canQueueIndividual, canQueueGroup = self.campaignBrowser:CanQueue(data)
            return canQueueIndividual or canQueueGroup
        end
    end
end

function CampaignBrowser:DoQueue()
    if(self.mouseOverRow) then
        local data = ZO_ScrollList_GetData(self.mouseOverRow)
        self.campaignBrowser:DoQueue(data)
    end
end

function CampaignBrowser:CanLeave()
    if(self.mouseOverRow) then
        return self.campaignBrowser:CanLeave(ZO_ScrollList_GetData(self.mouseOverRow))
    end
end

function CampaignBrowser:DoLeave()
    if(self.mouseOverRow) then
        self.campaignBrowser:DoLeave(ZO_ScrollList_GetData(self.mouseOverRow))
    end
end

function CampaignBrowser:GetCampaignBrowser()
    return self.campaignBrowser
end

function CampaignBrowser:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,
        
        --Leave/Abandon
        {
            name = function()
                if(self.mouseOverRow) then
                    if self:CanLeave() then
                        return GetString(SI_CAMPAIGN_BROWSER_LEAVE_QUEUE)
                    elseif self:CanAbandon() then
                        return GetString(SI_CAMPAIGN_BROWSER_ABANDON_CAMPAIGN)
                    end
                end
            end,

            keybind = "UI_SHORTCUT_NEGATIVE",
        
            callback = function()
                if(self.mouseOverRow) then
                    if self:CanLeave() then
                        self:DoLeave()
                    elseif self:CanAbandon() then
                        self:DoAbandon()
                    end
                end
            end,

            visible = function()
                return self:CanLeave() or self:CanAbandon()
            end
        },

        -- Guest
        {
            name = GetString(SI_CAMPAIGN_BROWSER_CHOOSE_GUEST_CAMPAIGN),
            keybind = "UI_SHORTCUT_TERTIARY",
        
            callback = function()
                self:DoGuest()
            end,

            visible = function()                
                return self:CanGuest()
            end
        },

        -- Home
        {
            name = GetString(SI_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN),
            keybind = "UI_SHORTCUT_SECONDARY",
        
            callback = function()
                self:DoHome()
            end,

            visible = function()
                return self:CanHome()
            end
        },

        --Queue/Enter
        {
            name = function()
                if(self.mouseOverRow) then
                    local data = ZO_ScrollList_GetData(self.mouseOverRow)
                    if(data.type == self.campaignBrowser:GetCampaignType()) then
                        return GetString(SI_CAMPAIGN_BROWSER_QUEUE_CAMPAIGN)
                    elseif(data.type == self.campaignBrowser:GetQueueType()) then
                        return GetString(SI_CAMPAIGN_BROWSER_ENTER_CAMPAIGN)
                    end
                end
            end,

            keybind = "UI_SHORTCUT_PRIMARY",
        
            callback = function()
                if(self.mouseOverRow) then
                    local data = ZO_ScrollList_GetData(self.mouseOverRow)
                    if(data.type == self.campaignBrowser:GetCampaignType()) then
                        self:DoQueue()
                    elseif(data.type == self.campaignBrowser:GetQueueType()) then
                        self:DoEnter()
                    end
                end
            end,

            visible = function()
                return self:CanQueue() or self:CanEnter()
            end
        },
    }
end

function CampaignBrowser:SetupAllianceControl(control, data)
    control.data = data
    control:SetTexture(ZO_CampaignBrowser_GetPopulationIcon(data.population))
end

function CampaignBrowser:SetupCampaign(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)    
 
    local name = GetControl(control, "Name")
    name:SetText(data.name)

    local icon = GetControl(control, "Icon")
    if(data.id == GetGuestCampaignId()) then
        icon:SetHidden(false)
        icon:SetTexture("EsoUI/Art/Campaign/campaignBrowser_guestCampaign.dds")
    elseif(data.id == GetAssignedCampaignId()) then
        icon:SetHidden(false)
        icon:SetTexture("EsoUI/Art/Campaign/campaignBrowser_homeCampaign.dds")    
    else
        icon:SetHidden(true)
    end

    local alliancePopulation1 = GetControl(control, "AlliancePopulation1")
    self:SetupAllianceControl(alliancePopulation1, {population = data.alliancePopulation1, campaignId = data.id, alliance = ALLIANCE_ALDMERI_DOMINION})

    local alliancePopulation2 = GetControl(control, "AlliancePopulation2")
    self:SetupAllianceControl(alliancePopulation2, {population = data.alliancePopulation2, campaignId = data.id, alliance = ALLIANCE_EBONHEART_PACT})

    local alliancePopulation3 = GetControl(control, "AlliancePopulation3")
    self:SetupAllianceControl(alliancePopulation3, {population = data.alliancePopulation3, campaignId = data.id, alliance = ALLIANCE_DAGGERFALL_COVENANT})

    GetControl(control, "GroupMembers"):SetHidden(data.numGroupMembers == 0)
    GetControl(control, "Friends"):SetHidden(data.numFriends == 0)
    GetControl(control, "GuildMembers"):SetHidden(data.numGuildMembers == 0)    
end

function CampaignBrowser:SetupCampaignQueue(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)

    local icon = GetControl(control, "Icon")
    local loading = GetControl(control, "Loading")
    local description = GetControl(control, "Description")
    
    local isLoading, message, messageicon = self.campaignBrowser:GetQueueMessage(data.id, data.isGroup, data.state)
    icon:SetHidden(isLoading)
    loading:SetHidden(not isLoading)

    if not isLoading then
        icon:SetTexture(messageicon)
    end

    description:SetText(message)
end

function CampaignBrowser:AddQueueRow(data, isGroup)
    local queued = IsQueuedForCampaign(data.id, isGroup)
    if(queued) then
        data.queues[isGroup] =
        {
            name = data.name,
            type = self.campaignBrowser:GetQueueType(),
            id = data.id,
            state = GetCampaignQueueState(data.id, isGroup),
            isGroup = isGroup,
        }
    end
end

local function HasQueueState(data, isGroup, state)
    local queueInfo = data.queues and data.queues[isGroup]
    if(queueInfo and queueInfo.state == state) then
        return true
    end
end

function CampaignBrowser:RefreshQueueRows(data)
    local hadConfirmingQueues = self.numConfirmingQueues > 0
    if(HasQueueState(data, CAMPAIGN_QUEUE_INDIVIDUAL, CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING)) then
        self.numConfirmingQueues = self.numConfirmingQueues - 1
    end
    if(HasQueueState(data, CAMPAIGN_QUEUE_GROUP, CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING)) then
        self.numConfirmingQueues = self.numConfirmingQueues - 1
    end
    
    data.queues = {}
    
    self:AddQueueRow(data, CAMPAIGN_QUEUE_INDIVIDUAL)
    self:AddQueueRow(data, CAMPAIGN_QUEUE_GROUP)

    if(HasQueueState(data, CAMPAIGN_QUEUE_INDIVIDUAL, CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING)) then
        self.numConfirmingQueues = self.numConfirmingQueues + 1
    end
    if(HasQueueState(data, CAMPAIGN_QUEUE_GROUP, CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING)) then
        self.numConfirmingQueues = self.numConfirmingQueues + 1
    end

    local hasConfirmingQueues = self.numConfirmingQueues > 0
    if(hasConfirmingQueues and not hadConfirmingQueues) then
        self.control:SetHandler("OnUpdate", function(control, seconds)
                -- Ensure that refresh only occurs on second boundaries
                if not self.nextUpdateTimeSeconds or seconds > self.nextUpdateTimeSeconds then
                    self.nextUpdateTimeSeconds  = zo_floor(seconds + 1)
                    self:RefreshVisible()
                end
            end)
    elseif(not hasConfirmingQueues and hadConfirmingQueues) then
        self.control:SetHandler("OnUpdate", nil)
    end
end

function CampaignBrowser:BuildMasterList()
    self.control:SetHandler("OnUpdate", nil)
    self.numConfirmingQueues = 0

    self.masterList = self.campaignBrowser:BuildMasterList()

    for i = 1, #self.masterList do
        self:RefreshQueueRows(self.masterList[i])
    end

    self:BuildCategories()
end

function CampaignBrowser:BuildCategories()
    self.rulesetTypes = self.campaignBrowser:BuildCategoriesList()

    self.tree:Reset()

    for i = 1, GetNumCampaignRulesetTypes() do
        local rulesetIds = self.rulesetTypes[i]
        if(rulesetIds) then
            local numRulesetIds = 0
            for _, _ in pairs(rulesetIds) do
                numRulesetIds = numRulesetIds + 1
            end

            if(numRulesetIds == 1) then
                self.tree:AddNode("ZO_RulesetEntry", {rulesetId = rulesetIds[1], noHeader = true}, nil, SOUNDS.DEFAULT_CLICK)
            else
                local parent = self.tree:AddNode("ZO_RulesetTypeHeader", i, nil, SOUNDS.CAMPAIGN_BLADE_SELECTED)
                for _, rulesetId in pairs(rulesetIds) do
                    self.tree:AddNode("ZO_RulesetEntry", {rulesetId = rulesetId, noHeader = false}, parent, SOUNDS.DEFAULT_CLICK)
                end
            end
        end
    end

    self.tree:Commit()
end

function CampaignBrowser:FilterScrollList()
    self.filteredList = {}
       
    for i = 1, #self.masterList do
        local data = self.masterList[i]
        if((self.rulesetTypeFilter == nil or self.rulesetTypeFilter == data.rulesetType) and
           (self.rulesetIdFilter == nil or self.rulesetIdFilter == data.rulesetId)) then
            table.insert(self.filteredList, ZO_ScrollList_CreateDataEntry(self.campaignBrowser:GetCampaignType(), data))
        end
    end
end

function CampaignBrowser:CompareCampaigns(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, ENTRY_SORT_KEYS, self.currentSortOrder)
end

function CampaignBrowser:SortScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)       

    if(self.currentSortKey ~= nil and self.currentSortOrder ~= nil) then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        table.sort(self.filteredList, self.sortFunction)

        --add the queue rows under the campaign rows
        for i = 1, #self.filteredList do
            local entry = self.filteredList[i]
            table.insert(scrollData, entry)
            local data = entry.data
            if(data.queues) then
                if(data.queues[CAMPAIGN_QUEUE_INDIVIDUAL]) then
                    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(self.campaignBrowser:GetQueueType(), data.queues[CAMPAIGN_QUEUE_INDIVIDUAL]))
                end
                if(data.queues[CAMPAIGN_QUEUE_GROUP]) then
                    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(self.campaignBrowser:GetQueueType(), data.queues[CAMPAIGN_QUEUE_GROUP]))
                end
            end
        end
    end
end

function CampaignBrowser:GetRowColors(data, mouseIsOver, control)
    local textColor
    if(data.type == self.campaignBrowser:GetCampaignType()) then
        textColor = ZO_SECOND_CONTRAST_TEXT
    else
        textColor = ZO_NORMAL_TEXT
    end

    if(mouseIsOver) then
        textColor = ZO_SELECTED_TEXT
    else
        if(control.normalColor) then
            textColor = control.normalColor
        end
    end

    return textColor, nil
end

function CampaignBrowser:GetDataByCampaignId(campaignId)
    return self.campaignBrowser:GetDataByCampaignId(campaignId)
end

--Events
------------

function CampaignBrowser:OnCampaignSelectionDataChanged()
    self:RefreshData()
end

function CampaignBrowser:OnCampaignQueueJoined(campaignId)
    local data = self:GetDataByCampaignId(campaignId)
    if(data) then
        self:RefreshQueueRows(data)
        self:RefreshFilters()
    end
end

function CampaignBrowser:OnCampaignQueueLeft(campaignId)
    local data = self:GetDataByCampaignId(campaignId)
    if(data) then
        self:RefreshQueueRows(data)
        self:RefreshFilters()
    end
end

function CampaignBrowser:OnCampaignQueueStateChanged(campaignId)
    local data = self:GetDataByCampaignId(campaignId)
    if(data) then
        self:RefreshQueueRows(data)
        self:RefreshFilters()
    end
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

--Local XML Handlers
---------------------

local g_nextTimeUpdate
local function UpdateWaitingTooltip(control, time)
    if(not g_nextTimeUpdate or time > g_nextTimeUpdate) then
        g_nextTimeUpdate = time + 1
        CAMPAIGN_BROWSER:QueueRowIcon_OnMouseEnter(control)
    end
end

function CampaignBrowser:QueueRowIcon_OnMouseEnter(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
        
    if(data.state == CAMPAIGN_QUEUE_REQUEST_STATE_WAITING) then
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
    local data = ZO_ScrollList_GetData(control:GetParent())

    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    if(data.id == GetGuestCampaignId()) then
        SetTooltipText(InformationTooltip, GetString(SI_CAMPAIGN_BROWSER_TOOLTIP_GUEST_CAMPAIGN))
    elseif(data.id == GetAssignedCampaignId()) then
        SetTooltipText(InformationTooltip, GetString(SI_CAMPAIGN_BROWSER_TOOLTIP_HOME_CAMPAIGN))
    end
    
    self:EnterRow(control:GetParent())
end

function CampaignBrowser:RowIcon_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    self:ExitRow(control:GetParent())
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
        local queueWaitSeconds = GetSelectionCampaignQueueWaitTime(data.campaignId)
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
    if(button == MOUSE_BUTTON_INDEX_RIGHT and upInside) then
        ClearMenu()

        if(self:CanQueue()) then
            AddMenuItem(GetString(SI_CAMPAIGN_BROWSER_QUEUE_CAMPAIGN), function() self:DoQueue() end)
        end
        if(self:CanHome()) then
            AddMenuItem(GetString(SI_CAMPAIGN_BROWSER_CHOOSE_HOME_CAMPAIGN), function() self:DoHome() end)
        end
        if(self:CanGuest()) then
            AddMenuItem(GetString(SI_CAMPAIGN_BROWSER_CHOOSE_GUEST_CAMPAIGN), function() self:DoGuest() end)
        end
        if(self:CanAbandon()) then
            AddMenuItem(GetString(SI_CAMPAIGN_BROWSER_ABANDON_CAMPAIGN), function() self:DoAbandon() end)
        end
        
        self:ShowMenu(control)
    end
end

function CampaignBrowser:Row_OnMouseDoubleClick(control)
    if self:CanQueue() then
        self:DoQueue()
    end
end

function CampaignBrowser:QueueRow_OnMouseUp(control, button, upInside)
    if(button == MOUSE_BUTTON_INDEX_RIGHT and upInside) then
        ClearMenu()

        if(self:CanEnter()) then
            AddMenuItem(GetString(SI_CAMPAIGN_BROWSER_ENTER_CAMPAIGN), function() self:DoEnter() end)
        end
        if(self:CanLeave()) then
            AddMenuItem(GetString(SI_CAMPAIGN_BROWSER_LEAVE_QUEUE), function() self:DoLeave() end)
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
