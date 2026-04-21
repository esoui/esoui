local isSubclassingMousedOver = false

-- Point Allocation Dialogs --

local function InitializeKeyboardMorphDialog()
    local dialogControl = ZO_SkillsMorphDialog
    dialogControl.desc = dialogControl:GetNamedChild("Description")

    local baseAbility = dialogControl:GetNamedChild("BaseAbility")
    baseAbility.icon = baseAbility:GetNamedChild("Icon")
    --Hardcoded to four to hide the XP bar: this ability should always be max rank, so no need to show it.
    baseAbility.overrideRank = 4
    dialogControl.baseAbility = baseAbility

    local morphAbility1 = dialogControl:GetNamedChild("MorphAbility1")
    morphAbility1.icon = morphAbility1:GetNamedChild("Icon")
    morphAbility1.selectedCallout = morphAbility1:GetNamedChild("SelectedCallout")
    morphAbility1.advised = false
    dialogControl.morphAbility1 = morphAbility1

    local morphAbility2 = dialogControl:GetNamedChild("MorphAbility2")
    morphAbility2.icon = morphAbility2:GetNamedChild("Icon")
    morphAbility2.selectedCallout = morphAbility2:GetNamedChild("SelectedCallout")
    morphAbility2.advised = false
    dialogControl.morphAbility2 = morphAbility2

    dialogControl.warning = dialogControl:GetNamedChild("Warning")
    dialogControl.trackArrows = dialogControl:GetNamedChild("Track")
    dialogControl.confirmButton = dialogControl:GetNamedChild("Confirm")

    local function ClearMorphChoice()
        morphAbility1.selectedCallout:SetHidden(true)
        morphAbility2.selectedCallout:SetHidden(true)

        ZO_ActionSlot_SetUnusable(morphAbility1.icon, false)
        ZO_ActionSlot_SetUnusable(morphAbility2.icon, false)

        dialogControl.confirmButton:SetState(BSTATE_DISABLED)
        dialogControl.chosenMorphProgressionData = nil
    end

    local function ChooseMorph(morphSlot)
        local otherMorphSlot = morphSlot == morphAbility1 and morphAbility2 or morphAbility1

        morphSlot.selectedCallout:SetHidden(false)
        otherMorphSlot.selectedCallout:SetHidden(true)

        ZO_ActionSlot_SetUnusable(morphSlot.icon, false)
        ZO_ActionSlot_SetUnusable(otherMorphSlot.icon, true)

        dialogControl.confirmButton:SetState(BSTATE_NORMAL)
        dialogControl.chosenMorphProgressionData = morphSlot.skillProgressionData
    end

    local function ConfirmWhenBatchSaving()
        if dialogControl.chosenMorphProgressionData and SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
            local skillPointAllocator = dialogControl.chosenMorphProgressionData:GetSkillData():GetPointAllocator()
            skillPointAllocator:Morph(dialogControl.chosenMorphProgressionData:GetMorphSlot())
            local RELEASED_FROM_BUTTON_PRESS = true
            ZO_Dialogs_ReleaseDialog(dialogControl, RELEASED_FROM_BUTTON_PRESS)
        end
    end

    morphAbility1:SetHandler("OnClicked", ChooseMorph)
    morphAbility1:SetHandler("OnMouseDoubleClick", ConfirmWhenBatchSaving)
    morphAbility2:SetHandler("OnClicked", ChooseMorph)
    morphAbility2:SetHandler("OnMouseDoubleClick", ConfirmWhenBatchSaving)

    local function SetupMorphAbilityConfirmDialog(dialog, skillData)
        -- Passives cannot be morphed
        assert(not skillData:IsPassive())
        local skillPointAllocator = skillData:GetPointAllocator()
        if skillPointAllocator:CanMorph() then
            local baseProgressionData = skillData:GetMorphData(MORPH_SLOT_BASE)
            local morph1ProgressionData = skillData:GetMorphData(MORPH_SLOT_MORPH_1)
            local morph2ProgressionData = skillData:GetMorphData(MORPH_SLOT_MORPH_2)

            dialog.desc:SetText(zo_strformat(SI_SKILLS_SELECT_MORPH, baseProgressionData:GetName()))

            baseAbility.skillProgressionData = baseProgressionData
            baseAbility.icon:SetTexture(baseProgressionData:GetIcon())
            ZO_Skills_SetKeyboardAbilityButtonTextures(baseAbility)

            morphAbility1.skillProgressionData = morph1ProgressionData
            morphAbility1.icon:SetTexture(morph1ProgressionData:GetIcon())
            ZO_Skills_SetKeyboardAbilityButtonTextures(morphAbility1) 
            morphAbility1.showAdvice = true
            morphAbility1.advised = ZO_SKILLS_ADVISOR_SINGLETON:IsSkillProgressionDataInSelectedBuild(morph1ProgressionData)

            morphAbility2.skillProgressionData = morph2ProgressionData
            morphAbility2.icon:SetTexture(morph2ProgressionData:GetIcon())
            ZO_Skills_SetKeyboardAbilityButtonTextures(morphAbility2)
            morphAbility2.showAdvice = true
            morphAbility2.advised = ZO_SKILLS_ADVISOR_SINGLETON:IsSkillProgressionDataInSelectedBuild(morph2ProgressionData)

            if skillPointAllocator:GetMorphSlot() == MORPH_SLOT_BASE then
                ClearMorphChoice()
            elseif skillPointAllocator:GetMorphSlot() == MORPH_SLOT_MORPH_1 then
                ChooseMorph(morphAbility1)
            else
                ChooseMorph(morphAbility2)
            end

            if morphAbility1.advised and not morphAbility2.advised then
                dialogControl.trackArrows:SetTexture("EsoUI/Art/SkillsAdvisor/morph_graphic_TOP.dds")
            elseif morphAbility2.advised and not morphAbility1.advised then
                dialogControl.trackArrows:SetTexture("EsoUI/Art/SkillsAdvisor/morph_graphic_BOTTOM.dds")
            else
                dialogControl.trackArrows:SetTexture("EsoUI/Art/Progression/morph_graphic.dds")
                morphAbility1.showAdvice = false
                morphAbility2.showAdvice = false
            end

            local skillLineData = skillData:GetSkillLineData()
            if skillLineData:IsClassMastery() then
                dialog.warning:SetText(zo_strformat(SI_SKILLS_CLASS_MASTERY_COST, skillLineData:GetClassMasteryCost()))
            else
                dialog.warning:SetText(zo_strformat(SI_SKILLS_IMPROVEMENT_COST, skillData:GetSkillPointCostMultiplier()))
            end
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
            {
                control = dialogControl:GetNamedChild("Confirm"),
                text =  SI_SKILLS_MORPH_CONFIRM,
                callback = function(dialog)
                    if dialog.chosenMorphProgressionData then
                        local skillPointAllocator = dialog.chosenMorphProgressionData:GetSkillData():GetPointAllocator()
                        skillPointAllocator:Morph(dialog.chosenMorphProgressionData:GetMorphSlot())
                    end
                end,
            },
            {
                control = dialogControl:GetNamedChild("Cancel"),
                text = SI_CANCEL,
            }
        }
    })
end

local function InitializeKeyboardConfirmDialog()
    local confirmDialogControl = ZO_SkillsConfirmDialog
    confirmDialogControl.abilityName = confirmDialogControl:GetNamedChild("AbilityName")
    confirmDialogControl.ability = confirmDialogControl:GetNamedChild("Ability")
    confirmDialogControl.ability.icon = confirmDialogControl.ability:GetNamedChild("Icon")
    confirmDialogControl.warning = confirmDialogControl:GetNamedChild("Warning")
    local advisementLabel = confirmDialogControl:GetNamedChild("Advisement")
    advisementLabel:SetText(GetString(SI_SKILLS_ADVISOR_PURCHASE_ADVISED))
    advisementLabel:SetColor(ZO_SKILLS_ADVISOR_ADVISED_COLOR:UnpackRGBA())
    confirmDialogControl.advisementLabel = advisementLabel

    local function SetupPurchaseAbilityConfirmDialog(dialog, skillProgressionData)
        local skillData = skillProgressionData:GetSkillData()
        if skillData:GetPointAllocator():CanPurchase() then
            local dialogAbility = dialog.ability
            dialog.abilityName:SetText(skillProgressionData:GetFormattedName())

            dialogAbility.skillProgressionData = skillProgressionData
            dialogAbility.icon:SetTexture(skillProgressionData:GetIcon())
            ZO_Skills_SetKeyboardAbilityButtonTextures(dialogAbility)

            local skillLineData = skillData:GetSkillLineData()
            if skillLineData:IsClassMastery() then
                dialog.warning:SetText(zo_strformat(SI_SKILLS_CLASS_MASTERY_COST, skillLineData:GetClassMasteryCost()))
            else
                dialog.warning:SetText(zo_strformat(SI_SKILLS_IMPROVEMENT_COST, skillData:GetSkillPointCostMultiplier()))
            end

            local hideAdvisement = (not ZO_SKILLS_ADVISOR_SINGLETON:CanUseSkillsAdvisor()) or ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() or (not skillProgressionData:IsAdvised())
            dialog.advisementLabel:SetHidden(hideAdvisement)
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
            {
                control = confirmDialogControl:GetNamedChild("Confirm"),
                text = SI_SKILLS_UNLOCK_CONFIRM,
                callback = function(dialog)
                    local skillProgressionData = dialog.data
                    local skillPointAllocator = skillProgressionData:GetSkillData():GetPointAllocator()
                    skillPointAllocator:Purchase()
                end,
            },
            {
                control = confirmDialogControl:GetNamedChild("Cancel"),
                text = SI_CANCEL,
            }
        }
    })
