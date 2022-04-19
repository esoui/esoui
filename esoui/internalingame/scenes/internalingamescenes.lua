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
announcementScene:AddFragment(UI_SHORTCUTS_ACTION_LAYER_FRAGMENT)
announcementScene:AddFragment(ZO_ActionLayerFragment:New("MarketAnnouncement"))

----------------------------------
-- Antiquity Digging Game Scene --
----------------------------------
ANTIQUITY_DIGGING_SCENE:AddFragment(ANTIQUITY_DIGGING_FRAGMENT)
ANTIQUITY_DIGGING_SCENE:AddFragment(MOUSE_UI_MODE_FRAGMENT)

-----------------------
--Scrying Game Scene --
-----------------------
SCRYING_SCENE:AddFragment(MOUSE_UI_MODE_FRAGMENT)
SCRYING_SCENE:AddFragment(UI_SHORTCUTS_ACTION_LAYER_FRAGMENT)

-----------------------
--Tribute Game Scene --
-----------------------
TRIBUTE_SCENE:AddFragment(TRIBUTE_FRAGMENT)
TRIBUTE_SCENE:AddFragment(MOUSE_UI_MODE_FRAGMENT)
TRIBUTE_SCENE:AddFragment(UI_SHORTCUTS_ACTION_LAYER_FRAGMENT)