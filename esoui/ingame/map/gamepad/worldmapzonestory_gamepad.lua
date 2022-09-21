----------------------------------
-- ZO_WorldMapZoneStory_Gamepad --
----------------------------------

-- Shows up with the map as merely an uninteractive brief display, much like a tooltip

ZO_WorldMapZoneStory_Gamepad = ZO_WorldMapZoneStory_Shared:Subclass()

function ZO_WorldMapZoneStory_Gamepad:New(...)
    return ZO_WorldMapZoneStory_Shared.New(self, ...)
end

function ZO_WorldMapZoneStory_Gamepad:Initialize(control)
    ZO_WorldMapZoneStory_Shared.Initialize(self, control, ZO_TranslateFromLeftSceneFragment)

    local header = self.control:GetNamedChild("ContainerHeader")
    local headerData =
    {
        titleText = GetString(SI_ZONE_STORY_ACTIVITY_COMPLETION_HEADER),
    }
    ZO_GamepadGenericHeader_Initialize(header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)
    ZO_GamepadGenericHeader_Refresh(header, headerData)

    WORLD_MAP_ZONE_STORY_GAMEPAD_FRAGMENT = self:GetFragment()
end

-- Begin ZO_WorldMapZoneStory_Shared Overrides --

function ZO_WorldMapZoneStory_Gamepad:InitializeList()
    self.scrollChild = self.control:GetNamedChild("ContainerScrollScrollChild")
    self.rowPool = ZO_ControlPool:New("ZO_WorldMapZoneStoryRow_Gamepad", self.scrollChild, "Row")
    self.rowPool:SetCustomFactoryBehavior(function(control)
        control.icon = control:GetNamedChild("Icon")
        control.descriptorLabel = control:GetNamedChild("Descriptor")
        control.progressLabel = control:GetNamedChild("ProgressLabel")
        control.progressBar = control:GetNamedChild("ProgressBar")
    end)
end

function ZO_WorldMapZoneStory_Gamepad:RegisterForEvents()
    ZO_WorldMapZoneStory_Shared.RegisterForEvents(self)

    local keepInfoObject = SYSTEMS:GetGamepadObject("world_map_keep_info")
    keepInfoObject:RegisterCallback("PreShowKeep", function()
        self:GetFragment():SetHiddenForReason(ZO_WORLD_MAP_ZONE_STORY_HIDE_REASONS.KEEP_INFO_SHOWN, true)
    end)

    keepInfoObject:RegisterCallback("WorldMapKeepInfoHidden", function()
        self:GetFragment():SetHiddenForReason(ZO_WORLD_MAP_ZONE_STORY_HIDE_REASONS.KEEP_INFO_SHOWN, false)
    end)

    CALLBACK_MANAGER:RegisterCallback("WorldMapInfo_Gamepad_Showing", function()
        self:GetFragment():SetHiddenForReason(ZO_WORLD_MAP_ZONE_STORY_HIDE_REASONS.MAP_INFO_SHOWN, true)
    end)

    CALLBACK_MANAGER:RegisterCallback("WorldMapInfo_Gamepad_Hidden", function()
        self:GetFragment():SetHiddenForReason(ZO_WORLD_MAP_ZONE_STORY_HIDE_REASONS.MAP_INFO_SHOWN, false)
    end)
end

function ZO_WorldMapZoneStory_Gamepad:GetBackgroundFragment()
    return GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT
end

function ZO_WorldMapZoneStory_Gamepad:RefreshInfo()
    if self:IsShowing() then
        self.rowPool:ReleaseAllObjects()

        local previousControl = nil
        local maxProgressLabelWidth = 0
        local zoneId = self:GetCurrentZoneStoryZoneId()
        for _, zoneCompletionType in ipairs(ZO_ZONE_STORY_ACTIVITY_COMPLETION_TYPES_SORTED_LIST) do
            if GetNumZoneActivitiesForZoneCompletionType(zoneId, zoneCompletionType) > 0 then
                local control = self.rowPool:AcquireObject()
                control.icon:SetTexture(ZO_ZoneStories_Manager.GetCompletionTypeIcon(zoneCompletionType))
                local numCompletedActivities, totalActivities, numUnblockedActivities, blockingBranchErrorStringId, text = ZO_ZoneStories_Manager.GetActivityCompletionProgressValuesAndText(zoneId, zoneCompletionType)
                --Clear out the desired width so the label sizes based on the text in it
                control.progressLabel:SetWidth(0)
                control.progressLabel:SetText(text)
                maxProgressLabelWidth = zo_max(maxProgressLabelWidth, control.progressLabel:GetTextWidth())
                control.progressBar:SetMinMax(0, totalActivities > 0 and totalActivities or 1)
                control.progressBar:SetValue(numCompletedActivities)

                if previousControl then
                    control:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 5)
                else
                    control:SetAnchor(TOPLEFT, self.scrollChild)
                end

                previousControl = control
            end
        end
        --Have all of the labels fill the same width so that bars all align
        for _, control in pairs(self.rowPool:GetActiveObjects()) do
            control.progressLabel:SetWidth(maxProgressLabelWidth)
        end
    end
