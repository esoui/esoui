local MAX_ICONS_PER_ROW = 7

-- Antiquity Tile Base

ZO_AntiquityTileBase_Keyboard = ZO_Object:Subclass()

function ZO_AntiquityTileBase_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_AntiquityTileBase_Keyboard:Initialize(control)
    self.control = control
    control.owner = self
    self.predecessorTile = nil

    self.header = control:GetNamedChild("Header")
    self.antiquityType = self.header:GetNamedChild("AntiquityType")
    self.icon = control:GetNamedChild("Icon")
    self.status = control:GetNamedChild("Status")
    self.highlight = control:GetNamedChild("Highlight")
    self.highlightAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("AntiquityJournalTileHighlight_Keyboard", self.highlight)
    self.numRecoveredLabel = self.header:GetNamedChild("NumRecovered")
    self.title = self.header:GetNamedChild("Title")

    local function GetRewardData()
        if not self.rewardData and self.tileData then
            if self.tileData:GetType() == ZO_ANTIQUITY_TYPE_INDIVIDUAL then
                local antiquitySetData = self.tileData:GetAntiquitySetData()
                if antiquitySetData and antiquitySetData:HasReward() then
                    local QUANTITIY = 1
                    self.rewardData = REWARDS_MANAGER:GetInfoForReward(antiquitySetData:GetRewardId(), QUANTITIY)
                end
            end
            if not self.rewardData and self.tileData:HasReward() then
                local QUANTITIY = 1
                self.rewardData = REWARDS_MANAGER:GetInfoForReward(self.tileData:GetRewardId(), QUANTITIY)
            end
        end
        return self.rewardData
    end
    control.GetRewardData = GetRewardData

    self.mouseInputGroup = ZO_MouseInputGroup:New(control)
    self.mouseInputGroup:Add(self.icon, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
end

function ZO_AntiquityTileBase_Keyboard:GetControl()
    return self.control
end

function ZO_AntiquityTileBase_Keyboard:GetActionLabel(actionIndex)
    if self.actions then
        local action = self.actions[actionIndex]
        if action then
            return action.label
        end
    end
end

function ZO_AntiquityTileBase_Keyboard:IsActionVisible(actionIndex)
    if self.actions then
        local action = self.actions[actionIndex]
        if action then
            if not action.visible then
                return true
            else
                return action.visible(self)
            end
        end
    end
    return false
end

function ZO_AntiquityTileBase_Keyboard:CanPerformAction(actionIndex)
    if self.actions and self:IsActionVisible(actionIndex) then
        local action = self.actions[actionIndex]
        if action then
            if not action.enabled then
                return true
            else
                return action.enabled(self)
            end
        end
    end
    return false
end

function ZO_AntiquityTileBase_Keyboard:PerformAction(actionIndex)
    if self.actions then
        local action = self.actions[actionIndex]
        if action and action.execute then
            return action.execute(self)
        end
    end
end

function ZO_AntiquityTileBase_Keyboard:SetHighlightHidden(hidden)
    self.highlight:SetHidden(false)
    if hidden then
        self.highlightAnimation:PlayBackward()
        self.icon.highlightAnimation:PlayBackward()
    else
        self.highlightAnimation:PlayForward()
        self.icon.highlightAnimation:PlayForward()
    end
end

function ZO_AntiquityTileBase_Keyboard:SetPredecessorTileOrHeading(predecessorTile)
    -- Docks this tile instance beneath the specified tile.
    self.predecessorTile = predecessorTile
    self.control:ClearAnchors()
    if predecessorTile then
        local predecessorControl
        if type(predecessorTile) == "userdata" then
            predecessorControl = predecessorTile
        else
            predecessorControl = predecessorTile:GetControl()
        end
        self.control:SetAnchor(TOPLEFT, predecessorControl, BOTTOMLEFT)
    else
        self.control:SetAnchor(TOPLEFT)
    end
end

ZO_AntiquityTileBase_Keyboard.Layout = ZO_AntiquityTileBase_Keyboard:MUST_IMPLEMENT()

function ZO_AntiquityTileBase_Keyboard:Reset()
    self.tileData = nil
    self.rewardData = nil
    self.predecessorTile = nil
    self:SetHighlightHidden(true)
end

function ZO_AntiquityTileBase_Keyboard:Refresh()
    local tileData = self.tileData

    if tileData then
        -- Populate the controls that display elements that are common to both Antiquities and Antiquity Sets.
        local colorizeLabels = self.colorizeLabels
        local hasDiscovered = tileData:HasDiscovered()
        local hasRecovered = tileData:HasRecovered()
        local hasReward = tileData:HasReward()
        local isRepeatable = tileData:IsRepeatable()
        local highlightColor = (not colorizeLabels or hasRecovered) and ZO_DEFAULT_ENABLED_COLOR or ZO_DEFAULT_DISABLED_MOUSEOVER_COLOR
        local labelColor = (not colorizeLabels or hasRecovered) and ZO_NORMAL_TEXT or ZO_DISABLED_TEXT

        self.highlight:GetNamedChild("Bottom"):SetColor(highlightColor:UnpackRGB())
        self.highlight:GetNamedChild("Middle"):SetColor(highlightColor:UnpackRGB())
        self.highlight:GetNamedChild("Top"):SetColor(highlightColor:UnpackRGB())

        ZO_AntiquityIcon_SetData(self.icon, tileData)

        self.status:ClearIcons()
        if tileData:HasNewLead() then
            self.status:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end
        self.status:Show()

        self.title:ClearAnchors()
        if hasDiscovered then
            self.title:SetText(tileData:GetColorizedFormattedName())
            self.title:SetColor(ZO_NORMAL_TEXT:UnpackRGB())
            self.title:SetAnchor(TOPLEFT)
        else
            self.title:SetText(GetString(SI_ANTIQUITY_NAME_HIDDEN))
            local titleColor = colorizeLabels and ZO_DISABLED_TEXT or ZO_NORMAL_TEXT
            self.title:SetColor(titleColor:UnpackRGB())
            self.title:SetAnchor(LEFT)
        end

        if hasDiscovered and hasReward then
            local rewardContextualTypeString = REWARDS_MANAGER:GetRewardContextualTypeString(tileData:GetRewardId()) or GetString(SI_ANTIQUITY_TYPE_FALLBACK)
            if not colorizeLabels or hasRecovered then
                rewardContextualTypeString = ZO_SELECTED_TEXT:Colorize(rewardContextualTypeString)
            end
            self.antiquityType:SetText(zo_strformat(SI_ANTIQUITY_TYPE, rewardContextualTypeString))
            self.antiquityType:SetColor(labelColor:UnpackRGB())
            self.antiquityType:SetHidden(false)
        else
            self.antiquityType:SetHidden(true)
        end

        if hasDiscovered and isRepeatable then
            local numRecovered = tileData:GetNumRecovered()
            if not colorizeLabels or hasRecovered then
                numRecovered = ZO_SELECTED_TEXT:Colorize(numRecovered)
            end
            self.numRecoveredLabel:ClearAnchors()
            if hasReward then
                self.numRecoveredLabel:SetAnchor(LEFT, self.antiquityType, RIGHT, 15)
            else
                self.numRecoveredLabel:SetAnchor(TOPLEFT, self.title, BOTTOMLEFT)
            end
            self.numRecoveredLabel:SetText(zo_strformat(SI_ANTIQUITY_TIMES_ACQUIRED, numRecovered))
            self.numRecoveredLabel:SetColor(labelColor:UnpackRGB())
            self.numRecoveredLabel:SetHidden(false)
        else
            self.numRecoveredLabel:SetHidden(true)
        end
    end

    self.control:SetHidden(false)
end

function ZO_AntiquityTileBase_Keyboard:IsControlHidden()
    return self.control:IsHidden()
end

function ZO_AntiquityTileBase_Keyboard:OnMouseEnter()
    ANTIQUITY_JOURNAL_KEYBOARD:SetMouseOverTile(self)
end

function ZO_AntiquityTileBase_Keyboard:OnMouseExit()
    ANTIQUITY_JOURNAL_KEYBOARD:ClearMouseOverTile(self)
end

function ZO_AntiquityTileBase_Keyboard:OnMouseDoubleClick()
    if self:CanPerformAction("primary") then
        return self:PerformAction("primary")
    end
end

function ZO_AntiquityTileBase_Keyboard:ShowTooltip()
    -- tileData will be either an antiquityData or antiquitySetData
    -- figure out which and assign appropriately
    local antiquityData
    local antiquitySetData
    if self.tileData:GetType() == ZO_ANTIQUITY_TYPE_INDIVIDUAL then
        antiquityData = self.tileData
        antiquitySetData = antiquityData:GetAntiquitySetData()
    else
        antiquitySetData = self.tileData
    end

    -- Overall we want to show the reward for discovering this antiquity or set
    -- and if this antiquity is part of a set (a set fragment) we want to show the tooltip
    -- for that as well
    if antiquityData and antiquityData:HasDiscovered() then
        if antiquitySetData then
            InitializeTooltip(AntiquityTooltip, self.control, TOPLEFT, 0, 5, BOTTOMLEFT)
            AntiquityTooltip:SetAntiquitySetFragment(antiquityData:GetId())
        elseif antiquityData:HasReward() then
            ZO_LayoutAntiquityRewardTooltip_Keyboard(antiquityData, self.control, RIGHT, LEFT)
        end
    end

    if antiquitySetData and antiquitySetData:HasDiscovered() then
        if antiquitySetData:HasReward() then
            ZO_LayoutAntiquityRewardTooltip_Keyboard(antiquitySetData, self.control, RIGHT, LEFT)
        end
    end
end

function ZO_AntiquityTileBase_Keyboard:HideTooltip(antiquitySetId)
    -- this mirrors the ShowTooltip function in order to figure out
    -- which tooltips to clear
    local antiquityData
    local antiquitySetData
    if self.tileData:GetType() == ZO_ANTIQUITY_TYPE_INDIVIDUAL then
        antiquityData = self.tileData
        antiquitySetData = antiquityData:GetAntiquitySetData()
    else
        antiquitySetData = self.tileData
    end

    if antiquityData and antiquityData:HasDiscovered() then
        if antiquitySetData then
            ClearTooltip(AntiquityTooltip)
        elseif antiquityData:HasReward() then
            ZO_Rewards_Shared_OnMouseExit(self.control)
        end

        if antiquityData:HasNewLead() then
            antiquityData:ClearNewLead()
        end
    end

    if antiquitySetData and antiquitySetData:HasDiscovered() then
        if antiquitySetData:HasReward() then
            ZO_Rewards_Shared_OnMouseExit(self.control)
        end
    end
end

-- Antiquity Tile

ZO_AntiquityTile_Keyboard = ZO_AntiquityTileBase_Keyboard:Subclass()

function ZO_AntiquityTile_Keyboard:New(...)
    return ZO_AntiquityTileBase_Keyboard.New(self, ...)
end

function ZO_AntiquityTile_Keyboard:Initialize(control)
    self.colorizeLabels = true
    ZO_AntiquityTileBase_Keyboard.Initialize(self, control)
    self.logBookProgressContainer = control:GetNamedChild("HeaderLogBookProgress")
    self.logBookProgress = self.logBookProgressContainer:GetNamedChild("Progress")
    self.logBook = self.logBookProgressContainer:GetNamedChild("LogBook")
    self.actions =
    {
        ["primary"] =
        {
            label = GetString(SI_ANTIQUITY_LOG_BOOK),
            visible = function()
                return self.tileData:HasDiscovered() and self.tileData:GetNumLoreEntries() > 0
            end,
            execute = function()
                ANTIQUITY_LORE_KEYBOARD:ShowAntiquity(self:GetAntiquityId())
            end,
        },
    }
end

function ZO_AntiquityTile_Keyboard:GetAntiquityId()
    return self.tileData and self.tileData:GetId() or 0
end

function ZO_AntiquityTile_Keyboard:Layout(antiquityId)
    self:Reset()
    self.tileData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)
    self:Refresh()
