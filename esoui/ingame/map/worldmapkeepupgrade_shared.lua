--Keep Upgrade Window Shared
local UPDATE_RATE_SECONDS = 1

ZO_MapKeepUpgrade_Shared = ZO_Object:Subclass()

function ZO_MapKeepUpgrade_Shared:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_MapKeepUpgrade_Shared:Initialize(control)
    self.control = control
    self.currentLevelLabel = control:GetNamedChild("CurrentLevel")
    self.barLabel = control:GetNamedChild("BarLabel")
    self.barControl = control:GetNamedChild("Bar")
    self.timeContainer = control:GetNamedChild("Time")
    self.timeUntilNextLevelLabel = control:GetNamedChild("TimeUntilNextLevel")
    self.levelsControl = control:GetNamedChild("Levels")
    ZO_StatusBar_InitializeDefaultColors(self.barControl)

    self.levelsGridList = self.gridListClass:New(self.levelsControl, ZO_GRID_SCROLL_LIST_DONT_AUTOFILL)

    local function WorldMapKeepUpgradeGridHeaderEntrySetup(control, data, list)
        ZO_DefaultGridHeaderSetup(control, data, list)

        local level = self.keepUpgradeObject:GetUpgradeLevel()
        if data.data.level <= level then
            control:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
        else
            control:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
        end
    end

    local function WorldMapKeepUpgradeGridEntrySetup(control, data, list)
        ZO_DefaultGridEntrySetup(control, data, list)

        local level = self.keepUpgradeObject:GetUpgradeLevel()
        local isActive = level >= data.dataSource.level
        local lockControl = control:GetNamedChild("Lock")
        lockControl:SetHidden(isActive)
        ZO_ActionSlot_SetUnusable(control.icon, not isActive)
    end

    local HIDE_CALLBACK = nil
    local SPACING_X = 6
    local params = self.symbolParams
    self.levelsGridList:SetGridEntryTemplate(self.buttonLayout, params.SYMBOL_ICON_SIZE, params.SYMBOL_ICON_SIZE, WorldMapKeepUpgradeGridEntrySetup, HIDE_CALLBACK, ZO_ObjectPool_DefaultResetControl, SPACING_X, params.GRID_DEFAULT_SPACING_Y)
    self.levelsGridList:SetHeaderTemplate(self.labelLayout, ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_HEIGHT, WorldMapKeepUpgradeGridHeaderEntrySetup)
    self.levelsGridList:SetHeaderPrePadding(params.SYMBOL_PADDING_Y)

    control:SetHandler("OnUpdate", function(_, timeS)
        if self.nextUpdateS == nil or timeS > self.nextUpdateS then
            self:RefreshTimeDependentControls()
            self.nextUpdateS = timeS + UPDATE_RATE_SECONDS
        end
    end)

    self.fragment = ZO_FadeSceneFragment:New(control)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWN then
            self:OnFragmentShown()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnFragmentHidden()
        end
    end)

    local function IfShowing(callback)
        if self.fragment:IsShowing() then
            callback(self)
        end
    end

    local function IfShowingKeep(keepId, bgQueryType, callback)
        if self.keepUpgradeObject and keepId == self.keepUpgradeObject:GetKeep() and DoBattlegroundContextsIntersect(bgQueryType, self.keepUpgradeObject:GetBGQueryType()) then
            callback(self)
        end
    end

    control:RegisterForEvent(EVENT_KEEP_ALLIANCE_OWNER_CHANGED, function(_, keepId, bgContext)
            IfShowingKeep(keepId, bgContext, self.RefreshAll)
        end)
    control:RegisterForEvent(EVENT_KEEP_INITIALIZED, function(_, keepId, bgContext)
            IfShowingKeep(keepId, bgContext, self.RefreshAll)
        end)
    control:RegisterForEvent(EVENT_KEEPS_INITIALIZED, function()
            IfShowing(self.RefreshAll)
        end)

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapKeepChanged", function()
            IfShowing(self.RefreshAll)
        end)
