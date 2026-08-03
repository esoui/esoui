local KEYBOARD_ZONE_STORIES_BACKGROUND_TEXTURE_WIDTH = 620
local KEYBOARD_ZONE_STORIES_BACKGROUND_SOURCE_WIDTH = 1024
ZO_KEYBOARD_ZONE_STORIES_BACKGROUND_TEXTURE_COORD_RIGHT = KEYBOARD_ZONE_STORIES_BACKGROUND_TEXTURE_WIDTH / KEYBOARD_ZONE_STORIES_BACKGROUND_SOURCE_WIDTH

ZO_ZoneStories_Keyboard = ZO_ZoneStories_Shared:Subclass()

function ZO_ZoneStories_Keyboard:New(...)
    return ZO_ZoneStories_Shared.New(self, ...)
end

function ZO_ZoneStories_Keyboard:Initialize(control)
    local templateData =
    {
        gridListClass = ZO_GridScrollList_Keyboard,
        gridListClassInitExtraArgs = {},
        achievements =
        {
            entryTemplate = "ZO_ZoneStory_AchievementTile_Keyboard_Control",
            dimensionsX = ZO_ZONE_STORIES_ACHIEVEMENT_TILE_KEYBOARD_DIMENSIONS_X,
            dimensionsY = ZO_ZONE_STORIES_ACHIEVEMENT_TILE_KEYBOARD_DIMENSIONS_Y,
            gridPaddingX = 2,
            gridPaddingY = 20,
        },












        activityCompletion =
        {
            headerTemplate = "ZO_ZoneStory_ActivityCompletionHeader_Keyboard",
            entryTemplate = "ZO_ZoneStory_ActivityCompletionTile_Keyboard_Control",
            dimensionsX = ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_KEYBOARD_DIMENSIONS_X,
            dimensionsY = ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_KEYBOARD_DIMENSIONS_Y,
            gridPaddingX = 4,
            gridPaddingY = 16,
            headerHeight = 40,
        },
        headerPrePadding = 20
    }

    local buttonContainer = control:GetNamedChild("ButtonContainer")
    self.playStoryButton = buttonContainer:GetNamedChild("PlayStoryButton")
    self.playStoryButton:SetClickSound(SOUNDS.ZONE_STORIES_TRACK_ACTIVITY)
    self.stopTrackingButton = buttonContainer:GetNamedChild("StopTrackingButton")

    self.trackingMessageLabel = control:GetNamedChild("TrackingMessage")

    local infoContainerControl = control:GetNamedChild("InfoContainer")
    ZO_ZoneStories_Shared.Initialize(self, control, infoContainerControl, templateData)

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        name = GetString(SI_ZONE_STORY_MORE_INFO_KEYBIND),
        keybind = "UI_SHORTCUT_HELP",
        visible = function()
            local helpCategoryIndex, helpIndex = GetZoneStoriesHelpIndices()
            return helpCategoryIndex ~= nil
        end,
        callback = function()
            local helpCategoryIndex, helpIndex = GetZoneStoriesHelpIndices()
            HELP:ShowSpecificHelp(helpCategoryIndex, helpIndex)
        end,
    }

    ZONE_STORIES_FRAGMENT = ZO_FadeSceneFragment:New(control)
    ZONE_STORIES_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:UpdateZoneStory()
            TriggerTutorial(TUTORIAL_TRIGGER_ZONE_STORIES_SHOWN)
            KEYBIND_STRIP:AddKeybindButton(self.keybindStripDescriptor)
        elseif newState == SCENE_FRAGMENT_SHOWN then
            HandleUISystemShown(UI_SYSTEM_ZONE_GUIDE)
        elseif newState == SCENE_FRAGMENT_HIDING then
            KEYBIND_STRIP:RemoveKeybindButton(self.keybindStripDescriptor)
        end
    end)

    local categoryData = ZONE_STORIES_MANAGER.GetCategoryData()
    local keyboardCategoryData = categoryData.keyboardData
    keyboardCategoryData.categoryFragment = ZONE_STORIES_FRAGMENT

    -- Add to category list in Activity Finder
    GROUP_MENU_KEYBOARD:AddCategory(keyboardCategoryData)
