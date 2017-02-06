local NUM_RECENT_ACHIEVEMENTS_TO_SHOW = 6

-- NOTE: If any chain is added which gets larger than this, design will need to
--  come up with a layout that works with the additional number, or can dynamically
--  adjust the number.
local MAX_CHAIN_SIZE = 5

local CHECKED_ICON          = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"
local UNCHECKED_ICON = nil
local NO_ACHIEVEMENT_ICON   = "EsoUI/Art/Achievements/Gamepad/Achievement_EmptyIcon.dds"
local SUMMARY_ICON          = "EsoUI/Art/TreeIcons/gamepad/achievement_categoryIcon_Summary.dds"

local ZO_Achievements_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

local function IsAchievementALine(achievementId)
    local chainId = GetFirstAchievementInLine(achievementId)
    if chainId == 0 then
        return false
    elseif chainId ~= achievementId then
        return true
    end
    local nextId = GetNextAchievementInLine(chainId)
    return nextId ~= 0
end

local function DoesAchievementLineContainAchievement(achievementLineId, achievementId)
    local firstAchievementId = GetFirstAchievementInLine(achievementLineId)
    if firstAchievementId ~= 0 then
        achievementLineId = firstAchievementId
    end

    while achievementLineId ~= 0 do
        if achievementLineId == achievementId then
            return true
        end
        achievementLineId = GetNextAchievementInLine(achievementLineId)
    end

    return false
end

local function GetCategoryInfoFromAchievementIdDetailed(achievementId)
    -- If the user is selecting from the recent achievements list, there
    --  will not be an open category id, so attempt to get the category
    --  from the achievement.
    local categoryId = GetCategoryInfoFromAchievementId(achievementId)
    if categoryId then
        return categoryId
    end

    -- Some achievements cannot find their category id properly, so try
    --  walking the achievement chain and look for one that has a category
    --  id.
    local tryAchievementId = GetFirstAchievementInLine(achievementId)
    while tryAchievementId ~= 0 do
        categoryId = GetCategoryInfoFromAchievementId(tryAchievementId)
        if categoryId then
            return categoryId
        end
        tryAchievementId = GetNextAchievementInLine(tryAchievementId)
    end

    -- We were unable to determine the correct category id.
    return nil
end

