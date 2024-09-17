local ARROW_ICON_WIDTH = 32
ZO_GAMEPAD_DEFAULT_LIST_ENTRY_WITH_ARROW_WIDTH_AFTER_INDENT = ZO_GAMEPAD_DEFAULT_LIST_ENTRY_WIDTH_AFTER_INDENT - ARROW_ICON_WIDTH

ZO_MENU_ENTRIES = {}

ZO_MENU_MAIN_ENTRIES =
{
    CROWN_STORE     = 1,
    ANNOUNCEMENTS   = 2,
    NOTIFICATIONS   = 3,
    COLLECTIONS     = 4,
    INVENTORY       = 5,
    CHARACTER       = 6,
    SKILLS          = 7,
    CHAMPION        = 8,
    CAMPAIGN        = 9,
    JOURNAL         = 10,
    SOCIAL          = 11,
    ACTIVITY_FINDER = 12,
    HELP            = 13,
    OPTIONS         = 14,
    LOG_OUT         = 15,
}

local MENU_MAIN_ENTRIES = ZO_MENU_MAIN_ENTRIES

local MENU_CROWN_STORE_ENTRIES =
{
    CROWN_STORE                 = 1,
    EXPIRING_MARKET_CURRENCY    = 2,
    ENDEAVOR_SEAL_STORE         = 3,
    DAILY_LOGIN_REWARDS         = 4,
    CROWN_CRATES                = 5,
    CHAPTERS                    = 6,
    GIFT_INVENTORY              = 7,
    REDEEM_CODE                 = 8,
}

ZO_MENU_CROWN_STORE_ENTRIES = MENU_CROWN_STORE_ENTRIES

local MENU_COLLECTIONS_ENTRIES =
{
    COLLECTIONS         = 1,
    ITEM_SETS           = 2,
    TRIBUTE_PATRONS     = 3,
}
local MENU_JOURNAL_ENTRIES =
{
    QUESTS              = 1,
    CADWELLS_JOURNAL    = 2,
    ANTIQUITIES         = 3,
    LORE_LIBRARY        = 4,
    ACHIEVEMENTS        = 5,
    LEADERBOARDS        = 6,
}
local MENU_SOCIAL_ENTRIES =
{
    VOICE_CHAT  = 1,
    TEXT_CHAT   = 2,
    EMOTES      = 3,
    GROUP       = 4,
    GUILDS      = 5,
    FRIENDS     = 6,
    IGNORED     = 7,
    MAIL        = 8,
}

local function IsAnySubMenuNewCallback(entryData)
    for entryIndex, entry in ipairs(entryData.subMenu) do
        if entry:IsNew() then
            return true
        end
    end
    return false
end

