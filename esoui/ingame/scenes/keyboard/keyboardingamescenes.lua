------------------------
--Achievements Scene
------------------------

local achievementsScene = SCENE_MANAGER:GetScene("achievements")
achievementsScene:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
achievementsScene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
achievementsScene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
achievementsScene:AddFragment(ACHIEVEMENTS_FRAGMENT)
achievementsScene:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL)
achievementsScene:AddFragment(RIGHT_BG_FRAGMENT)
achievementsScene:AddFragment(TREE_UNDERLAY_FRAGMENT)
achievementsScene:AddFragment(TITLE_FRAGMENT)
achievementsScene:AddFragment(JOURNAL_TITLE_FRAGMENT)
achievementsScene:AddFragment(CODEX_WINDOW_SOUNDS)
achievementsScene:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_ACHIEVEMENTS_OPENED))

--------------------
--Quest Journal Scene
--------------------

QUEST_JOURNAL_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
QUEST_JOURNAL_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
QUEST_JOURNAL_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
QUEST_JOURNAL_SCENE:AddFragment(QUEST_JOURNAL_FRAGMENT)
QUEST_JOURNAL_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL)
QUEST_JOURNAL_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
QUEST_JOURNAL_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)
QUEST_JOURNAL_SCENE:AddFragment(TITLE_FRAGMENT)
QUEST_JOURNAL_SCENE:AddFragment(JOURNAL_TITLE_FRAGMENT)
QUEST_JOURNAL_SCENE:AddFragment(CODEX_WINDOW_SOUNDS)
QUEST_JOURNAL_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_JOURNAL_OPENED))

-----------------------
--Provisioner Scene
-----------------------
PROVISIONER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
PROVISIONER_SCENE:AddFragment(PROVISIONER_FRAGMENT)
PROVISIONER_SCENE:AddFragment(CRAFTING_RESULTS_FRAGMENT)
PROVISIONER_SCENE:AddFragment(RIGHT_PANEL_BG_FRAGMENT)
PROVISIONER_SCENE:AddFragment(ZO_WindowSoundFragment:New(SOUNDS.PROVISIONING_OPENED, SOUNDS.PROVISIONING_CLOSED))
PROVISIONER_SCENE:AddFragment(PLAYER_PROGRESS_BAR_FRAGMENT)

-----------------------
--Friends List
-----------------------

FRIENDS_LIST_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
FRIENDS_LIST_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
FRIENDS_LIST_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
FRIENDS_LIST_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
FRIENDS_LIST_SCENE:AddFragment(FRIENDS_LIST_FRAGMENT)
FRIENDS_LIST_SCENE:AddFragment(DISPLAY_NAME_FRAGMENT)
FRIENDS_LIST_SCENE:AddFragment(TITLE_FRAGMENT)
FRIENDS_LIST_SCENE:AddFragment(CONTACTS_TITLE_FRAGMENT)
FRIENDS_LIST_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)
FRIENDS_LIST_SCENE:AddFragment(CONTACTS_WINDOW_SOUNDS)
FRIENDS_LIST_SCENE:AddFragment(FRIENDS_ONLINE_FRAGMENT)
FRIENDS_LIST_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_CONTACTS_OPENED))

--------------------------
--Ignore List
--------------------------

IGNORE_LIST_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
IGNORE_LIST_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
IGNORE_LIST_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
IGNORE_LIST_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
IGNORE_LIST_SCENE:AddFragment(DISPLAY_NAME_FRAGMENT)
IGNORE_LIST_SCENE:AddFragment(IGNORE_LIST_FRAGMENT)
IGNORE_LIST_SCENE:AddFragment(TITLE_FRAGMENT)
IGNORE_LIST_SCENE:AddFragment(CONTACTS_TITLE_FRAGMENT)
IGNORE_LIST_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)
IGNORE_LIST_SCENE:AddFragment(CONTACTS_WINDOW_SOUNDS)
IGNORE_LIST_SCENE:AddFragment(FRIENDS_ONLINE_FRAGMENT)
IGNORE_LIST_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_CONTACTS_OPENED))

----------------
--Trade Scene
----------------

local tradeScene = SCENE_MANAGER:GetScene("trade")
tradeScene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
tradeScene:AddFragment(TITLE_FRAGMENT)
tradeScene:AddFragment(PLAYER_TRADE_TITLE_FRAGMENT)
tradeScene:AddFragment(RIGHT_BG_FRAGMENT)
tradeScene:AddFragment(TRADE_FRAGMENT)
tradeScene:AddFragment(INVENTORY_FRAGMENT)
tradeScene:AddFragment(BACKPACK_PLAYER_TRADE_LAYOUT_FRAGMENT)
tradeScene:AddFragment(TRADE_WINDOW_SOUNDS)
tradeScene:AddFragment(PLAYER_PROGRESS_BAR_FRAGMENT)
tradeScene:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_TRADE_OPENED))

SYSTEMS:RegisterKeyboardRootScene("trade", tradeScene)

-----------------------
--Guild Ranks
-----------------------

GUILD_RANKS_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
GUILD_RANKS_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
GUILD_RANKS_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
GUILD_RANKS_SCENE:AddFragment(GUILD_SELECTOR_FRAGMENT)
GUILD_RANKS_SCENE:AddFragment(GUILD_RANKS_FRAGMENT)
GUILD_RANKS_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
GUILD_RANKS_SCENE:AddFragment(DISPLAY_NAME_FRAGMENT)
GUILD_RANKS_SCENE:AddFragment(GUILD_SHARED_INFO_FRAGMENT)
GUILD_RANKS_SCENE:AddFragment(GUILD_WINDOW_SOUNDS)
GUILD_RANKS_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)
GUILD_RANKS_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)
GUILD_RANKS_SCENE:AddFragment(GUILD_SELECTOR_ACTION_LAYER_FRAGMENT)

