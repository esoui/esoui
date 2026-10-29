ZO_MINIMAP_ZOOM_IN = -0.5
ZO_MINIMAP_ZOOM_OUT = 0.5

ZO_Minimap = ZO_DeferredInitializingObject:Subclass()

function ZO_Minimap:Initialize(control)
    self.control = control
    self.mapDisplay = control:GetNamedChild("Display")
    self.mapNameLabel = control:GetNamedChild("MapName")
    self.poiIcon = control:GetNamedChild("POIIcon")

    local FADE_IN_TIME_MS = 0
    self.fragment = ZO_HUDFadeSceneFragment:New(control, FADE_IN_TIME_MS)

    ZO_DeferredInitializingObject.Initialize(self, self.fragment)

    MINIMAP_FRAGMENT = self.fragment

    local MINIMAP_OPTIONS =
    {
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.BOOLEAN,
            name = GetString(SI_HUD_EDITOR_CUSTOM_OPTION_VISIBLE),
            tooltipText = GetString(SI_INTERFACE_OPTIONS_SHOW_MINIMAP_TOOLTIP),
            key = "Visible",
            defaultValue = function()
                return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_MINIMAP)
            end,
            dontSave = true,
            callback = function(element, subKey, oldValue, value)
                if value ~= oldValue then
                    SetSetting(SETTING_TYPE_UI, UI_SETTING_SHOW_MINIMAP, tostring(value))
                end
            end,
        },
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.ENUM,
            name = GetString(SI_INTERFACE_OPTIONS_COMPASS_ACTIVE_QUESTS),
            tooltipText = GetString(SI_INTERFACE_OPTIONS_COMPASS_ACTIVE_QUESTS_TOOLTIP),
            key = "ActiveQuests",
            valueStringPrefix = "SI_COMPASSACTIVEQUESTSCHOICE",
            values = { COMPASS_ACTIVE_QUESTS_CHOICE_OFF, COMPASS_ACTIVE_QUESTS_CHOICE_ON, COMPASS_ACTIVE_QUESTS_CHOICE_FOCUSED, },
            valueTooltips = { GetString(SI_INTERFACE_OPTIONS_COMPASS_ACTIVE_QUESTS_OFF_RESTRICTION), "", GetString(SI_INTERFACE_OPTIONS_COMPASS_ACTIVE_QUESTS_FOCUSED_RESTRICTION) },
            defaultValue = function()
                return tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_COMPASS_ACTIVE_QUESTS))
            end,
            dontSave = true,
            callback = function(element, subKey, oldValue, value)
                if value ~= oldValue then
                    SetSetting(SETTING_TYPE_UI, UI_SETTING_COMPASS_ACTIVE_QUESTS, tostring(value))
                end
            end,
        },
        {
            type = ZO_HUD_EDITOR_OPTION_TYPES.BOOLEAN,
            name = GetString(SI_INTERFACE_OPTIONS_COMPASS_QUEST_GIVERS),
            tooltipText = GetString(SI_INTERFACE_OPTIONS_COMPASS_QUEST_GIVERS_TOOLTIP),
            key = "CompassQuestGivers",
            defaultValue = function()
                return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_COMPASS_QUEST_GIVERS)
            end,
            enabled = function()
                return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_QUEST_BESTOWER_INDICATORS)
            end,
            dontSave = true,
            callback = function(element, subKey, oldValue, value)
                if value ~= oldValue then
                    SetSetting(SETTING_TYPE_UI, UI_SETTING_COMPASS_QUEST_GIVERS, tostring(value))
                end
            end,
        },
    }

    local DEFAULT_CONFIG = nil
    local elementName = GetString(SI_HUD_EDITOR_MINIMAP)
    self.keyboardElement = HUD_MANAGER:RegisterKeyboardElement(self.control, elementName, DEFAULT_CONFIG, MINIMAP_OPTIONS)
    self.gamepadElement = HUD_MANAGER:RegisterGamepadElement(self.control, elementName, DEFAULT_CONFIG, MINIMAP_OPTIONS)

    local function OnInterfaceSettingChanged(_, settingType, settingId)
        if settingType == SETTING_TYPE_UI and settingId == UI_SETTING_SHOW_MINIMAP then
            self:RefreshEnabled()
        end
    end
    EVENT_MANAGER:RegisterForEvent("ZO_Minimap", EVENT_INTERFACE_SETTING_CHANGED, OnInterfaceSettingChanged)

    self:RefreshEnabled()
end

