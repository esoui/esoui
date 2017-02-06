local MENU_ENTRIES = {}
local CATEGORY_TO_ENTRY_DATA = {}

do
    local MENU_MAIN_ENTRIES =
    {
        MARKET          = 1,
        CROWN_CRATES     = 2,
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
    local MENU_JOURNAL_ENTRIES =
    {
        QUESTS              = 1,
        CADWELLS_JOURNAL    = 2,
        LORE_LIBRARY        = 3,
        ACHIEVEMENTS        = 4,
        LEADERBOARDS        = 5,
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

    local MENU_ENTRY_DATA =
    {
        [MENU_MAIN_ENTRIES.NOTIFICATIONS] =
        {
            scene = "gamepad_notifications_root",
            name =
                function()
                    local numNotifications = GAMEPAD_NOTIFICATIONS and GAMEPAD_NOTIFICATIONS:GetNumNotifications() or 0
                    return zo_strformat(SI_GAMEPAD_MAIN_MENU_NOTIFICATIONS, numNotifications)
                end,
            icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_notifications.dds",
            isNewCallback =
                function()
                    return true --new icon indicator should always display
                end,
            isVisibleCallback =
                function()
                    if GAMEPAD_NOTIFICATIONS then
                        return GAMEPAD_NOTIFICATIONS:GetNumNotifications() > 0
                    else
                        return false
                    end
                end,
        },
        [MENU_MAIN_ENTRIES.MARKET] =
        {
            scene = "gamepad_market_pre_scene",
            additionalScenes =
                {
                    "gamepad_market",
                    "gamepad_market_preview",
                    "gamepad_market_bundle_contents",
                    "gamepad_market_purchase",
                    "gamepad_market_locked",
                },
            customTemplate = "ZO_GamepadMenuCrownStoreEntryTemplate",
            name = GetString(SI_GAMEPAD_MAIN_MENU_MARKET_ENTRY),
            icon = "EsoUI/Art/MenuBar/Gamepad/gp_PlayerMenu_icon_store.dds",
            header = GetString(SI_ESO_PLUS_TITLE),
            postPadding = 70,
            showHeader = function() return IsESOPlusSubscriber() end
        },
        [MENU_MAIN_ENTRIES.CROWN_CRATES] =
        {
            scene = "crownCrateGamepad",
            name = GetString(SI_MAIN_MENU_CROWN_CRATES),
            icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_crownCrates.dds",
            isNewCallback =
                function()
                    return GetNextOwnedCrownCrateId() ~= nil
                end,
            disableWhenDead = true,
            disableWhenReviving = true,
            disableWhenSwimming = true,
            disableWhenWerewolf = true,
            isNewCallback =
                function()
                    return GetNumOwnedCrownCrateTypes() > 0
                end,
            isVisibleCallback = function()
                --An unusual case, we don't want to blow away this option if you're already in the scene when it's disabled
                --Crown crates will properly refresh again when it closes its scene
                return CanInteractWithCrownCratesSystem() or SYSTEMS:IsShowing("crownCrate")
            end,
        },
        [MENU_MAIN_ENTRIES.COLLECTIONS] =
        {
            scene = "gamepadCollectionsBook",
            name = GetString(SI_MAIN_MENU_COLLECTIONS),
            icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_collections.dds",
            isNewCallback =
                function()
                    return (GAMEPAD_COLLECTIONS_BOOK and GAMEPAD_COLLECTIONS_BOOK:HasAnyNewCollectibles()) or (COLLECTIONS_BOOK_SINGLETON and COLLECTIONS_BOOK_SINGLETON:DoesAnyDLCHaveQuestPending())
                end,
        },
        [MENU_MAIN_ENTRIES.INVENTORY] =
        {
            scene = "gamepad_inventory_root",
            name = GetString(SI_MAIN_MENU_INVENTORY),
            icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_inventory.dds",
            isNewCallback =
                function()
                    return SHARED_INVENTORY:AreAnyItemsNew(nil, nil, BAG_BACKPACK, BAG_VIRTUAL)
                end,
        },
        [MENU_MAIN_ENTRIES.CHARACTER] =
        {
            scene = "gamepad_stats_root",
            name = GetString(SI_MAIN_MENU_CHARACTER),
            icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_character.dds",
            canLevel =
                function()
                    return GetAttributeUnspentPoints() > 0
                end
        },
        [MENU_MAIN_ENTRIES.SKILLS] =
        {
            scene = "gamepad_skills_root",
            customTemplate = "ZO_GamepadNewAnimatingMenuEntryTemplate",
            name = GetString(SI_MAIN_MENU_SKILLS),
            icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_skills.dds",
            canLevel =
                function()
                    return GetAvailableSkillPoints() > 0
                end,
        },
        [MENU_MAIN_ENTRIES.CHAMPION] =
        {
            scene = "gamepad_championPerks_root",
            name = GetString(SI_MAIN_MENU_CHAMPION),
            icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_champion.dds",
            isNewCallback =
                function()
                    if CHAMPION_PERKS then
                        return CHAMPION_PERKS:IsChampionSystemNew()
                    end
                end,
            isVisibleCallback =
                function()
                    return IsChampionSystemUnlocked()
                end,
            canLevel =
                function()
                    if CHAMPION_PERKS then
                        return CHAMPION_PERKS:HasAnySpendableUnspentPoints()
                    end
                end,
        },
        [MENU_MAIN_ENTRIES.CAMPAIGN] =
        {
            scene = "gamepad_campaign_root",
            name = GetString(SI_PLAYER_MENU_CAMPAIGNS),
            icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_allianceWar.dds",
            isNewCallback =
                function()
                    local tutorialId = GetTutorialId(TUTORIAL_TRIGGER_CAMPAIGN_BROWSER_OPENED)
                    if CanTutorialBeSeen(tutorialId) then
                        return not HasSeenTutorial(tutorialId)
                    end
                    return false
                end,
            isVisibleCallback =
                function()
                    local currentLevel = GetUnitLevel("player")
                    return currentLevel >= GetMinLevelForCampaignTutorial()
                end,
        },
        [MENU_MAIN_ENTRIES.JOURNAL] =
        {
            customTemplate = "ZO_GamepadMenuEntryTemplateWithArrow",
            name = GetString(SI_MAIN_MENU_JOURNAL),
            icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_journal.dds",
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
                    isVisibleCallback =
                        function()
                            return GetCadwellProgressionLevel() > CADWELL_PROGRESSION_LEVEL_BRONZE
                        end,
                },
                [MENU_JOURNAL_ENTRIES.LORE_LIBRARY] =
                {
                    scene = "loreLibraryGamepad",
                    name = GetString(SI_GAMEPAD_MAIN_MENU_JOURNAL_LORE_LIBRARAY),
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
            isNewCallback =
                function()
                    return HasUnreadMail()
                end,
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
                    isVisibleCallback =
                        function()
                            return not IsConsoleUI()
                        end,
                },
                [MENU_SOCIAL_ENTRIES.MAIL] =
                {
                    scene = "mailManagerGamepad",
                    name = GetString(SI_MAIN_MENU_MAIL),
                    icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_mail.dds",
                    isNewCallback =
                        function()
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
            activatedCallback =
                function()
                    ZO_Dialogs_ShowPlatformDialog("LOG_OUT")
                end,
        },
    }

    CATEGORY_TO_ENTRY_DATA =
    {
        [MENU_CATEGORY_NOTIFICATIONS]   = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.NOTIFICATIONS],
        [MENU_CATEGORY_MARKET]          = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.MARKET],
        [MENU_CATEGORY_CROWN_CRATES]    = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.CROWN_CRATES],
        [MENU_CATEGORY_COLLECTIONS]     = MENU_ENTRY_DATA[MENU_MAIN_ENTRIES.COLLECTIONS],
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

        entry.data = data
        return entry
    end

    for _, data in ipairs(MENU_ENTRY_DATA) do
        local newEntry = CreateEntry(data)

        if data.subMenu then
            newEntry.subMenu = {}
            for _, subMenuData in ipairs(data.subMenu) do
                local newSubMenuEntry = CreateEntry(subMenuData)
                table.insert(newEntry.subMenu, newSubMenuEntry)
            end
        end

        table.insert(MENU_ENTRIES, newEntry)
    end
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

    control:RegisterForEvent(EVENT_LEVEL_UPDATE, function() self:RefreshLists() end)
    control:AddFilterForEvent(EVENT_LEVEL_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
    control:RegisterForEvent(EVENT_CADWELL_PROGRESSION_LEVEL_CHANGED, function() self:RefreshLists() end)

    PLAYER_SUBMENU_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.mode = MODE_SUBLIST
        end
        ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
    end)
    MAIN_MENU_MANAGER:RegisterCallback("OnPlayerStateUpdate", function() self:UpdateEntryEnabledStates() end)
