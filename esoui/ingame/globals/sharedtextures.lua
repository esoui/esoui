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
    [INSTANCE_DISPLAY_TYPE_DUNGEON] = "EsoUI/Art/Icons/mapKey/mapKey_groupInstance.dds",
    [INSTANCE_DISPLAY_TYPE_RAID] = "EsoUI/Art/Icons/mapKey/mapKey_raidDungeon.dds",
    [INSTANCE_DISPLAY_TYPE_GROUP_DELVE] = "EsoUI/Art/Icons/mapKey/mapKey_groupDelve.dds",
    [INSTANCE_DISPLAY_TYPE_GROUP_AREA] = "EsoUI/Art/Icons/mapKey/mapKey_groupArea.dds",
    [INSTANCE_DISPLAY_TYPE_PUBLIC_DUNGEON] = "EsoUI/Art/Icons/mapKey/mapKey_publicDungeon.dds",
    [INSTANCE_DISPLAY_TYPE_DELVE] = "EsoUI/Art/Icons/mapKey/mapKey_delve.dds",
    [INSTANCE_DISPLAY_TYPE_HOUSING] = "EsoUI/Art/Icons/mapKey/mapKey_housing.dds",
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

local CHAMPION_POINT_ICON = "EsoUI/Art/Champion/champion_icon.dds"
local CHAMPION_POINT_ICON_SMALL = "EsoUI/Art/Champion/champion_icon_32.dds"
local GAMEPAD_CHAMPION_POINT_ICON = "EsoUI/Art/Champion/Gamepad/gp_champion_icon.dds"

function GetChampionPointsIcon()
    return CHAMPION_POINT_ICON
end

function GetChampionPointsIconSmall()
    return CHAMPION_POINT_ICON_SMALL
end

function GetGamepadChampionPointsIcon()
    return GAMEPAD_CHAMPION_POINT_ICON
end

local VETERAN_ICON = "EsoUI/Art/UnitFrames/target_veteranRank_icon.dds"
local GAMEPAD_VETERAN_ICON = "EsoUI/Art/Contacts/Gamepad/gp_social_levelIcon_veteran.dds"

function GetVeteranIcon()
    return VETERAN_ICON
end

function GetGamepadVeteranIcon()
    return GAMEPAD_VETERAN_ICON
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

local POINTS_ATTRIBUTE_HUD_ICON =
{
    [ATTRIBUTE_HEALTH] = "EsoUI/Art/Champion/champion_points_health_icon-HUD.dds",
    [ATTRIBUTE_MAGICKA] = "EsoUI/Art/Champion/champion_points_magicka_icon-HUD.dds",
    [ATTRIBUTE_STAMINA] = "EsoUI/Art/Champion/champion_points_stamina_icon-HUD.dds",
}

function GetChampionPointAttributeHUDIcon(attribute)
    return POINTS_ATTRIBUTE_HUD_ICON[attribute]
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

local KEYBOARD_ROLE_ICONS =
{
    [LFG_ROLE_DPS] = "EsoUI/Art/LFG/LFG_icon_dps.dds",
    [LFG_ROLE_TANK] = "EsoUI/Art/LFG/LFG_icon_tank.dds",
    [LFG_ROLE_HEAL] = "EsoUI/Art/LFG/LFG_icon_healer.dds",
}

function GetKeyboardRoleIcon(role)
    return KEYBOARD_ROLE_ICONS[role]
end

local GAMEPAD_ROLE_ICONS =
{
    [LFG_ROLE_DPS] = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_dps.dds",
    [LFG_ROLE_TANK] = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_tank.dds",
    [LFG_ROLE_HEAL] = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_healer.dds",
}

function GetGamepadRoleIcon(role)
    return GAMEPAD_ROLE_ICONS[role]
end

function GetRoleIcon(role)
    if IsInGamepadPreferredMode() then
        return GetGamepadRoleIcon(role)
    else
        return GetKeyboardRoleIcon(role)
    end
end

local KEYBOARD_DUNEGON_DIFFICULTY_ICONS =
{
    [DUNGEON_DIFFICULTY_NORMAL] = "EsoUI/Art/LFG/LFG_normalDungeon_up.dds",
    [DUNGEON_DIFFICULTY_VETERAN] = "EsoUI/Art/LFG/LFG_veteranDungeon_up.dds",
}

function GetKeyboardDungeonDifficultyIcon(dungeonDifficulty)
    return KEYBOARD_DUNEGON_DIFFICULTY_ICONS[dungeonDifficulty]
end

local GAMEPAD_DUNGEON_DIFFICULTY_ICONS =
{
    [DUNGEON_DIFFICULTY_NORMAL] = "EsoUI/Art/LFG/Gamepad/gp_LFG_menuIcon_normalDungeon.dds",
    [DUNGEON_DIFFICULTY_VETERAN] = "EsoUI/Art/LFG/Gamepad/gp_LFG_menuIcon_veteranDungeon.dds",
}

function GetGamepadDungeonDifficultyIcon(dungeonDifficulty)
    return GAMEPAD_DUNGEON_DIFFICULTY_ICONS[dungeonDifficulty]
end

