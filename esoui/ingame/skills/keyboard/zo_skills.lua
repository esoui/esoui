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

function ZO_SkillsManager:Initialize(container)
    SKILLS_FRAGMENT = ZO_FadeSceneFragment:New(container)

    self.displayedAbilityProgressions = {}

    self.container = container
    self.availablePoints = 0
    self.skyShards = 0
    self.availablePointsLabel = GetControl(container, "AvailablePoints")
    self.skyShardsLabel = GetControl(container, "SkyShards")
    self.abilityList = GetControl(container, "AbilityList")
    self.advisedOverlayControl = container:GetNamedChild("SkillLineAdvisedOverlay")
    self.skillLineUnlockTitleControl = self.advisedOverlayControl:GetNamedChild("SkillLineUnlockTitle")
    self.skillLineUnlockTextControl = self.advisedOverlayControl:GetNamedChild("SkillLineUnlockText")
    self.showAdvisorInAdvancedMode = false

    self.navigationContainer = GetControl(container, "NavigationContainer")
    self.navigationTree = ZO_Tree:New(self.navigationContainer:GetNamedChild("ScrollChild"), 74, -10, 300)
    self.skillTypeToNode = {}

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
        local name, _, _, _, advised = GetSkillLineInfo(data.skillType, data.skillLineIndex)
        control:SetText(zo_strformat(SI_SKILLS_TREE_NAME_FORMAT, name))

        control.statusIcon:ClearIcons()

        if NEW_SKILL_CALLOUTS:IsSkillLineNew(data.skillType, data.skillLineIndex) or advised then
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

    ZO_ScrollList_Initialize(self.abilityList)
    ZO_ScrollList_AddDataType(self.abilityList, SKILL_ABILITY_DATA, "ZO_Skills_Ability", 70, function(control, data) self:SetupAbilityEntry(control, data, ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE) end)
    ZO_ScrollList_AddDataType(self.abilityList, SKILL_HEADER_DATA, "ZO_Skills_AbilityTypeHeader", 32, function(control, data) self:SetupHeaderEntry(control, data) end)
    ZO_ScrollList_AddResizeOnScreenResize(self.abilityList)

    self.warning = GetControl(container, "Warning")

    -- initialize dialogs
    ZO_Skills_InitializeKeyboardMorphDialog()
    ZO_Skills_InitializeKeyboardConfirmDialog()
    ZO_Skills_InitializeKeyboardUpgradeDialog()

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
    container:RegisterForEvent(EVENT_SKILL_BUILD_SELECTION_UPDATED, function(eventId, ...) 
        self.showAdvisorInAdvancedMode = false
        self:UpdateSkillsAdvisorVisibility() 
    end)
    container:RegisterForEvent(EVENT_ACTIVE_WEAPON_PAIR_CHANGED, function()
        TUTORIAL_SYSTEM:RemoveTutorialByTrigger(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_WEAPON_SWAP_SHOWN_IN_SKILLS_AFTER_UNLOCK)
    end)

    -- callbacks
    local function OnNewStatusChanged()
        self.navigationTree:RefreshVisible()
        MAIN_MENU_KEYBOARD:RefreshCategoryIndicators()
    end

    NEW_SKILL_CALLOUTS:RegisterCallback("OnSkillLineNewStatusChanged", OnNewStatusChanged)
    NEW_SKILL_CALLOUTS:RegisterCallback("OnAbilityUpdatedStatusChanged", OnNewStatusChanged)

    do
    --Weapon Swap Tutorial Setup
        local tutorialAnchor = ZO_Anchor:New(RIGHT, ZO_ActionBar1WeaponSwap, LEFT, -10, 0)
        TUTORIAL_SYSTEM:RegisterTriggerLayoutInfo(TUTORIAL_TYPE_POINTER_BOX, TUTORIAL_TRIGGER_WEAPON_SWAP_SHOWN_IN_SKILLS_AFTER_UNLOCK, self.container, SKILLS_FRAGMENT, tutorialAnchor)
    end

    self:InitializeKeybindDescriptors()
