ZO_ScryingGoal = ZO_Object:Subclass()

function ZO_ScryingGoal:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ScryingGoal:Initialize(pool)
    self.control = ZO_ObjectPool_CreateControl("ZO_ScryingGoal", pool, GuiRoot)

    self.unownedLoop = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ScryingGoal_UnownedFlipbook", self.control)
    self.ownedLoop = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ScryingGoal_OwnedFlipbook", self.control)
    self.activateAnim = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_ScryingGoal_ActivateFlipbook", self.control)
    self.activateAnim:SetHandler("OnPlay", function()
        SCRYING_HEX_ANIMATION_PROVIDER:AddBlockingGoal()
    end)
    self.activateAnim:SetHandler("OnStop", function(_, completedPlaying)
        if completedPlaying then
            self:SetState(ZO_SCRYING_GOAL_STATE_OWNED)
        end
        SCRYING_HEX_ANIMATION_PROVIDER:RemoveBlockingGoal()
    end)

    self:SetState(ZO_SCRYING_GOAL_STATE_NONE)
end

ZO_SCRYING_GOAL_TEXTURE_WIDTH = 512
ZO_SCRYING_GOAL_TEXTURE_HEIGHT = 512
function ZO_ScryingGoal:SetHex(hex)
    local hexControl = hex:GetControl()
    self.control:SetParent(hexControl)
    self.control:ClearAnchors()
    self.control:SetAnchor(CENTER, hexControl, CENTER, 0, 0)

    local hexWidth, hexHeight = hex:GetParentBoard():GetHexDimensions()
    local goalWidth = hexWidth * (ZO_SCRYING_GOAL_TEXTURE_WIDTH / ZO_SCRYING_HEX_TEXTURE_WIDTH)
    local goalHeight = hexHeight * (ZO_SCRYING_GOAL_TEXTURE_HEIGHT / ZO_SCRYING_HEX_TEXTURE_HEIGHT)
    self.control:SetDimensions(goalWidth, goalHeight)
    self.control:SetHidden(false)
end

ZO_SCRYING_GOAL_STATE_NONE = 0
ZO_SCRYING_GOAL_STATE_UNOWNED = 1
ZO_SCRYING_GOAL_STATE_PREVIOUSLY_OWNED = 2
ZO_SCRYING_GOAL_STATE_OWNING = 3
ZO_SCRYING_GOAL_STATE_OWNED = 4
function ZO_ScryingGoal:SetState(state)
    if state ~= self.state then
        self.state = state
        if self.currentAnimation then
            self.currentAnimation:Stop()
        end

        if state == ZO_SCRYING_GOAL_STATE_NONE then
            self.currentAnimation = nil
        elseif state == ZO_SCRYING_GOAL_STATE_UNOWNED or state == ZO_SCRYING_GOAL_STATE_PREVIOUSLY_OWNED then
            self.control:SetTexture("EsoUI/Art/Scrying/goal_idle_flipbook.dds")
            self.currentAnimation = self.unownedLoop
            self.currentAnimation:PlayFromStart()
        elseif state == SO_SCRYING_GOAL_STATE_OWNING then
            self.control:SetTexture("EsoUI/Art/Scrying/goal_activate_flipbook.dds")
            self.currentAnimation = self.activateAnim
            self.currentAnimation:PlayFromStart()
            PlaySound(SOUNDS.SCRYING_CAPTURE_GOAL)
        elseif state == ZO_SCRYING_GOAL_STATE_OWNED then
            self.control:SetTexture("EsoUI/Art/Scrying/goal_owned_flipbook.dds")
            self.currentAnimation = self.ownedLoop
            self.currentAnimation:PlayFromStart()
        end
    end
end

function ZO_ScryingGoal:Reset()
    ZO_ObjectPool_DefaultResetControl(self.control)
    self:SetState(ZO_SCRYING_GOAL_STATE_NONE)
end

