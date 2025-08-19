local GAMEPAD_SPECTACLE_EVENTS_BACKGROUND_SOURCE_WIDTH = 1024
local GAMEPAD_SPECTACLE_EVENTS_BACKGROUND_TEXTURE_WIDTH = 832
ZO_GAMEPAD_SPECTACLE_EVENTS_BACKGROUND_TEXTURE_COORDS_RIGHT = GAMEPAD_SPECTACLE_EVENTS_BACKGROUND_TEXTURE_WIDTH / GAMEPAD_SPECTACLE_EVENTS_BACKGROUND_SOURCE_WIDTH

local GAMEPAD_SPECTACLE_EVENTS_BACKGROUND_SOURCE_HEIGHT = 1024
local GAMEPAD_SPECTACLE_EVENTS_BACKGROUND_TEXTURE_HEIGHT = 955
ZO_GAMEPAD_SPECTACLE_EVENTS_BACKGROUND_TEXTURE_COORDS_BOTTOM = GAMEPAD_SPECTACLE_EVENTS_BACKGROUND_TEXTURE_HEIGHT / GAMEPAD_SPECTACLE_EVENTS_BACKGROUND_SOURCE_HEIGHT

ZO_SpectacleEvents_Gamepad = ZO_SpectacleEvents_Shared:Subclass()

function ZO_SpectacleEvents_Gamepad:OnDeferredInitialize()
    ZO_SpectacleEvents_Shared.OnDeferredInitialize(self)

    self.isActivated = false
end

function ZO_SpectacleEvents_Gamepad:InitializeActivityFinderCategory()
    self.categoryData =
    {
        gamepadData =
        {
            priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.SPECTACLE_EVENTS,
            name = GetString(SI_ACTIVITY_FINDER_CATEGORY_WRITHING_WALL),
            menuIcon = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_writhingWall.dds",
            disabledMenuIcon = "EsoUI/Art/LFG/Gamepad/LFG_menuIcon_writhingWall_disabled.dds",
            categoryFragment = self.fragment,
            visible = function()
                return GetNumActiveSpectacleEvents() > 0
            end,
            activateCategory = function()
                self:Activate()
            end,
        },
    }

    local gamepadData = self.categoryData.gamepadData
    ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:AddCategory(gamepadData, gamepadData.priority)
end

function ZO_SpectacleEvents_Gamepad:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Back
        KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(function()
            self:Deactivate()
        end, "UI_SHORTCUT_NEGATIVE", SOUNDS.GAMEPAD_MENU_BACK),

        -- Accept Quest
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            name = GetString(SI_LFG_ACCEPT_QUEST),
            callback = function()
                self:RequestBestowActiveSpectacleEventQuest()
            end,
            visible = function()
                return self:CanAcceptActiveSpectacleEventQuest()
            end,
        },

        -- Show On Map
        {
            keybind = "UI_SHORTCUT_SECONDARY",
            name = GetString(SI_QUEST_JOURNAL_SHOW_ON_MAP),
            callback = function()
                self:ShowActiveSpectacleEventQuestOnMap()
            end,
            visible = function()
                return self:GetActiveSpectacleEventQuestIndex() ~= nil
            end,
        }
    }
end

function ZO_SpectacleEvents_Gamepad:Activate()
    if ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:IsShowing() then
        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:DeactivateCurrentList()
        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:RemoveListKeybinds()
        GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.GAMEPAD_ACTIVITY_FINDER_QUEUE_DATA_DEPENDENCIES)

        PlaySound(SOUNDS.DEFAULT_WINDOW_OPEN)
        -- Setting isActivated needs to happen before AddKeybinds
        self.isActivated = true
        self:AddKeybinds()
        self.gridList:Activate()
    end
end

function ZO_SpectacleEvents_Gamepad:Deactivate()
    if self.isActivated then
        self:RemoveKeybinds()
        self.gridList:Deactivate()
        self.isActivated = false
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)

        if ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:IsShowing() then
            GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_ACTIVITY_FINDER_QUEUE_DATA_DEPENDENCIES)
            ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:AddListKeybinds()
            ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ActivateCurrentList()
        end
    end
