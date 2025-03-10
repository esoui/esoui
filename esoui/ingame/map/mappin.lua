ZO_MAP_TOOLTIP_MODE =
{
    INFORMATION = 1,
    KEEP = 2,
    MAP_LOCATION = 3,
}

ZO_MapPin = ZO_InitializingObject:Subclass()

local CONSTANTS =
{
    DEFAULT_PIN_SIZE = 20,
    QUEST_PIN_SIZE = 32,
    QUEST_AREA_MIN_SIZE = 18,
    POI_PIN_SIZE = 40,
    MAP_LOCATION_PIN_SIZE = 36,
    PLAYER_PIN_SIZE = 16,
    SMALL_KILL_LOCATION_SIZE = 16,
    MEDIUM_KILL_LOCATION_SIZE = 20,
    LARGE_KILL_LOCATION_SIZE = 24,
    KEEP_PIN_SIZE = 53,
    KEEP_PIN_ACCESSIBLE_SIZE = 70,
    KEEP_PIN_ATTACKED_SIZE = 70,
    ARTIFACT_PIN_SIZE = 64,
    DAEDRIC_ARTIFACT_PIN_SIZE = 32,
    AVA_OBJECTIVE_SIZE = 16,
    KEEP_RESOURCE_PIN_SIZE = 27,
    KEEP_RESOURCE_MIN_SIZE = 24,
    KEEP_RESOURCE_PIN_ATTACKED_SIZE = 36,
    MIN_PIN_SIZE = 18,
    MIN_PIN_SCALE = 0.6,
    MAX_PIN_SCALE = 1,
    RESTRICTED_LINK_PIN_SIZE = 16,
    CAPTURE_AREA_PIN_SIZE = 53,
    CARRYABLE_OBJECTIVE_PIN_SIZE = 64,
    RETURN_OBJECTIVE_PIN_SIZE = 64,
    SUGGESTED_AREA_PIN_SIZE = 40,

    --The highest-priority fast travel pins are 7 higher than the default,
    --so starting with 112 lets us fit between 110 and 120.
    FAST_TRAVEL_DEFAULT_PIN_LEVEL = 112,
}