end

function ZO_AntiquityTile_Keyboard:Refresh()
    ZO_AntiquityTileBase_Keyboard.Refresh(self)

    local tileData = self.tileData
    local numLoreEntries = tileData:GetNumLoreEntries()
    local hasDiscovered = tileData:HasDiscovered()
    local hasRecovered = tileData:HasRecovered()
    local labelColor = hasRecovered and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT

    if hasDiscovered and numLoreEntries > 0 then
        self.logBook:SetColor(labelColor:UnpackRGB())
        self.logBookProgress:SetText(string.format("%d / %d", tileData:GetNumUnlockedLoreEntries(), numLoreEntries))
        local progressColor = hasRecovered and ZO_DEFAULT_ENABLED_COLOR or ZO_DISABLED_TEXT
        self.logBookProgress:SetColor(progressColor:UnpackRGB())
        self.logBookProgressContainer:SetHidden(false)
    else
        self.logBookProgressContainer:SetHidden(true)
    end
end

-- Antiquity Set Tile

ZO_AntiquitySetTile_Keyboard = ZO_AntiquityTileBase_Keyboard:Subclass()

function ZO_AntiquitySetTile_Keyboard:New(...)
    return ZO_AntiquityTileBase_Keyboard.New(self, ...)
end

function ZO_AntiquitySetTile_Keyboard:Initialize(control)
    self.colorizeLabels = true
    ZO_AntiquityTileBase_Keyboard.Initialize(self, control)
    self.antiquities = control:GetNamedChild("Antiquities")
    self.antiquitiesRecoveredLabel = control:GetNamedChild("AntiquitiesRecovered")
    self.logBookProgressContainer = control:GetNamedChild("HeaderLogBookProgress")
    self.logBookProgress = self.logBookProgressContainer:GetNamedChild("Progress")
    self.logBook = self.logBookProgressContainer:GetNamedChild("LogBook")
    self.actions =
    {
        ["primary"] =
        {
            label = GetString(SI_ANTIQUITY_LOG_BOOK),
            visible = function()
                return self.tileData:HasDiscovered() and self.tileData:GetNumLoreEntries() > 0
            end,
            execute = function()
                ANTIQUITY_LORE_KEYBOARD:ShowAntiquitySet(self:GetAntiquitySetId())
            end,
        },
    }
end

function ZO_AntiquitySetTile_Keyboard:SetupAntiquityIconMetaPool(antiquityIconControlPool)
    self.antiquityIconMetaPool = ZO_MetaPool:New(antiquityIconControlPool)
end

function ZO_AntiquitySetTile_Keyboard:GetAntiquitySetId()
    return self.tileData and self.tileData:GetId() or 0
end

function ZO_AntiquitySetTile_Keyboard:Reset()
    ZO_AntiquityTileBase_Keyboard.Reset(self)
    -- remove all of the icons from antiquityIconMetaPool from our mouseover group
    local excludedControls = { self.icon }
    self.mouseInputGroup:RemoveAll(ZO_MOUSE_INPUT_GROUP_MOUSE_OVER, excludedControls)
    self.antiquityIconMetaPool:ReleaseAllObjects()
end

