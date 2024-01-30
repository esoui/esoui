ZO_FOUR_PI = ZO_TWO_PI * 2.0

ZO_BACKGROUND_PARAMETER_TYPES =
{
    ANGLE = 1,
    BOOLEAN = 2,
    CALCULATED = 3,
    FLOAT = 4,
    INTEGER = 5,
}

local g_backgroundParameters = {}
local g_backgroundParametersSorted = {}
local g_currentBackgroundParameterIndex = 0
local g_dirtyLayoutTextureControls = {}
local g_hasDirtyBackgroundParameters = false
local g_isLayoutDirty = true
local g_textureControls = {}
local g_textureControlPreferredAnchors = {}

local function RegisterBackgroundParameter(parameterKey, parameterInfo)
    if internalassert(g_backgroundParameters[parameterKey] == nil, string.format("Failed to register duplicate background parameter value [%s]", parameterKey)) then
        g_hasDirtyBackgroundParameters = true

        -- Visually order parameters in the order in which they are defined.
        g_currentBackgroundParameterIndex = g_currentBackgroundParameterIndex + 1
        parameterInfo.index = g_currentBackgroundParameterIndex

        -- Register the parameter.
        g_backgroundParameters[parameterKey] = parameterInfo

        return parameterInfo
    end
end

-- Specify 'defaultValue' in degrees; 'value' is stored in radians
function CreateBackgroundParameterAngle(parameterKey, defaultValue, minValue, maxValue, formatString)
    local parameterInfo =
    {
        dataType = ZO_BACKGROUND_PARAMETER_TYPES.ANGLE,
        defaultValue = defaultValue or 0.0,
        formatString = formatString or "%f deg",
        getFunction = function(self) return math.deg(self.value) end,
        labelText = parameterKey,
        key = parameterKey,
        maxValue = maxValue or 0.0,
        minValue = minValue or 360.0,
        setFunction = function(self, value) self.value = math.rad(value) end,
        value = math.rad(defaultValue),
    }
    return RegisterBackgroundParameter(parameterKey, parameterInfo)
end

function CreateBackgroundParameterBoolean(parameterKey, defaultValue)
    local parameterInfo =
    {
        dataType = ZO_BACKGROUND_PARAMETER_TYPES.BOOLEAN,
        defaultValue = defaultValue,
        formatString = "%s",
        labelText = parameterKey,
        key = parameterKey,
        value = defaultValue,
    }
    return RegisterBackgroundParameter(parameterKey, parameterInfo)
end

-- Calculated parameter values are set automatically by UpdateBackgroundParameters()
function CreateBackgroundParameterCalculated(parameterKey, valueFunction)
    local parameterInfo =
    {
        dataType = ZO_BACKGROUND_PARAMETER_TYPES.CALCULATED,
        key = parameterKey,
        valueFunction = valueFunction,
    }
    return RegisterBackgroundParameter(parameterKey, parameterInfo)
end

function CreateBackgroundParameterFloat(parameterKey, defaultValue, minValue, maxValue, formatString)
    local parameterInfo =
    {
        dataType = ZO_BACKGROUND_PARAMETER_TYPES.FLOAT,
        defaultValue = defaultValue,
        formatString = formatString or "%f",
        labelText = parameterKey,
        key = parameterKey,
        maxValue = maxValue,
        minValue = minValue,
        value = defaultValue,
    }
    return RegisterBackgroundParameter(parameterKey, parameterInfo)
end

function CreateBackgroundParameterInteger(parameterKey, defaultValue, minValue, maxValue, formatString)
    local parameterInfo =
    {
        dataType = ZO_BACKGROUND_PARAMETER_TYPES.INTEGER,
        defaultValue = defaultValue,
        formatString = formatString or "%d",
        key = parameterKey,
        labelText = parameterKey,
        maxValue = maxValue,
        minValue = minValue,
        value = defaultValue,
    }
    return RegisterBackgroundParameter(parameterKey, parameterInfo)
end

-- Returns a reference to the sorted background parameter registry table.
function ZO_GetBackgroundParameters()
    return g_backgroundParametersSorted
end

-- Returns the current value for the specified background parameter.
function ZO_GetBackgroundParameterValue(parameterKey)
    local parameterInfo = g_backgroundParameters[parameterKey]
    if internalassert(parameterInfo, "Failed to retrieve background parameter [%s]", parameterKey) then
        local value = nil
        if parameterInfo.getFunction then
            value = parameterInfo:getFunction()
        else
            value = parameterInfo.value
        end
        return value
    end
end

