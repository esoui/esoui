local GAMEPAD_ZONE_STORIES_BACKGROUND_SOURCE_WIDTH = 1024
local GAMEPAD_ZONE_STORIES_BACKGROUND_TEXTURE_WIDTH = 832
ZO_GAMEPAD_ZONE_STORIES_BACKGROUND_TEXTURE_COORDS_RIGHT = GAMEPAD_ZONE_STORIES_BACKGROUND_TEXTURE_WIDTH / GAMEPAD_ZONE_STORIES_BACKGROUND_SOURCE_WIDTH

local GAMEPAD_ZONE_STORIES_BACKGROUND_SOURCE_HEIGHT = 1024
local GAMEPAD_ZONE_STORIES_BACKGROUND_TEXTURE_HEIGHT = 955
ZO_GAMEPAD_ZONE_STORIES_BACKGROUND_TEXTURE_COORDS_BOTTOM = GAMEPAD_ZONE_STORIES_BACKGROUND_TEXTURE_HEIGHT / GAMEPAD_ZONE_STORIES_BACKGROUND_SOURCE_HEIGHT

local ZONE_STORIES_TILE_GRID_PADDING_X = 5
local ZONE_STORIES_TILE_GRID_PADDING_Y = 25
local COMPLETION_ACTIVITY_DESCRIPTION_TOOLTIP_INDEX = 0

ZO_ZoneStories_Gamepad = ZO_Object.MultiSubclass(ZO_ZoneStories_Shared, ZO_Gamepad_ParametricList_Screen)

