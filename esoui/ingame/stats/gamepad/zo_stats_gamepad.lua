--Attribute Spinner

local ZO_AttributeSpinner_Gamepad = ZO_AttributeSpinner_Shared:Subclass()

function ZO_AttributeSpinner_Gamepad:New(attributeControl, attributeType, attributeManager, valueChangedCallback)
    local attributeSpinner = ZO_AttributeSpinner_Shared.New(self, attributeControl, attributeType, attributeManager, valueChangedCallback)
    attributeSpinner:SetSpinner(ZO_Spinner_Gamepad:New(attributeControl.spinner, 0, 0, GAMEPAD_SPINNER_DIRECTION_HORIZONTAL))
    return attributeSpinner
end

function ZO_AttributeSpinner_Gamepad:SetActive(active)
    self.pointsSpinner:SetActive(active)
end

--Stats

local GAMEPAD_STATS_COMMIT_POINTS_DIALOG_NAME = "GAMEPAD_STATS_COMMIT_POINTS"

local GAMEPAD_STATS_DISPLAY_MODE = {
    CHARACTER = 1,
    EFFECTS = 2,
    TITLE = 3,
}

local GAMEPAD_ATTRIBUTE_ICONS = {
    [ATTRIBUTE_HEALTH] = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_healthIcon.dds",
    [ATTRIBUTE_STAMINA] = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_staminaIcon.dds",
    [ATTRIBUTE_MAGICKA] = "/esoui/art/characterwindow/Gamepad/gp_characterSheet_magickaIcon.dds",
}

local GAMEPAD_ATTRIBUTE_ORDERING = {
    ATTRIBUTE_MAGICKA,
    ATTRIBUTE_HEALTH,
    ATTRIBUTE_STAMINA,
}

ZO_GamepadStats = ZO_Object.MultiSubclass(ZO_Stats_Common, ZO_Gamepad_ParametricList_Screen)

function ZO_GamepadStats:New(...)
    local gamepadStats = ZO_Object.New(self)
    gamepadStats:Initialize(...)
    return gamepadStats
end

function ZO_GamepadStats:Initialize(control)
    ZO_Stats_Common.Initialize(self, control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control)

    if not self.initialized then
        self.initialized = true

        self.control = control
        self.displayMode = GAMEPAD_STATS_DISPLAY_MODE.TITLE

        --Only allow the window to update once every quarter second so if buffs are updating like crazy we're not tanking the frame rate
        self:SetUpdateCooldown(250)

        GAMEPAD_STATS_ROOT_SCENE = ZO_Scene:New("gamepad_stats_root", SCENE_MANAGER)
        GAMEPAD_STATS_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
            if newState == SCENE_SHOWING then
                self:PerformDeferredInitializationRoot()

                self:TryResetScreenState()
                self:RefreshBattleLevelHeader()
                self:ActivateMainList()             
                
                local function OnUpdate(_, unitTag)
                    if unitTag == "player" then 
                        self:Update()
                    end
                end

                local function OnRefresh()
                    self:Update()
                end

                self.control:RegisterForEvent(EVENT_STATS_UPDATED, OnUpdate)
                self.control:RegisterForEvent(EVENT_LEVEL_UPDATE, OnUpdate)
                self.control:RegisterForEvent(EVENT_EFFECT_CHANGED, OnRefresh)
                self.control:AddFilterForEvent(EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, "player")
                self.control:RegisterForEvent(EVENT_EFFECTS_FULL_UPDATE, OnRefresh)
                self.control:RegisterForEvent(EVENT_ATTRIBUTE_UPGRADE_UPDATED, OnRefresh)
                self.control:RegisterForEvent(EVENT_TITLE_UPDATE, OnUpdate)
                self.control:RegisterForEvent(EVENT_PLAYER_TITLES_UPDATE, OnRefresh)
                self.control:RegisterForEvent(EVENT_CHAMPION_POINT_GAINED, OnRefresh)
                self.control:RegisterForEvent(EVENT_CHAMPION_SYSTEM_UNLOCKED, OnRefresh)
                STABLE_MANAGER:RegisterCallback("StableMountInfoUpdated", OnRefresh)

                self:Update()

                TriggerTutorial(TUTORIAL_TRIGGER_STATS_OPENED)
                if GetAttributeUnspentPoints() > 0 then
                    TriggerTutorial(TUTORIAL_TRIGGER_STATS_OPENED_AND_ATTRIBUTE_POINTS_UNSPENT)
                end
            elseif newState == SCENE_HIDDEN then
                self:DeactivateMainList()         
    
                if(self.currentTitleDropdown ~= nil) then
                    self.currentTitleDropdown:Deactivate(true)
                end       

                self.control:UnregisterForEvent(EVENT_STATS_UPDATED)
                self.control:UnregisterForEvent(EVENT_LEVEL_UPDATE)
                self.control:UnregisterForEvent(EVENT_EFFECT_CHANGED)
                self.control:UnregisterForEvent(EVENT_EFFECTS_FULL_UPDATE)
                self.control:UnregisterForEvent(EVENT_ATTRIBUTE_UPGRADE_UPDATED)
                self.control:UnregisterForEvent(EVENT_TITLE_UPDATE)
                self.control:UnregisterForEvent(EVENT_PLAYER_TITLES_UPDATE)
                STABLE_MANAGER:UnregisterCallback("StableMountInfoUpdated", OnRefresh)
            end

            ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
        end)
    end
