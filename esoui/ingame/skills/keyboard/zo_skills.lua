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
    --Hardcoded to one because we want to show the baseline values
    morphAbility1.overrideRank = 1
    morphAbility1.advised = false
    dialogControl.morphAbility1 = morphAbility1

    local morphAbility2 = dialogControl:GetNamedChild("MorphAbility2")
    morphAbility2.icon = morphAbility2:GetNamedChild("Icon")
    morphAbility2.selectedCallout = morphAbility2:GetNamedChild("SelectedCallout")
    --Hardcoded to one because we want to show the baseline values
    morphAbility2.overrideRank = 1
    morphAbility2.advised = false
    dialogControl.morphAbility2 = morphAbility2

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
                control = dialogControl:GetNamedChild("Confirm"),
                text =  SI_SKILLS_MORPH_CONFIRM,
                callback =  function(dialog)
                                if dialog.chosenMorphProgressionData then
                                    local skillPointAllocator = dialog.chosenMorphProgressionData:GetSkillData():GetPointAllocator()
                                    skillPointAllocator:Morph(dialog.chosenMorphProgressionData:GetMorphSlot())
                                end
                            end,
            },
        
            [2] =
            {
                control =   dialogControl:GetNamedChild("Cancel"),
                text =      SI_CANCEL,
            }
        }
    })
end

local function InitializeKeyboardConfirmDialog()
    local confirmDialogControl = ZO_SkillsConfirmDialog
    confirmDialogControl.abilityName = confirmDialogControl:GetNamedChild("AbilityName")
    confirmDialogControl.ability = confirmDialogControl:GetNamedChild("Ability")
    confirmDialogControl.ability.icon = confirmDialogControl.ability:GetNamedChild("Icon")
    local advisementLabel = confirmDialogControl:GetNamedChild("Advisement")
    advisementLabel:SetText(GetString(SI_SKILLS_ADVISOR_PURCHASE_ADVISED))
    advisementLabel:SetColor(ZO_SKILLS_ADVISOR_ADVISED_COLOR:UnpackRGBA())
    confirmDialogControl.advisementLabel = advisementLabel

    local function SetupPurchaseAbilityConfirmDialog(dialog, skillProgressionData)
        if skillProgressionData:GetSkillData():GetPointAllocator():CanPurchase() then
            local dialogAbility = dialog.ability
            dialog.abilityName:SetText(skillProgressionData:GetFormattedName())

            dialogAbility.skillProgressionData = skillProgressionData
            dialogAbility.icon:SetTexture(skillProgressionData:GetIcon())
            ZO_Skills_SetKeyboardAbilityButtonTextures(dialogAbility)

            local hideAdvisement = ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() or not skillProgressionData:IsAdvised()
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
            [1] =
            {
                control =   confirmDialogControl:GetNamedChild("Confirm"),
                text =      SI_SKILLS_UNLOCK_CONFIRM,
                callback =  function(dialog)
                                local skillProgressionData = dialog.data
                                local skillPointAllocator = skillProgressionData:GetSkillData():GetPointAllocator()
                                skillPointAllocator:Purchase()
                            end,
            },
        
            [2] =
            {
                control =   confirmDialogControl:GetNamedChild("Cancel"),
                text =      SI_CANCEL,
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

            local hideAdvisement = ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() or not skillData:IsAdvised()
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
            [1] =
            {
                control = upgradeDialogControl:GetNamedChild("Confirm"),
                text =  SI_SKILLS_UPGRADE_CONFIRM,
                callback =  function(dialog)
                                local skillData = dialog.data
                                local skillPointAllocator = skillData:GetPointAllocator()
                                skillPointAllocator:IncreaseRank()
                            end,
            },
            [2] =
            {
                control =   upgradeDialogControl:GetNamedChild("Cancel"),
                text =      SI_CANCEL,
            }
        }
    })
end