end

local function InitializeKeyboardUpgradeDialog()
    local upgradeDialogControl = ZO_SkillsUpgradeDialog
    upgradeDialogControl.desc = upgradeDialogControl:GetNamedChild("Description")

    upgradeDialogControl.baseAbility = upgradeDialogControl:GetNamedChild("BaseAbility")
    upgradeDialogControl.baseAbility.icon = upgradeDialogControl.baseAbility:GetNamedChild("Icon")

    upgradeDialogControl.upgradeAbility = upgradeDialogControl:GetNamedChild("UpgradeAbility")
    upgradeDialogControl.upgradeAbility.icon = upgradeDialogControl.upgradeAbility:GetNamedChild("Icon")

    upgradeDialogControl.warning = upgradeDialogControl:GetNamedChild("Warning")

    local advisementLabel = upgradeDialogControl:GetNamedChild("Advisement")
    advisementLabel:SetText(GetString(SI_SKILLS_ADVISOR_PURCHASE_ADVISED))
    advisementLabel:SetColor(ZO_SKILLS_ADVISOR_ADVISED_COLOR:UnpackRGBA())

    local function SetupUpgradeAbilityDialog(dialog, skillData)
        --Only passives upgrade
        assert(skillData:IsPassive())

        local skillPointAllocator = skillData:GetPointAllocator()
        if skillPointAllocator:CanIncreaseRank() then
            local rank = skillPointAllocator:GetSkillProgressionKey()
            local skillProgressionData = skillData:GetRankData(rank)
            local nextSkillProgressionData = skillData:GetRankData(rank + 1)

            dialog.desc:SetText(zo_strformat(SI_SKILLS_UPGRADE_DESCRIPTION, skillProgressionData:GetName()))

            local baseAbility = dialog.baseAbility
            baseAbility.skillProgressionData = skillProgressionData
            baseAbility.icon:SetTexture(skillProgressionData:GetIcon())
            ZO_Skills_SetKeyboardAbilityButtonTextures(baseAbility)

            local upgradeAbility = dialog.upgradeAbility
            upgradeAbility.skillProgressionData = nextSkillProgressionData
            upgradeAbility.icon:SetTexture(nextSkillProgressionData:GetIcon())
            ZO_Skills_SetKeyboardAbilityButtonTextures(upgradeAbility)

            local skillLineData = skillData:GetSkillLineData()
            if skillLineData:IsClassMastery() then
                dialog.warning:SetText(zo_strformat(SI_SKILLS_CLASS_MASTERY_COST, skillLineData:GetClassMasteryCost()))
            else
                dialog.warning:SetText(zo_strformat(SI_SKILLS_IMPROVEMENT_COST, skillData:GetSkillPointCostMultiplier()))
            end

            local hideAdvisement = (not ZO_SKILLS_ADVISOR_SINGLETON:CanUseSkillsAdvisor()) or ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() or (not skillProgressionData:IsAdvised())
            advisementLabel:SetHidden(hideAdvisement)
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
            {
                control = upgradeDialogControl:GetNamedChild("Confirm"),
                text = SI_SKILLS_UPGRADE_CONFIRM,
                callback = function(dialog)
                    local skillData = dialog.data
                    local skillPointAllocator = skillData:GetPointAllocator()
                    skillPointAllocator:IncreaseRank()
                end,
            },
            {
                control = upgradeDialogControl:GetNamedChild("Cancel"),
                text = SI_CANCEL,
            }
        }
    })
end

function ZO_InitializeKeyboardSkillRespecCastDialog(control)
    control.bar = control:GetNamedChild("ContentContainerProgress")

    local function SetupRespecCastDialog(dialog)
        ZO_StatusBar_SetGradientColor(dialog.bar, ZO_XP_BAR_GRADIENT_COLORS)
        dialog.bar:SetMinMax(0, RESPEC_CAST_TIME_MS)
        dialog.bar:SetValue(0)
    end

    ZO_Dialogs_RegisterCustomDialog("SKILL_RESPEC_CAST_KEYBOARD",
    {
        customControl = control,
        setup = SetupRespecCastDialog,
        title =
        {
            text = GetString(SI_SKILL_RESPEC_START_RESPEC_KEYBIND),
        },
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                control = control:GetNamedChild("Cancel"),
                text = SI_DIALOG_CANCEL,
                sound = SOUNDS.DIALOG_DECLINE,
                callback = function()
                    CancelSkillPointAllocationRequest()
                end,
            },
        },
        updateFn = function(dialog)
            local progress = RESPEC_CAST_TIME_MS - GetSkillRespecCastTimeRemainingMs()
            dialog.bar:SetValue(progress)
        end,
        noChoiceCallback = function(dialog)
            CancelSkillPointAllocationRequest()
        end,
    })
end

function ZO_InitializeKeyboardSkillRespecConfirmationGoldDialog(control)
    local function SetupRespecConfirmationGoldDialog()
        local balance = GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
        local cost = GetSkillRespecCost(SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode())
        local showCost = cost > 0

        local balanceControl = control:GetNamedChild("Balance")
        local balanceHeaderControl = control:GetNamedChild("BalanceHeader")
        ZO_CurrencyControl_SetSimpleCurrency(balanceControl, CURT_MONEY, balance, CURRENCY_OPTIONS)
        balanceControl:SetHidden(not showCost)
        balanceHeaderControl:SetHidden(not showCost)

        local costControl = control:GetNamedChild("Cost")
        local costHeaderControl = control:GetNamedChild("CostHeader")
        ZO_CurrencyControl_SetSimpleCurrency(costControl, CURT_MONEY, cost, CURRENCY_OPTIONS)
        costControl:SetHidden(not showCost)
        costHeaderControl:SetHidden(not showCost)
    end

    ZO_Dialogs_RegisterCustomDialog("SKILL_RESPEC_CONFIRM_GOLD_KEYBOARD",
    {
        customControl = control,
        setup = SetupRespecConfirmationGoldDialog,
        title =
        {
            text = SI_SKILL_RESPEC_CONFIRM_DIALOG_TITLE,
        },
        mainText =
        {
            text = function(dialog)
                local mainTextEntryTable = ZO_Dialogs_GetSkillsRespecMainTextEntryTable()
                return ZO_GenerateParagraphSeparatedList(mainTextEntryTable)
            end,
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                control = control:GetNamedChild("Confirm"),
                text = SI_DIALOG_CONFIRM,
                callback =  function()
                    SKILLS_AND_ACTION_BAR_MANAGER:ApplyChanges()
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                control = control:GetNamedChild("Cancel"),
                text = SI_DIALOG_CANCEL,
            },
        }
    })
end

local function InitializeKeyboardSkillRespecConfirmClearDialog()
    local control = ZO_SkillRespecConfirmClearDialog

    -- Radio buttons
    local skillLineRadioButton = control:GetNamedChild("SkillLineRadioButton")
    local skillLineRadioButtonLabel = skillLineRadioButton:GetNamedChild("Label")
    local allRadioButton = control:GetNamedChild("AllRadioButton")
    local radioButtonGroup = ZO_RadioButtonGroup:New()
    radioButtonGroup:Add(skillLineRadioButton)
    radioButtonGroup:Add(allRadioButton)

    control.radioButtonGroup = radioButtonGroup

    local function SetupSkillRespecConfirmClear(dialog, skillLineData)
        skillLineRadioButton.skillLineData = skillLineData
        skillLineRadioButtonLabel:SetText(skillLineData:GetFormattedName())
        radioButtonGroup:SetClickedButton(skillLineRadioButton)
    end

    ZO_Dialogs_RegisterCustomDialog("SKILL_RESPEC_CONFIRM_CLEAR_ALL_KEYBOARD",
    {
        customControl = control,
        setup = SetupSkillRespecConfirmClear,
        title =
        {
            text = function()
                return GetString("SI_SKILLPOINTALLOCATIONMODE_CLEARKEYBIND", SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode())
            end,
        },
        mainText =
        {
            text = function()
                return GetString("SI_SKILLPOINTALLOCATIONMODE_CLEARCHOICEHEADERKEYBOARD", SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode())
            end
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                control = control:GetNamedChild("Confirm"),
                text = SI_DIALOG_CONFIRM,
                callback = function()
                    local selectedButton = radioButtonGroup:GetClickedButton()
                    if selectedButton.skillLineData then
                        SKILL_POINT_ALLOCATION_MANAGER:ClearPointsOnSkillLine(selectedButton.skillLineData)
                    else
                        SKILL_POINT_ALLOCATION_MANAGER:ClearPointsOnAllSkillLines()
                    end
                    PlaySound(SOUNDS.SKILL_RESPEC_CLEAR_ALL)
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                control = control:GetNamedChild("Cancel"),
                text = SI_DIALOG_CANCEL,
            },
        },
    })
