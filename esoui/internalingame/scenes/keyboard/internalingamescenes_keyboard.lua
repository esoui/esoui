-------------------
--Crown Store Scene
-------------------

local marketScene = SCENE_MANAGER:GetScene("market")
-- The preview options fragment needs to be added before the ITEM_PREVIEW_KEYBOARD fragment,
-- which is part of ZO_ITEM_PREVIEW_LIST_HELPER_KEYBOARD_FRAGMENT_GROUP
marketScene:AddFragment(MARKET_ITEM_PREVIEW_OPTIONS_FRAGMENT)
marketScene:AddFragmentGroup(ZO_ITEM_PREVIEW_LIST_HELPER_KEYBOARD_FRAGMENT_GROUP)

marketScene:AddFragment(TREE_UNDERLAY_FRAGMENT)
marketScene:AddFragment(KEYBIND_STRIP_FADE_FRAGMENT)
marketScene:AddFragment(UI_SHORTCUTS_ACTION_LAYER_FRAGMENT)

----------------------------
--Endeavor Seals Store Scene
----------------------------

local endeavorSealStoreScene = SCENE_MANAGER:GetScene("endeavorSealStoreSceneKeyboard")
-- The preview options fragment needs to be added before the ITEM_PREVIEW_KEYBOARD fragment,
-- which is part of ZO_ITEM_PREVIEW_LIST_HELPER_KEYBOARD_FRAGMENT_GROUP
endeavorSealStoreScene:AddFragment(MARKET_ITEM_PREVIEW_OPTIONS_FRAGMENT)
endeavorSealStoreScene:AddFragmentGroup(ZO_ITEM_PREVIEW_LIST_HELPER_KEYBOARD_FRAGMENT_GROUP)

endeavorSealStoreScene:AddFragment(TREE_UNDERLAY_FRAGMENT)
endeavorSealStoreScene:AddFragment(KEYBIND_STRIP_FADE_FRAGMENT)
endeavorSealStoreScene:AddFragment(UI_SHORTCUTS_ACTION_LAYER_FRAGMENT)

-------------------
--Eso Plus Offers Scene
-------------------

local esoPlusOffersScene = SCENE_MANAGER:GetScene("esoPlusOffersSceneKeyboard")
-- The preview options fragment needs to be added before the ITEM_PREVIEW_KEYBOARD fragment,
-- which is part of ZO_ITEM_PREVIEW_LIST_HELPER_KEYBOARD_FRAGMENT_GROUP
esoPlusOffersScene:AddFragment(MARKET_ITEM_PREVIEW_OPTIONS_FRAGMENT)
esoPlusOffersScene:AddFragmentGroup(ZO_ITEM_PREVIEW_LIST_HELPER_KEYBOARD_FRAGMENT_GROUP)

esoPlusOffersScene:AddFragment(TREE_UNDERLAY_FRAGMENT)
esoPlusOffersScene:AddFragment(KEYBIND_STRIP_FADE_FRAGMENT)
esoPlusOffersScene:AddFragment(UI_SHORTCUTS_ACTION_LAYER_FRAGMENT)

-------------------
--Crown Crates Scene
-------------------
local remoteCrownCratesSceneKeyboard = ZO_RemoteScene:New("crownCrateKeyboard", SCENE_MANAGER)

