local skillTypeToSound =
{
    [SKILL_TYPE_CLASS] = SOUNDS.SKILL_TYPE_CLASS,
    [SKILL_TYPE_WEAPON] = SOUNDS.SKILL_TYPE_WEAPON,
    [SKILL_TYPE_ARMOR] = SOUNDS.SKILL_TYPE_ARMOR,
    [SKILL_TYPE_WORLD] = SOUNDS.SKILL_TYPE_WORLD,
    [SKILL_TYPE_GUILD] = SOUNDS.SKILL_TYPE_GUILD,
    [SKILL_TYPE_AVA] = SOUNDS.SKILL_TYPE_AVA,
    [SKILL_TYPE_RACIAL] = SOUNDS.SKILL_TYPE_RACIAL,
    [SKILL_TYPE_TRADESKILL] = SOUNDS.SKILL_TYPE_TRADESKILL,
}

local ALERT_TEXTURES =
{
    [ZO_SKILLS_MORPH_STATE] = {normal = "EsoUI/Art/Progression/morph_up.dds", mouseDown = "EsoUI/Art/Progression/morph_down.dds", mouseover = "EsoUI/Art/Progression/morph_over.dds"},
    [ZO_SKILLS_PURCHASE_STATE] = {normal = "EsoUI/Art/Progression/addPoints_up.dds", mouseDown = "EsoUI/Art/Progression/addPoints_down.dds", mouseover = "EsoUI/Art/Progression/addPoints_over.dds"},
}

-- Skill Manager
--------------------

local SKILL_ABILITY_DATA = 1
local SKILL_HEADER_DATA = 2

ZO_SkillsManager = ZO_Object:Subclass()

local function SetAbilityButtonTextures(button, passive)
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
end