end

function ZO_GamepadStats:ActivateMainList()
    if(not self.mainList:IsActive()) then
        self.mainList:Activate()

        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GamepadStats:DeactivateMainList()
    if(self.mainList:IsActive()) then

        self.mainList:Deactivate()

        local selectedControl = self.mainList:GetSelectedControl()
        if selectedControl and selectedControl.pointLimitedSpinner then
            selectedControl.pointLimitedSpinner:SetActive(false)
        end

        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_GamepadStats:ActivateTitleDropdown()
    if(self.currentTitleDropdown ~= nil) then
        self:DeactivateMainList()

        self.currentTitleDropdown:Activate()

        local currentTitleIndex = GetCurrentTitleIndex()
        if(currentTitleIndex) then
            currentTitleIndex = currentTitleIndex + 1
        else
            currentTitleIndex = 1
        end
        self.currentTitleDropdown:SetHighlightedItem(currentTitleIndex)
    end
end

function ZO_GamepadStats:OnTitleDropdownDeactivated()
    self:ActivateMainList()
    if self.refreshMainListOnDropdownClose then
        self:RefreshMainList()
        self.refreshMainListOnDropdownClose = false
    end
end

function ZO_GamepadStats:ResetAttributeData()
    self.attributeData = {}

    for attributeType = 1, GetNumAttributes() do
        self.attributeData[attributeType] = {
            addedPoints = 0
        }
    end

    for attributeType, statType in pairs(STAT_TYPES) do
        self:UpdatePendingStatBonuses(statType, 0)
    end
end

function ZO_GamepadStats:ResetDisplayState()
    -- Reset any stateful variables used in this screen.
    self.displayedBuffIndex = nil
    self.displayMode = nil
end

function ZO_GamepadStats:TryResetScreenState()
    self:ResetAttributeData()
    self:ResetDisplayState()
end

function ZO_GamepadStats:PerformDeferredInitializationRoot()
    if self.deferredInitialied then return end
    self.deferredInitialied = true
    
    self.infoPanel = self.control:GetNamedChild("RightPane"):GetNamedChild("InfoPanel")

    self:InitializeCharacterStats()
    self:InitializeCharacterEffects()

    self:InitializeHeader()
    self:InitializeBattleLevelHeader()
    self:InitializeCommitPointsDialog()
end

function ZO_GamepadStats:InitializeBattleLevelHeader()
    local battleLevelHeader = self.control:GetNamedChild("RightPane"):GetNamedChild("BattleLevelHeader")

    self.levelTypeIcon = battleLevelHeader:GetNamedChild("LevelTypeIcon")
    self.levelTypeIcon:SetTexture(GetGamepadVeteranRankIcon())

    self.levelLabel = battleLevelHeader:GetNamedChild("Level")

    self.battleLevelHeader = battleLevelHeader
end

function ZO_GamepadStats:RefreshBattleLevelHeader()       
    local isBattleLeveled = IsUnitBattleLeveled("player")
    local isVetBattleLeveled = IsUnitVetBattleLeveled("player")

    if isVetBattleLeveled then
        self.levelTypeIcon:SetWidth(32)
        self.levelTypeIcon:SetHidden(false)
        self.levelLabel:SetText(GetUnitVetBattleLevel("player"))
    elseif isBattleLeveled then
        self.levelTypeIcon:SetWidth(0)
        self.levelTypeIcon:SetHidden(true)
        self.levelLabel:SetText(GetUnitBattleLevel("player"))
    end

    self.battleLevelHeader:SetHidden(not (isBattleLeveled or isVetBattleLeveled))
end

