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

local SHOW_HIDE_INSTANT = 1
local SHOW_HIDE_ANIMATED = 2

ZO_Stats = ZO_Stats_Common:Subclass()

function ZO_Stats:New(...)
    local stats = ZO_Stats_Common.New(self)
    stats:Initialize(...)
    return stats
end

function ZO_Stats:Initialize(control)
    ZO_Stats_Common.Initialize(self, control)
    self.control = control

    STATS_SCENE = ZO_Scene:New("stats", SCENE_MANAGER)
    STATS_FRAGMENT = ZO_FadeSceneFragment:New(control)
    STATS_SCENE:AddFragment(STATS_FRAGMENT)

    STATS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_HIDING then
            self:OnHiding()
        elseif newState == SCENE_HIDDEN then
            self:OnHidden()
        end
    end)
end

function ZO_Stats:OnShowing()
    if not self.initialized then
        self.initialized = true

        self.scroll = self.control:GetNamedChild("Pane")
        self.scrollChild = self.scroll:GetNamedChild("ScrollChild")
        self.attributeControls = {}
        self.statEntries = {}
        self.pendingEquipOutfitIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex()

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

        local function OnPlayerActivated()
            self.resetAddedPoints = true 
            self:UpdateSpendablePoints() 
            self:RefreshTitleSection()
        end

        self.control:RegisterForEvent(EVENT_ATTRIBUTE_UPGRADE_UPDATED, function() self:UpdateSpendablePoints() end)
        self.control:RegisterForEvent(EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

        local function UpdateLevelUpRewards()
            self:UpdateLevelUpRewards()
        end

        ZO_LEVEL_UP_REWARDS_MANAGER:RegisterCallback("OnLevelUpRewardsUpdated", UpdateLevelUpRewards)

        self.control:SetHandler("OnUpdate", function() self:OnUpdate() end)
    end

    self:UpdateSpendablePoints()
    self:RefreshEquipmentBonus()

    self:UpdateLevelUpRewards()

    TriggerTutorial(TUTORIAL_TRIGGER_STATS_OPENED)
    if GetAttributeUnspentPoints() > 0 then
        TriggerTutorial(TUTORIAL_TRIGGER_STATS_OPENED_AND_ATTRIBUTE_POINTS_UNSPENT)
    end

    ZO_ScrollList_ResetToTop(self.scroll)
end

function ZO_Stats:OnHiding()
    if self.attributesPointerBox then
        self.isAttributesHeaderTitleInScrollBounds = nil
    end

    if self.pendingEquipOutfitIndex ~= ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex() then
        if self.pendingEquipOutfitIndex then
            ZO_OUTFIT_MANAGER:EquipOutfit(self.pendingEquipOutfitIndex)
        else
            UnequipOutfit()
        end
    end
end

function ZO_Stats:OnHidden()
    ZO_KEYBOARD_CLAIM_LEVEL_UP_REWARDS:Hide()
end

function ZO_Stats:OnUpdate()
    local attributesHeaderTitleInView = ZO_Scroll_IsControlFullyInView(self.scroll, self.attributesHeaderTitle)
    if attributesHeaderTitleInView ~= self.isAttributesHeaderTitleInScrollBounds then
        self.isAttributesHeaderTitleInScrollBounds = attributesHeaderTitleInView
        self:UpdateSpendAttributePointsTip(SHOW_HIDE_INSTANT)
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
                            return self:GetTotalAddedPoints() > 0
                       end,
            callback = function()
                            self:PurchaseAttributes()
                        end,
        },
         -- Level Up Help
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_LEVEL_UP_REWARDS_HELP_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            visible = function()
                local helpCategoryIndex, helpIndex = GetLevelUpHelpIndicesForLevel(ZO_LEVEL_UP_REWARDS_MANAGER:GetPendingRewardLevel())
                return helpCategoryIndex ~= nil
            end,
            callback = function()
                local helpCategoryIndex, helpIndex = GetLevelUpHelpIndicesForLevel(ZO_LEVEL_UP_REWARDS_MANAGER:GetPendingRewardLevel())
                HELP:ShowSpecificHelp(helpCategoryIndex, helpIndex)
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
    self.equipmentBonus.value = EQUIPMENT_BONUS_LOW
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

    -- Titles --

    local titleDropdownRow = self:AddDropdownRow(GetString(SI_STATS_TITLE))
    titleDropdownRow.dropdown:SetSortsItems(false)

    local function UpdateSelectedTitle()
        self:UpdateTitleDropdownSelection(titleDropdownRow.dropdown)
    end

    local function UpdateTitles()
        self:UpdateTitleDropdownTitles(titleDropdownRow.dropdown)
    end

    UpdateTitles()

    -- Outfits --

    local outfitDropdownRow = self:AddDropdownRow(GetString(SI_OUTFIT_SELECTOR_TITLE))
    local outfitDropdown = outfitDropdownRow.dropdown
    outfitDropdown:SetSortsItems(false)

    local function UpdateEquippedOutfit()
        self.pendingEquipOutfitIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex()
        self:UpdateOutfitDropdownSelection(outfitDropdown)
    end

    local function UpdateOutfits()
        self:UpdateOutfitDropdownOutfits(outfitDropdown)
    end

    UpdateOutfits()

    ZO_OUTFIT_MANAGER:RegisterCallback("RefreshEquippedOutfitIndex", UpdateEquippedOutfit)
    ZO_OUTFIT_MANAGER:RegisterCallback("RefreshOutfits", UpdateOutfits)
    ZO_OUTFIT_MANAGER:RegisterCallback("RefreshOutfitName", UpdateOutfits)
    
    -- Alliance Ranks --

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

    -- Bounty --

    local bountyRow = self:AddBountyRow(GetString(SI_STATS_BOUNTY_LABEL))

    self.control:RegisterForEvent(EVENT_TITLE_UPDATE, UpdateSelectedTitle)
    self.control:AddFilterForEvent(EVENT_TITLE_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
    self.control:RegisterForEvent(EVENT_PLAYER_TITLES_UPDATE, UpdateTitles)
    self.control:RegisterForEvent(EVENT_RANK_POINT_UPDATE, UpdateRank)
    self.control:AddFilterForEvent(EVENT_RANK_POINT_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
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
    self:SetNextControlPadding(0)
    self:AddStatRow(STAT_CRITICAL_RESISTANCE)
end

do
    local IGNORE_CALLBACK = true
    local UNEQUIP_OUTFIT = nil

    function ZO_Stats:UpdateOutfitDropdownSelection(dropdown)
        local equippedOutfitIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex()
        local itemEntries = dropdown:GetItems()
        for i, entry in ipairs(itemEntries) do
            if equippedOutfitIndex == entry.outfitIndex then
                dropdown:SelectItem(entry, IGNORE_CALLBACK)
                break
            end
        end
    end

    function ZO_Stats:UpdateOutfitDropdownOutfits(dropdown)
        dropdown:ClearItems()

        local function OnUnequipOutfitSelected()
            self.pendingEquipOutfitIndex = UNEQUIP_OUTFIT
            ITEM_PREVIEW_KEYBOARD:PreviewUnequipOutfit()
        end
    
        local function OnOutfitEntrySelected(_, _, entry)
            self.pendingEquipOutfitIndex = entry.outfitIndex
            ITEM_PREVIEW_KEYBOARD:PreviewOutfit(entry.outfitIndex)
        end

        local function OnUnlockNewOutfitsSelected(comboBox, name, entry, selectionChanged, oldEntry)
            dropdown:SelectItem(oldEntry)
            ShowMarketAndSearch(GetString(SI_CROWN_STORE_SEARCH_ADDITIONAL_OUTFITS), MARKET_OPEN_OPERATION_UNLOCK_NEW_OUTFIT)
        end

        local unequippedOutfitEntry = ZO_ComboBox:CreateItemEntry(GetString(SI_NO_OUTFIT_EQUIP_ENTRY), OnUnequipOutfitSelected)
        dropdown:AddItem(unequippedOutfitEntry, ZO_COMBOBOX_SUPRESS_UPDATE)

        local equippedOutfitIndex = ZO_OUTFIT_MANAGER:GetEquippedOutfitIndex()
        local defaultEntry = unequippedOutfitEntry

        local numOutfits = ZO_OUTFIT_MANAGER:GetNumOutfits()
        for outfitIndex = 1, numOutfits do
            local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(outfitIndex)
            local entry = ZO_ComboBox:CreateItemEntry(outfitManipulator:GetOutfitName(), OnOutfitEntrySelected)
            entry.outfitIndex = outfitIndex
            dropdown:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE)
            if equippedOutfitIndex == outfitIndex then
                defaultEntry = entry
            end
        end

        if numOutfits < MAX_OUTFIT_UNLOCKS then
            dropdown:AddItem(ZO_ComboBox:CreateItemEntry(GetString(SI_OUTFIT_PURCHASE_MORE_ENTRY), OnUnlockNewOutfitsSelected), ZO_COMBOBOX_SUPRESS_UPDATE)
        end

        dropdown:UpdateItems()
        dropdown:SelectItem(defaultEntry)
    end
end


function ZO_Stats:UpdateSpendablePoints()
    self:UpdateAttributesHeader()
    self:UpdateSpendAttributePointsTip(SHOW_HIDE_ANIMATED)

    if self.resetAddedPoints then
        for i, attributeControl in ipairs(self.attributeControls) do
            attributeControl.pointLimitedSpinner:ResetAddedPoints()
        end
        self.resetAddedPoints = false
    end

    local totalAddedPoints = 0
    for i, attributeControl in ipairs(self.attributeControls) do
        local addedPoints = attributeControl.pointLimitedSpinner:GetAllocatedPoints()
        attributeControl.pointLimitedSpinner:Reinitialize(attributeControl.attributeType, addedPoints)

        totalAddedPoints = totalAddedPoints + addedPoints
    end

    local totalSpendablePoints = self:GetTotalSpendablePoints()
    local availablePoints = totalSpendablePoints - totalAddedPoints
    self:SetAvailablePoints(availablePoints)

    for i, attributeControl in ipairs(self.attributeControls) do
        attributeControl.pointLimitedSpinner:SetButtonsHidden(totalSpendablePoints == 0)
        attributeControl.increaseHighlight:SetHidden(availablePoints == 0)
    end
end

function ZO_Stats:UpdateAttributesHeader()
    local totalSpendablePoints = self:GetTotalSpendablePoints()

    if self.attributesHeaderTitle ~= nil and totalSpendablePoints ~= nil then
        local shouldAnimate = totalSpendablePoints > 0
        local attributesHeaderTitle = self.attributesHeaderTitle
        local attributesHeaderTitleTimeline = self.attributesHeaderTitleTimeline
        local isAnimating = attributesHeaderTitleTimeline:IsPlaying()
        if shouldAnimate ~= isAnimating then
            if shouldAnimate then
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

function ZO_Stats:UpdateSpendAttributePointsTip(showHideMethod)
    local skipAnimation = showHideMethod == SHOW_HIDE_INSTANT
    local totalSpendablePoints = self:GetTotalSpendablePoints()
    if self.attributesHeaderTitle ~= nil and totalSpendablePoints ~= nil and STATS_SCENE:IsShowing() then
        if totalSpendablePoints > 0 and self.isAttributesHeaderTitleInScrollBounds then
            if not self.attributesPointerBox then
                self.attributesPointerBox = POINTER_BOXES:Acquire()
                self.attributesPointerBox:SetContentsControl(self.control:GetNamedChild("AttributesPointerBoxContents"))
                self.attributesPointerBox:SetParent(self.control)
                self.attributesPointerBox:SetHideWithFragment(STATS_FRAGMENT)
                self.attributesPointerBox:SetCloseable(false)
                self.attributesPointerBox:SetAnchor(RIGHT, self.attributesHeaderTitle, LEFT, -10, 0)
                self.attributesPointerBox:Commit()
            end
            self.attributesPointerBox:Show(skipAnimation)
        else
            if self.attributesPointerBox then
                self.attributesPointerBox:Hide(skipAnimation)
            end
        end
    end
end

function ZO_Stats:GetTotalAddedPoints()
    local points = 0
    for i, attributeControl in ipairs(self.attributeControls) do
        points = points + attributeControl.pointLimitedSpinner:GetAllocatedPoints()
    end
    return points
end

function ZO_Stats:PurchaseAttributes()
    PlaySound(SOUNDS.STATS_PURCHASE)
    PurchaseAttributes(self.attributeControls[ATTRIBUTE_HEALTH].pointLimitedSpinner.addedPoints, self.attributeControls[ATTRIBUTE_MAGICKA].pointLimitedSpinner.addedPoints, self.attributeControls[ATTRIBUTE_STAMINA].pointLimitedSpinner.addedPoints)
    self.resetAddedPoints = true
    zo_callLater(function()
        if SCENE_MANAGER:IsShowing("stats") and self:GetTotalSpendablePoints() == 0 then
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
    for i, attributeControl in ipairs(self.attributeControls) do
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
    for i, attributeControl in ipairs(self.attributeControls) do
        attributeControl.pointLimitedSpinner:RefreshSpinnerMax()
        attributeControl.increaseHighlight:SetHidden(true)
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
    if self.lastControl == nil then
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
    local function UpdateEffects()
        if not container:IsHidden() then
            effectsRowPool:ReleaseAllObjects()

            local effectsRows = {}

            --Artificial effects--
            for effectId in ZO_GetNextActiveArtificialEffectIdIter do
                local displayName, iconFile, effectType, sortOrder, startTime, endTime = GetArtificialEffectInfo(effectId)
                local effectsRow = effectsRowPool:AcquireObject()
                effectsRow.name:SetText(zo_strformat(SI_ABILITY_TOOLTIP_NAME, displayName))
                effectsRow.icon:SetTexture(iconFile)
                effectsRow.effectType = effectType
                local duration = startTime - endTime
                effectsRow.time:SetHidden(duration == 0)
                effectsRow.time.endTime = endTime
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
                if prevRow then
                    effectsRow:SetAnchor(TOPLEFT, prevRow, BOTTOMLEFT)
                else
                    effectsRow:SetAnchor(TOPLEFT, nil, TOPLEFT, 5, 0)
                end
                effectsRow:SetHidden(false)

                prevRow = effectsRow
            end

        end
    end

    local function OnEffectChanged(eventCode, changeType, buffSlot, buffName, unitTag)
        UpdateEffects()
    end

    container:RegisterForEvent(EVENT_EFFECT_CHANGED, OnEffectChanged)
    container:AddFilterForEvent(EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, "player")
    container:RegisterForEvent(EVENT_EFFECTS_FULL_UPDATE, UpdateEffects)
    container:RegisterForEvent(EVENT_ARTIFICIAL_EFFECT_ADDED, UpdateEffects)
    container:RegisterForEvent(EVENT_ARTIFICIAL_EFFECT_REMOVED, UpdateEffects)
    container:SetHandler("OnEffectivelyShown", UpdateEffects)
end

function ZO_Stats:UpdateLevelUpRewards()
    if STATS_SCENE:IsShowing() then
        if HasPendingLevelUpReward() then
            ZO_KEYBOARD_UPCOMING_LEVEL_UP_REWARDS:Hide()
            ZO_KEYBOARD_CLAIM_LEVEL_UP_REWARDS:Show()
        elseif HasUpcomingLevelUpReward() then
            local wasClaimShowing = ZO_KEYBOARD_CLAIM_LEVEL_UP_REWARDS:IsShowing()
            ZO_KEYBOARD_CLAIM_LEVEL_UP_REWARDS:Hide()
            local fadeInUpcomingContents = wasClaimShowing
            ZO_KEYBOARD_UPCOMING_LEVEL_UP_REWARDS:Show(fadeInUpcomingContents)
        else
            ZO_KEYBOARD_CLAIM_LEVEL_UP_REWARDS:Hide()
            ZO_KEYBOARD_UPCOMING_LEVEL_UP_REWARDS:Hide()
        end

        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindButtons)
    end
end

--
--[[ XML Handlers ]]--
--

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
