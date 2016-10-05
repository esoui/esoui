--Attribute Spinners

local ZO_AttributeSpinner_Keyboard = ZO_AttributeSpinner_Shared:Subclass()

function ZO_AttributeSpinner_Keyboard:New(attributeControl, attributeType, attributeManager, valueChangedCallback)
    local attributeSpinner = ZO_AttributeSpinner_Shared.New(self, attributeControl, attributeType, attributeManager, valueChangedCallback)
    attributeSpinner:SetSpinner(ZO_Spinner:New(attributeControl.spinner, 0, 0, false))
    return attributeSpinner
end

function ZO_AttributeSpinner_Keyboard:OnMouseWheel(delta)
    self.pointsSpinner:OnMouseWheel(delta)
end

function ZO_AttributeSpinner_Keyboard:SetEnabled(enabled)
    self.pointsSpinner:SetEnabled(enabled)
end

--Stats

ZO_Stats = ZO_Stats_Common:Subclass()

function ZO_Stats:New(...)
    local stats = ZO_Object.New(self)
    stats:Initialize(...)
    return stats
end

function ZO_Stats:Initialize(control)
    ZO_Stats_Common.Initialize(self, control)
    self.control = control

    control:SetHandler("OnEffectivelyShown", function() self:OnShown() end)
end

function ZO_Stats:OnShown()
    if not self.initialized then
        self.initialized = true

        self.scrollChild = self.control:GetNamedChild("PaneScrollChild")
        self.attributeControls = {}
        self.statEntries = {}        

        self:SetUpTitleSection()

        self:AddDivider()
        self:CreateBackgroundSection()
        self:AddDivider()
        self:CreateAttributesSection()
        self:AddDivider()
        self:CreateMountSection()
        self:AddDivider()
        self:CreateActiveEffectsSection()

        self:InitializeKeybindButtons()

        self.control:RegisterForEvent(EVENT_ATTRIBUTE_UPGRADE_UPDATED, function() self:UpdateSpendablePoints() end)
        self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, function() self:RefreshTitleSection() end)
    end

    self:UpdateSpendablePoints()
    self:RefreshEquipmentBonus()

    TriggerTutorial(TUTORIAL_TRIGGER_STATS_OPENED)
    if GetAttributeUnspentPoints() > 0 then
        TriggerTutorial(TUTORIAL_TRIGGER_STATS_OPENED_AND_ATTRIBUTE_POINTS_UNSPENT)
    end
end

function ZO_Stats:InitializeKeybindButtons()
    self.keybindButtons = {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Commit
        {
            name = GetString(SI_STATS_COMMIT_ATTRIBUTES_BUTTON),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function() 
                            return self:GetAddedPoints() > 0
                       end,
            callback = function()
                            self:PurchaseAttributes()
                        end,
        },
    }

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindButtons)

    local function OnStateChange(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindButtons)
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindButtons)
        end
    end
    STATS_SCENE:RegisterCallback("StateChange", OnStateChange)
end

function ZO_Stats:SetUpTitleSection()
    local titleSectionControl = self.control:GetNamedChild("TitleSection")
    local allianceIconControl = titleSectionControl:GetNamedChild("AllianceIcon")
    self.allianceIconControl = allianceIconControl
    local nameControl = titleSectionControl:GetNamedChild("Name")
    local raceClassControl = titleSectionControl:GetNamedChild("RaceClass")

    nameControl:SetText(GetUnitName("player"))
    raceClassControl:SetText(zo_strformat(SI_STATS_RACE_CLASS, GetUnitRace("player"), GetUnitClass("player")))
    allianceIconControl:SetHandler("OnMouseEnter", function(control)
        local playerAlliance = GetUnitAlliance("player")
        InitializeTooltip(InformationTooltip, control, RIGHT, -5, 0)
        SetTooltipText(InformationTooltip, zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(playerAlliance)))
    end)
    allianceIconControl:SetHandler("OnMouseExit", function(control)
        ClearTooltip(InformationTooltip)
    end)

    self.equipmentBonus = titleSectionControl:GetNamedChild("EquipmentBonus")
    local equipmentBonusIcons = self.equipmentBonus:GetNamedChild("Icons")
    self.equipmentBonus.iconPool = ZO_ControlPool:New("ZO_StatsEquipmentBonusIcon", equipmentBonusIcons)
    self.equipmentBonus.value = EQUIPMENT_SCORE_LOW
    self.equipmentBonus.lowestEquipSlot = EQUIP_SLOT_NONE

    self:RefreshTitleSection()