-----------------------
--Guild Roster
-----------------------

GUILD_ROSTER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
GUILD_ROSTER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
GUILD_ROSTER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
GUILD_ROSTER_SCENE:AddFragment(GUILD_SELECTOR_FRAGMENT)
GUILD_ROSTER_SCENE:AddFragment(GUILD_ROSTER_FRAGMENT)
GUILD_ROSTER_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
GUILD_ROSTER_SCENE:AddFragment(DISPLAY_NAME_FRAGMENT)
GUILD_ROSTER_SCENE:AddFragment(GUILD_SHARED_INFO_FRAGMENT)
GUILD_ROSTER_SCENE:AddFragment(GUILD_WINDOW_SOUNDS)
GUILD_ROSTER_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_GUILDS_ROSTER_OPENED))
GUILD_ROSTER_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)
GUILD_ROSTER_SCENE:AddFragment(GUILD_SELECTOR_ACTION_LAYER_FRAGMENT)

-------------------
--Trading House
-------------------

TRADING_HOUSE_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
TRADING_HOUSE_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
TRADING_HOUSE_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)
TRADING_HOUSE_SCENE:AddFragment(TRADING_HOUSE_FRAGMENT)
TRADING_HOUSE_SCENE:AddFragment(BACKPACK_TRADING_HOUSE_LAYOUT_FRAGMENT)
TRADING_HOUSE_SCENE:AddFragment(TRADING_HOUSE_WINDOW_SOUNDS)
TRADING_HOUSE_SCENE:AddFragment(PLAYER_PROGRESS_BAR_FRAGMENT)

----------------
--Interact Scene
----------------

local interactScene = SCENE_MANAGER:GetScene("interact")
interactScene:AddFragment(MOUSE_UI_MODE_FRAGMENT)
interactScene:AddFragment(INTERACT_FRAGMENT)
interactScene:AddFragment(INTERACT_WINDOW_SOUNDS)
interactScene:AddFragment(PLAYER_PROGRESS_BAR_FRAGMENT)
interactScene:AddFragment(ZO_ActionLayerFragment:New("Conversation"))

SYSTEMS:RegisterKeyboardRootScene(ZO_INTERACTION_SYSTEM_NAME, interactScene)

-------------------
--Fence Scene
-------------------

local fenceKeyboardScene = SCENE_MANAGER:GetScene("fence_keyboard")
fenceKeyboardScene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
fenceKeyboardScene:AddFragment(RIGHT_PANEL_BG_FRAGMENT)
fenceKeyboardScene:AddFragment(FENCE_MENU_FRAGMENT)
fenceKeyboardScene:AddFragment(STORE_WINDOW_SOUNDS)
fenceKeyboardScene:AddFragment(PLAYER_PROGRESS_BAR_FRAGMENT)

-----------------------
--Dyeing Scene
-----------------------

DYEING_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
DYEING_SCENE:AddFragment(DYEING_FRAGMENT)
DYEING_SCENE:AddFragment(RIGHT_PANEL_BG_FRAGMENT)
DYEING_SCENE:AddFragment(MEDIUM_LEFT_PANEL_BG_FRAGMENT)
DYEING_SCENE:AddFragment(ZO_WindowSoundFragment:New(SOUNDS.DYEING_OPENED, SOUNDS.DYEING_CLOSED))

-----------------------
--Alchemy Scene
-----------------------

ALCHEMY_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
ALCHEMY_SCENE:AddFragment(ALCHEMY_FRAGMENT)
ALCHEMY_SCENE:AddFragment(CRAFTING_RESULTS_FRAGMENT)
ALCHEMY_SCENE:AddFragment(RIGHT_PANEL_BG_FRAGMENT)
ALCHEMY_SCENE:AddFragment(ZO_WindowSoundFragment:New(SOUNDS.ALCHEMY_OPENED, SOUNDS.ALCHEMY_CLOSED))
ALCHEMY_SCENE:AddFragment(PLAYER_PROGRESS_BAR_FRAGMENT)
SYSTEMS:RegisterKeyboardRootScene("alchemy", ALCHEMY_SCENE)
SYSTEMS:RegisterKeyboardObject("alchemy", ALCHEMY)

-----------------------
--Enchanting Scene
-----------------------

ENCHANTING_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
ENCHANTING_SCENE:AddFragment(ENCHANTING_FRAGMENT)
ENCHANTING_SCENE:AddFragment(CRAFTING_RESULTS_FRAGMENT)
ENCHANTING_SCENE:AddFragment(RIGHT_PANEL_BG_FRAGMENT)
ENCHANTING_SCENE:AddFragment(ZO_WindowSoundFragment:New(SOUNDS.ENCHANTING_OPENED, SOUNDS.ENCHANTING_CLOSED))
ENCHANTING_SCENE:AddFragment(PLAYER_PROGRESS_BAR_FRAGMENT)

-----------------------
--Smithing Scene
-----------------------