function ZO_Achievements_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_Achievements_Gamepad:Initialize(control)
    ACHIEVEMENTS_GAMEPAD_SCENE = ZO_Scene:New("achievementsGamepad", SCENE_MANAGER)

    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, nil, ACHIEVEMENTS_GAMEPAD_SCENE)

    self.selectedCategoryId = nil
    self.visibleCategoryId = nil
    self.achievementId = nil
    self.filterType = SI_ACHIEVEMENT_FILTER_SHOW_ALL

    self.selectedCategoryIndex = nil
    self.selectedAchievementIndices = {} --one saved per category

    self.footerBarName = ZO_Gamepad_Achievements_FooterBar:GetNamedChild("Name")
    self.footerBarValue = ZO_Gamepad_Achievements_FooterBar:GetNamedChild("Rank")
    self.footerBarBar = ZO_Gamepad_Achievements_FooterBar:GetNamedChild("XPBar")

    self.headerData = {
        titleText = GetString(SI_JOURNAL_MENU_ACHIEVEMENTS),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_Achievements_Gamepad:SetupList(list)
    local function MenuEntryTemplateSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, activated)

        control.barContainer:SetMinMax(0, data.totalPoints)
        control.barContainer:SetValue(data.earnedPoints)
        control.barContainer:SetHidden(not selected)
        ZO_StatusBar_SetGradientColor(control.barContainer, ZO_SKILL_XP_BAR_GRADIENT_COLORS)
    end

    list:SetDirectionalInputEnabled(false)

    list:AddDataTemplate("ZO_GamepadAchievementsEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader("ZO_GamepadAchievementsEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    list:AddDataTemplate("ZO_GamepadMenuEntryWithBarTemplate", MenuEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    self.itemList = list
end

local PADDING = 3
local function CreateAchievementSlot(parent, previous, index)
    local newControl = CreateControlFromVirtual("$(parent)Entry", parent, "ZO_Gamepad_Achievement_Entry", index)
    if previous then
        newControl:SetAnchor(LEFT, previous, RIGHT, PADDING, 0)
    else
         newControl:SetAnchor(LEFT, nil, LEFT, 25, 0)
    end

    newControl.index = index
    newControl.icon = newControl:GetNamedChild("Icon")
    newControl.frame = newControl:GetNamedChild("Frame")

    return newControl
end

local function CanFocusAchievement(control)
    return (control.achievementId ~= nil)
end

local function AchievementControlActivate(control)
    control.frame:SetEdgeColor(ZO_SELECTED_TEXT:UnpackRGB())
end

local function AchievementControlDectivate(control)
    control.frame:SetEdgeColor(ZO_NORMAL_TEXT:UnpackRGB())
end

local function PlayHorizontalSound()
    PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
end

local function SetupAchievementList(parentControl, numEntries, controllers, canFocusFunction)
    local focus = ZO_GamepadFocus:New(parentControl, nil, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    focus.onPlaySoundFunction = PlayHorizontalSound
    local controls = {}

    local previous
    for i=1, numEntries do
        local control = CreateAchievementSlot(parentControl, previous, i)
        table.insert(controls, control)

        local focusEntry = {
                control = control,
                canFocus = canFocusFunction,
                activate = AchievementControlActivate,
                deactivate = AchievementControlDectivate,
                iconScaleAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_Gamepad_Achievement_FocusIconScaleAnimation", control.icon),
            }

        focus:AddEntry(focusEntry)
        previous = control
    end

    return focus, controls
end

function ZO_Achievements_Gamepad:OnDeferredInitialize()
    ZO_Gamepad_ParametricList_Screen.OnDeferredInitialize(self)

    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)

    local rootContainer = self.control:GetNamedChild("Mask"):GetNamedChild("Container")

    self.noEntriesLabel = rootContainer:GetNamedChild("NoEntries")

    self.recentAchievementContainer = rootContainer:GetNamedChild("Recent")
    self.recentAchievementFocus, self.recentAchievementControls = SetupAchievementList(self.recentAchievementContainer:GetNamedChild("Centerer"), NUM_RECENT_ACHIEVEMENTS_TO_SHOW, {ZO_DI_LEFT_STICK, ZO_DI_DPAD})
    self.recentAchievementFocus:SetFocusChangedCallback(function(...) self:AchievementListSelectionChanged(self.recentAchievementFocus, ...) end)

    self.chainContainer = self.control:GetNamedChild("Chain")
    self.chainFocus, self.chainControls = SetupAchievementList(self.chainContainer, MAX_CHAIN_SIZE, {ZO_DI_LEFT_STICK}, CanFocusAchievement)
    self.chainFocus:SetFocusChangedCallback(function(...) self:AchievementListSelectionChanged(self.chainFocus, ...) end)

    self:InitializeOptionsDialog()
    self:InitializeEvents()
end

function ZO_Achievements_Gamepad:InitializeEvents()
    local function OnAchievementUpdated(event, id)
        if SCENE_MANAGER:IsShowing("achievementsGamepad") then
            local entry = self.itemList:GetTargetData()
            if entry.achievementId == id then
                self:ShowAchievementTooltip(id)
            end
        end
    end
    
    local function Update()
        self:Update()
    end
    
    self.control:RegisterForEvent(EVENT_ACHIEVEMENTS_UPDATED, Update)
    self.control:RegisterForEvent(EVENT_ACHIEVEMENT_UPDATED, OnAchievementUpdated)
    self.control:RegisterForEvent(EVENT_ACHIEVEMENT_AWARDED, Update)
end

function ZO_Achievements_Gamepad:SetRecentAchievementsHidden(hidden)
    if self.recentAchievementContainer:IsControlHidden() == hidden then return end

    self.recentAchievementContainer:SetHidden(hidden)
    if hidden then
        -- In addition to hiding the container, we change its dimensions so the parameteric list
        --  fills the space.
        self.recentAchievementContainer:SetDimensions(nil, 0)
    else
        -- When the container is reshown, we need it to expand back to the size of its children
        --  so the list does not clip into the container.
        self.recentAchievementContainer:SetResizeToFitDescendents(true)
    end
end

function ZO_Achievements_Gamepad:UpdateDirectionalInput()
    local result = self.movementController:CheckMovement()
    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        if self.recentAchievementFocus.active then
            self.recentAchievementFocus:Deactivate()
            self:ShowAchievementSummaryTooltip() -- We are selecting the "summary" entry.
            self.itemList:Activate()
            PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        else
            self.itemList:MoveNext()
        end
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        if self.itemList.selectedIndex ~= 1 then
            self.itemList:MovePrevious()
        elseif not self.recentAchievementContainer:IsControlHidden() then
            self.itemList:Deactivate()
            self.recentAchievementFocus:Activate()
            PlaySound(SOUNDS.GAMEPAD_MENU_UP)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end
end

function ZO_Achievements_Gamepad:AchievementListSelectionChanged(list, entry)
    if entry then
        local recentAchievementId = entry.control.achievementId
        if recentAchievementId then
            self:ShowAchievementTooltip(recentAchievementId)
        else
            self:ShowNoAchievementTooltip()
        end
    elseif (self.visibleCategoryId == nil) and (list == self.recentAchievementFocus) then
        self:HideTooltip()
    end
end

function ZO_Achievements_Gamepad:RefreshRecentAchievements()
    local recentAchievements = {GetRecentlyCompletedAchievements(NUM_RECENT_ACHIEVEMENTS_TO_SHOW)}
    for i=1, NUM_RECENT_ACHIEVEMENTS_TO_SHOW do
        local control = self.recentAchievementControls[i]
        local achievementId = recentAchievements[i]

        control.icon:ClearIcons()

        if achievementId then
            local achievementName, description, points, icon, completed, date, time = GetAchievementInfo(achievementId)
            control.achievementId = achievementId
            control.icon:AddIcon(icon)
        else
            -- Occurs if the user does not have enough recent acheivements.
            control.achievementId = nil
            control.icon:AddIcon(NO_ACHIEVEMENT_ICON)
        end

        control.icon:Show()
    end
end

function ZO_Achievements_Gamepad:ShowAchievement(achievementId)
    local categoryId = GetCategoryInfoFromAchievementIdDetailed(achievementId)
    self:SwitchToCategoryAndAchievement(categoryId, achievementId)
    SCENE_MANAGER:Show("achievementsGamepad")
end

function ZO_Achievements_Gamepad:OnShowing()
    self:SwitchToFilterMode(SI_ACHIEVEMENT_FILTER_SHOW_ALL)

    ZO_Gamepad_ParametricList_Screen.OnShowing(self)

    DIRECTIONAL_INPUT:Activate(self, self.control)
    self.recentAchievementFocus:Deactivate()
end

function ZO_Achievements_Gamepad:OnHide()
    if self.visibleCategoryId or self.selectedCategoryId or self.achievementId then
        self:SwitchToCategoryAndAchievement(nil, nil)
    end

    ZO_Gamepad_ParametricList_Screen.OnHide(self)

    self:HideTooltip()

    self.recentAchievementFocus:Deactivate()
    DIRECTIONAL_INPUT:Deactivate(self)
end

function ZO_Achievements_Gamepad:SwitchToFilterMode(newMode)
    -- Skip the update if there was nothing to do.
    if self.filterType == newMode then return end
    self.filterType = newMode

    -- Update the icons displayed in the options dialog.
    for i=1, #self.dialogFilterEntries do
        local filterEntry = self.dialogFilterEntries[i]
        filterEntry:ClearIcons()
        if filterEntry.filterType == newMode then
            filterEntry:AddIcon(CHECKED_ICON)
        else
            filterEntry:AddIcon(UNCHECKED_ICON)
        end
    end

    -- Refresh the display list, if needed. We know the filter
    --  only applies when viewing a specific category, and not
    --  on the category list.
    if self.visibleCategoryId then
        self:Update()
    end
end

function ZO_Achievements_Gamepad:InitializeOptionsDialog()
    local function SwitchToFilterMode(entry)
        self:SwitchToFilterMode(entry.filterType)
    end

    local function CreateEntry(filterType)
        local newEntry = ZO_GamepadEntryData:New(zo_strformat(filterType), (self.filterType == filterType) and CHECKED_ICON or UNCHECKED_ICON)
        newEntry.setup = ZO_SharedGamepadEntry_OnSetup
        newEntry.filterType = filterType
        newEntry.callback = SwitchToFilterMode
        return newEntry
    end

    local showAllAchievements = CreateEntry(SI_ACHIEVEMENT_FILTER_SHOW_ALL)
    local showEarnedAchievements = CreateEntry(SI_ACHIEVEMENT_FILTER_SHOW_EARNED)
    local showUnearnedAchievements = CreateEntry(SI_ACHIEVEMENT_FILTER_SHOW_UNEARNED)
    
    self.dialogFilterEntries = {showAllAchievements, showEarnedAchievements, showUnearnedAchievements}

    ZO_Dialogs_RegisterCustomDialog("ACHIEVEMENTS_OPTIONS_GAMEPAD",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        title =
        {
            text = SI_GAMEPAD_ACHIEVEMENTS_OPTIONS,
        },

        setup = function(dialog)
            dialog:setupFunc()
        end,

        parametricList =
        {
            {
                template = "ZO_GamepadMenuEntryTemplate",
                header = SI_GAMEPAD_OPTIONS_MENU,
                entryData = showAllAchievements,
            },
            {
                template = "ZO_GamepadMenuEntryTemplate",
                entryData = showEarnedAchievements,
            },
            {
                template = "ZO_GamepadMenuEntryTemplate",
                entryData = showUnearnedAchievements,
            },
        },
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback =  function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    if data.callback then
                        data.callback(data)
                    end
                end,
                clickSound = SOUNDS.DIALOG_ACCEPT,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },
        }
    })