function ZO_AntiquitySetTile_Keyboard:Refresh()
    ZO_AntiquityTileBase_Keyboard.Refresh(self)
    local hasDiscovered = self.tileData:HasDiscovered()

    if hasDiscovered then
        local tileData = self.tileData
        local hasRecovered = tileData:HasRecovered()
        local numLoreEntries = tileData:GetNumLoreEntries()
        local labelColor = hasRecovered and ZO_NORMAL_TEXT or ZO_DISABLED_TEXT
        local previousItem, firstItemInRow
        local rowItemCount = 0

        for _, antiquityData in tileData:AntiquityIterator() do
            local iconControl = self.antiquityIconMetaPool:AcquireObject()
            iconControl:SetParent(self.antiquities)
            ZO_AntiquityIcon_SetData(iconControl, antiquityData)
            self.mouseInputGroup:Add(iconControl, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)

            if previousItem then
                if rowItemCount >= MAX_ICONS_PER_ROW then
                    rowItemCount = 0
                    iconControl:SetAnchor(TOPLEFT, firstItemInRow, BOTTOMLEFT, nil, 12)
                    firstItemInRow = iconControl
                else
                    iconControl:SetAnchor(TOPLEFT, previousItem, TOPRIGHT, 14)
                end
            else
                iconControl:SetAnchor(TOPLEFT, self.antiquities, TOPLEFT, nil, 8)
            end

            if not firstItemInRow then
                firstItemInRow = iconControl
            end

            previousItem = iconControl
            rowItemCount = rowItemCount + 1
        end

        self.antiquities:SetHidden(false)

        local numAntiquities = tileData:GetNumAntiquities()
        local numAntiquitiesRecovered = tileData:GetNumAntiquitiesRecovered()
        if hasRecovered then
            numAntiquities = ZO_SELECTED_TEXT:Colorize(numAntiquities)
            numAntiquitiesRecovered = ZO_SELECTED_TEXT:Colorize(numAntiquitiesRecovered)
        else
            numAntiquities = ZO_DISABLED_TEXT:Colorize(numAntiquities)
            numAntiquitiesRecovered = ZO_DISABLED_TEXT:Colorize(numAntiquitiesRecovered)
        end

        self.antiquitiesRecoveredLabel:SetText(zo_strformat(SI_ANTIQUITY_PIECES_FOUND, numAntiquitiesRecovered, numAntiquities))
        self.antiquitiesRecoveredLabel:SetColor(labelColor:UnpackRGB())
        self.antiquitiesRecoveredLabel:SetHidden(false)

        if numLoreEntries > 0 then
            self.logBook:SetColor(labelColor:UnpackRGB())
            self.logBookProgress:SetText(string.format("%d / %d", tileData:GetNumUnlockedLoreEntries(), numLoreEntries))
            self.logBookProgress:SetColor((hasRecovered and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT):UnpackRGB())
            self.logBookProgressContainer:SetHidden(false)
        else
            self.logBookProgressContainer:SetHidden(true)
        end
    else
        self.antiquities:SetHidden(true)
        self.antiquitiesRecoveredLabel:SetHidden(true)
        self.logBookProgressContainer:SetHidden(true)
    end
end

function ZO_AntiquitySetTile_Keyboard:Layout(antiquitySetId)
    self:Reset()
    self.tileData = ANTIQUITY_DATA_MANAGER:GetAntiquitySetData(antiquitySetId)
    self:Refresh()
end

-- Scryable Antiquity Tile

ZO_ScryableAntiquityTile_Keyboard = ZO_AntiquityTileBase_Keyboard:Subclass()

function ZO_ScryableAntiquityTile_Keyboard:New(...)
    return ZO_AntiquityTileBase_Keyboard.New(self, ...)
end

function ZO_ScryableAntiquityTile_Keyboard:Initialize(control)
    self.colorizeLabels = false
    ZO_AntiquityTileBase_Keyboard.Initialize(self, control)
    self.difficulty = self.header:GetNamedChild("Difficulty")
    self.zoneLabel = self.header:GetNamedChild("Zone")
    self.leadExpiration = self.header:GetNamedChild("LeadExpiration")
    self.progressIcons = control:GetNamedChild("ProgressIcons")
    self.actions =
    {
        ["showOnMap"] =
        {
            label = GetString(SI_QUEST_JOURNAL_SHOW_ON_MAP),
            visible = function()
                return self.tileData:HasDiscoveredDigSites()
            end,
            execute = function()
                local antiquityId = self:GetAntiquityId()
                SetTrackedAntiquityId(antiquityId)
                WORLD_MAP_MANAGER:ShowAntiquityOnMap(antiquityId)
            end,
        },
        ["negative"] =
        {
            label = GetString(SI_ANTIQUITY_ABANDON),
            visible = function()
                return self.tileData:HasDiscoveredDigSites()
            end,
            execute = function()
                ZO_Dialogs_ShowDialog("CONFIRM_ABANDON_ANTIQUITY_SCRYING_PROGRESS", { antiquityId = self:GetAntiquityId() })
            end,
        },
        ["tertiary"] =
        {
            label = GetString(SI_ANTIQUITY_VIEW_IN_CODEX),
            execute = function()
                local categoryData = self.tileData:GetAntiquityCategoryData()
                ANTIQUITY_JOURNAL_KEYBOARD:ShowCategory(categoryData:GetId(), self.tileData:GetFormattedName())
            end,
        },
        ["primary"] =
        {
            label = GetString(SI_ANTIQUITY_SCRY),
            enabled = function()
                local canScry, scryResultMessage = self.tileData:CanScry()
                return canScry, scryResultMessage
            end,
            visible = function()
                return self.tileData:HasDiscovered()
            end,
            execute = function()
                ScryForAntiquity(self:GetAntiquityId())
            end,
        },
    }
end

function ZO_ScryableAntiquityTile_Keyboard:SetupProgressIconMetaPool(progressIconControlPool)
    self.progressIconMetaPool = ZO_MetaPool:New(progressIconControlPool)
end

function ZO_ScryableAntiquityTile_Keyboard:GetAntiquityId()
    return self.tileData and self.tileData:GetId() or 0
end

function ZO_ScryableAntiquityTile_Keyboard:Layout(antiquityId)
    self:Reset()
    self.tileData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)
    self:Refresh()
end

function ZO_ScryableAntiquityTile_Keyboard:Refresh(...)
    ZO_AntiquityTileBase_Keyboard.Refresh(self, ...)
    local tileData = self.tileData
    local hasDiscovered = tileData:HasDiscovered()

    if hasDiscovered then
        local difficultyColor = ZO_SELECTED_TEXT
        if not tileData:MeetsScryingSkillRequirements() then
            difficultyColor = ZO_ERROR_COLOR
        end
        local difficultyString = difficultyColor:Colorize(GetString("SI_ANTIQUITYDIFFICULTY", tileData:GetDifficulty()))
        self.difficulty:SetText(zo_strformat(SI_ANTIQUITY_DIFFICULTY_FORMATTER, difficultyString))
        self.difficulty:SetColor(ZO_NORMAL_TEXT:UnpackRGB())
        self.difficulty:ClearAnchors()
        if tileData:HasReward() or tileData:IsRepeatable() then
            self.difficulty:SetAnchor(TOPLEFT, self.title, BOTTOMLEFT, 0, 22)
        else
            self.difficulty:SetAnchor(TOPLEFT, self.title, BOTTOMLEFT)
        end
        self.difficulty:SetHidden(false)

        local zoneId = tileData:GetZoneId()
        --If the zone id is 0, it means that there is no zone to display
        if zoneId ~= 0 then
            local zoneName = GetZoneNameById(zoneId)
            self.zoneLabel:SetText(zo_strformat(SI_ANTIQUITY_ZONE, ZO_SELECTED_TEXT:Colorize(zoneName)))
            self.zoneLabel:SetHidden(false)
        else
            self.zoneLabel:SetHidden(true)
        end

        local leadTimeRemainingS = tileData:GetLeadTimeRemainingS()
        if leadTimeRemainingS > 0 then
            local leadTimeRemainingText = ZO_FormatAntiquityLeadTime(leadTimeRemainingS)
            self.leadExpiration:SetText(zo_strformat(SI_ANTIQUITY_TOOLTIP_LEAD_EXPIRATION, leadTimeRemainingText))
            self.leadExpiration:SetHidden(false)
        else
            self.leadExpiration:SetHidden(true)
        end

        local numGoalsAchieved = tileData:GetNumGoalsAchieved()
        if numGoalsAchieved > 0 then
            local previousItem
            local totalNumGoals = tileData:GetTotalNumGoals()
            for goalIndex = 1, totalNumGoals do
                local iconControl = self.progressIconMetaPool:AcquireObject()
                iconControl:SetParent(self.progressIcons)
                if numGoalsAchieved >= goalIndex then
                    iconControl:SetTexture(ZO_DIGSITE_COMPLETE_ICON_TEXTURE)
                else
                    iconControl:SetTexture(ZO_DIGSITE_UNKNOWN_ICON_TEXTURE)
                end
                if previousItem then
                    iconControl:SetAnchor(TOPLEFT, previousItem, TOPRIGHT, 2)
                else
                    iconControl:SetAnchor(TOPLEFT)
                end
                previousItem = iconControl
            end
        end
        self.progressIcons:ClearAnchors()
        if leadTimeRemainingS > 0 then
            self.progressIcons:SetAnchor(TOPLEFT, self.leadExpiration, BOTTOMLEFT, 0, 4)
        else
            self.progressIcons:SetAnchor(TOPLEFT, self.difficulty, BOTTOMLEFT, 0, 4)
        end
        self.progressIcons:SetHidden(false)
    else
        self.difficulty:SetHidden(true)
        self.leadExpiration:SetHidden(true)
        self.progressIcons:SetHidden(true)
        self.zoneLabel:SetHidden(true)
    end
