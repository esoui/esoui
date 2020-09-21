local g_mapTileManager
local g_mapPinManager
local g_mapLocationManager
local g_mouseoverMapBlobManager
local g_keepNetworkManager

local g_ownsTooltip = false
local g_playerChoseCurrentMap = false
local g_resizingMap = false
local g_resizeIsWidthDriven
local g_savedVars
local g_fastTravelNodeIndex = nil
local g_queryType = BGQUERY_UNKNOWN
local g_campaignId = 0
local g_pendingKeepInfo
local g_keybindStrips = {}
local g_mapRefresh
local g_gamepadMode = false
local g_interactKeybindForceHidden = false
local g_questPingData = nil

--- The list of locals was at the absolute size limit of what Lua can handle
--- (any more and it was erroring with "too many registers" and "too complex".)
--- I put all the local constants in a single table to prevent this.
local CONSTANTS =
{
    MAP_HEIGHT = 690,
    MAP_WIDTH = 690,
    MAP_MIN_SIZE = 200,
    KEYBOARD_MAP_PADDING_Y_PIXELS = 30,
    GAMEPAD_MAP_PADDING_Y_PIXELS = 75,
    CENTER_OFFSET_Y_PIXELS = 9,
    GAMEPAD_CENTER_OFFSET_Y_PIXELS = -10,
    MAIN_MENU_AREA_Y = 120,
    MAP_INFO_WIDTH = 425,
    ZOOM_DIRECTION_IN = 1,
    ZOOM_DIRECTION_OUT = 2,

    WORLDMAP_SIZE_SMALL_WINDOW_SIZE = 550,
    WORLDMAP_RESIZE_WIDTH_DRIVEN = true,
    WORLDMAP_RESIZE_HEIGHT_DRIVEN = false,

    WORLDMAP_SIZE_FULLSCREEN = 1,
    WORLDMAP_SIZE_SMALL = 2,
    
    GAMEPAD_TOOLTIP_ID = 1,

    HISTORY_SLIDER_RANGE = 100,
    DRAG_START_DIST_SQ = 10 * 10,

    -- times are in seconds
    PIN_UPDATE_DELAY          = .04,   -- Delay for updating pin positions and rotations for player and group members.
    MAP_REFRESH_UPDATE_DELAY  = 1,     -- Delay between checking to see if the map needs to change based on the player's current location

    ALLIANCE_TO_RESTRICTED_PIN_TYPE = {
        [ALLIANCE_ALDMERI_DOMINION] = MAP_PIN_TYPE_RESTRICTED_LINK_ALDMERI_DOMINION,
        [ALLIANCE_EBONHEART_PACT] = MAP_PIN_TYPE_RESTRICTED_LINK_EBONHEART_PACT,
        [ALLIANCE_DAGGERFALL_COVENANT] = MAP_PIN_TYPE_RESTRICTED_LINK_DAGGERFALL_COVENANT,
    },

    KEYBOARD_HEADER_STYLE = {
        NAME_OFFSET_Y = 10,
        NAME_FONT = "ZoFontAnnounceMessage",
        NAME_MODIFY_STYLE = MODIFY_TEXT_TYPE_NONE,
        DESCRIPTION_OFFSET_Y = 2,
        DESCRIPTION_FONT = "ZoFontGameOutline",
        DESCRIPTION_MODIFY_STYLE = MODIFY_TEXT_TYPE_NONE,
    },

    GAMEPAD_HEADER_STYLE = {
        NAME_OFFSET_Y = 44,
        NAME_FONT = "ZoFontGamepadBold34",
        NAME_MODIFY_STYLE = MODIFY_TEXT_TYPE_UPPERCASE,
        DESCRIPTION_OFFSET_Y = 8,
        DESCRIPTION_FONT = "ZoFontGamepad34",
        DESCRIPTION_MODIFY_STYLE = MODIFY_TEXT_TYPE_NONE,
    },
}

-- To properly contain the actual map, the worldmap window needs to compensate for these offsets

--Padding is the total space in the window not occupied by the map
local MAP_CONTAINER_LAYOUT =
{
    [CONSTANTS.WORLDMAP_SIZE_SMALL] =
    {
        --left edge, right edge
        paddingX = 4 + 4,
        --top edge, title bar, buttons bar, bot edge
        paddingY = 4 + 26 + 36 + 4,
        offsetX = 4,
        offsetY = 30,
        titleBarHeight = 26,
    },
    [CONSTANTS.WORLDMAP_SIZE_FULLSCREEN] =
    {
        paddingX = 0,
        paddingY = 0,
        offsetX = 0,
        offsetY = 0,
    },
}

local function GetInformationTooltip(isGamepadMode)
    if isGamepadMode then
        return ZO_MapLocationTooltip_Gamepad
    else
        return InformationTooltip
    end
end

local function GetKeepTooltip(isGamepadMode)
    if isGamepadMode then
        return ZO_MapLocationTooltip_Gamepad
    else
        return ZO_KeepTooltip
    end
end

local function GetMapLocationTooltip(isGamepadMode)
    if isGamepadMode then
        return ZO_MapLocationTooltip_Gamepad
    else
        return ZO_MapLocationTooltip
    end
end

local function GetPlatformInformationTooltip()
    return GetInformationTooltip(IsInGamepadPreferredMode())
end

local function GetPlatformKeepTooltip()
    return GetKeepTooltip(IsInGamepadPreferredMode())
end

local function GetPlatformMapLocationTooltip()
    return GetMapLocationTooltip(IsInGamepadPreferredMode())
end

local g_mapOverflowX = 0
local g_mapOverflowY = 0
local g_mapOverflowMaxX = 0
local g_mapOverflowMaxY = 0
local g_mapScale = 1

local g_dataRegistration
local g_cyrodiilMapIndex
local g_imperialCityMapIndex

local g_mapDragX
local g_mapDragY
local g_dragging = false
local g_mapPanAndZoom

local g_pinUpdateTime = nil
local g_refreshUpdateTime = nil
local g_activeGroupPins = {}
local g_objectiveMovingPins = {}
local g_nextRespawnTimeMS = 0

MAP_MODE_SMALL_CUSTOM = 1
MAP_MODE_LARGE_CUSTOM = 2
MAP_MODE_KEEP_TRAVEL = 3
MAP_MODE_FAST_TRAVEL = 4
MAP_MODE_AVA_RESPAWN = 5
MAP_MODE_AVA_KEEP_RECALL = 6
MAP_MODE_DIG_SITES = 7

local MAP_TRANSIENT_MODES =
{
    [MAP_MODE_SMALL_CUSTOM] = {},
    [MAP_MODE_LARGE_CUSTOM] = {},
}

local MAP_MODE_CHANGE_RESTRICTIONS =
{
    [MAP_MODE_KEEP_TRAVEL] =
    {
        disableMapChanging = true,
    },
    [MAP_MODE_AVA_RESPAWN] =
    {
        restrictedCyrodiilImperialCityMapChanging = true,
    },
    [MAP_MODE_AVA_KEEP_RECALL] =
    {
        disableMapChanging = true,
    },
    [MAP_MODE_DIG_SITES] =
    {
        disableMapChanging = true,
    },
}

local g_enableCampaignHistory = false
local g_historyPercent = 1.0

local function ShouldUseHistoryPercent()
    if g_enableCampaignHistory == false then
        return false
    end

    local modeData = WORLD_MAP_MANAGER:GetModeData()
    return modeData.allowHistory == nil or modeData.allowHistory == true
end

function ZO_WorldMap_GetHistoryPercentToUse()
    if ShouldUseHistoryPercent() then
        return g_historyPercent
    else
        return 1.0
    end
end

local function IsShowingCosmicMap()
    return GetMapType() == MAPTYPE_COSMIC
end

function ZO_WorldMap_IsNormalizedPointInsideMapBounds(x, y)
    -- At some point this could take a size as well to determine if an icon/pin would hang off the edge of the map, even though the center of the pin is inside the map.

    -- NOTE: This will NEVER show a point on the edge, assuming that icons displayed there would always hang outside the map.
    return x > 0 and x < 1 and y > 0 and y < 1
end

local function NormalizePreferredMousePositionToMap()
    if IsInGamepadPreferredMode() then
        local x, y = ZO_WorldMapScroll:GetCenter()
        return NormalizePointToControl(x, y, ZO_WorldMapContainer)
    else
        return NormalizeMousePositionToControl(ZO_WorldMapContainer)
    end
end

local function IsMouseOverMap()
    -- WORLD_MAP_AUTO_NAVIGATION_OVERLAY_FRAGMENT will eat all the mouse input, so the mouse can't be over the map
    if not WORLD_MAP_AUTO_NAVIGATION_OVERLAY_FRAGMENT:IsShowing() then
        if IsInGamepadPreferredMode() then
            return SCENE_MANAGER:IsShowing("gamepad_worldMap")
        else
            return not ZO_WorldMapScroll:IsHidden() and MouseIsOver(ZO_WorldMapScroll) and SCENE_MANAGER:IsShowing("worldMap")
        end
    end

    return false
end

--[[
    Pin management...
--]]

--[[
    Map Tile Pool Object.  Creates the base tiles for the world map...controls must be able to be indexed by tile
--]]

local ZO_WorldMapTiles = ZO_Object:Subclass()

function ZO_WorldMapTiles:New(...)
    local tiles = ZO_Object.New(self)
    tiles:Initialize(...)
    return tiles
end

function ZO_WorldMapTiles:Initialize(parent)
    self.parent = parent
    self.indexToTile = {}
end

function ZO_WorldMapTiles:GetTile(i)
    return self.indexToTile[i]
end

function ZO_WorldMapTiles:GetOrCreateTile(i)
    local tile = self:GetTile(i)
    if tile == nil then
        tile = CreateControlFromVirtual(self.parent:GetName(), self.parent, "ZO_MapTile", i)
        self.indexToTile[i] = tile
    end
    return tile
end

function ZO_WorldMapTiles:ReleaseTiles()
    for k, tile in ipairs(self.indexToTile) do
        tile:SetHidden(true)
    end
end

function ZO_WorldMapTiles:UpdateMapData()
    local numHorizontalTiles, numVerticalTiles = GetMapNumTiles()

    self.horizontalTiles = numHorizontalTiles
    self.verticalTiles = numVerticalTiles
end

function ZO_WorldMapTiles:LayoutTiles()
    if self.horizontalTiles == nil then
        self:UpdateMapData()
    end

    local tileWidth = CONSTANTS.MAP_WIDTH / self.horizontalTiles
    local tileHeight = CONSTANTS.MAP_HEIGHT / self.verticalTiles

    local numHorizontalTiles, numVerticalTiles = self.horizontalTiles, self.verticalTiles
    self:ReleaseTiles()

    for i = 1, (numHorizontalTiles * numVerticalTiles) do
        local tileControl = self:GetOrCreateTile(i)
        tileControl:SetHidden(false)
        tileControl:SetDimensions(tileWidth, tileHeight)
        tileControl:ClearAnchors()
        local xOffset = zo_mod(i - 1, numHorizontalTiles) * tileWidth
        local yOffset = zo_floor((i - 1) / numHorizontalTiles) * tileHeight
        tileControl:SetAnchor(TOPLEFT, ZO_WorldMapContainer, TOPLEFT, xOffset, yOffset)
    end
end

function ZO_WorldMapTiles:UpdateTextures()
    self:UpdateMapData()
    self:LayoutTiles()

    local totalTiles = self.horizontalTiles * self.verticalTiles
    for i = 1, totalTiles do
        local tileControl = self:GetTile(i)
        tileControl:SetTexture(GetMapTileTexture(i))
        tileControl:SetHidden(false)
    end

    for i = totalTiles + 1, #self.indexToTile do
        local tileControl = self:GetTile(i)
        tileControl:SetHidden(true)
    end
end

local InformationTooltipMixin = {}

function InformationTooltipMixin:AddDivider()
    -- Does nothing on non-gamepad version
end

function InformationTooltipMixin:AddMoney(tooltip, cost, text, hasEnough)
    ZO_ItemTooltip_AddMoney(tooltip, cost, text, hasEnough)
end

function ZO_WorldMap_GetWayshrineTooltipCollectibleLockedText(pin)
    --Don't call this function if you don't already know it's locked.
    --Otherwise we'd run superflous code to return useless information
    assert(pin:IsLockedByLinkedCollectible())

    local collectibleId = GetFastTravelNodeLinkedCollectibleId(pin:GetFastTravelNodeIndex())
    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)
    local stringId = collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_CHAPTER) and SI_TOOLTIP_POI_LINKED_CHAPTER_COLLECTIBLE_LOCKED or SI_TOOLTIP_POI_LINKED_DLC_COLLECTIBLE_LOCKED
    return zo_strformat(stringId, collectibleData:GetName(), collectibleData:GetCategoryData():GetName())
end

function InformationTooltipMixin:AppendWayshrineTooltip(pin)
    local nodeIndex = pin:GetFastTravelNodeIndex()
    local informationTooltip = GetPlatformInformationTooltip()
    local _, name, _, _, _, _, poiType = GetFastTravelNodeInfo(nodeIndex)
    informationTooltip:AddLine(zo_strformat(SI_WORLD_MAP_LOCATION_NAME, name), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())

    local isCurrentLoc = g_fastTravelNodeIndex == nodeIndex
    local isOutboundOnly, outboundOnlyErrorStringId = GetFastTravelNodeOutboundOnlyInfo(nodeIndex)
    local nodeIsHousePreview = poiType == POI_TYPE_HOUSE and not HasCompletedFastTravelNodePOI(nodeIndex)
    if isCurrentLoc then --NO CLICK: Can't travel to origin
        informationTooltip:AddLine(GetString(SI_TOOLTIP_WAYSHRINE_CURRENT_LOC), "", ZO_HIGHLIGHT_TEXT:UnpackRGB())
    elseif g_fastTravelNodeIndex == nil and IsInCampaign() then --NO CLICK: Can't recall while inside AvA zone
        informationTooltip:AddLine(GetString(SI_TOOLTIP_WAYSHRINE_CANT_RECALL_AVA), "", ZO_ERROR_COLOR:UnpackRGB())
    elseif isOutboundOnly then --NO CLICK: Can't travel to this wayshrine, only from it
        local message = GetErrorString(outboundOnlyErrorStringId)
        informationTooltip:AddLine(message, "", ZO_ERROR_COLOR:UnpackRGB())
    elseif not CanLeaveCurrentLocationViaTeleport() then --NO CLICK: Current Zone or Subzone restricts jumping
        local cantLeaveStringId
        if IsInOutlawZone() then
            cantLeaveStringId = SI_TOOLTIP_WAYSHRINE_CANT_RECALL_OUTLAW_REFUGE
        else
            cantLeaveStringId = SI_TOOLTIP_WAYSHRINE_CANT_RECALL_FROM_LOCATION
        end
        informationTooltip:AddLine(GetString(cantLeaveStringId), "", ZO_ERROR_COLOR:UnpackRGB())
    elseif pin:IsLockedByLinkedCollectible() then --CLICK: Open the store
        local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_MARKET_COLORS, MARKET_COLORS_ON_SALE)
        local SET_TO_FULL_SIZE = true
        informationTooltip:AddLine(ZO_WorldMap_GetWayshrineTooltipCollectibleLockedText(pin), "", r, g, b, CENTER, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, SET_TO_FULL_SIZE)

        if pin:GetLinkedCollectibleType() == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
            informationTooltip:AddLine(GetString(SI_TOOLTIP_WAYSHRINE_CLICK_TO_UPGRADE_CHAPTER), "", ZO_HIGHLIGHT_TEXT:UnpackRGB())
        else
            informationTooltip:AddLine(GetString(SI_TOOLTIP_WAYSHRINE_CLICK_TO_OPEN_CROWN_STORE), "", ZO_HIGHLIGHT_TEXT:UnpackRGB())
        end
    elseif IsUnitDead("player") then --NO CLICK: Dead
        informationTooltip:AddLine(GetString(SI_TOOLTIP_WAYSHRINE_CANT_RECALL_WHEN_DEAD), "", ZO_ERROR_COLOR:UnpackRGB())
    elseif g_fastTravelNodeIndex == nil then --Recall
        local _, premiumTimeLeft = GetRecallCooldown()
        if premiumTimeLeft == 0 then --CLICK: Recall
            local text = GetString(nodeIsHousePreview and SI_TOOLTIP_WAYSHRINE_CLICK_TO_PREVIEW_HOUSE or SI_TOOLTIP_WAYSHRINE_CLICK_TO_RECALL)
            informationTooltip:AddLine(text, "", ZO_HIGHLIGHT_TEXT:UnpackRGB())

            local cost = GetRecallCost(nodeIndex)
            if cost > 0 then
                local currency = GetRecallCurrency(nodeIndex)
                local notEnoughCurrency = cost > GetCurrencyAmount(currency, CURRENCY_LOCATION_CHARACTER)
                informationTooltip:AddMoney(informationTooltip, cost, SI_TOOLTIP_RECALL_COST, notEnoughCurrency)
            end
        else --NO CLICK: Waiting on cooldown
            local cooldownText = zo_strformat(SI_TOOLTIP_WAYSHRINE_RECALL_COOLDOWN, ZO_FormatTimeMilliseconds(premiumTimeLeft, TIME_FORMAT_STYLE_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS))
            informationTooltip:AddLine(cooldownText, "", ZO_HIGHLIGHT_TEXT:UnpackRGB())
        end
    else --CLICK: Fast Travel
        local text = GetString(nodeIsHousePreview and SI_TOOLTIP_WAYSHRINE_CLICK_TO_PREVIEW_HOUSE or SI_TOOLTIP_WAYSHRINE_CLICK_TO_FAST_TRAVEL)
        informationTooltip:AddLine(text, "", ZO_HIGHLIGHT_TEXT:UnpackRGB())
    end
end

function InformationTooltipMixin:AppendSuggestionActivity(pin)
    local shortDescription = pin:GetShortDescription()

    if shortDescription then
        GetPlatformInformationTooltip():AddLine(shortDescription, "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
    end
end

function ZO_WorldMap_GetTooltipForMode(mode)
    if mode == ZO_MAP_TOOLTIP_MODE.INFORMATION then
        return GetPlatformInformationTooltip()
    elseif mode == ZO_MAP_TOOLTIP_MODE.KEEP then
        return GetPlatformKeepTooltip()
    elseif mode == ZO_MAP_TOOLTIP_MODE.MAP_LOCATION then
        return GetPlatformMapLocationTooltip()
    else
        assert(false)
    end
end
do
    local KEYBOARD_DUNGEON_BUTTON_TEXTURES =
    {
        UP = {
            NORMAL = "EsoUI/Art/WorldMap/mapNav_upArrow_up.dds",
            PRESSED = "EsoUI/Art/WorldMap/mapNav_upArrow_down.dds",
            MOUSEOVER = "EsoUI/Art/Buttons/ESO_buttonLarge_mouseOver.dds",
            DISABLED = "EsoUI/Art/WorldMap/mapNav_upArrow_disabled.dds",
        },
        DOWN = {
            NORMAL = "EsoUI/Art/WorldMap/mapNav_downArrow_up.dds",
            PRESSED = "EsoUI/Art/WorldMap/mapNav_downArrow_down.dds",
            MOUSEOVER = "EsoUI/Art/Buttons/ESO_buttonLarge_mouseOver.dds",
            DISABLED = "EsoUI/Art/WorldMap/mapNav_downArrow_disabled.dds",
        },
    }

    local GAMEPAD_DUNGEON_BUTTON_TEXTURES = {
        UP = {
            KEY_CODE = KEY_GAMEPAD_LEFT_SHOULDER,
        },
        DOWN = {
            KEY_CODE = KEY_GAMEPAD_RIGHT_SHOULDER,
        },
    }

    local function SetButtonTextures(button, textures)
        if textures.KEY_CODE then
            button:SetKeyCode(textures.KEY_CODE)
        else
            button:SetKeyCode(nil)
            button:SetNormalTexture(textures.NORMAL)
            button:SetPressedTexture(textures.PRESSED)
            button:SetMouseOverTexture(textures.MOUSEOVER)
            button:SetDisabledTexture(textures.DISABLED)
        end
    end

    SetupWorldMap = function()
        local buttonTextures
        if IsInGamepadPreferredMode() then
            buttonTextures = GAMEPAD_DUNGEON_BUTTON_TEXTURES
            g_gamepadMode = true
        else
            buttonTextures = KEYBOARD_DUNGEON_BUTTON_TEXTURES
            g_gamepadMode = false
        end

        local headerStyle
        if IsInGamepadPreferredMode() then
            headerStyle = CONSTANTS.GAMEPAD_HEADER_STYLE
        else
            headerStyle = CONSTANTS.KEYBOARD_HEADER_STYLE
        end

        ZO_WorldMapMouseoverName:ClearAnchors()
        ZO_WorldMapMouseoverName:SetAnchor(TOPLEFT, ZO_WorldMapScroll, TOPLEFT, 0, headerStyle.NAME_OFFSET_Y)
        ZO_WorldMapMouseoverName:SetAnchor(TOPRIGHT, ZO_WorldMapScroll, TOPRIGHT, 0, headerStyle.NAME_OFFSET_Y)
        ZO_WorldMapMouseoverName:SetFont(headerStyle.NAME_FONT)
        ZO_WorldMapMouseoverName:SetModifyTextType(headerStyle.NAME_MODIFY_STYLE)

        ZO_WorldMapMouseOverDescription:ClearAnchors()
        ZO_WorldMapMouseOverDescription:SetAnchor(TOPLEFT, ZO_WorldMapMouseoverName, BOTTOMLEFT, 0, headerStyle.DESCRIPTION_OFFSET_Y)
        ZO_WorldMapMouseOverDescription:SetAnchor(TOPRIGHT, ZO_WorldMapMouseoverName, BOTTOMRIGHT, 0, headerStyle.DESCRIPTION_OFFSET_Y)
        ZO_WorldMapMouseOverDescription:SetFont(headerStyle.DESCRIPTION_FONT)
        ZO_WorldMapMouseOverDescription:SetModifyTextType(headerStyle.DESCRIPTION_MODIFY_STYLE)

        SetButtonTextures(ZO_WorldMapButtonsFloorsUp, buttonTextures.UP)
        SetButtonTextures(ZO_WorldMapButtonsFloorsDown, buttonTextures.DOWN)
        SetButtonTextures(ZO_WorldMapButtonsLevelsUp, buttonTextures.UP)
        SetButtonTextures(ZO_WorldMapButtonsLevelsDown, buttonTextures.DOWN)

        ApplyTemplateToControl(ZO_WorldMapMapFrame, ZO_GetPlatformTemplate("ZO_WorldMapFrame"))
        ApplyTemplateToControl(ZO_WorldMapButtonsFloors, ZO_GetPlatformTemplate("ZO_DungeonFloorNavigation"))

        WORLD_MAP_MANAGER:RefreshMapFrameAnchor()
    end
end

local tooltipOrder =
{
    ZO_MAP_TOOLTIP_MODE.KEEP, ZO_MAP_TOOLTIP_MODE.MAP_LOCATION, ZO_MAP_TOOLTIP_MODE.INFORMATION
}

--[[
    Sticky Pin Utilities for gamepad map control (utilized by mouse over list construction)
--]]

local WorldMapStickyPin = ZO_Object:Subclass()
local g_stickyPin

function WorldMapStickyPin:New(...)
    local stickyPin = ZO_Object.New(self)
    stickyPin:Initialize(...)
    return stickyPin
end

function WorldMapStickyPin:Initialize()
    self.BASE_STICKY_MIN_DISTANCE_UNITS = 50
    self.BASE_STICKY_MAX_DISTANCE_UNITS = 75

    self.m_thresholdDistanceSq = self.BASE_STICKY_MIN_DISTANCE_UNITS * self.BASE_STICKY_MIN_DISTANCE_UNITS
    self.m_enabled = true
end

function WorldMapStickyPin:SetEnabled(enabled)
    self.m_enabled = enabled
end

function WorldMapStickyPin:UpdateThresholdDistance(currentNormalizedZoom)
    local stickyDistance = zo_lerp(self.BASE_STICKY_MIN_DISTANCE_UNITS, self.BASE_STICKY_MAX_DISTANCE_UNITS, currentNormalizedZoom)
    self.m_thresholdDistanceSq = stickyDistance * stickyDistance
end

function WorldMapStickyPin:SetStickyPin(pin)
    self.m_pin = pin
end

function WorldMapStickyPin:GetStickyPin()
    return self.m_pin
end

function WorldMapStickyPin:ClearStickyPin(mover)
    if self.m_movingToPin and self:GetStickyPin() then
        mover:ClearTargetOffset()
    end

    self:SetStickyPin(nil)
end

function WorldMapStickyPin:MoveToStickyPin(mover)
    local movingToPin = self:GetStickyPin()
    if movingToPin then
        self.m_movingToPin = movingToPin
        local useCurrentZoom = true
        mover:PanToPin(movingToPin, useCurrentZoom)
    end
end

function WorldMapStickyPin:SetStickyPinFromNearestCandidate()
    self:SetStickyPin(self.m_nearestCandidate)
end

function WorldMapStickyPin:ClearNearestCandidate()
    self.m_nearestCandidate = nil
    self.m_nearestCandidateDistanceSq = 0
end

function WorldMapStickyPin:ConsiderPin(pin, x, y)
    if self.m_enabled then
        local pinGroup = pin:GetPinGroup()
        if pinGroup == nil or WORLD_MAP_MANAGER:AreStickyPinsEnabledForPinGroup(pinGroup) then
            local distanceSq = pin:DistanceToSq(x, y)
            if distanceSq < self.m_thresholdDistanceSq then
                if not self.m_nearestCandidate or distanceSq < self.m_nearestCandidateDistanceSq then
                    self.m_nearestCandidate = pin
                    self.m_nearestCandidateDistanceSq = distanceSq
                end
            end
        end
    end
end

--[[
    Utilities to build lists of pins the mouse is currently over and was previously over so the world map knows how
    to properly call the OnMouseExit and OnMouseEnter events on the pins.
--]]
local currentMouseOverPins = {}
local previousMouseOverPins = {}
local mouseExitPins = {}
local mousedOverPinWasReset = false
local invalidateTooltip = false

function ZO_WorldMap_InvalidateTooltip()
    invalidateTooltip = true
end

local function ResetMouseOverPins()
    currentMouseOverPins = {}
    previousMouseOverPins = {}
end

local function BuildMouseOverPinLists(cursorPositionX, cursorPositionY)
    -- Determine if the mouse is even over the world map
    local mouseOverWorldMap = IsMouseOverMap()

    -- Swap lists
    previousMouseOverPins, currentMouseOverPins = currentMouseOverPins, previousMouseOverPins

    -- Update any pins that were moused over in the current list that may no longer be in the active pins
    for pin, mousedOver in pairs(currentMouseOverPins) do
        if mousedOver then
            currentMouseOverPins[pin] = mouseOverWorldMap and pin:MouseIsOver(cursorPositionX, cursorPositionY)
        end
    end

    -- Update active list and determine the sticky pin!
    g_stickyPin:ClearNearestCandidate()

    local pins = g_mapPinManager:GetActiveObjects()
    for k, pin in pairs(pins) do
        local isMouseCurrentlyOverPin = mouseOverWorldMap and pin:MouseIsOver(cursorPositionX, cursorPositionY)
        currentMouseOverPins[pin] = isMouseCurrentlyOverPin
        g_stickyPin:ConsiderPin(pin, cursorPositionX, cursorPositionY)
    end

    g_stickyPin:SetStickyPinFromNearestCandidate()

    -- Determine which pins need to have their mouse enter called and which need to have their mouse exit called.
    -- Return whether or not the lists for current and previous changed so that nothing is updated unecessarily
    local wasPreviouslyMousedOver, doMouseEnter, doMouseExit
    local listsChanged = false
    local needsContinuousTooltipUpdates = false

    for pin, isMousedOver in pairs(currentMouseOverPins) do
        wasPreviouslyMousedOver = previousMouseOverPins[pin]
        doMouseEnter = isMousedOver and not wasPreviouslyMousedOver
        doMouseExit = not isMousedOver and wasPreviouslyMousedOver

        mouseExitPins[pin] = doMouseExit

        listsChanged = listsChanged or doMouseEnter or doMouseExit
        needsContinuousTooltipUpdates = needsContinuousTooltipUpdates or (isMousedOver and pin:NeedsContinuousTooltipUpdates())
    end

    return listsChanged, needsContinuousTooltipUpdates
end

local function DoMouseExitForPin(pin)
    if pin:IsPOI() or pin:IsFastTravelWayShrine() then
        --reset the status to show what part of the map we're over (except if it's the name of this zone)
        if g_mouseoverMapBlobManager.m_currentLocation ~= ZO_WorldMap.zoneName then
            ZO_WorldMapMouseoverName:SetText(zo_strformat(SI_WORLD_MAP_LOCATION_NAME, g_mouseoverMapBlobManager.m_currentLocation))
            ZO_WorldMapMouseoverName.owner = "map"
        else
            ZO_WorldMapMouseoverName:SetText("")
            ZO_WorldMapMouseoverName.owner = ""
        end

        ZO_WorldMapMouseOverDescription:SetText("")
    end

    local pinType = pin:GetPinType()
    g_keybindStrips.mouseover:DoMouseExitForPinType(pinType)
    g_keybindStrips.gamepad:DoMouseExitForPinType(pinType)
end

local function MouseOverPins_OnPinReset(pin)
    if currentMouseOverPins[pin] then
        mousedOverPinWasReset = true
        DoMouseExitForPin(pin)
    end
    currentMouseOverPins[pin] = nil
    previousMouseOverPins[pin] = nil

    --If we are showing a menu to choose a pin action and one of those pins is removed from the map then we need to handle that here
    WORLD_MAP_CHOICE_DIALOG_GAMEPAD:OnPinRemovedFromMap(pin)
    if ZO_MapPin.pinsInKeyboardMapChoiceDialog and ZO_MapPin.pinsInKeyboardMapChoiceDialog[pin] then
        ClearMenu()
    end
end

local usedTooltips = {}

local function HideKeyboardTooltips()
    local NOT_GAMEPAD_MODE = false
    if g_ownsTooltip then
        ClearTooltip(GetInformationTooltip(NOT_GAMEPAD_MODE))
        g_ownsTooltip = false
    end

    GetKeepTooltip(NOT_GAMEPAD_MODE):SetHidden(true)
    ClearTooltip(GetMapLocationTooltip(NOT_GAMEPAD_MODE))
end

local function HideGamepadTooltip()
    local GAMEPAD_MODE = true
    GetMapLocationTooltip(GAMEPAD_MODE):ClearLines()
    SCENE_MANAGER:RemoveFragment(GAMEPAD_WORLD_MAP_TOOLTIP_FRAGMENT)
end

local g_hideTooltipsAt

local function ClearHideTooltipsLater()
    g_hideTooltipsAt = nil
end

local function HideAllTooltipsLater()
    if not g_gamepadMode then
        HideKeyboardTooltips()
        for i = 1, #tooltipOrder do
            usedTooltips[i] = nil
        end
    else
        g_hideTooltipsAt = GetGameTimeMilliseconds() + 1000
    end
end

local function HideAllTooltips()
    if not g_gamepadMode then
        HideKeyboardTooltips()
    else
        HideGamepadTooltip()
    end
    ClearHideTooltipsLater()
    for i = 1, #tooltipOrder do
        usedTooltips[i] = nil
    end
end

local function ShowGamepadTooltip(resetScroll)
    if not IsInGamepadPreferredMode() then return end

    if g_hideTooltipsAt then
        -- If we are in the process of hiding the tooltips then treat it as a fresh tooltip
        ZO_MapLocationTooltip_Gamepad:ClearLines(resetScroll)
        ClearHideTooltipsLater()
    end

    if not usedTooltips[CONSTANTS.GAMEPAD_TOOLTIP_ID] then
        usedTooltips[CONSTANTS.GAMEPAD_TOOLTIP_ID] = true
        SCENE_MANAGER:AddFragment(GAMEPAD_WORLD_MAP_TOOLTIP_FRAGMENT)

        ZO_MapLocationTooltip_Gamepad:ClearLines(resetScroll)
    end


    return ZO_MapLocationTooltip_Gamepad
end

local function GetValueOrExecute(value, ...)
    if type(value) == "function" then
        return value(...)
    end
    return value
end

local function CompareIgnoreNil(first, second)
    if first == second then
        return nil
    elseif first and second then
        return first < second
    elseif first then
        return true
    else
        return false
    end
end

local function GamepadTooltipPinSortFunction(firstPin, secondPin)
    local firstPinType = firstPin and firstPin:GetPinType()
    local secondPinType = secondPin and secondPin:GetPinType()

    -- We don't need to check the types for nil, as if they are nil, the following
    --  infos will get nil, and that will produce the same result.

    local firstTooltipInfo = ZO_MapPin.TOOLTIP_CREATORS[firstPinType]
    local secondTooltipInfo = ZO_MapPin.TOOLTIP_CREATORS[secondPinType]

    -- If either tooltip info is nil, that pin has no tooltip, and we just need
    --  to make sure it sorts to a consistant place.
    if not firstTooltipInfo then
        return false
    elseif not secondTooltipInfo then
        return true
    end

    local firstCategoryId = GetValueOrExecute(firstTooltipInfo.categoryId, firstPin) or GetValueOrExecute(firstTooltipInfo.gamepadCategory, firstPin)
    local secondCategoryId = GetValueOrExecute(secondTooltipInfo.categoryId, secondPin) or GetValueOrExecute(secondTooltipInfo.gamepadCategory, secondPin)

    local idResult = CompareIgnoreNil(firstCategoryId, secondCategoryId)
    if idResult ~= nil then
        return idResult
    end

    local firstCategory = GetValueOrExecute(firstTooltipInfo.gamepadCategory, firstPin)
    local secondCategory = GetValueOrExecute(secondTooltipInfo.gamepadCategory, secondPin)
    idResult = CompareIgnoreNil(firstCategory, secondCategory)
    if idResult ~= nil then
        return idResult
    end

    local firstEntryName = GetValueOrExecute(firstTooltipInfo.entryName, firstPin)
    local secondEntryName = GetValueOrExecute(secondTooltipInfo.entryName, secondPin)
    idResult = CompareIgnoreNil(firstEntryName, secondEntryName)
    if idResult ~= nil then
        return idResult
    end

    return false