SMITHING_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
SMITHING_SCENE:AddFragment(SMITHING_FRAGMENT)
SMITHING_SCENE:AddFragment(CRAFTING_RESULTS_FRAGMENT)
SMITHING_SCENE:AddFragment(RIGHT_PANEL_BG_FRAGMENT)
SMITHING_SCENE:AddFragment(ZO_WindowSoundFragment:New(SOUNDS.SMITHING_OPENED, SOUNDS.SMITHING_CLOSED))
SMITHING_SCENE:AddFragmentGroup(FRAGMENT_GROUP.READ_ONLY_EQUIPPED_ITEMS)
SMITHING_SCENE:AddFragment(PLAYER_PROGRESS_BAR_FRAGMENT)

----------------
--Group List
----------------

GROUP_LIST_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
GROUP_LIST_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
GROUP_LIST_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
GROUP_LIST_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
GROUP_LIST_SCENE:AddFragment(GROUP_LIST_FRAGMENT)
GROUP_LIST_SCENE:AddFragment(DISPLAY_NAME_FRAGMENT)
GROUP_LIST_SCENE:AddFragment(TITLE_FRAGMENT)
GROUP_LIST_SCENE:AddFragment(GROUP_TITLE_FRAGMENT)
GROUP_LIST_SCENE:AddFragment(GROUP_MEMBERS_FRAGMENT)
GROUP_LIST_SCENE:AddFragment(PREFERRED_ROLES_FRAGMENT)
GROUP_LIST_SCENE:AddFragment(GROUP_CENTER_INFO_FRAGMENT)
GROUP_LIST_SCENE:AddFragment(SEARCHING_FOR_GROUP_FRAGMENT)
GROUP_LIST_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_YOUR_GROUP_OPENED))
GROUP_LIST_SCENE:AddFragment(GROUP_WINDOW_SOUNDS)
GROUP_LIST_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)

-------------------
--Grouping Tools
-------------------

GROUPING_TOOLS_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
GROUPING_TOOLS_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
GROUPING_TOOLS_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
GROUPING_TOOLS_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
GROUPING_TOOLS_SCENE:AddFragment(GROUPING_TOOLS_FRAGMENT)
GROUPING_TOOLS_SCENE:AddFragment(DISPLAY_NAME_FRAGMENT)
GROUPING_TOOLS_SCENE:AddFragment(TITLE_FRAGMENT)
GROUPING_TOOLS_SCENE:AddFragment(GROUP_TITLE_FRAGMENT)
GROUPING_TOOLS_SCENE:AddFragment(GROUP_MEMBERS_FRAGMENT)
GROUPING_TOOLS_SCENE:AddFragment(PREFERRED_ROLES_FRAGMENT)
GROUPING_TOOLS_SCENE:AddFragment(GROUP_CENTER_INFO_FRAGMENT)
GROUPING_TOOLS_SCENE:AddFragment(SEARCHING_FOR_GROUP_FRAGMENT)
GROUPING_TOOLS_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_GROUP_TOOLS_OPENED))
GROUPING_TOOLS_SCENE:AddFragment(GROUP_WINDOW_SOUNDS)
GROUPING_TOOLS_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)

-------------------
--Campaign Browser Scene
-------------------

CAMPAIGN_BROWSER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
CAMPAIGN_BROWSER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
CAMPAIGN_BROWSER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
CAMPAIGN_BROWSER_SCENE:AddFragment(CAMPAIGN_BROWSER_FRAGMENT)
CAMPAIGN_BROWSER_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)
CAMPAIGN_BROWSER_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
CAMPAIGN_BROWSER_SCENE:AddFragment(TITLE_FRAGMENT)
CAMPAIGN_BROWSER_SCENE:AddFragment(ALLIANCE_WAR_TITLE_FRAGMENT)
CAMPAIGN_BROWSER_SCENE:AddFragment(CURRENT_CAMPAIGNS_FRAGMENT)
CAMPAIGN_BROWSER_SCENE:AddFragment(CAMPAIGN_AVA_RANK_FRAGMENT)
CAMPAIGN_BROWSER_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_CAMPAIGN_BROWSER_OPENED))
CAMPAIGN_BROWSER_SCENE:AddFragment(ALLIANCE_WAR_WINDOW_SOUNDS)
CAMPAIGN_BROWSER_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_AVA)

-------------------
--Campaign Overview Scene
-------------------

CAMPAIGN_OVERVIEW_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
CAMPAIGN_OVERVIEW_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
CAMPAIGN_OVERVIEW_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
CAMPAIGN_OVERVIEW_SCENE:AddFragment(CAMPAIGN_OVERVIEW_FRAGMENT)
CAMPAIGN_OVERVIEW_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
CAMPAIGN_OVERVIEW_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)
CAMPAIGN_OVERVIEW_SCENE:AddFragment(TITLE_FRAGMENT)
CAMPAIGN_OVERVIEW_SCENE:AddFragment(ALLIANCE_WAR_TITLE_FRAGMENT)
CAMPAIGN_OVERVIEW_SCENE:AddFragment(CURRENT_CAMPAIGNS_FRAGMENT)
CAMPAIGN_OVERVIEW_SCENE:AddFragment(CAMPAIGN_SELECTOR_FRAGMENT)
CAMPAIGN_OVERVIEW_SCENE:AddFragment(CAMPAIGN_AVA_RANK_FRAGMENT)
CAMPAIGN_OVERVIEW_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_CAMPAIGN_OVERVIEW_OPENED))
CAMPAIGN_OVERVIEW_SCENE:AddFragment(ALLIANCE_WAR_WINDOW_SOUNDS)
CAMPAIGN_OVERVIEW_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_AVA)