local function InitializeKeyboardRespecConfirmationGoldDialog()
    local control = ZO_SkillsRespecConfirmationGoldDialog

    local function SetupRespecConfirmationGoldDialog()
        local balance = GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
        local cost = GetSkillRespecCost(SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode())

        local balanceControl = control:GetNamedChild("Balance")
        ZO_CurrencyControl_SetSimpleCurrency(balanceControl, CURT_MONEY, balance, CURRENCY_OPTIONS)

        local costControl = control:GetNamedChild("Cost")
        ZO_CurrencyControl_SetSimpleCurrency(costControl, CURT_MONEY, cost, CURRENCY_OPTIONS)
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
            text = SI_SKILL_RESPEC_CONFIRM_DIALOG_BODY_INTRO,
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
                keybind =   "DIALOG_PRIMARY",
                control =   control:GetNamedChild("Confirm"),
                text =      SI_DIALOG_CONFIRM,
                callback =  function()
                                local selectedButton = radioButtonGroup:GetClickedButton()
                                if selectedButton.skillLineData then
                                    SKILL_POINT_ALLOCATION_MANAGER:ClearPointsOnSkillLine(selectedButton.skillLineData)
                                else
                                    SKILL_POINT_ALLOCATION_MANAGER:ClearPointsOnAllSkillLines()
                                end
                            end,
            },
            {
                keybind =   "DIALOG_NEGATIVE",
                control =   control:GetNamedChild("Cancel"),
                text =      SI_DIALOG_CANCEL,
            },
        },
    })
end

-- Skill Manager
--------------------

local SKILL_ABILITY_DATA = 1
local SKILL_HEADER_DATA = 2

ZO_SkillsManager = ZO_CallbackObject:Subclass()

function ZO_SkillsManager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_SkillsManager:Initialize(control)
    self.control = control

    SKILLS_FRAGMENT = ZO_FadeSceneFragment:New(control)
    KEYBOARD_SKILLS_SCENE = ZO_InteractScene:New("skills", SCENE_MANAGER, ZO_SKILL_RESPEC_INTERACT_INFO)

    self.showAdvisorInAdvancedMode = false

    self:InitializeControls()
    self:InitializeSkillLineList()
    self:InitializeSkillList()
    self:InitializeKeybindDescriptors()

    InitializeKeyboardMorphDialog()
    InitializeKeyboardConfirmDialog()
    InitializeKeyboardUpgradeDialog()
    InitializeKeyboardRespecConfirmationGoldDialog()
    InitializeKeyboardSkillRespecConfirmClearDialog()

    self:RegisterForEvents()
end

function ZO_SkillsManager:InitializeControls()
    local control = self.control

    self.availablePointsLabel = control:GetNamedChild("AvailablePoints")
    self.skyShardsLabel = control:GetNamedChild("SkyShards")
    self.advisedOverlayControl = control:GetNamedChild("SkillLineAdvisedOverlay")
    self.skillLineUnlockTitleControl = self.advisedOverlayControl:GetNamedChild("SkillLineUnlockTitle")
    self.skillLineUnlockTextControl = self.advisedOverlayControl:GetNamedChild("SkillLineUnlockText")
    self.skillInfo = control:GetNamedChild("SkillInfo")
    self.assignableActionBar = ZO_KeyboardAssignableActionBar:New(control:GetNamedChild("AssignableActionBar"))
end

