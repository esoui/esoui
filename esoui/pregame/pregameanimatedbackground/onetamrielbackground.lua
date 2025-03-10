local OneTamrielBackground = ZO_Object:Subclass()

-- Map and texture sizes
local MAP_AREA_MIN_SIZE = 1080
local MAP_AREA_MAX_SIZE = 1920
local MAP_AREA_TEXTURE_SIZE = 2048
local MAP_AREA_MIN_SIZE_PERCENT_OF_TEXTURE_SIZE = MAP_AREA_MIN_SIZE / MAP_AREA_TEXTURE_SIZE
local MAP_AREA_MAX_SIZE_PERCENT_OF_TEXTURE_SIZE = MAP_AREA_MAX_SIZE / MAP_AREA_TEXTURE_SIZE
local MAP_AREA_DEPTH = 0
local MAP_AREA_ASPECT_RATIO = 1

-- Scene graph node depths
local DEPTH_EPSILON = 0.00001
local MAP_DEPTH = MAP_AREA_DEPTH
local LINES_DEPTH = -0.2
local RINGS_DEPTH = LINES_DEPTH - DEPTH_EPSILON
local CONSTELLATIONS_DEPTH = -0.45
local DAEDRIC_TEXT_DEPTH = -0.65
local REALM_DEPTH = DAEDRIC_TEXT_DEPTH - DEPTH_EPSILON

-- Rotation speeds
local LINES_ROTATION_RADIANS_PER_S = math.rad(0.25)
local RINGS_ROTATION_RADIANS_PER_S = math.rad(-0.5)
local DAEDRIC_TEXT_ROTATION_RADIANS_PER_S = math.rad(-0.5)
local CONSTELLATIONS_ROTATION_RADIANS_PER_S = math.rad(-0.125)

-- Animation timing
ZO_ONE_TAMRIEL_BACKGROUND_MAP_FADE_DURATION_MS = 500
ZO_ONE_TAMRIEL_BACKGROUND_LINES_FADE_DELAY_MS = 150
ZO_ONE_TAMRIEL_BACKGROUND_LINES_FADE_DURATION_MS = 500
ZO_ONE_TAMRIEL_BACKGROUND_RINGS_FADE_DELAY_MS = 300
ZO_ONE_TAMRIEL_BACKGROUND_RINGS_FADE_DURATION_MS = 500
ZO_ONE_TAMRIEL_BACKGROUND_CONSTELLATIONS_FADE_DELAY_MS = 450
ZO_ONE_TAMRIEL_BACKGROUND_CONSTELLATIONS_FADE_DURATION_MS = 500
ZO_ONE_TAMRIEL_BACKGROUND_DAEDRIC_TEXT_FADE_DELAY_MS = 600
ZO_ONE_TAMRIEL_BACKGROUND_DAEDRIC_TEXT_FADE_DURATION_MS = 500 
ZO_ONE_TAMRIEL_BACKGROUND_REALM_FADE_DELAY_MS = 750
ZO_ONE_TAMRIEL_BACKGROUND_REALM_FADE_DURATION_MS = 500 

function OneTamrielBackground:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function OneTamrielBackground:Initialize(control)
    self.control = control

    -- Map Elements
    self.canvasControl = control:GetNamedChild("Canvas")
    self.mapTexture = self.canvasControl:GetNamedChild("Map")
    self.linesTexture = self.canvasControl:GetNamedChild("Lines")
    self.rings1Texture = self.canvasControl:GetNamedChild("Rings1")
    self.rings2Texture = self.canvasControl:GetNamedChild("Rings2")
    self.daedricTextTexture = self.canvasControl:GetNamedChild("DaedricText")
    self.constellationsTexture = self.canvasControl:GetNamedChild("Constellations")

    -- Realm "Islands"
    self.realms =
    {
        Apocrypha = { graphAngleOffsetRadians = math.rad(120), },
        Artaeum = { graphAngleOffsetRadians = math.rad(60), },
        ClockworkCity = { graphAngleOffsetRadians = math.rad(240), },
        Coldharbour = { graphAngleOffsetRadians = math.rad(150), },
        Deadlands = { graphAngleOffsetRadians = math.rad(330), },
        Eyevea = { graphAngleOffsetRadians = math.rad(180), },
        Fargrave = { graphAngleOffsetRadians = math.rad(300), },
    }

    for realmName, realmData in pairs(self.realms) do
        realmData.control = self.canvasControl:GetNamedChild(realmName)
    end

    PREGAME_ANIMATED_BACKGROUND_FRAGMENT = ZO_SimpleSceneFragment:New(control)
    PREGAME_ANIMATED_BACKGROUND_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:Start()
        elseif newState == SCENE_HIDDEN then
            self:Stop()
        end
    end)

    control:SetHandler("OnUpdate", function(_, timeS) self:OnUpdate(timeS) end)
    control:RegisterForEvent(EVENT_SCREEN_RESIZED, function() self:OnScreenResized() end)

    self:InitializeAnimations()
    self.sceneGraph = ZO_SceneGraph:New(self.canvasControl)
    self:BuildSceneGraph()
    self:ResizeSizes()