do
    local KEYBOARD_RECIPE_CRAFTING_SYSTEM_BUTTON_TEXTURES =
    {
        [RECIPE_CRAFTING_SYSTEM_BLACKSMITHING_DIAGRAMS] =
        {
            up = "EsoUI/Art/Crafting/diagrams_tabIcon_up.dds",
            down = "EsoUI/Art/Crafting/diagrams_tabIcon_down.dds",
            over = "EsoUI/Art/Crafting/diagrams_tabIcon_over.dds",
            disabled = "EsoUI/Art/Crafting/diagrams_tabIcon_disabled.dds"
        },
        [RECIPE_CRAFTING_SYSTEM_CLOTHIER_PATTERNS] =
        {
            up = "EsoUI/Art/Crafting/patterns_tabIcon_up.dds",
            down = "EsoUI/Art/Crafting/patterns_tabIcon_down.dds",
            over = "EsoUI/Art/Crafting/patterns_tabIcon_over.dds",
            disabled = "EsoUI/Art/Crafting/patterns_tabIcon_disabled.dds",
        },
        [RECIPE_CRAFTING_SYSTEM_ENCHANTING_SCHEMATICS] =
        {
            up = "EsoUI/Art/Crafting/schematics_tabIcon_up.dds",
            down = "EsoUI/Art/Crafting/schematics_tabIcon_down.dds",
            over = "EsoUI/Art/Crafting/schematics_tabIcon_over.dds",
            disabled = "EsoUI/Art/Crafting/schematics_tabIcon_disabled.dds",
        },
        [RECIPE_CRAFTING_SYSTEM_ALCHEMY_FORMULAE] = 
        {
            up = "EsoUI/Art/Crafting/formulae_tabIcon_up.dds",
            down = "EsoUI/Art/Crafting/formulae_tabIcon_down.dds",
            over = "EsoUI/Art/Crafting/formulae_tabIcon_over.dds",
            disabled = "EsoUI/Art/Crafting/formulae_tabIcon_disabled.dds",
        },
        [RECIPE_CRAFTING_SYSTEM_PROVISIONING_DESIGNS] =
        {
            up = "EsoUI/Art/Crafting/designs_tabIcon_up.dds",
            down = "EsoUI/Art/Crafting/designs_tabIcon_down.dds",
            over = "EsoUI/Art/Crafting/designs_tabIcon_over.dds",
            disabled = "EsoUI/Art/Crafting/designs_tabIcon_disabled.dds",
        },
        [RECIPE_CRAFTING_SYSTEM_WOODWORKING_BLUEPRINTS] =
        {
            up = "EsoUI/Art/Crafting/blueprints_tabIcon_up.dds",
            down = "EsoUI/Art/Crafting/blueprints_tabIcon_down.dds",
            over = "EsoUI/Art/Crafting/blueprints_tabIcon_over.dds",
            disabled = "EsoUI/Art/Crafting/blueprints_tabIcon_disabled.dds",
        },
    }

    function GetKeyboardRecipeCraftingSystemButtonTextures(recipeCraftingSystem)
        local textures = KEYBOARD_RECIPE_CRAFTING_SYSTEM_BUTTON_TEXTURES[recipeCraftingSystem]
        if textures then
            return textures.up, textures.down, textures.over, textures.disabled
        end
    end
end

do
    local GAMEPAD_RECIPE_CRAFTING_SYSTEM_MENU_TEXTURES =
    {
        [RECIPE_CRAFTING_SYSTEM_BLACKSMITHING_DIAGRAMS] = "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_diagrams.dds",
        [RECIPE_CRAFTING_SYSTEM_CLOTHIER_PATTERNS] = "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_patterns.dds",
        [RECIPE_CRAFTING_SYSTEM_ENCHANTING_SCHEMATICS] = "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_schematics.dds",
        [RECIPE_CRAFTING_SYSTEM_ALCHEMY_FORMULAE] = "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_formulae.dds",
        [RECIPE_CRAFTING_SYSTEM_PROVISIONING_DESIGNS] = "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_designs.dds",
        [RECIPE_CRAFTING_SYSTEM_WOODWORKING_BLUEPRINTS] = "EsoUI/Art/Crafting/Gamepad/gp_crafting_menuIcon_blueprints.dds",
    }

    function GetGamepadRecipeCraftingSystemMenuTextures(recipeCraftingSystem)
        return GAMEPAD_RECIPE_CRAFTING_SYSTEM_MENU_TEXTURES[recipeCraftingSystem]
    end
end


ZO_NO_TEXTURE_FILE = "/esoui/art/icons/icon_missing.dds"
ZO_KEYBOARD_NEW_ICON = "EsoUI/Art/Miscellaneous/new_icon.dds"
ZO_GAMEPAD_NEW_ICON_32 = "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_new.dds"
ZO_GAMEPAD_NEW_ICON_64 = "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_new_64.dds"
ZO_GAMEPAD_SUBMIT_ENTRY_ICON = "EsoUI/Art/Miscellaneous/Gamepad/gp_submit.dds"
ZO_TIMER_ICON_32 = "EsoUI/Art/Miscellaneous/timer_32.dds"
ZO_TIMER_ICON_64 = "EsoUI/Art/Miscellaneous/timer_64.dds"
ZO_KEYBOARD_LOCKED_ICON = "EsoUI/Art/Miscellaneous/status_locked.dds"
ZO_GAMEPAD_LOCKED_ICON_32 = "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_locked32.dds"

-- Gamepad Currency Textures
ZO_GAMEPAD_CURRENCY_ICON_GOLD_TEXTURE = "EsoUI/Art/currency/gamepad/gp_gold.dds"
ZO_GAMEPAD_CURRENCY_ICON_ALLIANCE_POINTS_TEXTURE = "EsoUI/Art/currency/gamepad/gp_alliancePoints.dds"
ZO_GAMEPAD_CURRENCY_ICON_TELVAR_STONES_TEXTURE = "EsoUI/Art/currency/gamepad/gp_telvar.dds"
ZO_GAMEPAD_CURRENCY_ICON_INSPIRATION_POINTS_TEXTURE = "EsoUI/Art/currency/gamepad/gp_inspiration.dds"
ZO_GAMEPAD_CURRENCY_ICON_CROWNS_TEXTURE = "EsoUI/Art/currency/gamepad/gp_crowns.dds"