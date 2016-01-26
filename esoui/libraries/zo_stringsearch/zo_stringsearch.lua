---------------
--String Search
---------------

ZO_StringSearch = ZO_Object:Subclass()

function ZO_StringSearch:New(doCaching)
    local search = ZO_Object.New(self)

    search.data = {}
    search.processors = {}
    search.cache = doCaching or false

    return search
end

function ZO_StringSearch:AddProcessor(typeId, processingFunction)
    self.processors[typeId] = processingFunction
end

function ZO_StringSearch:Insert(data)
    if(data) then
        table.insert(self.data, data)
    end
end

function ZO_StringSearch:Remove(data)
    if(data) then
        local numData = #self.data
        for i = 1, numData do
            if(self.data[i] == data) then
                self.data[i] = self.data[numData]
                table.remove(self.data, numData)
                return
            end
        end
    end
end

function ZO_StringSearch:RemoveAll()
    self.data = {}
end

function ZO_StringSearch:ClearCache()
    local data = self.data
    local max = #data
    for i = 1, max do
        data[i].cache = nil
        data[i].cached = false
    end
end

function ZO_StringSearch:Process(data, searchTerms)
    local numTerms = #searchTerms
    for i = 1, numTerms do
        local processFunc = self.processors[data.type]
        if(not processFunc(self, data, searchTerms[i], self.cache)) then
            return false
        end
    end

    return true
end

function ZO_StringSearch:GetSearchTerms(str)
    local strLen = #str
    local lowerStr = str:lower()
    local searchTerms = {}

    for term in lowerStr:gmatch("%S+") do
        table.insert(searchTerms, term:lower())
    end

    return searchTerms
end

function ZO_StringSearch:IsMatch(str, data)
    if(not str or str == "") then return true end
    local searchTerms = self:GetSearchTerms(str)
    return self:Process(data, searchTerms)
end

function ZO_StringSearch:GetFromCache(data, cache, dataFunction, ...)
    if(cache) then
        if(not data.cached) then
            --store the result list as a table
            data.cache = { dataFunction(...) }
            data.cached = true
        end
        --return the list of results
        return unpack(data.cache)
    else
        --if we're not using caching, just call the function
        return dataFunction(...)
    end
end