end

function ZO_Stats:SetEquipmentBonusTooltip()
    InformationTooltip:AddLine(GetString(SI_STATS_EQUIPMENT_BONUS), "", ZO_NORMAL_TEXT:UnpackRGBA())
    InformationTooltip:AddVerticalPadding(10)

    InformationTooltip:AddLine(GetString("SI_EQUIPMENTBONUS", self.equipmentBonus.value))
    InformationTooltip:AddVerticalPadding(10)

    InformationTooltip:AddLine(GetString(SI_STATS_EQUIPMENT_BONUS_GENERAL_TOOLTIP))
    InformationTooltip:AddVerticalPadding(10)

    if self.equipmentBonus.value < EQUIPMENT_BONUS_SUPERIOR and self.equipmentBonus.lowestEquipSlot ~= EQUIP_SLOT_NONE then
        local equipSlotHasItem = select(2, GetEquippedItemInfo(self.equipmentBonus.lowestEquipSlot))
        local lowestItemText
        if equipSlotHasItem then
            local lowestItemLink = GetItemLink(BAG_WORN, self.equipmentBonus.lowestEquipSlot)
            lowestItemText = GetItemLinkName(lowestItemLink)
            local quality = GetItemLinkQuality(lowestItemLink)
            local qualityColor = GetItemQualityColor(quality)
            lowestItemText = qualityColor:Colorize(lowestItemText)
        else
            lowestItemText = zo_strformat(SI_STATS_EQUIPMENT_BONUS_TOOLTIP_EMPTY_SLOT, GetString("SI_EQUIPSLOT", self.equipmentBonus.lowestEquipSlot))
            lowestItemText = ZO_ERROR_COLOR:Colorize(lowestItemText)
        end
        InformationTooltip:AddLine(zo_strformat(SI_STATS_EQUIPMENT_BONUS_LOWEST_PIECE_KEYBOARD, lowestItemText), "", ZO_NORMAL_TEXT:UnpackRGBA())
    end
end

function ZO_Stats:RefreshTitleSection()
    local playerAlliance = GetUnitAlliance("player")
    self.allianceIconControl:SetTexture(GetLargeAllianceSymbolIcon(playerAlliance))
end

function ZO_Stats:CreateBackgroundSection()
    self:AddHeader(SI_STATS_BACKGROUND)

    local dropdownRow = self:AddDropdownRow(GetString(SI_STATS_TITLE))
    dropdownRow.dropdown:SetSortsItems(false)

    local function UpdateSelectedTitle()
        self:UpdateTitleDropdownSelection(dropdownRow.dropdown)
    end

    local function UpdateTitles()
        self:UpdateTitleDropdownTitles(dropdownRow.dropdown)
    end

    UpdateTitles()

    local iconRow = self:AddIconRow(GetString(SI_STATS_ALLIANCE_RANK))
    
    local function UpdateRank()
        local rank, subRank = GetUnitAvARank("player")

        if rank == 0 then
            iconRow.icon:SetHidden(true)
        else
            iconRow.icon:SetHidden(false)
            iconRow.icon:SetTexture(GetAvARankIcon(rank))
        end

        iconRow.value:SetText(zo_strformat(SI_STAT_RANK_NAME_FORMAT, GetAvARankName(GetUnitGender("player"), rank)))
    end

    UpdateRank()

    local bountyRow = self:AddBountyRow(GetString(SI_STATS_BOUNTY_LABEL))

    self.control:RegisterForEvent(EVENT_TITLE_UPDATE, function(_, unitTag) if(unitTag == "player") then UpdateSelectedTitle() end end)
    self.control:RegisterForEvent(EVENT_PLAYER_TITLES_UPDATE, UpdateTitles)
    self.control:RegisterForEvent(EVENT_RANK_POINT_UPDATE, function(eventCode, unitTag) if unitTag == "player" then UpdateRank() end end)