-- Set the current value for the specified background parameter.
function ZO_SetBackgroundParameterValue(parameterKey, newValue)
    local parameterInfo = g_backgroundParameters[parameterKey]
    if internalassert(parameterInfo, "Failed to update background parameter [%s]", parameterKey) then
        local previousValue = parameterInfo.value
        if parameterInfo.setFunction then
            parameterInfo:setFunction(newValue)
        else
            parameterInfo.value = newValue
        end
        g_hasDirtyBackgroundParameters = g_hasDirtyBackgroundParameters or previousValue ~= newValue
    end
end

local function CompareBackgroundParametersByKey(left, right)
    return left.key < right.key
end

-- Updates the global table with the current / calculated parameter values.
function UpdateBackgroundParameters()
    if not g_hasDirtyBackgroundParameters then
        return
    end

    local CALCULATED_TYPE = ZO_BACKGROUND_PARAMETER_TYPES.CALCULATED
    g_hasDirtyBackgroundParameters = false

    -- First update literal values.
    local numBackgroundParameters = 0
    for parameterKey, parameterInfo in pairs(g_backgroundParameters) do
        if parameterInfo.dataType ~= CALCULATED_TYPE then
            _G[parameterKey] = parameterInfo.value
        end
        numBackgroundParameters = numBackgroundParameters + 1
    end

    -- Then update calculated values as these could be dependent on literal values.
    for parameterKey, parameterInfo in pairs(g_backgroundParameters) do
        if parameterInfo.dataType == CALCULATED_TYPE then
            parameterInfo.value = parameterInfo.valueFunction()
            _G[parameterKey] = parameterInfo.value
        end
    end

    if numBackgroundParameters ~= #g_backgroundParametersSorted then
        -- Populate or update the sorted background parameter registry table.
        ZO_ClearNumericallyIndexedTable(g_backgroundParametersSorted)
        for _, parameterInfo in pairs(g_backgroundParameters) do
            table.insert(g_backgroundParametersSorted, parameterInfo)
        end
        table.sort(g_backgroundParametersSorted, CompareBackgroundParametersByKey)
    end
end

-- Base parameter definitions
-- CreateBackgroundParameter* arguments: parameterKey, defaultValue, minValue, maxValue, formatString

CreateBackgroundParameterFloat("ZO_BACKGROUND_TEXTURE_LOAD_TIMEOUT_SECONDS", 1, 1, 10, "%f seconds")

CreateBackgroundParameterInteger("ZO_BACKGROUND_TEXTURE_FILE_HEIGHT", 2048, 1, 4096)
CreateBackgroundParameterInteger("ZO_BACKGROUND_TEXTURE_FILE_WIDTH", 2048, 1, 4096)

CreateBackgroundParameterInteger("ZO_BACKGROUND_TEXTURE_IMAGE_HEIGHT", 1080, 1, 4096)
CreateBackgroundParameterInteger("ZO_BACKGROUND_TEXTURE_IMAGE_WIDTH", 1920, 1, 4096)

CreateBackgroundParameterFloat("ZO_BACKGROUND_INTRO_ANIMATION_DELAY_SECONDS", 0, 0, 30, "%f seconds")
CreateBackgroundParameterFloat("ZO_BACKGROUND_INTRO_ANIMATION_DURATION_SECONDS", 5, 0, 30, "%f seconds")

CreateBackgroundParameterFloat("ZO_BACKGROUND_LOOP_ANIMATION_DELAY_SECONDS", 5.5, 0, 600, "%f seconds")
CreateBackgroundParameterFloat("ZO_BACKGROUND_LOOP_ANIMATION_DURATION_SECONDS", 600, 0, 600, "%f seconds")

CreateBackgroundParameterFloat("ZO_BACKGROUND_PERSISTENT_ANIMATION_DURATION_SECONDS", 600, 0, 600, "%f seconds")

CreateBackgroundParameterCalculated("ZO_BACKGROUND_TEXTURE_IMAGE_ASPECT_RATIO", function() return ZO_BACKGROUND_TEXTURE_IMAGE_WIDTH / ZO_BACKGROUND_TEXTURE_IMAGE_HEIGHT end)
CreateBackgroundParameterCalculated("ZO_BACKGROUND_TEXTURE_IMAGE_HALF_HEIGHT", function() return ZO_BACKGROUND_TEXTURE_IMAGE_HEIGHT * 0.5 end)
CreateBackgroundParameterCalculated("ZO_BACKGROUND_TEXTURE_COORD_BOTTOM", function() return ZO_BACKGROUND_TEXTURE_IMAGE_HEIGHT / ZO_BACKGROUND_TEXTURE_FILE_HEIGHT end)
CreateBackgroundParameterCalculated("ZO_BACKGROUND_TEXTURE_COORD_RIGHT", function() return ZO_BACKGROUND_TEXTURE_IMAGE_WIDTH / ZO_BACKGROUND_TEXTURE_FILE_WIDTH end)

-- After defining the parameters, the global table -must- be
-- updated with the current/calculated parameter values.
UpdateBackgroundParameters()