--[[
    A Scrying island represents a contiguous block of hexes.
]]--
ZO_ScryingIsland = ZO_Object:Subclass()

function ZO_ScryingIsland:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_ScryingIsland:Initialize(board, control, areHexesEdgePredicate)
    self.board = board
    self.control = control
    self.areHexesEdgePredicate = areHexesEdgePredicate
    self.points = {}

    self.control.islandObject = self
end

function ZO_ScryingIsland:GetControl()
    return self.control
end

do
    -- Angle indexes go from 0-5 inclusive, to make the math operations they're used in simpler
    local CLOCKWISE_NEIGHBORS =
    {
        [0] = {-2, 0},
        {-1, 1},
        {1, 1},
        {2, 0},
        {1, -1},
        {-1, -1},
    }
    local EDGE_POINT_ANGLE_FOR_NEIGHBOR =
    {
        [0] = 240,
        300,
        0,
        60,
        120,
        180,
    }

    local function InvertAngleIndex(angleIndex)
        return (angleIndex - 3) % 6
    end

    local function WrapAngleIndex(angleIndex)
        return angleIndex % 6
    end

    local function GetClockwiseNeighborOffsets(angleIndex)
        return unpack(CLOCKWISE_NEIGHBORS[angleIndex % 6])
    end

    local function AngleIndexToAngleDegrees(angleIndex)
        return EDGE_POINT_ANGLE_FOR_NEIGHBOR[angleIndex % 6]
    end

    function ZO_ScryingIsland:FindEdge(startHex, lastAngleIndex)
        local startRow, startColumn = startHex:GetCoordinates()
        local startAngleIndex = InvertAngleIndex(lastAngleIndex)
        for angleIndex = startAngleIndex + 2, startAngleIndex + 6 do
            local lastOffsetRow, lastOffsetColumn = GetClockwiseNeighborOffsets(angleIndex - 1)
            local lastRow, lastColumn = startRow + lastOffsetRow, startColumn + lastOffsetColumn
            local lastHex = self.board:GetHex(lastRow, lastColumn)

            local testOffsetRow, testOffsetColumn = GetClockwiseNeighborOffsets(angleIndex)
            local testRow, testColumn = startRow + testOffsetRow, startColumn + testOffsetColumn
            local testHex = self.board:GetHex(testRow, testColumn)

            if self.areHexesEdgePredicate(lastHex, testHex) then
                -- Edge found: report out the node it connects to and its angle from the current node
                return testHex, WrapAngleIndex(angleIndex)
            end
        end

        -- if we are here we found no edge continuations (probably island with only one tile)
        return nil, nil
    end

    function ZO_ScryingIsland:GeneratePolygonFromIsland()
        self.control:ClearPoints()

        local hexWidth, hexHeight = self.board:GetHexDimensions()
        local boardWidth, boardHeight = self.control:GetDimensions()
        for _, point in ipairs(self.points) do
            local hex, angleIndex = unpack(point)
            -- step one, get point for angle
            local normalizedX, normalizedY = ZO_Scrying_CalculateHexPoint(AngleIndexToAngleDegrees(angleIndex))

            -- step two, scale/offset to position relative to board
            local boardPositionX, boardPositionY = self.board:ConvertHexCoordinateToOffset(hex:GetCoordinates())
            boardPositionX = boardPositionX + (normalizedX - 0.5) * hexWidth
            boardPositionY = boardPositionY + (normalizedY - 0.5) * hexHeight

            -- step three, normalize to boardsize
            local normalizedBoardX, normalizedBoardY = boardPositionX / boardWidth, boardPositionY / boardHeight

            -- step four, reanchor to bottom center of board
            normalizedBoardX = normalizedBoardX + 0.5
            normalizedBoardY = normalizedBoardY + 1.0

            self.control:AddPoint(normalizedBoardX, normalizedBoardY)
        end
    end

    function ZO_ScryingIsland:GenerateIslandPoints(startHex)
        ZO_ClearNumericallyIndexedTable(self.points)
        -- initial angle index, so we always test the tile just above us first
        -- For this to generate an outer edge, the initial tile should _always_ be at the top of our given island.
        -- We can also set our initial tile to just below an interior hole to generate an inner edge around the hole: not currently used, but interesting
        local START_ANGLE = 2

        --[[
            Store the first edge so we can detect cycles.
            This must be an edge and not just the tile we started on to
            handle the situation where the same tile provides multiple
            edges.

            Imagine a blob that looks like so

               _   _
             _/ \_/ \_
            / \_/X\_/ \
            \_/ \_/ \_/
              \_/ \_/

            the only thing connecting left and right halves is the one tile
            bridge marked with X. To complete the loop, this tile would need to
            be traversed twice: once to provide an edge going right, and once to
            provide an edge going left. We can only say the loop is repeating
            when we try to go right on the tile twice, or left on that tile
            twice.
        ]]--
        local hex, angleIndex = self:FindEdge(startHex, START_ANGLE)
        local firstEdgeHex, firstAngleIndex = hex, angleIndex
        if hex == nil then
            -- we are an island of a single tile
            for pointAngleIndex = 0, 5 do
                table.insert(self.points, {startHex, pointAngleIndex})
            end
            return
        end

        local iterations = 0
        -- repeat until we've looped around to where we started
        repeat
            local lastHex, lastAngleIndex = hex, angleIndex
            hex, angleIndex = self:FindEdge(hex, angleIndex)
            if not internalassert(hex, "Edge not found") then
                ZO_ClearNumericallyIndexedTable(self.points)
                return
            end

            -- go clockwise from:
            -- the point where lastHex and the hex before it met
            -- The point where lastHex and currentHex meet
            local startAngleIndex = InvertAngleIndex(lastAngleIndex)
            local endAngleIndex = angleIndex
            if endAngleIndex <= startAngleIndex then
                -- denormalize, The start angle must before the angle to ensure a clockwise order
                startAngleIndex = startAngleIndex - 6
            end

            for pointAngleIndex = startAngleIndex + 2, endAngleIndex do
                table.insert(self.points, {lastHex, pointAngleIndex})
            end

            iterations = iterations + 1
            if iterations > 1000 then
                internalassert(false, "too many iterations: potential loop")
                ZO_ClearNumericallyIndexedTable(self.points)
                return
            end
        until hex == firstEdgeHex and angleIndex == firstAngleIndex
    end

    function ZO_ScryingIsland:GenerateIsland(startHex)
        self:GenerateIslandPoints(startHex)
        self:GeneratePolygonFromIsland()
    end
