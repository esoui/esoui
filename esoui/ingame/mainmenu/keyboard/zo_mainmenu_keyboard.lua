local MainMenu_Keyboard = ZO_InitializingCallbackObject:Subclass()

-- If you disable a category in MainMenu.lua you should also disable it in PlayerMenu.lua
ZO_CATEGORY_LAYOUT_INFO =
{
    [MENU_CATEGORY_MARKET] =
    {
        binding = "TOGGLE_MARKET",
        categoryName = SI_MAIN_MENU_MARKET,

        descriptor = MENU_CATEGORY_MARKET,
        normal = "EsoUI/Art/MainMenu/menuBar_market_up.dds",
        pressed = "EsoUI/Art/MainMenu/menuBar_market_down.dds",
        disabled = "EsoUI/Art/MainMenu/menuBar_market_disabled.dds",
        highlight = "EsoUI/Art/MainMenu/menuBar_market_over.dds",
        --override the sizes set by AddCategories because these icons are twice as big as the others
        overrideNormalSize = 102,
        overrideDownSize = 128,

        onInitializeCallback = function(button)
            local animationTexture = button:GetNamedChild("ImageAnimation")
            animationTexture:SetTexture("EsoUI/Art/MainMenu/menuBar_market_animation.dds")
            animationTexture:SetHidden(false)
            animationTexture:SetBlendMode(TEX_BLEND_MODE_ADD)
            button.animationTexture = animationTexture

            button.timeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_CrownStoreShineAnimation", animationTexture)
            button.timeline:PlayFromStart()

            local isSubscriber = IsESOPlusSubscriber()
            local membershipControl = button:GetNamedChild("Membership")
            local remainingCrownsControl = button:GetNamedChild("RemainingCrowns")
            membershipControl:SetHidden(not isSubscriber)
            local esoPlusString = zo_iconTextFormatNoSpace("EsoUI/Art/Market/Keyboard/ESOPlus_Chalice_GOLD_32.dds", 28, 28, GetString(SI_ESO_PLUS_TITLE))
            membershipControl:SetText(esoPlusString)
            remainingCrownsControl:SetHidden(false)
            local currentCrownBalance = GetPlayerMarketCurrency(MKCT_CROWNS)
            remainingCrownsControl:SetText(zo_strformat(SI_NUMBER_FORMAT, currentCrownBalance))
            button:RegisterForEvent(EVENT_CROWN_UPDATE, function(currencyAmount)
                local playerCrownBalance = GetPlayerMarketCurrency(MKCT_CROWNS)
                remainingCrownsControl:SetText(zo_strformat(SI_NUMBER_FORMAT, playerCrownBalance))
            end)
        end,
        onResetCallback = function(button)
            button.animationTexture:SetHidden(true)
            button.timeline:PlayInstantlyToStart()
            button.timeline:Stop()
            button:UnregisterForEvent(EVENT_CROWN_UPDATE)
            button:GetNamedChild("Membership"):SetHidden(true)
            button:GetNamedChild("RemainingCrowns"):SetHidden(true)
        end,
        onButtonStatePressed = function(button)
            button.animationTexture:SetHidden(true)
            button.timeline:PlayInstantlyToStart()
            button.timeline:Stop()
        end,
        onButtonStateNormal = function(button)
            button.animationTexture:SetHidden(false)
            button.timeline:PlayFromStart()
        end,
        onButtonStateDisabled = function(button)
            button.animationTexture:SetHidden(true)
            button.timeline:PlayInstantlyToStart()
            button.timeline:Stop()
        end,
        indicators = function()
            if GIFT_INVENTORY_MANAGER and GIFT_INVENTORY_MANAGER:HasAnyUnseenGifts() then
                return { ZO_KEYBOARD_NEW_ICON }
            end

            if GetDailyLoginClaimableRewardIndex() then
                return { ZO_KEYBOARD_NEW_ICON }
            end
        end,
    },
    [MENU_CATEGORY_CROWN_CRATES] =
    {
        binding = "TOGGLE_CROWN_CRATES",
        categoryName = SI_MAIN_MENU_CROWN_CRATES,
        scene = "crownCrateKeyboard",
        previousButtonExtraPadding = 10,
        barPadding = 20,
        hideCategoryBar = true,

        descriptor = MENU_CATEGORY_CROWN_CRATES,
        normal = "EsoUI/Art/MainMenu/menuBar_crownCrates_up.dds",
        pressed = "EsoUI/Art/MainMenu/menuBar_crownCrates_down.dds",
        disabled = "EsoUI/Art/MainMenu/menuBar_crownCrates_disabled.dds",
        highlight = "EsoUI/Art/MainMenu/menuBar_crownCrates_over.dds",
        --override the sizes set by AddCategories because these icons are twice as big as the others
        overrideNormalSize = 102,
        overrideDownSize = 128,
        
        disableWhenDead = true,
        disableWhenReviving = true,
        disableWhenSwimming = true,
        disableWhenWerewolf = true,
        disableWhenPassenger = true,

        indicators = function()
            if GetNumOwnedCrownCrateTypes() > 0 then
                return { ZO_KEYBOARD_NEW_ICON }
            end
        end,
        visible = function()
            --An unusual case, we don't want to blow away this option if you're already in the scene when it's disabled
            --Crown crates will properly refresh again when it closes its scene
            return CanInteractWithCrownCratesSystem() or SYSTEMS:IsShowing("crownCrate")
        end,
    },
    [MENU_CATEGORY_INVENTORY] =
    {
        binding = "TOGGLE_INVENTORY",
        categoryName = SI_MAIN_MENU_INVENTORY,

        descriptor = MENU_CATEGORY_INVENTORY,
        normal = "EsoUI/Art/MainMenu/menuBar_inventory_up.dds",
        pressed = "EsoUI/Art/MainMenu/menuBar_inventory_down.dds",
        disabled = "EsoUI/Art/MainMenu/menuBar_inventory_disabled.dds",
        highlight = "EsoUI/Art/MainMenu/menuBar_inventory_over.dds",

        indicators = function()
            if SHARED_INVENTORY then
                if SHARED_INVENTORY:AreAnyItemsNew(nil, nil, BAG_BACKPACK, BAG_VIRTUAL) then
                    return { ZO_KEYBOARD_NEW_ICON }
                end
            end
        end,
    },
    [MENU_CATEGORY_CHARACTER] =
    {
        binding = "TOGGLE_CHARACTER",
        categoryName = SI_MAIN_MENU_CHARACTER,

        descriptor = MENU_CATEGORY_CHARACTER,
        normal = "EsoUI/Art/MainMenu/menuBar_character_up.dds",
        pressed = "EsoUI/Art/MainMenu/menuBar_character_down.dds",
        disabled = "EsoUI/Art/MainMenu/menuBar_character_disabled.dds",
        highlight = "EsoUI/Art/MainMenu/menuBar_character_over.dds",
        indicators = function()
            if HasPendingLevelUpReward() or GetAttributeUnspentPoints() > 0 then
                return { ZO_KEYBOARD_NEW_ICON }
            end
        end,
    },
    [MENU_CATEGORY_SKILLS] =
    {
        binding = "TOGGLE_SKILLS",
        categoryName = SI_MAIN_MENU_SKILLS,

        descriptor = MENU_CATEGORY_SKILLS,
        normal = "EsoUI/Art/MainMenu/menuBar_skills_up.dds",
        pressed = "EsoUI/Art/MainMenu/menuBar_skills_down.dds",
        disabled = "EsoUI/Art/MainMenu/menuBar_skills_disabled.dds",
        highlight = "EsoUI/Art/MainMenu/menuBar_skills_over.dds",

        indicators = function()
            if SKILLS_DATA_MANAGER and SKILLS_DATA_MANAGER:AreAnyPlayerSkillLinesOrAbilitiesNew() then
                return { ZO_KEYBOARD_NEW_ICON }
            end
        end,
    },
    [MENU_CATEGORY_CHAMPION] =
    {
        binding = "TOGGLE_CHAMPION",
        categoryName = SI_MAIN_MENU_CHAMPION,

        descriptor = MENU_CATEGORY_CHAMPION,
        normal = "EsoUI/Art/MainMenu/menuBar_champion_up.dds",
        pressed = "EsoUI/Art/MainMenu/menuBar_champion_down.dds",
        highlight = "EsoUI/Art/MainMenu/menuBar_champion_over.dds",
        indicators = function()
            if CHAMPION_PERKS then
                local indicators = {}
                if CHAMPION_PERKS:IsChampionSystemNew() or CHAMPION_DATA_MANAGER:HasAnySavedUnspentPoints() then
                    table.insert(indicators, ZO_KEYBOARD_NEW_ICON)
                end
                return indicators
            end
        end,
        hideCategoryBar = true,
        visible = function()
            return IsChampionSystemUnlocked()
        end,
    },
    [MENU_CATEGORY_JOURNAL] =
    {
        binding = "TOGGLE_JOURNAL",
        categoryName = SI_MAIN_MENU_JOURNAL,

        descriptor = MENU_CATEGORY_JOURNAL,
        normal = "EsoUI/Art/MainMenu/menuBar_journal_up.dds",
        pressed = "EsoUI/Art/MainMenu/menuBar_journal_down.dds",
        disabled = "EsoUI/Art/MainMenu/menuBar_journal_disabled.dds",
        highlight = "EsoUI/Art/MainMenu/menuBar_journal_over.dds",
        indicators = function()
            if ANTIQUITY_DATA_MANAGER and ANTIQUITY_DATA_MANAGER:HasNewLead() then
                return { ZO_KEYBOARD_NEW_ICON }
            end
        end,
    },
    [MENU_CATEGORY_COLLECTIONS] =
    {
        binding = "TOGGLE_COLLECTIONS_BOOK",
        categoryName = SI_MAIN_MENU_COLLECTIONS,

        descriptor = MENU_CATEGORY_COLLECTIONS,
        normal = "EsoUI/Art/MainMenu/menuBar_collections_up.dds",
        pressed = "EsoUI/Art/MainMenu/menuBar_collections_down.dds",
        disabled = "EsoUI/Art/MainMenu/menuBar_collections_disabled.dds",
        highlight = "EsoUI/Art/MainMenu/menuBar_collections_over.dds",

        indicators = function()
            if GetNumNewCollectibles() > 0 or
                (ITEM_SET_COLLECTIONS_DATA_MANAGER and ITEM_SET_COLLECTIONS_DATA_MANAGER:HasAnyNewPieces()) then
                return { ZO_KEYBOARD_NEW_ICON }
            end
        end,
    },
    [MENU_CATEGORY_MAP] =
    {
        binding = "TOGGLE_MAP",
        categoryName = SI_MAIN_MENU_MAP,

        descriptor = MENU_CATEGORY_MAP,
        normal = "EsoUI/Art/MainMenu/menuBar_map_up.dds",
        pressed = "EsoUI/Art/MainMenu/menuBar_map_down.dds",
        disabled = "EsoUI/Art/MainMenu/menuBar_map_disabled.dds",
        highlight = "EsoUI/Art/MainMenu/menuBar_map_over.dds",
    },
    [MENU_CATEGORY_GROUP] =
    {
        binding = "TOGGLE_GROUP",
        categoryName = SI_MAIN_MENU_GROUP,

        descriptor = MENU_CATEGORY_GROUP,
        normal = function(button)
            if PROMOTIONAL_EVENT_MANAGER:IsCampaignActive() and not IsPromotionalEventSystemLocked() then
                return "EsoUI/Art/MainMenu/menuBar_group_gold_up.dds"
            else
                return "EsoUI/Art/MainMenu/menuBar_group_up.dds"
            end
        end,
        pressed = function(button)
            if PROMOTIONAL_EVENT_MANAGER:IsCampaignActive() and not IsPromotionalEventSystemLocked() then
                return "EsoUI/Art/MainMenu/menuBar_group_gold_down.dds"
            else
                return "EsoUI/Art/MainMenu/menuBar_group_down.dds"
            end
        end,
        disabled = "EsoUI/Art/MainMenu/menuBar_group_disabled.dds",
        highlight = function(button)
            if PROMOTIONAL_EVENT_MANAGER:IsCampaignActive() and not IsPromotionalEventSystemLocked() then
                return "EsoUI/Art/MainMenu/menuBar_group_gold_over.dds"
            else
                return "EsoUI/Art/MainMenu/menuBar_group_over.dds"
            end
        end,
        indicators = function()
            if not IsPromotionalEventSystemLocked() then
                local campaignData = PROMOTIONAL_EVENT_MANAGER:GetCurrentCampaignData()
                if campaignData and (not campaignData:HasBeenSeen() or campaignData:IsAnyRewardClaimable()) then
                    return { ZO_KEYBOARD_NEW_ICON }
                end
            end
        end,
    },
    [MENU_CATEGORY_CONTACTS] =
    {
        binding = "TOGGLE_CONTACTS",
        categoryName = SI_MAIN_MENU_CONTACTS,

        descriptor = MENU_CATEGORY_CONTACTS,
        normal = "EsoUI/Art/MainMenu/menuBar_social_up.dds",
        pressed = "EsoUI/Art/MainMenu/menuBar_social_down.dds",
        disabled = "EsoUI/Art/MainMenu/menuBar_social_disabled.dds",
        highlight = "EsoUI/Art/MainMenu/menuBar_social_over.dds",
    },
    [MENU_CATEGORY_GUILDS] =
    {
        binding = "TOGGLE_GUILDS",
        categoryName = SI_MAIN_MENU_GUILDS,

        descriptor = MENU_CATEGORY_GUILDS,
        normal = "EsoUI/Art/MainMenu/menuBar_guilds_up.dds",
        pressed = "EsoUI/Art/MainMenu/menuBar_guilds_down.dds",
        disabled = "EsoUI/Art/MainMenu/menuBar_guilds_disabled.dds",
        highlight = "EsoUI/Art/MainMenu/menuBar_guilds_over.dds",
    },
    [MENU_CATEGORY_ALLIANCE_WAR] =
    {
        binding = "TOGGLE_ALLIANCE_WAR",
        categoryName = SI_MAIN_MENU_ALLIANCE_WAR,

        descriptor = MENU_CATEGORY_ALLIANCE_WAR,
        normal = "EsoUI/Art/MainMenu/menuBar_ava_up.dds",
        pressed = "EsoUI/Art/MainMenu/menuBar_ava_down.dds",
        disabled = "EsoUI/Art/MainMenu/menuBar_ava_disabled.dds",
        highlight = "EsoUI/Art/MainMenu/menuBar_ava_over.dds",

        visible = function()
            local currentLevel = GetUnitLevel("player")
            return currentLevel >= GetMinLevelForCampaignTutorial()
        end,
    },
    [MENU_CATEGORY_MAIL] =
    {
        binding = "TOGGLE_MAIL",
        categoryName = SI_MAIN_MENU_MAIL,
        scene = "mailInbox",

        descriptor = MENU_CATEGORY_MAIL,
        normal = "EsoUI/Art/MainMenu/menuBar_mail_up.dds",
        pressed = "EsoUI/Art/MainMenu/menuBar_mail_down.dds",
        disabled = "EsoUI/Art/MainMenu/menuBar_mail_disabled.dds",
        highlight = "EsoUI/Art/MainMenu/menuBar_mail_over.dds",
        disableWhenDead = true,
        disableWhenInCombat = true,
        disableWhenReviving = true,
    },
    [MENU_CATEGORY_NOTIFICATIONS] =
    {
        binding = "TOGGLE_NOTIFICATIONS",
        categoryName = SI_MAIN_MENU_NOTIFICATIONS,

        descriptor = MENU_CATEGORY_NOTIFICATIONS,
        normal = "EsoUI/Art/MainMenu/menuBar_notifications_up.dds",
        pressed = "EsoUI/Art/MainMenu/menuBar_notifications_down.dds",
        disabled = "EsoUI/Art/MainMenu/menuBar_notifications_disabled.dds",
        highlight = "EsoUI/Art/MainMenu/menuBar_notifications_over.dds",
    },
    [MENU_CATEGORY_HELP] =
    {
        binding = "TOGGLE_HELP",
        categoryName = SI_MAIN_MENU_HELP,

        descriptor = MENU_CATEGORY_HELP,
        normal = "EsoUI/Art/MenuBar/menuBar_help_up.dds",
        pressed = "EsoUI/Art/MenuBar/menuBar_help_down.dds",
        disabled = "EsoUI/Art/MenuBar/menuBar_help_disabled.dds",
        highlight = "EsoUI/Art/MenuBar/menuBar_help_over.dds",
    },
    [MENU_CATEGORY_ACTIVITY_FINDER] =
    {
        binding = "TOGGLE_ACTIVITY_FINDER",
        descriptor = MENU_CATEGORY_ACTIVITY_FINDER,
        hidden = true,
        alias = MENU_CATEGORY_GROUP, --On keyboard, we want the activity finder keybind to just take you to group naturally for now
    },
}