end

local function TooltipPinSortFunction(firstPin, secondPin)
    local firstPinType = firstPin and firstPin:GetPinType()
    local secondPinType = secondPin and secondPin:GetPinType()

    -- We don't need to check the types for nil, as if they are nil, the following
    --  infos will get nil, and that will produce the same result.

    local firstTooltipInfo = ZO_MapPin.TOOLTIP_CREATORS[firstPinType]
    local secondTooltipInfo = ZO_MapPin.TOOLTIP_CREATORS[secondPinType]

    -- If either tooltip info is nil, that pin has no tooltip, and we just need
    --  to make sure it sorts to a consistant place.
    if not firstTooltipInfo then
        return false
    elseif not secondTooltipInfo then
        return true
    end

    local firstCategoryId = GetValueOrExecute(firstTooltipInfo.categoryId, firstPin)
    local secondCategoryId = GetValueOrExecute(secondTooltipInfo.categoryId, secondPin)

    local idResult = CompareIgnoreNil(firstCategoryId, secondCategoryId)
    if idResult ~= nil then
        return idResult
    end

    local firstEntryName = GetValueOrExecute(firstTooltipInfo.entryName, firstPin)
    local secondEntryName = GetValueOrExecute(secondTooltipInfo.entryName, secondPin)
    idResult = CompareIgnoreNil(firstEntryName, secondEntryName)
    if idResult ~= nil then
        return idResult
    end

    return false
end

local tooltipMouseOverPins = {}
local foundTooltipMouseOverPins = {}
local function GetTooltipMouseOverPins()
    ZO_ClearNumericallyIndexedTable(tooltipMouseOverPins)
    ZO_ClearNumericallyIndexedTable(foundTooltipMouseOverPins)
    for pin, isMousedOver in pairs(currentMouseOverPins) do
        if pin then
            table.insert(tooltipMouseOverPins, pin)
        end
    end

    return tooltipMouseOverPins
end

local function UpdateMouseOverPins()
    local isInGamepadPreferredMode = SCENE_MANAGER:IsCurrentSceneGamepad()

    local cursorPositionX
    local cursorPositionY
    if isInGamepadPreferredMode then
        cursorPositionX, cursorPositionY = ZO_WorldMapScroll:GetCenter()
    else
        cursorPositionX, cursorPositionY = GetUIMousePosition()
    end

    local mouseOverListChanged, needsContinuousTooltipUpdates = BuildMouseOverPinLists(cursorPositionX, cursorPositionY)
    local needsTooltipUpdate = mouseOverListChanged or mousedOverPinWasReset or needsContinuousTooltipUpdates or invalidateTooltip
    local needsTooltipScrollReset = mouseOverListChanged or mousedOverPinWasReset
    invalidateTooltip = false
    mousedOverPinWasReset = false

    if not needsTooltipUpdate then
        return
    end

    local wasShowingTooltip = ZO_WorldMap_IsTooltipShowing()
    HideAllTooltipsLater()

    -- Iterate over the current pins, using the key as the actual pin to facilitate looking up whether or not it's appropriate to call mouseEnter/mouseExit
    -- for the pins.
    local tooltipMouseOverPins = GetTooltipMouseOverPins()

    -- Do the exit pins first (so that ZO_WorldMapMouseoverName gets cleared then set in the correct order)
    for index, pin in ipairs(tooltipMouseOverPins) do
        if mouseExitPins[pin] then
            DoMouseExitForPin(pin)
        end
    end

    for index, pin in ipairs(tooltipMouseOverPins) do
        local isMousedOver = currentMouseOverPins[pin]

        -- NOTE: Right now we don't need to call the mouse enter handlers, because all custom behavior is part of tooltip generation, so just move on to that step.
        -- Verify that control is still moused over due to OnUpdate/OnShow handler issues (prevents tooltip popping)
        if isMousedOver and pin:MouseIsOver(cursorPositionX, cursorPositionY) then
            table.insert(foundTooltipMouseOverPins, pin)
        else
            pin:SetTargetScale(1)
        end
    end

    if IsInGamepadPreferredMode() then
        table.sort(foundTooltipMouseOverPins, GamepadTooltipPinSortFunction)
    else
        table.sort(foundTooltipMouseOverPins, TooltipPinSortFunction)

        if #foundTooltipMouseOverPins > 0 then
            WORLD_MAP_MANAGER:HidePinPointerBox()
        end
    end

    local MAX_QUEST_PINS = 10
    local currentQuestPins = 0
    local missedQuestPins = 0
    local maxKeepTooltipPinLevel = 0
    local informationTooltipAppendedTo = false
    local lastGamepadCategory = nil
    local informationTooltip = GetPlatformInformationTooltip()

    for index, pin in ipairs(foundTooltipMouseOverPins) do
        local pinType = pin:GetPinType()
        local pinTooltipInfo = ZO_MapPin.TOOLTIP_CREATORS[pinType]

        if pinTooltipInfo then
            local layoutPinTooltip = true
            if pin:IsQuest() then
                if pin:IsAssisted() then
                    --always allow assisted pins through
                elseif currentQuestPins < MAX_QUEST_PINS then
                    currentQuestPins = currentQuestPins + 1
                else
                    layoutPinTooltip = false
                    missedQuestPins = missedQuestPins + 1
                end
            end

            if layoutPinTooltip then
                if not pin:IsAreaPin() or pin:ShowsPinAndArea() then
                    pin:SetTargetScale(1.3)
                end

                local layoutTooltip = true
                local usedTooltip = pinTooltipInfo.tooltip
                if not isInGamepadPreferredMode and usedTooltip == ZO_MAP_TOOLTIP_MODE.KEEP then
                    local pinLevel = pin:GetLevel()
                    if pinLevel > maxKeepTooltipPinLevel then
                        maxKeepTooltipPinLevel = pinLevel
                    else
                        layoutTooltip = false
                    end
                end

                if layoutTooltip and pinTooltipInfo.hasTooltip then
                    layoutTooltip = pinTooltipInfo.hasTooltip(pin)
                end

                if layoutTooltip then
                    if usedTooltip then
                        if not isInGamepadPreferredMode then
                            for i = 1, #tooltipOrder do
                                if tooltipOrder[i] == usedTooltip then
                                    if not usedTooltips[i] then
                                        usedTooltips[i] = true
                                        if usedTooltip == ZO_MAP_TOOLTIP_MODE.KEEP then
                                            GetPlatformKeepTooltip():SetHidden(false)
                                        else
                                            InitializeTooltip(ZO_WorldMap_GetTooltipForMode(usedTooltip), pin:GetControl())
                                        end
                                    end
                                end
                            end
                        else
                            if not ZO_WorldMap_IsWorldMapInfoShowing() and not ZO_WorldMap_IsKeepInfoShowing() then
                                ShowGamepadTooltip(needsTooltipScrollReset)
                            end
                        end
                    end

                    if isInGamepadPreferredMode then
                        local nextCategoryText = GetValueOrExecute(pinTooltipInfo.gamepadCategory, pin)
                        if type(nextCategoryText) == "number" then
                            nextCategoryText = GetString(nextCategoryText)
                        end

                        local nextCategory = nextCategoryText
                        if not nextCategory then
                            nextCategory = pinTooltipInfo.categoryId
                        end

                        local isDifferentCategory = (lastGamepadCategory ~= nextCategory)

                        if nextCategoryText and isDifferentCategory then
                            local categoryIcon = GetValueOrExecute(pinTooltipInfo.gamepadCategoryIcon, pin)
                            local titleStyleName = pinTooltipInfo.gamepadCategoryStyleName
                            titleStyleName = titleStyleName and informationTooltip.tooltip:GetStyle(titleStyleName)

                            local groupSection = informationTooltip.tooltip:AcquireSection(titleStyleName, informationTooltip.tooltip:GetStyle("mapKeepCategorySpacing"))
                            local mapIconTitleStyle = categoryIcon and informationTooltip.tooltip:GetStyle("mapIconTitle") or nil
                            informationTooltip:LayoutGroupHeader(groupSection, categoryIcon, nextCategoryText, titleStyleName, mapIconTitleStyle, informationTooltip.tooltip:GetStyle("mapTitle"))
                            informationTooltip.tooltip:AddSection(groupSection)
                        elseif pinTooltipInfo.gamepadSpacing or isDifferentCategory then
                            local groupSection = informationTooltip.tooltip:AcquireSection(informationTooltip.tooltip:GetStyle("mapKeepCategorySpacing"))
                            informationTooltip.tooltip:AddSectionEvenIfEmpty(groupSection)
                        end

                        lastGamepadCategory = nextCategory
                    end

                    pinTooltipInfo.creator(pin)

                    g_keybindStrips.mouseover:DoMouseEnterForPinType(pinType)
                    g_keybindStrips.gamepad:DoMouseEnterForPinType(pinType)

                    --space out the appended lines in the information tooltip
                    if usedTooltip == ZO_MAP_TOOLTIP_MODE.INFORMATION and not isInGamepadPreferredMode then
                        informationTooltipAppendedTo = true
                        informationTooltip:AddVerticalPadding(5)
                    end
                end
            end
        end
    end

    if missedQuestPins > 0 then
        local text = string.format(zo_strformat(SI_TOOLTIP_MAP_MORE_QUESTS, missedQuestPins))
        if not IsInGamepadPreferredMode() then
            informationTooltip:AddLine(text)
        else
            local lineSection = informationTooltip.tooltip:AcquireSection(informationTooltip.tooltip:GetStyle("mapMoreQuestsContentSection"))
            lineSection:AddLine(text, informationTooltip.tooltip:GetStyle("mapLocationTooltipContentLabel"), informationTooltip.tooltip:GetStyle("gamepadElderScrollTooltipContent"))
            informationTooltip.tooltip:AddSection(lineSection)
        end
    end

    --Remove the last bit of extra padding on the end
    if informationTooltipAppendedTo and not isInGamepadPreferredMode then
        informationTooltip:AddVerticalPadding(-5)
    end

    -- Gamepad handles its own layout
    if not isInGamepadPreferredMode then
        local prevControl = nil
        local placeAbove = GuiMouse:GetTop() > (GuiRoot:GetHeight() / 2)
        local placeLeft = GuiMouse:GetLeft() > (GuiRoot:GetWidth() / 2)
        for i = 1, #tooltipOrder do
            if usedTooltips[i] then
                local tooltip = tooltipOrder[i]
                local tooltipControl = ZO_WorldMap_GetTooltipForMode(tooltip)

                if prevControl then
                    if placeLeft then
                        if placeAbove then
                            tooltipControl:ClearAnchors()
                            tooltipControl:SetAnchor(BOTTOMRIGHT, prevControl, TOPRIGHT, 0, -5)
                        else
                            tooltipControl:ClearAnchors()
                            tooltipControl:SetAnchor(TOPRIGHT, prevControl, BOTTOMRIGHT, 0, 5)
                        end
                    else
                        if placeAbove then
                            tooltipControl:ClearAnchors()
                            tooltipControl:SetAnchor(BOTTOMLEFT, prevControl, TOPLEFT, 0, -5)
                        else
                            tooltipControl:ClearAnchors()
                            tooltipControl:SetAnchor(TOPLEFT, prevControl, BOTTOMLEFT, 0, 5)
                        end
                    end
                else
                    if placeLeft then
                        tooltipControl:ClearAnchors()
                        tooltipControl:SetAnchor(RIGHT, GuiMouse, LEFT, -32, 0)
                    else
                        tooltipControl:ClearAnchors()
                        tooltipControl:SetAnchor(LEFT, GuiMouse, RIGHT, 32, 0)
                    end
                end

                prevControl = tooltipControl

                if tooltip == ZO_MAP_TOOLTIP_MODE.INFORMATION then
                    g_ownsTooltip = true
                end
            end
        end
    end

    local isShowingTooltip = ZO_WorldMap_IsTooltipShowing()
    if wasShowingTooltip ~= isShowingTooltip then
        if isShowingTooltip then
            CALLBACK_MANAGER:FireCallbacks("OnShowWorldMapTooltip")
        else
            CALLBACK_MANAGER:FireCallbacks("OnHideWorldMapTooltip")
        end
    end
end

local function OnGuildNameAvailable()
    local keepTooltip = GetPlatformKeepTooltip()
    if not keepTooltip:IsHidden() then
        keepTooltip:RefreshKeepInfo()
    end
end

--Pin Click Handlers
----------------------

local function RemoveInvalidSpawnLocations(pinDatas)
    for i = #pinDatas, 1, -1 do
        local pin = pinDatas[i].pin
        local pinHandler = pinDatas[i].handler

        if ZO_MapPin.IsReviveLocation(pinHandler) and not ZO_MapPin.CanReviveAtPin(pin, pinHandler) then
            table.remove(pinDatas, i)
        end
    end
end

local function GetShownHandlersForPin(pin, mouseButton)
    if pin and ZO_MapPin.PIN_CLICK_HANDLERS[mouseButton] then
        local handlers = ZO_MapPin.PIN_CLICK_HANDLERS[mouseButton][pin:GetPinType()]
        if handlers then
            for i = 1, #handlers do
                local handler = handlers[i]
                if handler.show == nil or handler.show(pin) then
                    if handler.GetDynamicHandlers then
                        return handler.GetDynamicHandlers(pin)
                    else
                        return { handler }
                    end
                end
            end
        end
    end

    return nil
end

local function GetFirstShownHandlerForPin(pin, mouseButton)
    local handlers = GetShownHandlersForPin(pin, mouseButton)
    if handlers then
        return handlers[1]
    end

    return nil
end

function ZO_WorldMap_WouldPinHandleClick(pinControl, button, ctrl, alt, shift)
    if ctrl or alt then
        return false
    end

    if pinControl then
        local pin = ZO_MapPin.GetMapPinForControl(pinControl)
        local validPinHandler = GetFirstShownHandlerForPin(pin, button)
        if validPinHandler then
            return true
        end
    end

    for pin, isMousedOver in pairs(currentMouseOverPins) do
        if isMousedOver then
            local validHandler = GetFirstShownHandlerForPin(pin, button)
            if validHandler then
                return true
            end
        end
    end
end

function ZO_WorldMap_GetPinHandlers(mouseButton)
    local pinDatas = ZO_MapPin.pinDatas
    ZO_ClearNumericallyIndexedTable(pinDatas)

    for pin, isMousedOver in pairs(currentMouseOverPins) do
        if isMousedOver then
            local shownHandlers = GetShownHandlersForPin(pin, mouseButton)
            if shownHandlers then
                for _, handler in ipairs(shownHandlers) do
                    local duplicate = false
                    local duplicatesFunction = handler.duplicates
                    if duplicatesFunction then
                        for _, pinData in ipairs(pinDatas) do
                            --if these handlers are of the same type
                            if handler == pinData.handler then
                                if duplicatesFunction(pin, pinData.pin) then
                                    duplicate = true
                                    break
                                end
                            end
                        end
                    end

                    if not duplicate then
                        table.insert(pinDatas, {handler = handler, pin = pin})
                    end
                end
            end
        end
    end

    return pinDatas
end

function ZO_WorldMap_ChoosePinOption(pin, handler)
    if handler.show and not handler.show(pin) then
        --If something changed and we shouldn't be showing this option anymore then...
        if handler.failedAfterBeingShownError then
            --If we have some error text for this case then show it in a dialog
            local text
            if type(handler.failedAfterBeingShownError) == "function" then
                text = handler.failedAfterBeingShownError(pin)
            else
                text = handler.failedAfterBeingShownError
            end
            ZO_Dialogs_ShowPlatformDialog("WORLD_MAP_CHOICE_FAILED", nil, { mainTextParams = { text } })
        end
        --Then skip doing the action
        return
    end
    handler.callback(pin)
end

do
    local function SortPinDatas(firstData, secondData)
        local firstEntryName = GetValueOrExecute(firstData.handler.name, firstData.pin)
        local secondEntryName = GetValueOrExecute(secondData.handler.name, secondData.pin)
        local idResult = CompareIgnoreNil(firstEntryName, secondEntryName)
        if idResult ~= nil then
            return idResult
        end

        return false
    end

    local function OnMenuHiddenCallback()
        ZO_MapPin.pinsInKeyboardMapChoiceDialog = nil
    end

    function ZO_WorldMap_SetupKeyboardChoiceMenu(pinDatas, pinControl)
        ClearMenu()
        ZO_MapPin.pinsInKeyboardMapChoiceDialog = { }

        table.sort(pinDatas, SortPinDatas)

        for i = 1, #pinDatas do
            local handler = pinDatas[i].handler
            local pin = pinDatas[i].pin
            local name = handler.name
            if type(name) == "function" then
                name = name(pin)
            end
            AddMenuItem(name, function()
                ZO_WorldMap_ChoosePinOption(pin, handler)
            end)
            ZO_MapPin.pinsInKeyboardMapChoiceDialog[pin] = true
        end
        SetMenuHiddenCallback(OnMenuHiddenCallback)
        ShowMenu(pinControl)
    end
end

function ZO_WorldMap_HandlePinClicked(pinControl, mouseButton, ctrl, alt, shift)
    if ctrl or alt then
        return
    end

    local pinDatas = ZO_WorldMap_GetPinHandlers(mouseButton)

    RemoveInvalidSpawnLocations(pinDatas)

    if #pinDatas == 1 then
        pinDatas[1].handler.callback(pinDatas[1].pin)
    elseif #pinDatas > 1 then
        if IsInGamepadPreferredMode() then
            ZO_WorldMap_SetupGamepadChoiceDialog(pinDatas)
        else
            ZO_WorldMap_SetupKeyboardChoiceMenu(pinDatas, pinControl)
        end
    end
end

--Pins Manager

ZO_WorldMapPins = ZO_ObjectPool:Subclass()