-------------------
--Leaderboards Scene
-------------------
LEADERBOARDS_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
LEADERBOARDS_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
LEADERBOARDS_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
LEADERBOARDS_SCENE:AddFragment(LEADERBOARDS_FRAGMENT)
LEADERBOARDS_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL)
LEADERBOARDS_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
LEADERBOARDS_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)
LEADERBOARDS_SCENE:AddFragment(TITLE_FRAGMENT)
LEADERBOARDS_SCENE:AddFragment(JOURNAL_TITLE_FRAGMENT)
LEADERBOARDS_SCENE:AddFragment(CODEX_WINDOW_SOUNDS)
LEADERBOARDS_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_LEADERBOARDS_OPENED))

--------------------
--Cadwell's Almanac Scene
--------------------

local cadwellsAlmanacScene = ZO_Scene:New("cadwellsAlmanac", SCENE_MANAGER)
cadwellsAlmanacScene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
cadwellsAlmanacScene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
cadwellsAlmanacScene:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
cadwellsAlmanacScene:AddFragment(CADWELLS_ALMANAC_FRAGMENT)
cadwellsAlmanacScene:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL)
cadwellsAlmanacScene:AddFragment(RIGHT_BG_FRAGMENT)
cadwellsAlmanacScene:AddFragment(TREE_UNDERLAY_FRAGMENT)
cadwellsAlmanacScene:AddFragment(TITLE_FRAGMENT)
cadwellsAlmanacScene:AddFragment(JOURNAL_TITLE_FRAGMENT)
cadwellsAlmanacScene:AddFragment(CODEX_WINDOW_SOUNDS)
cadwellsAlmanacScene:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_CADWELLS_ALMANAC_OPENED))

-------------------
--Stable Scene
-------------------

local stablesScene = SCENE_MANAGER:GetScene("stables")
stablesScene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
stablesScene:AddFragment(RIGHT_PANEL_BG_FRAGMENT)
stablesScene:AddFragment(STABLES_MENU_FRAGMENT)
stablesScene:AddFragment(PLAYER_PROGRESS_BAR_FRAGMENT)
stablesScene:AddFragment(STORE_WINDOW_SOUNDS)

-------------------
--Collections Book Scene
-------------------

COLLECTIONS_BOOK_SCENE = SCENE_MANAGER:GetScene("collectionsBook")
COLLECTIONS_BOOK_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
COLLECTIONS_BOOK_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
COLLECTIONS_BOOK_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
COLLECTIONS_BOOK_SCENE:AddFragment(COLLECTIONS_BOOK_FRAGMENT)
COLLECTIONS_BOOK_SCENE:AddFragment(PLAYER_PROGRESS_BAR_FRAGMENT)
COLLECTIONS_BOOK_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
COLLECTIONS_BOOK_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL)
COLLECTIONS_BOOK_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)
COLLECTIONS_BOOK_SCENE:AddFragment(COLLECTIONS_WINDOW_SOUNDS)
COLLECTIONS_BOOK_SCENE:AddFragment(TITLE_FRAGMENT)
COLLECTIONS_BOOK_SCENE:AddFragment(COLLECTIONS_TITLE_FRAGMENT)
COLLECTIONS_BOOK_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_COLLECTIONS_OPENED))

-------------------
--Notifications
-------------------

NOTIFICATIONS_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
NOTIFICATIONS_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
NOTIFICATIONS_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
NOTIFICATIONS_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
NOTIFICATIONS_SCENE:AddFragment(NOTIFICATIONS_FRAGMENT)
NOTIFICATIONS_SCENE:AddFragment(TITLE_FRAGMENT)
NOTIFICATIONS_SCENE:AddFragment(NOTIFICATIONS_TITLE_FRAGMENT)
NOTIFICATIONS_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_NOTIFICATIONS_OPENED))
NOTIFICATIONS_SCENE:AddFragment(NOTIFICATIONS_WINDOW_SOUNDS)
NOTIFICATIONS_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)

--------------------
--Help Customer Support Scene
--------------------

HELP_CUSTOMER_SUPPORT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
HELP_CUSTOMER_SUPPORT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
HELP_CUSTOMER_SUPPORT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
HELP_CUSTOMER_SUPPORT_SCENE:AddFragment(HELP_FEEDBACK_FRAGMENT)
HELP_CUSTOMER_SUPPORT_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL)
HELP_CUSTOMER_SUPPORT_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
HELP_CUSTOMER_SUPPORT_SCENE:AddFragment(TITLE_FRAGMENT)
HELP_CUSTOMER_SUPPORT_SCENE:AddFragment(HELP_TITLE_FRAGMENT)
HELP_CUSTOMER_SUPPORT_SCENE:AddFragment(HELP_WINDOW_SOUNDS)
HELP_CUSTOMER_SUPPORT_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_HELP_CUSTOMER_SUPPORT_OPENED))

-------------------------
--Help Tutorials Scene
-------------------------

local helpTutorialsScene = ZO_Scene:New("helpTutorials", SCENE_MANAGER)
helpTutorialsScene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
helpTutorialsScene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
helpTutorialsScene:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
helpTutorialsScene:AddFragment(HELP_TUTORIALS_FRAGMENT)
helpTutorialsScene:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL)
helpTutorialsScene:AddFragment(RIGHT_BG_FRAGMENT)
helpTutorialsScene:AddFragment(TREE_UNDERLAY_FRAGMENT)
helpTutorialsScene:AddFragment(TITLE_FRAGMENT)
helpTutorialsScene:AddFragment(HELP_TITLE_FRAGMENT)
helpTutorialsScene:AddFragment(HELP_WINDOW_SOUNDS)
helpTutorialsScene:AddFragment(MINIMIZE_CHAT_FRAGMENT)
helpTutorialsScene:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_HELP_TUTORIALS_OPENED))