end

function ZO_Achievements_Gamepad:SwitchToCategoryAndAchievement(categoryId, achievementId)
    self.visibleCategoryId = categoryId
    self.selectedCategoryId = categoryId
    self.achievementId = achievementId
    self:Update()
end

function ZO_Achievements_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
                if self.visibleCategoryId then
                    self.visibleCategoryId = nil
                    self.achievementId = nil
                    self:Update()
                    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                else
                    SCENE_MANAGER:HideCurrentScene()
                end
            end),

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                    local targetData = self.itemList:GetTargetData()
                    self:SwitchToCategoryAndAchievement(targetData.categoryIndex, targetData.achievementId)
                end,
            visible = function()
                    if self.recentAchievementFocus.active then
                        return false
                    else
                        local targetData = self.itemList:GetTargetData()
                        return targetData and targetData.canEnter
                    end
                end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },

        -- Options
        {
            name = GetString(SI_GAMEPAD_DYEING_OPTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function() ZO_Dialogs_ShowGamepadDialog("ACHIEVEMENTS_OPTIONS_GAMEPAD") end,
            visible = function() return self.visibleCategoryId ~= nil end,
        },
    }
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.itemList)
end

function ZO_Achievements_Gamepad:ShowAchievementSummaryTooltip()
    -- Setup the tooltip contents.
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:LayoutAchievementSummary(GAMEPAD_LEFT_TOOLTIP)

    -- Hide the chain list.
    self:ClearLineList()
