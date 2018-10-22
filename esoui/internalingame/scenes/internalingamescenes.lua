-------------------
--Crown Store Scene
-------------------

local marketScene = SCENE_MANAGER:GetScene("market")
if marketScene then
    -- the preview options fragment needs to be added before the ITEM_PREVIEW_KEYBOARD fragment
    -- which is part of ZO_ITEM_PREVIEW_LIST_HELPER_KEYBOARD_FRAGMENT_GROUP
    marketScene:AddFragment(MARKET_ITEM_PREVIEW_OPTIONS_FRAGMENT)
    marketScene:AddFragmentGroup(ZO_ITEM_PREVIEW_LIST_HELPER_KEYBOARD_FRAGMENT_GROUP)

    marketScene:AddFragment(TREE_UNDERLAY_FRAGMENT)
    marketScene:AddFragment(KEYBIND_STRIP_FADE_FRAGMENT)
    marketScene:AddFragment(UI_SHORTCUTS_ACTION_LAYER_FRAGMENT)
    marketScene:AddFragment(GENERAL_ACTION_LAYER_FRAGMENT)
end

-------------------
-- Show Market Scene
-------------------

local showMarketScene = ZO_RemoteScene:New("show_market", SCENE_MANAGER)

-------------------
-- Show ESO Plus Scene
-------------------

local showESOPlusScene = ZO_RemoteScene:New("show_esoPlus", SCENE_MANAGER)

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
announcementScene:AddFragment(ZO_ActionLayerFragment:New("MarketAnnouncement"))

-------------------
--Eso Plus Offers Scene
-------------------

local esoPlusOffersScene = SCENE_MANAGER:GetScene("esoPlusOffersSceneKeyboard")
if esoPlusOffersScene then
    -- the preview options fragment needs to be added before the ITEM_PREVIEW_KEYBOARD fragment
    -- which is part of ZO_ITEM_PREVIEW_LIST_HELPER_KEYBOARD_FRAGMENT_GROUP
    esoPlusOffersScene:AddFragment(MARKET_ITEM_PREVIEW_OPTIONS_FRAGMENT)
    esoPlusOffersScene:AddFragmentGroup(ZO_ITEM_PREVIEW_LIST_HELPER_KEYBOARD_FRAGMENT_GROUP)

    esoPlusOffersScene:AddFragment(TREE_UNDERLAY_FRAGMENT)
    esoPlusOffersScene:AddFragment(KEYBIND_STRIP_FADE_FRAGMENT)
    esoPlusOffersScene:AddFragment(UI_SHORTCUTS_ACTION_LAYER_FRAGMENT)
    esoPlusOffersScene:AddFragment(GENERAL_ACTION_LAYER_FRAGMENT)
end

local remoteCrownCratesSceneKeyboard = ZO_RemoteScene:New("crownCrateKeyboard", SCENE_MANAGER)
local remoteCrownCratesSceneGamepad = ZO_RemoteScene:New("crownCrateGamepad", SCENE_MANAGER)