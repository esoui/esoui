-- TODO Share these in Common?

----------------------------------------
-- Keybind Strip
----------------------------------------

local ZO_KeybindStripFragment = ZO_FadeSceneFragment:Subclass()

function ZO_KeybindStripFragment:New(...)
    return ZO_FadeSceneFragment.New(self, ...)
end

function ZO_KeybindStripFragment:Show()
    KEYBIND_STRIP:SetStyle(KEYBIND_STRIP_STANDARD_STYLE)
    ZO_FadeSceneFragment.Show(self)
end

function ZO_KeybindStripFragment:Hide()
    ZO_FadeSceneFragment.Hide(self)
end

KEYBIND_STRIP_FADE_FRAGMENT = ZO_KeybindStripFragment:New(ZO_KeybindStripControl)

MARKET_ITEM_PREVIEW_OPTIONS_FRAGMENT = ZO_ItemPreviewOptionsFragment:New({
    paddingLeft = 0,
    paddingRight = 950,
    dynamicFramingConsumedWidth = 1150,
    dynamicFramingConsumedHeight = 300,
    forcePreparePreview = true,
})
RIGHT_BG_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedRightBackground)
GENERAL_ACTION_LAYER_FRAGMENT = ZO_ActionLayerFragment:New(GetString(SI_KEYBINDINGS_LAYER_GENERAL))
UI_SHORTCUTS_ACTION_LAYER_FRAGMENT = ZO_ActionLayerFragment:New(GetString(SI_KEYBINDINGS_LAYER_USER_INTERFACE_SHORTCUTS))
MOUSE_UI_MODE_FRAGMENT = ZO_ActionLayerFragment:New("MouseUIMode")
TREE_UNDERLAY_FRAGMENT = ZO_FadeSceneFragment:New(ZO_SharedTreeUnderlay)

----------------------------------------
--Window Sound Fragment
----------------------------------------

ZO_WindowSoundFragment = ZO_SceneFragment:Subclass()

function ZO_WindowSoundFragment:New(showSoundId, hideSoundId)
    local fragment = ZO_SceneFragment.New(self)
    fragment.showSoundId = showSoundId
    fragment.hideSoundId = hideSoundId
    return fragment
end

function ZO_WindowSoundFragment:Show()
    PlaySound(self.showSoundId)
    self:OnShown()
end

function ZO_WindowSoundFragment:Hide()
    --only play the close sound if we're exiting the window UI
    if(SCENE_MANAGER:IsShowingBaseSceneNext()) then
        PlaySound(self.hideSoundId)
    end
    self:OnHidden()
end