end

function ZO_SelectSkillStyleDialog_OnInitialized(control)
    control.selectSkillStyleContainerControl = control:GetNamedChild("SkillStyleContainer")
    control.selectSkillStyleGridListControl = control.selectSkillStyleContainerControl:GetNamedChild("Panel")
    control.defaultStyleButton = control:GetNamedChild("DefaultStyle")
    control.defaultStyleBorder = control:GetNamedChild("DefaultSelectedBorder")
    control.skillStylesLabel = control:GetNamedChild("SkillStylesLabel")
    control.notPurchasedLabel = control:GetNamedChild("NotPurchasedLabel")

    local function OnDefaultStyleMouseUp()
        control.skillStyleSelector:TryClearSelection()
    end

    control.defaultStyleButton:SetHandler("OnMouseUp", OnDefaultStyleMouseUp)

    local function OnSkillStyleIconSelected(newIconIndex)
        control.defaultStyleBorder:SetHidden(newIconIndex ~= nil)
    end

    control.skillStyleSelector = ZO_SkillStyleIconSelector_Keyboard:New(control.selectSkillStyleGridListControl)
    control.skillStyleSelector:SetSkillStyleIconSelectedCallback(OnSkillStyleIconSelected)

    local function SetupSelectSkillStyleDialog(dialog, data)
        control.skillStyleSelector:SetSkillData(data.skillData)
        control.skillStyleSelector:BuildSkillStyleSelectorIconGridList()
        control.defaultStyleBorder:SetHidden(dialog.skillStyleSelector:GetActiveData() ~= nil)

        local purchaseText = SKILLS_DATA_MANAGER:GetSkillStyleWarningText(data)
        if purchaseText == "" then
            control.selectSkillStyleContainerControl:ClearAnchors()
            control.selectSkillStyleContainerControl:SetAnchor(TOP, control.skillStylesLabel, BOTTOM, 0, 5)
            control.notPurchasedLabel:SetHidden(true)
        else
            control.selectSkillStyleContainerControl:ClearAnchors()
            control.selectSkillStyleContainerControl:SetAnchor(TOP, control.notPurchasedLabel, BOTTOM, 0, 5)
            control.notPurchasedLabel:SetHidden(false)
            control.notPurchasedLabel:SetText(purchaseText)
        end
    end

    ZO_Dialogs_RegisterCustomDialog("SKILL_STYLE_SELECT_KEYBOARD",
    {
        customControl = control,
        setup = SetupSelectSkillStyleDialog,
        title =
        {
            text = function(dialog)
                local data = dialog.data
                local skillType = data.skillData.skillLineData.skillTypeData.skillType
                local skillLineIndex = data.skillData.skillLineData.skillLineIndex
                local skillIndex = data.skillData.skillIndex
                return zo_strformat(SI_SKILL_STYLING_DIALOG_TITLE, GetProgressionSkillProgressionName(skillType, skillLineIndex, skillIndex))
            end,
        },
        mainText =
        {
            text = "",
        },
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                control = control:GetNamedChild("Close"),
                text = SI_DIALOG_CLOSE,
                callback = function(dialog)
                    ClearTooltip(ItemTooltip)
                end,
            },
        }
    })
end

-- Skill Manager
--------------------

local SKILL_ABILITY_DATA = 1
local SKILL_HEADER_DATA = 2

ZO_SkillsManager = ZO_InitializingCallbackObject:Subclass()

function ZO_SkillsManager:Initialize(control)
    self.control = control

    SKILLS_FRAGMENT = ZO_FadeSceneFragment:New(control)
    KEYBOARD_SKILLS_SCENE = ZO_InteractScene:New("skills", SCENE_MANAGER, ZO_SKILL_RESPEC_INTERACT_INFO)

    self.showAdvisorInAdvancedMode = false

    self:InitializeControls()
    self:InitializeSkillLineList()
    self:InitializeSkillList()
    self:InitializeSubclassing()
    self:InitializeKeybindDescriptors()

    InitializeKeyboardMorphDialog()
    InitializeKeyboardConfirmDialog()
    InitializeKeyboardUpgradeDialog()
    InitializeKeyboardSkillRespecConfirmClearDialog()

    self:RegisterForEvents()
end

function ZO_SkillsManager:InitializeControls()
    local control = self.control

    self.availablePointsLabel = control:GetNamedChild("AvailablePoints")
    self.skyShardsLabel = control:GetNamedChild("SkyShards")
    self.advisedOverlay = ZO_Skills_SkillLineAdvisedOverlay:New(control:GetNamedChild("SkillLineAdvisedOverlay"))
    self.skillInfo = control:GetNamedChild("SkillInfo")
    self.classMasteryLabel = control:GetNamedChild("ClassMasteryPoints")
    self.assignableActionBar = ZO_KeyboardAssignableActionBar:New(control:GetNamedChild("AssignableActionBar"))
end