end

function ZO_ScryableAntiquityTile_Keyboard:Reset()
    ZO_AntiquityTileBase_Keyboard.Reset(self)
    self.progressIconMetaPool:ReleaseAllObjects()
end

-- Antiquity Journal

ZO_AntiquityJournal_Keyboard = ZO_Object:Subclass()

function ZO_AntiquityJournal_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_AntiquityJournal_Keyboard:Initialize(control)
    self.control = control
    self.antiquityTilesByAntiquityId = {}
    self.antiquitySetTilesByAntiquitySetId = {}
    self.categoryNodeLookupData = {}

    self:InitializeKeybindDescriptors()
    self:InitializeControls()
    self:InitializeCategories()
    self:InitializeScene()
    self:InitializeEvents()
    self:InitializeFilters()
end

function ZO_AntiquityJournal_Keyboard:InitializeKeybindDescriptors()
    self.keybindStripDescriptor = {}

    local function AddKeybindDescriptor(actionIndex, keybind)
        local keybindDescriptor =
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            keybind = keybind,
            name = function()
                return self:GetMouseOverTile():GetActionLabel(actionIndex)
            end,
            callback = function()
                return self:GetMouseOverTile():PerformAction(actionIndex)
            end,
            enabled = function()
                local tile = self:GetMouseOverTile()
                if tile then
                    local isEnabled, alertMessage = tile:CanPerformAction(actionIndex)
                    if isEnabled == nil then
                        return true
                    else
                        return isEnabled, alertMessage
                    end
                else
                    return true
                end
            end,
            visible = function()
                local tile = self:GetMouseOverTile()
                return tile and tile:IsActionVisible(actionIndex)
            end,
        }
        table.insert(self.keybindStripDescriptor, keybindDescriptor)
    end

    AddKeybindDescriptor("tertiary", "UI_SHORTCUT_TERTIARY")
    AddKeybindDescriptor("showOnMap", "UI_SHORTCUT_SHOW_QUEST_ON_MAP")
    AddKeybindDescriptor("negative", "UI_SHORTCUT_NEGATIVE")
    AddKeybindDescriptor("primary", "UI_SHORTCUT_PRIMARY")
end

function ZO_AntiquityJournal_Keyboard:InitializeControls()
    -- Initialize static controls.
    self.contents = self.control:GetNamedChild("Contents")
    self.contentEmptyLabel = self.contents:GetNamedChild("ContentEmptyLabel")
    self.contentsCategories = self.contents:GetNamedChild("Categories")
    self.lockedContentPanel = self.contents:GetNamedChild("LockedContentPanel")
    self.antiquarianGuildZoneLockedLabel = self.lockedContentPanel:GetNamedChild("AntiquarianGuildZoneLockedLabel")
    self.scryingToolLockedLabel = self.lockedContentPanel:GetNamedChild("ScryingToolLockedLabel")
    self.upgradeContentButton = self.lockedContentPanel:GetNamedChild("UpgradeContentButton")
    self.contentList = self.contents:GetNamedChild("ContentList")
    self.contentListScrollChild = self.contentList:GetNamedChild("ScrollChild")
    self.categoryInset = self.contents:GetNamedChild("Category")
    self.categoryLabel = self.categoryInset:GetNamedChild("Title")
    self.categoryProgress = self.categoryInset:GetNamedChild("Progress")
    self.contentSearchEditBox = self.contents:GetNamedChild("SearchBox")
    self.filter = self.categoryInset:GetNamedChild("Filter")
    ZO_StatusBar_SetGradientColor(self.categoryProgress, ZO_XP_BAR_GRADIENT_COLORS)

    -- Initialize resource pools.
    local function ResetIconControl(control)
        control:SetParent(nil)
        control.antiquityData = nil
    end

    self.antiquityHeadingControlPool = ZO_ControlPool:New("ZO_AntiquityScryableHeading_Keyboard", self.contentListScrollChild, "AntiquityScryableHeading_Keyboard")

    self.antiquityIconControlPool = ZO_ControlPool:New("ZO_AntiquityFragmentIcon", self.control, "AntiquityIcon")
    self.antiquityIconControlPool:SetCustomResetBehavior(ResetIconControl)
    
    self.progressIconControlPool = ZO_ControlPool:New("ZO_AntiquityProgressIcon", self.control, "AntiquityProgressIcon")
    self.progressIconControlPool:SetCustomResetBehavior(ResetIconControl)

    local function ResetTileControl(control)
        control.owner:Reset()
    end

    self.antiquityTileControlPool = ZO_ControlPool:New("ZO_AntiquityTileControl_Keyboard", self.contentListScrollChild, "Antiquity")
    self.antiquityTileControlPool:SetCustomResetBehavior(ResetTileControl)

    self.antiquitySetTileControlPool = ZO_ControlPool:New("ZO_AntiquitySetTileControl_Keyboard", self.contentListScrollChild, "AntiquitySet")
    self.antiquitySetTileControlPool:SetCustomFactoryBehavior(function(control) control.owner:SetupAntiquityIconMetaPool(self.antiquityIconControlPool) end)
    self.antiquitySetTileControlPool:SetCustomResetBehavior(ResetTileControl)

    self.scryableAntiquityTileControlPool = ZO_ControlPool:New("ZO_ScryableAntiquityTileControl_Keyboard", self.contentListScrollChild, "ScryableAntiquity")
    self.scryableAntiquityTileControlPool:SetCustomFactoryBehavior(function(control) control.owner:SetupProgressIconMetaPool(self.progressIconControlPool) end)
    self.scryableAntiquityTileControlPool:SetCustomResetBehavior(ResetTileControl)
end

function ZO_AntiquityJournal_Keyboard:UpdateCategoryStatusIcon(categoryId)
    local categoryNode = self.categoryNodeLookupData[categoryId]
    if categoryNode then
        self:UpdateCategoryNodeStatusIcon(categoryNode)
    end
end

function ZO_AntiquityJournal_Keyboard:UpdateCategoryNodeStatusIcon(categoryNode)
    if categoryNode then
        local categoryControl = categoryNode.control
        if not categoryControl.statusIcon then
            categoryControl.statusIcon = categoryControl:GetNamedChild("StatusIcon")
        end
        categoryControl.statusIcon:ClearIcons()
        local categoryData = categoryNode.data
        if categoryData:HasNewLead() then
            categoryControl.statusIcon:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end
        categoryControl.statusIcon:Show()
    end
