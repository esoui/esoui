local CHECKED_ICON = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"
local UNCHECKED_ICON = "EsoUI/Art/Miscellaneous/Gamepad/gp_bullet_ochre.dds"

function ZO_Tooltip:LayoutCadwells(progressionLevel, zoneIndex)
    local mainSection = self:AcquireSection(self:GetStyle("cadwellSection"), self:GetStyle("tooltip"))


    local titleSection = self:AcquireSection(self:GetStyle("cadwellObjectiveTitleSection"))
    titleSection:AddLine(GetString(SI_CADWELL_OBJECTIVES), self:GetStyle("cadwellObjectiveTitle"))
    mainSection:AddSection(titleSection)

    objectives = {}
    for objectiveIndex = 1, GetNumPOIsForCadwellProgressionLevelAndZone(progressionLevel, zoneIndex) do
        local name, openingText, closingText, objectiveOrder, discovered, completed = GetCadwellZonePOIInfo(progressionLevel, zoneIndex, objectiveIndex)
        table.insert(objectives, {name=name, openingText=openingText, closingText=closingText, order=objectiveOrder, discovered=discovered, completed=completed})
    end

    table.sort(objectives, ZO_CadwellSort)

    local objectivesSection = mainSection:AcquireSection(self:GetStyle("cadwellObjectivesSection"))

    for i=1, #objectives do
        local objectiveInfo = objectives[i]
        local name = objectiveInfo.name
        local openingText = objectiveInfo.openingText
        local closingText = objectiveInfo.closingText
        local discovered = objectiveInfo.discovered
        local completed = objectiveInfo.completed

        -- Extract the actual information we want to display based on the state of the objective.
        local icon
        local text
        local style
        if discovered and completed then
            icon = CHECKED_ICON
            text = closingText
            style = "cadwellObjectiveComplete"
        elseif discovered and (not completed) then
            icon = UNCHECKED_ICON
            text = openingText
            style = "cadwellObjectiveActive"
        else
            icon = UNCHECKED_ICON
            text = openingText
            style = "cadwellObjectiveInactive"
        end

        local objectiveContainerSection = objectivesSection:AcquireSection(self:GetStyle("cadwellObjectiveContainerSection"))

        -- Add the bullet icon to the tooltip.
        local textureContainerSection = objectiveContainerSection:AcquireSection(self:GetStyle("cadwellTextureContainer"))
        textureContainerSection:AddTexture(icon, self:GetStyle("achievementCriteriaCheck"))
        objectiveContainerSection:AddSection(textureContainerSection)

        -- Add the information to the tooltip.
        local objectiveSection = objectiveContainerSection:AcquireSection(self:GetStyle("cadwellObjectiveSection"))
        objectiveSection:AddLine(zo_strformat(SI_CADWELL_OBJECTIVE_FORMAT, name, text), self:GetStyle(style))
        objectiveContainerSection:AddSection(objectiveSection)

        objectivesSection:AddSection(objectiveContainerSection)
    end

    mainSection:AddSection(objectivesSection)
    self:AddSection(mainSection)
end
