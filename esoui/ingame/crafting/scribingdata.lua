---------------------------
-- ZO_CraftedAbilityScriptData --
---------------------------

ZO_CraftedAbilityScriptData = ZO_InitializingObject:Subclass()

function ZO_CraftedAbilityScriptData:Initialize(scriptId)
    self.scriptId = scriptId
end

function ZO_CraftedAbilityScriptData:GetId()
    return self.scriptId
end

function ZO_CraftedAbilityScriptData:GetDisplayName()
    return GetCraftedAbilityScriptDisplayName(self.scriptId)
end

function ZO_CraftedAbilityScriptData:GetFormattedName()
    return zo_strformat(SI_CRAFTED_ABILITY_SCRIPT_NAME_FORMATTER, self:GetDisplayName())
end

function ZO_CraftedAbilityScriptData:GetFormattedNameWithSlot()
    local slot = GetString("SI_SCRIBINGSLOT_SHORT", self:GetScribingSlot())
    return zo_strformat(SI_CRAFTED_ABILITY_SCRIPT_NAME_AND_SLOT_TYPE_FORMATTER, self:GetDisplayName(), slot)
end

function ZO_CraftedAbilityScriptData:GetDescription(craftedAbilityData)
    return GetCraftedAbilityScriptDescription(craftedAbilityData:GetId(), self.scriptId)
end

function ZO_CraftedAbilityScriptData:GetGeneralDescription()
    return GetCraftedAbilityScriptGeneralDescription(self.scriptId)
end

function ZO_CraftedAbilityScriptData:GetIcon()
    return GetCraftedAbilityScriptIcon(self.scriptId)
end

function ZO_CraftedAbilityScriptData:GetAcquireHint()
    return GetCraftedAbilityScriptAcquireHint(self.scriptId)
end

function ZO_CraftedAbilityScriptData:GetScribingSlot()
    return GetCraftedAbilityScriptScribingSlot(self.scriptId)
end

function ZO_CraftedAbilityScriptData:IsCompatibleWithSelections(craftedAbilityId, selectedPrimaryScriptId, selectedSecondaryScriptId, selectedTertiaryScriptId)
    return IsCraftedAbilityScriptCompatibleWithSelections(self.scriptId, craftedAbilityId, selectedPrimaryScriptId, selectedSecondaryScriptId, selectedTertiaryScriptId)
end

function ZO_CraftedAbilityScriptData:IsDisabled()
    return IsCraftedAbilityScriptDisabled(self.scriptId)
end

function ZO_CraftedAbilityScriptData:IsUnlocked()
    return IsCraftedAbilityScriptUnlocked(self.scriptId)
end

-----------------------------------
-- ZO_CraftedAbilityData --
-----------------------------------

ZO_CraftedAbilityData = ZO_InitializingObject:Subclass()

function ZO_CraftedAbilityData:Initialize(craftedAbilityId)
    self.craftedAbilityId = craftedAbilityId
    self.scribingSlotTable =
    {
        [SCRIBING_SLOT_PRIMARY] = {},
        [SCRIBING_SLOT_SECONDARY] = {},
        [SCRIBING_SLOT_TERTIARY] = {},
    }
end

function ZO_CraftedAbilityData:GetId()
    return self.craftedAbilityId
end

function ZO_CraftedAbilityData:GetDisplayName()
    return GetCraftedAbilityDisplayName(self.craftedAbilityId)
end

function ZO_CraftedAbilityData:GetFormattedName()
    return zo_strformat(SI_CRAFTED_ABILITY_NAME_FORMATTER, self:GetDisplayName())
end

function ZO_CraftedAbilityData:GetFormattedNameWithSkillLine()
    local skillData = self:GetSkillData()
    if skillData then
        local skillLineData = skillData:GetSkillLineData()
        local skillTypeData = skillLineData:GetSkillTypeData()
        return zo_strformat(SI_CRAFTED_ABILITY_NAME_AND_SKILL_LINE_FORMATTER, self:GetDisplayName(), skillTypeData:GetName(), skillLineData:GetName())
    end
    return self:GetFormattedName()
end

function ZO_CraftedAbilityData:GetDescription()
    return GetCraftedAbilityDescription(self.craftedAbilityId)
end

function ZO_CraftedAbilityData:GetIcon()
    return GetCraftedAbilityIcon(self.craftedAbilityId)
end

function ZO_CraftedAbilityData:GetAcquireHint()
    return GetCraftedAbilityAcquireHint(self.craftedAbilityId)
end