end

--[[
    Utility object for constructing outlines around affected/selected hexes
]]--
ZO_ScryingBorderIsland = ZO_ScryingIsland:Subclass()

function ZO_ScryingBorderIsland:New(...)
    return ZO_ScryingIsland.New(self, ...)
end

function ZO_ScryingBorderIsland:Initialize(pool)
    local board = internalassert(SCRYING:GetScryingBoard(), "Missing scrying board object: maybe initializing an island too early?")
    local control = ZO_ObjectPool_CreateControl("ZO_ScryingBorderOutline", pool, board:GetControl())

    local function IsBorderEdge(lastHex, testHex)
        local lastBorder = lastHex and lastHex:GetBorderType()
        local testBorder = testHex and testHex:GetBorderType()

        return lastBorder ~= testBorder and testBorder == self.targetBorderType
    end
    ZO_ScryingIsland.Initialize(self, board, control, IsBorderEdge)
end

-- Override
function ZO_ScryingBorderIsland:GenerateIsland(startHex)
    self.control:SetHidden(false)
    self:SetTargetBorderType(startHex:GetBorderType())

    ZO_ScryingIsland.GenerateIsland(self, startHex)
end

ZO_AFFECTED_HEX_BORDER_PIXELS = "10px"
ZO_TARGETED_HEX_BORDER_PIXELS = "4px"
ZO_NOT_SELECTED_HEX_BORDER_PIXELS = "2px"
function ZO_ScryingBorderIsland:SetTargetBorderType(borderType)
    self.targetBorderType = borderType
    if borderType == ZO_SCRYING_HEX_BORDER_AFFECTED then
        self.control:SetBorderThickness(ZO_AFFECTED_HEX_BORDER_PIXELS, ZO_AFFECTED_HEX_BORDER_PIXELS, 0)
    elseif borderType == ZO_SCRYING_HEX_BORDER_TARGETED then
        self.control:SetBorderThickness(ZO_TARGETED_HEX_BORDER_PIXELS, ZO_TARGETED_HEX_BORDER_PIXELS, 0)
    end