do
    local function GetPOIPinTexture(pin)
        return pin:GetPOIIcon()
    end

    local function GetPOIPinTint(pin)
        if pin:IsLockedByLinkedCollectible() then
            return LOCKED_COLOR
        else
            return ZO_DEFAULT_ENABLED_COLOR
        end
    end

    local function GetObjectiveAuraPinTint(pin)
        local auraPinType, red, green, blue = GetObjectiveAuraPinInfo(pin:GetObjectiveKeepId(), pin:GetObjectiveObjectiveId(), pin:GetBattlegroundContext())
        if auraPinType ~= MAP_PIN_TYPE_INVALID then
            return ZO_ColorDef:New(red, green, blue)
        else
            return ZO_DEFAULT_ENABLED_COLOR
        end
    end

    local function GetPlayerWaypointPinColor()
        return ZO_ColorDef:New(GetSetting(SETTING_TYPE_ACCESSIBILITY, ACCESSIBILITY_SETTING_PLAYER_WAYPOINT_ICON_COLOR))
    end

    local function GetLocationPinTexture(pin)
        return pin:GetLocationIcon()
    end

    local function GetWorldEventPOIPinTexture(pin)
        return pin:GetWorldEventPOIIcon()
    end

    local function GetWorldEventUnitPinTexture(pin)
        return pin:GetWorldEventUnitIcon()
    end

    local function GetIsWorldEventUnitPinTextureAnimated(pin)
        return pin:GetIsWorldEventUnitIconAnimated()
    end

    local function GetFastTravelPinTextures(pin)
        return pin:GetFastTravelIcons()
    end

    local function GetQuestPinTexture(pin)
        return pin:GetQuestIcon()
    end

    local function GetGroupPinTexture(pin)
        return pin:GetGroupIcon()
    end

    local function GetFastTravelPinDrawLevel(pin)
        return pin:GetFastTravelDrawLevel()
    end

    -- How the texturing data works:
    -- The texture can come from a string or a callback function
    -- If it's a callback function it must return first the base icon texture, and second the pin's pulseTexture
    -- isAnimated can come from a bool or a callback function
    ZO_MapPin.PIN_DATA =
    {
        [MAP_PIN_TYPE_PLAYER]                                       = { level = 170, texture = "EsoUI/Art/MapPins/UI-WorldMapPlayerPip.dds", size = CONSTANTS.PLAYER_PIN_SIZE, mouseLevel = 0 },
        [MAP_PIN_TYPE_PING]                                         = { level = 162, minSize = 32, texture = "EsoUI/Art/MapPins/MapPing.dds", isAnimated = true, framesWide = 32, framesHigh = 1, framesPerSecond = 32 },
        [MAP_PIN_TYPE_RALLY_POINT]                                  = { level = 161, minSize = 100, texture = "EsoUI/Art/MapPins/MapRallyPoint.dds", isAnimated = true, framesWide = 32, framesHigh = 1, framesPerSecond = 32 },
        [MAP_PIN_TYPE_PLAYER_WAYPOINT]                              = { level = 160, minSize = 32, texture = "EsoUI/Art/MapPins/UI_Worldmap_pin_customDestination_white.dds", tint = GetPlayerWaypointPinColor },
        [MAP_PIN_TYPE_GROUP_LEADER]                                 = { level = 151, size = 32, texture = GetGroupPinTexture },
        [MAP_PIN_TYPE_GROUP]                                        = { level = 150, size = 32, texture = GetGroupPinTexture },
        [MAP_PIN_TYPE_ACTIVE_COMPANION]                             = { level = 150, size = 32, texture = "EsoUI/Art/MapPins/activeCompanion_pin.dds" },
        [MAP_PIN_TYPE_UNIT_COMBAT_HEALTHY]                          = { level = 147, size = 64, texture = GetWorldEventUnitPinTexture, isAnimated = GetIsWorldEventUnitPinTextureAnimated, framesWide = 16, framesHigh = 1, framesPerSecond = 12 },
        [MAP_PIN_TYPE_UNIT_COMBAT_WEAK]                             = { level = 147, size = 64, texture = GetWorldEventUnitPinTexture, isAnimated = GetIsWorldEventUnitPinTextureAnimated, framesWide = 16, framesHigh = 1, framesPerSecond = 12 },
        [MAP_PIN_TYPE_UNIT_IDLE_HEALTHY]                            = { level = 147, size = 64, texture = GetWorldEventUnitPinTexture, isAnimated = GetIsWorldEventUnitPinTextureAnimated, framesWide = 16, framesHigh = 1, framesPerSecond = 12 },
        [MAP_PIN_TYPE_UNIT_IDLE_WEAK]                               = { level = 147, size = 64, texture = GetWorldEventUnitPinTexture, isAnimated = GetIsWorldEventUnitPinTextureAnimated, framesWide = 16, framesHigh = 1, framesPerSecond = 12 },
        [MAP_PIN_TYPE_TRACKED_QUEST_OFFER_ZONE_STORY]               = { level = 145, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4, showsPinAndArea = true},
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_CONDITION]          = { level = 145, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = { level = 145, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_ENDING]             = { level = 145, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION]                     = { level = 143, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION]            = { level = 143, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_ASSISTED_QUEST_ENDING]                        = { level = 143, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION]          = { level = 140, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = { level = 140, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_ENDING]             = { level = 140, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_CONDITION]           = { level = 135, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_OPTIONAL_CONDITION]  = { level = 135, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_ENDING]              = { level = 135, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_TRACKED_QUEST_CONDITION]                      = { level = 133, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_TRACKED_QUEST_OPTIONAL_CONDITION]             = { level = 133, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_TRACKED_QUEST_ENDING]                         = { level = 133, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_CONDITION]           = { level = 130, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_OPTIONAL_CONDITION]  = { level = 130, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_ENDING]              = { level = 130, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_CONDITION]                   = { level = 125, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_OPTIONAL_CONDITION]          = { level = 125, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_ENDING]                      = { level = 125, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_QUEST_CONDITION]                              = { level = 123, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_QUEST_OPTIONAL_CONDITION]                     = { level = 123, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_QUEST_ENDING]                                 = { level = 123, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_QUEST_REPEATABLE_CONDITION]                   = { level = 120, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_QUEST_REPEATABLE_OPTIONAL_CONDITION]          = { level = 120, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_QUEST_REPEATABLE_ENDING]                      = { level = 120, size = CONSTANTS.QUEST_PIN_SIZE, minAreaSize = CONSTANTS.QUEST_AREA_MIN_SIZE, texture = GetQuestPinTexture, hitInsetX = 7, hitInsetY = 4},
        [MAP_PIN_TYPE_ANTIQUITY_DIG_SITE]                           = { level = 120, size = 32, texture = nil, },
        [MAP_PIN_TYPE_TRACKED_ANTIQUITY_DIG_SITE]                   = { level = 120, size = 32, texture = nil, },
        [MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE]                        = { level = GetFastTravelPinDrawLevel, size = CONSTANTS.POI_PIN_SIZE, texture = GetFastTravelPinTextures, tint = GetPOIPinTint, hitInsetX = 5, hitInsetY = 10},
        [MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE_CURRENT_LOC]            = { level = CONSTANTS.FAST_TRAVEL_DEFAULT_PIN_LEVEL, size = CONSTANTS.POI_PIN_SIZE, texture = GetFastTravelPinTextures, tint = GetPOIPinTint, hitInsetX = 5, hitInsetY = 10},
        [MAP_PIN_TYPE_FORWARD_CAMP_ALDMERI_DOMINION]                = { level = 110, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_cemetary_aldmeri.dds", hitInsetX = 20, hitInsetY = 20, showsPinAndArea = true},
        [MAP_PIN_TYPE_FORWARD_CAMP_EBONHEART_PACT]                  = { level = 110, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_cemetary_ebonheart.dds", hitInsetX = 20, hitInsetY = 20, showsPinAndArea = true},
        [MAP_PIN_TYPE_FORWARD_CAMP_DAGGERFALL_COVENANT]             = { level = 110, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_cemetary_daggerfall.dds", hitInsetX = 20, hitInsetY = 20, showsPinAndArea = true},
        [MAP_PIN_TYPE_ARTIFACT_ALDMERI_OFFENSIVE]                   = { level = 105, size = CONSTANTS.ARTIFACT_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifact_altadoon.dds", hitInsetX = 17, hitInsetY = 23},
        [MAP_PIN_TYPE_ARTIFACT_ALDMERI_DEFENSIVE]                   = { level = 105, size = CONSTANTS.ARTIFACT_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifact_mnem.dds", hitInsetX = 17, hitInsetY = 23},
        [MAP_PIN_TYPE_ARTIFACT_EBONHEART_OFFENSIVE]                 = { level = 105, size = CONSTANTS.ARTIFACT_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifact_ghartok.dds", hitInsetX = 17, hitInsetY = 23},
        [MAP_PIN_TYPE_ARTIFACT_EBONHEART_DEFENSIVE]                 = { level = 105, size = CONSTANTS.ARTIFACT_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifact_chim.dds", hitInsetX = 17, hitInsetY = 23},
        [MAP_PIN_TYPE_ARTIFACT_DAGGERFALL_OFFENSIVE]                = { level = 105, size = CONSTANTS.ARTIFACT_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifact_nimohk.dds", hitInsetX = 17, hitInsetY = 23},
        [MAP_PIN_TYPE_ARTIFACT_DAGGERFALL_DEFENSIVE]                = { level = 105, size = CONSTANTS.ARTIFACT_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifact_almaruma.dds", hitInsetX = 17, hitInsetY = 23},
        [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_NEUTRAL]      = { level = 100, size = CONSTANTS.DAEDRIC_ARTIFACT_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_daedricArtifact_volendrung_neutral.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_ALDMERI]      = { level = 100, size = CONSTANTS.DAEDRIC_ARTIFACT_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_daedricArtifact_volendrung_aldmeri.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_EBONHEART]    = { level = 100, size = CONSTANTS.DAEDRIC_ARTIFACT_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_daedricArtifact_volendrung_ebonheart.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_DAGGERFALL]   = { level = 100, size = CONSTANTS.DAEDRIC_ARTIFACT_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_daedricArtifact_volendrung_daggerfall.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_FLAG_FIRE_DRAKES]                       = { level = 99, size = CONSTANTS.CARRYABLE_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_flag_pin_orange.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_FLAG_FIRE_DRAKES_AURA]                  = { level = 98, size = CONSTANTS.CARRYABLE_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_flag_halo_orange.dds", tint = GetObjectiveAuraPinTint, hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_FLAG_PIT_DAEMONS]                       = { level = 97, size = CONSTANTS.CARRYABLE_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_flag_pin_green.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_FLAG_PIT_DAEMONS_AURA]                  = { level = 96, size = CONSTANTS.CARRYABLE_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_flag_halo_green.dds", tint = GetObjectiveAuraPinTint, hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_FLAG_STORM_LORDS]                       = { level = 95, size = CONSTANTS.CARRYABLE_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_flag_pin_purple.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_FLAG_STORM_LORDS_AURA]                  = { level = 94, size = CONSTANTS.CARRYABLE_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_flag_halo_purple.dds", tint = GetObjectiveAuraPinTint, hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_FLAG_NEUTRAL]                           = { level = 93, size = CONSTANTS.CARRYABLE_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_flag_pin_neutral.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_FLAG_NEUTRAL_AURA]                      = { level = 92, size = CONSTANTS.CARRYABLE_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_flag_halo_neutral.dds", tint = GetObjectiveAuraPinTint, hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_MURDERBALL_NEUTRAL]                     = { level = 91, size = CONSTANTS.CARRYABLE_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_murderball_neutral.dds"},
        [MAP_PIN_TYPE_BGPIN_MURDERBALL_FIRE_DRAKES]                 = { level = 91, size = CONSTANTS.CARRYABLE_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_murderball_orange.dds"},
        [MAP_PIN_TYPE_BGPIN_MURDERBALL_PIT_DAEMONS]                 = { level = 91, size = CONSTANTS.CARRYABLE_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_murderball_green.dds"},
        [MAP_PIN_TYPE_BGPIN_MURDERBALL_STORM_LORDS]                 = { level = 91, size = CONSTANTS.CARRYABLE_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_murderball_purple.dds"},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_FIRE_DRAKES]               = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_capturePoint_pin_orange.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_PIT_DAEMONS]               = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_capturePoint_pin_green.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_STORM_LORDS]               = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_capturePoint_pin_purple.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_NEUTRAL]                   = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_capturePoint_pin_neutral.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_FIRE_DRAKES]             = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_A_pin_orange.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_PIT_DAEMONS]             = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_A_pin_green.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_STORM_LORDS]             = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_A_pin_purple.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_NEUTRAL]                 = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_A_pin_neutral.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_FIRE_DRAKES]             = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_B_pin_orange.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_PIT_DAEMONS]             = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_B_pin_green.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_STORM_LORDS]             = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_B_pin_purple.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_NEUTRAL]                 = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_B_pin_neutral.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_FIRE_DRAKES]             = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_C_pin_orange.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_PIT_DAEMONS]             = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_C_pin_green.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_STORM_LORDS]             = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_C_pin_purple.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_NEUTRAL]                 = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_C_pin_neutral.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_FIRE_DRAKES]             = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_D_pin_orange.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_PIT_DAEMONS]             = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_D_pin_green.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_STORM_LORDS]             = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_D_pin_purple.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_NEUTRAL]                 = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_multiCapturePoint_D_pin_neutral.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_FIRE_DRAKES]        = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_orange.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_PIT_DAEMONS]        = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_green.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_STORM_LORDS]        = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_purple.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_NEUTRAL]            = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_neutral.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_A_FIRE_DRAKES]      = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_orange_A.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_A_PIT_DAEMONS]      = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_green_A.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_A_STORM_LORDS]      = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_purple_A.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_A_NEUTRAL]          = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_neutral_A.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_B_FIRE_DRAKES]      = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_orange_B.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_B_PIT_DAEMONS]      = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_green_B.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_B_STORM_LORDS]      = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_purple_B.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_B_NEUTRAL]          = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_neutral_B.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_C_FIRE_DRAKES]      = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_orange_C.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_C_PIT_DAEMONS]      = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_green_C.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_C_STORM_LORDS]      = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_purple_C.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_C_NEUTRAL]          = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_neutral_C.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_D_FIRE_DRAKES]      = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_orange_D.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_D_PIT_DAEMONS]      = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_green_D.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_D_STORM_LORDS]      = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_purple_D.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_D_NEUTRAL]          = { level = 86, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_pin_neutral_D.dds", hitInsetX = 13, hitInsetY = 7},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_AURA]                      = { level = 85, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_capturePoint_halo.dds", tint = GetObjectiveAuraPinTint, hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_AURA]               = { level = 85, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_mobileCapturePoint_halo.dds", tint = GetObjectiveAuraPinTint, hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_AURA]                      = { level = 85, size = CONSTANTS.CAPTURE_AREA_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_capturePoint_halo.dds", tint = GetObjectiveAuraPinTint, hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_FLAG_SPAWN_FIRE_DRAKES]                 = { level = 81, size = CONSTANTS.RETURN_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_flagSpawn_pin_orange.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_FLAG_SPAWN_PIT_DAEMONS]                 = { level = 81, size = CONSTANTS.RETURN_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_flagSpawn_pin_green.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_FLAG_SPAWN_STORM_LORDS]                 = { level = 81, size = CONSTANTS.RETURN_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_flagSpawn_pin_purple.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_FLAG_SPAWN_NEUTRAL]                     = { level = 81, size = CONSTANTS.RETURN_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_flagSpawn_pin_neutral.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_MURDERBALL_SPAWN_NEUTRAL]               = { level = 81, size = CONSTANTS.RETURN_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_murderballSpawn_pin_neutral.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_ARTIFACT_RETURN_ALDMERI]                      = { level = 80, texture = "EsoUI/Art/MapPins/AvA_flagBase_Aldmeri.dds"},
        [MAP_PIN_TYPE_ARTIFACT_RETURN_EBONHEART]                    = { level = 80, texture = "EsoUI/Art/MapPins/AvA_flagBase_Ebonheart.dds"},
        [MAP_PIN_TYPE_ARTIFACT_RETURN_DAGGERFALL]                   = { level = 80, texture = "EsoUI/Art/MapPins/AvA_flagBase_Daggerfall.dds"},
        [MAP_PIN_TYPE_BGPIN_FLAG_RETURN_FIRE_DRAKES]                = { level = 80, size = CONSTANTS.RETURN_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_returnPoint_pin_orange.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_FLAG_RETURN_PIT_DAEMONS]                = { level = 80, size = CONSTANTS.RETURN_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_returnPoint_pin_green.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_BGPIN_FLAG_RETURN_STORM_LORDS]                = { level = 80, size = CONSTANTS.RETURN_OBJECTIVE_PIN_SIZE, texture = "EsoUI/Art/MapPins/battlegrounds_returnPoint_pin_purple.dds", hitInsetX = 15, hitInsetY = 11},
        [MAP_PIN_TYPE_TRI_BATTLE_SMALL]                             = { level = 70, size = CONSTANTS.SMALL_KILL_LOCATION_SIZE, texture = "EsoUI/Art/MapPins/AvA_3Way.dds" },
        [MAP_PIN_TYPE_TRI_BATTLE_MEDIUM]                            = { level = 70, size = CONSTANTS.MEDIUM_KILL_LOCATION_SIZE, texture = "EsoUI/Art/MapPins/AvA_3Way.dds" },
        [MAP_PIN_TYPE_TRI_BATTLE_LARGE]                             = { level = 70, size = CONSTANTS.LARGE_KILL_LOCATION_SIZE, texture = "EsoUI/Art/MapPins/AvA_3Way.dds" },
        [MAP_PIN_TYPE_ALDMERI_VS_EBONHEART_SMALL]                   = { level = 70, size = CONSTANTS.SMALL_KILL_LOCATION_SIZE, texture = "EsoUI/Art/MapPins/AvA_AldmeriVEbonheart.dds" },
        [MAP_PIN_TYPE_ALDMERI_VS_EBONHEART_MEDIUM]                  = { level = 70, size = CONSTANTS.MEDIUM_KILL_LOCATION_SIZE, texture = "EsoUI/Art/MapPins/AvA_AldmeriVEbonheart.dds" },
        [MAP_PIN_TYPE_ALDMERI_VS_EBONHEART_LARGE]                   = { level = 70, size = CONSTANTS.LARGE_KILL_LOCATION_SIZE, texture = "EsoUI/Art/MapPins/AvA_AldmeriVEbonheart.dds" },
        [MAP_PIN_TYPE_ALDMERI_VS_DAGGERFALL_SMALL]                  = { level = 70, size = CONSTANTS.SMALL_KILL_LOCATION_SIZE, texture = "EsoUI/Art/MapPins/AvA_AldmeriVDaggerfall.dds" },
        [MAP_PIN_TYPE_ALDMERI_VS_DAGGERFALL_MEDIUM]                 = { level = 70, size = CONSTANTS.MEDIUM_KILL_LOCATION_SIZE, texture = "EsoUI/Art/MapPins/AvA_AldmeriVDaggerfall.dds" },
        [MAP_PIN_TYPE_ALDMERI_VS_DAGGERFALL_LARGE]                  = { level = 70, size = CONSTANTS.LARGE_KILL_LOCATION_SIZE, texture = "EsoUI/Art/MapPins/AvA_AldmeriVDaggerfall.dds" },
        [MAP_PIN_TYPE_EBONHEART_VS_DAGGERFALL_SMALL]                = { level = 70, size = CONSTANTS.SMALL_KILL_LOCATION_SIZE, texture = "EsoUI/Art/MapPins/AvA_EbonheartVDaggerfall.dds" },
        [MAP_PIN_TYPE_EBONHEART_VS_DAGGERFALL_MEDIUM]               = { level = 70, size = CONSTANTS.MEDIUM_KILL_LOCATION_SIZE, texture = "EsoUI/Art/MapPins/AvA_EbonheartVDaggerfall.dds" },
        [MAP_PIN_TYPE_EBONHEART_VS_DAGGERFALL_LARGE]                = { level = 70, size = CONSTANTS.LARGE_KILL_LOCATION_SIZE, texture = "EsoUI/Art/MapPins/AvA_EbonheartVDaggerfall.dds" },
        [MAP_PIN_TYPE_FARM_NEUTRAL]                                 = { level = 60, size = CONSTANTS.KEEP_RESOURCE_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_farm_Neutral.dds", hitInsetX = 9, hitInsetY = 5, minSize = CONSTANTS.KEEP_RESOURCE_MIN_SIZE},
        [MAP_PIN_TYPE_FARM_ALDMERI_DOMINION]                        = { level = 60, size = CONSTANTS.KEEP_RESOURCE_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_farm_Aldmeri.dds", hitInsetX = 9, hitInsetY = 5, minSize = CONSTANTS.KEEP_RESOURCE_MIN_SIZE},
        [MAP_PIN_TYPE_FARM_EBONHEART_PACT]                          = { level = 60, size = CONSTANTS.KEEP_RESOURCE_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_farm_Ebonheart.dds", hitInsetX = 9, hitInsetY = 5, minSize = CONSTANTS.KEEP_RESOURCE_MIN_SIZE},
        [MAP_PIN_TYPE_FARM_DAGGERFALL_COVENANT]                     = { level = 60, size = CONSTANTS.KEEP_RESOURCE_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_farm_Daggerfall.dds", hitInsetX = 9, hitInsetY = 5, minSize = CONSTANTS.KEEP_RESOURCE_MIN_SIZE},
        [MAP_PIN_TYPE_MINE_NEUTRAL]                                 = { level = 60, size = CONSTANTS.KEEP_RESOURCE_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_mine_Neutral.dds", hitInsetX = 5, hitInsetY = 6, minSize = CONSTANTS.KEEP_RESOURCE_MIN_SIZE},
        [MAP_PIN_TYPE_MINE_ALDMERI_DOMINION]                        = { level = 60, size = CONSTANTS.KEEP_RESOURCE_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_mine_Aldmeri.dds", hitInsetX = 5, hitInsetY = 6, minSize = CONSTANTS.KEEP_RESOURCE_MIN_SIZE},
        [MAP_PIN_TYPE_MINE_EBONHEART_PACT]                          = { level = 60, size = CONSTANTS.KEEP_RESOURCE_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_mine_Ebonheart.dds", hitInsetX = 5, hitInsetY = 6, minSize = CONSTANTS.KEEP_RESOURCE_MIN_SIZE},
        [MAP_PIN_TYPE_MINE_DAGGERFALL_COVENANT]                     = { level = 60, size = CONSTANTS.KEEP_RESOURCE_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_mine_Daggerfall.dds", hitInsetX = 5, hitInsetY = 6, minSize = CONSTANTS.KEEP_RESOURCE_MIN_SIZE},
        [MAP_PIN_TYPE_MILL_NEUTRAL]                                 = { level = 60, size = CONSTANTS.KEEP_RESOURCE_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_lumbermill_Neutral.dds", hitInsetX = 6, hitInsetY = 7, minSize = CONSTANTS.KEEP_RESOURCE_MIN_SIZE},
        [MAP_PIN_TYPE_MILL_ALDMERI_DOMINION]                        = { level = 60, size = CONSTANTS.KEEP_RESOURCE_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_lumbermill_Aldmeri.dds", hitInsetX = 6, hitInsetY = 7, minSize = CONSTANTS.KEEP_RESOURCE_MIN_SIZE},
        [MAP_PIN_TYPE_MILL_EBONHEART_PACT]                          = { level = 60, size = CONSTANTS.KEEP_RESOURCE_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_lumbermill_Ebonheart.dds", hitInsetX = 6, hitInsetY = 7, minSize = CONSTANTS.KEEP_RESOURCE_MIN_SIZE},
        [MAP_PIN_TYPE_MILL_DAGGERFALL_COVENANT]                     = { level = 60, size = CONSTANTS.KEEP_RESOURCE_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_lumbermill_Daggerfall.dds", hitInsetX = 6, hitInsetY = 7, minSize = CONSTANTS.KEEP_RESOURCE_MIN_SIZE},
        [MAP_PIN_TYPE_KEEP_NEUTRAL]                                 = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_largeKeep_neutral.dds", hitInsetX = 20, hitInsetY = 16},
        [MAP_PIN_TYPE_KEEP_ALDMERI_DOMINION]                        = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_largeKeep_Aldmeri.dds", hitInsetX = 20, hitInsetY = 16},
        [MAP_PIN_TYPE_KEEP_EBONHEART_PACT]                          = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_largeKeep_Ebonheart.dds", hitInsetX = 20, hitInsetY = 16},
        [MAP_PIN_TYPE_KEEP_DAGGERFALL_COVENANT]                     = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_largeKeep_Daggerfall.dds", hitInsetX = 20, hitInsetY = 16},
        [MAP_PIN_TYPE_IMPERIAL_DISTRICT_NEUTRAL]                    = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_imperialDistrict_Neutral.dds", hitInsetX = 17, hitInsetY = 17},
        [MAP_PIN_TYPE_IMPERIAL_DISTRICT_ALDMERI_DOMINION]           = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_imperialDistrict_Aldmeri.dds", hitInsetX = 17, hitInsetY = 17},
        [MAP_PIN_TYPE_IMPERIAL_DISTRICT_EBONHEART_PACT]             = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_imperialDistrict_Ebonheart.dds", hitInsetX = 17, hitInsetY = 17},
        [MAP_PIN_TYPE_IMPERIAL_DISTRICT_DAGGERFALL_COVENANT]        = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_imperialDistrict_Daggerfall.dds", hitInsetX = 17, hitInsetY = 17},
        [MAP_PIN_TYPE_AVA_TOWN_NEUTRAL]                             = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_town_Neutral.dds", hitInsetX = 17, hitInsetY = 17},
        [MAP_PIN_TYPE_AVA_TOWN_ALDMERI_DOMINION]                    = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_town_Aldmeri.dds", hitInsetX = 17, hitInsetY = 17},
        [MAP_PIN_TYPE_AVA_TOWN_EBONHEART_PACT]                      = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_town_Ebonheart.dds", hitInsetX = 17, hitInsetY = 17},
        [MAP_PIN_TYPE_AVA_TOWN_DAGGERFALL_COVENANT]                 = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_town_Daggerfall.dds", hitInsetX = 17, hitInsetY = 17},
        [MAP_PIN_TYPE_OUTPOST_NEUTRAL]                              = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_outpost_neutral.dds", hitInsetX = 20, hitInsetY = 17},
        [MAP_PIN_TYPE_OUTPOST_ALDMERI_DOMINION]                     = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_outpost_aldmeri.dds", hitInsetX = 20, hitInsetY = 17},
        [MAP_PIN_TYPE_OUTPOST_EBONHEART_PACT]                       = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_outpost_ebonheart.dds", hitInsetX = 20, hitInsetY = 17},
        [MAP_PIN_TYPE_OUTPOST_DAGGERFALL_COVENANT]                  = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_outpost_daggerfall.dds", hitInsetX = 20, hitInsetY = 17},
        [MAP_PIN_TYPE_BORDER_KEEP_ALDMERI_DOMINION]                 = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_borderKeep_pin_aldmeri.dds", hitInsetX = 16, hitInsetY = 16},
        [MAP_PIN_TYPE_BORDER_KEEP_EBONHEART_PACT]                   = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_borderKeep_pin_ebonheart.dds", hitInsetX = 16, hitInsetY = 16},
        [MAP_PIN_TYPE_BORDER_KEEP_DAGGERFALL_COVENANT]              = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_borderKeep_pin_daggerfall.dds", hitInsetX = 16, hitInsetY = 16},
        [MAP_PIN_TYPE_ARTIFACT_KEEP_ALDMERI_DOMINION]               = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifactTemple_Aldmeri.dds", hitInsetX = 17, hitInsetY = 17},
        [MAP_PIN_TYPE_ARTIFACT_KEEP_EBONHEART_PACT]                 = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifactTemple_Ebonheart.dds", hitInsetX = 17, hitInsetY = 17},
        [MAP_PIN_TYPE_ARTIFACT_KEEP_DAGGERFALL_COVENANT]            = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifactTemple_Daggerfall.dds", hitInsetX = 17, hitInsetY = 17},
        [MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_ALDMERI_DOMINION]          = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifactGate_aldmeri_open.dds", hitInsetX = 14, hitInsetY = 14},
        [MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_DAGGERFALL_COVENANT]       = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifactGate_daggerfall_open.dds", hitInsetX = 14, hitInsetY = 14},
        [MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_EBONHEART_PACT]            = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifactGate_ebonheart_open.dds", hitInsetX = 14, hitInsetY = 14},
        [MAP_PIN_TYPE_ARTIFACT_GATE_CLOSED_ALDMERI_DOMINION]        = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifactGate_aldmeri_closed.dds", hitInsetX = 14, hitInsetY = 14},
        [MAP_PIN_TYPE_ARTIFACT_GATE_CLOSED_DAGGERFALL_COVENANT]     = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifactGate_daggerfall_closed.dds", hitInsetX = 14, hitInsetY = 14},
        [MAP_PIN_TYPE_ARTIFACT_GATE_CLOSED_EBONHEART_PACT]          = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_artifactGate_ebonheart_closed.dds", hitInsetX = 14, hitInsetY = 14},
        [MAP_PIN_TYPE_POI_SUGGESTED]                                = { level = 46, size = CONSTANTS.POI_PIN_SIZE, texture = GetPOIPinTexture, tint = GetPOIPinTint, hitInsetX = 5, hitInsetY = 10, showsPinAndArea = true},
        [MAP_PIN_TYPE_POI_SEEN]                                     = { level = 46, size = CONSTANTS.POI_PIN_SIZE, texture = GetPOIPinTexture, tint = GetPOIPinTint, hitInsetX = 5, hitInsetY = 10},
        [MAP_PIN_TYPE_POI_COMPLETE]                                 = { level = 45, size = CONSTANTS.POI_PIN_SIZE, texture = GetPOIPinTexture, tint = GetPOIPinTint, hitInsetX = 5, hitInsetY = 10},
        [MAP_PIN_TYPE_LOCATION]                                     = { level = 45, size = CONSTANTS.MAP_LOCATION_PIN_SIZE, texture = GetLocationPinTexture},
        [MAP_PIN_TYPE_WORLD_EVENT_POI_ACTIVE]                       = { level = 44, size = CONSTANTS.POI_PIN_SIZE, texture = GetWorldEventPOIPinTexture, isAnimated = true, framesWide = 16, framesHigh = 1, framesPerSecond = 12 },
        [MAP_PIN_TYPE_SKYSHARD_SUGGESTED]                           = { level = 43, size = CONSTANTS.POI_PIN_SIZE, texture = "EsoUI/Art/MapPins/skyshard_seen.dds", insetX = 5, insetY = 3, showsPinAndArea = true},
        [MAP_PIN_TYPE_SKYSHARD_SEEN]                                = { level = 43, size = CONSTANTS.POI_PIN_SIZE, texture = "EsoUI/Art/MapPins/skyshard_seen.dds", insetX = 5, insetY = 3},
        [MAP_PIN_TYPE_SKYSHARD_COMPLETE]                            = { level = 42, size = CONSTANTS.POI_PIN_SIZE, texture = "EsoUI/Art/MapPins/skyshard_complete.dds", insetX = 5, insetY = 3},
        [MAP_PIN_TYPE_FORWARD_CAMP_ACCESSIBLE]                      = { level = 40, size = CONSTANTS.KEEP_PIN_ACCESSIBLE_SIZE, texture = "EsoUI/Art/MapPins/AvA_cemetary_linked_backdrop.dds"},
        [MAP_PIN_TYPE_KEEP_GRAVEYARD_ACCESSIBLE]                    = { level = 40, size = CONSTANTS.KEEP_PIN_ACCESSIBLE_SIZE, texture = "EsoUI/Art/MapPins/AvA_keep_linked_backdrop.dds"},
        [MAP_PIN_TYPE_IMPERIAL_DISTRICT_GRAVEYARD_ACCESSIBLE]       = { level = 40, size = CONSTANTS.KEEP_PIN_ACCESSIBLE_SIZE, texture = "EsoUI/Art/MapPins/AvA_imperialDistrict_glow.dds"},
        [MAP_PIN_TYPE_AVA_TOWN_GRAVEYARD_ACCESSIBLE]                = { level = 40, size = CONSTANTS.KEEP_PIN_ACCESSIBLE_SIZE, texture = "EsoUI/Art/MapPins/AvA_town_glow.dds"},
        [MAP_PIN_TYPE_FAST_TRAVEL_KEEP_ACCESSIBLE]                  = { level = 40, size = CONSTANTS.KEEP_PIN_ACCESSIBLE_SIZE, texture = "EsoUI/Art/MapPins/AvA_keep_linked_backdrop.dds"},
        [MAP_PIN_TYPE_FAST_TRAVEL_BORDER_KEEP_ACCESSIBLE]           = { level = 40, size = CONSTANTS.KEEP_PIN_ACCESSIBLE_SIZE, texture = "EsoUI/Art/MapPins/AvA_borderKeep_linked_backdrop.dds"},
        [MAP_PIN_TYPE_RESPAWN_BORDER_KEEP_ACCESSIBLE]               = { level = 40, size = CONSTANTS.KEEP_PIN_ACCESSIBLE_SIZE, texture = "EsoUI/Art/MapPins/AvA_borderKeep_linked_backdrop.dds"},
        [MAP_PIN_TYPE_FAST_TRAVEL_OUTPOST_ACCESSIBLE]               = { level = 40, size = CONSTANTS.KEEP_PIN_ACCESSIBLE_SIZE, texture = "EsoUI/Art/MapPins/AvA_outpost_linked_backdrop.dds"},
        [MAP_PIN_TYPE_OUTPOST_GRAVEYARD_ACCESSIBLE]                 = { level = 40, size = CONSTANTS.KEEP_PIN_ACCESSIBLE_SIZE, texture = "EsoUI/Art/MapPins/AvA_outpost_linked_backdrop.dds"},
        [MAP_PIN_TYPE_KEEP_ATTACKED_LARGE]                          = { level = 30, size = CONSTANTS.KEEP_PIN_ATTACKED_SIZE, texture = "EsoUI/Art/MapPins/AvA_attackBurst_64.dds"},
        [MAP_PIN_TYPE_KEEP_ATTACKED_SMALL]                          = { level = 30, size = CONSTANTS.KEEP_RESOURCE_PIN_ATTACKED_SIZE, texture = "EsoUI/Art/MapPins/AvA_attackBurst_32.dds"},
        [MAP_PIN_TYPE_RESTRICTED_LINK_ALDMERI_DOMINION]             = { level = 20, size = CONSTANTS.RESTRICTED_LINK_PIN_SIZE, texture = "EsoUI/Art/AvA/AvA_transitLocked.dds", tint = GetAllianceColor(ALLIANCE_ALDMERI_DOMINION)},
        [MAP_PIN_TYPE_RESTRICTED_LINK_EBONHEART_PACT]               = { level = 20, size = CONSTANTS.RESTRICTED_LINK_PIN_SIZE, texture = "EsoUI/Art/AvA/AvA_transitLocked.dds", tint = GetAllianceColor(ALLIANCE_EBONHEART_PACT)},
        [MAP_PIN_TYPE_RESTRICTED_LINK_DAGGERFALL_COVENANT]          = { level = 20, size = CONSTANTS.RESTRICTED_LINK_PIN_SIZE, texture = "EsoUI/Art/AvA/AvA_transitLocked.dds", tint = GetAllianceColor(ALLIANCE_DAGGERFALL_COVENANT)},
        [MAP_PIN_TYPE_KEEP_BRIDGE]                                  = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_bridge_passable.dds", hitInsetX = 20, hitInsetY = 16},
        [MAP_PIN_TYPE_KEEP_BRIDGE_IMPASSABLE]                       = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_bridge_not_passable.dds", hitInsetX = 20, hitInsetY = 16},
        [MAP_PIN_TYPE_KEEP_MILEGATE]                                = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_milegate_passable.dds", hitInsetX = 20, hitInsetY = 16},
        [MAP_PIN_TYPE_KEEP_MILEGATE_CENTER_DESTROYED]               = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_milegate_center_destroyed.dds", hitInsetX = 20, hitInsetY = 16},
        [MAP_PIN_TYPE_KEEP_MILEGATE_IMPASSABLE]                     = { level = 50, size = CONSTANTS.KEEP_PIN_SIZE, texture = "EsoUI/Art/MapPins/AvA_milegate_not_passable.dds", hitInsetX = 20, hitInsetY = 16},
        [MAP_PIN_TYPE_AUTO_MAP_NAVIGATION_PING]                     = { level = 10, minSize = 100, texture = "EsoUI/Art/MapPins/MapAutoNavigationPing.dds", isAnimated = true, framesWide = 32, framesHigh = 1, framesPerSecond = 32 },
        [MAP_PIN_TYPE_QUEST_PING]                                   = { level = 10, minSize = 100, texture = "EsoUI/Art/MapPins/QuestPing.dds", isAnimated = true, framesWide = 32, framesHigh = 1, framesPerSecond = 32 },
        [MAP_PIN_TYPE_ANTIQUITY_DIG_SITE_PING]                      = { level = 10, minSize = 100, texture = "EsoUI/Art/MapPins/MapAutoNavigationPing.dds", isAnimated = true, framesWide = 32, framesHigh = 1, framesPerSecond = 32 },
        --[[ Pins should start with a level greater than 2 ]]--
    }
end

ZO_MapPin.UNIT_PIN_TYPES =
{
    [MAP_PIN_TYPE_PLAYER] = true,
    [MAP_PIN_TYPE_GROUP] = true,
    [MAP_PIN_TYPE_GROUP_LEADER] = true,
    [MAP_PIN_TYPE_ACTIVE_COMPANION] = true,
}

ZO_MapPin.GROUP_PIN_TYPES =
{
    [MAP_PIN_TYPE_GROUP] = true,
    [MAP_PIN_TYPE_GROUP_LEADER] = true,
}

ZO_MapPin.POI_PIN_TYPES =
{
    [MAP_PIN_TYPE_POI_SEEN] = true,
    [MAP_PIN_TYPE_POI_COMPLETE] = true,
}

ZO_MapPin.SKYSHARD_PIN_TYPES =
{
    [MAP_PIN_TYPE_SKYSHARD_SEEN] = true,
    [MAP_PIN_TYPE_SKYSHARD_COMPLETE] = true,
}

ZO_MapPin.QUEST_PIN_TYPES =
{
    [MAP_PIN_TYPE_TRACKED_QUEST_CONDITION] = true,
    [MAP_PIN_TYPE_TRACKED_QUEST_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_TRACKED_QUEST_ENDING] = true,
    [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_CONDITION] = true,
    [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_ENDING] = true,
    [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_CONDITION] = true,
    [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_ENDING] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_ENDING] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_ENDING] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_ENDING] = true,
    [MAP_PIN_TYPE_QUEST_CONDITION] = true,
    [MAP_PIN_TYPE_QUEST_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_QUEST_ENDING] = true,
    [MAP_PIN_TYPE_QUEST_REPEATABLE_CONDITION] = true,
    [MAP_PIN_TYPE_QUEST_REPEATABLE_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_QUEST_REPEATABLE_ENDING] = true,
    [MAP_PIN_TYPE_QUEST_ZONE_STORY_CONDITION] = true,
    [MAP_PIN_TYPE_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_QUEST_ZONE_STORY_ENDING] = true,
}

ZO_MapPin.QUEST_CONDITION_PIN_TYPES =
{
    [MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_TRACKED_QUEST_CONDITION] = true,
    [MAP_PIN_TYPE_TRACKED_QUEST_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_CONDITION] = true,
    [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_CONDITION] = true,
    [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_QUEST_CONDITION] = true,
    [MAP_PIN_TYPE_QUEST_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_QUEST_REPEATABLE_CONDITION] = true,
    [MAP_PIN_TYPE_QUEST_REPEATABLE_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_QUEST_ZONE_STORY_CONDITION] = true,
    [MAP_PIN_TYPE_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = true,
}

ZO_MapPin.ASSISTED_PIN_TYPES =
{
    [MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_ENDING] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_ENDING] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = true,
    [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_ENDING] = true,
}

ZO_MapPin.OBJECTIVE_PIN_TYPES =
{
    [MAP_PIN_TYPE_ARTIFACT_ALDMERI_OFFENSIVE] = true,
    [MAP_PIN_TYPE_ARTIFACT_ALDMERI_DEFENSIVE] = true,
    [MAP_PIN_TYPE_ARTIFACT_EBONHEART_OFFENSIVE] = true,
    [MAP_PIN_TYPE_ARTIFACT_EBONHEART_DEFENSIVE] = true,
    [MAP_PIN_TYPE_ARTIFACT_DAGGERFALL_OFFENSIVE] = true,
    [MAP_PIN_TYPE_ARTIFACT_DAGGERFALL_DEFENSIVE] = true,
    [MAP_PIN_TYPE_ARTIFACT_RETURN_ALDMERI] = true,
    [MAP_PIN_TYPE_ARTIFACT_RETURN_EBONHEART] = true,
    [MAP_PIN_TYPE_ARTIFACT_RETURN_DAGGERFALL] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_FIRE_DRAKES] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_PIT_DAEMONS] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_STORM_LORDS] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_NEUTRAL] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_FIRE_DRAKES] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_PIT_DAEMONS] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_STORM_LORDS] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_NEUTRAL] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_FIRE_DRAKES] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_PIT_DAEMONS] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_STORM_LORDS] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_NEUTRAL] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_FIRE_DRAKES] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_PIT_DAEMONS] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_STORM_LORDS] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_NEUTRAL] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_FIRE_DRAKES] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_PIT_DAEMONS] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_STORM_LORDS] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_NEUTRAL] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_FIRE_DRAKES] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_PIT_DAEMONS] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_STORM_LORDS] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_NEUTRAL] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_A_FIRE_DRAKES] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_A_PIT_DAEMONS] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_A_STORM_LORDS] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_A_NEUTRAL] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_B_FIRE_DRAKES] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_B_PIT_DAEMONS] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_B_STORM_LORDS] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_B_NEUTRAL] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_C_FIRE_DRAKES] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_C_PIT_DAEMONS] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_C_STORM_LORDS] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_C_NEUTRAL] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_D_FIRE_DRAKES] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_D_PIT_DAEMONS] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_D_STORM_LORDS] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_D_NEUTRAL] = true,
    [MAP_PIN_TYPE_BGPIN_FLAG_FIRE_DRAKES] = true,
    [MAP_PIN_TYPE_BGPIN_FLAG_PIT_DAEMONS] = true,
    [MAP_PIN_TYPE_BGPIN_FLAG_STORM_LORDS] = true,
    [MAP_PIN_TYPE_BGPIN_FLAG_NEUTRAL] = true,
    [MAP_PIN_TYPE_BGPIN_MURDERBALL_NEUTRAL] = true,
    [MAP_PIN_TYPE_BGPIN_MURDERBALL_FIRE_DRAKES] = true,
    [MAP_PIN_TYPE_BGPIN_MURDERBALL_PIT_DAEMONS] = true,
    [MAP_PIN_TYPE_BGPIN_MURDERBALL_STORM_LORDS] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_AURA] = true,
    [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_AURA] = true,
    [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_AURA] = true,
    [MAP_PIN_TYPE_BGPIN_FLAG_NEUTRAL_AURA] = true,
    [MAP_PIN_TYPE_BGPIN_FLAG_FIRE_DRAKES_AURA] = true,
    [MAP_PIN_TYPE_BGPIN_FLAG_PIT_DAEMONS_AURA] = true,
    [MAP_PIN_TYPE_BGPIN_FLAG_STORM_LORDS_AURA] = true,
    [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_NEUTRAL] = true,
    [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_ALDMERI] = true,
    [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_EBONHEART] = true,
    [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_DAGGERFALL] = true,
}

