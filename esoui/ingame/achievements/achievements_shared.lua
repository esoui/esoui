function ZO_GetNextInProgressAchievementInLine(achievementId)
    local nextAchievementId = achievementId
    while nextAchievementId ~= 0 do
        achievementId = nextAchievementId

        if not IsAchievementComplete(achievementId) then
            return achievementId
        end

        nextAchievementId = GetNextAchievementInLine(achievementId)
    end

    return achievementId
end

function ZO_ShouldShowAchievement(filterType, id)
    if filterType == SI_ACHIEVEMENT_FILTER_SHOW_ALL then
        return true
    end

    while id ~= 0 do
        local _, _, _, _, completed, _, _= GetAchievementInfo(id)
        if completed then
            if filterType == SI_ACHIEVEMENT_FILTER_SHOW_EARNED then
                return true
            end

            -- This achievement was completed, but we want to show unearned, so see if there are any unearned achievements in this line
            id = GetNextAchievementInLine(id)

        else -- This achievement wasn't completed
            if filterType == SI_ACHIEVEMENT_FILTER_SHOW_UNEARNED then
                return true
            end

            -- Otherwise we only want to show earned achievements, so find the first completed achievement working backwards from this one
            id = GetPreviousAchievementInLine(id)
        end
    end

    -- Either this achievement wasn't a line, or everything in it was filtered.
    return false
end

function ZO_GetAchievementIds(categoryIndex, subcategoryIndex, numAchievements, considerSearchResults)
    local result = {}
    local searchResults = considerSearchResults and ACHIEVEMENTS_MANAGER:GetSearchResults()
    if searchResults then
        local effectiveSubcategoryIndex = subcategoryIndex or ZO_ACHIEVEMENTS_ROOT_SUBCATEGORY
        searchResults = searchResults[categoryIndex][effectiveSubcategoryIndex]
    end

    for achievementIndex = 1, numAchievements do
        if not searchResults or searchResults[achievementIndex] then
            table.insert(result, GetAchievementId(categoryIndex, subcategoryIndex, achievementIndex))
        end
    end
    return result
end