end

function ZO_Achievements_Gamepad:ShowNoAchievementTooltip()
    -- Setup the tooltip contents.
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:LayoutNoAchievement(GAMEPAD_LEFT_TOOLTIP)

    -- Hide the chain list.
    self:ClearLineList()
end

function ZO_Achievements_Gamepad:ShowAchievementTooltip(achievementId)
    -- Setup the tooltip contents.
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    GAMEPAD_TOOLTIPS:LayoutAchievement(GAMEPAD_LEFT_TOOLTIP, achievementId)
end

function ZO_Achievements_Gamepad:ClearLineList()
    self:SetupLineList(0)
end

function ZO_Achievements_Gamepad:SetupLineList(achievementId)
    self.updatingLineList = true

    local chainId = GetFirstAchievementInLine(achievementId)
    local chainIndex = 1
    local selectedChainIndex = nil

    while chainId ~= 0 do
        local chainControl = self.chainControls[chainIndex]
        local achievementName, description, points, icon, completed, date, time = GetAchievementInfo(chainId)
        local iconDesaturation = completed and 0 or 1

        chainControl.icon:ClearIcons()
        chainControl.icon:AddIcon(icon)
        chainControl.icon:SetDesaturation(iconDesaturation)
        chainControl.achievementId = chainId
        if chainId == achievementId then
            self.chainFocus:SetFocusByIndex(chainIndex)
        end
        chainControl:SetDimensions(55, 55)
        chainControl.icon:Show()
        chainControl:SetHidden(false)

        chainId = GetNextAchievementInLine(chainId)
        chainIndex = chainIndex + 1
    end

    for i=chainIndex, MAX_CHAIN_SIZE do
        local chainControl = self.chainControls[i]
        chainControl.achievementId = nil
        chainControl:SetDimensions(0, 0)
        chainControl.icon:Hide()
        chainControl:SetHidden(true)
    end

    local selectedAchievementEntryControl = self.itemList:GetTargetControl()

    -- NOTE: chainIndex can be 1 or 2 as sometimes GetFirstAchievementInLine will return 0 and sometimes it might
    --  return achievementId for a non-chained achievement. The difference seems to be a 1-achievement chain vs no
    --  chain, however we want to display both cases the same here.
    local chainContainer = self.chainContainer
    if (not selectedAchievementEntryControl) or (chainIndex <= 2) then
        -- This achievement is not part of a chain, hide the chain list.
        chainContainer:SetHidden(true)
        chainContainer:SetDimensions(nil, 0)
        self.chainFocus:Deactivate()
    else
        -- This achievement is part of a chain, show the chain list.
        chainContainer:SetHidden(false)
        self.chainFocus:Activate()

        chainContainer:ClearAnchors()
        chainContainer:SetHeight(71)
        chainContainer:SetAnchor(TOPLEFT, selectedAchievementEntryControl, BOTTOMLEFT, 80, 0)
        chainContainer:SetAnchor(TOPRIGHT, selectedAchievementEntryControl, BOTTOMRIGHT, 0, -2)
    end

    self.updatingLineList = false