function ZO_WorldMapPins:New(parentControl)
    local mouseInputGroup = ZO_MouseInputGroup:New(parentControl)

    local function CreatePin(pool)
        local pin = ZO_MapPin:New(parentControl)
        mouseInputGroup:Add(pin:GetControl(), ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
        return pin
    end

    local function ResetPin(pin)
        MouseOverPins_OnPinReset(pin)

        pin:Reset()
    end

    local mapPins = ZO_ObjectPool.New(self, CreatePin, ResetPin)

    mapPins.mouseInputGroup = mouseInputGroup

    -- Each of these tables holds a method of mapping pin lookup indices to the actual object pool keys needed to release the pins later
    -- The reason this exists is because the game events will hold info like "remove this specific quest index", and at that point we
    -- need to be able to lookup a pin for game-event data rather than pinTag data, without iterating over every single pin in the
    -- active objects list.
    mapPins.m_keyToPinMapping =
    {
        ["poi"] = {},       -- { [zone index 1] = { [objective index 1] = pinKey1, [objective index 2] = pinKey2,  ... }, ... }
        ["loc"] = {},
        ["quest"] = {},     -- { [quest index 1] = { [quest pin tag 1] = pinKey1, [quest pin tag 2] = pinKey2, ... }, ... }
        ["objective"] = {},
        ["keep"] = {},
        ["pings"] = {},
        ["killLocation"] = {},
        ["fastTravelKeep"] = {},
        ["fastTravelWayshrine"] = {},
        ["forwardCamp"] = {},
        ["AvARespawn"] = {},
        ["group"] = {},
        ["restrictedLink"] = {},
        ["suggestion"] = {},
        ["worldEventUnit"] = {},
        ["antiquityDigSite"] = {},
    }

    mapPins.nextCustomPinType = MAP_PIN_TYPE_INVALID
    mapPins.customPins = {}

    local function CreateBlobControl(pool)
        return ZO_ObjectPool_CreateNamedControl("ZO_QuestPinBlob", "ZO_PinBlob", pool, parentControl)
    end

    local function ResetBlobControl(blobControl)
        ZO_ObjectPool_DefaultResetControl(blobControl)
        blobControl:SetAlpha(1)
    end

    mapPins.pinBlobPool = ZO_ObjectPool:New(CreateBlobControl, ResetBlobControl)

    local function CreatePolygonBlobControl(pool)
        local polygonBlob = ZO_ObjectPool_CreateNamedControl("ZO_PinPolygonBlob", "ZO_PinPolygonBlob", pool, parentControl)
        mouseInputGroup:Add(polygonBlob, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
        return polygonBlob
    end

    local function ResetPolygonBlobControl(polygonControl)
        ZO_ObjectPool_DefaultResetControl(polygonControl)
        polygonControl:SetHandler("OnMouseUp", nil)
        polygonControl:SetHandler("OnMouseDown", nil)
        polygonControl:SetAlpha(1)
    end

    mapPins.pinPolygonBlobPool = ZO_ObjectPool:New(CreatePolygonBlobControl, ResetPolygonBlobControl)

    mapPins.pinFadeInAnimationPool = ZO_AnimationPool:New("ZO_WorldMapPinFadeIn")

    local function OnAnimationTimelineStopped(timeline)
        mapPins.pinFadeInAnimationPool:ReleaseObject(timeline.key)
    end

    local function SetupTimeline(timeline)
        timeline:SetHandler("OnStop", OnAnimationTimelineStopped)
    end

    mapPins.pinFadeInAnimationPool:SetCustomFactoryBehavior(SetupTimeline)

    local function ResetTimeline(animationTimeline)
        local pinAnimation = animationTimeline:GetAnimation(1)
        pinAnimation:SetAnimatedControl(nil)

        local areaAnimation = animationTimeline:GetAnimation(2)
        areaAnimation:SetAnimatedControl(nil)
    end

    mapPins.pinFadeInAnimationPool:SetCustomResetBehavior(ResetTimeline)

    --Wait until the map mode has been set before fielding these updates since adding a pin depends on the map having a mode.
    local OnWorldMapModeChanged
    OnWorldMapModeChanged = function(modeData)
        if modeData then
            WORLD_MAP_QUEST_BREADCRUMBS:RegisterCallback("QuestAvailable", function(...) mapPins:OnQuestAvailable(...) end)
            WORLD_MAP_QUEST_BREADCRUMBS:RegisterCallback("QuestRemoved", function(...) mapPins:OnQuestRemoved(...) end)
            CALLBACK_MANAGER:UnregisterCallback("OnWorldMapModeChanged", OnWorldMapModeChanged)
        end
    end
    CALLBACK_MANAGER:RegisterCallback("OnWorldMapModeChanged", OnWorldMapModeChanged)

    return mapPins
end

function ZO_WorldMapPins:AcquirePinBlob()
    return self.pinBlobPool:AcquireObject()
end

function ZO_WorldMapPins:ReleasePinBlob(pinBlobKey)
    self.pinBlobPool:ReleaseObject(pinBlobKey)
end

function ZO_WorldMapPins:AcquirePinPolygonBlob()
    return self.pinPolygonBlobPool:AcquireObject()
end

function ZO_WorldMapPins:ReleasePinPolygonBlob(pinBlobKey)
    self.pinPolygonBlobPool:ReleaseObject(pinBlobKey)
end

function ZO_WorldMapPins:AcquirePinFadeInAnimation()
    local animation, key = self.pinFadeInAnimationPool:AcquireObject()
    animation.key = key
    return animation
end

function ZO_WorldMapPins:OnQuestAvailable(questIndex)
    self:AddQuestPin(questIndex)
end

function ZO_WorldMapPins:OnQuestRemoved(questIndex)
    self:RemovePins("quest", questIndex)
    if g_questPingData and g_questPingData.questIndex then
         self:RemovePins("pings", MAP_PIN_TYPE_QUEST_PING)
    end
end

do
    local MAPS_WITHOUT_QUEST_PINS =
    {
        [MAPTYPE_WORLD] = true,
        [MAPTYPE_COSMIC] = true,
    }

    function ZO_WorldMap_DoesMapHideQuestPins()
        return MAPS_WITHOUT_QUEST_PINS[GetMapType()]
    end
end

function ZO_WorldMapPins:AddQuestPin(questIndex)
    if ZO_WorldMap_DoesMapHideQuestPins() then
        return
    end

    if not ZO_WorldMap_IsPinGroupShown(MAP_FILTER_QUESTS) then
        return
    end

    local questSteps = WORLD_MAP_QUEST_BREADCRUMBS:GetSteps(questIndex)
    if questSteps then
        for stepIndex, questConditions in pairs(questSteps) do
            for conditionIndex, conditionData in pairs(questConditions) do
                local xLoc, yLoc = conditionData.xLoc, conditionData.yLoc
                if conditionData.insideCurrentMapWorld and ZO_WorldMap_IsNormalizedPointInsideMapBounds(xLoc, yLoc) then
                    local tag = ZO_MapPin.CreateQuestPinTag(questIndex, stepIndex, conditionIndex)
                    tag.isBreadcrumb = conditionData.isBreadcrumb
                    local pin = self:CreatePin(conditionData.pinType, tag, xLoc, yLoc, conditionData.areaRadius)

                    if pin:DoesQuestDataMatchQuestPingData() then
                        local questPinTag = ZO_MapPin.CreateQuestPinTag(questIndex, stepIndex, conditionIndex)
                        self:CreatePin(MAP_PIN_TYPE_QUEST_PING, questPinTag, xLoc, yLoc)
                    end
                end
            end
        end
    end
end

function ZO_WorldMapPins:GetNextCustomPinType()
    self.nextCustomPinType = self.nextCustomPinType + 1
    return self.nextCustomPinType
end

function ZO_WorldMapPins:CreateCustomPinType(pinType)
    local pinTypeId = self:GetNextCustomPinType()
    _G[pinType] = pinTypeId
    return pinTypeId
end

function ZO_WorldMapPins:AddCustomPin(pinType, pinTypeAddCallback, pinTypeOnResizeCallback, pinLayoutData, pinTooltipCreator)
    if _G[pinType] ~= nil then return end

    local pinTypeString = pinType
    local pinTypeId = self:CreateCustomPinType(pinType)

    self.m_keyToPinMapping[pinTypeString] = {}

    self.customPins[pinTypeId] = { enabled = false, layoutCallback = pinTypeAddCallback, resizeCallback = pinTypeOnResizeCallback, pinTypeString = pinTypeString }
    ZO_MapPin.TOOLTIP_CREATORS[pinTypeId] = pinTooltipCreator
    ZO_MapPin.PIN_DATA[pinTypeId] = pinLayoutData
end

function ZO_WorldMapPins:SetCustomPinEnabled(pinType, enabled)
    local pinData = self.customPins[pinType]
    if pinData then
        pinData.enabled = enabled
    end
end

function ZO_WorldMapPins:IsCustomPinEnabled(pinType)
    local pinData = self.customPins[pinType]
    if pinData then
        return pinData.enabled
    end
end

function ZO_WorldMapPins:RefreshCustomPins(optionalPinType)
    for pinTypeId, pinData in pairs(self.customPins) do
        if optionalPinType == nil or optionalPinType == pinTypeId then
            self:RemovePins(pinData.pinTypeString)

            if pinData.enabled then
                pinData.layoutCallback(self)
            end
        end
    end
end

function ZO_WorldMapPins:MapPinLookupToPinKey(lookupType, majorIndex, keyIndex, pinKey)
    local lookupTable = self.m_keyToPinMapping[lookupType]

    local keys = lookupTable[majorIndex]
    if not keys then
        keys = {}
        lookupTable[majorIndex] = keys
    end

    keys[keyIndex] = pinKey
end

function ZO_WorldMapPins:CreatePin(pinType, pinTag, xLoc, yLoc, radius, borderInformation)
    local pin, pinKey = self:AcquireObject()
    pin:SetData(pinType, pinTag)
    pin:SetLocation(xLoc, yLoc, radius, borderInformation)

    if pinType == MAP_PIN_TYPE_PLAYER then
        pin:PingMapPin(ZO_MapPin.PulseAnimation)
        self.playerPin = pin
    end

    if not pin:ValidatePvPPinAllowed() then
        self:ReleaseObject(pinKey)
        return
    end

    if pin:IsPOI() then
        self:MapPinLookupToPinKey("poi", pin:GetPOIZoneIndex(), pin:GetPOIIndex(), pinKey)
    elseif pin:IsLocation() then
        self:MapPinLookupToPinKey("loc", pin:GetLocationIndex(), pin:GetLocationIndex(), pinKey)
    elseif pin:IsQuest() then
        self:MapPinLookupToPinKey("quest", pin:GetQuestIndex(), pinTag, pinKey)
    elseif pin:IsObjective() then
        self:MapPinLookupToPinKey("objective", pin:GetObjectiveKeepId(), pinTag, pinKey)
    elseif pin:IsKeepOrDistrict() then
        self:MapPinLookupToPinKey("keep", pin:GetKeepId(), pin:IsUnderAttackPin(), pinKey)
    elseif pin:IsMapPing() then
        self:MapPinLookupToPinKey("pings", pinType, pinTag, pinKey)
    elseif pin:IsKillLocation() then
        self:MapPinLookupToPinKey("killLocation", pinType, pinTag, pinKey)
    elseif pin:IsFastTravelKeep() then
        self:MapPinLookupToPinKey("fastTravelKeep", pin:GetFastTravelKeepId(), pin:GetFastTravelKeepId(), pinKey)
    elseif pin:IsFastTravelWayShrine() then
        self:MapPinLookupToPinKey("fastTravelWayshrine", pinType, pinTag, pinKey)
    elseif pin:IsForwardCamp() then
        self:MapPinLookupToPinKey("forwardCamp", pinType, pinTag, pinKey)
    elseif pin:IsAvARespawn() then
        self:MapPinLookupToPinKey("AvARespawn", pinType, pinTag, pinKey)
    elseif pin:IsGroup() then
        self:MapPinLookupToPinKey("group", pinType, pinTag, pinKey)
    elseif pin:IsRestrictedLink() then
        self:MapPinLookupToPinKey("restrictedLink", pinType, pinTag, pinKey)
    elseif pin:IsSuggestion() then
        self:MapPinLookupToPinKey("suggestion", pinType, pinTag, pinKey)
    elseif pin:IsWorldEventUnitPin() then
        self:MapPinLookupToPinKey("worldEventUnit", pin:GetWorldEventInstanceId(), pin:GetUnitTag(), pinKey)
    elseif pin:IsAntiquityDigSitePin() then
        self:MapPinLookupToPinKey("antiquityDigSite", pinType, pinTag, pinKey)
    else
        local customPinData = self.customPins[pinType]
        if customPinData then
            self:MapPinLookupToPinKey(customPinData.pinTypeString, pinType, pinTag, pinKey)
        end
    end

    g_mapPanAndZoom:OnPinCreated()

    return pin
end

function ZO_WorldMapPins:PingQuest(questIndex, animation)
    local pins = self:GetActiveObjects()
    local pinQuestIndex

    for pinKey, pin in pairs(pins) do
        pinQuestIndex = pin:GetQuestIndex()

        if pinQuestIndex > -1 then
            if pinQuestIndex == questIndex then
                pin:PingMapPin(animation)
            else
                pin:ResetAnimation(ZO_MapPin.ANIM_CONSTANTS.RESET_ANIM_HIDE_CONTROL)
            end
        end
    end
end

function ZO_WorldMapPins:SetQuestPinsAssisted(questIndex, assisted)
    local pins = self:GetActiveObjects()

    for pinKey, pin in pairs(pins) do
        local curIndex = pin:GetQuestIndex()
        if curIndex == questIndex then
            local currentPinType = pin:GetPinType()
            local trackingLevel = GetTrackingLevel(TRACK_TYPE_QUEST, questIndex)
            local newPinType = GetQuestPinTypeForTrackingLevel(currentPinType, trackingLevel)
            pin:ChangePinType(newPinType)
        end
    end
end

function ZO_WorldMapPins:FindPin(lookupType, majorIndex, keyIndex)
    local lookupTable = self.m_keyToPinMapping[lookupType]
    local keys
    if majorIndex then
        keys = lookupTable[majorIndex]
    else
        keys = select(2, next(lookupTable))
    end

    if keys then
        local pinKey
        if keyIndex then
            pinKey = keys[keyIndex]
        else
            pinKey = select(2, next(keys))
        end

        if pinKey then
            return self:GetActiveObject(pinKey)
        end
    end
end

function ZO_WorldMapPins:AddPinsToArray(pins, lookupType, majorIndex)
    local lookupTable = self.m_keyToPinMapping[lookupType]

    local function AddPinsForKeys(keysTable)
        if keysTable then
            for _, pinKey in pairs(keysTable) do
                local pin = self:GetActiveObject(pinKey)
                if pin then
                    table.insert(pins, pin)
                end
            end
        end
    end

    if majorIndex then
        local keys = lookupTable[majorIndex]
        AddPinsForKeys(keys)
    else
        for _, keys in pairs(lookupTable) do
            AddPinsForKeys(keys)
        end
    end

    return pins
end

function ZO_WorldMapPins:RemovePins(lookupType, majorIndex, keyIndex)
    local lookupTable = self.m_keyToPinMapping[lookupType]

    if majorIndex then
        local keys = lookupTable[majorIndex]
        if keys then
            if keyIndex then
                 --Remove a specific pin
                local pinKey = keys[keyIndex]
                if pinKey then
                    self:ReleaseObject(pinKey)
                    keys[keyIndex] = nil
                end
            else
                --Remove all pins in the major index
                for _, pinKey in pairs(keys) do
                    self:ReleaseObject(pinKey)
                end

                self.m_keyToPinMapping[lookupType][majorIndex] = {}
            end
        end
    else
        --Remove all pins of the lookup type
        for _, keys in pairs(lookupTable) do
            for _, pinKey in pairs(keys) do
                self:ReleaseObject(pinKey)
            end
        end

        self.m_keyToPinMapping[lookupType] = {}
    end
end

function ZO_WorldMapPins:UpdatePinsForMapSizeChange()
    local pins = self:GetActiveObjects()
    for pinKey, pin in pairs(pins) do
        pin:UpdateLocation()
        pin:UpdateSize()
    end

    for pinTypeId, pinData in pairs(self.customPins) do
        if pinData.enabled and pinData.resizeCallback then
            pinData.resizeCallback(self, CONSTANTS.MAP_WIDTH, CONSTANTS.MAP_HEIGHT)
        end
    end
end

function ZO_WorldMapPins:GetWayshrinePin(nodeIndex)
    local pins = self:GetActiveObjects()

    for pinKey, pin in pairs(pins) do
        local curIndex = pin:GetFastTravelNodeIndex()
        if curIndex == nodeIndex then
            return pin
        end
    end
end

function ZO_WorldMapPins:GetQuestConditionPin(questIndex)
    local pins = self:GetActiveObjects()

    for pinKey, pin in pairs(pins) do
        local curIndex = pin:GetQuestIndex()
        if curIndex == questIndex then
            return pin
        end
    end
end

function ZO_WorldMapPins:GetPlayerPin()
    return self.playerPin
end

--Map texture overlay management
---------------------------------

local function ShowMapTexture(textureControl, textureName, width, height, offsetX, offsetY)
    textureControl:SetTexture(textureName)
    textureControl:SetDimensions(width, height)
    textureControl:SetSimpleAnchorParent(offsetX, offsetY)
    textureControl:SetAlpha(1)
    textureControl:SetHidden(false)
end

--[[
    Blob factory function
--]]
local function MapOverlayControlFactory(pool, controlNamePrefix, templateName, parent)
    local overlayControl = ZO_ObjectPool_CreateNamedControl(controlNamePrefix, templateName, pool, parent)
    overlayControl:SetAlpha(0)              -- Because it's not shown yet and we want to fade in using current values
    ZO_AlphaAnimation:New(overlayControl)   -- This control will always use this utility object to animate itself, this links the control to the anim, so we don't need the return.
    return overlayControl
end

--[[
    Mouseover Map Blob manager.
    Shows a highlight for the current mouseover map that the user is pointing at.
--]]

ZO_MouseoverMapBlobManager = ZO_ObjectPool:Subclass()

function ZO_MouseoverMapBlobManager:New(blobContainer)
    local blobFactory = function(pool) return MapOverlayControlFactory(pool, "MapMouseoverBlob", "ZO_MapBlob", blobContainer) end
    local manager = ZO_ObjectPool.New(self, blobFactory, ZO_ObjectPool_DefaultResetControl)
    manager.m_currentTexture = ""
    manager.m_currentLocation = ""
    return manager
end

local function NormalizedBlobDataToUI(blobWidth, blobHeight, blobXOffset, blobYOffset)
    return blobWidth * CONSTANTS.MAP_WIDTH, blobHeight * CONSTANTS.MAP_HEIGHT, blobXOffset * CONSTANTS.MAP_WIDTH, blobYOffset * CONSTANTS.MAP_HEIGHT
end

function ZO_MouseoverMapBlobManager:Update(normalizedMouseX, normalizedMouseY, forceShowBlob)
    local locationName = ""
    local textureFile = ""
    local textureUIWidth, textureUIHeight, textureXOffset, textureYOffset

    if forceShowBlob or IsMouseOverMap() then
        local locXN, locYN, widthN, heightN
        locationName, textureFile, widthN, heightN, locXN, locYN = GetMapMouseoverInfo(normalizedMouseX, normalizedMouseY)
        textureUIWidth, textureUIHeight, textureXOffset, textureYOffset = NormalizedBlobDataToUI(widthN, heightN, locXN, locYN)
    end

    if locationName ~= self.m_currentLocation and ZO_WorldMapMouseoverName.owner ~= "poi" then
        if locationName ~= ZO_WorldMap.zoneName then
            ZO_WorldMapMouseoverName:SetText(zo_strformat(SI_WORLD_MAP_LOCATION_NAME, locationName))
        else
            ZO_WorldMapMouseoverName:SetText("")
        end
        self.m_currentLocation = locationName
    end

    local textureChanged = false
    if textureFile ~= self.m_currentTexture then
        self:HideCurrent()
        self.m_currentTexture = textureFile
        textureChanged = true
    elseif self.m_zoom ~= g_mapPanAndZoom:GetCurrentCurvedZoom() then
        self.m_zoom = g_mapPanAndZoom:GetCurrentCurvedZoom()
        textureChanged = true
    end

    if textureChanged then
        if textureFile ~= "" then
            local blob = self:AcquireObject(textureFile)
            if blob then
                ShowMapTexture(blob, textureFile, textureUIWidth, textureUIHeight, textureXOffset, textureYOffset)
            end
        end
    end
end

function ZO_MouseoverMapBlobManager:IsShowingMapRegionBlob()
    return self.m_currentTexture ~= ""
end

function ZO_MouseoverMapBlobManager:HideBlob(textureName)
    local blob = self:AcquireObject(textureName)

    if blob then
        blob:SetHidden(true)
    end
end

function ZO_MouseoverMapBlobManager:HideCurrent()
    if self.m_currentTexture ~= "" then
        self:HideBlob(self.m_currentTexture)
        self.m_currentTexture = ""
    end
end

function ZO_MouseoverMapBlobManager:ClearLocation()
    self.m_currentLocation = ""
end

local function PrepareBlobManagersForZoneUpdate()
    g_mouseoverMapBlobManager:HideCurrent()
    g_mouseoverMapBlobManager:ClearLocation()
end

--[[
    Map Location Management (set up the place names text that appears on the map...)
--]]

CONSTANTS.LOCATION_FONT = "$(BOLD_FONT)|%d|soft-shadow-thin"

ZO_MapLocations = ZO_ObjectPool:Subclass()

function ZO_MapLocations:New(container)
    local factory = function(pool) return ZO_ObjectPool_CreateNamedControl("ZO_MapLandmark", "ZO_MapLocation", pool, container) end
    local locations = ZO_ObjectPool.New(self, factory, ZO_ObjectPool_DefaultResetControl)

    locations.m_minFontSize = 17
    locations.m_maxFontSize = 32
    locations.m_cachedFontStrings = {}

    locations:SetFontScale(1)

    return locations
end

function ZO_MapLocations:SetFontScale(scale)
    if scale ~= self.m_fontScale then
        self.m_fontScale = scale
        self.m_cachedFontStrings = {}
    end
end

function ZO_MapLocations:GetFontString(size)
    -- apply scale to the (unscaled) input size, clamp it, and arive at final font string.
    -- unscale by global ui scale because we want the font to get a little bigger at smaller ui scales to approximately cover the same map area...
    local fontString = self.m_cachedFontStrings[size]
    if not fontString then
        fontString = string.format(CONSTANTS.LOCATION_FONT, zo_round(size / GetUIGlobalScale()))
        self.m_cachedFontStrings[size] = fontString
    end

    return fontString
end

function ZO_MapLocations:AddLocation(locationIndex)
    if IsMapLocationVisible(locationIndex) then
        local icon, x, y = GetMapLocationIcon(locationIndex)

        if icon ~= "" and ZO_WorldMap_IsNormalizedPointInsideMapBounds(x, y) then
            local tag = ZO_MapPin.CreateLocationPinTag(locationIndex, icon)
            g_mapPinManager:CreatePin(MAP_PIN_TYPE_LOCATION, tag, x, y)
        end
    end
end

function ZO_MapLocations:RefreshLocations()
    self:ReleaseAllObjects()
    g_mapPinManager:RemovePins("loc")

    for i = 1, GetNumMapLocations() do
        self:AddLocation(i)
    end
end

--Keep Fast Travel Network
-----------------------------

ZO_KeepNetwork = ZO_Object:Subclass()

ZO_KeepNetwork.ALLIANCE_OWNER_ALPHA =
{
    [ALLIANCE_ALDMERI_DOMINION] = 0.8,
    [ALLIANCE_EBONHEART_PACT] = 0.8,
    [ALLIANCE_DAGGERFALL_COVENANT] = 0.8,
    [ALLIANCE_NONE] = 0.2,
}

ZO_KeepNetwork.LINK_READY_COLOR = ZO_ColorDef:New(0, 1, 0, 0.4)
ZO_KeepNetwork.LINK_NOT_READY_COLOR = ZO_ColorDef:New(1, 1, 1, 0.2)

function ZO_KeepNetwork:New(container)
    local manager = ZO_Object.New(self)

    manager.container = container

    manager.linkPool = ZO_ControlPool:New("ZO_MapKeepLink", container, "Link")

    return manager
end

function ZO_KeepNetwork:SetOpenNetwork(keepId)
    g_mapRefresh:RefreshAll("keepNetwork")
end

function ZO_KeepNetwork:ClearOpenNetwork()
    if self.container:IsHidden() then
        g_mapPinManager:RemovePins("fastTravelKeep")
    else
        g_mapRefresh:RefreshAll("keepNetwork")
    end
end

do
    local function AddNetworkLinks(self)
        local linkPool = self.linkPool

        linkPool:ReleaseAllObjects()
        g_mapPinManager:RemovePins("restrictedLink")

        if GetMapFilterType() ~= MAP_FILTER_TYPE_AVA_CYRODIIL or GetCurrentMapIndex() ~= g_cyrodiilMapIndex then
            return
        end

        local showTransitLines = WORLD_MAP_MANAGER:GetFilterValue(MAP_FILTER_TRANSIT_LINES) ~= false
        if not showTransitLines then
            return
        end

        local showOnlyMyAlliance = WORLD_MAP_MANAGER:GetFilterValue(MAP_FILTER_TRANSIT_LINES_ALLIANCE) == MAP_TRANSIT_LINE_ALLIANCE_MINE

        local playerAlliance = GetUnitAlliance("player")
        local r,g,b
        local bgContext = ZO_WorldMap_GetBattlegroundQueryType()
        local numLinks = GetNumKeepTravelNetworkLinks(bgContext)
        local historyPercent = ZO_WorldMap_GetHistoryPercentToUse()
        local mapWidth = CONSTANTS.MAP_WIDTH
        local mapHeight = CONSTANTS.MAP_HEIGHT

        for linkIndex = 1, numLinks do
            local linkType, linkOwner, restrictedToAlliance, startNX, startNY, endNX, endNY = GetHistoricalKeepTravelNetworkLinkInfo(linkIndex, bgContext, historyPercent)
            local matchesAllianceOption = not showOnlyMyAlliance or linkOwner == playerAlliance
            if matchesAllianceOption and (ZO_WorldMap_IsNormalizedPointInsideMapBounds(startNX, startNY) or ZO_WorldMap_IsNormalizedPointInsideMapBounds(endNX, endNY)) then
                local startX, startY, endX, endY = startNX * mapWidth, startNY * mapHeight, endNX * mapWidth, endNY * mapHeight

                local linkControl = linkPool:AcquireObject()
                linkControl.startNX = startNX
                linkControl.startNY = startNY
                linkControl.endNX = endNX
                linkControl.endNY = endNY
                linkControl:SetHidden(false)

                if GetKeepFastTravelInteraction() then
                    if linkOwner == playerAlliance then
                        if linkType == FAST_TRAVEL_LINK_ACTIVE then
                            linkControl:SetColor(ZO_KeepNetwork.LINK_READY_COLOR:UnpackRGBA())
                        else
                            linkControl:SetColor(ZO_KeepNetwork.LINK_NOT_READY_COLOR:UnpackRGBA())
                        end
                    else
                        r,g,b = GetAllianceColor(linkOwner):UnpackRGB()
                        linkControl:SetColor(r, g, b, ZO_KeepNetwork.ALLIANCE_OWNER_ALPHA[linkOwner])
                    end
                else
                    r,g,b = GetAllianceColor(linkOwner):UnpackRGB()
                    linkControl:SetColor(r, g, b, ZO_KeepNetwork.ALLIANCE_OWNER_ALPHA[linkOwner])
                end

                if linkType == FAST_TRAVEL_LINK_IN_COMBAT then
                    linkControl:SetTexture("EsoUI/Art/AvA/AvA_transitLine_dashed.dds")
                else
                    linkControl:SetTexture("EsoUI/Art/AvA/AvA_transitLine.dds")
                end

                ZO_Anchor_LineInContainer(linkControl, nil, startX, startY, endX, endY)

                --only show alliance restrictions on uncontrolled links.
                if linkOwner == ALLIANCE_NONE and restrictedToAlliance ~= ALLIANCE_NONE then
                    local linkCenterX = (startNX + endNX) / 2
                    local linkCenterY = (startNY + endNY) / 2

                    local tag = ZO_MapPin.CreateRestrictedLinkTravelNetworkPinTag(restrictedToAlliance, bgContext)
                    local pinType = CONSTANTS.ALLIANCE_TO_RESTRICTED_PIN_TYPE[restrictedToAlliance]
                    g_mapPinManager:CreatePin(pinType, tag, linkCenterX, linkCenterY)
                end
            end
        end
    end

    function ZO_KeepNetwork:UpdateLinkPostionsForNewMapSize()
        local mapWidth = CONSTANTS.MAP_WIDTH
        local mapHeight = CONSTANTS.MAP_HEIGHT

        local links = self.linkPool:GetActiveObjects()
        for _, link in pairs(links) do
            local startX, startY, endX, endY = link.startNX * mapWidth, link.startNY * mapHeight, link.endNX * mapWidth, link.endNY * mapHeight
            ZO_Anchor_LineInContainer(link, nil, startX, startY, endX, endY)
        end
    end

    function ZO_KeepNetwork:RefreshLinks()
        g_mapPinManager:RemovePins("fastTravelKeep")

        AddNetworkLinks(self)

        if GetKeepFastTravelInteraction() or WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_KEEP_RECALL) then
            local bgContext = ZO_WorldMap_GetBattlegroundQueryType();

            for i = 1, GetNumKeepTravelNetworkNodes(bgContext) do
                if self:CanAddKeep(i, bgContext) then
                    local keepId, accessible, normalizedX, normalizedY = GetKeepTravelNetworkNodeInfo(i, bgContext)
                    local pinType = MAP_PIN_TYPE_FAST_TRAVEL_KEEP_ACCESSIBLE
                    local keepType = GetKeepType(keepId)
                    if keepType == KEEPTYPE_BORDER_KEEP then
                        pinType = MAP_PIN_TYPE_FAST_TRAVEL_BORDER_KEEP_ACCESSIBLE
                    elseif keepType == KEEPTYPE_OUTPOST then
                        pinType = MAP_PIN_TYPE_FAST_TRAVEL_OUTPOST_ACCESSIBLE
                    end
                    local tag = ZO_MapPin.CreateKeepTravelNetworkPinTag(keepId)
                    g_mapPinManager:CreatePin(pinType, tag, normalizedX, normalizedY)
                end
            end
        end
    end

    function ZO_KeepNetwork:CanAddKeep(keepIndex, bgContext)
        local normalizedX, normalizedY = GetKeepTravelNetworkNodePosition(keepIndex, bgContext)
        if ZO_WorldMap_IsNormalizedPointInsideMapBounds(normalizedX, normalizedY) then
            local keepId = GetKeepTravelNetworkNodeKeepId(keepIndex, bgContext)
            if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_KEEP_RECALL) then
                return GetKeepRecallAvailable(keepId, bgContext)
            else
                return CanKeepBeFastTravelledTo(keepId, bgContext)
            end
        end

        return false
    end

end 

--[[
    World Map Logic
--]]

local function UpdateGroupPins()
    for groupTag, groupPin in pairs(g_activeGroupPins) do
        local x, y = GetMapPlayerPosition(groupTag)
        groupPin:SetLocation(x, y)
    end
end

local function UpdatePlayerPin()
    local playerPin = g_mapPinManager:GetPlayerPin()
    local x, y, _, isShownInCurrentMap = GetMapPlayerPosition("player")
    playerPin:SetLocation(x, y)
    -- Design rule, don't show player pin on cosmic, even if they're in the map
    if isShownInCurrentMap and not IsShowingCosmicMap() then
        playerPin:SetHidden(false)
        playerPin:SetRotation(GetPlayerCameraHeading())
    else
        playerPin:SetHidden(true)
    end
end



local UpdateMovingPins
do
    local g_worldEventUnitPins = {}
    
    function UpdateMovingPins()
        UpdatePlayerPin()
        UpdateGroupPins()

        for _, pin in ipairs(g_objectiveMovingPins) do
            local pinType, currentX, currentY = GetObjectivePinInfo(pin:GetObjectiveKeepId(), pin:GetObjectiveObjectiveId(), pin:GetBattlegroundContext())
            pin:SetLocation(currentX, currentY)
        end

        g_mapPinManager:AddPinsToArray(g_worldEventUnitPins, "worldEventUnit")
        for _, pin in ipairs(g_worldEventUnitPins) do
            local xLoc, yLoc = GetMapPlayerPosition(pin:GetUnitTag())
            pin:SetLocation(xLoc, yLoc)
        end
        ZO_ClearNumericallyIndexedTable(g_worldEventUnitPins)
    end
end

--Map Sizing
-------------------------

local function GetSquareMapWindowDimensions(dimension, widthDriven, mapSize)
    mapSize = mapSize or WORLD_MAP_MANAGER:GetModeMapSize()

    local conformedWidth, conformedHeight
    local squareDiff = MAP_CONTAINER_LAYOUT[mapSize].paddingY - MAP_CONTAINER_LAYOUT[mapSize].paddingX

    if widthDriven then
        conformedWidth, conformedHeight = dimension, dimension + squareDiff
    else
        conformedWidth, conformedHeight = dimension - squareDiff, dimension
    end

    local uiWidth, uiHeight = GuiRoot:GetDimensions()
    if conformedWidth < CONSTANTS.MAP_MIN_SIZE then
        conformedWidth = CONSTANTS.MAP_MIN_SIZE
        conformedHeight = conformedWidth + squareDiff
    end
    if conformedWidth > uiWidth then
        conformedWidth = uiWidth
        conformedHeight = conformedWidth + squareDiff
    end
    if conformedHeight < CONSTANTS.MAP_MIN_SIZE then
        conformedHeight = CONSTANTS.MAP_MIN_SIZE
        conformedWidth = conformedHeight - squareDiff
    end
    if conformedHeight > uiHeight then
        conformedHeight = uiHeight
        conformedWidth = conformedHeight - squareDiff
    end

    return conformedWidth, conformedHeight
end

local function GetFullscreenMapWindowDimensions()
    local uiWidth, uiHeight = GuiRoot:GetDimensions()
    local mapPaddingY = IsInGamepadPreferredMode() and CONSTANTS.GAMEPAD_MAP_PADDING_Y_PIXELS or CONSTANTS.KEYBOARD_MAP_PADDING_Y_PIXELS
    local mapWidth, mapHeight = GetSquareMapWindowDimensions(uiHeight - CONSTANTS.MAIN_MENU_AREA_Y * 2 - (mapPaddingY / GetUIGlobalScale()), CONSTANTS.WORLDMAP_RESIZE_HEIGHT_DRIVEN)
    --if this size would not allow enough space to fit the map info panel then recalculate using that requirement
    if (uiWidth - mapWidth) / 2 < CONSTANTS.MAP_INFO_WIDTH then
        mapWidth, mapHeight = GetSquareMapWindowDimensions(uiWidth - 2 * CONSTANTS.MAP_INFO_WIDTH, CONSTANTS.WORLDMAP_RESIZE_WIDTH_DRIVEN)
    end
    return mapWidth, mapHeight
end

local function CalculateContainerAnchorOffsets()
    local containerCenterX, containerCenterY = ZO_WorldMapContainer:GetCenter()
    local scrollCenterX, scrollCenterY = ZO_WorldMapScroll:GetCenter()
    return containerCenterX - scrollCenterX, containerCenterY - scrollCenterY
end

local ZOOM_KEYBIND_STRIP_PADDING_Y = 10

--this is a total hack function to fix sizing issues on gamepad PC until map can be redone
local function GetGamepadAdjustedMapDimensions()
    local uiWidth, uiHeight = GuiRoot:GetDimensions()

    -- Get location tooltip left, get info box right, calculate the difference, send that as your square.
    local left = GAMEPAD_WORLD_MAP_TOOLTIP_FRAGMENT.control:GetLeft()
    local right = GAMEPAD_WORLD_MAP_INFO_FRAGMENT.control:GetRight()
    local padding = 50
    local newMapWidth = left - right - padding

    --caculate the safe zone height
    local headerHeight = ZO_WorldMapHeader_Gamepad:GetNamedChild("ZoomKeybind"):GetHeight() + ZOOM_KEYBIND_STRIP_PADDING_Y -- use the zoomkeybind so we don't create a cyclical dependancy between the header title and map extants
    local buttonsHeight = ZO_WorldMapButtons:GetHeight()
    local keybindStripHeight = ZO_KeybindStripGamepadBackgroundTexture:GetHeight()
    local safeHeight = uiHeight - ZO_GAMEPAD_SAFE_ZONE_INSET_Y - headerHeight - buttonsHeight - keybindStripHeight - padding

    newMapWidth = zo_min(newMapWidth, safeHeight)

    return newMapWidth, newMapWidth
end

local function SetMapWindowSize(newWidth, newHeight)
    if IsInGamepadPreferredMode() then
        newWidth, newHeight = GetGamepadAdjustedMapDimensions()
    end

    local LAYOUT = MAP_CONTAINER_LAYOUT[WORLD_MAP_MANAGER:GetModeMapSize()]

    local verticalPadding = LAYOUT.paddingY
    local horizontalPadding = LAYOUT.paddingX

    local containerHeight = zo_floor(newHeight - verticalPadding)
    local containerWidth = zo_floor(newWidth - horizontalPadding)
    local mapSize = zo_max(containerHeight, containerWidth) * g_mapPanAndZoom:GetCurrentCurvedZoom()

    CONSTANTS.MAP_WIDTH = mapSize
    CONSTANTS.MAP_HEIGHT = mapSize

    local RAGGED_EDGE_OFFSET_X = 90
    local RAGGED_EDGE_OFFSET_Y = 95
    local raggedEdgeScaledOffsetX = RAGGED_EDGE_OFFSET_X * g_mapPanAndZoom:GetCurrentCurvedZoom()
    local raggedEdgeScaledOffsetY = RAGGED_EDGE_OFFSET_Y * g_mapPanAndZoom:GetCurrentCurvedZoom()

    if IsInGamepadPreferredMode() then
        g_mapOverflowX = mapSize * .5
        g_mapOverflowY = mapSize * .5
    else
        g_mapOverflowX = zo_floor(mapSize - containerWidth) * .5
        g_mapOverflowY = zo_floor(mapSize - containerHeight) * .5
    end

    g_mapOverflowMaxX = g_mapOverflowX
    g_mapOverflowMaxY = g_mapOverflowY

    ZO_WorldMap:SetDimensions(newWidth, newHeight)
    ZO_WorldMapContainer:SetDimensions(CONSTANTS.MAP_WIDTH, CONSTANTS.MAP_HEIGHT)

    ZO_WorldMapContainerBackground:SetDimensions(CONSTANTS.MAP_WIDTH * 2, CONSTANTS.MAP_HEIGHT * 2)

    ZO_WorldMapContainerRaggedEdge:SetAnchor(TOPLEFT, ZO_WorldMapContainer, TOPLEFT, -raggedEdgeScaledOffsetX, -raggedEdgeScaledOffsetY)
    ZO_WorldMapContainerRaggedEdge:SetAnchor(BOTTOMRIGHT, ZO_WorldMapContainer, BOTTOMRIGHT, raggedEdgeScaledOffsetX, raggedEdgeScaledOffsetY)

    ZO_WorldMapContainerRaggedEdge:SetScale(g_mapPanAndZoom:GetCurrentCurvedZoom())

    ZO_WorldMapScroll:SetDimensions(containerWidth, containerHeight)
    ZO_WorldMapScroll:SetAnchor(TOPLEFT, ZO_WorldMap, TOPLEFT, LAYOUT.offsetX, LAYOUT.offsetY)

    g_mapTileManager:LayoutTiles()

    g_mapScale = mapSize / (GuiRoot:GetHeight() - verticalPadding)
    g_mapLocationManager:SetFontScale(g_mapScale)

    UpdateMovingPins()
    local normalizedX, normalizedY = NormalizePreferredMousePositionToMap()
    g_mouseoverMapBlobManager:Update(normalizedX, normalizedY)
    g_mapPinManager:UpdatePinsForMapSizeChange()
    if g_keepNetworkManager then
        g_keepNetworkManager:UpdateLinkPostionsForNewMapSize()
    end

    if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_SMALL_CUSTOM) then
        local modeData = WORLD_MAP_MANAGER:GetModeData()
        modeData.width = newWidth
        modeData.height = newHeight
    end
end

local function ResizeAndReanchorMap()
    local uiWidth, uiHeight = GuiRoot:GetDimensions()
    ZO_WorldMap:SetDimensionConstraints(CONSTANTS.MAP_MIN_SIZE, CONSTANTS.MAP_MIN_SIZE, uiWidth, uiHeight)

    local modeData = WORLD_MAP_MANAGER:GetModeData()

    local oldMapWidth, oldMapHeight = ZO_WorldMap:GetDimensions()
    local newMapWidth, newMapHeight
    if modeData.mapSize == CONSTANTS.WORLDMAP_SIZE_FULLSCREEN then
        newMapWidth, newMapHeight = GetFullscreenMapWindowDimensions()
    else
        if modeData.keepSquare then
            newMapWidth, newMapHeight = GetSquareMapWindowDimensions(oldMapWidth, CONSTANTS.WORLDMAP_RESIZE_WIDTH_DRIVEN)
        else
            newMapWidth, newMapHeight = zo_min(oldMapWidth, uiWidth), zo_min(oldMapHeight, uiHeight)
        end
    end
    SetMapWindowSize(newMapWidth, newMapHeight)
    if modeData.mapSize == CONSTANTS.WORLDMAP_SIZE_FULLSCREEN then
        ZO_WorldMap:ClearAnchors()
        if IsInGamepadPreferredMode() then
            ZO_WorldMap:SetAnchor(CENTER, nil, CENTER, 0, CONSTANTS.GAMEPAD_CENTER_OFFSET_Y_PIXELS / GetUIGlobalScale())
        else
            ZO_WorldMap:SetAnchor(CENTER, nil, CENTER, 0, CONSTANTS.CENTER_OFFSET_Y_PIXELS / GetUIGlobalScale())
        end
    end
end

function ZO_WorldMap_OnResizeStart(self)
    g_resizingMap = true
    local x,y = GetUIMousePosition()
    local left, top, right, bot = ZO_WorldMap:GetScreenRect()
    local minXToSide = zo_min(zo_abs(x - left), zo_abs(x - right))
    local minYToSide = zo_min(zo_abs(y - top), zo_abs(y - bot))
    g_resizeIsWidthDriven = (minXToSide < minYToSide)
end

local function SaveMapPosition()
    if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_SMALL_CUSTOM) then
        local modeData = WORLD_MAP_MANAGER:GetModeData()

        local isValid, target
        isValid, modeData.point, target, modeData.relPoint, modeData.x, modeData.y = ZO_WorldMap:GetAnchor(0)
    end
end

function ZO_WorldMap_OnResizeStop(self)
    SaveMapPosition()
    g_resizingMap = false
    ZO_WorldMap_UpdateMap()
end

-- Zoom Keybind Descriptor (for handling updates on various parts of the map and pins)
local ZO_MapZoomKeybindStrip = ZO_Object:Subclass()

function ZO_MapZoomKeybindStrip:New(...)
    local zoomKeybindStrip = ZO_Object.New(self)
    zoomKeybindStrip:Initialize(...)
    return zoomKeybindStrip
end

function ZO_MapZoomKeybindStrip:Initialize(control, descriptor)
    self.control = control
    self.descriptor = descriptor
end

function ZO_MapZoomKeybindStrip:GetDescriptor()
    return self.descriptor
end

function ZO_MapZoomKeybindStrip:MarkDirty()
    self.isDirty = true
end

function ZO_MapZoomKeybindStrip:CleanDirty()
    if self.isDirty then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self:GetDescriptor())
        self.isDirty = false
        return true
    end
    return false
end

-- Mouseover Keybind Descriptor (for handling updates on various parts of the map and pins)
local ZO_MapMouseoverKeybindStrip = ZO_Object:Subclass()

function ZO_MapMouseoverKeybindStrip:New(...)
    local mouseoverKeybindStrip = ZO_Object.New(self)
    mouseoverKeybindStrip:Initialize(...)
    return mouseoverKeybindStrip
end

function ZO_MapMouseoverKeybindStrip:Initialize(control, descriptor)
    self.control = control
    self.descriptor = descriptor
    self.mouseoverPins = {}
end

function ZO_MapMouseoverKeybindStrip:GetDescriptor()
    return self.descriptor
end

function ZO_MapMouseoverKeybindStrip:MarkDirty()
    self.isDirty = true
end

function ZO_MapMouseoverKeybindStrip:CleanDirty()
    if self.isDirty then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self:GetDescriptor())
        self.isDirty = false
        return true
    end
    return false
end

function ZO_MapMouseoverKeybindStrip:DoMouseEnterForPinType(pinType)
    -- NOTE: Only checking the pin types that this would care about
    if pinType == MAP_PIN_TYPE_PLAYER_WAYPOINT then
        self:SetIsOverPinType(MAP_PIN_TYPE_PLAYER_WAYPOINT, true)
    end

    if IsInGamepadPreferredMode() then
        self:MarkDirty()
    end
end

function ZO_MapMouseoverKeybindStrip:DoMouseExitForPinType(pinType)
    -- NOTE: Only checking the pin types that this would care about
    if pinType == MAP_PIN_TYPE_PLAYER_WAYPOINT then
        self:SetIsOverPinType(MAP_PIN_TYPE_PLAYER_WAYPOINT, false)
    end

    if IsInGamepadPreferredMode() then
        self:MarkDirty()
    end
end

function ZO_MapMouseoverKeybindStrip:IsOverPinType(pinType)
    return self.mouseoverPins[pinType]
end

function ZO_MapMouseoverKeybindStrip:SetIsOverPinType(pinType, isOver)
    local wasOverPinType = self:IsOverPinType(pinType)
    self.mouseoverPins[pinType] = isOver

    if wasOverPinType ~= self.mouseoverPins[pinType] then
        self:MarkDirty()
    end
end

--Pan and Zoom State

local ZO_MapPanAndZoom = ZO_Object:Subclass()
local LERP_FACTOR = 0.07
ZO_MapPanAndZoom.WHEN_AVAILABLE_LIMIT = 5

function ZO_MapPanAndZoom:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_MapPanAndZoom:Initialize(zoomControl)
    self.control = zoomControl
    WORLD_MAP_ZOOM_FRAGMENT = ZO_FadeSceneFragment:New(zoomControl)

    self.zoomSliderControl = zoomControl:GetNamedChild("Slider")
    self.zoomPlusControl = zoomControl:GetNamedChild("Plus")
    self.zoomMinusControl = zoomControl:GetNamedChild("Minus")

    self.zoomSlider = ZO_SmoothSlider:New(self.zoomSliderControl, "ZO_WorldMapZoomButton", 16, 25, -2, 1.8)
    self.zoomSlider:EnableHighlight("EsoUI/Art/Buttons/smoothSliderButton_up.dds", "EsoUI/Art/Buttons/smoothSliderButton_selected.dds")
    self.zoomSlider:SetNumDivisions(11)
    self.zoomSlider:SetMinMax(0, 1)

    local function zoomSliderButtonClicked(value)
        PlaySound(SOUNDS.MAP_ZOOM_LEVEL_CLICKED)
        self:SetTargetNormalizedZoom(value)
    end
    self.zoomSlider:SetClickedCallback(zoomSliderButtonClicked)
    self:SetMapZoomMinMax(1,5)
    self:SetCurrentNormalizedZoomInternal(0)
    self.reachedTargetOffset = true

    zoomControl:RegisterForEvent(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function(eventId, isGamepadPreferred)
        self:SetAllowPanPastMapEdge(isGamepadPreferred)
        local modeData = WORLD_MAP_MANAGER:GetModeData()
        if ZO_WorldMap and modeData then
            --Refresh the amount of border scrolling space since it depends if we're using gamepad or not
            ResizeAndReanchorMap()
        end
    end)
    self:SetAllowPanPastMapEdge(IsInGamepadPreferredMode())
end

function ZO_MapPanAndZoom:SetAllowPanPastMapEdge(allowed)
    self.allowPanPastMapEdge = allowed