-----------------------
--Guild Create
-----------------------

GUILD_CREATE_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
GUILD_CREATE_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
GUILD_CREATE_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
GUILD_CREATE_SCENE:AddFragment(GUILD_CREATE_FRAGMENT)
GUILD_CREATE_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
GUILD_CREATE_SCENE:AddFragment(GUILD_SELECTOR_FRAGMENT)
GUILD_CREATE_SCENE:AddFragment(GUILD_WINDOW_SOUNDS)
GUILD_CREATE_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)
GUILD_CREATE_SCENE:AddFragment(GUILD_SELECTOR_ACTION_LAYER_FRAGMENT)

--------------------------
--Guild Home
--------------------------

GUILD_HOME_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
GUILD_HOME_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
GUILD_HOME_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
GUILD_HOME_SCENE:AddFragment(GUILD_SELECTOR_FRAGMENT)
GUILD_HOME_SCENE:AddFragment(GUILD_HOME_FRAGMENT)
GUILD_HOME_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
GUILD_HOME_SCENE:AddFragment(DISPLAY_NAME_FRAGMENT)
GUILD_HOME_SCENE:AddFragment(GUILD_SHARED_INFO_FRAGMENT)
GUILD_HOME_SCENE:AddFragment(GUILD_WINDOW_SOUNDS)
GUILD_HOME_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)
GUILD_HOME_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_GUILDS_HOME_OPENED))
GUILD_HOME_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)
GUILD_HOME_SCENE:AddFragment(GUILD_SELECTOR_ACTION_LAYER_FRAGMENT)

-----------------------
--Guild History
-----------------------

GUILD_HISTORY_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
GUILD_HISTORY_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
GUILD_HISTORY_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
GUILD_HISTORY_SCENE:AddFragment(GUILD_SELECTOR_FRAGMENT)
GUILD_HISTORY_SCENE:AddFragment(GUILD_HISTORY_FRAGMENT)
GUILD_HISTORY_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
GUILD_HISTORY_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)
GUILD_HISTORY_SCENE:AddFragment(DISPLAY_NAME_FRAGMENT)
GUILD_HISTORY_SCENE:AddFragment(GUILD_SHARED_INFO_FRAGMENT)
GUILD_HISTORY_SCENE:AddFragment(GUILD_WINDOW_SOUNDS)
GUILD_HISTORY_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)
GUILD_HISTORY_SCENE:AddFragment(GUILD_SELECTOR_ACTION_LAYER_FRAGMENT)

-----------------------
--Guild Heraldry
-----------------------

GUILD_HERALDRY_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
GUILD_HERALDRY_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
GUILD_HERALDRY_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
GUILD_HERALDRY_SCENE:AddFragment(GUILD_SELECTOR_FRAGMENT)
GUILD_HERALDRY_SCENE:AddFragment(GUILD_HERALDRY_FRAGMENT)
GUILD_HERALDRY_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
GUILD_HERALDRY_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)
GUILD_HERALDRY_SCENE:AddFragment(DISPLAY_NAME_FRAGMENT)
GUILD_HERALDRY_SCENE:AddFragment(GUILD_SHARED_INFO_FRAGMENT)
GUILD_HERALDRY_SCENE:AddFragment(GUILD_WINDOW_SOUNDS)
GUILD_HERALDRY_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_GUILDS_HERALDRY_OPENED))
GUILD_HERALDRY_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)
GUILD_HERALDRY_SCENE:AddFragment(GUILD_SELECTOR_ACTION_LAYER_FRAGMENT)

-------------------------
--Lore Library
-------------------------

LORE_LIBRARY_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
LORE_LIBRARY_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
LORE_LIBRARY_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
LORE_LIBRARY_SCENE:AddFragment(LORE_LIBRARY_FRAGMENT)
LORE_LIBRARY_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL)
LORE_LIBRARY_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
LORE_LIBRARY_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)
LORE_LIBRARY_SCENE:AddFragment(TITLE_FRAGMENT)
LORE_LIBRARY_SCENE:AddFragment(JOURNAL_TITLE_FRAGMENT)
LORE_LIBRARY_SCENE:AddFragment(CODEX_WINDOW_SOUNDS)
LORE_LIBRARY_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_LORE_LIBRARY_OPENED))

----------------
--Mail Inbox Scene
----------------

MAIL_INBOX_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
MAIL_INBOX_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
MAIL_INBOX_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
MAIL_INBOX_SCENE:AddFragment(TITLE_FRAGMENT)
MAIL_INBOX_SCENE:AddFragment(MAIL_TITLE_FRAGMENT)
MAIL_INBOX_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
MAIL_INBOX_SCENE:AddFragment(MAIL_INBOX_FRAGMENT)
MAIL_INBOX_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)
MAIL_INBOX_SCENE:AddFragment(MAIL_WINDOW_SOUNDS)
MAIL_INBOX_SCENE:AddFragment(MAIL_INTERACTION_FRAGMENT)
MAIL_INBOX_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_MAIL_OPENED))

----------------
--Mail Send Scene
----------------

