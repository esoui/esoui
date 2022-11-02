-----------------------------
--Fullscreen Effect Fragment
-----------------------------

ZO_FullscreenEffectFragment = ZO_SceneFragment:Subclass()

function ZO_FullscreenEffectFragment:New(effectType, ...)
    local fragment = ZO_SceneFragment.New(self)
    fragment.effectType = effectType
    fragment.params = {...}
    fragment:SetHideOnSceneHidden(true)
    return fragment
end

function ZO_FullscreenEffectFragment:Show()
    SetFullscreenEffect(self.effectType, unpack(self.params))
    self:OnShown()
end

function ZO_FullscreenEffectFragment:Hide()
    SetFullscreenEffect(FULLSCREEN_EFFECT_NONE)
    self:OnHidden()
end

UNIFORM_BLUR_FRAGMENT = ZO_FullscreenEffectFragment:New(FULLSCREEN_EFFECT_UNIFORM_BLUR)