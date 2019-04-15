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
    tree.autoSelectChildOnNodeOpen = false
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

    tree.childContainerPool:SetCustomResetBehavior(function(container) container:SetAlpha(1) end)

    tree:Reset()

    TREES:Add(tree)

    tree:FindScrollControl()

    return tree
end

function ZO_Tree:OnScreenResized()
    self.rootNode:UpdateAllChildrenHeightsAndCurrentHeights()
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

function ZO_Tree:GetTreeNodeByData(data)
    return self:GetTreeNodeInTreeByData(data, self.rootNode)
end

function ZO_Tree:GetTreeNodeInTreeByData(data, rootNode)
    if rootNode then
        if rootNode.data == data then
            return rootNode
        end
        local currentChildren = rootNode:GetChildren()
        if currentChildren then
            for _, currentChild in ipairs(currentChildren) do
                local foundNode = self:GetTreeNodeInTreeByData(data, currentChild)
                if foundNode then 
                    return foundNode
                end
            end
        end
    end

    return nil
end

function ZO_Tree:SelectAnything()
    if not self.selectedNode or not self.selectedNode:IsEnabled() then
        local currentNode = self.rootNode
        while currentNode and not currentNode:IsLeaf() and currentNode:IsEnabled() do
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
    self.openAnimationPool = ZO_AnimationPool:New(animationTemplate)
    self.openAnimationPool:SetCustomFactoryBehavior(function(timeline)
        timeline:SetHandler("OnStop", function(currentTimeline) self:OnOpenAnimationStopped(currentTimeline) end)
    end)
    --populated on demand since it requires making an animation from the pool to know
    self.openAnimationDurationMS = nil
end

function ZO_Tree:GetOpenAnimationDuration()
    if not self.openAnimationDurationMS then
        local timeline, key = self.openAnimationPool:AcquireObject()
        self.openAnimationDurationMS = timeline:GetDuration()
        self.openAnimationPool:ReleaseObject(key)
    end
    return self.openAnimationDurationMS
end

function ZO_Tree:SetExclusive(exclusive)
    self.exclusive = exclusive
end

function ZO_Tree:SetAutoSelectChildOnNodeOpen(autoSelect)
    self.autoSelectChildOnNodeOpen = autoSelect
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
        template = template,
        childIndent = childIndent,
        childSpacing = childSpacing,
        setupFunction = setupFunction,
        selectionFunction = selectionFunction,
        equalityFunction = equalityFunction or DefaultEqualityFunction,
        objectPool = ZO_ControlPool:New(template, self.control)
    }    
end

function ZO_Tree:AddNode(template, data, parentNode, selectSoundOverride, open)
    if not parentNode then
        parentNode = self.rootNode
    end

    local templateInfo = self.templateInfo[template]

    local treeNode = ZO_TreeNode:New(self, templateInfo, parentNode, data, templateInfo.childIndent or self.defaultIndent, templateInfo.childSpacing or self.defaultSpacing, open == true)

    if selectSoundOverride ~= nil then
        treeNode.selectSound = selectSoundOverride
    elseif parentNode == self.rootNode then
        treeNode.selectSound = SOUNDS.TREE_HEADER_CLICK
    else
        treeNode.selectSound = SOUNDS.TREE_SUBCATEGORY_CLICK
    end

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

    if nodeToSelect ~= nil and nodeToSelect:IsEnabled() then
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