end

function ZO_ZoneStories_Keyboard:InitializeZonesList()
    self.zoneSelectorControl = self.control:GetNamedChild("ZoneSelector")
    local zoneSelectorComboBox = ZO_ComboBox_ObjectFromContainer(self.zoneSelectorControl)
    zoneSelectorComboBox:SetSortsItems(false)
    zoneSelectorComboBox:SetFont("ZoFontWinT1")
    zoneSelectorComboBox:SetSpacing(4)
    zoneSelectorComboBox:SetHeight(500)
    self.zoneSelectorComboBox = zoneSelectorComboBox
    self:BuildZonesList()
end

function ZO_ZoneStories_Keyboard:OnZoneSelectionChanged(comboBox, entryText, entry)
    self:UpdateZoneStory()
end

function ZO_ZoneStories_Keyboard:UpdatePlayStoryButtonText()
    local zoneId = self:GetSelectedZoneId()
    local isZoneAvailable = ZO_ZoneStories_Manager.GetZoneAvailability(zoneId)
    local canContinueZone = CanZoneStoryContinueTrackingActivities(zoneId)
    self.playStoryButton:SetEnabled(isZoneAvailable and canContinueZone)
    self.playStoryButton:SetText(self:GetPlayStoryButtonText())
end

function ZO_ZoneStories_Keyboard:UpdateBackgroundTexture()
    local selectedData = self:GetSelectedStoryData()
    if selectedData then
        self.backgroundTexture:SetTexture(GetZoneStoryKeyboardBackground(selectedData.id))
    end
end

function ZO_ZoneStories_Keyboard:BuildZonesList()
    ZO_ZoneStories_Shared.BuildZonesList(self)

    local function OnSelectionChanged(...)
        self:OnZoneSelectionChanged(...)
    end

    local trackedZoneId = GetTrackedZoneStoryActivityInfo()
    local trackedEntry = nil
    local defaultZoneId = ZO_ZoneStories_Manager.GetDefaultZoneSelection()
    local defaultEntry = nil
    self.zoneSelectorComboBox:ClearItems()

    for _, zoneData in ZONE_STORIES_MANAGER:ZoneListIterator() do
        local entry = self.zoneSelectorComboBox:CreateItemEntry(zoneData.name, OnSelectionChanged)
        entry.data =
        {
            id = zoneData.id,
            name = zoneData.name
        }

        if trackedZoneId ~= 0 and trackedZoneId == zoneData.id then
            trackedEntry = entry
            trackedEntry.name = zo_iconTextFormat(ZO_CHECK_ICON, "100%", "100%", trackedEntry.data.name)
        elseif zoneData.id == defaultZoneId then
            defaultEntry = entry
            defaultEntry.name = zo_iconTextFormat("EsoUI/Art/MapPins/UI-WorldMapPlayerPip.dds", 16, 16, defaultEntry.data.name)
        end

        self.zoneSelectorComboBox:AddItem(entry, ZO_COMBOBOX_SUPPRESS_UPDATE)
    end

    local IGNORE_CALLBACK = false
    local selectedEntry = trackedEntry or defaultEntry
    if selectedEntry then
        self.zoneSelectorComboBox:SelectItem(selectedEntry, IGNORE_CALLBACK)
    else
        self.zoneSelectorComboBox:SelectFirstItem()
    end
end

function ZO_ZoneStories_Keyboard:UpdateZoneStory()
    ZO_ZoneStories_Shared.UpdateZoneStory(self)

    local zoneId = GetTrackedZoneStoryActivityInfo()
    local selectedData = self:GetSelectedStoryData()
    local selectedZoneId = selectedData.id
    self.stopTrackingButton:SetHidden(zoneId ~= selectedZoneId)

    local isZoneAvailable, zoneAvailableErrorText = ZO_ZoneStories_Manager.GetZoneAvailability(selectedZoneId)
    local shouldShowBlockingMessage = not isZoneAvailable and zoneAvailableErrorText ~= nil
    if shouldShowBlockingMessage then
        self.trackingMessageLabel:SetText(zoneAvailableErrorText)
    else
        local arePriorityQuestsBlocked, errorStringText = ZO_ZoneStories_Manager.GetZoneCompletionTypeBlockingInfo(selectedZoneId, ZONE_COMPLETION_TYPE_PRIORITY_QUESTS)
        shouldShowBlockingMessage = arePriorityQuestsBlocked and errorStringText ~= nil
        if shouldShowBlockingMessage then
            self.trackingMessageLabel:SetText(errorStringText)
        end
    end

    self.trackingMessageLabel:SetHidden(not shouldShowBlockingMessage)
