function ZO_DumpTopControlCreations(maxToOutput)
    local sources = {}
    local total = 0
    for i = 1, GetNumControlCreatingSources() do
        local sourceName = GetControlCreatingSourceName(i)
        local source =
        {
            name = sourceName,
            count = 0,
        }
        table.insert(sources, source)

        for j = 1, GetNumControlCreatingSourceCallSites(sourceName) do
            local creationStack, count = GetControlCreatingSourceCallSiteInfo(sourceName, j)
            source.count = source.count + count
        end
        total = total + source.count
    end

    table.sort(sources, function(a, b) return a.count > b.count end)

    d(string.format("Total: %d", total))
    for i = 1, zo_min(#sources, maxToOutput) do
        local source = sources[i]
        d(string.format("|cffffff%d - %s|r", source.count, source.name))
    end
end

function ZO_DumpControlCreationStacksForSource(searchTerm)
    local sources = {}
    searchTerm = string.lower(searchTerm)

    for i = 1, GetNumControlCreatingSources() do
        local sourceName = GetControlCreatingSourceName(i)
        local lowerSourceName = string.lower(sourceName)
        if zo_plainstrfind(lowerSourceName, searchTerm) then
            table.insert(sources, { name = sourceName, index = i })
        end        
    end
    
    d(string.format("|c00ff00Matches for '%s':", searchTerm)) 
    for _, source in ipairs(sources) do
        d(string.format("|cffffff%s|r", source.name))
        for j = 1, GetNumControlCreatingSourceCallSites(source.name) do
            local creationStack, count = GetControlCreatingSourceCallSiteInfo(source.name, j)
            d(string.format(">|cff0000%d|r from:", count))
            d(creationStack)
        end
    end
end

--If this setting is enabled, start the profiler so addons can profile their loading.
if GetCVar("StartLuaProfilingOnUILoad") == "1" then
    SetCVar("StartLuaProfilingOnUILoad", "0")
    StartScriptProfiler()
end