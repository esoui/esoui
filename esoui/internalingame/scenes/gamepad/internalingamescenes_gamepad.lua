-----------------------
--Gamepad Market Scenes
-----------------------

ZO_GAMEPAD_MARKET_PRE_SCENE:AddFragmentGroup(ZO_GAMEPAD_INTERNAL_INGAME_FRAGMENT_GROUP)
ZO_GAMEPAD_MARKET_PRE_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)

local gamepadMarketScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_SCENE_NAME)
if gamepadMarketScene then
    gamepadMarketScene:AddFragmentGroup(ZO_GAMEPAD_INTERNAL_INGAME_FRAGMENT_GROUP)
    gamepadMarketScene:AddFragment(GAMEPAD_MARKET_FRAGMENT)
    gamepadMarketScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)
    gamepadMarketScene:AddFragment(GAMEPAD_MARKET_CROWNS_FOOTER_FRAGMENT)
end

local gamepadMarketPreviewScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_PREVIEW_SCENE_NAME)
if gamepadMarketPreviewScene then
    gamepadMarketPreviewScene:AddFragmentGroup(ZO_GAMEPAD_INTERNAL_INGAME_FRAGMENT_GROUP)
    gamepadMarketPreviewScene:AddFragment(GAMEPAD_MARKET_PREVIEW_FRAGMENT)
end

local gamepadMarketBundleContentsScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS_SCENE_NAME)
if gamepadMarketBundleContentsScene then
    gamepadMarketBundleContentsScene:AddFragmentGroup(ZO_GAMEPAD_INTERNAL_INGAME_FRAGMENT_GROUP)
    gamepadMarketBundleContentsScene:AddFragment(GAMEPAD_MARKET_BUNDLE_CONTENTS_FRAGMENT)
    gamepadMarketBundleContentsScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)
    gamepadMarketBundleContentsScene:AddFragment(GAMEPAD_MARKET_CROWNS_FOOTER_FRAGMENT)
end

local gamepadMarketLockedScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_LOCKED_SCENE_NAME)
if gamepadMarketLockedScene then
    gamepadMarketLockedScene:AddFragmentGroup(ZO_GAMEPAD_INTERNAL_INGAME_FRAGMENT_GROUP)
    gamepadMarketLockedScene:AddFragment(GAMEPAD_MARKET_LOCKED_FRAGMENT)
    gamepadMarketLockedScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT)
    gamepadMarketLockedScene:AddFragment(GAMEPAD_MARKET_CROWNS_FOOTER_FRAGMENT)
end

local gamepadMarketPurchaseScene = SCENE_MANAGER:GetScene(ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME)
if gamepadMarketPurchaseScene then
    gamepadMarketPurchaseScene:AddFragmentGroup(ZO_GAMEPAD_INTERNAL_INGAME_FRAGMENT_GROUP)
end

SCENE_MANAGER:AddSceneGroup("gamepad_market_scenegroup", ZO_SceneGroup:New(ZO_GAMEPAD_MARKET_SCENE_NAME, ZO_GAMEPAD_MARKET_PREVIEW_SCENE_NAME, ZO_GAMEPAD_MARKET_BUNDLE_CONTENTS_SCENE_NAME, ZO_GAMEPAD_MARKET_PURCHASE_SCENE_NAME))

ZO_GAMEPAD_MARKET:SetupSceneGroupCallback()

--
-- Gamepad Mail Scene
--

local gamepadMailScene = ZO_RemoteScene:New("mailManagerGamepad", SCENE_MANAGER)
gamepadMailScene:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)

SCENE_MANAGER:OnScenesLoaded()

ZO_GAMEPAD_DIALOG_BASE_SCENE_NAME = "empty"