local MENU_ENTRY_DATA =
{
    [MENU_MAIN_ENTRIES.CROWN_STORE] =
    {
        customTemplate = "ZO_GamepadMenuCrownStoreEntryTemplate",
        name = GetString(SI_GAMEPAD_MAIN_MENU_CROWN_STORE_CATEGORY),
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_PlayerMenu_icon_store.dds",
        header = zo_iconTextFormatNoSpace("EsoUI/Art/Market/Gamepad/gp_ESOPlus_Chalice_GOLD_64.dds", 32, 32, ZO_MARKET_PRODUCT_ESO_PLUS_COLOR:Colorize(GetString(SI_ESO_PLUS_TITLE))),
        postPadding = 70,
        showHeader = function() return IsESOPlusSubscriber() end,
        isNewCallback = IsAnySubMenuNewCallback,
        subLabelsNarrationText = function(entryData, entryControl)
            local narrations = {}
            table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(GetString(SI_GAMEPAD_MAIN_MENU_MARKET_BALANCE_TITLE)))
            table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_NUMBER_FORMAT, GetPlayerMarketCurrency(MKCT_CROWNS))))
            return narrations
        end,
        subMenu =
        {
            [MENU_CROWN_STORE_ENTRIES.CROWN_STORE] =
            {
                scene = "gamepad_market_pre_scene",
                sceneGroup = "gamepad_market_scenegroup",
                name = GetString(SI_GAMEPAD_MAIN_MENU_CROWN_STORE_ENTRY),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_PlayerMenu_icon_store.dds",
            },
            [MENU_CROWN_STORE_ENTRIES.EXPIRING_MARKET_CURRENCY] =
            {
                name = GetString(SI_GAMEPAD_MAIN_MENU_EXPIRING_CROWNS),
                icon = GetCurrencyGamepadIcon(CURT_CROWNS),
                isVisibleCallback = HasExpiringMarketCurrency,
                fragmentGroupCallback = function()
                    return { ZO_EXPIRING_MARKET_CURRENCY_GAMEPAD:GetFragment(), GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT }
                end,
                shouldDisableFunction = function()
                    return true
                end,
                narrationText = function(entryData, entryControl)
                    local narrations = {}
                    ZO_AppendNarration(narrations, ZO_GetSharedGamepadEntryDefaultNarrationText(entryData, entryControl))

                    ZO_AppendNarration(narrations, ZO_EXPIRING_MARKET_CURRENCY_GAMEPAD:GetNarrationText())
                    return narrations
                end,

            },
            [MENU_CROWN_STORE_ENTRIES.ENDEAVOR_SEAL_STORE] =
            {
                scene = "gamepad_endeavor_seal_market_pre_scene",
                sceneGroup = "gamepad_market_scenegroup",
                name = GetString(SI_GAMEPAD_MAIN_MENU_ENDEAVOR_SEAL_MARKET_ENTRY),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_PlayerMenu_icon_sealStore.dds",
            },
            [MENU_CROWN_STORE_ENTRIES.DAILY_LOGIN_REWARDS] =
            {
                name = GetString(SI_GAMEPAD_MAIN_MENU_DAILY_LOGIN_REWARDS_ENTRY),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_dailyLoginRewards.dds",
                shouldDisableFunction = function()
                    return ZO_DAILYLOGINREWARDS_MANAGER:IsDailyRewardsLocked() or not ZO_DAILYLOGINREWARDS_MANAGER:HasClaimableRewardInMonth()
                end,
                fragmentGroupCallback = function()
                    return {ZO_DAILY_LOGIN_REWARDS_GAMEPAD:GetFragment(), GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT}
                end,
                activatedCallback = function(self)
                    self:ActivateHelperPanel(ZO_DAILY_LOGIN_REWARDS_GAMEPAD)
                end,
                isNewCallback = function()
                    return GetDailyLoginClaimableRewardIndex() ~= nil
                end,
            },
            [MENU_CROWN_STORE_ENTRIES.CROWN_CRATES] =
            {
                scene = "crownCrateGamepad",
                name = GetString(SI_MAIN_MENU_CROWN_CRATES),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_crownCrates.dds",
                disableWhenDead = true,
                disableWhenReviving = true,
                disableWhenSwimming = true,
                disableWhenWerewolf = true,
                disableWhenPassenger = true,
                isNewCallback = function()
                    return GetNumOwnedCrownCrateTypes() > 0
                end,
                isVisibleCallback = function()
                    --An unusual case, we don't want to blow away this option if you're already in the scene when it's disabled
                    --Crown crates will properly refresh again when it closes its scene
                    return CanInteractWithCrownCratesSystem() or SYSTEMS:IsShowing("crownCrate")
                end,
            },
            [MENU_CROWN_STORE_ENTRIES.CHAPTERS] =
            {
                scene = "chapterUpgradeGamepad",
                sceneGroup = "gamepad_chapterUpgrade_scenegroup",
                name = GetString(SI_MAIN_MENU_CHAPTERS),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_chapters.dds",
                isVisibleCallback = function()
                    return ZO_CHAPTER_UPGRADE_MANAGER:GetNumChapterUpgrades() > 0
                end,
            },
            [MENU_CROWN_STORE_ENTRIES.GIFT_INVENTORY] =
            {
                scene = "giftInventoryGamepad",
                name = GetString(SI_MAIN_MENU_GIFT_INVENTORY),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_giftInventory.dds",
                isNewCallback = function()
                    return GIFT_INVENTORY_MANAGER and GIFT_INVENTORY_MANAGER:HasAnyUnseenGifts()
                end,
            },
            [MENU_CROWN_STORE_ENTRIES.REDEEM_CODE] =
            {
                scene = "codeRedemptionGamepad",
                name = GetString(SI_MAIN_MENU_REDEEM_CODE),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_redeemCode.dds",
                isVisibleCallback = DoesPlatformSupportCodeRedemption,
            },
        },
    },
    [MENU_MAIN_ENTRIES.ANNOUNCEMENTS] =
    {
        name = GetString(SI_MAIN_MENU_ANNOUNCEMENTS),
        icon = "EsoUI/Art/AnnounceWindow/gamepad/gp_announcement_Icon.dds",
        activatedCallback = function()
            SCENE_MANAGER:Show("marketAnnouncement")
            RequestMarketAnnouncement()
        end,
    },
    [MENU_MAIN_ENTRIES.NOTIFICATIONS] =
    {
        scene = "gamepad_notifications_root",
        name = function()
            local numNotifications = GAMEPAD_NOTIFICATIONS and GAMEPAD_NOTIFICATIONS:GetNumNotifications() or 0
            return zo_strformat(SI_GAMEPAD_MAIN_MENU_NOTIFICATIONS, numNotifications)
        end,
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_notifications.dds",
        isNewCallback = function()
            return true --new icon indicator should always display
        end,
        isVisibleCallback = function()
            if GAMEPAD_NOTIFICATIONS then
                return GAMEPAD_NOTIFICATIONS:GetNumNotifications() > 0
            else
                return false
            end
        end,
    },
    [MENU_MAIN_ENTRIES.COLLECTIONS] =
    {
        customTemplate = "ZO_GamepadMenuEntryTemplateWithArrow",
        name = GetString(SI_MAIN_MENU_COLLECTIONS),
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_collections.dds",
        isNewCallback = IsAnySubMenuNewCallback,
        subMenu =
        {
            [MENU_COLLECTIONS_ENTRIES.COLLECTIONS] =
            {
                scene = "gamepadCollectionsBook",
                name = GetString(SI_MAIN_MENU_COLLECTIONS),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_collections.dds",
                header = GetString(SI_MAIN_MENU_COLLECTIONS),
                isNewCallback = function()
                    local newCollectibles = GetNumNewCollectibles()
                    local newPatronCollectibles = GetNumNewCollectiblesByCategoryType(COLLECTIBLE_CATEGORY_TYPE_TRIBUTE_PATRON)
                    return newCollectibles > newPatronCollectibles
                end,
            },
            [MENU_COLLECTIONS_ENTRIES.ITEM_SETS] =
            {
                scene = "gamepadItemSetsBook",
                name = GetString(SI_ITEM_SETS_BOOK_TITLE),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_itemSetCollections.dds",
                isNewCallback = function()
                    return ITEM_SET_COLLECTIONS_DATA_MANAGER:HasAnyNewPieces()
                end,
            },
            [MENU_COLLECTIONS_ENTRIES.TRIBUTE_PATRONS] =
            {
                scene = "gamepadTributePatronBook",
                name = GetString(SI_TRIBUTE_PATRON_BOOK_TITLE),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_tributePatrons.dds",
                isNewCallback = function()
                    local newPatronCollectibles = GetNumNewCollectiblesByCategoryType(COLLECTIBLE_CATEGORY_TYPE_TRIBUTE_PATRON)
                    return newPatronCollectibles > 0
                end,
            },
        }
    },
    [MENU_MAIN_ENTRIES.INVENTORY] =
    {
        scene = "gamepad_inventory_root",
        name = GetString(SI_MAIN_MENU_INVENTORY),
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_inventory.dds",
        isNewCallback = function()
            return SHARED_INVENTORY:AreAnyItemsNew(nil, nil, BAG_BACKPACK, BAG_VIRTUAL)
        end,
    },
    [MENU_MAIN_ENTRIES.CHARACTER] =
    {
        scene = "gamepad_stats_root",
        name = GetString(SI_MAIN_MENU_CHARACTER),
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_character.dds",
        canLevel = function()
            return HasPendingLevelUpReward() or GetAttributeUnspentPoints() > 0
        end
    },
    [MENU_MAIN_ENTRIES.SKILLS] =
    {
        scene = "gamepad_skills_root",
        customTemplate = "ZO_GamepadNewAnimatingMenuEntryTemplate",
        name = GetString(SI_MAIN_MENU_SKILLS),
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_skills.dds",
        canLevel = function()
            return GetAvailableSkillPoints() > 0
        end,
        isNewCallback =  function()
            return SKILLS_DATA_MANAGER and SKILLS_DATA_MANAGER:AreAnyPlayerSkillLinesOrAbilitiesNew()
        end,
    },
    [MENU_MAIN_ENTRIES.CHAMPION] =
    {
        scene = "gamepad_championPerks_root",
        name = GetString(SI_MAIN_MENU_CHAMPION),
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_champion.dds",
        isNewCallback = function()
            if CHAMPION_PERKS then
                return CHAMPION_PERKS:IsChampionSystemNew()
            end
        end,
        isVisibleCallback = function()
            return IsChampionSystemUnlocked()
        end,
        canLevel = function()
            if CHAMPION_DATA_MANAGER then
                return CHAMPION_DATA_MANAGER:HasAnySavedUnspentPoints()
            end
        end,
    },
    [MENU_MAIN_ENTRIES.CAMPAIGN] =
    {
        scene = "gamepad_campaign_root",
        name = GetString(SI_PLAYER_MENU_CAMPAIGNS),
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_allianceWar.dds",
        isNewCallback = function()
            local tutorialId = GetTutorialId(TUTORIAL_TRIGGER_CAMPAIGN_BROWSER_OPENED)
            if CanTutorialBeSeen(tutorialId) then
                return not HasSeenTutorial(tutorialId)
            end
            return false
        end,
        isVisibleCallback = function()
            local currentLevel = GetUnitLevel("player")
            return currentLevel >= GetMinLevelForCampaignTutorial()
        end,
    },
    [MENU_MAIN_ENTRIES.JOURNAL] =
    {
        customTemplate = "ZO_GamepadMenuEntryTemplateWithArrow",
        name = GetString(SI_MAIN_MENU_JOURNAL),
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_journal.dds",
        isNewCallback = IsAnySubMenuNewCallback,
        subMenu =
        {
            [MENU_JOURNAL_ENTRIES.QUESTS] =
            {
                scene = "gamepad_quest_journal",
                name = GetString(SI_GAMEPAD_MAIN_MENU_JOURNAL_QUESTS),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_quests.dds",
                header = GetString(SI_MAIN_MENU_JOURNAL),
            },
            [MENU_JOURNAL_ENTRIES.CADWELLS_JOURNAL] =
            {
                scene = "cadwellGamepad",
                name = GetString(SI_GAMEPAD_MAIN_MENU_JOURNAL_CADWELL),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_cadwell.dds",
                isVisibleCallback = function()
                    return GetCadwellProgressionLevel() > CADWELL_PROGRESSION_LEVEL_BRONZE
                end,
            },
            [MENU_JOURNAL_ENTRIES.ANTIQUITIES] =
            {
                scene = "gamepad_antiquity_journal",
                name = GetString(SI_JOURNAL_MENU_ANTIQUITIES),
                icon = "EsoUI/Art/Journal/Gamepad/GP_journal_tabIcon_antiquities.dds",
                isNewCallback = function()
                    return ANTIQUITY_DATA_MANAGER and ANTIQUITY_DATA_MANAGER:HasNewLead()
                end,
            },
            [MENU_JOURNAL_ENTRIES.LORE_LIBRARY] =
            {
                scene = "loreLibraryGamepad",
                name = GetString(SI_GAMEPAD_MAIN_MENU_JOURNAL_LORE_LIBRARY),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_loreLibrary.dds",
            },
            [MENU_JOURNAL_ENTRIES.ACHIEVEMENTS] =
            {
                scene = "achievementsGamepad",
                name = GetString(SI_GAMEPAD_MAIN_MENU_JOURNAL_ACHIEVEMENTS),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_achievements.dds",
            },
            [MENU_JOURNAL_ENTRIES.LEADERBOARDS] =
            {
                scene = "gamepad_leaderboards",
                name = GetString(SI_JOURNAL_MENU_LEADERBOARDS),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_leaderBoards.dds",
            },
        }
    },
    [MENU_MAIN_ENTRIES.SOCIAL] =
    {
        customTemplate = "ZO_GamepadMenuEntryTemplateWithArrow",
        name = GetString(SI_MAIN_MENU_SOCIAL),
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_multiplayer.dds",
        isNewCallback = IsAnySubMenuNewCallback,
        subMenu =
        {
            [MENU_SOCIAL_ENTRIES.VOICE_CHAT] =
            {
                scene = "gamepad_voice_chat",
                name = GetString(SI_MAIN_MENU_GAMEPAD_VOICECHAT),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_communications.dds",
                header = GetString(SI_MAIN_MENU_SOCIAL),
                isVisibleCallback = IsConsoleUI
            },
            [MENU_SOCIAL_ENTRIES.TEXT_CHAT] =
            {
                scene = "gamepadChatMenu",
                name = GetString(SI_GAMEPAD_TEXT_CHAT),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_textChat.dds",
                header = not IsConsoleUI() and GetString(SI_MAIN_MENU_SOCIAL) or nil,
                isVisibleCallback = IsChatSystemAvailableForCurrentPlatform
            },
            [MENU_SOCIAL_ENTRIES.EMOTES] =
            {
                scene = "gamepad_player_emote",
                name = GetString(SI_GAMEPAD_MAIN_MENU_EMOTES),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_emotes.dds",
                header = (not IsConsoleUI() and not IsChatSystemAvailableForCurrentPlatform()) and GetString(SI_MAIN_MENU_SOCIAL) or nil,
            },
            [MENU_SOCIAL_ENTRIES.GROUP] =
            {
                scene = "gamepad_groupList",
                name = GetString(SI_PLAYER_MENU_GROUP),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_groups.dds",
            },
            [MENU_SOCIAL_ENTRIES.GUILDS] =
            {
                scene = "gamepad_guild_hub",
                name = GetString(SI_MAIN_MENU_GUILDS),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_guilds.dds",
            },
            [MENU_SOCIAL_ENTRIES.FRIENDS] =
            {
                scene = "gamepad_friends",
                name = GetString(SI_GAMEPAD_CONTACTS_FRIENDS_LIST_TITLE),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_contacts.dds",
            },
            [MENU_SOCIAL_ENTRIES.IGNORED] =
            {
                scene = "gamepad_ignored",
                name = GetString(SI_GAMEPAD_CONTACTS_IGNORED_LIST_TITLE),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_contacts.dds",
                isVisibleCallback = function()
                    return not IsConsoleUI()
                end,
            },
            [MENU_SOCIAL_ENTRIES.MAIL] =
            {
                scene = "mailGamepad",
                name = GetString(SI_MAIN_MENU_MAIL),
                icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_mail.dds",
                isNewCallback = function()
                    return HasUnreadMail()
                end,
                disableWhenDead = true,
                disableWhenInCombat = true,
                disableWhenReviving = true,
            },
        }
    },
    [MENU_MAIN_ENTRIES.ACTIVITY_FINDER] =
    {
        scene = ZO_GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE_NAME,
        name = GetString(SI_MAIN_MENU_ACTIVITY_FINDER),
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_activityFinder.dds",
        isActivityFinder = true,
        isNewCallback =  function()
            if ZO_HasGroupFinderNewApplication() then
                return true
            elseif not IsPromotionalEventSystemLocked() then
                local currentCampaignData = PROMOTIONAL_EVENT_MANAGER:GetCurrentCampaignData()
                return currentCampaignData and (not currentCampaignData:HasBeenSeen() or currentCampaignData:IsAnyRewardClaimable())
            end
            return false
        end,
    },
    [MENU_MAIN_ENTRIES.HELP] =
    {
        scene = "helpRootGamepad",
        name = GetString(SI_MAIN_MENU_HELP),
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_help.dds",
    },
    [MENU_MAIN_ENTRIES.OPTIONS] =
    {
        scene = "gamepad_options_root",
        name = GetString(SI_GAMEPAD_OPTIONS_MENU),
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_settings.dds",
    },
    [MENU_MAIN_ENTRIES.LOG_OUT] =
    {
        name = GetString(SI_GAME_MENU_LOGOUT),
        icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_logout.dds",
        activatedCallback = function()
            ZO_Dialogs_ShowGamepadDialog("GAMEPAD_LOG_OUT")
        end,
    },
}

