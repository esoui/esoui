ZO_SceneGraphNode = ZO_Object:Subclass()

function ZO_SceneGraphNode:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_SceneGraphNode:Initialize(sceneGraph, name)
    self.sceneGraph = sceneGraph
    self.name = name
    self.translateX = 0
    self.translateY = 0
    self.translateZ = 0
    self.rotation = 0
    self.scale = 1
    self.anchorPoint = CENTER
    self:SetDirty(true)
end

function ZO_SceneGraphNode:GetSceneGraph()
    return self.sceneGraph
end

function ZO_SceneGraphNode:GetName()
    return self.name
end

function ZO_SceneGraphNode:SetParent(parent)
    if self.parent then
        self.parent:OnChildRemoved(parent)
    end
    self.parent = parent
    self.parent:OnChildAdded(self)
    self:SetDirty(true)
end

function ZO_SceneGraphNode:GetChildren()
    return self.children
end

function ZO_SceneGraphNode:SetDirty(dirty)
    self.dirty = dirty
    if dirty then
        self.sceneGraph:OnSceneNodeDirty()
    end
end

function ZO_SceneGraphNode:GetX()
    return self.translateX
end

function ZO_SceneGraphNode:AddX(dx)
    self:SetX(self.translateX + dx)
end

function ZO_SceneGraphNode:SetX(x)
    if self.translateX ~= x then
        self.translateX = x
        self:SetDirty(true)
    end
end

function ZO_SceneGraphNode:GetY()
    return self.translateY
end

function ZO_SceneGraphNode:AddY(dy)
    self:SetY(self.translateY + dy)
end

function ZO_SceneGraphNode:SetY(y)
    if self.translateY ~= y then
        self.translateY = y
        self:SetDirty(true)
    end
end

function ZO_SceneGraphNode:GetZ()
    return self.translateZ
end

function ZO_SceneGraphNode:SetZ(z)
    if self.translateZ ~= z then
        self.translateZ = z
        self:SetDirty(true)
    end
end

function ZO_SceneGraphNode:GetRotation()
    return self.rotation
end

function ZO_SceneGraphNode:AddRotation(radians)
    self:SetRotation(self.rotation + radians)
end

function ZO_SceneGraphNode:SetRotation(radians)
    if self.rotation ~= radians then
        self.rotation = radians % (2 * math.pi)
        self:SetDirty(true)
    end
end

function ZO_SceneGraphNode:SetScale(scale)
    if self.scale ~= scale then
        self.scale = scale
        self:SetDirty(true)
    end
end

function ZO_SceneGraphNode:ComputeSizeForDepth(x, y, z, referenceCameraZ)
    local distanceFromCamera = self.translateZ + z
    local parent = self.parent
    while parent do
        distanceFromCamera = distanceFromCamera + parent.translateZ
        parent = parent.parent
    end
    if referenceCameraZ == nil then
        referenceCameraZ = self.sceneGraph:GetCameraZ()
    end
    distanceFromCamera = distanceFromCamera - referenceCameraZ
    local scale = 1
    if distanceFromCamera > 0 then
        scale = 1 / distanceFromCamera
    end

    return x / scale, y / scale
end

function ZO_SceneGraphNode:IsDirty()
    return self.dirty
end

function ZO_SceneGraphNode:AcquireWorkingMatrix()
    if not self.workingMatrix then
       self.workingMatrix = hmake Matrix33 { }
    end
    return self.workingMatrix
end

function ZO_SceneGraphNode:AcquireResultMatrix()
    if not self.resultMatrix then
        self.resultMatrix = hmake Matrix33 { }
    end
    return self.resultMatrix
end

function ZO_SceneGraphNode:BuildWorldViewMatrix()
    local resultMatrix : Matrix33
    self.finalRotation = self.rotation
    self.finalScale = self.scale
    self.finalTranslateZ = self.translateZ

    if self.scale ~= 1 then
        resultMatrix = self:AcquireResultMatrix()
        zo_setToScaleMatrix2D(resultMatrix, self.scale)
    end
    if self.translateX ~= 0 or self.translateY ~= 0 then
        if resultMatrix then
            local workingMatrix : Matrix33 = self:AcquireWorkingMatrix()
            zo_setToTranslationMatrix2D(workingMatrix, self.translateX, self.translateY)
            zo_matrixMultiply33x33(workingMatrix, resultMatrix, resultMatrix)
        else
            resultMatrix = self:AcquireResultMatrix()
            zo_setToTranslationMatrix2D(resultMatrix, self.translateX, self.translateY)
        end
    end
    if self.rotation ~= 0 then
        if resultMatrix then
            local workingMatrix : Matrix33 = self:AcquireWorkingMatrix()
            zo_setToRotationMatrix2D(workingMatrix, self.rotation)
            zo_matrixMultiply33x33(workingMatrix, resultMatrix, resultMatrix)
        else
            resultMatrix = self:AcquireResultMatrix()
            zo_setToRotationMatrix2D(resultMatrix, self.rotation)
        end
    end

    local parent = self.parent
    if parent then
        if resultMatrix then
            zo_matrixMultiply33x33(parent.worldViewMatrix, resultMatrix, resultMatrix)
        else
            resultMatrix = parent.worldViewMatrix
        end
        self.finalRotation = self.finalRotation + parent.finalRotation
        self.finalScale = self.finalScale * parent.finalScale
        self.finalTranslateZ = self.finalTranslateZ + parent.finalTranslateZ
    end

    if resultMatrix then
        self.worldViewMatrix = resultMatrix
    else
        self.worldViewMatrix = self:AcquireResultMatrix()
        zo_setToIdentityMatrix33(self.worldViewMatrix)
    end

