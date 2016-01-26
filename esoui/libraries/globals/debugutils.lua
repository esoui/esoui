local function EmitMessage(text)
    if(CHAT_SYSTEM)
    then
        if(text == "")
        then
            text = "[Empty String]"
        end
        
        CHAT_SYSTEM:AddMessage(text)
    end
end

local function EmitTable(t, indent, tableHistory)
    indent          = indent or "."
    tableHistory    = tableHistory or {}
    
    for k, v in pairs(t)
    do
        local vType = type(v)

        EmitMessage(indent.."("..vType.."): "..tostring(k).." = "..tostring(v))
        
        if(vType == "table")
        then
            if(tableHistory[v])
            then
                EmitMessage(indent.."Avoiding cycle on table...")
            else
                tableHistory[v] = true
                EmitTable(v, indent.."  ", tableHistory)
            end
        end
    end    
end

function d(...)    
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if(type(value) == "table")
        then
            EmitTable(value)
        else
            EmitMessage(tostring (value))
        end
    end
end

function df(formatter, ...)
    return d(formatter:format(...))
end

function countGlobals(desiredType)
    if(desiredType == nil)
    then
        countGlobals("number")
        countGlobals("string")
        countGlobals("boolean")
        countGlobals("table")
        countGlobals("function")
        countGlobals("thread")
        countGlobals("userdata")
        return
    end

    local count = 0
    desiredType = tostring(desiredType)
    
    for k, v in pairs(_G)
    do 
        if(type(v) == desiredType)
        then 
            count = count + 1 
        end 
    end 
    
    d("There are "..count.." variables of type "..desiredType)
end

function eventArgumentDebugger(...)
    local arg = { ... }    
    local numArgs = #arg
    
    if(numArgs == 0)
    then
        return "[Unamed event, without arguments]"
    end
    
    local eventName = arg[1]
    
    if(EVENT_NAME_LOOKUP) -- nice, we can get a string look up for this event code!  (TODO: just expose these as strings?)
    then
        eventName = EVENT_NAME_LOOKUP[eventName] or eventName
    end
    
    local argString = "["..eventName.."]"
    local currentArg
    
    for i = 2, numArgs
    do
        currentArg = arg[i]
        if(type(currentArg) ~= "userdata")
        then
            argString = argString.."|c00ff00["..i.."]:|r "..tostring(currentArg)
        else
            -- Assume it's a control...which may not always be correct
            argString = argString.."|c00ff00["..i.."]:|r "..currentArg:GetName()
        end
        
        if(i < numArgs) then argString = argString..", " end
    end
    
    return argString
end

local eventRegistry = {}

function ZO_Debug_EventNotification(eventCode, register, allEvents)
    local eventManager = GetEventManager()
    local eventName = "ZO_Debug_EventNotification"..eventCode
    
    if(register and not eventRegistry[eventName])
    then
        eventRegistry[eventName] = true
        
        if(allEvents)
        then
            eventManager:RegisterForAllEvents(eventName, function(...) d(eventArgumentDebugger(...)) end)
        else
            eventManager:RegisterForEvent(eventName, eventCode, function(...) d(eventArgumentDebugger(...)) end)
        end
    else
        eventRegistry[eventName] = nil
        eventManager:UnregisterForEvent(eventName)
    end
end

-- Because typing is painful.
e = ZO_Debug_EventNotification

function all() e(0, true, true) end

-- Convenience for multiple event registration only using event variables.
-- Pass in multiple comma delimited events as the arguments:
-- ZO_Debug_MultiEventRegister(EVENT_QUEST_LIST_UPDATED, EVENT_QUEST_CONDITION_COUNTER_CHANGED, EVENT_QUEST_TOOL_UPDATED, etc...)
function ZO_Debug_MultiEventRegister(...)
    for i = 1, select("#", ...)
    do
        -- NOTE: should be able to use arg[i] here, but it's not reliable...
        local eventCode = select(i, ...)
        e(eventCode, true, false)
    end
end

m = ZO_Debug_MultiEventRegister

--
-- Execute a command with a well-known pattern over a range of numbers.
-- You give a base command (like: "]createitem")
-- and a range (start id, end id)
-- This function executes it using ExecuteChatCommand(finalCommand) n times where n = end - start
-- and where the id fed to ExecuteChatCommand is start + i.
function ExecutePatternedChatCommand(commandBase, startId, endId)
    if(type(startId) == "number" and type(endId) == "number" and endId > startId)
    then
        for i = startId, endId
        do
            ExecuteChatCommand(string.format("%s %s", commandBase, tostring(i)))
        end
    end
end

expat = ExecutePatternedChatCommand

--
-- Utility to grab the current mouse over window and display its details.
-- stands for MouseOverName
--
function mon()
    local control = moc()
    
    if(control and type(control) == "userdata") then
        d(control)
    else
        d("Mouse isn't over a control, or isn't over a mouseEnabled control.")
    end
    
    return control
end

function moc()
    return WINDOW_MANAGER:GetMouseOverControl()
end

local tierToString =
{
    [DT_LOW] = "LOW",
    [DT_MEDIUM] = "MEDIUM",
    [DT_HIGH] = "HIGH",
    [DT_PARENT] = "PARENT",
}

local layerToString =
{
    [DL_BACKGROUND] = "BACKGROUND",
    [DL_CONTROLS] = "CONTROLS",
    [DL_TEXT] = "TEXT",
    [DL_OVERLAY] = "OVERLAY",
}

local function drawInfo(control)
    local drawTier = tierToString[control:GetDrawTier()] or tostring(control:GetDrawTier())
    local drawLayer = layerToString[control:GetDrawLayer()] or tostring(control:GetDrawLayer())

    d(string.format("|c00ff00DrawInfo of: %s\n    Tier[%s] Layer[%s] Level[%d]", control:GetName(), drawTier, drawLayer, control:GetDrawLevel()))
end

di = drawInfo