end

function ZO_ZoneStories_Keyboard:GetSelectedZoneId()
    local selectedItemData = self.zoneSelectorComboBox:GetSelectedItemData()
    if selectedItemData then
        return selectedItemData.data.id
    end
    return nil
end

function ZO_ZoneStories_Keyboard:GetSelectedStoryData()
    local selectedItemData = self.zoneSelectorComboBox:GetSelectedItemData()
    if selectedItemData then
        return selectedItemData.data
    end
    return nil
end

function ZO_ZoneStories_Keyboard:SetSelectedByZoneId(zoneId)
    for _, itemData in ipairs(self.zoneSelectorComboBox:GetItems()) do
        if itemData and itemData.data and itemData.data.id == zoneId then
            self.zoneSelectorComboBox:SelectItem(itemData)
        end
    end
end

function ZO_ZoneStories_Keyboard:SetKeyboardActivityCompletionTooltipInfo(control)
    self.activityCompletionTooltipInfo = 
    {
        control = control,
        textControl = control:GetNamedChild("Text"),
        cycleKeybindControl = control:GetNamedChild("CycleKeybind")
    }

    ZO_KeybindButtonTemplate_Setup(self.activityCompletionTooltipInfo.cycleKeybindControl, "UI_SHORTCUT_TERTIARY", nil, GetString(SI_ZONE_STORY_ACTIVITY_COMPLETION_CYCLE_KEYBIND))
end

function ZO_ZoneStories_Keyboard:SetKeyboardActivityCompletionListTooltipInfo(control)
    self.activityCompletionListTooltipInfo = 
    {
        control = control,
        titleControl = control:GetNamedChild("Title"),
        listControl = control:GetNamedChild("CheckList"),
        additionalInfoLabel = control:GetNamedChild("AdditionalInfoText"),
    }

    local checkPool = ZO_ControlPool:New("ZO_CompletionTypeCheckbox", self.activityCompletionListTooltipInfo.listControl)
    checkPool:SetCustomFactoryBehavior(function(checkControl)
                                            checkControl.label = checkControl:GetNamedChild("Label")
                                       end)
    self.activityCompletionListTooltipInfo.checkControlPool = checkPool

    local columnPool = ZO_ControlPool:New("ZO_CompletionTypeCheckboxColumn", self.activityCompletionListTooltipInfo.listControl)
    self.activityCompletionListTooltipInfo.columnControlPool = columnPool
end

