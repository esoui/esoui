---------------------
--Cadwell Manager
---------------------
local ZO_CadwellManager = ZO_Object:Subclass()

function ZO_CadwellManager:New(control)
    local manager = ZO_Object.New(self)
    manager.control = control

    manager.zoneInfoContainer = control:GetNamedChild("ZoneInfoContainer")
    manager.zoneStepContainer = control:GetNamedChild("ZoneStepContainer")
    manager.titleText = control:GetNamedChild("TitleText")
    manager.descriptionText = control:GetNamedChild("DescriptionText")
    manager.objectivesText = control:GetNamedChild("ObjectivesText")
    manager.objectiveLinePool = ZO_ControlPool:New("ZO_Cadwell_ObjectiveLine", control, "Objective")

    manager.currentCadwellProgressionLevel = GetCadwellProgressionLevel()

    manager:InitializeCategoryList(control)
    manager:RefreshList()

    local function OnCadwellProgressionLevelChanged(event, cadwellProgression)
        MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("journalSceneGroup")
        manager.currentCadwellProgressionLevel = cadwellProgression
        manager:RefreshList()
    end

    local function OnPOIUpdated()
        if manager.currentCadwellProgressionLevel > CADWELL_PROGRESSION_LEVEL_BRONZE then
            manager:RefreshList()
        end
    end

    control:RegisterForEvent(EVENT_POI_UPDATED, OnPOIUpdated)
    control:RegisterForEvent(EVENT_CADWELL_PROGRESSION_LEVEL_CHANGED, OnCadwellProgressionLevelChanged)

    return manager
end

function ZO_CadwellManager:InitializeCategoryList(control)
    self.navigationTree = ZO_Tree:New(control:GetNamedChild("NavigationContainerScrollChild"), 60, -10, 300)

    local progressionLevelToIcon = 
    {
        [CADWELL_PROGRESSION_LEVEL_SILVER] = 
        {
            "EsoUI/Art/Cadwell/cadwell_indexIcon_silver_down.dds",
            "EsoUI/Art/Cadwell/cadwell_indexIcon_silver_up.dds",
            "EsoUI/Art/Cadwell/cadwell_indexIcon_silver_over.dds",
        },
        [CADWELL_PROGRESSION_LEVEL_GOLD] = 
        {
            "EsoUI/Art/Cadwell/cadwell_indexIcon_gold_down.dds",
            "EsoUI/Art/Cadwell/cadwell_indexIcon_gold_up.dds",
            "EsoUI/Art/Cadwell/cadwell_indexIcon_gold_over.dds",
        },
    }
    local function GetIconsForCadwellProgressionLevel(progressionLevel)
        if progressionLevelToIcon[progressionLevel] then
            return unpack(progressionLevelToIcon[progressionLevel])
        end
    end

    local function TreeHeaderSetup(node, control, progressionLevel, open)
        control.progressionLevel = progressionLevel
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(GetString("SI_CADWELLPROGRESSIONLEVEL", progressionLevel))
        local down, up, over = GetIconsForCadwellProgressionLevel(progressionLevel)

        control.icon:SetTexture(open and down or up)
        control.iconHighlight:SetTexture(over)

        ZO_IconHeader_Setup(control, open)
    end
    self.navigationTree:AddTemplate("ZO_IconHeader", TreeHeaderSetup, nil, nil, nil, 0)

    local function TreeEntrySetup(node, control, data, open)
        control:SetText(zo_strformat(SI_CADWELL_QUEST_NAME_FORMAT, data.name))
        GetControl(control, "CompletedIcon"):SetHidden(not data.completed)

        control:SetSelected(false)
    end
    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected and not reselectingDuringRebuild then
            self:RefreshDetails()
        end
    end
    local function TreeEntryEquality(left, right)
        return left.name == right.name
    end
    self.navigationTree:AddTemplate("ZO_CadwellNavigationEntry", TreeEntrySetup, TreeEntryOnSelected, TreeEntryEquality)

    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function ZO_CadwellManager:RefreshList()
    if self.control:IsHidden() then
        self.dirty = true
        return
    end

    self.navigationTree:Reset()

    local zones = {}

    for progressionLevel = CADWELL_PROGRESSION_LEVEL_SILVER, CADWELL_PROGRESSION_LEVEL_GOLD do
        local numZones = GetNumZonesForCadwellProgressionLevel(progressionLevel)
        if self.currentCadwellProgressionLevel < progressionLevel then
            break
        end

        if numZones > 0 then
            local parent = self.navigationTree:AddNode("ZO_IconHeader", progressionLevel, nil, SOUNDS.CADWELL_BLADE_SELECTED)

            for zoneIndex = 1, numZones do
                local zoneName, zoneDescription, zoneOrder = GetCadwellZoneInfo(progressionLevel, zoneIndex)

                local zoneCompleted = true

                local objectives = {}

                local numObjectives = GetNumPOIsForCadwellProgressionLevelAndZone(progressionLevel, zoneIndex)
                for objectiveIndex = 1, numObjectives do
                    local name, openingText, closingText, objectiveOrder, discovered, completed = GetCadwellZonePOIInfo(progressionLevel, zoneIndex, objectiveIndex)
                    zoneCompleted = zoneCompleted and completed
                    table.insert(objectives, {name = name, openingText = openingText, closingText = closingText, order = objectiveOrder, discovered = discovered, completed = completed})
                end

                table.sort(objectives, ZO_CadwellSort)

                table.insert(zones, {name = zoneName, description = zoneDescription, order = zoneOrder, completed = zoneCompleted, objectives = objectives, parent = parent})
            end
        end
    end

    table.sort(zones, ZO_CadwellSort)

    for i = 1, #zones do
        local zoneInfo = zones[i]
        local parent = zoneInfo.parent
        self.navigationTree:AddNode("ZO_CadwellNavigationEntry", zoneInfo, parent, SOUNDS.CADWELL_ITEM_SELECTED)
    end

    self.navigationTree:Commit()

    self:RefreshDetails()