end

function ZO_MapPanAndZoom:ClearLockPoint()
    self.lockPointNX = nil
    self.lockPointNY = nil
    self.lockPointX = nil
    self.lockPointY = nil
end

function ZO_MapPanAndZoom:ClearTargetOffset()
    self.targetOffsetX = nil
    self.targetOffsetY = nil
    self.reachedTargetOffset = true
end

function ZO_MapPanAndZoom:ClearTargetNormalizedZoom()
    self.targetNormalizedZoom = nil
    self:RefreshZoomButtonsEnabled()
end

function ZO_MapPanAndZoom:SetTargetNormalizedZoom(normalizedZoom)
    if zo_abs(self.currentNormalizedZoom - normalizedZoom) > 0.001 then
        self.targetNormalizedZoom = normalizedZoom
        self:RefreshZoomButtonsEnabled()
    end
end

ZO_MapPanAndZoom.MAX_OVER_ZOOM = 1.3
ZO_MapPanAndZoom.NAVIGATE_IN_OR_OUT_NORMALIZED_ZOOM_ADJUSTMENT = 0.1

function ZO_MapPanAndZoom:ComputeMinZoom()
    return 1
end

function ZO_MapPanAndZoom:ComputeMaxZoom()
    if not self:CanMapZoom() then
        return 1
    else
        local customMaxZoom = GetMapCustomMaxZoom()
        if customMaxZoom then
            return customMaxZoom
        else
            --default to a zoom level that doesn't make the map texture look bad
            local numTiles = GetMapNumTiles()
            local tilePixelWidth = ZO_WorldMapContainer1:GetTextureFileDimensions()
            local totalPixels = numTiles * tilePixelWidth
            local mapAreaUIUnits = ZO_WorldMapScroll:GetHeight()
            local mapAreaPixels = mapAreaUIUnits * GetUIGlobalScale()
            local maxZoomToStayBelowNative = totalPixels / mapAreaPixels
            return zo_max(maxZoomToStayBelowNative * ZO_MapPanAndZoom.MAX_OVER_ZOOM, 1)
        end
    end
end

function ZO_MapPanAndZoom:CanInitializeMap()
    --Check that the texture is shown due to a possible optimization where the texture unit is auto-released when the texture control is hidden
    return ZO_WorldMapContainer1 and ZO_WorldMapContainer1:IsTextureLoaded() and not ZO_WorldMapContainer1:IsHidden()
end

local USE_CURRENT_ZOOM = true

function ZO_MapPanAndZoom:SetNormalizedZoomAndOffsetInNewMap(normalizedZoom)
    self:SetCurrentNormalizedZoom(normalizedZoom)
    local pin = g_mapPinManager:GetPlayerPin()

    if self:JumpToPin(pin, USE_CURRENT_ZOOM) then
        return
    else
        self:SetCurrentOffset(0, 0)
    end
end

function ZO_MapPanAndZoom:InitializeMap(wasNavigateIn)
    if self:CanInitializeMap() then
        self.pendingInitializeMap = false

        self:ClearLockPoint()
        self:ClearTargetOffset()
        self:ClearTargetNormalizedZoom()
        self:SetMapZoomMinMax(self:ComputeMinZoom(), self:ComputeMaxZoom())

        if self.pendingJumpToPin then
            self:JumpToPin(self.pendingJumpToPin, self.pendingJumpToPinZoomMode)
        elseif self.pendingPanToPin then
            self:PanToPin(self.pendingPanToPin, self.pendingPanToPinZoomMode)
        elseif self.pendingPanToNormalizedPosition then
            self:PanToNormalizedPosition(self.pendingPanToNormalizedPosition.positionX, self.pendingPanToNormalizedPosition.positionY, self.pendingPanToNormalizedPositionZoomMode)
        elseif wasNavigateIn ~= nil and IsInGamepadPreferredMode() then
            if wasNavigateIn then
                self:SetNormalizedZoomAndOffsetInNewMap(ZO_MapPanAndZoom.NAVIGATE_IN_OR_OUT_NORMALIZED_ZOOM_ADJUSTMENT)
            else
                self:SetNormalizedZoomAndOffsetInNewMap(1 - ZO_MapPanAndZoom.NAVIGATE_IN_OR_OUT_NORMALIZED_ZOOM_ADJUSTMENT)
            end
        else
            self:SetCurrentNormalizedZoom(0)
            self:SetCurrentOffset(0, 0)
        end

        self.pendingJumpToPin = nil
        self.pendingPanToPin = nil
        self.pendingPanToNormalizedPosition = nil
        self.pendingPanToPinZoomMode = nil
        self.pendingJumpToPinZoomMode = nil
        self.pendingPanToNormalizedPositionZoomMode = nil
    else
        self.pendingInitializeMap = true
        self.pendingInitializeMapWasNavigateIn = wasNavigateIn
    end
end

function ZO_MapPanAndZoom:SetCustomZoomMinMax(minZoom, maxZoom)
    self.customMin = minZoom
    self.customMax = maxZoom
    self:RefreshZoom()
end

function ZO_MapPanAndZoom:ClearCustomZoomMinMax()
    self.customMin = nil
    self.customMax = nil
    self:RefreshZoom()
end

function ZO_MapPanAndZoom:SetMapZoomMinMax(minZoom, maxZoom)
    self.mapMin = minZoom
    self.mapMax = maxZoom
    self:RefreshZoom()
end

function ZO_MapPanAndZoom:RefreshZoom()
    if self.customMin then
        self:SetZoomMinMax(self.customMin, self.customMax)
    else
        self:SetZoomMinMax(self.mapMin, self.mapMax)
    end
end

function ZO_MapPanAndZoom:SetZoomMinMax(minZoom, maxZoom)
    self.minZoom = minZoom
    self.maxZoom = maxZoom
    local hideZoomBar = self.maxZoom - self.minZoom <= 0
    self.zoomSliderControl:SetHidden(hideZoomBar)
    self.zoomPlusControl:SetHidden(hideZoomBar)
    self.zoomMinusControl:SetHidden(hideZoomBar)
    self:RefreshZoomButtonsEnabled()
end

function ZO_MapPanAndZoom:GetCurrentNormalizedZoom()
    return self.currentNormalizedZoom
end

function ZO_MapPanAndZoom:ComputeCurvedZoom(normalizedZoom)
    return zo_lerp(self.minZoom, self.maxZoom, ZO_EaseNormalizedZoom(normalizedZoom))
end

function ZO_MapPanAndZoom:GetCurrentCurvedZoom()
    return self:ComputeCurvedZoom(self.currentNormalizedZoom)
end

function ZO_MapPanAndZoom:SetCurrentNormalizedZoom(zoom)
    self:ClearTargetNormalizedZoom()
    self:SetCurrentNormalizedZoomInternal(zoom)
end

function ZO_MapPanAndZoom:SetCurrentNormalizedZoomInternal(normalizedZoom)
    normalizedZoom = zo_clamp(normalizedZoom, 0, 1)
    self.currentNormalizedZoom = normalizedZoom
    self.zoomSlider:SetValue(normalizedZoom)

    g_stickyPin:UpdateThresholdDistance(normalizedZoom)

    self:RefreshZoomButtonsEnabled()

    if ZO_WorldMap then
        SetMapWindowSize(ZO_WorldMap:GetDimensions())
    end
end

function ZO_MapPanAndZoom:RefreshZoomButtonsEnabled()
    local considerNormalizedZoom
    if self.targetNormalizedZoom then
        considerNormalizedZoom = self.targetNormalizedZoom
    else
        considerNormalizedZoom = self.currentNormalizedZoom
    end

    if considerNormalizedZoom then
        if self.mapMax - self.mapMin > 0 then
            self.canZoomOutFurther = considerNormalizedZoom > 0
            self.canZoomInFurther = considerNormalizedZoom < 1
        else
            self.canZoomOutFurther = false
            self.canZoomInFurther = false
        end
        self.zoomMinusControl:SetEnabled(self.canZoomOutFurther)
        self.zoomPlusControl:SetEnabled(self.canZoomInFurther)
    end
end

function ZO_MapPanAndZoom:CanZoomInFurther()
    return self.canZoomInFurther
end

function ZO_MapPanAndZoom:CanZoomOutFurther()
    return self.canZoomOutFurther
end

function ZO_MapPanAndZoom:Step(amount)
    local oldNormalizedZoom = self.targetNormalizedZoom or self.currentNormalizedZoom
    local newNormalizedZoom = self.zoomSlider:GetStepValue(oldNormalizedZoom, amount)
    self:SetLockedNormalizedZoom(newNormalizedZoom, ZO_WorldMapScroll:GetCenter())
end

do
    local NORMALIZED_ZOOM_PER_DELTA = 0.1

    function ZO_MapPanAndZoom:AddZoomDelta(delta, mouseX, mouseY)
        local oldNormalizedZoom = self.targetNormalizedZoom or self.currentNormalizedZoom
        local newNormalizedZoom = zo_clamp(oldNormalizedZoom + delta * NORMALIZED_ZOOM_PER_DELTA, 0, 1)
        self:SetLockedNormalizedZoom(newNormalizedZoom, mouseX, mouseY)
        if delta > 0 and self.canZoomInFurther then
            PlaySound(SOUNDS.MAP_ZOOM_IN)
        elseif delta < 0 and self.canZoomOutFurther then
            PlaySound(SOUNDS.MAP_ZOOM_OUT)
        end
    end
end

do
    local MAX_FULL_ZOOM_DURATION_S = 2
    local MIN_ZOOM_SPEED_PER_S = 2

    function ZO_MapPanAndZoom:AddZoomDeltaGamepad(triggerMagnitude, frameDeltaS)
        local oldNormalizedZoom = self.targetNormalizedZoom or self.currentNormalizedZoom
        local zoomDifference = self.maxZoom - self.minZoom
        local speed = triggerMagnitude * zo_max(MIN_ZOOM_SPEED_PER_S, zoomDifference / MAX_FULL_ZOOM_DURATION_S)
        local normalizedSpeed = zoomDifference > 0 and (speed / zoomDifference) or 0
        local newNormalizedZoom = zo_clamp(oldNormalizedZoom + frameDeltaS * normalizedSpeed, 0, 1)
        self:SetLockedNormalizedZoom(newNormalizedZoom, ZO_WorldMapScroll:GetCenter())
        if triggerMagnitude > 0 and self.canZoomInFurther then
            PlaySound(SOUNDS.MAP_ZOOM_IN)
        elseif triggerMagnitude < 0 and self.canZoomOutFurther then
            PlaySound(SOUNDS.MAP_ZOOM_OUT)
        end
    end
end

function ZO_MapPanAndZoom:SetLockedNormalizedZoom(normalizedZoom, mouseX, mouseY)
    if normalizedZoom ~= self.currentNormalizedZoom then
        self:ClearTargetOffset()

        local cX, cY = ZO_WorldMapScroll:GetCenter()
        local oldMapSize = ZO_WorldMapContainer:GetHeight()
        self.lockPointX = mouseX - cX
        self.lockPointY = mouseY - cY
        local oldContainerOffsetX, oldContainerOffsetY = CalculateContainerAnchorOffsets()
        self.lockPointNX = (self.lockPointX - oldContainerOffsetX) / oldMapSize
        self.lockPointNY = (self.lockPointY - oldContainerOffsetY) / oldMapSize

        self:SetTargetNormalizedZoom(normalizedZoom)
    end
end

function ZO_MapPanAndZoom:AddCurrentOffsetDelta(deltaX, deltaY)
    local cx, cy = CalculateContainerAnchorOffsets()

    local nextOffsetX = zo_clamp(cx + deltaX, -g_mapOverflowMaxX, g_mapOverflowMaxX)
    local nextOffsetY = zo_clamp(cy + deltaY, -g_mapOverflowMaxY, g_mapOverflowMaxY)

    self:SetCurrentOffset(nextOffsetX, nextOffsetY)
end

function ZO_MapPanAndZoom:SetCurrentOffset(offsetX, offsetY)
    self:ClearLockPoint()
    self:ClearTargetOffset()
    ZO_WorldMapContainer:SetAnchor(CENTER, nil, CENTER, offsetX, offsetY)
end

function ZO_MapPanAndZoom:SetTargetOffset(offsetX, offsetY)
    self:ClearLockPoint()
    self.targetOffsetX = offsetX
    self.targetOffsetY = offsetY
end

function ZO_MapPanAndZoom:AddTargetOffsetDelta(deltaX, deltaY)
    local cx, cy = CalculateContainerAnchorOffsets()

    local nextOffsetX = zo_clamp((self.targetOffsetX or cx) + deltaX, -g_mapOverflowMaxX, g_mapOverflowMaxX)
    local nextOffsetY = zo_clamp((self.targetOffsetY or cy) + deltaY, -g_mapOverflowMaxY, g_mapOverflowMaxY)

    self:SetTargetOffset(nextOffsetX, nextOffsetY)
end

function ZO_MapPanAndZoom:SetFinalTargetOffset(offsetX, offsetY, targetNormalizedZoom)
    local ratio = self:ComputeCurvedZoom(targetNormalizedZoom) / self:GetCurrentCurvedZoom()
    self:SetTargetOffset(offsetX / ratio, offsetY / ratio)
end

function ZO_MapPanAndZoom:HasLockPoint()
    return self.lockPointX ~= nil
end

function ZO_MapPanAndZoom:HasTargetOffset()
    return self.targetOffsetX ~= nil or self.targetOffsetY ~= nil
end

function ZO_MapPanAndZoom:HasTargetZoom()
    return self.targetNormalizedZoom ~= nil
end

function ZO_MapPanAndZoom:GetNormalizedPositionFocusZoomAndOffset(normalizedX, normalizedY, useCurrentZoom)
    if normalizedX and normalizedY and ZO_WorldMap_IsNormalizedPointInsideMapBounds(normalizedX, normalizedY) then
        local targetNormalizedZoom = useCurrentZoom and self.currentNormalizedZoom or 1
        local curvedTargetZoom = self:ComputeCurvedZoom(targetNormalizedZoom)

        local zoomedNX = normalizedX * curvedTargetZoom
        local zoomedNY = normalizedY * curvedTargetZoom
        local borderSizeN = (curvedTargetZoom - 1) / 2
        local offsetNX = 0.5 + borderSizeN - zoomedNX
        local offsetNY = 0.5 + borderSizeN - zoomedNY

        if not self.allowPanPastMapEdge then
            offsetNX = zo_clamp(offsetNX, -borderSizeN, borderSizeN)
            offsetNY = zo_clamp(offsetNY, -borderSizeN, borderSizeN)
        end

        local offsetX = offsetNX * ZO_WorldMapScroll:GetWidth()
        local offsetY = offsetNY * ZO_WorldMapScroll:GetHeight()

        return targetNormalizedZoom, offsetX, offsetY
    end
end

function ZO_MapPanAndZoom:GetPinFocusZoomAndOffset(pin, useCurrentZoom)
    if pin then
        local x, y = pin:GetNormalizedPosition()
        return self:GetNormalizedPositionFocusZoomAndOffset(x, y, useCurrentZoom)
    end
end

function ZO_MapPanAndZoom:PanToPin(pin, useCurrentZoom)
    if self.pendingInitializeMap then
        self.pendingPanToPin = pin
        self.pendingPanToPinZoomMode = useCurrentZoom
    else
        local targetNormalizedZoom, offsetX, offsetY = self:GetPinFocusZoomAndOffset(pin, useCurrentZoom)
        if targetNormalizedZoom then
            self:SetFinalTargetOffset(offsetX, offsetY, targetNormalizedZoom)
            self:SetTargetNormalizedZoom(targetNormalizedZoom)
        end
    end
end

function ZO_MapPanAndZoom:PanToNormalizedPosition(positionX, positionY, useCurrentZoom)
    if self.pendingInitializeMap then
        self.pendingPanToNormalizedPosition = { positionX = positionX, positionY = positionY }
        self.pendingPanToNormalizedPositionZoomMode = useCurrentZoom
    else
        local targetNormalizedZoom, offsetX, offsetY = self:GetNormalizedPositionFocusZoomAndOffset(positionX, positionY, useCurrentZoom)
        if targetNormalizedZoom then
            self:SetFinalTargetOffset(offsetX, offsetY, targetNormalizedZoom)
            self:SetTargetNormalizedZoom(targetNormalizedZoom)
        end
    end
end

function ZO_MapPanAndZoom:JumpToPin(pin, useCurrentZoom)
    if self.pendingInitializeMap then
        self.pendingJumpToPin = pin
        self.pendingJumpToPinZoomMode = useCurrentZoom
        return false
    else
        local targetNormalizedZoom, offsetX, offsetY = self:GetPinFocusZoomAndOffset(pin, useCurrentZoom)
        if targetNormalizedZoom then
            self:SetCurrentNormalizedZoom(targetNormalizedZoom)
            self:SetCurrentOffset(offsetX, offsetY)
            return true
        end
        return false
    end
end

function ZO_MapPanAndZoom:JumpToPinWhenAvailable(findPinFunction)
    local pin = findPinFunction()
    if pin then
        g_mapPanAndZoom:JumpToPin(pin)
    else
        self.jumpWhenAvailableFindPinFunction = findPinFunction
        self.jumpWhenAvailableExpiresAt = GetFrameTimeSeconds() + ZO_MapPanAndZoom.WHEN_AVAILABLE_LIMIT
    end
end

function ZO_MapPanAndZoom:ClearJumpToPinWhenAvailable()
    self.jumpWhenAvailableFindPinFunction = nil
    self.jumpWhenAvailableExpiresAt = nil
end

function ZO_MapPanAndZoom:Update(currentTime)
    if self.pendingInitializeMap then
        self:InitializeMap(self.pendingInitializeMapWasNavigateIn)
    end

    self.currentNormalizedZoom = zo_clamp(self.currentNormalizedZoom, 0, 1)

    if self:HasTargetZoom() then
        local oldNormalizedZoom = self.currentNormalizedZoom

        if self.targetNormalizedZoom >= 0 and zo_abs(self.currentNormalizedZoom - self.targetNormalizedZoom) < .001 then
            self:SetCurrentNormalizedZoomInternal(self.targetNormalizedZoom)
            self:ClearTargetNormalizedZoom()
            self:ClearLockPoint()
        else
            self:SetCurrentNormalizedZoomInternal(zo_deltaNormalizedLerp(self.currentNormalizedZoom, self.targetNormalizedZoom, LERP_FACTOR))
        end

        local ratio = self:GetCurrentCurvedZoom() / self:ComputeCurvedZoom(oldNormalizedZoom)

        if not self:HasLockPoint() then
            local offsetX, offsetY = CalculateContainerAnchorOffsets()
            self.targetOffsetX = (self.targetOffsetX or offsetX) * ratio
            self.targetOffsetY = (self.targetOffsetY or offsetY) * ratio

            ZO_WorldMapContainer:SetAnchor(CENTER, nil, CENTER, offsetX * ratio, offsetY * ratio)
        end
    end

    local offsetX, offsetY = CalculateContainerAnchorOffsets()

    if self:HasLockPoint() then
        local mapSize = ZO_WorldMapScroll:GetHeight() * self:GetCurrentCurvedZoom()
        local newLockPointX = self.lockPointNX * mapSize
        local newLockPointY = self.lockPointNY * mapSize
        local newContainerOffsetX = self.lockPointX - newLockPointX
        local newContainerOffsetY = self.lockPointY - newLockPointY

        local nextOffsetX = zo_clamp(newContainerOffsetX, -g_mapOverflowMaxX, g_mapOverflowMaxX)
        local nextOffsetY = zo_clamp(newContainerOffsetY, -g_mapOverflowMaxY, g_mapOverflowMaxY)

        ZO_WorldMapContainer:SetAnchor(CENTER, nil, CENTER, nextOffsetX, nextOffsetY)
    elseif self:HasTargetOffset() then
        local amount = g_dragging and 1.0 or LERP_FACTOR
        self.reachedTargetOffset = true

        if self.targetOffsetX then
            if zo_abs(self.targetOffsetX - offsetX) < 1 then
                self.targetOffsetX = nil
            else
                offsetX = zo_deltaNormalizedLerp(offsetX, self.targetOffsetX, amount)
                self.reachedTargetOffset = false
            end
        end

        if self.targetOffsetY then
            if zo_abs(self.targetOffsetY - offsetY) < 1 then
                self.targetOffsetY = nil
            else
                offsetY = zo_deltaNormalizedLerp(offsetY, self.targetOffsetY, amount)
                self.reachedTargetOffset = false
            end
        end

        local nextOffsetX = zo_clamp(offsetX, -g_mapOverflowMaxX, g_mapOverflowMaxX)
        local nextOffsetY = zo_clamp(offsetY, -g_mapOverflowMaxY, g_mapOverflowMaxY)

        ZO_WorldMapContainer:SetAnchor(CENTER, nil, CENTER, nextOffsetX, nextOffsetY)
    end

    if self.jumpWhenAvailableExpiresAt ~= nil and currentTime > self.jumpWhenAvailableExpiresAt then
        self:ClearJumpToPinWhenAvailable()
    end
end

function ZO_MapPanAndZoom:ReachedTargetOffset()
    return self.reachedTargetOffset
end

function ZO_MapPanAndZoom:CanMapZoom()
    local mapContentType = GetMapContentType()
    return mapContentType ~= MAP_CONTENT_DUNGEON and mapContentType ~= MAP_CONTENT_BATTLEGROUND
end

--Events

function ZO_MapPanAndZoom:OnPinCreated()
    if self.jumpWhenAvailableFindPinFunction then
        local pin = self.jumpWhenAvailableFindPinFunction()
        if pin then
            self:ClearJumpToPinWhenAvailable()
            self:JumpToPin(pin)
        end
    end
end

function ZO_MapPanAndZoom:OnWorldMapChanged(wasNavigateIn)
    self:InitializeMap(wasNavigateIn)
end

function ZO_MapPanAndZoom:OnWorldMapShowing()
    if not g_playerChoseCurrentMap then
        if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
            CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
        end

        local pin = g_mapPinManager:GetPlayerPin()
        self:JumpToPin(pin, USE_CURRENT_ZOOM)
    end
end

local g_gamepadMap
local GamepadMap = ZO_Object:Subclass()

function GamepadMap:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function GamepadMap:Initialize()
    self.GAMEPAD_MAP_MOVE_SCALE = 15
    self.FREE_MOTION_THRESHOLD_SQ = 2
    self.NAVIGATE_WAIT_DURATION = 0.6
    self.NAVIGATE_DISABLE_ZOOM_DURATION = 0.5
end

function GamepadMap:UpdateDirectionalInput()
    if IsInGamepadPreferredMode() and not WORLD_MAP_MANAGER:IsPreventingMapNavigation() then
        --Only show the center reticle if we have input to move
        local isInputAvailable = DIRECTIONAL_INPUT:IsAvailable(ZO_DI_LEFT_STICK) or DIRECTIONAL_INPUT:IsAvailable(ZO_DI_DPAD)
        ZO_WorldMapCenterPoint:SetHidden(not isInputAvailable)

        local zoomInMagnitude = GetGamepadRightTriggerMagnitude()
        local zoomOutMagnitude = GetGamepadLeftTriggerMagnitude()
        local zoomDelta = zoomInMagnitude - zoomOutMagnitude
        local wantsToZoom = zoomDelta ~= 0

        local motionX, motionY = DIRECTIONAL_INPUT:GetXY(ZO_DI_LEFT_STICK, ZO_DI_DPAD)
        g_dragging = (motionX ~= 0 or motionY ~= 0)

        if g_dragging or wantsToZoom then
            g_stickyPin:ClearStickyPin(g_mapPanAndZoom)
            WORLD_MAP_MANAGER:StopAutoNavigationMovement()
        end

        local reachedTarget = g_mapPanAndZoom:ReachedTargetOffset()
        local isAutoNavigating = WORLD_MAP_MANAGER:IsAutoNavigating()
        g_stickyPin:SetEnabled(reachedTarget and not isAutoNavigating)

        local normalizedFrameDelta = GetFrameDeltaNormalizedForTargetFramerate()
        local deltaX = -motionX * self.GAMEPAD_MAP_MOVE_SCALE * normalizedFrameDelta
        local deltaY = motionY * self.GAMEPAD_MAP_MOVE_SCALE * normalizedFrameDelta

        local navigateInAt = self.navigateInAt
        local navigateOutAt = self.navigateOutAt
        self.navigateInAt = nil
        self.navigateOutAt = nil

        local performedZoom = false
        if wantsToZoom then
            performedZoom = self:TryZoom(zoomDelta, GetFrameDeltaSeconds(), deltaX, deltaY, navigateInAt, navigateOutAt)
        end

        if g_dragging and not performedZoom then
            g_mapPanAndZoom:AddCurrentOffsetDelta(deltaX, deltaY)
        end

        if not (g_dragging or wantsToZoom) then
            local motionMagSq = (motionX * motionX) + (motionY * motionY)
            local stickyPin = g_stickyPin:GetStickyPin()
            if reachedTarget and stickyPin and motionMagSq < self.FREE_MOTION_THRESHOLD_SQ then
                g_stickyPin:MoveToStickyPin(g_mapPanAndZoom)
            end
        end

        self.lastUpdate = GetFrameTimeSeconds()
    else
        ZO_WorldMapCenterPoint:SetHidden(true)
    end
end

function GamepadMap:TryZoom(zoomDelta, normalizedFrameDelta, deltaX, deltaY, navigateInAt, navigateOutAt)
    if not self:IsZoomDisabledForDuration() then
        local currentFrameTimeS = GetFrameTimeSeconds()
        if zoomDelta > 0 then
            if g_mapPanAndZoom:CanZoomInFurther() then
                g_mapPanAndZoom:AddCurrentOffsetDelta(deltaX, deltaY)
                g_mapPanAndZoom:AddZoomDeltaGamepad(zoomDelta, normalizedFrameDelta)
                return true
            else
                local canNavigateIn = g_mouseoverMapBlobManager:IsShowingMapRegionBlob() and WORLD_MAP_MANAGER:IsMapChangingAllowed(CONSTANTS.ZOOM_DIRECTION_IN)
                if navigateInAt == nil then
                    if canNavigateIn then
                        PlaySound(SOUNDS.GAMEPAD_MAP_START_MAP_CHANGE)
                        self.navigateInAt = currentFrameTimeS + self.NAVIGATE_WAIT_DURATION
                        return false
                    end
                else
                    if currentFrameTimeS > navigateInAt then
                        if canNavigateIn then
                            PlaySound(SOUNDS.GAMEPAD_MAP_COMPLETE_MAP_CHANGE)
                            ZO_WorldMap_MouseUp(nil, MOUSE_BUTTON_INDEX_LEFT, true)
                            self:DisableZoomingFor(self.NAVIGATE_DISABLE_ZOOM_DURATION)
                            return false
                        end
                    else
                        self.navigateInAt = navigateInAt
                        return false
                    end
                end
            end
        else
            local canNavigateOut = not IsShowingCosmicMap() and WORLD_MAP_MANAGER:IsMapChangingAllowed(CONSTANTS.ZOOM_DIRECTION_OUT)
            if g_mapPanAndZoom:CanZoomOutFurther() then
                g_mapPanAndZoom:AddCurrentOffsetDelta(deltaX, deltaY)
                g_mapPanAndZoom:AddZoomDeltaGamepad(zoomDelta, normalizedFrameDelta)
                return true
            else
                if navigateOutAt == nil then
                    if canNavigateOut then
                        PlaySound(SOUNDS.GAMEPAD_MAP_START_MAP_CHANGE)
                        self.navigateOutAt = currentFrameTimeS + self.NAVIGATE_WAIT_DURATION
                        return false
                    end
                else
                    if currentFrameTimeS > navigateOutAt then
                        if canNavigateOut then
                            PlaySound(SOUNDS.GAMEPAD_MAP_COMPLETE_MAP_CHANGE)
                            ZO_WorldMap_MouseUp(nil, MOUSE_BUTTON_INDEX_RIGHT, true)
                            self:DisableZoomingFor(self.NAVIGATE_DISABLE_ZOOM_DURATION)
                            return false
                        end
                    else
                        self.navigateOutAt = navigateOutAt
                        return false
                    end
                end
            end
        end
    end

    return false
end

function GamepadMap:DisableZoomingFor(seconds)
    self.canZoomAgainAt = GetFrameTimeSeconds() + seconds
end

function GamepadMap:IsZoomDisabledForDuration()
    if self.canZoomAgainAt ~= nil then
        if GetFrameTimeSeconds() < self.canZoomAgainAt then
            return true
        else
            self.canZoomAgainAt = nil
            return false
        end
    end
    return false
end

function GamepadMap:StopMotion()
    g_stickyPin:ClearStickyPin(g_mapPanAndZoom)
    g_stickyPin:SetEnabled(false)

    g_mapPanAndZoom:ClearTargetOffset()
    WORLD_MAP_MANAGER:StopAutoNavigationMovement()
end

--Local XML

function ZO_MapPanAndZoom:OnMouseWheel(delta)
    local mouseX, mouseY = GetUIMousePosition()
    self:AddZoomDelta(delta, mouseX, mouseY)
end

--Global XML

function ZO_WorldMapZoomMinus_OnClicked()
    PlaySound(SOUNDS.MAP_ZOOM_OUT)
    g_mapPanAndZoom:Step(-1)
end

function ZO_WorldMapZoomPlus_OnClicked()
    PlaySound(SOUNDS.MAP_ZOOM_IN)
    g_mapPanAndZoom:Step(1)
end

function ZO_WorldMapZoom_OnMouseWheel(delta)
    g_mapPanAndZoom:Step(delta)
end

function ZO_WorldMapZoom_OnInitialized(self)
    g_stickyPin = WorldMapStickyPin:New()
    g_mapPanAndZoom = ZO_MapPanAndZoom:New(self)
    g_gamepadMap = GamepadMap:New()
end

--Main Update Loop
local Update, ResetMouseIsOverWorldMap
do
    local mouseWasOverWorldMapScroll = false
    local mouseIsOverWorldMapScroll = false
    local nextMouseOverUpdateS

    function ResetMouseIsOverWorldMap()
        mouseWasOverWorldMapScroll = false
        mouseIsOverWorldMapScroll = false
    end

    function Update(map, currentTimeS)
        if g_pinUpdateTime == nil then g_pinUpdateTime = currentTimeS end
        if g_refreshUpdateTime == nil then g_refreshUpdateTime = currentTimeS end

        if g_refreshUpdateTime <= currentTimeS then
            g_refreshUpdateTime = currentTimeS + CONSTANTS.MAP_REFRESH_UPDATE_DELAY

            -- If the player is just wandering around the world, with their map open, then refresh it every so often so that
            -- it's showing the appropriate location for where they are.  If they actually picked a loction, then avoid this update.
            if not g_playerChoseCurrentMap then
                if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
                    CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
                    local pin = g_mapPinManager:GetPlayerPin()
                    g_mapPanAndZoom:JumpToPin(pin)
                end
            end
        end

        if g_pinUpdateTime <= currentTimeS then
            g_pinUpdateTime = currentTimeS + CONSTANTS.PIN_UPDATE_DELAY

            --if we're resizing the map, we update this continuously
            if not g_resizingMap then
                UpdateMovingPins()
            end
        end

        if g_resizingMap then
            local windowWidth, windowHeight = ZO_WorldMap:GetDimensions()
            local modeData = WORLD_MAP_MANAGER:GetModeData()
            if modeData.keepSquare then
                local conformedWidth, conformedHeight = GetSquareMapWindowDimensions((g_resizeIsWidthDriven and windowWidth or windowHeight), g_resizeIsWidthDriven)
                SetMapWindowSize(conformedWidth, conformedHeight)
            else
                SetMapWindowSize(windowWidth, windowHeight)
            end

            UpdateMovingPins()
        end

        g_mapPanAndZoom:Update(currentTimeS)

        if nextMouseOverUpdateS == nil or currentTimeS > nextMouseOverUpdateS then
            UpdateMouseOverPins()
            nextMouseOverUpdateS = currentTimeS + 0.3
        end

        if WORLD_MAP_MANAGER:IsAutoNavigating() then
            if WORLD_MAP_MANAGER:ShouldShowAutoNavigateHighlightBlob() then
                local FORCE_SHOW_BLOB = true
                local normalizedX, normalizedY = GetAutoMapNavigationNormalizedPositionForCurrentMap()
                g_mouseoverMapBlobManager:Update(normalizedX, normalizedY, FORCE_SHOW_BLOB)
            end
        else
            local normalizedX, normalizedY = NormalizePreferredMousePositionToMap()
            g_mouseoverMapBlobManager:Update(normalizedX, normalizedY)
        end

        mouseIsOverWorldMapScroll = IsMouseOverMap()
        if mouseIsOverWorldMapScroll ~= mouseWasOverWorldMapScroll then
            g_keybindStrips.mouseover:MarkDirty()
            g_keybindStrips.gamepad:MarkDirty()
        end
        mouseWasOverWorldMapScroll = mouseIsOverWorldMapScroll

        g_keybindStrips.mouseover:CleanDirty()
        g_keybindStrips.PC:CleanDirty()
        if g_keybindStrips.gamepad:CleanDirty() then
            ZO_WorldMap_UpdateInteractKeybind_Gamepad()
        end
        g_mapRefresh:UpdateRefreshGroups()

        ZO_WorldMap_RefreshRespawnTimer(currentTimeS)

        if g_hideTooltipsAt and currentTimeS * 1000 > g_hideTooltipsAt then
            g_hideTooltipsAt = nil
            HideAllTooltips()
        end

        WORLD_MAP_MANAGER:Update(currentTimeS)
    end