ZO_MapPin.SPAWN_OBJECTIVE_PIN_TYPES =
{
    [MAP_PIN_TYPE_BGPIN_FLAG_SPAWN_FIRE_DRAKES] = true,
    [MAP_PIN_TYPE_BGPIN_FLAG_SPAWN_PIT_DAEMONS] = true,
    [MAP_PIN_TYPE_BGPIN_FLAG_SPAWN_STORM_LORDS] = true,
    [MAP_PIN_TYPE_BGPIN_FLAG_SPAWN_NEUTRAL] = true,
    [MAP_PIN_TYPE_BGPIN_MURDERBALL_SPAWN_NEUTRAL] = true,
}

ZO_MapPin.RETURN_OBJECTIVE_PIN_TYPES =
{
    [MAP_PIN_TYPE_BGPIN_FLAG_RETURN_FIRE_DRAKES] = true,
    [MAP_PIN_TYPE_BGPIN_FLAG_RETURN_PIT_DAEMONS] = true,
    [MAP_PIN_TYPE_BGPIN_FLAG_RETURN_STORM_LORDS] = true,
}

ZO_MapPin.KEEP_PIN_TYPES =
{
    [MAP_PIN_TYPE_KEEP_NEUTRAL] = true,
    [MAP_PIN_TYPE_KEEP_ALDMERI_DOMINION] = true,
    [MAP_PIN_TYPE_KEEP_EBONHEART_PACT] = true,
    [MAP_PIN_TYPE_KEEP_DAGGERFALL_COVENANT] = true,
    [MAP_PIN_TYPE_OUTPOST_NEUTRAL] = true,
    [MAP_PIN_TYPE_OUTPOST_ALDMERI_DOMINION] = true,
    [MAP_PIN_TYPE_OUTPOST_EBONHEART_PACT] = true,
    [MAP_PIN_TYPE_OUTPOST_DAGGERFALL_COVENANT] = true,
    [MAP_PIN_TYPE_BORDER_KEEP_ALDMERI_DOMINION] = true,
    [MAP_PIN_TYPE_BORDER_KEEP_EBONHEART_PACT] = true,
    [MAP_PIN_TYPE_BORDER_KEEP_DAGGERFALL_COVENANT] = true,
    [MAP_PIN_TYPE_FARM_NEUTRAL] = true,
    [MAP_PIN_TYPE_FARM_ALDMERI_DOMINION] = true,
    [MAP_PIN_TYPE_FARM_EBONHEART_PACT] = true,
    [MAP_PIN_TYPE_FARM_DAGGERFALL_COVENANT] = true,
    [MAP_PIN_TYPE_MINE_NEUTRAL] = true,
    [MAP_PIN_TYPE_MINE_ALDMERI_DOMINION] = true,
    [MAP_PIN_TYPE_MINE_EBONHEART_PACT] = true,
    [MAP_PIN_TYPE_MINE_DAGGERFALL_COVENANT] = true,
    [MAP_PIN_TYPE_MILL_NEUTRAL] = true,
    [MAP_PIN_TYPE_MILL_ALDMERI_DOMINION] = true,
    [MAP_PIN_TYPE_MILL_EBONHEART_PACT] = true,
    [MAP_PIN_TYPE_MILL_DAGGERFALL_COVENANT] = true,
    [MAP_PIN_TYPE_ARTIFACT_KEEP_ALDMERI_DOMINION] = true,
    [MAP_PIN_TYPE_ARTIFACT_KEEP_EBONHEART_PACT] = true,
    [MAP_PIN_TYPE_ARTIFACT_KEEP_DAGGERFALL_COVENANT] = true,
    [MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_ALDMERI_DOMINION] = true,
    [MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_DAGGERFALL_COVENANT] = true,
    [MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_EBONHEART_PACT] = true,
    [MAP_PIN_TYPE_ARTIFACT_GATE_CLOSED_ALDMERI_DOMINION] = true,
    [MAP_PIN_TYPE_ARTIFACT_GATE_CLOSED_DAGGERFALL_COVENANT]  = true,
    [MAP_PIN_TYPE_ARTIFACT_GATE_CLOSED_EBONHEART_PACT] = true,
    [MAP_PIN_TYPE_KEEP_ATTACKED_SMALL] = true,
    [MAP_PIN_TYPE_KEEP_ATTACKED_LARGE] = true,
    [MAP_PIN_TYPE_AVA_TOWN_NEUTRAL] = true,
    [MAP_PIN_TYPE_AVA_TOWN_ALDMERI_DOMINION] = true,
    [MAP_PIN_TYPE_AVA_TOWN_EBONHEART_PACT] = true,
    [MAP_PIN_TYPE_AVA_TOWN_DAGGERFALL_COVENANT] = true,
    [MAP_PIN_TYPE_KEEP_BRIDGE] = true,
    [MAP_PIN_TYPE_KEEP_BRIDGE_IMPASSABLE] = true,
    [MAP_PIN_TYPE_KEEP_MILEGATE] = true,
    [MAP_PIN_TYPE_KEEP_MILEGATE_CENTER_DESTROYED] = true,
    [MAP_PIN_TYPE_KEEP_MILEGATE_IMPASSABLE] = true,
}

ZO_MapPin.DISTRICT_PIN_TYPES =
{
    [MAP_PIN_TYPE_IMPERIAL_DISTRICT_NEUTRAL] = true,
    [MAP_PIN_TYPE_IMPERIAL_DISTRICT_ALDMERI_DOMINION] = true,
    [MAP_PIN_TYPE_IMPERIAL_DISTRICT_EBONHEART_PACT] = true,
    [MAP_PIN_TYPE_IMPERIAL_DISTRICT_DAGGERFALL_COVENANT] = true,
    [MAP_PIN_TYPE_KEEP_ATTACKED_SMALL] = true,
    [MAP_PIN_TYPE_KEEP_ATTACKED_LARGE] = true,
}

ZO_MapPin.MAP_PING_PIN_TYPES =
{
    [MAP_PIN_TYPE_PING] = true,
    [MAP_PIN_TYPE_RALLY_POINT] = true,
    [MAP_PIN_TYPE_PLAYER_WAYPOINT] = true,
    [MAP_PIN_TYPE_AUTO_MAP_NAVIGATION_PING] = true,
    [MAP_PIN_TYPE_QUEST_PING] = true,
    [MAP_PIN_TYPE_ANTIQUITY_DIG_SITE_PING] = true,
}

ZO_MapPin.KILL_LOCATION_PIN_TYPES =
{
    [MAP_PIN_TYPE_TRI_BATTLE_SMALL] = true,
    [MAP_PIN_TYPE_TRI_BATTLE_MEDIUM] = true,
    [MAP_PIN_TYPE_TRI_BATTLE_LARGE] = true,
    [MAP_PIN_TYPE_ALDMERI_VS_EBONHEART_SMALL] = true,
    [MAP_PIN_TYPE_ALDMERI_VS_EBONHEART_MEDIUM] = true,
    [MAP_PIN_TYPE_ALDMERI_VS_EBONHEART_LARGE] = true,
    [MAP_PIN_TYPE_ALDMERI_VS_DAGGERFALL_SMALL] = true,
    [MAP_PIN_TYPE_ALDMERI_VS_DAGGERFALL_MEDIUM] = true,
    [MAP_PIN_TYPE_ALDMERI_VS_DAGGERFALL_LARGE] = true,
    [MAP_PIN_TYPE_EBONHEART_VS_DAGGERFALL_SMALL] = true,
    [MAP_PIN_TYPE_EBONHEART_VS_DAGGERFALL_MEDIUM] = true,
    [MAP_PIN_TYPE_EBONHEART_VS_DAGGERFALL_LARGE] = true,
}

ZO_MapPin.FAST_TRAVEL_KEEP_PIN_TYPES =
{
    [MAP_PIN_TYPE_FAST_TRAVEL_KEEP_ACCESSIBLE] = true,
    [MAP_PIN_TYPE_FAST_TRAVEL_BORDER_KEEP_ACCESSIBLE] = true,
    [MAP_PIN_TYPE_FAST_TRAVEL_OUTPOST_ACCESSIBLE] = true,
}

ZO_MapPin.FAST_TRAVEL_WAYSHRINE_PIN_TYPES =
{
    [MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE] = true,
    [MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE_CURRENT_LOC] = true,
}

ZO_MapPin.FORWARD_CAMP_PIN_TYPES =
{
    [MAP_PIN_TYPE_FORWARD_CAMP_ALDMERI_DOMINION] = true,
    [MAP_PIN_TYPE_FORWARD_CAMP_EBONHEART_PACT] = true,
    [MAP_PIN_TYPE_FORWARD_CAMP_DAGGERFALL_COVENANT] = true,
}

ZO_MapPin.AVA_RESPAWN_PIN_TYPES =
{
    [MAP_PIN_TYPE_FORWARD_CAMP_ACCESSIBLE] = true,
    [MAP_PIN_TYPE_KEEP_GRAVEYARD_ACCESSIBLE] = true,
    [MAP_PIN_TYPE_IMPERIAL_DISTRICT_GRAVEYARD_ACCESSIBLE] = true,
    [MAP_PIN_TYPE_AVA_TOWN_GRAVEYARD_ACCESSIBLE] = true,
    [MAP_PIN_TYPE_OUTPOST_GRAVEYARD_ACCESSIBLE] = true,
    [MAP_PIN_TYPE_RESPAWN_BORDER_KEEP_ACCESSIBLE] = true,
}

ZO_MapPin.AVA_RESTRICTED_LINK_PIN_TYPES =
{
    [MAP_PIN_TYPE_RESTRICTED_LINK_ALDMERI_DOMINION] = true,
    [MAP_PIN_TYPE_RESTRICTED_LINK_EBONHEART_PACT] = true,
    [MAP_PIN_TYPE_RESTRICTED_LINK_DAGGERFALL_COVENANT] = true,
}

ZO_MapPin.WORLD_EVENT_UNIT_PIN_TYPES =
{
    [MAP_PIN_TYPE_UNIT_COMBAT_HEALTHY] = true,
    [MAP_PIN_TYPE_UNIT_COMBAT_WEAK] = true,
    [MAP_PIN_TYPE_UNIT_IDLE_HEALTHY] = true,
    [MAP_PIN_TYPE_UNIT_IDLE_WEAK] = true,
}

ZO_MapPin.WORLD_EVENT_POI_PIN_TYPES =
{
    [MAP_PIN_TYPE_WORLD_EVENT_POI_ACTIVE] = true,
}

ZO_MapPin.SUGGESTION_PIN_TYPES =
{
    [MAP_PIN_TYPE_TRACKED_QUEST_OFFER_ZONE_STORY] = true,
    [MAP_PIN_TYPE_POI_SUGGESTED] = true,
    [MAP_PIN_TYPE_SKYSHARD_SUGGESTED] = true,
}

ZO_MapPin.PIN_TYPE_TO_PIN_GROUP =
{
    [MAP_PIN_TYPE_GROUP_LEADER] = MAP_FILTER_GROUP_MEMBERS,
    [MAP_PIN_TYPE_GROUP] = MAP_FILTER_GROUP_MEMBERS,

    [MAP_PIN_TYPE_TRACKED_QUEST_OFFER_ZONE_STORY] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_ASSISTED_QUEST_ENDING] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_ENDING] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_CONDITION] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_ENDING] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_TRACKED_QUEST_CONDITION] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_TRACKED_QUEST_OPTIONAL_CONDITION] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_TRACKED_QUEST_ENDING] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_CONDITION] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_ENDING] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_CONDITION] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = MAP_FILTER_QUESTS,
    [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_ENDING] = MAP_FILTER_QUESTS,

    -- Although there are now 4 MapFilters for fast travel, what we call a "pin group" can suffice with just using MAP_FILTER_WAYSHRINES for all of them
    -- Pin Group should have gotten its own enum, but it opted to just use MapFilter for convenience
    [MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE] = MAP_FILTER_WAYSHRINES,
    [MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE_CURRENT_LOC] = MAP_FILTER_WAYSHRINES,

    [MAP_PIN_TYPE_FORWARD_CAMP_ALDMERI_DOMINION] = MAP_FILTER_AVA_GRAVEYARDS,
    [MAP_PIN_TYPE_FORWARD_CAMP_EBONHEART_PACT] = MAP_FILTER_AVA_GRAVEYARDS,
    [MAP_PIN_TYPE_FORWARD_CAMP_DAGGERFALL_COVENANT] = MAP_FILTER_AVA_GRAVEYARDS,
    [MAP_PIN_TYPE_FORWARD_CAMP_ACCESSIBLE] = MAP_FILTER_AVA_GRAVEYARDS,

    [MAP_PIN_TYPE_ARTIFACT_ALDMERI_OFFENSIVE] = MAP_FILTER_AVA_OBJECTIVES,
    [MAP_PIN_TYPE_ARTIFACT_ALDMERI_DEFENSIVE] = MAP_FILTER_AVA_OBJECTIVES,
    [MAP_PIN_TYPE_ARTIFACT_EBONHEART_OFFENSIVE] = MAP_FILTER_AVA_OBJECTIVES,
    [MAP_PIN_TYPE_ARTIFACT_EBONHEART_DEFENSIVE] = MAP_FILTER_AVA_OBJECTIVES,
    [MAP_PIN_TYPE_ARTIFACT_DAGGERFALL_OFFENSIVE] = MAP_FILTER_AVA_OBJECTIVES,
    [MAP_PIN_TYPE_ARTIFACT_DAGGERFALL_DEFENSIVE] = MAP_FILTER_AVA_OBJECTIVES,
    [MAP_PIN_TYPE_ARTIFACT_RETURN_ALDMERI] = MAP_FILTER_AVA_OBJECTIVES,
    [MAP_PIN_TYPE_ARTIFACT_RETURN_EBONHEART] = MAP_FILTER_AVA_OBJECTIVES,
    [MAP_PIN_TYPE_ARTIFACT_RETURN_DAGGERFALL] = MAP_FILTER_AVA_OBJECTIVES,
    [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_NEUTRAL] = MAP_FILTER_AVA_OBJECTIVES,
    [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_ALDMERI] = MAP_FILTER_AVA_OBJECTIVES,
    [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_EBONHEART] = MAP_FILTER_AVA_OBJECTIVES,
    [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_DAGGERFALL] = MAP_FILTER_AVA_OBJECTIVES,

    [MAP_PIN_TYPE_TRI_BATTLE_SMALL] = MAP_FILTER_KILL_LOCATIONS,
    [MAP_PIN_TYPE_TRI_BATTLE_MEDIUM] = MAP_FILTER_KILL_LOCATIONS,
    [MAP_PIN_TYPE_TRI_BATTLE_LARGE] = MAP_FILTER_KILL_LOCATIONS,
    [MAP_PIN_TYPE_ALDMERI_VS_EBONHEART_SMALL] = MAP_FILTER_KILL_LOCATIONS,
    [MAP_PIN_TYPE_ALDMERI_VS_EBONHEART_MEDIUM] = MAP_FILTER_KILL_LOCATIONS,
    [MAP_PIN_TYPE_ALDMERI_VS_EBONHEART_LARGE] = MAP_FILTER_KILL_LOCATIONS,
    [MAP_PIN_TYPE_ALDMERI_VS_DAGGERFALL_SMALL] = MAP_FILTER_KILL_LOCATIONS,
    [MAP_PIN_TYPE_ALDMERI_VS_DAGGERFALL_MEDIUM] = MAP_FILTER_KILL_LOCATIONS,
    [MAP_PIN_TYPE_ALDMERI_VS_DAGGERFALL_LARGE] = MAP_FILTER_KILL_LOCATIONS,
    [MAP_PIN_TYPE_EBONHEART_VS_DAGGERFALL_SMALL] = MAP_FILTER_KILL_LOCATIONS,
    [MAP_PIN_TYPE_EBONHEART_VS_DAGGERFALL_MEDIUM] = MAP_FILTER_KILL_LOCATIONS,
    [MAP_PIN_TYPE_EBONHEART_VS_DAGGERFALL_LARGE] = MAP_FILTER_KILL_LOCATIONS,

    [MAP_PIN_TYPE_FARM_NEUTRAL] = MAP_FILTER_RESOURCE_KEEPS,
    [MAP_PIN_TYPE_FARM_ALDMERI_DOMINION] = MAP_FILTER_RESOURCE_KEEPS,
    [MAP_PIN_TYPE_FARM_EBONHEART_PACT] = MAP_FILTER_RESOURCE_KEEPS,
    [MAP_PIN_TYPE_FARM_DAGGERFALL_COVENANT] = MAP_FILTER_RESOURCE_KEEPS,
    [MAP_PIN_TYPE_MINE_NEUTRAL] = MAP_FILTER_RESOURCE_KEEPS,
    [MAP_PIN_TYPE_MINE_ALDMERI_DOMINION] = MAP_FILTER_RESOURCE_KEEPS,
    [MAP_PIN_TYPE_MINE_EBONHEART_PACT] = MAP_FILTER_RESOURCE_KEEPS,
    [MAP_PIN_TYPE_MINE_DAGGERFALL_COVENANT] = MAP_FILTER_RESOURCE_KEEPS,
    [MAP_PIN_TYPE_MILL_NEUTRAL] = MAP_FILTER_RESOURCE_KEEPS,
    [MAP_PIN_TYPE_MILL_ALDMERI_DOMINION] = MAP_FILTER_RESOURCE_KEEPS,
    [MAP_PIN_TYPE_MILL_EBONHEART_PACT] = MAP_FILTER_RESOURCE_KEEPS,
    [MAP_PIN_TYPE_MILL_DAGGERFALL_COVENANT] = MAP_FILTER_RESOURCE_KEEPS,
    [MAP_PIN_TYPE_KEEP_ATTACKED_SMALL] = MAP_FILTER_RESOURCE_KEEPS,

    [MAP_PIN_TYPE_POI_SUGGESTED] = MAP_FILTER_OBJECTIVES,
    [MAP_PIN_TYPE_POI_SEEN] = MAP_FILTER_OBJECTIVES,
    [MAP_PIN_TYPE_POI_COMPLETE] = MAP_FILTER_OBJECTIVES,

    [MAP_PIN_TYPE_SKYSHARD_SUGGESTED] = MAP_FILTER_OBJECTIVES,
    [MAP_PIN_TYPE_SKYSHARD_SEEN] = MAP_FILTER_OBJECTIVES,

    [MAP_PIN_TYPE_SKYSHARD_COMPLETE] = MAP_FILTER_ACQUIRED_SKYSHARDS,

    [MAP_PIN_TYPE_ANTIQUITY_DIG_SITE] = MAP_FILTER_DIG_SITES,
    [MAP_PIN_TYPE_TRACKED_ANTIQUITY_DIG_SITE] = MAP_FILTER_DIG_SITES,
}