CATEGORY_TO_ENTRY_DATA =
{
    [MENU_CATEGORY_NOTIFICATIONS]   = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.NOTIFICATIONS],
    [MENU_CATEGORY_MARKET]          = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.CROWN_STORE].subMenu[MENU_CROWN_STORE_ENTRIES.CROWN_STORE],
    [MENU_CATEGORY_CROWN_CRATES]    = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.CROWN_STORE].subMenu[MENU_CROWN_STORE_ENTRIES.CROWN_CRATES],
    [MENU_CATEGORY_GIFT_INVENTORY]  = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.CROWN_STORE].subMenu[MENU_CROWN_STORE_ENTRIES.GIFT_INVENTORY],
    [MENU_CATEGORY_COLLECTIONS]     = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.COLLECTIONS].subMenu[MENU_COLLECTIONS_ENTRIES.COLLECTIONS],
    [MENU_CATEGORY_INVENTORY]       = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.INVENTORY],
    [MENU_CATEGORY_CHARACTER]       = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.CHARACTER],
    [MENU_CATEGORY_SKILLS]          = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.SKILLS],
    [MENU_CATEGORY_CHAMPION]        = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.CHAMPION],
    [MENU_CATEGORY_ALLIANCE_WAR]    = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.CAMPAIGN],
    [MENU_CATEGORY_JOURNAL]         = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.JOURNAL].subMenu[MENU_JOURNAL_ENTRIES.QUESTS],
    [MENU_CATEGORY_GROUP]           = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.SOCIAL].subMenu[MENU_SOCIAL_ENTRIES.GROUP],
    [MENU_CATEGORY_CONTACTS]        = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.SOCIAL].subMenu[MENU_SOCIAL_ENTRIES.FRIENDS],
    [MENU_CATEGORY_GUILDS]          = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.SOCIAL].subMenu[MENU_SOCIAL_ENTRIES.GUILDS],
    [MENU_CATEGORY_MAIL]            = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.SOCIAL].subMenu[MENU_SOCIAL_ENTRIES.MAIL],
    [MENU_CATEGORY_ACTIVITY_FINDER] = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.ACTIVITY_FINDER],
    [MENU_CATEGORY_HELP]            = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.HELP],
    [MENU_CATEGORY_MAP]             = { scene = "gamepad_worldMap" }, --no gamepad menu entry for world map
}