-- ZO_BaseBackground Animation Scene

ZO_BaseBackground = ZO_InitializingObject:Subclass()

function ZO_BaseBackground:Initialize(control)
    self.control = control
    control.owner = self

    self.scaleX = 1
    self.scaleY = 1

    self:InitializeControls()
    self:UpdateLayout()

    PREGAME_ANIMATED_BACKGROUND = self
    PREGAME_ANIMATED_BACKGROUND_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    PREGAME_ANIMATED_BACKGROUND_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_HIDING then
            self:OnHiding()
        elseif newState == SCENE_HIDDEN then
            self:OnHidden()
        elseif newState == SCENE_SHOWING then
            self:OnShowing()
        else
            self:OnShown()
        end
    end)

    control:RegisterForEvent(EVENT_SCREEN_RESIZED, function()
        self:OnScreenResized()
    end)
end

function ZO_BaseBackground:InitializeControls()
    local control = self.control

    self.backgroundTexture = control:GetNamedChild("Background")
    self.ouroborosTexture = control:GetNamedChild("Ouroboros")
    self.titleTexture = control:GetNamedChild("Title")

    self.persistentTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_BaseBackgroundAnimation_Persistent", control)
    self.persistentTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)

    self.introTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_BaseBackgroundAnimation_Intro", control)
    self.introTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)

    self.loopTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_BaseBackgroundAnimation_Loop", control)
    self.loopTimeline:SetSkipAnimationsBehindPlayheadOnInitialPlay(false)
end

function ZO_BaseBackground:HasTextureLoadTimedOut()
    return self.hasTextureLoadTimedOut == true -- Coerce to Boolean
end

function ZO_BaseBackground:AreTexturesReady()
    if not (self.areTexturesReady or self.hasTextureLoadTimedOut) then
        local frameTimeS = GetFrameTimeSeconds()
        if not self.textureLoadStartTimeS then
            -- Track when textures began loading.
            self.textureLoadStartTimeS = frameTimeS
        elseif not self.hasTextureLoadTimedOut then
            if (frameTimeS - self.textureLoadStartTimeS) >= ZO_BACKGROUND_TEXTURE_LOAD_TIMEOUT_SECONDS then
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

function ZO_BaseBackground:GetTimelineProgress(timeline)
    local progress = timeline:GetFullProgress()
    local durationMs = timeline:GetDuration()
    local elapsedMs = durationMs * progress
    return progress, elapsedMs, durationMs
end

function ZO_BaseBackground:GetIntroTimelineProgress()
    return self:GetTimelineProgress(self.introTimeline)
end

function ZO_BaseBackground:GetLoopTimelineProgress()
    return self:GetTimelineProgress(self.loopTimeline)
end

function ZO_BaseBackground:GetScale()
    return self.scaleX, self.scaleY
end

function ZO_BaseBackground:GetTextureControls()
    return g_textureControls
end

function ZO_BaseBackground:IsLayoutDirty()
    return g_isLayoutDirty ~= false -- Coerce to Boolean
end

function ZO_BaseBackground:StartAnimation()
    if self.startFrameTimeS then
        -- Animation is already started.
        return
    end

    self.startFrameTimeS = GetFrameTimeSeconds()
    self.startLoopFrameTimeS = self.startFrameTimeS + ZO_BACKGROUND_LOOP_ANIMATION_DELAY_SECONDS

    local persistentAnimation = self.persistentTimeline:GetAnimation(1)
    persistentAnimation:SetDuration(ZO_BACKGROUND_PERSISTENT_ANIMATION_DURATION_SECONDS * 1000)
    self.persistentTimeline:PlayFromStart()

    local introAnimation = self.introTimeline:GetAnimation(1)
    introAnimation:SetDuration(ZO_BACKGROUND_INTRO_ANIMATION_DURATION_SECONDS * 1000)
    introAnimation:SetOffsetInParent(ZO_BACKGROUND_INTRO_ANIMATION_DELAY_SECONDS * 1000)
    self.introTimeline:PlayFromStart()

    local loopAnimation = self.loopTimeline:GetAnimation(1)
    loopAnimation:SetDuration(ZO_BACKGROUND_LOOP_ANIMATION_DURATION_SECONDS * 1000)
    loopAnimation:SetOffsetInParent(ZO_BACKGROUND_LOOP_ANIMATION_DELAY_SECONDS * 1000)
    self.loopTimeline:PlayFromStart()

    PlayPregameAnimatedBackgroundSounds()
end

function ZO_BaseBackground:StopAnimation()
    if not self.startFrameTimeS then
        -- Animation is already stopped.
        return
    end

    self.startFrameTimeS = nil
    self.startLoopFrameTimeS = nil

    self.persistentTimeline:Stop()
    self.introTimeline:Stop()
    self.loopTimeline:Stop()

    StopPregameAnimatedBackgroundSounds()
