ZO_CategoryManager = ZO_Object:Subclass()

--list to hold node order for adding
local nodeList = {}

function ZO_CategoryManager:New()
    local newObj = ZO_Object.New(self)
    
    newObj.m_categoryCache = {}
    newObj.m_categoryData = {}

    return newObj
end

function ZO_CategoryManager:GetCategoryCache()
    return self.m_categoryCache
end

function ZO_CategoryManager:GetCategoryCacheData(catId)
    if(catId and self.m_categoryCache[catId])
    then
        return self.m_categoryCache[catId].data
    end
end

function ZO_CategoryManager:GetCategoryData()    
    return self.m_categoryData
end

function ZO_CategoryManager:ClearCategoryCache()
    self.m_categoryCache = {}
end

function ZO_CategoryManager:ClearCategoryData()
    self.m_categoryData = {}
    
    for k,v in pairs(self.m_categoryCache) do        
        v.children = nil
        v.inTree = nil
    end
end

function ZO_CategoryManager:AddCategory(catId, parentId, data)
    if(catId and not self:HasCategory(catId))
    then
		self.m_categoryCache[catId] = { id = catId, parentId = parentId, data = data}            
    end
end

function ZO_CategoryManager:HasCategory(catId)
    return self.m_categoryCache[catId] ~= nil
end

function ZO_CategoryManager:InsertData(parentCatId, data, comparator)
    
    --build the data node
    local dataNode = { parentId = parentCatId, data = data }
    table.insert(nodeList, dataNode)
    
    --collect nodes that lead to the data (ex. [grandParent, parent, data])
    local currCatId = parentCatId
    local currCat = nil

    -- Prevent cycles
    local visited = {}
    
    while(currCatId ~= nil) do
        if(visited[currCatId]) then break end

        currCat = self.m_categoryCache[currCatId]
        visited[currCatId] = true
        table.insert(nodeList, currCat)
        currCatId = currCat.parentId
    end

    self:InsertDataHelper(nodeList, comparator, self.m_categoryData)
end

function ZO_CategoryManager:InsertDataHelper(nodeList, comparator, level)
    
    --we've just processed the leaf node, quit
    if(#nodeList == 0) then
        return
    end
    
    --collect the next node and strike it from the list
    local currNode = nodeList[#nodeList]
    --node list is cleared out in the process of inserting the data
    nodeList[#nodeList] = nil
    
    --if we found the category is already in the tree, continue on...
    if(currNode.inTree) then
        self:InsertDataHelper(nodeList, comparator, currNode.children)
        return
    end
    
    --otherwise, add the category
    self:InsertAtLevel(currNode, comparator, level)
    self:InsertDataHelper(nodeList, comparator, currNode.children)
end

local function BinaryInsert(node, comparator, level)

    local low = 1
    local high = #level
    local mid

    --search out the insert position
    while(low <= high) do
        mid = low + math.floor((high-low) * 0.5)
        local compVal = comparator(node,level[mid])
        if(compVal > 0) then
            low = mid + 1
        else
            high = mid - 1
        end
    end
    
    table.insert(level, high+1, node)

end

function ZO_CategoryManager:InsertAtLevel(node, comparator, level)
    --leaf nodes have no id and no children
    if(node.id) then
        node.children= {}
    end
    
    node.inTree = true
    
    --ordered add
    if(comparator and #level > 0) then
        BinaryInsert(node, comparator, level) 
        return  
    end
    
    --unordered add, or it's at the end of the ordered list
    table.insert(level, node)
end

