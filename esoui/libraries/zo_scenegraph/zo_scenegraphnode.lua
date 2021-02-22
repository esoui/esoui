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
        self.parent:OnChildRemoved(self)
    end
    self.parent = parent
    if self.parent then
        self.parent:OnChildAdded(self)
    end
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

function ZO_SceneGraphNode:GetWorldViewMatrix()
    return self.worldViewMatrix
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

local DRAW_LEVEL_BASE = ZO_ABOVE_SCENEGRAPH_DRAW_LEVEL
local Z_TO_DRAW_LEVEL_FACTOR = 100 -- draw levels are integers, so this is effectively 2 digits of precision
local function ComputeDrawLevel(z)
    return DRAW_LEVEL_BASE - z * Z_TO_DRAW_LEVEL_FACTOR
end

function ZO_SceneGraphNode:Render()
    local customScale = GetUICustomScale()
    local worldViewMatrix : Matrix33 = self.worldViewMatrix
    local cameraPositionZ = self.sceneGraph:GetCameraZ()

    if self.textures then
        for _, textureControl in ipairs(self.textures) do
            local positionZ = textureControl.sceneZ
            local distanceFromCamera = self.finalTranslateZ + positionZ - cameraPositionZ
            if distanceFromCamera > 0 then
                local depthScale = 1 / (distanceFromCamera * customScale)
                local positionX = textureControl.sceneX
                local positionY = textureControl.sceneY

                local finalX, finalY = zo_matrixTransformPoint(worldViewMatrix, positionX, positionY)

                finalX = finalX * depthScale
                finalY = finalY * depthScale

                local anchorPoint = textureControl.sceneAnchorPoint
                textureControl:SetAnchor(anchorPoint, nil, CENTER, finalX, finalY)
                textureControl:SetScale(self.finalScale * depthScale * textureControl.sceneScale)
                textureControl:SetDrawLevel(ComputeDrawLevel(self.finalTranslateZ + positionZ))
                textureControl:SetHidden(textureControl.sceneHidden)

                if self.finalRotation ~= 0 and textureControl.sceneUseRotation then
                    textureControl:SetTextureRotation(self.finalRotation, ANCHOR_TO_NORMALIZED_X[anchorPoint], ANCHOR_TO_NORMALIZED_Y[anchorPoint])
                else
                    textureControl:SetTextureRotation(0)
                end
            else
                textureControl:SetHidden(true)
            end
        end
    end

    if self.composites then
        for _, compositeControl in ipairs(self.composites) do
            local positionZ = compositeControl.sceneZ
            local distanceFromCamera = self.finalTranslateZ + positionZ - cameraPositionZ
            if distanceFromCamera > 0 then
                local depthScale = 1 / (distanceFromCamera * customScale)
                local positionX = compositeControl.sceneX
                local positionY = compositeControl.sceneY

                local finalX, finalY = zo_matrixTransformPoint(worldViewMatrix, positionX, positionY)

                finalX = finalX * depthScale
                finalY = finalY * depthScale

                compositeControl:SetAnchor(compositeControl.sceneAnchorPoint, nil, CENTER, finalX, finalY)
                compositeControl:SetScale(self.finalScale * depthScale * compositeControl.sceneScale)
                compositeControl:SetDrawLevel(ComputeDrawLevel(self.finalTranslateZ + positionZ))
                compositeControl:SetHidden(compositeControl.sceneHidden)
            else
                compositeControl:SetHidden(true)
            end
        end
    end

    if self.lines then
        for _, lineControl in ipairs(self.lines) do
            local distanceFromCamera = self.finalTranslateZ + lineControl.sceneZ - cameraPositionZ
            if distanceFromCamera > 0 then
                local thickness = self.finalScale * lineControl.sceneThickness / distanceFromCamera / customScale
                lineControl:SetThickness(thickness)
                lineControl:SetDrawLevel(ComputeDrawLevel(self.finalTranslateZ + lineControl.sceneZ))
                lineControl:SetHidden(lineControl.sceneHidden)
            else
                lineControl:SetHidden(true)
            end
        end
    end
    self.dirty = false
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
    return inputX + canvasCenterX, inputY + canvasCenterY
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