end

local ANCHOR_TO_NORMALIZED_X =
{
    [TOPLEFT] = 0,
    [LEFT] = 0,
    [BOTTOMLEFT] = 0,
    [TOP] = 0.5,
    [CENTER] = 0.5,
    [BOTTOM] = 0.5,
    [TOPRIGHT] = 1,
    [RIGHT] = 1,
    [BOTTOMRIGHT] = 1,
}

local ANCHOR_TO_NORMALIZED_Y =
{
    [TOPLEFT] = 0,
    [TOP] = 0,
    [TOPRIGHT] = 0,
    [LEFT] = 0.5,
    [CENTER] = 0.5,
    [RIGHT] = 0.5,
    [BOTTOMLEFT] = 1,
    [BOTTOM] = 1,
    [BOTTOMRIGHT] = 1,
}

function ZO_SceneGraphNode:Render()
    local customScale = GetUICustomScale()
    if self.controls then
        local worldViewMatrix : Matrix33 = self.worldViewMatrix
        for i, control in ipairs(self.controls) do
            local distanceFromCamera = self.finalTranslateZ + self.controlZ[i] - self.sceneGraph:GetCameraZ()
            if distanceFromCamera > 0 then
                local depthScale = 1 / distanceFromCamera
                local positionX = self.controlX[i]
                local positionY = self.controlY[i]

                local finalX, finalY = zo_matrixTransformPoint(worldViewMatrix, positionX, positionY)

                finalX = finalX * depthScale
                finalY = finalY * depthScale

                finalX = finalX / customScale
                finalY = finalY / customScale

                local anchorPoint = self.controlAnchorPoint[i]
                control:SetAnchor(anchorPoint, nil, CENTER, finalX, finalY)
                if self.finalRotation ~= 0 and self.controlUseRotation[i] then
                    control:SetTextureRotation(self.finalRotation, ANCHOR_TO_NORMALIZED_X[anchorPoint], ANCHOR_TO_NORMALIZED_Y[anchorPoint])
                else
                    control:SetTextureRotation(0)
                end
                control:SetScale((self.finalScale * depthScale * self.controlScale[i]) / customScale)
                control:SetDrawLevel(self:ComputeDrawLevel(self.finalTranslateZ + self.controlZ[i]))
                control:SetHidden(self.controlHidden[i])
            else
                control:SetHidden(true)
            end
        end
    end

    if self.lines then
        for _, line in ipairs(self.lines) do
            local distanceFromCamera = self.finalTranslateZ + line.sceneZ - self.sceneGraph:GetCameraZ()
            if distanceFromCamera > 0 then
                local thickness = self.finalScale * line.sceneThickness / distanceFromCamera / customScale
                line:SetThickness(thickness)
                line:SetDrawLevel(self:ComputeDrawLevel(self.finalTranslateZ + line.sceneZ))
            else
                line:SetHidden(true)
            end
        end
    end
end

function ZO_SceneGraphNode:TransformPoint(inputPointX, inputPointY, referencePlaneZ)
    if not self.finalTranslateZ then
        -- waiting for control to be rendered at least once
        return nil
    end
    local distanceFromCamera = self.finalTranslateZ + referencePlaneZ - self.sceneGraph:GetCameraZ()
    if distanceFromCamera <= 0 then
        return nil
    end

    local inputX, inputY = zo_matrixTransformPoint(self.worldViewMatrix, inputPointX, inputPointY)

    local depthScale = 1 / distanceFromCamera
    inputX = inputX * depthScale
    inputY = inputY * depthScale

    local customScale = GetUICustomScale()
    inputX = inputX / customScale
    inputY = inputY / customScale

    local canvasCenterX, canvasCenterY = self.sceneGraph:GetCanvasControl():GetCenter()
    local inputX, inputY = screenPointX + canvasCenterX, screenPointY + canvasCenterY

    return inputX, inputY
end

