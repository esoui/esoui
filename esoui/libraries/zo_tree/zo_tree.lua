local ZO_TreeNode
local RESELECTING_DURING_REBUILD = true
local USER_REQUESTED_OPEN = true
local SYSTEM_REQUESTED_OPEN = false

--Tree
---------------

ZO_Tree = ZO_Object:Subclass()

function ZO_Tree:New(control, defaultIndent, defaultSpacing, width)
    local tree = ZO_Object.New(self)
    
    tree.control = control
    tree.width = width
    tree.defaultIndent = defaultIndent
    tree.defaultSpacing = defaultSpacing
    tree.exclusive = false
    tree.enabled = true
    tree.templateInfo = {}
    tree.exclusiveCloseNodeFunction =   function(treeNode)                               
                                            for i = 1, #tree.exclusivePath do
                                                if(tree.exclusivePath[i] == treeNode) then
                                                    return
                                                end
                                            end
                                            treeNode:SetOpen(false, SYSTEM_REQUESTED_OPEN)
                                        end
    
    tree.childContainerPool = ZO_ControlPool:New("ZO_TreeChildContainer", control, "Container")

    tree.childContainerPool:SetCustomResetBehavior(function(control) control:SetAlpha(1) end)

    tree:Reset()

    return tree
end

function ZO_Tree:Reset()
    local OPEN = true

    self.previousRoot = self.rootNode
    self.selectedNode = nil

    self.rootNode = ZO_TreeNode:New(self, nil, nil, nil, 0, self.defaultSpacing, OPEN)
    self.childContainerPool:ReleaseAllObjects()
    for template, templateInfo in pairs(self.templateInfo) do
        templateInfo.objectPool:ReleaseAllObjects()
    end
    if(self.selectionHighlight) then
        self.selectionHighlight:SetHidden(true)
    end
    if(self.openAnimationPool) then
        self.openAnimationPool:ReleaseAllObjects()
    end

    self:SetSuspendAnimations(true)
end

function ZO_Tree:SelectAnything()
    if not self.selectedNode then
        local currentNode = self.rootNode
        while currentNode and not currentNode:IsLeaf() do
            currentNode = currentNode:GetChildren()[1]
        end
        if currentNode and currentNode ~= self.rootNode then
            self:SelectNode(currentNode)
        end
    end
end

function ZO_Tree:SelectFirstChild(parentNode)
    local children = parentNode:GetChildren()
    if(children) then
        local firstChild = children[1]
        if(firstChild) then
            self:SelectNode(firstChild)
        end
    end
end

function ZO_Tree:SetSelectionHighlight(template)
    self.selectionHighlightTemplate = template
end

function ZO_Tree:SetOpenAnimation(animationTemplate)
    self.openAnimationTemplate = animationTemplate

    local factory = function(pool)
                        return ANIMATION_MANAGER:CreateTimelineFromVirtual(self.openAnimationTemplate)
                    end
    local reset =   function(animation)
                        animation:Stop()                       
                    end 

    self.openAnimationPool = ZO_ObjectPool:New(factory, reset)
end

function ZO_Tree:SetExclusive(exclusive)
    self.exclusive = exclusive
end

function ZO_Tree:SetSuspendAnimations(suspendAnimations)
    self.suspendAnimations = suspendAnimations
end

function ZO_Tree:GetWidth()
    return self.width
end

local function DefaultEqualityFunction(left, right)
    return left == right
end

function ZO_Tree:AddTemplate(template, setupFunction, selectionFunction, equalityFunction, childIndent, childSpacing)    
    self.templateInfo[template] =
    {
        childIndent = childIndent,
        childSpacing = childSpacing,
        setupFunction = setupFunction,
        selectionFunction = selectionFunction,
        equalityFunction = equalityFunction or DefaultEqualityFunction,
        objectPool = ZO_ControlPool:New(template, self.control)
    }    
end

