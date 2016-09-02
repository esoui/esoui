local PregameAnimatedBackground = ZO_Object:Subclass()

local MAP_AREA_MIN_SIZE = 1080
local MAP_AREA_MAX_SIZE = 1920
local MAP_AREA_DEPTH = 0
local MAP_AREA_ASPECT_RATIO = 1

local DEPTH_EPSILON = 0.001
local MAP_DEPTH = MAP_AREA_DEPTH
local LINES_DEPTH = -0.2
local RINGS_DEPTH = LINES_DEPTH - DEPTH_EPSILON
local CONSTELLATIONS_DEPTH = -0.45
local DAEDRIC_TEXT_DEPTH = -0.65
local COLD_HARBOR_DEPTH = DAEDRIC_TEXT_DEPTH - DEPTH_EPSILON

local LINES_ROTATION_RADIANS_PER_S = math.rad(1)
local RINGS_ROTATION_RADIANS_PER_S = math.rad(-1)
local DAEDRIC_TEXT_ROTATION_RADIANS_PER_S = math.rad(-0.5)
local CONSTELLATIONS_ROTATION_RADIANS_PER_S = math.rad(0.5)
local COLD_HARBOR_ROTATION_RADIANS_PER_S = math.rad(-1)

ZO_PREGAME_ANIMATED_BACKGROUND_MAP_FADE_DURATION_MS = 500
ZO_PREGAME_ANIMATED_BACKGROUND_LINES_FADE_DELAY_MS = 150
ZO_PREGAME_ANIMATED_BACKGROUND_LINES_FADE_DURATION_MS = 500
ZO_PREGAME_ANIMATED_BACKGROUND_RINGS_FADE_DELAY_MS = 300
ZO_PREGAME_ANIMATED_BACKGROUND_RINGS_FADE_DURATION_MS = 500
ZO_PREGAME_ANIMATED_BACKGROUND_CONSTELLATIONS_FADE_DELAY_MS = 450
ZO_PREGAME_ANIMATED_BACKGROUND_CONSTELLATIONS_FADE_DURATION_MS = 500
ZO_PREGAME_ANIMATED_BACKGROUND_DAEDRIC_TEXT_FADE_DELAY_MS = 600
ZO_PREGAME_ANIMATED_BACKGROUND_DAEDRIC_TEXT_FADE_DURATION_MS = 500 
ZO_PREGAME_ANIMATED_BACKGROUND_COLD_HARBOR_FADE_DELAY_MS = 750
ZO_PREGAME_ANIMATED_BACKGROUND_COLD_HARBOR_FADE_DURATION_MS = 500 

function PregameAnimatedBackground:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function PregameAnimatedBackground:Initialize(control)
    self.control = control
    self.canvasControl = control:GetNamedChild("Canvas")
    self.mapTexture = self.canvasControl:GetNamedChild("Map")
    self.linesTexture = self.canvasControl:GetNamedChild("Lines")
    self.rings1Texture = self.canvasControl:GetNamedChild("Rings1")
    self.rings2Texture = self.canvasControl:GetNamedChild("Rings2")
    self.daedricTextTexture = self.canvasControl:GetNamedChild("DaedricText")
    self.constellationsTexture = self.canvasControl:GetNamedChild("Constellations")
    self.coldHarborTexture = self.canvasControl:GetNamedChild("ColdHarbor")
    
    PREGAME_ANIMATED_BACKGROUND_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    PREGAME_ANIMATED_BACKGROUND_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:Start()
        elseif newState == SCENE_HIDDEN then
            self.lastUpdateS = nil
        end
    end)

    control:SetHandler("OnUpdate", function(_, timeS) self:OnUpdate(timeS) end)
    control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:OnScreenResized() end)

    self:InitializeAnimations()
    self.sceneGraph = ZO_SceneGraph:New(self.canvasControl)
    self:ResizeSizes()
    self:BuildSceneGraph()
end

function PregameAnimatedBackground:InitializeAnimations()
    self.fadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_PregameAnimatedBackgroundFadeAnimation")
    self.fadeTimeline:GetAnimation(1):SetAnimatedControl(self.mapTexture)
    self.fadeTimeline:GetAnimation(2):SetAnimatedControl(self.linesTexture)
    self.fadeTimeline:GetAnimation(3):SetAnimatedControl(self.rings1Texture)
    self.fadeTimeline:GetAnimation(4):SetAnimatedControl(self.rings2Texture)
    self.fadeTimeline:GetAnimation(5):SetAnimatedControl(self.constellationsTexture)
    self.fadeTimeline:GetAnimation(6):SetAnimatedControl(self.daedricTextTexture)
    self.fadeTimeline:GetAnimation(7):SetAnimatedControl(self.coldHarborTexture)
end

