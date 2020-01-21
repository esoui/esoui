function ZO_Tooltip:LayoutSkillBuild(skillBuildId)
    local GET_ADVANCED_IF_NO_ID = true
    local skillBuild = ZO_SKILLS_ADVISOR_SINGLETON:GetAvailableSkillBuildById(skillBuildId, GET_ADVANCED_IF_NO_ID) 

    local headerSection = self:AcquireSection(self:GetStyle("topSection"))
    headerSection:AddLine(skillBuild.name, self:GetStyle("title"))
    self:AddSection(headerSection)

    local buildTypeTable = ZO_SKILLS_ADVISOR_SINGLETON:GetSkillBuildRoleLinesById(skillBuildId)
    if #buildTypeTable then
        local roleSection = self:AcquireSection(self:GetStyle("topSection"))
        -- Top section of tooltips displays the first added item at the bottom so we need to add lines in reverse order
        for i = #buildTypeTable, 1, -1 do
            roleSection:AddLine(buildTypeTable[i], self:GetStyle("topSection"))
        end
        self:AddSection(roleSection)
    end

    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(skillBuild.description, self:GetStyle("bodyDescription"))
    if skillBuildId == GetDefaultSkillBuildId() then
        bodySection:AddLine(GetString(SI_SKILLS_ADVISOR_SKILL_BUILD_NEW_PLAYER), self:GetStyle("bodyDescription"), self:GetStyle("succeeded"))
    end
    self:AddSection(bodySection)
end