function ZO_Tree:AddNode(template, data, parentNode, selectSound)
    if(not parentNode) then
        parentNode = self.rootNode
    end

    local templateInfo = self.templateInfo[template]

    local CLOSED = false
    local treeNode = ZO_TreeNode:New(self, templateInfo, parentNode, data, templateInfo.childIndent or self.defaultIndent, templateInfo.childSpacing or self.defaultSpacing, CLOSED)
	treeNode.selectSound = selectSound
    parentNode:AddChild(treeNode)
    
    return treeNode
end

local function ReopenNodes(tree, currentNodeOfPreviousTree, currentNodeOfCurrentTree)
    if currentNodeOfPreviousTree and currentNodeOfCurrentTree then
        local previousChildren = currentNodeOfPreviousTree:GetChildren()
        local currentChildren = currentNodeOfCurrentTree:GetChildren()
        if previousChildren and currentChildren then
            for _, previousChild in ipairs(previousChildren) do
                for _, currentChild in ipairs(currentChildren) do
                    if previousChild.equalityFunction == currentChild.equalityFunction and previousChild.equalityFunction(previousChild.data, currentChild.data) then
                        if previousChild:IsLeaf() and currentChild:IsLeaf() then
                            if previousChild:IsSelected() ~= currentChild:IsSelected() then
                                tree:SelectNode(currentChild, RESELECTING_DURING_REBUILD)
                                if tree.exclusive then
                                    return
                                end
                            end
                        elseif not previousChild:IsLeaf() and not currentChild:IsLeaf() then
                            if currentChild:IsOpen() ~= previousChild:IsOpen() then
                                currentChild:SetOpen(previousChild:IsOpen(), SYSTEM_REQUESTED_OPEN)
                            end
                            ReopenNodes(tree, previousChild, currentChild)
                        end
                    end
                end
            end
        end
    end
end

function ZO_Tree:Commit(nodeToSelect)
    if self.previousRoot then
        local currentNodeOfPreviousTree = self.previousRoot
        local currentNodeOfCurrentTree = self.rootNode
        ReopenNodes(self, currentNodeOfPreviousTree, currentNodeOfCurrentTree)
    end

    if nodeToSelect ~= nil then
        self:SelectNode(nodeToSelect)
    elseif self.exclusive then
        self:SelectAnything()
    end

    self.previousRoot = nil

    self:SetSuspendAnimations(false)
end

function ZO_Tree:SetEnabled(enabled)
    if self.enabled ~= enabled then
        self.enabled = enabled
        self:RefreshVisible()
    end
end

function ZO_Tree:IsEnabled()
    return self.enabled
end

function ZO_Tree:RefreshVisible()
    local USER_REQUESTED = true
    self.rootNode:RefreshVisible(USER_REQUESTED)
end

function ZO_Tree:ToggleNode(treeNode)
    if not self.exclusive or not treeNode:IsOpen() then
        self:SetNodeOpen(treeNode, not treeNode:IsOpen(), USER_REQUESTED_OPEN)
    end
end

function ZO_Tree:SetNodeOpen(treeNode, open, userRequested)
    if(open) then
        treeNode:SetOpen(true, userRequested)

        --open the path to the root
        local current = treeNode:GetParent()
        while(current) do
            --because the tree is automatically opening a path, any opened nodes must be system requested opens
            current:SetOpen(true, SYSTEM_REQUESTED_OPEN)
            current = current:GetParent()
        end

        if(self.exclusive) then
            self.exclusivePath = {}
            local current = treeNode
            while(current) do
                table.insert(self.exclusivePath, current)
                current = current:GetParent()
            end

            --close every node not on the newly opened path
            local rootChildren = self.rootNode:GetChildren()
            for i = 1, #rootChildren do
                local rootChild = rootChildren[i]
                self:ExecuteOnSubTree(rootChild, self.exclusiveCloseNodeFunction)
            end
        end
    else
        treeNode:SetOpen(false, userRequested)
    end