ZO_MapPin.PIN_ORDERS =
{
    DESTINATIONS = 10,
    AVA_KEEP = 19,
    AVA_OUTPOST = 20,
    AVA_TOWN = 21,
    AVA_RESOURCE = 22,
    AVA_GATE = 23,
    AVA_KILL_LOCATION = 24,
    AVA_ARTIFACT = 25,
    AVA_IMPERIAL_CITY = 26,
    AVA_FORWARD_CAMP = 27,
    AVA_RESTRICTED_LINK = 28,
    CRAFTING = 30,
    SUGGESTIONS = 34,
    SKYSHARDS = 36,
    ANTIQUITIES = 38,
    QUESTS = 40,
    WORLD_EVENT_UNITS = 45,
    PLAYERS = 50,
}

ZO_MapPin.ANIM_CONSTANTS =
{
    RESET_ANIM_ALLOW_PLAY = 1,
    RESET_ANIM_PREVENT_PLAY = 2,
    RESET_ANIM_HIDE_CONTROL = 3,
    DEFAULT_LOOP_COUNT = 6, -- each reversal of the ping pong is a loop, 3 pulses is a loop count of 6.
    LONG_LOOP_COUNT = 24,
}

do
    --Pin Tooltips
    -----------------
    local function IsDelveOrPublicDungeon(pin)
        return pin:IsDelvePin() or pin:IsPublicDungeonPin()
    end

    local function AppendPOIInfo(pin)
        -- Currently, delves and public dungeons are the only POIs which use this tooltip flow
        if IsDelveOrPublicDungeon(pin) then
            ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendDelveInfo(pin)
        end
    end

    local function IsKillLocation(pin)
        return pin:IsKillLocation()
    end

    local function AppendKillLocationInfo(pin)
        if IsKillLocation(pin) then
            ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendKillLocationInfo(pin)
        end
    end

    local function GetWayshrineNameFromPin(pin)
        local nodeIndex = pin:GetFastTravelNodeIndex()
        local known, name = GetFastTravelNodeInfo(nodeIndex)
        return name
    end

    local function SetWayshrineMessage(pinType, pin)
        local nodeIndex = pin:GetFastTravelNodeIndex()
        local zoneIndex, poiIndex = GetFastTravelNodePOIIndicies(nodeIndex)

        local known, name = GetFastTravelNodeInfo(nodeIndex)
        ZO_WorldMapMouseoverName.owner = "fastTravelWayshrine"
        ZO_WorldMapMouseoverName:SetText(zo_strformat(SI_WORLD_MAP_LOCATION_NAME, name))

        local poiStartDesc, poiFinishedDesc = select(3, GetPOIInfo(zoneIndex, poiIndex))

        if HasCompletedFastTravelNodePOI(nodeIndex) then
            ZO_WorldMapMouseOverDescription:SetText(poiFinishedDesc)
        else
            ZO_WorldMapMouseOverDescription:SetText(poiStartDesc)
        end

        ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendWayshrineTooltip(pin)
    end

    local function LayoutMapLocation(pin)
        local locationIndex = pin:GetLocationIndex()
        ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.MAP_LOCATION):SetMapLocation(locationIndex)
    end

    local function HasMapLocationTooltip(pin)
        local locationIndex = pin:GetLocationIndex()
        return ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.MAP_LOCATION):HasMapLocationTooltip(locationIndex)
    end

    local function AppendObjectiveTooltip(pin)
        local objectivePinTier = OBJECTIVE_PIN_TIER_PRIMARY
        if ZO_MapPin.SPAWN_OBJECTIVE_PIN_TYPES[pin:GetPinType()] then
            objectivePinTier = OBJECTIVE_PIN_TIER_SPAWN
        elseif ZO_MapPin.RETURN_OBJECTIVE_PIN_TYPES[pin:GetPinType()] then
            objectivePinTier = OBJECTIVE_PIN_TIER_RETURN
        end

        ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendAvAObjective(pin:GetBattlegroundContext(), pin:GetObjectiveKeepId(), pin:GetObjectiveObjectiveId(), objectivePinTier)
    end

    local function AppendRestrictedLinkTooltip(pin)
        local mapLocationTooltip = ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.MAP_LOCATION)
        local alliance = pin:GetRestrictedAlliance()
        local allianceName = GetAllianceName(alliance)
        if not IsInGamepadPreferredMode() then
            mapLocationTooltip:AddLine(zo_strformat(SI_TOOLTIP_ALLIANCE_RESTRICTED_LINK, allianceName), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())
        else
            local allianceIcon = ZO_GetPlatformAllianceSymbolIcon(alliance)
            local allianceColorFormat = {
                fontColorType = INTERFACE_COLOR_TYPE_ALLIANCE,
                fontColorField = alliance,
            }
            mapLocationTooltip:LayoutIconStringLine(mapLocationTooltip.tooltip, allianceIcon, zo_strformat(SI_GAMEPAD_WORLD_MAP_TOOLTIP_ALLIANCE_RESTRICTED_LINK, allianceName), allianceColorFormat, mapLocationTooltip.tooltip:GetStyle("keepBaseTooltipContent"))
        end
    end

    local function LayoutKeepTooltip(pin)
        ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.KEEP):SetKeep(pin:GetKeepId(), pin:GetBattlegroundContext(), ZO_WorldMap_GetHistoryPercentToUse())
    end

    local function LayoutForwardCampTooltip(pin)
        ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.KEEP):SetForwardCamp(pin:GetForwardCampIndex(), ZO_WorldMap_GetBattlegroundQueryType(), pin:IsForwardCampUsable())
    end

    local function GetColoredQuestNameFromPin(pin)
        local questIndex = pin:GetQuestData()

        local questLevel = GetJournalQuestLevel(questIndex)
        local questColor = GetColorDefForCon(GetCon(questLevel))

        local questName = GetJournalQuestName(questIndex)

        return questColor:Colorize(questName)
    end

    local function GetQuestEndingFromPin(pin)
        local questIndex = pin:GetQuestData()
        return GetJournalQuestEnding(questIndex)
    end

    local function GetQuestConditionFromPin(pin)
        local questIndex, stepIndex, conditionIndex = pin:GetQuestData()
        return GetJournalQuestConditionInfo(questIndex, stepIndex, conditionIndex)
    end

    local function GetUnitNameFromPin(pin)
        return GetUnitName(pin:GetUnitTag())
    end

    local function GetQuestCategoryIcon(pin)
        local questIndex = pin:GetQuestData()
        if GetTrackedIsAssisted(TRACK_TYPE_QUEST, questIndex) then
            return "EsoUI/Art/Journal/Gamepad/gp_trackedQuestIcon.dds"
        else
            return nil
        end
    end

    local SHARED_TOOLTIP_CREATORS =
    {
        POI =
        {
            creator = AppendPOIInfo,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            hasTooltip = IsDelveOrPublicDungeon,
            categoryId = ZO_MapPin.PIN_ORDERS.DESTINATIONS,
            gamepadSpacing = true,
        },
        PLAYER_PIN =
        {
            creator = function(pin)
                ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendUnitName(pin:GetUnitTag())
            end,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            categoryId = ZO_MapPin.PIN_ORDERS.PLAYERS,
            entryName = GetUnitNameFromPin,
        },
        COMPANION_PIN =
        {
            creator = function(pin)
                ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendUnitName(pin:GetUnitTag())
            end,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            categoryId = ZO_MapPin.PIN_ORDERS.PLAYERS,
            entryName = GetUnitNameFromPin,
        },
        QUEST_CONDITION =
        {
            creator = function(pin)
                ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendQuestCondition(pin:GetQuestData())
            end,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            gamepadCategory = GetColoredQuestNameFromPin,
            categoryId = ZO_MapPin.PIN_ORDERS.QUESTS,
            gamepadCategoryIcon = GetQuestCategoryIcon,
            entryName = GetQuestConditionFromPin,
            gamepadCategoryStyleName = "mapQuestTitle",
        },
        QUEST_ENDING =
        {
            creator = function(pin)
                ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendQuestEnding(pin:GetQuestIndex())
            end,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            gamepadCategory = GetColoredQuestNameFromPin,
            categoryId = ZO_MapPin.PIN_ORDERS.QUESTS,
            gamepadCategoryIcon = GetQuestCategoryIcon,
            entryName = GetQuestEndingFromPin,
            gamepadCategoryStyleName = "mapQuestTitle",
        },
        WAYSHRINE =
        {
            creator = function(pin)
                SetWayshrineMessage(MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE, pin)
            end,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            categoryId = ZO_MapPin.PIN_ORDERS.DESTINATIONS,
            gamepadSpacing = true,
            entryName = GetWayshrineNameFromPin,
        },
        KEEP =
        {
            creator = LayoutKeepTooltip,
            tooltip = ZO_MAP_TOOLTIP_MODE.KEEP,
            categoryId = ZO_MapPin.PIN_ORDERS.AVA_KEEP,
            gamepadSpacing = true,
        },
        OUTPOST =
        {
            creator = LayoutKeepTooltip,
            tooltip = ZO_MAP_TOOLTIP_MODE.KEEP,
            categoryId = ZO_MapPin.PIN_ORDERS.AVA_OUTPOST,
            gamepadSpacing = true,
        },
        RESOURCE =
        {
            creator = LayoutKeepTooltip,
            tooltip = ZO_MAP_TOOLTIP_MODE.KEEP,
            categoryId = ZO_MapPin.PIN_ORDERS.AVA_RESOURCE,
            gamepadSpacing = true,
        },
        TOWN =
        {
            creator = LayoutKeepTooltip,
            tooltip = ZO_MAP_TOOLTIP_MODE.KEEP,
            categoryId = ZO_MapPin.PIN_ORDERS.AVA_TOWN,
            gamepadSpacing = true,
        },
        GATE =
        {
            creator = LayoutKeepTooltip,
            tooltip = ZO_MAP_TOOLTIP_MODE.KEEP,
            categoryId = ZO_MapPin.PIN_ORDERS.AVA_GATE,
            gamepadSpacing = true,
        },
        DISTRICT =
        {
            creator = LayoutKeepTooltip,
            tooltip = ZO_MAP_TOOLTIP_MODE.KEEP,
            categoryId = ZO_MapPin.PIN_ORDERS.AVA_IMPERIAL_CITY,
            gamepadSpacing = true,
        },
        ARTIFACT =
        {
            creator = AppendObjectiveTooltip,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            gamepadCategory = SI_GAMEPAD_WORLD_MAP_TOOLTIP_CATEGORY_ARTIFACT,
            categoryId = ZO_MapPin.PIN_ORDERS.AVA_ARTIFACT,
        },
        FORWARD_CAMP =
        {
            creator = LayoutForwardCampTooltip,
            tooltip = ZO_MAP_TOOLTIP_MODE.KEEP,
            gamepadCategory = SI_TOOLTIP_FORWARD_CAMP,
            categoryId = ZO_MapPin.PIN_ORDERS.AVA_FORWARD_CAMP,
        },
        RESTRICTED_LINK =
        {
            creator = AppendRestrictedLinkTooltip,
            tooltip = ZO_MAP_TOOLTIP_MODE.MAP_LOCATION,
            categoryId = ZO_MapPin.PIN_ORDERS.AVA_RESTRICTED_LINK,
            gamepadSpacing = true,
        },
        BG_OBJECTIVE =
        {
            creator = AppendObjectiveTooltip,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
        },
        SUGGESTION_ACTIVITY =
        {
            creator = function(pin)
                ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendSuggestionActivity(pin)
            end,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            gamepadCategory = SI_ZONE_STORY_INFO_HEADER,
            categoryId = ZO_MapPin.PIN_ORDERS.SUGGESTIONS,
            gamepadSpacing = true,
        },
        WORLD_EVENT_UNIT =
        {
            creator = function(pin)
                ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendUnitName(pin:GetUnitTag())
            end,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            categoryId = ZO_MapPin.PIN_ORDERS.WORLD_EVENT_UNITS,
            entryName = GetUnitNameFromPin,
        },
        DAEDRIC_ARTIFACT =
        {
            creator = AppendObjectiveTooltip,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
        },
        LOCATION =
        {
            creator = LayoutMapLocation,
            hasTooltip = HasMapLocationTooltip,
            tooltip = ZO_MAP_TOOLTIP_MODE.MAP_LOCATION,
            categoryId = ZO_MapPin.PIN_ORDERS.CRAFTING,
            gamepadSpacing = true,
        },
        PING =
        {
            creator = function(pin)
                ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendMapPing(MAP_PIN_TYPE_PING, pin:GetUnitTag())
            end,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            gamepadCategory = SI_GAMEPAD_WORLD_MAP_TOOLTIP_CATEGORY_DESTINATION,
            categoryId = ZO_MapPin.PIN_ORDERS.DESTINATIONS,
            gamepadSpacing = true,
        },
        RALLY_POINT =
        {
            creator = function(pin)
                ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendMapPing(MAP_PIN_TYPE_RALLY_POINT)
            end,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            gamepadCategory = SI_GAMEPAD_WORLD_MAP_TOOLTIP_CATEGORY_DESTINATION,
            categoryId = ZO_MapPin.PIN_ORDERS.DESTINATIONS,
            gamepadSpacing = true
        },
        PLAYER_WAYPOINT =
        {
            creator = function(pin)
                ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendMapPing(MAP_PIN_TYPE_PLAYER_WAYPOINT)
            end,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            gamepadCategory = SI_GAMEPAD_WORLD_MAP_TOOLTIP_CATEGORY_DESTINATION,
            categoryId = ZO_MapPin.PIN_ORDERS.DESTINATIONS,
            gamepadSpacing = true,
        },
        SKYSHARD = 
        {
            creator = function(pin)
                ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendSkyshardHint(pin:GetSkyshardId())
            end,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            categoryId = ZO_MapPin.PIN_ORDERS.SUGGESTIONS,
            gamepadSpacing = true,
        },
        DIG_SITE =
        {
            creator = function(pin)
                ZO_WorldMap_GetTooltipForMode(ZO_MAP_TOOLTIP_MODE.INFORMATION):AppendDigSiteAntiquities(pin:GetAntiquityDigSiteId())
            end,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            categoryId = ZO_MapPin.PIN_ORDERS.ANTIQUITIES,
            gamepadCategory = SI_GAMEPAD_WORLD_MAP_TOOLTIP_CATEGORY_ANTIQUITIES,
        },
        KILL_LOCATION =
        {
            creator = AppendKillLocationInfo,
            tooltip = ZO_MAP_TOOLTIP_MODE.INFORMATION,
            hasTooltip = IsKillLocation,
            categoryId = ZO_MapPin.PIN_ORDERS.AVA_KILL_LOCATION,
            gamepadSpacing = true,
        },
    }

    ZO_MapPin.TOOLTIP_CREATORS =
    {
        [MAP_PIN_TYPE_PLAYER]                                       =   SHARED_TOOLTIP_CREATORS.PLAYER_PIN,
        [MAP_PIN_TYPE_GROUP]                                        =   SHARED_TOOLTIP_CREATORS.PLAYER_PIN,
        [MAP_PIN_TYPE_GROUP_LEADER]                                 =   SHARED_TOOLTIP_CREATORS.PLAYER_PIN,
        [MAP_PIN_TYPE_ASSISTED_QUEST_ENDING]                        =   SHARED_TOOLTIP_CREATORS.QUEST_ENDING,
        [MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION]                     =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION]            =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_ENDING]             =   SHARED_TOOLTIP_CREATORS.QUEST_ENDING,
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION]          =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION] =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_ENDING]             =   SHARED_TOOLTIP_CREATORS.QUEST_ENDING,
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_CONDITION]          =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_POI_SUGGESTED]                                =   SHARED_TOOLTIP_CREATORS.SUGGESTION_ACTIVITY,
        [MAP_PIN_TYPE_POI_SEEN]                                     =   SHARED_TOOLTIP_CREATORS.POI,
        [MAP_PIN_TYPE_POI_COMPLETE]                                 =   SHARED_TOOLTIP_CREATORS.POI,
        [MAP_PIN_TYPE_SKYSHARD_SUGGESTED]                           =   SHARED_TOOLTIP_CREATORS.SUGGESTION_ACTIVITY,
        [MAP_PIN_TYPE_SKYSHARD_SEEN]                                =   SHARED_TOOLTIP_CREATORS.SKYSHARD,
        [MAP_PIN_TYPE_SKYSHARD_COMPLETE]                            =   SHARED_TOOLTIP_CREATORS.SKYSHARD,
        [MAP_PIN_TYPE_TRACKED_QUEST_ENDING]                         =   SHARED_TOOLTIP_CREATORS.QUEST_ENDING,
        [MAP_PIN_TYPE_TRACKED_QUEST_CONDITION]                      =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_TRACKED_QUEST_OPTIONAL_CONDITION]             =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_ENDING]              =   SHARED_TOOLTIP_CREATORS.QUEST_ENDING,
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_CONDITION]           =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_OPTIONAL_CONDITION]  =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_ENDING]              =   SHARED_TOOLTIP_CREATORS.QUEST_ENDING,
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_CONDITION]           =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_OPTIONAL_CONDITION]  =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_QUEST_ENDING]                                 =   SHARED_TOOLTIP_CREATORS.QUEST_ENDING,
        [MAP_PIN_TYPE_QUEST_CONDITION]                              =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_QUEST_OPTIONAL_CONDITION]                     =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_QUEST_REPEATABLE_ENDING]                      =   SHARED_TOOLTIP_CREATORS.QUEST_ENDING,
        [MAP_PIN_TYPE_QUEST_REPEATABLE_CONDITION]                   =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_QUEST_REPEATABLE_OPTIONAL_CONDITION]          =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_ENDING]                      =   SHARED_TOOLTIP_CREATORS.QUEST_ENDING,
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_CONDITION]                   =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_OPTIONAL_CONDITION]          =   SHARED_TOOLTIP_CREATORS.QUEST_CONDITION,
        [MAP_PIN_TYPE_TRACKED_QUEST_OFFER_ZONE_STORY]               =   SHARED_TOOLTIP_CREATORS.SUGGESTION_ACTIVITY,
        [MAP_PIN_TYPE_ANTIQUITY_DIG_SITE]                           =   SHARED_TOOLTIP_CREATORS.DIG_SITE,
        [MAP_PIN_TYPE_TRACKED_ANTIQUITY_DIG_SITE]                   =   SHARED_TOOLTIP_CREATORS.DIG_SITE,
        [MAP_PIN_TYPE_LOCATION]                                     =   SHARED_TOOLTIP_CREATORS.LOCATION,
        [MAP_PIN_TYPE_PING]                                         =   SHARED_TOOLTIP_CREATORS.PING,
        [MAP_PIN_TYPE_RALLY_POINT]                                  =   SHARED_TOOLTIP_CREATORS.RALLY_POINT,
        [MAP_PIN_TYPE_PLAYER_WAYPOINT]                              =   SHARED_TOOLTIP_CREATORS.PLAYER_WAYPOINT,
        [MAP_PIN_TYPE_KEEP_NEUTRAL]                                 =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_KEEP_ALDMERI_DOMINION]                        =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_KEEP_EBONHEART_PACT]                          =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_KEEP_DAGGERFALL_COVENANT]                     =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_OUTPOST_NEUTRAL]                              =   SHARED_TOOLTIP_CREATORS.OUTPOST,
        [MAP_PIN_TYPE_OUTPOST_ALDMERI_DOMINION]                     =   SHARED_TOOLTIP_CREATORS.OUTPOST,
        [MAP_PIN_TYPE_OUTPOST_EBONHEART_PACT]                       =   SHARED_TOOLTIP_CREATORS.OUTPOST,
        [MAP_PIN_TYPE_OUTPOST_DAGGERFALL_COVENANT]                  =   SHARED_TOOLTIP_CREATORS.OUTPOST,
        [MAP_PIN_TYPE_BORDER_KEEP_ALDMERI_DOMINION]                 =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_BORDER_KEEP_EBONHEART_PACT]                   =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_BORDER_KEEP_DAGGERFALL_COVENANT]              =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_ARTIFACT_KEEP_ALDMERI_DOMINION]               =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_ARTIFACT_KEEP_EBONHEART_PACT]                 =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_ARTIFACT_KEEP_DAGGERFALL_COVENANT]            =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_KEEP_BRIDGE]                                  =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_KEEP_BRIDGE_IMPASSABLE]                       =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_KEEP_MILEGATE]                                =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_KEEP_MILEGATE_CENTER_DESTROYED]               =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_KEEP_MILEGATE_IMPASSABLE]                     =   SHARED_TOOLTIP_CREATORS.KEEP,
        [MAP_PIN_TYPE_FARM_NEUTRAL]                                 =   SHARED_TOOLTIP_CREATORS.RESOURCE,
        [MAP_PIN_TYPE_FARM_ALDMERI_DOMINION]                        =   SHARED_TOOLTIP_CREATORS.RESOURCE,
        [MAP_PIN_TYPE_FARM_EBONHEART_PACT]                          =   SHARED_TOOLTIP_CREATORS.RESOURCE,
        [MAP_PIN_TYPE_FARM_DAGGERFALL_COVENANT]                     =   SHARED_TOOLTIP_CREATORS.RESOURCE,
        [MAP_PIN_TYPE_MINE_NEUTRAL]                                 =   SHARED_TOOLTIP_CREATORS.RESOURCE,
        [MAP_PIN_TYPE_MINE_ALDMERI_DOMINION]                        =   SHARED_TOOLTIP_CREATORS.RESOURCE,
        [MAP_PIN_TYPE_MINE_EBONHEART_PACT]                          =   SHARED_TOOLTIP_CREATORS.RESOURCE,
        [MAP_PIN_TYPE_MINE_DAGGERFALL_COVENANT]                     =   SHARED_TOOLTIP_CREATORS.RESOURCE,
        [MAP_PIN_TYPE_MILL_NEUTRAL]                                 =   SHARED_TOOLTIP_CREATORS.RESOURCE,
        [MAP_PIN_TYPE_MILL_ALDMERI_DOMINION]                        =   SHARED_TOOLTIP_CREATORS.RESOURCE,
        [MAP_PIN_TYPE_MILL_EBONHEART_PACT]                          =   SHARED_TOOLTIP_CREATORS.RESOURCE,
        [MAP_PIN_TYPE_MILL_DAGGERFALL_COVENANT]                     =   SHARED_TOOLTIP_CREATORS.RESOURCE,
        [MAP_PIN_TYPE_AVA_TOWN_NEUTRAL]                             =   SHARED_TOOLTIP_CREATORS.TOWN,
        [MAP_PIN_TYPE_AVA_TOWN_ALDMERI_DOMINION]                    =   SHARED_TOOLTIP_CREATORS.TOWN,
        [MAP_PIN_TYPE_AVA_TOWN_EBONHEART_PACT]                      =   SHARED_TOOLTIP_CREATORS.TOWN,
        [MAP_PIN_TYPE_AVA_TOWN_DAGGERFALL_COVENANT]                 =   SHARED_TOOLTIP_CREATORS.TOWN,
        [MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_ALDMERI_DOMINION]          =   SHARED_TOOLTIP_CREATORS.GATE,
        [MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_DAGGERFALL_COVENANT]       =   SHARED_TOOLTIP_CREATORS.GATE,
        [MAP_PIN_TYPE_ARTIFACT_GATE_OPEN_EBONHEART_PACT]            =   SHARED_TOOLTIP_CREATORS.GATE,
        [MAP_PIN_TYPE_ARTIFACT_GATE_CLOSED_ALDMERI_DOMINION]        =   SHARED_TOOLTIP_CREATORS.GATE,
        [MAP_PIN_TYPE_ARTIFACT_GATE_CLOSED_DAGGERFALL_COVENANT]     =   SHARED_TOOLTIP_CREATORS.GATE,
        [MAP_PIN_TYPE_ARTIFACT_GATE_CLOSED_EBONHEART_PACT]          =   SHARED_TOOLTIP_CREATORS.GATE,
        [MAP_PIN_TYPE_ARTIFACT_ALDMERI_OFFENSIVE]                   =   SHARED_TOOLTIP_CREATORS.ARTIFACT,
        [MAP_PIN_TYPE_ARTIFACT_ALDMERI_DEFENSIVE]                   =   SHARED_TOOLTIP_CREATORS.ARTIFACT,
        [MAP_PIN_TYPE_ARTIFACT_EBONHEART_OFFENSIVE]                 =   SHARED_TOOLTIP_CREATORS.ARTIFACT,
        [MAP_PIN_TYPE_ARTIFACT_EBONHEART_DEFENSIVE]                 =   SHARED_TOOLTIP_CREATORS.ARTIFACT,
        [MAP_PIN_TYPE_ARTIFACT_DAGGERFALL_OFFENSIVE]                =   SHARED_TOOLTIP_CREATORS.ARTIFACT,
        [MAP_PIN_TYPE_ARTIFACT_DAGGERFALL_DEFENSIVE]                =   SHARED_TOOLTIP_CREATORS.ARTIFACT,
        [MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE]                        =   SHARED_TOOLTIP_CREATORS.WAYSHRINE,
        [MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE_CURRENT_LOC]            =   SHARED_TOOLTIP_CREATORS.WAYSHRINE,
        [MAP_PIN_TYPE_FORWARD_CAMP_ALDMERI_DOMINION]                =   SHARED_TOOLTIP_CREATORS.FORWARD_CAMP,
        [MAP_PIN_TYPE_FORWARD_CAMP_EBONHEART_PACT]                  =   SHARED_TOOLTIP_CREATORS.FORWARD_CAMP,
        [MAP_PIN_TYPE_FORWARD_CAMP_DAGGERFALL_COVENANT]             =   SHARED_TOOLTIP_CREATORS.FORWARD_CAMP,
        [MAP_PIN_TYPE_IMPERIAL_DISTRICT_NEUTRAL]                    =   SHARED_TOOLTIP_CREATORS.DISTRICT,
        [MAP_PIN_TYPE_IMPERIAL_DISTRICT_ALDMERI_DOMINION]           =   SHARED_TOOLTIP_CREATORS.DISTRICT,
        [MAP_PIN_TYPE_IMPERIAL_DISTRICT_EBONHEART_PACT]             =   SHARED_TOOLTIP_CREATORS.DISTRICT,
        [MAP_PIN_TYPE_IMPERIAL_DISTRICT_DAGGERFALL_COVENANT]        =   SHARED_TOOLTIP_CREATORS.DISTRICT,
        [MAP_PIN_TYPE_RESTRICTED_LINK_ALDMERI_DOMINION]             =   SHARED_TOOLTIP_CREATORS.RESTRICTED_LINK,
        [MAP_PIN_TYPE_RESTRICTED_LINK_EBONHEART_PACT]               =   SHARED_TOOLTIP_CREATORS.RESTRICTED_LINK,
        [MAP_PIN_TYPE_RESTRICTED_LINK_DAGGERFALL_COVENANT]          =   SHARED_TOOLTIP_CREATORS.RESTRICTED_LINK,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_FIRE_DRAKES]               =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_PIT_DAEMONS]               =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_STORM_LORDS]               =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_NEUTRAL]                   =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_FIRE_DRAKES]             =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_PIT_DAEMONS]             =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_STORM_LORDS]             =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_A_NEUTRAL]                 =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_FIRE_DRAKES]             =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_PIT_DAEMONS]             =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_STORM_LORDS]             =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_B_NEUTRAL]                 =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_FIRE_DRAKES]             =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_PIT_DAEMONS]             =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_STORM_LORDS]             =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_C_NEUTRAL]                 =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_FIRE_DRAKES]             =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_PIT_DAEMONS]             =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_STORM_LORDS]             =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_CAPTURE_AREA_D_NEUTRAL]                 =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_FIRE_DRAKES]        =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_PIT_DAEMONS]        =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_STORM_LORDS]        =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_NEUTRAL]            =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_A_FIRE_DRAKES]      =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_A_PIT_DAEMONS]      =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_A_STORM_LORDS]      =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_A_NEUTRAL]          =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_B_FIRE_DRAKES]      =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_B_PIT_DAEMONS]      =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_B_STORM_LORDS]      =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_B_NEUTRAL]          =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_C_FIRE_DRAKES]      =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_C_PIT_DAEMONS]      =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_C_STORM_LORDS]      =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_C_NEUTRAL]          =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_D_FIRE_DRAKES]      =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_D_PIT_DAEMONS]      =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_D_STORM_LORDS]      =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MOBILE_CAPTURE_AREA_D_NEUTRAL]          =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_FLAG_FIRE_DRAKES]                       =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_FLAG_PIT_DAEMONS]                       =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_FLAG_STORM_LORDS]                       =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_FLAG_NEUTRAL]                           =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_FLAG_SPAWN_FIRE_DRAKES]                 =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_FLAG_SPAWN_PIT_DAEMONS]                 =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_FLAG_SPAWN_STORM_LORDS]                 =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_FLAG_SPAWN_NEUTRAL]                     =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_FLAG_RETURN_FIRE_DRAKES]                =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_FLAG_RETURN_PIT_DAEMONS]                =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_FLAG_RETURN_STORM_LORDS]                =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MURDERBALL_NEUTRAL]                     =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MURDERBALL_FIRE_DRAKES]                 =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MURDERBALL_PIT_DAEMONS]                 =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MURDERBALL_STORM_LORDS]                 =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_BGPIN_MURDERBALL_SPAWN_NEUTRAL]               =   SHARED_TOOLTIP_CREATORS.BG_OBJECTIVE,
        [MAP_PIN_TYPE_UNIT_COMBAT_HEALTHY]                          =   SHARED_TOOLTIP_CREATORS.WORLD_EVENT_UNIT,
        [MAP_PIN_TYPE_UNIT_COMBAT_WEAK]                             =   SHARED_TOOLTIP_CREATORS.WORLD_EVENT_UNIT,
        [MAP_PIN_TYPE_UNIT_IDLE_HEALTHY]                            =   SHARED_TOOLTIP_CREATORS.WORLD_EVENT_UNIT,
        [MAP_PIN_TYPE_UNIT_IDLE_WEAK]                               =   SHARED_TOOLTIP_CREATORS.WORLD_EVENT_UNIT,
        [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_NEUTRAL]      =   SHARED_TOOLTIP_CREATORS.DAEDRIC_ARTIFACT,
        [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_ALDMERI]      =   SHARED_TOOLTIP_CREATORS.DAEDRIC_ARTIFACT,
        [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_EBONHEART]    =   SHARED_TOOLTIP_CREATORS.DAEDRIC_ARTIFACT,
        [MAP_PIN_TYPE_AVA_DAEDRIC_ARTIFACT_VOLENDRUNG_DAGGERFALL]   =   SHARED_TOOLTIP_CREATORS.DAEDRIC_ARTIFACT,
        [MAP_PIN_TYPE_ACTIVE_COMPANION]                             =   SHARED_TOOLTIP_CREATORS.COMPANION_PIN,
        [MAP_PIN_TYPE_ALDMERI_VS_EBONHEART_SMALL]                   =   SHARED_TOOLTIP_CREATORS.KILL_LOCATION,
        [MAP_PIN_TYPE_ALDMERI_VS_EBONHEART_MEDIUM]                  =   SHARED_TOOLTIP_CREATORS.KILL_LOCATION,
        [MAP_PIN_TYPE_ALDMERI_VS_EBONHEART_LARGE]                   =   SHARED_TOOLTIP_CREATORS.KILL_LOCATION,
        [MAP_PIN_TYPE_ALDMERI_VS_DAGGERFALL_SMALL]                  =   SHARED_TOOLTIP_CREATORS.KILL_LOCATION,
        [MAP_PIN_TYPE_ALDMERI_VS_DAGGERFALL_MEDIUM]                 =   SHARED_TOOLTIP_CREATORS.KILL_LOCATION,
        [MAP_PIN_TYPE_ALDMERI_VS_DAGGERFALL_LARGE]                  =   SHARED_TOOLTIP_CREATORS.KILL_LOCATION,
        [MAP_PIN_TYPE_EBONHEART_VS_DAGGERFALL_SMALL]                =   SHARED_TOOLTIP_CREATORS.KILL_LOCATION,
        [MAP_PIN_TYPE_EBONHEART_VS_DAGGERFALL_MEDIUM]               =   SHARED_TOOLTIP_CREATORS.KILL_LOCATION,
        [MAP_PIN_TYPE_EBONHEART_VS_DAGGERFALL_LARGE]                =   SHARED_TOOLTIP_CREATORS.KILL_LOCATION,
        [MAP_PIN_TYPE_TRI_BATTLE_SMALL]                             =   SHARED_TOOLTIP_CREATORS.KILL_LOCATION,
        [MAP_PIN_TYPE_TRI_BATTLE_MEDIUM]                            =   SHARED_TOOLTIP_CREATORS.KILL_LOCATION,
        [MAP_PIN_TYPE_TRI_BATTLE_LARGE]                             =   SHARED_TOOLTIP_CREATORS.KILL_LOCATION,
    }
