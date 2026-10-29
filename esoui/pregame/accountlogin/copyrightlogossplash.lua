local CreateCopyrightLogosSplashScene
do
    local KEYBOARD_STYLE = { copyrightInfo = "ZO_CopyrightInfo_Keyboard_Template" }
    local GAMEPAD_STYLE = { copyrightInfo = "ZO_CopyrightInfo_Gamepad_Template" }

    local ZO_CopyrightLogosSplashFragment = ZO_FadeSceneFragment:Subclass()

    function ZO_CopyrightLogosSplashFragment:Initialize(control)
        ZO_FadeSceneFragment.Initialize(self, control, false, 700)
    end

    function ZO_CopyrightLogosSplashFragment:ApplyPlatformStyle(style)
        ApplyTemplateToControl(self.copyrightInfoLabel, style.copyrightInfo)
    end

    function ZO_CopyrightLogosSplashFragment:Show()
        self.copyrightInfoLabel = self.control:GetNamedChild("CopyrightInfo")
        local COPYRIGHT_END_YEAR = 2027
        self.copyrightInfoLabel:SetText(zo_strformat(SI_SPLASH_SCREEN_COPYRIGHT, COPYRIGHT_END_YEAR))
        ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, KEYBOARD_STYLE, GAMEPAD_STYLE)

        self.autoFadeTime = GetFrameTimeMilliseconds() + 5000

        local function OnUpdate()
            if(GetFrameTimeMilliseconds() >= self.autoFadeTime) then
                self.control:SetHandler("OnUpdate", nil)
                SCENE_MANAGER:Hide("copyrightLogosSplash")
            end
        end

        self.control:SetHandler("OnUpdate", OnUpdate)

        -- Call base class for animations after everything has been tweaked
        ZO_FadeSceneFragment.Show(self)
    end

    function ZO_CopyrightLogosSplashFragment:OnHidden()
        ZO_FadeSceneFragment.OnHidden(self)
        self.control:SetHandler("OnUpdate", nil)

        -- After all videos and the splash screen have shown, the user is no longer *required* to sit through them.
        SetCVar("HasPlayedPregameVideo", "1")
        ZO_PregameStateManager_AdvanceState()
    end

    CreateCopyrightLogosSplashScene = function(control)
        local copyrightLogosSplash = ZO_Scene:New("copyrightLogosSplash", SCENE_MANAGER)
        copyrightLogosSplash:AddFragment(ZO_CopyrightLogosSplashFragment:New(control))
    end
end

function CopyrightLogosSplash_Initialize(self)
    CreateCopyrightLogosSplashScene(self)
end

function CopyrightLogosSplash_AttemptHide()
    if ZO_Pregame_CanSkipVideos() then
        SCENE_MANAGER:Hide("copyrightLogosSplash")
    end
end