end

function ZO_AntiquityJournal_Keyboard:InitializeCategories()
    self.categories = self.control:GetNamedChild("ContentsCategories")
    self.categoryTree = ZO_Tree:New(self.categories:GetNamedChild("ScrollChild"), 0, -10, 290)

    local function BaseTreeHeaderIconSetup(control, data, open, updateSizeFunction)
        local normalIcon, pressedIcon, mousedOverIcon = data:GetKeyboardIcons()
        control.icon:SetTexture(open and pressedIcon or normalIcon)
        control.iconHighlight:SetTexture(mousedOverIcon)
        local ENABLED = true
        local DISABLE_SCALING = false
        ZO_IconHeader_Setup(control, open, ENABLED, DISABLE_SCALING, updateSizeFunction)
    end

    local function BaseTreeHeaderSetup(node, control, data, open, updateSizeFunction)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(data:GetName())
        BaseTreeHeaderIconSetup(control, data, open, updateSizeFunction)
        self:UpdateCategoryNodeStatusIcon(node)
    end

    local function TreeHeaderSetup_Child(node, control, data, open, userRequested)
        BaseTreeHeaderSetup(node, control, data, open)
        if open and userRequested then
            self.categoryTree:SelectFirstChild(node)
        end
    end

    local function TreeHeaderSetup_Childless(node, control, data, open)
        BaseTreeHeaderSetup(node, control, data, open)
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)
        if selected and (not reselectingDuringRebuild or self.forceUpdateContentOnCategoryReselect) then
            self:OnCategorySelected(data)
        end
    end

    local function TreeEntryOnSelected_Childless(control, data, selected, reselectingDuringRebuild)
        TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        BaseTreeHeaderIconSetup(control, data, selected)
    end

    local function TreeEntrySetup(node, control, data, open)
        control:SetSelected(false)
        control:SetText(ZO_CachedStrFormat(SI_ZONE_NAME, data:GetName()))
        self:UpdateCategoryNodeStatusIcon(node)
    end

    local function TreeEqualityFunction(left, right)
        return left:GetId() == right:GetId()
    end

    -- Define the templates that are to be used by the tree view control.
    local CHILD_INDENT = 74
    local CHILD_SPACING = 0
    self.categoryTree:AddTemplate("ZO_AntiquityJournal_StatusIconHeader", TreeHeaderSetup_Child, nil, TreeEqualityFunction, CHILD_INDENT, CHILD_SPACING)
    self.categoryTree:AddTemplate("ZO_AntiquityJournal_StatusIconChildlessHeader", TreeHeaderSetup_Childless, TreeEntryOnSelected_Childless, TreeEqualityFunction)
    self.categoryTree:AddTemplate("ZO_AntiquityJournal_SubCategory", TreeEntrySetup, TreeEntryOnSelected, TreeEqualityFunction)
    self.categoryTree:SetExclusive(true)
    self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function ZO_AntiquityJournal_Keyboard:InitializeScene()
    self.scene = ZO_Scene:New("antiquityJournalKeyboard", SCENE_MANAGER)
    SYSTEMS:RegisterKeyboardRootScene("antiquityJournalKeyboard", self.scene)
    ANTIQUITY_JOURNAL_KEYBOARD_SCENE = self.scene

    self.scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            ANTIQUITY_DATA_MANAGER:SetSearch(self.contentSearchEditBox:GetText())
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            TriggerTutorial(TUTORIAL_TRIGGER_ANTIQUITY_JOURNAL_OPENED)
            self.refreshGroups:RefreshAll("AntiquitiesUpdated")
        elseif newState == SCENE_HIDING then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end)
end