function ZO_SceneGraphNode:GetWorldSpaceCoordinates(inputPointX, inputPointY, inputPointZ)
    local worldViewMatrix : Matrix33 = self.worldViewMatrix
    local cameraSpaceX, cameraSpaceY = zo_matrixTransformPoint(self.worldViewMatrix, inputPointX, inputPointY)
    local inverseViewMatrix : Matrix33 = self:AcquireWorkingMatrix()
    zo_invertMatrix33(self.sceneGraph:GetCameraNode():GetWorldViewMatrix(), inverseViewMatrix)
    local worldSpaceX, worldSpaceY = zo_matrixTransformPoint(inverseViewMatrix, cameraSpaceX, cameraSpaceY)
    local worldSpaceZ = self.finalTranslateZ + inputPointZ
    return worldSpaceX, worldSpaceY, worldSpaceZ
end

function ZO_SceneGraphNode:OnChildAdded(child)
    if self.children == nil then
        self.children = {}
    end
    table.insert(self.children, child)
end

function ZO_SceneGraphNode:OnChildRemoved(child)
    if self.children then
        ZO_RemoveFirstElementFromNumericallyIndexedTable(self.children, child)
    end
end

function ZO_SceneGraphNode:AddLine(lineControl, startControl, endControl, z)
    if not self.lines then
        self.lines = {}
    end
    table.insert(self.lines, lineControl)

    -- It's assumed that startControl and endControl are part of the
    -- scenegraph. The line is fixed to draw in between those two control points.
    lineControl.sceneZ = z
    lineControl.sceneThickness = lineControl:GetThickness()
    lineControl:ClearAnchors()
    lineControl:SetAnchor(TOPLEFT, startControl, CENTER)
    lineControl:SetAnchor(BOTTOMRIGHT, endControl, CENTER)
    self:SetDirty(true)
end

function ZO_SceneGraphNode:SetLineThickness(lineControl, thickness)
    lineControl.sceneThickness = thickness
    self:SetDirty(true)
end

function ZO_SceneGraphNode:AddTextureComposite(compositeControl, x, y, z)
    if not self.composites then
        self.composites = {}
    end
    table.insert(self.composites, compositeControl)

    compositeControl.sceneX = x
    compositeControl.sceneY = y
    compositeControl.sceneZ = z
    compositeControl.sceneScale = 1
    compositeControl.sceneHidden = false
    compositeControl.sceneAnchorPoint = CENTER
    self:SetDirty(true)
end

function ZO_SceneGraphNode:RemoveTextureComposite(compositeControl)
    ZO_RemoveFirstElementFromNumericallyIndexedTable(self.composites, compositeControl)
end

function ZO_SceneGraphNode:AddTexture(textureControl, x, y, z)
    if not self.textures then
        self.textures = {}
    end
    table.insert(self.textures, textureControl)

    textureControl.sceneX = x
    textureControl.sceneY = y
    textureControl.sceneZ = z
    textureControl.sceneScale = 1
    textureControl.sceneHidden = false
    textureControl.sceneAnchorPoint = CENTER
    textureControl.sceneUseRotation = true
    self:SetDirty(true)
end

function ZO_SceneGraphNode:RemoveTexture(textureControl)
    ZO_RemoveFirstElementFromNumericallyIndexedTable(self.textures, textureControl)
end

function ZO_SceneGraphNode:ClearControls()
    if self.textures then
        ZO_ClearNumericallyIndexedTable(self.textures)
    end

    if self.composites then
        ZO_ClearNumericallyIndexedTable(self.composites)
    end

    if self.lines then
        ZO_ClearNumericallyIndexedTable(self.lines)
    end
end

function ZO_SceneGraphNode:SetControlPosition(control, x, y, z)
    control.sceneX = x
    control.sceneY = y
    control.sceneZ = z
    self:SetDirty(true)
end

function ZO_SceneGraphNode:SetControlHidden(control, hidden)
    if control.sceneHidden ~= hidden then
        control.sceneHidden = hidden
        self:SetDirty(true)
    end
end

function ZO_SceneGraphNode:SetControlScale(control, scale)
    if control.sceneScale ~= scale then
        control.sceneScale = scale
        self:SetDirty(true)
    end
end

function ZO_SceneGraphNode:SetControlAnchorPoint(control, anchorPoint)
    if control.sceneAnchorPoint ~= anchorPoint then
        control.sceneAnchorPoint = anchorPoint
        self:SetDirty(true)
    end
end

function ZO_SceneGraphNode:SetTextureUseRotation(textureControl, useRotation)
    if textureControl.sceneUseRotation ~= useRotation then
        textureControl.sceneUseRotation = useRotation
        self:SetDirty(true)
    end
end