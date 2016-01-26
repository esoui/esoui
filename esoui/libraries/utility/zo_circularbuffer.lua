ZO_CircularBuffer = ZO_Object:Subclass()

local DEFAULT_MAX_SIZE = 100

function ZO_CircularBuffer:New(maxSize)
    local buffer = ZO_Object.New(self)
    
    buffer.maxSize = maxSize or DEFAULT_MAX_SIZE
    buffer:Clear()
    
    return buffer
end

function ZO_CircularBuffer:Add(item)
    self.index = self.index + 1
    
    local old = self.entries[self.index]
    self.entries[self.index] = item
    
    self.index = self.index % self.maxSize
    
    return old
end

function ZO_CircularBuffer:CalculateIndex(index)
    return (self.index - self:Size() + index - 1) % self.maxSize + 1
end

function ZO_CircularBuffer:At(index)
    if index > 0 and index <= self:Size() then
        local index = self:CalculateIndex(index)
        return self.entries[index]
    end
end

function ZO_CircularBuffer:Clear()
    self.index = 0
    self.entries = {}
end

function ZO_CircularBuffer:Size()
    return #self.entries
end

function ZO_CircularBuffer:MaxSize()
    return self.maxSize
end

function ZO_CircularBuffer:IsFull()
    return self.maxSize == #self.entries
end

function ZO_CircularBuffer:SetMaxSize(maxSize)
    self.maxSize = maxSize or DEFAULT_MAX_SIZE
    self.index = self.index % self.maxSize
end

function ZO_CircularBuffer:GetEnumerator()
    local currentIndex = 0
    local size = self:Size()
    return function()
        if currentIndex < size then
            currentIndex = currentIndex + 1

            return currentIndex, self:At(currentIndex)
        end
    end
end