function ZO_SkillsManager:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_SkillsManager:Initialize(container)
    self.displayedAbilityProgressions = {}

    self.container = container
    self.availablePoints = 0
    self.skyShards = 0
    self.availablePointsLabel = GetControl(container, "AvailablePoints")
    self.skyShardsLabel = GetControl(container, "SkyShards")

    self.navigationContainer = GetControl(container, "NavigationContainer")
    self.navigationTree = ZO_Tree:New(self.navigationContainer:GetNamedChild("ScrollChild"), 74, -10, 300)

    local function TreeHeaderSetup(node, control, skillType, open)
        control.skillType = skillType
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(GetString("SI_SKILLTYPE", skillType))
        local down, up, over = ZO_Skills_GetIconsForSkillType(skillType)

        control.icon:SetTexture(open and down or up)
        control.iconHighlight:SetTexture(over)

        control.statusIcon:ClearIcons()

        if NEW_SKILL_CALLOUTS:AreAnySkillLinesInTypeNew(skillType) then
            control.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end

        control.statusIcon:Show()
        
        ZO_IconHeader_Setup(control, open)
    end

    self.navigationTree:AddTemplate("ZO_SkillIconHeader", TreeHeaderSetup, nil, nil, nil, 0)

    local function TreeEntrySetup(node, control, data, open)
        local name = GetSkillLineInfo(data.skillType, data.skillLineIndex)
        control:SetText(zo_strformat(SI_SKILLS_TREE_NAME_FORMAT, name))

        control.statusIcon:ClearIcons()

        if NEW_SKILL_CALLOUTS:IsSkillLineNew(data.skillType, data.skillLineIndex) then
            control.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end

        control.statusIcon:Show()
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected and not reselectingDuringRebuild then
            self:RefreshSkillInfo()
            self:RefreshList()
            NEW_SKILL_CALLOUTS:ClearSkillLineNewStatus(data.skillType, data.skillLineIndex)
        end

    end

    local function TreeEntryEquality(left, right)
        return left.skillType == right.skillType and left.skillLineIndex == right.skillLineIndex
    end

    self.navigationTree:AddTemplate("ZO_SkillsNavigationEntry", TreeEntrySetup, TreeEntryOnSelected, TreeEntryEquality)

    self.navigationTree:SetExclusive(true)
    self.navigationTree:SetOpenAnimation("ZO_TreeOpenAnimation")

    self.skillInfo = GetControl(container, "SkillInfo")

    self.abilityList = GetControl(container, "AbilityList")
    ZO_ScrollList_Initialize(self.abilityList)
    ZO_ScrollList_AddDataType(self.abilityList, SKILL_ABILITY_DATA, "ZO_Skills_Ability", 70, function(control, data) self:SetupAbilityEntry(control, data) end)
    ZO_ScrollList_AddDataType(self.abilityList, SKILL_HEADER_DATA, "ZO_Skills_AbilityTypeHeader", 32, function(control, data) self:SetupHeaderEntry(control, data) end)
    ZO_ScrollList_AddResizeOnScreenResize(self.abilityList)

    self.warning = GetControl(container, "Warning")

    -- initialize dialogs
    self:InitializeMorphDialog()
    self:InitializeConfirmDialog()
    self:InitializeUpgradeDialog()

    -- event registration
    local function Refresh()
        self:Refresh()
    end

    local function OnSkillLineUpdate(event, skillType, skillIndex)
        if self:GetSelectedSkillType() == skillType and skillIndex == self:GetSelectedSkillLineIndex() then
            self:RefreshSkillInfo()
            self:RefreshList()
        end
    end

    local function OnAbilityProgressionUpdate(event, progressionIndex)
        if self.displayedAbilityProgressions[progressionIndex] then
            self:RefreshList()
        end
    end

    local function OnSkillPointsChanged()
        self:RefreshSkillInfo()
        self:RefreshList()
    end

    local function OnSkillAbilityProgressionsUpdated()
        self:RefreshList()
    end

    container:RegisterForEvent(EVENT_SKILL_RANK_UPDATE, OnSkillLineUpdate)
    container:RegisterForEvent(EVENT_SKILL_XP_UPDATE, OnSkillLineUpdate)
    container:RegisterForEvent(EVENT_SKILLS_FULL_UPDATE, Refresh)
    container:RegisterForEvent(EVENT_SKILL_POINTS_CHANGED, OnSkillPointsChanged)
    container:RegisterForEvent(EVENT_SKILL_ABILITY_PROGRESSIONS_UPDATED, OnSkillAbilityProgressionsUpdated)
    container:RegisterForEvent(EVENT_PLAYER_ACTIVATED, Refresh)
    container:RegisterForEvent(EVENT_ABILITY_PROGRESSION_RANK_UPDATE, OnAbilityProgressionUpdate)
    container:RegisterForEvent(EVENT_ABILITY_PROGRESSION_XP_UPDATE, OnAbilityProgressionUpdate)

    -- callbacks
    local function OnNewStatusChanged()
        self.navigationTree:RefreshVisible()
        MAIN_MENU_KEYBOARD:RefreshCategoryIndicators()
    end

    NEW_SKILL_CALLOUTS:RegisterCallback("OnSkillLineNewStatusChanged", OnNewStatusChanged)
    NEW_SKILL_CALLOUTS:RegisterCallback("OnAbilityUpdatedStatusChanged", OnNewStatusChanged)
end

