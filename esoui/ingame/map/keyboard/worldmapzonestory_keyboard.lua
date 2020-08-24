ZO_WORLD_MAP_ZONE_STORY_ROW_HEIGHT = 40

local ZONE_COMPLETION_TYPE_ROW_DATA = 1
local DESCRIPTION_TO_ACHIEVEMENT_ANCHOR = ZO_Anchor:New(TOPLEFT, ACHIEVEMENTS:GetAchievementDetailedTooltipControl(), TOPRIGHT, 5)

ZO_WorldMapZoneStory_Keyboard = ZO_WorldMapZoneStory_Shared:Subclass()

function ZO_WorldMapZoneStory_Keyboard:New(...)
    return ZO_WorldMapZoneStory_Shared.New(self, ...)
end

function ZO_WorldMapZoneStory_Keyboard:Initialize(control)
    ZO_WorldMapZoneStory_Shared.Initialize(self, control, ZO_FadeSceneFragment)

    WORLD_MAP_ZONE_STORY_KEYBOARD_FRAGMENT = self:GetFragment()
end

function ZO_WorldMapZoneStory_Keyboard:GetBackgroundFragment()
    return MEDIUM_LEFT_PANEL_BG_FRAGMENT
end

function ZO_WorldMapZoneStory_Keyboard:OnHiding()
    ZO_WorldMapZoneStory_Shared.OnHiding(self)

    self:ClearMouseoverControl()
end

function ZO_WorldMapZoneStory_Keyboard:ClearMouseoverControl()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self.mouseoverRow = nil
    ZONE_STORIES_KEYBOARD:HideActivityCompletionTooltip()
end

function ZO_WorldMapZoneStory_Keyboard:OnMouseEnterRow(control)
    if self:IsShowing() then
        local OFFSET_X = 40
        local anchor = ZO_Anchor:New(LEFT, control, RIGHT, OFFSET_X)
        local data = control.dataEntry.data
        ZONE_STORIES_KEYBOARD:ShowActivityCompletionTooltip(data.zoneId, data.zoneCompletionType, anchor, DESCRIPTION_TO_ACHIEVEMENT_ANCHOR)

        self.mouseoverRow = control

        if not KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor) then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
        end
    end
end

function ZO_WorldMapZoneStory_Keyboard:OnMouseExitRow(control)
    if self:IsShowing() then
        self:ClearMouseoverControl()
    end
end

-- Begin ZO_WorldMapZoneStory_Shared Overrides --

function ZO_WorldMapZoneStory_Keyboard:InitializeList()
    self.list = self.control:GetNamedChild("List")

    local function SetupCompletionType(control, data)
        local zoneId = data.zoneId
        local zoneCompletionType = data.zoneCompletionType

        local icon = ZO_ZoneStories_Manager.GetCompletionTypeIcon(zoneCompletionType)
        local numCompletedActivities, totalActivities, numUnblockedActivities, _, progressText = ZONE_STORIES_MANAGER.GetActivityCompletionProgressValuesAndText(zoneId, zoneCompletionType)

        control.icon:SetTexture(icon)
        control.progressBar:SetMinMax(0, totalActivities)
        control.progressBar:SetValue(numCompletedActivities)
        control.progressBarProgressLabel:SetText(progressText)
    end

    ZO_ScrollList_AddDataType(self.list, ZONE_COMPLETION_TYPE_ROW_DATA, "ZO_WorldMapZoneStoryRow_Keyboard", ZO_WORLD_MAP_ZONE_STORY_ROW_HEIGHT, SetupCompletionType)
end

function ZO_WorldMapZoneStory_Keyboard:InitializeKeybindDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        {
            name = GetString(SI_ZONE_STORY_ACTIVITY_COMPLETION_CYCLE_KEYBIND),

            keybind = "UI_SHORTCUT_TERTIARY",

            ethereal = true,

            enabled = function()
                return self:CanCycleTooltip()
            end,

            callback = function()
                ZONE_STORIES_KEYBOARD:IncrementActivityCompletionTooltip()
            end,
        },
    }
end

function ZO_WorldMapZoneStory_Keyboard:RegisterForEvents()
    ZO_WorldMapZoneStory_Shared.RegisterForEvents(self)

    local keepInfoObject = SYSTEMS:GetKeyboardObject("world_map_keep_info")
    keepInfoObject:RegisterCallback("PreShowKeep", function()
        self:GetFragment():SetHiddenForReason(ZO_WORLD_MAP_ZONE_STORY_HIDE_REASONS.KEEP_INFO_SHOWN, true)
    end)

    keepInfoObject:RegisterCallback("WorldMapKeepInfoHidden", function()
        self:GetFragment():SetHiddenForReason(ZO_WORLD_MAP_ZONE_STORY_HIDE_REASONS.KEEP_INFO_SHOWN, false)
    end)
end

function ZO_WorldMapZoneStory_Keyboard:RefreshInfo()
    if self:IsShowing() then
        ZO_ScrollList_Clear(self.list)
        local scrollData = ZO_ScrollList_GetDataList(self.list)

        for _, zoneCompletionType in ipairs(ZO_ZONE_STORY_ACTIVITY_COMPLETION_TYPES_SORTED_LIST) do
            if GetNumZoneActivitiesForZoneCompletionType(self:GetCurrentZoneStoryZoneId(), zoneCompletionType) > 0 then
                local data =
                {
                    zoneId = self:GetCurrentZoneStoryZoneId(),
                    zoneCompletionType = zoneCompletionType,
                }
                local dataEntry = ZO_ScrollList_CreateDataEntry(ZONE_COMPLETION_TYPE_ROW_DATA, data)
                table.insert(scrollData, dataEntry)
            end
        end

        ZO_ScrollList_Commit(self.list)
    end
end

function ZO_WorldMapZoneStory_Keyboard:CanCycleTooltip()
    if self.mouseoverRow then
        local data = self.mouseoverRow.dataEntry.data
        return GetNumAssociatedAchievementsForZoneCompletionType(data.zoneId, data.zoneCompletionType) > 1
    end
    return false
end

-- End ZO_WorldMapZoneStory_Shared Overrides --

-- Begin Global Functions --

function ZO_WorldMapZoneStoryRow_Keyboard_OnInitialized(control)
    control.icon = control:GetNamedChild("Icon")
    control.progressBar = control:GetNamedChild("ProgressStatusBar")
    ZO_StatusBar_SetGradientColor(control.progressBar, ZO_XP_BAR_GRADIENT_COLORS)
    control.progressBarProgressLabel = control.progressBar:GetNamedChild("Progress")
end

function ZO_WorldMapZoneStoryRow_Keyboard_OnMouseEnter(control)
    WORLD_MAP_ZONE_STORY_KEYBOARD:OnMouseEnterRow(control)
end

function ZO_WorldMapZoneStoryRow_Keyboard_OnMouseExit(control)
    WORLD_MAP_ZONE_STORY_KEYBOARD:OnMouseExitRow(control)
end

function ZO_WorldMapZoneStory_Keyboard_OnInitialized(control)
    WORLD_MAP_ZONE_STORY_KEYBOARD = ZO_WorldMapZoneStory_Keyboard:New(control)
end

function ZO_WorldMapZoneStory_Keyboard_ZoneStoriesButton_OnClick(control)
    ZONE_STORIES_MANAGER:ShowZoneStoriesScene(WORLD_MAP_ZONE_STORY_KEYBOARD:GetCurrentZoneStoryZoneId())
end

-- End Global Functions --