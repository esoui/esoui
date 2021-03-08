function ZO_Tooltip:LayoutChampionSkill(championSkillData)

    -- programmatic callouts
    local calloutSection = self:AcquireSection(self:GetStyle("championTopSection"))
    if championSkillData:IsTypeSlottable() then
        if CHAMPION_PERKS:IsChampionSkillDataSlotted(championSkillData) then
            local currentSlot = CHAMPION_PERKS:GetChampionBar():GetGamepadEditor():GetCurrentSlot()
            local matchingSlot = CHAMPION_PERKS:GetChampionBar():FindSlotMatchingChampionSkill(championSkillData)
            local isCurrentlySelected = false

            if currentSlot and matchingSlot then
                local currentSlotIndex = currentSlot:GetSlotIndices()
                local matchingSlotIndex = matchingSlot:GetSlotIndices()
                isCurrentlySelected = (currentSlotIndex == matchingSlotIndex)
            end

            if isCurrentlySelected then
                calloutSection:AddLine(GetString(SI_CHAMPION_TOOLTIP_SKILL_EQUIPPED_IN_CURRENT_SLOT))
            else
                calloutSection:AddLine(GetString(SI_CHAMPION_TOOLTIP_SKILL_EQUIPPED))
            end
        else
            if championSkillData:WouldBePurchased() then
                calloutSection:AddLine(ZO_SUCCEEDED_TEXT:Colorize(GetString(SI_CHAMPION_TOOLTIP_SLOT_TO_ACTIVATE)))
            else
                calloutSection:AddLine(ZO_DISABLED_TEXT:Colorize(GetString(SI_CHAMPION_TOOLTIP_SLOT_TO_ACTIVATE)))
            end
        end
    end
    self:AddSection(calloutSection)

    -- ability info (name, description)
    self:AddLine(championSkillData:GetFormattedName(), self:GetStyle("title"))

    local abilityId = championSkillData:GetAbilityId()
    if not IsAbilityPassive(abilityId) then
        self:AddAbilityStats(abilityId)
    end
    self:AddAbilityDescription(abilityId, championSkillData:GetDescription())

    local pendingPoints = championSkillData:GetNumPendingPoints()
    local nextJumpPoint = championSkillData:GetNextJumpPoint(pendingPoints)
    
    -- current bonus
    local currentBonusText = championSkillData:GetCurrentBonusText()
    if currentBonusText then
        local pointsSection = self:AcquireSection(self:GetStyle("bodySection"))
        pointsSection:AddLine(GetString(SI_CHAMPION_TOOLTIP_CURRENT_BONUS), self:GetStyle("succeeded"), self:GetStyle("bodyHeader"))
        pointsSection:AddLine(currentBonusText, self:GetStyle("succeeded"), self:GetStyle("bodyDescription"))
        self:AddSection(pointsSection)
    end

    -- Champion skill progress bar
    if championSkillData:GetType() ~= CHAMPION_SKILL_TYPE_STAT_POOL_SLOTTABLE then
        local bar = self:AcquireStatusBar(self:GetStyle("championSkillBar"))
        bar:Reset()
        local min = 0
        local max = championSkillData:GetMaxPossiblePoints()
        bar:SetMinMax(min, max)
        bar:SetMinMaxText(min, max)
        bar:SetValue(pendingPoints)

        local maskValue
        if championSkillData:HasJumpPoints() then
            local jumpPoints = championSkillData:GetJumpPoints()
            for _, jumpPoint in ipairs(jumpPoints) do
                if maskValue == nil and jumpPoint >= pendingPoints then
                    -- first jump point above or at pending points, store it as the mask point
                    maskValue = jumpPoint
                end

                if jumpPoint > min and jumpPoint < max then
                    bar:AddNotch(jumpPoint)
                end
            end
        else
            maskValue = max
        end

        bar:SetMaskValue(maskValue)

        self:AddStatusBar(bar)
    end

    -- Points to next upgrade/unlock
    local pointsToNextJump = nextJumpPoint - pendingPoints
    if pointsToNextJump > 0 then
        local pointsSection = self:AcquireSection(self:GetStyle("bodySection"))
        local pointPoolIcon = championSkillData:GetChampionDisciplineData():GetPointPoolIcon()
        local pointsText
        if championSkillData:WouldBePurchased() then
            pointsText = zo_strformat(SI_CHAMPION_TOOLTIP_POINTS_TO_UPGRADE, pointsToNextJump, pointPoolIcon)
        else
            pointsText = zo_strformat(SI_CHAMPION_TOOLTIP_POINTS_TO_UNLOCK, pointsToNextJump, pointPoolIcon)
        end
        pointsSection:AddLine(pointsText, self:GetStyle("bodyDescription"), self:GetStyle("succeeded"))
        self:AddSection(pointsSection)
    end
end

function ZO_Tooltip:LayoutChampionCluster(clusterData)
    local clusterNameSection = self:AcquireSection(self:GetStyle("championTitleSection"), self:GetStyle("title"))
    clusterNameSection:AddLine(clusterData:GetFormattedName(), self:GetStyle("championTitle"))
    clusterNameSection:AddTexture(ZO_GAMEPAD_HEADER_DIVIDER_TEXTURE, self:GetStyle("dividerLine"))
    self:AddSection(clusterNameSection)

    local bodySection = self:AcquireSection(self:GetStyle("championClusterBodySection"), self:GetStyle("bodySection"))
    for _, clusterChild in ipairs(clusterData:GetClusterChildren()) do
        local colorizedFormattedName = ZO_OFF_WHITE:Colorize(clusterChild:GetFormattedName())
        local formattedClusterChild = zo_strformat(SI_CHAMPION_TOOLTIP_CLUSTER_CHILD_FORMAT, colorizedFormattedName, clusterChild:GetNumPendingPoints(), clusterChild:GetMaxPossiblePoints())
        bodySection:AddLine(formattedClusterChild, self:GetStyle("bodyDescription"))
    end
    self:AddSection(bodySection)
end