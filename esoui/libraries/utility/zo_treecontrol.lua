--[[
    The tree node
--]]

local ZO_TreeNode = ZO_Object:Subclass()

function ZO_TreeNode:New(myTree, controlData, myParent, childIndent)
    local node = ZO_Object.New(self)

    node.m_OwningTree       = myTree
    node.m_Control          = controlData
    node.m_Expanded         = true
    node.m_Showing          = true
    node.m_Child            = nil
    node.m_Sibling          = nil
    node.m_Parent           = myParent
    node.m_ExpandedCallback = nil
    node.m_ChildIndent      = childIndent
    
    return node
end

function ZO_TreeNode:SetExpandedCallback(callback)
    self.m_ExpandedCallback = callback
end

local function DetermineVisibility(node)
    if(node)
    then
        local parentShowing = true
        local parentExpanded = true
        
        if(node.m_Parent)
        then
            parentShowing = node.m_Parent:IsShowing()
            parentExpanded = node.m_Parent:IsExpanded()
        end
        
        node.m_Showing = parentShowing and parentExpanded

        if(node.m_Child)
        then
            DetermineVisibility(node.m_Child)
        end

        if(node.m_Sibling)
        then
            DetermineVisibility(node.m_Sibling)
        end
    end
end

function ZO_TreeNode:ToggleExpanded(expanded)
    if(expanded == nil) then
        expanded = not self.m_Expanded
    end
    
    self.m_Expanded = expanded
    
    if(self.m_ExpandedCallback) then
        self.m_ExpandedCallback(self, expanded)
    end
       
    if(expanded) then   
        --climb the tree opening un-expanded parents
        local lastChangedParent = self
        local curParent = self.m_Parent
        while(curParent ~= nil) do
            if(not curParent.m_Expanded) then
                curParent.m_Expanded = true
                if(curParent.m_ExpandedCallback) then
                    curParent.m_ExpandedCallback(curParent, true)
                end
                lastChangedParent = curParent
            end
            curParent = curParent.m_Parent
        end
        --update visibility from the highest changed node
        DetermineVisibility(lastChangedParent)
    else
        DetermineVisibility(self)
    end
    
    -- Update the whole tree.
    self.m_OwningTree:Update()
end

function ZO_TreeNode:IsExpanded()
    return self.m_Expanded
end

function ZO_TreeNode:IsShowing()
    return self.m_Showing
end

function ZO_TreeNode:HasChildren()
    return (self.m_Child ~= nil)
end

function ZO_TreeNode:GetNestingLevel()
    local nestingLevel = 0
    local ancestor = self.m_Parent
    
    while(ancestor ~= self.m_OwningTree.m_Root)
    do
        nestingLevel = nestingLevel + 1
        ancestor = ancestor.m_Parent
    end
    
    return nestingLevel
end

function ZO_TreeNode:GetControl()
    return self.m_Control
end

function ZO_TreeNode:GetOwningTree()
    return self.m_OwningTree
end

function ZO_TreeNode:GetNextSibling()
    return self.m_Sibling
end

function ZO_TreeNode:GetParent()
    return self.m_Parent
end

function ZO_TreeNode:GetChildIndent()
    return self.m_ChildIndent
end

function ZO_TreeNode:SetOffsetY(offsetY)
    self.m_OffsetY = offsetY
end
--[[
    The tree control
--]]

ZO_TreeControl = ZO_Object:Subclass()

local DEFAULT_INDENT_OFFSET = 10
local DEFAULT_LINE_SPACING  = 5


function ZO_TreeControl:New(initialAnchor, indentXOffset, verticalSpacing)
    local tree = ZO_Object.New(self)
    
    tree.m_Root             = ZO_TreeNode:New(tree)
    tree.m_OffsetX          = indentXOffset or DEFAULT_INDENT_OFFSET
    tree.m_OffsetY          = verticalSpacing or DEFAULT_LINE_SPACING
    tree.m_InitialAnchor    = initialAnchor

    return tree
end

function ZO_TreeControl:AddChild(atNode, insertedControl, childIndent)
    atNode = atNode or self.m_Root
    
    if(atNode == nil)
    then
        return nil
    end
    
    -- If root is the insertion point, and there is no child add the new node as Root's first child
    if((atNode == self.m_Root) and (self.m_Root.m_Child == nil))
    then
        local newNode = ZO_TreeNode:New(self, insertedControl, self.m_Root, childIndent)
        
        self.m_Root.m_Child = newNode        
        return newNode
    end
    
    -- Find the last sibling of atNode's first child and insert after that.
    if(atNode.m_Child == nil)
    then
        local newNode = ZO_TreeNode:New(self, insertedControl, atNode, childIndent)
        
        atNode.m_Child = newNode
        return newNode
    end

    return self:AddSibling(atNode.m_Child, insertedControl, childIndent)