end

-- If a pin group is here, it will override filters on dungeon maps
-- Recent design change calls for hiding wayshrines on dungeon maps
local hiddenPinGroupsOnDungeonMaps =
{
    [MAP_FILTER_WAYSHRINES] = true,
}

function ZO_WorldMap_IsPinGroupShown(pinGroup)
    local mapContentType = GetMapContentType()

    -- Dungeon maps supercede map context/mode
    if mapContentType == MAP_CONTENT_DUNGEON and hiddenPinGroupsOnDungeonMaps[pinGroup] then
        return false
    end

    local value = WORLD_MAP_MANAGER:GetFilterValue(pinGroup)
    if value ~= nil then
        return value ~= false
    end

    return true
end

local function IsMapShowingBattlegroundContext(bgContext)
    return (g_queryType == BGQUERY_LOCAL and IsLocalBattlegroundContext(bgContext))
            or (g_queryType == BGQUERY_ASSIGNED_CAMPAIGN and IsAssignedBattlegroundContext(bgContext))
end

local function IsPresentlyShowingKeeps()
    return GetMapFilterType() == MAP_FILTER_TYPE_AVA_CYRODIIL or GetMapFilterType() == MAP_FILTER_TYPE_AVA_IMPERIAL
end

local function AddKeep(keepId, bgContext)
    local historyPercent = ZO_WorldMap_GetHistoryPercentToUse()
    local pinType, locX, locY = GetHistoricalKeepPinInfo(keepId, bgContext, historyPercent)
    if pinType ~= MAP_PIN_TYPE_INVALID then
        local keepUnderAttack = GetHistoricalKeepUnderAttack(keepId, bgContext, historyPercent)
        local keepUnderAttackPinType = ZO_MapPin.GetUnderAttackPinForKeepPin(pinType)

        if ZO_WorldMap_IsNormalizedPointInsideMapBounds(locX, locY) then
            local keepType = GetKeepType(keepId)
            if ZO_WorldMap_IsPinGroupShown(MAP_FILTER_RESOURCE_KEEPS) or keepType ~= KEEPTYPE_RESOURCE then
                if keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT and GetCurrentMapIndex() ~= g_imperialCityMapIndex then
                    return
                end

                if IsMapShowingBattlegroundContext(bgContext) then
                    local underAttackPin = true
                    local notUnderAttackPin = false

                    local existingKeepPin = g_mapPinManager:FindPin("keep", keepId, notUnderAttackPin)
                    if not existingKeepPin then
                        local tag = ZO_MapPin.CreateKeepPinTag(keepId, bgContext, notUnderAttackPin)
                        g_mapPinManager:CreatePin(pinType, tag, locX, locY)

                        if keepUnderAttack then
                            tag = ZO_MapPin.CreateKeepPinTag(keepId, bgContext, underAttackPin)
                            g_mapPinManager:CreatePin(keepUnderAttackPinType, tag, locX, locY)
                        end
                    end
                end
            end
        end
    end
end

local function RefreshKeepUnderAttack(keepId, bgContext)
    local UNDER_ATTACK_PIN = true
    local NOT_UNDER_ATTACK_PIN = false
    local existingKeepPin = g_mapPinManager:FindPin("keep", keepId, NOT_UNDER_ATTACK_PIN)
    if existingKeepPin then
        local historyPercent = ZO_WorldMap_GetHistoryPercentToUse()
        local keepUnderAttack = GetHistoricalKeepUnderAttack(keepId, bgContext, historyPercent)
        local existingUnderAttackKeepPin = g_mapPinManager:FindPin("keep", keepId, UNDER_ATTACK_PIN)
        local hasUnderAttackPin = existingUnderAttackKeepPin ~= nil
        if keepUnderAttack ~= hasUnderAttackPin then
            if keepUnderAttack then
                --Add under attack pin
                local pinType, locX, locY = GetHistoricalKeepPinInfo(keepId, bgContext, historyPercent)
                local keepUnderAttackPinType = ZO_MapPin.GetUnderAttackPinForKeepPin(pinType)
                local tag = ZO_MapPin.CreateKeepPinTag(keepId, bgContext, UNDER_ATTACK_PIN)
                g_mapPinManager:CreatePin(keepUnderAttackPinType, tag, locX, locY)
            else
                --Remove under attack pin
                g_mapPinManager:RemovePins("keep", keepId, UNDER_ATTACK_PIN)
            end
        end
    end
end

local function RefreshKeep(keepId, bgContext)
    g_mapPinManager:RemovePins("keep", keepId)
    ZO_WorldMap_RefreshAccessibleAvAGraveyards()

    if IsPresentlyShowingKeeps() then
        AddKeep(keepId, bgContext)
    end
end

local function RefreshKeeps()
    g_mapPinManager:RemovePins("keep")
    ZO_WorldMap_RefreshAccessibleAvAGraveyards()

    if IsPresentlyShowingKeeps() then
        local numKeeps = GetNumKeeps()
        for i = 1, numKeeps do
            local keepId, bgContext = GetKeepKeysByIndex(i)
            AddKeep(keepId, bgContext)
        end
    end
end

local function RefreshMapPings()
    g_mapPinManager:RemovePins("pings")

    if not IsShowingCosmicMap() then
        -- We don't want these manual player pings showing up on the Aurbis
        for i = 1, GROUP_SIZE_MAX do
            local unitTag = ZO_Group_GetUnitTagForGroupIndex(i)
            local x, y = GetMapPing(unitTag)

            if x ~= 0 and y ~= 0 then
                g_mapPinManager:CreatePin(MAP_PIN_TYPE_PING, unitTag, x, y)
            end
        end

        -- Add rally point
        local x, y = GetMapRallyPoint()

        if x ~= 0 and y ~= 0 then
            g_mapPinManager:CreatePin(MAP_PIN_TYPE_RALLY_POINT, "rally", x, y)
        end

        -- Add Player Waypoint
        x, y = GetMapPlayerWaypoint()
        if x ~= 0 and y ~= 0 then
            g_mapPinManager:CreatePin(MAP_PIN_TYPE_PLAYER_WAYPOINT , "waypoint", x, y)
        end

        -- Add Quest Ping
        if g_questPingData then
            local pins = {}
            g_mapPinManager:AddPinsToArray(pins, "quest", g_questPingData.questIndex)
            for _, pin in ipairs(pins) do
                if pin:DoesQuestDataMatchQuestPingData() then
                    local tag = ZO_MapPin.CreateQuestPinTag(g_questPingData.questIndex, g_questPingData.stepIndex, g_questPingData.conditionIndex)
                    local xLoc, yLoc = pin:GetNormalizedPosition()
                    g_mapPinManager:CreatePin(MAP_PIN_TYPE_QUEST_PING, tag, xLoc, yLoc)
                end
            end
        end
    end

    -- Add auto navigation target, and we do want this on the Aurbis
    if HasAutoMapNavigationTarget() then
        local normalizedX, normalizedY = GetAutoMapNavigationNormalizedPositionForCurrentMap()
        g_mapPinManager:CreatePin(MAP_PIN_TYPE_AUTO_MAP_NAVIGATION_PING, "pings", normalizedX, normalizedY)
    end
end

do
    local IS_OBJECTIVE_TYPE_SHOWN_IN_AVA =
    {
        [OBJECTIVE_ARTIFACT_OFFENSIVE] = true,
        [OBJECTIVE_ARTIFACT_DEFENSIVE] = true,
        [OBJECTIVE_DAEDRIC_WEAPON] = true,
    }
    function ZO_WorldMap_IsObjectiveShown(keepId, objectiveId, bgContext)
        if IsBattlegroundObjective(keepId, objectiveId, bgContext) then
            return true
        else
            local _, objectiveType = GetObjectiveInfo(keepId, objectiveId, bgContext)
            return IS_OBJECTIVE_TYPE_SHOWN_IN_AVA[objectiveType]
        end
    end
end

local function RefreshObjectives()
    g_mapPinManager:RemovePins("objective")
    ZO_ClearNumericallyIndexedTable(g_objectiveMovingPins)

    local mapFilterType = GetMapFilterType()
    if mapFilterType ~= MAP_FILTER_TYPE_AVA_CYRODIIL and mapFilterType ~= MAP_FILTER_TYPE_BATTLEGROUND then
        return
    end

    local numObjectives = GetNumObjectives()

    local worldMapAvAPinsShown = ZO_WorldMap_IsPinGroupShown(MAP_FILTER_AVA_OBJECTIVES)

    for i = 1, numObjectives do
        local keepId, objectiveId, bgContext = GetObjectiveIdsForIndex(i)
        local isEnabled = IsObjectiveEnabled(keepId, objectiveId, bgContext)

        if isEnabled then
            local isVisible = IsObjectiveObjectVisible(keepId, objectiveId, bgContext)
            if ZO_WorldMap_IsObjectiveShown(keepId, objectiveId, bgContext) and IsMapShowingBattlegroundContext(bgContext) then
                --spawn locations
                local spawnPinType, spawnX, spawnY = GetObjectiveSpawnPinInfo(keepId, objectiveId, bgContext)
                if spawnPinType ~= MAP_PIN_TYPE_INVALID then
                    if worldMapAvAPinsShown then
                        if ZO_WorldMap_IsNormalizedPointInsideMapBounds(spawnX, spawnY) then
                            local spawnTag = ZO_MapPin.CreateObjectivePinTag(keepId, objectiveId, bgContext)
                            g_mapPinManager:CreatePin(spawnPinType, spawnTag, spawnX, spawnY)
                        end
                    end
                end

                --return locations
                local returnPinType, returnX, returnY, returnContinuousUpdate = GetObjectiveReturnPinInfo(keepId, objectiveId, bgContext)
                if returnPinType ~= MAP_PIN_TYPE_INVALID then
                    local returnTag = ZO_MapPin.CreateObjectivePinTag(keepId, objectiveId, bgContext)
                    local returnPin = g_mapPinManager:CreatePin(returnPinType, returnTag, returnX, returnY)

                    if returnContinuousUpdate then
                        table.insert(g_objectiveMovingPins, returnPin)
                    end
                end

                -- current locations
                local pinType, currentX, currentY, continuousUpdate = GetObjectivePinInfo(keepId, objectiveId, bgContext)
                if isVisible and pinType ~= MAP_PIN_TYPE_INVALID then
                    if worldMapAvAPinsShown then
                        if ZO_WorldMap_IsNormalizedPointInsideMapBounds(currentX, currentY) then
                            local objectiveTag = ZO_MapPin.CreateObjectivePinTag(keepId, objectiveId, bgContext)
                            local objectivePin = g_mapPinManager:CreatePin(pinType, objectiveTag, currentX, currentY)

                            if objectivePin then
                                local auraPinType = GetObjectiveAuraPinInfo(keepId, objectiveId, bgContext)
                                local auraPin
                                if auraPinType ~= MAP_PIN_TYPE_INVALID then
                                    local auraTag = ZO_MapPin.CreateObjectivePinTag(keepId, objectiveId, bgContext)
                                    auraPin = g_mapPinManager:CreatePin(auraPinType, auraTag, currentX, currentY)
                                    objectivePin:AddScaleChild(auraPin)
                                end

                                if continuousUpdate then
                                    table.insert(g_objectiveMovingPins, objectivePin)
                                    if auraPin then
                                        table.insert(g_objectiveMovingPins, auraPin)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function ZO_WorldMap_RefreshKillLocations()
    g_mapPinManager:RemovePins("killLocation")
    RemoveMapPinsInRange(MAP_PIN_TYPE_TRI_BATTLE_SMALL, MAP_PIN_TYPE_EBONHEART_VS_DAGGERFALL_LARGE)

    --spawn locations
    for i = 1, GetNumKillLocations() do
        local pinType, normalizedX, normalizedY = GetKillLocationPinInfo(i)
        if pinType ~= MAP_PIN_TYPE_INVALID then
            if ZO_WorldMap_IsPinGroupShown(MAP_FILTER_KILL_LOCATIONS) then
                if ZO_WorldMap_IsNormalizedPointInsideMapBounds(normalizedX, normalizedY) then
                    g_mapPinManager:CreatePin(pinType, i, normalizedX, normalizedY)
                end
            end

            --Minimap
            --param 1 is the C index of the location
            AddMapPin(pinType, i-1)
        end
    end
end

do
    local MAPS_WITHOUT_WORLD_EVENT_PINS =
    {
        [MAPTYPE_WORLD] = true,
        [MAPTYPE_COSMIC] = true,
    }

    function ZO_WorldMap_DoesMapHideWorldEventPins()
        return MAPS_WITHOUT_WORLD_EVENT_PINS[GetMapType()]
    end
end

do
    local function GetNextWorldEventInstanceIdIter(state, var1)
        return GetNextWorldEventInstanceId(var1)
    end

    local function AddWorldEvent(worldEventInstanceId)
        if ZO_WorldMap_DoesMapHideWorldEventPins() then
            return
        end

        local numUnits = GetNumWorldEventInstanceUnits(worldEventInstanceId)
        for i = 1, numUnits do
            local unitTag = GetWorldEventInstanceUnitTag(worldEventInstanceId, i)
            local pinType = GetWorldEventInstanceUnitPinType(worldEventInstanceId, unitTag)
            if pinType ~= MAP_PIN_TYPE_INVALID then
                local xLoc, yLoc, _, isInCurrentMap = GetMapPlayerPosition(unitTag)
                if isInCurrentMap then
                    local tag = ZO_MapPin.CreateWorldEventUnitPinTag(worldEventInstanceId, unitTag)
                    g_mapPinManager:CreatePin(pinType, tag, xLoc, yLoc)
                end
            end
        end
    end

    function ZO_WorldMap_RefreshWorldEvent(worldEventInstanceId)
        g_mapPinManager:RemovePins("worldEventUnit", worldEventInstanceId)

        AddWorldEvent(worldEventInstanceId)
    end

    function ZO_WorldMap_RefreshWorldEvents()
        g_mapPinManager:RemovePins("worldEventUnit")

        for worldEventInstanceId in GetNextWorldEventInstanceIdIter do
            AddWorldEvent(worldEventInstanceId)
        end
    end
end

function ZO_WorldMap_RefreshRespawnTimer(currentTime)
    if g_nextRespawnTimeMS ~= 0 then
        local currentTimeMS = currentTime * 1000
        local formattedTimeRemaining = ""
        local isTimerHidden = true

        if currentTimeMS > g_nextRespawnTimeMS then
            -- hide the timer and refresh the forward camp pins (which turns the green hightlight back on)
            g_nextRespawnTimeMS = 0
            isTimerHidden = true

            ZO_WorldMap_RefreshForwardCamps()
            if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_RESPAWN) then
                ZO_WorldMap_RefreshAccessibleAvAGraveyards()
            end
        else
            if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_RESPAWN) then
                local secondsRemaining = (g_nextRespawnTimeMS - currentTimeMS) / 1000
                formattedTimeRemaining = ZO_FormatTimeAsDecimalWhenBelowThreshold(secondsRemaining)
                isTimerHidden = false
            else
                -- hide the timer when not in AvA-Respawn map mode
                isTimerHidden = true
            end
        end

        if IsInGamepadPreferredMode() then
            local timerText = isTimerHidden and "" or GetString(SI_MAP_FORWARD_CAMP_RESPAWN_COOLDOWN)
            local data =
            {
                data1HeaderText = timerText,
                data1Text = formattedTimeRemaining
            }
            GAMEPAD_GENERIC_FOOTER:Refresh(data)
        else
            ZO_WorldMapRespawnTimerValue:SetText(formattedTimeRemaining)
            WORLD_MAP_RESPAWN_TIMER_FRAGMENT_KEYBOARD:SetHiddenForReason("TimerInactive", isTimerHidden)
        end
    end
end

function ZO_WorldMap_RefreshForwardCamps()
    g_mapPinManager:RemovePins("forwardCamp")

    if GetMapFilterType() ~= MAP_FILTER_TYPE_AVA_CYRODIIL then
        return
    end
    if not ZO_WorldMap_IsPinGroupShown(MAP_FILTER_AVA_GRAVEYARDS) then return end

    for i = 1, GetNumForwardCamps(g_queryType) do
        local pinType, normalizedX, normalizedY, normalizedRadius, useable = GetForwardCampPinInfo(g_queryType, i)
        if ZO_WorldMap_IsNormalizedPointInsideMapBounds(normalizedX, normalizedY) then
            if not ZO_WorldMap_IsPinGroupShown(MAP_FILTER_AVA_GRAVEYARD_AREAS) then
                normalizedRadius = 0
            end
            g_mapPinManager:CreatePin(pinType, ZO_MapPin.CreateForwardCampPinTag(i), normalizedX, normalizedY, normalizedRadius)
        end
    end
end

function ZO_WorldMap_RefreshAccessibleAvAGraveyards()
    g_mapPinManager:RemovePins("AvARespawn")
    if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_RESPAWN) then
        if ZO_WorldMap_IsPinGroupShown(MAP_FILTER_AVA_GRAVEYARDS) then
            for i = 1, GetNumForwardCamps(g_queryType) do
                local _, normalizedX, normalizedY, normalizedRadius, useable = GetForwardCampPinInfo(g_queryType, i)
                if useable and ZO_WorldMap_IsNormalizedPointInsideMapBounds(normalizedX, normalizedY) then
                    g_mapPinManager:CreatePin(MAP_PIN_TYPE_FORWARD_CAMP_ACCESSIBLE, ZO_MapPin.CreateAvARespawnPinTag(i), normalizedX, normalizedY)
                end
            end
        end

        for i = 1, GetNumKeeps() do
            local keepId, _ = GetKeepKeysByIndex(i)
            if CanRespawnAtKeep(keepId) then
                local keepType = GetKeepType(keepId)
                local pinType
                if keepType == KEEPTYPE_BORDER_KEEP then
                    pinType = MAP_PIN_TYPE_RESPAWN_BORDER_KEEP_ACCESSIBLE
                elseif keepType == KEEPTYPE_TOWN then
                    pinType = MAP_PIN_TYPE_AVA_TOWN_GRAVEYARD_ACCESSIBLE
                elseif keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT then
                    if GetCurrentMapIndex() == g_imperialCityMapIndex then
                        pinType = MAP_PIN_TYPE_IMPERIAL_DISTRICT_GRAVEYARD_ACCESSIBLE
                    end
                elseif keepType == KEEPTYPE_OUTPOST then
                    pinType = MAP_PIN_TYPE_OUTPOST_GRAVEYARD_ACCESSIBLE
                else
                    pinType = MAP_PIN_TYPE_KEEP_GRAVEYARD_ACCESSIBLE
                end

                if pinType then
                    local _, locX, locY = GetKeepPinInfo(keepId, g_queryType)
                    g_mapPinManager:CreatePin(pinType, ZO_MapPin.CreateAvARespawnPinTag(i), locX, locY)
                end
            end
        end
    end
end

function ZO_WorldMap_RefreshGroupPins()
    g_mapPinManager:RemovePins("group")
    ZO_ClearTable(g_activeGroupPins)

    if ZO_WorldMap_IsPinGroupShown(MAP_FILTER_GROUP_MEMBERS) and not IsShowingCosmicMap() then
        for i = 1, GROUP_SIZE_MAX do
            local groupTag = ZO_Group_GetUnitTagForGroupIndex(i)
            if DoesUnitExist(groupTag) and not AreUnitsEqual("player", groupTag) and IsUnitOnline(groupTag) then
                local isGroupMemberHiddenByInstance = false
                -- We're in the same world as the group member, but a different instance
                if DoesCurrentMapMatchMapForPlayerLocation() and IsGroupMemberInSameWorldAsPlayer(groupTag) and not IsGroupMemberInSameInstanceAsPlayer(groupTag) then
                    -- If the instance we're in has it's own map, it's going to be a dungeon map.  Don't show on the map if we're on different instances
                    -- If it doesn't have it's own map, we're okay to show the group member regardless of instance
                    isGroupMemberHiddenByInstance = GetMapContentType() == MAP_CONTENT_DUNGEON
                end

                if not isGroupMemberHiddenByInstance then
                    local x, y, _, isInCurrentMap = GetMapPlayerPosition(groupTag)
                    if isInCurrentMap then
                        local isLeader = IsUnitGroupLeader(groupTag)
                        local tagData = groupTag
                        if IsUnitWorldMapPositionBreadcrumbed(groupTag) then
                            tagData =
                            {
                                groupTag = groupTag,
                                isBreadcrumb = true
                            }
                        end

                        local groupPin = g_mapPinManager:CreatePin(isLeader and MAP_PIN_TYPE_GROUP_LEADER or MAP_PIN_TYPE_GROUP, tagData)
                        if groupPin then
                            g_activeGroupPins[groupTag] = groupPin
                            groupPin:SetLocation(x, y)
                        end
                    end
                end
            end
        end
    end
end

-- currently keeping this function around for backward compatibility
function ZO_WorldMap_GetUnderAttackPinForKeepPin(keepPinType)
    return ZO_MapPin.GetUnderAttackPinForKeepPin(keepPinType)
end

-- This should only be called by RefreshAllPOI and RefreshSinglePOI as appropriate.
local function CreateSinglePOIPin(zoneIndex, poiIndex)
    local xLoc, zLoc, poiPinType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = GetPOIMapInfo(zoneIndex, poiIndex)

    if isShownInCurrentMap and (isDiscovered or isNearby) then
        if ZO_MapPin.POI_PIN_TYPES[poiPinType] then
            local poiType = GetPOIType(zoneIndex, poiIndex)

            if poiPinType ~= MAP_PIN_TYPE_POI_SEEN then
                -- Seen Wayshines are POIs, discovered Wayshrines are handled by AddWayshrines()
                -- Request was made by design to have houses and dungeons behave like wayshrines.
                if poiType == POI_TYPE_WAYSHRINE or poiType == POI_TYPE_HOUSE or poiType == POI_TYPE_GROUP_DUNGEON then
                    return
                end
            end

            local tag = ZO_MapPin.CreatePOIPinTag(zoneIndex, poiIndex, icon, linkedCollectibleIsLocked)
            g_mapPinManager:CreatePin(poiPinType, tag, xLoc, zLoc)
        end
    end
end

local function RefreshSinglePOI(zoneIndex, poiIndex)
    g_mapPinManager:RemovePins("poi", zoneIndex, poiIndex)

    if ZO_WorldMap_IsPinGroupShown(MAP_FILTER_OBJECTIVES) then
        CreateSinglePOIPin(zoneIndex, poiIndex)
    end
end

function ZO_WorldMap_RefreshAllPOIs()
    g_mapPinManager:RemovePins("poi")
    if ZO_WorldMap_IsPinGroupShown(MAP_FILTER_OBJECTIVES) then
        local zoneIndex = GetCurrentMapZoneIndex()
        for i = 1, GetNumPOIs(zoneIndex) do
            CreateSinglePOIPin(zoneIndex, i)
        end
    end
end

local function FloorLevelNavigationUpdate()
    local currentFloor, numFloors = GetMapFloorInfo()

    local showFloorControls = false
    local showLevelControls = false
    if IsInGamepadPreferredMode() then
        if not (ZO_WorldMap_IsWorldMapInfoShowing() or ZO_WorldMap_IsKeepInfoShowing()) then
            showFloorControls = numFloors > 0
            showLevelControls = not showFloorControls
        end
    else
        showFloorControls = numFloors > 0
    end

    ZO_WorldMapButtonsFloors:SetHidden(not showFloorControls)
    ZO_WorldMapButtonsLevels:SetHidden(not showLevelControls)

    if showFloorControls then
        ZO_WorldMapButtonsFloorsUp:SetEnabled(currentFloor ~= 1)
        ZO_WorldMapButtonsFloorsDown:SetEnabled(currentFloor ~= numFloors)
    end
end

function ZO_WorldMap_GetMapTitle()
    local titleText
    local mapName = GetMapName()
    local dungeonDifficulty = ZO_WorldMap_GetMapDungeonDifficulty()
    local isInAvAMap = IsPresentlyShowingKeeps()
    if isInAvAMap then
        if g_campaignId == 0 then
            titleText = zo_strformat(SI_WINDOW_TITLE_WORLD_MAP, mapName)
        else
            local campaignName = GetCampaignName(g_campaignId)
            titleText = zo_strformat(SI_WINDOW_TITLE_WORLD_MAP_WITH_CAMPAIGN_NAME, mapName, campaignName)
        end
    elseif dungeonDifficulty == DUNGEON_DIFFICULTY_NONE then
        titleText = zo_strformat(SI_WINDOW_TITLE_WORLD_MAP, mapName)
    else
        titleText = zo_strformat(SI_WINDOW_TITLE_WORLD_MAP_WITH_DUNGEON_DIFFICULTY, mapName, GetString("SI_DUNGEONDIFFICULTY", dungeonDifficulty))
    end
    return titleText
end

function ZO_WorldMap_GetMapDungeonDifficulty()
    if DoesCurrentMapShowPlayerWorld() and GetMapContentType() == MAP_CONTENT_DUNGEON then
        return GetCurrentZoneDungeonDifficulty()
    else
        return DUNGEON_DIFFICULTY_NONE
    end
end

function ZO_WorldMap_UpdateMap()
    PrepareBlobManagersForZoneUpdate()

    -- Set up base map
    g_mapTileManager:UpdateTextures()

    ZO_WorldMap.zoneName = GetMapName()

    local mapTitle = ZO_WorldMap_GetMapTitle()
    ZO_WorldMapTitle:SetText(mapTitle)
    ZO_WorldMapHeader_GamepadTitle:SetText(mapTitle)

    -- Set up map location names
    g_mapRefresh:RefreshAll("location")
    g_mapRefresh:RefreshAll("keepNetwork")
    ZO_WorldMap_RefreshAllPOIs()
    FloorLevelNavigationUpdate()
    ZO_WorldMap_RefreshObjectives()
    ZO_WorldMap_RefreshKeeps()
    RefreshMapPings()
    ZO_WorldMap_RefreshKillLocations()
    ZO_WorldMap_RefreshWayshrines()
    ZO_WorldMap_RefreshForwardCamps()
    g_mapRefresh:RefreshAll("worldEvent")

    g_mapPinManager:RefreshCustomPins()
    ResizeAndReanchorMap()

    WORLD_MAP_MANAGER:RefreshAll()
end

function ZO_Map_GetFastTravelNode()
    return g_fastTravelNodeIndex
end

local function ClearFastTravelNode()
    g_fastTravelNodeIndex = nil
end

local function UpdateMapCampaign()
    local lastCampaignId = g_campaignId
    local lastQueryType = g_queryType

    local localCampaignId = GetCurrentCampaignId()
    local isLocalCampaignImperialCity = IsImperialCityCampaign(localCampaignId)
    local currentMapFilterType = GetMapFilterType()

    if currentMapFilterType == MAP_FILTER_TYPE_AVA_CYRODIIL then
        if localCampaignId ~= 0 and not isLocalCampaignImperialCity then
            g_queryType = BGQUERY_LOCAL
        else
            -- If we aren't in a cyrodiil campaign, show the home campaign. If we don't have a campaign this will behave like we didn't pick a query type
            g_queryType = BGQUERY_ASSIGNED_CAMPAIGN
        end
    elseif currentMapFilterType == MAP_FILTER_TYPE_AVA_IMPERIAL then
        if localCampaignId ~= 0 and isLocalCampaignImperialCity then
            g_queryType = BGQUERY_LOCAL
        else
            -- IC campaigns can never be homed, so never query the home campaign here
            g_queryType = BGQUERY_UNKNOWN
        end
    elseif currentMapFilterType == MAP_FILTER_TYPE_BATTLEGROUND then
        -- BGs use campaign messaging to show objectives, but don't have an localCampaignId.
        -- This means the map should show objectives for the current BG, but not show a campaign name next to the map name.
        g_queryType = BGQUERY_LOCAL
    else
        g_queryType = BGQUERY_UNKNOWN
    end

    if g_queryType == BGQUERY_UNKNOWN then
        g_campaignId = 0
    elseif g_queryType == BGQUERY_LOCAL then
        g_campaignId = localCampaignId
    elseif g_queryType == BGQUERY_ASSIGNED_CAMPAIGN then
        g_campaignId = GetAssignedCampaignId()
    end

    if lastCampaignId ~= g_campaignId or lastQueryType ~= g_queryType then
        if ZO_WorldMap_IsWorldMapShowing() and currentMapFilterType == MAP_FILTER_TYPE_AVA_CYRODIIL then
            ZO_WorldMap_RefreshKeeps()
            g_mapRefresh:RefreshAll("objective")
            g_mapRefresh:RefreshAll("keepNetwork")
            ResetCampaignHistoryWindow(ZO_WorldMap_GetBattlegroundQueryType())
        end
        g_dataRegistration:Refresh()
        CALLBACK_MANAGER:FireCallbacks("OnWorldMapCampaignChanged")
    end
end

function ZO_WorldMap_GetCampaign()
    return g_campaignId, g_queryType
end

local OnFastTravelBegin, OnFastTravelEnd
do
    local function AddWayshrines()
        -- Dungeons no longer show wayshrines of any kind (possibly pending some system rework)
        -- Design rule, don't show wayshrine pins on cosmic, even if they're in the map
        if IsShowingCosmicMap() or not ZO_WorldMap_IsPinGroupShown(MAP_FILTER_WAYSHRINES) then
            return
        end

        local numFastTravelNodes = GetNumFastTravelNodes()
        for nodeIndex = 1, numFastTravelNodes do
            local known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked = GetFastTravelNodeInfo(nodeIndex)

            if known and isLocatedInCurrentMap and ZO_WorldMap_IsNormalizedPointInsideMapBounds(normalizedX, normalizedY) then
                local isCurrentLoc = g_fastTravelNodeIndex == nodeIndex

                if isCurrentLoc then
                    glowIcon = nil
                end

                local tag = ZO_MapPin.CreateTravelNetworkPinTag(nodeIndex, icon, glowIcon, linkedCollectibleIsLocked)

                local pinType = isCurrentLoc and MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE_CURRENT_LOC or MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE

                g_mapPinManager:CreatePin(pinType, tag, normalizedX, normalizedY)
            end
        end
    end

    function ZO_WorldMap_RefreshWayshrines()
        g_mapPinManager:RemovePins("fastTravelWayshrine")
        AddWayshrines()
    end

    function OnFastTravelBegin(eventCode, nodeIndex)
        g_fastTravelNodeIndex = nodeIndex
        if WORLD_MAP_INFO then 
            WORLD_MAP_INFO:SelectTab(SI_MAP_INFO_MODE_LOCATIONS)
        end
        WORLD_MAP_MANAGER:PushSpecialMode(MAP_MODE_FAST_TRAVEL)
        if not ZO_WorldMap_IsWorldMapShowing() then
            ZO_WorldMap_ShowWorldMap()
        else
            g_playerChoseCurrentMap = false
            if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
                CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
            end
        end
        ZO_WorldMap_RefreshWayshrines()
    end

    function OnFastTravelEnd()
        g_fastTravelNodeIndex = nil
        WORLD_MAP_MANAGER:PopSpecialMode()
        ZO_Dialogs_ReleaseDialog("FAST_TRAVEL_CONFIRM")
        ZO_Dialogs_ReleaseDialog("RECALL_CONFIRM")
    end
end

local function PlayerChosenMapUpdate(playerChoseMap, navigateIn)
    -- Determines whether or not the player actually selected this map.  If the player hits the recenter button
    -- we want the map to behave like they just opened it, but by default this function is called when the player
    -- actually chose which map to show so it defaults to true if nothing is passed in.
    --
    -- NOTE: Only call this function if the map was successfully changed (indicated by the return from the various
    -- SetMap* functions)


    if playerChoseMap == nil then playerChoseMap = true end
    g_playerChoseCurrentMap = playerChoseMap

    CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged", navigateIn)
end

--XML Handlers
----------------

local function RebuildMapHistory()
    ZO_WorldMap_RefreshKeeps()
    g_mapRefresh:RefreshAll("keepNetwork")
    g_mapRefresh:RefreshAll("objective")
end

function ZO_WorldMapHistorySlider_OnValueChanged(slider, value, eventReason)
    --prevent the initial software setting of these sliders from updating anything
    if g_savedVars and eventReason == EVENT_REASON_HARDWARE then
        local percent = value/CONSTANTS.HISTORY_SLIDER_RANGE

        local oldValue = g_historyPercent
        g_historyPercent = percent

        if DoesHistoryRequireMapRebuild(ZO_WorldMap_GetBattlegroundQueryType(), oldValue, g_historyPercent) then
            ResetCampaignHistoryWindow(ZO_WorldMap_GetBattlegroundQueryType(), g_historyPercent)
            RebuildMapHistory()
        end

    end
end

function ZO_WorldMap_ResetHistorySlider()
    if g_historyPercent ~= 1 then
        if g_campaignId ~= 0 and ResetCampaignHistoryWindow(ZO_WorldMap_GetBattlegroundQueryType(), g_historyPercent) then
            RebuildMapHistory()
        end
    end
end

