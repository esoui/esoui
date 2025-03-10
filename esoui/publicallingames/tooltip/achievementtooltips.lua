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
        categorySection:AddLine(categoryName, self:GetStyle("achievementSummaryCriteriaHeader"))

        local barSection = self:AcquireSection(self:GetStyle("topSection"))
        local statusBar = self:AcquireStatusBar(self:GetStyle("achievementCriteriaBar"))
        statusBar:SetMinMax(0, totalPoints)
        statusBar:SetValue(earnedPoints)
        local function GetStatusBarNarrationText()
            local percentage = (earnedPoints / totalPoints) * 100
            percentage = string.format("%.2f", percentage)
            return zo_strformat(SI_SCREEN_NARRATION_PERCENT_FORMATTER, percentage)
        end
        barSection:AddStatusBar(statusBar, GetStatusBarNarrationText)
        categorySection:AddSection(barSection)

        self:AddSection(categorySection)
    end
end

function ZO_Tooltip:LayoutNoAchievement()
    -- Title
    local titleTextSection = self:AcquireSection(self:GetStyle("topSection"))
    titleTextSection:AddLine(GetString(SI_GAMEPAD_ACHIEVEMENTS_NO_ACHIEVEMENT), self:GetStyle("title"))
    self:AddSection(titleTextSection)
end

function ZO_Tooltip:LayoutAchievement(achievementId)
    local achievementName, description, points, icon, completed, date, time = GetAchievementInfo(achievementId)
    local achievementStatus = ZO_GetAchievementStatus(achievementId)
    local persistenceLevel = GetAchievementPersistenceLevel(achievementId)
    local isCharacterPersistent = persistenceLevel == ACHIEVEMENT_PERSISTENCE_CHARACTER

    -- Title
    local titleTextSection = self:AcquireSection(self:GetStyle("topSection"))
    local titleStyle = {}
    if isCharacterPersistent then
        table.insert(titleStyle, self:GetStyle("achievementCharacterHeading"))
    end
    table.insert(titleStyle, self:GetStyle("title"))
    -- Achievement display names use gender switching
    titleTextSection:AddLine(zo_strformat(achievementName), unpack(titleStyle))

    if completed then
        titleTextSection:AddLine(date)
    elseif achievementStatus == ZO_ACHIEVEMENTS_COMPLETION_STATUS.IN_PROGRESS then
        titleTextSection:AddLine(GetString(SI_ACHIEVEMENTS_PROGRESS))
    elseif achievementStatus == ZO_ACHIEVEMENTS_COMPLETION_STATUS.INCOMPLETE then
        titleTextSection:AddLine(GetString(SI_ACHIEVEMENTS_INCOMPLETE))
    end

    if isCharacterPersistent then
        local titleIcon = zo_iconFormatInheritColor("EsoUI/Art/Miscellaneous/Gamepad/gp_charNameIcon.dds", "75%", "75%")
        local titleText = zo_strformat(SI_ACHIEVEMENT_TITLE_CHARACTER_LEVEL, titleIcon, GetString(SI_GAMEPAD_ACHIEVEMENTS_CHARACTER_PERSISTENT))
        titleTextSection:AddLine(titleText, self:GetStyle("achievementCharacterHeading"))
    end

    self:AddSection(titleTextSection)

    if points ~= ACHIEVEMENT_POINT_LEGENDARY_DEED then
        local statValuePair = self:AcquireStatValuePair(self:GetStyle("statValuePair"))
        statValuePair:SetStat(GetString(SI_GAMEPAD_ACHIEVEMENTS_POINTS_LABEL), self:GetStyle("statValuePairStat"))
        statValuePair:SetValue(points, self:GetStyle("statValuePairValue"))
        self:AddStatValuePair(statValuePair)
    end

    -- Body
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(zo_strformat(description), self:GetStyle("flavorText"))
    self:AddSection(bodySection)

    self:LayoutAchievementCriteria(achievementId)
    self:LayoutAchievementRewards(achievementId)

    if completed and not isCharacterPersistent then
        local completeByCharId = GetCharIdForCompletedAchievement(achievementId)
        if completeByCharId then
            local completedSection = self:AcquireSection(self:GetStyle("bodySection"))
            local characterName = GetCharacterNameById(completeByCharId)
            if characterName ~= "" then
                local colorizedCharacterName = ZO_SELECTED_TEXT:Colorize(colorizedCharacterName)
                completedSection:AddLine(zo_strformat(SI_ACHIEVEMENT_EARNED_FORMATTER, characterName), self:GetStyle("flavorText"))
                self:AddSection(completedSection)
            end
        end
    end
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
            criteriaSection:AddSection(self:GetCheckboxSection(zo_strformat(SI_ACHIEVEMENT_CRITERION_FORMAT, description), isComplete))
        else -- Progress bar.
            local entrySection = self:AcquireSection(self:GetStyle("topSection"))
            local statusBar = self:AcquireStatusBar(self:GetStyle("achievementCriteriaBar"))
            statusBar:SetMinMax(0, numRequired)
            statusBar:SetValue(numCompleted)
            entrySection:AddStatusBar(statusBar)
            entrySection:AddLine(zo_strformat(SI_JOURNAL_PROGRESS_BAR_PROGRESS, numCompleted, numRequired), self:GetStyle("statValuePairValueSmall"))
            entrySection:AddLine(zo_strformat(SI_ACHIEVEMENT_CRITERION_FORMAT, description))

            criteriaSection:AddSection(entrySection)
        end
    end
    self:AddSection(criteriaSection)