end

function ZO_Achievements_Gamepad:HideTooltip()
    self:ClearLineList()
    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
end

function ZO_Achievements_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if selectedData and selectedData.achievementId then
        self:ShowAchievementTooltip(selectedData.achievementId)
        self:SetupLineList(selectedData.achievementId)
        self.selectedAchievementIndices[selectedData.categoryIndex] = list:GetSelectedIndex()
    elseif selectedData and selectedData.isSummary then
        self:ShowAchievementSummaryTooltip()
        self:ClearLineList()
        self.selectedCategoryIndex = 1
    else
        self.selectedCategoryIndex = list:GetSelectedIndex()
        self:HideTooltip()
    end
end

function ZO_Achievements_Gamepad:PopulateCategories()
    local totalPoints = GetTotalAchievementPoints()
    local earnedPoints = GetEarnedAchievementPoints()
    self.footerBarName:SetText(GetString(SI_GAMEPAD_ACHIEVEMENTS_POINTS_LABEL))
    self.footerBarValue:SetText(earnedPoints)
    self.footerBarBar:SetMinMax(0, totalPoints)
    self.footerBarBar:SetValue(earnedPoints)

    -- Create summary "category".
    local entryData = ZO_GamepadEntryData:New(zo_strformat(SI_JOURNAL_PROGRESS_SUMMARY), SUMMARY_ICON)
    entryData:SetIconTintOnSelection(true)
    entryData.earnedPoints = earnedPoints
    entryData.totalPoints = totalPoints
    entryData.canEnter = false
    entryData.isSummary = true
    self.itemList:AddEntry("ZO_GamepadMenuEntryWithBarTemplate", entryData)

    -- Populate actual categories.
    for categoryIndex=1, GetNumAchievementCategories() do
        local categoryName, _, _, earnedPoints, totalPoints = GetAchievementCategoryInfo(categoryIndex)
        local gamepadIcon = GetAchievementCategoryGamepadIcon(categoryIndex)

        local entryData = ZO_GamepadEntryData:New(zo_strformat(categoryName), gamepadIcon)
        entryData:SetIconTintOnSelection(true)
        entryData.categoryIndex = categoryIndex
        entryData.earnedPoints = earnedPoints
        entryData.totalPoints = totalPoints
        entryData.canEnter = true

        self.itemList:AddEntry("ZO_GamepadMenuEntryWithBarTemplate", entryData)
    end