function ZO_SkillsManager:InitializeMorphDialog()
    local dialogControl = GetControl("ZO_SkillsMorphDialog")
    dialogControl.desc = GetControl(dialogControl, "Description")

    dialogControl.baseAbility = GetControl(dialogControl, "BaseAbility")
    dialogControl.baseAbility.icon = GetControl(dialogControl.baseAbility, "Icon")

    dialogControl.morphAbility1 = GetControl(dialogControl, "MorphAbility1")
    dialogControl.morphAbility1.icon = GetControl(dialogControl.morphAbility1, "Icon")
    dialogControl.morphAbility1.selectedCallout = GetControl(dialogControl.morphAbility1, "SelectedCallout")
    dialogControl.morphAbility1.morph = 1
    dialogControl.morphAbility1.rank = 1

    dialogControl.morphAbility2 = GetControl(dialogControl, "MorphAbility2")
    dialogControl.morphAbility2.icon = GetControl(dialogControl.morphAbility2, "Icon")
    dialogControl.morphAbility2.selectedCallout = GetControl(dialogControl.morphAbility2, "SelectedCallout")
    dialogControl.morphAbility2.morph = 2
    dialogControl.morphAbility2.rank = 1

    dialogControl.confirmButton = GetControl(dialogControl, "Confirm")

    local function SetupMorphAbilityConfirmDialog(dialog, abilityControl)
        if abilityControl.ability.atMorph then
            local ability = abilityControl.ability
            local slot = abilityControl.ability.slot

            dialog.desc:SetText(zo_strformat(SI_SKILLS_SELECT_MORPH, ability.name))

            local baseAbility = dialog.baseAbility
            baseAbility.skillType = abilityControl.skillType
            baseAbility.lineIndex = abilityControl.lineIndex
            baseAbility.index = abilityControl.index
            baseAbility.icon:SetTexture(slot.iconFile)

            local morphAbility1 = dialog.morphAbility1
            local _, morph1Icon = GetAbilityProgressionAbilityInfo(ability.progressionIndex, morphAbility1.morph, morphAbility1.rank)
            morphAbility1.progressionIndex = ability.progressionIndex
            morphAbility1.icon:SetTexture(morph1Icon)
            morphAbility1.selectedCallout:SetHidden(true)
            ZO_ActionSlot_SetUnusable(morphAbility1.icon, false)

            local morphAbility2 = dialog.morphAbility2
            local _, morph2Icon = GetAbilityProgressionAbilityInfo(ability.progressionIndex, morphAbility2.morph, morphAbility2.rank)
            morphAbility2.progressionIndex = ability.progressionIndex
            morphAbility2.icon:SetTexture(morph2Icon)
            morphAbility2.selectedCallout:SetHidden(true)
            ZO_ActionSlot_SetUnusable(morphAbility2.icon, false)

            dialog.confirmButton:SetState(BSTATE_DISABLED)

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

    self.morphDialog = dialogControl
end

function ZO_SkillsManager:InitializeConfirmDialog()
    local confirmDialogControl = GetControl("ZO_SkillsConfirmDialog")
    confirmDialogControl.abilityName = GetControl(confirmDialogControl, "AbilityName")
    confirmDialogControl.ability = GetControl(confirmDialogControl, "Ability")
    confirmDialogControl.ability.icon = GetControl(confirmDialogControl.ability, "Icon")

    local function SetupPurchaseAbilityConfirmDialog(dialog, abilityControl)
        local ability = abilityControl.ability
        local slot = abilityControl.ability.slot
        local dialogAbility = dialog.ability

        SetAbilityButtonTextures(dialogAbility, ability.passive)

        dialog.abilityName:SetText(ability.plainName)

        dialogAbility.skillType = abilityControl.skillType
        dialogAbility.lineIndex = abilityControl.lineIndex
        dialogAbility.index = abilityControl.index
        dialogAbility.icon:SetTexture(slot.iconFile)

        dialog.chosenSkillType = abilityControl.skillType
        dialog.chosenLineIndex = abilityControl.lineIndex
        dialog.chosenAbilityIndex = abilityControl.index
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

    self.confirmDialog = confirmDialogControl
end

function ZO_SkillsManager:InitializeUpgradeDialog()
    local upgradeDialogControl = GetControl("ZO_SkillsUpgradeDialog")
    upgradeDialogControl.desc = GetControl(upgradeDialogControl, "Description")

    upgradeDialogControl.baseAbility = GetControl(upgradeDialogControl, "BaseAbility")
    upgradeDialogControl.baseAbility.icon = GetControl(upgradeDialogControl.baseAbility, "Icon")

    upgradeDialogControl.upgradeAbility = GetControl(upgradeDialogControl, "UpgradeAbility")
    upgradeDialogControl.upgradeAbility.icon = GetControl(upgradeDialogControl.upgradeAbility, "Icon")

    local function SetupUpgradeAbilityDialog(dialog, abilityControl)
        local ability = abilityControl.ability
        local slot = abilityControl.ability.slot

        dialog.desc:SetText(zo_strformat(SI_SKILLS_UPGRADE_DESCRIPTION, ability.plainName))

        local baseAbility = dialog.baseAbility
        local upgradeAbility = dialog.upgradeAbility

        SetAbilityButtonTextures(baseAbility, ability.passive)
        SetAbilityButtonTextures(upgradeAbility, ability.passive)

        baseAbility.skillType = abilityControl.skillType
        baseAbility.lineIndex = abilityControl.lineIndex
        baseAbility.index = abilityControl.index
        baseAbility.icon:SetTexture(slot.iconFile)

        local _, upgradeIcon = GetSkillAbilityNextUpgradeInfo(abilityControl.skillType, abilityControl.lineIndex, abilityControl.index)
        upgradeAbility.skillType = abilityControl.skillType
        upgradeAbility.lineIndex = abilityControl.lineIndex
        upgradeAbility.index = abilityControl.index
        upgradeAbility.icon:SetTexture(upgradeIcon)

        dialog.chosenSkillType = abilityControl.skillType
        dialog.chosenLineIndex = abilityControl.lineIndex
        dialog.chosenAbilityIndex = abilityControl.index
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

    self.upgradeDialog = upgradeDialogControl