function ZO_WorldMap_OnHide()
    local playerPin = g_mapPinManager:GetPlayerPin()
    playerPin:ResetAnimation(ZO_MapPin.ANIM_CONSTANTS.RESET_ANIM_HIDE_CONTROL)

    -- Always needs to be cleared
    ZO_WorldMapMouseoverName:SetText("")
    ZO_WorldMapMouseoverName.owner = ""
    ZO_WorldMapMouseOverDescription:SetText("")

    PrepareBlobManagersForZoneUpdate()
    ResetMouseIsOverWorldMap()

    -- Reset this...the next time the map opens it will be forced to the player's current location
    g_playerChoseCurrentMap = false

    EndInteraction(INTERACTION_FAST_TRAVEL_KEEP)
    EndInteraction(INTERACTION_FAST_TRAVEL)

    --Exit respawn mode
    local mode = WORLD_MAP_MANAGER:GetMode()
    if mode == MAP_MODE_AVA_RESPAWN or mode == MAP_MODE_AVA_KEEP_RECALL then
        WORLD_MAP_MANAGER:PopSpecialMode()
        ZO_WorldMap_RefreshAccessibleAvAGraveyards()
    elseif mode == MAP_MODE_DIG_SITES then
        local NO_SOUND = true
        WORLD_MAP_MANAGER:EndDigSiteReveal(NO_SOUND)
        WORLD_MAP_MANAGER:RefreshAllAntiquityDigSites()
    end
end

function ZO_WorldMap_OnShow()
    -- We really only want to ping the player pin when the map is opened...not every pin that's on the map.
    local playerPin = g_mapPinManager:GetPlayerPin()
    playerPin:PingMapPin(ZO_MapPin.PulseAnimation)

    ZO_WorldMap_ResetHistorySlider()
end

function ZO_WorldMapTitleBar_OnDragStart()
    local mapSize = WORLD_MAP_MANAGER:GetModeMapSize()
    if mapSize == CONSTANTS.WORLDMAP_SIZE_SMALL then
        ZO_WorldMap:SetMovable(true)
        ZO_WorldMap:StartMoving()
    end
end

function ZO_WorldMapTitleBar_OnMouseUp(button, upInside)
    ZO_WorldMap:SetMovable(false)
    SaveMapPosition()
end

function ZO_WorldMap_ToggleSize()
    if g_savedVars.userMode == MAP_MODE_SMALL_CUSTOM then
        WORLD_MAP_MANAGER:SetUserMode(MAP_MODE_LARGE_CUSTOM)
    else
        WORLD_MAP_MANAGER:SetUserMode(MAP_MODE_SMALL_CUSTOM)
    end
end

local function MapDragUpdate()
    local x, y = GetUIMousePosition()

    local diffX = x - g_mapDragX
    local diffY = y - g_mapDragY

    if g_dragging then
        g_mapPanAndZoom:AddTargetOffsetDelta(diffX, diffY)
        g_mapDragX = x
        g_mapDragY = y
    else
        local distSq = diffX * diffX + diffY * diffY
        if distSq > CONSTANTS.DRAG_START_DIST_SQ then
            g_mapDragX = x
            g_mapDragY = y
            g_dragging = true
            WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_PAN)
        end
    end
end

function ZO_WorldMap_MouseDown(button, ctrl, alt, shift)
    if IsInGamepadPreferredMode() then
        return
    end

    if button == MOUSE_BUTTON_INDEX_LEFT then
        local x, y = NormalizePreferredMousePositionToMap()

        if shift and not alt and not ctrl then
            PingMap(MAP_PIN_TYPE_RALLY_POINT, MAP_TYPE_LOCATION_CENTERED, x, y)
        elseif not shift and not alt and ctrl then
            PingMap(MAP_PIN_TYPE_PING, MAP_TYPE_LOCATION_CENTERED, x, y)
        else
            g_mapDragX, g_mapDragY = GetUIMousePosition()
            g_mapPanAndZoom:ClearTargetOffset()
            g_mapPanAndZoom:ClearLockPoint()
            g_mapPanAndZoom:AddTargetOffsetDelta(0, 0)

            g_dragging = not WouldProcessMapClick(x, y)
            if g_dragging then
                WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_PAN)
            end

            ZO_WorldMapContainer:SetHandler("OnUpdate", MapDragUpdate)
        end
    end

    WORLD_MAP_MANAGER:HandleMouseDown(button, ctrl, alt, shift)
end

function ZO_WorldMap_MouseUp(mapControl, mouseButton, upInside)
    ZO_WorldMapContainer:SetHandler("OnUpdate", nil)

    if g_dragging and not IsInGamepadPreferredMode() then
        g_dragging = false
        WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)

        local lastFrameDeltaX, lastFrameDeltaY = GetUIMouseDeltas()

        g_mapPanAndZoom:AddTargetOffsetDelta(lastFrameDeltaX * 15, lastFrameDeltaY * 15)

        g_mapDragX = nil
        g_mapDragY = nil
    else
        -- If modifier keys are still pressed then ignore this click because modifier keys are used to ping the map
        -- The reason upInside needs to be passed is that the mouse may have been pressed over the map, but the press
        -- spawns a map ping, so upInside would have been false, and this function would never have been called.
        -- That fact messed up the hook that some dev-functionality uses, so upInside is passed in to guarantee that the hook is always called.
        if not upInside or IsControlKeyDown() or IsAltKeyDown() or IsShiftKeyDown() then
            return
        end

        local needUpdate = false
        local navigateIn

        if mouseButton == MOUSE_BUTTON_INDEX_LEFT and WORLD_MAP_MANAGER:IsMapChangingAllowed(CONSTANTS.ZOOM_DIRECTION_IN) then
            needUpdate = ProcessMapClick(NormalizePreferredMousePositionToMap()) == SET_MAP_RESULT_MAP_CHANGED
            navigateIn = true
        elseif mouseButton == MOUSE_BUTTON_INDEX_RIGHT and WORLD_MAP_MANAGER:IsMapChangingAllowed(CONSTANTS.ZOOM_DIRECTION_OUT) then
            needUpdate = (MapZoomOut() == SET_MAP_RESULT_MAP_CHANGED)
            navigateIn = false
        end

        if needUpdate then
            g_gamepadMap:StopMotion()

            PlayerChosenMapUpdate(nil, navigateIn)
        end
    end
end

function ZO_WorldMap_MouseWheel(delta)
    g_mapPanAndZoom:OnMouseWheel(delta)
end

function ZO_WorldMap_MouseEnter()
    if not IsInGamepadPreferredMode() then
        KEYBIND_STRIP:AddKeybindButtonGroup(g_keybindStrips.mouseover:GetDescriptor())
    end
end

function ZO_WorldMap_MouseExit()
    if not IsInGamepadPreferredMode() then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(g_keybindStrips.mouseover:GetDescriptor())
    end
end

function ZO_WorldMap_HandlePinEnter()
    -- This is specifically written to avoid popping tooltips when the mouse is over a pin
    -- and the map is hidden and shown again without moving the mouse.
    -- The popping happens because when the map is shown an update happens that does the pin
    -- layout and anchoring...however the pin that the mouse was previously over has probably
    -- moved.  So the tooltip is created over the wrong pin, with the wrong data.
    -- Then the OnUpdate handler is called and realizes that the mouse is over a different pin and pops the tooltip.
    UpdateMouseOverPins()
end

function ZO_WorldMap_HandlePinExit()
    -- ZO_WorldMap_HandlePinExit exists for the same reason that ZO_WorldMap_HandlePinEnter does, to avoid tooltip and zone text pop.
    UpdateMouseOverPins()
end

function ZO_WorldMap_ChangeFloor(self)
    local currentFloor = GetMapFloorInfo()
    if SetMapFloor(currentFloor + self.floorDirection) == SET_MAP_RESULT_MAP_CHANGED then
        PlayerChosenMapUpdate()
    end
end

function ZO_WorldMap_ShowDungeonFloorTooltip(self)
    local informationTooltip = GetPlatformInformationTooltip()
    InitializeTooltip(informationTooltip, self, TOP, 0, 5)
    SetTooltipText(informationTooltip, self.tooltipFormatString)
end

--Global API

function ZO_WorldMap_ShowAvARespawns()
    WORLD_MAP_MANAGER:PushSpecialMode(MAP_MODE_AVA_RESPAWN)
    ZO_WorldMap_RefreshAccessibleAvAGraveyards()
end

function ZO_WorldMap_ShowAvAKeepRecall()
    WORLD_MAP_MANAGER:PushSpecialMode(MAP_MODE_AVA_KEEP_RECALL)
    g_mapRefresh:RefreshAll("keepNetwork")
    ZO_WorldMap_ShowWorldMap()
end

function ZO_WorldMap_AddCustomPin(pinType, pinTypeAddCallback, pinTypeOnResizeCallback, pinLayoutData, pinTooltipCreator)
    g_mapPinManager:AddCustomPin(pinType, pinTypeAddCallback, pinTypeOnResizeCallback, pinLayoutData, pinTooltipCreator)
end

function ZO_WorldMap_SetCustomPinEnabled(pinType, enabled)
    g_mapPinManager:SetCustomPinEnabled(pinType, enabled)
end

function ZO_WorldMap_IsCustomPinEnabled(pinType)
    return g_mapPinManager:IsCustomPinEnabled(pinType)
end

function ZO_WorldMap_ResetCustomPinsOfType(pinTypeString)
    g_mapPinManager:RemovePins(pinTypeString)
end

function ZO_WorldMap_RefreshCustomPinsOfType(pinType)
    g_mapPinManager:RefreshCustomPins(pinType)
end

function ZO_WorldMap_GetMapDimensions()
    return CONSTANTS.MAP_WIDTH, CONSTANTS.MAP_HEIGHT
end

function ZO_WorldMap_SetCustomZoomLevels(minZoom, maxZoom)
    g_mapPanAndZoom:SetCustomZoomMinMax(minZoom, maxZoom)
end

function ZO_WorldMap_ClearCustomZoomLevels()
    g_mapPanAndZoom:ClearCustomZoomMinMax()
end

function ZO_WorldMap_GetBattlegroundQueryType()
    return g_queryType
end

function ZO_WorldMap_SetMapByIndex(mapIndex)
    if WORLD_MAP_MANAGER:IsMapChangingAllowed() then
        if SetMapToMapListIndex(mapIndex) == SET_MAP_RESULT_MAP_CHANGED then
            g_playerChoseCurrentMap = true
            CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
        end
    end
end

function ZO_WorldMap_PanToWayshrine(nodeIndex)
    local pin = g_mapPinManager:GetWayshrinePin(nodeIndex)
    g_mapPanAndZoom:PanToPin(pin)
end

function ZO_WorldMap_PanToQuest(questIndex)
    local pin = g_mapPinManager:GetQuestConditionPin(questIndex)
    g_mapPanAndZoom:PanToPin(pin)
end

function ZO_WorldMap_PanToPlayer()
    local pin = g_mapPinManager:GetPlayerPin()
    g_gamepadMap:StopMotion()
    g_mapPanAndZoom:PanToPin(pin)
end

function ZO_WorldMap_PanToNormalizedPosition(x, y)
    g_gamepadMap:StopMotion()
    g_mapPanAndZoom:PanToNormalizedPosition(x, y)
end

function ZO_WorldMap_JumpToPlayer()
    local pin = g_mapPinManager:GetPlayerPin()
    g_gamepadMap:StopMotion()
    g_mapPanAndZoom:JumpToPin(pin)
end

function ZO_WorldMap_RefreshKeepNetwork()
    g_mapRefresh:RefreshAll("keepNetwork")
end

function ZO_WorldMap_DidPlayerChooseCurrentMap()
    return g_playerChoseCurrentMap
end

function ZO_WorldMap_ShowQuestOnMap(questIndex)
    if not WORLD_MAP_MANAGER:IsMapChangingAllowed() then
        return
    end

    WORLD_MAP_MANAGER:ClearQuestPings()

    --first try to set the map to one of the quest's step pins
    local result = SET_MAP_RESULT_FAILED
    for stepIndex = QUEST_MAIN_STEP_INDEX, GetJournalQuestNumSteps(questIndex) do
        --Loop through the conditions, if there are any. Prefer non-completed conditions to completed ones.
        local requireNotCompleted = true
        local conditionsExhausted = false
        while result == SET_MAP_RESULT_FAILED and not conditionsExhausted do 
            for conditionIndex = 1, GetJournalQuestNumConditions(questIndex, stepIndex) do
                local tryCondition = true
                if requireNotCompleted then
                    local complete = select(4, GetJournalQuestConditionValues(questIndex, stepIndex, conditionIndex))
                    tryCondition = not complete
                end
                if tryCondition then
                    result = SetMapToQuestCondition(questIndex, stepIndex, conditionIndex)
                    if result ~= SET_MAP_RESULT_FAILED then
                        -- only set questIndex so all the steps and conditions for this quest shown on the map get pings
                        g_questPingData =
                        {
                            questIndex = questIndex,
                        }
                        break
                    end
                end
            end
            if requireNotCompleted then
                requireNotCompleted = false
            else
                conditionsExhausted = true
            end
        end

        if result ~= SET_MAP_RESULT_FAILED then
            break
        end

        --If it's the end, set the map to the ending location (Endings don't have conditions)
        if IsJournalQuestStepEnding(questIndex, stepIndex) then
            result = SetMapToQuestStepEnding(questIndex, stepIndex)
            if result ~= SET_MAP_RESULT_FAILED then
                -- only set questIndex so all the steps and conditions for this quest shown on the map get pings
                g_questPingData =
                {
                    questIndex = questIndex,
                }
                break
            end
        end
    end

    --if it has no condition pins, set it to the quest's zone
    if result == SET_MAP_RESULT_FAILED then
        result = SetMapToQuestZone(questIndex)
        if result ~= SET_MAP_RESULT_FAILED then
            -- only set questIndex so all the steps and conditions for this quest shown on the map get pings
            g_questPingData =
            {
                questIndex = questIndex,
            }
        end
    end

    --if that doesn't work, bail
    if result == SET_MAP_RESULT_FAILED then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_WORLD_MAP_NO_QUEST_MAP_LOCATION)
        return
    end

    g_playerChoseCurrentMap = true
    if result == SET_MAP_RESULT_MAP_CHANGED then
        CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
    elseif g_questPingData then
        -- Make sure the pings get refreshed since the map didn't change
        RefreshMapPings()
    end

    if not ZO_WorldMap_IsWorldMapShowing() then
        if IsInGamepadPreferredMode() then
            SCENE_MANAGER:Push("gamepad_worldMap")
        else
            MAIN_MENU_KEYBOARD:ShowCategory(MENU_CATEGORY_MAP)
        end
    end

    g_mapPanAndZoom:JumpToPinWhenAvailable(function()
        return g_mapPinManager:GetQuestConditionPin(questIndex)
    end)
end

function ZO_WorldMap_ShowKeepOnMap(keepId)
    if not WORLD_MAP_MANAGER:IsMapChangingAllowed() then
        return
    end

    if g_cyrodiilMapIndex == nil then
        return
    end

    local result = SetMapToMapListIndex(g_cyrodiilMapIndex)

    if result == SET_MAP_RESULT_FAILED then
        return
    end

    g_playerChoseCurrentMap = true

    if result == SET_MAP_RESULT_MAP_CHANGED then
        CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
    end

    if not ZO_WorldMap_IsWorldMapShowing() then
        g_pendingKeepInfo = keepId
        ZO_WorldMap_ShowWorldMap()
    else
        SYSTEMS:GetObject("world_map_keep_info"):ToggleKeep(keepId)
    end

    g_mapPanAndZoom:JumpToPinWhenAvailable(function()
        local notUnderAttackPin = false
        return g_mapPinManager:FindPin("keep", keepId, notUnderAttackPin)
    end)
end

function ZO_WorldMap_RefreshKeeps()
    g_mapRefresh:RefreshAll("keep")
end

function ZO_WorldMap_RefreshObjectives()
    g_mapRefresh:RefreshAll("objective")
end

function ZO_WorldMap_RemovePlayerWaypoint()
    RemovePlayerWaypoint()
    g_keybindStrips.mouseover:DoMouseExitForPinType(MAP_PIN_TYPE_PLAYER_WAYPOINT) -- this should have been called by the mouseover update, but it's not getting called
    g_keybindStrips.gamepad:DoMouseExitForPinType(MAP_PIN_TYPE_PLAYER_WAYPOINT) -- this should have been called by the mouseover update, but it's not getting called
end

function ZO_WorldMap_GetPinManager()
    return g_mapPinManager
end

function ZO_WorldMap_GetPanAndZoom()
    return g_mapPanAndZoom
end

function ZO_WorldMap_GetQuestPingData()
    return g_questPingData
end

--Initialization
------------------
do
    --Event Handlers
    ---------------------
    local EVENT_HANDLERS =
    {
        [EVENT_NON_COMBAT_BONUS_CHANGED] = function()
            g_mapRefresh:RefreshAll("location")
        end,

        [EVENT_POI_UPDATED] = function(eventCode, zoneIndex, poiIndex)
            RefreshSinglePOI(zoneIndex, poiIndex)
            g_mapRefresh:RefreshAll("location")
        end,
        
        [EVENT_UNIT_CREATED] = function(eventCode, unitTag)
            local inGroup = ZO_Group_IsGroupUnitTag(unitTag)
            if inGroup and not AreUnitsEqual("player", unitTag) then
                g_mapRefresh:RefreshAll("group")
            end
        end,

        [EVENT_UNIT_DESTROYED] = function(eventCode, unitTag)
            local inGroup = ZO_Group_IsGroupUnitTag(unitTag)
            if inGroup and not AreUnitsEqual("player", unitTag) then
                g_mapRefresh:RefreshAll("group")
            end
        end,

        [EVENT_GROUP_MEMBER_LEFT] = function(evt, characterName, reason, wasLocalPlayer, amLeader)
            if wasLocalPlayer then
                g_mapRefresh:RefreshAll("group")
            end
        end,

        [EVENT_GROUP_UPDATE] = function(eventCode)
            g_mapRefresh:RefreshAll("group")
        end,

        [EVENT_LEADER_UPDATE] = function(eventCode)
            g_mapRefresh:RefreshAll("group")
        end,

        [EVENT_GROUP_MEMBER_CONNECTED_STATUS] = function()
            g_mapRefresh:RefreshAll("group")
        end,

        [EVENT_SCREEN_RESIZED] = function()
            ResizeAndReanchorMap()
        end,
        [EVENT_POIS_INITIALIZED] = function()
            CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
        end,
        [EVENT_OBJECTIVES_UPDATED] = ZO_WorldMap_RefreshObjectives,
        [EVENT_OBJECTIVE_CONTROL_STATE] = ZO_WorldMap_RefreshObjectives,
        [EVENT_KEEP_ALLIANCE_OWNER_CHANGED] = function(_, keepId, bgContext)
            g_mapRefresh:RefreshSingle("keep", keepId, bgContext)
            if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_RESPAWN) then
                ZO_WorldMap_RefreshAccessibleAvAGraveyards()
            end
        end,
        [EVENT_KEEP_UNDER_ATTACK_CHANGED] = function(_, keepId, bgContext)
            RefreshKeepUnderAttack(keepId, bgContext)
            if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_RESPAWN) then
                ZO_WorldMap_RefreshAccessibleAvAGraveyards()
            end
        end,
        [EVENT_KEEP_IS_PASSABLE_CHANGED] = function(_, keepId, bgContext)
            g_mapRefresh:RefreshSingle("keep", keepId, bgContext)
        end,
        [EVENT_KEEP_PIECE_DIRECTIONAL_ACCESS_CHANGED] = function(_, keepId, bgContext)
            g_mapRefresh:RefreshSingle("keep", keepId, bgContext)
        end,
        [EVENT_KEEP_GATE_STATE_CHANGED] = ZO_WorldMap_RefreshKeeps,
        [EVENT_KEEP_INITIALIZED] = function(_, keepId, bgContext)
            g_mapRefresh:RefreshSingle("keep", keepId, bgContext)
        end,
        [EVENT_KEEPS_INITIALIZED] = ZO_WorldMap_RefreshKeeps,
        [EVENT_KILL_LOCATIONS_UPDATED] = ZO_WorldMap_RefreshKillLocations,
        [EVENT_FORWARD_CAMPS_UPDATED] = function()
            ZO_WorldMap_RefreshForwardCamps()
            if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_RESPAWN) then
                ZO_WorldMap_RefreshAccessibleAvAGraveyards()
            end
        end,

        [EVENT_MAP_PING] = function(eventCode, pingEventType, pingType, pingTag, x, y, isPingOwner)
            if pingEventType == PING_EVENT_ADDED then
                if isPingOwner then
                    PlaySound(SOUNDS.MAP_PING)
                end
                g_mapPinManager:RemovePins("pings", pingType, pingTag)
                g_mapPinManager:CreatePin(pingType, pingTag, x, y)
            elseif pingEventType == PING_EVENT_REMOVED then
                if isPingOwner then
                    PlaySound(SOUNDS.MAP_PING_REMOVE)
                end
                g_mapPinManager:RemovePins("pings", pingType, pingTag)
            end
        end,

        [EVENT_FAST_TRAVEL_KEEP_NETWORK_UPDATED] = function()
            g_mapRefresh:RefreshAll("keepNetwork")
        end,

        [EVENT_START_FAST_TRAVEL_KEEP_INTERACTION] = function(eventCode, keepId)
            WORLD_MAP_MANAGER:PushSpecialMode(MAP_MODE_KEEP_TRAVEL)
            ZO_WorldMap_ShowWorldMap()
            g_keepNetworkManager:SetOpenNetwork(keepId)
        end,

        [EVENT_END_FAST_TRAVEL_KEEP_INTERACTION] = function()
            g_keepNetworkManager:ClearOpenNetwork()
            WORLD_MAP_MANAGER:PopSpecialMode()
        end,

        [EVENT_RECALL_KEEP_USE_RESULT] = function(eventId, result)
            if result == KEEP_RECALL_STONE_USE_RESULT_SUCCESS then
                ZO_WorldMap_ShowAvAKeepRecall()
            end
        end,
        [EVENT_ZONE_CHANGED] = function(eventId, zoneName, subzoneName)
            if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_KEEP_RECALL) and subzoneName ~= "" then
                g_mapRefresh:RefreshAll("keepNetwork")
            end
        end,
        [EVENT_PLAYER_COMBAT_STATE] = function()
            if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_KEEP_RECALL) then
                g_mapRefresh:RefreshAll("keepNetwork")
            end
        end,
        [EVENT_PLAYER_DEAD] = function()
            if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_KEEP_RECALL) then
                g_mapRefresh:RefreshAll("keepNetwork")
            end
        end,

        [EVENT_FAST_TRAVEL_NETWORK_UPDATED] = ZO_WorldMap_RefreshWayshrines,
        [EVENT_START_FAST_TRAVEL_INTERACTION] = OnFastTravelBegin,
        [EVENT_END_FAST_TRAVEL_INTERACTION] = OnFastTravelEnd,

        [EVENT_PLAYER_ALIVE] = function()
            if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_RESPAWN) then
                WORLD_MAP_MANAGER:PopSpecialMode()
                ZO_WorldMap_RefreshAccessibleAvAGraveyards()
                ZO_WorldMap_HideWorldMap()
            end
        end,

        [EVENT_CURRENT_CAMPAIGN_CHANGED] = function()
            UpdateMapCampaign()
        end,
        [EVENT_ASSIGNED_CAMPAIGN_CHANGED] = function()
            UpdateMapCampaign()
        end,
        [EVENT_PLAYER_ACTIVATED] = function()
            ClearFastTravelNode()
            g_mapRefresh:RefreshAll("group")
            CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
        end,
        [EVENT_GUILD_NAME_AVAILABLE] = OnGuildNameAvailable,
        [EVENT_KEEP_START_INTERACTION] = function()
            local keepId = GetInteractionKeepId()
            ZO_WorldMap_ShowKeepOnMap(keepId)
            EndInteraction(INTERACTION_KEEP_INSPECT)
        end,

        [EVENT_FORWARD_CAMP_RESPAWN_TIMER_BEGINS] = function(eventCode, durationMS)
            g_nextRespawnTimeMS = durationMS + GetFrameTimeMilliseconds()
        end,

        [EVENT_WORLD_EVENTS_INITIALIZED] = function()
            g_mapRefresh:RefreshAll("worldEvent")
        end,

        [EVENT_WORLD_EVENT_ACTIVATED] = function(_, worldEventInstanceId)
            g_mapRefresh:RefreshSingle("worldEvent", worldEventInstanceId)
        end,

        [EVENT_WORLD_EVENT_DEACTIVATED] = function(_, worldEventInstanceId)
            g_mapRefresh:RefreshSingle("worldEvent", worldEventInstanceId)
        end,

        [EVENT_WORLD_EVENT_UNIT_CREATED] = function(_, worldEventInstanceId)
            g_mapRefresh:RefreshSingle("worldEvent", worldEventInstanceId)
        end,

        [EVENT_WORLD_EVENT_UNIT_DESTROYED] = function(_, worldEventInstanceId)
            g_mapRefresh:RefreshSingle("worldEvent", worldEventInstanceId)
        end,

        [EVENT_WORLD_EVENT_UNIT_CHANGED_PIN_TYPE] = function(_, worldEventInstanceId)
            g_mapRefresh:RefreshSingle("worldEvent", worldEventInstanceId)
        end,

        [EVENT_SHOW_WORLD_MAP] = function()
            ZO_WorldMap_ShowWorldMap()
        end,

        [EVENT_REVEAL_ANTIQUITY_DIG_SITES_ON_MAP] = function(_, antiquityId)
            WORLD_MAP_MANAGER:RevealAntiquityDigSpotsOnMap(antiquityId)
        end,
    }
    
    --Callbacks
    ------------
    local function OnAssistStateChanged(unassistedData, assistedData)
        if unassistedData then
            g_mapPinManager:SetQuestPinsAssisted(unassistedData:GetJournalIndex(), false)
        end
        if assistedData then
            g_mapPinManager:SetQuestPinsAssisted(assistedData:GetJournalIndex(), true)
        end
        ZO_WorldMap_InvalidateTooltip()
    end
    
    local function OnGamepadPreferredModeChanged()
        SetupWorldMap()
        FloorLevelNavigationUpdate()
    end

    local function OnCollectionUpdated(collectionUpdateType, collectiblesByNewUnlockState)
        if collectionUpdateType == ZO_COLLECTION_UPDATE_TYPE.REBUILD then
            ZO_WorldMap_RefreshAllPOIs()
            ZO_WorldMap_RefreshWayshrines()
            return
        else
            for _, unlockStateTable in pairs(collectiblesByNewUnlockState) do
                for _, collectibleData in ipairs(unlockStateTable) do
                    if collectibleData:IsStory() then
                        ZO_WorldMap_RefreshAllPOIs()
                        ZO_WorldMap_RefreshWayshrines()
                        return
                    end
                end
            end
        end
    end

    --Initialize Refresh Groups
    ----------------------------

    local function InitializeRefreshGroups()
        g_mapRefresh = ZO_Refresh:New()

        g_mapRefresh:AddRefreshGroup("keep",
        {
            RefreshAll = RefreshKeeps,
            RefreshSingle = RefreshKeep,
            IsShown = IsPresentlyShowingKeeps,
        })

        g_mapRefresh:AddRefreshGroup("keepNetwork",
        {
            RefreshAll = function()
                if g_keepNetworkManager then
                    g_keepNetworkManager:RefreshLinks()
                end
            end,
            IsShown = IsPresentlyShowingKeeps,
        })

        g_mapRefresh:AddRefreshGroup("objective",
        {
            RefreshAll = RefreshObjectives,
        })

        g_mapRefresh:AddRefreshGroup("group",
        {
            RefreshAll = ZO_WorldMap_RefreshGroupPins,
        })

        g_mapRefresh:AddRefreshGroup("location",
        {
            RefreshAll =  function()
                g_mapLocationManager:RefreshLocations()
            end,
        })

        g_mapRefresh:AddRefreshGroup("worldEvent",
        {
            RefreshAll = ZO_WorldMap_RefreshWorldEvents,
            RefreshSingle = ZO_WorldMap_RefreshWorldEvent,
        })
    end

    --Initialize
    ---------------
    function ZO_WorldMap_Initialize(control)
        local worldMapContainer = control:GetNamedChild("Container")
        g_mapLocationManager = ZO_MapLocations:New(worldMapContainer)
        g_mouseoverMapBlobManager = ZO_MouseoverMapBlobManager:New(worldMapContainer)
        g_mapTileManager = ZO_WorldMapTiles:New(worldMapContainer)
        g_mapPinManager = ZO_WorldMapPins:New(worldMapContainer)
        InitializeRefreshGroups()

        g_mapPinManager:CreatePin(MAP_PIN_TYPE_PLAYER, "player")

        g_nextRespawnTimeMS = GetNextForwardCampRespawnTime()

        --delay a lot of initialization until after the addon loads
        local function OnAddOnLoaded(eventCode, addOnName)
            if addOnName == "ZO_Ingame" then
                local DEFAULT_SMALL_WIDTH, DEFAULT_SMALL_HEIGHT = GetSquareMapWindowDimensions(CONSTANTS.WORLDMAP_SIZE_SMALL_WINDOW_SIZE, CONSTANTS.WORLDMAP_RESIZE_HEIGHT_DRIVEN, CONSTANTS.WORLDMAP_SIZE_SMALL)

                local defaults =
                {
                    [MAP_MODE_SMALL_CUSTOM] =
                    {
                        keepSquare = true,
                        width = DEFAULT_SMALL_WIDTH,
                        height = DEFAULT_SMALL_HEIGHT,
                        x = 0,
                        y = 0,
                        point = CENTER,
                        relPoint = CENTER,
                        mapSize = CONSTANTS.WORLDMAP_SIZE_SMALL,
                        filters =
                        {
                            [MAP_FILTER_TYPE_STANDARD] =
                            {

                            },
                            [MAP_FILTER_TYPE_AVA_CYRODIIL] =
                            {
                                [MAP_FILTER_OBJECTIVES] = false,
                                [MAP_FILTER_AVA_GRAVEYARD_AREAS] = false,
                                [MAP_FILTER_TRANSIT_LINES_ALLIANCE] = MAP_TRANSIT_LINE_ALLIANCE_ALL,
                            },
                            [MAP_FILTER_TYPE_AVA_IMPERIAL] =
                            {

                            },
                            [MAP_FILTER_TYPE_BATTLEGROUND] =
                            {

                            },
                        }
                    },
                    [MAP_MODE_LARGE_CUSTOM] =
                    {
                        mapSize = CONSTANTS.WORLDMAP_SIZE_FULLSCREEN,
                        filters =
                        {
                            [MAP_FILTER_TYPE_STANDARD] =
                            {

                            },
                            [MAP_FILTER_TYPE_AVA_CYRODIIL] =
                            {
                                [MAP_FILTER_OBJECTIVES] = false,
                                [MAP_FILTER_AVA_GRAVEYARD_AREAS] = false,
                                [MAP_FILTER_TRANSIT_LINES_ALLIANCE] = MAP_TRANSIT_LINE_ALLIANCE_ALL,
                            },
                            [MAP_FILTER_TYPE_AVA_IMPERIAL] =
                            {

                            },

                            [MAP_FILTER_TYPE_BATTLEGROUND] =
                            {

                            },
                        }
                    },
                    [MAP_MODE_KEEP_TRAVEL] =
                    {
                        mapSize = CONSTANTS.WORLDMAP_SIZE_FULLSCREEN,
                        allowHistory = false,
                        filters =
                        {
                            [MAP_FILTER_TYPE_AVA_CYRODIIL] =
                            {
                                [MAP_FILTER_KILL_LOCATIONS] = false,
                                [MAP_FILTER_OBJECTIVES] = false,
                                [MAP_FILTER_QUESTS] = false,
                                [MAP_FILTER_RESOURCE_KEEPS] = false,
                                [MAP_FILTER_AVA_GRAVEYARDS] = false,
                                [MAP_FILTER_WAYSHRINES] = false,
                                [MAP_FILTER_TRANSIT_LINES_ALLIANCE] = MAP_TRANSIT_LINE_ALLIANCE_ALL,
                            }
                        },
                        disabledStickyPins =
                        {
                            [MAP_FILTER_TYPE_AVA_CYRODIIL] =
                            {
                                [MAP_FILTER_RESOURCE_KEEPS] = true,
                            }
                        },
                    },
                    [MAP_MODE_FAST_TRAVEL] =
                    {
                        mapSize = CONSTANTS.WORLDMAP_SIZE_FULLSCREEN,
                        allowHistory = false,
                        filters =
                        {
                            [MAP_FILTER_TYPE_STANDARD] =
                            {

                            },
                            [MAP_FILTER_TYPE_AVA_CYRODIIL] =
                            {
                                [MAP_FILTER_KILL_LOCATIONS] = false,
                                [MAP_FILTER_AVA_OBJECTIVES] = false,
                                [MAP_FILTER_TRANSIT_LINES_ALLIANCE] = MAP_TRANSIT_LINE_ALLIANCE_ALL,
                            },
                            [MAP_FILTER_TYPE_AVA_IMPERIAL] =
                            {

                            },

                            [MAP_FILTER_TYPE_BATTLEGROUND] =
                            {

                            },
                        }
                    },
                    [MAP_MODE_AVA_RESPAWN] =
                    {
                        mapSize = CONSTANTS.WORLDMAP_SIZE_FULLSCREEN,
                        allowHistory = false,
                        filters =
                        {
                            [MAP_FILTER_TYPE_AVA_CYRODIIL] =
                            {
                                [MAP_FILTER_KILL_LOCATIONS] = false,
                                [MAP_FILTER_WAYSHRINES] = false,
                                [MAP_FILTER_OBJECTIVES] = false,
                                [MAP_FILTER_RESOURCE_KEEPS] = false,
                                [MAP_FILTER_TRANSIT_LINES_ALLIANCE] = MAP_TRANSIT_LINE_ALLIANCE_ALL,
                            },
                            [MAP_FILTER_TYPE_AVA_IMPERIAL] =
                            {

                            },

                            [MAP_FILTER_TYPE_BATTLEGROUND] =
                            {

                            },
                        },
                        disabledStickyPins =
                        {
                            [MAP_FILTER_TYPE_AVA_CYRODIIL] =
                            {
                                [MAP_FILTER_RESOURCE_KEEPS] = true,
                            }
                        },
                    },
                    [MAP_MODE_AVA_KEEP_RECALL] =
                    {
                        mapSize = CONSTANTS.WORLDMAP_SIZE_FULLSCREEN,
                        allowHistory = false,
                        filters =
                        {
                            [MAP_FILTER_TYPE_AVA_CYRODIIL] =
                            {
                                [MAP_FILTER_KILL_LOCATIONS] = false,
                                [MAP_FILTER_OBJECTIVES] = false,
                                [MAP_FILTER_QUESTS] = false,
                                [MAP_FILTER_RESOURCE_KEEPS] = false,
                                [MAP_FILTER_AVA_GRAVEYARDS] = false,
                                [MAP_FILTER_WAYSHRINES] = false,
                                [MAP_FILTER_TRANSIT_LINES] = false,
                            }
                        },
                        disabledStickyPins =
                        {
                            [MAP_FILTER_TYPE_AVA_CYRODIIL] =
                            {
                                [MAP_FILTER_RESOURCE_KEEPS] = true,
                            }
                        },
                    },
                    [MAP_MODE_DIG_SITES] =
                    {
                        mapSize = CONSTANTS.WORLDMAP_SIZE_FULLSCREEN,
                        allowHistory = false,
                        filters =
                        {
                            [MAP_FILTER_TYPE_STANDARD] =
                            {
                                [MAP_FILTER_OBJECTIVES] = false,
                            },
                            [MAP_FILTER_TYPE_AVA_CYRODIIL] =
                            {
                                [MAP_FILTER_OBJECTIVES] = false,
                                [MAP_FILTER_KILL_LOCATIONS] = false,
                                [MAP_FILTER_AVA_OBJECTIVES] = false,
                                [MAP_FILTER_TRANSIT_LINES_ALLIANCE] = MAP_TRANSIT_LINE_ALLIANCE_ALL,
                            },
                            [MAP_FILTER_TYPE_AVA_IMPERIAL] =
                            {

                            },

                            [MAP_FILTER_TYPE_BATTLEGROUND] =
                            {

                            },
                        }
                    },
                    userMode = MAP_MODE_LARGE_CUSTOM,
                }

                g_savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 4, "WorldMap", defaults)
                local smallCustom = g_savedVars[MAP_MODE_SMALL_CUSTOM]

                g_cyrodiilMapIndex = GetCyrodiilMapIndex()
                g_imperialCityMapIndex = GetImperialCityMapIndex()

                CALLBACK_MANAGER:FireCallbacks("OnWorldMapSavedVarsReady", g_savedVars)

                --Constrain any bad custom sizes
                local uiWidth, uiHeight = GuiRoot:GetDimensions()
                if smallCustom.width > uiWidth or smallCustom.height > uiHeight then
                    smallCustom.width = DEFAULT_SMALL_WIDTH
                    smallCustom.height = DEFAULT_SMALL_HEIGHT
                end

                WORLD_MAP_MANAGER:SetUserMode(g_savedVars.userMode)

                SetupWorldMap()
                EVENT_MANAGER:RegisterForEvent("ZO_WorldMap", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, OnGamepadPreferredModeChanged)

                g_keepNetworkManager = ZO_KeepNetwork:New(ZO_WorldMapContainerKeepLinks)
                g_dataRegistration = ZO_CampaignDataRegistration:New("WorldMapData", function()
                    local assignedCampaignId = GetAssignedCampaignId()
                    return  ZO_WorldMap_IsWorldMapShowing() and
                            GetMapContentType() == MAP_CONTENT_AVA and
                            GetCurrentCampaignId() ~= assignedCampaignId and
                            g_campaignId == assignedCampaignId
                end)

                SetCampaignHistoryEnabled(false)

                UpdateMapCampaign()
                ZO_WorldMap_UpdateMap()

                for event, handler in pairs(EVENT_HANDLERS) do
                    EVENT_MANAGER:RegisterForEvent("ZO_WorldMap", event, handler)
                end

                FOCUSED_QUEST_TRACKER:RegisterCallback("QuestTrackerAssistStateChanged", OnAssistStateChanged)
                ZO_COLLECTIBLE_DATA_MANAGER:RegisterCallback("OnCollectionUpdated", OnCollectionUpdated)

                CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function(wasNavigateIn)
                    ZO_WorldMapMouseoverName:SetText("")
                    ZO_WorldMapMouseOverDescription:SetText("")
                    ZO_WorldMapMouseoverName.owner = ""
                    UpdateMovingPins()
                    UpdateMapCampaign()
                    ZO_WorldMap_UpdateMap()
                    g_mapRefresh:RefreshAll("group")
                    g_mapPanAndZoom:OnWorldMapChanged(wasNavigateIn)
                    ZO_WorldMap_MarkKeybindStripsDirty()
                    g_dataRegistration:Refresh()
                    WORLD_MAP_MANAGER:TryTriggeringTutorials()
                end)
            end
        end

        EVENT_MANAGER:RegisterForEvent("ZO_WorldMap_Add_On_Loaded", EVENT_ADD_ON_LOADED, OnAddOnLoaded)

        --setup history
        ZO_WorldMapButtonsHistorySlider:SetMinMax(0, CONSTANTS.HISTORY_SLIDER_RANGE)
        ZO_WorldMapButtonsHistorySlider:SetValue(CONSTANTS.HISTORY_SLIDER_RANGE)
        g_historyPercent = 1

        --info panels
        if ZO_WorldMapInfo_Initialize then
            ZO_WorldMapInfo_Initialize()
        end
        if ZO_WorldMapInfo_Gamepad_Initialize then
            ZO_WorldMapInfo_Gamepad_Initialize()
        end
        GAMEPAD_WORLD_MAP_INFO_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
            if newState == SCENE_FRAGMENT_SHOWING or newState == SCENE_FRAGMENT_HIDDEN then
                FloorLevelNavigationUpdate()
            end
        end)

        if GetKeepFastTravelInteraction() then
            CloseChatter()
        end

        --TODO: Move WAY more into the object
        WORLD_MAP_MANAGER = ZO_WorldMapManager:New(control)
    end
