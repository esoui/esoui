local NUM_KEEP_UPGRADE_LEVELS = 6

--Multi-Level Status Bar
---------------------------

local ZO_MultiLevelStatusBar = ZO_Object:Subclass()

function ZO_MultiLevelStatusBar:New(control, numLevels, color, projectedColor, width)
    local manager = ZO_Object.New(self)

    manager.numLevels = numLevels
    manager.control = control
    control:SetWidth(width)

    manager.progress = GetControl(control, "Progress")
    manager.progress:SetMinMax(0,1)
    manager.progress:SetColor(color:UnpackRGBA())
    manager.projected = GetControl(control, "Projected")
    manager.projected:SetMinMax(0,1)
    if(projectedColor) then
        manager.projected:SetColor(projectedColor:UnpackRGBA())
    else
        manager.projected:SetHidden(true)
    end
    manager.projected:SetValue(0)

    manager.sections = {}

    local sectionWidth = width / numLevels
    local sectionsContainer = GetControl(control, "Sections")
    local prevControl = nil
    for i = 0, numLevels-1 do
        local control = CreateControlFromVirtual(control:GetName().."Section",  sectionsContainer, "ZO_MultiLevelStatusBarSection", i)
        GetControl(control, "Label"):SetText(i)
        control.index = i
        control.manager = manager
        control:SetWidth(sectionWidth)
        if(not prevControl) then
            control:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
            control:SetAnchor(BOTTOMLEFT, nil, BOTTOMLEFT, 0, 0)
        else
            control:SetAnchor(TOPLEFT, prevControl, TOPRIGHT, 0, 0)
            control:SetAnchor(BOTTOMLEFT, prevControl, BOTTOMRIGHT, 0, 0)
        end
        
        manager.sections[i] = control

        prevControl = control
    end

    return manager
end

function ZO_MultiLevelStatusBar:UpdateSections()
    for i = 0, self.numLevels-1 do
        local section = self.sections[i]
        local color
        local achieved = true
        if(self.progressLevel and i <= self.progressLevel) then
            color = ZO_NORMAL_TEXT
        elseif(self.projectedLevel and i <= self.projectedLevel) then
            color = ZO_NORMAL_TEXT
        else
            achieved = false
            color = ZO_SELECTED_TEXT            
        end
        GetControl(section, "Label"):SetColor(color:UnpackRGBA())
        if(achieved) then
            section:SetTexture("EsoUI/Art/AvA/AvA_resourceStatus_progBar_achieved_overlay_up.dds")
        else
            section:SetTexture("EsoUI/Art/AvA/AvA_resourceStatus_progBar_unachieved_overlay_up.dds")
        end
    end
end

function ZO_MultiLevelStatusBar:SetProgress(level)
    local value = level / (self.numLevels)
    self.progress:SetValue(value)
    
    local highestAchievedLevel = zo_floor(level)
    self.progressLevel = highestAchievedLevel
    
    self:UpdateSections()
end

function ZO_MultiLevelStatusBar:ProjectProgress(level)
    local value = level / (self.numLevels)
    self.projectedLevel = zo_floor(level)
    self.projected:SetValue(value)

    self:UpdateSections()
end

--Keep Upgrade
----------------

local ZO_KeepUpgradeManager = ZO_Object:Subclass()
local UPGRADE_TYPE_RESOURCE_KEEP = 1
local UPGRADE_TYPE_MAIN_KEEP = 2

local RESOURCE_TYPE_TO_UPKEEP_FORMAT =
{
    [RESOURCETYPE_FOOD] = GetString(SI_KEEP_FOOD_UPKEEP_COST_FORMAT),
    [RESOURCETYPE_ORE] = GetString(SI_KEEP_ORE_UPKEEP_COST_FORMAT),
    [RESOURCETYPE_WOOD] = GetString(SI_KEEP_WOOD_UPKEEP_COST_FORMAT),
}

function ZO_KeepUpgradeManager:New(control, numLevels, color, projectedColor, upgradeType, upgradePath, owningWindow, width)
    local manager = ZO_Object.New(self)

    manager.control = control
    manager.owningWindow = owningWindow
    manager.upgradeType = upgradeType
    manager.upgradePath = upgradePath
    manager.upkeepCostHeader = GetControl(control, "UpkeepCostHeader")
    manager.upkeepCost = GetControl(control, "UpkeepCost")
    manager.name = GetControl(control, "Name")
    manager.level = GetControl(control, "Level")
    manager.additionalTokens = 0

    manager.indent = 15
    manager.headerSpacingY = 16
    manager.lineSpacingY = 8
    manager.topOffsetY = 0

    manager.status = ZO_MultiLevelStatusBar:New(GetControl(control, "Status"), numLevels, color, projectedColor, width)

    manager.scrollPane = GetControl(control, "Pane")
    manager.scrollChild = GetControl(manager.scrollPane, "ScrollChild")
    manager.levelHeader = GetControl(control, "LevelHeader")

    manager.bonusLines = ZO_ControlPool:New("ZO_KeepWindowBonusLine", manager.scrollChild, "BonusLine")
    manager.bonusLines:SetCustomResetBehavior(  function(control)
                                                    control:SetHeight(0)
                                                end)

    manager.control:SetHandler("OnUpdate", function() manager:OnUpdate() end)

    return manager