end

function ZO_SkillsManager:SetupAbilityEntry(ability, data)
    SetAbilityButtonTextures(ability.slot, data.passive)

    ability.name = data.name
    ability.plainName = data.plainName
    ability.nameLabel:SetText(data.name)
    ability.alert.skillType = data.skillType
    ability.alert.lineIndex = data.lineIndex
    ability.alert.index = data.abilityIndex
    ability.purchased = data.purchased
    ability.passive = data.passive
    ability.ultimate = data.ultimate
    local isTheSame = ability.progressionIndex == data.progressionIndex
    ability.progressionIndex = data.progressionIndex

    local slot = ability.slot

    slot.skillType = data.skillType
    slot.lineIndex = data.lineIndex
    slot.index = data.abilityIndex
    slot.icon:SetTexture(data.icon)
    slot.iconFile = data.icon

    ability:ClearAnchors()

    if data.progressionIndex then
        ability.xpBar:SetHidden(false)

        local lastXP, nextXP, currentXP, atMorph = GetAbilityProgressionXPInfo(data.progressionIndex)
        local _, morph, rank = GetAbilityProgressionInfo(data.progressionIndex)
        local wasAbilityRespecced = ability.morph and ability.morph > morph or false

        ZO_SkillInfoXPBar_SetValue(ability.xpBar, rank, lastXP, nextXP, currentXP, not isTheSame or wasAbilityRespecced)
        ability.atMorph = atMorph
        ability.morph = morph
        ability.nameLabel:SetAnchor(LEFT, ability.slot, RIGHT, 10, -10)
    else
        ability.xpBar:SetHidden(true)
        ZO_SkillInfoXPBar_SetValue(ability.xpBar, nil, 0, 1, 0, FORCE_INIT_SMOOTH_STATUS_BAR)
        ability.atMorph = false
        ability.nameLabel:SetAnchor(LEFT, ability.slot, RIGHT, 10, 0)
    end

    ability.upgradeAvailable = data.nextUpgradeEarnedRank and data.lineRank >= data.nextUpgradeEarnedRank
    
    if ability.purchased then
        slot:SetEnabled(true)

        ZO_ActionSlot_SetUnusable(slot.icon, false)

        ability.nameLabel:SetColor(PURCHASED_COLOR:UnpackRGBA())

        if ability.atMorph and self.availablePoints > 0 then
            ability.alert:SetHidden(false)
            ability.lock:SetHidden(true)
            ZO_Skills_SetAlertButtonTextures(ability.alert, ALERT_TEXTURES[ZO_SKILLS_MORPH_STATE])
        elseif ability.upgradeAvailable and self.availablePoints > 0 then
            ability.alert:SetHidden(false)
            ability.lock:SetHidden(true)
            ZO_Skills_SetAlertButtonTextures(ability.alert, ALERT_TEXTURES[ZO_SKILLS_PURCHASE_STATE])
        else
            ability.alert:SetHidden(true)
            ability.lock:SetHidden(true)
        end
    else
        slot:SetEnabled(false)
        ZO_ActionSlot_SetUnusable(slot.icon, true)

        if data.lineRank >= data.earnedRank then
            ability.nameLabel:SetColor(UNPURCHASED_COLOR:UnpackRGBA())

            ability.lock:SetHidden(true)

            if self.availablePoints > 0 then
                ability.alert:SetHidden(false)
                ZO_Skills_SetAlertButtonTextures(ability.alert, ALERT_TEXTURES[ZO_SKILLS_PURCHASE_STATE])
            else
                ability.alert:SetHidden(true)
            end
        else
            ability.nameLabel:SetColor(LOCKED_COLOR:UnpackRGBA())

            ability.alert:SetHidden(true)
            ability.lock:SetHidden(false)
        end
    end
