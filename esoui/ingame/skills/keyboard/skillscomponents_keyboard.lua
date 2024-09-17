function ZO_SkillInfoXPBar_OnMouseEnter(control)
    -- Verify that the control has skillLineData and is truly visible for systems like Universal Deconstruction that do not show/hide the XP bar.
    if control.skillLineData and control:GetAlpha() > 0 then
        SKILLS_WINDOW:StopSelectedSkillBuildSkillAnimations() -- TODO: Companions, remove direct skills reference
        InitializeTooltip(SkillTooltip, control, TOPLEFT, 15, 5, BOTTOMLEFT)
        SkillTooltip:SetSkillLineById(control.skillLineData:GetId())
    end
end

function ZO_SkillInfoXPBar_OnMouseExit()
    ClearTooltip(SkillTooltip)
end

function ZO_SkillLineInfo_Keyboard_Refresh(skillLineInfo, skillLineData, forceInit)
    local lastRankXP, nextRankXP, currentRankXP = skillLineData:GetRankXPValues()

    skillLineInfo.name:SetText(skillLineData:GetFormattedName())
    local skillInfoXPBar = skillLineInfo.xpBar
    local skillInfoXPBarControl = skillInfoXPBar:GetControl()
    local dontWrap = skillInfoXPBarControl.skillLineData ~= skillLineData or forceInit
    skillInfoXPBarControl.skillLineData = skillLineData
    if skillLineData:IsAvailable() then
        ZO_SkillInfoXPBar_SetValue(skillInfoXPBar, skillLineData:GetCurrentRank(), lastRankXP, nextRankXP, currentRankXP, dontWrap)
    elseif skillLineData:IsAdvised() then
        local RANK_NOT_SHOWN = 1
        local CURRENT_XP_NOT_SHOWN = 0
        ZO_SkillInfoXPBar_SetValue(skillInfoXPBar, RANK_NOT_SHOWN, lastRankXP, nextRankXP, CURRENT_XP_NOT_SHOWN, dontWrap)
    end

    if SkillTooltip:GetOwner() == skillInfoXPBarControl then
        ZO_SkillInfoXPBar_OnMouseEnter(skillInfoXPBarControl)
    end
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

-- ZO_Skills_AbilitySlot
function ZO_Skills_AbilitySlot_OnMouseEnter(control)
    SKILLS_WINDOW:StopSelectedSkillBuildSkillAnimations() -- TODO: Companions, remove direct skills reference
    InitializeTooltip(SkillTooltip, control, TOPLEFT, 5, -5, TOPRIGHT)

    local SHOW_SKILL_POINT_COST = true
    local DONT_SHOW_UPGRADE_TEXT = false
    local DONT_SHOW_ADVISED = false
    local SHOW_BAD_MORPH = true
    control.skillProgressionData:SetKeyboardTooltip(SkillTooltip, SHOW_SKILL_POINT_COST, DONT_SHOW_UPGRADE_TEXT, DONT_SHOW_ADVISED, SHOW_BAD_MORPH)

    local skillData = control.skillProgressionData.skillData
    if skillData:HasUpdatedStatus() then
        skillData:SetUpdatedStatusByType(ZO_SKILL_DATA_NEW_STATE.MORPHABLE, false)
        skillData:SetUpdatedStatusByType(ZO_SKILL_DATA_NEW_STATE.CRAFTED_ABILITY, false)
        control.statusIcon:SetHidden(not skillData:HasUpdatedStatus())
    end
end

function ZO_Skills_AbilitySlot_OnMouseExit()
    ClearTooltip(SkillTooltip)
end