end

function ZO_BaseBackground:UpdateLayout()
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
        if screenAspectRatio > ZO_BACKGROUND_TEXTURE_IMAGE_ASPECT_RATIO then
            self.scaleX = screenWidth / ZO_BACKGROUND_TEXTURE_IMAGE_WIDTH
            local targetHeight = screenWidth * (1 / ZO_BACKGROUND_TEXTURE_IMAGE_ASPECT_RATIO)
            self.scaleY = targetHeight / ZO_BACKGROUND_TEXTURE_IMAGE_HEIGHT
        else
            self.scaleY = screenHeight / ZO_BACKGROUND_TEXTURE_IMAGE_HEIGHT
            local targetWidth = screenHeight * ZO_BACKGROUND_TEXTURE_IMAGE_ASPECT_RATIO
            self.scaleX = targetWidth / ZO_BACKGROUND_TEXTURE_IMAGE_WIDTH
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

    return true
end

function ZO_BaseBackground:UpdateTextureControlLayout(control, textureOptions)
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
        if textureWidth >= ZO_BACKGROUND_TEXTURE_FILE_WIDTH then
            -- Fullscreen width
            textureWidth = ZO_BACKGROUND_TEXTURE_IMAGE_WIDTH
            maxTexCoordX = ZO_BACKGROUND_TEXTURE_COORD_RIGHT
        end
        if textureHeight >= ZO_BACKGROUND_TEXTURE_FILE_HEIGHT then
            -- Fullscreen height
            textureHeight = ZO_BACKGROUND_TEXTURE_IMAGE_HEIGHT
            maxTexCoordY = ZO_BACKGROUND_TEXTURE_COORD_BOTTOM
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
function ZO_BaseBackground:GetScaledAnchorOffsets(offsetX, offsetY)
    local scaledOffsetX = offsetX * self.scaleX
    local scaledOffsetY = offsetY * self.scaleY
    return scaledOffsetX, scaledOffsetY
end

-- Events

function ZO_BaseBackground:OnHidden()
    -- Can be overridden
end

function ZO_BaseBackground:OnHiding()
    self:StopAnimation()
end

function ZO_BaseBackground:OnPersistentAnimationPlay(animation, completed)
    -- Can be overridden
end

function ZO_BaseBackground:OnPersistentAnimationStop(animation, completed)
    -- Can be overridden
end

function ZO_BaseBackground:OnPersistentAnimationUpdate(animation, progress)
    -- Can be overridden
end

function ZO_BaseBackground:OnIntroAnimationPlay(animation, completed)
    self.backgroundTexture:SetAlpha(0)
    self.ouroborosTexture:SetAlpha(0)
    self.titleTexture:SetAlpha(0)
end

function ZO_BaseBackground:OnIntroAnimationStop(animation, completed)
    self.backgroundTexture:SetAlpha(1)
    self.ouroborosTexture:SetAlpha(1)
    self.titleTexture:SetAlpha(1)
end

function ZO_BaseBackground:OnIntroAnimationUpdate(animation, progress)
    local backgroundAlpha = ZO_EaseInQuadratic(progress)
    self.backgroundTexture:SetAlpha(backgroundAlpha)

    local foregroundAlpha = ZO_EaseInQuadratic(zo_max(0, (progress - 0.25) * 1.3333))
    self.ouroborosTexture:SetAlpha(foregroundAlpha)
    self.titleTexture:SetAlpha(foregroundAlpha)
end

function ZO_BaseBackground:OnLoopAnimationPlay(animation, completed)
    -- Can be overridden.
end

function ZO_BaseBackground:OnLoopAnimationStop(animation, completed)
    -- Can be overridden.
end

function ZO_BaseBackground:OnLoopAnimationUpdate(animation, progress)
    -- Can be overridden.
end

function ZO_BaseBackground:OnScreenResized()
    g_isLayoutDirty = true
end

function ZO_BaseBackground:OnShowing()
    -- Can be overridden
end

function ZO_BaseBackground:OnShown()
    self:StartAnimation()
end

function ZO_BaseBackground:OnUpdate()
    -- Order matters:
    UpdateBackgroundParameters()
    self:UpdateLayout()
end

-- Global XML Handlers

function ZO_BaseBackground_RegisterTextureControl(control, hasStaticAnchors, isManuallySized)
    local textureOptions = 
    {
        hasStaticAnchors = hasStaticAnchors == true,    -- Coerce to Boolean, default to false
        isManuallySized = isManuallySized == true,      -- Coerce to Boolean, default to false
    }
    g_textureControls[control] = textureOptions
    g_dirtyLayoutTextureControls[control] = true
end