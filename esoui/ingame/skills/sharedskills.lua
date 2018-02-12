local SKILL_TYPE_TO_ICONS = 
{
    [SKILL_TYPE_CLASS] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_class_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_class_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_class_over.dds",
        "EsoUI/Art/Progression/skills_announce_class.dds",
    },
    [SKILL_TYPE_WEAPON] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_weapons_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_weapons_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_weapons_over.dds",
        "EsoUI/Art/Progression/skills_announce_weapons.dds",
    },
    [SKILL_TYPE_ARMOR] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_armor_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_armor_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_armor_over.dds",
        "EsoUI/Art/Progression/skills_announce_armor.dds",
    },
    [SKILL_TYPE_WORLD] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_world_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_world_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_world_over.dds",
        "EsoUI/Art/Progression/skills_announce_world.dds",
    },
    [SKILL_TYPE_GUILD] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_guilds_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_guilds_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_guilds_over.dds",
        "EsoUI/Art/Progression/skills_announce_guilds.dds",
    },
    [SKILL_TYPE_AVA] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_AVA_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_AVA_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_AVA_over.dds",
        "EsoUI/Art/Progression/skills_announce_ava.dds",
    },
    [SKILL_TYPE_RACIAL] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_race_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_race_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_race_over.dds",
        "EsoUI/Art/Progression/skills_announce_race.dds",
    },
    [SKILL_TYPE_TRADESKILL] = 
    {
        "EsoUI/Art/Progression/progression_indexIcon_tradeskills_down.dds",
        "EsoUI/Art/Progression/progression_indexIcon_tradeskills_up.dds",
        "EsoUI/Art/Progression/progression_indexIcon_tradeskills_over.dds",
        "EsoUI/Art/Progression/skills_announce_tradeskills.dds",
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
ZO_SKILLS_NOT_ADVISED_MORPH_STATE = 3


ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE = 1
ZO_SKILL_ABILITY_DISPLAY_VIEW = 2  

ZO_SKILLS_KEYBOARD = 1
ZO_SKILLS_GAMEPAD = 2

ZO_SKILL_ABILITY_ALERT_ICON_NONE = 0
ZO_SKILL_ABILITY_ALERT_ICON_ADD = 1
ZO_SKILL_ABILITY_ALERT_ICON_MORPH = 2
ZO_SKILL_ABILITY_ALERT_ICON_BAD_MORPH = 3


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
                        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.SKILL_LINE_LEVELED_UP)
                        messageParams:SetText(zo_strformat(SI_SKILL_RANK_UP, lineName, lineRank))
                        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_SKILL_RANK_UPDATE)
                        CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
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

function ZO_Skills_GetValidatedRankIndex(rank)
    return ZO_SKILLS_ADVISOR_SINGLETON:GetValidatedRankIndex(rank)
end