end

local function GetReviveKeybindText(pinDatas)
    -- All invalid revive locations are already removed from the pinHandlers passed in,
    -- just count how many are revive locations
    local numRespawnLocations = 0
    for i, pinData in ipairs(pinDatas) do
        if ZO_MapPin.IsReviveLocation(pinData.handler) then
            numRespawnLocations = numRespawnLocations + 1
        end
    end

    if numRespawnLocations == 1 then
        return GetString(SI_GAMEPAD_WORLD_MAP_INTERACT_REVIVE)
    elseif numRespawnLocations > 1 then
        return GetString(SI_GAMEPAD_WORLD_MAP_INTERACT_CHOOSE_REVIVE)
    end

    return ZO_ERROR_COLOR:Colorize(GetString(SI_GAMEPAD_WORLD_MAP_INTERACT_CANT_REVIVE))
end

local QUEST_PIN_LMB =
{
    {
        name = function(pin)
            local questIndex = pin:GetQuestIndex()
            local questName = GetJournalQuestName(questIndex)
            return zo_strformat(SI_WORLD_MAP_ACTION_SELECT_QUEST, questName)
        end,
        show = function(pin)
            local questIndex = pin:GetQuestIndex()
            return questIndex ~= -1 and not GetTrackedIsAssisted(TRACK_TYPE_QUEST, questIndex)
        end,
        callback = function(pin)
            local questIndex = pin:GetQuestIndex()
            FOCUSED_QUEST_TRACKER:ForceAssist(questIndex)
        end,
        duplicates = function(pin1, pin2)
            local questIndex1 = pin1:GetQuestIndex()
            local questIndex2 = pin2:GetQuestIndex()
            return questIndex1 == questIndex2
        end,
        gamepadName = function(pinDatas)
            if #pinDatas == 1 then
                return GetString(SI_GAMEPAD_WORLD_MAP_INTERACT_SET_ACTIVE_QUEST)
            else
                return GetString(SI_GAMEPAD_WORLD_MAP_INTERACT_CHOOSE_ACTIVE_QUEST)
            end
        end,
    },
}

local RALLY_POINT_RMB =
{
    {
        name = GetString(SI_WORLD_MAP_ACTION_REMOVE_RALLY_POINT),
        callback = function()
            RemoveRallyPoint()
        end,
    }
}

local KEEP_TRAVEL_BIND =
{
    name = GetString(SI_WORLD_MAP_ACTION_TRAVEL_TO_KEEP),
    show = function(pin)
        local keepId = pin:GetKeepId()
        local isLocalKeep = IsLocalBattlegroundContext(pin:GetBattlegroundContext())
        local worldMapMode = WORLD_MAP_MANAGER:GetMode()
        if keepId ~= 0 and (worldMapMode == MAP_MODE_KEEP_TRAVEL or worldMapMode == MAP_MODE_AVA_KEEP_RECALL) and isLocalKeep then
            local fastTravelPin = ZO_WorldMap_GetPinManager():FindPin("fastTravelKeep", keepId, keepId)
            if fastTravelPin then
                return true
            end
        end

        return false
    end,
    failedAfterBeingShownError = GetString(SI_WORLD_MAP_ACTION_TRAVEL_TO_KEEP_FAILED),
    callback = function(pin)
        local keepId = pin:GetKeepId()
        local canTravelToKeep = WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_KEEP_RECALL)
        if not canTravelToKeep then
            local startKeepId = GetKeepFastTravelInteraction()
            canTravelToKeep = startKeepId and keepId ~= startKeepId
        end
        if canTravelToKeep then
            TravelToKeep(keepId)
            ZO_WorldMap_HideWorldMap()
        end
    end,
    gamepadName = function(pinDatas)
        if #pinDatas == 1 then
            return GetString(SI_GAMEPAD_WORLD_MAP_INTERACT_TRAVEL)
        else
            return GetString(SI_GAMEPAD_WORLD_MAP_INTERACT_CHOOSE_DESTINATION)
        end
    end,
}

local KEEP_RESPAWN_BIND =
{
    name = GetString(SI_WORLD_MAP_ACTION_RESPAWN_AT_KEEP),
    show = function(pin)
        if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_RESPAWN) then
            return CanRespawnAtKeep(pin:GetKeepId())
        end
    end,
    failedAfterBeingShownError = GetString(SI_WORLD_MAP_ACTION_RESPAWN_AT_KEEP_FAILED),
    callback = function(pin)
        local keepId = pin:GetKeepId()
        RespawnAtKeep(keepId)
        ZO_WorldMap_HideWorldMap()
    end,
    gamepadName = function(pinDatas)
        return GetReviveKeybindText(pinDatas)
    end,
    isKeepRespawnHandler = true,
}

local KEEP_INFO_BIND =
{
    name = GetString(SI_WORLD_MAP_ACTION_SHOW_INFORMATION),
    gamepadName = GetString(SI_WORLD_MAP_ACTION_SHOW_INFORMATION),
    show = function(pin)
        local keepId = pin:GetKeepId()
        local keepType = GetKeepType(keepId)
        local worldMapMode = WORLD_MAP_MANAGER:GetMode()
        return (keepType == KEEPTYPE_KEEP or keepType == KEEPTYPE_RESOURCE) and worldMapMode ~= MAP_MODE_KEEP_TRAVEL and worldMapMode ~= MAP_MODE_AVA_RESPAWN and worldMapMode ~= MAP_MODE_AVA_KEEP_RECALL
    end,
    callback = function(pin)
        local keepId = pin:GetKeepId()

        SYSTEMS:GetObject("world_map_keep_info"):ToggleKeep(keepId)
    end,
}

local HIDE_KEEP_INFO_BIND =
{
    name = GetString(SI_WORLD_MAP_ACTION_HIDE_INFORMATION),
    gamepadName = GetString(SI_WORLD_MAP_ACTION_HIDE_INFORMATION),
    show = function(pin)
        local worldMapMode = WORLD_MAP_MANAGER:GetMode()
        return worldMapMode ~= MAP_MODE_KEEP_TRAVEL and worldMapMode ~= MAP_MODE_AVA_RESPAWN and worldMapMode ~= MAP_MODE_AVA_KEEP_RECALL and SYSTEMS:GetObject("world_map_keep_info"):GetKeepUpgradeObject() ~= nil
    end,
    callback = function(pin)
        SYSTEMS:GetObject("world_map_keep_info"):HideKeep()
    end,
}

local KEEP_PIN_LMB =
{
    KEEP_TRAVEL_BIND,
    KEEP_RESPAWN_BIND,
    KEEP_INFO_BIND,
}

local DISTRICT_PIN_LMB =
{
    KEEP_RESPAWN_BIND,
    HIDE_KEEP_INFO_BIND,
}

local TOWN_PIN_LMB =
{
    KEEP_TRAVEL_BIND,
    KEEP_RESPAWN_BIND,
    HIDE_KEEP_INFO_BIND,
}

local function GetTravelPinGamepadButtonText(pinDatas)
    if #pinDatas == 1 then
        if pinDatas[1].pin:IsLockedByLinkedCollectible() then
            return pinDatas[1].pin:GetLockedByLinkedCollectibleInteractString()
        else
            return GetString(SI_GAMEPAD_WORLD_MAP_INTERACT_TRAVEL)
        end
    else
        return GetString(SI_GAMEPAD_WORLD_MAP_INTERACT_CHOOSE_DESTINATION)
    end
end