end

function ZO_KeepUpgradeManager:OnUpdate()
    if(self.pendingScrollToHeader) then
        if(not self.delay) then
            self.delay = true
        else
            self.delay = nil
            ZO_Scroll_ScrollControlToTop(self.scrollPane, self.pendingScrollToHeader)
            self.pendingScrollToHeader = nil
        end
    end
end

function ZO_KeepUpgradeManager:Initialize()
    self:UpdateProgress()
    self:ProjectProgress(0)
    self:UpdateLevels()
    self:ScrollToLevel(self:GetUpgradeLevel())
end

function ZO_KeepUpgradeManager:Refresh()
    self:UpdateProgress()
    self:UpdateLevels()
    self:ProjectProgress(self.additionalTokens)
end

function ZO_KeepUpgradeManager:SetName(name)
    self.name:SetText(name)
end

function ZO_KeepUpgradeManager:SetUpgradePath(upgradePath)
    self.upgradePath = upgradePath
end

function ZO_KeepUpgradeManager:GetUpgradeLevel()
    local keepId = self.owningWindow:GetKeepId()
    local battlegroundContext = self.owningWindow:GetBattlegroundContext()

    if(self.upgradeType == UPGRADE_TYPE_RESOURCE_KEEP) then
        if(self.upgradePath == UPGRADEPATH_DEFENSIVE) then
            return GetKeepDefensiveLevel(keepId, battlegroundContext)
        else
            return GetKeepProductionLevel(keepId, battlegroundContext)
        end
    else
        return GetKeepResourceLevel(keepId, battlegroundContext, self.upgradePath)
    end

    return 0
end

function ZO_KeepUpgradeManager:GetUpgradeInfo(level)
    local keepId = self.owningWindow:GetKeepId()
    local battlegroundContext = self.owningWindow:GetBattlegroundContext()
    local path = self.upgradePath
    
    if(self.upgradeType == UPGRADE_TYPE_MAIN_KEEP) then
        return GetKeepResourceInfo(keepId, battlegroundContext, path, level)
    else
        return GetKeepUpgradeInfo(keepId, battlegroundContext, path, level)
    end
end

function ZO_KeepUpgradeManager:GetNumLevelUpgrades(level)
    local keepId = self.owningWindow:GetKeepId()
    local battlegroundContext = self.owningWindow:GetBattlegroundContext()
    local path = self.upgradePath

    if(self.upgradeType == UPGRADE_TYPE_MAIN_KEEP) then
        return GetNumUpgradesForKeepAtResourceLevel(keepId, battlegroundContext, path, level)
    else
        return GetNumUpgradesForKeepAtPathLevel(keepId, battlegroundContext, path, level)
    end   
end

function ZO_KeepUpgradeManager:GetLevelUpgradeInfo(level, index)
    local keepId = self.owningWindow:GetKeepId()
    local battlegroundContext = self.owningWindow:GetBattlegroundContext()
    local path = self.upgradePath

    if(self.upgradeType == UPGRADE_TYPE_MAIN_KEEP) then
        return GetKeepUpgradeDetails(keepId, battlegroundContext, path, level, index)
    else
        return GetKeepUpgradePathDetails(keepId, battlegroundContext, path, level, index)
    end
end

function ZO_KeepUpgradeManager:UpdateProgress()
    local keepId = self.owningWindow:GetKeepId()
    local path = self.upgradePath
    local progressLevel = self:GetUpgradeLevel()
        
    local levelCurrentPoints, levelMaxPoints = self:GetUpgradeInfo(progressLevel)

    if(levelMaxPoints > 0) then
        self.status:SetProgress(progressLevel + (levelCurrentPoints / levelMaxPoints))
    else
        self.status:SetProgress(progressLevel)
    end
end

function ZO_KeepUpgradeManager:ScrollToLevel(level)
    local activeLines = self.bonusLines:GetActiveObjects()
    for _, line in pairs(activeLines) do
        if(line.headerLevel == level) then
            self.pendingScrollToHeader = line
            return
        end
    end
end

local LABEL_HEADER = true
local LABEL_NOT_HEADER = false

function ZO_KeepUpgradeManager:GetUpgradeLabel(isHeader)
    local label = self.bonusLines:AcquireObject()
    label.headerLevel = nil

    if(isHeader) then
        label:SetColor(ZO_HIGHLIGHT_TEXT:UnpackRGBA())
    end

    label:SetHidden(false)
    return label
end

function ZO_KeepUpgradeManager:AnchorUpgradeLabel(label, prevLabel, isHeader)
    local offsetX = 0
    local offsetY = 0

    if(not prevLabel) then
        label:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, self.topOffsetY)
        label:SetWidth(GetControl(self.scrollPane, "Scroll"):GetWidth())
    else
        local prevIsHeader = (prevLabel.headerLevel ~= nil)
        if(isHeader) then
            if(not prevIsHeader) then
                offsetX = -self.indent
            end
            offsetY = self.headerSpacingY
        else
            if(prevIsHeader) then
                offsetX = self.indent
            end
            offsetY = self.lineSpacingY
        end
        label:SetAnchor(TOPLEFT, prevLabel, TOPLEFT, offsetX, offsetY)
        label:SetAnchor(TOPRIGHT, prevLabel, BOTTOMRIGHT, 0, offsetY)   
    end   