do
    local GAMPAD_ALERT_TEXTURES =
    {
        [ZO_SKILLS_MORPH_STATE] = {normal = "EsoUI/Art/Progression/Gamepad/gp_morph.dds", mouseDown = "EsoUI/Art/Progression/Gamepad/gp_morph.dds", mouseover = "EsoUI/Art/Progression/Gamepad/gp_morph.dds"},
        [ZO_SKILLS_PURCHASE_STATE] = {normal = "EsoUI/Art/Progression/Gamepad/gp_purchase.dds", mouseDown = "EsoUI/Art/Progression/Gamepad/gp_purchase.dds", mouseover = "EsoUI/Art/Progression/Gamepad/gp_purchase.dds"},
        [ZO_SKILLS_NOT_ADVISED_MORPH_STATE] = {normal = "EsoUI/Art/SkillsAdvisor/gamepad/gp_bad_morph.dds"}
    }

    local KEYBOARD_ALERT_TEXTURES =
    {
        [ZO_SKILLS_MORPH_STATE] = {normal = "EsoUI/Art/Progression/morph_up.dds", mouseDown = "EsoUI/Art/Progression/morph_down.dds", mouseover = "EsoUI/Art/Progression/morph_over.dds"},
        [ZO_SKILLS_PURCHASE_STATE] = {normal = "EsoUI/Art/Progression/addPoints_up.dds", mouseDown = "EsoUI/Art/Progression/addPoints_down.dds", mouseover = "EsoUI/Art/Progression/addPoints_over.dds"},
        [ZO_SKILLS_NOT_ADVISED_MORPH_STATE] = {normal = "EsoUI/Art/SkillsAdvisor/indicator_badMorph_64.dds"}
    }

    function ZO_Skills_SetUpAbilityEntry(skillType, skillLineIndex, abilityIndex, skillBuildMorphChoice, skillBuildRankIndex, iconControl, labelControl, alertControl, lockControl, morphControl, displayView, platform)
        local ALERT_TEXTURES = platform == ZO_SKILLS_GAMEPAD and GAMPAD_ALERT_TEXTURES or KEYBOARD_ALERT_TEXTURES

        local availablePoints = GetAvailableSkillPoints()
        local _, lineRank = GetSkillLineInfo(skillType, skillLineIndex)
        local name, _, earnedRank, _, _, purchased, progressionIndex = GetSkillAbilityInfo(skillType, skillLineIndex, abilityIndex)
        local morph = nil
        if progressionIndex then
            name, morph = GetAbilityProgressionInfo(progressionIndex)
        end

        if lockControl then
            local isLocked
            if displayView == ZO_SKILL_ABILITY_DISPLAY_VIEW then
                isLocked = ZO_SKILLS_ADVISOR_SINGLETON:IsSpecificSkillAbilityLocked(skillType, skillLineIndex, abilityIndex, skillBuildMorphChoice, skillBuildRankIndex, displayView)
            else
                isLocked = ZO_SKILLS_ADVISOR_SINGLETON:IsCurrentSkillAbilityLocked(skillType, skillLineIndex, abilityIndex)
            end
            lockControl:SetHidden(not isLocked)
        end

        if alertControl then
            alertControl:SetHidden(true)
            if alertControl.ClearIcons then
                alertControl:ClearIcons()
            end
			
			if displayView == ZO_SKILL_ABILITY_DISPLAY_VIEW then
				-- Display view is used in Skills Advisor and is a view where the ability cannot be edited. 
				labelControl:SetColor(PURCHASED_COLOR:UnpackRGBA())
				
				 local currentMorphControl = morphControl or alertControl
				if currentMorphControl then
					if currentMorphControl.AddIcon then 
						ZO_Skills_SetAlertButtonTextures(currentMorphControl, ALERT_TEXTURES[ZO_SKILLS_MORPH_STATE])
					end
					currentMorphControl:SetHidden(not ZO_SKILLS_ADVISOR_SINGLETON:IsSpecificSkillAbilityMorph(skillType, skillLineIndex, abilityIndex, skillBuildMorphChoice))
				end
			else
				ZO_ActionSlot_SetUnusable(iconControl, not purchased)
				
                if platform == ZO_SKILLS_KEYBOARD then 
				    if purchased then
			            labelControl:SetColor(PURCHASED_COLOR:UnpackRGBA())
				    else
				        if lineRank >= earnedRank then
						    labelControl:SetColor(UNPURCHASED_COLOR:UnpackRGBA())
					    else 
						    labelControl:SetColor(LOCKED_COLOR:UnpackRGBA())
					    end
				    end
                end
				
                local purchaseAvailable = ZO_SKILLS_ADVISOR_SINGLETON:IsPurchaseable(skillType, skillLineIndex, abilityIndex) == ZO_SKILLS_ABILITY_PURCHASEABLE
				local morphAvailable = ZO_SKILLS_ADVISOR_SINGLETON:IsMorphAvailable(skillType, skillLineIndex, abilityIndex, skillBuildMorphChoice) == ZO_SKILLS_ABILITY_MORPH_AVAILABLE
				local upgradeAvailable = ZO_SKILLS_ADVISOR_SINGLETON:IsUpgradeAvailable(skillType, skillLineIndex, abilityIndex, skillBuildRankIndex) == ZO_SKILLS_ABILITY_UPGRADE_AVAILABLE
				if availablePoints > 0  and (purchaseAvailable or morphAvailable or upgradeAvailable) then
					if purchaseAvailable then 
						ZO_Skills_SetAlertButtonTextures(alertControl, ALERT_TEXTURES[ZO_SKILLS_PURCHASE_STATE])
						alertControl.iconStatus = ZO_SKILL_ABILITY_ALERT_ICON_ADD
                    elseif morphAvailable then
						ZO_Skills_SetAlertButtonTextures(alertControl, ALERT_TEXTURES[ZO_SKILLS_MORPH_STATE])
						alertControl.iconStatus = ZO_SKILL_ABILITY_ALERT_ICON_MORPH
					elseif upgradeAvailable then 
						ZO_Skills_SetAlertButtonTextures(alertControl, ALERT_TEXTURES[ZO_SKILLS_PURCHASE_STATE])
						alertControl.iconStatus = ZO_SKILL_ABILITY_ALERT_ICON_ADD
					end
					
					alertControl:SetHidden(platform == ZO_SKILLS_GAMEPAD)
				else
                    local NO_MORPH = 0
                    alertControl.iconStatus = ZO_SKILL_ABILITY_ALERT_ICON_NONE
                    if ZO_SKILLS_ADVISOR_SINGLETON:IsAbilityInSelectedSkillBuild(skillType, skillLineIndex, abilityIndex, NO_MORPH) then
                        if morph and morph > 0 then
                            local morphInSelectedSkillBuild = ZO_SKILLS_ADVISOR_SINGLETON:IsAbilityInSelectedSkillBuild(skillType, skillLineIndex, abilityIndex, morph)
                            local morphSiblingInSelectedSkillBuild = ZO_SKILLS_ADVISOR_SINGLETON:IsSiblingMorphInSelectedSkillBuild(skillType, skillLineIndex, abilityIndex, morph)
                            if not morphInSelectedSkillBuild and morphSiblingInSelectedSkillBuild then
                                alertControl.iconStatus = ZO_SKILL_ABILITY_ALERT_ICON_BAD_MORPH
                            end
                        end
                    end
				end
			end
        end
    end