end

function ZO_Achievements_Gamepad:AddAchievements(categoryIndex, subCategoryIndex, subCategoryName, achievementIds)
    local currentIndex = 0

    for achievementIndex=1, #achievementIds do
        local achievementId = achievementIds[achievementIndex]

        if ZO_ShouldShowAchievement(self.filterType, achievementId) then
            local nextAchievementId = ZO_GetNextInProgressAchievementInLine(achievementId)
            local firstAchievementId = GetFirstAchievementInLine(achievementId)

            currentIndex = currentIndex + 1

            local achievementName, description, points, icon, completed, date, time = GetAchievementInfo(nextAchievementId)

            local entryData = ZO_GamepadEntryData:New(zo_strformat(achievementName), icon)
            entryData:SetFontScaleOnSelection(false)
            entryData:SetIconDesaturation(completed and 0 or 1)
            entryData.isEarnedAchievement = completed
            entryData.categoryIndex = categoryIndex
            entryData.subCategoryIndex = subCategoryIndex
            entryData.achievementId = nextAchievementId
            entryData.firstAchievementId = firstAchievementId
            if points ~= ACHIEVEMENT_POINT_LEGENDARY_DEED then
                entryData:AddSubLabel(points)
                entryData:SetShowUnselectedSublabels(true)
            end
            entryData.canEnter = false

            local template
            if currentIndex == 1 then
                entryData:SetHeader(subCategoryName)
                template = "ZO_GamepadAchievementsEntryTemplateWithHeader"
            else
                template = "ZO_GamepadAchievementsEntryTemplate"
            end

            local postSelectedPadding = IsAchievementALine(nextAchievementId) and 48 or 0
            self.itemList:AddEntry(template, entryData, nil, nil, nil, postSelectedPadding)
        end
    end
end

