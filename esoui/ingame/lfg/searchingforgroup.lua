local SearchingForGroupManager = ZO_Object:Subclass()

function SearchingForGroupManager:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end


do
    local STATUS_HEADER_TEXT = GetString(SI_LFG_QUEUE_STATUS)
    local ESTIMATED_HEADER_TEXT = GetString(SI_GAMEPAD_LFG_QUEUE_ESTIMATED)
    local ACTUAL_HEADER_TEXT = GetString(SI_GAMEPAD_LFG_QUEUE_ACTUAL)
    local NO_ICON = ""
    local LOADING_ICON = zo_iconFormat(ZO_TIMER_ICON_32, 24, 24)

    function SearchingForGroupManager:Initialize(control)
        self.control = control
        self.leaveQueueButton = control:GetNamedChild("LeaveQueueButton")
    
        self.statusLabel = control:GetNamedChild("Status")
        self.estimatedTimeLabel = control:GetNamedChild("EstimatedTime")
        self.actualTimeLabel = control:GetNamedChild("ActualTime")
    
        self:Update()

        local function OnActivityFinderStatusUpdate(status)
            if self.activityFinderStatus ~= status then
                local wasSearching = self.activityFinderStatus == ACTIVITY_FINDER_STATUS_QUEUED
                self.activityFinderStatus = status
                local searching = self.activityFinderStatus == ACTIVITY_FINDER_STATUS_QUEUED

                local icon = searching and LOADING_ICON or NO_ICON
                local statusLabelText = zo_strformat(SI_ACTIVITY_QUEUE_STATUS_LABEL_FORMAT, STATUS_HEADER_TEXT, icon, GetString("SI_ACTIVITYFINDERSTATUS", status))
                self.statusLabel:SetText(statusLabelText)

                self.leaveQueueButton:SetEnabled(searching and IsUnitSoloOrGroupLeader("player"))
                
                if not searching then
                    self.actualTimeLabel:SetText("")
                    self.estimatedTimeLabel:SetText("")
                end

                self:Update()

                if searching then
                    PlaySound(SOUNDS.LFG_SEARCH_STARTED)
                elseif wasSearching then
                    PlaySound(SOUNDS.LFG_SEARCH_FINISHED)
                end
            end
        end

        local lastUpdateS = 0
        local function OnUpdate(control, currentFrameTimeSeconds)
            if currentFrameTimeSeconds - lastUpdateS > 1 then
                self:Update()
                lastUpdateS = currentFrameTimeSeconds
            end
        end

        ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnActivityFinderStatusUpdate", OnActivityFinderStatusUpdate)
        control:SetHandler("OnUpdate", OnUpdate)
    end

    function SearchingForGroupManager:Update()
        if self.activityFinderStatus == ACTIVITY_FINDER_STATUS_QUEUED then
            local searchStartTimeMs, searchEstimatedCompletionTimeMs = GetLFGSearchTimes()

            local timeSinceSearchStartMs = GetFrameTimeMilliseconds() - searchStartTimeMs
            local textStartTime = ZO_FormatTimeMilliseconds(timeSinceSearchStartMs, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            self.actualTimeLabel:SetText(zo_strformat(SI_ACTIVITY_QUEUE_STATUS_LABEL_FORMAT, ACTUAL_HEADER_TEXT, NO_ICON, textStartTime))

            if searchEstimatedCompletionTimeMs > 0 then
                local textEstimatedTime = ZO_GetSimplifiedTimeEstimateText(searchEstimatedCompletionTimeMs)
                self.estimatedTimeLabel:SetText(zo_strformat(SI_ACTIVITY_QUEUE_STATUS_LABEL_FORMAT, ESTIMATED_HEADER_TEXT, NO_ICON, textEstimatedTime))
            else
                self.estimatedTimeLabel:SetText("")
            end
        end
    end
end

function ZO_SearchingForGroup_OnInitialized(self)
    SEARCHING_FOR_GROUP = SearchingForGroupManager:New(self)
end

function ZO_SearchingForGroupQueueButton_OnClicked(self, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        ZO_Dialogs_ShowDialog("LFG_LEAVE_QUEUE_CONFIRMATION")
    end
end