end

function ZO_KeepUpgradeManager:UpdateLevels()
    local path = self.upgradePath
    local keepId = self.owningWindow:GetKeepId()
    local activeLevel = self:GetUpgradeLevel()
    
    self.level:SetText(zo_strformat(SI_KEEP_CURRENT_LEVEL, activeLevel))

    self.bonusLines:ReleaseAllObjects()    
    local prevLabel = nil
    for currentLevel = 0, NUM_KEEP_UPGRADE_LEVELS-1 do
        local numUpgrades = self:GetNumLevelUpgrades(currentLevel)
        if(numUpgrades > 0) then
            local label = self:GetUpgradeLabel(LABEL_HEADER)
            label:SetText(zo_strformat(SI_KEEP_UPGRADE_LEVEL_HEADER, currentLevel))
            label.headerLevel = currentLevel
            self:AnchorUpgradeLabel(label, prevLabel, LABEL_HEADER)
            prevLabel = label
                
            for i = 0, numUpgrades - 1 do
                local name, description, atPercent, isActive = self:GetLevelUpgradeInfo(currentLevel, i)
                local label = self:GetUpgradeLabel(LABEL_NOT_HEADER)

                if(atPercent == 0 or isActive) then
                    label:SetText(zo_strformat(SI_KEEP_UPGRADE_NAME_DESCRIPTION, name, description))
                else
                    label:SetText(zo_strformat(SI_KEEP_UPGRADE_NAME_PERCENT_DESCRIPTION, name, atPercent, description))
                end
            
                if(isActive) then
                    label:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
                else
                    label:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
                end          
            
                self:AnchorUpgradeLabel(label, prevLabel, LABEL_NOT_HEADER)
                prevLabel = label
            end
        end
    end
end

function ZO_KeepUpgradeManager:ProjectProgress(additionalTokens)
    self.additionalTokens = additionalTokens

    local keepId = self.owningWindow:GetKeepId()
    local path = self.upgradePath
    local level = self:GetUpgradeLevel()
    
    while(level < NUM_KEEP_UPGRADE_LEVELS) do
        local levelCurrentPoints, levelMaxPoints = self:GetUpgradeInfo(level)
        local pointsToGo = levelMaxPoints - levelCurrentPoints
        if(pointsToGo > additionalTokens) then
            self.status:ProjectProgress(level + ((levelCurrentPoints + additionalTokens) / levelMaxPoints))
            return
        else
            additionalTokens = additionalTokens - pointsToGo
            level = level + 1
        end
    end

    self.status:ProjectProgress(NUM_KEEP_UPGRADE_LEVELS)
end

function ZO_KeepUpgradeManager:GetStatus()
    return self.status
end

--Keep Window Manager
------------------

local ZO_KeepWindowManager = ZO_Object:Subclass()
KEEP_WINDOW = nil

local MAIN_KEEP_MODE = 1
local RESOURCE_KEEP_MODE = 2

local MAIN_KEEP_TAB_SUMMARY = 1
local MAIN_KEEP_TAB_WOOD = 2
local MAIN_KEEP_TAB_FOOD = 3
local MAIN_KEEP_TAB_ORE = 4

local RESOURCE_KEEP_TAB_DEFENSIVE = 1
local RESOURCE_KEEP_TAB_PRODUCTION = 2

local NUM_UPGRADE_LEVELS = 6
local MAIN_UPGRADE_BAR_WIDTH = 630
local RESOURCE_UPGRADE_BAR_WIDTH = 634
local PROJECTED_COLOR = ZO_ColorDef:New(0.224, 0.392, 0.722, 1.000)
local DEFENSIVE_COLOR = ZO_ColorDef:New(0.561, 0.208, 0.298, 1.000)
local PRODUCTION_COLOR = ZO_ColorDef:New(0.388, 0.537, 0.220, 1.000)
local RESOURCE_COLOR = ZO_ColorDef:New(0.647, 0.352, 0.647, 1.000)
local RESOURCE_UPDATE_TIMER = 2