local function CreateEntry(data)
    local name = data.name
    if type(name) == "function" then
        name = "" --will be updated whenever the list is generated
    end

    local entry = ZO_GamepadEntryData:New(name, data.icon, nil, nil, data.isNewCallback)
    entry:SetIconTintOnSelection(true)
    entry:SetIconDisabledTintOnSelection(true)

    local header = data.header
    if header then
        entry:SetHeader(header)
    end

    entry.canLevel = data.canLevel
    entry.narrationText = data.narrationText
    entry.subLabelsNarrationText = data.subLabelsNarrationText

    entry.data = data
    return entry
end

for menuEntryId, data in ipairs(MENU_ENTRY_DATA) do
    local newEntry = CreateEntry(data)

    newEntry.id = menuEntryId
    if data.subMenu then
        newEntry.subMenu = {}
        for submenuEntryId, subMenuData in ipairs(data.subMenu) do
            local newSubMenuEntry = CreateEntry(subMenuData)
            newSubMenuEntry.id = submenuEntryId
            table.insert(newEntry.subMenu, newSubMenuEntry)
        end
    end

    table.insert(ZO_MENU_ENTRIES, newEntry)
end

local MODE_MAIN_LIST = 1
local MODE_SUBLIST = 2
--
--[[ ZO_MainMenuManager_Gamepad ]]--
--
local ZO_MainMenuManager_Gamepad = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_MainMenuManager_Gamepad:New(control)
    return ZO_Gamepad_ParametricList_Screen.New(self, control)