end

-- End ZO_WorldMapZoneStory_Shared Overrides --

--------------------------------------
-- ZO_WorldMapInfoZoneStory_Gamepad --
--------------------------------------

-- Shows up in the map info scene as one of the interactive tab fragments

ZO_WORLD_MAP_INFO_ZONE_STORY_ENTRY_PROGRESS_WIDTH = 75
ZO_WORLD_MAP_INFO_ZONE_STORY_ENTRY_LABEL_WIDTH = ZO_GAMEPAD_DEFAULT_LIST_ENTRY_WIDTH_AFTER_INDENT - ZO_WORLD_MAP_INFO_ZONE_STORY_ENTRY_PROGRESS_WIDTH

local COMPLETION_ACTIVITY_DESCRIPTION_TOOLTIP_INDEX = 0

ZO_WorldMapInfoZoneStory_Gamepad = ZO_WorldMapZoneStory_Shared:Subclass()

function ZO_WorldMapInfoZoneStory_Gamepad:New(...)
    return ZO_WorldMapZoneStory_Shared.New(self, ...)
end

function ZO_WorldMapInfoZoneStory_Gamepad:Initialize(control)
    ZO_WorldMapZoneStory_Shared.Initialize(self, control, ZO_SimpleSceneFragment)

    WORLD_MAP_ZONE_INFO_STORY_GAMEPAD_FRAGMENT = self:GetFragment()
end

function ZO_WorldMapInfoZoneStory_Gamepad:UpdateTooltip()
    if self:IsShowing() then
        local targetData = self.list:GetTargetData()
        if targetData then
            local zoneData = targetData.zoneData
            local zoneCompletionType = targetData.zoneCompletionType
            ZO_ZoneStories_Gamepad.LayoutCompletionTypeTooltip(zoneData, zoneCompletionType, self.tooltipSelectedIndex)
        end
    end
end

-- Begin ZO_WorldMapZoneStory_Shared Overrides --

function ZO_WorldMapInfoZoneStory_Gamepad:InitializeList()
    self.list = ZO_GamepadVerticalParametricScrollList:New(self.control:GetNamedChild("MainList"))
    self.list:AddDataTemplate("ZO_WorldMapInfoZoneStoryEntry_Gamepad", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    local function OnTargetChanged()
        self.tooltipSelectedIndex = COMPLETION_ACTIVITY_DESCRIPTION_TOOLTIP_INDEX
        local targetData = self.list:GetTargetData()
        if targetData then
            local completedActivities = ZO_ZoneStories_Manager.GetActivityCompletionProgressValues(targetData.zoneData.id, targetData.zoneCompletionType)
            if completedActivities > 0 then
                -- the first tooltip is the activity description tooltip so if we've already completed some of the
                -- activities for this type we want to skip to the next tooltip
                -- this should resolve to 1 and since we are guaranteed to have 2 tooltips it doesn't need to be validated
                self.tooltipSelectedIndex = self.tooltipSelectedIndex + 1
            end
        end
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        self:UpdateTooltip()
    end
    self.list:SetOnTargetDataChangedCallback(OnTargetChanged)
    self.list:SetAlignToScreenCenter(true)
    local narrationInfo = 
    {
        canNarrate = function()
            return self:IsShowing()
        end,
        headerNarrationFunction = function()
            return GAMEPAD_WORLD_MAP_INFO:GetHeaderNarration()
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterParametricList(self.list, narrationInfo)
end

function ZO_WorldMapInfoZoneStory_Gamepad:InitializeKeybindDescriptor()
    self.tooltipSelectedIndex = COMPLETION_ACTIVITY_DESCRIPTION_TOOLTIP_INDEX

    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            name = GetString(SI_ZONE_STORY_OPEN_FROM_MAP_ACTION),

            keybind = "UI_SHORTCUT_QUATERNARY",

            callback = function()
                ZONE_STORIES_MANAGER:ShowZoneStoriesScene(self:GetCurrentZoneStoryZoneId())
            end,
        },

        {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,

            name = GetString(SI_ZONE_STORY_ACTIVITY_COMPLETION_CYCLE_KEYBIND),

            keybind = "UI_SHORTCUT_INPUT_RIGHT",

            callback = function()
                local targetData = self.list:GetTargetData()
                self.tooltipSelectedIndex = ZO_ZoneStories_Gamepad.GetValidatedTooltipIndex(targetData.zoneData, targetData.zoneCompletionType, self.tooltipSelectedIndex + 1)

                self:UpdateTooltip()
                SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.list)
            end,
        },

        {
            -- No name, shares name with INPUT_RIGHT

            alignment = KEYBIND_STRIP_ALIGN_RIGHT,

            keybind = "UI_SHORTCUT_INPUT_LEFT",

            callback = function()
                local targetData = self.list:GetTargetData()
                self.tooltipSelectedIndex = ZO_ZoneStories_Gamepad.GetValidatedTooltipIndex(targetData.zoneData, targetData.zoneCompletionType, self.tooltipSelectedIndex - 1)

                self:UpdateTooltip()
                SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.list)
            end,
        }
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, ZO_WorldMapInfo_OnBackPressed)
end

