ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE = 1
ZO_SKILL_ABILITY_DISPLAY_VIEW = 2

ZO_SKILL_RESPEC_INTERACT_INFO =
{
    type = "Skill Respec Shrine",
    End = function()
        SCENE_MANAGER:ShowBaseScene()
    end,
    interactTypes = { INTERACTION_SKILL_RESPEC },
}

ZO_SceneManager_Leader.AddBypassHideSceneConfirmationReason("SKILLS_PLAYER_DEACTIVATED")

function ZO_SkillInfoXPBar_OnLevelChanged(xpBar, level)
    xpBar:GetControl():GetParent().rank:SetText(level)
end

function ZO_SkillInfoXPBar_SetValue(xpBar, level, lastRankXP, nextRankXP, currentXP, noWrap)
    local maxed = nextRankXP == 0 or nextRankXP == lastRankXP

    if maxed then
        xpBar:SetValue(level, 1, 1, noWrap)
    else
        xpBar:SetValue(level, currentXP - lastRankXP, nextRankXP - lastRankXP, noWrap)
    end
end

function ZO_Skills_TieSkillInfoHeaderToCraftingSkill(skillInfoHeaderControl, craftingSkillType)
    local name = skillInfoHeaderControl.name
    local xpBar = skillInfoHeaderControl.xpBar
    local rank = skillInfoHeaderControl.rank
    local glowContainer = skillInfoHeaderControl.glowContainer

    skillInfoHeaderControl.increaseAnimation = skillInfoHeaderControl.increaseAnimation or ANIMATION_MANAGER:CreateTimelineFromVirtual("SkillIncreasedBarAnimation", glowContainer)

    local hadUpdateWhileCrafting = false
    skillInfoHeaderControl.updateSkillInfoHeaderCallback = function(skillLineData)
        local craftingSkillLineData = SKILLS_DATA_MANAGER:GetCraftingSkillLineData(craftingSkillType)

        if not skillLineData or skillLineData == craftingSkillLineData then
            if ZO_CraftingUtils_IsPerformingCraftProcess() then
                hadUpdateWhileCrafting = true
            else
                if craftingSkillLineData == nil then
                    local isSettingTemplate = IsSettingTemplate() and "true" or "false"
                    local numTradeSkillLinesInC = GetNumSkillLines(SKILL_TYPE_TRADESKILL)
                    local message = string.format("CraftingType yielded no skill line data. Is Setting Template - %s; Num Trade Skill Lines in C - %d", isSettingTemplate, numTradeSkillLinesInC)
                    internalassert(false, message)
                end

                local lineRank = craftingSkillLineData:GetCurrentRank()
                local lastXP, nextXP, currentXP = craftingSkillLineData:GetRankXPValues()

                name:SetText(craftingSkillLineData:GetFormattedName())
                local lastRank = rank.lineRank
                rank.lineRank = lineRank

                xpBar:GetControl().skillLineData = craftingSkillLineData

                if skillLineData or hadUpdateWhileCrafting then
                    skillInfoHeaderControl.increaseAnimation:PlayFromStart()
                end

                ZO_SkillInfoXPBar_SetValue(xpBar, lineRank, lastXP, nextXP, currentXP, skillLineData == nil and not hadUpdateWhileCrafting)
            end

            if SkillTooltip:GetOwner() == xpBar:GetControl() then
                ZO_SkillInfoXPBar_OnMouseEnter(xpBar:GetControl())
            end
        end
        SKILLS_DATA_MANAGER:UnregisterCallback("FullSystemUpdated", skillInfoHeaderControl.updateSkillInfoHeaderCallback)
    end

    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineUpdated", skillInfoHeaderControl.updateSkillInfoHeaderCallback)

    skillInfoHeaderControl.craftingAnimationsStoppedCallback = function() 
        if hadUpdateWhileCrafting then
            skillInfoHeaderControl.updateSkillInfoHeaderCallback()
            hadUpdateWhileCrafting = false
        end
    end

    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", skillInfoHeaderControl.craftingAnimationsStoppedCallback)

    if SKILLS_DATA_MANAGER:IsDataReady() then
        skillInfoHeaderControl.updateSkillInfoHeaderCallback()
    else
        SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", skillInfoHeaderControl.updateSkillInfoHeaderCallback)
    end
