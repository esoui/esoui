local SKILL_TYPE_TO_ICONS = 
{
    [SKILL_TYPE_CLASS] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_class_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_class_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_class_over.dds",
    },
    [SKILL_TYPE_WEAPON] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_weapons_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_weapons_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_weapons_over.dds",
    },
    [SKILL_TYPE_ARMOR] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_armor_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_armor_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_armor_over.dds",
    },
    [SKILL_TYPE_WORLD] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_world_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_world_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_world_over.dds",
    },
    [SKILL_TYPE_GUILD] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_guilds_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_guilds_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_guilds_over.dds",
    },
    [SKILL_TYPE_AVA] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_AVA_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_AVA_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_AVA_over.dds",
    },
    [SKILL_TYPE_RACIAL] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_race_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_race_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_race_over.dds",
    },
    [SKILL_TYPE_TRADESKILL] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_tradeskills_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_tradeskills_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_tradeskills_over.dds",
    },
}
function ZO_Skills_GetIconsForSkillType(skillType)
    if SKILL_TYPE_TO_ICONS[skillType] then
        return unpack(SKILL_TYPE_TO_ICONS[skillType])
    end
end

function ZO_SkillInfoXPBar_OnLevelChanged(xpBar, level)
    xpBar:GetControl():GetParent().rank:SetText(level)
end

function ZO_SkillInfoXPBar_SetValue(xpBar, level, lastRankXP, nextRankXP, currentXP, forceInit)
    local maxed = (nextRankXP == 0)

    if maxed then
        xpBar:SetValue(level, 1, 1, forceInit)
    else
        xpBar:SetValue(level, currentXP - lastRankXP, nextRankXP - lastRankXP, forceInit)
    end
end


ZO_SKILLS_MORPH_STATE = 1
ZO_SKILLS_PURCHASE_STATE = 2

function ZO_Skills_SetAlertButtonTextures(control, styleTable)
    if control:GetType() == CT_TEXTURE then
        control:AddIcon(styleTable.normal)
    elseif control:GetType() == CT_BUTTON then
        control:SetNormalTexture(styleTable.normal)
        control:SetPressedTexture(styleTable.mouseDown)
        control:SetMouseOverTexture(styleTable.mouseover)
    end
end

function ZO_Skills_GenerateAbilityName(stringIndex, name, currentUpgradeLevel, maxUpgradeLevel, progressionIndex)
    if currentUpgradeLevel and maxUpgradeLevel then
        return zo_strformat(stringIndex, name, currentUpgradeLevel, maxUpgradeLevel) 
    elseif progressionIndex then
        local _, _, rank = GetAbilityProgressionInfo(progressionIndex)
        if rank > 0 then
            return zo_strformat(SI_ABILITY_NAME_AND_RANK, name, rank)
        end
    end

    return zo_strformat(SI_SKILLS_ENTRY_NAME_FORMAT, name)
end

function ZO_Skills_PurchaseAbility(skillType, skillLineIndex, abilityIndex)
    PlaySound(SOUNDS.ABILITY_SKILL_PURCHASED)
    PutPointIntoSkillAbility(skillType, skillLineIndex, abilityIndex)

    local isPassive, isUltimate = select(4, GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex))
    if isUltimate then
        TriggerTutorial(TUTORIAL_TRIGGER_PURCHASED_ULTIMATE_ABILITY)
    elseif isPassive then
        TriggerTutorial(TUTORIAL_TRIGGER_PURCHASED_PASSIVE_ABILITY)
    else
        TriggerTutorial(TUTORIAL_TRIGGER_PURCHASED_ABILITY)
    end
end

function ZO_Skills_UpgradeAbility(skillType, skillLineIndex, abilityIndex)
    PlaySound(SOUNDS.ABILITY_UPGRADE_PURCHASED)
    local PUT_POINT_IN_NEXT_UPGRADE = true
    PutPointIntoSkillAbility(skillType, skillLineIndex, abilityIndex, PUT_POINT_IN_NEXT_UPGRADE)
end

function ZO_Skills_MorphAbility(progressionIndex, morphChoiceIndex)
    PlaySound(SOUNDS.ABILITY_MORPH_PURCHASED)
    ChooseAbilityProgressionMorph(progressionIndex, morphChoiceIndex)
end