function ZO_GamepadStats:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = { 
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select / Commit Points
        {
            name = function()
                if(self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.TITLE) then
                    return GetString(SI_GAMEPAD_SELECT_OPTION)
                else
                    return GetString(SI_STAT_GAMEPAD_COMMIT_POINTS)
                end
            end,
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                if(self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.TITLE) then
                    return true
                else
                    return self:GetNumPointsAdded() > 0 
                end
            end,
            callback = function() 
                if(self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.TITLE) then
                    self:ActivateTitleDropdown()
                else
                    ZO_Dialogs_ShowGamepadDialog(GAMEPAD_STATS_COMMIT_POINTS_DIALOG_NAME)
                end
            end,
        },
        -- remove buff
        { 
            name = GetString(SI_STAT_GAMEPAD_EFFECTS_REMOVE),
            keybind = "UI_SHORTCUT_SECONDARY",
            visible = function()
                local selectedData = self.mainList:GetTargetData()
                if(selectedData ~= nil and selectedData.buffSlot ~= nil) then
                    return selectedData.canClickOff
                end
                return false
            end,
            callback = function()
                local selectedData = self.mainList:GetTargetData()
                CancelBuff(selectedData.buffSlot)
            end,
        },
    }

    
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.mainList)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

function ZO_GamepadStats:SetAddedPoints(attributeType, addedPoints)
    self.attributeData[attributeType].addedPoints = addedPoints

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    self:RefreshCharacterStats()
end

function ZO_GamepadStats:GetAddedPoints(attributeType)
    return self.attributeData[attributeType].addedPoints
end

function ZO_GamepadStats:GetNumPointsAdded()
    local addedPoints = 0

    for attributeType = 1, GetNumAttributes() do
        addedPoints = addedPoints + self.attributeData[attributeType].addedPoints
    end

    return addedPoints
end

function ZO_GamepadStats:PurchaseAttributes()
    PlaySound(SOUNDS.STATS_PURCHASE)
    PurchaseAttributes(self.attributeData[ATTRIBUTE_HEALTH].addedPoints, self.attributeData[ATTRIBUTE_MAGICKA].addedPoints, self.attributeData[ATTRIBUTE_STAMINA].addedPoints)
    self:ResetAttributeData()
        end

function ZO_GamepadStats:UpdateScreenVisibility()
    local isStatsHidden = true
    local isEffectsHidden = true

    if(self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.CHARACTER or self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.TITLE) then
        isStatsHidden = false
        self:RefreshCharacterStats()
    elseif(self.displayMode == GAMEPAD_STATS_DISPLAY_MODE.EFFECTS) then
        isEffectsHidden = (self.numActiveEffects == 0)
        if(not isEffectsHidden) then
            self:RefreshCharacterEffects()    
        end
    end

    self.characterStats:SetHidden(isStatsHidden)
    
    self.characterEffects:SetHidden(isEffectsHidden)

    local hideQuadrant2Background = isStatsHidden and isEffectsHidden
    if(hideQuadrant2Background) then
        GAMEPAD_STATS_ROOT_SCENE:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        self.contentHeader:SetHidden(true)
    else
        GAMEPAD_STATS_ROOT_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
        self.contentHeader:SetHidden(false)
    end
end

function ZO_GamepadStats:RefreshConfirmScreen()
    self:RefreshCommitPointsConfirmList()

    self.displayMode = GAMEPAD_STATS_DISPLAY_MODE.CHARACTER
    
    self:UpdateScreenVisibility()
end

function ZO_GamepadStats:PerformUpdate()
    self:UpdateSpendablePoints()

    self:RefreshMainList()
    
    local selectedData = self.mainList:GetTargetData()
    if(selectedData.displayMode ~= nil) then
        self.displayMode = selectedData.displayMode
    end

    self:UpdateScreenVisibility()
end

function ZO_GamepadStats:OnSetAvailablePoints()
    self:RefreshHeader()
end

function ZO_GamepadStats:UpdateSpendablePoints()
    self:SetAvailablePoints(self:GetTotalSpendablePoints() - self:GetNumPointsAdded())
end

--------------------------
-- Commit Points Dialog --
--------------------------

function ZO_GamepadStats:InitializeCommitPointsDialog()
    ZO_Dialogs_RegisterCustomDialog(GAMEPAD_STATS_COMMIT_POINTS_DIALOG_NAME,
    {
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },

        title =
        {
            text = SI_STAT_GAMEPAD_CHANGE_ATTRIBUTES,
        },

        mainText = 
        {
            text = SI_STAT_GAMEPAD_COMMIT_POINTS_QUESTION,
        },
       
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_DIALOG_YES_BUTTON,
                callback = function()
                    self:PurchaseAttributes()
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_DIALOG_NO_BUTTON,
            },
        }
    })
