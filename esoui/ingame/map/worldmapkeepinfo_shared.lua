local KeepUpgradeType_Shared = ZO_Object:Subclass()

function KeepUpgradeType_Shared:SetKeep(keepId)
    self.keepId = keepId
end

function KeepUpgradeType_Shared:SetBGQueryType(bgQueryType)
    self.bgQueryType = bgQueryType
end

function KeepUpgradeType_Shared:SetUpgradeTooltip(level, index)
    KeepUpgradeTooltip:SetKeepUpgrade(self.keepId, self.bgQueryType, self.upgradeLine, level, index)
end

function KeepUpgradeType_Shared:GetAlliance()
     return GetKeepAlliance(self.keepId, self.bgQueryType)
end

function KeepUpgradeType_Shared:GetGuildOwner()
    return GetClaimedKeepGuildName(self.keepId, self.bgQueryType)
end

function KeepUpgradeType_Shared:GetKeep()
    return self.keepId
end

function KeepUpgradeType_Shared:GetBGQueryType()
    return self.bgQueryType
end

function KeepUpgradeType_Shared:GetRate()
    return GetKeepUpgradeRate(self.keepId, self.bgQueryType, self.upgradeLine)
end

--Keep Upgrade Type

ZO_KeepUpgrade_Shared = KeepUpgradeType_Shared:Subclass()

function ZO_KeepUpgrade_Shared:New()
    return KeepUpgradeType_Shared.New(self)
end

function ZO_KeepUpgrade_Shared:SetResourceType(resourceType)
    self.resourceType = resourceType
    self.upgradeLine = GetKeepUpgradeLineFromResourceType(self.resourceType)
end

function ZO_KeepUpgrade_Shared:GetUpgradeLevel()
    return GetKeepResourceLevel(self.keepId, self.bgQueryType, self.resourceType)
end

function ZO_KeepUpgrade_Shared:GetUpgradeLevelProgress(level)
    return GetKeepResourceInfo(self.keepId, self.bgQueryType, self.resourceType, level)
end

function ZO_KeepUpgrade_Shared:GetNumLevelUpgrades(level)
    return GetNumUpgradesForKeepAtResourceLevel(self.keepId, self.bgQueryType, self.resourceType, level)
end

function ZO_KeepUpgrade_Shared:GetLevelUpgradeInfo(level, index)
    return GetKeepUpgradeDetails(self.keepId, self.bgQueryType, self.resourceType, level, index)
end

function ZO_KeepUpgrade_Shared:GetUpgradeTypeName()
    return GetString("SI_KEEPRESOURCETYPE", self.resourceType)
end

function ZO_KeepUpgrade_Shared:GetNumUpgradeTypes()
    return GetNumKeepResourceTypes()
end

function ZO_KeepUpgrade_Shared:IsInputEnemyControlled()
    local resourceKeepId = GetResourceKeepForKeep(self.keepId, self.resourceType)
    local resourceAlliance = GetKeepAlliance(resourceKeepId, self.bgQueryType)
    local keepAlliance = GetKeepAlliance(self.keepId, self.bgQueryType)
    return resourceAlliance ~= keepAlliance
end