end

function SetCampaignHistoryEnabled(enabled)
    local wasUsingHistory = ShouldUseHistoryPercent()

    g_enableCampaignHistory = enabled

    local isUsingHistory = ShouldUseHistoryPercent()
    ZO_WorldMapButtonsHistorySlider:SetHidden(not isUsingHistory)

    if wasUsingHistory ~= isUsingHistory then
        RebuildMapHistory()
    end
end

function ZO_WorldMap_MarkKeybindStripsDirty()
    g_keybindStrips.mouseover:MarkDirty()
    g_keybindStrips.PC:MarkDirty()
    g_keybindStrips.gamepad:MarkDirty()
end

function ZO_WorldMap_InteractKeybindForceHidden(hidden)
    g_interactKeybindForceHidden = hidden
    ZO_WorldMap_UpdateInteractKeybind_Gamepad()
end

function ZO_WorldMap_SetKeepMode(active)
    if not IsInGamepadPreferredMode() then
        return
    end

    if active then
        ZO_WorldMap_SetGamepadKeybindsShown(false)

        GAMEPAD_WORLD_MAP_KEEP_UPGRADE:Activate()

        -- Hide the tooltips
        ZO_WorldMap_HideAllTooltips()

        -- Add the Close Keep keybind
        KEYBIND_STRIP:AddKeybindButtonGroup(g_keybindStrips.gamepadCloseKeep:GetDescriptor())

        ZO_WorldMap_InteractKeybindForceHidden(true)
    else
        -- Remove the Close Keep keybind
        KEYBIND_STRIP:RemoveKeybindButtonGroup(g_keybindStrips.gamepadCloseKeep:GetDescriptor())

        GAMEPAD_WORLD_MAP_KEEP_UPGRADE:Deactivate()

        ZO_WorldMap_SetGamepadKeybindsShown(true)
        ZO_WorldMap_InteractKeybindForceHidden(false)
    end
end

function ZO_WorldMap_HandlersContain(pinDatas, types)
    for _, pinData in ipairs(pinDatas) do
        local handler = pinData.handler
        for _, type in ipairs(types) do
            if handler == type then
                return true
            end
        end
    end
    return false
end

function ZO_WorldMap_GetGamepadPinActionGroupForHandler(handler)
    for gamepadPinActionGroup, handlers in ipairs(ZO_WORLD_MAP_GAMEPAD_PIN_ACTION_GROUP_TYPE_TO_HANDLERS) do
        for _, searchHandler in ipairs(handlers) do
            if searchHandler == handler then
                return gamepadPinActionGroup
            end
        end
    end
end

function ZO_WorldMap_CountHandlerTypes(pinDatas)
    local count = 0
    for _, types in ipairs(ZO_WORLD_MAP_GAMEPAD_PIN_ACTION_GROUP_TYPE_TO_HANDLERS) do
        if ZO_WorldMap_HandlersContain(pinDatas, types) then
            count = count + 1
        end
    end

    return count
end

function ZO_WorldMap_UpdateInteractKeybind_Gamepad()
    if IsInGamepadPreferredMode() then
        if not ZO_WorldMap_IsWorldMapInfoShowing() then
            local pinDatas = ZO_WorldMap_GetPinHandlers(MOUSE_BUTTON_INDEX_LEFT)

            if #pinDatas == 0 then
                -- There are no actionable pins under the cursor.
                ZO_WorldMapGamepadInteractKeybind:SetHidden(true)
            else
                -- We want to filter out all invalid spawn locations because if they are selected
                -- along with another pin that is valid they should be ignored as if they are not selected
                -- If there are no validHandlers, we have only invalid spawn locations.
                -- We still want to display the invalid spawn location text, so use the first invalid handler
                -- to access the buttonText callback
                local firstHandler = pinDatas[1].handler
                RemoveInvalidSpawnLocations(pinDatas)

                -- Use the first valid handler if one exists
                if #pinDatas > 0 then
                    firstHandler = pinDatas[1].handler
                end

                local buttonText = firstHandler.gamepadName
                -- If we are highlighting multiple types of pins at the same time
                if ZO_WorldMap_CountHandlerTypes(pinDatas) > 1 then
                    buttonText = GetString(SI_GAMEPAD_SELECT_OPTION)
                elseif type(buttonText) == "function" then
                    buttonText = buttonText(pinDatas)
                end

                ZO_WorldMapGamepadInteractKeybind:SetHidden(g_interactKeybindForceHidden or GAMEPAD_WORLD_MAP_KEY_FRAGMENT:IsShowing())
                local KEYBIND_SCALE_PERCENT = 120
                ZO_WorldMapGamepadInteractKeybind:SetText(zo_strformat(SI_GAMEPAD_WORLD_MAP_INTERACT, ZO_Keybindings_GenerateIconKeyMarkup(KEY_GAMEPAD_BUTTON_1, KEYBIND_SCALE_PERCENT), buttonText))
            end
        end
    else
        ZO_WorldMapGamepadInteractKeybind:SetHidden(true)
    end
end

function ZO_WorldMap_SetDirectionalInputActive(active)
    if active then
        if GAMEPAD_WORLD_MAP_SCENE:IsShowing() then
            DIRECTIONAL_INPUT:Activate(g_gamepadMap, ZO_WorldMap)
        end
    else
        DIRECTIONAL_INPUT:Deactivate(g_gamepadMap)
    end
end

function ZO_WorldMap_SetGamepadKeybindsShown(enabled)
    ZO_WorldMap_SetDirectionalInputActive(enabled)
    if enabled then
        -- Activate the keybinding and directional controls
        KEYBIND_STRIP:AddKeybindButtonGroup(g_keybindStrips.gamepad:GetDescriptor())
        ZO_WorldMapCenterPoint:SetHidden(false)
        ZO_WorldMapHeader_GamepadZoomKeybind:SetHidden(false)
    else
        -- Deactivate the keybinding and directional controls
        KEYBIND_STRIP:RemoveKeybindButtonGroup(g_keybindStrips.gamepad:GetDescriptor())
        ZO_WorldMapCenterPoint:SetHidden(true)
        ZO_WorldMapHeader_GamepadZoomKeybind:SetHidden(true)
    end
end

function ZO_WorldMap_HideAllTooltips()
    if not GetPlatformInformationTooltip() then -- Tooltips aren't active
        return
    end

    HideAllTooltips()

    CALLBACK_MANAGER:FireCallbacks("OnHideWorldMapTooltip")
end

function ZO_WorldMap_ShowGamepadTooltip(resetScroll)
    if not GetPlatformInformationTooltip() then -- Tooltips aren't active
        return
    end

    local tooltipControl = ShowGamepadTooltip(resetScroll)

    CALLBACK_MANAGER:FireCallbacks("OnShowWorldMapTooltip")

    return tooltipControl
end

function ZO_WorldMap_IsTooltipShowing()
    if IsInGamepadPreferredMode() then
        return usedTooltips[CONSTANTS.GAMEPAD_TOOLTIP_ID]
    else
        for i = 1, #tooltipOrder do
            if usedTooltips[i] then
                return true
            end
        end

        return false
    end
end

function ZO_WorldMap_GetZoomText_Gamepad()
    return ZO_Keybindings_GenerateIconKeyMarkup(KEY_GAMEPAD_LEFT_TRIGGER) .. ZO_Keybindings_GenerateIconKeyMarkup(KEY_GAMEPAD_RIGHT_TRIGGER, SCALE) .. GetString(SI_WORLD_MAP_ZOOM)
end

function ZO_WorldMap_IsWorldMapInfoShowing()
    return GAMEPAD_WORLD_MAP_INFO_FRAGMENT:IsShowing()
end

function ZO_WorldMap_IsKeepInfoShowing()
    return GAMEPAD_WORLD_MAP_KEEP_INFO_FRAGMENT:IsShowing()
end

function ZO_WorldMap_IsWorldMapShowing()
    return SCENE_MANAGER:IsShowing("worldMap") or SCENE_MANAGER:IsShowing("gamepad_worldMap")
end

function ZO_WorldMap_ShowWorldMap()
    if IsInGamepadPreferredMode() then
        SCENE_MANAGER:Show("gamepad_worldMap")
    else
        SCENE_MANAGER:Show("worldMap")
    end
end

function ZO_WorldMap_HideWorldMap()
    if SCENE_MANAGER:IsShowing("worldMap") then
        SCENE_MANAGER:Hide("worldMap")
    elseif SCENE_MANAGER:IsShowing("gamepad_worldMap") then
        SCENE_MANAGER:Hide("gamepad_worldMap")
    end
end

function ZO_WorldMap_SetupGamepadChoiceDialog(mouseOverPinHandlers)
    ZO_Dialogs_ShowGamepadDialog("WORLD_MAP_CHOICE_GAMEPAD", { mouseOverPinHandlers = mouseOverPinHandlers })
end

--[[
The World Map object, where state for the map system in general can be stored
This file still relies heavily on locals and global functions but in time that can be migrated to the class
]]--

local AUTO_NAVIGATION_STATE =
{
    INACTIVE = 1,
    WAITING_TO_PAN = 2,
    PANNING = 3,
    WAITING_TO_CLICK = 4,
}

local AUTO_NAVIGATION_CONSTANTS =
{
    START_PAN_DELAY_S = 1.5,
    PAN_DELAY_S = 1.0,
    CLICK_DELAY_S = 0.25,
    START_ZOOM = 0.3,
}

local ANTIQUITY_DIG_SITE_ANIMATION_STATE =
{
    INACTIVE = 1,
    INITIALIZE_ANIMATIONS = 2,
    TRIGGER_ANIMATIONS = 3,
    FINISH_ANIMATIONS = 4,
}

local ANTIQUITY_DIG_SITE_ANIMATION_CONSTANTS =
{
    START_ADDING_PINGS_DELAY_S = 3.8, -- delayed largely for CSA
    TIME_BETWEEN_PINGS_S = 0.8,
    PING_DURATION_S = 0.6,
}

ZO_WorldMapManager = ZO_CallbackObject:Subclass()

function ZO_WorldMapManager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_WorldMapManager:Initialize(control)
    self.control = control

    -- NOTE: The update loop queries to see if it needs to update the current map, so we don't have to register for the ZONE_CHANGED event.
    control:SetHandler("OnUpdate", Update)

    --Constrain map to screen
    local uiWidth, uiHeight = GuiRoot:GetDimensions()
    control:SetDimensionConstraints(CONSTANTS.MAP_MIN_SIZE, CONSTANTS.MAP_MIN_SIZE, uiWidth, uiHeight)

    self.autoNavigationState = AUTO_NAVIGATION_STATE.INACTIVE
    self.autoNavigationDelayUntilFrameTimeS = nil

    self.antiquityDigSiteAnimationState = ANTIQUITY_DIG_SITE_ANIMATION_STATE.INACTIVE
    self.antiquityDigSiteAnimationDelayUntilFrameTimeS = nil
    self.antiquityDigSitePinInfo = {}

    -- initial mode will be set from the saved variables
    self.mode = nil
    self.modeData = nil
    self.inSpecialMode = false

    --Scenes
    self:CreateKeyboardWorldMapScene()
    self:CreateGamepadWorldMapScene()

    WORLD_MAP_AUTO_NAVIGATION_OVERLAY_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_WorldMapAutoNavigationOverlay)
    WORLD_MAP_AUTO_NAVIGATION_OVERLAY_FRAGMENT:SetConditional(function() return self:IsPreventingMapNavigation() end)

    local autoNavigationOverlayControl = ZO_WorldMapAutoNavigationOverlay
    WORLD_MAP_AUTO_NAVIGATION_OVERLAY_FRAGMENT = ZO_SimpleSceneFragment:New(autoNavigationOverlayControl)
    WORLD_MAP_AUTO_NAVIGATION_OVERLAY_FRAGMENT:SetConditional(function() return self:IsPreventingMapNavigation() end)

    local autoNavigationContinueKeybind = autoNavigationOverlayControl:GetNamedChild("ContinueKeybind")

    -- TODO: Make this a more generic handler for exiting map auto-navigation
    local function EndDigSiteReveal()
        WORLD_MAP_MANAGER:EndDigSiteReveal()
    end
    ZO_KeybindButtonTemplate_Setup(autoNavigationContinueKeybind, "UI_SHORTCUT_PRIMARY", EndDigSiteReveal, GetString(SI_WORLD_MAP_ANTIQUITIES_CONTINUE))
    autoNavigationContinueKeybind:SetMouseOverEnabled(false)
    autoNavigationContinueKeybind:SetClickSound(SOUNDS.POSITIVE_CLICK)
    autoNavigationContinueKeybind:SetAnchor(BOTTOM, control:GetNamedChild("MapFrame"), BOTTOM, 0, -15)
    self.autoNavigationContinueKeybind = autoNavigationContinueKeybind

    WORLD_MAP_RESPAWN_TIMER_FRAGMENT_KEYBOARD = ZO_FadeSceneFragment:New(ZO_WorldMapRespawnTimer)
    ZO_MixinHideableSceneFragment(WORLD_MAP_RESPAWN_TIMER_FRAGMENT_KEYBOARD)
    WORLD_MAP_RESPAWN_TIMER_FRAGMENT_KEYBOARD:SetHiddenForReason("TimerInactive", true)

    WORLD_MAP_SCENE:AddFragment(WORLD_MAP_AUTO_NAVIGATION_OVERLAY_FRAGMENT)
    WORLD_MAP_SCENE:AddFragment(WORLD_MAP_RESPAWN_TIMER_FRAGMENT_KEYBOARD)
    GAMEPAD_WORLD_MAP_SCENE:AddFragment(WORLD_MAP_AUTO_NAVIGATION_OVERLAY_FRAGMENT)

    WORLD_MAP_FRAGMENT = ZO_FadeSceneFragment:New(control)
    WORLD_MAP_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            UpdateMovingPins()
            g_dataRegistration:Refresh()
            g_mapPanAndZoom:OnWorldMapShowing()
            self:OnShowing()
            self:TryTriggeringTutorials()
        elseif newState == SCENE_FRAGMENT_HIDING then
            HideAllTooltips()
            ResetMouseOverPins()
            self:OnHiding()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            g_dataRegistration:Refresh()
            self:OnHidden()
        end
    end)

    --Information tooltip mixin
    zo_mixin(InformationTooltip, InformationTooltipMixin)

    self:InitializeKeybinds()

    self:RegisterForEvents()

    self:InitializePlatformStyle()
end

function ZO_WorldMapManager:RegisterForEvents()
    self.control:RegisterForEvent(EVENT_AUTO_MAP_NAVIGATION_TARGET_SET, function()
        self:OnAutoNavigationTargetSet()
    end)

    local function RefreshSuggestionPins()
        self:RefreshSuggestionPins()
    end

    self.control:RegisterForEvent(EVENT_ZONE_STORY_ACTIVITY_TRACKED, RefreshSuggestionPins)
    self.control:RegisterForEvent(EVENT_ZONE_STORY_ACTIVITY_UNTRACKED, RefreshSuggestionPins)

    local function RefreshAntiquityDigSites()
        self:RefreshAllAntiquityDigSites()
    end

    ANTIQUITY_DATA_MANAGER:RegisterCallback("AntiquitiesUpdated", RefreshAntiquityDigSites)
    ANTIQUITY_DATA_MANAGER:RegisterCallback("SingleAntiquityDigSitesUpdated", RefreshAntiquityDigSites)
    self.control:RegisterForEvent(EVENT_ANTIQUITY_TRACKING_UPDATE, RefreshAntiquityDigSites)

    CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function()
        self:OnWorldMapChanged()
    end)
end

do
    local KEYBOARD_STYLE =
    {
        hideAutoNavigationContinueKeybindBackground = false,
    }

    local GAMEPAD_STYLE =
    {
        hideAutoNavigationContinueKeybindBackground = true,
    }

    function ZO_WorldMapManager:InitializePlatformStyle()
        self.platformStyle = ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)
    end
end

function ZO_WorldMapManager:ApplyPlatformStyle(style)
    local autoNavigationContinueKeybind = self.autoNavigationContinueKeybind
    ApplyTemplateToControl(autoNavigationContinueKeybind, ZO_GetPlatformTemplate("ZO_KeybindButton"))
    autoNavigationContinueKeybind:GetNamedChild("Bg"):SetHidden(style.hideAutoNavigationContinueKeybindBackground)
    -- Reset the text here to handle the force uppercase on gamepad
    autoNavigationContinueKeybind:SetText(GetString(SI_WORLD_MAP_ANTIQUITIES_CONTINUE))
end

function ZO_WorldMapManager:Update(currentFrameTimeS)
    self:RefreshAutoNavigation(currentFrameTimeS)
    self:RefreshAntiquityDigSitePings(currentFrameTimeS)
end

function ZO_WorldMapManager:CreateKeyboardWorldMapScene()
    WORLD_MAP_SCENE = ZO_Scene:New("worldMap", SCENE_MANAGER)
    WORLD_MAP_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            g_keybindStrips.zoomKeybind:SetHidden(false)
            SCENE_MANAGER:AddFragment(WORLD_MAP_ZONE_STORY_KEYBOARD_FRAGMENT)
            KEYBIND_STRIP:AddKeybindButtonGroup(g_keybindStrips.PC:GetDescriptor())
            if g_pendingKeepInfo then
                WORLD_MAP_KEEP_INFO:ShowKeep(g_pendingKeepInfo)
                g_pendingKeepInfo = nil
            end
        elseif newState == SCENE_HIDDEN then
            g_keybindStrips.zoomKeybind:SetHidden(true)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(g_keybindStrips.PC:GetDescriptor())
            KEYBIND_STRIP:RemoveKeybindButtonGroup(g_keybindStrips.mouseover:GetDescriptor())
        end
    end)
end

function ZO_WorldMapManager:CreateGamepadWorldMapScene()
    GAMEPAD_WORLD_MAP_SCENE = ZO_Scene:New("gamepad_worldMap", SCENE_MANAGER)
    GAMEPAD_WORLD_MAP_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            ZO_WorldMap_SetGamepadKeybindsShown(true)
            SCENE_MANAGER:AddFragment(WORLD_MAP_ZONE_STORY_GAMEPAD_FRAGMENT)
            if g_pendingKeepInfo then
                GAMEPAD_WORLD_MAP_KEEP_INFO:ShowKeep(g_pendingKeepInfo)
                g_pendingKeepInfo = nil
            end
            if ZO_WorldMapButtonsToggleSize then
                ZO_WorldMapButtonsToggleSize:SetHidden(true)
            end
        elseif newState == SCENE_HIDING then
            ZO_WorldMap_SetDirectionalInputActive(false)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(g_keybindStrips.gamepad:GetDescriptor())
            KEYBIND_STRIP:RemoveKeybindButtonGroup(g_keybindStrips.gamepadCloseOptions:GetDescriptor())
        elseif newState == SCENE_HIDDEN then
            g_gamepadMap:StopMotion()
            if ZO_WorldMapButtonsToggleSize then
                ZO_WorldMapButtonsToggleSize:SetHidden(false)
            end

            ZO_SavePlayerConsoleProfile()
            ZO_WorldMap_SetGamepadKeybindsShown(false)
        end
    end)
end

function ZO_WorldMapManager:OnShowing()
    self:FireCallbacks("Showing")
end

function ZO_WorldMapManager:OnHiding()
    self:FireCallbacks("Hiding")
end

function ZO_WorldMapManager:OnHidden()
    self:ClearAutoNavigation()
    self:ClearQuestPings()

    self:FireCallbacks("Hidden")
end

function ZO_WorldMapManager:OnWorldMapChanged()
    self:HidePinPointerBox()
end

function ZO_WorldMapManager:InitializeKeybinds()
    local zoomKeybind = self.control:GetNamedChild("ZoomKeybind")
    zoomKeybind:SetCustomKeyText(GetString(SI_WORLD_MAP_ZOOM_KEY))
    zoomKeybind:SetText(GetString(SI_WORLD_MAP_ZOOM))
    zoomKeybind:SetKeybindEnabledInEdit(true)
    zoomKeybind:SetMouseOverEnabled(false)
    g_keybindStrips.zoomKeybind = zoomKeybind

    local function EndDigSiteReveal()
        self:EndDigSiteReveal()
    end

    local sharedKeybindStrip =
    {
        -- Recenter
        {
            name = GetString(SI_WORLD_MAP_CURRENT_LOCATION),
            keybind = "UI_SHORTCUT_SECONDARY",
            visible = function()
                return self:IsMapChangingAllowed()
            end,
            enabled = function()
                return not self:IsAutoNavigating()
            end,
            callback = function()
                if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
                    local forceGameSelectedMap = false
                    PlayerChosenMapUpdate(forceGameSelectedMap)
                end
                ZO_WorldMap_PanToPlayer()
            end,
        },
    }

    local function AddSharedKeybindStrip(descriptor)
        for i, v in ipairs(sharedKeybindStrip) do
            table.insert(descriptor, v)
        end
    end

    local zoomPCDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Zoom
        {
            customKeybindControl = zoomKeybind,
            keybind = "",
            visible = function()
                return g_mapPanAndZoom:CanMapZoom() and not self:IsAnimatingDigSites()
            end,
            enabled = function()
                return not self:IsAutoNavigating()
            end,
        },
        {
            keybind = "UI_SHORTCUT_PRIMARY",
            ethereal = true,
            enabled = function()
                return self:IsAnimatingDigSites()
            end,
            callback = EndDigSiteReveal,
        },
    }

    AddSharedKeybindStrip(zoomPCDescriptor)

    g_keybindStrips.PC = ZO_MapZoomKeybindStrip:New(self.control, zoomPCDescriptor)

    local gamepadDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor(),

        -- Gamepad zoom in
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad World Map Zoom In",
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
            ethereal = true,
        },
        -- Gamepad zoom out
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad World Map Zoom Out",
            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
            ethereal = true,
        },
        -- Gamepad go up a level on a map with floors
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad World Map Up Level",
            keybind = "UI_SHORTCUT_LEFT_SHOULDER",
            ethereal = true,
            enabled = function()
                return not self:IsPreventingMapNavigation()
            end,
            callback = function()
                local currentFloor, numFloors = GetMapFloorInfo()
                if numFloors > 0 and currentFloor ~= numFloors then
                    ZO_WorldMap_ChangeFloor(ZO_WorldMapButtonsFloorsDown)
                else
                    if self:IsMapChangingAllowed(CONSTANTS.ZOOM_DIRECTION_OUT) and MapZoomOut() == SET_MAP_RESULT_MAP_CHANGED then
                        g_gamepadMap:StopMotion()
                        local NAVIGATE_OUT = false
                        PlayerChosenMapUpdate(nil, NAVIGATE_OUT)
                    end
                end
            end,
        },
        -- Gamepad go down a level on a map with floors
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad World Map Down Level",
            keybind = "UI_SHORTCUT_RIGHT_SHOULDER",
            ethereal = true,
            enabled = function()
                return not self:IsPreventingMapNavigation()
            end,
            callback = function()
                local currentFloor, numFloors = GetMapFloorInfo()
                if numFloors > 0 then
                    ZO_WorldMap_ChangeFloor(ZO_WorldMapButtonsFloorsUp)
                else
                    if self:IsMapChangingAllowed(CONSTANTS.ZOOM_DIRECTION_IN) and ProcessMapClick(NormalizePreferredMousePositionToMap()) == SET_MAP_RESULT_MAP_CHANGED then
                        g_gamepadMap:StopMotion()
                        local NAVIGATE_IN = true
                        PlayerChosenMapUpdate(nil, NAVIGATE_IN)
                    end
                end
            end,
        },
        -- Gamepad selection of pins
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad World Map Select Pin",
            ethereal = true,
            keybind = "UI_SHORTCUT_PRIMARY",
            enabled = function()
                if WORLD_MAP_MANAGER:IsAnimatingDigSites() then
                    return true
                end
                return ZO_WorldMap_WouldPinHandleClick(nil, MOUSE_BUTTON_INDEX_LEFT) and not self:IsAutoNavigating()
            end,
            callback = function()
                if WORLD_MAP_MANAGER:IsAnimatingDigSites() then
                    EndDigSiteReveal()
                else
                    ZO_WorldMap_HandlePinClicked(nil, MOUSE_BUTTON_INDEX_LEFT)
                end
            end,
        },
        -- Gamepad bring up Quests, Locations etc
        {
            name = GetString(SI_GAMEPAD_WORLD_MAP_OPTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",
            enabled = function()
                return not self:IsPreventingMapNavigation()
            end,
            callback = function()
                ZO_WorldMapGamepadInteractKeybind:SetHidden(true)

                -- Hide Legend if it is showing
                SCENE_MANAGER:RemoveFragment(GAMEPAD_WORLD_MAP_KEY_FRAGMENT)
                ZO_WorldMap_HideAllTooltips()

                -- Add the World Map Info
                GAMEPAD_WORLD_MAP_INFO:Show()
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Gamepad navigate to Zone Stories
        {
            name = GetString(SI_ZONE_STORY_OPEN_FROM_MAP_ACTION),
            keybind = "UI_SHORTCUT_QUATERNARY",
            visible = function()
                local currentZoneIndex = GetCurrentMapZoneIndex()
                local zoneStoryZoneId = ZO_ExplorationUtils_GetZoneStoryZoneIdByZoneIndex(currentZoneIndex)
                return zoneStoryZoneId ~= 0
            end,
            enabled = function()
                return not self:IsPreventingMapNavigation()
            end,
            callback = function()
                local currentZoneIndex = GetCurrentMapZoneIndex()
                local zoneStoryZoneId = ZO_ExplorationUtils_GetZoneStoryZoneIdByZoneIndex(currentZoneIndex)
                ZONE_STORIES_MANAGER:ShowZoneStoriesScene(zoneStoryZoneId)
            end,
            sound = SOUNDS.GAMEPAD_MENU_FORWARD,
        },
        -- Gamepad bring up keys/legend
        {
            name = GetString(SI_GAMEPAD_WORLD_MAP_LEGEND),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            enabled = function()
                return not self:IsPreventingMapNavigation()
            end,
            callback = function()
                if GAMEPAD_WORLD_MAP_KEY_FRAGMENT:IsShowing() then
                    SCENE_MANAGER:RemoveFragment(GAMEPAD_WORLD_MAP_KEY_FRAGMENT)
                else
                    SCENE_MANAGER:AddFragment(GAMEPAD_WORLD_MAP_KEY_FRAGMENT)
                    PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                end
            end,
        },
        -- Add Waypoint
        {
            name = function()
                if g_keybindStrips.gamepad:IsOverPinType(MAP_PIN_TYPE_PLAYER_WAYPOINT) then
                    return GetString(SI_WORLD_MAP_ACTION_REMOVE_PLAYER_WAYPOINT)
                else
                    return GetString(SI_WORLD_MAP_ACTION_SET_PLAYER_WAYPOINT)
                end
            end,
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            visible = function()
                return not IsShowingCosmicMap() and IsMouseOverMap()
            end,
            callback = function()
                if g_keybindStrips.gamepad:IsOverPinType(MAP_PIN_TYPE_PLAYER_WAYPOINT) then
                    ZO_WorldMap_RemovePlayerWaypoint()
                else
                    local x, y = NormalizePreferredMousePositionToMap()
                    if ZO_WorldMap_IsNormalizedPointInsideMapBounds(x, y) then
                        PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, x, y)
                        g_keybindStrips.gamepad:DoMouseEnterForPinType(MAP_PIN_TYPE_PLAYER_WAYPOINT) -- this should have been called by the mouseover update, but it's not getting called
                    end
                end
            end,
        }
    }

    AddSharedKeybindStrip(gamepadDescriptor)

    -- Gamepad uses fake mouseover (the cursor acts like a mouse) events to handle tooltips and keybinds.
    g_keybindStrips.gamepad = ZO_MapMouseoverKeybindStrip:New(self.control, gamepadDescriptor)

    local gamepadDescriptorCloseOptions =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Gamepad bring up Quests, Locations etc
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = "Gamepad World Map Hide Info",
            keybind = "UI_SHORTCUT_NEGATIVE",
            ethereal = true,
            callback = function()
                -- Remove the World Map Info
                KEYBIND_STRIP:RemoveKeybindButtonGroup(g_keybindStrips.gamepadCloseOptions:GetDescriptor())
                GAMEPAD_WORLD_MAP_INFO:Hide()
            end,
        },
    }

    -- Gamepad has an options mode. This is the keybind for closing the options
    g_keybindStrips.gamepadCloseOptions = ZO_MapZoomKeybindStrip:New(self.control, gamepadDescriptorCloseOptions)

    local gamepadDescriptorCloseKeep =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,

        -- Gamepad bring up Quests, Locations etc
        {
            keybind = "UI_SHORTCUT_NEGATIVE",
            name = GetString(SI_GAMEPAD_BACK_OPTION),
            callback = function()
                GAMEPAD_WORLD_MAP_KEEP_INFO:HideKeep()
            end,
        },
    }

    -- Gamepad has a keep mode. This is the keybind for closing the keep
    g_keybindStrips.gamepadCloseKeep = ZO_MapZoomKeybindStrip:New(self.control, gamepadDescriptorCloseKeep)

    local mouseoverDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Add Waypoint
        {
            name = function()
                if g_keybindStrips.mouseover:IsOverPinType(MAP_PIN_TYPE_PLAYER_WAYPOINT) then
                    return GetString(SI_WORLD_MAP_ACTION_REMOVE_PLAYER_WAYPOINT)
                else
                    return GetString(SI_WORLD_MAP_ACTION_SET_PLAYER_WAYPOINT)
                end
            end,
            keybind = "UI_SHORTCUT_TERTIARY",
            visible = function()
                return not IsShowingCosmicMap() and IsMouseOverMap()
            end,
            callback = function()
                if g_keybindStrips.mouseover:IsOverPinType(MAP_PIN_TYPE_PLAYER_WAYPOINT) then
                    ZO_WorldMap_RemovePlayerWaypoint()
                else
                    local x, y = NormalizePreferredMousePositionToMap()
                    if ZO_WorldMap_IsNormalizedPointInsideMapBounds(x, y) then
                        PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, x, y)
                        g_keybindStrips.mouseover:DoMouseEnterForPinType(MAP_PIN_TYPE_PLAYER_WAYPOINT) -- this should have been called by the mouseover update, but it's not getting called
                    end
                end
            end,
        },
    }

    g_keybindStrips.mouseover = ZO_MapMouseoverKeybindStrip:New(self.control, mouseoverDescriptor)