function ZO_AntiquityJournal_Keyboard:InitializeEvents()
    -- Define refresh groups.
    self.refreshGroups = ZO_Refresh:New()
    self.refreshGroups:AddRefreshGroup("AntiquitiesUpdated", {
        RefreshAll = function()
            self:OnAntiquitiesUpdated()
        end,
    })

    -- Register event handlers that flag refresh groups as dirty when necessary.
    local function OnAntiquitiesUpdated()
        self.refreshGroups:RefreshAll("AntiquitiesUpdated")
        MAIN_MENU_KEYBOARD:RefreshCategoryIndicators()
    end
    ANTIQUITY_DATA_MANAGER:RegisterCallback("AntiquitiesUpdated", OnAntiquitiesUpdated)
    ANTIQUITY_DATA_MANAGER:RegisterCallback("SingleAntiquityUpdated", OnAntiquitiesUpdated)
    ANTIQUITY_DATA_MANAGER:RegisterCallback("SingleAntiquityDigSitesUpdated", OnAntiquitiesUpdated)
    ANTIQUITY_MANAGER:RegisterCallback("OnContentLockChanged", OnAntiquitiesUpdated)

    local function OnSingleAntiquityLeadUpdated(data)
        self:OnSingleAntiquityLeadUpdated(data)
    end
    ANTIQUITY_DATA_MANAGER:RegisterCallback("SingleAntiquityLeadAcquired", OnSingleAntiquityLeadUpdated)
    ANTIQUITY_DATA_MANAGER:RegisterCallback("SingleAntiquityNewLeadCleared", OnSingleAntiquityLeadUpdated)

    local function OnPlayerActivated()
        OnAntiquitiesUpdated()
    end
    EVENT_MANAGER:RegisterForEvent("AntiquityJournal_Keyboard", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

    local function OnUpdate()
        self.refreshGroups:UpdateRefreshGroups()
    end
    self.control:SetHandler("OnUpdate", OnUpdate)

    local function OnUpdateSearchResults()
        if self.scene:IsShowing() then
            self.forceUpdateContentOnCategoryReselect = true
            self:RefreshCategories()
            self.forceUpdateContentOnCategoryReselect = false
        end
    end
    ANTIQUITY_DATA_MANAGER:RegisterCallback("UpdateSearchResults", OnUpdateSearchResults)
end

function ZO_AntiquityJournal_Keyboard:InitializeFilters()
    local comboBox = ZO_ComboBox_ObjectFromContainer(self.filter)
    comboBox:SetSortsItems(false)
    comboBox:SetFont("ZoFontWinT1")
    comboBox:SetSpacing(4)

    local function OnFilterChanged(comboBox, entryText, entry)
        self:SetFilterType(entry.filterType)
    end

    for filterType = ANTIQUITY_FILTER_ITERATION_BEGIN, ANTIQUITY_FILTER_ITERATION_END do
        local entry = comboBox:CreateItemEntry(GetString("SI_ANTIQUITYFILTER", filterType), OnFilterChanged)
        entry.filterType = filterType
        comboBox:AddItem(entry)
    end

    comboBox:SelectFirstItem()
end

function ZO_AntiquityJournal_Keyboard:ShowLockedContentPanel()
    local isAntiquarianGuildZoneUnlocked = ZO_IsAntiquarianGuildUnlocked()
    local isScryingToolUnlocked = ZO_IsScryingToolUnlocked()
    local areSkillLinesDiscovered = AreAntiquitySkillLinesDiscovered()
    local isScryingUnlocked = isScryingToolUnlocked and areSkillLinesDiscovered

    if not isAntiquarianGuildZoneUnlocked then
        self.antiquarianGuildZoneLockedLabel:SetText(ANTIQUITY_MANAGER:GetAntiquarianGuildZoneLockedMessage())
    end
    self.antiquarianGuildZoneLockedLabel:SetHidden(isAntiquarianGuildZoneUnlocked)

    if not isScryingUnlocked then
        self.scryingToolLockedLabel:SetText(ANTIQUITY_MANAGER:GetScryingLockedMessage())
    end
    self.scryingToolLockedLabel:SetHidden(isScryingUnlocked)
    self.upgradeContentButton:SetHidden(isAntiquarianGuildZoneUnlocked)

    self.filter:SetHidden(true)
    self.categoryProgress:SetHidden(true)
    self.contentList:SetHidden(true)
    self.contentEmptyLabel:SetHidden(true)
    self.lockedContentPanel:SetHidden(false)
end

function ZO_AntiquityJournal_Keyboard:HideLockedContentPanel()
    self.lockedContentPanel:SetHidden(true)
    self.contentList:SetHidden(false)
end

function ZO_AntiquityJournal_Keyboard:ResetTiles()
    -- Reset all tiles and lookup indexes.
    self:ClearMouseOverTile(self.mouseOverTile)
    self.antiquityHeadingControlPool:ReleaseAllObjects()
    self.antiquityTileControlPool:ReleaseAllObjects()
    self.antiquitySetTileControlPool:ReleaseAllObjects()
    self.scryableAntiquityTileControlPool:ReleaseAllObjects()
    ZO_ClearTable(self.antiquityTilesByAntiquityId)
    ZO_ClearTable(self.antiquitySetTilesByAntiquitySetId)
end

do
    local filterCategories
    local filterAntiquities
    local filterAntiquitySets

    function ZO_AntiquityJournal_Keyboard:GetFilterTypeFunction()
        if self.filterType then
            return ANTIQUITY_DATA_MANAGER:GetAntiquityFilterFunction(self.filterType)
        end
    end

    function ZO_AntiquityJournal_Keyboard:SetFilterType(filterType)
        self.filterType = filterType
        self.filterTypeFunction = self:GetFilterTypeFunction()
        self:RefreshCategories()
    end

    function ZO_AntiquityJournal_Keyboard:ResetFilters() 
        ZO_ComboBox_ObjectFromContainer(self.filter):SelectFirstItem()
    end

    function ZO_AntiquityJournal_Keyboard:MeetsFilterCriteria(...)
        if self.filterTypeFunction then
            return self.filterTypeFunction(...)
        else
            return true
        end
    end

    function ZO_AntiquityJournal_Keyboard:AddScryableAntiquityTiles(previousTileOrHeading, headingText, antiquities, sortFunction)
        table.sort(antiquities, sortFunction)

        local headingControl = self.antiquityHeadingControlPool:AcquireObject()
        headingControl:GetNamedChild("Label"):SetText(headingText)
        if previousTileOrHeading then
            if type(previousTileOrHeading) ~= "userdata" then
                previousTileOrHeading = previousTileOrHeading.control
            end
            headingControl:SetAnchor(TOPLEFT, previousTileOrHeading, BOTTOMLEFT, 0, 10)
        else
            headingControl:SetAnchor(TOPLEFT, nil, nil, 0, 6)
        end
        previousTileOrHeading = headingControl

        for _, antiquityData in ipairs(antiquities) do
            -- Add this scryable antiquity as a tile.
            local antiquityId = antiquityData:GetId()
            local tileControl = self.scryableAntiquityTileControlPool:AcquireObject()
            local tileObject = tileControl.owner
            tileObject:Layout(antiquityId)
            tileObject:SetPredecessorTileOrHeading(previousTileOrHeading)
            previousTileOrHeading = tileObject
            self.antiquityTilesByAntiquityId[antiquityId] = tileObject
        end
        return previousTileOrHeading
    end

    function ZO_AntiquityJournal_Keyboard:AddAntiquitySetTile(previousTileOrHeading, antiquitySetId)
        -- Add this antiquity's set as a tile if the antiquity set has not already been added.
        local tileControl = self.antiquitySetTileControlPool:AcquireObject()
        local tileObject = tileControl.owner
        tileObject:Layout(antiquitySetId)
        tileObject:SetPredecessorTileOrHeading(previousTileOrHeading)
        return tileObject
    end

    function ZO_AntiquityJournal_Keyboard:AddAntiquityTile(previousTileOrHeading, antiquityId)
        -- Add this antiquity as a tile.
        local tileControl = self.antiquityTileControlPool:AcquireObject()
        local tileObject = tileControl.owner
        tileObject:Layout(antiquityId)
        tileObject:SetPredecessorTileOrHeading(previousTileOrHeading)
        return tileObject
    end

    function ZO_AntiquityJournal_Keyboard:ResetCategoryTiles(shouldHideProgressBar)
        self:ResetTiles()
        ZO_Scroll_ResetToTop(self.contentList)
        self.contentList:SetHidden(true)
        self.contentList:ClearAnchors()
        self.contentList:SetAnchor(BOTTOMRIGHT, nil, nil, -10, -75)

        if shouldHideProgressBar then
            self.categoryProgress:SetHidden(true)
            self.contentList:SetAnchor(TOPLEFT, self.categoryInset, BOTTOMLEFT, nil, 15)
            self.filter:SetHidden(true)
        else
            self.contentList:SetAnchor(TOPLEFT, self.categoryInset, BOTTOMLEFT, nil, 25)
        end
    end

    function ZO_AntiquityJournal_Keyboard:BuildCategoryAntiquityTiles(categoryData)
        local isEmptyList = true
        local horizontalScrollOffset
        local verticalScrollOffset

        if self.isRefreshingAll then
            horizontalScrollOffset, verticalScrollOffset = self.contentList.scroll:GetScrollOffsets()
        end

        -- ResetCategoryTiles will end up clearing the mouseover control
        -- so save it off before calling it
        local oldMouseOverTile = self.mouseOverTile

        local isScryableSubcategory = ZO_IsAntiquityScryableSubcategory(categoryData)
        self:ResetCategoryTiles(isScryableSubcategory)

        if isScryableSubcategory then
            local antiquitySections = ANTIQUITY_MANAGER:GetOrCreateAntiquitySectionList()

            -- Iterate over all antiquities in the subcategory, adding each antiquity to the section whose criteria it meets (if any).
            for _, antiquityData in categoryData:AntiquityIterator({ZO_Antiquity.IsVisible}) do
                for _, antiquitySection in ipairs(antiquitySections) do
                    if ANTIQUITY_MANAGER:ShouldScryableSubcategoryShowSection(categoryData, antiquitySection) then
                        local passesFilter = true
                        for _, filterFunction in ipairs(antiquitySection.filterFunctions) do
                            if not filterFunction(antiquityData) then
                                passesFilter = false
                                break
                            end
                        end
                        if passesFilter then
                            table.insert(antiquitySection.list, antiquityData)
                            break
                        end
                    end
                end
            end

            -- Sort each sections' list by the associated sort function.
            local previousTileOrHeading
            for _, antiquitySection in ipairs(antiquitySections) do
                if #antiquitySection.list ~= 0 then
                    isEmptyList = false
                    previousTileOrHeading = self:AddScryableAntiquityTiles(previousTileOrHeading, antiquitySection.sectionHeading, antiquitySection.list, antiquitySection.sortFunction)
                end
            end
        else
            local maxLoreEntries = 0
            local unlockedLoreEntries = 0

            local previousTileOrHeading
            for _, antiquityData in categoryData:AntiquityIterator({ZO_Antiquity.IsVisible}) do
                local antiquitySetData = antiquityData:GetAntiquitySetData()

                if self:MeetsFilterCriteria(antiquityData, antiquitySetData) then
                    local antiquityId = antiquityData:GetId()
                    local antiquitySetId = antiquitySetData and antiquitySetData:GetId()
                    if not filterAntiquities or filterAntiquities[antiquityId] or (antiquitySetId and filterAntiquitySets[antiquitySetId]) then
                        if antiquitySetId then
                            local antiquitySetTile = self.antiquitySetTilesByAntiquitySetId[antiquitySetId]
                            if not antiquitySetTile then
                                antiquitySetTile = self:AddAntiquitySetTile(previousTileOrHeading, antiquitySetId)
                                self.antiquitySetTilesByAntiquitySetId[antiquitySetId] = antiquitySetTile
                                previousTileOrHeading = antiquitySetTile
                            end
                            self.antiquityTilesByAntiquityId[antiquityId] = antiquitySetTile
                        else
                            previousTileOrHeading = self:AddAntiquityTile(previousTileOrHeading, antiquityId)
                            self.antiquityTilesByAntiquityId[antiquityId] = previousTileOrHeading
                        end
                        maxLoreEntries = maxLoreEntries + previousTileOrHeading.tileData:GetNumLoreEntries()
                        unlockedLoreEntries = unlockedLoreEntries + previousTileOrHeading.tileData:GetNumUnlockedLoreEntries()
                    end
                end
            end

            isEmptyList = previousTileOrHeading == nil
            if maxLoreEntries > 0 then
                self.categoryProgress:SetValue(unlockedLoreEntries / maxLoreEntries)
            else
                self.categoryProgress:SetValue(0)
            end

            self.categoryProgress:SetHidden(false)
            self.filter:SetHidden(false)
        end

        self.contentList:SetHidden(isEmptyList)
        self.contentEmptyLabel:SetHidden(not isEmptyList)

        if verticalScrollOffset then
            ZO_Scroll_ScrollAbsoluteInstantly(self.contentList, verticalScrollOffset)
        end

        if oldMouseOverTile and not oldMouseOverTile:IsControlHidden() then
            self:SetMouseOverTile(oldMouseOverTile)
        end
    end

    function ZO_AntiquityJournal_Keyboard:UpdateCategoryLabels(categoryData)
        -- Refresh category-specific controls and all tiles.
        self.categoryInset:ClearAnchors()
        self.categoryInset:SetAnchor(TOPRIGHT, nil, nil, -12, 11)
        if ZO_IsAntiquityScryableSubcategory(categoryData) then
            self.categoryInset:SetAnchor(BOTTOMLEFT, self.contentsCategories, TOPRIGHT, 38, -40)
        else
            self.categoryInset:SetAnchor(BOTTOMLEFT, self.contentsCategories, TOPRIGHT, 38, -12)
        end

        local parentData = categoryData:GetParentCategoryData()
        if parentData then
            self.categoryLabel:SetText(zo_strformat(SI_JOURNAL_PROGRESS_CATEGORY_SUBCATEGORY, parentData:GetName(), categoryData:GetName()))
        else
            self.categoryLabel:SetText(zo_strformat(SI_JOURNAL_PROGRESS_CATEGORY, categoryData:GetName()))
        end
        self.filter:SetHidden(false)
    end

    local function AddFilterCategories(categoryData)
        -- Recursively add a Category Id and its parent Category Id(s) to filterCategories.
        if categoryData then
            local categoryId = categoryData:GetId()
            -- Prevent accidental infinite recursion and stack overflow.
            if not filterCategories[categoryId] then
                filterCategories[categoryId] = true
                AddFilterCategories(categoryData:GetParentCategoryData())
            end
        end
    end

    function ZO_AntiquityJournal_Keyboard:AddScryableCategory()
        -- Scryables parent category
        local scryableEntryData = ZO_EntryData:New(ZO_SCRYABLE_ANTIQUITY_CATEGORY_DATA)
        local scryableTreeNode = self.categoryTree:AddNode("ZO_AntiquityJournal_StatusIconHeader", scryableEntryData)
        self.categoryNodeLookupData[scryableEntryData:GetId()] = scryableTreeNode

        -- Current zone subcategory
        local currentZoneEntryData = ZO_EntryData:New(ZO_SCRYABLE_ANTIQUITY_CURRENT_ZONE_SUBCATEGORY_DATA)
        local currentZoneTreeNode = self.categoryTree:AddNode("ZO_AntiquityJournal_SubCategory", currentZoneEntryData, scryableTreeNode)
        self.categoryNodeLookupData[currentZoneEntryData:GetId()] = currentZoneTreeNode

        -- All leads subcategory
        local allLeadsEntryData = ZO_EntryData:New(ZO_SCRYABLE_ANTIQUITY_ALL_LEADS_SUBCATEGORY_DATA)
        local allLeadsTreeNode = self.categoryTree:AddNode("ZO_AntiquityJournal_SubCategory", allLeadsEntryData, scryableTreeNode)
        self.categoryNodeLookupData[allLeadsEntryData:GetId()] = allLeadsTreeNode
    end

    function ZO_AntiquityJournal_Keyboard:AddCategory(category, parentCategory)
        local nodeTemplate

        -- Identify the Category's template type.
        if parentCategory then
            nodeTemplate = "ZO_AntiquityJournal_SubCategory"
        elseif category:GetNumSubcategories() > 0 then
            nodeTemplate = "ZO_AntiquityJournal_StatusIconHeader"
        else
            nodeTemplate = "ZO_AntiquityJournal_StatusIconChildlessHeader"
        end

        if filterCategories then
            -- Construct a set of child Categories that match the specified filter criteria.
            local matchedSubcategories = {}
            for _, subcategory in category:SubcategoryIterator() do
                if filterCategories[subcategory:GetId()] then
                    table.insert(matchedSubcategories, subcategory)
                end
            end

            -- If any child Categories match the filter criteria, or if this parent Category matches the filter criteria,
            -- then add the matching child Categories and this parent Category to the tree view control.
            if #matchedSubcategories > 0 or filterCategories[category:GetId()] then
                local categoryEntryData = ZO_EntryData:New(category)
                local parentNode = parentCategory and self.categoryNodeLookupData[parentCategory:GetId()] or nil
                local treeNode = self.categoryTree:AddNode(nodeTemplate, categoryEntryData, parentNode)
                self.categoryNodeLookupData[category:GetId()] = treeNode
                for _, subcategory in ipairs(matchedSubcategories) do
                    self:AddCategory(subcategory, category)
                end
            end
        else
            -- Add this Category and any child Categories to the tree view control.
            local categoryEntryData = ZO_EntryData:New(category)
            local parentNode = parentCategory and self.categoryNodeLookupData[parentCategory:GetId()] or nil
            local treeNode = self.categoryTree:AddNode(nodeTemplate, categoryEntryData, parentNode)
            self.categoryNodeLookupData[category:GetId()] = treeNode
            for _, subcategory in category:SubcategoryIterator() do
                self:AddCategory(subcategory, category)
            end
        end
    end

    function ZO_AntiquityJournal_Keyboard:ApplySearchCriteria()
        local searchResults = ANTIQUITY_DATA_MANAGER:GetSearchResults()
        if searchResults then
            filterAntiquities = {}
            filterAntiquitySets = {}
            filterCategories = {}

            for _, antiquityId in ipairs(searchResults) do
                local antiquityData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)
                if antiquityData and antiquityData:HasDiscovered() then
                    -- Construct a set of the Antiquities that match the filter criteria, if any.
                    filterAntiquities[antiquityId] = true

                    local antiquitySetData = antiquityData:GetAntiquitySetData()
                    if antiquitySetData then
                        -- Construct a set of the Antiquity Sets that contain Antiquities that match the filter criteria, if any.
                        filterAntiquitySets[antiquitySetData:GetId()] = true
                    end

                    -- Construct a set of the parent and child Categories that contain Antiquities and/or Antiquity Sets that match the filter criteria, if any.
                    local categoryData = antiquityData:GetAntiquityCategoryData()
                    if categoryData then
                        AddFilterCategories(categoryData)
                    end
                end
            end
        else
            filterAntiquities = nil
            filterAntiquitySets = nil
            filterCategories = nil
        end
    end

    function ZO_AntiquityJournal_Keyboard:RefreshCategories()
        self.isRefreshingAll = true
        self:ApplySearchCriteria()

        self.categoryTree:Reset()
        ZO_ClearTable(self.categoryNodeLookupData)

        self:AddScryableCategory()

        local NO_PARENT_CATEGORY = nil
        for _, category in ANTIQUITY_DATA_MANAGER:TopLevelAntiquityCategoryIterator() do
            self:AddCategory(category, NO_PARENT_CATEGORY)
        end

        local categoryNode = self.queuedCategoryId and self.categoryNodeLookupData[self.queuedCategoryId]
        self.categoryTree:Commit(categoryNode)

        self:RefreshVisibleCategoryFilter()
        self.isRefreshingAll = false
        self.queuedCategoryId = nil
    end

    function ZO_AntiquityJournal_Keyboard:RefreshVisibleCategoryFilter()
        local selectedCategoryData = self.categoryTree:GetSelectedData()
        if selectedCategoryData then
            self:OnCategorySelected(selectedCategoryData)
        end
    end
