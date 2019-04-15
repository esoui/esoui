--[[
This is a reference implementation of a profile reporter using the ScriptProfiler API.
You can use it as an example of you how you can get useful results from the API, but alternate reporters
should be implemented in terms of the API, and not the functions defined here.
Usage:
to start collecting data:
    StartScriptProfiler()
to stop:
    StopScriptProfiler()
To print a report out to chat:
    ZO_ScriptProfiler_GenerateReport()
--]]

local g_generatingReport = false
function ZO_ScriptProfiler_GenerateReport()
    if g_generatingReport then
        return
    end
    g_generatingReport = true

    local numRecords = 0
    local timeSpent = 0
    local recordDataByRecordDataType =
    {
        [SCRIPT_PROFILER_RECORD_DATA_TYPE_CLOSURE] = {},
        [SCRIPT_PROFILER_RECORD_DATA_TYPE_CFUNCTION] = {},
        [SCRIPT_PROFILER_RECORD_DATA_TYPE_GARBAGE_COLLECTION] = {},
        [SCRIPT_PROFILER_RECORD_DATA_TYPE_USER_EVENT] = {},
    }

    local function GetOrCreateRecordData(recordDataType, recordDataIndex)
        assert(recordDataByRecordDataType[recordDataType] ~= nil, "Missing record type")
        if not recordDataByRecordDataType[recordDataType][recordDataIndex] then
            local data =
            {
                dataType = recordDataType,
                count = 0,
                includeTime = 0,
                excludeTime = 0,
            }

            if recordDataType == SCRIPT_PROFILER_RECORD_DATA_TYPE_CLOSURE then
                -- Closures are functions defined in Lua. Functions defined in the same file, on the same line, are considered the same function by the profiler.
                local name, filename, lineDefined = GetScriptProfilerClosureInfo(recordDataIndex)
                data.name = string.format("%s (%s:%d)", name, filename, lineDefined)
            elseif recordDataType == SCRIPT_PROFILER_RECORD_DATA_TYPE_CFUNCTION then
                -- C Functions are functions defined by ZOS as part of the game's API.
                data.name = GetScriptProfilerCFunctionInfo(recordDataIndex)
            elseif recordDataType == SCRIPT_PROFILER_RECORD_DATA_TYPE_GARBAGE_COLLECTION then
                -- At arbitrary times, the lua intepreter will automatically try to reclaim memory you are no longer using. When it does this we generate a GC event to track it.
                data.name = GetScriptProfilerGarbageCollectionInfo(recordDataIndex) == SCRIPT_PROFILER_GARBAGE_COLLECTION_TYPE_AUTOMATIC and "Lua GC Step" or "Manual collectgarbage() GC step"
            elseif recordDataType == SCRIPT_PROFILER_RECORD_DATA_TYPE_USER_EVENT then
                -- You can fire off your own custom events using RecordScriptProfilerUserEvent(myEventString). Events with the same eventString will share a recordDataIndex.
                data.name = string.format("User event: %q", GetScriptProfilerUserEventInfo(recordDataIndex))
            else
                assert(false, "Missing record type")
            end
            recordDataByRecordDataType[recordDataType][recordDataIndex] = data
        end

        return recordDataByRecordDataType[recordDataType][recordDataIndex]
    end

    local function ParseRecord(frameIndex, recordIndex)
        local recordDataIndex, startTimeNS, endTimeNS, calledByRecordIndex, recordDataType = GetScriptProfilerRecordInfo(frameIndex, recordIndex)
        local timeMS = (endTimeNS - startTimeNS) / (1000*1000)

        local source = GetOrCreateRecordData(recordDataType, recordDataIndex)
        source.count = source.count + 1
        source.includeTime = source.includeTime + timeMS
        source.excludeTime = source.excludeTime + timeMS
        timeSpent = timeSpent + timeMS

        if calledByRecordIndex then
            -- get caller, and exclude the current record's time from it. By the end, the only time that will be left is time spent exclusively in the caller and not in the callees.
            local calledByRecordDataIndex, _, _, _, calledByRecordDataType = GetScriptProfilerRecordInfo(frameIndex, calledByRecordIndex)
            local calledByData = GetOrCreateRecordData(calledByRecordDataType, calledByRecordDataIndex)
            calledByData.excludeTime = calledByData.excludeTime - timeMS
        end
    end

    local function PrintReport()
        local sorted = {}
        for recordDataType, recordDatas in pairs(recordDataByRecordDataType) do
            for recordDataIndex, recordData in pairs(recordDatas) do
                table.insert(sorted, recordData)
            end
        end

        table.sort(sorted, function(a, b)
            return a.excludeTime > b.excludeTime
        end)

        -- Print backwards, so the first element is at the bottom of chat
        for i = math.min(20, #sorted), 1, -1 do
            d("---")
            d(sorted[i])
        end
        local totals =
        {
            numRecords = numRecords,
            averageTimePerFrame = timeSpent / GetScriptProfilerNumFrames(),
        }
        d(totals)
        g_generatingReport = false
    end

    do
        -- This splits up the work you would otherwise do as:
        -- for frameIndex = 1, GetScriptProfilerNumFrames() do
        --     for recordIndex = 1, GetScriptProfilerFrameNumRecords(frameIndex) do
        --         ...
        --     end
        -- end
        local frameIndex = 1
        local recordIndex = 1

        local numFrames = GetScriptProfilerNumFrames()
        local numFrameRecords = GetScriptProfilerFrameNumRecords(frameIndex)

        local RECORDS_PER_UPDATE = 100000 -- Arbitrarily chosen number, tune to workload

        EVENT_MANAGER:RegisterForUpdate("ZO_ScriptProfiler_Report", 0, function()
            for _ = 1, RECORDS_PER_UPDATE do
                if recordIndex > numFrameRecords then
                    frameIndex = frameIndex + 1
                    recordIndex = 1
                    numFrameRecords = GetScriptProfilerFrameNumRecords(frameIndex)
                end

                if frameIndex > numFrames then
                    EVENT_MANAGER:UnregisterForUpdate("ZO_ScriptProfiler_Report")
                    PrintReport()
                    return
                end

                ParseRecord(frameIndex, recordIndex)

                numRecords = numRecords + 1
                recordIndex = recordIndex + 1
            end
        end)
        d("building report...")
    end
end