function MainMenu_Keyboard:SetCategoriesEnabled(categoryFilterFunction, shouldBeEnabled)
    for i = 1, #ZO_CATEGORY_LAYOUT_INFO do
        local categoryInfo = ZO_CATEGORY_LAYOUT_INFO[i]
        if categoryFilterFunction(categoryInfo) then
            if not shouldBeEnabled and self:IsShowing() and (self.lastCategory == i) then
                self:Hide()
            end
            ZO_MenuBar_SetDescriptorEnabled(self.categoryBar, i, shouldBeEnabled)
        end
    end
end

function MainMenu_Keyboard:Initialize(control)
    local primaryKeybindDescriptor =
    {
        keybind = "ADDONS_PANEL_PRIMARY",
        name = function()
            if HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
                return GetString(SI_ADDON_MANAGER_RELOAD)
            else
                return GetString(SI_ADDON_MANAGER_VIEW_EULA)
            end
        end,
        enabled = function()
            if HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
                return ADD_ON_MANAGER:AllowReload()
            end

            return true
        end,
        callback = function()
            if HasAgreedToEULA(EULA_TYPE_ADDON_EULA) then
                ReloadUI("ingame")
            else
                CALLBACK_MANAGER:FireCallbacks("ShowAddOnEULAIfNecessary")
            end
        end,
    }
    local secondaryKeybindDescriptor =
    {
        keybind = "ADDONS_PANEL_SECONDARY",
        name =  GetString(SI_CLEAR_UNUSED_KEYBINDS_KEYBIND),
        callback = function()
            ZO_Dialogs_ShowDialog("CONFIRM_CLEAR_UNUSED_KEYBINDS")
        end,
    }
    ADD_ON_MANAGER = ZO_AddOnManager:New(primaryKeybindDescriptor, secondaryKeybindDescriptor)

    local maxCustomBinds = GetMaxNumSavedKeybindings()

    local function RefreshKeybindingsLabel(label)
        local currentNumSavedBindings = GetNumSavedKeybindings()
        label:SetText(zo_strformat(SI_KEYBINDINGS_CURRENT_SAVED_BIND_COUNT, currentNumSavedBindings, maxCustomBinds))

        local color = ZO_NORMAL_TEXT
        if currentNumSavedBindings >= maxCustomBinds then
            color = ZO_ERROR_COLOR
        end
        label:SetColor(color:UnpackRGBA())
    end
    ADD_ON_MANAGER:SetRefreshSavedKeybindsLabelFunction(RefreshKeybindingsLabel)

    self.control = control

    self.categoryBar = GetControl(self.control, "CategoryBar")
    ZO_MenuBar_ClearClickSound(self.categoryBar)
    self.categoryBarFragment = ZO_FadeSceneFragment:New(self.categoryBar)

    self.sceneGroupBar = GetControl(self.control, "SceneGroupBar")
    self.sceneGroupBarLabel = GetControl(self.control, "SceneGroupBarLabel")

    self.tabPressedCallback =   function(tabControl)
                                    if tabControl.sceneGroupName then
                                        self:OnSceneGroupTabClicked(tabControl.sceneGroupName)
                                    end
                                end

    self:AddCategories()

    self.lastCategory = MENU_CATEGORY_INVENTORY

    local function OnBlockingSceneActivated(activatedByMouseClick, isSceneGroup)
        if activatedByMouseClick then
            local SKIP_ANIMATION = true
            if isSceneGroup then
                ZO_MenuBar_RestoreLastClickedButton(self.sceneGroupBar, SKIP_ANIMATION)
            else
                ZO_MenuBar_RestoreLastClickedButton(self.categoryBar, SKIP_ANIMATION)
            end
        end
    end

    local function OnBlockingSceneCleared(nextSceneData, showBaseScene)
        if not IsInGamepadPreferredMode() then
            if nextSceneData then
                if nextSceneData.sceneGroup then
                    nextSceneData.sceneGroup:SetActiveScene(nextSceneData.sceneName)
                    self:Update(nextSceneData.category, nextSceneData.sceneName)
                elseif nextSceneData.sceneName then
                    self:ToggleScene(nextSceneData.sceneName)
                elseif nextSceneData.category then
                    self:ToggleCategory(nextSceneData.category)
                end
            end
        end
    end

    MAIN_MENU_MANAGER:RegisterCallback("OnPlayerStateUpdate", function() self:UpdateCategories() end)
    MAIN_MENU_MANAGER:RegisterCallback("OnBlockingSceneActivated", OnBlockingSceneActivated)
    MAIN_MENU_MANAGER:RegisterCallback("OnBlockingSceneCleared", OnBlockingSceneCleared)

    local function UpdateCategoryBar()
        self:RefreshCategoryBar()
    end
    control:RegisterForEvent(EVENT_LEVEL_UP_REWARD_UPDATED, UpdateCategoryBar)
    control:RegisterForEvent(EVENT_ATTRIBUTE_UPGRADE_UPDATED, UpdateCategoryBar)
    control:RegisterForEvent(EVENT_LEVEL_UPDATE, UpdateCategoryBar)
    control:AddFilterForEvent(EVENT_LEVEL_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
    control:RegisterForEvent(EVENT_PROMOTIONAL_EVENTS_ACTIVITY_PROGRESS_UPDATED, UpdateCategoryBar)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("RewardsClaimed", UpdateCategoryBar)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignSeenStateChanged", UpdateCategoryBar)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignsUpdated", UpdateCategoryBar)

    self:UpdateCategories()