end

function ZO_MainMenuManager_Gamepad:Initialize(control)
    MAIN_MENU_GAMEPAD_SCENE = ZO_Scene:New("mainMenuGamepad", SCENE_MANAGER)
    PLAYER_SUBMENU_SCENE = ZO_Scene:New("playerSubmenu", SCENE_MANAGER)

    local DONT_ACTIVATE_ON_SHOW = false
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, DONT_ACTIVATE_ON_SHOW, MAIN_MENU_GAMEPAD_SCENE)
    control.header:SetHidden(true)

    self.mainList = self:GetMainList()
    self.subList = self:AddList("Submenu")
    self.lastList = self.mainList
    self:ReanchorListsOverHeader()
    self.mode = MODE_MAIN_LIST

    self:SetListsUseTriggerKeybinds(true)

    local function RefreshLists()
        self:RefreshLists()
    end

    control:RegisterForEvent(EVENT_LEVEL_UPDATE, RefreshLists)
    control:AddFilterForEvent(EVENT_LEVEL_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
    control:RegisterForEvent(EVENT_CADWELL_PROGRESSION_LEVEL_CHANGED, RefreshLists)
    control:RegisterForEvent(EVENT_PROMOTIONAL_EVENTS_ACTIVITY_PROGRESS_UPDATED, RefreshLists)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("RewardsClaimed", RefreshLists)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignSeenStateChanged", RefreshLists)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignsUpdated", RefreshLists)

    PLAYER_SUBMENU_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.mode = MODE_SUBLIST
        end
        ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
    end)
    MAIN_MENU_MANAGER:RegisterCallback("OnPlayerStateUpdate", function() self:UpdateEntryEnabledStates() end)
    control:RegisterForEvent(EVENT_DAILY_LOGIN_REWARDS_UPDATED, function() self:UpdateEntryEnabledStates() end)
    control:RegisterForEvent(EVENT_NEW_DAILY_LOGIN_REWARD_AVAILABLE, function() self:UpdateEntryEnabledStates() end)
    control:RegisterForEvent(EVENT_DAILY_LOGIN_REWARDS_CLAIMED, function() self:UpdateEntryEnabledStates() end)

    local function OnBlockingSceneCleared(nextSceneData, showBaseScene)
        if IsInGamepadPreferredMode() then
            if showBaseScene then
                SCENE_MANAGER:ShowBaseScene()
            elseif nextSceneData then
                if nextSceneData.sceneName then
                    self:ToggleScene(nextSceneData.sceneName)
                elseif nextSceneData.category then
                    self:ToggleCategory(nextSceneData.category)
                end
            end
        end
    end

    MAIN_MENU_MANAGER:RegisterCallback("OnBlockingSceneCleared", OnBlockingSceneCleared)
end

function ZO_MainMenuManager_Gamepad:OnShowing()
    self:RefreshLists()
    -- Both MAIN_MENU_GAMEPAD_SCENE and PLAYER_SUBMENU_SCENE use OnShowing to set the active list, which also adds the appropriate list fragment to the scene
    -- Two separate scenes are needed for this to properly control the direction the fragments conveyor in and out.
    self:SetCurrentList(self.mode == MODE_SUBLIST and self.subList or self.mainList)

    -- This is to set the Daily Rewards panel to selected if we entered the main menu from the Daily Rewards Preview. 
    -- (ie. we backed out of a preview we entered from a selected Daily Reward screen)
    if SCENE_MANAGER:GetPreviousSceneName() == "dailyLoginRewardsPreview_Gamepad" then
        self:SwitchToSelectedScene(self:GetCurrentList())
    end
end

function ZO_MainMenuManager_Gamepad:OnHiding()
    self.mode = MODE_MAIN_LIST
    self:DeactivateHelperPanel()
end

do
    local function ReanchorList(list)
        local control = list:GetControl()
        local container = control:GetParent()
        control:ClearAnchors()
        control:SetAnchorFill(container)
    end

    function ZO_MainMenuManager_Gamepad:ReanchorListsOverHeader()
        ReanchorList(self.mainList)
        ReanchorList(self.subList)
    end
end