end

local ADD_HERE = 1
local ADD_ON_END = 2
local function AddSiblingInternal(self, atNode, insertedControl, where, childIndent)
    atNode = atNode or self.m_Root.m_Child
    
    if((not atNode) or (atNode == self.m_Root))
    then
        return nil
    end
    
    local newNode = ZO_TreeNode:New(self, insertedControl, atNode.m_Parent, childIndent)
    if(where == ADD_ON_END) then
        while(atNode.m_Sibling)
        do
            atNode = atNode.m_Sibling
        end
    
        atNode.m_Sibling = newNode
    else     
        newNode.m_Sibling = atNode.m_Sibling
        atNode.m_Sibling = newNode   
    end
    
    return newNode
end

function ZO_TreeControl:AddSibling(atNode, insertedControl, childIndent)
    return AddSiblingInternal(self, atNode, insertedControl, ADD_ON_END, childIndent)
end

function ZO_TreeControl:AddSiblingAfterNode(atNode, insertedControl, childIndent)
    return AddSiblingInternal(self, atNode, insertedControl, ADD_HERE, childIndent)
end

-- NOTE: This removes entire subtrees, but does not inform the controls in those subtrees that they have been
-- removed.  That needs to be handled by whatever is calling RemoveNode.
function ZO_TreeControl:RemoveNode(node)
    if(node == self.m_Root) 
    then
        self:Clear()
        return
    end
    
    if(node.m_Parent)
    then
        if(node.m_Parent.m_Child == node)
        then
            node.m_Parent.m_Child = node.m_Sibling
            return
        end
        
        local previousSibling = nil
        local currentSibling = node.m_Parent.m_Child
        
        if(currentSibling == nil) 
        then 
            d("ZO_TreeControl: Corrupted tree.  Parent of: ", node, "...has no children.") 
            return 
        end
                
        while((currentSibling ~= node) and (currentSibling ~= nil))
        do
            previousSibling = currentSibling
            currentSibling = currentSibling.m_Sibling
        end
        
        if(currentSibling == node)
        then
            previousSibling.m_Sibling = node.m_Sibling
        end
    end
end

function ZO_TreeControl:Clear()
    self.m_Root = ZO_TreeNode:New(self)
end

function ZO_TreeControl:Update(updateFromNode, indent, anchor, firstControl)
    local node  = updateFromNode or self.m_Root
    indent      = indent or 0
    anchor      = anchor or ZO_Anchor:New(self.m_InitialAnchor)
    
    if(firstControl == nil) then
        firstControl = true
    end
        
    if(node)
    then
        local hidden = not node:IsShowing()
        
        if(node.m_Control)
        then
            node.m_Control:SetHidden(hidden)
                        
            if(not hidden)
            then
                if(firstControl) then
                    self.m_InitialAnchor:Set(node.m_Control)
                    firstControl = false
                else
                    anchor:SetOffsets(indent, node.m_OffsetY or self.m_OffsetY)                
                    anchor:Set(node.m_Control)           
                end     
                
                anchor:SetTarget(node.m_Control)
                anchor:SetRelativePoint(self.m_relativePoint or BOTTOMLEFT)
            end
        end
        
        local backOffIndent = false
        
        if(node.m_Child)
        then
            if(node == self.m_Root)
            then
                indent = 0
            else
                indent = node:GetChildIndent() or self.m_OffsetX
            end
                        
            anchor, indent = self:Update(node.m_Child, indent, anchor, firstControl)
            backOffIndent = node.m_Child:IsShowing()
        end
        
        if(backOffIndent)
        then
            indent = indent - (node:GetChildIndent() or self.m_OffsetX)
        else
            indent = 0
        end        
        
        node = node.m_Sibling
        
        if(node)
        then
            return self:Update(node, indent, anchor, firstControl)
        end
    end
    
    return anchor, indent
end

function ZO_TreeControl:SetRelativePoint(relativePoint)
    self.m_relativePoint = relativePoint
end

function ZO_TreeControl:SetIndent(indentX)
    self.m_OffsetX = indentX
end