end

function OneTamrielBackground:InitializeAnimations()
    self.fadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_OneTamrielBackgroundFadeAnimation")

    -- Map Elements
    self.fadeTimeline:GetAnimation(1):SetAnimatedControl(self.mapTexture)
    self.fadeTimeline:GetAnimation(2):SetAnimatedControl(self.linesTexture)
    self.fadeTimeline:GetAnimation(3):SetAnimatedControl(self.rings1Texture)
    self.fadeTimeline:GetAnimation(4):SetAnimatedControl(self.rings2Texture)
    self.fadeTimeline:GetAnimation(5):SetAnimatedControl(self.constellationsTexture)
    self.fadeTimeline:GetAnimation(6):SetAnimatedControl(self.daedricTextTexture)

    -- Realm "Islands"
    local animationIndex = 7
    for realmName, realmData in pairs(self.realms) do
        self.fadeTimeline:GetAnimation(animationIndex):SetAnimatedControl(realmData.control)
        animationIndex = animationIndex + 1
    end
end

function OneTamrielBackground:BuildSceneGraph()
    self.rootNode = self.sceneGraph:CreateNode("root")
    self.rootNode:SetParent(self.sceneGraph:GetCameraNode())

    -- Map Elements
    self.mapNode = self.sceneGraph:CreateNode("map")
    self.mapNode:SetParent(self.rootNode)
    self.mapNode:AddTexture(self.mapTexture, 0, 0, MAP_DEPTH)

    self.linesNode = self.sceneGraph:CreateNode("lines")
    self.linesNode:SetParent(self.rootNode)
    self.linesNode:AddTexture(self.linesTexture, 0, 0, LINES_DEPTH)

    self.rings1Node = self.sceneGraph:CreateNode("rings1")
    self.rings1Node:SetParent(self.rootNode)
    self.rings1Node:AddTexture(self.rings1Texture, 0, 0, RINGS_DEPTH)

    self.rings2Node = self.sceneGraph:CreateNode("rings2")
    self.rings2Node:SetParent(self.rootNode)
    self.rings2Node:AddTexture(self.rings2Texture, 0, 0, RINGS_DEPTH)

    self.daedricTextNode = self.sceneGraph:CreateNode("daedricText")
    self.daedricTextNode:SetParent(self.rootNode)
    self.daedricTextNode:AddTexture(self.daedricTextTexture, 0, 0, DAEDRIC_TEXT_DEPTH)

    self.constellationsNode = self.sceneGraph:CreateNode("constellations")
    self.constellationsNode:SetParent(self.rootNode)
    self.constellationsNode:AddTexture(self.constellationsTexture, 0, 0, CONSTELLATIONS_DEPTH)

    -- Realm "Islands"
    for realmName, realmData in pairs(self.realms) do
        local graphNode = self.sceneGraph:CreateNode(realmName)
        realmData.graphNode = graphNode
        graphNode:SetParent(self.rootNode)

        -- Rotate the graph node into its assigned position on the ring.
        graphNode:SetRotation(realmData.graphAngleOffsetRadians)

        local islandGraphNode = self.sceneGraph:CreateNode(realmName .. "Island")
        realmData.islandGraphNode = islandGraphNode
        islandGraphNode:SetParent(graphNode)
        islandGraphNode:AddTexture(realmData.control, 0, 0, REALM_DEPTH)

        -- Counter the graph node's offset angle to ensure that the island remains upright.
        islandGraphNode:SetRotation(-realmData.graphAngleOffsetRadians)
    end
end