end

function MainMenu_Keyboard:AddCategories()
    local categoryBarData =
    {
        buttonPadding = 16,
        normalSize = 51,
        downSize = 64,
        animationDuration = DEFAULT_SCENE_TRANSITION_TIME,
        buttonTemplate = "ZO_MainMenuCategoryBarButton",
    }

    ZO_MenuBar_SetData(self.categoryBar, categoryBarData)

    self.categoryInfo = {}
    self.sceneInfo = {}
    self.sceneGroupInfo = {}
    self.categoryAreaFragments = {}

    for i = 1, #ZO_CATEGORY_LAYOUT_INFO do
        local categoryLayoutInfo = ZO_CATEGORY_LAYOUT_INFO[i]
        categoryLayoutInfo.callback = function() self:OnCategoryClicked(i) end
        ZO_MenuBar_AddButton(self.categoryBar, categoryLayoutInfo)

        local subcategoryBar = CreateControlFromVirtual("ZO_MainMenuSubcategoryBar", self.control, "ZO_MainMenuSubcategoryBar", i)
        subcategoryBar:SetAnchor(TOP, self.categoryBar, BOTTOM, 0, 7)
        local subcategoryBarFragment = ZO_FadeSceneFragment:New(subcategoryBar)
        self.categoryInfo[i] =
        {
            barControls = {},
            subcategoryBar = subcategoryBar,
            subcategoryBarFragment = subcategoryBarFragment,
        }
    end

    self:RefreshCategoryIndicators()
    self:AddCategoryAreaFragment(self.categoryBarFragment)