end

function ZO_Tree:SelectNode(treeNode, reselectingDuringRebuild)
    if(treeNode:IsLeaf() and self.selectedNode ~= treeNode) then
        if self.selectedNode then
            self.selectedNode:OnUnselected()
        end
        self.selectedNode = treeNode
        if not reselectingDuringRebuild then
            self:SetNodeOpen(treeNode, true, USER_REQUESTED_OPEN)
        end
        treeNode:OnSelected(reselectingDuringRebuild)
        local selectionHighlight = self:GetSelectionHighlight()
        if(selectionHighlight) then
            selectionHighlight:ClearAnchors()
            local treeNodeControl = treeNode:GetControl()
            selectionHighlight:SetAnchorFill(treeNodeControl)
            selectionHighlight:SetParent(treeNode:GetParent():GetChildContainer())
            selectionHighlight:SetHidden(false)
        end
    end
end

function ZO_Tree:ClearSelectedNode()
    if self.selectedNode then
        self.selectedNode:OnUnselected()
        self.selectedNode = nil
        if self.selectionHighlight then
            self.selectionHighlight:SetHidden(true)
        end
    end
end

function ZO_Tree:GetSelectedData()
    if self.selectedNode then
        return self.selectedNode.data
    end
end

function ZO_Tree:GetSelectionHighlight()
    if(self.selectionHighlight) then
        return self.selectionHighlight
    else
        if(self.selectionHighlightTemplate) then
            self.selectionHighlight = CreateControlFromVirtual(self.control:GetName().."Highlight", self.control, self.selectionHighlightTemplate)
            return self.selectionHighlight
        end
    end
end

function ZO_Tree:ExecuteOnSubTree(treeRoot, func)
    if(treeRoot) then
        func(treeRoot)
    else
        treeRoot = self.rootNode
    end

    local children = treeRoot:GetChildren()
    if(children) then
        for i = 1, #children do
            self:ExecuteOnSubTree(children[i], func)
        end
    end
end

function ZO_Tree:AcquireNewChildContainer()
    return self.childContainerPool:AcquireObject()
end

function ZO_Tree:OnOpenAnimationStopped(timeline)
    local node = timeline.node
    self.openAnimationPool:ReleaseObject(node)
end

function ZO_Tree:AcquireOpenAnimation(treeNode)
    if(self.openAnimationPool) then
        local timeline = self.openAnimationPool:GetExistingObject(treeNode)
        if(timeline) then
            return timeline
        end

        timeline = self.openAnimationPool:AcquireObject(treeNode)
        timeline.node = treeNode
        timeline:SetHandler("OnStop", function(timeline) self:OnOpenAnimationStopped(timeline) end)
        return timeline
    end
end

function ZO_Tree:GetControl()
    return self.control
end

function ZO_Tree:IsAnimated()
    return not self.suspendAnimations 
           and self.openAnimationPool ~= nil
end

--TreeNode
---------------

ZO_TreeNode = ZO_Object:Subclass()

function ZO_TreeNode:New(tree, templateInfo, parentNode, data, childIndent, childSpacing, open)
    local node = ZO_Object.New(self)

    if(templateInfo) then
        local control = templateInfo.objectPool:AcquireObject()
        node.control = control
        control.node = node
        node.setupFunction = templateInfo.setupFunction
        node.selectionFunction = templateInfo.selectionFunction
        node.equalityFunction = templateInfo.equalityFunction
        control:SetHidden(false)
    end

    node.tree = tree
    node.parentNode = parentNode
    node.data = data
    node.childIndent = childIndent
    node.childSpacing = childSpacing
    node.childrenHeight = 0
    node.childrenCurrentHeight = 0
    node.open = open
    node.openPercentage = open and 1 or 0
    node.selected = false

    node:RefreshControl()

    return node
end