end

function ZO_Skills_SetKeyboardAbilityButtonTextures(button, passive)
    local advisedBorder = button:GetNamedChild("AdvisedBorder")
    if ZO_SKILLS_ADVISOR_SINGLETON:IsAbilityInSelectedSkillBuild(button.skillType, button.lineIndex, button.index, button.skillBuildMorphChoice, button.skillBuildRankIndex) then
        if passive then
            button:SetNormalTexture("EsoUI/Art/SkillsAdvisor/circle_passiveAbilityFrame_doubleframe.dds")
            button:SetPressedTexture("EsoUI/Art/SkillsAdvisor/circle_passiveAbilityFrame_doubleframe_down.dds")
            button:SetMouseOverTexture(nil)
            button:SetDisabledTexture("EsoUI/Art/SkillsAdvisor/circle_passiveAbilityFrame_doubleframe.dds")
        else
            button:SetNormalTexture("EsoUI/Art/SkillsAdvisor/square_abilityFrame64_doubleFrame.dds")
            button:SetPressedTexture("EsoUI/Art/SkillsAdvisor/square_abilityFrame64_doubleFrame_down.dds")
            button:SetMouseOverTexture("EsoUI/Art/ActionBar/actionBar_mouseOver.dds")
            button:SetDisabledTexture("EsoUI/Art/SkillsAdvisor/square_abilityFrame64_doubleFrame.dds")
        end

        if passive then
            advisedBorder:SetTexture("EsoUI/Art/SkillsAdvisor/circle_passiveAbilityFrame_doubleframeCorners.dds")
        else
            advisedBorder:SetTexture("EsoUI/Art/SkillsAdvisor/square_abilityFrame64_doubleFrameCorners.dds")
        end 
        advisedBorder:SetHidden(false)
    else
        if passive then
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