function ZO_SkillsManager:InitializeSkillLineList()
    self.skillLinesContainer = self.control:GetNamedChild("SkillLinesContainer")
    local skillLinesTree = ZO_Tree:New(self.skillLinesContainer:GetNamedChild("ScrollChild"), 74, -10, 300)
    self.skillLineIdToNode = {}

    local function TreeHeaderSetup(node, control, skillTypeData, open)
        control.skillTypeData = skillTypeData
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(skillTypeData:GetName())
        local up, down, over = skillTypeData:GetKeyboardIcons()

        control.icon:SetTexture(open and down or up)
        control.iconHighlight:SetTexture(over)

        control.statusIcon:ClearIcons()

        if skillTypeData:AreAnySkillLinesOrAbilitiesNew() then
            control.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end

        control.statusIcon:Show()

        ZO_IconHeader_Setup(control, open)
    end

    skillLinesTree:AddTemplate("ZO_SkillIconHeader", TreeHeaderSetup, nil, nil, nil, 0)

    local function TreeEntrySetup(node, control, skillLineData, open)
        -- ESO-910632 Addresses an issue where a node gets removed when closing the screen but never fires the unselect callback
        -- so the control still appears selected when it gets recycled
        control:SetSelected(node.selected)

        if skillLineData.isSubclassingNode == true then
            control:SetText(GetString(SI_SKILLS_SUBCLASSING_ENTRY_NAME))
            control.statusIcon:ClearIcons()
            if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeAllowAccessToSubclassing() then
                node:SetEnabled(true)
                node.control:SetEnabled(true)
            else
                node:SetEnabled(false)
                node.control:SetEnabled(false)
            end

            local OnMouseEnter = function(control)
                ZO_SelectableLabel_OnMouseEnter(control)

                InitializeTooltip(InformationTooltip, control, RIGHT, -10)

                local SET_TO_FULL_SIZE = true
                local normalR, normalG, normalB = ZO_NORMAL_TEXT:UnpackRGB()
                InformationTooltip:AddLine(GetString(SI_SKILLS_SUBCLASSING_DESCRIPTION), "", normalR, normalG, normalB, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, SET_TO_FULL_SIZE)

                if not SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeAllowAccessToSubclassing() then
                    local achievementTextColor = ZO_ERROR_COLOR
                    local questTextColor = ZO_ERROR_COLOR
                    local achievementId = GetSubclassingAchievementId()
                    local questId = GetSubclassingQuestId()
                    local questNameText = zo_strformat(SI_SKILLS_SUBCLASSING_UNLOCK_QUEST_TEXT, GetQuestName(questId))
                    if IsAchievementComplete(achievementId) then
                        achievementTextColor = ZO_NORMAL_TEXT
                    end
                    local achievementR, achievementG, achievementB = achievementTextColor:UnpackRGB()
                    local questR, questG, questB = questTextColor:UnpackRGB()
                    InformationTooltip:AddLine(GetString(SI_SKILLS_SUBCLASSING_UNLOCK_TOOLTIP_HEADER), "", normalR, normalG, normalB, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, SET_TO_FULL_SIZE)
                    InformationTooltip:AddLine(GetString(SI_SKILLS_SUBCLASSING_UNLOCK_ACHIEVEMENT_TEXT), "", achievementR, achievementG, achievementB, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, SET_TO_FULL_SIZE)
                    InformationTooltip:AddLine(questNameText, "", questR, questG, questB, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, SET_TO_FULL_SIZE)
                    isSubclassingMousedOver = true
                    SKILLS_WINDOW:UpdateKeybinds()
                end
            end

            local OnMouseExit = function(control)
                ZO_SelectableLabel_OnMouseExit(control)
                ClearTooltip(InformationTooltip)
                isSubclassingMousedOver = false
                SKILLS_WINDOW:UpdateKeybinds()
            end

            node.control:SetHandler("OnMouseEnter", OnMouseEnter)
            node.control:SetHandler("OnMouseExit", OnMouseExit)
        else
            if skillLineData:IsClassMastery() then
                local isEnabled = SKILLS_DATA_MANAGER:GetNumPlayerClassActiveSkillLines() == SKILLS_DATA_MANAGER:GetNumActiveClassSkillLines()
                node:SetEnabled(isEnabled)
                node.control:SetEnabled(isEnabled)

                if not isEnabled then
                    local OnMouseEnter = function(control)
                        ZO_SelectableLabel_OnMouseEnter(control)

                        InitializeTooltip(InformationTooltip, control, RIGHT, -10)

                        local SET_TO_FULL_SIZE = true
                        local normalR, normalG, normalB = ZO_NORMAL_TEXT:UnpackRGB()
                        InformationTooltip:AddLine(GetString(SI_SKILLS_CLASS_MASTERY_DISABLED_DESCRIPTION), "", normalR, normalG, normalB, LEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_LEFT, SET_TO_FULL_SIZE)
                    end

                    local OnMouseExit = function(control)
                        ZO_SelectableLabel_OnMouseExit(control)
                        ClearTooltip(InformationTooltip)
                    end

                    node.control:SetHandler("OnMouseEnter", OnMouseEnter)
                    node.control:SetHandler("OnMouseExit", OnMouseExit)
                else
                    node.control:SetHandler("OnMouseEnter", ZO_SelectableLabel_OnMouseEnter)
                    node.control:SetHandler("OnMouseExit", ZO_SelectableLabel_OnMouseExit)
                end
            else
                node:SetEnabled(true)
                node.control:SetEnabled(true)

                node.control:SetHandler("OnMouseEnter", nil)
                node.control:SetHandler("OnMouseExit", nil)
            end

            if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
                control:SetText(skillLineData:GetFormattedNameWithNumPointsAllocated())
            else
                control:SetText(skillLineData:GetFormattedName())
            end

            control.statusIcon:ClearIcons()

            if skillLineData:IsSkillLineOrAbilitiesNew() or skillLineData:IsAdvised() then
                control.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
            end

            if skillLineData:IsInTraining() then
                local TRAINING_ICON = "EsoUI/Art/Progression/training_32.dds"
                control.statusIcon:AddIcon(TRAINING_ICON)
            end

            control.statusIcon:Show()
        end
    end

    local function TreeEntryOnSelected(control, skillLineData, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected and not reselectingDuringRebuild then
            self:RefreshSkillLineInfo()
            if skillLineData.isSubclassingNode == true then
                TriggerTutorial(TUTORIAL_TRIGGER_SUBCLASSING_SYSTEM)
                self.skillListRefreshGroup:MarkDirty("Visible")
                self.subclassingPanel:Show()
            else
                self.subclassingPanel:Hide()
                self:RefreshActionbarState()
                skillLineData:ClearNew()
                self.skillListRefreshGroup:MarkDirty("List")
                self.skillListRefreshGroup:TryClean()
            end
            SKILLS_WINDOW:UpdateKeybinds()
        end
    end

    local function TreeEqualityFunction(left, right)
        if left.isSubclassingNode and right.isSubclassingNode then
            return true
        elseif left.GetId and right.GetId then
            return left:GetId() == right:GetId()
        end
        return false
    end

    skillLinesTree:AddTemplate("ZO_SkillsNavigationEntry", TreeEntrySetup, TreeEntryOnSelected, TreeEqualityFunction)

    skillLinesTree:SetExclusive(true)
    skillLinesTree:SetOpenAnimation("ZO_TreeOpenAnimation")

    local skillLinesTreeRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    skillLinesTreeRefreshGroup:AddDirtyState("List", function()
        self:RebuildSkillLineList()

        local skillLineData = self:GetSelectedSkillLineData()
        if skillLineData and skillLineData.isSubclassingNode then
            local skillLineToSelect = self.subclassingPanel:GetAndClearSkillLineToSelect()
            if skillLineToSelect then
                self:BrowseToSkillLine(skillLineToSelect)
            end
        end
    end)
    skillLinesTreeRefreshGroup:AddDirtyState("Visible", function()
        skillLinesTree:RefreshVisible()
    end)
    skillLinesTreeRefreshGroup:SetActive(function()
        return SKILLS_FRAGMENT:IsShowing()
    end)
    skillLinesTreeRefreshGroup:MarkDirty("List")

    self.skillLinesTreeRefreshGroup = skillLinesTreeRefreshGroup
    self.skillLinesTree = skillLinesTree
end

function ZO_SkillsManager:InitializeSkillList()
    local skillList = self.control:GetNamedChild("SkillList")

    local SKILL_ABILITY_HEIGHT = 70
    ZO_ScrollList_AddDataType(skillList, SKILL_ABILITY_DATA, "ZO_Skills_Ability", SKILL_ABILITY_HEIGHT, function(abilityControl, data)
        ZO_Skills_AbilityEntry_Setup(abilityControl, data.skillData)
    end)
    local SKILL_HEADER_HEIGHT = 32
    ZO_ScrollList_AddDataType(skillList, SKILL_HEADER_DATA, "ZO_Skills_AbilityTypeHeader", SKILL_HEADER_HEIGHT, function(headerControl, data)
        headerControl:GetNamedChild("Label"):SetText(data.headerText)
    end)
    ZO_ScrollList_AddResizeOnScreenResize(skillList)

    local skillListRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    skillListRefreshGroup:AddDirtyState("List", function()
        self:RebuildSkillList()
    end)
    skillListRefreshGroup:AddDirtyState("Visible", function()
        local skillLineData = self:GetSelectedSkillLineData()
        if skillLineData then
            ZO_ScrollList_RefreshVisible(skillList)

            self:RefreshSkillLineDisplay(skillLineData)
        end
    end)
    skillListRefreshGroup:SetActive(function()
        return SKILLS_FRAGMENT:IsShowing()
    end)

    self.skillListRefreshGroup = skillListRefreshGroup
    self.skillList = skillList
end

function ZO_SkillsManager:InitializeSubclassing()
    self.subclassingPanel = ZO_SkillsSubclassing_Keyboard:New(self.control:GetNamedChild("SubclassingPanel"), self)
end

function ZO_SkillsManager:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = function()
                if isSubclassingMousedOver then
                    return GetString(SI_SKILLS_SUBCLASSING_QUEST_GRANT_TEXT)
                elseif self.subclassingPanel:IsSkillLineMousedOver() then
                    return GetString(SI_SKILLS_SUBCLASSING_PREVIEW_ACTION)
                else
                    return self.subclassingPanel:GetSkillsListViewActionText()
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                if isSubclassingMousedOver then
                    BestowSubclassingQuest()
                    self:UpdateKeybinds()
                    ClearTooltip(InformationTooltip)
                elseif self.subclassingPanel:IsSkillLineMousedOver() then
                    self.subclassingPanel:ShowSkillsListView(self.subclassingPanel:GetMousedOverSkillLine())
                    PlaySound(SOUNDS.SKILLS_SUBCLASSING_SKILL_LINE_SELECT)
                elseif self.subclassingPanel:IsSkillsListViewActionAvailable() then
                    self.subclassingPanel:DoSkillsListViewAction()
                    self:UpdateKeybinds()
                end
            end,
            visible = function()
                if isSubclassingMousedOver then
                    if not HasAccessToSubclassing() then
                        local achievementId = GetSubclassingAchievementId()
                        if IsAchievementComplete(achievementId) then
                            local questId = GetSubclassingQuestId()
                            return not HasQuest(questId)
                        end
                    end
                    return false
                else
                    return self.subclassingPanel:IsSkillLineMousedOver() or self.subclassingPanel:IsSkillsListViewActionAvailable()
                end
            end
        },
        {
            name = function()
                if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
                    return GetString(SI_SKILL_RESPEC_CONFIRM_KEYBIND)
                else
                    return GetString(SI_SKILL_RESPEC_START_RESPEC_KEYBIND)
                end
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            enabled = function()
                if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
                    return true
                else
                    if IsCurrentCampaignVengeanceRuleset() then
                        return false, GetString("SI_RESPECRESULT", RESPEC_RESULT_IN_VENGEANCE)
                    end

                    if IsRaidInProgress() then
                        return false, GetString("SI_RESPECRESULT", RESPEC_RESULT_DISALLOWED_IN_ACTIVITY)
                    end

                    if IsUnitInCombat("player") then
                        return false, GetString("SI_RESPECRESULT", RESPEC_RESULT_IS_IN_COMBAT)
                    end

                    return true
                end
            end,
            callback = function()
                if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
                    if SKILLS_AND_ACTION_BAR_MANAGER:DoPendingChangesIncurCost() then
                        if SKILLS_AND_ACTION_BAR_MANAGER:GetSkillRespecPaymentType() == RESPEC_PAYMENT_TYPE_GOLD then
                            if GetSkillRespecCost(SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode()) > 0 or SKILL_LINE_ASSIGNMENT_MANAGER:HasSubclassingChanges() then
                                ZO_Dialogs_ShowDialog("SKILL_RESPEC_CONFIRM_GOLD_KEYBOARD")
                            else
                                SKILLS_AND_ACTION_BAR_MANAGER:ApplyChanges()
                            end
                        else
                            ZO_Dialogs_ShowDialog("SKILL_RESPEC_CONFIRM_SCROLL")
                        end
                    else
                        if SKILL_LINE_ASSIGNMENT_MANAGER:HasSubclassingChanges() then
                            ZO_Dialogs_ShowDialog("SKILL_RESPEC_CONFIRM_FREE")
                        else
                            SKILLS_AND_ACTION_BAR_MANAGER:ApplyChanges()
                        end
                    end
                else
                    if GetInteractionType() == INTERACTION_SKILL_RESPEC then
                        --If the interaction is already active we just need to update the allocation mode
                        SKILLS_AND_ACTION_BAR_MANAGER:SetSkillPointAllocationMode(SKILL_POINT_ALLOCATION_MODE_FULL)
                    else
                        StartSkillRespecFromUI()
                    end
                end
            end,
        },
        {
            name = function()
                local selectedData = self.skillLinesTree:GetSelectedData()
                if selectedData.isSubclassingNode then
                    return GetString(SI_SKILLS_SUBCLASSING_UNTRAIN_ACTION)
                else
                    return GetString("SI_SKILLPOINTALLOCATIONMODE_CLEARKEYBIND", SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode())
                end
            end,
            keybind = "UI_SHORTCUT_NEGATIVE",
            callback = function()
                local selectedData = self.skillLinesTree:GetSelectedData()
                if selectedData.isSubclassingNode then
                    self.subclassingPanel:DoUntrainInSkillsListView()
                    self:UpdateKeybinds()
                else
                    ZO_Dialogs_ShowDialog("SKILL_RESPEC_CONFIRM_CLEAR_ALL_KEYBOARD", self.skillLinesTree:GetSelectedData())
                end
            end,
            visible = function()
                local selectedData = self.skillLinesTree:GetSelectedData()
                if selectedData.isSubclassingNode then
                    return self.subclassingPanel:CanUntrainInSkillsListView()
                else
                    return SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeAllowClear()
                end
            end
        },
        {
            name = function()
                local collectibleData = SCRIBING_DATA_MANAGER:GetScribingPurchasableCollectibleData()
                if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_CHAPTER) then
                    return GetString(SI_SCRIBING_ACTION_UPGRADE)
                else
                    return GetString(SI_GAMEPAD_DLC_BOOK_ACTION_OPEN_CROWN_STORE)
                end
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function()
                local collectibleData = SCRIBING_DATA_MANAGER:GetScribingPurchasableCollectibleData()
                local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData:GetName())
                ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_SKILLS_SCRIBING_LIBRARY)
            end,
            visible = function()
                return not SCRIBING_DATA_MANAGER:IsScribingUnlocked() and self.scribingLibraryTab_isMousedOver
            end
        },
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = function()
                if self.showAdvisorInAdvancedMode then
                    return GetString(SI_CLOSE_SKILLS_ADVISOR_KEYBIND)
                else
                    return GetString(SI_OPEN_SKILLS_ADVISOR_KEYBIND)
                end
            end,
            keybind = "UI_SHORTCUT_QUATERNARY",
            callback = function()
                self.showAdvisorInAdvancedMode = not self.showAdvisorInAdvancedMode
                self:UpdateSkillsAdvisorVisibility()
            end,
            visible = function()
                return ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() and ZO_SKILLS_ADVISOR_SINGLETON:CanUseSkillsAdvisor()
            end
        },
        {
            name = GetString(SI_SKILLS_SUBCLASSING_MORE_INFO_KEYBIND),
            keybind = "UI_SHORTCUT_HELP",
            callback = function()
                local helpCategoryIndex, helpIndex = GetSubclassingHelpIndices()
                HELP:ShowSpecificHelp(helpCategoryIndex, helpIndex)
            end,
            visible = function()
                if isSubclassingMousedOver then
                    local helpCategoryIndex, helpIndex = GetSubclassingHelpIndices()
                    return helpCategoryIndex ~= nil
                end
            end,
        },
        -- Exit/Back
        {
            name = function()
                local selectedData = self.skillLinesTree:GetSelectedData()
                if selectedData.isSubclassingNode and self.skillLinesContainer:IsHidden() then
                    return GetString(SI_SKILLS_SUBCLASSING_EXIT_PREVIEW_ACTION)
                else
                    return GetString(SI_EXIT_BUTTON)
                end
            end,
            keybind = "UI_SHORTCUT_EXIT",
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            callback = function()
                local selectedData = self.skillLinesTree:GetSelectedData()
                if selectedData.isSubclassingNode and self.skillLinesContainer:IsHidden() then
                    self.subclassingPanel:MarkRefreshGroupDirty("ResetToClassSkillLines")
                    PlaySound(SOUNDS.SKILLS_SUBCLASSING_SKILL_LINE_BACK)
                else
                    SCENE_MANAGER:HideCurrentScene()
                end
            end,
        },
    }