end

function MainMenu_Keyboard:AddCategoryAreaFragment(fragment)
    self.categoryAreaFragments[#self.categoryAreaFragments + 1] = fragment
end

function MainMenu_Keyboard:AddRawScene(sceneName, category, categoryInfo, sceneGroupName)
    local scene = SCENE_MANAGER:GetScene(sceneName)

    local hideCategoryBar = ZO_CATEGORY_LAYOUT_INFO[category].hideCategoryBar
    if hideCategoryBar == nil or hideCategoryBar == false then
        scene:AddFragment(categoryInfo.subcategoryBarFragment)
        for i, categoryAreaFragment in ipairs(self.categoryAreaFragments) do
            scene:AddFragment(categoryAreaFragment)
        end
    end

    local sceneInfo =
    {
        category = category,
        sceneName = sceneName,
        sceneGroupName = sceneGroupName,
    }
    self.sceneInfo[sceneName] = sceneInfo

    scene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.ignoreCallbacks = true

            local skipAnimation = not self:IsShowing()
            ZO_MenuBar_SelectDescriptor(self.categoryBar, category, skipAnimation)
            self.lastCategory = category

            if sceneGroupName == nil then
                -- don't set the last scene name if this scene is part of a scene group
                -- when we toggle a category we will default to showing the last scene name
                -- however for scene groups we want to show the active scene not necessarily the last shown scene
                self:SetLastSceneName(categoryInfo, sceneName)
            else
                ZO_MenuBar_SelectDescriptor(self.sceneGroupBar, sceneName, skipAnimation)
                -- if we are part of a scene group, when we show the scene, make sure to
                -- flag this scene as the active one
                local sceneGroup = SCENE_MANAGER:GetSceneGroup(sceneGroupName)
                sceneGroup:SetActiveScene(sceneName)
            end

            self.ignoreCallbacks = false
        end
    end)

    return scene