end

function ZO_Stats:CreateAttributesSection()
    self.attributesHeader = self:CreateControlFromVirtual("Header", "ZO_AttributesHeader")
    self.attributesHeaderTitle = self.attributesHeader:GetNamedChild("Title")
    self.attributesHeaderPointsLabel = self.attributesHeader:GetNamedChild("AttributePointsLabel")
    self.attributesHeaderPointsValue = self.attributesHeader:GetNamedChild("AttributePointsValue")

    self.attributesHeaderTitle.text = { GetString(SI_STATS_ATTRIBUTES), GetString(SI_STATS_ATTRIBUTES_LEVEL_UP) }
    self.attributesHeaderTitleTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_AttributesHeaderCrossFade", self.attributesHeaderTitle)
    self:UpdateAttributesHeader()

    self:SetNextControlPadding(20)

    local attributesRow = self:CreateControlFromVirtual("AttributesRow", "ZO_StatsAttributesRow")
    self:SetUpAttributeControl(attributesRow:GetNamedChild("Health"), STAT_HEALTH_MAX, ATTRIBUTE_HEALTH, POWERTYPE_HEALTH)
    self:SetUpAttributeControl(attributesRow:GetNamedChild("Magicka"), STAT_MAGICKA_MAX, ATTRIBUTE_MAGICKA, POWERTYPE_MAGICKA)
    self:SetUpAttributeControl(attributesRow:GetNamedChild("Stamina"), STAT_STAMINA_MAX, ATTRIBUTE_STAMINA, POWERTYPE_STAMINA)

    self:SetNextControlPadding(20)

    self:AddStatRow(STAT_MAGICKA_MAX, STAT_MAGICKA_REGEN_COMBAT)
    self:SetNextControlPadding(0)
    self:AddStatRow(STAT_HEALTH_MAX, STAT_HEALTH_REGEN_COMBAT)
    self:SetNextControlPadding(0)
    self:AddStatRow(STAT_STAMINA_MAX, STAT_STAMINA_REGEN_COMBAT)
    self:SetNextControlPadding(20)
    self:AddStatRow(STAT_SPELL_POWER, STAT_POWER)
    self:SetNextControlPadding(0)
    self:AddStatRow(STAT_SPELL_CRITICAL, STAT_CRITICAL_STRIKE)
    self:SetNextControlPadding(20)
    self:AddStatRow(STAT_SPELL_RESIST, STAT_PHYSICAL_RESIST)
    self:AddStatRow(STAT_CRITICAL_RESISTANCE)
end

function ZO_Stats:UpdateSpendablePoints()
    self:UpdateAttributesHeader()

    local totalSpendablePoints = self:GetTotalSpendablePoints()

    self:ResetAllAttributes()
    for i = 1, #self.attributeControls do
        self.attributeControls[i].pointLimitedSpinner:RefreshPoints()
        self.attributeControls[i].pointLimitedSpinner:SetButtonsHidden(totalSpendablePoints == 0)
        self.attributeControls[i].increaseHighlight:SetHidden(totalSpendablePoints == 0)
    end
end

function ZO_Stats:UpdateAttributesHeader()
    local totalSpendablePoints = self:GetTotalSpendablePoints()

    if(self.attributesHeaderTitle ~= nil and totalSpendablePoints ~= nil) then
        local shouldAnimate = totalSpendablePoints > 0
        local attributesHeaderTitle = self.attributesHeaderTitle
        local attributesHeaderTitleTimeline = self.attributesHeaderTitleTimeline
        local isAnimating = attributesHeaderTitleTimeline:IsPlaying()
        if(shouldAnimate ~= isAnimating) then
            if(shouldAnimate) then
                attributesHeaderTitle.textIndex = 1
                attributesHeaderTitle:SetText(attributesHeaderTitle.text[1])
                attributesHeaderTitleTimeline:PlayFromStart()
            else
                attributesHeaderTitleTimeline:Stop()
                attributesHeaderTitle:SetText(attributesHeaderTitle.text[1])
                attributesHeaderTitle:SetAlpha(1)
            end
        end
    end