function ZO_ZoneStories_Gamepad:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_ZoneStories_Gamepad:Initialize(control)
    local templateData =
    {
        gridListClass = ZO_GridScrollList_Gamepad,
        achievements = 
        {
            entryTemplate = "ZO_ZoneStory_AchievementTile_Gamepad_Control",
            dimensionsX = ZO_ZONE_STORIES_ACHIEVEMENT_TILE_GAMEPAD_DIMENSIONS_X,
            dimensionsY = ZO_ZONE_STORIES_ACHIEVEMENT_TILE_GAMEPAD_DIMENSIONS_Y,
            gridPaddingX = ZONE_STORIES_TILE_GRID_PADDING_X,
            gridPaddingY = ZONE_STORIES_TILE_GRID_PADDING_Y,
        },
        activityCompletion =
        {
            headerTemplate = "ZO_ZoneStory_ActivityCompletionHeader_Gamepad",
            entryTemplate = "ZO_ZoneStory_ActivityCompletionTile_Gamepad_Control",
            dimensionsX = ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_GAMEPAD_DIMENSIONS_X,
            dimensionsY = ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_GAMEPAD_DIMENSIONS_Y,
            gridPaddingX = ZONE_STORIES_TILE_GRID_PADDING_X,
            gridPaddingY = ZONE_STORIES_TILE_GRID_PADDING_Y,
            headerHeight = 70,
        },
        headerPrePadding = ZONE_STORIES_TILE_GRID_PADDING_Y
    }

    local sceneName = "zoneStoriesGamepad"
    GAMEPAD_ZONE_STORIES_SCENE = ZO_Scene:New(sceneName, SCENE_MANAGER)

    local ACTIVATE_LIST_ON_SHOW = true
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ACTIVATE_LIST_ON_SHOW, GAMEPAD_ZONE_STORIES_SCENE)

    local function SubMenuEntrySetup(entryControl, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(entryControl, data, selected, reselectingDuringRebuild, enabled, active)

        local NO_TINT = nil
        local iconControl = entryControl.statusIndicator
        local trackedZoneId = GetTrackedZoneStoryActivityInfo()
        local playerZoneId = ZO_ExplorationUtils_GetZoneStoryZoneIdByZoneIndex(GetUnitZoneIndex("player"))
        iconControl:ClearIcons()
        if trackedZoneId == data.id then
            iconControl:AddIcon(ZO_CHECK_ICON, NO_TINT, GetString(SI_SCREEN_NARRATION_TRACKED_ICON_NARRATION))
        end

        if playerZoneId == data.id then
            iconControl:AddIcon("EsoUI/Art/Icons/mapKey/mapKey_player.dds", NO_TINT, GetString(SI_SCREEN_NARRATION_CURRENT_ZONE_ICON_NARRATION))
        end

        iconControl:Show()
    end
    self:GetMainList():AddDataTemplate("ZO_GamepadItemSubEntryTemplate", SubMenuEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    -- Initialize shared elements in info display area
    local rightPane = control:GetNamedChild("RightPane")
    local rightPaneFragment = ZO_FadeSceneFragment:New(rightPane)
    GAMEPAD_ZONE_STORIES_SCENE:AddFragment(rightPaneFragment)

    local infoContainerControl = rightPane:GetNamedChild("InfoContainer")
    ZO_ZoneStories_Shared.Initialize(self, control, infoContainerControl, templateData)

    self.headerData =
    {
        titleText = GetString(SI_ACTIVITY_FINDER_CATEGORY_ZONE_STORIES),
    }
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)

    self.tooltipSelectedIndex = COMPLETION_ACTIVITY_DESCRIPTION_TOOLTIP_INDEX

    -- Adds Zone Stories to category list in Activity Finder
    local categoryData = ZONE_STORIES_MANAGER.GetCategoryData()
    local gamepadCategoryData = categoryData.gamepadData
    ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:AddCategory(gamepadCategoryData, gamepadCategoryData.priority)

    GAMEPAD_ZONE_STORIES_SCENE:RegisterCallback("StateChange", function(oldState, newState)
                                                            if newState == SCENE_SHOWING then
                                                                self:UpdateZoneStory()
                                                                self:SetFocusOnSelectedZone()
                                                                TriggerTutorial(TUTORIAL_TRIGGER_ZONE_STORIES_SHOWN)
                                                            end
                                                        end)
end

function ZO_ZoneStories_Gamepad:PerformUpdate()
    -- Function override required
end

function ZO_ZoneStories_Gamepad:InitializeZonesList()
    self:BuildZonesList()
end

function ZO_ZoneStories_Gamepad:InitializeGridList()
    ZO_ZoneStories_Shared.InitializeGridList(self)

    local function GetHeaderNarration()
        local narrations = {}
        local data = self:GetSelectedStoryData()
        local zoneData = ZONE_STORIES_MANAGER:GetZoneData(data.id)
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zoneData.name))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zoneData.description))
        return narrations
    end

    self.gridList:SetHeaderNarrationFunction(GetHeaderNarration)
    self.gridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridSelectionChanged(...) end)
end

function ZO_ZoneStories_Gamepad:Deactivate()
    ZO_Gamepad_ParametricList_Screen.Deactivate(self)

    self.gridList:Deactivate()
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD1_TOOLTIP)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.zoneKeybindStripDescriptor)
end

