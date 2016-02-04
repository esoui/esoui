local ActivityQueueData_Gamepad = ZO_Object:Subclass()

function ActivityQueueData_Gamepad:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ActivityQueueData_Gamepad:Initialize(control)
    GAMEPAD_ACTIVITY_QUEUE_DATA_FRAGMENT = ZO_FadeSceneFragment:New(control)
    GAMEPAD_ACTIVITY_QUEUE_DATA_FRAGMENT:RegisterCallback("StateChange",
        function(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                self:RefreshQueuedStatus(IsCurrentlySearchingForGroup())
            end
        end
    )

    local function OnGroupingToolsStatusUpdate(event, isSearching)
        if self:IsShowing() then
            self:RefreshQueuedStatus(isSearching)
        end
    end

    local lastUpdateS = 0
    local function OnUpdate(control, currentFrameTimeSeconds)
        if currentFrameTimeSeconds - lastUpdateS > 1 then
            self:Update()
            lastUpdateS = currentFrameTimeSeconds
        end
    end

    control:RegisterForEvent(EVENT_GROUPING_TOOLS_STATUS_UPDATE, OnGroupingToolsStatusUpdate)
    control:SetHandler("OnUpdate", OnUpdate)

    self.footerData = { }
end

do
    local STATUS_HEADER_TEXT = GetString(SI_LFG_QUEUE_STATUS)
    local STATUS_QUEUED_TEXT = GetString(SI_LFG_QUEUE_STATUS_QUEUED)
    local STATUS_NOT_QUEUED_TEXT = GetString(SI_LFG_QUEUE_STATUS_NOT_QUEUED)
    local ESTIMATED_HEADER_TEXT = GetString(SI_GAMEPAD_LFG_QUEUE_ESTIMATED)
    local ACTUAL_HEADER_TEXT = GetString(SI_GAMEPAD_LFG_QUEUE_ACTUAL)

    function ActivityQueueData_Gamepad:RefreshQueuedStatus(isSearching)
        self.isSearching = isSearching

        local footerData = self.footerData
        footerData.data3ShowLoading = isSearching

        if isSearching then
            footerData.data1HeaderText = ACTUAL_HEADER_TEXT
            self:Update()
        else
            footerData.data1HeaderText = STATUS_HEADER_TEXT
            footerData.data1Text = STATUS_NOT_QUEUED_TEXT
            footerData.data2HeaderText = nil
            footerData.data2Text = nil
            footerData.data3HeaderText = nil
            footerData.data3Text = nil
            if self:IsShowing() then
                GAMEPAD_GENERIC_FOOTER:Refresh(GAMEPAD_ACTIVITY_QUEUE_DATA:GetFooterData())
            end
        end

        if self:IsShowing() then
            CALLBACK_MANAGER:FireCallbacks("OnGroupStatusChange")
        end
    end

    function ActivityQueueData_Gamepad:Update()
        if self.isSearching then
            local footerData = self.footerData
            local searchStartTimeMs, searchEstimatedCompletionTimeMs = GetLFGSearchTimes()

            local timeSinceSearchStartMs = GetFrameTimeMilliseconds() - searchStartTimeMs
            local textStartTime = ZO_FormatTimeMilliseconds(timeSinceSearchStartMs, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            footerData.data1Text = textStartTime

            if searchEstimatedCompletionTimeMs > 0 then
                local textEstimatedTime = ZO_GetSimplifiedTimeEstimateText(searchEstimatedCompletionTimeMs)
                footerData.data2HeaderText = ESTIMATED_HEADER_TEXT
                footerData.data2Text = textEstimatedTime
                footerData.data3HeaderText = STATUS_HEADER_TEXT
                footerData.data3Text = STATUS_QUEUED_TEXT
            else
                footerData.data2HeaderText = STATUS_HEADER_TEXT
                footerData.data2Text = STATUS_QUEUED_TEXT
                footerData.data3HeaderText = nil
                footerData.data3Text = nil
            end

            GAMEPAD_GENERIC_FOOTER:Refresh(GAMEPAD_ACTIVITY_QUEUE_DATA:GetFooterData())
        end
    end
end

function ActivityQueueData_Gamepad:IsShowing()
    return GAMEPAD_ACTIVITY_QUEUE_DATA_FRAGMENT:IsShowing()
end

function ActivityQueueData_Gamepad:GetFooterData()
    return self.footerData
end

function ZO_ActivityQueueDataGamepad_OnInitialized(self)
    GAMEPAD_ACTIVITY_QUEUE_DATA = ActivityQueueData_Gamepad:New(self)
end