local WAYSHRINE_LMB =
{
    --Recall
    {
        name = function(pin)
            if pin:IsLockedByLinkedCollectible() then
                return pin:GetLockedByLinkedCollectibleInteractString()
            else
                local nodeIndex = pin:GetFastTravelNodeIndex()
                local _, recallLocationName = GetFastTravelNodeInfo(nodeIndex)
                return zo_strformat(SI_WORLD_MAP_ACTION_RECALL_TO_WAYSHRINE, recallLocationName)
            end
        end,

        show = function(pin)
            local nodeIndex = pin:GetFastTravelNodeIndex()
            return nodeIndex ~= nil and GetFastTravelNodeHouseId(nodeIndex) == 0 and ZO_Map_GetFastTravelNode() == nil and 
                    not IsInCampaign() and not GetFastTravelNodeOutboundOnlyInfo(nodeIndex) and
                    CanLeaveCurrentLocationViaTeleport() and not IsUnitDead("player")
        end,
        
        callback = function(pin)
            if pin:IsLockedByLinkedCollectible() then
                if pin:GetLinkedCollectibleType() == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
                    ZO_ShowChapterUpgradePlatformScreen(MARKET_OPEN_OPERATION_DLC_FAILURE_WORLD_MAP)
                else
                    local collectibleData = pin:GetLinkedCollectibleData()
                    local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData:GetName())
                    ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_DLC_FAILURE_WORLD_MAP)
                end
            else
                ZO_Dialogs_ReleaseDialog("FAST_TRAVEL_CONFIRM")
                ZO_Dialogs_ReleaseDialog("RECALL_CONFIRM")
                ZO_Dialogs_ReleaseDialog("TRAVEL_TO_HOUSE_CONFIRM")
                local nodeIndex = pin:GetFastTravelNodeIndex()
                local name = select(2, GetFastTravelNodeInfo(nodeIndex))
                local _, premiumTimeLeft = GetRecallCooldown()
                if premiumTimeLeft == 0 then
                    ZO_Dialogs_ShowPlatformDialog("RECALL_CONFIRM", {nodeIndex = nodeIndex}, {mainTextParams = {name}})
                else
                    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, zo_strformat(SI_FAST_TRAVEL_RECALL_COOLDOWN, name, ZO_FormatTimeMilliseconds(premiumTimeLeft, TIME_FORMAT_STYLE_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS)))
                end
            end
        end,

        gamepadName = GetTravelPinGamepadButtonText,
    },

    --Fast Travel
    {
        name = function(pin)
            if pin:IsLockedByLinkedCollectible() then
                return pin:GetLockedByLinkedCollectibleInteractString()
            else
                local nodeIndex = pin:GetFastTravelNodeIndex()
                local _, travelLocationName = GetFastTravelNodeInfo(nodeIndex)
                return zo_strformat(SI_WORLD_MAP_ACTION_TRAVEL_TO_WAYSHRINE, travelLocationName)
            end
        end,

        show = function(pin)
            local nodeIndex = pin:GetFastTravelNodeIndex()
            return nodeIndex and GetFastTravelNodeHouseId(nodeIndex) == 0 and ZO_Map_GetFastTravelNode() and not GetFastTravelNodeOutboundOnlyInfo(nodeIndex)
        end,

        callback = function(pin)
            if pin:IsLockedByLinkedCollectible() then
                if pin:GetLinkedCollectibleType() == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
                    ZO_ShowChapterUpgradePlatformScreen(MARKET_OPEN_OPERATION_DLC_FAILURE_WORLD_MAP)
                else
                    local collectibleData = pin:GetLinkedCollectibleData()
                    local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData:GetName())
                    ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_DLC_FAILURE_WORLD_MAP)
                end
            else
                ZO_Dialogs_ReleaseDialog("FAST_TRAVEL_CONFIRM")
                ZO_Dialogs_ReleaseDialog("RECALL_CONFIRM")
                ZO_Dialogs_ReleaseDialog("TRAVEL_TO_HOUSE_CONFIRM")
                local nodeIndex = pin:GetFastTravelNodeIndex()
                local name = select(2, GetFastTravelNodeInfo(nodeIndex))
                ZO_Dialogs_ShowPlatformDialog("FAST_TRAVEL_CONFIRM", {nodeIndex = nodeIndex}, {mainTextParams = {name}})
            end
        end,

        gamepadName = GetTravelPinGamepadButtonText,
    },

    --House
    {
        show = function(pin)
            local nodeIndex = pin:GetFastTravelNodeIndex()
            if nodeIndex and GetFastTravelNodeHouseId(nodeIndex) ~= 0 then
                if ZO_Map_GetFastTravelNode() then
                    return true
                else
                    return CanLeaveCurrentLocationViaTeleport() and not IsInCampaign() and not IsUnitDead("player")
                end
            end
            return false
        end,

        GetDynamicHandlers = function(pin)
            local nodeIndex = pin:GetFastTravelNodeIndex()
            local _, travelLocationName = GetFastTravelNodeInfo(nodeIndex)
            local houseId = GetFastTravelNodeHouseId(nodeIndex)
            local isPreview = not HasCompletedFastTravelNodePOI(nodeIndex)

            local handlers = {}
            local primaryHandler =
            {
                name = function(pin)
                    if isPreview then
                        return zo_strformat(SI_WORLD_MAP_ACTION_PREVIEW_HOUSE, travelLocationName)
                    else
                        return zo_strformat(SI_WORLD_MAP_ACTION_TRAVEL_TO_HOUSE_INSIDE, travelLocationName)
                    end
                end,

                callback = function(pin)
                    ZO_Dialogs_ReleaseDialog("FAST_TRAVEL_CONFIRM")
                    ZO_Dialogs_ReleaseDialog("RECALL_CONFIRM")
                    ZO_Dialogs_ReleaseDialog("TRAVEL_TO_HOUSE_CONFIRM")
                    local nodeIndex = pin:GetFastTravelNodeIndex()
                    local name = select(2, GetFastTravelNodeInfo(nodeIndex))
                    ZO_Dialogs_ShowPlatformDialog("TRAVEL_TO_HOUSE_CONFIRM", { houseId = houseId, travelOutside = false }, { mainTextParams = { name } })
                end,

                gamepadName = GetTravelPinGamepadButtonText,

                gamepadPinActionGroup = ZO_WORLD_MAP_GAMEPAD_PIN_ACTION_GROUP_FAST_TRAVEL,

                gamepadChoiceOverrideName = function(pin)
                    if isPreview then
                        return zo_strformat(SI_WORLD_MAP_ACTION_PREVIEW_HOUSE, travelLocationName)
                    else
                        return zo_strformat(SI_GAMEPAD_WORLD_MAP_TRAVEL_TO_HOUSE_INSIDE, travelLocationName)
                    end
                end,
            }

            table.insert(handlers, primaryHandler)

            if not isPreview then
                local secondaryHandler =
                {
                    name = function(pin)
                        return zo_strformat(SI_WORLD_MAP_ACTION_TRAVEL_TO_HOUSE_OUTSIDE, travelLocationName)
                    end,

                    callback = function(pin)
                        ZO_Dialogs_ReleaseDialog("FAST_TRAVEL_CONFIRM")
                        ZO_Dialogs_ReleaseDialog("RECALL_CONFIRM")
                        ZO_Dialogs_ReleaseDialog("TRAVEL_TO_HOUSE_CONFIRM")
                        local nodeIndex = pin:GetFastTravelNodeIndex()
                        local name = select(2, GetFastTravelNodeInfo(nodeIndex))
                        ZO_Dialogs_ShowPlatformDialog("TRAVEL_TO_HOUSE_CONFIRM", { houseId = houseId, travelOutside = true }, { mainTextParams = { name } })
                    end,

                    gamepadName = GetTravelPinGamepadButtonText,

                    gamepadPinActionGroup = ZO_WORLD_MAP_GAMEPAD_PIN_ACTION_GROUP_FAST_TRAVEL,

                    gamepadChoiceOverrideName = function(pin)
                        return zo_strformat(SI_GAMEPAD_WORLD_MAP_TRAVEL_TO_HOUSE_OUTSIDE, travelLocationName)
                    end,
                }

                table.insert(handlers, secondaryHandler)
            end

            return handlers
        end,
    },
}

local FORWARD_CAMP_LMB =
{
    {
        name = GetString(SI_WORLD_MAP_ACTION_RESPAWN_AT_FORWARD_CAMP),
        show = function(pin)
            return WORLD_MAP_MANAGER:IsInMode(MAP_MODE_AVA_RESPAWN)
        end,
        callback = function(pin)
            if pin:IsForwardCampUsable() then
                RespawnAtForwardCamp(pin:GetForwardCampIndex())
            end
        end,
        gamepadName = function(pinDatas)
            return GetReviveKeybindText(pinDatas)
        end,
    },
}

local DIG_SITE_LMB =
{
    {
        show = function(pin)
            -- only show a handler for a tracked dig site if there are multiple antiquities associated with it
            if pin:GetPinType() == MAP_PIN_TYPE_TRACKED_ANTIQUITY_DIG_SITE then
                local antiquityIds = { GetInProgressAntiquitiesForDigSite(pin:GetAntiquityDigSiteId()) }
                return #antiquityIds > 1
            end

            return true
        end,
        GetDynamicHandlers = function(pin)
            local handlers = {}
            local antiquityIds = { GetInProgressAntiquitiesForDigSite(pin:GetAntiquityDigSiteId()) }

            local trackedAntiquityId = GetTrackedAntiquityId()

            for i, antiquityId in ipairs(antiquityIds) do
                if antiquityId ~= trackedAntiquityId then
                    local antiquityData = ANTIQUITY_DATA_MANAGER:GetAntiquityData(antiquityId)
                    local handler =
                    {
                        name = function(pin)
                            return zo_strformat(SI_WORLD_MAP_ACTION_TRACK_ANTIQUITY, antiquityData:GetName())
                        end,
                        gamepadName = function(pinDatas)
                            if #pinDatas == 1 then
                                return GetString(SI_GAMEPAD_WORLD_MAP_INTERACT_TRACK_ANTIQUITY)
                            else
                                return GetString(SI_GAMEPAD_WORLD_MAP_INTERACT_CHOOSE_TRACKED_ANTIQUITY)
                            end
                        end,
                        gamepadDialogEntryName = antiquityData:GetFormattedName(),
                        gamepadDialogEntryColor = GetAntiquityQualityColor(antiquityData:GetQuality()),
                        callback = function(pin)
                            SetTrackedAntiquityId(antiquityId)
                        end,
                    }

                    table.insert(handlers, handler)
                end
            end

            return handlers
        end,
    },
}

ZO_MapPin.PIN_CLICK_HANDLERS =
{
    [MOUSE_BUTTON_INDEX_LEFT] =
    {
        [MAP_PIN_TYPE_TRACKED_QUEST_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_TRACKED_QUEST_OPTIONAL_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_TRACKED_QUEST_ENDING] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_ENDING] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_ENDING] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_ASSISTED_QUEST_ENDING] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_ENDING] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_ENDING] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_QUEST_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_QUEST_OPTIONAL_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_QUEST_ENDING] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_QUEST_REPEATABLE_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_QUEST_REPEATABLE_OPTIONAL_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_QUEST_REPEATABLE_ENDING] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_ENDING] = QUEST_PIN_LMB,
        [MAP_PIN_TYPE_KEEP_NEUTRAL] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_KEEP_ALDMERI_DOMINION] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_KEEP_EBONHEART_PACT] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_KEEP_DAGGERFALL_COVENANT] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_BORDER_KEEP_ALDMERI_DOMINION] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_BORDER_KEEP_EBONHEART_PACT] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_BORDER_KEEP_DAGGERFALL_COVENANT] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_FARM_NEUTRAL] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_FARM_ALDMERI_DOMINION] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_FARM_EBONHEART_PACT] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_FARM_DAGGERFALL_COVENANT] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_MINE_NEUTRAL] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_MINE_ALDMERI_DOMINION] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_MINE_EBONHEART_PACT] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_MINE_DAGGERFALL_COVENANT] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_MILL_NEUTRAL] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_MILL_ALDMERI_DOMINION] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_MILL_EBONHEART_PACT] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_MILL_DAGGERFALL_COVENANT] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_OUTPOST_ALDMERI_DOMINION] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_OUTPOST_EBONHEART_PACT] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_OUTPOST_DAGGERFALL_COVENANT] = KEEP_PIN_LMB,
        [MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE] = WAYSHRINE_LMB,
        [MAP_PIN_TYPE_FORWARD_CAMP_ALDMERI_DOMINION] = FORWARD_CAMP_LMB,
        [MAP_PIN_TYPE_FORWARD_CAMP_EBONHEART_PACT] = FORWARD_CAMP_LMB,
        [MAP_PIN_TYPE_FORWARD_CAMP_DAGGERFALL_COVENANT] = FORWARD_CAMP_LMB,
        [MAP_PIN_TYPE_IMPERIAL_DISTRICT_NEUTRAL] = DISTRICT_PIN_LMB,
        [MAP_PIN_TYPE_IMPERIAL_DISTRICT_ALDMERI_DOMINION] = DISTRICT_PIN_LMB,
        [MAP_PIN_TYPE_IMPERIAL_DISTRICT_EBONHEART_PACT] = DISTRICT_PIN_LMB,
        [MAP_PIN_TYPE_IMPERIAL_DISTRICT_DAGGERFALL_COVENANT] = DISTRICT_PIN_LMB,
        [MAP_PIN_TYPE_AVA_TOWN_NEUTRAL] = TOWN_PIN_LMB,
        [MAP_PIN_TYPE_AVA_TOWN_ALDMERI_DOMINION] = TOWN_PIN_LMB,
        [MAP_PIN_TYPE_AVA_TOWN_EBONHEART_PACT] = TOWN_PIN_LMB,
        [MAP_PIN_TYPE_AVA_TOWN_DAGGERFALL_COVENANT] = TOWN_PIN_LMB,
        [MAP_PIN_TYPE_ANTIQUITY_DIG_SITE] = DIG_SITE_LMB,
        [MAP_PIN_TYPE_TRACKED_ANTIQUITY_DIG_SITE] = DIG_SITE_LMB,
    },

    [MOUSE_BUTTON_INDEX_RIGHT] =
    {
        [MAP_PIN_TYPE_RALLY_POINT] = RALLY_POINT_RMB,
    },
}

function ZO_MapPin.IsReviveLocation(pinHandler)
    return pinHandler == KEEP_RESPAWN_BIND or pinHandler == FORWARD_CAMP_LMB[1]
end

function ZO_MapPin.CanReviveAtPin(pin, pinHandler)
    if pinHandler == KEEP_RESPAWN_BIND then
        local keepId = pin:GetKeepId()
        if CanRespawnAtKeep(keepId) then
            return true
        end
    elseif pinHandler == FORWARD_CAMP_LMB[1] then
        if pin:IsForwardCampUsable() then
            return true
        end
    end

    return false
end

ZO_WORLD_MAP_GAMEPAD_PIN_ACTION_GROUP_QUEST = 1
ZO_WORLD_MAP_GAMEPAD_PIN_ACTION_GROUP_FAST_TRAVEL = 2
ZO_WORLD_MAP_GAMEPAD_PIN_ACTION_GROUP_RESPAWN = 3

ZO_WORLD_MAP_GAMEPAD_PIN_ACTION_GROUP_TYPE_TO_HANDLERS = 
{
    { QUEST_PIN_LMB[1] }, -- Quest types
    { KEEP_TRAVEL_BIND, WAYSHRINE_LMB[1], WAYSHRINE_LMB[2] }, -- Fast Travel types
    { FORWARD_CAMP_LMB[1], KEEP_RESPAWN_BIND }, -- Revive types
}

ZO_MapPin.pinDatas = {}

ZO_MapPin.ANIMATION_ALPHA = 1

ZO_MapPin.PulseAnimation =
{
    texture = "EsoUI/Art/MapPins/UI-WorldMapPinHighlight.dds",
    duration = ZO_MapPin.ANIM_CONSTANTS.DEFAULT_LOOP_COUNT,
    type = ZO_MapPin.ANIMATION_ALPHA,
}

ZO_MapPin.SelectedAnimation =
{
    texture = "EsoUI/Art/WorldMap/selectedQuestHighlight.dds",
    duration = LOOP_INDEFINITELY,
    type = ZO_MapPin.ANIMATION_ALPHA,
}

do
    local nextPinId = 0
    function ZO_MapPin:Initialize(parentControl)
        local control = CreateControlFromVirtual("ZO_MapPin", parentControl, "ZO_MapPin", nextPinId)

        control.m_Pin = self
        self.m_Control = control
        self.highlightControl = control:GetNamedChild("Highlight")
        self.backgroundControl = control:GetNamedChild("Background")
        self.labelControl = control:GetNamedChild("Label")
        self.scaleModifier = 1
        self.pinId = nextPinId

        ZO_AlphaAnimation:New(self.highlightControl)
        self:ResetAnimation(ZO_MapPin.ANIM_CONSTANTS.RESET_ANIM_HIDE_CONTROL)

        nextPinId = nextPinId + 1
        return self
    end
end

function ZO_MapPin.GetMapPinForControl(control)
    return control.m_Pin
end

function ZO_MapPin.HidePulseAfterFadeOut(control)
    control:SetHidden(true)
end

function ZO_MapPin.DoFinalFadeInAfterPing(control)
    ZO_AlphaAnimation_GetAnimation(control):FadeIn(0, 300)
end

function ZO_MapPin.DoFinalFadeOutAfterPing(control)
    ZO_AlphaAnimation_GetAnimation(control):FadeOut(0, 300)
end

function ZO_MapPin.CreateQuestPinTag(questIndex, stepIndex, conditionIndex)
    return { questIndex, conditionIndex, stepIndex }
end

function ZO_MapPin.CreatePOIPinTag(zoneIndex, poiIndex, icon, linkedCollectibleIsLocked)
    return { zoneIndex, poiIndex, icon, linkedCollectibleIsLocked }
end

function ZO_MapPin.CreateLocationPinTag(locationIndex, icon)
    return { locationIndex, icon }
end

function ZO_MapPin.CreateObjectivePinTag(keepId, objectiveId, battlegroundContext)
    return { keepId, objectiveId, battlegroundContext }
end

function ZO_MapPin.CreateKeepPinTag(keepId, battlegroundContext, isUnderAttackPin)
    return { keepId, battlegroundContext, isUnderAttackPin }
end

function ZO_MapPin.CreateKeepTravelNetworkPinTag(keepId)
    return { keepId }
end

function ZO_MapPin.CreateRestrictedLinkTravelNetworkPinTag(restrictedAlliance, battlegroundContext)
    return { restrictedAlliance, battlegroundContext }
end

function ZO_MapPin.CreateTravelNetworkPinTag(nodeIndex, icon, glowIcon, linkedCollectibleIsLocked)
    return { nodeIndex, icon, glowIcon, linkedCollectibleIsLocked }
end

function ZO_MapPin.CreateForwardCampPinTag(forwardCampIndex)
    return { forwardCampIndex }
end

function ZO_MapPin.CreateAvARespawnPinTag(id)
    return { id }
end

function ZO_MapPin.CreateZoneStoryTag(zoneId, zoneCompletionType, activityId, icon)
    local tag = { zoneId, zoneCompletionType, activityId, icon }
    tag.isZoneStory = true
    return tag
end

function ZO_MapPin.CreateSkyshardPinTag(skyshardId)
    return { skyshardId }
end

function ZO_MapPin.CreateWorldEventPOIPinTag(worldEventInstanceId, zoneIndex, poiIndex)
    return { worldEventInstanceId, zoneIndex, poiIndex }
end

function ZO_MapPin.CreateWorldEventUnitPinTag(worldEventInstanceId, unitTag)
    return { worldEventInstanceId, unitTag }
end

function ZO_MapPin.CreateAntiquityDigSitePinTag(digSiteId)
    return { digSiteId }
end

function ZO_MapPin:StopTextureAnimation()
    if self.m_textureAnimTimeline then
        self.m_textureAnimTimeline:Stop()
    end
end

function ZO_MapPin:PlayTextureAnimation(framesWide, framesHigh, framesPerSecond)
    self:StopTextureAnimation()

    if not self.m_textureAnimTimeline then
        local anim
        anim, self.m_textureAnimTimeline = CreateSimpleAnimation(ANIMATION_TEXTURE, self.backgroundControl)

        anim:SetHandler("OnStop", function() self.backgroundControl:SetTextureCoords(0, 1, 0, 1) end)
    end

    local animation = self.m_textureAnimTimeline:GetAnimation(1)
    animation:SetImageData(framesWide, framesHigh)
    animation:SetFramerate(framesPerSecond)

    self.m_textureAnimTimeline:SetPlaybackType(ANIMATION_PLAYBACK_LOOP, LOOP_INDEFINITELY)
    self.m_textureAnimTimeline:PlayFromStart()
end

function ZO_MapPin:ResetAnimation(resetOptions, loopCount, pulseIcon, overlayIcon, postPulseCallback, min, max)
    resetOptions = resetOptions or ZO_MapPin.ANIM_CONSTANTS.RESET_ANIM_PREVENT_PLAY

    -- The animated control
    local pulseControl = self.highlightControl

    if resetOptions == ZO_MapPin.ANIM_CONSTANTS.RESET_ANIM_ALLOW_PLAY then
        pulseControl:SetHidden(pulseIcon == nil)

        if pulseIcon then
            pulseControl:SetTexture(pulseIcon)
            postPulseCallback = postPulseCallback or ZO_MapPin.DoFinalFadeOutAfterPing
            ZO_AlphaAnimation_GetAnimation(pulseControl):PingPong(0.3, 1, 750, loopCount, postPulseCallback)
        end
    elseif resetOptions == ZO_MapPin.ANIM_CONSTANTS.RESET_ANIM_HIDE_CONTROL then
        ZO_AlphaAnimation_GetAnimation(pulseControl):Stop()
        pulseControl:SetHidden(true)
        self:StopTextureAnimation()
    elseif resetOptions == ZO_MapPin.ANIM_CONSTANTS.RESET_ANIM_PREVENT_PLAY then
        ZO_AlphaAnimation_GetAnimation(pulseControl):FadeOut(0, 300, ZO_ALPHA_ANIMATION_OPTION_USE_CURRENT_ALPHA, ZO_MapPin.HidePulseAfterFadeOut)
    end
end

-- Simple utility to just ping a map pin
function ZO_MapPin:PingMapPin(animation)
    if animation.type == ZO_MapPin.ANIMATION_ALPHA then
        self:ResetAnimation(ZO_MapPin.ANIM_CONSTANTS.RESET_ANIM_ALLOW_PLAY, animation.duration, animation.texture)
    end
