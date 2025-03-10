ZO_ACHIEVEMENTS_COMPLETION_STATUS = 
{
    NOT_APPLICABLE = 1,
    INCOMPLETE = 2,
    IN_PROGRESS = 3,
    COMPLETE = 4,
}

function ZO_GetAchievementStatus(achievementId)
    local completed = 0
    local total = 0
    local numCriteria = GetAchievementNumCriteria(achievementId)
    for criterionIndex = 1, numCriteria do
        local _, numCompleted, numRequired = GetAchievementCriterion(achievementId, criterionIndex)
        completed = completed + numCompleted
        total = total + numRequired
    end

    if total > 0 then
        if completed > 0 then
            if completed == total then
                return ZO_ACHIEVEMENTS_COMPLETION_STATUS.COMPLETE
            else
                return ZO_ACHIEVEMENTS_COMPLETION_STATUS.IN_PROGRESS
            end
        else
            return ZO_ACHIEVEMENTS_COMPLETION_STATUS.INCOMPLETE
        end
    end

    return ZO_ACHIEVEMENTS_COMPLETION_STATUS.NOT_APPLICABLE
end