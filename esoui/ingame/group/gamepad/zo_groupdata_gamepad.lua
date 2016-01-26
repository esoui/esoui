local ZO_GroupDataManager_Gamepad = GroupMembersManager_Shared:Subclass()

function ZO_GroupDataManager_Gamepad:New(control)
    local manager = ZO_Object.New(self)
    manager:Initialize(control)
    return manager
end

function ZO_GroupDataManager_Gamepad:Initialize(control)
    GroupMembersManager_Shared.Initialize(self, control)

    GAMEPAD_GROUP_DATA_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GroupData_Gamepad)
    GAMEPAD_GROUP_DATA_FRAGMENT:RegisterCallback("StateChange",
        function(oldState, newState)
    	    if newState == SCENE_FRAGMENT_SHOWING then
                self:RefreshQueuedStatus(IsCurrentlySearchingForGroup())
	        end
        end
    )

    local function OnRaidLifeUpdate(event, currentCounter)
        if not IsRaidInProgress() and not HasRaidEnded() then
            currentCounter = nil
        else
            currentCounter = currentCounter or GetRaidReviveCounterInfo()
        end
        self:UpdateRaidLife(currentCounter)
    end

    local function OnGroupingToolsStatusUpdate(isSearching)
        if self:IsShowing() then
            self:RefreshQueuedStatus(isSearching)
        end
    end

    control:RegisterForEvent(EVENT_RAID_REVIVE_COUNTER_UPDATE, OnRaidLifeUpdate)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnRaidLifeUpdate)
    control:RegisterForEvent(EVENT_RAID_TIMER_STATE_UPDATE, OnRaidLifeUpdate)
    control:RegisterForEvent(EVENT_GROUPING_TOOLS_STATUS_UPDATE, function(event, ...) OnGroupingToolsStatusUpdate(...) end)

    self:InitializeData()
    self:Update()
end

function ZO_GroupDataManager_Gamepad:InitializeData()
    self.headerData = {
        titleText = GetString(SI_MAIN_MENU_GROUP),
    }

    self.footerData = {
        data1HeaderText = GetString(SI_GAMEPAD_GROUP_LIST_PANEL_GROUP_MEMBERS_LABEL),
        -- data2HeaderText is the Soul Reservoir (which is hidden until required)
        data3HeaderText = GetString(SI_LFG_QUEUE_STATUS),
    }
end

function ZO_GroupDataManager_Gamepad:UpdateRaidLife(currentCounter)
    if currentCounter then
        self.footerData.data2HeaderText = GetString(SI_GAMEPAD_GROUP_LIST_PANEL_SOUL_RESERVOIR_LABEL)
        self.footerData.data2Text = zo_strformat(SI_GAMEPAD_GROUP_LIST_PANEL_SOUL_RESERVOIR_COUNT, currentCounter)
    else
        self.footerData.data2HeaderText = nil
        self.footerData.data2Text = nil
    end

    if self:IsShowing() then
        CALLBACK_MANAGER:FireCallbacks("OnGroupStatusChange")
    end
end

function ZO_GroupDataManager_Gamepad:RefreshQueuedStatus(isSearching)
    self.footerData.data3Text = isSearching and GetString(SI_LFG_QUEUE_STATUS_QUEUED) or GetString(SI_LFG_QUEUE_STATUS_NOT_QUEUED)
    self.footerData.showLoading = isSearching
    if self:IsShowing() then
        CALLBACK_MANAGER:FireCallbacks("OnGroupStatusChange")
    end
end

function ZO_GroupDataManager_Gamepad:IsShowing()
    return GAMEPAD_GROUP_DATA_FRAGMENT:IsShowing()
end

function ZO_GroupDataManager_Gamepad:GetHeaderData()
    return self.headerData
end

function ZO_GroupDataManager_Gamepad:GetFooterData()
    return self.footerData
end

function ZO_GroupDataManager_Gamepad:Update()
    self.footerData.data1Text = self:GetGroupSizeText()
    if self:IsShowing() then
        CALLBACK_MANAGER:FireCallbacks("OnGroupStatusChange")
    end
end

function ZO_GroupDataManager_Gamepad_OnInitialized(self)
    GAMEPAD_GROUP_DATA = ZO_GroupDataManager_Gamepad:New(self)
end