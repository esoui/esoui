local ALLIANCE_ICON_TEXTURES =
{
    [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/AvA/AvA_HUD_emblem_aldmeri.dds",
    [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/AvA/AvA_HUD_emblem_ebonheart.dds",
    [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/AvA/AvA_HUD_emblem_daggerfall.dds",
}

function GetAllianceTexture(alliance)
    return ALLIANCE_ICON_TEXTURES[alliance]
end

local ALLIANCE_SYMBOL_ICONS =
{
    [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/Contacts/social_allianceIcon_aldmeri.dds",
    [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/Contacts/social_allianceIcon_ebonheart.dds",
    [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/Contacts/social_allianceIcon_daggerfall.dds",
}

function GetAllianceSymbolIcon(alliance)
    return ALLIANCE_SYMBOL_ICONS[alliance]
end

local LARGE_ALLIANCE_SYMBOL_ICONS =
{
    [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/Stats/allianceBadge_Aldmeri.dds",
    [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/Stats/allianceBadge_Ebonheart.dds",
    [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/Stats/allianceBadge_Daggerfall.dds",
}

function GetLargeAllianceSymbolIcon(alliance)
    return LARGE_ALLIANCE_SYMBOL_ICONS[alliance]
end

function GetPlatformAllianceSymbolIcon(alliance)
    local icon

    if IsInGamepadPreferredMode() then
        icon = GetLargeAllianceSymbolIcon(alliance)
    else
        icon = GetAllianceSymbolIcon(alliance)
    end

    return icon
end

local ALLIANCE_BANNER_ICONS =
{
    [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/Contacts/social_allianceIcon_aldmeri.dds",
    [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/Contacts/social_allianceIcon_ebonheart.dds",
    [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/Contacts/social_allianceIcon_daggerfall.dds",
}

function GetAllianceBannerIcon(alliance)
    return ALLIANCE_BANNER_ICONS[alliance]
end

local INSTANCE_DISPLAY_TYPE_ICONS =
{
    [INSTANCE_DISPLAY_TYPE_SOLO] = "EsoUI/Art/Icons/mapKey/mapKey_soloInstance.dds",
    [INSTANCE_DISPLAY_TYPE_GROUP] = "EsoUI/Art/Icons/mapKey/mapKey_groupInstance.dds",
    [INSTANCE_DISPLAY_TYPE_RAID] = "EsoUI/Art/Icons/mapKey/mapKey_raidDungeon.dds",
    [INSTANCE_DISPLAY_TYPE_GROUP_DELVE] = "EsoUI/Art/Icons/mapKey/mapKey_groupDelve.dds",
}

function GetInstanceDisplayTypeIcon(instanceType)
    return INSTANCE_DISPLAY_TYPE_ICONS[instanceType]
end

local SOCKET_TEXTURES = {
    --Using blue slot for enchantment currently
    [SOCKET_TYPE_ENCHANTMENT] = "EsoUI/Art/ItemToolTip/ESO_itemToolTip_blueSlot.dds",
    [SOCKET_TYPE_PRECISION] = "EsoUI/Art/AvA/AvA_itemHighlight_precision.dds",
    [SOCKET_TYPE_AMMO] = "EsoUI/Art/AvA/AvA_itemHighlight_ammo.dds",
    [SOCKET_TYPE_LAUNCH_VELOCITY] = "EsoUI/Art/AvA/AvA_itemHighlight_range.dds",
    [SOCKET_TYPE_TOUGHNESS] = "EsoUI/Art/AvA/AvA_itemHighlight_toughness.dds",
}

function GetSocketTexture(socketType)
    return SOCKET_TEXTURES[socketType]
end

do
    local CLASS_ICONS = {}
    local GAMEPAD_CLASS_ICONS = {}

    for i = 1, GetNumClasses() do
        local classId, _, _, _, _, _, keyboardIcon, gamepadIcon = GetClassInfo(i)
        CLASS_ICONS[classId] = keyboardIcon
        GAMEPAD_CLASS_ICONS[classId] = gamepadIcon
    end 

    function GetClassIcon(classId)
        return CLASS_ICONS[classId]
    end

    function GetGamepadClassIcon(classId)
        return GAMEPAD_CLASS_ICONS[classId]
    end

    function GetPlatformClassIcon(classId)
        local icon

        if IsInGamepadPreferredMode() then
            icon = GetGamepadClassIcon(classId)
        else
            icon = GetClassIcon(classId)
        end

        return icon
    end
end

local STATUS_ICONS =
{
    [PLAYER_STATUS_ONLINE] = "EsoUI/Art/Contacts/social_status_online.dds",
    [PLAYER_STATUS_OFFLINE] = "EsoUI/Art/Contacts/social_status_offline.dds",
    [PLAYER_STATUS_AWAY] = "EsoUI/Art/Contacts/social_status_afk.dds",
    [PLAYER_STATUS_DO_NOT_DISTURB] = "EsoUI/Art/Contacts/social_status_dnd.dds",
}

local GAMEPAD_STATUS_ICONS =
{
    [PLAYER_STATUS_ONLINE] = "EsoUI/Art/Contacts/Gamepad/gp_social_status_online.dds",
    [PLAYER_STATUS_OFFLINE] = "EsoUI/Art/Contacts/Gamepad/gp_social_status_offline.dds",
    [PLAYER_STATUS_AWAY] = "EsoUI/Art/Contacts/Gamepad/gp_social_status_afk.dds",
    [PLAYER_STATUS_DO_NOT_DISTURB] = "EsoUI/Art/Contacts/Gamepad/gp_social_status_dnd.dds",
}

function GetPlayerStatusIcon(playerStatus)
    return STATUS_ICONS[playerStatus]
end

function GetGamepadPlayerStatusIcon(playerStatus)
    return GAMEPAD_STATUS_ICONS[playerStatus]
end

local VETERAN_RANK_ICON = "EsoUI/Art/UnitFrames/target_veteranRank_icon.dds"
local GAMEPAD_VETERAN_RANK_ICON = "EsoUI/Art/Contacts/Gamepad/gp_social_levelIcon_veteran.dds"

function GetVeteranRankIcon()
    return VETERAN_RANK_ICON
end

function GetGamepadVeteranRankIcon()
    return GAMEPAD_VETERAN_RANK_ICON
end

function GetColoredAvARankIconMarkup(avaRank, alliance, size)
    local rankIconMarkup = string.format("|t%d:%d:%s:inheritColor|t", size, size, GetAvARankIcon(avaRank))
    local coloredRankIconMarkup = GetAllianceColor(alliance):Colorize(rankIconMarkup)
    return coloredRankIconMarkup
end

local POINTS_ATTRIBUTE_ICON =
{
    [ATTRIBUTE_HEALTH] = "EsoUI/Art/Champion/champion_points_health_icon.dds",
    [ATTRIBUTE_MAGICKA] = "EsoUI/Art/Champion/champion_points_magicka_icon.dds",
    [ATTRIBUTE_STAMINA] = "EsoUI/Art/Champion/champion_points_stamina_icon.dds",
}

function GetChampionPointAttributeIcon(attribute)
    return POINTS_ATTRIBUTE_ICON[attribute]
end

local POINTS_ATTRIBUTE_ACTIVE_ICON =
{
    [ATTRIBUTE_HEALTH] = "EsoUI/Art/Champion/champion_points_health_icon_active.dds",
    [ATTRIBUTE_MAGICKA] = "EsoUI/Art/Champion/champion_points_magicka_icon_active.dds",
    [ATTRIBUTE_STAMINA] = "EsoUI/Art/Champion/champion_points_stamina_icon_active.dds",
}

function GetChampionPointAttributeActiveIcon(attribute)
    return POINTS_ATTRIBUTE_ACTIVE_ICON[attribute]
end

ZO_NO_TEXTURE_FILE = "esoui/art/icons/icon_missing.dds"

ZO_GAMEPAD_SUBMIT_ENTRY_ICON = "EsoUI/Art/Miscellaneous/Gamepad/gp_submit.dds"

-- Gamepad Currency Textures
ZO_GAMEPAD_CURRENCY_ICON_GOLD_TEXTURE = "EsoUI/Art/currency/gamepad/gp_gold.dds"
ZO_GAMEPAD_CURRENCY_ICON_ALLIANCE_POINTS_TEXTURE = "EsoUI/Art/currency/gamepad/gp_alliancePoints.dds"
ZO_GAMEPAD_CURRENCY_ICON_TELVAR_STONES_TEXTURE = "EsoUI/Art/currency/gamepad/gp_telvar.dds"
ZO_GAMEPAD_CURRENCY_ICON_INSPIRATION_POINTS_TEXTURE = "EsoUI/Art/currency/gamepad/gp_inspiration.dds"
ZO_GAMEPAD_CURRENCY_ICON_CROWNS_TEXTURE = "EsoUI/Art/currency/gamepad/gp_crowns.dds"