end

-- Override
function ZO_SpectacleEvents_Gamepad:CanAddKeybinds()
    if self.isActivated then
        return ZO_SpectacleEvents_Shared.CanAddKeybinds(self)
    end
    return false
end

function ZO_SpectacleEvents_Gamepad:GetCategoryData()
    return self.categoryData
end

-- Override
function ZO_SpectacleEvents_Gamepad:InitializeControls()
    ZO_SpectacleEvents_Shared.InitializeControls(self)

    self.backgroundTexture = self.control:GetNamedChild("Background")
end

-- Override
function ZO_SpectacleEvents_Gamepad:OnShowing()
    ZO_SpectacleEvents_Shared.OnShowing(self)

    SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
end

-- Override
function ZO_SpectacleEvents_Gamepad:OnHiding()
    ZO_SpectacleEvents_Shared.OnHiding(self)

    SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
    self:Deactivate()
end

-- Override
function ZO_SpectacleEvents_Gamepad:InitializeGridList()
    self.gridList = ZO_GridScrollList_Gamepad:New(self.gridListControl)

    local HIDE_CALLBACK = nil
    local dimensionsX = ZO_ZONE_STORIES_ACHIEVEMENT_TILE_GAMEPAD_DIMENSIONS_X
    local dimensionsY = ZO_ZONE_STORIES_ACHIEVEMENT_TILE_GAMEPAD_DIMENSIONS_Y
    local gridPaddingX = 5
    local gridPaddingY = 25
    self.gridList:AddEntryTemplate("ZO_ZoneStory_AchievementTile_Gamepad_Control", dimensionsX, dimensionsY, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, gridPaddingX, gridPaddingY)
    self.gridList:SetOnSelectedDataChangedCallback(function(...) self:OnGridSelectionChanged(...) end)

    local function GetHeaderNarration()
        local narrations = {}
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.titleControl:GetText()))
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.descriptionControl:GetText()))

        if not self.progressBarHeaderLabel:IsHidden() then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.progressBarHeaderLabel:GetText()))
        end

        if not self.progressStatusBar:IsHidden() then
            local barMin, barMax = self.progressStatusBar:GetMinMax()
            local barValue = self.progressStatusBar:GetValue()
            local percentFormat = "%.1f"
            local progressBarNarration = ZO_GetProgressBarNarrationText(barMin, barMax, barValue, percentFormat)
            ZO_AppendNarration(narrations, progressBarNarration)
        end

        if not self.phaseCompleteLabel:IsHidden() then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.phaseCompleteLabel:GetText()))
        end

        if not self.nextPhaseBeginsLabel:IsHidden() then
            ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.nextPhaseBeginsLabel:GetText()))
        end

        return narrations
    end
    self.gridList:SetHeaderNarrationFunction(GetHeaderNarration)
end

-- Override
function ZO_SpectacleEvents_Gamepad:AddGridListAchievementEntry(data)
    self.gridList:AddEntry(data, "ZO_ZoneStory_AchievementTile_Gamepad_Control")
end

-- Override
function ZO_SpectacleEvents_Gamepad:UpdateBackground()
    local activityFinderBackground = GetActiveSpectacleEventActivityFinderBackgroundGamepad(self.activeSpectacleEventId)
    self.backgroundTexture:SetTexture(activityFinderBackground)
end

function ZO_SpectacleEvents_Gamepad:OnGridSelectionChanged(oldSelectedData, selectedData)
    if selectedData then
        GAMEPAD_TOOLTIPS:LayoutAchievement(GAMEPAD_RIGHT_TOOLTIP, selectedData.achievementId)
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end

function ZO_SpectacleEvents_Gamepad.OnControlInitialized(control)
    SPECTACLE_EVENTS_GAMEPAD = ZO_SpectacleEvents_Gamepad:New(control)
end