do
    local INITIAL_INDEX = 1

    function ZO_ZoneStories_Keyboard:ShowActivityCompletionTooltip(zoneId, completionType, anchor, descriptionToAchievementAnchor, completionIndex)
        local activityCompletionTooltipInfo = self.activityCompletionTooltipInfo
        local activityCompletionListTooltipInfo = self.activityCompletionListTooltipInfo
        activityCompletionTooltipInfo.anchor = anchor
        activityCompletionTooltipInfo.currentZoneId = zoneId
        activityCompletionTooltipInfo.currentCompletionType = completionType
        activityCompletionTooltipInfo.control:ClearAnchors()
        activityCompletionTooltipInfo.cycleKeybindControl:SetHidden(true)

        local numAchievements = GetNumAssociatedAchievementsForZoneCompletionType(zoneId, completionType)
        if numAchievements > 0 then
            self:UpdateActivityCompletionTooltip(INITIAL_INDEX)

            if GetNumAssociatedAchievementsForZoneCompletionType(zoneId, completionType) > 1 then
                activityCompletionTooltipInfo.cycleKeybindControl:SetHidden(false)
            end
            descriptionToAchievementAnchor:Set(activityCompletionTooltipInfo.control)
            activityCompletionListTooltipInfo.control:SetHidden(true)
        else
            activityCompletionListTooltipInfo.control:ClearAnchors()
            activityCompletionListTooltipInfo.checkControlPool:ReleaseAllObjects()
            activityCompletionListTooltipInfo.columnControlPool:ReleaseAllObjects()

            self:SetupCompletionTypeListTooltip(zoneId, completionType, completionIndex)

            anchor:Set(activityCompletionListTooltipInfo.control)

            local detailsAnchor = ZO_Anchor:New(descriptionToAchievementAnchor:GetMyPoint(), activityCompletionListTooltipInfo.control, descriptionToAchievementAnchor:GetRelativePoint(), descriptionToAchievementAnchor:GetOffsetX(), descriptionToAchievementAnchor:GetOffsetY())
            detailsAnchor:Set(activityCompletionTooltipInfo.control)
            activityCompletionListTooltipInfo.control:SetHidden(false)
        end

        if DoesZoneStoryActivityCompletionTypeUseIndex(completionType) then





                activityCompletionTooltipInfo.textControl:SetText(GetZoneStoryActivityDescriptionForCompletionTypeAndIndex(zoneId, completionType, completionIndex))
                activityCompletionTooltipInfo.control:SetHidden(false)



        else
            activityCompletionTooltipInfo.textControl:SetText(GetString("SI_ZONECOMPLETIONTYPE_DESCRIPTION", completionType))
            activityCompletionTooltipInfo.control:SetHidden(false)
        end
    end

    local function ActivityDataComparator(left, right)
        if left.complete == right.complete then
            return left.activityIndex < right.activityIndex
        end

        return not left.complete
    end

    local MAX_CONTROLS_PER_COLUMN = 20
    local MAX_COLUMNS = 2
    local MAX_VISIBLE_CHECKBOX_CONTROLS = MAX_COLUMNS * MAX_CONTROLS_PER_COLUMN

    function ZO_ZoneStories_Keyboard:SetupCompletionTypeListTooltip(zoneId, completionType, completionIndex)
        local PADDING_Y = 10
        local MIN_WIDTH = 250
        local MAX_WIDTH = 330
        local AUTO_SIZE = 0
        local activityCompletionListTooltipInfo = self.activityCompletionListTooltipInfo
        local additionalInfoLabel = activityCompletionListTooltipInfo.additionalInfoLabel
        local completionTypeUsesIndex = DoesZoneStoryActivityCompletionTypeUseIndex(completionType)
        local additionalInfoDisplayText
        local tooltipTitleText
        if completionTypeUsesIndex then
            tooltipTitleText = GetZoneStoryActivityNameForCompletionTypeAndIndex(zoneId, completionType, completionIndex)
        else
            tooltipTitleText = GetString("SI_ZONECOMPLETIONTYPE", completionType)
        end
        activityCompletionListTooltipInfo.titleControl:SetText(zo_strformat(SI_ZONE_STORY_LIST_TOOLTIP_TITLE_FORMATTER, GetZoneNameById(zoneId), tooltipTitleText))

        local numActivityColumnsAdded = 0
        local numUnblockedActivities, blockingBranchErrorStringId = select(3, ZO_ZoneStories_Manager.GetActivityCompletionProgressValues(zoneId, completionType, completionIndex))
        if numUnblockedActivities > 0 then
            local activityData = {}
            for activityIndex = 1, numUnblockedActivities do
                local complete = IsZoneStoryActivityComplete(zoneId, completionType, activityIndex, completionIndex)
                local name = GetZoneStoryActivityNameByActivityIndex(zoneId, completionType, activityIndex, completionIndex)
                local data =
                {
                    activityIndex = activityIndex,
                    complete = complete,
                    name = zo_strformat(SI_ZONE_STORY_LIST_TOOLTIP_ACTIVITY_NAME_FORMATTER, name),
                }
                table.insert(activityData, data)
            end

            local numVisibleCheckControls = completionTypeUsesIndex and numUnblockedActivities <= 1 and 0 or numUnblockedActivities
            local addAdditionalActivitiesControl = false

            if completionTypeUsesIndex then
                additionalInfoDisplayText = GetZoneStoryActivityAttainTextForCompletionTypeAndIndex(zoneId, completionType, completionIndex)
            else
                additionalInfoDisplayText = GetErrorString(blockingBranchErrorStringId)
            end

            -- check to see if there are more activities than can be shown in the tooltip
            -- if so we will add a label at the end indiciating how many more activities are hidden
            if numUnblockedActivities > MAX_VISIBLE_CHECKBOX_CONTROLS then
                addAdditionalActivitiesControl = true
                numVisibleCheckControls = MAX_VISIBLE_CHECKBOX_CONTROLS - 1 -- -1 because we will add the "hidden" label

                -- since we are hiding some of the activities we will sort so the completed
                -- ones are at the end (and therefore the ones that end up hidden)
                table.sort(activityData, ActivityDataComparator)
            end

            -- we want to evenly divide the controls between the columns
            -- so figure out how many controls should go in each
            local numControlsPerColumn = MAX_CONTROLS_PER_COLUMN
            if numVisibleCheckControls > MAX_CONTROLS_PER_COLUMN then
                local numColumns = math.ceil(numVisibleCheckControls / MAX_CONTROLS_PER_COLUMN)
                numControlsPerColumn = math.ceil(numVisibleCheckControls / numColumns)
            end

            local COLUMN_PADDING_X = 40
            local ROW_PADDING_Y = 5
            local previousControl = nil

            local columnPool = activityCompletionListTooltipInfo.columnControlPool
            local columnControl = columnPool:AcquireObject()
            columnControl:SetAnchor(TOPLEFT)
            numActivityColumnsAdded = 1

            -- add all the visible activities to the list
            local checkBoxIndex = 1
            local checkControlPool = activityCompletionListTooltipInfo.checkControlPool
            while checkBoxIndex <= numVisibleCheckControls do
                local activityInfo = activityData[checkBoxIndex]

                local checkControl = checkControlPool:AcquireObject()
                checkControl:SetAlpha(activityInfo.complete and 1 or 0)
                checkControl:SetHidden(false)

                checkControl.label:SetText(activityInfo.name)
                ZO_Achievements_ApplyTextColorToLabel(checkControl.label, activityInfo.complete, ZO_SELECTED_TEXT)

                -- check if we need to start a new column
                if checkBoxIndex > numControlsPerColumn * numActivityColumnsAdded then
                    local newColumnControl = columnPool:AcquireObject()
                    newColumnControl:SetAnchor(TOPLEFT, columnControl, TOPRIGHT, COLUMN_PADDING_X)
                    columnControl = newColumnControl
                    previousControl = nil
                    numActivityColumnsAdded = numActivityColumnsAdded + 1
                end

                checkControl:SetParent(columnControl)
                if previousControl then
                    checkControl:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, ROW_PADDING_Y)
                else
                    checkControl:SetAnchor(TOPLEFT)
                end
                previousControl = checkControl

                checkBoxIndex = checkBoxIndex + 1
            end

            if addAdditionalActivitiesControl then
                -- since the data has been sorted so all the completed activities are at the end
                -- if the first hidden activity is complete then all the others must be as well
                local allHiddenActivitiesComplete = activityData[numVisibleCheckControls + 1].complete
                local checkControl = checkControlPool:AcquireObject()

                ZO_Achievements_ApplyTextColorToLabel(checkControl.label, allHiddenActivitiesComplete, ZO_SELECTED_TEXT)
                local numHiddenActivities = numUnblockedActivities - numVisibleCheckControls
                checkControl.label:SetText(zo_strformat(SI_ZONE_STORY_LIST_TOOLTIP_ADDITIONAL_ACTVITIES_FORMATTER, numHiddenActivities))
                checkControl:SetAlpha(allHiddenActivitiesComplete and 1 or 0)
                checkControl:SetHidden(false)
                -- this should always be the last control in the current column, so no need
                -- to check if we need a new column
                checkControl:SetParent(columnControl)
                checkControl:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, ROW_PADDING_Y)
            end
        end

        activityCompletionListTooltipInfo.listControl:SetHidden(numUnblockedActivities == 0)
        additionalInfoLabel:ClearAnchors()
        if numUnblockedActivities == 0 then
            additionalInfoLabel:SetAnchor(TOPLEFT, activityCompletionListTooltipInfo.titleControl, BOTTOMLEFT, 0, PADDING_Y)
            additionalInfoLabel:SetDimensionConstraints(MIN_WIDTH, AUTO_SIZE, MAX_WIDTH, AUTO_SIZE)
        else
            additionalInfoLabel:SetAnchor(TOPLEFT, activityCompletionListTooltipInfo.listControl, BOTTOMLEFT, 0, PADDING_Y)

            -- numActivityColumnsAdded should never be 0 here because numUnblockedActivities == 0 means there shouldn't be any columns added
            if numActivityColumnsAdded == 1 then
                additionalInfoLabel:SetDimensionConstraints(MIN_WIDTH, AUTO_SIZE, MAX_WIDTH, AUTO_SIZE)
            else
                additionalInfoLabel:SetAnchor(TOPRIGHT, activityCompletionListTooltipInfo.listControl, BOTTOMRIGHT, 0, PADDING_Y)
                additionalInfoLabel:SetDimensionConstraints(AUTO_SIZE, AUTO_SIZE, AUTO_SIZE, AUTO_SIZE)
            end
        end

        additionalInfoLabel:SetText(additionalInfoDisplayText)
        additionalInfoLabel:SetHidden(false)
    end

    function ZO_ZoneStories_Keyboard:HideActivityCompletionTooltip()
        self.activityCompletionTooltipInfo.control:SetHidden(true)
        self.activityCompletionListTooltipInfo.control:SetHidden(true)
        ACHIEVEMENTS:HideAchievementDetailedTooltip()
    end

    function ZO_ZoneStories_Keyboard:IncrementActivityCompletionTooltip()
        local activityCompletionTooltipInfo = self.activityCompletionTooltipInfo
        local zoneId = activityCompletionTooltipInfo.currentZoneId
        local completionType = activityCompletionTooltipInfo.currentCompletionType
        local tooltipIndex = activityCompletionTooltipInfo.currentIndex

        tooltipIndex = tooltipIndex + 1

        local numAchievements = GetNumAssociatedAchievementsForZoneCompletionType(zoneId, completionType)
        if tooltipIndex > numAchievements then
            tooltipIndex = INITIAL_INDEX
        end

        self:UpdateActivityCompletionTooltip(tooltipIndex)
    end

    function ZO_ZoneStories_Keyboard:UpdateActivityCompletionTooltip(tooltipIndex)
        local activityCompletionTooltipInfo = self.activityCompletionTooltipInfo
        local zoneId = activityCompletionTooltipInfo.currentZoneId
        local completionType = activityCompletionTooltipInfo.currentCompletionType
        local achievementId = GetAssociatedAchievementIdForZoneCompletionType(zoneId, completionType, tooltipIndex)

        ACHIEVEMENTS:ShowAchievementDetailedTooltip(achievementId, activityCompletionTooltipInfo.anchor)

        activityCompletionTooltipInfo.currentIndex = tooltipIndex
    end
end

function ZO_ZoneStories_Keyboard_OnInitialize(control)
    ZONE_STORIES_KEYBOARD = ZO_ZoneStories_Keyboard:New(control)
end

function ZO_ZoneStories_PlayStory_OnClick(control)
    ZONE_STORIES_KEYBOARD:TrackNextActivity()
    ZONE_STORIES_KEYBOARD:BuildZonesList()
end

function ZO_ZoneStories_StopTracking_OnClick(control)
    ClearTrackedZoneStory()
    ZONE_STORIES_KEYBOARD:BuildZonesList()
end

function ZO_ZoneStory_ActivityCompletionTooltip_Keyboard_OnInitialized(control)
    ZONE_STORIES_KEYBOARD:SetKeyboardActivityCompletionTooltipInfo(control)
end

function ZO_ZoneStory_ActivityCompletionListTooltip_Keyboard_OnInitialized(control)
    ZONE_STORIES_KEYBOARD:SetKeyboardActivityCompletionListTooltipInfo(control)
end