local RESOURCE_OWNER_TO_ICON =
{
    [RESOURCETYPE_WOOD] =
    {
        [ALLIANCE_NONE] = "EsoUI/Art/AvA/AvA_keepStatus_icon_wood_neutral.dds",
        [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/AvA/AvA_keepStatus_icon_wood_aldmeri.dds",
        [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/AvA/AvA_keepStatus_icon_wood_ebonheart.dds",
        [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/AvA/AvA_keepStatus_icon_wood_daggerfall.dds",
    },
    [RESOURCETYPE_FOOD] =
    {
        [ALLIANCE_NONE] = "EsoUI/Art/AvA/AvA_keepStatus_icon_food_neutral.dds",
        [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/AvA/AvA_keepStatus_icon_food_aldmeri.dds",
        [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/AvA/AvA_keepStatus_icon_food_ebonheart.dds",
        [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/AvA/AvA_keepStatus_icon_food_daggerfall.dds",
    },
    [RESOURCETYPE_ORE] =
    {
        [ALLIANCE_NONE] = "EsoUI/Art/AvA/AvA_keepStatus_icon_ore_neutral.dds",
        [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/AvA/AvA_keepStatus_icon_ore_aldmeri.dds",
        [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/AvA/AvA_keepStatus_icon_ore_ebonheart.dds",
        [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/AvA/AvA_keepStatus_icon_ore_daggerfall.dds",
    },
}

local TAB_TO_RESOURCE_TYPE =
{
    [MAIN_KEEP_TAB_WOOD] = RESOURCETYPE_WOOD,
    [MAIN_KEEP_TAB_FOOD] = RESOURCETYPE_FOOD,
    [MAIN_KEEP_TAB_ORE] = RESOURCETYPE_ORE,
}

--Public

function ZO_KeepWindowManager:New(window)
    local manager = ZO_Object.New(self)

    manager.window = window
    manager.title = GetControl(window, "Title")
    manager.allianceOwner = GetControl(window, "AllianceOwner")
    manager.guildOwner = GetControl(window, "GuildOwner")
    manager.allianceOwnerIcon = GetControl(window, "AllianceOwnerIcon")
    manager.mainSummary = GetControl(window, "MainSummary")
    manager.mainResource = GetControl(window, "MainResource")
    manager.resourceDefensive = GetControl(window, "ResourceDefensive")
    manager.resourceProduction = GetControl(window, "ResourceProduction")

    --resource keep
    manager.defensiveUpgrades = ZO_KeepUpgradeManager:New(  GetControl(manager.resourceDefensive, "Upgrade"), 
                                                            NUM_UPGRADE_LEVELS,
                                                            DEFENSIVE_COLOR,
                                                            PROJECTED_COLOR,
                                                            UPGRADE_TYPE_RESOURCE_KEEP,
                                                            UPGRADEPATH_DEFENSIVE,
                                                            manager,
                                                            RESOURCE_UPGRADE_BAR_WIDTH
                                                          )
    manager.defensiveUpgrades:SetName(GetString(SI_KEEP_DEFENSIVE_TITLE))

    manager.productionUpgrades = ZO_KeepUpgradeManager:New( GetControl(manager.resourceProduction, "Upgrade"), 
                                                            NUM_UPGRADE_LEVELS,
                                                            PRODUCTION_COLOR,
                                                            PROJECTED_COLOR,
                                                            UPGRADE_TYPE_RESOURCE_KEEP,
                                                            UPGRADEPATH_PRODUCTION,
                                                            manager,
                                                            RESOURCE_UPGRADE_BAR_WIDTH
                                                           )
    manager.productionUpgrades:SetName(GetString(SI_KEEP_PRODUCTION_TITLE))

    --main keep

    manager.tabControlToTab =
    {
        [ZO_KeepWindowMainSummaryTab] = MAIN_KEEP_TAB_SUMMARY,
        [ZO_KeepWindowMainWoodTab] = MAIN_KEEP_TAB_WOOD,
        [ZO_KeepWindowMainFoodTab] = MAIN_KEEP_TAB_FOOD,
        [ZO_KeepWindowMainOreTab] = MAIN_KEEP_TAB_ORE,
        [ZO_KeepWindowResourceDefensiveTab] = RESOURCE_KEEP_TAB_DEFENSIVE,
        [ZO_KeepWindowResourceProductionTab] = RESOURCE_KEEP_TAB_PRODUCTION,
    }

    manager.rateIconToResourceType =
    {
        [ZO_KeepWindowMainSummaryWoodRateIcon] = RESOURCETYPE_WOOD,
        [ZO_KeepWindowMainSummaryFoodRateIcon] = RESOURCETYPE_FOOD,
        [ZO_KeepWindowMainSummaryOreRateIcon] = RESOURCETYPE_ORE,
    }

    local handleTabClick = function(tabControl) manager:OnTabClicked(tabControl) end
    local visualData = {}
    ZO_CreateUniformIconTabData(visualData, nil, nil, nil, "EsoUI/Art/AvA/AvA_keepStatus_tabIcon_keep.dds", "EsoUI/Art/AvA/AvA_keepStatus_tabIcon_keep_inactive.dds")
    ZO_TabButton_Icon_Initialize(ZO_KeepWindowMainSummaryTab, "FancyBottomEdgeImage", visualData, handleTabClick)
    ZO_TabButton_SetTooltipText(ZO_KeepWindowMainSummaryTab, GetString(SI_KEEP_WINDOW_SUMMARY_TAB))

    ZO_CreateUniformIconTabData(visualData, nil, nil, nil, "EsoUI/Art/AvA/AvA_keepStatus_tabIcon_wood.dds", "EsoUI/Art/AvA/AvA_keepStatus_tabIcon_wood_inactive.dds")
    ZO_TabButton_Icon_Initialize(ZO_KeepWindowMainWoodTab, "FancyBottomEdgeImage", visualData, handleTabClick)
    ZO_TabButton_SetTooltipText(ZO_KeepWindowMainWoodTab, GetString("SI_KEEPRESOURCETYPE", RESOURCETYPE_WOOD))

    ZO_CreateUniformIconTabData(visualData, nil, nil, nil, "EsoUI/Art/AvA/AvA_keepStatus_tabIcon_food.dds", "EsoUI/Art/AvA/AvA_keepStatus_tabIcon_food_inactive.dds")
    ZO_TabButton_Icon_Initialize(ZO_KeepWindowMainFoodTab, "FancyBottomEdgeImage", visualData, handleTabClick)
    ZO_TabButton_SetTooltipText(ZO_KeepWindowMainFoodTab, GetString("SI_KEEPRESOURCETYPE", RESOURCETYPE_FOOD))

    ZO_CreateUniformIconTabData(visualData, nil, nil, nil, "EsoUI/Art/AvA/AvA_keepStatus_tabIcon_ore.dds", "EsoUI/Art/AvA/AvA_keepStatus_tabIcon_ore_inactive.dds")
    ZO_TabButton_Icon_Initialize(ZO_KeepWindowMainOreTab, "FancyBottomEdgeImage", visualData, handleTabClick)
    ZO_TabButton_SetTooltipText(ZO_KeepWindowMainOreTab, GetString("SI_KEEPRESOURCETYPE", RESOURCETYPE_ORE))

    manager.mainTabGroup = ZO_TabButtonGroup:New()
    manager.mainTabGroup:Add(ZO_KeepWindowMainSummaryTab)
    manager.mainTabGroup:Add(ZO_KeepWindowMainWoodTab)
    manager.mainTabGroup:Add(ZO_KeepWindowMainFoodTab)
    manager.mainTabGroup:Add(ZO_KeepWindowMainOreTab)

    ZO_CreateUniformIconTabData(visualData, nil, nil, nil, "EsoUI/Art/AvA/AvA_resourceStatus_tabIcon_defense.dds", "EsoUI/Art/AvA/AvA_resourceStatus_tabIcon_defense_inactive.dds")
    ZO_TabButton_Icon_Initialize(ZO_KeepWindowResourceDefensiveTab, "FancyBottomEdgeImage", visualData, handleTabClick)
    ZO_TabButton_SetTooltipText(ZO_KeepWindowResourceDefensiveTab, GetString(SI_KEEP_DEFENSIVE_TAB_TOOLTIP))

    ZO_CreateUniformIconTabData(visualData, nil, nil, nil, "EsoUI/Art/AvA/AvA_resourceStatus_tabIcon_production.dds", "EsoUI/Art/AvA/AvA_resourceStatus_tabIcon_production_inactive.dds")
    ZO_TabButton_Icon_Initialize(ZO_KeepWindowResourceProductionTab, "FancyBottomEdgeImage", visualData, handleTabClick)
    ZO_TabButton_SetTooltipText(ZO_KeepWindowResourceProductionTab, GetString(SI_KEEP_PRODUCTION_TAB_TOOLTIP))

    manager.resourceTabGroup = ZO_TabButtonGroup:New()
    manager.resourceTabGroup:Add(ZO_KeepWindowResourceDefensiveTab)
    manager.resourceTabGroup:Add(ZO_KeepWindowResourceProductionTab)

    manager.resourceRows = { ZO_KeepWindowMainSummaryWood, ZO_KeepWindowMainSummaryFood, ZO_KeepWindowMainSummaryOre }

    manager.resourceUpgrades = ZO_KeepUpgradeManager:New(   ZO_KeepWindowMainResourceUpgrade, 
                                                            NUM_UPGRADE_LEVELS,
                                                            RESOURCE_COLOR,
                                                            nil,
                                                            UPGRADE_TYPE_MAIN_KEEP,
                                                            nil,
                                                            manager,
                                                            MAIN_UPGRADE_BAR_WIDTH
                                                          )

    EVENT_MANAGER:RegisterForEvent("KeepWindow", EVENT_KEEP_ALLIANCE_OWNER_CHANGED, function(_, keepId) manager:OnKeepAllianceOwnerChanged(keepId) end)
    EVENT_MANAGER:RegisterForEvent("KeepWindow", EVENT_KEEP_GUILD_CLAIM_UPDATE, function(_, keepId) manager:OnKeepGuildClaimUpdate(keepId) end)
    EVENT_MANAGER:RegisterForEvent("KeepWindow", EVENT_KEEP_BATTLE_TOKENS_UPDATE, function(_, keepId) manager:OnKeepBattleTokensUpdate(keepId) end)
    EVENT_MANAGER:RegisterForEvent("KeepWindow", EVENT_KEEP_INITIALIZED, function(_, keepId) manager:OnKeepInitialized(keepId) end)
    EVENT_MANAGER:RegisterForEvent("KeepWindow", EVENT_KEEPS_INITIALIZED, function() manager:OnKeepsInitialized() end)

    EVENT_MANAGER:RegisterForEvent("KeepWindow", EVENT_KEEP_START_INTERACTION, function() manager:OnKeepStartInteraction() end)
    EVENT_MANAGER:RegisterForEvent("KeepWindow", EVENT_KEEP_END_INTERACTION, function() manager:OnKeepEndInteraction() end)

    manager.updateHandler =    function(_, currentTime)
                                    manager:OnUpdate(currentTime)
                                end

    if GetInteractionKeepId() ~= 0 then
        manager:OnKeepStartInteraction()
    end

    local KEEP_INSPECT_INTERACTION = 
    {
        type = "Keep Inspect",
        End =   function()
                    SCENE_MANAGER:Hide("keepWindow")
                end,
        interactTypes = { INTERACTION_KEEP_INSPECT },
    }

    KEEP_WINDOW_SCENE = ZO_InteractScene:New("keepWindow", SCENE_MANAGER, KEEP_INSPECT_INTERACTION)
    KEEP_WINDOW_SCENE:RegisterCallback("StateChange",   function(oldState, newState)
                                                            if(newState == SCENE_HIDDEN) then
                                                                manager.keepId = nil
                                                            end
                                                        end)

    return manager
end

function ZO_KeepWindowManager:GetKeepId()
    return self.keepId
end

function ZO_KeepWindowManager:GetBattlegroundContext()
    return self.battlegroundContext
end

function ZO_KeepWindowManager:ShowKeep(keepId, battlegroundContext)
    if(keepId ~= self.keepId or bgContext ~= self.battlegroundContext) then
        local keepType = GetKeepType(keepId)
        if(keepType == KEEPTYPE_KEEP or keepType == KEEPTYPE_RESOURCE) then
            
            -- currently doesn't do anything
            if(not self.window:IsHidden()) then
                RequestKeepInfoForKeep(self.keepId, false)
                RequestKeepInfoForKeep(keepId, true)    
            end        

            self.keepId = keepId
            self.battlegroundContext = battlegroundContext 
            self:UpdateKeepInfo(keepId, battlegroundContext)

            if(keepType == KEEPTYPE_KEEP) then
                self:ShowMainKeep(keepId)
            elseif(keepType == KEEPTYPE_RESOURCE) then
                self:ShowResourceKeep(keepId)
            end

            SCENE_MANAGER:Show("keepWindow")
            return true
        end 
    end 
    
    return false  
end

function ZO_KeepWindowManager:ShowClosestKeep()
    local closestKeep = GetClosestKeep(ZO_WorldMap_GetBattlegroundQueryType())
    if(closestKeep ~= 0) then
        return self:ShowKeep(closestKeep, ZO_WorldMap_GetBattlegroundQueryType())
    end
end

function ZO_KeepWindowManager:Toggle()
    if(SCENE_MANAGER:IsShowing("keepWindow")) then
        SCENE_MANAGER:Hide("keepWindow")
    else
        self:ShowClosestKeep()        
    end
end

--Private

function ZO_KeepWindowManager:UpdateKeepInfo(keepId, battlegroundContext)
    local keepName = GetKeepName(keepId)
    self.title:SetText(keepName)

    local allianceOwner = GetKeepAlliance(keepId, battlegroundContext)
    local allianceName = GetAllianceName(allianceOwner)
    self.allianceOwner:SetText(allianceName)
    self.allianceOwnerIcon:SetTexture(GetAllianceTexture(allianceOwner))

    local guildOwnerName = GetClaimedKeepGuildName(keepId, battlegroundContext)
    if(guildOwnerName == "") then
        guildOwnerName = GetString(SI_KEEP_UNCLAIMED_GUILD)
    end
    self.guildOwner:SetText(guildOwnerName)
end

function ZO_KeepWindowManager:ChangeMode(mode)
    if(mode ~= self.mode) then
       self.mode = mode
       self.tab = nil
       self.window:SetHandler("OnUpdate", nil)
       GetControl(self.window, "Main"):SetHidden(not (mode == MAIN_KEEP_MODE))
       GetControl(self.window, "Resource"):SetHidden(not (mode == RESOURCE_KEEP_MODE))
    end
end

function ZO_KeepWindowManager:ComputeRemainingTime(current, forNextLevel, resourceRate, level)
    if(forNextLevel <= 0 or resourceRate <= 0 or current > forNextLevel or level >= (NUM_UPGRADE_LEVELS - 1)) then
        return GetString(SI_KEEP_UPGRADE_INVALID_TIME)
    else        
        local timeRemaining = ((forNextLevel - current) / resourceRate) * 60
        return ZO_FormatCountdownTimer(timeRemaining)    
    end
end

function ZO_KeepWindowManager:UpdateResourceSummaryRow(row, keepId, resourceKeepId, battlegroundContext, resourceType)
    local iconControl = GetControl(row, "Icon")
    local resourceKeepAlliance = GetKeepAlliance(resourceKeepId, battlegroundContext)
    local iconFile = RESOURCE_OWNER_TO_ICON[resourceType][resourceKeepAlliance]
    iconControl:SetTexture(iconFile)

    local resourceLevel = GetKeepResourceLevel(keepId, battlegroundContext, resourceType)
    local current, forNextLevel = GetKeepResourceInfo(keepId, battlegroundContext, resourceType, resourceLevel)

    local levelLabel = GetControl(row, "Level")
    levelLabel:SetText(resourceLevel)

    local rateLabel = GetControl(row, "Rate")
    local resourceRate = GetKeepResourceRate(keepId, battlegroundContext, resourceType)
    rateLabel:SetText(zo_strformat(SI_KEEP_RATE_FORMAT, resourceRate))

    local timeLabel = GetControl(row, "Time")
    local timeRemaining = self:ComputeRemainingTime(current, forNextLevel, resourceRate, resourceLevel)
            
    timeLabel:SetText(timeRemaining)          
end

function ZO_KeepWindowManager:UpdateSummaryView()
    local keepId = self.keepId
    local battlegroundContext = self.battlegroundContext

    for resourceType = 1, #self.resourceRows do
        local resourceKeepId = GetResourceKeepForKeep(keepId, resourceType)
        local row = self.resourceRows[resourceType]

        if(resourceKeepId == 0) then
            row:SetHidden(true)
        else
            row:SetHidden(false)
            self:UpdateResourceSummaryRow(row, keepId, resourceKeepId, battlegroundContext, resourceType)          
        end
    end
end

function ZO_KeepWindowManager:UpdateResourceView()
    local keepId = self.keepId
    local battlegroundContext = self.battlegroundContext
    local resourceType = TAB_TO_RESOURCE_TYPE[self.tab]

    self.resourceUpgrades:Refresh()
        
    local resourceName = GetString("SI_KEEPRESOURCETYPE", resourceType)
    self.resourceUpgrades:SetName(zo_strformat(SI_KEEP_RESOURCE_TITLE, resourceName))

    self:UpdateResourceSummaryRow(GetControl(self.mainResource, "Summary"), keepId, GetResourceKeepForKeep(keepId, resourceType), battlegroundContext, resourceType)
end

function ZO_KeepWindowManager:SetMainKeepTab(tab)
    if(self.mode == MAIN_KEEP_MODE) then
        if(self.tab ~= tab) then
            self.tab = tab
            if(tab) then
                if(tab == MAIN_KEEP_TAB_SUMMARY) then
                    self.mainSummary:SetHidden(false)
                    self.mainResource:SetHidden(true)

                    self:UpdateSummaryView()
                else
                    self.mainSummary:SetHidden(true)
                    self.mainResource:SetHidden(false)

                    local resourceType = TAB_TO_RESOURCE_TYPE[tab]
                    self.resourceUpgrades:SetUpgradePath(resourceType)

                    self:UpdateResourceView()
                    self.resourceUpgrades:ScrollToLevel(self.resourceUpgrades:GetUpgradeLevel())
                end
            end
        end
    end
end

function ZO_KeepWindowManager:SetResourceKeepTab(tab)
    if(self.mode == RESOURCE_KEEP_MODE) then
        if(self.tab ~= tab) then
            self.tab = tab
            if(tab) then
                if(tab == RESOURCE_KEEP_TAB_DEFENSIVE) then
                    self.resourceDefensive:SetHidden(false)
                    self.resourceProduction:SetHidden(true)
                else
                    self.resourceDefensive:SetHidden(true)
                    self.resourceProduction:SetHidden(false)
                end
            end
        end
    end
end

function ZO_KeepWindowManager:ShowMainKeep(keepId)
    self:ChangeMode(MAIN_KEEP_MODE)
    
    self.mainTabGroup:SetClickedButton(ZO_KeepWindowMainSummaryTab)
    self:SetMainKeepTab(MAIN_KEEP_TAB_SUMMARY)

    self.nextUpdateTime = GetFrameTimeSeconds()
    self.window:SetHandler("OnUpdate", self.updateHandler)
end

function ZO_KeepWindowManager:ShowResourceKeep(keepId)
    self:ChangeMode(RESOURCE_KEEP_MODE)   
    
    self.resourceTabGroup:SetClickedButton(ZO_KeepWindowResourceDefensiveTab)
    self:SetResourceKeepTab(RESOURCE_KEEP_TAB_DEFENSIVE)

    self.defensiveUpgrades:Initialize()
    self.productionUpgrades:Initialize()
end

function ZO_KeepWindowManager:GetUpgradeForPath(path)
    if(path == UPGRADEPATH_DEFENSIVE) then
        return self.defensiveUpgrades
    else
        return self.productionUpgrades
    end
end

--gets the keep that this one would switch to (parent keep -> resource keep, or resource keep -> parent keep)
function ZO_KeepWindowManager:GetKeepSwitchTarget()
    if(self.mode == RESOURCE_KEEP_MODE) then
        return GetParentKeepForKeep(self.keepId)
    else
        return GetResourceKeepForKeep(self.keepId, TAB_TO_RESOURCE_TYPE[self.tab])
    end
end

--Event/Callbacks

function ZO_KeepWindowManager:OnShow()    
    RequestKeepInfoForKeep(self.keepId, true)
end

function ZO_KeepWindowManager:OnHide()
    RequestKeepInfoForKeep(self.keepId, false)                
end

function ZO_KeepWindowManager:OnUpdate(currentTime)
    if(currentTime > self.nextUpdateTime) then
        self.nextUpdateTime = currentTime + RESOURCE_UPDATE_TIMER
        if(self.tab == MAIN_KEEP_TAB_SUMMARY) then
            self:UpdateSummaryView()
        else
            self:UpdateResourceView()
        end
    end
end

function ZO_KeepWindowManager:OnTabClicked(tabControl)
    if(self.mode == MAIN_KEEP_MODE) then
        self:SetMainKeepTab(self.tabControlToTab[tabControl])
    else
        self:SetResourceKeepTab(self.tabControlToTab[tabControl])
    end
end

function ZO_KeepWindowManager:OnKeepStartInteraction()
    --TODO: GetInteractionKeepQueryType()
    if(not self:ShowKeep(GetInteractionKeepId(), ZO_WorldMap_GetBattlegroundQueryType())) then
        EndInteraction(INTERACTION_KEEP_INSPECT)
    end
end

function ZO_KeepWindowManager:OnKeepEndInteraction()
    SCENE_MANAGER:Hide("keepWindow")
end

function ZO_KeepWindowManager:OnKeepAllianceOwnerChanged(keepId)
    if(not ZO_KeepWindow:IsHidden() and keepId == self.keepId) then
        self:UpdateKeepInfo(self.keepId, self.battlegroundContext)
    end
end

function ZO_KeepWindowManager:OnKeepGuildClaimUpdate(keepId)
    if(not ZO_KeepWindow:IsHidden() and keepId == self.keepId) then
        self:UpdateKeepInfo(self.keepId, self.battlegroundContext)
    end
end

function ZO_KeepWindowManager:HandleFullUpdate()
    self:UpdateKeepInfo(self.keepId, self.battlegroundContext)

    if(self.mode == RESOURCE_KEEP_MODE) then
        self.defensiveUpgrades:Refresh()
        self.productionUpgrades:Refresh()           
    else        
        if(self.tab == MAIN_KEEP_TAB_SUMMARY) then
            self:UpdateSummaryView()
        else
            self:UpdateResourceView()
        end
    end
end

function ZO_KeepWindowManager:OnKeepInitialized(keepId)
    if(not ZO_KeepWindow:IsHidden() and keepId == self.keepId) then
        self:HandleFullUpdate()
    end
end

function ZO_KeepWindowManager:OnKeepsInitialized()
    if(not ZO_KeepWindow:IsHidden()) then
        self:HandleFullUpdate()
    end
end

function ZO_KeepWindowManager:OnKeepBattleTokensUpdate(keepId)
    if(not ZO_KeepWindow:IsHidden() and keepId == self.keepId) then
        if(self.mode == RESOURCE_KEEP_MODE) then
            self.defensiveUpgrades:Refresh()
            self.productionUpgrades:Refresh()          
        end
    end
end

function ZO_KeepWindowManager:OnTotalChanged(path, total)
    local upgrade = self:GetUpgradeForPath(path)
    upgrade:ProjectProgress(total)    
end

function ZO_KeepWindowManager:OnSwitchEnter(button)
    local keepTarget = self:GetKeepSwitchTarget()
    if(keepTarget ~= 0) then
        local text = zo_strformat(SI_KEEP_SWITCH_TOOLTIP, GetKeepName(keepTarget))
        ZO_Tooltips_ShowTextTooltip(button, nil, text)
    end   
end

function ZO_KeepWindowManager:OnTooltipExit()
    ClearTooltip(InformationTooltip)
end

function ZO_KeepWindowManager:OnSwitchClicked()
    local keepTarget = self:GetKeepSwitchTarget()
    if(keepTarget ~= 0) then
        self:ShowKeep(keepTarget, ZO_WorldMap_GetBattlegroundQueryType())
    end
end

function ZO_KeepWindowManager:OnSummaryRowRateEnter(texture)
    local resourceType
    if(self.tab == MAIN_KEEP_TAB_SUMMARY) then
        resourceType = self.rateIconToResourceType[texture]
    else
        resourceType = TAB_TO_RESOURCE_TYPE[self.tab]
    end

    local resourceKeepId = GetResourceKeepForKeep(self.keepId, resourceType)
    if(resourceKeepId ~= 0) then
        local text = zo_strformat(SI_KEEP_SUMMARY_RATE_TOOLTIP, GetString("SI_KEEPRESOURCETYPE", resourceType), GetKeepName(resourceKeepId))
        ZO_Tooltips_ShowTextTooltip(texture, LEFT, text)
    end
end


--XML Handlers
function ZO_KeepWindowSummaryRowRate_OnMouseEnter(texture)
    KEEP_WINDOW:OnSummaryRowRateEnter(texture)
end

function ZO_KeepWindowSummaryRowRate_OnMouseExit()
    KEEP_WINDOW:OnTooltipExit()
end

function ZO_KeepWindowSwitch_OnMouseEnter(button)
    KEEP_WINDOW:OnSwitchEnter(button)
end

function ZO_KeepWindowSwitch_OnMouseExit()
    KEEP_WINDOW:OnTooltipExit()
end

function ZO_KeepWindowSwitch_OnClicked()
   KEEP_WINDOW:OnSwitchClicked() 
end

function ZO_KeepWindow_OnShow()
    KEEP_WINDOW:OnShow()
end

function ZO_KeepWindow_OnHide()
    KEEP_WINDOW:OnHide()
end

function ZO_KeepWindow_OnInitialized(window)
    KEEP_WINDOW = ZO_KeepWindowManager:New(window)
end
