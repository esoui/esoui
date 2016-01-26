local UPDATE_RATE = 1

ZO_MapKeepSummary_Shared = ZO_Object:Subclass()

function ZO_MapKeepSummary_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_MapKeepSummary_Shared:Initialize(control)
    self.control = control
    control:SetHandler("OnUpdate", function(_, time)
        if(self.nextUpdate == nil or time > self.nextUpdate) then
            self:RefreshTimeDependentControls()
            self.nextUpdate = time + UPDATE_RATE
        end
    end)

    self.fragment = ZO_FadeSceneFragment:New(control)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if(newState == SCENE_FRAGMENT_SHOWING) then
            self:RefreshAll()
        elseif(newState == SCENE_FRAGMENT_HIDDEN) then
            self.keepUpgradeObject = nil
        end
    end)

    local function IfShowing(f)
        if(self.fragment:IsShowing()) then
            f(self)
        end
    end

    local function IfShowingKeep(keepId, bgQueryType, f)
        if(self.keepUpgradeObject and keepId == self.keepUpgradeObject:GetKeep() and DoBattlegroundContextsIntersect(bgQueryType, self.keepUpgradeObject:GetBGQueryType())) then
            f(self)
        end
    end

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapKeepChanged", function()
        IfShowing(self.RefreshAll)
    end)
    control:RegisterForEvent(EVENT_GUILD_NAME_AVAILABLE, function()
        IfShowing(self.RefreshGuildOwner)
    end)
    control:RegisterForEvent(EVENT_KEEP_ALLIANCE_OWNER_CHANGED, function(_, keepId, bgContext)
        IfShowingKeep(keepId, bgContext, self.RefreshAll)
    end)
    control:RegisterForEvent(EVENT_KEEP_GUILD_CLAIM_UPDATE, function(_, keepId, bgContext)
        IfShowingKeep(keepId, bgContext, self.RefreshGuildOwner)
    end)
    control:RegisterForEvent(EVENT_KEEP_INITIALIZED, function(_, keepId, bgContext)
        IfShowingKeep(keepId, bgContext, self.RefreshAll)
    end)
    control:RegisterForEvent(EVENT_KEEPS_INITIALIZED, function()
        IfShowing(self.RefreshAll)
    end)

    self.rowPool = ZO_ControlPool:New(self.rowLayout, control, "UpgradeRow")
    self.rowPool:SetCustomFactoryBehavior(function(control)
        control.allianceTexture = control:GetNamedChild("Alliance")
    end)
end

function ZO_MapKeepSummary_Shared:InitializeRows()
    self.rowPool:ReleaseAllObjects()
    local lastRow
    local keepId = self.keepUpgradeObject:GetKeep()
    local keepType = GetKeepType(keepId)
    for i = 1, self.keepUpgradeObject:GetNumUpgradeTypes() do
        local row = self.rowPool:AcquireObject(i)
        if(keepType == KEEPTYPE_KEEP) then
            self.keepUpgradeObject:SetResourceType(i)
        else
            self.keepUpgradeObject:SetUpgradePath(i)
        end  
        row:GetNamedChild("ResourceName"):SetText(self.keepUpgradeObject:GetUpgradeTypeName())
        if(lastRow) then
            row:SetAnchor(TOPLEFT, lastRow, BOTTOMLEFT, 0, 20)
        else
            row:SetAnchor(TOPLEFT, self.control:GetNamedChild("Alliance"), BOTTOMLEFT, 0, 37)
        end
        lastRow = row
    end
end

function ZO_MapKeepSummary_Shared:RefreshAll()
    self:RefreshData()
    self:RefreshAlliance()
    self:RefreshGuildOwner()
    self:RefreshTimeDependentControls()
end

function ZO_MapKeepSummary_Shared:GetFragment()
    return self.fragment
end

function ZO_MapKeepSummary_Shared:GetKeepUpgradeObject()
    -- stub
end

function ZO_MapKeepSummary_Shared:RefreshData()
    self.keepUpgradeObject = self:GetKeepUpgradeObject()
    self:InitializeRows()
end

function ZO_MapKeepSummary_Shared:RefreshAlliance()
    local alliance = self.keepUpgradeObject:GetAlliance()
    local allianceControl = self.control:GetNamedChild("Alliance")
    allianceControl.alliance = alliance
    allianceControl:SetTexture(GetLargeAllianceSymbolIcon(alliance))
end

function ZO_MapKeepSummary_Shared:RefreshGuildOwner()
    local guildName = self.keepUpgradeObject:GetGuildOwner()
    if(guildName == "") then
        guildName = GetString(SI_KEEP_UNCLAIMED)
    end
    self.control:GetNamedChild("GuildOwner"):SetText(guildName)
end

function ZO_MapKeepSummary_Shared:GenerateRemainingTimeLabel(current, forNextLevel, resourceRate, level)
    if(self.keepUpgradeObject:IsInputEnemyControlled()) then
        return GetString(SI_KEEP_UPGRADE_ENEMY_CONTROLLED)
    elseif(level >= MAX_KEEP_UPGRADE_LEVELS - 1) then
        return GetString(SI_KEEP_UPGRADE_AT_MAX)
    elseif(forNextLevel <= 0 or resourceRate <= 0 or current > forNextLevel) then
        return GetString(SI_KEEP_UPGRADE_TIME_TO_NEXT_LEVEL_INVALID)
    else        
        local timeRemaining = ((forNextLevel - current) / resourceRate) * 60
        local timeText = ZO_FormatCountdownTimer(timeRemaining)
        return zo_strformat(SI_KEEP_UPGRADE_TIME_TO_NEXT_LEVEL, timeText)
    end
end

function ZO_MapKeepSummary_Shared:RefreshTimeDependentControls()
    local keepId = self.keepUpgradeObject:GetKeep()
    local keepType = GetKeepType(keepId)
    for i, row in ipairs(self.rowPool:GetActiveObjects()) do
        if(keepType == KEEPTYPE_KEEP) then
            self.keepUpgradeObject:SetResourceType(i)
        else
            self.keepUpgradeObject:SetUpgradePath(i)
        end  

        if(keepType == KEEPTYPE_KEEP) then
            local resourceKeepId = GetResourceKeepForKeep(keepId, i)
            local alliance = GetKeepAlliance(resourceKeepId, self.keepUpgradeObject:GetBGQueryType())
            row.allianceTexture:SetHidden(false)
            row.allianceTexture.alliance = alliance
            row.allianceTexture:SetTexture(GetLargeAllianceSymbolIcon(alliance))
        else
            row.allianceTexture:SetHidden(true)
        end

        local level = self.keepUpgradeObject:GetUpgradeLevel()
        row:GetNamedChild("Level"):SetText(level)

        local current, forNextLevel = self.keepUpgradeObject:GetUpgradeLevelProgress(level)  
        local resourceRate = self.keepUpgradeObject:GetRate()
        local remainingTimeText = self:GenerateRemainingTimeLabel(current, forNextLevel, resourceRate, level)
        row:GetNamedChild("TimeUntilNextLevel"):SetText(remainingTimeText)
    end
end