end

function ZO_AntiquityJournal_Keyboard:OnSingleAntiquityLeadUpdated(data)
    if data:GetType() == ZO_ANTIQUITY_TYPE_INDIVIDUAL then
        -- Refresh this antiquity's individual tile.
        local tile = self.antiquityTilesByAntiquityId[data:GetId()]
        if tile then
            tile:Layout(tile.tileData:GetId())
        end

        -- If this antiquity is a set fragment, refresh this antiquity set's tile.
        local antiquitySetData = data:GetAntiquitySetData()
        if antiquitySetData then
            local setTile = self.antiquitySetTilesByAntiquitySetId[antiquitySetData:GetId()]
            if setTile then
                setTile:Layout(setTile.tileData:GetId())
            end
        end
    end

    -- Refresh this antiquity's category and predecessor category(ies).
    local categoryData = data:GetAntiquityCategoryData()
    while categoryData do
        self:UpdateCategoryStatusIcon(categoryData:GetId())
        categoryData = categoryData:GetParentCategoryData()
    end

    self:UpdateCategoryStatusIcon(ZO_SCRYABLE_ANTIQUITY_CATEGORY_ID)

    -- Refresh the main menu and scene group's new indicators.
    MAIN_MENU_KEYBOARD:RefreshCategoryBar()
    MAIN_MENU_KEYBOARD:UpdateSceneGroupButtons("journalSceneGroup")
