-- Alliance --
do
    local ALLIANCE_ICON_TEXTURES =
    {
        [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/AvA/AvA_HUD_emblem_aldmeri.dds",
        [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/AvA/AvA_HUD_emblem_ebonheart.dds",
        [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/AvA/AvA_HUD_emblem_daggerfall.dds",
    }

    function GetAllianceTexture(alliance)
        return ALLIANCE_ICON_TEXTURES[alliance]
    end
end

do
    local ALLIANCE_SYMBOL_ICONS =
    {
        [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/Contacts/social_allianceIcon_aldmeri.dds",
        [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/Contacts/social_allianceIcon_ebonheart.dds",
        [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/Contacts/social_allianceIcon_daggerfall.dds",
    }

    function GetAllianceSymbolIcon(alliance)
        return ALLIANCE_SYMBOL_ICONS[alliance]
    end
end

do
    local LARGE_BATTLEGROUND_ALLIANCE_ICONS =
    {
        [BATTLEGROUND_ALLIANCE_FIRE_DRAKES] = "EsoUI/Art/Stats/battleground_alliance_badge_Fire_Drakes.dds",
        [BATTLEGROUND_ALLIANCE_PIT_DAEMONS] = "EsoUI/Art/Stats/battleground_alliance_badge_Pit_Daemons.dds",
        [BATTLEGROUND_ALLIANCE_STORM_LORDS] = "EsoUI/Art/Stats/battleground_alliance_badge_Storm_Lords.dds",
    }

    function GetLargeBattlegroundAllianceSymbolIcon(bgAlliance)
        return LARGE_BATTLEGROUND_ALLIANCE_ICONS[bgAlliance]
    end
end

do
    local COUNTDOWN_BATTLEGROUND_ALLIANCE_ICONS =
    {
        [BATTLEGROUND_ALLIANCE_FIRE_DRAKES] = "EsoUI/Art/HUD/HUD_Countdown_Badge_BG_orange.dds",
        [BATTLEGROUND_ALLIANCE_PIT_DAEMONS] = "EsoUI/Art/HUD/HUD_Countdown_Badge_BG_green.dds",
        [BATTLEGROUND_ALLIANCE_STORM_LORDS] = "EsoUI/Art/HUD/HUD_Countdown_Badge_BG_purple.dds",
    }

    function GetCountdownBattlegroundAllianceSymbolIcon(bgAlliance)
        return COUNTDOWN_BATTLEGROUND_ALLIANCE_ICONS[bgAlliance]
    end
end

do
    local LARGE_ALLIANCE_SYMBOL_ICONS =
    {
        [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/Stats/allianceBadge_Aldmeri.dds",
        [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/Stats/allianceBadge_Ebonheart.dds",
        [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/Stats/allianceBadge_Daggerfall.dds",
    }

    function GetLargeAllianceSymbolIcon(alliance)
        return LARGE_ALLIANCE_SYMBOL_ICONS[alliance]
    end
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

do
    local ALLIANCE_KEEP_REWARD_ICONS =
    {
        [ALLIANCE_ALDMERI_DOMINION] = "EsoUI/Art/Icons/AVA_Siege_UI_006.dds",
        [ALLIANCE_EBONHEART_PACT] = "EsoUI/Art/Icons/AVA_Siege_UI_008.dds",
        [ALLIANCE_DAGGERFALL_COVENANT] = "EsoUI/Art/Icons/AVA_Siege_UI_007.dds",
    }

    function GetAllianceKeepRewardIcon(alliance)
        return ALLIANCE_KEEP_REWARD_ICONS[alliance]
    end
end

-- Instance Display Type --
do
    local INSTANCE_DISPLAY_TYPE_ICONS =
    {
        [INSTANCE_DISPLAY_TYPE_SOLO] = "EsoUI/Art/Icons/mapKey/mapKey_soloInstance.dds",
        [INSTANCE_DISPLAY_TYPE_DUNGEON] = "EsoUI/Art/Icons/mapKey/mapKey_groupInstance.dds",
        [INSTANCE_DISPLAY_TYPE_RAID] = "EsoUI/Art/Icons/mapKey/mapKey_raidDungeon.dds",
        [INSTANCE_DISPLAY_TYPE_GROUP_DELVE] = "EsoUI/Art/Icons/mapKey/mapKey_groupDelve.dds",
        [INSTANCE_DISPLAY_TYPE_GROUP_AREA] = "EsoUI/Art/Icons/mapKey/mapKey_groupArea.dds",
        [INSTANCE_DISPLAY_TYPE_PUBLIC_DUNGEON] = "EsoUI/Art/Icons/mapKey/mapKey_dungeon.dds",
        [INSTANCE_DISPLAY_TYPE_DELVE] = "EsoUI/Art/Icons/mapKey/mapKey_delve.dds",
        [INSTANCE_DISPLAY_TYPE_HOUSING] = "EsoUI/Art/Icons/mapKey/mapKey_housing.dds",
        [INSTANCE_DISPLAY_TYPE_ZONE_STORY] = "EsoUI/Art/Icons/mapKey/mapKey_zoneStory.dds",
    }

    function GetInstanceDisplayTypeIcon(instanceType)
        return INSTANCE_DISPLAY_TYPE_ICONS[instanceType]
    end
end

-- Socket --
do
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
end

-- Class --
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

-- Social Status --
do
    local STATUS_ICONS =
    {
        [PLAYER_STATUS_ONLINE] = "EsoUI/Art/Contacts/social_status_online.dds",
        [PLAYER_STATUS_OFFLINE] = "EsoUI/Art/Contacts/social_status_offline.dds",
        [PLAYER_STATUS_AWAY] = "EsoUI/Art/Contacts/social_status_afk.dds",
        [PLAYER_STATUS_DO_NOT_DISTURB] = "EsoUI/Art/Contacts/social_status_dnd.dds",
    }

    function GetPlayerStatusIcon(playerStatus)
        return STATUS_ICONS[playerStatus]
    end
end

do
    local GAMEPAD_STATUS_ICONS =
    {
        [PLAYER_STATUS_ONLINE] = "EsoUI/Art/Contacts/Gamepad/gp_social_status_online.dds",
        [PLAYER_STATUS_OFFLINE] = "EsoUI/Art/Contacts/Gamepad/gp_social_status_offline.dds",
        [PLAYER_STATUS_AWAY] = "EsoUI/Art/Contacts/Gamepad/gp_social_status_afk.dds",
        [PLAYER_STATUS_DO_NOT_DISTURB] = "EsoUI/Art/Contacts/Gamepad/gp_social_status_dnd.dds",
    }

    function GetGamepadPlayerStatusIcon(playerStatus)
        return GAMEPAD_STATUS_ICONS[playerStatus]
    end
end

-- Champion --
do
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

    local ACTION_BAR_DISCIPLINE_TEXTURES = 
    {
        [CHAMPION_DISCIPLINE_TYPE_COMBAT] =
        {
            border = "EsoUI/Art/Champion/ActionBar/champion_bar_slot_frame.dds",
            selected = "EsoUI/Art/Champion/ActionBar/champion_bar_combat_selection.dds",
            slotted = "EsoUI/Art/Champion/ActionBar/champion_bar_combat_slotted.dds",
            empty = "EsoUI/Art/Champion/ActionBar/champion_bar_combat_empty.dds",
            disabled = "EsoUI/Art/Champion/ActionBar/champion_bar_slot_frame_disabled.dds",
        },
        [CHAMPION_DISCIPLINE_TYPE_CONDITIONING] =
        {
            border = "EsoUI/Art/Champion/ActionBar/champion_bar_slot_frame.dds",
            selected = "EsoUI/Art/Champion/ActionBar/champion_bar_conditioning_selection.dds",
            slotted = "EsoUI/Art/Champion/ActionBar/champion_bar_conditioning_slotted.dds",
            empty = "EsoUI/Art/Champion/ActionBar/champion_bar_conditioning_empty.dds",
            disabled = "EsoUI/Art/Champion/ActionBar/champion_bar_slot_frame_disabled.dds",
        },
        [CHAMPION_DISCIPLINE_TYPE_WORLD] =
        {
            border = "EsoUI/Art/Champion/ActionBar/champion_bar_slot_frame.dds",
            selected = "EsoUI/Art/Champion/ActionBar/champion_bar_world_selection.dds",
            slotted = "EsoUI/Art/Champion/ActionBar/champion_bar_world_slotted.dds",
            empty = "EsoUI/Art/Champion/ActionBar/champion_bar_world_empty.dds",
            disabled = "EsoUI/Art/Champion/ActionBar/champion_bar_slot_frame_disabled.dds",
        },
    }

    function GetChampionBarDisciplineTextures(disciplineType)
        return ACTION_BAR_DISCIPLINE_TEXTURES[disciplineType]
    end
end

-- Veteran --
do
    local VETERAN_ICON = "EsoUI/Art/UnitFrames/target_veteranRank_icon.dds"
    local GAMEPAD_VETERAN_ICON = "EsoUI/Art/Contacts/Gamepad/gp_social_levelIcon_veteran.dds"

    function GetVeteranIcon()
        return VETERAN_ICON
    end

    function GetGamepadVeteranIcon()
        return GAMEPAD_VETERAN_ICON
    end
end

-- AvA Rank --
function GetColoredAvARankIconMarkup(avaRank, alliance, size)
    local rankIconMarkup = string.format("|t%d:%d:%s:inheritColor|t", size, size, GetAvARankIcon(avaRank))
    local coloredRankIconMarkup = GetAllianceColor(alliance):Colorize(rankIconMarkup)
    return coloredRankIconMarkup
end

--LFG Role --
do
    local KEYBOARD_ROLE_ICONS =
    {
        [LFG_ROLE_DPS] = "EsoUI/Art/LFG/LFG_icon_dps.dds",
        [LFG_ROLE_TANK] = "EsoUI/Art/LFG/LFG_icon_tank.dds",
        [LFG_ROLE_HEAL] = "EsoUI/Art/LFG/LFG_icon_healer.dds",
    }

    function GetKeyboardRoleIcon(role)
        return KEYBOARD_ROLE_ICONS[role]
    end
end

do
    local GAMEPAD_ROLE_ICONS =
    {
        [LFG_ROLE_DPS] = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_dps.dds",
        [LFG_ROLE_TANK] = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_tank.dds",
        [LFG_ROLE_HEAL] = "EsoUI/Art/LFG/Gamepad/LFG_roleIcon_healer.dds",
    }

    function GetGamepadRoleIcon(role)
        return GAMEPAD_ROLE_ICONS[role]
    end
end

function GetRoleIcon(role)
    if IsInGamepadPreferredMode() then
        return GetGamepadRoleIcon(role)
    else
        return GetKeyboardRoleIcon(role)
    end
end

-- Battlegrounds --
do
    local KEYBOARD_BATTLEGROUND_TEAM_ICONS =
    {
        [BATTLEGROUND_ALLIANCE_FIRE_DRAKES] = "EsoUI/Art/Battlegrounds/battlegrounds_teamIcon_orange.dds",
        [BATTLEGROUND_ALLIANCE_PIT_DAEMONS] = "EsoUI/Art/Battlegrounds/battlegrounds_teamIcon_green.dds",
        [BATTLEGROUND_ALLIANCE_STORM_LORDS] = "EsoUI/Art/Battlegrounds/battlegrounds_teamIcon_purple.dds",
    }

    function GetKeyboardBattlegroundTeamIcon(battlegroundAlliance)
        return KEYBOARD_BATTLEGROUND_TEAM_ICONS[battlegroundAlliance]
    end
end

do
    local GAMEPAD_BATTLEGROUND_TEAM_ICONS =
    {
        [BATTLEGROUND_ALLIANCE_FIRE_DRAKES] = "EsoUI/Art/Battlegrounds/Gamepad/gp_battlegrounds_teamIcon_orange.dds",
        [BATTLEGROUND_ALLIANCE_PIT_DAEMONS] = "EsoUI/Art/Battlegrounds/Gamepad/gp_battlegrounds_teamIcon_green.dds",
        [BATTLEGROUND_ALLIANCE_STORM_LORDS] = "EsoUI/Art/Battlegrounds/Gamepad/gp_battlegrounds_teamIcon_purple.dds",
    }

    function GetGamepadBattlegroundTeamIcon(battlegroundAlliance)
        return GAMEPAD_BATTLEGROUND_TEAM_ICONS[battlegroundAlliance]
    end
end

function GetBattlegroundTeamIcon(battlegroundAlliance)
    if IsInGamepadPreferredMode() then
        return GetGamepadBattlegroundTeamIcon(battlegroundAlliance)
    else
        return GetKeyboardBattlegroundTeamIcon(battlegroundAlliance)
    end
end

function GetBattlegroundIconMarkup(battlegroundAlliance, size)
    return zo_iconFormatInheritColor(GetBattlegroundTeamIcon(battlegroundAlliance), size, size)
end

-- Difficulty --
do
    local KEYBOARD_DUNEGON_DIFFICULTY_ICONS =
    {
        [DUNGEON_DIFFICULTY_NORMAL] = "EsoUI/Art/LFG/LFG_normalDungeon_up.dds",
        [DUNGEON_DIFFICULTY_VETERAN] = "EsoUI/Art/LFG/LFG_veteranDungeon_up.dds",
    }

    function GetKeyboardDungeonDifficultyIcon(dungeonDifficulty)
        return KEYBOARD_DUNEGON_DIFFICULTY_ICONS[dungeonDifficulty]
    end
end

do
    local GAMEPAD_DUNGEON_DIFFICULTY_ICONS =
    {
        [DUNGEON_DIFFICULTY_NORMAL] = "EsoUI/Art/LFG/Gamepad/gp_LFG_menuIcon_normalDungeon.dds",
        [DUNGEON_DIFFICULTY_VETERAN] = "EsoUI/Art/LFG/Gamepad/gp_LFG_menuIcon_veteranDungeon.dds",
    }

    function GetGamepadDungeonDifficultyIcon(dungeonDifficulty)
        return GAMEPAD_DUNGEON_DIFFICULTY_ICONS[dungeonDifficulty]
    end
end

-- Recipe crafting --
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
        [RECIPE_CRAFTING_SYSTEM_JEWELRYCRAFTING_SKETCHES] =
        {
            up = "EsoUI/Art/Crafting/sketches_tabIcon_up.dds",
            down = "EsoUI/Art/Crafting/sketches_tabIcon_down.dds",
            over = "EsoUI/Art/Crafting/sketches_tabIcon_over.dds",
            disabled = "EsoUI/Art/Crafting/sketches_tabIcon_disabled.dds",
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
        [RECIPE_CRAFTING_SYSTEM_JEWELRYCRAFTING_SKETCHES] = "EsoUI/Art/Crafting/Gamepad/gp_tabIcon_JewelryCraft_sketches.dds",
    }

    function GetGamepadRecipeCraftingSystemMenuTextures(recipeCraftingSystem)
        return GAMEPAD_RECIPE_CRAFTING_SYSTEM_MENU_TEXTURES[recipeCraftingSystem]
    end
end

do
    local ITEM_TRAIT_INFORMATION_KEYBOARD_ICON_PATHS =
    {
        [ITEM_TRAIT_INFORMATION_ORNATE] = "EsoUI/Art/Inventory/inventory_trait_ornate_icon.dds",
        [ITEM_TRAIT_INFORMATION_INTRICATE] = "EsoUI/Art/Inventory/inventory_trait_intricate_icon.dds",
        [ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED] = "EsoUI/Art/Inventory/inventory_trait_not_researched_icon.dds",
        [ITEM_TRAIT_INFORMATION_RETRAITED] = "EsoUI/Art/Inventory/inventory_trait_retrait_icon.dds",
        [ITEM_TRAIT_INFORMATION_RECONSTRUCTED] = "EsoUI/Art/Inventory/inventory_trait_reconstruct_icon.dds",
    }

    local ITEM_TRAIT_INFORMATION_GAMEPAD_ICON_PATHS =
    {
        [ITEM_TRAIT_INFORMATION_ORNATE] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_trait_ornate_icon.dds",
        [ITEM_TRAIT_INFORMATION_INTRICATE] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_trait_intricate_icon.dds",
        [ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_trait_not_researched_icon.dds",
        [ITEM_TRAIT_INFORMATION_RETRAITED] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_trait_retrait_icon.dds",
        [ITEM_TRAIT_INFORMATION_RECONSTRUCTED] = "EsoUI/Art/Inventory/Gamepad/gp_inventory_trait_reconstruct_icon.dds",
    }

    function GetPlatformTraitInformationIcon(itemTraitInformation)
        if itemTraitInformation then
            if IsInGamepadPreferredMode() then
                return ITEM_TRAIT_INFORMATION_GAMEPAD_ICON_PATHS[itemTraitInformation]
            else
                return ITEM_TRAIT_INFORMATION_KEYBOARD_ICON_PATHS[itemTraitInformation]
            end
        end
    end
end

do
    local ITEM_SELL_INFORMATION_ICON_PATHS =
    {
        [ITEM_SELL_INFORMATION_PRIORITY_SELL] = "EsoUI/Art/Inventory/inventory_trait_ornate_icon.dds",
        [ITEM_SELL_INFORMATION_INTRICATE] = "EsoUI/Art/Inventory/inventory_trait_intricate_icon.dds",
        [ITEM_SELL_INFORMATION_CAN_BE_RESEARCHED] = "EsoUI/Art/Inventory/inventory_trait_not_researched_icon.dds",
        [ITEM_SELL_INFORMATION_CANNOT_SELL] = "EsoUI/Art/Inventory/inventory_sell_forbidden_icon.dds",
        [ITEM_SELL_INFORMATION_RECONSTRUCTED] = "EsoUI/Art/Inventory/inventory_trait_reconstruct_icon.dds",
    }

    function GetItemSellInformationIcon(itemSellInformation)
        if itemSellInformation then
            return ITEM_SELL_INFORMATION_ICON_PATHS[itemSellInformation]
        end
    end
end

-- Misc --
ZO_NO_TEXTURE_FILE = "/esoui/art/icons/icon_missing.dds"
ZO_KEYBOARD_NEW_ICON = "EsoUI/Art/Miscellaneous/new_icon.dds"
ZO_GAMEPAD_NEW_ICON_32 = "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_new.dds"
ZO_GAMEPAD_NEW_ICON_64 = "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_new_64.dds"
ZO_GAMEPAD_SUBMIT_ENTRY_ICON = "EsoUI/Art/Miscellaneous/Gamepad/gp_submit.dds"
ZO_TIMER_ICON_32 = "EsoUI/Art/Miscellaneous/timer_32.dds"
ZO_TIMER_ICON_64 = "EsoUI/Art/Miscellaneous/timer_64.dds"
ZO_KEYBOARD_LOCKED_ICON = "EsoUI/Art/Miscellaneous/status_locked.dds"
ZO_GAMEPAD_LOCKED_ICON_32 = "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_locked32.dds"
ZO_KEYBOARD_IS_EQUIPPED_ICON = "EsoUI/Art/Inventory/inventory_icon_equipped.dds"
ZO_GAMEPAD_IS_EQUIPPED_ICON = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"
ZO_CHECK_ICON = "EsoUI/Art/Miscellaneous/check_icon_32.dds"
ZO_GAMEPAD_HERON_NAME_ICON = "EsoUI/Art/Miscellaneous/Gamepad/gp_heronNameIcon.dds"
