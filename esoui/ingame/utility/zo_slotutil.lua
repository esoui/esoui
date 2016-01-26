-- ==================================================================================
-- Input Handlers - All input handlers (mouse down, mouse click, mouse enter, etc) work in the same manner. For each handler,
-- a table of slot types is maintained. When an input event happens, if an entry matching the interacted slot type exists, the 
-- functions listed within that entry are executed in the listed order. However, upon the first function returning true, execution
-- stops.
-- ==================================================================================

--convenience function to execute handlers
function RunHandlers(handlerTable, slot, ...)
    local handlers = handlerTable[slot.slotType]
    if(not handlers) then return end

    for i = 1,#handlers do
        local done, returnVal = handlers[i](slot, ...)
        --terminate on the first handler that returns something that's not false or nil
        if(done) then
            return done, returnVal
        end
    end

    return false
end

function RunClickHandlers(handlerTable, slot, buttonId, ...)
    local handlers = handlerTable[slot.slotType]
    if(not handlers) then
        return 
    end
   
    local buttonHandlers = handlers[buttonId]
    if(not buttonHandlers) then return end
   
    for i = 1,#buttonHandlers do
        local done, returnVal = buttonHandlers[i](slot, ...)
        --terminate on the first handler that returns something that's not false or nil
        if(done) then
            return done, returnVal
        end
    end

    return false
end