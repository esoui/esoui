function ZO_TrianglePoints_SetPoint(points, index, p, isMirrored)
    -- Use of isMirrored assumes normalized points.  Might add support for non-normalized points later
    if(index == 3 and isMirrored) then
        points[index] = { x = p.x, y = 1 - p.y }
    else
        points[index] = { x = p.x, y = p.y }
    end
end

local function Dot(x1, y1, x2, y2)
    return x1 * x2 + y1 * y2
end

local sqrt = math.sqrt

local function Length(x, y)
    return sqrt((x * x) + (y * y))
end

local function Normalize(x, y, length)
    local length = length or Length(x, y)
    return x / length, y / length
end

--[[ ZO_Triangle: 
    A simple collection of 3 verts that allows point testing to determine if a user-supplied point is inside or outside
    the triangle and facilities to clamp a user-supplied point to the nearest edge.
--]]

ZO_Triangle = ZO_Object:Subclass()

function ZO_Triangle:New(points, isMirrored)
    local triangle = ZO_Object.New(self)

    triangle:SetPoints(points)
    triangle.m_isMirrored = isMirrored
    return triangle
end

function ZO_Triangle:SetPoints(points)
    -- Points are defined in CCW order starting at lower left
    self.m_points = ZO_DeepTableCopy(points)
end

function ZO_Triangle:GetPoint(pointIndex)
    return self.m_points[pointIndex]
end

function ZO_Triangle:GetPreviousPoint(pointIndex)
    return pointIndex == 1 and self.m_points[3] or self.m_points[pointIndex - 1]
end

function ZO_Triangle:GetClosestPointOnTriangle(x, y)
    local minDist = nil
    local closestX, closestY

    for i=1, 3 do
        local currentPoint = self:GetPoint(i)
        local lastPoint = self:GetPreviousPoint(i)
        local edgeX, edgeY = currentPoint.x - lastPoint.x, currentPoint.y - lastPoint.y
        local edgeLength = Dot(edgeX, edgeY, edgeX, edgeY)
        local edgeNormalX, edgeNormalY = -edgeY, edgeX
        local differenceX, differenceY = x - lastPoint.x, y - lastPoint.y

        if Dot(differenceX, differenceY, edgeNormalX, edgeNormalY) > 0 then
            local edgeProjection = zo_clamp(Dot(differenceX, differenceY, edgeX, edgeY) / edgeLength, 0.0, 1.0)

            local pointOnEdgeX, pointOnEdgeY = lastPoint.x + (edgeX * edgeProjection), lastPoint.y + (edgeY * edgeProjection)

            local diffToEdgeX, diffToEdgeY = pointOnEdgeX - x, pointOnEdgeY - y
            local diffToEdgeLength = Dot(diffToEdgeX, diffToEdgeY, diffToEdgeX, diffToEdgeY)

            if not minDist or diffToEdgeLength < minDist then
                minDist = diffToEdgeLength
                closestX = pointOnEdgeX
                closestY = pointOnEdgeY
            end
        end
    end

    if minDist then
        --Outside
        return closestX, closestY, false
    end
    
    --Inside
    return x, y, true
end

function ZO_Triangle:ContainsPoint(x, y)
    if(self.m_isMirrored) then
        y = 1 - y
    end

    return self:GetClosestPointOnTriangle(x, y)
end

function ZO_Triangle:GetTriangleParams(x, y)
    local vTop = self:GetPoint(3)
    local vLeft = self:GetPoint(1)
    local vRight = self:GetPoint(2)

    local userX = x - vTop.x
    local userY = y - vTop.y
    local rX = vRight.x - vTop.x
    local rY = vRight.y - vTop.y
    local lX = vLeft.x - vTop.x
    local lY = vLeft.y - vTop.y

    local b = (userY * rX - userX * rY) / (lY * rX - lX * rY)
    local a = (userX - b * lX) / rX

    if(self.m_isMirrored) then
        a, b = b, a
    end
    
    if(a < 0) then
        a = zo_abs(a)
        b = b + a
    elseif(b < 0) then
        b = zo_abs(b)
        a = a + b
    end

    return a, b
end

function ZO_Triangle:PointFromParams(a, b)
    if(self.m_isMirrored) then
        a, b = b, a
    end

    local vTop = self:GetPoint(3)
    local xTop, yTop = vTop.x, vTop.y

    local vLeft = self:GetPoint(1)
    local xLeft, yLeft = vLeft.x, vLeft.y

    local vRight = self:GetPoint(2)
    local xRight, yRight = vRight.x, vRight.y

    local x = xTop + (xRight - xTop) * a + (xLeft - xTop) * b
    local y = yTop + (yRight - yTop) * a + (yLeft - yTop) * b

    if(self.m_isMirrored) then
        y = 1 - y
    end

    return x, y        
end

--[[ ZO_TrianglePicker:
    Wraps a single triangle object and a gui control so that a thumb button can be positioned within the triangle
--]]

ZO_TrianglePicker = ZO_Object:Subclass()

function ZO_TrianglePicker:New(...)
    local picker = ZO_Object.New(self)
    picker:Initialize(...)
    return picker
end