function ZO_SceneGraphNode:InvertPoint(screenPointX, screenPointY, referencePlaneZ)
    if not self.finalTranslateZ then
        -- waiting for control to be rendered at least once
        return nil
    end
    local distanceFromCamera = self.finalTranslateZ + referencePlaneZ - self.sceneGraph:GetCameraZ()
    if distanceFromCamera <= 0 then
        return nil
    end

    local canvasCenterX, canvasCenterY = self.sceneGraph:GetCanvasControl():GetCenter()
    local inputX, inputY = screenPointX - canvasCenterX, screenPointY - canvasCenterY

    local customScale = GetUICustomScale()
    inputX = inputX * customScale
    inputY = inputY * customScale

    local depthScale = 1 / distanceFromCamera
    inputX = inputX / depthScale
    inputY = inputY / depthScale

    local worldViewMatrix : Matrix33 = self.worldViewMatrix
    local inverseMatrix : Matrix33 = self:AcquireWorkingMatrix()
    zo_invertMatrix33(self.worldViewMatrix, inverseMatrix)

    inputX, inputY = zo_matrixTransformPoint(inverseMatrix, inputX, inputY)
    return inputX, inputY
end

function ZO_SceneGraphNode:OnChildAdded(child)
    if self.children == nil then
        self.children = {}
    end
    table.insert(self.children, child)
end

function ZO_SceneGraphNode:OnChildRemoved(child)
    if self.children then
        local childIndex = ZO_IndexOfElementInNumericallyIndexedTable(self.children, child)
        table.remove(self.children, childIndex)
    end
end

function ZO_SceneGraphNode:ComputeDrawLevel(z)
    return 10000 - z * 100
end

function ZO_SceneGraphNode:AddLine(lineControl, startControl, endControl, z)
    -- It's assumed that startControl and endControl are part of the
    -- scenegraph. The line is fixed to draw in between those two control points.
    lineControl.sceneZ = z
    lineControl.sceneThickness = lineControl:GetThickness()
    lineControl:ClearAnchors()
    lineControl:SetAnchor(TOPLEFT, startControl, CENTER)
    lineControl:SetAnchor(BOTTOMRIGHT, endControl, CENTER)
    if not self.lines then
        self.lines = {}
    end
    table.insert(self.lines, lineControl)
end

-- TODO: rename to AddTexture?
function ZO_SceneGraphNode:AddControl(control, x, y, z)
    if x and y and z then
        if not self.controls then
            self.controls = {}
            self.controlX = {}
            self.controlY = {}
            self.controlZ = {}
            self.controlScale = {}
            self.controlHidden = {}
            self.controlAnchorPoint = {}
            self.controlUseRotation = {}
        end
        table.insert(self.controls, control)
        table.insert(self.controlX, x)
        table.insert(self.controlY, y)
        table.insert(self.controlZ, z)
        table.insert(self.controlScale, 1)
        table.insert(self.controlHidden, false)
        table.insert(self.controlAnchorPoint, CENTER)
        table.insert(self.controlUseRotation, true)
        self:SetDirty(true)
        self:RefreshControlIndices()
    end
end

local function RemoveFromTables(index, ...)
    for i = 1, select("#", ...) do
        local tableToRemoveFrom = select(i, ...)
        local numElements = #tableToRemoveFrom
        tableToRemoveFrom[index] = tableToRemoveFrom[numElements]
        tableToRemoveFrom[numElements] = nil
    end
end

function ZO_SceneGraphNode:RemoveControl(control)
    local controlIndex = self:GetControlIndex(control)
    if controlIndex then
        RemoveFromTables(controlIndex, self.controls, self.controlX, self.controlY, self.controlZ, self.controlScale, self.controlHidden, self.controlAnchorPoint, self.controlUseRotation)
        self:RefreshControlIndices()
    end
end

function ZO_SceneGraphNode:GetControlIndex(control)
    return control.index
end

function ZO_SceneGraphNode:RefreshControlIndices()
    for i, currentControl in ipairs(self.controls) do
        currentControl.index = i
    end
end

function ZO_SceneGraphNode:GetControl(i)
    return self.controls[i]
end

function ZO_SceneGraphNode:SetControlPosition(control, x, y, z)
    local index = self:GetControlIndex(control)
    self.controlX[index] = x
    self.controlY[index] = y
    self.controlZ[index] = z
    self:SetDirty(true)
end

function ZO_SceneGraphNode:SetControlHidden(control, hidden)
    local index = self:GetControlIndex(control)
    if self.controlHidden[index] ~= hidden then
        self.controlHidden[index] = hidden
        self:SetDirty(true)
    end
end

function ZO_SceneGraphNode:SetControlScale(control, scale)
    local index = self:GetControlIndex(control)
    if self.controlScale[index] ~= scale then
        self.controlScale[index] = scale
        self:SetDirty(true)
    end
end

function ZO_SceneGraphNode:GetControlScale(control, scale)
    local index = self:GetControlIndex(control)
    return self.controlScale[index]
end

function ZO_SceneGraphNode:SetControlAnchorPoint(control, anchorPoint)
    local index = self:GetControlIndex(control)
    if self.controlAnchorPoint[index] ~= anchorPoint then
        self.controlAnchorPoint[index] = anchorPoint
        self:SetDirty(true)
    end
end

function ZO_SceneGraphNode:SetControlUseRotation(control, useRotation)
    local index = self:GetControlIndex(control)
    if self.controlUseRotation[index] ~= useRotation then
        self.controlUseRotation[index] = useRotation
        self:SetDirty(true)
    end
end