--Computes the offset of the bottom of the control at the end of the path from the scroll child top
--Used to determine where a node control will end up after being selected. This simulates the layout logic.
function ZO_Tree:ComputeEndOfPathControlFinalBottomOffset(currentTreeNode, pathToSelectedNode)
    local offset = 0
    --Path goes from parents to children
    local nextNodeOnPathToSelectedNode = pathToSelectedNode[#pathToSelectedNode]
    for i, childTreeNode in ipairs(currentTreeNode:GetChildren()) do
        if childTreeNode == nextNodeOnPathToSelectedNode then
            --When we find a node on the path we add its height, then if we can recurse on its children we add the proper spacing for the child section (1/2 on top, 1/2 on bottom) then recurse.
            offset = offset + childTreeNode:GetControlHeight()
            if #pathToSelectedNode == 1 then
                return offset
            else
                offset = offset + childTreeNode:GetParent():GetChildSpacing()
                table.remove(pathToSelectedNode)
                return offset + self:ComputeEndOfPathControlFinalBottomOffset(childTreeNode, pathToSelectedNode)
            end
        else
            if self.exclusive then
                --In exclusive mode we will be closing every non-leaf node except for the ones on the path so just count their control height. Their children will be hidden. 
                offset = offset + childTreeNode:GetControlHeight()
            else
                --In non-exlcusive mode we won't be touching the nodes off the path so use their actual height with children
                offset = offset + childTreeNode:GetHeight()
            end
            offset = offset + childTreeNode:GetParent():GetChildSpacing()
        end
    end
    return 0
end

function ZO_Tree:SetScrollToTargetNode(treeNode)
    local pathToSelectedNode = {}
    local currentNode = treeNode
    while currentNode and currentNode ~= self.rootNode do
        table.insert(pathToSelectedNode, currentNode)
        currentNode = currentNode:GetParent()
    end

    --Compute some metrics about the state of this tree after treeNode is selected. We use this so we can scroll to where the node WILL BE instead of where it is right now.
    local treeNodeControlFinalBottomOffset = self:ComputeEndOfPathControlFinalBottomOffset(self.rootNode, pathToSelectedNode)
    local treeNodeControlFinalTopOffset = treeNodeControlFinalBottomOffset - treeNode:GetControlHeight()

    local finalTotalHeight
    if self.exclusive then
        local previouslyOpenSectionChildrenHeight = 0
        for _, rootChild in ipairs(self.rootNode:GetChildren()) do
            if not rootChild:IsLeaf() and rootChild:IsOpen() then
                previouslyOpenSectionChildrenHeight = rootChild:GetChildrenHeight()
                break
            end
        end
        -- new node's height subtracted from the previously openned nodes' heights
        -- this is the change in height the tree will have, which will be needed to calculate the scroll's animation
        finalTotalHeight = self.rootNode:GetCurrentChildrenHeight() + treeNode:GetChildrenHeight() - previouslyOpenSectionChildrenHeight
    else
        finalTotalHeight = self.rootNode:GetCurrentChildrenHeight() + treeNode:GetChildrenHeight()
    end

    ZO_Scroll_SetScrollToRealOffsetAccountingForGradients(self.scrollControl, finalTotalHeight, treeNodeControlFinalTopOffset, self:GetOpenAnimationDuration())
    self.scrollTargetNode = treeNode
end

function ZO_Tree:ToggleNode(treeNode)
    if treeNode:IsEnabled() and (not self.exclusive or not treeNode:IsOpen()) then
        if self.scrollControl and not treeNode:IsOpen() then
            self:SetScrollToTargetNode(treeNode)
        end
        self:SetNodeOpen(treeNode, not treeNode:IsOpen(), USER_REQUESTED_OPEN)
    end
end

function ZO_Tree:SetNodeOpen(treeNode, open, userRequested)
    if(open) then
        treeNode:SetOpen(true, userRequested)

        --open the path to the root
        local currentNode = treeNode:GetParent()
        while currentNode do
            --because the tree is automatically opening a path, any opened nodes must be system requested opens
            currentNode:SetOpen(true, SYSTEM_REQUESTED_OPEN)
            currentNode = currentNode:GetParent()
        end

        if(self.exclusive) then
            self.exclusivePath = {}
            currentNode = treeNode
            while currentNode do
                table.insert(self.exclusivePath, currentNode)
                currentNode = currentNode:GetParent()
            end

            --close every node not on the newly opened path
            local rootChildren = self.rootNode:GetChildren()
            for i = 1, #rootChildren do
                local rootChild = rootChildren[i]
                self:ExecuteOnSubTree(rootChild, self.exclusiveCloseNodeFunction)
            end
        end

        if self.autoSelectChildOnNodeOpen and userRequested then
            self:SelectFirstChild(treeNode)
        end
    else
        treeNode:SetOpen(false, userRequested)
    end
end

function ZO_Tree:SelectNode(treeNode, reselectingDuringRebuild, bringParentIntoView)
    --Default to bringing the immediate parent of this node into view
    if bringParentIntoView == nil then
        bringParentIntoView = true
    end

    --Can only select leaf nodes
    if treeNode:IsLeaf() and treeNode:IsEnabled() then
        if self.selectedNode == treeNode then
            --If we already have this node selected we should still try to bring the parent into view anyway
            if not reselectingDuringRebuild and bringParentIntoView and self.scrollControl then
                local immediateParentNode = treeNode:GetParent()
                if immediateParentNode then
                    local immediateParentNodeControl = immediateParentNode:GetControl()
                    if immediateParentNodeControl then
                        if immediateParentNode:IsOpen() and not immediateParentNode == self.scrollTargetNode then
                            --If the parent is open then just scroll it to the top right now
                            ZO_Scroll_ScrollControlToTop(self.scrollControl, immediateParentNodeControl)                            
                        else
                            --If the parent is closed we need to open it and set up the scroll to target node behavior
                            self:SetScrollToTargetNode(immediateParentNode)
                            self:SetNodeOpen(immediateParentNode, true, SYSTEM_REQUESTED_OPEN)
                        end
                    end
                end                
            end
        else
            --Otherwise we need to select the node
            if self.selectedNode then
                self.selectedNode:OnUnselected()
            end
            self.selectedNode = treeNode
            if not reselectingDuringRebuild then
                if bringParentIntoView and self.scrollControl then
                    local immediateParentNode = treeNode:GetParent()
                    if immediateParentNode then
                        local immediateParentNodeControl = immediateParentNode:GetControl()
                        if immediateParentNodeControl then
                            if immediateParentNode:IsOpen() and not immediateParentNode == self.scrollTargetNode then
                                --If the parent is already open we can scroll to it right now
                                ZO_Scroll_ScrollControlToTop(self.scrollControl, immediateParentNodeControl)
                            else
                                --Otherwise we need to setup scroll over time since sections will be opening and closing
                                self:SetScrollToTargetNode(immediateParentNode)
                            end
                        end
                    end
                end
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

function ZO_Tree:GetSelectedNode()
    return self.selectedNode
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
        local stopIteration = func(treeRoot)
        if stopIteration then
            return
        end
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
    if self.scrollTargetNode == node and self.scrollControl then
        self.scrollTargetNode = nil
    end
    node:ReleaseTimeline()
end

function ZO_Tree:GetOpenAnimationPool()
    return self.openAnimationPool
end

function ZO_Tree:GetControl()
    return self.control
end

function ZO_Tree:IsAnimated()
    return not self.suspendAnimations 
           and self.openAnimationPool ~= nil
end

function ZO_Tree:FindScrollControl()
    local scrollControl = self.control:GetParent():GetParent()
    if scrollControl and scrollControl.scroll then
        self.scrollControl = scrollControl
    end
end

--TreeNode
---------------

ZO_TreeNode = ZO_Object:Subclass()

function ZO_TreeNode:New(tree, templateInfo, parentNode, data, childIndent, childSpacing, open)
    local node = ZO_Object.New(self)

    if templateInfo then
        node.templateInfo = templateInfo
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
    node.enabled = true

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

--Tree nodes have a control and a child section. The child section if it exists anchors to the control with half childSpacing above and half below to center it. Tree nodes
--within a child section anchor one after another with childSpacing between them. The first control anchors to the top left of the child section with no offset. The child spacing
--comes from the parent of the node that the child is being added to. This is likely wrong. It should come from the node the child is being added to.
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

--This functionality works in the context of a full refresh rather than arbitrarily deciding to disable a node manually
--So you'll want to control this in a setup/refresh, and ensure that the tree's Commit function is called after said refresh.
function ZO_TreeNode:SetEnabled(enabled)
    self.enabled = enabled
end

function ZO_TreeNode:IsEnabled()
    return self.enabled
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

function ZO_TreeNode:GetOrAcquireTimeline()
    if not self.timeline then
        local pool = self.tree:GetOpenAnimationPool()
        self.timeline, self.poolKey = pool:AcquireObject()
        self.timeline.node = self
    end
    return self.timeline
end

function ZO_TreeNode:ReleaseTimeline()
    local pool = self.tree:GetOpenAnimationPool()
    pool:ReleaseObject(self.poolKey)
    self.timeline = nil
    self.poolKey = nil
end

function ZO_TreeNode:SetOpen(open, userRequested)
    if not self:IsLeaf() and self.enabled and self.open ~= open then
        self.open = open
        self:RefreshControl(userRequested)
        if self:IsAnimated() then
            local timeline = self:GetOrAcquireTimeline()
            if timeline:IsPlaying() then
                if open then
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

                if open then
                    customAnim:SetEasingFunction(ZO_EaseOutQuadratic)
                    timeline:PlayFromStart()
                else
                    customAnim:SetEasingFunction(ZO_EaseInQuadratic)
                    timeline:PlayFromEnd()
                end
            end
        else
            if self.open then
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

function ZO_TreeNode:GetControlHeight()
    return self.control:GetHeight()
end

function ZO_TreeNode:GetChildrenHeight()
    return self.childrenHeight
end

function ZO_TreeNode:GetCurrentHeight()
    return self.control:GetHeight() + self.childrenCurrentHeight
end

function ZO_TreeNode:GetCurrentChildrenHeight()
    return self.childrenCurrentHeight
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

--The height of the children if this node was all the way open
function ZO_TreeNode:GetChildrenTotalHeight()
    if self.children then
        local height = 0
        for i = 1, #self.children do
            height = height + self.children[i]:GetHeight()
        end
        height = height + self.childSpacing * (#self.children - 1)
        return height
    else
        return 0
    end
end

function ZO_TreeNode:UpdateChildrenHeight()
    self.childrenHeight = self:GetChildrenTotalHeight()
end

function ZO_TreeNode:UpdateChildrenHeightsToRoot()
    self:UpdateChildrenHeight()

    if(self.parentNode) then
        self.parentNode:UpdateChildrenHeightsToRoot()
    end
end

--The height of the children taking into account how open they are
function ZO_TreeNode:GetChildrenTotalCurrentHeight()
    if self.children then
        local height = 0
        for i = 1, #self.children do
            height = height + self.children[i]:GetCurrentHeight()
        end
        height = height + self.childSpacing * (#self.children - 1)
        return height
    else
        return 0
    end
end

function ZO_TreeNode:UpdateChildrenCurrentHeight()
    local height = self:GetChildrenTotalCurrentHeight()
    height = height * self.openPercentage
    self.childrenCurrentHeight = height
    if self.childContainer then
        self.childContainer:SetHeight(self.childrenCurrentHeight)
    end
end

function ZO_TreeNode:UpdateCurrentChildrenHeightsToRoot()
    self:UpdateChildrenCurrentHeight()

    if(self.parentNode) then
        self.parentNode:UpdateCurrentChildrenHeightsToRoot()
    end
end

function ZO_TreeNode:UpdateAllChildrenHeightsAndCurrentHeights()
    if self.children then
        for _, child in ipairs(self.children) do
            child:UpdateAllChildrenHeightsAndCurrentHeights(child)
        end
    end

    self:UpdateChildrenHeight()
    self:UpdateChildrenCurrentHeight()
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

function ZO_TreeNode:GetTemplate()
    return self.templateInfo.template
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
        if not self.node:IsEnabled() then
            PlaySound(SOUNDS.NEGATIVE_CLICK)
        elseif not self.node.open and self.node.selectSound then
            PlaySound(self.node.selectSound)
        end

        self.node:GetTree():ToggleNode(self.node)
    end
end

function ZO_TreeEntry_OnMouseUp(self, upInside)
    if(upInside and self.node.tree.enabled) then
        -- Play the selected sound if not already selected
        if not self.node:IsEnabled() then
            PlaySound(SOUNDS.NEGATIVE_CLICK)
        elseif not self.node.selected and self.node.selectSound then
            PlaySound(self.node.selectSound)
        end

        local NOT_REBUILDING = false
        local DONT_BRING_PARENT_INTO_VIEW = false
        self.node:GetTree():SelectNode(self.node, NOT_REBUILDING, DONT_BRING_PARENT_INTO_VIEW)
    end
end

function ZO_TreeControl_GetNode(self)
    return self.node
end

--ZO_Trees
---------------

ZO_Trees = ZO_Object:Subclass()

function ZO_Trees:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_Trees:Initialize()
    self.trees = {}
    EVENT_MANAGER:RegisterForEvent("ZO_Trees", EVENT_ALL_GUI_SCREENS_RESIZED, function() self:OnScreenResized() end)
end

function ZO_Trees:Add(tree)
    table.insert(self.trees, tree)
end

function ZO_Trees:OnScreenResized()
    for _, tree in ipairs(self.trees) do
        tree:OnScreenResized()
    end
end

TREES = ZO_Trees:New()