end

function ZO_Tooltip:GetCheckboxSection(text, isComplete)
    local CHECKED_ICON = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"
    local UNCHECKED_ICON = nil
    local checkStyle = isComplete and "achievementCriteriaCheckComplete" or "achievementCriteriaCheckIncomplete"
    local textStyle = isComplete and "achievementDescriptionComplete" or "achievementDescriptionIncomplete"
    local texture = isComplete and CHECKED_ICON or UNCHECKED_ICON

    local entrySection = self:AcquireSection(self:GetStyle("achievementCriteriaSectionCheck"))
    entrySection:AddTexture(texture, self:GetStyle(checkStyle))
    entrySection:AddLine(text, self:GetStyle(textStyle))
    return entrySection
end

function ZO_Tooltip:LayoutAchievementRewards(achievementId)
    local hasRewardItem, itemName, iconTextureName, displayQuality = GetAchievementRewardItem(achievementId)
    local hasRewardTitle, titleName = GetAchievementRewardTitle(achievementId)
    local hasRewardDye, dyeId = GetAchievementRewardDye(achievementId)
    local hasRewardCollectible, collectibleId = GetAchievementRewardCollectible(achievementId)
    local hasRewardTributeCardUpgrade, tributePatronId, tributeCardIndex = GetAchievementRewardTributeCardUpgradeInfo(achievementId)
    local hasReward = hasRewardItem or hasRewardTitle or hasRewardDye or hasRewardCollectible or hasRewardTributeCardUpgrade

    if not hasReward then
        return
    end

    local rewardsSection = self:AcquireSection(self:GetStyle("achievementRewardsSection"))

    -- Item
    if hasRewardItem then
        local itemSection = rewardsSection:AcquireSection(self:GetStyle("topSection"))
        local iconStyle = self:GetStyle("achievementItemIcon")
        local iconTexture = zo_iconFormat(iconTextureName, iconStyle.width, iconStyle.height)
        itemSection:AddLine(zo_strformat(SI_GAMEPAD_ACHIEVEMENTS_ITEM_ICON_AND_DESCRIPTION, iconTexture, itemName), ZO_TooltipStyles_GetItemQualityStyle(displayQuality), self:GetStyle("statValuePairValueSmall"))
        itemSection:AddLine(GetString(SI_GAMEPAD_ACHIEVEMENTS_ITEM_LABEL))

        rewardsSection:AddSection(itemSection)
    end

    -- Title
    if hasRewardTitle then
        local rewardsEntrySection = rewardsSection:AcquireSection(self:GetStyle("topSection"))
        rewardsEntrySection:AddLine(titleName, self:GetStyle("statValuePairValueSmall"))
        rewardsEntrySection:AddLine(GetString(SI_GAMEPAD_ACHIEVEMENTS_TITLE))

        rewardsSection:AddSection(rewardsEntrySection)
    end

    -- Dye
    if hasRewardDye then
        local rewardsEntrySection = rewardsSection:AcquireSection(self:GetStyle("topSection"))
        local swatchStyle = self:GetStyle("dyeSwatchStyle")
        local dyeName, known, rarity, hueCategory, dyeAchievementId, r, g, b = GetDyeInfoById(dyeId)
        rewardsEntrySection:AddColorAndTextSwatch(r, g, b, 1, dyeName, swatchStyle)
        rewardsEntrySection:AddLine(GetString(SI_GAMEPAD_ACHIEVEMENTS_DYE))

        rewardsSection:AddSection(rewardsEntrySection)
    end

    --Collectible
    if hasRewardCollectible then
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        local rewardsEntrySection = rewardsSection:AcquireSection(self:GetStyle("topSection"))
        rewardsEntrySection:AddLine(collectibleData:GetFormattedName(), self:GetStyle("statValuePairValueSmall"))
        rewardsEntrySection:AddLine(ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, collectibleData:GetCategoryTypeDisplayName()))

        rewardsSection:AddSection(rewardsEntrySection)
    end

    --Tribute Card Upgrade
    if hasRewardTributeCardUpgrade then
        local patronData = TRIBUTE_DATA_MANAGER:GetTributePatronData(tributePatronId)
        local baseCardId, upgradeCardId = patronData:GetDockCardInfoByIndex(tributeCardIndex)
        local upgradeCardData = ZO_TributeCardData:New(tributePatronId, upgradeCardId)
        local rewardsEntrySection = rewardsSection:AcquireSection(self:GetStyle("topSection"))
        rewardsEntrySection:AddLine(upgradeCardData:GetColorizedFormattedName(), self:GetStyle("statValuePairValueSmall"))
        rewardsEntrySection:AddLine(GetString(SI_GAMEPAD_ACHIEVEMENTS_TRIBUTE_CARD_UPGRADE))
        rewardsSection:AddSection(rewardsEntrySection)
    end

    self:AddSection(rewardsSection)
end