local CATEGORY_TO_SCENE =
{
    [MENU_CATEGORY_MARKET] =
    {
        scene = "gamepad_market_pre_scene",
    },
    [MENU_CATEGORY_INVENTORY] =
    {
        scene = "gamepad_inventory_root",
    },
    [MENU_CATEGORY_CHARACTER] =
    {
        scene = "gamepad_stats_root",
    },
    [MENU_CATEGORY_SKILLS] =
    {
        scene = "gamepad_skills_root",
    },
    [MENU_CATEGORY_CHAMPION] =
    {
        scene = "gamepad_championPerks_root",
    },
    [MENU_CATEGORY_JOURNAL] =
    {
        scene = "gamepad_quest_journal",
    },
    [MENU_CATEGORY_COLLECTIONS] =
    {
        scene = "gamepadCollectionsBook",
    },
    [MENU_CATEGORY_MAP] =
    {
        scene = "gamepad_worldMap",
    },
    [MENU_CATEGORY_GROUP] =
    {
        scene = "gamepad_groupList",
    },
    [MENU_CATEGORY_CONTACTS] =
    {
        scene = "gamepad_friends",
    },
    [MENU_CATEGORY_GUILDS] =
    {
        scene = "gamepad_guild_hub",
    },
    [MENU_CATEGORY_ALLIANCE_WAR] =
    {
        scene = "gamepad_campaign_root",
    },
    [MENU_CATEGORY_MAIL] =
    {
        scene = "mailManagerGamepad",
    },
    [MENU_CATEGORY_NOTIFICATIONS] =
    {
        scene = "gamepad_notifications_root",
    },
    [MENU_CATEGORY_HELP] =
    {
        scene = "helpRootGamepad",
    },
}

local function ShowLogoutDialog()
    ZO_Dialogs_ShowPlatformDialog("LOG_OUT")
end

--[[
    menuTable = the table to add the entry to. MUST exist and be a table
    entryName = the display name in the menu.
    icon = the icon displayed to the left of the name. Can be nil.
    isNew = function or boolean determining if the new icon indicator should display. Can be nil.
    isVisibleCallback = function determining when to show the entry. If nil, the entry is always shown.
    header = string to set as the header for the entry. Can be nil. If header is an empty string, the entry will have a blank header.
--]]
local function AddEntryToMenu(menuTable, entryName, icon, sceneName, isNew, isVisibleCallback, header)
    local entry = ZO_GamepadEntryData:New(entryName, icon, nil, nil, isNew)
    entry.scene = sceneName
    entry.isVisibleCallback = isVisibleCallback
    if header then
        entry:SetHeader(header)
    end

    table.insert(menuTable, entry)
    return entry
end

