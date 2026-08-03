ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_KEYBOARD_DIMENSIONS_X = 96
ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_KEYBOARD_DIMENSIONS_Y = 52
ZO_ZONE_STORIES_ACTIVITY_COMPLETION_TILE_KEYBOARD_ICON_DIMENSIONS = 40

local DESCRIPTION_TO_ACHIEVEMENT_ANCHOR = ZO_Anchor:New(TOPRIGHT, ACHIEVEMENTS:GetAchievementDetailedTooltipControl(), TOPLEFT, -5)

-- Primary logic class must be subclassed after the platform class so that platform specific functions will have priority over the logic class functionality
ZO_ZoneStory_ActivityCompletionTile_Keyboard = ZO_Object.MultiSubclass(ZO_ContextualActionsTile_Keyboard, ZO_ContextualActionsTile)

function ZO_ZoneStory_ActivityCompletionTile_Keyboard:New(...)
    return ZO_ContextualActionsTile.New(self, ...)
end

function ZO_ZoneStory_ActivityCompletionTile_Keyboard:InitializePlatform(...)
    ZO_ContextualActionsTile_Keyboard.InitializePlatform(self, ...)
    
    local control = self.control
    self.iconControl = control:GetNamedChild("Icon")
    self.valueControl = control:GetNamedChild("Title")
    self.selectionFrameControl = control:GetNamedChild("SelectionFrame")
end

function ZO_ZoneStory_ActivityCompletionTile_Keyboard:PostInitializePlatform(...)
    -- keybindStripDescriptor needs to be set after initialize, because ZO_ContextualActionsTile
    -- won't have finished initializing those until after InitializePlatform is called
    ZO_ContextualActionsTile_Keyboard.PostInitializePlatform(self, ...)

    -- Track/Stop Tracking
    table.insert(self.keybindStripDescriptor,
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        name = function()
            if self:IsTracking() then
                return GetString(SI_ZONE_STORY_STOP_TRACKING_ZONE_STORY_ACTION)
            end
            return ZO_ZoneStories_Shared.GetPlayStoryActionTextByZoneAndCompletionType(self.zoneId, self.completionType)
        end,

        keybind = "UI_SHORTCUT_PRIMARY",

        callback = function()
            if self:IsTracking() then
                ClearTrackedZoneStory()
            else
                self:Track()
            end
            ZONE_STORIES_KEYBOARD:BuildZonesList()
        end,

        enabled = function()
            local zoneId = self.zoneId
            local completionType = self.completionType
            local completionIndex = self.completionIndex
            if ZO_ZoneStories_Manager.IsZoneCompletionTypeComplete(zoneId, completionType, completionIndex) then
                return false, GetString(SI_ZONE_STORY_SPECIFIC_ACTION_DISABLED_COMPLETE)
            end

            local isCompletionTypeBlocked, blockingErrorStringText = ZO_ZoneStories_Manager.GetZoneCompletionTypeBlockingInfo(zoneId, completionType, completionIndex)
            if isCompletionTypeBlocked then
                return false, blockingErrorStringText
            end

            return true
        end,

        visible = function()
            return ZO_ZoneStories_Shared.IsZoneCollectibleUnlocked(self.zoneId) and ZO_ZoneStories_Manager.CanTrackCompletionType(self.completionType)
        end,
    })
    
    -- Cycle through tooltip that is moused over
    table.insert(self.keybindStripDescriptor,
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        name = GetString(SI_ZONE_STORY_ACTIVITY_COMPLETION_CYCLE_KEYBIND),

        keybind = "UI_SHORTCUT_TERTIARY",

        ethereal = true,

        callback = function()
            ZONE_STORIES_KEYBOARD:IncrementActivityCompletionTooltip()
        end,

        enabled = function()
            return GetNumAssociatedAchievementsForZoneCompletionType(self.zoneId, self.completionType) > 1
        end,
    })
end

function ZO_ZoneStory_ActivityCompletionTile_Keyboard:Layout(data)
    ZO_ContextualActionsTile.Layout(self, data)

    local zoneId = data.zoneData.id
    local completionType = data.completionType
    local completionIndex = data.completionIndex
    self.zoneData = data.zoneData
    self.zoneId = zoneId
    self.completionType = completionType
    self.completionIndex = completionIndex

    self.iconControl:SetTexture(ZO_ZoneStories_Manager.GetCompletionTypeIcon(completionType, completionIndex))
    local text = ZO_ZoneStories_Manager.GetActivityCompletionProgressText(zoneId, completionType, completionIndex)
    self.valueControl:SetText(text)

    local color = ZO_ZoneStories_Manager.IsZoneCompletionTypeComplete(zoneId, completionType) and ZO_NORMAL_TEXT or ZO_SELECTED_TEXT
    self.valueControl:SetColor(color:UnpackRGB())

    self.selectionFrameControl:SetHidden(not self:IsTracking())
end

function ZO_ZoneStory_ActivityCompletionTile_Keyboard:IsTracking()
    local trackedZoneId, trackedZoneCompletionType = GetTrackedZoneStoryActivityInfo()
    return trackedZoneId == self.zoneId and trackedZoneCompletionType == self.completionType
end

function ZO_ZoneStory_ActivityCompletionTile_Keyboard:Track()
    local SET_AUTO_MAP_NAVIGATION_TARGET = true
    TrackNextActivityForZoneStory(self.zoneId, self.completionType, self.completionIndex, SET_AUTO_MAP_NAVIGATION_TARGET)
end

function ZO_ZoneStory_ActivityCompletionTile_Keyboard:OnMouseEnter()
    ZO_ContextualActionsTile_Keyboard.OnMouseEnter(self)

    local offsetX = self.control:GetParent():GetLeft() - self.control:GetLeft() - 15
    local anchor = ZO_Anchor:New(RIGHT, self.control, LEFT, offsetX)

    ZONE_STORIES_KEYBOARD:ShowActivityCompletionTooltip(self.zoneId, self.completionType, anchor, DESCRIPTION_TO_ACHIEVEMENT_ANCHOR, self.completionIndex)
end

function ZO_ZoneStory_ActivityCompletionTile_Keyboard:OnMouseExit()
    ZO_ContextualActionsTile_Keyboard.OnMouseExit(self)

    ZONE_STORIES_KEYBOARD:HideActivityCompletionTooltip()
end

function ZO_ZoneStory_ActivityCompletionTile_Keyboard:OnMouseUp(button, upInside)
    ZO_ContextualActionsTile_Keyboard.OnMouseUp(self, button, upInside)

    self:Track()
end

function ZO_ZoneStory_ActivityCompletionTile_Keyboard.OnControlInitialized(control)
    ZO_ZoneStory_ActivityCompletionTile_Keyboard:New(control)
end