end

function ZO_SkillsManager:RegisterForEvents()
    local control = self.control

    local function OnFullSystemUpdated()
        self.skillLinesTreeRefreshGroup:MarkDirty("List")
    end

    local function OnSkillLineUpdated(skillLineData)
        if skillLineData == self:GetSelectedSkillLineData() then
            self:RefreshSkillLineInfo()
            self.skillListRefreshGroup:MarkDirty("List")
        end
    end

    local function OnSkillProgressionUpdated(skillData)
        if skillData:GetSkillLineData() == self:GetSelectedSkillLineData() then
            self.skillListRefreshGroup:MarkDirty("Visible")
        end
    end

    local function OnSkillLineNewStatusChanged(skillLineData)
        self.skillLinesTreeRefreshGroup:MarkDirty("Visible")
        if skillLineData == self:GetSelectedSkillLineData() then
            self.skillListRefreshGroup:MarkDirty("Visible")
        end
        MAIN_MENU_KEYBOARD:RefreshCategoryIndicators()
    end

    SKILLS_DATA_MANAGER:RegisterCallback("FullSystemUpdated", OnFullSystemUpdated)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineUpdated", OnSkillLineUpdated)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillProgressionUpdated", OnSkillProgressionUpdated)
    SKILLS_DATA_MANAGER:RegisterCallback("SkillLineNewStatusChanged", OnSkillLineNewStatusChanged)

    local function OnSkillPointsChanged()
        if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
            self.skillLinesTreeRefreshGroup:MarkDirty("Visible")
        end

        self:RefreshSkillPointInfo()
        self:RefreshSkillLineInfo()
        self.skillListRefreshGroup:MarkDirty("Visible")
    end

    local function OnSkillProgressionKeyChanged(skillPointAllocator)
        if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
            self.skillLinesTreeRefreshGroup:MarkDirty("Visible")
        end

        local skillLineData = skillPointAllocator:GetSkillData():GetSkillLineData()
        if skillLineData == self:GetSelectedSkillLineData() then
            -- In case we only switched morphs.  Might be accompanied by OnSkillPointsChanged.
            self.skillListRefreshGroup:MarkDirty("Visible")
        end
    end

    SKILL_POINT_ALLOCATION_MANAGER:RegisterCallback("SkillPointsChanged", OnSkillPointsChanged)
    SKILL_POINT_ALLOCATION_MANAGER:RegisterCallback("SkillProgressionKeyChanged", OnSkillProgressionKeyChanged)

    local function OnSelectedSkillBuildUpdated()
        self.showAdvisorInAdvancedMode = false
        self:UpdateSkillsAdvisorVisibility()
        self.skillListRefreshGroup:MarkDirty("Visible")
    end

    local function OnSkillBuildAvailabilityChanged()
        self:UpdateSkillsAdvisorVisibility()
        self.skillListRefreshGroup:MarkDirty("Visible")
    end
    
    ZO_SKILLS_ADVISOR_SINGLETON:RegisterCallback("OnSelectedSkillBuildUpdated", OnSelectedSkillBuildUpdated)
    ZO_SKILLS_ADVISOR_SINGLETON:RegisterCallback("OnSkillsAdvisorAvailabilityChanged", OnSkillBuildAvailabilityChanged)

    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnFullSystemUpdated)

    --Weapon Swap Tutorial Setup
    local tutorialAnchor = ZO_Anchor:New(RIGHT, self.assignableActionBar:GetHotbarSwap():GetHotbarNameLabel(), LEFT, -10, 0)
    TUTORIAL_SYSTEM:RegisterTriggerLayoutInfo(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_WEAPON_SWAP_SHOWN_IN_SKILLS_AFTER_UNLOCK_POINTER_BOX, control, SKILLS_FRAGMENT, tutorialAnchor)
    control:RegisterForEvent(EVENT_ACTIVE_WEAPON_PAIR_CHANGED, function()
        TUTORIAL_SYSTEM:RemoveTutorialByTrigger(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_WEAPON_SWAP_SHOWN_IN_SKILLS_AFTER_UNLOCK_POINTER_BOX)
    end)

    local function OnConfirmHideScene(...)
        self:OnConfirmHideScene(...)
    end

    local function OnSkillPointAllocationModeChanged()
        self.skillLinesTreeRefreshGroup:MarkDirty("Visible")
        self.skillListRefreshGroup:MarkDirty("Visible")
        self:UpdateKeybinds()

        -- Only set a hide confirmation callback when we are in a mode where you will lose your changes when leaving
        -- If we always have a callback we will cause a small visual hiccup with the main menu tabs if we don't
        -- actually show a confirmation and immediately accept.
        if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
            KEYBOARD_SKILLS_SCENE:SetHideSceneConfirmationCallback(OnConfirmHideScene)
        else
            KEYBOARD_SKILLS_SCENE:SetHideSceneConfirmationCallback(nil)
        end
    end
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("SkillPointAllocationModeChanged", OnSkillPointAllocationModeChanged)
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("LostConditionalAccessToSubclassing", OnFullSystemUpdated)
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("RespecStateReset", OnFullSystemUpdated)

    -- make sure we've correctly set our hide confirmation callback to start with
    if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
        KEYBOARD_SKILLS_SCENE:SetHideSceneConfirmationCallback(OnConfirmHideScene)
    end

    control:RegisterForEvent(EVENT_PLAYER_DEACTIVATED, function() self:OnPlayerDeactivated() end)

    local function OnPurchaseLockStateChanged()
        self.skillListRefreshGroup:MarkDirty("Visible")
    end
    control:RegisterForEvent(EVENT_ACTION_BAR_LOCKED_REASON_CHANGED, OnPurchaseLockStateChanged)

    local function OnCollectibleUpdated(collectibleId)
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
        if collectibleData:IsSkillStyle() then
            local entries = ZO_ScrollList_GetDataList(self.skillList)
            for index, entry in ipairs(entries) do
                if entry.data.skillData and entry.control and entry.data.skillData.progressionId == collectibleData:GetSkillStyleProgressionId() then
                    local entryCollectibleId = GetActiveProgressionSkillAbilityFxOverrideCollectibleId(entry.data.skillData.progressionId)
                    if entryCollectibleId == 0 then
                        entry.control.skillStyleControl.defaultStyleButton:SetHidden(false)
                        entry.control.skillStyleControl.selectedStyleButton:SetHidden(true)
                    else
                        entry.control.skillStyleControl.defaultStyleButton:SetHidden(true)
                        entry.control.skillStyleControl.selectedStyleButton:SetHidden(false)
                        entry.control.skillStyleControl.selectedStyleButton.icon:SetTexture(collectibleData:GetIcon())
                    end
                end
            end
        end
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectibleUpdated", OnCollectibleUpdated)

    local function OnCollectionUpdated(collectionUpdateType, collectiblesByNewUnlockState)
        local scribingCollectibleId = GetScribingCollectibleId()
        for _, unlockStateTable in pairs(collectiblesByNewUnlockState) do
            for _, collectibleData in ipairs(unlockStateTable) do
                if collectibleData:GetId() == scribingCollectibleId then
                    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("skillsSceneGroup")
                end
            end
        end
    end

    ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCollectionUpdated)

    local function OnSkillLineRespecUpdate()
        self.skillLinesTreeRefreshGroup:MarkDirty("List")
    end

    SKILL_LINE_ASSIGNMENT_MANAGER:RegisterCallback("SkillLineRespecUpdate", OnSkillLineRespecUpdate)

    local function OnQuestsChanged()
        self.skillLinesTreeRefreshGroup:MarkDirty("Visible")
    end

    control:RegisterForEvent(EVENT_QUEST_ADDED, OnQuestsChanged)
    control:RegisterForEvent(EVENT_QUEST_REMOVED, OnQuestsChanged)

    local function OnStartRespecCast()
        if not IsInGamepadPreferredMode() then
            PlaySound(SOUNDS.RESPEC_CAST_TIME_START)
            ZO_Dialogs_ShowDialog("SKILL_RESPEC_CAST_KEYBOARD")
        end
    end

    local function OnSkillRespecResult(eventId, result)
        if ZO_Dialogs_IsShowing("SKILL_RESPEC_CAST_KEYBOARD") and not ZO_Dialogs_IsDialogHiding("SKILL_RESPEC_CAST_KEYBOARD") then
            PlaySound(SOUNDS.RESPEC_CAST_TIME_COMPLETE)
            ZO_Dialogs_ReleaseDialog("SKILL_RESPEC_CAST_KEYBOARD")
        end
    end

    control:RegisterForEvent(EVENT_START_SKILL_RESPEC_CAST, OnStartRespecCast)
    control:RegisterForEvent(EVENT_SKILL_RESPEC_RESULT, OnSkillRespecResult)