end
                 
------------
-- Header --
------------

function ZO_GamepadStats:InitializeHeader()
    self.headerData = {
        titleText = GetString(SI_STAT_GAMEPAD_CHARACTER_SHEET_TITLE),

        data1HeaderText = GetString(SI_STATS_GAMEPAD_AVAILABLE_POINTS),
    }

    local rightPane = self.control:GetNamedChild("RightPane")
    local contentContainer = rightPane:GetNamedChild("HeaderContainer")
    self.contentHeader = contentContainer:GetNamedChild("Header")

    ZO_GamepadGenericHeader_Initialize(self.contentHeader, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, DATA_PAIRS_TOGETHER)
    self.contentHeaderData = {}
end

function ZO_GamepadStats:RefreshHeader()
    self.headerData.data1Text = tostring(self:GetAvailablePoints())

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_GamepadStats:RefreshContentHeader(title, dataHeaderText, dataText)
    self.contentHeaderData.titleText = zo_strformat(SI_ABILITY_TOOLTIP_NAME, title)
    self.contentHeaderData.data1HeaderText = dataHeaderText
    self.contentHeaderData.data1Text = dataText
    ZO_GamepadGenericHeader_Refresh(self.contentHeader, self.contentHeaderData)

    local headerTitle = self.contentHeader:GetNamedChild("TitleContainer"):GetNamedChild("Title")
    headerTitle:ClearAnchors()
    headerTitle:SetAnchor(LEFT)
    headerTitle:SetAnchor(RIGHT, self.battleLevelHeader:GetNamedChild("ScaledLevel"), LEFT)
end

---------------
-- Main List --
---------------