function PregameAnimatedBackground:BuildSceneGraph()

    self.rootNode = self.sceneGraph:CreateNode("root")
    self.rootNode:SetParent(self.sceneGraph:GetCameraNode())

    self.mapNode = self.sceneGraph:CreateNode("map")
    self.mapNode:SetParent(self.rootNode)
    self.mapTexture:SetDimensions(self.mapNode:ComputeSizeForDepth(2048, 2048, MAP_DEPTH))
    self.mapNode:AddControl(self.mapTexture, 0, 0, MAP_DEPTH)

    self.linesNode = self.sceneGraph:CreateNode("lines")
    self.linesNode:SetParent(self.rootNode)
    self.linesTexture:SetDimensions(self.linesNode:ComputeSizeForDepth(2448, 2448, LINES_DEPTH))
    self.linesNode:AddControl(self.linesTexture, 0, 0, LINES_DEPTH)

    self.rings1Node = self.sceneGraph:CreateNode("rings1")
    self.rings1Node:SetParent(self.rootNode)
    self.rings1Texture:SetDimensions(self.rings1Node:ComputeSizeForDepth(2048, 2048, RINGS_DEPTH))
    self.rings1Node:AddControl(self.rings1Texture, 0, 0, RINGS_DEPTH)

    self.rings2Node = self.sceneGraph:CreateNode("rings2")
    self.rings2Node:SetParent(self.rootNode)
    self.rings2Texture:SetDimensions(self.rings2Node:ComputeSizeForDepth(2048, 2048, RINGS_DEPTH))
    self.rings2Node:AddControl(self.rings2Texture, 0, 0, RINGS_DEPTH)

    self.daedricTextNode = self.sceneGraph:CreateNode("daedricText")
    self.daedricTextNode:SetParent(self.rootNode)
    self.daedricTextTexture:SetDimensions(self.daedricTextNode:ComputeSizeForDepth(2048, 2048, DAEDRIC_TEXT_DEPTH))
    self.daedricTextNode:AddControl(self.daedricTextTexture, 0, 0, DAEDRIC_TEXT_DEPTH)

    self.constellationsNode = self.sceneGraph:CreateNode("constellations")
    self.constellationsNode:SetParent(self.rootNode)
    self.constellationsTexture:SetDimensions(self.constellationsNode:ComputeSizeForDepth(2348, 2348, CONSTELLATIONS_DEPTH))
    self.constellationsNode:AddControl(self.constellationsTexture, 0, 0, CONSTELLATIONS_DEPTH)

    self.coldHarborNode = self.sceneGraph:CreateNode("coldHarbor")
    self.coldHarborNode:SetParent(self.rootNode)
    self.coldHarborTexture:SetDimensions(self.coldHarborNode:ComputeSizeForDepth(512, 512, COLD_HARBOR_DEPTH))
    self.coldHarborNode:AddControl(self.coldHarborTexture, 210, 0, COLD_HARBOR_DEPTH)
    self.coldHarborNode:SetControlUseRotation(self.coldHarborTexture, false)
    self.coldHarborNode:SetRotation(math.rad(30) - zo_random() * math.rad(60) + math.pi * (zo_random(2) - 1))
end

function PregameAnimatedBackground:ResizeSizes()
    local canvasWidth, canvasHeight = GuiRoot:GetDimensions()
    local cameraZ = 0
    if canvasHeight > 0 then
        local canvasAspectRatio = canvasWidth / canvasHeight        
        local mapAreaSize
        if canvasAspectRatio > MAP_AREA_ASPECT_RATIO then
            mapAreaSize = canvasHeight
            if canvasWidth > (MAP_AREA_MAX_SIZE / MAP_AREA_MIN_SIZE) * mapAreaSize then
                mapAreaSize = canvasWidth * (MAP_AREA_MIN_SIZE / MAP_AREA_MAX_SIZE)
            end
        else
            mapAreaSize = canvasWidth
            if canvasHeight > (MAP_AREA_MAX_SIZE / MAP_AREA_MIN_SIZE) * mapAreaSize then
                mapAreaSize = canvasHeight * (MAP_AREA_MIN_SIZE / MAP_AREA_MAX_SIZE)
            end
        end
        local magnification = mapAreaSize / MAP_AREA_MIN_SIZE
        cameraZ = - (1 / magnification)
    end
    self.sceneGraph:SetCameraZ(cameraZ)
    self.rootCameraZ = cameraZ
end

function PregameAnimatedBackground:Start()    
    for i = 1, self.canvasControl:GetNumChildren() do
        local child = self.canvasControl:GetChild(i)
        child:SetAlpha(0)
    end
    self.fadeTimeline:PlayFromStart()
end

--Events

function PregameAnimatedBackground:OnUpdate(timeS)
    if self.lastUpdateS then
        local deltaS = timeS - self.lastUpdateS
        self.linesNode:AddRotation(deltaS * LINES_ROTATION_RADIANS_PER_S)
        self.rings1Node:AddRotation(deltaS * RINGS_ROTATION_RADIANS_PER_S)
        self.rings2Node:AddRotation(deltaS * -RINGS_ROTATION_RADIANS_PER_S)
        self.daedricTextNode:AddRotation(deltaS * DAEDRIC_TEXT_ROTATION_RADIANS_PER_S)
        self.constellationsNode:AddRotation(deltaS * CONSTELLATIONS_ROTATION_RADIANS_PER_S)
        self.coldHarborNode:AddRotation(deltaS * COLD_HARBOR_ROTATION_RADIANS_PER_S)
        self.sceneGraph:SetCameraX(10 * math.cos(timeS * 0.2))
        self.sceneGraph:SetCameraY(15 * math.sin(timeS * 0.2))
    end
    self.lastUpdateS = timeS    
end

function PregameAnimatedBackground:OnScreenResized()
    self:ResizeSizes()
end

--Global XML Handlers

function ZO_PregameAnimatedBackground_OnInitialized(self)
    PREGAME_ANIMATED_BACKGROUND = PregameAnimatedBackground:New(self)
end