end

function ZO_SkillsManager:OnScribingLibraryTabMouseEnter()
    self.scribingLibraryTab_isMousedOver = true
    SKILLS_WINDOW:UpdateKeybinds()
end

function ZO_SkillsManager:OnScribingLibraryTabMouseExit()
    self.scribingLibraryTab_isMousedOver = false
    SKILLS_WINDOW:UpdateKeybinds()
end

function ZO_SkillsManager:SetSkillLinesHidden(isHidden)
    self.skillLinesContainer:SetHidden(isHidden)
end

function ZO_SkillsManager:GetSelectedSkillLineData()
    return self.skillLinesTree:GetSelectedData()
end

function ZO_SkillsManager:UpdateKeybinds()
    if SKILLS_FRAGMENT:IsShowing() then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_SkillsManager:UpdateSkillsAdvisorVisibility()
    if SKILLS_FRAGMENT:IsShowing() then
        if self:IsSkillsAdvisorShown() then
            SCENE_MANAGER:RemoveFragment(FRAME_TARGET_STANDARD_RIGHT_PANEL_FRAGMENT)
            SCENE_MANAGER:RemoveFragment(FRAME_TARGET_BLUR_STANDARD_RIGHT_PANEL_FRAGMENT)
            SCENE_MANAGER:AddFragment(FRAME_TARGET_STANDARD_RIGHT_PANEL_MEDIUM_LEFT_PANEL_FRAGMENT)
            SCENE_MANAGER:AddFragment(FRAME_TARGET_BLUR_STANDARD_RIGHT_PANEL_MEDIUM_LEFT_PANEL_FRAGMENT)
            SCENE_MANAGER:AddFragment(SKILLS_ADVISOR_FRAGMENT)
        else
            SCENE_MANAGER:RemoveFragment(SKILLS_ADVISOR_FRAGMENT)
            SCENE_MANAGER:RemoveFragment(FRAME_TARGET_STANDARD_RIGHT_PANEL_MEDIUM_LEFT_PANEL_FRAGMENT)
            SCENE_MANAGER:RemoveFragment(FRAME_TARGET_BLUR_STANDARD_RIGHT_PANEL_MEDIUM_LEFT_PANEL_FRAGMENT)
            SCENE_MANAGER:AddFragment(FRAME_TARGET_STANDARD_RIGHT_PANEL_FRAGMENT)
            SCENE_MANAGER:AddFragment(FRAME_TARGET_BLUR_STANDARD_RIGHT_PANEL_FRAGMENT)
        end
        self:UpdateKeybinds()
    end
end

function ZO_SkillsManager:IsSkillsAdvisorShown()
    return ZO_SKILLS_ADVISOR_SINGLETON:CanUseSkillsAdvisor() and (not ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() or self.showAdvisorInAdvancedMode)
end

function ZO_SkillsManager:StopSelectedSkillBuildSkillAnimations()
    if self.selectedSkillBuildIconTimeline and self.selectedSkillBuildIconTimeline:IsPlaying() then
        self.selectedSkillBuildIconTimeline:Stop()
    end

    if self.selectedSkillBuildIconLoopTimeline and self.selectedSkillBuildIconLoopTimeline:IsPlaying() then
        self.selectedSkillBuildIconLoopTimeline:Stop()
    end

    if self.selectedSkillBuildIncreaseTimeline and self.selectedSkillBuildIncreaseTimeline:IsPlaying() then
        self.selectedSkillBuildIncreaseTimeline:Stop()
    end

    if self.selectedSkillBuildIncreaseLoopTimeline and self.selectedSkillBuildIncreaseLoopTimeline:IsPlaying() then
        self.selectedSkillBuildIncreaseLoopTimeline:Stop()
    end
end

