function ZO_Tooltip:LayoutRidingSkill(trainingType, bonus, maxBonus)
    --Title
    local headerSection = self:AcquireSection(self:GetStyle("bodyHeader"))
    headerSection:AddLine(GetString("SI_RIDINGTRAINTYPE", trainingType), self:GetStyle("title"))
    self:AddSection(headerSection)
    
    --Status bar
    local barSection = self:AcquireSection(self:GetStyle("conditionOrChargeBarSection"))
    local valueFormat = trainingType == RIDING_TRAIN_SPEED and SI_MOUNT_ATTRIBUTE_SPEED_FORMAT or SI_MOUNT_ATTRIBUTE_SIMPLE_FORMAT
    local skillBar = self:AcquireStatusBar(self:GetStyle("ridingTrainingChargeBar"))
    skillBar:SetValue(bonus, maxBonus, valueFormat)
    barSection:AddStatusBar(skillBar)
	self:AddSection(barSection)

    --Body
    local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
    bodySection:AddLine(zo_strformat(RIDING_TRAIN_DESCRIPTIONS[trainingType], GetMaxRidingTraining(trainingType)), self:GetStyle("bodyDescription"))
    self:AddSection(bodySection)

    local warningSection = self:AcquireSection(self:GetStyle("bodySection"))
    local warningText = GetString(bonus < maxBonus and SI_GAMEPAD_STABLE_ONCE_PER_DAY_WARNING or SI_GAMEPAD_STABLE_FULLY_UPGRADED_WARNING)
    warningSection:AddLine(warningText, self:GetStyle("bodyDescription"))
    self:AddSection(warningSection)
end