do
    local function NewMenuEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        if data.data.isActivityFinder and PROMOTIONAL_EVENT_MANAGER:IsCampaignActive() and not IsPromotionalEventSystemLocked() then
            data:SetNameColors(ZO_PROMOTIONAL_EVENT_SELECTED_COLOR, ZO_PROMOTIONAL_EVENT_UNSELECTED_COLOR)
            data:SetIconTint(ZO_PROMOTIONAL_EVENT_SELECTED_COLOR, ZO_PROMOTIONAL_EVENT_UNSELECTED_COLOR)
        else
            data:SetNameColors(ZO_GAMEPAD_SELECTED_COLOR, ZO_GAMEPAD_UNSELECTED_COLOR)
            data:SetIconTint(ZO_GAMEPAD_SELECTED_COLOR, ZO_GAMEPAD_UNSELECTED_COLOR)
        end

        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end

    local function AnimatingLabelEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        local totalSpendablePoints = GetAttributeUnspentPoints()
    
        if totalSpendablePoints ~= nil then
            local shouldAnimate = totalSpendablePoints > 0
            local animatingControl = control.label
            local animatingControlTimeline = animatingControl.animationTimeline
            local isAnimating = animatingControlTimeline:IsPlaying()
            if(shouldAnimate ~= isAnimating) then
                animatingControl:SetText(animatingControl.text[1])
                if(shouldAnimate) then
                    animatingControl.textIndex = 1
                    animatingControlTimeline:PlayFromStart()
                else
                    animatingControlTimeline:Stop()
                    animatingControl:SetAlpha(1)
                end
            end
        end
    end

    local function EntryWithSubMenuSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

        local color = data:GetNameColor(selected)
        if type(color) == "function" then
            color = color(data)
        end
        control:GetNamedChild("Arrow"):SetColor(color:UnpackRGBA())
    end

    local function CrownStoreEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, active)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)

        local balanceLabel = control:GetNamedChild("Balance")
        balanceLabel:SetText(GetString(SI_GAMEPAD_MAIN_MENU_MARKET_BALANCE_TITLE))

        local remainingCrownsLabel = control:GetNamedChild("RemainingCrowns")
        local currencyString = zo_strformat(SI_NUMBER_FORMAT, GetPlayerMarketCurrency(MKCT_CROWNS))
        remainingCrownsLabel:SetText(currencyString)

        local color = data:GetNameColor(selected)
        if type(color) == "function" then
            color = color(data)
        end
        control:GetNamedChild("Arrow"):SetColor(color:UnpackRGBA())
    end

    function ZO_MainMenuManager_Gamepad:SetupList(list)
        list:AddDataTemplate("ZO_GamepadNewMenuEntryTemplate", NewMenuEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadNewMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

        list:AddDataTemplate("ZO_GamepadMenuEntryTemplateWithArrow", EntryWithSubMenuSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplateWithArrow", EntryWithSubMenuSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")

        list:AddDataTemplate("ZO_GamepadNewAnimatingMenuEntryTemplate", AnimatingLabelEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

        list:AddDataTemplate("ZO_GamepadMenuCrownStoreEntryTemplate", CrownStoreEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadMenuCrownStoreEntryTemplate", CrownStoreEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadCrownStoreMenuEntryHeaderTemplate")
    end
end

local function ShouldDisableEntry(entryData)
    if entryData.disableWhenDead and MAIN_MENU_MANAGER:IsPlayerDead() then
        return true
    elseif entryData.disableWhenInCombat and MAIN_MENU_MANAGER:IsPlayerInCombat() then
        return true
    elseif entryData.disableWhenReviving and MAIN_MENU_MANAGER:IsPlayerReviving() then
        return true
    elseif entryData.disableWhenSwimming and MAIN_MENU_MANAGER:IsPlayerSwimming() then
        return true
    elseif entryData.disableWhenWerewolf and MAIN_MENU_MANAGER:IsPlayerWerewolf() then
        return true
    elseif entryData.disableWhenPassenger and MAIN_MENU_MANAGER:IsPlayerPassenger() then
        return true
    elseif entryData.shouldDisableFunction and entryData.shouldDisableFunction() then
        return true
    end

    return false
end

function ZO_MainMenuManager_Gamepad:UpdateEntryEnabledStates()
    local function UpdateState(entry)
        if ShouldDisableEntry(entry.data) then
            entry:SetEnabled(false)

            if self:IsEntrySceneShowing(entry.data) then
                SCENE_MANAGER:ShowBaseScene()
            end
        else
            entry:SetEnabled(true)
        end
    end

    for _, entry in ipairs(ZO_MENU_ENTRIES) do
        UpdateState(entry)
        if entry.subMenu then
            for _, subMenuEntry in ipairs(entry.subMenu) do
                UpdateState(subMenuEntry)
            end
        end
    end

    self:RefreshLists()
end


function ZO_MainMenuManager_Gamepad:RefreshLists()
    if self.mode == MODE_MAIN_LIST then
        self:RefreshMainList()
    else
        local entry = self.mainList:GetTargetData()
        self:RefreshSubList(entry)
    end
end

function ZO_MainMenuManager_Gamepad:OnDeferredInitialize()
    local function MarkNewnessDirty()
        self:MarkNewnessDirty()
    end

    self.exitHelperPanelFunction = function()
        self:DeactivateHelperPanel()
    end

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", MarkNewnessDirty)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", MarkNewnessDirty)
    EVENT_MANAGER:RegisterForEvent("mainMenuGamepad", EVENT_LEVEL_UPDATE, MarkNewnessDirty)
    EVENT_MANAGER:RegisterForEvent("mainMenuGamepad", EVENT_MAIL_NUM_UNREAD_CHANGED, MarkNewnessDirty)
    GIFT_INVENTORY_MANAGER:RegisterCallback("GiftListsChanged", MarkNewnessDirty)
    EVENT_MANAGER:RegisterForEvent("mainMenuGamepad", EVENT_NEW_DAILY_LOGIN_REWARD_AVAILABLE, MarkNewnessDirty)
    EVENT_MANAGER:RegisterForEvent("mainMenuGamepad", EVENT_DAILY_LOGIN_REWARDS_CLAIMED, MarkNewnessDirty)

    self:UpdateEntryEnabledStates()
end

function ZO_MainMenuManager_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_MAIN_MENU_GAMEPAD_VOICECHAT),
            keybind = "UI_SHORTCUT_TERTIARY",
            callback = function() SCENE_MANAGER:Push("gamepad_voice_chat") end,
            visible = IsConsoleUI,
        },
        {
            name = GetString(SI_GAMEPAD_TEXT_CHAT),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() SCENE_MANAGER:Push("gamepadChatMenu") end,
            visible = IsChatSystemAvailableForCurrentPlatform,
        }
    }

    local  function IsForwardNavigationEnabled()
        local currentList = self:GetCurrentList() 
        local entry = currentList and currentList:GetTargetData()
        return entry and entry:IsEnabled()
    end

    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:SwitchToSelectedScene(self:GetCurrentList()) end, nil, nil, IsForwardNavigationEnabled)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function()
        if self:IsCurrentList(self.mainList) then
            self:Exit()
        else
            SCENE_MANAGER:HideCurrentScene()
        end
    end)