function ZO_TreeNode:ComputeTotalIndentFrom(treeNode)
    local total = 0
    while(treeNode ~= nil) do
        total = total + treeNode:GetChildIndent()
        treeNode = treeNode:GetParent()
    end
    return total
end

function ZO_TreeNode:AddChild(treeNode)
    local previousNode = nil
    if(not self.children) then
        self.children = {}
        self.childContainer = self.tree:AcquireNewChildContainer()
        self.childContainer:SetHidden(false)
        local childContainerWidth = self.tree:GetWidth() - self:ComputeTotalIndentFrom(self.parentNode)
        if(self.control) then
            --split the child spacing evenly on either side of the child container
            self.childContainer:SetAnchor(TOPLEFT, self.control, BOTTOMLEFT, 0, self.parentNode:GetChildSpacing() * 0.5)
            self.childContainer:SetWidth(childContainerWidth)
        else
            --root node, anchor that to fill the tree control space
            self.childContainer:SetAnchor(TOPLEFT, self.tree:GetControl(), TOPLEFT, 0, 0)
            self.childContainer:SetWidth(childContainerWidth)
        end

        if(self.parentNode) then
            self.childContainer:SetParent(self.parentNode:GetChildContainer())
        end

        if(self.nextNode) then
            self:AttachNext(self.nextNode)
        end
    else
        previousNode = self.children[#self.children]
    end

    local childControl = treeNode:GetControl()
    childControl:SetParent(self.childContainer)
    if(previousNode) then
        previousNode:AttachNext(treeNode)
    else        
        childControl:SetAnchor(TOPLEFT, self.childContainer, TOPLEFT, self.childIndent, 0)
    end

    table.insert(self.children, treeNode)

    self:UpdateChildrenHeightsToRoot()
    self:UpdateCurrentChildrenHeightsToRoot()
end

function ZO_TreeNode:AttachNext(nextTreeNode)
    local nextNodeControl = nextTreeNode:GetControl()
    nextNodeControl:ClearAnchors()
    if(self.childContainer) then
        --split the child spacing evenly on either side of the child container
        nextNodeControl:SetAnchor(TOPLEFT, self.childContainer, BOTTOMLEFT, 0, self.parentNode:GetChildSpacing() * 0.5)
    else
        nextNodeControl:SetAnchor(TOPLEFT, self.control, BOTTOMLEFT, 0, self.parentNode:GetChildSpacing())
    end
    self.nextNode = nextTreeNode
end

function ZO_TreeNode:IsAnimated()
    return self.tree:IsAnimated()
end

function ZO_TreeNode:IsSelected()
    return self:IsLeaf() and self.selected
end

function ZO_TreeNode:RefreshVisible(userRequested)
    self:RefreshControl(userRequested)
    if self.children then
        for i, child in ipairs(self.children) do
            child:RefreshVisible(userRequested)
        end
    end
end

function ZO_TreeNode:IsOpen()
    if(self:IsLeaf()) then
        return true
    else
        return self.open
    end
end

function ZO_TreeNode:SetOpen(open, userRequested)
    if(not self:IsLeaf() and self.open ~= open) then
        self.open = open
        self:RefreshControl(userRequested)
        if(self:IsAnimated()) then
            local timeline = self.tree:AcquireOpenAnimation(self)
            if(timeline:IsPlaying()) then
                if(open) then
                    timeline:PlayForward()
                else
                    timeline:PlayBackward()
                end
            else
                --custom anim must always be first
                local customAnim = timeline:GetFirstAnimation()
                customAnim:SetUpdateFunction(function(animation, progress) self:SetOpenPercentage(progress) end)
                local numAnimations = timeline:GetNumAnimations()
                for i = 2, numAnimations do
                    local animation = timeline:GetAnimation(i)
                    animation:SetAnimatedControl(self.childContainer)
                end

                if(open) then
                    customAnim:SetEasingFunction(ZO_EaseOutQuadratic)
                    timeline:PlayFromStart()
                else
                    customAnim:SetEasingFunction(ZO_EaseInQuadratic)
                    timeline:PlayFromEnd()
                end
            end
        else
            if(self.open) then
                self:SetOpenPercentage(1)
            else
                self:SetOpenPercentage(0)
            end
        end
    end
end

function ZO_TreeNode:SetOpenPercentage(openPercentage)
    self.openPercentage = openPercentage
    self:UpdateCurrentChildrenHeightsToRoot()
end

function ZO_TreeNode:OnSelected(reselectingDuringRebuild)
    if self.selectionFunction then
        self.selectionFunction(self.control, self.data, true, reselectingDuringRebuild)
    end
    self.selected = true
end

function ZO_TreeNode:OnUnselected()
    if self.selectionFunction then
        self.selectionFunction(self.control, self.data, false, false)
    end
    self.selected = false
end

function ZO_TreeNode:GetHeight()
    return self.control:GetHeight() + self.childrenHeight
end

function ZO_TreeNode:GetCurrentHeight()
    return self.control:GetHeight() + self.childrenCurrentHeight
end

function ZO_TreeNode:GetWidth()
    return self.control and self.control:GetWidth() or 0
end

function ZO_TreeNode:GetTotalWidth()
    if self.parentNode and self.control then
        return self:GetControl():GetRight() - self.parentNode:GetChildContainer():GetLeft()
    end
    return self:GetWidth()
end

function ZO_TreeNode:GetChildContainer()
    return self.childContainer
end

function ZO_TreeNode:IsLeaf()
    return (self.children == nil)
end

function ZO_TreeNode:GetTree()
    return self.tree
end

function ZO_TreeNode:UpdateChildrenHeightsToRoot()
    if(self.children) then
        local height = 0
        for i = 1, #self.children do
            height = height + self.children[i]:GetHeight()
        end
        height = height + self.childSpacing * (#self.children - 1)
        self.childrenHeight = height
    end

    if(self.parentNode) then
        self.parentNode:UpdateChildrenHeightsToRoot()
    end
end

function ZO_TreeNode:UpdateCurrentChildrenHeightsToRoot()
    if(self.children) then
        local height = 0
        for i = 1, #self.children do
            height = height + self.children[i]:GetCurrentHeight()
        end
        height = height + self.childSpacing * (#self.children - 1)
        height = height * self.openPercentage
        self.childrenCurrentHeight = height
        self.childContainer:SetHeight(self.childrenCurrentHeight)
    end

    if(self.parentNode) then
        self.parentNode:UpdateCurrentChildrenHeightsToRoot()
    end
end

function ZO_TreeNode:GetControl()
    return self.control
end

function ZO_TreeNode:GetParent()
    return self.parentNode
end

function ZO_TreeNode:GetChildren()
    return self.children
end

function ZO_TreeNode:GetChildSpacing()
    return self.childSpacing
end

function ZO_TreeNode:GetChildIndent()
    return self.childIndent
end

function ZO_TreeNode:GetData()
    return self.data
end

function ZO_TreeNode:RefreshControl(userRequested)
    if(self.setupFunction) then
        self.setupFunction(self, self.control, self.data, self.open, userRequested, self.tree:IsEnabled())
    end
end

--Global XML

function ZO_TreeHeader_OnMouseUp(self, upInside)
    if(upInside and self.node.tree.enabled) then
        -- Play the selected sound if not already opened
		if(not self.node.open and self.node.selectSound) then
			PlaySound(self.node.selectSound)
		end

        self.node:GetTree():ToggleNode(self.node)
    end
end

function ZO_TreeEntry_OnMouseUp(self, upInside)
    if(upInside and self.node.tree.enabled) then
        -- Play the selected sound if not already selected
		if(not self.node.selected and self.node.selectSound) then
			PlaySound(self.node.selectSound)
		end

        self.node:GetTree():SelectNode(self.node)
    end
end