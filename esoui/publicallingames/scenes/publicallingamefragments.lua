-----------------------------
--Fullscreen Effect Fragment
-----------------------------

ZO_FullscreenEffectFragment = ZO_SceneFragment:Subclass()

function ZO_FullscreenEffectFragment:Initialize(effectType, ...)
    ZO_SceneFragment.Initialize(self)

    self.effectType = effectType
    self.params = {...}
    self:SetHideOnSceneHidden(true)
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