end

function ZO_MainMenuManager_Gamepad:SwitchToSelectedScene(list)
    local entry = list:GetTargetData()
    
    if entry.enabled then
        local entryData = entry.data
        local scene = entryData.scene
        local activatedCallback = entryData.activatedCallback

        if scene then
            list:SetActive(false)
            SCENE_MANAGER:Push(scene)
        elseif entryData.subMenu then
            list:SetActive(false)
            SCENE_MANAGER:Push("playerSubmenu")
        elseif activatedCallback then
            activatedCallback(self)
        end

    else
        PlaySound(SOUNDS.PLAYER_MENU_ENTRY_DISABLED)
    end
end

function ZO_MainMenuManager_Gamepad:Exit()
    SCENE_MANAGER:Hide("mainMenuGamepad")
end

do
    local DEFAULT_MENU_ENTRY_SCENE_NAME = "gamepad_inventory_root"

    local function AddEntryToList(list, entry, menuEntryToEntryIndex)
        local entryData = entry.data

        if not entryData.isVisibleCallback or entryData.isVisibleCallback() then
            local customTemplate = entryData.customTemplate
            local postPadding = entryData.postPadding or 0
            local entryTemplate = customTemplate and customTemplate or "ZO_GamepadNewMenuEntryTemplate"
       
            local showHeader = entryData.showHeader
            local useHeader = entry.header
            if type(showHeader) == "function" then
                useHeader = showHeader()
            elseif type(showHeader) == "boolean" then
                useHeader = showHeader
            end

            local name = entryData.name
            if type(name) == "function" then
                entry:SetText(name())
            end

            if useHeader then
                list:AddEntryWithHeader(entryTemplate, entry, 0, postPadding)
            else
                list:AddEntry(entryTemplate, entry, 0, postPadding)
            end
            menuEntryToEntryIndex[entry.id] = list:GetNumEntries()

            return true
        end
        return false
    end

    function ZO_MainMenuManager_Gamepad:RefreshMainList()
        self.mainList:Clear()

        self.mainMenuEntryToListIndex = {}
        -- if we haven't yet initialized, set the default selection
        -- we only need to default the first time the Player Menu is shown
        -- so as soon as we init, we don't need to update this any more
        if self.initialized then
            for _, entry in ipairs(ZO_MENU_ENTRIES) do
                AddEntryToList(self.mainList, entry, self.mainMenuEntryToListIndex)
            end
        else
            --The entry we want to start on may not be at the top, and its index can be variable since entries are contextually visible
            local currentMenuIndex = 0
            local defaultEntryIndex = 1
            for _, entry in ipairs(ZO_MENU_ENTRIES) do
                if AddEntryToList(self.mainList, entry, self.mainMenuEntryToListIndex) then
                    currentMenuIndex = currentMenuIndex + 1
                    if entry.data.scene == DEFAULT_MENU_ENTRY_SCENE_NAME then
                        defaultEntryIndex = currentMenuIndex
                    end
                end
            end

            self.mainList:SetDefaultSelectedIndex(defaultEntryIndex)
        end
        self.mainList:Commit()
    end

    function ZO_MainMenuManager_Gamepad:RefreshSubList(mainListEntry)
        self.subList:Clear()
        self.subMenuEntryToListIndex = {}

        if mainListEntry and mainListEntry.subMenu then
            for _, entry in ipairs(mainListEntry.subMenu) do
                AddEntryToList(self.subList, entry, self.subMenuEntryToListIndex)
            end
        end

        self.subList:Commit()
    end
end

function ZO_MainMenuManager_Gamepad:OnSelectionChanged(list, selectedData, oldSelectedData)
    if list == self.subList then
        if oldSelectedData and oldSelectedData.data.fragmentGroupCallback then
            local fragmentGroup = oldSelectedData.data.fragmentGroupCallback()
            SCENE_MANAGER:RemoveFragmentGroup(fragmentGroup)
        end

        if selectedData and selectedData.data.fragmentGroupCallback then
            local fragmentGroup = selectedData.data.fragmentGroupCallback()
            SCENE_MANAGER:AddFragmentGroup(fragmentGroup)
        end
    end
end

function ZO_MainMenuManager_Gamepad:ActivateHelperPanel(panel)
    self:DeactivateCurrentList()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self.activeHelperPanel = panel
    panel:RegisterCallback("PanelSelectionEnd", self.exitHelperPanelFunction)
    panel:Activate()
end

function ZO_MainMenuManager_Gamepad:DeactivateHelperPanel()
    if self.activeHelperPanel then
        self.activeHelperPanel:Deactivate()
        if self:IsShowing() then
            self:ActivateCurrentList()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
        end
        self.activeHelperPanel:UnregisterCallback("PanelSelectionEnd", self.exitHelperPanelFunction)
        self.activeHelperPanel = nil
    end
end

function ZO_MainMenuManager_Gamepad:IsShowing()
    return SCENE_MANAGER:IsShowing("mainMenuGamepad") or SCENE_MANAGER:IsShowing("playerSubmenu")
end

function ZO_MainMenuManager_Gamepad:ShowLastCategory()
    SCENE_MANAGER:Show("mainMenuGamepad")
end

function ZO_MainMenuManager_Gamepad:MarkNewnessDirty()
    if self:IsShowing() then
        self:RefreshLists()
    end
end

function ZO_MainMenuManager_Gamepad:OnNumNotificationsChanged(numNotifications)
    self:MarkNewnessDirty()
end