end

function ZO_SkillsManager:SetupHeaderEntry(header, data)
    local label = GetControl(header, "Label")

    if data.passive then
        label:SetText(GetString(SI_SKILLS_PASSIVE_ABILITIES))
    elseif data.ultimate then
        label:SetText(GetString(SI_SKILLS_ULTIMATE_ABILITIES))
    else
        label:SetText(GetString(SI_SKILLS_ACTIVE_ABILITIES))
    end
end

function ZO_SkillsManager:UpdateSkyShards()
    self.skyShardsLabel:SetText(zo_strformat(SI_SKILLS_SKY_SHARDS_COLLECTED, self.skyShards))
end

function ZO_SkillsManager:RefreshSkillInfo()
    if self.container:IsHidden() then
        self.dirty = true
        return
    end

    local skillType = self:GetSelectedSkillType()
    local skillIndex = self:GetSelectedSkillLineIndex()

    local lineName, lineRank = GetSkillLineInfo(skillType, skillIndex)
    local lastXP, nextXP, currentXP = GetSkillLineXPInfo(skillType, skillIndex)

    self.skillInfo.name:SetText(zo_strformat(SI_SKILLS_ENTRY_LINE_NAME_FORMAT, lineName))
    local isTheSame = self.skillInfo.xpBar:GetControl().skillType == skillType and self.skillInfo.xpBar:GetControl().skillIndex == skillIndex
    self.skillInfo.xpBar:GetControl().skillType = skillType
    self.skillInfo.xpBar:GetControl().skillIndex = skillIndex
    ZO_SkillInfoXPBar_SetValue(self.skillInfo.xpBar, lineRank, lastXP, nextXP, currentXP, not isTheSame)

    self.availablePoints = GetAvailableSkillPoints()
    self.availablePointsLabel:SetText(zo_strformat(SI_SKILLS_POINTS_TO_SPEND, self.availablePoints))

    self.skyShards = GetNumSkyShards()
    self:UpdateSkyShards()

    if SkillTooltip:GetOwner() == self.skillInfo.xpBar:GetControl() then
        ZO_SkillInfoXPBar_OnMouseEnter(self.skillInfo.xpBar:GetControl())
    end
end

function ZO_SkillsManager:RefreshList()
    if self.container:IsHidden() then
        self.dirty = true
        return
    end

    if not IsActionBarSlottingAllowed() then
        self.abilityList:SetHidden(true)
        return
    else
        self.abilityList:SetHidden(false)
    end

    local skillType = self:GetSelectedSkillType()
    local skillIndex = self:GetSelectedSkillLineIndex()

    local _, lineRank = GetSkillLineInfo(skillType, skillIndex)

    local scrollData = ZO_ScrollList_GetDataList(self.abilityList)
    ZO_ScrollList_Clear(self.abilityList)
    self.displayedAbilityProgressions = {}

    local numAbilities = GetNumSkillAbilities(skillType, skillIndex)

    local foundFirstActive = false
    local foundFirstPassive = false
    local foundFirstUltimate = false

    for i = 1, numAbilities do
        local name, icon, earnedRank, passive, ultimate, purchased, progressionIndex = GetSkillAbilityInfo(skillType, skillIndex, i)
        local currentUpgradeLevel, maxUpgradeLevel = GetSkillAbilityUpgradeInfo(skillType, skillIndex, i)
        local _, _, nextUpgradeEarnedRank = GetSkillAbilityNextUpgradeInfo(skillType, skillIndex, i)

        local plainName = zo_strformat(SI_ABILITY_NAME, name)
        name = ZO_Skills_GenerateAbilityName(SI_ABILITY_NAME_AND_UPGRADE_LEVELS, name, currentUpgradeLevel, maxUpgradeLevel, progressionIndex)

        if not (currentUpgradeLevel and maxUpgradeLevel) and progressionIndex then
            self.displayedAbilityProgressions[progressionIndex] = true
        end

        local isActive = (not passive and not ultimate)
        local isUltimate = (not passive and ultimate)

        local addHeader = (isActive and not foundFirstActive) or (passive and not foundFirstPassive) or (isUltimate and not foundFirstUltimate)
        if addHeader then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILL_HEADER_DATA,  {
                                                                                            passive = passive,
                                                                                            ultimate = isUltimate
                                                                                        }))
        end

        foundFirstActive = foundFirstActive or isActive
        foundFirstPassive = foundFirstPassive or passive
        foundFirstUltimate = foundFirstUltimate or isUltimate

        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(SKILL_ABILITY_DATA,  {
                                                                                        skillType = skillType,
                                                                                        lineIndex = skillIndex,
                                                                                        abilityIndex = i,
                                                                                        plainName = plainName,
                                                                                        name = name,
                                                                                        icon = icon,
                                                                                        earnedRank = earnedRank,
                                                                                        passive = passive,
                                                                                        ultimate = ultimate,
                                                                                        purchased = purchased,
                                                                                        progressionIndex = progressionIndex,
                                                                                        lineRank = lineRank,
                                                                                        nextUpgradeEarnedRank = nextUpgradeEarnedRank,
                                                                                    }))
    end

    ZO_ScrollList_Commit(self.abilityList)
