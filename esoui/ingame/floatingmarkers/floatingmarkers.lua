local function OnPlayerActivated()
    SetFloatingMarkerInfo(MAP_PIN_TYPE_ASSISTED_QUEST_CONDITION, 32, "EsoUI/Art/FloatingMarkers/quest_icon_assisted.dds", "EsoUI/Art/FloatingMarkers/quest_icon_door_assisted.dds")
    SetFloatingMarkerInfo(MAP_PIN_TYPE_ASSISTED_QUEST_OPTIONAL_CONDITION, 32, "EsoUI/Art/FloatingMarkers/quest_icon_assisted.dds", "EsoUI/Art/FloatingMarkers/quest_icon_door_assisted.dds")
    SetFloatingMarkerInfo(MAP_PIN_TYPE_ASSISTED_QUEST_ENDING, 32, "EsoUI/Art/FloatingMarkers/quest_icon_assisted.dds", "EsoUI/Art/FloatingMarkers/quest_icon_door_assisted.dds")
    SetFloatingMarkerInfo(MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_CONDITION, 32, "EsoUI/Art/FloatingMarkers/repeatableQuest_icon_assisted.dds", "EsoUI/Art/FloatingMarkers/repeatableQuest_icon_door_assisted.dds")
    SetFloatingMarkerInfo(MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_OPTIONAL_CONDITION, 32, "EsoUI/Art/FloatingMarkers/repeatableQuest_icon_assisted.dds", "EsoUI/Art/FloatingMarkers/repeatableQuest_icon_door_assisted.dds")
    SetFloatingMarkerInfo(MAP_PIN_TYPE_ASSISTED_QUEST_REPEATABLE_ENDING, 32, "EsoUI/Art/FloatingMarkers/repeatableQuest_icon_assisted.dds", "EsoUI/Art/FloatingMarkers/repeatableQuest_icon_door_assisted.dds")

    SetFloatingMarkerInfo(MAP_PIN_TYPE_TRACKED_QUEST_CONDITION, 32, "EsoUI/Art/FloatingMarkers/quest_icon.dds", "EsoUI/Art/FloatingMarkers/quest_icon_door.dds")
    SetFloatingMarkerInfo(MAP_PIN_TYPE_TRACKED_QUEST_OPTIONAL_CONDITION, 32, "EsoUI/Art/FloatingMarkers/quest_icon.dds", "EsoUI/Art/FloatingMarkers/quest_icon_door.dds")
    SetFloatingMarkerInfo(MAP_PIN_TYPE_TRACKED_QUEST_ENDING, 32, "EsoUI/Art/FloatingMarkers/quest_icon.dds", "EsoUI/Art/FloatingMarkers/quest_icon_door.dds")
    SetFloatingMarkerInfo(MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_CONDITION, 32, "EsoUI/Art/FloatingMarkers/repeatableQuest_icon.dds", "EsoUI/Art/FloatingMarkers/repeatableQuest_icon_door.dds")
    SetFloatingMarkerInfo(MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_OPTIONAL_CONDITION, 32, "EsoUI/Art/FloatingMarkers/repeatableQuest_icon.dds", "EsoUI/Art/FloatingMarkers/repeatableQuest_icon_door.dds")
    SetFloatingMarkerInfo(MAP_PIN_TYPE_TRACKED_QUEST_REPEATABLE_ENDING, 32, "EsoUI/Art/FloatingMarkers/repeatableQuest_icon.dds", "EsoUI/Art/FloatingMarkers/repeatableQuest_icon_door.dds")

    SetFloatingMarkerInfo(MAP_PIN_TYPE_TIMELY_ESCAPE_NPC, 32, "EsoUI/Art/FloatingMarkers/timely_escape_npc.dds", "EsoUI/Art/FloatingMarkers/timely_escape_npc.dds")
    SetFloatingMarkerInfo(MAP_PIN_TYPE_DARK_BROTHERHOOD_TARGET, 32, "EsoUI/Art/FloatingMarkers/darkbrotherhood_target.dds", "EsoUI/Art/FloatingMarkers/darkbrotherhood_target.dds")

    local PULSES = true
    SetFloatingMarkerInfo(MAP_PIN_TYPE_QUEST_OFFER, 32, "EsoUI/Art/FloatingMarkers/quest_available_icon.dds", "", PULSES)
    SetFloatingMarkerInfo(MAP_PIN_TYPE_QUEST_OFFER_REPEATABLE, 32, "EsoUI/Art/FloatingMarkers/repeatableQuest_available_icon.dds", "", PULSES)
end

EVENT_MANAGER:RegisterForEvent("ZO_FloatingMarkers", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

SetFloatingMarkerGlobalAlpha(0)