function ZO_KeepUpgrade_Shared:SetRateTooltip()
    local tooltipStringId
    if(self:GetAlliance() == GetUnitAlliance("player")) then
        if(not self:IsInputEnemyControlled()) then
            tooltipStringId = SI_MAP_KEEP_INFO_KEEP_RATE_OWNED_INCREASING_TOOLTIP
        else
            tooltipStringId = SI_MAP_KEEP_INFO_KEEP_RATE_OWNED_NOT_INCREASING_TOOLTIP
        end
    else
        if(not self:IsInputEnemyControlled()) then
            tooltipStringId = SI_MAP_KEEP_INFO_KEEP_RATE_NOT_OWNED_INCREASING_TOOLTIP
        else
            tooltipStringId = SI_MAP_KEEP_INFO_KEEP_RATE_NOT_OWNED_NOT_INCREASING_TOOLTIP
        end
    end

    local resourceName = self:GetUpgradeTypeName()
    local resourceKeepId = GetResourceKeepForKeep(self.keepId, self.resourceType)
    local resourceKeepName = GetKeepName(resourceKeepId)
    InformationTooltip:AddLine(zo_strformat(tooltipStringId, resourceName, resourceKeepName), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
end

--Resource Upgrade Type

ZO_ResourceUpgrade_Shared = KeepUpgradeType_Shared:Subclass()

function ZO_ResourceUpgrade_Shared:New()
    return KeepUpgradeType_Shared.New(self)
end

function ZO_ResourceUpgrade_Shared:SetUpgradePath(path)
    self.upgradePath = path
    self.upgradeLine = GetKeepUpgradeLineFromUpgradePath(self.upgradePath)
end

function ZO_ResourceUpgrade_Shared:GetUpgradeLevel()
    if(self.upgradePath == UPGRADEPATH_DEFENSIVE) then
        return GetKeepDefensiveLevel(self.keepId, self.bgQueryType)
    else
        return GetKeepProductionLevel(self.keepId, self.bgQueryType)
    end
end

function ZO_ResourceUpgrade_Shared:GetUpgradeLevelProgress(level)
    return GetKeepUpgradeInfo(self.keepId, self.bgQueryType, self.upgradePath, level)
end

function ZO_ResourceUpgrade_Shared:GetNumLevelUpgrades(level)
    return GetNumUpgradesForKeepAtPathLevel(self.keepId, self.bgQueryType, self.upgradePath, level)
end

function ZO_ResourceUpgrade_Shared:GetLevelUpgradeInfo(level, index)
    return GetKeepUpgradePathDetails(self.keepId, self.bgQueryType, self.upgradePath, level, index)
end

function ZO_ResourceUpgrade_Shared:GetUpgradeTypeName()
    return GetString("SI_KEEPUPGRADEPATH", self.upgradePath)
end

function ZO_ResourceUpgrade_Shared:GetNumUpgradeTypes()
    return GetNumKeepUpgradePaths()
end

function ZO_ResourceUpgrade_Shared:IsInputEnemyControlled()
    return false
end

function ZO_ResourceUpgrade_Shared:SetRateTooltip()
    InformationTooltip:AddLine(zo_strformat(SI_MAP_KEEP_INFO_RESOURCE_RATE_TOOLTIP, self:GetUpgradeTypeName()), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
end

--Keep Resource Fragment

ZO_KeepResourceTypeFragment_Shared = ZO_SceneFragment:Subclass()

function ZO_KeepResourceTypeFragment_Shared:New(resourceType, keepInfoObject)
    local fragment = ZO_SceneFragment.New(self)
    fragment.resourceType = resourceType
    fragment.keepInfoObject = keepInfoObject
    return fragment
end

function ZO_KeepResourceTypeFragment_Shared:Show()
    self.keepInfoObject:SetKeepResourceType(self.resourceType)
    self:OnShown()
end

function ZO_KeepResourceTypeFragment_Shared:Hide()
    self:OnHidden()
end

--Keep Upgrade Fragment

ZO_KeepUpgradePathFragment_Shared = ZO_SceneFragment:Subclass()

function ZO_KeepUpgradePathFragment_Shared:New(upgradePath, keepInfoObject)
    local fragment = ZO_SceneFragment.New(self)
    fragment.upgradePath = upgradePath
    fragment.keepInfoObject = keepInfoObject
    return fragment
end

function ZO_KeepUpgradePathFragment_Shared:Show()
    self.keepInfoObject:SetKeepUpgradePath(self.upgradePath)
    self:OnShown()
end

function ZO_KeepUpgradePathFragment_Shared:Hide()
    self:OnHidden()
end

--World Map Keep Info

ZO_WorldMapKeepInfo_Shared = ZO_CallbackObject:Subclass()

function ZO_WorldMapKeepInfo_Shared:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_WorldMapKeepInfo_Shared:Initialize(control, fragmentClass)
    self.control = control
    self.externalFragments = {}
    self.keepNameLabel = control:GetNamedChild("KeepName")

    self:InitializeTabs()

    self.worldMapKeepInfoFragment = fragmentClass:New(control)
    self.worldMapKeepInfoFragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapCampaignChanged", function()
        if(self.keepUpgradeObject) then
            self.keepUpgradeObject:SetBGQueryType(ZO_WorldMap_GetBattlegroundQueryType())
            CALLBACK_MANAGER:FireCallbacks("OnWorldMapKeepChanged")
        end
    end)

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function()
        self:HideKeep()
    end)
end

function ZO_WorldMapKeepInfo_Shared:GetKeepUpgradeObject()
    return self.keepUpgradeObject
end

function ZO_WorldMapKeepInfo_Shared:SetKeepResourceType(resourceType)
    if(self.keepUpgradeObject) then
        self.keepUpgradeObject:SetResourceType(resourceType)
        CALLBACK_MANAGER:FireCallbacks("OnWorldMapKeepChanged")
    end