function ZO_Achievements_Gamepad:PopulateAchievements(categoryIndex)
    local categoryName, numSubCategories, numAchievements, earnedPoints, totalPoints = GetAchievementCategoryInfo(categoryIndex)
    self.footerBarName:SetText(categoryName)
    self.footerBarValue:SetText(earnedPoints)
    self.footerBarBar:SetMinMax(0, totalPoints)
    self.footerBarBar:SetValue(earnedPoints)

    -- Handle "General"
    local achievementIds = ZO_GetAchievementIds(categoryIndex, nil, numAchievements)
    self:AddAchievements(categoryIndex, nil, GetString(SI_JOURNAL_PROGRESS_CATEGORY_GENERAL), achievementIds)

    -- Handle categories
    for subCategoryIndex=1, numSubCategories do
        local subCategoryName, subNumAchievements = GetAchievementSubCategoryInfo(categoryIndex, subCategoryIndex)
        local achievementIds = ZO_GetAchievementIds(categoryIndex, subCategoryIndex, subNumAchievements)
        self:AddAchievements(categoryIndex, subCategoryIndex, subCategoryName, achievementIds)
    end
end

--[[
    Gets the currently selected achievement ID from the screen.

    Returns a 2-tuple of (hasSelection, selectionId), with the following possible values:
        false, nil - There is no valid selection.
        true, true - The summary is selected.
        true, nil - An achievement category is selected.
        true, number - An achievement is selected, with selectionId being the achievementId.
]]
function ZO_Achievements_Gamepad:GetSelectionInformation()
    if self.itemList.active then
        local targetData = self.itemList:GetTargetData()
        if targetData and targetData.achievementId then
            -- The user has an entry in the main item list selected that is an achievement.
            return true, targetData.achievementId
        elseif targetData and targetData.isSummary then
            -- The user has an entry in the main item list selected that is the summary.
            return true, true
        elseif targetData then
            -- The user has an entry in the main item list selected that is an achievement category.
            return false, nil
        end
    end

    local selectedData = self.chainFocus:GetFocusItem()
    if selectedData then
        return true, selectedData.control.achievementId
    end

    selectedData = self.recentAchievementFocus:GetFocusItem()
    if selectedData then
        return true, selectedData.control.achievementId
    end

    return false, nil
end

function ZO_Achievements_Gamepad:PerformUpdate()
    self.itemList:Clear()

    local selectedIndex
    if not self.visibleCategoryId then
        selectedIndex = self.selectedCategoryIndex or 1
        self:PopulateCategories()
        self:RefreshRecentAchievements()
        self:SetRecentAchievementsHidden(false)
        self.headerData.titleText = GetString(SI_JOURNAL_MENU_ACHIEVEMENTS)
    else
        selectedIndex = self.selectedAchievementIndices[self.visibleCategoryId] or 1
        self:PopulateAchievements(self.visibleCategoryId)
        self:SetRecentAchievementsHidden(true)
        self.headerData.titleText = GetAchievementCategoryInfo(self.visibleCategoryId)
    end

    self.itemList:CommitWithoutReselect()

    local hasItems = self.itemList:GetNumItems() ~= 0
    self.noEntriesLabel:SetHidden(hasItems)

    if hasItems then
        -- NOTE: This does not use self.itemList:SetSelectedIndexWithoutAnimation() as that function has additional side-effects
        --  with the selected item and does not properly call the setup functions.
        self.itemList:EnableAnimation(false)
        self.itemList:SetSelectedIndex(selectedIndex)
        self.itemList:EnableAnimation(true)
    end

    local hasSelection, selectedAchievementId = self:GetSelectionInformation()
    if hasSelection and (type(selectedAchievementId) == "number") then
        self:ShowAchievementTooltip(selectedAchievementId)
    elseif hasSelection and selectedAchievementId then
        self:ShowAchievementSummaryTooltip()
    elseif hasSelection then
        self:ShowNoAchievementTooltip()
    else
        self:HideTooltip()
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function ZO_Achievements_Gamepad_OnInitialize(control)
    ACHIEVEMENTS_GAMEPAD = ZO_Achievements_Gamepad:New(control)
    SYSTEMS:RegisterGamepadObject("achievements", ACHIEVEMENTS_GAMEPAD)
end