end

function ZO_Stats:ResetAllAttributes()
    for i = 1, #self.attributeControls do
        local attributeControl = self.attributeControls[i]
        attributeControl.pointLimitedSpinner:ResetAddedPoints()        
        self:UpdatePendingStatBonuses(attributeControl.statType, 0)
    end
    
    self:SetAvailablePoints(self:GetTotalSpendablePoints())
end

function ZO_Stats:GetAddedPoints()
    local points = 0
    for i = 1, #self.attributeControls do
        points = points + self.attributeControls[i].pointLimitedSpinner.addedPoints
    end
    return points
end

function ZO_Stats:PurchaseAttributes()
    PlaySound(SOUNDS.STATS_PURCHASE)
    PurchaseAttributes(self.attributeControls[ATTRIBUTE_HEALTH].pointLimitedSpinner.addedPoints, self.attributeControls[ATTRIBUTE_MAGICKA].pointLimitedSpinner.addedPoints, self.attributeControls[ATTRIBUTE_STAMINA].pointLimitedSpinner.addedPoints)
    zo_callLater(function()
        if(SCENE_MANAGER:IsShowing("stats") and self:GetTotalSpendablePoints() == 0) then
            MAIN_MENU_KEYBOARD:ShowScene("skills")
        end
    end, 1000)
end

function ZO_Stats:RefreshAllAttributes()
    for _, statEntry in pairs(self.statEntries) do
        statEntry:UpdateStatValue()
    end
end

function ZO_Stats:SetSpinnersEnabled(enabled)
    local totalSpendablePoints = self:GetTotalSpendablePoints()

    for i = 1, #self.attributeControls do
        local attributeControl = self.attributeControls[i]
        attributeControl.pointLimitedSpinner:SetEnabled(enabled)
        attributeControl.increaseHighlight:SetHidden(true)
    end
end

local BAR_TEXTURES =
{
    [POWERTYPE_HEALTH] = "EsoUI/Art/Stats/stats_healthBar.dds",
    [POWERTYPE_MAGICKA] = "EsoUI/Art/Stats/stats_magickaBar.dds",
    [POWERTYPE_STAMINA] = "EsoUI/Art/Stats/stats_staminaBar.dds",
}

function ZO_Stats:SetUpAttributeControl(attributeControl, statType, attributeType, powerType)
    attributeControl.pointLimitedSpinner = ZO_AttributeSpinner_Keyboard:New(attributeControl, attributeType, self)
    attributeControl.name:SetText(GetString("SI_ATTRIBUTES", attributeType))
    attributeControl.statType = statType
    attributeControl.attributeType = attributeType
    attributeControl.powerType = powerType    
    attributeControl.bar:SetTexture(BAR_TEXTURES[powerType])    

    attributeControl.spinner:SetHandler("OnMouseEnter", function() self:RefreshSpinnerMaxes() end)

    self.attributeControls[#self.attributeControls + 1] = attributeControl
end

function ZO_Stats:RefreshSpinnerMaxes()
    for i = 1, #self.attributeControls do
        self.attributeControls[i].pointLimitedSpinner:RefreshSpinnerMax()
        self.attributeControls[i].increaseHighlight:SetHidden(true)
    end
end

function ZO_Stats:OnSetAvailablePoints()
    self.attributesHeaderPointsValue:SetText(tostring(self:GetAvailablePoints()))
    self:RefreshSpinnerMaxes()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindButtons)
end

function ZO_Stats:UpdatePendingStatBonuses(statType, pendingBonus)
    local statEntry = self.statEntries[statType]
    if statEntry then
        self:SetPendingStatBonuses(statType, pendingBonus)
        statEntry:UpdateStatValue()        
    end