-- AbilityEntry
-- An ability entry represents a skill data in a list, and provides controls for manipulating them.
function ZO_Skills_AbilityEntry_OnInitialized(control)
    control.nameLabel = control:GetNamedChild("Name")
    control.increaseButton = control:GetNamedChild("Increase")
    control.decreaseButton = control:GetNamedChild("Decrease")
    control.slot = control:GetNamedChild("Slot")
    control.slotIcon = control:GetNamedChild("SlotIcon")
    control.slotLock = control:GetNamedChild("SlotLock")
    control.slot.statusIcon = control:GetNamedChild("SlotStatusIcon")
    control.slot.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
    control.skillStyleControl = control:GetNamedChild("SkillStyle")
    control.skillStyleControl.statusIcon = control:GetNamedChild("SkillStyleStatusIcon")
    control.skillStyleControl.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
    control.skillStyleControl.defaultStyleButton = control.skillStyleControl:GetNamedChild("DefaultStyle")
    control.skillStyleControl.selectedStyleButton = control.skillStyleControl:GetNamedChild("SelectedStyle")
    control.skillStyleControl.selectedStyleButton.icon = control.skillStyleControl.selectedStyleButton:GetNamedChild("Icon")

    local xpBarControl = control:GetNamedChild("XPBar")
    control.xpBar = ZO_WrappingStatusBar:New(xpBarControl)
    ZO_StatusBar_SetGradientColor(xpBarControl, ZO_XP_BAR_GRADIENT_COLORS)
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

    function ZO_Skills_AbilityEntry_Setup(control, skillData)
        local skillPointAllocator = skillData:GetPointAllocator()
        local skillProgressionData = skillPointAllocator:GetProgressionData()

        local isPassive = skillData:IsPassive()
        local isActive = not isPassive
        local isPurchased = skillPointAllocator:IsPurchased()
        local isUnlocked = skillProgressionData:IsUnlocked()

        local lastSkillProgressionData = control.skillProgressionData
        control.skillProgressionData = skillProgressionData
        control.slot.skillProgressionData = skillProgressionData
        control.slot.skillData = skillData

        -- slot
        control.slotIcon:SetTexture(skillProgressionData:GetIcon())
        ZO_Skills_SetKeyboardAbilityButtonTextures(control.slot)
        ZO_ActionSlot_SetUnusable(control.slotIcon, not isPurchased)
        control.slot:SetEnabled(isPurchased and isActive)
        control.slotLock:SetHidden(isUnlocked)

        local hasSlotStatusUpdated = skillData:HasUpdatedStatusByType(ZO_SKILL_DATA_NEW_STATE.MORPHABLE) or skillData:HasUpdatedStatusByType(ZO_SKILL_DATA_NEW_STATE.CRAFTED_ABILITY)
        control.slot.statusIcon:SetHidden(not hasSlotStatusUpdated)

        if skillProgressionData:IsActive() and skillProgressionData:HasAnyNonHiddenSkillStyles() then
            local collectibleData = skillProgressionData:GetSelectedSkillStyleCollectibleData()
            if collectibleData then
                control.skillStyleControl.selectedStyleButton.icon:SetTexture(collectibleData:GetIcon())
            end
        end

        -- xp bar
        local showXPBar = skillProgressionData:HasRankData()
        if showXPBar then
            local currentRank = skillProgressionData:GetCurrentRank()
            local startXP, endXP = skillProgressionData:GetRankXPExtents(currentRank)
            local currentXP = skillProgressionData:GetCurrentXP()
            local dontWrap = lastSkillProgressionData ~= skillProgressionData

            control.xpBar:SetHidden(false)
            ZO_SkillInfoXPBar_SetValue(control.xpBar, currentRank, startXP, endXP, currentXP, dontWrap)
        else
            local NO_LEVEL = nil
            local START_XP = 0
            local END_XP = 1
            local NO_XP = 0
            local DONT_WRAP = true

            control.xpBar:SetHidden(true)
            ZO_SkillInfoXPBar_SetValue(control.xpBar, NO_LEVEL, START_XP, END_XP, NO_XP, DONT_WRAP)
        end

        -- name
        local detailedName = skillProgressionData:GetDetailedName()
        control.nameLabel:SetText(detailedName)
        local offsetY = showXPBar and -10 or 0
        control.nameLabel:SetAnchor(LEFT, control.slot, RIGHT, 10, offsetY)

        if isPurchased then
            control.nameLabel:SetColor(PURCHASED_COLOR:UnpackRGBA())
        else
            if isUnlocked then
                control.nameLabel:SetColor(UNPURCHASED_COLOR:UnpackRGBA())
            else 
                control.nameLabel:SetColor(LOCKED_COLOR:UnpackRGBA())
            end
        end

        -- increase/decrease buttons
        local increaseButton = control.increaseButton
        local decreaseButton = control.decreaseButton
        local hideIncreaseButton = true
        local hideDecreaseButton = true
        local canPurchase = skillPointAllocator:CanPurchase()
        local canIncreaseRank = skillPointAllocator:CanIncreaseRank()
        local canMorph = skillPointAllocator:CanMorph()
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

        -- Don't show skill style functionality if in respec mode (decrease button showing)
        local skillStyleControl = control.skillStyleControl
        if hideDecreaseButton then
            skillStyleControl:ClearAnchors()
            if hideIncreaseButton then
                skillStyleControl:SetAnchor(RIGHT, control.slot, LEFT, -12)
            else
                skillStyleControl:SetAnchor(RIGHT, increaseButton, LEFT)
            end

            if isActive and skillProgressionData:HasAnyNonHiddenSkillStyles() then
                skillStyleControl:SetHidden(false)
                if skillProgressionData:IsSkillStyleSelected() then
                    skillStyleControl.defaultStyleButton:SetHidden(true)
                    skillStyleControl.selectedStyleButton:SetHidden(false)
                else
                    skillStyleControl.defaultStyleButton:SetHidden(false)
                    skillStyleControl.selectedStyleButton:SetHidden(true)
                end
                skillStyleControl.statusIcon:SetHidden(not skillData:HasUpdatedStatusByType(ZO_SKILL_DATA_NEW_STATE.STYLE_COLLECTIBLE))
            else
                skillStyleControl:SetHidden(true)
            end
        else
            skillStyleControl:SetHidden(true)
        end
    end

    function ZO_Skills_CompanionSkillEntry_Setup(control, skillData)
        local skillPointAllocator = skillData:GetPointAllocator()
        local skillProgressionData = skillPointAllocator:GetProgressionData()

        local isPassive = skillData:IsPassive()
        local isActive = not isPassive
        local isPurchased = skillPointAllocator:IsPurchased()
        local isUnlocked = skillProgressionData:IsUnlocked()

        local lastSkillProgressionData = control.skillProgressionData
        control.skillProgressionData = skillProgressionData
        control.slot.skillProgressionData = skillProgressionData

        -- slot
        control.slotIcon:SetTexture(skillProgressionData:GetIcon())
        ZO_Skills_SetKeyboardAbilityButtonTextures(control.slot)
        ZO_ActionSlot_SetUnusable(control.slotIcon, not isPurchased)
        control.slot:SetEnabled(isPurchased and isActive)
        control.slotLock:SetHidden(isUnlocked)

        -- xp bar
        control.xpBar:SetHidden(true)

        -- name
        local detailedName = skillProgressionData:GetDetailedName()
        control.nameLabel:SetText(detailedName)
        control.nameLabel:SetAnchor(LEFT, control.slot, RIGHT, 10, 0)

        if isPurchased then
            control.nameLabel:SetColor(PURCHASED_COLOR:UnpackRGBA())
        else
            if isUnlocked then
                control.nameLabel:SetColor(UNPURCHASED_COLOR:UnpackRGBA())
            else 
                control.nameLabel:SetColor(LOCKED_COLOR:UnpackRGBA())
            end
        end

        -- increase/decrease buttons
        control.increaseButton:SetHidden(true)
        control.decreaseButton:SetHidden(true)
    end
