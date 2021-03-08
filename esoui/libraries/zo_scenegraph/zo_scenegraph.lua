ZO_ABOVE_SCENEGRAPH_DRAW_LEVEL = 100000

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
    self.needsRender = false
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

    if self.debugModeEnabled then
        self:AddDebugTextureToNode(node)
    end

    self.nodes[name] = node

    return node
end

function ZO_SceneGraph:RemoveNode(node)
    -- after this point, this node will no longer participate in rendering, the node should eventually be garbage collected.
    -- it's important that you nil out references in application code too to achieve this.
    -- child controls do not hold references to their scene node, so they will
    -- also become "free-floating". Likewise, it's your responsibility to reuse
    -- those controls to not leak memory.
    node:SetParent(nil)
    self.nodes[node:GetName()] = nil
    local children = node:GetChildren()
    if children then
        for _, childNode in ipairs(children) do
            self:RemoveNode(childNode)
        end
    end
end

function ZO_SceneGraph:AddDebugTextureToNode(node)
    -- shortcut so you can see where a node is placed visually
    -- draws a purple box centered on the node's origin point
    local debugTexture = GetWindowManager():CreateControl(string.format("%sDebugTexture%d", self.canvasControl:GetName(), self.debugTextureId), self.canvasControl, CT_TEXTURE)
    self.debugTextureId = self.debugTextureId + 1
    debugTexture:SetDimensions(20, 20)
    debugTexture:SetColor(0.7, 0.7, 1, 1)
    debugTexture:SetPixelRoundingEnabled(false)
    node:AddTexture(debugTexture, 0, 0, 0)
end

function ZO_SceneGraph:OnSceneNodeDirty()
    self.needsRender = true
end

function ZO_SceneGraph:OnUpdate()
    if self.needsRender then
        self.needsRender = false
        self:Render()
    end
end

do
    local function RenderNode(node, dirtyUpstream)
        local dirty = dirtyUpstream or node:IsDirty()
        if dirty then
            node:BuildWorldViewMatrix()
            node:Render()
        end

        local children = node:GetChildren()
        if children ~= nil then
            for i = 1, #children do
                local child = children[i]
                RenderNode(child, dirty)
            end
        end
    end

    function ZO_SceneGraph:Render()
        local NOT_DIRTY_UPSTREAM = false
        RenderNode(self.cameraNode, NOT_DIRTY_UPSTREAM)
    end
end
