ZO_PRELOGIN_OVERLAY_TEXTURE_LOAD_TIMEOUT_SECONDS = 1
ZO_PRELOGIN_OVERLAY_TEXTURE_FILE_HEIGHT = 2048
ZO_PRELOGIN_OVERLAY_TEXTURE_FILE_WIDTH = 2048
ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_HEIGHT = 1080
ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_WIDTH = 1920
ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_HALF_HEIGHT = ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_HEIGHT * 0.5
ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_ASPECT_RATIO = ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_WIDTH / ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_HEIGHT
ZO_PRELOGIN_OVERLAY_TEXTURE_COORD_BOTTOM = ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_HEIGHT / ZO_PRELOGIN_OVERLAY_TEXTURE_FILE_HEIGHT
ZO_PRELOGIN_OVERLAY_TEXTURE_COORD_RIGHT = ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_WIDTH / ZO_PRELOGIN_OVERLAY_TEXTURE_FILE_WIDTH

local FADE_OUT_DURATION_MS = 2000
local g_textureControls = {}
local g_dirtyLayoutTextureControls = {}

-- ZO_PreloginOverlay Scene

ZO_PreloginOverlay = ZO_InitializingObject:Subclass()

function ZO_PreloginOverlay:Initialize(control)
    self.control = control
    control.owner = self

    self.scaleX = 1
    self.scaleY = 1
    self.hidden = true

    self:InitializeControls()
    self:UpdateLayout()

    control:RegisterForEvent(EVENT_SCREEN_RESIZED, function()
        self:OnScreenResized()
    end)

    PRELOGIN_OVERLAY = self
end

function ZO_PreloginOverlay:InitializeControls()
    local control = self.control

    self.spinnerControl = control:GetNamedChild("Spinner")
    self.ouroborosTexture = self.spinnerControl:GetNamedChild("Ouroboros")
end

function ZO_PreloginOverlay:SetHidden(hidden)
    if hidden == self.hidden then
        return
    end

    -- Fade out is handled in OnUpdate()
    self.hidden = hidden
    if hidden then
        self.hiddenStartTimeMS = GetFrameTimeMilliseconds()
    else
        self.hiddenStartTimeMS = nil
        self.spinnerControl:SetAlpha(1)
        self.control:SetAlpha(1)
        self.control:SetHidden(false)
    end
end

function ZO_PreloginOverlay:HasTextureLoadTimedOut()
    return self.hasTextureLoadTimedOut == true -- Coerce to Boolean
end

function ZO_PreloginOverlay:AreTexturesReady()
    if not (self.areTexturesReady or self.hasTextureLoadTimedOut) then
        local frameTimeS = GetFrameTimeSeconds()
        if not self.textureLoadStartTimeS then
            -- Track when textures began loading.
            self.textureLoadStartTimeS = frameTimeS
        elseif not self.hasTextureLoadTimedOut then
            if (frameTimeS - self.textureLoadStartTimeS) >= ZO_PRELOGIN_OVERLAY_TEXTURE_LOAD_TIMEOUT_SECONDS then
                -- Texture loading has met or exceeded the timeout threshold.
                self.hasTextureLoadTimedOut = true
                return true
            end
        end

        local textureControls = self:GetTextureControls()
        for textureControl in pairs(textureControls) do
            if not textureControl:IsTextureLoaded() then
                -- One or more textures are still loading.
                return false
            end
        end

        -- All textures have loaded.
        self.areTexturesReady = true
    end

    return true
end

function ZO_PreloginOverlay:GetScale()
    return self.scaleX, self.scaleY
end

function ZO_PreloginOverlay:GetTextureControls()
    return g_textureControls
end

function ZO_PreloginOverlay:IsLayoutDirty()
    return g_isLayoutDirty ~= false -- Coerce to Boolean
end

function ZO_PreloginOverlay:IsHidden()
    return self.control:IsHidden()
end

function ZO_PreloginOverlay:UpdateAnimation()
    local rotationAngle = -0.4 * GetFrameTimeSeconds() % ZO_TWO_PI
    ZO_ScaleAndRotateTextureCoords(self.ouroborosTexture, rotationAngle, 0.5, 0.5, 1.0, 1.0)
end