end

function ZO_SkillsManager:UpdateSkillsAdvisorVisibility()
    if not IsInGamepadPreferredMode() then
        if not ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() or self.showAdvisorInAdvancedMode then
            SCENE_MANAGER:RemoveFragment(FRAME_TARGET_STANDARD_RIGHT_PANEL_FRAGMENT)
            SCENE_MANAGER:AddFragment(FRAME_TARGET_SKILLS_RIGHT_PANEL_FRAGMENT)
            SCENE_MANAGER:AddFragment(SKILLS_ADVISOR_FRAGMENT)
        else
            SCENE_MANAGER:RemoveFragment(SKILLS_ADVISOR_FRAGMENT)
            SCENE_MANAGER:RemoveFragment(FRAME_TARGET_SKILLS_RIGHT_PANEL_FRAGMENT)
            SCENE_MANAGER:AddFragment(FRAME_TARGET_STANDARD_RIGHT_PANEL_FRAGMENT)
        end
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_SkillsManager:IsSkillsAdvisorShown()
    return not ZO_SKILLS_ADVISOR_SINGLETON:IsAdvancedModeSelected() or self.showAdvisorInAdvancedMode
end 

function ZO_SkillsManager:InitializeKeybindDescriptors()
    self.keybindStripDescriptor =
    {
		alignment = KEYBIND_STRIP_ALIGN_LEFT,

		{
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

function ZO_SkillsManager:StopSelectedSkillBuildSkillAnimations()
    if self.selectedSkillBuildIconTimeline and self.selectedSkillBuildIconTimeline:IsPlaying() then
        self.selectedSkillBuildIconTimeline:Stop()
    end

    if self.selectedSkillBuildIconLoopTimeline and self.selectedSkillBuildIconLoopTimeline:IsPlaying() then
        self.selectedSkillBuildIconLoopTimeline:Stop()
    end

    if self.selectedSkillBuildAlertTimeline and self.selectedSkillBuildAlertTimeline:IsPlaying() then
        self.selectedSkillBuildAlertTimeline:Stop()
    end

    if self.selectedSkillBuildAlertLoopTimeline and self.selectedSkillBuildAlertLoopTimeline:IsPlaying() then
        self.selectedSkillBuildAlertLoopTimeline:Stop()
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
        local textureFile = ""
        local loopTextureFile = ""

        if abilityControl.passive then
            if ZO_SKILLS_ADVISOR_SINGLETON:IsAbilityInSelectedSkillBuild(abilityControl.skillType, abilityControl.lineIndex, abilityControl.index, abilityControl.skillBuildMorphChoice, abilityControl.skillBuildRankIndex) then
                textureFile = "EsoUI/Art/SkillsAdvisor/animation_circle_1024x64_FLASH.dds"
                loopTextureFile = "EsoUI/Art/SkillsAdvisor/animation_circle_4096x64.dds"
            else
                textureFile = "EsoUI/Art/SkillsAdvisor/animation_circleSingle_1024x64_FLASH.dds"
                loopTextureFile = "EsoUI/Art/SkillsAdvisor/animation_circleSingle_4096x64.dds"
            end
        else
            if ZO_SKILLS_ADVISOR_SINGLETON:IsAbilityInSelectedSkillBuild(abilityControl.skillType, abilityControl.lineIndex, abilityControl.index, abilityControl.skillBuildMorphChoice, abilityControl.skillBuildRankIndex) then
                textureFile = "EsoUI/Art/SkillsAdvisor/animation_square_1024x64_FLASH.dds"
                loopTextureFile = "EsoUI/Art/SkillsAdvisor/animation_square_4096x64.dds"
            else
                textureFile = "EsoUI/Art/SkillsAdvisor/animation_squareSingle_1024x64_FLASH.dds"
                loopTextureFile = "EsoUI/Art/SkillsAdvisor/animation_squareSingle_4096x64.dds"
            end
        end
        iconAnimationObject:SetAnimatedControl(abilitySlotAnimTexture)
        iconAnimationLoopObject:SetAnimatedControl(abilitySlotAnimTexture)

        local function OnStopIcon(timeline, completedPlaying)
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

        -- Alert Animation Setup
        if abilityControl.alert.iconStatus ~= ZO_SKILL_ABILITY_ALERT_ICON_NONE then
            if not self.selectedSkillBuildAlertTimeline then 
                self.selectedSkillBuildAlertTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("SkillBuildSelectionAlertAnim")
            end

            if not self.selectedSkillBuildAlertLoopTimeline then 
                self.selectedSkillBuildAlertLoopTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("SkillBuildSelectionAlertLoopAnim")
            end

            local alertAnimationObject = self.selectedSkillBuildAlertTimeline:GetFirstAnimation()
            local alertAnimationLoopObject = self.selectedSkillBuildAlertLoopTimeline:GetFirstAnimation()
            local abilityAlertAnimTexture = abilityControl:GetNamedChild("SelectedSkillBuildAlertAnim")
            local showAlertAnimation = true
            local alertTexture = ""
            local alertTextureLoop = ""
            if abilityControl.alert.iconStatus == ZO_SKILL_ABILITY_ALERT_ICON_ADD then
                alertTexture = "EsoUI/Art/SkillsAdvisor/animation_add_1024x64_FLASH.dds"
                alertTextureLoop = "EsoUI/Art/SkillsAdvisor/animation_add_4096x64.dds"
            elseif abilityControl.alert.iconStatus == ZO_SKILL_ABILITY_ALERT_ICON_MORPH then
                alertTexture = "EsoUI/Art/SkillsAdvisor/animation_morph_1024x64_FLASH.dds"
                alertTextureLoop = "EsoUI/Art/SkillsAdvisor/animation_morph_4096x64.dds"
            else
                showAlertAnimation = false
            end
            alertAnimationObject:SetAnimatedControl(abilityAlertAnimTexture)
            alertAnimationLoopObject:SetAnimatedControl(abilityAlertAnimTexture)
                
            local function OnStopAlert(timeline, completedPlaying)
                abilityAlertAnimTexture:SetTexture(alertTextureLoop)
                if completedPlaying then
                    skillsObject.selectedSkillBuildAlertLoopTimeline:PlayFromStart()
                else
                    abilityAlertAnimTexture:SetHidden(true)
                end
            end
            self.selectedSkillBuildAlertTimeline:SetHandler("OnStop", OnStopAlert)

            local function OnLoopStopAlert()
                abilityAlertAnimTexture:SetHidden(true)
            end
            self.selectedSkillBuildAlertLoopTimeline:SetHandler("OnStop", OnLoopStopAlert)

            if showAlertAnimation then
                abilityAlertAnimTexture:SetTexture(alertTexture)
                abilityAlertAnimTexture:SetHidden(false)
                self.selectedSkillBuildAlertTimeline:PlayFromStart()
            end
        end
    end
end

function ZO_SkillsManager:OnSkillLineSet(skillType, skillIndex, abilityIndex)
    -- Set navigationTree to category containing skill and refresh abilityList
    local selectedData = self.navigationTree:GetSelectedData()
    if skillType ~= selectedData.skillType or skillIndex ~= selectedData.skillLineIndex then
        if self.skillTypeToNode[skillType] and self.skillTypeToNode[skillType][skillIndex] then
            self:StopSelectedSkillBuildSkillAnimations()
            self.navigationTree:SelectNode(self.skillTypeToNode[skillType][skillIndex])
        else
            -- SkillLine is not known or yet advised
            self.selectAbilityData = 
            {
                skillType = skillType,
                skillIndex = skillIndex,
                abilityIndex = abilityIndex,
            }
            local ADVISE_SKILL_LINE = true
            SetAdviseSkillLine(skillType, skillIndex, ADVISE_SKILL_LINE)
            return
        end
    end

    self:ScrollToSkillLineAbility(skillType, skillIndex, abilityIndex)
end

function ZO_SkillsManager:ScrollToSkillLineAbility(skillType, skillIndex, abilityIndex)
    -- Get DataIndex of set ability in abilityList and scroll that index into view
    local dataIndex = nil
    local dataValue = nil
    for index, data in ipairs(self.abilityList.data) do
        if data.data.skillType == skillType and data.data.lineIndex == skillIndex and data.data.abilityIndex == abilityIndex then
            dataIndex = index
            dataValue = data.data
            break
        end
    end

    local function PlaySkillBuildAnimation(successfulAnimateInView)
        if successfulAnimateInView then
            -- Play Glow Animation on selected skill
            local abilityControl = ZO_ScrollList_GetDataControl(self.abilityList, dataValue)
            self:PlaySelectedSkillBuildSkillAnimations(abilityControl)
            self:FireCallbacks("OnReadyToHandleClickAction")
        end
    end

    if dataIndex then
        ZO_ScrollList_ScrollDataToCenter(self.abilityList, dataIndex, PlaySkillBuildAnimation)
    end

    self:RefreshSkillLineDisplay(skillType, skillIndex)
end

function ZO_SkillsManager:SetupAbilityEntry(ability, data, displayView)
    if not displayView then
        displayView = ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE
    end

    ability.name = data.name
    ability.plainName = data.plainName
    ability.nameLabel:SetText(data.name)
    ability.skillType = data.skillType
    ability.lineIndex = data.lineIndex
    ability.index = data.abilityIndex
    ability.skillBuildRankIndex = data.skillBuildRankIndex
    ability.skillBuildMorphChoice = data.skillBuildMorphChoice

    ability.alert.skillType = data.skillType
    ability.alert.lineIndex = data.lineIndex
    ability.alert.index = data.abilityIndex
    ability.alert.iconStatus = ZO_SKILL_ABILITY_ALERT_ICON_NONE
    ability.purchased = data.purchased
    ability.passive = data.passive
    ability.ultimate = data.ultimate
    local isTheSame = ability.progressionIndex == data.progressionIndex
    ability.progressionIndex = data.progressionIndex
    ability.upgradeAvailable = data.nextUpgradeEarnedRank and data.lineRank >= data.nextUpgradeEarnedRank
    ability.atMorph = nil
    ability.morph = nil

    local slot = ability.slot

    slot.skillType = data.skillType
    slot.lineIndex = data.lineIndex
    slot.index = data.abilityIndex
    slot.abilityId = data.abilityId
    slot.skillBuildRankIndex = data.skillBuildRankIndex
    slot.skillBuildMorphChoice = data.skillBuildMorphChoice
    slot.icon:SetTexture(data.icon)
    slot.iconFile = data.icon

    ZO_Skills_SetKeyboardAbilityButtonTextures(ability.slot, data.passive)

    ability:ClearAnchors()

    if data.progressionIndex then
        local lastXP, nextXP, currentXP, atMorph = GetAbilityProgressionXPInfo(data.progressionIndex)
        local _, morph, rank = GetAbilityProgressionInfo(data.progressionIndex)
        ability.atMorph = atMorph
        ability.morph = morph

        if displayView == ZO_SKILL_ABILITY_DISPLAY_INTERACTIVE then
            ability.xpBar:SetHidden(false)
            local wasAbilityRespecced = ability.morph and ability.morph > morph or false
            ZO_SkillInfoXPBar_SetValue(ability.xpBar, rank, lastXP, nextXP, currentXP, not isTheSame or wasAbilityRespecced)
        else
            ZO_SkillInfoXPBar_SetValue(ability.xpBar, nil, 0, 1, 0, FORCE_INIT_SMOOTH_STATUS_BAR)
        end
    else
        ability.xpBar:SetHidden(true)
    end

    if displayView == ZO_SKILL_ABILITY_DISPLAY_VIEW then
        ability.xpBar:SetHidden(true)
        ability.nameLabel:SetAnchor(LEFT, ability.slot, RIGHT, 10, 0)
        ability.slot:SetMouseOverTexture(nil)
    else
        local offsetY = data.progressionIndex and -10 or 0
        ability.nameLabel:SetAnchor(LEFT, ability.slot, RIGHT, 10, offsetY)
    end

    local morphControl = ability:GetNamedChild("Morph")
    ZO_Skills_SetUpAbilityEntry(data.skillType, data.lineIndex, data.abilityIndex, data.skillBuildMorphChoice, data.skillBuildRankIndex, slot.icon, ability.nameLabel, ability.alert, ability.lock, morphControl, displayView, ZO_SKILLS_KEYBOARD)
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

    local lineName, lineRank, _, _, advised = GetSkillLineInfo(skillType, skillIndex)
    local lastXP, nextXP, currentXP = GetSkillLineXPInfo(skillType, skillIndex)

    self.skillInfo.name:SetText(zo_strformat(SI_SKILLS_ENTRY_LINE_NAME_FORMAT, lineName))
    local isTheSame = self.skillInfo.xpBar:GetControl().skillType == skillType and self.skillInfo.xpBar:GetControl().skillIndex == skillIndex
    self.skillInfo.xpBar:GetControl().skillType = skillType
    self.skillInfo.xpBar:GetControl().skillIndex = skillIndex
    if advised then
        local RANK_NOT_SHOWN = 1
        local CURRENT_XP_NOT_SHOWN = 0  
        ZO_SkillInfoXPBar_SetValue(self.skillInfo.xpBar, RANK_NOT_SHOWN, lastXP, nextXP, CURRENT_XP_NOT_SHOWN, not isTheSame)
    else
        ZO_SkillInfoXPBar_SetValue(self.skillInfo.xpBar, lineRank, lastXP, nextXP, currentXP, not isTheSame)
    end

    self.availablePoints = GetAvailableSkillPoints()
    self.availablePointsLabel:SetText(zo_strformat(SI_SKILLS_POINTS_TO_SPEND, self.availablePoints))

    self.skyShards = GetNumSkyShards()
    self:UpdateSkyShards()

    if SkillTooltip:GetOwner() == self.skillInfo.xpBar:GetControl() then
        ZO_SkillInfoXPBar_OnMouseEnter(self.skillInfo.xpBar:GetControl())
    end
end

function ZO_SkillsManager:RefreshList()
    self:StopSelectedSkillBuildSkillAnimations()

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

    self:RefreshSkillLineDisplay(skillType, skillIndex)
end

function ZO_SkillsManager:RefreshSkillLineDisplay(skillType, skillIndex)
    local name, _, available, _, advised, unlockText = GetSkillLineInfo(skillType, skillIndex)
    if not available and advised then
        self:StopSelectedSkillBuildSkillAnimations()
        self.skillLineUnlockTitleControl:SetText(zo_strformat(SI_SKILLS_ADVISOR_SKILL_NOT_DISCOVERED_NAME, name))
        self.skillLineUnlockTextControl:SetText(zo_strformat(SI_SKILLS_ADVISOR_SKILL_NOT_DISCOVERED_DESCRIPTION, unlockText))
        self.advisedOverlayControl:SetHidden(false)
        self.abilityList:SetAlpha(0.1)
    else
        self.advisedOverlayControl:SetHidden(true)
        self.abilityList:SetAlpha(1)
    end 
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
    self.skillTypeToNode = {}
    for skillType = 1, GetNumSkillTypes() do
        local numSkillLines = GetNumSkillLines(skillType)
        local parent
        for skillLineIndex = 1, numSkillLines do
            local _, _, available, _, advised = GetSkillLineInfo(skillType, skillLineIndex)
            if available or advised then
                if not parent then
                    parent = self.navigationTree:AddNode("ZO_SkillIconHeader", skillType, nil, skillTypeToSound[skillType])
                end
                local node = self.navigationTree:AddNode("ZO_SkillsNavigationEntry", { skillType = skillType, skillLineIndex = skillLineIndex }, parent, SOUNDS.SKILL_LINE_SELECT)
            
                if not self.skillTypeToNode[skillType] then
                    self.skillTypeToNode[skillType] = {}
                end
                self.skillTypeToNode[skillType][skillLineIndex] = node
            end
        end
    end

    self.navigationTree:Commit()

    self:RefreshSkillInfo()
    self:RefreshList()

    if self.selectAbilityData ~= nil then
        self.navigationTree:SelectNode(self.skillTypeToNode[self.selectAbilityData.skillType][self.selectAbilityData.skillIndex])
        self:ScrollToSkillLineAbility(self.selectAbilityData.skillType, self.selectAbilityData.skillIndex, self.selectAbilityData.abilityIndex)
        self.selectAbilityData = nil
    end
end

function ZO_SkillsManager:OnShown()
    if self:IsSkillsAdvisorShown() then
        SCENE_MANAGER:AddFragment(FRAME_TARGET_SKILLS_RIGHT_PANEL_FRAGMENT)
    else
        SCENE_MANAGER:AddFragment(FRAME_TARGET_STANDARD_RIGHT_PANEL_FRAGMENT)
    end
    SCENE_MANAGER:AddFragment(FRAME_PLAYER_FRAGMENT)

    if self.dirty then
        self:Refresh()
    end
    self:UpdateSkillsAdvisorVisibility()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    
    local level = GetUnitLevel("player")
    if level >= GetWeaponSwapUnlockedLevel() then
        TriggerTutorial(TUTORIAL_TRIGGER_WEAPON_SWAP_SHOWN_IN_SKILLS_AFTER_UNLOCK)
    end
end

function ZO_SkillsManager:OnHidden()
    self:StopSelectedSkillBuildSkillAnimations()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
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
        local dialogControl = ZO_SkillsMorphDialog
        dialogControl.chosenMorphProgressionIndex = morphSlot.progressionIndex
        dialogControl.chosenMorph = morphSlot.morph

        if morphSlot == dialogControl.morphAbility1 then
            SetMorphButtonTextures(dialogControl.morphAbility1, true)
            SetMorphButtonTextures(dialogControl.morphAbility2, false)
        else
            SetMorphButtonTextures(dialogControl.morphAbility1, false)
            SetMorphButtonTextures(dialogControl.morphAbility2, true)
        end

        dialogControl.confirmButton:SetState(BSTATE_NORMAL)
    end
end

function ZO_Skills_AbilitySlot_OnMouseEnter(control)
    SKILLS_WINDOW:StopSelectedSkillBuildSkillAnimations()

    InitializeTooltip(SkillTooltip, control, TOPLEFT, 5, -5, TOPRIGHT)

    local isBadMorph = control.ability and control.ability.alert and control.ability.alert.iconStatus == ZO_SKILL_ABILITY_ALERT_ICON_BAD_MORPH
    SkillTooltip:SetSkillAbility(control.skillType, control.lineIndex, control.index, isBadMorph)
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
    SKILLS_WINDOW:StopSelectedSkillBuildSkillAnimations()

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
    SkillTooltip:SetProgressionAbility(control.progressionIndex, control.morph, control.rank, control.showAdvice, control.advised)
end

function ZO_Skills_MorphAbilitySlot_OnClicked(control)
    SKILLS_WINDOW:ChooseMorph(control)
end

function ZO_SkillInfoXPBar_OnMouseEnter(control)
    SKILLS_WINDOW:StopSelectedSkillBuildSkillAnimations()
    InitializeTooltip(SkillTooltip, control, TOPLEFT, 15, 5, BOTTOMLEFT)
    SkillTooltip:SetSkillLine(control.skillType, control.skillIndex)
end

function ZO_SkillInfoXPBar_OnMouseExit(control)
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