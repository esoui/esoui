local SearchingForGroupManager = ZO_Object:Subclass()

function SearchingForGroupManager:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function SearchingForGroupManager:Initialize(control)
    self.control = control
    self.spinner = control:GetNamedChild("Spinner")

    self.estimatedTimeControl = control:GetNamedChild("EstimatedTime")
    self.estimatedTimeValueControl = self.estimatedTimeControl:GetNamedChild("Value")

    self.actualTimeControl = control:GetNamedChild("ActualTime")
    self.actualTimeValueControl = self.actualTimeControl:GetNamedChild("Value")

    self.searching = IsCurrentlySearchingForGroup()
    self:Update()

    local function OnGroupingToolsStatusUpdate(searching)
        if self.searching ~= searching then
            self.searching = searching
            self:Update()

            if searching then
                PlaySound(SOUNDS.LFG_SEARCH_STARTED)
            else
                PlaySound(SOUNDS.LFG_SEARCH_FINISHED)
            end
        end
    end

    local function OnPlayerActivated()
        OnGroupingToolsStatusUpdate(IsCurrentlySearchingForGroup())
    end

    local lastUpdateS = 0
    local function OnUpdate(control, currentFrameTimeSeconds)
        if currentFrameTimeSeconds - lastUpdateS > 1 then
            self:Update()
            lastUpdateS = currentFrameTimeSeconds
        end
    end

    control:RegisterForEvent(EVENT_GROUPING_TOOLS_STATUS_UPDATE, function(event, ...) OnGroupingToolsStatusUpdate(...) end)
    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function(event, ...) OnPlayerActivated(...) end)
    control:SetHandler("OnUpdate", OnUpdate)
end

function SearchingForGroupManager:Update()
    if self.searching then
        self.spinner:Show()
        self.estimatedTimeControl:SetHidden(false)
        self.actualTimeControl:SetHidden(false)

        local searchStartTimeMs, searchEstimatedCompletionTimeMs = GetLFGSearchTimes()

        local textEstimatedTime = ZO_GetSimplifiedTimeEstimateText(searchEstimatedCompletionTimeMs)
        self.estimatedTimeValueControl:SetText(textEstimatedTime)

        local timeSinceSearchStartMs = GetFrameTimeMilliseconds() - searchStartTimeMs
        local textStartTime = ZO_FormatTimeMilliseconds(timeSinceSearchStartMs, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
        self.actualTimeValueControl:SetText(textStartTime)
    else
        self.spinner:Hide()
        self.estimatedTimeControl:SetHidden(true)
        self.actualTimeControl:SetHidden(true)
    end
end

function ZO_SearchingForGroup_OnInitialized(self)
    SEARCHING_FOR_GROUP = SearchingForGroupManager:New(self)
end