function ZO_SkillsManager:InitializeSkillLineList()
    local container = self.control:GetNamedChild("SkillLinesContainer")
    local skillLinesTree = ZO_Tree:New(container:GetNamedChild("ScrollChild"), 74, -10, 300)
    self.skillLineIdToNode = {}

    local function TreeHeaderSetup(node, control, skillTypeData, open)
        control.skillTypeData = skillTypeData
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(skillTypeData:GetName())
        local up, down, over = skillTypeData:GetKeyboardIcons()
        
        control.icon:SetTexture(open and down or up)
        control.iconHighlight:SetTexture(over)

        control.statusIcon:ClearIcons()

        if skillTypeData:AreAnySkillLinesNew() then
            control.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end

        control.statusIcon:Show()
        
        ZO_IconHeader_Setup(control, open)
    end

    skillLinesTree:AddTemplate("ZO_SkillIconHeader", TreeHeaderSetup, nil, nil, nil, 0)

    local function TreeEntrySetup(node, control, skillLineData, open)
        if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() then
            control:SetText(skillLineData:GetFormattedNameWithNumPointsAllocated())
        else
            control:SetText(skillLineData:GetFormattedName())
        end

        control.statusIcon:ClearIcons()

        if skillLineData:IsNew() or skillLineData:IsAdvised() then
            control.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end

        control.statusIcon:Show()
    end

    local function TreeEntryOnSelected(control, skillLineData, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected and not reselectingDuringRebuild then
            self:RefreshSkillLineInfo()
            self:RefreshActionbarState()
            skillLineData:ClearNew()
            self.skillListRefreshGroup:MarkDirty("List")
            self.skillListRefreshGroup:TryClean()
        end
    end

    skillLinesTree:AddTemplate("ZO_SkillsNavigationEntry", TreeEntrySetup, TreeEntryOnSelected)

    skillLinesTree:SetExclusive(true)
    skillLinesTree:SetOpenAnimation("ZO_TreeOpenAnimation")

    local skillLinesTreeRefreshGroup = ZO_OrderedRefreshGroup:New(ZO_ORDERED_REFRESH_GROUP_AUTO_CLEAN_PER_FRAME)
    skillLinesTreeRefreshGroup:AddDirtyState("List", function()
        self:RebuildSkillLineList()
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

    ZO_ScrollList_AddDataType(skillList, SKILL_ABILITY_DATA, "ZO_Skills_Ability", 70, function(...) self:SetupAbilityEntry(...) end)
    ZO_ScrollList_AddDataType(skillList, SKILL_HEADER_DATA, "ZO_Skills_AbilityTypeHeader", 32, function(...) self:SetupHeaderEntry(...) end)
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

function ZO_SkillsManager:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
        
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        {
            name = GetString(SI_SKILL_RESPEC_CONFIRM_KEYBIND),

            keybind = "UI_SHORTCUT_SECONDARY",

            callback = function()
                if SKILL_POINT_ALLOCATION_MANAGER:DoPendingChangesIncurCost() then
                    if SKILLS_AND_ACTION_BAR_MANAGER:GetSkillRespecPaymentType() == SKILL_RESPEC_PAYMENT_TYPE_GOLD then
                        ZO_Dialogs_ShowDialog("SKILL_RESPEC_CONFIRM_GOLD_KEYBOARD")
                    else
                        ZO_Dialogs_ShowDialog("SKILL_RESPEC_CONFIRM_SCROLL")
                    end
                else
                    ZO_Dialogs_ShowDialog("SKILL_RESPEC_CONFIRM_FREE")
                end
            end,

            visible = function()
                return SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave()
            end
        },

        {
            name = function()
                return GetString("SI_SKILLPOINTALLOCATIONMODE_CLEARKEYBIND", SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode())
            end,

            keybind = "UI_SHORTCUT_NEGATIVE",

            callback = function()
                ZO_Dialogs_ShowDialog("SKILL_RESPEC_CONFIRM_CLEAR_ALL_KEYBOARD", self.skillLinesTree:GetSelectedData())
            end,

            visible = function()
                return SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeAllowDecrease()
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
                return ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected()
            end
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
            self.skillListRefreshGroup:MarkDirty("Visible")
        end
    end

    local function OnSkillProgressionUpdated(skillData)
        if skillData:GetSkillLineData() == self:GetSelectedSkillLineData() then
            self.skillListRefreshGroup:MarkDirty("Visible")
        end
    end

    local function OnSkillLineNewStatusChanged()
        self.skillLinesTreeRefreshGroup:MarkDirty("Visible")
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

    ZO_SKILLS_ADVISOR_SINGLETON:RegisterCallback("OnSelectedSkillBuildUpdated", OnSelectedSkillBuildUpdated)

    control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnFullSystemUpdated)

    --Weapon Swap Tutorial Setup
    local tutorialAnchor = ZO_Anchor:New(RIGHT, self.assignableActionBar:GetHotbarSwap():GetHotbarNameLabel(), LEFT, -10, 0)
    TUTORIAL_SYSTEM:RegisterTriggerLayoutInfo(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_WEAPON_SWAP_SHOWN_IN_SKILLS_AFTER_UNLOCK, control, SKILLS_FRAGMENT, tutorialAnchor)
    control:RegisterForEvent(EVENT_ACTIVE_WEAPON_PAIR_CHANGED, function()
        TUTORIAL_SYSTEM:RemoveTutorialByTrigger(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_WEAPON_SWAP_SHOWN_IN_SKILLS_AFTER_UNLOCK)
    end)

    local function OnSkillPointAllocationModeChanged()
        self.skillLinesTreeRefreshGroup:MarkDirty("Visible")
        self.skillListRefreshGroup:MarkDirty("Visible")
        self:UpdateKeybinds()
    end
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("SkillPointAllocationModeChanged", OnSkillPointAllocationModeChanged)
    SKILLS_AND_ACTION_BAR_MANAGER:RegisterCallback("RespecStateReset", OnFullSystemUpdated)

    control:RegisterForEvent(EVENT_PLAYER_DEACTIVATED, function() self:OnPlayerDeactivated() end)
    KEYBOARD_SKILLS_SCENE:SetHideSceneConfirmationCallback(function(...) self:OnConfirmHideScene(...) end)

    local function OnPurchaseLockStateChanged()
        self.skillListRefreshGroup:MarkDirty("Visible")
    end
    control:RegisterForEvent(EVENT_ACTION_BAR_LOCKED_REASON_CHANGED, OnPurchaseLockStateChanged)
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
        if not ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() or self.showAdvisorInAdvancedMode then
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
    return not ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() or self.showAdvisorInAdvancedMode
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

do
    local INCREASE_BUTTON_TEXTURES =
    {
        PLUS =
        {
            normal = "EsoUI/Art/Progression/addPoints_up.dds",
            mouseDown = "EsoUI/Art/Progression/addPoints_down.dds",
            mouseover = "EsoUI/Art/Progression/addPoints_over.dds",
            disabled = "EsoUI/Art/Progression/addPoints_disabled.dds",
        },
        MORPH =
        {
            normal = "EsoUI/Art/Progression/morph_up.dds",
            mouseDown = "EsoUI/Art/Progression/morph_down.dds",
            mouseover = "EsoUI/Art/Progression/morph_over.dds",
            disabled = "EsoUI/Art/Progression/morph_disabled.dds",
        },
        REMORPH =
        {
            normal = "EsoUI/Art/Progression/remorph_up.dds",
            mouseDown = "EsoUI/Art/Progression/remorph_down.dds",
            mouseover = "EsoUI/Art/Progression/remorph_over.dds",
            disabled = "EsoUI/Art/Progression/remorph_disabled.dds",
        },
    }

    local function ApplyButtonTextures(button, textures)
        button:SetNormalTexture(textures.normal)
        button:SetPressedTexture(textures.mouseDown)
        button:SetMouseOverTexture(textures.mouseover)
        button:SetDisabledTexture(textures.disabled)
    end

    function ZO_SkillsManager:SetupAbilityEntry(ability, data)
        local skillData = data.skillData
        local skillPointAllocator = skillData:GetPointAllocator()
        local skillProgressionData = skillPointAllocator:GetProgressionData()

        local isPassive = skillData:IsPassive()
        local isActive = not isPassive
        local isPurchased = skillPointAllocator:IsPurchased()
        local isUnlocked = skillProgressionData:IsUnlocked()

        local detailedName
        if isPassive and skillData:GetNumRanks() > 1 then
            detailedName = skillProgressionData:GetFormattedNameWithUpgradeLevels()
        elseif isActive then
            detailedName = skillProgressionData:GetFormattedNameWithRank()
        else
            detailedName = skillProgressionData:GetFormattedName()
        end
        ability.nameLabel:SetText(detailedName)

        if isPurchased then
            ability.nameLabel:SetColor(PURCHASED_COLOR:UnpackRGBA())
        else
            if isUnlocked then
                ability.nameLabel:SetColor(UNPURCHASED_COLOR:UnpackRGBA())
            else 
                ability.nameLabel:SetColor(LOCKED_COLOR:UnpackRGBA())
            end
        end

        local slot = ability.slot

        slot.skillProgressionData = skillProgressionData
        slot.icon:SetTexture(skillProgressionData:GetIcon())
        ZO_Skills_SetKeyboardAbilityButtonTextures(slot)
        ZO_ActionSlot_SetUnusable(slot.icon, not isPurchased)
        slot:SetEnabled(isPurchased and not isPassive)

        local hideXPBar = true
        if isActive and skillProgressionData:HasRankData() then
            local currentRank = skillProgressionData:GetCurrentRank()
            local startXP, endXP = skillProgressionData:GetRankXPExtents(currentRank)
            local currentXP = skillProgressionData:GetCurrentXP()

            local dontWrap = ability.skillProgressionData ~= skillProgressionData
            ability.xpBar:SetHidden(false)
            ZO_SkillInfoXPBar_SetValue(ability.xpBar, currentRank, startXP, endXP, currentXP, dontWrap)
            hideXPBar = false
        end

        ability.skillProgressionData = skillProgressionData

        local offsetY = hideXPBar and 0 or -10
        ability.nameLabel:SetAnchor(LEFT, slot, RIGHT, 10, offsetY)

        if hideXPBar then
            ability.xpBar:SetHidden(true)
            local NO_LEVEL = nil
            local DONT_WRAP = true
            ZO_SkillInfoXPBar_SetValue(ability.xpBar, NO_LEVEL, 0, 1, 0, DONT_WRAP)
        end

        ability.lock:SetHidden(isUnlocked)

        local canPurchase = skillPointAllocator:CanPurchase()
        local canIncreaseRank = skillPointAllocator:CanIncreaseRank()
        local canMorph = skillPointAllocator:CanMorph()

        local increaseButton = ability.increaseButton
        local decreaseButton = ability.decreaseButton
        local hideIncreaseButton = true
        local hideDecreaseButton = true
        local skillPointAllocationMode = SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode()
        if skillPointAllocationMode == SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY then
            local increaseTextures = nil
            if canMorph then
                increaseTextures = INCREASE_BUTTON_TEXTURES.MORPH
            elseif canPurchase or canIncreaseRank then
                increaseTextures = INCREASE_BUTTON_TEXTURES.PLUS
            end

            if increaseTextures then
                ApplyButtonTextures(increaseButton, increaseTextures)
                if GetActionBarLockedReason() == ACTION_BAR_LOCKED_REASON_COMBAT then
                    increaseButton:SetState(BSTATE_DISABLED)
                else
                    increaseButton:SetState(BSTATE_NORMAL)
                end
                hideIncreaseButton = false
            end
        else
            local isFullRespec = skillPointAllocationMode == SKILL_POINT_ALLOCATION_MODE_FULL
            if skillData:CanPointAllocationsBeAltered(isFullRespec) then
                hideIncreaseButton = false
                hideDecreaseButton = false

                if isPassive or not isPurchased or not skillData:IsAtMorph() then
                    ApplyButtonTextures(increaseButton, INCREASE_BUTTON_TEXTURES.PLUS)
                else
                    if skillProgressionData:IsMorph() then
                        ApplyButtonTextures(increaseButton, INCREASE_BUTTON_TEXTURES.REMORPH)
                    else
                        ApplyButtonTextures(increaseButton, INCREASE_BUTTON_TEXTURES.MORPH)
                    end
                end

                if canMorph or canPurchase or canIncreaseRank then
                    increaseButton:SetState(BSTATE_NORMAL)
                else
                    increaseButton:SetState(BSTATE_DISABLED)
                end

                if skillPointAllocator:CanSell() or skillPointAllocator:CanDecreaseRank() or skillPointAllocator:CanUnmorph() then
                    decreaseButton:SetState(BSTATE_NORMAL)
                else
                    decreaseButton:SetState(BSTATE_DISABLED)
                end
            end
        end

        increaseButton:SetHidden(hideIncreaseButton)
        decreaseButton:SetHidden(hideDecreaseButton)
    end
end

function ZO_SkillsManager:SetupHeaderEntry(header, data)
    local label = GetControl(header, "Label")
    label:SetText(data.headerText)
end

function ZO_SkillsManager:RefreshSkillLineInfo(forceInit)
    local skillLineData = self:GetSelectedSkillLineData()

    local lastRankXP, nextRankXP, currentRankXP = skillLineData:GetRankXPValues()

    self.skillInfo.name:SetText(skillLineData:GetFormattedName())
    local skillInfoXPBar = self.skillInfo.xpBar
    local skillInfoXPBarControl = skillInfoXPBar:GetControl()
    local dontWrap = skillInfoXPBarControl.skillLineData ~= skillLineData or forceInit
    skillInfoXPBarControl.skillLineData = skillLineData
    if skillLineData:IsAdvised() then
        local RANK_NOT_SHOWN = 1
        local CURRENT_XP_NOT_SHOWN = 0
        ZO_SkillInfoXPBar_SetValue(skillInfoXPBar, RANK_NOT_SHOWN, lastRankXP, nextRankXP, CURRENT_XP_NOT_SHOWN, dontWrap)
    else
        ZO_SkillInfoXPBar_SetValue(skillInfoXPBar, skillLineData:GetCurrentRank(), lastRankXP, nextRankXP, currentRankXP, dontWrap)
    end

    if SkillTooltip:GetOwner() == skillInfoXPBarControl then
        ZO_SkillInfoXPBar_OnMouseEnter(skillInfoXPBarControl)
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

        for _, skillData in skillLineData:SkillIterator() do
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
    if not skillLineData:IsAvailable() and skillLineData:IsAdvised() then
        self:StopSelectedSkillBuildSkillAnimations()
        self.skillLineUnlockTitleControl:SetText(zo_strformat(SI_SKILLS_ADVISOR_SKILL_NOT_DISCOVERED_NAME, skillLineData:GetName()))
        self.skillLineUnlockTextControl:SetText(zo_strformat(SI_SKILLS_ADVISOR_SKILL_NOT_DISCOVERED_DESCRIPTION, skillLineData:GetUnlockText()))
        self.advisedOverlayControl:SetHidden(false)
        self.skillList:SetAlpha(0.1)
    else
        self.advisedOverlayControl:SetHidden(true)
        self.skillList:SetAlpha(1)
    end 
end

function ZO_SkillsManager:RefreshActionbarState()
    ACTION_BAR_ASSIGNMENT_MANAGER:UpdateWerewolfBarStateInCycle(self:GetSelectedSkillLineData())
end

function ZO_SkillsManager:RebuildSkillLineList()
    self.skillLinesTree:Reset()
    ZO_ClearTable(self.skillLineIdToNode)
    for _, skillTypeData in SKILLS_DATA_MANAGER:SkillTypeIterator() do
        local parent
        for _, skillLineData in skillTypeData:SkillLineIterator() do
            if skillLineData:IsAvailable() or skillLineData:IsAdvised() then
                if not parent then
                    parent = self.skillLinesTree:AddNode("ZO_SkillIconHeader", skillTypeData)
                end
                local node = self.skillLinesTree:AddNode("ZO_SkillsNavigationEntry", skillLineData, parent)
                self.skillLineIdToNode[skillLineData:GetId()] = node
            end
        end
    end

    self.skillLinesTree:Commit()

    local FORCE_INIT = true
    self:RefreshSkillLineInfo(FORCE_INIT)
    self:RefreshSkillPointInfo()
    self.skillListRefreshGroup:MarkDirty("List")
    self.skillListRefreshGroup:TryClean()

    if self.selectSkillDataOnRefresh ~= nil then
        local skillLineData = self.selectSkillDataOnRefresh:GetSkillLineData()
        self.skillLinesTree:SelectNode(self.skillLineIdToNode[skillLineData:GetId()])
        self:ScrollToSkillData(self.selectSkillDataOnRefresh)
        self.selectSkillDataOnRefresh = nil
    end
end

function ZO_SkillsManager:OnShown()
    self.skillLinesTreeRefreshGroup:TryClean()
    self.skillListRefreshGroup:TryClean()

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)

    self:UpdateSkillsAdvisorVisibility()
    self:RefreshActionbarState()
    self.assignableActionBar:RefreshAllButtons()

    local level = GetUnitLevel("player")
    if level >= GetWeaponSwapUnlockedLevel() then
        TriggerTutorial(TUTORIAL_TRIGGER_WEAPON_SWAP_SHOWN_IN_SKILLS_AFTER_UNLOCK)
    end
end

function ZO_SkillsManager:OnHidden()
    self:StopSelectedSkillBuildSkillAnimations()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
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
        local DEFAULT_PUSH = nil
        local DEFAULT_NEXT_SCENE_CLEARS_SCENE_STACK = nil
        local DEFAULT_NUM_SCENES_NEXT_SCENE_POPS = nil
        SCENE_MANAGER:Show(SCENE_MANAGER:GetBaseScene():GetName(), DEFAULT_PUSH, DEFAULT_NEXT_SCENE_CLEARS_SCENE_STACK, DEFAULT_NUM_SCENES_NEXT_SCENE_POPS, ZO_BHSCR_SKILLS_PLAYER_DEACTIVATED)
    end
end

function ZO_Skills_AbilitySlot_OnMouseEnter(control)
    SKILLS_WINDOW:StopSelectedSkillBuildSkillAnimations()

    InitializeTooltip(SkillTooltip, control, TOPLEFT, 5, -5, TOPRIGHT)

    local SHOW_SKILL_POINT_COST = true
    local DONT_SHOW_UPGRADE_TEXT = false
    local DONT_SHOW_ADVISED = false
    local SHOW_BAD_MORPH = true
    control.skillProgressionData:SetKeyboardTooltip(SkillTooltip, SHOW_SKILL_POINT_COST, DONT_SHOW_UPGRADE_TEXT, DONT_SHOW_ADVISED, SHOW_BAD_MORPH)
end

function ZO_Skills_DialogAbilitySlot_OnMouseEnter(control)
    InitializeTooltip(SkillTooltip, control, TOPLEFT, 5, -5, TOPRIGHT)

    local DONT_SHOW_SKILL_POINT_COST = false
    local SHOW_UPGRADE_TEXT = true
    local DONT_SHOW_BAD_MORPH = false
    control.skillProgressionData:SetKeyboardTooltip(SkillTooltip, DONT_SHOW_SKILL_POINT_COST, SHOW_UPGRADE_TEXT, control.showAdvice, DONT_SHOW_BAD_MORPH, control.overrideRank)
end

function ZO_Skills_AbilitySlot_OnMouseExit()
    ClearTooltip(SkillTooltip)
end

function ZO_Skills_AbilitySlot_OnDragStart(control)
    if(GetCursorContentType() == MOUSE_CONTENT_EMPTY) then
        local skillData = control.skillProgressionData:GetSkillData()
            PickupAbilityBySkillLine(skillData:GetIndices())
        end
end

function ZO_Skills_AbilitySlot_OnDoubleClick(control)
    local skillData = control.skillProgressionData:GetSkillData()
    if not skillData:IsPassive() and skillData:GetPointAllocator():IsPurchased() then
        if ACTION_BAR_ASSIGNMENT_MANAGER:TryToSlotNewSkill(skillData) then
            PlaySound(SOUNDS.ABILITY_SLOTTED)
        end
    end
end

function ZO_Skills_AbilitySlot_OnClick(control)
    local hotbar = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
    local skillData = control.skillProgressionData:GetSkillData()
    if not skillData:IsPassive() and skillData:GetPointAllocator():IsPurchased() then
        ClearMenu()
        if skillData:IsUltimate() then
            local ultimateSlotIndex = ACTION_BAR_ULTIMATE_SLOT_INDEX + 1
            if hotbar:GetExpectedSkillSlotResult(ultimateSlotIndex, skillData) == HOT_BAR_RESULT_SUCCESS then
                AddMenuItem(GetString(SI_SKILL_ABILITY_ASSIGN_TO_ULTIMATE_SLOT), function()
                    if hotbar:AssignSkillToSlot(ultimateSlotIndex, skillData) then
                        PlaySound(SOUNDS.ABILITY_SLOTTED)
                    end
                end)
            end
        else
            local slotId = hotbar:FindEmptySlotForSkill(skillData)
            if slotId then
                AddMenuItem(GetString(SI_SKILL_ABILITY_ASSIGN_TO_EMPTY_SLOT), function()
                    if hotbar:AssignSkillToSlot(slotId, skillData) then
                        PlaySound(SOUNDS.ABILITY_SLOTTED)
                    end
                end)
            end

            for actionSlotIndex = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1, ACTION_BAR_ULTIMATE_SLOT_INDEX do
                if hotbar:GetExpectedSkillSlotResult(actionSlotIndex, skillData) == HOT_BAR_RESULT_SUCCESS then
                    AddMenuItem(zo_strformat(SI_SKILL_ABILITY_ASSIGN_TO_SLOT, actionSlotIndex - 2), function()
                        if hotbar:AssignSkillToSlot(actionSlotIndex, skillData) then
                            PlaySound(SOUNDS.ABILITY_SLOTTED)
                        end
                    end)
                end
            end
        end
        ShowMenu(control)
    end
end

function ZO_Skills_AbilityIncrease_OnClicked(control, shift)
    SKILLS_WINDOW:StopSelectedSkillBuildSkillAnimations()
    local skillProgressionData = control:GetParent().skillProgressionData
    local skillData = skillProgressionData:GetSkillData()
    local skillPointAllocator = skillData:GetPointAllocator()

    if shift and SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeBatchSave() and skillPointAllocator:CanMaxout() then
        skillPointAllocator:Maxout()
    else
        if skillPointAllocator:CanPurchase() then
            if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeConfirmOnPurchase() then
                ZO_Dialogs_ShowDialog("PURCHASE_ABILITY_CONFIRM", skillProgressionData)
            else
                skillPointAllocator:Purchase()
            end
        elseif skillPointAllocator:CanIncreaseRank() then
            if SKILLS_AND_ACTION_BAR_MANAGER:DoesSkillPointAllocationModeConfirmOnIncreaseRank() then
                ZO_Dialogs_ShowDialog("UPGRADE_ABILITY_CONFIRM", skillData)
            else
                skillPointAllocator:IncreaseRank()
            end
        elseif skillPointAllocator:CanMorph() then
            ZO_Dialogs_ShowDialog("MORPH_ABILITY_CONFIRM", skillData)
        end
    end
end

function ZO_Skills_AbilityIncrease_OnMouseEnter(control)
    if SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode() == SKILL_POINT_ALLOCATION_MODE_PURCHASE_ONLY then
        local lockedReason = GetActionBarLockedReason()
        if lockedReason == ACTION_BAR_LOCKED_REASON_COMBAT then
            InitializeTooltip(InformationTooltip, control, RIGHT, -5, 0, LEFT)
            SetTooltipText(InformationTooltip, GetString("SI_RESPECRESULT", RESPEC_RESULT_IS_IN_COMBAT))
        elseif lockedReason == ACTION_BAR_LOCKED_REASON_NOT_RESPECCABLE then
            InitializeTooltip(InformationTooltip, control, RIGHT, -5, 0, LEFT)
            SetTooltipText(InformationTooltip, GetString("SI_RESPECRESULT", RESPEC_RESULT_ACTIVE_HOTBAR_NOT_RESPECCABLE))
        end
    end
end

function ZO_Skills_AbilityIncrease_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_Skills_AbilityDecrease_OnClicked(control, shift)
    local skillProgressionData = control:GetParent().skillProgressionData
    local skillPointAllocator = skillProgressionData:GetSkillData():GetPointAllocator()

    if shift and skillPointAllocator:CanClear() then
        skillPointAllocator:Clear()
    else
        if skillPointAllocator:CanSell() then
            skillPointAllocator:Sell()
        elseif skillPointAllocator:CanDecreaseRank() then
            skillPointAllocator:DecreaseRank()
        elseif skillPointAllocator:CanUnmorph() then
            skillPointAllocator:Unmorph()
        end
    end
end

function ZO_Skills_AbilityDecrease_OnMouseEnter(control)
    if SKILLS_AND_ACTION_BAR_MANAGER:GetSkillPointAllocationMode() == SKILL_POINT_ALLOCATION_MODE_MORPHS_ONLY then
        local skillProgressionData = control:GetParent().skillProgressionData
        local skillPointAllocator = skillProgressionData:GetSkillData():GetPointAllocator()

        if skillProgressionData:IsActive() and skillPointAllocator:IsPurchased() and skillPointAllocator:GetMorphSlot() == MORPH_SLOT_BASE and not skillPointAllocator:CanSell() then
            InitializeTooltip(InformationTooltip, control, RIGHT, -5, 0, LEFT)
            SetTooltipText(InformationTooltip, GetString(SI_SKILL_RESPEC_MORPHS_ONLY_CANNOT_SELL_BASE_ABILITY))
        end
    end
end

function ZO_Skills_AbilityDecrease_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

function ZO_SkillInfoXPBar_OnMouseEnter(control)
    SKILLS_WINDOW:StopSelectedSkillBuildSkillAnimations()
    InitializeTooltip(SkillTooltip, control, TOPLEFT, 15, 5, BOTTOMLEFT)
    SkillTooltip:SetSkillLine(control.skillLineData:GetIndices())
end

function ZO_SkillInfoXPBar_OnMouseExit()
    ClearTooltip(SkillTooltip)
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