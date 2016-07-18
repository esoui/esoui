local CHECKED_ICON = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"
local UNCHECKED_ICON = nil
local NO_ACHIEVEMENT_ICON = "EsoUI/Art/Achievements/Gamepad/Achievement_EmptyIcon.dds"

function ZO_Tooltip:LayoutAchievementFromLink(achievementLink)
    local achievementId = GetAchievementIdFromLink(achievementLink)
    if achievementId > 0 then
        self:LayoutAchievement(achievementId)
    end
end

function ZO_Tooltip:LayoutAchievementSummary()
    for categoryIndex=1, GetNumAchievementCategories() do
        local categoryName, numSubCategories, numAchievements, earnedPoints, totalPoints = GetAchievementCategoryInfo(categoryIndex)

        local categorySection = self:AcquireSection(self:GetStyle("achievementSummaryCategorySection"))
        categorySection:AddLine(categoryName, self:GetStyle("achievementCriteriaProgress"))

        local barSection = categorySection:AcquireSection(self:GetStyle("achievementCriteriaBarWrapper"))
        local statusBar = self:AcquireStatusBar(self:GetStyle("achievementCriteriaBar"))
        statusBar:SetMinMax(0, totalPoints)
        statusBar:SetValue(earnedPoints)
        barSection:AddStatusBar(statusBar)
        categorySection:AddSection(barSection)

        self:AddSection(categorySection)
    end
end

function ZO_Tooltip:LayoutNoAchievement()
    local completionStyle = self:GetStyle("achievementComplete")

    -- Title
    local titleTextSection = self:AcquireSection(self:GetStyle("achievementTextSection"))
    titleTextSection:AddLine(GetString(SI_GAMEPAD_ACHIEVEMENTS_NO_ACHIEVEMENT), completionStyle, self:GetStyle("achievementName"))
    self:AddSection(titleTextSection)
end

function ZO_Tooltip:LayoutAchievement(achievementId)
    local achievementName, description, points, icon, completed, date, time = GetAchievementInfo(achievementId)
    local completionStyle = completed and self:GetStyle("achievementComplete") or self:GetStyle("achievementIncomplete")

    -- Title
    local titleTextSection = self:AcquireSection(self:GetStyle("achievementTextSection"))
    if completed then
        titleTextSection:AddLine(date, self:GetStyle("achievementSubtitleText"))
    else
        titleTextSection:AddLine(GetString(SI_ACHIEVEMENTS_TOOLTIP_PROGRESS), self:GetStyle("achievementSubtitleText"))
    end
    titleTextSection:AddLine(zo_strformat(SI_ACHIEVEMENTS_NAME, achievementName), completionStyle, self:GetStyle("achievementName"))
    if points ~= ACHIEVEMENT_POINT_LEGENDARY_DEED then
        local pointsEntrySection = titleTextSection:AcquireSection(self:GetStyle("achievementPointsSection"))
        pointsEntrySection:AddLine(GetString(SI_GAMEPAD_ACHIEVEMENTS_POINTS_LABEL), self:GetStyle("achievementPointsText"))
        pointsEntrySection:AddLine(points, self:GetStyle("achievementRewardsName"))
        titleTextSection:AddSection(pointsEntrySection)
    end
    self:AddSection(titleTextSection)

    -- Body
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(zo_strformat(SI_ACHIEVEMENTS_DESCRIPTION, description), self:GetStyle("flavorText"))
    self:AddSection(bodySection)

    self:LayoutAchievementCriteria(achievementId)
    self:LayoutAchievementRewards(achievementId)
end