function ZO_ZoneStories_Gamepad:InitializeKeybindStripDescriptors()
    local trackActivityKeybind = 
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        name = function()
            return self:GetPlayStoryButtonText()
        end,

        keybind = "UI_SHORTCUT_SECONDARY",

        callback = function()
            self:TrackNextActivity()
            self:BuildZonesList()
        end,

        enabled = function()
            local zoneId = self:GetSelectedZoneId()
            local isZoneAvailable = ZO_ZoneStories_Manager.GetZoneAvailability(zoneId)
            local canContinueZone = CanZoneStoryContinueTrackingActivities(zoneId)
            return isZoneAvailable and canContinueZone
        end,

        visible = function()
            return self:GetSelectedZoneId() ~= nil
        end,

        sound = SOUNDS.ZONE_STORIES_TRACK_ACTIVITY,
    }

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Select
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),

            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                self:SetFocusOnSelectedZone()
            end,
        },

        -- Track Activity
        trackActivityKeybind,

        -- Back
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),
    }

    -- Zone Selected Keybind Strip
    self.zoneKeybindStripDescriptor = {
        -- Track Activity
        trackActivityKeybind,

        -- Stop Tracking
        {
            alignment = KEYBIND_STRIP_ALIGN_CENTER,

            name = GetString(SI_ZONE_STORY_STOP_TRACKING_ZONE_STORY_ACTION),

            keybind = "UI_SHORTCUT_RIGHT_STICK",

            callback = function()
                ClearTrackedZoneStory()
                self:BuildZonesList()
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.zoneKeybindStripDescriptor)
            end,

            enabled = function()
                return CanZoneStoryContinueTrackingActivities(self:GetSelectedZoneId())
            end,

            visible = function()
                local zoneId  = GetTrackedZoneStoryActivityInfo()
                return zoneId == self:GetSelectedZoneId()
            end,
        },

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.zoneKeybindStripDescriptor)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            self.gridList:Deactivate()
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_QUAD1_TOOLTIP)
            self:UpdateInfoTooltip(GAMEPAD_RIGHT_TOOLTIP)
            self:ActivateCurrentList()
        end, "UI_SHORTCUT_NEGATIVE", SOUNDS.GAMEPAD_MENU_BACK),

        -- Cycle tooltip forward
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,

            name = GetString(SI_ZONE_STORY_ACTIVITY_COMPLETION_CYCLE_KEYBIND),

            keybind = "UI_SHORTCUT_RIGHT_SHOULDER",

            visible = function()
                local selectedData = self.gridList:GetSelectedData()
                if selectedData then
                    -- data with a completion type of ZONE_COMPLETION_TYPE_FEATURED_ACHIEVEMENTS is a different
                    -- entry type than the others (it doesn't have zoneData) and it only ever shows 1 tooltip
                    -- all the other types have at least 2 tooltips to show and so always cycle
                    return selectedData.completionType ~= ZONE_COMPLETION_TYPE_FEATURED_ACHIEVEMENTS
                end

                return false
            end,

            callback = function()
                local selectedData = self.gridList:GetSelectedData()
                if selectedData then
                    local zoneData = selectedData.zoneData
                    local completionType = selectedData.completionType
                    self.tooltipSelectedIndex = ZO_ZoneStories_Gamepad.GetValidatedTooltipIndex(zoneData, completionType, self.tooltipSelectedIndex + 1)
                    ZO_ZoneStories_Gamepad.LayoutCompletionTypeTooltip(zoneData, completionType, self.tooltipSelectedIndex)
                    --Re-narrate when cycling the tooltip
                    SCREEN_NARRATION_MANAGER:QueueGridListEntry(self.gridList)
                end
            end,
        },

        -- Cycle tooltip backward
        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,

            keybind = "UI_SHORTCUT_LEFT_SHOULDER",

            visible = function()
                local selectedData = self.gridList:GetSelectedData()
                if selectedData then
                    -- data with a completion type of ZONE_COMPLETION_TYPE_FEATURED_ACHIEVEMENTS is a different
                    -- entry type than the others (it doesn't have zoneData) and it only ever shows 1 tooltip
                    -- all the other types have at least 2 tooltips to show and so always cycle
                    return selectedData.completionType ~= ZONE_COMPLETION_TYPE_FEATURED_ACHIEVEMENTS
                end

                return false
            end,

            callback = function()
                local selectedData = self.gridList:GetSelectedData()
                if selectedData then
                    local zoneData = selectedData.zoneData
                    local completionType = selectedData.completionType
                    self.tooltipSelectedIndex = ZO_ZoneStories_Gamepad.GetValidatedTooltipIndex(zoneData, completionType, self.tooltipSelectedIndex - 1)
                    ZO_ZoneStories_Gamepad.LayoutCompletionTypeTooltip(zoneData, completionType, self.tooltipSelectedIndex)
                    --Re-narrate when cycling the tooltip
                    SCREEN_NARRATION_MANAGER:QueueGridListEntry(self.gridList)
                end
            end,
        },
    }
end