function ZO_Skills_InitializeKeyboardMorphDialog()
    local dialogControl = ZO_SkillsMorphDialog
    dialogControl.desc = GetControl(dialogControl, "Description")

    dialogControl.baseAbility = GetControl(dialogControl, "BaseAbility")
    dialogControl.baseAbility.icon = GetControl(dialogControl.baseAbility, "Icon")

    dialogControl.morphAbility1 = GetControl(dialogControl, "MorphAbility1")
    dialogControl.morphAbility1.icon = GetControl(dialogControl.morphAbility1, "Icon")
    dialogControl.morphAbility1.selectedCallout = GetControl(dialogControl.morphAbility1, "SelectedCallout")
    dialogControl.morphAbility1.morph = 1
    --Hardcoded to one because we don't know how much xp the morph has until we own it
    dialogControl.morphAbility1.rank = 1
    dialogControl.morphAbility1.advised = false

    dialogControl.morphAbility2 = GetControl(dialogControl, "MorphAbility2")
    dialogControl.morphAbility2.icon = GetControl(dialogControl.morphAbility2, "Icon")
    dialogControl.morphAbility2.selectedCallout = GetControl(dialogControl.morphAbility2, "SelectedCallout")
    dialogControl.morphAbility2.morph = 2
    --Hardcoded to one because we don't know how much xp the morph has until we own it
    dialogControl.morphAbility2.rank = 1
    dialogControl.morphAbility2.advised = false

    dialogControl.trackArrows = GetControl(dialogControl, "Track")

    dialogControl.confirmButton = GetControl(dialogControl, "Confirm")

    local function SetupMorphAbilityConfirmDialog(dialog, abilityControl)
        if abilityControl.ability.atMorph then
            local ability = abilityControl.ability
            local slot = abilityControl.ability.slot
            local name = ability.name
            local icon = slot.iconFile

            -- The dialog was shown from the skill advisor list which has what we morph to. This dialog needs the unmorphed version.
            if ability.skillBuildMorphChoice and ability.skillBuildMorphChoice > 0 then
                local UNMORPHED = 0
                local abilityId = GetSpecificSkillAbilityInfo(abilityControl.skillType, abilityControl.lineIndex, abilityControl.index, UNMORPHED)
                name = GetAbilityName(abilityId)
                icon = GetAbilityIcon(abilityId)
            end

            dialog.desc:SetText(zo_strformat(SI_SKILLS_SELECT_MORPH, name))

            local baseAbility = dialog.baseAbility
            baseAbility.skillType = abilityControl.skillType
            baseAbility.lineIndex = abilityControl.lineIndex
            baseAbility.index = abilityControl.index
            baseAbility.icon:SetTexture(icon)
            ZO_Skills_SetKeyboardAbilityButtonTextures(baseAbility) 

            local morphAbility1 = dialog.morphAbility1
            local _, morph1Icon = GetAbilityProgressionAbilityInfo(ability.progressionIndex, morphAbility1.morph, morphAbility1.rank)
            morphAbility1.progressionIndex = ability.progressionIndex
            morphAbility1.icon:SetTexture(morph1Icon)
            morphAbility1.selectedCallout:SetHidden(true)
            ZO_ActionSlot_SetUnusable(morphAbility1.icon, false)

            morphAbility1.skillType = baseAbility.skillType
            morphAbility1.lineIndex = baseAbility.lineIndex
            morphAbility1.index = baseAbility.index
            morphAbility1.skillBuildMorphChoice = 1
            ZO_Skills_SetKeyboardAbilityButtonTextures(morphAbility1) 
            morphAbility1.showAdvice = true
            morphAbility1.advised = ZO_SKILLS_ADVISOR_SINGLETON:IsAbilityInSelectedSkillBuild(morphAbility1.skillType, morphAbility1.lineIndex, morphAbility1.index, morphAbility1.skillBuildMorphChoice)

            local morphAbility2 = dialog.morphAbility2
            local _, morph2Icon = GetAbilityProgressionAbilityInfo(ability.progressionIndex, morphAbility2.morph, morphAbility2.rank)
            morphAbility2.progressionIndex = ability.progressionIndex
            morphAbility2.icon:SetTexture(morph2Icon)
            morphAbility2.selectedCallout:SetHidden(true)
            ZO_ActionSlot_SetUnusable(morphAbility2.icon, false)

            morphAbility2.skillType = baseAbility.skillType
            morphAbility2.lineIndex = baseAbility.lineIndex
            morphAbility2.index = baseAbility.index
            morphAbility2.skillBuildMorphChoice = 2
            ZO_Skills_SetKeyboardAbilityButtonTextures(morphAbility2) 
            morphAbility2.showAdvice = true
            morphAbility2.advised = ZO_SKILLS_ADVISOR_SINGLETON:IsAbilityInSelectedSkillBuild(morphAbility2.skillType, morphAbility2.lineIndex, morphAbility2.index, morphAbility2.skillBuildMorphChoice)

            dialog.confirmButton:SetState(BSTATE_DISABLED)

            if morphAbility1.advised and not morphAbility2.advised then
                dialogControl.trackArrows:SetTexture("EsoUI/Art/SkillsAdvisor/morph_graphic_TOP.dds")
            elseif morphAbility2.advised and not morphAbility1.advised then
                dialogControl.trackArrows:SetTexture("EsoUI/Art/SkillsAdvisor/morph_graphic_BOTTOM.dds")
            else
                dialogControl.trackArrows:SetTexture("EsoUI/Art/Progression/morph_graphic.dds")
                morphAbility1.showAdvice = false
                morphAbility2.showAdvice = false
            end

            dialog.chosenMorphProgressionIndex = nil
            dialog.chosenMorph = nil
        end
    end

    ZO_Dialogs_RegisterCustomDialog("MORPH_ABILITY_CONFIRM",
    {
        customControl = dialogControl,
        setup = SetupMorphAbilityConfirmDialog,
        title =
        {
            text = SI_SKILLS_MORPH_ABILITY,
        },
        buttons =
        {
            [1] =
            {
                control = GetControl(dialogControl, "Confirm"),
                text =  SI_SKILLS_MORPH_CONFIRM,
                callback =  function(dialog)
                                if dialog.chosenMorphProgressionIndex and dialog.chosenMorph then
                                    ZO_Skills_MorphAbility(dialog.chosenMorphProgressionIndex, dialog.chosenMorph)
                                end
                            end,
            },
        
            [2] =
            {
                control =   GetControl(dialogControl, "Cancel"),
                text =      SI_CANCEL,
            }
        }
    })