function ZO_Tooltip:LayoutAchievementCriteria(achievementId)
    local numCriteria = GetAchievementNumCriteria(achievementId)
    if numCriteria == 1 then
        local description, numCompleted, numRequired = GetAchievementCriterion(achievementId, 1)
        if numRequired == 1 then
            -- Do not show a single checkbox.
            return
        end
    end

    local criteriaSection = self:AcquireSection(self:GetStyle("achievementCriteriaSection"))

    for i = 1, numCriteria do
        local description, numCompleted, numRequired = GetAchievementCriterion(achievementId, i)
        local isComplete = (numCompleted == numRequired)

        if numRequired == 1 then -- Checkbox
            local checkStyle = isComplete and "achievementCriteriaCheckComplete" or "achievementCriteriaCheckIncomplete"
            local descriptionStyle = isComplete and "achievementDescriptionComplete" or "achievementDescriptionIncomplete"
            local texture = isComplete and CHECKED_ICON or UNCHECKED_ICON

            local entrySection = self:AcquireSection(self:GetStyle("achievementCriteriaSectionCheck"))
            entrySection:AddTexture(texture, self:GetStyle(checkStyle))
            entrySection:AddLine(zo_strformat(SI_ACHIEVEMENT_CRITERION_FORMAT, description), self:GetStyle(descriptionStyle))
            criteriaSection:AddSection(entrySection)

        else -- Progress bar.
            local entrySection = self:AcquireSection(self:GetStyle("achievementCriteriaSectionBar"))
            entrySection:AddLine(zo_strformat(SI_ACHIEVEMENT_CRITERION_FORMAT, description), self:GetStyle("achievementCriteriaProgress"))
            entrySection:AddLine(zo_strformat(SI_JOURNAL_PROGRESS_BAR_PROGRESS, numCompleted, numRequired), self:GetStyle("achievementCriteriaProgress"))

            local barSection = entrySection:AcquireSection(self:GetStyle("achievementCriteriaBarWrapper"))
            local statusBar = self:AcquireStatusBar(self:GetStyle("achievementCriteriaBar"))
            statusBar:SetMinMax(0, numRequired)
            statusBar:SetValue(numCompleted)
            barSection:AddStatusBar(statusBar)
            entrySection:AddSection(barSection)

            criteriaSection:AddSection(entrySection)
        end
    end
    self:AddSection(criteriaSection)
end

function ZO_Tooltip:LayoutAchievementRewards(achievementId)
    local hasRewardItem, itemName, iconTextureName, quality = GetAchievementRewardItem(achievementId)
    local hasRewardTitle, titleName = GetAchievementRewardTitle(achievementId)
    local hasRewardDye, dyeId = GetAchievementRewardDye(achievementId)
    local hasRewardCollectible, collectibleId = GetAchievementRewardCollectible(achievementId)
    local hasReward = hasRewardItem or hasRewardTitle or hasRewardDye or hasRewardCollectible

    if not hasReward then
        return
    end

    local rewardsSection = self:AcquireSection(self:GetStyle("achievementRewardsSection"))

    -- Item
    if hasRewardItem then
        local itemSection = rewardsSection:AcquireSection(self:GetStyle("achievementRewardsEntrySection"))
        itemSection:AddLine(GetString(SI_GAMEPAD_ACHIEVEMENTS_ITEM_LABEL), self:GetStyle("achievementRewardsTitle"))

        local iconStyle = self:GetStyle("achievementItemIcon")
        local iconTexture = zo_iconFormat(iconTextureName, iconStyle.width, iconStyle.height)
        itemSection:AddLine(zo_strformat(SI_GAMEPAD_ACHIEVEMENTS_ITEM_ICON_AND_DESCRIPTION, iconTexture, itemName), ZO_TooltipStyles_GetItemQualityStyle(quality), self:GetStyle("achievementRewardsName"))

        rewardsSection:AddSection(itemSection)
    end

    -- Title
    if hasRewardTitle then
        local rewardsEntrySection = rewardsSection:AcquireSection(self:GetStyle("achievementRewardsEntrySection"))
        rewardsEntrySection:AddLine(GetString(SI_GAMEPAD_ACHIEVEMENTS_TITLE), self:GetStyle("achievementRewardsTitle"))
        rewardsEntrySection:AddLine(titleName, self:GetStyle("achievementName"))

        rewardsSection:AddSection(rewardsEntrySection)
    end

    -- Dye
    if hasRewardDye then
        local rewardsEntrySection = rewardsSection:AcquireSection(self:GetStyle("achievementRewardsEntrySection"))
        rewardsEntrySection:AddLine(GetString(SI_GAMEPAD_ACHIEVEMENTS_DYE), self:GetStyle("achievementRewardsTitle"))

        local swatchStyle = self:GetStyle("dyeSwatchStyle")
        local dyeName, known, rarity, hueCategory, achievementId, r, g, b = GetDyeInfoById(dyeId)
        rewardsEntrySection:AddColorAndTextSwatch(r, g, b, 1, dyeName, swatchStyle)

        rewardsSection:AddSection(rewardsEntrySection)
    end

    --Collectible
    if hasRewardCollectible then
        local collectibleName, _, _, _, _, _, _, categoryType = GetCollectibleInfo(collectibleId)
        local rewardsEntrySection = rewardsSection:AcquireSection(self:GetStyle("achievementRewardsEntrySection"))
        rewardsEntrySection:AddLine(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, GetString("SI_COLLECTIBLECATEGORYTYPE", categoryType)), self:GetStyle("achievementRewardsTitle"))
        rewardsEntrySection:AddLine(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, collectibleName), self:GetStyle("achievementRewardsName"))

        rewardsSection:AddSection(rewardsEntrySection)
    end

    self:AddSection(rewardsSection)
end