MAIL_SEND_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
MAIL_SEND_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
MAIL_SEND_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_KEYBOARD_CURRENT)
MAIL_SEND_SCENE:AddFragment(TITLE_FRAGMENT)
MAIL_SEND_SCENE:AddFragment(MAIL_TITLE_FRAGMENT)
MAIL_SEND_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
MAIL_SEND_SCENE:AddFragment(MAIL_SEND_FRAGMENT)
MAIL_SEND_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SOCIAL)
MAIL_SEND_SCENE:AddFragment(MAIL_WINDOW_SOUNDS)
MAIL_SEND_SCENE:AddFragment(INVENTORY_FRAGMENT)
MAIL_SEND_SCENE:AddFragment(BACKPACK_MAIL_LAYOUT_FRAGMENT)
MAIL_SEND_SCENE:AddFragment(MAIL_INTERACTION_FRAGMENT)
MAIL_SEND_SCENE:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_MAIL_OPENED))

------------------------
--World Map
------------------------

WORLD_MAP_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
WORLD_MAP_SCENE:AddFragment(UNIFORM_BLUR_FRAGMENT)
WORLD_MAP_SCENE:AddFragment(WORLD_MAP_FRAGMENT)
WORLD_MAP_SCENE:AddFragment(WORLD_MAP_CORNER_FRAGMENT)
WORLD_MAP_SCENE:AddFragment(WORLD_MAP_INFO_FRAGMENT)
WORLD_MAP_SCENE:AddFragment(WORLD_MAP_INFO_BG_FRAGMENT)
WORLD_MAP_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_MAP)
WORLD_MAP_SCENE:AddFragment(MAP_WINDOW_SOUNDS)
WORLD_MAP_SCENE:AddFragment(WORLD_MAP_ZOOM_FRAGMENT)

-------------------
--Store Scene
-------------------

local storeScene = SCENE_MANAGER:GetScene("store")
storeScene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
storeScene:AddFragment(RIGHT_PANEL_BG_FRAGMENT)
storeScene:AddFragment(STORE_MENU_FRAGMENT)
storeScene:AddFragment(STORE_WINDOW_SOUNDS)
storeScene:AddFragment(PLAYER_PROGRESS_BAR_FRAGMENT)
storeScene:AddFragment(ZO_TutorialTriggerFragment:New(TUTORIAL_TRIGGER_STORE_OPENED))
storeScene:AddFragment(BACKPACK_STORE_LAYOUT_FRAGMENT)

-------------------
--Main Menu
-------------------

MAIN_MENU_KEYBOARD:AddCategoryAreaFragment(TOP_BAR_FRAGMENT)

--World Map
MAIN_MENU_KEYBOARD:AddScene(MENU_CATEGORY_MAP, "worldMap")

--Market

MAIN_MENU_KEYBOARD:AddScene(MENU_CATEGORY_MARKET, "market")

--Inventory

MAIN_MENU_KEYBOARD:AddScene(MENU_CATEGORY_INVENTORY, "inventory")

--Character

MAIN_MENU_KEYBOARD:AddScene(MENU_CATEGORY_CHARACTER, "stats")

--Skills

MAIN_MENU_KEYBOARD:AddScene(MENU_CATEGORY_SKILLS, "skills")

--Champion

MAIN_MENU_KEYBOARD:AddScene(MENU_CATEGORY_CHAMPION, "championPerks")

--Notifications

MAIN_MENU_KEYBOARD:AddScene(MENU_CATEGORY_NOTIFICATIONS, "notifications")

--Collections

MAIN_MENU_KEYBOARD:AddScene(MENU_CATEGORY_COLLECTIONS, "collectionsBook")

--Group SceneGroup

do
    local iconData = {
        {
            categoryName = SI_WINDOW_TITLE_GROUP_LIST,
            descriptor = "groupList",
            normal = "EsoUI/Art/LFG/LFG_tabIcon_myGroup_up.dds",
            pressed = "EsoUI/Art/LFG/LFG_tabIcon_myGroup_down.dds",
            highlight = "EsoUI/Art/LFG/LFG_tabIcon_myGroup_over.dds",
        },
        {
            categoryName = SI_WINDOW_TITLE_GROUPING_TOOLS,
            descriptor = "groupingToolsKeyboard",
            normal = "EsoUI/Art/LFG/LFG_tabIcon_groupTools_up.dds",
            pressed = "EsoUI/Art/LFG/LFG_tabIcon_groupTools_down.dds",
            highlight = "EsoUI/Art/LFG/LFG_tabIcon_groupTools_over.dds",
        },
    }
    local function SceneGroupScenePreference()
        if IsUnitGrouped("player") then
            return "groupList"
        else
            return "groupingToolsKeyboard"
        end
    end
    SCENE_MANAGER:AddSceneGroup("groupSceneGroup", ZO_SceneGroup:New("groupList", "groupingToolsKeyboard"))
    MAIN_MENU_KEYBOARD:AddSceneGroup(MENU_CATEGORY_GROUP, "groupSceneGroup", iconData, SceneGroupScenePreference)
end

--Contacts