end

function ZO_Skills_InitializeKeyboardConfirmDialog()
    local confirmDialogControl = ZO_SkillsConfirmDialog
    confirmDialogControl.abilityName = confirmDialogControl:GetNamedChild("AbilityName")
    confirmDialogControl.ability = confirmDialogControl:GetNamedChild("Ability")
    confirmDialogControl.ability.icon = confirmDialogControl.ability:GetNamedChild("Icon")
    confirmDialogControl.advisement = confirmDialogControl:GetNamedChild("Advisement")

    local function SetupPurchaseAbilityConfirmDialog(dialog, abilityControl)
        local ability = abilityControl.ability
        local slot = abilityControl.ability.slot
        local dialogAbility = dialog.ability

        ZO_Skills_SetKeyboardAbilityButtonTextures(dialogAbility, ability.passive)

        dialog.abilityName:SetText(ability.plainName)

        --Active abilities don't care about rank index for skill builds. Passives do.
        dialogAbility.skillBuildRankIndex = 1
        if ability.passive then
            local _, _, skillUnlockedAtSkillLineRank = GetSkillAbilityNextUpgradeInfo(abilityControl.skillType, abilityControl.lineIndex, abilityControl.index)
            --skillUnlockedAtSkillLineRank will only be filled out if we own the ability. If we don't own it we stick with rank index 1.
            if skillUnlockedAtSkillLineRank then
                dialogAbility.skillBuildRankIndex = GetUpgradeSkillHighestRankIndexAvailableAtSkillLineRank(abilityControl.skillType, abilityControl.lineIndex, abilityControl.index, skillUnlockedAtSkillLineRank)
            end
        end

        dialogAbility.skillType = abilityControl.skillType
        dialogAbility.lineIndex = abilityControl.lineIndex
        dialogAbility.index = abilityControl.index
        dialogAbility.icon:SetTexture(slot.iconFile)
        ZO_Skills_SetKeyboardAbilityButtonTextures(dialogAbility, ability.passive) 

        dialog.chosenSkillType = abilityControl.skillType
        dialog.chosenLineIndex = abilityControl.lineIndex
        dialog.chosenAbilityIndex = abilityControl.index

        if not ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() then
            if ZO_SKILLS_ADVISOR_SINGLETON:IsAbilityInSelectedSkillBuild(abilityControl.skillType, abilityControl.lineIndex, abilityControl.index) then
                dialog.advisement:SetText(GetString(SI_SKILLS_ADVISOR_PURCHASE_ADVISED))
                dialog.advisement:SetColor(ZO_SKILLS_ADVISOR_ADVISED_COLOR:UnpackRGBA())
                dialog.advisement:SetHidden(false)
            else
                dialog.advisement:SetHidden(true)
            end   
        end
    end

    ZO_Dialogs_RegisterCustomDialog("PURCHASE_ABILITY_CONFIRM",
    {
        customControl = confirmDialogControl,
        setup = SetupPurchaseAbilityConfirmDialog,
        title =
        {
            text = SI_SKILLS_CONFIRM_PURCHASE_ABILITY,
        },
        buttons =
        {
            [1] =
            {
                control =   GetControl(confirmDialogControl, "Confirm"),
                text =      SI_SKILLS_UNLOCK_CONFIRM,
                callback =  function(dialog)
                                if dialog.chosenSkillType and dialog.chosenLineIndex and dialog.chosenAbilityIndex then
                                    ZO_Skills_PurchaseAbility(dialog.chosenSkillType, dialog.chosenLineIndex, dialog.chosenAbilityIndex)
                                end
                            end,
            },
        
            [2] =
            {
                control =   GetControl(confirmDialogControl, "Cancel"),
                text =      SI_CANCEL,
            }
        }
    })
end

