ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_KEYBOARD_DIMENSIONS_X = 98
ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_KEYBOARD_DIMENSIONS_Y = 40
ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_KEYBOARD_ICON_DIMENSIONS = 40

local DESCRIPTION_TO_ACHIEVEMENT_ANCHOR = ZO_Anchor:New(TOPRIGHT, ACHIEVEMENTS:GetAchievementDetailedTooltipControl(), TOPLEFT, -5)

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_ZoneStory_ActivityCompletionTile_Keyboard = ZO_Object.MultiSubclass(ZO_Tile_Keyboard, ZO_ZoneStory_ActivityCompletionTile)

function ZO_ZoneStory_ActivityCompletionTile_Keyboard:New(...)
    return ZO_ZoneStory_ActivityCompletionTile.New(self, ...)
end

function ZO_ZoneStory_ActivityCompletionTile_Keyboard:InitializePlatform(...)
    ZO_Tile_Keyboard.InitializePlatform(self, ...)

    self.keybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Cycle through tooltip that is moused over
        {
            name = GetString(SI_ZONE_STORY_ACTIVITY_COMPLETION_CYCLE_KEYBIND),

            keybind = "UI_SHORTCUT_TERTIARY",

            ethereal = true,

            callback = function()
                ZONE_STORIES_KEYBOARD:IncrementActivityCompletionTooltip()
            end,

            enabled = function()
                return GetNumAssociatedAchievementsForZoneCompletionType(self.zoneData.id, self.completionType) > 1
            end,
        }
    }
end

function ZO_ZoneStory_ActivityCompletionTile_Keyboard:OnMouseEnter()
    ZO_Tile_Keyboard.OnMouseEnter(self)
    
    local offsetX = self.control:GetParent():GetLeft() - self.control:GetLeft() - 15
    local anchor = ZO_Anchor:New(RIGHT, self.control, LEFT, offsetX)

    ZONE_STORIES_KEYBOARD:ShowActivityCompletionTooltip(self.zoneData.id, self.completionType, anchor, DESCRIPTION_TO_ACHIEVEMENT_ANCHOR)

    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_ZoneStory_ActivityCompletionTile_Keyboard:OnMouseExit()
    ZO_Tile_Keyboard.OnMouseExit(self)

    ZONE_STORIES_KEYBOARD:HideActivityCompletionTooltip()

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_ZoneStory_ActivityCompletionTile_Keyboard:OnControlHidden()
    if self.isMousedOver then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZO_ZoneStory_ActivityCompletionTile_Keyboard_OnInitialized(control)
    ZO_ZoneStory_ActivityCompletionTile_Keyboard:New(control)
end