function ZO_Minimap:OnDeferredInitialize()
    self.mapNameAnimation = ZO_AlphaAnimation:New(self.mapNameLabel)
    self.mapNameHighlightAnimation = ZO_AlphaAnimation:New(self.mapNameLabel:GetNamedChild("Highlight"))
    self.poiIconAnimation = ZO_AlphaAnimation:New(self.poiIcon)

    local iconScaleDownAnimation
    iconScaleDownAnimation, self.iconScaleDownTimeline = CreateSimpleAnimation(ANIMATION_SCALE, self.poiIcon)
    iconScaleDownAnimation:SetScaleValues(1.75, 1)
    iconScaleDownAnimation:SetDuration(FADE_OUT_TIME)

    local function OnAnimationStopped(animation, animationControl)
        self.scaleUpAnimationPool:ReleaseObject(animation:GetTimeline().key)
        animationControl:SetScale(1)
    end
    self.scaleUpAnimationPool = ZO_AnimationPool:New("MapPOIPinScaleUp")
    self.scaleUpAnimationPool:SetCustomFactoryBehavior(function(timeline)
        timeline:GetFirstAnimation():SetHandler("OnStop", OnAnimationStopped)
    end)

    local KEYBOARD_FONTS =
    {
        {
            font = "ZoFontGameLargeBoldShadow",
            lineLimit = 2,
        },
    }

    local GAMEPAD_FONTS =
    {
        {
            font = "ZoFontGamepad34",
            lineLimit = 1,
        },
        {
            font = "ZoFontGamepad27",
            lineLimit = 2,
        },
    }
    ZO_PlatformStyleFontAdjustingWrapLabel_OnInitialized(self.mapNameLabel, KEYBOARD_FONTS, GAMEPAD_FONTS, TEXT_WRAP_MODE_ELLIPSIS)

    ZO_PlatformStyle:New(function(...) self:UpdatePlatformStyles(...) end)

    self:RegisterForEvents()
end

do
    local FADE_IN_TIME = 500
    local FADE_OUT_TIME = 500
    local g_doIconIn = false

    function ZO_Minimap:RegisterForEvents()
        local function AcquireScaleUpAnimation()
            local animation, key = self.scaleUpAnimationPool:AcquireObject()
            animation.key = key
            return animation
        end

        local function TryPlayingAnimationOnSinglePOI(zoneIndex, poiIndex, pinType)
            local animation = AcquireScaleUpAnimation()
            if not StartMapPinAnimation(animation, PIN_ANIMATION_TARGET_MAP_AND_GUTTER, CT_MAPDISPLAY, pinType, zoneIndex - 1, poiIndex - 1) then
                self.scaleUpAnimationPool:ReleaseObject(animation.key)
            end
        end

        local function PlayPOIPinScaleUp()
            local zoneIndex, poiIndex = GetCurrentSubZonePOIIndices()
            TryPlayingAnimationOnSinglePOI(zoneIndex, poiIndex, MAP_PIN_TYPE_POI_SEEN)
            TryPlayingAnimationOnSinglePOI(zoneIndex, poiIndex, MAP_PIN_TYPE_POI_COMPLETE)
        end

        local function OnMapNameFadeOutComplete()
            self:UpdateMapName()
            self.mapNameAnimation:FadeIn(0, FADE_IN_TIME, ZO_ALPHA_ANIMATION_OPTION_FORCE_ALPHA)
            if g_doIconIn then
                self.poiIconAnimation:FadeIn(0, FADE_OUT_TIME, ZO_ALPHA_ANIMATION_OPTION_USE_CURRENT_ALPHA, function() self.poiIcon:SetAlpha(1) end)
                self.iconScaleDownTimeline:PlayFromStart()
            end
        end

        local function OnZoneChanged(eventCode)
            self.mapNameAnimation:FadeOut(0, FADE_OUT_TIME, ZO_ALPHA_ANIMATION_OPTION_FORCE_ALPHA, OnMapNameFadeOutComplete)

            local hadPOIIcon = self.inPOI
            self:UpdateInPOI()
            local hasPOIIcon = self.inPOI
            g_doIconIn = false

            self.poiIconAnimation:Stop()

            if hadPOIIcon then
                if hasPOIIcon then
                    --in anim
                    g_doIconIn = true
                    PlayPOIPinScaleUp()
                else
                    --out anim
                    self.poiIconAnimation:FadeOut(0, FADE_OUT_TIME, ZO_ALPHA_ANIMATION_OPTION_USE_CURRENT_ALPHA, function() self.poiIcon:SetAlpha(0) end)
                end
            else
                if hasPOIIcon then
                    --in anim
                    g_doIconIn = true
                    PlayPOIPinScaleUp()
                else
                    --nothing
                end
            end
        end

        --TODO Minimap: Investigate what this function is supposed to be doing. It currently does not work
        local function OnPOIUpdated(eventCode, zoneIndex, poiIndex)
            if zoneIndex == g_zoneIndex and poiIndex == g_POIIndex then
                local _, _, _, icon = GetPOIMapInfo(zoneIndex, poiIndex)
                self.poiIcon:SetTexture(icon)
            end
        end

        local function OnLoadedIntoZone()
            self:UpdateMapName()
            self:ZoomToZone()
        end

        local function OnMapChanged()
            self:ZoomToZone()
        end

        EVENT_MANAGER:RegisterForEvent("ZO_Minimap", EVENT_ZONE_CHANGED, OnZoneChanged)
        EVENT_MANAGER:RegisterForEvent("ZO_Minimap", EVENT_POI_UPDATED, OnPOIUpdated)
        EVENT_MANAGER:RegisterForEvent("ZO_Minimap", EVENT_PLAYER_TELEPORTED_LOCALLY, OnLoadedIntoZone)
        EVENT_MANAGER:RegisterForEvent("ZO_Minimap", EVENT_PLAYER_ACTIVATED, OnLoadedIntoZone)

        -- TODO Minimap: Rework this so it isn't being called every frame
        self.control:SetHandler("OnUpdate", OnMapChanged)
    end
