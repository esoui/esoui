ZO_SceneNodeRing = ZO_Object:Subclass()

function ZO_SceneNodeRing:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_SceneNodeRing:Initialize(rootNode)
    self.rootNode = rootNode
    self.sceneGraph = rootNode:GetSceneGraph()
    self.angularVelocity = 0
    self.currentAngle = 0
    self.nodePositionsDirty = false

    self.ringNodes = {}
end

function ZO_SceneNodeRing:SetRadius(radius)
    if radius ~= self.radius then
        self.radius = radius
        self.nodePositionsDirty = true
    end
end

function ZO_SceneNodeRing:GetNodePadding(node)
    return node.ringPadding
end

function ZO_SceneNodeRing:SetNodePadding(node, radians)
    if radians ~= node.ringPadding then
        node.ringPadding = radians
        self.nodePositionsDirty = true
    end
end

function ZO_SceneNodeRing:RefreshNodePositions()
    if self.nodePositionsDirty then
        self.nodePositionsDirty = false

        local totalPadding = 0
        for i, node in ipairs(self.ringNodes) do
            totalPadding = totalPadding + node.ringPadding
        end
        --padding is on both side of a node
        totalPadding = totalPadding * 2

        local nodeArcSize = (2 * math.pi - totalPadding) / #self.ringNodes
        local currentAngle = 0
        for i, node in ipairs(self.ringNodes) do
            local nextNodeIndex = i % #self.ringNodes + 1
            local nextNode = self.ringNodes[nextNodeIndex]
            node:SetX(self.radius)
            node:SetRotation(currentAngle)
            currentAngle = currentAngle + nodeArcSize + node.ringPadding + nextNode.ringPadding
        end
    end
end

function ZO_SceneNodeRing:AddNode(node)
    node.ringPadding = 0
    table.insert(self.ringNodes, node)
    self.nodePositionsDirty = true
end

function ZO_SceneNodeRing:SetAngularVelocity(radiansPerSecond)
    self.angularVelocity = radiansPerSecond
end

function ZO_SceneNodeRing:GetAngle()
    return self.currentAngle
end

function ZO_SceneNodeRing:SetAngle(angle)
    self.currentAngle = angle % (2 * math.pi)
    self.rootNode:SetRotation(self.currentAngle)
end

function ZO_SceneNodeRing:GetNodeAtAngle(radians)
    radians = (radians - self.rootNode:GetRotation()) % (2 * math.pi)
    local closestNode
    local closestDistance
    for _, node in ipairs(self.ringNodes) do
        local nodeAngle = node:GetRotation()
        local distance = zo_abs(nodeAngle - radians)
        if distance > math.pi then
            distance = 2 * math.pi - distance
        end
        if not closestNode or distance < closestDistance then
            closestNode = node
            closestDistance = distance
        end
    end
    return closestNode
end

function ZO_SceneNodeRing:GetNextNode(node)
    for i, currentNode in ipairs(self.ringNodes) do
        if currentNode == node then
            return self.ringNodes[i % #self.ringNodes + 1]
        end
    end
end

function ZO_SceneNodeRing:GetPreviousNode(node)
    for i, currentNode in ipairs(self.ringNodes) do
        if currentNode == node then
            local prevIndex = i - 1
            if prevIndex == 0 then
                prevIndex = #self.ringNodes
            end
            return self.ringNodes[prevIndex]
        end
    end
end

function ZO_SceneNodeRing:GetAngularVelocity()
    return self.angularVelocity
end

function ZO_SceneNodeRing:Update(delta)
    if not self.sceneGraph:IsHidden() then
        self:RefreshNodePositions()
        self.currentAngle = self.currentAngle + self.angularVelocity * delta
        self.rootNode:SetRotation(self.currentAngle)
    end    
end