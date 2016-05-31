-- Constants for screens that are derived from the LoginBase
ZO_LOGIN_EDITBOX_WIDTH = 500

-- Login Base screen -- 
ZO_LoginBase_Keyboard = ZO_Object:Subclass()

local DMM_LOGIN_LOGO_DATA = {
    leftSideTexturePath = "EsoUI/Art/Login/jp_login_logo_left.dds",
    leftSideWidth = 512,
    rightSideTexturePath = "EsoUI/Art/Login/jp_login_logo_right.dds",
    rightSideWidth = 256,
    height = 256,       -- Left and right logos share the same height
}

function ZO_LoginBase_Keyboard:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_LoginBase_Keyboard:Initialize(control)
    self.control = control

    self.bgMunge = control:GetNamedChild("BGMunge")
    self.esoLogo = control:GetNamedChild("ESOLogo")
    self.esoLogoRightSide = self.esoLogo:GetNamedChild("Right")

    self:UpdateEsoLogo()

    self:ResizeControls()
end

function ZO_LoginBase_Keyboard:ResizeControls()
    ZO_ReanchorControlForLeftSidePanel(self.bgMunge)
end

function ZO_LoginBase_Keyboard:UpdateEsoLogo()
    if not self.logoUpdated then
        -- Update the logo based on the service currently being used, if necessary

        local logoData
        local serviceType = GetPlatformServiceType()
        
        if serviceType == PLATFORM_SERVICE_TYPE_DMM then
            logoData = DMM_LOGIN_LOGO_DATA
        end

        if logoData then
            self.esoLogo:SetTexture(logoData.leftSideTexturePath)
            self.esoLogo:SetDimensions(logoData.leftSideWidth, logoData.height)
            
            self.esoLogoRightSide:SetTexture(logoData.rightSideTexturePath)
            self.esoLogoRightSide:SetDimensions(logoData.rightSideWidth, logoData.height)
        end

        self.logoUpdated = true
    end
end