function ZO_PreloginOverlay:UpdateLayout()
    if not self:AreTexturesReady() then
        return false
    end

    if g_isLayoutDirty ~= false then
        g_isLayoutDirty = false

        local screenWidth, screenHeight = GuiRoot:GetDimensions()
        self.screenWidth, self.screenHeight = screenWidth, screenHeight

        -- Calculate the x- and y-scaling necessary to fill the entire screen
        -- while maintaining the target aspect ratio.
        local screenAspectRatio = screenWidth / screenHeight
        if screenAspectRatio > ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_ASPECT_RATIO then
            self.scaleX = screenWidth / ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_WIDTH
            local targetHeight = screenWidth * (1 / ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_ASPECT_RATIO)
            self.scaleY = targetHeight / ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_HEIGHT
        else
            self.scaleY = screenHeight / ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_HEIGHT
            local targetWidth = screenHeight * ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_ASPECT_RATIO
            self.scaleX = targetWidth / ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_WIDTH
        end
        self.scaleX, self.scaleY = zo_max(1, self.scaleX), zo_max(1, self.scaleY)

        -- Update the scale and anchoring for all texture controls.
        for control, textureOptions in pairs(self:GetTextureControls()) do
            self:UpdateTextureControlLayout(control, textureOptions)
        end

        ZO_ClearTable(g_dirtyLayoutTextureControls)
    elseif next(g_dirtyLayoutTextureControls) then
        -- Update the scale and anchoring for texture controls that have changed.
        for control in pairs(g_dirtyLayoutTextureControls) do
            local textureOptions = g_textureControls[control]
            self:UpdateTextureControlLayout(control, textureOptions)
        end

        ZO_ClearTable(g_dirtyLayoutTextureControls)
    end

    self:UpdateAnimation()

    return true
end

function ZO_PreloginOverlay:UpdateTextureControlLayout(control, textureOptions)
    local textureWidth, textureHeight = control:GetTextureFileDimensions()

    if not textureOptions then
        return
    end

    if textureOptions.hasStaticAnchors then
        if not control.baseAnchor then
            -- Cache the default anchor.
            control.baseAnchor = ZO_Anchor:New()
            control.baseAnchor:SetFromControlAnchor(control, 0)
        end
        local offsetX, offsetY = control.baseAnchor:GetOffsets()
        if offsetX ~= 0 or offsetY ~= 0 then
            -- Scale the anchor offset and reapply the anchor.
            local scaledOffsetX, scaledOffsetY = offsetX * self.scaleX, offsetY * self.scaleY
            local scaledAnchor = ZO_Anchor:New(control.baseAnchor)
            scaledAnchor:SetOffsets(scaledOffsetX, scaledOffsetY)
            scaledAnchor:Set(control)
        end
    end

    if not textureOptions.isManuallySized then
        local maxTexCoordX, maxTexCoordY = 1, 1
        if textureWidth >= ZO_PRELOGIN_OVERLAY_TEXTURE_FILE_WIDTH then
            -- Fullscreen width
            textureWidth = ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_WIDTH
            maxTexCoordX = ZO_PRELOGIN_OVERLAY_TEXTURE_COORD_RIGHT
        end
        if textureHeight >= ZO_PRELOGIN_OVERLAY_TEXTURE_FILE_HEIGHT then
            -- Fullscreen height
            textureHeight = ZO_PRELOGIN_OVERLAY_TEXTURE_IMAGE_HEIGHT
            maxTexCoordY = ZO_PRELOGIN_OVERLAY_TEXTURE_COORD_BOTTOM
        end
        control:SetTextureCoords(0, maxTexCoordX, 0, maxTexCoordY)
    end

    if textureOptions.isManuallySized then
        if not textureOptions.width then
            -- Cache the original dimensions.
            textureOptions.width, textureOptions.height = control:GetDimensions()
        end
        textureWidth, textureHeight = textureOptions.width, textureOptions.height
    end

    -- Apply scaled dimensions.
    local scaledWidth = textureWidth * self.scaleX
    local scaledHeight = textureHeight * self.scaleY
    control:SetDimensions(scaledWidth, scaledHeight)
end

-- Scales the specified x- and y-offsets relative to the screen aspect ratio.
function ZO_PreloginOverlay:GetScaledAnchorOffsets(offsetX, offsetY)
    local scaledOffsetX = offsetX * self.scaleX
    local scaledOffsetY = offsetY * self.scaleY
    return scaledOffsetX, scaledOffsetY
end

-- Events

function ZO_PreloginOverlay:OnScreenResized()
    g_isLayoutDirty = true
end

function ZO_PreloginOverlay:OnUpdate()
    self:UpdateLayout()

    if self.hiddenStartTimeMS then
        local intervalMS = GetFrameTimeMilliseconds() - self.hiddenStartTimeMS
        local progress = intervalMS / FADE_OUT_DURATION_MS
        if progress >= 1.0 then
            self.hiddenStartTimeMS = nil
            self.control:SetHidden(true)
        else
            self.spinnerControl:SetAlpha(zo_clamp(1.0 - 4.0 * progress, 0.0, 1.0))
            progress = 1.0 - progress
            self.control:SetAlpha(progress * progress)
        end
    end
end

function ZO_PreloginOverlay.InitializeControl(control)
    PRELOGIN_OVERLAY = ZO_PreloginOverlay:New(control)
end

-- Global XML Handlers

function ZO_PreloginOverlay_RegisterTextureControl(control, hasStaticAnchors, isManuallySized)
    local textureOptions = 
    {
        hasStaticAnchors = hasStaticAnchors == true,    -- Coerce to Boolean, default to false
        isManuallySized = isManuallySized == true,      -- Coerce to Boolean, default to false
    }
    g_textureControls[control] = textureOptions
    g_dirtyLayoutTextureControls[control] = true
end