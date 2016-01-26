--Keep Upgrade Window Shared
local UPDATE_RATE = 1

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
    ZO_StatusBar_InitializeDefaultColors(self.barControl)
    
    self.levelPool = ZO_ControlPool:New(self.levelLayout, control, "UpgradeLevel")
    self.levelPool:SetCustomFactoryBehavior(function(control)
        control.nameLabel = control:GetNamedChild("Name")
    end)
    self.buttonPool = ZO_ControlPool:New(self.buttonLayout, control, "UpgradeButton")
    self.buttonPool:SetCustomFactoryBehavior(function(control)
        control.lockTexture = control:GetNamedChild("Lock")
        control.iconTexture = control:GetNamedChild("Icon")
    end)
    
    control:SetHandler("OnUpdate", function(_, time)
        if(self.nextUpdate == nil or time > self.nextUpdate) then
            self:RefreshTimeDependentControls()
            self.nextUpdate = time + UPDATE_RATE
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

function ZO_MapKeepUpgrade_Shared:RefreshAll()
    -- stub
end

function ZO_MapKeepUpgrade_Shared:RefreshData()
    -- stub
end

function ZO_MapKeepUpgrade_Shared:RefreshBarLabel()
    self.barLabel:SetText(self.keepUpgradeObject:GetUpgradeTypeName())
end

function ZO_MapKeepUpgrade_Shared:GenerateRemainingTimeLabel(current, forNextLevel, resourceRate, level)
    if(level >= (MAX_KEEP_UPGRADE_LEVELS - 1) or forNextLevel <= 0 or current > forNextLevel) then
        return nil
    elseif(resourceRate <= 0) then
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
    if(remainingTimeText) then
        self.timeContainer:SetHidden(false)
        self.timeUntilNextLevelLabel:SetText(remainingTimeText)
    else
        self.timeContainer:SetHidden(true)
    end
end

function ZO_MapKeepUpgrade_Shared:RefreshLevels()
    self.levelPool:ReleaseAllObjects()
    self.buttonPool:ReleaseAllObjects()
    local prevLevelSection

    self.buttons = {}
    local params = self.symbolParams
    for currentLevel = 0, MAX_KEEP_UPGRADE_LEVELS - 1 do
        local numUpgrades = self.keepUpgradeObject:GetNumLevelUpgrades(currentLevel)
        if(numUpgrades > 0) then
            local buttonList = {}
            self.buttons[#self.buttons + 1] = buttonList

            local levelSection = self.levelPool:AcquireObject()
            levelSection.level = currentLevel
            levelSection.nameLabel:SetText(zo_strformat(SI_KEEP_UPGRADE_LEVEL_SECTION_HEADER, currentLevel))

            if(prevLevelSection) then
                levelSection:SetAnchor(TOPLEFT, prevLevelSection, BOTTOMLEFT, params.SYMBOL_SECTION_OFFSET_X, params.SYMBOL_SECTION_OFFSET_Y)
            else
                levelSection:SetAnchor(TOPLEFT, self.currentLevelLabel, BOTTOMLEFT, params.FIRST_SECTION_OFFSET_X, params.FIRST_SECTION_OFFSET_Y)
            end

            prevLevelSection = levelSection
                            
            local levelSectionButtonsContainer = levelSection:GetNamedChild("Buttons")
            local lastButton

            for i = 1, numUpgrades do
                local name, description, icon, atPercent, isActive = self.keepUpgradeObject:GetLevelUpgradeInfo(currentLevel, i)
                local button = self.buttonPool:AcquireObject()
                button.iconTexture:SetTexture(icon)
                button:SetParent(levelSectionButtonsContainer)
                button.level = currentLevel
                button.info = {name = name, description = description, isActive = isActive }
                button.index = i
                if(lastButton) then
                    button:SetAnchor(TOPLEFT, lastButton, TOPRIGHT, params.SYMBOL_PADDING_X, 0)
                else
                    button:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, params.SYMBOL_PADDING_Y)
                end
                buttonList[#buttonList + 1] = button
                lastButton = button
            end
        end
    end
end

function ZO_MapKeepUpgrade_Shared:RefreshLevelsEnabled()
    local level = self.keepUpgradeObject:GetUpgradeLevel()
    for _, levelSection in pairs(self.levelPool:GetActiveObjects()) do
        if(levelSection.level <= level) then
            levelSection.nameLabel:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
        else
            levelSection.nameLabel:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
        end 
    end

    for _, button in pairs(self.buttonPool:GetActiveObjects()) do
        local _, _, _, _, isActive = self.keepUpgradeObject:GetLevelUpgradeInfo(button.level, button.index)
        button.lockTexture:SetHidden(isActive)
        ZO_ActionSlot_SetUnusable(button.iconTexture, not isActive)
    end
end

function ZO_MapKeepUpgrade_Shared:RefreshTimeDependentControls()
    self:RefreshLevelsEnabled()
    self:RefreshBar()
end

--Local XML

function ZO_MapKeepUpgrade_Shared:Button_OnMouseEnter(button)
    InitializeTooltip(KeepUpgradeTooltip, button, TOPLEFT, 5, 0)
    self.keepUpgradeObject:SetUpgradeTooltip(button.level, button.index)
end

function ZO_MapKeepUpgrade_Shared:Button_OnMouseExit(button)
    ClearTooltip(KeepUpgradeTooltip)
end

function ZO_MapKeepUpgrade_Shared:Time_OnMouseEnter(label)
    InitializeTooltip(InformationTooltip, label, TOPLEFT, 10, 0)
    self.keepUpgradeObject:SetRateTooltip()    
end

function ZO_MapKeepUpgrade_Shared:Time_OnMouseExit(label)
    ClearTooltip(InformationTooltip)
end

function ZO_MapKeepUpgrade_Shared:Bar_OnMouseEnter(bar)
    if(not self.timeContainer:IsHidden()) then
        self:Time_OnMouseEnter(self.timeContainer)
    end
end

function ZO_MapKeepUpgrade_Shared:Bar_OnMouseExit(bar)
    self:Time_OnMouseExit(self.timeContainer)
end
