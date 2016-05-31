local CreateLogoSplashScene
do
    local KEYBOARD_STYLE = { copyrightInfo = "ZO_CopyrightInfo_Keyboard_Template" }
    local GAMEPAD_STYLE = { copyrightInfo = "ZO_CopyrightInfo_Gamepad_Template" }

    local ZO_LogoSplashFragment = ZO_FadeSceneFragment:Subclass()

    function ZO_LogoSplashFragment:New(control)
        local fragment = ZO_FadeSceneFragment.New(self, control, false, 700)
        fragment.control = control
        control:GetNamedChild("DMMLogo"):SetHidden(GetPlatformServiceType() ~= PLATFORM_SERVICE_TYPE_DMM)
        return fragment
    end

    function ZO_LogoSplashFragment:ApplyPlatformStyle(style)
        ApplyTemplateToControl(self.control:GetNamedChild("CopyrightInfo"), style.copyrightInfo)
    end

    function ZO_LogoSplashFragment:Show()
        ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)

        self.autoFadeTime = GetFrameTimeMilliseconds() + 5000

        local function OnUpdate()
            if(GetFrameTimeMilliseconds() >= self.autoFadeTime) then
                self.control:SetHandler("OnUpdate", nil)
                SCENE_MANAGER:Hide("logoSplash")
            end
        end

        self.control:SetHandler("OnUpdate", OnUpdate)

        -- Call base class for animations after everything has been tweaked
        ZO_FadeSceneFragment.Show(self)
    end

    function ZO_LogoSplashFragment:OnHidden()
        ZO_FadeSceneFragment.OnHidden(self)
        self.control:SetHandler("OnUpdate", nil)

        -- After all videos and the splash screen have shown, the user is no longer *required* to sit through them.
        SetCVar("HasPlayedPregameVideo", "1")
        PregameStateManager_AdvanceState()
    end

    CreateLogoSplashScene = function(control)
        local logoSplash = ZO_Scene:New("logoSplash", SCENE_MANAGER)
        logoSplash:AddFragment(ZO_LogoSplashFragment:New(control))
    end
end

function LogoSplash_Initialize(self)
    CreateLogoSplashScene(self)
end

function LogoSplash_AttemptHide()
    if(IsConsoleUI() or not ZO_Pregame_MustPlayVideos()) then
        SCENE_MANAGER:Hide("logoSplash")
    end
end