end

function ZO_Minimap:UpdatePlatformStyles()
    ZO_ApplyPlatformTemplateToControl(self.control, "ZO_Minimap_TopLevel")
end

function ZO_Minimap:OnShowing()
    self:UpdateInPOI()
    self:UpdateMapName()
    self:ZoomToZone()

    if self.inPOI then
        self.poiIcon:SetAlpha(1)
    else
        self.poiIcon:SetAlpha(0)
    end
end

function ZO_Minimap:GetControl()
    return self.control
end

function ZO_Minimap:UpdateInPOI()
    self.zoneIndex, self.POIIndex = GetCurrentSubZonePOIIndices()
    self.inPOI = self.zoneIndex ~= nil
end

function ZO_Minimap:UpdateMapName()
    self.mapNameLabel:SetText(zo_strformat(GetString(SI_MINIMAP_AREA_NAME), GetPlayerLocationName()))
    local zoneIndex, poiIndex = GetCurrentSubZonePOIIndices()
    if zoneIndex then
        local _, _, _, icon = GetPOIMapInfo(zoneIndex, poiIndex)
        self.poiIcon:SetTexture(icon)
    end
end

function ZO_Minimap:ZoomToZone()
    local zoom
    if ShouldPlayerMinimapBeZoomedIn() then
        zoom = 0.5
    else
        zoom = 1.5
    end
    self.mapDisplay:SetZoom(zoom)
end

function ZO_Minimap:Zoom(zoomDelta)
    if self.mapDisplay then
        local zoom = self.mapDisplay:GetZoom()

        -- 10% zoom change by default
        -- 25% zoom change if shift pressed
        -- 100% zoom change if ctrl pressed

        if IsControlKeyDown() then
            zoom = (zoomDelta > 0) and 1 or 0
        else
            if IsShiftKeyDown() then
                zoomDelta = zoomDelta * 2.5
            end

            --TODO Minimap: Work out final numbers with design
            zoom = zo_clamp(zoom + zoomDelta, 0, 2)
        end

        self.mapDisplay:SetZoom(zoom)
    end
end

function ZO_Minimap:MouseDown(button, ctrl, alt, shift)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        local x, y = NormalizeMousePositionToControl(self.mapDisplay)

        if shift and not alt and not ctrl then
            PingMap(MAP_PIN_TYPE_RALLY_POINT, MAP_TYPE_PLAYER_CENTERED, x, y, self.mapDisplay)
        elseif not shift and not alt and ctrl then
            PingMap(MAP_PIN_TYPE_PING, MAP_TYPE_PLAYER_CENTERED, x, y, self.mapDisplay)
        end
    end
end

function ZO_Minimap:MapNameMouseEnter()
    ZO_Tooltips_ShowTruncatedTextTooltip(self.mapNameLabel)
end

function ZO_Minimap:MapNameMouseExit()
    ZO_Tooltips_HideTruncatedTextTooltip()
end

function ZO_Minimap:IsVisible()
    return self.fragment:IsShowing()
end

function ZO_Minimap:IsEnabled()
    return GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_MINIMAP)
end

function ZO_Minimap:IsUsingDefaultAnchor(isGamepadPreferredMode)
    local isUsingDefault
    if isGamepadPreferredMode then
        isUsingDefault = self.gamepadElement:IsUsingDefaultAnchor()
    else
        isUsingDefault = self.keyboardElement:IsUsingDefaultAnchor()
    end

    return isUsingDefault
end

function ZO_Minimap:GetGamepadElement()
    return self.gamepadElement
end

function ZO_Minimap:GetKeyboardElement()
    return self.keyboardElement
end

function ZO_Minimap:RefreshEnabled()
    local shouldShow = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SHOW_MINIMAP)
    self.fragment:SetHiddenForReason("Setting", not shouldShow)
end

function ZO_Minimap.OnControlInitialized(control)
    MINIMAP = ZO_Minimap:New(control)
end