function ZO_SkillsManager:PlaySelectedSkillBuildSkillAnimations(abilityControl)
    if abilityControl then
        -- If animation if currently playing then stop it before starting new animation
        self:StopSelectedSkillBuildSkillAnimations()

        if not self.selectedSkillBuildIconTimeline then 
            self.selectedSkillBuildIconTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("SkillBuildSelectionIconAnim")
        end

        if not self.selectedSkillBuildIconLoopTimeline then 
            self.selectedSkillBuildIconLoopTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("SkillBuildSelectionIconLoopAnim")
        end

        local abilitySlotControl = abilityControl:GetNamedChild("Slot")
        local abilitySlotAnimTexture = abilitySlotControl:GetNamedChild("SelectedSkillBuildIconAnim")
        local iconAnimationObject = self.selectedSkillBuildIconTimeline:GetFirstAnimation()
        local iconAnimationLoopObject = self.selectedSkillBuildIconLoopTimeline:GetFirstAnimation()
        local skillsObject = self
        local textureFile
        local loopTextureFile
        local skillProgressionData = abilityControl.skillProgressionData
        local skillPointAllocator = skillProgressionData:GetSkillData():GetPointAllocator()
        local isAdvised = skillProgressionData:IsAdvised()

        if skillProgressionData:IsPassive() then
            if isAdvised then
                textureFile = "EsoUI/Art/SkillsAdvisor/animation_circle_1024x64_FLASH.dds"
                loopTextureFile = "EsoUI/Art/SkillsAdvisor/animation_circle_4096x64.dds"
            else
                textureFile = "EsoUI/Art/SkillsAdvisor/animation_circleSingle_1024x64_FLASH.dds"
                loopTextureFile = "EsoUI/Art/SkillsAdvisor/animation_circleSingle_4096x64.dds"
            end
        else
            if isAdvised then
                textureFile = "EsoUI/Art/SkillsAdvisor/animation_square_1024x64_FLASH.dds"
                loopTextureFile = "EsoUI/Art/SkillsAdvisor/animation_square_4096x64.dds"
            else
                textureFile = "EsoUI/Art/SkillsAdvisor/animation_squareSingle_1024x64_FLASH.dds"
                loopTextureFile = "EsoUI/Art/SkillsAdvisor/animation_squareSingle_4096x64.dds"
            end
        end
        iconAnimationObject:SetAnimatedControl(abilitySlotAnimTexture)
        iconAnimationLoopObject:SetAnimatedControl(abilitySlotAnimTexture)

        local function OnStopIcon(_, completedPlaying)
            abilitySlotAnimTexture:SetTexture(loopTextureFile)
            if completedPlaying then 
                skillsObject.selectedSkillBuildIconLoopTimeline:PlayFromStart()
            else
                abilitySlotAnimTexture:SetHidden(true)
            end
        end
        self.selectedSkillBuildIconTimeline:SetHandler("OnStop", OnStopIcon)

        local function OnLoopStopIcon()
            abilitySlotAnimTexture:SetHidden(true)
        end
        self.selectedSkillBuildIconLoopTimeline:SetHandler("OnStop", OnLoopStopIcon)

        abilitySlotAnimTexture:SetTexture(textureFile)
        abilitySlotAnimTexture:SetHidden(false)
        self.selectedSkillBuildIconTimeline:PlayFromStart()

        local showIncreaseAdd = skillPointAllocator:CanPurchase() or skillPointAllocator:CanIncreaseRank()
        local showIncreaseMorph = skillPointAllocator:CanMorph()
        -- Increase Animation Setup
        if showIncreaseAdd or showIncreaseMorph then
            if not self.selectedSkillBuildIncreaseTimeline then 
                self.selectedSkillBuildIncreaseTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("SkillBuildSelectionIncreaseAnim")
            end

            if not self.selectedSkillBuildIncreaseLoopTimeline then 
                self.selectedSkillBuildIncreaseLoopTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("SkillBuildSelectionIncreaseLoopAnim")
            end

            local increaseAnimationObject = self.selectedSkillBuildIncreaseTimeline:GetFirstAnimation()
            local increaseAnimationLoopObject = self.selectedSkillBuildIncreaseLoopTimeline:GetFirstAnimation()
            local abilityIncreaseAnimTexture = abilityControl:GetNamedChild("SelectedSkillBuildIncreaseAnim")
            local increaseTexture = ""
            local increaseTextureLoop = ""
            if showIncreaseAdd then
                increaseTexture = "EsoUI/Art/SkillsAdvisor/animation_add_1024x64_FLASH.dds"
                increaseTextureLoop = "EsoUI/Art/SkillsAdvisor/animation_add_4096x64.dds"
            elseif showIncreaseMorph then
                increaseTexture = "EsoUI/Art/SkillsAdvisor/animation_morph_1024x64_FLASH.dds"
                increaseTextureLoop = "EsoUI/Art/SkillsAdvisor/animation_morph_4096x64.dds"
            end
            increaseAnimationObject:SetAnimatedControl(abilityIncreaseAnimTexture)
            increaseAnimationLoopObject:SetAnimatedControl(abilityIncreaseAnimTexture)

            local function OnStopIncrease(_, completedPlaying)
                abilityIncreaseAnimTexture:SetTexture(increaseTextureLoop)
                if completedPlaying then
                    skillsObject.selectedSkillBuildIncreaseLoopTimeline:PlayFromStart()
                else
                    abilityIncreaseAnimTexture:SetHidden(true)
                end
            end
            self.selectedSkillBuildIncreaseTimeline:SetHandler("OnStop", OnStopIncrease)

            local function OnLoopStopIncrease()
                abilityIncreaseAnimTexture:SetHidden(true)
            end
            self.selectedSkillBuildIncreaseLoopTimeline:SetHandler("OnStop", OnLoopStopIncrease)

            abilityIncreaseAnimTexture:SetTexture(increaseTexture)
            abilityIncreaseAnimTexture:SetHidden(false)
            self.selectedSkillBuildIncreaseTimeline:PlayFromStart()
        end
    end
end

function ZO_SkillsManager:BrowseToSkill(scrollToSkillData)
    local skillLineData = scrollToSkillData:GetSkillLineData()
    self:BrowseToSkillLineAndSkill(skillLineData, scrollToSkillData)
end

function ZO_SkillsManager:BrowseToSkillLine(skillLineData)
    self:BrowseToSkillLineAndSkill(skillLineData, nil)
end

function ZO_SkillsManager:BrowseToSkillLineAndSkill(skillLineData, scrollToSkillData)
    self:SetSkillLinesHidden(false)
    -- Set skillLinesTree to category containing skill and refresh skillList
    local selectedData = self:GetSelectedSkillLineData()
    if selectedData ~= skillLineData then
        local node = self.skillLineIdToNode[skillLineData:GetId()]
        if node then
            self:StopSelectedSkillBuildSkillAnimations()
            self.skillLinesTree:SelectNode(node)
        else
            -- SkillLine is not known or yet advised
            self.selectSkillDataOnRefresh = scrollToSkillData
            skillLineData:SetAdvised(true)
            scrollToSkillData = nil
        end
    end

    if scrollToSkillData then
        self:ScrollToSkillData(scrollToSkillData)
    end
end

function ZO_SkillsManager:ScrollToSkillData(skillData)
    -- Get DataIndex of set ability in skillList and scroll that index into view
    local dataIndex = nil
    local dataValue = nil
    local entries = ZO_ScrollList_GetDataList(self.skillList)
    for index, entry in ipairs(entries) do
        if entry.data.skillData == skillData then
            dataIndex = index
            dataValue = entry.data
            break
        end
    end

    local function PlaySkillBuildAnimation(successfulAnimateInView)
        if successfulAnimateInView then
            -- Play Glow Animation on selected skill
            local abilityControl = ZO_ScrollList_GetDataControl(self.skillList, dataValue)
            self:PlaySelectedSkillBuildSkillAnimations(abilityControl)
            self:FireCallbacks("OnReadyToHandleClickAction")
        end
    end

    if dataIndex then
        ZO_ScrollList_ScrollDataToCenter(self.skillList, dataIndex, PlaySkillBuildAnimation)
    end
end

function ZO_SkillsManager:RefreshSkillLineInfo(forceInit)
    local skillLineData = self:GetSelectedSkillLineData()
    if skillLineData and not skillLineData.isSubclassingNode and not skillLineData:IsClassMastery() then
        self.classMasteryLabel:SetHidden(true)
        self.availablePointsLabel:SetHidden(false)
        self.skyShardsLabel:SetHidden(false)
        self.skillInfo:SetHidden(false)
        ZO_SkillLineInfo_Keyboard_Refresh(self.skillInfo, skillLineData, forceInit)
    else
        self.skillInfo:SetHidden(true)
        if skillLineData and skillLineData.IsClassMastery and skillLineData:IsClassMastery() then
            self.availablePointsLabel:SetHidden(true)
            self.skyShardsLabel:SetHidden(true)
            self.classMasteryLabel:SetText(zo_strformat(SI_SKILLS_CLASS_MASTERY_NUM_POINTS, ZO_SELECTED_TEXT:Colorize(SKILL_POINT_ALLOCATION_MANAGER:GetAvailableClassMasteryPointsForSkillLine(skillLineData))))
            self.classMasteryLabel:SetHidden(false)
        else
            self.classMasteryLabel:SetHidden(true)
            self.availablePointsLabel:SetHidden(false)
            self.skyShardsLabel:SetHidden(false)
        end
    end
end

function ZO_SkillsManager:RefreshSkillPointInfo()
    local availablePoints = SKILL_POINT_ALLOCATION_MANAGER:GetAvailableSkillPoints()
    self.availablePointsLabel:SetText(zo_strformat(SI_SKILLS_POINTS_TO_SPEND, availablePoints))

    local skyShards = GetNumSkyShards()
    self.skyShardsLabel:SetText(zo_strformat(SI_SKILLS_SKY_SHARDS_COLLECTED, skyShards))
end