do
    local iconData = {
        {
            categoryName = SI_WINDOW_TITLE_FRIENDS_LIST,
            descriptor = "friendsList",
            normal = "EsoUI/Art/Contacts/tabIcon_friends_up.dds",
            pressed = "EsoUI/Art/Contacts/tabIcon_friends_down.dds",
            highlight = "EsoUI/Art/Contacts/tabIcon_friends_over.dds",
        },
        {
            categoryName = SI_IGNORE_LIST_PANEL_TITLE,
            descriptor = "ignoreList",
            normal = "EsoUI/Art/Contacts/tabIcon_ignored_up.dds",
            pressed = "EsoUI/Art/Contacts/tabIcon_ignored_down.dds",
            highlight = "EsoUI/Art/Contacts/tabIcon_ignored_over.dds",
        },
    }
    SCENE_MANAGER:AddSceneGroup("contactsSceneGroup", ZO_SceneGroup:New("friendsList", "ignoreList"))
    MAIN_MENU_KEYBOARD:AddSceneGroup(MENU_CATEGORY_CONTACTS, "contactsSceneGroup", iconData)
end

--Guilds

do
    local iconData = {
        {
            categoryName = SI_WINDOW_TITLE_GUILD_HOME,
            descriptor = "guildHome",
            normal = "EsoUI/Art/Guild/tabIcon_home_up.dds",
            pressed = "EsoUI/Art/Guild/tabIcon_home_down.dds",
            disabled = "EsoUI/Art/Guild/tabIcon_home_disabled.dds",
            highlight = "EsoUI/Art/Guild/tabIcon_home_over.dds",
        },
        {
            categoryName = SI_WINDOW_TITLE_GUILD_ROSTER,
            descriptor = "guildRoster",
            normal = "EsoUI/Art/Guild/tabIcon_roster_up.dds",
            pressed = "EsoUI/Art/Guild/tabIcon_roster_down.dds",
            disabled = "EsoUI/Art/Guild/tabIcon_roster_disabled.dds",
            highlight = "EsoUI/Art/Guild/tabIcon_roster_over.dds",
        },
        {
            categoryName = SI_WINDOW_TITLE_GUILD_RANKS,
            descriptor = "guildRanks",
            normal = "EsoUI/Art/Guild/tabIcon_ranks_up.dds",
            pressed = "EsoUI/Art/Guild/tabIcon_ranks_down.dds",
            disabled = "EsoUI/Art/Guild/tabIcon_ranks_disabled.dds",
            highlight = "EsoUI/Art/Guild/tabIcon_ranks_over.dds",
        },
        {
            categoryName = SI_WINDOW_TITLE_GUILD_HERALDRY,
            descriptor = "guildHeraldry",
            visible = function() return GUILD_HERALDRY:IsEnabled() end,
            normal = "EsoUI/Art/Guild/tabIcon_heraldry_up.dds",
            pressed = "EsoUI/Art/Guild/tabIcon_heraldry_down.dds",
            disabled = "EsoUI/Art/Guild/tabIcon_heraldry_disabled.dds",
            highlight = "EsoUI/Art/Guild/tabIcon_heraldry_over.dds",
        },
        {
            categoryName = SI_WINDOW_TITLE_GUILD_HISTORY,
            descriptor = "guildHistory",
            normal = "EsoUI/Art/Guild/tabIcon_history_up.dds",
            pressed = "EsoUI/Art/Guild/tabIcon_history_down.dds",
            disabled = "EsoUI/Art/Guild/tabIcon_history_disabled.dds",
            highlight = "EsoUI/Art/Guild/tabIcon_history_over.dds",
        }
    }
    SCENE_MANAGER:AddSceneGroup("guildsSceneGroup", ZO_SceneGroup:New("guildHome", "guildRoster", "guildRanks", "guildHeraldry", "guildHistory", "guildCreate"))
    MAIN_MENU_KEYBOARD:AddSceneGroup(MENU_CATEGORY_GUILDS, "guildsSceneGroup", iconData)
    GUILD_SELECTOR:OnScenesCreated()
    MAIN_MENU_KEYBOARD:EvaluateSceneGroupVisibilityOnCallback("guildsSceneGroup", "OnGuildSelected")
    MAIN_MENU_KEYBOARD:EvaluateSceneGroupVisibilityOnEvent("guildsSceneGroup", EVENT_GUILD_MEMBER_RANK_CHANGED)
    MAIN_MENU_KEYBOARD:EvaluateSceneGroupVisibilityOnEvent("guildsSceneGroup", EVENT_GUILD_MEMBER_ADDED)
    MAIN_MENU_KEYBOARD:EvaluateSceneGroupVisibilityOnEvent("guildsSceneGroup", EVENT_GUILD_MEMBER_REMOVED)
end

--Journal