end

function ZO_ScryingBorderIsland:Reset()
    ZO_ObjectPool_DefaultResetControl(self.control)
end

--[[
    A global singleton object used for holding scrying visual resources
]]--
ZO_ScryingHexAnimationProvider = ZO_CallbackObject:Subclass()

function ZO_ScryingHexAnimationProvider:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_ScryingHexAnimationProvider:Initialize()
    self.idleAnimationPool = ZO_AnimationPool:New("ZO_ScryingHex_Idle")
    self.flashAnimationPool = ZO_AnimationPool:New("ZO_ScryingHex_Flash")
    self.goalPool = ZO_ObjectPool:New(ZO_ScryingGoal, ZO_ObjectPool_DefaultResetObject)
    self.numBlockingGoals = 0
    self.borderIslandPool = ZO_ObjectPool:New(ZO_ScryingBorderIsland, ZO_ObjectPool_DefaultResetObject)
end

function ZO_ScryingHexAnimationProvider:ReleaseAllAnimations()
    self.idleAnimationPool:ReleaseAllObjects()
    self.flashAnimationPool:ReleaseAllObjects()
    self.goalPool:ReleaseAllObjects()
end

function ZO_ScryingHexAnimationProvider:AcquireIdleAnimation(hex)
    local timeline, timelineKey = self.idleAnimationPool:AcquireObject()
    timeline:ApplyAllAnimationsToControl(hex:GetControl())

    return timeline, timelineKey
end

ZO_SCROLLING_BACKGROUND_TEXTURE_WIDTH = 512
ZO_SCROLLING_BACKGROUND_TEXTURE_HEIGHT = 512
-- NOTE: to loop correctly, texture deltas should be whole numbers. This means that each parameter should be read as "this texture will scroll N times over this period"
local HEX_IDLE_ANIMATIONS =
{
    -- TODO: fill this out
    [SCRYING_HEX_TYPE_ONE]   = { slideDeltas = {{5, 0}, {5, 2}}, periodMS = 500000 },
    [SCRYING_HEX_TYPE_TWO]   = { slideDeltas = {{0, -5}, {-5, -2}}, periodMS = 500000 },
    [SCRYING_HEX_TYPE_THREE] = { slideDeltas = {{-5, 0}, {-5, -2}}, periodMS = 500000 },
    [SCRYING_HEX_TYPE_FOUR]  = { slideDeltas = {{-5, 0}, {5, -2}}, periodMS = 500000 },
    [SCRYING_HEX_TYPE_FIVE]  = { slideDeltas = {{5, 0}, {-5, 2}}, periodMS = 500000 },
    [SCRYING_HEX_TYPE_SIX]   = { slideDeltas = {{-5, 0}, {-5, 2}}, periodMS = 500000 },
    [SCRYING_HEX_TYPE_SEVEN] = { slideDeltas = {{0, 5}, {5, -2}}, periodMS = 500000 },
    [SCRYING_HEX_TYPE_EIGHT] = { slideDeltas = {{0, 5}, {5, 2}}, periodMS = 500000 },
    [SCRYING_HEX_TYPE_OWNED] = { slideDeltas = {{0, -5}, {-5, -2}}, periodMS = 500000 },
    [SCRYING_HEX_TYPE_GOAL]  = { slideDeltas = {{0, -5}, {-5, 2}}, periodMS = 500000 },
}
function ZO_ScryingHexAnimationProvider:UpdateIdleAnimationParams(timeline, hex)
    local left, right, top, bottom = hex:GetGridRect()
    left = left / ZO_SCROLLING_BACKGROUND_TEXTURE_WIDTH
    right = right / ZO_SCROLLING_BACKGROUND_TEXTURE_WIDTH
    top = top / ZO_SCROLLING_BACKGROUND_TEXTURE_HEIGHT
    bottom = bottom / ZO_SCROLLING_BACKGROUND_TEXTURE_HEIGHT

    local animationData = HEX_IDLE_ANIMATIONS[hex:GetHexType()]

    for animationIndex, slideDelta in ipairs(animationData.slideDeltas) do
        local animation = timeline:GetAnimation(animationIndex)
        -- apply some texture offset so there's never a point where the two textures have the same coordinates
        local offsetU, offsetV = (animationIndex - 1) * .3, (animationIndex - 1) * .2
        local distanceU, distanceV = unpack(slideDelta)
        animation:SetBaseTextureCoords(left + offsetU, right + offsetU, top + offsetV, bottom + offsetV)
        animation:SetSlideDistances(distanceU, distanceV)
        animation:SetDuration(animationData.periodMS)
    end