do
    local currentPickerId = 0
    function ZO_TrianglePicker:Initialize(width, height, parent, control)
        self.width = width or 128
        self.height = height or 128
        self.enabled = true

        if(control) then
            self.control = control
        else
            currentPickerId = currentPickerId + 1
            self.control = CreateControlFromVirtual("ZO_TrianglePickerControl", parent or GuiRoot, "ZO_TrianglePickerTemplate", currentPickerId)
        end

        self.control.owner = self

        self:UpdateTriangle()
    end
end

function ZO_TrianglePicker:UpdateTriangle()
    self.control:SetDimensions(self.width, self.height)

    local points = {
        { x = 0, y = self.height },
        { x = self.width, y = self.height },
        { x = self.width / 2, y = 0 },
    }

    if(self.triangle) then 
        self.triangle:SetPoints(points)
    else
        self.triangle = ZO_Triangle:New(points)
    end
end

function ZO_TrianglePicker:SetThumb(control)
    self.thumb = control
end

function ZO_TrianglePicker:SetEnabled(enabled)
    if(enabled ~= self.enabled) then
        self.enabled = enabled
        self:OnMouseUp()

        local thumb = self.thumb
        if(thumb) then
            if(enabled) then
                thumb:SetState(BSTATE_NORMAL, false)
            else
                thumb:SetState(BSTATE_DISABLED, true)
            end
        end
    end
end

function ZO_TrianglePicker:SetUpdateCallback(callback)
    self.updateCallback = callback
end

function ZO_TrianglePicker:GetControl()
    return self.control
end

local function SetThumbAnchor(thumb, anchorTo, x, y)
    if(thumb) then
        thumb:ClearAnchors()
        thumb:SetAnchor(CENTER, anchorTo, TOPLEFT, x, y)
    end
end

function ZO_TrianglePicker:GetThumbPosition() --In local control space
    return self.lastX, self.lastY
end

function ZO_TrianglePicker:SetThumbPosition(x, y) -- In local control space
    self.lastX, self.lastY = self.triangle:GetClosestPointOnTriangle(x, y)
    SetThumbAnchor(self.thumb, self.control, self.lastX, self.lastY)
end

local function GetControlSpaceCoordinates(control, x, y)
    local scale = control:GetScale()
    return (x - control:GetLeft()) / scale, (y - control:GetTop()) / scale
end

function ZO_TrianglePicker:OnUpdate()
    local x, y = GetControlSpaceCoordinates(self.control, GetUIMousePosition())
    local closestPointX, closestPointY, isInside = self.triangle:GetClosestPointOnTriangle(x, y)

    self.isInside = isInside

    if(isInside or self.thumbMoving) then
        WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_UI_HAND)
    else
        WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
    end

    if(self.thumbMoving) then
        local lastX, lastY = self.lastX, self.lastY

        if(lastX ~= closestPointX or lastY ~= closestPointY) then
            SetThumbAnchor(self.thumb, self.control, closestPointX, closestPointY)

            if(self.updateCallback) then
                self.updateCallback(self, closestPointX, closestPointY)
            end
        end
    
        self.lastX, self.lastY = closestPointX, closestPointY
    end
end

function ZO_TrianglePicker:SetThumbMoving(moving)
    self.thumbMoving = moving
end

function ZO_TrianglePicker:SetUpdateHandlerEnabled(enableUpdates)
    if(enableUpdates) then
        if(not self.control:GetHandler("OnUpdate")) then
            self.onUpdateFunction = self.onUpdateFunction or function()
                self:OnUpdate()
            end

            self.control:SetHandler("OnUpdate", self.onUpdateFunction)
        end
    else
        self.control:SetHandler("OnUpdate", nil)
    end
end

function ZO_TrianglePicker:OnMouseDown()
    if(not self.enabled) then return end

    if(self.isInside) then    
        self:SetThumbMoving(true)
        self:SetUpdateHandlerEnabled(true)
        PlaySound(SOUNDS.DEFAULT_CLICK)
    end
end

function ZO_TrianglePicker:OnMouseUp()
    if(not self.enabled) then
        WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
        PlaySound(SOUNDS.DEFAULT_CLICK)
        return
    end

    self:SetThumbMoving(false)
    
    if(not self.isInside) then
        WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
    end
    PlaySound(SOUNDS.DEFAULT_CLICK)
    -- Ok, the mouse wasn't over the actual triangle, but we may need to keep running the 
    -- update handler because it's still over the control...
    self:SetUpdateHandlerEnabled(WINDOW_MANAGER:GetMouseOverControl() == self.control)
end

function ZO_TrianglePicker:OnMouseEnter()
    if(not self.enabled) then return end

    self:SetUpdateHandlerEnabled(true)
end

function ZO_TrianglePicker:OnMouseExit()
    if(not self.enabled) then return end

    if(not self.thumbMoving) then
        self:SetUpdateHandlerEnabled(false)
        WINDOW_MANAGER:SetMouseCursor(MOUSE_CURSOR_DO_NOT_CARE)
    end
end

--[[ XML Handlers ]]--

function ZO_TrianglePicker_OnMouseDown(control)
    control.owner:OnMouseDown()
end

function ZO_TrianglePicker_OnMouseUp(control)
    control.owner:OnMouseUp()
end

function ZO_TrianglePicker_OnMouseEnter(control)
    control.owner:OnMouseEnter()
end

function ZO_TrianglePicker_OnMouseExit(control)
    control.owner:OnMouseExit()
end