function ZO_ZoneStories_Gamepad.GetValidatedTooltipIndex(zoneData, completionType, tooltipIndex)
    -- by default the first tooltip is the activity description tooltip and the second will either be a tooltip that
    -- will list out all the activities for the completion type
    -- However, if the completionType has associated achievements we will show individual tooltips for each achievement
    -- instead of the list tooltip
    local maxTooltipIndex = 1
    local numAssociatedAchievements = GetNumAssociatedAchievementsForZoneCompletionType(zoneData.id, completionType)
    if numAssociatedAchievements > 0 then
        maxTooltipIndex = numAssociatedAchievements
    end

    -- wrap the tooltip index
    if tooltipIndex < COMPLETION_ACTIVITY_DESCRIPTION_TOOLTIP_INDEX then
        return maxTooltipIndex
    elseif tooltipIndex > maxTooltipIndex then
        return COMPLETION_ACTIVITY_DESCRIPTION_TOOLTIP_INDEX
    else
        return tooltipIndex
    end
end

function ZO_ZoneStories_Gamepad.LayoutCompletionTypeTooltip(zoneData, completionType, tooltipIndex)
    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP, true)

    if tooltipIndex == COMPLETION_ACTIVITY_DESCRIPTION_TOOLTIP_INDEX then
        GAMEPAD_TOOLTIPS:LayoutZoneStoryActivityCompletion(GAMEPAD_RIGHT_TOOLTIP, zoneData, completionType)
    else
        local achievementId = GetAssociatedAchievementIdForZoneCompletionType(zoneData.id, completionType, tooltipIndex)
        if achievementId ~= 0 then
            GAMEPAD_TOOLTIPS:LayoutAchievement(GAMEPAD_RIGHT_TOOLTIP, achievementId)
        else
            GAMEPAD_TOOLTIPS:LayoutZoneStoryActivityCompletionTypeList(GAMEPAD_RIGHT_TOOLTIP, zoneData, completionType)
        end
    end
end

function ZO_ZoneStories_Gamepad:SetFocusOnSelectedZone()
    self:DeactivateCurrentList()
    self.gridList:Activate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.zoneKeybindStripDescriptor)

    self:UpdateInfoTooltip(GAMEPAD_QUAD1_TOOLTIP)
end

function ZO_ZoneStories_Gamepad:UpdatePlayStoryButtonText()
    if self.gridList and self.gridList:IsActive() then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.zoneKeybindStripDescriptor)
    end
end

function ZO_ZoneStories_Gamepad:UpdateBackgroundTexture()
    local selectedData = self:GetSelectedStoryData()
    if selectedData then
        self.backgroundTexture:SetTexture(GetZoneStoryGamepadBackground(selectedData.id))
    end
end

function ZO_ZoneStories_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if GAMEPAD_ZONE_STORIES_SCENE:IsShowing() and selectedData and selectedData.dataSource then
        self:UpdateZoneStory(selectedData.dataSource)
    end
end

function ZO_ZoneStories_Gamepad:UpdateZoneStory()
    ZO_ZoneStories_Shared.UpdateZoneStory(self)

    self:UpdateInfoTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_ZoneStories_Gamepad:UpdateInfoTooltip(tooltipType)
    GAMEPAD_TOOLTIPS:ClearTooltip(tooltipType)

    if GAMEPAD_ZONE_STORIES_SCENE:IsShowing() then
        local selectedData = self:GetSelectedStoryData()
        if selectedData then
            local selectedZoneId = selectedData.id

            local isZoneAvailable, zoneAvailableErrorText = ZO_ZoneStories_Manager.GetZoneAvailability(selectedZoneId)
            local shouldShowBlockingMessage = not isZoneAvailable and zoneAvailableErrorText ~= nil
            if shouldShowBlockingMessage then
                GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(tooltipType, zoneAvailableErrorText)
            else
                local arePriorityQuestsBlocked, errorStringText = ZO_ZoneStories_Manager.GetZoneCompletionTypeBlockingInfo(selectedZoneId, ZONE_COMPLETION_TYPE_PRIORITY_QUESTS)
                shouldShowBlockingMessage = arePriorityQuestsBlocked and errorStringText ~= nil
                if shouldShowBlockingMessage then
                    GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(tooltipType, errorStringText)
                end
            end
        end
    end