end

function ZO_Stats:CreateMountSection()
    self:AddHeader(SI_STATS_RIDING_SKILL)

    local stableRow = self:CreateControlFromVirtual("StableRow", "ZO_StatsStableSlotRow")

    self:SetNextControlPadding(10)

    local function UpdateRidingSkills()
        local timeUntilCanBeTrained, totalTrainedWaitDuration = GetTimeUntilCanBeTrained()
        local speedBonus, _, staminaBonus, _, inventoryBonus = STABLE_MANAGER:GetStats()

        stableRow.speedStatLabel:SetText(zo_strformat(SI_MOUNT_ATTRIBUTE_SPEED_FORMAT, speedBonus))
        stableRow.staminaStatLabel:SetText(staminaBonus)
        stableRow.carryStatLabel:SetText(inventoryBonus)

        local ridingSkillMaxedOut = STABLE_MANAGER:IsRidingSkillMaxedOut()
        if timeUntilCanBeTrained == 0 then
            stableRow.readyForTrain:SetHidden(ridingSkillMaxedOut)
            stableRow.timer:SetHidden(true)
        else
            stableRow.readyForTrain:SetHidden(true)
            stableRow.timer:SetHidden(ridingSkillMaxedOut)
            if not ridingSkillMaxedOut then
                stableRow.timerOverlay:StartCooldown(timeUntilCanBeTrained, totalTrainedWaitDuration, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_UNTIL, NO_LEADING_EDGE)
            end
        end
    end

    local function OnUpdate()
        local timeUntilCanBeTrained = GetTimeUntilCanBeTrained()

        if timeUntilCanBeTrained > 0 then
            if stableRow.timer.mouseInside then
                local timeLeft = ZO_FormatTimeMilliseconds(timeUntilCanBeTrained, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
                InformationTooltip:ClearLines()
                SetTooltipText(InformationTooltip, zo_strformat(SI_STABLE_NOT_TRAINABLE_TOOLTIP, timeLeft))
            end
        end
    end

    UpdateRidingSkills()

    stableRow.timer:SetHandler("OnUpdate", OnUpdate)
    STABLE_MANAGER:RegisterCallback("StableMountInfoUpdated", UpdateRidingSkills)
end

function ZO_Stats:CreateActiveEffectsSection()
    self:AddHeader(SI_STATS_ACTIVE_EFFECTS)

    local activeEffects = self:CreateControlFromVirtual("ActiveEffects", "ZO_StatsActiveEffects")
    local effectsRowPool = ZO_ControlPool:New("ZO_StatsActiveEffectRow", activeEffects)
    self:AddLongTermEffects(activeEffects, effectsRowPool)
end

function ZO_Stats:AddDivider()
    if(self.lastControl == nil) then
        self:SetNextControlPadding(2)
    else
        self:SetNextControlPadding(15)
    end
    
    return self:CreateControlFromVirtual("Divider", "ZO_WideHorizontalDivider")
end

function ZO_Stats:AddHeader(text, optionalTemplate)
    self:SetNextControlPadding(-3)
    local header = self:CreateControlFromVirtual("Header", "ZO_StatsHeader")
    header:SetText(GetString(text))
    return header
end

function ZO_Stats:AddDropdownRow(rowName)
    local dropdownRow = self:CreateControlFromVirtual("DropdownRow", "ZO_StatsDropdownRow")
    dropdownRow.name:SetText(rowName)
    return dropdownRow
end

function ZO_Stats:AddIconRow(rowName)
    local iconRow = self:CreateControlFromVirtual("IconRow", "ZO_StatsIconRow")
    iconRow.name:SetText(rowName)
    return iconRow
end

function ZO_Stats:AddBountyRow(rowName)
    local bountyRow = self:CreateControlFromVirtual("BountyRow", "ZO_StatsBountyRow")
    bountyRow.name:SetText(rowName)
    return bountyRow
end

function ZO_Stats:SetNextControlPadding(padding)
    self.nextControlPadding = padding
end

function ZO_Stats:AddRawControl(control)
    if self.lastControl then
        control:SetAnchor(TOP, self.lastControl, BOTTOM, 0, self.nextControlPadding or 5)
    else
        control:SetAnchor(TOP, self.lastControl, TOP, 0, self.nextControlPadding or 5)
    end
    self.nextControlPadding = 5
    self.lastControl = control
    return control
end

function ZO_Stats:CreateControlFromVirtual(controlType, template)
    local numControlTypeName = "num" .. controlType
    self[numControlTypeName] = (self[numControlTypeName] or 0) + 1 
    return self:AddRawControl(CreateControlFromVirtual("$(parent)", self.scrollChild, template, controlType .. self[numControlTypeName]))
end

function ZO_Stats:AddStatRow(statType1, statType2)
    local row = self:CreateControlFromVirtual("StatsRow", "ZO_StatsRow")
    if statType1 then
        self.statEntries[statType1] = ZO_StatEntry_Keyboard:New(row:GetNamedChild("Stat1"), statType1, self)
        self:UpdatePendingStatBonuses(statType1, 0)
    end
    if statType2 then
        self.statEntries[statType2] = ZO_StatEntry_Keyboard:New(row:GetNamedChild("Stat2"), statType2, self)
        self:UpdatePendingStatBonuses(statType2, 0)
    end
end

local function EffectsRowComparator(left, right)
    local leftIsArtificial, rightIsArtificial = left.isArtificial, right.isArtificial
    if leftIsArtificial ~= rightIsArtificial then
        --Artificial before real
        return leftIsArtificial
    else
        if leftIsArtificial then
            --Both artificial, use def defined sort order
            return left.sortOrder < right.sortOrder
        else
            --Both real, use time
            return left.time.endTime < right.time.endTime
        end
    end
end

function ZO_Stats:AddLongTermEffects(container, effectsRowPool)
    local function UpdateEffects(eventCode, changeType, buffSlot, buffName, unitTag, startTime, endTime, stackCount, iconFile, buffType, effectType, abilityType, statusEffectType)
        if (not unitTag or unitTag == "player") and not container:IsHidden() then
            effectsRowPool:ReleaseAllObjects()
            
            local effectsRows = {}

            --Artificial effects--
            for effectId in ZO_GetNextActiveArtificialEffectIdIter do
                local displayName, iconFile, effectType, sortOrder = GetArtificialEffectInfo(effectId)
                local effectsRow = effectsRowPool:AcquireObject()
                effectsRow.name:SetText(zo_strformat(SI_ABILITY_TOOLTIP_NAME, displayName))
                effectsRow.icon:SetTexture(iconFile)
                effectsRow.effectType = effectType
                effectsRow.time:SetHidden(true)
                effectsRow.sortOrder = sortOrder
                effectsRow.tooltipTitle = displayName
                effectsRow.effectId = effectId
                effectsRow.isArtificial = true

                table.insert(effectsRows, effectsRow)
            end

            for i = 1, GetNumBuffs("player") do
                local buffName, startTime, endTime, buffSlot, stackCount, iconFile, buffType, effectType, abilityType, statusEffectType = GetUnitBuffInfo("player", i)

                if buffSlot > 0 and buffName ~= "" then
                    local effectsRow = effectsRowPool:AcquireObject()
                    effectsRow.name:SetText(zo_strformat(SI_ABILITY_TOOLTIP_NAME, buffName))
                    effectsRow.icon:SetTexture(iconFile)

                    local duration = startTime - endTime
                    effectsRow.time:SetHidden(duration == 0)
                    effectsRow.time.endTime = endTime
                    effectsRow.effectType = effectType
                    effectsRow.buffSlot = buffSlot
                    effectsRow.isArtificial = false

                    table.insert(effectsRows, effectsRow)
                end
            end

            table.sort(effectsRows, EffectsRowComparator)
            local prevRow
            for i, effectsRow in ipairs(effectsRows) do
                if(prevRow) then
                    effectsRow:SetAnchor(TOPLEFT, prevRow, BOTTOMLEFT)
                else
                    effectsRow:SetAnchor(TOPLEFT, nil, TOPLEFT, 5, 0)
                end
                effectsRow:SetHidden(false)

                prevRow = effectsRow
            end

        end
    end

    container:RegisterForEvent(EVENT_EFFECT_CHANGED, UpdateEffects)
    container:RegisterForEvent(EVENT_EFFECTS_FULL_UPDATE, UpdateEffects)
    container:RegisterForEvent(EVENT_ARTIFICIAL_EFFECT_ADDED, UpdateEffects)
    container:RegisterForEvent(EVENT_ARTIFICIAL_EFFECT_REMOVED, UpdateEffects)
    container:SetHandler("OnEffectivelyShown", UpdateEffects)
end

function ZO_Stats_Initialize(control)
    STATS = ZO_Stats:New(control)
end

function ZO_Stats_EquipmentBonus_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOMRIGHT, 0, -5, TOPRIGHT)
    STATS:SetEquipmentBonusTooltip()
