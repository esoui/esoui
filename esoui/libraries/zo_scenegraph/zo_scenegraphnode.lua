ZO_SceneGraphNode = ZO_Object:Subclass()

function ZO_SceneGraphNode:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_SceneGraphNode:InitializeStaticBehavior()
    --called on the class table, not an instance. one event for all scene nodes
    self.UICustomScale = tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_CUSTOM_SCALE))
    EVENT_MANAGER:RegisterForEvent("ZO_SceneGraphNode", EVENT_INTERFACE_SETTING_CHANGED, function(_, settingType, settingId)
        if settingType == SETTING_TYPE_UI and settingId == UI_SETTING_CUSTOM_SCALE then
            self.UICustomScale = tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_CUSTOM_SCALE))
        end
    end)
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

function ZO_SceneGraphNode:ComputeSizeForDepth(x, y, z)
    local scale = 1 + self.translateZ + z
    local parent = self.parent
    while parent do
        scale = scale + parent.translateZ
        parent = parent.parent
    end

    return x * scale, y * scale
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

    if self.controls then
        for i, control in ipairs(self.controls) do
            control:SetDrawLevel(self:ComputeDrawLevel(self.finalTranslateZ + self.controlZ[i]))
        end
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
    if self.controls and #self.controls > 0 then
        for i, control in ipairs(self.controls) do
            local distanceFromCamera = self.finalTranslateZ + self.controlZ[i] - self.sceneGraph:GetCameraZ()
            if distanceFromCamera > 0 then
                local depthScale = 1 / distanceFromCamera
                local positionX = self.controlX[i]
                local positionY = self.controlY[i]
                local worldViewMatrix : Matrix33 = self.worldViewMatrix

                local finalX = worldViewMatrix._11 * positionX + worldViewMatrix._12 * positionY + worldViewMatrix._13
                local finalY = worldViewMatrix._21 * positionX + worldViewMatrix._22 * positionY + worldViewMatrix._23

                finalX = finalX * depthScale
                finalY = finalY * depthScale

                finalX = finalX / self.UICustomScale
                finalY = finalY / self.UICustomScale

                local anchorPoint = self.controlAnchorPoint[i]
                control:SetAnchor(anchorPoint, nil, CENTER, finalX, finalY)
                if self.finalRotation ~= 0 and self.controlUseRotation[i] then
                    control:SetTextureRotation(self.finalRotation, ANCHOR_TO_NORMALIZED_X[anchorPoint], ANCHOR_TO_NORMALIZED_Y[anchorPoint])
                else
                    control:SetTextureRotation(0)
                end
                control:SetScale((self.finalScale * depthScale * self.controlScale[i]) / self.UICustomScale)
                control:SetHidden(self.controlHidden[i])
            else
                control:SetHidden(true)
            end
        end
    end
end

function ZO_SceneGraphNode:OnChildAdded(child)
    if self.children == nil then
        self.children = {}
    end
    table.insert(self.children, child)
end

function ZO_SceneGraphNode:ComputeDrawLevel(z)
    return 10000 - z * 100
end

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
        table.remove(select(i, ...), index)
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
    if self.controlAnchorPoint[index] ~= anchorPoint then
        self.controlUseRotation[index] = useRotation
        self:SetDirty(true)
    end
end

ZO_SceneGraphNode:InitializeStaticBehavior()