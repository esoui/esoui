-----------------------
--Gamepad Options Root Scene
-----------------------

GAMEPAD_OPTIONS:InitializeScenes()
GAMEPAD_OPTIONS_ROOT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
GAMEPAD_OPTIONS_ROOT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD)
GAMEPAD_OPTIONS_ROOT_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SYSTEM)
GAMEPAD_OPTIONS_ROOT_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
GAMEPAD_OPTIONS_ROOT_SCENE:AddFragment(MINIMIZE_CHAT_FRAGMENT)
GAMEPAD_OPTIONS_ROOT_SCENE:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)
GAMEPAD_OPTIONS_ROOT_SCENE:AddFragment(OPTIONS_MENU_INFO_PANEL_FRAGMENT)
GAMEPAD_OPTIONS_ROOT_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_4_BACKGROUND_FRAGMENT)
GAMEPAD_OPTIONS_ROOT_SCENE:AddFragment(GAMEPAD_OPTIONS_FRAGMENT)
GAMEPAD_OPTIONS_ROOT_SCENE:AddFragment(GAMEPAD_OPTIONS:GetHeaderFragment())

-----------------------
--Gamepad Options Panel Scene
-----------------------

GAMEPAD_OPTIONS_PANEL_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
GAMEPAD_OPTIONS_PANEL_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD)
GAMEPAD_OPTIONS_PANEL_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SYSTEM)
GAMEPAD_OPTIONS_PANEL_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
GAMEPAD_OPTIONS_PANEL_SCENE:AddFragment(MINIMIZE_CHAT_FRAGMENT)
GAMEPAD_OPTIONS_PANEL_SCENE:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)
GAMEPAD_OPTIONS_PANEL_SCENE:AddFragment(OPTIONS_MENU_INFO_PANEL_FRAGMENT)
GAMEPAD_OPTIONS_PANEL_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_4_BACKGROUND_FRAGMENT)
GAMEPAD_OPTIONS_PANEL_SCENE:AddFragment(GAMEPAD_OPTIONS_FRAGMENT)
GAMEPAD_OPTIONS_PANEL_SCENE:AddFragment(GAMEPAD_OPTIONS:GetHeaderFragment())

---------------------------
-- Gamepad Guild Bank Error Scene
---------------------------

GAMEPAD_GUILD_BANK_ERROR_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
GAMEPAD_GUILD_BANK_ERROR_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD)
GAMEPAD_GUILD_BANK_ERROR_SCENE:AddFragment(GAMEPAD_GUILD_BANK_ERROR_FRAGMENT)
GAMEPAD_GUILD_BANK_ERROR_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
GAMEPAD_GUILD_BANK_ERROR_SCENE:AddFragment(MINIMIZE_CHAT_FRAGMENT)
GAMEPAD_GUILD_BANK_ERROR_SCENE:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)

---------------------------
-- Gamepad Guild Bank Scene
---------------------------

GAMEPAD_GUILD_BANK_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
GAMEPAD_GUILD_BANK_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD)
GAMEPAD_GUILD_BANK_SCENE:AddFragment(GAMEPAD_GUILD_BANK_FRAGMENT)
GAMEPAD_GUILD_BANK_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
GAMEPAD_GUILD_BANK_SCENE:AddFragment(MINIMIZE_CHAT_FRAGMENT)
GAMEPAD_GUILD_BANK_SCENE:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)
GAMEPAD_GUILD_BANK_SCENE:AddFragment(ZO_GUILD_NAME_FOOTER_FRAGMENT)

-----------------------
--Help Root Scene Gamepad
-----------------------

local helpRootGamepadScene = SCENE_MANAGER:GetScene("helpRootGamepad")
helpRootGamepadScene:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
helpRootGamepadScene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_RIGHT)
helpRootGamepadScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
helpRootGamepadScene:AddFragment(MINIMIZE_CHAT_FRAGMENT)
helpRootGamepadScene:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)

-----------------------
--Help Customer Service (Submit Ticket) Scene Gamepad
-----------------------

local helpCustomerServiceGamepadScene = SCENE_MANAGER:GetScene("helpCustomerServiceGamepad")
helpCustomerServiceGamepadScene:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
helpCustomerServiceGamepadScene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_RIGHT)
helpCustomerServiceGamepadScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
helpCustomerServiceGamepadScene:AddFragment(MINIMIZE_CHAT_FRAGMENT)
helpCustomerServiceGamepadScene:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)

-----------------------
--Help Tutorials Categories Scene Gamepad
-----------------------

local helpTutorialsCategoriesGamepadScene = SCENE_MANAGER:GetScene("helpTutorialsCategoriesGamepad")
helpTutorialsCategoriesGamepadScene:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
helpTutorialsCategoriesGamepadScene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_RIGHT)
helpTutorialsCategoriesGamepadScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
helpTutorialsCategoriesGamepadScene:AddFragment(MINIMIZE_CHAT_FRAGMENT)
helpTutorialsCategoriesGamepadScene:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)

-----------------------
--Help Tutorials Entries Scene Gamepad
-----------------------

local helpTutorialsEntriesGamepadScene = SCENE_MANAGER:GetScene("helpTutorialsEntriesGamepad")
helpTutorialsEntriesGamepadScene:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
helpTutorialsEntriesGamepadScene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_RIGHT)
helpTutorialsEntriesGamepadScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
helpTutorialsEntriesGamepadScene:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
helpTutorialsEntriesGamepadScene:AddFragment(MINIMIZE_CHAT_FRAGMENT)
helpTutorialsEntriesGamepadScene:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)

--------------------
--Help Legal Docs Scene
--------------------

local helpLegalDocsGamepadScene = SCENE_MANAGER:GetScene("helpLegalDocsGamepad")
helpLegalDocsGamepadScene:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
helpLegalDocsGamepadScene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_RIGHT)
helpLegalDocsGamepadScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
helpLegalDocsGamepadScene:AddFragment(MINIMIZE_CHAT_FRAGMENT)
helpLegalDocsGamepadScene:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)

do
    SCENE_MANAGER:AddSceneGroup("helpSceneGroupGamepad", ZO_SceneGroup:New("helpTutorialsCategoriesGamepad", "helpTutorialsEntriesGamepad"))
end

------------------------
--Screen Adjust Scene
------------------------

local screenAdjustScene = SCENE_MANAGER:GetScene("screenAdjust")
screenAdjustScene:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
screenAdjustScene:AddFragment(MINIMIZE_CHAT_FRAGMENT)
