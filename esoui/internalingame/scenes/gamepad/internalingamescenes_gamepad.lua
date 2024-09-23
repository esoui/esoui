-----------------------
--Gamepad Market Scenes
-----------------------

ZO_GAMEPAD_MARKET_PRE_SCENE:AddFragmentGroup(ZO_GAMEPAD_MARKET_KEYBINDS_FRAGMENT_GROUP)
ZO_GAMEPAD_MARKET_PRE_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)

ZO_GAMEPAD_ENDEAVOR_SEAL_MARKET_PRE_SCENE:AddFragmentGroup(ZO_GAMEPAD_MARKET_KEYBINDS_FRAGMENT_GROUP)
ZO_GAMEPAD_ENDEAVOR_SEAL_MARKET_PRE_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)

local gamepadMarketScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_SCENE_NAME)
gamepadMarketScene:AddFragmentGroup(ZO_GAMEPAD_MARKET_KEYBINDS_FRAGMENT_GROUP)
gamepadMarketScene:AddFragment(GAMEPAD_MARKET_FRAGMENT)
gamepadMarketScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)
gamepadMarketScene:AddFragment(MARKET_CURRENCY_GAMEPAD_FRAGMENT)

GAMEPAD_MARKET_PREVIEW_SCENE:AddFragmentGroup(ZO_GAMEPAD_MARKET_KEYBINDS_FRAGMENT_GROUP)
-- The preview options fragment needs to be added before the ITEM_PREVIEW_GAMEPAD fragment,
-- which is part of ZO_ITEM_PREVIEW_LIST_HELPER_GAMEPAD_FRAGMENT_GROUP
GAMEPAD_MARKET_PREVIEW_SCENE:AddFragment(GAMEPAD_MARKET_ITEM_PREVIEW_OPTIONS_FRAGMENT)
GAMEPAD_MARKET_PREVIEW_SCENE:AddFragmentGroup(ZO_ITEM_PREVIEW_LIST_HELPER_GAMEPAD_FRAGMENT_GROUP)

local gamepadMarketBundleContentsScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS_SCENE_NAME)
gamepadMarketBundleContentsScene:AddFragmentGroup(ZO_GAMEPAD_MARKET_KEYBINDS_FRAGMENT_GROUP)
gamepadMarketBundleContentsScene:AddFragment(GAMEPAD_MARKET_BUNDLE_CONTENTS_FRAGMENT)
gamepadMarketBundleContentsScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)
gamepadMarketBundleContentsScene:AddFragment(MARKET_CURRENCY_GAMEPAD_FRAGMENT)


local gamepadMarketLockedScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_LOCKED_SCENE_NAME)
gamepadMarketLockedScene:AddFragmentGroup(ZO_GAMEPAD_MARKET_KEYBINDS_FRAGMENT_GROUP)
gamepadMarketLockedScene:AddFragment(GAMEPAD_MARKET_LOCKED_FRAGMENT)
gamepadMarketLockedScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)
gamepadMarketLockedScene:AddFragment(MARKET_CURRENCY_GAMEPAD_FRAGMENT)


local gamepadMarketPurchaseScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME)
gamepadMarketPurchaseScene:AddFragmentGroup(ZO_GAMEPAD_MARKET_KEYBINDS_FRAGMENT_GROUP)


local gamepadMarketContentListScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_CONTENT_LIST_SCENE_NAME)
gamepadMarketContentListScene:AddFragment(MARKET_CURRENCY_GAMEPAD_FRAGMENT)
gamepadMarketContentListScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
gamepadMarketContentListScene:AddFragment(GAMEPAD_MARKET_LIST_FRAGMENT)
gamepadMarketContentListScene:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
gamepadMarketContentListScene:AddFragment(UI_SHORTCUTS_ACTION_LAYER_FRAGMENT)

GAMEPAD_MARKET_SCENE_GROUP = ZO_SceneGroup:New(
                                        ZO_GAMEPAD_MARKET_SCENE_NAME,
                                        ZO_GAMEPAD_MARKET_PREVIEW_SCENE_NAME,
                                        ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS_SCENE_NAME,
                                        ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME,
                                        ZO_GAMEPAD_MARKET_CONTENT_LIST_SCENE_NAME,
                                        ZO_GAMEPAD_MARKET_LOCKED_SCENE_NAME
                                          )

SCENE_MANAGER:AddSceneGroup("gamepad_market_scenegroup", GAMEPAD_MARKET_SCENE_GROUP)

ZO_GAMEPAD_MARKET:SetupSceneGroupCallback()

--
-- Gamepad Mail Scene
--

local gamepadMailScene = ZO_RemoteScene:New("mailGamepad", SCENE_MANAGER)
gamepadMailScene:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)

------------------------------------
--Gamepad Code Redemption Scene
------------------------------------

local codeRedemptionGamepadScene = SCENE_MANAGER:GetScene("codeRedemptionGamepad")
codeRedemptionGamepadScene:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
codeRedemptionGamepadScene:AddFragment(UI_SHORTCUTS_ACTION_LAYER_FRAGMENT)
codeRedemptionGamepadScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)

------------------------------------
--Crown Crates Scene
------------------------------------
local remoteCrownCratesSceneGamepad = ZO_RemoteScene:New("crownCrateGamepad", SCENE_MANAGER)

SCENE_MANAGER:OnScenesLoaded()

ZO_GAMEPAD_DIALOG_BASE_SCENE_NAME = "empty"
