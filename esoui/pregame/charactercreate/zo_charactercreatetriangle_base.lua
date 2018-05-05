ZO_CharacterCreateTriangle_Base = ZO_Object:Subclass()

function ZO_CharacterCreateTriangle_Base:New(...)
    local triangle = ZO_Object.New(self)
    triangle:Initialize(...)
    return triangle
end

function ZO_CharacterCreateTriangle_Base:Initialize(triangleControl, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)
    GetControl(triangleControl, "LabelTop"):SetText(GetString(topStringId))
    GetControl(triangleControl, "LabelLeft"):SetText(GetString(leftStringId))
    GetControl(triangleControl, "LabelRight"):SetText(GetString(rightStringId))

    local pickerControl = GetControl(triangleControl, "Picker")
    self.width, self.height = pickerControl:GetDimensions()

    local picker = ZO_TrianglePicker:New(self.width, self.height, pickerControl:GetParent(), pickerControl)
    local thumb = GetControl(pickerControl, "Thumb")
    thumb:SetDrawLevel(1)
    picker:SetThumb(thumb)
    picker:SetThumbPosition(pickerControl:GetWidth() * 0.5, pickerControl:GetHeight() * 0.67) -- put the thumb in the "center" of the triangle for now.
    picker:SetUpdateCallback(function(picker, x, y) self:SetValue(x, y) end)

    triangleControl.sliderObject = self
    self.control = triangleControl
    self.padlock = GetControl(triangleControl, "Padlock")
    self.thumb = thumb
    self.picker = picker
    self.setterFn = setterFn
    self.updaterFn = updaterFn
    self.lockState = TOGGLE_BUTTON_OPEN

    -- NOTE: This button data may change to be defined by whatever is using the triangle object...for all triangles use the same icon layouts.
    -- NOTE: The coordinates are normalized!!  You can make the window any size and the subtriangles will still be correct.
    -- Liberties have been taken with the normalized values to account for image data (make the buttons appear at the correct junction points)
    self.triangleButtonData =
    {
        { x = 0.5, y = 0, },          -- point 0 (top)
        { x = 0.7455, y = 0.5034, },  -- proceeding clockwise, point 1, etc...
        { x = 1, y = 1, },
        { x = 0.5, y = 1, },
        { x = 0, y = 1, },
        { x = 0.2544, y = 0.5034, },
    }

    -- The picker control is split into 4 sub triangles, the picker defines points in CCW order, but the sub triangles
    -- used by the game are in CW order, so adjust accordingly
    self.subTrianglePoints =
    {
        { 6, 2, 1 },
        { 4, 3, 2 },
        { 6, 2, 4, isMirrored = true }, -- the upside down triangle
        { 5, 4, 6},
    }

    -- Create control points
    local baseName = triangleControl:GetName().."Point"
    local width = pickerControl:GetWidth()
    local height = pickerControl:GetHeight()

    self.subTriangles = {}
    local points = {}

    for i = 1, #self.subTrianglePoints do
        local pointIndices = self.subTrianglePoints[i]
        local isMirrored = pointIndices.isMirrored
        ZO_TrianglePoints_SetPoint(points, 1, self.triangleButtonData[pointIndices[1]], isMirrored)
        ZO_TrianglePoints_SetPoint(points, 2, self.triangleButtonData[pointIndices[2]], isMirrored)
        ZO_TrianglePoints_SetPoint(points, 3, self.triangleButtonData[pointIndices[3]], isMirrored)

        self.subTriangles[i] = ZO_Triangle:New(points, isMirrored)
    end
end

function ZO_CharacterCreateTriangle_Base:ToggleLocked()
    self.lockState = not self.lockState
    ZO_ToggleButton_SetState(self.padlock, self.lockState)

    self:UpdateLockState()
end

function ZO_CharacterCreateTriangle_Base:CanLock()
    return true
end

function ZO_CharacterCreateTriangle_Base:IsLocked()
    return self.lockState ~= TOGGLE_BUTTON_OPEN
end

function ZO_CharacterCreateTriangle_Base:Randomize(randomizeType)
    if self.lockState == TOGGLE_BUTTON_OPEN then
        local triangle = zo_random(1, #self.subTrianglePoints)
        local a = zo_random() * .5
        local b = zo_random() * .5

        self.setterFn(triangle, a, b)
        if self.onValueChangedCallback then
            self.onValueChangedCallback()
        end
        self:Update()
    end
end

function ZO_CharacterCreateTriangle_Base:SetOnValueChangedCallback(onValueChangedCallback)
    self.onValueChangedCallback = onValueChangedCallback
end

local function LengthSquared(x1, y1, x2, y2)
    local x = x2 - x1
    local y = y2 - y1
    return (x * x) + (y * y)
end

-- NOTE: x and y are normalized
function ZO_CharacterCreateTriangle_Base:GetSubTriangle(x, y)
    local closestX
    local closestY
    local closestTri

    for triIndex, triangle in ipairs(self.subTriangles) do
        local cX, cY, isInside = triangle:ContainsPoint(x, y)

        if isInside then
            return triIndex, cX, cY
        end

        if not closestX or (LengthSquared(cX, cY, x, y) < LengthSquared(closestX, closestY, x, y)) then
            closestX = cX
            closestY = cY
            closestTri = triIndex
        end
    end

    return closestTri, closestX, closestY
end

-- NOTE: x and y are normalized
function ZO_CharacterCreateTriangle_Base:GetSubTriangleParams(triIndex, x, y)
    return self.subTriangles[triIndex]:GetTriangleParams(x, y)
end

function ZO_CharacterCreateTriangle_Base:SetValue(x, y)
    x = x / self.width
    y = y / self.height

    local triangleIndex, subPosX, subPosY = self:GetSubTriangle(x, y)
    local setterParamA, setterParamB = self:GetSubTriangleParams(triangleIndex, subPosX, subPosY)

    self.setterFn(triangleIndex, setterParamA, setterParamB)
    if self.onValueChangedCallback then
        self.onValueChangedCallback()
    end
end

function ZO_CharacterCreateTriangle_Base:Update()
    local triIndex, a, b = self.updaterFn()
    local triangle = self.subTriangles[triIndex]

    if triangle then
        local x, y = triangle:PointFromParams(a, b)
        self.picker:SetThumbPosition(self.width * x, self.height * y)
    end
end

function ZO_CharacterCreateTriangle_Base:UpdateLockState()
    -- optional override
end
