ZO_SceneGraph = ZO_Object:Subclass()

function ZO_SceneGraph:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_SceneGraph:Initialize(canvasControl, debugModeEnabled)
    self.nodes = {}
    self.canvasControl = canvasControl
    canvasControl:SetHandler("OnUpdate", function() self:OnUpdate() end)
    self.debugModeEnabled = debugModeEnabled
    self.debugTextureId = 1
    self.dirty = false
    self.cameraNode = self:CreateNode("camera")
    self.cameraZ = -1
end

function ZO_SceneGraph:IsHidden()
    return self.canvasControl:IsHidden()
end

function ZO_SceneGraph:GetCameraX()
    return -self.cameraNode:GetX()
end

function ZO_SceneGraph:AddCameraX(dx)
    self.cameraNode:AddX(-dx)
end

function ZO_SceneGraph:SetCameraX(x)
    self.cameraNode:SetX(-x)
end

function ZO_SceneGraph:GetCameraY()
    return -self.cameraNode:GetY()
end

function ZO_SceneGraph:AddCameraY(dy)
    self.cameraNode:AddY(-dy)
end

function ZO_SceneGraph:SetCameraY(y)
    self.cameraNode:SetY(-y)
end

function ZO_SceneGraph:AddCameraRotation(radians)
    self.cameraNode:AddRotation(-radians)
end

function ZO_SceneGraph:SetCameraRotation(radians)
    self.cameraNode:SetRotation(-radians)
end

function ZO_SceneGraph:GetCameraZ()
    return self.cameraZ
end

function ZO_SceneGraph:AddCameraZ(z)
    self:SetCameraZ(self.cameraZ + z)
end

function ZO_SceneGraph:SetCameraZ(z)
    if self.cameraZ ~= z then
        self.cameraZ = z
        self.cameraNode:SetDirty(true)
    end
end

function ZO_SceneGraph:GetCameraNode()
    return self.cameraNode
end

function ZO_SceneGraph:GetCanvasControl()
    return self.canvasControl
end

function ZO_SceneGraph:GetNode(name)
    return self.nodes[name]
end

function ZO_SceneGraph:CreateNode(name)
    local node = ZO_SceneGraphNode:New(self, name)

    if(self.debugModeEnabled) then
        local debugTexture = GetWindowManager():CreateControl(string.format("%sDebugTexture%d", self.canvasControl:GetName(), self.debugTextureId), self.canvasControl, CT_TEXTURE)
        self.debugTextureId = self.debugTextureId + 1
        debugTexture:SetDimensions(20, 20)
        debugTexture:SetColor(0.7, 0.7, 1, 1)
        debugTexture:SetPixelRoundingEnabled(false)
        node:AddControl(debugTexture, 0, 0, 0)
    end

    self.nodes[name] = node

    return node
end

function ZO_SceneGraph:OnSceneNodeDirty()
    self.dirty = true
end

function ZO_SceneGraph:OnUpdate()
    if self.dirty then
        self.dirty = false
        self:Render()
    end
end

function ZO_SceneGraph:Render(node, dirtyUpstream)
    if node == nil then
        node = self.cameraNode
    end

    local dirty = node:IsDirty()
    if dirty or dirtyUpstream then
        node:BuildWorldViewMatrix()
        node:Render()
    end

    local children = node:GetChildren()
    if children ~= nil then
        for i = 1, #children do
            local child = children[i]
            self:Render(child, dirty or dirtyUpstream)
        end
    end
end