end

--
-- Auto Navigation Functions
--

function ZO_WorldMapManager:OnAutoNavigationTargetSet()
    if HasAutoMapNavigationTarget() and self:IsMapChangingAllowed() then
        local hasMapChanged = false

        if not ZO_WorldMap_IsWorldMapShowing() then
            -- We're about to choose a map, and it's based on the players location map unless we're manually viewing a different map
            if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
                hasMapChanged = true
            end
        end

        local mapIndex = GetAutoMapNavigationCommonZoomOutMapIndex()
        if mapIndex then
            self.autoNavigationState = AUTO_NAVIGATION_STATE.WAITING_TO_PAN
            self.autoNavigationDelayUntilFrameTimeS = GetFrameTimeSeconds() + AUTO_NAVIGATION_CONSTANTS.START_PAN_DELAY_S
            g_playerChoseCurrentMap = true

            ZO_WorldMap_MarkKeybindStripsDirty()

            if SetMapToMapListIndex(mapIndex) == SET_MAP_RESULT_MAP_CHANGED then
                hasMapChanged = true
            end

            ZO_WorldMap_ShowWorldMap()

            -- make sure to update the map pings so that the auto-nav ping appears
            if hasMapChanged then
                CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
            else
                RefreshMapPings()
            end

            g_mapPanAndZoom:SetNormalizedZoomAndOffsetInNewMap(AUTO_NAVIGATION_CONSTANTS.START_ZOOM)
        else
            -- We can't actually auto navigate from where we are to where we're going
            self:ClearAutoNavigation()

            if hasMapChanged then
                CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
            end
        end
    end
end

function ZO_WorldMapManager:IsAutoNavigating()
    return self.autoNavigationState ~= AUTO_NAVIGATION_STATE.INACTIVE
end

function ZO_WorldMapManager:ShouldShowAutoNavigateHighlightBlob()
    return self.autoNavigationState >= AUTO_NAVIGATION_STATE.PANNING
end

function ZO_WorldMapManager:RefreshAutoNavigation(currentFrameTimeS)
    if HasAutoMapNavigationTarget() then
        local normalizedX, normalizedY = GetAutoMapNavigationNormalizedPositionForCurrentMap()

        if self.autoNavigationState == AUTO_NAVIGATION_STATE.WAITING_TO_PAN then
            if self.autoNavigationDelayUntilFrameTimeS <= currentFrameTimeS then
                g_mapPanAndZoom:PanToNormalizedPosition(normalizedX, normalizedY)
                if g_mapPanAndZoom:CanMapZoom() then
                    PlaySound(SOUNDS.MAP_AUTO_NAVIGATION_BEGIN_ZOOM)
                end
                self.autoNavigationState = AUTO_NAVIGATION_STATE.PANNING
            end
        elseif self.autoNavigationState == AUTO_NAVIGATION_STATE.PANNING then
            if g_mapPanAndZoom:ReachedTargetOffset() then
                if WouldProcessMapClick(normalizedX, normalizedY) then
                    self.autoNavigationDelayUntilFrameTimeS = currentFrameTimeS + AUTO_NAVIGATION_CONSTANTS.CLICK_DELAY_S
                    self.autoNavigationState = AUTO_NAVIGATION_STATE.WAITING_TO_CLICK
                else
                    self:TryShowAutoMapNavigationTargetMap(currentFrameTimeS)
                end
            end
        elseif self.autoNavigationState == AUTO_NAVIGATION_STATE.WAITING_TO_CLICK then
            if self.autoNavigationDelayUntilFrameTimeS <= currentFrameTimeS then
                if ProcessMapClick(normalizedX, normalizedY) == SET_MAP_RESULT_MAP_CHANGED then
                    self:HandleAutoNavigationMapChange(currentFrameTimeS)
                else
                    self:TryShowAutoMapNavigationTargetMap(currentFrameTimeS)
                end
            end
        end
    end
end

function ZO_WorldMapManager:HandleAutoNavigationMapChange(currentFrameTimeS)
    local SIMULATE_PLAYER_CHOSEN = true
    local NAVIGATE_IN = true
    PlayerChosenMapUpdate(SIMULATE_PLAYER_CHOSEN, NAVIGATE_IN)
    self.autoNavigationDelayUntilFrameTimeS = currentFrameTimeS + AUTO_NAVIGATION_CONSTANTS.PAN_DELAY_S
    self.autoNavigationState = AUTO_NAVIGATION_STATE.WAITING_TO_PAN
    PlaySound(SOUNDS.MAP_AUTO_NAVIGATION_MAP_CHANGE)
end

function ZO_WorldMapManager:TryShowAutoMapNavigationTargetMap(currentFrameTimeS)
    -- We got to the final map we could click in to, but try to show the actual map
    -- for the auto navigation position in case it's not this map
    local setMapResult = SetMapToAutoMapNavigationTargetPosition()
    if setMapResult == SET_MAP_RESULT_MAP_CHANGED then
        self:HandleAutoNavigationMapChange(currentFrameTimeS)
    else
        -- No further to go
        self:OnAutoNavigationComplete()
    end
end

function ZO_WorldMapManager:OnAutoNavigationComplete()
    -- TODO: Figure out a better generic solution when there can be more than one of these at a time
    if not IsInGamepadPreferredMode() then
        local pin = g_mapPinManager:FindPin("suggestion")
        if pin then
            self:AssignPointerBoxToPin(pin)
        end
    end

    self:ClearAutoNavigation()
end

function ZO_WorldMapManager:StopAutoNavigationMovement()
    self.autoNavigationState = AUTO_NAVIGATION_STATE.INACTIVE
    self.autoNavigationDelayUntilFrameTimeS = nil

    -- make sure to refresh the fragment so the conditional will re-evaluate and the fragment will hide
    WORLD_MAP_AUTO_NAVIGATION_OVERLAY_FRAGMENT:Refresh()

    ZO_WorldMap_MarkKeybindStripsDirty()
end

function ZO_WorldMapManager:ClearAutoNavigation()
    self:StopAutoNavigationMovement()
    ClearAutoMapNavigationTarget()

    -- Typically we only refresh pings when a map changes, but the auto nav ping is only meant to last for as long as we have a navigation target.
    g_mapPinManager:RemovePins("pings", MAP_PIN_TYPE_AUTO_MAP_NAVIGATION_PING)
end

--
-- End Auto Navigation Functions
--

function ZO_WorldMapManager:ClearQuestPings()
    if g_questPingData then
        g_questPingData = nil
        g_mapPinManager:RemovePins("pings", MAP_PIN_TYPE_QUEST_PING)
    end
end

do
    local ZONE_COMPLETION_TYPE_WITHOUT_PIN =
    {
        [ZONE_COMPLETION_TYPE_MAGES_GUILD_BOOKS] = true,
        [ZONE_COMPLETION_TYPE_SKYSHARDS] = true,
        [ZONE_COMPLETION_TYPE_FEATURED_ACHIEVEMENTS] = true,
    }

    function ZO_WorldMapManager:RefreshSuggestionPins()
        g_mapPinManager:RemovePins("suggestion")

        if IsZoneStoryActivelyTracking() then
            local zoneId, zoneCompletionType, activityId = GetTrackedZoneStoryActivityInfo()
            if not ZONE_COMPLETION_TYPE_WITHOUT_PIN[zoneCompletionType] then
                local normalizedX, normalizedY, normalizedRadius, isShownInCurrentMap = GetNormalizedPositionForZoneStoryActivityId(zoneId, zoneCompletionType, activityId)
                if isShownInCurrentMap then
                    if zoneCompletionType == ZONE_COMPLETION_TYPE_PRIORITY_QUESTS then
                        if not ZO_WorldMap_DoesMapHideQuestPins() then
                            local questOfferTag = ZO_MapPin.CreateZoneStoryTag(zoneId, zoneCompletionType, activityId)
                            questOfferTag.isBreadcrumb = false -- TODO: Zone Stories: Hook up quest offer breadcrumbing
                            g_mapPinManager:CreatePin(MAP_PIN_TYPE_TRACKED_QUEST_OFFER_ZONE_STORY, questOfferTag, normalizedX, normalizedY, normalizedRadius)
                        end
                    else
                        -- Everything else is a POI
                        local zoneIndex, poiIndex = GetPOIIndices(activityId)
                        if zoneIndex == GetCurrentMapZoneIndex() then
                            local DONT_ENFORCE_NEARBY = false
                            local icon = GetPOIPinIcon(activityId, DONT_ENFORCE_NEARBY)
                            local suggestedPOITag = ZO_MapPin.CreatePOIPinTag(zoneIndex, poiIndex, icon)
                            g_mapPinManager:CreatePin(MAP_PIN_TYPE_POI_SUGGESTED, suggestedPOITag, normalizedX, normalizedY, normalizedRadius)
                        end
                    end
                end
            end
        end
    end
end

--
-- Antiquity Dig Site Functions
--

function ZO_WorldMapManager:SetFocusedAntiquityId(antiquityId)
    self.focusedAntiquityId = antiquityId
end

function ZO_WorldMapManager:ClearFocusedAntiquityId()
    self:SetFocusedAntiquityId(nil)
end

function ZO_WorldMapManager:GetFocusedAntiquityId()
    return self.focusedAntiquityId
end

function ZO_WorldMapManager:AddDigSite(digSiteId, pinType, normalizedX, normalizedY, borderInformation)
    local tag = ZO_MapPin.CreateAntiquityDigSitePinTag(digSiteId)
    if self:IsInMode(MAP_MODE_DIG_SITES) then
        local pinInfo =
        {
            digSiteId = digSiteId,
            pinType = pinType,
            normalizedX = normalizedX,
            normalizedY = normalizedY,
            borderInformation = borderInformation,
            tag = tag,
        }
        table.insert(self.antiquityDigSitePinInfo, pinInfo)
    else
        local NO_RADIUS = 0
        g_mapPinManager:CreatePin(pinType, tag, normalizedX, normalizedY, NO_RADIUS, borderInformation)
    end
end

function ZO_WorldMapManager:ClearDigSitePings()
    self.antiquityDigSitePinInfo = {}
    g_mapPinManager:RemovePins("pings", MAP_PIN_TYPE_ANTIQUITY_DIG_SITE_PING)
end

function ZO_WorldMapManager:IsAnimatingDigSites()
    return self.antiquityDigSiteAnimationState ~= ANTIQUITY_DIG_SITE_ANIMATION_STATE.INACTIVE
end

function ZO_WorldMapManager:EndDigSiteReveal(shouldSupressSound)
    if not shouldSupressSound then
        PlaySound(SOUNDS.POSITIVE_CLICK)
    end
    self:ClearFocusedAntiquityId()
    self:PopSpecialMode()
    self.autoNavigationContinueKeybind:SetHidden(true)
    ZO_WorldMap_MarkKeybindStripsDirty()
    g_mapPanAndZoom:SetCurrentNormalizedZoom(0)

    self.antiquityDigSiteAnimationState = ANTIQUITY_DIG_SITE_ANIMATION_STATE.INACTIVE

    -- make sure to refresh the fragment so the conditional will re-evaluate and the fragment will hide
    WORLD_MAP_AUTO_NAVIGATION_OVERLAY_FRAGMENT:Refresh()
end

function ZO_WorldMapManager:RefreshAntiquityDigSitePings(currentFrameTimeS)
    if self:IsInMode(MAP_MODE_DIG_SITES) then
        if self.antiquityDigSiteAnimationState == ANTIQUITY_DIG_SITE_ANIMATION_STATE.INITIALIZE_ANIMATIONS then
            if self.antiquityDigSiteAnimationDelayUntilFrameTimeS <= currentFrameTimeS then
                table.sort(self.antiquityDigSitePinInfo, function(left, right)
                    return left.normalizedY < right.normalizedY
                end)

                for index, pinInfo in ipairs(self.antiquityDigSitePinInfo) do
                    pinInfo.pingStartTimeS = currentFrameTimeS + (index - 1) * ANTIQUITY_DIG_SITE_ANIMATION_CONSTANTS.TIME_BETWEEN_PINGS_S
                end

                self.antiquityDigSiteAnimationState = ANTIQUITY_DIG_SITE_ANIMATION_STATE.TRIGGER_ANIMATIONS
            end
        elseif self.antiquityDigSiteAnimationState == ANTIQUITY_DIG_SITE_ANIMATION_STATE.TRIGGER_ANIMATIONS then
            local addedAllPins = true
            for index, pinInfo in ipairs(self.antiquityDigSitePinInfo) do
                if not pinInfo.addedDigSite then
                    addedAllPins = false

                    if pinInfo.addDigSiteTime and pinInfo.addDigSiteTime <= currentFrameTimeS then
                        local NO_RADIUS = 0
                        local pin = g_mapPinManager:CreatePin(pinInfo.pinType, pinInfo.tag, pinInfo.normalizedX, pinInfo.normalizedY, NO_RADIUS, pinInfo.borderInformation)
                        pinInfo.addedDigSite = true

                        pin:FadeInMapPin()

                        g_mapPinManager:RemovePins("pings", MAP_PIN_TYPE_ANTIQUITY_DIG_SITE_PING, pinInfo.tag)
                    elseif not pinInfo.addDigSiteTime and pinInfo.pingStartTimeS <= currentFrameTimeS then
                        g_mapPinManager:CreatePin(MAP_PIN_TYPE_ANTIQUITY_DIG_SITE_PING, pinInfo.tag, pinInfo.normalizedX, pinInfo.normalizedY)
                        pinInfo.addDigSiteTime = pinInfo.pingStartTimeS + ANTIQUITY_DIG_SITE_ANIMATION_CONSTANTS.PING_DURATION_S
                    end
                end
            end

            if addedAllPins then
                self.antiquityDigSiteAnimationState = ANTIQUITY_DIG_SITE_ANIMATION_STATE.FINISH_ANIMATIONS
            end
        elseif self.antiquityDigSiteAnimationState == ANTIQUITY_DIG_SITE_ANIMATION_STATE.FINISH_ANIMATIONS then
            self:ClearDigSitePings()
            self.autoNavigationContinueKeybind:SetHidden(false)
        end
    end
end

function ZO_WorldMapManager:TryAddDigSiteToMap(digSiteId, isTracked)
    local centerX, centerZ, isShownInCurrentMap = GetDigSiteNormalizedCenterPosition(digSiteId)
    if isShownInCurrentMap then
        local points = {}

        local minX = 1.0
        local maxX = 0.0
        local minY = 1.0
        local maxY = 0.0

        local borderPoints = { GetDigSiteNormalizedBorderPoints(digSiteId) }
        for i = 1, #borderPoints, 2 do -- loop by 2 because we are getting x and z coordinates
            local x = borderPoints[i]
            local y = borderPoints[i + 1] -- UI is going to treat z as y

            minX = zo_min(x, minX)
            maxX = zo_max(x, maxX)

            minY = zo_min(y, minY)
            maxY = zo_max(y, maxY)

            local coordinates =
            {
                x = x,
                y = y,
            }
            table.insert(points, coordinates)
        end

        for index, coordinates in ipairs(points) do
            coordinates.x = zo_normalize(coordinates.x, minX, maxX)
            coordinates.y = zo_normalize(coordinates.y, minY, maxY)
        end

        local borderInformation =
        {
            borderPoints = points,
            borderWidth = maxX - minX,
            borderHeight = maxY - minY,
        }

        local pinType = isTracked and MAP_PIN_TYPE_TRACKED_ANTIQUITY_DIG_SITE or MAP_PIN_TYPE_ANTIQUITY_DIG_SITE

        self:AddDigSite(digSiteId, pinType, centerX, centerZ, borderInformation)
    end
end

function ZO_WorldMapManager:RefreshAllAntiquityDigSites()
    g_mapPinManager:RemovePins("antiquityDigSite")
    self:ClearDigSitePings()

    if ZO_WorldMap_DoesMapHideQuestPins() or not ZO_WorldMap_IsPinGroupShown(MAP_FILTER_DIG_SITES) then
        return false
    end

    local digSites = {}

    local focusedAntiquityId = self:GetFocusedAntiquityId()

    local numInProgressAntiquities = GetNumInProgressAntiquities()
    for antiquityIndex = 1, numInProgressAntiquities do
        if focusedAntiquityId == nil or GetInProgressAntiquityId(antiquityIndex) == focusedAntiquityId then
            local numDigSites = GetNumDigSitesForInProgressAntiquity(antiquityIndex)
            for digSiteIndex = 1, numDigSites do
                local digSiteId = GetInProgressAntiquityDigSiteId(antiquityIndex, digSiteIndex)
                digSites[digSiteId] = digSites[digSiteId] or IsDigSiteAssociatedWithTrackedAntiquity(digSiteId)
            end
        end
    end

    for digSiteId, isTracked in pairs(digSites) do
        self:TryAddDigSiteToMap(digSiteId, isTracked)
    end
end

function ZO_WorldMapManager:RevealAntiquityDigSpotsOnMap(antiquityId)
    self:PushSpecialMode(MAP_MODE_DIG_SITES)
    self:SetFocusedAntiquityId(antiquityId)

    self:ShowAntiquityOnMap(antiquityId)

    if self.antiquityDigSiteAnimationState == ANTIQUITY_DIG_SITE_ANIMATION_STATE.INACTIVE then
        self.antiquityDigSiteAnimationState = ANTIQUITY_DIG_SITE_ANIMATION_STATE.INITIALIZE_ANIMATIONS
        self.antiquityDigSiteAnimationDelayUntilFrameTimeS = GetFrameTimeSeconds() + ANTIQUITY_DIG_SITE_ANIMATION_CONSTANTS.START_ADDING_PINGS_DELAY_S
        g_mapPanAndZoom:SetCurrentNormalizedZoom(0)
        ZO_WorldMap_MarkKeybindStripsDirty()
    end
end

function ZO_WorldMapManager:ShowAntiquityOnMap(antiquityId)
    if WORLD_MAP_INFO then
        WORLD_MAP_INFO:SelectTab(SI_MAP_INFO_MODE_ANTIQUITIES)
    end

    ZO_WorldMap_ShowWorldMap()

    self:RefreshAllAntiquityDigSites()

    g_playerChoseCurrentMap = true

    local antiquityData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)
    local changedMap = false
    local zoneId = antiquityData:GetZoneId()
    local mapIndex = GetMapIndexByZoneId(zoneId)
    if mapIndex then
        -- If the antiquity is restricted to a zone, show its zone map
        if SetMapToMapListIndex(mapIndex) == SET_MAP_RESULT_MAP_CHANGED then
            changedMap = true
        end
    elseif antiquityData:HasDiscoveredDigSites() then
        -- If no associated zone map get the first dig site and try to show its map
        local firstDigSiteId = GetInProgressAntiquityDigSiteId(antiquityData:GetId(), 1)
        if SetMapToDigSitePosition(firstDigSiteId) == SET_MAP_RESULT_MAP_CHANGED then
            changedMap = true
        end
    else
        -- just set the map to the player's current map
        if SetMapToPlayerLocation() == SET_MAP_RESULT_MAP_CHANGED then
            changedMap = true
        end
    end

    if changedMap then
        CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
    end
end

--
-- End Antiquity Dig Site Functions
--

function ZO_WorldMapManager:AssignPointerBoxToPin(pin)
    if POINTER_BOXES and pin then
        local shortDescription = pin:GetShortDescription()
        if shortDescription then
            if not self.pinPointerBox then
                self.pinPointerBox = POINTER_BOXES:Acquire()
                self.pinPointerBoxContents = self.control:GetNamedChild("PinPointerBoxContents")
                self.pinPointerBox:SetContentsControl(self.pinPointerBoxContents)
                self.pinPointerBox:SetHideWithFragment(WORLD_MAP_FRAGMENT)
                self.pinPointerBox:SetCloseable(true)
            end

            self.pinPointerBox:SetParent(pin:GetControl())
            local normalizedX = pin:GetNormalizedPosition()
            if normalizedX < 0.5 then
                self.pinPointerBox:SetAnchor(LEFT, pin:GetControl(), RIGHT, 10, 0)
            else
                self.pinPointerBox:SetAnchor(RIGHT, pin:GetControl(), LEFT, -10, 0)
            end
            self.pinPointerBoxContents:SetText(shortDescription)
            self.pinPointerBox:Commit()
            self.pinPointerBox:Show()
        end
    end
end

function ZO_WorldMapManager:HidePinPointerBox()
    if self.pinPointerBox then
        self.pinPointerBox:Hide()
    end
end

function ZO_WorldMapManager:HandleMouseDown(button, ctrl, alt, shift)
    self:HidePinPointerBox()
end

function ZO_WorldMapManager:RefreshAll()
    self:RefreshSuggestionPins()
    self:RefreshAllAntiquityDigSites()
end

function ZO_WorldMapManager:IsPreventingMapNavigation()
    return self:IsAutoNavigating() or self:IsAnimatingDigSites()
end

--
-- Map Mode Functions
--

function ZO_WorldMapManager:GetMode()
    return self.mode
end

function ZO_WorldMapManager:IsInMode(mode)
    return self.mode == mode
end

function ZO_WorldMapManager:GetModeData()
    return self.modeData
end

function ZO_WorldMapManager:GetModeMapSize()
    return self.modeData and self.modeData.mapSize or nil
end

function ZO_WorldMapManager:SetUserMode(mode)
    g_savedVars.userMode = mode
    if not self.inSpecialMode then
        self:SetToMode(mode)
    end
end

function ZO_WorldMapManager:PushSpecialMode(mode)
    if not self.inSpecialMode then
        self.inSpecialMode = true
        self:SetToMode(mode)
    end
end

function ZO_WorldMapManager:PopSpecialMode()
    if self.inSpecialMode then
        self.inSpecialMode = false
        self:SetToMode(g_savedVars.userMode)
    end
end

function ZO_WorldMapManager:SetToMode(mode)
    self.control:StopMovingOrResizing()

    --store off any settings that aren't maintained in saved variables
    if self.mode == MAP_MODE_SMALL_CUSTOM or self.mode == MAP_MODE_LARGE_CUSTOM then
        local transientData = MAP_TRANSIENT_MODES[self.mode]
        transientData.mapZoom = g_mapPanAndZoom:GetCurrentNormalizedZoom()
        local _, _, _, _, containerOffsetX, containerOffsetY = ZO_WorldMapContainer:GetAnchor(0)
        transientData.offsetX, transientData.offsetY = containerOffsetX, containerOffsetY
    end

    self.mode = mode
    self.modeData = g_savedVars[mode]

    local transientModeData = nil
    if mode == MAP_MODE_SMALL_CUSTOM or mode == MAP_MODE_LARGE_CUSTOM then
        transientModeData = MAP_TRANSIENT_MODES[mode]
    end

    local initialNormalizedZoom = 0
    if transientModeData and transientModeData.mapZoom then
        initialNormalizedZoom = zo_clamp(transientModeData.mapZoom, 0, 1)
    end
    g_mapPanAndZoom:SetCurrentNormalizedZoom(initialNormalizedZoom)

    local smallMap = self.modeData.mapSize == CONSTANTS.WORLDMAP_SIZE_SMALL
    if smallMap then
        ZO_WorldMapTitleBar:SetMouseEnabled(true)
        self.control:SetResizeHandleSize(8)
        SetMapWindowSize(self.modeData.width, self.modeData.height)
        g_mapPanAndZoom:InitializeMap()
        ZO_WorldMapButtonsBG:SetHidden(false)
        ZO_WorldMapTitleBarBG:SetHidden(false)
    else
        ZO_WorldMapTitleBar:SetMouseEnabled(false)
        self.control:SetResizeHandleSize(0)
        ZO_WorldMapContainer:SetAlpha(1)
        self.control:BringWindowToTop()
        local mapWidth, mapHeight = GetFullscreenMapWindowDimensions()
        SetMapWindowSize(mapWidth, mapHeight)
        ZO_WorldMapButtonsBG:SetHidden(true)
        ZO_WorldMapTitleBarBG:SetHidden(true)
    end

    self:RefreshMapFrameAnchor()

    local layout = MAP_CONTAINER_LAYOUT[self.modeData.mapSize]
    if layout.titleBarHeight then
        ZO_WorldMapTitle:SetHidden(false)
        ZO_WorldMapTitleBar:SetHidden(false)
        ZO_WorldMapTitleBar:SetHeight(layout.titleBarHeight)
    else
        ZO_WorldMapTitle:SetHidden(true)
        ZO_WorldMapTitleBar:SetHidden(true)
    end

    if transientModeData then
        g_mapPanAndZoom:SetFinalTargetOffset(transientModeData.offsetX or 0, transientModeData.offsetY or 0, g_mapPanAndZoom:GetCurrentNormalizedZoom())
    else
        g_mapPanAndZoom:SetCurrentOffset(0, 0)
    end

    self:FindAvAKeepMap()

    ZO_WorldMapContainer:SetAlpha(self.modeData.alpha or 1)
    ZO_WorldMap_UpdateMap()
    CALLBACK_MANAGER:FireCallbacks("OnWorldMapModeChanged", self.modeData)
end

function ZO_WorldMapManager:FindAvAKeepMap()
    local desiredMap
    local mode = self:GetMode()
    if mode == MAP_MODE_KEEP_TRAVEL or mode == MAP_MODE_AVA_KEEP_RECALL then
        desiredMap = g_cyrodiilMapIndex
    elseif mode == MAP_MODE_AVA_RESPAWN then
        if IsInImperialCity() then
            desiredMap = g_imperialCityMapIndex
        else
            desiredMap = g_cyrodiilMapIndex
        end
    end

    if desiredMap then
        if GetCurrentMapIndex() == desiredMap then
            g_playerChoseCurrentMap = true
        elseif SetMapToMapListIndex(desiredMap) == SET_MAP_RESULT_MAP_CHANGED then
            g_playerChoseCurrentMap = true
            CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
        end
    end
end

function ZO_WorldMapManager:RefreshMapFrameAnchor()
    self.control:ClearAnchors()
    local modeData = self:GetModeData()
    local smallMap = modeData.mapSize == CONSTANTS.WORLDMAP_SIZE_SMALL
    if smallMap then
        self.control:SetAnchor(modeData.point, nil, modeData.relPoint, modeData.x, modeData.y)
    else
        if IsInGamepadPreferredMode() then
            self.control:SetAnchor(CENTER, nil, CENTER, 0, CONSTANTS.GAMEPAD_CENTER_OFFSET_Y_PIXELS / GetUIGlobalScale())
        else
            self.control:SetAnchor(CENTER, nil, CENTER, 0, CONSTANTS.CENTER_OFFSET_Y_PIXELS / GetUIGlobalScale())
        end
    end
end

function ZO_WorldMapManager:IsMapChangingAllowed(zoomDirection)
    local restrictions = MAP_MODE_CHANGE_RESTRICTIONS[self.mode]
    if restrictions then
        if restrictions.disableMapChanging then
            return false
        elseif restrictions.restrictedCyrodiilImperialCityMapChanging then
            --Restricted means that only zooming will work, and only if the player is inside of Imperial City or Sewers
            --Can only zoom between Cyrodiil and the City itself
            if IsInImperialCity() and zoomDirection then
                local currentMapIndex = GetCurrentMapIndex()
                if zoomDirection == CONSTANTS.ZOOM_DIRECTION_OUT and currentMapIndex == g_imperialCityMapIndex then
                    return true
                elseif zoomDirection == CONSTANTS.ZOOM_DIRECTION_IN and currentMapIndex == g_cyrodiilMapIndex then
                    local wouldProcess, resultingMapIndex = WouldProcessMapClick(NormalizePreferredMousePositionToMap())
                    if wouldProcess and resultingMapIndex == g_imperialCityMapIndex then
                        return true
                    end
                end
            end
            return false
        end
    end
    return true
end

function ZO_WorldMapManager:GetFilterValue(option)
    local modeData = self:GetModeData()
    if modeData and modeData.filters then
        local mapFilterType = GetMapFilterType()
        local filters = modeData.filters[mapFilterType]
        if filters then
            return filters[option]
        end
    end

    return nil
end

function ZO_WorldMapManager:AreStickyPinsEnabledForPinGroup(pinGroup)
    local modeData = self:GetModeData()
    if modeData.disabledStickyPins then
        local mapFilterType = GetMapFilterType()
        local disabledStickyPinsByMapType = modeData.disabledStickyPins[mapFilterType]
        if disabledStickyPinsByMapType then
            return disabledStickyPinsByMapType[pinGroup] ~= true
        end
    end
    return true
end

--
-- End Map Mode Functions
--

function ZO_WorldMapManager:TryTriggeringTutorials()
    if WORLD_MAP_FRAGMENT:IsShowing() then
        local interactionType = GetInteractionType()
        if interactionType == INTERACTION_NONE then
            local mapFilterType = GetMapFilterType()
            if mapFilterType == MAP_FILTER_TYPE_AVA_CYRODIIL then
                TriggerTutorial(TUTORIAL_TRIGGER_MAP_OPENED_CYRODIIL)
            elseif mapFilterType == MAP_FILTER_TYPE_AVA_IMPERIAL then
                TriggerTutorial(TUTORIAL_TRIGGER_MAP_OPENED_IMPERIAL_CITY)
            elseif mapFilterType == MAP_FILTER_TYPE_BATTLEGROUND then
                TriggerTutorial(TUTORIAL_TRIGGER_MAP_OPENED_BATTLEGROUND)
            else
                TriggerTutorial(TUTORIAL_TRIGGER_MAP_OPENED_PVE)
            end

            if self:IsInMode(MAP_MODE_DIG_SITES) then
                TriggerTutorial(TUTORIAL_TRIGGER_MAP_OPENED_ANTIQUITY_DIG_SITES)
            end
        elseif interactionType == INTERACTION_FAST_TRAVEL_KEEP then
            TriggerTutorial(TUTORIAL_TRIGGER_AVA_FAST_TRAVEL)
        elseif interactionType == INTERACTION_FAST_TRAVEL then
            TriggerTutorial(TUTORIAL_TRIGGER_PVE_FAST_TRAVEL)
        end
    end
end