end

function ZO_WorldMapKeepInfo_Shared:SetKeepUpgradePath(upgradePath)
    if(self.keepUpgradeObject) then
        self.keepUpgradeObject:SetUpgradePath(upgradePath)
        CALLBACK_MANAGER:FireCallbacks("OnWorldMapKeepChanged")
    end
end

function ZO_WorldMapKeepInfo_Shared:ToggleKeep(keepId)
    if(self.keepUpgradeObject and self.keepUpgradeObject:GetKeep() == keepId) then
        self:HideKeep()
    else
        self:ShowKeep(keepId)
    end
end

function ZO_WorldMapKeepInfo_Shared:PreShowKeep()
    self:FireCallbacks("PreShowKeep")
end

function ZO_WorldMapKeepInfo_Shared:PostShowKeep()
    self:FireCallbacks("PostShowKeep")
end

function ZO_WorldMapKeepInfo_Shared:ShowKeep(keepId)
    local keepType = GetKeepType(keepId)
    if(keepType == KEEPTYPE_KEEP or keepType == KEEPTYPE_RESOURCE) then
        self.keepNameLabel:SetText(zo_strformat(SI_TOOLTIP_KEEP_NAME, GetKeepName(keepId)))

        self:PreShowKeep()

        if(keepType == KEEPTYPE_KEEP) then
            self.keepUpgradeObject = self.keepUpgrade
        else
            self.keepUpgradeObject = self.resourceUpgrade
        end

        self.keepUpgradeObject:SetKeep(keepId)
        self.keepUpgradeObject:SetBGQueryType(ZO_WorldMap_GetBattlegroundQueryType())

        if(keepType == KEEPTYPE_KEEP) then
            self:AddKeepTabs()
        else
            self:AddResourceTabs()
        end

        self:PostShowKeep()

        SCENE_MANAGER:AddFragment(self.worldMapKeepInfoFragment)
        SCENE_MANAGER:AddFragment(self:GetBackgroundFragment())
        CALLBACK_MANAGER:FireCallbacks("OnWorldMapKeepChanged")
    end
end

function ZO_WorldMapKeepInfo_Shared:HideKeep()
    if self.keepUpgradeObject then
        SCENE_MANAGER:RemoveFragment(self:GetBackgroundFragment())
        SCENE_MANAGER:RemoveFragment(self.worldMapKeepInfoFragment)
        self:FireCallbacks("WorldMapKeepInfoHidden")
    end
    ZO_WorldMap_InvalidateTooltip()
end

function ZO_WorldMapKeepInfo_Shared:GetFragment()
    return self.worldMapKeepInfoFragment
end

function ZO_WorldMapKeepInfo_Shared:GetBackgroundFragment()
    assert(false) -- Must be overriden
end

function ZO_WorldMapKeepInfo_Shared:CreateButtonData(normal, pressed, highlight)
     return {
        normal = normal,
        pressed = pressed,
        highlight = highlight,
    }
end

-- These stubs are used to abstract between TabBar (Gamepad) and ModeBar (Keyboard)
function ZO_WorldMapKeepInfo_Shared:BeginBar()
    -- stub
end

function ZO_WorldMapKeepInfo_Shared:AddBar(text, fragments, buttonData)
    -- stub
end

function ZO_WorldMapKeepInfo_Shared:FinishBar()
    -- stub
end

