-----------------------
--Gamepad Market Scenes
-----------------------

ZO_GAMEPAD_MARKET_PRE_SCENE:AddFragmentGroup(ZO_GAMEPAD_INTERNAL_INGAME_FRAGMENT_GROUP)
ZO_GAMEPAD_MARKET_PRE_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)

local gamepadMarketScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_SCENE_NAME)
gamepadMarketScene:AddFragmentGroup(ZO_GAMEPAD_INTERNAL_INGAME_FRAGMENT_GROUP)
gamepadMarketScene:AddFragment(GAMEPAD_MARKET_FRAGMENT)
gamepadMarketScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)
gamepadMarketScene:AddFragment(MARKET_CURRENCY_GAMEPAD_FRAGMENT)

GAMEPAD_MARKET_PREVIEW_SCENE:AddFragmentGroup(ZO_GAMEPAD_INTERNAL_INGAME_FRAGMENT_GROUP)
GAMEPAD_MARKET_PREVIEW_SCENE:AddFragment(GAMEPAD_MARKET_ITEM_PREVIEW_OPTIONS_FRAGMENT)
GAMEPAD_MARKET_PREVIEW_SCENE:AddFragmentGroup(ZO_ITEM_PREVIEW_LIST_HELPER_GAMEPAD_FRAGMENT_GROUP)

local gamepadMarketBundleContentsScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS_SCENE_NAME)
gamepadMarketBundleContentsScene:AddFragmentGroup(ZO_GAMEPAD_INTERNAL_INGAME_FRAGMENT_GROUP)
gamepadMarketBundleContentsScene:AddFragment(GAMEPAD_MARKET_BUNDLE_CONTENTS_FRAGMENT)
gamepadMarketBundleContentsScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)
gamepadMarketBundleContentsScene:AddFragment(MARKET_CURRENCY_GAMEPAD_FRAGMENT)


local gamepadMarketLockedScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_LOCKED_SCENE_NAME)
gamepadMarketLockedScene:AddFragmentGroup(ZO_GAMEPAD_INTERNAL_INGAME_FRAGMENT_GROUP)
gamepadMarketLockedScene:AddFragment(GAMEPAD_MARKET_LOCKED_FRAGMENT)
gamepadMarketLockedScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)
gamepadMarketLockedScene:AddFragment(MARKET_CURRENCY_GAMEPAD_FRAGMENT)


local gamepadMarketPurchaseScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME)
gamepadMarketPurchaseScene:AddFragmentGroup(ZO_GAMEPAD_INTERNAL_INGAME_FRAGMENT_GROUP)


local gamepadMarketContentListScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_CONTENT_LIST_SCENE_NAME)
gamepadMarketContentListScene:AddFragment(MARKET_CURRENCY_GAMEPAD_FRAGMENT)
gamepadMarketContentListScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
gamepadMarketContentListScene:AddFragment(GAMEPAD_MARKET_LIST_FRAGMENT)
gamepadMarketContentListScene:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
gamepadMarketContentListScene:AddFragment(GENERAL_ACTION_LAYER_FRAGMENT)

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

local gamepadMailScene = ZO_RemoteScene:New("mailManagerGamepad", SCENE_MANAGER)
gamepadMailScene:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)

SCENE_MANAGER:OnScenesLoaded()

ZO_GAMEPAD_DIALOG_BASE_SCENE_NAME = "empty"
