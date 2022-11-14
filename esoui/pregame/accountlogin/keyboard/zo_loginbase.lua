-- Constants for screens that are derived from the LoginBase
ZO_LOGIN_EDITBOX_WIDTH = 500

-- Login Base screen -- 
ZO_LoginBase_Keyboard = ZO_Object:Subclass()

local DMM_LOGIN_LOGO_DATA =
{
    leftSideTexturePath = "EsoUI/Art/Login/jp_login_logo_left.dds",
    rightSideTexturePath = "EsoUI/Art/Login/jp_login_logo_right.dds",
}

local LANGUAGE_OVERRIDES_LOGIN_LOGO =
{
    ["zh"] = true,
}

function ZO_LoginBase_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_LoginBase_Keyboard:Initialize(control)
    self.control = control

    self.bgMunge = control:GetNamedChild("BGMunge")
    self.esoLogoLeftSide = control:GetNamedChild("ESOLogoLeft")
    self.esoLogoRightSide = control:GetNamedChild("ESOLogoRight")

    self:UpdateEsoLogo()

    self:ResizeControls()
end

function ZO_LoginBase_Keyboard:ResizeControls()
    if PregameStateManager_GetCurrentState() == "AccountLogin" then
        ZO_ReanchorControlTopHorizontalMenu(ZO_OptionsWindow)
    else
        ZO_ReanchorControlForLeftSidePanel(self.bgMunge)
    end
end

function ZO_LoginBase_Keyboard:UpdateEsoLogo()
    if not self.logoUpdated then
        -- Update the logo based on the service currently being used, if necessary

        local logoData
        local serviceType = GetPlatformServiceType()
        
        if serviceType == PLATFORM_SERVICE_TYPE_DMM then
            logoData = DMM_LOGIN_LOGO_DATA
        else
            local language = GetCVar("Language.2")
            if LANGUAGE_OVERRIDES_LOGIN_LOGO[language] then
                logoData =
                {
                    leftSideTexturePath = string.format("EsoUI/Art/Login/%s_login_logo_left.dds", language),
                    rightSideTexturePath = string.format("EsoUI/Art/Login/%s_login_logo_right.dds", language),
                }
            end
        end

        if logoData then
            self.esoLogoLeftSide:SetTexture(logoData.leftSideTexturePath)
            self.esoLogoRightSide:SetTexture(logoData.rightSideTexturePath)
        end

        self.logoUpdated = true
    end
end