function ZO_WorldMapKeepInfo_Shared:InitializeTabs()
    self.summaryButtonData = self:CreateButtonData("EsoUI/Art/WorldMap/map_AVA_tabIcon_keepSummary_up.dds",
                                                "EsoUI/Art/WorldMap/map_AVA_tabIcon_keepSummary_down.dds",
                                                "EsoUI/Art/WorldMap/map_AVA_tabIcon_keepSummary_over.dds")

    self.woodKeepResourceTypeFragment = ZO_KeepResourceTypeFragment_Shared:New(RESOURCETYPE_WOOD, self)
    self.woodButtonData = self:CreateButtonData("EsoUI/Art/WorldMap/map_AVA_tabIcon_woodMill_up.dds",
                                                 "EsoUI/Art/WorldMap/map_AVA_tabIcon_woodMill_down.dds",
                                                 "EsoUI/Art/WorldMap/map_AVA_tabIcon_woodMill_over.dds")

    self.foodKeepResourceTypeFragment = ZO_KeepResourceTypeFragment_Shared:New(RESOURCETYPE_FOOD, self)
    self.foodButtonData = self:CreateButtonData("EsoUI/Art/WorldMap/map_AVA_tabIcon_foodFarm_up.dds",
                                                 "EsoUI/Art/WorldMap/map_AVA_tabIcon_foodFarm_down.dds",
                                                 "EsoUI/Art/WorldMap/map_AVA_tabIcon_foodFarm_over.dds")

    self.oreKeepResourceTypeFragment = ZO_KeepResourceTypeFragment_Shared:New(RESOURCETYPE_ORE, self)
    self.oreButtonData = self:CreateButtonData("EsoUI/Art/WorldMap/map_AVA_tabIcon_oreMine_up.dds",
                                                "EsoUI/Art/WorldMap/map_AVA_tabIcon_oreMine_down.dds",
                                                "EsoUI/Art/WorldMap/map_AVA_tabIcon_oreMine_over.dds")

    self.productionFragment = ZO_KeepUpgradePathFragment_Shared:New(UPGRADEPATH_PRODUCTION, self)
    self.productionButtonData = self:CreateButtonData("EsoUI/Art/WorldMap/map_AVA_tabIcon_resourceProduction_up.dds",
                                                      "EsoUI/Art/WorldMap/map_AVA_tabIcon_resourceProduction_down.dds",
                                                      "EsoUI/Art/WorldMap/map_AVA_tabIcon_resourceProduction_over.dds")

    self.defenseFragment = ZO_KeepUpgradePathFragment_Shared:New(UPGRADEPATH_DEFENSIVE, self)
    self.defenseButtonData = self:CreateButtonData("EsoUI/Art/WorldMap/map_AVA_tabIcon_resourceDefense_up.dds",
                                                   "EsoUI/Art/WorldMap/map_AVA_tabIcon_resourceDefense_down.dds",
                                                   "EsoUI/Art/WorldMap/map_AVA_tabIcon_resourceDefense_over.dds")
end

function ZO_WorldMapKeepInfo_Shared:AddKeepTabs()
    self:BeginBar()

    local fragments = self.externalFragments

    --Summary Button
    self:AddBar(SI_MAP_KEEP_INFO_MODE_SUMMARY, { fragments.SUMMARY_FRAGMENT }, self.summaryButtonData)

    --Wood Button
    self:AddBar(SI_MAP_KEEP_INFO_MODE_WOOD, { self.woodKeepResourceTypeFragment,  fragments.UPGRADE_FRAGMENT }, self.woodButtonData)

    --Food Button
    self:AddBar(SI_MAP_KEEP_INFO_MODE_FOOD, { self.foodKeepResourceTypeFragment,  fragments.UPGRADE_FRAGMENT }, self.foodButtonData)

    --Ore Button
    self:AddBar(SI_MAP_KEEP_INFO_MODE_ORE, { self.oreKeepResourceTypeFragment,  fragments.UPGRADE_FRAGMENT }, self.oreButtonData)

    self:FinishBar()
end

function ZO_WorldMapKeepInfo_Shared:AddResourceTabs()
    self:BeginBar()

    local keepId = self.keepUpgradeObject:GetKeep()
    local resourceType = GetKeepResourceType(keepId)

    --Summary Button
    local buttonData
    if(resourceType == RESOURCETYPE_WOOD) then
        buttonData = self.woodButtonData
    elseif(resourceType == RESOURCETYPE_FOOD) then
        buttonData = self.foodButtonData
    else
        buttonData = self.oreButtonData
    end
    buttonData.callback = nil

    local fragments = self.externalFragments

    self:AddBar(SI_MAP_KEEP_INFO_MODE_SUMMARY, { fragments.SUMMARY_FRAGMENT }, buttonData)

    --Production Button
    self:AddBar(SI_MAP_KEEP_INFO_MODE_PRODUCTION, { self.productionFragment,  fragments.UPGRADE_FRAGMENT }, self.productionButtonData)

    --Defense Button
    self:AddBar(SI_MAP_KEEP_INFO_MODE_DEFENSE, { self.defenseFragment,  fragments.UPGRADE_FRAGMENT }, self.defenseButtonData)

    self:FinishBar()
end

function ZO_WorldMapKeepInfo_Shared:SetFragment(name, fragment)
    self.externalFragments[name] = fragment
end

function ZO_WorldMapKeepInfo_Shared:OnShowing()
    -- To be overriden
end

function ZO_WorldMapKeepInfo_Shared:OnHidden()
    self:FireCallbacks("WorldMapKeepInfoHidden")
end