function ZO_WorldMapInfoZoneStory_Gamepad:GetBackgroundFragment()
    return nil
end

function ZO_WorldMapInfoZoneStory_Gamepad:RefreshInfo()
    if self:IsShowing() then
        self.list:Clear()

        local zoneId = self:GetCurrentZoneStoryZoneId()
        local zoneData = ZONE_STORIES_MANAGER:GetZoneData(zoneId)
        for _, zoneCompletionType in ipairs(ZO_ZONE_STORY_ACTIVITY_COMPLETION_TYPES_SORTED_LIST) do
            if GetNumZoneActivitiesForZoneCompletionType(zoneId, zoneCompletionType) > 0 then
                local descriptor = GetString("SI_ZONECOMPLETIONTYPE", zoneCompletionType)
                local icon = ZO_ZoneStories_Manager.GetCompletionTypeIcon(zoneCompletionType)
                local numCompletedActivities, totalActivities, numUnblockedActivities, _, text = ZONE_STORIES_MANAGER.GetActivityCompletionProgressValuesAndText(zoneId, zoneCompletionType)

                local entryData = ZO_GamepadEntryData:New(descriptor, icon)
                entryData.zoneData = zoneData
                entryData.zoneCompletionType = zoneCompletionType
                local MIN_ACTIVITIES = 0
                entryData:SetBarValues(MIN_ACTIVITIES, totalActivities, numCompletedActivities)
                entryData:AddSubLabel(text)
                entryData:SetFontScaleOnSelection(false)
                entryData:SetShowUnselectedSublabels(true)
                entryData:SetShowBarEvenWhenUnselected(false)
                self.list:AddEntry("ZO_WorldMapInfoZoneStoryEntry_Gamepad", entryData)
            end
        end

        self.list:Commit()
    end
end

function ZO_WorldMapInfoZoneStory_Gamepad:CanCycleTooltip()
    return true
end

function ZO_WorldMapInfoZoneStory_Gamepad:OnShowing()
    GAMEPAD_TOOLTIPS:SetAutoShowBg(GAMEPAD_RIGHT_TOOLTIP, false)

    ZO_WorldMapZoneStory_Shared.OnShowing(self)

    self.list:Activate()
    self:RefreshInfo()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_WorldMapInfoZoneStory_Gamepad:OnHiding()
    GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_WorldMapInfoZoneStory_Gamepad:OnHidden()
    ZO_WorldMapZoneStory_Shared.OnHidden(self)

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self.list:Deactivate()
end

-- End ZO_WorldMapZoneStory_Shared Overrides --

-- Begin Global Functions --

function ZO_WorldMapZoneStory_Gamepad_OnInitialized(control)
    WORLD_MAP_ZONE_STORY_GAMEPAD = ZO_WorldMapZoneStory_Gamepad:New(control)
end

function ZO_WorldMapInfoZoneStory_Gamepad_OnInitialized(control)
    GAMEPAD_WORLD_MAP_INFO_ZONE_STORY = ZO_WorldMapInfoZoneStory_Gamepad:New(control)
end

-- End Global Functions --