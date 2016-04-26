function ZO_Tooltip:LayoutGroupTooltip(title, bodyText, errorText)
    local titleSection = self:AcquireSection(self:GetStyle("groupTitleSection"))
    titleSection:AddLine(title, self:GetStyle("title"))
    self:AddSection(titleSection)

    local bodySection = self:AcquireSection(self:GetStyle("groupBodySection"), self:GetStyle("bodySection"))
    if errorText then
        bodySection:AddLine(errorText, self:GetStyle("groupDescription"), self:GetStyle("groupDescriptionError"))
    end
    bodySection:AddLine(bodyText, self:GetStyle("groupDescription"))
    self:AddSection(bodySection)
end

function ZO_Tooltip:LayoutDungeonDifficultyTooltip()
    local hasControlOfDifficulty, difficultyControlReason = CanPlayerChangeGroupDifficulty()

    local titleText = GetString(SI_GAMEPAD_GROUP_DUNGEON_DIFFICULTY)
    local bodyText = GetString(SI_DUNGEON_DIFFICULTY_HELP_TOOLTIP)
    local difficultyControlText = GetString("SI_GROUPDIFFICULTYCHANGEREASON", difficultyControlReason)
    local difficultyControlStyle = hasControlOfDifficulty and "succeeded" or "groupDescriptionError"

    local titleSection = self:AcquireSection(self:GetStyle("groupTitleSection"))
    titleSection:AddLine(titleText, self:GetStyle("title"))
    self:AddSection(titleSection)

    local bodySection = self:AcquireSection(self:GetStyle("groupBodySection"), self:GetStyle("bodySection"))
    bodySection:AddLine(difficultyControlText, self:GetStyle("groupDescription"), self:GetStyle(difficultyControlStyle))
    bodySection:AddLine(bodyText, self:GetStyle("groupDescription"))
    self:AddSection(bodySection)
end

do
    local TEXT_ROLES_GENERAL_DESCRIPTION = GetString(SI_GROUP_PREFERRED_ROLE_DESCRIPTION)

    function ZO_Tooltip:LayoutGroupRole(textTitle, textBody, lowestAverageTime)
        local titleSection = self:AcquireSection(self:GetStyle("groupRolesTitleSection"))
        titleSection:AddLine(textTitle, self:GetStyle("title"))

        if lowestAverageTime > 0 then
            local textLowestAverageTime = ZO_GetSimplifiedTimeEstimateText(lowestAverageTime * 1000)

            local statValuePair = titleSection:AcquireStatValuePair(self:GetStyle("statValuePair"))
            statValuePair:SetStat(GetString(SI_GAMEPAD_ACTIVITY_FINDER_DUNGEON_AVERAGE_ROLE_TIME_HEADER), self:GetStyle("statValuePairStat"))
            statValuePair:SetValue(textLowestAverageTime, self:GetStyle("groupRolesStatValuePairValue"))
            titleSection:AddStatValuePair(statValuePair)
        end

        self:AddSection(titleSection)

        local bodySection = self:AcquireSection(self:GetStyle("groupBodySection"), self:GetStyle("bodySection"))
        bodySection:AddLine(textBody, self:GetStyle("groupDescription"))
        bodySection:AddLine(TEXT_ROLES_GENERAL_DESCRIPTION, self:GetStyle("groupDescription"))
        self:AddSection(bodySection)
    end
end