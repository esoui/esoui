-------------------
--Empty
-------------------

local empty = ZO_Scene:New("empty", SCENE_MANAGER)

-------------------
--Crown Store Scene
-------------------

local marketScene = SCENE_MANAGER:GetScene(ZO_KEYBOARD_MARKET_SCENE_NAME)
if marketScene then
    marketScene:AddFragment(RIGHT_BG_FRAGMENT)
    marketScene:AddFragment(MARKET_ITEM_PREVIEW_OPTIONS_FRAGMENT)
    marketScene:AddFragment(ITEM_PREVIEW_KEYBOARD:GetFragment())
    marketScene:AddFragment(MARKET_FRAGMENT)
    marketScene:AddFragment(MARKET_TREE_UNDERLAY_FRAGMENT)
    marketScene:AddFragment(KEYBIND_STRIP_FADE_FRAGMENT)
    marketScene:AddFragment(UI_SHORTCUTS_ACTION_LAYER_FRAGMENT)
    marketScene:AddFragment(GENERAL_ACTION_LAYER_FRAGMENT)
end

-------------------
-- Show Market Scene
-------------------

local showMarketScene = ZO_RemoteScene:New("show_market", SCENE_MANAGER)

-------------------
--Announcement Scene
-------------------

local announcementScene = SCENE_MANAGER:GetScene("marketAnnouncement")
--fragments may not exist depending on the platform (mostly console)
if ZO_KEYBOARD_MARKET_ANNOUNCEMENT then
    announcementScene:AddFragment(ZO_KEYBOARD_MARKET_ANNOUNCEMENT:GetFragment())
end
if ZO_GAMEPAD_MARKET_ANNOUNCEMENT then
    announcementScene:AddFragment(ZO_GAMEPAD_MARKET_ANNOUNCEMENT:GetFragment())
end
announcementScene:AddFragment(MOUSE_UI_MODE_FRAGMENT)
announcementScene:AddFragment(GENERAL_ACTION_LAYER_FRAGMENT)
announcementScene:AddFragment(GAMEPAD_ACTION_LAYER_FRAGMENT)
announcementScene:AddFragment(ZO_ActionLayerFragment:New("MarketAnnouncement"))

local remoteCrownCratesSceneKeyboard = ZO_RemoteScene:New("crownCrateKeyboard", SCENE_MANAGER)
local remoteCrownCratesSceneGamepad = ZO_RemoteScene:New("crownCrateGamepad", SCENE_MANAGER)