end

function ZO_CadwellManager:RefreshDetails()
    self.objectiveLinePool:ReleaseAllObjects()

    local selectedData = self.navigationTree:GetSelectedData()
    if not selectedData or not selectedData.objectives then
        self.zoneInfoContainer:SetHidden(true)
        self.zoneStepContainer:SetHidden(true)
        return
    else
        self.zoneInfoContainer:SetHidden(false)
        self.zoneStepContainer:SetHidden(false)
    end

    self.titleText:SetText(zo_strformat(SI_CADWELL_ZONE_NAME_FORMAT, selectedData.name))
    self.descriptionText:SetText(zo_strformat(SI_CADWELL_ZONE_DESC_FORMAT, selectedData.description))

    local previous

    for i = 1, #selectedData.objectives do
        local objectiveInfo = selectedData.objectives[i]
        local objectiveLine = self.objectiveLinePool:AcquireObject()

        if objectiveInfo.discovered and not objectiveInfo.completed then
            objectiveLine:SetColor(ZO_SELECTED_TEXT:UnpackRGBA())
            GetControl(objectiveLine, "Check"):SetHidden(true)
            objectiveLine:SetText(zo_strformat(SI_CADWELL_OBJECTIVE_FORMAT, objectiveInfo.name, objectiveInfo.openingText))
        elseif not objectiveInfo.discovered then
            objectiveLine:SetColor(ZO_DISABLED_TEXT:UnpackRGBA())
            GetControl(objectiveLine, "Check"):SetHidden(true)
            objectiveLine:SetText(zo_strformat(SI_CADWELL_OBJECTIVE_FORMAT, objectiveInfo.name, objectiveInfo.openingText))
        else
            objectiveLine:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
            GetControl(objectiveLine, "Check"):SetHidden(false)
            objectiveLine:SetText(zo_strformat(SI_CADWELL_OBJECTIVE_FORMAT, objectiveInfo.name, objectiveInfo.closingText))
        end

        if not previous then
            objectiveLine:SetAnchor(TOPLEFT, self.objectivesText, BOTTOMLEFT, 25, 15)
        else
            objectiveLine:SetAnchor(TOPLEFT, previous, BOTTOMLEFT, 0, 15)
        end

        previous = objectiveLine
    end
end

function ZO_CadwellManager:OnShown()
    if self.dirty then
        self:RefreshList()
        self.dirty = false
    end
end

--XML Handlers

function ZO_Cadwell_OnShown()
    CADWELLS_ALMANAC:OnShown()
end

function ZO_Cadwell_Initialize(control)
    CADWELLS_ALMANAC = ZO_CadwellManager:New(control)
end