do
    local function SetupEffectAttributeRow(control, data, ...)
        ZO_SharedGamepadEntry_OnSetup(control, data, ...)
        local frameControl = control:GetNamedChild("Frame")
        hasIcon = data:GetNumIcons() > 0
        frameControl:SetHidden(not hasIcon)
    end

    function ZO_GamepadStats:SetupList(list)
        self.mainList = list

        self.mainList:AddDataTemplate("ZO_GamepadStatTitleRow", ZO_GamepadStatTitleRow_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        self.mainList:AddDataTemplateWithHeader("ZO_GamepadStatTitleRow", ZO_GamepadStatTitleRow_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

        self.mainList:AddDataTemplate("ZO_GamepadStatAttributeRow", ZO_GamepadStatAttributeRow_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        self.mainList:AddDataTemplateWithHeader("ZO_GamepadStatAttributeRow", ZO_GamepadStatAttributeRow_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

        self.mainList:AddDataTemplate("ZO_GamepadEffectAttributeRow", SetupEffectAttributeRow, ZO_GamepadMenuEntryTemplateParametricListFunction)
        self.mainList:AddDataTemplateWithHeader("ZO_GamepadEffectAttributeRow", SetupEffectAttributeRow, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

        --Title Entry
        self.titleEntry = ZO_GamepadEntryData:New("")
        self.titleEntry.displayMode = GAMEPAD_STATS_DISPLAY_MODE.TITLE
        self.titleEntry.statsObject = self
        self.titleEntry:SetHeader(GetString(SI_STATS_TITLE))

        --Attribute Entries
        self.attributeEntries = {}
        for index, attributeType in ipairs(GAMEPAD_ATTRIBUTE_ORDERING) do
            local icon = GAMEPAD_ATTRIBUTE_ICONS[attributeType]
            local data = ZO_GamepadEntryData:New(GetString("SI_ATTRIBUTES", attributeType), icon)
            data.screen = self
            data.attributeType = attributeType
            data.displayMode = GAMEPAD_STATS_DISPLAY_MODE.CHARACTER
        
            if index == 1 then
                data:SetHeader(GetString(SI_STATS_ATTRIBUTES))
            end
            table.insert(self.attributeEntries, data)
        end
    end
end

function ZO_GamepadStats:OnSelectionChanged(list, selectedData, oldSelectedData)
    local refreshDueToDisplayMode = (selectedData.displayMode ~= nil and self.displayMode ~= selectedData.displayMode)
    local refreshDueToBuffIndex = (selectedData.buffIndex ~= nil and self.displayedBuffIndex ~= selectedData.buffIndex)

    if(refreshDueToDisplayMode or refreshDueToBuffIndex) then 
        if(refreshDueToDisplayMode) then
            self.displayMode = selectedData.displayMode
        end

        if(refreshDueToBuffIndex) then
            self.displayedBuffIndex = selectedData.buffIndex
        end
        
        self:UpdateScreenVisibility()
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_GamepadStats:RefreshMainList()
    if self.currentTitleDropdown and self.currentTitleDropdown:IsDropdownVisible() then
        self.refreshMainListOnDropdownClose = true
        return
    end

    self.mainList:Clear()

    --Title
    self.mainList:AddEntryWithHeader("ZO_GamepadStatTitleRow", self.titleEntry)
    
    -- Attributes    
    for index, attributeEntry in ipairs(self.attributeEntries) do
        if index == 1 then
            self.mainList:AddEntryWithHeader("ZO_GamepadStatAttributeRow", attributeEntry)
        else
            self.mainList:AddEntry("ZO_GamepadStatAttributeRow", attributeEntry)
        end
    end
    
    -- Active Effects
    self.numActiveEffects = 0
    local numBuffs = GetNumBuffs("player")
    local hasActiveEffects = numBuffs > 0
    if(hasActiveEffects) then
        for i = 1, numBuffs do
            local buffName, startTime, endTime, buffSlot, stackCount, iconFile, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff = GetUnitBuffInfo("player", i)

            if buffSlot > 0 and buffName ~= "" then
                local data = ZO_GamepadEntryData:New(zo_strformat(SI_ABILITY_TOOLTIP_NAME, buffName), iconFile)
                data.displayMode = GAMEPAD_STATS_DISPLAY_MODE.EFFECTS
                data.buffIndex = i
                data.buffSlot = buffSlot
                data.canClickOff = canClickOff

                local duration = endTime - startTime
                if(duration > 0) then
                    local timeLeft = (endTime * 1000.0) - GetFrameTimeMilliseconds()
                    data:SetCooldown(timeLeft, duration * 1000.0)
                end
            
                if i == 1 then
                    data:SetHeader(GetString(SI_STATS_ACTIVE_EFFECTS))
                    self.mainList:AddEntryWithHeader("ZO_GamepadEffectAttributeRow", data)
                else
                    self.mainList:AddEntry("ZO_GamepadEffectAttributeRow", data)
                end

                self.numActiveEffects = self.numActiveEffects + 1
            end
        end
    end

    if(self.numActiveEffects == 0) then
        local data = ZO_GamepadEntryData:New(GetString(SI_STAT_GAMEPAD_EFFECTS_NONE_ACTIVE))
        data.displayMode = GAMEPAD_STATS_DISPLAY_MODE.EFFECTS
        data:SetHeader(GetString(SI_STATS_ACTIVE_EFFECTS))
        
        self.mainList:AddEntryWithHeader("ZO_GamepadEffectAttributeRow", data)
    end

    self.mainList:Commit()

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

-------------------
-- Heat & Bounty --
-------------------

function ZO_Stats_Gamepad_BountyDisplay_Initialize(control)
    GAMEPAD_STATS_BOUNTY_DISPLAY = ZO_BountyDisplay:New(control, true)
end

-----------------------
-- Character Effects --
-----------------------

function ZO_GamepadStats:InitializeCharacterEffects()
    self.characterEffects = self.infoPanel:GetNamedChild("CharacterEffectsPanel")

    local titleSection = self.characterEffects:GetNamedChild("TitleSection")

    self.effectDesc = titleSection:GetNamedChild("EffectDesc")
end

function ZO_GamepadStats:RefreshCharacterEffects()
    local selectedData = self.mainList:GetTargetData()
    local buffName, startTime, endTime, buffSlot, stackCount, iconFile, buffType, effectType, abilityType, statusEffectType, abilityId = GetUnitBuffInfo("player", selectedData.buffIndex)

    local desc = nil

    if(DoesAbilityExist(abilityId)) then
        desc = GetAbilityEffectDescription(buffSlot)
    end
    
    self.effectDesc:SetText(desc)

    local function OnTimerUpdate()
        local selectedData = self.mainList:GetTargetData()
        local buffName, startTime, endTime, buffSlot, stackCount, iconFile, buffType, effectType, abilityType, statusEffectType = GetUnitBuffInfo("player", selectedData.buffIndex)

        local duration = endTime - startTime
        if(duration > 0) then
            local timeLeft = endTime - (GetFrameTimeMilliseconds() / 1000.0)

            local durationText = ZO_FormatTime(timeLeft, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)

            self:RefreshContentHeader(buffName, GetString(SI_STAT_GAMEPAD_TIME_REMAINING), durationText)
        end
    end
    
    self.effectDesc:SetHandler("OnUpdate", OnTimerUpdate)
    
    self:RefreshContentHeader(buffName)

    return buffName
end

---------------------
-- Character Stats --
---------------------

function ZO_GamepadStats:InitializeCharacterStats()
    self.characterStats = self.infoPanel:GetNamedChild("CharacterStatsPanel")

    -- Left Column

    local leftColumn = self.characterStats:GetNamedChild("LeftColumn")

    self.race = leftColumn:GetNamedChild("Race")
    self.class = leftColumn:GetNamedChild("Class")

    self.championRankHeader = leftColumn:GetNamedChild("ChampionRankHeader")
    self.championRank = leftColumn:GetNamedChild("ChampionRank")

    self.maxMagickaHeader = leftColumn:GetNamedChild("MaxMagickaHeader")
    self.maxHealthHeader = leftColumn:GetNamedChild("MaxHealthHeader")
    self.maxStaminaHeader = leftColumn:GetNamedChild("MaxStaminaHeader")

    self.spellPowerHeader = leftColumn:GetNamedChild("SpellPowerHeader")
    self.spellCriticalHeader = leftColumn:GetNamedChild("SpellCriticalHeader")

    self.spellResistanceHeader = leftColumn:GetNamedChild("SpellResistanceHeader")
    self.critResistanceHeader = leftColumn:GetNamedChild("CritResistanceHeader")

    self.maxMagicka = leftColumn:GetNamedChild("MaxMagicka")
    self.maxMagickaBonus = leftColumn:GetNamedChild("MaxMagickaBonus")
    self.maxHealth = leftColumn:GetNamedChild("MaxHealth")
    self.maxHealthBonus = leftColumn:GetNamedChild("MaxHealthBonus")
    self.maxStamina = leftColumn:GetNamedChild("MaxStamina")
    self.maxStaminaBonus = leftColumn:GetNamedChild("MaxStaminaBonus")

    self.spellPower = leftColumn:GetNamedChild("SpellPower")
    self.spellCritical = leftColumn:GetNamedChild("SpellCritical")

    self.spellResistance = leftColumn:GetNamedChild("SpellResistance")
    self.critResistance = leftColumn:GetNamedChild("CritResistance")

    self.ridingSpeed = leftColumn:GetNamedChild("RidingSpeed")
    self.ridingCapacity = leftColumn:GetNamedChild("RidingCapacity")

    local rightColumn = self.characterStats:GetNamedChild("RightColumn")

    self.alliance = rightColumn:GetNamedChild("Alliance")
    self.rankIcon = rightColumn:GetNamedChild("RankIcon")
    self.rank = rightColumn:GetNamedChild("Rank")
    
    self.magickaRecoveryHeader = rightColumn:GetNamedChild("MagickaRecoveryHeader")
    self.healthRecoveryHeader = rightColumn:GetNamedChild("HealthRecoveryHeader")
    self.staminaRecoveryHeader = rightColumn:GetNamedChild("StaminaRecoveryHeader")

    self.weaponDamageHeader = rightColumn:GetNamedChild("WeaponDamageHeader")
    self.weaponCriticalHeader = rightColumn:GetNamedChild("WeaponCriticalHeader")
    self.armorHeader = rightColumn:GetNamedChild("ArmorHeader")

    self.magickaRecovery = rightColumn:GetNamedChild("MagickaRecovery")
    self.healthRecovery = rightColumn:GetNamedChild("HealthRecovery")
    self.staminaRecovery = rightColumn:GetNamedChild("StaminaRecovery")

    self.weaponDamage = rightColumn:GetNamedChild("WeaponDamage")
    self.weaponCritical = rightColumn:GetNamedChild("WeaponCritical")
    self.armor = rightColumn:GetNamedChild("Armor")

    self.ridingStamina = rightColumn:GetNamedChild("RidingStamina")
    self.ridingTrainingHeader = rightColumn:GetNamedChild("RidingTrainingHeader")
    self.ridingTrainingReady = rightColumn:GetNamedChild("RidingTrainingReady")
    self.ridingTrainingTimer = rightColumn:GetNamedChild("RidingTrainingTimer")

    local function OnTimerUpdate()
        local timeUntilCanBeTrained = GetTimeUntilCanBeTrained()
        if timeUntilCanBeTrained == 0 then
            self:RefreshCharacterStats()
        else
            local timeLeft = ZO_FormatTimeMilliseconds(timeUntilCanBeTrained, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR)
            self.ridingTrainingTimer:SetText(timeLeft)
        end
    end

    self.ridingTrainingTimer:SetHandler("OnUpdate", OnTimerUpdate)

    self.headers = {
        -- Left Column
        { label = self.maxMagickaHeader, stat = STAT_MAGICKA_MAX },
        { label = self.maxHealthHeader, stat = STAT_HEALTH_MAX },
        { label = self.maxStaminaHeader, stat = STAT_STAMINA_MAX },

        { label = self.spellPowerHeader, stat = STAT_SPELL_POWER },
        { label = self.spellCriticalHeader, stat = STAT_SPELL_CRITICAL },

        { label = self.spellResistanceHeader, stat = STAT_SPELL_RESIST },
        { label = self.critResistanceHeader, stat = STAT_CRITICAL_RESISTANCE },

        -- Right Column
        { label = self.magickaRecoveryHeader, stat = STAT_MAGICKA_REGEN_COMBAT },
        { label = self.healthRecoveryHeader, stat = STAT_HEALTH_REGEN_COMBAT },
        { label = self.staminaRecoveryHeader, stat = STAT_STAMINA_REGEN_COMBAT },

        { label = self.weaponDamageHeader, stat = STAT_POWER },
        { label = self.weaponCriticalHeader, stat = STAT_CRITICAL_STRIKE },
        { label = self.armorHeader, stat = STAT_PHYSICAL_RESIST },
    }

    self.statValues = {
        -- Left Column
        { label = self.maxMagicka, stat = STAT_MAGICKA_MAX },
        { label = self.maxHealth, stat = STAT_HEALTH_MAX },
        { label = self.maxStamina, stat = STAT_STAMINA_MAX },
        
        { label = self.spellPower, stat = STAT_SPELL_POWER },
        { label = self.spellCritical, stat = STAT_SPELL_CRITICAL, formatString = SI_STAT_VALUE_PERCENT },

        { label = self.spellResistance, stat = STAT_SPELL_RESIST },
        { label = self.critResistance, stat = STAT_CRITICAL_RESISTANCE },

        -- Right Column
        { label = self.magickaRecovery, stat = STAT_MAGICKA_REGEN_COMBAT },
        { label = self.healthRecovery, stat = STAT_HEALTH_REGEN_COMBAT },
        { label = self.staminaRecovery, stat = STAT_STAMINA_REGEN_COMBAT },
        
        { label = self.weaponDamage, stat = STAT_POWER },
        { label = self.weaponCritical, stat = STAT_CRITICAL_STRIKE, formatString = SI_STAT_VALUE_PERCENT },
        { label = self.armor, stat = STAT_PHYSICAL_RESIST },
    }

    
    self.bonusValues = {
        { label = self.maxMagickaBonus, stat = STAT_MAGICKA_MAX},
        { label = self.maxHealthBonus, stat = STAT_HEALTH_MAX},
        { label = self.maxStaminaBonus, stat = STAT_STAMINA_MAX},
    }
end

function ZO_GamepadStats:SetBonusText(statType, label)
    local bonus = self:GetPendingStatBonuses(statType)
    label:SetHidden(bonus == 0 or self:IsPlayerBattleLeveled())      -- We don't show any attribute stat increases while in battle leveled zones because
    label:SetText(zo_strformat(SI_STAT_PENDING_BONUS_FORMAT, bonus)) -- it doesn't make any sense based on how battle leveling now works
    label:SetColor(STAT_HIGHER_COLOR:UnpackRGBA())
end

function ZO_GamepadStats:SetStatValue(statType, label, formatString)
    if(suffix == nil) then
        suffix = ""
    end

    local value = GetPlayerStat(statType, STAT_BONUS_OPTION_APPLY_BONUS, STAT_SOFT_CAP_OPTION_APPLY_SOFT_CAP)
    local USE_MINIMUM = true

    if(statType == STAT_CRITICAL_STRIKE or statType == STAT_SPELL_CRITICAL) then
        value = GetCriticalStrikeChance(value, USE_MINIMUM)
    end

    local text = nil
    if(formatString ~= nil) then
        text = zo_strformat(formatString, value)
    else
        text = tostring(value)
    end

    local statChanged = text ~= label:GetText()
    if statChanged then 
        label:SetText(text)
    end
end

local function GetStatText(statType)
    local statText = GetString("SI_DERIVEDSTATS", statType)
    return statText
end

function ZO_GamepadStats:RefreshCharacterStats()
    -- Left & Right Column
    local unitRace = GetUnitRace("player")
    local unitClass = GetUnitClass("player")
    self.race:SetText(zo_strformat(GetString(SI_STAT_GAMEPAD_RACE_NAME), unitRace))
    self.class:SetText(zo_strformat(GetString(SI_STAT_GAMEPAD_CLASS_NAME), unitClass))

    local hasChampionRank = IsChampionSystemUnlocked()
    self.championRankHeader:SetHidden(not hasChampionRank)
    self.championRank:SetHidden(not hasChampionRank)
    if hasChampionRank then
        self.championRank:SetText(GetPlayerChampionPointsEarned())
    end

    for i, header in ipairs(self.headers) do
        header.label:SetText(GetStatText(header.stat))
    end

    for i, value in ipairs(self.statValues) do
        self:SetStatValue(value.stat, value.label, value.formatString)
    end
    
    for i, value in ipairs(self.bonusValues) do
        self:SetBonusText(value.stat, value.label)
    end
    
    -- Right Pane
    local allianceName = GetAllianceName(GetUnitAlliance("player"))
    self.alliance:SetText(zo_strformat(SI_ALLIANCE_NAME, allianceName))

    local rank, subRank = GetUnitAvARank("player")
    local rankName = GetAvARankName(GetUnitGender("player"), rank)
    if(rank == 0) then
        self.rankIcon:SetHidden(true)
    else
        self.rankIcon:SetHidden(false)
        self.rankIcon:SetTexture(GetAvARankIcon(rank))
    end
    self.rank:SetText(zo_strformat(SI_STAT_RANK_NAME_FORMAT, rankName))

    self:RefreshContentHeader(GetString(SI_STATS_ATTRIBUTES))

    --Riding skill
    local speedBonus, _, staminaBonus, _, inventoryBonus = STABLE_MANAGER:GetStats()
    self.ridingSpeed:SetText(zo_strformat(SI_MOUNT_ATTRIBUTE_SPEED_FORMAT, speedBonus))
    self.ridingStamina:SetText(staminaBonus)
    self.ridingCapacity:SetText(inventoryBonus)

    local ridingSkillMaxedOut = STABLE_MANAGER:IsRidingSkillMaxedOut()
    local readyToTrain = GetTimeUntilCanBeTrained() == 0
    self.ridingTrainingHeader:SetHidden(ridingSkillMaxedOut)
    self.ridingTrainingTimer:SetHidden(ridingSkillMaxedOut or readyToTrain)
    self.ridingTrainingReady:SetHidden(ridingSkillMaxedOut or not readyToTrain)
end

function ZO_GamepadStats_OnInitialize(control)
    GAMEPAD_STATS = ZO_GamepadStats:New(control)
end

function ZO_GamepadStats:SetCurrentTitleDropdown(dropdown)
    self.currentTitleDropdown = dropdown
end

------------------------------
-- Stat Title Attribute Row --
------------------------------

function ZO_GamepadStatTitleRow_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    control.dropdown:SetSortsItems(false)

    data.statsObject:SetCurrentTitleDropdown(control.dropdown)
    data.statsObject:UpdateTitleDropdownTitles(control.dropdown)

    control.dropdown:SetDeactivatedCallback(data.statsObject.OnTitleDropdownDeactivated, data.statsObject)
end

------------------------
-- Stat Attribute Row --
------------------------

function ZO_GamepadStatAttributeRow_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, active)

    local availablePoints = GetAttributeUnspentPoints()
    local showSpinnerArrows = (availablePoints > 0)

    control.spinnerDecrease:SetHidden(not showSpinnerArrows)
    control.spinnerIncrease:SetHidden(not showSpinnerArrows)

    control.attributeType = data.attributeType

    local function SetAttributeText(points, addedPoints)
        if(addedPoints > 0) then
            control.pointLimitedSpinner.pointsSpinner:SetNormalColor(STAT_HIGHER_COLOR)
        else
            control.pointLimitedSpinner.pointsSpinner:SetNormalColor(ZO_SELECTED_TEXT)
        end
    end

    local onValueChangedCallback = function(points, addedPoints)
        data.screen:SetAddedPoints(control.attributeType, addedPoints)
        SetAttributeText(points, addedPoints)
    end

    local addedPoints = data.screen:GetAddedPoints(data.attributeType)

    if(control.pointLimitedSpinner == nil) then
        control.pointLimitedSpinner = ZO_AttributeSpinner_Gamepad:New(control, control.attributeType, data.screen, onValueChangedCallback)
        control.pointLimitedSpinner:ResetAddedPoints()
    else
        control.pointLimitedSpinner:Reinitialize(control.attributeType, addedPoints, onValueChangedCallback)
    end

    control.pointLimitedSpinner:SetActive(selected)

    SetAttributeText(control.pointLimitedSpinner:GetPoints(), addedPoints)
end