end

function MainMenu_Keyboard:SetLastSceneName(categoryInfo, sceneName)
    categoryInfo.lastSceneName = sceneName
    categoryInfo.lastSceneGroupName = nil
end

function MainMenu_Keyboard:SetLastSceneGroupName(categoryInfo, sceneGroupName)
    categoryInfo.lastSceneGroupName = sceneGroupName
    categoryInfo.lastSceneName = nil
end

function MainMenu_Keyboard:HasLast(categoryInfo)
    return categoryInfo.lastSceneName ~= nil or categoryInfo.lastSceneGroupName ~= nil
end

function MainMenu_Keyboard:AddScene(category, sceneName)
    local categoryInfo = self.categoryInfo[category]
    self:AddRawScene(sceneName, category, categoryInfo)
    if(not self:HasLast(categoryInfo)) then
        self:SetLastSceneName(categoryInfo, sceneName)
    end
end

function MainMenu_Keyboard:SetSceneEnabled(sceneName, enabled)
    local sceneInfo = self.sceneInfo[sceneName]
    if(sceneInfo) then
        local sceneGroupName = sceneInfo.sceneGroupName
        if(sceneGroupName) then
            local sceneGroupInfo = self.sceneGroupInfo[sceneGroupName]
            local menuBarIconData = sceneGroupInfo.menuBarIconData
            local sceneGroupBarFragment = sceneGroupInfo.sceneGroupBarFragment
            for i = 1, #menuBarIconData do
                local layoutData = menuBarIconData[i]
                if(layoutData.descriptor == sceneName) then
                    layoutData.enabled = enabled
                    
                    if(sceneGroupBarFragment:IsShowing()) then
                        self:UpdateSceneGroupBarEnabledStates(sceneGroupName)
                    end

                    return
                end
            end
        end
    end
end

function MainMenu_Keyboard:AddSceneGroup(category, sceneGroupName, menuBarIconData, sceneGroupPreferredSceneFunction, sceneGroupBarTutorialTrigger)
    local categoryInfo = self.categoryInfo[category]

    local sceneGroup = SCENE_MANAGER:GetSceneGroup(sceneGroupName)
    sceneGroup:RegisterCallback("StateChange", function(_, newState)
        if newState == SCENE_GROUP_SHOWING then
            self.sceneShowGroupName = sceneGroupName
            local nextScene = SCENE_MANAGER:GetNextScene():GetName()
            -- this update can be called before the scene itself is set to showing,
            -- so make sure to set the active scene here so we can update the scene group bar correctly
            sceneGroup:SetActiveScene(nextScene)
            self:SetLastSceneGroupName(categoryInfo, sceneGroupName)
            self:SetupSceneGroupBar(category, sceneGroupName)
        elseif newState == SCENE_GROUP_SHOWN then
            local sceneGroupBarTutorialTrigger = self.sceneGroupInfo[sceneGroupName].sceneGroupBarTutorialTrigger
            if sceneGroupBarTutorialTrigger then
                TriggerTutorial(sceneGroupBarTutorialTrigger)
            end
        end
    end)

    for i = 1, sceneGroup:GetNumScenes() do
        local sceneName = sceneGroup:GetSceneName(i)
        self:AddRawScene(sceneName, category, categoryInfo, sceneGroupName)
    end

    if not self:HasLast(categoryInfo) then
        self:SetLastSceneGroupName(categoryInfo, sceneGroupName)
    end

    local sceneGroupBarFragment = ZO_FadeSceneFragment:New(self.sceneGroupBar)
    for i = 1, #menuBarIconData do
        local sceneName = menuBarIconData[i].descriptor
        local scene = SCENE_MANAGER:GetScene(sceneName)
        scene:AddFragment(sceneGroupBarFragment)
    end

    self.sceneGroupInfo[sceneGroupName] =
    {
        menuBarIconData = menuBarIconData,
        category = category,
        sceneGroupPreferredSceneFunction = sceneGroupPreferredSceneFunction,
        sceneGroupBarFragment = sceneGroupBarFragment,
        sceneGroupBarTutorialTrigger = sceneGroupBarTutorialTrigger,
    }
end

local FORCE_SELECTION = true
function MainMenu_Keyboard:EvaluateSceneGroupVisibilityOnEvent(sceneGroupName, event)
    local sceneInfo = self.sceneGroupInfo[sceneGroupName]
    if sceneInfo then
        EVENT_MANAGER:RegisterForEvent(self.control:GetName() .. sceneGroupName, event, function()
            if self.sceneShowGroupName == sceneGroupName then
                ZO_MenuBar_UpdateButtons(self.sceneGroupBar, FORCE_SELECTION)
            end
        end)
    end
end