do
    local g_shownHeaderTexts = {}

    function ZO_SkillsManager:RebuildSkillList()
        self:StopSelectedSkillBuildSkillAnimations()

        local skillLineData = self:GetSelectedSkillLineData()
        local scrollData = ZO_ScrollList_GetDataList(self.skillList)
        ZO_ScrollList_Clear(self.skillList)
        ZO_ClearTable(g_shownHeaderTexts)

        local function IsSkillVisible(skillData)
            return not skillData:IsHidden()
        end

        for _, skillData in skillLineData:SkillIterator({ IsSkillVisible }) do
            local headerText = skillData:GetHeaderText()
            if not g_shownHeaderTexts[headerText] then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILL_HEADER_DATA, { headerText = headerText }))
                g_shownHeaderTexts[headerText] = true
            end

            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILL_ABILITY_DATA,  { skillData = skillData, }))
        end

        ZO_ScrollList_Commit(self.skillList)

        self:RefreshSkillLineDisplay(skillLineData)
    end
end

function ZO_SkillsManager:RefreshSkillLineDisplay(skillLineData)
    if skillLineData.isSubclassingNode then
        self.skillList:SetHidden(true)
        self.advisedOverlay:Hide()
        self.skillList:SetAlpha(1)
    else
        self.skillList:SetHidden(false)
        if (not skillLineData:IsAvailable() and skillLineData:IsAdvised())
            or (skillLineData:IsClassMastery()
                and HasMaxRankInAnyClassSkillLine()
                and not HasMaxRankInAllClassSkillLines()) then
            self:StopSelectedSkillBuildSkillAnimations()
            self.advisedOverlay:Show(skillLineData)
            self.skillList:SetAlpha(0.1)
        else
            self.advisedOverlay:Hide()
            self.skillList:SetAlpha(1)
        end
    end
end

function ZO_SkillsManager:RefreshActionbarState()
    ACTION_BAR_ASSIGNMENT_MANAGER:UpdateWerewolfBarStateInCycle(self:GetSelectedSkillLineData())
end

function ZO_SkillsManager:SelectEntryByAllocationMode()
    local allocationMode = SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode()
    if allocationMode == SKILL_POINT_ALLOCATION_MODE_SUBCLASS_ONLY then
        self.selectSubclassing = true
    end
end

do
    local function IsSkillLineAvailableOrAdvised(skillLineData)
        return skillLineData:IsAvailable() or skillLineData:IsAdvised()
    end
    local SKILL_LINE_FILTERS = { IsSkillLineAvailableOrAdvised }
    function ZO_SkillsManager:RebuildSkillLineList()
        self.skillLinesTree:Reset()
        ZO_ClearTable(self.skillLineIdToNode)
        local nodeToSelect = nil
        for _, skillTypeData in SKILLS_DATA_MANAGER:SkillTypeIterator() do
            local parent
            for _, skillLineData in skillTypeData:SkillLineIterator(SKILL_LINE_FILTERS) do
                if not parent then
                    parent = self.skillLinesTree:AddNode("ZO_SkillIconHeader", skillTypeData)
                end
                local node = self.skillLinesTree:AddNode("ZO_SkillsNavigationEntry", skillLineData, parent)
                self.skillLineIdToNode[skillLineData:GetId()] = node
            end
            if skillTypeData.skillType == SKILL_TYPE_CLASS and not IsCurrentCampaignVengeanceRuleset() then
                local subclassingData =
                {
                    isSubclassingNode = true
                }
                local node = self.skillLinesTree:AddNode("ZO_SkillsNavigationEntry", subclassingData, parent)
                if self.selectSubclassing then
                    nodeToSelect = node
                    self.selectSubclassing = false
                end
            end
        end

        self.skillLinesTree:Commit(nodeToSelect)

        local selectedData = self.skillLinesTree:GetSelectedData()
        local FORCE_INIT = true
        self:RefreshSkillLineInfo(FORCE_INIT)
        self:RefreshSkillPointInfo()
        if selectedData.isSubclassingNode then
            self.skillListRefreshGroup:MarkDirty("Visible")
        else
            self.skillListRefreshGroup:MarkDirty("List")
        end
        self.skillListRefreshGroup:TryClean()

        if self.selectSkillDataOnRefresh ~= nil then
            local skillLineData = self.selectSkillDataOnRefresh:GetSkillLineData()
            self.skillLinesTree:SelectNode(self.skillLineIdToNode[skillLineData:GetId()])
            self:ScrollToSkillData(self.selectSkillDataOnRefresh)
            self.selectSkillDataOnRefresh = nil
        end
    end
end

function ZO_SkillsManager:OnShown()
    self.skillLinesTreeRefreshGroup:TryClean()
    self.skillListRefreshGroup:TryClean()

    KEYBIND_STRIP:RemoveDefaultExit()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

    self:UpdateSkillsAdvisorVisibility()
    self:RefreshActionbarState()
    self.assignableActionBar:RefreshAllButtons()

    local level = GetUnitLevel("player")
    if level >= GetWeaponSwapUnlockedLevel() then
        TriggerTutorial(TUTORIAL_TRIGGER_WEAPON_SWAP_SHOWN_IN_SKILLS_AFTER_UNLOCK_POINTER_BOX)
    end

    HandleUISystemShown(UI_SYSTEM_SKILLS)
end

function ZO_SkillsManager:OnHidden()
    self:StopSelectedSkillBuildSkillAnimations()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:RestoreDefaultExit()
    SKILLS_AND_ACTION_BAR_MANAGER:ResetInterface()
    ACTION_BAR_ASSIGNMENT_MANAGER:CancelPendingWeaponSwap()
end

function ZO_SkillsManager:OnConfirmHideScene(scene, nextSceneName, bypassHideSceneConfirmationReason)
    if bypassHideSceneConfirmationReason == nil and SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
        ZO_Dialogs_ShowDialog("CONFIRM_REVERT_CHANGES",
        {
            confirmCallback = function() scene:AcceptHideScene() end,
            declineCallback = function() scene:RejectHideScene() end,
        })
    else
        scene:AcceptHideScene()
    end
end

function ZO_SkillsManager:OnPlayerDeactivated()
    --If we are deactivated we might be jumping somewhere else. We also might be in the respec interaction which will not be valid when we get where we are going. So just clear out the respec here.
    if KEYBOARD_SKILLS_SCENE:IsShowing() and SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
        SCENE_MANAGER:RequestShowLeaderBaseScene(ZO_BHSCR_SKILLS_PLAYER_DEACTIVATED)
    end
end

function ZO_Skills_DialogAbilitySlot_OnMouseEnter(control)
    InitializeTooltip(SkillTooltip, control, TOPLEFT, 5, -5, TOPRIGHT)

    local DONT_SHOW_SKILL_POINT_COST = false
    local SHOW_UPGRADE_TEXT = true
    local DONT_SHOW_BAD_MORPH = false
    control.skillProgressionData:SetKeyboardTooltip(SkillTooltip, DONT_SHOW_SKILL_POINT_COST, SHOW_UPGRADE_TEXT, control.showAdvice, DONT_SHOW_BAD_MORPH, control.overrideRank)
end

function ZO_Skills_OnEffectivelyShown(self)
    SKILLS_WINDOW:OnShown()
end

function ZO_Skills_OnEffectivelyHidden(self)
    SKILLS_WINDOW:OnHidden()
end

function ZO_Skills_Initialize(control)
    SKILLS_WINDOW = ZO_SkillsManager:New(control)
end

function ZO_SkillIconHeader_OnInitialized(self)
    ZO_IconHeader_OnInitialized(self)
    self.statusIcon = self:GetNamedChild("StatusIcon")
end

function ZO_SkillsNavigationEntry_OnInitialized(self)
    ZO_SelectableLabel_OnInitialized(self)
    self.statusIcon = self:GetNamedChild("StatusIcon")
end

function ZO_SkillStyle_SelectorIcon_Keyboard_OnMouseEnter(self)
    if self.data and self.data.collectibleData then
        local offsetX = ZO_SelectSkillStyleDialog:GetRight() - self:GetRight() + 5
        InitializeTooltip(ItemTooltip, self, LEFT, offsetX, 0, RIGHT)
        local SHOW_NICKNAME = true
        local SHOW_PURCHASABLE_HINT = true
        local SHOW_BLOCK_REASON = true
        ItemTooltip:SetCollectible(self.data.collectibleData:GetId(), SHOW_NICKNAME, SHOW_PURCHASABLE_HINT, SHOW_BLOCK_REASON, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    end
end

function ZO_SkillStyle_SelectorIcon_Keyboard_OnMouseExit(self)
    ClearTooltip(ItemTooltip)
end

function ZO_SelectSkillStyleDialog_DefaultStyle_Keyboard_OnMouseEnter(self)
    local offsetX = ZO_SelectSkillStyleDialog:GetRight() - self:GetRight() + 5
    InitializeTooltip(InformationTooltip, self, LEFT, offsetX, 0, RIGHT)
    InformationTooltip:AddLine(GetString(SI_SKILL_STYLING_TOOLTIP_DEFAULT_TITLE), "", ZO_NORMAL_TEXT:UnpackRGBA())
    InformationTooltip:AddLine(GetString(SI_SKILL_STYLING_TOOLTIP_DEFAULT_DESCRIPTION), "", ZO_NORMAL_TEXT:UnpackRGBA())
end

function ZO_SelectSkillStyleDialog_DefaultStyle_Keyboard_OnMouseExit(self)
    ClearTooltip(InformationTooltip)
end