function ZO_Skills_TieSkillInfoHeaderToCraftingSkill(skillInfoHeaderControl, craftingSkillType)
    local name = skillInfoHeaderControl.name
    local xpBar = skillInfoHeaderControl.xpBar
    local rank = skillInfoHeaderControl.rank
    local glowContainer = skillInfoHeaderControl.glowContainer

    skillInfoHeaderControl.increaseAnimation = skillInfoHeaderControl.increaseAnimation or ANIMATION_MANAGER:CreateTimelineFromVirtual("SkillIncreasedBarAnimation", glowContainer)

    local hadUpdateWhileCrafting = false

    local function UpdateSkillInfoHeader(eventCode, skillTypeUpdated, skillIndexUpdated)
        local skillType, skillIndex = GetCraftingSkillLineIndices(craftingSkillType)
        if eventCode == nil or (skillTypeUpdated == skillType and skillIndexUpdated == skillIndex) then
            if ZO_CraftingUtils_IsPerformingCraftProcess() then
                hadUpdateWhileCrafting = true
            else
                local lineName, lineRank = GetSkillLineInfo(skillType, skillIndex)
                local lastXP, nextXP, currentXP = GetSkillLineXPInfo(skillType, skillIndex)

                name:SetText(zo_strformat(SI_SKILLS_ENTRY_LINE_NAME_FORMAT, lineName))
                local lastRank = rank.lineRank
                rank.lineRank = lineRank

                xpBar:GetControl().skillType = skillType
                xpBar:GetControl().skillIndex = skillIndex

                if eventCode or hadUpdateWhileCrafting then
                    skillInfoHeaderControl.increaseAnimation:PlayFromStart()

                    if lineRank > lastRank then
                        CENTER_SCREEN_ANNOUNCE:AddMessage(EVENT_SKILL_RANK_UPDATE, CSA_EVENT_LARGE_TEXT, SOUNDS.SKILL_LINE_LEVELED_UP, zo_strformat(SI_SKILL_RANK_UP, lineName, lineRank))
                    end
                end

                ZO_SkillInfoXPBar_SetValue(xpBar, lineRank, lastXP, nextXP, currentXP, eventCode == nil and not hadUpdateWhileCrafting)
            end

            if SkillTooltip:GetOwner() == xpBar:GetControl() then
                ZO_SkillInfoXPBar_OnMouseEnter(xpBar:GetControl())
            end
        end
    end

    skillInfoHeaderControl:RegisterForEvent(EVENT_SKILL_RANK_UPDATE, UpdateSkillInfoHeader)
    skillInfoHeaderControl:RegisterForEvent(EVENT_SKILL_XP_UPDATE, UpdateSkillInfoHeader)

    skillInfoHeaderControl.craftingAnimationsStoppedCallback = function() 
        if hadUpdateWhileCrafting then
            UpdateSkillInfoHeader()
            hadUpdateWhileCrafting = false
        end
    end

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", skillInfoHeaderControl.craftingAnimationsStoppedCallback)

    UpdateSkillInfoHeader()
end

function ZO_SkillsInfo_OnInitialized(control)
    control.name = GetControl(control, "Name")
    control.rank = GetControl(control, "Rank")
    control.xpBar = ZO_WrappingStatusBar:New(GetControl(control, "XPBar"), ZO_SkillInfoXPBar_OnLevelChanged)
    ZO_StatusBar_SetGradientColor(control.xpBar:GetControl(), ZO_SKILL_XP_BAR_GRADIENT_COLORS)
    control.glowContainer = GetControl(control.xpBar:GetControl(), "GlowContainer")
end

function ZO_Skills_UntieSkillInfoHeaderToCraftingSkill(skillInfoHeaderControl)
    skillInfoHeaderControl:UnregisterForEvent(EVENT_SKILL_RANK_UPDATE)
    skillInfoHeaderControl:UnregisterForEvent(EVENT_SKILL_XP_UPDATE)
    CALLBACK_MANAGER:UnregisterCallback("CraftingAnimationsStopped", skillInfoHeaderControl.craftingAnimationsStoppedCallback)
    skillInfoHeaderControl.craftingAnimationsStoppedCallback = nil
end

function ZO_Skills_AbilityFailsWerewolfRequirement(skillType, lineIndex)
    return IsWerewolf() and not IsWerewolfSkillLine(skillType, lineIndex)
end

function ZO_Skills_OnlyWerewolfAbilitiesAllowedAlert()
    ZO_AlertEvent(EVENT_HOT_BAR_RESULT, HOT_BAR_RESULT_CANNOT_USE_WHILE_WEREWOLF)
end