function MainMenu_Keyboard:EvaluateSceneGroupVisibilityOnCallback(sceneGroupName, callbackName)
    local sceneInfo = self.sceneGroupInfo[sceneGroupName]
    if sceneInfo then
        CALLBACK_MANAGER:RegisterCallback(callbackName, function()
            if self.sceneShowGroupName == sceneGroupName then
                ZO_MenuBar_UpdateButtons(self.sceneGroupBar, FORCE_SELECTION)
            end
        end)
    end
end

function MainMenu_Keyboard:RefreshCategoryIndicators()
    for i, categoryLayoutData in ipairs(ZO_CATEGORY_LAYOUT_INFO) do
        local indicators = categoryLayoutData.indicators
        if indicators then
            local buttonControl = ZO_MenuBar_GetButtonControl(self.categoryBar, categoryLayoutData.descriptor)
            if buttonControl then
                local indicatorTexture = buttonControl:GetNamedChild("Indicator")
                local textures
                if type(indicators) == "table" then
                    textures = indicators
                elseif type(indicators) == "function" then
                    textures = indicators()
                end
                if textures and #textures > 0 then
                    indicatorTexture:ClearIcons()
                    for _, texture in ipairs(textures) do
                        indicatorTexture:AddIcon(texture)
                    end
                    indicatorTexture:Show()
                else
                    indicatorTexture:Hide()
                end
            end
        end
    end
end

function MainMenu_Keyboard:RefreshCategoryBar(forceSelection)
    if forceSelection == nil then
        forceSelection = FORCE_SELECTION
    end
    ZO_MenuBar_UpdateButtons(self.categoryBar, forceSelection)
    self:RefreshCategoryIndicators()
end

function MainMenu_Keyboard:AddButton(category, name, callback)
    local categoryInfo = self.categoryInfo[category]
    
    --sub category bar
    local numControls = #categoryInfo.barControls
    local button = CreateControlFromVirtual("ZO_MainMenu"..category.."Button", categoryInfo.subcategoryBar, "ZO_MainMenuSubcategoryButton", numControls + 1)
    local lastControl = categoryInfo.barControls[numControls]
    if(lastControl) then
        button:SetAnchor(TOPLEFT, lastControl, TOPRIGHT, 20, 0)
    else
        button:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
    end
    
    button:SetText(GetString(name))
    button:SetHandler("OnMouseUp", callback)

    table.insert(categoryInfo.barControls, button)
end

function MainMenu_Keyboard:IsShowing()
    return self.categoryBarFragment:IsShowing()
end

function MainMenu_Keyboard:Hide()
    SCENE_MANAGER:ShowBaseScene()
end

function MainMenu_Keyboard:UpdateSceneGroupBarEnabledStates(sceneGroupName)
    local menuBarIconData = self.sceneGroupInfo[sceneGroupName].menuBarIconData
    for i, layoutData in ipairs(menuBarIconData) do
        ZO_MenuBar_SetDescriptorEnabled(self.sceneGroupBar, layoutData.descriptor, (layoutData.enabled == nil or layoutData.enabled == true))
    end
end

function MainMenu_Keyboard:UpdateSceneGroupButtons(groupName)
    if self:IsShowing() and self.sceneShowGroupName == groupName then
        ZO_MenuBar_UpdateButtons(self.sceneGroupBar)
        if not ZO_MenuBar_GetSelectedDescriptor(self.sceneGroupBar) then
            ZO_MenuBar_SelectFirstVisibleButton(self.sceneGroupBar, true)
        end
    end
end

function MainMenu_Keyboard:SetupSceneGroupBar(category, sceneGroupName)
    local sceneGroupInfo = self.sceneGroupInfo[sceneGroupName]
    if sceneGroupInfo then
        -- This is a scene group
        ZO_MenuBar_ClearButtons(self.sceneGroupBar)

        local sceneGroupBarTutorialTrigger = sceneGroupInfo.sceneGroupBarTutorialTrigger
        if sceneGroupBarTutorialTrigger then
            local tutorialAnchor = ZO_Anchor:New(RIGHT, self.sceneGroupBarLabel, LEFT, -10, 0)
            TUTORIAL_SYSTEM:RegisterTriggerLayoutInfo(TUTORIAL_TYPE_POINTER_BOX, sceneGroupBarTutorialTrigger, self.control, sceneGroupInfo.sceneGroupBarFragment, tutorialAnchor)
        end

        local sceneGroup = SCENE_MANAGER:GetSceneGroup(sceneGroupName)
        local menuBarIconData = sceneGroupInfo.menuBarIconData
        for i, layoutData in ipairs(menuBarIconData) do
            local sceneName = layoutData.descriptor
            layoutData.callback = function()
                local currentCategoryName = self.sceneGroupBarLabel:GetText()
                self.sceneGroupBarLabel:SetText(GetString(layoutData.categoryName))

                if not self.ignoreCallbacks then
                    if MAIN_MENU_MANAGER:HasBlockingScene() then
                        local CLICKED_BY_MOUSE = true
                        local sceneData =
                        {
                            category = category,
                            sceneName = sceneName,
                            sceneGroup = sceneGroup,
                        }
                        MAIN_MENU_MANAGER:ActivatedBlockingScene_Scene(sceneData, CLICKED_BY_MOUSE)
                    else
                        -- If the current scene will need confirmation to hide then go back to the previous button. We'll select the button for this scene group if and when the scene shows.
                        if SCENE_MANAGER:WillCurrentSceneConfirmHide() then
                            local SKIP_ANIMATION = true
                            ZO_MenuBar_RestoreLastClickedButton(self.sceneGroupBar, SKIP_ANIMATION)
                            self.sceneGroupBarLabel:SetText(currentCategoryName)
                        end
                        SCENE_MANAGER:Show(sceneName)
                    end

                    if sceneGroupBarTutorialTrigger then
                        TUTORIAL_SYSTEM:RemoveTutorialByTrigger(TUTORIAL_TYPE_POINTER_BOX, sceneGroupBarTutorialTrigger)
                    end
                end
            end
            ZO_MenuBar_AddButton(self.sceneGroupBar, layoutData)
            local enabled = layoutData.enabled == nil or layoutData.enabled == true
            if layoutData.enabled and type(layoutData.enabled) == "function" then
                enabled = layoutData.enabled()
            end
            ZO_MenuBar_SetDescriptorEnabled(self.sceneGroupBar, layoutData.descriptor, enabled)
        end

        local activeSceneName = sceneGroup:GetActiveScene()
        local layoutData
        for i, iconData in ipairs(menuBarIconData) do
            if iconData.descriptor == activeSceneName then
                layoutData = iconData
                break
            end
        end

        self.ignoreCallbacks = true

        if layoutData then
            if not ZO_MenuBar_SelectDescriptor(self.sceneGroupBar, activeSceneName) then
                self.ignoreCallbacks = false
                ZO_MenuBar_SelectFirstVisibleButton(self.sceneGroupBar, true)
            end

            self.sceneGroupBarLabel:SetHidden(false)
            self.sceneGroupBarLabel:SetText(GetString(layoutData.categoryName))
        end

        self.ignoreCallbacks = false
    end