end

function ZO_AntiquityJournal_Keyboard:UpdateKeybinds()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_AntiquityJournal_Keyboard:SetMouseOverTile(tile)
    self.mouseOverTile = tile
    tile:ShowTooltip()
    tile:SetHighlightHidden(false)
    self:UpdateKeybinds()
end

function ZO_AntiquityJournal_Keyboard:ClearMouseOverTile(tile)
    if tile and tile == self.mouseOverTile then
        self.mouseOverTile = nil
        tile:HideTooltip()
        tile:SetHighlightHidden(true)
        self:UpdateKeybinds()
    end
end

function ZO_AntiquityJournal_Keyboard:GetMouseOverTile()
    return self.mouseOverTile
end

function ZO_AntiquityJournal_Keyboard:OnCategorySelected(categoryData)
    self:UpdateCategoryLabels(categoryData)
    if (ZO_IsAntiquityScryableCategory(categoryData) or ZO_IsAntiquityScryableSubcategory(categoryData)) and not ZO_IsScryingUnlocked() then
        self:ShowLockedContentPanel()
        return
    end
    self:BuildCategoryAntiquityTiles(categoryData)
    self:HideLockedContentPanel()
end

function ZO_AntiquityJournal_Keyboard:OnAntiquitiesUpdated()
    self:RefreshCategories()
end

function ZO_AntiquityJournal_Keyboard:ShowCategory(categoryId, filterText)

    --Order matters, resetting the filters will trigger a refresh of the categories, and we don't want this call to inadvertantly clear the queuedCategoryId
    self:ResetFilters()

    if ANTIQUITY_DATA_MANAGER:GetSearch() ~= "" or filterText then
        if filterText then
            self.contentSearchEditBox:SetText(filterText)
        else
            self.contentSearchEditBox:SetText("")
        end
        --Store the category id to be used once the search finishes updating
        self.queuedCategoryId = categoryId
    else
        local categoryNode = self.categoryNodeLookupData[categoryId]
        if categoryNode ~= nil then
            self.categoryTree:SelectNode(categoryNode)
        end
    end
end

function ZO_AntiquityJournal_Keyboard:ShowScryable()
    self:ShowCategory(ZO_SCRYABLE_ANTIQUITY_CATEGORY_ID)
end

-- Global XML

function ZO_AntiquityJournal_Keyboard_OnInitialized(control)
    ANTIQUITY_JOURNAL_KEYBOARD = ZO_AntiquityJournal_Keyboard:New(control)
    SYSTEMS:RegisterKeyboardObject("antiquityJournalKeyboard", ANTIQUITY_JOURNAL_KEYBOARD)
end

function ZO_AntiquityJournal_Keyboard_OnSearchTextChanged(editBox)
    ANTIQUITY_DATA_MANAGER:SetSearch(editBox:GetText())
end

function ZO_AntiquityTileBaseControl_Keyboard_OnMouseEnter(control, ...)
    control.owner:OnMouseEnter(...)
end

function ZO_AntiquityTileBaseControl_Keyboard_OnMouseExit(control, ...)
    control.owner:OnMouseExit(...)
end

function ZO_AntiquityTileBaseControl_Keyboard_OnMouseDoubleClick(control, ...)
    control.owner:OnMouseDoubleClick(...)
end

function ZO_AntiquityTile_Keyboard_OnInitialized(control)
    ZO_AntiquityTile_Keyboard:New(control)
end

function ZO_AntiquitySetTile_Keyboard_OnInitialized(control)
    ZO_AntiquitySetTile_Keyboard:New(control)
end

function ZO_ScryableAntiquityTile_Keyboard_OnInitialized(control)
    ZO_ScryableAntiquityTile_Keyboard:New(control)
end

function ZO_AntiquityIcon_SetData(control, tileData)
    control.antiquityData = tileData
    local textureControl = control:GetNamedChild("Icon")
    local textureIcon = tileData:HasDiscovered() and tileData:GetIcon() or ZO_ANTIQUITY_UNKNOWN_ICON_TEXTURE
    textureControl:SetTexture(textureIcon)

    local isLocked = textureIcon ~= ZO_ANTIQUITY_UNKNOWN_ICON_TEXTURE and not tileData:HasRecovered()
    ZO_SetDefaultIconSilhouette(textureControl, isLocked)
    if not tileData:IsComplete() then
        textureControl:SetDesaturation(1)
    end

    if control.status then
        control.status:ClearIcons()
        if control.antiquityData:GetAntiquitySetData() and control.antiquityData:HasNewLead() then
            control.status:AddIcon(ZO_KEYBOARD_NEW_ICON)
        end
        control.status:Show()
    end
end

function ZO_AntiquityIcon_OnInitialized(control)
    control.highlightTexture = control:GetNamedChild("HighlightTexture")
    control.highlightAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("AntiquityJournalIconHighlight_Keyboard", control.highlightTexture)
    control.highlightAnimation:PlayBackward()
end

function ZO_AntiquityFragmentIcon_OnInitialized(control)
    ZO_AntiquityIcon_OnInitialized(control)
    control.status = control:GetNamedChild("Status")
end

function ZO_AntiquityFragmentIcon_OnMouseEnter(control)
    if control.antiquityData then
        InitializeTooltip(AntiquityTooltip, control, TOPLEFT, 0, 5, BOTTOMLEFT)
        AntiquityTooltip:SetAntiquitySetFragment(control.antiquityData:GetId())
        control.highlightAnimation:PlayForward()
    end
end

function ZO_AntiquityFragmentIcon_OnMouseExit(control)
    if control.antiquityData then
        ClearTooltip(AntiquityTooltip)
        control.antiquityData:ClearNewLead()
        control.highlightAnimation:PlayBackward()
    end
end
