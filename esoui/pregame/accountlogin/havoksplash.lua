local CreateHavokSplashScene
do
    local ZO_HavokSplashFragment = ZO_FadeSceneFragment:Subclass()

    function ZO_HavokSplashFragment:New(control)
        local fragment = ZO_FadeSceneFragment.New(self, control, 700)
        fragment.control = control
        return fragment
    end

    function ZO_HavokSplashFragment:Show()
        self.autoFadeTime = GetFrameTimeMilliseconds() + 2000

        local function OnUpdate()
            if(GetFrameTimeMilliseconds() >= self.autoFadeTime) then
                self.control:SetHandler("OnUpdate", nil)
                SCENE_MANAGER:Hide("havokSplash")
            end
        end

        self.control:SetHandler("OnUpdate", OnUpdate)

        -- Call base class for animations after everything has been tweaked
        ZO_FadeSceneFragment.Show(self)
    end

    function ZO_HavokSplashFragment:OnHidden()
        ZO_FadeSceneFragment.OnHidden(self)
        self.control:SetHandler("OnUpdate", nil)

        PregameStateManager_AdvanceState()
    end

    CreateHavokSplashScene = function(control)
        local havokSplash = ZO_Scene:New("havokSplash", SCENE_MANAGER)
        havokSplash:AddFragment(ZO_HavokSplashFragment:New(control))
    end
end

function HavokSplash_Initialize(self)
    CreateHavokSplashScene(self)
end

function HavokSplash_AttemptHide()
    if(IsConsoleUI() or not ZO_Pregame_MustPlayVideos()) then
        SCENE_MANAGER:Hide("havokSplash")
    end
end