end

function MainMenu_Keyboard:Update(category, sceneName)
    SCENE_MANAGER:Show(sceneName)
end

function MainMenu_Keyboard:ShowScene(sceneName)
    local sceneInfo = self.sceneInfo[sceneName]
    if sceneInfo.sceneGroupName then
        self:ShowSceneGroup(sceneInfo.sceneGroupName, sceneName)
    else
        self:Update(sceneInfo.category, sceneName)
    end
end

function MainMenu_Keyboard:ToggleScene(sceneName)
    if SCENE_MANAGER:IsShowing(sceneName) then
        SCENE_MANAGER:ShowBaseScene()
    else
        self:RefreshCategoryBar()
        self:ShowScene(sceneName)
    end
end

function MainMenu_Keyboard:SetPreferredActiveScene(sceneGroupInfo, sceneGroup)
    if sceneGroupInfo.sceneGroupPreferredSceneFunction then
        local sceneNameToShow = sceneGroupInfo.sceneGroupPreferredSceneFunction()
        if sceneNameToShow then
            sceneGroup:SetActiveScene(sceneNameToShow)
        end
    end
end

function MainMenu_Keyboard:ShowSceneGroup(sceneGroupName, specificScene)
    local sceneGroup = SCENE_MANAGER:GetSceneGroup(sceneGroupName)
    if not specificScene then
        local sceneGroupInfo = self.sceneGroupInfo[sceneGroupName]
        self:SetPreferredActiveScene(sceneGroupInfo, sceneGroup)
        specificScene = sceneGroup:GetActiveScene()
    end

    if sceneGroup:IsShowing() then
        -- if the scene group is already showing then we can just select the
        -- descriptor on the scene group bar that matches the scene we want to
        -- show. If we just show the scene, the scene bar won't update correctly.
        local skipAnimation = not self:IsShowing()
        local RESELECT_IF_SELECTED = true -- Necessary if we are showing a scene group scene that doesn't have a descriptor and we want to switch back to the selected descriptor scene
        if not ZO_MenuBar_SelectDescriptor(self.sceneGroupBar, specificScene, skipAnimation, RESELECT_IF_SELECTED) then
            -- we didn't select the descriptor successfully, which means there is no
            -- matching descriptor for the specificScene
            -- To support GuildSelector_Keyboard, which has a scene in its scene group
            -- that doesn't have a descriptor, we will simply call to show the requested
            -- scene
            SCENE_MANAGER:Show(specificScene)
        end
    else
        SCENE_MANAGER:Show(specificScene)
    end
end

function MainMenu_Keyboard:ToggleSceneGroup(sceneGroupName, specificScene)
    local sceneGroupInfo = self.sceneGroupInfo[sceneGroupName]
    if self:IsShowing() and self.lastCategory == sceneGroupInfo.category then
        SCENE_MANAGER:ShowBaseScene()
    else
        self:ShowSceneGroup(sceneGroupName, specificScene)
    end
end

function MainMenu_Keyboard:ShowCategory(category)
    --Keyboard and gamepad aren't always one-to-one, so sometimes we might need a binding to do the exact same thing as a different binding
    local categoryLayoutInfo = ZO_CATEGORY_LAYOUT_INFO[category]
    if categoryLayoutInfo.alias then
        category = categoryLayoutInfo.alias
        categoryLayoutInfo = ZO_CATEGORY_LAYOUT_INFO[category]
    end

    if(categoryLayoutInfo.visible == nil or categoryLayoutInfo.visible()) then
        local categoryInfo = self.categoryInfo[category]
        if(categoryInfo.lastSceneName) then
            self:ShowScene(categoryInfo.lastSceneName)
        else
            self:ShowSceneGroup(categoryInfo.lastSceneGroupName)
        end
    end
end