end

function ZO_ZoneStories_Gamepad:OnGridSelectionChanged(oldSelectedData, selectedData)
    -- Deselect previous tile
    if oldSelectedData and oldSelectedData.dataSource and oldSelectedData.dataEntry then
        if oldSelectedData.dataEntry.control then
            oldSelectedData.dataEntry.control.object:SetSelected(false)
        end
        oldSelectedData.isSelected = false
    end

    self.tooltipSelectedIndex = COMPLETION_ACTIVITY_DESCRIPTION_TOOLTIP_INDEX

    -- Select newly selected tile.
    if selectedData and selectedData.dataEntry then
        if selectedData.dataEntry.control then
            selectedData.dataEntry.control.object:SetSelected(true)
        end
        selectedData.isSelected = true

        local completionType = selectedData.completionType
        if completionType == ZONE_COMPLETION_TYPE_FEATURED_ACHIEVEMENTS then
            GAMEPAD_TOOLTIPS:LayoutAchievement(GAMEPAD_RIGHT_TOOLTIP, selectedData.achievementId)
        else
            local zoneData = selectedData.zoneData
            local completedActivities = ZO_ZoneStories_Manager.GetActivityCompletionProgressValues(zoneData.id, completionType)
            if completedActivities > 0 then
                -- the first tooltip is the activity description tooltip so if we've already completed some of the
                -- activities for this type we want to skip to the next tooltip
                -- this should resolve to 1 and since we are guaranteed to have 2 tooltips it doesn't need to be validated
                self.tooltipSelectedIndex = self.tooltipSelectedIndex + 1
            end
            ZO_ZoneStories_Gamepad.LayoutCompletionTypeTooltip(zoneData, completionType, self.tooltipSelectedIndex)
        end
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end

    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.zoneKeybindStripDescriptor)
end

function ZO_ZoneStories_Gamepad:BuildZonesList()
    ZO_ZoneStories_Shared.BuildZonesList(self)

    local list = self:GetMainList()
    local trackedZoneId = GetTrackedZoneStoryActivityInfo()
    local trackedEntryData
    local defaultZoneId = ZO_ZoneStories_Manager.GetDefaultZoneSelection()
    local defaultEntryData
    list:Clear()
    for _, zoneData in ZONE_STORIES_MANAGER:ZoneListIterator() do
        local entryData = ZO_GamepadEntryData:New(zoneData.name)
        entryData:SetDataSource(zoneData)
        if trackedZoneId ~= 0 and trackedZoneId == zoneData.id then
            trackedEntryData = entryData
        elseif zoneData.id == defaultZoneId then
            defaultEntryData = entryData
        end
        list:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
    end
    list:Commit()

    local selectedEntryData = trackedEntryData or defaultEntryData 
    if selectedEntryData then
        local selectIndex = list:GetIndexForData("ZO_GamepadItemSubEntryTemplate", selectedEntryData)
        list:SetSelectedIndexWithoutAnimation(selectIndex)
    end
end

function ZO_ZoneStories_Gamepad:GetSelectedZoneId()
    local list = self:GetMainList()
    local data = list:GetSelectedData()
    if data then
        return data.id
    end
    return nil
end

function ZO_ZoneStories_Gamepad:GetSelectedStoryData()
    local list = self:GetMainList()
    local data = list:GetSelectedData()
    if data then
        return data.dataSource
    end
    return nil
end

function ZO_ZoneStories_Gamepad:SetSelectedByZoneId(zoneId)
    local list = self:GetMainList()
    for i = 1, list:GetNumEntries() do
        local entryData = list:GetEntryData(i)
        if entryData and entryData.id == zoneId then
            list:SetSelectedIndexWithoutAnimation(i)
            break
        end
    end
end

function ZO_ZoneStories_Gamepad_OnInitialize(control)
    ZONE_STORIES_GAMEPAD = ZO_ZoneStories_Gamepad:New(control)
end