end

function ZO_ScryingHexAnimationProvider:PlayFlashAnimation(hex, initialDelayMS)
    local flashAnimation, flashAnimationKey = self.flashAnimationPool:AcquireObject()
    flashAnimation:ApplyAllAnimationsToControl(hex:GetControl())

    flashAnimation:GetFirstAnimation():SetHandler("OnStop", hex:GetRefreshTypeCallback())
    flashAnimation:SetHandler("OnStop", function()
        self.flashAnimationPool:ReleaseObject(flashAnimationKey)
        self:OnBlockingAnimationStopped()
    end)

    -- Play all animations in sequence, with delay
    local timelineDuration = initialDelayMS
    for i = 1, flashAnimation:GetNumAnimations() do
        local animation = flashAnimation:GetAnimation(i)
        local animationDuration = animation:GetDuration()
        flashAnimation:SetAnimationOffset(animation, timelineDuration)
        timelineDuration = timelineDuration + animationDuration
    end
    flashAnimation:PlayFromStart()
end

function ZO_ScryingHexAnimationProvider:AcquireGoal()
    return self.goalPool:AcquireObject()
end

function ZO_ScryingHexAnimationProvider:ReleaseBorderHexIslands()
    self.borderIslandPool:ReleaseAllObjects()
end

function ZO_ScryingHexAnimationProvider:TraceBorderHexIsland(topBorderHex)
    local island = self.borderIslandPool:AcquireObject()
    island:GenerateIsland(topBorderHex)
end

function ZO_ScryingHexAnimationProvider:AddBlockingGoal()
    self.numBlockingGoals = self.numBlockingGoals + 1
end

function ZO_ScryingHexAnimationProvider:RemoveBlockingGoal()
    -- delay end to give the idle animation a bit of time to play
    local DELAY_MS = 500
    zo_callLater(function()
        self.numBlockingGoals = self.numBlockingGoals - 1
        self:OnBlockingAnimationStopped()
    end, DELAY_MS)
end

function ZO_ScryingHexAnimationProvider:AreBlockingAnimationsPlaying()
    return self.numBlockingGoals > 0 or self.flashAnimationPool:HasActiveObjects()
end

function ZO_ScryingHexAnimationProvider:OnBlockingAnimationStopped()
    if not self:AreBlockingAnimationsPlaying() then
        self:FireCallbacks("BlockingAnimationsCompleted")
    end
end

SCRYING_HEX_ANIMATION_PROVIDER = ZO_ScryingHexAnimationProvider:New()
