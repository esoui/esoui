local CreateSimpleLogoSplashScene
do
    local ZO_SimpleLogoSplashFragment = ZO_FadeSceneFragment:Subclass()

    function ZO_SimpleLogoSplashFragment:New(control)
        local fragment = ZO_FadeSceneFragment.New(self, control, 700)
        fragment.control = control
        return fragment
    end

    function ZO_SimpleLogoSplashFragment:Show()
        self.autoFadeTime = GetFrameTimeMilliseconds() + 2000

        local function OnUpdate()
            if(GetFrameTimeMilliseconds() >= self.autoFadeTime) then
                self.control:SetHandler("OnUpdate", nil)
                SCENE_MANAGER:Hide("simpleLogoSplash")
            end
        end

        self.control:SetHandler("OnUpdate", OnUpdate)

        -- Call base class for animations after everything has been tweaked
        ZO_FadeSceneFragment.Show(self)
    end

    function ZO_SimpleLogoSplashFragment:OnHidden()
        ZO_FadeSceneFragment.OnHidden(self)
        self.control:SetHandler("OnUpdate", nil)

        PregameStateManager_AdvanceState()
    end

    CreateSimpleLogoSplashScene = function(control)
        local simpleLogoSplash = ZO_Scene:New("simpleLogoSplash", SCENE_MANAGER)
        simpleLogoSplash:AddFragment(ZO_SimpleLogoSplashFragment:New(control))
    end
end

function SimpleLogoSplash_Initialize(self)
    CreateSimpleLogoSplashScene(self)
    self.logoTexture = self:GetNamedChild("Logo")
end

function SimpleLogoSplash_ShowWithTexture(textureFile)
    ZO_SimpleLogoSplash.logoTexture:SetTexture(textureFile)
    SCENE_MANAGER:Show("simpleLogoSplash")
end

function SimpleLogoSplash_AttemptHide()
    if ZO_Pregame_CanSkipVideos() then
        SCENE_MANAGER:Hide("simpleLogoSplash")
    end
end