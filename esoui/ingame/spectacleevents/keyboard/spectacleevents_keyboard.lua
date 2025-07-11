local KEYBOARD_SPECTACLE_EVENTS_BACKGROUND_TEXTURE_WIDTH = 620
local KEYBOARD_SPECTACLE_EVENTS_BACKGROUND_SOURCE_WIDTH = 1024
ZO_KEYBOARD_SPECTACLE_EVENTS_BACKGROUND_TEXTURE_COORD_RIGHT = KEYBOARD_SPECTACLE_EVENTS_BACKGROUND_TEXTURE_WIDTH / KEYBOARD_SPECTACLE_EVENTS_BACKGROUND_SOURCE_WIDTH

ZO_SpectacleEvents_Keyboard = ZO_SpectacleEvents_Shared:Subclass()

function ZO_SpectacleEvents_Keyboard:OnDeferredInitialize()
    ZO_SpectacleEvents_Shared.OnDeferredInitialize(self)
end

function ZO_SpectacleEvents_Keyboard:InitializeActivityFinderCategory()
    self.categoryData =
    {
        priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.SPECTACLE_EVENTS,
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_WRITHING_WALL),
        normalIcon = "EsoUI/Art/LFG/LFG_indexIcon_writhingWall_up.dds",
        pressedIcon = "EsoUI/Art/LFG/LFG_indexIcon_writhingWall_down.dds",
        mouseoverIcon = "EsoUI/Art/LFG/LFG_indexIcon_writhingWall_over.dds",
        disabledIcon = "EsoUI/Art/LFG/LFG_indexIcon_writhingWall_disabled.dds",
        categoryFragment = self.fragment,
        visible = function()
            return GetNumActiveSpectacleEvents() > 0
        end,
    }
    GROUP_MENU_KEYBOARD:AddCategory(self.categoryData)
end

-- Override
function ZO_SpectacleEvents_Keyboard:InitializeControls()
    ZO_SpectacleEvents_Shared.InitializeControls(self)

    self.control.object = self
    self.acceptQuestButton = self.control:GetNamedChild("AcceptQuest")
    self.showOnMapButton = self.control:GetNamedChild("ShowOnMap")
    self.backgroundTexture = self.infoContainerControl:GetNamedChild("Background")
end

function ZO_SpectacleEvents_Keyboard:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Show On Map
        {
            keybind = "UI_SHORTCUT_SHOW_QUEST_ON_MAP",
            name = GetString(SI_QUEST_JOURNAL_SHOW_ON_MAP),
            callback = function()
                self:ShowActiveSpectacleEventQuestOnMap()
            end,
            ethereal = true,
            enabled = function()
                return self:GetActiveSpectacleEventQuestIndex() ~= nil
            end,
        }
    }
end

-- Override
function ZO_SpectacleEvents_Keyboard:OnKeybindsUpdated(active)
    ZO_SpectacleEvents_Shared.OnKeybindsUpdated(self)

    self:UpdateButtons()
end

-- Override
function ZO_SpectacleEvents_Keyboard:OnShowing()
    ZO_SpectacleEvents_Shared.OnShowing(self)

    self:UpdateButtons()
end

-- Override
function ZO_SpectacleEvents_Keyboard:InitializeGridList()
    self.gridList = ZO_GridScrollList_Keyboard:New(self.gridListControl)

    local HIDE_CALLBACK = nil
    local dimensionsX = ZO_ZONE_STORIES_ACHIEVEMENT_TILE_KEYBOARD_DIMENSIONS_X
    local dimensionsY = ZO_ZONE_STORIES_ACHIEVEMENT_TILE_KEYBOARD_DIMENSIONS_Y
    local gridPaddingX = 2
    local gridPaddingY = 20
    self.gridList:AddEntryTemplate("ZO_ZoneStory_AchievementTile_Keyboard_Control", dimensionsX, dimensionsY, ZO_DefaultGridTileEntrySetup, HIDE_CALLBACK, ZO_DefaultGridTileEntryReset, gridPaddingX, gridPaddingY)
end

-- Override
function ZO_SpectacleEvents_Keyboard:AddGridListAchievementEntry(data)
    self.gridList:AddEntry(data, "ZO_ZoneStory_AchievementTile_Keyboard_Control")
end

-- Override
function ZO_SpectacleEvents_Keyboard:UpdateBackground()
    local activityFinderBackground = GetActiveSpectacleEventActivityFinderBackgroundKeyboard(self.activeSpectacleEventId)
    self.backgroundTexture:SetTexture(activityFinderBackground)
end

function ZO_SpectacleEvents_Keyboard:UpdateButtons()
    local acceptQuestVisible = self:CanAcceptActiveSpectacleEventQuest()
    self.acceptQuestButton:SetHidden(not acceptQuestVisible)

    local showOnMapVisible = self:GetActiveSpectacleEventQuestIndex() ~= nil
    self.showOnMapButton:SetHidden(not showOnMapVisible)
end

function ZO_SpectacleEvents_Keyboard.OnControlInitialized(control)
    SPECTACLE_EVENTS_KEYBOARD = ZO_SpectacleEvents_Keyboard:New(control)
end