end

-- ability entry callbacks
function ZO_Skills_AbilitySlot_OnDragStart(control)
    if GetCursorContentType() == MOUSE_CONTENT_EMPTY then
        control.skillProgressionData:TryPickup()
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

function ZO_Skills_AbilitySlot_OnMouseUp(control)
    local hotbar = ACTION_BAR_ASSIGNMENT_MANAGER:GetCurrentHotbar()
    local skillData = control.skillProgressionData:GetSkillData()

    local function OnLinkInChat()
        local link = skillData:GetCurrentProgressionLink()
        if internalassert(link, "Unable to generate link for skill.") then
            ZO_LinkHandler_InsertLink(link)
        end
    end

    if skillData:IsPassive() then
        ClearMenu()
        AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), OnLinkInChat)
        ShowMenu(control)
    else
        ClearMenu()
        if skillData:GetPointAllocator():IsPurchased() and control.skillProgressionData == skillData:GetCurrentProgressionData() then
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
        end
        AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), OnLinkInChat)
        ShowMenu(control)
    end
end

function ZO_Skills_AbilityIncrease_OnClicked(control, shift)
    SKILLS_WINDOW:StopSelectedSkillBuildSkillAnimations() -- TODO: Companions, remove direct skills reference
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

function ZO_Skills_SkillStyle_OnClicked(control)
    local skillProgressionData = control:GetParent().skillProgressionData
    local skillData = skillProgressionData:GetSkillData()
    ZO_Dialogs_ShowDialog("SKILL_STYLE_SELECT_KEYBOARD", { skillData = skillData })
end

function ZO_Skills_SkillStyle_OnMouseEnter(control)
    control.statusIcon:SetHidden(true)
    control:GetParent().slot.skillData:SetUpdatedStatusByType(ZO_SKILL_DATA_NEW_STATE.STYLE_COLLECTIBLE, false)
end

function ZO_Skills_SkillStyle_OnMouseExit(control)
    -- TODO SkillStyle: Implement
end

ZO_Skills_SkillLineAdvisedOverlay = ZO_InitializingObject:Subclass()

function ZO_Skills_SkillLineAdvisedOverlay:Initialize(control)
    self.control = control
    self.titleLabel = control:GetNamedChild("Title")
    self.unlockTextLabel = control:GetNamedChild("UnlockText")
end

function ZO_Skills_SkillLineAdvisedOverlay:Show(skillLineData)
    self.titleLabel:SetText(zo_strformat(SI_SKILLS_ADVISOR_SKILL_NOT_DISCOVERED_NAME, skillLineData:GetName()))
    self.unlockTextLabel:SetText(zo_strformat(SI_SKILLS_ADVISOR_SKILL_NOT_DISCOVERED_DESCRIPTION, skillLineData:GetUnlockText()))
    self.control:SetHidden(false)
end

function ZO_Skills_SkillLineAdvisedOverlay:Hide()
    self.control:SetHidden(true)
end
