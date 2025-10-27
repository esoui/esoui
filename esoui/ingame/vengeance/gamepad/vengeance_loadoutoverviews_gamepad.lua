-------------------------------------------------
-- ZO_Vengeance_EquippedLoadoutOverview_Gamepad
-------------------------------------------------

ZO_Vengeance_EquippedLoadoutOverview_Gamepad = ZO_InitializingObject:Subclass()

function ZO_Vengeance_EquippedLoadoutOverview_Gamepad:Initialize(control)
    self.control = control

    ZO_VENGEANCE_EQUIPPED_LOADOUT_OVERVIEW_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    ZO_VENGEANCE_EQUIPPED_LOADOUT_OVERVIEW_GAMEPAD_FRAGMENT:RegisterCallback("StateChange",
        function(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                self:OnShowing()
            end
        end)

    self.container = control:GetNamedChild("Container")
    self.scrollContainer = self.container:GetNamedChild("ScrollContainer")
    self.scrollChild = self.scrollContainer:GetNamedChild("ScrollChild")

    self.loadoutNameControl = self.scrollChild:GetNamedChild("LoadoutName")

    -- Set up the skill rows
    self.skillBarRow1 = self.scrollChild:GetNamedChild("SkillsActionBar1").object
    self.skillBarRow2 = self.scrollChild:GetNamedChild("SkillsActionBar2").object
    self.skillBarRow1:SetHotbarCategory(HOTBAR_CATEGORY_PRIMARY)
    self.skillBarRow2:SetHotbarCategory(HOTBAR_CATEGORY_BACKUP)

    -- Create perks controls
    self.perkControls  = {}
    self.perkControls[VENGEANCE_PERK_SLOT_RED] = self.scrollChild:GetNamedChild("RedPerk")
    self.perkControls[VENGEANCE_PERK_SLOT_YELLOW] = self.scrollChild:GetNamedChild("YellowPerk")
    self.perkControls[VENGEANCE_PERK_SLOT_BLUE] = self.scrollChild:GetNamedChild("BluePerk")
end

function ZO_Vengeance_EquippedLoadoutOverview_Gamepad:OnShowing()
    local loadoutData = ZO_VENGEANCE_MANAGER:GetEquippedLoadoutData()
    if loadoutData then
        self.loadoutNameControl:SetText(loadoutData:GetName())

        self.skillBarRow1:AssignSkillsData(loadoutData:GetPrimaryActionBarData())
        self.skillBarRow2:AssignSkillsData(loadoutData:GetBackupActionBarData())

        for slot, control in pairs(self.perkControls) do
            control.icon:SetPerkSlot(slot)
            control.icon:SetPerkData(loadoutData:GetPerkDataBySlot(slot))

            control.name:SetText(loadoutData:GetPerkNameBySlot(slot))
        end

        self.loadoutData = loadoutData
    end
end

function ZO_Vengeance_EquippedLoadoutOverview_Gamepad:GetNarrationText()
    local narrations = {}
    if self.loadoutData then
        -- Equipped Status
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_EQUIPPED_ITEM_HEADER)))

        -- Loadout Name
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.loadoutData:GetName()))

        -- Skill Hotbars
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_VENGEANCE_LOADOUT_SKILLS_CATEGORY)))
        ZO_AppendNarration(narrations, self.skillBarRow1:GetNarrationText())
        ZO_AppendNarration(narrations, self.skillBarRow2:GetNarrationText())

        -- Perks
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_VENGEANCE_LOADOUT_PERKS_CATEGORY)))
        for slot, control in pairs(self.perkControls) do
            local perkNarrationText = zo_strformat(SI_GAMEPAD_VENGEANCE_PERK_NARRATION_FORMATTER, ZO_VENGEANCE_MANAGER:GetPerkSlotName(slot), self.loadoutData:GetPerkNameBySlot(slot))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(perkNarrationText))
        end
    end
    return narrations
end

function ZO_Vengeance_EquippedLoadoutOverview_Gamepad.OnInitialized(control)
    VENGEANCE_EQUIPPED_LOADOUT_OVERVIEW_GAMEPAD = ZO_Vengeance_EquippedLoadoutOverview_Gamepad:New(control)
end

---------------------------------------------------
-- ZO_Vengeance_UnequippedLoadoutOverview_Gamepad
---------------------------------------------------

ZO_Vengeance_UnequippedLoadoutOverview_Gamepad = ZO_InitializingObject:Subclass()