end

function ZO_SkillsManager:GetSelectedSkillType()
    local selectedData = self.navigationTree:GetSelectedData()
    if selectedData then
        return selectedData.skillType
    end
end

function ZO_SkillsManager:GetSelectedSkillLineIndex()
    local selectedData = self.navigationTree:GetSelectedData()
    if selectedData then
        return selectedData.skillLineIndex
    end
end

function ZO_SkillsManager:Refresh()
    if self.container:IsHidden() then
        self.dirty = true
        return
    end

    if IsActionBarSlottingAllowed() then
        self.warning:SetHidden(true)
    else
        self.warning:SetText(GetString(SI_SKILLS_DISABLED_SPECIAL_ABILITIES))
        self.warning:SetHidden(false)
    end

    self.navigationTree:Reset()
    for skillType = 1, GetNumSkillTypes() do
        local numSkillLines = GetNumSkillLines(skillType)
        local parent
        for skillLineIndex = 1, numSkillLines do
            local _, _, discovered = GetSkillLineInfo(skillType, skillLineIndex)
            if discovered then
                if not parent then
                    parent = self.navigationTree:AddNode("ZO_SkillIconHeader", skillType, nil, skillTypeToSound[skillType])
                end
                self.navigationTree:AddNode("ZO_SkillsNavigationEntry", { skillType = skillType, skillLineIndex = skillLineIndex }, parent, SOUNDS.SKILL_LINE_SELECT)
            end
        end
    end

    self.navigationTree:Commit()

    self:RefreshSkillInfo()
    self:RefreshList()
end

function ZO_SkillsManager:OnShown()
    if self.dirty then
        self:Refresh()
    end
end

local function SetMorphButtonTextures(button, chosen)
    if chosen then
        ZO_ActionSlot_SetUnusable(button.icon, false)
        button.selectedCallout:SetHidden(false)
    else
        ZO_ActionSlot_SetUnusable(button.icon, true)
        button.selectedCallout:SetHidden(true)
    end
end

function ZO_SkillsManager:ChooseMorph(morphSlot)
    if morphSlot then
        self.morphDialog.chosenMorphProgressionIndex = morphSlot.progressionIndex
        self.morphDialog.chosenMorph = morphSlot.morph

        if morphSlot == self.morphDialog.morphAbility1 then
            SetMorphButtonTextures(self.morphDialog.morphAbility1, true)
            SetMorphButtonTextures(self.morphDialog.morphAbility2, false)
        else
            SetMorphButtonTextures(self.morphDialog.morphAbility1, false)
            SetMorphButtonTextures(self.morphDialog.morphAbility2, true)
        end

        self.morphDialog.confirmButton:SetState(BSTATE_NORMAL)
    end
end

function ZO_Skills_AbilitySlot_OnMouseEnter(control)
    InitializeTooltip(SkillTooltip, control, TOPLEFT, 5, -5, TOPRIGHT)
    SkillTooltip:SetSkillAbility(control.skillType, control.lineIndex, control.index)
end

function ZO_Skills_AbilitySlot_OnMouseExit()
    ClearTooltip(SkillTooltip)
end