do
    local iconData = {
        {
            categoryName = SI_JOURNAL_MENU_QUESTS,
            descriptor = "questJournal",
            normal = "EsoUI/Art/Journal/journal_tabIcon_quest_up.dds",
            pressed = "EsoUI/Art/Journal/journal_tabIcon_quest_down.dds",
            highlight = "EsoUI/Art/Journal/journal_tabIcon_quest_over.dds",
        },
        {
            categoryName = SI_JOURNAL_MENU_CADWELLS_ALMANAC,
            descriptor = "cadwellsAlmanac",
            normal = "EsoUI/Art/Journal/journal_tabIcon_cadwell_up.dds",
            pressed = "EsoUI/Art/Journal/journal_tabIcon_cadwell_down.dds",
            highlight = "EsoUI/Art/Journal/journal_tabIcon_cadwell_over.dds",
            visible = function() return GetPlayerDifficultyLevel() > PLAYER_DIFFICULTY_LEVEL_FIRST_ALLIANCE end,
        },
        {
            categoryName = SI_JOURNAL_MENU_LORE_LIBRARY,
            descriptor = "loreLibrary",
            normal = "EsoUI/Art/Journal/journal_tabIcon_loreLibrary_up.dds",
            pressed = "EsoUI/Art/Journal/journal_tabIcon_loreLibrary_down.dds",
            highlight = "EsoUI/Art/Journal/journal_tabIcon_loreLibrary_over.dds",
        },
        {
            categoryName = SI_JOURNAL_MENU_ACHIEVEMENTS,
            descriptor = "achievements",
            normal = "EsoUI/Art/Journal/journal_tabIcon_achievements_up.dds",
            pressed = "EsoUI/Art/Journal/journal_tabIcon_achievements_down.dds",
            highlight = "EsoUI/Art/Journal/journal_tabIcon_achievements_over.dds",
        },

        {
            categoryName = SI_JOURNAL_MENU_LEADERBOARDS,
            descriptor = "leaderboards",
            normal = "EsoUI/Art/Journal/journal_tabIcon_leaderboard_up.dds",
            pressed = "EsoUI/Art/Journal/journal_tabIcon_leaderboard_down.dds",
            highlight = "EsoUI/Art/Journal/journal_tabIcon_leaderboard_over.dds",
        },

    }
    SCENE_MANAGER:AddSceneGroup("journalSceneGroup", ZO_SceneGroup:New("questJournal", "cadwellsAlmanac", "loreLibrary", "achievements", "leaderboards"))
    MAIN_MENU_KEYBOARD:AddSceneGroup(MENU_CATEGORY_JOURNAL, "journalSceneGroup", iconData)
end

--Alliance War

do
    local iconData = {
        {
            categoryName = SI_WINDOW_TITLE_CAMPAIGN_OVERVIEW,
            descriptor = "campaignOverview",
            visible = function() return GetCurrentCampaignId() ~= 0 or GetAssignedCampaignId() ~= 0 end,
            normal = "EsoUI/Art/Campaign/campaign_tabIcon_summary_up.dds",
            pressed = "EsoUI/Art/Campaign/campaign_tabIcon_summary_down.dds",
            highlight = "EsoUI/Art/Campaign/campaign_tabIcon_summary_over.dds",
        },
        {
            categoryName = SI_WINDOW_TITLE_CAMPAIGN_BROWSER,
            descriptor = "campaignBrowser",
            normal = "EsoUI/Art/Campaign/campaign_tabIcon_browser_up.dds",
            pressed = "EsoUI/Art/Campaign/campaign_tabIcon_browser_down.dds",
            highlight = "EsoUI/Art/Campaign/campaign_tabIcon_browser_over.dds",
        },
    }
    SCENE_MANAGER:AddSceneGroup("allianceWarSceneGroup", ZO_SceneGroup:New("campaignOverview", "campaignBrowser"))
    MAIN_MENU_KEYBOARD:AddSceneGroup(MENU_CATEGORY_ALLIANCE_WAR, "allianceWarSceneGroup", iconData)
    MAIN_MENU_KEYBOARD:EvaluateSceneGroupVisibilityOnEvent("allianceWarSceneGroup", EVENT_CURRENT_CAMPAIGN_CHANGED)
    MAIN_MENU_KEYBOARD:EvaluateSceneGroupVisibilityOnEvent("allianceWarSceneGroup", EVENT_ASSIGNED_CAMPAIGN_CHANGED)
end

--Help

do
    local iconData = {
        {
            categoryName = SI_HELP_TUTORIALS,
            descriptor = "helpTutorials",
            normal = "EsoUI/Art/Help/help_tabIcon_tutorial_up.dds",
            pressed = "EsoUI/Art/Help/help_tabIcon_tutorial_down.dds",
            highlight = "EsoUI/Art/Help/help_tabIcon_tutorial_over.dds",
        },
        {
            categoryName = SI_HELP_CUSTOMER_SUPPORT,
            descriptor = "helpCustomerSupport",
            normal = "EsoUI/Art/Help/help_tabIcon_CS_up.dds",
            pressed = "EsoUI/Art/Help/help_tabIcon_CS_down.dds",
            highlight = "EsoUI/Art/Help/help_tabIcon_CS_over.dds",
        },
    }
    SCENE_MANAGER:AddSceneGroup("helpSceneGroup", ZO_SceneGroup:New("helpTutorials", "helpCustomerSupport"))
    MAIN_MENU_KEYBOARD:AddSceneGroup(MENU_CATEGORY_HELP, "helpSceneGroup", iconData)
end

--Mail

do
    local iconData = {
        {
            categoryName = SI_WINDOW_TITLE_INBOX_MAIL,
            descriptor = "mailInbox",
            normal = "EsoUI/Art/Mail/mail_tabIcon_inbox_up.dds",
            pressed = "EsoUI/Art/Mail/mail_tabIcon_inbox_down.dds",
            highlight = "EsoUI/Art/Mail/mail_tabIcon_inbox_over.dds",
        },
        {
            categoryName = SI_WINDOW_TITLE_SEND_MAIL,
            descriptor = "mailSend",
            normal = "EsoUI/Art/Mail/mail_tabIcon_compose_up.dds",
            pressed = "EsoUI/Art/Mail/mail_tabIcon_compose_down.dds",
            highlight = "EsoUI/Art/Mail/mail_tabIcon_compose_over.dds",
        },
    }
    SCENE_MANAGER:AddSceneGroup("mailSceneGroup", ZO_SceneGroup:New("mailInbox", "mailSend"))
    MAIN_MENU_KEYBOARD:AddSceneGroup(MENU_CATEGORY_MAIL, "mailSceneGroup", iconData)
end