do
    local function GetCategoryState(categoryInfo)
        if MAIN_MENU_MANAGER:IsPlayerDead() and categoryInfo.disableWhenDead then
            return MAIN_MENU_CATEGORY_DISABLED_WHILE_DEAD
        elseif MAIN_MENU_MANAGER:IsPlayerInCombat() and categoryInfo.disableWhenInCombat then
            return MAIN_MENU_CATEGORY_DISABLED_WHILE_IN_COMBAT
        elseif MAIN_MENU_MANAGER:IsPlayerReviving() and categoryInfo.disableWhenReviving then
            return MAIN_MENU_CATEGORY_DISABLED_WHILE_REVIVING
        elseif MAIN_MENU_MANAGER:IsPlayerSwimming() and categoryInfo.disableWhenSwimming then
            return MAIN_MENU_CATEGORY_DISABLED_WHILE_SWIMMING
        elseif MAIN_MENU_MANAGER:IsPlayerWerewolf() and categoryInfo.disableWhenWerewolf then
            return MAIN_MENU_CATEGORY_DISABLED_WHILE_WEREWOLF
        elseif MAIN_MENU_MANAGER:IsPlayerPassenger() and categoryInfo.disableWhenPassenger then
            return MAIN_MENU_CATEGORY_DISABLED_WHILE_PASSENGER
        else
            return MAIN_MENU_CATEGORY_ENABLED
        end
    end

    local function ZO_MainMenuManager_ToggleCategoryInternal(self, category)
        local categoryLayoutInfo = ZO_CATEGORY_LAYOUT_INFO[category]
        local categoryState = GetCategoryState(categoryLayoutInfo)

        if categoryState == MAIN_MENU_CATEGORY_DISABLED_WHILE_DEAD then
            ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_DEAD)
        elseif categoryState == MAIN_MENU_CATEGORY_DISABLED_WHILE_IN_COMBAT then
            ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_IN_COMBAT)
        elseif categoryState == MAIN_MENU_CATEGORY_DISABLED_WHILE_REVIVING then
            ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_REVIVING)
        elseif categoryState == MAIN_MENU_CATEGORY_DISABLED_WHILE_SWIMMING then
            ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_SWIMMING)
        elseif categoryState == MAIN_MENU_CATEGORY_DISABLED_WHILE_WEREWOLF then
            ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_WEREWOLF)
        elseif categoryState == MAIN_MENU_CATEGORY_DISABLED_WHILE_PASSENGER then
            ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_PASSENGER)
        else
            if(categoryLayoutInfo.visible == nil or categoryLayoutInfo.visible()) then
                local categoryInfo = self.categoryInfo[category]
                if(categoryInfo.lastSceneName) then
                    self:ToggleScene(categoryInfo.lastSceneName)
                else
                    self:ToggleSceneGroup(categoryInfo.lastSceneGroupName)
                end
            end
        end
    end

    function MainMenu_Keyboard:ToggleCategory(category)
        --Keyboard and gamepad aren't always one-to-one, so sometimes we might need a binding to do the exact same thing as a different binding
        local categoryLayoutInfo = ZO_CATEGORY_LAYOUT_INFO[category]
        if categoryLayoutInfo.alias then
            category = categoryLayoutInfo.alias
        end

        if MAIN_MENU_MANAGER:HasBlockingScene() then
            local sceneData = {
                category = category,
            }
            MAIN_MENU_MANAGER:ActivatedBlockingScene_Scene(sceneData)
        else
            ZO_MainMenuManager_ToggleCategoryInternal(self, category)
        end
    end

    function MainMenu_Keyboard:ShowLastCategory()
        local categoryLayoutInfo = ZO_CATEGORY_LAYOUT_INFO[self.lastCategory]
        local categoryState = GetCategoryState(categoryLayoutInfo)

        if categoryState == MAIN_MENU_CATEGORY_ENABLED then
            self:ShowCategory(self.lastCategory)
        else -- if a category is disabled, default to the character menu
            self:ToggleCategory(MENU_CATEGORY_CHARACTER)
        end
    end

    function MainMenu_Keyboard:UpdateCategories()
        for i = 1, #ZO_CATEGORY_LAYOUT_INFO do
            local categoryInfo = ZO_CATEGORY_LAYOUT_INFO[i]
            local shouldBeEnabled = GetCategoryState(categoryInfo) == MAIN_MENU_CATEGORY_ENABLED
            if not shouldBeEnabled and (self.lastCategory == i) and SCENE_MANAGER:IsShowing(categoryInfo.scene) then
                self:Hide()
            end
            ZO_MenuBar_SetDescriptorEnabled(self.categoryBar, i, shouldBeEnabled)
        end
    end
end

function MainMenu_Keyboard:ToggleLastCategory()
    self:ToggleCategory(self.lastCategory)
end

--Events

function MainMenu_Keyboard:OnCategoryClicked(category)
    if not self.ignoreCallbacks then
        if MAIN_MENU_MANAGER:HasBlockingScene() then
            local CLICKED_BY_MOUSE = true
            local sceneData =
            {
                category = category,
            }
            MAIN_MENU_MANAGER:ActivatedBlockingScene_Scene(sceneData, CLICKED_BY_MOUSE)
        else
            --If the scene will need confirmation to hide then go back to the previous button. We'll select the button for this category on the scene or scene group showing (if it is allowed).
            if SCENE_MANAGER:WillCurrentSceneConfirmHide() then
                local SKIP_ANIMATION = true
                ZO_MenuBar_RestoreLastClickedButton(self.categoryBar, SKIP_ANIMATION)
            end
            self:ShowCategory(category)
        end
    end
end

function MainMenu_Keyboard:OnSceneGroupTabClicked(sceneGroupName)
    if not self.ignoreCallbacks then
        self:ShowSceneGroup(sceneGroupName)
    end
end

function MainMenu_Keyboard:OnSceneGroupBarLabelTextChanged()
    -- SetText will get called before self.sceneGroupBar refreshes its anchors, so the position of the label needs
    -- to let that update before it notifies anyone of it's new rectangle
    zo_callLater(function() MAIN_MENU_KEYBOARD:FireCallbacks("OnSceneGroupBarLabelTextChanged", self.sceneGroupBarLabel) end, 10)
end

--Global XML

function ZO_MainMenuCategoryBarButton_OnMouseEnter(self)
    ZO_MenuBarButtonTemplate_OnMouseEnter(self)
    InitializeTooltip(InformationTooltip, self:GetParent(), LEFT, 15, 2)

    local buttonData = ZO_MenuBarButtonTemplate_GetData(self)
    local bindingString = ZO_Keybindings_GetHighestPriorityBindingStringFromAction(buttonData.binding)
    local button = self.m_object.m_menuBar:ButtonObjectForDescriptor(buttonData.descriptor)
    
    local tooltipText = GetString(SI_MAIN_MENU_TOOLTIP_DISABLED_BUTTON)
    if (button.m_state ~= BSTATE_DISABLED) then
        tooltipText = zo_strformat(SI_MAIN_MENU_KEYBIND, GetString(buttonData.categoryName), bindingString or GetString(SI_ACTION_IS_NOT_BOUND))
    end
    
    SetTooltipText(InformationTooltip, tooltipText)
end

function ZO_MainMenuCategoryBarButton_OnMouseExit(self)
    ZO_MenuBarButtonTemplate_OnMouseExit(self)
    ClearTooltip(InformationTooltip)
end

function ZO_MainMenu_OnSceneGroupBarLabelTextChanged()
    MAIN_MENU_KEYBOARD:OnSceneGroupBarLabelTextChanged()
end

function ZO_MainMenu_OnInitialized(self)
    MAIN_MENU_KEYBOARD = MainMenu_Keyboard:New(self)
    SYSTEMS:RegisterKeyboardObject("mainMenu", MAIN_MENU_KEYBOARD)
end