end

function ZO_MapPin:FadeInMapPin()
    local fadeInAnimation = ZO_WorldMap_GetPinManager():AcquirePinFadeInAnimation()

    local pinAnimation = fadeInAnimation:GetAnimation(1)
    local pinControl = self:GetControl()
    pinAnimation:SetAnimatedControl(pinControl)

    local areaControl = self.pinBlob
    if areaControl == nil then
        areaControl = self.polygonBlob
    end

    if areaControl then
        local areaAnimation = fadeInAnimation:GetAnimation(2)
        areaAnimation:SetAnimatedControl(areaControl)
    end

    PlaySound(SOUNDS.MAP_PIN_FADEIN)
    fadeInAnimation:PlayFromStart()
end

function ZO_MapPin:GetPinId()
    return self.pinId
end

function ZO_MapPin:GetPinType()
    return self.m_PinType
end

function ZO_MapPin:GetPinTypeAndTag()
    return self.m_PinType, self.m_PinTag
end

function ZO_MapPin:SetQuestIndex(newQuestIndex)
    if type(self.m_PinTag) == "table" then
        self.m_PinTag[1] = newQuestIndex
    end
end

function ZO_MapPin:GetQuestIndex()
    if self:IsQuest() then
        return self.m_PinTag[1]
    end

    -- an invalid quest index that isn't nil, in case something actually decides to pass nil
    -- questIndex to a function that queries this pin.
    return -1
end

function ZO_MapPin:IsObjective()
    return ZO_MapPin.OBJECTIVE_PIN_TYPES[self.m_PinType] or ZO_MapPin.SPAWN_OBJECTIVE_PIN_TYPES[self.m_PinType] or ZO_MapPin.RETURN_OBJECTIVE_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsAvAObjective()
    return self:IsObjective() and not IsBattlegroundObjective(self:GetObjectiveKeepId(), self:GetObjectiveObjectiveId(), self:GetBattlegroundContext())
end

function ZO_MapPin:IsBattlegroundObjective()
    return self:IsObjective() and IsBattlegroundObjective(self:GetObjectiveKeepId(), self:GetObjectiveObjectiveId(), self:GetBattlegroundContext())
end

function ZO_MapPin:IsKeep()
    return ZO_MapPin.KEEP_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsDistrict()
    return ZO_MapPin.DISTRICT_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsKeepOrDistrict()
    return self:IsKeep() or self:IsDistrict()
end

function ZO_MapPin:IsUnit()
    return ZO_MapPin.UNIT_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsGroup()
    return ZO_MapPin.GROUP_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsQuest()
    return ZO_MapPin.QUEST_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsPOI()
    return ZO_MapPin.POI_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsAssisted()
    return ZO_MapPin.ASSISTED_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsMapPing()
    return ZO_MapPin.MAP_PING_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsKillLocation()
    return ZO_MapPin.KILL_LOCATION_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsFastTravelKeep()
    return ZO_MapPin.FAST_TRAVEL_KEEP_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsFastTravelWayShrine()
    return ZO_MapPin.FAST_TRAVEL_WAYSHRINE_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsForwardCamp()
    return ZO_MapPin.FORWARD_CAMP_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsAvARespawn()
    return ZO_MapPin.AVA_RESPAWN_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsRestrictedLink()
    return ZO_MapPin.AVA_RESTRICTED_LINK_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsWorldEventPOIPin()
   return ZO_MapPin.WORLD_EVENT_POI_PIN_TYPES[self.m_PinType] 
end

function ZO_MapPin:IsWorldEventUnitPin()
   return ZO_MapPin.WORLD_EVENT_UNIT_PIN_TYPES[self.m_PinType] 
end

function ZO_MapPin:IsAntiquityDigSitePin()
   return self.m_PinType == MAP_PIN_TYPE_ANTIQUITY_DIG_SITE or self.m_PinType == MAP_PIN_TYPE_TRACKED_ANTIQUITY_DIG_SITE
end

function ZO_MapPin:IsCompanion()
    return self.m_PinType == MAP_PIN_TYPE_ACTIVE_COMPANION
end

function ZO_MapPin:IsSkyshard()
    return ZO_MapPin.SKYSHARD_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsZoneStory()
    return self.m_PinTag.isZoneStory
end

function ZO_MapPin:IsSuggestion()
    return ZO_MapPin.SUGGESTION_PIN_TYPES[self.m_PinType]
end

function ZO_MapPin:IsImperialCityPin()
    return self:IsAvARespawn() or self:IsDistrict()
end

function ZO_MapPin:IsCyrodiilPin()
    return self:IsAvAObjective() or self:IsAvARespawn() or self:IsForwardCamp() or self:IsFastTravelKeep() or self:IsKeep()
end

function ZO_MapPin:IsAvAPin()
    return self:IsImperialCityPin() or self:IsCyrodiilPin()
end

function ZO_MapPin:IsBattlegroundPin()
    return self:IsBattlegroundObjective()
end

function ZO_MapPin:IsAreaPin()
    return self.pinBlob ~= nil
end

function ZO_MapPin:IsPublicDungeonPin()
    local poiType = self:GetPOIType()
    
    return poiType == POI_TYPE_PUBLIC_DUNGEON
end

function ZO_MapPin:IsDelvePin()
    local poiIndex = self:GetPOIIndex()
    local zoneIndex = self:GetPOIZoneIndex()
    local zoneCompletionType = GetPOIZoneCompletionType(zoneIndex, poiIndex)
    
    return zoneCompletionType == ZONE_COMPLETION_TYPE_DELVES or zoneCompletionType == ZONE_COMPLETION_TYPE_GROUP_DELVES
end

function ZO_MapPin:ShowsPinAndArea()
    local singlePinData = ZO_MapPin.PIN_DATA[self.m_PinType]
    return singlePinData.showsPinAndArea
end

function ZO_MapPin:ShouldShowPin()
    local singlePinData = ZO_MapPin.PIN_DATA[self.m_PinType]
    local showsArea = self.radius and self.radius > 0
    return (not showsArea or singlePinData.showsPinAndArea) and not self.polygonBlob
end

function ZO_MapPin:GetQuestData()
    if ZO_MapPin.QUEST_PIN_TYPES[self.m_PinType] then
        -- returns index, step, condition
        return self.m_PinTag[1], self.m_PinTag[3], self.m_PinTag[2]
    end

    -- Invalid quest data that isn't nil, in case something actually decides to pass nil
    -- quest data to a function that queries this pin.
    return -1, -1, -1
end

function ZO_MapPin:DoesQuestDataMatchQuestPingData()
    local questPingData = ZO_WorldMap_GetQuestPingData()
    if questPingData then
        -- Quest tags store indices as questIndex, conditionIndex, stepIndex
        if questPingData.questIndex == self.m_PinTag[1] then
            local hasMatchingStepIndex = questPingData.stepIndex == nil or questPingData.stepIndex == self.m_PinTag[3]
            local hasMatchingConditionIndex = questPingData.conditionIndex == nil or questPingData.conditionIndex == self.m_PinTag[2]
            return hasMatchingStepIndex and hasMatchingConditionIndex
        end
    end
    return false
end

function ZO_MapPin:ValidatePvPPinAllowed()
    local mapContentType = GetMapContentType()
    if self:IsAvAPin() then
        if mapContentType == MAP_CONTENT_AVA then
            local currentMapIndex = GetCurrentMapIndex()
            if currentMapIndex == GetCyrodiilMapIndex() then
                return self:IsCyrodiilPin()
            elseif currentMapIndex == GetImperialCityMapIndex() then
                return self:IsImperialCityPin()
            end
        end
        return false
    elseif self:IsBattlegroundPin() then
        return mapContentType == MAP_CONTENT_BATTLEGROUND
    end
    return true
end

function ZO_MapPin:GetShortDescription()
    if self:IsZoneStory() then
        return GetZoneStoryShortDescriptionByActivityId(self:GetZoneStoryZoneId(), self:GetZoneCompletionType(), self:GetZoneStoryActivityId())
    elseif self:GetPinType() == MAP_PIN_TYPE_POI_SUGGESTED or self:GetPinType() == MAP_PIN_TYPE_SKYSHARD_SUGGESTED then
        -- currently SUGGESTED pins are only used by zone story and only for the currently tracked activity
        -- in the future we may need to check what system is adding this pin and adjust accordingly
        local zoneId, zoneCompletionType, activityId = GetTrackedZoneStoryActivityInfo()
        return GetZoneStoryShortDescriptionByActivityId(zoneId, zoneCompletionType, activityId)
    end
    return nil
end