-- a table of layout information to display a list of scenes available to the user
-- Entries are addded to the list in order, so the first entry added to the table appears at the top of the list
-- If you disable a category in PlayerMenu.lua you should also disable it in MainMenu.lua
local function GetLayoutData()
    local layoutData = {}

    -- Notifications --
    local MARK_NOTIFICATIONS_NEW = true -- when we have notifications, we are always new
    local notifications = AddEntryToMenu(layoutData, "", "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_notifications.dds", "gamepad_notifications_root", MARK_NOTIFICATIONS_NEW,
                                            function()
                                                if GAMEPAD_NOTIFICATIONS then
                                                    return GAMEPAD_NOTIFICATIONS:GetNumNotifications() > 0
                                                else
                                                    return false
                                                end
                                            end)
    notifications.refreshCallback = function()
                                        local numNotifications = GAMEPAD_NOTIFICATIONS and GAMEPAD_NOTIFICATIONS:GetNumNotifications() or 0
                                        local textString = zo_strformat(SI_GAMEPAD_MAIN_MENU_NOTIFICATIONS, numNotifications)
                                        notifications:SetText(textString)
                                    end
    notifications:refreshCallback()

    -- Crown Store --
    local market = AddEntryToMenu(layoutData, GetString(SI_GAMEPAD_MAIN_MENU_MARKET_ENTRY), "EsoUI/Art/MenuBar/Gamepad/gp_PlayerMenu_icon_store.dds", "gamepad_market_pre_scene")
    market.additionalScenes =   {
                                    "gamepad_market",
                                    "gamepad_market_preview",
                                    "gamepad_market_bundle_contents",
                                    "gamepad_market_purchase",
                                    "gamepad_market_locked",
                                }
    market.disableWhenDead = true

    -- Collections --
    local collections = AddEntryToMenu(layoutData, GetString(SI_MAIN_MENU_COLLECTIONS), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_collections.dds", "gamepadCollectionsBook")
    collections:SetNew(function() return GAMEPAD_NOTIFICATIONS and GAMEPAD_NOTIFICATIONS:GetNumCollectionsNotifications() > 0 or false end)

    -- Inventory --
    AddEntryToMenu(layoutData, GetString(SI_MAIN_MENU_INVENTORY), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_inventory.dds", "gamepad_inventory_root",
                    function() return SHARED_INVENTORY:AreAnyItemsNew(nil, nil, BAG_BACKPACK) end)

    -- Character Sheet --
    local character = AddEntryToMenu(layoutData, GetString(SI_MAIN_MENU_CHARACTER), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_character.dds", "gamepad_stats_root")
    character.canLevel = function() return GetAttributeUnspentPoints() > 0 end

    -- Skills --
    local skills = AddEntryToMenu(layoutData, GetString(SI_MAIN_MENU_SKILLS), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_skills.dds", "gamepad_skills_root")
    skills.canLevel = function() return GetAvailableSkillPoints() > 0 end
    skills.canAnimate = true
    
    -- Champion --
    local champion = AddEntryToMenu(layoutData, GetString(SI_MAIN_MENU_CHAMPION), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_champion.dds", "gamepad_championPerks_root",
                                        function()
                                            if CHAMPION_PERKS then
                                                return CHAMPION_PERKS:IsChampionSystemNew()
                                            end
                                        end,
                                        function() return IsChampionSystemUnlocked() end)
    champion.canLevel = function()
        if CHAMPION_PERKS then
            return CHAMPION_PERKS:HasAnySpendableUnspentPoints()
        end
    end

    -- Alliance War --
    AddEntryToMenu(layoutData, GetString(SI_PLAYER_MENU_CAMPAIGNS), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_allianceWar.dds", "gamepad_campaign_root",
                    function()
                        local tutorialId = GetTutorialId(TUTORIAL_TRIGGER_CAMPAIGN_BROWSER_OPENED)
                        if CanTutorialBeSeen(tutorialId) then
                            return not HasSeenTutorial(tutorialId)
                        end
                        return false
                    end,
                    function()
                        local currentLevel = GetUnitLevel("player")
                        return currentLevel >= GetMinLevelForCampaignTutorial()
                    end)

    -- Journal Menu --
    local journal = AddEntryToMenu(layoutData, GetString(SI_MAIN_MENU_JOURNAL), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_quests.dds")
    journal.subMenu = {}

    -- Quests --
    AddEntryToMenu(journal.subMenu, GetString(SI_GAMEPAD_MAIN_MENU_JOURNAL_QUESTS), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_quests.dds", "gamepad_quest_journal", nil, nil, GetString(SI_MAIN_MENU_JOURNAL))

    -- Cadwell's Journal --
    AddEntryToMenu(journal.subMenu, GetString(SI_GAMEPAD_MAIN_MENU_JOURNAL_CADWELL), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_cadwell.dds", "cadwellGamepad", nil,
                    function()
                        return GetPlayerDifficultyLevel() > PLAYER_DIFFICULTY_LEVEL_FIRST_ALLIANCE
                    end)

    -- Lore Library --
    AddEntryToMenu(journal.subMenu, GetString(SI_GAMEPAD_MAIN_MENU_JOURNAL_LORE_LIBRARAY), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_loreLibrary.dds", "loreLibraryGamepad")

    -- Achievements --
    AddEntryToMenu(journal.subMenu, GetString(SI_GAMEPAD_MAIN_MENU_JOURNAL_ACHIEVEMENTS), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_achievements.dds", "achievementsGamepad")

    -- Leaderboards --
    AddEntryToMenu(journal.subMenu, GetString(SI_JOURNAL_MENU_LEADERBOARDS), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_leaderBoards.dds", "gamepad_leaderboards")


    -- Social Menu --
    local social = AddEntryToMenu(layoutData, GetString(SI_MAIN_MENU_SOCIAL), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_multiplayer.dds", nil,
                                        function()
                                            return HasUnreadMail()
                                        end)
    social.subMenu = {}

    -- Voice Chat --
    if IsConsoleUI() then
        AddEntryToMenu(social.subMenu, GetString(SI_MAIN_MENU_GAMEPAD_VOICECHAT), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_communications.dds", "gamepad_voice_chat", nil, nil, GetString(SI_MAIN_MENU_SOCIAL))
    
            -- Text Chat --
        if IsChatSystemAvailableForCurrentPlatform() then
            AddEntryToMenu(social.subMenu, GetString(SI_GAMEPAD_TEXT_CHAT), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_communications.dds", "gamepad_text_chat")
        end
    end

    -- Emotes --
    local headerText
    if not IsConsoleUI() then
        headerText = GetString(SI_MAIN_MENU_SOCIAL)
    end
    AddEntryToMenu(social.subMenu, GetString(SI_GAMEPAD_MAIN_MENU_EMOTES), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_emotes.dds", "gamepad_player_emote", nil, nil, headerText)

    -- Group --
    AddEntryToMenu(social.subMenu, GetString(SI_PLAYER_MENU_GROUP), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_groups.dds", "gamepad_groupList")

    -- Guilds --
    AddEntryToMenu(social.subMenu, GetString(SI_MAIN_MENU_GUILDS), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_guilds.dds", "gamepad_guild_hub")

    -- Friends --
    AddEntryToMenu(social.subMenu, GetString(SI_GAMEPAD_CONTACTS_FRIENDS_LIST_TITLE), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_contacts.dds", "gamepad_friends")

    -- Ignored List --
    if not IsConsoleUI() then
        AddEntryToMenu(social.subMenu, GetString(SI_GAMEPAD_CONTACTS_IGNORED_LIST_TITLE), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_contacts.dds", "gamepad_ignored")
    end

    -- Mail --
    local mailbox = AddEntryToMenu(social.subMenu, GetString(SI_MAIN_MENU_MAIL), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_mail.dds", "mailManagerGamepad",
                                    function()
                                        return HasUnreadMail()
                                    end)
    mailbox.disableWhenDead = true
    mailbox.disableWhenInCombat = true
    mailbox.disableWhenReviving = true

    -- Help --
    AddEntryToMenu(layoutData, GetString(SI_MAIN_MENU_HELP), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_help.dds", "helpRootGamepad")

    -- Options --
    AddEntryToMenu(layoutData, GetString(SI_GAMEPAD_OPTIONS_MENU), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_settings.dds", "gamepad_options_root")

    -- Log Out --
    local logOut = AddEntryToMenu(layoutData, GetString(SI_GAME_MENU_LOGOUT), "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_logout.dds")
    logOut.activatedCallback = ShowLogoutDialog

    return layoutData
end

local CATEGORY_LAYOUT_INFO = GetLayoutData()

local GENERIC_ENTRY_TEMPLATE = "ZO_GamepadNewMenuEntryTemplate"
local ENTRY_WITH_SUB_MENU_TEMPLATE = "ZO_GamepadMenuEntryTemplateWithArrow"
local ANIMATING_ENTRY_TEMPLATE = "ZO_GamepadNewAnimatingMenuEntryTemplate"

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

    control:RegisterForEvent(EVENT_LEVEL_UPDATE,
            function()
                self:RefreshLists()
            end)
    control:AddFilterForEvent(EVENT_LEVEL_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")

    control:RegisterForEvent(EVENT_DIFFICULTY_LEVEL_CHANGED, function() self:RefreshLists() end)

    PLAYER_SUBMENU_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.mode = MODE_SUBLIST
        end
        ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
    end)
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

function ZO_MainMenuManager_Gamepad:SetupList(list)
    list:AddDataTemplate(GENERIC_ENTRY_TEMPLATE, ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader(GENERIC_ENTRY_TEMPLATE, ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    list:AddDataTemplate(ENTRY_WITH_SUB_MENU_TEMPLATE, EntryWithSubMenuSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
    list:AddDataTemplateWithHeader(ENTRY_WITH_SUB_MENU_TEMPLATE, EntryWithSubMenuSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
    list:AddDataTemplate(ANIMATING_ENTRY_TEMPLATE, AnimatingLabelEntrySetup, ZO_GamepadMenuEntryTemplateParametricListFunction)
end

do
    local function GetCategoryState(categoryInfo)
        if MAIN_MENU_MANAGER:IsPlayerDead() and categoryInfo.disableWhenDead then
            return MAIN_MENU_CATEGORY_DISABLED_WHILE_DEAD
        elseif MAIN_MENU_MANAGER:IsPlayerInCombat() and categoryInfo.disableWhenInCombat then
            return MAIN_MENU_CATEGORY_DISABLED_WHILE_IN_COMBAT
        elseif MAIN_MENU_MANAGER:IsPlayerReviving() and categoryInfo.disableWhenReviving then
            return MAIN_MENU_CATEGORY_DISABLED_WHILE_REVIVING
        else
            return MAIN_MENU_CATEGORY_ENABLED
        end
    end

    local function TryHideCategoryScene(categoryInfo)
        local shouldHide = false
        if SCENE_MANAGER:IsShowing(categoryInfo.scene) then
            shouldHide = true
        elseif categoryInfo.additionalScenes then
            for _, sceneName in ipairs(categoryInfo.additionalScenes) do
                if SCENE_MANAGER:IsShowing(sceneName) then
                    shouldHide = true
                    break
                end
            end
        end

        if shouldHide then
            SCENE_MANAGER:ShowBaseScene()
        end
    end

    local function DetermineCategoryEnabled(categoryInfo)
        local shouldBeEnabled = GetCategoryState(categoryInfo) == MAIN_MENU_CATEGORY_ENABLED
        categoryInfo:SetEnabled(shouldBeEnabled)
        if not shouldBeEnabled then
            TryHideCategoryScene(categoryInfo)
        end
    end

    function ZO_MainMenuManager_Gamepad:UpdateCategories()
        for _, categoryInfo in ipairs(CATEGORY_LAYOUT_INFO) do
            DetermineCategoryEnabled(categoryInfo)
            if categoryInfo.subMenu then
                for _, subCategoryInfo in ipairs(categoryInfo.subMenu) do
                    DetermineCategoryEnabled(subCategoryInfo)
                end
            end
        end

        self:RefreshLists()
    end
end

function ZO_MainMenuManager_Gamepad:RefreshLists()
    if self.mode == MODE_MAIN_LIST then
        self:RefreshMainList()
    else
        local targetData = self.mainList:GetTargetData()
        self:RefreshSubList(targetData)
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
    MAIN_MENU_MANAGER:RegisterCallback("OnPlayerStateUpdate", function() self:UpdateCategories() end)
    MAIN_MENU_MANAGER:RegisterCallback("OnBlockingSceneCleared", OnBlockingSceneCleared)

    self:UpdateCategories()
end

function ZO_MainMenuManager_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_MAIN_MENU_GAMEPAD_VOICECHAT),
            keybind = "UI_SHORTCUT_TERTIARY",
            visible = function() return IsConsoleUI() end,
            callback = function() SCENE_MANAGER:Push("gamepad_voice_chat") end,
        },
        {
            name = GetString(SI_GAMEPAD_MAIN_MENU_EMOTES),
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function() SCENE_MANAGER:Push("gamepad_player_emote") end,
        }
    }

    local  function IsForwardNavigationEnabled()
        local currentList = self:GetCurrentList() 
        local categoryInfo = currentList and currentList:GetTargetData()
        return categoryInfo and categoryInfo:IsEnabled()
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
    local targetData = list:GetTargetData()
    if targetData.enabled then
        local scene = targetData.scene
        local activatedCallback = targetData.activatedCallback

        if scene then
            list:SetActive(false)
            SCENE_MANAGER:Push(scene)
        elseif targetData.subMenu then
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
    if not entry.isVisibleCallback or entry.isVisibleCallback() then
        if entry.refreshCallback then
            entry.refreshCallback()
        end

        entry:SetIconTintOnSelection(true)
        entry:SetIconDisabledTintOnSelection(true)

        local entryTemplate = GENERIC_ENTRY_TEMPLATE
        
        if entry.canAnimate then
            entryTemplate = ANIMATING_ENTRY_TEMPLATE
        elseif entry.subMenu then
            entryTemplate = ENTRY_WITH_SUB_MENU_TEMPLATE
        end

        if entry.header then
            list:AddEntryWithHeader(entryTemplate, entry)
        else
            list:AddEntry(entryTemplate, entry)
        end
    end
end

function ZO_MainMenuManager_Gamepad:RefreshMainList()
    self.mainList:Clear()

    for _, layout in ipairs(CATEGORY_LAYOUT_INFO) do
        AddEntryToList(self.mainList, layout)
    end

    -- if we haven't yet initialized, set the default selection to be the inventory
    -- we only need to default to inventory the first time the Player Menu is shown
    -- so as soon as we init, we don't need to update this any more
    if not self.initialized then
        -- notifications will appear at the top of the list if there are any available
        local INVENTORY_LIST_INDEX = GAMEPAD_NOTIFICATIONS:GetNumNotifications() == 0 and 3 or 4
        self.mainList:SetDefaultSelectedIndex(INVENTORY_LIST_INDEX)
    end

    self.mainList:Commit()
end

function ZO_MainMenuManager_Gamepad:RefreshSubList(targetData)
    self.subList:Clear()

    if targetData and targetData.subMenu then
        for _, entry in ipairs(targetData.subMenu) do
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

function ZO_MainMenuManager_Gamepad:ToggleCategory(category)
    self:ToggleScene(CATEGORY_TO_SCENE[category].scene)
end

function ZO_MainMenuManager_Gamepad:ShowCategory(category)
    self:ShowScene(CATEGORY_TO_SCENE[category].scene)
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