end

function ZO_Skills_UntieSkillInfoHeaderToCraftingSkill(skillInfoHeaderControl)
    SKILLS_DATA_MANAGER:UnregisterCallback("SkillLineUpdated", skillInfoHeaderControl.updateSkillInfoHeaderCallback)
    SKILLS_DATA_MANAGER:UnregisterCallback("FullSystemUpdated", skillInfoHeaderControl.updateSkillInfoHeaderCallback)
    CALLBACK_MANAGER:UnregisterCallback("CraftingAnimationsStopped", skillInfoHeaderControl.craftingAnimationsStoppedCallback)
    skillInfoHeaderControl.craftingAnimationsStoppedCallback = nil
end

function ZO_SkillsInfo_OnInitialized(control)
    control.name = control:GetNamedChild("Name")
    control.rank = control:GetNamedChild("Rank")
    control.xpBar = ZO_WrappingStatusBar:New(control:GetNamedChild("XPBar"), ZO_SkillInfoXPBar_OnLevelChanged)
    local statusBarControl = control.xpBar:GetControl()
    ZO_StatusBar_SetGradientColor(statusBarControl, ZO_SKILL_XP_BAR_GRADIENT_COLORS)
    control.glowContainer = statusBarControl:GetNamedChild("GlowContainer")
end

function ZO_Skills_SetKeyboardAbilityButtonTextures(button)
    local advisedBorder = button:GetNamedChild("AdvisedBorder")
    local skillProgressionData = button.skillProgressionData
    local isPassive = skillProgressionData:IsPassive()
    if ZO_SKILLS_ADVISOR_SINGLETON:IsSkillProgressionDataInSelectedBuild(skillProgressionData) then
        if isPassive then
            button:SetNormalTexture("EsoUI/Art/SkillsAdvisor/circle_passiveAbilityFrame_doubleframe.dds")
            button:SetPressedTexture("EsoUI/Art/SkillsAdvisor/circle_passiveAbilityFrame_doubleframe_down.dds")
            button:SetMouseOverTexture("EsoUI/Art/ActionBar/passiveAbilityFrame_round_over.dds")
            button:SetDisabledTexture("EsoUI/Art/SkillsAdvisor/circle_passiveAbilityFrame_doubleframe.dds")
        else
            button:SetNormalTexture("EsoUI/Art/SkillsAdvisor/square_abilityFrame64_doubleFrame.dds")
            button:SetPressedTexture("EsoUI/Art/SkillsAdvisor/square_abilityFrame64_doubleFrame_down.dds")
            button:SetMouseOverTexture("EsoUI/Art/ActionBar/actionBar_mouseOver.dds")
            button:SetDisabledTexture("EsoUI/Art/SkillsAdvisor/square_abilityFrame64_doubleFrame.dds")
        end

        if isPassive then
            advisedBorder:SetTexture("EsoUI/Art/SkillsAdvisor/circle_passiveAbilityFrame_doubleframeCorners.dds")
        else
            advisedBorder:SetTexture("EsoUI/Art/SkillsAdvisor/square_abilityFrame64_doubleFrameCorners.dds")
        end 
        advisedBorder:SetHidden(false)
    else
        if isPassive then
            button:SetNormalTexture("EsoUI/Art/ActionBar/passiveAbilityFrame_round_up.dds")
            button:SetPressedTexture("EsoUI/Art/ActionBar/passiveAbilityFrame_round_up.dds")
            button:SetMouseOverTexture(nil)
            button:SetDisabledTexture("EsoUI/Art/ActionBar/passiveAbilityFrame_round_up.dds")
        else
            button:SetNormalTexture("EsoUI/Art/ActionBar/abilityFrame64_up.dds")
            button:SetPressedTexture("EsoUI/Art/ActionBar/abilityFrame64_down.dds")
            button:SetMouseOverTexture("EsoUI/Art/ActionBar/actionBar_mouseOver.dds")
            button:SetDisabledTexture("EsoUI/Art/ActionBar/abilityFrame64_up.dds")
        end

        if advisedBorder then
            advisedBorder:SetHidden(true)
        end
    end
end