function OneTamrielBackground:ResizeSizes()
    local canvasWidth, canvasHeight = GuiRoot:GetDimensions()
    local cameraZ = 0
    local mapAreaSize = 0
    if canvasHeight > 0 then
        local canvasAspectRatio = canvasWidth / canvasHeight
        if canvasAspectRatio > MAP_AREA_ASPECT_RATIO then
            --If there is extra width space then start with making the map area as tall as possible (right up the the edge of the min size that has to 
            --be on screen). This will cover the most width.
            local heightPercentOfImage = MAP_AREA_MIN_SIZE_PERCENT_OF_TEXTURE_SIZE
            local widthPercentOfImage = heightPercentOfImage * canvasAspectRatio
            --If the percentage of the map area that would be shown width wise is still larger than what's allowed
            if widthPercentOfImage > MAP_AREA_MAX_SIZE_PERCENT_OF_TEXTURE_SIZE then
                --Then size the map area to the width of the screen and compute the height from that (this will clip more into the min
                --area than desired but it can't be helped since we need to maintain the aspect ratio).
                widthPercentOfImage = MAP_AREA_MAX_SIZE_PERCENT_OF_TEXTURE_SIZE
                heightPercentOfImage = widthPercentOfImage / canvasAspectRatio
            end
            mapAreaSize = canvasHeight / heightPercentOfImage
        else
            --same algorithm but for extra height space
            local widthPercentOfImage = MAP_AREA_MIN_SIZE_PERCENT_OF_TEXTURE_SIZE
            local heightPercentOfImage = widthPercentOfImage / canvasAspectRatio
            if heightPercentOfImage > MAP_AREA_MAX_SIZE_PERCENT_OF_TEXTURE_SIZE then
                heightPercentOfImage = MAP_AREA_MAX_SIZE_PERCENT_OF_TEXTURE_SIZE
                widthPercentOfImage = heightPercentOfImage * canvasAspectRatio
            end
            mapAreaSize = canvasWidth / widthPercentOfImage
        end
    end

    --The ratio of the final map area to the reference size is used as a scale factor. The size of every other node is done in reference to the MAP_AREA_TEXTURE_SIZE
    local magnification = mapAreaSize / MAP_AREA_TEXTURE_SIZE

    -- Map Elements
    self.mapTexture:SetDimensions(self.mapNode:ComputeSizeForDepth(MAP_AREA_TEXTURE_SIZE * magnification, MAP_AREA_TEXTURE_SIZE * magnification, MAP_DEPTH))
    self.linesTexture:SetDimensions(self.linesNode:ComputeSizeForDepth(2448 * magnification, 2448 * magnification, LINES_DEPTH))
    self.linesNode:SetX(self.linesNode:ComputeSizeForDepth(50 * magnification, 0, LINES_DEPTH))
    self.rings1Texture:SetDimensions(self.rings1Node:ComputeSizeForDepth(2048 * magnification, 2048 * magnification, RINGS_DEPTH))
    self.rings2Texture:SetDimensions(self.rings2Node:ComputeSizeForDepth(2048 * magnification, 2048 * magnification, RINGS_DEPTH))
    self.daedricTextTexture:SetDimensions(self.daedricTextNode:ComputeSizeForDepth(2048 * magnification, 2048 * magnification, DAEDRIC_TEXT_DEPTH))
    self.constellationsTexture:SetDimensions(self.constellationsNode:ComputeSizeForDepth(2348 * magnification, 2348 * magnification, CONSTELLATIONS_DEPTH))

    -- Realm "Islands"
    local realmSize = 384 * magnification
    local realmOffset = 735 * magnification
    for realmName, realmData in pairs(self.realms) do
        realmData.control:SetDimensions(realmData.islandGraphNode:ComputeSizeForDepth(realmSize, realmSize, REALM_DEPTH))
        realmData.graphNode:SetX(realmData.graphNode:ComputeSizeForDepth(realmOffset, 0, REALM_DEPTH))
    end
end

function OneTamrielBackground:Start()
    for i = 1, self.canvasControl:GetNumChildren() do
        local child = self.canvasControl:GetChild(i)
        child:SetAlpha(0)
    end
    self.fadeTimeline:PlayFromStart()
end

function OneTamrielBackground:Stop()
    self.fadeTimeline:Stop()
end

-- Events

function OneTamrielBackground:OnUpdate(timeS)
    local deltaS = GetFrameDeltaTimeSeconds()

    -- Map Elements
    self.constellationsNode:AddRotation(deltaS * CONSTELLATIONS_ROTATION_RADIANS_PER_S)
    self.linesNode:AddRotation(deltaS * LINES_ROTATION_RADIANS_PER_S)
    self.rings1Node:AddRotation(deltaS * RINGS_ROTATION_RADIANS_PER_S)
    self.rings2Node:AddRotation(deltaS * -RINGS_ROTATION_RADIANS_PER_S)
    self.daedricTextNode:AddRotation(deltaS * DAEDRIC_TEXT_ROTATION_RADIANS_PER_S)

    -- Realm "Islands"
    local realmRotationRadians = deltaS * RINGS_ROTATION_RADIANS_PER_S
    for realmName, realmData in pairs(self.realms) do
        realmData.graphNode:AddRotation(realmRotationRadians)
        -- Counter the graph node rotation to keep the realm upright.
        realmData.islandGraphNode:AddRotation(-realmRotationRadians)
    end
end

function OneTamrielBackground:OnScreenResized()
    self:ResizeSizes()
end

-- Global XML Handlers

function ZO_OneTamrielBackground_OnInitialized(self)
    PREGAME_ANIMATED_BACKGROUND = OneTamrielBackground:New(self)
end