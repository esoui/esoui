function ZO_Tooltip:LayoutArmoryBuildAttributes(armoryBuildData)
    local headerSection = self:AcquireSection(self:GetStyle("topSection"))
    headerSection:AddLine(GetString(SI_STATS_ATTRIBUTES), self:GetStyle("topSection"))
    self:AddSection(headerSection)

    local SELECTED = true
    local NOT_SELECTED = false
    local DISABLED = false
    local NOT_ACTIVE = false
    local attributeSection = self:AcquireSection(self:GetStyle("armoryBuildAttributeBodySection"))

    local attributeDataList =
    {
        {
            type = ATTRIBUTE_MAGICKA,
            icon = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_magickaIcon.dds",
        },
        {
            type = ATTRIBUTE_HEALTH,
            icon = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_healthIcon.dds",
        },
        {
            type = ATTRIBUTE_STAMINA,
            icon = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_staminaIcon.dds",
        },
    }

    local spentAttributePoints = 0
    local armoryBuildSpentAttributePoints = 0
    for i, attribute in ipairs(attributeDataList) do
        local attributeName = GetString("SI_ATTRIBUTES", attribute.type)
        local attributeData = ZO_GamepadEntryData:New(attributeName, attribute.icon)
        local rowControl = self:AcquireCustomControl(self:GetStyle("armoryBuildAttributeEntryRow"))
        ZO_SharedGamepadEntry_OnSetup(rowControl, attributeData, SELECTED, NOT_SELECTED, DISABLED, NOT_ACTIVE)
        local spinnerDisplayControl = rowControl:GetNamedChild("SpinnerDisplay")
        local attributeSpentPoints = armoryBuildData:GetAttributeSpentPoints(attribute.type)
        spinnerDisplayControl:SetText(attributeSpentPoints)
        attributeSection:AddCustomControl(rowControl, { attributeName, tostring(attributeSpentPoints) })

        spentAttributePoints = spentAttributePoints + GetAttributeSpentPoints(attribute.type)
        armoryBuildSpentAttributePoints = armoryBuildSpentAttributePoints + armoryBuildData:GetAttributeSpentPoints(attribute.type)
    end

    self:AddSection(attributeSection)

    local statsSection = self:AcquireSection(self:GetStyle("armoryBuildAttributeStatsSection"))
    local attributePair = statsSection:AcquireStatValuePair(self:GetStyle("armoryBuildStatValuePair"))
    local totalAttributePoints = GetAttributeUnspentPoints() + spentAttributePoints
    attributePair:SetStat(GetString(SI_GAMEPAD_ARMORY_UNSPENT_POINTS), self:GetStyle("statValuePairStat"))
    attributePair:SetValue(totalAttributePoints - armoryBuildSpentAttributePoints, self:GetStyle("armoryBuildStatValuePairValue"))
    statsSection:AddStatValuePair(attributePair)

    self:AddSection(statsSection)
end

function ZO_Tooltip:LayoutArmoryBuildChampionSkill(championSkillData)
    -- ability info (name, description)
    self:AddLine(championSkillData:GetFormattedName(), self:GetStyle("title"))

    local abilityId = championSkillData:GetAbilityId()
    if not IsAbilityPassive(abilityId) then
        self:AddAbilityStats(abilityId)
    end
    self:AddAbilityDescription(abilityId, championSkillData:GetDescription())
end