function ZO_Vengeance_UnequippedLoadoutOverview_Gamepad:Initialize(control)
    self.control = control

    ZO_VENGEANCE_UNEQUIPPED_LOADOUT_OVERVIEW_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    ZO_VENGEANCE_UNEQUIPPED_LOADOUT_OVERVIEW_GAMEPAD_FRAGMENT:RegisterCallback("StateChange",
        function(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING then
                self:OnShowing()
            end
        end)

    self.container = control:GetNamedChild("Container")
    self.scrollContainer = self.container:GetNamedChild("ScrollContainer")
    self.scrollChild = self.scrollContainer:GetNamedChild("ScrollChild")

    self.loadoutNameControl = self.scrollChild:GetNamedChild("LoadoutName")

    -- Set up the skill rows
    self.skillBarRow1 = self.scrollChild:GetNamedChild("SkillsActionBar1").object
    self.skillBarRow2 = self.scrollChild:GetNamedChild("SkillsActionBar2").object
    self.skillBarRow1:SetHotbarCategory(HOTBAR_CATEGORY_PRIMARY)
    self.skillBarRow2:SetHotbarCategory(HOTBAR_CATEGORY_BACKUP)

    -- Create perks controls
    self.perkIcons = {}
    self.perkIcons[VENGEANCE_PERK_SLOT_RED] = self.scrollChild:GetNamedChild("RedPerk").object
    self.perkIcons[VENGEANCE_PERK_SLOT_YELLOW] = self.scrollChild:GetNamedChild("YellowPerk").object
    self.perkIcons[VENGEANCE_PERK_SLOT_BLUE] = self.scrollChild:GetNamedChild("BluePerk").object

    -- Create Important Stats Pool
    self.importantStatsContainer = self.scrollChild:GetNamedChild("ImportantStatsContainer")
    self.importantStatControlPool = ZO_ControlPool:New("ZO_GamepadSubMenuEntryLabelTemplate")
    self.importantStatControls = {}
end

function ZO_Vengeance_UnequippedLoadoutOverview_Gamepad:OnShowing()
    self:UpdateLoadout()
end

function ZO_Vengeance_UnequippedLoadoutOverview_Gamepad:UpdateLoadout()
    local loadoutData = self.loadoutData
    if loadoutData then
        self.loadoutNameControl:SetText(loadoutData:GetName())

        self.skillBarRow1:AssignSkillsData(loadoutData:GetPrimaryActionBarData())
        self.skillBarRow2:AssignSkillsData(loadoutData:GetBackupActionBarData())

        for slot, icon in pairs(self.perkIcons) do
            icon:SetPerkSlot(slot)
            icon:SetPerkData(loadoutData:GetPerkDataBySlot(slot))
        end

        local relativeToAnchor = self.importantStatsContainer
        ZO_ClearTable(self.importantStatControls)
        self.importantStatControlPool:ReleaseAllObjects()
        local positiveImportantStats = loadoutData:GetPositiveImportantStats()
        for i, text in ipairs(positiveImportantStats) do
            local importantStatControl = self.importantStatControlPool:AcquireObject()
            importantStatControl:SetText(text)
            importantStatControl:SetParent(self.importantStatsContainer)
            importantStatControl:ClearAnchors()
            if i == 1 then
                importantStatControl:SetAnchor(TOPLEFT, relativeToAnchor, TOPLEFT)
            else
                importantStatControl:SetAnchor(TOPLEFT, relativeToAnchor, BOTTOMLEFT)
            end
            table.insert(self.importantStatControls, importantStatControl)
            relativeToAnchor = importantStatControl
        end

        local negativeImportantStats = loadoutData:GetNegativeImportantStats()
        for i, text in ipairs(negativeImportantStats) do
            local importantStatControl = self.importantStatControlPool:AcquireObject()
            importantStatControl:SetText(text)
            importantStatControl:SetParent(self.importantStatsContainer)
            importantStatControl:ClearAnchors()
            importantStatControl:SetAnchor(TOPLEFT, relativeToAnchor, BOTTOMLEFT)
            table.insert(self.importantStatControls, importantStatControl)
            relativeToAnchor = importantStatControl
        end
    end
end

function ZO_Vengeance_UnequippedLoadoutOverview_Gamepad:SetLoadout(loadoutData)
    self.loadoutData = loadoutData
    self:UpdateLoadout()
end

function ZO_Vengeance_UnequippedLoadoutOverview_Gamepad:GetNarrationText()
    local narrations = {}
    if self.loadoutData then
        -- Loadout Name
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.loadoutData:GetName()))

        -- Skill Hotbars
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_VENGEANCE_LOADOUT_SKILLS_CATEGORY)))
        ZO_AppendNarration(narrations, self.skillBarRow1:GetNarrationText())
        ZO_AppendNarration(narrations, self.skillBarRow2:GetNarrationText())

        -- Perks
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_VENGEANCE_LOADOUT_PERKS_CATEGORY)))
        for slot, icon in pairs(self.perkIcons) do
            local perkNarrationText = zo_strformat(SI_GAMEPAD_VENGEANCE_PERK_NARRATION_FORMATTER, ZO_VENGEANCE_MANAGER:GetPerkSlotName(slot), self.loadoutData:GetPerkNameBySlot(slot))
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(perkNarrationText))
        end

        -- Important Stats
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_CAMPAIGN_VENGEANCE_LOADOUT_STATS_HEADER)))
        local positiveImportantStats = self.loadoutData:GetPositiveImportantStats()
        for i, text in ipairs(positiveImportantStats) do
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(text))
        end

        local negativeImportantStats = self.loadoutData:GetNegativeImportantStats()
        for i, text in ipairs(negativeImportantStats) do
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(text))
        end
    end
    return narrations
end

function ZO_Vengeance_UnequippedLoadoutOverview_Gamepad.OnInitialized(control)
    VENGEANCE_UNEQUIPPED_LOADOUT_OVERVIEW_GAMEPAD = ZO_Vengeance_UnequippedLoadoutOverview_Gamepad:New(control)
end