function  ZO_Skills_InitializeKeyboardUpgradeDialog()
    local upgradeDialogControl = GetControl("ZO_SkillsUpgradeDialog")
    upgradeDialogControl.desc = upgradeDialogControl:GetNamedChild("Description")

    upgradeDialogControl.baseAbility = upgradeDialogControl:GetNamedChild("BaseAbility")
    upgradeDialogControl.baseAbility.icon = upgradeDialogControl.baseAbility:GetNamedChild("Icon")

    upgradeDialogControl.upgradeAbility = upgradeDialogControl:GetNamedChild("UpgradeAbility")
    upgradeDialogControl.upgradeAbility.icon = upgradeDialogControl.upgradeAbility:GetNamedChild("Icon")

    upgradeDialogControl.advisement = upgradeDialogControl:GetNamedChild("Advisement")

    local function SetupUpgradeAbilityDialog(dialog, abilityControl)
        --Only passives upgrade

        local ability = abilityControl.ability
        local slot = abilityControl.ability.slot

        dialog.desc:SetText(zo_strformat(SI_SKILLS_UPGRADE_DESCRIPTION, ability.plainName))

        local baseAbility = dialog.baseAbility
        local upgradeAbility = dialog.upgradeAbility

        ZO_Skills_SetKeyboardAbilityButtonTextures(baseAbility, ability.passive)
        ZO_Skills_SetKeyboardAbilityButtonTextures(upgradeAbility, ability.passive)

        baseAbility.skillType = abilityControl.skillType
        baseAbility.lineIndex = abilityControl.lineIndex
        baseAbility.index = abilityControl.index
        baseAbility.icon:SetTexture(slot.iconFile)
        ZO_Skills_SetKeyboardAbilityButtonTextures(baseAbility, true) 

        local _, upgradeIcon, skillUnlockedAtSkillLineRank = GetSkillAbilityNextUpgradeInfo(abilityControl.skillType, abilityControl.lineIndex, abilityControl.index)
        --skillUnlockedAtSkillLineRank will only be filled out if we own the ability. If we don't own it we stick with rank index 1.
        if skillUnlockedAtSkillLineRank then
            upgradeAbility.skillBuildRankIndex = GetUpgradeSkillHighestRankIndexAvailableAtSkillLineRank(abilityControl.skillType, abilityControl.lineIndex, abilityControl.index, skillUnlockedAtSkillLineRank)
        else
            upgradeAbility.skillBuildRankIndex = 1
        end

        upgradeAbility.skillType = abilityControl.skillType
        upgradeAbility.lineIndex = abilityControl.lineIndex
        upgradeAbility.index = abilityControl.index
        upgradeAbility.icon:SetTexture(upgradeIcon)
        ZO_Skills_SetKeyboardAbilityButtonTextures(upgradeAbility, true) 

        dialog.chosenSkillType = abilityControl.skillType
        dialog.chosenLineIndex = abilityControl.lineIndex
        dialog.chosenAbilityIndex = abilityControl.index

        if not ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() then
            if ZO_SKILLS_ADVISOR_SINGLETON:IsAbilityInSelectedSkillBuild(upgradeAbility.skillType, upgradeAbility.lineIndex, upgradeAbility.index) then
                dialog.advisement:SetText(GetString(SI_SKILLS_ADVISOR_PURCHASE_ADVISED))
                dialog.advisement:SetColor(ZO_SKILLS_ADVISOR_ADVISED_COLOR:UnpackRGBA())
                dialog.advisement:SetHidden(false)
            else
                dialog.advisement:SetHidden(true)
            end   
        end
    end

    ZO_Dialogs_RegisterCustomDialog("UPGRADE_ABILITY_CONFIRM",
    {
        customControl = upgradeDialogControl,
        setup = SetupUpgradeAbilityDialog,
        title =
        {
            text = SI_SKILLS_UPGRADE_ABILITY,
        },
        buttons =
        {
            [1] =
            {
                control = GetControl(upgradeDialogControl, "Confirm"),
                text =  SI_SKILLS_UPGRADE_CONFIRM,
                callback =  function(dialog)
                                if dialog.chosenSkillType and dialog.chosenLineIndex and dialog.chosenAbilityIndex then
                                    ZO_Skills_UpgradeAbility(dialog.chosenSkillType, dialog.chosenLineIndex, dialog.chosenAbilityIndex)
                                end
                            end,
            },
            [2] =
            {
                control =   GetControl(upgradeDialogControl, "Cancel"),
                text =      SI_CANCEL,
            }
        }
    })
end