end

function ZO_Stats_EquipmentBonus_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end

local ATTRIBUTE_DESCRIPTIONS =
{
    [ATTRIBUTE_HEALTH] = SI_ATTRIBUTE_TOOLTIP_HEALTH,
    [ATTRIBUTE_MAGICKA] = SI_ATTRIBUTE_TOOLTIP_MAGICKA,
    [ATTRIBUTE_STAMINA] = SI_ATTRIBUTE_TOOLTIP_STAMINA,
}

function ZO_StatsAttribute_OnMouseEnter(control)
    local attributeType = control.attributeType
    local attributeName = GetString("SI_ATTRIBUTES", attributeType)

    InitializeTooltip(InformationTooltip, control, RIGHT, -5)
    InformationTooltip:AddLine(attributeName, "", ZO_NORMAL_TEXT:UnpackRGBA())
    InformationTooltip:AddLine(GetString(ATTRIBUTE_DESCRIPTIONS[attributeType]))
end

function ZO_StatsAttribute_OnMouseExit()
    ClearTooltip(InformationTooltip)
end

function ZO_StatsActiveEffect_OnMouseEnter(control)
    InitializeTooltip(GameTooltip, control, RIGHT, -15)
    if control.isArtificial then
        local tooltipText = GetArtificialEffectTooltipText(control.effectId)
        GameTooltip:AddLine(control.tooltipTitle, "", ZO_SELECTED_TEXT:UnpackRGBA())
        GameTooltip:AddLine(tooltipText, "", ZO_NORMAL_TEXT:UnpackRGBA())
    else
        GameTooltip:SetBuff(control.buffSlot, "player")
    end

    if not control.animation then
        control.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ShowOnMouseOverLabelAnimation", control:GetNamedChild("Highlight"))
    end
    control.animation:PlayForward()
end

function ZO_StatsActiveEffect_OnMouseExit(control)
    ClearTooltip(GameTooltip)
    control.animation:PlayBackward()
end

function ZO_StatsActiveEffect_OnMouseUp(control, button, upInside)
    if upInside and button == MOUSE_BUTTON_INDEX_RIGHT and not control.isArtificial then
        CancelBuff(control.buffSlot)
    end
end

function ZO_Stats_InitializeRidingSkills(control)
    control.speedStatLabel = control:GetNamedChild("SpeedInfo"):GetNamedChild("Stat")
    control.staminaStatLabel = control:GetNamedChild("StaminaInfo"):GetNamedChild("Stat")
    control.carryStatLabel = control:GetNamedChild("CarryInfo"):GetNamedChild("Stat")
    control.timer = control:GetNamedChild("Timer")
    control.timerOverlay = control.timer:GetNamedChild("Overlay")
    control.readyForTrain = control:GetNamedChild("ReadyForTrain")
end

-- Infamy and bounty meters

function ZO_Stats_BountyDisplay_Initialize(control)
    STATS_BOUNTY_DISPLAY = ZO_BountyDisplay:New(control, false)
end
