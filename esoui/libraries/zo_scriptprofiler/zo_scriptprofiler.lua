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

-- TODO: Someday there will be multiple record types, and they will be delineated by a SCRIPT_PROFILER_RECORD_TYPE enum.
local SCRIPT_PROFILER_RECORD_TYPE_CLOSURE = 1

local g_generatingReport = false
function ZO_ScriptProfiler_GenerateReport()
    if g_generatingReport then
        return
    end
    g_generatingReport = true

    local numRecords = 0
    local timeSpent = 0
    local recordDataByRecordType =
    {
        [SCRIPT_PROFILER_RECORD_TYPE_CLOSURE] = {},
    }

    local function GetOrCreateRecordData(recordType, recordDataIndex)
        assert(recordDataByRecordType[recordType] ~= nil, "Missing record type")
        if not recordDataByRecordType[recordType][recordDataIndex] then
            local data =
            {
                count = 0,
                includeTime = 0,
                excludeTime = 0,
            }

            if recordType == SCRIPT_PROFILER_RECORD_TYPE_CLOSURE then
                local name, filename, lineDefined = GetScriptProfilerClosureInfo(recordDataIndex)
                data.name = string.format("%s (%s:%d)", name, filename, lineDefined)
            else
                assert(false, "Missing record type")
            end
            recordDataByRecordType[recordType][recordDataIndex] = data
        end

        return recordDataByRecordType[recordType][recordDataIndex]
    end

    local function ParseRecord(frameIndex, recordIndex)
        local recordType = SCRIPT_PROFILER_RECORD_TYPE_CLOSURE -- TODO
        local recordDataIndex, startTimeNS, endTimeNS, calledByRecordIndex = GetScriptProfilerRecordInfo(frameIndex, recordIndex)
        local timeMS = (endTimeNS - startTimeNS) / (1000*1000)

        local source = GetOrCreateRecordData(recordType, recordDataIndex)
        source.count = source.count + 1
        source.includeTime = source.includeTime + timeMS
        source.excludeTime = source.excludeTime + timeMS
        timeSpent = timeSpent + timeMS

        if calledByRecordIndex then
            local calledByRecordType = SCRIPT_PROFILER_RECORD_TYPE_CLOSURE -- TODO
            local calledByRecordDataIndex = GetScriptProfilerRecordInfo(frameIndex, calledByRecordIndex)
            local calledByData = GetOrCreateRecordData(calledByRecordType, calledByRecordDataIndex)
            calledByData.excludeTime = calledByData.excludeTime - timeMS
        end
    end

    local function PrintReport()
        local sorted = {}
        for recordType, recordDatas in pairs(recordDataByRecordType) do
            for recordDataIndex, recordData in pairs(recordDatas) do
                table.insert(sorted, recordData)
            end
        end

        table.sort(sorted, function(a, b)
            return a.includeTime > b.includeTime
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