end

function ZO_MainMenuManager_Gamepad:OnShowing()
    self:RefreshLists()
    -- Both MAIN_MENU_GAMEPAD_SCENE and PLAYER_SUBMENU_SCENE use OnShowing to set the active list, which also adds the appropriate list fragment to the scene
    -- Two separate scenes are needed for this to properly control the direction the fragments conveyor in and out.
    self:SetCurrentList(self.mode == MODE_SUBLIST and self.subList or self.mainList)
end

function ZO_MainMenuManager_Gamepad:OnHiding()
    self.mode = MODE_MAIN_LIST
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
        local currencyString = ZO_CommaDelimitNumber(GetPlayerCrowns())
        remainingCrownsLabel:SetText(currencyString)
    end
    
    function ZO_MainMenuManager_Gamepad:SetupList(list)
        list:AddDataTemplate("ZO_GamepadNewMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadNewMenuEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    
        list:AddDataTemplate("ZO_GamepadMenuEntryTemplateWithArrow", EntryWithSubMenuSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
        list:AddDataTemplateWithHeader("ZO_GamepadMenuEntryTemplateWithArrow", EntryWithSubMenuSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    
        list:AddDataTemplate("ZO_GamepadNewAnimatingMenuEntryTemplate", AnimatingLabelEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    
        list:AddDataTemplateWithHeader("ZO_GamepadMenuCrownStoreEntryTemplate", CrownStoreEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadCrownStoreMenuEntryHeaderTemplate")
        list:AddDataTemplate("ZO_GamepadMenuCrownStoreEntryTemplate", CrownStoreEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    end
end

local function ShouldDisableEntry(entryData)
    if MAIN_MENU_MANAGER:IsPlayerDead() and entryData.disableWhenDead then
        return true
    elseif MAIN_MENU_MANAGER:IsPlayerInCombat() and entryData.disableWhenInCombat then
        return true
    elseif MAIN_MENU_MANAGER:IsPlayerReviving() and entryData.disableWhenReviving then
        return true
    elseif MAIN_MENU_MANAGER:IsPlayerSwimming() and entryData.disableWhenSwimming then
        return true
    elseif MAIN_MENU_MANAGER:IsPlayerWerewolf() and entryData.disableWhenWerewolf then
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

    for _, entry in ipairs(MENU_ENTRIES) do
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

    local function OnBlockingSceneCleared(nextSceneData, showBaseScene)
        if IsInGamepadPreferredMode() then
            if showBaseScene then
                SCENE_MANAGER:ShowBaseScene()
            elseif nextSceneData and nextSceneData.sceneName then
                SCENE_MANAGER:Toggle(nextSceneData.sceneName)
            end
        end
    end

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", MarkNewnessDirty)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", MarkNewnessDirty)
    EVENT_MANAGER:RegisterForEvent("mainMenuGamepad", EVENT_LEVEL_UPDATE, MarkNewnessDirty)
    EVENT_MANAGER:RegisterForEvent("mainMenuGamepad", EVENT_MAIL_NUM_UNREAD_CHANGED, MarkNewnessDirty)
    MAIN_MENU_MANAGER:RegisterCallback("OnBlockingSceneCleared", OnBlockingSceneCleared)

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
            activatedCallback()
        end

    else
        PlaySound(SOUNDS.PLAYER_MENU_ENTRY_DISABLED)
    end
end

function ZO_MainMenuManager_Gamepad:Exit()
    SCENE_MANAGER:Hide("mainMenuGamepad")
end

local function AddEntryToList(list, entry)
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
    end
end

function ZO_MainMenuManager_Gamepad:RefreshMainList()
    self.mainList:Clear()

    for _, entry in ipairs(MENU_ENTRIES) do
        AddEntryToList(self.mainList, entry)
    end

    -- if we haven't yet initialized, set the default selection to be the inventory
    -- we only need to default to inventory the first time the Player Menu is shown
    -- so as soon as we init, we don't need to update this any more
    if not self.initialized then
        -- notifications will appear at the top of the list if there are any available
        local INVENTORY_LIST_INDEX = GAMEPAD_NOTIFICATIONS:GetNumNotifications() == 0 and 4 or 5 -- 4 and 5 correspond to collections and inventory, respectively 
        self.mainList:SetDefaultSelectedIndex(INVENTORY_LIST_INDEX)
    end

    self.mainList:Commit()
end

function ZO_MainMenuManager_Gamepad:RefreshSubList(mainListEntry)
    self.subList:Clear()

    if mainListEntry and mainListEntry.subMenu then
        for _, entry in ipairs(mainListEntry.subMenu) do
            AddEntryToList(self.subList, entry)
        end
    end

    self.subList:Commit()
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

function ZO_MainMenu_Gamepad_OnInitialized(self)
    MAIN_MENU_GAMEPAD = ZO_MainMenuManager_Gamepad:New(self)
    SYSTEMS:RegisterGamepadObject("mainMenu", MAIN_MENU_GAMEPAD)
end