function ZO_Skills_UpgradeAbilitySlot_OnMouseEnter(control)
    InitializeTooltip(SkillTooltip, control, TOPLEFT, 5, -5, TOPRIGHT)
    SkillTooltip:SetSkillUpgradeAbility(control.skillType, control.lineIndex, control.index)
end

function ZO_Skills_UpgradeAbilitySlot_OnMouseExit()
    ClearTooltip(SkillTooltip)
end

function ZO_Skills_AbilitySlot_OnDragStart(control)
    if(GetCursorContentType() == MOUSE_CONTENT_EMPTY) then
        if ZO_Skills_AbilityFailsWerewolfRequirement(control.skillType, control.lineIndex) then
            ZO_Skills_OnlyWerewolfAbilitiesAllowedAlert()
        else
            PickupAbilityBySkillLine(control.skillType, control.lineIndex, control.index)
        end
    end
end

function ZO_Skills_AbilitySlot_OnDoubleClick(control)
    local ability = control.ability
    if ability.purchased and not ability.passive then
        if ZO_Skills_AbilityFailsWerewolfRequirement(control.skillType, control.lineIndex) then
            ZO_Skills_OnlyWerewolfAbilitiesAllowedAlert()
        else
            local slot = GetFirstFreeValidSlotForSkillAbility(control.skillType, control.lineIndex, control.index)
            if slot then
                SlotSkillAbilityInSlot(control.skillType, control.lineIndex, control.index, slot)
            end
        end
    end
end

function ZO_Skills_AbilitySlot_OnClick(control)
    local ability = control.ability
    if ability.purchased and not ability.passive then
        ClearMenu()
        if not ZO_Skills_AbilityFailsWerewolfRequirement(control.skillType, control.lineIndex) then
            if ability.ultimate then
                AddMenuItem(GetString(SI_SKILL_ABILITY_ASSIGN_TO_ULTIMATE_SLOT), function() SelectSlotSkillAbility(control.skillType, control.lineIndex, control.index, ACTION_BAR_ULTIMATE_SLOT_INDEX + 1) end)
            else
                local slot = GetFirstFreeValidSlotForSkillAbility(control.skillType, control.lineIndex, control.index)
                if slot then
                    AddMenuItem(GetString(SI_SKILL_ABILITY_ASSIGN_TO_EMPTY_SLOT), function() SlotSkillAbilityInSlot(control.skillType, control.lineIndex, control.index, slot) end)
                end

                for i = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX, ACTION_BAR_ULTIMATE_SLOT_INDEX - 1 do
                    AddMenuItem(zo_strformat(SI_SKILL_ABILITY_ASSIGN_TO_SLOT, i - 1), function() SelectSlotSkillAbility(control.skillType, control.lineIndex, control.index, i + 1) end)
                end
            end
        else
            ZO_Skills_OnlyWerewolfAbilitiesAllowedAlert()
        end
        ShowMenu(control)
    end
end

function ZO_Skills_AbilityAlert_OnClicked(control)
    if not control.ability.purchased then
        ZO_Dialogs_ShowDialog("PURCHASE_ABILITY_CONFIRM", control)
    elseif control.ability.atMorph then
        ZO_Dialogs_ShowDialog("MORPH_ABILITY_CONFIRM", control)
    elseif control.ability.upgradeAvailable then
        ZO_Dialogs_ShowDialog("UPGRADE_ABILITY_CONFIRM", control)
    end
end

function ZO_Skills_MorphAbilitySlot_OnMouseEnter(control)
    InitializeTooltip(SkillTooltip, control, TOPLEFT, 5, -5, TOPRIGHT)
    SkillTooltip:SetProgressionAbility(control.progressionIndex, control.morph, control.rank)
end

function ZO_Skills_MorphAbilitySlot_OnClicked(control)
    SKILLS_WINDOW:ChooseMorph(control)
end

function ZO_SkillInfoXPBar_OnMouseEnter(control)
    InitializeTooltip(SkillTooltip, control, TOPLEFT, 15, 5, BOTTOMLEFT)
    SkillTooltip:SetSkillLine(control.skillType, control.skillIndex)
end

function ZO_SkillInfoXPBar_OnMouseExit(control)
    ClearTooltip(SkillTooltip)
end

function ZO_Skills_OnShown(self)
    SKILLS_WINDOW:OnShown()
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