function ZO_MainMenuManager_Gamepad:IsEntrySceneShowing(entryData)
    if entryData.sceneGroup then
        if SCENE_MANAGER:IsSceneGroupShowing(entryData.sceneGroup) then
            return true
        end
    end

    if entryData.additionalScenes then
        for _, scene in ipairs(entryData.additionalScenes) do
            if SCENE_MANAGER:IsShowing(scene) then
                return true
            end
        end
    end

    return SCENE_MANAGER:IsShowing(entryData.scene)
end

function ZO_MainMenuManager_Gamepad:ToggleCategory(category)
    local entryData = CATEGORY_TO_ENTRY_DATA[category]

    if self:IsEntrySceneShowing(entryData) then
        SCENE_MANAGER:ShowBaseScene()
    else
        if entryData.isVisibleCallback and not entryData.isVisibleCallback() then
            return
        end

        if ShouldDisableEntry(entryData) then
            return
        end

        self:ToggleScene(entryData.scene)
    end
end

function ZO_MainMenuManager_Gamepad:ShowCategory(category)
    self:ShowScene(CATEGORY_TO_ENTRY_DATA[category].scene)
end

function ZO_MainMenuManager_Gamepad:ShowScene(sceneName)
    if MAIN_MENU_MANAGER:HasBlockingScene() then
        local sceneData = {
            sceneName = sceneName,
        }
        MAIN_MENU_MANAGER:ActivatedBlockingScene_Scene(sceneData)
    else
        SCENE_MANAGER:Show(sceneName)
    end
end

function ZO_MainMenuManager_Gamepad:ToggleScene(sceneName)
    if MAIN_MENU_MANAGER:HasBlockingScene() then
        local sceneData = {
            sceneName = sceneName,
        }
        MAIN_MENU_MANAGER:ActivatedBlockingScene_Scene(sceneData)
    else
        SCENE_MANAGER:Toggle(sceneName)
    end
end

function ZO_MainMenuManager_Gamepad:AttemptShowBaseScene()
    if MAIN_MENU_MANAGER:HasBlockingScene() then
        MAIN_MENU_MANAGER:ActivatedBlockingScene_BaseScene()
    else
        SCENE_MANAGER:ShowBaseScene()
    end
end

function ZO_MainMenuManager_Gamepad:ShowExpiringMarketCurrencyEntry()
    self:SelectMenuEntryAndSubEntry(MENU_MAIN_ENTRIES.CROWN_STORE, MENU_CROWN_STORE_ENTRIES.EXPIRING_MARKET_CURRENCY)
end

function ZO_MainMenuManager_Gamepad:ShowDailyLoginRewardsEntry()
    self:SelectMenuEntryAndSubEntry(MENU_MAIN_ENTRIES.CROWN_STORE, MENU_CROWN_STORE_ENTRIES.DAILY_LOGIN_REWARDS)
end

function ZO_MainMenuManager_Gamepad:ShowAntiquityJournal()
    self:SelectMenuEntryAndSubEntry(MENU_MAIN_ENTRIES.JOURNAL, MENU_JOURNAL_ENTRIES.ANTIQUITIES, "gamepad_antiquity_journal")
end

function ZO_MainMenuManager_Gamepad:ShowScryableAntiquities()
    ANTIQUITY_JOURNAL_GAMEPAD:QueueBrowseToScryable()
    self:ShowAntiquityJournal()
end

function ZO_MainMenuManager_Gamepad:ShowAntiquityInJournal(antiquityData)
    ANTIQUITY_JOURNAL_GAMEPAD:QueueBrowseToAntiquityOrSetData(antiquityData)
    self:ShowAntiquityJournal()
end

function ZO_MainMenuManager_Gamepad:ShowGroupMenu()
    self:SelectMenuEntryAndSubEntry(MENU_MAIN_ENTRIES.SOCIAL, MENU_SOCIAL_ENTRIES.GROUP, "gamepad_groupList")
end

function ZO_MainMenuManager_Gamepad:SelectMenuEntry(menuEntry)
    self.mainList:SetSelectedIndexWithoutAnimation(self.mainMenuEntryToListIndex[menuEntry])
end

function ZO_MainMenuManager_Gamepad:SelectMenuEntryAndSubEntry(menuEntry, menuSubEntry, sceneName)
    self:SelectMenuEntry(menuEntry)
    local entry = self.mainList:GetTargetData()
    self:RefreshSubList(entry)

    -- the given subeEntry may not be currently visible and not exist in subMenuEntryToListIndex
    local subListIndex = self.subMenuEntryToListIndex[menuSubEntry]
    if subListIndex then
        self.subList:SetSelectedIndexWithoutAnimation(subListIndex)
    end

    if sceneName then
        SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "playerSubmenu", sceneName)
    else
        SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "playerSubmenu")
    end
end

function ZO_MainMenuManager_Gamepad:ShowZoneStoriesEntry(createFullStack)
    local zoneStoriesSceneName = "zoneStoriesGamepad"

    self:SelectMenuEntry(MENU_MAIN_ENTRIES.ACTIVITY_FINDER)
    local mainList = ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:GetMainList()
    for i = 1, mainList:GetNumEntries() do
        local entryData = mainList:GetEntryData(i)
        if entryData.data.sceneName and entryData.data.sceneName == zoneStoriesSceneName then
            mainList:SetSelectedIndexWithoutAnimation(i)
            break
        end
    end

    if createFullStack then
        SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", ZO_GAMEPAD_ACTIVITY_FINDER_ROOT_SCENE_NAME, zoneStoriesSceneName)
    else
        SCENE_MANAGER:Push(zoneStoriesSceneName)
    end
end

function ZO_MainMenuManager_Gamepad:GetFooterNarration()
    return GAMEPAD_PLAYER_PROGRESS_BAR_NAME_LOCATION:GetNarration()
end

function ZO_MainMenu_Gamepad_OnInitialized(self)
    MAIN_MENU_GAMEPAD = ZO_MainMenuManager_Gamepad:New(self)
    SYSTEMS:RegisterGamepadObject("mainMenu", MAIN_MENU_GAMEPAD)
end