do
    local questPinTextures =
    {
        [MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION] = "EsoUI/Art/Compass/quest_icon_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/quest_icon_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_ENDING] = "EsoUI/Art/Compass/quest_icon_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_ENDING] = "EsoUI/Art/Compass/repeatableQuest_icon_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_ENDING] = "EsoUI/Art/Compass/zoneStoryQuest_icon_assisted.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_CONDITION] = "EsoUI/Art/Compass/quest_icon.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/quest_icon.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_ENDING] = "EsoUI/Art/Compass/quest_icon.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_ENDING] = "EsoUI/Art/Compass/repeatableQuest_icon.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_ENDING] = "EsoUI/Art/Compass/zoneStoryQuest_icon.dds",
        [MAP_PIN_TYPE_QUEST_CONDITION] = "EsoUI/Art/Compass/quest_icon.dds",
        [MAP_PIN_TYPE_QUEST_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/quest_icon.dds",
        [MAP_PIN_TYPE_QUEST_ENDING] = "EsoUI/Art/Compass/quest_icon.dds",
        [MAP_PIN_TYPE_QUEST_REPEATABLE_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon.dds",
        [MAP_PIN_TYPE_QUEST_REPEATABLE_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon.dds",
        [MAP_PIN_TYPE_QUEST_REPEATABLE_ENDING] = "EsoUI/Art/Compass/repeatableQuest_icon.dds",
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon.dds",
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon.dds",
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_ENDING] = "EsoUI/Art/Compass/zoneStoryQuest_icon.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_OFFER_ZONE_STORY] = "EsoUI/Art/Compass/zoneStoryQuest_available_icon.dds",
    }

    local breadcrumbQuestPinTextures =
    {
        [MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION] = "EsoUI/Art/Compass/quest_icon_door_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/quest_icon_door_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_ENDING] = "EsoUI/Art/Compass/quest_icon_door_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon_door_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon_door_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_ENDING] = "EsoUI/Art/Compass/repeatableQuest_icon_door_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon_door_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon_door_assisted.dds",
        [MAP_PIN_TYPE_ASSISTED_QUEST_ZONE_STORY_ENDING] = "EsoUI/Art/Compass/zoneStoryQuest_icon_door_assisted.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_CONDITION] = "EsoUI/Art/Compass/quest_icon_door.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/quest_icon_door.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_ENDING] = "EsoUI/Art/Compass/quest_icon_door.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon_door.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon_door.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_ENDING] = "EsoUI/Art/Compass/repeatableQuest_icon_door.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon_door.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon_door.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_ZONE_STORY_ENDING] = "EsoUI/Art/Compass/zoneStoryQuest_icon_door.dds",
        [MAP_PIN_TYPE_QUEST_CONDITION] = "EsoUI/Art/Compass/quest_icon_door.dds",
        [MAP_PIN_TYPE_QUEST_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/quest_icon_door.dds",
        [MAP_PIN_TYPE_QUEST_ENDING] = "EsoUI/Art/Compass/quest_icon_door.dds",
        [MAP_PIN_TYPE_QUEST_REPEATABLE_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon_door.dds",
        [MAP_PIN_TYPE_QUEST_REPEATABLE_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/repeatableQuest_icon_door.dds",
        [MAP_PIN_TYPE_QUEST_REPEATABLE_ENDING] = "EsoUI/Art/Compass/repeatableQuest_icon_door.dds",
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon_door.dds",
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_OPTIONAL_CONDITION] = "EsoUI/Art/Compass/zoneStoryQuest_icon_door.dds",
        [MAP_PIN_TYPE_QUEST_ZONE_STORY_ENDING] = "EsoUI/Art/Compass/zoneStoryQuest_icon_door.dds",
        [MAP_PIN_TYPE_TRACKED_QUEST_OFFER_ZONE_STORY] = "EsoUI/Art/Compass/zoneStoryQuest_available_icon_door.dds",
    }
    
    function ZO_MapPin:GetQuestIcon()
        if self.m_PinTag.isBreadcrumb then
            return breadcrumbQuestPinTextures[self:GetPinType()]
        else
            return questPinTextures[self:GetPinType()]
        end
    end
end

do
    local groupPinTextures =
    {
        [MAP_PIN_TYPE_GROUP_LEADER]                                 = "EsoUI/Art/Compass/groupLeader.dds",
        [MAP_PIN_TYPE_GROUP]                                        = "EsoUI/Art/MapPins/UI-WorldMapGroupPip.dds",
    }

    local breadcrumbGroupPinTextures =
    {
        [MAP_PIN_TYPE_GROUP_LEADER]                                 = "EsoUI/Art/Compass/groupLeader_door.dds",
        [MAP_PIN_TYPE_GROUP]                                        = "EsoUI/Art/Compass/groupMember_door.dds",
    }

    function ZO_MapPin:GetGroupIcon()
        if self.m_PinTag.isBreadcrumb then
            return breadcrumbGroupPinTextures[self:GetPinType()]
        else
            return groupPinTextures[self:GetPinType()]
        end
    end
end

function ZO_MapPin:GetNumAllianceKills(alliance)
    if not self:IsKillLocation() then
        return 0
    end

    local killLocationIndex = self.m_PinTag
    local numAllianceKills = GetNumKillLocationAllianceKills(killLocationIndex, alliance)
    return numAllianceKills
end

function ZO_MapPin:GetPOIIndex()
    if self:IsPOI() or self.m_PinType == MAP_PIN_TYPE_POI_SUGGESTED then
        return self.m_PinTag[2]
    elseif self:IsWorldEventPOIPin() then
        return self.m_PinTag[3]
    end

    -- an invalid POI index that isn't nil, in case something actually decides to pass a nil
    -- POI index to a function that queries this pin.
    return -1
end

function ZO_MapPin:GetPOIZoneIndex()
    if self:IsPOI() or self.m_PinType == MAP_PIN_TYPE_POI_SUGGESTED then
        return self.m_PinTag[1]
    elseif self:IsWorldEventPOIPin() then
        return self.m_PinTag[2]
    end

    -- an invalid POI index that isn't nil, in case something actually decides to pass a nil
    -- POI index to a function that queries this pin.
    return -1
end

function ZO_MapPin:GetPOIIcon()
    if self:IsPOI() or self.m_PinType == MAP_PIN_TYPE_POI_SUGGESTED then
        return self.m_PinTag[3]
    end

    -- an invalid POI icon that isn't nil
    return ""
end

function ZO_MapPin:IsLocation()
    return self.m_PinType == MAP_PIN_TYPE_LOCATION
end

function ZO_MapPin:GetLocationIndex()
    if self.m_PinType == MAP_PIN_TYPE_LOCATION then
        return self.m_PinTag[1]
    end

    -- Invalid location index
    return -1
end

function ZO_MapPin:GetLocationIcon()
    if self.m_PinType == MAP_PIN_TYPE_LOCATION then
        return self.m_PinTag[2]
    end

    -- Empty icon string
    return ""
end

function ZO_MapPin:GetWorldEventPOIIcon()
    if self.m_PinType == MAP_PIN_TYPE_WORLD_EVENT_POI_ACTIVE then
        local zoneIndex = self:GetPOIZoneIndex()
        local poiIndex = self:GetPOIIndex()
        local poiPinType = select(3, GetPOIMapInfo(zoneIndex, poiIndex))
        if poiPinType == MAP_PIN_TYPE_POI_COMPLETE then
            return "EsoUI/Art/MapPins/worldEvent_poi_active_complete.dds"
        elseif poiPinType == MAP_PIN_TYPE_POI_SEEN then
            return "EsoUI/Art/MapPins/worldEvent_poi_active_incomplete.dds"
        end
    end

    -- Empty icon string
    return ""
end

function ZO_MapPin:GetFastTravelIcons()
    if self:IsFastTravelWayShrine() then
        local glow
        if not self:IsLockedByLinkedCollectible() then
            glow = self.m_PinTag[3]
        end
        return self.m_PinTag[2], nil, glow
    end

    -- Empty icon string
    return ""
end

function ZO_MapPin:GetFastTravelDrawLevel()
    if self:IsFastTravelWayShrine() then
        local nodeIndex = self:GetFastTravelNodeIndex()
        return CONSTANTS.FAST_TRAVEL_DEFAULT_PIN_LEVEL + GetFastTravelNodeDrawLevelOffset(nodeIndex)
    end

    return 0
end

function ZO_MapPin:GetUnitTag()
    if self:IsUnit() or self:IsMapPing() then
        if self:IsUnit() and not (type(self.m_PinTag) == "string") then
            return self.m_PinTag.groupTag
        else
            return self.m_PinTag
        end
    elseif self:IsWorldEventUnitPin() then
        return self.m_PinTag[2]
    end

    -- An invalid UnitTag that isn't nil, in case something actually decides to pass a nil
    -- UnitTag to a function that queries this pin.
    return ""
end

function ZO_MapPin:GetObjectiveKeepId()
    if self:IsObjective() then
        return self.m_PinTag[1]
    end
end

function ZO_MapPin:GetObjectiveObjectiveId()
    if self:IsObjective() then
        return self.m_PinTag[2]
    end
end

function ZO_MapPin:GetKeepId()
    if self:IsKeepOrDistrict() then
        return self.m_PinTag[1]
    end
end

function ZO_MapPin:IsUnderAttackPin()
    if self:IsKeepOrDistrict() then
        return self.m_PinTag[3]
    end
    return false
end

function ZO_MapPin:GetFastTravelKeepId()
    if self:IsFastTravelKeep() then
        return self.m_PinTag[1]
    end
end

function ZO_MapPin:GetSkyshardId()
    if self:IsSkyshard() then
        return self.m_PinTag[1]
    end
end

function ZO_MapPin:IsLockedByLinkedCollectible()
    if self:IsPOI() or self:IsFastTravelWayShrine() then
        return self.m_PinTag[4]
    end
    return false
end

function ZO_MapPin:GetLinkedCollectibleData()
    if self:IsFastTravelWayShrine() then
        local collectibleId = GetFastTravelNodeLinkedCollectibleId(self:GetFastTravelNodeIndex())
        -- Will either be an override collectible, the passed in id, or 0 if it cannot be purchased
        local purchasableCollectibleId = GetPurchasableCollectibleIdForCollectible(collectibleId)
        local relevantCollectibleId = purchasableCollectibleId ~= 0 and purchasableCollectibleId or collectibleId
        local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(relevantCollectibleId)
        return collectibleData
    end
    -- TODO: Handle if self:IsPOI()?
    return nil
end

function ZO_MapPin:GetLinkedCollectibleType()
    local collectibleData = self:GetLinkedCollectibleData()
    if collectibleData then
        return collectibleData:GetCategoryType()
    end
    return COLLECTIBLE_CATEGORY_TYPE_DLC
end

function ZO_MapPin:GetLockedByLinkedCollectibleInteractString()
    if self:GetLinkedCollectibleType() == COLLECTIBLE_CATEGORY_TYPE_CHAPTER then
        return GetString(SI_WORLD_MAP_ACTION_UPGRADE_CHAPTER)
    else
        return GetString(SI_WORLD_MAP_ACTION_GO_TO_CROWN_STORE)
    end
end

function ZO_MapPin:GetBattlegroundContext()
    if self:IsKeepOrDistrict() then
        return self.m_PinTag[2]
    elseif self:IsObjective() then
        return self.m_PinTag[3]
    elseif self:IsRestrictedLink() then
        return self.m_PinTag[2]
    end
end

function ZO_MapPin:GetRestrictedAlliance()
    if self:IsRestrictedLink() then
        return self.m_PinTag[1]
    end
end

function ZO_MapPin:GetFastTravelCost()
    if self:IsFastTravelKeep() then
        local keepId = self:GetFastTravelKeepId()
        local bgContext =  ZO_WorldMap_GetBattlegroundQueryType()
        return 0, CanKeepBeFastTravelledTo(keepId, bgContext)
    elseif self:IsKeepOrDistrict() then
        local keepId = self:GetKeepId()
        local bgContext =  ZO_WorldMap_GetBattlegroundQueryType()
        return 0, CanKeepBeFastTravelledTo(keepId, bgContext)
    elseif self:IsFastTravelWayShrine() then
        local nodeIndex = self:GetFastTravelNodeIndex()
        local isCurrentLoc = (ZO_Map_GetFastTravelNode() == nodeIndex)

        if isCurrentLoc then
            -- Already at the wayshrine.
            return 0, false
        elseif ZO_Map_GetFastTravelNode() == nil then --recall
            if IsInCampaign() then
                -- Cannot recall while in AVA.
                return 0, false
            else
                local _, premiumTimeLeft = GetRecallCooldown()
                if premiumTimeLeft == 0 then
                    -- Costs money.
                    local travelCost = GetRecallCost(nodeIndex)
                    local travelCurrency = GetRecallCurrency(nodeIndex)
                    return travelCost, (travelCost <= GetCurrencyAmount(travelCurrency, CURRENCY_LOCATION_CHARACTER))
                else
                    -- Must wait for recall cool-down.
                    return 0, false
                end
            end
        else
            -- Can always travel between wayshrines
            return 0, true
        end
    end
end

function ZO_MapPin:IsForwardCampUsable()
    local _, _, _, _, usable = GetForwardCampPinInfo(ZO_WorldMap_GetBattlegroundQueryType(), self:GetForwardCampIndex())
    return usable
end

function ZO_MapPin:GetFastTravelNodeIndex()
    if self:IsFastTravelWayShrine() then
        return self.m_PinTag[1]
    end
end

function ZO_MapPin:GetPOIType()
    local zoneIndex, poiIndex
    if self:IsFastTravelWayShrine() then
        local poiType = select(7, GetFastTravelNodeInfo(self:GetFastTravelNodeIndex()))
        return poiType
    else
        local zoneIndex = self:GetPOIZoneIndex()
        local poiIndex = self:GetPOIIndex()
        return GetPOIType(zoneIndex, poiIndex)
    end
end

function ZO_MapPin:GetForwardCampIndex()
    if self:IsForwardCamp() then
        return self.m_PinTag[1]
    end
end

function ZO_MapPin:GetAvARespawnId()
    if self:IsAvARespawn() then
        return self.m_PinTag[1]
    end
end

function ZO_MapPin:GetZoneStoryZoneId()
    if self:IsZoneStory() then
        return self.m_PinTag[1]
    end
end

function ZO_MapPin:GetZoneCompletionType()
    if self:IsZoneStory() then
        return self.m_PinTag[2]
    end
end

function ZO_MapPin:GetZoneStoryActivityId()
    if self:IsZoneStory() then
        return self.m_PinTag[3]
    end
end

function ZO_MapPin:GetWorldEventInstanceId()
    if self:IsWorldEventUnitPin() or self:IsWorldEventPOIPin() then
        return self.m_PinTag[1]
    end
end

function ZO_MapPin:GetWorldEventUnitIcon()
    if self:IsWorldEventUnitPin() then
        local worldEventInstanceId = self.m_PinTag[1]
        local unitTag = self.m_PinTag[2]
        local REQUEST_ANIMATED_TEXTURE = false
        return GetWorldEventInstanceUnitPinIcon(worldEventInstanceId, unitTag, REQUEST_ANIMATED_TEXTURE)
    end
end

function ZO_MapPin:GetIsWorldEventUnitIconAnimated()
    if self:IsWorldEventUnitPin() then
        local worldEventInstanceId = self.m_PinTag[1]
        local unitTag = self.m_PinTag[2]
        return GetIsWorldEventInstanceUnitPinIconAnimated(worldEventInstanceId, unitTag)
    end
end

function ZO_MapPin:GetAntiquityDigSiteId()
    if self:IsAntiquityDigSitePin() then
        return self.m_PinTag[1]
    end
end

function ZO_MapPin:GetControl()
    return self.m_Control
end

function ZO_MapPin:SetHidden(hidden)
    return self.m_Control:SetHidden(hidden)
end

function ZO_MapPin:GetLevel()
    if self.m_PinType then
        local singlePinData = ZO_MapPin.PIN_DATA[self.m_PinType]
        if singlePinData.mouseLevel then
            return singlePinData.mouseLevel
        end
        if singlePinData.level then
            if type(singlePinData.level) == "function" then
                return singlePinData.level(self)
            else
                return singlePinData.level
            end
        end
    end

    return 0
end

function ZO_MapPin:GetBlobPinControl()
    return self.pinBlob
end

function ZO_MapPin:MouseIsOver(positionX, positionY)
    local control = self:GetControl()
    if not control:IsHidden() then
        if self.polygonBlob then
            return self.polygonBlob:IsPointInside(positionX, positionY)
        else
            return control:IsPointInside(positionX, positionY)
        end
    end
    return false
end

function ZO_MapPin:NeedsContinuousTooltipUpdates()
    if ZO_WorldMap_IsWorldMapInfoShowing() then
        return false -- Turn off Continuous updates while world map info is showing
    end

    if self:IsFastTravelWayShrine() then
        local cooldownRemaining, premiumTimeLeft = GetRecallCooldown()
        if cooldownRemaining > 0 then
            return true
        end
    end

    if IsInGamepadPreferredMode() and ZO_WorldMapCenterPoint:IsHidden() then
        return false -- Turn off Continuous updates if there is no center point
    end

    return false
end

do
    function ZO_MapPin:UpdateSize()
        local singlePinData = ZO_MapPin.PIN_DATA[self.m_PinType]
        if singlePinData ~= nil then
            -- There are two passes on setting the size...it could also be set when SetLocation is called because that takes a pin radius.
            local control = self:GetControl()
            local hasNonZeroRadius = self.radius and self.radius > 0
            local baseSize = singlePinData.size or CONSTANTS.DEFAULT_PIN_SIZE

            local mapWidth, mapHeight = ZO_WorldMap_GetMapDimensions()

            if hasNonZeroRadius then
                local pinDiameter = self.radius * 2 * mapHeight

                if singlePinData.minAreaSize and pinDiameter < singlePinData.minAreaSize then
                    pinDiameter = singlePinData.minAreaSize
                end

                control:SetShapeType(SHAPE_CIRCLE)
                control:SetDimensions(pinDiameter, pinDiameter)

                if self.pinBlob then
                    self:UpdateAreaPinTexture()
                    self.pinBlob:SetDimensions(pinDiameter, pinDiameter)
                    control:SetHitInsets(0, 0, 0, 0)
                end
            end

            if self.polygonBlob then
                local width = self.borderInformation.borderWidth * mapWidth
                local height = self.borderInformation.borderHeight * mapHeight
                self.polygonBlob:SetDimensions(width, height)

                local centerColor = self:GetCenterColor()
                local r, g, b = centerColor:UnpackRGB()
                local alpha = 0.39
                self.polygonBlob:SetCenterColor(r, g, b, alpha)

                local borderColor = self:GetBorderColor()
                self.polygonBlob:SetBorderColor(borderColor:UnpackRGBA())
            end

            if self:ShouldShowPin() then
                --We scale the pin based on the map scale. However, we try to prevent it from becoming too small to be useful. First, we bound it on the lower end by a percentage of its
                --full size. This is to preserve relative sizes between the pins. Second, we bound it by an absolute size to prevent any pin from getting smaller than that size,
                --because any pin that small is unreadable. A pin may specify its own min size as well.
                local minSize = singlePinData.minSize or CONSTANTS.MIN_PIN_SIZE
                local scale = zo_clamp(ZO_WorldMap_GetPanAndZoom():GetCurrentCurvedZoom(), CONSTANTS.MIN_PIN_SCALE, CONSTANTS.MAX_PIN_SCALE)
                local size = zo_max((baseSize * scale) / GetUICustomScale(), minSize)

                control:SetDimensions(size, size)

                --rescale the insets based on the pin size
                --insetX/insetY maintained for backwards compatability with addons
                local hitInsetX = singlePinData.hitInsetX or singlePinData.insetX or 0
                local hitInsetY = singlePinData.hitInsetY or singlePinData.insetY or 0
                hitInsetX = hitInsetX * (size / baseSize)
                hitInsetY = hitInsetY * (size / baseSize)

                control:SetHitInsets(hitInsetX, hitInsetY, -hitInsetX, -hitInsetY)
            end
        end
    end

    function ZO_MapPin:ChangePinType(pinType)
        self:SetData(pinType, self.m_PinTag)
        self:SetLocation(self.normalizedX, self.normalizedY, self.radius)
    end

    local function GetPinTextureData(self, textureData)
        if type(textureData) == "string" then
            return textureData
        elseif type(textureData) == "function" then
            return textureData(self)
        end
    end

    local function GetPinTextureColor(self, textureColor)
        if type(textureColor) == "function" then
            return textureColor(self)
        end
        return textureColor
    end

    local function IsPinAnimated(self, isAnimated)
        if type(isAnimated) == "boolean" then
            return isAnimated
        elseif type(isAnimated) == "function" then
            return isAnimated(self)
        end
    end

    function ZO_MapPin.GetStaticPinTexture(pinType)
        local singlePinData = ZO_MapPin.PIN_DATA[pinType]
        if singlePinData then
            if type(singlePinData.texture) == "string" then
                return singlePinData.texture
            end
        end
    end

    function ZO_MapPin:SetData(pinType, pinTag)
        self:ClearData()
        self.m_PinType = pinType
        self.m_PinTag = pinTag

        if type(pinTag) == "string" and ZO_Group_IsGroupUnitTag(pinTag) then
            pinTag = "group"
        end

        self.labelControl:SetText("")

        local singlePinData = ZO_MapPin.PIN_DATA[pinType]
        if singlePinData ~= nil then
            -- Set up texture
            local overlayTexture, pulseTexture, glowTexture = GetPinTextureData(self, singlePinData.texture)

            if overlayTexture ~= "" then
                self.backgroundControl:SetTexture(overlayTexture)
            end

            if pulseTexture then
                self:ResetAnimation(ZO_MapPin.ANIM_CONSTANTS.RESET_ANIM_ALLOW_PLAY, ZO_MapPin.ANIM_CONSTANTS.LONG_LOOP_COUNT, pulseTexture, overlayTexture, ZO_MapPin.DoFinalFadeInAfterPing)
            elseif glowTexture then
                self:ResetAnimation(ZO_MapPin.ANIM_CONSTANTS.RESET_ANIM_HIDE_CONTROL)
                self.highlightControl:SetHidden(false)
                self.highlightControl:SetAlpha(1)
                self.highlightControl:SetTexture(glowTexture)
            else
                self.highlightControl:SetHidden(true)
            end

            local level = singlePinData.level
            if type(level) == "function" then
                level = level(self)
            end

            local pinLevel = zo_max(level, 1)

            --if the pin doesn't have click behavior, push the mouse enable control down so it doesn't eat clicks
            if ZO_MapPin.PIN_CLICK_HANDLERS[MOUSE_BUTTON_INDEX_LEFT][self.m_PinType] or ZO_MapPin.PIN_CLICK_HANDLERS[MOUSE_BUTTON_INDEX_RIGHT][self.m_PinType] then
                self.m_Control:SetDrawLevel(pinLevel)
            else
                self.m_Control:SetDrawLevel(0)
            end

            self.backgroundControl:SetDrawLevel(pinLevel)
            self.highlightControl:SetDrawLevel(pinLevel - 1)
            self.labelControl:SetDrawLevel(pinLevel + 1)

            if IsPinAnimated(self, singlePinData.isAnimated) then
                self:PlayTextureAnimation(singlePinData.framesWide, singlePinData.framesHigh, singlePinData.framesPerSecond)
            end

            if singlePinData.tint then
                local tint = GetPinTextureColor(self, singlePinData.tint)
                if tint then
                    self.backgroundControl:SetColor(tint:UnpackRGBA())
                end
            else
                self.backgroundControl:SetColor(1, 1, 1, 1)
            end
        end
        self:BuildDependencies()
    end
end

function ZO_MapPin:ClearData()
    self:CleanUpDependencies()
    self.m_PinType = nil
    self.m_PinTag = nil
end

function ZO_MapPin:ResetScale(maintainScaleModifier)
    self.targetScale = nil
    if not maintainScaleModifier then
        self.scaleModifier = 1
    end
    self.m_Control:SetScale(1 * self.scaleModifier)
    self.m_Control:SetHandler("OnUpdate", nil)
    if self.scaleChildren then
        for childPin, _ in pairs(self.scaleChildren) do
            childPin:ResetScale()
        end
    end
end

function ZO_MapPin:UpdateLocation()
    local myControl = self:GetControl()
    if self.normalizedX and self.normalizedY then
        local mapWidth, mapHeight = ZO_WorldMap_GetMapDimensions()
        local offsetX = self.originalNormalizedX * mapWidth
        local offsetY = self.originalNormalizedY * mapHeight

        -- The overlap offset spaces out the symbolic pin that are otherwise
        -- all stacked together in the center of the symbolic blob.
        if self:IsSymbolicPosition() then
            if self.overlapOffsetX and self.overlapOffsetX ~= 0 then
                offsetX = offsetX + self.overlapOffsetX
            end
            if self.overlapOffsetY and self.overlapOffsetY ~= 0 then
                offsetY = offsetY + self.overlapOffsetY
            end
        end
        -- Map navigation, particularly for gamepad, does all it's positional
        -- math based on the normalized position of the pin so the normalized
        -- position must be adjusted to be consistent with the symbolic offset
        -- it was given.
        self.normalizedX = offsetX / mapWidth
        self.normalizedY = offsetY / mapHeight

        myControl:ClearAnchors()
        myControl:SetAnchor(CENTER, nil, TOPLEFT, offsetX, offsetY)
        if self.pinBlob then
            self.pinBlob:ClearAnchors()
            self.pinBlob:SetAnchor(CENTER, nil, TOPLEFT, offsetX, offsetY)
        end
        if self.polygonBlob then
            self.polygonBlob:ClearAnchors()
            self.polygonBlob:SetAnchor(CENTER, nil, TOPLEFT, offsetX, offsetY)
        end
    end
end

function ZO_MapPin:GetCenter()
    return self:GetControl():GetCenter()
end

function ZO_MapPin:DistanceToSq(x, y)
    local centerX, centerY = self:GetCenter()

    local dx = x - centerX
    local dy = y - centerY
    return dx * dx + dy * dy
end

function ZO_MapPin:GetPinGroup()
    return ZO_MapPin.PIN_TYPE_TO_PIN_GROUP[self.m_PinType]
end

function ZO_MapPin:GetCenterColor()
    if self:IsAssisted() then
        return ZO_MAP_PIN_ASSISTED_COLOR
    elseif self.m_PinType == MAP_PIN_TYPE_ANTIQUITY_DIG_SITE then
        return ZO_MAP_PIN_DIG_SITE_COLOR
    elseif self.m_PinType == MAP_PIN_TYPE_TRACKED_ANTIQUITY_DIG_SITE then
        return ZO_MAP_PIN_TRACKED_DIG_SITE_COLOR
    else
        return ZO_MAP_PIN_NORMAL_COLOR
    end
end

function ZO_MapPin:GetBorderColor()
    if self:IsAntiquityDigSitePin() then
        return ZO_MAP_PIN_DIG_SITE_BORDER_COLOR
    else
        return ZO_MAP_PIN_NORMAL_COLOR
    end
end

function ZO_MapPin:UpdateAreaPinTexture()
    if self.pinBlob then
        local color = self:GetCenterColor()
        self.pinBlob:SetColor(color:UnpackRGBA())
    end
end

function ZO_MapPin:IsLocationValid()
    return self.validLocation
end

function ZO_MapPin:SetLocation(xLoc, yLoc, radius, borderInformation)
    local valid = xLoc and yLoc and ZO_WorldMap_IsNormalizedPointInsideMapBounds(xLoc, yLoc)

    local myControl = self:GetControl()
    myControl:SetHidden(not valid)

    -- Original normalize position is used for determining the proper offset
    -- and subsequent symbolic offset from which the normalize position will
    -- need to be adjusted.
    self.originalNormalizedX = xLoc
    self.originalNormalizedY = yLoc
    self.normalizedX = xLoc
    self.normalizedY = yLoc
    self.radius = radius
    self.borderInformation = borderInformation
    self.validLocation = valid

    if valid then
        if radius and radius > 0 then
            if not self:IsKeepOrDistrict() then
                if not self.pinBlob then
                    self.pinBlob, self.pinBlobKey = ZO_WorldMap_GetPinManager():AcquirePinBlob()
                end
                self.pinBlob:SetHidden(false)
            end
        elseif borderInformation then
            if not self.polygonBlob then
                self.polygonBlob, self.polygonBlobKey = ZO_WorldMap_GetPinManager():AcquirePinPolygonBlob()
                self.polygonBlob:SetHandler("OnMouseUp", function(control, ...)
                    zo_callHandler(myControl, "OnMouseUp", ...)
                end)
                self.polygonBlob:SetHandler("OnMouseDown", function(control, ...)
                    zo_callHandler(myControl, "OnMouseDown", ...)
                end)
            end
            self.polygonBlob:SetHidden(false)
            self.polygonBlob:ClearPoints()
            for i, point in ipairs(borderInformation.borderPoints) do
                self.polygonBlob:AddPoint(point.x, point.y)
            end
        end

        self.backgroundControl:SetHidden(not self:ShouldShowPin())

        self:UpdateSize()
        self:UpdateLocation()
    end
end

function ZO_MapPin:IsSymbolicPosition()
    return self.symbolicPosition
end

function ZO_MapPin:SetIsSymbolicPosition(isSymbolicPosition)
    self.symbolicPosition = isSymbolicPosition
end

function ZO_MapPin:GetOriginalPosition()
    return self.originalX, self.originalY
end

function ZO_MapPin:SetOriginalPosition(xLoc, yLoc)
    self.originalX = xLoc
    self.originalY = yLoc
end

function ZO_MapPin:SetOverlapOffsets(xOffset, yOffset)
    self.overlapOffsetX = xOffset
    self.overlapOffsetY = yOffset
end

function ZO_MapPin:SetRotation(angle)
    self.backgroundControl:SetTextureRotation(angle)
end

function ZO_MapPin:GetNormalizedPosition()
    return self.normalizedX, self.normalizedY
end

function ZO_MapPin:SetTargetScale(targetScale)
    if (self.targetScale ~= nil and targetScale ~= self.targetScale) or (self.targetScale == nil and targetScale ~= self.m_Control:GetScale()) then
        self.targetScale = targetScale

        self.m_Control:SetHandler("OnUpdate", function(control)
            local newScale = zo_deltaNormalizedLerp(control:GetScale(), self.targetScale * self.scaleModifier, 0.17)
            if zo_abs(newScale - self.targetScale) < 0.01 then
                control:SetScale(self.targetScale * self.scaleModifier)
                self.targetScale = nil
                control:SetHandler("OnUpdate", nil)
            else
                control:SetScale(newScale)
            end
        end)
    end

    if self.scaleChildren then
        for childPin, _ in pairs(self.scaleChildren) do
            childPin:SetTargetScale(targetScale)
        end
    end
end

function ZO_MapPin:AddScaleChild(pin)
    if not self.scaleChildren then
        self.scaleChildren = {}
    end
    self.scaleChildren[pin] = true
end

function ZO_MapPin:RemoveScaleChild(pin)
    if self.scaleChildren then
        self.scaleChildren[pin] = nil
    end
end

function ZO_MapPin:GetScaleChildren()
    return self.scaleChildren
end

function ZO_MapPin:ClearScaleChildren()
    if self.scaleChildren then
        ZO_ClearTable(self.scaleChildren)
    end
end

function ZO_MapPin:BuildDependencies()
    if self:IsWorldEventPOIPin() then
        local zoneIndex = self:GetPOIZoneIndex()
        local poiIndex = self:GetPOIIndex()
        local associatedPOIPin = ZO_WorldMap_GetPinManager():FindPin("poi", zoneIndex, poiIndex)
        if associatedPOIPin then
            associatedPOIPin:SetScaleModifier(0.75)
        end
    end
end

function ZO_MapPin:CleanUpDependencies()
    if self:IsWorldEventPOIPin() then
        local zoneIndex = self:GetPOIZoneIndex()
        local poiIndex = self:GetPOIIndex()
        local associatedPOIPin = ZO_WorldMap_GetPinManager():FindPin("poi", zoneIndex, poiIndex)
        if associatedPOIPin then
            associatedPOIPin:SetScaleModifier(1)
        end
    end
end

function ZO_MapPin:SetScaleModifier(modifier)
    modifier = modifier or 1
    if modifier ~= self.scaleModifier then
        local originalScale = self.m_Control:GetScale() / self.scaleModifier
        local newScale = originalScale * modifier
        self.scaleModifier = modifier
        self.m_Control:SetScale(newScale)
    end
end

function ZO_MapPin.GetUnderAttackPinForKeepPin(keepPinType)
    if keepPinType then
        local pinData = ZO_MapPin.PIN_DATA[keepPinType]
        local size = pinData.size or CONSTANTS.DEFAULT_PIN_SIZE
        if size == CONSTANTS.KEEP_PIN_SIZE then
            return MAP_PIN_TYPE_KEEP_ATTACKED_LARGE
        end
    end

    return MAP_PIN_TYPE_KEEP_ATTACKED_SMALL
end

function ZO_MapPin:Reset()
    self:ClearData()

    self:SetHidden(true)

    self:ClearScaleChildren()
    self:ResetAnimation(ZO_MapPin.ANIM_CONSTANTS.RESET_ANIM_HIDE_CONTROL)
    self:ResetScale()
    self:SetRotation(0)
    self:SetOverlapOffsets()

    local control = self:GetControl()
    control:SetAlpha(1)

    -- Remove area blob from pin, put it back in its own pool.
    if self.pinBlobKey then
        ZO_WorldMap_GetPinManager():ReleasePinBlob(self.pinBlobKey)
        self.pinBlobKey = nil
        self.pinBlob = nil
    end

    if self.polygonBlob then
        ZO_WorldMap_GetPinManager():ReleasePinPolygonBlob(self.polygonBlobKey)
        self.polygonBlobKey = nil
        self.polygonBlob = nil
    end
end