end

function ZO_MapKeepUpgrade_Shared:GetFragment()
    return self.fragment
end

function ZO_MapKeepUpgrade_Shared:OnFragmentShown()
    self:RefreshAll()
end

function ZO_MapKeepUpgrade_Shared:OnFragmentHidden()
    self.keepUpgradeObject = nil
    -- clear the grid list when we hide the fragment because when the screen resizes
    -- it will refresh the list, but updating the entries relies on self.keepUpgradeObject
    -- and we just set that to nil
    self.levelsGridList:ClearGridList()
    self.levelsGridList:CommitGridList()
end

function ZO_MapKeepUpgrade_Shared:OnGridListSelectedDataChanged(previousData, newData)
    -- To be overridden
end

function ZO_MapKeepUpgrade_Shared:RefreshAll()
    self:RefreshData()
    self:RefreshLevels()
    self:RefreshBarLabel()
    self:RefreshTimeDependentControls()
end

function ZO_MapKeepUpgrade_Shared:RefreshData()
    -- To be overridden
end

function ZO_MapKeepUpgrade_Shared:RefreshBarLabel()
    self.barLabel:SetText(self.keepUpgradeObject:GetUpgradeTypeName())
end

function ZO_MapKeepUpgrade_Shared:GenerateRemainingTimeLabel(current, forNextLevel, resourceRate, level)
    if level >= GetKeepMaxUpgradeLevel(self.keepUpgradeObject:GetKeep()) or forNextLevel <= 0 or current > forNextLevel then
        return nil
    elseif resourceRate <= 0 then
        return GetString(SI_KEEP_UPGRADE_INVALID_TIME)
    else
        local timeRemaining = ((forNextLevel - current) / resourceRate) * 60
        return ZO_FormatCountdownTimer(timeRemaining)
    end
end

function ZO_MapKeepUpgrade_Shared:RefreshBar()
    local level = self.keepUpgradeObject:GetUpgradeLevel()
    self.currentLevelLabel:SetText(level)

    local cur, max = self.keepUpgradeObject:GetUpgradeLevelProgress(level)
    self.barControl:SetMinMax(0, max)
    self.barControl:SetValue(cur)

    local resourceRate = self.keepUpgradeObject:GetRate()
    local remainingTimeText = self:GenerateRemainingTimeLabel(cur, max, resourceRate, level)
    if remainingTimeText then
        self.timeContainer:SetHidden(false)
        self.timeUntilNextLevelLabel:SetText(remainingTimeText)
    else
        self.timeContainer:SetHidden(true)
    end
end

function ZO_MapKeepUpgrade_Shared:RefreshLevels()
    self.levelsGridList:ClearGridList()

    for currentLevel = 0, GetKeepMaxUpgradeLevel(self.keepUpgradeObject:GetKeep()) do
        local numUpgrades = self.keepUpgradeObject:GetNumLevelUpgrades(currentLevel)
        if numUpgrades > 0 then
            local levelHeaderText = zo_strformat(SI_KEEP_UPGRADE_LEVEL_SECTION_HEADER, currentLevel)
            for i = 1, numUpgrades do
                local name, description, icon, atPercent, isActive = self.keepUpgradeObject:GetLevelUpgradeInfo(currentLevel, i)
                local data = {
                    index = i,
                    gridHeaderName = levelHeaderText,
                    level = currentLevel,
                    name = name,
                    description = description,
                    icon = icon,
                    atPercent = atPercent,
                    isActive = isActive,
                }

                self.levelsGridList:AddEntry(ZO_GridSquareEntryData_Shared:New(data))
            end
        end
    end

    self.levelsGridList:CommitGridList()
end

function ZO_MapKeepUpgrade_Shared:RefreshTimeDependentControls()
    self.levelsGridList:RefreshGridList()
    self:RefreshBar()
end
