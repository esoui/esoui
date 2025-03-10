----------------------------------------
-- Gamepad Keybind Strip
----------------------------------------

local ZO_GamepadKeybindStripFragment = ZO_TranslateFromBottomSceneFragment:Subclass()

function ZO_GamepadKeybindStripFragment:New(...)
    return ZO_TranslateFromBottomSceneFragment.New(self, ...)
end

function ZO_GamepadKeybindStripFragment:Show()
    KEYBIND_STRIP:SetStyle(KEYBIND_STRIP_GAMEPAD_STYLE)
    ZO_TranslateFromBottomSceneFragment.Show(self)
end

function ZO_GamepadKeybindStripFragment:Hide()
    ZO_TranslateFromBottomSceneFragment.Hide(self)
end

KEYBIND_STRIP_GAMEPAD_FRAGMENT = ZO_GamepadKeybindStripFragment:New(ZO_KeybindStripControl)
KEYBIND_STRIP_GAMEPAD_BACKDROP_FRAGMENT = ZO_FadeSceneFragment:New(ZO_KeybindStripGamepadBackground)

----------------------------------------
-- Gamepad Market Keybind Strip
----------------------------------------

local ZO_GamepadMarketKeybindStripFragment = ZO_TranslateFromBottomSceneFragment:Subclass()

function ZO_GamepadMarketKeybindStripFragment:New(...)
    return ZO_TranslateFromBottomSceneFragment.New(self, ...)
end

function ZO_GamepadMarketKeybindStripFragment:Show()
    ZO_GamepadMarketKeybindStrip_RefreshStyle()
    ZO_TranslateFromBottomSceneFragment.Show(self)
end

function ZO_GamepadMarketKeybindStripFragment:Hide()
    ZO_TranslateFromBottomSceneFragment.Hide(self)
end

KEYBIND_STRIP_GAMEPAD_MARKET_FRAGMENT = ZO_GamepadMarketKeybindStripFragment:New(ZO_KeybindStripControl)

-- Dialogs --

GAMEPAD_DIALOG_SOUNDS_FRAGMENT = ZO_WindowSoundFragment:New(SOUNDS.DIALOG_SHOW, SOUNDS.DIALOG_HIDE)

-- Quadrant System Gamepad Grid Backgrounds: DO NOT BLOAT! --
    
GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT = ZO_TranslateFromLeftSceneFragment:New(ZO_SharedGamepadNavQuadrant_1_Background)
ZO_BackgroundFragment:Mixin(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedGamepadNavQuadrant_2_Background)
ZO_BackgroundFragment:Mixin(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)
GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedGamepadNavQuadrant_4_Background)
ZO_BackgroundFragment:Mixin(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedGamepadNavQuadrant_2_3_Background)
ZO_BackgroundFragment:Mixin(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
GAMEPAD_NAV_QUADRANT_2_3_4_BACKGROUND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedGamepadNavQuadrant_2_3_4_Background)
GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedGamepadNavQuadrant_4_Background)
GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedGamepadNavQuadrant_1_2_3_Background)

GAMEPAD_MARKET_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 0,
    paddingRight = ZO_GAMEPAD_PANEL_WIDTH + ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    dynamicFramingConsumedWidth = 700,
    dynamicFramingConsumedHeight = 400,
})

GAMEPAD_NAV_QUADRANT_2_3_4_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = ZO_GAMEPAD_PANEL_WIDTH + ZO_GAMEPAD_SAFE_ZONE_INSET_X,
    paddingRight = 0,
    dynamicFramingConsumedWidth = 1150,
    dynamicFramingConsumedHeight = 400,
    forcePreparePreview = false,
    previewBufferMS = 300
})


-- END Quadrant System Gamepad Grid Backgrounds: DO NOT BLOAT! --

-------------------------
--Gamepad Market
-------------------------

GAMEPAD_MARKET_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadMarket)
GAMEPAD_MARKET_PREVIEW_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadMarket_Preview)
GAMEPAD_MARKET_BUNDLE_CONTENTS_FRAGMENT = ZO_FadeSceneFragment:New(ZO_GamepadMarket_BundleContents)
GAMEPAD_MARKET_LOCKED_FRAGMENT = ZO_CreateQuadrantConveyorFragment(ZO_GamepadMarket_Locked, ALWAYS_ANIMATE)

ZO_GAMEPAD_KEYBINDS_FRAGMENT_GROUP =
{
    UI_SHORTCUTS_ACTION_LAYER_FRAGMENT,
    KEYBIND_STRIP_GAMEPAD_FRAGMENT,
}

ZO_GAMEPAD_MARKET_KEYBINDS_FRAGMENT_GROUP =
{
    UI_SHORTCUTS_ACTION_LAYER_FRAGMENT,
    KEYBIND_STRIP_GAMEPAD_MARKET_FRAGMENT,
}

-- most scenes in internal ingame use ZO_GAMEPAD_MARKET_KEYBINDS_FRAGMENT_GROUP so we will set that
-- as the default dialog fragment group
ZO_GAMEPAD_DIALOG_FRAGMENT_GROUP = ZO_GAMEPAD_MARKET_KEYBINDS_FRAGMENT_GROUP

GAMEPAD_MARKET_LIST_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_GamepadMarket_ProductListScene)

-------------------------
--Gamepad Tribute
-------------------------

ZO_GAMEPAD_TRIBUTE_PILE_VIEWER_FRAGMENT_GROUP =
{
    KEYBIND_STRIP_GAMEPAD_BACKDROP_FRAGMENT,
    TRIBUTE_PILE_VIEWER_GAMEPAD_FRAGMENT,
}

ZO_GAMEPAD_TRIBUTE_TARGET_VIEWER_FRAGMENT_GROUP =
{
    KEYBIND_STRIP_GAMEPAD_BACKDROP_FRAGMENT,
    TRIBUTE_TARGET_VIEWER_GAMEPAD_FRAGMENT,
}

ZO_GAMEPAD_TRIBUTE_CONFINEMENT_VIEWER_FRAGMENT_GROUP =
{
    KEYBIND_STRIP_GAMEPAD_BACKDROP_FRAGMENT,
    TRIBUTE_CONFINEMENT_VIEWER_GAMEPAD_FRAGMENT,
}

ZO_GAMEPAD_TRIBUTE_PATRON_SELECTION_FRAGMENT_GROUP =
{
    KEYBIND_STRIP_GAMEPAD_BACKDROP_FRAGMENT,
    TRIBUTE_PATRON_SELECTION_GAMEPAD_FRAGMENT,
}