function ZO_CraftedAbilityData:GetSkillType()
    return GetSkillTypeForCraftedAbilityId(self.craftedAbilityId)
end

function ZO_CraftedAbilityData:GetSkillAbilityIndices()
    return GetSkillAbilityIndicesFromCraftedAbilityId(self.craftedAbilityId)
end

function ZO_CraftedAbilityData:GetSkillData()
    local skillType, skillLineIndex, skillIndex = self:GetSkillAbilityIndices()
    return SKILLS_DATA_MANAGER:GetSkillDataByIndices(skillType, skillLineIndex, skillIndex)
end

function ZO_CraftedAbilityData:GetAbilityId()
    return GetAbilityIdForCraftedAbilityId(self.craftedAbilityId)
end

function ZO_CraftedAbilityData:GetRepresentativeAbilityId()
    return GetCraftedAbilityRepresentativeAbilityId(self.craftedAbilityId)
end

function ZO_CraftedAbilityData:SetScriptIdSelectionOverride(primaryScriptId, secondaryScriptId, tertiaryScriptId)
    SetCraftedAbilityScriptSelectionOverride(self.craftedAbilityId, primaryScriptId, secondaryScriptId, tertiaryScriptId)
end

function ZO_CraftedAbilityData:SetScriptDataSelectionOverride(primaryScriptData, secondaryScriptData, tertiaryScriptData)
    local primaryScriptId = primaryScriptData and primaryScriptData:GetId() or 0
    local secondaryScriptId = secondaryScriptData and secondaryScriptData:GetId() or 0
    local tertiaryScriptId = tertiaryScriptData and tertiaryScriptData:GetId() or 0
    self:SetScriptIdSelectionOverride(primaryScriptId, secondaryScriptId, tertiaryScriptId)
end

function ZO_CraftedAbilityData:IsScribableScriptIdCombination(primaryScriptId, secondaryScriptId, tertiaryScriptId)
    return IsScribableScriptCombinationForCraftedAbility(self.craftedAbilityId, primaryScriptId, secondaryScriptId, tertiaryScriptId)
end

function ZO_CraftedAbilityData:IsScribableScriptDataCombination(primaryScriptData, secondaryScriptData, tertiaryScriptData)
    local primaryScriptId = primaryScriptData and primaryScriptData:GetId() or 0
    local secondaryScriptId = secondaryScriptData and secondaryScriptData:GetId() or 0
    local tertiaryScriptId = tertiaryScriptData and tertiaryScriptData:GetId() or 0
    return self:IsScribableScriptIdCombination(primaryScriptId, secondaryScriptId, tertiaryScriptId)
end

function ZO_CraftedAbilityData:IsScriptActive(scriptData)
    return IsCraftedAbilityScriptActive(self.craftedAbilityId, scriptData:GetId())
end

function ZO_CraftedAbilityData:GetActiveScriptIds()
    return GetCraftedAbilityActiveScriptIds(self.craftedAbilityId)
end

function ZO_CraftedAbilityData:AreScriptIdsActive(primaryScriptId, secondaryScriptId, tertiaryScriptId)
    local activePrimaryScriptId, activeSecondaryScriptId, activeTertiaryScriptId = self:GetActiveScriptIds()
    return primaryScriptId == activePrimaryScriptId and secondaryScriptId == activeSecondaryScriptId and tertiaryScriptId == activeTertiaryScriptId
end

function ZO_CraftedAbilityData:AddScript(scribingSlot, scriptId)
    if scribingSlot ~= SCRIBING_SLOT_NONE then
        table.insert(self.scribingSlotTable[scribingSlot], scriptId)
    end
end

function ZO_CraftedAbilityData:GetScriptIdsForScribingSlot(scribingSlot)
    if scribingSlot ~= SCRIBING_SLOT_NONE then
        return self.scribingSlotTable[scribingSlot]
    end
end

function ZO_CraftedAbilityData:IsDisabled()
    return IsCraftedAbilityDisabled(self.craftedAbilityId)
end

function ZO_CraftedAbilityData:IsUnlocked()
    return IsCraftedAbilityUnlocked(self.craftedAbilityId)
end

function ZO_CraftedAbilityData:IsScribed()
    return IsCraftedAbilityScribed(self.craftedAbilityId)
end

function ZO_CraftedAbilityData:IsSlottedOnHotBar()
    local skillType, skillLineIndex, skillIndex = self:GetSkillAbilityIndices()
    local slotIndex = GetAssignedSlotFromSkillAbility(skillType, skillLineIndex, skillIndex)
    return slotIndex ~= nil
end